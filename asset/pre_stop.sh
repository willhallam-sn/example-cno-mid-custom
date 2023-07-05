#!/bin/bash
date +"%Y-%m-%d %T.%3N" > /midconfig/pre_stop.log
echo "starting backup_config.sh" >> /midconfig/pre_stop.log
/opt/snc_mid_server/backup_config.sh >> /midconfig/pre_stop.log 2>&1
echo "cd /opt/snc_mid_server/agent" >> /midconfig/pre_stop.log
cd /opt/snc_mid_server/agent
echo "starting stop.sh" >> /midconfig/pre_stop.log
./stop.sh >> /midconfig/pre_stop.log 2>&1
date +"%Y-%m-%d %T.%3N" > /midconfig/pre_stop.log