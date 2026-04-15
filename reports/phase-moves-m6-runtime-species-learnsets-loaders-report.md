# M6 — Extraction des loaders runtime spécialisés `species` + `learnsets` hors du mapper battle

## 1. Résumé exécutif honnête

M6 est livré comme un lot strictement borné à `packages/map_runtime`.

Le gros reader JSON privé encore présent dans `RuntimeBattleSetupMapper` a été extrait vers deux seams runtime spécialisés :
- `RuntimePokemonSpeciesLoader`
- `RuntimePokemonLearnsetLoader`

Le mapper reste maintenant centré sur ce qu’il doit vraiment faire :
- sélectionner le bon combattant ;
- calculer les données runtime utiles ;
- résoudre les moves via le seam moves déjà introduit en M5 ;
- conserver le gate explicite M5-bis ;
- projeter vers `BattleSetup`.

Les invariants métier importants ont été préservés :
- résolution `species` par `id` déclaré dans le JSON, pas par nom de fichier ;
- fallback `learnsetRef -> fallbackSpeciesId` ;
- filtrage tolérant des entrées `levelUp` invalides ;
- aucune dépendance à `map_editor` ;
- aucune ouverture vers `map_battle`.

Le diff reste petit et défendable :
- 1 fichier runtime simplifié ;
- 2 nouveaux loaders ciblés ;
- 2 nouveaux fichiers de tests dédiés ;
- 1 test d’intégration mapper ajouté pour fermer le trou de couverture relevé en review.

## 2. Pré-gate M5/M5-bis

Commande réellement exécutée avant toute modification :

```text
cd packages/map_runtime && /opt/homebrew/bin/flutter test test/runtime_move_catalog_loader_test.dart test/runtime_battle_setup_mapper_test.dart test/wild_battle_end_to_end_flow_test.dart
```

Résultat réel :

```text
00:01 +17: All tests passed!
```

Classification honnête de l’état initial :
- `vert`

Conclusion :
- aucun rouge préexistant n’a bloqué M6 ;
- le seam runtime M5/M5-bis était sain au départ ;
- l’extraction M6 pouvait être menée sans absorber une dette préalable parasite.

## 3. État initial audité réel

Fichiers réellement relus avant code :
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_exception.dart`
- `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`
- `packages/map_runtime/test/runtime_move_catalog_loader_test.dart`
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/pokemon_move.dart`

Constat réel avant patch :
- `RuntimeMoveCatalogLoader` existait déjà et jouait bien son rôle de seam runtime strict du canonique moves ;
- `RuntimeBattleSetupMapper` ne relisait plus `moves.json` lui-même ;
- en revanche, il contenait encore un reader JSON privé ad hoc pour `species` et `learnsets` ;
- ce reader était long, peu testable isolément et mélangeait lecture locale + logique de composition battle ;
- les invariants utiles y étaient implicites et donc fragiles à une future reprise.

Invariants observés avant extraction :
- la species était résolue par `id` déclaré dans les fichiers JSON, pas par nom de fichier ;
- le scan species restait top-level (`recursive: false`) ;
- `learnsetRef` vide retombait sur `fallbackSpeciesId` ;
- les entrées `levelUp` invalides étaient filtrées, pas rendues fatales ;
- `RuntimeBattleSetupException` était déjà le bon contrat d’erreur partagé.

Sub-agent d’audit/design utilisé : `Euler`.

Retour utile retenu :
- le seam devait sortir du mapper sans déplacer la policy battle ;
- les invariants listés ci-dessus devaient être conservés explicitement ;
- le danger principal aurait été de durcir au hasard le parsing `levelUp` ou de dépendre naïvement du filename pour les species.

## 4. Problèmes confirmés / non confirmés

### Problèmes confirmés

1. **Lecture JSON species/learnsets encore collée au mapper**
   - confirmé dans `runtime_battle_setup_mapper.dart`
   - impact : lisibilité, testabilité, frontière architecturale

2. **Invariants runtime importants seulement implicites**
   - confirmé
   - impact : risque de régression lors d’une future reprise ou extension

### Problèmes non confirmés

1. **Besoin d’ouvrir `map_core`**
   - non confirmé
   - aucun besoin réel observé

2. **Besoin d’ouvrir `map_battle`**
   - non confirmé
   - totalement hors sujet pour ce lot

3. **Besoin d’un framework runtime générique**
   - non confirmé
   - le besoin réel est beaucoup plus petit

## 5. Cause racine réelle

La cause racine n’était pas un bug métier isolé, mais une frontière technique incomplètement extraite après M5 :
- les moves avaient déjà leur loader runtime spécialisé ;
- `species` et `learnsets` étaient encore lus localement dans le mapper ;
- le mapper continuait donc d’assumer à la fois lecture JSON et composition battle.

M6 ferme précisément cette incohérence de couture.

## 6. Décisions retenues / rejetées

### Décisions retenues

1. **Créer deux petits loaders spécialisés dans `map_runtime/src/application/`**
   - `runtime_pokemon_species_loader.dart`
   - `runtime_pokemon_learnset_loader.dart`

2. **Conserver `RuntimeBattleSetupException` comme contrat unique d’erreur runtime**
   - pas de nouvelle famille d’exceptions

3. **Créer de petits DTOs runtime typés et minimaux**
   - `RuntimePokemonSpecies`
   - `RuntimePokemonLearnset`
   - `RuntimePokemonLevelUpMove`

4. **Préserver les comportements métier existants**
   - species par `id` déclaré
   - fallback `learnsetRef -> fallbackSpeciesId`
   - filtrage tolérant des `levelUp` invalides

5. **Laisser le mapper propriétaire de la composition battle**
   - sélection de membre
   - calcul HP
   - résolution des moves
   - gate M5-bis
   - projection finale

### Décisions rejetées

1. **Créer un repository runtime Pokémon générique**
   - rejeté : trop large, trop spéculatif, non justifié par le besoin réel

2. **Déplacer la policy battle dans les nouveaux loaders**
   - rejeté : ce serait brouiller la frontière avec M5/M5-bis

3. **Toucher `RuntimeMoveCatalogLoader` pour homogénéiser tout de suite**
   - rejeté : pas nécessaire pour livrer M6 proprement

4. **Durcir `levelUp` invalide en erreur fatale**
   - rejeté : contraire au comportement réel observé avant extraction

## 7. Critique explicite du prompt reçu

### Ce qui était juste

