import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

class FavoritesManager {
  FavoritesManager._();
  static final instance = FavoritesManager._();

  static const _storageKey = 'favorite_provider_ids';
  final _ids = <String>{};
  bool _loaded = false;

  bool isFav(String id) => _ids.contains(id);
  Set<String> get ids => Set.unmodifiable(_ids);

  Future<void> load() async {
    if (_loaded) return;
    final raw = await _storage.read(key: _storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _ids
          ..clear()
          ..addAll(list.map((id) => id.toString()));
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> _save() async {
    await _storage.write(key: _storageKey, value: jsonEncode(_ids.toList()));
  }

  /// Toggles favorite state. Returns true if now favorited.
  bool toggle(String id) {
    if (_ids.contains(id)) {
      _ids.remove(id);
      _save();
      return false;
    } else {
      _ids.add(id);
      _save();
      return true;
    }
  }
}
