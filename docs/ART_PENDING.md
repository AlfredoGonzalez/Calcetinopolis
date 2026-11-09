# Arte pendiente

Aquí solo está **lo que falta**. Lo ya entregado se quitó para no hacer ruido. Los originales van en `assets/art/source/` como JPG (imágenes) y `tool/process_art.py` los recorta a PNG. Los prompts están en inglés.

## 1. Qué falta (resumen)

La mascota (reposo, salto, celebra), el Centrifugado, los tres sprites de la mascota (idle, celebra, salto) y las tres cutscenes ya están en el juego. Lo que queda es opcional:

| # | Qué | Tipo | Dónde se usa | Prioridad |
| --- | --- | --- | --- | --- |
| 1 | Sprites de los managers o de los negocios | AutoSprite | Mejoras y pantalla de Negocios | Baja |
| 2 | Retoques de lo entregado | Regenerar | Ver sección 6 | Baja |
| 3 | Fondos de las 10 tarjetas de negocio | Imagen (sin magenta) | Panel izquierdo de cada tarjeta en Negocios | Media |
| 4 | Fondo de la barra inferior (opcional) | Imagen | Hoy es espuma y burbujas dibujadas en código | Baja |
| 5 | Fondos de Mejoras y Metas | Imagen (sin magenta) | Pantallas Mejoras y Metas | Media |

Los prompts base (bloques A, B y C) siguen abajo por si regeneras algo.

## 2. Cómo generar las imágenes

- 1024×1024, un solo objeto, centrado, ~10% de margen.
- **Fondo magenta liso #FF00FF**, sin degradado, sin marco, sin esquinas redondeadas, sin sombra de suelo.
- Sin texto ni números.
- Adjunta de referencia `assets/art/source/mascota_reposo.webp` (calcetín base). Si el modelo cambia de estilo, vuelve a adjuntarla y repite el bloque A.
- Se acepta JPG o WebP. Nombra el archivo como en las tablas y súbelo a `assets/art/source/`.

### Bloque A: estilo (al inicio de todos)

```text
Flat 2D illustration, cute children's storybook style, with a subtle knitted wool texture. Warm brown outline (#5A3E36), thick and soft, never black. Flat single-tone shading, light coming from the top left. Limited palette: cream #FFF4E0, pink #FF9EB5, blue #7EC8E3, mint #A8E6CF, butter yellow #FFE29A, soft orange #FFB36B, lavender #C3A6E8, tomato red #E85D5D, gold #F2B93B. Same style as the attached reference image. Very readable silhouette at small sizes.
```

### Bloque B: el calcetín (si lleva al personaje)

```text
Character: a sock with a blue (#7EC8E3) cuff on top, cream body, rounded heel and toe, big wide-set eyes with a highlight, a small mouth, pink cheeks and one loose thread at the toe. No legs.
```

### Bloque C: fondo (al final de todos)

```text
A single object, centered, front view, filling about 80% of the frame with even margins. Solid flat magenta background #FF00FF, no gradient, no frame, no rounded corners, no ground shadow, no reflections or glow on the background. No text, no letters, no numbers, no watermarks, no characters from other brands. Square format 1024x1024.
```

## 5. Cómo generar sprites en AutoSprite (referencia)

Esto fue lo que funcionó para la mascota. Úsalo igual para cualquier otro personaje:

- **Frame inicial y final:** el mismo cuadro (la imagen de reposo), con **Loop** apagado salvo en el idle.
- **Paso 1, "Describe the pose":** cómo se ve el cuadro, quieto, con colores y detalles (parche, mejillas).
- **Paso 2, "Action":** solo el movimiento, y siempre "same design, colors and yellow patch in every frame, static camera, no turning sideways, plain white background".
- **Frame:** *Normal* para movimientos pequeños (idle); **Padded 2×** si salta, estira o hay confeti.
- **Frames:** 16 basta (25 si el movimiento es grande). **Size:** 512. **Sharpen:** Light. **Compression:** apagado.
- **Exporta** PNG transparente y súbelo a `assets/art/source/` como `spr_<nombre>.png`. Yo lo recorto, lo empaco y lo conecto.
- Si el navegador conserva una hoja vieja, el archivo se publica con la cuadrícula en el nombre (`_4x4`, `_5x5`).

## 6. Retoques de lo entregado (opcionales)

