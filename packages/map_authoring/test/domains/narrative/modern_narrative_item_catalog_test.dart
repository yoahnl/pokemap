import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/domains/narrative/narrative_action_support.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('modern narrative item catalog', () {
    for (final kind in ['give', 'take', 'interactive', 'condition']) {
      test('$kind preview and diagnostic delta resolve the snapshot catalog',
          () {
        final snapshot = _snapshot(itemCatalog: _catalog);
        final scene = _itemScene(kind);
        final draft = const SceneActions().build(_context(snapshot, scene));

        expect(draft.preview['canPublish'], isTrue);
        expect(draft.preview['diagnostics'], isEmpty);
        final delta = draft.preview['diagnosticDelta'] as Map;
        expect(delta['introduced'], isEmpty);
      });

      test('$kind scene query resolves known items', () {
        final scene = _itemScene(kind);
        final snapshot = _snapshot(scenes: [scene], itemCatalog: _catalog);

        expect(_sceneDiagnostics(snapshot, scene.id), isEmpty);
      });

      test('$kind scene query rejects an item absent from a loaded catalog',
          () {
        final scene = _itemScene(kind);
        final snapshot = _snapshot(scenes: [scene], itemCatalog: _emptyCatalog);

        expect(
          _sceneDiagnostics(snapshot, scene.id)
              .where((diagnostic) => diagnostic['severity'] == 'error'),
          isNotEmpty,
        );
      });

      test('$kind mutation rejects an item absent from a loaded catalog',
          () async {
        final snapshot = _snapshot(itemCatalog: _emptyCatalog);

        await expectLater(
          const SceneActions().prepare(_context(snapshot, _itemScene(kind))),
          throwsA(isA<NarrativeAuthoringException>().having(
            (error) => error.code,
            'code',
            'scene.publication_blocked',
          )),
        );
      });
    }

    test('Fact preview resolves item references from the snapshot catalog', () {
      final scene = _itemScene('give');
      final snapshot = _snapshot(scenes: [scene], itemCatalog: _catalog);
      final draft = const FactRuleActions().build(_context(
        snapshot,
        scene,
        actionId: 'fact.create',
        parameters: {
          'fact':
              NarrativeFactDefinition(id: 'fact_test', label: 'Test').toJson(),
        },
      ));

      expect(draft.preview['canPublish'], isTrue);
      expect(draft.preview['diagnostics'], isEmpty);
    });

    test('Event preview resolves item references from the snapshot catalog',
        () {
      final scene = _itemScene('give');
      final snapshot = _snapshot(scenes: [scene], itemCatalog: _catalog);
      final draft = const EventV2Actions().build(_context(
        snapshot,
        scene,
        actionId: 'event_v2.registry_mode.set',
        parameters: {'mode': EventSystemMode.v2Only.name},
      ));

      expect(draft.preview['canPublish'], isTrue);
      expect(draft.preview['diagnostics'], isEmpty);
    });

    test('Fact preview preserves unknown item publication blockers', () {
      final scene = _itemScene('give');
      final snapshot = _snapshot(scenes: [scene], itemCatalog: _emptyCatalog);
      final draft = const FactRuleActions().build(_context(
        snapshot,
        scene,
        actionId: 'fact.create',
        parameters: {
          'fact':
              NarrativeFactDefinition(id: 'fact_test', label: 'Test').toJson(),
        },
      ));

      expect(draft.preview['canPublish'], isFalse);
      expect(
        draft.preview['diagnostics'],
        contains(allOf(
          containsPair('code', 'scene.consequenceUnknownItem'),
          containsPair('severity', 'error'),
        )),
      );
    });

    test('graph patch cannot bypass item reference validation', () async {
      final scene = _itemScene('give');
      final snapshot = _snapshot(scenes: [scene], itemCatalog: _catalog);
      final context = _context(
        snapshot,
        scene,
        actionId: 'scene.graph.patch',
        parameters: {
          'sceneId': scene.id,
          'upsertNodes': [
            {
              ...scene.graph.nodes[1].toJson(),
              'title': 'Grant a missing item',
              'payload': SceneActionPayload.consequence(
                SceneConsequence.giveItem(itemId: 'missing_item', quantity: 1),
              ).toJson(),
            }
          ],
        },
      );

      await expectLater(
        const SceneActions().prepare(context),
        throwsA(isA<NarrativeAuthoringException>().having(
          (error) => error.code,
          'code',
          'scene.publication_blocked',
        )),
      );
    });

    test('an unavailable catalog keeps Scene diagnostics provisional', () {
      final scene = _itemScene('give');
      final snapshot = _snapshot(scenes: [scene]);
      final diagnostics = _sceneDiagnostics(snapshot, scene.id);

      expect(diagnostics,
          contains(containsPair('code', 'consequenceItemCatalogUnavailable')));
      expect(
          diagnostics
              .every((diagnostic) => diagnostic['severity'] == 'warning'),
          isTrue);
      final draft = narrativeProjectDraft(
        _snapshot(),
        snapshot.manifest,
        operation: 'scene.upsert',
        path: '/scenes/${scene.id}',
      );
      final delta = draft.preview['diagnosticDelta'] as Map;
      expect(
        (delta['introduced'] as List).cast<Map>().where((diagnostic) =>
            diagnostic['code'] == 'dependency.unavailableReference'),
        contains(containsPair('severity', 'error')),
      );
    });

    for (final code in [
      'project.item_catalog_missing',
      'project.item_catalog_invalid'
    ]) {
      test('scene query preserves blocking load diagnostic $code', () {
        final scene = _itemScene('give');
        final snapshot = _snapshot(
          scenes: [scene],
          loadDiagnostics: [
            ProjectSnapshotLoadDiagnostic(
              code: code,
              resourceKind: 'itemCatalog',
              resourceId: 'items',
            )
          ],
        );

        expect(
          _sceneDiagnostics(snapshot, scene.id),
          contains(allOf(
            containsPair('code', code),
            containsPair('severity', 'error'),
            containsPair('resourceKind', 'itemCatalog'),
          )),
        );
      });
    }

    test('catalog propagation preserves other publication blockers', () {
      final scene = _itemScene('give');
      final broken = SceneAsset(
        id: scene.id,
        name: scene.name,
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [SceneNode(id: 'start', kind: SceneNodeKind.start)],
          edges: const [],
        ),
      );
      final snapshot = _snapshot(itemCatalog: _catalog);

      expect(
        () => const SceneActions().build(_context(snapshot, broken)),
        throwsA(isA<NarrativeAuthoringException>().having(
          (error) => error.code,
          'code',
          'scene.publication_blocked',
        )),
      );
    });
  });
}

