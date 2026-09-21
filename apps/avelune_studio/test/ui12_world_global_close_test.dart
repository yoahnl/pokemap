import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/world/world_view_state.dart';
import 'package:avelune_studio/presentation/features/world/world_workspace_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/m2_ui_fixture.dart';
import 'support/ui12_close_harness.dart';
import 'support/ui12_held_world_port.dart';
import 'support/ui12_world_harness.dart';

void main() {
  testWidgets('global close saves new world states with Stories connected', (
    tester,
  ) async {
    final (h, guard) = await host(tester);
    final world = opened(tester);
    final factId = state(world, 'Départ confirmé');
    final independentId = state(world, 'Signal reçu');
    final ruleId = composeRule(world, factId);
    world.narrative.pendingStories['close_story'] = StorylineAsset(
      id: 'close_story',
      title: 'Départ en préparation',
    );
    world.changed();
    await pumpIo(tester, frames: 6);
    expect(world.narrative.saveStoryDrafts, isNotNull);
    expect(world.project.facts.any((fact) => fact.id == factId), isFalse);
    expect(world.pendingRules, contains(ruleId));

    final pending = guard();
    await pumpIo(tester, frames: 8);
    await tester.tap(inDialog('Enregistrer'));
    await pumpIo(tester, frames: 40);
    expect(await pending, isTrue, reason: world.error);
    expect(world.narrative.pendingFacts, isEmpty);
    expect(world.narrative.pendingStories, isEmpty);
    expect(world.pendingRules, isEmpty);

    final reopened = (await tester.runAsync(
      () => Ui12WorldHarness.open(h.directory),
    ))!;
    addTearDown(() async {
      await tester.runAsync(() => reopened.dispose(deleteDirectory: false));
    });
    final project = reopened.world.project;
    final savedFact = project.facts.singleWhere(
      (fact) => fact.label == 'Départ confirmé',
    );
    final independent = project.facts.singleWhere(
      (fact) => fact.label == 'Signal reçu',
    );
    expect(savedFact.id, isNot(factId));
    expect(independent.id, isNot(independentId));
    expect(project.worldRules.single.source.sourceId, savedFact.id);
    expect(
      project.storylines.singleWhere((story) => story.id == 'close_story').title,
      'Départ en préparation',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid input on a clean rule still requires an explicit choice', (
    tester,
  ) async {
    final (h, guard) = await host(tester);
    final world = opened(tester);
    final factId = state(world, 'Train arrivé');
    final factWrite = world.saveFact(factId);
    await pumpIo(tester, frames: 20);
    expect(await factWrite, isTrue);
    final ruleId = composeRule(world, world.selectedFactId!);
    final ruleWrite = world.saveRule(ruleId);
    await pumpIo(tester, frames: 20);
    expect(await ruleWrite, isTrue);
    expect(world.dirty, isFalse);
    final published = world.project.worldRules.single;

    final page = tester.widget<WorldWorkspacePage>(
      find.byType(WorldWorkspacePage),
    );
    page.view.view = WorldView.rules;
    world.changed();
    await pumpIo(tester, frames: 6);
    await tester.enterText(
      find.widgetWithText(TextField, 'Nom de la règle'),
      '',
    );

    var pending = guard();
    await pumpIo(tester, frames: 8);
    expect(world.hasRuleDraft, isFalse);
    expect(page.view.invalidFields, isNotEmpty);
    expect(find.text('Conserver vos modifications ?'), findsOneWidget);
    await tester.tap(inDialog('Enregistrer'));
    await pumpIo(tester, frames: 8);
    expect(await pending, isFalse);
    expect(world.error, contains('Corrigez les champs invalides'));
    expect(world.project.worldRules.single, published);

    pending = guard();
    await pumpIo(tester, frames: 8);
    await tester.tap(inDialog('Abandonner'));
    await pumpIo(tester, frames: 8);
    expect(await pending, isTrue);
    final reopened = (await tester.runAsync(
      () => Ui12WorldHarness.open(h.directory),
    ))!;
    addTearDown(() async {
      await tester.runAsync(() => reopened.dispose(deleteDirectory: false));
    });
    expect(reopened.world.project.worldRules.single, published);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed rule keeps close blocked after its new state is saved', (
    tester,
  ) async {
    late Ui12HeldWorldPort held;
    final (h, guard) = await host(
      tester,
      wrap: (port) => held = Ui12HeldWorldPort(port),
    );
    final world = opened(tester);
    final factId = state(world, 'Passage autorisé');
    composeRule(world, factId);
    held.ruleFailure = const WorldFailure('Publication de règle refusée');

    var pending = guard();
    await pumpIo(tester, frames: 8);
    await tester.tap(inDialog('Enregistrer'));
    await pumpIo(tester, frames: 30);
    expect(await pending, isFalse);
    expect(world.error, contains('Publication de règle refusée'));
    expect(world.pendingRules, hasLength(1));
    expect(world.project.worldRules, isEmpty);
    final saved = world.project.facts.singleWhere(
      (fact) => fact.label == 'Passage autorisé',
    );
    expect(saved.id, isNot(factId));
    expect(world.pendingRules.values.single.source!.sourceId, saved.id);

    held.ruleFailure = null;
    pending = guard();
    await pumpIo(tester, frames: 8);
    await tester.tap(inDialog('Enregistrer'));
    await pumpIo(tester, frames: 30);
    expect(await pending, isTrue, reason: world.error);
    final reopened = (await tester.runAsync(
      () => Ui12WorldHarness.open(h.directory),
    ))!;
    addTearDown(() async {
      await tester.runAsync(() => reopened.dispose(deleteDirectory: false));
    });
    expect(reopened.world.project.worldRules.single.source.sourceId, saved.id);
    expect(world.pendingRules, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
