import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

/// Chaîne de dégâts PSDK, transcrite depuis la source Ruby.
///
/// Source : `scripts/5 Battle/10 Move/101 Damage_Calc.rb`, méthode `damages`,
/// qui déclare suivre la formule de 4e génération. Ce qui compte ici n'est pas
/// la liste des multiplicateurs mais **la position de chaque troncature** : ce
/// sont elles qui rendent le résultat sensible à l'ordre, et c'est exactement ce
/// que le ticket demande de documenter.
///
///     damage = level * 2 / 5 + 2
///     damage = (damage * base_power).floor
///     damage = (damage * sp_atk).floor / 50
///     damage = (damage / sp_def).floor
///     damage = (damage * mod1).floor + 2      <- brûlure, météo, terrain
///     damage = (damage * ch).floor            <- critique
///     damage = (damage * mod2).floor
///     damage = damage * rand(85..100) / 100
///     damage = (damage * stab).floor
///     damage = (damage * type1).floor         <- une troncature PAR type
///     damage = (damage * type2).floor
///     damage = (damage * mod3).floor          <- objet tenu, talent final
///     damage = damage.clamp(1, target_hp)
///
/// Cette fonction est écrite depuis le Ruby, pas depuis le calculateur Dart.
/// C'est ce qui lui donne sa valeur d'oracle : une erreur d'arithmétique dans le
/// moteur ne peut pas se recopier ici.
int referenceDamage({
  required int roll,
  required int level,
  required int power,
  required int offensiveStat,
  required int defensiveStat,
  double mod1 = 1,
  double criticalMultiplier = 1,
  double mod2 = 1,
  double stab = 1,
  List<double> sequentialTypeMultipliers = const <double>[],
  double combinedTypeMultiplier = 1,
  double mod3 = 1,
}) {
  var damage = (2 * level) ~/ 5 + 2;
  damage = (damage * power).floor();
  damage = (damage * offensiveStat).floor() ~/ 50;
  damage = damage ~/ defensiveStat;
  damage = (damage * mod1).floor() + 2;
  damage = (damage * criticalMultiplier).floor();
  damage = (damage * mod2).floor();
  damage = (damage * roll) ~/ 100;
  damage = (damage * stab).floor();
  for (final multiplier in sequentialTypeMultipliers) {
    damage = (damage * multiplier).floor();
  }
  damage = (damage * combinedTypeMultiplier).floor();
  damage = (damage * mod3).floor();
  return damage < 1 ? 1 : damage;
}

/// Roll de dégâts produit par une graine, transcrit depuis `BattleRngStream`.
///
///     nextPercent       -> (seed.abs() % 100) + 1
///     nextDamagePercent -> 85 + (value % 16)
///
/// Le connaître change la nature de la preuve. Une première version de ce
/// fichier comparait les dégâts à la bande des seize rolls possibles ; deux
/// sabotages du moteur — STAB déplacé avant le roll, et diviseur 50 changé en
/// 49 — la traversaient sans être vus. Une valeur exacte ne pardonne rien.
int damageRollForSeed(int seed) => 85 + (((seed.abs() % 100) + 1) % 16);

/// Roll de la graine `moveDamage: 1` utilisée par tous les vecteurs.
const int _seededRoll = 87;

