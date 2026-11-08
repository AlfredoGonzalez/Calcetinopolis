import 'package:flutter/material.dart';

import '../app/game_controller.dart';
import 'art.dart';
import 'businesses_page.dart';
import 'goals_page.dart';
import 'settings_page.dart';
import 'offline_dialog.dart';
import 'prestige_page.dart';
import 'shop_page.dart';
import 'cutscene_player.dart';
import 'effects.dart';
import 'mascot_burst.dart';
import 'theme.dart';
import 'upgrades_page.dart';

/// Barra superior con monedas + 5 pestañas (spec 9.11).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final GameController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _tab = 0;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_maybeShowOffline);
    _lastTutorial = widget.controller.tutorialStep;
    widget.controller.addListener(_tutorialMascot);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowIntro();
      _maybeShowOffline();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_maybeShowOffline);
    widget.controller.removeListener(_tutorialMascot);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      widget.controller.onPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.controller.onResumed();
    }
  }

  /// La intro se ve una sola vez, al abrir una partida nueva.
  Future<void> _maybeShowIntro() async {
    final c = widget.controller;
    if (!mounted || _dialogOpen || !c.shouldShowCutscene('intro')) return;
    _dialogOpen = true;
    await showCutscene(context, Cutscene.intro, sound: c.state.settings.sound);
    await c.markCutsceneSeen('intro');
    _dialogOpen = false;
    if (mounted) _maybeShowOffline();
  }

  int? _lastTutorial;

  /// La mascota salta al avanzar un paso del tutorial y celebra al terminar.
  void _tutorialMascot() {
    final step = widget.controller.tutorialStep;
    final last = _lastTutorial;
    _lastTutorial = step;
    if (!mounted || last == null || step == last) return;
    if (step != null && step > last) {
      playMascot(context, MascotMove.jump);
    } else if (step == null && last == 2) {
      playMascot(context, MascotMove.celebrate);
    }
  }

  // Una sola ventana a la vez (spec 9.11).
  void _maybeShowOffline() {
    if (_dialogOpen || !mounted || widget.controller.pendingOffline == null) {
      return;
    }
    _dialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final c = widget.controller;
      final away = c.pendingOffline?.secondsAway ?? 0;
      if (mounted && away >= 4 * 3600 && c.shouldShowCutscene('welcome')) {
        await showCutscene(
          context,
          Cutscene.welcome,
          sound: c.state.settings.sound,
        );
        await c.markCutsceneSeen('welcome');
      }
      if (mounted && widget.controller.pendingOffline != null) {
        await showOfflineDialog(
          context,
          widget.controller,
          widget.controller.formatter,
        );
      }
      _dialogOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final pages = <Widget>[
          BusinessesPage(controller: c, formatter: widget.controller.formatter),
          UpgradesPage(controller: c, formatter: widget.controller.formatter),
          PrestigePage(controller: c, formatter: widget.controller.formatter),
          GoalsPage(controller: c, formatter: c.formatter),
          ShopPage(controller: c, formatter: c.formatter),
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
                  GainPulse(
                    value: c.state.money,
                    minRatio: 1.5,
                    child: const Art('icon_pelusitas', size: 30),
                  ),
                  const SizedBox(width: 8),
                  // El dinero cede espacio antes de que algo se desborde.
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        key: const Key('money'),
                        widget.controller.formatter.format(c.state.money),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Palette.outline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 2,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (c.state.boostSeconds > 0) ...[
                            Chip(
                              key: const Key('boost-chip'),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: Palette.orange,
                              label: Text(
                                'x2 ${formatDuration(c.state.boostSeconds)}',
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (c.state.goldButtons.isPositive) ...[
                            GainPulse(
                              value: c.state.goldButtons,
                              child: const Art(
                                'icon_botones_dorados',
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              c.formatter.format(c.state.goldButtons),
                              key: const Key('gold-top'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Palette.outline,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          GainPulse(
                            value: c.state.pairsClaimed,
                            child: const Art('icon_pareja_reunida', size: 26),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.controller.formatter.format(
                              c.state.pairsClaimed,
                            ),
                            key: const Key('pairs-top'),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Palette.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  key: const Key('settings'),
                  tooltip: 'Ajustes',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SettingsPage(controller: c),
                    ),
                  ),
                  icon: const Art(
                    'icon_ui_ajustes',
                    size: 30,
                    fallback: Icons.settings,
                  ),
                ),
              ],
            ),
            body: SafeArea(child: pages[_tab]),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) {
                setState(() => _tab = i);
                if (i == 4) c.logIapView();
              },
              destinations: [
                const NavigationDestination(
                  icon: Art(
                    'icon_ui_negocios',
                    size: 30,
                    fallback: Icons.storefront,
                  ),
                  label: 'Negocios',
                ),
                NavigationDestination(
                  icon: Badge(
                    key: const Key('badge-mejoras'),
                    isLabelVisible: c.hasAffordableUpgrade,
                    smallSize: 8,
                    backgroundColor: Palette.tomato,
                    child: const Art(
                      'icon_ui_mejoras',
                      size: 30,
                      fallback: Icons.arrow_circle_up,
                    ),
                  ),
                  label: 'Mejoras',
                ),
                const NavigationDestination(
                  icon: Art(
                    'icon_ui_centrifugado',
                    size: 30,
                    fallback: Icons.local_laundry_service,
                  ),
                  label: 'Centrifugado',
                ),
                NavigationDestination(
                  icon: Badge(
                    key: const Key('badge-metas'),
                    isLabelVisible: c.hasGoalNotice,
                    smallSize: 8,
                    backgroundColor: Palette.tomato,
                    child: const Art(
                      'icon_ui_metas',
                      size: 30,
                      fallback: Icons.flag,
                    ),
                  ),
                  label: 'Metas',
                ),
                const NavigationDestination(
                  icon: Art(
                    'icon_ui_tienda',
                    size: 30,
                    fallback: Icons.shopping_bag,
                  ),
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
