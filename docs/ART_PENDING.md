# Arte pendiente

Estado del arte frente a `docs/ART_STYLE.md`. Los originales van en `assets/art/source/` como JPG; `tool/process_art.py` quita el fondo y genera los PNG.

## Cómo generar para que el recorte salga limpio

- 1024×1024 (los íconos de interfaz también), un solo objeto, centrado, con ~10% de margen.
- **Fondo magenta liso #FF00FF**, sin degradado, sin esquinas redondeadas, sin marco ni mosaico, sin sombra de suelo.
- Sin texto. Mismo calcetín base de referencia en cada prompt.
- Nombre con el prefijo de la tabla (`icon_`, `shop_`, `anim_`...).

## Ya entregado y en uso

Ícono de la app, 10 negocios (`biz_*`), 10 managers (`mgr_*`), Pelusitas, Pareja Reunida, fondo del cuarto de lavado, íconos de pestañas (negocios, mejoras, centrifugado, metas, tienda), ajustes y regalo.

## Entregado pero aún sin usar (lo conecto en F7)

`icon_botones_dorados`, `icon_ui_boost`, `icon_ui_comprar`, `icon_ui_manager`, `icon_ui_notificacion`, `icon_ui_reloj`, `bg_pelusas_flotando`.

## Pendiente: prioridad alta (lo necesita la Tienda o una pantalla ya hecha)

La Tienda ya existe y, mientras no haya `shop_*`, usa arte que ya tienes como respaldo (regalo, medalla de metas, botón dorado, flecha de mejoras). En cuanto subas un archivo con el nombre de la tabla, se usa solo, sin tocar código.

| Archivo sugerido | Qué es | Dónde se usa |
| --- | --- | --- |
| `icon_hilvanes` | Ícono de la moneda Hilvanes (un ovillo, carrete o aguja con hilo; distinto de la Pareja y de las Pelusitas) | Barra superior, tienda de Centrifugado, metas |
| `shop_vip` | Pase VIP (por ejemplo, una corona o un boleto dorado) | Tienda |
| `shop_starter` | Paquete de inicio (caja o bolsa de regalo con un calcetín) | Tienda |
| `shop_mult` | Multiplicador permanente x2 (por ejemplo, un calcetín con destellos y "x2" sin texto, o una estrella) | Tienda |
| `shop_botones_1` a `shop_botones_4` | Botones Dorados en 4 tamaños: uno, un puñito, una bolsita, un cofre | Tienda |
| `icon_ui_anuncio` | "Ver un anuncio" (triángulo de play en un botón o una pantallita) | Botones de anuncio |
| `mascota_reposo`, `mascota_salto`, `mascota_celebra` | El calcetín protagonista en 3 poses (hoy no hay hoja del protagonista; solo aparece dentro de los negocios) | Tutorial, Centrifugado, Tienda |

## Pendiente: prioridad media

| Archivo sugerido | Qué es |
| --- | --- |
| `anim_centrifugado_*` | Animación de Centrifugado: lavadora (frente), dos calcetines separados (izquierdo y derecho) y un corazón. Hoy es un ícono con emoji |
| `ui_hilo_flecha` | Flecha hecha de hilo para el tutorial |
| `icon_mejora_detergente`, `icon_mejora_suerte`, `icon_mejora_ayudas`, `icon_mejora_cesto` | Las 4 mejoras de la tienda de Hilvanes |
| `bg_tienda` (opcional) | Fondo de la Tienda |
| `store_feature_1024x500` | Gráfico de función de Google Play (1024×500). Esta sí puede llevar texto, armada en una herramienta de diseño |
| Capturas de pantalla | Para la ficha de Google Play (se arman en una herramienta de diseño, no en el generador) |

## Lo puedo hacer yo desde lo que ya hay (no hace falta que lo generes)

- Siluetas de negocios bloqueados (a partir de los PNG de `biz_*`).
- Sombras de suelo (se dibujan en el juego).
- Ícono adaptativo de Android (calcetín sobre transparente + fondo menta), recortando el `app_icon`.
- Pantalla de carga (con el ícono sobre el color menta).

## Después (v1.1 y animación)

- Animaciones: negocios "trabajando" (4 a 8 cuadros cada uno, o Rive), managers parpadeando y saludando, mascota (reposo, salto, celebración). Si prefieres Rive o Spine, dime y preparo el formato.
- Cosméticos: estampados, gorritos, lentes, fondos de cuarto, animaciones de Centrifugado.
- Eventos de temporada: Calcetín Fantasma (Halloween), Calcetines Navideños, Día del Calcetín Desparejado.
- Segundo mundo: fondo y 10 negocios nuevos (Lavandería pública).

## Notas de calidad de lo ya entregado

- `icon_ui_negocios` vino en 1024×559; funciona, pero conviene regenerarlo cuadrado.
- `biz_10_portal` trae una placa gris de esquinas redondeadas que los demás negocios no tienen; si quieres coherencia, regénéralo sin placa.
- `mgr_10_gran_centrifugadora`: el brillo de la corona se pierde un poco al quitar el fondo.
- Varios negocios y managers venían con un mosaico redondeado y esquinas blancas; con la receta de arriba salen sin trabajo extra.
