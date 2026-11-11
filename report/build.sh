#!/usr/bin/env bash
# Rebuilds the PDFs from report/src/*.md. Requires pandoc and Node + Playwright (Chromium).
set -euo pipefail
cd "$(dirname "$0")"
for lang in en no; do
  toc_title=$([ "$lang" = no ] && echo "Innhold" || echo "Contents")
  pandoc "src/report-$lang.md" -s --toc --toc-depth=1 -M toc-title="$toc_title" \
    --no-highlight --css style.css --embed-resources -o "/tmp/report-$lang.html"
  node -e '
    const { chromium } = require("playwright");
    (async () => {
      const [src, out, footer] = process.argv.slice(1);
      const b = await chromium.launch(); const p = await b.newPage();
      await p.goto("file://" + src); 
      await p.pdf({ path: out, format: "A4", printBackground: true, displayHeaderFooter: true,
        headerTemplate: "<span></span>",
        footerTemplate: `<div style="font-size:7pt;color:#5b6475;width:100%;padding:0 16mm;display:flex;justify-content:space-between"><span>${footer}</span><span><span class=pageNumber></span>/<span class=totalPages></span></span></div>`,
        margin: { top: "16mm", bottom: "18mm", left: "0", right: "0" } });
      await b.close();
    })();' "/tmp/report-$lang.html" "bankid-smishing-kit-analysis-$lang.pdf" \
    "0xS3-TR-2026-01 v2.0 · 0xS3J4D · TLP:CLEAR"
done
echo "PDFs written to $(pwd)"
