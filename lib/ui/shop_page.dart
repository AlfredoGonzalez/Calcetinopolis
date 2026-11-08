import 'package:flutter/material.dart';

import '../app/game_controller.dart';
import '../core/config/economy_config.dart';
import '../core/economy/engine.dart';
import '../core/number_format.dart';
import 'art.dart';
import 'offline_dialog.dart' show formatDuration;
import 'mascot_burst.dart';
import 'theme.dart';
import 'ui_kit.dart';

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
    final goldProducts = products
        .where((p) => p.kind == ProductKind.gold)
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        if (c.testMode) const _TestBanner(),
        _GoldBalance(controller: c, formatter: formatter),
        const SectionTitle('Boosts gratis'),
        _BoostCard(controller: c),
        _WarpCard(controller: c, formatter: formatter),
        if (eco.starterAvailable(c.state)) ...[
          const SectionTitle('Oferta única'),
          for (final p in products.where((p) => p.kind == ProductKind.starter))
            _ProductCard(
              controller: c,
              product: p,
              art: 'shop_starter',
              artFallback: 'icon_ui_regalo',
              fallback: Icons.card_giftcard,
              accent: Ui.orange,
            ),
        ],
        const SectionTitle('Pase VIP'),
        for (final p in products.where((p) => p.kind == ProductKind.vip))
          _ProductCard(
            controller: c,
            product: p,
            art: 'shop_vip',
            artFallback: 'icon_ui_metas',
            fallback: Icons.workspace_premium,
            ownedText: 'Activo',
            isOwned: c.state.vip,
            accent: Ui.yellow,
          ),
        const SectionTitle(
          'Botones Dorados',
          subtitle: 'Sirven para saltos de tiempo. Se ganan jugando; comprarlos solo ahorra tiempo.',
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.74,
          padding: const EdgeInsets.only(bottom: 4),
          children: [
            for (var i = 0; i < goldProducts.length; i++)
              _PackCard(
                controller: c,
                product: goldProducts[i],
                art: 'shop_botones_${i + 1}',
              ),
          ],
        ),
        const SectionTitle(
          'Multiplicador permanente',
          subtitle: 'Máximo 3 niveles. El pago acelera tu progreso; no desbloquea nada que no se pueda ganar jugando.',
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
            accent: Ui.violet,
          ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          key: const Key('shop-restore'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Ui.ink,
            side: const BorderSide(color: Ui.ink, width: 2),
            shape: const StadiumBorder(),
            minimumSize: const Size.fromHeight(48),
          ),
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

/// Botón oscuro de las compras y los anuncios de la Tienda.
ButtonStyle _inkButton({double minWidth = 96, double height = 48}) =>
    FilledButton.styleFrom(
      backgroundColor: Ui.ink,
      foregroundColor: Colors.white,
      disabledBackgroundColor: Ui.disabled,
      disabledForegroundColor: Ui.disabledInk,
      minimumSize: Size(minWidth, height),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(
        fontFamily: Ui.fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );

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
      Flexible(child: Text(text, textAlign: TextAlign.center)),
    ],
  );
}

class _TestBanner extends StatelessWidget {
  const _TestBanner();

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('shop-test-banner'),
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Ui.yellow,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Ui.ink, width: 1.5),
    ),
    child: const Text(
      'Modo de prueba: los anuncios y las compras son simulados. No se cobra nada.',
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.3),
    ),
  );
}

class _GoldBalance extends StatelessWidget {
  const _GoldBalance({required this.controller, required this.formatter});
  final GameController controller;
  final NumberFormatter formatter;

