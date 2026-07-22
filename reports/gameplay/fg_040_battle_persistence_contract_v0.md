# Lot 2.1 — FG-020 / FG-021 / FG-040 — PlayerPokemon Persistence Expansion V0

## Résumé exécutif

Le lot étend `PlayerPokemon` avec l'XP totale nullable et les PP courants nullable, conserve `null` comme sentinelle legacy, hydrate ces valeurs depuis les données projet avant que le runtime devienne jouable ou qu'une conséquence narrative publie un nouveau Pokémon possédé, et refuse les états invalides avec des erreurs explicites. Le niveau legacy 16 reste 16 et reçoit exactement 2535 XP sur la courbe `medium_slow`.

Statuts proposés, sans modification de la roadmap :

- FG-020 : `DONE` proposé — audit champ par champ repris ci-dessous.
- FG-021 : `DONE` proposé — modèle, migration, normalisation et round-trip prouvés.
- FG-040 : `DONE` proposé comme lot de contrat/audit — le contrat de write-back est gelé ci-dessous.
- FG-041 et suivants : restent `TODO` ; ce lot ne fait aucun write-back PP post-combat ni attribution d'XP.

## Confirmation du scope et audit du prompt

Le scope exécuté est celui de Task 2.1 : persistance, migration/hydratation catalogue et intégration boot/load. Aucun moteur battle, reward, level-up, move learning ou évolution n'a été modifié.

Deux tensions ont été arbitrées :

1. `codex_rule.md` demande des sub-agents, mais la demande directe interdit d'en créer. La priorité des instructions impose zéro délégation ; les cinq passes nommées sont consignées plus bas.
2. Le catalogue `growth_rates` actuel décrit les courbes sans porter les seuils. L'espèce canonique porte `progression.growthRateId`; le loader projette donc cet id et le calcul d'hydratation applique la courbe canonique. Cette logique reste dans un service application pur, jamais dans Flame ou `map_core`.

Documentation Flame consultée : recherche `FlameGame onLoad lifecycle loading assets and state before game becomes playable`, aucun résultat MCP. L'intégration s'appuie donc sur le `onLoad` existant et ses tests de production.

## État Git initial

- HEAD : `a5ed1de2d1cb27f402d7525e51e8570fca48499e`.
- `git status --short --untracked-files=all` : aucune sortie.
- Branche : main courant explicitement autorisé par la demande.
- Aucun push demandé ni effectué.

## Audit initial des contrats

| Champ PlayerPokemon | Avant | Après ce lot | Contrat battle/write-back |
|---|---|---|---|
| speciesId | persistant | inchangé | résolu par catalogue |
| level | persistant | inchangé, jamais recalculé pendant migration | progression FG-045 |
| experience | absent | `int?`, `null` legacy, XP totale | attribution FG-044 |
| currentHp | persistant | inchangé | write-back HP déjà existant |
| knownMoveIds | persistant | inchangé | apprentissage FG-046 |
| currentPpByMoveId | absent | `Map<String,int>?`, `null` legacy | write-back FG-041 |
| statusId | persistant | inchangé | write-back FG-042 |
| heldItemId | persistant | inchangé | mutation battle différée |
| nature/ability/gender | persistants | inchangés | lecture catalogue/runtime |
| IV/EV/shiny | persistants | inchangés | hors progression de ce lot |
| maxHp/maxPp | non persistés | restent dérivés | catalogues/stat calculator |
| form/met/friendship | absents | restent hors scope MVP de ce lot | non-objectifs |

Points d'intégration audités :

- `gameStateFromSaveData` normalise déjà `SaveData` puis transporte party/storage.
- `saveDataFromGameState` transporte party/storage sans projection destructrice.
- `PlayableMapGame.onLoad` est le dernier point asynchrone avant construction du monde jouable.
- `PlayableMapGame.loadGame` charge le bundle cible avant sa phase destructive ; l'hydratation y est placée avant l'assignation de `_gameState`.
- Le catalogue moves canonique expose `PokemonMove.pp`.
- Les fichiers espèce exposent `progression.growthRateId`.

Risques initiaux préservés : ancienne save niveau > 1 sans XP, valeur `null` confondue avec zéro, PP réinitialisés à chaque boot, attaque inconnue acceptée, logique métier cachée dans Flame, et état narratif lisant un snapshot pré-hydraté.

## Correctif P1 issu de la revue qualité

État Git au début de la reprise :

- HEAD : `dd945f8308695ff1452e0cc514ec575b3fb5ab34` (`feat(core): persist Pokemon experience and PP`).
- `git status --short --untracked-files=all` : aucune sortie.

Finding confirmé : le boot et `loadGame()` étaient hydratés, mais le projet Selbrume démarre avec `initialParty: []`. La conséquence `giveConfiguredStarter` copie ensuite le Pokémon authored depuis `newGame.starterOptions` dans `SceneConsequenceRuntimeWriter`, donc après l'hydratation du boot. Le premier état jouable après la scène gardait `experience == null` et `currentPpByMoveId == null`.

Décision d'architecture :

