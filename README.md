# The Invisible Census

A real-time intelligence platform that tracks San Francisco's unsheltered population by aggregating public data sources with **Apify** and processing them through an **OpenClaw** agent (via **Donely**) to surface urgent situations for outreach teams.

![Stack](https://img.shields.io/badge/Apify-Data%20Collection-00C853?style=flat-square)
![Stack](https://img.shields.io/badge/OpenClaw-Agent%20Intelligence-7C3AED?style=flat-square)
![Stack](https://img.shields.io/badge/Leaflet.js-Map%20Frontend-199900?style=flat-square)

## How It Works

```
Apify (scrape)  →  OpenClaw via Donely (analyze)  →  Leaflet Map (visualize)
```

### 1. Data Collection with Apify

We use [Apify](https://apify.com) actors to scrape and aggregate reports from multiple public sources across San Francisco:

| Apify Actor | Source | What It Collects |
|-------------|--------|------------------|
| **SF 311 Scraper** | `data.sfgov.org` API | Service requests tagged "Homeless Encampment" or "Homeless Person" with coordinates, descriptions, timestamps |
| **Reddit Scraper** | `r/sanfrancisco`, `r/AskSF` | Community posts mentioning homelessness, encampments, or people needing help |
| **Twitter/X Scraper** | Keyword search | Geotagged tweets about encampments, street conditions |
| **Nextdoor Scraper** | SF neighborhoods | Neighborhood-level reports and discussions |
| **News Scraper** | SF Chronicle, local outlets | Breaking stories with location mentions |

Each actor outputs **standardized JSON**:
```json
{
  "source": "sf311",
  "text": "Large encampment under freeway",
  "latitude": 37.7699,
  "longitude": -122.4103,
  "timestamp": "2026-03-25T22:00:00Z",
  "urgency": 8
}
```

Apify runs on a schedule and triggers a **webhook** on completion, sending the scraped data downstream.

### 2. Agent Intelligence with OpenClaw (via Donely)

The [OpenClaw](https://openclaw.ai) general agent, hosted on [Donely](https://donely.ai), receives the raw Apify data and runs a 5-step pipeline:

| Step | What It Does |
|------|--------------|
| **Ingest** | Receives webhook payload from Apify with raw JSON reports |
| **Cluster** | Groups reports within 200m using haversine distance; merges overlapping clusters |
| **Score** | Assigns urgency 1-20 based on medical keywords (+10), report volume (+5), recency (+3), vulnerable mentions (+5) |
| **Brief** | Generates human-readable outreach summaries per cluster |
| **Dispatch** | Sends alerts to outreach coordinators via Telegram/WhatsApp |

**Urgency levels:**
- **CRITICAL (15+)** — Medical distress, overdose, vulnerable individuals
- **HIGH (10-14)** — Large or growing encampments, safety concerns
- **MEDIUM (5-9)** — Stable clusters, periodic monitoring
- **LOW (<5)** — Sporadic reports, low concern

**Example agent output:**
```
CLUSTER:  SoMa / Division St
URGENCY:  CRITICAL (score: 18)
REPORTS:  14 in last 24h
SUMMARY:  Large encampment under freeway overpass.
          Multiple reports of medical distress. Growing rapidly.
ACTION:   Dispatch mobile health unit + outreach team.
```

### 3. Frontend Map (Leaflet.js)

The processed clusters are rendered on a dark-themed interactive map:
- Color-coded circles by urgency (red/orange/yellow/blue)
- Click any cluster to see the outreach brief and dispatch alerts
- Stats bar showing total reports, active clusters, and critical count
- Critical clusters pulse to draw attention

## Quick Start

```bash
# Clone the repo
git clone https://github.com/felixleezd/invisible-census.git
cd invisible-census

# Run the pipeline (uses demo data)
./run.sh

# Open the map
open frontend/index.html
```

## Project Structure

```
invisible-census/
├── README.md                # You are here
├── ARCHITECTURE.md          # Detailed system architecture
├── run.sh                   # Pipeline runner
├── frontend/
│   └── index.html           # Interactive Leaflet map
└── output/
    ├── sf311-output.json    # SF 311 data feed
    └── reddit-output.json   # Reddit data feed
```

## Tech Stack

- **[Apify](https://apify.com)** — Web scraping platform for data collection
- **[OpenClaw](https://openclaw.ai)** — General AI agent for data processing
- **[Donely](https://donely.ai)** — Agent hosting platform
- **[Leaflet.js](https://leafletjs.com)** — Interactive map rendering
- **[CartoDB](https://carto.com)** — Dark basemap tiles

## Why This Matters

San Francisco's official Point-in-Time count happens once every two years. Between counts, the city operates with outdated data. The Invisible Census provides **continuous, real-time awareness** by listening to the signals already being generated across public platforms — and routing that intelligence to the people who can act on it.
