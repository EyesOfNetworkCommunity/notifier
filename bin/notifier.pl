#!/usr/bin/perl
## 
## Program: notifier.pl v1.4, Rule-based Notification Addon for Nagios(r)
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

use POSIX qw(locale_h);	## Modif L.P
use POSIX qw(strftime);	## Modif L.P
use Getopt::Std;
use File::Basename;
use XML::Simple;

setlocale(LC_CTYPE, "en_EN");
$XML::Simple::PREFERRED_PARSER = XML::Parser;

my $data_type;
my $config_file = "/srv/eyesofnetwork/notifier/etc/notifier.cfg";
my $config;
my $rules;
my $debug;
my $debug_rules;
my $log_file;
my %commands;
my $mike_commands;
my ( $rudebug, $contacts, $hosts, $services, $states, $timeperiods, $numbers, $methods );
my $rdebug;
my $found;
my $wildcard;
my $state;
my %methods_hash;
my $priority = 100;


## common part
my $host_source;
my $host_state;
my $host_address;
my $notification_type;
my $contact_mail;
my $nagios_longtimedate;

## host part
my $host_output;

## service part
my $service_desc;
my $service_state;
my $service_output;

%options=();
getopts( "t:c:r:h:s:e:T:i:n:C:O:G:N:A:B:X:Y:", \%options);
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

$contact_mail=$options{C};
$service_state=$options{e};
$service_output=$options{O};
$service_desc=$options{s};

$group_host=$options{A};
$group_service=$options{B};
$group_contact=$options{G};
$contact_pager=$options{N};
$nagios_time=$options{X};
$nagios_notification_number=$options{Y};

if( $config_file eq "" )
{
	$config_file="/srv/eyesofnetwork/notifier/etc/notifier.cfg";
}


if( $rules_file eq "" )
{
	$rules_file="/srv/eyesofnetwork/notifier/etc/notifier.rules";
}


if( $data_type ne "host" && $data_type ne "service" )
{
	#$today=strftime "%w", gmtime;
	#print "today : $dayweek[$today]\n";
	print "usage: $0 -t {host|service} [-c <config file>] [-r <rules file>] [-T TIME] [-h host] [-s service] [-e state] [-i IP] [-n notification_type] [-C contact_mail] [-O Output] [-A HostGroup] [-B ServiceGroup] [-G ContactGroup] [-N ContactPager] [-X NagiosTime] [-Y NagiosNotificationNumber ]\n";
	exit 1;
}

open CONFIG, "< $config_file" or die "failed to open config file: $config_file!";
close CONFIG;		#### just for testing config file ####
open RULES, "< $rules_file" or die "failed to rules file: $rules_file!";
close RULES;		#### just for testing config file ####

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
open LOG, ">> $log_file" or die "failed to open log file!" if $debug;
open LOGRULES, ">> $logrules_file" or die "failed to open log rules file!";
open NOTIFSENTRULES, ">> $notifsent_file" or die "failed to open sent notification file!" if ($debug_rules == 2 || $debug_rules == 3);

print LOG "\n********************************************\n" if $debug;
print LOG "Begin Context\n" if $debug;
print LOG "********************************************\n" if $debug;
print LOG "$0 @ARGV\n" if $debug;
print LOG "debug_rules: $debug_rules\n" if $debug;
print LOG "********************************************\n" if $debug;
print LOG "date = $nagios_longtimedate\n" if $debug;
print LOG "data type = $data_type\n" if $debug;
print LOG "config file = $config_file\n" if $debug;
print LOG "rules file = $rules_file\n" if $debug;

print LOG "host_source = $host_source\n" if $debug;
print LOG "host_state = $host_state\n" if $debug;
print LOG "host_address = $host_address\n" if $debug;
print LOG "notification_type = $notification_type\n" if $debug;
print LOG "host_output = $host_output\n" if $debug;

print LOG "service_state = $service_state\n" if $debug;
print LOG "service_desc = $service_desc\n" if $debug;
print LOG "contact_mail = $contact_mail\n" if $debug;
print LOG "service_output = $service_output\n" if $debug;

print LOG "group_host = $group_host\n" if $debug;
print LOG "group_service = $group_service\n" if $debug;
print LOG "group_contact = $group_contact\n" if $debug;
print LOG "contact_pager = $contact_pager\n" if $debug;
print LOG "nagios_time = $nagios_time\n" if $debug;
print LOG "nagios_notification_number = $nagios_notification_number\n" if $debug;
print LOG "\n********************************************\n" if $debug;
print LOG "End of  Context\n" if $debug;
print LOG "********************************************\n" if $debug;