- le writer reste synchrone et sans I/O ; son test continue de prouver qu'il copie exactement le Pokémon authored ;
- `PlayableMapGame` porte un seam asynchrone unique `_hydrateOwnedPlayerPokemonProgression`, déjà utilisé par boot/load ;
- après une Scene V2 terminée, l'état complet est hydraté avant d'être retourné au coordinateur et donc avant le commit narratif ; une erreur catalogue devient un résultat de scène échoué, sans publication partielle ;
- après une Scene V1 réussie, la même hydratation précède `_applyNarrativeGameState` ; une erreur suit le fail-closed existant ;
- le seam couvre donc `giveConfiguredStarter` et `givePokemon` des conséquences Scene V1/V2. La capture et les autres admissions hors Scene restent explicitement hors lot 2.1.

Preuve projet canonique : Bulbizarre authored niveau 16, courbe `medium_slow`, moves `tackle`, `growl`, `vine_whip`, devient jouable avec exactement 2535 XP et les PP max canoniques 35/40/25. Ces valeurs sont présentes dans l'état immédiatement après la conséquence, dans le repository après sauvegarde, puis après rechargement.

## Contrat FG-040 — Battle Persistence Contract V0

### État qui doit revenir du combat

| Donnée | Clé de corrélation | Règle |
|---|---|---|
| HP courant | `partyIndex` stable | réécrire le membre engagé, sans toucher les autres |
| PP courant | `partyIndex + moveId` | écrire dans `currentPpByMoveId`; max PP reste catalogue |
| statut majeur | `partyIndex` | écrire `statusId` selon le bridge FG-042 |
| held item | `partyIndex` | persister seulement si une mécanique consomme/change réellement l'objet |
| XP totale | `partyIndex` | ajouter les gains calculés, jamais depuis une sentinelle `null` |
| niveau | `partyIndex` | dériver depuis XP/courbe, cap 100 dans FG-045 |
| moves | `partyIndex + moveId` | ajout/remplacement explicite dans FG-046 |
| évolution | `partyIndex` | produire une décision pending ; aucun remplacement silencieux d'espèce |

### Mapping lineup vers party

Le futur handoff FG-041 doit conserver pour chaque combattant joueur le `partyIndex` d'origine. L'ordre actif après switch n'est pas une clé de persistance. Le write-back doit appliquer chaque snapshot final au slot corrélé, y compris plusieurs membres engagés, et ignorer les combattants adverses/copies temporaires. Ce lot ne modifie pas le moteur pour ajouter cette corrélation ; il gèle le contrat.

### Non-objectifs

- aucun write-back PP/status/held item ;
- aucune distribution d'XP ou argent ;
- aucun calcul de level-up/stat max ;
- aucun apprentissage de move ou évolution ;
- aucun IV/EV/friendship/met metadata supplémentaire ;
- aucun changement de `map_battle`.

## Fichiers et zones modifiés

| Fichier | Zone | Raison / impact |
|---|---|---|
| `packages/map_core/lib/src/models/save_data.dart` | factory et `normalized()` de `PlayerPokemon` | ajoute les sentinelles nullable et validations structurelles sans catalogue |
| `packages/map_core/lib/src/models/save_data.freezed.dart` | API Freezed générée PlayerPokemon | copyWith, égalité, debug et champs générés |
| `packages/map_core/lib/src/models/save_data.g.dart` | JSON généré PlayerPokemon | lecture/écriture explicite de `experience` et `currentPpByMoveId` |
| `packages/map_core/test/save_data_test.dart` | groupe PlayerPokemon | legacy, round-trip, XP/PP négatifs, clé vide |
| `packages/map_core/test/game_state_persistence_test.dart` | saveDataFromGameState | round-trip GameState/SaveData des deux champs |
| `packages/map_runtime/lib/src/application/runtime_player_pokemon_progression_hydrator.dart` | nouveau service + loader | hydratation pure, courbes, erreurs typées, projection catalogue |
| `packages/map_runtime/test/runtime_player_pokemon_progression_hydrator_test.dart` | nouveau test | party/storage, niveau 16, erreurs, loader réel, New Game et loadGame |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | constructeur, helper partagé, `onLoad`, Scene V1/V2, `_loadGameWithActivationWorkAcquired` | charge/hydrate avant jouabilité, avant commit narratif et avant phase destructive de load |
| `packages/map_runtime/lib/map_runtime.dart` | barrel application | exporte le nouveau contrat public |
| `packages/map_runtime/test/selbrume_new_game_starter_integration_test.dart` | chemin canonical no-save starter | prouve party vide, admission du starter hydraté, save/reload non-null et idempotence narrative |
| `reports/gameplay/fg_040_battle_persistence_contract_v0.md` | nouveau rapport/contrat | evidence pack du lot ; ne se duplique pas récursivement |

## TDD rouge puis vert

Premier RED obligatoire :

```text
cd packages/map_core
dart test test/save_data_test.dart --name "legacy JSON preserves missing progression fields as null sentinels"
exit 1
Expected: contains pair 'experience' => <null>
Actual: JSON sans clé 'experience'
```

RED étendu modèle/persistance : exit 1 avec 6 échecs attendus (clés absentes, XP/PP négatifs acceptés avant implémentation).

RED hydrateur : exit 1, API `RuntimePlayerPokemonProgressionCatalogs` et fonction d'hydratation absentes.

RED intégration : exit 1, paramètre `runtimePlayerPokemonProgressionCatalogLoader` absent de `PlayableMapGame`.

RED correctif P1 :

