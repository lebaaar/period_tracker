from PIL import Image
import pathlib
D = pathlib.Path(__file__).parent
SRC = D / "shots"; DST = D / "comp"; DST.mkdir(exist_ok=True)
H = 2224  # uniform visible source height -> uniform device geometry

# ('k', y0, y1) keep band from source | ('p', n) pad n px of black
PLAN = {
    "home":     [('k', 0, 1745), ('k', 1825, 2304)],
    "insights": [('k', 0, 2224)],
    "profile":  [('k', 0, 2224)],
    "restore":  [('k', 0, 140), ('p', 240), ('k', 900, 1660), ('p', 1084)],
}

for name, plan in PLAN.items():
    src = Image.open(SRC / f"{name}.png").convert("RGB")
    out = Image.new("RGB", (1080, H), (0, 0, 0))
    y = 0
    for op in plan:
        if op[0] == 'k':
            band = src.crop((0, op[1], 1080, op[2]))
            out.paste(band, (0, y)); y += band.height
        else:
            y += op[1]
    assert y == H, (name, y)
    out.save(DST / f"{name}.png")
    print(name, "->", out.size)
