import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('party move diagnostics distinguish an unavailable catalog', () {
    final scene = updateSceneConditionSource(
      _scene(),
      nodeId: 'condition',
      source: SceneConditionSource.partyKnowsMove(moveId: 'synthetic_move'),
    ).updatedScene;
    final project = ProjectManifest(
      name: 'Party fixture',
      maps: [],
      tilesets: [],
      scenes: [scene],
    );
    final report = diagnoseSceneAgainstProject(scene, project);
    expect(
      report.diagnostics.where(
        (value) => value.code.name == 'conditionPartyMoveCatalogUnavailable',
      ),
      hasLength(1),
    );
    expect(report.hasErrors, isFalse);
    final missing = diagnoseSceneAgainstProject(
      scene,
      project,
      availableMoveIds: {},
    );
    expect(
      missing.diagnostics.where(
        (value) => value.code.name == 'conditionPartyMoveRefUnknown',
      ),
      hasLength(1),
    );
    expect(missing.hasErrors, isTrue);
    final resolved = diagnoseSceneAgainstProject(
      scene,
      project,
      availableMoveIds: {'synthetic_move'},
    );
    expect(
      resolved.diagnostics.where(
        (value) => value.code.name.startsWith('conditionPartyMove'),
      ),
      isEmpty,
    );
    expect(resolved.hasErrors, isFalse);
  });
  for (final patch in <Map<String, dynamic>>[
    {'sourceId': 'unknown'},
    {'sourceId': ' canReceivePokemon'},
    {'operator': 'equals'},
    {'field': 'moveId'},
    {'value': 'tackle'},
    {'field': null},
    {'mapId': 'room'},
    {'key': 'A'},
    {'factOperator': 'equals', 'factValueType': 'boolean', 'factValue': true},
    {'unknown': true},
  ]) {
    test('strict party capacity JSON rejects $patch', () {
      expect(
        () => SceneConditionSource.fromJson({
          'sourceKind': 'partyState',
          'sourceId': 'canReceivePokemon',
          'operator': 'isTrue',
          ...patch,
        }),
        throwsFormatException,
      );
    });
  }
  test('direct party constructor rejects unsupported discriminator', () {
    expect(
      () => SceneConditionSource(
        sourceKind: SceneConditionSourceKind.partyState,
        sourceId: 'unknown',
        operator: SceneConditionOperator.isTrue,
      ),
      throwsArgumentError,
    );
  });
  for (final expected in [true, false]) {
    test('all typed party factories round trip expected $expected', () {
      final sources = [
        SceneConditionSource.partyCanReceivePokemon(expected: expected),
        SceneConditionSource.partyKnowsMove(
          moveId: 'synthetic_move',
          expected: expected,
        ),
        SceneConditionSource.partyHasUsableMove(
          moveId: 'synthetic_move',
          expected: expected,
        ),
        SceneConditionSource.partyCanUseFieldAbility(
          ability: FieldAbility.rockSmash,
          expected: expected,
        ),
      ];
      for (var i = 0; i < sources.length; i++) {
        final source = sources[i];
        expect(source.partyConditionKind, ScenePartyConditionKind.values[i]);
        expect(source.partyExpected, expected);
        expect(SceneConditionSource.fromJson(source.toJson()), source);
        expect(source.partyConditionKind!.label, isNotEmpty);
      }
      expect(sources[0].partyMoveId, isNull);
      expect(sources[1].partyMoveId, 'synthetic_move');
      expect(sources[2].partyMoveId, 'synthetic_move');
      expect(sources[3].partyMoveId, isNull);
      expect(sources[3].partyFieldAbility, FieldAbility.rockSmash);
      expect(sources[3].value, 'rock_smash');
    });
  }
  for (final predicate in ['knowsMove', 'hasUsableMove']) {
    for (final patch in <Map<String, dynamic>>[
      {'value': ''},
      {'value': ' move'},
      {'value': 'move '},
      {'value': null},
      {'field': 'ability'},
      {'field': ' moveId'},
      {'field': null},
      {'operator': 'equals'},
      {'mapId': 'map'},
      {'key': 'A'},
      {'factOperator': 'equals'},
      {'unexpected': true},
    ]) {
      test('$predicate rejects malformed reference $patch', () {
        expect(
          () => SceneConditionSource.fromJson({
            'sourceKind': 'partyState',
            'sourceId': predicate,
            'field': 'moveId',
            'value': 'synthetic_move',
            'operator': 'isTrue',
            ...patch,
          }),
          throwsFormatException,
        );
      });
    }
  }
  for (final value in [null, '', 'rockSmash', ' rock_smash', 'unknown']) {
    test('field ability rejects noncanonical value $value', () {
      expect(
        () => SceneConditionSource.fromJson({
          'sourceKind': 'partyState',
          'sourceId': 'canUseFieldAbility',
          'field': 'ability',
          'value': value,
          'operator': 'isTrue',
        }),
        throwsFormatException,
      );
    });
  }
  test('constructors enforce reference combinations and boolean operators', () {
    for (final kind in ScenePartyConditionKind.values) {
      expect(
        () => SceneConditionSource(
          sourceKind: SceneConditionSourceKind.partyState,
          sourceId: kind.name,
          operator: SceneConditionOperator.equals,
        ),
        throwsArgumentError,
      );
    }
    expect(
      () => SceneConditionSource.partyKnowsMove(moveId: ' bad'),
      throwsArgumentError,
    );
    expect(
      () => SceneConditionSource(
        sourceKind: SceneConditionSourceKind.partyState,
        sourceId: 'canUseFieldAbility',
        operator: SceneConditionOperator.isTrue,
        field: 'ability',
        value: 'rockSmash',
      ),
      throwsArgumentError,
    );
    final other = SceneConditionSource.playerFacing(
      direction: EntityFacing.north,
    );
    expect(other.partyConditionKind, isNull);
    expect(other.partyExpected, isNull);
    expect(other.partyMoveId, isNull);
    expect(other.partyFieldAbility, isNull);
  });
  test(
    'party conditions author and diagnose in 2D and spatial without a fake dependency',
    () {
      for (final dimension in ProjectDimension.values) {
        for (final source in [
          SceneConditionSource.partyCanReceivePokemon(),
          SceneConditionSource.partyKnowsMove(moveId: 'synthetic_move'),
          SceneConditionSource.partyHasUsableMove(moveId: 'synthetic_move'),
          SceneConditionSource.partyCanUseFieldAbility(
            ability: FieldAbility.surf,
          ),
        ]) {
          final initial = _scene();
          final before = initial.toJson();
          final changed = updateSceneConditionSource(
            initial,
            nodeId: 'condition',
            source: source,
          ).updatedScene;
          final payload =
              changed.graph.nodes[1].payload as SceneConditionPayload;
          expect(payload.conditionLabel, source.partyConditionKind!.label);
          final project = ProjectManifest(
            name: 'Party fixture',
            maps: [],
            tilesets: [],
            settings: ProjectSettings(dimension: dimension),
            scenes: [changed],
          );
          expect(
            diagnoseSceneAgainstProject(changed, project).hasErrors,
            isFalse,
          );
          expect(
            buildNarrativeDependencyIndex(project: project).usages.where(
              (usage) =>
                  usage.target.sourceKind == 'legacyCondition.partyState',
            ),
            isEmpty,
          );
          expect(
            SpatialGameplayCapabilities.conditionSources,
            contains(SceneConditionSourceKind.partyState),
          );
          expect(initial.toJson(), before);
        }
      }
    },
  );
}

SceneAsset _scene() => SceneAsset(
  id: 'party',
  name: 'Party condition fixture',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(id: 'condition', kind: SceneNodeKind.condition),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'enter',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'condition',
        kind: SceneEdgeKind.defaultFlow,
      ),
      for (final expected in [true, false])
        SceneEdge(
          id: 'condition_$expected',
          fromNodeId: 'condition',
          fromPortId: '$expected',
          toNodeId: 'end',
          kind: expected
              ? SceneEdgeKind.conditionTrue
              : SceneEdgeKind.conditionFalse,
        ),
    ],
  ),
  layout: SceneGraphLayout(nodeLayouts: []),
  declaredOutcomes: [],
);
