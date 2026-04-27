# Réalignement des fondations Pokédex

Date : 2026-04-10

## Résumé exécutif

Cette intervention répare les incohérences de fondation les plus gênantes du système Pokédex local, sans élargir le scope vers l'import externe, les écrans de détail riches, les overrides ou le runtime.

Concrètement, le chantier a fait converger :

- le storage local vers `data/pokemon/media`
- le modèle espèce vers un vrai bloc `refs`
- l'existence d'un vrai `PokemonMediaFile`
- la lecture/écriture/validation/index Pokédex autour de ce contrat
- les tests et le seed de démonstration
- la config projet Pokémon avec l'ensemble des catalogues locaux déjà bootstrapés

Le résultat est beaucoup plus cohérent qu'avant :

- `ProjectPokemonConfig.mediaDir` et le bootstrap racontent enfin la même histoire
- le repo n'utilise plus `spriteSetRef` / `cryRef` comme contrat actif de vérité
- il existe un vrai JSON `media/<species>.json`
- l'index Pokédex utilise désormais `refs.media`
- les repositories et le validateur savent traiter les médias

## Problème exact corrigé

Avant ce correctif, le Pokédex local présentait plusieurs décalages structurels réels :

1. `project.json` pointait vers `data/pokemon/media`, mais le bootstrap local créait encore `data/pokemon/sprite_sets`.
2. `PokemonSpeciesFile` utilisait toujours un ancien contrat éclaté :
   - `learnsetRef`
   - `evolutionRef`
   - `spriteSetRef`
   - `cryRef`
3. Il n'existait pas de vrai `PokemonMediaFile`.
4. Les repositories de lecture/écriture ne savaient pas lire/écrire les médias Pokémon.
5. Le validateur et l'index Pokédex dépendaient encore de l'ancien shape `spriteSetRef` / `cryRef`.
6. Le bootstrap local et la config projet Pokémon n'étaient pas totalement cohérents sur les catalogues secondaires.

Le but de cette intervention était de réparer ces points sans mélanger :

- import externe
- UI riche de détail
- gameplay
- overrides
- runtime

## Périmètre inclus

Inclus dans ce correctif :

- réalignement du bootstrap local vers `data/pokemon/media`
- réalignement du manifeste local Pokémon bootstrap
- ajout d'un vrai `PokemonMediaFile`
- ajout d'un vrai bloc `PokemonSpeciesRefs`
- compatibilité de lecture legacy `spriteSetRef` / `cryRef` -> `refs.media`
- enrichissement minimal des modèles `learnset` et `evolution`
- ajout de lecture/écriture média dans les repositories
- extension du validateur Pokédex pour le média
- réalignement de `PokemonDatabaseIndex` sur `refs.media`
- extension de `ProjectPokemonConfig.catalogFiles` avec les catalogues secondaires déjà existants
- mise à jour des seeds de démonstration
- mise à jour des tests ciblés

## Périmètre explicitement exclu

Volontairement non traité ici :

- aucun import Showdown / PokeAPI
- aucune UI de fiche détail Pokédex
- aucune édition locale Pokédex
- aucune logique runtime / in-game
- aucun OwnedPokemon / Bag / SaveGame
- aucun changement d'architecture global hors Pokédex
- aucun refactor des catalogues génériques vers 11 familles Dart ultra typées

Note honnête :

- les catalogues restent modélisés via `PokemonCatalogFile`, donc la spécialisation forte par type de catalogue n'a pas été faite dans ce correctif.
- c'est une dette encore acceptable à ce stade, parce qu'elle n'empêche plus la cohérence des fondations Pokédex locales.

## Décisions techniques prises

### 1. Converger vers `refs`

Décision :

- `PokemonSpeciesFile` utilise maintenant `PokemonSpeciesRefs`.

Pourquoi :

- c'est le contrat retenu par le mémo produit ;
- ça supprime la duplication de vérité autour des références locales ;
- ça rend l'espèce plus stable pour la suite des lots.

Compatibilité :

- `PokemonSpeciesFile.fromJson(...)` sait encore lire l'ancien format si un JSON legacy contient `learnsetRef`, `evolutionRef`, `spriteSetRef`, `cryRef`.
- la sérialisation `toJson()` écrit désormais le nouveau contrat `refs`.

