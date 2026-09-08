import base64, os, subprocess, pathlib

D = pathlib.Path(__file__).parent
OUT = D / "out"
OUT.mkdir(exist_ok=True)

def b64(p, mime):
    return f"data:{mime};base64," + base64.b64encode(pathlib.Path(p).read_bytes()).decode()

FONTS = "".join(
    f"@font-face{{font-family:'Lexend';font-style:normal;font-weight:{w};"
    f"src:url({b64(D/'fonts'/f'Lexend-{w}.ttf','font/ttf')}) format('truetype');}}"
    for w in (300, 400, 500, 600, 700, 800)
)

IMG = {n: b64(D / "comp" / f"{n}.png", "image/png") for n in
       ("home", "insights", "profile", "restore")}
LOGO = b64(D / "logo.png", "image/png")

PINK = "#FF91C5"

GRAIN = ("data:image/svg+xml;base64," + base64.b64encode(
    b"""<svg xmlns='http://www.w3.org/2000/svg' width='200' height='200'>
    <filter id='n'><feTurbulence type='fractalNoise' baseFrequency='.85' numOctaves='3'/>
    <feColorMatrix type='saturate' values='0'/></filter>
    <rect width='200' height='200' filter='url(#n)' opacity='.5'/></svg>""").decode())

CSS = f"""
{FONTS}
*{{margin:0;padding:0;box-sizing:border-box}}
html,body{{width:1080px;height:1920px;overflow:hidden}}
body{{font-family:'Lexend',sans-serif;background:#08050A;color:#fff;
  -webkit-font-smoothing:antialiased}}
.stage{{position:relative;width:1080px;height:1920px;overflow:hidden;isolation:isolate}}

/* ---- background ---- */
.bg{{position:absolute;inset:0;z-index:0}}
.bg::before{{content:'';position:absolute;inset:0;
  background:linear-gradient(168deg,#150713 0%,#07040A 46%,#0D050F 100%)}}
.bloom{{position:absolute;border-radius:50%;filter:blur(150px)}}
.bloom.a{{width:980px;height:980px;background:{PINK};opacity:.22}}
.bloom.b{{width:760px;height:760px;background:#8E4BFF;opacity:.13}}
.grid{{position:absolute;inset:0;opacity:.35;
  background-image:radial-gradient(rgba(255,255,255,.10) 1.4px,transparent 1.4px);
  background-size:44px 44px;
  -webkit-mask-image:radial-gradient(ellipse 70% 55% at 50% 30%,#000 0%,transparent 72%)}}
.grain{{position:absolute;inset:0;background-image:url({GRAIN});
  background-size:200px 200px;opacity:.05;mix-blend-mode:overlay}}
.vig{{position:absolute;inset:0;
  background:radial-gradient(ellipse 82% 62% at 50% 38%,transparent 34%,rgba(0,0,0,.80) 100%)}}

/* ---- copy ---- */
.copy{{position:absolute;z-index:3;left:88px;right:88px;top:118px;text-align:center}}
h1{{font-size:76px;line-height:1.06;font-weight:800;letter-spacing:-.032em;
  text-wrap:balance}}
h1 em{{font-style:normal;color:{PINK}}}
.sub{{margin-top:30px;min-height:92px;font-size:31px;line-height:1.48;font-weight:300;
  color:rgba(255,255,255,.60);max-width:790px;margin-left:auto;margin-right:auto;
  text-wrap:balance}}

/* ---- device ---- */
.device{{position:absolute;z-index:2;left:50%;transform:translateX(-50%);
  width:672px;border-radius:62px;padding:13px;background:#111014;
  box-shadow:0 0 0 1.5px rgba(255,255,255,.13),
             0 0 0 9px rgba(255,145,197,.055),
             0 60px 130px -30px rgba(0,0,0,.95),
             0 0 190px -25px rgba(255,145,197,.34)}}
.screen{{position:relative;border-radius:50px;overflow:hidden;background:#000;
  height:1330px}}
.screen img{{width:100%;display:block}}
.gloss{{position:absolute;inset:0;pointer-events:none;
  background:linear-gradient(196deg,rgba(255,255,255,.085) 0%,transparent 34%)}}
.fade{{position:absolute;left:0;right:0;bottom:0;height:190px;z-index:4;
  background:linear-gradient(to top,#08040B 8%,rgba(8,4,11,0) 100%)}}

/* ---- chips ---- */
.chips{{margin-top:44px;display:flex;gap:16px;justify-content:center;flex-wrap:wrap}}
.chip{{font-size:24px;font-weight:500;letter-spacing:.01em;
  padding:14px 28px;border-radius:100px;color:rgba(255,255,255,.86);
  background:rgba(255,255,255,.055);border:1.5px solid rgba(255,255,255,.12);
  backdrop-filter:blur(6px)}}

/* ---- final card ---- */
.final{{position:absolute;z-index:3;inset:0;display:flex;flex-direction:column;
  align-items:center;justify-content:center;padding:0 100px;text-align:center}}
.logo{{width:210px;height:210px;border-radius:50%;margin-bottom:56px;
  box-shadow:0 0 130px -10px rgba(255,145,197,.6),0 30px 70px -20px rgba(0,0,0,.9)}}
.final h1{{font-size:86px}}
.final .sub{{font-size:33px;margin-top:34px}}
.stack{{margin-top:74px;display:flex;flex-direction:column;gap:22px;width:100%;
  max-width:620px}}
.row{{display:flex;align-items:center;gap:22px;text-align:left;
  padding:24px 32px;border-radius:26px;
  background:rgba(255,255,255,.045);border:1.5px solid rgba(255,255,255,.10)}}
.row .tick{{flex:0 0 auto;width:40px;height:40px;border-radius:50%;
  background:{PINK};color:#12060C;font-size:24px;font-weight:800;
  display:flex;align-items:center;justify-content:center}}
.row span{{font-size:29px;font-weight:400;color:rgba(255,255,255,.90)}}
"""


