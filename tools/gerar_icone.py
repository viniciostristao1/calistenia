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


def clock_mask(size, scale, cy_frac=0.53):
    """Máscara (L) do cronômetro: anel + botão no topo + marcadores + ponteiro."""
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    cx = size / 2
    cy = size * cy_frac
    r_out = size * 0.5 * scale
    ring = r_out * 0.15  # espessura do anel
    r_in = r_out - ring

    # Anel: círculo cheio branco menos o furo interno.
    d.ellipse([cx - r_out, cy - r_out, cx + r_out, cy + r_out], fill=255)
    d.ellipse([cx - r_in, cy - r_in, cx + r_in, cy + r_in], fill=0)

    # Botão estilo cronômetro no topo: haste + tampa larga arredondada.
    sw = r_out * 0.16
    sh = r_out * 0.17
    stem_top = cy - r_out - sh * 0.7
    d.rounded_rectangle(
        [cx - sw / 2, stem_top, cx + sw / 2, cy - r_out + ring * 0.4],
        radius=sw * 0.4,
        fill=255,
    )
    cap_w = r_out * 0.44
    cap_h = r_out * 0.17
    cap_top = stem_top - cap_h * 0.78
    d.rounded_rectangle(
        [cx - cap_w / 2, cap_top, cx + cap_w / 2, cap_top + cap_h],
        radius=cap_h * 0.5,
        fill=255,
    )

    # Marcadores nas 12h, 3h, 6h e 9h (dentro do anel).
    mk = r_out * 0.052
    rm = r_in * 0.80
    for (mx, my) in [(cx, cy - rm), (cx + rm, cy), (cx, cy + rm), (cx - rm, cy)]:
        d.ellipse([mx - mk, my - mk, mx + mk, my + mk], fill=255)

    # Ponteiro apontando p/ ~1-2h (nordeste), curto p/ não bater nos marcadores.
    ang = math.radians(-58)
    length = r_in * 0.60
    px, py = cx + length * math.cos(ang), cy + length * math.sin(ang)
    d.line([(cx, cy), (px, py)], fill=255, width=int(r_out * 0.07))
    cap = r_out * 0.033
    d.ellipse([px - cap, py - cap, px + cap, py + cap], fill=255)

    # Miolo central.
    hub = r_out * 0.072
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
    # full: relógio com bastante margem sobre o fundo (menor ainda).
    salvar(compor(clock_mask(S, 0.50, cy_frac=0.52), com_fundo=True), "icon_full.png")
    # adaptive background: só o fundo degradê.
    salvar(vgrad(S, BG_TOP, BG_BOT).convert("RGBA"), "icon_background.png")
    # adaptive foreground: o launcher_icons ainda aplica inset de 16%.
    salvar(
        compor(clock_mask(S, 0.62, cy_frac=0.5), com_fundo=False),
        "icon_foreground.png",
    )
    # logo p/ usar DENTRO do app (transparente, relógio preenchendo o quadro).
    salvar(
        compor(clock_mask(S, 0.82, cy_frac=0.54), com_fundo=False),
        "logo.png",
    )


if __name__ == "__main__":
    main()
