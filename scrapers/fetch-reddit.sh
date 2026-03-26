#!/bin/bash
# Fetch Reddit posts about SF homelessness using Apify Reddit Scraper Lite
# Actor: trudax/reddit-scraper-lite
# Requires: APIFY_TOKEN environment variable

set -e
mkdir -p output

source .env 2>/dev/null || true
APIFY_TOKEN="${APIFY_TOKEN:?Set APIFY_TOKEN in .env}"

echo "📡 Running Apify Reddit scraper for r/sanfrancisco & r/AskSF..."

# Start the actor run and wait for it to finish (up to 120s)
RUN_RESPONSE=$(curl -s -X POST \
  "https://api.apify.com/v2/acts/trudax~reddit-scraper-lite/runs?waitForFinish=120" \
  -H "Authorization: Bearer ${APIFY_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "searches": ["homeless encampment", "unhoused", "tent encampment", "homeless san francisco"],
    "searchPosts": true,
    "searchComments": false,
    "skipComments": true,
    "sort": "new",
    "maxItems": 50,
    "proxy": {
      "useApifyProxy": true
    }
  }')

# Extract dataset ID from response
DATASET_ID=$(echo "$RUN_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['defaultDatasetId'])" 2>/dev/null)

if [ -z "$DATASET_ID" ]; then
  echo "  ✗ Failed to start Apify actor. Response:"
  echo "$RUN_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RUN_RESPONSE"
  exit 1
fi

echo "  ✓ Actor run complete. Dataset: ${DATASET_ID}"

# Fetch the results
curl -s "https://api.apify.com/v2/datasets/${DATASET_ID}/items?format=json" \
  -H "Authorization: Bearer ${APIFY_TOKEN}" \
  -o output/reddit-raw.json

# Transform to our standard format
python3 -c "
import json

with open('output/reddit-raw.json') as f:
    raw = json.load(f)

results = []
for r in raw:
    # Reddit posts don't have coordinates, so we skip geolocation here
    # OpenClaw agent handles geocoding from text mentions
    results.append({
        'source': 'reddit',
        'subreddit': r.get('communityName', r.get('subreddit', '')),
        'title': r.get('title', ''),
        'text': r.get('body', r.get('selftext', r.get('text', ''))),
        'url': r.get('url', ''),
        'timestamp': r.get('createdAt', r.get('created_utc', '')),
        'upvotes': r.get('numberOfUpvotes', r.get('score', 0)),
        'comments': r.get('numberOfComments', r.get('num_comments', 0))
    })

with open('output/reddit-output.json', 'w') as f:
    json.dump(results, f, indent=2)

print(f'  ✓ {len(results)} Reddit posts saved to output/reddit-output.json')
"
