import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final expected in [true, false]) {
    test(
      'trainer condition authoring and dependency use a canonical trainer $expected',
      () {
        final scene = _scene();
        final source = SceneConditionSource(
          sourceKind: SceneConditionSourceKind.trainerDefeated,
          sourceId: 'clair',
          operator: expected
              ? SceneConditionOperator.isTrue
              : SceneConditionOperator.isFalse,
        );
        expect(SceneConditionSource.fromJson(source.toJson()), source);
        final changed = updateSceneConditionSource(
          scene,
          nodeId: 'condition',
          source: source,
        ).updatedScene;
        final project = ProjectManifest(
          name: 'Johto',
          maps: [],
          tilesets: [],
          trainers: const [
            ProjectTrainerEntry(
              id: 'clair',
              name: 'Sandra',
              trainerClass: 'Championne',
            ),
          ],
          scenes: [changed],
        );
        expect(
          diagnoseSceneAgainstProject(changed, project).hasErrors,
          isFalse,
        );
        final usages = buildNarrativeDependencyIndex(
          project: project,
        ).usages.where((usage) => usage.target.sourceKind == 'battle');
        expect(usages.single.target.id, 'trainer:clair');
        expect(
          usages.single.resolution,
          NarrativeDependencyResolution.resolved,
        );
        expect(project.facts, isEmpty);
        for (final trainers in <List<ProjectTrainerEntry>>[
          [],
          [project.trainers.single, project.trainers.single],
          [
            project.trainers.single.copyWith(tags: ['static-encounter']),
          ],
        ]) {
          final invalid = diagnoseSceneAgainstProject(
            changed,
            project.copyWith(trainers: trainers),
          );
          expect(
            invalid.diagnostics.any(
              (diagnostic) =>
                  diagnostic.code.name == 'conditionTrainerRefUnknown',
            ),
            isTrue,
          );
        }
      },
    );
  }
  for (final patch in <Map<String, dynamic>>[
    {'sourceId': ' clair'},
    {'sourceId': 'clair '},
    {'sourceId': ''},
    {'operator': 'equals', 'value': 'true'},
    {'field': 'victory'},
    {'value': 'true'},
    {'mapId': 'map'},
    {'key': 'A'},
    {'factOperator': 'equals', 'factValueType': 'boolean', 'factValue': true},
    {'unknown': true},
  ]) {
    test('trainer condition refuses incompatible fields $patch', () {
      expect(
        () => SceneConditionSource.fromJson({
          'sourceKind': 'trainerDefeated',
          'sourceId': 'clair',
          'operator': 'isTrue',
          ...patch,
        }),
        throwsFormatException,
      );
    });
  }
  test('direct construction rejects incompatible trainer fields', () {
    expect(
      () => SceneConditionSource(
        sourceKind: SceneConditionSourceKind.trainerDefeated,
        sourceId: 'clair',
        operator: SceneConditionOperator.equals,
        value: 'true',
      ),
      throwsArgumentError,
    );
  });
}

SceneAsset _scene() => SceneAsset(
  id: 'badge',
  name: 'Sandra vaincue',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'condition',
        kind: SceneNodeKind.condition,
        payload: SceneConditionPayload(
          conditionSource: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.trainerDefeated,
            sourceId: 'clair',
            operator: SceneConditionOperator.isTrue,
            label: 'Sandra vaincue',
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
