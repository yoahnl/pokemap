class UniformKeyCache {
  UniformKeyCache({this.capacity = 256}) : assert(capacity > 0);

  final int capacity;
  final _keys = <String, (String, String?, int?)>{};

  (String, String?, int?) parse(String key) {
    final cached = _keys[key];
    if (cached != null) {
      return cached;
    }

    final parsed = parseUncached(key);
    if (_keys.length == capacity) {
      _keys.remove(_keys.keys.first);
    }
    _keys[key] = parsed;
    return parsed;
  }

  (String, String?, int?) parseUncached(String key) {
    final match = _keyRegex.firstMatch(key);
    if (match == null) {
      throw StateError('Invalid uniform key: "$key"');
    }

    final struct = match.group(1)!;
    final member = match.group(2);
    final index = match.group(3);
    return (struct, member, index != null ? int.parse(index) : null);
  }

  static final _keyRegex = RegExp(r'^(\w+)(?:\.(\w+))?(?:\[(\d+)\])?$');
}
