import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_contextual_capture.dart';
import 'package:map_runtime/src/application/runtime_pokemon_species_loader.dart';

void main() {
  test('historical profile and forged item policy fail before metadata lookup', () {
    final policy = ProjectContextualCapturePolicy(successEffects: [ProjectCaptureSetFriendship(200)]);
    for (final profile in [PokemonRulesetProfile.pokeMapBetaV1, PokemonRulesetProfile.standardV1]) {
      expect(() => prepareRuntimeBattleCapture(choice: PlayerBattleChoiceCapture(contextualPolicy: policy),
        battleState: _state(), ruleset: profile), throwsStateError);
    }
    final canonical = ProjectCaptureItemDefinition(rateNumerator: 1, rateDenominator: 1,
        allowedEncounterKinds: {EncounterKind.walk}, contextualPolicy: policy);
    expect(() => prepareRuntimeBattleCapture(
      choice: PlayerBattleChoiceCapture(contextualPolicy: ProjectContextualCapturePolicy()),
      battleState: _state(), ruleset: PokemonRulesetProfile.contextualV1,
      canonicalCapture: canonical), throwsStateError);
    expect(() => prepareRuntimeBattleCapture(
      choice: PlayerBattleChoiceCapture(contextualPolicy: policy, captureContext: BattleCaptureContext()),
      battleState: _state(), ruleset: PokemonRulesetProfile.contextualV1,
      canonicalCapture: canonical), throwsStateError);
  });
  test(
    'preparation uses current species and typing but original individual sexes',
    () {
      final species = <String, RuntimePokemonSpecies>{'current': _species()};
      final source = RuntimeCaptureProvenance(
        speciesById: species,
        playerSexesByLineupIndex: {0: 'male', 1: 'female'},
        targetSex: 'male',
        encounterKind: EncounterKind.superRod,
      );
      species.clear();
      final prepared = prepareRuntimeBattleCapture(
        choice: PlayerBattleChoiceCapture(
          contextualPolicy: ProjectContextualCapturePolicy(rateRules: []),
        ),
        battleState: _state(),
        ruleset: PokemonRulesetProfile.contextualV1,
        provenance: source,
      );
      final context = prepared.choice.captureContext!;
      expect(context.targetSpecies, 'current');
      expect(context.targetTypes, {'water', 'flying'});
      expect(context.targetBaseSpeed, 101);
      expect(context.targetWeightDecikilograms, 999);
      expect(context.targetBaseCatchRate, 190);
      expect(context.attackerSex, BattleCaptureSex.female);
      expect(context.targetSex, BattleCaptureSex.male);
      expect(context.encounterOrigin, ProjectCaptureEncounterOrigin.fishing);
      expect(context.targetEvolutionItemIds, isNull);
    },
  );

  test('unknown gender remains unknown and known empty evolution data remains empty', () {
    final source = RuntimeCaptureProvenance(
      speciesById: {'current': _species()},
      playerSexesByLineupIndex: {1: null},
      targetSex: 'genderless',
      encounterKind: EncounterKind.walk,
      targetEvolutionItemIdsBySpecies: {'current': {}},
    );
    final prepared = prepareRuntimeBattleCapture(
      choice: PlayerBattleChoiceCapture(
        contextualPolicy: ProjectContextualCapturePolicy(rateRules: []),
      ),
      battleState: _state(),
      ruleset: PokemonRulesetProfile.contextualV1,
      provenance: source,
    );
    expect(prepared.choice.captureContext!.attackerSex, isNull);
    expect(
      prepared.choice.captureContext!.targetSex,
      BattleCaptureSex.genderless,
    );
    expect(prepared.choice.captureContext!.targetEvolutionItemIds, isEmpty);
  });

  test('current species metadata and requested optional fields fail before submission', () {
    for (final source in [
      null,
      RuntimeCaptureProvenance(
        speciesById: {},
        playerSexesByLineupIndex: {},
        targetSex: null,
        encounterKind: EncounterKind.walk,
      ),
    ]) {
      expect(
        () => prepareRuntimeBattleCapture(
          choice: PlayerBattleChoiceCapture(
            contextualPolicy: ProjectContextualCapturePolicy(rateRules: []),
          ),
          battleState: _state(),
          ruleset: PokemonRulesetProfile.contextualV1,
          provenance: source,
        ),
        throwsStateError,
      );
    }
  });

  test('unrepresentable optional mass does not block Friend but fails a Heavy policy', () {
    final source = RuntimeCaptureProvenance(
      speciesById: {'current': _species(weightKg: 99.91)},
      playerSexesByLineupIndex: {},
      targetSex: null,
      encounterKind: EncounterKind.walk,
    );
    final friend = ProjectContextualCapturePolicy(
      rateRules: [],
      successEffects: [ProjectCaptureSetFriendship(200)],
    );
    expect(
      prepareRuntimeBattleCapture(
        choice: PlayerBattleChoiceCapture(contextualPolicy: friend),
        battleState: _state(),
        ruleset: PokemonRulesetProfile.contextualV1,
        provenance: source,
      ).choice.captureContext!.targetWeightDecikilograms,
      isNull,
    );
    final heavy = ProjectContextualCapturePolicy(
      rateRules: [
        ProjectCaptureRateRule(
          when: ProjectCaptureNumericCondition(
            left: ProjectCaptureIntegerOperand.field(
              ProjectCaptureNumericField.targetWeightDecikilograms,
            ),
            comparison: ProjectCaptureComparison.lessThan,
            right: ProjectCaptureIntegerOperand.literal(1000),
          ),
          adjustment: ProjectCaptureRateAdd(-20),
        ),
      ],
    );
    expect(
      () => prepareRuntimeBattleCapture(
        choice: PlayerBattleChoiceCapture(contextualPolicy: heavy),
        battleState: _state(),
        ruleset: PokemonRulesetProfile.contextualV1,
        provenance: source,
      ),
      throwsA(isA<BattleCaptureMissingContext>()),
    );
  });

  test('mass conversion is exact at Heavy thresholds and rejects fractional decikilograms', () {
    for (final value in <double, int>{
      0: 0,
      0.1: 1,
      99.9: 999,
      100: 1000,
      199.9: 1999,
      200: 2000,
      300: 3000,
      0.7: 7,
    }.entries) {
      expect(runtimeCaptureWeightDecikilograms(value.key), value.value);
    }
    expect(runtimeCaptureWeightDecikilograms(null), isNull);
    for (final value in [
      99.91,
      -1.0,
      double.nan,
      double.infinity,
      214748364.8,
    ]) {
      expect(() => runtimeCaptureWeightDecikilograms(value), throwsStateError);
    }
  });

  test('requested absent evolution metadata fails but an explicitly loaded empty set is valid', () {
    final policy = ProjectContextualCapturePolicy(
      rateRules: [
        ProjectCaptureRateRule(
          when: ProjectCaptureMatchCondition(
            field: ProjectCaptureMatchField.targetEvolutionItemIds,
            values: {'moon-stone'},
          ),
          adjustment: ProjectCaptureRateAdd(1),
        ),
      ],
    );
    for (final known in [false, true]) {
      final source = RuntimeCaptureProvenance(
        speciesById: {'current': _species()},
        playerSexesByLineupIndex: {},
        targetSex: null,
        encounterKind: EncounterKind.walk,
        targetEvolutionItemIdsBySpecies: known ? {'current': {}} : null,
      );
      RuntimePreparedBattleCapture prepare() => prepareRuntimeBattleCapture(
        choice: PlayerBattleChoiceCapture(contextualPolicy: policy),
        battleState: _state(),
        ruleset: PokemonRulesetProfile.contextualV1,
        provenance: source,
      );
      if (known) {
        expect(
          prepare().choice.captureContext!.targetEvolutionItemIds,
          isEmpty,
        );
      } else {
        expect(
          prepare,
          throwsA(
            isA<BattleCaptureMissingContext>().having(
              (error) => error.field,
              'field',
              BattleCaptureContextField.targetEvolutionItemIds,
            ),
          ),
        );
      }
    }
  });

  test('form-specific species metadata cannot silently stand in for HGSS base species data', () {
    final species = _species(isBaseForm: false);
    expect(
      () => prepareRuntimeBattleCapture(
        choice: PlayerBattleChoiceCapture(
          contextualPolicy: ProjectContextualCapturePolicy(rateRules: []),
        ),
        battleState: _state(),
        ruleset: PokemonRulesetProfile.contextualV1,
        provenance: RuntimeCaptureProvenance(
          speciesById: {'current': species},
          playerSexesByLineupIndex: {},
          targetSex: null,
          encounterKind: EncounterKind.walk,
        ),
      ),
      throwsStateError,
    );
  });

  test('MVP preparation leaves choice and context untouched', () {
    const choice = PlayerBattleChoiceCapture();
    final prepared = prepareRuntimeBattleCapture(
      choice: choice,
      battleState: _state(),
      ruleset: PokemonRulesetProfile.contextualV1,
    );
    expect(identical(prepared.choice, choice), isTrue);
    expect(prepared.choice.captureContext, isNull);
  });
}

