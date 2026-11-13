"""App Store product page header (3840x1646) and search results (3840x2560) assets, per language.

usage: python3 header.py RAW_DIR OUT_DIR
"""
import asyncio, os, sys
sys.argv += [] if len(sys.argv) > 2 else ["/tmp/raw", "out"]
from compose import FONTS, BASE_CSS, b64, RAWS, HERE  # noqa: E402
from playwright.async_api import async_playwright  # noqa: E402

RAW, OUT = sys.argv[1], sys.argv[2]
ICON = b64(os.path.join(HERE, "icon.png"))

COPY = {
    "en": ("Every minute out,<br>accounted for.", "The aligner timer that lives in your Dynamic Island.", "No account · No ads · Pay once"),
    "fr": ("Chaque minute<br>hors bouche, comptée.", "Le minuteur de gouttières dans votre Dynamic Island.", "Sans compte · Sans pub · Un seul paiement"),
    "es": ("Cada minuto fuera,<br>bajo control.", "El temporizador de alineadores en tu Dynamic Island.", "Sin cuenta · Sin anuncios · Pago único"),
    "ar": ("كل دقيقة خارج الفم<br>محسوبة.", "مؤقت التقويم الشفاف في الـ Dynamic Island.", "بدون حساب · بدون إعلانات · ادفع مرة واحدة"),
}

CSS = """
.glow { background:
  radial-gradient(40% 70% at 50% 50%, rgba(91,157,255,.30), transparent 70%),
  radial-gradient(30% 60% at 18% 60%, rgba(255,181,71,.22), transparent 70%),
  radial-gradient(30% 60% at 82% 60%, rgba(61,220,151,.20), transparent 70%); }
.center { position: absolute; left: 50%; top: 50%; transform: translate(-50%, -50%); text-align: center; z-index: 5; width: var(--cw); }
.brand { display: inline-flex; align-items: center; gap: 34px; }
.brand img { width: var(--icon); height: var(--icon); border-radius: 26%; box-shadow: 0 0 0 3px rgba(255,255,255,.1), 0 30px 80px -10px rgba(91,157,255,.5); }
.brand span { font-size: var(--word); font-weight: 900; letter-spacing: -.05em; }
h1 { margin-top: var(--gap); font-size: var(--h1); line-height: 1.02; font-weight: 900; letter-spacing: -.045em; }
body[dir=rtl] h1 { letter-spacing: 0; line-height: 1.3; }
.sub { margin-top: calc(var(--gap) * .7); font-size: var(--sub); font-weight: 600; color: #9A9AA6; }
.chips { margin-top: calc(var(--gap) * .8); font-size: var(--chip); font-weight: 800; color: #3DDC97; }
.phone { position: absolute; width: var(--pw); height: calc(var(--pw) * 2.106); border-radius: calc(var(--pw) * .145); padding: calc(var(--pw) * .025);
  background: linear-gradient(145deg, #3a3a42, #15151a 40%, #2a2a31 75%, #101014);
  box-shadow: 0 0 0 4px #050507, inset 0 0 0 3px rgba(255,255,255,.09), 0 80px 160px -40px rgba(0,0,0,.95); }
.phone .s { width: 100%; height: 100%; border-radius: calc(var(--pw) * .12); overflow: hidden; background: #0B0B0F; }
.phone img { width: 100%; display: block; }
"""


def phones_html(lang, layout):
    out = []
    for key, style in layout:
        raw = os.path.join(RAW, RAWS[lang][key] + ".png")
        out.append(f'<div class="phone" style="{style}"><div class="s"><img src="data:image/png;base64,{b64(raw)}"></div></div>')
    return "".join(out)


def page(lang, w, h, vars_, layout):
    title, sub, chips = COPY[lang]
    rtl = ' dir="rtl"' if lang == "ar" else ""
    body = f"""<div class="glow"></div><div class="grain"></div>{phones_html(lang, layout)}
<div class="center"><div class="brand" dir="ltr"><img src="data:image/png;base64,{ICON}"><span>Inly</span></div>
<h1>{title}</h1><p class="sub">{sub}</p><p class="chips">{chips}</p></div>"""
    css = BASE_CSS.replace("W", f"{w}px").replace("H", f"{h}px") + CSS
    return f'<!doctype html><html><head><meta charset="utf-8"><style>{FONTS}{css}</style></head><body{rtl} style="{vars_}">{body}</body></html>'


async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        for lang in COPY:
            d = os.path.join(OUT, lang)
            os.makedirs(d, exist_ok=True)
            # Header 21:9: text in the middle, phones on both sides (they crop away first on narrow screens).
            hv = "--cw:1400px;--icon:140px;--word:130px;--gap:50px;--h1:116px;--sub:42px;--chip:38px;--pw:600px"
            hl = [("trays", "left:620px;top:470px;transform:rotate(-4deg) scale(.86);opacity:.9"),
                  ("history", "right:620px;top:470px;transform:rotate(4deg) scale(.86);opacity:.9"),
                  ("out", "left:110px;top:200px;transform:rotate(-8deg)"),
                  ("in", "right:110px;top:200px;transform:rotate(8deg)")]
            pg = await browser.new_page(viewport={"width": 3840, "height": 1646})
            await pg.set_content(page(lang, 3840, 1646, hv, hl), wait_until="load")
            await pg.wait_for_timeout(300)
            await pg.screenshot(path=os.path.join(d, "header.png"))
            await pg.close()
            # Search results 3:2: text up top in the middle, three phones rising from the bottom.
            sv = "--cw:2400px;--icon:150px;--word:140px;--gap:50px;--h1:136px;--sub:54px;--chip:44px;--pw:880px"
            sl = [("out", "left:420px;top:1230px;transform:rotate(-7deg)"),
                  ("trays", "right:420px;top:1230px;transform:rotate(7deg)"),
                  ("in", "left:1480px;top:1120px")]
            pg = await browser.new_page(viewport={"width": 3840, "height": 2560})
            html = page(lang, 3840, 2560, sv, sl).replace(".center { position: absolute; left: 50%; top: 50%; transform: translate(-50%, -50%);",
                                                          ".center { position: absolute; left: 50%; top: 170px; transform: translateX(-50%);")
            await pg.set_content(html, wait_until="load")
            await pg.wait_for_timeout(300)
            await pg.screenshot(path=os.path.join(d, "search.png"))
            await pg.close()
        await browser.close()

asyncio.run(main())
