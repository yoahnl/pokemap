import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK clean type-aware damage', () {
    test('STAB and type effectiveness increase damage over a neutral hit', () {
      final neutral = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'fire'),
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
        playerMove: _damagingMove(
          id: 'swift',
          type: 'normal',
          category: PsdkBattleMoveCategory.special,
          power: 40,
        ),
      );
      final superEffectiveStab = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'fire'),
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
        playerMove: _damagingMove(
          id: 'ember',
          type: 'fire',
          category: PsdkBattleMoveCategory.special,
          power: 40,
        ),
      );

      expect(neutral.damageToOpponent, 8);
      expect(superEffectiveStab.damageToOpponent, 24);
      expect(superEffectiveStab.timelineKinds, contains('damage'));
    });

    test('type immunity stops before animation and damage RNG', () {
      const seeds = BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 2,
        moveAccuracy: 3,
        generic: 4,
      );
      final result = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'electric'),
        opponentTypes: const PsdkBattleTypes(primary: 'ground'),
        playerMove: _damagingMove(
          id: 'thunder_shock',
          type: 'electric',
          category: PsdkBattleMoveCategory.special,
          power: 40,
        ),
        seeds: seeds,
      );

      expect(result.damageToOpponent, 0);
      expect(result.rngSeeds.moveDamage, seeds.moveDamage);
      expect(result.timelineKinds, contains('move_immune'));
      expect(
        result.timelineEvents.where(
          (event) =>
              event.kind == 'animation_cue' &&
              event.toJson()['moveId'] == 'thunder_shock',
        ),
        isEmpty,
      );
      expect(
        result.timelineEvents.where(
          (event) =>
              event.kind == 'damage' &&
              event.toJson()['moveId'] == 'thunder_shock',
        ),
        isEmpty,
      );
    });

    test('critical rate can force a critical hit through PSDK move data', () {
      const noCriticalSeeds = BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      );
      const criticalSeeds = BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 2,
        moveAccuracy: 3,
        generic: 4,
      );
      final baseline = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'water'),
        playerMove: _damagingMove(
          id: 'tackle',
          type: 'normal',
          power: 40,
          criticalRate: 1,
        ),
        seeds: noCriticalSeeds,
      );
      final critical = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'water'),
        playerMove: _damagingMove(
          id: 'karate_chop',
          type: 'normal',
          power: 40,
          criticalRate: 4,
        ),
        seeds: criticalSeeds,
      );

      expect(critical.damageToOpponent, greaterThan(baseline.damageToOpponent));
      expect(critical.rngSeeds.moveCritical, criticalSeeds.moveCritical);
      expect(critical.rngSeeds.moveDamage, isNot(criticalSeeds.moveDamage));
    });

    test('self critical markers improve the effective critical count', () {
      const critWindowSeeds = BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 20000,
        moveAccuracy: 3,
        generic: 4,
      );
      final baseline = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'fighting'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        seeds: critWindowSeeds,
        playerMove: _damagingMove(
          id: 'karate_chop',
          type: 'fighting',
          power: 50,
        ),
      );

      final focused = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'fighting'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerEffects: _playerEffect('focus_energy'),
        seeds: critWindowSeeds,
        playerMove: _damagingMove(
          id: 'karate_chop',
          type: 'fighting',
          power: 50,
        ),
      );
      final tripleArrows = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'fighting'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerEffects: _playerEffect('triple_arrows'),
        seeds: critWindowSeeds,
        playerMove: _damagingMove(
          id: 'triple_arrows_followup',
          type: 'fighting',
          power: 50,
        ),
      );

      expect(focused.damageToOpponent, greaterThan(baseline.damageToOpponent));
      expect(
        tripleArrows.damageToOpponent,
        greaterThan(baseline.damageToOpponent),
      );
    });

    test('dragon cheer uses the PSDK dragon-type critical bonus', () {
      const critWindowSeeds = BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 20000,
        moveAccuracy: 3,
        generic: 4,
      );
      final baseline = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        seeds: critWindowSeeds,
        playerMove: _damagingMove(id: 'slash', type: 'normal', power: 50),
      );
      final cheeredNonDragon = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerEffects: _playerEffect('dragon_cheer'),
        seeds: critWindowSeeds,
        playerMove: _damagingMove(id: 'slash', type: 'normal', power: 50),
      );
      final dragonBaseline = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'dragon'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        seeds: critWindowSeeds,
        playerMove: _damagingMove(id: 'slash', type: 'normal', power: 50),
      );
      final cheeredDragon = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'dragon'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerEffects: _playerEffect('dragon_cheer'),
        seeds: critWindowSeeds,
        playerMove: _damagingMove(id: 'slash', type: 'normal', power: 50),
      );

      expect(cheeredNonDragon.damageToOpponent, baseline.damageToOpponent);
      expect(
        cheeredDragon.damageToOpponent,
        greaterThan(dragonBaseline.damageToOpponent),
      );
    });

    test('laser focus guarantees the next critical without advancing RNG', () {
      const noCriticalSeeds = BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      );
      final baseline = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        seeds: noCriticalSeeds,
        playerMove: _damagingMove(id: 'tackle', type: 'normal', power: 50),
      );
      final laserFocused = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerEffects: _playerEffect('laser_focus'),
        seeds: noCriticalSeeds,
        playerMove: _damagingMove(id: 'tackle', type: 'normal', power: 50),
      );

      expect(
        laserFocused.damageToOpponent,
        greaterThan(baseline.damageToOpponent),
      );
      expect(laserFocused.rngSeeds.moveCritical, noCriticalSeeds.moveCritical);
    });

    test('Lucky Chant and armor abilities prevent random critical hits', () {
      const noCriticalSeeds = BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      );
      final baseline = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        seeds: noCriticalSeeds,
        playerMove: _damagingMove(id: 'tackle', type: 'normal', power: 50),
      );
      final critical = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        seeds: noCriticalSeeds,
        playerMove: _damagingMove(
          id: 'slash',
          type: 'normal',
          power: 50,
          criticalRate: 4,
        ),
      );
      final luckyChant = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentEffects: _opponentBankEffect('lucky_chant'),
        seeds: noCriticalSeeds,
        playerMove: _damagingMove(
          id: 'slash',
          type: 'normal',
          power: 50,
          criticalRate: 4,
        ),
      );
      final battleArmor = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentAbilityId: 'battle_armor',
        seeds: noCriticalSeeds,
        playerMove: _damagingMove(
          id: 'slash',
          type: 'normal',
          power: 50,
          criticalRate: 4,
        ),
      );
      final shellArmor = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentAbilityId: 'shell_armor',
        seeds: noCriticalSeeds,
        playerMove: _damagingMove(
          id: 'slash',
          type: 'normal',
          power: 50,
          criticalRate: 4,
        ),
      );

      expect(critical.damageToOpponent, greaterThan(baseline.damageToOpponent));
      expect(luckyChant.damageToOpponent, baseline.damageToOpponent);
      expect(battleArmor.damageToOpponent, baseline.damageToOpponent);
      expect(shellArmor.damageToOpponent, baseline.damageToOpponent);
    });

    test('Merciless guarantees critical hits against poisoned targets', () {
      const noCriticalSeeds = BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      );
      final baseline = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'poison'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        seeds: noCriticalSeeds,
        playerMove: _damagingMove(id: 'poison_jab', type: 'poison', power: 50),
      );
      final merciless = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'poison'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerAbilityId: 'merciless',
        opponentMajorStatus: PsdkBattleMajorStatus.poison,
        seeds: noCriticalSeeds,
        playerMove: _damagingMove(id: 'poison_jab', type: 'poison', power: 50),
      );

      expect(
          merciless.damageToOpponent, greaterThan(baseline.damageToOpponent));
      expect(merciless.rngSeeds.moveCritical, noCriticalSeeds.moveCritical);
    });

    test('Super Luck and critical items improve critical count', () {
      const critWindowSeeds = BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 10000,
        moveAccuracy: 3,
        generic: 4,
      );
      final baseline = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        seeds: critWindowSeeds,
        playerMove: _damagingMove(id: 'slash', type: 'normal', power: 50),
      );
      final superLuck = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerAbilityId: 'super_luck',
        seeds: critWindowSeeds,
        playerMove: _damagingMove(id: 'slash', type: 'normal', power: 50),
      );
      final scopeLens = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerHeldItemId: 'scope_lens',
        seeds: critWindowSeeds,
        playerMove: _damagingMove(id: 'slash', type: 'normal', power: 50),
      );
      final leekFarfetchd = _runSinglePlayerMove(
        playerSpeciesId: 'farfetch_d',
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerHeldItemId: 'leek',
        seeds: critWindowSeeds,
        playerMove: _damagingMove(id: 'slash', type: 'normal', power: 50),
      );
      final luckyPunchChansey = _runSinglePlayerMove(
        playerSpeciesId: 'chansey',
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerHeldItemId: 'lucky_punch',
        seeds: critWindowSeeds,
        playerMove: _damagingMove(id: 'slash', type: 'normal', power: 50),
      );
      final lansatBerry = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerEffects: _playerEffect('lansat_berry'),
        seeds: critWindowSeeds,
        playerMove: _damagingMove(id: 'slash', type: 'normal', power: 50),
      );

      expect(
          superLuck.damageToOpponent, greaterThan(baseline.damageToOpponent));
      expect(
          scopeLens.damageToOpponent, greaterThan(baseline.damageToOpponent));
      expect(
        leekFarfetchd.damageToOpponent,
        greaterThan(baseline.damageToOpponent),
      );
      expect(
        luckyPunchChansey.damageToOpponent,
        greaterThan(baseline.damageToOpponent),
      );
      expect(
          lansatBerry.damageToOpponent, greaterThan(baseline.damageToOpponent));
    });

    test('Tar Shot marker doubles fire-type effectiveness locally', () {
      final baseline = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'fire'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerMove: _damagingMove(
          id: 'ember',
          type: 'fire',
          category: PsdkBattleMoveCategory.special,
          power: 40,
        ),
      );
      final tarred = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'fire'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentEffects: const PsdkBattleEffectStack.empty().addEffect(
          TarShotEffect(scope: BattlerBattleEffectScope(psdkOpponentSlot)),
        ),
        playerMove: _damagingMove(
          id: 'ember',
          type: 'fire',
          category: PsdkBattleMoveCategory.special,
          power: 40,
        ),
      );

      expect(baseline.damageToOpponent, 12);
      expect(tarred.damageToOpponent, 24);
    });

    test('Charge marker doubles Electric move base power only', () {
      final baseline = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'electric'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerMove: _damagingMove(
          id: 'spark',
          type: 'electric',
          power: 40,
        ),
      );
      final chargedElectric = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'electric'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerEffects: _playerEffect('charge'),
        playerMove: _damagingMove(
          id: 'spark',
          type: 'electric',
          power: 40,
        ),
      );
      final chargedNormal = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerEffects: _playerEffect('charge'),
        playerMove: _damagingMove(
          id: 'tackle',
          type: 'normal',
          power: 40,
        ),
      );
      final normalBaseline = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerMove: _damagingMove(
          id: 'tackle',
          type: 'normal',
          power: 40,
        ),
      );

      expect(chargedElectric.damageToOpponent,
          greaterThan(baseline.damageToOpponent));
      expect(chargedNormal.damageToOpponent, normalBaseline.damageToOpponent);
    });

    test('sport markers halve matching move base power only', () {
      final electricBaseline = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'electric'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerMove: _damagingMove(
          id: 'spark',
          type: 'electric',
          power: 40,
        ),
      );
      final mudSportElectric = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'electric'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerEffects: _playerEffect(PsdkBattleEffectIds.mudSport),
        playerMove: _damagingMove(
          id: 'spark',
          type: 'electric',
          power: 40,
        ),
      );
      final fireBaseline = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'fire'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerMove: _damagingMove(
          id: 'ember',
          type: 'fire',
          category: PsdkBattleMoveCategory.special,
          power: 40,
        ),
      );
      final waterSportFire = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'fire'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerEffects: _playerEffect(PsdkBattleEffectIds.waterSport),
        playerMove: _damagingMove(
          id: 'ember',
          type: 'fire',
          category: PsdkBattleMoveCategory.special,
          power: 40,
        ),
      );
      final mudSportFire = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'fire'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerEffects: _playerEffect(PsdkBattleEffectIds.mudSport),
        playerMove: _damagingMove(
          id: 'ember',
          type: 'fire',
          category: PsdkBattleMoveCategory.special,
          power: 40,
        ),
      );

      expect(mudSportElectric.damageToOpponent,
          lessThan(electricBaseline.damageToOpponent));
      expect(waterSportFire.damageToOpponent,
          lessThan(fireBaseline.damageToOpponent));
      expect(mudSportFire.damageToOpponent, fireBaseline.damageToOpponent);
    });

    test('ability suppression marker disables Levitate grounding immunity', () {
      final levitate = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'ground'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentAbilityId: 'levitate',
        playerMove: _damagingMove(
          id: 'mud_shot',
          type: 'ground',
          power: 40,
        ),
      );
      final suppressed = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'ground'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentAbilityId: 'levitate',
        opponentEffects: _opponentEffect('ability_suppressed'),
        playerMove: _damagingMove(
          id: 'mud_shot',
          type: 'ground',
          power: 40,
        ),
      );

      expect(levitate.damageToOpponent, 0);
      expect(suppressed.damageToOpponent, greaterThan(0));
    });

    test('Telekinesis marker makes grounded targets immune to Ground moves',
        () {
      final grounded = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'ground'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerMove: _damagingMove(
          id: 'mud_shot',
          type: 'ground',
          power: 40,
        ),
      );
      final telekinesis = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'ground'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentEffects: _opponentEffect('telekinesis'),
        playerMove: _damagingMove(
          id: 'mud_shot',
          type: 'ground',
          power: 40,
        ),
      );

      expect(grounded.damageToOpponent, greaterThan(0));
      expect(telekinesis.damageToOpponent, 0);
      expect(telekinesis.timelineKinds, contains('move_immune'));
    });

    test('Magnet Rise marker makes grounded targets immune to Ground moves',
        () {
      final grounded = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'ground'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerMove: _damagingMove(
          id: 'mud_shot',
          type: 'ground',
          power: 40,
        ),
      );
      final magnetRise = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'ground'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentEffects: _opponentEffect('magnet_rise'),
        playerMove: _damagingMove(
          id: 'mud_shot',
          type: 'ground',
          power: 40,
        ),
      );
      final knockedDown = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'ground'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentEffects: const PsdkBattleEffectStack.empty()
            .addEffect(
              GenericBattleEffect(
                id: 'magnet_rise',
                scope: BattlerBattleEffectScope(psdkOpponentSlot),
              ),
            )
            .addEffect(
              GenericBattleEffect(
                id: 'smack_down',
                scope: BattlerBattleEffectScope(psdkOpponentSlot),
              ),
            ),
        playerMove: _damagingMove(
          id: 'mud_shot',
          type: 'ground',
          power: 40,
        ),
      );

      expect(grounded.damageToOpponent, greaterThan(0));
      expect(magnetRise.damageToOpponent, 0);
      expect(magnetRise.timelineKinds, contains('move_immune'));
      expect(knockedDown.damageToOpponent, greaterThan(0));
    });

    test('Embargo marker suppresses grounding item effects', () {
      final airBalloon = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'ground'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentHeldItemId: 'air_balloon',
        playerMove: _damagingMove(
          id: 'mud_shot',
          type: 'ground',
          power: 40,
        ),
      );
      final embargoedAirBalloon = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'ground'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentHeldItemId: 'air_balloon',
        opponentEffects: _opponentEffect('embargo'),
        playerMove: _damagingMove(
          id: 'mud_shot',
          type: 'ground',
          power: 40,
        ),
      );

      expect(airBalloon.damageToOpponent, 0);
      expect(airBalloon.timelineKinds, contains('move_immune'));
      expect(embargoedAirBalloon.damageToOpponent, greaterThan(0));
    });

    test('Electrify and Ion Deluge rewrite move type to Electric', () {
      final normalIntoGround = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'ground'),
        playerMove: _damagingMove(
          id: 'tackle',
          type: 'normal',
          power: 40,
        ),
      );
      final electrifiedIntoGround = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'ground'),
        playerEffects: _playerEffect('electrify'),
        playerMove: _damagingMove(
          id: 'tackle',
          type: 'normal',
          power: 40,
        ),
      );
      final normalIntoGhost = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'ghost'),
        playerMove: _damagingMove(
          id: 'tackle',
          type: 'normal',
          power: 40,
        ),
      );
      final ionDelugeIntoGhost = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'ghost'),
        playerEffects: _playerEffect('ion_deluge'),
        playerMove: _damagingMove(
          id: 'tackle',
          type: 'normal',
          power: 40,
        ),
      );

      expect(normalIntoGround.damageToOpponent, greaterThan(0));
      expect(electrifiedIntoGround.damageToOpponent, 0);
      expect(electrifiedIntoGround.timelineKinds, contains('move_immune'));
      expect(normalIntoGhost.damageToOpponent, 0);
      expect(ionDelugeIntoGhost.damageToOpponent, greaterThan(0));
    });

    test('durable change-type marker does not behave like Electrify', () {
      final changedType = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'ground'),
        playerEffects: _playerEffect('change_type'),
        playerMove: _damagingMove(
          id: 'tackle',
          type: 'normal',
          power: 40,
        ),
      );

      expect(changedType.damageToOpponent, greaterThan(0));
    });

    test('Foresight and Miracle Eye overwrite matching type immunities', () {
      final ghostImmune = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'fighting'),
        opponentTypes: const PsdkBattleTypes(primary: 'ghost'),
        playerMove: _damagingMove(
          id: 'karate_chop',
          type: 'fighting',
          power: 40,
        ),
      );
      final foresightHit = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'fighting'),
        opponentTypes: const PsdkBattleTypes(primary: 'ghost'),
        opponentEffects: _opponentEffect('foresight'),
        playerMove: _damagingMove(
          id: 'karate_chop',
          type: 'fighting',
          power: 40,
        ),
      );
      final darkImmune = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'psychic'),
        opponentTypes: const PsdkBattleTypes(primary: 'dark'),
        playerMove: _damagingMove(
          id: 'confusion',
          type: 'psychic',
          category: PsdkBattleMoveCategory.special,
          power: 40,
        ),
      );
      final miracleEyeHit = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'psychic'),
        opponentTypes: const PsdkBattleTypes(primary: 'dark'),
        opponentEffects: _opponentEffect('miracle_eye'),
        playerMove: _damagingMove(
          id: 'confusion',
          type: 'psychic',
          category: PsdkBattleMoveCategory.special,
          power: 40,
        ),
      );

      expect(ghostImmune.damageToOpponent, 0);
      expect(foresightHit.damageToOpponent, greaterThan(0));
      expect(darkImmune.damageToOpponent, 0);
      expect(miracleEyeHit.damageToOpponent, greaterThan(0));
    });

    test('PSDK third type participates in STAB and effectiveness', () {
      final noStab = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerMove: _damagingMove(
          id: 'ember',
          type: 'fire',
          category: PsdkBattleMoveCategory.special,
          power: 40,
        ),
      );
      final thirdTypeStab = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        playerType3: 'fire',
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerMove: _damagingMove(
          id: 'ember',
          type: 'fire',
          category: PsdkBattleMoveCategory.special,
          power: 40,
        ),
      );
      final normalTarget = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'fire'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerMove: _damagingMove(
          id: 'ember',
          type: 'fire',
          category: PsdkBattleMoveCategory.special,
          power: 40,
        ),
      );
      final grassThirdType = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'fire'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentType3: 'grass',
        playerMove: _damagingMove(
          id: 'ember',
          type: 'fire',
          category: PsdkBattleMoveCategory.special,
          power: 40,
        ),
      );
      final ghostThirdType = _runSinglePlayerMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentType3: 'ghost',
        playerMove: _damagingMove(
          id: 'tackle',
          type: 'normal',
          power: 40,
        ),
      );

      expect(
          thirdTypeStab.damageToOpponent, greaterThan(noStab.damageToOpponent));
      expect(grassThirdType.damageToOpponent,
          greaterThan(normalTarget.damageToOpponent));
      expect(ghostThirdType.damageToOpponent, 0);
    });
  });
}

