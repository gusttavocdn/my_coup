# -*- coding: utf-8 -*-
"""Extrai os SVGs do canvas de design (design/ui/referencia) para assets/arte/design.

Os quadros são HTML estático com SVG inline. O Godot (ThorVG) não desenha <text>,
então só saem peças sem texto: retratos, ícones, verso, moedas, avatares, cenários.
Rode da raiz do projeto: python tools/extract_design_assets.py
"""
import os
import re

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
SRC = os.path.join(ROOT, "design", "ui", "referencia")
OUT = os.path.join(ROOT, "assets", "arte", "design")

KEEP = ("viewBox", "fill", "stroke", "stroke-width", "stroke-linecap", "stroke-linejoin")


def read(name):
    with open(os.path.join(SRC, name), encoding="utf-8") as handle:
        return handle.read()


def svg_blocks(text):
    """Every <svg> in [text] as (start, end, opening tag), outermost first by position."""
    blocks, stack = [], []
    for match in re.finditer(r"<svg\b[^>]*>|</svg>", text):
        if match.group(0).startswith("</"):
            start, tag = stack.pop()
            blocks.append((start, match.end(), tag, len(stack)))
        elif not match.group(0).endswith("/>"):
            stack.append((match.start(), match.group(0)))
    return sorted(blocks)


def standalone(text, start, end, tag):
    """The block as a self-contained .svg file (drops layout style, aria and role)."""
    attrs = dict(re.findall(r'([\w:-]+)="([^"]*)"', tag))
    view = attrs["viewBox"]
    _x, _y, width, height = view.split()
    inner = text[start:end]
    inner = inner[len(tag):-len("</svg>")]
    kept = "".join(' %s="%s"' % (key, attrs[key]) for key in KEEP if key in attrs and key != "viewBox")
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="%s" width="%s" height="%s"%s>%s</svg>\n' % (
        view, width, height, kept, inner)


def clip_circle(svg):
    """The canvas clips avatars to a circle with CSS; bake that into the SVG."""
    head_end = svg.index(">") + 1
    return (svg[:head_end]
            + '<defs><clipPath id="round"><circle cx="28" cy="28" r="28"/></clipPath></defs>'
            + '<g clip-path="url(#round)">' + svg[head_end:].replace("</svg>", "</g></svg>"))


def write(name, content):
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, name), "w", encoding="utf-8", newline="\n") as handle:
        handle.write(content)


def top_level(text, view_prefix=None, label=None):
    """Blocks outside <defs> symbols (depth 0), optionally filtered by viewBox or aria-label."""
    found = []
    for start, end, tag, depth in svg_blocks(text):
        if depth != 0 or 'width="0"' in tag:
            continue
        if view_prefix and 'viewBox="%s' % view_prefix not in tag:
            continue
        if label and label not in tag:
            continue
        found.append((start, end, tag))
    return found


def main():
    # Characters: portrait (260x250) and the 38x38 ability icons (action first, block last).
    cards = {"duque": "Main", "assassino": "Assassino", "capitao": "Capitao",
             "embaixador": "Embaixador", "condessa": "Condessa", "inquisidor": "Inquisidor"}
    for ident, board in cards.items():
        text = read(board + ".dc.html")
        blocks = svg_blocks(text)
        portrait = [b for b in blocks if 'viewBox="0 0 260 250"' in b[2]][0]
        write("retrato_%s.svg" % ident, standalone(text, portrait[0], portrait[1], portrait[2]))
        icons = [b for b in blocks if 'viewBox="0 0 40 40"' in b[2] and b[3] == portrait[3]]
        names = ["acao", "bloqueio"] if len(icons) == 2 else ["acao", "acao2", "bloqueio"]
        for name, block in zip(names, icons):
            write("icone_%s_%s.svg" % (ident, name), standalone(text, block[0], block[1], block[2]))

    # Card back and coins.
    text = read("Verso.dc.html")
    back = [b for b in svg_blocks(text) if 'viewBox="0 0 276 396"' in b[2]][0]
    write("verso.svg", standalone(text, back[0], back[1], back[2]))
    text = read("Moedas.dc.html")
    coins = [b for b in svg_blocks(text) if 'viewBox="0 0 140 140"' in b[2]]
    write("moeda_ouro.svg", standalone(text, coins[0][0], coins[0][1], coins[0][2]))
    write("moeda_prata.svg", standalone(text, coins[1][0], coins[1][1], coins[1][2]))

    # Table pieces from the desktop and phone boards.
    desktop = read("Desktop.dc.html")
    mobile = read("Mobile.dc.html")
    start, end, tag = top_level(desktop, view_prefix="0 0 1440 900")[0]
    write("cenario_paisagem.svg", standalone(desktop, start, end, tag))
    start, end, tag = top_level(mobile, view_prefix="0 0 390 844")[0]
    write("cenario_retrato.svg", standalone(mobile, start, end, tag))

    avatars = {}
    for who in ("Marina", "Rafa", "Bia"):
        start, end, tag = top_level(desktop, label="Avatar de %s" % who)[0]
        avatars[who.lower()] = clip_circle(standalone(desktop, start, end, tag))
        write("avatar_%s.svg" % who.lower(), avatars[who.lower()])
    # Three more avatars: the same drawings recolored (background, shirt, skin, hair).
    recolor = {
        "caio": ("rafa", {"#10263B": "#3A2866", "#6FB8D0": "#E0B24A", "#B07852": "#D3A582", "#1B120D": "#5A2418"}),
        "duda": ("marina", {"#4A1428": "#1E5448", "#E88FAF": "#7FD0B4", "#E8BE98": "#8F5C3E", "#B0402A": "#1B120D"}),
        "leo": ("bia", {"#12362F": "#6E2140", "#7FD0B4": "#E88FAF", "#8F5C3E": "#E8BE98", "#1B120D": "#B0402A"}),
    }
    for name, (base, mapping) in recolor.items():
        svg = avatars[base]
        for old, new in mapping.items():
            svg = svg.replace(old, new)
        write("avatar_%s.svg" % name, svg)

    # Fan card back, small coin, menu and rules icons.
    fan = [b for b in top_level(desktop, view_prefix="0 0 44 62") if "aria-hidden" in b[2]][0]
    write("carta_mini_verso.svg", standalone(desktop, *fan))
    coin = [b for b in top_level(desktop, view_prefix="0 0 24 24") if 'width="18"' in b[2] and "fill=" not in b[2]][0]
    write("moeda_icone.svg", standalone(desktop, *coin))
    gold = [b for b in top_level(desktop, view_prefix="0 0 24 24") if 'stroke="#E0B24A"' in b[2]]
    write("icone_menu.svg", standalone(desktop, *gold[0]))
    write("icone_regras.svg", standalone(desktop, *gold[1]))

    # Action medallion icons, in the order of the desktop action bar.
    medallions = [b for b in top_level(desktop, view_prefix="0 0 24 24") if 'width="28"' in b[2]]
    for name, block in zip(["renda", "ajuda", "golpe", "taxar", "assassinar", "extorquir", "trocar", "investigar"], medallions):
        write("medalhao_%s.svg" % name, standalone(desktop, *block))
    print("ok:", len(os.listdir(OUT)), "arquivos em", OUT)


if __name__ == "__main__":
    main()
