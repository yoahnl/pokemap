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
          '| partiel | z_move | s_z_move | partial | StaticBasicMoveRegistry.s_z_move |',
        ),
      );
    });

    test('scopes ported s_basic coverage to plain damage metadata only', () {
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
            sourceFile: 'liquidation.json',
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

      expect(report, contains('| fait | 1 |'));
      expect(report, contains('| partiel | 2 |'));
      expect(
        report,
        contains('| fait | mega_punch | s_basic | ported |'),
      );
      expect(
        report,
        contains('| partiel | liquidation | s_basic | ported |'),
      );
      expect(
        report,
        contains('| partiel | growl_like_bad_data | s_basic | ported |'),
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

      expect(report, contains('| fait | 1 |'));
      expect(report, contains('| partiel | 2 |'));
      expect(report, contains('| fait | calm_mind | s_self_stat | ported |'));
      expect(
        report,
        contains('| partiel | hone_claws | s_self_stat | ported |'),
      );
      expect(
        report,
        contains('| partiel | power_up_punch | s_self_stat | ported |'),
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
            target: 'adjacent_pokemon',
            sourceFile: 'swagger.json',
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

      expect(report, contains('| fait | 2 |'));
      expect(report, contains('| partiel | 2 |'));
      expect(report, contains('| fait | tail_whip | s_stat | ported |'));
      expect(report, contains('| fait | swords_dance | s_stat | ported |'));
      expect(report, contains('| partiel | sand_attack | s_stat | ported |'));
      expect(report, contains('| partiel | swagger | s_stat | ported |'));
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

      expect(report, contains('| fait | 2 |'));
      expect(report, contains('| partiel | 2 |'));
      expect(report, contains('| fait | thunder_wave | s_status | ported |'));
      expect(report, contains('| fait | toxic | s_status | ported |'));
      expect(report, contains('| partiel | confuse_ray | s_status | ported |'));
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

      expect(report, contains('| fait | 1 |'));
      expect(report, contains('| partiel | 3 |'));
      expect(report, contains('| fait | fly | s_2turns | ported |'));
      expect(report, contains('| partiel | skull_bash | s_2turns | ported |'));
      expect(report, contains('| partiel | bounce | s_2turns | ported |'));
      expect(
        report,
        contains('| partiel | razor_wind | s_2turns | ported |'),
      );
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
  });
}
