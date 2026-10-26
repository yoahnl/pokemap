import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/ui12_world_harness.dart';

void main() {
  test('visual sliders retain structural catalogues and keep canonical drafts current', () async {
    final (h, port) = await _harness();
    addTearDown(h.dispose);
    final factId = _draftFact(h, 'Brume');
    final id = h.world.createRule(factId: factId);
    h.world.editRule(id, (draft) {
      draft.target = WorldRuleTarget(
        kind: WorldRuleTargetKind.atmosphere,
        mapId: h.world.project.maps.first.id,
      );
      draft.effect = WorldRuleEffect(
        kind: WorldRuleEffectKind.atmosphere,
        visualSettings: SpatialVisualPatch.fromJson({'fogOpacity': .1}),
      );
    });
    final catalog = h.world.catalog;
    final before = await _projectBytes(h);
    for (var i = 0; i < 100; i++) {
      h.world.editRule(id, (draft) {
        draft.effect = WorldRuleEffect(
          kind: WorldRuleEffectKind.atmosphere,
          visualSettings: SpatialVisualPatch.fromJson({'fogOpacity': i / 200}),
        );
      });
      expect(h.world.catalog, same(catalog));
      expect(
        h.world
            .rule(id)!
            .effect
            .visualSettings!
            .number(SpatialVisualParameter.fogOpacity),
        i / 200,
      );
    }
    expect(await _projectBytes(h), before);
    expect(port.batches, isEmpty);
    h.world.undoRule(id);
    expect(h.world.catalog, same(catalog));
    expect(
      h.world
          .rule(id)!
          .effect
          .visualSettings!
          .number(SpatialVisualParameter.fogOpacity),
      .49,
    );
    expect(h.world.model, isNot(same(catalog)));
    h.world.editRule(id, (draft) => draft.label = 'Autre libellé');
    expect(h.world.catalog.worldRules.single.rule.label, 'Autre libellé');
  });

  test('save all without rule drafts performs no publication', () async {
    final (h, port) = await _harness();
    addTearDown(h.dispose);
    expect(await h.world.saveAll(), isTrue);
    expect(port.factWrites, 0);
    expect(port.singleRuleWrites, 0);
    expect(port.batches, isEmpty);
    expect(await _journals(h), isEmpty);
  });

  test('save all publishes two rules with one canonical transaction', () async {
    final (h, port) = await _harness();
    addTearDown(h.dispose);
    final factId = await _savedFact(h);
    final before = (await _history(h)).map((entry) => entry.entryId).toSet();
    _rule(h, factId, 'Masquer le conducteur');
    _rule(h, factId, 'Masquer le contrôleur');

    expect(await h.world.saveAll(), isTrue, reason: h.world.error);
    expect(port.singleRuleWrites, 0);
    expect(port.batches, hasLength(1));
    expect(port.batches.single, hasLength(2));
    final created = (await _history(h))
        .where((entry) => !before.contains(entry.entryId));
    expect(created, hasLength(1));
    expect(created.single.receipt.actionId, 'world_rule.upsert_batch');
    expect(created.single.changes, hasLength(1));
    expect(created.single.changes.single.storageKey, 'project.json');
    expect(h.world.pendingRules, isEmpty);

    final reopened = await Ui12WorldHarness.open(h.directory);
    addTearDown(() => reopened.dispose(deleteDirectory: false));
    expect(reopened.world.project.worldRules, h.world.project.worldRules);
    expect(reopened.world.project.worldRules, hasLength(2));
  });

  test(
    'an incomplete last draft refuses every write including its fact',
    () async {
      final (h, port) = await _harness();
      addTearDown(h.dispose);
      final factId = _draftFact(h, 'Départ confirmé');
      _rule(h, factId, 'Première règle');
      h.world.createRule(factId: factId);
      final before = await _projectBytes(h);

      expect(await h.world.saveAll(), isFalse);
      expect(port.factWrites, 0);
      expect(port.singleRuleWrites, 0);
      expect(port.batches, isEmpty);
      expect(await _projectBytes(h), before);
      expect(await _journals(h), isEmpty);
      expect(h.world.pendingRules, hasLength(2));
      expect(h.world.narrative.pendingFacts, contains(factId));
    },
  );

  test(
    'an invalid last reference refuses the dependent fact before I/O',
    () async {
      final (h, port) = await _harness();
      addTearDown(h.dispose);
      final factId = _draftFact(h, 'Passage autorisé');
      _rule(h, factId, 'Première règle');
      final last = _rule(h, factId, 'Dernière règle');
      h.world.editRule(last, (draft) {
        draft.target = WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEntity,
          mapId: h.world.maps.first.id,
          entityId: 'entité absente',
        );
      });
      final before = await _projectBytes(h);

      expect(await h.world.saveAll(), isFalse);
      expect(port.factWrites, 0);
      expect(port.singleRuleWrites, 0);
      expect(port.batches, isEmpty);
      expect(await _projectBytes(h), before);
      expect(await _journals(h), isEmpty);
      expect(h.world.pendingRules, hasLength(2));
    },
  );

  test(
    '129 drafts are refused before any dependent fact publication',
    () async {
      final (h, port) = await _harness();
      addTearDown(h.dispose);
      final factId = _draftFact(h, 'Lot trop grand');
      for (var index = 0; index < 129; index++) {
        _rule(h, factId, 'Règle $index');
      }
      port.refuseWrites = true;
      final before = await _projectBytes(h);

      expect(await h.world.saveAll(), isFalse);
      expect(port.factWrites, 0);
      expect(port.singleRuleWrites, 0);
      expect(port.batches, isEmpty);
      expect(await _projectBytes(h), before);
      expect(h.world.pendingRules, hasLength(129));
    },
  );

  test(
    'new rules sharing a label receive sequential canonical identities',
    () async {
      final (h, port) = await _harness();
      addTearDown(h.dispose);
      final factId = await _savedFact(h);
      _rule(h, factId, 'Meme regle');
      _rule(h, factId, 'Meme regle');

      expect(await h.world.saveAll(), isTrue, reason: h.world.error);
      expect(h.world.project.worldRules.map((rule) => rule.id), [
        'world_rule_meme_regle',
        'world_rule_meme_regle_2',
      ]);
      expect(port.batches, hasLength(1));
      expect(h.world.selectedRuleId, 'world_rule_meme_regle_2');
    },
  );

  test(
    'one stale base refuses the complete batch without a first commit',
    () async {
      final (h, port) = await _harness();
      addTearDown(h.dispose);
      final factId = await _savedFact(h);
      for (final label in ['Première règle', 'Seconde règle']) {
        expect(await h.world.saveRule(_rule(h, factId, label)), isTrue);
      }
      final first = h.world.project.worldRules.first;
      final second = h.world.project.worldRules.last;
      h.world.editRule(
        first.id,
        (draft) => draft.description = 'Premier brouillon',
      );
      h.world.editRule(
        second.id,
        (draft) => draft.description = 'Second brouillon',
      );
      final external = await Ui12WorldHarness.open(h.directory);
      addTearDown(() => external.dispose(deleteDirectory: false));
      final changed = WorldRuleDefinition.fromJson({
        ...second.toJson(),
        'description': 'Écriture externe',
      });
      await external.port.publishRule(base: second, current: changed);
      final before = await _projectBytes(h);
      final journals = await _journals(h);
      final history = (await _history(h))
          .map((entry) => entry.entryId)
          .toList();
      port.singleRuleWrites = 0;

      expect(await h.world.saveAll(), isFalse);
      expect(await _projectBytes(h), before);
      expect(await _journals(h), journals);
      expect((await _history(h)).map((entry) => entry.entryId), history);
      expect(h.world.pendingRules.keys, [first.id, second.id]);
      expect(h.world.error, contains('changé sur le disque'));
      expect(port.singleRuleWrites, 0);
    },
  );

  test(
    'an edit during a batch survives its receipt with history and selection',
    () async {
      final (h, port) = await _harness();
      addTearDown(h.dispose);
      final factId = await _savedFact(h);
      _rule(h, factId, 'Première règle');
      final second = _rule(h, factId, 'Seconde règle');
      port.gate = Completer<void>();
      final saving = h.world.saveAll();
      await port.started.future;
      h.world.editRule(
        second,
        (draft) => draft.description = 'Pendant l’écriture',
      );
      port.gate!.complete();

      expect(await saving, isFalse);
      final published = h.world.project.worldRules.last;
      expect(published.description, isEmpty);
      expect(h.world.pendingRules.keys, [published.id]);
      expect(
        h.world.ruleDraft(published.id)!.description,
        'Pendant l’écriture',
      );
      expect(h.world.selectedRuleId, published.id);
      expect(h.world.canUndoRule(published.id), isTrue);
      h.world.undoRule(published.id);
      expect(h.world.ruleDraft(published.id)!.description, isEmpty);
      expect(port.batches, hasLength(1));
    },
  );

  test('a withdrawn draft is not adopted after the batch commits', () async {
    final (h, port) = await _harness();
    addTearDown(h.dispose);
    final factId = await _savedFact(h);
    _rule(h, factId, 'Première règle');
    final withdrawn = _rule(h, factId, 'Seconde règle');
    port.gate = Completer<void>();
    final saving = h.world.saveAll();
    await port.started.future;
    expect(await h.world.deleteRule(withdrawn), isTrue);
    port.gate!.complete();

    expect(await saving, isFalse);
    expect(h.world.project.worldRules, hasLength(2));
    expect(h.world.pendingRules, isEmpty);
    expect(h.world.ruleDraft(withdrawn), isNull);
    expect(h.world.selectedRuleId, isNull);
    expect(h.world.canUndoRule(h.world.project.worldRules.last.id), isFalse);
  });

  test(
    'a closed controller ignores a batch receipt without dropping drafts',
    () async {
      final (h, port) = await _harness();
      addTearDown(h.dispose);
      final factId = await _savedFact(h);
      final first = _rule(h, factId, 'Première règle');
      final second = _rule(h, factId, 'Seconde règle');
      port.gate = Completer<void>();
      final saving = h.world.saveAll();
      await port.started.future;
      h.world.dispose();
      port.gate!.complete();

      expect(await saving, isFalse);
      expect(h.world.project.worldRules, isEmpty);
      expect(h.world.pendingRules.keys, [first, second]);
      expect(h.world.selectedRuleId, second);
      final reopened = await Ui12WorldHarness.open(h.directory);
      addTearDown(() => reopened.dispose(deleteDirectory: false));
      expect(reopened.world.project.worldRules, hasLength(2));
    },
  );

  test(
    'closing after a dependent fact prevents the rule batch from starting',
    () async {
      final (h, port) = await _harness();
      addTearDown(h.dispose);
      final factId = _draftFact(h, 'Départ confirmé');
      final first = _rule(h, factId, 'Première règle');
      final second = _rule(h, factId, 'Seconde règle');
      var closed = false;
      h.onChanged = () {
        if (!closed &&
            !h.world.saving &&
            h.world.project.facts.any(
              (fact) => fact.label == 'Départ confirmé',
            )) {
          closed = true;
          h.world.dispose();
        }
      };

      expect(await h.world.saveAll(), isFalse);
      expect(closed, isTrue);
      expect(port.batches, isEmpty);
      expect(port.factWrites, 1);
      expect(h.world.pendingRules.keys, [first, second]);
      expect(h.world.project.worldRules, isEmpty);
      final reopened = await Ui12WorldHarness.open(h.directory);
      addTearDown(() => reopened.dispose(deleteDirectory: false));
      expect(
        reopened.world.project.facts.any(
          (fact) => fact.label == 'Départ confirmé',
        ),
        isTrue,
      );
      expect(reopened.world.project.worldRules, isEmpty);
      expect((await _history(h)).map((entry) => entry.receipt.actionId), [
        'fact.create',
      ]);
    },
  );

  test(
    'closing in the saving callback prevents the rule batch from starting',
    () async {
      final (h, port) = await _harness();
      addTearDown(h.dispose);
      final factId = await _savedFact(h);
      final first = _rule(h, factId, 'Première règle');
      final second = _rule(h, factId, 'Seconde règle');
      h.onChanged = () {
        if (h.world.saving) h.world.dispose();
      };

      expect(await h.world.saveAll(), isFalse);
      expect(port.batches, isEmpty);
      expect(h.world.pendingRules.keys, [first, second]);
      expect(h.world.project.worldRules, isEmpty);
    },
  );

  test(
    'a superseding generation after a dependent fact prevents the batch',
    () async {
      final (h, port) = await _harness();
      addTearDown(h.dispose);
      final factId = _draftFact(h, 'Départ confirmé');
      final first = _rule(h, factId, 'Première règle');
      final second = _rule(h, factId, 'Seconde règle');
      var refreshed = false;
      Future<void>? refreshing;
      h.onChanged = () {
        if (!refreshed &&
            !h.world.saving &&
            h.world.project.facts.any(
              (fact) => fact.label == 'Départ confirmé',
            )) {
          refreshed = true;
          refreshing = h.world.initialize();
        }
      };

      expect(await h.world.saveAll(), isFalse);
      await refreshing;
      expect(refreshed, isTrue);
      expect(port.batches, isEmpty);
      expect(port.factWrites, 1);
      expect(h.world.pendingRules.keys, [first, second]);
      expect(h.world.project.worldRules, isEmpty);
      expect((await _history(h)).map((entry) => entry.receipt.actionId), [
        'fact.create',
      ]);
    },
  );

  test('only dependent facts are saved before one rule batch', () async {
    final (h, port) = await _harness();
    addTearDown(h.dispose);
    final dependency = _draftFact(h, 'Départ confirmé');
    final independent = _draftFact(h, 'État indépendant');
    _rule(h, dependency, 'Première règle');
    _rule(h, dependency, 'Seconde règle');

    expect(await h.world.saveAll(), isTrue, reason: h.world.error);
    expect(port.factWrites, 1);
    expect(port.batches, hasLength(1));
    expect(h.world.narrative.pendingFacts.keys, [independent]);
    final savedFact = h.world.project.facts.singleWhere(
      (fact) => fact.label == 'Départ confirmé',
    );
    expect(savedFact.id, isNot(dependency));
    expect(h.world.project.worldRules.map((rule) => rule.source.sourceId), [
      savedFact.id,
      savedFact.id,
    ]);
  });

  test(
    'a refused batch reports facts already saved as a partial result',
    () async {
      final (h, port) = await _harness();
      addTearDown(h.dispose);
      final factId = _draftFact(h, 'Départ confirmé');
      _rule(h, factId, 'Première règle');
      _rule(h, factId, 'Seconde règle');
      port.ruleFailure = const WorldFailure('Lot refusé');

      expect(await h.world.saveAll(), isFalse);
      expect(port.factWrites, 1);
      expect(port.batches, hasLength(1));
      expect(h.world.error, contains('Lot refusé'));
      expect(h.world.error, contains('enregistré'));
      expect(h.world.project.worldRules, isEmpty);
      expect(h.world.pendingRules, hasLength(2));
      expect(
        h.world.project.facts.any((fact) => fact.label == 'Départ confirmé'),
        isTrue,
      );
    },
  );
}

