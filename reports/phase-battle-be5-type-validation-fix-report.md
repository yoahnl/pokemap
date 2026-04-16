# BE5-mini-fix — Validation sémantique des types supportés côté runtime avant le battle

## 1. Résumé exécutif honnête

Le mini-fix corrige un vrai problème de code, pas un simple problème de wording.

Avant ce lot :
- `RuntimePokemonSpeciesLoader` validait bien la forme de `typing.types`, mais pas sa compatibilité avec les types réellement supportés par `map_battle`.
- `RuntimeBattleMoveBridge` validait bien qu’un `move.type` n’était pas vide, mais pas qu’il appartenait à l’ensemble des types réellement supportés.
- le chemin runtime normal pouvait donc laisser passer une espèce ou un move invalide, puis échouer plus tard dans `map_battle` via `BattleTypeChart._ensureSupportedType(...)` avec un `StateError` tardif et mal placé.

Après ce lot :
- une espèce avec type non supporté échoue tôt au chargement runtime avec `RuntimeBattleSetupException` ;
- un move avec type non supporté échoue tôt au bridge runtime -> battle avec `RuntimeBattleSetupException` ;
- le mini-fix réutilise une source de vérité unique, `BattleTypeChart.supportedTypes` ;
- aucune sémantique métier de BE5 n’a été changée côté dégâts, STAB, effectiveness ou immunités.

Ce que j’ai réellement fait :
- durcissement sémantique du typing espèce côté loader runtime ;
- durcissement sémantique du type du move côté bridge runtime -> battle ;
- ajout de tests unitaires ciblés sur ces deux seams ;
- rerun des validations battle/runtime demandées ;
- rédaction d’un report complet.

Ce que je n’ai volontairement pas fait :
- aucun changement du type chart ;
- aucun changement des dégâts BE5 ;
- aucun changement de STAB, immunités ou effectiveness ;
- aucun changement dans `map_core` ;
- aucun changement dans `map_editor` ;
- aucun test d’intégration lourd supplémentaire, parce que le prompt demandait un mini-fix et que les deux seams corrigés sont maintenant couverts directement.

## 2. Pré-gates exécutés + résultats

Pré-gates exécutés avant toute modification :

- `git status --short`
  - résultat : vide
- `git diff --stat`
  - résultat : vide
- `git ls-files --others --exclude-standard`
  - résultat : vide
- `cd packages/map_battle && /opt/homebrew/bin/dart test`
  - résultat : vert
- `cd packages/map_battle && /opt/homebrew/bin/dart analyze`
  - résultat : vert
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/runtime_move_catalog_loader_test.dart test/runtime_pokemon_species_loader_test.dart test/runtime_pokemon_learnset_loader_test.dart test/runtime_battle_move_bridge_test.dart test/runtime_battle_combatant_seed_builder_test.dart test/runtime_battle_setup_mapper_test.dart test/runtime_battle_outcome_apply_test.dart test/wild_battle_end_to_end_flow_test.dart test/playable_map_game_whiteout_lite_test.dart`
  - résultat : vert
- `cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub lib/src/application/runtime_battle_move_bridge.dart lib/src/application/runtime_battle_combatant_seed_builder.dart lib/src/application/runtime_battle_setup_mapper.dart lib/src/application/runtime_pokemon_species_loader.dart test/runtime_battle_move_bridge_test.dart test/runtime_battle_combatant_seed_builder_test.dart test/runtime_battle_setup_mapper_test.dart test/runtime_move_catalog_loader_test.dart test/runtime_pokemon_species_loader_test.dart test/runtime_pokemon_learnset_loader_test.dart test/runtime_battle_outcome_apply_test.dart test/wild_battle_end_to_end_flow_test.dart test/playable_map_game_whiteout_lite_test.dart`
  - résultat : vert

Classification honnête des pré-gates :
- battle : vert
- runtime ciblé battle : vert
- état git initial : propre

## 3. État initial audité réel

Fichiers audités avant modification :

- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_type_chart.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_pokemon_species_loader_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_move_bridge_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`
- `/Users/karim/Project/pokemonProject/reports/phase-battle-be5-type-damage-report.md`

Constats initiaux confirmés :

- `BattleTypeChart.supportedTypes` existait déjà comme liste canonique des types battle supportés.
- `RuntimePokemonSpeciesLoader` validait la forme de `typing.types`, mais ne vérifiait pas l’appartenance à `BattleTypeChart.supportedTypes`.
- `RuntimeBattleMoveBridge._translateType(...)` rejetait `type` vide, mais laissait passer un type non supporté tant qu’il n’était pas vide.
- ce trou n’était pas seulement théorique : il exposait le runtime à un `StateError` tardif dans `map_battle`, alors que l’erreur relevait du seam runtime.

## 4. Problèmes confirmés / non confirmés

Problèmes confirmés :

- validation sémantique manquante sur `typing.types` côté `RuntimePokemonSpeciesLoader`
- validation sémantique manquante sur `move.type` côté `RuntimeBattleMoveBridge`
- possibilité de fuite tardive vers `StateError` battle pour des données runtime invalides

Problèmes non confirmés :

- besoin d’un nouveau helper/factory/service dédié aux types
- besoin de modifier `map_battle` pour corriger ce mini-fix
- besoin d’ajouter une seconde whitelist des types supportés dans `map_runtime`

## 5. Cause racine réelle

La cause racine n’était pas un type chart faux.

La cause racine était une frontière de validation incomplète :
- la source de vérité battle existait déjà ;
- le runtime ne la consultait pas assez tôt ;
- le moteur battle se retrouvait à découvrir trop tard qu’un type était invalide.

En clair :
- la donnée projet était bien résolue au runtime ;
- mais sa compatibilité avec le contrat battle n’était pas entièrement validée avant le handoff.

## 6. Décisions retenues / rejetées

Décisions retenues :

- réutiliser `BattleTypeChart.supportedTypes` comme source de vérité unique
- valider les types d’espèce au chargement runtime, là où les species data projet sont lues
- valider les types de move au bridge runtime -> battle, là où la projection battle est décidée
- lever `RuntimeBattleSetupException` avec `debugDetails` actionnables
- ajouter seulement des tests ciblés unitaires

Décisions rejetées :

- dupliquer la liste des types supportés dans `map_runtime`
- déplacer la validation dans `map_battle`
- toucher au type chart ou aux dégâts BE5
- ajouter un test d’intégration large “juste pour être sûr”

## 7. Critique explicite du prompt

Ce qui était juste :

- le bug ciblé était réel
- la préférence pour `BattleTypeChart.supportedTypes` comme source de vérité était saine
- le cadrage “petit fix, pas nouveau lot” était bon
- la cible “échouer tôt au runtime avec `RuntimeBattleSetupException`” était la bonne

Ce qui était discutable :

- le prompt supposait implicitement qu’il faudrait peut-être toucher `map_battle`; après audit, ce n’était pas nécessaire
- le prompt demandait de “vérifier qu’on n’obtient plus un `StateError` battle tardif sur les chemins runtime normaux” ; on peut le démontrer raisonnablement par les seams corrigés et leurs tests, mais pas prouver exhaustivement tous les chemins sans ouvrir un lot de tests d’intégration plus large

Ce qui aurait été dangereux si suivi aveuglément :

- créer un helper runtime séparé des types supportés “pour rester découplé” aurait créé une deuxième source de vérité
- ajouter un gros test d’intégration BE5 pour un simple trou de validation aurait élargi le scope sans gain proportionné

