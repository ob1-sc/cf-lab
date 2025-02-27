#!/usr/bin/env bash

avi_tenant=$1
avi_version=$2
avi_username=$3
avi_password=$4
avi_controller_ip=$5
backup_configuration_uuid=$6
backup_passphrase=$7

curl -k -i -c ./cookie-jar -H "X-Avi-Version: ${avi_version}" -H "X-Avi-Tenant: $avi_tenant" -H "Content-Type: application/json" -d '{"username": "'${avi_username}'", "password": "'${avi_password}'"}' -POST https://${avi_controller_ip}/login

avi_csrf_token=$(sed -nr "s/.*csrftoken[[:space:]]+(.*)$/\1/p" ./cookie-jar)

curl -k \
  -X PUT \
  -i \
  -b ./cookie-jar \
  -H "X-CSRFToken: ${avi_csrf_token}" \
  -H "Referer: https://${avi_controller_ip}/" \
  -H "Content-Type: application/json" \
  -d '{"name":"Backup-Configuration","backup_passphrase":"'${backup_passphrase}'","save_local":"true"}' \
  https://${avi_controller_ip}/api/backupconfiguration/${backup_configuration_uuid}