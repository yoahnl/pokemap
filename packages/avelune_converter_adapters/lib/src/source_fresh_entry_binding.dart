import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';
import 'source_event_projection.dart';
import 'source_player_character_import.dart';

final class SourceFreshEntryBinding {
  SourceFreshEntryBinding._({
    required this.config,
    required this.defeatRecovery,
    required this.scene,
    required List<NativeArtifact> artifacts,
    required List<NativeMutation> importMutations,
    required List<NativeMutation> mutations,
    required List<NarrativeFactDefinition> facts,
    required Map<int, MapData> nativeMaps,
    required List<SourcePlayerCharacterImport> imports,
    required Map<String, Object?> evidence,
  })  : artifacts = List.unmodifiable(artifacts),
        importMutations = List.unmodifiable(importMutations),
        mutations = List.unmodifiable(mutations),
        facts = List.unmodifiable(facts),
        nativeMaps = Map.unmodifiable(nativeMaps),
        imports = List.unmodifiable(imports),
        evidence = immutableCanonicalJsonOf(evidence) as Map<String, Object?>;

  final ProjectNewGameConfig config;
  final ProjectDefeatRecoveryConfig defeatRecovery;
  final SceneAsset scene;
  final List<NativeArtifact> artifacts;
  final List<NativeMutation> importMutations, mutations;
  final List<NarrativeFactDefinition> facts;
  final Map<int, MapData> nativeMaps;
  final List<SourcePlayerCharacterImport> imports;
  final Map<String, Object?> evidence;
  MapData get startMap => nativeMaps[1]!;
}

final class SourceFreshEntryBindingResolver {
  const SourceFreshEntryBindingResolver();

