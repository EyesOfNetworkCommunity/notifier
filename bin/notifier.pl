#!/usr/bin/perl
##
## Program: notifier.pl v2.1, Rule-based Notification Addon for Nagios(r)
## License: GPL
## Copyleft 2013 Vincent Fricou (vincent.fricou@gmail.com)
## Hugely inspired by the excellent work of Yueh-Hung Liu (yuehung.liu@gmail.com)
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.
##

use strict;
use warnings;

use POSIX qw(locale_h);
use POSIX qw(strftime);
use Getopt::Std;
use File::Basename;
use XML::Simple;
use DBI;
use Data::Dumper;

$XML::Simple::PREFERRED_PARSER = 'XML::Parser';

setlocale(LC_CTYPE, 'en_US');

my $notifier_dur_start = time;

my $log_file;
my %commands;
my $found;
my $wildcard;
my $state;
my %methods_hash;
my $priority = 100;

## SQL part
my $query;
my $sqluser = 'notifierSQL';
my $sqlpassword = 'Notifier66';
my $epoch = time;
my $cmd_dur_start;
my $cmd_duration;
my $mrules;
my $calledmethods;
my @results;
my ($cmd,$etat);
my $adapt_methods;
my $array_methods;

# database connection
my $dbh = DBI->connect('DBI:mysql:notifier:127.0.0.1', $sqluser, $sqlpassword);

## ARGS
my %options=();
getopts( 't:c:r:h:s:e:T:i:n:C:O:G:N:A:B:X:Y:M:', \%options);
my $nagios_longtimedate=$options{T};
my $data_type=$options{t};
my $config_file=$options{c};
my $rules_file=$options{r};

my $host_source=$options{h};
my $host_state=$options{e};
my $host_address=$options{i};
my $notification_type=$options{n};
my $host_output=$options{O};

my $contact_name=$options{C};
my $contact_mail=$options{M};
my $service_state=$options{e};
my $service_output=$options{O};
my $service_desc=$options{s};

my $group_host=$options{A};
my $group_service=$options{B};
my $group_contact=$options{G};
my $contact_pager=$options{N};
my $nagios_time=$options{X};
my $nagios_notification_number=$options{Y};

if (! length($config_file))
{
	$config_file='/srv/eyesofnetwork/notifier/etc/notifier.cfg';
}
if (! length($rules_file))
{
	$rules_file='/srv/eyesofnetwork/notifier/etc/notifier.rules';
}

if( $data_type ne 'host' && $data_type ne 'service' )
{
	print "usage: $0 -t {host|service} [-c <config file>] [-r <rules file>] [-T TIME] [-h host] [-s service] [-e state] [-i IP] [-n notification_type] [-C contact_name] [-M contact_mail] [-O Output] [-A HostGroup] [-B ServiceGroup] [-G ContactGroup] [-N ContactPager] [-X NagiosTime] [-Y NagiosNotificationNumber ]\n";
	exit 1;
}
my $fh;
open $fh, '<', $config_file or die "failed to open config file: $config_file!";
close $fh or die "failed to close config file: $config_file!";		#### just for testing config file ####
open $fh, '<', $rules_file or die "failed to rules file: $rules_file!";
close $fh or die "failed to close config file: $rules_file!";;		#### just for testing config file ####

$notification_type = $data_type;

my $config = XMLin($config_file);
my $rules = XMLin($rules_file);
my $debug = $config->{'debug'};
my $debug_rules = $rules->{'debug_rules'};
$debug += 0;
$debug_rules += 0;
$log_file = $config->{'log_file'};
my $logrules_file = $rules->{'logrules_file'};
my $notifsent_file = $rules->{'notifsent_file'};
chomp $log_file;
chomp $logrules_file;

open my $fh_log, '>>', $log_file or die "failed to open log file!" if $debug;
open my $fh_notif, '>>', $notifsent_file or die "failed to open sent notification file!" if ($debug_rules > 0);

