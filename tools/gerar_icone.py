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

# Cores (RGB) — estilo lista_app: cronômetro PRETO sobre âmbar degradê (um
# tom mais escuro, mais próximo do lista_app).
BG_TOP = (223, 175, 77)   # #DFAF4D  âmbar
BG_BOT = (197, 137, 50)   # #C58932  âmbar quente/escuro
CLOCK_BLACK = (26, 26, 26)   # #1A1A1A  linhas do cronômetro (preto suave)
LOGO_AMBER = (240, 176, 66)  # #F0B042  cronômetro no logo (sobre o navy da home)


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def vgrad(size, top, bot):
    """Gradiente vertical (rápido: uma linha por Y)."""
    img = Image.new("RGB", (size, size))
    d = ImageDraw.Draw(img)
    for y in range(size):
        d.line([(0, y), (size, y)], fill=lerp(top, bot, y / (size - 1)))
    return img


def _oriented_rect(d, cx, cy, dist, ang, length, width, fill, round_cap=True):
    """Desenha um retângulo orientado radialmente (centro a `dist` do centro,
    no ângulo `ang`), opcionalmente com a ponta externa arredondada."""
    dx, dy = math.cos(ang), math.sin(ang)
    px, py = -dy, dx  # perpendicular
    bcx, bcy = cx + dist * dx, cy + dist * dy
    corners = []
    for sl in (1, -1):
        for sw in (1, -1):
            corners.append((
                bcx + sl * (length / 2) * dx + sl * sw * (width / 2) * px,
                bcy + sl * (length / 2) * dy + sl * sw * (width / 2) * py,
            ))
    d.polygon(corners, fill=fill)
    if round_cap:
        # ponta externa arredondada
        ex, ey = bcx + (length / 2) * dx, bcy + (length / 2) * dy
        r = width / 2
        d.ellipse([ex - r, ey - r, ex + r, ey + r], fill=fill)


def clock_mask(size, scale, cy_frac=0.52):
    """Máscara (L) do cronômetro: anel + botão no topo + botão lateral (NE) +
    ponteiro afilado (sem marcadores). Segue a referência do usuário."""
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

    # Botão de topo: haste + tampa larga arredondada.
    sw = r_out * 0.17
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

    # Botão lateral no canto superior-direito (nordeste), saindo do anel.
    aL = math.radians(-52)
    _oriented_rect(
        d, cx, cy,
        dist=r_out + r_out * 0.42 * 0.18,
        ang=aL,
        length=r_out * 0.42,
        width=r_out * 0.21,
        fill=255,
    )

    # Ponteiro afilado (triângulo) apontando p/ ~1-2h (nordeste).
    aP = math.radians(-58)
    L = r_in * 0.66
    dx, dy = math.cos(aP), math.sin(aP)
    px, py = -dy, dx
    baseW = r_out * 0.135
    d.polygon([
        (cx + L * dx, cy + L * dy),          # ponta
        (cx + (baseW / 2) * px, cy + (baseW / 2) * py),  # base 1
        (cx - (baseW / 2) * px, cy - (baseW / 2) * py),  # base 2
    ], fill=255)

    # Miolo central.
    hub = r_out * 0.085
    d.ellipse([cx - hub, cy - hub, cx + hub, cy + hub], fill=255)
    return m


def compor(mask, com_fundo, clock_color=CLOCK_BLACK):
    """Aplica a cor do relógio na máscara, opcionalmente sobre o fundo âmbar."""
    clock = Image.new("RGB", (S, S), clock_color).convert("RGBA")
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
    # full: cronômetro PRETO menor e um pouco mais p/ baixo, sobre âmbar.
    salvar(compor(clock_mask(S, 0.46, cy_frac=0.55), com_fundo=True), "icon_full.png")
    # adaptive background: só o âmbar degradê.
    salvar(vgrad(S, BG_TOP, BG_BOT).convert("RGBA"), "icon_background.png")
    # adaptive foreground: cronômetro preto (o launcher_icons aplica inset 16%).
    salvar(
        compor(clock_mask(S, 0.58, cy_frac=0.52), com_fundo=False),
        "icon_foreground.png",
    )
    # logo p/ usar DENTRO do app (âmbar transparente, sobre o navy da home).
    salvar(
        compor(clock_mask(S, 0.82, cy_frac=0.54), com_fundo=False,
               clock_color=LOGO_AMBER),
        "logo.png",
    )


if __name__ == "__main__":
    main()
