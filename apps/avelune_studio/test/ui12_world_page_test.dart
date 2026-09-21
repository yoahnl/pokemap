import 'dart:async';

import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';

import 'package:avelune_studio/presentation/features/world/world_view_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/m2_ui_fixture.dart';
import 'support/ui12_page_harness.dart';

Future<void> activate(WidgetTester tester, Finder finder) async {
  await tester.pump(const Duration(milliseconds: 350));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 350));
  await pumpIo(tester, frames: 12);
}

/// Lets a chain of real writes finish without opening a second [runAsync]
/// alongside the one the port already holds.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    if (WidgetResourcePort.pending case final pending?) await pending;
  }
}

void main() {
  testWidgets('a state and its rule are composed from the page controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final h = (await tester.runAsync(() => Ui12PageHarness.create(tester)))!;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(h.dispose);
    });
    await tester.pumpWidget(h.app());
    unawaited(h.controller.initialize());
    await pumpIo(tester);

    await activate(tester, find.text('Nouvel état').first);
    expect(h.controller.selectedFactId, isNotNull);
    await tester.enterText(
      find.widgetWithText(TextField, 'Nouvel état').first,
      'Train parti',
    );
    await activate(tester, find.text('États').first);
    expect(h.controller.activeFact!.label, 'Train parti');
    await activate(tester, find.text('Enregistrer').first);
    for (var i = 0; i < 30 && h.controller.loading; i++) {
      await pumpIo(tester, frames: 3);
    }
    final factId = h.controller.selectedFactId!;
    expect(h.controller.isFactDirty(factId), isFalse);
    await h.capture(tester, 'ui12-01-etats');

    await activate(tester, find.byTooltip('Créer une règle avec cet état'));
    expect(h.view.view, WorldView.rules);
    final ruleId = h.controller.selectedRuleId!;
    expect(h.controller.ruleDraft(ruleId)!.source, isNotNull);
    expect(
      h.controller.ruleDraft(ruleId)!.missing,
      contains('la cible'),
      reason: 'An unfinished draft names what it still needs',
    );

    final target = h.controller.model.targetOptions.firstWhere(
      (option) => option.kind == WorldRuleTargetKind.mapEntity,
    );
    await activate(tester, find.byKey(const ValueKey('rule-block-Cible')));
    await activate(tester, find.text(target.label).last);
    expect(h.controller.ruleDraft(ruleId)!.target?.entityId, target.entityId);

    await activate(tester, find.byKey(const ValueKey('rule-block-Effet')));
    expect(
      find.text('Remplacer le dialogue'),
      findsNothing,
      reason: 'A visibility target never offers a dialogue effect',
    );
    await activate(tester, find.text('Masquer le personnage').last);
    final draft = h.controller.ruleDraft(ruleId)!;
    expect(draft.effect, isNotNull);
    expect(
      isWorldRuleEffectCompatibleWithTarget(
        draft.target!.kind,
        draft.effect!.kind,
      ),
      isTrue,
      reason: 'The effect catalogue is filtered by the chosen target',
    );
    expect(draft.missing, isEmpty);

    await activate(tester, find.text('Enregistrer').first);
    expect(h.controller.error, isNull);
    await activate(tester, find.text('Tester la règle'));
    expect(h.controller.report, isNotNull);
    expect(find.text('Avant la règle'), findsOneWidget);
    await h.capture(tester, 'ui12-02-regle');

    // The condition holds only once the test value says the train has left.
    await activate(tester, find.text('Après la règle'));
    expect(find.textContaining('Présent'), findsOneWidget);

    await activate(tester, find.byType(Switch).last);
    expect(
      h.controller.isHypothetical(factId),
      isTrue,
      reason: 'The test value is a hypothesis, not the project value',
    );
    expect(
      find.textContaining('Absent'),
      findsOneWidget,
      reason: 'The picture and the verdict must agree once the rule applies',
    );
    await h.capture(tester, 'ui12-03-apres');

    expect(
      h.controller.fact(factId)!.initialValue,
      const NarrativeValue.boolean(false),
      reason: 'Testing never rewrites the value of the project',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a rule refuses to outrun the state it reads, and offers it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final h = (await tester.runAsync(() => Ui12PageHarness.create(tester)))!;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(h.dispose);
    });
    await tester.pumpWidget(h.app());
    unawaited(h.controller.initialize());
    await pumpIo(tester);

    final factId = h.controller.createFact();
    h.controller.editFact(
      NarrativeFactDefinition(
        id: factId,
        label: 'Train parti',
        initialValue: const NarrativeValue.boolean(false),
      ),
    );
    final ruleId = h.controller.createRule(factId: factId);
    final map = h.controller.maps.firstWhere((map) => map.entities.isNotEmpty);
    h.controller.editRule(ruleId, (draft) {
      draft.label = 'Masquer le conducteur';
      draft.target = WorldRuleTarget(
        kind: WorldRuleTargetKind.mapEntity,
        mapId: map.id,
        entityId: map.entities.first.id,
        label: map.entities.first.id,
      );
      draft.effect = const WorldRuleEffect(
        kind: WorldRuleEffectKind.entityHidden,
      );
    });
    h.view.view = WorldView.rules;
    await pumpIo(tester);

    await activate(tester, find.text('Enregistrer').first);
    expect(find.textContaining('Train parti'), findsWidgets);
    await activate(tester, find.text('Annuler'));
    expect(h.controller.project.worldRules, isEmpty);
    expect(h.controller.isRuleDirty(ruleId), isTrue);

    await activate(tester, find.text('Enregistrer').first);
    await tester.tap(find.text('Enregistrer l’état puis la règle'));
    await settle(tester);
    expect(h.controller.error, isNull);
    final rule = h.controller.project.worldRules.single;
    expect(
      h.controller.project.facts.any((fact) => fact.id == rule.source.sourceId),
      isTrue,
      reason: 'the rule keeps the canonical id the state received',
    );
    expect(h.controller.pendingRules, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
