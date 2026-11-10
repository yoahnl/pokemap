import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';

import '../support/event_backend_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late EventBackendFixture fixture;
  late DialogueWorkspaceController controller;
  late String start, branch, first, second, line;
  setUp(() async {
    fixture = await EventBackendFixture.create();
    controller = DialogueWorkspaceController(
      fixture.narrative,
      LocalDialogueAdapter(
        session: fixture.source.session,
        mapAdapter: fixture.source.maps,
      ),
      changed: () {},
    );
    await controller.create('Connexions');
    start = controller.active!.document.nodes.single.id;
    line = controller.active!.document.nodes.single.steps
        .whereType<DeLineStep>()
        .single
        .id;
    controller.updateLine(line, text: 'Bonjour.');
    first = controller.addNode('Première')!;
    controller.addLine(first, text: 'Première destination.');
    second = controller.addNode('Seconde')!;
    controller.addLine(second, text: 'Seconde destination.');
    branch = controller.addResponse(
      controller.addChoice(start)!,
      'Texte conservé',
    )!;
    controller.assignOutcome(branch, controller.addOutcome('Accepter')!);
    controller.connect(branch, first);
  });
  tearDown(() async {
    controller.dispose();
    await fixture.dispose();
  });

  test('cancelled replacement preserves content and history', () async {
    final before = controller.active!;
    expect(
      await controller.connectSelection(
        branch,
        second,
        confirmReplacement: () async => false,
      ),
      isFalse,
    );
    expect(controller.active!.source, before.source);
    expect(controller.active!.revision, before.revision);
  });

  test(
    'confirmed replacement preserves response and outcome, undo and reopen',
    () async {
      final before = controller.active!.source;
      expect(
        await controller.connectSelection(
          branch,
          second,
          confirmReplacement: () async => true,
        ),
        isTrue,
      );
      final current = controller.active!.document.nodes
          .expand(dialogueBranches)
          .single;
      expect(current.label, 'Texte conservé');
      expect(current.outcomeId, isNotNull);
      expect(
        current.steps.whereType<DeJumpStep>().single.targetTitle,
        'Seconde',
      );
      controller.undo();
      expect(controller.active!.source, before);
      controller.redo();
      expect(await controller.save(), isTrue, reason: controller.error);
      expect(await controller.reload(), isTrue);
      expect(
        controller.active!.document.nodes
            .expand(dialogueBranches)
            .single
            .steps
            .whereType<DeJumpStep>()
            .single
            .targetTitle,
        'Seconde',
      );
    },
  );

  for (final changeOwner in [false, true]) {
    test('stale confirmation refuses changed owner: $changeOwner', () async {
      final confirmation = Completer<bool>();
      final pending = controller.connectSelection(
        branch,
        second,
        confirmReplacement: () => confirmation.future,
      );
      if (changeOwner) {
        await controller.create('Autre propriétaire');
      } else {
        controller.updateResponse(branch, 'Dernière saisie');
      }
      final before = controller.active!;
      confirmation.complete(true);
      expect(await pending, isFalse);
      expect(controller.active!.source, before.source);
      expect(controller.active!.revision, before.revision);
    });
  }

  test(
    'node and jump resolve their native source and only confirm replacement',
    () async {
      var confirmations = 0;
      Future<bool> confirm() async {
        confirmations++;
        return true;
      }

      expect(
        await controller.connectSelection(
          first,
          second,
          confirmReplacement: confirm,
        ),
        isTrue,
      );
      expect(confirmations, 0);
      final jump = controller.active!.document
          .nodeById(first)!
          .steps
          .whereType<DeJumpStep>()
          .single;
      expect(
        await controller.connectSelection(
          jump.id,
          start,
          confirmReplacement: confirm,
        ),
        isTrue,
      );
      expect(confirmations, 1);
      expect(
        controller.active!.document
            .nodeById(first)!
            .steps
            .whereType<DeJumpStep>()
            .single
            .targetTitle,
        controller.active!.document.nodeById(start)!.title,
      );
    },
  );

  test(
    'selection deletion keeps unrelated response content and respects priority',
    () {
      final source = controller.active!.document.nodes
          .expand(dialogueBranches)
          .single;
      final jump = source.steps.whereType<DeJumpStep>().single.id;
      expect(
        controller.deleteSelection(
          wireId: jump,
          branchId: branch,
          stepId: line,
          nodeId: start,
        ),
        isTrue,
      );
      final kept = controller.active!.document.nodes
          .expand(dialogueBranches)
          .single;
      expect(kept.label, source.label);
      expect(kept.outcomeId, source.outcomeId);
      expect(kept.steps.whereType<DeJumpStep>(), isEmpty);
      expect(
        controller.active!.document
            .nodeById(start)!
            .steps
            .any((step) => step.id == line),
        isTrue,
      );
      expect(controller.deleteSelection(branchId: branch), isTrue);
      expect(
        controller.active!.document.nodes.expand(dialogueBranches),
        isEmpty,
      );
      expect(controller.deleteSelection(stepId: line), isTrue);
      expect(
        controller.active!.document
            .nodeById(start)!
            .steps
            .any((step) => step.id == line),
        isFalse,
      );
      expect(controller.deleteSelection(nodeId: second), isTrue);
      expect(controller.active!.document.nodeById(first), isNotNull);
      expect(controller.active!.document.nodeById(second), isNull);
    },
  );

  test('inactive confirmation cannot alter its document', () async {
    final before = controller.active!;
    expect(
      await controller.connectSelection(
        branch,
        second,
        confirmReplacement: () async => true,
        isActive: () => false,
      ),
      isFalse,
    );
    expect(controller.active!.source, before.source);
    expect(controller.active!.revision, before.revision);
  });
}
