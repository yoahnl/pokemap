import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_narrative_event_consumers.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

String _event(int index) =>
    'evt_019abcde-0000-7000-8000-${index.toRadixString(16).padLeft(12, '0')}';

final _ruled = _event(1);
final _spare = _event(2);
final _sourced = _event(3);

WorldRuleDefinition _targetRule(String eventId, String label) =>
    WorldRuleDefinition(
        id: 'world_rule_target',
        label: label,
        source: WorldRuleSource.civilWeekday(
            weekday: CivilWeekday.friday, expectedValue: true),
        target: WorldRuleTarget(
            kind: WorldRuleTargetKind.narrativeEvent,
            mapId: '',
            eventId: eventId),
        effect: const WorldRuleEffect(kind: WorldRuleEffectKind.eventDisabled));

NarrativeEventRecord _draft(String id, String name) =>
    NarrativeEventRecord.draft(NarrativeEventDraft(
        id: id, name: name, conditions: const [], priority: 0, order: 0));

void main() {
  Future<Set<String>> users(_Fixture fixture, String eventId) async => {
        for (final consumer in await CatalogNarrativeEventConsumers.consumersOf(
                await fixture.snapshot(), eventId) ??
            const <CatalogNarrativeEventConsumer>[])
          '${consumer.kind}:${consumer.id}:${consumer.label}'
      };

  Future<({_Fixture fixture, String created, String renamed})> edit(
      {required bool derived}) async {
    final fixture = await _Fixture.open();
    addTearDown(fixture.close);
    if (derived) {
      await fixture.api.prepareWorkshopCatalog(fixture.opened.projectHandle,
          scope: CatalogNarrativeEventConsumers.preparationScope);
    }
    final created = await fixture.apply('world_rule.create',
        {'rule': _targetRule(_ruled, 'Target').toJson()}, 'create-rule');
    final renamed = await fixture.apply('world_rule.update',
        {'rule': _targetRule(_ruled, 'Renamed').toJson()}, 'rename-rule');
    return (
      fixture: fixture,
      created: created.receipt.receiptId,
      renamed: renamed.receipt.receiptId
    );
  }

  test('a separate derived index follows edits, undo, redo and reopening',
      () async {
    final (:fixture, :created, :renamed) = await edit(derived: true);
    expect(await users(fixture, _sourced),
        {'worldRule:world_rule_consumed:Consumed'});
    expect(
        await users(fixture, _ruled), {'worldRule:world_rule_target:Renamed'});
    await fixture.api.undoMutation(fixture.opened.projectHandle,
        entryId: renamed, idempotencyKey: 'undo-1');
    expect(
        await users(fixture, _ruled), {'worldRule:world_rule_target:Target'});
    await fixture.api.undoMutation(fixture.opened.projectHandle,
        entryId: created, idempotencyKey: 'undo-2');
    expect(await users(fixture, _ruled), isEmpty);
    await fixture.api.redoMutation(fixture.opened.projectHandle,
        entryId: created, idempotencyKey: 'redo-1');
    expect(
        await users(fixture, _ruled), {'worldRule:world_rule_target:Target'});
    await fixture.reattach();
    await fixture.api.prepareWorkshopCatalog(fixture.opened.projectHandle);
    await fixture.api.prepareWorkshopCatalog(fixture.opened.projectHandle,
        scope: 'metadataContext');
    final head = await fixture.snapshot();
    final preview = await fixture.api.maintainHistory(
        fixture.opened.projectHandle,
        expectedRevision: 'sha256:${head.root.sha256}');
    expect(preview['blockedReason'], isNull);
    await fixture.api.redoMutation(fixture.opened.projectHandle,
        entryId: renamed, idempotencyKey: 'redo-2');
    expect(
        await users(fixture, _ruled), {'worldRule:world_rule_target:Renamed'});
  });

  for (final derived in [false, true]) {
    test(
        'history maintenance ${derived ? 'reports' : 'prepares'} retained generations ${derived ? 'with' : 'without'} a separate derived index',
        () async {
      final (:fixture, :created, :renamed) = await edit(derived: derived);
      await fixture.api.undoMutation(fixture.opened.projectHandle,
          entryId: renamed, idempotencyKey: 'undo-1');
      await fixture.reattach();
      await fixture.api.prepareWorkshopCatalog(fixture.opened.projectHandle);
      final head = 'sha256:${(await fixture.snapshot()).root.sha256}';
      final preview = await fixture.api.maintainHistory(
          fixture.opened.projectHandle,
          expectedRevision: head,
          maxOperations: 1);
      final applied = await fixture.api.maintainHistory(
          fixture.opened.projectHandle,
          expectedRevision: head,
          maxOperations: 1,
          apply: true,
          expectedFingerprint: preview['fingerprint'] as String);
      expect(applied['validatedHistoricalGenerations'], 2);
      expect(applied['preparedHistoricalGenerations'], derived ? 0 : 2);
      expect(applied['historicalGenerationsRequiringPreparation'],
          hasLength(derived ? 2 : 0));
      final copy = await fixture.copy();
      addTearDown(copy.close);
      await copy.api.prepareWorkshopCatalog(copy.opened.projectHandle);
      final redo = copy.api.redoMutation(copy.opened.projectHandle,
          entryId: renamed, idempotencyKey: 'copy-redo');
      if (!derived) {
        await redo;
        return;
      }
      await expectLater(
          redo,
          throwsA(isA<CatalogStorageException>().having(
              (error) => error.code, 'code', 'catalog.preparation_required')));
    });
  }

  for (final derived in [false, true]) {
    test(
        'a copied project undoes an upsert-only edit ${derived ? 'with' : 'without'} a separate derived index',
        () async {
      final (:fixture, :created, :renamed) = await edit(derived: derived);
      final copy = await fixture.copy();
      addTearDown(copy.close);
      await copy.api.prepareWorkshopCatalog(copy.opened.projectHandle);
      final undo = copy.api.undoMutation(copy.opened.projectHandle,
          entryId: renamed, idempotencyKey: 'copy-undo');
      if (!derived) {
        await undo;
        await expectLater(
            copy.api.undoMutation(copy.opened.projectHandle,
                entryId: created, idempotencyKey: 'copy-undo-create'),
            throwsA(isA<FormatException>().having(
                (error) => error.message,
                'message',
                'catalog.delta: removal dependency proof required')));
        return;
      }
      await expectLater(
          undo,
          throwsA(isA<CatalogStorageException>().having(
              (error) => error.code, 'code', 'catalog.preparation_required')));
      await copy.api.prepareWorkshopCatalog(copy.opened.projectHandle,
          scope: 'metadataContext');
      await copy.api.undoMutation(copy.opened.projectHandle,
          entryId: renamed, idempotencyKey: 'copy-undo-after-context');
      expect(await users(copy, _ruled), {'worldRule:world_rule_target:Target'});
      await expectLater(
          copy.apply('world_rule.update',
              {'rule': _targetRule(_spare, 'Moved').toJson()}, 'copy-refused'),
          throwsA(isA<CatalogStorageException>().having(
              (error) => error.code, 'code', 'catalog.preparation_required')));
      await copy.api.prepareWorkshopCatalog(copy.opened.projectHandle);
      await copy.apply('world_rule.update',
          {'rule': _targetRule(_spare, 'Moved').toJson()}, 'copy-move-rule');
      expect(await users(copy, _spare), {'worldRule:world_rule_target:Moved'});
    });
  }
}

