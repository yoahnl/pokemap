import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';
import 'source_static_door_program.dart';
import 'source_routed_door_program.dart';
import 'source_stair_program.dart';
import 'source_hole_native_program.dart';
import 'source_elevator_program.dart';
import 'native_mutation_batches.dart';

String _mapSourcePath(int id) =>
    'Data/Map${id.toString().padLeft(3, '0')}.rxdata';

final class SourceEventExecutionContext {
  SourceEventExecutionContext._({
    required this.sourceSnapshotHash,
    required this.normalizationHash,
    required this.sourceProfileHash,
    required this.baseDraftHash,
    required Map<int, String> mapIds,
    required Map<int, Sha256Hash> mapHashes,
    required List<String> refusals,
    required Map<String, Object?> proof,
    this.staticDoorIdentity,
    this.routedDoorIdentity,
    this.routedSourceMapId,
    this.stairIdentity,
    this.stairSourceMapId,
    this.stairTargetMapId,
    this.holeIdentity,
    this.elevatorIdentity,
    this.elevatorSourceMapId,
  })  : mapIds = Map.unmodifiable(mapIds),
        _mapHashes = Map.unmodifiable(mapHashes),
        refusals = List.unmodifiable(refusals),
        _proof = canonicalJsonOf(proof);

  final Sha256Hash sourceSnapshotHash;
  final Sha256Hash normalizationHash;
  final Sha256Hash sourceProfileHash;
  final Sha256Hash? baseDraftHash;
  final ConverterId? staticDoorIdentity,
      routedDoorIdentity,
      stairIdentity,
      holeIdentity,
      elevatorIdentity;
  final int? routedSourceMapId,
      stairSourceMapId,
      stairTargetMapId,
      elevatorSourceMapId;
  final Map<int, String> mapIds;
  final List<String> refusals;
  final Map<int, Sha256Hash> _mapHashes;
  final String _proof;

  bool get isQualified => refusals.isEmpty;

  bool supportsRouteBarrierOnSourceMap(int sourceMapId,
          {ConverterId? eventIdentity}) =>
      isQualified &&
      staticDoorIdentity == null &&
      holeIdentity == null &&
      (elevatorIdentity != null
          ? eventIdentity == elevatorIdentity &&
              sourceMapId == elevatorSourceMapId
          : stairIdentity != null
              ? eventIdentity == stairIdentity &&
                  {stairSourceMapId, stairTargetMapId}.contains(sourceMapId)
              : routedDoorIdentity != null
                  ? eventIdentity == routedDoorIdentity &&
                      sourceMapId == routedSourceMapId
                  : mapIds.containsKey(sourceMapId)) &&
      mapIds.containsKey(sourceMapId);

  bool isBoundTo(NormalizedSourceProject source, SourceEventProfile profile,
          Map<int, MapData> maps) =>
      source.snapshot.canonicalHash == sourceSnapshotHash &&
      source.canonicalHash == normalizationHash &&
      profile.canonicalHash == sourceProfileHash &&
      maps.length == mapIds.length &&
      mapIds.entries.every((entry) =>
          maps[entry.key]?.id == entry.value &&
          canonicalHashOf(jsonDecode(jsonEncode(maps[entry.key]!.toJson()))) ==
              _mapHashes[entry.key]);

  bool sharesNativeBindingWith(SourceEventExecutionContext other) =>
      sourceSnapshotHash == other.sourceSnapshotHash &&
      normalizationHash == other.normalizationHash &&
      sourceProfileHash == other.sourceProfileHash &&
      baseDraftHash == other.baseDraftHash &&
      mapIds.length == other.mapIds.length &&
      mapIds.entries.every((entry) =>
          other.mapIds[entry.key] == entry.value &&
          other._mapHashes[entry.key] == _mapHashes[entry.key]);

  Map<String, Object?> toJson() => {
        'kind': 'sourceEventExecutionContext',
        'version': 1,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'sourceProfileHash': sourceProfileHash.value,
        'baseDraftHash': baseDraftHash?.value,
        if (staticDoorIdentity != null)
          'staticDoorIdentity': staticDoorIdentity!.value,
        if (routedDoorIdentity != null)
          'routedDoorIdentity': routedDoorIdentity!.value,
        if (routedSourceMapId != null) 'routedSourceMapId': routedSourceMapId,
        if (holeIdentity != null) 'holeIdentity': holeIdentity!.value,
        if (stairIdentity != null) ...{
          'stairIdentity': stairIdentity!.value,
          'stairSourceMapId': stairSourceMapId,
          'stairTargetMapId': stairTargetMapId
        },
        if (elevatorIdentity != null) ...{
          'elevatorIdentity': elevatorIdentity!.value,
          'elevatorSourceMapId': elevatorSourceMapId
        },
        'mapIds': {
          for (final entry in mapIds.entries) '${entry.key}': entry.value
        },
        'mapHashes': {
          for (final entry in _mapHashes.entries)
            '${entry.key}': entry.value.value
        },
        'qualified': isQualified,
        'refusals': refusals,
        'proof': jsonDecode(_proof),
      };
}

final class SourceEventExecutionContextResolver {
  const SourceEventExecutionContextResolver();

