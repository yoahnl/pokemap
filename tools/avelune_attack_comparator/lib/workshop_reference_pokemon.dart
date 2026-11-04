import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

typedef ReferencePokemonPair = ({String attacker, String target});
typedef PreparedReferencePokemon = ({String id, String name});
typedef PreparedReferencePair = ({
  PreparedReferencePokemon attacker,
  PreparedReferencePokemon target,
});

ReferencePokemonPair? referencePokemonForUrl(
  Map<String, dynamic> references,
  String? url,
) {
  final uri = url == null ? null : Uri.tryParse(url);
  if (uri == null || uri.pathSegments.isEmpty) return null;
  final value = references[uri.pathSegments.last];
  if (value is! List || value.length != 2 ||
      value[0] is! String || value[1] is! String) {
    return null;
  }
  final attacker = value[0] as String;
  final target = value[1] as String;
  if (!_safeId.hasMatch(attacker) || !_safeId.hasMatch(target)) return null;
  return (attacker: attacker, target: target);
}

final _safeId = RegExp(r'^[a-z0-9][a-z0-9-]{0,127}$');
final _sha256Tag = RegExp(r'^"sha256-([0-9a-f]{64})"$');

typedef _Sprite = ({String relativePath, bool animated});
typedef _Response = ({Uint8List bytes, String? contentType, String? etag});

final class WorkshopReferencePokemonStore {
  WorkshopReferencePokemonStore({required this.root, Uri? origin})
      : _origin = origin ?? Uri.https('pokemon-api.yoahn.me');

  final Directory root;
  final Uri _origin;
  static const _release = 'public-2026-11-02-bw2';
  static const _timeout = Duration(seconds: 3);
  static const _maxSpriteBytes = 8 * 1024 * 1024;
  final Map<String, Future<_Sprite?>> _sprites = {};
  final Map<String, Future<String?>> _names = {};
  final Map<String, Future<void>> _mediaWrites = {};
  final Set<Future<PreparedReferencePair?>> _pending = {};
  Future<void>? _closing;
  bool _closed = false;