def page(body):
    return f"<!doctype html><meta charset=utf-8><style>{CSS}</style><body>{body}</body>"


def shot(img, title, sub, chips, bloom, top=160, dev_top=660, shift=0):
    ba, bb = bloom
    chip_html = "".join(f"<div class=chip>{c}</div>" for c in chips)
    return page(f"""
<div class=stage>
  <div class=bg>
    <div class="bloom a" style="left:{ba[0]}px;top:{ba[1]}px"></div>
    <div class="bloom b" style="left:{bb[0]}px;top:{bb[1]}px"></div>
    <div class=grid></div><div class=vig></div><div class=grain></div>
  </div>
  <div class=copy style="top:{top}px">
    <h1>{title}</h1>
    <div class=sub>{sub}</div>
    <div class=chips>{chip_html}</div>
  </div>
  <div class=device style="top:{dev_top}px">
    <div class=screen><img src="{img}" style="margin-top:{shift}px"><div class=gloss></div></div>
  </div>
  <div class=fade></div>
</div>""")


SHOTS = [
    dict(name="01_home", img=IMG["home"],
         title="Your next period,<br><em>always in sight</em>",
         sub="Cycle day, countdown and a calendar you can read at a glance.",
         chips=["No ads", "No account", "100% offline"],
         bloom=((-140, 240), (700, 1180))),
    dict(name="02_insights", img=IMG["insights"],
         title="Gain insights<br><em>from every cycle</em>",
         sub="Average cycle and period length, computed as you go",
         chips=["Full period history", "One tap to log"],
         bloom=((620, 180), (-160, 1080))),
    dict(name="03_reminders", img=IMG["profile"],
         title="A heads-up<br><em>before it starts</em>",
         sub="Choose how many days ahead you get notified. Nothing else pings you.",
         chips=["Custom lead time", "Dynamic or fixed cycle"],
         bloom=((640, 900), (-120, 200))),
    dict(name="04_restore", img=IMG["restore"],
         title="Switch phones,<br><em>keep everything</em>",
         sub="Move your history across devices with one file. No cloud involved.",
         chips=["Offline transfer", "One file"],
         bloom=((-100, 300), (620, 1220))),
]

FINAL = page(f"""
<div class=stage>
  <div class=bg>
    <div class="bloom a" style="left:-60px;top:420px"></div>
    <div class="bloom b" style="left:620px;top:1000px"></div>
    <div class=grid></div><div class=vig></div><div class=grain></div>
  </div>
  <div class=final>
    <img class=logo src="{LOGO}">
    <h1>Period tracking,<br><em>and nothing else</em></h1>
    <div class=sub>No ads, no paywall, no account.</div>
    <div class=stack>
      <div class=row><div class=tick>&#10003;</div><span>No account, no internet needed</span></div>
      <div class=row><div class=tick>&#10003;</div><span>Free and open source</span></div>
      <div class=row><div class=tick>&#10003;</div><span>No ads, ever</span></div>
      <div class=row><div class=tick>&#10003;</div><span>No premium, no paywall</span></div>
    </div>
  </div>
</div>""")

pages = [(s["name"], shot(**{k: v for k, v in s.items() if k != "name"})) for s in SHOTS]
pages.append(("05_promise", FINAL))

CHROME = "/usr/bin/chromium-browser"
for name, html in pages:
    f = OUT / f"{name}.html"
    f.write_text(html)
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                    "--force-device-scale-factor=1", "--window-size=1080,1920",
                    "--default-background-color=00000000",
                    f"--screenshot={OUT/(name+'.png')}", f"file://{f}"],
                   check=True, capture_output=True)
    print("rendered", name)
