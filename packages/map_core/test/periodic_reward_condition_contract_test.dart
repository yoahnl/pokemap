import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final reference = PeriodicRewardReference(
    sceneId: 'source',
    nodeId: 'claim',
    rewardId: 'daily',
  );
  test('reward locator has a strict versioned immutable contract', () {
    expect(reference.toJson(), {
      'schemaVersion': 1,
      'sceneId': 'source',
      'nodeId': 'claim',
      'rewardId': 'daily',
    });
    expect(PeriodicRewardReference.fromJson(reference.toJson()), reference);
    for (final patch in <Map<String, dynamic>>[
      {'schemaVersion': 2},
      {'schemaVersion': 1.0},
      {'sceneId': ''},
      {'nodeId': ' claim'},
      {'rewardId': 'daily '},
      {'extra': true},
    ]) {
      expect(
        () =>
            PeriodicRewardReference.fromJson({...reference.toJson(), ...patch}),
        throwsFormatException,
      );
    }
  });
  test('all three condition contracts preserve the same reward locator', () {
    final scene = SceneConditionSource.periodicRewardAvailable(
      reference: reference,
      expectedValue: true,
    );
    final event = NarrativeEventCondition.periodicRewardAvailable(
      reference: reference,
      expectedValue: false,
    );
    final rule = WorldRuleSource.periodicRewardAvailable(
      reference: reference,
      expectedValue: true,
    );
    expect(SceneConditionSource.fromJson(scene.toJson()), scene);
    expect(NarrativeEventCondition.fromJson(event.toJson()), event);
    expect(WorldRuleSource.fromJson(rule.toJson()), rule);
    expect(
      () => SceneConditionSource.fromJson({
        ...scene.toJson(),
        'sourceId': 'wrong',
      }),
      throwsFormatException,
    );
    expect(
      () => WorldRuleSource.fromJson({...rule.toJson(), 'sourceId': 'wrong'}),
      throwsFormatException,
    );
    expect(
      () => SceneConditionSource.fromJson({
        ...scene.toJson(),
        'operator': 'equals',
      }),
      throwsFormatException,
    );
    expect(
      () =>
          WorldRuleSource.fromJson({...rule.toJson(), 'predicate': 'consumed'}),
      throwsFormatException,
    );
  });
}
