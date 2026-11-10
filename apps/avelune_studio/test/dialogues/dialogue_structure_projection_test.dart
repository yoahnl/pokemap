import 'package:avelune_studio/features/dialogues/application/dialogue_structure_projection.dart';
import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';

import '../support/event_backend_fixture.dart';

DialogueEditorDocument _document() => DialogueEditorDocument(
  nodes: [
    DialogueEditorNode(
      id: 'start',
      title: 'Accueil',
      steps: [
        DeStartStep(id: 'marker'),
        DeLineStep(id: 'line', body: 'Bonjour'),
        DeChoiceStep(
          id: 'choice',
          branches: [
            DeChoiceBranch(
              id: 'outer',
              label: 'Premier choix',
              outcomeId: 'ready',
              steps: [
                DeNarrationStep(id: 'narration', text: 'Un instant'),
                DeChoiceStep(
                  id: 'nested-choice',
                  branches: [
                    DeChoiceBranch(
                      id: 'nested',
                      label: 'Continuer',
                      steps: [
                        DeLineStep(id: 'nested-line', body: 'Suite'),
                        DeJumpStep(id: 'nested-jump', targetTitle: 'Départ'),
                      ],
                    ),
                  ],
                ),
                DeJumpStep(id: 'branch-jump', targetTitle: 'Départ'),
              ],
            ),
            DeChoiceBranch(
              id: 'unresolved',
              label: 'Référence conservée',
              steps: [DeJumpStep(id: 'missing-jump', targetTitle: 'Absente')],
            ),
          ],
        ),
        DeJumpStep(id: 'node-jump', targetTitle: 'Départ'),
        DeEndStep(id: 'end'),
      ],
    ),
    DialogueEditorNode(id: 'target', title: 'Départ', steps: []),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'nested choices keep row order depth and native jump source identities',
    () {
      final document = _document();
      final before = emitDocumentToYarn(document);
      final projection = DialogueStructureProjection(document);
      final rows = projection.rows['start']!;
      expect(rows.map((row) => row.id), [
        'line',
        'choice',
        'outer',
        'narration',
        'nested-choice',
        'nested',
        'nested-line',
        'unresolved',
        'node-jump',
      ]);
      expect(rows.map((row) => row.depth), [0, 0, 0, 1, 1, 1, 2, 0, 0]);
      expect(rows[2].branch!.outcomeId, 'ready');
      expect(
        projection.wires.map(
          (wire) => (wire.id, wire.source, wire.target, wire.row),
        ),
        [
          ('outer', 'start', 'target', 2),
          ('nested', 'start', 'target', 5),
          ('node-jump', 'start', 'target', 8),
        ],
      );
      expect(projection.rows['target'], isEmpty);
      expect(emitDocumentToYarn(document), before);
      expect(
        document.nodes.first.steps
            .whereType<DeChoiceStep>()
            .single
            .branches
            .last
            .steps
            .whereType<DeJumpStep>()
            .single
            .targetTitle,
        'Absente',
      );
    },
  );

  test('ports exclude ordinary rows missing nodes and invalid row indices', () {
    final projection = DialogueStructureProjection(_document());
    expect(projection.portIdAt('start', 2), 'outer');
    expect(projection.portIdAt('start', 5), 'nested');
    expect(projection.portIdAt('start', 7), 'unresolved');
    expect(projection.portIdAt('start', 8), 'node-jump');
    for (final index in [-1, 0, 1, 3, 4, 6, 9, 999]) {
      expect(projection.portIdAt('start', index), isNull);
    }
    expect(projection.portIdAt('missing', 0), isNull);
    expect(projection.portIdAt('target', 0), isNull);
    expect(() => projection.rows.clear(), throwsUnsupportedError);
    expect(() => projection.rows['start']!.clear(), throwsUnsupportedError);
    expect(() => projection.wires.clear(), throwsUnsupportedError);
    final empty = DialogueStructureProjection(
      const DialogueEditorDocument(nodes: []),
    );
    expect(empty.rows, isEmpty);
    expect(empty.wires, isEmpty);
  });

  test('projected branch ports connect the exact controller response with undo and cold reopening', () async {
    final fixture = await EventBackendFixture.create();
    addTearDown(fixture.dispose);
    final adapter = LocalDialogueAdapter(
      session: fixture.source.session,
      mapAdapter: fixture.source.maps,
    );
    final controller = DialogueWorkspaceController(
      fixture.narrative,
      adapter,
      changed: () {},
    );
    addTearDown(controller.dispose);
    await controller.create('Projection');
    final start = controller.active!.document.nodes.single.id;
    controller.updateLine(
      controller.active!.document.nodes.single.steps
          .whereType<DeLineStep>()
          .single
          .id,
      text: 'Choisissez votre départ.',
    );
    final target = controller.addNode('Destination')!;
    controller.addLine(target, text: 'Arrivée');
    final choice = controller.addChoice(start)!;
    final first = controller.addResponse(choice, 'Garder')!;
    final selected = controller.addResponse(choice, 'Partir')!;
    final outcome = controller.addOutcome('Départ')!;
    controller.assignOutcome(selected, outcome);
    final document = controller.active!.document;
    final projection = DialogueStructureProjection(document);
    final row = projection.rows[start]!.indexWhere((row) => row.id == selected);
    final port = projection.portIdAt(start, row)!;
    final before = controller.active!.source;
    final reads = controller.sourceReads;
    final compilations = controller.compilationCount;
    DialogueStructureProjection(document);
    expect(controller.sourceReads, reads);
    expect(controller.compilationCount, compilations);
    expect(
      await controller.connectSelection(
        port,
        'missing',
        confirmReplacement: () async => true,
      ),
      isFalse,
    );
    expect(controller.active!.source, before);
    expect(
      await controller.connectSelection(
        port,
        target,
        confirmReplacement: () async => throw StateError('No replacement'),
      ),
      isTrue,
    );
    final current = controller.active!.document.nodes
        .expand(dialogueBranches)
        .toList();
    expect(
      current
          .singleWhere((branch) => branch.id == first)
          .steps
          .whereType<DeJumpStep>(),
      isEmpty,
    );
    final connected = current.singleWhere((branch) => branch.id == selected);
    expect(connected.label, 'Partir');
    expect(connected.outcomeId, outcome);
    expect(
      connected.steps.whereType<DeJumpStep>().single.targetTitle,
      'Destination',
    );
    controller.undo();
    expect(controller.active!.source, before);
    controller.redo();
    expect(await controller.save(), isTrue, reason: controller.error);
    final id = controller.activeId!;
    final reopened = await adapter.load(id);
    final read = parseYarnToDocument(
      reopened.source,
      entryNodeTitle: reopened.entry.defaultStartNode,
    );
    final wire = DialogueStructureProjection(read).wires.single;
    final reopenedBranch = read.nodes
        .expand(dialogueBranches)
        .singleWhere((branch) => branch.label == 'Partir');
    expect(wire.id, reopenedBranch.id);
    expect(reopenedBranch.outcomeId, outcome);
    expect(read.nodeById(wire.target)!.title, 'Destination');
    expect(controller.deleteSelection(wireId: selected), isTrue);
    expect(
      controller.active!.document.nodes
          .expand(dialogueBranches)
          .singleWhere((branch) => branch.id == selected)
          .outcomeId,
      outcome,
    );
  });
}
