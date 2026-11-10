import 'package:avelune_studio/features/scenes/application/scene_dialogue_line_policy_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

SceneDialogueLinePolicyDraft _draft({
  DialogueLineFeedback? feedback,
  bool embedded = false,
}) {
  return SceneDialogueLinePolicyDraft(
    project: ProjectManifest(
      name: 'Dialogue',
      maps: [],
      tilesets: [],
      cinematicMediaAssets: [
        CinematicMediaAsset(
          id: 'fanfare',
          label: 'Petite fanfare',
          kind: CinematicMediaAssetKind.sound,
          relativePath: 'audio/fanfare.ogg',
        ),
        CinematicMediaAsset(
          id: 'loop',
          label: 'Boucle',
          kind: CinematicMediaAssetKind.sound,
          relativePath: 'audio/loop.ogg',
          loopByDefault: true,
        ),
        CinematicMediaAsset(
          id: 'music',
          label: 'Musique',
          kind: CinematicMediaAssetKind.music,
          relativePath: 'audio/music.ogg',
        ),
      ],
    ),
    document: RuntimeDialogueDocument(
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
    ),
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
  );
}

void main() {
  test('fractional rhythm preserves rich text, icon, jingle and interruption metadata', () {
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
        bgmInterruption: DialogueBgmInterruption(fadeOutMs: 123, fadeInMs: 456),
      ),
    );
    final draft = _draft(feedback: feedback);
    expect(draft.revealMs, '12.501');
    expect(draft.delayMs, '33.001');
    draft.revealMs = '19.125';
    expect(draft.prepared.nodeName, 'Start');
    expect(draft.prepared.lineIndex, 0);
    expect(draft.feedback.revealIntervalMicros, 19125);
    expect(draft.feedback.segments, feedback.segments);
    expect(draft.feedback.audioCue, feedback.audioCue);
    expect(draft.feedback.advance, feedback.advance);
  });

  test('automatic advancement returns to confirmation without inventing reveal timing', () {
    final draft = _draft()
      ..advance = DialogueLineAdvanceKind.autoAfterReveal
      ..delayMs = '500.125';
    expect(
      draft.feedback.advance,
      DialogueLineAdvancePolicy.autoAfterReveal(500125),
    );
    draft.advance = DialogueLineAdvanceKind.confirm;
    expect(draft.feedback.advance, const DialogueLineAdvancePolicy.confirm());
    expect(draft.feedback.revealIntervalMicros, isNull);
  });

  test('nested choice lines keep independent addresses and policy values', () {
    final draft = _draft()..scopeIndex = 1;
    draft.read();
    draft.revealMs = '0';
    expect(draft.prepared.lineIndex, 1);
    expect(draft.feedback.revealIntervalMicros, 0);
    draft.scopeIndex = 0;
    draft.read();
    expect(draft.revealMs, '');
  });

  test(
    'negative, nonfinite and submicrosecond timing cannot produce a policy',
    () {
      final draft = _draft();
      for (final value in ['-1', '0.0001', 'NaN']) {
        draft.revealMs = value;
        expect(() => draft.prepared, throwsFormatException, reason: value);
      }
      draft.revealMs = '0.001';
      expect(draft.feedback.revealIntervalMicros, 1);
    },
  );

  test(
    'audio choices exclude loops and music and create a stable authored cue',
    () {
      final draft = _draft()
        ..mediaId = 'fanfare'
        ..volume = '75'
        ..offset = '2';
      expect(draft.sounds.keys, ['', 'fanfare']);
      final cue = draft.feedback.audioCue!;
      expect(cue.mediaAssetId, 'fanfare');
      expect(cue.volume, .75);
      expect(cue.revealOffset, 2);
      expect(cue.role, DialogueAudioCueRole.effect);
      expect(cue.cueId, isNotEmpty);
      expect(draft.feedback.audioCue!.cueId, cue.cueId);
    },
  );

  test('invalid audio offset and volume are refused', () {
    final draft = _draft()
      ..mediaId = 'fanfare'
      ..offset = '999';
    expect(() => draft.feedback, throwsFormatException);
    draft.offset = '0';
    draft.volume = '101';
    expect(() => draft.feedback, throwsFormatException);
  });

  test('a jingle starts with the line and can be removed explicitly', () {
    final draft = _draft()
      ..mediaId = 'fanfare'
      ..offset = '2'
      ..role = DialogueAudioCueRole.musicEffect;
    expect(draft.feedback.audioCue!.role, DialogueAudioCueRole.musicEffect);
    expect(draft.feedback.audioCue!.revealOffset, 0);
    draft.mediaId = '';
    expect(draft.feedback.audioCue, isNull);
  });

  test('embedded feedback cannot be silently overridden', () {
    final draft = _draft(
      feedback: DialogueLineFeedback(revealIntervalMicros: 12345),
      embedded: true,
    )..revealMs = '20';
    expect(
      () => draft.feedback,
      throwsA(
        isA<FormatException>().having(
          (failure) => failure.message,
          'message',
          contains('inscrits dans le document'),
        ),
      ),
    );
  });
}
