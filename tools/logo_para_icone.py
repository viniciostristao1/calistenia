"""Gera os assets de ícone a partir do logo pronto (quadrado) enviado pelo
usuário. O logo vem com uma MOLDURA PRETA nos cantos (fora do quadrado
arredondado âmbar); ela é removida (preenchida com âmbar) para o ícone ficar
âmbar full-bleed, sem "quadrado em volta". Produz, em app/assets/icon/:
  - icon_full.png       (1024)  âmbar + arte (ícone legacy / iOS)
  - icon_background.png (1024)  âmbar sólido (adaptive background)
  - icon_foreground.png (1024)  o logo âmbar+arte a ~90% (adaptive foreground)
O logo da HOME (logo.png) mantém a arte original (os cantos pretos somem no
fundo navy da home).
Depois: `cd app && dart run flutter_launcher_icons`.
"""
import os

from PIL import Image, ImageDraw

AQUI = os.path.dirname(__file__)
SRC = os.path.join(AQUI, "..", "file_00000000440c820ebc643a945725ef31.png")
ASSETS = os.path.join(AQUI, "..", "app", "assets", "icon")
OUT = 1024
AMBER = (252, 178, 37)  # âmbar do fundo do logo (amostrado)

logo = Image.open(SRC).convert("RGBA")
lado = min(logo.size)
logo = logo.crop((0, 0, lado, lado)).resize((OUT, OUT), Image.LANCZOS)

# --- logo da home = original (cantos pretos somem no navy da home) ---
logo.save(os.path.join(ASSETS, "logo.png"))

# --- remove a moldura preta: flood-fill dos 4 cantos até o âmbar ---
sem_moldura = logo.convert("RGB")
for xy in [(1, 1), (OUT - 2, 1), (1, OUT - 2), (OUT - 2, OUT - 2)]:
    ImageDraw.floodfill(sem_moldura, xy, AMBER, thresh=70)
sem_moldura = sem_moldura.convert("RGBA")

# --- icon_full = âmbar + arte, sem moldura ---
sem_moldura.save(os.path.join(ASSETS, "icon_full.png"))

# --- background âmbar sólido (casa com o full-bleed) ---
Image.new("RGBA", (OUT, OUT), (*AMBER, 255)).save(
    os.path.join(ASSETS, "icon_background.png"))

# --- foreground: âmbar+arte a ~90% (margem âmbar mínima = sem costura) ---
fg = Image.new("RGBA", (OUT, OUT), (0, 0, 0, 0))
lado_fg = int(OUT * 0.90)
mini = sem_moldura.resize((lado_fg, lado_fg), Image.LANCZOS)
off = (OUT - lado_fg) // 2
fg.paste(mini, (off, off), mini)
fg.save(os.path.join(ASSETS, "icon_foreground.png"))
print("ok: moldura preta removida; ícones regenerados")
