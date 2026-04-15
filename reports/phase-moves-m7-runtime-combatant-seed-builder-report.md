# M7 — Extraction du reste de l’assemblage combat runtime hors de `RuntimeBattleSetupMapper`

## 1. Résumé exécutif honnête

Le lot M7 a été implémenté dans `packages/map_runtime` avec un recadrage volontaire du prompt.

Le résultat concret est le suivant :

- `RuntimeBattleSetupMapper` ne construit plus lui-même les seeds de combattants runtime ;
- un nouveau seam dédié, `RuntimeBattleCombatantSeedBuilder`, assemble désormais :
  - les seeds joueur ;
  - les seeds sauvage ;
  - les seeds dresseur ;
  - la dérivation des moves depuis le learnset ;
  - le lookup strict dans le catalogue moves ;
  - le gate M5-bis ;
  - le calcul du HP max ;
- le mapper reste responsable de l’orchestration de haut niveau :
  - sélection du slot joueur ;
  - sélection du dresseur et du membre de team retenu ;
  - politique `allowCapture` ;
  - assemblage final de `BattleSetup`.

Je n’ai pas ouvert M8.
Je n’ai pas touché `map_battle`, `map_core` ni `map_editor`.
Je n’ai pas réintroduit de fallback legacy.

Le diff est petit et défendable :

- 1 fichier runtime modifié ;
- 2 fichiers runtime créés ;
- 1 report créé.

## 2. Pré-gate exécuté avant code + résultat

Commande exécutée avant toute modification :

```bash
cd packages/map_runtime && /opt/homebrew/bin/flutter test test/runtime_move_catalog_loader_test.dart test/runtime_battle_setup_mapper_test.dart test/runtime_pokemon_species_loader_test.dart test/runtime_pokemon_learnset_loader_test.dart test/wild_battle_end_to_end_flow_test.dart
```

Résultat réel :

- `00:02 +27: All tests passed!`

Classification honnête du pré-gate :

- `vert`

Conclusion :

- l’état initial du seam runtime M5 / M5-bis / M6 était sain avant M7 ;
- M7 n’était pas un lot de réparation urgente mais bien un lot d’extraction / clarification.

## 3. État initial audité réel

Audit réellement relu avant implémentation :

- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart`
- `packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart`
- `packages/map_runtime/lib/src/application/runtime_pokemon_learnset_loader.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_exception.dart`
- `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`
- `packages/map_runtime/test/runtime_move_catalog_loader_test.dart`
- `packages/map_runtime/test/runtime_pokemon_species_loader_test.dart`
- `packages/map_runtime/test/runtime_pokemon_learnset_loader_test.dart`
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/pokemon_move.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

Constat réel au départ :

- M5 avait déjà extrait `moves` hors du mapper ;
- M6 avait déjà extrait `species` et `learnsets` hors du mapper ;
- malgré cela, `RuntimeBattleSetupMapper` concentrait encore une grosse quantité de logique d’assemblage :
  - construction seed joueur ;
  - construction seed sauvage ;
  - construction seed dresseur ;
  - dérivation des moves depuis le learnset ;
  - lookup des moves ;
  - gate M5-bis ;
  - calcul du HP max ;
  - normalisation / déduplication des ids de moves.

Autrement dit :

- la plomberie JSON était déjà extraite ;
- mais la plomberie d’assemblage combat restait encore tassée dans le mapper.

## 4. Problèmes confirmés / non confirmés

### Problèmes confirmés

- `RuntimeBattleSetupMapper` restait trop chargé pour un simple orchestrateur.
- Les invariants métier M5/M5-bis/M6 étaient corrects mais dispersés au même endroit que l’assemblage final `BattleSetup`.
- Il manquait un seam dédié testable autour de la construction des seeds de combattants.

### Problèmes non confirmés

- Je n’ai pas confirmé qu’il fallait extraire toute la logique hors du mapper.
- Je n’ai pas confirmé qu’un seam plus gros du type `RuntimeBattleSetupBuilder` serait sain.
- Je n’ai pas confirmé le besoin d’un second seam prod en plus du builder de seeds.

## 5. Cause racine réelle

La cause racine n’était pas un bug fonctionnel.

La cause racine était une extraction incomplète par étapes :

- M5 a sorti le chargement des moves ;
- M6 a sorti le chargement des species et learnsets ;
- il restait donc un “noyau épais” d’assemblage de combattants dans le mapper.

Ce noyau mélangeait encore :

- résolution runtime ;
- policy de sélection de moves ;
- gate battle MVP ;
- calcul des seeds de combattants.

## 6. Décisions retenues / rejetées

### Décisions retenues

1. Créer un seul nouveau seam prod :
   - `RuntimeBattleCombatantSeedBuilder`

2. Déplacer dans ce seam :
   - build player combatant seed
   - build wild combatant seed
   - build trainer combatant seed
   - dérivation learnset -> move ids
   - lookup des moves
   - gate M5-bis
   - calcul du HP max
   - normalisation / déduplication des ids de moves

3. Laisser dans `RuntimeBattleSetupMapper` :
   - `selectUsablePartyMemberIndex`
   - `_selectPlayerPartyMember`
   - `_findTrainer`
   - décision `allowCapture`
   - assemblage final du `BattleSetup`

4. Réutiliser strictement :
   - `RuntimeMoveCatalogLoader`
   - `RuntimePokemonSpeciesLoader`
   - `RuntimePokemonLearnsetLoader`
   - `RuntimeBattleSetupException`

### Décisions rejetées

1. Ne pas créer de `RuntimeBattleSetupBuilder` global
   - trop large ;
   - mauvaise frontière ;
   - proche d’une réouverture implicite de M8.

2. Ne pas déplacer la sélection du slot joueur dans le nouveau seam
   - `PlayableMapGame` consomme déjà explicitement cette logique ;
   - c’est une décision d’orchestration runtime, pas un assemblage de seed.

3. Ne pas créer un repository runtime Pokémon générique
   - besoin non prouvé ;
   - architecture de bureaucrate ;
   - hors échelle pour M7.

4. Ne pas toucher `map_battle`
   - inutile pour ce lot ;
   - hors scope ;
   - risquerait de transformer M7 en M8 déguisé.

## 7. Critique explicite du prompt reçu

### Ce qui était juste

- Le prompt identifiait correctement que le prochain seam naturel n’était plus le chargement JSON, mais l’assemblage des combattants runtime.
- Le prompt insistait correctement sur la conservation des policies M5 / M5-bis / M6.
- Le prompt avait raison de refuser :
  - `map_battle`
  - `map_core`
  - `map_editor`
  - les frameworks génériques.

### Ce qui était discutable

- La formule “extraction du reste de l’assemblage combat runtime hors du mapper” était un peu trop large.
- Suivie littéralement, elle pouvait pousser à sortir aussi :
  - la sélection du slot joueur ;
  - la recherche du dresseur ;
  - la décision `allowCapture` ;
  - voire l’assemblage final `BattleSetup`.

### Ce qui aurait été dangereux si suivi aveuglément

- Créer un gros seam “setup builder” qui avale presque tout le mapper.
- Déplacer dans un seam secondaire des décisions runtime de haut niveau qui doivent rester visibles au call site.
- Brouiller la frontière entre :
  - assemblage runtime ;
  - orchestration du combat ;
  - bridge battle MVP.

### Ce que j’ai recadré

- J’ai recentré M7 sur un seam plus petit et plus honnête :
  - un builder de seeds de combattants ;
  - pas un builder global de `BattleSetup`.

### Pourquoi ce recadrage est meilleur dans ce repo réel

- `PlayableMapGame` a déjà besoin d’une sélection explicite du slot joueur ;
- `allowCapture` dépend encore clairement du runtime et du bag ;
- la sélection du dresseur et du premier membre d’équipe relève encore d’une orchestration de haut niveau ;
- le besoin réel prouvé aujourd’hui est l’extraction de l’assemblage des seeds, pas l’effacement complet du mapper.

## 8. Périmètre inclus / exclu

### Inclus

- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`
- `packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart`
- `reports/phase-moves-m7-runtime-combatant-seed-builder-report.md`

