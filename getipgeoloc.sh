#!/bin/sh

CURL_PATH=$(which curl)
JQ_PATH=$(which jq)

# 检查是否具有 curl 命令
if [ -z "$CURL_PATH" ]; then
    echo "curl is not installed, please install curl and try again."
    exit 1
fi

# 检查是否具有 jq 命令
if [ -z "$JQ_PATH" ]; then
    echo "jq is not installed"

    # 如果是 Ubuntu，则尝试安装 jq
    if [ -f /etc/lsb-release ]; then
        echo "Attempting to install jq..."
        sudo apt update
        sudo apt install -y jq
    else
        echo "jq installation requires manual intervention on this system"
        exit 1
    fi
fi

# 使用 jq 命令获取 IP 地址信息并输出
#$CURL_PATH -s https://ipvigilante.com/$(curl -s https://ipinfo.io/ip) | $JQ_PATH '.data.latitude, .data.longitude, .data.city_name, .data.country_name'

$CURL_PATH -s https://ipinfo.io | $JQ_PATH '.loc, .city, .country'
