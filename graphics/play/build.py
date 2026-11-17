"""Play Store graphics. Needs screens from `flutter test test/shots_test.dart`
(writes shots/*.png). Run: python3 graphics/play/build.py -> graphics/play/*.png"""

import base64
import pathlib
import subprocess

D = pathlib.Path(__file__).parent
ROOT = D.parent.parent
OUT = D / "out"
OUT.mkdir(exist_ok=True)
CHROME = "/usr/bin/chromium-browser"


def b64(p, mime):
    return (
        f"data:{mime};base64," + base64.b64encode(pathlib.Path(p).read_bytes()).decode()
    )


FONTS = "".join(
    f"@font-face{{font-family:'Inter';font-weight:{w};src:url({b64(ROOT / 'assets/fonts' / f'Inter-{n}.ttf', 'font/ttf')}) format('truetype')}}"
    for w, n in ((400, "Regular"), (500, "Medium"), (600, "SemiBold"), (700, "Bold"))
)
LOGO = b64(ROOT / "images/logo.png", "image/png")


def shot(n):
    return b64(D / "shots" / f"{n}.png", "image/png")


PINK, CREAM, INK = "#FF91C5", "#F5F3F1", "#111111"
THEMES = {
    "cream": {"bg": CREAM, "fg": INK, "sub": "#6B6966", "frame": "#111111"},
    "pink": {"bg": PINK, "fg": INK, "sub": "rgba(17,17,17,.68)", "frame": "#111111"},
    "ink": {
        "bg": "#0B0B0C",
        "fg": "#FFFFFF",
        "sub": "rgba(255,255,255,.58)",
        "frame": "#2A2A2D",
    },
}

BASE = f"""{FONTS}
*{{margin:0;padding:0;box-sizing:border-box}}
body{{font-family:'Inter',sans-serif;-webkit-font-smoothing:antialiased;overflow:hidden}}
"""


def slide(theme, title, sub, img, kicker):
    t = THEMES[theme]
    return f"""<!doctype html><meta charset=utf-8><style>{BASE}
html,body{{width:1080px;height:1920px}}
body{{background:{t["bg"]};color:{t["fg"]}}}
.k{{position:absolute;left:88px;top:96px;font-size:26px;font-weight:600;letter-spacing:.02em;
  display:flex;align-items:center;gap:14px}}
.k i{{width:12px;height:12px;border-radius:50%;background:{PINK if theme != "pink" else INK};display:block}}
h1{{position:absolute;left:84px;top:130px;width:900px;font-size:112px;line-height:1;
  font-weight:700;letter-spacing:-.045em}}
p{{position:absolute;left:88px;top:400px;width:700px;font-size:36px;line-height:1.38;
  font-weight:400;letter-spacing:-.011em;color:{t["sub"]}}}
.dev{{position:absolute;left:50%;top:580px;transform:translateX(-50%);width:860px;
  padding:14px;border-radius:92px 92px 0 0;background:{t["frame"]};
  box-shadow:0 -2px 0 rgba(255,255,255,.06) inset,0 50px 120px -30px rgba(0,0,0,.35)}}
.dev .s{{border-radius:78px 78px 0 0;overflow:hidden;background:#fff;height:1340px;position:relative}}
.dev img{{width:100%;display:block}}
.dev .cam{{position:absolute;top:24px;left:50%;transform:translateX(-50%);width:30px;height:30px;
  border-radius:50%;background:#0A0A0A}}
</style><body>
<h1>{title}</h1><p>{sub}</p>
<div class=dev><div class=s><img src="{img}"><div class=cam></div></div></div></body>"""


SLIDES = [
    (
        "01_home",
        "cream",
        "Your cycle,<br>at a glance.",
        "Cycle day, countdown and a calendar that reads in a second.",
        "home",
        "Today",
    ),
    (
        "02_insights",
        "pink",
        "Know your<br>numbers.",
        "Average cycle and period length, worked out from your own history.",
        "insights",
        "Insights",
    ),
    (
        "03_log",
        "ink",
        "Log a period<br>in seconds.",
        "Tap the days, add a note if you like, done.",
        "log_dark",
        "Log",
    ),
    (
        "04_reminders",
        "cream",
        "A heads-up<br>before it starts.",
        "Pick how many days ahead and what time. Nothing else ever pings you.",
        "reminders",
        "Reminders",
    ),
    (
        "05_transfer",
        "pink",
        "New phone?<br>Keep it all.",
        "Move your history across with one file. No cloud, no account.",
        "transfer",
        "Your data",
    ),
]

FEATURE = f"""<!doctype html><meta charset=utf-8><style>{BASE}
html,body{{width:1024px;height:500px}}
body{{background:{PINK};color:{INK}}}
.logo{{position:absolute;left:64px;top:56px;width:60px;height:60px;border-radius:50%}}
.n{{position:absolute;left:120px;top:56px;line-height:60px;font-size:26px;font-weight:600;letter-spacing:-.02em}}
h1{{position:absolute;left:62px;top:170px;font-size:58px;line-height:1;font-weight:700;letter-spacing:-.045em}}
p{{position:absolute;left:64px;top:320px;font-size:22px;font-weight:500;color:rgba(17,17,17,.68);letter-spacing:-.01em}}
.d{{position:absolute;top:70px;width:290px;padding:7px;border-radius:44px 44px 0 0;background:#111}}
.d .s{{border-radius:37px 37px 0 0;overflow:hidden;height:440px}}
.d img{{width:100%;display:block}}
.a{{left:584px;top:96px}} .b{{left:890px;top:40px}}
</style><body>
<img class=logo src="{LOGO}"><div class=n>Period Tracker</div>
<h1>Track your cycle.<br>Nothing else.</h1>
<p>No ads · No account · 100% offline</p>
<div class="d a"><div class=s><img src="{shot("home")}"></div></div>
<div class="d b"><div class=s><img src="{shot("insights")}"></div></div>
</body>"""


def render(name, html, w, h):
    f = OUT / f"{name}.html"
    f.write_text(html)
    subprocess.run(
        [
            CHROME,
            "--headless=new",
            "--disable-gpu",
            "--hide-scrollbars",
            "--force-device-scale-factor=1",
            f"--window-size={w},{h}",
            f"--screenshot={D / (name + '.png')}",
            f"file://{f}",
        ],
        check=True,
        capture_output=True,
    )
    print("rendered", name)


for name, th, title, sub, img, kick in SLIDES:
    render(name, slide(th, title, sub, shot(img), kick), 1080, 1920)
render("feature_graphic", FEATURE, 1024, 500)
