import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Scene item catalog diagnostics', () {
    test(
      'explains unavailable item context for every scene item reference',
      () {
        final scene = _itemScene();
        final report = diagnoseSceneAgainstProject(scene, _project(scene));

        final diagnostics = report.diagnostics
            .where(
              (diagnostic) =>
                  diagnostic.code.name.contains('ItemCatalogUnavailable'),
            )
            .toList();
        expect(diagnostics, hasLength(4));
        expect(
          diagnostics.map((diagnostic) => diagnostic.nodeId),
          unorderedEquals(['inventory', 'give', 'take', 'interactive']),
        );
        for (final diagnostic in diagnostics) {
          expect(diagnostic.severity, SceneDiagnosticSeverity.warning);
          expect(diagnostic.sceneId, scene.id);
          expect(diagnostic.target, SceneDiagnosticTarget.node);
          expect(diagnostic.message, contains('catalogue'));
          expect(diagnostic.message, contains('chargé'));
        }
      },
    );

    test(
      'project validator propagates an empty item catalog to scene checks',
      () {
        final scene = _itemScene();
        final report = validateNarrativeProject(
          _project(scene),
          maps: const [],
          knownItemIds: const {},
        );

        final diagnostics = report.diagnostics.where(
          (diagnostic) => const {
            'conditionItemRefUnknown',
            'consequenceUnknownItem',
            'commandUnknownItem',
          }.contains(diagnostic.code),
        );
        expect(diagnostics, hasLength(4));
        expect(
          diagnostics.map((diagnostic) => diagnostic.path),
          unorderedEquals([
            'scenes.scene.items.node.inventory',
            'scenes.scene.items.node.give',
            'scenes.scene.items.node.take',
            'scenes.scene.items.node.interactive',
          ]),
        );
        for (final diagnostic in diagnostics) {
          expect(diagnostic.severity, NarrativeProjectDiagnosticSeverity.error);
          expect(diagnostic.sceneId, scene.id);
        }
        expect(report.isPlayable, isFalse);
      },
    );

    test('accepts all scene references present in the loaded item catalog', () {
      final scene = _itemScene();
      final report = diagnoseSceneAgainstProject(
        scene,
        _project(scene),
        availableItemIds: const {'potion'},
      );

      expect(_itemDiagnostics(report), isEmpty);
      expect(report.hasErrors, isFalse);
    });

    for (final ids in [
      <String>{},
      {'antidote'},
    ]) {
      test('rejects all scene references absent from loaded catalog $ids', () {
        final scene = _itemScene();
        final report = diagnoseSceneAgainstProject(
          scene,
          _project(scene),
          availableItemIds: ids,
        );

        final diagnostics = _itemDiagnostics(report);
        expect(diagnostics, hasLength(4));
        expect(
          diagnostics.map((diagnostic) => diagnostic.code),
          unorderedEquals([
            SceneDiagnosticCode.conditionItemRefUnknown,
            SceneDiagnosticCode.consequenceUnknownItem,
            SceneDiagnosticCode.consequenceUnknownItem,
            SceneDiagnosticCode.commandUnknownItem,
          ]),
        );
        for (final diagnostic in diagnostics) {
          expect(diagnostic.severity, SceneDiagnosticSeverity.error);
          expect(diagnostic.message, contains('potion'));
        }
      });
    }

    test('preserves malformed item consequence shape diagnostics', () {
      final scene = _itemScene(giveItemId: ' ', takeQuantity: 0);
      final report = diagnoseSceneAgainstProject(
        scene,
        _project(scene),
        availableItemIds: const {'potion'},
      );

      expect(
        report
            .byCode(SceneDiagnosticCode.consequenceMissingTarget)
            .single
            .nodeId,
        'give',
      );
      expect(
        report
            .byCode(SceneDiagnosticCode.consequenceInvalidValue)
            .single
            .nodeId,
        'take',
      );
      expect(_itemDiagnostics(report), isEmpty);
      expect(report.hasErrors, isTrue);
    });

    test(
      'unavailable item context preserves unrelated blocking diagnostics',
      () {
        final scene = _itemScene(includeMissingFact: true);
        final report = diagnoseSceneAgainstProject(scene, _project(scene));

        expect(_itemDiagnostics(report), hasLength(4));
        final factError = report
            .byCode(SceneDiagnosticCode.consequenceUnknownFact)
            .single;
        expect(factError.nodeId, 'missing_fact');
        expect(factError.severity, SceneDiagnosticSeverity.error);
        expect(report.hasErrors, isTrue);
      },
    );

    test(
      'project validator propagates known and unavailable item contexts',
      () {
        final scene = _itemScene();
        final project = _project(scene);
        final known = validateNarrativeProject(
          project,
          maps: const [],
          knownItemIds: const {'potion'},
        );
        final unavailable = validateNarrativeProject(project, maps: const []);

        for (final code in _itemDiagnosticCodes) {
          expect(known.byCode(code.name), isEmpty);
        }
        final unavailableDiagnostics = unavailable.diagnostics.where(
          (diagnostic) => diagnostic.code.contains('ItemCatalogUnavailable'),
        );
        expect(unavailableDiagnostics, hasLength(4));
        expect(
          unavailableDiagnostics.map((diagnostic) => diagnostic.path).toSet(),
          hasLength(4),
        );
      },
    );
  });

  group('Scene item dependency context', () {
    test('indexes consequence item references at their authored paths', () {
      final scene = _itemScene();
      final index = buildNarrativeDependencyIndex(
        project: _project(scene),
        itemCatalog: const ProjectItemCatalog(schemaVersion: 1, entries: []),
      );
      final usages = _itemUsages(index);

      expect(usages, hasLength(4));
      expect(
        usages.map((usage) => usage.path),
        unorderedEquals([
          'scenes[scene.items].graph.nodes[1].payload.conditionSource.sourceId',
          'scenes[scene.items].graph.nodes[2].payload.consequence.itemId',
          'scenes[scene.items].graph.nodes[3].payload.consequence.itemId',
          'scenes[scene.items].graph.nodes[4].payload.interactiveCommand.itemId',
        ]),
      );
      for (final usage in usages) {
        expect(usage.owner, const NarrativeDependencyKey.scene('scene.items'));
        expect(usage.resolution, NarrativeDependencyResolution.missing);
        expect(
          usage.criticality,
          NarrativeDependencyCriticality.runtimeBlocking,
        );
      }
    });

    test('unloaded catalog keeps item usages blocking and unavailable', () {
      final scene = _itemScene();
      final index = buildNarrativeDependencyIndex(project: _project(scene));

      final usages = _itemUsages(index);
      expect(usages, hasLength(4));
      for (final usage in usages) {
        expect(usage.resolution, NarrativeDependencyResolution.unavailable);
        expect(
          usage.criticality,
          NarrativeDependencyCriticality.runtimeBlocking,
        );
      }
      final issues = index.issues.where(
        (issue) => issue.target.kind == NarrativeDependencyTargetKind.item,
      );
      expect(issues, hasLength(4));
      for (final issue in issues) {
        expect(issue.kind, NarrativeDependencyIssueKind.unavailableReference);
        expect(
          issue.criticality,
          NarrativeDependencyCriticality.runtimeBlocking,
        );
        expect(issue.message, contains('catalog'));
        expect(issue.message, isNot(contains('actor')));
      }
    });

    test(
      'resolves every scene item reference when the item catalog is loaded',
      () {
        final scene = _itemScene();
        final index = buildNarrativeDependencyIndex(
          project: _project(scene),
          itemCatalog: const ProjectItemCatalog(
            schemaVersion: 1,
            entries: [
              ProjectItemDefinition(
                id: 'potion',
                displayName: 'Potion',
                pocketId: 'medicine',
              ),
            ],
          ),
        );

        final usages = _itemUsages(index);
        expect(usages, hasLength(4));
        for (final usage in usages) {
          expect(usage.resolution, NarrativeDependencyResolution.resolved);
          expect(
            usage.criticality,
            NarrativeDependencyCriticality.runtimeBlocking,
          );
        }
        expect(
          index.issues.where(
            (issue) => issue.target.kind == NarrativeDependencyTargetKind.item,
          ),
          isEmpty,
        );
      },
    );

    test('unloaded item catalog preserves missing non-item blockers', () {
      final scene = _itemScene(includeMissingFact: true);
      final index = buildNarrativeDependencyIndex(project: _project(scene));
      final issue = index.issues.singleWhere(
        (issue) => issue.target.kind == NarrativeDependencyTargetKind.fact,
      );

      expect(_itemUsages(index), hasLength(4));
      expect(issue.kind, NarrativeDependencyIssueKind.missingReference);
      expect(issue.target.id, 'fact.missing');
      expect(issue.criticality, NarrativeDependencyCriticality.runtimeBlocking);
    });
  });
}

