import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('cue reveal offset is strict bounded and restricted to effects', () {
    final cue = DialogueAudioCue.fromJson({
      'mediaAssetId': 'fanfare',
      'cueId': 'item',
      'revealOffset': 2,
    });
    expect(cue.toJson()['revealOffset'], 2);
    expect(
      cue,
      isNot(DialogueAudioCue(mediaAssetId: 'fanfare', cueId: 'item')),
    );
    for (final value in [-1, 1048577, 1.0, null, '2']) {
      expect(
        () => DialogueAudioCue.fromJson({
          'mediaAssetId': 'fanfare',
          'cueId': 'item',
          'revealOffset': value,
        }),
        throwsFormatException,
      );
    }
    expect(
      () => DialogueAudioCue.fromJson({
        'mediaAssetId': 'fanfare',
        'cueId': 'item',
        'revealOffset': 2,
        'role': 'musicEffect',
      }),
      throwsFormatException,
    );
  });

  test(
    'reveal offset counts runes and rejects positions outside line text',
    () {
      final feedback = DialogueLineFeedback.fromJson({
        'segments': [
          {'kind': 'text', 'text': '😀a'},
        ],
        'advance': {'kind': 'confirm'},
        'audioCue': {
          'mediaAssetId': 'fanfare',
          'cueId': 'item',
          'revealOffset': 2,
        },
      });
      feedback.validateText('😀a');
      expect(() => feedback.validateText('😀'), throwsFormatException);
      expect(
        () => DialogueLineFeedback.fromJson({
          ...feedback.toJson(),
          'audioCue': {
            'mediaAssetId': 'fanfare',
            'cueId': 'item',
            'revealOffset': 3,
          },
        }),
        throwsFormatException,
      );
    },
  );

  test(
    'text substitution remaps cue after placeholders using unicode runes',
    () {
      final text = '😀{{ player_name }} found it';
      final offset = '😀{{ player_name }}'.runes.length;
      final feedback = DialogueLineFeedback.fromJson({
        'segments': [
          {'kind': 'text', 'text': text},
        ],
        'advance': {'kind': 'confirm'},
        'audioCue': {
          'mediaAssetId': 'fanfare',
          'cueId': 'item',
          'revealOffset': offset,
        },
      });
      final mapped = feedback.mapText(
        (value) => value.replaceAll('{{ player_name }}', 'É😀'),
      );
      expect(mapped.plainText, '😀É😀 found it');
      expect(mapped.audioCue!.toJson()['revealOffset'], 3);
      mapped.validateText(mapped.plainText);
    },
  );

  test('text substitution refuses an ambiguous cue inside a placeholder', () {
    final feedback = DialogueLineFeedback.fromJson({
      'segments': [
        {'kind': 'text', 'text': '{{ player_name }} found it'},
      ],
      'advance': {'kind': 'confirm'},
      'audioCue': {
        'mediaAssetId': 'fanfare',
        'cueId': 'item',
        'revealOffset': 4,
      },
    });
    expect(
      () => feedback.mapText(
        (value) => value.replaceAll('{{ player_name }}', 'Tom'),
      ),
      throwsFormatException,
    );
  });

  test('cue remapping preserves styled segments and icon rune boundaries', () {
    final feedback = DialogueLineFeedback(
      segments: [
        DialogueTextSegment(
          '😀',
          style: DialogueSegmentStyle(colorArgb: 0xff123456),
        ),
        DialogueIconSegment(assetId: 'pocket', widthPx: 16, heightPx: 16),
        DialogueTextSegment('{{ player_name }}!'),
      ],
      audioCue: DialogueAudioCue(
        mediaAssetId: 'fanfare',
        cueId: 'item',
        revealOffset: 2 + '{{ player_name }}'.runes.length,
      ),
    );
    final mapped = feedback.mapText(
      (value) => value.replaceAll('{{ player_name }}', 'É😀'),
    );
    expect(mapped.audioCue!.revealOffset, 4);
    expect(mapped.segments[0], feedback.segments[0]);
    expect(mapped.segments[1], feedback.segments[1]);
    mapped.validateText('😀\uFFFCÉ😀!');
  });

  test('typed cue interruption is bounded and restricted to music effects', () {
    final interruption = DialogueBgmInterruption(fadeOutMs: 0, fadeInMs: 60000);
    expect(
      () => DialogueAudioCue(
        mediaAssetId: 'fanfare',
        cueId: 'item',
        bgmInterruption: interruption,
      ),
      throwsArgumentError,
    );
    final cue = DialogueAudioCue(
      mediaAssetId: 'fanfare',
      cueId: 'item',
      role: DialogueAudioCueRole.musicEffect,
      bgmInterruption: interruption,
    );
    expect(cue.role, DialogueAudioCueRole.musicEffect);
    expect(cue.bgmInterruption, interruption);
    expect(
      DialogueBgmInterruption.fromJson(
        Map<String, dynamic>.from(interruption.toJson()),
      ),
      interruption,
    );
    for (final value in [-1, 60001]) {
      expect(
        () => DialogueBgmInterruption(fadeOutMs: value, fadeInMs: 0),
        throwsArgumentError,
      );
      expect(
        () => DialogueBgmInterruption(fadeOutMs: 0, fadeInMs: value),
        throwsArgumentError,
      );
    }
  });

  test('music effect interruption survives strict cue round-trip', () {
    final json = _musicEffect();
    final cue = DialogueAudioCue.fromJson(json);
    expect(cue.toJson(), json);
    expect(
      DialogueAudioCue.fromJson(Map<String, dynamic>.from(cue.toJson())),
      cue,
    );
    expect(
      DialogueAudioCue.fromJson({
        ...json,
        'bgmInterruption': {'fadeOutMs': 0, 'fadeInMs': 60000},
      }).toJson()['bgmInterruption'],
      {'fadeOutMs': 0, 'fadeInMs': 60000},
    );
  });

  test(
    'effect defaults are omitted and music effects need no interruption',
    () {
      final base = {'mediaAssetId': 'fanfare', 'cueId': 'item'};
      expect(DialogueAudioCue.fromJson(base).toJson(), base);
      expect(
        DialogueAudioCue.fromJson({...base, 'role': 'effect'}).toJson(),
        base,
      );
      expect(
        DialogueAudioCue.fromJson({...base, 'role': 'musicEffect'}).toJson(),
        {...base, 'role': 'musicEffect'},
      );
    },
  );

  test('cue equality distinguishes audio roles and interruption durations', () {
    final cue = DialogueAudioCue.fromJson(_musicEffect());
    final same = DialogueAudioCue.fromJson(_musicEffect());
    final changed = DialogueAudioCue.fromJson({
      ..._musicEffect(),
      'bgmInterruption': {'fadeOutMs': 500, 'fadeInMs': 300},
    });
    final effect = DialogueAudioCue.fromJson({
      'mediaAssetId': 'fanfare',
      'cueId': 'item',
      'volume': 0.8,
    });
    expect(cue, same);
    expect(cue.hashCode, same.hashCode);
    expect({cue, same, changed, effect}, hasLength(3));
  });

  test('strict cue JSON rejects invalid roles and interruption policies', () {
    final base = {'mediaAssetId': 'fanfare', 'cueId': 'item'};
    for (final json in [
      {...base, 'role': null},
      {...base, 'role': 'bgm'},
      {...base, 'role': 1},
      {
        ...base,
        'bgmInterruption': {'fadeOutMs': 0, 'fadeInMs': 0},
      },
      {..._musicEffect(), 'bgmInterruption': null},
      {
        ..._musicEffect(),
        'bgmInterruption': {'fadeOutMs': -1, 'fadeInMs': 0},
      },
      {
        ..._musicEffect(),
        'bgmInterruption': {'fadeOutMs': 0, 'fadeInMs': 60001},
      },
      {
        ..._musicEffect(),
        'bgmInterruption': {'fadeOutMs': 1.0, 'fadeInMs': 0},
      },
      {
        ..._musicEffect(),
        'bgmInterruption': {'fadeOutMs': 0},
      },
      {
        ..._musicEffect(),
        'bgmInterruption': {
          'fadeOutMs': 0,
          'fadeInMs': 0,
          'pauseScript': 'anything',
        },
      },
    ]) {
      expect(() => DialogueAudioCue.fromJson(json), throwsFormatException);
    }
  });

  test(
    'scene and runtime dialogue retain music effect semantics on a line',
    () {
      final feedback = _feedback()..['audioCue'] = _musicEffect();
      final json = {
        'dialogueId': 'pickup',
        'linePolicies': [_policy()..['feedback'] = feedback],
      };
      expect(
        SceneYarnDialoguePayload.fromJson(json).toJson()['linePolicies'],
        json['linePolicies'],
      );
      final document = {
        'format': 1,
        'nodes': [
          {
            'title': 'Start',
            'steps': [
              {'kind': 'line', 'text': 'Found!', 'feedback': feedback},
            ],
          },
        ],
      };
      expect(
        const RuntimeDialogueDocumentCodec().decodeJson(document).toJson(),
        document,
      );
    },
  );

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

Map<String, dynamic> _musicEffect() => {
  'mediaAssetId': 'fanfare',
  'cueId': 'item',
  'volume': 0.8,
  'role': 'musicEffect',
  'bgmInterruption': {'fadeOutMs': 0, 'fadeInMs': 500},
};

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