Future<(Ui12WorldHarness, _BatchWorldPort)> _harness() async {
  late _BatchWorldPort port;
  final h = await Ui12WorldHarness.create(
    wrap: (delegate) => port = _BatchWorldPort(delegate),
  );
  return (h, port);
}

String _draftFact(Ui12WorldHarness h, String label) {
  final id = h.world.createFact();
  h.world.editFact(NarrativeFactDefinition(id: id, label: label));
  return id;
}

Future<String> _savedFact(Ui12WorldHarness h) async {
  final id = _draftFact(h, 'Train parti');
  expect(await h.world.saveFact(id), isTrue, reason: h.world.error);
  return h.world.selectedFactId!;
}

String _rule(Ui12WorldHarness h, String factId, String label) {
  final map = h.world.maps.firstWhere((map) => map.entities.isNotEmpty);
  final id = h.world.createRule(factId: factId);
  h.world.editRule(id, (draft) {
    draft.label = label;
    draft.target = WorldRuleTarget(
      kind: WorldRuleTargetKind.mapEntity,
      mapId: map.id,
      entityId: map.entities.first.id,
    );
    draft.effect = const WorldRuleEffect(
      kind: WorldRuleEffectKind.entityHidden,
    );
  });
  return id;
}

Future<List<int>> _projectBytes(Ui12WorldHarness h) =>
    File('${h.directory.path}/project.json').readAsBytes();

