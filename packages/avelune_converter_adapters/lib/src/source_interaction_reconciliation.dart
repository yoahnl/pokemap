import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';

final class SourceInteractionReconciliation {
  SourceInteractionReconciliation._(this._json);

  final Map<String, Object?> _json;

  static SourceInteractionReconciliation build({
    required Map<String, Object?> inventory,
    required Map<String, Object?> projectionEvidence,
    required Iterable<NativeMutation> expectedMutations,
    required ProjectManifest observedProject,
    required Iterable<MapData> observedMaps,
    required String toolRevision,
    required String projectionToolRevision,
    required String logicalProjectNamespace,
    required String sourceSnapshotHash,
    required String normalizationHash,
    required String sourceProfileHash,
    String? interpretationProfileHash,
  }) {
    _require(toolRevision.isNotEmpty && projectionToolRevision == toolRevision,
        'projection_revision');
    _require(projectionEvidence['toolRevision'] == toolRevision,
        'projection_evidence_revision');
    _require(
        inventory['kind'] == 'sourceInteractionInventory' &&
            inventory['schemaVersion'] == 1,
        'inventory_contract');
    _require(inventory['toolRevision'] == toolRevision, 'inventory_revision');
    _require(
        logicalProjectNamespace.isNotEmpty &&
            inventory['logicalProjectNamespace'] == logicalProjectNamespace &&
            projectionEvidence['logicalProjectNamespace'] ==
                logicalProjectNamespace,
        'namespace');
    _require(
        projectionEvidence['interpretationProfileHash'] ==
            interpretationProfileHash,
        'interpretation_profile');
    for (final pair in [
      ('sourceSnapshotHash', sourceSnapshotHash),
      ('normalizationHash', normalizationHash),
    ]) {
      _require(
          inventory[pair.$1] == pair.$2 &&
              projectionEvidence[pair.$1] == pair.$2,
          pair.$1);
    }
    _require(
        inventory['analysisProfileHash'] == sourceProfileHash &&
            projectionEvidence['sourceProfileHash'] == sourceProfileHash,
        'source_profile');
    final source = _unique(_rows(inventory['events']), 'sourceIdentity');
    final projected =
        _unique(_rows(projectionEvidence['events']), 'sourceIdentity');
    _require(
        projected.keys.every(source.containsKey), 'unknown_projected_event');
    final sourcePages = <String, Map<int, Map<String, Object?>>>{};
    final sourceLocations = <String>{};
    final pageRecordOwners = <String, (String, int?)>{};
    var pageCount = 0;
    for (final entry in source.entries) {
      final event = entry.value;
      final map = event['sourceMapId'];
      final id = event['sourceEventId'];
      _require(map is int && id is int && sourceLocations.add('$map:$id'),
          'source_locator');
      final pages = _pages(event);
      sourcePages[entry.key] = pages;
      pageCount += pages.length;
      pageRecordOwners[_eventId(
              logicalProjectNamespace, map as int, id as int, 'quarantine')] =
          (entry.key, null);
      for (final page in pages.keys) {
        pageRecordOwners[
                _eventId(logicalProjectNamespace, map, id, 'page_$page')] =
            (entry.key, page);
      }
      if (projected[entry.key] case final value?) {
        final supplied = _pages(value);
        _require(
            supplied.length == pages.length &&
                supplied.keys.every(pages.containsKey),
            'projection_page_census');
        final locator = _object(value['locator']);
        _require(locator['mapId'] == map && locator['eventId'] == id,
            'projection_locator');
        _require(
            _hash(value['locator']) == _hash(event['locator']) &&
                value['sourceFileId'] == event['sourceFileId'],
            'projection_source_reference');
        for (final page in supplied.entries) {
          for (final field in ['locator', 'rawDataRef']) {
            _require(_hash(page.value[field]) == _hash(pages[page.key]![field]),
                'projection_page_reference');
          }
        }
      }
    }
    _require(
        inventory['eventCount'] == source.length &&
            inventory['pageCount'] == pageCount,
        'inventory_census');
    final maps = <String, MapData>{};
    for (final map in observedMaps) {
      _require(!maps.containsKey(map.id), 'duplicate_native_map');
      maps[map.id] = map;
    }
    final mapIds = observedProject.maps.map((map) => map.id).toSet();
    _require(
        mapIds.length == observedProject.maps.length &&
            maps.length == mapIds.length &&
            mapIds.every(maps.containsKey) &&
            inventory['mapCount'] == maps.length,
        'native_map_census');
    final observed = <String, Map<String, Object?>>{};
    void observe(String kind, Map<String, Object?> json, [String? mapId]) {
      final id = _identity(json, kind);
      final key = _key(kind, id, mapId);
      _require(!observed.containsKey(key), 'duplicate_native_object');
      observed[key] = json;
    }

    for (final map in maps.values) {
      for (final entity in map.entities) {
        observe('entity', entity.toJson(), map.id);
      }
      for (final trigger in map.triggers) {
        observe('trigger', trigger.toJson(), map.id);
      }
      for (final warp in map.warps) {
        observe('warp', warp.toJson(), map.id);
      }
    }
    for (final row in observedProject.eventRegistry?.records ??
        const <NarrativeEventRecord>[]) {
      observe('record', row.toJson());
    }
    for (final scene in observedProject.scenes) {
      observe('scene', scene.toJson());
    }
    for (final fact in observedProject.facts) {
      observe('fact', fact.toJson());
    }
    for (final dialogue in observedProject.dialogues) {
      observe('dialogue', dialogue.toJson());
    }
    for (final cinematic in observedProject.cinematics) {
      observe('cinematic', cinematic.toJson());
    }
    for (final rule in observedProject.worldRules) {
      observe('worldRule', rule.toJson());
    }
    for (final shop in observedProject.shops) {
      observe('shop', shop.toJson());
    }
    final recordsByOwner = <String, List<Map<String, Object?>>>{};
    final entitiesByOwner = <String, List<MapEntity>>{};
    final scenesByOwner = <String, List<SceneAsset>>{};
    for (final entry
        in observed.entries.where((entry) => entry.key.startsWith('record:'))) {
      final owner = pageRecordOwners[_identity(entry.value, 'record')];
      if (owner != null) {
        recordsByOwner.putIfAbsent(owner.$1, () => []).add(entry.value);
      }
    }
    for (final entity in maps.values.expand((map) => map.entities)) {
      final owner = entity.properties['sourceEventIdentity'];
      if (owner != null) {
        entitiesByOwner.putIfAbsent(owner, () => []).add(entity);
      }
    }
    for (final scene in observedProject.scenes) {
      final owner = scene.metadata['sourceEventIdentity'];
      if (owner != null) scenesByOwner.putIfAbsent(owner, () => []).add(scene);
    }
    final expected = <String, _ExpectedObject>{};
    final operationIds = <String>{};
    final unknown = <String, List<String>>{};
    for (final mutation in expectedMutations) {
      _require(operationIds.add(mutation.operationId.value),
          'duplicate_expected_operation');
      final owners = mutation.sourceEntityIds
          .map((id) => id.value)
          .where(source.containsKey)
          .toSet();
      if (owners.isEmpty) continue;
      final target = _target(mutation);
      if (target == null) {
        for (final owner in owners) {
          unknown.putIfAbsent(owner, () => []).add(mutation.actionId);
        }
        continue;
      }
      final (kind, id, mapId, value, patch) = target;
      _require(mutation.targetEntityIds.any((target) => target.value == id),
          'mutation_target');
      final key = _key(kind, id, mapId);
      final recordOwner = kind == 'record' ? pageRecordOwners[id] : null;
      final metadata = value['metadata'];
      final properties = value['properties'];
      for (final container in [metadata, properties]) {
        final declaredOwner =
            container is Map ? container['sourceEventIdentity'] : null;
        _require(declaredOwner == null || owners.contains(declaredOwner),
            'mutation_source_owner');
      }
      _require(recordOwner == null || owners.contains(recordOwner.$1),
          'mutation_record_owner');
      final page = recordOwner?.$2 ??
          (metadata is Map
              ? int.tryParse('${metadata['sourcePageIndex']}')
              : null);
      final row = expected.putIfAbsent(
          key, () => _ExpectedObject(key, kind, id, mapId, page));
      if (patch) {
        row.value = {...?row.value, ...value};
      } else {
        row.value = {...value};
      }
      row.partial = row.partial && patch;
      row.owners.addAll(owners);
      row.actions.add(mutation.actionId);
    }
    final resultsByOwner = <String, List<Map<String, Object?>>>{};
    for (final object in expected.values) {
      final actual = observed[object.key];
      final expectedValue = object.kind == 'entity' && !object.partial
          ? MapEntity.fromJson(object.value!).toJson()
          : object.value!;
      final comparable = actual == null
          ? null
          : object.partial
              ? {for (final field in expectedValue.keys) field: actual[field]}
              : actual;
      final status = actual == null
          ? 'missing'
          : _hash(expectedValue) == _hash(comparable)
              ? 'match'
              : 'different';
      final result = <String, Object?>{
        'key': object.key,
        'kind': object.kind,
        'id': object.id,
        if (object.mapId != null) 'mapId': object.mapId,
        'sourcePageIndex': object.page,
        'status': status,
        'actions': object.actions.toList()..sort(),
        'expectedHash': _hash(expectedValue),
        'observedHash': comparable == null ? null : _hash(comparable),
        'comparisonScope': object.partial ? 'targetedFields' : 'wholeObject',
        if (object.kind == 'dialogue') 'sourceBytesComparison': 'notAssessed',
      };
      for (final owner in object.owners) {
        resultsByOwner.putIfAbsent(owner, () => []).add(result);
      }
    }
    final decisionCounts = <String, int>{};
    final comparisonCounts = <String, int>{};
    final gapCounts = <String, int>{};
    final output = <Map<String, Object?>>[];
    for (final entry in source.entries) {
      final event = entry.value;
      final projection = projected[entry.key];
      final projectedPages = projection == null
          ? <int, Map<String, Object?>>{}
          : _pages(projection);
      final rawDecision = projection?['status'];
      final decision = const {
        'adaptedStaticSemantics',
        'quarantinedWholeEvent',
        'partiallyAdapted',
      }.contains(rawDecision)
          ? rawDecision as String
          : 'notAssessed';
      final gaps = (projection?['gaps'] as List? ?? const [])
          .cast<String>()
          .toSet()
          .toList()
        ..sort();
      final objects = resultsByOwner[entry.key] ?? [];
      final unassessed = unknown[entry.key] ?? [];
      final comparison = _comparison(objects, unassessed);
      _increment(decisionCounts, decision);
      _increment(comparisonCounts, comparison);
      for (final gap in gaps) {
        _increment(gapCounts, gap);
      }
      Map<String, Object?> actualNative([int? page]) {
        final records = (recordsByOwner[entry.key] ?? const []).where((record) {
          final owner = pageRecordOwners[_identity(record, 'record')];
          return owner?.$1 == entry.key &&
              (page == null || owner?.$2 == null || owner?.$2 == page);
        }).toList();
        final entities = entitiesByOwner[entry.key] ?? const [];
        final scenes = (scenesByOwner[entry.key] ?? const <SceneAsset>[]).where(
            (scene) =>
                (page == null || scene.metadata['sourcePageIndex'] == '$page'));
        final configured = records
            .where((record) => record['state'] == 'configured')
            .map((record) => _identity(record, 'record'))
            .toList()
          ..sort();
        final drafts = records
            .where((record) => record['state'] == 'draft')
            .map((record) => _identity(record, 'record'))
            .toList()
          ..sort();
        return {
          'configuredRecordIds': configured,
          'draftRecordIds': drafts,
          'sceneIds': scenes.map((scene) => scene.id).toList()..sort(),
          'entityIds': entities.map((entity) => entity.id).toList()..sort(),
          'fieldObstacleEntityIds': entities
              .where((entity) => entity.fieldObstacle != null)
              .map((entity) => entity.id)
              .toList()
            ..sort(),
          'draftAndConfiguredCoexist':
              configured.isNotEmpty && drafts.isNotEmpty,
        };
      }

      final shared =
          objects.where((object) => object['sourcePageIndex'] == null).toList();
      output.add({
        'sourceIdentity': entry.key,
        'locator': event['locator'],
        'sourceFileId': event['sourceFileId'],
        'sourceFileSha256': event['sourceFileSha256'],
        'sourceMapId': event['sourceMapId'],
        'sourceEventId': event['sourceEventId'],
        'name': event['name'],
        'mapName': event['mapName'],
        for (final key in ['x', 'y', 'roles', 'sourceSemanticContextHash'])
          if (event.containsKey(key)) key: event[key],
        for (final key in ['nativeProgramKinds', 'nativeProgramEvidence'])
          if (projection?.containsKey(key) ?? false) key: projection![key],
        'converterDecision': decision,
        if (rawDecision != null && decision == 'notAssessed')
          'rawConverterDecision': rawDecision,
        'gaps': gaps,
        'nativeComparison': comparison,
        'nativeComparisonScope': 'selectedExpectedObjectsOnly',
        'pageNativeCoverageCertified': false,
        'expectedObjects': objects,
        'unassessedActions': unassessed.toSet().toList()..sort(),
        'actualNative': actualNative(),
        'runtimeProof': 'notReplayed',
        'criticality': 'requiresReview',
        'witness': {
          'sourceLocator': event['locator'],
          'expectedObjectKeys': objects.map((object) => object['key']).toList(),
          'observedNative': actualNative(),
          'runtimeProof': 'notReplayed',
        },
        'pages': [
          for (final page in sourcePages[entry.key]!.entries)
            {
              'originalPageIndex': page.key,
              'locator': page.value['locator'] ??
                  {
                    ..._object(event['locator']),
                    'pageIndex': page.key,
                  },
              'rawDataRef': page.value['rawDataRef'],
              'roles': page.value['roles'] ?? const [],
              'commandBodyEmpty': page.value['commandBodyEmpty'],
              for (final key in [
                'triggerCode',
                'trigger',
                'condition',
                'selection',
                'expectedBehaviorSignals',
                'diagnostics',
                'sourceAdaptations',
                'unresolvedCommonEventCalls',
                'reviewReasons',
                'staticAnalysisQuarantined',
                'noExecutableCommands',
                'rawCommandCount',
                'rawExecutableCommandCount',
              ])
                if (page.value.containsKey(key)) key: page.value[key],
              'adaptedCommands':
                  projectedPages[page.key]?['adaptedCommands'] ?? const [],
              'converterDecision': decision,
              'expectedObjectKeys': objects
                  .where((object) => object['sourcePageIndex'] == page.key)
                  .map((object) => object['key'])
                  .toList(),
              'sharedExpectedObjectKeys':
                  shared.map((object) => object['key']).toList(),
              'nativeComparison': _comparison([
                ...shared,
                ...objects
                    .where((object) => object['sourcePageIndex'] == page.key),
              ], unassessed),
              'nativeComparisonScope': 'selectedExpectedObjectsOnly',
              'coverage': {
                'pageSpecificExpectedCount': objects
                    .where((object) => object['sourcePageIndex'] == page.key)
                    .length,
                'sharedExpectedCount': shared.length,
                'pageNativeCoverageCertified': false,
              },
              'actualNative': actualNative(page.key),
              'witness': {
                'sourceLocator': page.value['locator'] ??
                    {..._object(event['locator']), 'pageIndex': page.key},
                'observedNative': actualNative(page.key),
                'runtimeProof': 'notReplayed',
              },
              'runtimeProof': 'notReplayed',
              'criticality': 'requiresReview',
            }
        ],
      });
    }
    final summary = <String, Object?>{
      'mapCount': maps.length,
      'eventCount': output.length,
      'pageCount': pageCount,
      'converterDecisionCounts': _sorted(decisionCounts),
      'nativeComparisonCounts': _sorted(comparisonCounts),
      'categoryCountsExclusive': true,
      'nativeComparisonScope': 'selectedExpectedObjectsOnly',
      'pageNativeCoverageCertified': false,
      'gapEventCounts': _sorted(gapCounts),
      'gapCountsOverlap': true,
      'expectedObjectCount': expected.length,
      'unassessedScope': [
        'runtimePlayability',
        'progressionCriticality',
        'dialogueSourceBytes',
        'externalAssets',
        'unmappedMutationKinds'
      ],
    };
    return SourceInteractionReconciliation._({
      'kind': 'sourceInteractionReconciliation',
      'schemaVersion': 1,
      'provenance': {
        'toolRevision': toolRevision,
        'projectionToolRevision': projectionToolRevision,
        'logicalProjectNamespace': logicalProjectNamespace,
        'sourceSnapshotHash': sourceSnapshotHash,
        'normalizationHash': normalizationHash,
        'sourceProfileHash': sourceProfileHash,
        'interpretationProfileHash': interpretationProfileHash,
      },
      'summary': summary,
      'events': output,
      'globalPlayabilityCertified': false,
      'sourceScriptsExecuted': 0,
      'aiSourceInferenceCalls': 0,
    });
  }

