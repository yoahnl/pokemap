import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('badge conditions serialize without a shadow progression fact', () {
    final source = SceneConditionSource.fromJson({
      'sourceKind': 'badge',
      'sourceId': 'mineral',
      'operator': 'isTrue',
    });
    expect(source.sourceKind.name, 'badge');
    expect(SceneConditionSource.fromJson(source.toJson()), source);
    expect(source.factOperator, isNull);
    expect(source.expectedFactValue, isNull);
  });

  for (final kind in ['badgeOwned', 'badgeNotOwned']) {
    test('NPC $kind predicate round-trips the canonical badge reference', () {
      final predicate = MapEntityRuntimePredicate.fromJson({
        'kind': kind,
        'refId': 'mineral',
      });
      expect(predicate.kind.name, kind);
      expect(MapEntityRuntimePredicate.fromJson(predicate.toJson()), predicate);
    });
  }

  test('badge authoring validates the project badge reference', () {
    final scene = _scene();
    final known = ProjectManifest(
      name: 'Johto',
      maps: const [],
      tilesets: const [],
      badges: const [BadgeDefinition(id: 'mineral', label: 'Badge Mineral')],
      scenes: [scene],
    );
    expect(diagnoseSceneAgainstProject(scene, known).hasErrors, isFalse);
    expect(
      diagnoseSceneAgainstProject(
        scene,
        known.copyWith(badges: []),
      ).byCode(SceneDiagnosticCode.conditionBadgeRefUnknown),
      hasLength(1),
    );
    final updated = updateSceneConditionSource(
      scene,
      nodeId: 'condition',
      source: SceneConditionSource(
        sourceKind: SceneConditionSourceKind.badge,
        sourceId: 'mineral',
        operator: SceneConditionOperator.isFalse,
      ),
    );
    expect(
      updated.updatedPayload.conditionSource!.badgeOwnershipExpected,
      isFalse,
    );
    expect(
      () => updateSceneConditionSource(
        scene,
        nodeId: 'condition',
        source: SceneConditionSource(
          sourceKind: SceneConditionSourceKind.badge,
          sourceId: 'mineral',
          operator: SceneConditionOperator.equals,
          value: 'true',
        ),
      ),
      throwsArgumentError,
    );
    final dependencies = buildNarrativeDependencyIndex(project: known);
    expect(
      dependencies.usages
          .where(
            (usage) => usage.target.kind == NarrativeDependencyTargetKind.badge,
          )
          .map((usage) => usage.target.id),
      contains('mineral'),
    );
  });
}

SceneAsset _scene() => SceneAsset(
  id: 'badge',
  name: 'Badge Mineral',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'condition',
        kind: SceneNodeKind.condition,
        payload: SceneConditionPayload(
          conditionSource: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.badge,
            sourceId: 'mineral',
            operator: SceneConditionOperator.isTrue,
            label: 'Badge Mineral',
          ),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'start_condition',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'condition',
        kind: SceneEdgeKind.defaultFlow,
      ),
      for (final value in [true, false])
        SceneEdge(
          id: 'condition_$value',
          fromNodeId: 'condition',
          fromPortId: value.toString(),
          toNodeId: 'end',
          kind: value
              ? SceneEdgeKind.conditionTrue
              : SceneEdgeKind.conditionFalse,
        ),
    ],
  ),
  layout: SceneGraphLayout(nodeLayouts: const []),
  declaredOutcomes: const [],
);
