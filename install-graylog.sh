#!/bin/bash

PASSWORD="somegraylogpassword"
ROOT_PASSWORD="somegraylogrootpassword"
WEB_HOST=127.0.0.1
WEB_PORT=9000
GEOGRAPHIC_AREA="Etc"
TZ="UTC"
SHOULD_RUN_APT_UPGRADE="true"
LOG_FILE="/var/log/graylog_installation.log"

export DEBIAN_FRONTEND=noninteractive

print_header() {
    echo
    echo "====================================================================="
    echo "                          ${1}"
    echo "====================================================================="
    echo
}

configure_file() {
    regex=${1}
    replacement=${2}
    file=${3}

    if ! grep -q -E "${regex}" "${file}"; then
        echo "${replacement}" >>"${file}"
    else
        sed -i "s~${regex}~${replacement}~" "${file}"
    fi
}

set_time_zone() {
    print_header "Setting time zone"
    apt update
    apt --no-install-recommends -y install debconf-utils
    echo "tzdata tzdata/Areas select ${GEOGRAPHIC_AREA}" | debconf-set-selections
    echo "tzdata tzdata/Zones/Europe select ${TZ}" | debconf-set-selections
}

install_dependencies() {
    print_header "Installing dependencies"
    apt-get update
    if [ ${SHOULD_RUN_APT_UPGRADE} == "true" ]; then
        apt-get upgrade -y
    fi
    apt-get install -y apt-utils apt-transport-https openjdk-17-jre-headless uuid-runtime pwgen wget gnupg curl
}

install_mongodb() {
    print_header "Installing MongoDB"
    curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc |
        gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg \
            --dearmor
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
    apt-get update && apt-get install -y mongodb-org=6.0.16 mongodb-org-server=6.0.16 mongodb-org-shell=6.0.16 mongodb-org-mongos=6.0.16 mongodb-org-tools=6.0.16
}


install_mongodb4() {
    print_header "Installing MongoDB 4.4"
    wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add -
    echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list
    apt-get update
    apt-get install -y mongodb-org=4.4.14 mongodb-org-server=4.4.14 mongodb-org-shell=4.4.14 mongodb-org-mongos=4.4.14 mongodb-org-tools=4.4.14
}


enable_and_start_mongodb() {
    systemctl daemon-reload
    systemctl enable mongod
    systemctl start mongod
}

install_elasticsearch() {
    print_header "Installing Elasticsearch"
    wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add - || exit 1
    echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list
    apt-get update && apt-get install -y elasticsearch
}

configure_elasticsearch() {
    print_header "Configuring Elasticsearch"
    configure_file "#network.host:.*" "network.host: 127.0.0.1" "/etc/elasticsearch/elasticsearch.yml"
    configure_file "#cluster.name:.*" "cluster.name: graylog" "/etc/elasticsearch/elasticsearch.yml"
    configure_file "#action.auto_create_index:.*" "action.auto_create_index: false" "/etc/elasticsearch/elasticsearch.yml"
}

enable_and_start_elasticsearch() {
    systemctl daemon-reload
    systemctl enable elasticsearch.service
    systemctl start elasticsearch.service
}

install_graylog() {
    print_header "Installing Graylog"
    wget https://packages.graylog2.org/repo/packages/graylog-4.3-repository_latest.deb || exit 1
    dpkg -i graylog-4.3-repository_latest.deb || exit 1
    apt-get update && apt-get install -y graylog-server
}

configure_graylog() {
    print_header "Configuring Graylog"
    configure_file "password_secret =.*" "password_secret = ${PASSWORD}" "/etc/graylog/server/server.conf"
    configure_file "root_password_sha2 =.*" "root_password_sha2 = $(echo -n ${ROOT_PASSWORD} | sha256sum | awk '{print $1}')" "/etc/graylog/server/server.conf"
    configure_file "#http_bind_address = 127.0.0.1:9000" "http_bind_address = 0.0.0.0:${WEB_PORT}" "/etc/graylog/server/server.conf"
    configure_file ".*elasticsearch_hosts =.*" "elasticsearch_hosts = http://127.0.0.1:9200/" "/etc/graylog/server/server.conf"
    configure_file "mongodb_uri =.*" "mongodb_uri = mongodb://localhost:27017/graylog" "/etc/graylog/server/server.conf"
}

