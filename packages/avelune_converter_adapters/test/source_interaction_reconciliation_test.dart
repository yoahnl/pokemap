import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'package:avelune_converter_adapters/src/native_project_writer.dart';
import 'package:avelune_converter_adapters/src/source_interaction_reconciliation.dart';

const _identity = 's1:synthetic-event';
const _snapshot =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _normalization =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _profile =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';

void main() {
  test('native trigger geometry is compared through its serialized values', () {
    const trigger = MapTrigger(
        id: 'trigger',
        type: TriggerType.interaction,
        area: MapRect(
            pos: GridPos(x: 1, y: 1), size: GridSize(width: 1, height: 1)));
    final mutations = [
      _mutation('trigger.create',
          {'mapId': 'map', 'trigger': jsonDecode(jsonEncode(trigger.toJson()))},
          target: 'trigger')
    ];
    final matched = _build(mutations: mutations, maps: [
      _map().copyWith(triggers: [trigger])
    ]).toJson();
    expect((matched['events'] as List).single['nativeComparison'], 'match');
    final changed = _build(mutations: mutations, maps: [
      _map().copyWith(triggers: [
        trigger.copyWith(
            area: trigger.area.copyWith(pos: const GridPos(x: 2, y: 1)))
      ])
    ]).toJson();
    expect((changed['events'] as List).single['nativeComparison'], 'different');
  });

  test('passive native entity is matched without inventing an event record',
      () {
    final result = _build().toJson();
    final event = (result['events'] as List).single as Map;
    expect(event['nativeComparison'], 'match');
    expect(event['criticality'], 'requiresReview');
    expect(event['runtimeProof'], 'notReplayed');
    final page = (event['pages'] as List).single as Map;
    expect((page['actualNative'] as Map)['configuredRecordIds'], isEmpty);
    expect((page['actualNative'] as Map)['entityIds'], ['actor']);
    expect(result['globalPlayabilityCertified'], isFalse);
  });

  test('expected missing and changed entities are distinguished', () {
    final missing =
        (_build(maps: [_map(entities: [])]).toJson()['events'] as List).single
            as Map;
    expect(missing['nativeComparison'], 'missing');
    final changed = (_build(maps: [
      _map(entities: [_entity(name: 'Edited')])
    ]).toJson()['events'] as List)
        .single as Map;
    expect(changed['nativeComparison'], 'different');
    expect((changed['expectedObjects'] as List).single['status'], 'different');
  });

  test('draft plus configured is reported without calling it disabled', () {
    final project = _project.copyWith(
        eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: [
          NarrativeEventRecord.draft(NarrativeEventDraft(
              id: _recordId('quarantine'),
              name: 'Old draft',
              conditions: const [],
              priority: 0,
              order: 0)),
          NarrativeEventRecord.configuredStructurallyUnchecked(
              NarrativeEventDefinition(
                  id: _recordId('page_0'),
                  name: 'Configured',
                  conditions: const [],
                  source: NarrativeEventSourceRef.mapEnter('map'),
                  sceneId: 'scene',
                  reusePolicy: NarrativeEventReusePolicy.reusable,
                  priority: 0,
                  order: 0),
              enabled: true,
              activeInLegacyMode: false),
        ],
            legacyClaims: const []));
    final event =
        (_build(project: project).toJson()['events'] as List).single as Map;
    final actual = event['actualNative'] as Map;
    expect(actual['draftAndConfiguredCoexist'], isTrue);
    expect(actual['configuredRecordIds'], [_recordId('page_0')]);
    expect(actual['draftRecordIds'], [_recordId('quarantine')]);
  });

  for (final key in [
    'sourceSnapshotHash',
    'normalizationHash',
    'sourceProfileHash'
  ]) {
    test('rejects mismatched projection $key', () {
      expect(() => _build(projection: {..._projection(), key: 'different'}),
          throwsStateError);
    });
  }

  test('rejects wrong namespace and stale producer revision', () {
    expect(() => _build(namespace: 'another'), throwsStateError);
    expect(() => _build(projectionRevision: 'old'), throwsStateError);
  });

  test('rejects duplicate source identities and duplicate pages', () {
    final inventory = _inventory();
    final events = inventory['events'] as List;
    events.add(events.single);
    expect(() => _build(inventory: inventory), throwsStateError);
    final pagesInventory = _inventory();
    final pages =
        ((pagesInventory['events'] as List).single as Map)['pages'] as List;
    pages.add(pages.single);
    expect(() => _build(inventory: pagesInventory), throwsStateError);
  });

  test('unknown projection and action are explicit rather than successful', () {
    final absent =
        _build(projection: {..._projection(), 'events': []}).toJson();
    expect(((absent['events'] as List).single as Map)['converterDecision'],
        'notAssessed');
    final unknown = _build(mutations: [
      _mutation('unknown.action', {'id': 'actor'})
    ]).toJson();
    expect(((unknown['events'] as List).single as Map)['nativeComparison'],
        'notAssessed');
  });

  test('unknown producer decision is not certified as a supported translation',
      () {
    final projection = _projection();
    ((projection['events'] as List).single as Map)['status'] = 'futureStatus';
    final event = (_build(projection: projection).toJson()['events'] as List)
        .single as Map;
    expect(event['converterDecision'], 'notAssessed');
    expect(event['rawConverterDecision'], 'futureStatus');
  });

  test('rejects stale page census and duplicate mutation identities', () {
    final projection = _projection();
    ((projection['events'] as List).single as Map)['pages'] = [];
    expect(() => _build(projection: projection), throwsStateError);
    final mutation = _mutation(
        'entity.upsert', {'mapId': 'map', 'entity': _entity().toJson()});
    expect(() => _build(mutations: [mutation, mutation]), throwsStateError);
  });

  test('rejects a foreign source file or page reference with the same IDs', () {
    final wrongFile = _projection();
    final event = (wrongFile['events'] as List).single as Map;
    event['locator'] = {
      ...Map<String, Object?>.from(event['locator'] as Map),
      'file': 'Data/Map999.rxdata',
    };
    expect(() => _build(projection: wrongFile), throwsStateError);
    final wrongPage = _projection();
    final page =
        (((wrongPage['events'] as List).single as Map)['pages'] as List).single
            as Map;
    page['rawDataRef'] = {'contentHash': 'different'};
    expect(() => _build(projection: wrongPage), throwsStateError);
  });

  test('duplicate native map identities and incomplete map census are rejected',
      () {
    expect(() => _build(maps: [_map(), _map()]), throwsStateError);
    expect(() => _build(maps: []), throwsStateError);
  });

  test('entity presentation overlays are folded before comparing final state',
      () {
    final entity = _entity();
    final result = _build(mutations: [
      _mutation('entity.upsert', {'mapId': 'map', 'entity': entity.toJson()}),
      _mutation('entity.set_presentation',
          {'mapId': 'map', 'entityId': 'actor', 'presentation': null},
          id: 'presentation'),
    ]).toJson();
    expect(((result['events'] as List).single as Map)['nativeComparison'],
        'match');
  });

  test('source and producer evidence survive without raw dialogue bodies', () {
    final inventory = _inventory();
    final source = (inventory['events'] as List).single as Map;
    source.addAll(<String, Object>{
      'x': 4,
      'y': 2,
      'roles': ['controller']
    });
    final sourcePage = (source['pages'] as List).single as Map;
    sourcePage.addAll(<String, Object>{
      'trigger': 'autorun',
      'triggerCode': 3,
      'condition': {'kind': 'always'},
      'selection': {'higherPageWins': true},
      'expectedBehaviorSignals': [
        {'kind': 'dialogue'}
      ],
      'diagnostics': [
        {'code': 'review.source'}
      ],
      'sourceAdaptations': [
        {'kind': 'sourceCorrection'}
      ],
      'rawCommands': ['dialogue body'],
    });
    final projection = _projection();
    final projected = (projection['events'] as List).single as Map;
    projected.addAll(<String, Object>{
      'nativeProgramKinds': ['nativeProgram'],
      'nativeProgramEvidence': {
        'nativeProgram': {'hash': _snapshot}
      },
    });
    ((projected['pages'] as List).single as Map)['adaptedCommands'] = [
      {'kind': 'showText', 'evidenceHash': _normalization}
    ];
    final event = (_build(inventory: inventory, projection: projection)
            .toJson()['events'] as List)
        .single as Map;
    expect(event['x'], 4);
    expect(event['roles'], ['controller']);
    expect(event['nativeProgramKinds'], ['nativeProgram']);
    final page = (event['pages'] as List).single as Map;
    expect(page['trigger'], 'autorun');
    expect(page['condition'], {'kind': 'always'});
    expect(page['diagnostics'], sourcePage['diagnostics']);
    expect(page['sourceAdaptations'], sourcePage['sourceAdaptations']);
    expect(page['adaptedCommands'], hasLength(1));
    expect(page.containsKey('rawCommands'), isFalse);
    expect(page['nativeComparisonScope'], 'selectedExpectedObjectsOnly');
    expect((page['coverage'] as Map)['pageNativeCoverageCertified'], isFalse);
    expect((page['coverage'] as Map)['sharedExpectedCount'], 1);
    expect((page['witness'] as Map)['runtimeProof'], 'notReplayed');
  });

  test('shop mutations use the writer value parameter', () {
    const shop = ShopDefinition(id: 'shop', label: 'Shop');
    final event = (_build(
      project: _project.copyWith(shops: [shop]),
      mutations: [
        _mutation('campaign.shop.upsert', {'value': shop.toJson()},
            target: 'shop')
      ],
    ).toJson()['events'] as List)
        .single as Map;
    expect(event['nativeComparison'], 'match');
  });

  test('refuses conflicting target ownership and projected namespace', () {
    final entity =
        _entity().copyWith(properties: {'sourceEventIdentity': 'other'});
    expect(
        () => _build(mutations: [
              _mutation(
                  'entity.upsert', {'mapId': 'map', 'entity': entity.toJson()})
            ]),
        throwsStateError);
    expect(
        () => _build(mutations: [
              _mutation('entity.upsert',
                  {'mapId': 'map', 'entity': _entity().toJson()},
                  target: 'wrong')
            ]),
        throwsStateError);
    expect(
        () => _build(
            projection: {..._projection(), 'logicalProjectNamespace': 'other'}),
        throwsStateError);
  });
}

