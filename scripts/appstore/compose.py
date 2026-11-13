"""Builds App Store marketing screenshots (1320x2868) from raw simulator captures.

usage: python3 compose.py RAW_DIR OUT_DIR
RAW_DIR holds the CI captures (01-today-in.png, 20-fr-today.png, watch-en-in.png, ...).
"""
import asyncio, base64, os, sys
from playwright.async_api import async_playwright

HERE = os.path.dirname(os.path.abspath(__file__))
RAW, OUT = (sys.argv[1], sys.argv[2]) if __name__ == "__main__" else ("", "")

def b64(path):
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode()

FONTS = f"""
@font-face {{ font-family: Nun; src: url(data:font/woff2;base64,{b64(os.path.join(HERE, 'nunito.woff2'))}) format('woff2'); font-weight: 200 1000; }}
@font-face {{ font-family: Taj; src: url(data:font/woff2;base64,{b64(os.path.join(HERE, 'tajawal-arabic-800-normal.woff2'))}) format('woff2'); font-weight: 800; }}
@font-face {{ font-family: Taj; src: url(data:font/woff2;base64,{b64(os.path.join(HERE, 'tajawal-arabic-500-normal.woff2'))}) format('woff2'); font-weight: 500; }}
"""

# Raw file per slide and language.
RAWS = {
    "en": {"out": "02-today-out", "in": "01-today-in", "trays": "05-trays", "history": "07-history", "calendar": "08-history-calendar"},
}
for code in ("fr", "es", "ar"):
    RAWS[code] = {"out": f"28-{code}-today-out", "in": f"20-{code}-today", "trays": f"21-{code}-trays",
                  "history": f"22-{code}-history", "calendar": f"29-{code}-calendar"}
for code in ("en", "fr", "es", "ar"):
    RAWS[code]["compare"] = f"32-{code}-compare"
    RAWS[code]["report"] = f"33-{code}-report"

COLORS = {"compare": "#FF8FB1", "report": "#5B9DFF", "out": "#FFB547", "in": "#5B9DFF", "trays": "#3DDC97", "history": "#B28DFF", "calendar": "#4FD1D9", "privacy": "#3DDC97"}

