# Skill: Intelligent Travel Researcher

## Purpose

Autonomously discover the best possible travel itineraries for a SYD → Wroclaw (Poland) trip in August 2026, behaving like a smart travel agent — not a price alert widget.

## Schedule

Run twice daily: **8am AEST** and **8pm AEST**
- 8am AEST = 22:00 UTC (previous day)
- 8pm AEST = 10:00 UTC

Cron: `0 22,10 * * *`

## Travel Context (encode as default)

- **Traveler count:** $TRAVELER_COUNT (default: 2)
- **Origin:** Sydney, Australia — SYD (or MEL as alternate)
- **Final destination:** Wroclaw, Poland (no direct flights — must route via gateway city)
- **Must arrive in Europe by:** 8 August 2026
- **Must return to Sydney by:** approximately 29–31 August 2026
- **Outbound flexibility:** 5–8 August 2026
- **Return flexibility:** 27–31 August 2026
- **Budget threshold:** $FLIGHT_BUDGET_THRESHOLD $FLIGHT_CURRENCY total — triggers urgent alert

## Accepted European Gateway Cities for Wroclaw

| Airport | Approx. travel to Wroclaw |
|---|---|
| Berlin (BER) | ~3h train |
| Prague (PRG) | ~3.5h bus/train |
| Warsaw (WAW) | ~4h train |
| Krakow (KRK) | ~3h train |
| Vienna (VIE) | ~4h bus |

## Routing Strategies to Actively Explore

1. **Budget EU hub jump** — SYD → London/Rome/Madrid/Amsterdam, then Ryanair/Wizz Air/easyJet/LOT for ~€20–50 to a gateway city. Always search the second leg separately.

2. **Stopover city** — SYD → Singapore/Dubai/Doha/Bangkok → European hub. Flag if a 1-day stopover saves >$300. 1–2 days in Singapore or Bangkok is acceptable.

3. **Sofia family visit (preferred if reasonable)** — User's parents are in Sofia, Bulgaria (SOF). Routing: SYD → SOF (5–6 days with family) → Wroclaw area → SOF → SYD. Check this proactively every run.

4. **Multi-city booking** — Outbound to one European city, return from a different one is explicitly fine. e.g. fly into Berlin, depart from Sofia.

5. **Return via different hub** — e.g. SYD → Berlin → ... → Sofia → SYD or similar.

## What to Do Each Run

### a) Search for top 5–8 route combinations

Use web search to query Google Flights, Skyscanner, ITA Matrix, or Kayak for the most promising combinations given the constraints above.

### b) Search budget EU legs separately

For each promising long-haul route, separately search for the connecting budget flight (Ryanair/Wizz Air/easyJet) to the final gateway city.

### c) Calculate total journey cost

`total = long_haul_fare + budget_leg_fare + ~€30–60 train/bus to Wroclaw`

Convert to $FLIGHT_CURRENCY. Prices must reflect $TRAVELER_COUNT travelers.

### d) Factor travel time

A $200 cheaper flight that adds 18 hours is worth flagging but not automatically "best". Balance cost vs. journey time.

### e) Check Sofia routing

Always compare: does the SYD → SOF → Wroclaw → SOF → SYD routing cost more or less than the direct routing? Recommend accordingly.

### f) Read and update persistent memory

Memory file: `./data/flight-research.json`

**CRITICAL: Never overwrite this file. Only append/update.**

Schema:

```json
{
  "all_time_best": {
    "route": "SYD→SOF→WRO / SOF→SYD",
    "total_aud": 2180,
    "seen_on": "2026-06-12",
    "snapshot_url": "...",
    "status": "EXPIRED"
  },
  "current_best": { },
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
      { "date": "2026-06-11", "price_aud": 1980 }
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

### g) Reason about memory before each check

Before searching, read the memory file and reason:
- Is today's best better or worse than yesterday's?
- Are any routes trending UP (rising = book soon pressure)?
- Are any routes trending DOWN (falling = wait and watch)?
- Has any previously seen deal expired or jumped significantly? → add to `regrets` with note of how much was missed
- What is overall `booking_urgency` (LOW / MEDIUM / HIGH / BOOK NOW)?
  - Urgency increases as August approaches AND if prices are rising

### h) Send Telegram update

Format:

```
✈️ Travel Research Update — [Day Date, Time]
━━━━━━━━━━━━━━━━━━━━━━━━━━

🧠 MEMORY CHECK — vs yesterday
Yesterday's best: [route] — [currency] [price] total
Today's best: [route] — [currency] [price] total
[Note if deal expired or price changed]

🏆 TODAY'S BEST DEAL
[Full route description with airlines and dates]
[Currency] [total price] for [N] people | [Journey time notes]

📊 PRICE TRENDS (last 7 days)
[Route 1]: $X → $Y → $Z [trend emoji] [note]
[Route 2]: ...

😬 REGRETS LOG (deals we watched but didn't book)
• [Date]: [route] for [currency] [price] — now [price] ([+/-amount])

🆕 NEW COMBINATION FOUND TODAY (if any)
[Route description and total]

🎯 BOOKING URGENCY: [LOW/MEDIUM/HIGH/BOOK NOW]
Reasoning: [1-2 sentences]

💬 Talk to me:
"Book the [route]" → I'll send you the direct booking link
"Wait another week" → I'll keep watching and warn you if it rises
"Check [airline] options" → I'll add that to tomorrow's search

🔍 Next check: [time]
```

### i) Urgent deal alert

If ANY combination drops below `$FLIGHT_BUDGET_THRESHOLD`, send immediately:

```
🚨 DEAL ALERT — BOOK NOW

[Route]: [Currency] [price] TOTAL
This is [currency] [diff] below your threshold and [diff] below yesterday.

Historical context: This route has been $X–Y for the past [N] days.
This is the lowest price we have EVER seen for this routing.

⏰ Flight fares at this level typically last 12-48 hours.

🔗 Book outbound: [link]
🔗 Book return: [link]

Reply "I booked it" to stop monitoring, or "keep watching" to continue.
```

### j) Handle "I booked it" reply

If the user replies "I booked it" or similar:
- Stop sending flight alerts
- Save the final booked itinerary to `./data/flight-research.json` under `"booked"`
- Offer to switch to trip planning mode (accommodation, local transport, Wroclaw area guides)

## Environment Variables

- `FLIGHT_BUDGET_THRESHOLD` — AUD total budget, triggers urgent alert
- `FLIGHT_CURRENCY` — Currency for all price display (default: AUD)
- `TRAVELER_COUNT` — Number of travelers (all prices must reflect this)
