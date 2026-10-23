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
import 'source_encounter_terrain_binding.dart';
import 'source_transfer_program_authority.dart';
import 'source_grass_rustle_compiler.dart';
import 'source_inventory_controller_program.dart';
import 'source_sequence_program.dart';
import 'source_interaction_program.dart';
import 'source_actor_preparation_program.dart';
import 'source_escort_program.dart';
import 'source_first_rival_binding.dart';
import 'source_oak_parcel_binding.dart';
import 'source_external_warp_binding.dart';

String _mapSourcePath(int id) =>
    'Data/Map${id.toString().padLeft(3, '0')}.rxdata';

final class _SourceGrassBaseAdmission {
  const _SourceGrassBaseAdmission._(this.isQualified, this.mutations);

  final bool isQualified;
  final Map<ConverterId, String> mutations;

  static Future<_SourceGrassBaseAdmission> verify({
    required NormalizedSourceProject source,
    required NativeProjectDraft base,
    required Map<int, MapData> nativeMaps,
    required List<NativeMutation> mutations,
    required SourceFilePort files,
    required NativeWriteLimits limits,
    ScanCancellation? cancellation,
  }) async {
    const refused = _SourceGrassBaseAdmission._(false, {});
    final semantic = base.compositionEvidence['sourceSemantics'];
    final projection = semantic is Map ? semantic['projection'] : null;
    final evidence = projection is Map ? projection['grassRustle'] : null;
    final hasActions = mutations.any((mutation) => mutation.actionId.startsWith('smart_tile.'));
    final layers = {
      for (final entry in nativeMaps.entries)
        entry.key: entry.value.layers.whereType<SmartTileLayer>().toList(),
    };
    if (evidence == null && !hasActions && layers.values.every((layers) => layers.isEmpty)) {
      return const _SourceGrassBaseAdmission._(true, {});
    }
    if (semantic is! Map || semantic['kind'] != 'sourceSemanticStudy' ||
        semantic['version'] != 1 ||
        semantic['sourceSnapshotHash'] != source.snapshot.canonicalHash.value ||
        semantic['normalizedSourceHash'] != source.canonicalHash.value || evidence is! Map) {
      return refused;
    }
    final compiled = await const SourceGrassRustleCompiler().compile(
        source: source, files: files,
        nativeMapIds: {for (final entry in nativeMaps.entries) entry.key: entry.value.id},
        limits: limits, cancellation: cancellation);
    if (compiled == null || canonicalJsonOf(evidence, limits: limits.draftEvidenceJsonLimits) !=
        canonicalJsonOf(compiled.evidence, limits: limits.draftEvidenceJsonLimits)) {
      return refused;
    }
    final expected = {
      for (final mutation in compiled.mutations)
        mutation.operationId: canonicalJsonOf(mutation.toJson(0), limits: limits.jsonLimits),
    };
    final actual = mutations.where((mutation) => expected.containsKey(mutation.operationId)).toList();
    if (actual.length != expected.length ||
        actual.map((mutation) => mutation.operationId).toSet().length != expected.length ||
        actual.any((mutation) => canonicalJsonOf(mutation.toJson(0), limits: limits.jsonLimits) !=
            expected[mutation.operationId]) ||
        compiled.artifacts.any((artifact) => !base.artifacts.any((candidate) => candidate.handle == artifact.handle))) {
      return refused;
    }
    for (final entry in layers.entries) {
      cancellation?.check();
      final expectedLayer = compiled.layersBySourceMapId[entry.key];
      if (canonicalJsonOf(entry.value.map((layer) => layer.toJson()).toList(), limits: limits.jsonLimits) !=
          canonicalJsonOf([if (expectedLayer != null) expectedLayer.toJson()], limits: limits.jsonLimits)) {
        return refused;
      }
    }
    return _SourceGrassBaseAdmission._(true, Map.unmodifiable(expected));
  }

  bool permits(NativeMutation mutation, NativeWriteLimits limits) =>
      mutations[mutation.operationId] == canonicalJsonOf(mutation.toJson(0), limits: limits.jsonLimits);
}