_RunResult _runSinglePlayerMove({
  String? playerSpeciesId,
  required PsdkBattleTypes playerTypes,
  String? playerType3,
  required PsdkBattleTypes opponentTypes,
  String? opponentType3,
  required PsdkBattleMoveData playerMove,
  String? playerAbilityId,
  String? opponentAbilityId,
  String? playerHeldItemId,
  String? opponentHeldItemId,
  PsdkBattleMajorStatus? opponentMajorStatus,
  PsdkBattleEffectStack playerEffects = const PsdkBattleEffectStack.empty(),
  PsdkBattleEffectStack opponentEffects = const PsdkBattleEffectStack.empty(),
  BattleRngSeeds seeds = const BattleRngSeeds(
    moveDamage: 1,
    moveCritical: 99999,
    moveAccuracy: 3,
    generic: 4,
  ),
}) {
  final setup = BattleEngineSetup.singles(
    player: _combatant(
      id: 'player',
      speciesId: playerSpeciesId,
      types: playerTypes,
      type3: playerType3,
      speed: 100,
      abilityId: playerAbilityId,
      heldItemId: playerHeldItemId,
      effects: playerEffects,
      moves: <PsdkBattleMoveData>[playerMove],
    ),
    opponent: _combatant(
      id: 'opponent',
      types: opponentTypes,
      type3: opponentType3,
      speed: 1,
      abilityId: opponentAbilityId,
      heldItemId: opponentHeldItemId,
      majorStatus: opponentMajorStatus,
      effects: opponentEffects,
      moves: <PsdkBattleMoveData>[
        _damagingMove(id: 'splash_hit', type: 'normal', power: 0),
      ],
    ),
    rngSeeds: seeds.psdkSeeds,
  );
  final engine = BattleEngine(setup: setup);
  final result = engine.submit(const BattleDecision.fight(moveSlot: 0));
  final opponentHp = result.state.battlerAt(psdkOpponentSlot).currentHp;
  return _RunResult(
    damageToOpponent: 100 - opponentHp,
    timelineEvents: result.timeline.events,
    rngSeeds: result.state.rngSeeds,
  );
}