foreach( split( /\n/, $$config{'commands'}{$data_type} ) )
{
	s/^[\s]*//;
	s/[\s]*$//;
	next if /^$/;

	chomp;
	/^(.+?)[\s]*=[\s]*(.*)$/;
	$commands{$1} = $2;
	print LOG "Reading $config_file and found: $commands{$1}\n" if $debug;
	print LOG "Dollar 1: $1\n" if $debug;
}
print LOGRULES "********************************************\n" if ($debug_rules == 1 || $debug_rules == 3);
print LOGRULES "date = $nagios_longtimedate\n" if ($debug_rules == 1 || $debug_rules == 3);
print LOGRULES "Reading $rules_file data_type: $$rules{$data_type}\n" if ($debug_rules == 1 || $debug_rules == 3);
print LOG "Reading $rules_file data_type: $$rules{$data_type}\n" if $debug;
foreach( split( /\n/, $$rules{$data_type} ) )
{
	s/^[\s]*//;
	s/[\s]*$//;
	next if /^$/;

	chomp;
	( $rudebug, $contacts, $hosts, $services, $states, $days, $timeperiods, $numbers, $methods ) = split /[\s]*:[\s]*/; ## Modif L.P
	print LOGRULES "********************************************\n" if ($rudebug == 1);
	print LOGRULES "date = $nagios_longtimedate\n" if ($rudebug == 1);
	print LOGRULES "Reading $rules_file data_type: $$rules{$data_type}\n" if ($rudebug == 1);

	if( $data_type eq "host" && $services ne "-" || $data_type eq "service" && $services eq "-" )
	{
		next;
	}

	print LOGRULES "#### matching rule ` $_ '....\n" if ($debug_rules == 1 || $debug_rules == 3 || $rudebug == 1);
	$wildcard = 0;

	foreach( split( /,/, $group_contact), $contact_mail )
        {
		$found = in_array( $_, split( /[\s]*,[\s]*/, $contacts ) );
		last if $found;
        }
	if( ! $found )
	{
		print LOGRULES "can't find contact  $contact_mail(groups=$group_contact) in $contacts ....skip this rule\n" if ($debug_rules == 1 || $debug_rules == 3 || $rudebug == 1);
		next;
	}
	print LOGRULES "found contact ` $contact_mail(groups=$group_contact) ' in ` $contacts '\n" if ($debug_rules == 1 || $debug_rules == 3 || $rudebug == 1);
	$wildcard += $found-1;
	
#
#	Ajout L.P.
#

	$today=lc(strftime "%a", gmtime);
	#
	## On met en minuscule et on split
	#
	$found = in_array( $today, split( /[\s]*,[\s]*/, lc($days)) );
	if( ! $found )
	{
		print LOGRULES "can't find today $today in  $days ....skip this rule\n" if ($debug_rules == 1 || $debug_rules == 3 || $rudebug == 1);
		next;
	}
	print LOGRULES "found today $today in $days \n" if ($debug_rules == 1 || $debug_rules == 3 || $rudebug == 1);
	$wildcard += $found-1;

	

	foreach( split( /,/, $group_host ), $host_source )
	{
		$found = in_array( $_, split( /[\s]*,[\s]*/, $hosts ) );
		last if $found;
	}
	if( ! $found )
	{
		print LOGRULES "can't find host $host_source(groups=$group_host) in  $hosts ....skip this rule\n" if ($debug_rules == 1 || $debug_rules == 3 || $rudebug == 1);
		next;
	}
	print LOGRULES "found host $host_source in $hosts \n" if ($debug_rules == 1 || $debug_rules == 3 || $rudebug == 1);
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
			print LOGRULES "can't find service $service_desc(groups=$group_service) in $services ....skip this rule\n" if ($debug_rules == 1 || $debug_rules == 3 || $rudebug == 1);
			next;
		}
		print LOGRULES "found service $service_desc in $services \n" if ($debug_rules == 1 || $debug_rules == 3 || $rudebug == 1);
		$wildcard += $found-1;
	}

	$state = $data_type eq "host" ? $host_state : $service_state;
	$found = in_array( $state, split( /[\s]*,[\s]*/, $states ) );
	if( ! $found )
	{
		print LOGRULES "can't find state ` $state ' in ` $states '....skip this rule\n" if ($debug_rules == 1 || $debug_rules == 3 || $rudebug == 1);
		next;
	}
	print LOGRULES "found state ` $state ' in ` $states '\n" if ($debug_rules == 1 || $debug_rules == 3 || $rudebug == 1);
	$wildcard += $found-1;

	$found = in_timeperiod( $nagios_time, split( /[\s]*,[\s]*/, $timeperiods ) );
	if( ! $found )
	{
		print LOGRULES "can't find time $nagios_time in $timeperiods ....skip this rule\n" if ($debug_rules == 1 || $debug_rules == 3 || $rudebug == 1);
		next;
	}
	print LOGRULES "found time $nagios_time in $timeperiods\n" if ($debug_rules == 1 || $debug_rules == 3 || $rudebug == 1);
	$wildcard += $found-1;

	$found = in_number( $nagios_notification_number , split( /[\s]*,[\s]*/, $numbers ) );
	if( ! $found )
	{
		print LOGRULES "can't find notification number $nagios_notification_number in $numbers ....skip this rule\n" if ($debug_rules == 1 || $debug_rules == 3 || $rudebug == 1);
		next;
	}
	print LOGRULES "found notification number $nagios_notification_number in $numbers \n" if ($debug_rules == 1 || $debug_rules == 3 || $rudebug == 1);
	$wildcard += $found-1;

	if( $wildcard > $priority )
	{
		print LOGRULES "current priority = $priority; new priority(wildcard matching) = $wildcard....ignore this rule\n" if ($debug_rules == 1 || $debug_rules == 3 || $rudebug == 1);
	}
	elsif( $wildcard == $priority )
	{
		print LOGRULES "current priority = $priority; new priority(wildcard matching) = $wildcard....merge this rule\n" if ($debug_rules == 1 || $debug_rules == 3 || $rudebug == 1);
		foreach( split( /[\s]*,[\s]*/, $methods ) )
		{
			print NOTIFSENTRULES "$nagios_longtimedate Sent notification to $contact_mail on $host_source $service_desc for state $state by $methods with priority $priority| {Matched rules : $rudebug;$contacts;$hosts;$services;$states;$days;$timeperiods;$numbers;$methods}\n" if( $debug_rules == 2  || $debug_rules == 3 );
			$methods_hash{$_} = 1;
		}
	}
	else
	{
		print LOGRULES "current priority = $priority; new priority(wildcard matching) = $wildcard....replace with this rule\n" if ($debug_rules == 1 || $debug_rules == 3 || $rudebug == 1);
		$priority = $wildcard;
		%methods_hash = ();
		foreach( split( /[\s]*,[\s]*/, $methods ) )
		{
			print NOTIFSENTRULES "$nagios_longtimedate Sent notification to $contact_mail on $host_source $service_desc for state $state by $methods with priority $priority | {Matched rules : $rudebug;$contacts;$hosts;$services;$states;$days;$timeperiods;$numbers;$methods}\n" if( $debug_rules == 2  || $debug_rules == 3 );
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
		print LOGRULES "#### notify $data_type by $_\n" if ($debug_rules == 1 || $debug_rules == 3 || $rudebug == 1);
		notify( $_ );
	}
}
else
{
	print LOGRULES "#### silence\n" if ($debug_rules == 1 || $debug_rules == 3 || $rudebug == 1);
}