Future<List<String>> _journals(Ui12WorldHarness h) async {
  final directory = Directory('${h.directory.path}/.pokemap');
  if (!await directory.exists()) return [];
  final journals = await directory
      .list(recursive: true)
      .where((entry) => entry is File && entry.path.endsWith('/journal.json'))
      .map((entry) => entry.path)
      .toList();
  return journals..sort();
}

Future<List<AuthoringHistoryEntry>> _history(Ui12WorldHarness h) async {
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: [h.directory.path],
    fileReader: reader,
  );
  final handles = WorkspaceHandleStore();
  final opened = await ProjectOpenService(
    policy: policy,
    fileReader: reader,
    handles: handles,
  ).openProject(h.directory.path);
  final api = LocalMapAuthoringMutationApi(
    policy: policy,
    snapshotLoader: ProjectSnapshotLoader(handles: handles),
  );
  await api.attachProject(
    projectRootPath: h.directory.path,
    workspaceHandle: opened.workspaceHandle,
    projectHandle: opened.projectHandle,
  );
  try {
    return (await api.listMutationHistory(
      opened.projectHandle,
      limit: 100,
    )).entries;
  } finally {
    await api.detachWorkspace(opened.workspaceHandle);
  }
}

class _BatchWorldPort implements WorldPort {
  _BatchWorldPort(this.delegate);
  final WorldPort delegate;
  final batches =
      <List<({WorldRuleDefinition? base, WorldRuleDefinition current})>>[];
  int factWrites = 0, singleRuleWrites = 0;
  bool refuseWrites = false;
  Object? ruleFailure;
  Completer<void>? gate;
  final started = Completer<void>();

