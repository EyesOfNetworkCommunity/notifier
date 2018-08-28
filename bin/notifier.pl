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

use POSIX qw(locale_h);
use POSIX qw(strftime);
use Getopt::Std;
use File::Basename;
use XML::Simple;
use DBI;
use Data::Dumper;

$XML::Simple::PREFERRED_PARSER = XML::Parser;

setlocale(LC_CTYPE, 'en_US');

my $notifier_dur_start = time;

my $data_type;
my $config_file = '/srv/eyesofnetwork/notifier/etc/notifier.cfg';
my $config;
my $rules;
my $debug;
my $debug_rules;
my $log_file;
my %commands;
my ( $rudebug, $contacts, $hosts, $services, $states, $timeperiods, $numbers, $methods, $tracking );
my $found;
my $wildcard;
my $state;
my %methods_hash;
my $priority = 100;

## SQL part
my $dbh;
my $query;
my $sqluser = 'notifierSQL';
my $sqlpassword = 'Notifier66';
my $epoch = time;
my $cmd_dur_start;
my $cmd_duration;
my $mrules;
my $calledmethods;
my $prev_methods;
my @results;
my ($cmd,$etat);
my $adapt_methods;
## common part
my $host_source;
my $host_state;
my $host_address;
my $notification_type;
my $contact_name;
my $contact_mail;
my $nagios_longtimedate;

## host part
my $host_output;

## service part
my $service_desc;
my $service_state;
my $service_output;

# database connection
$dbh = DBI->connect('DBI:mysql:notifier:127.0.0.1', $sqluser, $sqlpassword);

%options=();
getopts( 't:c:r:h:s:e:T:i:n:C:O:G:N:A:B:X:Y:M:', \%options);
$nagios_longtimedate=$options{T};
$data_type=$options{t};
$config_file=$options{c};
$rules_file=$options{r};

## ARGS
$host_source=$options{h};
$host_state=$options{e};
$host_address=$options{i};
$notification_type=$options{n};
$host_output=$options{O};

$contact_name=$options{C};
$contact_mail=$options{M};
$service_state=$options{e};
$service_output=$options{O};
$service_desc=$options{s};

$group_host=$options{A};
$group_service=$options{B};
$group_contact=$options{G};
$contact_pager=$options{N};
$nagios_time=$options{X};
$nagios_notification_number=$options{Y};

if( $config_file eq '' )
{
	$config_file='/srv/eyesofnetwork/notifier/etc/notifier.cfg';
}


if( $rules_file eq '' )
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

$config = XMLin($config_file);
$rules = XMLin($rules_file);
$debug = $$config{'debug'};
$debug_rules = $$rules{'debug_rules'};
$debug += 0;
$debug_rules += 0;
$log_file = $$config{'log_file'};
$logrules_file = $$rules{'logrules_file'};
$notifsent_file = $$rules{'notifsent_file'};
chomp $log_file;
chomp $logrules_file;

