Zabbix-Templates
========
这里主要汇总了一些在使用zabbix过程中经常用的监控模板。
#### OS：
*	OS_Linux_Server
*	OS_Netstats
*	OS_Network_Status
*	...

#### App:
*	App_Apache_Status
*	App_Nginx_Status
*	App_Php-fpm_Status
*	...

### 使用方法:
这里使用的template基本是使用zabbix trapper的方式通过程序收集数据，通过zabbix_sendre来发送数据的方式。
使用这种方式可以有效的减轻zabbix server的压力，提高zabbix的性能。

1.需要导入xxx.xml模板文件。

2.在被监控机上部署收集数据的程序，在cron里面可以定期执行。

例如收集php-fpm status信息：
<pre>
# Get php-fpm status to zabbix
*/2 * * * * root /xxx/xxx/zabbix-scripts/php-fpm_status_analyze.sh -z 127.0.0.1 -u http://127.0.0.1:80/pm_status > /dev/null 2>&1
</pre>