### Exclu

- `packages/map_battle/...`
- `packages/map_core/...`
- `packages/map_editor/...`
- la policy M5-bis
- les loaders runtime M5/M6 existants
- le bridge M8

## 9. Liste exacte des fichiers modifiés / créés / supprimés

### Modifiés

- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`

### Créés

- `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`
- `packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart`
- `reports/phase-moves-m7-runtime-combatant-seed-builder-report.md`

### Supprimés

- aucun

## 10. Justification fichier par fichier

### `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`

Raison :

- enlever le gros bloc d’assemblage des seeds ;
- garder un mapper mince ;
- préserver l’orchestration de haut niveau.

### `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`

Raison :

- porter explicitement le seam M7 ;
- rendre testable séparément la construction des combattants runtime ;
- centraliser l’assemblage qui était encore dispersé dans le mapper.

### `packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart`

Raison :

- prouver directement le nouveau seam ;
- éviter de dépendre uniquement des tests d’intégration du mapper ;
- verrouiller les invariants extraits :
  - `knownMoveIds`
  - dérivation learnset
  - fallback species -> learnset
  - wild
  - trainer
  - gate M5-bis
  - move absent du catalogue

### `reports/phase-moves-m7-runtime-combatant-seed-builder-report.md`

Raison :

- trace honnête du lot ;
- justification du recadrage ;
- audit ;
- validations ;
- review séparée ;
- annexe complète.

## 11. Commandes réellement exécutées

### Audit / état git

```bash
find . -name AGENTS.md -print
git status --short
git diff --stat
git ls-files --others --exclude-standard
rg -n "class OverworldReturnContext|enum EncounterKind|class WildBattleStartRequest" packages/map_core packages/map_gameplay packages/map_runtime -g '*.dart'
sed -n '...' sur les fichiers runtime / tests audités
```

### Pré-gate

```bash
cd packages/map_runtime && /opt/homebrew/bin/flutter test test/runtime_move_catalog_loader_test.dart test/runtime_battle_setup_mapper_test.dart test/runtime_pokemon_species_loader_test.dart test/runtime_pokemon_learnset_loader_test.dart test/wild_battle_end_to_end_flow_test.dart
```

### Format

```bash
cd packages/map_runtime && /opt/homebrew/bin/dart format lib/src/application/runtime_battle_setup_mapper.dart lib/src/application/runtime_battle_combatant_seed_builder.dart test/runtime_battle_combatant_seed_builder_test.dart
cd packages/map_runtime && /opt/homebrew/bin/dart format lib/src/application/runtime_battle_setup_mapper.dart
cd packages/map_runtime && /opt/homebrew/bin/dart format test/runtime_battle_combatant_seed_builder_test.dart
```

### Analyze

```bash
cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub lib/src/application/runtime_battle_setup_mapper.dart lib/src/application/runtime_battle_combatant_seed_builder.dart test/runtime_battle_combatant_seed_builder_test.dart test/runtime_battle_setup_mapper_test.dart test/runtime_move_catalog_loader_test.dart test/runtime_pokemon_species_loader_test.dart test/runtime_pokemon_learnset_loader_test.dart test/wild_battle_end_to_end_flow_test.dart
```

Commande relancée après correction locale :

```bash
cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub lib/src/application/runtime_battle_setup_mapper.dart lib/src/application/runtime_battle_combatant_seed_builder.dart test/runtime_battle_combatant_seed_builder_test.dart test/runtime_battle_setup_mapper_test.dart test/runtime_move_catalog_loader_test.dart test/runtime_pokemon_species_loader_test.dart test/runtime_pokemon_learnset_loader_test.dart test/wild_battle_end_to_end_flow_test.dart
```

### Tests

Test ciblé initial du nouveau seam :

```bash
cd packages/map_runtime && /opt/homebrew/bin/flutter test test/runtime_battle_combatant_seed_builder_test.dart
```

Validation runtime utile :

```bash
cd packages/map_runtime && /opt/homebrew/bin/flutter test test/runtime_battle_combatant_seed_builder_test.dart test/runtime_battle_setup_mapper_test.dart test/runtime_move_catalog_loader_test.dart test/runtime_pokemon_species_loader_test.dart test/runtime_pokemon_learnset_loader_test.dart test/wild_battle_end_to_end_flow_test.dart
```

Validation relancée après correction issue de la review :

```bash
cd packages/map_runtime && /opt/homebrew/bin/flutter test test/runtime_battle_combatant_seed_builder_test.dart test/runtime_battle_setup_mapper_test.dart test/runtime_move_catalog_loader_test.dart test/runtime_pokemon_species_loader_test.dart test/runtime_pokemon_learnset_loader_test.dart test/wild_battle_end_to_end_flow_test.dart
```

## 12. Résultats réels de format / analyze / tests

### Format

- OK

### Analyze

Premier passage :

- rouge local temporaire :
  - `The method 'toBattleCombatantData' isn't defined for the type 'Object'`
  - cause : branches du `switch` asynchrones hétérogènes dans le mapper

