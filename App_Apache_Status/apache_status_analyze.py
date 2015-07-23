#!/usr/bin/python
import urllib
from optparse import OptionParser
import os
from tempfile import mkstemp
import StringIO
import csv
import re
import socket
import fcntl
import struct
import commands
def fetchURL(url, user = None, passwd = None):
    if user and passwd:
        parts = url.split('://')
        url = parts[0] + "://" + user + ":" + passwd + "@" + parts[1]
    
    conn = urllib.urlopen(url)
    try:
        data = conn.read()
    finally:
        conn.close()
    return data

def clean(string, chars):
    for i in chars:
        string = string.replace(i, '')
    return string
def parse(data):
    mapping = {
        "_":"Waiting for Connection",
        "S":"Starting up",
        "R":"Reading Request",
        "W":"Sending Reply",
        "K":"Keepalive (read)",
        "D":"DNS Lookup",
        "C":"Closing connection",
        "L":"Logging",
        "G":"Gracefully finishing",
        "I":"Idle cleanup of worker",
        ".":"Open slot with no current process",
        }
    replace = '() '
    csvobj = csv.reader(StringIO.StringIO(data), delimiter = ":", skipinitialspace = True)
    ret = {}
    for (key, val) in csvobj:
        if key == 'Scoreboard':
            sb = {
                "Waiting for Connection":0,
                "Starting up":0,
                "Reading Request":0,
                "Sending Reply":0,
                "Keepalive (read)":0,
                "DNS Lookup":0,
                "Closing connection":0,
                "Logging":0,
                "Gracefully finishing":0,
                "Idle cleanup of worker":0,
                "Open slot with no current process":0,
                }
            for i in val:
                sb[mapping[i]] += 1
            ret[key] = sb
        else:
            ret[key] = val
    ret2 = {}
    for (key, val) in ret.items():
        if key == "Scoreboard":
            for (key, val) in val.items():
                ret2[clean(key, replace)] = val
        else:
            ret2[clean(key, replace)] = val
            
    return ret2

if __name__ == "__main__":

    import platform
    hostname=platform.uname()[1]

    
    url='http://127.0.0.1/server-status?auto'
    data = fetchURL(url)
    try:
        (tempfiled, tempfilepath) = mkstemp()
        tempfile = open(tempfilepath, 'wb')
    except:
        print "Error creating tmp file"
        
    try:
        try:
            data = parse(data = data)
        except csv.Error:
            parser.error("Error parsing returned data")
            
        try:
            for key, val in data.items():
                if isinstance(val,str):
                    if val.startswith("."):
                        val="0"+val
                tempfile.write("%s apache_%s %s\n" % (hostname, key, val))
            tempfile.close()
        except "bogus":
            parser.error("Error creating the file to send")
        
        try:
            zabbix_sender="/usr/bin/zabbix_sender"
            zabbix_conf="/etc/zabbix/zabbix_agentd.conf"
            zabbix_send_file=tempfilepath
            cmd="%s -c %s -i %s" % (zabbix_sender,zabbix_conf,zabbix_send_file)
            status,output=commands.getstatusoutput(cmd)
        except:
            print "something error"

    finally:
        try:
            tempfile.close()
        except:
            pass
        os.remove(tempfilepath)