  Future<SourceFreshEntryBinding?> read({
    required NormalizedSourceProject source,
    required SourceEventProjection projection,
    required SourceFilePort files,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    limits.validate();
    cancellation?.check();
    final program = sourceFreshEntryProgram(source);
    final profile = SourceEventProfile.forProject(source);
    if (program == null ||
        !program.isBoundTo(source) ||
        !profile.isQualified ||
        projection.semanticEvidence['sourceSnapshotHash'] !=
            source.snapshot.canonicalHash.value ||
        projection.semanticEvidence['normalizationHash'] !=
            source.canonicalHash.value ||
        projection.semanticEvidence['sourceProfileHash'] !=
            profile.canonicalHash.value) {
      return null;
    }
    final events = projection.semanticEvidence['events'];
    if (events is! List) return null;
    final rows = events
        .whereType<Map>()
        .where((row) =>
            row['sourceIdentity'] ==
            source
                .eventIdentity(
                    program.introSourceMapId, program.introSourceEventId)
                .value)
        .toList();
    if (rows.length != 1 ||
        rows.single['status'] != 'adaptedStaticSemantics' ||
        rows.single['gaps'] is! List ||
        (rows.single['gaps'] as List).isNotEmpty) {
      return null;
    }
    final introduction = rows.single['nativeIntroduction'];
    final freshId = sourceEventFactBindingId(
        'source:${source.snapshot.logicalProjectNamespace.value}:nativeFreshEntry:${program.intro.programHash.value}');
    final nativeIntro = introduction is Map ? introduction : const {};
    if (nativeIntro['programHash'] != program.intro.programHash.value ||
        nativeIntro['nativeEntryFactId'] != freshId ||
        nativeIntro['nativeEntryFactDefault'] != false ||
        nativeIntro['requiresNativeFreshEntryFactory'] != true) {
      return null;
    }
    final freshFacts =
        projection.facts.where((fact) => fact.id == freshId).toList();
    if (freshFacts.length != 1 ||
        freshFacts.single.initialValue != NarrativeValue.boolean(false)) {
      return null;
    }
    final maps = projection.nativeMaps;
    if (![1, 2, 7].every(maps.containsKey) ||
        maps.values.any((map) =>
            map.version == ProjectVersion.v9 || map.spatialScene != null)) {
      return null;
    }
    final start = maps[program.introSourceMapId]!;
    final recovery = maps[program.recoverySourceMapId]!;
    final nativeRecovery = maps[program.startingOverTargetSourceMapId]!;
    final recoveryPosition =
        GridPos(x: program.startingOverTargetX, y: program.startingOverTargetY);
    if (!_passableRecoveryCell(source, nativeRecovery,
        program.startingOverTargetSourceMapId, recoveryPosition)) {
      return null;
    }
    final stationary = [
      _stationaryCell(source, start, program.introSourceMapId,
          GridPos(x: program.introX, y: program.introY)),
      _stationaryCell(source, recovery, program.recoverySourceMapId,
          GridPos(x: program.recoveryX, y: program.recoveryY)),
    ];
    if (stationary.any((cell) => cell == null)) return null;
    final metadataFile = _exactFile(source.snapshot, 'PBS/metadata.txt');
    final metadataBytes =
        await _readAttested(metadataFile, files, cancellation, 65536);
    final metadata = _globalMetadata(metadataBytes);
    final direction =
        await _freshDirection(source, files, cancellation, limits);
    final imported = <SourcePlayerCharacterImport>[];
    for (final header in [1, 2]) {
      imported.add(await const SourcePlayerCharacterImporter().read(
          snapshot: source.snapshot,
          files: files,
          selectedHeaderId: header,
          selectedOutfit: program.sourceOutfit,
          cancellation: cancellation));
    }
    final namespace = 'source:${source.snapshot.logicalProjectNamespace.value}';
    final regionSource = '$namespace:variable:${program.regionVariableId}';
    final regionId = sourceEventIntegerVariableBindingId(regionSource);
    final matching =
        projection.facts.where((fact) => fact.id == regionId).toList();
    if (matching.length > 1 ||
        matching.any((fact) =>
            fact.initialValue != NarrativeValue.integer(0) ||
            fact.description != 'Persistent source integer: $regionSource')) {
      throw ContractError('source.fresh_entry.region_fact_invalid', r'$',
          'The region variable requires one exact integer Fact initially zero.');
    }
    final region = matching.isNotEmpty
        ? matching.single
        : addNarrativeFact(
            const ProjectManifest(
                name: 'Source event projection', maps: [], tilesets: []),
            label: 'Source variable ${canonicalHashOf({
                  'sourceVariableId': regionSource
                }).value.substring(0, 24)}',
            description: 'Persistent source integer: $regionSource',
            category: 'Source variables',
            initialValue: NarrativeValue.integer(0),
            tags: ['sourceImported']).createdFact;
    if (region.id != regionId) {
      throw StateError('The source region Fact identity drifted.');
    }
    final recoveredSource = '$namespace:switch:${program.startingOverSwitchId}';
    final recoveredId = sourceEventFactBindingId(recoveredSource);
    final recoveredMatches =
        projection.facts.where((fact) => fact.id == recoveredId).toList();
    if (recoveredMatches.length > 1 ||
        recoveredMatches.any((fact) =>
            fact.initialValue != NarrativeValue.boolean(false) ||
            fact.description !=
                'Persistent source boolean: $recoveredSource')) {
      throw ContractError('source.fresh_entry.recovery_fact_invalid', r'$',
          'The recovery marker requires one exact source boolean initially false.');
    }
    final recovered = recoveredMatches.isNotEmpty
        ? recoveredMatches.single
        : addNarrativeFact(
            const ProjectManifest(
                name: 'Source event projection', maps: [], tilesets: []),
            label: 'Source event ${canonicalHashOf({
                  'sourceFactId': recoveredSource
                }).value.substring(0, 24)} ${recoveredSource.split(':').skip(2).join(' ')}',
            description: 'Persistent source boolean: $recoveredSource',
            category: 'Source events',
            tags: ['sourceImported']).createdFact;
    if (recovered.id != recoveredId) {
      throw StateError('The source recovery Fact identity drifted.');
    }
    final defeatRecovery =
        ProjectDefeatRecoveryConfig(recoveredFactId: recoveredId);
    final facts = <NarrativeFactDefinition>[
      if (matching.isEmpty) region,
      if (recoveredMatches.isEmpty) recovered
    ];
    final identity = canonicalHashOf({
      'kind': 'sourceFreshEntryBinding',
      'sourceSnapshotHash': source.snapshot.canonicalHash.value,
      'programHash': program.programHash.value,
      'metadataHash': metadataFile.sha256!.value,
      'avatars': [for (final avatar in imported) avatar.character.id]
    }).value;
    final prefix = 'source_fresh_${identity.substring(0, 24)}';
    final spawnCandidates = start.entities
        .where((entity) =>
            entity.kind == MapEntityKind.spawn &&
            entity.spawn?.role == EntitySpawnRole.playerStart &&
            entity.pos == GridPos(x: program.introX, y: program.introY) &&
            entity.spawn?.facing == direction.facing)
        .toList();
    if (spawnCandidates.length > 1) {
      throw ContractError('source.fresh_entry.spawn_ambiguous', r'$',
          'The native introduction requires one explicit fresh spawn.');
    }
    final spawn = spawnCandidates.isNotEmpty
        ? spawnCandidates.single
        : MapEntity(
            id: '${prefix}_spawn',
            name: 'Nouvelle partie',
            kind: MapEntityKind.spawn,
            pos: GridPos(x: program.introX, y: program.introY),
            size: const GridSize(width: 1, height: 1),
            blocksMovement: false,
            spawn: MapEntitySpawnData(facing: direction.facing));
    if (spawnCandidates.isEmpty &&
        start.entities.any((entity) => entity.id == spawn.id)) {
      throw ContractError('source.fresh_entry.spawn_collision', r'$',
          'The fresh spawn identity is already owned by another entity.');
    }
    final startMap = spawnCandidates.isNotEmpty
        ? start
        : start.copyWith(entities: [...start.entities, spawn]);
    final nativeMaps = {...maps, program.introSourceMapId: startMap};
    final artifacts = <NativeArtifact>[];
    final importMutations = <NativeMutation>[];
    final owners = <ConverterId>[
      program.dispatcherRawDataRef.fileId,
      program.intro.rawDataRef.fileId,
      metadataFile.fileId,
      ...direction.files.map((file) => file.fileId)
    ];
    NativeMutation mutation(String suffix, String action, List<String> targets,
            Map<String, Object?> parameters, {List<ConverterId>? sourceIds}) =>
        NativeMutation(
            operationId: ConverterId('$prefix-$suffix'),
            actionId: action,
            sourceEntityIds: (sourceIds ?? owners).toSet().toList(),
            targetEntityIds: targets.map(ConverterId.new).toList(),
            parameters: parameters,
            limits: limits);
    final displayCharacters = <ProjectCharacterEntry>[];
    for (final (index, avatar) in imported.indexed) {
      final avatarOwners = [
        metadataFile.fileId,
        ...avatar.sheets.map((sheet) => sheet.imageFile.fileId)
      ];
      final label = index == 0 ? 'Personnage masculin' : 'Personnage féminin';
      displayCharacters.add(avatar.character.copyWith(name: label));
      for (final sheet in avatar.sheets) {
        final artifact =
            NativeArtifact(bytes: sheet.outputBytes, limits: limits);
        artifacts.add(artifact);
        importMutations.add(mutation(
            'avatar$index-${sheet.declaration}-image',
            'tileset.import_image',
            [sheet.tilesetId, sheet.assetId],
            {
              'artifactHandle': artifact.handle,
              'tilesetId': sheet.tilesetId,
              'name': '$label ${sheet.declaration}',
              'tileWidth': 32,
              'tileHeight': 32
            },
            sourceIds: avatarOwners));
      }
      importMutations.add(mutation(
          'avatar$index-create',
          'characterStudio.character.create',
          [avatar.character.id],
          {
            'name': avatar.character.name,
            'tilesetId': avatar.tilesetId,
            'frameWidth': avatar.character.frameWidth,
            'frameHeight': avatar.character.frameHeight,
            'tags': avatar.character.tags
          },
          sourceIds: avatarOwners));
      for (final clip in avatar.character.animations) {
        importMutations.add(mutation(
            'avatar$index-${clip.state.name}-${clip.direction.name}',
            'characterStudio.animationClip.upsert',
            [avatar.character.id],
            {
              'characterId': avatar.character.id,
              'kind': 'system',
              'state': clip.toJson()['state'],
              'direction': clip.direction.name,
              'sourceAssetId': clip.sourceAssetId,
              'loop': clip.loop,
              'frames': clip.frames.map((frame) => frame.toJson()).toList()
            },
            sourceIds: avatarOwners));
      }
      importMutations.add(mutation(
          'avatar$index-label',
          'characterStudio.character.update',
          [avatar.character.id],
          {'characterId': avatar.character.id, 'name': label},
          sourceIds: avatarOwners));
    }
    importMutations.add(mutation(
        'avatar-default',
        'characterStudio.character.setDefault',
        [imported.first.character.id],
        {'characterId': imported.first.character.id}));
    validateNativeArtifactCount(
        artifacts: artifacts, sourceArtifacts: const [], limits: limits);
    if (artifacts.fold<int>(0, (sum, a) => sum + a.bytes.length) >
        limits.maxTotalArtifactBytes) {
      throw const NativeWriteException('source.fresh_entry.artifact_quota',
          'Fresh avatar assets exceed their cumulative budget.');
    }
    final config = ProjectNewGameConfig(
        enabled: true,
        startMapId: startMap.id,
        startSpawnId: spawn.id,
        startingMoney: metadata.money,
        playerAvatarCharacterIds: imported.map((a) => a.character.id).toList(),
        initialFactValues: {
          freshId: NarrativeValue.boolean(true),
          regionId: NarrativeValue.integer(program.regionValue),
          recoveredId: NarrativeValue.boolean(false)
        },
        initialRecoveryPoint: ProjectNewGameRecoveryPoint(
            mapId: nativeRecovery.id,
            position: recoveryPosition,
            facing: EntityFacing.north));
    final context = ProjectManifest(
        name: 'Départ source',
        maps: [
          for (final map in nativeMaps.values)
            ProjectMapEntry(
                id: map.id, name: map.name, relativePath: 'maps/${map.id}.json')
        ],
        tilesets: [
          for (final avatar in imported)
            for (final sheet in avatar.sheets)
              ProjectTilesetEntry(
                  id: sheet.tilesetId,
                  name: sheet.charsetName,
                  relativePath: 'assets/studio/${sheet.tilesetId}.png',
                  source: ProjectRegularAtlasTilesetSource(
                      assetId: sheet.assetId,
                      pixelWidth: 256,
                      pixelHeight: 256,
                      tileWidth: 32,
                      tileHeight: 32))
        ],
        characters: displayCharacters,
        facts: [...projection.facts, ...facts],
        newGame: config,
        defeatRecovery: defeatRecovery,
        settings: const ProjectSettings(tileWidth: 32, tileHeight: 32));
    final ready = const SceneActions().createPreSessionScene(context,
        maps: nativeMaps.values.toList(),
        sceneId: '${prefix}_identity',
        name: 'Nouvelle partie',
        templateId: 'identitySetup',
        setAsEntrypoint: true);
    final scene = ready.scenes.single;
    final mutations = <NativeMutation>[
      for (final fact in facts)
        mutation(fact.id == regionId ? 'region-fact' : 'recovery-fact',
            'fact.create', [fact.id], {'fact': fact.toJson()}),
      if (spawnCandidates.isEmpty)
        mutation('intro-spawn', 'entity.create', [startMap.id, spawn.id],
            {'mapId': startMap.id, 'entity': spawn.toJson()}),
      mutation('identity-scene', 'scene.upsert', [scene.id],
          {'scene': scene.toJson()}),
      mutation('defeat-recovery', 'campaign.defeat_recovery.update',
          [recoveredId], {'defeatRecovery': defeatRecovery.toJson()}),
      mutation('new-game', 'campaign.new_game.update', [],
          {'newGame': ready.newGame.toJson()}),
    ];
    if (importMutations.length + mutations.length > limits.maxMutations) {
      throw const NativeWriteException('source.fresh_entry.mutation_quota',
          'Fresh entry actions exceed their bounded budget.');
    }
    return SourceFreshEntryBinding._(
        config: ready.newGame,
        defeatRecovery: defeatRecovery,
        scene: scene,
        artifacts: artifacts,
        importMutations: importMutations,
        mutations: mutations,
        facts: facts,
        nativeMaps: nativeMaps,
        imports: imported,
        evidence: {
          'kind': 'sourceFreshEntryBinding',
          'sourceSnapshotHash': source.snapshot.canonicalHash.value,
          'normalizationHash': source.canonicalHash.value,
          'profileHash': profile.canonicalHash.value,
          'interpretationProfileHash':
              source.interpretationProfile!.canonicalHash.value,
          'program': program.toJson(),
          'metadataFile': metadataFile.toJson(),
          'sourceStartMoney': metadata.money,
          'sourceHome': metadata.home,
          'initialPcItemStorage': {
            'sourceSymbols': metadata.pcItems,
            'status': metadata.pcItems.isEmpty ? 'empty' : 'unsupported',
            'diagnostic': metadata.pcItems.isEmpty
                ? null
                : 'sourceInitialPcItemStorageUnsupported',
            'addedToBag': false
          },
          'freshDirection': direction.evidence,
          'stationaryEntryPlacements': stationary,
          'avatars': imported.map((avatar) => avatar.evidence).toList(),
          'nativeMaps': {
            'intro': startMap.id,
            'recovery': nativeRecovery.id,
            'home': maps[7]!.id
          },
          'nativeEntryFactId': freshId,
          'regionFactId': regionId,
          'defeatRecovery': {
            'sourceRecoveryPoint': {
              'sourceMapId': program.recoverySourceMapId,
              'x': program.recoveryX,
              'y': program.recoveryY
            },
            'sourceStartingOverBranch': program.toJson()['startingOverBranch'],
            'nativeRecoveryPoint': ready.newGame.initialRecoveryPoint!.toJson(),
            'nativeMarker': defeatRecovery.toJson(),
            'sourceTechnicalMapExecuted': false,
            'adaptation': 'collapseAttestedStartingOverTransfer',
            'nativePartyAndStorageRetained': true,
            'sourceVariableBanksInjected': false,
            'collisionModified': false,
            'playerDefeatJourneyQualified': false,
          },
          'nativeStartSpawnId': spawn.id,
          'initialPartyCount': 0,
          'initialPokemonStorage': 'empty',
          'initialBagCount': 0,
          'starterSeeded': false,
          'nativeFollowers': 'empty',
          'sourceScriptsExecuted': 0,
          'aiCalls': 0,
          'nativeExecutionQualified': false,
          'preSession': 'canonicalIdentitySetup',
          'sourceIdentityPresentationParity': false
        });
  }
}

