#!/usr/bin/env bash

set -o pipefail

now=$(date +%s)
iat=$((${now} - 60)) # Issued 60 seconds in the past
exp=$((${now} + 600)) # Expires 10 minutes in the future

b64enc() { openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n'; }

header_json='{
    "typ":"JWT",
    "alg":"RS256"
}'
header=$(echo -n "${header_json}" | b64enc)

payload_json='{
    "iat":'"${iat}"',
    "exp":'"${exp}"',
    "iss":'"${APP_ID}"'
}'
payload=$(echo -n "${payload_json}" | b64enc)

header_payload="${header}.${payload}"
signature=$(openssl dgst -sha256 -sign <(echo -n "${PEM}") <(echo -n "${header_payload}") | b64enc)

jwt="${header_payload}.${signature}"

# Get an access token from the API using the installation ID of the GitHub app.
access_token=$(curl -X POST -fsSL \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $jwt" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "$ACCESS_TOKEN_API_URL" \
  | jq -r '.token')

# Retrieve a short lived runner registration token using the access token.
registration_token=$(curl -X POST -fsSL \
  -H 'Accept: application/vnd.github.v3+json' \
  -H "Authorization: Bearer $access_token" \
  -H 'X-GitHub-Api-Version: 2022-11-28' \
  "$REGISTRATION_TOKEN_API_URL" \
  | jq -r '.token')

# Register the ephemeral runner to run the job (--ephemeral ensures deregistration post job execution)
./config.sh --url $REPO_URL --token $registration_token --unattended --ephemeral && ./run.sh
