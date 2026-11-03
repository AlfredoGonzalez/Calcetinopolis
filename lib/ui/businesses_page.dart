import 'dart:async';

import 'package:flutter/material.dart';

import '../app/game_controller.dart';
import '../core/number_format.dart';
import 'theme.dart';

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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SegmentedButton<BuyAmount>(
            showSelectedIcon: false,
            segments: [
              for (final e in _amountLabels.entries)
                ButtonSegment(
                  value: e.key,
                  label: Text(e.value, key: Key('amount-${e.key.name}')),
                ),
            ],
            selected: {c.amount},
            onSelectionChanged: (s) => c.setAmount(s.first),
          ),
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
    return Card(
      color: Palette.lint,
      child: ListTile(
        leading: const Icon(Icons.lock, color: Palette.outline),
        title: const Text('???'),
        subtitle: Text('Cuesta ${formatter.format(cfg.baseCost)}'),
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

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        key: Key('card-$index'),
        borderRadius: BorderRadius.circular(12),
        onTap: owned ? () => c.tap(index) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Palette.mint,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Palette.outline),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cfg.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    'x${b.owned}',
                    key: Key('owned-$index'),
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  minHeight: 16,
                  value: fast ? 1 : (owned ? b.progress : 0),
                  color: Palette.blue,
                  backgroundColor: Palette.lint,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    fast
                        ? '${formatter.format(eco.incomePerSecond(c.state, index))}/s'
                        : '${formatter.format(income)} por ciclo',
                    key: Key('income-$index'),
                  ),
                  if (!fast && owned) Text('${remaining.toStringAsFixed(1)} s'),
                ],
              ),
              if (toNext != null && owned)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Faltan $toNext para el doble de velocidad',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _BuyButton(
                      key: Key('buy-$index'),
                      enabled: canBuy,
                      label: 'Comprar ${c.unitsFor(index)}',
                      detail: canBuy
                          ? formatter.format(c.costFor(index))
                          : 'Faltan ${formatter.format(c.missing(index))}',
                      onTap: () => c.buy(index),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (owned && !b.hasManager)
                    OutlinedButton(
                      key: Key('manager-$index'),
                      onPressed: cfg.manager.cost <= c.state.money
                          ? () => c.buyManager(index)
                          : null,
                      child: Text(
                        'Manager\n${formatter.format(cfg.manager.cost)}',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else if (b.hasManager)
                    const Chip(
                      label: Text('Manager ✓'),
                      backgroundColor: Palette.mint,
                    ),
                ],
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
    final bg = widget.enabled ? Palette.tomato : Palette.lint;
    return GestureDetector(
      onLongPressStart: widget.enabled
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
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: widget.enabled ? widget.onTap : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.enabled ? Colors.white : Palette.outline,
                  ),
                ),
                Text(
                  widget.detail,
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.enabled ? Colors.white : Palette.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
