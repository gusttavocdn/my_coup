# -*- coding: utf-8 -*-
"""Gera o baralho de Coup em SVG — 5 cartas de personagem.

Cada carta = moldura/papel/faixa comuns + retrato e paleta próprios.
Os nomes são contornos extraídos de uma fonte script (sem <text>), para
renderizarem em qualquer engine, inclusive ThorVG/Godot.
"""
import json
import math
import os
import random

HERE = os.path.dirname(os.path.abspath(__file__))
OUTDIR = os.path.normpath(os.path.join(HERE, "..", "Claude-Code-Game-Studios", "assets", "arte"))

W, H = 346, 578
CX, CY, CW, CH, CR = 12, 12, 320, 553, 19

NAMES = json.load(open(os.path.join(HERE, "names.json"), encoding="utf-8"))


def poly(pts, fill, stroke="none", sw=0.8, op=1.0):
    d = "M" + " L".join("%.1f,%.1f" % (x, y) for x, y in pts) + " Z"
    s = '<path d="%s" fill="%s"' % (d, fill)
    if stroke != "none":
        s += ' stroke="%s" stroke-width="%s"' % (stroke, sw)
    if op != 1.0:
        s += ' opacity="%s"' % op
    return s + "/>"


def jit(x, y, a=6):
    return (x + random.uniform(-a, a), y + random.uniform(-a, a))


class Card(object):
    def __init__(self, cid, name, pal):
        self.cid = cid
        self.name = name
        self.pal = pal
        self.out = []
        self.a = self.out.append

    # -- helpers ---------------------------------------------------------
    def p(self, d, fill, op=None, stroke=None, sw=None, extra=""):
        s = '<path d="%s" fill="%s"' % (d, fill)
        if stroke:
            s += ' stroke="%s"' % stroke
            if sw:
                s += ' stroke-width="%s"' % sw
        if op is not None:
            s += ' opacity="%s"' % op
        if extra:
            s += " " + extra
        return s + "/>"

    def f(self, d, fill, op=None):
        return self.p(d, fill, op, extra='fill-rule="evenodd"')

    # -- shared shell ----------------------------------------------------
    def head_defs(self):
        P = self.pal
        g = []
        g.append('<linearGradient id="gPaper" x1="0" y1="0" x2="0.4" y2="1">'
                 '<stop offset="0" stop-color="#FFFFFF"/>'
                 '<stop offset="0.55" stop-color="#FCFBF9"/>'
                 '<stop offset="1" stop-color="#F7F5F2"/></linearGradient>')
        g.append('<linearGradient id="gWash" x1="0.1" y1="0.05" x2="0.95" y2="0.95">'
                 '<stop offset="0" stop-color="%s"/>'
                 '<stop offset="0.35" stop-color="%s"/>'
                 '<stop offset="0.7" stop-color="%s"/>'
                 '<stop offset="1" stop-color="%s"/></linearGradient>'
                 % (P["wash"][0], P["wash"][1], P["wash"][2], P["wash"][3]))
        g.append('<linearGradient id="gRobe" x1="0.1" y1="0" x2="0.8" y2="1">'
                 '<stop offset="0" stop-color="%s"/>'
                 '<stop offset="0.4" stop-color="%s"/>'
                 '<stop offset="0.75" stop-color="%s"/>'
                 '<stop offset="1" stop-color="%s"/></linearGradient>'
                 % (P["robe"][0], P["robe"][1], P["robe"][2], P["robe"][3]))
        g.append('<radialGradient id="gBloom" cx="0.5" cy="0.5" r="0.5">'
                 '<stop offset="0" stop-color="%s" stop-opacity="0.85"/>'
                 '<stop offset="1" stop-color="%s" stop-opacity="0"/></radialGradient>'
                 % (P["bloom"], P["bloom"]))
        g.append('<linearGradient id="gGarment" x1="0.05" y1="0.1" x2="0.9" y2="1">'
                 '<stop offset="0" stop-color="%s"/>'
                 '<stop offset="0.3" stop-color="%s"/>'
                 '<stop offset="0.65" stop-color="%s"/>'
                 '<stop offset="1" stop-color="%s"/></linearGradient>'
                 % (P["garment"][0], P["garment"][1], P["garment"][2], P["garment"][3]))
        g.append('<linearGradient id="gSkin" x1="0.15" y1="0" x2="0.9" y2="1">'
                 '<stop offset="0" stop-color="%s"/>'
                 '<stop offset="0.42" stop-color="%s"/>'
                 '<stop offset="0.78" stop-color="%s"/>'
                 '<stop offset="1" stop-color="%s"/></linearGradient>'
                 % (P["skin"][0], P["skin"][1], P["skin"][2], P["skin"][3]))
        g.append('<linearGradient id="gCap" x1="0" y1="0.2" x2="1" y2="0.9">'
                 '<stop offset="0" stop-color="%s"/>'
                 '<stop offset="0.30" stop-color="%s"/>'
                 '<stop offset="0.5" stop-color="%s"/>'
                 '<stop offset="0.66" stop-color="#2E3042"/>'
                 '<stop offset="1" stop-color="#232231"/></linearGradient>'
                 % (P["hat"][0], P["hat"][1], P["hat"][2]))
        g.append('<linearGradient id="gBand" x1="0" y1="0" x2="1" y2="0.25">'
                 '<stop offset="0" stop-color="#55D2BF"/>'
                 '<stop offset="0.18" stop-color="#79DEC9"/>'
                 '<stop offset="0.45" stop-color="#A9EDD6"/>'
                 '<stop offset="0.72" stop-color="#BEF0D9"/>'
                 '<stop offset="1" stop-color="#CDF1D3"/></linearGradient>')
        g.append('<linearGradient id="gScript" x1="0" y1="0" x2="1" y2="0.6">'
                 '<stop offset="0" stop-color="#8E1246"/>'
                 '<stop offset="0.35" stop-color="#C81A5F"/>'
                 '<stop offset="0.62" stop-color="#E23A7C"/>'
                 '<stop offset="1" stop-color="#9A1450"/></linearGradient>')
        g.append('<linearGradient id="gX" x1="0" y1="0" x2="1" y2="1">'
                 '<stop offset="0" stop-color="#FF2E74"/>'
                 '<stop offset="1" stop-color="#B00E48"/></linearGradient>')
        g.append('<filter id="soft" x="-40%" y="-40%" width="180%" height="180%">'
                 '<feGaussianBlur stdDeviation="10"/></filter>')
        g.append('<filter id="soft6" x="-40%" y="-40%" width="180%" height="180%">'
                 '<feGaussianBlur stdDeviation="5"/></filter>')
        g.append('<filter id="grain" x="0" y="0" width="100%" height="100%">'
                 '<feTurbulence type="fractalNoise" baseFrequency="0.85" numOctaves="4" '
                 'seed="9" result="n"/><feColorMatrix in="n" type="saturate" values="0"/>'
                 '<feComponentTransfer><feFuncA type="linear" slope="0.55"/>'
                 '</feComponentTransfer></filter>')
        g.append('<clipPath id="cardClip"><rect x="%d" y="%d" width="%d" height="%d" '
                 'rx="%d"/></clipPath>' % (CX, CY, CW, CH, CR))
        g.append('<clipPath id="garmentY"><rect x="12" y="288" width="322" '
                 'height="278"/></clipPath>')
        return g

    def folds(self, seed, cols, n=70, y0=296, y1=430, wmax=2.6):
        """Dobras de tecido sobre a roupa."""
        a = self.a
        a('<g clip-path="url(#garmentY)">')
        random.seed(seed)
        for i in range(n):
            x = random.uniform(16, 332)
            y = random.uniform(y0, y1)
            ln = random.uniform(50, 165)
            dx = random.uniform(-7, 5)
            a('<path d="M%.1f,%.1f q%.1f,%.1f %.1f,%.1f" stroke="%s" '
              'stroke-width="%.2f" fill="none" opacity="%.2f" stroke-linecap="round"/>'
              % (x, y, dx * 0.5, ln * 0.5, dx, ln, random.choice(cols),
                 random.uniform(0.4, wmax * 0.55), random.uniform(0.06, 0.20)))
        a('</g>')

    def shoulder_light(self, d_line, col="#FFFFFF", op=0.32, sw=2.4):
        self.a('<path d="%s" fill="none" stroke="%s" stroke-width="%s" opacity="%s" '
               'stroke-linecap="round"/>' % (d_line, col, sw, op))

    def under_chin(self, d_shadow):
        self.a('<path d="%s" fill="none" stroke="#0A0509" stroke-width="15" '
               'opacity="0.42" filter="url(#soft6)"/>' % d_shadow)

    def paper(self):
        a = self.a
        a('<rect x="%d" y="%d" width="%d" height="%d" fill="url(#gPaper)"/>'
          % (CX, CY, CW, CH))
        a('<g filter="url(#soft)">')
        a(poly([(12, 40), (40, 38), (44, 150), (34, 250), (12, 262)], "#EDECEA", op=0.55))
        a(poly([(10, 55), (72, 52), (104, 86), (108, 132), (86, 182),
                (52, 216), (12, 232)], "#F0EFED", op=0.60))
        a('</g>')
        a('<g fill="#E9E8E4">')
        a('<rect x="14.5" y="46.5" width="148" height="6.2" rx="1.6"/>')
        a('<rect x="14.5" y="56" width="152" height="3.2" rx="1.2" opacity="0.85"/>')
        a('</g>')
        a('<rect x="14.5" y="52.9" width="148" height="1" fill="#FCFCFB" opacity="0.7"/>')

    def wash(self, d_teal, d_robe, blooms):
        a = self.a
        a('<path d="%s" fill="%s" filter="url(#soft)" opacity="0.45"/>'
          % (d_teal, self.pal["wash"][1]))
        a('<path d="%s" fill="url(#gWash)"/>' % d_teal)
        a('<path d="%s" fill="%s" filter="url(#soft)" opacity="0.55"/>'
          % (d_robe, self.pal["robe"][0]))
        a('<path d="%s" fill="url(#gRobe)"/>' % d_robe)
        for (cx, cy, rx, ry, op) in blooms:
            a('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="url(#gBloom)" opacity="%s"/>'
              % (cx, cy, rx, ry, op))

    def striations(self, clip_d, seed, n=170, y0=250, y1=430):
        a = self.a
        a('<g clip-path="url(#robeClip)">')
        random.seed(seed)
        cols = self.pal["stri"]
        for i in range(n):
            x = random.uniform(8, 336)
            yy = random.uniform(y0, y1)
            ln = random.uniform(40, 150)
            c = random.choice(cols)
            a('<path d="M%.1f,%.1f L%.1f,%.1f" stroke="%s" stroke-width="%.2f" '
              'opacity="%.2f"/>' % (x, yy, x + random.uniform(-1.6, 1.6), yy + ln,
                                    c, random.uniform(0.35, 1.2),
                                    random.uniform(0.08, 0.28)))
        a('</g>')

    def band(self, icons):
        a = self.a
        a('<path d="M31,470 C34,460 46,454 62,452 C102,449 150,450 200,450 '
          'C250,450 292,451 311,454 C321,456 323,464 321,477 C319,491 321,510 '
          '317,520 C311,530 291,533 261,533 C211,534 150,534 100,533 '
          'C60,532 36,530 32,520 C29,508 29,486 31,470 Z" fill="url(#gBand)"/>')
        a('<g opacity="0.45">')
        random.seed(41)
        for i in range(46):
            if random.random() < 0.5:
                x = random.uniform(34, 318)
                y = random.choice([452, 532]) + random.uniform(-3.5, 3.5)
            else:
                x = random.choice([32, 320]) + random.uniform(-3.5, 3.5)
                y = random.uniform(456, 530)
            r = random.uniform(2.2, 6.5)
            a('<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="#8FE6D2" '
              'opacity="%.2f"/>' % (x, y, r, r * 0.65, random.uniform(0.25, 0.6)))
        a('</g>')
        a('<path d="M44,466 C90,460 160,460 216,461 C262,462 296,464 310,468 '
          'L308,478 C270,472 200,470 140,470 C90,470 56,473 44,478 Z" '
          'fill="#C9F4DE" opacity="0.4"/>')
        a(ORN_LEFT)
        a(ORN_RIGHT)
        for frag in icons:
            a(frag)

    def script(self):
        n = NAMES[self.name]
        scale = min(0.44, 240.0 / n["w"])
        cy = n["y"] + n["h"] / 2.0
        self.a('<g transform="translate(298,48) rotate(90) scale(%.4f) '
               'translate(%.1f,%.1f)">' % (scale, -n["x"], -cy))
        self.a('<path d="%s" fill="url(#gScript)"/>' % n["d"])
        self.a('</g>')

    def render(self):
        P = self.pal
        head = ['<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" '
                'viewBox="0 0 %d %d" role="img">' % (W, H, W, H)]
        head.append('<title>%s — carta de Coup</title>' % self.name)
        head.append('<desc>%s</desc>' % P["desc"])
        head.append("<defs>")
        head.extend(self.head_defs())
        head.append(self.pal["clips"])
        head.append("</defs>")
        head.append('<g clip-path="url(#cardClip)">')
        body = "\n".join(self.out)
        tail = "</g>"
        tail += ('<rect x="%d" y="%d" width="%d" height="%d" rx="%d" fill="none" '
                 'stroke="#CBCBCB" stroke-width="1.3"/>' % (CX, CY, CW, CH, CR))
        tail += ('<rect x="%d" y="%d" width="%d" height="%d" rx="%d" fill="none" '
                 'stroke="#FFFFFF" stroke-width="1" opacity="0.65"/>'
                 % (CX + 1.2, CY + 1.2, CW - 2.4, CH - 2.4, CR - 1.2))
        tail += "</svg>"
        return "\n".join(head) + "\n" + body + "\n" + tail


