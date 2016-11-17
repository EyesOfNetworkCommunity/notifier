# EyesOfNetwork advanced notifier unit.
This is the code of EyesOfNetwork advanced notifier

## NEWS
Actually, the v2.0 include the new log in SQL Database

### V2.1-rc1
The new release v2.1-rc1 include notifications tracking.
Typically, current notification traited by notifier can check previous sent notification method to automatically adapt methods to use on it.
Exemple 1:
* 1st notification sent DOWN on host with method email and sms.
* 2nd notification sent UP on host with normal notification only email. But if you choose to track these types (In rules), this method can be adapted to auto take same notifications than 1st (email and sms). Next to, if you re-send UP notification in exact same case (contact and host), the new notification take normal methos (email)

### Most important change on rules and commands configuration
* Introduce a new field in notifier.rules configuration line in end of line. This field manage notification tracking or not (0 == tracking disables, 1 == tracking enabled)
* VERY IMPORTANT : all notifications command (in notifier.cfg) MUST BE in standard format if you use specific notification with match on state !
 * Example if you have a specific command to send custom email on CRITICAL state, the command ___must be___ in format « command-nameSTATE ». You choose all name of « command-name » but the ending is compulsory in tune with nagios state. (See notifier.cfg for explicit examples)

## To think
Is necessary to create notifier database before start using EON advanced notification.

### Create database
A script exist to automaticaly create database on running system if default mysql root password as not changed :
> docs/db/create_database.sh

Just launch this script to create database.

## Roadmap
* Creation of web GUI to rules configuration 
