class FavoritesManager {
  FavoritesManager._();
  static final instance = FavoritesManager._();

  final _ids = <String>{};

  bool isFav(String id) => _ids.contains(id);

  /// Toggles favorite state. Returns true if now favorited.
  bool toggle(String id) {
    if (_ids.contains(id)) {
      _ids.remove(id);
      return false;
    } else {
      _ids.add(id);
      return true;
    }
  }
}