Ce que j’ai recadré :

- j’ai gardé le fix strictement côté runtime
- je n’ai pas touché `map_battle`
- je n’ai pas ajouté de nouvelle abstraction
- je me suis appuyé directement sur la surface battle déjà publique

Pourquoi ce recadrage est meilleur pour ce repo réel :

- il corrige le trou là où il naît ;
- il conserve une seule source de vérité ;
- il garde le diff petit ;
- il n’altère aucune sémantique métier BE5.

## 8. Périmètre inclus / exclu

Inclus :

- validation sémantique des types d’espèce côté runtime
- validation sémantique des types de move côté runtime bridge
- tests unitaires ciblés associés
- report complet

Exclu :

- `map_battle`
- `map_core`
- `map_editor`
- docs `/docs`
- type chart
- dégâts BE5
- STAB
- immunités
- BE6 et suivants

## 9. Liste exacte des fichiers modifiés / créés / supprimés

Fichiers modifiés :

- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_pokemon_species_loader_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_move_bridge_test.dart`

Fichier créé :

- `/Users/karim/Project/pokemonProject/reports/phase-battle-be5-type-validation-fix-report.md`

Fichier supprimé :

- aucun

## 10. Justification fichier par fichier

`/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart`

- ajout de la validation sémantique des types supportés au point de lecture des species data
- réutilisation explicite de `BattleTypeChart.supportedTypes`
- ajout de commentaires expliquant pourquoi l’échec doit se produire ici

`/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`

- ajout de la validation sémantique du `move.type`
- rejet explicite via le style d’erreur existant du bridge
- normalisation explicite en minuscule conservée jusqu’au contrat battle

`/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_pokemon_species_loader_test.dart`

- ajout d’un test mono-type non supporté
- ajout d’un test dual-type dont un type n’est pas supporté

`/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_move_bridge_test.dart`

- ajout d’un test move avec type non supporté
- vérification de `RuntimeBattleSetupException` et de `debugDetails` utiles

`/Users/karim/Project/pokemonProject/reports/phase-battle-be5-type-validation-fix-report.md`

- documentation honnête du mini-fix, des validations, des retours d’agents et de l’annexe complète

## 11. Commandes réellement exécutées

Pré-gates :

```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard
cd packages/map_battle && /opt/homebrew/bin/dart test
cd packages/map_battle && /opt/homebrew/bin/dart analyze
cd packages/map_runtime && /opt/homebrew/bin/flutter test \
  test/runtime_move_catalog_loader_test.dart \
  test/runtime_pokemon_species_loader_test.dart \
  test/runtime_pokemon_learnset_loader_test.dart \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/playable_map_game_whiteout_lite_test.dart
cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub \
  lib/src/application/runtime_battle_move_bridge.dart \
  lib/src/application/runtime_battle_combatant_seed_builder.dart \
  lib/src/application/runtime_battle_setup_mapper.dart \
  lib/src/application/runtime_pokemon_species_loader.dart \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/runtime_move_catalog_loader_test.dart \
  test/runtime_pokemon_species_loader_test.dart \
  test/runtime_pokemon_learnset_loader_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/playable_map_game_whiteout_lite_test.dart
```

Audit :

```bash
sed -n '1,240p' packages/map_battle/lib/src/battle_type_chart.dart
sed -n '1,260p' packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart
sed -n '1,320p' packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart
sed -n '1,260p' packages/map_runtime/test/runtime_pokemon_species_loader_test.dart
sed -n '1,260p' packages/map_runtime/test/runtime_battle_move_bridge_test.dart
rg -n "supportedTypes|_translateType|typing.types|StateError|ensureSupportedType" packages/map_battle/lib/src packages/map_runtime/lib/src packages/map_runtime/test
```

Validation après implémentation :

```bash
cd packages/map_battle && /opt/homebrew/bin/dart format lib/src/battle_type_chart.dart
cd packages/map_runtime && /opt/homebrew/bin/dart format \
  lib/src/application/runtime_pokemon_species_loader.dart \
  lib/src/application/runtime_battle_move_bridge.dart \
  test/runtime_pokemon_species_loader_test.dart \
  test/runtime_battle_move_bridge_test.dart
cd packages/map_battle && /opt/homebrew/bin/dart analyze
cd packages/map_battle && /opt/homebrew/bin/dart test
cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub \
  lib/src/application/runtime_battle_move_bridge.dart \
  lib/src/application/runtime_pokemon_species_loader.dart \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_pokemon_species_loader_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_setup_mapper_test.dart
cd packages/map_runtime && /opt/homebrew/bin/flutter test \
  test/runtime_move_catalog_loader_test.dart \
  test/runtime_pokemon_species_loader_test.dart \
  test/runtime_pokemon_learnset_loader_test.dart \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/playable_map_game_whiteout_lite_test.dart
```

Relevé git final :

```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard
```

## 12. Résultats réels de format / analyze / tests

Format :

- `packages/map_battle`: `Formatted 1 file (0 changed) in 0.00 seconds.`
- `packages/map_runtime`: `Formatted 4 files (0 changed) in 0.01 seconds.`

Analyze :

- `packages/map_battle`: `No issues found!`
- `packages/map_runtime` ciblé : `No issues found! (ran in 1.4s)`

Tests :

- `packages/map_battle`: `All tests passed!`
- `packages/map_runtime` ciblé : `All tests passed!`

## 13. Incidents rencontrés

- premier essai de sub-agent d’audit/design impossible via `spawn_agent` car la limite de threads agents de la session était déjà atteinte
- j’ai donc réutilisé un agent existant
- un premier retour d’agent réutilisé était hors sujet et reflétait manifestement un ancien contexte BE5 plus large ; je ne l’ai pas pris comme review valide
- un reviewer séparé (`Maxwell`) n’a rien renvoyé dans la fenêtre d’attente
- j’ai alors tenté une seconde review séparée avec `Singer`, qui a bien répondu

## 14. État git utile

État git final :

- fichiers modifiés :
  - `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
  - `packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart`
  - `packages/map_runtime/test/runtime_battle_move_bridge_test.dart`
  - `packages/map_runtime/test/runtime_pokemon_species_loader_test.dart`
- fichier non suivi :
  - `reports/phase-battle-be5-type-validation-fix-report.md`

Résumé `git diff --stat` final :

```text
 .../application/runtime_battle_move_bridge.dart    | 23 ++++++-
 .../runtime_pokemon_species_loader.dart            | 18 ++++++
 .../test/runtime_battle_move_bridge_test.dart      | 37 +++++++++++
 .../test/runtime_pokemon_species_loader_test.dart  | 75 ++++++++++++++++++++++
 4 files changed, 150 insertions(+), 3 deletions(-)
```

## 15. Checklist finale

- [x] j’ai corrigé un vrai problème de validation code, pas juste du wording
- [x] une espèce avec type non supporté échoue tôt côté runtime
- [x] un move avec type non supporté échoue tôt côté runtime bridge
- [x] je n’ai pas dupliqué une deuxième source de vérité des types sans justification solide
- [x] je n’ai pas élargi le scope à BE6+
- [x] je n’ai pas touché `map_editor`
- [x] je n’ai pas touché `map_core` sauf nécessité exceptionnelle
- [x] j’ai ajouté des tests ciblés utiles
- [x] j’ai relancé format
- [x] j’ai relancé analyze
- [x] j’ai relancé les tests utiles
- [x] je n’ai fait aucune écriture Git interdite
- [x] mon report explique précisément ce que j’ai fait
- [x] mon report explique précisément ce que je n’ai pas fait
- [x] mon report dit clairement si j’ai corrigé le code, la doc, ou les deux

