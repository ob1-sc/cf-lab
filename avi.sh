#!/usr/bin/env bash

avi_tenant=admin
avi_version=31.1.1
avi_username=admin
avi_password='VMware1!VMware1!'
avi_controller_ip=192.168.20.94
path=$1

curl -k -s -o /dev/null -c ./cookie-jar -H "X-Avi-Version: ${avi_version}" -H "X-Avi-Tenant: $avi_tenant" -H "Content-Type: application/json" -d '{"username": "'${avi_username}'", "password": "'${avi_password}'"}' -POST https://${avi_controller_ip}/login

avi_csrf_token=$(sed -nr "s/.*csrftoken[[:space:]]+(.*)$/\1/p" ./cookie-jar)

curl -k \
  -X GET \
  -s \
  -b ./cookie-jar \
  -H "X-CSRFToken: ${avi_csrf_token}" \
  -H "Referer: https://${avi_controller_ip}/" \
  -H "Content-Type: application/json" \
  https://${avi_controller_ip}/api/${path}