- demander un pré-gate réel avant toute modif ;
- exiger un audit du code réel ;
- imposer que l’extraction reste dans `map_runtime` ;
- protéger la frontière `mapper` vs `loaders` ;
- insister sur la résolution species par `id` déclaré plutôt que par filename ;
- insister sur la préservation du fallback `learnsetRef -> fallbackSpeciesId`.

### Ce qui était discutable

- la préférence très explicite pour **deux fichiers** séparés était un peu sur-prescriptive ; après audit, un seul petit seam local à deux méthodes aurait aussi pu rester défendable.

### Ce qui aurait été dangereux si suivi aveuglément

- transformer l’extraction en mini-framework “pokemon project reader” générique ;
- durcir au hasard le parsing `levelUp` parce qu’un loader séparé “doit être strict partout” ;
- croire que “loader spécialisé” impose un clone complet des JSON species/learnsets ;
- toucher `map_battle` ou `map_core` pour “faire plus propre”.

### Ce que j’ai recadré

- j’ai gardé **deux petits loaders** parce que le découpage restait lisible et cohérent avec le seam moves déjà en place ;
- j’ai refusé toute abstraction générique partagée au-delà du besoin réel ;
- j’ai conservé la tolérance existante sur `levelUp` au lieu d’inventer une nouvelle policy métier.

### Pourquoi

Parce que c’est la version la plus petite et la plus stable pour le repo réel :
- assez extraite pour clarifier le mapper ;
- pas assez ambitieuse pour ouvrir M7/M8 déguisés.

## 8. Périmètre inclus / exclu

### Inclus
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart`
- `packages/map_runtime/lib/src/application/runtime_pokemon_learnset_loader.dart`
- `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`
- `packages/map_runtime/test/runtime_pokemon_species_loader_test.dart`
- `packages/map_runtime/test/runtime_pokemon_learnset_loader_test.dart`
- `reports/phase-moves-m6-runtime-species-learnsets-loaders-report.md`

### Exclus
- `packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart`
- `packages/map_runtime/test/runtime_move_catalog_loader_test.dart` (non modifié, seulement réexécuté)
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart` (non modifié, seulement réexécuté)
- tout `packages/map_battle/...`
- tout `packages/map_core/...`
- tout `packages/map_editor/...`

## 9. Liste exacte des fichiers modifiés / créés / supprimés

### Modifiés
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`

### Créés
- `packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart`
- `packages/map_runtime/lib/src/application/runtime_pokemon_learnset_loader.dart`
- `packages/map_runtime/test/runtime_pokemon_species_loader_test.dart`
- `packages/map_runtime/test/runtime_pokemon_learnset_loader_test.dart`
- `reports/phase-moves-m6-runtime-species-learnsets-loaders-report.md`

### Supprimés
- aucun

## 10. Justification fichier par fichier

### `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`

- extraction réelle du reader JSON privé species/learnsets ;
- injection des deux nouveaux seams runtime ;
- conservation de la logique battle pure et du gate M5-bis.

### `packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart`

- nouveau seam strict, petit et testable pour la lecture runtime des species ;
- résolution par `id` déclaré ;
- erreur explicite sur absence, duplication, JSON invalide ou `baseStats.hp` cassé.

### `packages/map_runtime/lib/src/application/runtime_pokemon_learnset_loader.dart`

- nouveau seam strict et borné pour la lecture runtime des learnsets ;
- fallback `learnsetRef -> fallbackSpeciesId` ;
- préservation de la tolérance historique sur `levelUp` invalide.

### `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`

- ajout d’un test d’intégration pour fermer le résiduel relevé en review :
  une species sans `learnsetRef` retombe bien sur son `species.id`.

### `packages/map_runtime/test/runtime_pokemon_species_loader_test.dart`

- preuve unitaire dédiée du seam species ;
- verrouillage des invariants `id` déclaré, duplication, JSON invalide, champs runtime minimaux.

### `packages/map_runtime/test/runtime_pokemon_learnset_loader_test.dart`

- preuve unitaire dédiée du seam learnset ;
- verrouillage du fallback et du filtrage utile de `levelUp`.

## 11. Commandes réellement exécutées

### Audit Git / état initial

```text
git status --short
git diff --stat
git ls-files --others --exclude-standard
find . -name AGENTS.md -print
```

### Pré-gate

```text
cd packages/map_runtime && /opt/homebrew/bin/flutter test test/runtime_move_catalog_loader_test.dart test/runtime_battle_setup_mapper_test.dart test/wild_battle_end_to_end_flow_test.dart
```

### Lecture ciblée / recherche

```text
sed -n '1,420p' packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
sed -n '1,260p' packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart
sed -n '1,220p' packages/map_runtime/lib/src/application/runtime_battle_setup_exception.dart
sed -n '1,280p' packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
sed -n '1,260p' packages/map_runtime/test/runtime_move_catalog_loader_test.dart
sed -n '1,260p' packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
sed -n '1,260p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '1,280p' packages/map_core/lib/src/models/pokemon_move.dart
rg -n "_RuntimePokemonProjectReader|_RuntimePokemonSpecies|_RuntimePokemonLearnset|readSpeciesById|readLearnsetByRef|speciesDir|learnsetsDir|jsonDecode\(" packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart packages/map_runtime/lib/src/application -g '!**/*.g.dart'
rg -n "ProjectPokemonConfig|speciesDir|learnsetsDir|catalogFiles\['moves'\]|RuntimeMoveCatalogLoader|RuntimeBattleSetupMapper\(" packages/map_runtime/lib packages/map_runtime/test -g '!**/*.g.dart'
rg -n "rewriteMoveCatalogEntrySupport|_writeProjectRelativeJson\(|_playerStateForTests|maps a wild encounter from real project species" packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
```

### Format

```text
cd packages/map_runtime && /opt/homebrew/bin/dart format lib/src/application/runtime_battle_setup_mapper.dart lib/src/application/runtime_pokemon_species_loader.dart lib/src/application/runtime_pokemon_learnset_loader.dart test/runtime_pokemon_species_loader_test.dart test/runtime_pokemon_learnset_loader_test.dart
cd packages/map_runtime && /opt/homebrew/bin/dart format lib/src/application/runtime_pokemon_species_loader.dart lib/src/application/runtime_pokemon_learnset_loader.dart
cd packages/map_runtime && /opt/homebrew/bin/dart format test/runtime_battle_setup_mapper_test.dart
```

### Analyze

```text
cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub lib/src/application/runtime_battle_setup_mapper.dart lib/src/application/runtime_move_catalog_loader.dart lib/src/application/runtime_battle_setup_exception.dart lib/src/application/runtime_pokemon_species_loader.dart lib/src/application/runtime_pokemon_learnset_loader.dart test/runtime_pokemon_species_loader_test.dart test/runtime_pokemon_learnset_loader_test.dart test/runtime_battle_setup_mapper_test.dart test/runtime_move_catalog_loader_test.dart test/wild_battle_end_to_end_flow_test.dart
cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub lib/src/application/runtime_battle_setup_mapper.dart lib/src/application/runtime_move_catalog_loader.dart lib/src/application/runtime_battle_setup_exception.dart lib/src/application/runtime_pokemon_species_loader.dart lib/src/application/runtime_pokemon_learnset_loader.dart test/runtime_pokemon_species_loader_test.dart test/runtime_pokemon_learnset_loader_test.dart test/runtime_battle_setup_mapper_test.dart test/runtime_move_catalog_loader_test.dart test/wild_battle_end_to_end_flow_test.dart
```

### Tests

```text
cd packages/map_runtime && /opt/homebrew/bin/flutter test test/runtime_pokemon_species_loader_test.dart test/runtime_pokemon_learnset_loader_test.dart test/runtime_battle_setup_mapper_test.dart test/runtime_move_catalog_loader_test.dart test/wild_battle_end_to_end_flow_test.dart
cd packages/map_runtime && /opt/homebrew/bin/flutter test test/runtime_pokemon_species_loader_test.dart test/runtime_pokemon_learnset_loader_test.dart test/runtime_battle_setup_mapper_test.dart test/runtime_move_catalog_loader_test.dart test/wild_battle_end_to_end_flow_test.dart
```

## 12. Résultats réels de format / analyze / tests

### Pré-gate

```text
00:01 +17: All tests passed!
```

### Format

```text
Formatted lib/src/application/runtime_pokemon_species_loader.dart
Formatted test/runtime_pokemon_species_loader_test.dart
Formatted 5 files (2 changed) in 0.01 seconds.
Formatted 2 files (0 changed) in 0.01 seconds.
Formatted 1 file (0 changed) in 0.01 seconds.
```

### Analyze

Premier run utile :

```text
No issues found! (ran in 1.5s)
```

Rerun final après le test mapper ajouté :

```text
No issues found! (ran in 1.4s)
```

### Tests

Premier run utile :
- 1 échec ciblé dans `runtime_pokemon_species_loader_test.dart`
- cause : `debugDetails` sur JSON invalide n’incluait pas encore le chemin du fichier, ce qui rendait l’erreur moins utile que souhaité

Rerun final après correction :

```text
00:01 +27: All tests passed!
```

## 13. Incidents rencontrés

1. **Un test species a échoué au premier run.**
   - Pas un bug de logique loader ; un défaut d’ergonomie d’erreur.
   - Correction minimale appliquée : ajout du chemin du fichier dans `debugDetails` pour les parse failures species/learnsets.

2. **Le reviewer a signalé un résiduel de couverture, pas un bug.**
   - Le fallback `species.id -> learnset` était bien prouvé au niveau loader, mais pas encore au niveau mapper.
   - J’ai ajouté un test d’intégration ciblé pour fermer ce trou.

## 14. État git utile

### `git status --short`

```text
 M packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
 M packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
