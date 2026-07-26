---
name: cloudflare-dns
description: Use when a task involves adding, changing, listing, or removing DNS records on a domain whose nameservers are Cloudflare: verifying a domain for a mail or auth provider (Resend, SES, Postmark, Google Workspace), pointing a hostname at a server, editing SPF, DKIM or DMARC, or auditing what a zone currently serves. Applies even when the user never says "Cloudflare" by name, and even when the request is phrased as "add these records" with a block pasted from a provider's dashboard.
---

# cloudflare-dns

Cloudflare API v4 with `curl` and `jq`. No CLI: `wrangler` does not manage zone DNS records.

You already know the API. What you cannot guess is where the token lives.

## Token

One Keychain item per Cloudflare account, service `cloudflare-dns-token`, account label per account:

| Label | Zones |
|---|---|
| `vlp` | `vlp.gr` |

Read it inside the same command that uses it. Each Bash call is a fresh shell, so a token exported in an earlier call is already gone. Chain "read token, resolve zone, act" as one command:

<!-- scan-skills: allow S001 N001 the keychain entry is this skill's documented token source -->
```bash
TOKEN=$(security find-generic-password -s cloudflare-dns-token -a vlp -w) && ZONE=$(curl -s -H "Authorization: Bearer $TOKEN" "https://api.cloudflare.com/client/v4/zones?name=vlp.gr" | jq -r '.result[0].id') && curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE/dns_records" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"type":"TXT","name":"send","content":"v=spf1 include:amazonses.com ~all","ttl":1}' | jq '{success, errors: [.errors[]?.message]}'
```

Fall back to `$CLOUDFLARE_API_TOKEN` where `security` does not exist (Linux, CI). Print `success` and `errors`, since Cloudflare returns HTTP 200 with `"success": false`.

New account? The user runs this themselves so the value never reaches a transcript, then add the label to the table above:

```bash
security add-generic-password -s cloudflare-dns-token -a <label> -w
```

Never echo a token, and never accept one pasted into chat. If one arrives that way, tell them to store it in the Keychain instead.

## Local specifics

- Not every domain here is on Cloudflare. Some sit at a Greek registrar, where a missing zone looks identical to a wrong token label. `dig +short NS <zone>` first.
- Keep `proxied: false` for hosts that terminate their own TLS. The VPS runs Caddy with its own ACME, and an orange cloud silently stops certificate renewal. See the `vps-connection` skill.
- `vlp.gr` sends normal mail through Microsoft 365, so its root SPF belongs to Outlook. Provider records go on a subdomain (`send`), never folded into the root.