TEXT = {
    "en": {
        "compare": ("See your smile<br>change.", "Guided photos. Compare any two trays with a slider."),
        "report": ("A report worth<br>bringing.", "A clean PDF of your wear time for your orthodontist."),
        "out": ("Every minute out,<br>accounted for.", "The timer lives in your Dynamic Island."),
        "in": ("22 hours a day,<br>made easy.", "One tap out, one tap in. Reminders do the rest."),
        "trays": ("Every tray,<br>on schedule.", "Refinements, appointments and progress photos."),
        "history": ("Progress you<br>can actually see.", "Weekly score, streaks and a 7-day chart."),
        "calendar": ("Your treatment,<br>day by day.", "Tap any day to see or fix every break."),
        "privacy": ("Private.<br>Pay once.", "No account, no ads, no tracking.", ["No account", "No ads", "No tracking"],
                    ["Apple Watch & complications", "Home & Lock Screen widgets", "iCloud sync", "Reports for your orthodontist"],
                    "Inly+ · one-time purchase · try free for 7 days"),
        "watch_in": ("Inly on your wrist.", ""), "watch_out": ("Log a break from your wrist.", ""),
    },
    "fr": {
        "compare": ("Voyez votre sourire<br>changer.", "Photos guidées. Comparez deux gouttières avec un curseur."),
        "report": ("Un rapport<br>à emporter.", "Un PDF clair de votre temps de port pour l'orthodontiste."),
        "out": ("Chaque minute<br>hors bouche, comptée.", "Le minuteur vit dans la Dynamic Island."),
        "in": ("22 heures par jour,<br>en toute simplicité.", "Un toucher pour enlever, un pour remettre."),
        "trays": ("Chaque gouttière,<br>dans les temps.", "Raffinements, rendez-vous et photos de progression."),
        "history": ("Des progrès<br>enfin visibles.", "Score hebdo, séries et graphique sur 7 jours."),
        "calendar": ("Tout votre traitement,<br>jour après jour.", "Touchez un jour pour voir ou corriger chaque pause."),
        "privacy": ("Privé.<br>Un seul paiement.", "Sans compte, sans pub, sans pistage.", ["Sans compte", "Sans pub", "Sans pistage"],
                    ["Apple Watch et complications", "Widgets d'accueil et verrouillage", "Synchro iCloud", "Rapports pour l'orthodontiste"],
                    "Inly+ · achat unique · essai gratuit de 7 jours"),
        "watch_in": ("Inly à votre poignet.", ""), "watch_out": ("Notez une pause au poignet.", ""),
    },
    "es": {
        "compare": ("Mira cómo cambia<br>tu sonrisa.", "Fotos guiadas. Compara dos alineadores con un deslizador."),
        "report": ("Un informe<br>que vale la pena.", "Un PDF claro de tu tiempo de uso para tu ortodoncista."),
        "out": ("Cada minuto fuera,<br>bajo control.", "El temporizador vive en la Dynamic Island."),
        "in": ("22 horas al día,<br>sin esfuerzo.", "Un toque para quitar, otro para poner."),
        "trays": ("Cada alineador,<br>al día.", "Refinamientos, citas y fotos de progreso."),
        "history": ("Un progreso<br>que se ve.", "Puntuación semanal, rachas y gráfico de 7 días."),
        "calendar": ("Todo tu tratamiento,<br>día a día.", "Toca un día para ver o corregir cada pausa."),
        "privacy": ("Privado.<br>Pago único.", "Sin cuenta, sin anuncios, sin rastreo.", ["Sin cuenta", "Sin anuncios", "Sin rastreo"],
                    ["Apple Watch y complicaciones", "Widgets de inicio y bloqueo", "Sincronización con iCloud", "Informes para tu ortodoncista"],
                    "Inly+ · compra única · prueba gratis 7 días"),
        "watch_in": ("Inly en tu muñeca.", ""), "watch_out": ("Registra una pausa desde tu muñeca.", ""),
    },
    "ar": {
        "compare": ("شاهد ابتسامتك<br>تتغيّر.", "صور موجّهة. قارن بين أي طقمين بشريط تمرير."),
        "report": ("تقرير جدير<br>بأخذه معك.", "ملف PDF واضح لوقت الارتداء لطبيب التقويم."),
        "out": ("كل دقيقة خارج الفم<br>محسوبة.", "المؤقت يعيش في الـ Dynamic Island."),
        "in": ("22 ساعة يوميًا<br>بكل سهولة.", "لمسة للإخراج ولمسة للإرجاع، والتذكيرات تتكفّل بالباقي."),
        "trays": ("كل طقم<br>في موعده.", "مراحل التحسين والمواعيد وصور التقدّم."),
        "history": ("تقدّم<br>تراه بعينك.", "نتيجة أسبوعية وسلاسل ورسم بياني لـ 7 أيام."),
        "calendar": ("علاجك كاملًا<br>يومًا بيوم.", "اضغط على أي يوم لترى كل استراحة أو تصحّحها."),
        "privacy": ("خصوصية تامة.<br>ادفع مرة واحدة.", "بدون حساب، بدون إعلانات، بدون تتبّع.", ["بدون حساب", "بدون إعلانات", "بدون تتبّع"],
                    ["Apple Watch وإضافات الساعة", "أدوات الشاشة الرئيسية والقفل", "مزامنة iCloud", "تقارير لطبيب التقويم"],
                    "Inly+ · شراء لمرة واحدة · تجربة مجانية 7 أيام"),
        "watch_in": ("Inly على معصمك.", ""), "watch_out": ("سجّل الاستراحة من معصمك.", ""),
    },
}

BASE_CSS = """
* { box-sizing: border-box; margin: 0; padding: 0; }
html, body { width: W; height: H; overflow: hidden; background: #0B0B0F; }
body { font-family: Nun, Taj, sans-serif; color: #fff; -webkit-font-smoothing: antialiased; position: relative; }
body[dir=rtl] { font-family: Taj, Nun, sans-serif; }
.glow { position: absolute; inset: 0; background:
  radial-gradient(70% 40% at 50% 34%, color-mix(in srgb, var(--c) 30%, transparent), transparent 70%),
  radial-gradient(60% 30% at 50% 0%, color-mix(in srgb, var(--c) 14%, transparent), transparent 80%); }
.grain { position: absolute; inset: 0; opacity: .05; background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='200' height='200'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='.9' numOctaves='3'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E"); }
"""

