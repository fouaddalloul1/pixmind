import 'package:objectbox/objectbox.dart';
import '../../../objectbox.g.dart';
import 'entities.dart';
import 'objectbox_store.dart';

class SecureRepo {
  final ObjectBoxStore _store;
  SecureRepo(this._store);

  Box<SecureFile> get _box => _store.secureBox;

  void addFile(String assetId) {
    // تحقق ما في مكرر
    final exists = _box
        .query(SecureFile_.assetId.equals(assetId))
        .build()
        .findFirst();
    if (exists != null) return;

    _box.put(SecureFile(assetId: assetId, addedAt: DateTime.now()));
  }

  void removeFile(String assetId) {
    final item = _box
        .query(SecureFile_.assetId.equals(assetId))
        .build()
        .findFirst();
    if (item != null) _box.remove(item.id);
  }

  List<String> getAllAssetIds() {
    return _box.getAll().map((f) => f.assetId).toList();
  }

  bool isSecure(String assetId) {
    return _box
            .query(SecureFile_.assetId.equals(assetId))
            .build()
            .findFirst() !=
        null;
  }

  int get count => _box.count();
}
