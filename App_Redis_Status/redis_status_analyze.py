#!/usr/bin/python2.7
#coding:utf-8

import sys, redis, json, re, struct, time, socket, optparse
import fcntl
import struct

def get_options():
    usage = "usage: %prog [options]"
    OptionParser = optparse.OptionParser
    parser = OptionParser(usage)
    parser.add_option("-H","--host",action="store",type="string",\
        dest="redis_host",default=None,help="Redis Server redis_host")
    parser.add_option("-p","--port",action="store",type="int",\
        dest="redis_port",default=6379,help="Redis Server Port")
    parser.add_option("-a","--auth",action="store",type="string",\
        dest="redis_pass",default=None,help="Redis Server Pass")
    parser.add_option("-z","--zabbix_server",action="store",type="string",\
        dest="zabbix_server",default="127.0.0.1",help="redis_host or IP address of Zabbix server.Default is 127.0.0.1")
    parser.add_option("-P","--zabbix_port",action="store",type="int",\
        dest="zabbix_port",default=10051,help="Specify port number of server trapper running on the server. Default is 10051")
    parser.add_option("-c","--zabbix_config",action="store",type="string",\
        dest="zabbix_config",default=None,help="Absolute path to the zabbix configuration file")
    options,args = parser.parse_args()
    return options,args

class Metric(object):
    def __init__(self, host, key, value, clock=None):
        self.host = host
        self.key = key
        self.value = value
        self.clock = clock

    def __repr__(self):
        if self.clock is None:
            return 'Metric(%r, %r, %r)' % (self.host, self.key, self.value)
        return 'Metric(%r, %r, %r, %r)' % (self.host, self.key, self.value, self.clock)

def get_ip_address(ifname):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    return socket.inet_ntoa(fcntl.ioctl(
        s.fileno(),
        0x8915,
        struct.pack('256s', ifname[:15])
    )[20:24])

def match_ip_address():
    reg = re.compile(r"10\..*|172\.16\..*")
    try:
        if reg.match(get_ip_address('bond0')):
            return get_ip_address('bond0')
    except:
        pass
    try:
        if reg.match(get_ip_address('eth0')):
            return get_ip_address('eth0')
    except:
        pass
    try:
        if reg.match(get_ip_address('eth1')):
            return get_ip_address('eth1')
    except:
        sys.exit(2)

def send_to_zabbix(metrics, zabbix_host='127.0.0.1', zabbix_port=10051):
    
    j = json.dumps
    metrics_data = []
    for m in metrics:
        clock = m.clock or ('%d' % time.time())
        metrics_data.append(('{"host":%s,"key":%s,"value":%s,"clock":%s}') % (j(m.host), j(m.key), j(m.value), j(clock)))
    json_data = ('{"request":"sender data","data":[%s]}') % (','.join(metrics_data))
    data_len = struct.pack('<Q', len(json_data))
    packet = 'ZBXD\x01'+ data_len + json_data
    
    try:
        zabbix = socket.socket()
        zabbix.connect((zabbix_host, zabbix_port))
        zabbix.sendall(packet)
        resp_hdr = _recv_all(zabbix, 13)
        if not resp_hdr.startswith('ZBXD\x01') or len(resp_hdr) != 13:
            print ('Wrong zabbix response')
            return False
        resp_body_len = struct.unpack('<Q', resp_hdr[5:])[0]
        resp_body = zabbix.recv(resp_body_len)
        zabbix.close()

        resp = json.loads(resp_body)
        print resp
        if resp.get('response') != 'success':
            print ('Got error from Zabbix: %s' % resp)
            return False
        return True
    except:
        print ('Error while sending data to Zabbix')
        return False

def _recv_all(sock, count):
    buf = ''
    while len(buf)<count:
        chunk = sock.recv(count-len(buf))
        if not chunk:
            return buf
        buf += chunk
    return buf

if __name__ == "__main__":
    options,args = get_options()
    zabbix_server = options.zabbix_server
    zabbix_port = options.zabbix_port
    redis_port = options.redis_port
    redis_pass = options.redis_pass
    #如果没有指定redis host，默认获取本机的内网ip地址
    if options.redis_host:
        redis_host = options.redis_host
    else:
        redis_host = match_ip_address()

    if redis_host and redis_port:
        client = redis.Redis(host=redis_host, port=redis_port, password=redis_pass)
        server_info = client.info()

        a = []
        for i in server_info:
            a.append(Metric(redis_host, ('redis[%s]' % i), server_info[i]))

    send_to_zabbix(a, zabbix_server, zabbix_port)
