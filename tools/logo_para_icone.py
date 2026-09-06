"""Gera os assets de icone a partir do novo logo file_00000000c230820eb5a52ce3318f075c.png"""
import os
from PIL import Image
AQUI = os.path.dirname(__file__)
SRC = os.path.join(AQUI, "..", "file_00000000c230820eb5a52ce3318f075c.png")
ASSETS = os.path.join(AQUI, "..", "app", "assets", "icon")
OUT = 1024
logo = Image.open(SRC).convert("RGBA")
lado = min(logo.size)
cx, cy = logo.size[0] // 2, logo.size[1] // 2
logo = logo.crop((cx - lado // 2, cy - lado // 2, cx + lado // 2, cy + lado // 2)).resize((OUT, OUT), Image.LANCZOS)
logo.save(os.path.join(ASSETS, "logo.png"))
logo.save(os.path.join(ASSETS, "icon_full.png"))
bg = logo.getpixel((5, 5))[:3]
Image.new("RGBA", (OUT, OUT), (*bg, 255)).save(os.path.join(ASSETS, "icon_background.png"))
fg = Image.new("RGBA", (OUT, OUT), (0, 0, 0, 0))
lado_fg = int(OUT * 0.90)
mini = logo.resize((lado_fg, lado_fg), Image.LANCZOS)
off = (OUT - lado_fg) // 2
fg.paste(mini, (off, off), mini)
fg.save(os.path.join(ASSETS, "icon_foreground.png"))
print("ok: icones regenerados a partir do novo logo")