?? packages/map_runtime/lib/src/application/runtime_pokemon_learnset_loader.dart
?? packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart
?? packages/map_runtime/test/runtime_pokemon_learnset_loader_test.dart
?? packages/map_runtime/test/runtime_pokemon_species_loader_test.dart
?? reports/phase-moves-m6-runtime-species-learnsets-loaders-report.md
```

### `git diff --stat`

```text
 .../application/runtime_battle_setup_mapper.dart   | 282 ++++-----------------
 .../test/runtime_battle_setup_mapper_test.dart     |  67 +++++
 2 files changed, 116 insertions(+), 233 deletions(-)
```

### Fichiers non suivis

```text
packages/map_runtime/lib/src/application/runtime_pokemon_learnset_loader.dart
packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart
packages/map_runtime/test/runtime_pokemon_learnset_loader_test.dart
packages/map_runtime/test/runtime_pokemon_species_loader_test.dart
reports/phase-moves-m6-runtime-species-learnsets-loaders-report.md
```

## 15. Checklist finale

- [x] j’ai audité le code réel avant de coder
- [x] j’ai challengé le prompt
- [x] j’ai exécuté le pré-gate M5/M5-bis
- [x] le pré-gate était vert
- [x] j’ai identifié où vivaient encore les lectures JSON species/learnsets
- [x] le mapper est réellement plus propre
- [x] je n’ai pas touché `map_battle`
- [x] je n’ai pas touché `map_core`
- [x] je n’ai pas touché `map_editor`
- [x] je n’ai pas touché le loader moves existant
- [x] j’ai conservé le gate M5-bis des moves
- [x] j’ai conservé la résolution species par `id` déclaré
- [x] j’ai conservé le fallback `learnsetRef -> fallbackSpeciesId`
- [x] j’ai conservé le filtrage tolérant des `levelUp` invalides
- [x] j’ai ajouté des tests dédiés species
- [x] j’ai ajouté des tests dédiés learnsets
- [x] j’ai ajouté une preuve mapper du fallback species -> learnset
- [x] j’ai exécuté format
- [x] j’ai exécuté analyze
- [x] j’ai exécuté les tests utiles
- [x] j’ai utilisé un sub-agent d’audit/design
- [x] j’ai utilisé un reviewer séparé
- [x] j’ai intégré les remarques utiles
- [x] je n’ai fait aucune écriture Git interdite
- [x] le report est honnête
- [x] l’autocritique finale est présente

## 16. Retour du reviewer séparé

Reviewer séparé utilisé : `Singer`.

Retour initial utile :
- pas de finding matériel sur la logique ;
- résiduel de couverture : absence d’un test d’intégration mapper pour le chemin `species sans learnsetRef -> fallbackSpeciesId`.

Retour final après ajout du test :
- aucun finding matériel ;
- les invariants demandés tiennent ;
- le seul résiduel est de l’ordre couverture/perf, pas correctness.

## 17. Corrections appliquées suite à la review

1. **Ajout d’un test mapper d’intégration**
   - prouve que le fallback `species.id -> learnset` fonctionne encore via `RuntimeBattleSetupMapper`.

2. **Aucune correction prod supplémentaire demandée par le reviewer**
   - la logique extraite était déjà jugée saine.

## 18. Autocritique finale

### Ce qui est solide

- le seam moves reste intact ;
- le mapper est réellement allégé ;
- les invariants délicats ont été explicitement verrouillés par des tests dédiés ;
- l’extraction ne crée pas de framework parasite.

### Ce qui reste seulement acceptable

- il existe une petite duplication de helpers JSON/path entre les nouveaux loaders et le loader moves existant ;
- je l’assume ici pour éviter de réouvrir M6 en abstraction générique prématurée.

### Principal risque architectural restant

Le principal risque restant est la duplication locale de lecture JSON entre seams runtime (`moves`, `species`, `learnsets`). Ce n’est pas encore une dette assez forte pour justifier un framework commun, mais ce sera à surveiller si un futur lot extrait encore d’autres domains Pokémon runtime.

### Ce que je corrigerais ensuite dans un M6-bis si on me le demandait

- seulement si plusieurs seams supplémentaires apparaissent, factoriser un mini helper interne de lecture JSON runtime partagé ;
- pas avant.

### Exigence du prompt que je trouve objectivement un peu mauvaise

L’idée qu’il fallait presque nécessairement deux fichiers distincts était un peu trop pilotée par la forme. Le vrai critère devait être la taille et la netteté du seam ; un seul petit reader ultra-borné aurait aussi pu être défendable. J’ai néanmoins gardé deux loaders parce que le résultat reste petit et très lisible.

## 19. Annexe avec le contenu complet de tous les fichiers texte touchés

Le report s’exclut lui-même de cette annexe pour éviter la récursion infinie.

## `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`

```dart
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'battle_start_request.dart';
import 'runtime_battle_setup_exception.dart';
import 'runtime_map_bundle.dart';
import 'runtime_move_catalog_loader.dart';
import 'runtime_pokemon_learnset_loader.dart';
import 'runtime_pokemon_species_loader.dart';

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
class RuntimeBattleSetupMapper {
  const RuntimeBattleSetupMapper({
    this.moveCatalogLoader = const RuntimeMoveCatalogLoader(),
    this.speciesLoader = const RuntimePokemonSpeciesLoader(),
    this.learnsetLoader = const RuntimePokemonLearnsetLoader(),
  });

