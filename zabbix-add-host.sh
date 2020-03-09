#!/bin/bash
 IP=1.1.1.1 #IP
 HOST_NAME=example.com #Host name
 # CONSTANT VARIABLES
 ERROR='0'
 ZABBIX_USER='Admin' #Make user with API access and put name here
 ZABBIX_PASS='PASS' #Make user with API access and put password here
 API='https://SERVER/zabbix/api_jsonrpc.php'
 HOSTGROUP="\"Discovered hosts\",\"Linux Servers\",\"Virtual machines\"" #What host group to create the server in
 TEMPLATE="\"Template Module ICMP Ping\"" #What is the template ID that we want to assign to new Servers?
 PSK_IDENTITY="test"
 PSK="0000000000000000000000000000000000000000000000000000000000000000" #in hex

 request(){
	json="{\"jsonrpc\":\"2.0\",\"method\":\"$1\",\"params\":{$2},\"auth\":$3,\"id\":0}"
	echo `curl -k -s -H 'Content-Type: application/json-rpc' -d "${json}" $API`
 }

 # Authenticate with Zabbix API
 payload="\"user\":\"${ZABBIX_USER}\",\"password\":\"${ZABBIX_PASS}\""
# echo ${payload}
 AUTH_TOKEN=`echo $(request "user.login" "$payload" "null" )|jq -r .result`
 echo $AUTH_TOKEN

 # Get Groups Ids
 payload="\"output\":[\"groupid\"],\"filter\":{\"name\":[${HOSTGROUP}]}"
# echo $payload
 output=$(request "hostgroup.get" "$payload" "\"$AUTH_TOKEN\"" )
# echo $output
 groups=$(echo "$output" | jq --raw-output ".result")
 groups="$(echo -e "${groups}" | tr -d '[:space:]')"
 echo $groups

 # Get Template Ids
 payload="\"output\":[\"groupid\"],\"filter\":{\"name\":[${TEMPLATE}]}"
# echo $payload
 output=$(request "template.get" "$payload" "\"$AUTH_TOKEN\"" )
# echo $output
 template=$(echo "$output" | jq --raw-output ".result")
 template="$(echo -e "${template}" | tr -d '[:space:]')"
 echo $template

 # Create Host
 payload="\"host\":\"$HOST_NAME\",\"interfaces\":[{\"type\":1,\"main\":1,\"useip\":1,\"ip\":\"$IP\",\"dns\":\"\",\"port\":\"10050\"}],\"groups\":${groups},\"templates\":${template},\"tls_accept\":2,\"tls_connect\":2,\"tls_psk_identity\":\"${PSK_IDENTITY}\",\"tls_psk\":\"${PSK}\""
# echo $payload
 output=$(request "host.create" "$payload" "\"$AUTH_TOKEN\"" )
# echo $output
 echo $output | grep -q "hostids"
 rc=$?
 if [ $rc -ne 0 ]
  then
      echo -e "Error in adding host ${HOST_NAME} at `date`:\n"
      echo $output | grep -Po '"message":.*?[^]",'
      echo $output | grep -Po '"data":.*?[^]"'
      exit
 else
      echo -e "\nHost ${HOST_NAME} added successfully\n"
      # start zabbix agent
      #service zabbix-agent start
      exit
 fi
