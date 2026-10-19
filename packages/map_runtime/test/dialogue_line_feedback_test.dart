import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/dialogue_feedback_playback_port.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/application/parse_yarn_dialogue.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_dialogue_runtime_awaitable_adapter.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_dialogue_runtime_awaitable_result.dart';
import 'package:map_runtime/src/presentation/flame/dialogue_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/dialogue_text_speed.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('changing text speed cannot bypass a pending inline cue start', () async {
    final gate = Completer<void>();
    final port = _Port()..gate = gate;
    var finished = 0;
    final overlay = DialogueOverlayComponent(
      session: _session().withLinePolicies([
        SceneDialogueLinePolicy(nodeName: 'Start', lineIndex: 0,
          feedback: DialogueLineFeedback(
            audioCue: DialogueAudioCue(mediaAssetId: 'fanfare', cueId: 'inline', revealOffset: 2))),
      ]),
      viewportSize: Vector2(320, 240), feedbackPlaybackPort: port,
      textSpeed: RuntimeDialogueTextSpeed.normal,
      onFinished: (_) => finished++);
    await overlay.onLoad();
    overlay.advance();
    overlay.setTextSpeed(RuntimeDialogueTextSpeed.instant);
    overlay.advance();
    expect((overlay.currentSession.state as DialogueShowingLine).text, 'Found!');
    expect(port.played, ['inline']);
    expect(finished, 0);
    gate.complete();
    await Future<void>.delayed(Duration.zero);
    overlay.advance();
    expect((overlay.currentSession.state as DialogueShowingLine).text, 'Pocket.');
    overlay.onRemove();
  });

  test(
    'inline cue waits for unicode reveal threshold and plays only once',
    () async {
      final port = _Port();
      final overlay = _inlineOverlay(port: port);
      await overlay.onLoad();
      expect(port.played, isEmpty);
      overlay.update(0.024);
      expect(overlay.visibleText, isEmpty);
      expect(port.played, isEmpty);
      overlay.update(0.026);
      expect(overlay.visibleText, '😀a');
      expect(port.played, ['inline']);
      await Future<void>.delayed(Duration.zero);
      overlay.update(1);
      overlay.advance();
      overlay.advance();
      overlay.onRemove();
      expect(port.played, ['inline']);
    },
  );

  test(
    'manual and instant reveal trigger inline cue without duplicate input',
    () async {
      for (final instant in [false, true]) {
        final port = _Port();
        final overlay = _inlineOverlay(
          port: port,
          interval: instant ? 0 : 25000,
        );
        await overlay.onLoad();
        expect(port.played, instant ? ['inline'] : isEmpty);
        overlay.advance();
        overlay.advance();
        await Future<void>.delayed(Duration.zero);
        expect(port.played, ['inline']);
        overlay.onRemove();
      }
    },
  );

  test('removes a hidden inline cue without playing it', () async {
    final port = _Port();
    final overlay = _inlineOverlay(port: port);
    await overlay.onLoad();
    overlay.onRemove();
    overlay.update(10);
    overlay.advance();
    expect(port.played, isEmpty);
  });

  test(
    'a revisited cue id is not replayed on a later line in the session',
    () async {
      final port = _Port();
      final overlay = DialogueOverlayComponent(
        session: _session().withLinePolicies([
          for (final index in [0, 1])
            SceneDialogueLinePolicy(
              nodeName: 'Start',
              lineIndex: index,
              feedback: DialogueLineFeedback(
                revealIntervalMicros: 25000,
                audioCue: DialogueAudioCue(
                  mediaAssetId: 'fanfare',
                  cueId: 'inline',
                  revealOffset: 2,
                ),
              ),
            ),
        ]),
        viewportSize: Vector2(320, 240),
        feedbackPlaybackPort: port,
        onFinished: (_) {},
      );
      await overlay.onLoad();
      overlay.advance();
      await Future<void>.delayed(Duration.zero);
      overlay.advance();
      await Future<void>.delayed(Duration.zero);
      overlay.advance();
      overlay.update(1);
      expect(port.played, ['inline']);
      overlay.onRemove();
    },
  );

  test('session remaps unsegmented cue after unicode substitution', () {
    final session =
        DialogueSession.start(
          parseYarnFile('title: Start\n---\n{{ player_name }}!\n==='),
          'Start',
        )!.withLinePolicies([
          SceneDialogueLinePolicy(
            nodeName: 'Start',
            lineIndex: 0,
            feedback: DialogueLineFeedback(
              audioCue: DialogueAudioCue(
                mediaAssetId: 'fanfare',
                cueId: 'inline',
                revealOffset: '{{ player_name }}'.runes.length,
              ),
            ),
          ),
        ]);
    final mapped = session.mapText(
      (value) => value.replaceAll('{{ player_name }}', '😀Tom'),
    );
    final state = mapped.state as DialogueShowingLine;
    expect(state.text, '😀Tom!');
    expect(state.feedback!.audioCue!.revealOffset, 4);
  });

  test(
    'attaches exact scoped line feedback and preserves it across mapping',
    () {
      final feedback = _feedback();
      final session = _session().withLinePolicies([
        SceneDialogueLinePolicy(
          nodeName: 'Start',
          lineIndex: 0,
          feedback: feedback,
        ),
      ]);
      expect((session.state as DialogueShowingLine).feedback, feedback);
      expect(
        (session.mapText((text) => text).state as DialogueShowingLine).feedback,
        feedback,
      );
      expect(
        (session.withChoicePolicies(const []).state as DialogueShowingLine)
            .feedback,
        feedback,
      );
      expect(
        (session.advance()!.state as DialogueShowingLine).feedback,
        isNull,
      );
    },
  );

  test('rejects unknown scopes and segment text drift before presentation', () {
    expect(
      () => _session().withLinePolicies([
        SceneDialogueLinePolicy(
          nodeName: 'Missing',
          lineIndex: 0,
          feedback: _feedback(),
        ),
      ]),
      throwsArgumentError,
    );
    expect(
      () => _session().withLinePolicies([
        SceneDialogueLinePolicy(
          nodeName: 'Start',
          lineIndex: 2,
          feedback: _feedback(),
        ),
      ]),
      throwsArgumentError,
    );
    expect(
      () => _session().withLinePolicies([
        SceneDialogueLinePolicy(
          nodeName: 'Start',
          lineIndex: 0,
          feedback: DialogueLineFeedback(
            segments: [DialogueTextSegment('wrong')],
          ),
        ),
      ]),
      throwsFormatException,
    );
  });

  test('wait begins after reveal and does not consume reveal time', () async {
    final overlay = _overlay();
    await overlay.onLoad();
    overlay.update(0.05);
    expect(overlay.visibleText, 'Fo');
    overlay.update(0.10);
    expect(overlay.visibleText, 'Found!');
    expect(
      (overlay.currentSession.state as DialogueShowingLine).text,
      'Found!',
    );
    overlay.update(1.999);
    expect(
      (overlay.currentSession.state as DialogueShowingLine).text,
      'Found!',
    );
    overlay.update(0.0011);
    expect(
      (overlay.currentSession.state as DialogueShowingLine).text,
      'Pocket.',
    );
    overlay.update(20);
    expect(
      (overlay.currentSession.state as DialogueShowingLine).text,
      'Pocket.',
    );
  });

  test(
    'explicit line cadence survives a player speed preference change',
    () async {
      final overlay = _overlay();
      await overlay.onLoad();
      overlay.setTextSpeed(RuntimeDialogueTextSpeed.normal);
      overlay.setTextSpeed(RuntimeDialogueTextSpeed.instant);
      expect(overlay.visibleText, isEmpty);
      overlay.update(0.025);
      expect(overlay.visibleText, 'F');
    },
  );

  test('manual confirmation cannot bypass an authored auto wait', () async {
    var completed = 0;
    final overlay = _overlay(onFinished: (_) => completed++);
    await overlay.onLoad();
    overlay.advance();
    expect(overlay.isCurrentLineFullyRevealed, isTrue);
    expect(overlay.advance(), isTrue);
    expect(
      (overlay.currentSession.state as DialogueShowingLine).text,
      'Found!',
    );
    overlay.update(2);
    expect(
      (overlay.currentSession.state as DialogueShowingLine).text,
      'Pocket.',
    );
    overlay.advance();
    overlay.advance();
    expect(completed, 1);
    overlay.update(10);
    overlay.advance();
    expect(completed, 1);
  });

  test(
    'zero delay advances once and never spends dt on the next line',
    () async {
      final session = _session().withLinePolicies([
        SceneDialogueLinePolicy(
          nodeName: 'Start',
          lineIndex: 0,
          feedback: DialogueLineFeedback(
            revealIntervalMicros: 0,
            advance: DialogueLineAdvancePolicy.autoAfterReveal(0),
          ),
        ),
        SceneDialogueLinePolicy(
          nodeName: 'Start',
          lineIndex: 1,
          feedback: DialogueLineFeedback(
            revealIntervalMicros: 0,
            advance: DialogueLineAdvancePolicy.autoAfterReveal(1000000),
          ),
        ),
      ]);
      var completed = 0;
      final overlay = DialogueOverlayComponent(
        session: session,
        viewportSize: Vector2(320, 240),
        onFinished: (_) => completed++,
      );
      await overlay.onLoad();
      overlay.update(10);
      expect(
        (overlay.currentSession.state as DialogueShowingLine).text,
        'Pocket.',
      );
      expect(completed, 0);
      overlay.update(0.999);
      expect(completed, 0);
      overlay.update(0.0011);
      expect(completed, 1);
      overlay.update(20);
      expect(completed, 1);
    },
  );

  test(
    'plays a cue once and leaves it running across advance and close',
    () async {
      final port = _Port();
      final overlay = _overlay(port: port);
      await overlay.onLoad();
      expect(port.played, ['item']);
      overlay.update(0.2);
      overlay.update(2);
      overlay.advance();
      overlay.advance();
      overlay.onRemove();
      expect(port.played, ['item']);
    },
  );

  test('explicit feedback requires its audio port instead of silently omitting sound', () async {
    final overlay = _overlay(withCue: true);
    await expectLater(overlay.onLoad(), throwsStateError);
  });

  test(
    'rejects transformed text that no longer agrees with typed segments',
    () {
      final session = _session().withLinePolicies([
        SceneDialogueLinePolicy(
          nodeName: 'Start',
          lineIndex: 0,
          feedback: DialogueLineFeedback(
            segments: [DialogueTextSegment('Found'), DialogueTextSegment('!')],
          ),
        ),
      ]);
      expect(
        () => session.mapText((text) => text == 'Found!' ? 'Changed!' : text),
        throwsFormatException,
      );
    },
  );

  test('propagates line policies through Scene plan request', () async {
    final launcher = _Launcher();
    final feedback = _feedback();
    final intent = SceneRuntimePlanIntent.showDialogue(
      dialogueId: 'pickup',
      linePolicies: [
        SceneDialogueLinePolicy(
          nodeName: 'Start',
          lineIndex: 0,
          feedback: feedback,
        ),
      ],
    );
    await SceneDialogueRuntimeAwaitableAdapter(
      runtimeSourceId: 'source',
      launcher: launcher,
      createdAtEpochMs: () => 1,
    ).showDialogue(intent);
    expect(launcher.request!.linePolicies.single.feedback, feedback);
  });
}