close LOG if $debug;
close LOGRULES;
close NOTIFSENTRULES if $debug_rules;


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
	$commands{$method} =~ s/\$CONTACTEMAIL\$/$contact_mail/g;
	$commands{$method} =~ s/\$CONTACTPAGER\$/$contact_pager/g;
	$commands{$method} =~ s/\$HOSTSTATE\$/$host_state/g;
	$commands{$method} =~ s/\$HOSTOUTPUT\$/$host_output/g;
	$commands{$method} =~ s/\$HOSTSTATE\$/$host_state/g;
	print LOG "command = $commands{$method}\n" if $debug;
	print LOGRULES "command = $commands{$method}\n" if ($debug_rules == 1 || $debug_rules == 3 || $rudebug == 1);
	system "$commands{$method}";
	if ($? == -1) {
        print NOTIFSENTRULES "Failed to execute: $! The final command was: $commands{$method} \n-----\n";
    }
    elsif ($? & 127) {
        printf NOTIFSENTRULES "Child died with signal %d, %s coredump. The final command was: $commands{$method} \n-----\n",
            ($? & 127),  ($? & 128) ? 'with' : 'without';
    }
    else {
        printf NOTIFSENTRULES "Child exited with value %d. The final command was: $commands{$method} \n-----\n", $? >> 8;
    }
}