  Future<void> _beforeRuleWrite() async {
    if (!started.isCompleted) started.complete();
    if (gate case final gate?) await gate.future;
    if (ruleFailure case final failure?) throw failure;
    if (refuseWrites) throw const WorldFailure('Écriture inattendue');
  }

  @override
  Future<ResourceMutationReceipt> publishRuleBatch({
    required List<({WorldRuleDefinition? base, WorldRuleDefinition current})>
    rules,
  }) async {
    batches.add(List.of(rules));
    await _beforeRuleWrite();
    return delegate.publishRuleBatch(rules: rules);
  }

  @override
  Future<ResourceMutationReceipt> publishRule({
    required WorldRuleDefinition? base,
    required WorldRuleDefinition current,
  }) async {
    singleRuleWrites++;
    await _beforeRuleWrite();
    return delegate.publishRule(base: base, current: current);
  }

  @override
  Future<ResourceMutationReceipt> publishFact({
    required NarrativeFactDefinition? base,
    required NarrativeFactDefinition current,
  }) {
    factWrites++;
    if (refuseWrites) throw const WorldFailure('Écriture inattendue');
    return delegate.publishFact(base: base, current: current);
  }

  @override
  Future<ResourceMutationReceipt> deleteFact(NarrativeFactDefinition base) =>
      delegate.deleteFact(base);

  @override
  Future<ResourceMutationReceipt> deleteRule(WorldRuleDefinition base) =>
      delegate.deleteRule(base);

  @override
  Future<List<MapData>> loadMaps() => delegate.loadMaps();
}
