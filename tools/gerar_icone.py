"""Gera a arte do ícone do app (cronômetro minimalista).

Azul claro degradê sobre fundo azul escuro degradê. Produz:
  - icon_full.png       (1024) fundo + cronômetro (ícone legacy)
  - icon_background.png (1024) só o fundo degradê (adaptive background)
  - icon_foreground.png (1024) só o cronômetro, transparente, na safe zone
                                (~66% central) para o adaptive icon.

Rodar com o venv do projeto:
  ./tools_venv/bin/python tools/gerar_icone.py
"""
import math
import os

from PIL import Image, ImageDraw

SS = 4  # supersampling
OUT = 1024
S = OUT * SS

ASSETS = os.path.join(os.path.dirname(__file__), "..", "app", "assets", "icon")

# Cores (RGB).
BG_TOP = (10, 15, 28)     # #0A0F1C  azul quase preto
BG_BOT = (23, 39, 90)     # #17275A  azul escuro
CLOCK_TOP = (173, 221, 255)  # #ADDDFF  azul bem claro
CLOCK_BOT = (59, 130, 246)   # #3B82F6  azul


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def vgrad(size, top, bot):
    """Gradiente vertical (rápido: uma linha por Y)."""
    img = Image.new("RGB", (size, size))
    d = ImageDraw.Draw(img)
    for y in range(size):
        d.line([(0, y), (size, y)], fill=lerp(top, bot, y / (size - 1)))
    return img


def clock_mask(size, scale, cy_frac=0.545):
    """Máscara (L) do cronômetro: anel + haste + ponteiro + centro."""
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    cx = size / 2
    cy = size * cy_frac
    r_out = size * 0.5 * scale
    ring = r_out * 0.165  # espessura do anel
    r_in = r_out - ring

    # Anel: círculo cheio branco menos o furo interno.
    d.ellipse([cx - r_out, cy - r_out, cx + r_out, cy + r_out], fill=255)
    d.ellipse([cx - r_in, cy - r_in, cx + r_in, cy + r_in], fill=0)

    # Haste (botão) no topo do cronômetro.
    sw = r_out * 0.26
    sh = r_out * 0.20
    top = cy - r_out - sh * 0.55
    d.rounded_rectangle(
        [cx - sw / 2, top, cx + sw / 2, top + sh],
        radius=sw * 0.32,
        fill=255,
    )

    # Ponteiro apontando p/ ~1-2h (nordeste).
    ang = math.radians(-58)
    length = r_in * 0.80
    px, py = cx + length * math.cos(ang), cy + length * math.sin(ang)
    d.line([(cx, cy), (px, py)], fill=255, width=int(r_out * 0.075))
    # cap arredondado na ponta
    cap = r_out * 0.037
    d.ellipse([px - cap, py - cap, px + cap, py + cap], fill=255)

    # Miolo central.
    hub = r_out * 0.075
    d.ellipse([cx - hub, cy - hub, cx + hub, cy + hub], fill=255)
    return m


def compor(mask, com_fundo):
    """Aplica o gradiente do relógio na máscara, opcionalmente sobre o fundo."""
    clock = vgrad(S, CLOCK_TOP, CLOCK_BOT).convert("RGBA")
    clock.putalpha(mask)
    if com_fundo:
        base = vgrad(S, BG_TOP, BG_BOT).convert("RGBA")
        base.alpha_composite(clock)
        return base
    return clock


def salvar(img, nome):
    img.resize((OUT, OUT), Image.LANCZOS).save(os.path.join(ASSETS, nome))
    print("ok:", nome)


def main():
    os.makedirs(ASSETS, exist_ok=True)
    # full: relógio maior sobre o fundo.
    salvar(compor(clock_mask(S, 0.74), com_fundo=True), "icon_full.png")
    # adaptive background: só o fundo degradê.
    salvar(vgrad(S, BG_TOP, BG_BOT).convert("RGBA"), "icon_background.png")
    # adaptive foreground: relógio maior e centralizado — o launcher_icons ainda
    # aplica um inset de 16%, então isto resulta em ~0.58 do tile visível.
    salvar(
        compor(clock_mask(S, 0.86, cy_frac=0.5), com_fundo=False),
        "icon_foreground.png",
    )


if __name__ == "__main__":
    main()
