---
name: grocery-planner
description: Every Sunday, researches Woolworths catalogue specials, builds a 7-day dinner menu around what's on sale, and sends a categorised shopping list to Telegram.
---

# Skill: Weekly Grocery + Menu Planner

## Purpose

Each week, research the current supermarket catalogue specials, build a 7-day menu around what's on sale, generate a consolidated categorised shopping list, and send it to Telegram.

## Schedule

Every Sunday at 9am AEST (configurable via `GROCERY_SCHEDULE` env var).

Default cron: `0 23 * * 6` (Saturday 23:00 UTC = Sunday 9:00 AEST)

Override with: `GROCERY_SCHEDULE=<cron expression>`

## Configuration (from environment)

- `GROCERY_STORE` — Name and location of the supermarket (e.g. `Woolworths Sydney`)
- `GROCERY_PREFERENCES` — Household dietary preferences (e.g. `family of 2 adults 1 child age 8, no restrictions`)
- `GROCERY_SCHEDULE` — Cron schedule override

## What to Do Each Run

### 1. Find this week's catalogue specials

Use web search to find current specials/catalogue for `$GROCERY_STORE`.
Search for: `"[store name] catalogue this week specials"`
Check the store's website directly if search results are not specific enough.

Extract:
- Items on special this week
- Approximate discounted prices
- Any buy-X-get-Y deals

### 2. Build a 7-day menu

Design 7 dinners (and optionally lunches) that:
- Centre around the week's best specials (especially meat, fish, produce)
- Match `$GROCERY_PREFERENCES`
- Are practical for the household type described
- Vary by cuisine/style across the week (no 3 pasta nights in a row)
- Include at least one batch-cook meal for leftovers

### 3. Generate categorised shopping list

Consolidate all ingredients across all 7 meals into a single list, categorised:

- Produce (fruit & vegetables)
- Meat & seafood
- Dairy & eggs
- Pantry & dry goods
- Frozen
- Bakery
- Other

Mark items that are on special this week with a star or note.

### 4. Send Telegram message

Format:

```
🛒 Weekly Grocery Plan — [Date]
━━━━━━━━━━━━━━━━━━━━━━━━━━

🏷️ THIS WEEK'S BEST SPECIALS @ [Store]
• [Item] — $[price] (was $[price])
• [Item] — $[price]
...

📅 7-DAY MENU

Mon: [Meal name]
Tue: [Meal name]
Wed: [Meal name]
Thu: [Meal name]
Fri: [Meal name]
Sat: [Meal name]
Sun: [Meal name]

🧾 SHOPPING LIST

🥦 Produce
• [item] x[qty]
...

🥩 Meat & Seafood
• [item] x[qty] ⭐ on special
...

🧀 Dairy & Eggs
• [item] x[qty]
...

🫙 Pantry
• [item] x[qty]
...

❄️ Frozen
• [item] x[qty]
...

🍞 Bakery
• [item] x[qty]
...

💬 Talk to me:
"Swap Wednesday to something vegetarian" → I'll update the plan
"Add a birthday cake for Saturday" → I'll add it with ingredients
"What should I do with the leftover chicken?" → I'll suggest recipes
```
