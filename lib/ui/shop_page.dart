import 'package:flutter/material.dart';

import '../app/game_controller.dart';
import '../core/config/economy_config.dart';
import '../core/economy/engine.dart';
import '../core/number_format.dart';
import 'art.dart';
import 'offline_dialog.dart' show formatDuration;
import 'mascot_burst.dart';
import 'theme.dart';

/// Tienda (spec 9.12 y 10): boost y saltos con anuncios opcionales, Botones
/// Dorados, Pase VIP y multiplicadores permanentes. Cada producto dice
/// exactamente qué da; sin temporizadores falsos ni ofertas inventadas.
class ShopPage extends StatelessWidget {
  const ShopPage({
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
    final mon = eco.config.monetization;
    if (mon == null) return const Center(child: Text('Tienda no disponible'));
    final products = mon.products;

    return Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.2,
            child: Image.asset(
              Art.bgShop,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
        _content(context, c, eco, mon, products),
      ],
    );
  }

  Widget _content(
    BuildContext context,
    GameController c,
    Economy eco,
    MonetizationConfig mon,
    List<ProductConfig> products,
  ) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (c.testMode) const _TestBanner(),
        _GoldBalance(controller: c, formatter: formatter),
        const SizedBox(height: 8),
        _SectionTitle('Boosts gratis'),
        _BoostCard(controller: c),
        _WarpCard(controller: c, formatter: formatter),
        if (eco.starterAvailable(c.state)) ...[
          _SectionTitle('Oferta única'),
          for (final p in products.where((p) => p.kind == ProductKind.starter))
            _ProductCard(
              controller: c,
              product: p,
              art: 'shop_starter',
              artFallback: 'icon_ui_regalo',
              fallback: Icons.card_giftcard,
            ),
        ],
        _SectionTitle('Pase VIP'),
        for (final p in products.where((p) => p.kind == ProductKind.vip))
          _ProductCard(
            controller: c,
            product: p,
            art: 'shop_vip',
            artFallback: 'icon_ui_metas',
            fallback: Icons.workspace_premium,
            ownedText: 'Activo',
            isOwned: c.state.vip,
          ),
        _SectionTitle('Botones Dorados'),
        const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text(
            'Sirven para saltos de tiempo. Se ganan jugando; comprarlos solo ahorra tiempo.',
            style: TextStyle(fontSize: 12),
          ),
        ),
        for (
          var i = 0;
          i < products.where((p) => p.kind == ProductKind.gold).length;
          i++
        )
          _ProductCard(
            controller: c,
            product: products
                .where((p) => p.kind == ProductKind.gold)
                .toList()[i],
            art: 'shop_botones_${i + 1}',
            artFallback: 'icon_botones_dorados',
            fallback: Icons.circle,
          ),
        _SectionTitle('Multiplicador permanente'),
        const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text(
            'Máximo 3 niveles. El pago acelera tu progreso; no desbloquea nada que no se pueda ganar jugando.',
            style: TextStyle(fontSize: 12),
          ),
        ),
        for (final p in products.where((p) => p.kind == ProductKind.multiplier))
          _ProductCard(
            controller: c,
            product: p,
            art: 'shop_mult',
            artFallback: 'icon_ui_mejoras',
            fallback: Icons.auto_awesome,
            isOwned: c.state.multLevel >= p.level,
            ownedText: 'Comprado',
            lockedText: c.state.multLevel + 1 < p.level
                ? 'Compra el nivel anterior'
                : null,
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('shop-restore'),
          onPressed: () async {
            final n = await c.restorePurchases();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  n > 0
                      ? 'Se restauraron $n compras'
                      : 'No hay compras por restaurar',
                ),
              ),
            );
          },
          icon: const Icon(Icons.restore),
          label: const Text('Restaurar compras'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Texto de un botón de anuncio, con el ícono de "reproducir" cuando hay anuncio.
class _AdLabel extends StatelessWidget {
  const _AdLabel(this.text, {required this.showIcon});
  final String text;
  final bool showIcon;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (showIcon) ...[
        const Art('icon_ui_anuncio', size: 22, fallback: Icons.play_circle),
        const SizedBox(width: 6),
      ],
      Text(text, textAlign: TextAlign.center),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 6),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _TestBanner extends StatelessWidget {
  const _TestBanner();

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('shop-test-banner'),
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Palette.butter,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Palette.outline),
    ),
    child: const Text(
      'Modo de prueba: los anuncios y las compras son simulados. No se cobra nada.',
    ),
  );
}

