"""Gera os assets de ícone a partir do logo do app (arquivo na raiz do repo).

Uso:  ./tools_venv/bin/python tools/logo_para_icone.py [arquivo.png]

Produz em app/assets/icon/: logo.png (usado na home), icon_full.png (ícone
legacy), icon_background.png (fundo do adaptive) e icon_foreground.png (arte
com transparência na safe zone). Também atualiza os ícones da web.

Depois rode `dart run flutter_launcher_icons` dentro de app/.
"""
import os
import sys

from PIL import Image

AQUI = os.path.dirname(__file__)
PADRAO = "file_000000000b10820e9dd5bc7e7891d5c3.png"
SRC = os.path.join(AQUI, "..", sys.argv[1] if len(sys.argv) > 1 else PADRAO)
ASSETS = os.path.join(AQUI, "..", "app", "assets", "icon")
WEB = os.path.join(AQUI, "..", "app", "web")
OUT = 1024

logo = Image.open(SRC).convert("RGBA")
lado = min(logo.size)
cx, cy = logo.size[0] // 2, logo.size[1] // 2
logo = logo.crop(
    (cx - lado // 2, cy - lado // 2, cx + lado // 2, cy + lado // 2)
).resize((OUT, OUT), Image.LANCZOS)
# icon_full = badge CHEIO (moldura neon quadrada) — vira o ícone do launcher.
logo.save(os.path.join(ASSETS, "icon_full.png"))
# logo.png = o logo DA HOME (ao lado de "Calis Timer"): aproxima no cronômetro,
# removendo a moldura quadrada neon (o usuário quer só o cronômetro, maior).
# Inset ~10.8% de cada lado = a arte do cronômetro preenche o quadro; os cantos
# com glow residual somem no ClipRRect(radius 8) da home.
inset = int(OUT * 0.108)
home = logo.crop((inset, inset, OUT - inset, OUT - inset)).resize(
    (OUT, OUT), Image.LANCZOS
)
home.save(os.path.join(ASSETS, "logo.png"))
bg = logo.getpixel((5, 5))[:3]
Image.new("RGBA", (OUT, OUT), (*bg, 255)).save(
    os.path.join(ASSETS, "icon_background.png")
)
fg = Image.new("RGBA", (OUT, OUT), (0, 0, 0, 0))
lado_fg = int(OUT * 0.90)
mini = logo.resize((lado_fg, lado_fg), Image.LANCZOS)
off = (OUT - lado_fg) // 2
fg.paste(mini, (off, off), mini)
fg.save(os.path.join(ASSETS, "icon_foreground.png"))

for nome, tam in [
    ("favicon.png", 32),
    ("icons/Icon-192.png", 192),
    ("icons/Icon-512.png", 512),
    ("icons/Icon-maskable-192.png", 192),
    ("icons/Icon-maskable-512.png", 512),
]:
    logo.resize((tam, tam), Image.LANCZOS).save(os.path.join(WEB, nome))

print("ok: ícones regenerados a partir do novo logo")