# --------------------------------------------------------------------------
# shared band ornaments / marks (ícones a tinta escura sobre a faixa)
ICON = "#1C463A"

ORT = ('<path d="M71,462.5 C64,462 58,462 53,463.5 C50,464.5 49,467 50.5,468.8 '
       'C52,470.5 55,470.3 55.6,468.2 C56.1,466.4 54.4,465.4 52.8,466.4" '
       'fill="none" stroke="#1C463A" stroke-width="2.4" stroke-linecap="round"/>'
       '<path d="M41.5,475 C40,481 40,487 41.5,492" fill="none" stroke="#1C463A" '
       'stroke-width="2.6" stroke-linecap="round"/>'
       '<path d="M41.5,475 C44,472 48,471 50,473.5 C52,476 50,479 47,478.4" '
       'fill="none" stroke="#1C463A" stroke-width="2.4" stroke-linecap="round"/>'
       '<path d="M52,473 L59,478.5 L50,479.5 Z" fill="#1C463A"/>'
       '<circle cx="46.2" cy="466.4" r="1.9" fill="#1C463A"/>'
       '<circle cx="49.6" cy="462.6" r="1.3" fill="#1C463A"/>')
ORN_LEFT = '<g>' + ORT + '</g>'
ORN_RIGHT = '<g transform="translate(346,0) scale(-1,1)">' + ORT + '</g>'

AMP = ('<path d="M170,475 C161,475 156,482 161,487 C166,492 175,489 176,481 '
       'C177,473 168,469 162,475 M161,488 C156,495 159,502 167,502 '
       'C174,502 177,497 177,492" fill="none" stroke="#255043" stroke-width="3" '
       'stroke-linecap="round"/>')

HAND = ('<path d="M84,491 C90,485 99,486 103,494 C106,502 106,512 102,518 '
        'C97,525 88,523 85,515 C82,507 82,498 84,491 Z" fill="#1C463A"/>'
        '<rect x="99" y="497" width="25" height="7.8" rx="3.9" '
        'transform="rotate(12 99 500.9)" fill="#1C463A"/>'
        '<rect x="101" y="505" width="26" height="7.8" rx="3.9" '
        'transform="rotate(12 101 508.9)" fill="#1C463A"/>'
        '<rect x="103" y="513" width="24" height="7.8" rx="3.9" '
        'transform="rotate(12 103 516.9)" fill="#1C463A"/>'
        '<path d="M100,498 L119,504 M102,506 L121,512 M104,514 L119,519" '
        'stroke="#8FE3C9" stroke-width="1.3" stroke-linecap="round" opacity="0.45"/>')


def coin1(cx, cy, r=8.0):
    s = '<circle cx="%s" cy="%s" r="%s" fill="#1C463A"/>' % (cx, cy, r)
    s += ('<g stroke="#8FE0C6" stroke-width="1.5" stroke-linecap="round" fill="none">'
          '<path d="M%.1f,%.1f L%.1f,%.1f"/>'
          '<path d="M%.1f,%.1f L%.1f,%.1f"/>'
          '<path d="M%.1f,%.1f L%.1f,%.1f"/></g>'
          % (cx - 1.4, cy + r * 0.44, cx + 0.8, cy - r * 0.44,
             cx - r * 0.39, cy - r * 0.17, cx + 0.8, cy - r * 0.44,
             cx - r * 0.37, cy + r * 0.46, cx + r * 0.37, cy + r * 0.46))
    return s


def xmark(cx=234.5, cy=475.5, s=11, w=7.4):
    return ('<g stroke="url(#gX)" stroke-width="%s" stroke-linecap="round">'
            '<path d="M%.1f,%.1f L%.1f,%.1f"/><path d="M%.1f,%.1f L%.1f,%.1f"/></g>'
            % (w, cx - s, cy - s, cx + s, cy + s, cx + s, cy - s, cx - s, cy + s))


def dagger(cx, cy, sc=1.0, col="#1C463A"):
    """Punhal apontado para baixo-direita."""
    s = '<g transform="translate(%s,%s) scale(%s)">' % (cx, cy, sc)
    s += ('<path d="M0,-17 C4,-10 5,-2 4,7 L-4,7 C-5,-2 -4,-10 0,-17 Z" fill="%s"/>' % col)
    s += ('<path d="M-3,7 L3,7 L2.2,11 L-2.2,11 Z" fill="%s"/>' % col)
    s += ('<rect x="-10" y="10.4" width="20" height="3.4" rx="1.7" fill="%s"/>' % col)
    s += ('<rect x="-2" y="13.6" width="4" height="10" rx="2" fill="%s"/>' % col)
    s += ('<circle cx="0" cy="25" r="3.1" fill="%s"/>' % col)
    s += ('<path d="M-1.4,-12 L-1.8,5" stroke="#8FE3C9" stroke-width="1.1" '
          'opacity="0.5" stroke-linecap="round"/>')
    s += "</g>"
    return s