Map<String, Object?>? _stationaryCell(NormalizedSourceProject source,
    MapData map, int sourceMapId, GridPos point) {
  if (point.x < 0 ||
      point.y < 0 ||
      point.x >= map.size.width ||
      point.y >= map.size.height ||
      map.entities.any((entity) =>
          entity.blocksMovement &&
          resolveEntityCollisionCells(entity).contains(point))) {
    return null;
  }
  if (map.layers.whereType<CollisionLayer>().any(
      (layer) => layer.collisions.length != map.size.width * map.size.height)) {
    return null;
  }
  final resolver = SourceSemanticResolver.forProject(source);
  final cell = resolver.cellAt(sourceMapId, point.x, point.y);
  final passage = resolver.resolveCell(cell);
  if (!resolver.profile.isQualified ||
      cell.width != map.size.width ||
      cell.height != map.size.height ||
      passage.directions.any(
          (direction) => direction.status == SourcePassageStatus.unqualified)) {
    return null;
  }
  return {
    'kind': 'stationaryAutorunSpawnOnSourceBlockedTile',
    'sourceCell': cell.toJson(),
    'sourcePassage': [
      for (final direction in passage.directions) direction.toJson()
    ],
    'nativeMapId': map.id,
    'nativeCollisionAtCell': [
      for (final layer in map.layers.whereType<CollisionLayer>())
        layer.collisions[point.y * map.size.width + point.x]
    ],
    'collisionModified': false,
    'movementRequiredBeforeScene': false,
    'sourceFreshEntryRequired': true,
  };
}

