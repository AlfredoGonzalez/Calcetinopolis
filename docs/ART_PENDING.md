# Arte pendiente

Aquí solo está **lo que falta**. Lo ya entregado se quitó para no hacer ruido. Los originales van en `assets/art/source/` como JPG (imágenes) y `tool/process_art.py` los recorta a PNG. Los prompts están en inglés.

## 1. Qué falta (resumen)

La mascota (reposo, salto, celebra), el Centrifugado, los tres sprites de la mascota (idle, celebra, salto) y las tres cutscenes ya están en el juego. Lo que queda es opcional:

| # | Qué | Tipo | Dónde se usa | Prioridad |
| --- | --- | --- | --- | --- |
| 1 | Sprites de los managers o de los negocios | AutoSprite | Mejoras y pantalla de Negocios | Baja |
| 2 | Retoques de lo entregado | Regenerar | Ver sección 6 | Baja |

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

- `anim_centrifugado_calcetin_der` mira hacia la **derecha** igual que el izquierdo (el prompt pedía que mirara a la izquierda) y no trae los rombos pedidos, solo parches cosidos. Lo volteo en código y sirve, pero si quieres los rombos, regenerarlo. También tiene un detalle en la boca que parece un aparato dental.
- `mascota_*` y `anim_centrifugado_calcetin_*` llevan un parche amarillo en la punta: es un detalle distinto al calcetín de los negocios. Si quieres un solo diseño, hay que elegir uno.

## Lo que hago yo sin arte nuevo

Siluetas de negocios bloqueados, sombras de suelo, ícono adaptativo de Android, pantalla de carga, destello al cruzar un umbral, pelusas flotando y brillo en monedas. No tienes que generar nada de eso.

## Después (v1.1)

Cosméticos (estampados, gorritos, lentes), eventos de temporada (Calcetín Fantasma, Navideños, Día del Calcetín Desparejado) y un segundo mundo (Lavandería pública).
