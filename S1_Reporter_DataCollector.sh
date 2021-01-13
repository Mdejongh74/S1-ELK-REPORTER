#!/bin/bash
# ------------------------------------------------------------------------------------
# Title: SentinelOne MSP Reporter Tool (S1_Reporter_DataCollector.sh)
# Version: V1.0
# Dev Date: 11-01-2021
# Developed by SentinelOne (www.sentinelone.com)
# Developer: Martin de Jongh
# Developer email: martind@sentinelone.com

#   Copyright 2021, SentinelOne
#   Licensed under the Apache License, Version 2.0 (the "License"); 
#   You may not use this Script except in compliance with the License.
#   You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and limitations under the License.
#
# ------------------------------------------------------------------------------------
# Important:
# Before executing below script to collect and Process SentinelOne Platform Data.
# Make certain you have an active ELK stack up & running or, 
# complete additional provided S1_Reporter_Install.sh script upfront to automate ELK stack installation & configuration. 
# ------------------------------------------------------------------------------------
#

# Setup Collector Program Files & Directories
echo '1. Checking if S1 Reporter directory structure is in place ..'
echo '     '
DIR1=/var/sentinelone/
if [ ! -d $DIR1 ]; then
mkdir /var/sentinelone/
fi

DIR2=/var/sentinelone/import
if [ ! -d $DIR2 ]; then
mkdir /var/sentinelone/import
fi

DIR3=/var/sentinelone/export
if [ ! -d $DIR3 ]; then
mkdir /var/sentinelone/export
fi

DIR4=/var/sentinelone/backup
if [ ! -d $DIR4 ]; then
mkdir /var/sentinelone/backup
fi

DIR5=/var/sentinelone/config
if [ ! -d $DIR5 ]; then
mkdir /var/sentinelone/config
fi

DIR6=/var/sentinelone/key
if [ ! -d $DIR6 ]; then
mkdir /var/sentinelone/key
fi


echo '2. Checking if ELK-Logstash S1 Collector File is configured..'
echo '  '
FILE1=/var/sentinelone/config/sentinelone.conf
if [ ! -f $FILE1 ]; then
    echo 'input {'$'\r' >> /var/sentinelone/config/sentinelone.conf
    echo '  file {'$'\r' >> /var/sentinelone/config/sentinelone.conf
    echo '      start_position => "beginning"'$'\r' >> /var/sentinelone/config/sentinelone.conf
    echo '      path => "/var/sentinelone/export/report.log"'$'\r' >> /var/sentinelone/config/sentinelone.conf
    echo '      sincedb_path => "/dev/null"'$'\r' >> /var/sentinelone/config/sentinelone.conf
    echo '  }'$'\r' >> /var/sentinelone/config/sentinelone.conf
    echo '}'$'\r' >> /var/sentinelone/config/sentinelone.conf
    echo 'filter {'$'\r' >> /var/sentinelone/config/sentinelone.conf
    echo '  json {'$'\r' >> /var/sentinelone/config/sentinelone.conf
    echo '      source => "message"'$'\r' >> /var/sentinelone/config/sentinelone.conf
    echo '  }'$'\r' >> /var/sentinelone/config/sentinelone.conf
    echo '  date {'$'\r' >> /var/sentinelone/config/sentinelone.conf
    echo '      match => ["createdAt", "ISO8601"]'$'\r' >> /var/sentinelone/config/sentinelone.conf
    echo '  }'$'\r' >> /var/sentinelone/config/sentinelone.conf
    echo '  mutate {'$'\r' >> /var/sentinelone/config/sentinelone.conf
    echo '      remove_field => ["message", "host", "path", "@version", "@timestamp"]'$'\r' >> /var/sentinelone/config/sentinelone.conf
    echo '  }'$'\r' >> /var/sentinelone/config/sentinelone.conf
    echo '}'$'\r' >> /var/sentinelone/config/sentinelone.conf
    echo 'output {'$'\r' >> /var/sentinelone/config/sentinelone.conf
    echo '  elasticsearch {'$'\r' >> /var/sentinelone/config/sentinelone.conf
    echo '      hosts => "http://localhost:9200"'$'\r' >> /var/sentinelone/config/sentinelone.conf
    echo '      index => "index-msp"'$'\r' >> /var/sentinelone/config/sentinelone.conf
    echo '  }'$'\r' >> /var/sentinelone/config/sentinelone.conf
    echo '  stdout {}'$'\r' >> /var/sentinelone/config/sentinelone.conf
    echo '}'$'\r' >> /var/sentinelone/config/sentinelone.conf
