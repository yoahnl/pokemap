import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'periodic_reward_condition_evaluation_test.dart' show rewardReference, rewardScene, rewardState;

void main() {
  final original = SpatialModelInstance(
    id: 'fruit',
    modelId: 'fruit',
    position: Model3dVector3.zero,
    entityId: 'anchor',
    blocksMovement: true,
  );
  final condition = NarrativeEventConditionExpression.leaf(
    NarrativeEventCondition.fact('picked', false),
  );

  test('instance visibility roundtrips without losing placement or binding', () {
    final wire = {...original.toJson(), 'visibilityCondition': condition.toJson()};
    final decoded = SpatialModelInstance.fromJson(wire);
    expect(decoded.toJson()['visibilityCondition'], condition.toJson());
    expect(decoded.copyWith(scale: 2).toJson()['visibilityCondition'], condition.toJson());
    expect(decoded.entityId, 'anchor');
    expect(decoded.blocksMovement, isTrue);
    expect(decoded, isNot(original));
  });

  test('unknown and malformed visibility conditions are rejected', () {
    for (final value in [false, [], {'kind': 'unknown'}]) {
      expect(() => SpatialModelInstance.fromJson({
        ...original.toJson(), 'visibilityCondition': value,
      }), throwsFormatException);
    }
  });
  test('visibility evaluates generic conditions and preserves unavailable negation', () {
    final map = MapData(id: 'garden', name: 'Garden',
      version: ProjectVersion.v9, size: const GridSize(width: 2, height: 2),
      spatialScene: MapSpatialScene(width: 2, depth: 2, instances: [
        original.copyWith(visibilityCondition: condition),
        SpatialModelInstance(id: 'bare', modelId: 'bare', position: Model3dVector3.zero),
      ]));
    final project = ProjectManifest(name: 'Test', maps: [], tilesets: [], facts: [
      NarrativeFactDefinition(id: 'picked', label: 'Picked'),
    ]);
    final projection = SpatialModelVisibilityProjection(project: project, map: map);
    expect(projection.isPresent(const GameState(saveId: 'save'), 'fruit'), isTrue);
    expect(projection.isPresent(const GameState(saveId: 'save', storyFlags: StoryFlags(activeFlags: {'picked'})), 'fruit'), isFalse);
    expect(projection.isPresent(const GameState(saveId: 'save'), 'bare'), isTrue);
    expect(projection.isPresent(const GameState(saveId: 'save'), 'absent'), isFalse);
    final unavailable = PresentationConditionContext(project: project, map: map);
    final missing = NarrativeEventConditionExpression.not(NarrativeEventConditionExpression.leaf(
      NarrativeEventCondition.fact('missing', false)));
    final result = unavailable.evaluate(missing, const GameState(saveId: 'save'));
    expect(result.passed, isFalse);
    expect(result.unavailable, isTrue);
    expect(map.spatialScene!.instances.first.blocksMovement, isTrue);
    expect(map.spatialScene!.instances.first.entityId, 'anchor');
  });

  test('periodic visibility caches selected sources across state transitions', () {
    var lookups = 0;
    final available = NarrativeEventConditionExpression.leaf(
      NarrativeEventCondition.periodicRewardAvailable(reference: rewardReference(), expectedValue: true));
    final map = MapData(id: 'garden', name: 'Garden',
      version: ProjectVersion.v9, size: const GridSize(width: 2, height: 2),
      spatialScene: MapSpatialScene(width: 2, depth: 2, instances: [
        original.copyWith(visibilityCondition: available),
      ]));
    final project = ProjectManifest(name: 'Test', maps: [], tilesets: []);
    final projection = SpatialModelVisibilityProjection(project: project, map: map,
      lookupRewardScenes: (_) { lookups++; return [rewardScene()]; });
    final full = rewardState();
    for (var i = 0; i < 100; i++) {
      expect(projection.isPresent(full, 'fruit'), isTrue);
    }
    expect(projection.isPresent(rewardState(claimed: true), 'fruit'), isFalse);
    expect(projection.isPresent(rewardState(initialized: false), 'fruit'), isFalse);
    expect(lookups, 1);
    expect(SpatialGameplayCapabilities.requiresPeriodicRewardCondition(project, maps: [map]), isTrue);
    final missing = PresentationConditionContext(project: project, map: map);
    final falseExpectation = NarrativeEventConditionExpression.leaf(
      NarrativeEventCondition.periodicRewardAvailable(reference: rewardReference(), expectedValue: false));
    expect(missing.evaluate(falseExpectation, full).unavailable, isTrue);
    expect(missing.evaluate(falseExpectation, full).passed, isFalse);
  });

  test('visibility clear, structural bounds and legacy defaults are explicit', () {
    expect(original.visibilityCondition, isNull);
    expect(original.toJson().containsKey('visibilityCondition'), isFalse);
    expect(original.copyWith(visibilityCondition: condition).copyWith(clearVisibilityCondition: true), original);
    expect(() => original.copyWith(visibilityCondition: NarrativeEventConditionExpression.any([])), throwsArgumentError);
  });

}
