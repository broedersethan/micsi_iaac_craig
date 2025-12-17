#!/bin/bash
# Script de test pour vérifier l'API Semaphore
# Usage: ./test_semaphore_api.sh <SEMAPHORE_URL> <API_TOKEN> <PROJECT_ID> <TEMPLATE_ID>

SEMAPHORE_URL="${1:-http://localhost:3000}"
API_TOKEN="${2}"
PROJECT_ID="${3:-1}"
TEMPLATE_ID="${4:-2}"

if [ -z "$API_TOKEN" ]; then
    echo "Usage: $0 <SEMAPHORE_URL> <API_TOKEN> <PROJECT_ID> <TEMPLATE_ID>"
    echo "Exemple: $0 http://10.0.20.50:3000 votre_token 1 2"
    exit 1
fi

echo "Test de l'API Semaphore"
echo "URL: $SEMAPHORE_URL"
echo "Project ID: $PROJECT_ID"
echo "Template ID: $TEMPLATE_ID"
echo ""

# Test 1: Vérifier l'endpoint
echo "1. Test de l'endpoint API..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "debug": false,
    "dry_run": false,
    "diff": false,
    "extra_vars": {
      "vm_name": "test-webhook",
      "netbox_url": "https://netbox.cesi.local"
    }
  }' \
  "$SEMAPHORE_URL/api/project/$PROJECT_ID/template/$TEMPLATE_ID")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "Code HTTP: $HTTP_CODE"
echo "Réponse: $BODY"
echo ""

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
    echo "✅ Succès ! L'API fonctionne correctement."
else
    echo "❌ Erreur ! Code HTTP: $HTTP_CODE"
    echo "Vérifiez:"
    echo "  - Que le token API est correct"
    echo "  - Que l'ID du projet et du template sont corrects"
    echo "  - Que Semaphore est accessible"
fi

