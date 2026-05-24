import 'package:map_battle/src/data/generated/psdk_move_registry_manifest.dart';
import 'package:map_battle/src/data/psdk_attack_coverage_report.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK attack coverage report', () {
    test('classifies Studio moves from their battle engine method status', () {
      final report = generatePsdkAttackCoverageReport(
        moves: const <PsdkStudioMoveCoverageEntry>[
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'done_move',
            battleEngineMethod: 's_done',
            type: 'normal',
            category: 'physical',
            power: 40,
            accuracy: '100',
            pp: 35,
            sourceFile: 'done.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'partial_move',
            battleEngineMethod: 's_partial',
            type: 'water',
            category: 'status',
            power: 0,
            accuracy: 'always',
            pp: 20,
            sourceFile: 'partial.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'missing_move',
            battleEngineMethod: 's_missing',
            type: 'grass',
            category: 'special',
            power: 80,
            accuracy: '90',
            pp: 10,
            sourceFile: 'missing.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'unknown|move',
            battleEngineMethod: 's_unknown',
            type: 'ghost',
            category: 'status',
            power: 0,
            accuracy: '0',
            pp: 5,
            sourceFile: 'unknown.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'z_move',
            battleEngineMethod: 's_z_move',
            type: 'electric',
            category: 'physical',
            power: 210,
            accuracy: '0',
            pp: 1,
            sourceFile: 'z_move.json',
          ),
        ],
        manifest: const <PsdkMoveRegistryManifestEntry>[
          PsdkMoveRegistryManifestEntry(
            battleEngineMethod: 's_done',
            rubyClass: 'Done',
            rubyPath: 'done.rb',
            dartBehavior: 'DoneBehavior',
            status: PsdkPortStatus.ported,
          ),
          PsdkMoveRegistryManifestEntry(
            battleEngineMethod: 's_partial',
            rubyClass: 'Partial',
            rubyPath: 'partial.rb',
            dartBehavior: 'PartialBehavior',
            status: PsdkPortStatus.partial,
          ),
          PsdkMoveRegistryManifestEntry(
            battleEngineMethod: 's_missing',
            rubyClass: 'Missing',
            rubyPath: 'missing.rb',
            dartBehavior: 'TODO',
            status: PsdkPortStatus.missing,
          ),
        ],
        sourceDescription: 'test moves',
      );

      expect(report, contains('| total_attacks | 5 |'));
      expect(report, contains('| fait | 1 |'));
      expect(report, contains('| partiel | 2 |'));
      expect(report, contains('| pas_fait | 2 |'));
      expect(report, contains('| unknown_methods | 1 |'));
      expect(
        report,
        contains('| pas_fait | unknown\\|move | s_unknown | unknown_method |'),
      );
      expect(
        report,
        contains(
          '| partiel | z_move | s_z_move | ported | StaticBasicMoveRegistry.s_z_move |',
        ),
      );
    });

    test('scopes ported s_basic coverage to supported damage riders', () {
      final report = generatePsdkAttackCoverageReport(
        moves: const <PsdkStudioMoveCoverageEntry>[
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'mega_punch',
            battleEngineMethod: 's_basic',
            type: 'normal',
            category: 'physical',
            power: 80,
            accuracy: '85',
            pp: 20,
            priority: 0,
            criticalRate: 1,
            sourceFile: 'mega_punch.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'liquidation',
            battleEngineMethod: 's_basic',
            type: 'water',
            category: 'physical',
            power: 85,
            accuracy: '100',
            pp: 10,
            priority: 0,
            criticalRate: 1,
            effectChance: 20,
            battleStageModCount: 1,
            battleStageMods: <PsdkStudioStageModCoverageEntry>[
              PsdkStudioStageModCoverageEntry(
                stat: 'defense',
                stages: -1,
              ),
            ],
            sourceFile: 'liquidation.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'fire_punch',
            battleEngineMethod: 's_basic',
            type: 'fire',
            category: 'physical',
            power: 75,
            accuracy: '100',
            pp: 15,
            priority: 0,
            criticalRate: 1,
            effectChance: 10,
            moveStatusCount: 1,
            moveStatuses: <PsdkStudioStatusCoverageEntry>[
              PsdkStudioStatusCoverageEntry(status: 'burn'),
            ],
            sourceFile: 'fire_punch.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'bite',
            battleEngineMethod: 's_basic',
            type: 'dark',
            category: 'physical',
            power: 60,
            accuracy: '100',
            pp: 25,
            priority: 0,
            criticalRate: 1,
            effectChance: 30,
            moveStatusCount: 1,
            moveStatuses: <PsdkStudioStatusCoverageEntry>[
              PsdkStudioStatusCoverageEntry(status: 'flinch'),
            ],
            sourceFile: 'bite.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'confusion',
            battleEngineMethod: 's_basic',
            type: 'psychic',
            category: 'special',
            power: 50,
            accuracy: '100',
            pp: 25,
            priority: 0,
            criticalRate: 1,
            effectChance: 10,
            moveStatusCount: 1,
            moveStatuses: <PsdkStudioStatusCoverageEntry>[
              PsdkStudioStatusCoverageEntry(status: 'confusion'),
            ],
            sourceFile: 'confusion.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'chatter',
            battleEngineMethod: 's_basic',
            type: 'flying',
            category: 'special',
            power: 65,
            accuracy: '100',
            pp: 20,
            priority: 0,
            criticalRate: 1,
            effectChance: 100,
            moveStatusCount: 1,
            moveStatuses: <PsdkStudioStatusCoverageEntry>[
              PsdkStudioStatusCoverageEntry(status: 'confusion'),
            ],
            sourceFile: 'chatter.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'blizzard',
            battleEngineMethod: 's_basic',
            type: 'ice',
            category: 'special',
            power: 110,
            accuracy: '70',
            pp: 5,
            priority: 0,
            criticalRate: 1,
            effectChance: 10,
            moveStatusCount: 1,
            moveStatuses: <PsdkStudioStatusCoverageEntry>[
              PsdkStudioStatusCoverageEntry(status: 'freeze'),
            ],
            target: 'adjacent_all_foe',
            sourceFile: 'blizzard.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'mud_slap',
            battleEngineMethod: 's_basic',
            type: 'ground',
            category: 'special',
            power: 20,
            accuracy: '100',
            pp: 10,
            priority: 0,
            criticalRate: 1,
            effectChance: 100,
            battleStageModCount: 1,
            battleStageMods: <PsdkStudioStageModCoverageEntry>[
              PsdkStudioStageModCoverageEntry(stat: 'accuracy', stages: -1),
            ],
            sourceFile: 'mud_slap.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'discharge',
            battleEngineMethod: 's_basic',
            type: 'electric',
            category: 'special',
            power: 80,
            accuracy: '100',
            pp: 15,
            priority: 0,
            criticalRate: 1,
            effectChance: 30,
            moveStatusCount: 1,
            moveStatuses: <PsdkStudioStatusCoverageEntry>[
              PsdkStudioStatusCoverageEntry(status: 'paralysis'),
            ],
            target: 'adjacent_all_pokemon',
            sourceFile: 'discharge.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'bulldoze',
            battleEngineMethod: 's_basic',
            type: 'ground',
            category: 'physical',
            power: 60,
            accuracy: '100',
            pp: 20,
            priority: 0,
            criticalRate: 1,
            effectChance: 100,
            battleStageModCount: 1,
            battleStageMods: <PsdkStudioStageModCoverageEntry>[
              PsdkStudioStageModCoverageEntry(stat: 'speed', stages: -1),
            ],
            target: 'adjacent_all_pokemon',
            sourceFile: 'bulldoze.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'secret_sword',
            battleEngineMethod: 's_basic',
            type: 'fighting',
            category: 'special',
            power: 85,
            accuracy: '100',
            pp: 10,
            priority: 0,
            criticalRate: 1,
            effectChance: 100,
            target: 'adjacent_pokemon',
            sourceFile: 'secret_sword.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'growl_like_bad_data',
            battleEngineMethod: 's_basic',
            type: 'normal',
            category: 'status',
            power: 0,
            accuracy: '100',
            pp: 40,
            priority: 0,
            criticalRate: 1,
            sourceFile: 'growl_like_bad_data.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'flash',
            battleEngineMethod: 's_basic',
            type: 'normal',
            category: 'status',
            power: 0,
            accuracy: '100',
            pp: 20,
            priority: 0,
            criticalRate: 1,
            effectChance: 100,
            battleStageModCount: 1,
            battleStageMods: <PsdkStudioStageModCoverageEntry>[
              PsdkStudioStageModCoverageEntry(
                stat: 'accuracy',
                stages: -1,
              ),
            ],
            sourceFile: 'flash.json',
          ),
        ],
        manifest: const <PsdkMoveRegistryManifestEntry>[
          PsdkMoveRegistryManifestEntry(
            battleEngineMethod: 's_basic',
            rubyClass: 'Basic',
            rubyPath: 'basic.rb',
            dartBehavior: 'StaticBasicMoveRegistry.s_basic',
            status: PsdkPortStatus.ported,
          ),
        ],
        sourceDescription: 's_basic test moves',
      );

      expect(report, contains('| fait | 11 |'));
      expect(report, contains('| partiel | 2 |'));
      expect(
        report,
        contains('| fait | mega_punch | s_basic | ported |'),
      );
      expect(
        report,
        contains('| fait | liquidation | s_basic | ported |'),
      );
      expect(
        report,
        contains('| fait | fire_punch | s_basic | ported |'),
      );
      expect(
        report,
        contains('| fait | bite | s_basic | ported |'),
      );
      expect(
        report,
        contains('| fait | confusion | s_basic | ported |'),
      );
      expect(
        report,
        contains('| fait | chatter | s_basic | ported |'),
      );
      expect(
        report,
        contains('| fait | blizzard | s_basic | ported |'),
      );
      expect(
        report,
        contains('| fait | mud_slap | s_basic | ported |'),
      );
      expect(
        report,
        contains('| fait | discharge | s_basic | ported |'),
      );
      expect(
        report,
        contains('| fait | bulldoze | s_basic | ported |'),
      );
      expect(
        report,
        contains('| fait | secret_sword | s_basic | ported |'),
      );
      expect(
        report,
        contains('| partiel | growl_like_bad_data | s_basic | ported |'),
      );
      expect(
        report,
        contains('| partiel | flash | s_basic | ported |'),
      );
    });

    test('classifies generic Studio Z-Move placeholders as strict s_basic', () {
      final report = generatePsdkAttackCoverageReport(
        moves: const <PsdkStudioMoveCoverageEntry>[
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'breakneck_blitz',
            battleEngineMethod: 's_basic',
            type: 'normal',
            category: 'physical',
            power: 0,
            accuracy: '0',
            pp: 1,
            target: 'adjacent_pokemon',
            protectable: false,
            kingRockUtility: true,
            sourceFile: 'breakneck_blitz.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'breakneck_blitz2',
            battleEngineMethod: 's_basic',
            type: 'normal',
            category: 'special',
            power: 0,
            accuracy: '0',
            pp: 1,
            target: 'adjacent_pokemon',
            protectable: false,
            kingRockUtility: true,
            sourceFile: 'breakneck_blitz2.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'zero_power_basic_not_z',
            battleEngineMethod: 's_basic',
            type: 'normal',
            category: 'physical',
            power: 0,
            accuracy: '0',
            pp: 1,
            target: 'adjacent_pokemon',
            sourceFile: 'zero_power_basic_not_z.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'breakneck_blitz',
            battleEngineMethod: 's_basic',
            type: 'fire',
            category: 'physical',
            power: 0,
            accuracy: '0',
            pp: 1,
            target: 'adjacent_pokemon',
            protectable: false,
            kingRockUtility: true,
            sourceFile: 'breakneck_blitz_bad_shape.json',
          ),
        ],
        manifest: const <PsdkMoveRegistryManifestEntry>[
          PsdkMoveRegistryManifestEntry(
            battleEngineMethod: 's_basic',
            rubyClass: 'Basic',
            rubyPath: 'basic.rb',
            dartBehavior: 'StaticBasicMoveRegistry.s_basic',
            status: PsdkPortStatus.ported,
          ),
        ],
        sourceDescription: 'generic Studio Z-Move placeholders',
      );

      expect(report, contains('| fait | 2 |'));
      expect(report, contains('| partiel | 2 |'));
      expect(
        report,
        contains('| fait | breakneck_blitz | s_basic | ported |'),
      );
      expect(
        report,
        contains('| fait | breakneck_blitz2 | s_basic | ported |'),
      );
      expect(
        report,
        contains(
          '| partiel | zero_power_basic_not_z | s_basic | ported |',
        ),
      );
      expect(
        report,
        contains(
          '| partiel | breakneck_blitz | s_basic | ported | '
          'StaticBasicMoveRegistry.s_basic | fire | physical | 0 | 0 | 1 | '
          'breakneck_blitz_bad_shape.json |',
        ),
      );
    });

    test('classifies offensive signature Studio Z-Moves as strict s_z_move',
        () {
      final report = generatePsdkAttackCoverageReport(
        moves: const <PsdkStudioMoveCoverageEntry>[
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'catastropika',
            battleEngineMethod: 's_z_move',
            type: 'electric',
            category: 'physical',
            power: 210,
            accuracy: '0',
            pp: 1,
            criticalRate: 1,
            target: 'adjacent_pokemon',
            protectable: false,
            kingRockUtility: true,
            sourceFile: 'catastropika.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'let_s_snuggle_forever',
            battleEngineMethod: 's_z_move',
            type: 'fairy',
            category: 'physical',
            power: 190,
            accuracy: '0',
            pp: 1,
            criticalRate: 1,
            target: 'adjacent_pokemon',
            protectable: false,
            kingRockUtility: true,
            sourceFile: 'let_s_snuggle_forever.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'menacing_moonraze_maelstrom',
            battleEngineMethod: 's_z_move',
            type: 'ghost',
            category: 'special',
            power: 200,
            accuracy: '0',
            pp: 1,
            criticalRate: 1,
            target: 'adjacent_pokemon',
            protectable: false,
            kingRockUtility: true,
            sourceFile: 'menacing_moonraze_maelstrom.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'oceanic_operetta',
            battleEngineMethod: 's_z_move',
            type: 'water',
            category: 'special',
            power: 195,
            accuracy: '0',
            pp: 1,
            criticalRate: 1,
            target: 'adjacent_pokemon',
            protectable: false,
            kingRockUtility: true,
            sourceFile: 'oceanic_operetta.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'pulverizing_pancake',
            battleEngineMethod: 's_z_move',
            type: 'normal',
            category: 'physical',
            power: 210,
            accuracy: '0',
            pp: 1,
            criticalRate: 1,
            target: 'adjacent_pokemon',
            protectable: false,
            kingRockUtility: true,
            sourceFile: 'pulverizing_pancake.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 's10_000_000_volt_thunderbolt',
            battleEngineMethod: 's_z_move',
            type: 'electric',
            category: 'special',
            power: 195,
            accuracy: '0',
            pp: 1,
            criticalRate: 3,
            target: 'adjacent_pokemon',
            protectable: false,
            kingRockUtility: true,
            sourceFile: 's10_000_000_volt_thunderbolt.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'searing_sunraze_smash',
            battleEngineMethod: 's_z_move',
            type: 'steel',
            category: 'physical',
            power: 200,
            accuracy: '0',
            pp: 1,
            criticalRate: 1,
            target: 'user',
            protectable: false,
            kingRockUtility: true,
            sourceFile: 'searing_sunraze_smash.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'sinister_arrow_raid',
            battleEngineMethod: 's_z_move',
            type: 'ghost',
            category: 'physical',
            power: 180,
            accuracy: '0',
            pp: 1,
            criticalRate: 1,
            target: 'adjacent_pokemon',
            protectable: false,
            kingRockUtility: true,
            sourceFile: 'sinister_arrow_raid.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'soul_stealing_7_star_strike',
            battleEngineMethod: 's_z_move',
            type: 'ghost',
            category: 'physical',
            power: 195,
            accuracy: '0',
            pp: 1,
            criticalRate: 1,
            target: 'adjacent_pokemon',
            protectable: false,
            kingRockUtility: true,
            sourceFile: 'soul_stealing_7_star_strike.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'stoked_sparksurfer',
            battleEngineMethod: 's_z_move',
            type: 'electric',
            category: 'special',
            power: 175,
            accuracy: '0',
            pp: 1,
            criticalRate: 1,
            effectChance: 100,
            moveStatusCount: 1,
            moveStatuses: <PsdkStudioStatusCoverageEntry>[
              PsdkStudioStatusCoverageEntry(status: 'paralysis'),
            ],
            target: 'adjacent_pokemon',
            protectable: false,
            kingRockUtility: true,
            sourceFile: 'stoked_sparksurfer.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'stoked_sparksurfer',
            battleEngineMethod: 's_z_move',
            type: 'electric',
            category: 'special',
            power: 175,
            accuracy: '0',
            pp: 1,
            criticalRate: 1,
            effectChance: 0,
            target: 'adjacent_pokemon',
            protectable: false,
            kingRockUtility: true,
            sourceFile: 'stoked_sparksurfer_bad_shape.json',
          ),
        ],
        manifest: const <PsdkMoveRegistryManifestEntry>[],
        sourceDescription: 'offensive signature Studio Z-Moves',
      );

      expect(report, contains('| fait | 10 |'));
      expect(report, contains('| partiel | 1 |'));
      expect(report, contains('| fait | catastropika | s_z_move | ported |'));
      expect(
        report,
        contains(
          '| fait | s10_000_000_volt_thunderbolt | s_z_move | ported |',
        ),
      );
      expect(
        report,
        contains('| fait | stoked_sparksurfer | s_z_move | ported |'),
      );
      expect(
        report,
        contains(
          '| partiel | stoked_sparksurfer | s_z_move | ported | '
          'StaticBasicMoveRegistry.s_z_move | electric | special | 175 | 0 | '
          '1 | stoked_sparksurfer_bad_shape.json |',
        ),
      );
    });

    test('scopes ported s_self_stat coverage to strict self boosts', () {
      final report = generatePsdkAttackCoverageReport(
        moves: const <PsdkStudioMoveCoverageEntry>[
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'calm_mind',
            battleEngineMethod: 's_self_stat',
            type: 'psychic',
            category: 'status',
            power: 0,
            accuracy: '0',
            pp: 20,
            effectChance: 100,
            battleStageModCount: 2,
            battleStageMods: <PsdkStudioStageModCoverageEntry>[
              PsdkStudioStageModCoverageEntry(
                stat: 'specialAttack',
                stages: 1,
              ),
              PsdkStudioStageModCoverageEntry(
                stat: 'specialDefense',
                stages: 1,
              ),
            ],
            target: 'user',
            sourceFile: 'calm_mind.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'hone_claws',
            battleEngineMethod: 's_self_stat',
            type: 'dark',
            category: 'status',
            power: 0,
            accuracy: '0',
            pp: 15,
            effectChance: 100,
            battleStageModCount: 2,
            battleStageMods: <PsdkStudioStageModCoverageEntry>[
              PsdkStudioStageModCoverageEntry(stat: 'attack', stages: 1),
              PsdkStudioStageModCoverageEntry(stat: 'accuracy', stages: 1),
            ],
            target: 'user',
            sourceFile: 'hone_claws.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'power_up_punch',
            battleEngineMethod: 's_self_stat',
            type: 'fighting',
            category: 'physical',
            power: 40,
            accuracy: '100',
            pp: 20,
            effectChance: 100,
            battleStageModCount: 1,
            battleStageMods: <PsdkStudioStageModCoverageEntry>[
              PsdkStudioStageModCoverageEntry(stat: 'attack', stages: 1),
            ],
            target: 'adjacent_foe',
            sourceFile: 'power_up_punch.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'clanging_scales',
            battleEngineMethod: 's_self_stat',
            type: 'dragon',
            category: 'special',
            power: 110,
            accuracy: '100',
            pp: 5,
            effectChance: 100,
            battleStageModCount: 1,
            battleStageMods: <PsdkStudioStageModCoverageEntry>[
              PsdkStudioStageModCoverageEntry(stat: 'defense', stages: -1),
            ],
            target: 'adjacent_all_foe',
            sourceFile: 'clanging_scales.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'diamond_storm',
            battleEngineMethod: 's_self_stat',
            type: 'rock',
            category: 'physical',
            power: 100,
            accuracy: '95',
            pp: 5,
            effectChance: 50,
            battleStageModCount: 1,
            battleStageMods: <PsdkStudioStageModCoverageEntry>[
              PsdkStudioStageModCoverageEntry(stat: 'defense', stages: 2),
            ],
            target: 'adjacent_all_foe',
            sourceFile: 'diamond_storm.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'shell_smash',
            battleEngineMethod: 's_self_stat',
            type: 'normal',
            category: 'status',
            power: 0,
            accuracy: '0',
            pp: 15,
            effectChance: 100,
            battleStageModCount: 5,
            battleStageMods: <PsdkStudioStageModCoverageEntry>[
              PsdkStudioStageModCoverageEntry(stat: 'attack', stages: 2),
              PsdkStudioStageModCoverageEntry(stat: 'defense', stages: -1),
              PsdkStudioStageModCoverageEntry(stat: 'speed', stages: 2),
              PsdkStudioStageModCoverageEntry(
                stat: 'specialAttack',
                stages: 2,
              ),
              PsdkStudioStageModCoverageEntry(
                stat: 'specialDefense',
                stages: -1,
              ),
            ],
            target: 'user',
            sourceFile: 'shell_smash.json',
          ),
        ],
        manifest: const <PsdkMoveRegistryManifestEntry>[
          PsdkMoveRegistryManifestEntry(
            battleEngineMethod: 's_self_stat',
            rubyClass: 'SelfStat',
            rubyPath: 'self.rb',
            dartBehavior: 'StatusStatMoveBehavior.selfStat',
            status: PsdkPortStatus.ported,
          ),
        ],
        sourceDescription: 's_self_stat test moves',
      );

      expect(report, contains('| fait | 6 |'));
      expect(report, contains('| partiel | 0 |'));
      expect(report, contains('| fait | calm_mind | s_self_stat | ported |'));
      expect(
        report,
        contains('| fait | hone_claws | s_self_stat | ported |'),
      );
      expect(
        report,
        contains('| fait | power_up_punch | s_self_stat | ported |'),
      );
      expect(
        report,
        contains('| fait | clanging_scales | s_self_stat | ported |'),
      );
      expect(
        report,
        contains('| fait | diamond_storm | s_self_stat | ported |'),
      );
      expect(
        report,
        contains('| fait | shell_smash | s_self_stat | ported |'),
      );
    });

    test('scopes ported s_stat coverage to strict target stat changes', () {
      final report = generatePsdkAttackCoverageReport(
        moves: const <PsdkStudioMoveCoverageEntry>[
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'tail_whip',
            battleEngineMethod: 's_stat',
            type: 'normal',
            category: 'status',
            power: 0,
            accuracy: '100',
            pp: 30,
            effectChance: 100,
            battleStageModCount: 1,
            battleStageMods: <PsdkStudioStageModCoverageEntry>[
              PsdkStudioStageModCoverageEntry(stat: 'defense', stages: -1),
            ],
            target: 'adjacent_all_foe',
            sourceFile: 'tail_whip.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'swords_dance',
            battleEngineMethod: 's_stat',
            type: 'normal',
            category: 'status',
            power: 0,
            accuracy: '0',
            pp: 20,
            effectChance: 100,
            battleStageModCount: 1,
            battleStageMods: <PsdkStudioStageModCoverageEntry>[
              PsdkStudioStageModCoverageEntry(stat: 'attack', stages: 2),
            ],
            target: 'user',
            sourceFile: 'swords_dance.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'sand_attack',
            battleEngineMethod: 's_stat',
            type: 'ground',
            category: 'status',
            power: 0,
            accuracy: '100',
            pp: 15,
            effectChance: 100,
            battleStageModCount: 1,
            battleStageMods: <PsdkStudioStageModCoverageEntry>[
              PsdkStudioStageModCoverageEntry(stat: 'accuracy', stages: -1),
            ],
            target: 'adjacent_pokemon',
            sourceFile: 'sand_attack.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'swagger',
            battleEngineMethod: 's_stat',
            type: 'normal',
            category: 'status',
            power: 0,
            accuracy: '85',
            pp: 15,
            effectChance: 100,
            battleStageModCount: 1,
            battleStageMods: <PsdkStudioStageModCoverageEntry>[
              PsdkStudioStageModCoverageEntry(stat: 'attack', stages: 2),
            ],
            moveStatusCount: 1,
            moveStatuses: <PsdkStudioStatusCoverageEntry>[
              PsdkStudioStatusCoverageEntry(status: 'confusion'),
            ],
            target: 'adjacent_pokemon',
            sourceFile: 'swagger.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'flatter',
            battleEngineMethod: 's_stat',
            type: 'dark',
            category: 'status',
            power: 0,
            accuracy: '100',
            pp: 15,
            effectChance: 100,
            battleStageModCount: 1,
            battleStageMods: <PsdkStudioStageModCoverageEntry>[
              PsdkStudioStageModCoverageEntry(
                stat: 'specialAttack',
                stages: 1,
              ),
            ],
            moveStatusCount: 1,
            moveStatuses: <PsdkStudioStatusCoverageEntry>[
              PsdkStudioStatusCoverageEntry(status: 'confusion'),
            ],
            target: 'adjacent_pokemon',
            sourceFile: 'flatter.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'aromatic_mist',
            battleEngineMethod: 's_stat',
            type: 'fairy',
            category: 'status',
            power: 0,
            accuracy: '0',
            pp: 20,
            effectChance: 0,
            battleStageModCount: 1,
            battleStageMods: <PsdkStudioStageModCoverageEntry>[
              PsdkStudioStageModCoverageEntry(
                stat: 'specialDefense',
                stages: 1,
              ),
            ],
            target: 'adjacent_ally',
            sourceFile: 'aromatic_mist.json',
          ),
        ],
        manifest: const <PsdkMoveRegistryManifestEntry>[
          PsdkMoveRegistryManifestEntry(
            battleEngineMethod: 's_stat',
            rubyClass: 'StatusStat',
            rubyPath: 'status_stat.rb',
            dartBehavior: 'StatusStatMoveBehavior.stat',
            status: PsdkPortStatus.ported,
          ),
        ],
        sourceDescription: 's_stat test moves',
      );

      expect(report, contains('| fait | 6 |'));
      expect(report, contains('| partiel | 0 |'));
      expect(report, contains('| fait | tail_whip | s_stat | ported |'));
      expect(report, contains('| fait | swords_dance | s_stat | ported |'));
      expect(report, contains('| fait | sand_attack | s_stat | ported |'));
      expect(report, contains('| fait | swagger | s_stat | ported |'));
      expect(report, contains('| fait | flatter | s_stat | ported |'));
      expect(report, contains('| fait | aromatic_mist | s_stat | ported |'));
    });

    test('scopes ported s_status coverage to strict major statuses', () {
      final report = generatePsdkAttackCoverageReport(
        moves: const <PsdkStudioMoveCoverageEntry>[
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'thunder_wave',
            battleEngineMethod: 's_status',
            type: 'electric',
            category: 'status',
            power: 0,
            accuracy: '90',
            pp: 20,
            effectChance: 100,
            moveStatusCount: 1,
            moveStatuses: <PsdkStudioStatusCoverageEntry>[
              PsdkStudioStatusCoverageEntry(status: 'paralysis'),
            ],
            target: 'adjacent_pokemon',
            sourceFile: 'thunder_wave.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'toxic',
            battleEngineMethod: 's_status',
            type: 'poison',
            category: 'status',
            power: 0,
            accuracy: '90',
            pp: 10,
            effectChance: 100,
            moveStatusCount: 1,
            moveStatuses: <PsdkStudioStatusCoverageEntry>[
              PsdkStudioStatusCoverageEntry(status: 'toxic'),
            ],
            target: 'adjacent_pokemon',
            sourceFile: 'toxic.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'confuse_ray',
            battleEngineMethod: 's_status',
            type: 'ghost',
            category: 'status',
            power: 0,
            accuracy: '100',
            pp: 10,
            effectChance: 100,
            moveStatusCount: 1,
            moveStatuses: <PsdkStudioStatusCoverageEntry>[
              PsdkStudioStatusCoverageEntry(status: 'confusion'),
            ],
            target: 'adjacent_pokemon',
            sourceFile: 'confuse_ray.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'teeter_dance',
            battleEngineMethod: 's_status',
            type: 'normal',
            category: 'status',
            power: 0,
            accuracy: '100',
            pp: 20,
            effectChance: 100,
            moveStatusCount: 1,
            moveStatuses: <PsdkStudioStatusCoverageEntry>[
              PsdkStudioStatusCoverageEntry(status: 'confusion'),
            ],
            target: 'adjacent_all_pokemon',
            sourceFile: 'teeter_dance.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'poison_sting_like_bad_data',
            battleEngineMethod: 's_status',
            type: 'poison',
            category: 'physical',
            power: 15,
            accuracy: '100',
            pp: 35,
            effectChance: 100,
            moveStatusCount: 1,
            moveStatuses: <PsdkStudioStatusCoverageEntry>[
              PsdkStudioStatusCoverageEntry(status: 'poison'),
            ],
            target: 'adjacent_pokemon',
            sourceFile: 'poison_sting_like_bad_data.json',
          ),
        ],
        manifest: const <PsdkMoveRegistryManifestEntry>[
          PsdkMoveRegistryManifestEntry(
            battleEngineMethod: 's_status',
            rubyClass: 'StatusStat',
            rubyPath: 'status_stat.rb',
            dartBehavior: 'StatusStatMoveBehavior.status',
            status: PsdkPortStatus.ported,
          ),
        ],
        sourceDescription: 's_status test moves',
      );

      expect(report, contains('| fait | 4 |'));
      expect(report, contains('| partiel | 1 |'));
      expect(report, contains('| fait | thunder_wave | s_status | ported |'));
      expect(report, contains('| fait | toxic | s_status | ported |'));
      expect(report, contains('| fait | confuse_ray | s_status | ported |'));
      expect(report, contains('| fait | teeter_dance | s_status | ported |'));
      expect(
        report,
        contains(
          '| partiel | poison_sting_like_bad_data | s_status | ported |',
        ),
      );
    });

    test('scopes ported s_self_status coverage to local self statuses', () {
      final report = generatePsdkAttackCoverageReport(
        moves: const <PsdkStudioMoveCoverageEntry>[
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'self_poison',
            battleEngineMethod: 's_self_status',
            type: 'poison',
            category: 'status',
            power: 0,
            accuracy: '0',
            pp: 20,
            effectChance: 100,
            moveStatusCount: 1,
            moveStatuses: <PsdkStudioStatusCoverageEntry>[
              PsdkStudioStatusCoverageEntry(status: 'poison'),
            ],
            target: 'adjacent_pokemon',
            sourceFile: 'self_poison.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'self_confuse',
            battleEngineMethod: 's_self_status',
            type: 'ghost',
            category: 'status',
            power: 0,
            accuracy: '0',
            pp: 20,
            effectChance: 100,
            moveStatusCount: 1,
            moveStatuses: <PsdkStudioStatusCoverageEntry>[
              PsdkStudioStatusCoverageEntry(status: 'confusion'),
            ],
            target: 'adjacent_pokemon',
            sourceFile: 'self_confuse.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'self_poison_hit',
            battleEngineMethod: 's_self_status',
            type: 'poison',
            category: 'physical',
            power: 40,
            accuracy: '100',
            pp: 20,
            effectChance: 100,
            moveStatusCount: 1,
            moveStatuses: <PsdkStudioStatusCoverageEntry>[
              PsdkStudioStatusCoverageEntry(status: 'poison'),
            ],
            target: 'adjacent_pokemon',
            sourceFile: 'self_poison_hit.json',
          ),
        ],
        manifest: const <PsdkMoveRegistryManifestEntry>[
          PsdkMoveRegistryManifestEntry(
            battleEngineMethod: 's_self_status',
            rubyClass: 'SelfStatus',
            rubyPath: 'self.rb',
            dartBehavior: 'StatusStatMoveBehavior.selfStatus',
            status: PsdkPortStatus.ported,
          ),
        ],
        sourceDescription: 's_self_status test moves',
      );

      expect(report, contains('| fait | 2 |'));
      expect(report, contains('| partiel | 1 |'));
      expect(
        report,
        contains('| fait | self_poison | s_self_status | ported |'),
      );
      expect(
        report,
        contains('| fait | self_confuse | s_self_status | ported |'),
      );
      expect(
        report,
        contains('| partiel | self_poison_hit | s_self_status | ported |'),
      );
    });

    test('scopes ported s_multi_hit coverage to strict random multi-hits', () {
      final report = generatePsdkAttackCoverageReport(
        moves: const <PsdkStudioMoveCoverageEntry>[
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'double_slap',
            battleEngineMethod: 's_multi_hit',
            type: 'normal',
            category: 'physical',
            power: 15,
            accuracy: '85',
            pp: 10,
            sourceFile: 'double_slap.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'water_shuriken',
            battleEngineMethod: 's_multi_hit',
            type: 'water',
            category: 'special',
            power: 15,
            accuracy: '100',
            pp: 20,
            priority: 1,
            sourceFile: 'water_shuriken.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'double_slap_with_status',
            battleEngineMethod: 's_multi_hit',
            type: 'normal',
            category: 'physical',
            power: 15,
            accuracy: '85',
            pp: 10,
            moveStatusCount: 1,
            moveStatuses: <PsdkStudioStatusCoverageEntry>[
              PsdkStudioStatusCoverageEntry(status: 'paralysis'),
            ],
            sourceFile: 'double_slap_with_status.json',
          ),
        ],
        manifest: const <PsdkMoveRegistryManifestEntry>[
          PsdkMoveRegistryManifestEntry(
            battleEngineMethod: 's_multi_hit',
            rubyClass: 'MultiHit',
            rubyPath: 'multi_hit.rb',
            dartBehavior: 'MultiHitMoveBehavior.psdkRandom',
            status: PsdkPortStatus.ported,
          ),
        ],
        sourceDescription: 's_multi_hit test moves',
      );

      expect(report, contains('| fait | 1 |'));
      expect(report, contains('| partiel | 2 |'));
      expect(report, contains('| fait | double_slap | s_multi_hit | ported |'));
      expect(
        report,
        contains('| partiel | water_shuriken | s_multi_hit | ported |'),
      );
      expect(
        report,
        contains(
          '| partiel | double_slap_with_status | s_multi_hit | ported |',
        ),
      );
    });

    test('scopes ported s_2turns coverage to strict charged damage', () {
      final report = generatePsdkAttackCoverageReport(
        moves: const <PsdkStudioMoveCoverageEntry>[
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'fly',
            battleEngineMethod: 's_2turns',
            type: 'flying',
            category: 'physical',
            power: 90,
            accuracy: '95',
            pp: 15,
            target: 'any_other_pokemon',
            sourceFile: 'fly.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'skull_bash',
            battleEngineMethod: 's_2turns',
            type: 'normal',
            category: 'physical',
            power: 130,
            accuracy: '100',
            pp: 10,
            target: 'adjacent_pokemon',
            sourceFile: 'skull_bash.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'bounce',
            battleEngineMethod: 's_2turns',
            type: 'flying',
            category: 'physical',
            power: 85,
            accuracy: '85',
            pp: 5,
            effectChance: 30,
            moveStatusCount: 1,
            moveStatuses: <PsdkStudioStatusCoverageEntry>[
              PsdkStudioStatusCoverageEntry(status: 'paralysis'),
            ],
            target: 'any_other_pokemon',
            sourceFile: 'bounce.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'razor_wind',
            battleEngineMethod: 's_2turns',
            type: 'normal',
            category: 'special',
            power: 80,
            accuracy: '100',
            pp: 10,
            target: 'adjacent_all_foe',
            sourceFile: 'razor_wind.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'geomancy',
            battleEngineMethod: 's_2turns',
            type: 'fairy',
            category: 'status',
            power: 0,
            accuracy: '0',
            pp: 10,
            battleStageModCount: 3,
            battleStageMods: <PsdkStudioStageModCoverageEntry>[
              PsdkStudioStageModCoverageEntry(
                stat: 'specialAttack',
                stages: 2,
              ),
              PsdkStudioStageModCoverageEntry(
                stat: 'specialDefense',
                stages: 2,
              ),
              PsdkStudioStageModCoverageEntry(stat: 'speed', stages: 2),
            ],
            target: 'user',
            sourceFile: 'geomancy.json',
          ),
        ],
        manifest: const <PsdkMoveRegistryManifestEntry>[
          PsdkMoveRegistryManifestEntry(
            battleEngineMethod: 's_2turns',
            rubyClass: 'TwoTurnBase',
            rubyPath: 'two_turn.rb',
            dartBehavior: 'StaticBasicMoveRegistry.s_2turns',
            status: PsdkPortStatus.ported,
          ),
        ],
        sourceDescription: 's_2turns test moves',
      );

      expect(report, contains('| fait | 5 |'));
      expect(report, contains('| partiel | 0 |'));
      expect(report, contains('| fait | fly | s_2turns | ported |'));
      expect(report, contains('| fait | skull_bash | s_2turns | ported |'));
      expect(report, contains('| fait | bounce | s_2turns | ported |'));
      expect(
        report,
        contains('| fait | razor_wind | s_2turns | ported |'),
      );
      expect(report, contains('| fait | geomancy | s_2turns | ported |'));
    });

    test('scopes ported s_reload coverage to strict recharge damage', () {
      final report = generatePsdkAttackCoverageReport(
        moves: const <PsdkStudioMoveCoverageEntry>[
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'hyper_beam',
            battleEngineMethod: 's_reload',
            type: 'normal',
            category: 'special',
            power: 150,
            accuracy: '90',
            pp: 5,
            target: 'adjacent_pokemon',
            sourceFile: 'hyper_beam.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'reload_status',
            battleEngineMethod: 's_reload',
            type: 'normal',
            category: 'status',
            power: 0,
            accuracy: '100',
            pp: 5,
            target: 'adjacent_pokemon',
            sourceFile: 'reload_status.json',
          ),
        ],
        manifest: const <PsdkMoveRegistryManifestEntry>[
          PsdkMoveRegistryManifestEntry(
            battleEngineMethod: 's_reload',
            rubyClass: 'Reload',
            rubyPath: 'reload.rb',
            dartBehavior: 'StaticBasicMoveRegistry.s_reload',
            status: PsdkPortStatus.ported,
          ),
        ],
        sourceDescription: 's_reload test moves',
      );

      expect(report, contains('| fait | 1 |'));
      expect(report, contains('| partiel | 1 |'));
      expect(report, contains('| fait | hyper_beam | s_reload | ported |'));
      expect(
          report, contains('| partiel | reload_status | s_reload | ported |'));
    });

    test('scopes ported s_recoil coverage to strict recoil damage', () {
      final report = generatePsdkAttackCoverageReport(
        moves: const <PsdkStudioMoveCoverageEntry>[
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'take_down',
            battleEngineMethod: 's_recoil',
            type: 'normal',
            category: 'physical',
            power: 90,
            accuracy: '85',
            pp: 20,
            target: 'adjacent_pokemon',
            sourceFile: 'take_down.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'flare_blitz',
            battleEngineMethod: 's_recoil',
            type: 'fire',
            category: 'physical',
            power: 120,
            accuracy: '100',
            pp: 15,
            effectChance: 10,
            moveStatusCount: 1,
            moveStatuses: <PsdkStudioStatusCoverageEntry>[
              PsdkStudioStatusCoverageEntry(status: 'burn'),
            ],
            target: 'adjacent_pokemon',
            sourceFile: 'flare_blitz.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'mind_blown',
            battleEngineMethod: 's_recoil',
            type: 'fire',
            category: 'special',
            power: 150,
            accuracy: '100',
            pp: 5,
            target: 'adjacent_all_pokemon',
            sourceFile: 'mind_blown.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'light_of_ruin',
            battleEngineMethod: 's_recoil',
            type: 'fairy',
            category: 'special',
            power: 140,
            accuracy: '90',
            pp: 5,
            effectChance: 100,
            target: 'adjacent_pokemon',
            sourceFile: 'light_of_ruin.json',
          ),
        ],
        manifest: const <PsdkMoveRegistryManifestEntry>[
          PsdkMoveRegistryManifestEntry(
            battleEngineMethod: 's_recoil',
            rubyClass: 'RecoilMove',
            rubyPath: 'recoil.rb',
            dartBehavior: 'RecoilMoveBehavior.psdkRecoil',
            status: PsdkPortStatus.ported,
          ),
        ],
        sourceDescription: 's_recoil test moves',
      );

      expect(report, contains('| fait | 4 |'));
      expect(report, contains('| partiel | 0 |'));
      expect(report, contains('| fait | take_down | s_recoil | ported |'));
      expect(report, contains('| fait | flare_blitz | s_recoil | ported |'));
      expect(report, contains('| fait | mind_blown | s_recoil | ported |'));
      expect(
        report,
        contains('| fait | light_of_ruin | s_recoil | ported |'),
      );
    });

    test('scopes ported s_absorb coverage to strict single-target drains', () {
      final report = generatePsdkAttackCoverageReport(
        moves: const <PsdkStudioMoveCoverageEntry>[
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'giga_drain',
            battleEngineMethod: 's_absorb',
            type: 'grass',
            category: 'special',
            power: 75,
            accuracy: '100',
            pp: 10,
            target: 'adjacent_pokemon',
            sourceFile: 'giga_drain.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'parabolic_charge',
            battleEngineMethod: 's_absorb',
            type: 'electric',
            category: 'special',
            power: 65,
            accuracy: '100',
            pp: 20,
            target: 'adjacent_all_pokemon',
            sourceFile: 'parabolic_charge.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'oblivion_wing',
            battleEngineMethod: 's_absorb',
            type: 'flying',
            category: 'special',
            power: 80,
            accuracy: '100',
            pp: 10,
            target: 'all_ally',
            sourceFile: 'oblivion_wing.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'absorb_status',
            battleEngineMethod: 's_absorb',
            type: 'grass',
            category: 'status',
            power: 0,
            accuracy: '100',
            pp: 20,
            target: 'adjacent_pokemon',
            sourceFile: 'absorb_status.json',
          ),
        ],
        manifest: const <PsdkMoveRegistryManifestEntry>[
          PsdkMoveRegistryManifestEntry(
            battleEngineMethod: 's_absorb',
            rubyClass: 'Absorb',
            rubyPath: 'absorb.rb',
            dartBehavior: 'DrainMoveBehavior.absorb',
            status: PsdkPortStatus.ported,
          ),
        ],
        sourceDescription: 's_absorb test moves',
      );

      expect(report, contains('| fait | 3 |'));
      expect(report, contains('| partiel | 1 |'));
      expect(report, contains('| fait | giga_drain | s_absorb | ported |'));
      expect(
        report,
        contains('| fait | parabolic_charge | s_absorb | ported |'),
      );
      expect(
        report,
        contains('| fait | oblivion_wing | s_absorb | ported |'),
      );
      expect(
        report,
        contains('| partiel | absorb_status | s_absorb | ported |'),
      );
    });

    test('scopes ported heal coverage to strict self recovery moves', () {
      final report = generatePsdkAttackCoverageReport(
        moves: const <PsdkStudioMoveCoverageEntry>[
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'recover',
            battleEngineMethod: 's_heal',
            type: 'normal',
            category: 'status',
            power: 0,
            accuracy: '0',
            pp: 5,
            target: 'user',
            sourceFile: 'recover.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'heal_pulse',
            battleEngineMethod: 's_heal',
            type: 'psychic',
            category: 'status',
            power: 0,
            accuracy: '0',
            pp: 10,
            effectChance: 100,
            target: 'any_other_pokemon',
            sourceFile: 'heal_pulse.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'synthesis',
            battleEngineMethod: 's_heal_weather',
            type: 'grass',
            category: 'status',
            power: 0,
            accuracy: '0',
            pp: 5,
            target: 'user',
            sourceFile: 'synthesis.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'rest',
            battleEngineMethod: 's_rest',
            type: 'psychic',
            category: 'status',
            power: 0,
            accuracy: '0',
            pp: 5,
            target: 'user',
            sourceFile: 'rest.json',
          ),
        ],
        manifest: const <PsdkMoveRegistryManifestEntry>[
          PsdkMoveRegistryManifestEntry(
            battleEngineMethod: 's_heal',
            rubyClass: 'HealMove',
            rubyPath: 'heal.rb',
            dartBehavior: 'HealMoveBehavior',
            status: PsdkPortStatus.ported,
          ),
          PsdkMoveRegistryManifestEntry(
            battleEngineMethod: 's_heal_weather',
            rubyClass: 'HealWeather',
            rubyPath: 'heal_weather.rb',
            dartBehavior: 'HealMoveBehavior.weather',
            status: PsdkPortStatus.ported,
          ),
          PsdkMoveRegistryManifestEntry(
            battleEngineMethod: 's_rest',
            rubyClass: 'Rest',
            rubyPath: 'rest.rb',
            dartBehavior: 'RecoveryStatMoveBehavior.rest',
            status: PsdkPortStatus.ported,
          ),
        ],
        sourceDescription: 'heal test moves',
      );

      expect(report, contains('| fait | 4 |'));
      expect(report, contains('| partiel | 0 |'));
      expect(report, contains('| fait | recover | s_heal | ported |'));
      expect(report, contains('| fait | heal_pulse | s_heal | ported |'));
      expect(
        report,
        contains('| fait | synthesis | s_heal_weather | ported |'),
      );
      expect(report, contains('| fait | rest | s_rest | ported |'));
    });

    test('scopes ported s_protect coverage to strict base variants', () {
      final report = generatePsdkAttackCoverageReport(
        moves: const <PsdkStudioMoveCoverageEntry>[
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'protect',
            battleEngineMethod: 's_protect',
            type: 'normal',
            category: 'status',
            power: 0,
            accuracy: '0',
            pp: 10,
            priority: 4,
            target: 'user',
            sourceFile: 'protect.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'detect',
            battleEngineMethod: 's_protect',
            type: 'fighting',
            category: 'status',
            power: 0,
            accuracy: '0',
            pp: 5,
            priority: 4,
            target: 'user',
            sourceFile: 'detect.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'endure',
            battleEngineMethod: 's_protect',
            type: 'normal',
            category: 'status',
            power: 0,
            accuracy: '0',
            pp: 10,
            priority: 4,
            target: 'user',
            sourceFile: 'endure.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'spiky_shield',
            battleEngineMethod: 's_protect',
            type: 'grass',
            category: 'status',
            power: 0,
            accuracy: '0',
            pp: 10,
            priority: 4,
            target: 'user',
            sourceFile: 'spiky_shield.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'king_s_shield',
            battleEngineMethod: 's_protect',
            type: 'steel',
            category: 'status',
            power: 0,
            accuracy: '0',
            pp: 10,
            priority: 4,
            target: 'user',
            sourceFile: 'king_s_shield.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'baneful_bunker',
            battleEngineMethod: 's_protect',
            type: 'poison',
            category: 'status',
            power: 0,
            accuracy: '0',
            pp: 10,
            priority: 4,
            target: 'user',
            sourceFile: 'baneful_bunker.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'wide_guard',
            battleEngineMethod: 's_protect',
            type: 'rock',
            category: 'status',
            power: 0,
            accuracy: '0',
            pp: 10,
            priority: 3,
            target: 'all_ally',
            sourceFile: 'wide_guard.json',
          ),
        ],
        manifest: const <PsdkMoveRegistryManifestEntry>[
          PsdkMoveRegistryManifestEntry(
            battleEngineMethod: 's_protect',
            rubyClass: 'Protect',
            rubyPath: 'protect.rb',
            dartBehavior: 'StaticBasicMoveRegistry.s_protect',
            status: PsdkPortStatus.ported,
          ),
        ],
        sourceDescription: 's_protect test moves',
      );

      expect(report, contains('| fait | 7 |'));
      expect(report, contains('| partiel | 0 |'));
      expect(report, contains('| fait | protect | s_protect | ported |'));
      expect(report, contains('| fait | detect | s_protect | ported |'));
      expect(report, contains('| fait | endure | s_protect | ported |'));
      expect(
        report,
        contains('| fait | spiky_shield | s_protect | ported |'),
      );
      expect(
        report,
        contains('| fait | king_s_shield | s_protect | ported |'),
      );
      expect(
        report,
        contains('| fait | baneful_bunker | s_protect | ported |'),
      );
      expect(
        report,
        contains('| fait | wide_guard | s_protect | ported |'),
      );
    });

    test('classifies strict trapping families as fully covered', () {
      final report = generatePsdkAttackCoverageReport(
        moves: const <PsdkStudioMoveCoverageEntry>[
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'bind',
            battleEngineMethod: 's_bind',
            type: 'normal',
            category: 'physical',
            power: 15,
            accuracy: '85',
            pp: 20,
            priority: 0,
            criticalRate: 1,
            target: 'adjacent_pokemon',
            sourceFile: 'bind.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'magma_storm',
            battleEngineMethod: 's_bind',
            type: 'fire',
            category: 'special',
            power: 100,
            accuracy: '75',
            pp: 5,
            priority: 0,
            criticalRate: 1,
            target: 'adjacent_pokemon',
            sourceFile: 'magma_storm.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'mean_look',
            battleEngineMethod: 's_cantflee',
            type: 'normal',
            category: 'status',
            power: 0,
            accuracy: '0',
            pp: 5,
            priority: 0,
            target: 'adjacent_pokemon',
            sourceFile: 'mean_look.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'thousand_waves',
            battleEngineMethod: 's_cantflee',
            type: 'ground',
            category: 'physical',
            power: 90,
            accuracy: '100',
            pp: 10,
            priority: 0,
            criticalRate: 1,
            target: 'adjacent_all_foe',
            sourceFile: 'thousand_waves.json',
          ),
        ],
        manifest: const <PsdkMoveRegistryManifestEntry>[
          PsdkMoveRegistryManifestEntry(
            battleEngineMethod: 's_bind',
            rubyClass: 'Bind',
            rubyPath: 'bind.rb',
            dartBehavior: 'StaticBasicMoveRegistry.s_bind',
            status: PsdkPortStatus.ported,
          ),
          PsdkMoveRegistryManifestEntry(
            battleEngineMethod: 's_cantflee',
            rubyClass: 'CantSwitch',
            rubyPath: 'cant_switch.rb',
            dartBehavior: 'StaticBasicMoveRegistry.s_cantflee',
            status: PsdkPortStatus.ported,
          ),
        ],
        sourceDescription: 'trapping test moves',
      );

      expect(report, contains('| fait | 4 |'));
      expect(report, contains('| partiel | 0 |'));
      expect(report, contains('| fait | bind | s_bind | ported |'));
      expect(report, contains('| fait | magma_storm | s_bind | ported |'));
      expect(report, contains('| fait | mean_look | s_cantflee | ported |'));
      expect(
        report,
        contains('| fait | thousand_waves | s_cantflee | ported |'),
      );
    });

    test('classifies strict side protection families as fully covered', () {
      final report = generatePsdkAttackCoverageReport(
        moves: const <PsdkStudioMoveCoverageEntry>[
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'reflect',
            battleEngineMethod: 's_reflect',
            type: 'psychic',
            category: 'status',
            power: 0,
            accuracy: '0',
            pp: 20,
            target: 'all_ally',
            sourceFile: 'reflect.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'light_screen',
            battleEngineMethod: 's_reflect',
            type: 'psychic',
            category: 'status',
            power: 0,
            accuracy: '0',
            pp: 30,
            target: 'all_ally',
            sourceFile: 'light_screen.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'aurora_veil',
            battleEngineMethod: 's_reflect',
            type: 'ice',
            category: 'status',
            power: 0,
            accuracy: '0',
            pp: 20,
            target: 'all_ally',
            sourceFile: 'aurora_veil.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'safeguard',
            battleEngineMethod: 's_safe_guard',
            type: 'normal',
            category: 'status',
            power: 0,
            accuracy: '0',
            pp: 25,
            target: 'all_ally',
            sourceFile: 'safeguard.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'mist',
            battleEngineMethod: 's_mist',
            type: 'ice',
            category: 'status',
            power: 0,
            accuracy: '0',
            pp: 30,
            target: 'all_ally',
            sourceFile: 'mist.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'lucky_chant',
            battleEngineMethod: 's_lucky_chant',
            type: 'normal',
            category: 'status',
            power: 0,
            accuracy: '0',
            pp: 30,
            target: 'all_ally',
            sourceFile: 'lucky_chant.json',
          ),
        ],
        manifest: const <PsdkMoveRegistryManifestEntry>[
          PsdkMoveRegistryManifestEntry(
            battleEngineMethod: 's_reflect',
            rubyClass: 'Reflect',
            rubyPath: 'reflect.rb',
            dartBehavior: 'StaticBasicMoveRegistry.s_reflect',
            status: PsdkPortStatus.ported,
          ),
          PsdkMoveRegistryManifestEntry(
            battleEngineMethod: 's_safe_guard',
            rubyClass: 'Safeguard',
            rubyPath: 'safeguard.rb',
            dartBehavior: 'StaticBasicMoveRegistry.s_safe_guard',
            status: PsdkPortStatus.ported,
          ),
          PsdkMoveRegistryManifestEntry(
            battleEngineMethod: 's_mist',
            rubyClass: 'Mist',
            rubyPath: 'mist.rb',
            dartBehavior: 'StaticBasicMoveRegistry.s_mist',
            status: PsdkPortStatus.ported,
          ),
          PsdkMoveRegistryManifestEntry(
            battleEngineMethod: 's_lucky_chant',
            rubyClass: 'LuckyChant',
            rubyPath: 'lucky_chant.rb',
            dartBehavior: 'StaticBasicMoveRegistry.s_lucky_chant',
            status: PsdkPortStatus.ported,
          ),
        ],
        sourceDescription: 'side protection test moves',
      );

      expect(report, contains('| fait | 6 |'));
      expect(report, contains('| partiel | 0 |'));
      expect(report, contains('| fait | reflect | s_reflect | ported |'));
      expect(report, contains('| fait | safeguard | s_safe_guard | ported |'));
      expect(report, contains('| fait | mist | s_mist | ported |'));
      expect(
        report,
        contains('| fait | lucky_chant | s_lucky_chant | ported |'),
      );
    });
  });
}