### 2. Introduire un vrai `PokemonMediaFile`

Décision :

- création de :
  - `PokemonMediaAnimationRef`
  - `PokemonMediaVariant`
  - `PokemonMediaFile`

Pourquoi :

- la séparation `species / learnsets / evolutions / media` faisait partie de la structure produit voulue ;
- sans vrai modèle média, les repos, la validation et l'index restaient sur un contrat provisoire.

### 3. Réparer le storage local au lieu de bricoler côté UI

Décision :

- `InitializePokemonProjectStorageUseCase` crée maintenant `data/pokemon/media/.keep`
- le manifeste local bootstrap utilise `futureDataFolders.media = media/`

Pourquoi :

- le problème était bien en fondation de données, pas en présentation.

### 4. Garder le scope strictement local

Décision :

- le média reste un JSON de références locales vers `assets/...`
- aucune vérification d'existence disque des assets n'a été ajoutée dans le validateur
- aucun GIF
- aucune lecture réelle d'assets binaires

Pourquoi :

- le but ici est de stabiliser le contrat de données, pas de lancer un pipeline média complet.

## Fichiers modifiés

### `map_core`

- `/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/project_manifest.dart`

### `map_editor` production

- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_database_index.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_validator.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`

### `map_editor` tests

- `/Users/karim/Project/pokemonProject/packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/seed_pokemon_demo_data_use_case_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_project_data_reader_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_read_repository_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_write_repository_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/validate_pokemon_project_data_use_case_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/project_pokemon_config_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_database_index_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/list_pokedex_entries_use_case_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart`

## Explication fichier par fichier

### `project_manifest.dart`

Changement :

- extension de `ProjectPokemonConfig.catalogFiles` avec :
  - `egg_groups`
  - `habitats`
  - `encounter_rules`
  - `generations`
  - `version_groups`

Pourquoi :

- ces catalogues existaient déjà dans le bootstrap local ;
- la config projet devait arrêter d'être plus pauvre que la réalité du workspace.

### `pokemon_project_data_models.dart`

Changements principaux :

- ajout de `PokemonSpeciesRefs`
- migration de `PokemonSpeciesFile` vers `refs`
- compatibilité de lecture legacy
- ajout de `PokemonMediaAnimationRef`
- ajout de `PokemonMediaVariant`
- ajout de `PokemonMediaFile`
- enrichissement de `PokemonLearnsetFile` avec :
  - `tm`
  - `tutor`
  - `egg`
  - `event`
  - `transfer`
- enrichissement de `PokemonEvolutionEntry` avec :
  - `itemId`
  - `requiredMoveId`
  - `conditionText`

Pourquoi :

- c'est le cœur du réalignement du schéma.

### `pokemon_database_index.dart`

Changement :

- `PokemonDatabaseIndexRefs` expose maintenant :
  - `learnset`
  - `evolution`
  - `media`

Pourquoi :

- l'index Pokédex ne devait plus refléter l'ancien contrat éclaté.

### `pokemon_read_repository.dart`

Ajouts :

- `listMediaIds(...)`
- `readMediaById(...)`

Pourquoi :

- la lecture média devait être un vrai contrat de port, pas un contournement.

### `pokemon_write_repository.dart`

Ajout :

- `saveMedia(...)`

Pourquoi :

- même logique que pour species / learnsets / evolutions / catalogues.

### `pokemon_project_data_reader.dart`

Ajouts :

- lecture média
- listing média

Modification :

- validation d'index basée sur `refs.media` au lieu de `spriteSetRef` / `cryRef`

Pourquoi :

- pour garder un reader cohérent avec le nouveau schéma.

### `pokemon_project_validator.dart`

Ajouts :

- chargement des médias
- validation de :
  - `species.media_ref_empty`
  - `species.media_ref_missing`
  - `media.species_id_empty`
  - `media.default_form_empty`
  - `media.variants_empty`
  - `media.species_missing`

Extension :

- les validations de moves couvrent aussi les nouvelles sections de learnset.

Pourquoi :

- le validateur devait suivre les fondations réellement stockées localement.

### `initialize_pokemon_project_storage_use_case.dart`

Changements :

- création de `data/pokemon/media`
- manifeste local `futureDataFolders.media`
- normalisation des clés catalogue bootstrap en snake_case

Pourquoi :

- réparation directe des incohérences les plus visibles du bootstrap.

### `seed_pokemon_demo_data_use_case.dart`

Changements :

- species seedées en `refs`
- ajout des fichiers `data/pokemon/media/*.json`
- enrichissement minimal learnset/evolution

Pourquoi :

- le seed devait produire un dataset conforme au nouveau contrat, sinon les tests restaient sur un ancien shape.

### `file_repositories.dart`

Changements :

- lecture média côté `FilePokemonReadRepository`
- écriture média côté `FilePokemonWriteRepository`

Pourquoi :

- compléter proprement les repos locaux sans inventer une nouvelle couche.

## Tests ajustés / ajoutés

Les tests existants ont été réalignés. Les principaux points désormais couverts :

- bootstrap local avec `data/pokemon/media`
- seed cohérent avec `refs` et `media`
- lecture d'un média Pokémon
- écriture d'un média Pokémon
- validation des références média
- index Pokédex basé sur `refs.media`
- compatibilité de la liste / UI Pokédex avec le nouveau contrat d'index
- config projet Pokémon enrichie avec les catalogues secondaires

## Commandes réellement exécutées

### Génération `map_core`

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core
dart run build_runner build --delete-conflicting-outputs
```

### Tests `map_core`

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core
dart test test/legacy_editor_json_compat_collision_test.dart
```

### Analyse `map_core`

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core
dart analyze lib/src/models/project_manifest.dart test/legacy_editor_json_compat_collision_test.dart
```

### Tests `map_editor`

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test \
  test/initialize_pokemon_project_storage_use_case_test.dart \
  test/seed_pokemon_demo_data_use_case_test.dart \
  test/pokemon_project_data_reader_test.dart \
  test/file_pokemon_read_repository_test.dart \
  test/file_pokemon_write_repository_test.dart \
  test/validate_pokemon_project_data_use_case_test.dart \
  test/project_pokemon_config_test.dart \
  test/pokemon_database_index_test.dart \
  test/list_pokedex_entries_use_case_test.dart \
  test/pokedex_workspace_ui_test.dart
```

### Analyse `map_editor`

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter analyze --no-pub \
  lib/src/application/models/pokemon_project_data_models.dart \
  lib/src/application/models/pokemon_database_index.dart \
  lib/src/application/ports/pokemon_read_repository.dart \
  lib/src/application/ports/pokemon_write_repository.dart \
  lib/src/application/services/pokemon_project_data_reader.dart \
  lib/src/application/services/pokemon_project_validator.dart \
  lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart \
  lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart \
  lib/src/infrastructure/repositories/file_repositories.dart \
  test/initialize_pokemon_project_storage_use_case_test.dart \
  test/seed_pokemon_demo_data_use_case_test.dart \
  test/pokemon_project_data_reader_test.dart \
  test/file_pokemon_read_repository_test.dart \
  test/file_pokemon_write_repository_test.dart \
  test/validate_pokemon_project_data_use_case_test.dart \
  test/project_pokemon_config_test.dart \
  test/pokemon_database_index_test.dart \
  test/list_pokedex_entries_use_case_test.dart \
  test/pokedex_workspace_ui_test.dart
```

### Vérifications d'état

```bash
cd /Users/karim/Project/pokemonProject
git status --short
git diff --stat -- <fichiers ciblés>
find . -maxdepth 2 \( -path './data' -o -path './assets' \) -print
./review_bundle.sh
```

## Résultats réels

### `map_core`

- `dart run build_runner build --delete-conflicting-outputs` ✅
- `dart test test/legacy_editor_json_compat_collision_test.dart` ✅
- `dart analyze ...` ✅ `No issues found!`

### `map_editor`

- `flutter test ...` ✅ `All tests passed!`
- `flutter analyze --no-pub ...` ✅ `No issues found!`

### Vérifications d'état

- `find . -maxdepth 2 \( -path './data' -o -path './assets' \) -print` ✅ aucune sortie
- `./review_bundle.sh` ✅ fichier généré :
  - `.review/review-20260410-234228.txt`

## État Git utile

`git status --short` au moment de la clôture :

- modifications attendues sur `map_core` / `map_editor` liées au correctif
- fichiers non suivis déjà présents hors périmètre :
  - `reports/map_editor_architecture_final_audit_2026-04-10.md`
  - `reports/pokedex-roadmap-status-and-next-steps-2026-04-10.md`

Point honnête :

- `build_runner` avait régénéré un fichier hors périmètre (`element_collision_profile.freezed.dart`) ;
- j'ai inspecté ce diff et je l'ai explicitement retiré pour ne pas polluer l'intervention.

## Diff ciblé

Sortie réelle de `git diff --stat -- ...` sur le correctif :

```text
.../map_core/lib/src/models/project_manifest.dart  |   5 +
.../application/models/pokemon_database_index.dart |  13 +-
.../models/pokemon_project_data_models.dart        | 327 +++++++++++++++++++--
.../application/ports/pokemon_read_repository.dart |   7 +
.../ports/pokemon_write_repository.dart            |   6 +
.../services/pokemon_project_data_reader.dart      |  52 +++-
.../services/pokemon_project_validator.dart        | 177 ++++++++++-
...nitialize_pokemon_project_storage_use_case.dart |  35 +--
.../use_cases/seed_pokemon_demo_data_use_case.dart | 102 ++++++-
.../repositories/file_repositories.dart            |  37 ++-
.../test/file_pokemon_read_repository_test.dart    |  27 +-
.../test/file_pokemon_write_repository_test.dart   | 157 +++++++---
...lize_pokemon_project_storage_use_case_test.dart |  49 +--
.../test/list_pokedex_entries_use_case_test.dart   |  41 ++-
.../map_editor/test/pokedex_workspace_ui_test.dart |   3 +-
.../test/pokemon_database_index_test.dart          |  30 +-
.../test/pokemon_project_data_reader_test.dart     |  39 ++-
.../test/project_pokemon_config_test.dart          |  31 +-
.../test/seed_pokemon_demo_data_use_case_test.dart |  55 +++-
...alidate_pokemon_project_data_use_case_test.dart |  68 +++--
20 files changed, 1020 insertions(+), 241 deletions(-)
```

## Ce qui est maintenant réparé par rapport aux lots partiels

### Réparé

- lot 1 : arborescence locale cohérente avec `media/`
- lot 2 : schéma espèce convergé vers `refs`
- lot 5 : vrai modèle média local
- lot 8 : lecture média locale
- lot 9 : écriture média locale
- lot 10 : validation média locale
- lot 11 : cohérence config projet / storage réel
- lot 12 : index Pokédex aligné sur `refs.media`

### Amélioré mais pas “maximalement exhaustif”

- lot 3 : learnset enrichi mais pas encore totalement exhaustif
- lot 4 : évolution enrichie mais pas encore totalement exhaustive
- lot 6/7 : catalogues cohérents et mieux alignés, mais toujours portés par un contrat générique `PokemonCatalogFile`

## Limites restantes / hors périmètre

Restent volontairement pour plus tard :

- spécialisation fine des catalogues globaux en types Dart dédiés par domaine
- import interne UI
- import externe Showdown / PokeAPI
- overrides Pokédex
- vue détail Pokédex riche
- édition Pokédex
- OwnedPokemon / SaveGame / runtime in-game

## Conclusion honnête

Ce correctif ne “termine” pas toute la roadmap Pokédex, mais il remet les fondations dans un état beaucoup plus propre et plus défendable.

Avant :

- la config projet, le bootstrap, les refs espèce et l'index Pokédex ne parlaient pas exactement le même langage.

Après :

- le contrat de données local est bien plus cohérent ;
- le média Pokémon existe comme vraie couche ;
- la lecture/écriture/validation/index suivent tous le même axe ;
- les tests ciblés passent ;
- l'analyse ciblée est propre.

Le prochain mouvement logique est maintenant beaucoup plus sain :

- reprendre la roadmap fonctionnelle Pokédex sur des fondations stabilisées,
- plutôt que continuer à empiler de la UI sur un schéma provisoire.

