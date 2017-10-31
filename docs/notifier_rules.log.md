# Notifier\_rules.log
This is an example to log file for rules full debug.

```
********************************************
date = Mon Jun 24 11:24:05 CEST 2013
Reading /srv/eyesofnetwork/notifier/etc/notifier.rules data_type: 
    *:*:*:*:*:*:*:email

#### matching rule ` *:*:*:*:*:*:*:email '....
found contact ` admin(groups=admins) ' in ` * '
found today mon in * 
found host localhost in * 
found service process_ged in * 
found state ` CRITICAL ' in ` * '
found time 11:24:05 in *
found notification number 1 in * 
current priority = 100; new priority(wildcard matching) = 7....replace with this rule
#### notify service by email
command = /usr/bin/printf "%b" "***** Nagios  *****\\n\\nNotification Type: service\\n\\nService: process_ged\\nHost: localhost\\nAddress: 127.0.0.1\\nState: CRITICAL\\n\\nDate/Time: Mon Jun 24 11:24:05 CEST 2013\\n\\nAdditional Info:\\n\\ntest" | /bin/mail -s "Services CRITICAL alert for localhost/process_ged!" root@localdomain
```
