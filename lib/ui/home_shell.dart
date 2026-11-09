import 'package:flutter/material.dart';

import '../app/game_controller.dart';
import 'businesses_page.dart';
import 'goals_page.dart';
import 'settings_page.dart';
import 'offline_dialog.dart';
import 'prestige_page.dart';
import 'shop_page.dart';
import 'art.dart';
import 'backdrop.dart';
import 'bottom_nav.dart';
import 'cutscene_player.dart';
import 'game_header.dart';
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
  /// Orden de la barra: Mejoras, Metas, Negocios, Centrifugado y Tienda.
  static const _homeTab = 2;
  static const _shopTab = 4;
  static const _prestigeTab = 3;
  int _tab = _homeTab;
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

  /// Cambia de pestaña (barra inferior o toque a los contadores del encabezado).
  void _go(int i) {
    setState(() => _tab = i);
    if (i == _shopTab) widget.controller.logIapView();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final pages = <Widget>[
          MenuBackdrop(
            image: Art.bgRoom,
            child: UpgradesPage(
              controller: c,
              formatter: widget.controller.formatter,
            ),
          ),
          MenuBackdrop(
            image: Art.bgShop,
            child: GoalsPage(controller: c, formatter: c.formatter),
          ),
          BusinessesPage(controller: c, formatter: widget.controller.formatter),
          MenuBackdrop(
            image: 'assets/art/bg_tambor.jpg',
            opacity: 0.16,
            child: PrestigePage(
              controller: c,
              formatter: widget.controller.formatter,
            ),
          ),
          ShopPage(controller: c, formatter: c.formatter),
        ];
        return PopScope(
          canPop: _tab == _homeTab,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) setState(() => _tab = _homeTab);
          },
          child: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(GameHeader.heightFor(context)),
              child: GameHeader(
                controller: c,
                onGold: () => _go(_shopTab),
                onPairs: () => _go(_prestigeTab),
                onSettings: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SettingsPage(controller: c),
                  ),
                ),
              ),
            ),
            body: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Ui.bg1, Ui.bg2],
                ),
              ),
              child: SafeArea(top: false, child: pages[_tab]),
            ),
            bottomNavigationBar: AnimatedBottomNav(
              selected: _tab,
              onSelect: _go,
              tabs: [
                NavTab(
                  label: 'Mejoras',
                  art: 'icon_ui_mejoras',
                  fallback: Icons.arrow_circle_up,
                  badgeKey: const Key('badge-mejoras'),
                  showBadge: c.hasAffordableUpgrade,
                ),
                NavTab(
                  label: 'Metas',
                  art: 'icon_ui_metas',
                  fallback: Icons.flag,
                  badgeKey: const Key('badge-metas'),
                  showBadge: c.hasGoalNotice,
                ),
                const NavTab(
                  label: 'Negocios',
                  art: 'icon_ui_negocios',
                  fallback: Icons.storefront,
                ),
                const NavTab(
                  label: 'Centrifugado',
                  art: 'icon_ui_centrifugado',
                  fallback: Icons.local_laundry_service,
                ),
                const NavTab(
                  label: 'Tienda',
                  art: 'icon_ui_tienda',
                  fallback: Icons.shopping_bag,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
