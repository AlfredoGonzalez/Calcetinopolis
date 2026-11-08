import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/game_controller.dart';
import '../core/big_num.dart';
import '../core/config/economy_config.dart';
import '../core/number_format.dart';
import 'art.dart';
import 'mascot_burst.dart';
import 'theme.dart';

/// Pantalla de Centrifugado: antes/después y tienda de Hilvanes (spec 9.12).
class PrestigePage extends StatelessWidget {
  const PrestigePage({
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
    final s = c.state;
    final pending = c.pairsPending;
    final bonus = eco.config.prestige.pairBonus;
    final multNow = eco.multiplierAfterPrestige(s) - pending.mulDouble(bonus);
    final multAfter = eco.multiplierAfterPrestige(s);
    final good = eco.isGoodTimeToPrestige(s);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row(
                  'Parejas Reunidas',
                  formatter.format(s.pairsClaimed),
                  key: 'pairs-now',
                ),
                _row(
                  'Bono actual',
                  'x${formatter.format(multNow)}',
                  key: 'bonus-now',
                ),
                const Divider(),
                _row(
                  'Parejas por cobrar',
                  '+${formatter.format(pending)}',
                  key: 'pairs-pending',
                ),
                _row(
                  'Bono después',
                  'x${formatter.format(multAfter)}',
                  key: 'bonus-after',
                ),
                const SizedBox(height: 8),
                if (good)
                  const Chip(
                    key: Key('good-time'),
                    avatar: Icon(Icons.auto_awesome, size: 18),
                    label: Text('Buen momento para centrifugar'),
                    backgroundColor: Palette.lavender,
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('centrifuge'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Palette.lavender,
                      foregroundColor: Palette.outline,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: pending.isPositive
                        ? () => _confirm(context)
                        : null,
                    icon: const Icon(Icons.local_laundry_service),
                    label: const Text('Centrifugar'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Art('icon_hilvanes', size: 32, fallback: Icons.linear_scale),
            const SizedBox(width: 8),
            Text(
              'Hilvanes: ${formatter.format(s.hilvanes)}',
              key: const Key('hilvanes'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Las Hilvanes se gastan aquí. Las Parejas Reunidas nunca se gastan: tu bono no baja.',
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 8),
        for (final it in eco.config.shop)
          _ShopCard(controller: c, item: it, formatter: formatter),
      ],
    );
  }

  Widget _row(String label, String value, {required String key}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          key: Key(key),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    ),
  );

  Future<void> _confirm(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Palette.cream,
        title: const Text('¿Centrifugar?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Se pierde:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              '• Dinero y todos los negocios\n• Managers\n• Upgrades de efectivo',
            ),
            SizedBox(height: 12),
            Text('Se conserva:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              '• Parejas Reunidas e Hilvanes\n• Mejoras de la tienda\n• Compras y estampados',
            ),
          ],
        ),
        actions: [
          FilledButton(
            key: const Key('cancel-centrifuge'),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: const Key('confirm-centrifuge'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Centrifugar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final got = await controller.centrifuge();
    if (!context.mounted || !got.isPositive) return;
    await showCentrifugeAnimation(context, formatter.format(got));
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.controller,
    required this.item,
    required this.formatter,
  });
  final GameController controller;
  final ShopItem item;
  final NumberFormatter formatter;

  String _effect(double v) {
    switch (item.type) {
      case ShopType.globalMult:
        return 'x$v a todas las ganancias';
      case ShopType.startMoney:
        return 'Empiezas con ${formatter.format(BigNum.fromDouble(v))} Pelusitas';
      case ShopType.freeManagers:
        return 'Managers gratis en los primeros ${v.toInt()} negocios';
      case ShopType.offlineCapHours:
        return 'Tope offline de ${v.toInt()} h';
    }
    return '$v';
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final level = c.economy.shopLevel(c.state, item.id);
    final next = c.economy.nextShopLevel(c.state, item.id);
    final current = level == 0
        ? 'Sin comprar'
        : _effect(item.levels[level - 1].value);
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Art(item.art, size: 52, fallback: Icons.upgrade),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.name}  ($level/${item.levels.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(item.description, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('Ahora: $current', key: Key('shop-now-${item.id}')),
                  if (next != null)
                    Text(
                      'Siguiente: ${_effect(next.value)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (next == null)
              const Chip(label: Text('Máximo'), backgroundColor: Palette.mint)
            else
              FilledButton(
                key: Key('shop-${item.id}'),
                onPressed: c.canBuyShop(item.id)
                    ? () => c.buyShop(item.id)
                    : null,
                child: Text(
                  '${formatter.format(next.cost)}\nHilvanes',
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Animación del Centrifugado: 3.5 s, se salta tocando (spec 9.12).
Future<void> showCentrifugeAnimation(BuildContext context, String pairsText) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CentrifugeDialog(pairsText: pairsText),
  );
}

class _CentrifugeDialog extends StatefulWidget {
  const _CentrifugeDialog({required this.pairsText});
  final String pairsText;

  @override
  State<_CentrifugeDialog> createState() => _CentrifugeDialogState();
}

class _CentrifugeDialogState extends State<_CentrifugeDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3500),
  )..forward();

  bool _celebrated = false;

  @override
  void initState() {
    super.initState();
    _anim.addListener(() {
      if (_anim.value >= 1 && !_celebrated) {
        _celebrated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) playMascot(context, MascotMove.celebrate);
        });
      }
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('centrifuge-anim'),
      behavior: HitTestBehavior.opaque,
      onTap: () => _anim.value = 1,
      child: Dialog(
        backgroundColor: Palette.cream,
        child: SizedBox(
          height: 340,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, _) {
              final t = _anim.value;
              final done = t >= 1;
              final meet = Curves.easeInOut.transform(
                (t * 1.4).clamp(0.0, 1.0),
              );
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // La lavadora tiembla mientras centrifuga.
                        Transform.translate(
                          offset: Offset(done ? 0 : math.sin(t * 90) * 2.5, 0),
                          child: const Art(
                            'anim_centrifugado_lavadora',
                            size: 150,
                            fallback: Icons.local_laundry_service,
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(-95 * (1 - meet), 12),
                          child: const Art(
                            'anim_centrifugado_calcetin_izq',
                            size: 80,
                            fallbackName: 'icon_pareja_reunida',
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(95 * (1 - meet), 12),
                          // El arte mira hacia la derecha: se voltea para que
                          // los dos calcetines se miren al encontrarse.
                          child: Transform.flip(
                            flipX: true,
                            child: const Art(
                              'anim_centrifugado_calcetin_der',
                              size: 80,
                              fallbackName: 'icon_pareja_reunida',
                            ),
                          ),
                        ),
                        if (done)
                          Transform.translate(
                            offset: const Offset(0, -62),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 450),
                              curve: Curves.elasticOut,
                              builder: (_, v, child) =>
                                  Transform.scale(scale: v, child: child),
                              child: const Art(
                                'anim_centrifugado_corazon',
                                size: 56,
                                fallback: Icons.favorite,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!done)
                    const Text(
                      'Centrifugando...  (toca para saltar)',
                      style: TextStyle(fontSize: 12),
                    ),
                  if (done) ...[
                    const Text(
                      '¡Se reencontraron!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '+${widget.pairsText} Parejas Reunidas',
                      key: const Key('centrifuge-result'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      key: const Key('centrifuge-done'),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Seguir'),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
