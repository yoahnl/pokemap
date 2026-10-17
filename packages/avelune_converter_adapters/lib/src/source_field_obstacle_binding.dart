import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';

import 'native_project_writer.dart';
import 'native_encounter_catalog_bindings.dart';

enum SourceRockSmashEncounterStatus { absent, requiredUnqualified, requiredQualified }

final class SourceFieldObstacleBindingUnavailable implements Exception {
  const SourceFieldObstacleBindingUnavailable(this.reason);
  final String reason;
}

final class SourceFieldObstacleBinding {
  SourceFieldObstacleBinding._({required this.eventIdentity,
    required this.sourceMapId, required this.sourceEventId,
    required this.x, required this.y, required this.program,
    required this.sourceSnapshotHash, required this.normalizationHash,
    required this.profileHash, required this.sourceRegion,
    required this.badgePolicyRegion, required this.sourceBadgeIndex,
    required this.nativeBadge, required this.nativeElement,
    required this.rockSmashEncounterStatus,
    _NativeRockSmashEncounterBinding? nativeRockSmashEncounterBinding})
      : _nativeRockSmashEncounterBinding = nativeRockSmashEncounterBinding;

  final ConverterId eventIdentity;
  final int sourceMapId, sourceEventId, x, y;
  final SourceFieldObstacleProgramNode program;
  final Sha256Hash sourceSnapshotHash, normalizationHash, profileHash;
  final int sourceRegion, badgePolicyRegion, sourceBadgeIndex;
  final BadgeDefinition nativeBadge;
  final ProjectElementEntry nativeElement;
  final SourceRockSmashEncounterStatus? rockSmashEncounterStatus;
  final _NativeRockSmashEncounterBinding? _nativeRockSmashEncounterBinding;

  String? get nativeRockSmashEncounterTableId => _nativeRockSmashEncounterBinding?.tableId;
  bool get pendingCatalogCompanion => _nativeRockSmashEncounterBinding != null;

  Map<String, Object?>? catalogCompanionRequest(String entityId) {
    final binding = _nativeRockSmashEncounterBinding;
    if (binding == null) return null;
    return {
      'sourceEventIdentity': eventIdentity.value,
      'sourceMapId': sourceMapId,
      'actionId': 'entity.set_interactive_encounter',
      'parameters': {
        'mapId': binding.nativeMapId,
        'entityId': entityId,
        'interactiveEncounter': MapEntityInteractiveEncounterData(
          encounterTableId: binding.tableId,
          trigger: InteractiveEncounterTrigger.afterRockSmash,
          reusePolicy: InteractiveEncounterReusePolicy.oncePerMapInstance,
        ).toJson(),
      },
      'binding': toJson(),
    };
  }

  FieldObstacleKind get nativeKind => switch (program.obstacleKind) {
    SourceFieldObstacleKind.cutTree => FieldObstacleKind.cutTree,
    SourceFieldObstacleKind.strengthBoulder => FieldObstacleKind.strengthBoulder,
    SourceFieldObstacleKind.rockSmashRock => FieldObstacleKind.rockSmashRock,
  };

  bool isBoundToEvent({required NormalizedSourceProject source,
      required SourceEventAnalysis analysis,
      required SourceEventDefinition event, String? nativeMapId}) =>
      source.snapshot.canonicalHash == sourceSnapshotHash &&
      source.canonicalHash == normalizationHash &&
      analysis.profile.canonicalHash == profileHash &&
      event.identity == eventIdentity && event.sourceMapId == sourceMapId &&
      event.sourceEventId == sourceEventId && event.x == x && event.y == y &&
      analysis.attestsFieldObstacleEvent(source: source, event: event) &&
      event.pages.length == 1 && event.pages.single.body.nodes.length == 1 &&
      event.pages.single.body.nodes.single is SourceFieldObstacleProgramNode &&
      canonicalJsonOf((event.pages.single.body.nodes.single as SourceFieldObstacleProgramNode).toJson()) ==
          canonicalJsonOf(program.toJson()) &&
      (nativeKind != FieldObstacleKind.rockSmashRock ||
          rockSmashEncounterStatus == SourceRockSmashEncounterStatus.absent ||
          rockSmashEncounterStatus == SourceRockSmashEncounterStatus.requiredQualified &&
              _nativeRockSmashEncounterBinding?.isBoundTo(
                  source: source, sourceMapId: sourceMapId, nativeMapId: nativeMapId) == true);

