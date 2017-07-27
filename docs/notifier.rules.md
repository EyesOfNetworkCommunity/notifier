# Notifier.ruls
This is an exemple of notifier.rules config file.  
This is to the original content of file.
```xml
<rules>
    <debug_rules> 2 </debug_rules> 
    <logrules_file> /srv/eyesofnetwork/notifier/log/notifier_rules.log </logrules_file>
    <notifsent_file> /srv/eyesofnetwork/notifier/log/notifier_send.log </notifsent_file>

    <host>
    0:*:*:-:*:*:*:*:email:0
    </host>

    <service>
    0:*:*:*:*:*:*:*:email:0
    </service>
</rules>
```

## Configuration

### Debug rules
The field **debug\ rules** turn debug on or off. But with specific levels :
 * 0 : No logs
 * 1 : Full debug logs ([see logrules\_files](#Logrules file))
 * 2 : Sent notifications logs ([see notifsent\_files](#Notifsent file))
 * 3 : Full debug logs + Sent notifications logs

### Logrules file
This field simply specify path to file will contain debuging log levels (debug 1 or 3)  
By default, the log is in /srv/eyesofnetwork/notifier/log/notifier\_rules.log

### Notifsent file
Here, you specify path to file will contain notification sended by notifier (debug 2 or 3).  
By default, the log is in /srv/eyesofnetwork/notifier/log/notifier\_send.log

### Rules
Same as [notifier.cfg](./notifier.cfg.md), you'll find two fields, **host** and **service**.  
Each according to **host and hostgroup** or **service and servicegroups** notifications rules.

The full format of notification rules is the next :
```xml
rules_debug:contact:host:service:state:dayofweek:timeperiod:notificationnumber:method:tracking
```

#### Fields
All fiels in bold could be comma separated to specify multiples values.
 * __rules\_debug__ : active full debug only on the rule.
 * __**contact**__ : person or group to notify (contact name corresponding to login)
 * __**host**__ : host(s), hostgroup to apply rule
 * __**service**__ : service(s), servicesgroup to apply rule
 * __**state**__ : state to match rule
 * __**dayofweek**__ : Day of week to would be notified by the rule
 * __**timeperiod**__ : Time range to would be notified by the rule 
 * __**notificationnumber**__ : Minimal number of notification to match the rule
 * __**method**__ : Notification method
 * __tracking__ : Activate notification method tracking. This option is design to check previous notification method on same host/service and re-use it.

You could mix hostgroups and hosts in same rules. Same for service/servicegroups.

state : UP, DOWn, UNREACHABLE, … (to host) / UP, CRITICAL, WARNING, … (to service)
dayofweek : mon,tue,web,thu,fri,sat,sun (could be \*)

You have two availables wildcard could be used in rules :
 1. - : neither
 2. * : any

### Example
#### Host
```xml
0:admin:localhost:-:*:mon,tue,wed,thu,fri:0800-1800:1:email
```
#### Service
```xml
1:admin:localhost:ssh:*:mon,tue,wed,thu,fri:0800-1800:1:email
```