  Map<String, Object?> toJson() => _object(jsonDecode(jsonEncode(_json)));

  Map<String, Object?> summaryJson() => _object(jsonDecode(jsonEncode({
        for (final entry in _json.entries)
          if (entry.key != 'events') entry.key: entry.value,
      })));
}

final class _ExpectedObject {
  _ExpectedObject(this.key, this.kind, this.id, this.mapId, this.page);
  final String key, kind, id;
  final String? mapId;
  final int? page;
  Map<String, Object?>? value;
  bool partial = true;
  final owners = <String>{};
  final actions = <String>{};
}

(String, String, String?, Map<String, Object?>, bool)? _target(
    NativeMutation mutation) {
  final parameters = mutation.parameters;
  final contract = switch (mutation.actionId) {
    'entity.upsert' => ('entity', 'entity'),
    'trigger.create' => ('trigger', 'trigger'),
    'warp.create' => ('warp', 'warp'),
    'event_v2.record_upsert' => ('record', 'record'),
    'scene.upsert' => ('scene', 'scene'),
    'fact.create' => ('fact', 'fact'),
    'dialogue.create' => ('dialogue', 'entry'),
    'cinematic.upsert' => ('cinematic', 'cinematic'),
    'world_rule.create' => ('worldRule', 'rule'),
    'campaign.shop.upsert' => ('shop', 'value'),
    _ => null,
  };
  if (contract != null) {
    final value = _object(parameters[contract.$2]);
    return (
      contract.$1,
      _identity(value, contract.$1),
      parameters['mapId'] as String?,
      value,
      false
    );
  }
  final field = switch (mutation.actionId) {
    'entity.set_presentation' => 'presentation',
    'entity.set_field_obstacle' => 'fieldObstacle',
    _ => null,
  };
  if (field == null) return null;
  return (
    'entity',
    parameters['entityId'] as String,
    parameters['mapId'] as String,
    {field: parameters[field]},
    true
  );
}