SourceFileEntry _exactFile(SourceSnapshot source, String path) {
  final matches = source.entries
      .where((entry) =>
          sourcePathCollisionKey(entry.relativePath) ==
          sourcePathCollisionKey(path))
      .toList();
  if (matches.length != 1 ||
      matches.single.relativePath != path ||
      matches.single.kind != SourceNodeKind.file ||
      matches.single.sha256 == null) {
    throw ContractError('source.fresh_entry.file_unattested', path,
        'Fresh entry requires one exact attested source file.');
  }
  return matches.single;
}

Future<List<int>> _readAttested(SourceFileEntry entry, SourceFilePort files,
    ScanCancellation? cancellation, int maxBytes) async {
  cancellation?.check();
  if (entry.byteLength > maxBytes) {
    throw const NativeWriteException('source.fresh_entry.source_quota',
        'Fresh source file exceeds its byte budget.');
  }
  final bytes = await files.read(entry.fileId);
  cancellation?.check();
  if (bytes.length != entry.byteLength ||
      bytes.any((value) => value < 0 || value > 255) ||
      crypto.sha256.convert(bytes).toString() != entry.sha256!.value) {
    throw ContractError('source.fresh_entry.source_changed', entry.relativePath,
        'Fresh entry source bytes changed after admission.');
  }
  return bytes;
}