## 16. Retour du sub-agent d’audit/design

Agent retenu :

- `Euler`

Retour exploitable retenu :

- la réutilisation de `BattleTypeChart.supportedTypes` comme source unique est bien le plus petit design sain
- le placement de validation est correct :
  - species loader pour les species data projet
  - bridge pour les move data projetées vers battle
- pas besoin de toucher `map_battle`

Retour rejeté :

- un premier retour d’agent réutilisé sur un ancien contexte BE5 plus large, non exploitable pour ce mini-fix ; il est documenté comme incident, pas comme avis de design valide

## 17. Retour du reviewer séparé

Reviewer retenu :

- `Singer`

Retour :

- aucun finding matériel sur les quatre fichiers touchés
- le reviewer confirme :
  - pas de duplication de source de vérité
  - bon placement de validation
  - tests suffisants pour ce mini-fix

Reviewer non exploitable :

- `Maxwell` n’a rien renvoyé dans la fenêtre d’attente

## 18. Corrections appliquées après review

- aucune correction de code supplémentaire n’a été nécessaire après la review utile de `Singer`
- j’ai seulement intégré dans ce report le fait que :
  - `Maxwell` n’a pas répondu
  - le premier agent réutilisé a renvoyé un contexte BE5 trop large et a été ignoré honnêtement

## 19. Autocritique finale

Ce qui est solide :

- le fix est réellement un fix de code
- il ferme le trou au bon seam
- il garde une seule source de vérité
- le diff est petit

Ce qui reste un peu fragile :

- la preuve “plus de `StateError` battle tardif sur les chemins runtime normaux” repose sur la correction des deux seams et leurs tests ciblés, pas sur une campagne d’intégration exhaustive

Ce que je ferais ensuite si un micro-lot connexe était demandé :

- rien côté métier
- au maximum, un test d’intégration runtime supplémentaire si un futur bug montrait encore une fuite tardive concrète

Compromis d’architecture :

- oui, le runtime dépend ici explicitement d’une surface battle (`BattleTypeChart.supportedTypes`) pour valider la compatibilité du contrat battle
- je considère ce compromis acceptable et sain dans ce repo réel, parce qu’il évite exactement la duplication toxique qu’on voulait éviter

Réponse explicite à la demande du prompt :

- oui, j’ai réutilisé `BattleTypeChart.supportedTypes`
- oui, le fix corrige le code
- non, je n’ai pas corrigé seulement la doc

## 20. Annexe avec le contenu complet de tous les fichiers texte touchés

Note :

- cette annexe inclut le contenu complet des fichiers texte modifiés par le mini-fix
- le report s’exclut lui-même de sa propre annexe pour éviter la récursion infinie

### `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'runtime_battle_setup_exception.dart';

/// Loader runtime spécialisé des espèces Pokémon projet.
///
/// M6 extrait ce seam du mapper battle pour deux raisons simples :
/// - la lecture JSON projet ne doit plus vivre cachée dans le mapper ;
/// - le runtime a besoin d'un point de lecture testable, strict et borné pour
///   les espèces, exactement comme il en a désormais un pour les moves.
///
/// Important :
/// - ce loader reste volontairement petit ;
/// - il ne devient pas un repository Pokémon générique ;
/// - il lit uniquement les champs dont le runtime battle actuel a besoin.
class RuntimePokemonSpeciesLoader {
  const RuntimePokemonSpeciesLoader();

  Future<RuntimePokemonSpecies> loadById({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required String speciesId,
  }) async {
    final normalizedSpeciesId = speciesId.trim();
    if (normalizedSpeciesId.isEmpty) {
      throw const RuntimeBattleSetupException(
        'Une espèce Pokémon vide ne peut pas être mappée vers le combat.',
      );
    }

    final speciesDirectory = Directory(
      _resolveProjectPath(
        projectRootDirectory,
        _normalizeConfiguredRelativePath(
          pokemonConfig.speciesDir,
          fallback: 'data/pokemon/species',
        ),
      ),
    );
    if (!await speciesDirectory.exists()) {
      throw RuntimeBattleSetupException(
        'Impossible de charger les espèces Pokémon locales pour démarrer le combat.',
        debugDetails: 'Missing species directory: ${speciesDirectory.path}',
      );
    }

    RuntimePokemonSpecies? matchedSpecies;
    String? matchedFilePath;

    // Invariant important préservé depuis le mapper historique :
    // la résolution se fait par l'id déclaré dans le JSON, pas par le nom
    // de fichier. On scanne donc les fichiers JSON top-level et on lit leur
    // `id` réel avant de conclure.
    await for (final entity in speciesDirectory.list(recursive: false)) {
      if (entity is! File ||
          p.extension(entity.path).toLowerCase() != '.json') {
        continue;
      }

      final rawJson = await _readJsonFile(
        entity,
        label: 'Pokemon species file',
      );
      final declaredId = (rawJson['id'] as String?)?.trim() ?? '';
      if (declaredId != normalizedSpeciesId) {
        continue;
      }

      if (matchedSpecies != null) {
        throw RuntimeBattleSetupException(
          'Plusieurs espèces Pokémon locales déclarent le même id; combat impossible.',
          debugDetails:
              'speciesId=$normalizedSpeciesId, firstFile=$matchedFilePath, duplicateFile=${entity.path}',
        );
      }

      matchedSpecies = _parseRuntimeSpecies(
        rawJson,
        expectedSpeciesId: normalizedSpeciesId,
        filePath: entity.path,
      );
      matchedFilePath = entity.path;
    }

    if (matchedSpecies == null) {
      throw RuntimeBattleSetupException(
        'Espèce Pokémon introuvable pour démarrer le combat.',
        debugDetails: 'speciesId=$speciesId',
      );
    }

    return matchedSpecies;
  }

