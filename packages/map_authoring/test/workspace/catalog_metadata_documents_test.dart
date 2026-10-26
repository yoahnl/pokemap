import 'dart:convert';

import 'package:map_authoring/src/workspace/catalog/catalog_metadata_documents.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
      'Fact identity indexes require explicit preparation and never self-certify on a local edit',
      () async {
    final fixture =
        _Fixture.units([_definition(0, 'enabled', alias: 'shared')]);
    final snapshot = await fixture.open();
    final stateKey = CatalogMetadataDocuments.fieldKey('facts');
    final payload = {...(await snapshot.lookup(stateKey))!.payload}
      ..remove('factRuntimeIdentitiesVersion');
    final patch = await snapshot.patch(
        upserts: [CatalogDefinitionUnit(key: stateKey, payload: payload)]);
    fixture.objects.addAll(patch.objects);
    fixture.root = patch.root;
    final reopened = await fixture.open();
    fixture.readDefinitions.clear();
    await expectLater(
        CatalogMetadataDocuments.readFactIdsForRuntimeIdentity(
            snapshot: reopened, runtimeIdentity: 'shared'),
        throwsA(isA<FormatException>().having((error) => error.message,
            'message', contains('preparation_required'))));
    expect(fixture.readDefinitions, isEmpty);
    final maintained = await CatalogMetadataDocuments.maintain(
        lookup: reopened.lookup,
        upserts: [_definition(0, 'enabled', alias: 'other')]);
    final state = maintained.singleWhere((unit) => unit.key == stateKey);
    expect(state.payload.containsKey('factRuntimeIdentitiesVersion'), isFalse);
    expect(
        maintained.any((unit) =>
            unit.key ==
            CatalogMetadataDocuments.factRuntimeIdentityKey('other')),
        isFalse);
  });
  for (final unrelated in [0, 900]) {
    test(
        'Fact identity facets select and maintain aliases with $unrelated unrelated Facts',
        () async {
      final fixture = _Fixture.units([
        _definition(0, 'enabled', alias: 'shared'),
        _definition(1, 'conflict', alias: 'shared'),
        for (var i = 0; i < unrelated; i++) _definition(i + 2, 'unused_$i'),
      ]);
      final snapshot = await fixture.open();
      fixture.readDefinitions.clear();
      fixture.readUnits.clear();
      expect(
          await CatalogMetadataDocuments.readFactIdsForRuntimeIdentity(
              snapshot: snapshot, runtimeIdentity: 'shared'),
          {'enabled', 'conflict'});
      expect(fixture.readDefinitions, isEmpty);
      expect(fixture.readUnits, [
        CatalogMetadataDocuments.fieldKey('facts'),
        CatalogMetadataDocuments.factRuntimeIdentityKey('shared')
      ]);
      final changes = [_definition(0, 'enabled', alias: 'other')];
      final maintained = await CatalogMetadataDocuments.maintain(
          lookup: snapshot.lookup, upserts: changes);
      final patch = await snapshot.patch(upserts: [...changes, ...maintained]);
      fixture.objects.addAll(patch.objects);
      fixture.root = patch.root;
      final reopened = await fixture.open();
      expect(
          await CatalogMetadataDocuments.readFactIdsForRuntimeIdentity(
              snapshot: reopened, runtimeIdentity: 'shared'),
          {'conflict'});
      expect(
          await CatalogMetadataDocuments.readFactIdsForRuntimeIdentity(
              snapshot: reopened, runtimeIdentity: 'other'),
          {'enabled'});
    });
  }
  for (final unrelated in [0, 900]) {
    test(
        'step owner facets remain targeted with $unrelated unrelated storylines',
        () async {
      final fixture = _Fixture.units([
        _storyline(0, 'owner', ['prepare']),
        _storyline(1, 'shared', ['prepare']),
        for (var i = 0; i < unrelated; i++)
          _storyline(i + 2, 'unused-$i', ['unused-step-$i']),
      ]);
      for (var attempt = 0; attempt < 2; attempt++) {
        final snapshot = await fixture.open();
        fixture.readDefinitions.clear();
        fixture.readUnits.clear();
        expect(
            await CatalogMetadataDocuments.readStorylineIdsForStep(
                snapshot: snapshot, stepId: 'prepare'),
            {'owner', 'shared'});
        expect(fixture.readDefinitions, isEmpty);
        expect(fixture.readUnits, [
          CatalogMetadataDocuments.fieldKey('storylines'),
          CatalogMetadataDocuments.storylineStepKey('prepare')
        ]);
      }
      final snapshot = await fixture.open();
      fixture.readDefinitions.clear();
      final changes = [
        _storyline(0, 'owner', ['new']),
        _storyline(unrelated + 2, 'appended', ['new'])
      ];
      final indexChanges = await CatalogMetadataDocuments.maintain(
          lookup: snapshot.lookup, upserts: changes);
      expect(fixture.readDefinitions, [0]);
      final patch =
          await snapshot.patch(upserts: [...changes, ...indexChanges]);
      fixture.objects.addAll(patch.objects);
      fixture.root = patch.root;
      final reopened = await fixture.open();
      fixture.readDefinitions.clear();
      expect(
          await CatalogMetadataDocuments.readStorylineIdsForStep(
              snapshot: reopened, stepId: 'prepare'),
          {'shared'});
      expect(
          await CatalogMetadataDocuments.readStorylineIdsForStep(
              snapshot: reopened, stepId: 'new'),
          {'owner', 'appended'});
      expect(
          await CatalogMetadataDocuments.readStorylineIdsForStep(
              snapshot: reopened, stepId: 'absent'),
          isEmpty);
      expect(fixture.readDefinitions, isEmpty);
    });
  }
  test('step owner facets require explicit preparation of old indexes',
      () async {
    final fixture = _Fixture.units([
      _storyline(0, 'owner', ['prepare'])
    ]);
    final snapshot = await fixture.open();
    final key = CatalogMetadataDocuments.fieldKey('storylines');
    final payload = {...(await snapshot.lookup(key))!.payload}
      ..remove('stepReferencesVersion');
    final patch = await snapshot
        .patch(upserts: [CatalogDefinitionUnit(key: key, payload: payload)]);
    fixture.objects.addAll(patch.objects);
    fixture.root = patch.root;
    final reopened = await fixture.open();
    fixture.readDefinitions.clear();
    await expectLater(
        CatalogMetadataDocuments.readStorylineIdsForStep(
            snapshot: reopened, stepId: 'prepare'),
        throwsA(isA<FormatException>().having((error) => error.message,
            'message', contains('preparation_required'))));
    final maintained = await CatalogMetadataDocuments.maintain(
        lookup: reopened.lookup,
        upserts: [
          _storyline(0, 'owner', ['new'])
        ]);
    expect(maintained.single.payload['valid'], isFalse);
    expect(fixture.readDefinitions, isEmpty);
  });
  test('scene dialogue facets are explicitly prepared from typed scene nodes',
      () {
    final units = [
      _scene(0, 'selected', ['dialogue', 'dialogue'])
    ];
    final index = CatalogMetadataDocuments.initialize(units);
    final state = index.singleWhere(
        (row) => row.key == CatalogMetadataDocuments.fieldKey('scenes'));
    expect(state.payload['sceneDialogueReferencesVersion'], 1);
    final facet = index.singleWhere((row) =>
        row.key ==
        CatalogDefinitionKey(CatalogDefinitionKind.workspaceState,
            jsonEncode(['sceneDialogue', 'dialogue'])));
    expect(facet.payload['sceneIds'], ['selected']);
  });

  for (final unrelated in [0, 900]) {
    test(
        'scene dialogue lookup stays targeted with $unrelated unrelated scenes',
        () async {
      final fixture = _Fixture.units([
        _scene(0, 'selected', ['old', 'old']),
        _scene(1, 'shared', ['old']),
        for (var i = 0; i < unrelated; i++)
          _scene(i + 2, 'unused-$i', ['unused-dialogue-$i']),
      ]);
      for (var attempt = 0; attempt < 2; attempt++) {
        final snapshot = await fixture.open();
        fixture.readDefinitions.clear();
        fixture.readUnits.clear();
        expect(
            await CatalogMetadataDocuments.readSceneIdsForDialogue(
                snapshot: snapshot, dialogueId: 'old'),
            {'selected', 'shared'});
        expect(fixture.readUnits.toSet(), {
          CatalogMetadataDocuments.fieldKey('scenes'),
          CatalogMetadataDocuments.sceneDialogueKey('old'),
        });
        expect(fixture.readUnits.length, 2);
        expect(
            await CatalogMetadataDocuments.readSceneIdsForDialogue(
                snapshot: snapshot, dialogueId: 'absent'),
            isEmpty);
        expect(fixture.readDefinitions, isEmpty);
      }
      final snapshot = await fixture.open();
      fixture.readDefinitions.clear();
      final changed = _scene(0, 'selected', ['new']);
      final appended = _scene(unrelated + 2, 'appended', ['new']);
      final auxiliary = await CatalogMetadataDocuments.maintain(
          lookup: snapshot.lookup, upserts: [changed, appended]);
      expect(fixture.readDefinitions, [0]);
      final patch =
          await snapshot.patch(upserts: [changed, appended, ...auxiliary]);
      fixture.objects.addAll(patch.objects);
      fixture.root = patch.root;
      final reopened = await fixture.open();
      fixture.readDefinitions.clear();
      expect(
          await CatalogMetadataDocuments.readSceneIdsForDialogue(
              snapshot: reopened, dialogueId: 'old'),
          {'shared'});
      expect(
          await CatalogMetadataDocuments.readSceneIdsForDialogue(
              snapshot: reopened, dialogueId: 'new'),
          {'selected', 'appended'});
      expect(fixture.readDefinitions, isEmpty);
      final removeReferences = [
        _scene(0, 'selected', []),
        _scene(unrelated + 2, 'appended', []),
      ];
      final removedAuxiliary = await CatalogMetadataDocuments.maintain(
          lookup: reopened.lookup, upserts: removeReferences);
      expect(
          removedAuxiliary
              .singleWhere((row) =>
                  row.key == CatalogMetadataDocuments.sceneDialogueKey('new'))
              .payload['sceneIds'],
          isEmpty);
      final removed = await reopened
          .patch(upserts: [...removeReferences, ...removedAuxiliary]);
      fixture.objects.addAll(removed.objects);
      fixture.root = removed.root;
      final last = await fixture.open();
      fixture.readDefinitions.clear();
      expect(
          await CatalogMetadataDocuments.readSceneIdsForDialogue(
              snapshot: last, dialogueId: 'new'),
          isEmpty);
      expect(fixture.readDefinitions, isEmpty);
    });
  }

  test('scene dialogue lookup refuses a missing preparation version', () async {
    final fixture = _Fixture.units([
      _scene(0, 'selected', ['dialogue'])
    ]);
    final snapshot = await fixture.open();
    final key = CatalogMetadataDocuments.fieldKey('scenes');
    final state = await snapshot.lookup(key);
    final payload = {...state!.payload}
      ..remove('sceneDialogueReferencesVersion');
    final patch = await snapshot
        .patch(upserts: [CatalogDefinitionUnit(key: key, payload: payload)]);
    fixture.objects.addAll(patch.objects);
    fixture.root = patch.root;
    final reopened = await fixture.open();
    fixture.readDefinitions.clear();
    await expectLater(
        CatalogMetadataDocuments.readSceneIdsForDialogue(
            snapshot: reopened, dialogueId: 'dialogue'),
        throwsA(isA<FormatException>().having((error) => error.message,
            'message', contains('preparation_required'))));
    await expectLater(
        CatalogMetadataDocuments.readDocuments(
            snapshot: reopened,
            project: const ProjectManifest(
                name: 'Documents', maps: [], tilesets: []),
            ids: {
              'scenes': {'selected'}
            }),
        throwsA(isA<FormatException>()));
    final maintained = await CatalogMetadataDocuments.maintain(
        lookup: reopened.lookup,
        upserts: [
          _scene(0, 'selected', ['changed'])
        ]);
    expect(maintained.single.payload['valid'], isFalse);
    expect(fixture.readDefinitions, isEmpty);
  });

  test(
      'trainer ball facets include ball and battle items but exclude held rewards',
      () async {
    final fixture = _Fixture.units(
        [_trainer(0, 'selected', itemId: 'medicine', ballItemId: 'ball')]);
    final snapshot = await fixture.open();
    expect(
        await CatalogMetadataDocuments.readTrainerIds(
            snapshot: snapshot, itemId: 'ball'),
        {'selected'});
    expect(
        await CatalogMetadataDocuments.readTrainerIds(
            snapshot: snapshot, itemId: 'medicine'),
        {'selected'});
    expect(
        await CatalogMetadataDocuments.readTrainerIds(
            snapshot: snapshot, itemId: 'held'),
        isEmpty);
  });

  test('unindexed append is detected without reading existing documents',
      () async {
    final fixture = _Fixture(900);
    final snapshot = await fixture.open();
    final patch =
        await snapshot.patch(upserts: [_definition(901, 'unindexed')]);
    fixture.objects.addAll(patch.objects);
    fixture.root = patch.root;
    final reopened = await fixture.open();
    fixture.readDefinitions.clear();
    await expectLater(
        CatalogMetadataDocuments.readDocuments(
            snapshot: reopened,
            project: const ProjectManifest(
                name: 'Documents', maps: [], tilesets: []),
            ids: {
              'facts': {'selected'}
            }),
        throwsA(isA<FormatException>().having(
            (error) => error.message, 'message', contains('index_stale'))));
    expect(fixture.readDefinitions, [901]);
  });

  test(
      'identity changes invalidate the field without looking up unrelated documents',
      () async {
    final fixture = _Fixture(900);
    final snapshot = await fixture.open();
    fixture.readDefinitions.clear();
    final changed = _definition(0, 'renamed');
    final auxiliary = await CatalogMetadataDocuments.maintain(
        lookup: snapshot.lookup, upserts: [changed]);
    expect(fixture.readDefinitions, [0]);
    final state = auxiliary.singleWhere(
        (unit) => unit.key == CatalogMetadataDocuments.fieldKey('facts'));
    expect(state.payload['valid'], isFalse);
  });

  test(
      'preparation supports diagnostic identities without changing document data',
      () {
    final key = _definitionKey('narrativeDiagnosticSuppressions', 0);
    final unit = CatalogDefinitionUnit(key: key, payload: {
      'section': r'$projectDefinition',
      'id': key.id,
      'position': 0,
      'value': {
        'field': 'narrativeDiagnosticSuppressions',
        'definition': {'diagnosticId': 'issue'}
      }
    });
    final index = CatalogMetadataDocuments.initialize([unit]);
    expect(
        index.any((row) =>
            row.key ==
            CatalogMetadataDocuments.documentKey(
                'narrativeDiagnosticSuppressions', 'issue')),
        isTrue);
    expect(unit.payload['value'], {
      'field': 'narrativeDiagnosticSuppressions',
      'definition': {'diagnosticId': 'issue'}
    });
  });

  for (final unrelated in [0, 900]) {
    test(
        'trainer facets select actual dependencies among $unrelated unrelated trainers',
        () async {
      final units = [
        _trainer(0, 'selected', itemId: 'ball', doubles: true),
        for (var i = 0; i < unrelated; i++) _trainer(i + 1, 'unused-$i'),
      ];
      final fixture = _Fixture.units(units);
      final snapshot = await fixture.open();
      fixture.readDefinitions.clear();
      expect(
          await CatalogMetadataDocuments.readTrainerIds(
              snapshot: snapshot, itemId: 'ball'),
          {'selected'});
      expect(
          await CatalogMetadataDocuments.readTrainerIds(
              snapshot: snapshot, doublesOnly: true),
          {'selected'});
      expect(
          await CatalogMetadataDocuments.readTrainerIds(
              snapshot: snapshot, itemId: 'unused-item'),
          isEmpty);
      expect(fixture.readDefinitions, isEmpty);
      final changed = _trainer(0, 'selected', itemId: 'medicine');
      final auxiliary = await CatalogMetadataDocuments.maintain(
          lookup: snapshot.lookup, upserts: [changed]);
      expect(fixture.readDefinitions, [0]);
      final patch = await snapshot.patch(upserts: [changed, ...auxiliary]);
      fixture.objects.addAll(patch.objects);
      fixture.root = patch.root;
      final reopened = await fixture.open();
      fixture.readDefinitions.clear();
      expect(
          await CatalogMetadataDocuments.readTrainerIds(
              snapshot: reopened, itemId: 'ball'),
          isEmpty);
      expect(
          await CatalogMetadataDocuments.readTrainerIds(
              snapshot: reopened, itemId: 'medicine'),
          {'selected'});
      expect(
          await CatalogMetadataDocuments.readTrainerIds(
              snapshot: reopened, doublesOnly: true),
          isEmpty);
      expect(fixture.readDefinitions, isEmpty);
    });
  }

  for (final unrelated in [0, 900]) {
    test('first and reopened reads select one of $unrelated unrelated facts',
        () async {
      final fixture = _Fixture(unrelated);
      for (var attempt = 0; attempt < 2; attempt++) {
        fixture.readDefinitions.clear();
        final snapshot = await fixture.open();
        final selected = await CatalogMetadataDocuments.readDocuments(
          snapshot: snapshot,
          project:
              const ProjectManifest(name: 'Documents', maps: [], tilesets: []),
          ids: {
            'facts': {'selected', 'absent'}
          },
        );
        expect(selected.project.facts.single.id, 'selected');
        expect(selected.counts['facts'], unrelated + 1);
        expect(
            selected.documents['facts']!['selected']!.payload['position'], 0);
        expect(selected.documents['facts']!['absent'], isNull);
        expect(fixture.readDefinitions, [0]);
      }
    });

    test(
        'updates and appends preserve unknown fields with $unrelated unrelated facts',
        () async {
      final fixture = _Fixture(unrelated);
      var snapshot = await fixture.open();
      final old = await snapshot.lookup(_definitionKey('facts', 0));
      final changed =
          _definition(0, 'selected', label: 'Updated', extra: 'keep');
      fixture.readDefinitions.clear();
      final auxiliary = await CatalogMetadataDocuments.maintain(
        lookup: snapshot.lookup,
        upserts: [changed, _definition(unrelated + 1, 'new')],
      );
      expect(fixture.readDefinitions.toSet(), {0});
      final patch = await snapshot.patch(
          upserts: [changed, _definition(unrelated + 1, 'new'), ...auxiliary]);
      fixture.objects.addAll(patch.objects);
      fixture.root = patch.root;
      snapshot = await fixture.open();
      final selected = await CatalogMetadataDocuments.readDocuments(
        snapshot: snapshot,
        project:
            const ProjectManifest(name: 'Documents', maps: [], tilesets: []),
        ids: {
          'facts': {'selected', 'new'}
        },
      );
      expect(old, isNotNull);
      expect(
          selected.project.facts.map((fact) => fact.id), ['selected', 'new']);
      expect(
          selected.documents['facts']!['selected']!.payload['future'], 'keep');
      expect(selected.counts['facts'], unrelated + 2);
    });
  }

  test('missing index requires explicit preparation', () async {
    final fixture = _Fixture(0, indexed: false);
    await expectLater(
        fixture.read(),
        throwsA(isA<FormatException>().having((error) => error.message,
            'message', contains('preparation_required'))));
  });

  test('stale row fingerprint and forged position are rejected', () async {
    for (final forgePosition in [false, true]) {
      final fixture = _Fixture(1);
      final snapshot = await fixture.open();
      final row = await snapshot
          .lookup(CatalogMetadataDocuments.documentKey('facts', 'selected'));
      final mutation = forgePosition
          ? CatalogDefinitionUnit(
              key: row!.key, payload: {...row.payload, 'position': 1})
          : _definition(0, 'selected', label: 'Changed outside index');
      final patch = await snapshot.patch(upserts: [mutation]);
      fixture.objects.addAll(patch.objects);
      fixture.root = patch.root;
      await expectLater(fixture.read(), throwsA(isA<FormatException>()));
    }
  });

  test('removal invalidates its field without reindexing other documents',
      () async {
    final fixture = _Fixture(900);
    final snapshot = await fixture.open();
    fixture.readDefinitions.clear();
    final auxiliary = await CatalogMetadataDocuments.maintain(
      lookup: snapshot.lookup,
      upserts: const [],
      removals: [_definitionKey('facts', 0)],
    );
    expect(fixture.readDefinitions, isEmpty);
    final patch = await snapshot.patch(upserts: auxiliary);
    fixture.objects.addAll(patch.objects);
    fixture.root = patch.root;
    await expectLater(
        fixture.read(),
        throwsA(isA<FormatException>().having((error) => error.message,
            'message', contains('preparation_required'))));
  });
}

