import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/services/pokemon_sdk_move_catalog_converter.dart';

void main() {
  const converter = PokemonSdkMoveCatalogConverter();

  group('PokemonSdkMoveCatalogConverter', () {
    test('converts a camelCase Studio status move into PokemonMove', () {
      final move = converter.convert(<String, Object?>{
        'id': 85,
        'dbSymbol': 'thunder_wave',
        'name': <String, Object?>{
          'en': 'Thunder Wave',
          'fr': 'Cage-Eclair',
        },
        'type': 'electric',
        'category': 'status',
        'power': 0,
        'accuracy': 90,
        'pp': 20,
        'priority': 0,
        'criticalRate': 1,
        'effectChance': 100,
        'battleEngineMethod': 's_status',
        'battleEngineAimedTarget': 'adjacent_foe',
        'flags': <String, Object?>{
          'blocable': true,
          'mirrorMove': true,
          'authentic': true,
        },
        'moveStatuses': <Object?>[
          <String, Object?>{
            'status': 'paralysis',
            'luckRate': 100,
          },
        ],
        'scriptPath': 'scripts/5 Battle/10 Move/2 Definitions/status.rb',
        'animationId': 'thunder_wave',
      });

      expect(move.id, 'thunder_wave');
      expect(move.source, 'pokemon_sdk_studio');
      expect(move.dbSymbol, 'thunder_wave');
      expect(move.name, 'Thunder Wave');
      expect(move.names, containsPair('fr', 'Cage-Eclair'));
      expect(move.type, 'electric');
      expect(move.category, PokemonMoveCategory.status);
      expect(move.battleEngineMethod, 's_status');
      expect(move.battleEngineAimedTarget, PokemonMoveAimedTarget.adjacentFoe);
      expect(move.power, 0);
      expect(move.accuracy, const PokemonMoveAccuracy.percent(value: 90));
      expect(move.studioFlags.blocable, isTrue);
      expect(move.studioFlags.mirrorMove, isTrue);
      expect(move.studioFlags.authentic, isTrue);
      expect(move.moveStatuses.single.statusId, 'paralysis');
      expect(move.moveStatuses.single.chance, 100);
      expect(move.sourceRefs.psdkStudioMoveId, '85');
      expect(move.sourceRefs.psdkDbSymbol, 'thunder_wave');
      expect(move.sourceRefs.psdkBattleEngineMethod, 's_status');
      expect(
        move.sourceRefs.psdkScriptPath,
        'scripts/5 Battle/10 Move/2 Definitions/status.rb',
      );
      expect(move.sourceRefs.psdkAnimationId, 'thunder_wave');
    });

    test('accepts snake_case Studio keys and stat stage mods', () {
      final move = converter.convert(<String, Object?>{
        'id': 'growl',
        'db_symbol': 'growl',
        'name': 'Growl',
        'type': 'normal',
        'category': 'status',
        'power': 0,
        'accuracy': 100,
        'pp': 40,
        'priority': 0,
        'critical_rate': 1,
        'effect_chance': 100,
        'battle_engine_method': 's_stat',
        'battle_engine_aimed_target': 'all_adjacent_foes',
        'flags': <String, Object?>{
          'sound_attack': true,
        },
        'battle_stage_mod': <Object?>[
          <String, Object?>{
            'battleStage': 'atk',
            'modificator': -1,
          },
        ],
      });

      expect(move.dbSymbol, 'growl');
      expect(
        move.battleEngineAimedTarget,
        PokemonMoveAimedTarget.allAdjacentFoes,
      );
      expect(move.studioFlags.soundAttack, isTrue);
      expect(move.battleStageMods.single.stat, PokemonMoveStatId.attack);
      expect(move.battleStageMods.single.stages, -1);
    });

    test('keeps PSDK accuracy zero as the canonical sentinel', () {
      final move = converter.convert(<String, Object?>{
        'dbSymbol': 'swift',
        'name': 'Swift',
        'type': 'normal',
        'category': 'special',
        'power': 60,
        'accuracy': 0,
        'pp': 20,
        'battleEngineMethod': 's_basic',
        'battleEngineAimedTarget': 'all_adjacent_foes',
      });

      expect(move.accuracy, const PokemonMoveAccuracy.percent(value: 0));
    });

    test('fails clearly when required Studio fields are missing', () {
      expect(
        () => converter.convert(const <String, Object?>{
          'name': 'Broken Move',
          'type': 'normal',
          'category': 'physical',
          'power': 40,
          'accuracy': 100,
          'pp': 35,
          'battleEngineMethod': 's_basic',
        }),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('dbSymbol'),
          ),
        ),
      );
    });

    test('produces project catalog entries sorted by dbSymbol', () {
      final catalog = converter.convertCatalog(<Map<String, Object?>>[
        <String, Object?>{
          'dbSymbol': 'water_gun',
          'name': 'Water Gun',
          'type': 'water',
          'category': 'special',
          'power': 40,
          'accuracy': 100,
          'pp': 25,
          'battleEngineMethod': 's_basic',
          'battleEngineAimedTarget': 'adjacent_foe',
        },
        <String, Object?>{
          'dbSymbol': 'tackle',
          'name': 'Tackle',
          'type': 'normal',
          'category': 'physical',
          'power': 40,
          'accuracy': 100,
          'pp': 35,
          'battleEngineMethod': 's_basic',
          'battleEngineAimedTarget': 'adjacent_foe',
        },
      ]);

      expect(catalog.catalog, 'moves');
      expect(catalog.meta.sourcePriority, contains('pokemon_sdk_studio'));
      expect(catalog.entries.map((entry) => entry['dbSymbol']), [
        'tackle',
        'water_gun',
      ]);
    });
  });
}