String _identity(Map<String, Object?> value, String kind) {
  final target =
      kind == 'record' ? _object(value['definition'] ?? value['draft']) : value;
  final id = target['id'];
  _require(id is String && id.isNotEmpty, 'native_identity');
  return id as String;
}

Map<String, Map<String, Object?>> _unique(
    List<Map<String, Object?>> values, String key) {
  final result = <String, Map<String, Object?>>{};
  for (final row in values) {
    final id = row[key];
    _require(id is String && id.isNotEmpty && !result.containsKey(id),
        'duplicate_or_missing_$key');
    result[id as String] = row;
  }
  return result;
}

Map<int, Map<String, Object?>> _pages(Map<String, Object?> event) {
  final pages = <int, Map<String, Object?>>{};
  for (final page in _rows(event['pages'])) {
    final index = page['originalPageIndex'];
    _require(index is int && index >= 0 && !pages.containsKey(index),
        'duplicate_or_missing_page');
    pages[index as int] = page;
  }
  return pages;
}

String _comparison(
    List<Map<String, Object?>> objects, List<String> unassessed) {
  if (objects.any((object) => object['status'] == 'missing')) return 'missing';
  if (objects.any((object) => object['status'] == 'different')) {
    return 'different';
  }
  if (objects.isEmpty) return 'notAssessed';
  return unassessed.isEmpty ? 'match' : 'partiallyAssessed';
}