CatalogDefinitionKey _definitionKey(String field, int position) =>
    CatalogDefinitionKey(
      CatalogDefinitionKind.catalogMetadata,
      jsonEncode(['projectDefinition', field, position]),
    );

CatalogDefinitionUnit _definition(int position, String id,
        {String? label, String? extra, String? alias}) =>
    CatalogDefinitionUnit(
      key: _definitionKey('facts', position),
      payload: {
        'section': r'$projectDefinition',
        'id': _definitionKey('facts', position).id,
        'position': position,
        if (extra != null) 'future': extra,
        'value': {
          'field': 'facts',
          'definition': NarrativeFactDefinition(
                  id: id, label: label ?? id, legacyFlagName: alias)
              .toJson()
        },
      },
    );

CatalogDefinitionUnit _trainer(int position, String id,
        {String? itemId, String? ballItemId, bool doubles = false}) =>
    CatalogDefinitionUnit(
      key: _definitionKey('trainers', position),
      payload: {
        'section': r'$projectDefinition',
        'id': _definitionKey('trainers', position).id,
        'position': position,
        'value': {
          'field': 'trainers',
          'definition': ProjectTrainerEntry(
              id: id,
              name: id,
              trainerClass: 'Trainer',
              battleFormat:
                  doubles ? BattleFormat.doubles : BattleFormat.singles,
              battleItems: itemId == null ? {} : {itemId: 1},
              team: [
                ProjectTrainerPokemonEntry(
                    speciesId: 'species',
                    level: 5,
                    ballItemId: ballItemId,
                    heldItemId: 'held')
              ]).toJson()
        },
      },
    );