  final RuntimeMoveCatalogLoader moveCatalogLoader;
  final RuntimePokemonSpeciesLoader speciesLoader;
  final RuntimePokemonLearnsetLoader learnsetLoader;

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

    final playerSeed = await _buildPlayerCombatantSeed(
      projectRootDirectory: bundle.projectRootDirectory,
      pokemonConfig: bundle.manifest.pokemon,
      movesCatalog: movesCatalog,
      gameState: gameState,
      playerPartyIndex: playerPartyIndex,
    );

    final enemySeed = switch (request) {
      WildBattleStartRequest() => await _buildWildCombatantSeed(
          projectRootDirectory: bundle.projectRootDirectory,
          pokemonConfig: bundle.manifest.pokemon,
          movesCatalog: movesCatalog,
          request: request,
        ),
      TrainerBattleStartRequest() => await _buildTrainerCombatantSeed(
          projectRootDirectory: bundle.projectRootDirectory,
          pokemonConfig: bundle.manifest.pokemon,
          movesCatalog: movesCatalog,
          manifest: bundle.manifest,
          request: request,
        ),
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

  Future<_RuntimeBattleCombatantSeed> _buildPlayerCombatantSeed({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimeMoveCatalog movesCatalog,
    required GameState gameState,
    int? playerPartyIndex,
  }) async {
    final playerPokemon = _selectPlayerPartyMember(
      gameState.party,
      playerPartyIndex: playerPartyIndex,
    );
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

    return _RuntimeBattleCombatantSeed(
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

  Future<_RuntimeBattleCombatantSeed> _buildWildCombatantSeed({
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

    return _RuntimeBattleCombatantSeed(
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

  Future<_RuntimeBattleCombatantSeed> _buildTrainerCombatantSeed({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimeMoveCatalog movesCatalog,
    required ProjectManifest manifest,
    required TrainerBattleStartRequest request,
  }) async {
    final trainer = _findTrainer(manifest, request.trainerId);
    if (trainer.team.isEmpty) {
      throw RuntimeBattleSetupException(
        'Le dresseur "${trainer.name}" n’a aucun Pokémon dans son équipe.',
        debugDetails: 'trainerId=${trainer.id}',
      );
    }

    // Le moteur battle MVP reste mono-combattant : on prend donc le premier
    // Pokémon authoré de l’équipe, sans inventer une seconde logique de party.
    final teamMember = trainer.team.first;
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
          'Le Pokémon du dresseur "${trainer.name}" (${teamMember.speciesId})',
    );

    return _RuntimeBattleCombatantSeed(
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

  /// Retourne l'index du slot réellement utilisé pour le handoff combat.
  ///
  /// Le runtime lot 10 doit mémoriser cet index exact pour réécrire les PV du
  /// bon membre après le combat. On expose donc explicitement cette sélection
  /// au lieu de forcer [PlayableMapGame] à dupliquer la logique.
  int selectUsablePartyMemberIndex(PlayerParty party) {
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

    // On construit la liste de moves disponibles en respectant uniquement les
    // familles déjà exploitées ailleurs dans le projet :
    // - startingMoves
    // - relearnMoves
    // - levelUp <= niveau courant
    //
    // Ensuite on garde les 4 derniers IDs uniques. Cela reste simple, lisible
    // et suffisamment proche d’un move set plausible sans inventer un nouveau
    // moteur de sélection.
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
          // Le moteur battle MVP reste borné :
          // - il ne connaît encore ni accuracy, ni effets structurés, ni
          //   support level ;
          // - il consomme uniquement une puissance de base simplifiée.
          //
          // M5-bis change volontairement la frontière :
          // - seuls les moves déjà marqués `structuredSupported` arrivent
          //   jusqu'ici ;
          // - `catalogOnly` et `structuredPartial` échouent explicitement un
          //   peu plus haut, avant toute projection vers `BattleMoveData`.
          //
          // Ce `power: 0` restant n'est donc plus un downgrade silencieux
          // d'un move partiellement supporté. Il ne sert plus qu'aux moves
          // réellement autorisés par le gate runtime, mais qui suivent un flow
          // de dégâts non standard ou purement status dans le bridge MVP.
          //
          // Conséquence assumée pour ce lot :
          // - si le move suit le flow de dégâts standard, on transmet
          //   `basePower` ;
          // - sinon on garde `0`, exactement comme les vieux status moves du
          //   MVP battle.
          //
          // On documente explicitement cette limite au lieu de l'étendre ici :
          // décider quels `effects`/support levels deviennent réellement
          // exécutables appartient au futur pont runtime -> battle (M8), pas
          // à ce seam de chargement M5.
          power: move.usesStandardDamageFlow ? move.basePower : 0,
        ),
      );
    }
    return List<BattleMoveData>.unmodifiable(moves);
  }

  /// Refuse explicitement les moves déjà marqués comme non projetables vers le
  /// handoff battle actuel.
  ///
  /// Pourquoi le gate vit ici, et pas dans le loader :
  /// - le loader runtime doit rester un transport strict du canonique ;
  /// - il doit continuer à charger honnêtement `catalogOnly` et
  ///   `structuredPartial` pour le runtime au sens large ;
  /// - c'est seulement ici, au moment précis où l'on s'apprête à écraser le
  ///   move canonique riche vers le pont MVP `BattleMoveData(id, name, power)`,
  ///   que l'on sait si cette projection est honnête ou trompeuse.
  ///
  /// Conséquence assumée de M5-bis :
  /// - `structuredSupported` passe ;
  /// - `structuredPartial` et `catalogOnly` échouent immédiatement ;
  /// - aucun filtrage silencieux, aucun downgrade vers `power: 0`.
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

    // Formule Pokémon simplifiée mais vraie dans son intention :
    // elle part bien des stats projet/save au lieu d’une constante hardcodée.
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

class _RuntimeBattleCombatantSeed {
  const _RuntimeBattleCombatantSeed({
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

## `packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart`

```dart
import 'dart:convert';
import 'dart:io';

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
    final baseHp = (baseStats?['hp'] as num?)?.toInt();
    if (baseHp == null || baseHp <= 0) {
      throw RuntimeBattleSetupException(
        'Les données d’espèce Pokémon locales sont invalides; combat impossible.',
        debugDetails:
            'speciesId=$expectedSpeciesId, file=$filePath, missing or invalid baseStats.hp',
      );
    }

    final refs = (rawJson['refs'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{
          'learnset': (rawJson['learnsetRef'] as String?)?.trim() ?? '',
        };
    final abilities = (rawJson['abilities'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    return RuntimePokemonSpecies(
      id: expectedSpeciesId,
      baseHp: baseHp,
      primaryAbilityId: (abilities['primary'] as String?)?.trim() ?? '',
      // `learnsetRef` peut rester vide : le loader learnset conservera le
      // fallback historique vers l'id de l'espèce.
      learnsetRef: (refs['learnset'] as String?)?.trim() ?? '',
    );
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
    required this.baseHp,
    required this.primaryAbilityId,
    required this.learnsetRef,
  });

  final String id;
  final int baseHp;
  final String primaryAbilityId;
  final String learnsetRef;
}

```

## `packages/map_runtime/lib/src/application/runtime_pokemon_learnset_loader.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'runtime_battle_setup_exception.dart';

/// Loader runtime spécialisé des learnsets Pokémon projet.
///
/// M6 extrait cette lecture hors du mapper pour garder une frontière nette :
/// - le loader lit le JSON projet strictement ;
/// - le mapper décide ensuite comment sélectionner les moves utiles pour le
///   combat courant.
///
/// Le contrat reste volontairement borné :
/// - lecture par `learnsetRef` si présent ;
/// - fallback vers `fallbackSpeciesId` si le ref est vide ;
/// - seules les familles déjà utilisées par le mapper sont exposées.
class RuntimePokemonLearnsetLoader {
  const RuntimePokemonLearnsetLoader();

  Future<RuntimePokemonLearnset> loadByRef({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required String speciesRef,
    required String fallbackSpeciesId,
  }) async {
    final normalizedSpeciesRef = speciesRef.trim();
    final normalizedFallbackSpeciesId = fallbackSpeciesId.trim();
    final learnsetId = normalizedSpeciesRef.isEmpty
        ? normalizedFallbackSpeciesId
        : normalizedSpeciesRef;
    if (learnsetId.isEmpty) {
      throw const RuntimeBattleSetupException(
        'Impossible de déterminer quel learnset Pokémon charger pour le combat.',
      );
    }

    final learnsetsDirectory = _normalizeConfiguredRelativePath(
      pokemonConfig.learnsetsDir,
      fallback: 'data/pokemon/learnsets',
    );
    final relativePath = p.join(learnsetsDirectory, '$learnsetId.json');
    final json = await _readJsonAtProjectRelativePath(
      projectRootDirectory,
      relativePath,
      label: 'Pokemon learnset "$learnsetId"',
    );

    final rawLevelUp = (json['levelUp'] as List?) ?? const <Object?>[];
    return RuntimePokemonLearnset(
      // On préserve volontairement la tolérance historique :
      // seules les vraies chaînes sont gardées ici, puis le mapper continuera
      // à normaliser/dédupliquer les ids plus loin.
      startingMoves: ((json['startingMoves'] as List?) ?? const <Object?>[])
          .whereType<String>()
          .toList(growable: false),
      relearnMoves: ((json['relearnMoves'] as List?) ?? const <Object?>[])
          .whereType<String>()
          .toList(growable: false),
      // Même choix qu'avant extraction :
      // - on ignore les entrées levelUp mal formées ;
      // - on ne change pas cette politique en erreur fatale dans M6 ;
      // - la sélection par niveau/ordre reste du ressort du mapper.
      levelUp: rawLevelUp
          .whereType<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .map(
            (entry) => RuntimePokemonLevelUpMove(
              moveId: (entry['moveId'] as String?)?.trim() ?? '',
              level: (entry['level'] as num?)?.toInt() ?? 0,
            ),
          )
          .where((entry) => entry.moveId.isNotEmpty && entry.level > 0)
          .toList(growable: false),
    );
  }

  Future<Map<String, dynamic>> _readJsonAtProjectRelativePath(
    String projectRootDirectory,
    String relativePath, {
    required String label,
  }) {
    return _readJsonFile(
      File(_resolveProjectPath(projectRootDirectory, relativePath)),
      label: label,
    );
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

/// Vue runtime minimale d'un learnset réellement consommé par le mapper.
class RuntimePokemonLearnset {
  const RuntimePokemonLearnset({
    required this.startingMoves,
    required this.relearnMoves,
    required this.levelUp,
  });

  final List<String> startingMoves;
  final List<String> relearnMoves;
  final List<RuntimePokemonLevelUpMove> levelUp;
}

/// Entrée level-up minimale conservée par le runtime.
class RuntimePokemonLevelUpMove {
  const RuntimePokemonLevelUpMove({
    required this.moveId,
    required this.level,
  });

  final String moveId;
  final int level;
}

```

## `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_mapper.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RuntimeBattleSetupMapper', () {
    late Directory tempProjectRoot;
    const mapper = RuntimeBattleSetupMapper();

    setUp(() async {
      tempProjectRoot =
          await Directory.systemTemp.createTemp('runtime_battle_mapper_');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    test('maps the real player party member from runtime save data', () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-player',
          party: PlayerParty(
            members: <PlayerPokemon>[
              // Ce Pokémon K.O. ne doit jamais être choisi par le mapper.
              PlayerPokemon(
                speciesId: 'spentmon',
                natureId: 'hardy',
                abilityId: 'pressure',
                level: 99,
                knownMoveIds: <String>['do-not-use'],
                currentHp: 0,
              ),
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                ivs: PokemonStatSpread(hp: 31),
                evs: PokemonStatSpread(hp: 8),
                knownMoveIds: <String>['growl', 'vine_whip'],
                currentHp: 23,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.playerPokemon.speciesId, equals('sproutle'));
      expect(setup.playerPokemon.level, equals(12));
      expect(setup.playerPokemon.currentHp, equals(23));
      expect(
        setup.playerPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['growl', 'vine_whip']),
      );
      expect(setup.playerPokemon.speciesId, isNot(equals('pikachu')));
    });

    test('uses the explicit player party index when the runtime provides one',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-player-index',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'hardy',
                abilityId: 'overgrow',
                level: 12,
                knownMoveIds: <String>['growl'],
                currentHp: 21,
              ),
              PlayerPokemon(
                speciesId: 'aquafi',
                natureId: 'calm',
                abilityId: 'torrent',
                level: 18,
                knownMoveIds: <String>['water_gun', 'aqua_ring'],
                currentHp: 17,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
        playerPartyIndex: 1,
      );

      expect(setup.playerPokemon.speciesId, equals('aquafi'));
      expect(setup.playerPokemon.currentHp, equals(17));
      expect(
        setup.playerPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['water_gun', 'aqua_ring']),
      );
    });

    test('maps a wild encounter from real project species and learnset data',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: _playerStateForTests(),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.isTrainerBattle, isFalse);
      expect(setup.allowCapture, isTrue);
      expect(setup.enemyPokemon.speciesId, equals('sparkitten'));
      expect(setup.enemyPokemon.level, equals(10));
      expect(setup.enemyPokemon.abilityId, equals('blaze'));
      expect(
        setup.enemyPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['scratch', 'tail_whip', 'ember']),
      );
      expect(
        setup.enemyPokemon.moves
            .firstWhere((move) => move.id == 'scratch')
            .power,
        equals(40),
      );
      expect(
        setup.enemyPokemon.moves
            .firstWhere((move) => move.id == 'tail_whip')
            .power,
        equals(0),
      );
      expect(
        setup.enemyPokemon.moves.map((move) => move.id),
        isNot(contains('flame_wheel')),
      );
      expect(setup.enemyPokemon.speciesId, isNot(equals('mew')));
    });

    test('falls back to the species id when the species has no learnset ref',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      await _rewriteSpeciesWithoutLearnsetRef(
        tempProjectRoot,
        speciesFileName: '001-sproutle.json',
        speciesId: 'sproutle',
        baseHp: 45,
        primaryAbilityId: 'overgrow',
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-species-id-fallback',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                currentHp: 20,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(
        setup.playerPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['tackle', 'growl', 'vine_whip']),
      );
    });

    test('disables capture in wild battles when the bag has no poke-ball',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: _playerStateForTests(
          bag: const Bag(),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.isTrainerBattle, isFalse);
      expect(setup.allowCapture, isFalse);
    });

    test('maps a trainer battle from the authored trainer team', () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'trainer_ace',
            name: 'Ace Jules',
            trainerClass: 'Ace Trainer',
            team: <ProjectTrainerPokemonEntry>[
              ProjectTrainerPokemonEntry(
                speciesId: 'aquafi',
                level: 18,
                moves: <String>['water_gun', 'aqua_ring'],
                heldItemId: 'mystic_water',
              ),
            ],
          ),
        ],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: _playerStateForTests(),
        request: _trainerRequest(),
      );

      expect(setup.isTrainerBattle, isTrue);
      expect(setup.allowCapture, isFalse);
      expect(setup.trainerId, equals('trainer_ace'));
      expect(setup.enemyPokemon.speciesId, equals('aquafi'));
      expect(setup.enemyPokemon.level, equals(18));
      expect(setup.enemyPokemon.abilityId, equals('torrent'));
      expect(
        setup.enemyPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['water_gun', 'aqua_ring']),
      );
      expect(setup.enemyPokemon.speciesId, isNot(equals('lapras')));
    });

    test('disables capture in wild battles when the party is already full',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final fullPartyState = GameState(
        saveId: 'save-full-party',
        bag: const Bag(
          entries: <BagEntry>[
            BagEntry(
              itemId: 'poke-ball',
              categoryId: 'items',
              quantity: 2,
            ),
          ],
        ),
        party: PlayerParty(
          members: List<PlayerPokemon>.generate(
            6,
            (index) => PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 12 + index,
              knownMoveIds: const <String>['growl'],
              currentHp: 20,
            ),
            growable: false,
          ),
        ),
      );

      final setup = await mapper.map(
        bundle: bundle,
        gameState: fullPartyState,
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.isTrainerBattle, isFalse);
      expect(setup.allowCapture, isFalse);
    });

    test(
        'throws explicitly when a runtime move reference is absent from the canonical catalog',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      await expectLater(
        () => mapper.map(
          bundle: bundle,
          gameState: const GameState(
            saveId: 'save-missing-move',
            party: PlayerParty(
              members: <PlayerPokemon>[
                PlayerPokemon(
                  speciesId: 'sproutle',
                  natureId: 'bold',
                  abilityId: 'overgrow',
                  level: 12,
                  knownMoveIds: <String>['move_that_does_not_exist'],
                  currentHp: 20,
                ),
              ],
            ),
          ),
          request: _wildRequest(
            speciesId: 'sparkitten',
            level: 10,
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

    test(
        'rejects an explicitly known move when its runtime support level is only partial',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      await _rewriteMoveCatalogEntrySupport(
        tempProjectRoot,
        moveId: 'growl',
        supportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
        unsupportedReasons: const <String>[
          'unsupported_mechanic:stat_drop_bridge',
        ],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      await expectLater(
        () => mapper.map(
          bundle: bundle,
          gameState: const GameState(
            saveId: 'save-unsupported-known-move',
            party: PlayerParty(
              members: <PlayerPokemon>[
                PlayerPokemon(
                  speciesId: 'sproutle',
                  natureId: 'bold',
                  abilityId: 'overgrow',
                  level: 12,
                  knownMoveIds: <String>['growl', 'vine_whip'],
                  currentHp: 20,
                ),
              ],
            ),
          ),
          request: _wildRequest(
            speciesId: 'sparkitten',
            level: 10,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>()
              .having(
                (error) => error.message,
                'message',
                contains('ne sait pas projeter honnêtement'),
              )
              .having(
                (error) => error.debugDetails,
                'debugDetails',
                allOf(
                  contains('combatant=Le Pokémon actif du joueur'),
                  contains('moveId=growl'),
                  contains('moveName=Growl'),
                  contains('engineSupportLevel=structuredPartial'),
                  contains(
                    'unsupportedReasons=[unsupported_mechanic:stat_drop_bridge]',
                  ),
                ),
              ),
        ),
      );
    });

    test(
        'rejects a learnset-derived move when its runtime support level is catalog only',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      await _rewriteMoveCatalogEntrySupport(
        tempProjectRoot,
        moveId: 'tackle',
        supportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
        unsupportedReasons: const <String>[
          'unsupported_mechanic:legacy_damage_bridge',
        ],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      await expectLater(
        () => mapper.map(
          bundle: bundle,
          gameState: const GameState(
            saveId: 'save-derived-unsupported-move',
            party: PlayerParty(
              members: <PlayerPokemon>[
                PlayerPokemon(
                  speciesId: 'sproutle',
                  natureId: 'bold',
                  abilityId: 'overgrow',
                  level: 12,
                  currentHp: 20,
                ),
              ],
            ),
          ),
          request: _wildRequest(
            speciesId: 'sparkitten',
            level: 10,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('combatant=Le Pokémon actif du joueur'),
              contains('moveId=tackle'),
              contains('moveName=Tackle'),
              contains('engineSupportLevel=catalogOnly'),
              contains(
                'unsupportedReasons=[unsupported_mechanic:legacy_damage_bridge]',
              ),
            ),
          ),
        ),
      );
    });
  });
}

GameState _playerStateForTests({
  Bag bag = const Bag(
    entries: <BagEntry>[
      BagEntry(
        itemId: 'poke-ball',
        categoryId: 'items',
        quantity: 2,
      ),
    ],
  ),
}) {
  return GameState(
    saveId: 'save-test',
    bag: bag,
    party: const PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          ivs: PokemonStatSpread(hp: 31),
          evs: PokemonStatSpread(hp: 8),
          knownMoveIds: <String>['growl', 'vine_whip'],
          currentHp: 23,
        ),
      ],
    ),
  );
}

