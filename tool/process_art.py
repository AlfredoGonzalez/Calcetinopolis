#!/usr/bin/env python3
"""Quita el fondo magenta/blanco de los JPG de assets/art/source y deja PNG
transparentes en assets/art/.

Uso:  python3 tool/process_art.py [carpeta_fuente] [carpeta_salida]
Requiere: Pillow, numpy, scipy.

Reglas por nombre de archivo:
  biz_*, mgr_*        -> PNG 384x384 transparente, recortado al contenido
  icon_*              -> PNG 256x256 transparente, recortado al contenido
  app_icon.jpg        -> PNG 512x512 opaco (esquinas rellenas), íconos de Android (clásico,
                         adaptativo y temático) y logo de la pantalla de carga
  shop_*              -> PNG 384x384 transparente, recortado al contenido
  mascota_*, anim_*   -> PNG 512x512 transparente, SIN recorte (las poses y los cuadros
                         deben conservar el mismo encuadre y escala entre sí)
  ui_*                -> PNG 256x256 transparente, recortado al contenido
  logo_*.png          -> PNG transparente recortado al contenido, máx. 768 px
  bg_*                -> si las esquinas son magenta, PNG transparente (overlay);
                         si no, JPG opaco (fondos de pantalla)
  store_*             -> se omite (gráficos de Google Play: no van dentro de la app)
Las sombras de suelo (magenta oscuro) se eliminan; si se quieren, se dibujan en el juego.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

# m = min(R, B) - G es alto en magenta/rosa chillón y bajo en los colores del arte
# (crema, azul, café, rosa de mejillas). Se normaliza a alfa entre estos umbrales.
M_FULL_BG = 95
M_FULL_FG = 45
WHITE_MIN = 238          # "casi blanco" para las esquinas blancas de algunos archivos
MIN_COMPONENT_PX = 60    # motas más pequeñas se descartan
RING_SPAN = 0.75         # marcos/anillos que ocupan casi toda la imagen se descartan
SHADOW_MIN_AVG = 105     # sombras de suelo grisáceas/beige: ni tan oscuras como el contorno (café)
SHADOW_MAX_AVG = 215     # ni tan claras como la lana crema
MIN_THICKNESS = 4        # líneas finas sueltas (bordes JPEG, arcos del mosaico) se descartan
EDGE_PX = 4              # componentes pegados al borde de la imagen se descartan (restos del fondo)


def key_image(rgb: np.ndarray, drop_edge=True, holes=False):
    """Devuelve (alfa 0..1, color sin contaminación) para una imagen RGB float 0..255."""
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    m = np.minimum(r, b) - g
    raw = np.clip((M_FULL_BG - m) / (M_FULL_BG - M_FULL_FG), 0, 1)

    # Esquinas/bordes blancos: componentes casi blancos que tocan el borde.
    white = rgb.min(axis=2) >= WHITE_MIN
    lab, n = ndimage.label(white)
    if n:
        edge = np.unique(np.concatenate([lab[0, :], lab[-1, :], lab[:, 0], lab[:, -1]]))
        edge = edge[edge != 0]
        raw[np.isin(lab, edge)] = 0

    # Huecos blancos encerrados (por ejemplo, el centro de una flecha en espiral):
    # se vuelven transparentes. Solo para piezas que lo piden (prefijo ui_).
    if holes:
        lab_w, n_w = ndimage.label(white)
        for i, sl in enumerate(ndimage.find_objects(lab_w), start=1):
            comp = lab_w[sl] == i
            if comp.sum() >= 400 and raw[sl][comp].mean() > 0.5:
                raw[sl][comp] = 0

    # Sombras de suelo desaturadas (gris/beige) pegadas al fondo ya quitado: se
    # propagan desde el fondo y se detienen en el contorno café del dibujo.
    r_, g_, b_ = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    avg = (r_ + g_ + b_) / 3
    shadowish = (
        (np.abs(r_ - g_) < 45)
        & (np.abs(g_ - b_) < 35)
        & (avg > SHADOW_MIN_AVG)
        & (avg < SHADOW_MAX_AVG)
        & (raw > 0.02)
    )
    if shadowish.any():
        grow = shadowish | (raw <= 0.02)
        lab_s, _ = ndimage.label(grow)
        touching = np.unique(lab_s[(raw <= 0.02) & grow])
        touching = touching[touching != 0]
        raw[np.isin(lab_s, touching) & shadowish] = 0

    # Componentes: quitar motas, marcos y restos pegados al borde. Se evalúa con un
    # umbral bajo para que también caiga el halo tenue del borde del mosaico.
    h, w = raw.shape
    lab, n = ndimage.label(raw > 0.05)
    drop = np.zeros(raw.shape, bool)
    for i, sl in enumerate(ndimage.find_objects(lab), start=1):
        comp = lab[sl] == i
        area = int(comp.sum())
        bh, bw = comp.shape
        thin = ndimage.distance_transform_edt(np.pad(comp, 1)).max() < MIN_THICKNESS
        ring = bh >= RING_SPAN * h and bw >= RING_SPAN * w and area < 0.35 * bh * bw
        touches = (sl[0].start <= EDGE_PX or sl[1].start <= EDGE_PX or
                   sl[0].stop >= h - EDGE_PX or sl[1].stop >= w - EDGE_PX)
        if area < MIN_COMPONENT_PX or thin or ring or (drop_edge and touches):
            drop[sl] |= comp
    if drop.any():
        raw[ndimage.binary_dilation(drop, iterations=3)] = 0

    # Color: separar el fondo que se filtra en los bordes (a * F + (1 - a) * Bg).
    bgmask = raw < 0.02
    if bgmask.any():
        idx = ndimage.distance_transform_edt(bgmask, return_distances=False, return_indices=True)
        bg_color = rgb[idx[0], idx[1]]
    else:
        bg_color = np.zeros_like(rgb)
    a = np.clip(raw, 1e-3, 1)[..., None]
    fgc = np.clip((rgb - (1 - a) * bg_color) / a, 0, 255)
    fgc = np.where(raw[..., None] >= 0.999, rgb, fgc)

    # Borde un poco más ajustado para que no quede halo rosa.
    alpha = np.clip((raw - 0.2) / 0.6, 0, 1)
    return alpha, fgc


def to_rgba(alpha, color) -> Image.Image:
    out = np.dstack([color, alpha * 255]).clip(0, 255).astype(np.uint8)
    return Image.fromarray(out, 'RGBA')


def crop_square(img: Image.Image, pad=0.08) -> Image.Image:
    box = img.getchannel('A').point(lambda v: 255 if v > 8 else 0).getbbox()
    if not box:
        return img
    l, t, r, b = box
    side = int(max(r - l, b - t) * (1 + 2 * pad))
    cx, cy = (l + r) // 2, (t + b) // 2
    canvas = Image.new('RGBA', (side, side), (0, 0, 0, 0))
    canvas.paste(img.crop(box), (side // 2 - (r - l) // 2, side // 2 - (b - t) // 2))
    return canvas


def fill_corners(img: Image.Image) -> Image.Image:
    """Ícono de app: las esquinas blancas se rellenan con el color del borde."""
    rgb = np.asarray(img.convert('RGB')).astype(np.float32)
    white = rgb.min(axis=2) >= 235
    lab, _ = ndimage.label(white)
    edge = np.unique(np.concatenate([lab[0, :], lab[-1, :], lab[:, 0], lab[:, -1]]))
    mask = np.isin(lab, edge[edge != 0])
    mask = ndimage.binary_dilation(mask, iterations=4)
    idx = ndimage.distance_transform_edt(mask, return_distances=False, return_indices=True)
    rgb[mask] = rgb[idx[0][mask], idx[1][mask]]
    return Image.fromarray(rgb.clip(0, 255).astype(np.uint8))


ANDROID_SIZES = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}


def write_launcher_icons(icon: Image.Image, res_dir: Path):
    """Escribe ic_launcher.png en cada mipmap de Android a partir del ícono de la app."""
    for density, px in ANDROID_SIZES.items():
        d = res_dir / f'mipmap-{density}'
        if d.exists():
            icon.resize((px, px), Image.LANCZOS).save(d / 'ic_launcher.png', optimize=True)


ADAPTIVE_SCALE = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}


def icon_layers(icon: Image.Image):
    """Separa el ícono de la app en calcetín transparente y color de fondo.

    El fondo es liso con una viñeta suave: se quita lo conectado al borde que
    esté cerca del color mediano del borde. Solo se conserva el objeto más
    grande (el calcetín), sin el destello suelto.
    """
    a = np.asarray(icon.convert('RGB')).astype(int)
    border = np.concatenate([a[0], a[-1], a[:, 0], a[:, -1]])
    bg = np.median(border, axis=0)
    near = np.abs(a - bg).max(axis=2) <= 40
    lab, _ = ndimage.label(near)
    edge = set(lab[0, :]) | set(lab[-1, :]) | set(lab[:, 0]) | set(lab[:, -1])
    edge.discard(0)
    fg = ~np.isin(lab, list(edge))
    fg = ndimage.binary_opening(fg, iterations=1)
    objs, n = ndimage.label(fg)
    sizes = ndimage.sum(fg, objs, range(1, n + 1))
    fg = objs == (int(np.argmax(sizes)) + 1)
    fg = ndimage.binary_fill_holes(fg)
    alpha = ndimage.gaussian_filter(fg.astype(float), 0.7)
    rgba = np.dstack([a.clip(0, 255), (alpha * 255).clip(0, 255)]).astype(np.uint8)
    ys, xs = np.where(fg)
    sock = Image.fromarray(rgba, 'RGBA').crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
    return sock, tuple(int(v) for v in bg)


def fit_centered(sock: Image.Image, canvas: int, height_frac: float) -> Image.Image:
    """Calcetín centrado en un lienzo transparente, ocupando height_frac del alto."""
    h = int(canvas * height_frac)
    w = max(1, round(sock.width * h / sock.height))
    if w > canvas * height_frac * 1.1:  # por si fuera muy ancho
        w = int(canvas * height_frac * 1.1)
        h = max(1, round(sock.height * w / sock.width))
    out = Image.new('RGBA', (canvas, canvas), (0, 0, 0, 0))
    out.paste(sock.resize((w, h), Image.LANCZOS), ((canvas - w) // 2, (canvas - h) // 2))
    return out


def write_adaptive_icons(icon: Image.Image, res_dir: Path):
    """Ícono adaptativo (Android 8+), temático (13+) y logo de la pantalla de carga.

    La zona segura de un ícono adaptativo es el círculo central de 66 dp sobre 108 dp,
    así que el calcetín ocupa ~58% del lienzo.
    """
    sock, bg = icon_layers(icon)
    for density, k in ADAPTIVE_SCALE.items():
        d = res_dir / f'mipmap-{density}'
        if d.exists():
            fg = fit_centered(sock, round(108 * k), 0.58)
            fg.save(d / 'ic_launcher_foreground.png', optimize=True)
            mono = Image.new('RGBA', fg.size, (0, 0, 0, 0))
            mono.putalpha(fg.getchannel('A'))
            mono.save(d / 'ic_launcher_monochrome.png', optimize=True)
        sd = res_dir / f'drawable-{density}'
        sd.mkdir(exist_ok=True)
        fit_centered(sock, round(160 * k), 0.9).save(sd / 'splash_logo.png', optimize=True)
    (res_dir / 'values').mkdir(exist_ok=True)
    hexbg = '#%02X%02X%02X' % bg
    (res_dir / 'values' / 'colors.xml').write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<resources>\n'
        f'    <color name="ic_launcher_background">{hexbg}</color>\n'
        f'    <color name="splash_background">{hexbg}</color>\n'
        '</resources>\n'
    )
    any_dir = res_dir / 'mipmap-anydpi-v26'
    any_dir.mkdir(exist_ok=True)
    xml = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>\n'
        '</adaptive-icon>\n'
    )
    (any_dir / 'ic_launcher.xml').write_text(xml)
    (any_dir / 'ic_launcher_round.xml').write_text(xml)


def is_magenta_corner(im: Image.Image) -> bool:
    """¿Las cuatro esquinas son magenta (fondo para recortar)?"""
    w, h = im.size
    for x, y in [(2, 2), (w - 3, 2), (2, h - 3), (w - 3, h - 3)]:
        r, g, b = im.getpixel((x, y))
        if min(r, b) - g < M_FULL_BG:
            return False
    return True


def main():
    src = Path(sys.argv[1] if len(sys.argv) > 1 else 'assets/art/source')
    out = Path(sys.argv[2] if len(sys.argv) > 2 else 'assets/art')
    out.mkdir(parents=True, exist_ok=True)
    # Logos ya transparentes (logo_*.png): se recortan al contenido y se reducen.
    for f in sorted(src.glob('*.png')):
        if not f.stem.lower().startswith('logo_'):
            continue
        im = Image.open(f).convert('RGBA')
        bbox = im.getchannel('A').point(lambda v: 255 if v > 8 else 0).getbbox()
        if bbox:
            im = im.crop(bbox)
        im.thumbnail((768, 768), Image.LANCZOS)
        im.save(out / f'{f.stem.lower()}.png', optimize=True)
        print('ok:', f.name)
    for f in sorted([*src.glob('*.jpg'), *src.glob('*.webp')]):
        name = f.stem
        im = Image.open(f).convert('RGB')
        if name == 'app_icon':
            icon = fill_corners(im).resize((512, 512), Image.LANCZOS)
            icon.save(out / f'{name}.png', optimize=True)
            write_launcher_icons(icon, Path('android/app/src/main/res'))
            write_adaptive_icons(icon, Path('android/app/src/main/res'))
        elif name.startswith('store_'):
            print('omitido (gráfico de tienda):', f.name)
            continue
        elif name.startswith(('mascota_', 'anim_')):
            a, c = key_image(np.asarray(im).astype(np.float32))
            to_rgba(a, c).resize((512, 512), Image.LANCZOS).save(out / f'{name}.png', optimize=True)
        elif name.startswith('ui_'):
            a, c = key_image(np.asarray(im).astype(np.float32), holes=True)
            crop_square(to_rgba(a, c)).resize((256, 256), Image.LANCZOS).save(out / f'{name}.png', optimize=True)
        elif name.startswith(('biz_', 'mgr_', 'shop_')):
            a, c = key_image(np.asarray(im).astype(np.float32))
            crop_square(to_rgba(a, c), pad=0.04).resize((384, 384), Image.LANCZOS).save(out / f'{name}.png', optimize=True)
        elif name.startswith('icon_'):
            a, c = key_image(np.asarray(im).astype(np.float32))
            crop_square(to_rgba(a, c)).resize((256, 256), Image.LANCZOS).save(out / f'{name}.png', optimize=True)
        elif name.startswith('bg_'):
            if is_magenta_corner(im):
                a, c = key_image(np.asarray(im).astype(np.float32), drop_edge=False)
                to_rgba(a, c).save(out / f'{name}.png', optimize=True)
            else:
                im.save(out / f'{name}.jpg', quality=88, optimize=True)
        else:
            print('omitido:', f.name)
            continue
        print('ok:', f.name)


if __name__ == '__main__':
    main()
