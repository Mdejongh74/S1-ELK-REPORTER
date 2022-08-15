#!/bin/bash
# ------------------------------------------------------------------------------------
# Title: SentinelOne MSP Reporter Tool (S1_Reporter_ELK_Install.sh)
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
# This script can be used to allow automated installation of ElasticSearc, Logstash & Kibana (ELK stack) enviroment on Linux OS.
# Additionally completing configuration of Logstash service for use with SentinelOne MSP reporter Tool. 
#
# Important:*** This script requires installation user to have passwordless sudo access on system ***

# Run following bash command to start script 'sudo ./S1_Reporter_ELK_Install.sh'
# ------------------------------------------------------------------------------------
#
#
dependency_check_deb() {
java -version
if [ $? -ne 0 ]
    then
        # Installing Java 7 if it's not installed
        # sudo apt-get install openjdk-7-jre-headless -y
        sudo apt install default-jdk -y
    # Checking if java installed is less than version 7. If yes, installing Java 7. As logstash & Elasticsearch require Java 7 or later.
    elif [ "`java -version 2> /tmp/version && awk '/version/ { gsub(/"/, "", $NF); print ( $NF < 1.7 ) ? "YES" : "NO" }' /tmp/version`" == "YES" ]
        then
            # sudo apt-get install openjdk-7-jre-headless -y
            sudo apt install default-jdk
fi
}

dependency_check_rpm() {
    java -version
    if [ $? -ne 0 ]
        then
            #Installing Java 7 if it's not installed
            sudo yum install jre-1.8.0-openjdk -y
        # Checking if java installed is less than version 7. If yes, installing Java 7. As logstash & Elasticsearch require Java 7 or later.
        elif [ "`java -version 2> /tmp/version && awk '/version/ { gsub(/"/, "", $NF); print ( $NF < 1.8 ) ? "YES" : "NO" }' /tmp/version`" == "YES" ]
            then
                sudo yum install jre-1.8.0-openjdk -y
    fi
}

debian_elk() {
    # resynchronize the package index files from their sources.
    sudo apt-get update
    # Install Jq event Parser
    sudo apt-get install jq -y
    # Downloading debian package of logstash
    sudo wget --directory-prefix=/opt/ https://artifacts.elastic.co/downloads/logstash/logstash-8.3.3-amd64.deb
    # Install logstash debian package
    sudo dpkg -i /opt/logstash*.deb
    # Downloading debian package of elasticsearch
    sudo wget --directory-prefix=/opt/ https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.3.3-amd64.deb
    # Install debian package of elasticsearch
    sudo dpkg -i /opt/elasticsearch*.deb
    # Download kibana tarball in /opt
    sudo wget --directory-prefix=/opt/ https://artifacts.elastic.co/downloads/kibana/kibana-8.3.3-amd64.deb
    # Extracting kibana tarball
    sudo dpkg -i /opt/kibana*.deb
    # Starting The Services
    sudo service logstash start
    sudo service elasticsearch start
    sudo service kibana start
}

rpm_elk() {
    #Install Jq Event Parser
    sudo yum install jq -y
    #Installing wget.
    sudo yum install wget -y
    # Downloading rpm package of logstash
    sudo wget --directory-prefix=/opt/ https://artifacts.elastic.co/downloads/logstash/logstash-8.3.3-x86_64.rpm
    # Install logstash rpm package
    sudo rpm -ivh /opt/logstash*.rpm
    # Downloading rpm package of elasticsearch
    sudo wget --directory-prefix=/opt/ https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.3.3-x86_64.rpm
    # Install rpm package of elasticsearch
    sudo rpm -ivh /opt/elasticsearch*.rpm
    # Download kibana tarball in /opt
    sudo wget --directory-prefix=/opt/ https://artifacts.elastic.co/downloads/kibana/kibana-8.3.3-x86_64.rpm
    # Extracting kibana tarball
    sudo rpm -ivh /opt/kibana*.rpm
    # Starting The Services
    sudo systemctl enable logstash
    sudo systemctl start logstash
    sudo systemctl enable elasticsearch
    sudo systemctl start elasticsearch
    sudo systemctl enable kibana
    sudo systemctl start kibana
}

setup_elk() {

# Setup Collector Program Files & Directories
echo 'Checking if S1 Reporter directory structure is in place ..'
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

echo 'Checking if ELK-Logstash S1 Collector File is configured..'
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
    echo '      hosts => "https://localhost:9200"'$'\r' >> /var/sentinelone/config/sentinelone.conf
    echo '      index => "index-msp"'$'\r' >> /var/sentinelone/config/sentinelone.conf
    echo '  }'$'\r' >> /var/sentinelone/config/sentinelone.conf
    echo '  stdout {}'$'\r' >> /var/sentinelone/config/sentinelone.conf
    echo '}'$'\r' >> /var/sentinelone/config/sentinelone.conf
fi

FILE2=/etc/logstash/conf.d/sentinelone.conf
if [ ! -f $FILE2 ]; then
cp /var/sentinelone/config/sentinelone.conf /etc/logstash/conf.d/sentinelone.conf
fi
}

# Checking whether user has enough permission to run this script
sudo -n true
if [ $? -ne 0 ]
    then
        echo "This script requires user to have passwordless sudo access"
        exit
fi


# Installing ELK Stack
if [ "$(grep -Ei 'debian|buntu|mint' /etc/*release)" ]
    then
        echo " It's a Debian based system"
        dependency_check_deb
        debian_elk
        setup_elk

elif [ "$(grep -Ei 'fedora|redhat|centos' /etc/*release)" ]
    then
        echo "It's a RedHat based system."
        dependency_check_rpm
        rpm_elk
        setup_elk
else
    echo "This script doesn't support ELK installation on this OS."
fi
#
# ------------------------------------------------------------------------------------
