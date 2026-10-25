import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring.dart';

import '../support/m3_story_fixture.dart';

void main() {
  late M3StoryFixture fixture;
  late LocalNarrativeAdapter port;
  setUp(() async {
    fixture = await M3StoryFixture.create();
    port = LocalNarrativeAdapter(
      session: fixture.session,
      mapAdapter: fixture.maps,
    );
  });
  tearDown(() => fixture.directory.delete(recursive: true));

  NarrativeEventRecord updated(NarrativeEventRecord record) {
    final json = record.toJson();
    return NarrativeEventRecord.fromJson({
      ...json,
      'definition': {
        ...Map<String, dynamic>.from(json['definition'] as Map),
        'priority': 42,
      },
    });
  }

  test('working scene edit resolves its story step owner', () async {
    final project = fixture.receipt.manifest;
    final store = await CatalogStorageStore.open(
      projectRoot: fixture.directory.path,
    );
    await WorkingProjectCatalog.create(
      store: store,
      expectedProjectRevision: await store.gateway.readResourceRevision(
        'project.json',
      ),
      projectId: 'story-scope',
      project: project,
    );
    await FileIdempotencyStore(
      filePath:
          '${fixture.directory.path}/.pokemap/authoring/idempotency.jsonl',
    ).prepareIncrementalStorage();
    final session = ProjectSession(
      sessionId: 'story-scope',
      name: project.name,
      directoryPath: fixture.directory.path,
      storage: ProjectSessionStorage.workingCatalog,
    );
    final maps = LocalMapWorkspaceAdapter();
    await maps.loadCatalog(session);
    final base = await maps.loadMap(session, project.maps.first);
    final original = project.eventRegistry!.records.first;
    final scene = project.scenes.singleWhere(
      (scene) => scene.id == original.definitionOrNull!.sceneId,
    );
    final updatedScene = SceneAsset.fromJson({
      ...scene.toJson(),
      'name': 'Updated story scene',
    });
    final receipt =
        await LocalNarrativeAdapter(session: session, mapAdapter: maps).publish(
          NarrativePublication(
            base: base,
            current: base.map,
            scenes: [updatedScene],
            expectedScenes: {scene.id: scene},
          ),
        );
    expect(receipt.manifest.scenes, contains(updatedScene));
    expect(receipt.manifest.storylines, containsAll(project.storylines));
    final reopened = LocalMapWorkspaceAdapter();
    final fresh = await reopened.loadProject(session);
    expect(
      fresh.scenes.singleWhere((entry) => entry.id == scene.id),
      updatedScene,
    );
    expect(fresh.storylines, project.storylines);
  });

  test('stale record-only write rejected inside mutation queue with unchanged scene', () async {
    final original = fixture.receipt.manifest.eventRegistry!.records.first;
    final scene = fixture.receipt.manifest.scenes.firstWhere(
      (scene) => scene.id == original.definitionOrNull!.sceneId,
    );
    final base = await fixture.maps.loadMap(
      fixture.session,
      fixture.receipt.manifest.maps.first,
    );
    final fresh = updated(original);
    final receipt = await port.publish(
      NarrativePublication(
        base: base,
        current: base.map,
        events: [fresh],
        expectedEvents: {original.id: original},
      ),
    );
    expect(receipt.manifest.scenes, fixture.receipt.manifest.scenes);
    final projectFile = File('${fixture.directory.path}/project.json');
    final before = await projectFile.readAsBytes();
    await expectLater(
      port.publish(
        NarrativePublication(
          base: base,
          current: base.map,
          events: [original],
          scenes: [scene],
          expectedEvents: {original.id: original},
          expectedScenes: {scene.id: scene},
        ),
      ),
      throwsA(
        isA<NarrativeFailure>().having(
          (e) => e.message,
          'record guard',
          contains('événement'),
        ),
      ),
    );
    expect(await projectFile.readAsBytes(), before);
    final reopened = await fixture.maps.loadProject(fixture.session);
    expect(
      reopened.eventRegistry!.records.firstWhere((r) => r.id == original.id),
      fresh,
    );
    expect(reopened.scenes.firstWhere((s) => s.id == scene.id), scene);
  });

  test(
    'independent event remains publishable after another record changed',
    () async {
      final records = fixture.receipt.manifest.eventRegistry!.records;
      final base = await fixture.maps.loadMap(
        fixture.session,
        fixture.receipt.manifest.maps.first,
      );
      final first = updated(records.first);
      await port.publish(
        NarrativePublication(
          base: base,
          current: base.map,
          events: [first],
          expectedEvents: {records.first.id: records.first},
        ),
      );
      final second = updated(records.last);
      final receipt = await port.publish(
        NarrativePublication(
          base: base,
          current: base.map,
          events: [second],
          expectedEvents: {records.last.id: records.last},
        ),
      );
      expect(
        receipt.manifest.eventRegistry!.records.firstWhere(
          (r) => r.id == first.id,
        ),
        first,
      );
      expect(
        receipt.manifest.eventRegistry!.records.firstWhere(
          (r) => r.id == second.id,
        ),
        second,
      );
      expect(receipt.manifest.scenes, fixture.receipt.manifest.scenes);
      expect(receipt.manifest.storylines, fixture.receipt.manifest.storylines);
    },
  );

  test(
    'scene baseline is protected even when record stays identical',
    () async {
      final original = fixture.receipt.manifest.eventRegistry!.records.first;
      final scene = fixture.receipt.manifest.scenes.firstWhere(
        (scene) => scene.id == original.definitionOrNull!.sceneId,
      );
      final base = await fixture.maps.loadMap(
        fixture.session,
        fixture.receipt.manifest.maps.first,
      );
      final fresh = SceneAsset.fromJson({
        ...scene.toJson(),
        'name': 'Scène graphique actuelle',
      });
      await port.publish(
        NarrativePublication(
          base: base,
          current: base.map,
          scenes: [fresh],
          expectedScenes: {scene.id: scene},
        ),
      );
      final before = await File('${fixture.directory.path}/project.json')
          .readAsBytes();
      await expectLater(
        port.publish(
          NarrativePublication(
            base: base,
            current: base.map,
            scenes: [scene],
            events: [original],
            expectedEvents: {original.id: original},
            expectedScenes: {scene.id: scene},
          ),
        ),
        throwsA(
          isA<NarrativeFailure>().having(
            (e) => e.message,
            'scene guard',
            contains('scène liée'),
          ),
        ),
      );
      expect(
        await File('${fixture.directory.path}/project.json').readAsBytes(),
        before,
      );
    },
  );

  test(
    'dialogue metadata baseline is protected when source bytes stay identical',
    () async {
      final original = fixture.receipt.manifest.dialogues.first;
      final source = await port.readDialogue(original);
      final base = await fixture.maps.loadMap(
        fixture.session,
        fixture.receipt.manifest.maps.first,
      );
      final current = NarrativeDialogueSource(
        entry: original.copyWith(name: 'Dialogue renommé'),
        source: source.source,
        revision: source.revision,
      );
      await port.publish(
        NarrativePublication(
          base: base,
          current: base.map,
          dialogues: [current],
          expectedDialogues: {original.id: original},
        ),
      );
      final before = await File('${fixture.directory.path}/project.json')
          .readAsBytes();
      await expectLater(
        port.publish(
          NarrativePublication(
            base: base,
            current: base.map,
            dialogues: [source],
            expectedDialogues: {original.id: original},
          ),
        ),
        throwsA(
          isA<NarrativeFailure>().having(
            (e) => e.message,
            'dialogue guard',
            contains('dialogue lié'),
          ),
        ),
      );
      expect(
        await File('${fixture.directory.path}/project.json').readAsBytes(),
        before,
      );
      expect((await port.readDialogue(current.entry)).source, source.source);
    },
  );
}
