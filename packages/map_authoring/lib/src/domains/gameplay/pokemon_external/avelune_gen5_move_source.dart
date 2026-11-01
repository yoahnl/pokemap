import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_distribution/map_distribution.dart';

import '../../../documents/document_errors.dart';
import 'avelune_catalog_release.dart';
import 'gen5_battle_script_parameters.dart';
import 'gen5_battle_script_source.dart';
import 'gen5_battle_source_dependencies.dart';
import 'pokemon_external_http_transport.dart';

final class AveluneGen5MoveSourceSnapshot {
  AveluneGen5MoveSourceSnapshot._({
    required this.release,
    required this.moveId,
    required this.sourceMoveId,
    required this.sourceRevision,
    required this.redistributionStatus,
    required this.audioStatus,
    required this.playbackStatus,
    required this.scriptBytes,
    required this.particleBytes,
    required Map<String, Uint8List> textureBytes,
    required this.diagnostic,
  }) : textureBytes = Map.unmodifiable(textureBytes);

  final String release;
  final String moveId;
  final int sourceMoveId;
  final String sourceRevision;
  final String redistributionStatus;
  final String audioStatus;
  final String playbackStatus;
  final Uint8List scriptBytes;
  final Uint8List particleBytes;
  final Map<String, Uint8List> textureBytes;
  final Gen5BattleSourceDependencies diagnostic;
}

final class AveluneGen5MoveSource {
  AveluneGen5MoveSource({
    required PokemonBoundedExternalHttpTransport client,
    this.baseUri = const String.fromEnvironment(
      'AVELUNE_SNAPSHOT_BASE_URI',
      defaultValue: 'https://pokemon-api.yoahn.me/v1/snapshots',
    ),
    this.release = aveluneCatalogRelease,
    this.requestTimeout = const Duration(seconds: 20),
    this.maximumBytes = 2 * 1024 * 1024,
  }) : _client = client {
    final uri = Uri.parse(baseUri);
    if (uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !_releasePattern.hasMatch(release) ||
        requestTimeout <= Duration.zero ||
        maximumBytes < 1 ||
        maximumBytes > 2 * 1024 * 1024) {
      throw ArgumentError('Invalid Gen 5 move source configuration');
    }
  }

  final PokemonBoundedExternalHttpTransport _client;
  final String baseUri;
  final String release;
  final Duration requestTimeout;
  final int maximumBytes;

  static final _releasePattern = RegExp(r'^[a-z0-9][a-z0-9-]{0,127}$');
  static final _movePattern = RegExp(r'^[a-z0-9][a-z0-9-]{0,99}$');
  static final _revisionPattern = RegExp(r'^[a-f0-9]{40}$');
  static final _textureName = RegExp(r'^[A-Za-z0-9_]{1,64}$');

