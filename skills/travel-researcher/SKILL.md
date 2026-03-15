---
name: travel-researcher
description: Searches for real SYD→Wroclaw flights for August 2026 via web search, reports specific flights with dates/airlines/prices/links every 4 hours.
---

# Skill: Travel Researcher

## Purpose

Find **real, bookable flights** from Sydney to Wroclaw (Poland) for August 2026. Report specific flights with exact dates, airlines, flight numbers, prices, and clickable booking/search links.

## Schedule

Cron: `0 */4 * * *` (every 4 hours)

## CRITICAL RULES — READ FIRST

1. **NEVER estimate, guess, or hallucinate flight prices or routes.** Only report flights you actually found via web search in THIS run. If a search returns no useful results, say "no results found" — do NOT make up data.
2. **Every flight you report MUST include ALL of these:** airline name, departure date, return date, departure/arrival times if available, price (in AUD), and a clickable URL where Pawel can see/book it.
3. **If you cannot provide a clickable link, do not report the flight.** A flight without a link is useless.
4. **When Pawel asks follow-up questions about a flight you reported, answer from your memory file.** Save all flight details to the memory file so you can reference them later.
5. **Do NOT say "I'll include details next time" or "that was from a previous session".** If you reported a flight, you must have the details. If you don't have details, you didn't actually find the flight.

## Travel Context

- **Origin:** Sydney (SYD)
- **Destination:** Wroclaw, Poland (no direct flights — route via European gateway)
- **Outbound dates:** 5–8 August 2026 (flexible within this window)
- **Return dates:** 27–31 August 2026 (flexible within this window)
- **Budget:** under $FLIGHT_BUDGET_PER_PERSON AUD per adult triggers urgent alert
- **Travelers — Solo scenario:** 1 adult
- **Travelers — Family scenario:** 2 adults + 2 children (ages 6 and 2) — both require their own seat

## Gateway Cities (fly into one of these, then train/bus to Wroclaw)

- Berlin BER (~3h train to Wroclaw)
- Warsaw WAW (~4h train)
- Krakow KRK (~3h train)
- Prague PRG (~3.5h bus/train)
- Vienna VIE (~4h bus)

## Routing Strategies

### Strategy 1: Direct to European Gateway
SYD → gateway city → SYD (single round-trip ticket).
Simplest option. Search for the cheapest direct round-trip.

### Strategy 2: Sofia Stopover (preferred if reasonable)
Pawel's parents live in Sofia (SOF). Preferred routing:
- SYD → SOF (5–6 days visiting family) → gateway city near Wroclaw → SOF → SYD
- Always check this routing. Compare cost to direct European gateway routing.

### Strategy 3: Split Ticket via Singapore (or Bangkok/KL)
Buy **two separate round-trip tickets** to exploit cheaper fares from Asian hubs:
- **Ticket A:** SYD → Singapore (SIN) → SYD — often AUD $400–600 return
- **Ticket B:** Singapore (SIN) → European gateway (BER/WAW/SOF etc.) → SIN — often much cheaper than SYD→Europe direct
- Allow 1–2 days in Singapore on each transit (fun stopover + buffer for connections)
- **Total cost = Ticket A + Ticket B** — compare against direct SYD→Europe price
- Also check Bangkok (BKK) and Kuala Lumpur (KUL) as alternative hubs — budget airlines (Scoot, AirAsia X, Jetstar) fly SYD↔these cities cheaply
- **Dates example:** Ticket A departs SYD ~3 Aug, Ticket B departs SIN ~5 Aug. Return: Ticket B arrives SIN ~28 Aug, Ticket A departs SIN ~29 Aug

### Strategy 4: Multi-city / Open-jaw (Pawel has used this before — it works well)
Book a single multi-city ticket with different inbound and outbound European cities. **Try both directions** for each city pair — the price can differ significantly depending on which city is inbound vs outbound.

For every city combination, search BOTH:
- **Direction A:** SYD → City1 → ... → City2 → SYD
- **Direction B:** SYD → City2 → ... → City1 → SYD

City pair examples to try:
| Direction A | Direction B |
|---|---|
| SYD → BER → ... → AMS → SYD | SYD → AMS → ... → BER → SYD |
| SYD → WAW → ... → SOF → SYD | SYD → SOF → ... → WAW → SYD |
| SYD → BER → ... → SOF → SYD | SYD → SOF → ... → BER → SYD |
| SYD → KRK → ... → SOF → SYD | SYD → SOF → ... → KRK → SYD |
| SYD → PRG → ... → SOF → SYD | SYD → SOF → ... → PRG → SYD |

Many airlines (especially Emirates, Qatar, Turkish) price multi-city the same or slightly more than a return. This is often the best value because Pawel can visit Wroclaw mid-trip and fly home from a different city without backtracking.

