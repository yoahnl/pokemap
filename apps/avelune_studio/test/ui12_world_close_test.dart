import 'dart:async';

import 'package:avelune_studio/features/map_workspace/coordination/workspace_workflow.dart';
import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/ui12_held_world_port.dart';
import 'support/ui12_world_harness.dart';
import 'support/world_authoring_workflow_fixture.dart';

void main() {
  test('invalid rule input blocks global save until corrected', () async {
    final h = await WorldAuthoringWorkflowFixture.create();
    addTearDown(h.dispose);
    final world = h.world;
    await world.saveFact(createWorldFact(world, 'Train parti de Kisaragi'));
    final factId = world.selectedFactId!;
    final ruleId = composeWorldRule(world, factId);
    createWorldFact(world, 'Conducteur prévenu');
    expect(world.hasRuleDraft, isTrue);
    expect(h.editor.commitRuleLabel(ruleId, ''), isFalse);

    h.closeChoice = null;
    expect(await h.workspace.allowClose(), isFalse);
    expect(world.hasRuleDraft, isTrue);
    h.closeChoice = WorkspaceCloseChoice.cancel;
    expect(await h.workspace.allowClose(), isFalse);
    expect(world.hasRuleDraft, isTrue);

    h.closeChoice = WorkspaceCloseChoice.save;
    expect(await h.workspace.allowClose(), isFalse);
    expect(world.pendingRules, contains(ruleId));
    expect(world.project.worldRules, isEmpty);
    expect(world.error, contains('Corrigez les champs invalides'));
    expect(h.inputs.invalidFields, isNotEmpty);
    expect(
      world.project.facts.any((fact) => fact.label == 'Conducteur prévenu'),
      isFalse,
    );

    expect(h.editor.commitRuleLabel(ruleId, 'Masquer le conducteur'), isTrue);
    expect(h.inputs.valid, isTrue);
    expect(await h.workspace.allowClose(), isTrue, reason: world.error);
    expect(world.pendingRules, isEmpty);
    expect(world.project.worldRules.single.label, 'Masquer le conducteur');
    expect(
      world.project.facts.map((fact) => fact.label),
      containsAll(['Train parti de Kisaragi', 'Conducteur prévenu']),
    );
    final reopened = await Ui12WorldHarness.open(h.harness.directory);
    addTearDown(() => reopened.dispose(deleteDirectory: false));
    expect(reopened.world.project.worldRules, hasLength(1));
  });

  test('an incomplete rule is never silently dropped', () async {
    final h = await WorldAuthoringWorkflowFixture.create();
    addTearDown(h.dispose);
    await h.world.saveFact(createWorldFact(h.world, 'Train parti de Kisaragi'));
    final ruleId = composeWorldRule(
      h.world,
      h.world.selectedFactId!,
      complete: false,
    );
    expect(await h.workspace.allowClose(), isFalse);
    expect(h.world.ruleDraft(ruleId), isNotNull);
    expect(h.world.error, contains('la cible'));
    expect(h.world.project.worldRules, isEmpty);
  });

  test('a close asked during a publication is refused', () async {
    final started = Completer<void>();
    late Ui12HeldWorldPort held;
    final h = await WorldAuthoringWorkflowFixture.create(
      wrap: (port) => held = Ui12HeldWorldPort(
        port,
        onRule: () {
          if (!started.isCompleted) started.complete();
        },
      ),
    );
    addTearDown(h.dispose);
    await h.world.saveFact(createWorldFact(h.world, 'Train parti de Kisaragi'));
    final ruleId = composeWorldRule(h.world, h.world.selectedFactId!);
    held.ruleGate = Completer<void>();
    final writing = h.world.saveRule(ruleId);
    addTearDown(() async {
      if (!held.ruleGate!.isCompleted) held.ruleGate!.complete();
      await writing;
    });
    await started.future.timeout(const Duration(seconds: 10));
    expect(h.world.saving, isTrue);
    expect(await h.workspace.allowClose(), isFalse);
    expect(h.closeQuestions, 0);
    held.ruleGate!.complete();
    expect(await writing, isTrue, reason: h.world.error);
    expect(h.world.pendingRules, isEmpty);
    expect(h.world.project.worldRules, hasLength(1));
  });
}
