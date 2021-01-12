#!/bin/bash
# ------------------------------------------------------------------------------------
# Title: SentinelOne MSP Reporter Tool (JSON-CSV_S1Data.sh)
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
# ------------------------------------------------------------------------------------
# Note:
# This script can be used to convert SentinelOne Global & Site specific Platform JSON data into CSV format for 3rd party reporting use.
# ------------------------------------------------------------------------------------
#

# Setup Collector Program Files & Directories
DIR1=/tmp/sentinelone/
if [ ! -d $DIR1 ]; then
sudo mkdir /tmp/sentinelone/
fi

DIR2=/var/sentinelone/
if [ ! -d $DIR2 ]; then
sudo mkdir /var/sentinelone/
fi

# Download JSON data using S1 API (GET) Call
sudo echo '   '
sudo read -p 'Please ENTER SentinelOne Management Console FQDN (like x.sentinelone.net): ' s1url
sudo echo '   '
sudo read -p 'Please ENTER SentinelOne API Key (like xxxxxxxxxxxxxxxxxxx): ' s1key
sudo echo '    '
sudo echo '1. Start Downloading new Platform data into dir /tmp/sentinelone/ '
sudo wget --no-check-certificate --quiet \
  --method GET \
  --timeout=0 \
  --header 'Authorization: ApiToken '$s1key \
   'https://'$s1url'/web/api/v2.1/sites?limit=999&states=active' -O /tmp/sentinelone/download.json

sudo echo '     '
sudo echo 'Download Platform data completed!'
# Transform S1 Platform (Global) JSON data into CSV format (global.csv) and store into /var/sentinelone dir
sudo echo '       '
sudo echo '2. Converting SentinelOne Platform Data (JSON) into global.csv file and storing in Dir /var/sentinelone.'
sudo echo '      '
sudo jq -c -r '.data.sites [] | [.accountId, .accountName, .activeLicenses, .createdAt, .creator, .creatorId, .expiration, .externalId, .healthStatus, .id, .isDefault, .name, .registrationToken, .siteType, .sku, .state, .suite, .totalLicenses, .unlimitedExpiration, .unlimitedLicenses, .updatedAt]' /tmp/sentinelone/download.json >> /tmp/sentinelone/total.tmp
sudo tr -d '"[]' < /tmp/sentinelone/total.tmp >> /var/sentinelone/global.csv
sudo rm -rf /tmp/sentinelone/total.tmp

# Transform S1 Platform JSON (Sites specific) data into CSV format (sites.csv) and store into /var/sentinelone dir
sudo echo '       '
sudo echo '3. Converting SentinelOne Sites Data (JSON) into sites.csv file and storing in Dir /var/sentinelone.'
sudo jq -c -r '.data.sites [] | [.name, .id, .state, .siteType, .activeLicenses, .totalLicenses, .suite, .expiration, .accountName]' /tmp/sentinelone/download.json >> /tmp/sentinelone/sites.tmp
sudo tr -d '"[]' < /tmp/sentinelone/sites.tmp >> /var/sentinelone/sites.csv 
sudo rm -rf /tmp/sentinelone/sites.tmp
sudo echo '      '
sudo echo 'SentinelOne MSP Reporter Script (JSON-CSV_S1Data.sh) completed.....'
sudo echo '     '