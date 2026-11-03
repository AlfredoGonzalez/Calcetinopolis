import 'package:flutter/material.dart';

import '../app/game_controller.dart';
import '../core/number_format.dart';
import 'businesses_page.dart';
import 'theme.dart';
import 'upgrades_page.dart';

/// Barra superior con monedas + 5 pestañas (spec 9.11).
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.controller,
    this.formatter = const NumberFormatter(),
  });

  final GameController controller;
  final NumberFormatter formatter;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final pages = <Widget>[
          BusinessesPage(controller: c, formatter: widget.formatter),
          UpgradesPage(controller: c, formatter: widget.formatter),
          const _Soon(title: 'Centrifugado', text: 'Llega en F4.'),
          const _Soon(title: 'Metas', text: 'Llega en F5.'),
          const _Soon(title: 'Tienda', text: 'Llega en F7.'),
        ];
        return PopScope(
          canPop: _tab == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) setState(() => _tab = 0);
          },
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Palette.blue,
              titleSpacing: 16,
              title: Row(
                children: [
                  const Icon(Icons.bubble_chart, color: Palette.cream),
                  const SizedBox(width: 8),
                  Text(
                    key: const Key('money'),
                    widget.formatter.format(c.state.money),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Palette.outline,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Parejas ${widget.formatter.format(c.state.pairsClaimed)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Palette.outline,
                    ),
                  ),
                ],
              ),
              actions: const [
                IconButton(
                  tooltip: 'Ajustes',
                  onPressed: null,
                  icon: Icon(Icons.settings, color: Palette.outline),
                ),
              ],
            ),
            body: SafeArea(child: pages[_tab]),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.storefront),
                  label: 'Negocios',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: c.hasAffordableUpgrade,
                    smallSize: 8,
                    backgroundColor: Palette.tomato,
                    child: const Icon(Icons.arrow_circle_up),
                  ),
                  label: 'Mejoras',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.local_laundry_service),
                  label: 'Centrifugado',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.flag),
                  label: 'Metas',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.shopping_bag),
                  label: 'Tienda',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Soon extends StatelessWidget {
  const _Soon({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(text),
      ],
    ),
  );
}
