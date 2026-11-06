import 'package:calcetinopolis/app/save_manager.dart';
import 'package:calcetinopolis/core/big_num.dart';
import 'package:calcetinopolis/core/state/game_state.dart';
import 'package:calcetinopolis/services/prefs_save_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('guardado web (SharedPreferences): ida y vuelta con 3 copias', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await PrefsSaveService.create();
    expect(await store.read(0), isNull);
    final m = SaveManager(store, SaveCodec(10));
    for (var i = 1; i <= 3; i++) {
      await m.save(
        GameState.initial(10)..money = BigNum.fromInt(i),
        DateTime.utc(2026, 11, 6),
      );
    }
    final r = await m.load();
    expect(r.data!.state.money, BigNum.fromInt(3));
    expect(await store.read(2), isNotNull);
  });
}
