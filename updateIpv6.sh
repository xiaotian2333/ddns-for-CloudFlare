#!/bin/sh

# 区域 ID,在域名概述内可以找到
zoneId=''
# 要修改的域名，不支持使用如 @.xt-url.com 我也不知道为什么（
recordName='www.xt-url.com'
# 你的 API 密钥
apiKey=''

getIpv6Address() {
  # IPv6地址获取，一般不用改
  # 因为一般ipv6没有nat ipv6的获得可以本机获得
  # ip addr show $(ip route show default | awk '/default/ {print $5}') | awk '/inet6 / {print $2}' | awk -F/ '{print $1}' | grep -v fe80:: | grep -v ::1 | head -n 1 获取第一个
  ip addr show $(ip route show default | awk '/default/ {print $5}') | awk '/inet6 / {print $2}' | awk -F/ '{print $1}' | grep -v fe80:: | grep -v ::1 | tail -n 1 # 获取最后一个
  # 通过api获取，可以使用自己的，只要返回的是纯文本就行
  # curl -s -6 https://ifconfig.co/ip
  # curl https://api64.ipify.org
}

# 下面的就别乱改了

listRecord() {
  local zoneId=$1
  local recordName=$2
  local apiKey=$3
  local result=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zoneId/dns_records?name=$recordName" \
    -H "Content-Type:application/json" \
    -H "Authorization: Bearer $apiKey")

  local resourceId=$(echo "$result" | grep -Po '(?<="id":")[^"]+')
  local currentValue=$(echo "$result" | grep -Po '(?<="content":")[^"]+')

  local successStat=$(echo "$result" | grep -Po '(?<="success":)[^,]+')
  if [ "$successStat" != "true" ]; then
    return 1
  fi

  printf '%s\n%s' "$resourceId" "$currentValue"
}

updateRecord() {
  local zoneId=$1
  local recordName=$2
  local apiKey=$3
  local resourceId=$4
  local type=$5
  local value=$6

  local result=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zoneId/dns_records/$resourceId" \
    -H "Authorization: Bearer $apiKey" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"$type\",\"name\":\"$recordName\",\"content\":\"$value\",\"ttl\":600,\"proxied\":false}")
  local successStat=$(echo "$result" | grep -Po '(?<="success":)[^,]+')
  [ "$successStat" = "true" ]
  return $?
}

createRecord() {
  local zoneId=$1
  local recordName=$2
  local apiKey=$3
  local type=$4
  local value=$5

  local result=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zoneId/dns_records" \
    -H "Authorization: Bearer $apiKey" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"$type\",\"name\":\"$recordName\",\"content\":\"$value\",\"ttl\":600,\"proxied\":false}")
  local successStat=$(echo "$result" | grep -Po '(?<="success":)[^,]+')
  if [ "$successStat" != "true" ]; then
    return 1
  fi
  local recordId=$(echo "$result" | grep -Po '(?<="id":")[^"]+')
  echo "$recordId"
}

#start

externalIpv6Add=$(getIpv6Address)
echo "Get external ipv6 address: $externalIpv6Add"

currentStat=$(listRecord "$zoneId" "$recordName" "$apiKey")
if [ $? -eq 1 ]; then
  echo "listRecord failed, Exit"
  exit 1
fi
resourceId=$(echo "$currentStat" | sed -n '1p')
currentValue=$(echo "$currentStat" | sed -n '2p')
printf 'Get currentStat:
resourceId=%s
currentValue=%s\n' "$resourceId" "$currentValue"

if [ -z "$resourceId" ]; then
  echo "record not exist, will create first"
  #  createRecord "$zoneId" "$recordName" "$apiKey" "AAAA" "$externalIpv6Add"
  createdRecordResourceId=$(createRecord "$zoneId" "$recordName" "$apiKey" "AAAA" "$externalIpv6Add")
  if [ $? -eq 0 ]; then
    resourceId=$createdRecordResourceId
  else
    echo "Create record failed. Exit"
    exit 1
  fi

fi

if [ "$currentValue" = "$externalIpv6Add" ]; then
  echo "DNS value already same as external address, will not update, exit."
  exit 0
fi

updateRecord "$zoneId" "$recordName" "$apiKey" "$resourceId" "AAAA" "$externalIpv6Add"
if [ $? -eq 0 ]; then
  echo "update success"
else
  echo "update failed"
fi