Deuxième passage après correction :

- `No issues found!`

### Tests

Pré-gate :

- `All tests passed!`

Test dédié initial du nouveau seam :

- `All tests passed!`

Validation runtime complète après implémentation :

- `All tests passed!`

Validation runtime complète après intégration du retour reviewer :

- `All tests passed!`

## 13. Incidents rencontrés

### Incident 1 — erreur de type dans le `switch`

Symptôme :

- `enemySeed` inféré en `Object` au lieu de `RuntimeBattleCombatantSeed`

Cause :

- un branchement `switch` mélangeait une branche `await` et une branche `Future`

Correction :

- faire porter l’`await` sur le `switch` lui-même

### Incident 2 — couverture encore indirecte sur le cas “move absent”

Remonté par le reviewer :

- le seam builder n’avait pas encore de preuve directe sur un `moveId` absent du catalogue

Correction :

- ajout d’un test ciblé dans `runtime_battle_combatant_seed_builder_test.dart`

## 14. État git utile

État git observé en fin de lot :

```text
 M packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
?? packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart
?? packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart
?? reports/phase-moves-m7-runtime-combatant-seed-builder-report.md
```

`git diff --stat` à ce moment :

```text
 .../application/runtime_battle_setup_mapper.dart   | 410 +++------------------
 1 file changed, 44 insertions(+), 366 deletions(-)
```

`git ls-files --others --exclude-standard` observé en fin de lot :

```text
packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart
packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart
reports/phase-moves-m7-runtime-combatant-seed-builder-report.md
```

## 15. Checklist finale

- [x] j’ai exécuté un pré-gate avant toute modif
- [x] j’ai audité le code réel
- [x] j’ai challengé le prompt au lieu de l’accepter aveuglément
- [x] je n’ai pas ouvert `map_battle`
- [x] je n’ai pas ouvert `map_core`
- [x] je n’ai pas ouvert `map_editor`
- [x] je n’ai pas réintroduit de fallback legacy
- [x] je n’ai pas rouvert M8
- [x] le mapper est réellement plus mince après M7
- [x] le seam extrait a des tests dédiés utiles
- [x] les policies M5 / M5-bis / M6 restent cohérentes
- [x] j’ai exécuté format
- [x] j’ai exécuté analyze
- [x] j’ai exécuté les tests utiles
- [x] j’ai utilisé un agent d’audit/design
- [x] j’ai utilisé un reviewer séparé
- [x] j’ai intégré les remarques valides
- [x] je n’ai fait aucune écriture Git interdite
- [x] mon report est honnête
- [x] mon report contient le contenu complet des fichiers touchés

## 16. Retour du reviewer séparé

Reviewer utilisé :

- `Singer`

Retour synthétique réel :

- aucun finding matériel sur le lot ;
- frontière générale jugée correcte ;
- risque résiduel seulement côté couverture :
  - pas encore de test direct builder pour le cas `moveId` absent du catalogue.

Citation synthétique fidèle :

> Aucun finding matériel sur ce lot M7.  
> Le refactor tient la frontière attendue.  
> Risque résiduel seulement côté couverture : le seam builder n’a pas encore un test direct sur un `moveId` absent du catalogue.

## 17. Corrections appliquées suite à la review

Correction retenue :

- ajout du test direct :
  - `fails explicitly when a requested move is absent from the catalog`

Correction rejetée :

- aucune

## 18. Autocritique finale

### Ce qui est solide

- le seam M7 est petit ;
- la frontière est lisible ;
- le mapper est réellement plus mince ;
- les invariants M5/M5-bis/M6 sont conservés ;
- les tests du nouveau seam couvrent maintenant les cas utiles.

### Ce qui reste seulement acceptable

- le builder projette encore directement vers `BattleMoveData`, donc il reste collé au bridge MVP battle ;
- c’est acceptable pour M7, mais cela montre bien qu’un futur M8 devra encore clarifier la frontière runtime -> battle plus riche.

### Principal risque architectural restant

- le builder concentre maintenant une partie de la policy battle MVP de projection simplifiée des moves (`power = basePower ou 0`) ;
- ce n’est pas nouveau fonctionnellement, mais ce n’est pas encore la frontière finale idéale pour un moteur battle plus riche.

### Si je devais faire un M7-bis

- je vérifierais si la sélection du membre de team dresseur mérite un seam plus explicite quand le jeu passera au multi-Pokémon trainer côté runtime ;
- mais aujourd’hui ce serait prématuré.

### Si une exigence du prompt était objectivement mal calibrée

- oui : l’idée implicite de sortir “le reste de l’assemblage” du mapper pouvait pousser trop loin ;
- le bon lot M7 n’était pas de vider complètement le mapper, mais de sortir précisément l’assemblage des combatant seeds.

## 19. Limites restantes

- M7 n’ouvre pas M8 :
  - pas d’exécution riche des effects ;
  - pas d’enrichissement de `BattleMoveData` ;
  - pas de refonte du bridge battle.
- Le seam trainer reste mono-combattant MVP :
  - le mapper sélectionne encore `trainer.team.first`.
