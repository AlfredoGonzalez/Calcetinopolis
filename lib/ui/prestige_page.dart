import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/game_controller.dart';
import '../core/big_num.dart';
import '../core/config/economy_config.dart';
import '../core/number_format.dart';
import 'art.dart';
import 'cutscene_player.dart';
import 'mascot_burst.dart';
import 'theme.dart';
import 'ui_kit.dart';

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

    final claimed = s.pairsClaimed;
    // Progreso hacia "buen momento": que lo por cobrar iguale lo que ya tienes.
    final double goal = claimed.isPositive
        ? (pending / claimed).toDouble().clamp(0.0, 1.0)
        : (pending.isPositive ? 1.0 : 0.0);
    final goalText = !pending.isPositive
        ? 'Aún no hay parejas por cobrar: sigue produciendo.'
        : claimed.isPositive
        ? '${formatter.format(pending)} por cobrar de ${formatter.format(claimed)} para un buen momento'
        : 'Ya puedes ganar tus primeras parejas';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        Column(
          children: [
            const Art(
              'icon_ui_centrifugado',
              size: 64,
              fallback: Icons.local_laundry_service,
            ),
            const SizedBox(height: 4),
            const Text(
              'Centrifugado',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Reinicia tu lavandería y gana pares de calcetines para un bono permanente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Ui.ink2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Parejas Reunidas',
                value: formatter.format(s.pairsClaimed),
                valueKey: 'pairs-now',
                edge: Ui.orangeSoft,
                icon: const Art(
                  'icon_pareja_reunida',
                  size: 30,
                  fallback: Icons.favorite,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Bono actual',
                value: 'x${formatter.format(multNow)}',
                valueKey: 'bonus-now',
                edge: Ui.tealSoft,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        UiCard(
          edge: Ui.orangeSoft,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Meta de esta vuelta',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${(goal * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Ui.ink2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  key: const Key('prestige-goal'),
                  value: goal,
                  minHeight: 16,
                  color: Ui.orange,
                  backgroundColor: Ui.track,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                goalText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Ui.ink2,
                ),
              ),
              if (good) ...[
                const SizedBox(height: 8),
                Container(
                  key: const Key('good-time'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Ui.violet.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 18, color: Ui.violet),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Buen momento para centrifugar',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: Ui.tealSoft,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              const Art(
                'anim_centrifugado_corazon',
                size: 44,
                fallback: Icons.favorite,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Al centrifugar ganarías',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '+${formatter.format(pending)}',
                          key: const Key('pairs-pending'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Tu bono pasaría a',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          'x${formatter.format(multAfter)}',
                          key: const Key('bonus-after'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: pending.isPositive
                    ? const Color(0xFF6A58D6)
                    : Ui.disabledInk.withValues(alpha: 0.5),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FilledButton.icon(
            key: const Key('centrifuge'),
            style: FilledButton.styleFrom(
              backgroundColor: Ui.violet,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Ui.disabled,
              disabledForegroundColor: Ui.disabledInk,
              minimumSize: const Size.fromHeight(62),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              textStyle: const TextStyle(
                fontFamily: Ui.fontFamily,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: pending.isPositive ? () => _confirm(context) : null,
            icon: const Icon(Icons.local_laundry_service),
            label: const Text('Centrifugar'),
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InfoCard(
                title: 'Se reinicia',
                body: 'Pelusas, negocios, managers y upgrades.',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _InfoCard(
                title: 'Te quedas con',
                body:
                    'Botones, parejas, Hilvanes, metas y compras de la Tienda.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Art('icon_hilvanes', size: 36, fallback: Icons.linear_scale),
            const SizedBox(width: 8),
            Text(
              'Hilvanes: ${formatter.format(s.hilvanes)}',
              key: const Key('hilvanes'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
            ),
          ],
        ),
        const SizedBox(height: 2),
        const Text(
          'Las Hilvanes se gastan aquí. Las Parejas Reunidas nunca se gastan: tu bono no baja.',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Ui.ink2,
          ),
        ),
        const SizedBox(height: 10),
        for (final it in eco.config.shop)
          _ShopCard(controller: c, item: it, formatter: formatter),
      ],
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Centrifugar?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LossGain(
              title: 'Se pierde',
              body: 'Dinero y todos los negocios, managers y upgrades de efectivo.',
              color: Color(0xFFFFD9D2),
              icon: Icons.restart_alt,
            ),
            SizedBox(height: 10),
            _LossGain(
              title: 'Se conserva',
              body: 'Parejas Reunidas e Hilvanes, mejoras de la tienda, compras y estampados.',
              color: Ui.tealSoft,
              icon: Icons.favorite,
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
    // La primera vez, antes del resultado, se ve el reencuentro.
    if (controller.shouldShowCutscene('reunion')) {
      await showCutscene(
        context,
        Cutscene.reunion,
        sound: controller.state.settings.sound,
      );
      await controller.markCutsceneSeen('reunion');
      if (!context.mounted) return;
    }
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
      case ShopType.tapPower:
        return '+${(v * 100).toStringAsFixed(v * 100 % 1 == 0 ? 0 : 1)}% por toque a la lavadora';
      case ShopType.washerMax:
        return 'Lavadora hasta +${(v * 100).round()}% de velocidad';
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
    return UiCard(
      edge: next == null ? Ui.tealSoft : Ui.soft(Ui.violet),
      child: Row(
        children: [
          AccentBadge(
            color: Ui.violet,
            size: 60,
            shape: BoxShape.rectangle,
            child: Art(item.art, size: 48, fallback: Icons.upgrade),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.name}  ($level/${item.levels.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Ui.ink2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ahora: $current',
                  key: Key('shop-now-${item.id}'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (next != null)
                  Text(
                    'Siguiente: ${_effect(next.value)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Ui.ink2,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (next == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Ui.tealSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Máximo',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          else
            ChunkyButton(
              key: Key('shop-${item.id}'),
              label: 'Hilvanes',
              detail: formatter.format(next.cost),
              width: 84,
              onPressed: c.canBuyShop(item.id)
                  ? () => c.buyShop(item.id)
                  : null,
            ),
        ],
      ),
    );
  }
}

/// Un panel del diálogo de confirmar: qué se pierde y qué se conserva.
class _LossGain extends StatelessWidget {
  const _LossGain({
    required this.title,
    required this.body,
    required this.color,
    required this.icon,
  });

  final String title;
  final String body;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.valueKey,
    required this.edge,
    this.icon,
  });

  final String label;
  final String value;
  final String valueKey;
  final Color edge;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return UiCard(
      edge: edge,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Ui.ink2,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 6)],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    key: Key(valueKey),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Ui.ink2,
              height: 1.3,
            ),
          ),
        ],
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
        child: SizedBox(
          height: 380,
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
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Ui.ink2,
                      ),
                    ),
                  if (done) ...[
                    const Text(
                      '¡Se reencontraron!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Ui.tealSoft,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Art(
                            'icon_pareja_reunida',
                            size: 28,
                            fallback: Icons.favorite,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '+${widget.pairsText} Parejas Reunidas',
                                key: const Key('centrifuge-result'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
