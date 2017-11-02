#!/bin/bash

NormFields=9
ScriptName="check_config_file.sh"
usage () {
        printf "This script is writted to do summary check of notifier rules configuration.
It'll be just check each configuration lines fields number. This information serve to correct line with missing fields (According to documentation).

Usage of ${ScriptName} :
        The only paramater you could specify is notifier.rules path file.

        Example. Considering notifier is previous version and notifier-2.1-1 is latest version :
                bash ./${ScriptName} /srv/eyesofnetwork/notifier/etc/notifier.rules

        If you don't specify path, this script will use standard EyesOfNetwork notifier paths.
        The standard EyesOfNetwork ISO deployement path :
          - /srv/eyesofnetwork/notifier/etc/notifier.rules\n"
        exit 128
}

if [[ "${1}" == "help" || "${1}" == "h" || "${1}" == "-h" ]]
then
	usage
fi

if [ ! ${1} ]
then
	ConfigFile="/srv/eyesofnetwork/notifier/etc/notifier.rules"
else
	ConfigFile="${1}"
fi

while read LINE
do
	RightLine=$(echo ${LINE} | sed 's/ //g' | grep "[0,1]:*")
	if [ ${RightLine} ]
	then
		Fields=$(echo ${RightLine} | awk -F ':' '{print NF-1}')
		if [ ${Fields} -eq ${NormFields} ]
		then
			echo "Right number of fields (${Fields}) on line ${RightLine}"
		elif [ ${Fields} -gt ${NormFields} ]
		then
			echo "Too much fields (${Fields}) on line ${RightLine}"
		elif [ ${Fields} -lt ${NormFields} ]
		then
			echo "Missing fields (${Fields}) on line ${RightLine}"
		fi
	fi
done < ${ConfigFile}

