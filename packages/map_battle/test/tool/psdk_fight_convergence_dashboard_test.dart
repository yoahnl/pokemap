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
            },
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
      expect(markdown, contains('Next recommended lot: close effect family'));
    });
  });
}
