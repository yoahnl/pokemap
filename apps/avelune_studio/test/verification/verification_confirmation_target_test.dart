import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../presentation/story_memory_harness.dart';
import '../scenes/scene_catalog_support.dart';
import '../scenes/steps/scene_step_fixtures.dart';
import '../storyline/storyline_widget_support.dart';
import 'verification_fakes.dart';

const _fieldPath = 'confirm.preSessionInteraction.prompt';

SceneAsset _confirmationScene({required bool hasConfirmation}) => SceneAsset(
  id: 'gate',
  name: 'Confirmer le départ',
  executionProfile: SceneExecutionProfile.preSession,
  graph: graphOf(
    [
      startNode(),
      if (hasConfirmation)
        SceneNode(
          id: 'confirm',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.preSessionInteraction(
            ScenePreSessionInteractionSpec.confirmation(
              prompt: SceneInteractionPrompt(
                localizationKey: 'departure',
                fallbackText: 'Bonjour {draft.playerName}.',
              ),
            ),
          ),
        ),
      endNode(_fieldPath),
    ],
    [
      link('start', hasConfirmation ? 'confirm' : _fieldPath),
      if (hasConfirmation) link('confirm', _fieldPath, port: 'confirmed'),
    ],
  ),
);

void main() {
  for (final exists in [true, false]) {
    testWidgets(
      'opening a confirmation field diagnostic with its owner present: $exists',
      (tester) async {
        final saved = _confirmationScene(hasConfirmation: true);
        final current = _confirmationScene(hasConfirmation: exists);
        final project = trameProject.copyWith(scenes: [saved]);
        final diagnostic = validateNarrativeProject(
          project,
          maps: const [],
        ).byCode('presentationTextReferenceUnresolvable').single;
        expect(diagnostic.path, 'scenes.gate.nodes.$_fieldPath');
        final index = memoryIndex()
          ..documents['gate'] = catalogDocument(current);
        await openTrameStudio(
          tester,
          project: project,
          index: index,
          verification: FakeVerificationPort(diagnostics: [diagnostic]),
        );
        for (final key in [
          'story-section-verification',
          'verification-start',
          'verification-open-0',
        ]) {
          await tester.tap(find.byKey(ValueKey(key)));
          await settleMemory(tester);
        }

        final graph = find.descendant(
          of: find.byKey(const ValueKey('scene-focus-graph-gate')),
          matching: find.byType(SceneGraphCanvas),
        );
        expect(tester.state<SceneGraphCanvasState>(graph).selection, {
          if (exists) 'confirm',
        });
        if (exists) {
          expect(
            find.byKey(const ValueKey('scene-graph-inspector-confirm')),
            findsOneWidget,
          );
        } else {
          expect(
            find.byKey(const ValueKey('scene-graph-checks')),
            findsOneWidget,
          );
        }
      },
    );
  }
}
