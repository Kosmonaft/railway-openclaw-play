# OpenClaw Railway Deployment

An OpenClaw agent running headlessly on Railway with two skills:
- **Travel Researcher** — twice-daily flight research for SYD → Wroclaw (Aug 2026), with price history, trend analysis, and Telegram alerts
- **Grocery Planner** — weekly menu and shopping list based on supermarket specials

## Prerequisites

- [Railway account](https://railway.com)
- Telegram bot token (via [@BotFather](https://t.me/BotFather))
- Telegram chat ID (via [@userinfobot](https://t.me/userinfobot))
- [Anthropic API key](https://console.anthropic.com)
- [Gemini API key](https://aistudio.google.com) (free tier)

## Deploy to Railway

### 1. Push to GitHub

```bash
git remote add origin https://github.com/Kosmonaft/railway-openclaw-play.git
git branch -M main
git push -u origin main
```

### 2. Create Railway project

1. Go to [railway.com](https://railway.com) → **New Project** → **Deploy from GitHub repo**
2. Select `railway-openclaw-play`
3. Railway detects the Dockerfile automatically → click **Deploy**

### 3. Set environment variables

In Railway → your service → **Variables** tab → **Raw Editor**, paste and fill in all variables from `.env.example`:

| Variable | Description |
|---|---|
| `ANTHROPIC_API_KEY` | Anthropic API key (primary LLM) |
| `GEMINI_API_KEY` | Google Gemini key (fallback LLM, free tier) |
| `TELEGRAM_BOT_TOKEN` | Bot token from @BotFather |
| `TELEGRAM_CHAT_ID` | Your chat ID from @userinfobot |
| `FLIGHT_BUDGET_THRESHOLD` | AUD total budget — triggers urgent alert if beaten |
| `FLIGHT_CURRENCY` | Currency for flight prices (default: AUD) |
| `TRAVELER_COUNT` | Number of travelers (prices reflect this) |
| `GROCERY_STORE` | Supermarket name/location for specials search |
| `GROCERY_PREFERENCES` | Household dietary preferences |
| `GROCERY_SCHEDULE` | Cron schedule for grocery runs |

### 4. Add persistent volume (important!)

1. Railway project → **+ New** → **Volume**
2. Attach to your service, mount path: `/app/data`

Without this, the agent loses its flight price history on every redeploy.

### 5. Verify

1. Railway → **Logs** tab — OpenClaw should show as connected to Telegram
2. Message your bot: `"What are you working on?"`
3. Message: `"Run a travel research check now"` to trigger immediately

## Interacting with the agent

Talk to it naturally via Telegram:

- `"Focus the flight search more on the Sofia routing this week"`
- `"I need to be in Wroclaw by Aug 10 not Aug 8, update the constraints"`
- `"What's the cheapest combination you've found so far?"`
- `"Check Skyscanner right now for SYD to BER on August 6"`
- `"Add Bangkok as a stopover option to explore"`
- `"I booked it"` — stops flight monitoring, saves itinerary, offers trip planning mode

## Estimated monthly cost

| Item | Cost |
|---|---|
| Railway Hobby | $5 credit |
| Anthropic Claude Sonnet | ~$2–4 |
| Gemini fallback | Free tier |
| **Total** | **~$7–9/month** |

## Project structure

```
.
├── Dockerfile
├── railway.json
├── openclaw.json
├── .env.example
├── .gitignore
├── README.md
├── skills/
│   ├── travel-researcher/
│   │   └── skill.md
│   └── grocery-planner/
│       └── skill.md
├── data/                  # gitignored, mount as Railway volume at /app/data
│   └── .gitkeep
└── scripts/
    └── healthcheck.sh
```