  RuntimePokemonSpecies _parseRuntimeSpecies(
    Map<String, dynamic> rawJson, {
    required String expectedSpeciesId,
    required String filePath,
  }) {
    final baseStats = (rawJson['baseStats'] as Map?)?.cast<String, dynamic>();
    final baseHp = _readRequiredBaseStat(
      baseStats,
      statKey: 'hp',
      expectedSpeciesId: expectedSpeciesId,
      filePath: filePath,
    );
    final baseAttack = _readRequiredBaseStat(
      baseStats,
      statKey: 'atk',
      expectedSpeciesId: expectedSpeciesId,
      filePath: filePath,
    );
    final baseDefense = _readRequiredBaseStat(
      baseStats,
      statKey: 'def',
      expectedSpeciesId: expectedSpeciesId,
      filePath: filePath,
    );
    final baseSpecialAttack = _readRequiredBaseStat(
      baseStats,
      statKey: 'spa',
      expectedSpeciesId: expectedSpeciesId,
      filePath: filePath,
    );
    final baseSpecialDefense = _readRequiredBaseStat(
      baseStats,
      statKey: 'spd',
      expectedSpeciesId: expectedSpeciesId,
      filePath: filePath,
    );
    final baseSpeed = _readRequiredBaseStat(
      baseStats,
      statKey: 'spe',
      expectedSpeciesId: expectedSpeciesId,
      filePath: filePath,
    );

    final refs = (rawJson['refs'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{
          'learnset': (rawJson['learnsetRef'] as String?)?.trim() ?? '',
        };
    final abilities = (rawJson['abilities'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final typing = _readRequiredTyping(
      rawJson,
      expectedSpeciesId: expectedSpeciesId,
      filePath: filePath,
    );

    return RuntimePokemonSpecies(
      id: expectedSpeciesId,
      typing: typing,
      baseHp: baseHp,
      baseAttack: baseAttack,
      baseDefense: baseDefense,
      baseSpecialAttack: baseSpecialAttack,
      baseSpecialDefense: baseSpecialDefense,
      baseSpeed: baseSpeed,
      primaryAbilityId: (abilities['primary'] as String?)?.trim() ?? '',
      // `learnsetRef` peut rester vide : le loader learnset conservera le
      // fallback historique vers l'id de l'espèce.
      learnsetRef: (refs['learnset'] as String?)?.trim() ?? '',
    );
  }

  List<String> _readRequiredTyping(
    Map<String, dynamic> rawJson, {
    required String expectedSpeciesId,
    required String filePath,
  }) {
    // BE5 ouvre enfin la consommation réelle du type dans `map_battle`.
    //
    // Le runtime doit donc arrêter de traiter le typing espèce comme une
    // donnée "nice to have" :
    // - le vrai chemin runtime -> battle a besoin d'un typing explicite ;
    // - l'absence ou la corruption de ce champ doit donc faire échouer le
    //   handoff tôt, avec une erreur actionnable ;
    // - on garde cette validation ici, côté lecture projet, et non dans le
    //   moteur battle qui ne doit jamais relire le JSON brut.
    final rawTyping = (rawJson['typing'] as Map?)?.cast<String, dynamic>();
    final rawTypes = (rawTyping?['types'] as List?)?.cast<Object?>();
    if (rawTypes == null || rawTypes.isEmpty || rawTypes.length > 2) {
      throw RuntimeBattleSetupException(
        'Les données d’espèce Pokémon locales sont invalides; combat impossible.',
        debugDetails:
            'speciesId=$expectedSpeciesId, file=$filePath, typing.types must contain 1 or 2 entries',
      );
    }

    final normalizedTypes = <String>[];
    for (final rawType in rawTypes) {
      final normalizedType = (rawType as String?)?.trim().toLowerCase() ?? '';
      if (normalizedType.isEmpty || normalizedTypes.contains(normalizedType)) {
        throw RuntimeBattleSetupException(
          'Les données d’espèce Pokémon locales sont invalides; combat impossible.',
          debugDetails:
              'speciesId=$expectedSpeciesId, file=$filePath, typing.types contains an empty or duplicate entry',
        );
      }

      // Source de vérité volontairement unique :
      // - BE5 a placé la liste canonique des types battle supportés dans
      //   `BattleTypeChart.supportedTypes` ;
      // - ce loader runtime ne doit ni recopier cette liste, ni inventer sa
      //   propre validation divergente ;
      // - on réutilise donc directement le contrat battle pour échouer tôt,
      //   avant qu'un `StateError` tardif n'émerge pendant le calcul des
      //   dégâts.
      if (!BattleTypeChart.supportedTypes.contains(normalizedType)) {
        throw RuntimeBattleSetupException(
          'Les données d’espèce Pokémon locales sont invalides; combat impossible.',
          debugDetails:
              'speciesId=$expectedSpeciesId, file=$filePath, unsupported typing.types entry=$normalizedType',
        );
      }

      normalizedTypes.add(normalizedType);
    }

    return List<String>.unmodifiable(normalizedTypes);
  }

  int _readRequiredBaseStat(
    Map<String, dynamic>? baseStats, {
    required String statKey,
    required String expectedSpeciesId,
    required String filePath,
  }) {
    // BE2 garde le loader species volontairement petit, mais il ne peut plus
    // se contenter de `hp` seulement : le runtime doit maintenant construire
    // un vrai snapshot de stats combat, donc chaque base stat non-HP requise
    // doit être présente ou provoquer une erreur actionnable.
    final value = (baseStats?[statKey] as num?)?.toInt();
    if (value == null || value <= 0) {
      throw RuntimeBattleSetupException(
        'Les données d’espèce Pokémon locales sont invalides; combat impossible.',
        debugDetails:
            'speciesId=$expectedSpeciesId, file=$filePath, missing or invalid baseStats.$statKey',
      );
    }
    return value;
  }

  Future<Map<String, dynamic>> _readJsonFile(
    File file, {
    required String label,
  }) async {
    if (!await file.exists()) {
      throw RuntimeBattleSetupException(
        'Impossible de charger les données Pokémon locales nécessaires au combat.',
        debugDetails: '$label file not found: ${file.path}',
      );
    }

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Root JSON object expected');
      }
      return decoded;
    } on RuntimeBattleSetupException {
      rethrow;
    } catch (error) {
      throw RuntimeBattleSetupException(
        'Impossible de lire les données Pokémon locales nécessaires au combat.',
        debugDetails: '$label parse failed: $error (file=${file.path})',
      );
    }
  }

  String _normalizeConfiguredRelativePath(
    String rawPath, {
    required String fallback,
  }) {
    final trimmed = rawPath.trim();
    return p.normalize(trimmed.isEmpty ? fallback : trimmed);
  }

  String _resolveProjectPath(
    String projectRootDirectory,
    String relativeOrAbsolutePath,
  ) {
    if (p.isAbsolute(relativeOrAbsolutePath)) {
      return p.normalize(relativeOrAbsolutePath);
    }
    return p.normalize(p.join(projectRootDirectory, relativeOrAbsolutePath));
  }
}

/// Vue runtime minimale d'une espèce réellement consommée par le mapper.
///
/// On ne clone pas le JSON espèce au complet :
/// - le runtime battle n'a besoin que de peu de champs ici ;
/// - un DTO minimal typed est plus sûr qu'un `Map<String, dynamic>`;
/// - cela évite de laisser de la logique métier dépendre de clés JSON libres.
class RuntimePokemonSpecies {
  const RuntimePokemonSpecies({
    required this.id,
    required this.typing,
    required this.baseHp,
    required this.baseAttack,
    required this.baseDefense,
    required this.baseSpecialAttack,
    required this.baseSpecialDefense,
    required this.baseSpeed,
    required this.primaryAbilityId,
    required this.learnsetRef,
  });

  final String id;

  /// Typing défensif minimal réellement nécessaire à partir de BE5.
  ///
  /// Le loader le garde encore côté runtime, pas côté battle :
  /// - il fait partie de la donnée projet résolue par l'application ;
  /// - le seed builder décidera ensuite du contrat battle précis à produire ;
  /// - `map_battle` reste ainsi libre de sa propre représentation locale.
  final List<String> typing;
  final int baseHp;
  final int baseAttack;
  final int baseDefense;
  final int baseSpecialAttack;
  final int baseSpecialDefense;
  final int baseSpeed;
  final String primaryAbilityId;
  final String learnsetRef;
}
```

### `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`

```dart
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'runtime_battle_setup_exception.dart';

/// Bridge runtime -> battle pour un sous-ensemble honnête de `PokemonMove`.
///
/// Frontière volontaire de M8 :
/// - le loader runtime charge le canonique sans faire de policy d'exécution ;
/// - ce bridge décide si un move canonique peut être projeté honnêtement vers
///   le moteur battle MVP actuel ;
/// - `map_battle` exécute ensuite uniquement ce petit contrat battle enrichi.
///
/// Le but n'est pas de "supporter un peu tout" :
/// - on garde le standard damage flow ;
/// - on supporte `modifyStats` déterministe pour un petit sous-ensemble utile ;
/// - on refuse explicitement le reste.
///
/// BE1 durcit ce bridge sur un autre axe :
/// - certaines dimensions canoniques étaient encore perdues silencieusement ;
/// - on transporte maintenant le petit supplément de contrat battle qui évite
///   cette perte (`type`, `target`, `pp`) ;
/// - et on refuse explicitement les dimensions non neutres qui resteraient
///   encore mensongères sans nouvelle couche moteur (`priority`, `critRatio`,
///   cibles hors 1v1 simple honnête).
///
/// BE3 recadre ensuite ce point :
/// - `priority` n'est plus refusée, parce que `map_battle` sait enfin
///   ordonner honnêtement deux actions `Fight` ;
/// - `speed` stage devient également supportée pour ce même besoin ;
/// - puis BE4 ouvre enfin l'accuracy battle minimale et les PP réels ;
/// - `critRatio` et le reste restent hors scope et donc refusés.
class RuntimeBattleMoveBridge {
  const RuntimeBattleMoveBridge();

  /// Projette un move canonique vers le contrat `BattleMoveData`.
  ///
  /// Le refus est explicite et descriptif :
  /// - pas de fallback silencieux ;
  /// - pas de `power: 0` mensonger pour un move que le moteur n'exécute pas ;
  /// - pas de mutation opportuniste de `engineSupportLevel`.
  BattleMoveData toBattleMoveData({
    required PokemonMove move,
    required String combatantLabel,
  }) {
    _ensureEngineSupportLevelAllowsBridge(
      move: move,
      combatantLabel: combatantLabel,
    );
    _ensureCritRatioIsNeutralEnoughForBattle(
      move: move,
      combatantLabel: combatantLabel,
    );
    final target = _translateSupportedTarget(
      move: move,
      combatantLabel: combatantLabel,
    );
    final type = _translateType(
      move: move,
      combatantLabel: combatantLabel,
    );
    final accuracy = _translateAccuracy(move.accuracy);

    final selfChanges = <BattleStatStageChange>[];
    final targetChanges = <BattleStatStageChange>[];

    for (final effect in move.effects) {
      effect.map(
        fixedDamage: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:fixed_damage',
        ),
        multiHit: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:multi_hit',
        ),
        applyStatus: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:apply_status',
        ),
        applyVolatileStatus: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:apply_volatile_status',
        ),
        modifyStats: (effect) {
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_modify_stats_not_supported',
            );
          }
          if (effect.stageChanges.isEmpty) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'empty_modify_stats_not_supported',
            );
          }

          final translated = effect.stageChanges
              .map(
                (change) => _translateStageChange(
                  change: change,
                  move: move,
                  combatantLabel: combatantLabel,
                ),
              )
              .toList(growable: false);

          switch (effect.targetScope) {
            case PokemonMoveEffectTargetScope.self:
              selfChanges.addAll(translated);
            case PokemonMoveEffectTargetScope.target:
              targetChanges.addAll(translated);
            case PokemonMoveEffectTargetScope.field:
            case PokemonMoveEffectTargetScope.allySide:
            case PokemonMoveEffectTargetScope.foeSide:
            case PokemonMoveEffectTargetScope.slot:
              _rejectMove(
                move: move,
                combatantLabel: combatantLabel,
                bridgeLimit:
                    'unsupported_modify_stats_scope:${effect.targetScope.name}',
              );
          }
        },
        heal: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:heal',
        ),
        drain: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:drain',
        ),
        recoil: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:recoil',
        ),
        setWeather: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:set_weather',
        ),
        setTerrain: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:set_terrain',
        ),
        setPseudoWeather: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:set_pseudo_weather',
        ),
        selfSwitch: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:self_switch',
        ),
        forceSwitch: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:force_switch',
        ),
        breakProtect: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:break_protect',
        ),
        requireRecharge: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:require_recharge',
        ),
        chargeThenStrike: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:charge_then_strike',
        ),
        setSideCondition: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:set_side_condition',
        ),
        setSlotCondition: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:set_slot_condition',
        ),
      );
    }

    // Un move battle exécutable doit avoir au moins un chemin d'exécution
    // réel pour le moteur actuel :
    // - soit des dégâts standards ;
    // - soit des changements d'étages de stats déterministes ;
    // - soit les deux.
    if (!move.usesStandardDamageFlow &&
        selfChanges.isEmpty &&
        targetChanges.isEmpty) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'no_supported_execution_path',
      );
    }

    // Le moteur battle actuel sait seulement :
    // - infliger des dégâts à l'adversaire actif ;
    // - ou appliquer des boosts/baisses déterministes sur `self` / target.
    //
    // Un move auto-ciblé qui ferait malgré tout des dégâts standards serait
    // donc encore projeté mensongèrement : `map_battle` le résoudrait contre
    // l'adversaire faute de vrai contrat "self damage".
    //
    // On préfère refuser explicitement ce cas tant qu'un lot ultérieur n'ouvre
    // pas une sémantique battle claire pour ce type d'exécution.
    if (move.usesStandardDamageFlow && target == BattleMoveTarget.self) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'unsupported_standard_damage_target:self',
      );
    }

    return BattleMoveData(
      id: move.id,
      name: move.name,
      power: move.usesStandardDamageFlow ? move.basePower : 0,
      type: type,
      category: _translateCategory(move.category),
      target: target,
      accuracy: accuracy,
      pp: move.pp,
      priority: move.priority,
      selfStatStageChanges:
          List<BattleStatStageChange>.unmodifiable(selfChanges),
      targetStatStageChanges:
          List<BattleStatStageChange>.unmodifiable(targetChanges),
    );
  }

  void _ensureEngineSupportLevelAllowsBridge({
    required PokemonMove move,
    required String combatantLabel,
  }) {
    if (move.engineSupportLevel ==
        PokemonMoveEngineSupportLevel.structuredSupported) {
      return;
    }
    _rejectMove(
      move: move,
      combatantLabel: combatantLabel,
      bridgeLimit: 'engine_support_level_not_bridgeable',
    );
  }

  BattleMoveAccuracy _translateAccuracy(PokemonMoveAccuracy accuracy) {
    return accuracy.map(
      percent: (accuracy) => BattleMoveAccuracy.percent(value: accuracy.value),
      alwaysHits: (_) => const BattleMoveAccuracy.alwaysHits(),
    );
  }

  void _ensureCritRatioIsNeutralEnoughForBattle({
    required PokemonMove move,
    required String combatantLabel,
  }) {
    // Même logique pour le critique :
    // - tant que le moteur n'a aucun crit réel ;
    // - un crit ratio non neutre serait perdu silencieusement ;
    // - on refuse donc le move au bridge au lieu de prétendre le supporter.
    if (move.critRatio == 1) {
      return;
    }
    _rejectMove(
      move: move,
      combatantLabel: combatantLabel,
      bridgeLimit: 'unsupported_crit_ratio:${move.critRatio}',
    );
  }

  String _translateType({
    required PokemonMove move,
    required String combatantLabel,
  }) {
    final normalizedType = move.type.trim().toLowerCase();
    if (normalizedType.isEmpty) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'invalid_type:empty',
      );
    }

    // Même règle qu'au chargement des espèces :
    // - la liste des types réellement supportés ne doit vivre qu'à un seul
    //   endroit ;
    // - le bridge réutilise donc `BattleTypeChart.supportedTypes` au lieu de
    //   maintenir une seconde liste locale ;
    // - cela permet de rejeter le move au bon seam runtime -> battle, avec
    //   une erreur actionnable, plutôt que de laisser `map_battle` exploser
    //   plus tard par `StateError`.
    if (!BattleTypeChart.supportedTypes.contains(normalizedType)) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'unsupported_type:$normalizedType',
      );
    }

    return normalizedType;
  }

  BattleMoveCategory _translateCategory(PokemonMoveCategory category) {
    return switch (category) {
      PokemonMoveCategory.physical => BattleMoveCategory.physical,
      PokemonMoveCategory.special => BattleMoveCategory.special,
      PokemonMoveCategory.status => BattleMoveCategory.status,
    };
  }

  BattleMoveTarget _translateSupportedTarget({
    required PokemonMove move,
    required String combatantLabel,
  }) {
    // BE1 ne promet toujours pas un système de targeting complet.
    // En revanche, on peut déjà arrêter de perdre silencieusement l'intention
    // canonique quand elle reste honnête en 1v1 simple actif :
    // - `self` -> self ;
    // - `normal`, `adjacentFoe`, `allAdjacentFoes`, `randomNormal`
    //   -> opponent.
    //
    // Les autres formes (`all`, `allySide`, `foeSide`, etc.) exigent une
    // sémantique de terrain/sides/slots ou de multibattle absente aujourd'hui.
    return switch (move.target) {
      PokemonMoveTarget.self => BattleMoveTarget.self,
      PokemonMoveTarget.normal ||
      PokemonMoveTarget.adjacentFoe ||
      PokemonMoveTarget.allAdjacentFoes ||
      PokemonMoveTarget.randomNormal =>
        BattleMoveTarget.opponent,
      _ => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_target:${move.target.name}',
        ),
    };
  }

  BattleStatStageChange _translateStageChange({
    required PokemonMoveStatStageChange change,
    required PokemonMove move,
    required String combatantLabel,
  }) {
    final stat = switch (change.stat) {
      PokemonMoveStatId.attack => BattleStatId.attack,
      PokemonMoveStatId.defense => BattleStatId.defense,
      PokemonMoveStatId.specialAttack => BattleStatId.specialAttack,
      PokemonMoveStatId.specialDefense => BattleStatId.specialDefense,
      // BE3 ouvre ici la plus petite extension honnête possible :
      // - `speed` stage devient enfin utile car le moteur ordonne désormais
      //   les deux actions `Fight` par vitesse effective ;
      // - on ne profite pas de cette ouverture pour accepter accuracy/evasion,
      //   qui resteraient mensongères sans hit pipeline réel.
      PokemonMoveStatId.speed => BattleStatId.speed,
      PokemonMoveStatId.accuracy => _rejectUnsupportedStat(
          move: move,
          combatantLabel: combatantLabel,
          stat: change.stat,
        ),
      PokemonMoveStatId.evasion => _rejectUnsupportedStat(
          move: move,
          combatantLabel: combatantLabel,
          stat: change.stat,
        ),
    };

    return BattleStatStageChange(
      stat: stat,
      stages: change.stages,
    );
  }

  Never _rejectUnsupportedStat({
    required PokemonMove move,
    required String combatantLabel,
    required PokemonMoveStatId stat,
  }) {
    _rejectMove(
      move: move,
      combatantLabel: combatantLabel,
      bridgeLimit: 'unsupported_stat_stage:${stat.name}',
    );
  }

  Never _rejectMove({
    required PokemonMove move,
    required String combatantLabel,
    required String bridgeLimit,
  }) {
    final unsupportedReasons = move.unsupportedReasons.isEmpty
        ? '[]'
        : '[${move.unsupportedReasons.join(', ')}]';
    throw RuntimeBattleSetupException(
      'Le combat ne peut pas démarrer car "$combatantLabel" utilise une attaque que le bridge battle actuel ne sait pas projeter honnêtement.',
      debugDetails:
          'combatant=$combatantLabel, moveId=${move.id}, moveName=${move.name}, engineSupportLevel=${move.engineSupportLevel.name}, unsupportedReasons=$unsupportedReasons, bridgeLimit=$bridgeLimit',
    );
  }
}
```

### `/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_pokemon_species_loader_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_exception.dart';
import 'package:map_runtime/src/application/runtime_pokemon_species_loader.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RuntimePokemonSpeciesLoader', () {
    late Directory tempProjectRoot;
    const loader = RuntimePokemonSpeciesLoader();

    setUp(() async {
      tempProjectRoot =
          await Directory.systemTemp.createTemp('runtime_species_loader_');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    test('loads a species by declared id even when the filename differs',
        () async {
      await _writeSpeciesFile(
        tempProjectRoot,
        relativePath: 'custom/pokemon/species/not-the-id.json',
        json: _speciesJson(
          id: 'sproutle',
          baseHp: 45,
          primaryAbilityId: 'overgrow',
          learnsetRef: 'sproutle',
        ),
      );

      final species = await loader.loadById(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        speciesId: 'sproutle',
      );

      expect(species.id, equals('sproutle'));
      expect(species.typing, equals(const <String>['grass']));
      expect(species.baseHp, equals(45));
      expect(species.baseAttack, equals(49));
      expect(species.baseDefense, equals(49));
      expect(species.baseSpecialAttack, equals(65));
      expect(species.baseSpecialDefense, equals(65));
      expect(species.baseSpeed, equals(45));
      expect(species.primaryAbilityId, equals('overgrow'));
      expect(species.learnsetRef, equals('sproutle'));
    });

    test('fails explicitly when the species is absent', () async {
      await _writeSpeciesFile(
        tempProjectRoot,
        relativePath: 'custom/pokemon/species/other.json',
        json: _speciesJson(
          id: 'aquafi',
          baseHp: 44,
          primaryAbilityId: 'torrent',
          learnsetRef: 'aquafi',
        ),
      );

      await expectLater(
        () => loader.loadById(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          speciesId: 'sproutle',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.message,
            'message',
            contains('Espèce Pokémon introuvable'),
          ),
        ),
      );
    });

    test('fails explicitly when multiple files declare the same species id',
        () async {
      await _writeSpeciesFile(
        tempProjectRoot,
        relativePath: 'custom/pokemon/species/001-a.json',
        json: _speciesJson(
          id: 'sproutle',
          baseHp: 45,
          primaryAbilityId: 'overgrow',
          learnsetRef: 'sproutle',
        ),
      );
      await _writeSpeciesFile(
        tempProjectRoot,
        relativePath: 'custom/pokemon/species/001-b.json',
        json: _speciesJson(
          id: 'sproutle',
          baseHp: 46,
          primaryAbilityId: 'chlorophyll',
          learnsetRef: 'sproutle_alt',
        ),
      );

      await expectLater(
        () => loader.loadById(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          speciesId: 'sproutle',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>()
              .having(
                (error) => error.message,
                'message',
                contains('même id'),
              )
              .having(
                (error) => error.debugDetails,
                'debugDetails',
                contains('speciesId=sproutle'),
              ),
        ),
      );
    });

    test('fails explicitly when a species JSON file is invalid', () async {
      await _writeRawProjectRelativeFile(
        tempProjectRoot,
        'custom/pokemon/species/broken.json',
        '{ not valid json',
      );

      await expectLater(
        () => loader.loadById(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          speciesId: 'sproutle',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('Pokemon species file parse failed'),
              contains('broken.json'),
            ),
          ),
        ),
      );
    });

    test('loads a dual-typed species honestly', () async {
      await _writeSpeciesFile(
        tempProjectRoot,
        relativePath: 'custom/pokemon/species/dual.json',
        json: _speciesJson(
          id: 'aquadrake',
          baseHp: 79,
          primaryAbilityId: 'torrent',
          learnsetRef: 'aquadrake',
          typing: const <String>['water', 'dragon'],
        ),
      );

      final species = await loader.loadById(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        speciesId: 'aquadrake',
      );

      expect(species.typing, equals(const <String>['water', 'dragon']));
    });

    test('fails explicitly when a mono-typing uses an unsupported battle type',
        () async {
      await _writeSpeciesFile(
        tempProjectRoot,
        relativePath: 'custom/pokemon/species/unsupported-mono.json',
        json: _speciesJson(
          id: 'sparkitten',
          baseHp: 39,
          primaryAbilityId: 'static',
          learnsetRef: 'sparkitten',
          typing: const <String>['electrik'],
        ),
      );

      await expectLater(
        () => loader.loadById(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          speciesId: 'sparkitten',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>()
              .having(
                (error) => error.message,
                'message',
                contains('données d’espèce Pokémon locales sont invalides'),
              )
              .having(
                (error) => error.debugDetails,
                'debugDetails',
                allOf(
                  contains('speciesId=sparkitten'),
                  contains('unsupported typing.types entry=electrik'),
                  contains('unsupported-mono.json'),
                ),
              ),
        ),
      );
    });

    test(
        'fails explicitly when a dual-typing contains an unsupported battle type',
        () async {
      await _writeSpeciesFile(
        tempProjectRoot,
        relativePath: 'custom/pokemon/species/unsupported-dual.json',
        json: _speciesJson(
          id: 'tidalwyrm',
          baseHp: 79,
          primaryAbilityId: 'torrent',
          learnsetRef: 'tidalwyrm',
          typing: const <String>['water', 'cosmic'],
        ),
      );

      await expectLater(
        () => loader.loadById(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          speciesId: 'tidalwyrm',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('speciesId=tidalwyrm'),
              contains('unsupported typing.types entry=cosmic'),
              contains('unsupported-dual.json'),
            ),
          ),
        ),
      );
    });

    test('fails explicitly when runtime-required species fields are broken',
        () async {
      await _writeSpeciesFile(
        tempProjectRoot,
        relativePath: 'custom/pokemon/species/broken-fields.json',
        json: <String, dynamic>{
          'id': 'sproutle',
          'baseStats': <String, int>{
            'atk': 49,
          },
        },
      );

      await expectLater(
        () => loader.loadById(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          speciesId: 'sproutle',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('missing or invalid baseStats.hp'),
          ),
        ),
      );
    });

    test('fails explicitly when typing is missing or invalid', () async {
      await _writeSpeciesFile(
        tempProjectRoot,
        relativePath: 'custom/pokemon/species/broken-typing.json',
        json: <String, dynamic>{
          'id': 'sproutle',
          'typing': <String, Object>{
            'types': <String>['grass', 'grass'],
          },
          'baseStats': <String, int>{
            'hp': 45,
            'atk': 49,
            'def': 49,
            'spa': 65,
            'spd': 65,
            'spe': 45,
          },
          'abilities': <String, String>{'primary': 'overgrow'},
          'refs': <String, String>{'learnset': 'sproutle'},
        },
      );

      await expectLater(
        () => loader.loadById(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          speciesId: 'sproutle',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('typing.types contains an empty or duplicate entry'),
          ),
        ),
      );
    });
  });
}