```text
cd packages/map_runtime
flutter test test/selbrume_new_game_starter_integration_test.dart --plain-name "canonical no-save boot gives the selected starter exactly once"
exit 1
Expected: <2535>
Actual: <null>
test/selbrume_new_game_starter_integration_test.dart:82
```

GREEN : tests ciblés finaux détaillés ci-dessous.

## Commandes et résultats exacts

```text
cd packages/map_core
dart run build_runner build --delete-conflicting-outputs
exit 0 — Built with build_runner in 2s; wrote 0 outputs.
```

```text
cd packages/map_core
dart test test/save_data_test.dart test/game_state_persistence_test.dart
exit 0 — +46: All tests passed!
dart analyze
exit 0 — No issues found!
```

```text
cd packages/map_runtime
flutter test test/runtime_player_pokemon_progression_hydrator_test.dart
exit 0 — +12: All tests passed!
```

```text
cd packages/map_runtime
flutter test test/playable_map_game_project_new_game_boot_test.dart test/playable_map_game_map_enter_v2_integration_test.dart
exit 0 — +4: All tests passed!
flutter analyze
exit 0 — No issues found! (ran in 3.4s)
```

Correctif P1 :

```text
cd packages/map_runtime
flutter test test/selbrume_new_game_starter_integration_test.dart --plain-name "canonical no-save boot gives the selected starter exactly once"
exit 0 — +1: All tests passed!

flutter test test/selbrume_new_game_starter_integration_test.dart test/runtime_player_pokemon_progression_hydrator_test.dart test/scene_consequence_runtime_writer_test.dart test/scene_event_runtime_hook_test.dart test/playable_map_game_project_new_game_boot_test.dart
exit 0 — +65: All tests passed!

flutter analyze
exit 0 — No issues found! (ran in 4.5s)
```

Le second test runtime journalise volontairement l'échec contrôlé `missing_save_target`; l'assertion attend `loadGame() == false` et la suite termine bien à `+4: All tests passed!`.

Build applicatif complet : non applicable à ces deux packages bibliothèque. Le build_runner ciblé map_core et les analyses Flutter/Dart sont les validations de compilation demandées. Aucune génération runtime n'a été lancée.

## Passes nommées exigées par codex_rule

- Passe Audit / Architecture — `PASS` : frontières map_core/runtime respectées ; aucun catalogue dans map_core ; finding P1 reproduit sur l'admission post-boot.
- Passe Implémentation — `PASS` : changements bornés aux champs, service, points de cycle de vie et frontière de commit Scene V1/V2.
- Passe Tests — `PASS` : positif, négatif, garde-fous, legacy niveau 16, New Game, admission starter, save/reload et loadGame couverts.
- Passe Build / Validation — `PASS` : commandes ciblées et analyses à exit 0.
- Passe Critique finale — `PASS WITH LIMITS` : aucun refactor annexe ; optimisation/cache du loader volontairement différée ; write-back battle non revendiqué.

## Limites, risques et auto-critique

- Le loader catalogue est volontairement minimal et non optimisé ; aucune optimisation n'est incluse dans ce lot.
- Toute Scene V1/V2 réussie repasse actuellement l'état possédé par le seam catalogue avant commit. Cette validation fail-closed est correcte ; un cache ou un fast-path demanderait des mesures et un lot séparé.
- Les courbes sont utilisées ici uniquement pour hydrater la sentinelle legacy. Le service gameplay de progression FG-044/045 restera la source des gains et level-ups.
- Une espèce sans `growthRateId`, un catalogue moves absent ou un move inconnu bloque honnêtement la jouabilité au lieu d'inventer une valeur.
- Les PP non-null sont conservés ; ce lot ne les soigne pas et ne les borne pas au max catalogue.
- Aucun test de suite complète `flutter test` n'a été lancé ; les tests ciblés touchés et les analyses demandées sont verts.
- Le rapport ne recopie pas son propre contenu afin d'éviter une duplication récursive.

## État Git final avant staging et commit

- Dix fichiers de code/test modifiés ou créés, plus ce rapport après amend du correctif P1.
- Aucun fichier hors lot détecté.
- `git diff --check` : aucune sortie, exit 0.
- Le statut post-commit est consigné dans le retour d'exécution, car l'écrire
  dans le commit nécessiterait un second commit ou un amend récursif.

## Prochaines étapes proposées, non implémentées

1. FG-041 : corrélation `partyIndex` et write-back PP après switch/multi-membres.
2. FG-042 : bridge status majeur.
3. FG-043/044/045 : rewards, XP réelle et level-up.
4. Mesurer puis optimiser le loader seulement si un lot dédié et une preuve de performance le justifient.

## Contenu complet des fichiers créés (hors ce rapport)

### packages/map_runtime/lib/src/application/runtime_player_pokemon_progression_hydrator.dart

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'runtime_move_catalog_loader.dart';

/// Machine-readable failures raised before a persisted Pokemon becomes
/// playable.
///
/// Catalogue-aware validation belongs in `map_runtime`, not `map_core`: the
/// save model owns only structural invariants and never reads project data.
enum RuntimePlayerPokemonProgressionHydrationErrorCode {
  negativeExperience,
  negativeCurrentPp,
  emptyMoveId,
  unknownMove,
  ppForUnlearnedMove,
  missingGrowthRate,
  unsupportedGrowthRate,
  invalidCatalogData,
}

