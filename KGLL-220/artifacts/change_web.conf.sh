#!/bin/sh

# This file is mounter in splunk docker config and exectuted upon startup

/opt/splunk/bin/splunk stop

sleep 5

cp /opt/splunk/etc/system/local/web.conf.KONG /opt/splunk/etc/system/local/web.conf
/opt/splunk/bin/splunk start > /dev/null 2>&1
