import 'package:map_battle/src/data/psdk_fight_convergence_dashboard.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK fight convergence dashboard', () {
    test('renders current counts and the highest impact next gap', () {
      final markdown = renderPsdkFightConvergenceDashboard(
        const <String, Object?>{
          'attacks': <String, Object?>{
            'totalAttacks': 728,
            'fait': 267,
            'partiel': 461,
            'pasFait': 0,
            'entries': <Object?>[
              <String, Object?>{
                'moveId': 'baton_pass',
                'battleEngineMethod': 's_baton_pass',
                'coverage': 'partiel',
                'reason': 'method_partial',
              },
            ],
          },
          'methods': <String, Object?>{
            'totalMethods': 330,
            'byStatus': <String, Object?>{
              'ported': 65,
              'partial': 265,
              'missing': 0,
            },
            'backlogBatches': <Object?>[
              <String, Object?>{
                'id': 'action_queue_copy_call',
                'label': 'Action queue / copy-call residuals',
                'count': 2,
                'methods': <Object?>['s_after_you', 's_assist'],
              },
              <String, Object?>{
                'id': 'audit_manifest_evidence',
                'label': 'Audit manifest evidence only',
                'count': 1,
                'methods': <Object?>['s_basic'],
              },
            ],
          },
          'effects': <String, Object?>{
            'totalEffects': 482,
            'byStatus': <String, Object?>{
              'ported': 0,
              'partial': 25,
              'missing': 457,
            },
            'byFamilyAndStatus': <String, Object?>{
              'ability': <String, Object?>{
                'ported': 0,
                'partial': 3,
                'missing': 251,
              },
              'item': <String, Object?>{
                'ported': 0,
                'partial': 2,
                'missing': 3,
              },
            },
            'entries': <Object?>[
              <String, Object?>{
                'effectName': 'FlashFire',
                'family': 'ability',
                'status': 'missing',
                'rubyPath': '06 Effects/04 Ability Effects/100 Flash Fire.rb',
                'hookFamilies': <Object?>['damage_change'],
              },
              <String, Object?>{
                'effectName': 'ArenaTrap',
                'family': 'ability',
                'status': 'partial',
                'rubyPath':
                    '06 Effects/04 Ability Effects/050 PreventingSwitchAbilities.rb',
                'hookFamilies': <Object?>['switch'],
              },
              <String, Object?>{
                'effectName': 'Protect',
                'family': 'move',
                'status': 'partial',
                'rubyPath': '06 Effects/02 Move Effects/001 Protect.rb',
                'hookFamilies': <Object?>['move_prevention'],
              },
              <String, Object?>{
                'effectName': 'ItemBasePowerMultiplier',
                'family': 'item',
                'status': 'partial',
                'rubyPath':
                    '06 Effects/05 Item Effects/050 ItemBasePowerMultiplier.rb',
                'hookFamilies': <Object?>[],
              },
              <String, Object?>{
                'effectName': 'StatusBerry',
                'family': 'item',
                'status': 'missing',
                'rubyPath': '06 Effects/05 Item Effects/050 StatusBerry.rb',
                'hookFamilies': <Object?>['item_change'],
              },
              <String, Object?>{
                'effectName': 'EjectButton',
                'family': 'item',
                'status': 'missing',
                'rubyPath': '06 Effects/05 Item Effects/100 Eject Button.rb',
                'hookFamilies': <Object?>['item_change'],
              },
              <String, Object?>{
                'effectName': 'TerrainSeeds',
                'family': 'item',
                'status': 'missing',
                'rubyPath': '06 Effects/05 Item Effects/050 TerrainSeeds.rb',
                'hookFamilies': <Object?>['item_change'],
              },
              <String, Object?>{
                'effectName': 'MentalHerb',
                'family': 'item',
                'status': 'partial',
                'rubyPath': '06 Effects/05 Item Effects/100 MentalHerb.rb',
                'hookFamilies': <Object?>['item_change'],
              },
            ],
          },
          'runtimeBridge': <String, Object?>{
            'status': 'explained',
            'reason': 'All runtime bridge rejections are explained.',
          },
        },
        generatedAt: DateTime.utc(2026, 5, 17),
      );

      expect(markdown, contains('# PSDK Fight Convergence Dashboard'));
      expect(markdown, contains('| Attacks | 267 / 728 | 36.7% | 461 |'));
      expect(markdown, contains('| Methods | 65 / 330 | 19.7% | 265 |'));
      expect(markdown, contains('| Effects | 0 / 482 | 0.0% | 482 |'));
      expect(markdown, contains('| ability | 0 | 3 | 251 | 254 |'));
      expect(markdown, contains('## Method Backlog'));
      expect(
        markdown,
        contains(
          '| Action queue / copy-call residuals | 2 | '
          '`s_after_you`, `s_assist` |',
        ),
      );
      expect(markdown, contains('| Audit manifest evidence only | 1 |'));
      expect(markdown, contains('## Ability Effect Backlog'));
      expect(markdown, contains('| damage_change | 0 | 1 | 1 |'));
      expect(markdown, contains('| switch | 1 | 0 | 1 |'));
      expect(markdown, contains('## Item Effect Backlog'));
      expect(markdown, contains('| damage/type/stat modifiers | 1 | 0 | 1 |'));
      expect(markdown, contains('| berries | 0 | 1 | 1 |'));
      expect(markdown, contains('| focus/eject/choice/orb | 0 | 1 | 1 |'));
      expect(markdown, contains('| weather/terrain/field | 0 | 1 | 1 |'));
      expect(
        markdown,
        contains('| held-item lifecycle and consumption | 1 | 0 | 1 |'),
      );
      expect(markdown, contains('Next recommended lot: close effect family'));
    });
  });
}