enable_and_start_graylog() {
    systemctl daemon-reload
    systemctl enable graylog-server.service
    systemctl start graylog-server.service
}

log_service_statuses() {
    print_header "Logging service statuses"
    echo "MongoDB status:" >>"${LOG_FILE}"
    systemctl status mongod >>"${LOG_FILE}" 2>&1
    echo "MongoDB logs:" >>"${LOG_FILE}"
    if [ -f /var/log/mongodb/mongod.log ]; then
        cat /var/log/mongodb/mongod.log >>"${LOG_FILE}"
    else
        echo "MongoDB log file not found!" >>"${LOG_FILE}"
    fi

    echo "Elasticsearch status:" >>"${LOG_FILE}"
    systemctl status elasticsearch >>"${LOG_FILE}" 2>&1
    echo "Elasticsearch logs:" >>"${LOG_FILE}"
    if [ -f /var/log/elasticsearch/elasticsearch.log ]; then
        cat /var/log/elasticsearch/elasticsearch.log >>"${LOG_FILE}"
    else
        echo "Elasticsearch log file not found!" >>"${LOG_FILE}"
    fi


    echo "Graylog status:" >>"${LOG_FILE}"
    systemctl status graylog-server >>"${LOG_FILE}" 2>&1
	
	
   

    # Graylog logs
    echo "Graylog logs:" >>"${LOG_FILE}"
    if [ -f /var/log/graylog-server/server.log ]; then
        cat /var/log/graylog-server/server.log >>"${LOG_FILE}"
    else
        echo "Graylog log file not found!" >>"${LOG_FILE}"
    fi	
	
}


print_vars_and_start() {
    print_header "Starting with variables"
    echo "WEB_HOST: ${WEB_HOST}"
    echo "WEB_PORT: ${WEB_PORT}"
    echo "PASSWORD: ${PASSWORD}"
    echo "ROOT_PASSWORD: ${ROOT_PASSWORD}"
    echo "GEOGRAPHIC_AREA: ${GEOGRAPHIC_AREA}"
    echo "TZ: ${TZ}"
    echo "SHOULD_RUN_APT_UPGRADE: ${SHOULD_RUN_APT_UPGRADE}"
    echo
}


# Check if AVX is supported
if lscpu | grep -iq avx; then
    echo "AVX is supported on this system."
else
    echo "Error: AVX is not supported on this system."
    echo "CHECK THE CPU SETTINGS ON YOUR VM (on Proxmox :choose host cpu)"
	exit(2)
fi

# Get the available space on the root filesystem in gigabytes
available_space=$(df --output=avail / | tail -n 1)
available_space_gb=$((available_space / 1024 / 1024))
if (( available_space_gb >= 10 )); then
    echo "You have at least 10GB of disk space available."
else
    echo "Warning: You have less than 10GB of disk space left."
	exit(3)
fi


print_vars_and_start
sleep 5
(
    set_time_zone &&
        install_dependencies &&
        install_mongodb &&
        install_elasticsearch &&
        configure_elasticsearch &&
        install_graylog &&
        configure_graylog &&
        enable_and_start_mongodb &&
        enable_and_start_elasticsearch &&
        enable_and_start_graylog &&
		log_service_statuses &&
        (
            echo "Graylog stack installed successfully!"
			local_ip=$(hostname -I | awk '{print $1}')
            echo "Visit Graylog Web Interface at http://${local_ip}:${WEB_PORT}"
			echo "graylog-server"
			systemctl list-units --type=service --all | grep graylog-server
			grep -i "error" /var/log/graylog-server/server.log
			echo " "

			echo "mongodb"
			systemctl list-units --type=service --all | grep mongod
			grep -i "error" /var/log/mongodb/mongod.log
			echo " "


			echo "elasticsearch"
			systemctl list-units --type=service --all | grep elasticsearch
			echo " "
			
			
			
			
        )
) || exit 1
