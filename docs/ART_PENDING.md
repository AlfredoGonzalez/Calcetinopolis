# Arte pendiente

Aquí solo está **lo que falta**. Lo ya entregado se quitó para no hacer ruido. Los originales van en `assets/art/source/` como JPG (imágenes) y `tool/process_art.py` los recorta a PNG. Los prompts están en inglés.

## 1. Qué falta (resumen)

| # | Qué | Tipo | Dónde se usa | Prioridad |
| --- | --- | --- | --- | --- |
| 1 | `mascota_reposo`, `mascota_salto`, `mascota_celebra` | 3 imágenes | Tutorial, Metas, Tienda, bienvenida offline, resultado del Centrifugado | Alta |
| 2 | `anim_centrifugado_lavadora`, `_calcetin_izq`, `_calcetin_der`, `_corazon` | 4 imágenes | Animación del reinicio (Centrifugado) | Alta |
| 3 | Animación de la mascota (idle, salto, celebra) | Sprites (AutoSprite) | Los mismos lugares que la mascota | Media, opcional |
| 4 | Cutscenes (intro, primer reencuentro, bienvenida) | AutoSprite | Primera vez que abres el juego, primer Centrifugado, volver tras mucho tiempo | Media, opcional |
| 5 | Retoques de lo entregado | Regenerar | Ver sección 5 | Baja |

**Orden recomendado:** primero el punto 1 y 2 (son siete imágenes; con eso ya puedo dejar listo el Centrifugado y la mascota). Los puntos 3 y 4 son un extra: el juego funciona y se ve bien sin ellos.

## 2. Cómo generar las imágenes (puntos 1 y 2)

- 1024×1024, un solo objeto, centrado, ~10% de margen.
- **Fondo magenta liso #FF00FF**, sin degradado, sin marco, sin esquinas redondeadas, sin sombra de suelo.
- Sin texto ni números.
- Adjunta de referencia `assets/art/source/biz_01_tendedero.jpg` (calcetín base) en cada generación. Si el modelo cambia de estilo, vuelve a adjuntarla y repite el bloque A.
- Genera cada tanda seguida (las 3 poses juntas, las 4 piezas juntas) para que el estilo no cambie.
- Nombra el archivo exactamente como en la tabla y súbelo a `assets/art/source/` como JPG.

Cada prompt = **A (estilo) + `Asset:` + C (fondo)**. La mascota lleva además **B (calcetín)**.

### Bloque A: estilo (al inicio de todos)

```text
Flat 2D illustration, cute children's storybook style, with a subtle knitted wool texture. Warm brown outline (#5A3E36), thick and soft, never black. Flat single-tone shading, light coming from the top left. Limited palette: cream #FFF4E0, pink #FF9EB5, blue #7EC8E3, mint #A8E6CF, butter yellow #FFE29A, soft orange #FFB36B, lavender #C3A6E8, tomato red #E85D5D, gold #F2B93B. Same style as the attached reference image. Very readable silhouette at small sizes.
```

### Bloque B: el calcetín (solo mascota)

```text
Character: a sock with a blue (#7EC8E3) cuff on top, cream body, rounded heel and toe, big wide-set eyes with a highlight, a small mouth, pink cheeks and one loose thread at the toe. No legs.
```

### Bloque C: fondo (al final de todos)

```text
A single object, centered, front view, filling about 80% of the frame with even margins. Solid flat magenta background #FF00FF, no gradient, no frame, no rounded corners, no ground shadow, no reflections or glow on the background. No text, no letters, no numbers, no watermarks, no characters from other brands. Square format 1024x1024.
```

## 3. Prompts: mascota (punto 1)

Usa A + B + C. Pide el mismo personaje en las tres poses, con la referencia adjunta.

**`mascota_reposo`**

```text
Asset: the protagonist sock standing upright, relaxed, with a calm smile and eyes open; the loose thread at the toe hangs straight down. Full body, front view.
```

**`mascota_salto`**

```text
Asset: the same sock jumping, stretched upward (exaggerated squash and stretch), eyes wide open and mouth in a happy "o" shape; the loose thread flutters downward; a few soft motion lines below. Full body.
```

**`mascota_celebra`**

```text
Asset: the same sock with two small oval hands raised, eyes closed in happy arcs, mouth open in a big smile and stronger pink cheeks; small confetti in the palette colors floating around. Full body.
```

