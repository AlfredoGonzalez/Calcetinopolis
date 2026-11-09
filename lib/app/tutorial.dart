import 'game_controller.dart';

/// Un paso del tutorial por fases.
///
/// Los pasos se evalúan en orden. Un paso "puerta" ([gate]) detiene a los
/// siguientes hasta cumplirse (la cadena inicial: Tendedero, comprar, Cesto,
/// manager y lavadora). Los demás aparecen cuando se cumple su condición.
class TutorialStep {
  const TutorialStep({
    required this.id,
    required this.target,
    required this.text,
    required this.trigger,
    required this.done,
    this.tab,
    this.gate = false,
  });

  final String id;

  /// Qué se queda iluminado (id de un `TutorialTarget`), según el estado.
  final String Function(GameController c) target;
  final String text;

  /// Cuándo toca mostrarlo.
  final bool Function(GameController c) trigger;

  /// Cuándo se da por cumplido (y deja de mostrarse).
  final bool Function(GameController c) done;

  /// Pestaña que debe estar abierta (null: cualquiera, p. ej. si el destino
  /// es la propia barra inferior).
  final int? tab;
  final bool gate;
}

const tabMejoras = 0;
const tabMetas = 1;
const tabNegocios = 2;
const tabCentrifugado = 3;
const tabTienda = 4;

/// Negocio con manager por contratar y alcance de pago, si lo hay.
int? _hireableManager(GameController c) {
  for (var i = 0; i < c.state.businesses.length; i++) {
    final b = c.state.businesses[i];
    if (b.owned > 0 &&
        !b.hasManager &&
        c.economy.config.businesses[i].manager.cost <= c.state.money) {
      return i;
    }
  }
  return null;
}

bool _canAfford(GameController c, int i) =>
    c.state.money >= c.economy.costOf(c.state, i, 1);

final List<TutorialStep> kTutorialSteps = [
  TutorialStep(
    id: 'tendedero',
    target: (_) => 'biz-0',
    tab: tabNegocios,
    gate: true,
    text:
        'Este es tu Tendedero de pelusas. Cada vez que termina su ciclo '
        'produce Pelusitas. ¡Tócalo para empezar!',
    trigger: (_) => true,
    done: (c) =>
        c.state.businesses[0].running || !c.state.lifetimeEarnings.isZero,
  ),
  TutorialStep(
    id: 'comprar',
    target: (_) => 'buy-0',
    tab: tabNegocios,
    gate: true,
    text:
        'Ya te alcanza para otro Tendedero. Cada uno que compras produce '
        'más: toca Comprar.',
    trigger: (c) => c.state.businesses[0].owned < 2 && _canAfford(c, 0),
    done: (c) => c.state.businesses[0].owned >= 2,
  ),
  TutorialStep(
    id: 'cesto',
    target: (_) => 'buy-1',
    tab: tabNegocios,
    gate: true,
    text:
        'Ya puedes abrir el Cesto de ropa sucia, tu segundo negocio. Más '
        'negocios, más Pelusitas: ¡cómpralo!',
    trigger: (c) => c.isNextToUnlock(1) && _canAfford(c, 1),
    done: (c) => c.state.businesses[1].owned >= 1,
  ),
  TutorialStep(
    id: 'manager',
    target: (c) => 'manager-${_hireableManager(c) ?? 0}',
    tab: tabNegocios,
    gate: true,
    text:
        'Ya puedes contratar a tu primer manager: toca su silueta. Trabaja '
        'solo y sigue produciendo incluso con la app cerrada.',
    trigger: (c) => _hireableManager(c) != null,
    done: (c) => c.state.businesses.any((b) => b.hasManager),
  ),
  TutorialStep(
    id: 'lavadora',
    target: (_) => 'washer',
    tab: tabNegocios,
    gate: true,
    text:
        '¡Tu negocio ya trabaja solo! Ahora toca la lavadora varias veces: '
        'cada toque le da velocidad a todos tus negocios, pero la energía '
        'se va gastando si dejas de tocar.',
    trigger: (_) => true,
    done: (c) => c.washerTaps >= 3,
  ),
  TutorialStep(
    id: 'mejoras',
    target: (_) => 'nav-Mejoras',
    text:
        'Tienes algo asequible en Mejoras. Ahí compras managers, upgrades y '
        'umbrales que multiplican tus ganancias. Entra.',
    trigger: (c) => c.hasAffordableUpgrade,
    done: (c) => c.hasVisitedTab(tabMejoras),
  ),
  TutorialStep(
    id: 'metas',
    target: (_) => 'nav-Metas',
    text:
        'En Metas hay premios por lo que logras y un regalo diario. Tienes '
        'algo por cobrar: ¡entra!',
    trigger: (c) => c.hasGoalNotice,
    done: (c) => c.hasVisitedTab(tabMetas),
  ),
  TutorialStep(
    id: 'centrifugado',
    target: (_) => 'nav-Centrifugado',
    text:
        'Ya puedes Centrifugar: reinicias tu lavandería, pero ganas Parejas '
        'Reunidas, un bono permanente. Entra para ver cuántas ganarías y '
        'cuándo conviene.',
    trigger: (c) => c.pairsPending.isPositive,
    done: (c) => c.hasVisitedTab(tabCentrifugado),
  ),
  TutorialStep(
    id: 'tienda',
    target: (_) => 'nav-Tienda',
    text:
        'La Tienda es opcional: hay Botones Dorados y un impulso de '
        'velocidad. El juego se puede completar sin gastar nada.',
    trigger: (c) => c.state.pairsClaimed.isPositive,
    done: (c) => c.hasVisitedTab(tabTienda),
  ),
];
