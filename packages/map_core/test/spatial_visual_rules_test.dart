import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'visual rules use canonical facts, field priorities, and restore inheritance',
    () {
      WorldRuleDefinition rule(
        String id,
        int priority,
        Map<String, dynamic> values,
      ) => WorldRuleDefinition(
        id: id,
        label: id,
        priority: priority,
        source: const WorldRuleSource(
          kind: WorldRuleSourceKind.fact,
          sourceId: 'storm',
          predicate: WorldRuleSourcePredicate.isTrue,
        ),
        target: const WorldRuleTarget(
          kind: WorldRuleTargetKind.atmosphere,
          mapId: 'village',
        ),
        effect: WorldRuleEffect(
          kind: WorldRuleEffectKind.atmosphere,
          visualSettings: SpatialVisualPatch.fromJson(values),
        ),
      );
      final project = ProjectManifest(
        name: 'Generic',
        tilesets: [],
        maps: [
          const ProjectMapEntry(
            id: 'village',
            name: 'Village',
            relativePath: 'maps/village.json',
          ),
        ],
        facts: [NarrativeFactDefinition(id: 'storm', label: 'Storm')],
        worldRules: [
          rule('base', 0, {'fogOpacity': .2, 'halosEnabled': true, 'weatherSoundEnabled': true, 'weatherRainVolume': .8}),
          rule('higher', 2, {'fogOpacity': .4}),
        ],
      );
      expect(SpatialWeatherCapabilities.requiresProject(project), isTrue);
      expect(SpatialWeatherCapabilities.requiresSoundProject(project), isTrue);
      final resolver = SpatialVisualRuleResolver(project);
      final active = GameState(
        saveId: 'save',
        storyFlags: const StoryFlags(activeFlags: {'storm'}),
      );
      final patch = resolver.resolve(active, 'village');
      expect(patch.number(SpatialVisualParameter.fogOpacity), .4);
      expect(patch.enabled(SpatialVisualParameter.halosEnabled), isTrue);
      expect(resolver.resolve(active, 'village'), same(patch));
      expect(resolver.resolve(active, 'another').isEmpty, isTrue);
      expect(
        resolver.resolve(GameState(saveId: 'save'), 'village').isEmpty,
        isTrue,
      );
      expect(
        WorldRuleDefinition.fromJson(project.worldRules.first.toJson()),
        project.worldRules.first,
      );
    },
  );
  test(
    'visual rules merge disjoint fields and reject opposed fields at equal priority',
    () {
      WorldRuleDefinition rule(String id, Map<String, dynamic> values) =>
          WorldRuleDefinition(
            id: id,
            label: id,
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.fact,
              sourceId: 'storm',
              predicate: WorldRuleSourcePredicate.isTrue,
            ),
            target: const WorldRuleTarget(
              kind: WorldRuleTargetKind.atmosphere,
              mapId: 'village',
            ),
            effect: WorldRuleEffect(
              kind: WorldRuleEffectKind.atmosphere,
              visualSettings: SpatialVisualPatch.fromJson(values),
            ),
          );
      final project = ProjectManifest(
        name: 'Generic',
        tilesets: [],
        maps: [
          const ProjectMapEntry(
            id: 'village',
            name: 'Village',
            relativePath: 'maps/village.json',
          ),
        ],
        facts: [NarrativeFactDefinition(id: 'storm', label: 'Storm')],
        worldRules: [
          rule('fog', {'fogOpacity': .2}),
          rule('light', {'halosEnabled': true}),
        ],
      );
      final active = GameState(
        saveId: 'save',
        storyFlags: const StoryFlags(activeFlags: {'storm'}),
      );
      final combined = SpatialVisualRuleResolver(
        project,
      ).resolve(active, 'village');
      expect(combined.number(SpatialVisualParameter.fogOpacity), .2);
      expect(combined.enabled(SpatialVisualParameter.halosEnabled), isTrue);
      final compatibleSequences = project.copyWith(worldRules: [
        rule('one', {'weatherSequence': ['clear', 'rain'], 'timeMode': 'real'}),
        rule('two', {'weatherSequence': ['clear', 'rain'], 'weatherMode': 'automatic'}),
      ]);
      expect(diagnoseWorldRules(compatibleSequences).byCode(WorldRuleDiagnosticCode.worldRuleConflict), isEmpty);
      expect(WorldEnvironmentCapabilities.requiresProject(compatibleSequences), isTrue);
      final opposed = project.copyWith(
        worldRules: [
          project.worldRules.first,
          rule('opposed', {'fogOpacity': .4}),
        ],
      );
      expect(
        diagnoseWorldRules(
          opposed,
        ).byCode(WorldRuleDiagnosticCode.worldRuleConflict),
        hasLength(2),
      );
      expect(
        SpatialVisualRuleResolver(opposed).resolve(active, 'village').isEmpty,
        isTrue,
      );
    },
  );
  test(
    'cinematic preview samples chained transitions at exact playhead times',
    () {
      final base = SpatialVisualPatch.fromJson({'haloStrength': .4});
      final initial = CinematicAsset(
        id: 'preview',
        title: 'Preview',
        mapId: 'village',
        timeline: CinematicTimeline(steps: []),
      );
      final first = addCinematicTimelineCommandStep(
        initial,
        kind: CinematicTimelineStepKind.atmosphere,
        durationMs: 1000,
        visualSettings: SpatialVisualPatch.fromJson({'haloStrength': 1.4}),
      ).cinematic;
      final cinematic = addCinematicTimelineCommandStep(
        first,
        kind: CinematicTimelineStepKind.atmosphere,
        durationMs: 1000,
        visualSettings: SpatialVisualPatch.fromJson({'haloStrength': .6}),
      ).cinematic;
      double? value(int elapsed) => sampleCinematicVisualProfile(
        cinematic: cinematic,
        base: base,
        elapsedMs: elapsed,
      ).number(SpatialVisualParameter.haloStrength);
      expect(value(0), .4);
      expect(value(500), closeTo(.9, 1e-9));
      expect(value(1000), closeTo(1.4, 1e-9));
      expect(value(1500), closeTo(1, 1e-9));
      expect(value(2000), closeTo(.6, 1e-9));
      expect(value(500), closeTo(.9, 1e-9));
    },
  );
  test(
    'scene atmosphere has typed strict payload and canonical command builder',
    () {
      final patch = SpatialVisualPatch.fromJson({
        'depthOfFieldEnabled': true,
        'depthOfFieldStrength': .65,
        'weatherSoundEnabled': true,
        'weatherRainVolume': .8,
        'weatherWindVolume': .4,
        'timeMode': 'fixed',
        'minuteOfDay': 1320,
        'weatherMode': 'automatic',
        'weatherSequence': ['clear', 'rain'],
      });
      final command = SceneInteractiveCommand.worldPresentation(
        operation: SceneWorldPresentationOperation.atmosphere,
        visualSettings: patch,
        scope: SceneVisualScope.scene,
        durationMs: 1000,
        waitForCompletion: true,
      );
      expect(SceneInteractiveCommand.fromJson(command.toJson()), command);
      expect(
        command.hashCode,
        SceneInteractiveCommand.fromJson(command.toJson()).hashCode,
      );
      expect(
        () => SceneInteractiveCommand.worldPresentation(
          operation: SceneWorldPresentationOperation.atmosphere,
        ),
        throwsArgumentError,
      );
      expect(
        () => SceneInteractiveCommand.worldPresentation(
          operation: SceneWorldPresentationOperation.flash,
          visualSettings: patch,
        ),
        throwsArgumentError,
      );
      final payload = buildScenePayloadForNarrativeCommand(
        commandId: NarrativeCommandIds.worldPresentation,
        parameters: {
          'operation': 'atmosphere',
          'scope': 'scene',
          'waitForCompletion': 'true',
          'visualSettings': '{"timeMode":"fixed","minuteOfDay":1320,"weatherMode":"fixed","weatherKind":"storm"}',
          'durationMs': '500',
        },
      );
      expect(
        (payload as SceneActionPayload).interactiveCommand,
        isA<SceneWorldPresentationInteractiveCommand>(),
      );
      expect(
        SpatialGameplayCapabilities.cinematicStepKinds,
        contains(CinematicTimelineStepKind.atmosphere),
      );
    },
  );
  test(
    'cinematic authoring preserves settings through duration edit and round trip',
    () {
      final asset = CinematicAsset(
        id: 'cinematic',
        title: 'Light',
        mapId: 'village',
        timeline: CinematicTimeline(steps: []),
      );
      final added = addCinematicTimelineCommandStep(
        asset,
        kind: CinematicTimelineStepKind.atmosphere,
        durationMs: 1000,
        visualSettings: SpatialVisualPatch.fromJson({'haloStrength': 1.4, 'timeMode': 'fixed', 'minuteOfDay': 1320, 'weatherMode': 'fixed', 'weatherKind': 'storm'}),
      );
      final edited = updateCinematicTimelineCommandStep(
        added.cinematic,
        stepId: added.step.id,
        durationMs: 2000,
      ).cinematic;
      expect(
        edited.timeline.steps.single.visualSettings,
        added.step.visualSettings,
      );
      expect(CinematicAsset.fromJson(edited.toJson()), edited);
      expect(cinematicCommandPublicationBlockers(edited), isEmpty);
    },
  );
}
