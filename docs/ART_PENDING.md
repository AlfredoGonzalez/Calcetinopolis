# Arte pendiente

Aquí solo está **lo que falta**. Lo ya entregado se quitó para no hacer ruido. Los originales van en `assets/art/source/` como JPG (imágenes) y `tool/process_art.py` los recorta a PNG. Los prompts están en inglés.

## 1. Qué falta (resumen)

La mascota (reposo, salto, celebra), el Centrifugado y los tres sprites de la mascota (idle, celebra, salto) ya están en el juego. Lo que queda es opcional:

| # | Qué | Tipo | Dónde se usa | Prioridad |
| --- | --- | --- | --- | --- |
| 1 | Cutscenes (intro, primer reencuentro, bienvenida) | AutoSprite | Primera vez que abres el juego, primer Centrifugado, volver tras mucho tiempo | Media, opcional |
| 2 | Sprites de los managers o de los negocios | AutoSprite | Mejoras y pantalla de Negocios | Baja |
| 3 | Retoques de lo entregado | Regenerar | Ver sección 7 | Baja |

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

## 6. Cutscenes en AutoSprite (punto 4, opcional)

Si las haces, las integro como escenas cortas (se pueden saltar con un toque). Son tres, ordenadas por utilidad:

| Cutscene | Cuándo sale | Duración | Para qué sirve |
| --- | --- | --- | --- |
| **Intro: "El calcetín que se quedó solo"** | Primera vez que abres el juego | 8 a 12 s | Cuenta la historia en una imagen: el calcetín pierde a su pareja en la lavadora y nace Calcetinópolis. Da el "por qué" antes del tutorial |
| **Primer reencuentro** | El primer Centrifugado (tu primera Pareja) | 6 a 10 s | Es el momento más emotivo y solo ocurre una vez; hace que reiniciar se sienta como un premio y no como perder progreso |
| **Bienvenida tras mucho tiempo** | Volver después de 4 h o más fuera | 4 a 6 s | La mascota recibe con las pelusas acumuladas; hace la recompensa offline más cálida |

Prompts (inglés):

```text
Cutscene 1 (intro): Flat 2D cute children's storybook style with a subtle wool texture, same character and palette as the reference. A blue-cuffed sock and its matching partner (blue diamonds on the body) tumble together inside a washing machine drum; the partner sock is suddenly swept away through a small hole and disappears; the first sock is left alone, looks around with big sad eyes, then spots a tiny glowing lint puff and a sign of hope. Soft transitions, 3 to 4 short shots, no text.
```

```text
Cutscene 2 (first reunion): Same style and characters. The lonely sock walks through a lavender spinning washing machine; from the other side its diamond-patterned partner appears; they see each other, run toward each other, hug, and a knitted lavender heart pops above them with white sparkles and confetti. Ends on both socks smiling side by side. 3 to 4 short shots, no text.
```

```text
Cutscene 3 (welcome back): Same style. The protagonist sock sits happily next to a big pile of gray lint puffs and golden buttons under a clothesline, waves with one small oval hand, then hops joyfully. 2 short shots, no text.
```

Si el generador permite imágenes de arranque y de cierre, usa como primer cuadro `mascota_reposo` y como último `mascota_celebra`.

## 7. Retoques de lo entregado (opcionales)

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