/// Explicit hydration failure with enough context for a runtime load error.
final class RuntimePlayerPokemonProgressionHydrationException
    implements Exception {
  const RuntimePlayerPokemonProgressionHydrationException({
    required this.code,
    required this.message,
    required this.speciesId,
    this.moveId,
  });

  final RuntimePlayerPokemonProgressionHydrationErrorCode code;
  final String message;
  final String speciesId;
  final String? moveId;

  @override
  String toString() {
    final moveDetails = moveId == null ? '' : ', moveId=$moveId';
    return 'RuntimePlayerPokemonProgressionHydrationException('
        'code=${code.name}, speciesId=$speciesId$moveDetails): $message';
  }
}

/// The catalogue projection needed by the pure progression hydrator.
///
/// Keeping this projection as two maps prevents the save model from learning
/// about project files and prevents Flame components from owning migration
/// rules. The application layer loads these values before invoking [hydrateRuntimePlayerPokemonProgression].
final class RuntimePlayerPokemonProgressionCatalogs {
  const RuntimePlayerPokemonProgressionCatalogs({
    required this.growthRateIdBySpeciesId,
    required this.maxPpByMoveId,
  });

  final Map<String, String> growthRateIdBySpeciesId;
  final Map<String, int> maxPpByMoveId;
}

/// Async catalogue boundary injected into [PlayableMapGame] tests and used by
/// production boot/load orchestration.
typedef RuntimePlayerPokemonProgressionCatalogLoader
    = Future<RuntimePlayerPokemonProgressionCatalogs> Function({
  required GameState gameState,
  required String projectRootDirectory,
  required ProjectPokemonConfig pokemonConfig,
});

/// Loads only the catalogue projection required by legacy hydration.
///
/// This IO boundary intentionally stays separate from the pure hydrator. Move
/// PP comes from the canonical move catalogue. Growth rate ids come from the
/// canonical species records because the current growth-rate catalogue only
/// names curves and does not duplicate each species assignment.
Future<RuntimePlayerPokemonProgressionCatalogs>
    loadRuntimePlayerPokemonProgressionCatalogs({
  required GameState gameState,
  required String projectRootDirectory,
  required ProjectPokemonConfig pokemonConfig,
}) async {
  final pokemon = <PlayerPokemon>[
    ...gameState.party.members,
    ...gameState.pokemonStorage.storedPokemon,
  ];
  if (pokemon.isEmpty) {
    return const RuntimePlayerPokemonProgressionCatalogs(
      growthRateIdBySpeciesId: <String, String>{},
      maxPpByMoveId: <String, int>{},
    );
  }

  final requiredMoveIds = <String>{
    for (final member in pokemon)
      ...member.knownMoveIds.map((moveId) => moveId.trim()),
    for (final member in pokemon)
      ...?member.currentPpByMoveId?.keys.map((moveId) => moveId.trim()),
  }..remove('');
  final maxPpByMoveId = <String, int>{};
  if (requiredMoveIds.isNotEmpty) {
    final moveCatalog = await RuntimeMoveCatalogLoader().load(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
    );
    for (final moveId in requiredMoveIds) {
      final move = moveCatalog.lookup(moveId);
      if (move != null) maxPpByMoveId[moveId] = move.pp;
    }
  }

  final speciesNeedingGrowthRate = <String>{
    for (final member in pokemon)
      if (member.experience == null) member.speciesId.trim(),
  }..remove('');
  final growthRateIdBySpeciesId = speciesNeedingGrowthRate.isEmpty
      ? const <String, String>{}
      : await _loadGrowthRateIds(
          projectRootDirectory: projectRootDirectory,
          pokemonConfig: pokemonConfig,
          speciesIds: speciesNeedingGrowthRate,
        );

  return RuntimePlayerPokemonProgressionCatalogs(
    growthRateIdBySpeciesId:
        Map<String, String>.unmodifiable(growthRateIdBySpeciesId),
    maxPpByMoveId: Map<String, int>.unmodifiable(maxPpByMoveId),
  );
}

