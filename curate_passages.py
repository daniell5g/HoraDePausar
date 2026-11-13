import json, re, sys
src, out = sys.argv[1], sys.argv[2]
BOOKS = {"GEN":"Gênesis","EXO":"Êxodo","NUM":"Números","DEU":"Deuteronômio","JOS":"Josué","1SA":"1 Samuel","NEH":"Neemias",
"PSA":"Salmos","PRO":"Provérbios","ECC":"Eclesiastes","ISA":"Isaías","JER":"Jeremias","LAM":"Lamentações","MIC":"Miqueias",
"HAB":"Habacuque","JOB":"Jó","EZE":"Ezequiel","JOE":"Joel","NAH":"Naum","1CH":"1 Crônicas","2CH":"2 Crônicas","2SA":"2 Samuel","RUT":"Rute","ACT":"Atos","2TH":"2 Tessalonicenses","1TI":"1 Timóteo","TIT":"Tito","2PE":"2 Pedro","ZEP":"Sofonias","MAT":"Mateus","MAR":"Marcos","LUK":"Lucas","JOH":"João","ROM":"Romanos","1CO":"1 Coríntios",
"2CO":"2 Coríntios","GAL":"Gálatas","EPH":"Efésios","PHI":"Filipenses","COL":"Colossenses","1TH":"1 Tessalonicenses",
"2TI":"2 Timóteo","HEB":"Hebreus","JAM":"Tiago","1PE":"1 Pedro","1JO":"1 João","REV":"Apocalipse"}
# (ref, theme)  themes: paz, forca, confianca, gratidao, esperanca, amor, sabedoria, oracao
CUR = """
PSA 4:8 paz|PSA 5:3 oracao|PSA 16:11 gratidao|PSA 19:14 oracao|PSA 23:1-3 confianca|PSA 23:4 confianca|PSA 27:1 forca|PSA 30:5 esperanca
PSA 32:8 sabedoria|PSA 34:8 gratidao|PSA 34:18 esperanca|PSA 37:4-5 confianca|PSA 37:7 paz|PSA 40:1 esperanca|PSA 42:1 oracao|PSA 42:11 esperanca
PSA 46:1 forca|PSA 46:10 paz|PSA 51:10 oracao|PSA 55:22 confianca|PSA 56:3 confianca|PSA 62:1-2 paz|PSA 63:1 oracao|PSA 73:26 forca
PSA 86:5 amor|PSA 90:12 sabedoria|PSA 91:1-2 confianca|PSA 91:11 confianca|PSA 94:19 paz|PSA 100:4-5 gratidao|PSA 103:1-2 gratidao|PSA 107:1 gratidao
PSA 118:24 gratidao|PSA 119:105 sabedoria|PSA 121:1-2 forca|PSA 121:7-8 confianca|PSA 127:1 confianca|PSA 130:5 esperanca|PSA 136:1 gratidao|PSA 138:8 esperanca
PSA 139:13-14 gratidao|PSA 143:8 oracao|PSA 145:18 oracao|PSA 147:3 esperanca|PSA 150:6 gratidao
PRO 3:5-6 confianca|PRO 4:23 sabedoria|PRO 15:1 sabedoria|PRO 16:3 confianca|PRO 16:9 confianca|PRO 17:17 amor|PRO 18:10 forca
ECC 3:1 sabedoria|ISA 12:2 confianca|ISA 26:3 paz|ISA 30:15 paz|ISA 40:29 forca|ISA 40:31 forca|ISA 41:10 forca|ISA 43:2 confianca
ISA 43:18-19 esperanca|ISA 54:10 amor|ISA 55:8-9 sabedoria|ISA 58:11 confianca|JER 29:11 esperanca|JER 29:13 oracao|JER 31:3 amor|JER 33:3 oracao
LAM 3:22-23 esperanca|DEU 31:6 forca|JOS 1:9 forca|NUM 6:24-26 paz|ZEP 3:17 amor|MIC 6:8 sabedoria|HAB 3:17-18 gratidao|EXO 14:14 paz|NEH 8:10 forca
1SA 16:7 sabedoria
MAT 5:8 oracao|MAT 5:9 paz|MAT 5:14 amor|MAT 5:16 amor|MAT 6:6 oracao|MAT 6:33 confianca|MAT 6:34 paz|MAT 7:7 oracao|MAT 11:28 paz|MAT 11:29-30 paz
MAT 18:20 oracao|MAT 19:26 esperanca|MAT 28:20 confianca|MAR 9:23 confianca|MAR 11:24 oracao|LUK 1:37 esperanca|LUK 6:31 amor
JOH 1:5 esperanca|JOH 3:16 amor|JOH 8:12 sabedoria|JOH 10:10 esperanca|JOH 11:25 esperanca|JOH 13:34 amor|JOH 14:1 paz|JOH 14:6 sabedoria
JOH 14:27 paz|JOH 15:5 forca|JOH 15:13 amor|JOH 16:33 paz
ROM 5:8 amor|ROM 8:28 confianca|ROM 8:38-39 amor|ROM 12:2 sabedoria|ROM 12:12 esperanca|ROM 15:13 esperanca
1CO 10:13 forca|1CO 13:4-5 amor|1CO 13:13 amor|1CO 16:14 amor|2CO 4:16 esperanca|2CO 5:17 esperanca|2CO 12:9 forca
GAL 2:20 amor|GAL 5:22-23 sabedoria|GAL 6:9 forca|EPH 2:8 gratidao|EPH 3:20-21 esperanca|EPH 4:32 amor
PHI 1:6 confianca|PHI 4:6-7 paz|PHI 4:8 sabedoria|PHI 4:13 forca|PHI 4:19 confianca|COL 3:23 sabedoria|1TH 5:16-18 gratidao
2TI 1:7 forca|HEB 4:16 oracao|HEB 11:1 confianca|HEB 13:5 confianca|JAM 1:5 sabedoria|JAM 1:17 gratidao|1PE 5:7 paz
1JO 1:9 amor|1JO 4:18 amor|1JO 4:19 amor|REV 3:20 amor|REV 21:4 esperanca
"""

