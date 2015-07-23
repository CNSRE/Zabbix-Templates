#!/bin/bash 

tcp_send_file="/tmp/tcp_send_file"
hostname=`hostname`
zabbix_conf="/etc/zabbix/zabbix_agentd.conf"
zabbix_send="/usr/bin/zabbix_sender"
service="netstat"

function get_status()
{
    ss -a |awk '
        BEGIN{
            a["SYN-SENT"]=0;
            a["LAST-ACK"]=0;
            a["SYN-RECV"]=0;
            a["ESTAB"]=0;
            a["FIN-WAIT-1"]=0;
            a["FIN-WAIT-2"]=0;
            a["TIME-WAIT"]=0;
            a["CLOSE-WAIT"]=0;
            a["LISTEN"]=0;
            a["CLOSE"]=0;
            a["CLOSING"]=0;
        }
        {
            a[$1]+=1
        }
        END{
            for (i in a){
                print hostname,prefix"_"i,a[i]
            }
        }' hostname=${hostname} prefix=${service} > ${tcp_send_file}
}
function send2zabbix()
{
    ${zabbix_send} -c ${zabbix_conf} -i ${tcp_send_file}
    echo $?
}
get_status
send2zabbix
