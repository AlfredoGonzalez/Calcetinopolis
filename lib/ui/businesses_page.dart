import 'dart:async';

import 'package:flutter/material.dart';

import '../app/game_controller.dart';
import '../core/number_format.dart';
import 'art.dart';
import 'effects.dart';
import 'sprite_sheet.dart';
import 'theme.dart';
import 'washer_card.dart';

const _amountLabels = {
  BuyAmount.one: 'x1',
  BuyAmount.ten: 'x10',
  BuyAmount.hundred: 'x100',
  BuyAmount.nextThreshold: 'Umbral',
  BuyAmount.max: 'Max',
};

class BusinessesPage extends StatelessWidget {
  const BusinessesPage({
    super.key,
    required this.controller,
    required this.formatter,
  });

  final GameController controller;
  final NumberFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final count = c.state.businesses.length;
    return Stack(
      children: [
        // Fondo del cuarto de lavado, atenuado para que las tarjetas se lean.
        Positioned.fill(
          child: Opacity(
            opacity: 0.22,
            child: Image.asset(
              Art.bgRoom,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
        Positioned.fill(child: FloatingLint(time: c.fxTime)),
        _content(c, count),
      ],
    );
  }

  Widget _content(GameController c, int count) {
    return Column(
      children: [
        _TutorialBanner(controller: c),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
          child: WasherCard(controller: c),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: _AmountPicker(selected: c.amount, onPick: c.setAmount),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: count,
            itemBuilder: (context, i) {
              if (c.isRevealed(i) || c.isNextToUnlock(i)) {
                return BusinessCard(
                  controller: c,
                  index: i,
                  formatter: formatter,
                );
              }
              return _LockedCard(controller: c, index: i, formatter: formatter);
            },
          ),
        ),
      ],
    );
  }
}

