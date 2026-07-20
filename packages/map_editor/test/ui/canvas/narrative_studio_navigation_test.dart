import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_destination.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_navigation.dart';

void main() {
  group('NSC-10 navigation session', () {
    test('restores a single-use route selection viewport and focus snapshot',
        () {
      final controller = NarrativeStudioNavigationController();
      final source = NarrativeStudioRouteLocation.events(
        selection: NarrativeStudioAssetSelection(
          kind: NarrativeStudioAssetKind.event,
          assetId: 'evt_port',
          parentId: 'map_port',
        ),
      );
      final target = NarrativeStudioRouteLocation.scenes(
        selection: NarrativeStudioAssetSelection(
          kind: NarrativeStudioAssetKind.scene,
          assetId: 'scene_depart',
        ),
      );
      final expectedReturn = NarrativeStudioReturnExpectation(
        location: source,
        scrollOffset: 236,
        zoom: 1.35,
        focusAnchorId: 'v2:evt_port',
      );

      controller.navigate(target, returnExpectation: expectedReturn);
      expect(controller.state.location, target);
      expect(controller.state.pendingReturn, expectedReturn);

      final restored = controller.restoreReturn();
      expect(restored, expectedReturn);
      expect(controller.state.location, source);
      expect(controller.state.pendingReturn, isNull);
      expect(controller.state.restorationRequest?.expectation, expectedReturn);

      final revision = controller.state.restorationRequest!.revision;
      expect(controller.consumeRestoration(revision), isTrue);
      expect(controller.state.restorationRequest, isNull);
      expect(controller.restoreReturn(), isNull);
    });

    test('rejects invalid viewport snapshots', () {
      final location = NarrativeStudioRouteLocation.scenes();

      expect(
        () => NarrativeStudioReturnExpectation(location: location, zoom: 0),
        throwsArgumentError,
      );
      expect(
        () => NarrativeStudioReturnExpectation(
          location: location,
          zoom: double.nan,
        ),
        throwsArgumentError,
      );
    });

    test('top-level replacement clears stale return and restoration state', () {
      final controller = NarrativeStudioNavigationController();
      final source = NarrativeStudioRouteLocation.scenes();
      final target = NarrativeStudioRouteLocation.dialogues(
        selection: NarrativeStudioAssetSelection(
          kind: NarrativeStudioAssetKind.dialogue,
          assetId: 'dialogue_lysa',
        ),
      );

      controller.navigate(
        target,
        returnExpectation: NarrativeStudioReturnExpectation(
          location: source,
          scrollOffset: 0,
          focusAnchorId: 'scene_node_dialogue',
        ),
      );
      controller.restoreReturn();
      controller.replace(NarrativeStudioRouteLocation.overview());

      expect(
        controller.state.location,
        NarrativeStudioRouteLocation.overview(),
      );
      expect(controller.state.pendingReturn, isNull);
      expect(controller.state.restorationRequest, isNull);
    });

    test('selection-only returns do not create a restoration request', () {
      final controller = NarrativeStudioNavigationController();
      final source = NarrativeStudioRouteLocation.cinematics(
        childRoute: NarrativeStudioChildRoute.cinematicLibrary,
        selection: NarrativeStudioAssetSelection(
          kind: NarrativeStudioAssetKind.cinematic,
          assetId: 'cinematic_intro',
        ),
      );

      controller.navigate(
        NarrativeStudioRouteLocation.dialogues(),
        returnExpectation: NarrativeStudioReturnExpectation(location: source),
      );

      expect(controller.restoreReturn()?.location, source);
      expect(controller.state.location, source);
      expect(controller.state.pendingReturn, isNull);
      expect(
        controller.state.restorationRequest,
        isNull,
        reason:
            'La sélection est portée par la route et ne requiert aucun ack.',
      );
    });

    test('reset prevents return context leaking into another project', () {
      final controller = NarrativeStudioNavigationController();
      controller.navigate(
        NarrativeStudioRouteLocation.cinematics(
          childRoute: NarrativeStudioChildRoute.cinematicBuilder,
          selection: NarrativeStudioAssetSelection(
            kind: NarrativeStudioAssetKind.cinematic,
            assetId: 'cinematic_intro',
          ),
        ),
        returnExpectation: NarrativeStudioReturnExpectation(
          location: NarrativeStudioRouteLocation.scenes(),
          scrollOffset: 12,
          focusAnchorId: 'scene_intro',
        ),
      );

      controller.resetForProject('project_b');

      expect(controller.state.projectIdentity, 'project_b');
      expect(
        controller.state.location,
        NarrativeStudioRouteLocation.overview(),
      );
      expect(controller.restoreReturn(), isNull);
    });
  });

  group('NSC-10 canonical intent adapter', () {
    test('resolves Scene, Cinematic and Dialogue to exact internal assets', () {
      final cases = <NarrativeDependencyNavigationIntent,
          ({
        NarrativeStudioDestination destination,
        NarrativeStudioChildRoute child,
        NarrativeStudioAssetKind kind,
      })>{
        const NarrativeDependencyNavigationIntent(
          kind: NarrativeDependencyTargetKind.scene,
          assetId: 'scene.port',
        ): (
          destination: NarrativeStudioDestination.scenes,
          child: NarrativeStudioChildRoute.sceneBuilder,
          kind: NarrativeStudioAssetKind.scene,
        ),
        const NarrativeDependencyNavigationIntent(
          kind: NarrativeDependencyTargetKind.cinematic,
          assetId: 'cine.depart',
        ): (
          destination: NarrativeStudioDestination.cinematics,
          child: NarrativeStudioChildRoute.cinematicBuilder,
          kind: NarrativeStudioAssetKind.cinematic,
        ),
        const NarrativeDependencyNavigationIntent(
          kind: NarrativeDependencyTargetKind.dialogue,
          assetId: 'dialogue.lysa',
        ): (
          destination: NarrativeStudioDestination.dialogues,
          child: NarrativeStudioChildRoute.dialogueEditor,
          kind: NarrativeStudioAssetKind.dialogue,
        ),
      };

      for (final entry in cases.entries) {
        final resolution = resolveNarrativeDependencyNavigationIntent(
          entry.key,
        );
        expect(
            resolution.kind, NarrativeStudioNavigationResolutionKind.internal);
        expect(resolution.location?.destination, entry.value.destination);
        expect(resolution.location?.childRoute, entry.value.child);
        expect(resolution.location?.selection?.kind, entry.value.kind);
        expect(resolution.location?.selection?.assetId, entry.key.assetId);
      }
    });

    test('resolves an Event to a physical Map without losing qualifiers', () {
      const intent = NarrativeDependencyNavigationIntent(
        kind: NarrativeDependencyTargetKind.sourceMap,
        assetId: 'npc.lysa',
        parentId: 'map.port',
        scope: 'map',
        sourceKind: 'entity',
        mapId: 'map.port',
      );

      final resolution = resolveNarrativeDependencyNavigationIntent(intent);

      expect(
          resolution.kind, NarrativeStudioNavigationResolutionKind.externalMap);
      expect(
        resolution.externalMapTarget,
        const NarrativeStudioExternalMapTarget(
          mapId: 'map.port',
          sourceKind: 'entity',
          sourceId: 'npc.lysa',
        ),
      );
    });

    test('keeps Chapter and Step hierarchy in their authoring selections', () {
      const chapterIntent = NarrativeDependencyNavigationIntent(
        kind: NarrativeDependencyTargetKind.chapter,
        assetId: 'chapter.port',
        parentId: 'story.main',
      );
      const stepIntent = NarrativeDependencyNavigationIntent(
        kind: NarrativeDependencyTargetKind.step,
        assetId: 'step.departure',
        parentId: 'chapter.port',
        rootId: 'story.main',
      );

      final chapterResolution = resolveNarrativeDependencyNavigationIntent(
        chapterIntent,
      );
      final resolution = resolveNarrativeDependencyNavigationIntent(stepIntent);

      expect(
        chapterResolution.location,
        NarrativeStudioRouteLocation.storylines(
          selection: NarrativeStudioAssetSelection(
            kind: NarrativeStudioAssetKind.chapter,
            assetId: 'chapter.port',
            parentId: 'story.main',
          ),
        ),
      );
      expect(
        resolution.location,
        NarrativeStudioRouteLocation.storylines(
          selection: NarrativeStudioAssetSelection(
            kind: NarrativeStudioAssetKind.step,
            assetId: 'step.departure',
            parentId: 'chapter.port',
            rootId: 'story.main',
          ),
        ),
      );
    });

    test('controller directly consumes internal canonical dependency intents',
        () {
      final controller = NarrativeStudioNavigationController();
      const intent = NarrativeDependencyNavigationIntent(
        kind: NarrativeDependencyTargetKind.scene,
        assetId: 'scene.port',
      );

      final resolution = controller.navigateToDependency(intent);

      expect(resolution.kind, NarrativeStudioNavigationResolutionKind.internal);
      expect(
        controller.state.location,
        NarrativeStudioRouteLocation.scenes(
          selection: NarrativeStudioAssetSelection(
            kind: NarrativeStudioAssetKind.scene,
            assetId: 'scene.port',
          ),
        ),
      );
    });

    test('controller consumes a navigation intent emitted by the real index',
        () {
      final project = ProjectManifest(
        name: 'Canonical navigation chain',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        scenes: <SceneAsset>[
          SceneAsset(
            id: 'scene.indexed',
            name: 'Indexed Scene',
            graph: SceneGraph(
              startNodeId: 'start',
              nodes: <SceneNode>[
                SceneNode(id: 'start', kind: SceneNodeKind.start),
              ],
            ),
          ),
        ],
      );
      final index = buildNarrativeDependencyIndex(project: project);
      final intent = index
          .definitionsFor(
            const NarrativeDependencyKey(
              NarrativeDependencyTargetKind.scene,
              'scene.indexed',
            ),
          )
          .single
          .navigationIntent!;
      final controller = NarrativeStudioNavigationController();
      final expectedReturn = NarrativeStudioReturnExpectation(
        location: NarrativeStudioRouteLocation.overview(),
      );

      controller.navigateToDependency(
        intent,
        returnExpectation: expectedReturn,
      );

      expect(
        controller.state.location,
        NarrativeStudioRouteLocation.scenes(
          selection: NarrativeStudioAssetSelection(
            kind: NarrativeStudioAssetKind.scene,
            assetId: 'scene.indexed',
            sourceContext: 'scenes[scene.indexed]',
          ),
        ),
      );
      expect(controller.state.pendingReturn, expectedReturn);
    });

    test('fails closed when a physical source has no usable map identity', () {
      const intent = NarrativeDependencyNavigationIntent(
        kind: NarrativeDependencyTargetKind.sourceMap,
        assetId: 'legacy.scenario',
        scope: 'legacy',
        sourceKind: 'scenario',
        mapId: 'map.fabricated',
      );

      final resolution = resolveNarrativeDependencyNavigationIntent(intent);

      expect(
        resolution.kind,
        NarrativeStudioNavigationResolutionKind.unavailable,
      );
      expect(resolution.location, isNull);
      expect(resolution.externalMapTarget, isNull);
      expect(resolution.reason, isNotEmpty);
    });

    test('maps a diagnostic to the exact asset instead of only its workspace',
        () {
      const diagnostic = NarrativeProjectDiagnostic(
        code: 'scene.dialogue.missing',
        severity: NarrativeProjectDiagnosticSeverity.error,
        domain: NarrativeProjectDiagnosticDomain.dialogue,
        message: 'Dialogue missing',
        path: 'scenes[scene.port].nodes[node.lysa]',
        destination: NarrativeProjectDiagnosticDestination.dialogue,
        sceneId: 'scene.port',
        dialogueId: 'dialogue.lysa',
      );

      final resolution = resolveNarrativeProjectDiagnostic(diagnostic);

      expect(
          resolution.location,
          NarrativeStudioRouteLocation.dialogues(
            selection: NarrativeStudioAssetSelection(
              kind: NarrativeStudioAssetKind.dialogue,
              assetId: 'dialogue.lysa',
              parentId: 'scene.port',
              sourceContext: 'scenes[scene.port].nodes[node.lysa]',
            ),
          ));
    });

    test('maps a Step diagnostic to canonical Storyline Structure', () {
      const diagnostic = NarrativeProjectDiagnostic(
        code: 'storylineStepNeverCompleted',
        severity: NarrativeProjectDiagnosticSeverity.error,
        domain: NarrativeProjectDiagnosticDomain.storyline,
        message: 'Step unreachable',
        path:
            'storylines[story.main].chapters[chapter.port].steps[step.departure]',
        destination: NarrativeProjectDiagnosticDestination.storyline,
        storylineId: 'story.main',
        chapterId: 'chapter.port',
        stepId: 'step.departure',
      );

      final resolution = resolveNarrativeProjectDiagnostic(diagnostic);

      expect(
        resolution.location,
        NarrativeStudioRouteLocation.storylines(
          selection: NarrativeStudioAssetSelection(
            kind: NarrativeStudioAssetKind.step,
            assetId: 'step.departure',
            parentId: 'chapter.port',
            rootId: 'story.main',
            sourceContext:
                'storylines[story.main].chapters[chapter.port].steps[step.departure]',
          ),
        ),
      );
    });
  });
}
