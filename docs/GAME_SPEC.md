# Idle Tycoon tierno — Especificación basada en AdVenture Capitalist

Nov 2, 2026 · @Alfredo

## 1. Propósito y cómo usar este documento

Este documento es la especificación de entrada para construir, con Claude Code, un idle tycoon móvil llamado Calcetinópolis (nombre provisional, pendiente de verificar en Google Play e IMPI), inspirado en AdVenture Capitalist (Hyper Hippo, 2014), pero de calcetines perdidos (sección 8.5), para Android primero, solo en español y con precios en MXN, con anuncios 100% opcionales y compras in-app que no rompan la experiencia.

Tiene dos mitades. Las secciones 2 a 7 describen cómo funciona el juego original y qué odian sus jugadores. Las secciones 8 a 11 son la especificación de tu juego: temática, sistemas, fórmulas, monetización y arquitectura.

**Cómo dárselo a Claude Code:**

1. Revisa y edita este documento aquí (puedes comentar cualquier párrafo).
2. Expórtalo a Markdown y guárdalo en la raíz del repo como `docs/GAME_SPEC.md`.
3. Pide a Claude Code que lo lea completo y construya por fases (sección 11), una fase por sesión, con tests de la fórmula económica antes de la UI.
4. Las secciones 2–7 son contexto; las 8–11 son requisitos. Si hay conflicto, mandan las 8–11.

**Convenciones:** "AdCap" = AdVenture Capitalist. Los números del juego original vienen de wikis de la comunidad y pueden variar entre versiones; se usan como referencia de balance, no para copiarlos tal cual.

## 2. Qué es AdVenture Capitalist y por qué engancha

