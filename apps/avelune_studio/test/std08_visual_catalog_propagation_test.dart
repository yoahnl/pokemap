import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:avelune_studio/features/verification/data/local_verification_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import 'support/event_backend_fixture.dart';
import 'support/ui06_scene_fixture.dart';

void main() {
  test('Studio Event catalog keeps a picture Scene buildable using its canonical media catalog', () async {
    final f = await _fixture();
    addTearDown(f.fixture.dispose);
    final controller = f.fixture.attach();
    expect(await controller.prepare(), isTrue);
    expect(
      controller.catalog.scenes
          .singleWhere((entry) => entry.scene.id == 'visual_producer')
          .buildable,
      isTrue,
    );
  });

  test(
    'Studio local Event publication accepts a picture Scene outcome source',
    () async {
      final f = await _fixture();
      addTearDown(f.fixture.dispose);
      final base = f.project.eventRegistry!.records.singleWhere(
        (record) => record.id == Ui06SceneFixture.eventId,
      );
      final current = NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: base.id,
          name: 'Picture outcome',
          source: NarrativeEventSourceRef.outcomeReceived(
            NarrativeOutcomeRef(
              producerKind: NarrativeOutcomeProducerKind.scene,
              producerId: 'visual_producer',
              outcomeId: 'shown',
            ),
          ),
          conditions: const [],
          sceneId: Ui06SceneFixture.sceneId,
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          priority: 0,
          order: 0,
        ),
        enabled: true,
        activeInLegacyMode: true,
      );
      final receipt = await LocalEventAdapter(
        session: f.fixture.source.session,
        mapAdapter: f.fixture.source.maps,
      ).publishEvent(id: base.id, base: base, current: current);
      expect(
        receipt.manifest.eventRegistry!.records
            .singleWhere((record) => record.id == base.id)
            .definitionOrNull!
            .source,
        current.definitionOrNull!.source,
      );
    },
  );

  test('Studio verification isolate validates picture references with canonical media', () async {
    final f = await _fixture();
    addTearDown(f.fixture.dispose);
    final maps = await LocalVerificationAdapter(
      session: f.fixture.source.session,
      mapAdapter: f.fixture.source.maps,
    ).loadMaps();
    final analysis = await LocalVerificationAdapter(
      session: f.fixture.source.session,
      mapAdapter: f.fixture.source.maps,
    ).analyse(project: f.project, maps: maps, sources: const []).result;
    expect(analysis.validation.byCode('commandUnknownPictureMedia'), isEmpty);
  });
}

Future<({EventBackendFixture fixture, ProjectManifest project})>
_fixture() async {
  final fixture = await EventBackendFixture.create();
  final scene = SceneAsset(
    id: 'visual_producer',
    name: 'Picture producer',
    declaredOutcomes: [SceneOutcome(id: 'shown', label: 'Shown')],
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'show',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.interactive(
            SceneInteractiveCommand.worldPresentation(
              operation: SceneWorldPresentationOperation.showPicture,
              slotId: 1,
              mediaAssetId: 'portrait',
              referenceWidth: 512,
              referenceHeight: 384,
              x: 0,
              y: 0,
            ),
          ),
        ),
        SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: 'shown'),
        ),
      ],
      edges: [
        SceneEdge(
          id: 'start_show',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'show',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'show_end',
          fromNodeId: 'show',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
  final project = fixture.workspace.project!.copyWith(
    scenes: [...fixture.workspace.project!.scenes, scene],
  );
  await File('${fixture.source.directory.path}/project.json')
      .writeAsString(jsonEncode(project.toJson()));
  final media = File(
    '${fixture.source.directory.path}/$projectMediaCatalogStorageKey',
  );
  await media.parent.create(recursive: true);
  await media.writeAsBytes(
    encodeProjectMediaCatalogBytes(
      ProjectMediaCatalog(
        entries: [
          ProjectMediaAsset(
            id: 'portrait',
            label: 'Portrait',
            kind: ProjectMediaKind.image,
            sourceAssetId: 'portrait_source',
          ),
        ],
      ),
    ),
  );
  await fixture.source.maps.loadProject(fixture.source.session);
  fixture.workspace.project = project;
  return (fixture: fixture, project: project);
}