Search for these as multi-city on Google Flights or Skyscanner (not "return" — use the multi-city option). **Always report the cheapest direction for each pair.**

## How to Search — USE TAVILY (mandatory)

**You MUST use the Tavily API for every search.** Do NOT skip this step. Do NOT generate results from memory or general knowledge. If you do not call Tavily, you have no data — report "no search performed" instead.

### How to call Tavily

Run this bash command for EACH search query:

```bash
curl -s -X POST https://api.tavily.com/search \
  -H "Content-Type: application/json" \
  -d "{\"api_key\":\"$TAVILY_API_KEY\",\"query\":\"YOUR QUERY HERE\",\"max_results\":5,\"search_depth\":\"advanced\",\"include_answer\":true}"
```

Replace `YOUR QUERY HERE` with the actual search query. The response contains:
- `answer` — a short summary
- `results` — list of `{title, url, content}` with real flight data and links

**CRITICAL: If the curl command fails or returns no results, say so. Do NOT make up data to fill the gap.**

You have a maximum of **5 Tavily searches per run**. Make them count.

### Search Strategy

Pick 2–3 of the most promising search queries from this list. Rotate which ones you use across runs so you cover different options over time.

**Search query examples (use these exact patterns):**

Direct routes:
1. `Sydney to Berlin flights August 5-8 2026 return August 27-31 one adult cheapest`
2. `Sydney to Sofia flights August 2026 return cheapest Skyscanner`
3. `Sydney to Warsaw flights 5 August 2026 return 29 August cheapest Google Flights`
4. `Sydney to Krakow cheapest flights August 2026 Kayak`
5. `cheap flights Sydney to Prague August 2026`

Split ticket via Singapore (search BOTH legs separately):
6. `Sydney to Singapore return flights August 3-5 2026 return August 29-31 cheapest`
7. `Singapore to Berlin flights August 5-7 2026 return August 27-29 one adult cheapest`
8. `Singapore to Sofia flights August 2026 return cheapest Skyscanner`
9. `Singapore to Warsaw flights August 5 2026 return August 28 cheapest`

Split ticket via Bangkok/KL:
10. `Sydney to Bangkok return flights August 2026 cheapest Scoot Jetstar`
11. `Bangkok to Berlin flights August 2026 return cheapest`

Multi-city (open-jaw) — search BOTH directions:
12. `multi-city flights Sydney to Berlin August 6 Amsterdam to Sydney August 29 2026`
13. `multi-city flights Sydney to Amsterdam August 6 Berlin to Sydney August 29 2026`
14. `multi-city Sydney to Warsaw then Sofia to Sydney August 2026 Google Flights`
15. `multi-city Sydney to Sofia then Warsaw to Sydney August 2026 Google Flights`
16. `open jaw flights Sydney Sofia return Krakow Sydney August 2026`

When searching split tickets, **always report both legs with individual prices AND the combined total** so Pawel can compare against direct flights.

### Constructing Clickable Links

For every flight found, provide a link so Pawel can check/book it. Use these **verified URL patterns**:

- **Google Flights:** `https://www.google.com/travel/flights?hl=en&q=Flights+to+BER+from+SYD+on+2026-08-06+through+2026-08-29`
- **Skyscanner:** `https://www.skyscanner.com.au/transport/flights/syd/berl/2026-08-06/2026-08-29/?adultsv2=1&cabinclass=economy`
- **Kayak:** `https://www.kayak.com.au/flights/SYD-BER/2026-08-06/2026-08-29?sort=bestflight_a`

Replace the airport codes (BER/berl, WAW/wsaw, etc.) and dates with the actual values from the flight you found.

**Skyscanner city codes** (use these, not IATA codes):
- Berlin = `berl`, Warsaw = `wsaw`, Krakow = `krak`, Prague = `prag`, Vienna = `vien`, Sofia = `sofi`

**Aim for variety:** include links from at least 2 different search engines per run so Pawel can compare prices across platforms. If the web search result itself contains a direct booking URL, include that as well.

### API Rate Limiting

- Maximum **5 web searches** per run
- Wait **15 seconds** between each search
- Do NOT retry failed searches — move on
- If one search gives good results, you may skip remaining searches

## What to Report Each Run

### Required Format for EVERY Flight

```
✈️ Flight [number]: [Airline]
📅 Outbound: [date] [time if known] SYD → [stops] → [destination]
📅 Return: [date] [time if known] [destination] → [stops] → SYD
💰 Price: AUD $[price] per adult | AUD $[total] for family of 4 (2 adults + 2 children)
⏱️ Journey time: [duration] each way (approx)
🔗 Search/Book: [clickable URL]
```

