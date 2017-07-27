# Notifier.cfg
This is an exemple of notifier.cfg.  
This is to the original content of file.

```xml
<config>

	<debug>0</debug>
	<log_file>/srv/eyesofnetwork/notifier/log/notifier.log </log_file>
	
	<commands>
    		<host>
			email = /usr/bin/printf "%b" "***** Nagios  *****\\n\\nNotification Type: $NOTIFICATIONTYPE$\\nHost: $HOSTNAME$\\nState: $HOSTSTATE$\\nAddress: $HOSTADDRESS$\\nInfo: $HOSTOUTPUT$\\n\\nDate/Time: $LONGDATETIME$\\n" | /bin/mail -s "Host $HOSTSTATE$ alert for $HOSTNAME$!" $CONTACTEMAIL$

			sms = /srv/eyesofnetwork/nagios/plugins/envoi_sms.sh $CONTACTPAGER$ "$HOSTNAME$ Status: $HOSTSTATE$  $LONGDATETIME$"
			smsdouble = /srv/eyesofnetwork/nagios/plugins/envoi_sms.sh $CONTACTPAGER$ "$HOSTNAME$ Status: $HOSTSTATE$  $LONGDATETIME$ SMS Numero 1" ; /srv/eyesofnetwork/nagios/plugins/envoi_sms.sh $CONTACTPAGER$ "$HOSTNAME$ Status: $HOSTSTATE$  $LONGDATETIME$ SMS Numero 2"
	        </host>

    		<service>
			email =	/usr/bin/printf "%b" "***** Nagios  *****\\n\\nNotification Type: $NOTIFICATIONTYPE$\\n\\nService: $SERVICEDESC$\\nHost: $HOSTALIAS$\\nAddress: $HOSTADDRESS$\\nState: $SERVICESTATE$\\n\\nDate/Time: $LONGDATETIME$\\n\\nAdditional Info:\\n\\n$SERVICEOUTPUT$" | /bin/mail -s "Services $SERVICESTATE$ alert for $HOSTNAME$/$SERVICEDESC$!" $CONTACTEMAIL$

			sms = /srv/eyesofnetwork/nagios/plugins/envoi_sms.sh $CONTACTPAGER$ "$HOSTNAME$ Service: $SERVICEDESC$ Status: $SERVICESTATE$ $SERVICEOUTPUT$"
			smsdouble = /srv/eyesofnetwork/nagios/plugins/envoi_sms.sh $CONTACTPAGER$ "$HOSTNAME$ Service: $SERVICEDESC$ Status: $SERVICESTATE$ $SERVICEOUTPUT$ SMS Numero 1" ; /srv/eyesofnetwork/nagios/plugins/envoi_sms.sh $CONTACTPAGER$ "$HOSTNAME$ Service: $SERVICEDESC$ Status: $SERVICESTATE$ $SERVICEOUTPUT$ SMS Numero 2"
    		</service>
	</commands>
</config>
```

## Fields
**debug** : Active debug for notifier.
**log\_file** : Path to debug log file.
**Command** : Contain list of commands could be launched by notifier.
  **host** : Specifics command for host or hostgroup notifications.
  **service** : Specifics command for service or servicegroup notifications.
