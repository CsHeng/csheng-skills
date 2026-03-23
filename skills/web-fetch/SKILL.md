---
name: web-fetch
description: "Fetch a URL and return clean Markdown content. Use when the user pastes a URL to read, when WebFetch fails or returns incomplete content, or when the URL is on X/Twitter. Falls back through Jina Reader → Firecrawl. 中文触发：读这个链接、抓取网页内容、URL 读不到。"
---

# Web Fetch

## Purpose

Fetch a URL and return full, clean Markdown content for reading and analysis.

## Use When

- User pastes a URL and wants to read, understand, or reference its content
- URL is on X/Twitter (x.com, twitter.com) — WebFetch cannot render these
- URL points to a JS-rendered page (SPA, dynamic content)
- WebFetch returned empty, truncated, or garbled content
- Full original text is needed (code review, quoting, translation)

## Fetch Strategy

Always attempt in order. Stop at first success.

### Step 1: Jina Reader

```bash
curl -sL "https://r.jina.ai/${URL}"

# With API key (higher rate limit):
curl -sL -H "Authorization: Bearer ${JINA_API_KEY}" "https://r.jina.ai/${URL}"
```

Handles JS rendering and X/Twitter. Zero local dependencies.

### Step 2: Firecrawl (fallback)

Use when Jina returns empty or an error page.

```bash
firecrawl scrape --only-main-content --format markdown "${URL}"
```

Requires `firecrawl` CLI and `FIRECRAWL_API_KEY`. Stronger anti-bot capability.

## Output

Return the fetched Markdown content directly. Do not summarize unless the user asks.
