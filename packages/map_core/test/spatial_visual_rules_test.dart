import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('visual rules use canonical facts, field priorities, and restore inheritance', () {
    WorldRuleDefinition rule(String id, int priority, Map<String, dynamic> values) => WorldRuleDefinition(
      id: id, label: id, priority: priority,
      source: const WorldRuleSource(kind: WorldRuleSourceKind.fact, sourceId: 'storm', predicate: WorldRuleSourcePredicate.isTrue),
      target: const WorldRuleTarget(kind: WorldRuleTargetKind.atmosphere, mapId: 'village'),
      effect: WorldRuleEffect(kind: WorldRuleEffectKind.atmosphere, visualSettings: SpatialVisualPatch.fromJson(values)));
    final project = ProjectManifest(name: 'Generic', tilesets: [],
      maps: [const ProjectMapEntry(id: 'village', name: 'Village', relativePath: 'maps/village.json')],
      facts: [NarrativeFactDefinition(id: 'storm', label: 'Storm')], worldRules: [
        rule('base', 0, {'fogOpacity': .2, 'halosEnabled': true}),
        rule('higher', 2, {'fogOpacity': .4}),
      ]);
    final resolver = SpatialVisualRuleResolver(project);
    final active = GameState(saveId: 'save', storyFlags: const StoryFlags(activeFlags: {'storm'}));
    final patch = resolver.resolve(active, 'village');
    expect(patch.number(SpatialVisualParameter.fogOpacity), .4);
    expect(patch.enabled(SpatialVisualParameter.halosEnabled), isTrue);
    expect(resolver.resolve(active, 'village'), same(patch));
    expect(resolver.resolve(active, 'another').isEmpty, isTrue);
    expect(resolver.resolve(GameState(saveId: 'save'), 'village').isEmpty, isTrue);
    expect(WorldRuleDefinition.fromJson(project.worldRules.first.toJson()), project.worldRules.first);
  });
  test('scene atmosphere has typed strict payload and canonical command builder', () {
    final patch = SpatialVisualPatch.fromJson({'depthOfFieldEnabled': true, 'depthOfFieldStrength': .65});
    final command = SceneInteractiveCommand.worldPresentation(operation: SceneWorldPresentationOperation.atmosphere,
      visualSettings: patch, scope: SceneVisualScope.scene, durationMs: 1000, waitForCompletion: true);
    expect(SceneInteractiveCommand.fromJson(command.toJson()), command);
    expect(command.hashCode, SceneInteractiveCommand.fromJson(command.toJson()).hashCode);
    expect(() => SceneInteractiveCommand.worldPresentation(operation: SceneWorldPresentationOperation.atmosphere), throwsArgumentError);
    expect(() => SceneInteractiveCommand.worldPresentation(operation: SceneWorldPresentationOperation.flash, visualSettings: patch), throwsArgumentError);
    final payload = buildScenePayloadForNarrativeCommand(commandId: NarrativeCommandIds.worldPresentation,
      parameters: {'operation':'atmosphere','visualSettings':'{"fogOpacity":0.3}','durationMs':'500'});
    expect((payload as SceneActionPayload).interactiveCommand, isA<SceneWorldPresentationInteractiveCommand>());
    expect(SpatialGameplayCapabilities.supportsScenePayload(payload), isTrue);
  });
  test('cinematic authoring preserves settings through duration edit and round trip', () {
    final asset = CinematicAsset(id: 'cinematic', title: 'Light', mapId: 'village', timeline: CinematicTimeline(steps: []));
    final added = addCinematicTimelineCommandStep(asset, kind: CinematicTimelineStepKind.atmosphere,
      durationMs: 1000, visualSettings: SpatialVisualPatch.fromJson({'haloStrength': 1.4}));
    final edited = updateCinematicTimelineCommandStep(added.cinematic, stepId: added.step.id, durationMs: 2000).cinematic;
    expect(edited.timeline.steps.single.visualSettings, added.step.visualSettings);
    expect(CinematicAsset.fromJson(edited.toJson()), edited);
    expect(cinematicCommandPublicationBlockers(edited), isEmpty);
  });
}
