# Arte pendiente

Estado del arte frente a `docs/ART_STYLE.md`. Los originales van en `assets/art/source/` como JPG; `tool/process_art.py` quita el fondo y genera los PNG.

## Cómo generar para que el recorte salga limpio

- 1024×1024 (los íconos de interfaz también), un solo objeto, centrado, con ~10% de margen.
- **Fondo magenta liso #FF00FF**, sin degradado, sin esquinas redondeadas, sin marco ni mosaico, sin sombra de suelo.
- Sin texto. Mismo calcetín base de referencia en cada prompt.
- Nombre con el prefijo de la tabla (`icon_`, `shop_`, `anim_`...).

## Ya entregado y en uso

Ícono de la app, 10 negocios (`biz_*`), 10 managers (`mgr_*`), Pelusitas, Hilvanes, Pareja Reunida, Botones Dorados, fondos (cuarto de lavado, Tienda, pelusas flotando), todos los íconos de interfaz (pestañas, ajustes, regalo, boost, reloj, anuncio, comprar, manager, notificación), los productos de la Tienda (`shop_*`), las 4 mejoras de Hilvanes (`icon_mejora_*`) y la flecha de hilo del tutorial.

## Pendiente: imágenes

Son las que ya tienen una pantalla esperándolas. Sin ellas el juego funciona; solo se ve más simple.

| Archivo | Qué es | Dónde se usa | Qué hay hoy en su lugar |
| --- | --- | --- | --- |
| `anim_centrifugado_lavadora` | Lavadora de frente con espiral lavanda | Animación de Centrifugado (ver abajo) | Un ícono de lavadora de Material girando |
| `anim_centrifugado_calcetin_izq` y `_der` | Los dos calcetines que se reencuentran | Animación de Centrifugado | Dos emojis 🧦 |
| `anim_centrifugado_corazon` | Corazón lavanda | Animación de Centrifugado | Un emoji 💜 |
| `mascota_reposo`, `mascota_salto`, `mascota_celebra` | El calcetín protagonista en 3 poses | Tutorial, Metas, Centrifugado, Tienda y bienvenida offline (ver abajo) | Nada: hoy el personaje solo aparece dentro de los negocios |

## Animaciones: dónde se usan y por qué

La mayoría **se animan en código a partir de imágenes estáticas**, con estiramiento y encogimiento, giros, rebotes y fundidos. La hoja de estilo ya lo recomienda porque el calcetín no tiene extremidades. Solo hace falta arte nuevo donde el dibujo tiene que cambiar (una pose distinta, ojos cerrados).

| Animación | Dónde se ve | Por qué importa | Qué necesita | Prioridad |
| --- | --- | --- | --- | --- |
| **Centrifugado** | Al confirmar el reinicio, un diálogo de 3.5 s (se salta tocando): la lavadora gira, los dos calcetines entran desde los lados, se juntan, aparece el corazón y sube el multiplicador | Es **el momento emotivo del juego** (etapa 6 del recorrido): cada reinicio cuenta la historia de dos calcetines que se encuentran. Además es lo que hace que reiniciar no se sienta como perder progreso | Las 4 piezas `anim_centrifugado_*`. Yo las animo en código, sin cuadros | Alta |
| **Mascota** | Tutorial (guía los 3 pasos y salta al comprar); Metas (celebra al reclamar); resultado del Centrifugado; Tienda tras una compra; ventana de bienvenida offline | Da personalidad y una cara a la recompensa ("sorpresa agradable"). Hoy las pantallas son solo tarjetas | Las 3 poses `mascota_*`. Las transiciones (reposo → salto → celebra) las hago en código | Alta |
| **Negocios "trabajando"** | Tarjetas de la pantalla Negocios, mientras el ciclo corre o el negocio tiene manager | Es la pantalla donde se pasa más tiempo; ver movimiento comunica "mi negocio está produciendo". Hoy solo se mueve la barra | **Nada nuevo para empezar**: un rebote o respiración suave del ícono actual. Cuadros propios (4 a 8 por negocio) solo si quieres movimiento real, como el calcetín asomándose | Media |
| **Managers (parpadeo y saludo)** | Mejoras → Managers (el retrato de cada uno) y un saludo al contratarlo | Personalidad de los 10 managers, que son parte del humor del juego. Contratar un manager es una compra grande y merece su momento | Un saludo o rebote al contratar sale **del retrato actual**. Parpadear requiere una segunda imagen por manager con los ojos cerrados (10 más), o hacerlo con Rive | Baja |
| **Cruzar un umbral** | Tarjeta de negocio al llegar a 25, 50, 100... unidades | Los umbrales son lo que más compras genera (spec 4.4); el jugador debe sentir el premio ("el doble de rápido") | **Nada**: destello y rebote de la tarjeta en código, con los destellos que ya tienen tus íconos | Media |
| **Pelusas flotando** | Fondo de Negocios, con efecto de profundidad suave | Da vida a la pantalla sin distraer. `bg_pelusas_flotando` ya está entregado | **Nada**: capa que sube lentamente en código | Baja |
| **Brillo en monedas** | Pelusitas y Botones Dorados de la barra superior y la Tienda al ganar | Refuerza "gané algo" cuando suben los números | **Nada**: destello en código | Baja |
| **Cosméticos** (v1.1) | Estampados, gorritos y lentes en los calcetines; animaciones de Centrifugado distintas | Es lo que mejor vende en un juego tierno y no afecta el balance | Arte nuevo grande, después | Después |

