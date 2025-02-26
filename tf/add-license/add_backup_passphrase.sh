curl -k -i -c ./cookie-jar -H "X-Avi-Version: $AVI_VERSION" -H "X-Avi-Tenant: $AVI_TENANT_NAME" -H "Content-Type: application/json" -d '{"username": "'$AVI_USERNAME'", "password": "'$AVI_PASSWORD'"}' -POST "https://$AVI_CONTROLLER_IP/login"

AVI_CSRF_TOKEN=$(sed -nr "s/.*csrftoken\s+(.*)$/\1/p" ./cookie-jar)

curl -k -i -b ./cookie-jar -H "X-CSRFToken: $AVI_CSRF_TOKEN" -H "Referer: https://$AVI_CONTROLLER_IP/" -H "X-Avi-Tenant: $AVI_TENANT_NAME" -H "Content-Type: application/json" --data "{<license data>}"-X PUT "https://$AVI_CONTROLLER_IP/api/license"