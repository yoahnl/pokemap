import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_metadata_documents.dart';

import '../support/catalog_unit_reads.dart';
import '../support/map_directory_fixture.dart';
import '../support/narrative_title_fixture.dart';

Future<AuthoringQueryPage> readDialogue(
  NarrativeTitleFixture fixture, {
  bool wire = false,
  String id = 'greet',
  Map<String, Object?> filters = const {},
}) async {
  final handles = WorkspaceHandleStore();
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
      allowedRootPaths: [fixture.root.path], fileReader: reader);
  final api = AuthoringReadApi(
      openService: ProjectOpenService(
          policy: policy,
          fileReader: reader,
          handles: handles,
          initializeSceneOwners: false,
          catalogMetadataFields: const {}),
      snapshotLoader: ProjectSnapshotLoader(handles: handles));
  final opened = await api.openProject(fixture.root.path);
  try {
    final request = AuthoringQueryRequest(
        resourceKind: 'dialogueDocument',
        operation: AuthoringQueryOperation.get,
        view: AuthoringQueryView.detail,
        ids: [id],
        filters: filters);
    if (!wire) return await api.queryProject(opened.projectHandle, request);
    final response = AuthoringResult.fromJson(
        jsonDecode(await JsonlWorker(api: api).processLine(jsonEncode({
      'id': 'dialogue',
      'command': 'query',
      'args': {
        'projectHandle': opened.projectHandle.value,
        'request': request.toJson(),
      }
    }))) as Map<String, dynamic>);
    expect(response.status, AuthoringResultStatus.success,
        reason: response.error?.message);
    return AuthoringQueryPage.fromJson(
        Map<String, dynamic>.from(response.data));
  } finally {
    await api.closeWorkspace(opened.workspaceHandle);
  }
}

