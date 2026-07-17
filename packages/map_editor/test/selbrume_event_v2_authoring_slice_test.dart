import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

import 'support/selbrume_event_v2_fixture.dart';

void main() {
  test(
    'J1 authors Lysa, port entry and clue sources through product operations',
    () async {
      final fixture = await SelbrumeEventV2Fixture.create();
      addTearDown(fixture.dispose);

      expect(fixture.copyFingerprintBefore, isNotEmpty);
      expect(
        await fixture.originalFingerprintAfter(),
        fixture.originalFingerprintBefore,
        reason: 'J1 must not mutate the original Selbrume project.',
      );

      final session = await NarrativeEventAuthoringSession.prepare(
        fixture.projectPath,
      );
      final registry = session.manifest.eventRegistry!;
      expect(registry.mode, EventSystemMode.dualRead);
      expect(registry.records, hasLength(3));
      expect(registry.records.every((record) => record.enabledOrNull == true),
          isTrue);
      expect(
        registry.records.map((record) => record.definitionOrNull!.source),
        containsAll(<NarrativeEventSourceRef>[
          NarrativeEventSourceRef.entityInteract(
            selbrumePortMapId,
            selbrumeLysaEntityId,
          ),
          NarrativeEventSourceRef.triggerEnter(
            selbrumePortMapId,
            selbrumePortEntryTriggerId,
          ),
          NarrativeEventSourceRef.entityInteract(
            selbrumeMarshMapId,
            selbrumeClueEntityId,
          ),
        ]),
      );
      expect(
        registry.records.map((record) => record.definitionOrNull!.sceneId),
        containsAll(<String>[
          selbrumeLysaSceneId,
          selbrumePortEntrySceneId,
          selbrumeClueSceneId,
        ]),
      );
      final lysaScene = session.manifest.scenes.singleWhere(
        (scene) => scene.id == selbrumeLysaSceneId,
      );
      expect(
        lysaScene.graph.nodes.map((node) => node.kind),
        containsAll(<SceneNodeKind>[
          SceneNodeKind.yarnDialogue,
          SceneNodeKind.cinematic,
          SceneNodeKind.battle,
          SceneNodeKind.action,
        ]),
      );
      expect(
        lysaScene.graph.nodes
            .where((node) => node.kind == SceneNodeKind.action)
            .map((node) => (node.payload as SceneActionPayload).consequence)
            .whereType<SceneConsequence>()
            .map((consequence) => consequence.kind),
        containsAll(<SceneConsequenceKind>[
          SceneConsequenceKind.setFact,
          SceneConsequenceKind.completeStoryStep,
        ]),
      );
      expect(
        session.manifest.storylines
            .expand((storyline) => storyline.chapters)
            .expand((chapter) => chapter.steps)
            .where((step) => step.id == selbrumeLysaStoryStepId),
        hasLength(1),
      );

      final mapRepository = FileMapRepository();
      final portEntry = session.manifest.maps.singleWhere(
        (entry) => entry.id == selbrumePortMapId,
      );
      final marshEntry = session.manifest.maps.singleWhere(
        (entry) => entry.id == selbrumeMarshMapId,
      );
      final port = await mapRepository.loadMap(
        p.join(fixture.projectRoot.path, portEntry.relativePath),
      );
      final marsh = await mapRepository.loadMap(
        p.join(fixture.projectRoot.path, marshEntry.relativePath),
      );
      final lysa = port.entities.singleWhere(
        (entity) => entity.id == selbrumeLysaEntityId,
      );
      final clue = marsh.entities.singleWhere(
        (entity) => entity.id == selbrumeClueEntityId,
      );
      expect(lysa.pos, const GridPos(x: 26, y: 16));
      expect(lysa.kind, MapEntityKind.npc);
      expect(lysa.npc?.characterId, selbrumeLysaCharacterId);
      expect(lysa.npc?.trainerId, selbrumeLysaTrainerId);
      expect(clue.pos, const GridPos(x: 8, y: 32));
      expect(clue.kind, MapEntityKind.custom);
      expect(
        port.triggers.any(
          (trigger) => trigger.id == selbrumePortEntryTriggerId,
        ),
        isTrue,
      );

      final report = buildNarrativeEventValidationReport(
        registry: registry,
        catalog: session.context.catalog,
      );
      expect(
        report.diagnostics.where(
          (diagnostic) =>
              diagnostic.severity == NarrativeEventValidationSeverity.error,
        ),
        isEmpty,
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
