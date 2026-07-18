import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/state/models/editor_workspace_mode.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_destination.dart';
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
        EditorWorkspaceMode.cutscene: NarrativeStudioDestination.cinematics,
        EditorWorkspaceMode.dialogue: NarrativeStudioDestination.dialogues,
        EditorWorkspaceMode.facts: NarrativeStudioDestination.facts,
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
}
