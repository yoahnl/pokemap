import 'package:avelune_studio/features/dialogues/application/dialogue_structure_projection.dart';
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

  DialogueEditorNode accueil() => c.active!.document.nodes.first;
  DeLineStep firstLine() => accueil().steps.whereType<DeLineStep>().first;
  DeChoiceBranch firstBranch() =>
      accueil().steps.whereType<DeChoiceStep>().first.branches.first;

  test('edits application-selected text and response then saves', () async {
    const text = 'Lecture et sauvegarde depuis le propriétaire.';
    expect(c.updateLine(firstLine().id, text: text), isTrue);
    expect(await c.save(), isTrue, reason: c.error);
    expect(f.port.writes, 1);
    expect(c.dirty, isFalse);
    expect(await f.savedSource(), contains(text));

    const answer = 'Partir tout de suite';
    expect(c.updateResponse(firstBranch().id, answer), isTrue);
    expect(c.dirty, isTrue);
    expect(await c.save(), isTrue, reason: c.error);
    expect(f.port.writes, 2);
    expect(c.dirty, isFalse);
    final saved = await f.savedSource();
    expect(saved, contains(text));
    expect(saved, contains(answer));
    expect(saved, contains('<<jump Depart>>'));
    expect(saved, contains('<<outcome depart>>'));
    final reopened = parseYarnToDocument(saved, entryNodeTitle: 'Accueil');
    final branch = reopened.nodes
        .firstWhere((node) => node.title == 'Accueil')
        .steps
        .whereType<DeChoiceStep>()
        .single
        .branches
        .firstWhere((branch) => branch.label == answer);
    expect(branch.outcomeId, 'depart');
    expect(
      branch.steps.whereType<DeJumpStep>().single.targetTitle,
      'Depart',
    );
  }, timeout: _slow);

  test('EV04 guided value picker distinguishes player identity from a Fact of the same name', () {
    f.workspace.project = f.workspace.project!.copyWith(
      facts: [
        ...f.workspace.project!.facts,
        NarrativeFactDefinition(
          id: 'player_name',
          label: 'Nom de la gare',
          initialValue: const NarrativeValue.string('Selbrume'),
        ),
        NarrativeFactDefinition(id: 'twin', label: 'Jumeau A'),
        NarrativeFactDefinition(id: 'twin', label: 'Jumeau B'),
      ],
    );
    final choices = c.textValueChoices;
    expect(choices['player_name'], 'Nom du joueur');
    expect(choices['fact:player_name'], contains('Nom de la gare'));
    expect(choices.keys, isNot(contains('fact:twin')));

    final line = firstLine().id;
    expect(c.insertTextValueChoice(line, 'fact:player_name'), isTrue);
    expect(c.active!.source, contains('{{ fact.player_name }}'));
    expect(c.active!.source, isNot(contains('{{ player_name }}')));
    expect(c.insertTextValueChoice(line, 'player_name'), isTrue);
    expect(c.active!.source, contains('{{ player_name }}'));
    expect(c.insertTextValueChoice(line, 'fact:twin'), isFalse);
    expect(c.error, isNotNull);
  }, timeout: _slow);

  test('focused text saves exact source and history remains usable', () async {
    const text = 'Le prochain train vous attend.';
    expect(c.updateLine(firstLine().id, text: text), isTrue);
    expect(await c.save(), isTrue, reason: c.error);
    expect(f.port.writes, 1);
    expect(c.busy, isFalse);
    expect(c.dirty, isFalse);
    expect(await f.savedSource(), contains(text));

    c.undo();
    expect(c.active!.source, contains('Souhaitez-vous préparer'));
    expect(c.active!.source, isNot(contains(text)));
    expect(c.dirty, isTrue);
    expect(c.canRedo, isTrue);
    c.redo();
    expect(c.active!.source, contains(text));
    expect(c.dirty, isFalse);
    expect(f.port.writes, 1);
  }, timeout: _slow);

  test('undo restores the exact source once then redo reapplies the edit', () {
    final before = c.active!.source;
    expect(c.canUndo, isFalse);
    expect(c.updateLine(firstLine().id, text: 'Une édition encore au clavier.'), isTrue);
    c.undo();
    expect(c.active!.source, before);
    expect(c.canUndo, isFalse);
    expect(c.canRedo, isTrue);
    c.undo();
    expect(c.active!.source, before);
    c.redo();
    expect(c.active!.source, contains('Une édition encore au clavier.'));
    expect(c.canRedo, isFalse);
    expect(f.port.writes, 0);
  }, timeout: _slow);

  test('invalid suite name on save stays visible without publishing', () async {
    final id = accueil().id;
    expect(c.renameNode(id, 'Depart'), isFalse);
    expect(c.error, contains('utilisée par'));
    expect(accueil().title, 'Accueil');
    expect(c.dirty, isFalse);
    final depart = c.active!.document.nodes.firstWhere(
      (node) => node.title == 'Depart',
    );
    c.error = null;
    expect(c.renameNode(depart.id, 'Attente'), isFalse);
    expect(c.error, contains('Title must be unique'));
    expect(
      c.active!.document.nodes.where((node) => node.title == 'Attente'),
      hasLength(1),
    );
    expect(c.dirty, isFalse);
    expect(await c.save(), isTrue);
    expect(f.port.writes, 0);
    expect(c.renameNode(id, '   '), isFalse);
    expect(c.renameNode(id, 'Deux\nlignes'), isFalse);
    expect(accueil().title, 'Accueil');
  }, timeout: _slow);

  test('renaming a free suite rewrites its jumps and publishes once', () async {
    final attente = c.active!.document.nodes.firstWhere(
      (node) => node.title == 'Attente',
    );
    expect(c.renameNode(attente.id, 'Salle'), isTrue, reason: c.error);
    expect(c.active!.source, contains('<<jump Salle>>'));
    expect(c.active!.source, isNot(contains('<<jump Attente>>')));
    expect(await c.save(), isTrue, reason: c.error);
    expect(f.port.writes, 1);
    expect(await f.savedSource(), contains('title: Salle'));
  }, timeout: _slow);

  test('preview reports an absent start node chosen at opening', () async {
    expect(await c.open(ui09DialogueId, startNode: 'DepartAbsent'), isTrue);
    expect(c.startPreview(), isFalse);
    expect(c.preview!.error, isNotNull);
    expect(await c.open(ui09DialogueId, startNode: 'Accueil'), isTrue);
    expect(c.startPreview(), isTrue);
    expect(c.preview!.error, isNull);
  }, timeout: _slow);

  test('UI09 40 suites 200 lines 50 links application projection does not reread or compile', () async {
    final port = _VolumePort(
      f.narrative.project.dialogues.firstWhere((e) => e.id == ui09DialogueId),
    );
    final controller = DialogueWorkspaceController(
      f.narrative,
      port,
      changed: () {},
    );
    addTearDown(controller.dispose);
    expect(await controller.open(ui09DialogueId), isTrue);
    expect(controller.active!.readOnlyReason, isNull);
    final snapshot = controller.active;
    final compilations = controller.compilationCount;

    for (var pass = 0; pass < 8; pass++) {
      final projection = DialogueStructureProjection(
        controller.active!.document,
      );
      expect(projection.rows, hasLength(40));
      expect(
        projection.rows.values
            .expand((rows) => rows)
            .where((row) => row.branch == null && row.step is DeLineStep),
        hasLength(200),
      );
      expect(projection.wires, hasLength(50));
    }
    expect(controller.active, same(snapshot));
    expect(controller.active!.dirty, isFalse);
    expect(port.reads, 1);
    expect(controller.compilationCount, compilations);
  }, timeout: _slow);
}

class _VolumePort implements DialoguePort {
  _VolumePort(this.entry);
  final ProjectDialogueEntry entry;
  int reads = 0;

  @override
  Future<DialogueSourceSnapshot> load(String id) async {
    reads++;
    final source = StringBuffer();
    for (var n = 0; n < 40; n++) {
      source.writeln('title: Suite$n\n---');
      for (var line = 0; line < 5; line++) {
        source.writeln('Voyageur: Réplique $line de la suite $n.');
      }
      if (n < 25) {
        for (var choice = 0; choice < 2; choice++) {
          source.writeln('-> Réponse $choice\n    <<jump Suite${n + choice + 1}>>');
        }
      }
      source.writeln('===');
    }
    return DialogueSourceSnapshot(
      entry: entry.copyWith(defaultStartNode: 'Suite0', declaredOutcomes: []),
      source: source.toString(),
      revision: 'volume',
    );
  }

  @override
  Future<DialoguePublicationReceipt> publish({
    required String id,
    required DialogueSourceSnapshot? base,
    required ProjectDialogueEntry? entry,
    required String? source,
    List<DialogueLineTextEdit>? lineTextEdits,
  }) => throw StateError('Consultation only');
}

const _slow = Timeout(Duration(minutes: 3));
