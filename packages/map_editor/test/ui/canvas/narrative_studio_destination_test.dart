import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/state/models/editor_workspace_mode.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_destination.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_navigation.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_route_presentation.dart';

void main() {
  group('Narrative Studio route presentation', () {
    test('maps every narrative workspace to the canonical destination', () {
      const expected = <EditorWorkspaceMode, NarrativeStudioDestination>{
        EditorWorkspaceMode.narrativeOverview:
            NarrativeStudioDestination.overview,
        EditorWorkspaceMode.globalStory: NarrativeStudioDestination.storylines,
        EditorWorkspaceMode.step: NarrativeStudioDestination.storylines,
        EditorWorkspaceMode.scenes: NarrativeStudioDestination.scenes,
        EditorWorkspaceMode.events: NarrativeStudioDestination.events,
        EditorWorkspaceMode.cinematics: NarrativeStudioDestination.cinematics,
        EditorWorkspaceMode.dialogue: NarrativeStudioDestination.dialogues,
        EditorWorkspaceMode.facts: NarrativeStudioDestination.facts,
        EditorWorkspaceMode.shops: NarrativeStudioDestination.shops,
        EditorWorkspaceMode.worldRules: NarrativeStudioDestination.worldRules,
        EditorWorkspaceMode.narrativeValidator:
            NarrativeStudioDestination.validator,
      };

      for (final entry in expected.entries) {
        expect(
          narrativeStudioRoutePresentationFor(entry.key)?.destination,
          entry.value,
          reason: '${entry.key} must select ${entry.value}',
        );
      }
    });

    test('step remains a child breadcrumb of Storylines', () {
      final storyline = narrativeStudioRoutePresentationFor(
        EditorWorkspaceMode.globalStory,
      );
      final step = narrativeStudioRoutePresentationFor(
        EditorWorkspaceMode.step,
      );

      expect(storyline?.breadcrumbLabels, const ['Storylines']);
      expect(step?.breadcrumbLabels, const ['Storylines', 'Étape']);
      expect(step?.destination, NarrativeStudioDestination.storylines);
    });

    test('uses the canonical French labels for localized destinations', () {
      expect(
        narrativeStudioRoutePresentationFor(EditorWorkspaceMode.scenes)?.label,
        'Scènes',
      );
      expect(
        narrativeStudioRoutePresentationFor(EditorWorkspaceMode.worldRules)
            ?.label,
        'Règles du monde',
      );
    });

    test('maps stays a gateway while Validator is a real destination', () {
      expect(
        NarrativeStudioDestination.values,
        const [
          NarrativeStudioDestination.overview,
          NarrativeStudioDestination.storylines,
          NarrativeStudioDestination.scenes,
          NarrativeStudioDestination.events,
          NarrativeStudioDestination.cinematics,
          NarrativeStudioDestination.dialogues,
          NarrativeStudioDestination.facts,
          NarrativeStudioDestination.shops,
          NarrativeStudioDestination.worldRules,
          NarrativeStudioDestination.validator,
        ],
      );
      expect(
        narrativeStudioRoutePresentationFor(
          EditorWorkspaceMode.narrativeValidator,
        )?.label,
        'Validateur',
      );
      expect(
        narrativeStudioRoutePresentationFor(EditorWorkspaceMode.map),
        isNull,
      );
      expect(
        narrativeStudioRoutePresentationFor(EditorWorkspaceMode.tileset),
        isNull,
      );
    });
  });

  group('NSC-10 typed child routes', () {
    test('keeps Map Events under Events and out of top-level destinations', () {
      final builder = NarrativeStudioRouteLocation.events();
      final mapEvents = NarrativeStudioRouteLocation.events(
        childRoute: NarrativeStudioChildRoute.mapEvents,
      );

      expect(builder.destination, NarrativeStudioDestination.events);
      expect(builder.childRoute, NarrativeStudioChildRoute.eventBuilder);
      expect(mapEvents.destination, NarrativeStudioDestination.events);
      expect(mapEvents.childRoute, NarrativeStudioChildRoute.mapEvents);
      expect(NarrativeStudioDestination.values, isNot(contains('mapEvents')));
      expect(
        narrativeStudioRoutePresentationForLocation(mapEvents).breadcrumbLabels,
        const ['Événements', 'Events par map'],
      );
    });

    test('models route, selected asset and return expectation separately', () {
      final scene = NarrativeStudioRouteLocation.scenes(
        selection: NarrativeStudioAssetSelection(
          kind: NarrativeStudioAssetKind.scene,
          assetId: 'scene_port',
          focusId: 'node_dialogue',
        ),
      );
      final cinematic = NarrativeStudioRouteLocation.cinematics(
        childRoute: NarrativeStudioChildRoute.cinematicBuilder,
        selection: NarrativeStudioAssetSelection(
          kind: NarrativeStudioAssetKind.cinematic,
          assetId: 'cinematic_depart',
        ),
      );
      final expectation = NarrativeStudioReturnExpectation(
        location: scene,
        scrollOffset: 184,
        focusAnchorId: 'node_dialogue',
      );

      expect(cinematic.destination, NarrativeStudioDestination.cinematics);
      expect(cinematic.selection?.assetId, 'cinematic_depart');
      expect(expectation.location, scene);
      expect(expectation.scrollOffset, 184);
      expect(expectation.focusAnchorId, 'node_dialogue');
    });

    test('maps legacy workspace modes to compatible typed locations', () {
      expect(
        narrativeStudioRouteLocationFor(EditorWorkspaceMode.step),
        NarrativeStudioRouteLocation.storylines(
          childRoute: NarrativeStudioChildRoute.storylineStep,
        ),
      );
      expect(
        narrativeStudioRouteLocationFor(EditorWorkspaceMode.cinematics),
        NarrativeStudioRouteLocation.cinematics(),
      );
      expect(
        narrativeStudioRouteLocationFor(EditorWorkspaceMode.map),
        isNull,
      );
    });

    test('rejects a selection that does not belong to the destination', () {
      expect(
        () => NarrativeStudioRouteLocation.events(
          selection: NarrativeStudioAssetSelection(
            kind: NarrativeStudioAssetKind.cinematic,
            assetId: 'cinematic_wrong',
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => NarrativeStudioRouteLocation.cinematics(
          childRoute: NarrativeStudioChildRoute.mapEvents,
        ),
        throwsArgumentError,
      );
      expect(
        () => NarrativeStudioAssetSelection(
          kind: NarrativeStudioAssetKind.scene,
          assetId: '   ',
        ),
        throwsArgumentError,
      );
    });
  });
}