const _catalog = ProjectItemCatalog(
  schemaVersion: 1,
  entries: [
    ProjectItemDefinition(
      id: 'potion',
      displayName: 'Potion',
      pocketId: 'medicine',
    )
  ],
);

const _emptyCatalog = ProjectItemCatalog(schemaVersion: 1, entries: []);

ProjectSnapshot _snapshot({
  List<SceneAsset> scenes = const [],
  ProjectItemCatalog? itemCatalog,
  List<ProjectSnapshotLoadDiagnostic> loadDiagnostics = const [],
}) {
  final manifest = ProjectManifest(
    name: 'Narrative item catalog',
    maps: const [],
    tilesets: const [],
    scenes: scenes,
  );
  final bytes = utf8.encode(jsonEncode(manifest.toJson()));
  final revision =
      computeAuthoringBytesFingerprint(bytes, logicalName: 'project.json');
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('item-catalog-fixture'),
    revision: revision,
    manifest: manifest,
    maps: const [],
    itemCatalog: itemCatalog,
    resourceFingerprints: {'project': revision},
    resourceBytes: {'project': bytes},
    loadDiagnostics: loadDiagnostics,
  );
}

AuthoringPlanningContext _context(
  ProjectSnapshot snapshot,
  SceneAsset scene, {
  String actionId = 'scene.upsert',
  Map<String, Object?>? parameters,
}) =>
    AuthoringPlanningContext(
      snapshot: snapshot,
      request: AuthoringRequest(
        requestId: 'item-catalog-request',
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: 'item-catalog-workspace',
        expectedRevision: snapshot.revision,
        idempotencyKey: 'item-catalog-mutation',
        parameters: parameters ?? {'scene': scene.toJson()},
      ),
      planId: 'item-catalog-plan',
      seed: 1,
    );

List<Map> _sceneDiagnostics(ProjectSnapshot snapshot, String sceneId) {
  final result = const ProjectQueryService().query(
    snapshot,
    AuthoringQueryRequest(
      resourceKind: 'scene',
      operation: AuthoringQueryOperation.get,
      view: AuthoringQueryView.detail,
      ids: [sceneId],
    ),
  );
  return (result.items.single['diagnostics'] as List).cast<Map>();
}

SceneAsset _itemScene(String kind) {
  final condition = kind == 'condition';
  final payload = switch (kind) {
    'give' => SceneActionPayload.consequence(
        SceneConsequence.giveItem(itemId: 'potion', quantity: 1)),
    'take' => SceneActionPayload.consequence(
        SceneConsequence.takeItem(itemId: 'potion', quantity: 1)),
    'interactive' => SceneActionPayload.interactive(
        SceneInteractiveCommand.giveItem(itemId: 'potion', quantity: 1)),
    'condition' => SceneConditionPayload(
          conditionSource: SceneConditionSource(
        sourceKind: SceneConditionSourceKind.inventoryItem,
        sourceId: 'potion',
        field: 'minimumQuantity',
        value: '1',
        operator: SceneConditionOperator.isTrue,
        label: 'Au moins une Potion',
      )),
    _ => throw ArgumentError.value(kind, 'kind'),
  };
  return SceneAsset(
    id: 'item_scene',
    name: 'Item scene',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
            id: 'item',
            kind: condition ? SceneNodeKind.condition : SceneNodeKind.action,
            payload: payload),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
            id: 'start_item',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'item',
            kind: SceneEdgeKind.defaultFlow),
        if (condition) ...[
          SceneEdge(
              id: 'item_true',
              fromNodeId: 'item',
              fromPortId: 'true',
              toNodeId: 'end',
              kind: SceneEdgeKind.conditionTrue),
          SceneEdge(
              id: 'item_false',
              fromNodeId: 'item',
              fromPortId: 'false',
              toNodeId: 'end',
              kind: SceneEdgeKind.conditionFalse),
        ] else
          for (final port in kind == 'interactive'
              ? const ['received', 'bagFull']
              : const ['completed'])
            SceneEdge(
                id: 'item_$port',
                fromNodeId: 'item',
                fromPortId: port,
                toNodeId: 'end',
                kind: SceneEdgeKind.actionCompleted),
      ],
    ),
    layout: SceneGraphLayout(nodeLayouts: [
      SceneNodeLayout(nodeId: 'start', x: 0, y: 0),
      SceneNodeLayout(nodeId: 'item', x: 200, y: 0),
      SceneNodeLayout(nodeId: 'end', x: 400, y: 0),
    ]),
  );
}
