import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';

final class SourceBattleMusicBinding {
  SourceBattleMusicBinding._(this.battleAudio, this.trainers, this.artifacts,
      this.importMutations, this.evidence);

  final ProjectBattleAudioConfig? battleAudio;
  final List<ProjectTrainerEntry> trainers;
  final List<NativeArtifact> artifacts;
  final List<NativeMutation> importMutations;
  final Map<String, Object?> evidence;

  static Future<SourceBattleMusicBinding> read({
    required NormalizedSourceProject source,
    required SourcePbsProject pbs,
    required SourceFilePort files,
    required List<ProjectTrainerEntry> trainers,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    final cancel = cancellation ?? ScanCancellation();
    cancel.check();
    limits.validate();
    final snapshot = source.snapshot;
    Never refuse(String reason, String path) => throw ContractError(
        'source.battle_music.$reason',
        path,
        'Source battle music ($reason) is unavailable at $path; exact bounded declarations and audio files are required.');
    final indexed = <String, List<SourceFileEntry>>{};
    for (final entry in snapshot.entries) {
      cancel.check();
      (indexed[sourcePathCollisionKey(entry.relativePath)] ??= []).add(entry);
    }
    SourceFileEntry exact(String path) {
      final entries = indexed[sourcePathCollisionKey(path)] ?? const [];
      if (entries.length != 1 ||
          entries.single.relativePath != path ||
          entries.single.kind != SourceNodeKind.file ||
          entries.single.sha256 == null) {
        refuse('source_missing_or_ambiguous', path);
      }
      return entries.single;
    }

    var readBytes = 0;
    final readFiles = <ConverterId, List<int>>{};
    Future<List<int>> read(String path) async {
      cancel.check();
      final file = exact(path);
      if (readFiles.containsKey(file.fileId)) return readFiles[file.fileId]!;
      if (file.byteLength > limits.maxArtifactBytes ||
          file.byteLength > limits.maxTotalArtifactBytes - readBytes) {
        refuse('quota', path);
      }
      readBytes += file.byteLength;
      final bytes = await files.read(file.fileId);
      cancel.check();
      if (bytes.length != file.byteLength ||
          bytes.any((v) => v < 0 || v > 255) ||
          crypto.sha256.convert(bytes).toString() != file.sha256!.value) {
        refuse('source_changed', path);
      }
      readFiles[file.fileId] = List<int>.unmodifiable(bytes);
      return readFiles[file.fileId]!;
    }

    final global = <String, String>{};
    final metadataExists =
        indexed.containsKey(sourcePathCollisionKey('PBS/metadata.txt'));
    if (metadataExists) {
      final bytes = await read('PBS/metadata.txt');
      if (bytes.length > 2097152) refuse('quota', 'PBS/metadata.txt');
      final sections = <String>{};
      String? section;
      for (final raw in const LineSplitter().convert(utf8.decode(bytes))) {
        cancel.check();
        final line = raw.replaceFirst('\uFEFF', '').split('#').first.trim();
        if (line.isEmpty) continue;
        final header = RegExp(r'^\[([0-9]+)\]$').firstMatch(line);
        if (header != null) {
          section = int.parse(header[1]!).toString();
          if (!sections.add(section)) {
            refuse('metadata_duplicate', 'PBS/metadata.txt');
          }
          continue;
        }
        if (section != '0') continue;
        final match =
            RegExp(r'^([A-Za-z][A-Za-z0-9]*)\s*=\s*(.*)$').firstMatch(line);
        if (match == null) refuse('metadata_shape', 'PBS/metadata.txt');
        if (!_globalFields.containsKey(match[1])) continue;
        if (global.containsKey(match[1])) {
          refuse('metadata_duplicate', 'PBS/metadata.txt');
        }
        global[match[1]!] = match[2]!.trim();
      }
    }
    final trainerTypes = <String, SourcePbsEntry>{};
    for (final trainer in trainers) {
      final identities = pbs.entries
          .where((entry) =>
              entry.family == SourcePbsFamily.trainers &&
              entry.identity?.sourceId.value == trainer.id)
          .toList();
      if (identities.length != 1) refuse('trainer_identity', trainer.id);
      final type = identities.single.identity!.trainerType!;
      final definitions = pbs.entries
          .where((entry) =>
              entry.family == SourcePbsFamily.trainerTypes &&
              entry.identity?.sourceSymbol == type)
          .toList();
      if (definitions.length != 1) refuse('trainer_type', type);
      trainerTypes[type] = definitions.single;
    }
    String declaration(SourcePbsEntry entry, String field) {
      final values = entry.fields.where((value) => value.key == field).toList();
      if (values.isEmpty) return '';
      if (values.length != 1 || values.single.values.length != 1) {
        refuse('trainer_declaration', entry.identity!.key);
      }
      return values.single.values.single;
    }

    final activeTypes = trainerTypes.entries
        .where((entry) =>
            declaration(entry.value, 'BattleBGM').isNotEmpty ||
            declaration(entry.value, 'VictoryBGM').isNotEmpty)
        .toList();
    final hasGlobal = global.values.any((value) => value.isNotEmpty);
    Future<Map<String, Map<String, MarshalNode>>> compiled(
        String path, String className, MarshalKind keyKind) async {
      final bytes = await read(path);
      final document = const MarshalDecoder().decode(bytes,
          sourcePath: path,
          limits: MarshalDecodeLimits(
              maxInputBytes: limits.maxArtifactBytes,
              maxNodes: 100000,
              maxObjects: 100000,
              maxTotalEntries: 100000,
              maxContainerEntries: 16384));
      final root = document.node(document.rootId);
      if (root.kind != MarshalKind.hash || root.defaultValue != null) {
        refuse('compiled_shape', path);
      }
      final result = <String, Map<String, MarshalNode>>{};
      for (final pair in root.pairs) {
        cancel.check();
        final key = document.node(pair.key);
        final object = document.node(pair.value);
        final id = key.kind == MarshalKind.integer
            ? key.integerValue.toString()
            : key.kind == MarshalKind.symbol
                ? key.text().text
                : null;
        if (key.kind != keyKind ||
            id == null ||
            result.containsKey(id) ||
            object.kind != MarshalKind.object ||
            object.className != className) {
          refuse('compiled_shape', path);
        }
        final fields = <String, MarshalNode>{};
        for (final field in object.instanceVariables) {
          final name = document.node(field.key);
          if (name.kind != MarshalKind.symbol ||
              fields.containsKey(name.text().text)) {
            refuse('compiled_shape', path);
          }
          fields[name.text().text!] = document.node(field.value);
        }
        final ownId = fields['@id'];
        final ownValue = ownId?.kind == MarshalKind.integer
            ? ownId!.integerValue.toString()
            : ownId?.kind == MarshalKind.symbol
                ? ownId!.text().text
                : null;
        if (ownValue != id) refuse('compiled_identity', path);
        result[id] = fields;
      }
      return result;
    }

    void sameDeclaration(Map<String, MarshalNode> fields, String field,
        String name, String path) {
      final value = fields[field];
      final compiledName = value == null || value.kind == MarshalKind.nil
          ? ''
          : value.kind == MarshalKind.string
              ? value.text().text
              : null;
      if (compiledName != name) refuse('compiled_mismatch', path);
    }

    if (hasGlobal ||
        indexed.containsKey(sourcePathCollisionKey('Data/metadata.dat'))) {
      final metadata = await compiled(
          'Data/metadata.dat', 'GameData::Metadata', MarshalKind.integer);
      final fields = metadata['0'];
      if (fields == null) refuse('compiled_identity', 'Data/metadata.dat');
      for (final entry in _globalFields.entries) {
        sameDeclaration(fields, entry.value.$1, global[entry.key] ?? '',
            'Data/metadata.dat');
      }
    }
    if (trainerTypes.isNotEmpty) {
      final types = await compiled('Data/trainer_types.dat',
          'GameData::TrainerType', MarshalKind.symbol);
      for (final entry in trainerTypes.entries) {
        final fields = types[entry.key];
        if (fields == null) {
          refuse('compiled_identity', 'Data/trainer_types.dat');
        }
        for (final field in const {
          'BattleBGM': '@battle_BGM',
          'VictoryBGM': '@victory_BGM'
        }.entries) {
          sameDeclaration(fields, field.value,
              declaration(entry.value, field.key), 'Data/trainer_types.dat');
        }
      }
    }
    if (!hasGlobal && activeTypes.isEmpty) {
      return SourceBattleMusicBinding._(
          null, List.unmodifiable(trainers), const [], const [], const {});
    }
    final profile = SourceEventProfile.forProject(source);
    if (snapshot.state != SourceScanState.complete ||
        !profile.isQualified ||
        pbs.sourceSnapshotHash != snapshot.canonicalHash ||
        pbs.logicalProjectNamespace != snapshot.logicalProjectNamespace) {
      refuse('profile', 'Data/Scripts.rxdata');
    }
    await read('Data/Scripts.rxdata');
    await source.interpretationProfile!
        .verifySource(snapshot: snapshot, files: files, cancellation: cancel);
    final artifacts = <String, NativeArtifact>{};
    final imports = <String, NativeMutation>{};
    final bindings = <Map<String, Object?>>[];
    Future<String?> resolve(String name, String owner, String field,
        SourceFileEntry declarationFile) async {
      cancel.check();
      if (name.isEmpty) return null;
      if (name.length > 512 ||
          name.trim() != name ||
          name == '.' ||
          name == '..' ||
          RegExp(r'[\\/:<>\x00-\x1f]').hasMatch(name)) {
        refuse('name', declarationFile.relativePath);
      }
      List<SourceFileEntry> matches(String value) {
        final key = sourcePathCollisionKey('Audio/BGM/$value');
        return [
          for (final entry in indexed.entries)
            if (entry.key.startsWith('$key.') &&
                !entry.key.substring(key.length + 1).contains('/'))
              ...entry.value
        ];
      }

      var candidates = matches(name);
      var resolution = 'exactSourceAudio';
      var resolvedName = name;
      if (candidates.isEmpty && _renamedSourceAudio.containsKey(name)) {
        resolvedName = _renamedSourceAudio[name]!;
        candidates = matches(resolvedName);
        resolution = 'closedRenamedSourceAudio';
      }
      if (candidates.length != 1) refuse('audio_missing_or_ambiguous', name);
      final file = candidates.single;
      final base = 'Audio/BGM/$resolvedName';
      final extension = file.relativePath.substring(base.length + 1);
      final mediaType = const {
        'ogg': 'audio/ogg',
        'wav': 'audio/wav',
        'mp3': 'audio/mpeg',
        'flac': 'audio/flac'
      }[extension];
      if (mediaType == null || file.relativePath != '$base.$extension') {
        refuse('audio_format', file.relativePath);
      }
      final bytes = await read(file.relativePath);
      final artifact = NativeArtifact(
          bytes: bytes,
          mediaType: mediaType,
          expectedSha256: file.sha256,
          limits: limits);
      artifacts[artifact.handle] = artifact;
      final identity = canonicalHashOf({
        'namespace': snapshot.logicalProjectNamespace.value,
        'kind': 'sourceBattleMusic',
        'sourceFileId': file.fileId.value,
        'sha256': file.sha256!.value
      }, limits: limits.jsonLimits)
          .value;
      final assetId = 'source_battle_music_$identity';
      final logicalPath = 'assets/audio/$assetId.$extension';
      imports[assetId] = NativeMutation(
          operationId: ConverterId('import_$assetId'),
          actionId: 'asset.import',
          sourceEntityIds: [file.fileId],
          targetEntityIds: [ConverterId(assetId)],
          parameters: {
            'assetId': assetId,
            'artifactHandle': artifact.handle,
            'logicalPath': logicalPath,
            'tags': ['source-battle-music'],
            'usages': ['battleMusic']
          },
          limits: limits);
      if (artifacts.length > limits.maxArtifacts ||
          imports.length + 1 > limits.maxMutations) {
        refuse('quota', name);
      }
      bindings.add({
        'owner': owner,
        'field': field,
        'declaredName': name,
        'resolvedName': resolvedName,
        'resolution': resolution,
        'declarationFile': declarationFile.toJson(),
        'sourceAudioFile': file.toJson(),
        'nativePath': logicalPath
      });
      return logicalPath;
    }

    final defaults = <String, dynamic>{};
    if (hasGlobal) {
      for (final entry in _globalFields.entries) {
        final path = await resolve(global[entry.key] ?? '', 'project',
            entry.value.$2, exact('PBS/metadata.txt'));
        if (path != null) defaults[entry.value.$2] = path;
      }
    }
    final musicByType = <String, (String?, String?)>{};
    for (final entry in activeTypes) {
      final file = exact(entry.value.headerLocator.file);
      musicByType[entry.key] = (
        await resolve(declaration(entry.value, 'BattleBGM'), entry.key,
            'battleMusicPath', file),
        await resolve(declaration(entry.value, 'VictoryBGM'), entry.key,
            'victoryMusicPath', file)
      );
    }
    final output = <ProjectTrainerEntry>[];
    for (final trainer in trainers) {
      final type = pbs.entries
          .singleWhere((entry) =>
              entry.family == SourcePbsFamily.trainers &&
              entry.identity?.sourceId.value == trainer.id)
          .identity!
          .trainerType!;
      final music = musicByType[type];
      output.add(music == null
          ? trainer
          : trainer.copyWith(
              battleMusicPath: music.$1, victoryMusicPath: music.$2));
    }
    cancel.check();
    final evidence = {
      'kind': 'sourceBattleMusicBinding',
      'version': 1,
      'sourceSnapshotHash': snapshot.canonicalHash.value,
      'normalizationHash': source.canonicalHash.value,
      'pbsHash': pbs.canonicalHash.value,
      'profileHash': profile.canonicalHash.value,
      'battleAuthority': 'aveluneNative',
      'automatic': true,
      'aiCalls': 0,
      'sourceScriptsExecuted': 0,
      'fullSourceMusicParity': false,
      'limitations': [
        'Global metadata defaults and represented trainer overrides only.',
        'Generic map, regional and dynamic source music overrides are not imported.',
        'Closed renamed-file adaptations are explicit; source playback gain is not reproduced.'
      ],
      'policy': 'exact-declarations-with-closed-renamed-source-audio-v1',
      'bindings': bindings,
      'sourceFiles': [
        for (final id in readFiles.keys)
          snapshot.entries.singleWhere((entry) => entry.fileId == id).toJson()
      ]
    };
    return SourceBattleMusicBinding._(
        defaults.isEmpty ? null : ProjectBattleAudioConfig.fromJson(defaults),
        List.unmodifiable(output),
        List.unmodifiable(artifacts.values),
        List.unmodifiable(imports.values),
        _freeze(evidence) as Map<String, Object?>);
  }
}

const _globalFields = {
  'WildBattleBGM': ('@wild_battle_BGM', 'wildBattleMusicPath'),
  'TrainerBattleBGM': ('@trainer_battle_BGM', 'trainerBattleMusicPath'),
  'WildVictoryBGM': ('@wild_victory_BGM', 'wildVictoryMusicPath'),
  'TrainerVictoryBGM': ('@trainer_victory_BGM', 'trainerVictoryMusicPath'),
};

const _renamedSourceAudio = {
  'FRLG Battle (VS Wild Pokemon)':
      'FRLG Battle Music - Wild Pokemon (Battle (VS Wild Pokemon))',
  'FRLG Battle (VS Trainer)':
      'FRLG Battle Music - Trainer (Battle (VS Trainer))',
  'FRLG Victory (VS Wild Pokemon)':
      'FRLG Battle Victory - Wild Pokemon (Victory (VS Wild Pokemon))',
  'FRLG Victory (VS Trainer)':
      'FRLG Battle Victory - Trainer (Victory (VS Trainer))',
  'FRLG Battle (VS Gym Leader)':
      'FRLG Battle Music - Gym Leader (Battle (VS Gym Leader))',
  'FRLG Victory (VS Gym Leader)':
      'FRLG Battle Victory - Gym Leader (Victory (VS Gym Leader))',
  'FRLG The Last Battle (VS Rival)':
      'FRLG Battle Intro - Champion (The Last Battle (VS Rival))',
};

Object? _freeze(Object? value) => switch (value) {
      Map values => Map<String, Object?>.unmodifiable(
          values.map((key, value) => MapEntry(key as String, _freeze(value)))),
      List values => List<Object?>.unmodifiable(values.map(_freeze)),
      _ => value,
    };
