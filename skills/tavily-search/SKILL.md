---
name: tavily-search
description: "Web search via Tavily API. Use when asked to search the web, look up sources, find links, or research any topic. Returns relevant results with titles, URLs, and snippets."
---

# Tavily Search

Search the web using the Tavily API via curl.

## Requirements

- `TAVILY_API_KEY` must be set in the environment (it is — injected by Railway)

## How to Search

Run this curl command to perform a web search:

```bash
curl -s -X POST https://api.tavily.com/search \
  -H "Content-Type: application/json" \
  -d "{\"api_key\":\"$TAVILY_API_KEY\",\"query\":\"YOUR QUERY HERE\",\"max_results\":5,\"search_depth\":\"basic\",\"include_answer\":true}"
```

## Output

Returns JSON with:
- `answer` — a short direct answer if available
- `results` — list of `{title, url, content}` entries

## Notes

- Keep `max_results` at 3–5 to reduce token load
- Use `"search_depth":"advanced"` for more thorough results when needed
- Do NOT retry failed searches — move on with available data
