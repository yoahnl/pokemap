import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const empty = GameState(saveId: 'surf-policy');
  const known = GameState(
    saveId: 'surf-policy',
    party: PlayerParty(members: [
      PlayerPokemon(
        speciesId: 'lapras',
        natureId: 'modest',
        abilityId: 'water-absorb',
        knownMoveIds: ['surf'],
      ),
    ]),
  );
  final licenseContext = ScriptEvaluationContext(
    narrativeFactResolver: NarrativeFactRuntimeResolver.fromFacts([
      NarrativeFactDefinition(
          id: 'license', label: 'License', defaultValue: true),
    ]),
  );
  const condition = ScriptCondition(
    type: ScriptConditionType.flagIsSet,
    params: {ScriptConditionParams.flagName: 'license'},
  );

  FieldActionEvaluation evaluate(
    ProjectSurfSettings? settings, {
    GameState state = empty,
    bool water = true,
    ScriptEvaluationContext? conditionContext,
  }) =>
      evaluateSurfAttempt(
        gameState: state,
        isTargetWater: water,
        surfSettings: settings,
        conditionContext: conditionContext,
      );

  test('null Surf policy preserves classic known move and progression gates',
      () {
    expect(evaluate(null), isA<MissingSurfCapablePokemon>());
    expect(evaluate(null, state: known), isA<SurfNotUnlocked>());
    expect(
      evaluate(null,
          state: known.copyWith(
            progression: const PlayerProgression(
              unlockedFieldAbilities: [FieldAbility.surf],
            ),
          )),
      isA<CanPromptSurf>(),
    );
  });

  test('disabled Surf refuses even a fully capable party', () {
    expect(evaluate(const ProjectSurfSettings(enabled: false), state: known),
        isA<SurfDisabled>());
  });

  test('always access independently retains the required known move', () {
    const settings =
        ProjectSurfSettings(accessMode: ProjectSurfAccessMode.always);
    expect(evaluate(settings), isA<MissingSurfCapablePokemon>());
    expect(evaluate(settings, state: known), isA<CanPromptSurf>());
  });

  test('always access permits an empty party when known move is disabled', () {
    expect(
        evaluate(const ProjectSurfSettings(
          requiresKnownMove: false,
          accessMode: ProjectSurfAccessMode.always,
        )),
        isA<CanPromptSurf>());
  });

  test('progression can be required without a known move', () {
    const settings = ProjectSurfSettings(requiresKnownMove: false);
    expect(evaluate(settings), isA<SurfNotUnlocked>());
    expect(
        evaluate(settings,
            state: empty.copyWith(
              progression: const PlayerProgression(
                unlockedFieldAbilities: [FieldAbility.surf],
              ),
            )),
        isA<CanPromptSurf>());
  });

  test(
      'conditional access evaluates current game state and narrative fact context',
      () {
    const settings = ProjectSurfSettings(
      requiresKnownMove: false,
      accessMode: ProjectSurfAccessMode.condition,
      condition: condition,
    );
    expect(evaluate(settings), isA<SurfNotUnlocked>());
    expect(
        evaluate(settings,
            state: empty.copyWith(
              storyFlags: const StoryFlags(activeFlags: {'license'}),
            )),
        isA<CanPromptSurf>());
    expect(evaluate(settings, conditionContext: licenseContext),
        isA<CanPromptSurf>());
  });

  test('free Surf still refuses land and redundant activation', () {
    const settings = ProjectSurfSettings(
      requiresKnownMove: false,
      accessMode: ProjectSurfAccessMode.always,
    );
    expect(evaluate(settings, water: false), isA<NotWater>());
    expect(
        evaluate(settings,
            state: empty.copyWith(
              playerMovementMode: MovementMode.surf,
            )),
        isA<AlreadySurfing>());
  });

  test('confirmation rechecks the current policy condition', () {
    const ticket = FieldActionTicket(
      ability: FieldAbility.surf,
      targetCell: GridPos(x: 1, y: 2),
      issuedAtStateRevision: 3,
    );
    const settings = ProjectSurfSettings(
      requiresKnownMove: false,
      accessMode: ProjectSurfAccessMode.condition,
      condition: condition,
    );
    FieldActionCommit commit({ScriptEvaluationContext? conditionContext}) =>
        commitFieldAction(
          ticket: ticket,
          gameState: empty,
          currentStateRevision: 3,
          confirmedTargetCell: ticket.targetCell,
          isTargetWater: true,
          surfSettings: settings,
          conditionContext: conditionContext,
        );
    expect(commit(conditionContext: licenseContext), isA<FieldActionApplied>());
    final refused = commit() as FieldActionRefused;
    expect(refused.refusal, FieldActionRefusal.noLongerAvailable);
    expect(refused.evaluation, isA<SurfNotUnlocked>());
  });
}