  Future<SourceEventExecutionContext> read({
    required NormalizedSourceProject source,
    required NativeProjectDraft? base,
    required Map<int, MapData> nativeMaps,
    required SourceFilePort files,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
    SourceStaticDoorProgram? staticDoorProgram,
    SourceRoutedDoorProgram? routedDoorProgram,
    SourceStairProgram? stairProgram,
    SourceElevatorProgram? elevatorProgram,
    SourceEventAnalysis? staticDoorAnalysis,
  }) =>
      _read(
          source: source,
          base: base,
          nativeMaps: nativeMaps,
          files: files,
          limits: limits,
          cancellation: cancellation,
          staticDoorProgram: staticDoorProgram,
          routedDoorProgram: routedDoorProgram,
          stairProgram: stairProgram,
          elevatorProgram: elevatorProgram,
          staticDoorAnalysis: staticDoorAnalysis);

  Future<Map<ConverterId, SourceEventExecutionContext>> readStaticTransfers({
    required NormalizedSourceProject source,
    required NativeProjectDraft base,
    required Map<int, MapData> nativeMaps,
    required SourceFilePort files,
    required Map<ConverterId, SourceStaticDoorProgram> programs,
    required SourceEventAnalysis analysis,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) =>
      readTransfers(
          source: source,
          base: base,
          nativeMaps: nativeMaps,
          files: files,
          programs: programs,
          analysis: analysis,
          limits: limits,
          cancellation: cancellation);

  Future<Map<ConverterId, SourceEventExecutionContext>> readRoutedTransfers({
    required NormalizedSourceProject source,
    required NativeProjectDraft base,
    required Map<int, MapData> nativeMaps,
    required SourceFilePort files,
    required Map<ConverterId, SourceRoutedDoorProgram> programs,
    required SourceEventAnalysis analysis,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) =>
      readTransfers(
          source: source,
          base: base,
          nativeMaps: nativeMaps,
          files: files,
          programs: const {},
          routedPrograms: programs,
          analysis: analysis,
          limits: limits,
          cancellation: cancellation);

  Future<Map<ConverterId, SourceEventExecutionContext>> readTransfers({
    required NormalizedSourceProject source,
    required NativeProjectDraft base,
    required Map<int, MapData> nativeMaps,
    required SourceFilePort files,
    required Map<ConverterId, SourceStaticDoorProgram> programs,
    Map<ConverterId, SourceRoutedDoorProgram> routedPrograms = const {},
    Map<ConverterId, SourceStairProgram> stairPrograms = const {},
    Map<ConverterId, SourceHoleNativeProgram> holePrograms = const {},
    Map<ConverterId, SourceElevatorProgram> elevatorPrograms = const {},
    required SourceEventAnalysis analysis,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    cancellation?.check();
    if (programs.isEmpty &&
        routedPrograms.isEmpty &&
        stairPrograms.isEmpty &&
        holePrograms.isEmpty &&
        elevatorPrograms.isEmpty) {
      return const {};
    }
    base.validateResourceBudget(limits: limits);
    final hashes = Map<int, Sha256Hash>.unmodifiable({
      for (final entry in nativeMaps.entries)
        entry.key:
            canonicalHashOf(jsonDecode(jsonEncode(entry.value.toJson()))),
    });
    final composition = base.compositionEvidence['composition'];
    final compositionHash = composition is Map
        ? canonicalHashOf(composition, limits: limits.jsonLimits)
        : null;
    final baseMutations = expandNativeMutationBatches(base, limits).toList();
    final authoritativeSourceAnalysis = SourceEventAnalyzer.forProject(source,
            profile: SourceEventProfile.forProject(source))
        .analyze();
    final parallelDormancyAuditor = SourceParallelDormancyAuditor.forProject(
        source, profile: authoritativeSourceAnalysis.profile);
    final result = <ConverterId, SourceEventExecutionContext>{};
    final witnesses = <String, Map<String, Object?>>{};
    final retained = <String, Future<NormalizedSourceProject>>{};
    final retainedAnalyses = <String, SourceEventAnalysis>{};
    for (final identity in {
      ...programs.keys,
      ...routedPrograms.keys,
      ...stairPrograms.keys,
      ...holePrograms.keys,
      ...elevatorPrograms.keys
    }) {
      final staticProgram = programs[identity];
      final routedProgram = routedPrograms[identity];
      final stair = stairPrograms[identity];
      final hole = holePrograms[identity];
      final elevator = elevatorPrograms[identity];
      cancellation?.check();
      if ((staticProgram != null && staticProgram.eventIdentity != identity) ||
          (routedProgram != null && routedProgram.eventIdentity != identity) ||
          (stair != null && stair.eventIdentity != identity) ||
          (hole != null && hole.eventIdentity != identity) ||
          (elevator != null && elevator.eventIdentity != identity) ||
          [staticProgram, routedProgram, stair, hole, elevator]
                  .where((program) => program != null)
                  .length !=
              1) {
        throw const NativeWriteException('events.source.binding',
            'Static transfer context keys require exact source identities');
      }
      result[identity] = await _read(
          source: source,
          base: base,
          nativeMaps: nativeMaps,
          files: files,
          limits: limits,
          cancellation: cancellation,
          staticDoorProgram: staticProgram,
          routedDoorProgram: routedProgram,
          stairProgram: stair,
          holeProgram: hole,
          elevatorProgram: elevator,
          staticDoorAnalysis: staticProgram == null ? null : analysis,
          authoritativeSourceAnalysis: authoritativeSourceAnalysis,
          parallelDormancyAuditor: parallelDormancyAuditor,
          nativeMapHashes: hashes,
          baseCompositionHash: compositionHash,
          baseMutations: baseMutations,
          witnessCache: witnesses,
          retainedCache: retained,
          retainedAnalysisCache: retainedAnalyses);
    }
    return Map.unmodifiable(result);
  }

  Future<SourceEventExecutionContext> _read({
    required NormalizedSourceProject source,
    required NativeProjectDraft? base,
    required Map<int, MapData> nativeMaps,
    required SourceFilePort files,
    required NativeWriteLimits limits,
    ScanCancellation? cancellation,
    SourceStaticDoorProgram? staticDoorProgram,
    SourceRoutedDoorProgram? routedDoorProgram,
    SourceStairProgram? stairProgram,
    SourceElevatorProgram? elevatorProgram,
    SourceEventAnalysis? staticDoorAnalysis,
    SourceHoleNativeProgram? holeProgram,
    SourceEventAnalysis? authoritativeSourceAnalysis,
    SourceParallelDormancyAuditor? parallelDormancyAuditor,
    Map<int, Sha256Hash>? nativeMapHashes,
    Sha256Hash? baseCompositionHash,
    List<NativeMutation>? baseMutations,
    Map<String, Map<String, Object?>>? witnessCache,
    Map<String, Future<NormalizedSourceProject>>? retainedCache,
    Map<String, SourceEventAnalysis>? retainedAnalysisCache,
  }) async {
    cancellation?.check();
    final profile = SourceEventProfile.forProject(source);
    final refusals = <String>{};
    final proof = <String, Object?>{};
    final snapshotHash = source.snapshot.canonicalHash;
    final normalizationHash = source.canonicalHash;
    final staticTransfer = staticDoorProgram != null;
    final localTransfer = staticTransfer ||
        routedDoorProgram != null ||
        stairProgram != null ||
        holeProgram != null ||
        elevatorProgram != null;
    SourceEventAnalysis? freshAnalysis = authoritativeSourceAnalysis;
    final sourceMapId = staticDoorProgram?.sourceMapId ??
        routedDoorProgram?.sourceMapId ??
        stairProgram?.sourceMapId ??
        holeProgram?.sourceMapId ??
        elevatorProgram?.sourceMapId;
    final targetMapId = staticDoorProgram?.targetSourceMapId ??
        routedDoorProgram?.targetSourceMapId ??
        stairProgram?.targetSourceMapId ??
        holeProgram?.warp.targetSourceMapId ??
        elevatorProgram?.targetSourceMapId;
    if (routedDoorProgram != null) {
      final authoritative = freshAnalysis ??=
          SourceEventAnalyzer.forProject(source, profile: profile).analyze();
      final event = authoritative.events
          .where((event) => event.identity == routedDoorProgram.eventIdentity)
          .singleOrNull;
      if (staticTransfer ||
          event == null ||
          !routedDoorProgram.isBoundTo(
              source: source, analysis: authoritative, event: event)) {
        refusals.add('sourceRoutedDoorProgramBindingInvalid');
      }
      if (nativeMaps.values.any((map) =>
          map.triggers.isNotEmpty ||
          map.entities.any((entity) =>
              entity.npc != null ||
              entity.properties.containsKey('sourceEventIdentity')))) {
        refusals.add('sourceForcedRouteActorSetUnsupported');
      }
    }
    if (stairProgram != null) {
      final authoritative = freshAnalysis ??=
          SourceEventAnalyzer.forProject(source, profile: profile).analyze();
      final event = authoritative.events
          .where((event) => event.identity == stairProgram.eventIdentity)
          .singleOrNull;
      if (staticTransfer ||
          routedDoorProgram != null ||
          event == null ||
          !stairProgram.isBoundTo(
              source: source, analysis: authoritative, event: event)) {
        refusals.add('sourceStairProgramBindingInvalid');
      }
      if (nativeMaps.values.any((map) =>
          map.triggers.isNotEmpty ||
          map.entities.any((entity) =>
              entity.npc != null ||
              entity.properties.containsKey('sourceEventIdentity')))) {
        refusals.add('sourceForcedRouteActorSetUnsupported');
      }
    }
    if (holeProgram != null) {
      final authoritative = freshAnalysis ??=
          SourceEventAnalyzer.forProject(source, profile: profile).analyze();
      final event = authoritative.events
          .where((event) => event.identity == holeProgram.eventIdentity)
          .singleOrNull;
      if (staticTransfer ||
          routedDoorProgram != null ||
          stairProgram != null ||
          event == null ||
          !holeProgram.isBoundTo(
              source: source, analysis: authoritative, event: event)) {
        refusals.add('sourceHoleProgramBindingInvalid');
      }
      if (nativeMaps.values.any((map) =>
          map.triggers.isNotEmpty ||
          map.entities.any((entity) =>
              entity.npc != null ||
              entity.properties.containsKey('sourceEventIdentity')))) {
        refusals.add('sourceHoleActorSetUnsupported');
      }
    }
    if (elevatorProgram != null) {
      final authoritative = freshAnalysis ??=
          SourceEventAnalyzer.forProject(source, profile: profile).analyze();
      final event = authoritative.events
          .where((event) => event.identity == elevatorProgram.eventIdentity)
          .singleOrNull;
      if (staticTransfer ||
          routedDoorProgram != null ||
          stairProgram != null ||
          event == null ||
          !elevatorProgram.isBoundTo(
              source: source, analysis: authoritative, event: event) ||
          !nativeMaps.keys
              .toSet()
              .containsAll(elevatorProgram.requiredSourceMapIds)) {
        refusals.add('sourceElevatorProgramBindingInvalid');
      }
      if (nativeMaps.values.any((map) =>
          map.triggers.isNotEmpty ||
          map.entities.any((entity) =>
              entity.npc != null ||
              entity.properties.containsKey('sourceEventIdentity')))) {
        refusals.add('sourceForcedRouteActorSetUnsupported');
      }
    }
    if (staticDoorAnalysis != null &&
        (staticDoorAnalysis.profile.canonicalHash != profile.canonicalHash ||
            staticDoorProgram == null ||
            staticDoorAnalysis.events
                    .where((event) =>
                        event.identity == staticDoorProgram.eventIdentity)
                    .length !=
                1 ||
            !staticDoorProgram.isBoundTo(
                source: source,
                analysis: staticDoorAnalysis,
                event: staticDoorAnalysis.events.singleWhere((event) =>
                    event.identity == staticDoorProgram.eventIdentity)))) {
      refusals.add('sourceStaticDoorProgramBindingInvalid');
    }
    if (staticDoorProgram != null &&
        (staticDoorProgram.sourceSnapshotHash != snapshotHash ||
            staticDoorProgram.normalizationHash != normalizationHash ||
            staticDoorProgram.profileHash != profile.canonicalHash)) {
      refusals.add('sourceStaticDoorProgramBindingInvalid');
    }
    final pluginInventory = {
      'entries': [
        for (final entry in source.snapshot.entries
            .where((entry) => _isPluginPath(entry.relativePath)))
          {
            'relativePath': entry.relativePath,
            'kind': entry.kind.name,
            'byteLength': entry.byteLength,
            'sha256': entry.sha256?.value,
          }
      ],
      'excludedPaths':
          source.snapshot.excludedPaths.where(_isPluginPath).toList(),
    };
    final pluginInventoryHash = canonicalHashOf(pluginInventory);
    final customPluginPolicy = source.interpretationProfile?.customPluginPolicy ??
        SourceCustomPluginPolicy.requireAbsent;
    final excludesCustomBehavior =
        customPluginPolicy == SourceCustomPluginPolicy.excludeCustomBehavior;
    if (source.snapshot.excludedPaths.any((path) {
      final excluded = sourcePathCollisionKey(path);
      return ['Data/PluginScripts.rxdata', 'Data/CommonEvents.rxdata']
          .any((witness) {
        final key = sourcePathCollisionKey(witness);
        return key == excluded || key.startsWith('$excluded/');
      });
    })) {
      refusals.add('sourceExecutionWitnessUnavailable');
    }
    if (source.snapshot.entries.any((entry) =>
            _isPluginPath(entry.relativePath) &&
            entry.kind != SourceNodeKind.directory &&
            !(excludesCustomBehavior && entry.kind == SourceNodeKind.file &&
                entry.sha256 != null)) ||
        source.snapshot.excludedPaths.any(_isPluginPath)) {
      refusals.add('sourcePluginInventoryUnsupported');
    }
    if (base == null) {
      refusals.add('sourceExecutionContextUnknown');
    } else {
      if (nativeMapHashes == null) base.validateResourceBudget(limits: limits);
      final semanticMutations =
          baseMutations ?? expandNativeMutationBatches(base, limits).toList();
      if (base.source.canonicalHash != normalizationHash ||
          canonicalJsonOf({
                for (final entry in nativeMaps.entries)
                  '${entry.key}': entry.value.id
              }) !=
              canonicalJsonOf({
                for (final entry in base.mapIds.entries)
                  '${entry.key}': entry.value
              })) {
        refusals.add('sourceExecutionBaseBindingInvalid');
      }
      final composition = base.compositionEvidence['composition'];
      if (base.compositionEvidence.keys.any((key) =>
              const {'kind', 'version', 'compositionHash'}.contains(key)) &&
          (base.compositionEvidence['kind'] != 'literalTileComposition' ||
              base.compositionEvidence['version'] != 2 ||
              composition is! Map ||
              base.compositionEvidence['compositionHash'] !=
                  (baseCompositionHash ??
                          canonicalHashOf(composition,
                              limits: limits.jsonLimits))
                      .value)) {
        refusals.add('sourceExecutionBaseUnsupported');
      }
      if (base.compositionEvidence.containsKey('sourceCheckpoint') ||
          semanticMutations.any((entry) =>
              entry.actionId.startsWith('game_save.') ||
              entry.actionId.startsWith('checkpoint.'))) {
        refusals.add('sourceCheckpointImportUnsupported');
      }
      if (base.compositionEvidence.keys.any((key) => !const {
                'composition',
                'kind',
                'version',
                'compositionHash',
                'sourceSemantics',
                'sourceCheckpoint'
              }.contains(key)) ||
          semanticMutations.any((entry) => !const {
                'tileset.import_image',
                'tileset.upsert',
                'map.create',
                'map.save',
                'connection.create_bidirectional_apply',
                'border.blueprint.draft.upsert',
                'border.blueprint.publish',
                'border_layer.feature_create',
                'border_layer.feature_set_replacement',
                'border_layer.materialize_apply',
                'element_category.upsert',
                'element.upsert',
                'characterStudio.character.create',
                'characterStudio.character.update',
                'characterStudio.animationClip.upsert',
                'characterStudio.character.setDefault',
              }.contains(entry.actionId))) {
        refusals.add('sourceExecutionBaseUnsupported');
      }
    }
    if (!profile.isQualified ||
        !source.canPlan ||
        source.snapshot.state != SourceScanState.complete) {
      refusals.add('sourceExecutionProfileUnqualified');
    }
    if (nativeMaps.isEmpty ||
        (localTransfer &&
            !nativeMaps.keys.toSet().containsAll({sourceMapId, targetMapId})) ||
        (localTransfer &&
            nativeMaps.values.any((map) => map.version == ProjectVersion.v9)) ||
        nativeMaps.values
            .any((map) => map.spatialScene != null || map.events.isNotEmpty)) {
      refusals.add('sourceExecutionMapsUnavailable');
    }
    if (nativeMaps.values.any((map) =>
        map.triggers.isNotEmpty ||
        map.entities.any((entity) =>
            entity.npc != null ||
            entity.properties.containsKey('sourceEventIdentity')))) {
      refusals.add('sourceForcedRouteActorSetUnsupported');
    }
    final representedMapIds =
        source.maps.map((map) => map.map.sourceMapId).toSet();
    final activeMapIds = elevatorProgram?.requiredSourceMapIds ??
        (localTransfer ? {sourceMapId!, targetMapId!} : representedMapIds);
    if (canonicalJsonOf(representedMapIds.toList()..sort()) !=
        canonicalJsonOf(nativeMaps.keys.toList()..sort())) {
      refusals.add('sourceExecutionMapsUnavailable');
    }
    final retainedMapIds = <int>{
      for (final connection in source.connections) ...[
        if (activeMapIds.contains(connection.sourceMapId))
          connection.targetSourceMapId,
        if (activeMapIds.contains(connection.targetSourceMapId))
          connection.sourceMapId,
      ]
    }..removeAll(activeMapIds);
    final attestedMapIds = {...activeMapIds, ...retainedMapIds};
    if (!source.connectionsExtracted) {
      refusals.add('sourceExecutionConnectionsUnavailable');
    }
    final connectionsEntry = source.snapshot.entries
        .where((entry) => entry.relativePath == 'Data/map_connections.dat')
        .firstOrNull;
    final witnesses = <Map<String, Object?>>[];
    for (final expected in {
      'Data/Scripts.rxdata':
          source.interpretationProfile?.scriptsArchiveHash.value,
      for (final path in [
        'Data/PluginScripts.rxdata',
        'Data/CommonEvents.rxdata'
      ])
        if (source.snapshot.entries.any((entry) =>
            sourcePathCollisionKey(entry.relativePath) ==
            sourcePathCollisionKey(path)))
          path: source.snapshot.entries
                  .where((entry) => entry.relativePath == path)
                  .firstOrNull
                  ?.sha256
                  ?.value ??
              '',
      'Data/map_connections.dat': connectionsEntry?.sha256?.value ?? '',
      for (final id in attestedMapIds.toList()..sort())
        _mapSourcePath(id): source.snapshot.entries
                .where((entry) => entry.relativePath == _mapSourcePath(id))
                .firstOrNull
                ?.sha256
                ?.value ??
            '',
    }.entries) {
      cancellation?.check();
      final matches = source.snapshot.entries
          .where((entry) =>
              sourcePathCollisionKey(entry.relativePath) ==
              sourcePathCollisionKey(expected.key))
          .toList();
      if (matches.length != 1 ||
          matches.single.relativePath != expected.key ||
          matches.single.kind != SourceNodeKind.file ||
          matches.single.sha256 == null) {
        refusals.add('sourceExecutionWitnessUnavailable');
        continue;
      }
      final entry = matches.single;
      if (entry.sha256!.value != expected.value) {
        refusals.add(expected.key == 'Data/PluginScripts.rxdata'
            ? 'sourcePluginRouteContextUnsupported'
            : 'sourceExecutionWitnessUnqualified');
      }
      final cached = witnessCache?[entry.relativePath];
      if (cached?['automaticCommonEventsManual'] == false) {
        refusals.add('sourceAutomaticCommonEventUnsupported');
      }
      if (!excludesCustomBehavior && cached?['pluginArchiveEmpty'] == false) {
        refusals.add('sourcePluginRouteContextUnsupported');
      }
      bool? manualCommonEvents;
      bool? pluginArchiveEmpty;
      if (cached == null) {
        final bytes = await files.read(entry.fileId);
        cancellation?.check();
        if (bytes.length != entry.byteLength ||
            crypto.sha256.convert(bytes).toString() != entry.sha256!.value) {
          throw const NativeWriteException('events.execution.witness.changed',
              'Execution context witnesses differ from the sealed source snapshot');
        }
        if (expected.key == 'Data/CommonEvents.rxdata') {
          manualCommonEvents = _commonEventsAreManual(bytes);
          if (!manualCommonEvents) {
            refusals.add('sourceAutomaticCommonEventUnsupported');
          }
        }
        if (expected.key == 'Data/PluginScripts.rxdata') {
          pluginArchiveEmpty = _emptyPluginArchive(bytes);
          if (!excludesCustomBehavior && !pluginArchiveEmpty) {
            refusals.add('sourcePluginRouteContextUnsupported');
          }
        }
      }
      final witness = <String, Object?>{
        'fileId': entry.fileId.value,
        'relativePath': entry.relativePath,
        'byteLength': entry.byteLength,
        'sha256': entry.sha256!.value,
        if (pluginArchiveEmpty != null ||
            cached?.containsKey('pluginArchiveEmpty') == true)
          'pluginArchiveEmpty':
              pluginArchiveEmpty ?? cached!['pluginArchiveEmpty'],
        if (manualCommonEvents != null ||
            cached?.containsKey('automaticCommonEventsManual') == true)
          'automaticCommonEventsManual':
              manualCommonEvents ?? cached!['automaticCommonEventsManual'],
      };
      witnessCache?[entry.relativePath] = witness;
      witnesses.add(witness);
    }
    NormalizedSourceProject? retainedSource;
    final unrepresentedRetainedMapIds =
        retainedMapIds.difference(representedMapIds);
    if (unrepresentedRetainedMapIds.isNotEmpty &&
        unrepresentedRetainedMapIds.every((id) => witnesses
            .any((entry) => entry['relativePath'] == _mapSourcePath(id)))) {
      final cacheKey = (unrepresentedRetainedMapIds.toList()..sort()).join(',');
      final pending = retainedCache?[cacheKey] ??
          const RmxpSourceNormalizer().normalize(
              snapshot: source.snapshot,
              files: files,
              selectedMapIds: unrepresentedRetainedMapIds,
              includeEventSystem: true,
              interpretationProfile: source.interpretationProfile,
              cancellation: cancellation);
      retainedCache?[cacheKey] = pending;
      retainedSource = await pending;
      if (!retainedSource.canPlan ||
          canonicalJsonOf(
                  retainedSource.maps.map((map) => map.map.sourceMapId).toList()
                    ..sort()) !=
              canonicalJsonOf(unrepresentedRetainedMapIds.toList()..sort())) {
        refusals.add('sourceRetainedMapContextUnsupported');
      }
    } else if (unrepresentedRetainedMapIds.isNotEmpty) {
      refusals.add('sourceRetainedMapContextUnsupported');
    }
    final dormancyScope = attestedMapIds.intersection(representedMapIds);
    final dormancy = (parallelDormancyAuditor ??
        SourceParallelDormancyAuditor.forProject(source, profile: profile))
        .audit(activeSourceMapIds: dormancyScope);
    if (dormancy.sourceSnapshotHash != snapshotHash ||
        dormancy.normalizationHash != normalizationHash ||
        dormancy.profileHash != profile.canonicalHash ||
        dormancy.activeSourceMapIds.length != dormancyScope.length ||
        !dormancy.activeSourceMapIds.containsAll(dormancyScope) ||
        !dormancy.isQualified) {
      refusals.add('sourceParallelDormancyUnqualified');
    }
    final pages = [
      for (final map in [...source.maps, ...?retainedSource?.maps]
          .where((map) => attestedMapIds.contains(map.map.sourceMapId)))
        for (final event in map.map.events)
          for (final page in event.pages)
            (map.map.sourceMapId, event.sourceEventId, page),
    ];
    if (pages.any((entry) =>
        entry.$3.triggerCode == 4 &&
        dormancy.permitsDormantParallelPage(entry.$1, entry.$2, entry.$3) !=
            true)) {
      refusals.add('sourceParallelEventUnsupported');
    }
    if (pages
        .any((entry) => entry.$3.triggerCode < 0 || entry.$3.triggerCode > 4)) {
      refusals.add('sourceMapAutonomyContextUnsupported');
    }
    final autonomy = <Map<String, Object?>>[];
    {
      for (final project in [
        source,
        if (retainedSource != null) retainedSource
      ]) {
        final cacheKey =
            (project.selectedSourceMapIds.toList()..sort()).join(',');
        final SourceEventAnalysis analysis;
        if (identical(project, source)) {
          analysis = freshAnalysis ??= SourceEventAnalyzer.forProject(project,
                  profile: SourceEventProfile.forProject(project))
              .analyze();
        } else {
          analysis = retainedAnalysisCache?[cacheKey] ??
              SourceEventAnalyzer.forProject(project,
                      profile: SourceEventProfile.forProject(project))
                  .analyze();
          retainedAnalysisCache?[cacheKey] = analysis;
        }
        for (final event in analysis.events
            .where((event) => attestedMapIds.contains(event.sourceMapId))) {
          for (final page in event.pages) {
            final graphic = page.graphic;
            final archive = project.sourceFiles[event.sourceFileId];
            if (graphic == null ||
                archive == null ||
                (!_staticAutonomySafe(archive.document, graphic) &&
                    elevatorProgram?.permitsDormantStoredRoute(
                            project, event, page) !=
                        true)) {
              refusals.add('sourceMapAutonomyContextUnsupported');
            }
            autonomy.add({
              'mapId': event.sourceMapId,
              'eventId': event.sourceEventId,
              'pageIndex': page.originalPageIndex,
              'moveType': graphic?.moveType,
              'rawPage': page.rawDataRef?.toJson()
            });
          }
        }
      }
    }
    if (refusals.isEmpty) {
      proof.addAll({
        'origin': 'freshNativeProject',
        'nativeCreationContract': {
          'template': 'empty',
          'dimension': 'twoD',
          'stateImports': 'notSupported'
        },
        'sourceCheckpoint': 'notImported',
        'followers': 'newGameDeclaredEmpty',
        'scope': {
          'sourceMapIds': activeMapIds.toList()..sort(),
          'pages': holeProgram != null
              ? ['${holeProgram.sourceMapId}/${holeProgram.sourceEventId}/all']
              : elevatorProgram != null
                  ? elevatorProgram.requiredEventIdentities
                      .map((id) => id.value)
                      .toList()
                  : stairProgram != null
                      ? [
                          '${stairProgram.sourceMapId}/${stairProgram.sourceEventId}/all'
                        ]
                      : routedDoorProgram != null
                          ? [
                              '${routedDoorProgram.sourceMapId}/${routedDoorProgram.sourceEventId}/all'
                            ]
                          : staticDoorProgram == null
                              ? ['allRepresentedSourceEvents']
                              : [
                                  '${staticDoorProgram.sourceMapId}/${staticDoorProgram.sourceEventId}/0'
                                ]
        },
        if (routedDoorProgram != null || stairProgram != null)
          'forcedRouteActorClosure': {
            'programIdentity': (routedDoorProgram?.eventIdentity ??
                    stairProgram!.eventIdentity)
                .value,
            'sourceMapId': sourceMapId,
            'player': 'freshNativePlayerWithoutFollowers',
            'eventAnchorId': 'ac13_${canonicalHashOf({
                  'namespace': source.snapshot.logicalProjectNamespace.value,
                  'mapId': sourceMapId,
                  'eventId': routedDoorProgram?.sourceEventId ??
                      stairProgram!.sourceEventId,
                  'role': 'anchor'
                }).value.substring(0, 24)}',
            'baseForcedActors': [],
            'baseAutomaticEvents': [],
            'barrierScope': 'allForcedNativeRoutesOnExactActiveMap',
            'routeProducers': stairProgram == null
                ? 'onlyBoundCompleteProgramsWithBarrierAfterEveryRoute'
                : 'boundStairMotionWithBarrierAndExactPostTransferFlagRestore',
            if (stairProgram != null) 'stairProgram': stairProgram.toJson(),
            'retainedMaps': 'noParallelOrScriptedAutonomousRouteProducers',
            'temporaryStateLifetime':
                'nativeMapEventInstanceResetAndRetainedInstancePreservation',
          },
        if (holeProgram != null) 'nativeHolePresentation': holeProgram.toJson(),
        if (elevatorProgram != null) ...{
          'elevatorProgram': elevatorProgram.toJson(),
          'elevatorForcedRouteActorClosure': {
            'sourceMapId': elevatorProgram.sourceMapId,
            'allowedEventActors': elevatorProgram.sourceActorIds.toList()
              ..sort(),
            'scope': 'completeDeclaredElevatorFamily',
            'storedStationaryRoutes': 'dormantUnlessExplicitlyForced',
            'storedRouteOracle': '044:918-931',
            'sourceGlobalBarrierOracle': '033:106-114'
          }
        },
        'sourceContextProfile': holeProgram != null
            ? 'declared-hole-native-local-fresh-v1'
            : elevatorProgram != null
                ? 'declared-complete-elevator-family-native-v1'
                : stairProgram != null
                    ? 'declared-stair-local-fresh-v1'
                    : routedDoorProgram != null
                        ? 'declared-routed-door-local-fresh-v1'
                        : staticTransfer
                            ? 'declared-static-transfer-fresh-v1'
                            : 'declared-original-door-fresh-v1',
        'sourcePluginContext': excludesCustomBehavior
            ? 'explicitCustomBehaviorExcluded'
            : 'freshEmptyPluginArchiveAndNoPluginFiles',
        'customPluginPolicy': customPluginPolicy.name,
        if (excludesCustomBehavior) 'excludedCustomBehavior': {
          'pluginInventory': pluginInventory,
          'compiledArchive': 'sealedSourceWitnessWhenPresent',
          'sourceScriptsExecuted': 0,
          'pluginBehaviorImported': false,
          'pluginParityQualified': false,
        },
        'pluginInventoryHash': pluginInventoryHash.value,
        'commonEvents': 'manualOnly',
        'parallelEvents': 'wholeEventQuarantinedWithClosedNativeWriterSet',
        'parallelDormancy': dormancy.toJson(),
        'sourceMapExecutionScope': {
          'activeSourceMapIds': activeMapIds.toList()..sort(),
          'retainedOnlySourceMapIds': retainedMapIds.toList()..sort(),
          'attestedSourceMapIds': attestedMapIds.toList()..sort(),
          'retention': 'directNeighboursOfActiveMapsFromFreshSourceHistory',
        },
        'mapAutonomyAudit': {
          'profile': 'declared-fresh-local-autonomy-v1',
          'pages': autonomy,
          'automaticCommonEvents': 'refused',
          'parallelEvents': 'refusedUnlessClosedDormancyProof',
          'customRouteCodes': [0, 1, 2, 3, 4, 16, 17, 18, 19, 24],
          'customRouteScripts': 'refused',
          'autoruns': 'serialMainInterpreterCannotOverlapExecutingProgram',
          'globalRouteBarrier': routedDoorProgram == null &&
                  stairProgram == null &&
                  elevatorProgram == null
              ? 'freshNativeActorClosureAvailableForBoundFinitePrograms'
              : 'exactProgramLocalNativeActorClosure',
          'ambientMovementParityQualified': false,
        },
        'witnesses': witnesses,
        'oracle': {
          'freshState': '027:76-80;031:39-57',
          'followers': '049:55-57,79-83',
          'barrier': '033:106-114',
          'followingTransfer': 'FollowingPokemonEX/MapTransfer:4-9,29-44,50-78',
          'mapActivation': '033:54-72;043:114-139,361-375;045:129-130,170-179'
        },
      });
    }
    return SourceEventExecutionContext._(
        sourceSnapshotHash: snapshotHash,
        normalizationHash: normalizationHash,
        sourceProfileHash: profile.canonicalHash,
        baseDraftHash: base?.canonicalHash,
        holeIdentity: holeProgram?.eventIdentity,
        staticDoorIdentity: staticDoorProgram?.eventIdentity,
        routedDoorIdentity: routedDoorProgram?.eventIdentity,
        routedSourceMapId: routedDoorProgram?.sourceMapId,
        elevatorIdentity: elevatorProgram?.eventIdentity,
        elevatorSourceMapId: elevatorProgram?.sourceMapId,
        stairIdentity: stairProgram?.eventIdentity,
        stairSourceMapId: stairProgram?.sourceMapId,
        stairTargetMapId: stairProgram?.targetSourceMapId,
        mapIds: {
          for (final entry in nativeMaps.entries) entry.key: entry.value.id
        },
        mapHashes: nativeMapHashes ??
            {
              for (final entry in nativeMaps.entries)
                entry.key: canonicalHashOf(
                    jsonDecode(jsonEncode(entry.value.toJson())))
            },
        refusals: refusals.toList()..sort(),
        proof: proof);
  }
}