final class _SourceSurfBaseAdmission {
  const _SourceSurfBaseAdmission._(
    this.isQualified,
    this.operationIds,
    this.proof,
  );

  factory _SourceSurfBaseAdmission.verify({
    required NormalizedSourceProject source,
    required NativeProjectDraft base,
    required Map<int, MapData> nativeMaps,
    required List<NativeMutation> mutations,
    required NativeWriteLimits limits,
    ScanCancellation? cancellation,
  }) {
    const refused = _SourceSurfBaseAdmission._(false, {}, {});
    final semantic = base.compositionEvidence['sourceSemantics'];
    final requested =
        semantic is Map && semantic['includeNativeSurfTraversal'] == true;
    final creates = mutations
        .where((entry) => entry.actionId == 'gameplay_zone.create')
        .toList();
    if (!requested && creates.isEmpty) {
      return const _SourceSurfBaseAdmission._(true, {}, {});
    }
    if (semantic is! Map ||
        semantic['includeNativeSurfTraversal'] != true ||
        semantic['kind'] != 'sourceSemanticStudy' ||
        semantic['version'] != 1 ||
        semantic['sourceSnapshotHash'] != source.snapshot.canonicalHash.value ||
        semantic['normalizedSourceHash'] != source.canonicalHash.value) {
      return refused;
    }
    cancellation?.check();
    try {
      final terrain = const SourceEncounterTerrainBinding().bind(
        source: source,
        nativeMapIds: {
          for (final entry in nativeMaps.entries) entry.key: entry.value.id,
        },
        tableIdsBySourceMethod: const {},
        expectedSourceSelectionHash: source.canonicalHash,
      );
      cancellation?.check();
      final expected = <ConverterId, NativeMutation>{};
      for (final entry in nativeMaps.entries) {
        cancellation?.check();
        final zones = terrain.zonesBySourceMapId[entry.key]!;
        if (canonicalJsonOf(
              jsonDecode(
                jsonEncode(
                  entry.value.gameplayZones
                      .map((zone) => zone.toJson())
                      .toList(),
                ),
              ),
              limits: limits.jsonLimits,
            ) !=
            canonicalJsonOf(
              jsonDecode(
                jsonEncode(zones.map((zone) => zone.toJson()).toList()),
              ),
              limits: limits.jsonLimits,
            )) {
          return refused;
        }
        for (final zone in zones) {
          final mutation = NativeMutation(
            operationId: ConverterId('ac12-surf-zone-${zone.id}'),
            actionId: 'gameplay_zone.create',
            sourceEntityIds: [source.mapIdentity(entry.key)],
            targetEntityIds: [
              ConverterId(entry.value.id),
              ConverterId(zone.id),
            ],
            parameters: {
              'mapId': entry.value.id,
              'zone': jsonDecode(jsonEncode(zone.toJson())),
            },
            limits: limits,
          );
          expected[mutation.operationId] = mutation;
        }
      }
      if (creates.length != expected.length) return refused;
      final saves = <String>{};
      final admitted = <ConverterId>{};
      final mapIds = nativeMaps.values.map((map) => map.id).toSet();
      for (final mutation in mutations) {
        cancellation?.check();
        if (mutation.actionId == 'map.save') {
          final saved = mutation.parameters['map'];
          if (saved is! Map || saved['id'] is! String) return refused;
          final savedId = saved['id'] as String;
          final zones = saved['gameplayZones'];
          if (!mapIds.contains(savedId) ||
              !saves.add(savedId) ||
              zones != null && (zones is! List || zones.isNotEmpty) ||
              admitted.isNotEmpty) {
            return refused;
          }
        } else if (mutation.actionId == 'gameplay_zone.create') {
          final canonical = expected[mutation.operationId];
          if (canonical == null ||
              !admitted.add(mutation.operationId) ||
              !saves.contains(mutation.parameters['mapId']) ||
              canonicalJsonOf(mutation.toJson(0), limits: limits.jsonLimits) !=
                  canonicalJsonOf(
                    canonical.toJson(0),
                    limits: limits.jsonLimits,
                  )) {
            return refused;
          }
        }
      }
      if (saves.length != mapIds.length || admitted.length != expected.length) {
        return refused;
      }
      return _SourceSurfBaseAdmission._(true, Set.unmodifiable(admitted), {
        'kind': 'sourceNativeSurfExecutionBase',
        'version': 1,
        'sourceSnapshotHash': source.snapshot.canonicalHash.value,
        'normalizedSourceHash': source.canonicalHash.value,
        'terrainBindingHash': canonicalHashOf(
          terrain.evidence,
          limits: limits.jsonLimits,
        ).value,
        'zoneCount': expected.length,
        'zoneMutationsHash': canonicalHashOf(
          creates.map((mutation) => mutation.toJson(0)).toList(),
          limits: limits.jsonLimits,
        ).value,
      });
    } on FormatException {
      return refused;
    } on TypeError {
      return refused;
    }
  }

