#!/bin/bash
##################################
# Zabbix monitoring script
#
# nginx:
#  - anything available via nginx stub-status module
#
##################################
# ChangeLog:
#  2015-03-25    V2    initial creation
#  2015-08-25    V3    add absolute path to the configuration file
##################################

# Zabbix default parameter
ZABBIX_SERVER="127.0.0.1"
if [ -x /usr/bin/zabbix_sender ];then
    ZABBIX_SENDER="/usr/bin/zabbix_sender"
else
    echo "do not find zabbix_sender."
    exit 1
fi

# Nginx defaults
URL="http://127.0.0.1:80/nginx_status"
WGET="/usr/bin/wget"

#tmp file
TMP_FILE="/dev/shm/nginx_status"
#error info
ERROR_DATA="either can not connect / bad host / bad port, or cat not get intranet ip"

usage(){
cat << EOF
Usage:
This program is extract data from nginx stats to zabbix.
Options:
  --help|-h)
    Print help info.
  --zabbix-server|-z)
    Hostname or IP address of Zabbix server(default=172.16.35.92).
  --url|-u)
    nginx status default URL(default:http://127.0.0.1:80/nginx_status).
  --config|-c)
    Absolute path to the configuration file.
Example:
  ./$0 -z 127.0.0.1 -u http://localhost:80/nginx_status
EOF
}


while test -n "$1"; do
    case "$1" in
    -z|--zabbix-server)
        ZABBIX_SERVER=$2
        shift 2
        ;;
    -u|--url)
        URL=$2
        shift 2
        ;;
    -c|--config)
        CONFIG=$2
        shift 2
        ;;
    -h|--help)
        usage
        exit
        ;;
    *)
        echo "Unknown argument: $1"
        usage
        exit
        ;;
    esac
done

input_file(){
/bin/cat > $TMP_FILE <<EOF
$IP active_connections $active_connections
$IP accepted_connections $accepted_connections
$IP handled_connections $handled_connections
$IP handled_requests $handled_requests
$IP request_time $request_time
$IP reading $reading
$IP writing $writing
$IP waiting $waiting
EOF
}

# Get localhost intranet ip
IP=$(ifconfig | grep -E "(eth|bond)" -A 1 | grep addr: | grep -E "10\.|172\.16" | awk -F\: '{print $2}' | cut -d' ' -f 1)

# save the nginx stats in a variable for future parsing
NGINX_STATS=$($WGET -q $URL -O - 2)


# error during retrieve
if [ -z "$NGINX_STATS" -o -z "$IP" ]; then
  echo $ERROR_DATA
  exit 1
fi

#Now all nginx_status data acquisition
active_connections=$(echo "$NGINX_STATS" | head -1 | cut -f3 -d' ')
accepted_connections=$(echo "$NGINX_STATS" | grep -Ev '[a-zA-Z]' | cut -f2 -d' ')
handled_connections=$(echo "$NGINX_STATS" | grep -Ev '[a-zA-Z]' | cut -f3 -d' ')
handled_requests=$(echo "$NGINX_STATS" | grep -Ev '[a-zA-Z]' | cut -f4 -d' ')
request_time=$(echo "$NGINX_STATS" | grep -Ev '[a-zA-Z]' | cut -f5 -d' ')
reading=$(echo "$NGINX_STATS" | tail -1 | cut -f2 -d' ')
writing=$(echo "$NGINX_STATS" | tail -1 | cut -f4 -d' ')
waiting=$(echo "$NGINX_STATS" | tail -1 | cut -f6 -d' ')

if [ -s "$TMP_FILE" ];then
        last_request_time=$(grep "request_time" $TMP_FILE | cut -f3 -d' ')
        last_handled_requests=$(grep "handled_request" $TMP_FILE | cut -f3 -d' ')

        if [ -n "$last_request_time" -a -n "$last_handled_requests" ]; then

                difference_request_time=$(echo $request_time-$last_request_time | bc)
                difference_handled_requests=$(echo $handled_requests-$last_handled_requests | bc)

                if [ "$difference_request_time" -ge 0 -a "$difference_handled_requests" -ge 0  ];then
                        average_response_time=$(echo "scale=5;$difference_request_time/$difference_handled_requests" | bc)
                        input_file
                        /bin/cat >> $TMP_FILE <<EOF
$IP average_response_time $average_response_time
EOF
                else
                        input_file
                fi
        else
                input_file
        fi
else
        input_file
fi

if [ ! -z $CONFIG ];then
    echo $ZABBIX_SENDER -c $CONFIG -i $TMP_FILE
    $ZABBIX_SENDER -c $CONFIG -i $TMP_FILE
else
    echo $ZABBIX_SENDER -z $ZABBIX_SERVER -i $TMP_FILE
    $ZABBIX_SENDER -z $ZABBIX_SERVER -i $TMP_FILE
fi

exit 0