def crown(cx, cy, sc=1.0, col="#1C463A"):
    s = '<g transform="translate(%s,%s) scale(%s)">' % (cx, cy, sc)
    s += ('<path d="M-15,9 L-15,-8 L-7.5,-1 L0,-12 L7.5,-1 L15,-8 L15,9 Z" fill="%s"/>' % col)
    s += '<rect x="-16.5" y="10.4" width="33" height="4.6" rx="1.6" fill="%s"/>' % col
    s += '<circle cx="-15" cy="-9.5" r="2.1" fill="%s"/>' % col
    s += '<circle cx="0" cy="-13.5" r="2.3" fill="%s"/>' % col
    s += '<circle cx="15" cy="-9.5" r="2.1" fill="%s"/>' % col
    s += ('<path d="M-9,4 L9,4 M-9,0 L9,0" stroke="#8FE3C9" stroke-width="1" '
          'opacity="0.35" stroke-linecap="round"/>')
    s += "</g>"
    return s


def cards2(cx, cy, sc=1.0, col="#1C463A"):
    """Duas cartas a trocar."""
    s = '<g transform="translate(%s,%s) scale(%s)">' % (cx, cy, sc)
    s += ('<rect x="-16" y="-14" width="19" height="26" rx="2.6" fill="%s" '
          'transform="rotate(-14 -6.5 -1)"/>' % col)
    s += ('<rect x="-3" y="-11" width="19" height="26" rx="2.6" fill="#2C5C4A" '
          'transform="rotate(12 6.5 2)"/>')
    s += ('<path d="M-2,-6 L10,-6 M-2,-1 L10,-1 M-2,4 L6,4" stroke="#9FE8CE" '
          'stroke-width="1.5" stroke-linecap="round" opacity="0.8" '
          'transform="rotate(12 6.5 2)"/>')
    s += ('<path d="M12,-20 C19,-20 22,-15 20,-11" fill="none" stroke="%s" '
          'stroke-width="2.2" stroke-linecap="round"/>' % col)
    s += ('<path d="M20,-11 L21.5,-15.6 L16.8,-14.6 Z" fill="%s"/>' % col)
    s += "</g>"
    return s


def hand_blocked(cx, cy, sc=1.0):
    """Mão que rouba, riscada."""
    s = '<g transform="translate(%s,%s) scale(%s)">' % (cx, cy, sc)
    s += ('<path d="M-14,2 C-8,-4 1,-3 5,5 C8,13 8,23 4,29 C-1,36 -10,34 -13,26 '
          'C-16,18 -16,9 -14,2 Z" fill="#1C463A"/>')
    s += ('<rect x="0" y="8" width="20" height="7.4" rx="3.7" fill="#1C463A"/>'
          '<rect x="2" y="16" width="21" height="7.4" rx="3.7" fill="#1C463A"/>')
    s += coin1(22, 2, 6.4)
    s += "</g>"
    return s


def coin_stack(cx, cy, n=3, col="#1C463A"):
    s = ""
    for i in range(n):
        s += ('<circle cx="%s" cy="%s" r="8.4" fill="%s"/>'
              % (cx, cy - i * 3.2, col))
    return s


# --------------------------------------------------------------------------
# Duque (retrato já aprovado)
DUQUE_FACE = ("M100,202 C100,180 112,164 134,157 C164,148 200,154 216,166 "
              "C230,177 238,192 240,208 C242,226 234,246 222,260 "
              "C208,276 184,288 158,288 C134,288 114,276 106,258 "
              "C98,240 100,216 100,202 Z")
DUQUE_BEARD = ("M98,250 C96,274 104,300 122,314 C138,326 160,328 176,318 "
               "C196,306 210,282 214,256 C217,240 214,232 208,228 "
               "L194,240 C180,252 158,256 140,253 C124,250 112,244 108,236 "
               "C104,232 98,240 98,250 Z")
DUQUE_COLLAR = ("M34,286 L40,256 L52,228 L74,196 L104,182 L140,178 L178,182 "
                "L212,192 L242,206 L266,222 L284,244 L292,268 L293,294 "
                "L285,320 L268,342 L244,358 L214,368 L182,372 L150,366 "
                "L122,356 L96,340 L66,318 Z")
DUQUE_COLLAR_IN = ("M58,290 L64,264 L76,238 L96,212 L124,198 L154,194 L186,198 "
                   "L214,208 L238,222 L256,240 L268,258 L270,280 L264,302 "
                   "L250,318 L230,332 L206,340 L180,344 L154,338 L130,330 "
                   "L108,316 L84,302 Z")


