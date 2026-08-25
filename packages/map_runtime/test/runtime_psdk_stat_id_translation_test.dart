import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Recette du 2026-08-25 : « il manque toujours d'animation de perte de
/// précision par exemple avec l'attaque Jet de Sable ».
///
/// Le moteur PSDK applique bien la baisse — il connaît `accuracy` et
/// `evasion`. C'est CE maillon qui la jetait : une stat non traduite rend
/// `null`, et l'événement est écarté sans bruit avant d'atteindre la
/// présentation. Ni aura, ni message.
///
/// Le piège PSDK est nommé ici parce qu'il a déjà mordu : `spd` est la
/// VITESSE et `dfs` la Défense Spéciale. Les intervertir échangerait
/// silencieusement deux auras et deux messages.
void main() {
  group('traduction des noms de stats du moteur', () {
    test('la précision et l’esquive arrivent jusqu’à la présentation', () {
      expect(runtimeBattleStatIdFor('acc'), BattleStatId.accuracy);
      expect(runtimeBattleStatIdFor('accuracy'), BattleStatId.accuracy);
      expect(runtimeBattleStatIdFor('eva'), BattleStatId.evasion);
      expect(runtimeBattleStatIdFor('evasion'), BattleStatId.evasion);
    });

    test('spd est la VITESSE et dfs la Défense Spéciale', () {
      expect(runtimeBattleStatIdFor('spd'), BattleStatId.speed);
      expect(runtimeBattleStatIdFor('dfs'), BattleStatId.specialDefense);
      expect(runtimeBattleStatIdFor('ats'), BattleStatId.specialAttack);
      expect(runtimeBattleStatIdFor('dfe'), BattleStatId.defense);
      expect(runtimeBattleStatIdFor('atk'), BattleStatId.attack);
    });

    test('une stat inconnue rend null plutôt qu’une stat au hasard', () {
      expect(runtimeBattleStatIdFor('nawak'), isNull);
    });

    test('les cinq stats de combat ET les deux jets sont tous couverts', () {
      // Si une valeur est ajoutée à BattleStatId sans être traduite ici, son
      // événement sera jeté en silence — exactement le défaut de la recette.
      final translated = <String>[
        'atk',
        'def',
        'ats',
        'dfs',
        'spd',
        'acc',
        'eva',
      ].map(runtimeBattleStatIdFor).whereType<BattleStatId>().toSet();
      expect(translated, BattleStatId.values.toSet());
    });
  });
}
