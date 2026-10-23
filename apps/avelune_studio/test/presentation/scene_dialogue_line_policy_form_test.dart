import 'package:avelune_studio/presentation/features/scenes/scene_dialogue_line_policy_form.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  testWidgets(
    'edits exact millisecond rhythm while retaining rich imported feedback',
    (tester) async {
      final feedback = DialogueLineFeedback(
        segments: [
          DialogueTextSegment(
            'Bonjour ',
            style: DialogueSegmentStyle(colorArgb: 0xff123456),
          ),
          DialogueIconSegment(assetId: 'badge', widthPx: 18, heightPx: 20),
        ],
        revealIntervalMicros: 12501,
        advance: DialogueLineAdvancePolicy.autoAfterReveal(33001),
        audioCue: DialogueAudioCue(
          mediaAssetId: 'fanfare',
          cueId: 'imported_cue',
          volume: .65,
          role: DialogueAudioCueRole.musicEffect,
          bgmInterruption: DialogueBgmInterruption(
            fadeOutMs: 123,
            fadeInMs: 456,
          ),
        ),
      );
      final results = <SceneDialogueLinePolicy>[];
      await _open(tester, feedback: feedback, results: results);
      expect(find.text('Bonjour \uFFFC'), findsWidgets);
      expect(find.text('Icône 18 × 20 px'), findsOneWidget);
      expect(_text(tester, 'scene-line-reveal-ms'), '12.501');
      expect(_text(tester, 'scene-line-delay-ms'), '33.001');
      await _enter(tester, 'scene-line-reveal-ms', '19.125');
      await _apply(tester);
      expect(results.single.nodeName, 'Start');
      expect(results.single.lineIndex, 0);
      expect(results.single.feedback.revealIntervalMicros, 19125);
      expect(results.single.feedback.segments, feedback.segments);
      expect(results.single.feedback.audioCue, feedback.audioCue);
      expect(results.single.feedback.advance, feedback.advance);
    },
  );

  testWidgets('edits automatic advancement and returns to confirmation', (
    tester,
  ) async {
    final results = <SceneDialogueLinePolicy>[];
    await _open(tester, results: results);
    await _pick(tester, 'scene-line-advance', 'Automatique après affichage');
    await _enter(tester, 'scene-line-delay-ms', '500.125');
    await _apply(tester);
    expect(
      results.last.feedback.advance,
      DialogueLineAdvancePolicy.autoAfterReveal(500125),
    );
    await _pick(tester, 'scene-line-advance', 'Confirmation du joueur');
    expect(find.byKey(const ValueKey('scene-line-delay-ms')), findsNothing);
    await _apply(tester);
    expect(
      results.last.feedback.advance,
      const DialogueLineAdvancePolicy.confirm(),
    );
    expect(results.last.feedback.revealIntervalMicros, isNull);
  });

  testWidgets('addresses nested choice lines with independent policy values', (
    tester,
  ) async {
    final results = <SceneDialogueLinePolicy>[];
    await _open(tester, results: results);
    await _pick(tester, 'scene-line-scope', 'Start · Ligne 2 · Une réponse');
    await _enter(tester, 'scene-line-reveal-ms', '0');
    await _apply(tester);
    expect(results.last.lineIndex, 1);
    expect(results.last.feedback.revealIntervalMicros, 0);
    await _pick(tester, 'scene-line-scope', 'Start · Ligne 1 · Bonjour');
    expect(_text(tester, 'scene-line-reveal-ms'), '');
  });

  testWidgets(
    'rejects negative or submicrosecond time values without applying',
    (tester) async {
      final results = <SceneDialogueLinePolicy>[];
      await _open(tester, results: results);
      for (final value in ['-1', '0.0001', 'NaN']) {
        await _enter(tester, 'scene-line-reveal-ms', value);
        expect(
          tester
              .widget<StudioButton>(
                find.byKey(const ValueKey('scene-line-apply')),
              )
              .onPressed,
          isNull,
        );
        expect(results, isEmpty);
      }
      await _enter(tester, 'scene-line-reveal-ms', '0.001');
      await _apply(tester);
      expect(results.single.feedback.revealIntervalMicros, 1);
    },
  );

  testWidgets(
    'offers only nonlooping sounds and authors an effect cue without raw identifiers',
    (tester) async {
      final results = <SceneDialogueLinePolicy>[];
      await _open(tester, results: results);
      final select = tester.widget<StudioSelect>(
        find.byKey(const ValueKey('scene-line-sound')),
      );
      expect(select.options.keys, ['', 'fanfare']);
      await _pick(tester, 'scene-line-sound', 'Petite fanfare');
      await _enter(tester, 'scene-line-audio-volume', '75');
      await _enter(tester, 'scene-line-audio-offset', '2');
      await _apply(tester);
      final cue = results.single.feedback.audioCue!;
      expect(cue.mediaAssetId, 'fanfare');
      expect(cue.volume, .75);
      expect(cue.revealOffset, 2);
      expect(cue.role, DialogueAudioCueRole.effect);
      expect(cue.cueId, isNotEmpty);
    },
  );

  testWidgets('rejects an audio offset beyond the line and an invalid volume', (
    tester,
  ) async {
    final results = <SceneDialogueLinePolicy>[];
    await _open(tester, results: results);
    await _pick(tester, 'scene-line-sound', 'Petite fanfare');
    await _enter(tester, 'scene-line-audio-offset', '999');
    expect(
      tester
          .widget<StudioButton>(find.byKey(const ValueKey('scene-line-apply')))
          .onPressed,
      isNull,
    );
    await _enter(tester, 'scene-line-audio-offset', '0');
    await _enter(tester, 'scene-line-audio-volume', '101');
    expect(
      tester
          .widget<StudioButton>(find.byKey(const ValueKey('scene-line-apply')))
          .onPressed,
      isNull,
    );
    expect(results, isEmpty);
  });

  testWidgets('jingle role uses a beginning-of-line cue and can remove audio', (
    tester,
  ) async {
    final results = <SceneDialogueLinePolicy>[];
    await _open(tester, results: results);
    await _pick(tester, 'scene-line-sound', 'Petite fanfare');
    await _enter(tester, 'scene-line-audio-offset', '2');
    await _pick(tester, 'scene-line-audio-role', 'Jingle musical');
    expect(find.byKey(const ValueKey('scene-line-audio-offset')), findsNothing);
    await _apply(tester);
    expect(
      results.last.feedback.audioCue!.role,
      DialogueAudioCueRole.musicEffect,
    );
    expect(results.last.feedback.audioCue!.revealOffset, 0);
    await _pick(tester, 'scene-line-sound', 'Aucun son');
    await _apply(tester);
    expect(results.last.feedback.audioCue, isNull);
  });

  testWidgets(
    'diagnoses embedded feedback conflicts instead of pretending to apply',
    (tester) async {
      final results = <SceneDialogueLinePolicy>[];
      final feedback = DialogueLineFeedback(revealIntervalMicros: 12345);
      await _open(tester, feedback: feedback, embedded: true, results: results);
      await _enter(tester, 'scene-line-reveal-ms', '20');
      expect(
        tester
            .widget<StudioButton>(
              find.byKey(const ValueKey('scene-line-apply')),
            )
            .onPressed,
        isNull,
      );
      expect(find.textContaining('inscrits dans le document'), findsOneWidget);
      expect(results, isEmpty);
    },
  );
}