def build_duque():
    pal = dict(
        desc="Busto de homem idoso, barba branca longa, barrete académico escuro e "
             "gola rufo carmim sobre aguada azul-petróleo.",
        wash=["#04293A", "#0A4F66", "#0E88B0", "#22A6C8"],
        robe=["#3E3342", "#2E2632", "#251D28", "#1B1521"],
        bloom="#40315A",
        garment=["#F32C8E", "#D2146E", "#5E0934", "#26040F"],
        skin=["#E8A85F", "#D98B54", "#C2603F", "#9E4238"],
        hat=["#49BFB8", "#2FA0A6", "#2B7A8C"],
        stri=["#5A4F64", "#6B5F74", "#3F3547", "#7C7086", "#2E2536"],
        clips='<clipPath id="robeClip"><path d="M12,438 C27,428 45,414 61,397 '
              'C79,378 97,360 119,348 C139,337 161,332 183,332 C207,332 233,328 '
              '253,317 C276,305 297,288 313,268 C323,256 329,248 333,242 '
              'L333,566 L12,566 Z"/></clipPath>'
              '<clipPath id="faceClip"><path d="%s"/></clipPath>'
              '<clipPath id="beardClip"><path d="%s"/></clipPath>'
              '<clipPath id="collarClip"><path d="%s"/></clipPath>'
              '<clipPath id="quiltClip"><path d="%s"/></clipPath>'
              % (DUQUE_FACE, DUQUE_BEARD, DUQUE_COLLAR, DUQUE_COLLAR_IN),
    )
    c = Card("duque", "Duque", pal)
    a = c.a
    c.paper()
    c.wash("M12,318 C36,320 58,326 80,338 C108,352 132,376 145,404 "
           "C153,422 156,440 156,458 L12,458 Z",
           "M12,438 C27,428 45,414 61,397 C79,378 97,360 119,348 C139,337 161,332 "
           "183,332 C207,332 233,328 253,317 C276,305 297,288 313,268 "
           "C323,256 329,248 333,242 L333,566 L12,566 Z",
           [(200, 400, 92, 80, 0.85), (272, 352, 60, 48, 0.7)])
    c.striations(None, 11)
    # gola
    a('<path d="%s" fill="url(#gGarment)"/>' % DUQUE_COLLAR)
    a('<path d="%s" fill="#3A1528"/>' % DUQUE_COLLAR_IN)
    a('<g clip-path="url(#quiltClip)">')
    random.seed(7)
    ccx, ccy, RX, RY = 170.0, 262.0, 100.0, 78.0
    PAL = ["#4E2140", "#3A1628", "#5E2946", "#2C101E", "#6E2C4C",
           "#41192D", "#331524", "#7E3358", "#4A1D33", "#8E3A5E"]
    for j in range(4):
        ra = 0.30 + 0.75 * j / 4
        rb = 0.30 + 0.75 * (j + 1) / 4
        off = 0.10 if j % 2 else 0.0
        for i in range(10):
            a0 = 2 * math.pi * i / 10 + off
            a1 = 2 * math.pi * (i + 1) / 10 + off
            pts = [jit(ccx + RX * ra * math.cos(a0), ccy + RY * ra * math.sin(a0), 3.2),
                   jit(ccx + RX * ra * math.cos(a1), ccy + RY * ra * math.sin(a1), 3.2),
                   jit(ccx + RX * rb * math.cos(a1), ccy + RY * rb * math.sin(a1), 3.2),
                   jit(ccx + RX * rb * math.cos(a0), ccy + RY * rb * math.sin(a0), 3.2)]
            a(poly(pts, random.choice(PAL), stroke="#241019",
                   sw=round(random.uniform(1.0, 1.7), 2), op=round(random.uniform(0.6, 0.95), 2)))
    a('</g>')
    a('<g clip-path="url(#collarClip)">')
    a(poly([(196, 178), (300, 214), (302, 300), (270, 356), (214, 372), (176, 300),
            (182, 214)], "#2E1020", op=0.86))
    a(poly([(150, 336), (300, 320), (300, 384), (150, 384)], "#2A0C1A", op=0.62))
    a('</g>')
    a('<path d="%s" fill="none" stroke="#2B0C1B" stroke-width="15" opacity="0.55" '
      'filter="url(#soft6)"/>' % DUQUE_COLLAR_IN)
    a('<path d="M112,268 C140,300 196,300 226,266" fill="none" stroke="#12040C" '
      'stroke-width="16" opacity="0.4" filter="url(#soft6)"/>')
    # coroa do barrete
    a('<path d="M108,164 C132,152 194,148 230,160 C236,172 235,184 231,192 '
      'L110,196 C105,184 104,172 108,164 Z" fill="#262536"/>')
    # cabeça
    a('<path d="M114,246 C114,274 122,300 134,316 L204,316 C218,298 226,274 228,244 Z" '
      'fill="#7A2E3C" opacity="0.4"/>')
    a('<path d="%s" fill="url(#gSkin)"/>' % DUQUE_FACE)
    a('<g clip-path="url(#faceClip)">')
    a('<path d="M100,204 C106,190 118,184 132,189 C146,195 153,213 151,232 '
      'C149,251 136,260 122,258 C108,256 97,232 100,204 Z" fill="#F0DCBE"/>')
    a(poly([(100, 190), (108, 180), (122, 177), (126, 188), (112, 198), (100, 198)],
           "#E9A34A", op=0.95))
    a('<path d="M144,188 C168,178 196,178 214,187 C232,196 244,213 246,231 '
      'C244,250 230,262 212,262 C194,262 180,250 174,234 C168,216 156,197 144,188 Z" '
      'fill="#A8302C" opacity="0.92"/>')
    a('<path d="M204,195 C224,201 238,215 242,232 C238,247 222,253 208,249 '
      'C216,231 214,209 204,195 Z" fill="#6E2230" opacity="0.88"/>')
    a('<path d="M104,186 C122,171 160,164 196,168 C208,170 214,176 210,184 '
      'C186,178 150,181 118,196 Z" fill="#B8352A" opacity="0.94"/>')
    a(poly([(102, 176), (118, 166), (134, 165), (130, 178), (110, 186), (100, 184)],
           "#F0A63C", op=0.75))
    a('<path d="M102,199 C118,190 142,187 156,191 C148,204 124,207 102,199 Z" '
      'fill="#7A2433" opacity="0.3"/>')
    a('<path d="M168,195 C182,189 204,188 220,194 C206,204 184,203 168,195 Z" '
      'fill="#7A2433" opacity="0.3"/>')
    a('<path d="M148,180 C158,184 164,192 166,202 C160,204 152,200 148,192 Z" '
      'fill="#F0C98F" opacity="0.9"/>')
    a('<path d="M156,214 C166,224 172,238 174,252 C166,260 156,258 150,250 '
      'C146,238 148,224 156,214 Z" fill="#8C3040" opacity="0.45"/>')
    random.seed(37)
    for _ in range(130):
        x = random.uniform(99, 242)
        y = random.uniform(158, 268)
        ln = random.uniform(5, 20)
        ang = math.radians(random.uniform(20, 70))
        a('<path d="M%.1f,%.1f l%.1f,%.1f" stroke="%s" stroke-width="%.2f" opacity="%.2f" '
          'stroke-linecap="round"/>'
          % (x, y, math.cos(ang) * ln, math.sin(ang) * ln,
             random.choice(["#6B2530", "#8E3A38", "#3A1620", "#C98A5E"]),
             random.uniform(0.3, 0.9), random.uniform(0.08, 0.3)))
    a('</g>')
    # barba
    a('<path d="%s" fill="#E7E1D3"/>' % DUQUE_BEARD)
    a('<g clip-path="url(#beardClip)">')
    a('<path d="M96,240 C126,278 186,286 240,248 L244,330 L96,330 Z" '
      'fill="#C4BAA6" opacity="0.7"/>')
    a('<path d="M106,242 C134,276 190,284 234,252 L236,268 C192,298 132,290 104,258 Z" '
      'fill="#F5F0E4" opacity="0.5"/>')
    random.seed(23)
    for i in range(620):
        x = random.uniform(94, 228)
        y = random.uniform(240, 336)
        ln = random.uniform(8, 34)
        ang = random.uniform(70, 110)
        if random.random() < 0.18:
            ang = random.uniform(40, 140)
        dx = math.cos(math.radians(ang)) * ln * random.choice([-0.35, 0.35])
        dy = math.sin(math.radians(ang)) * ln
        a('<path d="M%.1f,%.1f q%.1f,%.1f %.1f,%.1f" stroke="%s" stroke-width="%.2f" '
          'opacity="%.2f" fill="none" stroke-linecap="round"/>'
          % (x, y, dx, dy * 0.5, dx * 0.7, dy,
             random.choice(["#8C8370", "#6F6757", "#B0A794", "#544C3E", "#FFFFFF",
                            "#FFFFFF", "#A9A08C"]),
             random.uniform(0.4, 1.25), random.uniform(0.3, 0.85)))
    a('</g>')
    a('<path d="%s" fill="none" stroke="#2E1E26" stroke-width="1.2" opacity="0.55"/>'
      % DUQUE_BEARD)
    # bigode
    a('<path d="M108,242 C126,229 152,225 170,231 C184,236 194,235 200,229 '
      'C206,241 198,258 182,262 C162,267 134,262 116,252 Z" fill="#FBF7ED"/>')
    a('<path d="M118,250 C136,237 156,233 172,237" stroke="#C2B6A2" stroke-width="1.2" '
      'fill="none" opacity="0.7"/>')
    # sobrancelhas
    a('<path d="M100,199 C120,187 142,182 158,184" stroke="#2C1018" stroke-width="5.6" '
      'fill="none" stroke-linecap="round" opacity="0.95"/>')
    a('<path d="M170,184 C188,183 204,187 218,195" stroke="#2C1018" stroke-width="5.2" '
      'fill="none" stroke-linecap="round" opacity="0.95"/>')
    # olhos
    a('<path d="M104,209 C116,199 134,197 144,205 C135,217 116,218 104,209 Z" '
      'fill="#6E1F2C"/>')
    a('<path d="M104,209 C116,201 134,199 144,205" stroke="#26080E" stroke-width="1.9" '
      'fill="none" stroke-linecap="round"/>')
    a('<path d="M170,200 C182,193 200,193 208,199 C199,209 182,210 170,200 Z" '
      'fill="#6E1F2C"/>')
    a('<path d="M170,200 C182,194 200,194 208,199" stroke="#26080E" stroke-width="1.9" '
      'fill="none" stroke-linecap="round"/>')
    # nariz
    a('<path d="M146,181 C156,196 152,214 140,228 C132,237 121,233 120,222 '
      'C119,207 132,189 146,181 Z" fill="#FBE7C0"/>')
    a('<path d="M121,223 C125,232 135,238 146,236 C147,242 138,245 128,243 '
      'C120,241 118,231 121,223 Z" fill="#8E3240" opacity="0.85"/>')
    a('<path d="M127,232 C131,229 136,231 135,236 C133,240 127,238 127,232 Z" '
      'fill="#3A121C" opacity="0.85"/>')
    a('<path d="M121,221 C125,233 137,239 148,237" stroke="#3A121C" stroke-width="1.5" '
      'fill="none" stroke-linecap="round" opacity="0.75"/>')
    # orelha e caracóis
    a('<path d="M218,212 C231,210 239,221 237,233 C235,245 224,249 217,245 Z" '
      'fill="#8E3A3E"/>')
    a('<g stroke="#B0A498" stroke-width="1.9" fill="none" opacity="0.95" '
      'stroke-linecap="round">')
    for (cx2, cy2, r2) in [(212, 176, 7), (229, 188, 6), (239, 204, 5.5),
                           (235, 221, 5), (222, 232, 4.5), (200, 166, 6)]:
        a('<path d="M%.1f,%.1f C%.1f,%.1f %.1f,%.1f %.1f,%.1f C%.1f,%.1f %.1f,%.1f '
          '%.1f,%.1f"/>' % (cx2 - r2, cy2, cx2 - r2, cy2 - r2 * 1.4, cx2 + r2,
                            cy2 - r2 * 1.4, cx2 + r2, cy2, cx2 + r2, cy2 + r2 * 1.3,
                            cx2 - r2, cy2 + r2 * 1.3, cx2 - r2, cy2))
    a('</g>')
    a('<path d="%s" fill="none" stroke="#2A1620" stroke-width="1.2" opacity="0.45"/>'
      % DUQUE_FACE)
    # prancha do barrete
    a('<path d="M72,128 L168,98 L262,146 L150,170 Z" fill="url(#gCap)"/>')
    a('<path d="M198,119 L262,146 L150,170 L188,138 Z" fill="#232231" opacity="0.9"/>')
    a('<path d="M72,128 L168,98 L190,112 L104,142 Z" fill="#57CAC1" opacity="0.26"/>')
    a('<path d="M72,128 L150,170 L262,146" stroke="#1E1C28" stroke-width="1.4" '
      'fill="none" opacity="0.45"/>')
    a('<path d="M72,128 L168,98" stroke="#9AEAE0" stroke-width="1.1" fill="none" '
      'opacity="0.45"/>')
    a('<g filter="url(#soft6)">')
    a(poly([(168, 106), (202, 100), (220, 112), (202, 126), (176, 124)],
           "#E8422A", op=0.9))
    a('</g>')
    c.script()
    c.band([HAND, coin1(122, 470, 8.2), coin1(132.5, 485, 7.6), coin1(126, 492.5, 7.6),
            AMP, coin1(218, 492, 13), coin1(242, 503, 13), xmark()])
    a('<g opacity="0.15" style="mix-blend-mode:multiply">')
    a('<rect x="12" y="12" width="320" height="553" filter="url(#grain)"/>')
    a('</g>')
    return c


