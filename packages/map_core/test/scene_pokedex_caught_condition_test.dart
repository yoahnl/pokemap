import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final dimension in ProjectDimension.values) {
    test('caught species condition is executable only in 2D ($dimension)', () {
      final scene = SceneAsset(
        id: 'caught',
        name: 'Caught species',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'count',
              kind: SceneNodeKind.condition,
              payload: SceneConditionPayload(
                conditionSource: SceneConditionSource.pokedexCaughtAtLeast(
                  range: PokedexSpeciesRange(
                    firstNationalDex: 1,
                    lastNationalDex: 151,
                  ),
                  minimum: 20,
                ),
              ),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'enter',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'count',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'yes',
              fromNodeId: 'count',
              fromPortId: 'true',
              toNodeId: 'end',
              kind: SceneEdgeKind.conditionTrue,
            ),
            SceneEdge(
              id: 'no',
              fromNodeId: 'count',
              fromPortId: 'false',
              toNodeId: 'end',
              kind: SceneEdgeKind.conditionFalse,
            ),
          ],
        ),
      );
      final project = ProjectManifest(
        name: 'Caught species',
        maps: [],
        tilesets: [],
        settings: ProjectSettings(dimension: dimension),
        scenes: [scene],
      );
      final report = diagnoseSceneAgainstProject(scene, project);
      expect(report.hasErrors, dimension != ProjectDimension.twoD);
      expect(
        report.diagnostics.any(
          (value) => value.code.name == 'conditionUnsupportedDimension',
        ),
        dimension != ProjectDimension.twoD,
      );
    });
  }

  test(
    'native caught species condition round-trips its bounded national range',
    () {
      final json = <String, dynamic>{
        'sourceKind': 'pokedexCaughtCount',
        'sourceId': 'national:1:151',
        'operator': 'isTrue',
        'field': 'minimumCount',
        'value': '20',
      };
      final source = SceneConditionSource.fromJson(json);
      expect(source.toJson(), json);
      expect(source.sourceKind.name, 'pokedexCaughtCount');
    },
  );
  test('typed range and condition expose one canonical query and token', () {
    final range = PokedexSpeciesRange(
      firstNationalDex: 1,
      lastNationalDex: 151,
    );
    expect(range.key, 'national:1:151');
    expect(PokedexSpeciesRange.tryFromKey(range.key), range);
    expect(
      PokedexSpeciesRange.tryFromDialogueVariableName(
        range.dialogueVariableName,
      ),
      range,
    );
    expect(range.dialoguePlaceholder, '{{ pokedex_caught_national_1_151 }}');
    for (final expected in [true, false]) {
      final source = SceneConditionSource.pokedexCaughtAtLeast(
        range: range,
        minimum: 20,
        expected: expected,
      );
      expect(source.pokedexSpeciesRange, range);
      expect(source.pokedexMinimumCaughtCount, 20);
      expect(
        source.operator,
        expected
            ? SceneConditionOperator.isTrue
            : SceneConditionOperator.isFalse,
      );
      expect(SceneConditionSource.fromJson(source.toJson()), source);
    }
  });

  for (final change in <String, Object?>{
    'sourceId': 'national:151:1',
    'value': '020',
    'operator': 'equals',
    'field': 'unknown',
    'mapId': 'map',
    'unexpected': true,
  }.entries) {
    test('strict count wire rejects ${change.key}', () {
      expect(
        () => SceneConditionSource.fromJson({
          'sourceKind': 'pokedexCaughtCount',
          'sourceId': 'national:1:151',
          'operator': 'isTrue',
          'field': 'minimumCount',
          'value': '20',
          change.key: change.value,
        }),
        throwsFormatException,
      );
    });
  }

  test(
    'minimum count rejects noncanonical and out of range decimal values',
    () {
      for (final value in ['0', '-1', '65536', '20\n', ' 20', '20 ', '1.0']) {
        expect(
          () => SceneConditionSource.fromJson({
            'sourceKind': 'pokedexCaughtCount',
            'sourceId': 'national:1:151',
            'operator': 'isTrue',
            'field': 'minimumCount',
            'value': value,
          }),
          throwsFormatException,
        );
      }
    },
  );

  test('range bounds, decimal spelling and unknown scopes are refused', () {
    for (final range in [
      'national:0:151',
      'national:01:151',
      'national:1:65536',
      'region:1:151',
      'national:1:151:extra',
      'national:1:151\n',
    ]) {
      expect(PokedexSpeciesRange.tryFromKey(range), isNull);
    }
    for (final pair in [(0, 151), (151, 1), (1, 65536)]) {
      expect(
        () => PokedexSpeciesRange(
          firstNationalDex: pair.$1,
          lastNationalDex: pair.$2,
        ),
        throwsArgumentError,
      );
    }
  });
}