Future<Map<String, String>> _loadGrowthRateIds({
  required String projectRootDirectory,
  required ProjectPokemonConfig pokemonConfig,
  required Set<String> speciesIds,
}) async {
  final configuredSpeciesDirectory = pokemonConfig.speciesDir.trim().isEmpty
      ? 'data/pokemon/species'
      : pokemonConfig.speciesDir.trim();
  final speciesDirectory = Directory(
    p.isAbsolute(configuredSpeciesDirectory)
        ? p.normalize(configuredSpeciesDirectory)
        : p.normalize(
            p.join(projectRootDirectory, configuredSpeciesDirectory),
          ),
  );
  if (!await speciesDirectory.exists()) {
    throw RuntimePlayerPokemonProgressionHydrationException(
      code:
          RuntimePlayerPokemonProgressionHydrationErrorCode.invalidCatalogData,
      message: 'Pokemon species directory is missing.',
      speciesId: speciesIds.first,
    );
  }

  final jsonFiles = await speciesDirectory
      .list(recursive: false)
      .where((entity) => entity is File && p.extension(entity.path) == '.json')
      .cast<File>()
      .toList();
  final growthRateIds = <String, String>{};
  final parsedPaths = <String>{};

  Future<void> parseCandidate(File file) async {
    if (!parsedPaths.add(file.path)) return;
    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('JSON object expected');
      }
      json = decoded;
    } catch (error) {
      throw RuntimePlayerPokemonProgressionHydrationException(
        code: RuntimePlayerPokemonProgressionHydrationErrorCode
            .invalidCatalogData,
        message: 'Invalid Pokemon species catalogue file: ${file.path} '
            '($error)',
        speciesId: speciesIds.first,
      );
    }
    final speciesId = (json['id'] as String?)?.trim() ?? '';
    if (!speciesIds.contains(speciesId)) return;
    final progression = (json['progression'] as Map?)?.cast<String, dynamic>();
    final growthRateId =
        (progression?['growthRateId'] as String?)?.trim() ?? '';
    if (growthRateId.isNotEmpty) growthRateIds[speciesId] = growthRateId;
  }

  // Canonical files usually use either `<id>.json` or `<dex>-<id>.json`.
  // Parsing these candidates first avoids scanning every species at boot.
  for (final speciesId in speciesIds) {
    for (final file in jsonFiles) {
      final basename = p.basenameWithoutExtension(file.path);
      if (basename == speciesId || basename.endsWith('-$speciesId')) {
        await parseCandidate(file);
      }
    }
  }
  if (!growthRateIds.keys.toSet().containsAll(speciesIds)) {
    for (final file in jsonFiles) {
      await parseCandidate(file);
      if (growthRateIds.keys.toSet().containsAll(speciesIds)) break;
    }
  }

  return growthRateIds;
}

/// Hydrates legacy Pokemon progression sentinels and validates catalogue refs.
///
/// This function is deliberately synchronous and side-effect free. File IO
/// and catalogue caching remain runtime orchestration concerns. Both party and
/// storage are covered because either collection can later feed a battle.
GameState hydrateRuntimePlayerPokemonProgression({
  required GameState gameState,
  required RuntimePlayerPokemonProgressionCatalogs catalogs,
}) {
  PlayerPokemon hydrate(PlayerPokemon pokemon) {
    final speciesId = pokemon.speciesId.trim();
    final persistedExperience = pokemon.experience;
    if (persistedExperience != null && persistedExperience < 0) {
      throw RuntimePlayerPokemonProgressionHydrationException(
        code: RuntimePlayerPokemonProgressionHydrationErrorCode
            .negativeExperience,
        message: 'Pokemon experience must be non-negative.',
        speciesId: speciesId,
      );
    }

    final knownMoveIds = <String>[];
    for (final rawMoveId in pokemon.knownMoveIds) {
      final moveId = rawMoveId.trim();
      if (moveId.isEmpty) {
        throw RuntimePlayerPokemonProgressionHydrationException(
          code: RuntimePlayerPokemonProgressionHydrationErrorCode.emptyMoveId,
          message: 'Known move ids must not be empty.',
          speciesId: speciesId,
          moveId: rawMoveId,
        );
      }
      if (!catalogs.maxPpByMoveId.containsKey(moveId)) {
        throw RuntimePlayerPokemonProgressionHydrationException(
          code: RuntimePlayerPokemonProgressionHydrationErrorCode.unknownMove,
          message: 'Known move is absent from the runtime move catalogue.',
          speciesId: speciesId,
          moveId: moveId,
        );
      }
      knownMoveIds.add(moveId);
    }

    final persistedPp = pokemon.currentPpByMoveId;
    if (persistedPp != null) {
      for (final entry in persistedPp.entries) {
        final moveId = entry.key.trim();
        if (moveId.isEmpty) {
          throw RuntimePlayerPokemonProgressionHydrationException(
            code: RuntimePlayerPokemonProgressionHydrationErrorCode.emptyMoveId,
            message: 'Current PP move ids must not be empty.',
            speciesId: speciesId,
            moveId: entry.key,
          );
        }
        if (entry.value < 0) {
          throw RuntimePlayerPokemonProgressionHydrationException(
            code: RuntimePlayerPokemonProgressionHydrationErrorCode
                .negativeCurrentPp,
            message: 'Current PP values must be non-negative.',
            speciesId: speciesId,
            moveId: moveId,
          );
        }
        if (!catalogs.maxPpByMoveId.containsKey(moveId)) {
          throw RuntimePlayerPokemonProgressionHydrationException(
            code: RuntimePlayerPokemonProgressionHydrationErrorCode.unknownMove,
            message:
                'Current PP references a move absent from the runtime catalogue.',
            speciesId: speciesId,
            moveId: moveId,
          );
        }
        if (!knownMoveIds.contains(moveId)) {
          throw RuntimePlayerPokemonProgressionHydrationException(
            code: RuntimePlayerPokemonProgressionHydrationErrorCode
                .ppForUnlearnedMove,
            message: 'Current PP references a move the Pokemon does not know.',
            speciesId: speciesId,
            moveId: moveId,
          );
        }
      }
    }

    final experience = persistedExperience ??
        _minimumExperienceForLevel(
          level: pokemon.level,
          speciesId: speciesId,
          growthRateId: catalogs.growthRateIdBySpeciesId[speciesId],
        );
    final currentPpByMoveId = persistedPp ??
        <String, int>{
          for (final moveId in knownMoveIds)
            moveId: catalogs.maxPpByMoveId[moveId]!,
        };

    // A non-null persisted value is never recomputed here. Hydration is a
    // one-way legacy migration, not a heal operation or battle write-back.
    return pokemon.copyWith(
      experience: experience,
      currentPpByMoveId: currentPpByMoveId,
    );
  }

  return gameState.copyWith(
    party: gameState.party.copyWith(
      members: gameState.party.members.map(hydrate).toList(growable: false),
    ),
    pokemonStorage: gameState.pokemonStorage.copyWith(
      storedPokemon: gameState.pokemonStorage.storedPokemon
          .map(hydrate)
          .toList(growable: false),
    ),
  );
}