Example of a GOOD report:
```
✈️ Flight 1: Qatar Airways (QR908 + QR227)
📅 Outbound: 6 Aug 2026, 21:15 SYD → Doha → Berlin (BER), arrives 7 Aug 10:30
📅 Return: 29 Aug 2026, 14:00 BER → Doha → SYD, arrives 30 Aug 22:45
💰 Price: AUD $1,420 per adult | AUD $4,550 family estimate
⏱️ Journey time: ~22h each way
🔗 Skyscanner: https://www.skyscanner.com.au/transport/flights/syd/berl/2026-08-06/2026-08-29/?adultsv2=1&cabinclass=economy
🔗 Google Flights: https://www.google.com/travel/flights?hl=en&q=Flights+to+BER+from+SYD+on+2026-08-06+through+2026-08-29
🔗 Kayak: https://www.kayak.com.au/flights/SYD-BER/2026-08-06/2026-08-29?sort=bestflight_a
```

Example of a BAD report (DO NOT DO THIS):
```
Best Route Found: Sydney → Sofia → Wroclaw
Total Price (Estimated for 2 adults, 2 children): AUD $5,420
```
This is BAD because: no airline, no dates, no times, no flight numbers, no link, says "Estimated".

## Telegram Message Template

```
✈️ Travel Research Update — [date, time]
━━━━━━━━━━━━━━━━━━━━━━━━━━

🔎 Searches performed this run:
1. [search query] → [number of results / no results]
2. [search query] → [number of results / no results]

🏆 BEST FLIGHTS FOUND THIS RUN

[Use the required format above for each flight — include ALL details]

📊 vs PREVIOUS BEST
Previous best: [route + price from memory] on [date found]
Today's best: [route + price]
Change: [+/- amount or "NEW"]

🎯 BOOKING URGENCY: [LOW/MEDIUM/HIGH/BOOK NOW]
[1 sentence reasoning]

🔗 QUICK LINKS
• Google Flights SYD→BER Aug 6-29: [url]
• Google Flights SYD→SOF Aug 5-28: [url]
• Skyscanner SYD→WAW Aug 6-29: [url]

🔍 Next check: [time]
```

## Urgent Deal Alert (per-adult < $FLIGHT_BUDGET_PER_PERSON)

```
🚨 DEAL ALERT — UNDER $[FLIGHT_BUDGET_PER_PERSON] PER ADULT!

✈️ [Airline] — [flight numbers if known]
📅 Out: [date + times] SYD → [route] → [destination]
📅 Back: [date + times] [origin] → [route] → SYD
💰 AUD $[price] per adult | AUD $[total] family
🔗 BOOK NOW: [url]

This is $[diff] below your threshold.
⏰ Fares at this level typically last 12-48 hours.

Reply "I booked it" or "keep watching"
```

## Memory File

Path: `./data/flight-research.json`

**CRITICAL: Never overwrite — only append/update fields.**

Save every flight you find with full details so you can answer follow-up questions:

```json
{
  "last_run": "2026-03-14T12:00:00Z",
  "searches_performed": ["query1", "query2"],
  "current_best": {
    "airline": "Qatar Airways",
    "flight_numbers": "QR908 + QR227",
    "route": "SYD → DOH → BER",
    "outbound_date": "2026-08-06",
    "return_date": "2026-08-29",
    "price_per_adult_aud": 1420,
    "family_total_aud": 4550,
    "search_url": "https://www.skyscanner.com.au/...",
    "found_on": "2026-03-14"
  },
  "all_flights_found": [
    {
      "airline": "...",
      "route": "...",
      "outbound_date": "...",
      "return_date": "...",
      "price_per_adult_aud": 0,
      "search_url": "...",
      "found_on": "...",
      "status": "AVAILABLE"
    }
  ],
  "price_history": {
    "SYD-BER-via-QR": [
      { "date": "2026-03-14", "price_aud": 1420 }
    ]
  },
  "booking_urgency": "LOW"
}
```

### Before Each Search

Read the memory file and:
- Compare today's findings against previous best
- Note if any previously found deal has likely expired (>48h old without reconfirmation)
- Update `booking_urgency` based on price trends and time until August

## Handling Follow-up Questions

When Pawel asks about a flight you reported:
1. Read `./data/flight-research.json`
2. Find the relevant flight in `all_flights_found`
3. Answer with the stored details including the search URL
4. NEVER say "I don't have those details" — if you reported it, the details are in your memory file

## Handle "I booked it"

- Stop sending flight alerts
- Save booked itinerary to memory file under `"booked"`
- Offer trip planning help (accommodation, local transport)

## Environment Variables

- `FLIGHT_BUDGET_PER_PERSON` — AUD per adult threshold for urgent alerts (default: 1600)
- `FLIGHT_CURRENCY` — Currency for display (default: AUD)
