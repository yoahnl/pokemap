import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_header.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_builder_story_harness.dart';

void main() {
  testWidgets('undo follows the history of the active space', (tester) async {
    await open(tester);
    final id = story.behaviours.registry(maps.project!)!.records.first.id;
    NarrativeEventRecord meeting() => story.behaviours
        .registry(maps.project!)!
        .records
        .singleWhere((record) => record.id == id);
    VoidCallback? step({
      bool redo = false,
      bool scenario = true,
      bool editable = true,
    }) => mapBuilderHistoryStep(
      maps,
      redo: redo,
      editable: editable,
      story: scenario ? story : null,
    );

    expect(step(), isNull);
    expect(story.renameBehaviour(meeting(), 'Rencontre'), isTrue);
    expect(step(scenario: false), isNull);
    expect(step(editable: false), isNull);
    step()!();
    expect(meeting().name, 'meeting');
    step(redo: true)!();
    expect(meeting().name, 'Rencontre');

    final luth = story.elements!.byKey('entity:luth')!;
    expect(story.rename(luth, 'Luth bis'), isTrue);
    step(scenario: false)!();
    expect(story.entityOf(luth)!.name, 'Luth');
    expect(meeting().name, 'Rencontre');
  });

  testWidgets('an edit that cannot re-enable a behaviour says so', (
    tester,
  ) async {
    final registry = storyProject.eventRegistry!;
    await open(
      tester,
      project: storyProject.copyWith(
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: registry.schemaVersion,
          mode: registry.mode,
          records: [
            for (final record in registry.records)
              if (record.name == 'after-starter')
                storyEvent(
                  'after-starter',
                  NarrativeEventSourceRef.entityInteract('a', 'luth'),
                  reuse: NarrativeEventReusePolicy.reusable,
                )
              else
                record,
          ],
          legacyClaims: registry.legacyClaims,
        ),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey('map-story-element-entity:luth')),
    );
    await tester.pump();
    tester
        .widget<StudioSelect>(find.byKey(const ValueKey('map-story-after')))
        .onChanged!('eachTime');
    await tester.pump();

    expect(story.selectedBehaviour!.enabledOrNull, isFalse);
    expect(
      find.textContaining('Ce comportement a été désactivé'),
      findsOneWidget,
    );
  });

  for (final withMedia in [true, false]) {
    testWidgets(
      'scenes using other maps, rewards and images ${withMedia ? 'keep' : 'without media block'} behaviour edits',
      (tester) async {
        final puzzle = SceneOpenImagePuzzleInteractiveCommand(
          definition: ImagePuzzleDefinition(
            puzzleId: 'kabuto',
            imageResourceId: 'kabuto-image',
            rows: 2,
            columns: 2,
          ),
        );
        final claim = SceneInteractiveCommand.claimPeriodicReward(
          definition: PeriodicItemRewardDefinition(
            rewardId: 'daily',
            label: 'Baie',
            itemId: 'berry',
            quantity: 1,
          ),
        );
        final project = storyProject.copyWith(
          scenes: [
            ...storyProject.scenes,
            _actingScene(
              'scene-garden',
              SceneActionPayload.consequence(
                SceneConsequence.setNpcPresence(
                  mapId: 'b',
                  entityId: 'gardener',
                  present: false,
                ),
              ),
              const ['completed'],
            ),
            _actingScene(
              'scene-puzzle',
              SceneActionPayload.interactive(puzzle),
              puzzle.outputPortIds,
            ),
            _actingScene(
              'scene-berry',
              SceneActionPayload.interactive(claim),
              claim.outputPortIds,
              actionId: 'claim',
            ),
            _rewardCheckScene(),
          ],
        );
        await open(
          tester,
          project: project,
          loadMedia: (_) async => withMedia
              ? ProjectMediaCatalog(
                  entries: [
                    ProjectMediaAsset(
                      id: 'kabuto-image',
                      label: 'Kabuto',
                      kind: ProjectMediaKind.image,
                      sourceAssetId: 'kabuto-source',
                    ),
                  ],
                )
              : null,
        );
        expect(story.ready, isFalse);
        await story.prepare();
        expect(story.ready, isTrue);
        expect(story.error, isNull);

        await tester.tap(
          find.byKey(const ValueKey('map-story-element-entity:luth')),
        );
        await tester.pump();
        tester
            .widget<StudioSelect>(find.byKey(const ValueKey('map-story-after')))
            .onChanged!('eachTime');
        await tester.pump();

        final meeting = story.behaviours
            .registry(maps.project!)!
            .records
            .singleWhere((record) => record.name == 'meeting');
        if (withMedia) {
          expect(story.error, isNull);
          expect(meeting.reusePolicy, NarrativeEventReusePolicy.reusable);
          bool buildable(NarrativeEventProjectCatalog catalog, String id) =>
              catalog.scenes
                  .singleWhere((entry) => entry.scene.id == id)
                  .buildable;
          final strict = buildNarrativeEventProjectCatalog(
            project: maps.project!,
            maps: [story.map!],
          );
          final scoped = story.behaviours
              .context(maps.project!, story.map!)
              .catalog;
          for (final id in [
            'scene-garden',
            'scene-puzzle',
            'scene-berry-check',
          ]) {
            expect(buildable(strict, id), isFalse, reason: id);
            expect(buildable(scoped, id), isTrue, reason: id);
          }
        } else {
          expect(story.error, isNotNull);
          expect(meeting.reusePolicy, NarrativeEventReusePolicy.oneShot);
        }
      },
    );
  }
}

SceneAsset _actingScene(
  String id,
  SceneActionPayload payload,
  List<String> ports, {
  String actionId = 'act',
}) => SceneAsset(
  id: id,
  name: id,
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(id: actionId, kind: SceneNodeKind.action, payload: payload),
      SceneNode(
        id: 'end',
        kind: SceneNodeKind.end,
        payload: SceneEndPayload(outcomePolicy: SceneOutcomePolicy.progression),
      ),
    ],
    edges: [
      SceneEdge(
        id: 'enter',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: actionId,
        kind: SceneEdgeKind.defaultFlow,
      ),
      for (final port in ports)
        SceneEdge(
          id: port,
          fromNodeId: actionId,
          fromPortId: port,
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
    ],
  ),
);

SceneAsset _rewardCheckScene() => SceneAsset(
  id: 'scene-berry-check',
  name: 'scene-berry-check',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'check',
        kind: SceneNodeKind.condition,
        payload: SceneConditionPayload(
          conditionSource: SceneConditionSource.periodicRewardAvailable(
            reference: PeriodicRewardReference(
              sceneId: 'scene-berry',
              nodeId: 'claim',
              rewardId: 'daily',
            ),
            expectedValue: true,
          ),
        ),
      ),
      SceneNode(
        id: 'end',
        kind: SceneNodeKind.end,
        payload: SceneEndPayload(outcomePolicy: SceneOutcomePolicy.progression),
      ),
    ],
    edges: [
      SceneEdge(
        id: 'enter',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'check',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'true',
        fromNodeId: 'check',
        fromPortId: 'true',
        toNodeId: 'end',
        kind: SceneEdgeKind.conditionTrue,
      ),
      SceneEdge(
        id: 'false',
        fromNodeId: 'check',
        fromPortId: 'false',
        toNodeId: 'end',
        kind: SceneEdgeKind.conditionFalse,
      ),
    ],
  ),
);