# Expansion to 365 (2026-11-13): one passage per day of the year, ~45 per theme.
CUR += """
PSA 1:1-2 sabedoria|PSA 3:3 confianca|PSA 5:11 gratidao|PSA 8:3-4 gratidao|PSA 9:1 gratidao|PSA 9:9-10 confianca|PSA 16:8 forca|PSA 18:2 forca
PSA 18:28 esperanca|PSA 19:1 gratidao|PSA 20:7 confianca|PSA 23:5-6 gratidao|PSA 25:4-5 oracao|PSA 27:4 oracao|PSA 27:14 forca|PSA 28:7 forca
PSA 29:11 paz|PSA 30:11-12 gratidao|PSA 31:14-15 confianca|PSA 31:24 forca|PSA 33:20-22 esperanca|PSA 34:1 gratidao|PSA 34:4 oracao|PSA 34:17 oracao
PSA 36:5 amor|PSA 37:3 confianca|PSA 37:23-24 confianca|PSA 37:39 forca|PSA 39:7 esperanca|PSA 40:2-3 gratidao|PSA 50:15 oracao|PSA 51:12 oracao
PSA 55:17 oracao|PSA 59:16 forca|PSA 61:1-2 oracao|PSA 62:5-6 esperanca|PSA 62:8 confianca|PSA 63:6-7 oracao|PSA 73:23-24 confianca|PSA 84:5 forca
PSA 86:11 sabedoria|PSA 86:12-13 gratidao|PSA 90:14 gratidao|PSA 91:4 confianca|PSA 91:15 oracao|PSA 92:1-2 gratidao|PSA 95:1-2 gratidao|PSA 95:6 oracao
PSA 96:1 gratidao|PSA 100:1-3 gratidao|PSA 103:8 amor|PSA 103:11-12 amor|PSA 103:13 amor|PSA 104:33 gratidao|PSA 107:8-9 gratidao|PSA 111:10 sabedoria
PSA 116:1-2 oracao|PSA 116:7 paz|PSA 118:6 confianca|PSA 118:14 forca|PSA 119:9 sabedoria|PSA 119:11 sabedoria|PSA 119:18 oracao|PSA 119:97 sabedoria
PSA 119:114 esperanca|PSA 119:130 sabedoria|PSA 119:165 paz|PSA 124:8 forca|PSA 125:1 confianca|PSA 126:3 gratidao|PSA 126:5 esperanca|PSA 139:7-10 confianca
PSA 139:23-24 oracao|PSA 141:2 oracao|PSA 141:3 sabedoria|PSA 143:10 sabedoria|PSA 145:3 gratidao|PSA 145:8-9 amor|PSA 146:5 esperanca|PRO 1:7 sabedoria
PRO 2:6 sabedoria|PRO 3:1-2 sabedoria|PRO 3:24 paz|PRO 10:12 amor|PRO 12:18 sabedoria|PRO 12:25 paz|PRO 14:30 paz|PRO 16:24 sabedoria
PRO 16:32 forca|PRO 17:22 gratidao|PRO 24:16 forca|ECC 3:11 esperanca|ECC 4:12 forca|ECC 12:13 sabedoria|JOB 19:25 esperanca|ISA 1:18 amor
ISA 9:6 esperanca|ISA 25:1 gratidao|ISA 26:4 confianca|ISA 30:21 sabedoria|ISA 32:17 paz|ISA 40:8 sabedoria|ISA 40:11 amor|ISA 40:28 forca
ISA 41:13 confianca|ISA 43:1 amor|ISA 46:4 confianca|ISA 48:17 sabedoria|ISA 49:15-16 amor|ISA 52:7 paz|ISA 53:5 amor|ISA 55:6 oracao
ISA 55:12 paz|ISA 60:1 esperanca|ISA 61:10 gratidao|ISA 65:24 oracao|JER 15:16 gratidao|JER 17:7-8 confianca|LAM 3:24-26 esperanca|EZE 36:26 esperanca
1CH 16:34 gratidao|2CH 7:14 oracao|2SA 22:2-3 forca|RUT 1:16 amor|EXO 15:2 forca|EXO 33:14 paz|DEU 31:8 confianca|GEN 28:15 confianca
MAT 4:4 sabedoria|MAT 5:4 esperanca|MAT 5:44 amor|MAT 6:9-13 oracao|MAT 6:19-21 sabedoria|MAT 6:26 confianca|MAT 7:24 sabedoria|MAT 10:29-31 confianca
MAT 14:27 paz|MAT 21:22 oracao|MAT 22:37-39 amor|MAT 26:41 oracao|MAR 1:35 oracao|MAR 10:27 esperanca|LUK 2:10-11 esperanca|LUK 2:14 paz
LUK 6:36 amor|LUK 10:41-42 paz|LUK 12:32 paz|LUK 17:15-16 gratidao|LUK 18:1 oracao|JOH 6:35 esperanca|JOH 8:31-32 sabedoria|JOH 10:11 amor
JOH 15:7 oracao|JOH 15:9 amor|JOH 15:11 gratidao|JOH 16:24 oracao|ROM 5:1 paz|ROM 5:3-4 esperanca|ROM 5:5 amor|ROM 8:1 paz
ROM 8:18 esperanca|ROM 8:26 oracao|ROM 8:31 confianca|ROM 8:37 forca|ROM 14:19 paz|1CO 13:7 amor|1CO 15:57 gratidao|1CO 15:58 forca
1CO 16:13 forca|2CO 4:17-18 esperanca|2CO 9:15 gratidao|2CO 12:10 forca|EPH 1:3 gratidao|EPH 3:16-17 forca|EPH 4:2-3 paz|EPH 5:20 gratidao
EPH 6:10 forca|EPH 6:18 oracao|PHI 2:13 forca|PHI 3:13-14 esperanca|PHI 4:4 gratidao|PHI 4:11-12 gratidao|COL 2:6-7 gratidao|COL 3:2 sabedoria
COL 3:14 amor|COL 3:15 paz|COL 3:16 sabedoria|COL 4:2 oracao|2TH 3:16 paz|2TI 1:12 confianca|2TI 3:16-17 sabedoria|2TI 4:7 forca
HEB 4:12 sabedoria|HEB 6:19 esperanca|HEB 10:23 esperanca|HEB 12:1-2 forca|HEB 13:8 confianca|HEB 13:15 gratidao|JAM 1:2-3 forca|JAM 1:12 forca
JAM 1:19 sabedoria|JAM 1:22 sabedoria|JAM 3:17 sabedoria|JAM 4:8 oracao|JAM 5:13 oracao|JAM 5:16 oracao|1PE 1:3 esperanca|1PE 4:8 amor
1PE 5:10 forca|1JO 3:1 amor|1JO 4:16 amor|REV 21:5 esperanca|ROM 8:6 paz|ROM 12:18 paz|PHI 4:9 paz|HEB 12:14 paz
PSA 34:14 paz|MAT 5:5 paz|LUK 7:50 paz|2CO 13:11 paz
"""
verses = {}
for line in open(src, encoding="utf-8"):
    m = re.match(r"^(\S+) (\d+):(\d+) (.*)$", line.rstrip("\n"))
    if m: verses[(m[1], int(m[2]), int(m[3]))] = m[4]