IPHONE = """
.head { position: absolute; top: 190px; left: 90px; right: 90px; text-align: center; }
.eyebrow { display: inline-block; font-size: 38px; font-weight: 900; letter-spacing: .16em; text-transform: uppercase; color: var(--c); }
body[dir=rtl] .eyebrow { letter-spacing: 0; }
h1 { margin-top: 26px; font-size: 118px; line-height: 1.0; font-weight: 900; letter-spacing: -.045em; }
body[dir=rtl] h1 { letter-spacing: 0; line-height: 1.25; font-size: 112px; }
.sub { margin-top: 34px; font-size: 46px; line-height: 1.3; font-weight: 600; color: #9A9AA6; }
body[dir=rtl] .sub { font-weight: 500; }
.phone { position: absolute; left: 50%; top: 900px; width: 1040px; height: 2190px; transform: translateX(-50%);
  border-radius: 150px; padding: 26px; background: linear-gradient(145deg, #3a3a42, #15151a 40%, #2a2a31 75%, #101014);
  box-shadow: 0 0 0 4px #050507, inset 0 0 0 3px rgba(255,255,255,.09), 0 80px 160px -40px rgba(0,0,0,.95), 0 0 220px -40px color-mix(in srgb, var(--c) 45%, transparent); }
.screen { position: relative; width: 100%; height: 100%; border-radius: 126px; overflow: hidden; background: #0B0B0F; }
.screen img { position: absolute; left: 0; top: 0; width: 100%; }
.island { position: absolute; top: 30px; left: 50%; transform: translateX(-50%); height: 96px; width: 300px; border-radius: 48px; background: #000; z-index: 3;
  display: flex; align-items: center; justify-content: space-between; padding: 0 32px; }
.island.live { width: 560px; }
.island .t { font-size: 46px; font-weight: 900; color: #FFB547; font-variant-numeric: tabular-nums; direction: ltr; }
.bottomfade { position: absolute; left: 0; right: 0; bottom: 0; height: 260px; background: linear-gradient(transparent, #0B0B0F 85%); z-index: 4; }
"""

PRIVACY = """
.wrap { position: absolute; inset: 0; display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 0 100px; text-align: center; }
.shield { width: 240px; height: 240px; border-radius: 70px; display: grid; place-items: center;
  background: linear-gradient(160deg, rgba(61,220,151,.22), rgba(61,220,151,.05)); border: 3px solid rgba(61,220,151,.35); }
h1 { margin-top: 100px; font-size: 168px; line-height: 1.0; font-weight: 900; letter-spacing: -.05em; }
body[dir=rtl] h1 { letter-spacing: 0; line-height: 1.3; font-size: 132px; }
.strikes { margin-top: 120px; display: flex; flex-direction: column; gap: 46px; align-items: center; }
.strikes span { position: relative; font-size: 100px; font-weight: 900; color: #9A9AA6; letter-spacing: -.03em; }
body[dir=rtl] .strikes span { letter-spacing: 0; }
.strikes span::after { content: ""; position: absolute; left: -6%; right: -6%; top: 52%; height: 9px; border-radius: 5px; background: #FF6B5E; }
.plus { margin-top: 140px; width: 100%; border-radius: 64px; padding: 64px 70px; text-align: start;
  background: linear-gradient(160deg, rgba(91,157,255,.18), rgba(178,141,255,.06) 60%), #17171C; border: 3px solid rgba(91,157,255,.45); }
.plus .name { font-size: 96px; font-weight: 900; letter-spacing: -.03em; }
.plus .name b { color: #5B9DFF; }
.plus ul { list-style: none; margin-top: 40px; display: grid; gap: 30px; }
.plus li { display: flex; align-items: center; gap: 30px; font-size: 58px; font-weight: 700; color: #C9C9D2; }
.plus li::before { content: ""; flex: none; width: 22px; height: 22px; border-radius: 50%; background: #5B9DFF; box-shadow: 0 0 0 10px rgba(91,157,255,.18); }
.plus .foot { margin-top: 56px; font-size: 46px; font-weight: 800; color: #3DDC97; }
"""

WATCH = """
.head { position: absolute; top: 34px; left: 20px; right: 20px; text-align: center; font-size: 34px; font-weight: 900; line-height: 1.1; letter-spacing: -.02em; }
body[dir=rtl] .head { letter-spacing: 0; line-height: 1.3; }
.shot { position: absolute; left: 50%; bottom: 0; transform: translateX(-50%); height: 80%; border-radius: 40px; overflow: hidden; box-shadow: 0 0 80px -10px color-mix(in srgb, var(--c) 50%, transparent); }
.shot img { height: 100%; display: block; }
"""

ISLAND_SVG = """<svg width="56" height="56" viewBox="0 0 20 20"><circle cx="10" cy="10" r="7" fill="none" stroke="#3a2c12" stroke-width="3.2"/>
<circle cx="10" cy="10" r="7" fill="none" stroke="#FFB547" stroke-width="3.2" stroke-linecap="round" stroke-dasharray="44" stroke-dashoffset="18" transform="rotate(-90 10 10)"/></svg>"""