  Future<PreparedReferencePair?> prepare(
    ReferencePokemonPair pair, {
    bool Function()? isCurrent,
  }) {
    if (_closed) return Future.value(null);
    final pending = _prepare(pair, isCurrent: isCurrent);
    _pending.add(pending);
    return pending.whenComplete(() => _pending.remove(pending));
  }

  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    _closed = true;
    await Future.wait(_pending.toList());
  }

  Future<PreparedReferencePair?> _prepare(
    ReferencePokemonPair pair, {
    bool Function()? isCurrent,
  }) async {
    bool current() => !_closed && (isCurrent?.call() ?? true);
    if (!_safeId.hasMatch(pair.attacker) || !_safeId.hasMatch(pair.target) ||
        !current()) {
      return null;
    }
    final names = Future.wait([_name(pair.attacker), _name(pair.target)]);
    try {
      final sprites = await Future.wait([
        _sprite(pair.attacker, 'back'),
        _sprite(pair.target, 'front'),
      ]);
      if (!current() || sprites.any((sprite) => sprite == null)) return null;
      await Future.wait([
        _register(pair.attacker, 'back', sprites[0]!),
        _register(pair.target, 'front', sprites[1]!),
      ]);
      final displayNames = await names;
      if (!current()) return null;
      return (
        attacker: (id: pair.attacker, name: displayNames[0]),
        target: (id: pair.target, name: displayNames[1]),
      );
    } on Object {
      return null;
    }
  }

  Future<_Sprite?> _sprite(String id, String view) async {
    final key = '$id-$view';
    final pending = _sprites.putIfAbsent(key, () => _loadSprite(id, view));
    try {
      final sprite = await pending;
      if (sprite != null) {
        if (!sprite.animated && identical(_sprites[key], pending)) {
          _sprites.remove(key);
        }
        return sprite;
      }
    } on Object catch (_) {}
    if (identical(_sprites[key], pending)) _sprites.remove(key);
    return null;
  }

  Future<_Sprite?> _loadSprite(String id, String view) async {
    for (final animated in [true, false]) {
      final extension = animated ? 'gif' : 'png';
      final relative = 'assets/pokemon/comparator/$id-$view.$extension';
      final file = File(p.join(root.path, relative));
      if (await file.exists()) return (relativePath: relative, animated: animated);
      final type = animated ? 'animated' : 'static';
      final response = await _get('/v1/media/$_release/$id-gen5-$view-$type',
          _maxSpriteBytes);
      final hash = response == null ? null : _sha256Tag.firstMatch(response.etag ?? '');
      if (response == null || hash == null ||
          response.contentType != 'image/$extension' ||
          sha256.convert(response.bytes).toString() != hash[1] ||
          !_hasImageSignature(response.bytes, animated)) {
        continue;
      }
      await file.parent.create(recursive: true);
      final temporary = File('${file.path}.tmp');
      try {
        await temporary.writeAsBytes(response.bytes, flush: true);
        await temporary.rename(file.path);
      } finally {
        if (await temporary.exists()) await temporary.delete();
      }
      return (relativePath: relative, animated: animated);
    }
    return null;
  }

  bool _hasImageSignature(Uint8List bytes, bool animated) {
    final signature = animated
        ? [71, 73, 70, 56]
        : [137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.length < signature.length) return false;
    for (var index = 0; index < signature.length; index++) {
      if (bytes[index] != signature[index]) return false;
    }
    return true;
  }

  Future<String> _name(String id) async {
    final pending = _names.putIfAbsent(id, () => _loadName(id));
    final name = await pending;
    if (name != null) return name;
    if (identical(_names[id], pending)) _names.remove(id);
    return id;
  }

  Future<String?> _loadName(String id) async {
    try {
      final response = await _get('/v1/releases/$_release/pokemon/$id', 256 * 1024);
      if (response == null) return null;
      final doc = jsonDecode(utf8.decode(response.bytes));
      final name = doc is Map && doc['names'] is Map ? doc['names']['fr'] : null;
      return name is String && name.trim().isNotEmpty && name.length <= 128
          ? name : null;
    } on Object {
      return null;
    }
  }

  Future<void> _register(String id, String view, _Sprite sprite) async {
    final previous = _mediaWrites[id] ?? Future<void>.value();
    final write = previous.catchError((Object _) {}).then((_) async {
      final file = File(p.join(root.path, 'data/pokemon/media/$id.json'));
      Map<String, dynamic> doc = {};
      if (await file.exists()) {
        final existing = jsonDecode(await file.readAsString());
        if (existing is Map) doc = Map<String, dynamic>.from(existing);
      }
      final variants = doc['variants'] is Map
          ? Map<String, dynamic>.from(doc['variants'] as Map) : <String, dynamic>{};
      final base = variants['base'] is Map
          ? Map<String, dynamic>.from(variants['base'] as Map) : <String, dynamic>{};
      base['$view${sprite.animated ? 'Animated' : 'Static'}'] = sprite.relativePath;
      variants['base'] = base;
      doc['schemaVersion'] ??= 2;
      doc['speciesId'] ??= id;
      doc['defaultFormId'] ??= 'base';
      doc['variants'] = variants;
      await file.parent.create(recursive: true);
      final temporary = File('${file.path}.tmp');
      try {
        await temporary.writeAsString(jsonEncode(doc), flush: true);
        await temporary.rename(file.path);
      } finally {
        if (await temporary.exists()) await temporary.delete();
      }
    });
    _mediaWrites[id] = write;
    try {
      await write;
    } finally {
      if (identical(_mediaWrites[id], write)) _mediaWrites.remove(id);
    }
  }

  Future<_Response?> _get(String path, int maxBytes) async {
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client.getUrl(_origin.resolve(path)).timeout(_timeout);
      request.followRedirects = false;
      final response = await request.close().timeout(_timeout);
      if (response.statusCode != HttpStatus.ok || response.contentLength > maxBytes) {
        return null;
      }
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in response.timeout(_timeout)) {
        if (bytes.length + chunk.length > maxBytes) return null;
        bytes.add(chunk);
      }
      if (bytes.isEmpty) return null;
      return (
        bytes: bytes.takeBytes(),
        contentType: response.headers.contentType?.mimeType,
        etag: response.headers.value(HttpHeaders.etagHeader),
      );
    } on Object {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
