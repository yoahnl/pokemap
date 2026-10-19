import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';

Future<Map<String, Object?>> preflightConnections(
    PreparedStudy prepared, SourceFilePort files) async {
  final draft = prepared.nativeDraft!;
  final source = prepared.normalizedSource;
  final limits = prepared.settings.writeLimits;
  final ids = {for (final entry in draft.mapIds.entries) entry.value: entry.key};
  final maps = <int, MapData>{};
  for (final mutation in draft.mutations.where((m) => m.actionId == 'map.save')) {
    final map = MapData.fromJson(
        Map<String, dynamic>.from(mutation.parameters['map'] as Map));
    maps[ids[map.id]!] = map;
  }
  for (final mutation in draft.mutations.where(
      (m) => m.actionId == 'gameplay_zone.create')) {
    final sourceId = ids[mutation.parameters['mapId']]!;
    maps[sourceId] = addGameplayZoneToMap(maps[sourceId]!,
        zone: MapGameplayZone.fromJson(
            Map<String, dynamic>.from(mutation.parameters['zone'] as Map)));
  }
  final connections = draft.mutations.where(
      (m) => m.actionId == 'connection.create_bidirectional_apply').toList();
  for (final mutation in connections) {
    final p = mutation.parameters;
    final from = ids[p['mapId']]!, to = ids[p['targetMapId']]!;
    final direction = MapConnectionDirection.values.singleWhere(
        (direction) => direction.name == p['direction']);
    maps[from] = upsertMapConnectionOnMap(maps[from]!, connection: MapConnection(
        direction: direction, targetMapId: maps[to]!.id, offset: p['offset'] as int));
    maps[to] = upsertMapConnectionOnMap(maps[to]!, connection: MapConnection(
        direction: direction.opposite, targetMapId: maps[from]!.id,
        offset: -(p['offset'] as int)));
  }
  var manifest = sourceSemanticNativeProject(draft: draft, maps: maps,
      mutations: draft.mutations, limits: limits);
  manifest = manifest.copyWith(encounterTables: [
    for (final mutation in draft.mutations.where(
        (entry) => entry.actionId == 'campaign.encounter_table.upsert'))
      ProjectEncounterTable.fromJson(
          Map<String, dynamic>.from(mutation.parameters['value'] as Map)),
  ]);
  var resources = SourceBorderReplayResources();
  for (final mutation in draft.mutations.where((m) =>
      m.actionId.startsWith('border.') || m.actionId.startsWith('border_layer.'))) {
    final replay = await replaySourceBorderMutation(project: manifest,
        resources: resources,
        maps: mutation.actionId.startsWith('border_layer.')
            ? {for (final map in maps.values)
                if (map.id == mutation.parameters['mapId']) map.id: map}
            : const {},
        mutation: mutation, artifacts: draft.artifacts, limits: limits);
    manifest = replay.project;
    resources = replay.resources;
    for (final entry in replay.maps.entries) {
      maps[ids[entry.key]!] = entry.value;
    }
  }
  final admittedIds = connections.expand((m) => m.sourceEntityIds).toSet();
  final arrivals = [
    for (final connection in source.connections)
      if (admittedIds.contains(connection.identity))
        ...sourceConnectionArrivals(source: source, connection: connection,
            nativeMaps: maps),
  ];
  bool nativeWater(SourceConnectionArrival arrival) {
    final position = arrival.targetPosition;
    return maps[arrival.targetSourceMapId]!.gameplayZones.any((zone) =>
        zone.kind == GameplayZoneKind.movement &&
        zone.movement?.requiredMode == MovementMode.surf &&
        position.x >= zone.area.pos.x && position.y >= zone.area.pos.y &&
        position.x < zone.area.pos.x + zone.area.size.width &&
        position.y < zone.area.pos.y + zone.area.size.height);
  }
  final waterGaps = [for (final arrival in arrivals)
    if (arrival.passage.isPassable == true && nativeWater(arrival)) {
      'sourceMapId': arrival.targetSourceMapId,
      'targetPosition': arrival.targetPosition.toJson(),
      'sourceEntryStatus': arrival.passage.status.name,
      'nativeRequiresSurf': true,
    }
  ];
  final result = <String, Object?>{
    'kind': 'preparedNativeConnectionStaticPreflight',
    'scope': 'exactPreparedMapSavesSurfZonesConnectionsAndCanonicalBordersOnly',
    'finalEventStateQualified': false,
    'finalPublicationProof': false,
    'globalPlayabilityCertified': false,
    'sourceSnapshotHash': source.snapshot.canonicalHash.value,
    'normalizationHash': source.canonicalHash.value,
    'preparationHash': prepared.preparationHash.value,
    'nativeDraftHash': draft.canonicalHash.value,
    'mapCount': maps.length,
    'connectionCount': connections.length,
    'arrivalCount': arrivals.length,
    'sourceAllowedNativeSurfCount': waterGaps.length,
    'sourceAllowedNativeSurfExamples': waterGaps.take(64).toList(),
    'jumpDiagnostics': ((draft.compositionEvidence['sourceSemantics'] as Map?)?['directedJumps'] as Map?)?['diagnostics'],
  };
  try {
    const SourceEventArrivalValidator().validateConnections(manifest: manifest,
        maps: maps.values.toList(), source: source,
        connectionMutations: connections);
    result['passed'] = true;
  } on NativeWriteException catch (error) {
    result['passed'] = false;
    result['failureCode'] = error.code;
    result['failure'] = error.message;
  }
  result['evidenceHash'] = canonicalHashOf(
      jsonDecode(jsonEncode(result)), limits: limits.draftEvidenceJsonLimits).value;
  return result;
}