**Orden que propongo:** (1) Centrifugado y mascota, que son las dos que necesitan tus imágenes; (2) mientras tanto, lo que no necesita arte (umbrales, pelusas, brillos, rebote de negocios); (3) cuadros propios o Rive solo si después del paso 2 quieres más movimiento. Si prefieres Rive o Spine para los managers y la mascota, dímelo antes de generar cuadros, porque cambia el formato.

## Entregado pero todavía sin usar en pantalla

| Archivo | Dónde lo pondría |
| --- | --- |
| `icon_ui_comprar` | Botón de compra de las tarjetas de negocio |
| `icon_ui_manager` | Botón "Manager" de las tarjetas |
| `icon_ui_notificacion` | Ajustes y la petición de permiso de notificaciones (F8) |
| `bg_pelusas_flotando` | Capa animada de fondo (ver arriba) |

## Observaciones sobre lo entregado

- `store_feature_1024x500` llegó en **1024×765**. Google Play exige exactamente 1024×500: hay que recortarlo (se puede quitar arriba y abajo sin tocar a los personajes) o regenerarlo en formato panorámico. Se queda en `assets/art/source/` y no entra a la app.
- Las 14 imágenes de la última tanda llegaron con **fondo blanco** y una **sombra de suelo beige**, no magenta. El script las recorta bien y quita la sombra, salvo en `shop_starter` y `shop_botones_4` (sombra café oscura) donde queda un resto. Si quieres que salgan limpias, repite esas dos con "sin sombra de suelo, fondo magenta plano".
- El centro de la flecha de hilo era blanco; el script lo vuelve transparente.
- `icon_ui_negocios` vino en 1024×559. Funciona recortado, pero conviene regenerarlo cuadrado.
- `biz_10_portal` trae una placa gris de esquinas redondeadas que los demás negocios no tienen. Si quieres coherencia, regénéralo sin placa.
- `mgr_10_gran_centrifugadora`: el brillo de la corona se pierde un poco al quitar el fondo.

## Prompts

Cada prompt se arma con tres bloques: **A (estilo) + la línea `Asset:` + C (fondo)**. Los íconos y el protagonista llevan además el bloque **B (calcetín)**. Están en español porque la plantilla de `ART_STYLE.md` también lo está.

**Imágenes de referencia que conviene adjuntar en cada generación:**

- Para el calcetín: `biz_01_tendedero.jpg` (o `icon_pareja_reunida.jpg`).
- Para los íconos: `icon_ui_regalo.jpg` o `icon_ui_metas.jpg`, que ya tienen el grosor de contorno y la textura de lana que buscas.
- Si el modelo cambia de estilo a mitad de la tanda, vuelve a adjuntar la referencia y repite el bloque A completo.

### Bloque A: estilo (pegar al inicio de todos)

```text
Ilustración 2D plana, estilo tierno tipo cuento infantil, con textura sutil de tejido de lana. Contorno café cálido (#5A3E36), grueso y suave, nunca negro. Sombreado plano de un solo tono, luz desde arriba a la izquierda. Paleta limitada: crema #FFF4E0, rosa #FF9EB5, azul #7EC8E3, menta #A8E6CF, amarillo mantequilla #FFE29A, naranja suave #FFB36B, lavanda #C3A6E8, rojo tomate #E85D5D, dorado #F2B93B. Mismo estilo que la imagen de referencia adjunta. Silueta muy legible a tamaño pequeño.
```

### Bloque B: el calcetín (para todo lo que lleve al personaje)

```text
Personaje: un calcetín con puño arriba (azul #7EC8E3), cuerpo crema, talón y punta redondeados, ojos grandes y separados con brillo, boca pequeña, mejillas rosadas y un hilo suelto en la punta. Sin piernas.
```

### Bloque C: fondo (pegar al final de todos)

```text
Un solo objeto, centrado, visto de frente, ocupando alrededor del 80% del cuadro con margen parejo. Fondo magenta liso #FF00FF, sin degradado, sin marco, sin esquinas redondeadas, sin sombra de suelo, sin reflejos ni brillos sobre el fondo. Sin texto, sin letras, sin números, sin marcas de agua, sin personajes de otras marcas. Formato cuadrado 1024×1024.
```