fi

FILE2=/etc/logstash/conf.d/sentinelone.conf
if [ ! -f $FILE2 ]; then
cp /var/sentinelone/config/sentinelone.conf /etc/logstash/conf.d/sentinelone.conf
fi

# Delete old reporting data.
echo '3. Checking if SentinelOne Platform data is cleared & archived ..' 
FILE3=/var/sentinelone/export/report.log
if [ -f $FILE3 ]; then
    rm -rf $FILE3
fi
echo '     '

# Lookup S1 Auth key & Download JSON data using S1 API (GET) Call
echo '4. Checking if SentinelOne Authentication key exist for data download.'
echo '         '
FILE4=/var/sentinelone/key/auth.key
if [ ! -f $FILE4 ]; then
    echo 'ERROR: No Authentication information file found!'
    echo 'Please enter S1 Platform config data below: '
    echo '           '
    read -p "S1 Mngmnt Console Hostname (example x.sentinelone.net): " S1URL
    echo '   '
    echo FQDN=$S1URL >> /var/sentinelone/key/auth.key
    read -p 'S1 Mngmnt Console (API)Token: ' S1KEY
    echo APIKEY=$S1KEY >> /var/sentinelone/key/auth.key
    echo '   '
fi

echo '5. Start Downloading new Platform data into dir /var/sentinelone/import/ '

source /var/sentinelone/key/auth.key
wget --no-check-certificate -q --show-progress \
 --method GET \
 --timeout=0 \
 --header 'Authorization: ApiToken '$APIKEY \
 'https://'$FQDN'/web/api/v2.1/sites?limit=999&states=active' -O /var/sentinelone/import/download.json

# Transform S1 JSON data for import into ELK
echo '       '
echo '6. Transforming SentinelOne Platform data to ELK format..' 
echo '        '
jq ".data.sites" /var/sentinelone/import/download.json >>/var/sentinelone/import/convert.json
jq -c '.[]' /var/sentinelone/import/convert.json >>/var/sentinelone/export/report.log

# Make backups of collected S1 JSON data files
echo ' 7. Making Archive backups of new SentinelOne Data ..' 
echo '      '
cp /var/sentinelone/import/download.json /var/sentinelone/backup/download_"$(date +"%y-%m-%d")".org 2>/dev/null
cp /var/sentinelone/export/report.log /var/sentinelone/backup/mspreport_"$(date +"%y-%m-%d")".log 2>/dev/null

# Clear temp collection files
echo ' 8. Cleaning up temp data files ..' 
echo '     '
rm -rf /var/sentinelone/import/download.json
rm -rf /var/sentinelone/import/convert.json

# Starting  ELK-Logstash collector to process SentinelOne Platform Data.
echo '9. Starting ELK-Logstash service to process SentinelOne Platform data for visualisation in ELK-Kibana .. ' 
echo '   '
curl -X DELETE "localhost:9200/index-msp?pretty"
/usr/share/logstash/bin/logstash -f /etc/logstash/conf.d/sentinelone.conf

# Completed SentinelOne Collector script

#
# ------------------------------------------------------------------------------------
# Note:
# After data download and correct ELK data import, you can close SentinelOne Collector script + Console.
# When required, re-run script to collect new S1 info & to report within Kibana Console.
# ------------------------------------------------------------------------------------