String _eventId(String namespace, int mapId, int eventId, String role) {
  final hash = canonicalHashOf({
    'namespace': namespace,
    'mapId': mapId,
    'eventId': eventId,
    'role': role
  }).value;
  return 'evt_${hash.substring(0, 8)}-${hash.substring(8, 12)}-7${hash.substring(13, 16)}-8${hash.substring(17, 20)}-${hash.substring(20, 32)}';
}

String _key(String kind, String id, String? mapId) =>
    '$kind:${mapId ?? ''}:$id';
String _hash(Object? value) => canonicalHashOf(jsonDecode(jsonEncode(value)),
        limits: const ContractLimits(
            maxNodes: 8000000, maxTextCodeUnits: 134217728))
    .value;
void _increment(Map<String, int> counts, String key) =>
    counts.update(key, (value) => value + 1, ifAbsent: () => 1);
Map<String, int> _sorted(Map<String, int> counts) =>
    {for (final key in counts.keys.toList()..sort()) key: counts[key]!};
List<Map<String, Object?>> _rows(Object? value) {
  _require(value is List, 'list_expected');
  return (value as List).map(_object).toList();
}

Map<String, Object?> _object(Object? value) {
  _require(value is Map, 'object_expected');
  return Map<String, Object?>.from(value as Map);
}

void _require(bool valid, String code) {
  if (!valid) throw StateError('source.reconciliation.$code');
}