int _minimumExperienceForLevel({
  required int level,
  required String speciesId,
  required String? growthRateId,
}) {
  final normalizedGrowthRateId = growthRateId?.trim().toLowerCase();
  if (normalizedGrowthRateId == null || normalizedGrowthRateId.isEmpty) {
    throw RuntimePlayerPokemonProgressionHydrationException(
      code: RuntimePlayerPokemonProgressionHydrationErrorCode.missingGrowthRate,
      message: 'Species growth rate is required to hydrate legacy experience.',
      speciesId: speciesId,
    );
  }

  final cubed = level * level * level;
  final experience = switch (normalizedGrowthRateId) {
    'fast' => (4 * cubed) ~/ 5,
    'medium' || 'medium_fast' => cubed,
    'medium_slow' =>
      ((6 * cubed) ~/ 5) - (15 * level * level) + (100 * level) - 140,
    'slow' => (5 * cubed) ~/ 4,
    // Repository catalog ids follow the PokeAPI curve names. These aliases
    // are kept explicit so a future gameplay XP service can replace this
    // migration-only calculation without changing persisted data.
    'slow_then_very_fast' => _erraticExperience(level, cubed),
    'fast_then_very_slow' => _fluctuatingExperience(level, cubed),
    _ => throw RuntimePlayerPokemonProgressionHydrationException(
        code: RuntimePlayerPokemonProgressionHydrationErrorCode
            .unsupportedGrowthRate,
        message: 'Unsupported Pokemon growth rate "$normalizedGrowthRateId".',
        speciesId: speciesId,
      ),
  };

  // The classic medium-slow formula is negative at level one; persisted total
  // experience remains non-negative by contract.
  return experience < 0 ? 0 : experience;
}

int _erraticExperience(int level, int cubed) {
  if (level <= 50) return (cubed * (100 - level)) ~/ 50;
  if (level <= 68) return (cubed * (150 - level)) ~/ 100;
  if (level <= 98) {
    return (cubed * ((1911 - (10 * level)) ~/ 3)) ~/ 500;
  }
  return (cubed * (160 - level)) ~/ 100;
}