### Prioridad alta

**`icon_hilvanes`**: moneda gastable de la tienda de Centrifugado.

```text
Asset: ícono de moneda de juego, un carrete de hilo crema con hilo azul #7EC8E3 enrollado y una aguja de coser plateada clavada en diagonal; un trozo de hilo cuelga y forma un pequeño rizo; dos destellos blancos de cuatro puntas. Debe verse distinto de una pelusa gris, de un botón dorado y de dos calcetines. Estilo de ícono, objeto único.
```

**`shop_vip`**: Pase VIP.

```text
Asset: una corona pequeña tejida en lana dorada #F2B93B con tres puntas redondeadas, un botón dorado en el centro y una gema pequeña lavanda #C3A6E8 en cada punta; destellos blancos de cuatro puntas alrededor. Aspecto lujoso pero tierno. Estilo de ícono.
```

**`shop_starter`**: Paquete de inicio.

```text
Asset: una caja de regalo crema con lazo rosa #FF9EB5 y la tapa entreabierta; del interior asoma la punta de un calcetín con puño azul y destellos amarillos. Estilo de ícono.
```

**`shop_mult`**: Multiplicador permanente.

```text
Asset: una estrella grande de cinco puntas tejida en lana dorada #F2B93B con el contorno café; en el centro, un calcetín pequeño con puño azul sonriendo; tres destellos blancos de cuatro puntas alrededor. Transmite "poder permanente". Sin números ni letras. Estilo de ícono.
```

**`shop_botones_1`** a **`shop_botones_4`**: la misma moneda en cuatro tamaños de cantidad. Genera los cuatro seguidos, con la misma imagen de `icon_botones_dorados.jpg` adjunta como referencia del botón.

```text
Asset (1): tres botones dorados #F2B93B de cuatro agujeros con hilo cruzado, apilados en un montoncito pequeño. Estilo de ícono.
```

```text
Asset (2): una bolsita de tela crema cerrada con un cordón azul, de la que se asoman seis botones dorados #F2B93B. Estilo de ícono.
```

```text
Asset (3): un frasco de vidrio redondo con tapa de corcho, lleno hasta arriba de botones dorados #F2B93B; el vidrio es translúcido con un reflejo blanco suave. Estilo de ícono.
```

```text
Asset (4): un pequeño cofre de madera café con bordes dorados, abierto, desbordado de botones dorados #F2B93B que caen por el frente; destellos blancos de cuatro puntas. Estilo de ícono.
```

**`icon_ui_anuncio`**: "ver un anuncio".

```text
Asset: un botón redondo grande de color lavanda #C3A6E8 con un triángulo de "reproducir" crema en el centro, borde grueso café y brillo suave arriba a la izquierda; un destello blanco pequeño. Debe verse como el resto de íconos de interfaz (mismo grosor de contorno). Sin texto.
```

**`mascota_reposo`**, **`mascota_salto`**, **`mascota_celebra`**: el calcetín protagonista. Adjunta `biz_01_tendedero.jpg` y pide el mismo personaje en las tres poses. Usa bloques A + B + C.

```text
Asset (reposo): el calcetín protagonista de pie, derecho, con una sonrisa tranquila y los ojos abiertos; el hilo suelto de la punta cuelga recto. Cuerpo completo, vista de frente.
```

```text
Asset (salto): el mismo calcetín saltando, estirado hacia arriba (estiramiento y encogimiento exagerado), ojos muy abiertos y boca en forma de "o" de alegría; el hilo suelto ondea hacia abajo; unas líneas de movimiento suaves debajo. Cuerpo completo.
```

```text
Asset (celebra): el mismo calcetín con dos manitas ovaladas pequeñas levantadas, ojos cerrados en arcos felices, boca abierta sonriendo y mejillas rosadas más marcadas; confeti pequeño de colores de la paleta flotando alrededor. Cuerpo completo.
```

### Prioridad media

**Animación de Centrifugado**: cuatro imágenes sueltas que yo anímo en el juego (giro, encuentro y corazón). Usa bloques A + C.

```text
Asset (anim_centrifugado_lavadora): una lavadora de carga frontal vista de frente, cuerpo crema, perilla naranja, puerta redonda grande con cristal azul claro translúcido y, dentro, una espiral lavanda #C3A6E8 que sugiere el giro del tambor. Sin calcetines dentro.
```

```text
Asset (anim_centrifugado_calcetin_izq): un calcetín solo, de perfil mirando hacia la derecha, con puño azul, parche circular amarillo en la punta, ojos grandes con brillo y una expresión de esperanza. Cuerpo completo.
```