  MapEntity createNativeEntity(String entityId) => MapEntity(
      id: entityId, name: nativeElement.name, kind: MapEntityKind.custom,
      pos: GridPos(x: x, y: y), blocksMovement: true,
      fieldObstacle: MapEntityFieldObstacleData(kind: nativeKind),
      editorVisual: MapEntityEditorVisual(elementId: nativeElement.id));

  Map<String, Object?> toJson() => {
    'kind': 'sourceFieldObstacleBinding', 'version': 1,
    'sourceEventIdentity': eventIdentity.value,
    'sourceMapId': sourceMapId, 'sourceEventId': sourceEventId,
    'sourceSnapshotHash': sourceSnapshotHash.value,
    'normalizationHash': normalizationHash.value, 'profileHash': profileHash.value,
    'sourceRegion': sourceRegion, 'badgePolicyRegion': badgePolicyRegion,
    'sourceBadgeIndex': sourceBadgeIndex, 'program': program.toJson(),
    'nativeBadge': nativeBadge.toJson(), 'nativeElementId': nativeElement.id,
    'initialPlayerBadgeGranted': false, 'initialPlayerAbilityUnlocked': false,
    'nativeRequiresNonFaintedPokemon': true, 'nativeResetPolicy': 'mapInstance',
    'rockSmashEncounterStatus': rockSmashEncounterStatus?.name,
    'nativeRockSmashEncounterTableId': nativeRockSmashEncounterTableId,
    'nativeRockSmashEncounterBinding': _nativeRockSmashEncounterBinding?.toJson(),
    'pendingCatalogCompanion': pendingCatalogCompanion,
    'nativeExecutionQualified': !pendingCatalogCompanion,
    'fullSourceFieldObstacleParityQualified': false,
    'audioSourceParity': false, 'sourceScriptsExecuted': 0,
  };
}

final class SourceFieldObstacleBindings {
  SourceFieldObstacleBindings._({
    required Map<ConverterId, SourceFieldObstacleBinding> bindings,
    required Map<ConverterId, String> refusals,
    required List<BadgeDefinition> badges,
    required List<ProjectElementEntry> elements,
    required List<NativeArtifact> artifacts,
    required List<NativeMutation> mutations,
    required Map<String, Object?> evidence,
  }) : byEventIdentity = Map.unmodifiable(bindings),
       refusals = Map.unmodifiable(refusals), badges = List.unmodifiable(badges),
       elements = List.unmodifiable(elements), artifacts = List.unmodifiable(artifacts),
       mutations = List.unmodifiable(mutations), evidence = Map.unmodifiable(evidence);

  final Map<ConverterId, SourceFieldObstacleBinding> byEventIdentity;
  final Map<ConverterId, String> refusals;
  final List<BadgeDefinition> badges;
  final List<ProjectElementEntry> elements;
  final List<NativeArtifact> artifacts;
  final List<NativeMutation> mutations;
  final Map<String, Object?> evidence;
}

const _fieldVisuals = {
  SourceFieldObstacleKind.cutTree: (
    'OBJ_FRLG_Cut Tree', 'Arbre à couper',
    '68271cc5662b112111bec29ea8122466712535a4fd2381262a20a65064e974cb'),
  SourceFieldObstacleKind.strengthBoulder: (
    'OBJ_FRLG_Strength Boulder', 'Rocher à pousser',
    'd4fa3e710bf8147bf0e57e9d3974606087cf528e43841da6ab66560006f66fdf'),
  SourceFieldObstacleKind.rockSmashRock: (
    'OBJ_FRLG_RockSmash Rock', 'Rocher à briser',
    '9800dab1498f66d53cbcfac8b50a570e556fdf782245e6e681881a057350e0bc'),
};

final class SourceFieldObstacleBindingResolver {
  const SourceFieldObstacleBindingResolver();