({int money, List<String> pcItems, List<int> home}) _globalMetadata(
    List<int> bytes) {
  final values = <String, String>{};
  String text;
  try {
    text = utf8.decode(bytes);
  } on FormatException {
    throw ContractError('source.fresh_entry.metadata_invalid',
        'PBS/metadata.txt', 'Fresh metadata must be bounded UTF-8.');
  }
  var section = -1;
  var count = 0;
  for (final raw in const LineSplitter()
      .convert(text.replaceFirst(RegExp('^\\uFEFF'), ''))) {
    final line = raw.split('#').first.trim();
    if (line.isEmpty) continue;
    final header = RegExp(r'^\[([0-9]{1,5})\]$').firstMatch(line);
    if (header != null) {
      section = int.parse(header.group(1)!);
      if (section == 0) count++;
      continue;
    }
    if (section != 0) continue;
    final declaration =
        RegExp(r'^(StartMoney|StartItemStorage|Home)\s*=\s*(.*)$')
            .firstMatch(line);
    if (declaration == null) {
      if (RegExp(r'^(StartMoney|StartItemStorage|Home)\b').hasMatch(line)) {
        throw ContractError('source.fresh_entry.metadata_invalid',
            'PBS/metadata.txt', 'Fresh metadata assignments must be explicit.');
      }
      continue;
    }
    if (values.containsKey(declaration.group(1)!)) {
      throw ContractError('source.fresh_entry.metadata_ambiguous',
          'PBS/metadata.txt', 'Fresh metadata assignments must be unique.');
    }
    values[declaration.group(1)!] = declaration.group(2)!.trim();
  }
  final moneyText = values['StartMoney'] ?? '';
  final money = int.tryParse(moneyText);
  final pcText = values['StartItemStorage'];
  final pcItems = pcText == null || pcText.isEmpty
      ? <String>[]
      : pcText.split(',').map((s) => s.trim()).toList();
  final homeText = values['Home'] ?? '';
  final home =
      homeText.split(',').map((value) => int.tryParse(value.trim())).toList();
  if (count != 1 ||
      !RegExp(r'^\d{1,9}$').hasMatch(moneyText) ||
      money == null ||
      money > 9999999 ||
      pcItems.length > 256 ||
      pcItems
          .any((value) => !RegExp(r'^[A-Z][A-Z0-9_]{0,63}$').hasMatch(value)) ||
      home.length != 4 ||
      home.any((value) => value == null || value < 0 || value > 65535) ||
      !const [2, 4, 6, 8].contains(home.last)) {
    throw ContractError(
        'source.fresh_entry.metadata_invalid',
        'PBS/metadata.txt',
        'Money, initial PC symbols and home coordinates must be explicit bounded static metadata.');
  }
  return (
    money: money,
    pcItems: List.unmodifiable(pcItems),
    home: List<int>.unmodifiable(home.cast<int>())
  );
}