- `store_feature_1024x500` (Google Play) llegó en 1024×765; hay que **regenerarlo en panorámico 1024×500** o recortarlo. No entra a la app. Prompt:

```text
Flat 2D illustration, cute children's storybook style with a subtle knitted wool texture. Horizontal panorama 1024x500: on the left a cream washing machine with a lavender spiral inside the door; on the right two socks (one with a blue cuff and a yellow patch, the other with a blue cuff and diamonds) running toward each other with open arms; a knitted lavender heart between them; lint puffs and sparkles floating. Soft mint #A8E6CF background with a light gradient. Leave the top-left third free for a title added later. No text or letters.
```

- `shop_starter` y `shop_botones_4` conservan un resto de sombra. Regenerarlas con "no ground shadow, flat magenta background all the way to the edges".
- `icon_ui_negocios` llegó en 1024×559; conviene regenerarlo cuadrado 1024×1024 (mismo prompt, mismo estilo de ícono).
- `biz_10_portal` trae una placa gris que los demás negocios no tienen; regenerarlo con "no plaque, no background panel".
- `mgr_10_gran_centrifugadora`: el brillo de la corona se pierde un poco al quitar el fondo; regenerar con la corona sin halo luminoso sobre el fondo.

- `anim_centrifugado_calcetin_der` mira hacia la **derecha** igual que el izquierdo (el prompt pedía que mirara a la izquierda) y no trae los rombos pedidos, solo parches cosidos. Lo volteo en código y sirve. Los rombos son opcionales. Los braquets de la boca son intencionales.
- `mascota_*` y `anim_centrifugado_calcetin_*` llevan un parche amarillo en la punta: es un detalle distinto al calcetín de los negocios. Si quieres un solo diseño, hay que elegir uno.

## 7. Fondos de las tarjetas de negocio

El panel izquierdo de cada tarjeta mide ~112×170 dp (vertical). Hoy lleva un color pastel liso. Si subes `bg_biz_XX_nombre.jpg` a `assets/art/source/`, `tool/process_art.py` lo reduce a 400 px de ancho y el juego lo usa solo (sin tocar código). Si falta, queda el color pastel.

Reglas: **vertical 2:3 (1024×1536)**, **sin fondo magenta** (esta vez la imagen es el fondo completo, opaca), sin personajes, sin texto, sin el objeto del negocio (el negocio se dibuja encima, centrado). Deja libre el centro y la mitad baja. Colores más saturados que el pastel de hoy, pero suaves y con poco contraste, para que el negocio resalte. Nombres: `bg_biz_01_tendedero`, `bg_biz_02_cesto`, `bg_biz_03_sofa`, `bg_biz_04_burbujas`, `bg_biz_05_secadora`, `bg_biz_06_cajon`, `bg_biz_07_taller`, `bg_biz_08_fabrica`, `bg_biz_09_tren`, `bg_biz_10_portal`.

Pega primero el bloque A (estilo) y después el bloque base y la escena de cada negocio:

```text
Vertical 2:3 background illustration for a mobile game card, full bleed, opaque, no magenta. Flat 2D cute children's storybook style with a subtle knitted wool texture, warm brown outlines only on small details, soft vertical gradient, gentle depth with 2 or 3 blurred layers. Keep the center and the lower half mostly empty and calm so a character sprite can sit on top. No characters, no sock, no building or machine in the middle, no text, no letters, no numbers, no frame, no vignette. Palette saturated but soft.
```

Escenas (una por imagen, se agregan al bloque base):