final class _Fixture {
  _Fixture(this.root, this.opened, this.handles, this.api);
  final Directory root;
  final OpenedProject opened;
  final WorkspaceHandleStore handles;
  final LocalMapAuthoringMutationApi api;

  static Directory get _qa =>
      Directory('/Users/karim/Library/Caches/AveluneQA/c1/derived-history');

  static Future<_Fixture> open() async {
    await _qa.create(recursive: true);
    final root = await _qa.createTemp('project-');
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    await WorkingProjectCatalog.create(
      store: store,
      projectId: 'derived-history',
      project: ProjectManifest(
        name: 'Derived history',
        maps: const [],
        tilesets: const [],
        worldRules: [
          WorldRuleDefinition(
              id: 'world_rule_consumed',
              label: 'Consumed',
              source: WorldRuleSource(
                  kind: WorldRuleSourceKind.consumedEvent,
                  sourceId: _sourced,
                  predicate: WorldRuleSourcePredicate.consumed),
              target: const WorldRuleTarget(
                  kind: WorldRuleTargetKind.mapEntity,
                  mapId: 'town',
                  entityId: 'tree'),
              effect: const WorldRuleEffect(
                  kind: WorldRuleEffectKind.entityHidden)),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            _draft(_ruled, 'Ruled'),
            _draft(_spare, 'Spare'),
            _draft(_sourced, 'Sourced'),
          ],
          legacyClaims: const [],
        ),
      ),
    );
    return attach(root);
  }

  static Future<_Fixture> attach(Directory root) async {
    const reader = LocalProjectFileReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
      catalogMetadataFields: {},
    ).openProject(root.path);
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      catalogFileReader: reader,
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
    );
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return _Fixture(root, opened, handles, api);
  }

  Future<_Fixture> copy() async {
    final target = await _qa.createTemp('copy-');
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      final relative = entity.path.substring(root.path.length + 1);
      if (entity is Directory) {
        await Directory('${target.path}/$relative').create(recursive: true);
      } else if (entity is File) {
        final file = File('${target.path}/$relative');
        await file.parent.create(recursive: true);
        await entity.copy(file.path);
      }
    }
    return attach(target);
  }

  Future<void> reattach() async {
    await api.detachWorkspace(opened.workspaceHandle);
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
  }

  Future<CatalogSnapshot> snapshot() async {
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    return (await store.openRoot((await store.readHead())!)).snapshot;
  }

  Future<AuthoringMutationResult> apply(
      String action, Map<String, Object?> parameters, String operation) async {
    final snapshot = await api.readWorkshopSnapshot(opened.projectHandle,
        actionId: action, parameters: parameters);
    final plan = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
            requestId: operation,
            actionId: action,
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: operation,
            parameters: parameters,
            extensions: const {'workshopScope': true}));
    return api.applyMutation(opened.projectHandle,
        planId: plan.planId, operationId: operation);
  }

  Future<void> close() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    await root.delete(recursive: true);
  }
}