SourceInteractionReconciliation _build(
        {Map<String, Object?>? inventory,
        Map<String, Object?>? projection,
        List<NativeMutation>? mutations,
        ProjectManifest? project,
        List<MapData>? maps,
        String namespace = 'synthetic',
        String projectionRevision = 'revision'}) =>
    SourceInteractionReconciliation.build(
        inventory: inventory ?? _inventory(),
        projectionEvidence: projection ?? _projection(),
        expectedMutations: mutations ??
            [
              _mutation('entity.upsert',
                  {'mapId': 'map', 'entity': _entity().toJson()})
            ],
        observedProject: project ?? _project,
        observedMaps: maps ?? [_map()],
        toolRevision: 'revision',
        projectionToolRevision: projectionRevision,
        logicalProjectNamespace: namespace,
        sourceSnapshotHash: _snapshot,
        normalizationHash: _normalization,
        sourceProfileHash: _profile);

Map<String, Object?> _inventory() => {
      'kind': 'sourceInteractionInventory',
      'schemaVersion': 1,
      'toolRevision': 'revision',
      'logicalProjectNamespace': 'synthetic',
      'sourceSnapshotHash': _snapshot,
      'normalizationHash': _normalization,
      'analysisProfileHash': _profile,
      'mapCount': 1,
      'eventCount': 1,
      'pageCount': 1,
      'events': [
        {
          'sourceIdentity': _identity,
          'sourceMapId': 1,
          'sourceEventId': 1,
          'name': 'Passive',
          'mapName': 'Original',
          'locator': {'mapId': 1, 'eventId': 1},
          'pages': [
            {
              'originalPageIndex': 0,
              'commandBodyEmpty': true,
              'roles': ['passiveCandidate']
            }
          ],
        }
      ],
    };