Future<
        ({
          EntityFacing facing,
          List<SourceFileEntry> files,
          Map<String, Object?> evidence
        })>
    _freshDirection(NormalizedSourceProject source, SourceFilePort files,
        ScanCancellation? cancellation, NativeWriteLimits limits) async {
  final profile = source.interpretationProfile!;
  final archive = _exactFile(source.snapshot, profile.scriptsRelativePath);
  if (archive.sha256 != profile.scriptsArchiveHash) {
    throw ContractError(
        'source.fresh_entry.direction_unqualified',
        archive.relativePath,
        'The fresh direction archive must match its admitted profile.');
  }
  final bytes = await _readAttested(
      archive, files, cancellation, limits.maxArtifactBytes);
  final document =
      const MarshalDecoder().decode(bytes, sourcePath: archive.relativePath);
  final root = document.node(document.rootId);
  final evidence = <Map<String, Object?>>[];
  for (final spec in [
    (
      'walking.Game_Character',
      44,
      'Game_Character',
      '0cb6a5149f998c053055d3c7726d557fe1a1368fcabe14bb4a7c159f09a686b9'
    ),
    (
      'events.Game_Player',
      46,
      'Game_Player',
      '7159cc172004da46b72a51b7d009df24de7a297bdb09599de31a4b5116dab373'
    ),
  ]) {
    final pin = profile.sections[spec.$1];
    if (pin == null ||
        pin['index'] != spec.$2 ||
        pin['sha256'] != spec.$4 ||
        root.kind != MarshalKind.array ||
        root.elements.length <= spec.$2) {
      throw ContractError(
          'source.fresh_entry.direction_unqualified',
          archive.relativePath,
          'Fresh direction requires its exact constructor and player section witnesses.');
    }
    final row = document.node(root.elements[spec.$2]);
    if (row.kind != MarshalKind.array ||
        row.elements.length != 3 ||
        document.node(row.elements[1]).text().text != spec.$3) {
      throw ContractError(
          'source.fresh_entry.direction_unqualified',
          archive.relativePath,
          'Fresh direction section identity differs from its witness.');
    }
    final content = const BoundedZlibDecoder().decode(
        document.node(row.elements[2]).bytes!,
        sourcePath: archive.relativePath);
    if (crypto.sha256.convert(content).toString() != spec.$4) {
      throw ContractError(
          'source.fresh_entry.direction_unqualified',
          archive.relativePath,
          'Fresh direction section bytes differ from their witness.');
    }
    final lines = utf8.decode(content).split('\n');
    final at = lines.indexWhere(
        (line) => RegExp(r'^@direction\s*=\s*2$').hasMatch(line.trim()));
    final moveto =
        lines.indexWhere((line) => line.trim().startsWith('def moveto('));
    if (spec.$2 == 44 && (at < 0 || moveto < 0)) {
      throw StateError('The admitted fresh direction oracle drifted.');
    }
    evidence.add({
      'sectionIndex': spec.$2,
      'sectionName': spec.$3,
      'sha256': spec.$4,
      if (spec.$2 == 44) ...{
        'directionAssignmentLine': at + 1,
        'stationaryPlacementOracle': [
          for (var i = moveto; i < moveto + 9 && i < lines.length; i++)
            {'line': i + 1, 'text': lines[i]}
        ],
      }
    });
  }
  return (
    facing: EntityFacing.south,
    files: [archive],
    evidence: {
      'archive': archive.toJson(),
      'sections': evidence,
      'sourceDirection': 2,
      'nativeFacing': 'south',
      'sourceScriptsExecuted': 0
    }
  );
}

bool _passableRecoveryCell(NormalizedSourceProject source, MapData map,
    int sourceMapId, GridPos point) {
  if (point.x < 0 ||
      point.y < 0 ||
      point.x >= map.size.width ||
      point.y >= map.size.height ||
      map.layers.whereType<CollisionLayer>().any((layer) =>
          layer.collisions.length != map.size.width * map.size.height ||
          layer.collisions[point.y * map.size.width + point.x]) ||
      map.entities.any((entity) =>
          entity.blocksMovement &&
          resolveEntityCollisionCells(entity).contains(point))) {
    return false;
  }
  final resolver = SourceSemanticResolver.forProject(source);
  return resolver.profile.isQualified &&
      resolver
              .resolveConnectionEntryTile(
                  resolver.cellAt(sourceMapId, point.x, point.y))
              .status ==
          SourcePassageStatus.allowed;
}