EYEBROW = {
    "en": {"compare": "Photos", "report": "Reports", "out": "Live Activity", "in": "Today", "trays": "Trays", "history": "History", "calendar": "Calendar"},
    "fr": {"compare": "Photos", "report": "Rapports", "out": "Activité en direct", "in": "Aujourd'hui", "trays": "Gouttières", "history": "Historique", "calendar": "Calendrier"},
    "es": {"compare": "Fotos", "report": "Informes", "out": "Actividad en vivo", "in": "Hoy", "trays": "Alineadores", "history": "Historial", "calendar": "Calendario"},
    "ar": {"compare": "الصور", "report": "التقارير", "out": "النشاط المباشر", "in": "اليوم", "trays": "الأطقم", "history": "السجل", "calendar": "التقويم"},
}


def page(css, body, lang, color, w, h):
    rtl = ' dir="rtl"' if lang == "ar" else ""
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>{FONTS}{BASE_CSS.replace('W', str(w) + 'px').replace('H', str(h) + 'px')}{css}</style></head>
<body{rtl} style="--c:{color}"><div class="glow"></div><div class="grain"></div>{body}</body></html>"""


def iphone_slide(lang, key, raw_png):
    title, sub = TEXT[lang][key]
    island = ""  # the simulator capture already shows the Live Activity in the status bar
    body = f"""<div class="head"><span class="eyebrow">{EYEBROW[lang][key]}</span><h1>{title}</h1><p class="sub">{sub}</p></div>
<div class="phone"><div class="screen">{island}<img src="data:image/png;base64,{b64(raw_png)}"></div></div><div class="bottomfade"></div>"""
    return page(IPHONE, body, lang, COLORS[key], 1320, 2868)


def privacy_slide(lang):
    title, _, strikes, items, foot = TEXT[lang]["privacy"]
    lock = '<svg width="120" height="120" viewBox="0 0 24 24"><path fill="#3DDC97" d="M12 2a5 5 0 0 0-5 5v3H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8a2 2 0 0 0-2-2h-1V7a5 5 0 0 0-5-5zm-3 8V7a3 3 0 0 1 6 0v3z"/></svg>'
    body = f"""<div class="wrap"><div class="shield">{lock}</div><h1>{title}</h1>
<div class="strikes">{''.join(f'<span>{s}</span>' for s in strikes)}</div>
<div class="plus"><div class="name" dir="ltr" style="text-align:{'right' if lang == 'ar' else 'left'}">Inly<b>+</b></div><ul>{''.join(f'<li>{i}</li>' for i in items)}</ul><p class="foot">{foot}</p></div></div>"""
    return page(PRIVACY, body, lang, COLORS["privacy"], 1320, 2868)


def watch_slide(lang, state, raw_png, w, h):
    title = TEXT[lang]["watch_" + state][0]
    body = f"""<div class="head">{title}</div><div class="shot"><img src="data:image/png;base64,{b64(raw_png)}"></div>"""
    return page(WATCH, body, lang, COLORS["out" if state == "out" else "in"], w, h)


async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        for lang in ("en", "fr", "es", "ar"):
            d = os.path.join(OUT, lang)
            os.makedirs(d, exist_ok=True)
            pg = await browser.new_page(viewport={"width": 1320, "height": 2868})
            for i, key in enumerate(["out", "in", "trays", "history", "calendar", "compare", "report"], start=1):
                raw = os.path.join(RAW, RAWS[lang][key] + ".png")
                if not os.path.exists(raw):
                    print("missing", raw)
                    continue
                await pg.set_content(iphone_slide(lang, key, raw), wait_until="load")
                await pg.wait_for_timeout(250)
                await pg.screenshot(path=os.path.join(d, f"iphone-0{i}.png"))
            await pg.set_content(privacy_slide(lang), wait_until="load")
            await pg.wait_for_timeout(250)
            await pg.screenshot(path=os.path.join(d, "iphone-08.png"))
            await pg.close()
            # Apple Watch: same pixel size as the simulator capture.
            for j, state in enumerate(["in", "out"], start=1):
                raw = os.path.join(RAW, f"watch-{lang}-{state}.png")
                if not os.path.exists(raw):
                    print("missing", raw)
                    continue
                from PIL import Image
                w, h = Image.open(raw).size
                wp = await browser.new_page(viewport={"width": w, "height": h})
                await wp.set_content(watch_slide(lang, state, raw, w, h), wait_until="load")
                await wp.wait_for_timeout(200)
                await wp.screenshot(path=os.path.join(d, f"watch-0{j}.png"))
                await wp.close()
        await browser.close()

if __name__ == "__main__":
    asyncio.run(main())
