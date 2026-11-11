import 'dart:typed_data';

import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_authoring.dart';
import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:avelune_studio/features/dialogues/domain/dialogue_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core.dart';

import '../support/dialogue_workspace_owner_fixture.dart';
import '../support/ui09_runtime_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DialogueWorkspaceOwnerFixture f;
  late DialogueWorkspaceController c;
  setUp(() async {
    f = await DialogueWorkspaceOwnerFixture.create();
    c = f.dialogues;
    expect(await c.open(ui09DialogueId), isTrue, reason: c.error);
  });
  tearDown(() => f.dispose());

  DialogueEditorNode node(String title) =>
      c.active!.document.nodes.firstWhere((n) => n.title == title);
  DeLineStep firstLine() =>
      node('Accueil').steps.whereType<DeLineStep>().first;
  DeChoiceStep choice() =>
      node('Accueil').steps.whereType<DeChoiceStep>().single;

  test('default line and narration carry their starter texts', () {
    final lineId = c.addDefaultLine(node('Depart').id, narration: false)!;
    final narrationId = c.addDefaultLine(node('Depart').id, narration: true)!;
    final steps = dialogueSteps(node('Depart').steps);
    expect(
      steps.whereType<DeLineStep>().firstWhere((s) => s.id == lineId).body,
      'Bonjour !',
    );
    expect(
      steps.whereType<DeNarrationStep>().firstWhere((s) => s.id == narrationId).text,
      'Une nouvelle narration.',
    );
    expect(dialogueDefaultLineText, 'Bonjour !');
    expect(dialogueDefaultNarrationText, 'Une nouvelle narration.');
  });

  test('a default line on an absent suite is refused and reported', () {
    final before = c.active!.source;
    expect(c.addDefaultLine('absent', narration: false), isNull);
    expect(c.error, isNotNull);
    expect(c.active!.source, before);
  });

  test('a new choice starts with the Oui and Non responses in that order', () {
    final id = c.addChoiceWithStarterResponses(node('Depart').id)!;
    final created = dialogueSteps(node('Depart').steps)
        .whereType<DeChoiceStep>()
        .firstWhere((s) => s.id == id);
    expect(created.branches.map((b) => b.label), ['Oui', 'Non']);
    expect(dialogueChoiceStarterLabels, ['Oui', 'Non']);
  });

  test('no starter response is added when the choice itself is refused', () {
    final before = c.active!.source;
    expect(c.addChoiceWithStarterResponses('absent'), isNull);
    expect(c.active!.source, before);
  });

  test('a new response on an existing choice is named Nouvelle réponse', () {
    final id = c.addDefaultResponse(choice().id)!;
    expect(
      choice().branches.firstWhere((b) => b.id == id).label,
      'Nouvelle réponse',
    );
    expect(choice().branches, hasLength(3));
  });

  test('a created outcome is assigned to the selected response only when one is given', () {
    final branch = choice().branches.first;
    final id = c.addOutcomeAssigned('Résultat neuf', branchId: branch.id)!;
    expect(c.active!.entry.declaredOutcomes.map((o) => o.id), contains(id));
    expect(choice().branches.first.outcomeId, id);
    final alone = c.addOutcomeAssigned('Résultat seul')!;
    expect(c.active!.entry.declaredOutcomes.map((o) => o.id), contains(alone));
    expect(choice().branches.first.outcomeId, id);
    expect(choice().branches.last.outcomeId, isNot(alone));
    expect(c.addOutcomeAssigned('   ', branchId: branch.id), isNull);
  });

  test('a suite jump is read, found by title and removed from the suite level', () {
    final attente = node('Attente');
    expect(dialogueJumpTargetTitle(attente.steps), '');
    expect(c.disconnectNodeJump(attente.id), isFalse);
    expect(c.connectNode(attente.id, node('Depart').id), isTrue, reason: c.error);
    expect(dialogueJumpTargetTitle(node('Attente').steps), 'Depart');
    expect(c.nodeIdForTitle('Depart'), node('Depart').id);
    expect(c.nodeIdForTitle('Inconnue'), isNull);
    expect(c.disconnectNodeJump(node('Attente').id), isTrue, reason: c.error);
    expect(dialogueJumpTargetTitle(node('Attente').steps), '');
    expect(c.disconnectNodeJump('absent'), isFalse);
  });

  test('a response reads its destination title', () {
    expect(dialogueJumpTargetTitle(choice().branches.first.steps), 'Depart');
    expect(dialogueJumpTargetTitle(choice().branches.last.steps), 'Attente');
  });

  test('choosing a character takes its name and first portrait and a change resets the old portrait', () {
    final id = firstLine().id;
    expect(c.selectLineCharacter(id, 'guide'), isTrue, reason: c.error);
    expect(firstLine().characterId, 'guide');
    expect(firstLine().speaker, 'Chef de gare');
    expect(firstLine().portraitStateId, 'neutral');
  });

  test('choosing no character clears the portrait and the character', () {
    final id = firstLine().id;
    expect(c.selectLineCharacter(id, 'guide'), isTrue);
    expect(c.selectLineCharacter(id, ''), isTrue, reason: c.error);
    expect(firstLine().characterId, isNull);
    expect(firstLine().portraitStateId, isNull);
  });

  test('character and expression options follow the project', () {
    expect(c.lineCharacterChoices[''], 'Sans personnage');
    expect(c.lineCharacterChoices['guide'], 'Chef de gare');
    final id = c.addDefaultLine(node('Depart').id, narration: false)!;
    DeLineStep fresh() => dialogueSteps(node('Depart').steps)
        .whereType<DeLineStep>()
        .firstWhere((s) => s.id == id);
    expect(c.expressionChoices(fresh()), isNull);
    expect(c.lineHasNoPreparedPortrait(fresh()), isTrue);
    c.selectLineCharacter(id, 'guide');
    expect(c.expressionChoices(fresh()), {'': 'Sans portrait', 'neutral': 'Calme'});
    expect(c.lineHasNoPreparedPortrait(fresh()), isFalse);
  });

  test('the library filters by name and folder and states folder and draft status', () async {
    final base = f.workspace.project!;
    final guichet = base.dialogues.firstWhere((e) => e.id == ui09DialogueId);
    f.workspace.project = base.copyWith(
      dialogueFolders: const [
        ProjectDialogueFolder(id: 'f1', name: 'Gare'),
        ProjectDialogueFolder(id: 'f2', name: 'Route'),
      ],
      dialogues: [
        guichet,
        const ProjectDialogueEntry(
          id: 'rue',
          name: 'Rue',
          relativePath: 'dialogues/rue.yarn',
          folderId: 'f1',
        ),
        const ProjectDialogueEntry(
          id: 'adieu',
          name: 'Adieu',
          relativePath: 'dialogues/adieu.yarn',
          folderId: 'f2',
        ),
        const ProjectDialogueEntry(
          id: 'libre',
          name: 'Bonjour libre',
          relativePath: 'dialogues/libre.yarn',
        ),
      ],
    );
    List<String> names(String query, String folder) =>
        c.filteredEntries(query: query, folderId: folder).map((e) => e.id).toList();
    expect(names('', ''), [ui09DialogueId, 'rue', 'adieu', 'libre']);
    expect(names('ADIEU', ''), ['adieu']);
    expect(names('  adieu  ', 'f2'), ['adieu']);
    expect(names('', 'f1'), ['rue']);
    expect(names('adieu', 'f1'), isEmpty);
    expect(names('bonjour', ''), ['libre']);
    expect(c.libraryFolderName(c.entries.firstWhere((e) => e.id == 'adieu')), 'Route');
    expect(c.libraryFolderName(c.entries.firstWhere((e) => e.id == 'libre')), 'Dialogues du projet');
    expect(c.libraryStatus('adieu'), 'Contenu à ouvrir');
    expect(c.libraryStatus(ui09DialogueId), '3 suites');
    c.updateLine(firstLine().id, text: 'Autre texte');
    expect(c.libraryStatus(ui09DialogueId), '3 suites · brouillon');
  });

  test('the editable flag follows the read only reason', () {
    final session = c.active!;
    expect(session.editable, isTrue);
    final locked = DialogueEditSession(
      entry: session.entry,
      document: session.document,
      source: session.source,
      revision: session.revision,
      dirty: false,
      canUndo: false,
      canRedo: false,
      readOnlyReason: 'Source conservée',
    );
    expect(locked.editable, isFalse);
  });

  test('the preview names its start and offers to continue only while a line is pending', () async {
    expect(dialoguePreviewStartLabel(null), 'départ du document');
    expect(await c.open(ui09DialogueId, startNode: 'Depart'), isTrue);
    expect(dialoguePreviewStartLabel(c.active), 'Depart');
    expect(c.startPreview(), isTrue);
    expect(dialoguePreviewCanContinue(c.preview!), isTrue);
    for (var i = 0; i < 10 && !c.preview!.ended; i++) {
      c.advancePreview();
    }
    expect(c.preview!.ended, isTrue);
    expect(dialoguePreviewCanContinue(c.preview!), isFalse);
    expect(await c.open(ui09DialogueId, startNode: 'Absente'), isTrue);
    expect(c.startPreview(), isFalse);
    expect(dialoguePreviewCanContinue(c.preview!), isFalse);
  });

  test('a declared outcome is flagged until a response emits it', () {
    expect(dialogueOutcomeEmitted(c.active!, 'depart'), isTrue);
    expect(dialogueOutcomeEmitted(c.active!, 'inconnu'), isFalse);
    final id = c.addOutcome('Résultat neuf')!;
    expect(dialogueOutcomeEmitted(c.active!, id), isFalse);
    expect(c.assignOutcome(choice().branches.first.id, id), isTrue);
    expect(dialogueOutcomeEmitted(c.active!, id), isTrue);
  });

  test('the portrait is read only for a port that serves portraits and a complete identity', () async {
    final bytes = await readDialoguePortrait(f.port, 'guide', 'neutral');
    expect(bytes, isA<Uint8List>());
    expect(bytes, isNotEmpty);
    expect(readDialoguePortrait(f.port, null, 'neutral'), isNull);
    expect(readDialoguePortrait(f.port, 'guide', null), isNull);
    expect(readDialoguePortrait(_PlainPort(), 'guide', 'neutral'), isNull);
  });
}

class _PlainPort implements DialoguePort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