AdCap es un idle tycoon cuyo loop es: compras negocios, cada negocio produce dinero al terminar un temporizador, contratas managers para automatizarlos y, cuando el crecimiento se frena, reinicias a cambio de "Angel Investors" que multiplican todo lo siguiente. Lleva 12 años vivo: 4.7 estrellas con 384K calificaciones en App Store y 4.5 con más de 1.4M reseñas y 10M+ descargas en Google Play ([App Store](https://apps.apple.com/us/app/adventure-capitalist-tycoon/id927006017), [Google Play](https://play.google.com/store/apps/details?id=com.kongregate.mobile.adventurecapitalist.google)).

Hoy el juego tiene cuatro "destinos" (Tierra, Luna, Marte y Vacay Island, añadido en septiembre de 2025), eventos por tiempo limitado en rotación, minijuegos (Lemonade Stand, Business Battles), outfits con bonos y una ruta guiada de metas llamada Capitalist Ladder ([notas de versión](https://apps.apple.com/us/app/adventure-capitalist-tycoon/id927006017)).

**Sesión típica de un jugador:**

1. Abre el juego y ve cuánto ganó mientras no estaba (los managers siguen produciendo offline).
2. Compra negocios en lotes (x1, x10, x100, Max) apuntando al siguiente umbral: 25, 50, 100, 200…
3. Compra upgrades de efectivo y contrata managers nuevos.
4. Si quiere, ve un anuncio para duplicar ganancias durante 4 horas.
5. Cuando comprar lo siguiente tarda demasiado, reinicia para cobrar ángeles.
6. Cierra la app; el dinero sigue creciendo.

*(Diagrama del loop principal omitido en la exportación; el loop es la lista numerada de arriba.)*

El prestigio cierra el círculo: cada vuelta empieza desde cero pero con un multiplicador mayor, así que el muro llega más tarde.

**Por qué engancha:**

- **Metas siempre visibles:** el próximo umbral de 25/50/100 está a minutos, no a horas.
- **Progreso sin estar presente:** volver a la app siempre trae una recompensa.
- **El prestigio rompe la pared:** cada reinicio se siente más rápido que el anterior.
- **Números absurdos:** pasar de miles a "quattuordecillones" es parte de la gracia.
- **Humor:** managers y upgrades son parodias y juegos de palabras; los jugadores lo mencionan en reseñas positivas.
- **Anuncios a elección:** las reseñas positivas destacan que los anuncios solo aparecen si el jugador los pide a cambio de un premio.

## 3. Economía base: negocios y fórmulas

Todo el juego es un sube y baja: el costo de cada negocio crece exponencialmente y la producción crece de forma lineal con multiplicadores por umbrales. Cuando el costo alcanza a la producción, el jugador necesita un multiplicador nuevo o un reinicio ([Pecorella, productor de AdCap](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-i)).

### 3.1 Los 10 negocios de la Tierra

| Negocio | Costo inicial ($) | Coeficiente | Ciclo base (s) | Ingreso por ciclo ($) | $/s inicial |
| --- | --- | --- | --- | --- | --- |
| Lemonade Stand | 3.738 | 1.07 | 0.6 | 1 | 1.67 |
| Newspaper Delivery | 60 | 1.15 | 3 | 60 | 20 |
| Car Wash | 720 | 1.14 | 6 | 540 | 90 |
| Pizza Delivery | 8,640 | 1.13 | 12 | 4,320 | 360 |
| Donut Shop | 103,680 | 1.12 | 24 | 51,840 | 2,160 |
| Shrimp Boat | 1,244,160 | 1.11 | 96 | 622,080 | 6,480 |
| Hockey Team | 14,929,920 | 1.10 | 384 | 7,464,960 | 19,440 |
| Movie Studio | 179,159,040 | 1.09 | 1,536 | 89,579,520 | 58,320 |
| Bank | 2,149,908,480 | 1.08 | 6,144 | 1,074,954,240 | 174,960 |
| Oil Company | 25,798,901,760 | 1.07 | 36,864 | 29,668,737,024 | 804,816 |

Fuente: [AdCap Wiki — Businesses](https://adventure-capitalist.fandom.com/wiki/Businesses). El juego regala el primer Lemonade Stand y el segundo cuesta $4.

**Patrones de diseño que conviene copiar:**

- A partir de Car Wash, cada negocio cuesta exactamente 12× el anterior.
- El ciclo crece entre ×2 y ×6 en cada nivel: 0.6 s, 3 s, 6 s, 12 s, 24 s, 96 s… hasta 10 h 14 min para Oil.
- El coeficiente baja conforme sube el negocio (1.15 → 1.07): los negocios caros escalan más suave para que sigan siendo relevantes.
- Comprar x10 o x100 no da descuento; es la suma de comprar uno por uno.

### 3.2 Fórmulas

Costo de la siguiente unidad, con *b* = costo inicial, *r* = coeficiente, *k* = unidades que ya tienes:

```latex
C_{next} = b \cdot r^{k}
```

Costo de comprar *n* unidades de golpe (serie geométrica):

```latex
C_{bulk}(n) = b \cdot \frac{r^{k}\,(r^{n} - 1)}{r - 1}
```

Máximo de unidades que alcanzas con *c* de dinero (botón "Max"):

```latex
n_{max} = \left\lfloor \frac{\ln\!\left(\frac{c\,(r-1)}{b\,r^{k}} + 1\right)}{\ln r} \right\rfloor
```

Ingreso al terminar un ciclo, con *p* = ingreso base por unidad y *M* = producto de todos los multiplicadores (upgrades, unlocks, ángeles, boosts):

```latex
I_{ciclo} = p \cdot k \cdot M
```

Duración del ciclo, con *h* = número de "halvings" ganados (máximo 12, o sea 1/4096 del tiempo original):

```latex
T = \frac{T_{base}}{2^{h}}
```

Fórmulas de [Pecorella](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-i) y [AdCap Wiki](https://adventure-capitalist.fandom.com/wiki/Businesses).

### 3.3 Límite numérico

AdCap usa números de punto flotante de 64 bits; el precio más alto posible es \~1.8×10³⁰⁸ y por eso hay un máximo de unidades por negocio (por ejemplo, 5,049 Newspapers). Pasado ese punto, el precio es "infinito". Tu juego debe usar una librería de números grandes desde el día uno (sección 9).

## 4. Managers, upgrades y unlocks

Tres sistemas empujan la producción por encima del costo: managers (automatizan), upgrades (multiplican ganancias) y unlocks (premian llegar a cantidades redondas). Juntos crean la cadencia de "siempre hay algo que comprar".

### 4.1 Managers

| Tipo | Qué hace | Cómo se paga | Se pierde al reiniciar |
| --- | --- | --- | --- |
| Manager normal | Corre el temporizador de un negocio sin tocarlo, también offline | Dinero | Sí |
| Accountant | Muestra $/s en vez de $/ciclo y baja 10% el precio de ese negocio | Ángeles (se sacrifican) | Sí |
| Discount Manager | Baja 99.999% el precio de un negocio (endgame) | Dinero, cifras astronómicas | Sí |
| Upgrade Manager | Calidad de vida: "EZ Upgrader" (1 ángel) y "Quik Buy" para comprar todos los upgrades | Ángeles | Sí |

Fuente: [AdCap Wiki — Managers](https://adventure-capitalist.fandom.com/wiki/Managers). Cada manager es una parodia de un personaje conocido; es parte del humor del juego.

### 4.2 Upgrades de efectivo (Cash Upgrades)

- Se compran con dinero y multiplican ganancias, normalmente ×3, de un negocio o de todos.
- Los de "All Profits ×3" son los más valiosos para el jugador.
- Algunos aumentan la efectividad de los ángeles (por ejemplo, de +2% a más por ángel).
- Se pierden al reiniciar.

### 4.3 Upgrades de ángeles (Angel Upgrades)

- Hay 194 en la Tierra. Se pagan **sacrificando** ángeles, que se pierden para siempre.
- Dan multiplicadores, unidades gratis de un negocio y más efectividad por ángel.
- Generan una decisión interesante: gastar ángeles hoy baja tu bono permanente. La comunidad recomienda no gastar más de \~10% del total ([AdCap Wiki — Angel Investors](https://adventure-capitalist.fandom.com/wiki/Angel_Investors)).

### 4.4 Unlocks (umbrales)

- Al tener 25, 50, 100, 200, 300 y 400 unidades de un negocio, su ciclo se reduce a la mitad.
- Cuando **todos** los negocios llegan a ese mismo umbral, todos se aceleran otra vez (unlock "Everything").
- El máximo son 12 reducciones a la mitad; con 400 de todo, Oil Company pasa de 10 horas a \~9 segundos.
- Más allá de 400, los umbrales dan multiplicadores de ganancia (×2, ×3…) en lugar de velocidad, y algunos negocios dan bonos cruzados a otros.

Fuente: [AdCap Wiki — Businesses](https://adventure-capitalist.fandom.com/wiki/Businesses).

**Lección clave:** los unlocks de 25 y 50 son los que más compras generan, porque el jugador ve el premio justo antes de alcanzarlo. Pecorella muestra que las compras se concentran alrededor de esos umbrales ([fuente](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-i)).

## 5. Prestigio: Angel Investors y ganancias offline

Los ángeles son la única moneda principal que sobrevive al reinicio, y cada uno suma +2% a todas las ganancias. Se ganan según el dinero total acumulado desde el último reinicio completo, con una raíz cuadrada que hace cada ángel un poco más caro que el anterior.

### 5.1 Fórmula

Con *E* = ganancias de por vida en ese planeta:

```latex
A = 150 \cdot \sqrt{\frac{E}{10^{15}}}
```

Inversa, para saber cuánto dinero necesitas para *A* ángeles:

```latex
E = 10^{15} \cdot \left(\frac{A}{150}\right)^{2}
```

Bono de ganancia, con *e* = efectividad por ángel (0.02 de base, mejorable con upgrades):

```latex
M_{angeles} = 1 + A \cdot e
```

| Ganancias de por vida | Ángeles |
| --- | --- |
| $44,444,444,445 | 1 |
| $1 billón (10¹²) | 4 |
| $1 cuatrillón (10¹⁵) | 150 |
| 10¹⁸ | 4,743 |
| 10²¹ | 150,000 |
| 10²⁴ | 4,743,416 |

Fuente: [AdCap Wiki — Angel Investors](https://adventure-capitalist.fandom.com/wiki/Angel_Investors). La Luna usa la misma fórmula; Marte da el doble de ángeles por el mismo dinero. Los ángeles se suman, no se multiplican: 50 ángeles = +100% (×2); 1,000 ángeles = ×21.

### 5.2 Qué se conserva y qué se pierde

| Se conserva | Se pierde |
| --- | --- |
| Ángeles no gastados | Dinero y todos los negocios |
| Gold, Megabucks y compras con dinero real | Upgrades de efectivo |
| Multiplicadores permanentes (gold upgrades, negocios "gilded") | Managers y accountants |
| Outfits, badges | Upgrades de ángeles (y los ángeles que se sacrificaron) |

Fuentes: [AdCap Wiki — Angel Investors](https://adventure-capitalist.fandom.com/wiki/Angel_Investors), [AdCap Wiki — Mega Tickets](https://adventure-capitalist.fandom.com/wiki/Mega_Tickets).

### 5.3 Cuándo reiniciar

- El botón dice cuántos ángeles cobrarías ahora; el jugador decide.
- La regla de la comunidad es reiniciar cuando cobrarías al menos lo que ya tienes (duplicar ángeles).
- Para el primer reinicio, \~150 ángeles (×4 de ganancia) es un punto común; se alcanza tras uno o dos días de juego ([Steam](https://steamcommunity.com/app/346900/discussions/0/618459109264157866)).

### 5.4 Ganancias offline

- Todo negocio con manager sigue produciendo con la app cerrada.
- Al volver, una ventana muestra lo ganado. Es el momento más gratificante del juego.
- Hubo exploits clásicos: adelantar el reloj del teléfono daba años de ganancias ([PSNProfiles](https://psnprofiles.com/guide/7220-adventure-capitalist-trophy-guide)). Tu juego debe validar el tiempo transcurrido (sección 9).

## 6. Meta-sistemas, monedas premium y tienda

Alrededor del loop base, AdCap fue apilando sistemas durante 12 años para retener y monetizar. No todos valen la pena para un MVP; la sección 9 dice cuáles tomar.

### 6.1 Destinos (mundos)

- **Tierra, Luna, Marte y Vacay Island:** cada uno con sus 10 negocios, managers, upgrades, moneda y ángeles propios.
- Cada destino tiene su propio balance: la Luna usa coeficientes muy dispares (Gravity Booth 1.21, Giant Laser 1.50), Marte arranca con negocios casi gratis (Red Dirt a $0.05).
- Reiniciar un destino no afecta a los otros.

### 6.2 Eventos por tiempo limitado

- Rotan de forma regular (unos 4 días), con temática de temporada: Halloween, Navidad, San Valentín, Super Bowl…
- Cada evento trae 9–10 negocios propios con coeficientes agresivos (de 1.05 hasta ×12) para que se juegue en días, no meses.
- Tienen metas con recompensas (gold, Megabucks, time warps, badges) y un leaderboard global.
- **ProfitCaster:** boost de ×9 a ×33 durante 10–30 segundos, se recarga cada 1.5–4 horas ([AdCap Wiki](https://adventure-capitalist.fandom.com/wiki/ProfitCaster)).

### 6.3 Monedas y boosts

| Sistema | Qué es | Cómo se obtiene | Sobrevive al reinicio |
| --- | --- | --- | --- |
| Gold | Moneda premium | Compra con dinero real, metas de eventos | Sí |
| Megabucks | Segunda moneda premium | Eventos, anuncios, hitos, recompensas diarias | Sí |
| Mega Tickets | ×7.77 permanente a un negocio; con todo el planeta = "platinum" ×17.77, ampliable hasta ×7,777.77 con Megabucks | 20 Gold o 10 Megabucks | Sí (retirados en feb 2026, ver abajo) |
| Time Warp | Te da X horas/días de ganancias al instante | Gold, eventos | No aplica |
| Ad Boost | ×2 a todas las ganancias por 4 horas | Ver un anuncio; máx. 5 vistas por día por planeta | No aplica |
| Outfits | Ropa del personaje con bono a ganancias | Eventos, Megabucks | Sí |
| Capitalist Connections + Vaults | Managers coleccionables con bonos permanentes; cofres aleatorios | Gold o moneda de evento | Sí |

Fuentes: [Mega Tickets](https://adventure-capitalist.fandom.com/wiki/Mega_Tickets), [Opt-In Boosts](https://adventure-capitalist.fandom.com/wiki/Opt-In_Boosts), [v8.2.0](https://apkmirror.com/apk/hyper-hippo/adventure-capitalist/adventure-capitalist-8-2-0-release).

### 6.4 Cambios recientes (2025–2026)

> **Contexto, no verificado.** Estos datos vienen de búsquedas y no se pudieron reverificar. Ninguna decisión de diseño depende de ellos.

| Versión | Fecha | Cambio |
| --- | --- | --- |
| 9.27 | Sep 2026 | Opción de saltar pasos del tutorial |
| 9.21 | May 2026 | Hard reset desde el juego; "AdSkip Passes" para jugar sin anuncios |
| 9.20 | Mar 2026 | Tienda web propia con descuentos |
| 9.19 | Feb 2026 | Rediseño del "gilding"; Mega Tickets retirados y convertidos a Megabucks |
| 9.17 | Nov 2025 | Capitalist Ladder: ruta guiada de metas con recompensas gratis |
| 9.14 | Sep 2025 | Nuevo destino: Vacay Island |
| 9.12 | Jun 2025 | Minijuego Business Battles |

Fuente: [historial de versiones en App Store](https://apps.apple.com/us/app/adventure-capitalist-tycoon/id927006017). En Steam, Hyper Hippo anunció en octubre de 2026 un relanzamiento que **no** conserva el progreso ni las compras anteriores, y que reemplaza los anuncios por "Flex Credits" pagados con Gold ([Steam](https://steamcommunity.com/app/346900)).

### 6.5 Compras in-app actuales (App Store, EE. UU.)

| Producto | Precio (USD) |
| --- | --- |
| 20 Gold Bars | 1.99 |
| 55 Gold Bars | 4.99 |
| 115 Gold Bars | 9.99 |
| 240 Gold Bars | 19.99 |
| First Time Buyer Bundle | 3.99 / 7.99 |
| Insider Deal Package | 3.99 |
| Gold Subscription | 9.99 |
| 30 Day Ad Removal Pass | 14.99 |

Fuente: [App Store](https://apps.apple.com/us/app/adventure-capitalist-tycoon/id927006017). La ficha declara "Contains Loot Boxes" y Google Play (ficha regional consultada) lo clasifica 16+ por compras con objetos aleatorios ([Google Play](https://play.google.com/store/apps/details?id=com.kongregate.mobile.adventurecapitalist.google)).

## 7. Quejas de jugadores y lecciones de diseño

La queja dominante en 2025–2026 es que los anuncios dejaron de ser opcionales: aparecen al abrir menús y quitarlos cuesta una suscripción de US$14.99 al mes. Le siguen los eventos que se sienten pay-to-win, los leaderboards llenos de tramposos y la pérdida de progreso. Las reseñas positivas, en cambio, celebran justo lo contrario: anuncios a elección y que se puede jugar sin pagar.

| # | Tema | Qué dicen los jugadores | Dónde | Lección para tu juego |
| --- | --- | --- | --- | --- |
| 1 | Anuncios intrusivos | Al principio eran opcionales; luego salía un anuncio con solo abrir un menú, ver upgrades, contratar un manager o ir a la Luna. Hyper Hippo respondió que ver anuncios con recompensa reduce los pop-ups | [Google Play](https://play.google.com/store/apps/details?id=com.kongregate.mobile.adventurecapitalist.google), 2025 | Cero interstitials. Ningún anuncio sin que el jugador toque un botón que diga qué gana |
| 2 | Quitar anuncios por suscripción | US$14.99 por 30 días se percibe como codicia, sobre todo en un idle game | [Google Play](https://play.google.com/store/apps/details?id=com.kongregate.mobile.adventurecapitalist.google), [AppsMeNow](https://appsmenow.com/reviews/74834-adventure-capitalist) | Pase "sin anuncios" de pago único, no suscripción |
| 3 | Anuncios que sacan de la app | Algunos anuncios abren otras apps solos o tienen la "X" casi imposible de tocar | [Google Play](https://play.google.com/store/apps/details?id=com.kongregate.mobile.adventurecapitalist.google), jun 2025 | Filtrar categorías de anunciantes y reportar creativos problemáticos desde la mediación |
| 4 | Demasiadas vistas para todos los boosts | Un jugador cuenta 11 anuncios para activar todos los boosts solo en la Tierra | [App Store](https://apps.apple.com/us/app/adventure-capitalist-tycoon/id927006017), 2024 | Un solo botón de boost por sesión con valor alto; no fragmentar en muchos micro-anuncios |
| 5 | Eventos pay-to-win | Las metas son técnicamente gratis pero casi inalcanzables sin pagar | [GamingHQ](https://gaminghq.eu/2026/01/25/adventure-capitalist-review/), ene 2026 | Diseñar metas de evento alcanzables al 100% sin pagar; el pago acelera, no habilita |
| 6 | Tramposos en leaderboards | Puntajes imposibles minutos después de abrir un evento; sin anti-trampas | [Steam](https://steamcommunity.com/app/346900/discussions/0/1698300679762643168), 2018–2026 | Leaderboards por liga, validación de servidor o, en el MVP, sin leaderboards |
| 7 | Progreso perdido | Progreso de evento borrado, recompensas de primer lugar que nunca llegan, saves corruptos | [Steam](https://steamcommunity.com/app/346900/discussions/0/4846526727957271766), oct 2024 | Guardado frecuente, respaldos, migraciones de versión probadas y nube |
| 8 | Relanzamiento sin migrar progreso | En Steam, el relanzamiento de 2026 no conserva progreso ni compras; los anuncios se reemplazan por créditos pagados | [Steam](https://steamcommunity.com/app/346900), oct 2026 | Nunca romper un save; versionar el esquema desde el día uno |
| 9 | Requiere internet / no abre | Errores de conexión al iniciar, aun con internet | [Steam](https://steamcommunity.com/app/346900), oct 2026; [App Store](https://apps.apple.com/us/app/adventure-capitalist-tycoon/id927006017) | Juego base 100% offline; red solo para nube, eventos y tienda |
| 10 | Balance irregular | La Luna se siente mal balanceada; terminar la Tierra es matemáticamente casi imposible | [GamingHQ](https://gaminghq.eu/2026/01/25/adventure-capitalist-review/); [Steam](https://steamcommunity.com/app/346900/discussions/0/487870763318777936) | Simular el balance de cada mundo antes de lanzarlo; tener un final alcanzable |
| 11 | Cálculos de metas mal | Jugadores reportan metas de evento que fallan por una potencia de 10 | [Steam](https://steamcommunity.com/app/346900), oct 2026 | Tests automáticos de las fórmulas y de cada meta |
| 12 | Números difíciles de leer | Piden alternar entre nombres ("trillion") y notación científica | [App Store](https://apps.apple.com/us/app/adventure-capitalist-tycoon/id927006017), 2023 | Ajuste de formato de números desde el MVP |
| 13 | Loot boxes | La ficha declara loot boxes (Vaults) | [App Store](https://apps.apple.com/us/app/adventure-capitalist-tycoon/id927006017) | Evitar cajas aleatorias pagadas: riesgo regulatorio y de reputación |

**Lo que sí aman y hay que conservar:** anuncios solo si el jugador los pide, el humor de los nombres, que el juego avance mientras duermes, poder progresar sin pagar y tener metas a corto plazo siempre visibles ([App Store](https://apps.apple.com/us/app/adventure-capitalist-tycoon/id927006017)).

## 8. Temática elegida: calcetines perdidos (y alternativas)

La mejor temática es la que convierte el prestigio en algo natural, no en "inversionistas ángeles". El juego base es Calcetines perdidos (8.5). Las otras cuatro (8.1 a 8.4) quedan como candidatas a eventos de temporada, igual que AdCap usa Halloween o Navidad.

| Temática | Moneda | Prestigio (reemplaza a los ángeles) | Ventaja | Riesgo |
| --- | --- | --- | --- | --- |
| Ajolotitos de Xochimilco | Burbujitas | **Regeneración:** cada Ajolote Dorado da +2% | Tierno, mexicano, el prestigio ya existe en la biología del ajolote | El ajolote es tendencia; hay que diferenciar el estilo |
| Gusanitos y orugas del huerto | Hojitas | **Metamorfosis:** las orugas hacen capullo; cada Mariposa da +2% | Metáfora universal y clarísima; ideal para sprites | Los insectos le dan asco a algunos; requiere estilo muy kawaii |
| Calaquitas | Pétalos de cempasúchil | **Ofrenda:** cada Recuerdo da +2% | Identidad mexicana única; evento natural cada noviembre | Tema de muerte en algunos mercados; evitar parecerse a "Coco" (Disney/Pixar) |
| Changuitos de la selva | Plátanos | **Gran Ceiba:** cada Semilla Ancestral da +2% | Animaciones muy expresivas | Temática genérica; muchos juegos de monos |
| Calcetines perdidos (elegida) | Pelusitas | Centrifugado: cada Pareja Reunida da +2% | Humor propio; un solo sprite base con muchos estampados; cosméticos fáciles de producir | Que se parezca a otros personajes de "calcetín con ojos"; ya existen otros juegos de calcetines perdidos (ver 8.5) |

**Combinación sugerida:** Calcetines perdidos como juego base; Calaquitas como evento de Día de Muertos (noviembre); Changuitos como evento de verano; Ajolotitos u Orugas como eventos de primavera.

### 8.1 Ajolotitos de Xochimilco

- **Negocios (barato → caro):** Chinampa de lechuga, Puesto de esquites, Trajinera de nieves, Canal de flores, Mercado de dulces típicos, Embarcadero de trajineras, Vivero de flores, Mariachi flotante, Festival de la Trajinera, Acuario Gran Lago.
- **Managers:** garzas, patitos, ranitas, carpas y tortuguitas con oficio.
- **Mundos:** Xochimilco → Lago de Pátzcuaro → Lago-cielo (equivalente a la Luna).
- **Gancho extra:** el ajolote está en peligro de extinción; un porcentaje o un evento puede apoyar conservación, lo cual sirve para marketing.

### 8.2 Gusanitos y orugas del huerto

- **Negocios:** Hoja de lechuga, Gota de rocío, Fresa caída, Túnel de tierra, Hongo-hotel, Campo de tréboles, Maceta olvidada, Huerto de la abuelita, Invernadero, Árbol gigante.
- **Managers:** catarinas, caracoles, abejitas, hormigas y luciérnagas.
- **Mundos:** Jardín → Bosque → Noche de luciérnagas.
- **Gancho extra:** la animación del capullo al reiniciar es el momento "wow" del juego.

### 8.3 Calaquitas

- **Negocios:** Pan de muerto, Papel picado, Calaveritas de azúcar, Veladoras, Mariachi del más allá, Taller de alebrijes, Tamales de la abuela, Desfile de catrinas, Tranvía de almitas, Puente de cempasúchil al Mictlán.
- **Managers:** xoloitzcuintles, alebrijes, catrines y catrinas.
- **Mundos:** Pueblo → Panteón iluminado → Mictlán.
- **Gancho extra:** humor de "calaveritas literarias" para nombres de upgrades, igual que AdCap usa parodias.

### 8.4 Changuitos de la selva

- **Negocios:** Puesto de plátanos, Columpio de lianas, Spa de despiojado, Coco-bar, Tobogán de cascada, Mercado de mangos, Cine bajo las hojas, Tour al templo perdido, Parque en la copa, Aerolínea de tucanes.
- **Managers:** perezosos, tucanes, jaguarcitos y guacamayas.
- **Mundos:** Selva → Volcán → Isla flotante.

### 8.5 Calcetines perdidos (propuesta nueva, favorita)

**Premisa:** todos los calcetines que desaparecen de las lavadoras viven en un mundo secreto, y cada uno sueña con reencontrar a su pareja. El jugador es un calcetín emprendedor que levanta negocios en ese mundo.

- **Moneda:** Pelusitas.
- **Prestigio:** *Centrifugado.* Al reiniciar, la lavadora gira y el jugador gana **Parejas Reunidas**; cada una da +2% a todas las ganancias. Es el equivalente de los ángeles y cuenta una historia en cada reinicio: dos calcetines se encuentran.
- **Negocios (barato → caro):** Tendedero de pelusas, Cesto de ropa sucia, Rincón bajo el sofá, Lavandería de burbujas, Secadora giratoria, Cajón de calcetines, Taller de tejido, Fábrica de estambre, Tren del tendedero, Portal de la lavadora.
- **Managers:** botones, alfileres de seguridad, agujas, dedales, ganchos de ropa, bolitas de pelusa, etiquetas de lavado y jabones con personalidad. Cada manager es un calcetín con un estampado propio (rayas, lunares, rombos, tejido navideño) y un nombre de juego de palabras.
- **Mundos:** Casa (cuarto de lavado) → Lavandería pública → Dimensión de los Pares Perdidos (equivalente a la Luna).
- **Eventos de temporada:** Calcetín Fantasma (Halloween), Calcetines Navideños (diciembre), Día del Calcetín Desparejado (evento de verano).
- **Cosméticos:** estampados, accesorios (gorritos, lentes, bufandas), fondos de cuarto de lavado.

**Por qué encaja con tu pipeline de arte con IA:**

- Un calcetín es una forma simple: con un solo sprite base y cambios de estampado y paleta salen decenas de personajes distintos.
- Se anima bien con estirar y encoger (squash and stretch), sin necesidad de extremidades complejas.
- Los cosméticos son fáciles de producir y es lo que mejor vende en un juego tierno.

**Riesgos a vigilar:** no pedir al generador de imágenes personajes con marca (por ejemplo, elfos domésticos de películas conocidas) y revisar que "Calcetines perdidos" o el nombre final no choque con otras apps en las tiendas.

**Juegos de calcetines perdidos que ya existen (búsqueda del 2 de noviembre de 2026, a confirmar en las tiendas):**

- *Lost Socks Inc: Merge & Idle:* según una ficha en un sitio de descargas de terceros, es un juego de Google Play que combina fusionar calcetines con ingresos idle, con arte pixelado y gnomos como trabajadores. Es el competidor más directo.
- *Lost Sock Simulator 3000:* idle clicker para Nintendo Switch con fecha de salida del 19 de noviembre de 2026 ([Nintendo](https://www.nintendo.com/us/store/products/lost-sock-simulator-3000-switch/)).
- *Lost Sock:* juego de un solo botón en iOS ([App Store](https://apps.apple.com/us/app/-/id1434522367)) y *Lost Socks: Naughty Brothers*, un platformer en Android desde 2018 ([Android Authority](https://www.androidauthority.com/lost-socks-naughty-brothers-play-store-download-835522)).

**Qué significa:** la premisa no es nueva, aunque ninguno de estos juegos es un idle estilo AdCap con arte tierno, identidad mexicana y un prestigio emotivo de reencuentro de parejas. Eso sería tu diferenciación. Condiciones: un nombre propio que no use "Lost Socks", una búsqueda en Google Play con palabras en español (calcetines, calcetín, pares) y una revisión de marca antes de invertir en el arte.

**Regla para el arte con IA:** no generar nada que se parezca a personajes o diseños con derechos (Coco, Pokémon, etc.). Definir una hoja de estilo propia (paleta, proporciones, grosor de línea) y usarla en cada prompt.

## 9. Especificación funcional del juego propio

El MVP es un solo mundo con 10 negocios, managers, upgrades, unlocks, prestigio, ganancias offline, guardado en la nube y monetización opcional. Todo lo demás (eventos, segundo mundo, leaderboards) va después. Los valores numéricos de esta sección son un punto de partida para tunear con el simulador (sección 11), no valores finales.

### 9.1 Alcance por versión

| Sistema | MVP | v1.1 | Después |
| --- | --- | --- | --- |
| 10 negocios, 1 mundo | Sí |  |  |
| Managers (automatización) | Sí |  |  |
| Upgrades de efectivo y unlocks por umbral | Sí |  |  |
| Prestigio + tienda de mejoras permanentes | Sí |  |  |
| Ganancias offline con tope | Sí |  |  |
| Guardado local + nube | Sí |  |  |
| Boost por anuncio opcional | Sí |  |  |
| Compras in-app (pase sin anuncios, moneda premium) | Sí |  |  |
| Metas guiadas (tipo Capitalist Ladder) | Sí |  |  |
| Formato de números configurable | Sí |  |  |
| Segundo mundo |  | Sí |  |
| Eventos de temporada (sin leaderboard) |  | Sí |  |
| Cosméticos / outfits |  | Sí |  |
| Leaderboards por liga con validación de servidor |  |  | Sí |
| Minijuegos |  |  | Sí |

### 9.2 Negocios: valores iniciales

Mismo patrón que AdCap, pero con ciclos más cortos arriba (el último tarda 3 h, no 10 h) para sesiones móviles más cortas. Los costos están en Pelusitas y los managers se compran con Pelusitas.

| # | Negocio | Costo inicial (Pelusitas) | Coeficiente | Ciclo base (s) | Ingreso por ciclo | Manager (estampado) | Costo del manager |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Tendedero de pelusas | 4 | 1.07 | 1 | 1 | Doña Pinza (rayas) | 1,000 |
| 2 | Cesto de ropa sucia | 50 | 1.14 | 3 | 40 | Sir Zurcido (parches) | 15,000 |
| 3 | Rincón bajo el sofá | 600 | 1.13 | 6 | 400 | Madame Pelusa (lunares) | 100,000 |
| 4 | Lavandería de burbujas | 7,200 | 1.12 | 12 | 3,600 | Capitán Espuma (ondas azules) | 500,000 |
| 5 | Secadora giratoria | 86,400 | 1.11 | 30 | 40,000 | Remolina Mareada (espirales) | 1.2 M |
| 6 | Cajón de calcetines | 1.04 M | 1.10 | 90 | 450,000 | Marita Orden (cuadros) | 14 M |
| 7 | Taller de tejido | 12.4 M | 1.09 | 300 | 5.5 M | Aguja Pérez (rombos) | 130 M |
| 8 | Fábrica de estambre | 150 M | 1.08 | 900 | 60 M | Estambrina Lanas (tejido navideño) | 1.8 B (mil millones) |
| 9 | Tren del tendedero | 1.8 B (mil millones) | 1.08 | 3,600 | 700 M | Maquinista Hilario (tartán) | 20 B (mil millones) |
| 10 | Portal de la lavadora | 21.5 B (mil millones) | 1.07 | 10,800 | 9 B (mil millones) | La Gran Centrifugadora (arcoíris) | 300 B (mil millones) |

El jugador empieza con el negocio 1 gratis. Todos los valores viven en un archivo de configuración JSON, nunca en el código. Los costos de los managers son una primera propuesta: el simulador (11.2) los ajusta para que cada manager llegue poco antes de que tocar el negocio a mano se vuelva tedioso. Los precios en MXN de 10.2 también son de referencia y se validan en la consola de Google Play.

### 9.3 Reglas de la economía

1. **Costo y compra masiva:** fórmulas de la sección 3.2. Botones x1, x10, x100, "Siguiente umbral" y Max.
2. **Producción:** al terminar el ciclo se paga `ingreso × cantidad × multiplicadores`. Sin manager, el jugador toca el negocio para iniciar cada ciclo.
3. **Ciclos muy rápidos:** con manager, la producción siempre se calcula con un acumulador fraccionario (`ciclos = dt / T`), sin saltos ni diferencia entre online y offline. Si el ciclo baja de 0.25 s, solo cambia la animación: la barra se muestra llena y la tarjeta muestra $/s. Sin manager el umbral no aplica, porque el jugador toca para iniciar cada ciclo.
4. **Unlocks por negocio:** con 25, 50, 100, 200, 300 y 400 unidades, el ciclo se reduce a la mitad. Desde 500, cada +100 unidades duplica la ganancia. Un `max_owned` configurable por negocio (por ejemplo 2,000) sirve de seguro; el simulador confirma que ningún negocio se dispare.
5. **Unlocks globales:** cuando todos los negocios alcanzan un umbral, todos reciben ×2 de velocidad adicional.
6. **Upgrades de efectivo:** lista fija por negocio (×3) y globales (×3 a todo); se compran una vez por partida.
7. **Managers:** uno por negocio, se compran con dinero, se pierden al reiniciar.

### 9.4 Prestigio

Se ganan Parejas Reunidas (el prestigio se llama Centrifugado) según el dinero ganado en toda la vida del jugador (*E_vida*, no solo desde el último reinicio). *S* es la constante de escala, ajustable en config; su valor inicial era `1e12` (placeholder); el simulador lo calibró a `1e14` (ver `docs/BALANCE.md`) para que el primer reinicio llegue entre los 45 y 90 minutos de juego.

```latex
P_{total} = \left\lfloor 150 \cdot \sqrt{\frac{E_{vida}}{S}} \right\rfloor
```

- Al centrifugar se cobran `P_total − parejas_ya_cobradas` Parejas nuevas.
- **Dos monedas separadas, el bono nunca baja:**
  - **Parejas Reunidas:** permanentes, nunca se gastan. Cada una da +2% a todas las ganancias (aditivo, como en AdCap).
  - **Hilvanes:** moneda gastable de la tienda de mejoras permanentes. Se gana 1 Hilván por cada Pareja nueva obtenida en un Centrifugado.
- La pantalla de prestigio muestra: Parejas Reunidas actuales, Parejas por cobrar, y el multiplicador antes y después.
- Indicador "buen momento para reiniciar" cuando las Parejas por cobrar ≥ las actuales.
- **Diferencia con AdCap:** en lugar de sacrificar unidades, se gastan en una tienda de mejoras permanentes con su propia moneda de prestigio. Así el jugador nunca siente que pierde su bono al comprar.

### 9.5 Ganancias offline

- Ganancia = producción por segundo de los negocios con manager × tiempo fuera, con tope de 4 horas al inicio, ampliable hasta 24 h con mejoras permanentes que se compran con Botones Dorados (moneda premium) o con Parejas Reunidas.
- Al volver: ventana de bienvenida con el total y un botón opcional "×2 viendo un anuncio".
- **Anti-trampa de reloj:** usar la hora del servidor cuando haya red; si el reloj del dispositivo retrocede o el tiempo excede el tope, se ignora el exceso.

### 9.6 Números grandes y formato

- Usar una clase de número grande (mantisa + exponente) desde el día uno; los `double` revientan en \~1.8×10³⁰⁸, como le pasó a AdCap.
- **Ojo con el español:** "billón" en español es 10¹², pero "billion" en inglés es 10⁹. Para evitar confusión, usar mil, millón, mil millones (MM), billón… o sufijos cortos.
- Ajuste en configuración: nombres, sufijos cortos o notación científica (queja #12).
- **Formato por defecto (confirmado):** sufijos K, M, B, T (convención de los idle games) y luego aa, ab, ac… az, ba, bb… La notación científica es un ajuste opcional. Ojo: la "B" es 10⁹ (en México "billón" es 10¹²); el modo "nombres" usa mil millones, billón, etc.
- **En JSON y en el save:** los números grandes se guardan como string en notación científica (`"2.15e10"`) o como mantisa y exponente, nunca como decimal de 64 bits. Punto decimal en toda la spec.

### 9.7 Guardado

- Guardar cada 30 segundos, al comprar algo importante y al mandar la app a segundo plano.
- Esquema de guardado con número de versión y migraciones probadas con tests (quejas #7 y #8).
- Tres copias rotativas locales + sincronización en la nube (Google Play Games; Game Center cuando salga iOS).
- Exportar/importar save como texto para soporte.

### 9.8 Pantallas (resumen; el detalle está en 9.11 y 9.12)

1. **Principal:** lista de negocios con ícono animado, barra de ciclo, cantidad, próximo umbral, botón comprar y botón de manager.
2. **Upgrades:** lista ordenada por costo, con "comprar todos los asequibles".
3. **Managers.**
4. **Prestigio:** cálculo antes/después y la tienda de mejoras permanentes.
5. **Boosts:** estado del boost por anuncio y tiempo restante.
6. **Tienda:** pase sin anuncios, moneda premium, paquetes.
7. **Metas:** ruta guiada con recompensas.
8. **Ajustes:** formato de números, sonido, vibración, idioma, nube, exportar save.
9. **Bienvenida offline** (modal).

### 9.9 Analítica mínima

`tutorial_step`, `generator_buy`, `upgrade_buy`, `manager_buy`, `prestige`, `offline_claim`, `ad_offer_shown`, `ad_offer_accepted`, `ad_completed`, `iap_view`, `iap_purchase`, `session_start` con duración. Con esto se mide retención D1/D7, tiempo al primer prestigio y tasa de aceptación de anuncios.

### 9.10 User journey

El recorrido está pensado para que el jugador sienta recompensa en los primeros 10 segundos, quiera volver en el primer día y vea el primer anuncio o la primera compra solo cuando ya está contento. Los tiempos son metas para el simulador (11.2), no promesas.

| # | Etapa | Cuándo | Qué pasa | Qué debe sentir | Monetización | Métrica |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Descubrimiento | Antes de instalar | Ficha de Google Play con capturas en español, el calcetín protagonista y el gancho "Reúne a los calcetines perdidos" | Ternura y curiosidad | Ninguna | Conversión de visita a instalación |
| 2 | Primeros 60 segundos | Minuto 0 a 1 | Sin registro. Un calcetín solitario en la lavadora: toca el Tendedero, gana Pelusitas, compra el segundo. Tutorial de 3 pasos, que se puede saltar | "Ya estoy ganando" | Ninguna | `tutorial_step`, abandono antes del paso 3 |
| 3 | Enganche | Minutos 1 a 10 | Primer manager (antes de 3 min), negocios 2 y 3, primer umbral de 25 (el negocio va el doble de rápido). Aparecen las metas guiadas | "Siempre hay algo a punto de pasar" | Ninguna | Tiempo al primer manager y al primer umbral |
| 4 | Promesa de volver | Minuto 10 a 20 | El juego dice: "Tus calcetines siguen trabajando 4 horas aunque cierres". Aquí se pide permiso para notificaciones, con un motivo claro | Confianza, no presión | Ninguna | Aceptación de notificaciones, sesiones del día 0 |
| 5 | Primer regreso | Horas después, día 0 o 1 | Ventana de bienvenida con lo ganado. Aquí aparece la primera oferta de anuncio: "×2 a lo ganado" y el boost de 4 horas | Sorpresa agradable | Primer anuncio opcional | `offline_claim`, aceptación de anuncios |
| 6 | Primer Centrifugado | Entre 45 y 90 min de juego acumulado, normalmente día 1 o 2 | Pantalla de prestigio con el antes y después. La lavadora gira, dos calcetines se reencuentran y el multiplicador sube | El momento emotivo del juego | Paquete de inicio, una sola vez, justo después | Tiempo al primer prestigio, `prestige` |
| 7 | Rutina | Días 2 a 7 | Ciclos de prestigio cada vez más rápidos (1.5 a 2 veces). Regalo diario, boost de anuncio y metas. Los negocios 8 a 10 se desbloquean | Dominio y progreso | Pase VIP, solo después de aceptar varios anuncios; multiplicador permanente | Retención día 1 y día 7 |
| 8 | Compromiso | Semanas 2 a 4 | Eventos de temporada, estampados y accesorios, ampliar el tope offline, segundo mundo en v1.1 | Colección y novedad | Estampados, Botones Dorados | Compradores sobre jugadores activos, ingreso por usuario |
| 9 | Riesgo de abandono | Cuando la progresión se aplana | El juego avisa que se acerca un buen momento de Centrifugado; una notificación al día como máximo | Que el calcetín "te extraña", sin culpa | Ninguna | Usuarios inactivos 3 y 7 días |

**Reglas del recorrido:**

- No se muestra ningún anuncio antes de que el jugador haya vivido su primer regreso (etapa 5).
- La primera oferta de compra aparece después del primer Centrifugado, nunca antes.
- La calificación en la tienda se pide una sola vez, tras el tercer Centrifugado, nunca después de un anuncio o una compra.
- Todo recorrido funciona sin conexión salvo la nube, los eventos y la tienda.
- En ninguna etapa el jugador pierde progreso. Si algo falla, el juego restaura la copia anterior (9.7).

### 9.11 Navegación

La navegación es una barra inferior de cinco pestañas (Negocios, Mejoras, Centrifugado, Metas y Tienda), una barra superior fija con las monedas y un engranaje que abre Ajustes. Todo lo demás son ventanas emergentes.

*(Diagrama del mapa de navegación omitido en la exportación; ver el párrafo anterior y 9.12.)*

El diagrama es el resumen; el detalle de cada pantalla está en 9.12.

**Reglas de navegación:**

- La pestaña activa se recuerda entre sesiones; al abrir la app siempre se entra a Negocios.
- El botón Atrás de Android cierra la ventana emergente; si no hay ninguna, vuelve a Negocios; desde Negocios pide un segundo toque para salir.
- Nunca hay más de una ventana emergente a la vez: las demás esperan en una cola con prioridad (bienvenida offline, meta completada, oferta de anuncio, calificación).
- Ninguna ventana emergente aparece durante los primeros 10 minutos, salvo el tutorial (9.10).
- Todos los botones tienen un área táctil de al menos 48 dp, y el tamaño de letra se puede aumentar en Ajustes.

### 9.12 Detalle por pantalla

| Pantalla | Qué muestra | Qué puede hacer el jugador | Reglas y estados especiales |
| --- | --- | --- | --- |
| Negocios (principal) | Barra superior; lista vertical de 10 tarjetas. Cada una: ícono animado, nombre, cantidad, barra de ciclo con el tiempo restante, ingreso por ciclo, próximo umbral con su premio y botón Comprar con su costo | Tocar la tarjeta inicia el ciclo si no hay manager; elegir cantidad (x1, x10, x100, Siguiente umbral, Max); mantener presionado Comprar compra en ráfaga; abrir el manager del negocio | Un solo selector de cantidad para toda la lista, que se recuerda. Si no alcanza el dinero, el botón se ve atenuado y muestra cuánto falta. Los negocios aún no desbloqueados aparecen como silueta con su costo. Con ciclos menores de 0.25 s la barra se ve llena y muestra $/s. Al cruzar un umbral hay una animación breve |
| Mejoras | Tres subpestañas: Managers (tarjeta con el calcetín, estampado, accesorio, nombre y costo), Upgrades (ordenados por costo) y Umbrales (progreso de cada negocio hacia 25, 50, 100… y su premio) | Comprar uno; Comprar todo lo asequible; tocar un umbral para ir a ese negocio | Los comprados quedan en gris con una palomita. Un punto en la pestaña avisa si hay algo asequible, sin números ni parpadeo |
| Centrifugado | Parejas Reunidas actuales, bono total actual, Parejas por cobrar, bono después y un indicador de buen momento (cuando por cobrar ≥ actuales). Debajo, la tienda de mejoras permanentes con su costo en Parejas | Centrifugar; comprar mejoras permanentes | El botón está inactivo con 0 Parejas por cobrar. La confirmación dice qué se pierde (dinero, negocios, managers, upgrades) y qué se conserva (Parejas, Botones Dorados, compras, estampados), con Cancelar bien visible. La animación dura 3 a 4 s y se puede saltar tocando |
| Metas | Ruta guiada con nodos de meta y su recompensa; regalo diario | Reclamar recompensas; reclamar el regalo diario; ver un anuncio para mejorar el regalo | La racha diaria se pausa si faltas un día, no se reinicia a cero. Las recompensas gratis nunca bloquean el avance del juego |
| Tienda | Ofertas (Paquete de inicio, si sigue disponible), Pase VIP, Botones Dorados, multiplicadores permanentes, ampliar ganancias offline, estampados y accesorios, y un botón claramente etiquetado Ver un anuncio para un boost | Comprar; ver un anuncio; restaurar compras | Los precios en MXN vienen de Google Play. Cada producto dice exactamente qué da. Sin temporizadores falsos ni ofertas "últimas horas" inventadas |
| Ajustes | Formato de números (nombres, sufijos cortos o notación científica), música y efectos, vibración, notificaciones, cuenta de Google Play Games y nube, tamaño de letra, exportar e importar partida, reiniciar partida, ayuda y contacto, política de privacidad, créditos y versión | Cambiar cualquier ajuste; contactar a soporte | Reiniciar partida pide escribir la palabra REINICIAR. Exportar muestra el texto de la partida para copiarlo |
| Ventanas emergentes | Bienvenida offline (tiempo fuera y total ganado), oferta de anuncio (qué ganas y cuánto dura), confirmar Centrifugado, meta completada, compra exitosa, pedir calificación, error de conexión y tutorial | Recoger; Recoger ×2 viendo un anuncio; Ver o No, gracias; Cancelar o Confirmar | Todas se cierran tocando fuera, excepto la confirmación de Centrifugado. El error de conexión solo aparece en nube, tienda y eventos, con Reintentar; el juego sigue funcionando sin conexión |

**Tutorial:** tres pasos con una flecha hecha de hilo que señala el Tendedero, el botón Comprar y el primer manager. El jugador puede saltarlo en cualquier momento (AdCap añadió la opción de saltar pasos del tutorial en su versión 9.27).

## 10. Monetización: anuncios opcionales y compras justas

Regla de oro: el jugador nunca ve un anuncio que no pidió, y todo el contenido se puede completar sin pagar. Las compras ahorran tiempo, quitan anuncios o dan cosméticos. Esto responde directamente a las quejas #1 a #5 y #13 de la sección 7.

### 10.1 Anuncios recompensados (únicos permitidos)

| Ubicación | Recompensa | Límite |
| --- | --- | --- |
| Botón de boost | Cada vista suma 4 h de ×2 a todas las ganancias; máximo 12 h acumuladas | Tope de 12 h acumuladas (3 vistas con la reserva vacía); sin otro límite |
| Bienvenida offline | ×2 a lo ganado offline | 1 por regreso |
| Regalo diario | Un poco de moneda premium | 1 al día |
| Saltar espera | Avanza 15 min de producción (mini time warp) | 3 al día |

**Prohibido:** interstitials, banners, anuncios al abrir menús o al cambiar de pantalla, anuncios que se disparan solos al cerrar otro anuncio.

**Higiene de anuncios:** bloquear categorías de anunciantes sensibles en la mediación, activar modo "apto para familias" si la audiencia incluye menores (ver 10.4) y dar al jugador una forma de reportar un anuncio.

### 10.2 Compras in-app

| Producto | Tipo | Precio de referencia (MXN) | Qué incluye | Por qué es justo |
| --- | --- | --- | --- | --- |
| Pase VIP | Pago único | $149 | Recompensas de anuncios sin verlos, para siempre | Responde a la queja de la suscripción de US$14.99/mes |
| Paquete de inicio | Pago único, solo la primera vez | $49 | Botones Dorados + un estampado + un multiplicador permanente pequeño | Buen valor, se ofrece una sola vez |
| Botones Dorados (4 tamaños) | Consumible | $29 / $79 / $149 / $299 | Moneda premium para time warps, estampados y ampliar el tope de ganancias offline | Mismo contenido que se gana jugando, más rápido |
| Multiplicador permanente | Pago único por nivel | $99 / $199 / $349 | ×2 a todo, con tope de 3 compras | Tope explícito: el pago no rompe el balance |
| Ampliar ganancias offline | Se compra con Botones Dorados | Sin precio directo | Tope de 4 h → 8 h → 12 h → 24 h | Quien juega gratis también llega con Parejas Reunidas |
| Estampados y accesorios | Pago único | $29–$99 | Estampados, gorritos, lentes, fondos, animaciones de Centrifugado | Lo tierno vende cosméticos; no afecta poder |

**No hacer:** cajas aleatorias pagadas (loot boxes), suscripción para quitar anuncios, ofertas que interrumpen el juego, contadores de "última oportunidad" falsos.

### 10.3 Eventos sin pay-to-win

- Todas las metas de un evento deben poder completarse jugando gratis con 2–3 sesiones al día. El simulador lo verifica.
- En el MVP y v1.1, sin leaderboards globales. Si se agregan después: ligas de 30 jugadores de nivel similar, validación de servidor y recompensas cosméticas.

### 10.4 Menores de edad

**Recomendación: declarar la app para 13 años o más y no diseñada para niños.** Si algún grupo de edad objetivo incluye menores, Google Play exige cumplir su Política de Familias, que incluye usar solo SDK de anuncios autocertificados para familias ([Google Play Console](https://support.google.com/googleplay/android-developer/answer/9867159?hl=en)), y los anuncios deben poder cerrarse a los 5 segundos ([Programa de SDK de anuncios para familias](https://support.google.com/googleplay/android-developer/answer/12918983?hl=en)). Eso reduce las redes de anuncios disponibles y complica la monetización.

Mi razonamiento, que no es un dato de mercado verificado: los idle tycoon los juegan sobre todo adolescentes y adultos (AdCap aparece 16+ en Google Play, en la ficha regional consultada, y 9+ en App Store), y lo tierno funciona muy bien con adultos. Apuntar a 13+ te deja elegir la red de anuncios con libertad.

- **Qué hacer:** declarar 13+ en la consola, no usar personajes ni textos pensados para niños pequeños, y no pedir datos personales.
- **Riesgo:** Google puede revisar que el público declarado coincida con el contenido; una estética muy infantil podría obligarte a cumplir la política de familias.
- **Antes de decidir:** validar con la prueba cerrada y con la clasificación de contenido que te asigne Google. Si más adelante quieres una versión para niños, conviene que sea un juego aparte.

## 11. Arquitectura, arte con IA y fases de construcción

Recomiendo Flutter + Flame: un idle game es sobre todo UI (listas, botones, barras), Flutter es fuerte en eso, todo el proyecto es texto que Claude Code edita bien, y tiene paquetes oficiales de Google para anuncios y compras. La decisión final es tuya (sección 12).

### 11.1 Opciones de motor

| Motor | A favor | En contra |
| --- | --- | --- |
| Flutter + Flame (recomendado) | UI excelente; código 100% texto; paquetes oficiales `google_mobile_ads` e `in_app_purchase`; animación de sprites con Flame | Menos tutoriales de juegos que Unity |
| Godot 4 | Motor de juegos real, ligero, escenas en texto | Anuncios y compras dependen de plugins de la comunidad |
| Unity | El SDK de anuncios y mediación más maduro | Escenas y prefabs difíciles de editar para Claude Code; proyecto pesado |

### 11.2 Arquitectura

- **Núcleo de economía puro:** sin UI ni dependencias del motor. Una función `tick(estado, dt)` determinista, más funciones de compra, prestigio y offline. 100% cubierto con tests.
- **Configuración en JSON:** negocios, upgrades, unlocks, managers, mundos y textos. Cambiar el balance no requiere tocar código.
- **Servicios con interfaz y versión falsa (mock):** `SaveService`, `AdService`, `IapService`, `AnalyticsService`, `TimeService`. La UI y los tests usan mocks hasta la fase de monetización.
- **Simulador sin interfaz:** un script que juega solo con un bot "compra lo de mejor retorno" y reporta los tiempos a cada hito. Es la herramienta principal de balance.
- **Capa de UI:** solo lee el estado y llama acciones; nunca calcula economía.

**Metas de balance que el simulador debe cumplir (propuesta):**

| Hito | Tiempo objetivo |
| --- | --- |
| Comprar el negocio 2 | < 30 s |
| Primer manager | < 3 min |
| Desbloquear el negocio 10 | 40–60 min |
| Primer prestigio sugerido | 45–90 min |
| Volver al mismo punto tras un prestigio | 1.5–2× más rápido que la vez anterior |

### 11.3 Pipeline de arte con IA

1. **Hoja de estilo primero (la concreta está en 11.6):** paleta de 8–12 colores, proporciones (cabeza grande, ojos grandes), grosor de línea y tipo de sombreado. Se guarda como texto y como imagen de referencia.
2. **Personaje maestro:** generar el personaje principal en Gemini con fondo plano, varias vistas, y usarlo como referencia en cada prompt siguiente.
3. **Íconos de negocios:** 10 íconos con el mismo encuadre y fondo transparente.
4. **Animación:** para ciclos simples (respirar, trabajar, celebrar) conviene animación por huesos (Rive o Spine) a partir de una sola imagen; es más consistente que pedir cada cuadro a la IA. Para sprite sheets, generar 4–8 cuadros clave y limpiar en Aseprite.
5. **Lista de assets del MVP (versión concreta en 11.6):** ícono de app, personaje principal, 10 negocios (estático + animación "trabajando"), 10 managers (retrato), animación de prestigio, 1 fondo, íconos de UI y moneda.
6. **Derechos:** revisar los términos de uso comercial de cada herramienta de IA y no pedir estilos ni personajes de marcas registradas.

### 11.4 Fases para Claude Code

Una fase por sesión; no se avanza sin cumplir los criterios de aceptación.

1. **F0 — Base:** proyecto, estructura de carpetas, lint, CI, carga del JSON de configuración y clase de números grandes con tests.
2. **F1 — Economía:** núcleo puro con fórmulas de las secciones 3 y 9, tests y simulador. Criterio: el simulador cumple las metas de 11.2.
3. **F2 — Loop jugable:** pantalla principal con arte provisional: comprar (x1/x10/x100/Max), ciclos, managers, upgrades y unlocks.
4. **F3 — Persistencia:** guardado versionado, copias rotativas, ganancias offline, ventana de bienvenida y protección de reloj.
5. **F4 — Prestigio:** cálculo, pantalla antes/después y tienda de mejoras permanentes.
6. **F5 — Retención:** metas guiadas, tutorial que se puede saltar, ajustes de formato de números.
7. **F6 — Arte y sonido:** integrar sprites, animaciones, música, efectos y vibración.
8. **F7 — Monetización:** anuncios recompensados y compras in-app (primero mocks, luego SDKs reales en dispositivos de prueba) y analítica.
9. **F8 — Lanzamiento:** guardado en la nube, pulido, prueba cerrada en Google Play (Android primero; iOS queda para después) y soft launch en México. Con una cuenta de desarrollador personal creada después del 13 de noviembre de 2023, Google exige un mínimo de 12 testers durante 14 días seguidos antes de dar acceso a producción.
10. **F9 — v1.1:** segundo mundo y motor de eventos de temporada.

### 11.5 Prompt inicial sugerido para Claude Code

```markdown
Lee docs/GAME_SPEC.md completo. Es Calcetinópolis, un idle tycoon móvil de calcetines perdidos (Android primero, Flutter + Flame, solo español, precios en MXN). Vamos a construir la fase F0 y F1 únicamente.
- Las secciones 8 a 11 son requisitos; las 2 a 7 son contexto.
- El núcleo de economía debe ser lógica pura, sin dependencias de UI.
- Todo valor de balance vive en config/economy.json.
- Escribe tests para cada fórmula de las secciones 3.2 y 9.4.
- Construye el simulador de la sección 11.2 y muéstrame su reporte.
Antes de escribir código, propón la estructura de carpetas y espera mi aprobación.
```

### 11.6 Hoja de estilo de arte: calcetines tiernos

Esta hoja se guarda en `docs/ART_STYLE.md` y se pega al inicio de cada prompt de imagen, para que los 40 y tantos assets del MVP se vean de la misma familia.

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

## 12. Preguntas abiertas y fuentes

### 12.1 Decisiones tomadas antes de F0

- [x] Temática base elegida: Calcetines perdidos (sección 8.5)
- [x] ¿Motor: Flutter + Flame (recomendado), Godot o Unity?
- [x] ¿Público objetivo: 13+ o también menores? Define reglas de anuncios y compras (10.4).
- [x] ¿Idiomas del lanzamiento: solo español, o español e inglés desde el MVP?
- [x] ¿Lanzar primero en Android, iOS o ambos? (iOS requiere cuenta de Apple Developer de US$99/año).
- [x] ¿Tope de ganancias offline: 4 h base está bien o prefieres más generoso?
- [x] ¿Precios: en USD con conversión automática o con niveles pensados para México?

**Respuestas:**

- Motor: Flutter + Flame.
- Plataforma: Android primero.
- Idioma: solo español.
- Precios: MXN, con niveles pensados para México.
- Audiencia: 13+, sin dirigirse a menores.
- Anuncios: solo recompensados y opcionales.
- Compras: IAP justas, sin cajas sorpresa y sin suscripción para quitar anuncios.
- Tope offline: 4 h base, ampliable hasta 24 h.
- Notificaciones: se piden entre el minuto 10 y 20 de juego; máximo una al día.
- Nombre: Calcetinópolis.
- Formato de números: K, M, B, T, aa, ab… (ver 9.6).

### 12.2 Fuentes

- [AdVenture Capitalist en App Store](https://apps.apple.com/us/app/adventure-capitalist-tycoon/id927006017) — descripción, calificación, historial de versiones, precios de compras in-app, reseñas.
- [AdVenture Capitalist en Google Play](https://play.google.com/store/apps/details?id=com.kongregate.mobile.adventurecapitalist.google) — calificación, descargas, reseñas negativas sobre anuncios y respuestas del desarrollador.
- [Steam: anuncio del relanzamiento](https://steamcommunity.com/app/346900) — progreso no transferible, Flex Credits, reseñas de octubre 2026.
- [Steam: tramposos en leaderboards](https://steamcommunity.com/app/346900/discussions/0/1698300679762643168) y [progreso de evento perdido](https://steamcommunity.com/app/346900/discussions/0/4846526727957271766).
- [Steam: por qué la Tierra es imposible de completar](https://steamcommunity.com/app/346900/discussions/0/487870763318777936).
- [AdCap Wiki — Businesses](https://adventure-capitalist.fandom.com/wiki/Businesses) — tablas de negocios, coeficientes, umbrales.
- [AdCap Wiki — Angel Investors](https://adventure-capitalist.fandom.com/wiki/Angel_Investors) — fórmula y tabla de ángeles.
- [AdCap Wiki — Managers](https://adventure-capitalist.fandom.com/wiki/Managers) — tipos de managers.
- [AdCap Wiki — Mega Tickets](https://adventure-capitalist.fandom.com/wiki/Mega_Tickets), [Opt-In Boosts](https://adventure-capitalist.fandom.com/wiki/Opt-In_Boosts), [ProfitCaster](https://adventure-capitalist.fandom.com/wiki/ProfitCaster).
- [The Math of Idle Games, Part I — Anthony Pecorella](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-i) — fórmulas de costo, compra masiva y máximo asequible.
- [GamingHQ — reseña 2026](https://gaminghq.eu/2026/01/25/adventure-capitalist-review/) — eventos pay-to-win, balance de la Luna.
- [AppsMeNow — reseñas agregadas](https://appsmenow.com/reviews/74834-adventure-capitalist) y [JustUseApp](https://justuseapp.com/en/app/927006017/adventure-capitalist/reviews).
- [Notas de la versión 8.2.0](https://apkmirror.com/apk/hyper-hippo/adventure-capitalist/adventure-capitalist-8-2-0-release) — Capitalist Connections y Vaults.
- [Steam: estrategia de primer reinicio](https://steamcommunity.com/app/346900/discussions/0/618459109264157866).
- [PSNProfiles — exploit de reloj](https://psnprofiles.com/guide/7220-adventure-capitalist-trophy-guide).
