import '../big_num.dart';

class BusinessState {
  BusinessState({
    this.owned = 0,
    this.hasManager = false,
    this.progress = 0,
    this.running = false,
  });

  int owned;
  bool hasManager;

  /// Avance del ciclo, 0..1 (solo visual si hay manager).
  double progress;

  /// Sin manager: el ciclo corre solo si el jugador tocó el negocio.
  bool running;

  Map<String, Object?> toJson() => {
    'owned': owned,
    'manager': hasManager,
    'progress': progress,
    'running': running,
  };

  factory BusinessState.fromJson(Map<String, dynamic> j) => BusinessState(
    owned: (j['owned'] as num?)?.toInt().clamp(0, 1 << 31) ?? 0,
    hasManager: j['manager'] as bool? ?? false,
    progress: ((j['progress'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
    running: j['running'] as bool? ?? false,
  );

  BusinessState copy() => BusinessState(
    owned: owned,
    hasManager: hasManager,
    progress: progress,
    running: running,
  );
}

/// Ajustes del jugador. Se guardan con la partida y sobreviven al reinicio.
class PlayerSettings {
  PlayerSettings({
    this.numberFormat = 'shortSuffix',
    this.fontScale = 1.0,
    this.sound = true,
    this.vibration = true,
  });

  /// Nombre de `NumberFormatMode`: shortSuffix, names o scientific.
  String numberFormat;
  double fontScale;
  bool sound;
  bool vibration;

  Map<String, Object?> toJson() => {
    'numberFormat': numberFormat,
    'fontScale': fontScale,
    'sound': sound,
    'vibration': vibration,
  };

  factory PlayerSettings.fromJson(Map<String, dynamic>? j) {
    if (j == null) return PlayerSettings();
    final scale = (j['fontScale'] as num?)?.toDouble() ?? 1.0;
    final fmt = j['numberFormat'] as String? ?? 'shortSuffix';
    return PlayerSettings(
      numberFormat: const {'shortSuffix', 'names', 'scientific'}.contains(fmt)
          ? fmt
          : 'shortSuffix',
      fontScale: scale.isNaN ? 1.0 : scale.clamp(0.85, 1.6),
      sound: j['sound'] as bool? ?? true,
      vibration: j['vibration'] as bool? ?? true,
    );
  }

  PlayerSettings copy() => PlayerSettings(
    numberFormat: numberFormat,
    fontScale: fontScale,
    sound: sound,
    vibration: vibration,
  );
}

class GameState {
  GameState({
    required this.businesses,
    BigNum? money,
    BigNum? lifetimeEarnings,
    Set<String>? upgrades,
    BigNum? pairsClaimed,
    BigNum? hilvanes,
    Map<String, int>? shopLevels,
    Set<String>? goalsClaimed,
    this.dailyDay,
    this.dailyStreak = 0,
    this.tutorialDone = false,
    PlayerSettings? settings,
    BigNum? goldButtons,
    this.vip = false,
    this.starterBought = false,
    this.multLevel = 0,
    this.warpDay,
    this.warpCount = 0,
    this.dailyAdDay,
    this.firstReturnDone = false,
    Set<String>? cutscenesSeen,
    Set<String>? tutorialSeen,
    this.boostSeconds = 0,
  }) : money = money ?? BigNum.zero,
       lifetimeEarnings = lifetimeEarnings ?? BigNum.zero,
       upgrades = upgrades ?? <String>{},
       cutscenesSeen = cutscenesSeen ?? <String>{},
       tutorialSeen = tutorialSeen ?? <String>{},
       pairsClaimed = pairsClaimed ?? BigNum.zero,
       hilvanes = hilvanes ?? BigNum.zero,
       shopLevels = shopLevels ?? <String, int>{},
       goalsClaimed = goalsClaimed ?? <String>{},
       settings = settings ?? PlayerSettings(),
       goldButtons = goldButtons ?? BigNum.zero;

  /// Partida nueva: el primer negocio viene gratis (spec 9.2).
  factory GameState.initial(int businessCount) => GameState(
    businesses: List.generate(
      businessCount,
      (i) => BusinessState(owned: i == 0 ? 1 : 0),
    ),
  );

  BigNum money;

  /// E_vida: todo lo ganado en la vida del jugador (nunca se reinicia).
  BigNum lifetimeEarnings;
  final List<BusinessState> businesses;
  final Set<String> upgrades;

  /// Parejas Reunidas ya cobradas: permanentes, nunca se gastan.
  BigNum pairsClaimed;

  /// Hilvanes: moneda gastable de la tienda de prestigio.
  BigNum hilvanes;

  /// Nivel comprado de cada mejora de la tienda de Hilvanes (permanente).
  final Map<String, int> shopLevels;

  /// Metas ya cobradas (permanente).
  final Set<String> goalsClaimed;

  /// Último día en que se cobró el regalo diario ("2026-11-03"), hora local.
  String? dailyDay;

  /// Regalos cobrados en total. No se reinicia si faltas un día: se pausa.
  int dailyStreak;
  bool tutorialDone;

  /// Botones Dorados: moneda premium (no se pierde al centrifugar).
  BigNum goldButtons;

  /// Pase VIP: las recompensas de anuncios se dan sin verlos.
  bool vip;
  bool starterBought;

  /// Nivel comprado del multiplicador permanente (0 a 3).
  int multLevel;

  /// Anuncios de "saltar espera" vistos hoy.
  String? warpDay;
  int warpCount;

  /// Día en que se cobró el bono de Botones Dorados del regalo diario.
  String? dailyAdDay;

  /// Ya vivió su primer regreso (los anuncios no aparecen antes; spec 9.10).
  bool firstReturnDone;

  /// Cutscenes ya vistas (`intro`, `reunion`, `welcome`).
  final Set<String> cutscenesSeen;

  /// Pasos del tutorial ya vistos (ver `lib/app/tutorial.dart`).
  final Set<String> tutorialSeen;
  final PlayerSettings settings;

  /// Segundos restantes de boost por anuncio.
  double boostSeconds;

  /// Bono temporal de la lavadora (0.25 = +25% de velocidad). Se consume solo
  /// y no se guarda: al abrir la app empieza en cero.
  double washerBonus = 0;

  Map<String, Object?> toJson() => {
    'money': money.toJson(),
    'lifetime': lifetimeEarnings.toJson(),
    'businesses': businesses.map((b) => b.toJson()).toList(),
    'upgrades': upgrades.toList()..sort(),
    'pairs': pairsClaimed.toJson(),
    'hilvanes': hilvanes.toJson(),
    'shop': shopLevels,
    'goals': goalsClaimed.toList()..sort(),
    'dailyDay': dailyDay,
    'dailyStreak': dailyStreak,
    'tutorialDone': tutorialDone,
    'gold': goldButtons.toJson(),
    'vip': vip,
    'starterBought': starterBought,
    'multLevel': multLevel,
    'warpDay': warpDay,
    'warpCount': warpCount,
    'dailyAdDay': dailyAdDay,
    'firstReturnDone': firstReturnDone,
    'cutscenesSeen': cutscenesSeen.toList()..sort(),
    'tutorialSeen': tutorialSeen.toList()..sort(),
    'settings': settings.toJson(),
    'boostSeconds': boostSeconds,
  };

  /// Lee un estado guardado. Tolera campos faltantes y cambios en el número
  /// de negocios (se rellenan o se recortan).
  factory GameState.fromJson(Map<String, dynamic> j, int businessCount) {
    BigNum big(Object? v) {
      final n = BigNum.parse((v ?? '0').toString());
      return n.isNegative ? BigNum.zero : n;
    }

    final saved = (j['businesses'] as List? ?? const [])
        .map((e) => BusinessState.fromJson(e as Map<String, dynamic>))
        .toList();
    final list = List.generate(
      businessCount,
      (i) => i < saved.length ? saved[i] : BusinessState(),
    );
    if (list.first.owned == 0) list.first.owned = 1;
    final boost = (j['boostSeconds'] as num?)?.toDouble() ?? 0;
    return GameState(
      businesses: list,
      money: big(j['money']),
      lifetimeEarnings: big(j['lifetime']),
      upgrades: ((j['upgrades'] as List?) ?? const [])
          .map((e) => e as String)
          .toSet(),
      pairsClaimed: big(j['pairs']),
      hilvanes: big(j['hilvanes']),
      shopLevels: {
        for (final e in ((j['shop'] as Map?) ?? const {}).entries)
          if ((e.value as num) > 0) e.key as String: (e.value as num).toInt(),
      },
      goalsClaimed: ((j['goals'] as List?) ?? const [])
          .map((e) => e as String)
          .toSet(),
      dailyDay: j['dailyDay'] as String?,
      dailyStreak: ((j['dailyStreak'] as num?)?.toInt() ?? 0).clamp(0, 1 << 30),
      tutorialDone: j['tutorialDone'] as bool? ?? false,
      goldButtons: big(j['gold']),
      vip: j['vip'] as bool? ?? false,
      starterBought: j['starterBought'] as bool? ?? false,
      multLevel: ((j['multLevel'] as num?)?.toInt() ?? 0).clamp(0, 99),
      warpDay: j['warpDay'] as String?,
      warpCount: ((j['warpCount'] as num?)?.toInt() ?? 0).clamp(0, 1 << 20),
      dailyAdDay: j['dailyAdDay'] as String?,
      firstReturnDone: j['firstReturnDone'] as bool? ?? false,
      cutscenesSeen: {
        for (final e in (j['cutscenesSeen'] as List?) ?? const []) e as String,
      },
      tutorialSeen: {
        for (final e in (j['tutorialSeen'] as List?) ?? const []) e as String,
      },
      settings: PlayerSettings.fromJson(j['settings'] as Map<String, dynamic>?),
      boostSeconds: boost.isNaN || boost < 0 ? 0 : boost,
    );
  }

  GameState copy() => GameState(
    businesses: businesses.map((b) => b.copy()).toList(),
    money: money,
    lifetimeEarnings: lifetimeEarnings,
    upgrades: {...upgrades},
    pairsClaimed: pairsClaimed,
    hilvanes: hilvanes,
    shopLevels: {...shopLevels},
    goalsClaimed: {...goalsClaimed},
    dailyDay: dailyDay,
    dailyStreak: dailyStreak,
    tutorialDone: tutorialDone,
    goldButtons: goldButtons,
    vip: vip,
    starterBought: starterBought,
    multLevel: multLevel,
    warpDay: warpDay,
    warpCount: warpCount,
    dailyAdDay: dailyAdDay,
    firstReturnDone: firstReturnDone,
    cutscenesSeen: {...cutscenesSeen},
    tutorialSeen: {...tutorialSeen},
    settings: settings.copy(),
    boostSeconds: boostSeconds,
  )..washerBonus = washerBonus;
}