ProjectPokemonConfig _pokemonConfig() {
  return const ProjectPokemonConfig(
    dataRoot: 'custom/pokemon',
    speciesDir: 'custom/pokemon/species',
    learnsetsDir: 'custom/pokemon/learnsets',
    evolutionsDir: 'custom/pokemon/evolutions',
    mediaDir: 'custom/pokemon/media',
    catalogFiles: <String, String>{
      'moves': 'custom/pokemon/catalogs/moves.json',
    },
  );
}

Map<String, dynamic> _speciesJson({
  required String id,
  required int baseHp,
  required String primaryAbilityId,
  required String learnsetRef,
  int baseAttack = 49,
  int baseDefense = 49,
  int baseSpecialAttack = 65,
  int baseSpecialDefense = 65,
  int baseSpeed = 45,
  List<String> typing = const <String>['grass'],
}) {
  return <String, dynamic>{
    'id': id,
    'typing': <String, Object>{
      'types': typing,
    },
    'baseStats': <String, int>{
      'hp': baseHp,
      'atk': baseAttack,
      'def': baseDefense,
      'spa': baseSpecialAttack,
      'spd': baseSpecialDefense,
      'spe': baseSpeed,
    },
    'abilities': <String, String>{
      'primary': primaryAbilityId,
    },
    'refs': <String, String>{
      'learnset': learnsetRef,
    },
  };
}

