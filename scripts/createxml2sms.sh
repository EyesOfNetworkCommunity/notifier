#!/bin/bash
export LANG="en_US.UTF-8"

usage() {
echo "Usage :createxml2sms.sh
        -d destination
        -m Message_file_path 
	-s servicedesc
	-t longdatetime
	-S platform sms url
    "
exit 2
}

if [ "${10}" = "" ]; then usage; fi

ARGS="`echo $@ |sed -e 's:-[a-Z] :\n&:g' | sed -e 's: :;:g'`"
for i in $ARGS; do
        if [ -n "`echo ${i} | grep "^\-d"`" ]; then DESTINATION="`echo ${i} | sed -e 's: ::g' | sed -e 's:;::g' | cut -c 3-`"; if [ ! -n ${DESTINATION} ]; then usage;fi;fi
        if [ -n "`echo ${i} | grep "^\-m"`" ]; then MESSAGE_FILE="`echo ${i} | sed -e 's:;::g' | cut -c 3-`"; if [ ! -n ${MESSAGE_FILE} ]; then usage;fi;fi
        if [ -n "`echo ${i} | grep "^\-s"`" ]; then SERVICEDESC="`echo ${i} | sed -e 's:;::g' | cut -c 3-`"; if [ ! -n ${SERVICEDESC} ]; then usage;fi;fi
        if [ -n "`echo ${i} | grep "^\-t"`" ]; then LONGDATETIME="`echo ${i} | cut -c 4-`"; if [ ! -n ${LONGDATETIME} ]; then usage;fi;fi
        if [ -n "`echo ${i} | grep "^\-S"`" ]; then PLATFORMURL="`echo ${i} | sed -e 's:;::g' | cut -c 3-`"; if [ ! -n ${PLATFORMURL} ]; then usage;fi;fi
done


if [ ! -d /tmp/tmp-sendsms/ ]; then mkdir -p /tmp/tmp-sendsms/ && chown -R nagios.eyesofnetwork /tmp/tmp-sendsms ; fi


TMPFILE="/tmp/tmp-sendsms/${DESTINATION}"
DAY="`echo ${LONGDATETIME} | cut -d';' -f1`"
DAYNB="`echo ${LONGDATETIME} | cut -d';' -f3`"
MONTH="`echo ${LONGDATETIME} | cut -d';' -f 2,6 | sed 's/;/ /g'`"
TIME="`echo ${LONGDATETIME} | cut -d';' -f4`"
DATETIME="$DAY $DAYNB $MONTH $TIME"


echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<MESSAGE_GROUP xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"${PLATFORURL}\">
    <MESSAGE>" > /tmp/tmp-sendsms/${DESTINATION}.xml

cat ${MESSAGE_FILE} | sed "s:SERVICEDESC:${SERVICEDESC}:g" | sed "s/LONGDATETIME/${DATETIME}/g" >> /tmp/tmp-sendsms/${DESTINATION}.xml

echo " <DEST_GROUP>
            <DEST>
            <DEST_NAME>EON</DEST_NAME>
            <DEST_FORENAME>EON</DEST_FORENAME>
            <TERMINAL_ADDR>${DESTINATION}</TERMINAL_ADDR>            
            </DEST>
	</DEST_GROUP>
    </MESSAGE>
</MESSAGE_GROUP>" >> /tmp/tmp-sendsms/${DESTINATION}.xml

cp -af /tmp/tmp-sendsms/${DESTINATION}.xml /srv/eyesofnetwork/notifier/var/www/
wget -o /tmp/tmp-sendsms/${DESTINATION}-wget.xml -O /tmp/tmp-sendsms/${DESTINATION}-out.xml -F http://extranet.nimes.fr/extranet/test/sms/index.php?protocol=http\&serverid=2\&path=sms/${DESTINATION}.xml

rm -f /srv/eyesofnetwork/notifier/var/www/${DESTINATION}.xml

