import 'package:flutter/material.dart';

import '../app/game_controller.dart';
import '../core/number_format.dart';
import 'art.dart';
import 'theme.dart';

/// Metas guiadas y regalo diario (spec 9.12).
class GoalsPage extends StatelessWidget {
  const GoalsPage({
    super.key,
    required this.controller,
    required this.formatter,
  });

  final GameController controller;
  final NumberFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final eco = c.economy;
    final goals = eco.config.goals;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (eco.config.daily != null)
          _DailyCard(controller: c, formatter: formatter),
        const SizedBox(height: 8),
        Text('Ruta de metas', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        const Text(
          'Las recompensas son gratis y nunca bloquean el avance del juego.',
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < goals.length; i++)
          _GoalTile(controller: c, index: i, formatter: formatter),
      ],
    );
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.controller, required this.formatter});
  final GameController controller;
  final NumberFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final can = c.canClaimDaily;
    final preview = c.economy.dailyPreview(c.state);
    return Card(
      color: Palette.butter,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Art(
                  'icon_ui_regalo',
                  size: 40,
                  fallback: Icons.card_giftcard,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Regalo diario',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                Chip(
                  key: const Key('streak'),
                  label: Text('Racha: ${c.state.dailyStreak}'),
                  backgroundColor: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Hoy: ${formatter.format(preview.money)} Pelusitas'
              '${preview.hilvanes.isPositive ? ' y ${formatter.format(preview.hilvanes)} Hilvanes' : ''}',
              key: const Key('daily-preview'),
            ),
            const Text(
              'Si faltas un día, tu racha se pausa; no vuelve a cero.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('daily-claim'),
                onPressed: can
                    ? () {
                        final r = c.claimDaily();
                        if (r != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '¡Regalo recogido! Racha ${r.streak}',
                              ),
                            ),
                          );
                        }
                      }
                    : null,
                child: Text(can ? 'Recoger regalo' : 'Vuelve mañana'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
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
    final g = eco.config.goals[index];
    final claimed = eco.isGoalClaimed(c.state, g.id);
    final met = eco.goalMet(c.state, g);
    final progress = eco.goalProgress(c.state, g);
    final rewards = [
      if (g.rewardMoney.isPositive)
        '${formatter.format(g.rewardMoney)} Pelusitas',
      if (g.rewardHilvanes.isPositive)
        '${formatter.format(g.rewardHilvanes)} Hilvanes',
    ].join(' + ');

    return Card(
      key: Key('goal-${g.id}'),
      color: claimed ? Palette.lint : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: claimed
                  ? Palette.mint
                  : (met ? Palette.gold : Palette.lint),
              child: claimed
                  ? const Icon(Icons.check, color: Palette.outline)
                  : Text(
                      '${index + 1}',
                      style: const TextStyle(color: Palette.outline),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    g.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Recompensa: $rewards',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (!claimed) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        color: Palette.blue,
                        backgroundColor: Palette.lint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (claimed)
              const Text('Cobrada')
            else
              FilledButton(
                key: Key('claim-${g.id}'),
                onPressed: met ? () => c.claimGoal(g.id) : null,
                child: const Text('Reclamar'),
              ),
          ],
        ),
      ),
    );
  }
}