```text
Asset (anim_centrifugado_calcetin_der): el calcetín pareja del anterior, de perfil mirando hacia la izquierda, mismo puño azul pero con rombos azules en el cuerpo, ojos grandes con brillo y expresión de alegría. Cuerpo completo.
```

```text
Asset (anim_centrifugado_corazon): un corazón tejido en lana lavanda #C3A6E8 con contorno café y dos destellos blancos de cuatro puntas. Estilo de ícono.
```

**`ui_hilo_flecha`**: flecha del tutorial.

```text
Asset: una flecha curva hecha de un hilo azul #7EC8E3 grueso que se enrosca una vez y termina en una punta de flecha triangular; en el otro extremo, un nudo pequeño. Contorno café suave. Debe apuntar hacia la derecha y abajo. Sin texto.
```

**`icon_mejora_*`**: las cuatro mejoras de la tienda de Hilvanes. Estilo de ícono, con la misma base A + C.

```text
Asset (icon_mejora_detergente): una botella de detergente azul claro con tapa blanca y una etiqueta con una burbuja; tres burbujas translúcidas flotan alrededor; un destello blanco de cuatro puntas.
```

```text
Asset (icon_mejora_suerte): un calcetín pequeño con puño azul y ojos sonrientes sosteniendo un trébol verde menta de cuatro hojas; destellos blancos de cuatro puntas.
```

```text
Asset (icon_mejora_ayudas): una pinza de ropa de madera con una carita sonriente, un moño rosa y una banda azul de ayudante; sosteniendo un calcetín pequeño colgado.
```

```text
Asset (icon_mejora_cesto): un cesto de ropa de mimbre naranja, grande, con calcetines asomándose y cuatro flechas pequeñas color menta que apuntan hacia afuera desde las esquinas para sugerir "más capacidad".
```

**`bg_tienda`** (opcional). Este es un **fondo de pantalla**, no un objeto: no uses el bloque C. Deja el fondo con detalle y sin magenta.

```text
Ilustración 2D plana, estilo tierno tipo cuento infantil con textura sutil de tejido de lana, en la paleta del juego (crema #FFF4E0, azul #7EC8E3, menta #A8E6CF, amarillo mantequilla #FFE29A). Interior vacío de una tiendita de calcetines vista de frente: mostrador de madera clara, estantes con calcetines doblados de colores a los lados, una ventana redonda con luz cálida, un tendedero con banderines de tela arriba. Composición vertical 9:16, con el centro despejado para poner tarjetas encima, colores suaves y poco contraste. Sin personajes, sin texto, sin carteles con letras.
```

**`store_feature_1024x500`** (Google Play). El texto se agrega después en una herramienta de diseño.

```text
Ilustración 2D plana, estilo tierno tipo cuento infantil con textura sutil de tejido de lana. Panorámica horizontal 1024×500: a la izquierda una lavadora crema que gira con una espiral lavanda; a la derecha, dos calcetines (uno con puño azul y parche, otro con puño azul y rombos) corriendo uno hacia el otro con los brazos abiertos; un corazón tejido lavanda entre ambos; pelusas y destellos flotando. Fondo suave menta #A8E6CF con degradado ligero. Deja libre el tercio superior izquierdo para poner el título después. Sin texto ni letras.
```

### Consejos para que salgan consistentes

- Genera **una tanda por tipo** (los 4 `shop_botones`, las 3 poses, los 4 `icon_mejora`), no uno por uno, para que el estilo se mantenga.
- Si el modelo agrega sombra de suelo o un marco redondeado, repite con "sin sombra de suelo, sin esquinas redondeadas, fondo magenta plano hasta los bordes".
- Si el magenta sale con degradado, no hace falta repetir: el script lo tolera, pero un fondo plano da el recorte más limpio.
- Si algún texto o número se cuela en la imagen, regénerala: no se puede quitar después sin tocar el arte.
- Nombra el archivo exactamente como en la tabla y súbelo a `assets/art/source/` como JPG.

## Lo puedo hacer yo desde lo que ya hay (no hace falta que lo generes)

- Siluetas de negocios bloqueados (a partir de los PNG de `biz_*`).
- Sombras de suelo (se dibujan en el juego).
- Ícono adaptativo de Android (calcetín sobre transparente + fondo menta), recortando el `app_icon`.
- Pantalla de carga (con el ícono sobre el color menta).

## Después (v1.1)

- Cosméticos: estampados, gorritos, lentes, fondos de cuarto y animaciones de Centrifugado alternativas.
- Eventos de temporada: Calcetín Fantasma (Halloween), Calcetines Navideños, Día del Calcetín Desparejado.
- Segundo mundo: fondo y 10 negocios nuevos (Lavandería pública).
