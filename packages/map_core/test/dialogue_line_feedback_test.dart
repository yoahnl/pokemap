import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('retains a finite cue gain and rejects out-of-range gains', () {
    final cue = DialogueAudioCue(
      mediaAssetId: 'fanfare',
      cueId: 'item',
      volume: 0.8,
    );
    expect(
      DialogueAudioCue.fromJson(Map<String, dynamic>.from(cue.toJson())),
      cue,
    );
    for (final volume in [-0.1, 1.1, double.infinity, double.nan]) {
      expect(
        () => DialogueAudioCue(
          mediaAssetId: 'fanfare',
          cueId: 'item',
          volume: volume,
        ),
        throwsArgumentError,
      );
      expect(
        () => DialogueAudioCue.fromJson({
          'mediaAssetId': 'fanfare',
          'cueId': 'item',
          'volume': volume,
        }),
        throwsFormatException,
      );
    }
  });
  test('retains scoped feedback including precise cadence and media cue', () {
    final payload = SceneYarnDialoguePayload.fromJson(_payload());
    expect(payload.toJson()['linePolicies'], _payload()['linePolicies']);
    final encoded = payload.toJson();
    expect(SceneYarnDialoguePayload.fromJson(encoded), payload);
  });

  test(
    'rejects duplicate and invalid line scopes instead of dropping them',
    () {
      for (final policies in [
        [_policy(), _policy()],
        [_policy()..['lineIndex'] = -1],
        [_policy()..['nodeName'] = ' Start '],
      ]) {
        expect(
          () => SceneYarnDialoguePayload.fromJson({
            'dialogueId': 'pickup',
            'linePolicies': policies,
          }),
          throwsA(anyOf(isA<FormatException>(), isA<ValidationException>())),
        );
      }
    },
  );

  test('rejects malformed advancement, cadence and unknown control data', () {
    for (final presentation in [
      _feedback()..['revealIntervalMicros'] = -1,
      _feedback()..['advance'] = {'kind': 'autoAfterReveal', 'delayMicros': -1},
      _feedback()..['advance'] = {'kind': 'confirm', 'delayMicros': 1},
      _feedback()..['advance'] = {'kind': 'script', 'source': 'anything'},
      _feedback()..['script'] = 'pbItemBall',
      _feedback()..['audioCue'] = {'mediaAssetId': '', 'cueId': 'item'},
    ]) {
      expect(
        () => SceneYarnDialoguePayload.fromJson({
          'dialogueId': 'pickup',
          'linePolicies': [_policy()..['feedback'] = presentation],
        }),
        throwsA(anyOf(isA<FormatException>(), isA<ValidationException>())),
      );
    }
  });

  test('runtime document retains typed presentation attached to a line', () {
    final json = {
      'format': 1,
      'nodes': [
        {
          'title': 'Start',
          'steps': [
            {'kind': 'line', 'text': 'Found!', 'feedback': _feedback()},
          ],
        },
      ],
    };
    final document = const RuntimeDialogueDocumentCodec().decodeJson(json);
    expect(document.toJson(), json);
  });

  test('runtime document rejects segments that change the line text', () {
    expect(
      () => const RuntimeDialogueDocumentCodec().decodeJson({
        'format': 1,
        'nodes': [
          {
            'title': 'Start',
            'steps': [
              {'kind': 'line', 'text': 'Different!', 'feedback': _feedback()},
            ],
          },
        ],
      }),
      throwsFormatException,
    );
  });
}

Map<String, Object?> _payload() => {
  'dialogueId': 'pickup',
  'linePolicies': [_policy()],
};

Map<String, Object?> _policy() => {
  'nodeName': 'Start',
  'lineIndex': 0,
  'feedback': _feedback(),
};

Map<String, Object?> _feedback() => {
  'segments': [
    {
      'kind': 'text',
      'text': 'Found',
      'style': {'colorArgb': 0xff0070f8},
    },
    {'kind': 'text', 'text': '!'},
  ],
  'revealIntervalMicros': 12500,
  'advance': {'kind': 'autoAfterReveal', 'delayMicros': 2000000},
  'audioCue': {'mediaAssetId': 'fanfare', 'cueId': 'item'},
};