void main() {
  group('BETA-BAT-002 damage reference vectors', () {
    test('the transcribed roll matches the seed every vector uses', () {
      expect(damageRollForSeed(1), _seededRoll);
    });

    test('the reference chain reproduces the tracked golden vector', () {
      // basic_damage_neutral.json : Bulbasaur niveau 10, Tackle 40, 49 contre
      // 49, dégâts attendus 5. La fixture a été capturée indépendamment de
      // cette fonction ; qu'elle retombe dessus valide la transcription.
      expect(
        referenceDamage(
          roll: _seededRoll,
          level: 10,
          power: 40,
          offensiveStat: 49,
          defensiveStat: 49,
        ),
        5,
      );
    });

    test('a physical hit matches the reference to the point', () {
      expect(
        _run(
          move: _move(id: 'tackle', type: 'normal', power: 40),
          playerTypes: const PsdkBattleTypes(primary: 'water'),
          opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        ),
        _reference(),
      );
    });

    test('a special hit reads the special stats, not the physical ones', () {
      // Attaque physique énorme et attaque spéciale ordinaire : si le
      // calculateur lisait la mauvaise statistique, la valeur exploserait.
      expect(
        _run(
          move: _move(
            id: 'swift',
            type: 'normal',
            power: 40,
            category: PsdkBattleMoveCategory.special,
          ),
          playerTypes: const PsdkBattleTypes(primary: 'water'),
          opponentTypes: const PsdkBattleTypes(primary: 'normal'),
          playerStats: const PsdkBattleStats(
            attack: 200,
            defense: 50,
            specialAttack: 50,
            specialDefense: 50,
            speed: 100,
          ),
          opponentStats: const PsdkBattleStats(
            attack: 50,
            defense: 200,
            specialAttack: 50,
            specialDefense: 50,
            speed: 1,
          ),
        ),
        _reference(),
      );
    });

    test('an awkward vector pins every truncation of the chain', () {
      // Niveau 23, puissance 43, 53 contre 17 : aucune étape ne tombe rond, si
      // bien qu'une erreur d'un point à n'importe quelle troncature se propage
      // jusqu'au bout. Les vecteurs à statistiques rondes absorbaient au
      // contraire un diviseur faux, la seconde division rattrapant la première.
      expect(
        _run(
          level: 23,
          move: _move(id: 'ember', type: 'fire', power: 43),
          playerTypes: const PsdkBattleTypes(primary: 'fire'),
          opponentTypes: const PsdkBattleTypes(primary: 'normal'),
          playerStats: const PsdkBattleStats(
            attack: 53,
            defense: 50,
            specialAttack: 53,
            specialDefense: 50,
            speed: 100,
          ),
          opponentStats: const PsdkBattleStats(
            attack: 50,
            defense: 17,
            specialAttack: 50,
            specialDefense: 17,
            speed: 1,
          ),
        ),
        referenceDamage(
          roll: _seededRoll,
          level: 23,
          power: 43,
          offensiveStat: 53,
          defensiveStat: 17,
          stab: 1.5,
        ),
      );
    });

    test('STAB applies once whether the type is primary or secondary', () {
      final expected = _reference(stab: 1.5);
      final primary = _run(
        move: _move(id: 'ember', type: 'fire', power: 40),
        playerTypes: const PsdkBattleTypes(primary: 'fire'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
      );
      final secondary = _run(
        move: _move(id: 'ember', type: 'fire', power: 40),
        playerTypes: const PsdkBattleTypes(primary: 'rock', secondary: 'fire'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
      );

      expect(primary, expected);
      expect(secondary, expected);
      // Sans cette exclusion, un STAB oublié passerait pour un coup neutre.
      expect(expected, isNot(_reference()));
    });

    test('weakness and resistance land on their reference values', () {
      expect(
        _run(
          move: _move(id: 'ember', type: 'fire', power: 40),
          playerTypes: const PsdkBattleTypes(primary: 'water'),
          opponentTypes: const PsdkBattleTypes(primary: 'grass'),
        ),
        _reference(combinedTypeMultiplier: 2),
      );
      expect(
        _run(
          move: _move(id: 'ember', type: 'fire', power: 40),
          playerTypes: const PsdkBattleTypes(primary: 'water'),
          opponentTypes: const PsdkBattleTypes(primary: 'water'),
        ),
        _reference(combinedTypeMultiplier: 0.5),
      );
    });

    test('immunity produces no damage at all, not a floored one', () {
      // Le plancher à 1 ne doit pas transformer une immunité en égratignure.
      expect(
        _run(
          move: _move(id: 'thunder_shock', type: 'electric', power: 40),
          playerTypes: const PsdkBattleTypes(primary: 'electric'),
          opponentTypes: const PsdkBattleTypes(primary: 'ground'),
        ),
        0,
      );
    });

    test('a critical hit multiplies by 1.5 before the roll', () {
      // Le critique n'est pas observable sur le timeline : on le prouve en
      // exigeant la valeur critique exacte, qui diffère de la valeur neutre.
      final expected = _reference(criticalMultiplier: 1.5);

      expect(
        _run(
          move: _move(id: 'slash', type: 'normal', power: 40, criticalRate: 6),
          playerTypes: const PsdkBattleTypes(primary: 'water'),
          opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        ),
        expected,
      );
      expect(expected, isNot(_reference()));
    });

    test('burn halves a physical hit through Mod1, before the +2', () {
      // Mod1 agit AVANT le +2. Appliquer la brûlure après donnerait une valeur
      // plus haute : la valeur exacte sépare les deux positions.
      expect(
        _run(
          move: _move(id: 'tackle', type: 'normal', power: 40),
          playerTypes: const PsdkBattleTypes(primary: 'water'),
          opponentTypes: const PsdkBattleTypes(primary: 'normal'),
          playerMajorStatus: PsdkBattleMajorStatus.burn,
        ),
        _reference(mod1: 0.5),
      );
    });

    test('burn leaves a special hit alone', () {
      expect(
        _run(
          move: _move(
            id: 'swift',
            type: 'normal',
            power: 40,
            category: PsdkBattleMoveCategory.special,
          ),
          playerTypes: const PsdkBattleTypes(primary: 'water'),
          opponentTypes: const PsdkBattleTypes(primary: 'normal'),
          playerMajorStatus: PsdkBattleMajorStatus.burn,
        ),
        _reference(),
      );
    });

    test('rain and sun move water and fire in opposite directions', () {
      for (final probe in <_WeatherProbe>[
        _WeatherProbe(PsdkBattleWeatherId.rain, 'water', 1.5),
        _WeatherProbe(PsdkBattleWeatherId.rain, 'fire', 0.5),
        _WeatherProbe(PsdkBattleWeatherId.sunny, 'fire', 1.5),
        _WeatherProbe(PsdkBattleWeatherId.sunny, 'water', 0.5),
      ]) {
        expect(
          _run(
            move: _move(id: 'probe', type: probe.moveType, power: 40),
            playerTypes: const PsdkBattleTypes(primary: 'normal'),
            opponentTypes: const PsdkBattleTypes(primary: 'normal'),
            weather: probe.weather,
          ),
          _reference(mod1: probe.mod1),
          reason: '${probe.weather.name} on a ${probe.moveType} move',
        );
      }
    });

    test('a hit that rounds to nothing still takes one point', () {
      // clamp(1, hp) dans PSDK. Sans ce plancher, une attaque ridicule contre
      // une défense énorme rendrait 0 et se confondrait avec une immunité.
      expect(
        _run(
          move: _move(id: 'feint', type: 'normal', power: 1),
          playerTypes: const PsdkBattleTypes(primary: 'water'),
          opponentTypes: const PsdkBattleTypes(primary: 'rock'),
          playerStats: const PsdkBattleStats(
            attack: 1,
            defense: 50,
            specialAttack: 1,
            specialDefense: 50,
            speed: 100,
          ),
          opponentStats: const PsdkBattleStats(
            attack: 50,
            defense: 500,
            specialAttack: 50,
            specialDefense: 500,
            speed: 1,
          ),
        ),
        1,
      );
      expect(
        referenceDamage(
          roll: _seededRoll,
          level: 20,
          power: 1,
          offensiveStat: 1,
          defensiveStat: 500,
          combinedTypeMultiplier: 0.5,
        ),
        1,
        reason: 'the reference floor must agree that only 1 is reachable',
      );
    });


    test('an ability that boosts base power feeds the chain a bigger power',
        () {
      // Technician multiplie par 1.5 la puissance d'une capacite a 60 ou moins.
      // Le talent agit sur la PUISSANCE DE BASE, en amont de la chaine : le
      // vecteur de reference recoit donc 60 au lieu de 40, pas un multiplicateur
      // supplementaire en fin de calcul.
      final boosted = _run(
        move: _move(id: 'tackle', type: 'normal', power: 40),
        playerTypes: const PsdkBattleTypes(primary: 'water'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerAbilityId: 'technician',
      );

      expect(
        boosted,
        referenceDamage(
          roll: _seededRoll,
          level: 20,
          power: 60,
          offensiveStat: 50,
          defensiveStat: 50,
        ),
      );
      expect(boosted, isNot(_reference()));
    });

    test('a held item that boosts its type feeds the chain a bigger power', () {
      // Charcoal multiplie par 1.2 la puissance des capacites Feu :
      // floor(40 x 1.2) = 48.
      final boosted = _run(
        move: _move(id: 'ember', type: 'fire', power: 40),
        playerTypes: const PsdkBattleTypes(primary: 'water'),
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerHeldItemId: 'charcoal',
      );

      expect(
        boosted,
        referenceDamage(
          roll: _seededRoll,
          level: 20,
          power: 48,
          offensiveStat: 50,
          defensiveStat: 50,
        ),
      );
      expect(boosted, isNot(_reference()));
    });

    test('a held item leaves a move of another type alone', () {
      expect(
        _run(
          move: _move(id: 'tackle', type: 'normal', power: 40),
          playerTypes: const PsdkBattleTypes(primary: 'water'),
          opponentTypes: const PsdkBattleTypes(primary: 'normal'),
          playerHeldItemId: 'charcoal',
        ),
        _reference(),
      );
    });

    test('the roll band is 85..100 and both ends change the result', () {
      // Rolls minimum et maximum, deux critères du ticket. Les vérifier sur la
      // référence les rend lisibles sans dépendre d'une graine.
      final low = referenceDamage(
        roll: 85,
        level: 50,
        power: 100,
        offensiveStat: 150,
        defensiveStat: 100,
      );
      final high = referenceDamage(
        roll: 100,
        level: 50,
        power: 100,
        offensiveStat: 150,
        defensiveStat: 100,
      );

      expect(low, lessThan(high));
      expect(high - low, greaterThan(1));
      expect(damageRollForSeed(0), 86);
      expect(damageRollForSeed(15), 85);
    });

    test(
        'the engine combines the two type multipliers where PSDK floors '
        'between them', () {
      // ÉCART MESURÉ AVEC PSDK, trouvé le 2026-08-18.
      //
      // PSDK tronque après CHAQUE type. Le calculateur Dart combine les deux en
      // un multiplicateur puis tronque une fois. Sur une cible Eau/Plante
      // frappée par du Feu — 0.5 puis 2, produit exactement 1 — les deux
      // conventions divergent dès que la valeur avant type est impaire.
      //
      // Ce vecteur la rend impaire exprès : défense spéciale 35 donne 11 après
      // le roll. PSDK : floor(11 x 0.5) = 5, puis 5 x 2 = 10. Le moteur :
      // floor(11 x 1) = 11.
      //
      // Le test n'arbitre pas, il chiffre. La convention combinée est celle du
      // chaînage de la série principale Gen 5+, et la cible de parité est
      // déclarée hybride ; ce qui serait fautif, c'est que l'écart dérive sans
      // que personne ne le voie.
      const level = 20;
      const power = 40;
      const offensiveStat = 50;
      const defensiveStat = 35;

      final psdkSequential = referenceDamage(
        roll: _seededRoll,
        level: level,
        power: power,
        offensiveStat: offensiveStat,
        defensiveStat: defensiveStat,
        sequentialTypeMultipliers: const <double>[0.5, 2],
      );
      final engineCombined = referenceDamage(
        roll: _seededRoll,
        level: level,
        power: power,
        offensiveStat: offensiveStat,
        defensiveStat: defensiveStat,
        combinedTypeMultiplier: 1,
      );

      expect(psdkSequential, 10);
      expect(engineCombined, 11);

      expect(
        _run(
          move: _move(
            id: 'ember',
            type: 'fire',
            power: power,
            category: PsdkBattleMoveCategory.special,
          ),
          playerTypes: const PsdkBattleTypes(primary: 'normal'),
          opponentTypes: const PsdkBattleTypes(
            primary: 'water',
            secondary: 'grass',
          ),
          playerStats: const PsdkBattleStats(
            attack: offensiveStat,
            defense: 50,
            specialAttack: offensiveStat,
            specialDefense: 50,
            speed: 100,
          ),
          opponentStats: const PsdkBattleStats(
            attack: 50,
            defense: defensiveStat,
            specialAttack: 50,
            specialDefense: defensiveStat,
            speed: 1,
          ),
        ),
        engineCombined,
        reason: 'the engine follows the combined convention, not PSDK order',
      );
    });
  });
}

/// Vecteur de base partagé : niveau 20, puissance 40, 50 contre 50.
int _reference({
  double mod1 = 1,
  double criticalMultiplier = 1,
  double stab = 1,
  double combinedTypeMultiplier = 1,
  double mod3 = 1,
}) {
  return referenceDamage(
    roll: _seededRoll,
    level: 20,
    power: 40,
    offensiveStat: 50,
    defensiveStat: 50,
    mod1: mod1,
    criticalMultiplier: criticalMultiplier,
    stab: stab,
    combinedTypeMultiplier: combinedTypeMultiplier,
    mod3: mod3,
  );
}

final class _WeatherProbe {
  const _WeatherProbe(this.weather, this.moveType, this.mod1);

  final PsdkBattleWeatherId weather;
  final String moveType;
  final double mod1;
}

int _run({
  required PsdkBattleMoveData move,
  required PsdkBattleTypes playerTypes,
  required PsdkBattleTypes opponentTypes,
  PsdkBattleStats? playerStats,
  PsdkBattleStats? opponentStats,
  PsdkBattleMajorStatus? playerMajorStatus,
  PsdkBattleWeatherId? weather,
  String? playerAbilityId,
  String? playerHeldItemId,
  int level = 20,
  BattleRngSeeds seeds = const BattleRngSeeds(
    moveDamage: 1,
    moveCritical: 99999,
    moveAccuracy: 3,
    generic: 4,
  ),
}) {
  final setup = BattleEngineSetup.singlesPokeMapBetaV1ForTest(
    player: _combatant(
      id: 'player',
      types: playerTypes,
      speed: 100,
      stats: playerStats,
      majorStatus: playerMajorStatus,
      abilityId: playerAbilityId,
      heldItemId: playerHeldItemId,
      level: level,
      moves: <PsdkBattleMoveData>[move],
    ),
    opponent: _combatant(
      id: 'opponent',
      types: opponentTypes,
      speed: 1,
      stats: opponentStats,
      level: level,
      moves: <PsdkBattleMoveData>[
        _move(id: 'idle', type: 'normal', power: 0),
      ],
    ),
    rngSeeds: seeds.psdkSeeds,
    field: weather == null
        ? const PsdkBattleFieldState()
        : PsdkBattleFieldState(
            weather: PsdkBattleWeatherState(id: weather, remainingTurns: 3),
          ),
  );
  final engine = BattleEngine(setup: setup);
  final result = engine.submit(const BattleDecision.fight(moveSlot: 0));
  return 200 - result.state.battlerAt(psdkOpponentSlot).currentHp;
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required PsdkBattleTypes types,
  required int speed,
  PsdkBattleStats? stats,
  PsdkBattleMajorStatus? majorStatus,
  String? abilityId,
  String? heldItemId,
  int level = 20,
  required List<PsdkBattleMoveData> moves,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: level,
    maxHp: 200,
    currentHp: 200,
    types: types,
    stats: stats ??
        PsdkBattleStats(
          attack: 50,
          defense: 50,
          specialAttack: 50,
          specialDefense: 50,
          speed: speed,
        ),
    majorStatus: majorStatus,
    abilityId: abilityId,
    heldItemId: heldItemId,
    moves: moves,
  );
}

PsdkBattleMoveData _move({
  required String id,
  required String type,
  required int power,
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
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
