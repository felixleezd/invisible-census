# The Invisible Census - Architecture

## Overview

The Invisible Census is a real-time intelligence platform that aggregates and analyzes reports of unsheltered individuals across San Francisco, surfacing urgent situations for outreach teams.

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    DATA COLLECTION                       │
│                      (Apify)                            │
│                                                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────┐  │
│  │ SF 311   │ │ Reddit   │ │ Twitter/ │ │ Nextdoor  │  │
│  │ API      │ │ Scraper  │ │ X Scraper│ │ Scraper   │  │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └─────┬─────┘  │
│       │             │            │              │        │
│       └─────────────┴──────┬─────┴──────────────┘        │
└────────────────────────────┼────────────────────────────┘
                             │ JSON feeds
                             ▼
┌─────────────────────────────────────────────────────────┐
│                  AGENT INTELLIGENCE                      │
│               OpenClaw (via Donely)                      │
│                                                         │
│  1. Ingest raw reports from all Apify actors            │
│  2. Geocode & cluster by proximity (< 200m)             │
│  3. Score urgency (medical keywords → CRITICAL)         │
│  4. Generate outreach briefs per cluster                 │
│  5. Dispatch alerts (Telegram / WhatsApp)               │
│                                                         │
│  Agent Config:                                          │
│  - Platform: donely.ai                                  │
│  - Agent type: OpenClaw general agent                   │
│  - Trigger: Webhook on new Apify run completion         │
│  - Output: Clustered JSON + alert dispatch              │
└────────────────────────┬────────────────────────────────┘
                         │ Processed clusters
                         ▼
┌─────────────────────────────────────────────────────────┐
│                     FRONTEND                             │
│                  Leaflet.js Map                          │
│                                                         │
│  - Dark-themed interactive map of SF                    │
│  - Color-coded urgency circles (Critical → Low)         │
│  - Click-to-dispatch outreach alerts                    │
│  - Auto-refreshes from OpenClaw output                  │
└─────────────────────────────────────────────────────────┘
```

## Data Sources (Apify Actors)

| Actor | Source | Data Extracted |
|-------|--------|----------------|
| SF 311 Scraper | `data.sfgov.org` API | Case ID, request type, description, coordinates, timestamp |
| Reddit Scraper | `r/sanfrancisco`, `r/AskSF` | Post title, body text, upvotes, comments, timestamp |
| Twitter/X Scraper | Keyword search | Tweet text, location, engagement, timestamp |
| Nextdoor Scraper | SF neighborhoods | Post text, neighborhood, reactions |
| News Scraper | SF Chronicle, local outlets | Headlines, article text, mentioned locations |

Each actor outputs standardized JSON with: `source`, `text`, `latitude`, `longitude`, `timestamp`, `urgency`.

## OpenClaw Agent Pipeline (via Donely)

The OpenClaw agent on Donely processes incoming data through these steps:

### Step 1: Ingestion
Receives webhook from Apify with raw scraped data in JSON format.

### Step 2: Geolocation Clustering
Groups reports within 200m radius using haversine distance. Merges overlapping clusters.

### Step 3: Urgency Scoring
Scores each cluster 1-20 based on:
- **Medical keywords** ("unconscious", "medical", "overdose") → +10
- **Report volume** (>5 reports in 24h) → +5
- **Recency** (last hour) → +3
- **Vulnerable mentions** ("children", "elderly") → +5

Mapping: 15+ = CRITICAL, 10-14 = HIGH, 5-9 = MEDIUM, <5 = LOW

### Step 4: Brief Generation
Produces human-readable summaries per cluster:
```
CLUSTER: SoMa / Division St
URGENCY: CRITICAL (score: 18)
REPORTS: 12 in last 24h
SUMMARY: Large encampment growing under freeway overpass.
         Multiple reports of medical distress.
ACTION:  Dispatch mobile health unit + outreach team.
```

### Step 5: Alert Dispatch
Sends formatted alerts to outreach coordinators via Telegram and WhatsApp bots.

## How to Run

```bash
# 1. Run data collection + agent pipeline
./run.sh

# 2. Open the map
open frontend/index.html
```

## Project Structure

```
invisible-census/
├── ARCHITECTURE.md          # This file
├── run.sh                   # Main pipeline script
├── frontend/
│   └── index.html           # Interactive map UI
└── output/
    ├── sf311-output.json    # SF 311 data
    └── reddit-output.json   # Reddit data
```
