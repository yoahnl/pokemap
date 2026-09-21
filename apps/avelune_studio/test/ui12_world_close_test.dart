import 'dart:async';

import 'package:avelune_studio/presentation/features/world/world_view_state.dart';
import 'package:avelune_studio/presentation/features/world/world_workspace_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/m2_ui_fixture.dart';
import 'support/ui12_close_harness.dart';
import 'support/ui12_held_world_port.dart';
import 'support/ui12_world_harness.dart';

const _label = 'Train parti de Kisaragi';

void main() {
  testWidgets('invalid rule input blocks global save until corrected', (
    tester,
  ) async {
    final (h, guard) = await host(tester);
    final world = opened(tester);
    unawaited(world.saveFact(state(world, _label)));
    await pumpIo(tester, frames: 12);
    final factId = world.project.facts
        .firstWhere((fact) => fact.label == _label)
        .id;
    final ruleId = composeRule(world, factId);
    state(world, 'Conducteur prévenu');
    expect(world.hasRuleDraft, isTrue);

    final page = tester.widget<WorldWorkspacePage>(
      find.byType(WorldWorkspacePage),
    );
    page.view.view = WorldView.rules;
    await pumpIo(tester, frames: 6);
    final field = find.widgetWithText(TextField, 'Nom de la règle');
    await tester.enterText(field, '');
    await tester.pump();
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);

    var pending = guard();
    await pumpIo(tester, frames: 8);
    expect(find.text('Conserver vos modifications ?'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpIo(tester, frames: 8);
    expect(await pending, isFalse);
    expect(world.hasRuleDraft, isTrue);

    pending = guard();
    await pumpIo(tester, frames: 8);
    await tester.tap(inDialog('Annuler'));
    await pumpIo(tester, frames: 8);
    expect(await pending, isFalse);
    expect(world.hasRuleDraft, isTrue);

    pending = guard();
    await pumpIo(tester, frames: 8);
    await tester.tap(inDialog('Enregistrer'));
    await pumpIo(tester, frames: 8);
    expect(await pending, isFalse);
    expect(world.pendingRules, contains(ruleId));
    expect(world.project.worldRules, isEmpty);
    expect(world.error, contains('Corrigez les champs invalides'));
    expect(page.view.invalidFields, isNotEmpty);
    expect(
      world.project.facts.any((fact) => fact.label == 'Conducteur prévenu'),
      isFalse,
    );

    await tester.enterText(field, 'Masquer le conducteur');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await pumpIo(tester, frames: 6);
    expect(page.view.invalidFields, isEmpty);

    pending = guard();
    await pumpIo(tester, frames: 8);
    await tester.tap(inDialog('Enregistrer'));
    await pumpIo(tester, frames: 30);
    expect(await pending, isTrue, reason: world.error ?? '');
    expect(world.pendingRules, isEmpty);
    expect(world.project.worldRules, hasLength(1));
    expect(world.project.worldRules.single.label, 'Masquer le conducteur');
    expect(
      world.project.facts.map((fact) => fact.label),
      containsAll([_label, 'Conducteur prévenu']),
    );

    final reopened = await tester.runAsync(
      () => Ui12WorldHarness.open(h.directory),
    );
    addTearDown(() async {
      await tester.runAsync(() => reopened!.dispose(deleteDirectory: false));
    });
    expect(reopened!.world.project.worldRules, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('an incomplete rule is never silently dropped', (tester) async {
    final (_, guard) = await host(tester);
    final world = opened(tester);
    unawaited(world.saveFact(state(world, _label)));
    await pumpIo(tester, frames: 12);
    final factId = world.project.facts
        .firstWhere((fact) => fact.label == _label)
        .id;
    final ruleId = composeRule(world, factId, complete: false);

    final pending = guard();
    await pumpIo(tester, frames: 8);
    expect(find.text('Conserver vos modifications ?'), findsOneWidget);
    await tester.tap(inDialog('Enregistrer'));
    await pumpIo(tester, frames: 20);
    expect(await pending, isFalse);
    expect(world.ruleDraft(ruleId), isNotNull);
    expect(world.error, contains('la cible'));
    expect(world.project.worldRules, isEmpty);
  });

  testWidgets('a close asked during a publication is refused', (tester) async {
    late Ui12HeldWorldPort held;
    final (_, guard) = await host(
      tester,
      wrap: (port) => held = Ui12HeldWorldPort(port),
    );
    final world = opened(tester);
    unawaited(world.saveFact(state(world, _label)));
    await pumpIo(tester, frames: 12);
    final factId = world.project.facts
        .firstWhere((fact) => fact.label == _label)
        .id;
    final ruleId = composeRule(world, factId);

    held.ruleGate = Completer<void>();
    final writing = world.saveRule(ruleId);
    expect(world.saving, isTrue);
    expect(await guard(), isFalse);
    expect(find.text('Conserver vos modifications ?'), findsNothing);

    held.ruleGate!.complete();
    await pumpIo(tester, frames: 20);
    expect(await writing, isTrue, reason: world.error ?? '');
    expect(world.pendingRules, isEmpty);
    expect(world.project.worldRules, hasLength(1));
  });
}