Future<void> _writeSpeciesFile(
  Directory projectRoot, {
  required String relativePath,
  required Map<String, dynamic> json,
}) {
  return _writeProjectRelativeJson(projectRoot, relativePath, json);
}

Future<void> _writeProjectRelativeJson(
  Directory projectRoot,
  String relativePath,
  Map<String, dynamic> json,
) async {
  final absolutePath = p.join(projectRoot.path, relativePath);
  final file = File(absolutePath);
  await file.parent.create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}

Future<void> _writeRawProjectRelativeFile(
  Directory projectRoot,
  String relativePath,
  String rawContent,
) async {
  final absolutePath = p.join(projectRoot.path, relativePath);
  final file = File(absolutePath);
  await file.parent.create(recursive: true);
  await file.writeAsString(rawContent);
}
```

### `/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_move_bridge_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_battle_move_bridge.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_exception.dart';

void main() {
  group('RuntimeBattleMoveBridge', () {
    const bridge = RuntimeBattleMoveBridge();

    test('projects a standard damage move without destroying canonical data',
        () {
      const move = PokemonMove(
        id: 'vine_whip',
        name: 'Vine Whip',
        names: <String, String>{'en': 'Vine Whip'},
        generation: 1,
        source: 'test',
        type: 'grass',
        category: PokemonMoveCategory.physical,
        target: PokemonMoveTarget.normal,
        basePower: 45,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 25,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.id, equals('vine_whip'));
      expect(battleMove.power, equals(45));
      expect(battleMove.type, equals('grass'));
      expect(battleMove.category, equals(BattleMoveCategory.physical));
      expect(battleMove.target, equals(BattleMoveTarget.opponent));
      expect(
        battleMove.accuracy.kind,
        equals(BattleMoveAccuracyKind.percent),
      );
      expect(battleMove.accuracy.value, equals(100));
      expect(battleMove.pp, equals(25));
      expect(battleMove.selfStatStageChanges, isEmpty);
      expect(battleMove.targetStatStageChanges, isEmpty);
    });

    test('projects a deterministic target stat drop move honestly', () {
      const move = PokemonMove(
        id: 'growl',
        name: 'Growl',
        names: <String, String>{'en': 'Growl'},
        generation: 1,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.allAdjacentFoes,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 40,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.modifyStats(
            targetScope: PokemonMoveEffectTargetScope.target,
            stageChanges: <PokemonMoveStatStageChange>[
              PokemonMoveStatStageChange(
                stat: PokemonMoveStatId.attack,
                stages: -1,
              ),
            ],
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.power, equals(0));
      expect(battleMove.type, equals('normal'));
      expect(battleMove.category, equals(BattleMoveCategory.status));
      expect(battleMove.target, equals(BattleMoveTarget.opponent));
      expect(battleMove.pp, equals(40));
      expect(battleMove.selfStatStageChanges, isEmpty);
      expect(battleMove.targetStatStageChanges, hasLength(1));
      expect(
        battleMove.targetStatStageChanges.single.stat,
        equals(BattleStatId.attack),
      );
      expect(
        battleMove.targetStatStageChanges.single.stages,
        equals(-1),
      );
    });

    test('projects a deterministic self stat boost move honestly', () {
      const move = PokemonMove(
        id: 'swords_dance',
        name: 'Swords Dance',
        names: <String, String>{'en': 'Swords Dance'},
        generation: 1,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.self,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 20,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.modifyStats(
            targetScope: PokemonMoveEffectTargetScope.self,
            stageChanges: <PokemonMoveStatStageChange>[
              PokemonMoveStatStageChange(
                stat: PokemonMoveStatId.attack,
                stages: 2,
              ),
            ],
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.power, equals(0));
      expect(battleMove.selfStatStageChanges, hasLength(1));
      expect(
        battleMove.selfStatStageChanges.single.stat,
        equals(BattleStatId.attack),
      );
      expect(
        battleMove.selfStatStageChanges.single.stages,
        equals(2),
      );
      expect(battleMove.target, equals(BattleMoveTarget.self));
      expect(battleMove.pp, equals(20));
      expect(battleMove.targetStatStageChanges, isEmpty);
    });

    test(
        'rejects a self-target damage move that map_battle would still resolve against the opponent',
        () {
      const move = PokemonMove(
        id: 'mind_blown_self',
        name: 'Mind Blown Self',
        names: <String, String>{'en': 'Mind Blown Self'},
        generation: 9,
        source: 'test',
        type: 'fire',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.self,
        basePower: 50,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 5,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('moveId=mind_blown_self'),
              contains('bridgeLimit=unsupported_standard_damage_target:self'),
            ),
          ),
        ),
      );
    });

    test(
        'projects a move with non-zero priority once battle order consumes it honestly',
        () {
      const move = PokemonMove(
        id: 'quick_attack',
        name: 'Quick Attack',
        names: <String, String>{'en': 'Quick Attack'},
        generation: 1,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.physical,
        target: PokemonMoveTarget.normal,
        basePower: 40,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 30,
        priority: 1,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.id, equals('quick_attack'));
      expect(battleMove.priority, equals(1));
      expect(battleMove.power, equals(40));
      expect(battleMove.target, equals(BattleMoveTarget.opponent));
    });

    test('projects a deterministic speed boost move honestly', () {
      const move = PokemonMove(
        id: 'agility',
        name: 'Agility',
        names: <String, String>{'en': 'Agility'},
        generation: 1,
        source: 'test',
        type: 'psychic',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.self,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 30,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.modifyStats(
            targetScope: PokemonMoveEffectTargetScope.self,
            stageChanges: <PokemonMoveStatStageChange>[
              PokemonMoveStatStageChange(
                stat: PokemonMoveStatId.speed,
                stages: 2,
              ),
            ],
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.power, equals(0));
      expect(battleMove.target, equals(BattleMoveTarget.self));
      expect(battleMove.selfStatStageChanges, hasLength(1));
      expect(
        battleMove.selfStatStageChanges.single.stat,
        equals(BattleStatId.speed),
      );
      expect(
        battleMove.selfStatStageChanges.single.stages,
        equals(2),
      );
    });

    test(
        'projects a move with non-trivial percent accuracy once battle owns the hit check',
        () {
      const move = PokemonMove(
        id: 'fire_blast',
        name: 'Fire Blast',
        names: <String, String>{'en': 'Fire Blast'},
        generation: 1,
        source: 'test',
        type: 'fire',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 110,
        accuracy: PokemonMoveAccuracy.percent(value: 85),
        pp: 5,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.id, equals('fire_blast'));
      expect(
        battleMove.accuracy.kind,
        equals(BattleMoveAccuracyKind.percent),
      );
      expect(battleMove.accuracy.value, equals(85));
      expect(battleMove.pp, equals(5));
    });

    test(
        'rejects a move whose type is not actually supported by the current battle type chart',
        () {
      const move = PokemonMove(
        id: 'typo_bolt',
        name: 'Typo Bolt',
        names: <String, String>{'en': 'Typo Bolt'},
        generation: 1,
        source: 'test',
        type: 'electrik',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 80,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 15,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('moveId=typo_bolt'),
              contains('moveName=Typo Bolt'),
              contains('bridgeLimit=unsupported_type:electrik'),
            ),
          ),
        ),
      );
    });

    test(
        'rejects a move whose non-neutral crit ratio would still be lost by the current battle engine',
        () {
      const move = PokemonMove(
        id: 'razor_leaf',
        name: 'Razor Leaf',
        names: <String, String>{'en': 'Razor Leaf'},
        generation: 1,
        source: 'test',
        type: 'grass',
        category: PokemonMoveCategory.physical,
        target: PokemonMoveTarget.allAdjacentFoes,
        basePower: 55,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 25,
        critRatio: 2,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('moveId=razor_leaf'),
              contains('bridgeLimit=unsupported_crit_ratio:2'),
            ),
          ),
        ),
      );
    });

    test(
        'rejects a target shape that is still outside the honest 1v1 bridge subset',
        () {
      const move = PokemonMove(
        id: 'stealth_rock',
        name: 'Stealth Rock',
        names: <String, String>{'en': 'Stealth Rock'},
        generation: 4,
        source: 'test',
        type: 'rock',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.foeSide,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 20,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('moveId=stealth_rock'),
              contains('bridgeLimit=unsupported_target:foeSide'),
            ),
          ),
        ),
      );
    });

    test('rejects a status move that needs a real battle status system', () {
      const move = PokemonMove(
        id: 'thunder_wave',
        name: 'Thunder Wave',
        names: <String, String>{'en': 'Thunder Wave'},
        generation: 1,
        source: 'test',
        type: 'electric',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.normal,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 20,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.applyStatus(
            targetScope: PokemonMoveEffectTargetScope.target,
            statusId: 'par',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('moveId=thunder_wave'),
              contains('engineSupportLevel=structuredSupported'),
              contains('bridgeLimit=unsupported_effect_kind:apply_status'),
            ),
          ),
        ),
      );
    });

    test('rejects a probabilistic secondary effect that would lie without RNG',
        () {
      const move = PokemonMove(
        id: 'thunderbolt',
        name: 'Thunderbolt',
        names: <String, String>{'en': 'Thunderbolt'},
        generation: 1,
        source: 'test',
        type: 'electric',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 90,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 15,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.applyStatus(
            targetScope: PokemonMoveEffectTargetScope.target,
            chance: 10,
            statusId: 'par',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('moveId=thunderbolt'),
              contains('bridgeLimit=unsupported_effect_kind:apply_status'),
            ),
          ),
        ),
      );
    });

    test(
        'still rejects unsupported effect families even when accuracy is now bridgeable',
        () {
      const move = PokemonMove(
        id: 'sleep_powder',
        name: 'Sleep Powder',
        names: <String, String>{'en': 'Sleep Powder'},
        generation: 1,
        source: 'test',
        type: 'grass',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.normal,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.percent(value: 75),
        pp: 15,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.applyStatus(
            targetScope: PokemonMoveEffectTargetScope.target,
            statusId: 'slp',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('bridgeLimit=unsupported_effect_kind:apply_status'),
          ),
        ),
      );
    });
  });
}
```
