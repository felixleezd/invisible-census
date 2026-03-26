#!/bin/bash
set -e
mkdir -p output

echo "🔍 Starting Invisible Census Pipeline..."
echo ""

# Step 1: Fetch SF 311 data (direct from data.sfgov.org — no key needed)
echo "━━━ Step 1: SF 311 Data ━━━"
bash scrapers/fetch-sf311.sh
echo ""

# Step 2: Fetch Reddit data via Apify
echo "━━━ Step 2: Reddit Data (Apify) ━━━"
bash scrapers/fetch-reddit.sh
echo ""

# Step 3: Summary
echo "━━━ Pipeline Complete ━━━"
SF_COUNT=$(python3 -c "import json; print(len(json.load(open('output/sf311-output.json'))))" 2>/dev/null || echo "0")
REDDIT_COUNT=$(python3 -c "import json; print(len(json.load(open('output/reddit-output.json'))))" 2>/dev/null || echo "0")
echo "  📊 SF 311 reports:  ${SF_COUNT}"
echo "  📊 Reddit posts:    ${REDDIT_COUNT}"
echo ""
echo "  → Next: OpenClaw agent (via Donely) processes this data"
echo "    - Clusters by geolocation"
echo "    - Scores urgency"
echo "    - Generates outreach briefs"
echo ""
echo "🗺️  Open frontend/index.html to view the map"
echo "✨  Done!"
