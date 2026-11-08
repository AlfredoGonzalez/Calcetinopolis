import 'package:flutter/material.dart';

import '../app/game_controller.dart';
import '../core/number_format.dart';
import 'art.dart';
import 'theme.dart';
import 'ui_kit.dart';

/// Mejoras: Managers, Upgrades y Umbrales (spec 9.12).
class UpgradesPage extends StatelessWidget {
  const UpgradesPage({
    super.key,
    required this.controller,
    required this.formatter,
  });

  final GameController controller;
  final NumberFormatter formatter;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: PillTabBar(labels: ['Managers', 'Upgrades', 'Umbrales']),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _Managers(controller: controller, formatter: formatter),
                _Upgrades(controller: controller, formatter: formatter),
                _Thresholds(controller: controller),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Managers extends StatelessWidget {
  const _Managers({required this.controller, required this.formatter});
  final GameController controller;
  final NumberFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final items = <int>[
      for (var i = 0; i < c.state.businesses.length; i++)
        if (c.isRevealed(i)) i,
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Text(
            'Los managers cobran y reinician el negocio por ti, incluso cuando la app está cerrada.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Ui.ink2,
            ),
          ),
        ),
        for (final i in items)
          Builder(
            builder: (context) {
              final cfg = c.economy.config.businesses[i];
              final has = c.state.businesses[i].hasManager;
              final affordable = cfg.manager.cost <= c.state.money;
              final accent = Ui.accent(i);
              return UiCard(
                edge: has || affordable ? Ui.soft(accent) : Ui.disabled,
                child: Row(
                  children: [
                    AccentBadge(
                      color: accent,
                      child: Art(
                        cfg.manager.portrait,
                        size: 46,
                        fallback: Icons.checkroom,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cfg.manager.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${cfg.manager.pattern} · automatiza ${cfg.name}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Ui.ink2,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (has)
                      const ChunkyButton(
                        label: 'Contratado',
                        detail: 'Listo',
                        width: 96,
                        onPressed: null,
                      )
                    else
                      ChunkyButton(
                        key: Key('mgr-tab-$i'),
                        label: 'Contratar',
                        detail: formatter.format(cfg.manager.cost),
                        width: 96,
                        onPressed: affordable ? () => c.buyManager(i) : null,
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _Upgrades extends StatelessWidget {
  const _Upgrades({required this.controller, required this.formatter});
  final GameController controller;
  final NumberFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final all = c.economy.config.upgrades.toList()
      ..sort((a, b) => a.cost.compareTo(b.cost));
    final visible = all.where((u) {
      if (c.state.upgrades.contains(u.id)) return true;
      if (u.target == 'all') return true;
      return c
              .state
              .businesses[c.economy.config.businessIndex(u.target)]
              .owned >
          0;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('buy-all-upgrades'),
              onPressed: c.buyAllAffordableUpgrades,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Comprar todo lo asequible'),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              for (final u in visible)
                Builder(
                  builder: (context) {
                    final bought = c.state.upgrades.contains(u.id);
                    final affordable = u.cost <= c.state.money;
                    final isAll = u.target == 'all';
                    final bi = isAll
                        ? 0
                        : c.economy.config.businessIndex(u.target);
                    final accent = isAll ? Ui.yellow : Ui.accent(bi);
                    return UiCard(
                      edge: bought || affordable
                          ? Ui.soft(accent)
                          : Ui.disabled,
                      child: Row(
                        children: [
                          AccentBadge(
                            color: accent,
                            child: isAll
                                ? const Icon(
                                    Icons.auto_awesome,
                                    size: 28,
                                    color: Ui.ink,
                                  )
                                : Art(
                                    c.economy.config.businesses[bi].art,
                                    size: 44,
                                    fallback: Icons.bolt,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  u.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isAll
                                      ? 'x${u.multiplier.toStringAsFixed(0)} a todas las ganancias'
                                      : 'x${u.multiplier.toStringAsFixed(0)} a ${c.economy.config.businesses[bi].name}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Ui.ink2,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (bought)
                            const ChunkyButton(
                              label: 'Comprada',
                              detail: 'Lista',
                              width: 96,
                              onPressed: null,
                            )
                          else
                            ChunkyButton(
                              key: Key('upg-${u.id}'),
                              label: 'Comprar',
                              detail: formatter.format(u.cost),
                              width: 96,
                              onPressed: affordable
                                  ? () => c.buyUpgrade(u.id)
                                  : null,
                            ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Thresholds extends StatelessWidget {
  const _Thresholds({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final thresholds = c.economy.config.thresholds;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        for (var i = 0; i < c.state.businesses.length; i++)
          if (c.isRevealed(i))
            UiCard(
              edge: Ui.soft(Ui.accent(i)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AccentBadge(
                        color: Ui.accent(i),
                        size: 40,
                        child: Art(
                          c.economy.config.businesses[i].art,
                          size: 32,
                          fallback: Icons.store,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          c.economy.config.businesses[i].name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final t in thresholds)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: c.state.businesses[i].owned >= t
                                ? Ui.tealSoft
                                : Ui.track,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (c.state.businesses[i].owned >= t) ...[
                                const Icon(Icons.check, size: 14),
                                const SizedBox(width: 3),
                              ],
                              Text(
                                '$t',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tienes ${c.state.businesses[i].owned}. Cada umbral reduce el ciclo a la mitad.',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Ui.ink2,
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