  Future<SourceFieldObstacleBindings?> read({
    required NormalizedSourceProject source,
    required SourceEventAnalysis analysis,
    required SourceFilePort files,
    Set<int>? sourceMapIds,
    NativeEncounterCatalogQualification? nativeEncounterQualification,
    Map<int, String>? nativeMapIds,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    cancellation?.check();
    limits.validate();
    final events = analysis.events.where((event) =>
      (sourceMapIds == null || sourceMapIds.contains(event.sourceMapId)) &&
      !event.isQuarantined && event.pages.length == 1 &&
      event.pages.single.body.nodes.length == 1 &&
      event.pages.single.body.nodes.single is SourceFieldObstacleProgramNode).toList();
    if (events.isEmpty) return null;
    if (!analysis.profile.isQualified ||
        analysis.profile.sourceSnapshotHash != source.snapshot.canonicalHash ||
        analysis.profile.normalizationHash != source.canonicalHash ||
        source.snapshot.state != SourceScanState.complete ||
        events.any((event) => !analysis.attestsFieldObstacleEvent(source: source, event: event))) {
      throw const SourceFieldObstacleBindingUnavailable('event_attestation_unqualified');
    }
    var readBytes = 0;
    final witnesses = <String, SourceFileEntry>{};
    Future<List<int>> exact(String path, {String? hash}) async {
      cancellation?.check();
      final matches = source.snapshot.entries.where((entry) =>
          sourcePathCollisionKey(entry.relativePath) == sourcePathCollisionKey(path)).toList();
      if (matches.length != 1 || matches.single.relativePath != path ||
          matches.single.kind != SourceNodeKind.file || matches.single.sha256 == null ||
          (hash != null && matches.single.sha256!.value != hash)) {
        throw SourceFieldObstacleBindingUnavailable('source_unattested:$path');
      }
      final entry = matches.single;
      if (entry.byteLength > limits.maxArtifactBytes ||
          entry.byteLength > limits.maxTotalArtifactBytes - readBytes) {
        throw const NativeWriteException('events.field_obstacle.quota',
            'Field obstacle witnesses exceed the native read budget.');
      }
      readBytes += entry.byteLength;
      final bytes = await files.read(entry.fileId);
      cancellation?.check();
      if (bytes.length != entry.byteLength || bytes.any((value) => value < 0 || value > 255) ||
          crypto.sha256.convert(bytes).toString() != entry.sha256!.value) {
        throw ContractError('source.field_obstacle.source_changed', path,
            'Field obstacle bytes differ from their admitted snapshot.');
      }
      witnesses[path] = entry;
      return bytes;
    }

    final scripts = await exact('Data/Scripts.rxdata',
        hash: SourceEventProfile.kantoScriptsArchiveSha256);
    final settings = _fieldSettings(scripts);
    final metadata = _fieldMapRegions(utf8.decode(await exact('PBS/map_metadata.txt')));
    final refusals = <ConverterId, String>{};
    final policies = <ConverterId, (int, int, int)>{};
    final locksByKind = <SourceFieldObstacleKind, Set<String>>{};
    for (final event in events) {
      final program = event.pages.single.body.nodes.single as SourceFieldObstacleProgramNode;
      final region = metadata[event.sourceMapId];
      final policyRegion = region == null ? null : (region > 99 ? region ~/ 100 : region);
      final row = policyRegion != null && policyRegion >= 0 && policyRegion < settings.$1.length
          ? settings.$1[policyRegion] : null;
      final column = settings.$2[program.sourceMove];
      final badge = row != null && column != null && column >= 0 && column < row.length
          ? row[column] : null;
      if (region == null || policyRegion == null || badge == null || badge < 0) {
        refusals[event.identity] = 'sourceFieldObstacleBadgePolicyUnqualified';
        continue;
      }
      policies[event.identity] = (region, policyRegion, badge);
      locksByKind.putIfAbsent(program.obstacleKind, () => {}).add('$policyRegion:$badge');
    }
    for (final event in events) {
      final program = event.pages.single.body.nodes.single as SourceFieldObstacleProgramNode;
      if ((locksByKind[program.obstacleKind]?.length ?? 0) > 1) {
        refusals[event.identity] = 'sourceFieldObstacleConflictingBadgeLocks:${program.sourceMove}';
      }
    }
    final smashStatuses = <int, SourceRockSmashEncounterStatus>{};
    final nativeSmashBindings = <int, _NativeRockSmashEncounterBinding>{};
    if (events.any((event) =>
        (event.pages.single.body.nodes.single as SourceFieldObstacleProgramNode).obstacleKind ==
            SourceFieldObstacleKind.rockSmashRock && !refusals.containsKey(event.identity))) {
      try {
        final compiled = const MarshalDecoder().decode(await exact('Data/encounters.dat'),
            sourcePath: 'Data/encounters.dat');
        final presentMaps = _compiledRockSmashMaps(compiled);
        final pbs = await const SourcePbsParser().read(snapshot: source.snapshot,
            files: _FieldObstacleWitnessFiles(source, exact),
            families: const {SourcePbsFamily.encounters}, cancellation: cancellation);
        if (pbs.documents.isEmpty || pbs.diagnostics.any((diagnostic) => diagnostic.blocking)) {
          throw const SourceFieldObstacleBindingUnavailable('encounter_source_unqualified');
        }
        for (final entry in pbs.entries) {
          if (entry.isBlocked || entry.identity == null) {
            throw const SourceFieldObstacleBindingUnavailable('encounter_source_unqualified');
          }
          if (entry.methods.any((method) => method.name == 'RockSmash')) {
            presentMaps.add(entry.identity!.sourceMapId!);
          }
        }
        if (nativeEncounterQualification != null &&
            nativeEncounterQualification.admitsAutomaticSource(source.snapshot) &&
            nativeMapIds != null && nativeMapIds.isNotEmpty &&
            nativeMapIds.length <= 8 &&
            nativeMapIds.keys.every((mapId) => source.maps.any((map) => map.map.sourceMapId == mapId)) &&
            nativeMapIds.values.every((mapId) => mapId.trim().isNotEmpty && mapId.trim() == mapId) &&
            nativeMapIds.values.toSet().length == nativeMapIds.length) {
          final catalogPbs = await const SourcePbsParser().read(
              snapshot: source.snapshot, files: _FieldObstacleWitnessFiles(source, exact),
              families: const {SourcePbsFamily.species, SourcePbsFamily.encounters},
              cancellation: cancellation);
          try {
            final native = await const NativeEncounterCatalogBindings().bind(
                snapshot: source.snapshot, source: catalogPbs,
                files: _FieldObstacleWitnessFiles(source, exact), nativeMapIds: nativeMapIds,
                sourceMapNames: {for (final map in source.maps) map.map.sourceMapId: map.map.name},
                qualification: nativeEncounterQualification,
                ratePolicy: NativeEncounterRatePolicy.adaptSourceBasePercentToNativeConstantChance,
                fishingRatePolicy: NativeEncounterFishingRatePolicy.adaptSourceBaseFishingBiteChanceToNativeTable,
                cancellation: cancellation);
            for (final mapId in presentMaps) {
              final tableId = native.tableIdsBySourceMethod[mapId]?['RockSmash'];
              final table = native.tables.where((table) => table.id == tableId).singleOrNull;
              final rows = (native.evidence['tables'] as List).cast<Map>().where((row) =>
                  row['method'] == 'RockSmash' && row['nativeTableId'] == tableId &&
                  (row['sourceIdentity'] as Map)['sourceMapId'] == mapId &&
                  (row['sourceIdentity'] as Map)['namespace'] == source.snapshot.logicalProjectNamespace.value &&
                  row['nativeMapId'] == nativeMapIds[mapId]).toList();
              if (tableId == null || table == null || rows.length != 1 ||
                  table.encounterKind != EncounterKind.special || table.entries.isEmpty) {
                continue;
              }
              nativeSmashBindings[mapId] = _NativeRockSmashEncounterBinding(
                  source: source, sourceMapId: mapId, nativeMapId: nativeMapIds[mapId]!,
                  table: table, tableBinding: Map<String, Object?>.from(rows.single),
                  qualification: nativeEncounterQualification,
                  sourcePbsHash: catalogPbs.canonicalHash);
            }
          } on ContractError catch (error) {
            if (!error.code.startsWith('native_encounter.')) rethrow;
          }
        }
        for (final event in events) {
          final program = event.pages.single.body.nodes.single as SourceFieldObstacleProgramNode;
          if (program.obstacleKind != SourceFieldObstacleKind.rockSmashRock) continue;
          final status = presentMaps.contains(event.sourceMapId)
              ? nativeSmashBindings.containsKey(event.sourceMapId)
                  ? SourceRockSmashEncounterStatus.requiredQualified
                  : SourceRockSmashEncounterStatus.requiredUnqualified
              : SourceRockSmashEncounterStatus.absent;
          smashStatuses[event.sourceMapId] = status;
          if (status == SourceRockSmashEncounterStatus.requiredUnqualified) {
            refusals[event.identity] = 'sourceRockSmashEncounterRequiredUnqualified';
          }
        }
      } on SourceFieldObstacleBindingUnavailable catch (error) {
        for (final event in events) {
          if ((event.pages.single.body.nodes.single as SourceFieldObstacleProgramNode).obstacleKind ==
              SourceFieldObstacleKind.rockSmashRock) {
            refusals[event.identity] = 'sourceRockSmashEncounterUnattested:${error.reason}';
          }
        }
      } on ContractError {
        rethrow;
      } on FormatException {
        for (final event in events) {
          if ((event.pages.single.body.nodes.single as SourceFieldObstacleProgramNode).obstacleKind ==
              SourceFieldObstacleKind.rockSmashRock) {
            refusals[event.identity] = 'sourceRockSmashEncounterSourceInvalid';
          }
        }
      } on BinaryDecodeError {
        for (final event in events) {
          if ((event.pages.single.body.nodes.single as SourceFieldObstacleProgramNode).obstacleKind ==
              SourceFieldObstacleKind.rockSmashRock) {
            refusals[event.identity] = 'sourceRockSmashEncounterSourceInvalid';
          }
        }
      }
    }
    final accepted = events.where((event) => !refusals.containsKey(event.identity)).toList();
    final namespace = canonicalHashOf({
      'namespace': source.snapshot.logicalProjectNamespace.value,
      'kind': 'sourceFieldObstacles',
    }).value.substring(0, 24);
    final badges = <String, BadgeDefinition>{};
    final elements = <SourceFieldObstacleKind, ProjectElementEntry>{};
    final artifacts = <String, NativeArtifact>{};
    final mutations = <NativeMutation>[];
    NativeMutation mutation(String id, String action, List<String> targets,
        Map<String, Object?> parameters) => NativeMutation(
        operationId: ConverterId('source_field_${id}_$namespace'), actionId: action,
        sourceEntityIds: [for (final file in witnesses.values) file.fileId],
        targetEntityIds: targets.map(ConverterId.new).toList(),
        parameters: parameters, limits: limits);
    final kinds = accepted.map((event) =>
        (event.pages.single.body.nodes.single as SourceFieldObstacleProgramNode).obstacleKind).toSet()
        .toList()..sort((a,b) => a.index.compareTo(b.index));
    for (final kind in kinds) {
      final visual = _fieldVisuals[kind]!;
      final image = await exact('Graphics/Characters/${visual.$1}.png', hash: visual.$3);
      final dimensions = decodeRasterImageDimensions(image, mediaType: 'image/png');
      if (dimensions == null || dimensions.width != 128 || dimensions.height != 128) {
        throw const SourceFieldObstacleBindingUnavailable('visual_unqualified');
      }
      if (128 * 128 > limits.maxImagePixels) {
        throw const NativeWriteException('events.field_obstacle.quota',
            'Field obstacle visual exceeds the native image budget.');
      }
      final artifact = NativeArtifact(bytes: image, expectedSha256: Sha256Hash(visual.$3), limits: limits);
      artifacts[artifact.handle] = artifact;
      final tilesetId = 'source_field_${kind.name}_$namespace';
      final category = ProjectElementCategory(id: 'source_field_${kind.name}_category_$namespace', name: visual.$2);
      final element = ProjectElementEntry(id: 'source_field_${kind.name}_element_$namespace',
          name: visual.$2, tilesetId: tilesetId, categoryId: category.id,
          frames: [TilesetVisualFrame(source: const TilesetSourceRect(x:0,y:0))],
          collisionProfile: const ElementCollisionProfile(cells:[GridPos(x:0,y:0)]));
      elements[kind] = element;
      mutations.addAll([
        mutation('${kind.name}_visual', 'tileset.import_image', [tilesetId,'image_$tilesetId'],
          {'artifactHandle':artifact.handle,'tilesetId':tilesetId,'name':visual.$2,'tileWidth':32,'tileHeight':32}),
        mutation('${kind.name}_category', 'element_category.upsert', [category.id], {'category':category.toJson()}),
        mutation('${kind.name}_element', 'element.upsert', [element.id], {'element':element.toJson()}),
      ]);
    }
    final bindings = <ConverterId, SourceFieldObstacleBinding>{};
    for (final event in accepted) {
      final program = event.pages.single.body.nodes.single as SourceFieldObstacleProgramNode;
      final policy = policies[event.identity]!;
      final ability = switch (program.obstacleKind) {
        SourceFieldObstacleKind.cutTree => FieldAbility.cut,
        SourceFieldObstacleKind.strengthBoulder => FieldAbility.strength,
        SourceFieldObstacleKind.rockSmashRock => FieldAbility.rockSmash,
      };
      final badgeId = 'source_badge_r${policy.$2}_b${policy.$3}_$namespace';
      final badge = BadgeDefinition(id: badgeId,
          label: 'Badge source ${policy.$3} (région ${policy.$2})', fieldAbilityUnlock: ability);
      if (!badges.containsKey(badgeId)) {
        badges[badgeId] = badge;
        mutations.add(mutation('badge_r${policy.$2}_b${policy.$3}',
            'campaign.badge.upsert', [badgeId], {'value':badge.toJson()}));
      } else if (badges[badgeId] != badge) {
        throw const SourceFieldObstacleBindingUnavailable('badge_ability_conflict');
      }
      final binding = SourceFieldObstacleBinding._(eventIdentity:event.identity,
          sourceMapId:event.sourceMapId,sourceEventId:event.sourceEventId,x:event.x,y:event.y,
          program:program,sourceSnapshotHash:source.snapshot.canonicalHash,
          normalizationHash:source.canonicalHash,profileHash:analysis.profile.canonicalHash,
          sourceRegion:policy.$1,badgePolicyRegion:policy.$2,sourceBadgeIndex:policy.$3,
          nativeBadge:badge,nativeElement:elements[program.obstacleKind]!,
          rockSmashEncounterStatus:smashStatuses[event.sourceMapId],
          nativeRockSmashEncounterBinding: program.obstacleKind == SourceFieldObstacleKind.rockSmashRock
              ? nativeSmashBindings[event.sourceMapId] : null);
      if (!binding.isBoundToEvent(source:source,analysis:analysis,event:event,nativeMapId:nativeMapIds?[event.sourceMapId])) {
        throw const SourceFieldObstacleBindingUnavailable('event_binding_unqualified');
      }
      bindings[event.identity] = binding;
    }
    return SourceFieldObstacleBindings._(bindings:bindings,refusals:refusals,
        badges:badges.values.toList(),elements:elements.values.toList(),
        artifacts:artifacts.values.toList(),mutations:mutations,evidence:{
          'kind':'sourceFieldObstacleBindings','version':1,
          'sourceFiles':[for(final file in witnesses.values) file.toJson()],
          'events':[for(final binding in bindings.values) binding.toJson()],
          'pendingCatalogCompanions':[for(final binding in bindings.values)
            if(binding.pendingCatalogCompanion) binding.toJson()],
          'refusals':[for(final entry in refusals.entries)
            {'sourceEventIdentity':entry.key.value,'reason':entry.value}],
          'rockSmashEncounters':[for(final entry in smashStatuses.entries)
            {'sourceMapId':entry.key,'status':entry.value.name}],
          'nativeBadges':[for(final badge in badges.values) badge.toJson()],
          'initialPlayerStateMutated':false,
          'sourceFrame':{'sheetWidth':128,'sheetHeight':128,'x':0,'y':0,'width':32,'height':32},
          'nativeImageRawSha256':[for(final artifact in artifacts.values) artifact.rawSha256.value],
          'sourcePixelsResampled':false,'audioSourceParity':false,'sourceScriptsExecuted':0,
        });
  }
}

final class _NativeRockSmashEncounterBinding {
  _NativeRockSmashEncounterBinding({
    required NormalizedSourceProject source,
    required this.sourceMapId,
    required this.nativeMapId,
    required ProjectEncounterTable table,
    required Map<String, Object?> tableBinding,
    required this.qualification,
    required Sha256Hash sourcePbsHash,
  }) : sourceSnapshotHash = source.snapshot.canonicalHash,
       normalizationHash = source.canonicalHash,
       tableId = table.id,
       encodedEvidence = canonicalJsonOf({
         'sourceSnapshotHash': source.snapshot.canonicalHash.value,
         'normalizationHash': source.canonicalHash.value,
         'sourcePbsHash': sourcePbsHash.value,
         'sourceMapId': sourceMapId,
         'nativeMapId': nativeMapId,
         'nativeTableId': table.id,
         'nativeTableHash': canonicalHashOf(table.toJson()).value,
         'nativeTable': table.toJson(),
         'tableBinding': tableBinding,
         'qualification': qualification.evidence,
         'nativeTrigger': 'afterRockSmash',
         'nativeReusePolicy': 'oncePerMapInstance',
         'nativeExecutionQualified': false,
         'pendingCatalogCompanion': true,
       });

