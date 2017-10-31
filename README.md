# EyesOfNetwork advanced notifier unit.

## NEWS
Version 2.1 released with notification tracking.

### v2.1-1
This version will introduce a change on rules declarations.

This change affect the contact field in rules configurations.  
Now, to you'll specify not the contact email, but the contact login.

Command change too. you'll need to specify a new field in command (-M) to give contact mail informations to notifier.  
The previously field for contact email (-C) going contact name.

### V2.1
The new release v2.1 include notifications tracking.
Typically, current notification traited by notifier can check previous sent notification method to automatically adapt methods to use on it.
Exemple 1:
* 1st notification sent DOWN on host with method email and sms.
* 2nd notification sent UP on host with normal notification only email. But if you choose to track these types (In rules), this method can be adapted to auto take same notifications than 1st (email and sms). Next to, if you re-send UP notification in exact same case (contact and host), the new notification take normal methos (email)

### Most important change on rules and commands configuration
* Introduce a new field in notifier.rules configuration line in end of line. This field manage notification tracking or not (0 == tracking disables, 1 == tracking enabled)
* VERY IMPORTANT : all notifications command (in notifier.cfg) MUST BE in standard format if you use specific notification with match on state !
 * Example if you have a specific command to send custom email on CRITICAL state, the command ___must be___ in format « command-nameSTATE ». You choose all name of « command-name » but the ending is compulsory in tune with nagios state. (See notifier.cfg for explicit examples)

## To think
Is necessary to create notifier database before start using EON advanced notification from v2.0

### Create database
A script exist to automaticaly create database on running system if default mysql root password as not changed :
> docs/db/create_database.sh

Just launch this script to create database.

## Roadmap
* Creation of web GUI to rules configuration
* Finish script with some checks on rules (for v2.1-1 migration)

## Tools
A script has be writted to migrate one version to other more easier.  
You'll find it in [notifier/scripts/updates/v2.1_to_v2.1-1.sh](https://github.com/EyesOfNetworkCommunity/notifier/scripts/updates/v2.1_to_v2.1-1.sh)

## Troubleshooting
### Version 2.1-1
Notifier manual execution command :
```bash
# Generic command
./notifier.pl -t <host|service> -c <config_file_path> -r <rules_file_path> -T <YYYY-MM-DD-HH:mm:ss> -h <hostname> -A <hostgroup> -B <servicegroup> -s <servicename> -e <state> -i <hostaddress> -n <method> -C <contact_name> -M <contact_email> -O <output> -X <YYYY-MM-DD-HH:mm:ss> -Y <notification_number> -N <contact_pager>

# Exemple command
./notifier.pl -t service -c /srv/eyesofnetwork/notifier/etc/notifier.cfg -r /srv/eyesofnetwork/notifier/etc/notifier.rules -T 2017-07-27-10:05:00 -h localhost -A LINUX -B GENERIC-SERVICES -s memory -e CRITICAL -i 127.0.0.1 -n email -C admin -M "admin@localhost" -O "Test memory critical" -X 2017-07-27-10:05:00 -Y 1
```

### Version 2.1
Notifier manual execution command :
```bash
# Generic command
./notifier.pl -t <host|service> -c <config_file_path> -r <rules_file_path> -T <YYYY-MM-DD-HH:mm:ss> -h <hostname> -A <hostgroup> -B <servicegroup> -s <servicename> -e <state> -i <hostaddress> -n <method> -C <contact_email> -O <output> -X <YYYY-MM-DD-HH:mm:ss> -Y <notification_number> -N <contact_pager>

# Exemple command
./notifier.pl -t service -c /srv/eyesofnetwork/notifier/etc/notifier.cfg -r /srv/eyesofnetwork/notifier/etc/notifier.rules -T 2017-07-27-10:05:00 -h localhost -A LINUX -B GENERIC-SERVICES -s memory -e CRITICAL -i 127.0.0.1 -n email -C "admin@localhost" -O "Test memory critical" -X 2017-07-27-10:05:00 -Y 1
```
### SQL Syntax error
If you have an SQL Syntax error at notifier execution, probably you've not authorized characters in message body as quote or doublequote. Check this.

### Tracking not work
1. Check if you’ve correctly activate tracking option in rules file (Last field on each rules file line).
2. Check if your command name have the correct form as <command_def><STATE> (example: sms-appCRITICAL).