int _fluctuatingExperience(int level, int cubed) {
  if (level <= 15) {
    return (cubed * (((level + 1) ~/ 3) + 24)) ~/ 50;
  }
  if (level <= 35) return (cubed * (level + 14)) ~/ 50;
  return (cubed * ((level ~/ 2) + 32)) ~/ 50;
}
```
### packages/map_runtime/test/runtime_player_pokemon_progression_hydrator_test.dart

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('hydrateRuntimePlayerPokemonProgression', () {
    test('hydrates a level 16 legacy Pokemon without regressing its level', () {
      const legacy = PlayerPokemon(
        speciesId: 'wartortle',
        natureId: 'bold',
        abilityId: 'torrent',
        level: 16,
        knownMoveIds: ['water_gun', 'bite'],
      );

      final hydrated = hydrateRuntimePlayerPokemonProgression(
        gameState: const GameState(
          saveId: 'legacy_level_16',
          party: PlayerParty(members: [legacy]),
        ),
        catalogs: _catalogs(),
      );
      final pokemon = hydrated.party.members.single;

      expect(pokemon.level, 16);
      expect(pokemon.experience, 2535);
      expect(
        pokemon.currentPpByMoveId,
        {'water_gun': 25, 'bite': 25},
      );
    });

    test('hydrates null PP to an empty map when no moves are known', () {
      const legacy = PlayerPokemon(
        speciesId: 'wartortle',
        natureId: 'bold',
        abilityId: 'torrent',
        level: 16,
      );

      final hydrated = hydrateRuntimePlayerPokemonProgression(
        gameState: const GameState(
          saveId: 'legacy_no_moves',
          party: PlayerParty(members: [legacy]),
        ),
        catalogs: _catalogs(),
      );

      expect(hydrated.party.members.single.currentPpByMoveId, isEmpty);
    });

    test('preserves valid non-null experience and current PP', () {
      const persisted = PlayerPokemon(
        speciesId: 'wartortle',
        natureId: 'bold',
        abilityId: 'torrent',
        level: 16,
        knownMoveIds: ['water_gun'],
        experience: 3000,
        currentPpByMoveId: {'water_gun': 7},
      );

      final hydrated = hydrateRuntimePlayerPokemonProgression(
        gameState: const GameState(
          saveId: 'persisted_progression',
          party: PlayerParty(members: [persisted]),
        ),
        catalogs: _catalogs(),
      );
      final pokemon = hydrated.party.members.single;

      expect(pokemon.experience, 3000);
      expect(pokemon.currentPpByMoveId, {'water_gun': 7});
    });

    test('hydrates stored Pokemon as well as party members', () {
      const stored = PlayerPokemon(
        speciesId: 'wartortle',
        natureId: 'bold',
        abilityId: 'torrent',
        level: 16,
        knownMoveIds: ['bite'],
      );

      final hydrated = hydrateRuntimePlayerPokemonProgression(
        gameState: const GameState(
          saveId: 'stored_progression',
          pokemonStorage: PokemonStorage(storedPokemon: [stored]),
        ),
        catalogs: _catalogs(),
      );
      final pokemon = hydrated.pokemonStorage.storedPokemon.single;

      expect(pokemon.experience, 2535);
      expect(pokemon.currentPpByMoveId, {'bite': 25});
    });

    test('rejects negative experience with an explicit error code', () {
      const invalid = PlayerPokemon(
        speciesId: 'wartortle',
        natureId: 'bold',
        abilityId: 'torrent',
        experience: -1,
      );

      expect(
        () => hydrateRuntimePlayerPokemonProgression(
          gameState: const GameState(
            saveId: 'negative_experience',
            party: PlayerParty(members: [invalid]),
          ),
          catalogs: _catalogs(),
        ),
        throwsA(
          isA<RuntimePlayerPokemonProgressionHydrationException>().having(
            (error) => error.code,
            'code',
            RuntimePlayerPokemonProgressionHydrationErrorCode
                .negativeExperience,
          ),
        ),
      );
    });

    test('rejects negative current PP with an explicit error code', () {
      const invalid = PlayerPokemon(
        speciesId: 'wartortle',
        natureId: 'bold',
        abilityId: 'torrent',
        knownMoveIds: ['water_gun'],
        experience: 3000,
        currentPpByMoveId: {'water_gun': -1},
      );

      expect(
        () => hydrateRuntimePlayerPokemonProgression(
          gameState: const GameState(
            saveId: 'negative_pp',
            party: PlayerParty(members: [invalid]),
          ),
          catalogs: _catalogs(),
        ),
        throwsA(
          isA<RuntimePlayerPokemonProgressionHydrationException>().having(
            (error) => error.code,
            'code',
            RuntimePlayerPokemonProgressionHydrationErrorCode.negativeCurrentPp,
          ),
        ),
      );
    });

    test('rejects an empty current PP move key with an explicit error code',
        () {
      const invalid = PlayerPokemon(
        speciesId: 'wartortle',
        natureId: 'bold',
        abilityId: 'torrent',
        experience: 3000,
        currentPpByMoveId: {' ': 1},
      );

      expect(
        () => hydrateRuntimePlayerPokemonProgression(
          gameState: const GameState(
            saveId: 'empty_pp_key',
            party: PlayerParty(members: [invalid]),
          ),
          catalogs: _catalogs(),
        ),
        throwsA(
          isA<RuntimePlayerPokemonProgressionHydrationException>().having(
            (error) => error.code,
            'code',
            RuntimePlayerPokemonProgressionHydrationErrorCode.emptyMoveId,
          ),
        ),
      );
    });

    test('rejects current PP linked to an unknown move', () {
      const invalid = PlayerPokemon(
        speciesId: 'wartortle',
        natureId: 'bold',
        abilityId: 'torrent',
        knownMoveIds: ['missing_move'],
        experience: 3000,
        currentPpByMoveId: {'missing_move': 1},
      );

      expect(
        () => hydrateRuntimePlayerPokemonProgression(
          gameState: const GameState(
            saveId: 'unknown_move',
            party: PlayerParty(members: [invalid]),
          ),
          catalogs: _catalogs(),
        ),
        throwsA(
          isA<RuntimePlayerPokemonProgressionHydrationException>().having(
            (error) => error.code,
            'code',
            RuntimePlayerPokemonProgressionHydrationErrorCode.unknownMove,
          ),
        ),
      );
    });

    test('rejects current PP for a catalogued move that is not known', () {
      const invalid = PlayerPokemon(
        speciesId: 'wartortle',
        natureId: 'bold',
        abilityId: 'torrent',
        knownMoveIds: ['water_gun'],
        experience: 3000,
        currentPpByMoveId: {'bite': 1},
      );

      expect(
        () => hydrateRuntimePlayerPokemonProgression(
          gameState: const GameState(
            saveId: 'pp_for_unlearned_move',
            party: PlayerParty(members: [invalid]),
          ),
          catalogs: _catalogs(),
        ),
        throwsA(
          isA<RuntimePlayerPokemonProgressionHydrationException>().having(
            (error) => error.code,
            'code',
            RuntimePlayerPokemonProgressionHydrationErrorCode
                .ppForUnlearnedMove,
          ),
        ),
      );
    });
  });

  group('PlayableMapGame progression hydration', () {
    test('hydrates a project New Game before the runtime becomes playable',
        () async {
      final game = PlayableMapGame(
        bundle: _runtimeBundle(newGameEnabled: true),
        projectFilePath: '/tmp/progression_hydration/project.json',
        runtimePlayerPokemonProgressionCatalogLoader: _loadCatalogs,
      );

      game.onGameResize(Vector2(320, 240));
      await game.onLoad();

      final pokemon = game.gameStateSnapshot.party.members.single;
      expect(pokemon.level, 16);
      expect(pokemon.experience, 2535);
      expect(pokemon.currentPpByMoveId, {'water_gun': 25});
    });

    test('hydrates a legacy Pokemon restored by loadGame', () async {
      final repository = _MemoryGameSaveRepository(
        const GameState(
          saveId: 'legacy_runtime_load',
          currentMapId: 'hydration_map',
          playerPosition: GridPos(x: 1, y: 1),
          party: PlayerParty(
            members: [
              PlayerPokemon(
                speciesId: 'wartortle',
                natureId: 'bold',
                abilityId: 'torrent',
                level: 16,
                knownMoveIds: ['water_gun'],
              ),
            ],
          ),
        ),
      );
      final game = PlayableMapGame(
        bundle: _runtimeBundle(newGameEnabled: false),
        projectFilePath: '/tmp/progression_hydration/project.json',
        saveRepository: repository,
        runtimePlayerPokemonProgressionCatalogLoader: _loadCatalogs,
      );

      game.onGameResize(Vector2(320, 240));
      await game.onLoad();
      await _waitForActivationDispatch(game);

      expect(await game.loadGame(), isTrue);
      final pokemon = game.gameStateSnapshot.party.members.single;
      expect(pokemon.level, 16);
      expect(pokemon.experience, 2535);
      expect(pokemon.currentPpByMoveId, {'water_gun': 25});
    });
  });

  test('default loader projects growth rate and max PP from project data',
      () async {
    final root = await Directory.systemTemp.createTemp('progression_catalog_');
    addTearDown(() => root.delete(recursive: true));
    final speciesDirectory =
        Directory(p.join(root.path, 'data', 'pokemon', 'species'));
    final catalogDirectory =
        Directory(p.join(root.path, 'data', 'pokemon', 'catalogs'));
    await speciesDirectory.create(recursive: true);
    await catalogDirectory.create(recursive: true);
    await File(p.join(speciesDirectory.path, '0008-wartortle.json'))
        .writeAsString(
      jsonEncode({
        'id': 'wartortle',
        'progression': {'growthRateId': 'medium_slow'},
      }),
    );
    await File(p.join(catalogDirectory.path, 'moves.json')).writeAsString(
      jsonEncode({
        'catalog': 'moves',
        'entries': [
          const PokemonMove(
            id: 'water_gun',
            name: 'Water Gun',
            type: 'water',
            category: PokemonMoveCategory.special,
            accuracy: PokemonMoveAccuracy.percent(value: 100),
            pp: 25,
          ).toJson(),
        ],
      }),
    );

    final catalogs = await loadRuntimePlayerPokemonProgressionCatalogs(
      gameState: const GameState(
        saveId: 'loader_projection',
        party: PlayerParty(
          members: [
            PlayerPokemon(
              speciesId: 'wartortle',
              natureId: 'bold',
              abilityId: 'torrent',
              level: 16,
              knownMoveIds: ['water_gun'],
            ),
          ],
        ),
      ),
      projectRootDirectory: root.path,
      pokemonConfig: const ProjectPokemonConfig(),
    );

    expect(catalogs.growthRateIdBySpeciesId, {'wartortle': 'medium_slow'});
    expect(catalogs.maxPpByMoveId, {'water_gun': 25});
  });
}

RuntimePlayerPokemonProgressionCatalogs _catalogs() {
  return const RuntimePlayerPokemonProgressionCatalogs(
    growthRateIdBySpeciesId: {'wartortle': 'medium_slow'},
    maxPpByMoveId: {'water_gun': 25, 'bite': 25},
  );
}

Future<RuntimePlayerPokemonProgressionCatalogs> _loadCatalogs({
  required GameState gameState,
  required String projectRootDirectory,
  required ProjectPokemonConfig pokemonConfig,
}) async {
  return _catalogs();
}

Future<void> _waitForActivationDispatch(PlayableMapGame game) async {
  for (var i = 0; i < 240; i++) {
    if (!game.debugIsMapActivationDispatchInFlight) return;
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for map activation dispatch.');
}

RuntimeMapBundle _runtimeBundle({required bool newGameEnabled}) {
  const pokemon = PlayerPokemon(
    speciesId: 'wartortle',
    natureId: 'bold',
    abilityId: 'torrent',
    level: 16,
    knownMoveIds: ['water_gun'],
  );
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Progression hydration fixture',
      maps: const [
        ProjectMapEntry(
          id: 'hydration_map',
          name: 'Hydration map',
          relativePath: 'maps/hydration_map.json',
        ),
      ],
      tilesets: const [],
      newGame: ProjectNewGameConfig(
        enabled: newGameEnabled,
        startMapId: 'hydration_map',
        startSpawnId: 'spawn_start',
        initialParty: const [pokemon],
      ),
      surfaceCatalog: ProjectSurfaceCatalog(),
    ),
    map: const MapData(
      id: 'hydration_map',
      name: 'Hydration map',
      size: GridSize(width: 3, height: 3),
      layers: [MapLayer.object(id: 'objects', name: 'Objects')],
      entities: [
        MapEntity(
          id: 'spawn_start',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            spawnKey: 'spawn_start',
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn_start'),
    ),
    projectRootDirectory: '/tmp/progression_hydration',
    tilesetAbsolutePathsById: const {},
  );
}

final class _MemoryGameSaveRepository implements GameSaveRepository {
  _MemoryGameSaveRepository(this._state);

  GameState? _state;

  @override
  Future<void> save(GameState state) async => _state = state;

  @override
  Future<GameState?> load() async => _state;

  @override
  Future<bool> exists() async => _state != null;

  @override
  Future<void> delete() async => _state = null;
}
```
