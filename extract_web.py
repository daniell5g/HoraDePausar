"""Builds Core/Resources/passages.en.json from the World English Bible (public domain).

Takes the same 365 passage ids and themes as the Portuguese set and pulls each one's text from the
WEB USFM files (eBible.org "engwebp" USFM download). Footnotes, cross references, Strong's tags and
headings are removed; a few formatting fixes keep each passage a clean, self-contained excerpt.

    python3 extract_web.py <engwebp_usfm_dir> Core/Resources/passages.json Core/Resources/passages.en.json
"""
import re, json, glob, sys
usfm_dir, passages_path, out = sys.argv[1:4]
books = {}
for f in glob.glob(f"{usfm_dir}/*.usfm"):
    raw = open(f, encoding="utf-8-sig").read()
    m = re.search(r"\\id (\w{3})", raw)
    if not m: continue
    code = m.group(1)
    t = re.sub(r"\\f .*?\\f\*", "", raw, flags=re.S)        # footnotes
    t = re.sub(r"\\x .*?\\x\*", "", t, flags=re.S)          # cross refs
    t = re.sub(r"\\\+?w ([^|\\]*)\|[^\\]*\\\+?w\*", r"\1", t)     # \w / \+w word|strong\w*
    verses = {}; ch = 0; cur = None
    for tok in re.split(r"(\\c \d+|\\v \d+)", t):
        if tok.startswith("\\c "): ch = int(tok[3:]); cur = None; continue
        if tok.startswith("\\v "): cur = (ch, int(tok[3:])); verses[cur] = ""; continue
        if cur:
            seg = re.sub(r"\\(d|s\d?|ms\d?|mr|r|sp|cl|rem|toc\d|h|mt\d?|ide)\b[^\n]*", "", tok)  # headings
            seg = re.sub(r"\\\+?[a-z]+\d*\*?", " ", seg)          # remaining markers (\p \q1 \wj \add ...)
            verses[cur] += seg
    books[code] = {k: re.sub(r"\s+", " ", v).strip() for k, v in verses.items()}
BOOK_EN = {"GEN":"Genesis","EXO":"Exodus","NUM":"Numbers","DEU":"Deuteronomy","JOS":"Joshua","RUT":"Ruth","1SA":"1 Samuel","2SA":"2 Samuel","1CH":"1 Chronicles","2CH":"2 Chronicles","NEH":"Nehemiah","JOB":"Job","PSA":"Psalm","PRO":"Proverbs","ECC":"Ecclesiastes","ISA":"Isaiah","JER":"Jeremiah","LAM":"Lamentations","EZE":"Ezekiel","MIC":"Micah","HAB":"Habakkuk","ZEP":"Zephaniah","MAT":"Matthew","MAR":"Mark","LUK":"Luke","JOH":"John","ROM":"Romans","1CO":"1 Corinthians","2CO":"2 Corinthians","GAL":"Galatians","EPH":"Ephesians","PHI":"Philippians","COL":"Colossians","1TH":"1 Thessalonians","2TH":"2 Thessalonians","2TI":"2 Timothy","HEB":"Hebrews","JAM":"James","1PE":"1 Peter","1JO":"1 John","REV":"Revelation"}
USFM = {"EZE":"EZK","MAR":"MRK","JOH":"JHN","PHI":"PHP","JAM":"JAS","1JO":"1JN"}
res, missing = [], []
for p in json.load(open(passages_path)):
    b, ch, vs = p["id"].split(".")
    a, z = (map(int, vs.split("-")) if "-" in vs else (int(vs), int(vs)))
    bk = books.get(USFM.get(b, b), {})
    parts = [bk.get((int(ch), v)) for v in range(a, z + 1)]
    if None in parts or not all(parts): missing.append(p["id"]); continue
    res.append({"id": p["id"], "reference": f"{BOOK_EN[b]} {ch}:{vs}", "text": " ".join(parts), "theme": p["theme"]})
print("ok", len(res), "missing", missing)

# ---- tidy: same kind of formatting fixes as the Portuguese set (quotes, first letter, final punctuation)
FIXES = {"MAT.28.20": [("teaching them to observe all things that I commanded you. ", "")],
         "PSA.62.8": [(" Selah.", "")], "2SA.22.2-3": [("and he said: ", "")]}
def tidy(sid, t):
    for a, b in FIXES.get(sid, []):
        assert a in t, (sid, a); t = t.replace(a, b)
    if t.startswith("‘") and t.endswith("’") and not t.startswith("‘‘"):
        inner = t[1:-1]
        if "‘" not in inner: t = inner                       # whole passage is a nested quote
    o, c = t.count("“"), t.count("”")
    if o > c:
        t += "”"                                             # close the open quote
    elif c > o:
        i = t.rfind("”"); t = t[:i] + t[i + 1:]               # dangling closer
    t = t.strip()
    if t[-1] in ";,:": t = t[:-1].rstrip() + "."
    if t[0].islower(): t = t[0].upper() + t[1:]
    return t
for p in res: p["text"] = tidy(p["id"], p["text"])
json.dump(res, open(out, "w"), ensure_ascii=False, indent=1)
print("tidied")
