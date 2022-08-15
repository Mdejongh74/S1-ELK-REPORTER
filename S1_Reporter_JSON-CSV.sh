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
# Run following bash command to start script 'sudo ./S1_Reporter_JSON-CSV.sh'
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


# Delete old reporting data.
echo '2. Checking if SentinelOne Platform data is cleared before new download ..' 
FILE1=/var/sentinelone/import/download.json
if [ -f $FILE1 ]; then
    rm -rf $FILE1
fi
echo '     '

# Lookup S1 Auth key & Download JSON data using S1 API (GET) Call
echo '3. Checking if SentinelOne Authentication key exist for data download.'
echo '         '
FILE2=/var/sentinelone/key/auth.key
if [ ! -f $FILE2 ]; then
    echo 'ERROR: No Authentication information file found!!'
    echo 'Please enter S1 Platform config data below: '
    echo '           '
    read -p "S1 Mngmnt Console Hostname (example x.sentinelone.net): " S1URL
    echo '   '
    echo FQDN=$S1URL >> /var/sentinelone/key/auth.key
    read -p 'S1 Mngmnt Console (API)Token: ' S1KEY
    echo APIKEY=$S1KEY >> /var/sentinelone/key/auth.key
    echo '   '
fi

echo '4. Start Downloading new Platform data into dir /var/sentinelone/import/ '

source /var/sentinelone/key/auth.key
#PJ show-progress and method depreciated
wget --no-check-certificate -q --progress=bar \
 --timeout=0 \
 --header 'Authorization: ApiToken '$APIKEY \
 'https://'$FQDN'/web/api/v2.1/sites?limit=999&states=active' -O /var/sentinelone/import/download.json


# Transform S1 Platform (Global) JSON data into CSV format (global.csv) and store into /var/sentinelone dir
echo '       '
echo '5. Converting SentinelOne Platform Data (JSON) into global.csv file and storing in Dir /var/sentinelone/export.'
echo '      '

jq -c -r '.data.sites [] | [.accountId, .accountName, .activeLicenses, .createdAt, .creator, .creatorId, .expiration, .externalId, .healthStatus, .id, .isDefault, .name, .registrationToken, .siteType, .sku, .state, .suite, .totalLicenses, .unlimitedExpiration, .unlimitedLicenses, .updatedAt]' /var/sentinelone/import/download.json >> /var/sentinelone/import/total.tmp
tr -d '"[]' < /var/sentinelone/import/total.tmp >> /var/sentinelone/export/global.csv
rm -rf /var/sentinelone/import/total.tmp

# Transform S1 Platform JSON (Sites specific) data into CSV format (sites.csv) and store into /var/sentinelone dir
echo '6. Converting SentinelOne Sites Data (JSON) into sites.csv file and storing in Dir /var/sentinelone/export.'
echo '      '
jq -c -r '.data.sites [] | [.name, .id, .state, .siteType, .activeLicenses, .totalLicenses, .suite, .expiration, .accountName]' /var/sentinelone/import/download.json >> /var/sentinelone/import/sites.tmp
tr -d '"[]' < /var/sentinelone/import/sites.tmp >> /var/sentinelone/export/sites.csv 
rm -rf /var/sentinelone/import/sites.tmp

# Completed SentinelOne Collector script
echo '      '
echo 'SentinelOne MSP Reporter Script (JSON-CSV_S1Data.sh) completed.....'
echo '      '
echo 'S1 Platform CSV data files are stored in dir /var/sentinelone/export '
#
# ------------------------------------------------------------------------------------
