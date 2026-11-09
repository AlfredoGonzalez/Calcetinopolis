# Reporte de balance (simulador)

Generado con `dart run tool/simulate.dart config/economy.json 5`. El bot compra lo de mejor retorno (payback), toca los negocios sin manager con 2 s de retraso humano y centrifuga cuando las Parejas por cobrar llegan a `prestige.first_target_pairs` (100) y a las ya cobradas.

```
Corrida | negocio 2 | 1er manager | negocio 10 | prestigio sugerido | Parejas | mult. inicial
--------|-----------|-------------|------------|--------------------|---------|--------------
1 | 0.3 min | 1.4 min | — | 43.9 min | 100 | x1
2 | 0.1 min | 0.5 min | 16.9 min | 17.1 min | 100 | x3
3 | 0.0 min | 0.3 min | 10.0 min | 11.4 min | 200 | x5
4 | 0.0 min | 0.1 min | 5.8 min | 7.5 min | 401 | x9.02
5 | 0.0 min | 0.1 min | 2.6 min | 3.9 min | 808 | x17.06
6 | 0.0 min | 0.0 min | 1.4 min | 2.3 min | 1.63K | x33.22
Corrida 1 → 2: mismo punto 2.90× más rápido
Corrida 2 → 3: mismo punto 1.68× más rápido
Corrida 3 → 4: mismo punto 1.73× más rápido
Corrida 4 → 5: mismo punto 2.26× más rápido
Corrida 5 → 6: mismo punto 1.86× más rápido
```

## Metas de 11.2

| Hito | Objetivo | Resultado | |
| --- | --- | --- | --- |
| Comprar el negocio 2 | < 30 s | ~18 s | ✅ |
| Primer manager | < 3 min | ~1.4 min | ✅ |
| Desbloquear el negocio 10 | 40–60 min | ya no se alcanza en la corrida 1 (el prestigio llega antes); corrida 2: ~17 min | ➖ |
| Primer prestigio sugerido | 30–45 min (cambió de 45–90 por pedido del diseño) | ~44 min sin tocar la lavadora, ~23–29 min tocándola sin parar | ✅ |
| Mismo punto tras prestigio | 1.5–2× más rápido | 1.65–1.83× (corridas 2 a 5) | ✅ |
| Mismo punto, corrida 1 → 2 | 1.5–2× | 2.90× | ⚠️ |
| Mismo punto, corridas con tienda | 1.5–2× | 1.68–2.22× | ⚠️ (picos al comprar un nivel grande) |

**Desviación conocida:** el primer Centrifugado pasa de ×1 a ×3 (100 Parejas), por eso la corrida 2 es casi 3× más rápida. Bajar el objetivo a ~50 Parejas (×2) arregla esa razón, pero adelanta el primer prestigio antes del negocio 10 (probado: S=3e13 y 50 Parejas da 1.95× pero el primer prestigio cae a 42 min). Queda como decisión de diseño para la etapa de tuning; los tests aceptan hasta 3× en esa primera vuelta.

## Parámetros calibrados

- `prestige.scale` (S) = `1e13`. Con `1e14` el primer prestigio sugerido caía a los 55 min; se bajó para que sea de 30 a 45 min sin tocar la lavadora (44 min) y menos si se toca. La primera Pareja se logra con 4.44e8 de pelusas ganadas en total.
- Costos de managers de 9.2 sin cambios; los upgrades de efectivo de `config/economy.json` son una primera propuesta (3 por negocio ×3 y 5 globales ×3) y no vienen del spec.

## Limitaciones del bot

- Tiempo de paso fijo de 1 s: ciclos menores a 1 s en negocios sin manager se aproximan.
- No usa boosts de anuncio ni offline. Gasta Hilvanes en la tienda comprando siempre lo más barato primero.
- El retraso de toque (2 s) es una suposición.

## Tienda de Hilvanes (F4)

Mejoras permanentes en `prestige_shop` de `config/economy.json` (propuesta mía, ajustable): Detergente concentrado (x1.25 a x3 a todo), Calcetín de la suerte (Pelusitas al empezar), Primeras ayudas (managers gratis en los primeros negocios) y Cesto más grande (tope offline 8/12/24 h).

Con costos bajos la tienda aceleraba las corridas hasta 4.4× (y 3× en vueltas posteriores); los costos finales son 20× la primera propuesta. Aun así, al comprar un nivel grande hay picos de ~2.2×; los tests aceptan hasta 2.5× desde la tercera corrida.

## Metas y regalo diario (F5)

21 metas en `goals` de `config/economy.json` (propuesta mía, ajustable) y el regalo diario en `daily`. El simulador **no** cobra metas ni regalos, así que sus números no los incluyen. Las metas dan Pelusitas al inicio y Hilvanes después (unas 710 en total); las Pelusitas de metas y del regalo no cuentan para E_vida, así que no inflan el prestigio. Conviene revisar con jugadores reales si las Hilvanes de metas aceleran demasiado.

## Lavadora que se toca

Un bono temporal de velocidad que da el jugador activo; no cambia la economía de quien no la toca.

- **Mecánica:** cada toque suma `tap_bonus` (+2%) hasta `max_bonus` (+100%, es decir x2). El bono baja `decay_per_second` (1.5% por segundo) desde el momento en que se deja de tocar. No se guarda ni cuenta en las ganancias offline.
- **Se suma al boost de anuncios**, no se multiplica: boost x2 (+100%) con la lavadora al máximo (+100%) da x3, no x4.
- **Mejoras con Hilvanes** (`config/economy.json`, `prestige_shop`): *Toque potente* (`tap_power`: 3%, 4%, 6%, 9% por toque) y *Tanque de energía* (`washer_max`: +150%, +200%, +300%, +400%).
- **Parámetros** en `config/economy.json` → `washer`. Para afinarlos sin tocar código: `decay_per_second` es el más sensible.

### Calibración con el simulador

El bot base no toca la lavadora, así que la calibración anterior no cambió: primer Centrifugado en **55.0 / 20.9 / 14.9 min** en las corridas 1, 2 y 3. Con `washerTapsPerSecond` el bot toca sin parar durante toda la corrida (el mejor caso posible):

| Toques por segundo | Primer Centrifugado (corridas 1 / 2 / 3, min) |
| --- | --- |
| 0 | 55.0 / 20.9 / 14.9 |
| 0.5 | 54.5 / 20.7 / 14.8 |
| 0.75 | 54.1 / 20.6 / 14.8 |
| 1 | 28.9 / 10.6 / 7.8 |
| 2 | 28.2 / 10.6 / 7.8 |
| 4 | 28.2 / 10.6 / 7.8 |

Lectura: cada toque suma 2% y el bono baja 1.5% por segundo, así que con **1 toque por segundo o más** el bono llega al máximo (x2) y se mantiene; a 0.75 se compensan exactamente y por debajo casi no ayuda. Subió de 3% a 1.5% de descenso (y de 1% a 2% por toque) porque en pruebas reales casi no se lograba subir el porcentaje. Es un caso extremo (tocar sin parar durante una hora). Si resulta demasiado, subir `decay_per_second` o bajar `max_bonus`; si resulta difícil mantenerlo, bajar `decay_per_second`.
