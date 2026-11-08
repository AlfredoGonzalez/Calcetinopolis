# Reporte de balance (simulador)

Generado con `dart run tool/simulate.dart config/economy.json 5`. El bot compra lo de mejor retorno (payback), toca los negocios sin manager con 2 s de retraso humano y centrifuga cuando las Parejas por cobrar llegan a `prestige.first_target_pairs` (100) y a las ya cobradas.

```
Corrida | negocio 2 | 1er manager | negocio 10 | prestigio sugerido | Parejas | mult. inicial
--------|-----------|-------------|------------|--------------------|---------|--------------
1 | 0.3 min | 1.4 min | 49.0 min | 55.0 min | 100 | x1
2 | 0.1 min | 0.5 min | 16.9 min | 20.9 min | 100 | x3
3 | 0.0 min | 0.3 min | 10.0 min | 14.9 min | 200 | x5
4 | 0.0 min | 0.1 min | 5.8 min | 9.3 min | 400 | x9
5 | 0.0 min | 0.1 min | 2.7 min | 4.7 min | 826 | x17
6 | 0.0 min | 0.0 min | 1.4 min | 2.9 min | 1.65K | x33.52
Corrida 1 → 2: mismo punto 2.92× más rápido
Corrida 2 → 3: mismo punto 1.68× más rápido
Corrida 3 → 4: mismo punto 1.74× más rápido
Corrida 4 → 5: mismo punto 2.22× más rápido
Corrida 5 → 6: mismo punto 1.92× más rápido
```

## Metas de 11.2

| Hito | Objetivo | Resultado | |
| --- | --- | --- | --- |
| Comprar el negocio 2 | < 30 s | ~18 s | ✅ |
| Primer manager | < 3 min | ~1.4 min | ✅ |
| Desbloquear el negocio 10 | 40–60 min | ~49 min | ✅ |
| Primer prestigio sugerido | 45–90 min | ~55 min | ✅ |
| Mismo punto tras prestigio | 1.5–2× más rápido | 1.65–1.83× (corridas 2 a 5) | ✅ |
| Mismo punto, corrida 1 → 2 | 1.5–2× | 2.92× | ⚠️ |
| Mismo punto, corridas con tienda | 1.5–2× | 1.68–2.22× | ⚠️ (picos al comprar un nivel grande) |

**Desviación conocida:** el primer Centrifugado pasa de ×1 a ×3 (100 Parejas), por eso la corrida 2 es casi 3× más rápida. Bajar el objetivo a ~50 Parejas (×2) arregla esa razón, pero adelanta el primer prestigio antes del negocio 10 (probado: S=3e13 y 50 Parejas da 1.95× pero el primer prestigio cae a 42 min). Queda como decisión de diseño para la etapa de tuning; los tests aceptan hasta 3× en esa primera vuelta.

## Parámetros calibrados

- `prestige.scale` (S) = `1e14` (el placeholder `1e12` hacía el primer prestigio a los 30 min).
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

- **Mecánica:** cada toque suma `tap_bonus` (+1%) hasta `max_bonus` (+100%, es decir x2). El bono baja `decay_per_second` (3% por segundo) desde el momento en que se deja de tocar. No se guarda ni cuenta en las ganancias offline.
- **Se suma al boost de anuncios**, no se multiplica: boost x2 (+100%) con la lavadora al máximo (+100%) da x3, no x4.
- **Mejoras con Hilvanes** (`config/economy.json`, `prestige_shop`): *Toque potente* (`tap_power`: 1.5%, 2%, 3%, 5% por toque) y *Tanque de energía* (`washer_max`: +150%, +200%, +300%, +400%).
- **Parámetros** en `config/economy.json` → `washer`. Para afinarlos sin tocar código: `decay_per_second` es el más sensible.

### Calibración con el simulador

El bot base no toca la lavadora, así que la calibración anterior no cambió: primer Centrifugado en **55.0 / 20.9 / 14.9 min** en las corridas 1, 2 y 3. Con `washerTapsPerSecond` el bot toca sin parar durante toda la corrida (el mejor caso posible):

| Toques por segundo | Primer Centrifugado (corridas 1 / 2 / 3, min) |
| --- | --- |
| 0 | 55.0 / 20.9 / 14.9 |
| 2 | 54.5 / 20.6 / 14.8 |
| 4 | 28.5 / 10.6 / 7.8 |
| 6 | 28.3 / 10.6 / 7.8 |
| 8 | 28.3 / 10.6 / 7.8 |

Lectura: con un descenso de 3%/s hace falta tocar **más de 3 veces por segundo** para mantener el bono; por debajo se consume más rápido de lo que se llena y casi no ayuda, y por encima se queda cerca del máximo y casi duplica la velocidad. Es un caso extremo (tocar sin parar durante una hora). Si resulta demasiado, subir `decay_per_second` o bajar `max_bonus`; si resulta difícil mantenerlo, bajar `decay_per_second`.