- Le builder et le mapper restent volontairement dans `map_runtime`.

## 20. Annexe — contenu complet des fichiers texte touchés

Note :

- l’annexe inclut le contenu complet des fichiers de code touchés ;
- le report s’exclut lui-même de sa propre annexe pour éviter une récursion infinie.

### 20.1. `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`

```dart
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'battle_start_request.dart';
import 'runtime_battle_combatant_seed_builder.dart';
import 'runtime_battle_setup_exception.dart';
import 'runtime_map_bundle.dart';
import 'runtime_move_catalog_loader.dart';

export 'runtime_battle_setup_exception.dart' show RuntimeBattleSetupException;

const _runtimeCapturePokeBallItemId = 'poke-ball';
const _runtimeCapturePokeBallCategoryId = 'items';

/// Mapper runtime unique vers [BattleSetup].
///
/// Important :
/// - cette classe reste locale à `map_runtime` ;
/// - elle ne réintroduit pas de dépendance vers `map_editor` ;
/// - elle relit uniquement le strict nécessaire des données Pokémon projet
///   pour construire le setup de combat réel.
///
/// M5 introduit un seam runtime spécialisé pour les moves parce que :
/// - le catalogue moves est maintenant canonique et beaucoup plus riche ;
/// - `runtime_battle_setup_mapper.dart` ne doit plus relire `moves.json`
///   comme un tuple pauvre `id/name/power` ;
/// - `map_battle` ne doit toujours pas lire le JSON projet brut.
///
/// M6 poursuit cette extraction pour les espèces et learnsets :
/// - le mapper ne relit plus lui-même ces JSON projet ;
/// - il délègue à de petits loaders runtime spécialisés ;
/// - il reste centré sur la composition combat, pas sur la plomberie locale.
///
/// M7 poursuit dans la même direction :
/// - le mapper ne construit plus lui-même les seeds de combattants ;
/// - il délègue cette projection à un builder spécialisé ;
/// - il garde seulement l'orchestration de haut niveau, la politique de
///   capture et les sélections exactes qui appartiennent encore au runtime.
class RuntimeBattleSetupMapper {
  const RuntimeBattleSetupMapper({
    this.moveCatalogLoader = const RuntimeMoveCatalogLoader(),
    this.combatantSeedBuilder = const RuntimeBattleCombatantSeedBuilder(),
  });

  final RuntimeMoveCatalogLoader moveCatalogLoader;
  final RuntimeBattleCombatantSeedBuilder combatantSeedBuilder;

  Future<BattleSetup> map({
    required RuntimeMapBundle bundle,
    required GameState gameState,
    required BattleStartRequest request,
    int? playerPartyIndex,
  }) async {
    final movesCatalog = await moveCatalogLoader.load(
      projectRootDirectory: bundle.projectRootDirectory,
      pokemonConfig: bundle.manifest.pokemon,
    );
    final playerPokemon = _selectPlayerPartyMember(
      gameState.party,
      playerPartyIndex: playerPartyIndex,
    );

    final playerSeed = await combatantSeedBuilder.buildPlayerCombatantSeed(
      projectRootDirectory: bundle.projectRootDirectory,
      pokemonConfig: bundle.manifest.pokemon,
      movesCatalog: movesCatalog,
      playerPokemon: playerPokemon,
    );

    final enemySeed = await switch (request) {
      WildBattleStartRequest() => combatantSeedBuilder.buildWildCombatantSeed(
          projectRootDirectory: bundle.projectRootDirectory,
          pokemonConfig: bundle.manifest.pokemon,
          movesCatalog: movesCatalog,
          request: request,
        ),
      TrainerBattleStartRequest() => () async {
          final trainer = _findTrainer(bundle.manifest, request.trainerId);
          if (trainer.team.isEmpty) {
            throw RuntimeBattleSetupException(
              'Le dresseur "${trainer.name}" n’a aucun Pokémon dans son équipe.',
              debugDetails: 'trainerId=${trainer.id}',
            );
          }

          // Le moteur battle MVP reste mono-combattant : le mapper garde ce
          // choix précis de haut niveau, puis délègue l’assemblage du seed du
          // membre retenu au seam M7.
          return combatantSeedBuilder.buildTrainerCombatantSeed(
            projectRootDirectory: bundle.projectRootDirectory,
            pokemonConfig: bundle.manifest.pokemon,
            movesCatalog: movesCatalog,
            teamMember: trainer.team.first,
            trainerName: trainer.name,
          );
        }(),
    };

    return BattleSetup(
      playerPokemon: playerSeed.toBattleCombatantData(),
      enemyPokemon: enemySeed.toBattleCombatantData(),
      isTrainerBattle: request is TrainerBattleStartRequest,
      trainerId:
          request is TrainerBattleStartRequest ? request.trainerId : null,
      // Le moteur battle ne connaît ni le bag runtime, ni les limites de party.
      // On garde donc la décision de "peut-on capturer ?" ici, au point où le
      // runtime possède encore les vraies données save/projet nécessaires.
      //
      // Lot 14 reste volontairement borné :
      // - combat sauvage uniquement ;
      // - aucune capture si la party est pleine (pas de PC/boxes ici) ;
      // - aucune capture sans Poké Ball réelle dans le bag du joueur.
      allowCapture: request is WildBattleStartRequest &&
          gameState.party.members.length < 6 &&
          _playerHasAtLeastOnePokeBall(gameState.bag),
    );
  }

  /// Retourne l'index du slot réellement utilisé pour le handoff combat.
  ///
  /// Le runtime lot 10 doit mémoriser cet index exact pour réécrire les PV du
  /// bon membre après le combat. On expose donc explicitement cette sélection
  /// au lieu de forcer [PlayableMapGame] à dupliquer la logique.
  int selectUsablePartyMemberIndex(PlayerParty party) {
    // Cette sélection reste volontairement dans le mapper :
    // - `PlayableMapGame` l'utilise déjà pour mémoriser le slot à réécrire
    //   après le combat ;
    // - elle relève d'une décision d'orchestration runtime de haut niveau,
    //   pas d'un assemblage de seed de combattant ;
    // - l'extraire dans le builder brouillerait la frontière M7 pour peu de
    //   valeur réelle dans ce repo.
    for (var i = 0; i < party.members.length; i++) {
      if (!party.members[i].isFainted) {
        return i;
      }
    }

    if (party.members.isEmpty) {
      throw const RuntimeBattleSetupException(
        'Impossible de lancer un combat sans Pokémon dans l’équipe du joueur.',
      );
    }

    throw const RuntimeBattleSetupException(
      'Tous les Pokémon de l’équipe du joueur sont K.O.; combat impossible.',
    );
  }

  /// Retourne le Pokémon joueur qui doit être injecté dans [BattleSetup].
  ///
  /// Deux cas :
  /// - lot 9 seul : on prend le premier membre jouable ;
  /// - lot 10 : le runtime fournit [playerPartyIndex] pour garantir que le
  ///   combat et le write-back visent exactement le même slot.
  ///
  /// On refuse explicitement un index invalide ou un slot déjà K.O. pour éviter
  /// tout glissement silencieux vers un autre membre de la party.
  PlayerPokemon _selectPlayerPartyMember(
    PlayerParty party, {
    int? playerPartyIndex,
  }) {
    final resolvedIndex =
        playerPartyIndex ?? selectUsablePartyMemberIndex(party);
    if (resolvedIndex < 0 || resolvedIndex >= party.members.length) {
      throw RuntimeBattleSetupException(
        'Le slot de party joueur demandé pour le combat est invalide.',
        debugDetails:
            'playerPartyIndex=$resolvedIndex, partyLength=${party.members.length}',
      );
    }

    final member = party.members[resolvedIndex];
    if (member.isFainted) {
      throw RuntimeBattleSetupException(
        'Le slot de party joueur demandé pour le combat est déjà K.O.',
        debugDetails:
            'playerPartyIndex=$resolvedIndex, speciesId=${member.speciesId}',
      );
    }

    return member;
  }

  ProjectTrainerEntry _findTrainer(ProjectManifest manifest, String trainerId) {
    final normalizedTrainerId = trainerId.trim();
    for (final trainer in manifest.trainers) {
      if (trainer.id == normalizedTrainerId) {
        return trainer;
      }
    }

    throw RuntimeBattleSetupException(
      'Dresseur introuvable pour démarrer le combat.',
      debugDetails: 'trainerId=$trainerId',
    );
  }
}

/// Retourne `true` si le bag runtime contient au moins une Poké Ball exploitable.
///
/// Le guard vit ici plutôt que dans `map_battle` car :
/// - le moteur battle ne doit pas dépendre du système de bag ;
/// - le runtime est déjà la frontière qui décide si `allowCapture` peut être
///   activé pour une rencontre donnée ;
/// - le lot 14 n'ouvre pas un inventaire global ni une politique de capture.
///
/// On tolère des IDs non normalisés en mémoire (`" poke-ball "`) pour rester
/// robuste face à un état runtime pas encore passé par le pipeline save/load.
bool _playerHasAtLeastOnePokeBall(Bag bag) {
  for (final entry in bag.entries) {
    if (entry.itemId.trim() == _runtimeCapturePokeBallItemId &&
        entry.categoryId.trim() == _runtimeCapturePokeBallCategoryId &&
        entry.quantity > 0) {
      return true;
    }
  }
  return false;
}
```