FIXES = {"PSA.32.8":[("e de ensinarei","e te ensinarei")],"PSA.34.18":[(" sava "," salva ")],"PSA.90.12":[("Ensina -nos","Ensina-nos")],
"PSA.119.105":[("Nun :","")],"PRO.3.5-6":[("todas os","todos os")],"ISA.43.2":[("nem a chamas","nem as chamas")],
"MAT.19.26":[("eles ,e","eles, e")],"MAT.28.20":[("ensinando-lhes a guardar todas as coisas que eu vos tenho mandado. ","")],
"JOH.14.27":[("dá- la","dá-la")],"1CO.13.4-5":[("interesses ,","interesses,")],"2CO.5.17":[("é ;","é;")],
"PHI.4.19":[("todas a vossas","todas as vossas")],"REV.21.4":[("passaram.”","passaram.")]}

FIXES.update({"PSA.9.1":[("a ti , SENHOR com","a ti, SENHOR, com")],"PSA.30.11-12":[("lamentação ,","lamentação,")],
"PSA.33.20-22":[("nossa socorro","nosso socorro"),("SENOR","SENHOR")],"PSA.34.1":[("Salmo de Davi, quando ele mudou seu comportamento perante Abimeleque, que o expulsou, e ele foi embora: ","")],
"PSA.62.8":[(" (Selá)","")],"PSA.84.5":[("corretos .","corretos.")],"PSA.90.1-2":[("Oração de Moisés, homem de Deus: ","")],
"PSA.8.3-4":[("; O que é","; o que é")],"PSA.92.1-2":[("; Para anunciar","; para anunciar")],"PSA.111.10":[("todos o que","todos os que")],
"PSA.119.9":[("Bete : ","")],"PSA.119.97":[("Mem :","")],"PSA.139.7-10":[("estás ;","estás;"),("estás .","estás."),(", Até ali",", até ali")],
"PRO.1.7":[("principio","princípio")],"PRO.12.18":[("do sábios","dos sábios")],"PRO.29.25":[("no senhor","no SENHOR")],
"ISA.1.18":[("contas,diz","contas, diz")],"JER.17.7-8":[("; Porque","; porque")],"JOE.2.13":[("vestes.Convertei","vestes. Convertei")],
"1CH.16.34":[("Celebrai a o SENHOR","Celebrai ao SENHOR"),("; Porque","; porque")],"2CH.7.14":[("nem nome","meu nome")],
"2SA.22.2-3":[("E disse: ",""),("; Meu salvador","; meu salvador")],"DEU.6.5":[("E Amarás","Amarás"),("todo tua poder","todo teu poder")],
"EXO.15.2":[(", E foi-me",", e foi-me")],"GEN.28.15":[("disse.”","disse.")],"NUM.23.19":[("não fará?; Falou","não fará? Falou")],
"MAT.6.19-21":[("onde e a traça","onde a traça"),("; Mas ajuntai","; mas ajuntai")],"MAT.22.37-39":[("é :","é:")],
"MAT.25.40":[("“Em verdade","Em verdade"),("a mim”.","a mim.")],"LUK.10.41-42":[("; Mas somente","; mas somente")],
"ROM.5.3-4":[("isso ,","isso,")],"2CO.5.7":[("(Pois andamos pela fé, e não pela vista).","Pois andamos pela fé, e não pela vista.")],
"EPH.1.3":[("espirituis","espirituais")],"PHI.3.13-14":[("faço :","faço:")],"COL.3.12-13":[("fazei .","fazei.")],
"HEB.11.6":[("Deus .","Deus.")],"REV.21.5":[("“Eis","Eis"),("coisas.”","coisas."),("“Escreve","Escreve"),("fiéis.”","fiéis.")]})
def tidy(sid, text):
    for a,b in FIXES.get(sid,[]):
        assert a in text, (sid,a); text = text.replace(a,b)
    text = text.strip()
    if text[-1] in ";,:": text = text[:-1].rstrip() + "."
    if text[0].islower(): text = text[0].upper() + text[1:]
    return text

