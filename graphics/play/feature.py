import subprocess, pathlib, importlib.util
spec = importlib.util.spec_from_file_location("b", "build.py")
# reuse CSS pieces without re-rendering shots: read build.py constants directly
src = pathlib.Path("build.py").read_text()
import base64
D = pathlib.Path(".")
def b64(p, mime):
    return f"data:{mime};base64," + base64.b64encode(pathlib.Path(p).read_bytes()).decode()
FONTS = "".join(
    f"@font-face{{font-family:'Lexend';font-style:normal;font-weight:{w};"
    f"src:url({b64(D/'fonts'/f'Lexend-{w}.ttf','font/ttf')}) format('truetype');}}"
    for w in (300, 400, 500, 600, 700, 800))
LOGO = b64("logo.png", "image/png")
PHONE = b64("comp/home.png", "image/png")
GRAIN = ("data:image/svg+xml;base64," + base64.b64encode(
    b"""<svg xmlns='http://www.w3.org/2000/svg' width='200' height='200'>
    <filter id='n'><feTurbulence type='fractalNoise' baseFrequency='.85' numOctaves='3'/>
    <feColorMatrix type='saturate' values='0'/></filter>
    <rect width='200' height='200' filter='url(#n)' opacity='.5'/></svg>""").decode())
PINK = "#FF91C5"

html = f"""<!doctype html><meta charset=utf-8><style>
{FONTS}
*{{margin:0;padding:0;box-sizing:border-box}}
html,body{{width:1024px;height:500px;overflow:hidden}}
body{{font-family:'Lexend',sans-serif;background:#08050A;color:#fff;-webkit-font-smoothing:antialiased}}
.stage{{position:relative;width:1024px;height:500px;overflow:hidden}}
.bg::before{{content:'';position:absolute;inset:0;
  background:linear-gradient(120deg,#160814 0%,#07040A 55%,#0E050F 100%)}}
.bloom{{position:absolute;border-radius:50%;filter:blur(110px)}}
.b1{{width:620px;height:620px;background:{PINK};opacity:.22;left:-120px;top:-200px}}
.b2{{width:520px;height:520px;background:#8E4BFF;opacity:.15;left:560px;top:180px}}
.grid{{position:absolute;inset:0;opacity:.30;
  background-image:radial-gradient(rgba(255,255,255,.10) 1.2px,transparent 1.2px);
  background-size:30px 30px;
  -webkit-mask-image:radial-gradient(ellipse 65% 80% at 30% 40%,#000 0%,transparent 75%)}}
.grain{{position:absolute;inset:0;background-image:url({GRAIN});background-size:200px 200px;
  opacity:.05;mix-blend-mode:overlay}}
.vig{{position:absolute;inset:0;background:radial-gradient(ellipse 75% 90% at 34% 50%,transparent 30%,rgba(0,0,0,.72) 100%)}}
.left{{position:absolute;left:76px;top:50%;transform:translateY(-50%);z-index:3;width:560px}}
.brand{{display:flex;align-items:center;gap:20px;margin-bottom:26px}}
.brand img{{width:70px;height:70px;border-radius:50%;
  box-shadow:0 0 46px -6px rgba(255,145,197,.65)}}
.brand span{{font-size:34px;font-weight:700;letter-spacing:-.02em}}
h1{{font-size:52px;line-height:1.08;font-weight:800;letter-spacing:-.03em}}
h1 em{{font-style:normal;color:{PINK}}}
.chips{{margin-top:26px;display:flex;gap:12px}}
.chip{{font-size:18px;font-weight:500;padding:11px 20px;border-radius:100px;
  color:rgba(255,255,255,.88);background:rgba(255,255,255,.055);
  border:1.5px solid rgba(255,255,255,.13)}}
.device{{position:absolute;z-index:2;right:74px;top:52px;width:268px;border-radius:34px;
  padding:6px;background:#111014;transform:rotate(-6deg);
  box-shadow:0 0 0 1.2px rgba(255,255,255,.14),0 0 0 6px rgba(255,145,197,.06),
             0 40px 80px -20px rgba(0,0,0,.95),0 0 120px -20px rgba(255,145,197,.35)}}
.screen{{border-radius:29px;overflow:hidden;background:#000;height:520px}}
.screen img{{width:100%;display:block}}
</style><body>
<div class=stage>
  <div class=bg><div class="bloom b1"></div><div class="bloom b2"></div>
    <div class=grid></div><div class=vig></div><div class=grain></div></div>
  <div class=device><div class=screen><img src="{PHONE}"></div></div>
  <div class=left>
    <div class=brand><img src="{LOGO}"><span>Period Tracker</span></div>
    <h1>Track your cycle.<br><em>Nothing else.</em></h1>
    <div class=chips><div class=chip>No ads</div><div class=chip>No account</div>
      <div class=chip>100% offline</div></div>
  </div>
</div></body>"""
f = pathlib.Path("out/feature_graphic.html"); f.write_text(html)
subprocess.run(["/usr/bin/chromium-browser","--headless=new","--disable-gpu","--hide-scrollbars",
                "--force-device-scale-factor=1","--window-size=1024,500",
                "--screenshot=out/feature_graphic.png", f"file://{f.resolve()}"],
               check=True, capture_output=True)
print("rendered feature graphic")
