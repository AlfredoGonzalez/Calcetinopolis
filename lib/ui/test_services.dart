import 'dart:async';

import 'package:flutter/material.dart';

import '../services/services.dart';

/// Servicios de PRUEBA para la versión web y los builds de desarrollo: ningún
/// anuncio ni cobro es real. Muestran un diálogo para poder sentir el flujo.
/// Se reemplazan por AdMob y Google Play Billing al lanzar (F8).

/// Anuncio recompensado simulado: cuenta regresiva y botón para recoger.
class TestAdService implements AdService {
  TestAdService(this.navigatorKey, {this.seconds = 3});

  final GlobalKey<NavigatorState> navigatorKey;
  final int seconds;

  @override
  Future<bool> showRewarded(String placement) async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return false;
    final done = await showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => _TestAdDialog(seconds: seconds),
    );
    return done ?? false;
  }
}

class _TestAdDialog extends StatefulWidget {
  const _TestAdDialog({required this.seconds});
  final int seconds;

  @override
  State<_TestAdDialog> createState() => _TestAdDialogState();
}

class _TestAdDialogState extends State<_TestAdDialog> {
  late int _left = widget.seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_left <= 1) t.cancel();
      setState(() => _left--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = _left <= 0;
    return AlertDialog(
      title: const Text('Anuncio de prueba'),
      content: Text(
        done
            ? 'Listo: ganaste la recompensa.'
            : 'Aquí iría un anuncio real. Termina en $_left s…',
        key: const Key('test-ad-text'),
      ),
      actions: [
        TextButton(
          key: const Key('test-ad-skip'),
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cerrar sin recompensa'),
        ),
        FilledButton(
          key: const Key('test-ad-done'),
          onPressed: done ? () => Navigator.pop(context, true) : null,
          child: const Text('Recoger recompensa'),
        ),
      ],
    );
  }
}

/// Compras simuladas: confirmación sin cobro y precios de referencia en MXN.
class TestIapService implements IapService {
  TestIapService(this.navigatorKey, this.pricesMxn, {Set<String>? durable})
    : _durable = durable ?? {};

  final GlobalKey<NavigatorState> navigatorKey;
  final Map<String, double> pricesMxn;

  /// Productos permanentes: son los que [restore] devuelve.
  final Set<String> _durable;
  final _owned = <String>{};

  @override
  Future<void> load(Set<String> productIds) async {}

  @override
  String? priceOf(String productId) {
    final p = pricesMxn[productId];
    return p == null ? null : '\$${p.toStringAsFixed(0)} MXN';
  }

  @override
  Future<bool> purchase(String productId) async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return false;
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Compra de prueba'),
        content: Text(
          'No se cobra nada. Precio de referencia: ${priceOf(productId) ?? '?'}.',
          key: const Key('test-iap-text'),
        ),
        actions: [
          TextButton(
            key: const Key('test-iap-cancel'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('test-iap-ok'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Comprar (simulado)'),
          ),
        ],
      ),
    );
    if (ok == true && _durable.contains(productId)) _owned.add(productId);
    return ok ?? false;
  }

  @override
  Future<Set<String>> restore() async => {..._owned};
}