# --------------------------------------------------------------------------
def build_assassino():
    pal = dict(
        desc="Figura encapuzada, rosto na sombra com faixa de pano sobre a boca, "
             "sobre aguada carmim e petróleo.",
        wash=["#2A0A14", "#5E0E22", "#8E1430", "#B02A38"],
        robe=["#2E1420", "#1E0C14", "#170A10", "#0E0509"],
        bloom="#6A1030",
        garment=["#C0143C", "#8E0E2C", "#5A0820", "#2A0410"],
        skin=["#B0855C", "#96693F", "#74472E", "#3E2318"],
        hat=["#C0143C", "#8E0E2C", "#5A0820"],
        stri=["#4A2A38", "#603A46", "#2E1A22", "#7A4A54", "#221018"],
        clips='<clipPath id="robeClip"><path d="M12,352 C52,348 96,340 138,338 '
              'C178,336 214,326 244,308 C274,290 302,270 333,240 L333,566 L12,566 Z"/>'
              '</clipPath>'
              '<clipPath id="hoodClip"><path d="M86,306 C78,240 84,186 106,154 '
              'C128,120 174,110 208,120 C242,130 262,158 266,198 C270,238 262,286 '
              '252,316 L226,306 C240,264 242,224 236,196 C228,162 204,142 176,142 '
              'C148,142 126,162 118,196 C110,230 112,272 120,306 Z"/></clipPath>'
              '<clipPath id="faceClip"><path d="M120,200 C120,172 136,152 160,148 '
              'C186,144 210,156 220,178 C230,200 230,228 222,252 C214,274 196,288 '
              '174,288 C150,288 132,270 124,248 C118,230 118,214 120,200 Z"/>'
              '</clipPath>',
    )
    c = Card("assassino", "Assassino", pal)
    a = c.a
    c.paper()
    c.wash("M12,316 C36,318 60,326 82,340 C110,356 134,380 148,408 "
           "C156,426 158,444 158,460 L12,460 Z",
           "M12,352 C52,348 96,340 138,338 C178,336 214,326 244,308 "
           "C274,290 302,270 333,240 L333,566 L12,566 Z",
           [(210, 396, 96, 82, 0.8), (286, 344, 58, 46, 0.6)])
    c.striations(None, 13)
    # ombros do manto
    a('<path d="M72,302 C112,290 170,294 214,306 C252,314 286,298 312,274 '
      'C322,264 329,248 333,234 L333,566 L12,566 L12,318 C34,312 54,306 72,302 Z" '
      'fill="#1A0E16"/>')
    a('<path d="M72,302 C112,290 170,294 214,306 C252,314 286,298 312,274" '
      'fill="none" stroke="#C0143C" stroke-width="3" opacity="0.55"/>')
    c.folds(131, ["#4A1226", "#2A0812", "#8E1430", "#E8457A"], 90, 300, 470, 3.0)
    c.under_chin("M120,296 C150,314 200,314 228,292")
    # capuz
    a('<path d="M86,306 C78,240 84,186 106,154 C128,120 174,110 208,120 '
      'C238,128 262,158 266,198 C270,238 262,286 252,316 L226,306 '
      'C240,264 242,224 236,196 C228,162 204,142 176,142 C148,142 126,162 '
      '118,196 C110,230 112,272 120,306 Z" fill="#3B0814"/>')
    a('<path d="M120,300 C110,262 108,222 116,192 C124,160 148,142 176,142 '
      'C204,142 228,160 236,194 C242,224 240,264 226,304" fill="none" '
      'stroke="#C0143C" stroke-width="3.4" opacity="0.75"/>')
    a('<path d="M118,296 C110,258 110,220 118,192 C126,162 150,146 176,146" '
      'fill="none" stroke="#F0708E" stroke-width="1.6" opacity="0.45"/>')
    a('<g clip-path="url(#hoodClip)">')
    a(poly([(80, 150), (270, 150), (270, 320), (80, 320)], "#2A0A16", op=0.35))
    random.seed(29)
    for i in range(70):
        x = random.uniform(84, 268)
        y = random.uniform(120, 320)
        a('<path d="M%.1f,%.1f l%.1f,%.1f" stroke="%s" stroke-width="%.2f" '
          'opacity="%.2f" stroke-linecap="round"/>'
          % (x, y, random.uniform(-4, 4), random.uniform(10, 26),
             random.choice(["#E8457A", "#5A0820", "#3A0412"]),
             random.uniform(0.6, 2.0), random.uniform(0.1, 0.35)))
    a('</g>')
    # rosto na sombra
    a('<path d="M120,200 C120,172 136,152 160,148 C186,144 210,156 220,178 '
      'C230,200 230,228 222,252 C214,274 196,288 174,288 C150,288 132,270 '
      '124,248 C118,230 118,214 120,200 Z" fill="url(#gSkin)"/>')
    a('<g clip-path="url(#faceClip)">')
    a('<path d="M112,150 L236,150 L236,222 C210,212 176,210 150,216 C134,220 120,220 112,214 Z" '
      'fill="#1A0810" opacity="0.78"/>')
    a('<path d="M120,248 C150,236 200,236 226,250 L228,272 C200,286 148,286 118,268 Z" '
      'fill="#1A0810" opacity="0.35"/>')
    a('<path d="M124,196 C136,184 168,180 196,186 C214,190 224,196 228,202 '
      'C216,214 186,214 160,210 C144,208 132,204 124,196 Z" fill="#3A1620" opacity="0.5"/>')
    a('<path d="M128,206 C144,200 176,200 198,204 C186,214 156,216 134,212 Z" '
      'fill="#E8C79C" opacity="0.55"/>')
    a('<path d="M132,236 C150,246 182,248 204,240 L200,262 C180,272 152,268 136,256 Z" '
      'fill="#3A1620" opacity="0.35"/>')
    a('</g>')
    # olhos
    a('<path d="M126,209 C138,201 156,200 166,206 C157,218 138,219 126,209 Z" '
      'fill="#1A0810"/>')
    a('<path d="M126,209 C138,202 156,201 166,206" stroke="#F0D8A8" stroke-width="1.6" '
      'fill="none" stroke-linecap="round" opacity="0.9"/>')
    a('<path d="M178,205 C190,199 208,199 216,204 C207,214 190,215 178,205 Z" '
      'fill="#1A0810"/>')
    a('<path d="M178,205 C190,200 208,200 216,204" stroke="#F0D8A8" stroke-width="1.6" '
      'fill="none" stroke-linecap="round" opacity="0.9"/>')
    a('<path d="M118,196 C126,188 142,184 156,186" stroke="#1A0810" stroke-width="4.6" '
      'fill="none" stroke-linecap="round" opacity="0.9"/>')
    a('<path d="M180,186 C194,184 208,188 216,194" stroke="#1A0810" stroke-width="4.6" '
      'fill="none" stroke-linecap="round" opacity="0.9"/>')
    # nariz
    a('<path d="M162,196 C172,208 168,224 156,234 C148,241 139,236 138,228 '
      'C137,214 150,200 162,196 Z" fill="#D8AA7C" opacity="0.9"/>')
    a('<path d="M139,229 C143,237 152,242 162,240 C163,246 154,249 145,246 '
      'C138,244 136,234 139,229 Z" fill="#4A2030" opacity="0.8"/>')
    # faixa sobre a boca
    a('<path d="M118,244 C138,238 168,236 194,240 C212,243 224,240 230,236 '
      'L232,258 C222,266 200,268 178,266 C152,264 130,262 118,256 Z" '
      'fill="#2A0A16"/>')
    a('<path d="M122,248 C144,244 176,244 204,248" stroke="#7A1230" stroke-width="2.2" '
      'fill="none" opacity="0.8"/>')
    a('<path d="M126,258 C150,264 186,264 210,258" stroke="#7A1230" stroke-width="1.6" '
      'fill="none" opacity="0.6"/>')
    a('<path d="M118,244 C138,238 168,236 194,240" stroke="#12030A" stroke-width="1.4" '
      'fill="none" opacity="0.8"/>')
    c.script()
    c.band([dagger(126, 486, 1.0), coin1(104, 496, 7.4), coin1(112, 504, 7.0),
            coin1(120, 512, 6.6), AMP, coin1(214, 494, 8.6), coin1(226, 506, 8.2),
            coin1(236, 516, 7.8), xmark(252, 470, 9, 6.4)])
    a('<g opacity="0.15" style="mix-blend-mode:multiply">')
    a('<rect x="12" y="12" width="320" height="553" filter="url(#grain)"/>')
    a('</g>')
    return c