| # | Escena |
| --- | --- |
| 01 Tendedero | Sunny laundry-yard sky: soft blue to peach gradient, tiny clouds, a far-away clothesline thread crossing the top, a few floating lint puffs and bubbles. |
| 02 Cesto | A cozy dim laundry room corner: mint wall with subtle wallpaper pattern, a warm wooden floor line at the bottom, a small window light beam, scattered tiny lint. |
| 03 Sofá | The dusty shadow under a sofa: lavender and plum dark-ish gradient, soft dust bunnies and sparkles in a thin light ray, a hint of wooden floor at the bottom. |
| 04 Burbujas | Underwater-like soap scene: aqua to mint gradient, many bubbles of different sizes in the corners and edges, light caustics, no foam in the center. |
| 05 Secadora | Warm laundromat wall: butter yellow and orange gradient, soft heat shimmer lines rising, a faint row of round tiles, little sparkles. |
| 06 Cajón | The inside of a wooden drawer seen from the front: soft cream and tan wood-grain walls, a subtle vertical divider shadow at the edges, tiny knitted heart pattern at the borders. |
| 07 Taller | Cozy sewing workshop wall: pink and cream striped wallpaper, a tiny out-of-focus shelf with thread spools at the top corners, floating threads and stitches in the air. |
| 08 Fábrica | Wool factory interior: blue-gray gradient with soft rows of tiny round windows far away, drifting colorful yarn threads, gentle steam, a floor line at the bottom. |
| 09 Tren | Evening sky with a long clothesline rail across the lower third: orange to lavender sunset gradient, tiny stars, a few bunting flags at the top. |
| 10 Portal | Magical swirling lavender and mint spiral glow radiating from the center, stars and sparkles, soft nebula of bubbles, still readable and calm in the center. |

## 8. Fondo de la barra inferior (opcional)

Hoy la barra es azul marino con espuma y burbujas dibujadas en código. Si quieres una imagen propia (una orilla de espuma o una pila de burbujas), con **fondo magenta liso** (#FF00FF) y panorámica:

```text
Horizontal strip 1024x192, a row of soap bubbles and white foam forming a wavy scalloped top edge, light blue outlines, tiny sparkles, flat 2D cute storybook style with subtle wool texture, solid flat magenta background #FF00FF, no ground shadow, no text. The bottom 40% of the strip is solid cream foam so it can blend into a dark blue bar.
```

Sube el archivo como `bg_nav_espuma.png` y avísame; hoy el borde es código y se ve bien sin esto.

## 9. Fondos de pantalla de Mejoras y Metas

Son pantallas completas, **verticales 9:16 (1080×1920)**, opacas y **sin magenta**. El juego las dibuja atenuadas (~20%) detrás de las tarjetas, así que deben ser suaves y de poco contraste, con detalle solo en los bordes y el centro limpio. Súbelas como `bg_mejoras.jpg` y `bg_metas.jpg` a `assets/art/source/`. Si faltan, se usan los fondos de Negocios y Tienda.

Pega primero el bloque A (estilo) y luego el bloque base con la escena.

Bloque base:

```text
Vertical 9:16 full-screen background illustration for a mobile game menu, opaque, full bleed, no magenta. Flat 2D cute children's storybook style with a subtle knitted wool texture, soft gradient, gentle depth with 2 or 3 blurred layers, low contrast so cards can sit on top. Keep the center and most of the image calm and mostly empty; put the details near the top corners and the bottom edge. No characters, no sock, no text, no letters, no numbers, no frame, no vignette. Saturated but soft palette.
```

**Mejoras (managers, upgrades y umbrales): el taller de ayudantes**

```text
Scene: a cozy workshop corner for the sock helpers. Warm lavender and cream gradient wall with a subtle knitted-heart wallpaper pattern. At the top corners, blurred pegboards with tiny hanging tools (needle, scissors, thread spools, measuring tape) and a small lamp glow. At the bottom edge, a wooden shelf line with a few spools of colorful yarn and small gears, out of focus. Floating tiny sparkles, thread loops and gear shapes in the air. Soft upward arrows hidden as a faint pattern, hinting at improvements. Calm empty center.
```

**Metas (logros): el cielo de festejo**

```text
Scene: a celebration sky. Soft butter yellow to pink to light blue gradient, tiny clouds, a string of triangular bunting flags and small knitted stars across the top, confetti and sparkles scattered near the corners. At the bottom edge, a few soft rounded hills or cloud puffs with a small blurred golden trophy cup and a ribbon peeking at one corner. A faint ray of light from the top center. Calm empty center.
```

Si salen con elementos muy fuertes en el centro, agrega: `Reduce contrast by 30%, keep the center area plain.`

## Lo que hago yo sin arte nuevo

Ya hechos: destello al cruzar un umbral, pelusas flotando, brillo en monedas, respiración de los negocios, siluetas de negocios bloqueados, ícono adaptativo de Android y pantalla de carga. Queda:

Sombras de suelo. No tienes que generar nada de eso.

## Después (v1.1)

Cosméticos (estampados, gorritos, lentes), eventos de temporada (Calcetín Fantasma, Navideños, Día del Calcetín Desparejado) y un segundo mundo (Lavandería pública).
