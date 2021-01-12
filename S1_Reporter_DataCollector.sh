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

# Setup S1 Collector Program Files & Directories
DIR1=/tmp/sentinelone/
if [ ! -d $DIR1 ]; then
sudo mkdir /tmp/sentinelone/
fi

DIR2=/var/sentinelone/
if [ ! -d $DIR2 ]; then
sudo mkdir /var/sentinelone/
fi

FILE1=/tmp/sentinelone/config/sentinelone.conf
if [ ! -f $FILE1 ]; then
    sudo echo 'input {'$'\r' >> /var/sentinelone/sentinelone.conf
    sudo echo '  file {'$'\r' >> /var/sentinelone/sentinelone.conf
    sudo echo '      start_position => "beginning"'$'\r' >> /var/sentinelone/sentinelone.conf
    sudo echo '      path => "/tmp/sentinelone/S1ELK.log"'$'\r' >> /var/sentinelone/sentinelone.conf
    sudo echo '      sincedb_path => "/dev/null"'$'\r' >> /var/sentinelone/sentinelone.conf
    sudo echo '  }'$'\r' >> /var/sentinelone.conf
    sudo echo '}'$'\r' >> /var/sentinelone/sentinelone.conf
    sudo echo 'filter {'$'\r' >> /var/sentinelone/sentinelone.conf
    sudo echo '  json {'$'\r' >> /var/sentinelone/sentinelone.conf
    sudo echo '      source => "message"'$'\r' >> /var/sentinelone/sentinelone.conf
    sudo echo '  }'$'\r' >> /var/sentinelone/sentinelone.conf
    sudo echo '  date {'$'\r' >> /var/sentinelone/sentinelone.conf
    sudo echo '      match => ["createdAt", "ISO8601"]'$'\r' >> /var/sentinelone/sentinelone.conf
    sudo echo '  }'$'\r' >> /var/sentinelone/sentinelone.conf
    sudo echo '  mutate {'$'\r' >> /var/sentinelone/sentinelone.conf
    sudo echo '      remove_field => ["message", "host", "path", "@version", "@timestamp"]'$'\r' >> /var/sentinelone/sentinelone.conf
    sudo echo '  }'$'\r' >> /var/sentinelone/sentinelone.conf
    sudo echo '}'$'\r' >> /var/sentinelone/sentinelone.conf
    sudo echo 'output {'$'\r' >> /var/sentinelone/sentinelone.conf
    sudo echo '  elasticsearch {'$'\r' >> /var/sentinelone/sentinelone.conf
    sudo echo '      hosts => "http://localhost:9200"'$'\r' >> /var/sentinelone/sentinelone.conf
    sudo echo '      index => "index-msp"'$'\r' >> /var/sentinelone/sentinelone.conf
    sudo echo '  }'$'\r' >> /var/sentinelone/sentinelone.conf
    sudo echo '  stdout {}'$'\r' >> /var/sentinelone/sentinelone.conf
    sudo echo '}'$'\r' >> /var/sentinelone/sentinelone.conf
fi

# Step 1. Download SentinelOne Platform data using API-Call
sudo echo '   '
sudo read -p 'Please ENTER S1 Management Console FQDN (like x.sentinelone.net): ' s1url
sudo echo '   '
sudo read -p 'Please ENTER S1 API Key (like xxxxxxxxxxxxxxxxxxx): ' s1key
sudo echo '    '
sudo echo '1. Start Downloading new Platform data to /tmp/sentinelone/ '
sudo wget --no-check-certificate --quiet \
  --method GET \
  --timeout=0 \
  --header 'Authorization: ApiToken '$s1key \
   'https://'$s1url'/web/api/v2.1/sites?limit=999&states=active' -O /tmp/sentinelone/download.json

sudo echo '     '
sudo echo ' S1 Platform Data download completed!'
sudo echo '       '

# Step2. Transform S1 Platform data into ELK Stack Format
sudo echo '2. Transforming SentinelOne Platform data into ELK format..' 
sudo echo '   '
sudo jq ".data.sites" /tmp/sentinelone/download.json >>/tmp/sentinelone/convert.tmp
sudo jq -c '.[]' /tmp/sentinelone/convert.tmp >>/tmp/sentinelone/S1ELK.log
sudo echo '       '

# Step 3. Make backups of org S1 Platform data files for Archive Use
sudo echo '3. Making backups of downloaded SentinelOne JSON Data ..' 
sudo echo '      '
sudo cp /tmp/sentinelone/download.json /var/sentinelone/s1download_"$(date +"%y-%m-%d")".json 2>/dev/null
sudo cp /tmp/sentinelone/S1ELK.log /var/sentinelone/S1ELK_"$(date +"%y-%m-%d")".log 2>/dev/null
sudo echo '      '

# Step 4. Cleaning up temp S1 Platform collected Data
sudo echo '4. Clearing SentinelOne Old Kibana Data ..'
sudo echo '      '
sudo rm -rf /tmp/sentinelone/download.json
sudo rm -rf /tmp/sentinelone/convert.tmp
sudo echo '    '

# Step 5. Start ELK-Logstash collector to process SentinelOne Platform Data.
sudo echo '5. Starting Logstash service to process New SentinelOne Platform data into Kibana Report .. ' 
sudo echo '   '

FILE2=/etc/logstash/conf.d/sentinelone.conf
if [ ! -f $FILE2 ]; then
sudo cp /var/sentinelone/sentinelone.conf /etc/logstash/conf.d/sentinelone.conf
fi

sudo curl -X DELETE "localhost:9200/index-msp?pretty"

sudo /usr/share/logstash/bin/logstash -f /etc/logstash/conf.d/sentinelone.conf
#
# ------------------------------------------------------------------------------------
# Note:
# After data download and correct ELK data import, you can close SentinelOne Collector script + Console.
# When required, re-run script to collect new S1 info & to report within Kibana Console.
# ------------------------------------------------------------------------------------