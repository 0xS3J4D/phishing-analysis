# Detection content

| File | What it detects | Use it on |
|---|---|---|
| [`bankid_kit.yar`](bankid_kit.yar) | Back end (Telegram exfil), geo-filter and front end of the kit | Web roots, hosting accounts, kit archives, sandbox file dumps |

```bash
yara -r detection/bankid_kit.yar /path/to/webroot
```

## Hunting ideas (no rule file)

- **urlscan.io / sandboxes:** search for the cloned stylesheet name `authorization.feb520e19d2d6db01d95.css` on domains that do not belong to BankID.
- **Rendered DOM heuristic:** many text nodes that are a single character inside `<font>` or `<az>` elements, plus BankID logos → very likely phishing.
- **Web server egress:** a web host calling both `api.telegram.org` and `pro.ip-api.com`.
- **Analysis tip:** visit suspect URLs from a Norwegian IP with a mobile user agent, or the kit only shows a redirect.

The rules are based on static analysis of one sample. Test them against your own clean data for false positives before you deploy them.

## Tests

`detection/tests/` contains synthetic, non-functional fixtures. Each positive fixture must match a rule and no negative fixture may match. CI runs the tests on every change:

```bash
pip install yara-python && python detection/tests/run_tests.py
```
