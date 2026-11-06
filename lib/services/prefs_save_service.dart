import 'services.dart';

import 'package:shared_preferences/shared_preferences.dart';

/// Guardado en el almacenamiento del navegador (localStorage) para la versión
/// web. En Android se usa [FileSaveService].
class PrefsSaveService implements SaveService {
  PrefsSaveService(this._prefs);
  final SharedPreferences _prefs;

  static Future<PrefsSaveService> create() async =>
      PrefsSaveService(await SharedPreferences.getInstance());

  String _key(int slot) => 'calcetinopolis_save_$slot';

  @override
  Future<String?> read(int slot) async => _prefs.getString(_key(slot));

  @override
  Future<void> write(int slot, String data) async {
    await _prefs.setString(_key(slot), data);
  }
}