RuntimeMapBundle _buildRuntimeBundle(
  String projectRootDirectory,
  ProjectManifest manifest,
) {
  return RuntimeMapBundle(
    manifest: manifest,
    map: const MapData(
      id: 'field_map',
      name: 'Field Map',
      size: GridSize(width: 8, height: 8),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
    ),
    projectRootDirectory: projectRootDirectory,
    tilesetAbsolutePathsById: const <String, String>{},
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

TrainerBattleStartRequest _trainerRequest() {
  return const TrainerBattleStartRequest(
    requestId: 'trainer-request',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    trainerId: 'trainer_ace',
    npcEntityId: 'npc_ace',
    mapId: 'field_map',
    playerPos: GridPos(x: 1, y: 1),
  );
}

Future<ProjectManifest> _writeAndLoadProjectManifest(
  Directory projectRoot, {
  required List<ProjectTrainerEntry> trainers,
}) async {
  final manifest = ProjectManifest(
    name: 'Battle Mapper Test',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'field_map',
        name: 'Field Map',
        relativePath: 'maps/field_map.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    trainers: trainers,
    pokemon: const ProjectPokemonConfig(
      dataRoot: 'custom/pokemon',
      speciesDir: 'custom/pokemon/species',
      learnsetsDir: 'custom/pokemon/learnsets',
      evolutionsDir: 'custom/pokemon/evolutions',
      mediaDir: 'custom/pokemon/media',
      catalogFiles: <String, String>{
        'moves': 'custom/pokemon/catalogs/moves.json',
      },
    ),
  );

  await _writeProjectJson(projectRoot, manifest.toJson());
  await _writePokemonFixtures(projectRoot);

  return loadProjectManifestFromFile(p.join(projectRoot.path, 'project.json'));
}

Future<void> _writeProjectJson(
  Directory projectRoot,
  Map<String, dynamic> json,
) async {
  final file = File(p.join(projectRoot.path, 'project.json'));
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}

Future<void> _writePokemonFixtures(Directory projectRoot) async {
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/001-sproutle.json',
    <String, dynamic>{
      'id': 'sproutle',
      'slug': 'sproutle',
      'nationalDex': 1,
      'names': <String, String>{'en': 'Sproutle'},
      'speciesName': <String, String>{'en': 'Seedling'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['grass'],
      },
      'baseStats': <String, int>{
        'hp': 45,
        'atk': 49,
        'def': 49,
        'spa': 65,
        'spd': 65,
        'spe': 45,
        'bst': 318,
      },
      'abilities': <String, String>{'primary': 'overgrow'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.875, 'female': 0.125},
        'eggGroups': <String>['monster', 'grass'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 64,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'sproutle',
        'evolution': 'sproutle',
        'media': 'sproutle',
      },
      'dexContent': <String, Object>{
        'heightM': 0.7,
        'weightKg': 6.9,
      },
      'gameplayFlags': <String, bool>{'starterEligible': true},
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/004-sparkitten.json',
    <String, dynamic>{
      'id': 'sparkitten',
      'slug': 'sparkitten',
      'nationalDex': 4,
      'names': <String, String>{'en': 'Sparkitten'},
      'speciesName': <String, String>{'en': 'Ember Cat'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['fire'],
      },
      'baseStats': <String, int>{
        'hp': 39,
        'atk': 52,
        'def': 43,
        'spa': 60,
        'spd': 50,
        'spe': 65,
        'bst': 309,
      },
      'abilities': <String, String>{'primary': 'blaze'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.875, 'female': 0.125},
        'eggGroups': <String>['field'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 62,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'sparkitten',
        'evolution': 'sparkitten',
        'media': 'sparkitten',
      },
      'dexContent': <String, Object>{
        'heightM': 0.6,
        'weightKg': 8.5,
      },
      'gameplayFlags': <String, bool>{'starterEligible': true},
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/007-aquafi.json',
    <String, dynamic>{
      'id': 'aquafi',
      'slug': 'aquafi',
      'nationalDex': 7,
      'names': <String, String>{'en': 'Aquafi'},
      'speciesName': <String, String>{'en': 'Tadpole'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['water'],
      },
      'baseStats': <String, int>{
        'hp': 44,
        'atk': 48,
        'def': 65,
        'spa': 50,
        'spd': 64,
        'spe': 43,
        'bst': 314,
      },
      'abilities': <String, String>{'primary': 'torrent'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.5, 'female': 0.5},
        'eggGroups': <String>['water_1'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 63,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'aquafi',
        'evolution': 'aquafi',
        'media': 'aquafi',
      },
      'dexContent': <String, Object>{
        'heightM': 0.5,
        'weightKg': 9.0,
      },
      'gameplayFlags': <String, bool>{'starterEligible': false},
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/sproutle.json',
    <String, dynamic>{
      'speciesId': 'sproutle',
      'startingMoves': <String>['tackle'],
      'relearnMoves': <String>['growl'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{
          'moveId': 'vine_whip',
          'level': 7,
          'source': 'level_up',
          'versionGroup': 'project',
        },
        <String, Object>{
          'moveId': 'razor_leaf',
          'level': 20,
          'source': 'level_up',
          'versionGroup': 'project',
        },
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
        <String, Object>{
          'moveId': 'ember',
          'level': 7,
          'source': 'level_up',
          'versionGroup': 'project',
        },
        <String, Object>{
          'moveId': 'flame_wheel',
          'level': 20,
          'source': 'level_up',
          'versionGroup': 'project',
        },
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
        <String, Object>{
          'moveId': 'aqua_ring',
          'level': 18,
          'source': 'level_up',
          'versionGroup': 'project',
        },
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
        'description': 'Runtime test move catalog',
      },
      'entries': <Map<String, Object?>>[
        _moveEntry('tackle', 'Tackle', 40),
        _moveEntry('growl', 'Growl', 0),
        _moveEntry('vine_whip', 'Vine Whip', 45),
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

  // Le helper reste volontairement minimal :
  // - il ne change que le niveau de support/runtime reasons d'une entrée déjà
  //   canonique ;
  // - il évite de dupliquer un second seed de test complet juste pour deux
  //   cas M5-bis ;
  // - il garde les fixtures globales existantes lisibles et stables.
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
    reason: 'Expected to find move "$moveId" in the canonical runtime fixture.',
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
      'baseStats': <String, int>{
        'hp': baseHp,
      },
      'abilities': <String, String>{
        'primary': primaryAbilityId,
      },
      // Ce helper retire volontairement `refs.learnset` pour vérifier que le
      // mapper, via le loader learnset, retombe bien sur l'id de l'espèce.
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

## `packages/map_runtime/test/runtime_pokemon_species_loader_test.dart`

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
      expect(species.baseHp, equals(45));
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
}) {
  return <String, dynamic>{
    'id': id,
    'baseStats': <String, int>{
      'hp': baseHp,
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

## `packages/map_runtime/test/runtime_pokemon_learnset_loader_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_exception.dart';
import 'package:map_runtime/src/application/runtime_pokemon_learnset_loader.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RuntimePokemonLearnsetLoader', () {
    late Directory tempProjectRoot;
    const loader = RuntimePokemonLearnsetLoader();

    setUp(() async {
      tempProjectRoot =
          await Directory.systemTemp.createTemp('runtime_learnset_loader_');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    test('loads a learnset by ref and preserves useful families', () async {
      await _writeLearnsetFile(
        tempProjectRoot,
        relativePath: 'custom/pokemon/learnsets/sproutle_alt.json',
        json: <String, dynamic>{
          'speciesId': 'sproutle',
          'startingMoves': <Object>['tackle', 123],
          'relearnMoves': <Object>['growl', true],
          'levelUp': <Object>[
            <String, Object>{'moveId': 'vine_whip', 'level': 7},
            <String, Object>{'moveId': '', 'level': 9},
            <String, Object>{'moveId': 'razor_leaf', 'level': 0},
            <String, Object>{'moveId': 'sleep_powder', 'level': 13},
            'not-a-map',
          ],
        },
      );

      final learnset = await loader.loadByRef(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        speciesRef: 'sproutle_alt',
        fallbackSpeciesId: 'sproutle',
      );

      expect(learnset.startingMoves, equals(<String>['tackle']));
      expect(learnset.relearnMoves, equals(<String>['growl']));
      expect(
        learnset.levelUp
            .map((entry) => (entry.moveId, entry.level))
            .toList(growable: false),
        equals(<(String, int)>[
          ('vine_whip', 7),
          ('sleep_powder', 13),
        ]),
      );
    });

    test('falls back to fallbackSpeciesId when the learnset ref is empty',
        () async {
      await _writeLearnsetFile(
        tempProjectRoot,
        relativePath: 'custom/pokemon/learnsets/sproutle.json',
        json: <String, dynamic>{
          'speciesId': 'sproutle',
          'startingMoves': <String>['tackle'],
          'relearnMoves': <String>['growl'],
          'levelUp': <Map<String, Object>>[
            <String, Object>{'moveId': 'vine_whip', 'level': 7},
          ],
        },
      );

      final learnset = await loader.loadByRef(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        speciesRef: '',
        fallbackSpeciesId: 'sproutle',
      );

      expect(learnset.startingMoves, equals(<String>['tackle']));
      expect(learnset.relearnMoves, equals(<String>['growl']));
      expect(learnset.levelUp.single.moveId, equals('vine_whip'));
    });

    test('fails explicitly when the learnset file is absent', () async {
      await expectLater(
        () => loader.loadByRef(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          speciesRef: 'sproutle',
          fallbackSpeciesId: 'sproutle',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('Pokemon learnset "sproutle" file not found'),
          ),
        ),
      );
    });

    test('fails explicitly when the learnset JSON is invalid', () async {
      await _writeRawProjectRelativeFile(
        tempProjectRoot,
        'custom/pokemon/learnsets/sproutle.json',
        '{ invalid json',
      );

      await expectLater(
        () => loader.loadByRef(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          speciesRef: 'sproutle',
          fallbackSpeciesId: 'sproutle',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('Pokemon learnset "sproutle" parse failed'),
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

Future<void> _writeLearnsetFile(
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

