"""Every file in positive/ must match at least one rule; no file in negative/ may match."""
import pathlib, sys, yara
here = pathlib.Path(__file__).parent
rules = yara.compile(str(here.parent / "bankid_kit.yar"))
fail = 0
for kind in ("positive", "negative"):
    for f in sorted((here / kind).iterdir()):
        hits = [m.rule for m in rules.match(str(f))]
        ok = bool(hits) if kind == "positive" else not hits
        fail += not ok
        print(f"{'PASS' if ok else 'FAIL'}  {kind:8} {f.name:28} {hits}")
sys.exit(1 if fail else 0)
