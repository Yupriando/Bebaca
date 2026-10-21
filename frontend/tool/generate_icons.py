#!/usr/bin/env python3
"""
Membuat ikon Bebaca (PNG) -> assets/images/
  - logo_icon.png  : logo persegi 1:1 (diambil dari logo.png tanpa tulisan "Bebaca")
  - nav_belajar.png, nav_dongeng.png, nav_profile.png, nav_settings.png : ikon menu berwarna
  - assets/icon/app_icon.png            : ikon aplikasi (iPhone/iPad, Android lama, web)
  - assets/icon/app_icon_foreground.png : ikon Android modern (maskot diperkecil agar tidak terpotong)
  Setelah itu pasang ke semua platform:  dart run flutter_launcher_icons
Jalankan ulang bila ingin mengubah gambar:   pip install pillow && python3 tool/generate_icons.py
Mau pakai gambar sendiri? Ganti file di assets/images/ dengan nama yang sama (.png).
"""
import math
import os
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'images')
S = 1024          # kanvas gambar (digambar besar lalu diperkecil agar halus)
FINAL = 256       # ukuran akhir ikon menu


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def save_icon(img, name):
    img.resize((FINAL, FINAL), Image.LANCZOS).save(os.path.join(OUT, name))
    print('ok', name)


def shadow(img, offset=(0, 18), blur=22, alpha=70):
    """Bayangan lembut di bawah gambar."""
    a = img.split()[-1].point(lambda v: v * alpha // 255)
    sh = Image.new('RGBA', img.size, (0, 0, 0, 0))
    sh.putalpha(a)
    sh = sh.filter(ImageFilter.GaussianBlur(blur))
    out = Image.new('RGBA', img.size, (0, 0, 0, 0))
    out.alpha_composite(sh, offset)
    out.alpha_composite(img)
    return out


# ---------------------------------------------------------------- logo 1:1
def logo_square(art_width=1000):
    """Logo maskot (tanpa tulisan) di kanvas persegi S x S, dengan latar gradien
    yang meniru latar logo asli. art_width kecil = maskot lebih kecil di tengah."""
    src = Image.open(os.path.join(OUT, 'logo.png')).convert('RGB')
    bg = Image.new('RGB', (S, S))
    px = bg.load()
    c_in, c_out = (16, 52, 118), (2, 4, 48)
    for y in range(S):
        for x in range(S):
            d = min(1.0, math.hypot(x - S / 2, y - S / 2) / (S * 0.72))
            px[x, y] = lerp(c_in, c_out, d)
    # potong bagian gambar (tanpa tulisan), lalu letakkan di tengah dengan tepi menyatu
    art = src.crop((50, 25, 974, 785))
    w = art_width
    h = round(art.height * w / art.width)
    art = art.resize((w, h), Image.LANCZOS)
    edge = max(12, w // 25)
    mask = Image.new('L', (w, h), 0)
    ImageDraw.Draw(mask).rectangle((edge, edge, w - edge, h - edge), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(edge * 0.7))
    bg.paste(art, ((S - w) // 2, (S - h) // 2), mask)
    return bg


def make_logo_icon():
    logo_square().resize((512, 512), Image.LANCZOS).save(os.path.join(OUT, 'logo_icon.png'))
    print('ok logo_icon.png')


def make_app_icons():
    out = os.path.join(OUT, '..', 'icon')
    os.makedirs(out, exist_ok=True)
    logo_square(960).save(os.path.join(out, 'app_icon.png'))
    # Android adaptive: hanya ~66% tengah yang terlihat -> maskot dikecilkan ke area aman
    logo_square(640).save(os.path.join(out, 'app_icon_foreground.png'))
    print('ok assets/icon/app_icon.png, app_icon_foreground.png')


# ---------------------------------------------------------------- Belajar
def book(d, x0, y0, x1, y1, cover, dark, r=22):
    d.rounded_rectangle((x0, y0, x1, y1), r, fill=cover)
    # halaman (sisi kanan putih bergaris)
    d.rounded_rectangle((x1 - 70, y0 + 16, x1 - 6, y1 - 16), 10, fill=(250, 246, 232))
    for i in range(1, 4):
        yy = y0 + 16 + i * (y1 - y0 - 32) / 4
        d.line((x1 - 66, yy, x1 - 10, yy), fill=(214, 206, 184), width=4)
    d.rectangle((x0 + 40, y0, x0 + 64, y1), fill=dark)   # pita punggung buku
    d.rectangle((x0 + 90, y0, x0 + 104, y1), fill=dark)


def make_belajar():
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # tumpukan buku
    book(d, 150, 760, 820, 900, (104, 140, 72), (72, 100, 48))
    book(d, 190, 630, 860, 770, (52, 120, 196), (30, 82, 150))
    book(d, 170, 500, 800, 640, (214, 72, 72), (160, 44, 48))
    # topi wisuda
    d.polygon([(470, 470), (470, 380), (720, 380), (720, 470)], fill=(20, 60, 110))
    d.ellipse((470, 440, 720, 500), fill=(20, 60, 110))
    d.polygon([(595, 200), (900, 320), (595, 440), (290, 320)], fill=(30, 90, 160))
    d.polygon([(595, 200), (900, 320), (595, 330), (290, 320)], fill=(48, 118, 196))
    d.ellipse((575, 300, 615, 340), fill=(250, 196, 40))
    d.line((595, 320, 330, 345), fill=(250, 196, 40), width=10)
    d.line((330, 345, 330, 470), fill=(250, 196, 40), width=10)
    d.rounded_rectangle((308, 460, 352, 540), 10, fill=(250, 196, 40))
    # pensil
    pen = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    p = ImageDraw.Draw(pen)
    p.rectangle((380, 470, 820, 520), fill=(250, 190, 40))
    p.rectangle((380, 470, 820, 486), fill=(255, 214, 90))
    p.rectangle((340, 470, 380, 520), fill=(232, 120, 140))
    p.rectangle((380, 470, 400, 520), fill=(190, 190, 200))
    p.polygon([(820, 470), (900, 495), (820, 520)], fill=(240, 210, 170))
    p.polygon([(875, 487), (900, 495), (875, 503)], fill=(60, 60, 60))
    pen = pen.rotate(32, center=(620, 495), resample=Image.BICUBIC)
    img.alpha_composite(pen, (60, -140))
    save_icon(shadow(img), 'nav_belajar.png')


# ---------------------------------------------------------------- Dongeng
def leaf(d, cx, cy, length, width, angle, color):
    a = math.radians(angle)
    pts = []
    for i in range(41):
        t = i / 40
        along = t * length
        side = math.sin(t * math.pi) * width / 2
        pts.append((along, side))
    pts += [(x, -y) for x, y in reversed(pts)]
    rot = [(cx + x * math.cos(a) - y * math.sin(a), cy + x * math.sin(a) + y * math.cos(a)) for x, y in pts]
    d.polygon(rot, fill=color)


def flower(d, cx, cy, r, petal, center):
    for k in range(5):
        a = math.radians(k * 72 - 90)
        d.ellipse((cx + math.cos(a) * r - r * 0.7, cy + math.sin(a) * r - r * 0.7,
                   cx + math.cos(a) * r + r * 0.7, cy + math.sin(a) * r + r * 0.7), fill=petal)
    d.ellipse((cx - r * 0.55, cy - r * 0.55, cx + r * 0.55, cy + r * 0.55), fill=center)


def make_dongeng():
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # tanaman di belakang buku
    greens = [(76, 160, 96), (110, 190, 110), (46, 130, 110), (140, 200, 120)]
    for i, (cx, cy, ln, ang) in enumerate([
        (300, 560, 330, -120), (330, 560, 300, -95), (700, 560, 330, -60), (680, 560, 300, -85),
        (240, 600, 280, -150), (780, 600, 280, -30), (512, 520, 300, -90), (420, 540, 260, -105),
        (600, 540, 260, -75),
    ]):
        leaf(d, cx, cy, ln, 90, ang, greens[i % len(greens)])
    flower(d, 260, 300, 34, (240, 120, 140), (255, 210, 80))
    flower(d, 780, 270, 30, (250, 170, 90), (255, 230, 120))
    flower(d, 512, 220, 28, (120, 170, 240), (255, 230, 120))
    d.ellipse((150, 380, 180, 410), fill=(250, 196, 40))
    d.ellipse((860, 400, 885, 425), fill=(250, 196, 40))
    # sampul buku
    d.polygon([(120, 470), (512, 520), (904, 470), (904, 860), (512, 900), (120, 860)], fill=(228, 140, 48))
    # halaman
    d.polygon([(150, 430), (500, 480), (500, 860), (150, 820)], fill=(255, 255, 255))
    d.polygon([(524, 480), (874, 430), (874, 820), (524, 860)], fill=(242, 242, 242))
    d.polygon([(150, 820), (500, 860), (500, 875), (150, 838)], fill=(220, 220, 220))
    d.polygon([(524, 860), (874, 820), (874, 838), (524, 875)], fill=(205, 205, 205))
    d.line((512, 478, 512, 880), fill=(180, 120, 60), width=10)
    # pita pembatas
    d.polygon([(760, 445), (810, 438), (810, 560), (785, 535), (760, 565)], fill=(220, 60, 70))
    save_icon(shadow(img), 'nav_dongeng.png')


# ---------------------------------------------------------------- Profile
def make_profile():
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    circle = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    cd = ImageDraw.Draw(circle)
    # lingkaran bergradien biru
    for r in range(440, 0, -4):
        t = r / 440
        cd.ellipse((512 - r, 512 - r - (1 - t) * 60, 512 + r, 512 + r - (1 - t) * 60),
                   fill=lerp((90, 170, 255), (20, 110, 230), t))
    # bayangan panjang di dalam lingkaran
    lng = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    ld = ImageDraw.Draw(lng)
    ld.polygon([(380, 330), (640, 330), (1100, 790), (1100, 1100), (750, 1100), (290, 640)], fill=(10, 70, 180, 150))
    mask = Image.new('L', (S, S), 0)
    ImageDraw.Draw(mask).ellipse((72, 72, 952, 952), fill=255)
    lng.putalpha(Image.composite(lng.split()[-1], Image.new('L', (S, S), 0), mask))
    circle.alpha_composite(lng)
    cd = ImageDraw.Draw(circle)
    # siluet orang
    cd.ellipse((392, 230, 632, 500), fill=(255, 255, 255))
    cd.chord((262, 520, 762, 980), 180, 360, fill=(255, 255, 255))
    cd.rectangle((262, 750, 762, 800), fill=(255, 255, 255))
    body_mask = Image.new('L', (S, S), 0)
    ImageDraw.Draw(body_mask).ellipse((72, 72, 952, 952), fill=255)
    circle.putalpha(Image.composite(circle.split()[-1], Image.new('L', (S, S), 0), body_mask))
    img.alpha_composite(circle)
    save_icon(shadow(img, alpha=50), 'nav_profile.png')


# ---------------------------------------------------------------- Settings
def make_settings():
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = cy = 512
    teeth, r_out, r_in = 8, 420, 330
    pts = []
    for k in range(teeth):
        base = k * 360 / teeth - 90
        # kaki gigi lebih lebar dari puncaknya
        for off, r in ((-15, r_in), (-9, r_out), (9, r_out), (15, r_in)):
            a = math.radians(base + off)
            pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    d.polygon(pts, fill=(52, 52, 56))
    d.ellipse((cx - 345, cy - 345, cx + 345, cy + 345), fill=(52, 52, 56))
    # sorotan halus di bagian atas
    hl = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(hl).ellipse((cx - 300, cy - 300, cx + 300, cy + 300), fill=(90, 90, 96))
    hl_mask = Image.new('L', (S, S), 0)
    ImageDraw.Draw(hl_mask).rectangle((0, 0, S, cy), fill=255)
    hl.putalpha(Image.composite(hl.split()[-1], Image.new('L', (S, S), 0), hl_mask).filter(ImageFilter.GaussianBlur(40)))
    img.alpha_composite(hl)
    d = ImageDraw.Draw(img)
    d.ellipse((cx - 150, cy - 150, cx + 150, cy + 150), fill=(0, 0, 0, 0))
    d.ellipse((cx - 150, cy - 150, cx + 150, cy + 150), outline=(30, 30, 34), width=14)
    save_icon(shadow(img), 'nav_settings.png')


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    make_logo_icon()
    make_app_icons()
    make_belajar()
    make_dongeng()
    make_profile()
    make_settings()
