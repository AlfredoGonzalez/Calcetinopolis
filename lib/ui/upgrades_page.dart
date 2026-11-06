import 'package:flutter/material.dart';

import '../app/game_controller.dart';
import '../core/number_format.dart';
import 'art.dart';
import 'theme.dart';

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
          const TabBar(
            tabs: [
              Tab(text: 'Managers'),
              Tab(text: 'Upgrades'),
              Tab(text: 'Umbrales'),
            ],
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
      padding: const EdgeInsets.all(12),
      children: [
        for (final i in items)
          Builder(
            builder: (context) {
              final cfg = c.economy.config.businesses[i];
              final has = c.state.businesses[i].hasManager;
              final affordable = cfg.manager.cost <= c.state.money;
              return Card(
                color: has ? Palette.lint : Colors.white,
                child: ListTile(
                  leading: Art(
                    cfg.manager.portrait,
                    size: 48,
                    fallback: Icons.checkroom,
                  ),
                  title: Text(cfg.manager.name),
                  subtitle: Text(
                    '${cfg.manager.pattern} · automatiza ${cfg.name}',
                  ),
                  trailing: has
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : FilledButton(
                          key: Key('mgr-tab-$i'),
                          onPressed: affordable ? () => c.buyManager(i) : null,
                          child: Text(formatter.format(cfg.manager.cost)),
                        ),
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
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('buy-all-upgrades'),
              onPressed: c.buyAllAffordableUpgrades,
              child: const Text('Comprar todo lo asequible'),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final u in visible)
                Builder(
                  builder: (context) {
                    final bought = c.state.upgrades.contains(u.id);
                    final affordable = u.cost <= c.state.money;
                    return Card(
                      color: bought ? Palette.lint : Colors.white,
                      child: ListTile(
                        title: Text(u.name),
                        subtitle: Text(
                          u.target == 'all'
                              ? 'x${u.multiplier.toStringAsFixed(0)} a todas las ganancias'
                              : 'x${u.multiplier.toStringAsFixed(0)} a ${c.economy.config.businesses[c.economy.config.businessIndex(u.target)].name}',
                        ),
                        trailing: bought
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                            : FilledButton(
                                key: Key('upg-${u.id}'),
                                onPressed: affordable
                                    ? () => c.buyUpgrade(u.id)
                                    : null,
                                child: Text(formatter.format(u.cost)),
                              ),
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
      padding: const EdgeInsets.all(12),
      children: [
        for (var i = 0; i < c.state.businesses.length; i++)
          if (c.isRevealed(i))
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.economy.config.businesses[i].name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final t in thresholds)
                          Chip(
                            label: Text('$t'),
                            avatar: c.state.businesses[i].owned >= t
                                ? const Icon(Icons.check, size: 16)
                                : null,
                            backgroundColor: c.state.businesses[i].owned >= t
                                ? Palette.mint
                                : Palette.lint,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tienes ${c.state.businesses[i].owned}. Cada umbral reduce el ciclo a la mitad.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