class _LockedCard extends StatelessWidget {
  const _LockedCard({
    required this.controller,
    required this.index,
    required this.formatter,
  });
  final GameController controller;
  final int index;
  final NumberFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final cfg = controller.economy.config.businesses[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Ui.bg2,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Ui.disabled, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Ui.disabled,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Silueta del negocio: se ve qué viene, pero no cuál es.
                ColorFiltered(
                  key: Key('silhouette-$index'),
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF9A8F88),
                    BlendMode.srcATop,
                  ),
                  child: Art(cfg.art, size: 46),
                ),
                const Positioned(
                  right: 3,
                  bottom: 3,
                  child: Icon(Icons.lock, size: 18, color: Ui.disabledInk),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '???',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Ui.disabledInk,
                ),
              ),
              Text(
                'Cuesta ${formatter.format(cfg.baseCost)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Ui.disabledInk,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BusinessCard extends StatelessWidget {
  const BusinessCard({
    super.key,
    required this.controller,
    required this.index,
    required this.formatter,
  });

  final GameController controller;
  final int index;
  final NumberFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final eco = c.economy;
    final cfg = eco.config.businesses[index];
    final b = c.state.businesses[index];
    final owned = b.owned > 0;
    final cycle = owned
        ? eco.cycleSeconds(c.state, index)
        : cfg.baseCycleSeconds;
    final fast = cycle < 0.25 && b.hasManager;
    final canBuy = c.canBuy(index);
    final toNext = eco.unitsToNextThreshold(c.state, index);
    final remaining = b.running || b.hasManager
        ? (1 - b.progress) * cycle
        : cycle;

    final income = owned ? eco.incomePerCycle(c.state, index) : cfg.baseIncome;
    final level = eco.config.thresholds.where((t) => b.owned >= t).length;
    final accent = Ui.accent(index);

    return ThresholdFx(
      level: level,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: Ui.soft(accent), offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: Key('card-$index'),
              onTap: owned ? () => c.tap(index) : null,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // El arte del negocio, a todo lo alto de la tarjeta.
                    Container(
                      width: 112,
                      color: Ui.soft(accent).withValues(alpha: 0.55),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          WorkingBob(
                            active:
                                owned && !fast && (b.running || b.hasManager),
                            progress: b.progress,
                            child: Art(
                              cfg.art,
                              size: 100,
                              fallback: Icons.store,
                            ),
                          ),
                          Positioned(
                            left: 8,
                            top: 8,
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 28),
                              height: 28,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Ui.ink,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                'x${b.owned}',
                                key: Key('owned-$index'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      cfg.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        height: 1.15,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _ManagerSlot(
                                  key: Key('manager-$index'),
                                  index: index,
                                  controller: c,
                                  formatter: formatter,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      minHeight: 12,
                                      value: fast
                                          ? 1
                                          : (owned ? b.progress : 0),
                                      color: accent,
                                      backgroundColor: Ui.track,
                                    ),
                                  ),
                                ),
                                if (!fast && owned) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '${remaining.toStringAsFixed(1)} s',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Ui.ink2,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                fast
                                    ? '${formatter.format(eco.incomePerSecond(c.state, index))}/s'
                                    : '${formatter.format(income)} por ciclo',
                                if (toNext != null && owned)
                                  'faltan $toNext p/ x2',
                              ].join(' · '),
                              key: Key('income-$index'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Ui.ink2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _BuyButton(
                              key: Key('buy-$index'),
                              enabled: canBuy,
                              label: 'Comprar ${c.unitsFor(index)}',
                              detail: canBuy
                                  ? formatter.format(c.costFor(index))
                                  : 'Faltan ${formatter.format(c.missing(index))}',
                              onTap: () => c.buy(index),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// El manager del negocio: su silueta mientras no se contrata (se toca para
/// contratarlo si alcanzan las Pelusitas) y su retrato con una palomita cuando
/// ya trabaja.
class _ManagerSlot extends StatelessWidget {
  const _ManagerSlot({
    super.key,
    required this.index,
    required this.controller,
    required this.formatter,
  });

  final int index;
  final GameController controller;
  final NumberFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final cfg = c.economy.config.businesses[index];
    final b = c.state.businesses[index];
    final hired = b.hasManager;
    final owned = b.owned > 0;
    final affordable = owned && cfg.manager.cost <= c.state.money;
    final portrait = cfg.manager.portrait;
    final ringColor = hired ? Ui.teal : (affordable ? Ui.orange : Ui.disabled);

    Widget face = portrait == null
        ? const Icon(Icons.person, color: Ui.ink2)
        : Art(portrait, size: 46, fallback: Icons.person);
    if (!hired) {
      face = ColorFiltered(
        colorFilter: ColorFilter.mode(
          owned ? const Color(0xFF8E8A9A) : const Color(0xFFC5C0BA),
          BlendMode.srcATop,
        ),
        child: face,
      );
    }

    return Semantics(
      button: !hired,
      label: hired
          ? 'Manager contratado: ${cfg.manager.name}'
          : 'Contratar manager: ${cfg.manager.name}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: hired
            ? null
            : () {
                if (!owned) return;
                if (affordable) {
                  c.buyManager(index);
                } else {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(
                          'Para contratar a ${cfg.manager.name} necesitas '
                          '${formatter.format(cfg.manager.cost)} Pelusitas',
                        ),
                      ),
                    );
                }
              },
        child: SizedBox(
          width: 56,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    key: hired ? Key('manager-hired-$index') : null,
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hired ? Ui.tealSoft : const Color(0xFFF1ECE2),
                      border: Border.all(color: ringColor, width: 3),
                      boxShadow: affordable
                          ? [
                              BoxShadow(
                                color: Ui.orange.withValues(alpha: 0.45),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: ClipOval(child: face),
                  ),
                  if (hired)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Ui.teal,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              if (!hired && owned)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    formatter.format(cfg.manager.cost),
                    key: Key('manager-cost-$index'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: affordable ? Ui.tealEdge : Ui.ink2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón de compra: mantener presionado compra en ráfaga (spec 9.12).
class _BuyButton extends StatefulWidget {
  const _BuyButton({
    super.key,
    required this.enabled,
    required this.label,
    required this.detail,
    required this.onTap,
  });
  final bool enabled;
  final String label;
  final String detail;
  final VoidCallback onTap;

  @override
  State<_BuyButton> createState() => _BuyButtonState();
}

class _BuyButtonState extends State<_BuyButton> {
  Timer? _burst;

  void _stop() {
    _burst?.cancel();
    _burst = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.enabled;
    return GestureDetector(
      onLongPressStart: on
          ? (_) {
              widget.onTap();
              _burst = Timer.periodic(
                const Duration(milliseconds: 120),
                (_) => widget.onTap(),
              );
            }
          : null,
      onLongPressEnd: (_) => _stop(),
      onLongPressCancel: _stop,
      child: Container(
        decoration: BoxDecoration(
          color: on ? Ui.teal : Ui.disabled,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: on ? Ui.tealEdge : Ui.disabledInk.withValues(alpha: 0.5),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: on ? widget.onTap : null,
            child: Container(
              constraints: const BoxConstraints(minHeight: 54),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: on ? Ui.ink : Ui.disabledInk,
                    ),
                  ),
                  Text(
                    widget.detail,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: on ? Ui.ink : Ui.disabledInk,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Selector de cuántas unidades comprar: píldora blanca con la opción activa
/// en azul marino.
class _AmountPicker extends StatelessWidget {
  const _AmountPicker({required this.selected, required this.onPick});

  final BuyAmount selected;
  final ValueChanged<BuyAmount> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        boxShadow: const [
          BoxShadow(color: Ui.orangeSoft, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          for (final e in _amountLabels.entries)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onPick(e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: e.key == selected ? Ui.ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Text(
                    e.value,
                    key: Key('amount-${e.key.name}'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: e.key == selected ? Colors.white : Ui.ink,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tutorial de 3 pasos con una flecha de hilo (spec 9.12). Se puede saltar en cualquier momento.
class _TutorialBanner extends StatelessWidget {
  const _TutorialBanner({required this.controller});
  final GameController controller;

  static const _texts = [
    'Toca el Tendedero para ganar tus primeras Pelusitas.',
    'Compra otro Tendedero con el botón verde.',
    'Contrata a tu primer manager: trabaja solo, incluso con la app cerrada.',
  ];

  @override
  Widget build(BuildContext context) {
    final step = controller.tutorialStep;
    if (step == null) return const SizedBox.shrink();
    return Container(
      key: const Key('tutorial'),
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: Ui.yellow.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Ui.yellow, width: 2),
      ),
      child: Row(
        children: [
          const SpriteSheet(
            asset: 'assets/art/spr_mascota_idle_4x4.png',
            frameSize: Size(209, 309),
            columns: 4,
            rows: 4,
            fps: 8,
            scale: 0.17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Paso ${step + 1} de 3: ${_texts[step]}',
              key: const Key('tutorial-text'),
            ),
          ),
          TextButton(
            key: const Key('tutorial-skip'),
            onPressed: controller.skipTutorial,
            child: const Text('Saltar'),
          ),
        ],
      ),
    );
  }
}