  @override
  Widget build(BuildContext context) => UiCard(
    edge: Ui.yellow,
    margin: EdgeInsets.zero,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Row(
      children: [
        const Art('icon_botones_dorados', size: 40, fallback: Icons.circle),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${formatter.format(controller.state.goldButtons)} Botones Dorados',
            key: const Key('gold-balance'),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
        ),
      ],
    ),
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
    return UiCard(
      edge: Ui.orangeSoft,
      child: Row(
        children: [
          const AccentBadge(
            color: Ui.yellow,
            size: 56,
            child: Art('icon_ui_boost', size: 40, fallback: Icons.bolt),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Boost x${cfg.multiplier.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Cada ${vip ? 'activación' : 'anuncio'} suma ${cfg.hoursPerView.toStringAsFixed(0)} h de x${cfg.multiplier.toStringAsFixed(0)} a todas las ganancias. '
                  'Máximo ${cfg.maxHours.toStringAsFixed(0)} h acumuladas.',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Ui.ink2,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  left > 0
                      ? 'Te quedan ${formatDuration(left)}'
                      : 'Sin boost activo',
                  key: const Key('boost-left'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!unlocked)
                  Text(
                    _locked,
                    key: const Key('ads-locked'),
                    style: const TextStyle(fontSize: 12, color: Ui.ink2),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            key: const Key('shop-boost'),
            style: _inkButton(),
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
    return UiCard(
      edge: Ui.orangeSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AccentBadge(
                color: Ui.blue,
                size: 56,
                child: Art('icon_ui_reloj', size: 40, fallback: Icons.update),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saltar espera',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Recibes al instante la producción de los negocios con manager: '
                      '${mon.warpMinutes.toStringAsFixed(0)} min por anuncio, '
                      '${c.warpAdsLeft} de ${mon.warpPerDay} disponibles hoy.',
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
              FilledButton(
                key: const Key('shop-warp-ad'),
                style: _inkButton(),
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
          const SizedBox(height: 10),
          const Text(
            'O con Botones Dorados:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Ui.ink2,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < mon.warpGold.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    key: Key('shop-warp-gold-${mon.warpGold[i].id}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Ui.ink,
                      disabledForegroundColor: Ui.disabledInk,
                      side: BorderSide(
                        color: c.canBuyWarpWithGold(mon.warpGold[i].id)
                            ? Ui.ink
                            : Ui.disabled,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      minimumSize: const Size(0, 46),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    onPressed: c.canBuyWarpWithGold(mon.warpGold[i].id)
                        ? () {
                            final gain = c.buyWarpWithGold(mon.warpGold[i].id);
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
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${mon.warpGold[i].hours.toStringAsFixed(0)} h · ${mon.warpGold[i].gold} Botones',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Un paquete de Botones Dorados, en la cuadrícula de dos columnas.
class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.controller,
    required this.product,
    required this.art,
  });

  final GameController controller;
  final ProductConfig product;
  final String art;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final canBuy = c.economy.canBuyProduct(c.state, product.id);
    return UiCard(
      edge: Ui.yellow,
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: Art(
              art,
              size: 72,
              fallbackName: 'icon_botones_dorados',
              fallback: Icons.circle,
            ),
          ),
          Text(
            product.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            product.description,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Ui.ink2,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: Key('shop-buy-${product.id}'),
              style: _inkButton(height: 42),
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
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(c.priceOf(product.id)),
              ),
            ),
          ),
        ],
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
    this.accent = Ui.orange,
  });

  final GameController controller;
  final ProductConfig product;
  final String art;
  final String? artFallback;
  final IconData fallback;
  final bool isOwned;
  final String ownedText;
  final String? lockedText;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final canBuy =
        !isOwned &&
        lockedText == null &&
        c.economy.canBuyProduct(c.state, product.id);
    return UiCard(
      edge: isOwned ? Ui.disabled : Ui.soft(accent),
      color: isOwned ? const Color(0xFFF7F1E4) : Colors.white,
      child: Row(
        children: [
          AccentBadge(
            color: accent,
            size: 60,
            shape: BoxShape.rectangle,
            child: Art(
              art,
              size: 48,
              fallbackName: artFallback,
              fallback: fallback,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                Text(
                  product.description,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Ui.ink2,
                    height: 1.25,
                  ),
                ),
                if (lockedText != null && !isOwned)
                  Text(
                    lockedText!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Ui.ink2,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isOwned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Ui.tealSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                ownedText,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          else
            FilledButton(
              key: Key('shop-buy-${product.id}'),
              style: _inkButton(minWidth: 84),
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
    );
  }
}
