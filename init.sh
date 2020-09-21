#!/bin/bash

if [ -d /etc/zabbix ]
then 
    if [ ! -d /etc/zabbix/tmp ]
    then 
        mkdir -v /etc/zabbix/tmp
        chmod -v 777 /etc/zabbix/tmp
    fi
    if [ ! -d /etc/zabbix/scripts ]
    then
        mkdir -v /etc/zabbix/scripts
        chmod -v 777 /etc/zabbix/scripts 
    fi

    cp -v -f ./zabkins.conf /etc/zabbix/zabbix_agentd.d/
    cp -v -f ./zabkins.sh /etc/zabbix/scripts/
    cp -v -f ./jq-linux64 /etc/zabbix/scripts/
    systemctl restart zabbix-agent
fi

