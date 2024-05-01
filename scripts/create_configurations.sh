#!/bin/bash

api_server_url="https://api.p-fra-c1.appconnect.automation.ibm.com/api"
client_id="1356949b5a7099f8efc27341aa75dbdb"
client_password="647706973b888a76080afeda380557f4"
instance_id="vnna766ye"
apiKey="azE6dXNyXzAyMWFiNzFjLWMyODUtMzg5NC1iMmZlLWY0ZDNjZDJjNjQ3NTprYWNQMnM5VURUQ2M5enhETXZUNzVTMDMyTlFPNFgyRUR5VW9XelV0d3hNPTpGc1M1"

account_configuration_name="ibm-t3-accounts"
barauth_configuration_name="ibm-t3-github-barauth"
integration_server_name="ibm-t3-integration-server"

bar_file_location="../JTH-Customer-API.bar"
bar_file_name="T3TestBar"

# Use test or prod, in lower case
ENVIRONMENT_TO_DEPLOY="test"


# Function to extract access token from JSON
extract_access_token() {
    json_str="$1"
    access_token=$(echo "$json_str" | jq -r '.access_token')
    echo "$access_token"
}

echo -e "\n\n************************  RETRIEVING ACCESS TOKEN ***********************\n"

json_structure=$(
curl --request POST \
  --url $api_server_url/v1/tokens \
  --header "X-IBM-Client-Id: $client_id" \
  --header "X-IBM-Client-Secret: $client_password" \
  --header "accept: application/json" \
  --header "content-type: application/json" \
  --header "x-ibm-instance-id: $instance_id" \
  --data '{
  "apiKey": "'"$apiKey"'"
}'
)

# Extract the access token
access_token=$(extract_access_token "$json_structure")

echo -e "\n\n************************  CREATING ACCOUNTS CONFIGURATION ***********************\n"

# Base64 encode the accounts configuration yaml file and update the value in the t3-account-config.json file
#../config/$ENVIRONMENT_TO_DEPLOY/

###### Create or update Configurations (PUT)
## Accounts Configuration
curl --request PUT \
  --url $api_server_url/v1/configurations/$account_configuration_name \
  --header "Authorization: Bearer $access_token" \
  --header "X-IBM-Client-Id: $client_id" \
  --header 'accept: application/json' \
  --header 'Content-Type: application/json' \
  --data "@t3-account-config.json"

echo -e "\n\n************************  CREATING BARAUTH CONFIGURATION ***********************\n"

#
# Note: BarAuth configuration is not needed when uploading the BAR file to the ACE dashboard,
# but left in here for future use
#

# Base64 encode the barauth configuration json file and update the value in the t3-barauth-config.json file
barauth=$( cat ../config/$ENVIRONMENT_TO_DEPLOY/t3-barauth-json.json | openssl base64)
#sed -e "s/replace-with-namespace/${DEPLOYMENT_NAMESPACE}/" -e "s~replace-with-barauth-name~${BAR_NAME}-barauth~" -e "s~replace-with-barauth-base64~${barauth}~" ${CRs_template_folder}/configuration_barauth.yaml > ${CRs_generated_folder}/configurations/barauth-generated.yaml
sed -e "s/REPLACE/${barauth}/" t3-barauth-config.json

## Barauth Configuration
curl --request PUT \
  --url $api_server_url/v1/configurations/$barauth_configuration_name \
  --header "Authorization: Bearer $access_token" \
  --header "X-IBM-Client-Id: $client_id" \
  --header 'accept: application/json' \
  --header 'Content-Type: application/json' \
  --data '@t3-barauth-config.json'

echo -e "\n\n************************  UPLOADING BAR FILE ********************************\n"

bar_file_info=$(
curl --request PUT \
  --url $api_server_url/v1/bar-files/$bar_file_name \
  --header "Authorization: Bearer $access_token" \
  --header "X-IBM-Client-Id: $client_id" \
  --header 'accept: application/json' \
  --header 'Content-Type: application/octet-stream' \
  --data-binary @$bar_file_location
)

# Extract the url value from the BAR file create / update response

bar_url=$(echo $bar_file_info|jq ".url")

# Replace the BAR URL in the integration server definition with the url value from the BAR file create / update response, and store the result in a /tmp file

cat t3-integration-server.json | jq ".spec.barURL[0] |= $bar_url" > /tmp/t3-integration-server.json

echo -e "\n\n************************  CREATING INTEGRATION SERVER ***********************\n"

  ###### Create or edit Integration Runtime with specific name (PUT)
  curl --request PUT \
    --url $api_server_url/v1/integration-runtimes/$integration_server_name \
    --header "Authorization: Bearer $access_token" \
    --header "X-IBM-Client-Id: $client_id" \
    --header 'accept: application/json' \
    --header 'Content-Type: application/json' \
    --data '@/tmp/t3-integration-server.json'
