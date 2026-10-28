import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const empty = GameState(saveId: 'scene-surf');
  const known = GameState(
      saveId: 'scene-surf',
      party: PlayerParty(members: [
        PlayerPokemon(
            speciesId: 'lapras',
            natureId: 'modest',
            abilityId: 'water-absorb',
            knownMoveIds: ['surf']),
      ]));
  const free = ProjectSurfSettings(
      requiresKnownMove: false, accessMode: ProjectSurfAccessMode.always);
  bool canUse(
          {ProjectSurfSettings? surf,
          GameState state = empty,
          ProjectDimension dimension = ProjectDimension.twoD,
          bool expected = true,
          Iterable<FieldAbility> supported = const [FieldAbility.surf]}) =>
      evaluateScenePartyCondition(
          source: SceneConditionSource.partyCanUseFieldAbility(
              ability: FieldAbility.surf, expected: expected),
          gameState: state,
          context: ScenePartyConditionContext(
              supportedFieldAbilities: supported,
              projectSettings:
                  ProjectSettings(dimension: dimension, surf: surf)));

  for (final dimension in ProjectDimension.values) {
    test(
        'free Surf Scene matches action policy in $dimension without terrain or party',
        () {
      expect(
          evaluateSurfAttempt(
              gameState: empty, isTargetWater: true, surfSettings: free),
          isA<CanPromptSurf>());
      expect(canUse(surf: free, dimension: dimension), isTrue);
    });
  }
  test('already surfing does not make the Scene capability condition false',
      () {
    expect(
        canUse(
            surf: free,
            state: empty.copyWith(playerMovementMode: MovementMode.surf)),
        isTrue);
  });
  test('disabled Surf remains unavailable even while a save is surfing', () {
    expect(
        canUse(
            surf: const ProjectSurfSettings(enabled: false),
            state: known.copyWith(playerMovementMode: MovementMode.surf)),
        isFalse);
  });
  test('known move and progression remain independently configurable in Scenes',
      () {
    expect(
        canUse(
            surf: const ProjectSurfSettings(
                accessMode: ProjectSurfAccessMode.always)),
        isFalse);
    expect(
        canUse(
            surf: const ProjectSurfSettings(
                accessMode: ProjectSurfAccessMode.always),
            state: known),
        isTrue);
    expect(canUse(surf: const ProjectSurfSettings(requiresKnownMove: false)),
        isFalse);
    expect(
        canUse(
            surf: const ProjectSurfSettings(requiresKnownMove: false),
            state: empty.copyWith(
                progression: const PlayerProgression(
                    unlockedFieldAbilities: [FieldAbility.surf]))),
        isTrue);
  });
  test('conditional Surf Scene evaluates current progression state', () {
    const settings = ProjectSurfSettings(
        requiresKnownMove: false,
        accessMode: ProjectSurfAccessMode.condition,
        condition: ScriptCondition(
            type: ScriptConditionType.flagIsSet,
            params: {'flagName': 'license'}));
    expect(canUse(surf: settings), isFalse);
    expect(
        canUse(
            surf: settings,
            state: empty.copyWith(
                storyFlags: const StoryFlags(activeFlags: {'license'}))),
        isTrue);
  });
  test('legacy 2D Surf Scene retains classic move and saved unlock checks', () {
    expect(canUse(), isFalse);
    expect(canUse(state: known), isFalse);
    expect(
        canUse(
            state: known.copyWith(
                progression: const PlayerProgression(
                    unlockedFieldAbilities: [FieldAbility.surf]))),
        isTrue);
  });
  test('legacy 3D has no implicit Surf support despite a fully capable save',
      () {
    expect(
        canUse(
            dimension: ProjectDimension.threeD,
            state: known.copyWith(
                progression: const PlayerProgression(
                    unlockedFieldAbilities: [FieldAbility.surf]))),
        isFalse);
  });
  test('unsupported Surf stays unavailable even with a free project policy',
      () {
    expect(canUse(surf: free, supported: []), isFalse);
  });
  test('Scene negation applies to the same Surf policy decision', () {
    expect(canUse(surf: free, expected: false), isFalse);
    expect(
        canUse(
            surf: const ProjectSurfSettings(enabled: false), expected: false),
        isTrue);
  });
  for (final licensed in [false, true]) {
    test('conditional Scene Surf reads world fact defaults licensed=$licensed',
        () {
      final context = ScriptEvaluationContext(
          narrativeFactResolver: NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(
            id: 'license', label: 'License', defaultValue: licensed),
      ]));
      final settings = ProjectSettings(
          surf: const ProjectSurfSettings(
              requiresKnownMove: false,
              accessMode: ProjectSurfAccessMode.condition,
              condition: ScriptCondition(
                  type: ScriptConditionType.flagIsSet,
                  params: {'flagName': 'license'})));
      for (final expected in [false, true]) {
        expect(
            evaluateScenePartyCondition(
                source: SceneConditionSource.partyCanUseFieldAbility(
                    ability: FieldAbility.surf, expected: expected),
                gameState: empty,
                context: ScenePartyConditionContext(
                    supportedFieldAbilities: [FieldAbility.surf],
                    projectSettings: settings,
                    conditionContext: context)),
            licensed == expected);
      }
    });
  }
}