def build_capitao():
    pal = dict(
        desc="Capitão de bicorne azul-marinho com galões dourados, rosto curtido e "
             "bigode, sobre aguada azul-aço.",
        wash=["#08182E", "#12314F", "#1E4E78", "#2A6E96"],
        robe=["#22304A", "#1A2438", "#141C2C", "#0C1220"],
        bloom="#1E3A60",
        garment=["#3A5A8E", "#22406A", "#152A48", "#0A1728"],
        skin=["#D8A878", "#C08A5C", "#9E6644", "#6E422C"],
        hat=["#3A5A8E", "#22406A", "#152A48"],
        stri=["#3A4A66", "#4A5E7E", "#2A3446", "#5A7092", "#1C2434"],
        clips='<clipPath id="robeClip"><path d="M12,350 C50,346 90,340 130,340 '
              'C170,340 210,330 246,310 C276,293 302,272 333,240 L333,566 L12,566 Z"/>'
              '</clipPath>'
              '<clipPath id="faceClip"><path d="M106,198 C106,176 120,158 144,152 '
              'C172,146 198,154 212,172 C226,190 230,216 224,240 C218,264 196,278 '
              '170,278 C144,278 122,262 112,238 C106,222 106,210 106,198 Z"/>'
              '</clipPath>',
    )
    c = Card("capitao", "Capitão", pal)
    a = c.a
    c.paper()
    c.wash("M12,318 C36,320 58,326 80,338 C108,352 132,376 145,404 "
           "C153,422 156,440 156,458 L12,458 Z",
           "M12,350 C50,346 90,340 130,340 C170,340 210,330 246,310 "
           "C276,293 302,272 333,240 L333,566 L12,566 Z",
           [(196, 402, 92, 80, 0.8), (284, 336, 56, 44, 0.55)])
    c.striations(None, 17)
    # casaco
    a('<path d="M104,300 C130,286 168,282 202,288 C232,294 262,286 288,270 '
      'C312,256 324,246 333,238 L333,566 L12,566 L12,344 C46,334 80,318 104,300 Z" '
      'fill="url(#gGarment)"/>')
    a('<path d="M104,300 C130,286 168,282 202,288 C232,294 262,286 288,270" '
      'fill="none" stroke="#0A1424" stroke-width="3" opacity="0.5"/>')
    c.folds(137, ["#2A4066", "#16233A", "#5A7092", "#8FA8C8"], 95, 300, 470, 3.0)
    c.under_chin("M120,290 C150,308 200,308 226,286")
    # dragonas
    for (ox, oy, rot) in [(92, 332, -18), (272, 314, 18)]:
        a('<g transform="translate(%s,%s) rotate(%s)">' % (ox, oy, rot))
        a('<rect x="-26" y="-7" width="52" height="14" rx="7" fill="#C9A227"/>')
        a('<path d="M-20,-4 L20,-4 M-20,0 L20,0 M-20,4 L20,4" stroke="#8A6A10" '
          'stroke-width="1" opacity="0.6"/>')
        a('<path d="M20,-9 l10,0 M20,-2 l10,0 M20,5 l10,0" stroke="#C9A227" '
          'stroke-width="1.8" stroke-linecap="round"/>')
        a('</g>')
    # gola / gravata
    a('<path d="M136,268 C158,258 186,258 206,268 L216,320 L128,320 Z" '
      'fill="#E8DCC0"/>')
    a('<path d="M148,272 C166,266 180,266 194,272 L198,306 L142,306 Z" '
      'fill="#F4ECD8"/>')
    a('<path d="M166,276 L172,276 L176,300 L168,300 Z" fill="#C9A227" opacity="0.8"/>')
    # lapelas
    a('<path d="M134,286 L112,300 L120,340 L150,318 Z" fill="#152A48"/>')
    a('<path d="M206,286 L232,300 L226,340 L192,318 Z" fill="#152A48"/>')
    a('<path d="M134,286 L112,300 L120,340 L150,318 Z" fill="none" stroke="#C9A227" '
      'stroke-width="1.6" opacity="0.75"/>')
    a('<path d="M206,286 L232,300 L226,340 L192,318 Z" fill="none" stroke="#C9A227" '
      'stroke-width="1.6" opacity="0.75"/>')
    # cabeça
    a('<path d="M116,240 C116,266 124,290 136,306 L204,306 C218,288 226,264 228,238 Z" '
      'fill="#4A3020" opacity="0.4"/>')
    a('<path d="M106,198 C106,176 120,158 144,152 C172,146 198,154 212,172 '
      'C226,190 230,216 224,240 C218,264 196,278 170,278 C144,278 122,262 '
      '112,238 C106,222 106,210 106,198 Z" fill="url(#gSkin)"/>')
    a('<g clip-path="url(#faceClip)">')
    a('<path d="M104,186 C120,172 152,164 186,168 C204,170 214,176 218,182 '
      'C196,176 162,178 132,190 C120,194 110,192 104,186 Z" fill="#8E5A38" opacity="0.55"/>')
    a('<path d="M104,206 C118,196 148,192 172,196 C190,199 204,204 212,210 '
      'C198,220 168,220 142,214 C124,210 110,212 104,206 Z" fill="#B27A50" opacity="0.4"/>')
    a('<path d="M108,210 C120,200 140,196 158,200 C148,214 124,216 108,210 Z" '
      'fill="#E8C79C" opacity="0.5"/>')
    random.seed(53)
    for _ in range(80):
        x = random.uniform(106, 226)
        y = random.uniform(160, 270)
        a('<path d="M%.1f,%.1f l%.1f,%.1f" stroke="%s" stroke-width="%.2f" opacity="%.2f" '
          'stroke-linecap="round"/>'
          % (x, y, random.uniform(-5, 5), random.uniform(4, 14),
             random.choice(["#7A4A2E", "#5E3520", "#C08A5C"]),
             random.uniform(0.3, 0.8), random.uniform(0.06, 0.2)))
    a('</g>')
    # costeletas
    a('<path d="M104,192 C114,184 124,190 126,204 C128,222 122,242 114,250 '
      'C106,240 102,214 104,192 Z" fill="#2E1A12" opacity="0.9"/>')
    a('<path d="M226,190 C216,184 206,190 204,204 C202,222 208,242 216,250 '
      'C224,240 228,212 226,190 Z" fill="#2E1A12" opacity="0.9"/>')
    # sobrancelhas
    a('<path d="M112,196 C126,188 146,185 160,188" stroke="#2E1A12" stroke-width="5.4" '
      'fill="none" stroke-linecap="round" opacity="0.95"/>')
    a('<path d="M180,188 C196,185 212,190 220,198" stroke="#2E1A12" stroke-width="5" '
      'fill="none" stroke-linecap="round" opacity="0.95"/>')
    # olhos
    a('<path d="M114,210 C126,202 144,201 154,207 C145,218 126,219 114,210 Z" '
      'fill="#3A1A14"/>')
    a('<circle cx="134" cy="209" r="2.6" fill="#0E0705"/>')
    a('<path d="M178,206 C190,200 208,200 216,205 C207,215 190,216 178,206 Z" '
      'fill="#3A1A14"/>')
    a('<circle cx="197" cy="206" r="2.6" fill="#0E0705"/>')
    # nariz
    a('<path d="M158,190 C168,202 166,218 154,228 C146,235 137,230 136,222 '
      'C135,208 146,194 158,190 Z" fill="#E8B888"/>')
    a('<path d="M137,223 C141,231 150,236 160,234 C161,240 152,243 143,240 '
      'C136,238 134,228 137,223 Z" fill="#8E5238" opacity="0.8"/>')
    # bigode
    a('<path d="M120,240 C140,232 164,230 182,236 C198,241 212,240 220,234 '
      'C218,246 204,258 182,258 C158,258 132,252 120,246 Z" fill="#2E1A12"/>')
    a('<path d="M124,243 C142,237 160,235 176,239" stroke="#8A5E40" stroke-width="2.4" '
      'fill="none" opacity="0.85" stroke-linecap="round"/>')
    a('<path d="M130,249 C148,244 166,242 182,246" stroke="#6E4630" stroke-width="1.8" '
      'fill="none" opacity="0.8" stroke-linecap="round"/>')
    a('<path d="M204,240 C210,242 214,244 216,247" stroke="#8A5E40" stroke-width="1.8" '
      'fill="none" opacity="0.7" stroke-linecap="round"/>')
    # queixo
    a('<path d="M136,264 C152,272 176,272 194,264 C192,276 170,282 152,278 Z" '
      'fill="#9E6644" opacity="0.45"/>')
    # bicorne
    a('<path d="M84,170 C96,132 130,110 172,106 C214,102 252,122 268,156 '
      'C274,168 268,180 252,178 C222,172 200,176 176,180 C150,184 118,182 96,178 '
      'C86,176 82,176 84,170 Z" fill="#131E30"/>')
    a('<path d="M84,170 C96,132 130,110 172,106 C214,102 252,122 268,156 '
      'C250,140 216,124 176,126 C136,128 104,146 84,170 Z" fill="#22304A"/>')
    a('<path d="M90,168 C108,146 138,132 176,130 C214,128 246,142 262,160" '
      'fill="none" stroke="#C9A227" stroke-width="3" opacity="0.8"/>')
    a('<circle cx="176" cy="146" r="7" fill="#C9A227"/>')
    a('<circle cx="176" cy="146" r="3.2" fill="#8A6A10"/>')
    a('<path d="M118,166 l12,-4 M132,160 l12,-4" stroke="#C9A227" stroke-width="2" '
      'opacity="0.6" stroke-linecap="round"/>')
    c.script()
    c.band([hand_blocked(112, 505, 0.95), AMP, coin1(214, 492, 8.6), coin1(228, 504, 8.2),
            coin1(238, 514, 7.6), xmark(250, 470, 9, 6.4)])
    a('<g opacity="0.15" style="mix-blend-mode:multiply">')
    a('<rect x="12" y="12" width="320" height="553" filter="url(#grain)"/>')
    a('</g>')
    return c


