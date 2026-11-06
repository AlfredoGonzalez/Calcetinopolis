# Hoja de estilo de arte: calcetines tiernos

Extraída de la sección 11.6 de [GAME_SPEC.md](GAME_SPEC.md). Si hay conflicto, manda esta hoja para temas de arte.

Esta hoja vive en `docs/ART_STYLE.md` y se pega al inicio de cada prompt de imagen, para que los 40 y tantos assets del MVP se vean de la misma familia.

**Personaje base (el "calcetín"):**

- Cuerpo: forma de calcetín con puño arriba, talón redondeado y punta redonda. Sin piernas.
- Cara en la zona del tobillo: ojos grandes y separados, con un brillo; boca pequeña; mejillas rosadas.
- Un hilo suelto en la punta, que sirve para animar emociones.
- Manitas opcionales: dos óvalos pequeños, solo en poses de celebración.
- Cada manager usa el mismo cuerpo, con un estampado distinto en el puño y el cuerpo (tabla 9.2) y un accesorio propio.

**Estilo visual:**

- Ilustración 2D plana con una ligera textura de tejido de lana.
- Contorno suave en café cálido, nunca negro.
- Sombra plana de un solo tono; luz desde arriba a la izquierda.
- Fondo de un solo color liso para recortar fácil.
- Siluetas muy legibles a tamaño pequeño (los íconos se ven a unos 64 px en el teléfono).

**Paleta (11 colores):**

| Uso | Color | Hex |
| --- | --- | --- |
| Lana crema (base) | Crema | #FFF4E0 |
| Mejillas | Rosa | #FF9EB5 |
| Lavandería | Azul claro | #7EC8E3 |
| Fondos suaves | Menta | #A8E6CF |
| Resaltes | Amarillo mantequilla | #FFE29A |
| Calidez | Naranja suave | #FFB36B |
| Magia / prestigio | Lavanda | #C3A6E8 |
| Alertas y botones de acción | Rojo tomate | #E85D5D |
| Contorno | Café cálido | #5A3E36 |
| Pelusa | Gris cálido | #D9D4CC |
| Moneda premium (Botones Dorados) | Dorado | #F2B93B |

Los managers se distinguen por estampado y accesorio, no solo por color, para que se reconozcan también con daltonismo.

**Plantilla de prompt (se rellena por asset):**

```markdown
Ilustración 2D plana, estilo tierno tipo cuento infantil con textura sutil de tejido de lana.
Personaje: un calcetín con puño, talón redondeado, ojos grandes con brillo, mejillas rosadas, un hilo suelto en la punta. Sin piernas.
Contorno café cálido (#5A3E36), sombra plana de un solo tono, luz desde arriba a la izquierda.
Paleta limitada: crema #FFF4E0, rosa #FF9EB5, azul #7EC8E3, menta #A8E6CF, amarillo #FFE29A.
Asset: [DESCRIPCIÓN]. Estampado: [rayas | parches | lunares | ...]. Accesorio: [...].
Fondo de un solo color liso. Sin texto, sin marcas de agua, sin personajes de otras marcas.
```

**Texto en español dentro del arte:**

- Los generadores de imágenes suelen equivocarse con acentos, la "ñ" y signos como ¡ y ¿. Para que el texto se vea bonito y correcto, genera el arte **sin texto** y pon las palabras dentro del juego (Flutter/Flame) con una fuente redondeada que soporte español, por ejemplo Fredoka o Baloo 2 de Google Fonts.
- Para el logo del juego y el título de la tienda, que sí necesitan letras decoradas: genera varias opciones, elige la que tenga buena forma, y revisa letra por letra antes de usarla. Si falla, rehazlo con la fuente y añade adornos con la IA.
- Toda captura de la tienda con texto se arma en una herramienta de diseño, no en el generador de imágenes.

**Lista de assets del MVP:**

| Asset | Cantidad | Animación |
| --- | --- | --- |
| Ícono de la app (512 × 512 px, requisito de Google Play) | 1 | No |
| Calcetín protagonista | 1 | Reposo, salto al comprar, celebración |
| Íconos de negocios | 10 | Un bucle corto de "trabajando" (4 a 8 cuadros) |
| Retratos de managers | 10 | Parpadeo y saludo |
| Animación de Centrifugado (la lavadora gira y dos calcetines se encuentran) | 1 | 12 a 16 cuadros, o en Rive |
| Fondo del cuarto de lavado | 1 | Pelusas flotando (parallax simple) |
| Íconos de Pelusitas, Botones Dorados y Pareja Reunida | 3 | Brillo |
| Íconos de interfaz (compra, mejoras, ajustes, tienda) | \~12 | No |
| Gráfico de función de la ficha de Google Play (1024 × 500 px) | 1 | No |

**Pipeline recomendado:** generar una vez el calcetín base, aprobar el diseño, y producir las variantes (estampados y accesorios) con ese mismo calcetín como referencia. Para animar, usar huesos o malla en Rive/Spine sobre el mismo sprite; es más consistente que pedir cada cuadro a la IA. Limpiar y recortar en Aseprite o similar.