  final int sourceMapId;
  final String nativeMapId, tableId, encodedEvidence;
  final Sha256Hash sourceSnapshotHash, normalizationHash;
  final NativeEncounterCatalogQualification qualification;

  bool isBoundTo({required NormalizedSourceProject source,
      required int sourceMapId, required String? nativeMapId}) =>
      source.snapshot.canonicalHash == sourceSnapshotHash &&
      source.canonicalHash == normalizationHash &&
      this.sourceMapId == sourceMapId && this.nativeMapId == nativeMapId &&
      qualification.admitsAutomaticSource(source.snapshot);

  Map<String, Object?> toJson() =>
      (jsonDecode(encodedEvidence) as Map).cast<String, Object?>();
}

final class _FieldObstacleWitnessFiles implements SourceFilePort {
  const _FieldObstacleWitnessFiles(this.source, this.readExact);
  final NormalizedSourceProject source;
  final Future<List<int>> Function(String path, {String? hash}) readExact;
  @override
  Future<List<int>> read(ConverterId fileId) => readExact(
      source.snapshot.entries.singleWhere((entry) => entry.fileId == fileId).relativePath);
}

(List<List<int>>, Map<String,int>) _fieldSettings(List<int> scripts) {
  final document = const MarshalDecoder().decode(scripts, sourcePath:'Data/Scripts.rxdata');
  final entries = document.node(document.rootId).elements;
  const hashes = {
    0:'cc412c0b86e5ebbc121a91ca5efc2d7d6c7b398469cb0c7cd5be1b770531b06f',
    33:'b2f4c542a1542a5908d1208b87eae05d8b6f6ec0d26df1835871595842ed0355',
    244:'059eda46398b762791c755e7a41fcb80a1e56fdbd951c3b74f1d676513084c4b',
    258:'1c407a629598616d211b50aea2b7561f17c90dbbd7c6175087fdaa60dc6650e6',
    362:'377ba5397ff74128812af4ef5089de7ae480f6ad7ff040adea91bb25b24671a4',
  };
  String? settings;
  for (final entry in hashes.entries) {
    if (entry.key >= entries.length) throw const SourceFieldObstacleBindingUnavailable('scripts_unqualified');
    final row = document.node(entries[entry.key]).elements;
    if (row.length != 3 || document.node(row[2]).bytes == null) {
      throw const SourceFieldObstacleBindingUnavailable('scripts_unqualified');
    }
    final bytes = const BoundedZlibDecoder().decode(document.node(row[2]).bytes!,
        limits:const ZlibDecodeLimits(maxInputBytes:1048576,maxOutputBytes:1048576,maxBlocks:10000),
        sourcePath:'Data/Scripts.rxdata:${entry.key}');
    if (crypto.sha256.convert(bytes).toString() != entry.value) {
      throw const SourceFieldObstacleBindingUnavailable('scripts_unqualified');
    }
    if (entry.key == 0) settings = utf8.decode(bytes);
  }
  final count = RegExp(r'^\s*FIELD_MOVES_COUNT_BADGES\s*=\s*(true|false)\s*$',multiLine:true).allMatches(settings!).toList();
  final matrix = RegExp(r'^\s*REGION_HM_ARRAY\s*=\s*(\[(?:[\s\d,\-\[\]])+\])',multiLine:true).allMatches(settings).toList();
  if (count.length != 1 || count.single.group(1) != 'false' || matrix.length != 1) {
    throw const SourceFieldObstacleBindingUnavailable('badge_settings_unqualified');
  }
  final raw = jsonDecode(matrix.single.group(1)!) as List;
  if (raw.length > 64 || raw.any((row) => row is! List || row.length > 64 || row.any((value) => value is! int))) {
    throw const SourceFieldObstacleBindingUnavailable('badge_settings_unqualified');
  }
  final columns = <String,int>{};
  for(final move in ['CUT','STRENGTH','ROCKSMASH']) {
    final matches = RegExp('^\\s*BADGE_FOR_$move\\s*=\\s*(-?\\d+)\\s*\$',multiLine:true).allMatches(settings).toList();
    if (matches.length != 1) throw const SourceFieldObstacleBindingUnavailable('badge_settings_unqualified');
    columns[move] = int.parse(matches.single.group(1)!);
  }
  return ([for(final row in raw) (row as List).cast<int>()], columns);
}

Map<int,int> _fieldMapRegions(String metadata) {
  final regions = <int,int>{};
  final sections = <int>{};
  int? current;
  for(final raw in const LineSplitter().convert(metadata)) {
    final line = raw.split('#').first.trim();
    if (line.isEmpty) continue;
    final section = RegExp(r'^\[(\d+)\]$').firstMatch(line);
    if (section != null) {
      current = int.parse(section.group(1)!);
      if (!sections.add(current)) throw const SourceFieldObstacleBindingUnavailable('metadata_duplicate_section');
      continue;
    }
    final position = RegExp(r'^MapPosition\s*=\s*(\d+)\s*,\s*\d+\s*,\s*\d+\s*$').firstMatch(line);
    if (position != null && current != null) {
      if (regions.containsKey(current)) throw const SourceFieldObstacleBindingUnavailable('metadata_duplicate_position');
      regions[current] = int.parse(position.group(1)!);
    } else if (line.startsWith('MapPosition')) {
      throw const SourceFieldObstacleBindingUnavailable('metadata_position_unqualified');
    }
  }
  return regions;
}

Set<int> _compiledRockSmashMaps(MarshalDocument document) {
  final root = document.node(document.rootId);
  if (root.kind != MarshalKind.hash || root.defaultValue != null ||
      root.extensions.isNotEmpty || root.userClass != null || root.instanceVariables.isNotEmpty) {
    throw const SourceFieldObstacleBindingUnavailable('encounter_compiled_unqualified');
  }
  final maps = <int>{};
  final identities = <String>{};
  for(final pair in root.pairs) {
    final node = document.node(pair.value);
    final fields = {for(final field in node.instanceVariables)
      document.node(field.key).name: field.value};
    if (node.className != 'GameData::Encounter' || node.extensions.isNotEmpty ||
        node.userClass != null || fields.length != node.instanceVariables.length ||
        !fields.keys.toSet().containsAll({'@id','@map','@version','@types','@step_chances'})) {
      throw const SourceFieldObstacleBindingUnavailable('encounter_compiled_unqualified');
    }
    final map = document.node(fields['@map']!).integerValue?.toInt();
    final version = document.node(fields['@version']!).integerValue?.toInt();
    final types = document.node(fields['@types']!);
    final chances = document.node(fields['@step_chances']!);
    if (map == null || map < 1 || version == null || version < 0 ||
        !identities.add('$map:$version') || types.kind != MarshalKind.hash ||
        chances.kind != MarshalKind.hash || types.defaultValue != null || chances.defaultValue != null ||
        types.extensions.isNotEmpty || types.userClass != null || types.instanceVariables.isNotEmpty ||
        chances.extensions.isNotEmpty || chances.userClass != null || chances.instanceVariables.isNotEmpty) {
      throw const SourceFieldObstacleBindingUnavailable('encounter_compiled_unqualified');
    }
    final key = document.node(pair.key);
    final id = document.node(fields['@id']!);
    if (key.kind != MarshalKind.symbol || id.kind != MarshalKind.symbol ||
        key.name != '${map}_$version' || id.name != key.name) {
      throw const SourceFieldObstacleBindingUnavailable('encounter_compiled_identity_unqualified');
    }
    for (final chance in chances.pairs) {
      final name = document.node(chance.key);
      if (name.kind != MarshalKind.symbol) {
        throw const SourceFieldObstacleBindingUnavailable('encounter_compiled_unqualified');
      }
      if (name.name == 'RockSmash') maps.add(map);
    }
    for(final type in types.pairs) {
      final name = document.node(type.key);
      final slots = document.node(type.value);
      if (name.kind != MarshalKind.symbol || slots.kind != MarshalKind.array) {
        throw const SourceFieldObstacleBindingUnavailable('encounter_compiled_unqualified');
      }
      if (name.name == 'RockSmash') maps.add(map);
    }
  }
  return maps;
}
