# Monetización (F7, modo de prueba)

Implementa la sección 10 del spec con **servicios simulados**. Nada se cobra ni se muestra publicidad real. Los servicios reales se conectan en F8 sin cambiar la lógica del juego.

## Reglas que ya cumple el código

- Los anuncios solo aparecen si el jugador toca un botón que dice qué gana. No hay interstitials, banners ni anuncios al abrir pantallas.
- Ningún anuncio antes del primer regreso (la primera ganancia offline recogida) ni del primer Centrifugado. Para probar en la web: juega, cierra o recarga la pestaña, espera 1 minuto y vuelve.
- La oferta de compra (Paquete de inicio) solo existe después del primer Centrifugado y se compra una vez.
- Todo se puede ganar jugando: los Botones Dorados también salen del regalo diario; las compras ahorran tiempo.
- Sin cajas aleatorias, sin suscripción, sin temporizadores falsos.
- La tienda cobra primero; el juego solo aplica el producto si el cobro se completó **y** la regla lo permite (por ejemplo, el nivel 2 del multiplicador no se cobra sin el nivel 1).

## Anuncios recompensados

| Ubicación | Recompensa | Límite |
| --- | --- | --- |
| Tienda, Boost | +4 h de x2 a todo | Máximo 12 h acumuladas |
| Ventana de bienvenida offline | x2 a lo ganado offline | 1 por regreso |
| Tienda, Saltar espera | 15 min de producción de los negocios con manager | 3 al día |
| Metas, regalo diario | +5 Botones Dorados | 1 al día |

Con el **Pase VIP** las mismas recompensas se dan sin ver el anuncio (con los mismos límites).

## Productos (precios de referencia en MXN, `config/economy.json`)

| Producto | Precio | Qué da |
| --- | --- | --- |
| Pase VIP | $149 | Recompensas de anuncios sin verlos, para siempre |
| Paquete de inicio | $49 | 50 Botones Dorados y +25% a todo, para siempre. Una sola vez, después del primer Centrifugado |
| Botones Dorados | $29 / $79 / $149 / $299 | 30 / 90 / 200 / 450 Botones |
| Multiplicador permanente | $99 / $199 / $349 | Nivel 1, 2 y 3: **x2 cada uno** (x8 con los tres) |

Los Botones Dorados se gastan en saltos de tiempo: 1 h por 10, 4 h por 35, 12 h por 90.

## Decisiones tuyas que conviene revisar

- **Multiplicador permanente:** el spec dice "x2 a todo, con tope de 3 compras". Lo implementé literal (x2 por nivel, x8 en total). Es mucho; si prefieres otra curva (por ejemplo x2, x3, x4 acumulados) se cambia el `factor` de cada nivel en la config.
- **Cantidades de Botones Dorados y costos de los saltos:** son mías, sin calibrar.
- El simulador de balance **no** incluye compras ni anuncios.

## Cómo se prueba

La versión web (GitHub Pages) usa `TestAdService` y `TestIapService` (`lib/ui/test_services.dart`): el anuncio es un diálogo con cuenta regresiva de 3 s y la compra es una confirmación sin cobro. La Tienda muestra un aviso de "Modo de prueba".

## Pendiente para F8 (lanzamiento)

- `AdService` real con AdMob: IDs de aplicación y de unidades recompensadas, filtro de categorías sensibles y forma de reportar un anuncio.
- `IapService` real con Google Play Billing: crear los 9 productos en Play Console con los precios en MXN, restaurar compras y verificar recibos.
- Pedir la calificación en la tienda una sola vez, tras el tercer Centrifugado (no está hecho).
- Permiso de notificaciones entre el minuto 10 y 20, máximo una al día (no está hecho).
- Declaración de audiencia 13+ y clasificación de contenido en Play Console.
