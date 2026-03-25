#!/bin/bash
set -e
mkdir -p output

echo "🔍 Starting Invisible Census..."

# Mock SF 311 data
cat > output/sf311-output.json << 'EOF'
[
{"source":"sf311","caseId":"12345678","timestamp":"2026-03-25T22:00:00Z","requestType":"Homeless Encampment","description":"Large encampment under freeway","latitude":37.7699,"longitude":-122.4103,"neighborhood":"SoMa","urgency":8},
{"source":"sf311","caseId":"12345679","timestamp":"2026-03-25T21:00:00Z","requestType":"Homeless Person","description":"Person needs medical attention","latitude":37.7833,"longitude":-122.4167,"neighborhood":"Tenderloin","urgency":15},
{"source":"sf311","caseId":"12345680","timestamp":"2026-03-25T20:00:00Z","requestType":"Homeless Encampment","description":"Tent encampment near playground","latitude":37.7599,"longitude":-122.4148,"neighborhood":"Mission","urgency":12}
]
EOF

# Mock Reddit data
cat > output/reddit-output.json << 'EOF'
[
{"source":"reddit","subreddit":"sanfrancisco","title":"Large encampment on Division St","text":"Growing fast","timestamp":"2026-03-25T22:00:00Z","latitude":37.7699,"longitude":-122.4103,"urgency":8},
{"source":"reddit","subreddit":"AskSF","title":"Help needed in Tenderloin","text":"Medical emergency","timestamp":"2026-03-25T21:00:00Z","latitude":37.7833,"longitude":-122.4167,"urgency":15}
]
EOF

echo "✓ Data ready"
echo "🗺️ Map: Open frontend/index.html in browser"
echo "✨ Demo ready!"
