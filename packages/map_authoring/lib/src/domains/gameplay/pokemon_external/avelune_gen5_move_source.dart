import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_distribution/map_distribution.dart';

import '../../../documents/document_errors.dart';
import 'avelune_catalog_release.dart';
import 'gen5_battle_script_parameters.dart';
import 'gen5_battle_script_source.dart';
import 'gen5_battle_script_symbols.dart';
import 'gen5_battle_source_dependencies.dart';
import 'pokemon_external_http_transport.dart';

final class AveluneGen5MoveParticleSource {
  AveluneGen5MoveParticleSource._({
    required this.id,
    required this.definitionBytes,
    required this.definitionSha256,
    required Map<String, Uint8List> textureBytes,
    required Map<String, String> textureSha256,
  })  : textureBytes = Map.unmodifiable(textureBytes),
        textureSha256 = Map.unmodifiable(textureSha256);

  final int id;
  final Uint8List definitionBytes;
  final String definitionSha256;
  final Map<String, Uint8List> textureBytes;
  final Map<String, String> textureSha256;
}

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
    required this.scriptPath,
    required this.scriptSha256,
    required Map<int, AveluneGen5MoveParticleSource> particles,
    required this.reportedDependencyStatus,
    required this.effectiveDependencyStatus,
    required this.particleDependencyInventoryVerified,
    required List<int> missingParticleIds,
    required List<({int particleId, String name})> missingTextures,
    required Gen5BattleSourceDependencies? diagnostic,
  })  : particles = Map.unmodifiable(particles),
        missingParticleIds = List.unmodifiable(missingParticleIds),
        missingTextures = List.unmodifiable(missingTextures),
        _diagnostic = diagnostic;

  final String release;
  final String moveId;
  final int sourceMoveId;
  final String sourceRevision;
  final String redistributionStatus;
  final String audioStatus;
  final String playbackStatus;
  final Uint8List scriptBytes;
  final String scriptPath;
  final String scriptSha256;
  final Map<int, AveluneGen5MoveParticleSource> particles;
  final String? reportedDependencyStatus;
  final String? effectiveDependencyStatus;
  final bool particleDependencyInventoryVerified;
  final List<int> missingParticleIds;
  final List<({int particleId, String name})> missingTextures;
  final Gen5BattleSourceDependencies? _diagnostic;

  AveluneGen5MoveParticleSource get _singleParticle {
    if (particles.length != 1) {
      throw StateError('Source does not contain exactly one particle');
    }
    return particles.values.single;
  }

  Uint8List get particleBytes => _singleParticle.definitionBytes;
  Map<String, Uint8List> get textureBytes => _singleParticle.textureBytes;
  Gen5BattleSourceDependencies get diagnostic =>
      _diagnostic ??
      (throw StateError('Multi-particle diagnostics are unavailable'));
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

  static String _scriptPath(String moveId, int sourceMoveId) {
    final name = switch ((sourceMoveId, moveId)) {
      (108, 'smokescreen') => 'smoke_screen',
      (120, 'self-destruct') => 'selfdestruct',
      (135, 'soft-boiled') => 'softboiled',
      (136, 'high-jump-kick') => 'hi_jump_kick',
      (185, 'feint-attack') => 'faint_attack',
      (265, 'smelling-salts') => 'smelling_salt',
      _ => moveId.replaceAll('-', '_'),
    };
    return 'res/battle/animations/moves/$name.s';
  }

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
    final format = document['format'];
    if (document['release'] != release ||
        (format != 'gen5-move-source-v1' && format != 'gen5-move-source-v2') ||
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
    final completeness = _object(document['completeness'], {
      'audio',
      'playback',
      if (format == 'gen5-move-source-v2') 'dependencies',
    });
    if (completeness['audio'] != 'missing-sequences-banks-and-commands' ||
        completeness['playback'] != 'not-supported') {
      throw const FormatException('Unsupported Gen 5 move source completeness');
    }
    if (format == 'gen5-move-source-v2') {
      return _readV2(
        document,
        completeness,
        moveId: moveId,
        sourceMoveId: sourceMoveId,
        sourceRevision: revisions.single,
        redistributionStatus: source['redistributionStatus'] as String,
      );
    }
    final scriptFile = _SourceFile.read(document['script']);
    if (scriptFile.path != _scriptPath(moveId, sourceMoveId) ||
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
      scriptPath: scriptFile.path,
      scriptSha256: scriptFile.sha256Hex,
      particles: {
        particleId: AveluneGen5MoveParticleSource._(
          id: particleId,
          definitionBytes: particleBytes,
          definitionSha256: definition.sha256Hex,
          textureBytes: textures,
          textureSha256: {
            for (final entry in textureFiles.entries)
              entry.key: entry.value.sha256Hex,
          },
        ),
      },
      reportedDependencyStatus: null,
      effectiveDependencyStatus: null,
      particleDependencyInventoryVerified: true,
      missingParticleIds: const [],
      missingTextures: const [],
      diagnostic: diagnostic,
    );
  }

  AveluneGen5MoveSourceSnapshot _readV2(
    Map<String, dynamic> document,
    Map<String, dynamic> completeness, {
    required String moveId,
    required int sourceMoveId,
    required String sourceRevision,
    required String redistributionStatus,
  }) {
    final dependencyInfo = _object(completeness['dependencies'], {
      'status',
      'missingParticleIds',
      'missingTextures',
    });
    final status = dependencyInfo['status'];
    final missingIdsRaw = dependencyInfo['missingParticleIds'];
    final missingTexturesRaw = dependencyInfo['missingTextures'];
    if (status is! String ||
        !{'complete', 'partial', 'unknown'}.contains(status) ||
        missingIdsRaw is! List ||
        missingIdsRaw.length > 64 ||
        missingTexturesRaw is! List ||
        missingTexturesRaw.length > 4096) {
      throw const FormatException('Invalid Gen 5 dependency status');
    }
    final missingIds = <int>[];
    for (final raw in missingIdsRaw) {
      if (raw is! int ||
          raw < 0 ||
          raw > 65535 ||
          (missingIds.isNotEmpty && raw <= missingIds.last)) {
        throw const FormatException('Invalid missing particle identities');
      }
      missingIds.add(raw);
    }
    final missingTextures = <({int particleId, String name})>[];
    for (final raw in missingTexturesRaw) {
      final item = _object(raw, {'particleId', 'name'});
      final particleId = item['particleId'];
      final name = item['name'];
      if (particleId is! int ||
          particleId < 0 ||
          particleId > 65535 ||
          name is! String ||
          !_textureName.hasMatch(name)) {
        throw const FormatException('Invalid missing texture identity');
      }
      if (missingTextures.isNotEmpty) {
        final previous = missingTextures.last;
        if (particleId < previous.particleId ||
            (particleId == previous.particleId &&
                name.compareTo(previous.name) <= 0)) {
          throw const FormatException(
              'Missing textures are not unique and sorted');
        }
      }
      missingTextures.add((particleId: particleId, name: name));
    }
    if ((status == 'complete' &&
            (missingIds.isNotEmpty || missingTextures.isNotEmpty)) ||
        (status == 'partial' &&
            missingIds.isEmpty &&
            missingTextures.isEmpty)) {
      throw const FormatException('Contradictory Gen 5 dependency status');
    }

    final scriptFile = _SourceFile.read(document['script']);
    if (scriptFile.path != _scriptPath(moveId, sourceMoveId) ||
        scriptFile.size > 64 * 1024) {
      throw const FormatException('Invalid Gen 5 move script file');
    }
    final scriptBytes = scriptFile.decode();
    final scriptText = utf8.decode(scriptBytes);
    if (scriptText.contains('\u0000') || scriptText.startsWith('\ufeff')) {
      throw const FormatException('Invalid Gen 5 move script text');
    }
    final rawParticles = document['particles'];
    if (rawParticles is! List || rawParticles.length > 64) {
      throw const FormatException('Invalid Gen 5 particle source count');
    }
    final particles = <int, _DecodedGen5Particle>{};
    var totalBytes = scriptFile.size;
    var totalPixels = 0;
    for (final raw in rawParticles) {
      final particle = _readV2Particle(raw);
      final id = particle.source.id;
      if (particles.containsKey(id) || missingIds.contains(id)) {
        throw const FormatException('Duplicate or missing particle supplied');
      }
      particles[id] = particle;
      totalBytes += particle.byteCount;
      totalPixels += particle.pixelCount;
      if (totalBytes > 1024 * 1024 || totalPixels > 4194304) {
        throw const FormatException('Gen 5 move source exceeds budget');
      }
    }
    for (final missing in missingTextures) {
      if (particles[missing.particleId]
              ?.source
              .textureBytes
              .containsKey(missing.name) ??
          false) {
        throw const FormatException('Missing texture was supplied');
      }
    }

    var locallyVerified = false;
    Gen5BattleScriptParameters? script;
    if (status != 'unknown' &&
        sourceRevision == Gen5BattleScriptSymbols.sourceRevision) {
      try {
        script = Gen5BattleScriptParameters.read(
          Gen5BattleScriptSource.read(
            scriptBytes,
            sourceRevision: sourceRevision,
            sourcePath: scriptFile.path,
            expectedSha256: scriptFile.sha256Hex,
          ),
        );
      } on FormatException {
        script = null;
      }
    }
    if (script != null) {
      final loaded = <int>{};
      final requiredTextures = <({int particleId, String name})>{};
      int number(Gen5BattleOperand? operand) {
        if (operand is! Gen5BattleNumberOperand ||
            operand.signedWord < 0 ||
            operand.unsignedWord > 65535) {
          throw const FormatException('Unresolved particle operand');
        }
        return operand.unsignedWord;
      }

      for (final instruction in script.instructions) {
        switch (instruction.instruction.name) {
          case 'ParticleLoad':
            loaded.add(number(instruction.parameters['particle']));
          case 'EmitterMove':
          case 'EmitterAdd':
            final id = number(instruction.parameters['particle']);
            final emitter = number(instruction.parameters['emitter']);
            if (!loaded.contains(id)) {
              throw const FormatException(
                  'Emitter particle source is unavailable');
            }
            final source = particles[id];
            if (source != null) {
              final names = source.emitterTextures[emitter];
              if (names == null) {
                throw const FormatException('Unknown particle emitter');
              }
              requiredTextures.addAll(
                names.map((name) => (particleId: id, name: name)),
              );
            }
        }
      }
      final suppliedIds = particles.keys.toSet();
      if (suppliedIds.difference(loaded).isNotEmpty ||
          !_sameSet(loaded.difference(suppliedIds), missingIds.toSet())) {
        throw const FormatException(
            'Particle dependency list differs from script');
      }
      final actualMissingTextures = requiredTextures.where((texture) =>
          !particles[texture.particleId]!
              .source
              .textureBytes
              .containsKey(texture.name));
      final reportedForProvided = missingTextures
          .where((texture) => particles.containsKey(texture.particleId))
          .toSet();
      if (!_sameSet(actualMissingTextures.toSet(), reportedForProvided) ||
          missingTextures.any((texture) =>
              !particles.containsKey(texture.particleId) &&
              !missingIds.contains(texture.particleId))) {
        throw const FormatException('Missing texture list differs from script');
      }
      locallyVerified = missingTextures
          .every((texture) => particles.containsKey(texture.particleId));
    }

    return AveluneGen5MoveSourceSnapshot._(
      release: release,
      moveId: moveId,
      sourceMoveId: sourceMoveId,
      sourceRevision: sourceRevision,
      redistributionStatus: redistributionStatus,
      audioStatus: completeness['audio'] as String,
      playbackStatus: completeness['playback'] as String,
      scriptBytes: scriptBytes,
      scriptPath: scriptFile.path,
      scriptSha256: scriptFile.sha256Hex,
      particles: {
        for (final entry in particles.entries) entry.key: entry.value.source,
      },
      reportedDependencyStatus: status,
      effectiveDependencyStatus: locallyVerified ? status : 'unknown',
      particleDependencyInventoryVerified: locallyVerified,
      missingParticleIds: missingIds,
      missingTextures: missingTextures,
      diagnostic: null,
    );
  }

  _DecodedGen5Particle _readV2Particle(Object? raw) {
    final particle = _object(raw, {'id', 'definition', 'textures'});
    final id = particle['id'];
    if (id is! int || id < 0 || id > 65535) {
      throw const FormatException('Invalid Gen 5 particle source id');
    }
    final directory = 'res/particles/btlv_effvm_particles/$id';
    final definition = _SourceFile.read(particle['definition']);
    if (definition.path != '$directory/particles.json' ||
        definition.size > 262144) {
      throw const FormatException('Invalid Gen 5 particle definition file');
    }
    final definitionBytes = definition.decode();
    final inventory = Gen5BattleParticleInventory.read(definitionBytes,
        path: definition.path);
    final names = inventory.textureFormats.keys.toSet();

    final rawTextures = particle['textures'];
    if (rawTextures is! List || rawTextures.length > 64) {
      throw const FormatException('Invalid Gen 5 texture sources');
    }
    final textures = <String, Uint8List>{};
    final digests = <String, String>{};
    var byteCount = definition.size;
    var pixelCount = 0;
    for (final rawTexture in rawTextures) {
      final item = _object(rawTexture, {
        'name',
        'path',
        'size',
        'sha256',
        'encoding',
        'data',
      });
      final name = item['name'];
      if (name is! String ||
          !names.contains(name) ||
          textures.containsKey(name)) {
        throw const FormatException('Invalid Gen 5 texture identity');
      }
      final file = _SourceFile.read(item, texture: true);
      if (file.path != '$directory/$name.png') {
        throw const FormatException('Invalid Gen 5 texture source path');
      }
      final bytes = file.decode();
      final dimensions =
          decodeRasterImageDimensions(bytes, mediaType: 'image/png');
      if (dimensions == null ||
          dimensions.width > 1024 ||
          dimensions.height > 1024 ||
          dimensions.width * dimensions.height > 1048576) {
        throw const FormatException('Invalid particle texture dimensions');
      }
      byteCount += file.size;
      pixelCount += dimensions.width * dimensions.height;
      textures[name] = bytes;
      digests[name] = file.sha256Hex;
    }
    return _DecodedGen5Particle(
      source: AveluneGen5MoveParticleSource._(
        id: id,
        definitionBytes: definitionBytes,
        definitionSha256: definition.sha256Hex,
        textureBytes: textures,
        textureSha256: digests,
      ),
      emitterTextures: inventory.texturesByEmitter,
      byteCount: byteCount,
      pixelCount: pixelCount,
    );
  }
}

final class _DecodedGen5Particle {
  const _DecodedGen5Particle({
    required this.source,
    required this.emitterTextures,
    required this.byteCount,
    required this.pixelCount,
  });

  final AveluneGen5MoveParticleSource source;
  final Map<int, Set<String>> emitterTextures;
  final int byteCount;
  final int pixelCount;
}

bool _sameSet<T>(Set<T> left, Set<T> right) =>
    left.length == right.length && left.containsAll(right);

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