RuntimePokemonSpecies _species({
  bool isBaseForm = true,
  double? weightKg = 99.9,
}) => RuntimePokemonSpecies(
  id: 'current',
  isBaseForm: isBaseForm,
  typing: ['normal'],
  baseHp: 40,
  baseAttack: 40,
  baseDefense: 40,
  baseSpecialAttack: 40,
  baseSpecialDefense: 40,
  baseSpeed: 101,
  primaryAbilityId: 'none',
  abilityIds: ['none'],
  learnsetRef: '',
  growthRateId: 'medium_fast',
  baseExp: 50,
  catchRate: 190,
  weightKg: weightKg,
);

BattleState _state() => BattleState(
  phase: BattlePhase.playerChoice,
  player: BattleCombatant(
    speciesId: 'attacker-current',
    lineupIndex: 1,
    level: 40,
    currentHp: 40,
    maxHp: 40,
    stats: _stats,
    moves: [],
  ),
  enemy: BattleCombatant(
    speciesId: 'current',
    writeBackSpeciesId: 'original',
    level: 10,
    currentHp: 40,
    maxHp: 40,
    catchRate: 1,
    stats: _stats,
    typing: BattleTypingSnapshot(primaryType: 'water', secondaryType: 'flying'),
    moves: [],
  ),
);
const _stats = BattleStatsSnapshot(
  attack: 1,
  defense: 1,
  specialAttack: 1,
  specialDefense: 1,
  speed: 999,
);
