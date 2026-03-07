# OpenClaw VPS Setup — Claude Code Prompt & Railway Deployment Guide

---

## PART 1 — Claude Code Prompt

Copy and paste this entire prompt into Claude Code:

---

```
I need you to scaffold a production-ready OpenClaw deployment for Railway (a VPS-style PaaS).
This is NOT a local Mac setup — it must run headlessly as a Docker container with no GUI, 
no local model, and no filesystem persistence beyond what Railway provides.

## What to build

Set up an OpenClaw project with the following:

### Core requirements
- OpenClaw installed and configured to run as a persistent Node.js daemon
- API-only LLM configuration (no local models) — configure for Anthropic Claude Sonnet as 
  primary (this skill requires strong reasoning), with Gemini 2.5 Flash as a cheap fallback
- Telegram as the messaging interface
- All secrets stored as environment variables, never hardcoded
- A Dockerfile suitable for Railway deployment
- A railway.json or railway.toml config file
- A .env.example file listing every required environment variable with descriptions
- A .gitignore that excludes .env, node_modules, openclaw memory/data directories, and logs
- A README.md with clear setup instructions

---

### SKILL 1 — Intelligent Travel Researcher

This is NOT a simple price tracker. This is a research agent that autonomously discovers 
the best possible travel itineraries given flexible constraints. It should behave like a 
smart travel agent, not a price alert widget.

**The user's actual travel scenario (encode this as the skill's default context):**

- **Origin:** Sydney, Australia (SYD or MEL as alternates)
- **Destination:** Wroclaw, Poland — but no direct flights exist, so the agent must find 
  the best way to GET to the Wroclaw area
- **Must arrive in Europe by:** 8 August 2026
- **Must be back in Sydney by:** approximately 29-31 August 2026 (2-3 week trip)
- **Outbound flexibility:** 5-8 August 2026
- **Return flexibility:** 27-31 August 2026

**Accepted European gateway cities for the Wroclaw leg:**
The agent should know these airports are reasonable for reaching Wroclaw by train/bus:
- Berlin (BER) ~3h train
- Prague (PRG) ~3.5h bus/train  
- Warsaw (WAW) ~4h train
- Krakow (KRK) ~3h train
- Vienna (VIE) ~4h bus

**Accepted hub/stopover strategies the agent should actively explore:**

1. **Budget European hub jump:** Fly SYD → London/Rome/Madrid/Amsterdam, 
   then pick up a budget EU airline (Ryanair, Wizz Air, easyJet, LOT) 
   for ~€20-50 to Berlin/Prague/Warsaw/Krakow. 
   Agent should actively search for these second-leg fares.

2. **Stopover city stay (1-2 days):** Fly SYD → Singapore/Dubai/Doha/Bangkok → 
   European hub. A 1-2 day stopover in Singapore or Bangkok is acceptable 
   and potentially desirable. Agent should flag if a 1-day stopover saves >$300.

3. **Visit family en route:** User's parents are in Sofia, Bulgaria (SOF). 
   An itinerary like SYD → SOF (5-6 days with family) → Wroclaw area → SOF → SYD 
   is a valid and preferred option if pricing is reasonable. 
   The agent should proactively check this routing.

4. **Multi-city booking:** Outbound SYD → [European city], Return [different European city] → SYD 
   is explicitly acceptable. e.g. fly into Berlin, depart from Sofia.

5. **Return via different hub:** User is flexible on return routing too. 
   SYD → Berlin → ... → Sofia → SYD or similar is fine.

**What the skill must DO (not just check prices):**

Each run the agent should:

a) Use web search to query Google Flights, Skyscanner, ITA Matrix, or Kayak 
   for the top 5-8 most promising route combinations based on the constraints above

b) For each promising long-haul route found, separately search for the 
   connecting EU budget flight (Ryanair/Wizz Air/easyJet) to the final gateway city

c) Reason about total journey cost = long haul fare + budget leg fare + estimated train/bus 
   to Wroclaw (~€30-60)

d) Factor in travel time — a €200 cheaper flight that adds 18 hours is worth flagging but 
   not automatically "best"

e) Check if the Sofia routing makes the trip cheaper or more expensive vs direct routing, 
   and recommend accordingly

f) Maintain a persistent memory file at `./data/flight-research.json` with the 
   following structure — this is the agent's long-term brain and must NEVER be 
   overwritten, only appended to:

   ```json
   {
     "all_time_best": { 
       "route": "SYD→SOF→WRO / SOF→SYD", 
       "total_aud": 2180, 
       "seen_on": "2026-06-12", 
       "snapshot_url": "...",
       "status": "EXPIRED"
     },
     "current_best": { ... },
     "regrets": [
       {
         "route": "SYD→LHR (BA) + LHR→WAW (Ryanair)",
         "price_when_seen": 1640,
         "price_now": 1940,
         "first_seen": "2026-06-10",
         "last_seen": "2026-06-11",
         "note": "Was AUD 300 cheaper 2 days ago. Gone."
       }
     ],
     "price_history": {
       "SYD-BER-via-QR": [
         { "date": "2026-06-10", "price_aud": 2100 },
         { "date": "2026-06-11", "price_aud": 1980 },
         { "date": "2026-06-12", "price_aud": 2050 }
       ]
     },
     "trend_analysis": {
       "SYD-BER-via-QR": "RISING — up $70 over 2 days after a dip",
       "SYD-SOF-via-EK": "STABLE — within $50 range for 5 days"
     },
     "booking_urgency": "MEDIUM",
     "agent_notes": "Emirates SOF routing has been most stable. Qatar BER route volatile."
   }
   ```

g) Before each new check, the agent must READ the memory file and reason about:
   - Is today's best better or worse than yesterday's best?
   - Are any routes trending up (fares rising = book soon pressure)?
   - Are any routes trending down (fares falling = wait and watch)?
   - Has any previously seen deal now expired or gone up significantly? 
     → This goes into the "regrets" log with a note of how much was missed
   - What is the overall booking urgency (LOW / MEDIUM / HIGH / BOOK NOW)?
     Urgency should increase as August approaches AND if prices are rising

h) Send a Telegram update in this format:

   ```
   ✈️ Travel Research Update — Mon 15 Jun, 8am
   ━━━━━━━━━━━━━━━━━━━━━━━━━━
   
   🧠 MEMORY CHECK — vs yesterday
   Yesterday's best: SYD→LHR+LHR→WAW — AUD 1,640 total
   Today's best: SYD→SOF→WRO/SOF→SYD — AUD 2,180 total
   ⚠️ Yesterday's deal is GONE. The LHR+Ryanair combo jumped to AUD 1,940 overnight.
   We should have booked it. Adding to regrets log.
   
   🏆 TODAY'S BEST DEAL
   SYD → SOF (Emirates, 5 Aug) + SOF → WRO (Wizz Air, 11 Aug) + WRO → SOF + SOF → SYD
   AUD 2,180 total for 2 people | Includes 5 days with family in Sofia ❤️
   Journey outbound: 20h | Return: 18h
   
   📊 PRICE TRENDS (last 7 days)
   SYD→BER via Qatar:   $2,100 → $1,980 → $2,050  📈 volatile, currently mid-range
   SYD→SOF via Emirates: $1,450 → $1,460 → $1,440  📊 stable, holding ~$1,450
   SYD→LHR via BA:       $980 → $980 → $1,180      📈 JUMPED — something changed
   
   😬 REGRETS LOG (deals we watched but didn't book)
   • 10 Jun: SYD→LHR+LHR→WAW for AUD 1,640 — now AUD 1,940 (+$300)
   
   🆕 NEW COMBINATION FOUND TODAY
   SYD → SIN (1 night stopover, ~$80 hotel) → FRA → train to WRO
   Total: AUD 1,960 — 5h shorter journey than Emirates route
   
   🎯 BOOKING URGENCY: MEDIUM → nudging HIGH
   Reasoning: We're 8 weeks out. The cheap BA+Ryanair window closed in 48h.
   Emirates/Sofia route has been stable 5+ days — this is likely the move.
   Recommend booking within 3-5 days if it holds below AUD 2,200.
   
   💬 Talk to me:
   "Book the Emirates Sofia route" → I'll send you the direct booking link
   "Wait another week" → I'll keep watching and warn you if it rises
   "Check Lufthansa options" → I'll add that to tomorrow's search
   
   🔍 Next check: tonight 8pm
   ```

i) If ANY combination drops below FLIGHT_BUDGET_THRESHOLD, send an URGENT alert:

   ```
   🚨 DEAL ALERT — BOOK NOW
   
   SYD → SOF (Emirates) + SOF → SYD: AUD 1,890 TOTAL
   This is AUD 290 below your threshold and AUD 340 below yesterday.
   
   Historical context: This route has been $2,100–2,300 for the past 2 weeks.
   This is the lowest price we have EVER seen for this routing.
   
   ⏰ Flight fares at this level typically last 12-48 hours.
   
   🔗 Book outbound: [Skyscanner link]
   🔗 Book return: [Skyscanner link]
   
   Reply "I booked it" to stop monitoring, or "keep watching" to continue.
   ```

j) If the user replies "I booked it" or similar, the agent should:
   - Stop sending flight alerts
   - Save the final booked itinerary to memory
   - Offer to switch to "trip planning mode" (accommodation research, etc.)

**Schedule:** Run twice daily — 8am and 8pm AEST (adjust for UTC)

**Skill file location:** `skills/travel-researcher/skill.md`

**Additional env vars needed for this skill:**
```
FLIGHT_BUDGET_THRESHOLD=2500    # AUD total budget for flights, triggers urgent alert
FLIGHT_CURRENCY=AUD
TRAVELER_COUNT=2                # Number of travelers (prices should reflect this)
```

---

### SKILL 2 — Weekly Grocery + Menu Planner

Create a custom skill at `skills/grocery-planner/skill.md` that:
- Runs every Sunday at 9am AEST (configurable via GROCERY_SCHEDULE env var)
- Accepts household dietary preferences via GROCERY_PREFERENCES env var
- Accepts a supermarket name/location via GROCERY_STORE env var
- Uses web search to find that week's catalogue specials
- Builds a 7-day menu around what's on special
- Generates a consolidated, categorised shopping list (produce, dairy, meat, pantry etc.)
- Sends the menu + shopping list to Telegram in a clean, readable format

---

### File structure

```
openclaw-railway/
├── Dockerfile
├── railway.json
├── .env.example
├── .gitignore
├── README.md
├── openclaw.json
├── skills/
│   ├── travel-researcher/
│   │   └── skill.md
│   └── grocery-planner/
│       └── skill.md
├── data/                        # gitignored, mounted as Railway volume
│   └── .gitkeep
└── scripts/
    └── healthcheck.sh
```

### Dockerfile requirements
- Base image: node:20-slim
- Install OpenClaw globally via npm
- Copy skills and config
- Use a non-root user for security
- CMD starts OpenClaw in headless/daemon mode

### .env.example — must include:
```
# LLM API Keys
ANTHROPIC_API_KEY=
GEMINI_API_KEY=

# Telegram
TELEGRAM_BOT_TOKEN=
TELEGRAM_CHAT_ID=

# Travel Researcher
FLIGHT_BUDGET_THRESHOLD=2500
FLIGHT_CURRENCY=AUD
TRAVELER_COUNT=2

# Grocery Planner
GROCERY_STORE=Woolworths Sydney
GROCERY_PREFERENCES=family of 2 adults 1 child age 8, no restrictions
GROCERY_SCHEDULE=0 23 * * 6
```

Once complete, run `git init`, create an initial commit with message 
"Initial OpenClaw Railway setup", and confirm the repo is ready to push.
```

---

## PART 2 — Railway Deployment Instructions

### Step 1 — Push to GitHub

```bash
git remote add origin https://github.com/YOUR_USERNAME/openclaw-railway.git
git branch -M main
git push -u origin main
```

### Step 2 — Create Railway project

1. Go to **https://railway.com** → New Project → Deploy from GitHub repo
2. Select `openclaw-railway`
3. Railway detects the Dockerfile automatically → click **Deploy**

### Step 3 — Set environment variables

In Railway → your service → **Variables** tab → Raw Editor, paste and fill in all 
variables from `.env.example`:

**Telegram Bot Token:** Open Telegram → search `@BotFather` → `/newbot`  
**Telegram Chat ID:** Search `@userinfobot` → send any message → it replies with your ID  
**Anthropic key:** https://console.anthropic.com  
**Gemini key:** https://aistudio.google.com (free)

### Step 4 — Add persistent volume (important!)

1. Railway project → **+ New** → **Volume**
2. Attach to your service, mount path: `/app/data`
3. This preserves the flight research history and price tracking across redeploys

Without this the agent loses its price history every time you push code.

### Step 5 — Verify

1. Railway → **Logs** tab — OpenClaw should show as connected to Telegram
2. Message your bot: `"What are you working on?"`
3. It should describe the travel researcher and grocery planner skills
4. Message: `"Run a travel research check now"` to trigger it immediately without 
   waiting for the scheduled run

### Step 6 — Interact naturally

The whole point of OpenClaw is that you talk to it. Try:

- `"Focus the flight search more on the Sofia routing this week"`
- `"I actually need to be in Wroclaw by Aug 10 not Aug 8, update the constraints"`
- `"What's the cheapest combination you've found so far?"`
- `"Check Skyscanner right now for SYD to BER on August 6"`
- `"Add Bangkok as a stopover option to explore"`

The agent will update its behaviour and search strategy based on your messages.

---

### Estimated monthly cost

| Item | Cost |
|---|---|
| Railway Hobby | $5 credit |
| Anthropic Claude Sonnet (travel reasoning) | ~$2–4 |
| Gemini fallback | Free tier |
| **Total** | **~$7–9/month** |

Note: The travel researcher uses Claude Sonnet (not Haiku) because the multi-variable 
routing reasoning genuinely benefits from a smarter model. The grocery planner can 
fall back to Gemini to keep costs down.