  final bool isQualified;
  final Set<ConverterId> operationIds;
  final Map<String, Object?> proof;

  bool permits(NativeMutation mutation) =>
      isQualified &&
      mutation.actionId == 'gameplay_zone.create' &&
      operationIds.contains(mutation.operationId);
}

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
    this.programIdentity,
    Set<int> programSourceMapIds = const {},
  })  : mapIds = Map.unmodifiable(mapIds),
        programSourceMapIds = Set.unmodifiable(programSourceMapIds),
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
  final ConverterId? programIdentity;
  final Set<int> programSourceMapIds;
  final Map<int, Sha256Hash> _mapHashes;
  final String _proof;

  bool get isQualified => refusals.isEmpty;

  bool supportsRouteBarrierOnSourceMap(int sourceMapId,
          {ConverterId? eventIdentity}) =>
      isQualified &&
      staticDoorIdentity == null &&
      holeIdentity == null &&
      (programIdentity != null
          ? eventIdentity == programIdentity && programSourceMapIds.contains(sourceMapId)
          : elevatorIdentity != null
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

  SourceEventExecutionContext _forProgram(ConverterId identity, Set<int> scope) =>
      SourceEventExecutionContext._(
        sourceSnapshotHash: sourceSnapshotHash,
        normalizationHash: normalizationHash,
        sourceProfileHash: sourceProfileHash,
        baseDraftHash: baseDraftHash,
        mapIds: mapIds,
        mapHashes: _mapHashes,
        refusals: refusals,
        proof: (jsonDecode(_proof) as Map).cast<String, Object?>(),
        programIdentity: identity,
        programSourceMapIds: scope,
      );

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
        if (programIdentity != null) ...{
          'programIdentity': programIdentity!.value,
          'programSourceMapIds': programSourceMapIds.toList()..sort(),
        },
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

final class _SourceExecutionSnapshotIndex {
  factory _SourceExecutionSnapshotIndex(SourceSnapshot snapshot,
      ScanCancellation? cancellation) {
    final exact = <String, List<SourceFileEntry>>{};
    final collision = <String, List<SourceFileEntry>>{};
    final plugins = <SourceFileEntry>[];
    for (final entry in snapshot.entries) {
      cancellation?.check();
      final key = sourcePathCollisionKey(entry.relativePath);
      exact.putIfAbsent(entry.relativePath, () => []).add(entry);
      collision.putIfAbsent(key, () => []).add(entry);
      if (key == 'plugins' || key.startsWith('plugins/')) plugins.add(entry);
    }
    cancellation?.check();
    return _SourceExecutionSnapshotIndex._(snapshot,
      Map.unmodifiable({for (final e in exact.entries) e.key: List<SourceFileEntry>.unmodifiable(e.value)}),
      Map.unmodifiable({for (final e in collision.entries) e.key: List<SourceFileEntry>.unmodifiable(e.value)}),
      List.unmodifiable(plugins),
      List.unmodifiable(snapshot.excludedPaths.where(_isPluginPath)));
  }

  _SourceExecutionSnapshotIndex._(this.snapshot, this._exact, this._collision,
      this.pluginEntries, this.excludedPluginPaths);

  final SourceSnapshot snapshot;
  final Map<String, List<SourceFileEntry>> _exact, _collision;
  final List<SourceFileEntry> pluginEntries;
  final List<String> excludedPluginPaths;

  List<SourceFileEntry> exact(String path) => _exact[path] ?? const [];
  List<SourceFileEntry> colliding(String path) =>
      _collision[sourcePathCollisionKey(path)] ?? const [];

  late final Map<String, Object?> pluginInventory = {
    'entries': [for (final entry in pluginEntries) {
      'relativePath': entry.relativePath,
      'kind': entry.kind.name,
      'byteLength': entry.byteLength,
      'sha256': entry.sha256?.value,
    }],
    'excludedPaths': excludedPluginPaths,
  };
  late final Sha256Hash pluginInventoryHash = canonicalHashOf(pluginInventory);
}

final class SourceEventExecutionContextResolver {
  const SourceEventExecutionContextResolver();

  Future<Map<ConverterId, SourceEventExecutionContext>> readProgramContexts({
    required NormalizedSourceProject source,
    required NativeProjectDraft base,
    required Map<int, MapData> nativeMaps,
    required SourceFilePort files,
    required SourceEventAnalysis analysis,
    required Set<ConverterId> eventIdentities,
    Map<ConverterId, SourceSequenceProgram> sequencePrograms = const {},
    Map<ConverterId, SourceInteractionProgram> interactionPrograms = const {},
    Map<ConverterId, SourceActorPreparationProgram> actorPreparationPrograms = const {},
    Map<ConverterId, SourceEscortProgram> escortPrograms = const {},
    Map<ConverterId, SourceFirstRivalBinding> firstRivalBindings = const {},
    Map<ConverterId, SourceOakParcelBinding> oakParcelBindings = const {},
    SourceExternalWarpBinding? externalWarpBinding,
    SourceTransferProgramAuthority? authority,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    cancellation?.check();
    if (eventIdentities.isEmpty) return const {};
    final ownedAuthority = authority ?? SourceTransferProgramAuthority.forSource(source);
    final actual = ownedAuthority.analysisFor(source: source, analysis: analysis);
    final owned = ownedAuthority.executionContextFor(source);
    final scopes = <ConverterId, Set<int>>{};
    for (final identity in eventIdentities) {
      cancellation?.check();
      final event = actual.events.where((event) => event.identity == identity).singleOrNull;
      final supplied = analysis.events.where((event) => event.identity == identity).singleOrNull;
      bool bound(SourceEventDefinition candidate) =>
          sequencePrograms[identity]?.isBoundTo(source: source, analysis: actual, event: candidate) == true ||
          interactionPrograms[identity]?.isBoundTo(source: source, analysis: actual, event: candidate) == true ||
          actorPreparationPrograms[identity]?.isBoundTo(source, actual, candidate) == true ||
          escortPrograms[identity]?.isBoundTo(source, actual, candidate) == true ||
          firstRivalBindings[identity]?.isBoundTo(source, actual, candidate) == true ||
          oakParcelBindings[identity]?.isBoundTo(source, actual, candidate) == true ||
          (externalWarpBinding?.programs.containsKey(identity) == true &&
            externalWarpBinding?.isBoundToEvent(source: source, analysis: actual, event: candidate) == true);
      if (event == null || supplied == null || !bound(event) || !bound(supplied)) {
        throw const NativeWriteException('events.program.binding',
          'Execution contexts require exact authoritative closed source programs');
      }
      final scope = <int>{event.sourceMapId};
      for (final page in event.pages) {
        for (final command in page.sourcePage.commands.where((command) => command.code == 201)) {
          final parameters = command.parameters;
          if (parameters.length != 6 || parameters[0] != 0 ||
              parameters[1] is! int || !nativeMaps.containsKey(parameters[1])) {
            throw const NativeWriteException('events.program.scope',
              'Closed program destinations require exact represented source maps');
          }
          scope.add(parameters[1] as int);
        }
      }
      if (!nativeMaps.keys.toSet().containsAll(scope)) {
        throw const NativeWriteException('events.program.scope',
          'Closed program execution maps must be represented');
      }
      scopes[identity] = Set.unmodifiable(scope);
    }
    base.validateResourceBudget(limits: limits);
    final hashes = Map<int, Sha256Hash>.unmodifiable({for (final entry in nativeMaps.entries)
      entry.key: canonicalHashOf(jsonDecode(jsonEncode(entry.value.toJson())))});
    final composition = base.compositionEvidence['composition'];
    final compositionHash = composition is Map ? canonicalHashOf(composition, limits: limits.jsonLimits) : null;
    final mutations = expandNativeMutationBatches(base, limits).toList();
    final surf = _SourceSurfBaseAdmission.verify(source: source, base: base,
      nativeMaps: nativeMaps, mutations: mutations, limits: limits, cancellation: cancellation);
    final grass = await _SourceGrassBaseAdmission.verify(source: source, base: base,
      nativeMaps: nativeMaps, mutations: mutations, files: files, limits: limits, cancellation: cancellation);
    final inventoryControllers = sourceInventoryControllerPrograms(source: source,
      analysis: actual, authority: ownedAuthority);
    final inventory = _SourceExecutionSnapshotIndex(source.snapshot, cancellation);
    final witnesses = <String, Map<String, Object?>>{};
    final retained = <String, Future<NormalizedSourceProject>>{};
    final retainedAnalyses = <String, SourceEventAnalysis>{};
    final scopeContexts = <String, SourceEventExecutionContext>{};
    final result = <ConverterId, SourceEventExecutionContext>{};
    for (final entry in scopes.entries) {
      cancellation?.check();
      final key = (entry.value.toList()..sort()).join(',');
      final context = scopeContexts[key] ??= await _read(source: source, base: base,
        nativeMaps: nativeMaps, files: files, limits: limits, authority: ownedAuthority,
        cancellation: cancellation, authoritativeSourceAnalysis: actual,
        parallelDormancyAuditor: owned.parallelDormancyAuditor,
        surfBaseAdmission: surf, grassBaseAdmission: grass,
        nativeMapHashes: hashes, baseCompositionHash: compositionHash,
        baseMutations: mutations, witnessCache: witnesses, snapshotIndex: inventory,
        retainedCache: retained, retainedAnalysisCache: retainedAnalyses,
        programSourceMapIds: entry.value, inventoryControllerPrograms: inventoryControllers);
      result[entry.key] = context._forProgram(entry.key, entry.value);
    }
    return Map.unmodifiable(result);
  }

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
    SourceTransferProgramAuthority? authority,
  }) async {
    cancellation?.check();
    final ownedAuthority =
        authority ?? SourceTransferProgramAuthority.forSource(source);
    final owned = ownedAuthority.executionContextFor(source);
    return _read(
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
        staticDoorAnalysis: staticDoorAnalysis,
        authority: ownedAuthority,
        authoritativeSourceAnalysis: owned.analysis,
        parallelDormancyAuditor: owned.parallelDormancyAuditor);
  }

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
    SourceTransferProgramAuthority? authority,
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
    final surfBaseAdmission = _SourceSurfBaseAdmission.verify(
      source: source,
      base: base,
      nativeMaps: nativeMaps,
      mutations: baseMutations,
      limits: limits,
      cancellation: cancellation,
    );
    final grassBaseAdmission = await _SourceGrassBaseAdmission.verify(
        source: source, base: base, nativeMaps: nativeMaps,
        mutations: baseMutations, files: files, limits: limits,
        cancellation: cancellation);
    final ownedAuthority =
        authority ?? SourceTransferProgramAuthority.forSource(source);
    final owned = ownedAuthority.executionContextFor(source);
    final authoritativeSourceAnalysis = owned.analysis;
    final parallelDormancyAuditor = owned.parallelDormancyAuditor;
    final result = <ConverterId, SourceEventExecutionContext>{};
    final witnesses = <String, Map<String, Object?>>{};
    final retained = <String, Future<NormalizedSourceProject>>{};
    final retainedAnalyses = <String, SourceEventAnalysis>{};
    final snapshotIndex = _SourceExecutionSnapshotIndex(source.snapshot, cancellation);
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
          authority: ownedAuthority,
          authoritativeSourceAnalysis: authoritativeSourceAnalysis,
          parallelDormancyAuditor: parallelDormancyAuditor,
          surfBaseAdmission: surfBaseAdmission,
          grassBaseAdmission: grassBaseAdmission,
          nativeMapHashes: hashes,
          baseCompositionHash: compositionHash,
          baseMutations: baseMutations,
          witnessCache: witnesses,
          snapshotIndex: snapshotIndex,
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
    required SourceTransferProgramAuthority authority,
    ScanCancellation? cancellation,
    SourceStaticDoorProgram? staticDoorProgram,
    SourceRoutedDoorProgram? routedDoorProgram,
    SourceStairProgram? stairProgram,
    SourceElevatorProgram? elevatorProgram,
    SourceEventAnalysis? staticDoorAnalysis,
    SourceHoleNativeProgram? holeProgram,
    SourceEventAnalysis? authoritativeSourceAnalysis,
    SourceParallelDormancyAuditor? parallelDormancyAuditor,
    _SourceSurfBaseAdmission? surfBaseAdmission,
    _SourceGrassBaseAdmission? grassBaseAdmission,
    Map<int, Sha256Hash>? nativeMapHashes,
    Sha256Hash? baseCompositionHash,
    List<NativeMutation>? baseMutations,
    Map<String, Map<String, Object?>>? witnessCache,
    Map<String, Future<NormalizedSourceProject>>? retainedCache,
    Map<String, SourceEventAnalysis>? retainedAnalysisCache,
    _SourceExecutionSnapshotIndex? snapshotIndex,
    Set<int>? programSourceMapIds,
    Map<ConverterId, SourceInventoryControllerProgram>? inventoryControllerPrograms,
  }) async {
    cancellation?.check();
    final inventory = snapshotIndex ?? _SourceExecutionSnapshotIndex(source.snapshot, cancellation);
    if (!identical(inventory.snapshot, source.snapshot)) {
      throw const NativeWriteException('events.execution.inventory.binding',
          'Execution witness lookup requires its exact immutable source snapshot');
    }
    final profile = SourceEventProfile.forProject(source);
    final refusals = <String>{};
    final proof = <String, Object?>{};
    Map<String, Object?>? surfProof;
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
    final pluginInventory = inventory.pluginInventory;
    final pluginInventoryHash = inventory.pluginInventoryHash;
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
    if (inventory.pluginEntries.any((entry) =>
            entry.kind != SourceNodeKind.directory &&
            !(excludesCustomBehavior && entry.kind == SourceNodeKind.file &&
                entry.sha256 != null)) ||
        inventory.excludedPluginPaths.isNotEmpty) {
      refusals.add('sourcePluginInventoryUnsupported');
    }
    if (base == null) {
      refusals.add('sourceExecutionContextUnknown');
    } else {
      if (nativeMapHashes == null) base.validateResourceBudget(limits: limits);
      final semanticMutations =
          baseMutations ?? expandNativeMutationBatches(base, limits).toList();
      final surfAdmission = surfBaseAdmission ??
          _SourceSurfBaseAdmission.verify(
            source: source,
            base: base,
            nativeMaps: nativeMaps,
            mutations: semanticMutations,
            limits: limits,
            cancellation: cancellation,
          );
      if (!surfAdmission.isQualified) {
        refusals.add('sourceExecutionBaseUnsupported');
      } else if (surfAdmission.proof.isNotEmpty) {
        surfProof = surfAdmission.proof;
      }
      final grassAdmission = grassBaseAdmission ?? await _SourceGrassBaseAdmission.verify(
          source: source, base: base, nativeMaps: nativeMaps,
          mutations: semanticMutations, files: files, limits: limits,
          cancellation: cancellation);
      if (!grassAdmission.isQualified) {
        refusals.add('sourceExecutionBaseUnsupported');
      }
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
              }.contains(entry.actionId) && !surfAdmission.permits(entry) &&
                  !grassAdmission.permits(entry, limits))) {
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
        programSourceMapIds ?? (localTransfer ? {sourceMapId!, targetMapId!} : representedMapIds);
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
    final connectionsEntry = inventory.exact('Data/map_connections.dat').firstOrNull;
    final witnesses = <Map<String, Object?>>[];
    for (final expected in {
      'Data/Scripts.rxdata':
          source.interpretationProfile?.scriptsArchiveHash.value,
      for (final path in [
        'Data/PluginScripts.rxdata',
        'Data/CommonEvents.rxdata'
      ])
        if (inventory.colliding(path).isNotEmpty)
          path: inventory.exact(path).firstOrNull
                  ?.sha256
                  ?.value ??
              '',
      'Data/map_connections.dat': connectionsEntry?.sha256?.value ?? '',
      for (final id in attestedMapIds.toList()..sort())
        _mapSourcePath(id): inventory.exact(_mapSourcePath(id)).firstOrNull
                ?.sha256
                ?.value ??
            '',
    }.entries) {
      cancellation?.check();
      final matches = inventory.colliding(expected.key);
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
    freshAnalysis ??= SourceEventAnalyzer.forProject(source, profile: profile).analyze();
    final inventoryControllers = inventoryControllerPrograms ?? sourceInventoryControllerPrograms(
        source: source, analysis: freshAnalysis,
        authority: authority);
    final inventoryControllerMaps = inventoryControllers.values.map((program) => program.sourceMapId).toSet();
    final dormancyScope = attestedMapIds.intersection(representedMapIds).difference(inventoryControllerMaps);
    final dormancy = dormancyScope.isEmpty ? null : (parallelDormancyAuditor ??
        SourceParallelDormancyAuditor.forProject(source, profile: profile))
        .audit(activeSourceMapIds: dormancyScope);
    if (dormancy != null && (dormancy.sourceSnapshotHash != snapshotHash ||
        dormancy.normalizationHash != normalizationHash ||
        dormancy.profileHash != profile.canonicalHash ||
        dormancy.activeSourceMapIds.length != dormancyScope.length ||
        !dormancy.activeSourceMapIds.containsAll(dormancyScope) ||
        !dormancy.isQualified)) {
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
        !inventoryControllers.values.any((program) => program.sourceMapId == entry.$1 &&
            program.sourceEventId == entry.$2 && entry.$3.originalPageIndex == 0) &&
        dormancy?.permitsDormantParallelPage(entry.$1, entry.$2, entry.$3) != true)) {
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
        if (surfProof != null) 'nativeSurfTraversal': surfProof,
        'followers': 'newGameDeclaredEmpty',
        'scope': {
          'sourceMapIds': activeMapIds.toList()..sort(),
          'pages': programSourceMapIds != null
              ? ['boundProgramsOnActiveSourceMaps']
              : holeProgram != null
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
        'sourceContextProfile': programSourceMapIds != null
            ? 'declared-closed-program-local-fresh-v1'
            : holeProgram != null
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
        'parallelEvents': inventoryControllers.isEmpty ? 'wholeEventQuarantinedWithClosedNativeWriterSet' : 'closedMapEntryInventoryControllersAndDormantParallelPages',
        'parallelDormancy': dormancy?.toJson(),
        'inventoryControllers': [for (final program in inventoryControllers.values) program.toJson()],
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
          'parallelEvents': 'refusedUnlessClosedDormancyOrBoundMapEntryInventoryController',
          'customRouteCodes': [0, 1, 2, 3, 4, 9, 16, 17, 18, 19, 24, 32],
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
      if (!const {0, 1, 2, 3, 4, 9, 16, 17, 18, 19, 24, 32}.contains(value)) {
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
