import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

final class PreparedNarrativeCacheUnavailable implements Exception {
  const PreparedNarrativeCacheUnavailable();
}

final class HubPreparedNarrativeIndex {
  HubPreparedNarrativeIndex({required this.supportRoot});

  static const validatorVersion = 1;
  static const _maximumBytes = 128 * 1024 * 1024;
  static final _pending = <String, Future<void>>{};
  static final _pendingKeys = <String, Future<List<int>?>>{};
  final Directory supportRoot;

  File fileFor(GamePackageManifest manifest) {
    GameIdentity.validateGameId(manifest.gameId);
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(manifest.content.treeSha256)) {
      throw const FormatException(
        'Invalid prepared narrative content identity.',
      );
    }
    return File(
      p.join(
        supportRoot.path,
        'runtime-narrative',
        '${manifest.gameId}-${manifest.content.treeSha256}-$validatorVersion.index',
      ),
    );
  }

  Future<List<NarrativeMapProjection>?> load(
    GamePackageManifest manifest,
  ) async {
    try {
      final file = fileFor(manifest);
      if (!await _safeCacheDirectory(create: false) ||
          await FileSystemEntity.type(file.path, followLinks: false) !=
              FileSystemEntityType.file ||
          await file.length() > _maximumBytes) {
        return null;
      }
      final key = await _key(create: false);
      if (key == null) return null;
      final builder = BytesBuilder(copy: false);
      await for (final chunk in file.openRead()) {
        if (builder.length + chunk.length > _maximumBytes) return null;
        builder.add(chunk);
      }
      final bytes = builder.takeBytes();
      if (bytes.length < 33) return null;
      final body = Uint8List.sublistView(bytes, 32);
      final signature = Hmac(sha256, key).convert(body).bytes;
      var difference = 0;
      for (var index = 0; index < 32; index++) {
        difference |= bytes[index] ^ signature[index];
      }
      if (difference != 0) return null;
      return await _decodeCorpus(
        body,
        manifest.gameId,
        manifest.content.treeSha256,
      );
    } on Object {
      return null;
    }
  }

  static Future<List<NarrativeMapProjection>> _decodeCorpus(
    Uint8List body,
    String gameId,
    String treeSha256,
  ) => Isolate.run(() async {
    final output = BytesBuilder(copy: false);
    await for (final chunk in gzip.decoder.bind(Stream.value(body))) {
      if (output.length + chunk.length > _maximumBytes) {
        throw const PreparedNarrativeCacheUnavailable();
      }
      output.add(chunk);
    }
    final json = decodeNarrativeEventJsonStrict(
      utf8.decode(output.takeBytes()),
    );
    if (json is! Map<String, Object?> ||
        json.length != 5 ||
        json['format'] != 'avelune.runtime-narrative' ||
        json['validatorVersion'] is! int ||
        json['validatorVersion'] != validatorVersion ||
        json['gameId'] != gameId ||
        json['treeSha256'] != treeSha256 ||
        json['maps'] is! List) {
      throw const FormatException(
        'Prepared narrative index identity mismatch.',
      );
    }
    return List<NarrativeMapProjection>.unmodifiable([
      for (final map in json['maps']! as List)
        NarrativeMapProjection.fromJson(Map<String, Object?>.from(map as Map)),
    ]);
  });

  Future<void> prepare({
    required Directory versionRoot,
    required GamePackageManifest manifest,
  }) {
    final identity = p.normalize(p.absolute(fileFor(manifest).path));
    return _pending.putIfAbsent(identity, () async {
      try {
        await _prepare(versionRoot, manifest);
      } finally {
        _pending.remove(identity);
      }
    });
  }

  Future<void> _prepare(
    Directory versionRoot,
    GamePackageManifest manifest,
  ) async {
    await _verifySource(versionRoot, manifest, ['project/project.json']);
    final projectFile = File(
      p.join(versionRoot.path, 'project', 'project.json'),
    );
    final inventory = {
      for (final entry in manifest.content.files) entry.path: entry,
    };
    final catalog = await RuntimeProjectCatalog.open(
      projectFile.path,
      expectedSourceSha256: inventory['project/project.json']!.sha256,
    );
    try {
      final project = catalog.projectMetadata;
      final registry = project.eventRegistry;
      if (registry == null ||
          (registry.mode == EventSystemMode.legacyOnly &&
              !registry.hasLocalRuntimeAuthority)) {
        return;
      }
      final mapPaths = [
        for (final entry in project.maps) 'project/${entry.relativePath}',
      ];
      await _verifySource(versionRoot, manifest, mapPaths);
      final maps = await catalog.loadNarrativeMapData(
        expectedSha256ByMapId: {
          for (final entry in project.maps)
            entry.id: inventory['project/${entry.relativePath}']!.sha256,
        },
      );
      final mapsById = {for (final map in maps) map.id: map};
      await NarrativeEventRuntimeSnapshot.build(
        project: project,
        loadMap: (id) async => (
          project: project,
          map:
              mapsById[id] ??
              (throw const FormatException('Missing narrative map.')),
        ),
      );
      final corpus = await _projectMaps(maps);
      await _verifySource(versionRoot, manifest, [
        'project/project.json',
        ...mapPaths,
      ]);
      if (!await catalog.isCurrentPublication()) {
        throw const FormatException(
          'Project changed while preparing narrative data.',
        );
      }
      final encoded = await _encodeCorpus(
        corpus,
        manifest.gameId,
        manifest.content.treeSha256,
      );
      if (encoded.length + 32 > _maximumBytes) {
        throw const PreparedNarrativeCacheUnavailable();
      }
      try {
        await _safeCacheDirectory(create: true);
        final key = (await _key(create: true))!;
        final signature = Hmac(sha256, key).convert(encoded).bytes;
        final file = fileFor(manifest);
        final temporary = File(
          '${file.path}.$pid.${Random.secure().nextInt(1 << 32)}.tmp',
        );
        try {
          await temporary.create(exclusive: true);
          await temporary.writeAsBytes([...signature, ...encoded], flush: true);
          if (await FileSystemEntity.type(file.path, followLinks: false) ==
              FileSystemEntityType.link) {
            throw const PreparedNarrativeCacheUnavailable();
          }
          await temporary.rename(file.path);
        } finally {
          if (await temporary.exists()) await temporary.delete();
        }
      } on FileSystemException {
        throw const PreparedNarrativeCacheUnavailable();
      }
    } finally {
      catalog.dispose();
    }
  }

  static Future<List<int>> _encodeCorpus(
    List<Map<String, Object?>> corpus,
    String gameId,
    String treeSha256,
  ) => Isolate.run(() {
    final bytes = utf8.encode(
      jsonEncode({
        'format': 'avelune.runtime-narrative',
        'validatorVersion': validatorVersion,
        'gameId': gameId,
        'treeSha256': treeSha256,
        'maps': corpus,
      }),
    );
    if (bytes.length > _maximumBytes) {
      throw const PreparedNarrativeCacheUnavailable();
    }
    return gzip.encode(bytes);
  });
  Future<bool> _safeCacheDirectory({required bool create}) async {
    final directory = Directory(p.join(supportRoot.path, 'runtime-narrative'));
    var type = await FileSystemEntity.type(directory.path, followLinks: false);
    if (type == FileSystemEntityType.notFound && create) {
      await directory.create(recursive: true);
      type = await FileSystemEntity.type(directory.path, followLinks: false);
    }
    if (type == FileSystemEntityType.notFound) return false;
    if (type != FileSystemEntityType.directory) {
      throw const PreparedNarrativeCacheUnavailable();
    }
    final canonicalRoot = await supportRoot.resolveSymbolicLinks();
    if (!p.isWithin(canonicalRoot, await directory.resolveSymbolicLinks())) {
      throw const PreparedNarrativeCacheUnavailable();
    }
    return true;
  }

  Future<List<int>?> _key({required bool create}) async {
    final identity = p.normalize(p.absolute(supportRoot.path));
    final pending = _pendingKeys[identity];
    if (pending != null) {
      final result = await pending;
      if (result != null || !create) return result;
      return _key(create: true);
    }
    final operation = _readOrCreateKey(create: create);
    _pendingKeys[identity] = operation;
    try {
      return await operation;
    } finally {
      if (identical(_pendingKeys[identity], operation)) {
        _pendingKeys.remove(identity);
      }
    }
  }

  Future<List<int>?> _readOrCreateKey({required bool create}) async {
    final file = File(p.join(supportRoot.path, 'runtime-narrative', '.key'));
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type != FileSystemEntityType.notFound &&
        type != FileSystemEntityType.file) {
      throw const PreparedNarrativeCacheUnavailable();
    }
    if (type == FileSystemEntityType.file && await file.length() == 32) {
      return file.readAsBytes();
    }
    if (!create) return null;
    final temporary = File(
      '${file.path}.$pid.${Random.secure().nextInt(1 << 32)}.tmp',
    );
    try {
      await temporary.create(exclusive: true);
      final random = Random.secure();
      await temporary.writeAsBytes(
        List.generate(32, (_) => random.nextInt(256)),
        flush: true,
      );
      if (await FileSystemEntity.type(file.path, followLinks: false) ==
          FileSystemEntityType.link) {
        throw const PreparedNarrativeCacheUnavailable();
      }
      await temporary.rename(file.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
    return file.readAsBytes();
  }
}

Future<List<Map<String, Object?>>> _projectMaps(List<MapData> maps) =>
    Isolate.run(
      () => [
        for (final map in maps)
          NarrativeMapProjection.fromMapData(map).toJson(),
      ],
    );

Future<void> _verifySource(
  Directory root,
  GamePackageManifest manifest,
  List<String> paths,
) => Isolate.run(() async {
  final entries = {
    for (final entry in manifest.content.files) entry.path: entry,
  };
  final canonicalRoot = await root.resolveSymbolicLinks();
  for (final path in paths) {
    final entry = entries[path];
    final file = File(p.join(root.path, path));
    if (entry == null ||
        !p.isWithin(canonicalRoot, await file.resolveSymbolicLinks()) ||
        await FileSystemEntity.type(file.path, followLinks: false) !=
            FileSystemEntityType.file ||
        await file.length() != entry.size ||
        (await sha256.bind(file.openRead()).first).toString() != entry.sha256) {
      throw const FormatException(
        'Narrative source does not match the verified inventory.',
      );
    }
  }
});
