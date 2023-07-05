#!/bin/bash
date +"%Y-%m-%d %T.%3N"
if [ -f /opt/snc_mid_server/agent/security/agent_keystore ]; then
	echo "file /opt/snc_mid_server/agent/security/agent_keystore exists"
	date +%s > /midconfig/backup_time.txt
	echo "cp /opt/snc_mid_server/agent/config.xml /midconfig/config.xml" 
	\cp /opt/snc_mid_server/agent/config.xml /midconfig/config.xml
	echo "cp /opt/snc_mid_server/agent/conf/wrapper-override.conf /midconfig/wrapper-override.conf" 
	\cp /opt/snc_mid_server/agent/conf/wrapper-override.conf /midconfig/wrapper-override.conf
	echo "cp /opt/snc_mid_server/agent/security/agent_keystore /midconfig/agent_keystore"
	\cp /opt/snc_mid_server/agent/security/agent_keystore /midconfig/agent_keystore
	if [ ! -d /midconfig/jrelibsecurity ]
	then
		echo "mkdir /midconfig/jrelibsecurity"
    	mkdir /midconfig/jrelibsecurity
	fi
	echo "cp /opt/snc_mid_server/agent/jre/lib/security/* /midconfig/jrelibsecurity"
	\cp /opt/snc_mid_server/agent/jre/lib/security/* /midconfig/jrelibsecurity 
else	
	echo "File /opt/snc_mid_server/agent/security/agent_keystore does not exist. Aborting backup of config files"
fi