def build_condessa():
    pal = dict(
        desc="Condessa de rosto pálido, cabelo apanhado com tiara e gola de renda alta, "
             "sobre aguada violeta.",
        wash=["#2A1036", "#4A1A5E", "#6E2A80", "#8E3E96"],
        robe=["#3A1E46", "#2C1636", "#221028", "#170A1C"],
        bloom="#5A2A70",
        garment=["#8E3E96", "#6A2A72", "#43184A", "#240C28"],
        skin=["#F2DCC8", "#E8C6AE", "#D0A08C", "#A87064"],
        hat=["#8E3E96", "#6A2A72", "#43184A"],
        stri=["#4E3058", "#634070", "#38223E", "#7C5A88", "#26142C"],
        clips='<clipPath id="robeClip"><path d="M12,352 C50,348 92,342 132,340 '
              'C172,338 212,328 246,308 C276,291 302,270 333,240 L333,566 L12,566 Z"/>'
              '</clipPath>'
              '<clipPath id="faceClip"><path d="M116,200 C116,176 130,158 154,154 '
              'C180,150 202,162 210,182 C218,202 216,228 206,246 C196,264 178,274 '
              '158,274 C136,274 120,258 116,238 C113,224 114,212 116,200 Z"/>'
              '</clipPath>'
              '<clipPath id="collarClip2"><path d="M96,300 C92,266 106,238 132,224 '
              'L152,240 L176,246 L200,240 L220,224 C246,238 258,266 254,300 '
              'C230,316 190,324 172,324 C146,324 118,314 96,300 Z"/></clipPath>',
    )
    c = Card("condessa", "Condessa", pal)
    a = c.a
    c.paper()
    c.wash("M12,316 C36,318 60,326 82,340 C110,356 134,380 148,408 "
           "C156,426 158,444 158,460 L12,460 Z",
           "M12,352 C50,348 92,342 132,340 C172,338 212,328 246,308 "
           "C276,291 302,270 333,240 L333,566 L12,566 Z",
           [(198, 400, 92, 80, 0.8), (286, 340, 54, 44, 0.5)])
    c.striations(None, 19)
    # vestido
    a('<path d="M104,306 C132,290 168,286 202,292 C234,298 264,290 290,274 '
      'C312,260 324,250 333,242 L333,566 L12,566 L12,348 C44,338 82,324 104,306 Z" '
      'fill="url(#gGarment)"/>')
    a('<path d="M104,306 C132,290 168,286 202,292 C234,298 264,290 290,274" '
      'fill="none" stroke="#2A0C30" stroke-width="3" opacity="0.55"/>')
    c.folds(139, ["#5E2A66", "#3A1640", "#8E4E96", "#C088C8"], 90, 300, 470, 3.0)
    c.under_chin("M124,296 C150,312 198,312 222,292")
    # cabelo (massa escura atrás)
    a('<path d="M108,214 C104,178 122,146 154,136 C190,124 224,138 240,166 '
      'C252,188 250,214 242,236 C236,254 224,266 210,270 L206,246 '
      'C214,224 214,198 206,180 C196,158 172,150 150,158 C130,166 122,186 124,212 '
      'C126,232 132,250 142,262 L126,268 C114,254 108,234 108,214 Z" fill="#1C0A22"/>')
    a('<path d="M110,206 C108,172 126,144 156,134 C190,122 222,136 238,162" '
      'fill="none" stroke="#4A2452" stroke-width="3" opacity="0.65"/>')
    a('<g stroke="#4A2452" stroke-width="2.2" fill="none" opacity="0.55">')
    random.seed(31)
    for i in range(22):
        x = random.uniform(114, 236)
        y = random.uniform(146, 244)
        a('<path d="M%.1f,%.1f q%.1f,%.1f %.1f,%.1f"/>'
          % (x, y, random.uniform(-6, 6), 12, random.uniform(-8, 8), 24))
    a('</g>')
    # tiara
    a('<path d="M138,146 C150,132 170,126 188,130 C204,134 214,144 218,156 '
      'L210,160 C200,150 188,144 174,146 C160,148 148,154 142,162 Z" fill="#C9A227"/>')
    a('<circle cx="176" cy="136" r="4.6" fill="#E8D48A"/>')
    # rosto
    a('<path d="M116,200 C116,176 130,158 154,154 C180,150 202,162 210,182 '
      'C218,202 216,228 206,246 C196,264 178,274 158,274 C136,274 120,258 '
      '116,238 C113,224 114,212 116,200 Z" fill="url(#gSkin)"/>')
    a('<g clip-path="url(#faceClip)">')
    a('<path d="M112,170 C130,158 168,154 200,162 C212,166 216,172 214,178 '
      'C190,170 154,172 124,182 C116,184 110,178 112,170 Z" fill="#C08A7E" opacity="0.4"/>')
    a('<path d="M112,206 C126,198 148,196 168,200 C150,214 128,216 112,206 Z" '
      'fill="#F8EDE2" opacity="0.9"/>')
    a('<path d="M186,200 C200,196 214,200 218,208 C206,216 192,214 186,200 Z" '
      'fill="#F8EDE2" opacity="0.8"/>')
    a('<path d="M120,230 C132,240 148,246 162,244 C154,258 138,262 126,254 '
      'C118,248 116,238 120,230 Z" fill="#D8A6A0" opacity="0.5"/>')
    a('<path d="M186,240 C198,238 210,232 214,224 C218,234 212,246 200,252 '
      'C192,256 186,250 186,240 Z" fill="#D8A6A0" opacity="0.45"/>')
    a('</g>')
    # sobrancelhas finas
    a('<path d="M122,196 C134,190 148,189 158,192" stroke="#3A1A2E" stroke-width="3" '
      'fill="none" stroke-linecap="round"/>')
    a('<path d="M180,192 C192,189 206,190 214,196" stroke="#3A1A2E" stroke-width="3" '
      'fill="none" stroke-linecap="round"/>')
    # olhos amendoados
    a('<path d="M118,208 C130,200 146,199 156,205 C147,215 130,216 118,208 Z" '
      'fill="#F6ECE2"/>')
    a('<circle cx="138" cy="207" r="3.4" fill="#2A1226"/>')
    a('<circle cx="138" cy="207" r="1.5" fill="#0A0408"/>')
    a('<path d="M118,208 C130,201 146,200 156,205" stroke="#3A1A2E" stroke-width="1.6" '
      'fill="none" stroke-linecap="round"/>')
    a('<path d="M180,205 C190,199 206,200 216,207 C206,215 190,214 180,205 Z" '
      'fill="#F6ECE2"/>')
    a('<circle cx="199" cy="205" r="3.4" fill="#2A1226"/>')
    a('<circle cx="199" cy="205" r="1.5" fill="#0A0408"/>')
    a('<path d="M180,205 C190,200 206,201 216,207" stroke="#3A1A2E" stroke-width="1.6" '
      'fill="none" stroke-linecap="round"/>')
    # nariz
    a('<path d="M158,196 C166,206 164,220 156,228 C150,233 144,229 143,222 '
      'C142,210 150,200 158,196 Z" fill="#F8E4D2"/>')
    a('<path d="M144,222 C147,228 154,231 160,229 C160,234 153,236 147,233 '
      'C143,231 142,225 144,222 Z" fill="#C08A7E" opacity="0.7"/>')
    # boca
    a('<path d="M148,246 C154,242 166,242 174,246 C168,252 154,252 148,246 Z" '
      'fill="#B02448"/>')
    a('<path d="M150,247 C158,250 168,250 174,247" stroke="#7A0E2A" stroke-width="1.2" '
      'fill="none" opacity="0.8"/>')
    # gola de renda
    a('<path d="M102,308 C98,288 108,268 130,258 L150,270 L176,274 L200,270 L218,258 '
      'C242,268 250,288 248,308 C226,322 190,328 172,328 C148,328 122,320 102,308 Z" '
      'fill="#F4E9DC"/>')
    a('<g clip-path="url(#collarClip2)">')
    for i in range(11):
        a('<path d="M%s,312 C%s,296 %s,282 %s,268" fill="none" stroke="#D8C4B0" '
          'stroke-width="1.5" opacity="0.7"/>'
          % (112 + i * 13, 110 + i * 13, 116 + i * 13, 118 + i * 13))
    a('<path d="M96,300 C120,312 148,318 172,318 C200,318 232,310 254,298" '
      'fill="none" stroke="#D8C4B0" stroke-width="2" opacity="0.8"/>')
    a('</g>')
    # pérolas
    a('<g fill="#F0E6D8">')
    for i in range(7):
        a('<circle cx="%s" cy="%s" r="2.6"/>' % (150 + i * 8, 308 - abs(i - 3) * 1.5))
    a('</g>')
    c.script()
    c.band([crown(122, 492, 1.0), AMP, dagger(226, 484, 0.92), xmark(238, 505, 9, 6.6)])
    a('<g opacity="0.15" style="mix-blend-mode:multiply">')
    a('<rect x="12" y="12" width="320" height="553" filter="url(#grain)"/>')
    a('</g>')
    return c


