---
name: web-fetch
description: "Use for fetching or reading web content: URLs, pages, PDFs, incomplete WebFetch output, Jina Reader, Firecrawl fallback, and X/Twitter links."
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
case "${URL}" in
  https://r.jina.ai/*|http://r.jina.ai/*) FETCH_URL="${URL}" ;;
  *) FETCH_URL="https://r.jina.ai/${URL}" ;;
esac

curl -sL "${FETCH_URL}"

# With API key (higher rate limit):
curl -sL -H "Authorization: Bearer ${JINA_API_KEY}" "${FETCH_URL}"
```

Handles JS rendering and X/Twitter. Zero local dependencies.
Do not prepend `https://r.jina.ai/` to a URL that is already a Jina Reader URL.
If Jina returns an error page, including `451` access blocks, continue to the fallback
instead of retrying with nested Reader URLs.

### Step 2: Firecrawl (fallback)

Use when Jina returns empty or an error page.

```bash
firecrawl scrape --only-main-content --format markdown "${URL}"
```

Requires `firecrawl` CLI and `FIRECRAWL_API_KEY`. Stronger anti-bot capability.

## Output

Return the fetched Markdown content directly. Do not summarize unless the user asks.
