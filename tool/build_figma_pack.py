#!/usr/bin/env python3
"""Builds the Figma import pack: screen renders, brand vectors, a style guide
sheet, overview boards and a zip of it all.

Usage (from the project root, Flutter on PATH, Pillow installed):

    python3 tool/build_figma_pack.py out/figma

Writes the pack to the given folder and a .zip next to it.
"""

import json
import os
import shutil
import subprocess
import sys
import urllib.parse

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def render_screens(out):
    env = dict(os.environ, SCREENSHOT_DIR=os.path.join(out, 'screens'))
    subprocess.run(
        ['flutter', 'test', 'test/screenshots/screenshot_test.dart'],
        cwd=ROOT, env=env, check=True,
    )
    # Golden file names arrive URL-encoded ("01%20Home.png").
    for folder, _, files in os.walk(os.path.join(out, 'screens')):
        for name in files:
            decoded = urllib.parse.unquote(name)
            if decoded != name:
                os.rename(os.path.join(folder, name), os.path.join(folder, decoded))


def copy_assets(out):
    brand = os.path.join(out, 'brand')
    fonts = os.path.join(out, 'fonts')
    guide = os.path.join(out, 'style guide')
    for d in (brand, fonts, guide):
        os.makedirs(d, exist_ok=True)
    a = os.path.join(ROOT, 'assets')
    copies = {
        'brand/birr_icon.svg': 'brand/Birr icon.svg',
        'brand/birr_icon.png': 'brand/Birr icon - black.png',
        'brand/birr_icon_white.png': 'brand/Birr icon - white.png',
        'brand/birr_icon_badge.png': 'brand/Birr icon - lime badge.png',
        'brand/icon.png': 'brand/App icon 1024.png',
        'brand/app_icon.svg': 'brand/App icon.svg',
        'brand/logo_mark.svg': 'brand/Logo mark - black.svg',
        'brand/logo_mark_lime.svg': 'brand/Logo mark - lime.svg',
        'fonts/OFL.txt': 'fonts/OFL.txt',
    }
    for w in (400, 500, 600, 700, 800):
        copies[f'fonts/PlusJakartaSans-w{w}.ttf'] = f'fonts/PlusJakartaSans-w{w}.ttf'
    for src, dst in copies.items():
        shutil.copy(os.path.join(a, src), os.path.join(out, dst))
    shutil.copy(os.path.join(ROOT, 'tool', 'design-tokens.json'),
                os.path.join(guide, 'design-tokens.json'))
    shutil.copy(os.path.join(ROOT, 'tool', 'figma_pack_README.txt'),
                os.path.join(out, 'README - How to import into Figma.txt'))


def font(out, weight, size):
    return ImageFont.truetype(os.path.join(out, 'fonts', f'PlusJakartaSans-w{weight}.ttf'), size)