Map<String, Object?> _projection() => {
      'toolRevision': 'revision',
      'logicalProjectNamespace': 'synthetic',
      'sourceSnapshotHash': _snapshot,
      'normalizationHash': _normalization,
      'sourceProfileHash': _profile,
      'events': [
        {
          'sourceIdentity': _identity,
          'locator': {'mapId': 1, 'eventId': 1},
          'status': 'adaptedStaticSemantics',
          'gaps': <String>[],
          'pages': [
            {'originalPageIndex': 0, 'nativeEventId': _recordId('page_0')}
          ],
        }
      ],
    };

const _project = ProjectManifest(name: 'Native', maps: [
  ProjectMapEntry(id: 'map', name: 'Native', relativePath: 'maps/map.json')
], tilesets: []);

MapData _map({List<MapEntity>? entities}) => MapData(
    id: 'map',
    name: 'Native',
    size: const GridSize(width: 3, height: 3),
    layers: const [],
    entities: entities ?? [_entity()]);

MapEntity _entity({String name = 'Passive'}) => MapEntity(
    id: 'actor',
    name: name,
    kind: MapEntityKind.custom,
    pos: const GridPos(x: 1, y: 1),
    properties: const {'sourceEventIdentity': _identity});

NativeMutation _mutation(String action, Map<String, Object?> parameters,
        {String id = 'operation', String target = 'actor'}) =>
    NativeMutation(
        operationId: ConverterId(id),
        actionId: action,
        sourceEntityIds: [ConverterId(_identity)],
        targetEntityIds: [ConverterId(target)],
        parameters: parameters);

String _recordId(String role) {
  final hash = canonicalHashOf(
      {'namespace': 'synthetic', 'mapId': 1, 'eventId': 1, 'role': role}).value;
  return 'evt_${hash.substring(0, 8)}-${hash.substring(8, 12)}-7${hash.substring(13, 16)}-8${hash.substring(17, 20)}-${hash.substring(20, 32)}';
}