const _itemDiagnosticCodes = {
  SceneDiagnosticCode.conditionItemCatalogUnavailable,
  SceneDiagnosticCode.conditionItemRefUnknown,
  SceneDiagnosticCode.consequenceItemCatalogUnavailable,
  SceneDiagnosticCode.consequenceUnknownItem,
  SceneDiagnosticCode.commandItemCatalogUnavailable,
  SceneDiagnosticCode.commandUnknownItem,
};

List<SceneDiagnostic> _itemDiagnostics(SceneDiagnosticsReport report) => report
    .diagnostics
    .where((diagnostic) => _itemDiagnosticCodes.contains(diagnostic.code))
    .toList();

List<NarrativeDependencyUsage> _itemUsages(NarrativeDependencyIndex index) =>
    index.usages
        .where(
          (usage) => usage.target.kind == NarrativeDependencyTargetKind.item,
        )
        .toList();

ProjectManifest _project(SceneAsset scene) => ProjectManifest(
  name: 'Scene item catalog diagnostics',
  maps: const [],
  tilesets: const [],
  scenes: [scene],
);

SceneAsset _itemScene({
  String giveItemId = 'potion',
  int takeQuantity = 1,
  bool includeMissingFact = false,
}) => SceneAsset(
  id: 'scene.items',
  name: 'Item references',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'inventory',
        kind: SceneNodeKind.condition,
        payload: SceneConditionPayload(
          conditionSource: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.inventoryItem,
            sourceId: 'potion',
            operator: SceneConditionOperator.isTrue,
          ),
        ),
      ),
      SceneNode(
        id: 'give',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.giveItem(itemId: giveItemId, quantity: 1),
        ),
      ),
      SceneNode(
        id: 'take',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.takeItem(itemId: 'potion', quantity: takeQuantity),
        ),
      ),
      SceneNode(
        id: 'interactive',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.giveItem(itemId: 'potion', quantity: 1),
        ),
      ),
      if (includeMissingFact)
        SceneNode(
          id: 'missing_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: 'fact.missing', value: true),
          ),
        ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      _edge('start', 'completed', 'inventory', SceneEdgeKind.defaultFlow),
      _edge('inventory', 'true', 'give', SceneEdgeKind.conditionTrue),
      _edge('inventory', 'false', 'give', SceneEdgeKind.conditionFalse),
      _edge('give', 'completed', 'take', SceneEdgeKind.actionCompleted),
      _edge('take', 'completed', 'interactive', SceneEdgeKind.actionCompleted),
      _edge(
        'interactive',
        'received',
        includeMissingFact ? 'missing_fact' : 'end',
        SceneEdgeKind.actionCompleted,
      ),
      _edge(
        'interactive',
        'bagFull',
        includeMissingFact ? 'missing_fact' : 'end',
        SceneEdgeKind.actionCompleted,
      ),
      if (includeMissingFact)
        _edge(
          'missing_fact',
          'completed',
          'end',
          SceneEdgeKind.actionCompleted,
        ),
    ],
  ),
);

SceneEdge _edge(String from, String port, String to, SceneEdgeKind kind) =>
    SceneEdge(
      id: '$from.$port',
      fromNodeId: from,
      fromPortId: port,
      toNodeId: to,
      kind: kind,
    );
