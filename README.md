# Calcetinópolis

Idle tycoon móvil de calcetines perdidos, inspirado en AdVenture Capitalist. Android primero, solo en español, precios en MXN, anuncios 100% opcionales y compras in-app justas.

**Premisa:** los calcetines que desaparecen de las lavadoras viven en un mundo secreto, y cada uno sueña con reencontrar a su pareja. Tú eres un calcetín emprendedor. Reiniciar es un *Centrifugado*: dos calcetines se reencuentran y ganas Parejas Reunidas (+2% a todo).

## Documentación

- [`docs/GAME_SPEC.md`](docs/GAME_SPEC.md): especificación completa. Secciones 2–7 son contexto; 8–11 son requisitos y mandan si hay conflicto.
- [`docs/ART_STYLE.md`](docs/ART_STYLE.md): hoja de estilo para el arte con IA.

## Decisiones clave

Flutter + Flame · Android primero · solo español · MXN · 13+ · anuncios solo recompensados · sin loot boxes ni suscripción · offline 4 h base (hasta 24 h). Ver 12.1 del spec.

## Plan de construcción

Una fase por sesión (sección 11.4 del spec): F0 base, F1 economía y simulador, F2 loop jugable, F3 persistencia, F4 prestigio, F5 retención, F6 arte y sonido, F7 monetización, F8 lanzamiento, F9 v1.1.

**Estado:** F0 a F4 listas (base, economía, loop jugable, guardado/offline y prestigio con tienda de Hilvanes). Siguiente: F5, retención (metas, tutorial, ajustes).

## Desarrollo

```bash
flutter pub get
flutter test                                # fórmulas, motor, config y metas del simulador
dart run tool/simulate.dart config/economy.json 5   # reporte de balance
```

Estructura: `lib/app` (controlador), `lib/ui` (pantallas), `lib/core` (lógica pura: `big_num`, `economy/`, `config/`, `sim/`), `lib/services` (interfaces y mocks), `config/economy.json` (todo el balance), `docs/BALANCE.md` (reporte del simulador).

## Reglas del proyecto

- El núcleo de economía es lógica pura, sin UI; la UI solo lee estado y llama acciones.
- Todo valor de balance vive en `config/economy.json`, nunca en código.
- Cada fórmula de las secciones 3.2 y 9.4 tiene tests.