class _GoldBalance extends StatelessWidget {
  const _GoldBalance({required this.controller, required this.formatter});
  final GameController controller;
  final NumberFormatter formatter;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Art('icon_botones_dorados', size: 36, fallback: Icons.circle),
      const SizedBox(width: 8),
      Text(
        '${formatter.format(controller.state.goldButtons)} Botones Dorados',
        key: const Key('gold-balance'),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ],
  );
}

String _locked = 'Disponible después de tu primer regreso a la app.';

class _BoostCard extends StatelessWidget {
  const _BoostCard({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final cfg = c.economy.config.boost;
    final left = c.state.boostSeconds;
    final unlocked = c.adsUnlocked;
    final full = !c.economy.canAddBoost(c.state);
    final vip = c.state.vip;
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Art('icon_ui_boost', size: 48, fallback: Icons.bolt),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Boost x${cfg.multiplier.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Cada ${vip ? 'activación' : 'anuncio'} suma ${cfg.hoursPerView.toStringAsFixed(0)} h de x${cfg.multiplier.toStringAsFixed(0)} a todas las ganancias. '
                    'Máximo ${cfg.maxHours.toStringAsFixed(0)} h acumuladas.',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    left > 0
                        ? 'Te quedan ${formatDuration(left)}'
                        : 'Sin boost activo',
                    key: const Key('boost-left'),
                  ),
                  if (!unlocked)
                    Text(
                      _locked,
                      key: const Key('ads-locked'),
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              key: const Key('shop-boost'),
              onPressed: c.canWatchBoost
                  ? () async {
                      final ok = await c.watchBoostAd();
                      if (ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '+${cfg.hoursPerView.toStringAsFixed(0)} h de boost',
                            ),
                          ),
                        );
                      }
                    }
                  : null,
              child: _AdLabel(
                full ? 'Máximo' : (vip ? 'Activar' : 'Ver anuncio'),
                showIcon: !full && !vip,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarpCard extends StatelessWidget {
  const _WarpCard({required this.controller, required this.formatter});
  final GameController controller;
  final NumberFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final mon = c.economy.config.monetization!;
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Art('icon_ui_reloj', size: 48, fallback: Icons.update),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saltar espera',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Recibes al instante la producción de los negocios con manager: '
                        '${mon.warpMinutes.toStringAsFixed(0)} min por anuncio, '
                        '${c.warpAdsLeft} de ${mon.warpPerDay} disponibles hoy.',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const Key('shop-warp-ad'),
                  onPressed: c.canWatchWarp
                      ? () async {
                          final gain = await c.watchWarpAd();
                          if (gain != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '+${formatter.format(gain)} Pelusitas',
                                ),
                              ),
                            );
                          }
                        }
                      : null,
                  child: _AdLabel(
                    c.state.vip ? 'Saltar' : 'Ver anuncio',
                    showIcon: !c.state.vip,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'O con Botones Dorados:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final w in mon.warpGold)
                  OutlinedButton(
                    key: Key('shop-warp-gold-${w.id}'),
                    onPressed: c.canBuyWarpWithGold(w.id)
                        ? () {
                            final gain = c.buyWarpWithGold(w.id);
                            if (gain != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '+${formatter.format(gain)} Pelusitas',
                                  ),
                                ),
                              );
                            }
                          }
                        : null,
                    child: Text(
                      '${w.hours.toStringAsFixed(0)} h · ${w.gold} Botones',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.controller,
    required this.product,
    required this.art,
    this.artFallback,
    required this.fallback,
    this.isOwned = false,
    this.ownedText = 'Comprado',
    this.lockedText,
  });

  final GameController controller;
  final ProductConfig product;
  final String art;
  final String? artFallback;
  final IconData fallback;
  final bool isOwned;
  final String ownedText;
  final String? lockedText;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final canBuy =
        !isOwned &&
        lockedText == null &&
        c.economy.canBuyProduct(c.state, product.id);
    return Card(
      color: isOwned ? Palette.lint : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Art(art, size: 48, fallbackName: artFallback, fallback: fallback),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    product.description,
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (lockedText != null && !isOwned)
                    Text(
                      lockedText!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isOwned)
              Chip(label: Text(ownedText), backgroundColor: Palette.mint)
            else
              FilledButton(
                key: Key('shop-buy-${product.id}'),
                onPressed: canBuy
                    ? () async {
                        final ok = await c.purchase(product.id);
                        if (ok && context.mounted) {
                          playMascot(context, MascotMove.celebrate);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('¡Listo! ${product.name}')),
                          );
                        }
                      }
                    : null,
                child: Text(c.priceOf(product.id)),
              ),
          ],
        ),
      ),
    );
  }
}
