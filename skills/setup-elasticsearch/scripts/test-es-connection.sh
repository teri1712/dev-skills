#!/usr/bin/env bash

# Helper script to test the connection to Elasticsearch.
# Usage: ./test-es-connection.sh [ES_URL]
# Example: ./test-es-connection.sh http://localhost:9200

ES_URL=${1:-"http://localhost:9200"}

echo "Testing connection to Elasticsearch at ${ES_URL}..."

# Test basic connectivity
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "${ES_URL}")

if [ "$RESPONSE" -eq 200 ]; then
  echo "✅ Success: Elasticsearch is reachable! HTTP status $RESPONSE."
  
  # Fetch cluster health
  echo "Fetching cluster health..."
  curl -s "${ES_URL}/_cluster/health" | grep -o '"status":"[^"]*"'
  
  # Fetch Elasticsearch info
  echo "Elasticsearch Info:"
  curl -s "${ES_URL}/"
else
  echo "❌ Error: Could not connect to Elasticsearch at ${ES_URL}. HTTP status $RESPONSE."
  exit 1
fi
