#!/bin/bash

if [[ -z $1 ]] || [[ -z $2 ]] || [[ -z $3 ]]; then echo "usage: $0 {[server] [login] [password]}"; fi

SERVER=$1
USER=$2
PASS=$3
URL=http://$SERVER/zabbix/api_jsonrpc.php
EXPORT_DIR=/etc/puppet/modules/zabbix/files/zabbix_import/$SERVER
HIERA_DIR=/etc/puppet/hieradata
BACKUP_DIR="/etc/puppet/modules/zabbix/files/backup"

AUTH=`wget -O- -o /dev/null $URL --header 'Content-Type: application/json-rpc' --post-data "{\"jsonrpc\": \"2.0\",\"method\": \"user.login\",\"params\": {\"user\": \"$USER\",\"password\": \"$PASS\"},\"id\": 3}" | cut -d'"' -f8`
if [[ -z $AUTH ]];then exit 1; fi #chech if auth done

if [ ! -d "$EXPORT_DIR" ]; then
    mkdir $EXPORT_DIR
    mkdir $EXPORT_DIR/hosts
    mkdir $EXPORT_DIR/templates
    else
    DATE=$(date +%Y%m%d-%H%M%S)
    tar zcf $BACKUP_DIR/$SERVER.$DATE.tar.gz $EXPORT_DIR >/dev/null
    rm $EXPORT_DIR/hosts/*
    rm $EXPORT_DIR/templates/*
fi


HOST_IDS=`wget -O- -o /dev/null $URL --header 'Content-Type: application/json-rpc' --post-data "{\"jsonrpc\": \"2.0\",\"method\": \"host.get\",\"params\": {\"output\": [\"hostid\"],\"selectGroups\": \"extend\"},\"auth\": \"$AUTH\",\"id\": 3}" | jq '.' | grep "hostid" | awk '{print $2}' | tr -d '"'`

for hostid in ${HOST_IDS};
    do
    xml=`wget -O- -o /dev/null $URL --header 'Content-Type: application/json-rpc' --post-data "{\"jsonrpc\": \"2.0\",\"method\": \"configuration.export\",\"params\": {\"options\": {\"hosts\": [\"$hostid\"]},\"format\": \"xml\"},\"auth\": \"$AUTH\",\"id\": 3}" | jq '.result' | sed 's/^"\(.*\)"$/\1/' | sed  's/\\n//g' | sed 's/\\\"/\"/g'`
    echo "$xml" > $EXPORT_DIR/hosts/$hostid.xml
done

TEMPLATE_IDS=`wget -O- -o /dev/null $URL --header 'Content-Type: application/json-rpc' --post-data "{\"jsonrpc\": \"2.0\",\"method\": \"template.get\",\"params\": {\"output\": \"extend\"},\"auth\": \"$AUTH\",\"id\": 3}" | jq '.' | grep "templateid" |  awk '{print $2}' | tr -d '",'`

for templateid in ${TEMPLATE_IDS};
    do
    xml=`wget -O- -o /dev/null $URL --header 'Content-Type: application/json-rpc' --post-data "{\"jsonrpc\": \"2.0\",\"method\": \"configuration.export\",\"params\": {\"options\": {\"templates\": [\"$templateid\"]},\"format\": \"xml\"},\"auth\": \"$AUTH\",\"id\": 3}" | jq '.result' | sed 's/^"\(.*\)"$/\1/' | sed 's/\\n//g' |  sed 's/\\\"/\"/g'`
    echo "$xml" > $EXPORT_DIR/templates/$templateid.xml
done



if [ -f $HIERA_DIR/$SERVER.yaml ]; then
    if [ `cat $HIERA_DIR/$SERVER.yaml | grep -o "zabbix_import_dir"` == "zabbix_import_dir" ];
        then 
        SED_ARG="-i 's/^zabbix_import_dir.*/zabbix_import_dir : $SERVER/' $HIERA_DIR/$SERVER.yaml"; eval sed $SED_ARG
        else 
        printf "\nzabbix_import_dir : $SERVER\n" >> $HIERA_DIR/$SERVER.yaml;
    fi
else
    printf "\nzabbix_import_dir : $SERVER\n" >> $HIERA_DIR/$SERVER.yaml
fi