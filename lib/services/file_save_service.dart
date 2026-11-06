import 'dart:io';

import 'services.dart';

/// Guardado local en archivos, con escritura atómica (tmp + rename).
class FileSaveService implements SaveService {
  FileSaveService(this.dir);
  final Directory dir;

  File _file(int slot) => File('${dir.path}/save_$slot.json');

  @override
  Future<String?> read(int slot) async {
    final f = _file(slot);
    if (!await f.exists()) return null;
    try {
      return await f.readAsString();
    } on FileSystemException {
      return null;
    }
  }

  @override
  Future<void> write(int slot, String data) async {
    await dir.create(recursive: true);
    final tmp = File('${_file(slot).path}.tmp');
    await tmp.writeAsString(data, flush: true);
    await tmp.rename(_file(slot).path);
  }
}
