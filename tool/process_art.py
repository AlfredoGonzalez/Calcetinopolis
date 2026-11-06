#!/usr/bin/env python3
"""Quita el fondo magenta/blanco de los JPG de assets/art/source y deja PNG
transparentes en assets/art/.

Uso:  python3 tool/process_art.py [carpeta_fuente] [carpeta_salida]
Requiere: Pillow, numpy, scipy.

Reglas por nombre de archivo:
  biz_*, mgr_*        -> PNG 384x384 transparente, recortado al contenido
  icon_*              -> PNG 256x256 transparente, recortado al contenido
  app_icon.jpg        -> PNG 512x512 opaco (esquinas rellenas)
  shop_*              -> PNG 384x384 transparente, recortado al contenido
  mascota_*, anim_*   -> PNG 512x512 transparente, SIN recorte (las poses y los cuadros
                         deben conservar el mismo encuadre y escala entre sí)
  ui_*                -> PNG 256x256 transparente, recortado al contenido
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
MIN_THICKNESS = 4        # líneas finas sueltas (bordes JPEG, arcos del mosaico) se descartan
EDGE_PX = 4              # componentes pegados al borde de la imagen se descartan (restos del fondo)


def key_image(rgb: np.ndarray, drop_edge=True):
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
    for f in sorted(src.glob('*.jpg')):
        name = f.stem
        im = Image.open(f).convert('RGB')
        if name == 'app_icon':
            icon = fill_corners(im).resize((512, 512), Image.LANCZOS)
            icon.save(out / f'{name}.png', optimize=True)
            write_launcher_icons(icon, Path('android/app/src/main/res'))
        elif name.startswith('store_'):
            print('omitido (gráfico de tienda):', f.name)
            continue
        elif name.startswith(('mascota_', 'anim_')):
            a, c = key_image(np.asarray(im).astype(np.float32))
            to_rgba(a, c).resize((512, 512), Image.LANCZOS).save(out / f'{name}.png', optimize=True)
        elif name.startswith('ui_'):
            a, c = key_image(np.asarray(im).astype(np.float32))
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