out_list, warn = [], []
for item in [x.strip() for x in CUR.replace("\n","|").split("|") if x.strip()]:
    ref, theme = item.rsplit(" ", 1)
    book, cv = ref.split(" ")
    ch, vv = cv.split(":")
    a, b = (vv.split("-") + [vv])[:2]
    ch, a, b = int(ch), int(a), int(b)
    parts = []
    for v in range(a, b + 1):
        t = verses[(book, ch, v)]
        parts.append(t)
    text = " ".join(parts)
    text = re.sub(r"\[([^\]]*)\]", r"\1", text)          # remove supplied-word brackets
    if book == "PSA" and a == 1:                              # drop psalm superscription
        text2 = re.sub(r"^[^:]{0,80}?(Davi|Salmo|Cântico|Coré|Asafe|músico|Mictão|Masquil)[^:]{0,80}:\s*", "", text)
        if text2 != text: warn.append(f"superscription dropped {ref}: {text[:len(text)-len(text2)]!r}")
        text = text2
    text = re.sub(r"\s+", " ", text).strip()
    words = len(text.split())
    if words > 70: warn.append(f"LONG {ref} {words}w")
    sid = f"{book}.{ch}.{a}" + (f"-{b}" if b != a else "")
    reference = f"{BOOKS[book]} {ch}:{a}" + (f"-{b}" if b != a else "")
    text = tidy(sid, text)
    out_list.append({"id": sid, "reference": reference, "text": text, "theme": theme})
assert len({p["id"] for p in out_list}) == len(out_list), "dup ids"
json.dump(out_list, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(len(out_list), "passages"); print("\n".join(warn))
