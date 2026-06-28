from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "store_assets"
OUT.mkdir(exist_ok=True)
BRANDING = ROOT / "assets" / "branding"
BRANDING.mkdir(parents=True, exist_ok=True)

canva_logo = OUT / "applymate-canva-logo-thumbnail.png"
icon_out = OUT / "applymate-icon-512.png"


def make_app_icon() -> Image.Image:
    if canva_logo.exists():
        src = Image.open(canva_logo).convert("RGBA")
        # Crop the Canva icon mark, excluding the wordmark below it.
        mark = src.crop((165, 135, 283, 263)).resize((292, 292), Image.Resampling.LANCZOS)
    else:
        mark = Image.open(ROOT / "web" / "icons" / "Icon-512.png").convert("RGBA").resize((292, 292), Image.Resampling.LANCZOS)

    icon = Image.new("RGB", (512, 512), "#eff7ff")
    d = ImageDraw.Draw(icon)
    d.rounded_rectangle((76, 76, 436, 436), radius=96, fill="#2f98f0")
    icon.paste(mark, ((512 - mark.width) // 2, (512 - mark.height) // 2), mark)
    return icon


app_icon = make_app_icon()
app_icon.save(icon_out, optimize=True)
app_icon.save(BRANDING / "applymate-logo.png", optimize=True)

W, H = 1024, 500
img = Image.new("RGB", (W, H), "#f7fbff")
draw = ImageDraw.Draw(img)

blue = "#1b3a6b"
cyan = "#37b7ee"
green = "#18a999"
ink = "#102033"
muted = "#536579"
line = "#d7e5f4"
white = "#ffffff"

font_regular = "C:/Windows/Fonts/segoeui.ttf"
font_bold = "C:/Windows/Fonts/segoeuib.ttf"
title_font = ImageFont.truetype(font_bold, 68)
subtitle_font = ImageFont.truetype(font_regular, 30)
small_font = ImageFont.truetype(font_regular, 23)
label_font = ImageFont.truetype(font_bold, 24)

for y in range(H):
    ratio = y / H
    r = int(247 * (1 - ratio) + 231 * ratio)
    g = int(251 * (1 - ratio) + 243 * ratio)
    b = int(255 * (1 - ratio) + 250 * ratio)
    draw.line((0, y, W, y), fill=(r, g, b))

draw.rounded_rectangle((620, 44, 934, 456), radius=36, fill=white, outline=line, width=3)
draw.rounded_rectangle((650, 80, 904, 130), radius=12, fill="#ecf6ff")
draw.rounded_rectangle((650, 154, 904, 184), radius=9, fill="#e7eef7")
draw.rounded_rectangle((650, 202, 850, 232), radius=9, fill="#e7eef7")
draw.rounded_rectangle((650, 272, 904, 330), radius=14, fill="#f1f7fb", outline=line, width=2)
draw.rounded_rectangle((672, 290, 752, 312), radius=8, fill=cyan)
draw.rounded_rectangle((772, 290, 880, 312), radius=8, fill="#dce9f7")
draw.rounded_rectangle((650, 354, 904, 408), radius=14, fill="#f1f7fb", outline=line, width=2)
draw.ellipse((668, 368, 702, 402), fill=green)
draw.rounded_rectangle((720, 370, 884, 386), radius=8, fill="#dce9f7")
draw.rounded_rectangle((720, 392, 826, 402), radius=5, fill="#edf3fa")

draw.rounded_rectangle((66, 70, 158, 162), radius=24, fill=white, outline=line, width=2)
icon = app_icon.resize((72, 72), Image.Resampling.LANCZOS).convert("RGBA")
img.paste(icon, (76, 80), icon)

draw.text((66, 190), "ApplyMate", fill=ink, font=title_font)
draw.text((70, 278), "AI resume, cover letter", fill=blue, font=subtitle_font)
draw.text((70, 318), "and job search tools", fill=blue, font=subtitle_font)

chips = [
    ("Resume Builder", cyan),
    ("ATS Check", green),
    ("Cover Letters", blue),
]
x = 70
for label, color in chips:
    bbox = draw.textbbox((0, 0), label, font=label_font)
    tw = bbox[2] - bbox[0]
    draw.rounded_rectangle((x, 390, x + tw + 34, 436), radius=22, fill=color)
    draw.text((x + 17, 397), label, fill=white, font=label_font)
    x += tw + 48

img.save(OUT / "applymate-feature-graphic-1024x500.png", optimize=True)

print(icon_out)
print(OUT / "applymate-feature-graphic-1024x500.png")
