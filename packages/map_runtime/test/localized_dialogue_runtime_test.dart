import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/application/load_dialogue_content.dart';
import 'package:map_runtime/src/application/resolve_dialogue.dart';

void main() {
  late Directory root;
  late File file;
  late DialogueLocalization localization;
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
            'Bonjour',
            characterId: 'mother',
            portraitStateId: 'happy',
          ),
          RuntimeDialogueChoiceBlock([
            RuntimeDialogueChoice(
              text: 'Partir',
              outcomeId: 'leave',
              steps: [RuntimeDialogueLine('Au revoir')],
            ),
            RuntimeDialogueChoice(text: 'Rester', outcomeId: 'stay', steps: []),
          ]),
        ],
      ),
    ],
  );
  setUp(() async {
    root = await Directory.systemTemp.createTemp('localized-runtime-');
    file = File('${root.path}/talk.json');
    await file.writeAsBytes(
      const RuntimeDialogueDocumentCodec().encodeUtf8(document),
    );
    localization =
        DialogueLocalization(
              sourceLocale: 'fr',
              units: [
                for (final (index, scope) in runtimeDialogueTextScopes(
                  document,
                ).indexed)
                  DialogueTextUnit(
                    id: 'text-$index',
                    binding: scope.binding,
                    kind: scope.kind,
                    source: scope.text,
                  ),
              ],
            )
            .translate('text-0', 'en', 'Hello')
            .translate('text-1', 'en', 'Leave')
            .translate('text-3', 'en', 'Stay')
            .translate('text-0', 'de', 'Hallo');
  });
  tearDown(() => root.delete(recursive: true));
  ResolvedDialogue resolved(String locale, {DialogueLocalization? catalog}) =>
      ResolvedDialogue(
        absoluteFilePath: file.path,
        dialogueId: 'talk',
        localization: catalog ?? localization,
        preferredLocale: locale,
        locales: locales,
      );
  String text(DialogueSession? session) =>
      (session!.state as DialogueShowingLine).text;

  test(
    'the same cached document follows the language and current metadata',
    () async {
      expect(text(await loadDialogueContent(resolved('en'))), 'Hello');
      expect(text(await loadDialogueContent(resolved('fr-CA'))), 'Bonjour');
      expect(text(await loadDialogueContent(resolved('de'))), 'Bonjour');
      expect(text(await loadDialogueContent(resolved('es'))), 'Bonjour');
      final changed = localization.translate('text-0', 'en', 'Welcome');
      expect(
        text(await loadDialogueContent(resolved('en', catalog: changed))),
        'Welcome',
      );
      expect(text(await loadDialogueContent(resolved('en'))), 'Hello');
    },
  );

  test(
    'localized lines retain portraits and source-based feedback policies',
    () async {
      final loaded = (await loadDialogueContent(resolved('en')))!;
      final style = DialogueSegmentStyle(colorArgb: 0xffaabbcc);
      final configured = loaded.withLinePolicies([
        SceneDialogueLinePolicy(
          nodeName: 'Start',
          lineIndex: 0,
          feedback: DialogueLineFeedback(
            segments: [DialogueTextSegment('Bonjour', style: style)],
            revealIntervalMicros: 30000,
            advance: DialogueLineAdvancePolicy.autoAfterReveal(1000),
          ),
        ),
      ]);
      final state = configured.state as DialogueShowingLine;
      expect(state.text, 'Hello');
      expect(state.characterId, 'mother');
      expect(state.portraitStateId, 'happy');
      expect(state.feedback!.plainText, 'Hello');
      expect(
        (state.feedback!.segments.single as DialogueTextSegment).style,
        style,
      );
      expect(state.feedback!.revealIntervalMicros, 30000);
      expect(
        state.feedback!.advance,
        DialogueLineAdvancePolicy.autoAfterReveal(1000),
      );
      final choice = configured.advance()!.state as DialogueWaitingForChoice;
      expect(choice.choices.map((item) => item.text), ['Leave', 'Stay']);
      expect(choice.choices.map((item) => item.outcomeId), ['leave', 'stay']);
    },
  );

  test('bad metadata is refused without altering the compiled file', () async {
    final before = await file.readAsBytes();
    final broken = localization.withUnits([
      localization.units.first.copyWith(binding: '/Missing/0'),
      ...localization.units.skip(1),
    ]);
    expect(await loadDialogueContent(resolved('en', catalog: broken)), isNull);
    expect(await file.readAsBytes(), before);
    expect(text(await loadDialogueContent(resolved('en'))), 'Hello');
  });

  for (final locale in ['fr', 'en']) {
    test(
      'translated choices preserve cancellation and outcomes in $locale',
      () async {
        final loaded = (await loadDialogueContent(resolved(locale)))!
            .withChoicePolicies(const [
              SceneDialogueChoicePolicy(
                nodeName: 'Start',
                cancellation: SceneDialogueChoiceCancellation.choice('leave'),
              ),
            ]);
        final waiting = loaded.advance()!;
        expect(waiting.choiceCancellationOutcomeId, 'leave');
        final cancelled = waiting.cancelChoice()!;
        final confirmed = waiting.confirmChoice()!;
        expect(cancelled.selectedOutcomeId, 'leave');
        expect(confirmed.selectedOutcomeId, 'leave');
        expect(text(cancelled), 'Au revoir');
        expect(text(confirmed), 'Au revoir');
      },
    );
  }

  test(
    'a legacy path associates only its exact unique catalog entry',
    () async {
      final entry = ProjectDialogueEntry(
        id: 'talk',
        name: 'Accueil',
        relativePath: 'talk.json',
        localization: localization,
      );
      final request = resolveDialogue(
        entityId: 'mother',
        ref: const DialogueRef(
          dialogueId: 'wrong-id',
          scriptPathRelative: './talk.json',
        ),
        projectRootDirectory: root.path,
        dialogues: [entry],
        preferredLocale: 'en',
        locales: locales,
      )!;
      expect(text(await loadDialogueContent(request)), 'Hello');
      expect(
        resolveDialogue(
          entityId: 'mother',
          ref: const DialogueRef(
            dialogueId: 'talk',
            scriptPathRelative: 'talk.json',
          ),
          projectRootDirectory: root.path,
          dialogues: [
            entry,
            entry.copyWith(id: 'other'),
          ],
          preferredLocale: 'en',
          locales: locales,
        ),
        isNull,
      );
    },
  );

  test('an old monolingual Yarn dialogue remains readable', () async {
    final legacy = File('${root.path}/old.yarn');
    await legacy.writeAsString('title: Start\n---\nAncien dialogue\n===\n');
    expect(
      text(
        await loadDialogueContent(
          ResolvedDialogue(absoluteFilePath: legacy.path, dialogueId: 'old'),
        ),
      ),
      'Ancien dialogue',
    );
  });

  test('a legacy path keeps its original first-node entry point', () async {
    final entry = ProjectDialogueEntry(
      id: 'talk',
      name: 'Accueil',
      relativePath: 'talk.json',
      defaultStartNode: 'Later',
      localization: localization,
    );
    final resolved = resolveDialogue(
      entityId: 'mother',
      ref: const DialogueRef(
        dialogueId: 'talk',
        scriptPathRelative: 'talk.json',
      ),
      projectRootDirectory: root.path,
      dialogues: [entry],
      preferredLocale: 'en',
      locales: locales,
    )!;
    expect(resolved.startNode, isNull);
    expect(text(await loadDialogueContent(resolved)), 'Hello');
    expect(
      resolveDialogue(
        entityId: 'mother',
        ref: const DialogueRef(dialogueId: 'talk'),
        projectRootDirectory: root.path,
        dialogues: [entry],
      )!.startNode,
      'Later',
    );
  });

  test('localized content requires the official locale policy', () async {
    final before = await file.readAsBytes();
    expect(
      await loadDialogueContent(
        ResolvedDialogue(
          absoluteFilePath: file.path,
          dialogueId: 'talk',
          localization: localization,
          preferredLocale: 'en',
        ),
      ),
      isNull,
    );
    expect(await file.readAsBytes(), before);
  });
}