def style_guide(out):
    tokens = json.load(open(os.path.join(out, 'style guide', 'design-tokens.json')))
    colors = tokens['color']
    W = 2400
    img = Image.new('RGB', (W, 6000), '#F1F2EE')
    d = ImageDraw.Draw(img)
    F = lambda w, s: font(out, w, s)  # noqa: E731
    d.text((120, 110), 'Event Budget — Style guide', font=F(700, 84), fill='#141414')
    d.text((120, 220), 'Lime & ink · Plus Jakarta Sans · rounded cards and pills',
           font=F(500, 38), fill='#6B6D70')
    y = 330

    def section(title):
        nonlocal y
        d.text((120, y), title, font=F(700, 48), fill='#141414')
        y += 90

    section('Highlight colours')
    for i, k in enumerate(['lime', 'lavender', 'coral', 'sky', 'butter', 'mint']):
        x, c = 120 + i * 340, colors['highlight/' + k]
        d.rounded_rectangle([x, y, x + 300, y + 220], radius=40, fill=c)
        d.text((x + 24, y + 150), k.title(), font=F(700, 34), fill='#141414')
        d.text((x + 24, y + 236), c, font=F(500, 30), fill='#6B6D70')
    y += 320
    for mode in ('light', 'dark'):
        section(f'{mode.title()} surfaces & text')
        for i, k in enumerate(['canvas', 'card', 'border', 'ink', 'muted', 'faint', 'track', 'nav']):
            x, c = 120 + i * 270, colors[f'{mode}/{k}']
            d.rounded_rectangle([x, y, x + 240, y + 170], radius=32, fill=c, outline='#D6D8D0', width=2)
            d.text((x + 10, y + 186), k.title(), font=F(700, 30), fill='#141414')
            d.text((x + 10, y + 226), c, font=F(500, 26), fill='#6B6D70')
        y += 300
    section('Status')
    for i, k in enumerate(['success', 'warning', 'danger', 'info', 'neutral']):
        x, c = 120 + i * 420, colors['status/' + k]
        d.ellipse([x, y, x + 120, y + 120], fill=c)
        d.text((x + 140, y + 20), k.title(), font=F(700, 34), fill='#141414')
        d.text((x + 140, y + 64), c, font=F(500, 28), fill='#6B6D70')
    y += 200
    section('Type scale  (Plus Jakarta Sans, shown at 2×)')
    for name, (size, weight, _) in tokens['type'].items():
        f = F(700 if weight >= 700 else 600 if weight >= 600 else 500, int(size * 2))
        d.text((120, y + 4), name, font=F(700, 30), fill='#141414')
        d.text((120, y + 44), f'{size}px · {weight}', font=F(500, 26), fill='#6B6D70')
        for sample in ('Br 25,453.00 · Sara & Daniel’s Wedding', 'Br 25,453.00 · Wedding', 'Br 25,453.00'):
            if d.textlength(sample, font=f) < W - 680:
                break
        d.text((560, y), sample, font=f, fill='#141414')
        y += max(int(size * 2 * 1.25), 80) + 34
    y += 20
    section('Shape')
    for i, (label, r) in enumerate([('Card · 28', 56), ('Small card · 20', 40), ('Field · 18', 36), ('Pill', 110)]):
        x = 120 + i * 460
        d.rounded_rectangle([x, y, x + 400, y + 220], radius=r, fill='#FFFFFF')
        d.text((x + 28, y + 150), label, font=F(700, 32), fill='#141414')
    y += 260
    img.crop((0, 0, W, y + 80)).save(os.path.join(out, 'style guide', 'Style guide.png'))


def boards(out):
    os.makedirs(os.path.join(out, 'boards'), exist_ok=True)
    F = lambda w, s: font(out, w, s)  # noqa: E731
    for mode, bg, fg, sub in (('light', '#E3E5DD', '#141414', '#6B6D70'),
                              ('dark', '#161618', '#F5F5F4', '#A1A1A6')):
        files = sorted(os.listdir(os.path.join(out, 'screens', mode)))
        cols, tw, th, gap, label, top = 7, 432, 936, 56, 70, 260
        rows = (len(files) + cols - 1) // cols
        W = cols * tw + (cols + 1) * gap
        H = top + rows * (th + label + gap) + gap
        img = Image.new('RGB', (W, H), bg)
        d = ImageDraw.Draw(img)
        d.text((gap, 70), f'Event Budget — all screens ({mode} mode)', font=F(700, 72), fill=fg)
        d.text((gap, 170), 'Onboarding → home → event (Overview, Money, Tasks, People, Notes) → details, forms and settings',
               font=F(500, 34), fill=sub)
        mask = Image.new('L', (tw, th), 0)
        ImageDraw.Draw(mask).rounded_rectangle([0, 0, tw - 1, th - 1], radius=36, fill=255)
        for i, f in enumerate(files):
            r, c = divmod(i, cols)
            x, y = gap + c * (tw + gap), top + r * (th + label + gap)
            shot = Image.open(os.path.join(out, 'screens', mode, f)).convert('RGB')
            img.paste(shot.resize((tw, th), Image.LANCZOS), (x, y), mask)
            d.text((x + 4, y + th + 18), f[:-4], font=F(600, 28), fill=fg)
        img.save(os.path.join(out, 'boards', f'All screens - {mode}.png'), optimize=True)


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    out = os.path.abspath(sys.argv[1])
    if os.path.exists(out):
        shutil.rmtree(out)
    os.makedirs(out)
    render_screens(out)
    copy_assets(out)
    style_guide(out)
    boards(out)
    zip_base = out.rstrip('/')
    shutil.make_archive(zip_base, 'zip', out)
    print(f'Pack written to {out} and {zip_base}.zip')


if __name__ == '__main__':
    main()
