# Indicators of compromise / Kompromitteringsindikatorer

TLP:CLEAR. Sensitive values are redacted. Domains are defanged.
TLP:CLEAR. Sensitive verdier er sladdet. Domener er defanget.

| Type | Indicator | Context | Public |
|---|---|---|---|
| telegram-bot-token | `[REDACTED]` | `config.php`, exfiltration endpoint | No |
| telegram-chat-id | `[REDACTED]` | `config.php`, receiving chat | No |
| telegram-handle | `@[REDACTED]` | Footer in every exfil message | No |
| api-key | `[REDACTED]` | `pro.ip-api.com` key in `block.php` | No |
| domain | `bankld[.][REDACTED]` | Lookalike phishing domain from the SMS (homoglyph l/i) | Partial |
| domain | `scampage[.]net` | Redirect for non-Norwegian visitors | Yes |
| domain | `scampages[.]net` | Redirect for desktop visitors | Yes |
| domain | `geoiptool[.]com` | Legitimate geo-lookup, linked in exfil messages | Yes |
| filename | `authorization.feb520e19d2d6db01d95.css` | Cloned BankID stylesheet, hunting pivot | Yes |
| filename | `11siffer.php`, `6siffer.php`, `telefonnummer.php`, `Personlig-passord.php`, `block.php`, `action.php` | Kit structure | Yes |

Machine-readable: [`iocs.csv`](iocs.csv)

The redirect domains are where the kit sends unwanted visitors; operator ownership is not confirmed.

## Full set / Fullt sett

The unredacted set (bot token, chat ID, handle, API key) is shared only with CERTs, the impersonated brand and verified defensive researchers. Contact me through GitHub.
Det usladdede settet deles bare med CERT-er, varemerkeeier og verifiserte forsvarsforskere. Kontakt meg via GitHub.