{
	# We don't care of uninitialized values here
	no warnings 'uninitialized';
	log_notifier("********************************************
* Begin context:
  - cmdline args: $0 @ARGV
  - debug_rules : $debug_rules
  * Parameters:
    - long date = $nagios_longtimedate
    - data type = $data_type
    - config file = $config_file
    - rules file = $rules_file
    - host_source = $host_source
    - host_state = $host_state
    - host_address = $host_address
    - notification_type = $notification_type
    - host_output = $host_output
    - service_state = $service_state
    - service_desc = $service_desc
    - contact_name = $contact_name
    - contact_mail = $contact_mail
    - service_output = $service_output
    - group_host = $group_host
    - group_service = $group_service
    - group_contact = $group_contact
    - contact_pager = $contact_pager
    - nagios_time = $nagios_time
    - nagios_notification_number = $nagios_notification_number
********************************************");
}
log_notifier("  * Processing commands:");
foreach( split( /\n/, $config->{'commands'}->{$data_type} ) )
{
	s/^[\s]*//;
	s/[\s]*$//;
	next if /^$/;

	chomp;
	if (/^(.+?)[\s]*=[\s]*(.*)$/)
	{
		$commands{$1} = $2;
		log_notifier("command [$1]-> $commands{$1}");
	}
}

log_notifier("********************************************
	* Processing rules for data-type: $rules->{$data_type}
	***");

my $today=lc(strftime '%a', gmtime);
foreach( split /\n/, $rules->{$data_type} )
{
	s/^[\s]*//;
	s/[\s]*$//;
	next if /^$/;

	chomp;
	my ( $rudebug, $contacts, $hosts, $services, $states, $days, $timeperiods, $numbers, $methods, $tracking ) = split /[\s]*:[\s]*/;

	if( ($data_type eq 'host' || $data_type eq 'service') && $services eq '-' )
	{
		next;
	}

	log_rule( $rudebug, "matching rule ` $_ '..." );
	$wildcard = 0;

	foreach( split( /,/, $group_contact), $contact_name )
        {
		$found = in_array( $_, split /[\s]*,[\s]*/, $contacts );
		last if $found;
        }
	if( ! $found )
	{
		log_rule( $rudebug, "can't find contact  $contact_name(groups=$group_contact) in $contacts -> skip this rule\n" );
		next;
	}
	log_rule( $rudebug, "found contact ` $contact_name(groups=$group_contact) ' in ` $contacts '" );
	$wildcard += $found-1;

	
	$found = in_array( $today, split /[\s]*,[\s]*/, lc($days) );
	if( ! $found )
	{
		log_rule( $rudebug, "can't find today $today in  $days -> skip this rule\n" );
		next;
	}
	log_rule( $rudebug, "found today $today in $days" );
	$wildcard += $found-1;



	foreach( split( /,/, $group_host ), $host_source )
	{
		$found = in_array( $_, split /[\s]*,[\s]*/, $hosts );
		last if $found;
	}
	if( ! $found )
	{
		log_rule( $rudebug, "can't find host $host_source(groups=$group_host) in  $hosts -> skip this rule\n" );
		next;
	}
	log_rule( $rudebug, "found host $host_source in $hosts" );
	$wildcard += $found-1;

	if( $data_type eq 'service' )
	{
		foreach( split( /,/, $group_service ), $service_desc )
		{
			$found = in_array( $_, split /[\s]*,[\s]*/, $services );
			last if $found;
		}
		if( ! $found )
		{
			log_rule( $rudebug, "can't find service $service_desc(groups=$group_service) in $services -> skip this rule\n" );
			next;
		}
		log_rule( $rudebug, "found service $service_desc in $services" );
		$wildcard += $found-1;
	}

	$state = $data_type eq 'host' ? $host_state : $service_state;
	$found = in_array( $state, split /[\s]*,[\s]*/, $states );
	if( ! $found )
	{
		log_rule( $rudebug, "can't find state ` $state ' in ` $states ' -> skip this rule\n" );
		next;
	}
	log_rule( $rudebug, "found state ` $state ' in ` $states '" );
	$wildcard += $found-1;

	$found = in_timeperiod( $nagios_time, split /[\s]*,[\s]*/, $timeperiods );
	if( ! $found )
	{
		log_rule( $rudebug, "can't find time $nagios_time in $timeperiods -> skip this rule\n" );
		next;
	}
	log_rule( $rudebug, "found time $nagios_time in $timeperiods" );
	$wildcard += $found-1;

	$found = in_number( $nagios_notification_number , split /[\s]*,[\s]*/, $numbers );
	if( ! $found )
	{
		log_rule( $rudebug, "can't find notification number $nagios_notification_number in $numbers ....skip this rule\n" );
		next;
	}
	log_rule( $rudebug, "found notification number $nagios_notification_number in $numbers" );
	$wildcard += $found-1;

	if ( defined $tracking && $tracking eq '1' )
	{
		my $query_analysis = "SELECT state,method FROM notifier.sents_logs WHERE contact='".$contact_name."' AND host='".$host_source;
		if ( ! $service_desc )
		{
			$query_analysis = $query_analysis . "' order by id desc limit 1;";
		} else {
			$query_analysis = $query_analysis . "' AND service='".$service_desc."' order by id desc limit 1;";
		}
		@results = $dbh->selectrow_array($query_analysis);
		my $prev_state = $results[0];
		my @prev_methods = split ',', $results[1];
		if ( $state ne $prev_state )
		{
			$array_methods = '';
			foreach my $uniq_methods (@prev_methods)
			{
				($cmd,$etat) = $uniq_methods =~ /([a-z\-]+)(.*)$/;
				if ( $etat ne '' )
				{
					$adapt_methods=fill_method_array($cmd,$state);
				} else {
					$adapt_methods=fill_method_array($cmd);
				}
			}
			$methods=$adapt_methods;
		}
	}

	if( $wildcard > $priority )
	{
		log_rule( $rudebug, "current priority = $priority; new priority(wildcard matching) = $wildcard -> ignore this rule\n" );
	}
	elsif( $wildcard == $priority )
	{
		log_rule( $rudebug, "current priority = $priority; new priority(wildcard matching) = $wildcard....merge this rule\n" );
		$mrules="$rudebug,$contacts,$hosts,$services,$states,$days,$timeperiods,$numbers,$methods";
		$calledmethods="$methods";
		foreach( split( /[\s]*,[\s]*/, $methods ) )
		{
			log_trace("$nagios_longtimedate Sent notification to $contact_name on $host_source $service_desc for state $state by $methods with priority $priority on notifiaction number $nagios_notification_number | {Matched rules : $rudebug;$contacts;$hosts;$services;$states;$days;$timeperiods;$numbers;$methods}");
			$methods_hash{$_} = 1;
		}
	}
	else
	{
		log_rule( $rudebug, "current priority = $priority; new priority(wildcard matching) = $wildcard....replace with this rule\n" );
		$mrules="$rudebug,$contacts,$hosts,$services,$states,$days,$timeperiods,$numbers,$methods";
		$calledmethods="$methods";
		$priority = $wildcard;
		%methods_hash = ();
		foreach( split( /[\s]*,[\s]*/, $methods ) )
		{
			log_trace("$nagios_longtimedate Sent notification to $contact_name on $host_source $service_desc for state $state by $methods with priority $priority on notification number $nagios_notification_number | {Matched rules : $rudebug;$contacts;$hosts;$services;$states;$days;$timeperiods;$numbers;$methods}");
			$methods_hash{$_} = 1;
		}
	}
}

if( ! exists $methods_hash{q{-}} )
{
	if( exists $methods_hash{q{*}} )
	{
		%methods_hash = ();
		foreach( keys %commands )
		{
			$methods_hash{$_} = 1;
		}
	}

	foreach( keys %methods_hash )
	{
		log_rule( $debug_rules, "#### notify $data_type by $_");
		notify( $_ );
	}
}
else
{
	log_rule( $debug_rules, '#### silence');
}
$dbh->disconnect();
close $fh_log if $debug;
close $fh_notif if $debug_rules;


#######################
#
##### subroutines #####
#
#######################

sub in_array
{
	my ( $item, @array ) = @_;
	my $found = 0;

	return 2 if $array[0] =~ /^\*$/;
	foreach( @array )
	{
		if( /^$item$/ )
		{
			$found = 1;
			last;
		}
	}
	return $found;
}

sub in_timeperiod
{
	my ( $time, @array ) = @_;

	my $found = 0;
	my $start;
	my $end;

	return 2 if $array[0] =~ /^\*$/;

	$time =~ s/://g; 
	foreach( @array )
	{
		( $start, $end ) = split /[\s]*-[\s]*/;
		$start .= '00';
		$end .= '00';
		if( $time >= $start && $time < $end )
		{
			$found = 1;
			last;
		}
	}
	return $found;
}

sub in_number
{
	my ( $number, @array ) = @_;

	my $found = 0;
	my $start;
	my $end;

	return 2 if $array[0] =~ /^\*$/;
	foreach( @array )
	{
		if ( /-/ )
		{
			( $start, $end ) = split /[\s]*-[\s]*/;
		}
		else
		{
			$start = $end = $_;
		}

		if ($end == 0) { $end = $number; }
		if( $number >= $start && $number <= $end )
		{
			$found = 1;
			last;
		}
	}

	return $found;
}

sub fill_method_array
{
	my ($sub_cmd, $sub_etat) = @_;
	if ( ! $array_methods )
	{
		$array_methods = $sub_cmd . $sub_etat;
	} else {
		$array_methods = $array_methods . q{,} . $sub_cmd . $sub_etat;
	}
	return $array_methods;
}

sub notify
{
	my ( $method ) = @_;
	$commands{$method} =~ s/\$NOTIFICATIONTYPE\$/$data_type/g;
	$commands{$method} =~ s/\$SERVICEDESC\$/$service_desc/g;
	$commands{$method} =~ s/\$HOSTALIAS\$/$host_source/g;
	$commands{$method} =~ s/\$HOSTADDRESS\$/$host_address/g;
	$commands{$method} =~ s/\$SERVICESTATE\$/$service_state/g;
	$commands{$method} =~ s/\$LONGDATETIME\$/$nagios_longtimedate/g;
	$commands{$method} =~ s/\$SERVICEOUTPUT\$/$service_output/g;
	$commands{$method} =~ s/\$SERVICESTATE\$/$service_state/g;
	$commands{$method} =~ s/\$HOSTNAME\$/$host_source/g;
	$commands{$method} =~ s/\$CONTACTNAME\$/$contact_name/g;
	$commands{$method} =~ s/\$CONTACTEMAIL\$/$contact_mail/g;
	$commands{$method} =~ s/\$CONTACTPAGER\$/$contact_pager/g;
	$commands{$method} =~ s/\$HOSTSTATE\$/$host_state/g;
	$commands{$method} =~ s/\$HOSTGROUPNAMES\$/$group_host/g;
	$commands{$method} =~ s/\$SERVICEGROUPNAMES\$/$group_service/g;
	$commands{$method} =~ s/\$HOSTOUTPUT\$/$host_output/g;
	$commands{$method} =~ s/\$HOSTSTATE\$/$host_state/g;
	log_notifier ("command = $commands{$method}");
	$cmd_dur_start = time;
	system "$commands{$method}";
	my $ret = $?;
	$cmd_duration = time - $cmd_dur_start;
	$state = $data_type eq 'host' ? $host_state : $service_state;
	if ($ret == -1) {
		my $notifier_duration = time - $notifier_dur_start;
		$query = "INSERT INTO notifier.sents_logs (nagios_date, contact, host, service, state, notification_number, method, priority, matched_rule, exit_code, exit_command, epoch, cmd_duration, notifier_duration) VALUES('".$nagios_longtimedate."', '".$contact_name."', '".$host_source."', '".$service_desc."', '".$state."', '".$nagios_notification_number."',  '".$calledmethods."', $priority, '$mrules', $?, '".$commands{$method}."', $epoch, $cmd_duration, $notifier_duration)";
		$dbh->do($query);
        log_trace("Failed to execute: $! The final command was: $commands{$method}");
    }
    elsif ($ret & 127) {
		my $notifier_duration = time - $notifier_dur_start;
		$query = "INSERT INTO notifier.sents_logs (nagios_date, contact, host, service, state, notification_number, method, priority, matched_rule, exit_code, exit_command, epoch, cmd_duration, notifier_duration) VALUES('".$nagios_longtimedate."', '".$contact_name."', '".$host_source."', '".$service_desc."', '".$state."', '".$nagios_notification_number."',  '".$calledmethods."', $priority, '$mrules', $?, '".$commands{$method}."', $epoch, $cmd_duration, $notifier_duration)";
		$dbh->do($query);
        log_trace('Child died with signal \'' . ($ret & 127) . ($ret & 128) ? '\', with' : '\', without' . "coredump. The final command was: $commands{$method}");
    }
    else {
		my $notifier_duration = time - $notifier_dur_start;
		$query = "INSERT INTO notifier.sents_logs (nagios_date, contact, host, service, state, notification_number, method, priority, matched_rule, exit_code, exit_command, epoch, cmd_duration, notifier_duration) VALUES('".$nagios_longtimedate."', '".$contact_name."', '".$host_source."', '".$service_desc."', '".$state."', '".$nagios_notification_number."', '".$calledmethods."', $priority, '$mrules', $?, '".$commands{$method}."', $epoch, $cmd_duration, $notifier_duration)";
		$dbh->do($query);
        log_trace('Child exited with value ' . ($ret >> 8) . ". The final command was: $commands{$method}");
    }
	log_notifier('');
}

sub getDate
{
	my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime(time);
    sprintf( "%04i-%02i-%02i %02i:%02i", ( $year > 50 ) ? $year + 1900 : $year + 2000, $mon + 1, $mday, $hour, $min );
}
sub log_notifier
{
	# global notifier debug (0 or 1)
	# $debug
	#
	# rules debug (0: no, 1: full debug, 2: sent notification traces, 3: 1+2)
	# $debug_rules
	if (!$debug) { return; }
	return print {$fh_log} &getDate . " " . $_[0] . "\n";
}

sub log_rule
{
	my ($debug, $message) = @_;
	if (!$debug) { return; }
	if ($debug_rules == 1 || $debug_rules == 3 )
	{
		return log_notifier($message);
	}
	return 0;
}

sub log_trace
{
	if ($debug_rules == 2 || $debug_rules == 3 )
	{
		log_notifier($_[0]);
		return print {$fh_notif} &getDate . " " . $_[0] . "\n";
	}
	return 0;
}
