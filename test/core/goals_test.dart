import 'dart:convert';
import 'dart:io';

import 'package:calcetinopolis/core/big_num.dart';
import 'package:calcetinopolis/core/config/economy_config.dart';
import 'package:calcetinopolis/core/economy/engine.dart';
import 'package:calcetinopolis/core/state/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

BigNum n(String s) => BigNum.parse(s);

void main() {
  final source = File('config/economy.json').readAsStringSync();
  final config = EconomyConfig.fromJsonString(source);
  final eco = Economy(config);
  late GameState s;
  setUp(() => s = eco.newGame());

  group('metas', () {
    test('hay una ruta de metas válida y ordenada por dificultad', () {
      expect(config.goals.length, greaterThanOrEqualTo(15));
      expect(config.goals.map((g) => g.id).toSet().length, config.goals.length);
      for (final g in config.goals) {
        expect(
          g.rewardMoney.isPositive || g.rewardHilvanes.isPositive,
          isTrue,
          reason: g.id,
        );
      }
    });

    test('cada tipo mide lo que dice', () {
      GoalConfig of(String type) =>
          config.goals.firstWhere((g) => g.type == type);
      s.businesses[0].owned = 30;
      expect(
        eco.goalCurrent(s, of('own')),
        BigNum.fromInt(eco.goalCurrent(s, of('own')).toInt()),
      );
      expect(
        eco.goalCurrent(s, config.goals.firstWhere((g) => g.id == 'own25')),
        n('30'),
      );
      s.businesses[0].hasManager = true;
      s.businesses[2].hasManager = true;
      expect(eco.goalCurrent(s, of('managers')), n('2'));
      s.businesses[1].owned = 1;
      expect(eco.goalCurrent(s, of('businesses')), n('2'));
      for (final b in s.businesses) {
        b.owned = 25;
      }
      s.businesses[4].owned = 7;
      expect(eco.goalCurrent(s, of('all_owned')), n('7'));
      s.lifetimeEarnings = n('5e9');
      expect(eco.goalCurrent(s, of('lifetime')), n('5e9'));
      s.pairsClaimed = n('42');
      expect(eco.goalCurrent(s, of('pairs')), n('42'));
      s.upgrades.addAll(['a', 'b', 'c']);
      expect(eco.goalCurrent(s, of('upgrades')), n('3'));
    });

    test('progreso 0..1 y cumplida', () {
      final g = config.goals.firstWhere((g) => g.id == 'own25');
      s.businesses[0].owned = 5;
      expect(eco.goalProgress(s, g), closeTo(0.2, 1e-9));
      expect(eco.goalMet(s, g), isFalse);
      s.businesses[0].owned = 99;
      expect(eco.goalProgress(s, g), 1);
      expect(eco.goalMet(s, g), isTrue);
    });

    test('reclamar paga una vez, y sin cumplir no paga', () {
      expect(eco.claimGoal(s, 'first_manager'), isFalse);
      s.businesses[0].hasManager = true;
      final before = s.money;
      expect(eco.canClaimGoal(s, 'first_manager'), isTrue);
      expect(eco.claimGoal(s, 'first_manager'), isTrue);
      expect(s.money - before, eco.goal('first_manager').rewardMoney);
      expect(eco.claimGoal(s, 'first_manager'), isFalse, reason: 'ya cobrada');
    });

    test('recompensas en Hilvanes', () {
      s.pairsClaimed = n('1');
      expect(eco.claimGoal(s, 'first_pair'), isTrue);
      expect(s.hilvanes, eco.goal('first_pair').rewardHilvanes);
    });

    test('las Pelusitas de metas no inflan E_vida (prestigio)', () {
      s.businesses[0].owned = 10;
      eco.claimGoal(s, 'own10');
      expect(s.lifetimeEarnings, BigNum.zero);
      expect(s.money.isPositive, isTrue);
    });

    test('lo cobrado sobrevive al Centrifugado', () {
      s.businesses[0].hasManager = true;
      eco.claimGoal(s, 'first_manager');
      s.lifetimeEarnings = n('1e13');
      eco.prestige(s);
      expect(s.goalsClaimed, contains('first_manager'));
      expect(eco.canClaimGoal(s, 'first_manager'), isFalse);
    });

    test('hasClaimableGoal', () {
      expect(eco.hasClaimableGoal(s), isFalse);
      s.businesses[0].owned = 10;
      expect(eco.hasClaimableGoal(s), isTrue);
      eco.claimGoal(s, 'own10');
      expect(eco.hasClaimableGoal(s), isFalse);
    });

    test('la config rechaza metas inválidas', () {
      Map<String, dynamic> mutate(void Function(List goals) f) {
        final m = jsonDecode(source) as Map<String, dynamic>;
        f(m['goals'] as List);
        return m;
      }

      expect(
        () => EconomyConfig.fromJson(mutate((g) => g[0]['type'] = 'inventada')),
        throwsFormatException,
      );
      expect(
        () => EconomyConfig.fromJson(mutate((g) => g[0]['business'] = 'nada')),
        throwsFormatException,
      );
      expect(
        () => EconomyConfig.fromJson(mutate((g) => g[1]['id'] = g[0]['id'])),
        throwsFormatException,
      );
      expect(
        () => EconomyConfig.fromJson(mutate((g) => g[0]['target'] = '0')),
        throwsFormatException,
      );
    });
  });

  group('regalo diario', () {
    final day1 = DateTime(2026, 11, 3, 9);

    test('un regalo por día', () {
      expect(eco.canClaimDaily(s, day1), isTrue);
      final r = eco.claimDaily(s, day1)!;
      expect(r.streak, 1);
      expect(s.dailyStreak, 1);
      expect(s.money, r.money);
      expect(eco.canClaimDaily(s, DateTime(2026, 11, 3, 23, 59)), isFalse);
      expect(eco.claimDaily(s, day1), isNull);
      expect(eco.canClaimDaily(s, DateTime(2026, 11, 4, 0, 1)), isTrue);
    });

    test('la racha suma al día siguiente', () {
      eco.claimDaily(s, day1);
      final r = eco.claimDaily(s, DateTime(2026, 11, 4, 8))!;
      expect(r.streak, 2);
    });

    test('si faltas días la racha se pausa, no vuelve a cero', () {
      eco.claimDaily(s, day1);
      eco.claimDaily(s, DateTime(2026, 11, 4));
      final r = eco.claimDaily(s, DateTime(2026, 11, 20))!;
      expect(r.streak, 3);
    });

    test('reloj atrasado: no hay regalo extra', () {
      eco.claimDaily(s, DateTime(2026, 11, 10));
      expect(eco.canClaimDaily(s, DateTime(2026, 11, 5)), isFalse);
      expect(eco.claimDaily(s, DateTime(2026, 11, 5)), isNull);
    });

    test('mínimo al inicio y crece con el ingreso', () {
      final base = eco.dailyPreview(s).money;
      expect(base, config.daily!.baseMoney);
      s.businesses[0]
        ..owned = 200
        ..hasManager = true;
      final rich = eco.dailyPreview(s).money;
      expect(rich > base, isTrue);
      expect(
        rich,
        eco.managedIncomePerSecond(s).mulDouble(60 * config.daily!.minutes),
      );
    });

    test('el valor sube con la racha y el día 7 da Hilvanes', () {
      s.businesses[0]
        ..owned = 200
        ..hasManager = true;
      final first = eco.dailyPreview(s).money;
      s.dailyStreak = 1;
      expect(eco.dailyPreview(s).money > first, isTrue);
      s.dailyStreak = 6;
      final seven = eco.dailyPreview(s);
      expect(seven.streak, 7);
      expect(seven.hilvanes, config.daily!.hilvanes);
      s.dailyStreak = 7;
      expect(eco.dailyPreview(s).hilvanes, BigNum.zero);
      expect(
        eco.dailyPreview(s).money,
        first,
        reason: 'el ciclo de 7 días reinicia el valor',
      );
    });

    test('la clave de día es estable', () {
      expect(Economy.dayKey(DateTime(2026, 1, 5)), '2026-01-05');
    });
  });
}
