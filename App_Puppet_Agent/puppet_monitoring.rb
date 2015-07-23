#!/usr/bin/ruby1.8

require 'yaml'
require 'time'
require 'socket'

zabbix_sender="/usr/bin/zabbix_sender"
zabbix_conf="/etc/zabbix/zabbix_agentd.conf"
zabbix_send_file="/tmp/puppet_last_run_summary"

last_run_summary = "/var/lib/puppet/state/last_run_summary.yaml"

logfile = File.open( "#{last_run_summary}" ) 
report = YAML::load(logfile)
hostname = Socket.gethostname

File.open("#{zabbix_send_file}", 'w') do |f1|
  report.each do |key,value|
      value.each do |key1,value1|
          if (key1 =~ /last_run/)
              if (Time.now.to_i-value1)>61*60
                  value1=1
              else
                  value1=0
              end
          end
          f1.puts hostname+" puppet_"+key+"_"+key1+" "+value1.to_s
      end 
  end
end
output=`"#{zabbix_sender}" -c "#{zabbix_conf}" -i "#{zabbix_send_file}"`