  Future<AveluneGen5MoveSourceSnapshot?> fetch({
    required String moveId,
    required int sourceMoveId,
  }) async {
    if (!_movePattern.hasMatch(moveId) ||
        sourceMoveId < 1 ||
        sourceMoveId > 65535) {
      throw ArgumentError('Invalid Gen 5 move source request');
    }
    final base = Uri.parse(baseUri.endsWith('/') ? baseUri : '$baseUri/');
    final response = await _client.getBounded(
      base.resolve('$release/gen5-move/$sourceMoveId'),
      headers: const {'accept': 'application/json'},
      maximumBytes: maximumBytes,
      timeout: requestTimeout,
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EditorPersistenceException(
        'Gen 5 move source request failed with HTTP ${response.statusCode}',
      );
    }
    if (response.bodyBytes.isEmpty ||
        response.bodyBytes.length > maximumBytes) {
      throw const FormatException('Invalid Gen 5 move source response size');
    }
    final revisions = response.headers.entries
        .where((entry) => entry.key.toLowerCase() == 'x-source-revision')
        .map((entry) => entry.value)
        .toList();
    if (revisions.length != 1 || !_revisionPattern.hasMatch(revisions.single)) {
      throw const FormatException('Invalid Gen 5 move source revision header');
    }
    final jsonText = utf8.decode(response.bodyBytes);
    try {
      const StrictJsonStructureValidator().validate(
        jsonText,
        path: 'gen5-move-source',
        maxDepth: 16,
        maxNodes: 20000,
      );
    } on GamePackageFormatException {
      throw const FormatException('Invalid Gen 5 move source JSON');
    }
    final document = _object(jsonDecode(jsonText), {
      'release',
      'format',
      'game',
      'move',
      'source',
      'completeness',
      'script',
      'particles',
    });
    if (document['release'] != release ||
        document['format'] != 'gen5-move-source-v1' ||
        document['game'] != 'black2-white2') {
      throw const FormatException('Invalid Gen 5 move source identity');
    }
    final move = _object(document['move'], {'id', 'sourceId'});
    if (move['id'] != moveId || move['sourceId'] != sourceMoveId) {
      throw const FormatException('Gen 5 source belongs to another move');
    }
    final source = _object(document['source'], {
      'repository',
      'revision',
      'redistributionStatus',
    });
    if (source['repository'] != 'fuddlesworth/pokebw2' ||
        source['revision'] != revisions.single ||
        source['redistributionStatus'] != 'unverified') {
      throw const FormatException('Invalid Gen 5 move source provenance');
    }
    final completeness =
        _object(document['completeness'], {'audio', 'playback'});
    if (completeness['audio'] != 'missing-sequences-banks-and-commands' ||
        completeness['playback'] != 'not-supported') {
      throw const FormatException('Unsupported Gen 5 move source completeness');
    }
    final scriptFile = _SourceFile.read(document['script']);
    if (scriptFile.path !=
            'res/battle/animations/moves/${moveId.replaceAll('-', '_')}.s' ||
        scriptFile.size > 64 * 1024) {
      throw const FormatException('Invalid Gen 5 move script file');
    }
    final particles = document['particles'];
    if (particles is! List || particles.length != 1) {
      throw const FormatException('Unsupported Gen 5 particle source count');
    }
    final particle =
        _object(particles.single, {'id', 'definition', 'textures'});
    final particleId = particle['id'];
    if (particleId is! int || particleId < 0 || particleId > 65535) {
      throw const FormatException('Invalid Gen 5 particle source id');
    }
    final definition = _SourceFile.read(particle['definition']);
    if (definition.path !=
            'res/particles/btlv_effvm_particles/$particleId/particles.json' ||
        definition.size > 262144) {
      throw const FormatException('Invalid Gen 5 particle definition file');
    }
    final rawTextures = particle['textures'];
    if (rawTextures is! List || rawTextures.length > 64) {
      throw const FormatException('Invalid Gen 5 texture sources');
    }
    final textureFiles = <String, _SourceFile>{};
    for (final raw in rawTextures) {
      final item =
          _object(raw, {'name', 'path', 'size', 'sha256', 'encoding', 'data'});
      final name = item['name'];
      if (name is! String ||
          !_textureName.hasMatch(name) ||
          textureFiles.containsKey(name)) {
        throw const FormatException('Invalid Gen 5 texture identity');
      }
      final file = _SourceFile.read(item, texture: true);
      if (file.path !=
          'res/particles/btlv_effvm_particles/$particleId/$name.png') {
        throw const FormatException('Invalid Gen 5 texture source path');
      }
      textureFiles[name] = file;
    }
    final total = scriptFile.size +
        definition.size +
        textureFiles.values.fold<int>(0, (sum, file) => sum + file.size);
    if (total > 1024 * 1024) {
      throw const FormatException('Gen 5 move source exceeds byte budget');
    }
    final scriptBytes = scriptFile.decode();
    final particleBytes = definition.decode();
    final textures = <String, Uint8List>{
      for (final entry in textureFiles.entries) entry.key: entry.value.decode(),
    };
    final script = Gen5BattleScriptParameters.read(Gen5BattleScriptSource.read(
      scriptBytes,
      sourceRevision: revisions.single,
      sourcePath: scriptFile.path,
      expectedSha256: scriptFile.sha256Hex,
    ));
    final diagnostic = Gen5BattleSourceDependencies.inspect(
      script: script,
      particleId: particleId,
      particleBytes: particleBytes,
      particleRevision: revisions.single,
      particlePath: definition.path,
      particleSha256: definition.sha256Hex,
      textures: {
        for (final entry in textureFiles.entries)
          entry.key: Gen5BattleTextureSource(
            sourcePath: entry.value.path,
            sizeBytes: entry.value.size,
            sha256Hex: entry.value.sha256Hex,
            bytes: textures[entry.key]!,
          ),
      },
    );
    if (diagnostic.missingTextures.isNotEmpty) {
      throw const FormatException('Gen 5 move source is missing textures');
    }
    return AveluneGen5MoveSourceSnapshot._(
      release: release,
      moveId: moveId,
      sourceMoveId: sourceMoveId,
      sourceRevision: revisions.single,
      redistributionStatus: source['redistributionStatus'] as String,
      audioStatus: completeness['audio'] as String,
      playbackStatus: completeness['playback'] as String,
      scriptBytes: scriptBytes,
      particleBytes: particleBytes,
      textureBytes: textures,
      diagnostic: diagnostic,
    );
  }
}

Map<String, dynamic> _object(Object? value, Set<String> keys) {
  if (value is! Map<String, dynamic> ||
      value.length != keys.length ||
      !keys.containsAll(value.keys)) {
    throw const FormatException('Invalid Gen 5 source object');
  }
  return value;
}

final class _SourceFile {
  const _SourceFile(this.path, this.size, this.sha256Hex, this.encoded);

  final String path;
  final int size;
  final String sha256Hex;
  final String encoded;

  static final _sha256Pattern = RegExp(r'^[a-f0-9]{64}$');

  static _SourceFile read(Object? raw, {bool texture = false}) {
    final item = _object(raw, {
      if (texture) 'name',
      'path',
      'size',
      'sha256',
      'encoding',
      'data',
    });
    final path = item['path'];
    final size = item['size'];
    final digest = item['sha256'];
    final encoded = item['data'];
    if (path is! String ||
        path.isEmpty ||
        path.length > 512 ||
        size is! int ||
        size < 1 ||
        size > 1024 * 1024 ||
        digest is! String ||
        !_sha256Pattern.hasMatch(digest) ||
        item['encoding'] != 'base64' ||
        encoded is! String ||
        encoded.length != ((size + 2) ~/ 3) * 4) {
      throw const FormatException('Invalid Gen 5 source file');
    }
    return _SourceFile(path, size, digest, encoded);
  }

  Uint8List decode() {
    final bytes = base64.decode(encoded);
    if (bytes.length != size ||
        base64.encode(bytes) != encoded ||
        sha256.convert(bytes).toString() != sha256Hex) {
      throw const FormatException('Invalid Gen 5 source file bytes');
    }
    return bytes.asUnmodifiableView();
  }
}