void main() {
  for (final wire in [false, true]) {
    test('one dialogue exposes source, revision and scoped usages JSONL=$wire',
        () async {
      final fixture = await createMapDirectoryFixture();
      addTearDown(fixture.close);
      final head = File('${fixture.root.path}/catalog/HEAD.json');
      final before = await head.readAsBytes();
      final item = (await readDialogue(fixture, wire: wire)).items.single;
      expect((item['entry'] as Map)['id'], 'greet');
      expect(item['source'], contains('Welcome to the lab.'));
      expect(
          item['revision'],
          narrativeEventBytesFingerprint(
              await File('${fixture.root.path}/dialogues/greet.yarn')
                  .readAsBytes()));
      final usages = item['usages'] as Map;
      expect(usages['sceneIds'], ['scene_talk']);
      expect((usages['notCovered'] as List), isNotEmpty);
      expect(item['reads'], {'dialogues': 1, 'scenes': 0, 'maps': 0});
      expect(await head.readAsBytes(), before);
    });
  }

  test('invalid scope and an unknown dialogue fail explicitly', () async {
    final fixture = await createMapDirectoryFixture();
    addTearDown(fixture.close);
    Matcher code(String value) => isA<AuthoringQueryException>()
        .having((error) => error.code, 'code', value);
    await expectLater(readDialogue(fixture, filters: {'extra': true}),
        throwsA(code('query.dialogue_document_scope_invalid')));
    await expectLater(readDialogue(fixture, id: 'missing'),
        throwsA(code('query.resource_not_found')));
  });

  test('a missing source preserves the document and known references',
      () async {
    final fixture = await createMapDirectoryFixture();
    addTearDown(fixture.close);
    await File('${fixture.root.path}/dialogues/greet.yarn').delete();
    final item = (await readDialogue(fixture)).items.single;
    expect((item['entry'] as Map)['id'], 'greet');
    expect(item['source'], isNull);
    expect(item['revision'], isNull);
    expect(await File('${fixture.root.path}/dialogues/greet.yarn').exists(),
        isFalse);
    expect((item['usages'] as Map)['sceneIds'], ['scene_talk']);
  });

  test('unprepared dialogue metadata is refused without rebuilding it',
      () async {
    final fixture = await createMapDirectoryFixture();
    addTearDown(fixture.close);
    await alterDialogueFixture(fixture, (_) async => [], removals: [
      CatalogMetadataDocuments.fieldKey('dialogues'),
    ]);
    final head =
        await File('${fixture.root.path}/catalog/HEAD.json').readAsBytes();
    await expectLater(
        readDialogue(fixture),
        throwsA(isA<AuthoringQueryException>().having((error) => error.code,
            'code', 'query.dialogue_document_preparation_required')));
    expect(await File('${fixture.root.path}/catalog/HEAD.json').readAsBytes(),
        head);
  });

  test('an unavailable usage index is distinct from known empty usages',
      () async {
    final fixture = await createMapDirectoryFixture();
    addTearDown(fixture.close);
    await alterDialogueFixture(fixture, (snapshot) async {
      final key = CatalogMetadataDocuments.fieldKey('scenes');
      return [
        CatalogDefinitionUnit(
            key: key,
            payload: {
              ...(await snapshot.lookup(key))!.payload,
            }..remove('sceneDialogueReferencesVersion'))
      ];
    });
    final item = (await readDialogue(fixture)).items.single;
    expect(item['source'], isA<String>());
    expect((item['usages'] as Map)['sceneIds'], isEmpty);
    expect(
        (item['usages'] as Map)['notCovered'], contains('sceneDialogueIndex'));
    final base = mapDirectoryProject(2);
    final empty = await NarrativeTitleFixture.create(
        project: base.copyWith(
      scenes: base.scenes.where((scene) => scene.id != 'scene_talk').toList(),
    ));
    addTearDown(empty.close);
    await writeMapDirectoryFiles(empty.root, 2);
    final unused = (await readDialogue(empty)).items.single;
    expect((unused['usages'] as Map)['sceneIds'], isEmpty);
    expect((unused['usages'] as Map)['notCovered'],
        isNot(contains('sceneDialogueIndex')));
  });

  test('unsupported stored localization is not mislabeled as index preparation',
      () async {
    final fixture = await createMapDirectoryFixture();
    addTearDown(fixture.close);
    await alterDialogueFixture(fixture, (snapshot) async {
      final key = CatalogMetadataDocuments.definitionKey('dialogues', 0);
      final unit = (await snapshot.lookup(key))!;
      final value = Map<String, Object?>.from(unit.payload['value'] as Map);
      final definition = Map<String, Object?>.from(value['definition'] as Map);
      definition['localization'] = {
        'format': 999,
        'sourceLocale': 'fr',
        'units': []
      };
      final changed = CatalogDefinitionUnit(key: key, payload: {
        ...unit.payload,
        'value': {...value, 'definition': definition},
      });
      final rowKey = CatalogMetadataDocuments.documentKey('dialogues', 'greet');
      final row = (await snapshot.lookup(rowKey))!;
      return [
        changed,
        CatalogDefinitionUnit(key: rowKey, payload: {
          ...row.payload,
          'fingerprint': computeAuthoringJsonFingerprint(changed.toJson(),
              logicalName: 'metadata-document'),
        })
      ];
    });
    final before =
        await File('${fixture.root.path}/catalog/HEAD.json').readAsBytes();
    await expectLater(readDialogue(fixture), throwsA(isA<FormatException>()));
    expect(await File('${fixture.root.path}/catalog/HEAD.json').readAsBytes(),
        before);
  });

  test('unrelated maps and definitions do not increase document read work',
      () async {
    Future<Map<String, int>> reads(int maps) async {
      final base = mapDirectoryProject(maps);
      final fixture = await NarrativeTitleFixture.create(
          project: base.copyWith(
        dialogues: [
          ...base.dialogues,
          for (var i = 0; i < maps; i++)
            base.dialogues.single.copyWith(
                id: 'unrelated_$i',
                relativePath: 'dialogues/unrelated_$i.yarn'),
        ],
        scenes: [
          ...base.scenes,
          for (var i = 0; i < maps; i++)
            SceneAsset(
                id: 'unrelated_scene_$i',
                name: 'Unrelated $i',
                graph: base.scenes.first.graph),
        ],
      ));
      await writeMapDirectoryFiles(fixture.root, maps);
      try {
        final outside = Zone.current;
        var mapReads = 0;
        var sourceReads = 0;
        late Map<String, int> units;
        await IOOverrides.runZoned(() async {
          units = await CatalogUnitReads(fixture.root).count(() async {
            await readDialogue(fixture);
          });
        }, createFile: (path) {
          if (path.contains('/maps/')) mapReads++;
          if (path.endsWith('.yarn')) sourceReads++;
          return outside.run(() => File(path));
        });
        expect(mapReads, 0);
        expect(sourceReads, greaterThan(0));
        return units;
      } finally {
        await fixture.close();
      }
    }

    expect(await reads(60), await reads(2));
  }, timeout: const Timeout(Duration(minutes: 4)));
}

Future<void> alterDialogueFixture(
  NarrativeTitleFixture fixture,
  Future<List<CatalogDefinitionUnit>> Function(CatalogSnapshot) change, {
  List<CatalogDefinitionKey> removals = const [],
}) async {
  final store = await CatalogStorageStore.open(projectRoot: fixture.root.path);
  final snapshot = await fixture.snapshot();
  final patch =
      await snapshot.patch(upserts: await change(snapshot), removals: removals);
  await store.gateway.withExclusiveWriteLock(() async {
    await store.publishObjectsUnderLock(patch.objects);
    await File('${fixture.root.path}/catalog/HEAD.json')
        .writeAsBytes(CatalogStorageStore.encodeHead(patch.root));
    final updated = (await store.openRoot(patch.root)).snapshot;
    await updated.validate();
    await store.publishIndexAdmissionUnderLock(updated);
    await store.publishMetadataIndexAdmissionUnderLock(updated);
  });
}
