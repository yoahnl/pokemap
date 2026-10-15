import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final direction in EntityFacing.values) {
    for (final expected in [true, false]) {
      test(
        'player facing ${direction.name} expected $expected round trips',
        () {
          final source = SceneConditionSource.playerFacing(
            direction: direction,
            expected: expected,
          );
          expect(source.sourceKind, SceneConditionSourceKind.playerFacing);
          expect(source.sourceId, direction.name);
          expect(source.playerFacingDirection, direction);
          expect(
            source.operator,
            expected
                ? SceneConditionOperator.isTrue
                : SceneConditionOperator.isFalse,
          );
          expect(
            SceneConditionSource.fromJson(source.toJson()).toJson(),
            source.toJson(),
          );
        },
      );
    }
  }

  for (final patch in <Map<String, dynamic>>[
    {'sourceId': 'North'},
    {'sourceId': ' north'},
    {'sourceId': 'diagonal'},
    {'operator': 'equals', 'value': 'north'},
    {'field': 'direction'},
    {'mapId': 'map'},
    {'key': 'A'},
    {'factOperator': 'equals', 'factValueType': 'boolean', 'factValue': true},
    {'unknown': true},
  ]) {
    test('rejects malformed facing condition $patch', () {
      expect(
        () => SceneConditionSource.fromJson({
          'sourceKind': 'playerFacing',
          'sourceId': 'north',
          'operator': 'isTrue',
          ...patch,
        }),
        throwsFormatException,
      );
    });
  }

  test('direct constructor also rejects a nonboolean facing condition', () {
    expect(
      () => SceneConditionSource(
        sourceKind: SceneConditionSourceKind.playerFacing,
        sourceId: 'north',
        operator: SceneConditionOperator.equals,
        value: 'north',
      ),
      throwsArgumentError,
    );
  });

  test('other conditions do not expose a facing direction', () {
    final other = SceneConditionSource(
      sourceKind: SceneConditionSourceKind.factLikeStoryFlag,
      sourceId: 'north',
      operator: SceneConditionOperator.isTrue,
    );
    expect(other.playerFacingDirection, isNull);
  });
}
