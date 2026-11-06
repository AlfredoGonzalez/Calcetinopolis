import 'package:flutter/material.dart';

import '../app/game_controller.dart';
import '../core/number_format.dart';
import 'theme.dart';

String formatDuration(double seconds) {
  final s = seconds.round();
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  if (h > 0) return '$h h $m min';
  if (m > 0) return '$m min';
  return '$s s';
}

/// Ventana de bienvenida offline (spec 9.12).
Future<void> showOfflineDialog(
  BuildContext context,
  GameController c,
  NumberFormatter f,
) {
  final r = c.pendingOffline;
  if (r == null) return Future.value();
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Palette.cream,
      title: const Text('¡Tus calcetines trabajaron!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estuviste fuera ${formatDuration(r.secondsAway)}.'),
          if (r.capped)
            Text(
              'Se cuentan ${formatDuration(r.secondsCounted)} (tope offline).',
              style: const TextStyle(fontSize: 12),
            ),
          const SizedBox(height: 12),
          Text(
            '+${f.format(r.gain)} Pelusitas',
            key: const Key('offline-gain'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        if (c.canDoubleOffline)
          OutlinedButton(
            key: const Key('offline-x2'),
            onPressed: () async {
              Navigator.pop(ctx);
              await c.claimOffline(doubled: true);
            },
            child: Text(
              c.state.vip ? 'Recoger x2 (VIP)' : 'Recoger x2 viendo un anuncio',
            ),
          ),
        FilledButton(
          key: const Key('offline-claim'),
          onPressed: () async {
            Navigator.pop(ctx);
            await c.claimOffline();
          },
          child: const Text('Recoger'),
        ),
      ],
    ),
  );
}