def build_embaixador():
    pal = dict(
        desc="Embaixador de turbante com joia e manto verde-oliva com debrum dourado, "
             "sobre aguada esverdeada.",
        wash=["#0E2A1E", "#1A4630", "#2A6A46", "#3E8A5E"],
        robe=["#2A3A2A", "#1E2A1E", "#182216", "#0E1410"],
        bloom="#2E4A32",
        garment=["#4A6A3E", "#2E4A2E", "#1E3220", "#101C12"],
        skin=["#C89268", "#AE774E", "#8A5638", "#5A3626"],
        hat=["#4A6A3E", "#2E4A2E", "#1E3220"],
        stri=["#3A4A38", "#4C6048", "#2A3428", "#5E7458", "#1A2018"],
        clips='<clipPath id="robeClip"><path d="M12,350 C50,346 90,340 130,340 '
              'C170,340 210,330 246,310 C276,293 302,272 333,240 L333,566 L12,566 Z"/>'
              '</clipPath>'
              '<clipPath id="faceClip"><path d="M108,200 C108,178 122,160 146,154 '
              'C174,148 200,156 214,174 C228,192 232,218 226,242 C220,266 198,280 '
              '172,280 C146,280 124,264 114,240 C108,224 108,212 108,200 Z"/>'
              '</clipPath>',
    )
    c = Card("embaixador", "Embaixador", pal)
    a = c.a
    c.paper()
    c.wash("M12,318 C36,320 58,326 80,338 C108,352 132,376 145,404 "
           "C153,422 156,440 156,458 L12,458 Z",
           "M12,350 C50,346 90,340 130,340 C170,340 210,330 246,310 "
           "C276,293 302,272 333,240 L333,566 L12,566 Z",
           [(196, 400, 92, 80, 0.8), (284, 338, 56, 44, 0.55)])
    c.striations(None, 23)
    # manto
    a('<path d="M100,306 C128,290 168,286 202,292 C234,298 264,290 290,274 '
      'C312,260 324,250 333,242 L333,566 L12,566 L12,346 C44,336 80,322 100,306 Z" '
      'fill="url(#gGarment)"/>')
    a('<path d="M100,306 C128,290 168,286 202,292 C234,298 264,290 290,274" '
      'fill="none" stroke="#C9A227" stroke-width="3" opacity="0.6"/>')
    c.folds(149, ["#4A6A3E", "#22301E", "#7A9A5E", "#C9A227"], 90, 300, 470, 3.0)
    c.under_chin("M120,292 C150,310 198,310 224,288")
    a('<path d="M100,306 C128,290 168,286 202,292 C234,298 264,290 290,274 '
      'L294,286 C262,302 232,310 202,304 C170,298 132,302 104,318 Z" '
      'fill="#C9A227" opacity="0.35"/>')
    # xale / gola
    a('<path d="M118,272 C142,258 178,256 206,268 L226,330 L104,330 Z" '
      'fill="#D8C48A"/>')
    a('<path d="M126,278 C150,266 178,266 200,276 L212,322 L112,322 Z" '
      'fill="#E8D8A8"/>')
    a('<path d="M132,300 L206,300 M130,310 L208,310" stroke="#B89A50" stroke-width="2.4" '
      'opacity="0.7"/>')
    a('<path d="M164,280 L170,280 L174,318 L166,318 Z" fill="#8A6A10" opacity="0.6"/>')
    # cabeça
    a('<path d="M116,242 C116,268 124,292 136,308 L204,308 C218,290 226,266 228,240 Z" '
      'fill="#4A3020" opacity="0.35"/>')
    a('<path d="M108,200 C108,178 122,160 146,154 C174,148 200,156 214,174 '
      'C228,192 232,218 226,242 C220,266 198,280 172,280 C146,280 124,264 '
      '114,240 C108,224 108,212 108,200 Z" fill="url(#gSkin)"/>')
    a('<g clip-path="url(#faceClip)">')
    a('<path d="M106,188 C124,174 158,166 192,170 C208,172 218,178 222,184 '
      'C198,178 164,180 134,192 C122,196 112,194 106,188 Z" fill="#8E5A38" opacity="0.55"/>')
    a('<path d="M106,208 C120,198 150,194 174,198 C192,201 206,206 214,212 '
      'C200,222 170,222 144,216 C126,212 112,214 106,208 Z" fill="#B27A50" opacity="0.4"/>')
    a('<path d="M110,212 C122,202 142,198 160,202 C150,216 126,218 110,212 Z" '
      'fill="#E8C79C" opacity="0.5"/>')
    random.seed(61)
    for _ in range(70):
        x = random.uniform(108, 226)
        y = random.uniform(162, 272)
        a('<path d="M%.1f,%.1f l%.1f,%.1f" stroke="%s" stroke-width="%.2f" opacity="%.2f" '
          'stroke-linecap="round"/>'
          % (x, y, random.uniform(-5, 5), random.uniform(4, 14),
             random.choice(["#7A4A2E", "#5E3520", "#C08A5C"]),
             random.uniform(0.3, 0.8), random.uniform(0.06, 0.2)))
    a('</g>')
    # barba curta
    a('<path d="M118,252 C126,278 148,292 174,292 C198,292 216,278 224,254 '
      'C216,270 200,280 180,280 C160,280 132,272 118,252 Z" fill="#3E2418" opacity="0.85"/>')
    a('<path d="M126,258 C138,276 156,284 176,284 C194,284 210,274 218,258 '
      'C212,282 194,294 172,294 C150,294 132,282 126,258 Z" fill="#2E1A12" opacity="0.8"/>')
    # sobrancelhas
    a('<path d="M114,196 C128,188 148,186 162,189" stroke="#2E1A12" stroke-width="5.2" '
      'fill="none" stroke-linecap="round" opacity="0.95"/>')
    a('<path d="M182,189 C198,186 212,190 220,198" stroke="#2E1A12" stroke-width="4.8" '
      'fill="none" stroke-linecap="round" opacity="0.95"/>')
    # olhos calmos
    a('<path d="M116,210 C128,202 146,201 156,207 C147,218 128,219 116,210 Z" '
      'fill="#3A1A14"/>')
    a('<circle cx="136" cy="209" r="2.4" fill="#0E0705"/>')
    a('<path d="M180,207 C192,201 210,201 218,206 C209,216 192,217 180,207 Z" '
      'fill="#3A1A14"/>')
    a('<circle cx="199" cy="207" r="2.4" fill="#0E0705"/>')
    # nariz
    a('<path d="M160,192 C170,204 168,220 156,230 C148,237 139,232 138,224 '
      'C137,210 148,196 160,192 Z" fill="#E0B084"/>')
    a('<path d="M139,225 C143,233 152,238 162,236 C163,242 154,245 145,242 '
      'C138,240 136,230 139,225 Z" fill="#8E5238" opacity="0.8"/>')
    # boca
    a('<path d="M142,248 C152,244 168,244 178,248 C170,256 150,256 142,248 Z" '
      'fill="#7A3A2E"/>')
    a('<path d="M144,249 C154,252 168,252 176,249" stroke="#4A1E14" stroke-width="1.2" '
      'fill="none" opacity="0.8"/>')
    # turbante
    a('<path d="M96,184 C92,148 116,120 152,112 C190,104 224,122 238,152 '
      'C246,170 244,182 236,188 C212,180 182,178 154,180 C128,182 106,188 98,192 Z" '
      'fill="#E0D2B2"/>')
    a('<path d="M100,176 C104,148 124,124 152,116 C182,108 214,124 230,148 '
      'C212,132 182,126 156,130 C130,134 110,152 100,176 Z" fill="#EFE4CA"/>')
    a('<path d="M104,182 C120,158 150,142 180,140 C208,138 230,152 240,168" '
      'fill="none" stroke="#C9A227" stroke-width="7" opacity="0.5"/>')
    a('<path d="M94,180 C90,144 114,116 152,108 C192,100 228,118 242,150 '
      'C226,132 196,122 164,126 C132,130 106,150 96,176 Z" fill="#F4EAD2"/>')
    a('<path d="M100,168 C112,150 138,136 168,132 C196,128 224,138 238,154" '
      'fill="none" stroke="#C9A227" stroke-width="4" opacity="0.8"/>')
    a('<path d="M104,176 C118,158 144,144 172,140 C200,136 226,146 240,162" '
      'fill="none" stroke="#B89A50" stroke-width="1.6" opacity="0.6"/>')
    a('<path d="M150,116 C166,110 190,110 206,118 C190,122 168,122 152,124 Z" '
      'fill="#C9A227" opacity="0.55"/>')
    # joia
    a('<circle cx="168" cy="124" r="9" fill="#C9A227"/>')
    a('<circle cx="168" cy="124" r="5.4" fill="#B02448"/>')
    a('<circle cx="166" cy="122" r="2" fill="#E8D48A" opacity="0.9"/>')
    a('<path d="M150,146 C158,140 178,138 190,144" fill="none" stroke="#8A6A10" '
      'stroke-width="1.4" opacity="0.6"/>')
    c.script()
    c.band([cards2(120, 494, 1.05), AMP, hand_blocked(216, 500, 0.9),
            xmark(250, 472, 8.6, 6.2)])
    a('<g opacity="0.15" style="mix-blend-mode:multiply">')
    a('<rect x="12" y="12" width="320" height="553" filter="url(#grain)"/>')
    a('</g>')
    return c


def main():
    os.makedirs(OUTDIR, exist_ok=True)
    builders = [build_duque, build_assassino, build_capitao, build_condessa, build_embaixador]
    for fn in builders:
        c = fn()
        svg = c.render()
        path = os.path.join(OUTDIR, "%s.svg" % c.cid)
        with open(path, "w", encoding="utf-8") as f:
            f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
            f.write(svg)
        print("wrote", path, len(svg))


if __name__ == "__main__":
    main()
