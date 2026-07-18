import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/models/editor_workspace_mode.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_shell_policy.dart';

void main() {
  group('NarrativeStudioShellPolicy', () {
    test('enables the product shell for every Event system mode', () {
      expect(
        NarrativeStudioShellPolicy.shouldUseProductShell(
          workspaceMode: EditorWorkspaceMode.events,
          eventSystemMode: EventSystemMode.legacyOnly,
        ),
        isTrue,
      );
      expect(
        NarrativeStudioShellPolicy.shouldUseProductShell(
          workspaceMode: EditorWorkspaceMode.events,
          eventSystemMode: EventSystemMode.dualRead,
        ),
        isTrue,
      );
      expect(
        NarrativeStudioShellPolicy.shouldUseProductShell(
          workspaceMode: EditorWorkspaceMode.events,
          eventSystemMode: EventSystemMode.v2Only,
        ),
        isTrue,
      );
    });

    test('enables the product shell for the migrated Scenes route', () {
      for (final eventSystemMode in EventSystemMode.values) {
        expect(
          NarrativeStudioShellPolicy.shouldUseProductShell(
            workspaceMode: EditorWorkspaceMode.scenes,
            eventSystemMode: eventSystemMode,
          ),
          isTrue,
          reason: 'Scenes does not depend on $eventSystemMode',
        );
      }
    });

    test(
      'enables Storylines and its nested Step route atomically',
      () {
        for (final workspaceMode in <EditorWorkspaceMode>[
          EditorWorkspaceMode.globalStory,
          EditorWorkspaceMode.step,
        ]) {
          for (final eventSystemMode in EventSystemMode.values) {
            expect(
              NarrativeStudioShellPolicy.shouldUseProductShell(
                workspaceMode: workspaceMode,
                eventSystemMode: eventSystemMode,
              ),
              isTrue,
              reason: '$workspaceMode does not depend on $eventSystemMode',
            );
          }
        }
      },
    );

    test('enables the product shell for the complete Cinematics route', () {
      for (final eventSystemMode in EventSystemMode.values) {
        expect(
          NarrativeStudioShellPolicy.shouldUseProductShell(
            workspaceMode: EditorWorkspaceMode.cutscene,
            eventSystemMode: eventSystemMode,
          ),
          isTrue,
          reason: 'Cinematics does not depend on $eventSystemMode',
        );
      }
    });

    test(
      'enables Overview, Dialogues, Facts, World Rules and Validator atomically',
      () {
        for (final workspaceMode in <EditorWorkspaceMode>[
          EditorWorkspaceMode.narrativeOverview,
          EditorWorkspaceMode.dialogue,
          EditorWorkspaceMode.facts,
          EditorWorkspaceMode.worldRules,
          EditorWorkspaceMode.narrativeValidator,
        ]) {
          for (final eventSystemMode in EventSystemMode.values) {
            expect(
              NarrativeStudioShellPolicy.shouldUseProductShell(
                workspaceMode: workspaceMode,
                eventSystemMode: eventSystemMode,
              ),
              isTrue,
              reason: '$workspaceMode does not depend on $eventSystemMode',
            );
          }
        }
      },
    );

    test('keeps every other editor route outside the product shell', () {
      for (final workspaceMode in EditorWorkspaceMode.values) {
        if (workspaceMode == EditorWorkspaceMode.events ||
            workspaceMode == EditorWorkspaceMode.scenes ||
            workspaceMode == EditorWorkspaceMode.globalStory ||
            workspaceMode == EditorWorkspaceMode.step ||
            workspaceMode == EditorWorkspaceMode.cutscene ||
            workspaceMode == EditorWorkspaceMode.dialogue ||
            workspaceMode == EditorWorkspaceMode.facts ||
            workspaceMode == EditorWorkspaceMode.worldRules ||
            workspaceMode == EditorWorkspaceMode.narrativeValidator ||
            workspaceMode == EditorWorkspaceMode.narrativeOverview) {
          continue;
        }

        expect(
          NarrativeStudioShellPolicy.shouldUseProductShell(
            workspaceMode: workspaceMode,
            eventSystemMode: EventSystemMode.v2Only,
          ),
          isFalse,
          reason: '$workspaceMode is not a Narrative Studio destination',
        );
      }
    });
  });
}
