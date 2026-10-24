import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';
import 'source_event_projection.dart';
import 'source_new_game_binding.dart';
import 'source_new_game_defaults.dart';
import 'source_player_character_import.dart';

final class SourceSystemEntryBinding implements SourceNewGameBinding {
  SourceSystemEntryBinding._(
      {required this.config,
      required this.artifacts,
      required this.importMutations,
      required this.mutations,
      required this.nativeMaps,
      required this.imports,
      required Map<String, Object?> evidence})
      : evidence = immutableCanonicalJsonOf(evidence) as Map<String, Object?>;

  @override
  final ProjectNewGameConfig config;
  @override
  ProjectDefeatRecoveryConfig? get defeatRecovery => null;
  @override
  List<SceneAsset> get scenes => const [];
  @override
  List<NarrativeFactDefinition> get facts => const [];
  @override
  final List<NativeArtifact> artifacts;
  @override
  final List<NativeMutation> importMutations, mutations;
  @override
  final Map<int, MapData> nativeMaps;
  @override
  final List<SourcePlayerCharacterImport> imports;
  @override
  final Map<String, Object?> evidence;
}

final class SourceSystemEntryBindingResolver {
  const SourceSystemEntryBindingResolver();

  Future<SourceSystemEntryBinding?> read({
    required NormalizedSourceProject source,
    required SourceEventProjection projection,
    required SourceFilePort files,
    Map<String, Object?>? semanticPlayerEvidence,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    limits.validate();
    cancellation?.check();
    final start = sourceSystemStart(source);
    final profile = SourceEventProfile.forProject(source);
    if (start == null ||
        !start.isBoundTo(source) ||
        !profile.isQualified ||
        projection.semanticEvidence['sourceSnapshotHash'] !=
            source.snapshot.canonicalHash.value ||
        projection.semanticEvidence['normalizationHash'] !=
            source.canonicalHash.value ||
        projection.semanticEvidence['sourceProfileHash'] !=
            profile.canonicalHash.value) {
      return null;
    }
    final map = projection.nativeMaps[start.sourceMapId];
    final position = GridPos(x: start.x, y: start.y);
    if (map == null ||
        map.version == ProjectVersion.v9 ||
        map.spatialScene != null ||
        !_passable(source, map, start.sourceMapId, position) ||
        !sourceSystemEntryEventsQualified(
            source, projection, start.sourceMapId)) {
      return null;
    }
    final defaults = await const SourceNewGameDefaultsReader().read(
        source: source,
        files: files,
        limits: limits,
        cancellation: cancellation);
    if (defaults == null) return null;
    final avatar = await const SourcePlayerCharacterImporter().read(
        snapshot: source.snapshot,
        files: files,
        selectedHeaderId: defaults.avatarHeaderId,
        selectedOutfit: defaults.outfit,
        cancellation: cancellation);
    final reusePlayer = semanticPlayerEvidence != null &&
        canonicalJsonOf(semanticPlayerEvidence, limits: limits.jsonLimits) ==
            canonicalJsonOf(avatar.evidence, limits: limits.jsonLimits);
    final identity = canonicalHashOf({
      'kind': 'sourceSystemEntryBinding',
      'systemContentHash': start.systemContentHash.value,
      'sourceSnapshotHash': source.snapshot.canonicalHash.value,
      'defaults': defaults.evidence,
      'avatar': avatar.evidence,
    }).value;
    final prefix = 'source_system_${identity.substring(0, 24)}';
    final candidates = map.entities
        .where((entity) =>
            entity.kind == MapEntityKind.spawn &&
            entity.spawn?.role == EntitySpawnRole.playerStart &&
            entity.pos == position &&
            entity.spawn?.facing == defaults.facing)
        .toList();
    if (candidates.length > 1) {
      throw ContractError('source.new_game.spawn_ambiguous', r'$',
          'The source start requires one unambiguous player spawn.');
    }
    final spawn = candidates.firstOrNull ??
        MapEntity(
            id: '${prefix}_spawn',
            name: 'Nouvelle partie',
            kind: MapEntityKind.spawn,
            pos: position,
            size: const GridSize(width: 1, height: 1),
            blocksMovement: false,
            spawn: MapEntitySpawnData(facing: defaults.facing));
    if (candidates.isEmpty &&
        map.entities.any((entity) => entity.id == spawn.id)) {
      throw ContractError('source.new_game.spawn_collision', r'$',
          'The source start identity is already owned by another entity.');
    }
    final owners = <ConverterId>{
      start.systemFileId,
      avatar.metadataFile.fileId,
      ...avatar.sheets.map((sheet) => sheet.imageFile.fileId)
    }.toList();
    NativeMutation mutation(String suffix, String action, List<String> targets,
            Map<String, Object?> parameters) =>
        NativeMutation(
            operationId: ConverterId('$prefix-$suffix'),
            actionId: action,
            sourceEntityIds: owners,
            targetEntityIds: targets.map(ConverterId.new).toList(),
            parameters: parameters,
            limits: limits);
    final artifacts = <NativeArtifact>[];
    final imports = <NativeMutation>[];
    for (final sheet in avatar.sheets) {
      final artifact = NativeArtifact(bytes: sheet.outputBytes, limits: limits);
      artifacts.add(artifact);
      imports
          .add(mutation('${sheet.declaration}-image', 'tileset.import_image', [
        sheet.tilesetId,
        sheet.assetId
      ], {
        'artifactHandle': artifact.handle,
        'tilesetId': sheet.tilesetId,
        'name': '${avatar.character.name} ${sheet.declaration}',
        'tileWidth': 32,
        'tileHeight': 32,
      }));
    }
    imports.add(mutation('avatar-create', 'characterStudio.character.create', [
      avatar.character.id
    ], {
      'name': avatar.character.name,
      'tilesetId': avatar.tilesetId,
      'frameWidth': avatar.character.frameWidth,
      'frameHeight': avatar.character.frameHeight,
      'tags': avatar.character.tags
    }));
    for (final clip in avatar.character.animations) {
      imports.add(mutation('${clip.state.name}-${clip.direction.name}',
          'characterStudio.animationClip.upsert', [
        avatar.character.id
      ], {
        'characterId': avatar.character.id,
        'kind': 'system',
        'state': clip.toJson()['state'],
        'direction': clip.direction.name,
        'sourceAssetId': clip.sourceAssetId,
        'loop': clip.loop,
        'frames': clip.frames.map((frame) => frame.toJson()).toList(),
      }));
    }
    imports.add(mutation(
        'avatar-default',
        'characterStudio.character.setDefault',
        [avatar.character.id],
        {'characterId': avatar.character.id}));
    final config = ProjectNewGameConfig(
        enabled: true,
        startMapId: map.id,
        startSpawnId: spawn.id,
        playerName: defaults.playerName,
        startingMoney: defaults.money,
        playerAvatarCharacterIds: [avatar.character.id]);
    final mutations = <NativeMutation>[
      if (candidates.isEmpty)
        mutation('spawn', 'entity.create', [map.id, spawn.id],
            {'mapId': map.id, 'entity': spawn.toJson()}),
      mutation('new-game', 'campaign.new_game.update', [],
          {'newGame': config.toJson()}),
    ];
    validateNativeArtifactCount(
        artifacts: artifacts, sourceArtifacts: const [], limits: limits);
    if (artifacts.fold<int>(0, (sum, artifact) => sum + artifact.bytes.length) >
            limits.maxTotalArtifactBytes ||
        imports.length + mutations.length > limits.maxMutations) {
      throw const NativeWriteException('source.new_game.quota',
          'The source new game binding exceeds its bounded budget.');
    }
    cancellation?.check();
    return SourceSystemEntryBinding._(
        config: config,
        artifacts: reusePlayer ? const [] : List.unmodifiable(artifacts),
        importMutations: reusePlayer ? const [] : List.unmodifiable(imports),
        mutations: List.unmodifiable(mutations),
        nativeMaps: Map.unmodifiable({
          start.sourceMapId: candidates.isEmpty
              ? map.copyWith(entities: [...map.entities, spawn])
              : map
        }),
        imports: List.unmodifiable([avatar]),
        evidence: {
          'kind': 'sourceSystemEntryBinding',
          'sourceSnapshotHash': source.snapshot.canonicalHash.value,
          'normalizationHash': source.canonicalHash.value,
          'profileHash': profile.canonicalHash.value,
          'program': start.toJson(),
          'defaults': defaults.evidence,
          'avatars': [avatar.evidence],
          'semanticPlayerImportReused': reusePlayer,
          'nativeStartSpawnId': spawn.id,
          'nativeStartMapId': map.id,
          'initialPartyCount': 0,
          'initialBagCount': 0,
          'initialPokemonStorage': 'empty',
          'starterSeeded': false,
          'preSession': 'none',
          'initialRecoveryPoint': 'none',
          'initialPcItemStorage': {
            'sourceSymbols': defaults.pcItems,
            'status': defaults.pcItems.isEmpty ? 'empty' : 'unsupported',
            'diagnostic': defaults.pcItems.isEmpty
                ? null
                : 'sourceInitialPcItemStorageUnsupported',
            'addedToBag': false
          },
          'collisionModified': false,
          'sourceScriptsExecuted': 0,
          'aiCalls': 0,
          'nativeExecutionQualified': false,
        });
  }
}

bool sourceSystemEntryEventsQualified(NormalizedSourceProject source,
    SourceEventProjection projection, int sourceMapId) {
  final profile = SourceEventProfile.forProject(source);
  if (!profile.isQualified) return false;
  final analyzer = SourceEventAnalyzer.forProject(source, profile: profile);
  final maps =
      source.maps.where((entry) => entry.map.sourceMapId == sourceMapId);
  if (maps.length != 1) return false;
  final rows = projection.semanticEvidence['events'];
  if (rows is! List) return false;
  for (final raw in maps.single.map.events) {
    if (!raw.pages.any((page) => const {3, 4}.contains(page.triggerCode))) {
      continue;
    }
    final event = analyzer.analyzeEventAt(sourceMapId, raw.sourceEventId);
    if (event == null) return false;
    SourceEventPageAnalysis? selected;
    for (final page in event.pages.reversed) {
      final active = page.condition.evaluate(eventTempSwitches: const {
        'A':false,'B':false,'C':false,'D':false,
      });
      if (active == null) return false;
      if (active) {
        selected = page;
        break;
      }
    }
    if (selected == null ||
        !const {3, 4}.contains(selected.triggerCode) ||
        selected.isEmpty) {
      continue;
    }
    final evidence = rows
        .whereType<Map>()
        .where((row) => row['sourceIdentity'] == event.identity.value)
        .toList();
    if (evidence.length != 1 ||
        evidence.single['status'] != 'adaptedStaticSemantics' ||
        evidence.single['gaps'] is! List ||
        (evidence.single['gaps'] as List).isNotEmpty) {
      return false;
    }
    if ((evidence.single['nativeIntroduction'] as Map?)?['requiresNativeFreshEntryFactory'] == true) {
      return false;
    }
  }
  return true;
}

bool _passable(NormalizedSourceProject source, MapData map, int sourceMapId,
    GridPos point) {
  if (point.x < 0 ||
      point.y < 0 ||
      point.x >= map.size.width ||
      point.y >= map.size.height ||
      map.layers.whereType<CollisionLayer>().any((layer) =>
          layer.collisions.length != map.size.width * map.size.height ||
          layer.collisions[point.y * map.size.width + point.x]) ||
      map.entities.any((entity) =>
          entity.blocksMovement &&
          resolveEntityCollisionCells(entity).contains(point))) return false;
  final resolver = SourceSemanticResolver.forProject(source);
  return resolver.profile.isQualified &&
      resolver
              .resolveConnectionEntryTile(
                  resolver.cellAt(sourceMapId, point.x, point.y))
              .status ==
          SourcePassageStatus.allowed;
}
