#!/bin/bash

ScriptName="v2.1_to_v2.1-1.sh"
PrevNotifier="/srv/eyesofnetwork/notifier"
LatestNotifier="/srv/eyesofnetwork/notifier-2.1-1"
NotAction=""

usage () {
        printf "This script is writted to simplify notifier version updates.
It'll be copy all configurations of previous version, and update symbolic link in case of standard usage.

Usage of ${ScriptName} :
        The only paramater you could specify is notifier last version path and previous version.
        If you specify parameters to script, some actions will not done :
                - Symbolic link update

        Example. Considering notifier is previous version and notifier-2.1-1 is latest version :
                bash ./v2.1_to_v2.1-1.sh /srv/eyesofnetwork/notifier/ /srv/eyesofnetwork/notifier-2.1-1/

        If you don't specify path, this script will use standard EyesOfNetwork notifier paths.
        The standard EyesOfNetwork ISO deployement path :
          - /srv/eyesofnetwork/notifier (symbolic link)
          - /srv/eyesofnetwork/notifier-2.1-1 (folder containing notifier)

        Note : This script will automaticaly launch notifier.ruls file check to sort all configuration line with missing arguments.\n"
        exit 128
}
if [ ${1} ]
then
    if [[ "${1}" -eq "help" || "${1}" -eq "-h" ]]
    then
        usage
    fi

    if [ "${1}" -ne "" ]
    then
        NotAction="symlink"
    fi
fi

ConfFolders="etc/*"
LogFolders="log"
printf "Copy configurations and logs from previous notifier version to new notifier version following command ? [Y/n]\n"
printf "rsync -av ${PrevNotifier}/${ConfFolders} ${LatestNotifier} && rsync -av ${PrevNotifier}/${LogFolders} ${LatestNotifier} ? "
read Choice
if [[ "${Choice}" == "n" || "${Choice}" == "N" ]]
then
        printf "Copy aborted\n"
        exit 2
fi
if [[ "${Choice}" == "Y" || "${Choice}" == "y" || "${Choice}" == "" ]]
then
        rsync -av ${PrevNotifier}/${ConfFolders} ${LatestNotifier}/etc && rsync -av ${PrevNotifier}/${LogFolders} ${LatestNotifier}
        if [ $? == 0 ]
        then
                printf "Copy success\n"
                Status=0
        else
                printf "Copy failed\n"
                exit 3
        fi

        if [[ ${Status} == 0 && "${NotAction}" != "symlink" ]]
        then
                rm ${PrevNotifier}
                ln -s ${LatestNotifier} ${PrevNotifier}
        fi
fi

printf "Checking config file fields.\n"
bash ./check_config_file.sh ${LatestNotifier}/etc/notifier.rules