### 20.2. `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`

```dart
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'battle_start_request.dart';
import 'runtime_battle_setup_exception.dart';
import 'runtime_move_catalog_loader.dart';
import 'runtime_pokemon_learnset_loader.dart';
import 'runtime_pokemon_species_loader.dart';

/// Builder runtime spécialisé des seeds de combattants injectés dans
/// `BattleSetup`.
///
/// M7 extrait ce seam pour éviter que `RuntimeBattleSetupMapper` concentre
/// encore :
/// - la sélection du membre joueur ;
/// - la lecture species/learnsets déjà extraite en M6 ;
/// - la dérivation du move set ;
/// - le gate M5-bis vers `BattleMoveData` ;
/// - le calcul de HP max ;
/// - et la construction finale des seeds de combattants.
///
/// Frontière intentionnelle :
/// - ce builder assemble des données runtime locales vers un seed battle ;
/// - il ne crée pas un framework générique de combat ;
/// - il ne modifie pas le contrat `BattleSetup` ;
/// - il ne rouvre pas M8 et n’essaie pas d’exécuter les `effects`.
class RuntimeBattleCombatantSeedBuilder {
  const RuntimeBattleCombatantSeedBuilder({
    this.speciesLoader = const RuntimePokemonSpeciesLoader(),
    this.learnsetLoader = const RuntimePokemonLearnsetLoader(),
  });

  final RuntimePokemonSpeciesLoader speciesLoader;
  final RuntimePokemonLearnsetLoader learnsetLoader;

  Future<RuntimeBattleCombatantSeed> buildPlayerCombatantSeed({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimeMoveCatalog movesCatalog,
    required PlayerPokemon playerPokemon,
  }) async {
    final species = await speciesLoader.loadById(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesId: playerPokemon.speciesId,
    );
    final moveIds = playerPokemon.knownMoveIds.isNotEmpty
        ? playerPokemon.knownMoveIds
        : await _deriveLearnsetMoveIds(
            projectRootDirectory: projectRootDirectory,
            pokemonConfig: pokemonConfig,
            species: species,
            level: playerPokemon.level,
          );

    final moves = _resolveBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: moveIds,
      combatantLabel: 'Le Pokémon actif du joueur',
    );

    final maxHp = _calculateMaxHp(
      baseHp: species.baseHp,
      level: playerPokemon.level,
      ivHp: playerPokemon.ivs.hp,
      evHp: playerPokemon.evs.hp,
    );

    return RuntimeBattleCombatantSeed(
      speciesId: playerPokemon.speciesId.trim(),
      level: playerPokemon.level,
      maxHp: maxHp,
      currentHp: _clampInt(playerPokemon.currentHp, min: 0, max: maxHp),
      abilityId: playerPokemon.abilityId.trim().isEmpty
          ? 'unknown'
          : playerPokemon.abilityId.trim(),
      moves: moves,
    );
  }

  Future<RuntimeBattleCombatantSeed> buildWildCombatantSeed({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimeMoveCatalog movesCatalog,
    required WildBattleStartRequest request,
  }) async {
    final species = await speciesLoader.loadById(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesId: request.speciesId,
    );
    final moveIds = await _deriveLearnsetMoveIds(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      species: species,
      level: request.level,
    );
    final moves = _resolveBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: moveIds,
      combatantLabel: 'Le Pokémon sauvage "${request.speciesId}"',
    );

    return RuntimeBattleCombatantSeed(
      speciesId: request.speciesId.trim(),
      level: request.level,
      maxHp: _calculateMaxHp(
        baseHp: species.baseHp,
        level: request.level,
      ),
      abilityId: species.primaryAbilityId.isEmpty
          ? 'unknown'
          : species.primaryAbilityId,
      moves: moves,
    );
  }

  Future<RuntimeBattleCombatantSeed> buildTrainerCombatantSeed({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimeMoveCatalog movesCatalog,
    required ProjectTrainerPokemonEntry teamMember,
    required String trainerName,
  }) async {
    final species = await speciesLoader.loadById(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesId: teamMember.speciesId,
    );
    final moveIds = teamMember.moves.isNotEmpty
        ? teamMember.moves
        : await _deriveLearnsetMoveIds(
            projectRootDirectory: projectRootDirectory,
            pokemonConfig: pokemonConfig,
            species: species,
            level: teamMember.level,
          );

    final moves = _resolveBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: moveIds,
      combatantLabel:
          'Le Pokémon du dresseur "$trainerName" (${teamMember.speciesId})',
    );

    return RuntimeBattleCombatantSeed(
      speciesId: teamMember.speciesId.trim(),
      level: teamMember.level,
      maxHp: _calculateMaxHp(
        baseHp: species.baseHp,
        level: teamMember.level,
      ),
      abilityId: species.primaryAbilityId.isEmpty
          ? 'unknown'
          : species.primaryAbilityId,
      moves: moves,
    );
  }

  Future<List<String>> _deriveLearnsetMoveIds({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimePokemonSpecies species,
    required int level,
  }) async {
    final learnset = await learnsetLoader.loadByRef(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesRef: species.learnsetRef,
      fallbackSpeciesId: species.id,
    );

    // On conserve strictement la policy M6 :
    // - startingMoves
    // - relearnMoves
    // - levelUp <= niveau courant
    // - unicité préservant l'ordre
    // - 4 derniers moves maximum
    final ordered = <String>[
      ...learnset.startingMoves,
      ...learnset.relearnMoves,
      ...learnset.levelUp
          .where((entry) => entry.level <= level)
          .map((entry) => entry.moveId),
    ];
    final unique = _normalizeUniqueIdsPreserveOrder(ordered);
    if (unique.length <= 4) {
      return unique;
    }
    return unique.sublist(unique.length - 4);
  }

  List<BattleMoveData> _resolveBattleMoves({
    required RuntimeMoveCatalog movesCatalog,
    required List<String> moveIds,
    required String combatantLabel,
  }) {
    final normalizedMoveIds = _normalizeUniqueIdsPreserveOrder(moveIds);
    if (normalizedMoveIds.isEmpty) {
      throw RuntimeBattleSetupException(
        '$combatantLabel n’a aucune attaque exploitable pour démarrer le combat.',
      );
    }

    final moves = <BattleMoveData>[];
    for (final moveId in normalizedMoveIds.take(4)) {
      final move = movesCatalog.lookup(moveId);
      if (move == null) {
        throw RuntimeBattleSetupException(
          'Le catalogue local des attaques ne contient pas "$moveId".',
          debugDetails: 'combatant=$combatantLabel',
        );
      }
      _ensureMoveCanBeProjectedToBattle(
        move: move,
        combatantLabel: combatantLabel,
      );
      moves.add(
        BattleMoveData(
          id: move.id,
          name: move.name,
          // Le bridge battle reste volontairement MVP :
          // il ne connaît pas encore accuracy, effets structurés ni weather.
          // M7 n'ouvre pas M8 ; il préserve donc exactement la politique M5-bis
          // et continue à n'envoyer qu'une puissance simplifiée.
          power: move.usesStandardDamageFlow ? move.basePower : 0,
        ),
      );
    }
    return List<BattleMoveData>.unmodifiable(moves);
  }

  void _ensureMoveCanBeProjectedToBattle({
    required PokemonMove move,
    required String combatantLabel,
  }) {
    if (move.engineSupportLevel ==
        PokemonMoveEngineSupportLevel.structuredSupported) {
      return;
    }

    final unsupportedReasons = move.unsupportedReasons.isEmpty
        ? '[]'
        : '[${move.unsupportedReasons.join(', ')}]';
    throw RuntimeBattleSetupException(
      'Le combat ne peut pas démarrer car "$combatantLabel" utilise une attaque que le handoff battle actuel ne sait pas projeter honnêtement.',
      debugDetails:
          'combatant=$combatantLabel, moveId=${move.id}, moveName=${move.name}, engineSupportLevel=${move.engineSupportLevel.name}, unsupportedReasons=$unsupportedReasons',
    );
  }

  List<String> _normalizeUniqueIdsPreserveOrder(List<String> rawIds) {
    final out = <String>[];
    final seen = <String>{};
    for (final rawId in rawIds) {
      final normalizedId = rawId.trim();
      if (normalizedId.isEmpty || !seen.add(normalizedId)) {
        continue;
      }
      out.add(normalizedId);
    }
    return List<String>.unmodifiable(out);
  }

  int _calculateMaxHp({
    required int baseHp,
    required int level,
    int ivHp = 0,
    int evHp = 0,
  }) {
    final safeBaseHp = _clampInt(baseHp, min: 1, max: 255);
    final safeLevel = _clampInt(level, min: 1, max: 100);
    final safeIv = _clampInt(ivHp, min: 0, max: 31);
    final safeEv = _clampInt(evHp, min: 0, max: 252);

    final hp =
        (((2 * safeBaseHp + safeIv + (safeEv ~/ 4)) * safeLevel) ~/ 100) +
            safeLevel +
            10;
    return _clampInt(hp, min: 1, max: 999);
  }

  int _clampInt(
    int value, {
    required int min,
    required int max,
  }) {
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }
}

/// Seed runtime intermédiaire d'un combattant avant projection finale vers
/// `BattleCombatantData`.
///
/// On garde ce type séparé du mapper pour documenter explicitement la frontière
/// M7 :
/// - le builder assemble un seed runtime battle-ready ;
/// - le mapper assemble ensuite le `BattleSetup` global.
class RuntimeBattleCombatantSeed {
  const RuntimeBattleCombatantSeed({
    required this.speciesId,
    required this.level,
    required this.maxHp,
    required this.abilityId,
    required this.moves,
    this.currentHp,
  });

  final String speciesId;
  final int level;
  final int maxHp;
  final int? currentHp;
  final String abilityId;
  final List<BattleMoveData> moves;

  BattleCombatantData toBattleCombatantData() {
    return BattleCombatantData(
      speciesId: speciesId,
      level: level,
      maxHp: maxHp,
      currentHp: currentHp,
      abilityId: abilityId,
      moves: moves,
    );
  }
}
```