CatalogDefinitionUnit _storyline(
        int position, String id, List<String> stepIds) =>
    CatalogDefinitionUnit(
        key: _definitionKey('storylines', position),
        payload: {
          'section': r'$projectDefinition',
          'id': _definitionKey('storylines', position).id,
          'position': position,
          'value': {
            'field': 'storylines',
            'definition': StorylineAsset(
                id: id,
                type: StorylineType.main,
                title: id,
                chapters: [
                  StorylineChapter(
                      id: 'chapter',
                      title: 'Chapter',
                      order: 0,
                      steps: [
                        for (var i = 0; i < stepIds.length; i++)
                          StorylineStep(
                              id: stepIds[i], title: stepIds[i], order: i),
                      ]),
                ]).toJson(),
          },
        });

CatalogDefinitionUnit _scene(
        int position, String id, List<String> dialogueIds) =>
    CatalogDefinitionUnit(
      key: _definitionKey('scenes', position),
      payload: {
        'section': r'$projectDefinition',
        'id': _definitionKey('scenes', position).id,
        'position': position,
        'value': {
          'field': 'scenes',
          'definition': SceneAsset(
            id: id,
            name: id,
            graph: SceneGraph(startNodeId: 'start', nodes: [
              SceneNode(id: 'start', kind: SceneNodeKind.start),
              for (var i = 0; i < dialogueIds.length; i++)
                SceneNode(
                    id: 'dialogue-$i',
                    kind: SceneNodeKind.yarnDialogue,
                    payload:
                        SceneYarnDialoguePayload(dialogueId: dialogueIds[i]))
            ], edges: const []),
          ).toJson()
        }
      },
    );

