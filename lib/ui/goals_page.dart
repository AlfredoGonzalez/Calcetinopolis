import 'package:flutter/material.dart';

import '../app/game_controller.dart';
import '../core/number_format.dart';
import 'art.dart';
import 'mascot_burst.dart';
import 'theme.dart';
import 'ui_kit.dart';

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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        if (eco.config.daily != null)
          _DailyCard(controller: c, formatter: formatter),
        const SizedBox(height: 6),
        const SectionTitle(
          'Ruta de metas',
          subtitle: 'Las recompensas son gratis y nunca bloquean el avance del juego.',
        ),
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
    return UiCard(
      color: const Color(0xFFFFF0B8),
      edge: Ui.yellow,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Art(
                'icon_ui_regalo',
                size: 44,
                fallback: Icons.card_giftcard,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Regalo diario',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                ),
              ),
              Container(
                key: const Key('streak'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Racha: ${c.state.dailyStreak}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hoy: ${formatter.format(preview.money)} Pelusitas'
            '${preview.hilvanes.isPositive ? ' y ${formatter.format(preview.hilvanes)} Hilvanes' : ''}',
            key: const Key('daily-preview'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const Text(
            'Si faltas un día, tu racha se pausa; no vuelve a cero.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Ui.ink2,
            ),
          ),
          if (c.canWatchDailyGoldAd || c.state.dailyAdDay != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: OutlinedButton.icon(
                key: const Key('daily-gold-ad'),
                onPressed: c.canWatchDailyGoldAd
                    ? () async {
                        final g = await c.watchDailyGoldAd();
                        if (g != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('+$g Botones Dorados')),
                          );
                        }
                      }
                    : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Ui.ink,
                  side: BorderSide(
                    color: c.canWatchDailyGoldAd ? Ui.orange : Ui.disabled,
                    width: 2,
                  ),
                  shape: const StadiumBorder(),
                  minimumSize: const Size.fromHeight(44),
                ),
                icon: const Art('icon_botones_dorados', size: 24),
                label: Text(
                  c.canWatchDailyGoldAd
                      ? '+${c.economy.config.monetization!.dailyGiftGold} Botones Dorados ${c.state.vip ? '(VIP)' : 'viendo un anuncio'}'
                      : 'Bono de hoy recogido',
                ),
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('daily-claim'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Ui.teal,
                foregroundColor: Ui.ink,
                disabledBackgroundColor: Ui.disabled,
                disabledForegroundColor: Ui.disabledInk,
              ),
              onPressed: can
                  ? () {
                      final r = c.claimDaily();
                      if (r != null) {
                        playMascot(context, MascotMove.celebrate);
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

    final accent = Ui.accent(index);
    return UiCard(
      key: Key('goal-${g.id}'),
      edge: claimed ? Ui.disabled : (met ? Ui.tealEdge : Ui.soft(accent)),
      color: claimed ? const Color(0xFFF7F1E4) : Colors.white,
      child: Row(
        children: [
          AccentBadge(
            color: claimed ? Ui.teal : accent,
            size: 46,
            child: claimed
                ? const Icon(Icons.check, color: Ui.ink)
                : Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  g.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Recompensa: $rewards',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Ui.ink2,
                  ),
                ),
                if (!claimed) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      color: accent,
                      backgroundColor: Ui.track,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (claimed)
            const Text(
              'Cobrada',
              style: TextStyle(fontWeight: FontWeight.w700, color: Ui.ink2),
            )
          else
            ChunkyButton(
              key: Key('claim-${g.id}'),
              label: 'Reclamar',
              width: 92,
              height: 46,
              onPressed: met
                  ? () {
                      c.claimGoal(g.id);
                      playMascot(context, MascotMove.celebrate);
                    }
                  : null,
            ),
        ],
      ),
    );
  }
}
