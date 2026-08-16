import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_pre_session_interaction_dialog.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('exposes the five no-code pre-session interaction forms', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final kind in SceneInteractionRequestKind.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: ScenePreSessionInteractionEditor(
              key: ValueKey(kind),
              kind: kind,
              newGameConfig: const ProjectNewGameConfig(
                playerAvatarCharacterIds: ['hero_lune'],
              ),
              cueOptions: const [],
              initialInteraction: _interaction(kind),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text(scenePreSessionInteractionKindLabel(kind)),
        findsAtLeastNWidgets(1),
      );
      expect(
        find.byKey(const ValueKey('scene-interaction-runtime-preview')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-interaction-options')),
        kind == SceneInteractionRequestKind.choice ||
                kind == SceneInteractionRequestKind.selection
            ? findsOneWidget
            : findsNothing,
      );
      expect(
        find.byKey(const ValueKey('scene-interaction-minimum')),
        kind == SceneInteractionRequestKind.text ||
                kind == SceneInteractionRequestKind.selection
            ? findsOneWidget
            : findsNothing,
      );
      final outputPorts = find.byKey(
        const ValueKey('scene-interaction-output-ports'),
      );
      expect(outputPorts, findsOneWidget);
      expect(
        find.descendant(of: outputPorts, matching: find.byType(PokeMapBadge)),
        findsNWidgets(_interaction(kind).outputPortIds.length),
      );
    }
  });

  testWidgets('returns a typed text interaction and its cinematic cue', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    ScenePreSessionInteractionDraft? result;
    const cue = ScenePreSessionInteractionCueOption(
      presentationNodeId: 'presentation',
      markerId: 'cue_player_name',
      label: 'Ouverture · Demander le nom (0:06)',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) => PokeMapButton(
              key: const ValueKey('open-interaction-editor'),
              onPressed: () async {
                result = await showScenePreSessionInteractionEditor(
                  context: context,
                  kind: SceneInteractionRequestKind.text,
                  newGameConfig: const ProjectNewGameConfig(),
                  cueOptions: const [cue],
                );
              },
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('open-interaction-editor')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('scene-interaction-prompt')),
      'Comment veux-tu t’appeler ?',
    );
    tester
        .widget<PokeMapDropdownField<String>>(
          find.byKey(const ValueKey('scene-interaction-binding')),
        )
        .onChanged(ScenePreSessionDraftField.playerName.name);
    await tester.drag(
      find.byKey(const ValueKey('scene-pre-session-interaction-editor')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    tester
        .widget<PokeMapDropdownField<String>>(
          find.byKey(const ValueKey('scene-interaction-cue')),
        )
        .onChanged(cue.value);
    await tester.pump();
    await tester.drag(
      find.byKey(const ValueKey('scene-pre-session-interaction-editor')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('scene-interaction-submit')));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.interaction.kind, SceneInteractionRequestKind.text);
    expect(
      result!.interaction.resultBinding?.field,
      ScenePreSessionDraftField.playerName,
    );
    expect(result!.cueBinding?.markerId, 'cue_player_name');
  });

  test('builds only Presentation interaction cue options in Scene order', () {
    final options = buildScenePreSessionInteractionCueOptions(
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'presentation',
            title: 'Intro',
            kind: SceneNodeKind.presentationCinematic,
            payload: ScenePresentationCinematicPayload(
              presentationCinematicId: 'cinematic_intro',
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'start_presentation',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'presentation',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'presentation_end',
            fromNodeId: 'presentation',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.presentationCompleted,
          ),
        ],
      ),
      cinematics: [
        PresentationCinematicAsset(
          id: 'cinematic_intro',
          title: 'Ouverture',
          durationUs: 10000000,
          tracks: [
            PresentationTrack(
              id: 'markers',
              label: 'Repères',
              kind: PresentationTrackKind.marker,
              clips: [
                PresentationMarkerClip(
                  id: 'cue_player_name',
                  startUs: 6000000,
                  label: 'Demander le nom',
                  markerKind: PresentationMarkerKind.interactionCue,
                  required: true,
                ),
                PresentationMarkerClip(
                  id: 'ordinary',
                  startUs: 7000000,
                  label: 'Simple repère',
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(options, hasLength(1));
    expect(options.single.markerId, 'cue_player_name');
    expect(options.single.label, 'Intro · Demander le nom (0:06)');
  });
}

ScenePreSessionInteractionSpec _interaction(SceneInteractionRequestKind kind) {
  final prompt = SceneInteractionPrompt(
    localizationKey: 'scene.test.prompt',
    fallbackText: 'Texte de test',
  );
  final options = <SceneInteractionOption>[
    SceneInteractionOption(
      id: 'option_a',
      label: SceneInteractionPrompt(
        localizationKey: 'scene.test.optionA',
        fallbackText: 'Option A',
      ),
    ),
  ];
  return switch (kind) {
    SceneInteractionRequestKind.message =>
      ScenePreSessionInteractionSpec.message(prompt: prompt),
    SceneInteractionRequestKind.text => ScenePreSessionInteractionSpec.text(
      prompt: prompt,
      constraints: SceneTextInputConstraints(minGraphemes: 0, maxGraphemes: 48),
    ),
    SceneInteractionRequestKind.choice => ScenePreSessionInteractionSpec.choice(
      prompt: prompt,
      options: options,
    ),
    SceneInteractionRequestKind.confirmation =>
      ScenePreSessionInteractionSpec.confirmation(prompt: prompt),
    SceneInteractionRequestKind.selection =>
      ScenePreSessionInteractionSpec.selection(
        prompt: prompt,
        options: options,
        constraints: SceneSelectionConstraints(
          minSelections: 1,
          maxSelections: 1,
        ),
      ),
  };
}