## 4. Prompts: Centrifugado (punto 2)

Usa A + C (sin B; los calcetines ya describen su diseño). Yo los animo en código: giro, encuentro y corazón.

**`anim_centrifugado_lavadora`**

```text
Asset: a front-loading washing machine seen from the front, cream body, orange knob, a large round door with translucent light-blue glass and, inside, a lavender #C3A6E8 spiral suggesting the spinning drum. No socks inside.
```

**`anim_centrifugado_calcetin_izq`**

```text
Asset: a single sock in side profile facing right, blue cuff, a circular yellow patch on the toe, big eyes with a highlight and a hopeful expression. Full body.
```

**`anim_centrifugado_calcetin_der`**

```text
Asset: the matching partner sock of the previous one, in side profile facing left, same blue cuff but with blue diamonds on the body, big eyes with a highlight and a joyful expression. Full body.
```

**`anim_centrifugado_corazon`**

```text
Asset: a knitted wool heart in lavender #C3A6E8 with a brown outline and two white four-pointed sparkles. Icon style.
```

## 5. Animación con sprites en AutoSprite (punto 3, opcional)

**Qué reemplaza:** hoy muevo la mascota en código (estirar, rebotar, girar) a partir de una sola imagen. Eso ya se ve bien. Con sprites tendríamos movimiento "dibujado" (parpadeo, el hilo ondeando, brazos que aparecen), que se nota más.

**Cómo:** primero genera las 3 imágenes de la mascota (sección 3) y usa `mascota_reposo` como personaje base en AutoSprite. Pide estas tres animaciones:

| Animación | Cuadros | Bucle | Dónde |
| --- | --- | --- | --- |
| `spr_mascota_idle` | 6 a 8 | Sí | Tutorial y pantallas de espera: respira, parpadea, el hilo se mece |
| `spr_mascota_salto` | 8 a 10 | No | Al comprar y al terminar un paso del tutorial |
| `spr_mascota_celebra` | 8 a 12 | No | Al reclamar metas y al terminar el Centrifugado |

Prompts para el generador de animación (inglés):

```text
Animation (idle loop): the sock character stands in place and breathes gently (a slight squash and stretch), blinks once, and the loose thread at the toe sways side to side. Seamless loop, 8 frames, same flat storybook style and proportions as the reference, character stays centered on the same spot in every frame.
```

```text
Animation (jump): the sock character crouches (squash), launches upward (stretch) with eyes wide and a happy "o" mouth, reaches the top, and lands with a small squash before returning to rest. The loose thread trails behind. 10 frames, same style as the reference, same foot position on the ground at start and end.
```

```text
Animation (celebrate): the sock character raises two small oval hands, bounces twice with closed happy eyes and a big open smile, with small confetti falling around it. 12 frames, same style as the reference.
```

**Qué necesito de ti al exportar:**

- PNG con **fondo transparente** (si no se puede, fondo magenta liso #FF00FF y yo lo quito).
- De preferencia una **hoja de sprites** (todas las celdas del mismo tamaño en una fila o cuadrícula), o los cuadros sueltos numerados (`spr_mascota_idle_01.png`...).
- Dime los **cuadros por segundo** y el tamaño de cada cuadro. No conozco las opciones exactas de AutoSprite, así que dime qué formato sí te da y me adapto.
- Súbelos a `assets/art/source/`.

**Opcionales de menor prioridad (solo si quieres más):**

```text
Animation (washer spin loop): a front-loading washing machine with a lavender spiral inside the glass door; the spiral rotates continuously and the machine shakes very slightly. Seamless loop, 8 frames, same style as the reference.
```

```text
Animation (working loop): the sock character peeks out of its home object (basket, clothesline, etc.) and ducks back in, smiling. Seamless loop, 6 frames.
```

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

## Lo que hago yo sin arte nuevo

Siluetas de negocios bloqueados, sombras de suelo, ícono adaptativo de Android, pantalla de carga, destello al cruzar un umbral, pelusas flotando y brillo en monedas. No tienes que generar nada de eso.

## Después (v1.1)

Cosméticos (estampados, gorritos, lentes), eventos de temporada (Calcetín Fantasma, Navideños, Día del Calcetín Desparejado) y un segundo mundo (Lavandería pública).