### 20.3. `packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_battle_combatant_seed_builder.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_exception.dart';
import 'package:map_runtime/src/application/runtime_move_catalog_loader.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RuntimeBattleCombatantSeedBuilder', () {
    late Directory tempProjectRoot;
    const builder = RuntimeBattleCombatantSeedBuilder();
    const moveCatalogLoader = RuntimeMoveCatalogLoader();

    setUp(() async {
      tempProjectRoot =
          await Directory.systemTemp.createTemp('runtime_combatant_seed_');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    test('builds a player combatant seed from explicit knownMoveIds', () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          ivs: PokemonStatSpread(hp: 31),
          evs: PokemonStatSpread(hp: 8),
          knownMoveIds: <String>['growl', 'vine_whip'],
          currentHp: 23,
        ),
      );

      expect(seed.speciesId, equals('sproutle'));
      expect(seed.level, equals(12));
      expect(seed.maxHp, equals(36));
      expect(seed.currentHp, equals(23));
      expect(seed.abilityId, equals('overgrow'));
      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['growl', 'vine_whip']),
      );
    });

    test(
        'derives player moves from the learnset, falls back to species id and keeps the last four unique moves',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      await _rewriteSpeciesWithoutLearnsetRef(
        tempProjectRoot,
        speciesFileName: '001-sproutle.json',
        speciesId: 'sproutle',
        baseHp: 45,
        primaryAbilityId: 'overgrow',
      );
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'calm',
          abilityId: 'overgrow',
          level: 25,
          currentHp: 30,
        ),
      );

      // Le seam M7 doit conserver exactement la policy historique :
      // - concat starting/relearn/levelUp<=niveau ;
      // - unicité dans l'ordre d'apparition ;
      // - puis conservation des quatre derniers si la liste déborde.
      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['growl', 'vine_whip', 'sleep_powder', 'razor_leaf']),
      );
    });

    test('builds a wild combatant seed from species and learnset data',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildWildCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(seed.speciesId, equals('sparkitten'));
      expect(seed.level, equals(10));
      expect(seed.currentHp, isNull);
      expect(seed.abilityId, equals('blaze'));
      expect(seed.maxHp, equals(27));
      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['scratch', 'tail_whip', 'ember']),
      );
    });

    test('builds a trainer combatant seed from explicit trainer moves',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildTrainerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        teamMember: const ProjectTrainerPokemonEntry(
          speciesId: 'aquafi',
          level: 18,
          moves: <String>['water_gun', 'aqua_ring'],
          heldItemId: 'mystic_water',
        ),
        trainerName: 'Ace Jules',
      );

      expect(seed.speciesId, equals('aquafi'));
      expect(seed.level, equals(18));
      expect(seed.abilityId, equals('torrent'));
      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['water_gun', 'aqua_ring']),
      );
    });

    test(
        'preserves the M5-bis gate and rejects a partially supported move during seed assembly',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      await _rewriteMoveCatalogEntrySupport(
        tempProjectRoot,
        moveId: 'growl',
        supportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
        unsupportedReasons: const <String>[
          'unsupported_mechanic:stat_drop_bridge',
        ],
      );
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      await expectLater(
        () => builder.buildPlayerCombatantSeed(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          movesCatalog: movesCatalog,
          playerPokemon: const PlayerPokemon(
            speciesId: 'sproutle',
            natureId: 'bold',
            abilityId: 'overgrow',
            level: 12,
            knownMoveIds: <String>['growl', 'vine_whip'],
            currentHp: 23,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('combatant=Le Pokémon actif du joueur'),
              contains('moveId=growl'),
              contains('engineSupportLevel=structuredPartial'),
              contains(
                'unsupportedReasons=[unsupported_mechanic:stat_drop_bridge]',
              ),
            ),
          ),
        ),
      );
    });

    test('fails explicitly when a requested move is absent from the catalog',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      await expectLater(
        () => builder.buildPlayerCombatantSeed(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          movesCatalog: movesCatalog,
          playerPokemon: const PlayerPokemon(
            speciesId: 'sproutle',
            natureId: 'bold',
            abilityId: 'overgrow',
            level: 12,
            knownMoveIds: <String>['move_that_does_not_exist'],
            currentHp: 23,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.message,
            'message',
            contains('ne contient pas "move_that_does_not_exist"'),
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

WildBattleStartRequest _wildRequest({
  required String speciesId,
  required int level,
}) {
  return WildBattleStartRequest(
    requestId: 'wild-request',
    createdAtEpochMs: 1,
    returnContext: const OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    mapId: 'field_map',
    zoneId: 'grass',
    tableId: 'field_grass',
    encounterKind: EncounterKind.walk,
    speciesId: speciesId,
    level: level,
    minLevel: level,
    maxLevel: level,
    weight: 30,
    playerPos: const GridPos(x: 1, y: 1),
  );
}

Future<void> _writePokemonFixtures(Directory projectRoot) async {
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/001-sproutle.json',
    <String, dynamic>{
      'id': 'sproutle',
      'baseStats': <String, int>{'hp': 45},
      'abilities': <String, String>{'primary': 'overgrow'},
      'refs': <String, String>{'learnset': 'sproutle'},
    },
  );
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/004-sparkitten.json',
    <String, dynamic>{
      'id': 'sparkitten',
      'baseStats': <String, int>{'hp': 39},
      'abilities': <String, String>{'primary': 'blaze'},
      'refs': <String, String>{'learnset': 'sparkitten'},
    },
  );
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/007-aquafi.json',
    <String, dynamic>{
      'id': 'aquafi',
      'baseStats': <String, int>{'hp': 44},
      'abilities': <String, String>{'primary': 'torrent'},
      'refs': <String, String>{'learnset': 'aquafi'},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/sproutle.json',
    <String, dynamic>{
      'speciesId': 'sproutle',
      'startingMoves': <String>['tackle', 'growl'],
      'relearnMoves': <String>['growl', 'vine_whip'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{'moveId': 'vine_whip', 'level': 7},
        <String, Object>{'moveId': 'sleep_powder', 'level': 13},
        <String, Object>{'moveId': 'razor_leaf', 'level': 20},
      ],
    },
  );
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/sparkitten.json',
    <String, dynamic>{
      'speciesId': 'sparkitten',
      'startingMoves': <String>['scratch'],
      'relearnMoves': <String>['tail_whip'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{'moveId': 'ember', 'level': 7},
        <String, Object>{'moveId': 'flame_wheel', 'level': 20},
      ],
    },
  );
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/aquafi.json',
    <String, dynamic>{
      'speciesId': 'aquafi',
      'startingMoves': <String>['tackle'],
      'relearnMoves': <String>['water_gun'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{'moveId': 'aqua_ring', 'level': 18},
      ],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/catalogs/moves.json',
    <String, dynamic>{
      'schemaVersion': 1,
      'kind': 'pokemon_catalog',
      'catalog': 'moves',
      'meta': <String, Object>{
        'description': 'Runtime combatant seed builder test catalog',
      },
      'entries': <Map<String, Object?>>[
        _moveEntry('tackle', 'Tackle', 40),
        _moveEntry('growl', 'Growl', 0),
        _moveEntry('vine_whip', 'Vine Whip', 45),
        _moveEntry('sleep_powder', 'Sleep Powder', 0),
        _moveEntry('razor_leaf', 'Razor Leaf', 55),
        _moveEntry('scratch', 'Scratch', 40),
        _moveEntry('tail_whip', 'Tail Whip', 0),
        _moveEntry('ember', 'Ember', 40),
        _moveEntry('flame_wheel', 'Flame Wheel', 60),
        _moveEntry('water_gun', 'Water Gun', 40),
        _moveEntry('aqua_ring', 'Aqua Ring', 0),
      ],
    },
  );
}

Map<String, Object?> _moveEntry(
  String id,
  String name,
  int power, {
  PokemonMoveEngineSupportLevel engineSupportLevel =
      PokemonMoveEngineSupportLevel.structuredSupported,
  List<String> unsupportedReasons = const <String>[],
}) {
  return PokemonMove(
    id: id,
    name: name,
    names: <String, String>{'en': name},
    generation: 1,
    source: 'test_runtime_fixture',
    type: 'normal',
    category:
        power == 0 ? PokemonMoveCategory.status : PokemonMoveCategory.special,
    target: PokemonMoveTarget.normal,
    basePower: power,
    accuracy: power == 0
        ? const PokemonMoveAccuracy.alwaysHits()
        : const PokemonMoveAccuracy.percent(value: 100),
    pp: 35,
    engineSupportLevel: engineSupportLevel,
    unsupportedReasons: unsupportedReasons,
  ).toJson();
}

Future<void> _rewriteMoveCatalogEntrySupport(
  Directory projectRoot, {
  required String moveId,
  required PokemonMoveEngineSupportLevel supportLevel,
  required List<String> unsupportedReasons,
}) async {
  final catalogFile =
      File(p.join(projectRoot.path, 'custom/pokemon/catalogs/moves.json'));
  final decoded =
      jsonDecode(await catalogFile.readAsString()) as Map<String, dynamic>;
  final rawEntries =
      ((decoded['entries'] as List?) ?? const <Object?>[]).cast<Object?>();
  final updatedEntries = <Map<String, Object?>>[];
  var replaced = false;

  for (final rawEntry in rawEntries) {
    final entry = (rawEntry as Map).cast<String, dynamic>();
    final entryId = (entry['id'] as String?)?.trim() ?? '';
    if (entryId != moveId) {
      updatedEntries.add(Map<String, Object?>.from(entry));
      continue;
    }

    replaced = true;
    final move = PokemonMove.fromJson(entry).copyWith(
      engineSupportLevel: supportLevel,
      unsupportedReasons: unsupportedReasons,
    );
    updatedEntries.add(move.toJson());
  }

  expect(
    replaced,
    isTrue,
    reason:
        'Expected to find move "$moveId" in the combatant seed builder fixture catalog.',
  );

  decoded['entries'] = updatedEntries;
  await catalogFile.writeAsString(const JsonEncoder.withIndent('  ').convert(
    decoded,
  ));
}

Future<void> _rewriteSpeciesWithoutLearnsetRef(
  Directory projectRoot, {
  required String speciesFileName,
  required String speciesId,
  required int baseHp,
  required String primaryAbilityId,
}) {
  return _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/$speciesFileName',
    <String, dynamic>{
      'id': speciesId,
      'baseStats': <String, int>{'hp': baseHp},
      'abilities': <String, String>{'primary': primaryAbilityId},
      // Le test retire volontairement `refs.learnset` pour prouver que le
      // seam M7 conserve bien le fallback historique vers l'id d'espèce.
    },
  );
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
```
