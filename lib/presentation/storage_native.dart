import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SaveStore {
  Future<void> _queue = Future.value();
  void _check(String slot) {
    if (!RegExp(
      r'^(packages|(world|branch|legacy)_[0-2]|rules_[0-2]_[a-f0-9]{64})$',
    ).hasMatch(slot)) {
      throw const FormatException('Espacio de guardado inválido');
    }
  }

  Future<Directory> get _root async {
    final root = Directory(
      '${(await getApplicationDocumentsDirectory()).path}/barrio_cero',
    );
    await root.create(recursive: true);
    return root;
  }

  Future<void> write(String slot, String value) {
    _check(slot);
    final result = _queue.catchError((Object _) {}).then((_) async {
      final root = await _root;
      final target = File('${root.path}/$slot.json');
      final temp = File('${root.path}/$slot.pending');
      await temp.writeAsString(value, flush: true);
      if (await target.exists()) {
        final previous = File('${root.path}/$slot.backup.pending');
        await previous.writeAsBytes(await target.readAsBytes(), flush: true);
        await previous.rename('${root.path}/$slot.backup.json');
      }
      await temp.rename(target.path);
    });
    _queue = result;
    return result;
  }

  Future<String?> read(String slot, {bool backup = false}) async {
    _check(slot);
    await _queue.catchError((Object _) {});
    final root = await _root;
    final file = File('${root.path}/$slot${backup ? '.backup' : ''}.json');
    return await file.exists() ? file.readAsString() : null;
  }
}
