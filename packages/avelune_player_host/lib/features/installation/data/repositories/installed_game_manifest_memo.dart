import 'dart:io';

import 'package:map_distribution/map_distribution.dart';

typedef InstalledGameManifestDecoder = Future<GamePackageManifest> Function(
  String path,
);

final class InstalledGameManifestStamp {
  const InstalledGameManifestStamp._(
    this.path,
    this.size,
    this.modifiedMicros,
    this.changedMicros,
  );

  factory InstalledGameManifestStamp.of(String path) {
    final stat = FileStat.statSync(path);
    return InstalledGameManifestStamp._(
      path,
      stat.type == FileSystemEntityType.file ? stat.size : -1,
      stat.modified.microsecondsSinceEpoch,
      stat.changed.microsecondsSinceEpoch,
    );
  }

  final String path;
  final int size;
  final int modifiedMicros;
  final int changedMicros;

  bool get describesFile => size >= 0;

  @override
  bool operator ==(Object other) =>
      other is InstalledGameManifestStamp &&
      other.path == path &&
      other.size == size &&
      other.modifiedMicros == modifiedMicros &&
      other.changedMicros == changedMicros;

  @override
  int get hashCode => Object.hash(path, size, modifiedMicros, changedMicros);
}

final class InstalledGameDecodedManifest {
  const InstalledGameDecodedManifest(this.stamp, this.manifest);

  final InstalledGameManifestStamp stamp;
  final GamePackageManifest manifest;
}

final class InstalledGameManifestMemo {
  InstalledGameManifestMemo({this.capacity = 2}) : assert(capacity > 0);

  final int capacity;
  final _entries = <String, InstalledGameDecodedManifest>{};
  final _pending = <InstalledGameManifestStamp, Future<GamePackageManifest>>{};

  InstalledGameDecodedManifest? peek(String path) => _entries[path];

  void remember(InstalledGameDecodedManifest decoded) {
    if (!decoded.stamp.describesFile) return;
    _entries
      ..remove(decoded.stamp.path)
      ..[decoded.stamp.path] = decoded;
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  Future<GamePackageManifest> read(
    String path,
    InstalledGameManifestDecoder decode,
  ) {
    final stamp = InstalledGameManifestStamp.of(path);
    final known = _entries[path];
    if (known != null && known.stamp == stamp) {
      return Future<GamePackageManifest>.value(known.manifest);
    }
    final pending = _pending[stamp];
    if (pending != null) return pending;
    final decoding = _decode(stamp, decode);
    _pending[stamp] = decoding;
    return decoding;
  }

  Future<GamePackageManifest> _decode(
    InstalledGameManifestStamp stamp,
    InstalledGameManifestDecoder decode,
  ) async {
    try {
      final manifest = await decode(stamp.path);
      remember(InstalledGameDecodedManifest(stamp, manifest));
      return manifest;
    } finally {
      _pending.remove(stamp);
    }
  }
}

Future<InstalledGameDecodedManifest> readInstalledGameManifestOnce(
  String path, {
  InstalledGameDecodedManifest? known,
  required InstalledGameManifestDecoder decode,
}) async {
  final stamp = InstalledGameManifestStamp.of(path);
  if (known != null && known.stamp == stamp) return known;
  return InstalledGameDecodedManifest(stamp, await decode(path));
}
