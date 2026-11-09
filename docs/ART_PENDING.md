# Arte pendiente

Aquí solo está **lo que falta**. Lo ya entregado se quitó para no hacer ruido. Los originales van en `assets/art/source/` como JPG (imágenes) y `tool/process_art.py` los recorta a PNG. Los prompts están en inglés.

## 1. Qué falta (resumen)

La mascota (reposo, salto, celebra), el Centrifugado, los tres sprites de la mascota (idle, celebra, salto) y las tres cutscenes ya están en el juego. Lo que queda es opcional:

| # | Qué | Tipo | Dónde se usa | Prioridad |
| --- | --- | --- | --- | --- |
| 1 | Sprites de los managers o de los negocios | AutoSprite | Mejoras y pantalla de Negocios | Baja |
| 2 | Retoques de lo entregado | Regenerar | Ver sección 6 | Baja |
| 3 | Fondos de las tarjetas **09 Tren** y **10 Portal** (los otros 8 ya están) | Imagen (sin magenta) | Panel izquierdo de la tarjeta en Negocios | Media |
| 4 | Fondos de Mejoras y Metas | Imagen (sin magenta) | Pantallas Mejoras y Metas | Media |

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

## 7. Fondos de las tarjetas de negocio: faltan el 09 y el 10

Ya están integrados los fondos 01 a 08 y la espuma de la barra inferior. Faltan dos. Cada uno es **vertical 2:3 (1024×1536)**, **opaco, sin magenta** (la imagen es el fondo completo), sin personajes ni texto. El panel de la tarjeta mide ~112×170 dp y el negocio se dibuja encima, centrado: deja libre el centro y la mitad baja. Súbelos a `assets/art/source/` como `bg_biz_09_tren.webp` y `bg_biz_10_portal.webp` (o JPG). Mientras no estén, esas tarjetas usan su color pastel.

Cada prompt va completo (pega el bloque A de la sección 2 al inicio si el modelo cambia de estilo).

**bg_biz_09_tren**

```text
Vertical 2:3 background illustration for a mobile game card, full bleed, opaque, no magenta background. Flat 2D cute children's storybook style with a subtle knitted wool texture, soft gradient, gentle depth with 2 or 3 blurred layers, low contrast. Scene: an evening sky with an orange to pink to lavender sunset gradient, a few tiny stars near the top, a short string of small triangular bunting flags across the top edge, soft blurred clouds. In the lower third, a long thin clothesline wire running horizontally across the image like a rail, with a few tiny clothespins, and a faint hint of rooftops far away at the bottom edge. Keep the center and the middle of the image calm and mostly empty so a sprite can sit on top. No train, no characters, no sock, no text, no letters, no numbers, no frame, no vignette. Saturated but soft palette: lavender #C3A6E8, soft orange #FFB36B, pink #FF9EB5, cream #FFF4E0.
```

**bg_biz_10_portal**

```text
Vertical 2:3 background illustration for a mobile game card, full bleed, opaque, no magenta background. Flat 2D cute children's storybook style with a subtle knitted wool texture, soft gradient, gentle depth, low contrast. Scene: a magical swirling spiral glow in lavender #C3A6E8 and mint #A8E6CF, softly radiating from the center outward in wide, faint curved bands, with small sparkles, tiny stars and a few soap bubbles drifting near the edges and corners. The center is a soft glowing haze, calm and nearly empty so a sprite can sit on top. No portal frame, no door, no machine, no characters, no sock, no text, no letters, no numbers, no border, no vignette.
```

Si alguno sale con mucho detalle en el centro, agrega: `Reduce contrast by 30%, keep the center area plain.`

## 8. Fondos de pantalla de Mejoras y Metas

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