Future<void> _open(
  WidgetTester tester, {
  DialogueLineFeedback? feedback,
  bool embedded = false,
  required List<SceneDialogueLinePolicy> results,
}) async {
  tester.view.physicalSize = const Size(1000, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final project = ProjectManifest(
    name: 'Dialogue',
    maps: const [],
    tilesets: const [],
    cinematicMediaAssets: [
      CinematicMediaAsset(
        id: 'fanfare',
        label: 'Petite fanfare',
        kind: CinematicMediaAssetKind.sound,
        relativePath: 'audio/fanfare.ogg',
      ),
      CinematicMediaAsset(
        id: 'loop',
        label: 'Boucle exclue',
        kind: CinematicMediaAssetKind.sound,
        relativePath: 'audio/loop.ogg',
        loopByDefault: true,
      ),
      CinematicMediaAsset(
        id: 'music',
        label: 'Musique exclue',
        kind: CinematicMediaAssetKind.music,
        relativePath: 'audio/theme.ogg',
      ),
    ],
  );
  final document = RuntimeDialogueDocument(
    nodes: [
      RuntimeDialogueNode(
        title: 'Start',
        steps: [
          RuntimeDialogueLine(
            feedback?.plainText.isNotEmpty == true
                ? feedback!.plainText
                : 'Bonjour',
            feedback: embedded ? feedback : null,
          ),
          RuntimeDialogueChoiceBlock([
            RuntimeDialogueChoice(
              text: 'Oui',
              steps: [RuntimeDialogueLine('Une réponse')],
            ),
          ]),
        ],
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 600,
            child: SceneDialogueLinePolicyForm(
              project: project,
              document: document,
              payload: SceneYarnDialoguePayload(
                dialogueId: 'dialogue',
                linePolicies: [
                  if (feedback != null)
                    SceneDialogueLinePolicy(
                      nodeName: 'Start',
                      lineIndex: 0,
                      feedback: feedback,
                    ),
                ],
              ),
              onApply: results.add,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _text(WidgetTester tester, String key) => tester
    .widget<TextField>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(TextField),
      ),
    )
    .controller!
    .text;

Future<void> _enter(WidgetTester tester, String key, String value) async {
  final field = find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(TextField),
  );
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
}

Future<void> _apply(WidgetTester tester) async {
  final button = find.byKey(const ValueKey('scene-line-apply'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
}

Future<void> _pick(WidgetTester tester, String key, String label) async {
  final field = find.byKey(ValueKey(key));
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}