PsdkBattleEffectStack _playerEffect(String id) {
  return const PsdkBattleEffectStack.empty().addEffect(
    GenericBattleEffect(
        id: id, scope: BattlerBattleEffectScope(psdkPlayerSlot)),
  );
}

PsdkBattleEffectStack _opponentBankEffect(String id) {
  return const PsdkBattleEffectStack.empty().addEffect(
    GenericBattleEffect(id: id, scope: BankBattleEffectScope(1)),
  );
}

PsdkBattleEffectStack _opponentEffect(String id) {
  return const PsdkBattleEffectStack.empty().addEffect(
    GenericBattleEffect(
        id: id, scope: BattlerBattleEffectScope(psdkOpponentSlot)),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  String? speciesId,
  required PsdkBattleTypes types,
  String? type3,
  required int speed,
  required List<PsdkBattleMoveData> moves,
  String? abilityId,
  String? heldItemId,
  PsdkBattleMajorStatus? majorStatus,
  PsdkBattleEffectStack effects = const PsdkBattleEffectStack.empty(),
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: speciesId ?? id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    types: types,
    type3: type3,
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    abilityId: abilityId,
    heldItemId: heldItemId,
    majorStatus: majorStatus,
    moves: moves,
    effects: effects,
  );
}

PsdkBattleMoveData _damagingMove({
  required String id,
  required String type,
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int criticalRate = 1,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: 100,
    pp: 35,
    priority: 0,
    criticalRate: criticalRate,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}

final class _RunResult {
  const _RunResult({
    required this.damageToOpponent,
    required this.timelineEvents,
    required this.rngSeeds,
  });

  final int damageToOpponent;
  final List<BattleTimelineEvent> timelineEvents;
  final BattleRngSeeds rngSeeds;

  List<String> get timelineKinds {
    return timelineEvents.map((event) => event.kind).toList(growable: false);
  }
}