open my $fh_log, '>>', $log_file or die "failed to open log file!" if $debug;
open my $fh_notif, '>>', $notifsent_file or die "failed to open sent notification file!" if ($debug_rules > 0);

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
      - notification_type = $notification_typen
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
foreach( split( /\n/, $$config{'commands'}{$data_type} ) )
{
	s/^[\s]*//;
	s/[\s]*$//;
	next if /^$/;

	chomp;
	/^(.+?)[\s]*=[\s]*(.*)$/;
	$commands{$1} = $2;
	log_notifier("Found command: $1 with content: $commands{$1}");
}
log_notifier("********************************************
	* Processing rules for data-type: $$rules{$data_type}
	***");

foreach( split( /\n/, $$rules{$data_type} ) )
{
	s/^[\s]*//;
	s/[\s]*$//;
	next if /^$/;

	chomp;
	( $rudebug, $contacts, $hosts, $services, $states, $days, $timeperiods, $numbers, $methods, $tracking ) = split /[\s]*:[\s]*/;
	
	if( $data_type eq "host" && $services ne "-" || $data_type eq "service" && $services eq "-" )
	{
		next;
	}

	log_rule( $rudebug, "matching rule ` $_ '..." );
	$wildcard = 0;

	foreach( split( /,/, $group_contact), $contact_name )
        {
		$found = in_array( $_, split( /[\s]*,[\s]*/, $contacts ) );
		last if $found;
        }
	if( ! $found )
	{
		log_rule( $rudebug, "can't find contact  $contact_name(groups=$group_contact) in $contacts -> skip this rule" );
		next;
	}
	log_rule( $rudebug, "found contact ` $contact_name(groups=$group_contact) ' in ` $contacts '" );
	$wildcard += $found-1;

	$today=lc(strftime "%a", gmtime);
	$found = in_array( $today, split( /[\s]*,[\s]*/, lc($days)) );
	if( ! $found )
	{
		log_rule( $rudebug, "can't find today $today in  $days -> skip this rule" );
		next;
	}
	log_rule( $rudebug, "found today $today in $days" );
	$wildcard += $found-1;



	foreach( split( /,/, $group_host ), $host_source )
	{
		$found = in_array( $_, split( /[\s]*,[\s]*/, $hosts ) );
		last if $found;
	}
	if( ! $found )
	{
		log_rule( $rudebug, "can't find host $host_source(groups=$group_host) in  $hosts -> skip this rule" );
		next;
	}
	log_rule( $rudebug, "found host $host_source in $hosts" );
	$wildcard += $found-1;

	if( $data_type eq "service" )
	{
		foreach( split( /,/, $group_service ), $service_desc )
		{
			$found = in_array( $_, split( /[\s]*,[\s]*/, $services ) );
			last if $found;
		}
		if( ! $found )
		{
			log_rule( $rudebug, "can't find service $service_desc(groups=$group_service) in $services -> skip this rule" );
			next;
		}
		log_rule( $rudebug, "found service $service_desc in $services" );
		$wildcard += $found-1;
	}

	$state = $data_type eq "host" ? $host_state : $service_state;
	$found = in_array( $state, split( /[\s]*,[\s]*/, $states ) );
	if( ! $found )
	{
		log_rule( $rudebug, "can't find state ` $state ' in ` $states ' -> skip this rule" );
		next;
	}
	log_rule( $rudebug, "found state ` $state ' in ` $states '" );
	$wildcard += $found-1;

	$found = in_timeperiod( $nagios_time, split( /[\s]*,[\s]*/, $timeperiods ) );
	if( ! $found )
	{
		log_rule( $rudebug, "can't find time $nagios_time in $timeperiods -> skip this rule" );
		next;
	}
	log_rule( $rudebug, "found time $nagios_time in $timeperiods" );
	$wildcard += $found-1;

	$found = in_number( $nagios_notification_number , split( /[\s]*,[\s]*/, $numbers ) );
	if( ! $found )
	{
		log_rule( $rudebug, "can't find notification number $nagios_notification_number in $numbers ....skip this rule" );
		next;
	}
	log_rule( $rudebug, "found notification number $nagios_notification_number in $numbers" );
	$wildcard += $found-1;

	if ( $tracking != 0 )
	{
		if ( ! $service_desc )
		{
			$query_analysis = "SELECT state,method FROM notifier.sents_logs WHERE contact='".$contact_name."' AND host='".$host_source."' order by id desc limit 1;";
		} else {
			$query_analysis = "SELECT state,method FROM notifier.sents_logs WHERE contact='".$contact_name."' AND host='".$host_source."' AND service='".$service_desc."' order by id desc limit 1;";
		}
		@results = $dbh->selectrow_array($query_analysis);
		$prev_state = $results[0];
		$prev_methods = $results[1];
		my @prev_methods = split(',',$prev_methods);
		if ( $state ne $prev_state )
		{
			my $array_methods;
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
		log_rule( $rudebug, "current priority = $priority; new priority(wildcard matching) = $wildcard -> ignore this rule" );
	}
	elsif( $wildcard == $priority )
	{
		log_rule( $rudebug, "current priority = $priority; new priority(wildcard matching) = $wildcard....merge this rule" );
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
		log_rule( $rudebug, "current priority = $priority; new priority(wildcard matching) = $wildcard....replace with this rule" );
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

if( ! exists $methods_hash{'-'} )
{
	if( exists $methods_hash{'*'} )
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
	log_rule( $debug_rules, "#### silence");
}
$dbh->disconnect();
close($fh_log) if $debug;
close($fh_notif) if $debug_rules;


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
		$start .= "00";
		$end .= "00";
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

		$end = $number if $end == 0;
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
		$array_methods=$sub_cmd.$sub_etat;
	} else { 
		$array_methods=$array_methods.",".$sub_cmd.$sub_etat; 
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
	log ("command = $commands{$method}");
	$cmd_dur_start = time;
	system "$commands{$method}";
	$cmd_duration = time - $cmd_dur_start;
	$state = $data_type eq "host" ? $host_state : $service_state;
	if ($? == -1) {
		my $notifier_duration = time - $notifier_dur_start;
		$query = "INSERT INTO notifier.sents_logs (nagios_date, contact, host, service, state, notification_number, method, priority, matched_rule, exit_code, exit_command, epoch, cmd_duration, notifier_duration) VALUES('".$nagios_longtimedate."', '".$contact_name."', '".$host_source."', '".$service_desc."', '".$state."', '".$nagios_notification_number."',  '".$calledmethods."', $priority, '$mrules', $?, '".$commands{$method}."', $epoch, $cmd_duration, $notifier_duration)";
		$dbh->do($query);
        log_trace("Failed to execute: $! The final command was: $commands{$method}");
    }
    elsif ($? & 127) {
		my $notifier_duration = time - $notifier_dur_start;
		$query = "INSERT INTO notifier.sents_logs (nagios_date, contact, host, service, state, notification_number, method, priority, matched_rule, exit_code, exit_command, epoch, cmd_duration, notifier_duration) VALUES('".$nagios_longtimedate."', '".$contact_name."', '".$host_source."', '".$service_desc."', '".$state."', '".$nagios_notification_number."',  '".$calledmethods."', $priority, '$mrules', $?, '".$commands{$method}."', $epoch, $cmd_duration, $notifier_duration)";
		$dbh->do($query);
        log_trace("Child died with signal " + ($? & 127) + ($? & 128) ? ', with' : ', without' + "coredump. The final command was: $commands{$method}");
    }
    else {
		my $notifier_duration = time - $notifier_dur_start;
		$query = "INSERT INTO notifier.sents_logs (nagios_date, contact, host, service, state, notification_number, method, priority, matched_rule, exit_code, exit_command, epoch, cmd_duration, notifier_duration) VALUES('".$nagios_longtimedate."', '".$contact_name."', '".$host_source."', '".$service_desc."', '".$state."', '".$nagios_notification_number."', '".$calledmethods."', $priority, '$mrules', $?, '".$commands{$method}."', $epoch, $cmd_duration, $notifier_duration)";
		$dbh->do($query);
        log_trace("Child exited with value " + $? >> 8 + ". The final command was: $commands{$method}");
    }
}

sub log_notifier
{
	# global notifier debug (0 or 1)
	# $debug
	#
	# rules debug (0: no, 1: full debug, 2: sent notification traces, 3: 1+2)
	# $debug_rules
	if (!$debug) { return; }
	print $fh_log "$1\n";
}

sub log_rule
{

	my ($debug, $message) = @_;
	if (!$debug) { return; }
	if ($debug_rules == 1 || $debug_rules == 3 )
	{
		log_notifier($message);
	}
}

sub log_trace
{
	if ($debug_rules == 2 || $debug_rules == 3 )
	{
		log_notifier($1);
		print $fh_notif "$1\n";
	}
}