final class _Fixture {
  _Fixture(int unrelated, {bool indexed = true}) {
    final units = [
      _definition(0, 'selected', extra: 'keep'),
      for (var index = 0; index < unrelated; index++)
        _definition(index + 1, 'unused-$index'),
    ];
    final built = CatalogStorageBuilder().build(
        [...units, if (indexed) ...CatalogMetadataDocuments.initialize(units)]);
    objects.addAll(built.objects);
    root = built.root;
  }
  _Fixture.units(List<CatalogDefinitionUnit> units) {
    final built = CatalogStorageBuilder()
        .build([...units, ...CatalogMetadataDocuments.initialize(units)]);
    objects.addAll(built.objects);
    root = built.root;
  }
  final objects = <String, List<int>>{};
  final readDefinitions = <int>[];
  final readUnits = <CatalogDefinitionKey>[];
  late CatalogObjectReference root;

  Future<CatalogSnapshot> open() async {
    final snapshot = await CatalogSnapshot.open(
        root: root,
        readObject: (reference) async {
          final bytes = objects[reference.sha256]!;
          final json = jsonDecode(utf8.decode(bytes)) as Map;
          if (json['type'] == 'unit') {
            readUnits.add(CatalogDefinitionKey.fromJson(
                Map<String, dynamic>.from(json['key'] as Map)));
            final payload = json['payload'] as Map;
            if (payload['section'] == r'$projectDefinition') {
              readDefinitions.add(payload['position'] as int);
            }
          }
          return bytes;
        });
    return snapshot;
  }

  Future<CatalogMetadataDocumentSelection> read() async =>
      CatalogMetadataDocuments.readDocuments(
        snapshot: await open(),
        project:
            const ProjectManifest(name: 'Documents', maps: [], tilesets: []),
        ids: {
          'facts': {'selected'}
        },
      );
}
