import 'dart:async';

import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/ui12_held_world_port.dart';
import 'support/ui12_world_harness.dart';

const _label = 'Train parti de Kisaragi';

String draftState(Ui12WorldHarness h) {
  final id = h.world.createFact();
  h.world.editFact(
    NarrativeFactDefinition(
      id: id,
      label: _label,
      initialValue: const NarrativeValue.boolean(false),
    ),
  );
  return id;
}

String composeRule(Ui12WorldHarness h, String factId) {
  final map = h.world.maps.firstWhere((map) => map.entities.isNotEmpty);
  final entity = map.entities.first;
  final id = h.world.createRule(factId: factId);
  h.world.editRule(id, (draft) {
    draft.label = 'Masquer le conducteur';
    draft.target = WorldRuleTarget(
      kind: WorldRuleTargetKind.mapEntity,
      mapId: map.id,
      entityId: entity.id,
      label: entity.id,
    );
    draft.effect = const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden);
  });
  return id;
}

Future<(Ui12WorldHarness, Ui12HeldWorldPort)> held() async {
  late Ui12HeldWorldPort port;
  final h = await Ui12WorldHarness.create(
    wrap: (delegate) => port = Ui12HeldWorldPort(delegate),
  );
  return (h, port);
}

void main() {
  test('an edit made during the write is kept as an unsaved draft', () async {
    final (h, port) = await held();
    addTearDown(h.dispose);
    final factId = draftState(h);
    expect(await h.world.saveFact(factId), isTrue, reason: h.world.error ?? '');
    final savedFact = h.world.project.facts
        .firstWhere((fact) => fact.label == _label)
        .id;
    final ruleId = composeRule(h, savedFact);

    port.ruleGate = Completer<void>();
    final saving = h.world.saveRule(ruleId);
    await pumpEventQueue();
    h.world.editRule(
      ruleId,
      (draft) => draft.description = 'Ajoutée pendant l’écriture',
    );
    port.ruleGate!.complete();
    expect(await saving, isTrue, reason: h.world.error ?? '');

    final published = h.world.project.worldRules.single;
    expect(
      published.description,
      isEmpty,
      reason: 'the version actually sent is the one that got published',
    );
    expect(port.sentRules.single.description, isEmpty);
    expect(
      h.world.pendingRules.keys,
      [published.id],
      reason: 'the edit made during the write must survive the receipt',
    );
    expect(h.world.ruleDraft(published.id)!.description, 'Ajoutée pendant l’écriture');
    expect(h.world.selectedRuleId, published.id);
    expect(h.world.isRuleDirty(published.id), isTrue);

    expect(await h.world.saveRule(published.id), isTrue, reason: h.world.error ?? '');
    expect(h.world.pendingRules, isEmpty);

    final reopened = await Ui12WorldHarness.open(h.directory);
    addTearDown(() => reopened.dispose(deleteDirectory: false));
    expect(
      reopened.world.project.worldRules.single.description,
      'Ajoutée pendant l’écriture',
    );
  });

  test('an untouched rule becomes clean again after its publication', () async {
    final h = await Ui12WorldHarness.create();
    addTearDown(h.dispose);
    final factId = draftState(h);
    expect(await h.world.saveFact(factId), isTrue, reason: h.world.error ?? '');
    final savedFact = h.world.project.facts
        .firstWhere((fact) => fact.label == _label)
        .id;
    final ruleId = composeRule(h, savedFact);
    expect(await h.world.saveRule(ruleId), isTrue, reason: h.world.error ?? '');
    expect(h.world.pendingRules, isEmpty);
    expect(h.world.hasRuleDraft, isFalse);
  });

  test('a rule saved before its brand-new state explains the dependency', () async {
    final h = await Ui12WorldHarness.create();
    addTearDown(h.dispose);
    final factId = draftState(h);
    final ruleId = composeRule(h, factId);

    expect(await h.world.saveRule(ruleId), isFalse);
    expect(h.world.error, contains(_label));
    expect(
      h.world.pendingRules.keys,
      contains(ruleId),
      reason: 'a refused publication must never drop the draft',
    );
    expect(h.world.project.worldRules, isEmpty);
    expect(h.world.unsavedRuleDependency(ruleId)?.id, factId);

    expect(
      await h.world.saveRuleWithDependency(ruleId),
      isTrue,
      reason: h.world.error ?? '',
    );
    final rule = h.world.project.worldRules.single;
    expect(rule.source.sourceId, isNot(factId));
    expect(
      h.world.project.facts.any((fact) => fact.id == rule.source.sourceId),
      isTrue,
      reason: 'the rule must keep the canonical id the state received',
    );
    expect(h.world.pendingRules, isEmpty);
  });

  test('a state saved and a rule refused is reported as a partial result', () async {
    final (h, port) = await held();
    addTearDown(h.dispose);
    final factId = draftState(h);
    final ruleId = composeRule(h, factId);
    port.ruleFailure = const WorldFailure('écriture refusée');

    expect(await h.world.saveRuleWithDependency(ruleId), isFalse);
    expect(h.world.error, contains('écriture refusée'));
    expect(h.world.error, contains('état'));
    expect(h.world.project.facts.any((fact) => fact.label == _label), isTrue);
    expect(h.world.pendingRules, isNotEmpty);
    expect(h.world.project.worldRules, isEmpty);
  });
}
