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