bool _staticAutonomySafe(MarshalDocument document, SourceEventGraphic graphic) {
  if (!const {0, 1, 2, 3}.contains(graphic.moveType)) {
    return false;
  }
  try {
    bool plain(int id, MarshalKind kind) {
      final node = document.node(id);
      return node.kind == kind &&
          node.extensions.isEmpty &&
          node.userClass == null &&
          node.instanceVariables.isEmpty &&
          node.encoding == null;
    }

    Map<String, int>? fields(int id, String name, Set<String> names) {
      final node = document.node(id);
      if (node.kind != MarshalKind.object ||
          node.className != name ||
          node.extensions.isNotEmpty ||
          node.userClass != null ||
          node.instanceVariables.length != names.length) {
        return null;
      }
      final result = <String, int>{};
      for (final field in node.instanceVariables) {
        final key = document.node(field.key);
        if (!plain(field.key, MarshalKind.symbol) ||
            !names.contains(key.name) ||
            result.containsKey(key.name)) {
          return null;
        }
        result[key.name!] = field.value;
      }
      return result;
    }

    final route = fields(graphic.moveRouteNodeId, 'RPG::MoveRoute',
        const {'@repeat', '@skippable', '@list'});
    if (route == null ||
        !plain(route['@repeat']!, MarshalKind.boolean) ||
        !plain(route['@skippable']!, MarshalKind.boolean)) {
      return false;
    }
    final list = document.node(route['@list']!);
    if (list.kind != MarshalKind.array ||
        list.extensions.isNotEmpty ||
        list.userClass != null ||
        list.instanceVariables.isNotEmpty ||
        list.elements.isEmpty) {
      return false;
    }
    final codes = <int>[];
    for (final id in list.elements) {
      final step =
          fields(id, 'RPG::MoveCommand', const {'@code', '@parameters'});
      if (step == null) {
        return false;
      }
      final code = document.node(step['@code']!);
      final parameters = document.node(step['@parameters']!);
      if (!plain(step['@code']!, MarshalKind.integer) ||
          parameters.kind != MarshalKind.array ||
          parameters.elements.isNotEmpty ||
          parameters.extensions.isNotEmpty ||
          parameters.userClass != null ||
          parameters.instanceVariables.isNotEmpty) {
        return false;
      }
      final value = code.integerValue?.toInt();
      if (!const {0, 1, 2, 3, 4, 16, 17, 18, 19, 24}.contains(value)) {
        return false;
      }
      codes.add(value!);
    }
    return codes.last == 0 && !codes.take(codes.length - 1).contains(0);
  } on BinaryDecodeError {
    return false;
  } on RangeError {
    return false;
  }
}

