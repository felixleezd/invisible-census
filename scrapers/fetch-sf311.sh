#!/bin/bash
# Fetch real SF 311 reports from data.sfgov.org (Socrata API)
# Pulls encampment + street cleaning reports with coordinates
# No API key required — free public data

set -e
mkdir -p output

echo "📡 Fetching SF 311 data from data.sfgov.org..."

# Pull recent 311 reports (encampments + street/sidewalk cleaning which often covers homeless-related)
curl -m 30 -s "https://data.sfgov.org/resource/vw6y-z8j6.json?\$where=service_name%20in('Encampments','Street%20and%20Sidewalk%20Cleaning')&\$order=requested_datetime%20DESC&\$limit=200" \
  -H "Accept: application/json" \
  -o output/sf311-raw.json

# Transform to our standard format
python3 -c "
import json

with open('output/sf311-raw.json') as f:
    raw = json.load(f)

results = []
for r in raw:
    lat = r.get('lat') or r.get('latitude')
    lon = r.get('long') or r.get('longitude')
    if not lat or not lon:
        continue
    results.append({
        'source': 'sf311',
        'caseId': r.get('service_request_id', ''),
        'timestamp': r.get('requested_datetime', ''),
        'requestType': r.get('service_name', ''),
        'description': r.get('service_details', r.get('status_notes', '')),
        'address': r.get('address', ''),
        'latitude': float(lat),
        'longitude': float(lon),
        'neighborhood': r.get('analysis_neighborhood', 'Unknown')
    })

with open('output/sf311-output.json', 'w') as f:
    json.dump(results, f, indent=2)

print(f'  ✓ {len(results)} SF 311 reports saved to output/sf311-output.json')
"
