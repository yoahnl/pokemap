import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';

import 'native_encounter_catalog_bindings.dart';
import 'native_project_writer.dart';
import 'source_encounter_terrain_binding.dart';
import 'native_psdk_catalog.dart';

final class SourceEncounterConsumers {
  const SourceEncounterConsumers._(this.zones, this.companions, this.evidence);

  final Map<int, List<MapGameplayZone>> zones;
  final List<Map<String, Object?>> companions;
  final Map<String, Object?> evidence;

  static SourceEncounterConsumers bind({
    required NormalizedSourceProject source,
    required Map<int, String> nativeMapIds,
    required List<ProjectEncounterTable> tables,
    required Map<String, Object?> catalogEvidence,
    required NativeEncounterCatalogQualification qualification,
    required List<Object?> pendingCompanions,
    required List<NativeMutation> precedingMutations,
  }) {
    if (catalogEvidence['sourceSnapshotHash'] !=
            source.snapshot.canonicalHash.value ||
        canonicalHashOf(catalogEvidence['qualification'],
                limits: nativePsdkCatalogShardJsonLimits) !=
            qualification.evidenceHash) {
      _invalid('catalog_binding');
    }
    final rows = (catalogEvidence['tables'] as List).cast<Map>();
    final byId = {for (final table in tables) table.id: table};
    if (byId.length != tables.length || rows.length != tables.length) {
      _invalid('table_identity');
    }
    final methods = <int, Map<String, String>>{};
    for (final row in rows) {
      final id = (row['sourceIdentity'] as Map)['sourceMapId'] as int;
      final method = row['method'] as String;
      final tableId = row['nativeTableId'] as String;
      if (row['nativeMapId'] != nativeMapIds[id] ||
          !byId.containsKey(tableId) ||
          (methods[id] ?? const {}).containsKey(method)) {
        _invalid('table_identity');
      }
      (methods[id] ??= {})[method] = tableId;
    }
    final terrain = const SourceEncounterTerrainBinding().bind(
        source: source,
        nativeMapIds: nativeMapIds,
        tableIdsBySourceMethod: methods);
    final precedingZones = <String, Map>{};
    for (final mutation in precedingMutations
        .where((mutation) => mutation.actionId == 'gameplay_zone.create')) {
      final zone = mutation.parameters['zone'] as Map;
      final key = '${mutation.parameters['mapId']}|${zone['id']}';
      if (precedingZones.containsKey(key)) _invalid('movement_duplicate');
      precedingZones[key] = zone;
    }
    final encounterZones = <int, List<MapGameplayZone>>{};
    for (final entry in terrain.zonesBySourceMapId.entries) {
      encounterZones[entry.key] = [];
      for (final zone in entry.value) {
        if (zone.kind == GameplayZoneKind.movement) {
          final actual =
              precedingZones['${nativeMapIds[entry.key]}|${zone.id}'];
          if (actual == null ||
              canonicalJsonOf(actual) !=
                  canonicalJsonOf(_inert(zone.toJson()))) {
            _invalid('movement_missing');
          }
        } else if (zone.kind == GameplayZoneKind.encounter) {
          encounterZones[entry.key]!.add(zone);
        }
      }
    }
    final companions = <Map<String, Object?>>[];
    final identities = <String>{};
    for (final raw in pendingCompanions) {
      if (raw is! Map) _invalid('companion_shape');
      final request = Map<String, Object?>.from(raw);
      final parameters =
          Map<String, Object?>.from(request['parameters'] as Map);
      final binding = request['binding'] as Map;
      final proof = binding['nativeRockSmashEncounterBinding'] as Map;
      final sourceMapId = request['sourceMapId'];
      final tableId = binding['nativeRockSmashEncounterTableId'];
      final table = byId[tableId];
      final matching = rows.where((row) => row['nativeTableId'] == tableId);
      final entityId = parameters['entityId'];
      if (request['actionId'] != 'entity.set_interactive_encounter' ||
          sourceMapId is! int ||
          parameters['mapId'] != nativeMapIds[sourceMapId] ||
          entityId is! String ||
          !identities.add('${parameters['mapId']}|$entityId') ||
          binding['sourceEventIdentity'] != request['sourceEventIdentity'] ||
          binding['sourceSnapshotHash'] !=
              source.snapshot.canonicalHash.value ||
          binding['normalizationHash'] != source.canonicalHash.value ||
          binding['pendingCatalogCompanion'] != true ||
          binding['nativeExecutionQualified'] != false ||
          proof['kind'] != 'nativeRockSmashEncounterBinding' ||
          proof['version'] != 2 ||
          proof['sourceSnapshotHash'] != source.snapshot.canonicalHash.value ||
          proof['normalizationHash'] != source.canonicalHash.value ||
          proof['sourcePbsHash'] != catalogEvidence['sourcePbsHash'] ||
          proof['nativeMapId'] != nativeMapIds[sourceMapId] ||
          proof['sourceMapId'] != sourceMapId ||
          table == null ||
          methods[sourceMapId]?['RockSmash'] != tableId ||
          matching.length != 1 ||
          proof['qualificationEvidenceHash'] !=
              qualification.evidenceHash.value ||
          canonicalJsonOf(proof['nativeTable']) !=
              canonicalJsonOf(table.toJson()) ||
          proof['nativeTableHash'] != canonicalHashOf(table.toJson()).value ||
          canonicalJsonOf(proof['tableBinding']) !=
              canonicalJsonOf(matching.single) ||
          canonicalJsonOf(parameters['interactiveEncounter']) !=
              canonicalJsonOf(MapEntityInteractiveEncounterData(
                trigger: InteractiveEncounterTrigger.afterRockSmash,
                reusePolicy: InteractiveEncounterReusePolicy.oncePerMapInstance,
                encounterTableId: tableId as String,
              ).toJson())) {
        _invalid('companion_binding');
      }
      final owner = precedingMutations.where((mutation) =>
          mutation.actionId == 'entity.set_field_obstacle' &&
          mutation.parameters['mapId'] == parameters['mapId'] &&
          mutation.parameters['entityId'] == entityId &&
          (mutation.parameters['fieldObstacle'] as Map)['kind'] ==
              'rockSmashRock');
      if (owner.length != 1) _invalid('companion_owner');
      companions.add(parameters);
    }
    return SourceEncounterConsumers._(encounterZones, companions, {
      'kind': 'sourceEncounterConsumers',
      'version': 1,
      'sourceSnapshotHash': source.snapshot.canonicalHash.value,
      'normalizationHash': source.canonicalHash.value,
      'terrain': terrain.evidence,
      'terrainConsumersQualified': true,
      'fieldCompanionsPublished': companions.length,
      'fieldConsumersQualified': true,
      'sourceCadenceParityQualified': false,
      'sourceScriptsExecuted': 0,
      'aiCalls': 0,
      'playableCertified': false,
    });
  }
}

Object? _inert(Object? value) => jsonDecode(jsonEncode(value));

Never _invalid(String code) => throw NativeWriteException(
    'encounter_consumers.$code',
    'Native encounter consumers require exact source, terrain and table bindings.');