bool _isPluginPath(String path) {
  final key = sourcePathCollisionKey(path);
  return key == 'plugins' || key.startsWith('plugins/');
}

bool _commonEventsAreManual(List<int> bytes) {
  try {
    final document = const MarshalDecoder()
        .decode(bytes, sourcePath: 'Data/CommonEvents.rxdata');
    final root = document.node(document.rootId);
    if (root.kind != MarshalKind.array ||
        root.extensions.isNotEmpty ||
        root.userClass != null ||
        root.instanceVariables.isNotEmpty) {
      return false;
    }
    return root.elements.every((id) {
      final record = document.node(id);
      if (record.kind == MarshalKind.nil) {
        return true;
      }
      if (record.kind != MarshalKind.object ||
          record.className != 'RPG::CommonEvent' ||
          record.extensions.isNotEmpty ||
          record.userClass != null) {
        return false;
      }
      final triggers = record.instanceVariables
          .where((pair) => document.node(pair.key).name == '@trigger')
          .toList();
      return triggers.length == 1 &&
          document.node(triggers.single.value).kind == MarshalKind.integer &&
          document.node(triggers.single.value).integerValue == BigInt.zero;
    });
  } on BinaryDecodeError {
    return false;
  }
}

bool _emptyPluginArchive(List<int> bytes) {
  try {
    final document = const MarshalDecoder()
        .decode(bytes, sourcePath: 'Data/PluginScripts.rxdata');
    final root = document.node(document.rootId);
    return root.kind == MarshalKind.array &&
        root.elements.isEmpty &&
        root.extensions.isEmpty &&
        root.userClass == null &&
        root.instanceVariables.isEmpty;
  } on BinaryDecodeError {
    return false;
  }
}
