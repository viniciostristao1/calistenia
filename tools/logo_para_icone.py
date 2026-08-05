"""Gera os assets de ícone a partir do logo pronto (quadrado) enviado pelo
usuário. Produz, em app/assets/icon/:
  - icon_full.png       (1024)  o logo (ícone legacy / iOS)
  - icon_background.png (1024)  âmbar sólido amostrado do logo (adaptive bg)
  - icon_foreground.png (1024)  o logo na safe zone (~78%), transparente
  - logo.png                    o logo p/ a home
Depois: `cd app && dart run flutter_launcher_icons`.
"""
import os

from PIL import Image

AQUI = os.path.dirname(__file__)
SRC = os.path.join(AQUI, "..", "file_00000000440c820ebc643a945725ef31.png")
ASSETS = os.path.join(AQUI, "..", "app", "assets", "icon")
OUT = 1024

logo = Image.open(SRC).convert("RGBA")
# Quadra (caso não seja perfeitamente quadrado) e redimensiona para 1024.
lado = min(logo.size)
logo = logo.crop((0, 0, lado, lado)).resize((OUT, OUT), Image.LANCZOS)

# --- icon_full + logo da home = o próprio logo ---
logo.save(os.path.join(ASSETS, "icon_full.png"))
logo.save(os.path.join(ASSETS, "logo.png"))

# --- amostra o âmbar do fundo (borda esquerda, meia altura) p/ o background ---
px = logo.convert("RGB").getpixel((int(OUT * 0.06), OUT // 2))
bg = Image.new("RGBA", (OUT, OUT), (px[0], px[1], px[2], 255))
bg.save(os.path.join(ASSETS, "icon_background.png"))
print("background amber =", px)

# --- foreground: o logo reduzido à safe zone (~78%), centralizado, transparente ---
fg = Image.new("RGBA", (OUT, OUT), (0, 0, 0, 0))
escala = 0.80
lado_fg = int(OUT * escala)
mini = logo.resize((lado_fg, lado_fg), Image.LANCZOS)
off = (OUT - lado_fg) // 2
fg.paste(mini, (off, off), mini)
fg.save(os.path.join(ASSETS, "icon_foreground.png"))
print("ok: icon_full/background/foreground/logo gerados")
