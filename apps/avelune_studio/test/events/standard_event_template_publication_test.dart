import 'dart:io';
import 'dart:convert';

import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../support/event_backend_fixture.dart';
import '../support/ui06_scene_fixture.dart';

void main() {
  late EventBackendFixture fixture;

  setUp(() async {
    fixture = await EventBackendFixture.create();
    final initial = fixture.source.manifest;
    final registry = initial.eventRegistry!;
    await File('${fixture.source.directory.path}/project.json').writeAsString(
      jsonEncode(
        initial
            .copyWith(
              eventRegistry: NarrativeEventRegistry(
                schemaVersion: registry.schemaVersion,
                mode: EventSystemMode.v2Only,
                records: registry.records,
                legacyClaims: registry.legacyClaims,
              ),
            )
            .toJson(),
      ),
    );
    final project = await fixture.source.maps.loadProject(
      fixture.source.session,
    );
    final base = await fixture.source.maps.loadMap(
      fixture.source.session,
      project.maps.first,
    );
    await fixture.source.maps.saveMap(
      fixture.source.session,
      base,
      base.map.copyWith(
        entities: [
          ...base.map.entities,
          const MapEntity(
            id: 'template_a',
            name: 'Premier guide',
            kind: MapEntityKind.custom,
            pos: GridPos(x: 1, y: 1),
          ),
          const MapEntity(
            id: 'template_b',
            name: 'Deuxième guide',
            kind: MapEntityKind.custom,
            pos: GridPos(x: 2, y: 1),
          ),
        ],
      ),
    );
  });
  tearDown(() => fixture.dispose());

  StandardEventTemplateSpec spec(
    ProjectManifest project, {
    String owner = 'template_a',
    String? alternate,
  }) => StandardEventTemplateSpec(
    kind: StandardEventTemplateKind.conditionalNpc,
    mapId: project.maps.first.id,
    entityId: owner,
    name: 'Guide $owner',
    parameters: {
      'factId': Ui06SceneFixture.passFactId,
      'characterId': project.characters.first.id,
      'dialogueId': 'station_welcome',
      'alternateDialogueId': alternate ?? 'station_agreement',
    },
  );

  test(
    'guided controller refreshes the open map and its linked event together',
    () async {
      final project = await fixture.source.maps.loadProject(
        fixture.source.session,
      );
      final base = await fixture.source.maps.loadMap(
        fixture.source.session,
        project.maps.first,
      );
      fixture.workspace.project = project;
      fixture.workspace.active!.acceptCatalogContent(base);
      final controller = fixture.attach();
      expect(await controller.prepare(), isTrue);
      expect(
        await controller.publishTemplate(spec(project)),
        isTrue,
        reason: controller.error,
      );
      expect(
        readStandardEventTemplate(
          project: fixture.workspace.project!,
          map: fixture.workspace.active!.current,
          entityId: 'template_a',
        ),
        isNotNull,
      );
      expect(fixture.workspace.active!.dirty, isFalse);
      expect(
        controller.active!.definitionOrNull!.source,
        NarrativeEventSourceRef.entityInteract(base.mapId, 'template_a'),
      );
      expect(controller.busy, isFalse);
    },
  );

  test(
    'guided controller refuses a dirty map without erasing its draft',
    () async {
      final project = await fixture.source.maps.loadProject(
        fixture.source.session,
      );
      final base = await fixture.source.maps.loadMap(
        fixture.source.session,
        project.maps.first,
      );
      fixture.workspace.project = project;
      final document = fixture.workspace.active!;
      document.acceptCatalogContent(base);
      final draft = document.current.copyWith(name: 'Saisie non enregistrée');
      document.commit(draft);
      final controller = fixture.attach();
      expect(await controller.prepare(), isTrue);
      expect(await controller.publishTemplate(spec(project)), isFalse);
      expect(document.current, draft);
      expect(document.dirty, isTrue);
      expect((await fixture.readFresh()).eventRegistry, project.eventRegistry);
      expect(controller.busy, isFalse);
    },
  );

  test('one semantic publication saves map, pages, scenes and cold reopens for editing', () async {
    var project = await fixture.readFresh();
    var base = await fixture.source.maps.loadMap(
      fixture.source.session,
      project.maps.first,
    );
    final first = await fixture.port.publishTemplate(
      base: base,
      spec: spec(project),
      project: project,
      maps: [base.map],
    );
    expect(
      first.changedPaths,
      containsAll(['project.json', project.maps.first.relativePath]),
    );
    final freshPort = LocalMapWorkspaceAdapter();
    project = await freshPort.loadProject(fixture.source.session);
    base = await freshPort.loadMap(fixture.source.session, project.maps.first);
    expect(
      readStandardEventTemplate(
        project: project,
        map: base.map,
        entityId: 'template_a',
      )!.parameters['alternateDialogueId'],
      'station_agreement',
    );
    final firstIds = first.manifest.eventRegistry!.records
        .map((record) => record.id)
        .toSet();
    final second = await fixture.port.publishTemplate(
      base: base,
      spec: spec(project, alternate: 'station_refusal'),
      project: project,
      maps: [base.map],
    );
    expect(
      second.manifest.eventRegistry!.records.map((record) => record.id).toSet(),
      firstIds,
    );
    expect(
      readStandardEventTemplate(
        project: second.manifest,
        map: second.savedMap,
        entityId: 'template_a',
      )!.parameters['alternateDialogueId'],
      'station_refusal',
    );
    expect(
      second.manifest.scenes
          .where((scene) => scene.id == Ui06SceneFixture.sceneId)
          .single,
      Ui06SceneFixture.buildScene(),
    );
  });

  test(
    'a second parameterized instance leaves the first generated assets intact',
    () async {
      var project = await fixture.readFresh();
      var base = await fixture.source.maps.loadMap(
        fixture.source.session,
        project.maps.first,
      );
      final first = await fixture.port.publishTemplate(
        base: base,
        spec: spec(project),
        project: project,
        maps: [base.map],
      );
      project = await fixture.readFresh();
      base = await fixture.source.maps.loadMap(
        fixture.source.session,
        project.maps.first,
      );
      final firstEntity = base.map.entities.singleWhere(
        (entity) => entity.id == 'template_a',
      );
      final second = await fixture.port.publishTemplate(
        base: base,
        spec: spec(project, owner: 'template_b', alternate: 'station_refusal'),
        project: project,
        maps: [base.map],
      );
      expect(
        second.savedMap.entities.singleWhere(
          (entity) => entity.id == 'template_a',
        ),
        firstEntity,
      );
      expect(second.manifest.scenes, containsAll(first.manifest.scenes));
      expect(
        second.manifest.eventRegistry!.records,
        containsAll(first.manifest.eventRegistry!.records),
      );
      expect(
        readStandardEventTemplate(
          project: second.manifest,
          map: second.savedMap,
          entityId: 'template_b',
        )!.parameters['alternateDialogueId'],
        'station_refusal',
      );
    },
  );

  test(
    'a stale map refuses the entire publication without a partial registry',
    () async {
      final project = await fixture.readFresh();
      final base = await fixture.source.maps.loadMap(
        fixture.source.session,
        project.maps.first,
      );
      await fixture.source.maps.saveMap(
        fixture.source.session,
        base,
        base.map.copyWith(name: 'Carte modifiée ailleurs'),
      );
      final file = File('${fixture.source.directory.path}/project.json');
      final before = await file.readAsBytes();
      await expectLater(
        fixture.port.publishTemplate(
          base: base,
          spec: spec(project),
          project: project,
          maps: [base.map],
        ),
        throwsA(anything),
      );
      expect(await file.readAsBytes(), before);
      expect((await fixture.readFresh()).eventRegistry, project.eventRegistry);
    },
  );

  for (final checkpoint in [
    AuthoringTransactionCheckpoint.beforeResourcePromotion,
    AuthoringTransactionCheckpoint.afterResourcePromoted,
  ]) {
    test(
      'atomic recovery after $checkpoint leaves a coherent editable event',
      () async {
        final project = await fixture.readFresh();
        final base = await fixture.source.maps.loadMap(
          fixture.source.session,
          project.maps.first,
        );
        var interrupted = false;
        final port = LocalEventAdapter(
          session: fixture.source.session,
          mapAdapter: fixture.source.maps,
          faultInjector: (context) {
            if (!interrupted &&
                context.checkpoint == checkpoint &&
                context.promotionIndex == 0) {
              interrupted = true;
              throw StateError('simulated interruption');
            }
          },
        );
        final receipt = await port.publishTemplate(
          base: base,
          spec: spec(project),
          project: project,
          maps: [base.map],
        );
        expect(interrupted, isTrue);
        final freshPort = LocalMapWorkspaceAdapter();
        final fresh = await freshPort.loadProject(fixture.source.session);
        final map = (await freshPort.loadMap(
          fixture.source.session,
          fresh.maps.first,
        )).map;
        expect(fresh, receipt.manifest);
        final actual = map.toJson();
        final reported = receipt.savedMap.toJson();
        expect(
          [
            for (final key in actual.keys)
              if (jsonEncode(actual[key]) != jsonEncode(reported[key])) key,
          ],
          isEmpty,
          reason: 'The receipt must describe the bytes actually written.',
        );
        expect(
          readStandardEventTemplate(
            project: fresh,
            map: map,
            entityId: 'template_a',
          ),
          isNotNull,
        );
      },
    );
  }
}
