import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/services/showdown_move_catalog_converter.dart';

void main() {
  const converter = ShowdownMoveCatalogConverter();

  test('converts standard offensive, drain, multi-hit and direct status moves',
      () {
    final catalog = converter.convert(<String, dynamic>{
      'thunderbolt': <String, dynamic>{
        'name': 'Thunderbolt',
        'type': 'Electric',
        'category': 'Special',
        'basePower': 90,
        'accuracy': 100,
        'pp': 15,
        'priority': 0,
        'target': 'normal',
        'secondary': <String, dynamic>{
          'chance': 10,
          'status': 'par',
        },
        'shortDesc': 'May paralyze the target.',
        'desc': 'A strong electric blast crashes down on the target.',
        'gen': 1,
      },
      'absorb': <String, dynamic>{
        'name': 'Absorb',
        'type': 'Grass',
        'category': 'Special',
        'basePower': 20,
        'accuracy': 100,
        'pp': 20,
        'priority': 0,
        'target': 'normal',
        'drain': <int>[1, 2],
        'shortDesc': 'Heals the user by half the damage dealt.',
        'desc': 'A nutrient-draining attack.',
        'gen': 1,
      },
      'doubleslap': <String, dynamic>{
        'name': 'Double Slap',
        'type': 'Normal',
        'category': 'Physical',
        'basePower': 15,
        'accuracy': 85,
        'pp': 10,
        'priority': 0,
        'target': 'normal',
        'multihit': <int>[2, 5],
        'shortDesc': 'Hits 2-5 times in one turn.',
        'desc': 'Repeatedly slaps 2 to 5 times.',
        'gen': 1,
      },
      'swift': <String, dynamic>{
        'name': 'Swift',
        'type': 'Normal',
        'category': 'Special',
        'basePower': 60,
        'accuracy': true,
        'pp': 20,
        'priority': 0,
        'target': 'allAdjacentFoes',
        'shortDesc': 'This move does not check accuracy.',
        'desc': 'Star-shaped rays are shot at opposing Pokémon.',
        'gen': 1,
      },
      'thunderwave': <String, dynamic>{
        'name': 'Thunder Wave',
        'type': 'Electric',
        'category': 'Status',
        'basePower': 0,
        'accuracy': 90,
        'pp': 20,
        'priority': 0,
        'target': 'normal',
        'status': 'par',
        'shortDesc': 'Paralyzes the target.',
        'desc': 'A weak electric charge is launched at the target.',
        'gen': 1,
      },
      'swordsdance': <String, dynamic>{
        'name': 'Swords Dance',
        'type': 'Normal',
        'category': 'Status',
        'basePower': 0,
        'accuracy': true,
        'pp': 20,
        'priority': 0,
        'target': 'self',
        'boosts': <String, int>{'atk': 2},
        'shortDesc': 'Raises the user\'s Attack by 2.',
        'desc': 'A frenetic dance to uplift the fighting spirit.',
        'gen': 1,
      },
      'leer': <String, dynamic>{
        'name': 'Leer',
        'type': 'Normal',
        'category': 'Status',
        'basePower': 0,
        'accuracy': 100,
        'pp': 30,
        'priority': 0,
        'target': 'allAdjacentFoes',
        'boosts': <String, int>{'def': -1},
        'shortDesc': 'Lowers the target\'s Defense by 1.',
        'desc': 'The user gives opposing Pokémon an intimidating leer.',
        'gen': 1,
      },
    });

    final thunderbolt = _move(catalog, 'thunderbolt');
    expect(thunderbolt.source, 'showdown');
    expect(thunderbolt.basePower, 90);
    expect(thunderbolt.usesStandardDamageFlow, isTrue);
    expect(
      thunderbolt.accuracy,
      const PokemonMoveAccuracy.percent(value: 100),
    );
    expect(
      thunderbolt.effects,
      contains(
        const PokemonMoveEffect.applyStatus(
          chance: 10,
          statusId: 'par',
        ),
      ),
    );
    expect(
      thunderbolt.effects.map((effect) => effect.toJson()['kind']),
      isNot(contains('deal_damage')),
    );
    expect(
      thunderbolt.engineSupportLevel,
      PokemonMoveEngineSupportLevel.structuredSupported,
    );

    final absorb = _move(catalog, 'absorb');
    expect(
      absorb.effects,
      contains(
        const PokemonMoveEffect.drain(numerator: 1, denominator: 2),
      ),
    );

    final doubleSlap = _move(catalog, 'double_slap');
    expect(
      doubleSlap.effects,
      contains(
        const PokemonMoveEffect.multiHit(minHits: 2, maxHits: 5),
      ),
    );

    final swift = _move(catalog, 'swift');
    expect(swift.accuracy, const PokemonMoveAccuracy.alwaysHits());

    final thunderWave = _move(catalog, 'thunder_wave');
    expect(
      thunderWave.effects,
      contains(
        const PokemonMoveEffect.applyStatus(statusId: 'par'),
      ),
    );

    final swordsDance = _move(catalog, 'swords_dance');
    expect(
      swordsDance.effects,
      contains(
        const PokemonMoveEffect.modifyStats(
          targetScope: PokemonMoveEffectTargetScope.self,
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.attack,
              stages: 2,
            ),
          ],
        ),
      ),
    );

    final leer = _move(catalog, 'leer');
    expect(
      leer.effects,
      contains(
        const PokemonMoveEffect.modifyStats(
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.defense,
              stages: -1,
            ),
          ],
        ),
      ),
    );
  });

  test('converts weather, terrain, pseudo-weather, side and slot conditions',
      () {
    final catalog = converter.convert(<String, dynamic>{
      'raindance': <String, dynamic>{
        'name': 'Rain Dance',
        'type': 'Water',
        'category': 'Status',
        'basePower': 0,
        'accuracy': true,
        'pp': 5,
        'priority': 0,
        'target': 'self',
        'weather': 'raindance',
        'shortDesc': 'For 5 turns, heavy rain powers Water moves.',
        'desc': 'The user summons a heavy rain.',
        'gen': 2,
      },
      'electricterrain': <String, dynamic>{
        'name': 'Electric Terrain',
        'type': 'Electric',
        'category': 'Status',
        'basePower': 0,
        'accuracy': true,
        'pp': 10,
        'priority': 0,
        'target': 'self',
        'terrain': 'electricterrain',
        'shortDesc': 'For 5 turns, the terrain becomes electric.',
        'desc': 'The user electrifies the ground.',
        'gen': 6,
      },
      'trickroom': <String, dynamic>{
        'name': 'Trick Room',
        'type': 'Psychic',
        'category': 'Status',
        'basePower': 0,
        'accuracy': true,
        'pp': 5,
        'priority': -7,
        'target': 'all',
        'pseudoWeather': 'trickroom',
        'shortDesc': 'For 5 turns, slower Pokémon move first.',
        'desc':
            'The user creates a bizarre area in which slower Pokémon get to move first.',
        'gen': 4,
      },
      'stealthrock': <String, dynamic>{
        'name': 'Stealth Rock',
        'type': 'Rock',
        'category': 'Status',
        'basePower': 0,
        'accuracy': true,
        'pp': 20,
        'priority': 0,
        'target': 'foeSide',
        'sideCondition': 'stealthrock',
        'shortDesc': 'Sets a hazard on the foes\' side of the field.',
        'desc':
            'The user lays a trap of levitating stones around the opposing team.',
        'gen': 4,
      },
      'healingwish': <String, dynamic>{
        'name': 'Healing Wish',
        'type': 'Psychic',
        'category': 'Status',
        'basePower': 0,
        'accuracy': true,
        'pp': 10,
        'priority': 0,
        'target': 'self',
        'slotCondition': 'healingwish',
        'shortDesc': 'The user faints and heals its replacement.',
        'desc': 'The user faints and the Pokémon switched in is fully healed.',
        'gen': 4,
      },
    });

    expect(
      _move(catalog, 'rain_dance').effects,
      contains(
        const PokemonMoveEffect.setWeather(weatherId: 'raindance'),
      ),
    );
    expect(
      _move(catalog, 'electric_terrain').effects,
      contains(
        const PokemonMoveEffect.setTerrain(terrainId: 'electricterrain'),
      ),
    );
    expect(
      _move(catalog, 'trick_room').effects,
      contains(
        const PokemonMoveEffect.setPseudoWeather(
          pseudoWeatherId: 'trickroom',
        ),
      ),
    );
    expect(
      _move(catalog, 'stealth_rock').effects,
      contains(
        const PokemonMoveEffect.setSideCondition(
          conditionId: 'stealthrock',
        ),
      ),
    );
    expect(
      _move(catalog, 'healing_wish').effects,
      contains(
        const PokemonMoveEffect.setSlotCondition(
          conditionId: 'healingwish',
        ),
      ),
    );
  });

  test(
      'keeps Tail Whip and Withdraw fully supported when Showdown only adds zMove metadata',
      () {
    final catalog = converter.convert(<String, dynamic>{
      'tailwhip': <String, dynamic>{
        'name': 'Tail Whip',
        'type': 'Normal',
        'category': 'Status',
        'basePower': 0,
        'accuracy': 100,
        'pp': 30,
        'priority': 0,
        'target': 'allAdjacentFoes',
        'boosts': <String, int>{'def': -1},
        'zMove': <String, Object>{
          'boost': <String, int>{'atk': 1},
        },
        'shortDesc': 'Lowers the foe(s) Defense by 1.',
        'desc': 'Lowers the target Defense by 1 stage.',
        'gen': 1,
      },
      'withdraw': <String, dynamic>{
        'name': 'Withdraw',
        'type': 'Water',
        'category': 'Status',
        'basePower': 0,
        'accuracy': true,
        'pp': 40,
        'priority': 0,
        'target': 'self',
        'boosts': <String, int>{'def': 1},
        'zMove': <String, Object>{
          'boost': <String, int>{'def': 1},
        },
        'shortDesc': 'Raises the user Defense by 1.',
        'desc': 'The user withdraws into its shell to raise Defense by 1.',
        'gen': 1,
      },
    });

    final tailWhip = _move(catalog, 'tail_whip');
    expect(
      tailWhip.effects,
      contains(
        const PokemonMoveEffect.modifyStats(
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.defense,
              stages: -1,
            ),
          ],
        ),
      ),
    );
    expect(
      tailWhip.engineSupportLevel,
      equals(PokemonMoveEngineSupportLevel.structuredSupported),
    );
    expect(tailWhip.unsupportedReasons, isEmpty);

    final withdraw = _move(catalog, 'withdraw');
    expect(
      withdraw.effects,
      contains(
        const PokemonMoveEffect.modifyStats(
          targetScope: PokemonMoveEffectTargetScope.self,
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.defense,
              stages: 1,
            ),
          ],
        ),
      ),
    );
    expect(
      withdraw.engineSupportLevel,
      equals(PokemonMoveEngineSupportLevel.structuredSupported),
    );
    expect(withdraw.unsupportedReasons, isEmpty);
  });

  test(
      'keeps Bubble and Bubble Beam structured and fully supported once their probabilistic speed-drop rider is really consumable by battle',
      () {
    final catalog = converter.convert(<String, dynamic>{
      'bubble': <String, dynamic>{
        'name': 'Bubble',
        'type': 'Water',
        'category': 'Special',
        'basePower': 40,
        'accuracy': 100,
        'pp': 30,
        'priority': 0,
        'target': 'allAdjacentFoes',
        'secondary': <String, dynamic>{
          'chance': 10,
          'boosts': <String, int>{'spe': -1},
        },
        'shortDesc': '10% chance to lower the target Speed by 1.',
        'desc': 'A spray of bubbles may lower the target Speed by 1 stage.',
        'gen': 1,
      },
      'bubblebeam': <String, dynamic>{
        'name': 'Bubble Beam',
        'type': 'Water',
        'category': 'Special',
        'basePower': 65,
        'accuracy': 100,
        'pp': 20,
        'priority': 0,
        'target': 'normal',
        'secondary': <String, dynamic>{
          'chance': 10,
          'boosts': <String, int>{'spe': -1},
        },
        'shortDesc': '10% chance to lower the target Speed by 1.',
        'desc': 'A spray of bubbles may lower the target Speed by 1 stage.',
        'gen': 1,
      },
    });

    final bubble = _move(catalog, 'bubble');
    expect(
      bubble.effects,
      contains(
        const PokemonMoveEffect.modifyStats(
          chance: 10,
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.speed,
              stages: -1,
            ),
          ],
        ),
      ),
    );
    expect(
      bubble.engineSupportLevel,
      equals(PokemonMoveEngineSupportLevel.structuredSupported),
    );
    expect(
      bubble.unsupportedReasons,
      isNot(contains('unsupported_mechanic:probabilistic_modify_stats')),
    );

    final bubbleBeam = _move(catalog, 'bubble_beam');
    expect(
      bubbleBeam.engineSupportLevel,
      equals(PokemonMoveEngineSupportLevel.structuredSupported),
    );
    expect(
      bubbleBeam.unsupportedReasons,
      isNot(contains('unsupported_mechanic:probabilistic_modify_stats')),
    );
  });

  test(
      'keeps unsupported probabilistic stat riders partial when the affected stat still exceeds the local battle contract',
      () {
    final catalog = converter.convert(<String, dynamic>{
      'sandveil_burst': <String, dynamic>{
        'name': 'Sandveil Burst',
        'type': 'Ground',
        'category': 'Special',
        'basePower': 50,
        'accuracy': 100,
        'pp': 15,
        'priority': 0,
        'target': 'normal',
        'secondary': <String, dynamic>{
          'chance': 30,
          'boosts': <String, int>{'accuracy': -1},
        },
        'shortDesc': '30% chance to lower the target Accuracy by 1.',
        'desc': 'A dusty burst may lower the target Accuracy.',
        'gen': 3,
      },
    });

    final move = _move(catalog, 'sandveil_burst');
    expect(
      move.effects,
      contains(
        const PokemonMoveEffect.modifyStats(
          chance: 30,
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.accuracy,
              stages: -1,
            ),
          ],
        ),
      ),
    );
    expect(
      move.engineSupportLevel,
      equals(PokemonMoveEngineSupportLevel.structuredPartial),
    );
    expect(
      move.unsupportedReasons,
      contains('unsupported_mechanic:probabilistic_modify_stats'),
    );
  });

  test('tracks callbacks and downgrades support level honestly', () {
    final catalog = converter.convert(<String, dynamic>{
      'thunder': <String, dynamic>{
        'name': 'Thunder',
        'type': 'Electric',
        'category': 'Special',
        'basePower': 110,
        'accuracy': 70,
        'pp': 10,
        'priority': 0,
        'target': 'normal',
        'secondary': <String, dynamic>{
          'chance': 30,
          'status': 'par',
        },
        'onModifyMove': () {},
        'shortDesc': 'May paralyze the target. Accuracy changes in weather.',
        'desc': 'A wicked thunderbolt is dropped on the target.',
        'gen': 1,
      },
      'weatherball': <String, dynamic>{
        'name': 'Weather Ball',
        'type': 'Normal',
        'category': 'Special',
        'basePower': 50,
        'accuracy': 100,
        'pp': 10,
        'priority': 0,
        'target': 'normal',
        'basePowerCallback': () => 100,
        'shortDesc': 'Power and type change based on the weather.',
        'desc':
            'An attack move that varies in power and type depending on the weather.',
        'gen': 3,
      },
      'mysterymove': <String, dynamic>{
        'name': 'Mystery Move',
        'type': 'Normal',
        'category': 'Physical',
        'basePower': 40,
        'accuracy': 100,
        'pp': 15,
        'priority': 0,
        'target': 'normal',
        'flags': <String, int>{'mystery': 1},
        'shortDesc': 'Unsupported test move.',
        'desc': 'A move used to prove unknown flags are not ignored.',
        'gen': 9,
      },
    });

    final thunder = _move(catalog, 'thunder');
    expect(
      thunder.sourceRefs.showdownHooksPresent,
      contains('onModifyMove'),
    );
    expect(
      thunder.unsupportedReasons,
      contains('showdown_callback:onModifyMove'),
    );
    expect(
      thunder.engineSupportLevel,
      PokemonMoveEngineSupportLevel.structuredPartial,
    );

    final weatherBall = _move(catalog, 'weather_ball');
    expect(
      weatherBall.sourceRefs.showdownHooksPresent,
      contains('basePowerCallback'),
    );
    expect(
      weatherBall.unsupportedReasons,
      contains('showdown_callback:basePowerCallback'),
    );
    expect(
      weatherBall.engineSupportLevel,
      PokemonMoveEngineSupportLevel.catalogOnly,
    );

    final mysteryMove = _move(catalog, 'mystery_move');
    expect(
      mysteryMove.unsupportedReasons,
      contains('unknown_flag:mystery'),
    );
    expect(
      mysteryMove.engineSupportLevel,
      PokemonMoveEngineSupportLevel.structuredPartial,
    );
  });

  test(
      'converts fixed damage and keeps charge-based moves honest without fabricating effects',
      () {
    final catalog = converter.convert(<String, dynamic>{
      'sonicboom': <String, dynamic>{
        'name': 'Sonic Boom',
        'type': 'Normal',
        'category': 'Special',
        'basePower': 0,
        'damage': 20,
        'accuracy': 90,
        'pp': 20,
        'priority': 0,
        'target': 'normal',
        'shortDesc': 'Always does 20 HP of damage.',
        'desc': 'The target is hit with a destructive shock wave.',
        'gen': 1,
      },
      'solarbeam': <String, dynamic>{
        'name': 'Solar Beam',
        'type': 'Grass',
        'category': 'Special',
        'basePower': 120,
        'accuracy': 100,
        'pp': 10,
        'priority': 0,
        'target': 'normal',
        'flags': <String, int>{'charge': 1, 'protect': 1},
        'condition': <String, dynamic>{'duration': 2},
        'onTryMove': () {},
        'shortDesc': 'Charges on the first turn, attacks on the second.',
        'desc': 'In this two-turn attack, the user gathers light, then blasts.',
        'gen': 1,
      },
    });

    final sonicBoom = _move(catalog, 'sonic_boom');
    expect(
      sonicBoom.effects,
      contains(
        const PokemonMoveEffect.fixedDamage(value: 20),
      ),
    );

    final solarBeam = _move(catalog, 'solar_beam');
    expect(
      solarBeam.unsupportedReasons,
      contains('unsupported_mechanic:charge_then_strike'),
    );
    expect(
      solarBeam.sourceRefs.showdownHooksPresent,
      contains('onTryMove'),
    );
    expect(
      solarBeam.engineSupportLevel,
      PokemonMoveEngineSupportLevel.catalogOnly,
    );
    expect(
      solarBeam.effects.map((effect) => effect.toJson()['kind']),
      isNot(contains('charge_then_strike')),
    );
  });

  test('converts self switch, force switch, recharge and canonical json safely',
      () {
    final catalog = converter.convert(<String, dynamic>{
      'uturn': <String, dynamic>{
        'name': 'U-turn',
        'type': 'Bug',
        'category': 'Physical',
        'basePower': 70,
        'accuracy': 100,
        'pp': 20,
        'priority': 0,
        'target': 'normal',
        'selfSwitch': true,
        'shortDesc': 'User switches out after damaging the target.',
        'desc': 'After making its attack, the user rushes back.',
        'gen': 4,
      },
      'roar': <String, dynamic>{
        'name': 'Roar',
        'type': 'Normal',
        'category': 'Status',
        'basePower': 0,
        'accuracy': true,
        'pp': 20,
        'priority': -6,
        'target': 'normal',
        'forceSwitch': true,
        'shortDesc': 'Forces the target to switch to a random ally.',
        'desc': 'The target is scared off and replaced.',
        'gen': 1,
      },
      'hyperbeam': <String, dynamic>{
        'name': 'Hyper Beam',
        'type': 'Normal',
        'category': 'Special',
        'basePower': 150,
        'accuracy': 90,
        'pp': 5,
        'priority': 0,
        'target': 'normal',
        'flags': <String, int>{'recharge': 1, 'protect': 1},
        'self': <String, dynamic>{'volatileStatus': 'mustrecharge'},
        'shortDesc': 'User must recharge next turn.',
        'desc': 'The target is attacked with a powerful beam.',
        'gen': 1,
      },
    });

    final uTurn = _move(catalog, 'u_turn');
    expect(
      uTurn.effects,
      contains(const PokemonMoveEffect.selfSwitch()),
    );

    final roar = _move(catalog, 'roar');
    expect(
      roar.effects,
      contains(const PokemonMoveEffect.forceSwitch()),
    );

    final hyperBeam = _move(catalog, 'hyper_beam');
    expect(
      hyperBeam.effects,
      contains(const PokemonMoveEffect.requireRecharge()),
    );

    for (final entry in catalog.entries) {
      expect(() => PokemonMove.fromJson(entry), returnsNormally);
    }
  });
}

PokemonMove _move(PokemonCatalogFile catalog, String id) {
  final entry = catalog.entries.firstWhere((entry) => entry['id'] == id);
  return PokemonMove.fromJson(entry);
}