DialogueOverlayComponent _inlineOverlay({
  required _Port port,
  int interval = 25000,
}) => DialogueOverlayComponent(
  session:
      DialogueSession.start(
        parseYarnFile('title: Start\n---\n😀abc\n==='),
        'Start',
      )!.withLinePolicies([
        SceneDialogueLinePolicy(
          nodeName: 'Start',
          lineIndex: 0,
          feedback: DialogueLineFeedback(
            revealIntervalMicros: interval,
            audioCue: DialogueAudioCue(
              mediaAssetId: 'fanfare',
              cueId: 'inline',
              revealOffset: 2,
            ),
          ),
        ),
      ]),
  viewportSize: Vector2(320, 240),
  feedbackPlaybackPort: port,
  onFinished: (_) {},
);

DialogueSession _session() => DialogueSession.start(
  parseYarnFile('''
title: Start
---
Found!
Pocket.
===
'''),
  'Start',
)!;

DialogueLineFeedback _feedback({bool withCue = false}) => DialogueLineFeedback(
  segments: [DialogueTextSegment('Found!')],
  revealIntervalMicros: 25000,
  advance: DialogueLineAdvancePolicy.autoAfterReveal(2000000),
  audioCue: withCue
      ? DialogueAudioCue(mediaAssetId: 'fanfare', cueId: 'item')
      : null,
);

DialogueOverlayComponent _overlay({
  void Function(String?)? onFinished,
  DialogueFeedbackPlaybackPort? port,
  bool withCue = false,
}) => DialogueOverlayComponent(
  session: _session().withLinePolicies([
    SceneDialogueLinePolicy(
      nodeName: 'Start',
      lineIndex: 0,
      feedback: _feedback(withCue: withCue || port != null),
    ),
  ]),
  viewportSize: Vector2(320, 240),
  feedbackPlaybackPort: port,
  onFinished: onFinished ?? (_) {},
);

final class _Port implements DialogueFeedbackPlaybackPort {
  final played = <String>[];
  Completer<void>? gate;
  @override
  Future<void> playCue(
    DialogueAudioCue cue, {
    required String playbackId,
  }) async {
    played.add(cue.cueId);
    await gate?.future;
  }
}

final class _Launcher implements SceneDialogueRuntimeLauncher {
  SceneDialogueRuntimeDialogueRequest? request;
  @override
  Future<SceneDialogueRuntimeAwaitableResult> showDialogue(
    SceneDialogueRuntimeDialogueRequest value,
  ) async {
    request = value;
    return const SceneDialogueRuntimeAwaitableResult.completed();
  }
}
