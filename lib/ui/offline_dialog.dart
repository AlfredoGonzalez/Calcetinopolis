import 'package:flutter/material.dart';

import '../app/game_controller.dart';
import '../core/economy/offline.dart';
import '../core/number_format.dart';
import 'art.dart';
import 'sprite_sheet.dart';
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
  NumberFormatter f, {
  OfflineReport? preview,
}) {
  final r = preview ?? c.pendingOffline;
  if (r == null) return Future.value();
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text(
        '¡Tus calcetines trabajaron!',
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SpriteSheet(
            asset: 'assets/art/spr_mascota_celebra_5x5.png',
            frameSize: Size(336, 385),
            columns: 5,
            rows: 5,
            frames: 21,
            fps: 10,
            scale: 0.4,
            loop: false,
          ),
          const SizedBox(height: 8),
          Text(
            'Estuviste fuera ${formatDuration(r.secondsAway)}.',
            textAlign: TextAlign.center,
          ),
          if (r.capped)
            Text(
              'Se cuentan ${formatDuration(r.secondsCounted)} (tope offline).',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Ui.ink2),
            ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Ui.tealSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Art('icon_pelusitas', size: 34, fallback: Icons.cloud),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '+${f.format(r.gain)} Pelusitas',
                      key: const Key('offline-gain'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsOverflowButtonSpacing: 8,
      actions: [
        if (preview == null && c.canDoubleOffline)
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
          style: FilledButton.styleFrom(
            backgroundColor: Ui.teal,
            foregroundColor: Ui.ink,
            minimumSize: const Size(140, 46),
          ),
          onPressed: () async {
            Navigator.pop(ctx);
            if (preview == null) await c.claimOffline();
          },
          child: const Text('Recoger'),
        ),
      ],
    ),
  );
}
