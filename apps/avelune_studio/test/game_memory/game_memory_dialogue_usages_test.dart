import 'package:avelune_studio/features/game_memory/application/game_memory_controller.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/story_draft/domain/story_dialogue_source.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core.dart';

import 'game_memory_fakes.dart';

StoryDialogueSource localizedFactDialogue(String fact) {
  final source =
      '// Ignorer {{ fact.comment }}\ntitle: Start\n---\nValeur {{ fact.$fact }}.\n===\n';
  final parsed = readLocalizedDialogue(source: source, sourceLocale: 'fr');
  final unit = parsed.localization.units.single.id;
  final localization = parsed.localization
      .translate(unit, 'en', 'Value {{ fact.$fact }}.')
      .translate(unit, 'es', 'Valor {{ fact.$fact }}.');
  return StoryDialogueSource(
    entry: ProjectDialogueEntry(
      id: 'shared',
      name: 'Dialogue partagé',
      relativePath: 'dialogues/shared.yarn',
      localization: localization,
    ),
    source: source,
  );
}

void main() {
  late FakeNarrativeIndex index;
  late FakeMemoryStaging staging;
  late GameMemoryController memory;

  setUp(() async {
    index = FakeNarrativeIndex()
      ..addFacts([memoryFact('met', 'Rencontre'), memoryFact('door', 'Porte')]);
    for (final id in ['met', 'door']) {
      index.users[id] = NarrativeUsages(
        owners: const [],
        notCovered: const ['dialogueDefinitions', 'dialogueTextFacts'],
      );
    }
    staging = FakeMemoryStaging();
    memory = GameMemoryController(
      port: index,
      staging: staging,
      changed: () {},
    );
    addTearDown(memory.dispose);
    await memory.open();
    for (final id in ['met', 'door']) {
      memory.select(id);
      await Future<void>.delayed(Duration.zero);
    }
  });

  test('shared translations count one document and undo restores its known source contribution', () {
    final base = localizedFactDialogue('met');
    final next = localizedFactDialogue('door');
    staging.draft
      ..load(StoryDraftKind.dialogue, base.id, base)
      ..put(StoryDraftKind.dialogue, next);
    final uses = memory.usages['door']!;
    expect(uses.owners, const [
      NarrativeOwner(
        kind: NarrativeOwnerKind.dialogue,
        id: 'shared',
        role: NarrativeFactRole.read,
      ),
    ]);
    expect(uses.notCovered, ['dialogueDefinitions', 'dialogueTextFacts']);
    expect(memory.usages['comment'], isNull);
    expect(base.entry.localization!.units.single.translations, hasLength(2));
    staging.draft.undo();
    expect(memory.usages['door']!.owners, isEmpty);
    expect(
      memory.usages['met']!.owners.single.kind,
      NarrativeOwnerKind.dialogue,
    );
    staging.draft.redo();
    expect(memory.usages['door']!.owners, uses.owners);
    expect(index.userRequests, hasLength(2));
  });

  test('an unanalysable document keeps an explicit coverage gap and prevents discarding a created fact', () async {
    final id = memory.createFact('Brouillon', NarrativeValueKind.boolean)!;
    await Future<void>.delayed(Duration.zero);
    final base = localizedFactDialogue('met');
    staging.draft
      ..load(StoryDraftKind.dialogue, base.id, base)
      ..put(
        StoryDraftKind.dialogue,
        StoryDialogueSource(
          entry: base.entry,
          source: 'title: Start\n---\n<<if unknown>>\n===\n',
        ),
      );
    expect(memory.usages['met']!.notCovered, contains('draftAnalysis'));
    expect(memory.discardCreated(id), isFalse);
    staging.draft.undo();
    expect(memory.usages['met']!.notCovered, isNot(contains('draftAnalysis')));
    expect(memory.discardCreated(id), isTrue);
  });

  test('a created fact keeps identity and translations when a premature rename is refused', () {
    final id = memory.createFact('Brouillon', NarrativeValueKind.boolean)!;
    final dialogue = localizedFactDialogue(id);
    staging.draft
      ..load(StoryDraftKind.dialogue, dialogue.id, null)
      ..put(StoryDraftKind.dialogue, dialogue);
    final version = staging.draft.versionOf(StoryDraftKind.dialogue);
    expect(memory.renameFact(id, 'Autre nom'), isFalse);
    expect(memory.current(id)!.id, id);
    expect(
      staging.draft.currentOf(StoryDraftKind.dialogue, dialogue.id),
      same(dialogue),
    );
    expect(staging.draft.versionOf(StoryDraftKind.dialogue), version);
    expect(memory.usages[id]!.owners.single.id, dialogue.id);
    expect(memory.usages.draftCovered, isTrue);
  });

  test(
    'a valid line with an unknown command is not accepted as complete analysis',
    () {
      final base = localizedFactDialogue('met');
      staging.draft
        ..load(StoryDraftKind.dialogue, base.id, base)
        ..put(
          StoryDraftKind.dialogue,
          StoryDialogueSource(
            entry: base.entry,
            source: base.source.replaceFirst(
              '===',
              '<<commande_inconnue>>\n===',
            ),
          ),
        );
      expect(memory.usages['met']!.notCovered, contains('draftAnalysis'));
      expect(memory.usages.draftCovered, isFalse);
    },
  );

  test('abandoning a creation checks a preexisting reference to its formerly missing id', () async {
    index.userLoader = (ids) async => {
      for (final id in ids)
        id: NarrativeUsages(
          owners: const [
            NarrativeOwner(
              kind: NarrativeOwnerKind.scene,
              id: 'saved-reference',
              role: NarrativeFactRole.read,
            ),
          ],
          notCovered: const ['dialogueDefinitions'],
        ),
    };
    final id = memory.createFact('Brouillon', NarrativeValueKind.boolean)!;
    expect(memory.discardCreated(id), isFalse);
    await Future<void>.delayed(Duration.zero);
    expect(index.userRequests.last, [id]);
    expect(memory.usages[id]!.owners.single.id, 'saved-reference');
    expect(memory.discardCreated(id), isFalse);
  });
}
