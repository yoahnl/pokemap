import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final locales = ProjectLocalePolicy(
    supportedLocales: ['fr', 'en', 'es'],
    fallbackLocale: 'fr',
  );
  final document = RuntimeDialogueDocument(
    nodes: [
      RuntimeDialogueNode(
        title: 'Start',
        steps: [
          RuntimeDialogueLine(
            'Maman: Bonjour',
            characterId: 'mother',
            portraitStateId: 'happy',
          ),
          RuntimeDialogueChoiceBlock([
            RuntimeDialogueChoice(
              text: 'Partir',
              outcomeId: 'leave',
              steps: [
                RuntimeDialogueLine('Au revoir'),
                RuntimeDialogueJump('End'),
              ],
            ),
            RuntimeDialogueChoice(text: 'Rester', outcomeId: 'stay', steps: []),
          ]),
        ],
      ),
      RuntimeDialogueNode(title: 'End', steps: [RuntimeDialogueLine('Fin')]),
    ],
  );
  final source = DialogueLocalization(
    sourceLocale: 'fr',
    units: [
      for (final (index, scope) in runtimeDialogueTextScopes(document).indexed)
        DialogueTextUnit(
          id: 'text-$index',
          binding: scope.binding,
          kind: scope.kind,
          source: scope.text,
        ),
    ],
  );
  final translated = source
      .translate('text-0', 'en', 'Maman: Hello')
      .translate('text-1', 'en', 'Leave')
      .translate('text-3', 'en', 'Stay')
      .translate('text-0', 'de', 'Maman: Hallo');
  RuntimeDialogueDocument resolve(
    String locale, {
    DialogueLocalization? localization,
    ProjectLocalePolicy? policy,
  }) => resolveRuntimeDialogueLocalization(
    document,
    localization ?? translated,
    preferredLocale: locale,
    locales: policy ?? locales,
  );

  test(
    'resolves every choice recursively without changing outcomes or portraits',
    () {
      final english = resolve('en-GB');
      expect(runtimeDialogueTextScopes(english).map((scope) => scope.text), [
        'Maman: Hello',
        'Leave',
        'Au revoir',
        'Stay',
        'Fin',
      ]);
      expect(
        runtimeDialogueTextShape(english),
        runtimeDialogueTextShape(document),
      );
      final line = english.nodes.first.steps.first as RuntimeDialogueLine;
      expect(line.characterId, 'mother');
      expect(line.portraitStateId, 'happy');
      expect(
        (english.nodes.first.steps[1] as RuntimeDialogueChoiceBlock).choices
            .map((choice) => choice.outcomeId),
        ['leave', 'stay'],
      );
      expect(
        (document.nodes.first.steps.first as RuntimeDialogueLine).text,
        'Maman: Bonjour',
      );
    },
  );

  test('regional, missing and unshipped locales follow the project policy', () {
    expect(
      runtimeDialogueTextScopes(resolve('fr-CA')).first.text,
      'Maman: Bonjour',
    );
    expect(
      runtimeDialogueTextScopes(resolve('es')).first.text,
      'Maman: Bonjour',
    );
    expect(
      runtimeDialogueTextScopes(resolve('de')).first.text,
      'Maman: Bonjour',
    );
    final fallback = ProjectLocalePolicy(
      supportedLocales: ['fr', 'en', 'es'],
      fallbackLocale: 'en',
    );
    expect(
      runtimeDialogueTextScopes(resolve('es', policy: fallback)).first.text,
      'Maman: Hello',
    );
  });

  test('keeps repeated source texts bound to their own identities', () {
    final repeated = RuntimeDialogueDocument(
      nodes: [
        RuntimeDialogueNode(
          title: 'Same',
          steps: [
            RuntimeDialogueLine('Bonjour'),
            RuntimeDialogueLine('Bonjour'),
          ],
        ),
      ],
    );
    final catalog = DialogueLocalization(
      sourceLocale: 'fr',
      units: [
        DialogueTextUnit(
          id: 'first',
          binding: '/Same/0',
          kind: DialogueTextKind.line,
          source: 'Bonjour',
        ),
        DialogueTextUnit(
          id: 'second',
          binding: '/Same/1',
          kind: DialogueTextKind.line,
          source: 'Bonjour',
        ),
      ],
    ).translate('first', 'en', 'Hello').translate('second', 'en', 'Welcome');
    final result = resolveRuntimeDialogueLocalization(
      repeated,
      catalog,
      preferredLocale: 'en',
      locales: locales,
    );
    expect(runtimeDialogueTextScopes(result).map((scope) => scope.text), [
      'Hello',
      'Welcome',
    ]);
  });

  test(
    'rejects incomplete, stale, extra and wrongly typed compiled bindings',
    () {
      final first = source.units.first;
      for (final units in [
        source.units.skip(1).toList(),
        [first.copyWith(source: 'Obsolete'), ...source.units.skip(1)],
        [first.copyWith(binding: '/Missing/0'), ...source.units.skip(1)],
        [
          DialogueTextUnit(
            id: first.id,
            binding: first.binding,
            kind: DialogueTextKind.choice,
            source: first.source,
          ),
          ...source.units.skip(1),
        ],
        [
          ...source.units,
          DialogueTextUnit(
            id: 'extra',
            binding: '/Extra/0',
            kind: DialogueTextKind.line,
            source: 'Absent',
          ),
        ],
      ]) {
        expect(
          () => resolve(
            'en',
            localization: DialogueLocalization(
              sourceLocale: 'fr',
              units: units,
            ),
          ),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'preserves styles, timing and advancement when replacing one text segment',
    () {
      final style = DialogueSegmentStyle(colorArgb: 0xffaabbcc);
      final feedback = DialogueLineFeedback(
        segments: [DialogueTextSegment('Bonjour', style: style)],
        revealIntervalMicros: 20000,
        advance: DialogueLineAdvancePolicy.autoAfterReveal(1000),
      );
      final result = retargetDialogueLineFeedback(
        feedback,
        sourceText: 'Bonjour',
        text: 'Hello',
      )!;
      expect(result.plainText, 'Hello');
      expect((result.segments.single as DialogueTextSegment).style, style);
      expect(result.revealIntervalMicros, feedback.revealIntervalMicros);
      expect(result.advance, feedback.advance);
      expect(feedback.plainText, 'Bonjour');
    },
  );

  test(
    'refuses rich segmentation instead of discarding presentation rules',
    () {
      final feedback = DialogueLineFeedback(
        segments: [DialogueTextSegment('Bon'), DialogueTextSegment('jour')],
      );
      expect(
        () => retargetDialogueLineFeedback(
          feedback,
          sourceText: 'Bonjour',
          text: 'Hello',
        ),
        throwsFormatException,
      );
      expect(
        retargetDialogueLineFeedback(
          feedback,
          sourceText: 'Bonjour',
          text: 'Bonjour',
        ),
        same(feedback),
      );
    },
  );

  test(
    'a shorter translation refuses an invalid cue and preserves valid cues',
    () {
      final cue = DialogueAudioCue(
        mediaAssetId: 'fanfare',
        cueId: 'item',
        revealOffset: 6,
      );
      final feedback = DialogueLineFeedback(audioCue: cue);
      expect(
        () => retargetDialogueLineFeedback(
          feedback,
          sourceText: 'Bonjour',
          text: 'Hi',
        ),
        throwsFormatException,
      );
      final result = retargetDialogueLineFeedback(
        feedback,
        sourceText: 'Bonjour',
        text: 'Welcome',
      )!;
      expect(result.audioCue, same(cue));
      expect(feedback.audioCue!.revealOffset, 6);
    },
  );

  test('the project locale policy refuses malformed or duplicated tags', () {
    for (final supported in [
      ['!!!'],
      ['fr', 'FR'],
    ]) {
      expect(
        () => ProjectLocalePolicy(
          supportedLocales: supported,
          fallbackLocale: supported.first,
        ),
        throwsArgumentError,
      );
    }
  });
}
