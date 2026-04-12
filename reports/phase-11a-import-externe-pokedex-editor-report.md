# Phase 11A — Import externe Pokédex Editor

## 1. Résumé exécutif honnête

La phase 11A a été branchée jusqu’au produit sans recréer de pipeline parallèle. L’éditeur peut maintenant prévisualiser et importer une espèce depuis une source produit unique `API externe`, en réutilisant le port externe existant, le `dryRun` existant et les use cases existants.

Ce qui marche réellement maintenant :

- PokeAPI est branchée pour `pokemon`, `pokemon-species`, `evolution-chain` et les assets binaires.
- Showdown est branché comme source structurée complémentaire via snapshots `pokedex.json`, `learnsets.json` et `moves.json`.
- Le repository externe concret compose PokeAPI live et Showdown snapshot derrière le port existant.
- Le use case externe existant sait désormais enrichir l’espèce locale avec `pokemon-species`, traiter learnset/evolution comme best-effort, produire une preview riche via `dryRun`, et télécharger images/cries vers des chemins locaux du projet.
- Le wizard Pokédex Editor expose une vraie source `API externe`, une étape de saisie, une étape d’aperçu, puis l’import avec refresh et feedback.

Ce qui ne marche pas encore dans cette phase :

- pas d’import batch produit ;
- pas de hardening avancé (retry/backoff/cache disque) ;
- pas de vraie Move Library UI ;
- pas de parser dédié pour `abilities.js` Showdown, la donnée ability restant suffisante via `pokedex.json` pour le core species de cette phase.

## 2. État initial audité

- Le port externe existant ne couvrait que Showdown species + PokeAPI `pokemon` + PokeAPI `evolution-chain`.
- Les use cases externes existaient déjà : import unitaire, batch, `dryRun`, merge policy, convertisseurs, génération de media stub.
- Le wizard Pokédex Editor n’exposait réellement que le flux JSON local ; les cartes PokéAPI / Showdown n’étaient pas branchées comme produit.
- Le write repository Pokédex savait écrire les JSON métier, mais pas les assets binaires.
- `project.json` n’était pas impliqué par le pipeline d’import Pokémon ; cette contrainte a été conservée.

## 3. Faits vérifiés sur PokeAPI / Showdown / autres sources

Vérifications réseau réellement exécutées pendant cette phase :

- `pokemon/bulbasaur` renvoie bien `types`, `moves`, `sprites`, `cries`.
- `pokemon-species/bulbasaur` renvoie bien `names`, `flavor_text_entries`, `generation`, `evolution_chain.url`.
- `https://play.pokemonshowdown.com/data/pokedex.json` expose bien types, abilities et baseStats structurés.
- `https://play.pokemonshowdown.com/data/learnsets.json` expose bien les learnsets structurés.
- `https://play.pokemonshowdown.com/data/abilities.js` existe, mais sous forme d’export JS non JSON ; il a été audité puis laissé hors wiring direct 11A pour éviter un parseur supplémentaire non nécessaire au produit.

## 4. Stratégie source retenue

- Source visible côté UI : `API externe`.
- Source live principale : PokeAPI.
- Source structurée complémentaire : Showdown snapshot/data.
- Source d’assets secondaire : URLs PokeAPI elles-mêmes ; pas de GIF ; pas d’URL distante persistée.
- Politique bloquante / best-effort :
  - species : bloquant ;
  - learnset : non bloquant ;
  - evolution : non bloquant ;
  - images : best effort ;
  - cries : best effort.

Cartographie retenue :

- core species structuré : Showdown `pokedex.json` via le converter existant ;
- enrichissement encyclopédique : PokeAPI `pokemon-species` ;
- learnset : PokeAPI `pokemon` ;
- evolution : PokeAPI `evolution-chain` ;
- portrait : `other.official-artwork.front_default` ;
- front/back/shiny : `sprites.*` statiques ;
- cri : `cries.latest`, fallback `cries.legacy`.

## 5. Lots 57 à 64 — ce qui a été réellement fait

### Lot 57 — Geler la stratégie source

- mapping source/usage figé dans le code d’orchestration, le report et les adaptateurs ;
- audit move catalog effectué : l’import externe n’exige pas de catalogue moves pour écrire le learnset, mais le validateur projet peut signaler des moves absents plus tard ; ce point a été documenté comme dette hors 11A.

### Lot 58 — Adapter PokeAPI live

- ajout de `PokeApiLiveSource` avec cache mémoire, `User-Agent`, timeout, surface 404/timeout/payload invalide et téléchargement binaire.

### Lot 59 — Adapter Showdown snapshot/data

- ajout de `ShowdownSnapshotSource` avec cache mémoire pour `pokedex.json`, `learnsets.json`, `moves.json` ;
- lecture UI/runtime interdite respectée : aucun parsing Showdown dans le wizard.

### Lot 60 — Implémentation concrète du repository externe existant

- ajout de `HttpPokemonExternalSourceRepository` ;
- extension minimale du port existant pour `pokemon-species` et `fetchBinaryAsset`, sans port concurrent.

### Lot 61 — Preview externe via dry-run

- le wizard réutilise le `dryRun` existant ;
- la preview expose speciesId, nom, dex, types, learnset/evolution/media/cri, warnings et conflits.

### Lot 62 — Politique média + cries

- règles best-effort implémentées dans le use case ;
- exclusion explicite des GIF ;
- aucune URL distante persistée dans les JSON locaux.

### Lot 63 — Télécharger et stocker les assets locaux

- ajout de l’écriture binaire locale via `PokemonWriteRepository.saveBinaryAsset` ;
- téléchargement des assets sous `assets/pokemon/...` ;
- maintien du media stub JSON comme contrat local stable.

### Lot 64 — Wizard UI d’import API

- source `API externe` réellement branchée ;
- saisie nom/slug/dex ;
- preview ;
- import ;
- refresh de liste, auto-sélection, feedback succès/erreur.

## 6. Fichiers modifiés / créés / supprimés

Modifiés :

- `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`
- `packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart`
- `packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart`
- `packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_support.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart`
- `packages/map_editor/test/import_external_pokemon_use_cases_test.dart`
- `packages/map_editor/test/pokedex_workspace_ui_test.dart`
- `packages/map_editor/test/provider_wiring_test.dart`

Créés :

- `packages/map_editor/lib/src/application/services/pokeapi_pokemon_species_enricher.dart`
- `packages/map_editor/lib/src/infrastructure/external/pokeapi_live_source.dart`
- `packages/map_editor/lib/src/infrastructure/external/showdown_snapshot_source.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart`
- `packages/map_editor/test/http_pokemon_external_source_repository_test.dart`
- `packages/map_editor/test/pokeapi_live_source_test.dart`
- `packages/map_editor/test/showdown_snapshot_source_test.dart`

Supprimés : aucun.

## 7. Justification fichier par fichier

- `pokedex_providers.dart` : branchement DI/provider du repository externe concret et des use cases/flows UI associés.
- `pokemon_external_source_repository.dart` : extension minimale du port existant pour `pokemon-species` et les assets binaires.
- `pokemon_write_repository.dart` : ajout d’une capacité d’écriture binaire locale sans créer de service parallèle.
- `import_external_pokemon_use_cases.dart` : cœur de l’orchestration 11A ; enrichissement species, preview, best-effort optionnel, téléchargement d’assets, résultat produit détaillé.
- `file_repositories.dart` : implémentation concrète de l’écriture binaire locale.
- `pokeapi_live_source.dart` : adaptateur HTTP PokeAPI live.
- `showdown_snapshot_source.dart` : adaptateur Showdown snapshot structuré.
- `http_pokemon_external_source_repository.dart` : composition PokeAPI + Showdown derrière le port existant.
- `pokeapi_pokemon_species_enricher.dart` : enrichissement encyclopédique/localisé de l’espèce convertie.
- `pokedex_workspace_loader.dart` : nouveaux typedefs pour preview/import externe.
- `pokedex_workspace_page.dart` et `pokedex_workspace_body.dart` : injection des callbacks externes et refresh workspace.
- `pokedex_import_flow.dart`, `pokedex_import_flow_steps.dart`, `pokedex_import_flow_support.dart` : extension du wizard existant pour `API externe`, preview et wording produit.
- `import_external_pokemon_use_cases_test.dart` : couverture métier, best-effort, enrichissement et téléchargement local.
- `pokeapi_live_source_test.dart`, `showdown_snapshot_source_test.dart`, `http_pokemon_external_source_repository_test.dart` : couverture infra.
- `provider_wiring_test.dart` : couverture du wiring DI/providers.
- `pokedex_workspace_ui_test.dart` : couverture du flow widget JSON existant + nouveau flow `API externe`.

## 8. Sub-agents utilisés

- API Facts Auditor : a confirmé l’état réel des endpoints et le manque de `pokemon-species` dans le port existant.
- Architecture Integrator : a validé l’extension minimale du port et la réutilisation du `dryRun`/wizard existants.
- Media & Cries Reviewer : a verrouillé les chemins locaux, l’exclusion des GIF et l’interdiction des URLs persistées.
- UI/UX Reviewer : a confirmé la source produit unique `API externe` et un flow simple saisie → preview → import.
- Tests / QA Reviewer : a pointé les trous de couverture sur providers et assets.
- Contradictor : a challengé le scope pour éviter une deuxième stack d’import et toute dérive vers 11B.

Contrainte rencontrée : la limite de threads empêchait `spawn_agent`, donc des threads existants ont été réutilisés via `send_input`.

## 9. Commandes réellement exécutées

Audit repo :

```bash
git status --short -- packages/map_editor reports/phase-11a-import-externe-pokedex-editor-report.md
git diff --stat -- packages/map_editor reports/phase-11a-import-externe-pokedex-editor-report.md
rg -n "showPokedexImportFlowSheet|moveId|learnset|typing|types" packages/map_editor/...
sed -n ... sur les fichiers touchés et les tests ciblés
```

Audit live des sources :

```bash
curl -fsSL -H 'User-Agent: PokeMapEditor/0.1 (+https://pokemap.local)' https://pokeapi.co/api/v2/pokemon/bulbasaur | jq '{id, name, has_types: (.types|length>0), has_moves: (.moves|length>0), has_cries: (.cries.latest != null or .cries.legacy != null), has_sprites: (.sprites.front_default != null)}'
curl -fsSL -H 'User-Agent: PokeMapEditor/0.1 (+https://pokemap.local)' https://pokeapi.co/api/v2/pokemon-species/bulbasaur | jq '{id, name, generation: .generation.name, has_names: (.names|length>0), has_flavor_text_entries: (.flavor_text_entries|length>0), evolution_chain_url: .evolution_chain.url}'
curl -fsSL -H 'User-Agent: PokeMapEditor/0.1 (+https://pokemap.local)' https://play.pokemonshowdown.com/data/pokedex.json | jq '.bulbasaur | {name, num, types, abilities, baseStats}'
curl -fsSL -H 'User-Agent: PokeMapEditor/0.1 (+https://pokemap.local)' https://play.pokemonshowdown.com/data/learnsets.json | jq '.bulbasaur | {exists: (. != null), learnset_sample: (.learnset.tackle // null)}'
curl -fsSL -H 'User-Agent: PokeMapEditor/0.1 (+https://pokemap.local)' https://play.pokemonshowdown.com/data/abilities.js | sed -n '1,12p'
```

Validation :

```bash
dart format \ \ncd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub lib/src/app/providers/pokedex/pokedex_providers.dart lib/src/application/ports/pokemon_external_source_repository.dart lib/src/application/ports/pokemon_write_repository.dart lib/src/application/services/pokeapi_pokemon_species_enricher.dart lib/src/application/use_cases/import_external_pokemon_use_cases.dart lib/src/infrastructure/external/pokeapi_live_source.dart lib/src/infrastructure/external/showdown_snapshot_source.dart lib/src/infrastructure/repositories/file_repositories.dart lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_support.dart lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart lib/src/ui/canvas/pokedex_workspace_loader.dart test/import_external_pokemon_use_cases_test.dart test/pokeapi_live_source_test.dart test/showdown_snapshot_source_test.dart test/http_pokemon_external_source_repository_test.dart test/provider_wiring_test.dart test/pokedex_workspace_ui_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/import_external_pokemon_use_cases_test.dart test/pokeapi_live_source_test.dart test/showdown_snapshot_source_test.dart test/http_pokemon_external_source_repository_test.dart test/provider_wiring_test.dart test/pokedex_workspace_ui_test.dart
```

## 10. Résultats réels

- `dart format` final : `Formatted 21 files (0 changed) in 0.07 seconds.`
- `flutter analyze --no-pub ...` final : `No issues found! (ran in 1.7s)`
- `flutter test ...` final : `00:06 +54: All tests passed!`
- PokeAPI live audit : Bulbasaur renvoie bien types, moves, sprites et cries.
- PokeAPI species live audit : Bulbasaur renvoie bien generation, noms localisés, flavor texts et `evolution_chain.url`.
- Showdown snapshot live audit : `pokedex.json` et `learnsets.json` renvoient bien une donnée structurée exploitable.

## 11. Incidents rencontrés

- un premier `flutter analyze` a accidentellement analysé trop large à cause d’une résolution de chemins imparfaite ; relancé ensuite de manière strictement ciblée ;
- une erreur de typage dans `_tryConvertOptional` bloquait la compilation (`Future<T>` vs conversion synchrone) ; corrigée via `FutureOr<T>` et typage explicite ;
- le wording du widget d’aperçu affichait `Évolutions trouvés` au lieu de `Évolutions trouvées`, ce qui cassait les tests UI ; corrigé dans le composant de statut ;
- les endpoints externes répondaient plus proprement avec un `User-Agent` explicite ; ce header a été conservé dans les adaptateurs.

## 12. Limites restantes

- le batch produit (lot 65) n’est pas exposé dans l’éditeur ;
- pas de cache disque, seulement un cache mémoire de session ;
- `abilities.js` Showdown n’est pas normalisé dans cette phase ;
- les learnsets importés peuvent encore référencer des `moveId` absents du catalogue local ; cela n’empêche pas l’import 11A, mais le validateur projet peut ensuite remonter des warnings `learnset.move_missing_in_catalog`.

## 13. État Git utile

### `git status --short`

```text
 M packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart
 M packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart
 M packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart
 M packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart
 M packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_support.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart
 M packages/map_editor/test/import_external_pokemon_use_cases_test.dart
 M packages/map_editor/test/pokedex_workspace_ui_test.dart
 M packages/map_editor/test/provider_wiring_test.dart
?? packages/map_editor/lib/src/application/services/pokeapi_pokemon_species_enricher.dart
?? packages/map_editor/lib/src/infrastructure/external/
?? packages/map_editor/lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart
?? packages/map_editor/test/http_pokemon_external_source_repository_test.dart
?? packages/map_editor/test/pokeapi_live_source_test.dart
?? packages/map_editor/test/showdown_snapshot_source_test.dart
```

### `git diff --stat`

```text
 .../app/providers/pokedex/pokedex_providers.dart   |  67 ++
 .../ports/pokemon_external_source_repository.dart  |  52 +-
 .../ports/pokemon_write_repository.dart            |  12 +
 .../import_external_pokemon_use_cases.dart         | 720 +++++++++++++++++++--
 .../repositories/file_repositories.dart            |  24 +
 .../pokedex_workspace/pokedex_import_flow.dart     | 270 ++++++--
 .../pokedex_import_flow_steps.dart                 | 326 +++++++++-
 .../pokedex_import_flow_support.dart               |  83 ++-
 .../pokedex_workspace/pokedex_workspace_body.dart  |  11 +-
 .../pokedex_workspace/pokedex_workspace_page.dart  |  16 +
 .../src/ui/canvas/pokedex_workspace_loader.dart    |  12 +
 .../import_external_pokemon_use_cases_test.dart    | 264 +++++++-
 .../map_editor/test/pokedex_workspace_ui_test.dart | 220 +++++++
 packages/map_editor/test/provider_wiring_test.dart |  10 +
 14 files changed, 1898 insertions(+), 189 deletions(-)
```

### `git ls-files --others --exclude-standard`

```text
packages/map_editor/lib/src/application/services/pokeapi_pokemon_species_enricher.dart
packages/map_editor/lib/src/infrastructure/external/pokeapi_live_source.dart
packages/map_editor/lib/src/infrastructure/external/showdown_snapshot_source.dart
packages/map_editor/lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart
packages/map_editor/test/http_pokemon_external_source_repository_test.dart
packages/map_editor/test/pokeapi_live_source_test.dart
packages/map_editor/test/showdown_snapshot_source_test.dart
```

## 14. Checklist finale

- [x] lots 57 à 64 couverts uniquement
- [x] aucune phase 11B ouverte
- [x] aucun nouveau port externe concurrent
- [x] aucun nouveau use case externe concurrent inutile
- [x] `dryRun` existant réutilisé pour la preview
- [x] PokeAPI branchée réellement
- [x] Showdown intégré proprement comme source complémentaire snapshot/data
- [x] images téléchargées si disponibles
- [x] cries téléchargés si disponibles
- [x] aucun GIF utilisé
- [x] aucune URL distante persistée dans les JSON locaux
- [x] assets réécrits en chemins locaux projet
- [x] `project.json` inchangé
- [x] UI wizard API externe branchée
- [x] feedback utilisateur clair
- [x] code manuel très abondamment commenté
- [x] sub-agents utilisés intelligemment
- [x] tests passent
- [x] analyse passe
- [x] rapport final généré
- [x] contenu complet des fichiers texte touchés inclus dans le rapport
- [x] manifest des assets binaires inclus dans le rapport

## 15. Annexe — Manifest assets binaires

Aucun asset binaire n’a été ajouté au repository pendant cette phase. Les téléchargements d’assets sont couverts par tests et écrits dans des workspaces temporaires, pas committés dans le repo.

## 16. Annexe — Contenu complet des fichiers texte modifiés / créés

### `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../application/ports/pokemon_read_repository.dart';
import '../../../application/ports/pokemon_external_source_repository.dart';
import '../../../application/ports/pokemon_write_repository.dart';
import '../../../application/services/pokemon_database_index.dart';
import '../../../application/use_cases/import_external_pokemon_use_cases.dart';
import '../../../application/use_cases/import_pokemon_evolution_json_use_case.dart';
import '../../../application/use_cases/import_pokemon_json_bundle_use_case.dart';
import '../../../application/use_cases/import_pokemon_learnset_json_use_case.dart';
import '../../../application/use_cases/import_pokemon_media_json_use_case.dart';
import '../../../application/use_cases/import_pokemon_species_json_use_case.dart';
import '../../../application/use_cases/load_pokedex_species_detail_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_evolution_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_forms_classification_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_learnset_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_metadata_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_media_use_case.dart';
import '../../../infrastructure/external/pokeapi_live_source.dart';
import '../../../infrastructure/external/showdown_snapshot_source.dart';
import '../../../infrastructure/repositories/http_pokemon_external_source_repository.dart';
import '../../../infrastructure/repositories/file_repositories.dart';
import '../../../ui/canvas/pokedex_workspace_loader.dart';
import '../core/repository_providers.dart';

/// Wiring Pokédex local minimal.
///
/// Ce fichier reste volontairement petit et thématique :
/// - le workspace Pokédex n'instancie plus l'infrastructure directement ;
/// - on réutilise les repositories/services existants ;
/// - on ne crée pas un nouveau notifier ni une couche "future-proof" inutile.
final pokemonReadRepositoryProvider = Provider<PokemonReadRepository>((ref) {
  return const FilePokemonReadRepository();
});

final pokemonWriteRepositoryProvider = Provider<PokemonWriteRepository>((ref) {
  return const FilePokemonWriteRepository();
});

final pokemonExternalHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final pokeApiLiveSourceProvider = Provider<PokeApiLiveSource>((ref) {
  return PokeApiLiveSource(
    client: ref.watch(pokemonExternalHttpClientProvider),
  );
});

final showdownSnapshotSourceProvider = Provider<ShowdownSnapshotSource>((ref) {
  return ShowdownSnapshotSource(
    client: ref.watch(pokemonExternalHttpClientProvider),
  );
});

final pokemonExternalSourceRepositoryProvider =
    Provider<PokemonExternalSourceRepository>((ref) {
  return HttpPokemonExternalSourceRepository(
    pokeApiSource: ref.watch(pokeApiLiveSourceProvider),
    showdownSource: ref.watch(showdownSnapshotSourceProvider),
  );
});

final pokemonDatabaseIndexProvider = Provider<PokemonDatabaseIndex>((ref) {
  return PokemonDatabaseIndex(
    projectRepository: ref.watch(projectRepositoryProvider),
    pokemonReadRepository: ref.watch(pokemonReadRepositoryProvider),
  );
});

final pokedexEntryLoaderProvider = Provider<PokedexEntryLoader>((ref) {
  return createPokedexEntryLoader(
    projectRepository: ref.watch(projectRepositoryProvider),
    databaseIndex: ref.watch(pokemonDatabaseIndexProvider),
  );
});

final pokedexListProvider = Provider<PokedexEntryLoader>((ref) {
  return ref.watch(pokedexEntryLoaderProvider);
});

final loadPokedexSpeciesDetailUseCaseProvider =
    Provider<LoadPokedexSpeciesDetailUseCase>((ref) {
  return LoadPokedexSpeciesDetailUseCase(
    ref.watch(pokemonReadRepositoryProvider),
  );
});

final pokedexSpeciesDetailLoaderProvider =
    Provider<PokedexSpeciesDetailLoader>((ref) {
  final useCase = ref.watch(loadPokedexSpeciesDetailUseCaseProvider);
  return (workspace, speciesId) => useCase.execute(workspace, speciesId);
});

final importPokemonSpeciesJsonUseCaseProvider =
    Provider<ImportPokemonSpeciesJsonUseCase>((ref) {
  return ImportPokemonSpeciesJsonUseCase(
    ref.watch(pokemonWriteRepositoryProvider),
  );
});

final importPokemonLearnsetJsonUseCaseProvider =
    Provider<ImportPokemonLearnsetJsonUseCase>((ref) {
  return ImportPokemonLearnsetJsonUseCase(
    ref.watch(pokemonWriteRepositoryProvider),
  );
});

final importPokemonEvolutionJsonUseCaseProvider =
    Provider<ImportPokemonEvolutionJsonUseCase>((ref) {
  return ImportPokemonEvolutionJsonUseCase(
    ref.watch(pokemonWriteRepositoryProvider),
  );
});

final importPokemonMediaJsonUseCaseProvider =
    Provider<ImportPokemonMediaJsonUseCase>((ref) {
  return ImportPokemonMediaJsonUseCase(
    ref.watch(pokemonWriteRepositoryProvider),
  );
});

final importPokemonJsonBundleUseCaseProvider =
    Provider<ImportPokemonJsonBundleUseCase>((ref) {
  return ImportPokemonJsonBundleUseCase(
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
    speciesImportUseCase: ref.watch(importPokemonSpeciesJsonUseCaseProvider),
    learnsetImportUseCase: ref.watch(importPokemonLearnsetJsonUseCaseProvider),
    evolutionImportUseCase:
        ref.watch(importPokemonEvolutionJsonUseCaseProvider),
    mediaImportUseCase: ref.watch(importPokemonMediaJsonUseCaseProvider),
  );
});

final pokedexImportPreviewerProvider = Provider<PokedexImportPreviewer>((ref) {
  final useCase = ref.watch(importPokemonJsonBundleUseCaseProvider);
  return (workspace, absoluteSpeciesSourcePath) => useCase.preview(
        workspace,
        absoluteSpeciesSourcePath: absoluteSpeciesSourcePath,
      );
});

final pokedexImporterProvider = Provider<PokedexImporter>((ref) {
  final useCase = ref.watch(importPokemonJsonBundleUseCaseProvider);
  return (workspace, absoluteSpeciesSourcePath) => useCase.execute(
        workspace,
        absoluteSpeciesSourcePath: absoluteSpeciesSourcePath,
      );
});

final importExternalPokemonSpeciesUseCaseProvider =
    Provider<ImportExternalPokemonSpeciesUseCase>((ref) {
  return ImportExternalPokemonSpeciesUseCase(
    externalSourceRepository:
        ref.watch(pokemonExternalSourceRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final batchImportExternalPokemonSpeciesUseCaseProvider =
    Provider<BatchImportExternalPokemonSpeciesUseCase>((ref) {
  return BatchImportExternalPokemonSpeciesUseCase(
    ref.watch(importExternalPokemonSpeciesUseCaseProvider),
  );
});

final pokedexExternalImportPreviewerProvider =
    Provider<PokedexExternalImportPreviewer>((ref) {
  final useCase = ref.watch(importExternalPokemonSpeciesUseCaseProvider);
  return (workspace, speciesQuery) => useCase.execute(
        workspace,
        speciesId: speciesQuery,
        dryRun: true,
      );
});

final pokedexExternalImporterProvider =
    Provider<PokedexExternalImporter>((ref) {
  final useCase = ref.watch(importExternalPokemonSpeciesUseCaseProvider);
  return (workspace, speciesQuery) => useCase.execute(
        workspace,
        speciesId: speciesQuery,
      );
});

final updatePokedexSpeciesMetadataUseCaseProvider =
    Provider<UpdatePokedexSpeciesMetadataUseCase>((ref) {
  return UpdatePokedexSpeciesMetadataUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexSpeciesMetadataSaverProvider =
    Provider<PokedexSpeciesMetadataSaver>((ref) {
  final useCase = ref.watch(updatePokedexSpeciesMetadataUseCaseProvider);
  return (workspace, request) => useCase.execute(workspace, request);
});

final updatePokedexSpeciesFormsClassificationUseCaseProvider =
    Provider<UpdatePokedexSpeciesFormsClassificationUseCase>((ref) {
  return UpdatePokedexSpeciesFormsClassificationUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexSpeciesFormsClassificationSaverProvider =
    Provider<PokedexSpeciesFormsClassificationSaver>((ref) {
  final useCase = ref.watch(
    updatePokedexSpeciesFormsClassificationUseCaseProvider,
  );
  return (workspace, request) => useCase.execute(workspace, request);
});

final updatePokedexSpeciesLearnsetUseCaseProvider =
    Provider<UpdatePokedexSpeciesLearnsetUseCase>((ref) {
  return UpdatePokedexSpeciesLearnsetUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexSpeciesLearnsetSaverProvider =
    Provider<PokedexSpeciesLearnsetSaver>((ref) {
  final useCase = ref.watch(updatePokedexSpeciesLearnsetUseCaseProvider);
  return (workspace, request) => useCase.execute(workspace, request);
});

final updatePokedexSpeciesEvolutionUseCaseProvider =
    Provider<UpdatePokedexSpeciesEvolutionUseCase>((ref) {
  return UpdatePokedexSpeciesEvolutionUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexSpeciesEvolutionSaverProvider =
    Provider<PokedexSpeciesEvolutionSaver>((ref) {
  final useCase = ref.watch(updatePokedexSpeciesEvolutionUseCaseProvider);
  return (workspace, request) => useCase.execute(workspace, request);
});

final updatePokedexSpeciesMediaUseCaseProvider =
    Provider<UpdatePokedexSpeciesMediaUseCase>((ref) {
  return UpdatePokedexSpeciesMediaUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexSpeciesMediaSaverProvider =
    Provider<PokedexSpeciesMediaSaver>((ref) {
  final useCase = ref.watch(updatePokedexSpeciesMediaUseCaseProvider);
  return (workspace, request) => useCase.execute(workspace, request);
});

```

### `packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart`

```dart
import 'dart:typed_data';

/// Frontière applicative unique pour lire les données Pokémon externes.
///
/// Cette abstraction reste volontairement concentrée sur le pipeline déjà en
/// place dans l'application :
/// - Showdown reste la source structurée complémentaire pour le core species ;
/// - PokeAPI reste la source live principale pour `pokemon`, `pokemon-species`
///   et `evolution-chain` ;
/// - les médias et cries sont aussi lus via cette même frontière pour éviter
///   de créer un second sous-système réseau à côté de l'import existant.
///
/// Important :
/// - on étend minimalement le port historique au lieu d'en créer un nouveau ;
/// - le use case garde ainsi une seule dépendance externe injectable ;
/// - l'UI ne voit jamais de client HTTP concret ni d'URL brutes.
abstract class PokemonExternalSourceRepository {
  Future<Map<String, dynamic>> fetchShowdownSpeciesPayload(String speciesId);

  Future<Map<String, dynamic>> fetchPokeApiPokemonPayload(String speciesId);

  Future<Map<String, dynamic>> fetchPokeApiPokemonSpeciesPayload(
    String speciesId,
  );

  Future<Map<String, dynamic>> fetchPokeApiEvolutionChainPayload(
    String speciesId,
  );

  Future<PokemonExternalBinaryAsset> fetchBinaryAsset(String sourceUrl);
}

/// Payload binaire téléchargé depuis une source externe.
///
/// On garde ici juste le strict nécessaire pour réécrire l'asset localement :
/// - l'URL source réellement utilisée ;
/// - les bytes ;
/// - le content-type quand la réponse HTTP en expose un.
class PokemonExternalBinaryAsset {
  const PokemonExternalBinaryAsset({
    required this.sourceUrl,
    required this.bytes,
    this.contentType,
  });

  final String sourceUrl;
  final Uint8List bytes;
  final String? contentType;
}

```

### `packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart`

```dart
import '../models/pokemon_project_data_models.dart';
import 'project_workspace.dart';

/// Contrat d'écriture des données Pokémon locales d'un projet utilisateur.
///
/// Cette frontière garde les use cases applicatifs découplés de `dart:io`
/// et du layout concret du workspace. Le contrat reste volontairement petit :
/// il couvre uniquement les fichiers JSON déjà stabilisés à ce stade.
abstract class PokemonWriteRepository {
  /// Écrit un catalogue global dans `data/pokemon/catalogs/...`.
  ///
  /// Le `catalogKey` représente la clé logique utilisée dans le manifeste
  /// local (`moves`, `abilities`, `types`, etc.).
  Future<void> saveCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
    PokemonCatalogFile catalog,
  );

  /// Écrit une espèce Pokémon dans `data/pokemon/species/...`.
  ///
  /// Le fichier cible suit la convention déjà présente dans le projet :
  /// `<nationalDex sur 4 chiffres>-<slug ou id>.json`.
  Future<void> saveSpecies(
    ProjectWorkspace workspace,
    PokemonSpeciesFile species,
  );

  /// Écrit un learnset dans `data/pokemon/learnsets/<speciesId>.json`.
  Future<void> saveLearnset(
    ProjectWorkspace workspace,
    PokemonLearnsetFile learnset,
  );

  /// Écrit une évolution dans `data/pokemon/evolutions/<speciesId>.json`.
  Future<void> saveEvolution(
    ProjectWorkspace workspace,
    PokemonEvolutionFile evolution,
  );

  /// Écrit un média dans `data/pokemon/media/<speciesId>.json`.
  Future<void> saveMedia(
    ProjectWorkspace workspace,
    PokemonMediaFile media,
  );

  /// Écrit un asset binaire Pokémon sous un chemin relatif projet explicite.
  ///
  /// Cette extension reste volontairement minimaliste :
  /// - le use case décide du mapping URL distante -> chemin local ;
  /// - le repository se contente d'écrire les bytes au bon endroit ;
  /// - aucun manifest parallèle n'est créé ici.
  Future<void> saveBinaryAsset(
    ProjectWorkspace workspace, {
    required String relativePath,
    required List<int> bytes,
  });
}

```

### `packages/map_editor/lib/src/application/services/pokeapi_pokemon_species_enricher.dart`

```dart
import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';

/// Enrichit une espèce locale à partir du payload PokeAPI `pokemon-species`.
///
/// Le converter Showdown reste la source structurée pour le core species :
/// stats, abilities, formes, types et ids robustes.
/// Cet enricher complète ensuite ce socle avec les informations encyclopédiques
/// et localisées venant de PokeAPI :
/// - noms localisés ;
/// - génération ;
/// - flavor text ;
/// - egg groups ;
/// - growth rate ;
/// - catch rate ;
/// - base friendship ;
/// - flags baby / legendary / mythical ;
/// - couleur Pokédex.
///
/// Important :
/// - on n'introduit pas un nouveau modèle métier ;
/// - on ne remplace pas Showdown comme source complémentaire ;
/// - on se contente de produire une version enrichie du `PokemonSpeciesFile`
///   déjà existant.
class PokeApiPokemonSpeciesEnricher {
  const PokeApiPokemonSpeciesEnricher();

  PokemonSpeciesFile enrich({
    required PokemonSpeciesFile species,
    required Map<String, dynamic> pokemonSpeciesPayload,
    Map<String, dynamic>? pokemonPayload,
  }) {
    final canonicalId =
        _readOptionalTrimmedString(pokemonSpeciesPayload['name']);
    if (canonicalId == null || canonicalId.isEmpty) {
      throw const EditorPersistenceException(
        'PokeAPI pokemon-species payload must contain a non-empty name',
      );
    }

    final normalizedCanonicalId = _normalizeCatalogId(canonicalId);
    if (normalizedCanonicalId != species.id) {
      throw EditorValidationException(
        'PokeAPI pokemon-species payload resolved to "$normalizedCanonicalId" '
        'but Showdown species resolved to "${species.id}"',
      );
    }

    final localizedNames = _readLocalizedValues(
      pokemonSpeciesPayload['names'],
      field: 'pokemon-species.names',
    );
    final localizedSpeciesNames = _readLocalizedValues(
      pokemonSpeciesPayload['genera'],
      field: 'pokemon-species.genera',
      valueField: 'genus',
    );

    final generationId = _readNamedResourceId(
      pokemonSpeciesPayload['generation'],
      field: 'pokemon-species.generation',
    );
    final generationNumber = _parseGenerationNumber(generationId);

    final eggGroups = _readNamedResourceIdList(
      pokemonSpeciesPayload['egg_groups'],
      field: 'pokemon-species.egg_groups',
    );
    final growthRateId = _readNamedResourceId(
      pokemonSpeciesPayload['growth_rate'],
      field: 'pokemon-species.growth_rate',
    );
    final colorId = _readNamedResourceId(
      pokemonSpeciesPayload['color'],
      field: 'pokemon-species.color',
    );
    final flavorText =
        _readFlavorText(pokemonSpeciesPayload['flavor_text_entries']);

    final baseExp = _readOptionalInt(pokemonPayload?['base_experience']) ??
        species.progression.baseExp;
    final heightM =
        _readOptionalMetricValue(pokemonPayload?['height'], factor: 10) ??
            species.dexContent.heightM;
    final weightKg =
        _readOptionalMetricValue(pokemonPayload?['weight'], factor: 10) ??
            species.dexContent.weightKg;

    return PokemonSpeciesFile(
      id: species.id,
      slug: species.slug,
      nationalDex: species.nationalDex,
      names: localizedNames.isEmpty ? species.names : localizedNames,
      speciesName: localizedSpeciesNames.isEmpty
          ? species.speciesName
          : localizedSpeciesNames,
      genIntroduced: generationNumber ?? species.genIntroduced,
      typing: species.typing,
      baseStats: species.baseStats,
      abilities: species.abilities,
      breeding: PokemonSpeciesBreeding(
        genderRatio: species.breeding.genderRatio,
        eggGroups: eggGroups.isEmpty ? species.breeding.eggGroups : eggGroups,
        hatchCycles: species.breeding.hatchCycles,
      ),
      progression: PokemonSpeciesProgression(
        growthRateId: growthRateId.isEmpty
            ? species.progression.growthRateId
            : growthRateId,
        baseExp: baseExp,
        catchRate: _readOptionalInt(pokemonSpeciesPayload['capture_rate']) ??
            species.progression.catchRate,
        baseFriendship:
            _readOptionalInt(pokemonSpeciesPayload['base_happiness']) ??
                species.progression.baseFriendship,
      ),
      forms: species.forms,
      classification: PokemonSpeciesClassification(
        isEnabledInProject: species.classification.isEnabledInProject,
        isObtainable: species.classification.isObtainable,
        isLegendary: _readBool(pokemonSpeciesPayload['is_legendary']) ||
            species.classification.isLegendary,
        isMythical: _readBool(pokemonSpeciesPayload['is_mythical']) ||
            species.classification.isMythical,
        isBaby: _readBool(pokemonSpeciesPayload['is_baby']) ||
            species.classification.isBaby,
      ),
      refs: species.refs,
      dexContent: PokemonSpeciesDexContent(
        heightM: heightM,
        weightKg: weightKg,
        color: colorId.isEmpty ? species.dexContent.color : colorId,
        flavorText: flavorText ?? species.dexContent.flavorText,
      ),
      gameplayFlags: species.gameplayFlags,
      sourceMeta: PokemonSpeciesSourceMeta(
        seededBy: 'external_api',
        seedVersion: species.sourceMeta.seedVersion,
      ),
    );
  }

  Map<String, String> _readLocalizedValues(
    Object? raw, {
    required String field,
    String valueField = 'name',
  }) {
    if (raw == null) {
      return const <String, String>{};
    }
    if (raw is! List) {
      throw EditorPersistenceException('$field must be a list');
    }

    final values = <String, String>{};
    for (var index = 0; index < raw.length; index++) {
      final entry = raw[index];
      if (entry is! Map) {
        throw EditorPersistenceException('$field[$index] must be an object');
      }

      final normalizedEntry = entry.cast<String, dynamic>();
      final value = _readOptionalTrimmedString(normalizedEntry[valueField]);
      if (value == null || value.isEmpty) {
        continue;
      }
      final languageId = _readNamedResourceId(
        normalizedEntry['language'],
        field: '$field[$index].language',
      );
      if (languageId.isEmpty) {
        continue;
      }
      values[languageId] = _normalizeWhitespace(value);
    }

    return values;
  }

  String? _readFlavorText(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is! List) {
      throw const EditorPersistenceException(
        'pokemon-species.flavor_text_entries must be a list',
      );
    }

    String? fallback;
    for (final preferredLanguage in const <String>['en', 'fr']) {
      for (var index = 0; index < raw.length; index++) {
        final entry = raw[index];
        if (entry is! Map) {
          throw EditorPersistenceException(
            'pokemon-species.flavor_text_entries[$index] must be an object',
          );
        }
        final normalizedEntry = entry.cast<String, dynamic>();
        final languageId = _readNamedResourceId(
          normalizedEntry['language'],
          field: 'pokemon-species.flavor_text_entries[$index].language',
        );
        final flavorText =
            _readOptionalTrimmedString(normalizedEntry['flavor_text']);
        if (flavorText == null || flavorText.isEmpty) {
          continue;
        }
        fallback ??= _normalizeWhitespace(flavorText);
        if (languageId == preferredLanguage) {
          return _normalizeWhitespace(flavorText);
        }
      }
    }

    return fallback;
  }

  List<String> _readNamedResourceIdList(
    Object? raw, {
    required String field,
  }) {
    if (raw == null) {
      return const <String>[];
    }
    if (raw is! List) {
      throw EditorPersistenceException('$field must be a list');
    }

    final values = <String>{};
    for (var index = 0; index < raw.length; index++) {
      values.add(
        _readNamedResourceId(
          raw[index],
          field: '$field[$index]',
        ),
      );
    }
    return values.where((value) => value.isNotEmpty).toList(growable: false);
  }

  String _readNamedResourceId(
    Object? raw, {
    required String field,
  }) {
    if (raw is! Map) {
      throw EditorPersistenceException('$field must be an object');
    }
    final name = _readOptionalTrimmedString(raw['name']);
    if (name == null || name.isEmpty) {
      throw EditorPersistenceException('$field.name cannot be empty');
    }
    return _normalizeCatalogId(name);
  }

  int? _parseGenerationNumber(String generationId) {
    const generationMap = <String, int>{
      'generation-i': 1,
      'generation-ii': 2,
      'generation-iii': 3,
      'generation-iv': 4,
      'generation-v': 5,
      'generation-vi': 6,
      'generation-vii': 7,
      'generation-viii': 8,
      'generation-ix': 9,
    };
    return generationMap[generationId];
  }

  double? _readOptionalMetricValue(
    Object? raw, {
    required double factor,
  }) {
    final value = _readOptionalInt(raw);
    if (value == null) {
      return null;
    }
    return value / factor;
  }

  int? _readOptionalInt(Object? raw) {
    return (raw as num?)?.toInt();
  }

  bool _readBool(Object? raw) {
    return raw == true;
  }

  String _normalizeCatalogId(String raw) {
    return raw.trim().toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
  }

  String? _readOptionalTrimmedString(Object? raw) {
    final value = raw as String?;
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  String _normalizeWhitespace(String value) {
    return value
        .replaceAll('\n', ' ')
        .replaceAll('\f', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

```

### `packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart`

```dart
import 'dart:async';

import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_external_source_repository.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';
import '../services/pokeapi_pokemon_evolution_converter.dart';
import '../services/pokeapi_pokemon_learnset_converter.dart';
import '../services/pokeapi_pokemon_species_enricher.dart';
import '../services/pokemon_media_stub_generator.dart';
import '../services/pokemon_project_data_reader.dart';
import '../services/showdown_pokemon_species_converter.dart';

/// Politique minimale de gestion des fichiers déjà présents dans le workspace.
///
/// On garde exactement trois comportements, parce que c'est le minimum
/// raisonnable demandé pour rendre l'import exploitable sans le transformer en
/// framework de synchronisation :
/// - `failOnConflict` : aucun artefact n'est écrit si au moins une cible existe ;
/// - `skipExisting` : les cibles existantes sont laissées intactes ;
/// - `overwriteExisting` : les cibles existantes sont remplacées explicitement.
enum PokemonExternalImportMergePolicy {
  failOnConflict,
  skipExisting,
  overwriteExisting,
}

/// Type d'artefact local produit par un import externe d'espèce.
///
/// L'ordre de déclaration est aussi l'ordre de reporting utilisé par les
/// résultats, pour garder des sorties lisibles et stables.
enum PokemonExternalImportArtifactKind {
  species,
  learnset,
  evolution,
  media,
}

/// Action retenue pour un artefact donné.
///
/// On reste volontairement sur les quatre états réellement utiles au lot :
/// - créer ;
/// - skip ;
/// - overwrite ;
/// - signaler un conflit.
enum PokemonExternalImportArtifactAction {
  create,
  skip,
  overwrite,
  conflict,
}

/// Résultat détaillé pour un artefact local.
///
/// Chaque artefact expose :
/// - son type ;
/// - le chemin relatif ciblé ;
/// - l'action retenue par la merge policy ;
/// - si un fichier existait déjà ;
/// - un message optionnel si une explication locale aide la review.
class PokemonExternalImportArtifactResult {
  const PokemonExternalImportArtifactResult({
    required this.kind,
    required this.relativePath,
    required this.action,
    required this.existedBefore,
    this.message,
  });

  final PokemonExternalImportArtifactKind kind;
  final String relativePath;
  final PokemonExternalImportArtifactAction action;
  final bool existedBefore;
  final String? message;
}

/// Disponibilité d'un bloc de données avant import.
///
/// Ce modèle sert à la preview applicative :
/// - il reste volontairement lisible pour le wizard ;
/// - il ne confond pas "artefact source trouvé" et "fichier local écrit" ;
/// - il permet de montrer honnêtement les morceaux best-effort.
class PokemonExternalImportPreviewArtifact {
  const PokemonExternalImportPreviewArtifact({
    required this.label,
    required this.isAvailable,
    this.message,
  });

  final String label;
  final bool isAvailable;
  final String? message;
}

/// Preview applicative d'un import externe.
///
/// Cette preview est produite par le `dryRun` du use case existant.
/// On évite ainsi une seconde logique d'aperçu parallèle dans les providers ou
/// dans l'UI.
class PokemonExternalImportPreview {
  const PokemonExternalImportPreview({
    required this.speciesId,
    required this.nationalDex,
    required this.primaryName,
    required this.types,
    required this.learnset,
    required this.evolution,
    required this.media,
    required this.cries,
  });

  final String speciesId;
  final int nationalDex;
  final String primaryName;
  final List<String> types;
  final PokemonExternalImportPreviewArtifact learnset;
  final PokemonExternalImportPreviewArtifact evolution;
  final PokemonExternalImportPreviewArtifact media;
  final PokemonExternalImportPreviewArtifact cries;
}

/// Rapport d'un asset best-effort téléchargé ou tenté.
///
/// Les images et cries n'entrent pas dans la mécanique de conflit bloquante des
/// quatre JSON métier. On les suit donc séparément, avec un résultat plus
/// explicite pour la QA et le report final.
class PokemonExternalAssetDownloadResult {
  const PokemonExternalAssetDownloadResult({
    required this.label,
    required this.relativePath,
    required this.sourceUrl,
    required this.wasWritten,
    this.existedBefore = false,
    this.contentType,
    this.message,
  });

  final String label;
  final String relativePath;
  final String sourceUrl;
  final bool wasWritten;
  final bool existedBefore;
  final String? contentType;
  final String? message;
}

/// Résultat détaillé d'un import externe unitaire.
///
/// Le résultat est pensé pour être lisible directement en logs, tests ou futur
/// rapport d'import :
/// - l'espèce réellement produite ;
/// - la merge policy appliquée ;
/// - l'information dry-run ;
/// - les artefacts concernés ;
/// - d'éventuels warnings non bloquants.
class PokemonExternalImportResult {
  const PokemonExternalImportResult({
    required this.requestedSpeciesId,
    required this.importedSpeciesId,
    required this.preview,
    required this.dryRun,
    required this.mergePolicy,
    required this.artifacts,
    this.downloadedAssets = const <PokemonExternalAssetDownloadResult>[],
    this.warnings = const <String>[],
  });

  final String requestedSpeciesId;
  final String importedSpeciesId;
  final PokemonExternalImportPreview preview;
  final bool dryRun;
  final PokemonExternalImportMergePolicy mergePolicy;
  final List<PokemonExternalImportArtifactResult> artifacts;
  final List<PokemonExternalAssetDownloadResult> downloadedAssets;
  final List<String> warnings;

  bool get hasConflicts => artifacts.any(
        (artifact) =>
            artifact.action == PokemonExternalImportArtifactAction.conflict,
      );

  bool get hasSkips => artifacts.any(
        (artifact) =>
            artifact.action == PokemonExternalImportArtifactAction.skip,
      );

  bool get hasWritesApplied =>
      !dryRun &&
      artifacts.any(
        (artifact) =>
            artifact.action == PokemonExternalImportArtifactAction.create ||
            artifact.action == PokemonExternalImportArtifactAction.overwrite,
      );

  bool get isFullySkipped =>
      artifacts.isNotEmpty &&
      artifacts.every(
        (artifact) =>
            artifact.action == PokemonExternalImportArtifactAction.skip,
      );

  bool get importedSpecies => _hasAppliedArtifact(
        PokemonExternalImportArtifactKind.species,
      );

  bool get importedLearnset => _hasAppliedArtifact(
        PokemonExternalImportArtifactKind.learnset,
      );

  bool get importedEvolution => _hasAppliedArtifact(
        PokemonExternalImportArtifactKind.evolution,
      );

  bool get importedMedia => _hasAppliedArtifact(
        PokemonExternalImportArtifactKind.media,
      );

  int get downloadedAssetCount =>
      downloadedAssets.where((asset) => asset.wasWritten).length;

  bool _hasAppliedArtifact(PokemonExternalImportArtifactKind kind) {
    return artifacts.any(
      (artifact) =>
          artifact.kind == kind &&
          (artifact.action == PokemonExternalImportArtifactAction.create ||
              artifact.action == PokemonExternalImportArtifactAction.overwrite),
    );
  }
}

/// Résultat unitaire ou erreur pour une espèce dans un batch.
///
/// On ne masque pas les erreurs : chaque entrée porte soit un résultat détaillé
/// d'import, soit un message d'erreur lisible. Le batch peut ainsi continuer
/// sans perdre la granularité par espèce.
class PokemonExternalBatchImportEntryResult {
  const PokemonExternalBatchImportEntryResult({
    required this.speciesId,
    this.result,
    this.errorMessage,
  });

  final String speciesId;
  final PokemonExternalImportResult? result;
  final String? errorMessage;

  bool get isFailed => errorMessage != null;

  bool get isConflict => !isFailed && (result?.hasConflicts ?? false);

  bool get isSkipped => !isFailed && (result?.isFullySkipped ?? false);

  bool get isSuccessful => !isFailed && !isConflict;
}

/// Résultat global d'un import batch.
///
/// Le résultat reste volontairement compact :
/// - paramètres communs du batch ;
/// - résultats détaillés par espèce ;
/// - compteurs résumés.
class PokemonExternalBatchImportResult {
  const PokemonExternalBatchImportResult({
    required this.dryRun,
    required this.mergePolicy,
    required this.entries,
  });

  final bool dryRun;
  final PokemonExternalImportMergePolicy mergePolicy;
  final List<PokemonExternalBatchImportEntryResult> entries;

  int get successfulCount =>
      entries.where((entry) => entry.isSuccessful && !entry.isSkipped).length;

  int get skippedCount => entries.where((entry) => entry.isSkipped).length;

  int get conflictCount => entries.where((entry) => entry.isConflict).length;

  int get failedCount => entries.where((entry) => entry.isFailed).length;
}

/// Use case d'orchestration pour importer une seule espèce depuis les sources
/// externes déjà convertibles.
///
/// Ce use case est la couche applicative des lots 34 et 36 :
/// - il récupère les payloads externes via un port minimal ;
/// - il réutilise strictement les convertisseurs 28 à 33 ;
/// - il applique une merge policy simple ;
/// - il supporte un vrai dry-run sans écrire quoi que ce soit ;
/// - il délègue toute écriture réelle au repository local existant.
///
/// Non-objectifs assumés :
/// - pas d'UI ;
/// - pas de réseau concret ;
/// - pas de lot 37+ ;
/// - pas de stratégie de fusion "intelligente" par champ ;
/// - pas de validation croisée globale du Pokédex.
class ImportExternalPokemonSpeciesUseCase {
  ImportExternalPokemonSpeciesUseCase({
    required this.externalSourceRepository,
    required this.writeRepository,
    this.speciesConverter = const ShowdownPokemonSpeciesConverter(),
    this.speciesEnricher = const PokeApiPokemonSpeciesEnricher(),
    this.learnsetConverter = const PokeApiPokemonLearnsetConverter(),
    this.evolutionConverter = const PokeApiPokemonEvolutionConverter(),
    this.mediaStubGenerator = const PokemonMediaStubGenerator(),
    this.dataReader = const PokemonProjectDataReader(),
  });

  final PokemonExternalSourceRepository externalSourceRepository;
  final PokemonWriteRepository writeRepository;
  final ShowdownPokemonSpeciesConverter speciesConverter;
  final PokeApiPokemonSpeciesEnricher speciesEnricher;
  final PokeApiPokemonLearnsetConverter learnsetConverter;
  final PokeApiPokemonEvolutionConverter evolutionConverter;
  final PokemonMediaStubGenerator mediaStubGenerator;
  final PokemonProjectDataReader dataReader;

  Future<PokemonExternalImportResult> execute(
    ProjectWorkspace workspace, {
    required String speciesId,
    PokemonExternalImportMergePolicy mergePolicy =
        PokemonExternalImportMergePolicy.failOnConflict,
    bool dryRun = false,
  }) async {
    final requestedSpeciesId = speciesId.trim();
    if (requestedSpeciesId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon external import speciesId cannot be empty',
      );
    }

    // La stratégie source de la phase 11A est explicite :
    // - `pokemon-species` sert d'abord à résoudre l'identité canonique ;
    // - Showdown complète ensuite le core species structuré ;
    // - `/pokemon` et `evolution-chain` restent best-effort pour le learnset,
    //   les médias et les évolutions locales.
    final pokeApiSpeciesPayload = await externalSourceRepository
        .fetchPokeApiPokemonSpeciesPayload(requestedSpeciesId);
    final canonicalSpeciesId =
        _resolveCanonicalSpeciesIdFromSpeciesPayload(pokeApiSpeciesPayload);
    final showdownPayload = await externalSourceRepository
        .fetchShowdownSpeciesPayload(canonicalSpeciesId);
    final pokemonPayloadRead = await _tryReadOptionalPayload(
      () => externalSourceRepository.fetchPokeApiPokemonPayload(
        canonicalSpeciesId,
      ),
      warningContext:
          'Learnset and media payload unavailable for "$canonicalSpeciesId"',
    );
    final evolutionPayloadRead = await _tryReadOptionalPayload(
      () => externalSourceRepository.fetchPokeApiEvolutionChainPayload(
        canonicalSpeciesId,
      ),
      warningContext: 'Evolution chain unavailable for "$canonicalSpeciesId"',
    );

    final species = speciesEnricher.enrich(
      species: speciesConverter.convert(showdownPayload),
      pokemonSpeciesPayload: pokeApiSpeciesPayload,
      pokemonPayload: pokemonPayloadRead.payload,
    );
    final learnset = await _tryConvertOptional<PokemonLearnsetFile>(
      () => learnsetConverter.convert(
        speciesId: species.id,
        payload: pokemonPayloadRead.payload!,
      ),
      isEnabled: pokemonPayloadRead.payload != null,
      warningContext: 'Learnset conversion skipped for "${species.id}"',
    );
    final evolution = await _tryConvertOptional<PokemonEvolutionFile>(
      () => evolutionConverter.convert(
        speciesId: species.id,
        payload: evolutionPayloadRead.payload!,
      ),
      isEnabled: evolutionPayloadRead.payload != null,
      warningContext: 'Evolution conversion skipped for "${species.id}"',
    );
    final media = mediaStubGenerator.createStub(species);
    final assetCandidates = _resolveAssetCandidates(
      species: species,
      media: media,
      pokemonPayload: pokemonPayloadRead.payload,
    );

    final artifactPlans = await _planArtifacts(
      workspace,
      species: species,
      learnset: learnset,
      evolution: evolution,
      media: media,
      mergePolicy: mergePolicy,
    );

    final warnings = <String>[
      ...pokemonPayloadRead.warnings,
      ...evolutionPayloadRead.warnings,
      ...learnset.warnings,
      ...evolution.warnings,
    ];
    if (species.id != requestedSpeciesId.trim().toLowerCase()) {
      warnings.add(
        'Requested species "$requestedSpeciesId" resolved to '
        '"${species.id}" from source payload.',
      );
    }
    final result = _buildResult(
      requestedSpeciesId: requestedSpeciesId,
      species: species,
      dryRun: dryRun,
      mergePolicy: mergePolicy,
      artifactPlans: artifactPlans,
      warnings: warnings,
      assetCandidates: assetCandidates,
    );

    // Dry-run : tout a été converti et planifié, mais aucune écriture locale
    // n'est autorisée. Le résultat sert alors de rapport d'actions prévues.
    if (dryRun) {
      return result;
    }

    // La politique fail-on-conflict est volontairement atomique au niveau
    // d'une espèce : si un artefact est en conflit, on n'écrit rien pour
    // éviter une importation partielle ambiguë.
    if (result.hasConflicts) {
      return result;
    }

    for (final plan in artifactPlans) {
      switch (plan.action) {
        case PokemonExternalImportArtifactAction.create:
        case PokemonExternalImportArtifactAction.overwrite:
          await plan.write(workspace, writeRepository);
          break;
        case PokemonExternalImportArtifactAction.skip:
        case PokemonExternalImportArtifactAction.conflict:
          break;
      }
    }

    final assetBatch = await _downloadBestEffortAssets(
      workspace,
      mergePolicy: mergePolicy,
      candidates: assetCandidates,
    );

    return _buildResult(
      requestedSpeciesId: requestedSpeciesId,
      species: species,
      dryRun: false,
      mergePolicy: mergePolicy,
      artifactPlans: artifactPlans,
      warnings: <String>[
        ...warnings,
        ...assetBatch.warnings,
      ],
      assetCandidates: assetCandidates,
      downloadedAssets: assetBatch.results,
    );
  }

  Future<List<_PlannedArtifactWrite>> _planArtifacts(
    ProjectWorkspace workspace, {
    required PokemonSpeciesFile species,
    required _OptionalValue<PokemonLearnsetFile> learnset,
    required _OptionalValue<PokemonEvolutionFile> evolution,
    required PokemonMediaFile media,
    required PokemonExternalImportMergePolicy mergePolicy,
  }) async {
    final speciesRelativePath = await _resolveSpeciesRelativePath(
      workspace,
      species,
    );

    return <_PlannedArtifactWrite>[
      await _planArtifact(
        workspace,
        kind: PokemonExternalImportArtifactKind.species,
        relativePath: speciesRelativePath,
        mergePolicy: mergePolicy,
        write: (workspace, repository) =>
            repository.saveSpecies(workspace, species),
      ),
      if (learnset.value != null)
        await _planArtifact(
          workspace,
          kind: PokemonExternalImportArtifactKind.learnset,
          relativePath:
              'data/pokemon/learnsets/${learnset.value!.speciesId}.json',
          mergePolicy: mergePolicy,
          write: (workspace, repository) =>
              repository.saveLearnset(workspace, learnset.value!),
        ),
      if (evolution.value != null)
        await _planArtifact(
          workspace,
          kind: PokemonExternalImportArtifactKind.evolution,
          relativePath:
              'data/pokemon/evolutions/${evolution.value!.speciesId}.json',
          mergePolicy: mergePolicy,
          write: (workspace, repository) =>
              repository.saveEvolution(workspace, evolution.value!),
        ),
      await _planArtifact(
        workspace,
        kind: PokemonExternalImportArtifactKind.media,
        relativePath: 'data/pokemon/media/${media.speciesId}.json',
        mergePolicy: mergePolicy,
        write: (workspace, repository) =>
            repository.saveMedia(workspace, media),
      ),
    ];
  }

  Future<_PlannedArtifactWrite> _planArtifact(
    ProjectWorkspace workspace, {
    required PokemonExternalImportArtifactKind kind,
    required String relativePath,
    required PokemonExternalImportMergePolicy mergePolicy,
    required Future<void> Function(
      ProjectWorkspace workspace,
      PokemonWriteRepository repository,
    ) write,
  }) async {
    final absolutePath = workspace.resolveProjectRelativePath(relativePath);
    final existedBefore = await workspace.fileExists(absolutePath);
    final action = _resolveAction(
      existedBefore: existedBefore,
      mergePolicy: mergePolicy,
    );

    final message = switch (action) {
      PokemonExternalImportArtifactAction.conflict =>
        'Target already exists and merge policy is fail_on_conflict.',
      PokemonExternalImportArtifactAction.skip =>
        'Target already exists and merge policy is skip_existing.',
      PokemonExternalImportArtifactAction.overwrite =>
        'Target already exists and will be overwritten.',
      PokemonExternalImportArtifactAction.create => null,
    };

    return _PlannedArtifactWrite(
      kind: kind,
      relativePath: relativePath,
      existedBefore: existedBefore,
      action: action,
      message: message,
      writeDelegate: write,
    );
  }

  PokemonExternalImportArtifactAction _resolveAction({
    required bool existedBefore,
    required PokemonExternalImportMergePolicy mergePolicy,
  }) {
    if (!existedBefore) {
      return PokemonExternalImportArtifactAction.create;
    }

    return switch (mergePolicy) {
      PokemonExternalImportMergePolicy.failOnConflict =>
        PokemonExternalImportArtifactAction.conflict,
      PokemonExternalImportMergePolicy.skipExisting =>
        PokemonExternalImportArtifactAction.skip,
      PokemonExternalImportMergePolicy.overwriteExisting =>
        PokemonExternalImportArtifactAction.overwrite,
    };
  }

  Future<String> _resolveSpeciesRelativePath(
    ProjectWorkspace workspace,
    PokemonSpeciesFile species,
  ) async {
    // On reste aligné sur le repository d'écriture existant :
    // - si l'espèce existe déjà, on réutilise son vrai chemin courant ;
    // - sinon on génère le nom canonique `<dex>-<slug>.json`.
    final existingRelativePath =
        await dataReader.resolveSpeciesRelativePathById(workspace, species.id);
    if (existingRelativePath != null) {
      return existingRelativePath;
    }

    return 'data/pokemon/species/${_speciesFileName(species)}';
  }

  String _speciesFileName(PokemonSpeciesFile species) {
    final dex = species.nationalDex.toString().padLeft(4, '0');
    final slug = _sanitizeFileSegment(
      species.slug.isNotEmpty ? species.slug : species.id,
    );
    return '$dex-$slug.json';
  }

  String _sanitizeFileSegment(String value) {
    final normalized = value.trim().toLowerCase();
    final safe = normalized.replaceAll(RegExp(r'[^a-z0-9_-]+'), '_');
    final collapsed = safe.replaceAll(RegExp(r'_+'), '_');
    final trimmed = collapsed.replaceAll(RegExp(r'^_|_$'), '');
    return trimmed.isEmpty ? 'pokemon' : trimmed;
  }

  String _resolveCanonicalSpeciesIdFromSpeciesPayload(
    Map<String, dynamic> payload,
  ) {
    final name = payload['name'];
    if (name is! String || name.trim().isEmpty) {
      throw const EditorPersistenceException(
        'PokeAPI pokemon-species payload must expose a non-empty name',
      );
    }
    return name.trim().toLowerCase();
  }

  Future<_OptionalPayload<Map<String, dynamic>>> _tryReadOptionalPayload(
    Future<Map<String, dynamic>> Function() action, {
    required String warningContext,
  }) async {
    try {
      return _OptionalPayload<Map<String, dynamic>>(payload: await action());
    } on EditorApplicationException catch (error) {
      return _OptionalPayload<Map<String, dynamic>>(
        warnings: <String>['$warningContext: ${error.message}'],
      );
    } catch (error) {
      return _OptionalPayload<Map<String, dynamic>>(
        warnings: <String>['$warningContext: $error'],
      );
    }
  }

  Future<_OptionalValue<T>> _tryConvertOptional<T>(
    FutureOr<T> Function() action, {
    required bool isEnabled,
    required String warningContext,
  }) async {
    if (!isEnabled) {
      return _OptionalValue<T>();
    }

    try {
      return _OptionalValue<T>(value: await action());
    } on EditorApplicationException catch (error) {
      return _OptionalValue<T>(
        warnings: <String>['$warningContext: ${error.message}'],
      );
    } catch (error) {
      return _OptionalValue<T>(
        warnings: <String>['$warningContext: $error'],
      );
    }
  }

  PokemonExternalImportResult _buildResult({
    required String requestedSpeciesId,
    required PokemonSpeciesFile species,
    required bool dryRun,
    required PokemonExternalImportMergePolicy mergePolicy,
    required List<_PlannedArtifactWrite> artifactPlans,
    required List<String> warnings,
    required _PokemonExternalAssetCandidateBundle assetCandidates,
    List<PokemonExternalAssetDownloadResult> downloadedAssets =
        const <PokemonExternalAssetDownloadResult>[],
  }) {
    return PokemonExternalImportResult(
      requestedSpeciesId: requestedSpeciesId,
      importedSpeciesId: species.id,
      preview: PokemonExternalImportPreview(
        speciesId: species.id,
        nationalDex: species.nationalDex,
        primaryName: _resolvePrimaryName(species),
        types: _normalizeTypes(species.typing.types),
        learnset: PokemonExternalImportPreviewArtifact(
          label: 'Learnset',
          isAvailable: artifactPlans.any(
            (plan) => plan.kind == PokemonExternalImportArtifactKind.learnset,
          ),
        ),
        evolution: PokemonExternalImportPreviewArtifact(
          label: 'Évolutions',
          isAvailable: artifactPlans.any(
            (plan) => plan.kind == PokemonExternalImportArtifactKind.evolution,
          ),
        ),
        media: PokemonExternalImportPreviewArtifact(
          label: 'Médias',
          isAvailable: assetCandidates.hasMediaSource,
        ),
        cries: PokemonExternalImportPreviewArtifact(
          label: 'Cri',
          isAvailable: assetCandidates.hasCrySource,
        ),
      ),
      dryRun: dryRun,
      mergePolicy: mergePolicy,
      artifacts: artifactPlans
          .map(
            (plan) => PokemonExternalImportArtifactResult(
              kind: plan.kind,
              relativePath: plan.relativePath,
              action: plan.action,
              existedBefore: plan.existedBefore,
              message: plan.message,
            ),
          )
          .toList(growable: false),
      downloadedAssets: downloadedAssets,
      warnings: warnings,
    );
  }

  String _resolvePrimaryName(PokemonSpeciesFile species) {
    final english = species.names['en']?.trim();
    if (english != null && english.isNotEmpty) {
      return english;
    }
    final french = species.names['fr']?.trim();
    if (french != null && french.isNotEmpty) {
      return french;
    }
    for (final value in species.names.values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return species.id;
  }

  List<String> _normalizeTypes(List<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  _PokemonExternalAssetCandidateBundle _resolveAssetCandidates({
    required PokemonSpeciesFile species,
    required PokemonMediaFile media,
    required Map<String, dynamic>? pokemonPayload,
  }) {
    final defaultVariant = media.variants[media.defaultFormId];
    if (defaultVariant == null || pokemonPayload == null) {
      return const _PokemonExternalAssetCandidateBundle();
    }

    final portraitUrl = _readNestedString(
          pokemonPayload,
          const <String>[
            'sprites',
            'other',
            'official-artwork',
            'front_default'
          ],
        ) ??
        _readNestedString(
          pokemonPayload,
          const <String>['sprites', 'other', 'home', 'front_default'],
        ) ??
        _readNestedString(
          pokemonPayload,
          const <String>['sprites', 'front_default'],
        );
    final frontUrl = _readNestedString(
      pokemonPayload,
      const <String>['sprites', 'front_default'],
    );
    final backUrl = _readNestedString(
      pokemonPayload,
      const <String>['sprites', 'back_default'],
    );
    final frontShinyUrl = _readNestedString(
      pokemonPayload,
      const <String>['sprites', 'front_shiny'],
    );
    final backShinyUrl = _readNestedString(
      pokemonPayload,
      const <String>['sprites', 'back_shiny'],
    );
    final cryUrl = _readNestedString(
          pokemonPayload,
          const <String>['cries', 'latest'],
        ) ??
        _readNestedString(
          pokemonPayload,
          const <String>['cries', 'legacy'],
        );

    return _PokemonExternalAssetCandidateBundle(
      candidates: <_PokemonExternalAssetCandidate>[
        if (defaultVariant.portrait?.trim().isNotEmpty == true)
          _PokemonExternalAssetCandidate(
            label: 'Portrait',
            relativePath: defaultVariant.portrait!.trim(),
            sourceUrl: portraitUrl,
          ),
        if (defaultVariant.frontStatic?.trim().isNotEmpty == true)
          _PokemonExternalAssetCandidate(
            label: 'Sprite face',
            relativePath: defaultVariant.frontStatic!.trim(),
            sourceUrl: frontUrl,
          ),
        if (defaultVariant.backStatic?.trim().isNotEmpty == true)
          _PokemonExternalAssetCandidate(
            label: 'Sprite dos',
            relativePath: defaultVariant.backStatic!.trim(),
            sourceUrl: backUrl,
          ),
        if (defaultVariant.frontShinyStatic?.trim().isNotEmpty == true)
          _PokemonExternalAssetCandidate(
            label: 'Sprite shiny face',
            relativePath: defaultVariant.frontShinyStatic!.trim(),
            sourceUrl: frontShinyUrl,
          ),
        if (defaultVariant.backShinyStatic?.trim().isNotEmpty == true)
          _PokemonExternalAssetCandidate(
            label: 'Sprite shiny dos',
            relativePath: defaultVariant.backShinyStatic!.trim(),
            sourceUrl: backShinyUrl,
          ),
        if (defaultVariant.cry?.trim().isNotEmpty == true)
          _PokemonExternalAssetCandidate(
            label: 'Cri',
            relativePath: defaultVariant.cry!.trim(),
            sourceUrl: cryUrl,
          ),
      ],
      speciesId: species.id,
    );
  }

  Future<_DownloadedAssetBatch> _downloadBestEffortAssets(
    ProjectWorkspace workspace, {
    required PokemonExternalImportMergePolicy mergePolicy,
    required _PokemonExternalAssetCandidateBundle candidates,
  }) async {
    final warnings = <String>[];
    final results = <PokemonExternalAssetDownloadResult>[];

    for (final candidate in candidates.candidates) {
      final sourceUrl = candidate.sourceUrl?.trim();
      if (sourceUrl == null || sourceUrl.isEmpty) {
        continue;
      }
      if (_looksLikeGif(sourceUrl)) {
        final message =
            '${candidate.label} ignored because GIF assets are explicitly excluded.';
        warnings.add(message);
        results.add(
          PokemonExternalAssetDownloadResult(
            label: candidate.label,
            relativePath: candidate.relativePath,
            sourceUrl: sourceUrl,
            wasWritten: false,
            message: message,
          ),
        );
        continue;
      }

      final existedBefore = await workspace.fileExists(
        workspace.resolveProjectRelativePath(candidate.relativePath),
      );
      if (existedBefore &&
          mergePolicy != PokemonExternalImportMergePolicy.overwriteExisting) {
        final message =
            '${candidate.label} left untouched because the local asset already exists.';
        results.add(
          PokemonExternalAssetDownloadResult(
            label: candidate.label,
            relativePath: candidate.relativePath,
            sourceUrl: sourceUrl,
            wasWritten: false,
            existedBefore: true,
            message: message,
          ),
        );
        warnings.add(message);
        continue;
      }

      try {
        final asset =
            await externalSourceRepository.fetchBinaryAsset(sourceUrl);
        if (asset.bytes.isEmpty) {
          final message =
              '${candidate.label} download returned no bytes and was skipped.';
          warnings.add(message);
          results.add(
            PokemonExternalAssetDownloadResult(
              label: candidate.label,
              relativePath: candidate.relativePath,
              sourceUrl: sourceUrl,
              wasWritten: false,
              existedBefore: existedBefore,
              contentType: asset.contentType,
              message: message,
            ),
          );
          continue;
        }
        if (_looksLikeGif(asset.sourceUrl) ||
            _isGifContentType(asset.contentType)) {
          final message =
              '${candidate.label} ignored because GIF assets are not allowed in local media.';
          warnings.add(message);
          results.add(
            PokemonExternalAssetDownloadResult(
              label: candidate.label,
              relativePath: candidate.relativePath,
              sourceUrl: sourceUrl,
              wasWritten: false,
              existedBefore: existedBefore,
              contentType: asset.contentType,
              message: message,
            ),
          );
          continue;
        }

        await writeRepository.saveBinaryAsset(
          workspace,
          relativePath: candidate.relativePath,
          bytes: asset.bytes,
        );
        results.add(
          PokemonExternalAssetDownloadResult(
            label: candidate.label,
            relativePath: candidate.relativePath,
            sourceUrl: sourceUrl,
            wasWritten: true,
            existedBefore: existedBefore,
            contentType: asset.contentType,
          ),
        );
      } on EditorApplicationException catch (error) {
        final message = '${candidate.label} download failed: ${error.message}';
        warnings.add(message);
        results.add(
          PokemonExternalAssetDownloadResult(
            label: candidate.label,
            relativePath: candidate.relativePath,
            sourceUrl: sourceUrl,
            wasWritten: false,
            existedBefore: existedBefore,
            message: message,
          ),
        );
      } catch (error) {
        final message = '${candidate.label} download failed: $error';
        warnings.add(message);
        results.add(
          PokemonExternalAssetDownloadResult(
            label: candidate.label,
            relativePath: candidate.relativePath,
            sourceUrl: sourceUrl,
            wasWritten: false,
            existedBefore: existedBefore,
            message: message,
          ),
        );
      }
    }

    return _DownloadedAssetBatch(
      results: results,
      warnings: warnings,
    );
  }

  String? _readNestedString(
    Map<String, dynamic> payload,
    List<String> path,
  ) {
    Object? current = payload;
    for (final segment in path) {
      if (current is! Map) {
        return null;
      }
      current = current[segment];
    }
    final value = current as String?;
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  bool _looksLikeGif(String url) {
    return url.toLowerCase().contains('.gif');
  }

  bool _isGifContentType(String? contentType) {
    final normalized = contentType?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return false;
    }
    return normalized.contains('image/gif');
  }
}

/// Use case batch pour importer plusieurs espèces.
///
/// Ce lot 35 se contente d'enchaîner proprement l'import unitaire :
/// - l'ordre d'exécution est stabilisé ;
/// - chaque espèce garde son résultat détaillé ;
/// - les erreurs par espèce ne cassent pas le reste du batch.
class BatchImportExternalPokemonSpeciesUseCase {
  const BatchImportExternalPokemonSpeciesUseCase(this.singleImportUseCase);

  final ImportExternalPokemonSpeciesUseCase singleImportUseCase;

  Future<PokemonExternalBatchImportResult> execute(
    ProjectWorkspace workspace, {
    required List<String> speciesIds,
    PokemonExternalImportMergePolicy mergePolicy =
        PokemonExternalImportMergePolicy.failOnConflict,
    bool dryRun = false,
  }) async {
    final normalizedSpeciesIds = speciesIds
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort();

    if (normalizedSpeciesIds.isEmpty) {
      throw const EditorValidationException(
        'Pokemon external batch speciesIds cannot be empty',
      );
    }

    final entryResults = <PokemonExternalBatchImportEntryResult>[];
    for (final speciesId in normalizedSpeciesIds) {
      try {
        final result = await singleImportUseCase.execute(
          workspace,
          speciesId: speciesId,
          mergePolicy: mergePolicy,
          dryRun: dryRun,
        );
        entryResults.add(
          PokemonExternalBatchImportEntryResult(
            speciesId: speciesId,
            result: result,
          ),
        );
      } on EditorApplicationException catch (error) {
        entryResults.add(
          PokemonExternalBatchImportEntryResult(
            speciesId: speciesId,
            errorMessage: error.message,
          ),
        );
      } catch (error) {
        entryResults.add(
          PokemonExternalBatchImportEntryResult(
            speciesId: speciesId,
            errorMessage: 'Unexpected batch import error: $error',
          ),
        );
      }
    }

    return PokemonExternalBatchImportResult(
      dryRun: dryRun,
      mergePolicy: mergePolicy,
      entries: entryResults,
    );
  }
}

class _OptionalPayload<T> {
  const _OptionalPayload({
    this.payload,
    this.warnings = const <String>[],
  });

  final T? payload;
  final List<String> warnings;
}

class _OptionalValue<T> {
  const _OptionalValue({
    this.value,
    this.warnings = const <String>[],
  });

  final T? value;
  final List<String> warnings;
}

class _PokemonExternalAssetCandidate {
  const _PokemonExternalAssetCandidate({
    required this.label,
    required this.relativePath,
    required this.sourceUrl,
  });

  final String label;
  final String relativePath;
  final String? sourceUrl;
}

class _PokemonExternalAssetCandidateBundle {
  const _PokemonExternalAssetCandidateBundle({
    this.candidates = const <_PokemonExternalAssetCandidate>[],
    this.speciesId,
  });

  final List<_PokemonExternalAssetCandidate> candidates;
  final String? speciesId;

  bool get hasMediaSource => candidates.any(
        (candidate) =>
            candidate.label != 'Cri' &&
            candidate.sourceUrl?.trim().isNotEmpty == true,
      );

  bool get hasCrySource => candidates.any(
        (candidate) =>
            candidate.label == 'Cri' &&
            candidate.sourceUrl?.trim().isNotEmpty == true,
      );
}

class _DownloadedAssetBatch {
  const _DownloadedAssetBatch({
    required this.results,
    required this.warnings,
  });

  final List<PokemonExternalAssetDownloadResult> results;
  final List<String> warnings;
}

class _PlannedArtifactWrite {
  const _PlannedArtifactWrite({
    required this.kind,
    required this.relativePath,
    required this.existedBefore,
    required this.action,
    required this.writeDelegate,
    this.message,
  });

  final PokemonExternalImportArtifactKind kind;
  final String relativePath;
  final bool existedBefore;
  final PokemonExternalImportArtifactAction action;
  final String? message;
  final Future<void> Function(
    ProjectWorkspace workspace,
    PokemonWriteRepository repository,
  ) writeDelegate;

  Future<void> write(
    ProjectWorkspace workspace,
    PokemonWriteRepository repository,
  ) {
    return writeDelegate(workspace, repository);
  }
}

```

### `packages/map_editor/lib/src/infrastructure/external/pokeapi_live_source.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../application/errors/application_errors.dart';
import '../../application/ports/pokemon_external_source_repository.dart';

/// Adaptateur HTTP concret vers PokeAPI.
///
/// Cette couche reste purement infrastructure :
/// - elle parle HTTP et JSON ;
/// - elle applique une politique réseau sobre avec cache mémoire simple ;
/// - elle ne convertit pas les payloads vers les modèles métier du projet.
///
/// Le use case externe garde ainsi une seule responsabilité :
/// orchestrer l'import Pokémon à partir de payloads déjà décodés.
class PokeApiLiveSource {
  PokeApiLiveSource({
    required http.Client client,
    this.baseUri = const String.fromEnvironment(
      'POKEAPI_BASE_URI',
      defaultValue: 'https://pokeapi.co/api/v2',
    ),
    this.requestTimeout = const Duration(seconds: 20),
    this.userAgent = _defaultUserAgent,
  }) : _client = client;

  static const String _defaultUserAgent =
      'PokeMapEditor/0.1 (+https://pokemap.local)';

  final http.Client _client;
  final String baseUri;
  final Duration requestTimeout;
  final String userAgent;

  final Map<String, Map<String, dynamic>> _pokemonCache =
      <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> _pokemonSpeciesCache =
      <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> _evolutionChainCache =
      <String, Map<String, dynamic>>{};
  final Map<String, PokemonExternalBinaryAsset> _assetCache =
      <String, PokemonExternalBinaryAsset>{};

  /// Lit `/pokemon/{id or name}` avec un cache mémoire par clé normalisée.
  Future<Map<String, dynamic>> fetchPokemon(String speciesId) async {
    final cacheKey = _normalizeKey(speciesId);
    final cached = _pokemonCache[cacheKey];
    if (cached != null) {
      return _deepCopy(cached);
    }

    final payload = await _getJsonObject(
      _resolveApiUri('pokemon/$cacheKey'),
      notFoundMessage:
          'External PokeAPI pokemon payload not found for species "$speciesId"',
      contextLabel: 'PokeAPI pokemon payload',
    );
    _pokemonCache[cacheKey] = payload;
    return _deepCopy(payload);
  }

  /// Lit `/pokemon-species/{id or name}` avec un cache mémoire par clé.
  Future<Map<String, dynamic>> fetchPokemonSpecies(String speciesId) async {
    final cacheKey = _normalizeKey(speciesId);
    final cached = _pokemonSpeciesCache[cacheKey];
    if (cached != null) {
      return _deepCopy(cached);
    }

    final payload = await _getJsonObject(
      _resolveApiUri('pokemon-species/$cacheKey'),
      notFoundMessage:
          'External PokeAPI pokemon-species payload not found for species "$speciesId"',
      contextLabel: 'PokeAPI pokemon-species payload',
    );
    _pokemonSpeciesCache[cacheKey] = payload;

    final canonicalName = _readNamedResourceName(payload['name']);
    if (canonicalName.isNotEmpty) {
      _pokemonSpeciesCache.putIfAbsent(canonicalName, () => payload);
    }

    return _deepCopy(payload);
  }

  /// Lit la chaîne d'évolution en partant d'un payload `pokemon-species`.
  ///
  /// Le lot 11A garde cette étape dans l'adaptateur réseau pour éviter de
  /// remonter des détails d'URL PokeAPI au use case applicatif.
  Future<Map<String, dynamic>> fetchEvolutionChainForSpecies(
    String speciesId,
  ) async {
    final speciesPayload = await fetchPokemonSpecies(speciesId);
    final rawEvolutionChain = speciesPayload['evolution_chain'];
    if (rawEvolutionChain is! Map) {
      throw const EditorPersistenceException(
        'PokeAPI pokemon-species payload must contain an evolution_chain object',
      );
    }

    final evolutionChainUrl = (rawEvolutionChain['url'] as String?)?.trim();
    if (evolutionChainUrl == null || evolutionChainUrl.isEmpty) {
      throw const EditorPersistenceException(
        'PokeAPI pokemon-species payload must contain an evolution chain URL',
      );
    }

    final cached = _evolutionChainCache[evolutionChainUrl];
    if (cached != null) {
      return _deepCopy(cached);
    }

    final payload = await _getJsonObject(
      Uri.parse(evolutionChainUrl),
      notFoundMessage:
          'External PokeAPI evolution chain payload not found for species "$speciesId"',
      contextLabel: 'PokeAPI evolution-chain payload',
    );
    _evolutionChainCache[evolutionChainUrl] = payload;
    return _deepCopy(payload);
  }

  /// Télécharge un asset binaire distant.
  ///
  /// Cette méthode est réutilisée pour les sprites PNG et les cries OGG. Le
  /// cache mémoire évite les doublons pendant une session d'import ou un test.
  Future<PokemonExternalBinaryAsset> fetchBinaryAsset(String sourceUrl) async {
    final normalizedUrl = sourceUrl.trim();
    if (normalizedUrl.isEmpty) {
      throw const EditorValidationException(
        'External asset sourceUrl cannot be empty',
      );
    }

    final cached = _assetCache[normalizedUrl];
    if (cached != null) {
      return cached;
    }

    final response = await _sendRequest(
      Uri.parse(normalizedUrl),
      contextLabel: 'external binary asset',
      notFoundMessage: 'External asset not found: $normalizedUrl',
    );
    final contentType = response.headers['content-type']?.trim();
    final asset = PokemonExternalBinaryAsset(
      sourceUrl: normalizedUrl,
      bytes: Uint8List.fromList(response.bodyBytes),
      contentType: contentType?.isEmpty ?? true ? null : contentType,
    );
    _assetCache[normalizedUrl] = asset;
    return asset;
  }

  Uri _resolveApiUri(String relativePath) {
    final normalizedBase = baseUri.endsWith('/') ? baseUri : '$baseUri/';
    return Uri.parse(normalizedBase).resolve(relativePath);
  }

  Future<Map<String, dynamic>> _getJsonObject(
    Uri uri, {
    required String notFoundMessage,
    required String contextLabel,
  }) async {
    final response = await _sendRequest(
      uri,
      contextLabel: contextLabel,
      notFoundMessage: notFoundMessage,
    );

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException catch (error) {
      throw EditorPersistenceException(
        '$contextLabel is not valid JSON: ${error.message}',
      );
    }

    if (decoded is! Map) {
      throw EditorPersistenceException(
        '$contextLabel must decode to a JSON object',
      );
    }

    return decoded.cast<String, dynamic>();
  }

  Future<http.Response> _sendRequest(
    Uri uri, {
    required String contextLabel,
    required String notFoundMessage,
  }) async {
    final request = http.Request('GET', uri)
      ..headers['accept'] = 'application/json, text/plain, */*'
      ..headers['user-agent'] = userAgent;

    final streamedResponse = await _sendWithTimeout(
      () => _client.send(request),
      contextLabel,
    );
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 404) {
      throw EditorNotFoundException(notFoundMessage);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EditorPersistenceException(
        '$contextLabel request failed with HTTP ${response.statusCode}',
      );
    }

    return response;
  }

  Future<T> _sendWithTimeout<T>(
    Future<T> Function() action,
    String contextLabel,
  ) async {
    try {
      return await action().timeout(requestTimeout);
    } on TimeoutException {
      throw EditorPersistenceException(
        '$contextLabel request timed out after ${requestTimeout.inSeconds}s',
      );
    } on EditorApplicationException {
      rethrow;
    } catch (error) {
      throw EditorPersistenceException(
        '$contextLabel request failed: $error',
      );
    }
  }

  String _normalizeKey(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw const EditorValidationException(
        'External species identifier cannot be empty',
      );
    }
    return trimmed.toLowerCase();
  }

  String _readNamedResourceName(Object? raw) {
    if (raw is String) {
      return raw.trim().toLowerCase();
    }
    if (raw is! Map) {
      return '';
    }
    return (raw['name'] as String?)?.trim().toLowerCase() ?? '';
  }

  Map<String, dynamic> _deepCopy(Map<String, dynamic> source) {
    return jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
  }
}

```

### `packages/map_editor/lib/src/infrastructure/external/showdown_snapshot_source.dart`

```dart
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../application/errors/application_errors.dart';

/// Adaptateur snapshot/data pour Pokémon Showdown.
///
/// L'objectif de cette couche n'est pas d'exposer Showdown comme produit
/// visible dans l'éditeur. Elle sert uniquement d'alimentation complémentaire
/// et structurée pour l'import externe :
/// - `pokedex.json` pour le core species ;
/// - `learnsets.json` et `moves.json` pour les audits et l'extension future ;
/// - aucun parsing Showdown n'est fait dans l'UI.
///
/// Important :
/// - on privilégie les snapshots JSON quand ils existent ;
/// - on garde un cache mémoire simple pour éviter les refetchs ;
/// - on ne vendorise pas de dump tiers massif dans le repo pour cette phase.
class ShowdownSnapshotSource {
  ShowdownSnapshotSource({
    required http.Client client,
    this.baseUri = const String.fromEnvironment(
      'SHOWDOWN_DATA_BASE_URI',
      defaultValue: 'https://play.pokemonshowdown.com/data',
    ),
    this.requestTimeout = const Duration(seconds: 20),
    this.userAgent = _defaultUserAgent,
  }) : _client = client;

  static const String _defaultUserAgent =
      'PokeMapEditor/0.1 (+https://pokemap.local)';

  final http.Client _client;
  final String baseUri;
  final Duration requestTimeout;
  final String userAgent;

  Map<String, dynamic>? _pokedexSnapshot;
  Map<String, dynamic>? _learnsetsSnapshot;
  Map<String, dynamic>? _movesSnapshot;

  /// Extrait une entrée espèce unique depuis le snapshot `pokedex.json`.
  Future<Map<String, dynamic>> fetchSpecies(String speciesId) async {
    final normalizedId = _normalizeIdentifier(speciesId);
    final snapshot = await fetchPokedexSnapshot();
    final rawEntry = snapshot[normalizedId];
    if (rawEntry is! Map) {
      throw EditorNotFoundException(
        'External Showdown species payload not found for species "$speciesId"',
      );
    }

    final entry = rawEntry.cast<String, dynamic>();
    return <String, dynamic>{
      'id': normalizedId,
      ..._deepCopy(entry),
    };
  }

  /// Charge le snapshot Pokédex structuré utilisé par le converter species.
  Future<Map<String, dynamic>> fetchPokedexSnapshot() async {
    _pokedexSnapshot ??= await _getSnapshot(
      'pokedex.json',
      contextLabel: 'Showdown pokedex snapshot',
    );
    return _deepCopy(_pokedexSnapshot!);
  }

  /// Charge le snapshot learnsets pour audit, QA et extension future.
  Future<Map<String, dynamic>> fetchLearnsetsSnapshot() async {
    _learnsetsSnapshot ??= await _getSnapshot(
      'learnsets.json',
      contextLabel: 'Showdown learnsets snapshot',
    );
    return _deepCopy(_learnsetsSnapshot!);
  }

  /// Charge le snapshot moves pour garder la donnée structurée accessible.
  Future<Map<String, dynamic>> fetchMovesSnapshot() async {
    _movesSnapshot ??= await _getSnapshot(
      'moves.json',
      contextLabel: 'Showdown moves snapshot',
    );
    return _deepCopy(_movesSnapshot!);
  }

  Future<Map<String, dynamic>> _getSnapshot(
    String relativePath, {
    required String contextLabel,
  }) async {
    final uri = _resolveUri(relativePath);
    final request = http.Request('GET', uri)
      ..headers['accept'] = 'application/json, text/plain, */*'
      ..headers['user-agent'] = userAgent;

    final streamedResponse = await _sendWithTimeout(
      () => _client.send(request),
      contextLabel,
    );
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 404) {
      throw EditorNotFoundException('$contextLabel not found');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EditorPersistenceException(
        '$contextLabel request failed with HTTP ${response.statusCode}',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException catch (error) {
      throw EditorPersistenceException(
        '$contextLabel is not valid JSON: ${error.message}',
      );
    }

    if (decoded is! Map) {
      throw EditorPersistenceException(
        '$contextLabel must decode to a JSON object',
      );
    }

    return decoded.cast<String, dynamic>();
  }

  Uri _resolveUri(String relativePath) {
    final normalizedBase = baseUri.endsWith('/') ? baseUri : '$baseUri/';
    return Uri.parse(normalizedBase).resolve(relativePath);
  }

  Future<T> _sendWithTimeout<T>(
    Future<T> Function() action,
    String contextLabel,
  ) async {
    try {
      return await action().timeout(requestTimeout);
    } on TimeoutException {
      throw EditorPersistenceException(
        '$contextLabel request timed out after ${requestTimeout.inSeconds}s',
      );
    } on EditorApplicationException {
      rethrow;
    } catch (error) {
      throw EditorPersistenceException(
        '$contextLabel request failed: $error',
      );
    }
  }

  String _normalizeIdentifier(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw const EditorValidationException(
        'Showdown species identifier cannot be empty',
      );
    }
    return normalized;
  }

  Map<String, dynamic> _deepCopy(Map<String, dynamic> source) {
    return jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
  }
}

```

### `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/errors/application_errors.dart';
import '../../application/models/pokemon_database_index.dart';
import '../../application/models/pokemon_project_data_models.dart';
import '../../application/ports/pokemon_read_repository.dart';
import '../../application/ports/pokemon_write_repository.dart';
import '../../application/ports/project_workspace.dart';
import '../../application/services/pokemon_project_data_reader.dart';
import '../../domain/repositories/repositories.dart';

class FileProjectRepository implements ProjectRepository {
  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    debugPrint('FileProjectRepository: Validating and saving project to $path');
    ProjectValidator.validate(project);
    final file = File(path);
    if (!await file.parent.exists()) await file.parent.create(recursive: true);
    final json = project.toJson();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
  }

  @override
  Future<ProjectManifest> loadProject(String path) async {
    debugPrint('FileProjectRepository: Loading project from $path');
    final file = File(path);
    if (!await file.exists()) {
      throw const ProjectLoadException('Project file not found');
    }
    final content = await file.readAsString();
    try {
      final json = migrateProjectManifestJson(
        jsonDecode(content) as Map<String, dynamic>,
      );
      final manifest = ProjectManifest.fromJson(json);
      ProjectValidator.validate(manifest);
      return manifest;
    } catch (e) {
      throw ProjectLoadException('Failed to load project: $e');
    }
  }
}

class FileMapRepository implements MapRepository {
  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) async {
    debugPrint('FileMapRepository: Validating and saving map to $path');
    MapValidator.validate(
      map,
      projectDialogueContext: projectDialogueContext,
    );
    final file = File(path);
    if (!await file.parent.exists()) await file.parent.create(recursive: true);
    final json = map.toJson();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
  }

  @override
  Future<MapData> loadMap(String path) async {
    debugPrint('FileMapRepository: Loading map from $path');
    final file = File(path);
    if (!await file.exists()) {
      throw MapLoadException('Map file not found: $path');
    }
    final content = await file.readAsString();
    try {
      final json = migrateMapDataJson(
        jsonDecode(content) as Map<String, dynamic>,
      );
      final map = MapData.fromJson(json);
      MapValidator.validate(map);
      return map;
    } catch (e) {
      throw MapLoadException('Failed to load map: $e');
    }
  }

  @override
  Future<void> deleteMap(String path) async {
    debugPrint('FileMapRepository: Deleting map at $path');
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> renameMap(String oldPath, String newPath) async {
    debugPrint('FileMapRepository: Renaming map from $oldPath to $newPath');
    final file = File(oldPath);
    if (await file.exists()) {
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      await file.rename(newPath);
    }
  }
}

class FileTilesetRepository implements TilesetRepository {
  @override
  Future<void> saveTileset(TilesetConfig tileset, String path) async {
    final file = File(path);
    if (!await file.parent.exists()) await file.parent.create(recursive: true);
    final json = tileset.toJson();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
  }

  @override
  Future<TilesetConfig> loadTileset(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw const AssetNotFoundException('Tileset file not found');
    }
    final content = await file.readAsString();
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;
      return TilesetConfig.fromJson(json);
    } catch (e) {
      throw const ValidationException('Failed to load tileset');
    }
  }
}

/// Implémentation filesystem/workspace de la lecture locale Pokémon.
///
/// Cette classe sert de frontière infrastructurelle pour les use cases :
/// la mécanique JSON concrète reste déléguée au lecteur local existant.
class FilePokemonReadRepository implements PokemonReadRepository {
  const FilePokemonReadRepository({
    this.reader = const PokemonProjectDataReader(),
  });

  final PokemonProjectDataReader reader;

  @override
  Future<PokemonDataManifest> readManifest(ProjectWorkspace workspace) {
    return reader.readManifest(workspace);
  }

  @override
  Future<PokemonCatalogFile> readCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
  ) {
    return reader.readCatalogByKey(workspace, catalogKey);
  }

  @override
  Future<List<PokemonSpeciesIndexEntry>> listSpeciesIndexEntries(
    ProjectWorkspace workspace,
  ) {
    return reader.listSpeciesIndexEntries(workspace);
  }

  @override
  Future<List<PokemonDatabaseIndexEntry>> listDatabaseIndexEntries(
    ProjectWorkspace workspace, {
    required String speciesDirectoryRelativePath,
  }) {
    return reader.listDatabaseIndexEntries(
      workspace,
      speciesDirectoryRelativePath: speciesDirectoryRelativePath,
    );
  }

  @override
  Future<List<String>> listSpeciesFiles(ProjectWorkspace workspace) {
    return reader.listSpeciesFiles(workspace);
  }

  @override
  Future<PokemonSpeciesFile> readSpeciesByRelativePath(
    ProjectWorkspace workspace,
    String relativePath,
  ) {
    return reader.readSpeciesByRelativePath(workspace, relativePath);
  }

  @override
  Future<PokemonSpeciesFile> readSpeciesById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    return reader.readSpeciesById(workspace, speciesId);
  }

  @override
  Future<PokemonLearnsetFile> readLearnsetById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    return reader.readLearnsetById(workspace, speciesId);
  }

  @override
  Future<List<String>> listLearnsetIds(ProjectWorkspace workspace) {
    return reader.listLearnsetIds(workspace);
  }

  @override
  Future<PokemonEvolutionFile> readEvolutionById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    return reader.readEvolutionById(workspace, speciesId);
  }

  @override
  Future<List<String>> listEvolutionIds(ProjectWorkspace workspace) {
    return reader.listEvolutionIds(workspace);
  }

  @override
  Future<PokemonMediaFile> readMediaById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    return reader.readMediaById(workspace, speciesId);
  }

  @override
  Future<List<String>> listMediaIds(ProjectWorkspace workspace) {
    return reader.listMediaIds(workspace);
  }
}

/// Implémentation filesystem/workspace de l'écriture locale Pokémon.
///
/// Cette classe écrit uniquement les JSON déjà stabilisés à ce stade :
/// - catalogues globaux
/// - espèces
/// - learnsets
/// - évolutions
///
/// Elle ne touche jamais à `project.json` et n'écrit jamais hors du workspace.
class FilePokemonWriteRepository implements PokemonWriteRepository {
  const FilePokemonWriteRepository({
    this.reader = const PokemonProjectDataReader(),
  });

  /// Le repository d'écriture réutilise le lecteur local existant uniquement
  /// pour résoudre le chemin réel d'une espèce déjà présente.
  ///
  /// Cela évite de dupliquer une logique fragile de lookup par id au moment de
  /// l'écriture, tout en gardant la vérité métier côté JSON.
  final PokemonProjectDataReader reader;

  static const Map<String, String> _catalogRelativePaths = <String, String>{
    'moves': 'data/pokemon/catalogs/moves.json',
    'abilities': 'data/pokemon/catalogs/abilities.json',
    'items': 'data/pokemon/catalogs/items.json',
    'types': 'data/pokemon/catalogs/types.json',
    'growth_rates': 'data/pokemon/catalogs/growth_rates.json',
    'natures': 'data/pokemon/catalogs/natures.json',
    'egg_groups': 'data/pokemon/catalogs/egg_groups.json',
    'habitats': 'data/pokemon/catalogs/habitats.json',
    'generations': 'data/pokemon/catalogs/generations.json',
    'version_groups': 'data/pokemon/catalogs/version_groups.json',
    'encounter_rules': 'data/pokemon/catalogs/encounter_rules.json',
  };

  @override
  Future<void> saveCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
    PokemonCatalogFile catalog,
  ) async {
    final trimmedKey = catalogKey.trim();
    final payloadCatalog = catalog.catalog.trim();
    if (payloadCatalog != trimmedKey) {
      throw EditorValidationException(
        'Pokemon catalog key mismatch: requested "$trimmedKey" but payload is '
        '"$payloadCatalog"',
      );
    }
    final relativePath = _catalogRelativePaths[trimmedKey];
    if (relativePath == null) {
      throw EditorNotFoundException(
        'Pokemon catalog write path not declared for key: $catalogKey',
      );
    }
    await _writeJsonObject(workspace, relativePath, catalog.toJson());
  }

  @override
  Future<void> saveSpecies(
    ProjectWorkspace workspace,
    PokemonSpeciesFile species,
  ) async {
    final relativePath = await _resolveSpeciesWritePath(workspace, species);
    await _writeJsonObject(workspace, relativePath, species.toJson());
  }

  @override
  Future<void> saveLearnset(
    ProjectWorkspace workspace,
    PokemonLearnsetFile learnset,
  ) async {
    final speciesId = learnset.speciesId.trim();
    if (speciesId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon learnset speciesId cannot be empty',
      );
    }
    await _writeJsonObject(
      workspace,
      'data/pokemon/learnsets/$speciesId.json',
      learnset.toJson(),
    );
  }

  @override
  Future<void> saveEvolution(
    ProjectWorkspace workspace,
    PokemonEvolutionFile evolution,
  ) async {
    final speciesId = evolution.speciesId.trim();
    if (speciesId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon evolution speciesId cannot be empty',
      );
    }
    await _writeJsonObject(
      workspace,
      'data/pokemon/evolutions/$speciesId.json',
      evolution.toJson(),
    );
  }

  @override
  Future<void> saveMedia(
    ProjectWorkspace workspace,
    PokemonMediaFile media,
  ) async {
    final speciesId = media.speciesId.trim();
    if (speciesId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon media speciesId cannot be empty',
      );
    }
    await _writeJsonObject(
      workspace,
      'data/pokemon/media/$speciesId.json',
      media.toJson(),
    );
  }

  @override
  Future<void> saveBinaryAsset(
    ProjectWorkspace workspace, {
    required String relativePath,
    required List<int> bytes,
  }) async {
    final normalizedRelativePath = relativePath.trim();
    if (normalizedRelativePath.isEmpty) {
      throw const EditorValidationException(
        'Pokemon binary asset relativePath cannot be empty',
      );
    }
    if (bytes.isEmpty) {
      throw const EditorValidationException(
        'Pokemon binary asset bytes cannot be empty',
      );
    }

    final absolutePath =
        workspace.resolveProjectRelativePath(normalizedRelativePath);
    await workspace.ensureDirectoryExists(absolutePath);
    await File(absolutePath).writeAsBytes(bytes, flush: true);
  }

  Future<void> _writeJsonObject(
    ProjectWorkspace workspace,
    String relativePath,
    Map<String, Object?> payload,
  ) async {
    final absolutePath = workspace.resolveProjectRelativePath(relativePath);
    await workspace.ensureDirectoryExists(absolutePath);
    final file = File(absolutePath);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
  }

  Future<String> _resolveSpeciesWritePath(
    ProjectWorkspace workspace,
    PokemonSpeciesFile species,
  ) async {
    final trimmedId = species.id.trim();
    if (trimmedId.isEmpty) {
      throw const EditorValidationException(
          'Pokemon species id cannot be empty');
    }

    final speciesDirectory = Directory(
      workspace.resolveProjectRelativePath('data/pokemon/species'),
    );
    if (!await speciesDirectory.exists()) {
      return 'data/pokemon/species/${_speciesFileName(species)}';
    }

    final existingPath = await reader.resolveSpeciesRelativePathById(
      workspace,
      trimmedId,
    );
    if (existingPath != null) {
      return existingPath;
    }

    return 'data/pokemon/species/${_speciesFileName(species)}';
  }

  String _speciesFileName(PokemonSpeciesFile species) {
    final dex = species.nationalDex.toString().padLeft(4, '0');
    final slug = _sanitizeFileSegment(
        species.slug.isNotEmpty ? species.slug : species.id);
    return '$dex-$slug.json';
  }

  String _sanitizeFileSegment(String value) {
    final normalized = value.trim().toLowerCase();
    final safe = normalized.replaceAll(RegExp(r'[^a-z0-9_-]+'), '_');
    final collapsed = safe.replaceAll(RegExp(r'_+'), '_');
    final trimmed = collapsed.replaceAll(RegExp(r'^_|_$'), '');
    return trimmed.isEmpty ? 'pokemon' : p.basename(trimmed);
  }
}

```

### `packages/map_editor/lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart`

```dart
import '../../application/ports/pokemon_external_source_repository.dart';
import '../external/pokeapi_live_source.dart';
import '../external/showdown_snapshot_source.dart';

/// Implémentation concrète du port externe déjà existant.
///
/// Cette classe est volontairement mince :
/// - elle compose l'adaptateur PokeAPI live et l'adaptateur Showdown snapshot ;
/// - elle ne convertit aucun payload ;
/// - elle expose au use case une façade unique pour éviter toute stack
///   d'import parallèle dans l'application.
class HttpPokemonExternalSourceRepository
    implements PokemonExternalSourceRepository {
  const HttpPokemonExternalSourceRepository({
    required this.pokeApiSource,
    required this.showdownSource,
  });

  final PokeApiLiveSource pokeApiSource;
  final ShowdownSnapshotSource showdownSource;

  @override
  Future<Map<String, dynamic>> fetchShowdownSpeciesPayload(
    String speciesId,
  ) {
    return showdownSource.fetchSpecies(speciesId);
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonPayload(
    String speciesId,
  ) {
    return pokeApiSource.fetchPokemon(speciesId);
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonSpeciesPayload(
    String speciesId,
  ) {
    return pokeApiSource.fetchPokemonSpecies(speciesId);
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiEvolutionChainPayload(
    String speciesId,
  ) {
    return pokeApiSource.fetchEvolutionChainForSpecies(speciesId);
  }

  @override
  Future<PokemonExternalBinaryAsset> fetchBinaryAsset(String sourceUrl) {
    return pokeApiSource.fetchBinaryAsset(sourceUrl);
  }
}

```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart`

```dart
part of 'pokedex_workspace_page.dart';

// Orchestration unique du flow d'import Pokédex.
//
// Cette feuille modale reste volontairement la seule porte d'entrée UI pour
// les imports Pokédex :
// - source locale JSON ;
// - source produit `API externe` ;
// - aperçu avant write ;
// - confirmation finale.
//
// Toute la logique métier reste hors des widgets :
// - l'UI choisit une source et affiche un résumé ;
// - les providers injectés appellent les use cases existants ;
// - aucun parsing JSON ou HTTP ne vit ici.

Future<_CompletedPokedexImportFlowResult?> _showPokedexImportFlowSheet({
  required BuildContext context,
  required ProjectWorkspace workspace,
  required PokedexImportPreviewer previewImport,
  required PokedexImporter importPokemon,
  required PokedexExternalImportPreviewer previewExternalImport,
  required PokedexExternalImporter importExternalPokemon,
  Future<String?> Function()? pickJsonSourceFile,
}) {
  return showMacosEditorTallSheet<_CompletedPokedexImportFlowResult>(
    context: context,
    maxWidth: 760,
    builder: (sheetContext) => _PokedexImportFlowSheet(
      workspace: workspace,
      previewImport: previewImport,
      importPokemon: importPokemon,
      previewExternalImport: previewExternalImport,
      importExternalPokemon: importExternalPokemon,
      pickJsonSourceFile: pickJsonSourceFile ?? _pickPokedexJsonSourceFile,
    ),
  );
}

Future<String?> _pickPokedexJsonSourceFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['json'],
    withData: false,
  );
  final pickedPath = result?.files.single.path;
  if (pickedPath == null) {
    return null;
  }
  await _beginPokedexImportBundleAccessIfNeeded(pickedPath);
  return pickedPath;
}

Future<void> _beginPokedexImportBundleAccessIfNeeded(
    String selectedPath) async {
  if (defaultTargetPlatform != TargetPlatform.macOS) {
    return;
  }
  try {
    await _macOsImportFileAccessChannel.invokeMethod<void>(
      'beginImportBundleAccess',
      <String, String>{'selectedPath': selectedPath},
    );
  } catch (_) {
    // Best effort only.
  }
}

Future<void> _endPokedexImportBundleAccessIfNeeded() async {
  if (defaultTargetPlatform != TargetPlatform.macOS) {
    return;
  }
  try {
    await _macOsImportFileAccessChannel.invokeMethod<void>(
      'endImportBundleAccess',
    );
  } catch (_) {
    // Best effort only.
  }
}

enum _PokedexImportSourceKind {
  jsonLocal,
  externalApi,
}

enum _PokedexImportWizardStep {
  source,
  jsonFile,
  externalQuery,
  preview,
}

class _CompletedPokedexImportFlowResult {
  const _CompletedPokedexImportFlowResult({
    required this.speciesId,
    required this.primaryName,
    required this.importedLearnset,
    required this.importedEvolution,
    required this.importedMedia,
    this.downloadedAssetCount = 0,
  });

  final String speciesId;
  final String primaryName;
  final bool importedLearnset;
  final bool importedEvolution;
  final bool importedMedia;
  final int downloadedAssetCount;
}

// Le wizard reste séquentiel et local à la présentation.
//
// On ne crée pas de route dédiée ni de state container global :
// - un petit état d'écran pour la progression du modal ;
// - des callbacks injectés pour les use cases ;
// - une seule source de vérité métier dans les résultats applicatifs.
class _PokedexImportFlowSheet extends StatefulWidget {
  const _PokedexImportFlowSheet({
    required this.workspace,
    required this.previewImport,
    required this.importPokemon,
    required this.previewExternalImport,
    required this.importExternalPokemon,
    required this.pickJsonSourceFile,
  });

  final ProjectWorkspace workspace;
  final PokedexImportPreviewer previewImport;
  final PokedexImporter importPokemon;
  final PokedexExternalImportPreviewer previewExternalImport;
  final PokedexExternalImporter importExternalPokemon;
  final Future<String?> Function() pickJsonSourceFile;

  @override
  State<_PokedexImportFlowSheet> createState() =>
      _PokedexImportFlowSheetState();
}

class _PokedexImportFlowSheetState extends State<_PokedexImportFlowSheet> {
  _PokedexImportWizardStep _step = _PokedexImportWizardStep.source;
  _PokedexImportSourceKind _selectedSource = _PokedexImportSourceKind.jsonLocal;
  String? _selectedJsonSourcePath;
  PokemonJsonImportPreview? _jsonPreview;
  PokemonExternalImportResult? _externalPreview;
  bool _isBusy = false;
  String? _errorMessage;
  late final TextEditingController _externalQueryController;

  @override
  void initState() {
    super.initState();
    _externalQueryController = TextEditingController();
  }

  @override
  void dispose() {
    _externalQueryController.dispose();
    unawaited(_endPokedexImportBundleAccessIfNeeded());
    super.dispose();
  }

  Future<void> _pickJsonSource() async {
    final pickedPath = await widget.pickJsonSourceFile();
    if (!mounted || pickedPath == null) {
      return;
    }
    setState(() {
      _selectedJsonSourcePath = pickedPath;
      _errorMessage = null;
    });
  }

  Future<void> _loadPreview() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      switch (_selectedSource) {
        case _PokedexImportSourceKind.jsonLocal:
          final sourcePath = _selectedJsonSourcePath?.trim();
          if (sourcePath == null || sourcePath.isEmpty) {
            throw const EditorValidationException(
              'Sélectionnez un fichier JSON à importer.',
            );
          }
          final preview = await widget.previewImport(
            widget.workspace,
            sourcePath,
          );
          if (!mounted) {
            return;
          }
          setState(() {
            _jsonPreview = preview;
            _externalPreview = null;
            _step = _PokedexImportWizardStep.preview;
            _isBusy = false;
          });
          break;
        case _PokedexImportSourceKind.externalApi:
          final speciesQuery = _externalQueryController.text.trim();
          if (speciesQuery.isEmpty) {
            throw const EditorValidationException(
              'Saisissez un nom, un slug ou un numéro Pokédex.',
            );
          }
          final preview = await widget.previewExternalImport(
            widget.workspace,
            speciesQuery,
          );
          if (!mounted) {
            return;
          }
          setState(() {
            _externalPreview = preview;
            _jsonPreview = null;
            _step = _PokedexImportWizardStep.preview;
            _isBusy = false;
          });
          break;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBusy = false;
        _errorMessage = _resolveApplicationMessage(error);
      });
    }
  }

  Future<void> _confirmImport() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      switch (_selectedSource) {
        case _PokedexImportSourceKind.jsonLocal:
          final sourcePath = _selectedJsonSourcePath?.trim();
          if (sourcePath == null || sourcePath.isEmpty) {
            throw const EditorValidationException(
              'Sélectionnez un fichier JSON à importer.',
            );
          }
          final result = await widget.importPokemon(
            widget.workspace,
            sourcePath,
          );
          if (!mounted) {
            return;
          }
          Navigator.of(context).pop(
            _CompletedPokedexImportFlowResult(
              speciesId: result.preview.speciesId,
              primaryName: result.preview.primaryName,
              importedLearnset: result.importedLearnset,
              importedEvolution: result.importedEvolution,
              importedMedia: result.importedMedia,
            ),
          );
          break;
        case _PokedexImportSourceKind.externalApi:
          final speciesQuery = _externalQueryController.text.trim();
          if (speciesQuery.isEmpty) {
            throw const EditorValidationException(
              'Saisissez un nom, un slug ou un numéro Pokédex.',
            );
          }
          final result = await widget.importExternalPokemon(
            widget.workspace,
            speciesQuery,
          );
          if (!mounted) {
            return;
          }
          if (result.hasConflicts) {
            setState(() {
              _isBusy = false;
              _externalPreview = result;
              _errorMessage =
                  'Des fichiers existent déjà pour cette espèce. L’import externe reste volontairement prudent et ne remplace rien dans cette phase.';
            });
            return;
          }
          Navigator.of(context).pop(
            _CompletedPokedexImportFlowResult(
              speciesId: result.preview.speciesId,
              primaryName: result.preview.primaryName,
              importedLearnset: result.importedLearnset,
              importedEvolution: result.importedEvolution,
              importedMedia: result.importedMedia,
              downloadedAssetCount: result.downloadedAssetCount,
            ),
          );
          break;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBusy = false;
        _errorMessage = _resolveApplicationMessage(error);
      });
    }
  }

  String _resolveApplicationMessage(Object error) {
    return switch (error) {
      final EditorApplicationException applicationError =>
        applicationError.message,
      _ => error.toString(),
    };
  }

  void _continueFromSource() {
    setState(() {
      _errorMessage = null;
      _step = switch (_selectedSource) {
        _PokedexImportSourceKind.jsonLocal => _PokedexImportWizardStep.jsonFile,
        _PokedexImportSourceKind.externalApi =>
          _PokedexImportWizardStep.externalQuery,
      };
    });
  }

  void _goBackFromPreview() {
    setState(() {
      _errorMessage = null;
      _step = switch (_selectedSource) {
        _PokedexImportSourceKind.jsonLocal => _PokedexImportWizardStep.jsonFile,
        _PokedexImportSourceKind.externalApi =>
          _PokedexImportWizardStep.externalQuery,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_step) {
      _PokedexImportWizardStep.source => _PokedexImportSourceStep(
          selectedSource: _selectedSource,
          onSourceSelected: (value) {
            setState(() {
              _selectedSource = value;
              _errorMessage = null;
            });
          },
          onContinue: _continueFromSource,
          onCancel: () => Navigator.of(context).pop(),
        ),
      _PokedexImportWizardStep.jsonFile => _PokedexImportJsonFileStep(
          selectedJsonSourcePath: _selectedJsonSourcePath,
          isBusy: _isBusy,
          errorMessage: _errorMessage,
          onPickJsonSource: _pickJsonSource,
          onContinue: _loadPreview,
          onCancel: () => Navigator.of(context).pop(),
        ),
      _PokedexImportWizardStep.externalQuery => _PokedexImportExternalQueryStep(
          controller: _externalQueryController,
          isBusy: _isBusy,
          errorMessage: _errorMessage,
          onContinue: _loadPreview,
          onCancel: () => Navigator.of(context).pop(),
        ),
      _PokedexImportWizardStep.preview => switch (_selectedSource) {
          _PokedexImportSourceKind.jsonLocal => _PokedexImportPreviewStep(
              preview: _jsonPreview!,
              isBusy: _isBusy,
              errorMessage: _errorMessage,
              onBack: _goBackFromPreview,
              onImport: _confirmImport,
            ),
          _PokedexImportSourceKind.externalApi =>
            _PokedexExternalImportPreviewStep(
              preview: _externalPreview!,
              isBusy: _isBusy,
              errorMessage: _errorMessage,
              onBack: _goBackFromPreview,
              onImport: _confirmImport,
            ),
        },
    };
  }
}

```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart`

```dart
part of 'pokedex_workspace_page.dart';

// Étapes visuelles du wizard d'import.
//
// Chaque widget ici reste strictement présentation :
// - aucun accès disque ;
// - aucun accès HTTP ;
// - aucune validation métier ;
// - seulement du wording, de la hiérarchie visuelle et des callbacks.

class _PokedexImportSourceStep extends StatelessWidget {
  const _PokedexImportSourceStep({
    required this.selectedSource,
    required this.onSourceSelected,
    required this.onContinue,
    required this.onCancel,
  });

  final _PokedexImportSourceKind selectedSource;
  final ValueChanged<_PokedexImportSourceKind> onSourceSelected;
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final helperStyle = editorMacosFormLabelStyle(
      context,
    ).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: EditorChrome.subtleLabel(context),
      height: 1.4,
    );

    return Column(
      key: const Key('pokedex-import-source-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Importer des Pokémon',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          'Choisissez la source qui vous convient. Le parcours reste volontairement simple : une source, un aperçu honnête, puis un import dans le projet local.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        Text(
          'Choisir une source',
          style: editorMacosFormLabelStyle(context),
        ),
        const SizedBox(height: 12),
        _PokedexImportSourceCard(
          cardKey: const Key('pokedex-import-json-source-card'),
          title: 'Fichier JSON',
          icon: CupertinoIcons.doc_text_fill,
          isSelected: selectedSource == _PokedexImportSourceKind.jsonLocal,
          onPressed: () => onSourceSelected(_PokedexImportSourceKind.jsonLocal),
        ),
        const SizedBox(height: 10),
        _PokedexImportSourceCard(
          cardKey: const Key('pokedex-import-external-api-source-card'),
          title: 'API externe',
          icon: CupertinoIcons.cloud_fill,
          isSelected: selectedSource == _PokedexImportSourceKind.externalApi,
          trailingLabel: 'Live',
          onPressed: () =>
              onSourceSelected(_PokedexImportSourceKind.externalApi),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: onCancel,
              child: const Text('Annuler'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: const Key('pokedex-import-source-continue-button'),
              controlSize: ControlSize.large,
              onPressed: onContinue,
              child: const Text('Continuer'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PokedexImportJsonFileStep extends StatelessWidget {
  const _PokedexImportJsonFileStep({
    required this.selectedJsonSourcePath,
    required this.isBusy,
    required this.errorMessage,
    required this.onPickJsonSource,
    required this.onContinue,
    required this.onCancel,
  });

  final String? selectedJsonSourcePath;
  final bool isBusy;
  final String? errorMessage;
  final Future<void> Function() onPickJsonSource;
  final Future<void> Function() onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final hasFile = selectedJsonSourcePath?.trim().isNotEmpty == true;
    final helperStyle = editorMacosFormLabelStyle(
      context,
    ).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: subtle,
      height: 1.4,
    );

    return Column(
      key: const Key('pokedex-import-json-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Import depuis fichier JSON',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          'Sélectionnez le fichier espèce à importer. L’aperçu vous montrera ensuite ce qui sera ajouté au projet.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        Text(
          'Choisir un fichier',
          style: editorMacosFormLabelStyle(context),
        ),
        const SizedBox(height: 12),
        CupertinoButton(
          key: const Key('pokedex-import-pick-json-file-button'),
          color: EditorChrome.accentJade.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          onPressed: isBusy ? null : onPickJsonSource,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.folder_open, size: 18),
              SizedBox(width: 8),
              Text('Choisir un fichier'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          key: const Key('pokedex-import-selected-file'),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: EditorChrome.accentWarm.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Text(
            hasFile
                ? p.basename(selectedJsonSourcePath!)
                : 'Aucun fichier sélectionné',
            style: TextStyle(
              color: hasFile ? CupertinoColors.white : subtle,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            key: const Key('pokedex-import-error-message'),
            style: const TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: isBusy ? null : onCancel,
              child: const Text('Annuler'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: const Key('pokedex-import-json-continue-button'),
              controlSize: ControlSize.large,
              onPressed: isBusy ? null : onContinue,
              child: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressCircle(),
                    )
                  : const Text('Continuer'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PokedexImportExternalQueryStep extends StatelessWidget {
  const _PokedexImportExternalQueryStep({
    required this.controller,
    required this.isBusy,
    required this.errorMessage,
    required this.onContinue,
    required this.onCancel,
  });

  final TextEditingController controller;
  final bool isBusy;
  final String? errorMessage;
  final Future<void> Function() onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final helperStyle = editorMacosFormLabelStyle(
      context,
    ).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: EditorChrome.subtleLabel(context),
      height: 1.4,
    );

    return Column(
      key: const Key('pokedex-import-external-query-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Import depuis API externe',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          'Saisissez un nom, un slug ou un numéro Pokédex. L’éditeur préparera un aperçu avant toute écriture dans le projet.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        Text(
          'Pokémon à importer',
          style: editorMacosFormLabelStyle(context),
        ),
        const SizedBox(height: 12),
        CupertinoTextField(
          key: const Key('pokedex-import-external-query-field'),
          controller: controller,
          placeholder: 'Ex. pikachu, bulbasaur ou 25',
          enabled: !isBusy,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        const SizedBox(height: 10),
        Text(
          'La source visible reste “API externe”. Les détails techniques PokeAPI / Showdown restent internes au pipeline.',
          style: helperStyle,
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            key: const Key('pokedex-import-error-message'),
            style: const TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: isBusy ? null : onCancel,
              child: const Text('Annuler'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: const Key('pokedex-import-external-preview-button'),
              controlSize: ControlSize.large,
              onPressed: isBusy ? null : onContinue,
              child: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressCircle(),
                    )
                  : const Text('Prévisualiser'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PokedexImportPreviewStep extends StatelessWidget {
  const _PokedexImportPreviewStep({
    required this.preview,
    required this.isBusy,
    required this.errorMessage,
    required this.onBack,
    required this.onImport,
  });

  final PokemonJsonImportPreview preview;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onBack;
  final Future<void> Function() onImport;

  @override
  Widget build(BuildContext context) {
    final helperStyle = editorMacosFormLabelStyle(
      context,
    ).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: EditorChrome.subtleLabel(context),
      height: 1.4,
    );

    return Column(
      key: const Key('pokedex-import-preview-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Aperçu de l\'import',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          'Vérifiez rapidement l’espèce et les fichiers trouvés avant de lancer l’import.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        DecoratedBox(
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: EditorChrome.accentWarm.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${preview.nationalDex.toString().padLeft(3, '0')} ${preview.primaryName}',
                  key: const Key('pokedex-import-preview-title'),
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Type : ${preview.types.join(' / ')}',
                  key: const Key('pokedex-import-preview-types'),
                  style: TextStyle(
                    color: EditorChrome.subtleLabel(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                _PokedexImportArtifactLine(
                  key: const Key('pokedex-import-preview-learnset-status'),
                  label: preview.learnset.label,
                  isFound: preview.learnset.isFound,
                ),
                const SizedBox(height: 10),
                _PokedexImportArtifactLine(
                  key: const Key('pokedex-import-preview-evolution-status'),
                  label: preview.evolution.label,
                  isFound: preview.evolution.isFound,
                ),
                const SizedBox(height: 10),
                _PokedexImportArtifactLine(
                  key: const Key('pokedex-import-preview-media-status'),
                  label: preview.media.label,
                  isFound: preview.media.isFound,
                ),
              ],
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            key: const Key('pokedex-import-error-message'),
            style: const TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              key: const Key('pokedex-import-preview-back-button'),
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: isBusy ? null : onBack,
              child: const Text('Retour'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: const Key('pokedex-import-confirm-button'),
              controlSize: ControlSize.large,
              onPressed: isBusy ? null : onImport,
              child: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressCircle(),
                    )
                  : const Text('Importer'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PokedexExternalImportPreviewStep extends StatelessWidget {
  const _PokedexExternalImportPreviewStep({
    required this.preview,
    required this.isBusy,
    required this.errorMessage,
    required this.onBack,
    required this.onImport,
  });

  final PokemonExternalImportResult preview;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onBack;
  final Future<void> Function() onImport;

  @override
  Widget build(BuildContext context) {
    final helperStyle = editorMacosFormLabelStyle(
      context,
    ).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: EditorChrome.subtleLabel(context),
      height: 1.4,
    );
    final previewData = preview.preview;

    return Column(
      key: const Key('pokedex-import-external-preview-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Aperçu de l\'import API',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          'Vérifiez l’espèce, les données trouvées et les warnings avant d’ajouter ce Pokémon au projet local.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        DecoratedBox(
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: preview.hasConflicts
                  ? EditorChrome.inspectorJoyCoral
                  : EditorChrome.accentWarm.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${previewData.nationalDex.toString().padLeft(3, '0')} ${previewData.primaryName}',
                  key: const Key('pokedex-import-external-preview-title'),
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Type : ${previewData.types.join(' / ')}',
                  key: const Key('pokedex-import-external-preview-types'),
                  style: TextStyle(
                    color: EditorChrome.subtleLabel(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                _PokedexImportArtifactLine(
                  key: const Key(
                      'pokedex-import-external-preview-learnset-status'),
                  label: previewData.learnset.label,
                  isFound: previewData.learnset.isAvailable,
                ),
                const SizedBox(height: 10),
                _PokedexImportArtifactLine(
                  key: const Key(
                      'pokedex-import-external-preview-evolution-status'),
                  label: previewData.evolution.label,
                  isFound: previewData.evolution.isAvailable,
                ),
                const SizedBox(height: 10),
                _PokedexImportArtifactLine(
                  key:
                      const Key('pokedex-import-external-preview-media-status'),
                  label: previewData.media.label,
                  isFound: previewData.media.isAvailable,
                ),
                const SizedBox(height: 10),
                _PokedexImportArtifactLine(
                  key:
                      const Key('pokedex-import-external-preview-cries-status'),
                  label: previewData.cries.label,
                  isFound: previewData.cries.isAvailable,
                ),
                const SizedBox(height: 16),
                Text(
                  preview.hasConflicts
                      ? 'Politique actuelle : bloquer en cas de conflit'
                      : 'Politique actuelle : import local prudent',
                  style: helperStyle,
                ),
                if (preview.warnings.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  for (final warning in preview.warnings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• $warning',
                        key: Key(
                          'pokedex-import-external-warning-${warning.hashCode}',
                        ),
                        style: const TextStyle(
                          color: EditorChrome.inspectorJoyCoral,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            key: const Key('pokedex-import-error-message'),
            style: const TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              key: const Key('pokedex-import-external-preview-back-button'),
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: isBusy ? null : onBack,
              child: const Text('Retour'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: const Key('pokedex-import-confirm-button'),
              controlSize: ControlSize.large,
              onPressed: isBusy || preview.hasConflicts ? null : onImport,
              child: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressCircle(),
                    )
                  : const Text('Importer'),
            ),
          ],
        ),
      ],
    );
  }
}

```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_support.dart`

```dart
part of 'pokedex_workspace_page.dart';

// Petits widgets réutilisés par le flow d'import.
//
// Ils rendent l'aperçu plus lisible sans introduire une seconde logique de
// preview. Toute la donnée affichée vient déjà du previeweur applicatif.

class _PokedexImportSourceCard extends StatelessWidget {
  const _PokedexImportSourceCard({
    required this.cardKey,
    required this.title,
    required this.icon,
    this.onPressed,
    this.isSelected = false,
    this.trailingLabel,
  });

  final Key cardKey;
  final String title;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isSelected;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final accent = isSelected
        ? EditorChrome.accentJade
        : EditorChrome.accentWarm.withValues(alpha: 0.45);
    final text = isEnabled
        ? EditorChrome.primaryLabel(context)
        : EditorChrome.subtleLabel(context);

    return GestureDetector(
      key: cardKey,
      onTap: isEnabled ? onPressed : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EditorChrome.islandFillElevated(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent, width: isSelected ? 1.2 : 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 18, color: text),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailingLabel != null)
                Text(
                  trailingLabel!,
                  style: TextStyle(
                    color: EditorChrome.subtleLabel(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PokedexImportArtifactLine extends StatelessWidget {
  const _PokedexImportArtifactLine({
    super.key,
    required this.label,
    required this.isFound,
  });

  final String label;
  final bool isFound;

  @override
  Widget build(BuildContext context) {
    final accent = isFound ? EditorChrome.accentJade : EditorChrome.accentWarm;
    final text = EditorChrome.primaryLabel(context);
    final statusLabel = switch (label) {
      'Évolutions' => isFound ? 'Évolutions trouvées' : 'Évolutions manquantes',
      'Médias' => isFound ? 'Médias trouvés' : 'Médias manquants',
      'Cri' => isFound ? 'Cri trouvé' : 'Cri manquant',
      _ when label.endsWith('s') =>
        isFound ? '$label trouvés' : '$label manquants',
      _ => isFound ? '$label trouvé' : '$label manquant',
    };

    return Row(
      children: [
        Icon(
          isFound
              ? CupertinoIcons.check_mark_circled_solid
              : CupertinoIcons.exclamationmark_triangle_fill,
          size: 18,
          color: accent,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            statusLabel,
            style: TextStyle(
              color: text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart`

```dart
part of 'pokedex_workspace_page.dart';

// État principal du workspace.
//
// Cette partie porte seulement l'état d'écran local : recherche, filtres,
// sélection, feedback et chargement de la fiche détail. Elle ne remplace
// aucun provider métier et ne maintient aucun cache parallèle.

class _PokedexWorkspaceBodyState extends State<_PokedexWorkspaceBody> {
  late Future<List<PokemonDatabaseIndexEntry>> _entriesFuture;
  String _searchQuery = '';
  bool _filtersExpanded = false;
  String _selectedType = _allTypesFilterValue;
  String _selectedGeneration = _allGenerationsFilterValue;
  String _selectedStatus = _allStatusesFilterValue;
  String? _selectedSpeciesId;
  Future<PokedexSpeciesDetail>? _detailFuture;
  String _selectedDetailTabId = _overviewTabId;
  String? _feedbackMessage;
  bool _feedbackIsError = false;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _buildEntriesFuture();
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _PokedexWorkspaceBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectRootPath != widget.projectRootPath ||
        oldWidget.loader != widget.loader ||
        oldWidget.detailLoader != widget.detailLoader) {
      _entriesFuture = _buildEntriesFuture();
      // Les raffinements UI des lots 14 et 15 restent purement locaux :
      // quand on change de workspace projet ou de source de chargement, on
      // réinitialise la query et les filtres pour éviter de conserver des
      // critères devenus trompeurs sur une autre liste déjà chargée.
      _searchQuery = '';
      _filtersExpanded = false;
      _selectedType = _allTypesFilterValue;
      _selectedGeneration = _allGenerationsFilterValue;
      _selectedStatus = _allStatusesFilterValue;
      _selectedSpeciesId = null;
      _detailFuture = null;
      _selectedDetailTabId = _overviewTabId;
    }
  }

  Future<List<PokemonDatabaseIndexEntry>> _buildEntriesFuture() {
    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      return Future<List<PokemonDatabaseIndexEntry>>.value(
        const <PokemonDatabaseIndexEntry>[],
      );
    }

    final workspace = ProjectFileSystem(projectRootPath);
    return widget.loader(workspace);
  }

  @override
  Widget build(BuildContext context) {
    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      return const PokedexWorkspaceStateCard(
        title: 'Pokédex',
        message:
            'Chargez un projet pour afficher la liste locale des espèces importées.',
      );
    }

    return FutureBuilder<List<PokemonDatabaseIndexEntry>>(
      future: _entriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const PokedexWorkspaceLoadingState();
        }

        if (snapshot.hasError) {
          return PokedexWorkspaceErrorState(error: snapshot.error);
        }

        final entries = snapshot.data ?? const <PokemonDatabaseIndexEntry>[];
        final availableTypes = _buildAvailableTypes(entries);
        final availableGenerations = _buildAvailableGenerations(entries);
        final workspace = ProjectFileSystem(projectRootPath);

        // Les lots 14 et 15 restent volontairement locaux à la UI :
        // - on ne recharge pas le disque à chaque frappe ou changement de filtre ;
        // - on ne crée pas de provider/notifier Pokédex dédié ;
        // - on filtre simplement la liste déjà chargée en mémoire ;
        // - on conserve l'ordre fourni par l'index local existant.
        final filteredEntries = _filterEntries(entries);
        final selectedEntry = _resolveSelectedEntry(filteredEntries);

        // Décision UX explicite du mini-fix :
        // si la sélection courante n'est plus visible dans la liste filtrée,
        // on vide la fiche détail au lieu de garder un élément "fantôme".
        // Le reset d'état est planifié hors build pour rester propre côté
        // Flutter, mais le rendu revient tout de suite à l'état vide car
        // `selectedEntry` est déjà résolu sur la liste visible.
        _clearSelectionIfInvisible(filteredEntries);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: PokedexWorkspaceSpeciesList(
                entries: filteredEntries,
                selectedSpeciesId: _selectedSpeciesId,
                onEntrySelected: (entry) => _selectEntry(
                  workspace: workspace,
                  entry: entry,
                ),
                onImportRequested: () => _openImportFlow(workspace),
                query: _searchQuery,
                onQueryChanged: _updateSearchQuery,
                filtersExpanded: _filtersExpanded,
                onToggleFiltersExpanded: _toggleFiltersExpanded,
                availableTypes: availableTypes,
                selectedType: _selectedType,
                onTypeChanged: _updateSelectedType,
                availableGenerations: availableGenerations,
                selectedGeneration: _selectedGeneration,
                onGenerationChanged: _updateSelectedGeneration,
                selectedStatus: _selectedStatus,
                onStatusChanged: _updateSelectedStatus,
                feedbackMessage: _feedbackMessage,
                feedbackIsError: _feedbackIsError,
                emptyStateChild: entries.isEmpty
                    ? PokedexWorkspaceImportEmptyState(
                        onImportRequested: () => _openImportFlow(workspace),
                      )
                    : null,
                emptyResultsChild: entries.isNotEmpty && filteredEntries.isEmpty
                    ? PokedexWorkspaceNoResultsState(
                        query: _searchQuery,
                        selectedType: _selectedType == _allTypesFilterValue
                            ? null
                            : _selectedType,
                        selectedGeneration:
                            _selectedGeneration == _allGenerationsFilterValue
                                ? null
                                : _selectedGeneration,
                        selectedStatus:
                            _selectedStatus == _allStatusesFilterValue
                                ? null
                                : _selectedStatus,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 18),
            SizedBox(
              width: 480,
              child: PokedexWorkspaceDetailPane(
                selectedEntry: selectedEntry,
                selectedTabId: _selectedDetailTabId,
                onTabChanged: _updateSelectedDetailTab,
                detailFuture: _detailFuture,
                onSaveMetadata: _saveMetadata,
                onSaveFormsClassification: _saveFormsClassification,
                onSaveLearnset: _saveLearnset,
                onSaveEvolution: _saveEvolution,
                onSaveMedia: _saveMedia,
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateSearchQuery(String value) {
    if (value == _searchQuery) return;
    setState(() => _searchQuery = value);
  }

  void _toggleFiltersExpanded() {
    setState(() => _filtersExpanded = !_filtersExpanded);
  }

  void _updateSelectedType(String value) {
    if (value == _selectedType) return;
    setState(() => _selectedType = value);
  }

  void _updateSelectedGeneration(String value) {
    if (value == _selectedGeneration) return;
    setState(() => _selectedGeneration = value);
  }

  void _updateSelectedStatus(String value) {
    if (value == _selectedStatus) return;
    setState(() => _selectedStatus = value);
  }

  void _updateSelectedDetailTab(String value) {
    if (value == _selectedDetailTabId) return;
    setState(() => _selectedDetailTabId = value);
  }

  void _showFeedback(String message, {required bool isError}) {
    _feedbackTimer?.cancel();
    setState(() {
      _feedbackMessage = message;
      _feedbackIsError = isError;
    });
    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      setState(() => _feedbackMessage = null);
    });
  }

  Future<void> _openImportFlow(ProjectFileSystem workspace) async {
    final result = await _showPokedexImportFlowSheet(
      context: context,
      workspace: workspace,
      previewImport: widget.importPreviewer,
      importPokemon: widget.importer,
      previewExternalImport: widget.externalImportPreviewer,
      importExternalPokemon: widget.externalImporter,
      pickJsonSourceFile: widget.pickJsonImportFile,
    );
    if (!mounted || result == null) {
      return;
    }

    final importedSpeciesId = result.speciesId.trim();
    setState(() {
      _entriesFuture = _buildEntriesFuture();
      _searchQuery = '';
      _filtersExpanded = false;
      _selectedType = _allTypesFilterValue;
      _selectedGeneration = _allGenerationsFilterValue;
      _selectedStatus = _allStatusesFilterValue;
      _selectedSpeciesId = importedSpeciesId;
      _selectedDetailTabId = _overviewTabId;
      _detailFuture = widget.detailLoader(workspace, importedSpeciesId);
    });

    final importedArtifacts = <String>[
      'espèce',
      if (result.importedLearnset) 'learnset',
      if (result.importedEvolution) 'évolutions',
      if (result.importedMedia) 'médias',
    ];
    if (result.downloadedAssetCount > 0) {
      importedArtifacts.add('${result.downloadedAssetCount} assets');
    }
    _showFeedback(
      'Import terminé pour ${result.primaryName} · ${importedArtifacts.join(', ')}',
      isError: false,
    );
  }

  void _selectEntry({
    required ProjectFileSystem workspace,
    required PokemonDatabaseIndexEntry entry,
  }) {
    if (_selectedSpeciesId == entry.id && _detailFuture != null) {
      return;
    }
    setState(() {
      _selectedSpeciesId = entry.id;
      _selectedDetailTabId = _overviewTabId;
      _detailFuture = widget.detailLoader(workspace, entry.id);
    });
  }

  void _clearSelectionIfInvisible(
    List<PokemonDatabaseIndexEntry> visibleEntries,
  ) {
    final selectedId = _selectedSpeciesId;
    if (selectedId == null || selectedId.isEmpty) {
      return;
    }

    final stillVisible = visibleEntries.any((entry) => entry.id == selectedId);
    if (stillVisible) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_selectedSpeciesId != selectedId) return;
      setState(() {
        _selectedSpeciesId = null;
        _detailFuture = null;
        _selectedDetailTabId = _overviewTabId;
      });
    });
  }

  Future<void> _saveMetadata(
    UpdatePokedexSpeciesMetadataRequest request,
  ) async {
    await _runLocalPokemonSave(
      speciesId: request.speciesId,
      saveOperation: (workspace) => widget.metadataSaver(workspace, request),
    );
  }

  Future<void> _saveFormsClassification(
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) async {
    await _runLocalPokemonSave(
      speciesId: request.speciesId,
      saveOperation: (workspace) =>
          widget.formsClassificationSaver(workspace, request),
    );
  }

  Future<void> _saveLearnset(
    UpdatePokedexSpeciesLearnsetRequest request,
  ) async {
    await _runLocalPokemonSave(
      speciesId: request.speciesId,
      saveOperation: (workspace) => widget.learnsetSaver(workspace, request),
    );
  }

  Future<void> _saveEvolution(
    UpdatePokedexSpeciesEvolutionRequest request,
  ) async {
    await _runLocalPokemonSave(
      speciesId: request.speciesId,
      saveOperation: (workspace) => widget.evolutionSaver(workspace, request),
    );
  }

  Future<void> _saveMedia(
    UpdatePokedexSpeciesMediaRequest request,
  ) async {
    await _runLocalPokemonSave(
      speciesId: request.speciesId,
      saveOperation: (workspace) => widget.mediaSaver(workspace, request),
    );
  }

  Future<void> _runLocalPokemonSave({
    required String speciesId,
    required Future<void> Function(ProjectFileSystem workspace) saveOperation,
  }) async {
    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      throw StateError(
        'Cannot save local Pokemon data without a loaded project',
      );
    }

    final workspace = ProjectFileSystem(projectRootPath);
    await saveOperation(workspace);
    if (!mounted) {
      return;
    }

    // Après une sauvegarde locale, on relit la même source de vérité que le
    // reste du workspace :
    // - l'index léger pour la liste et les filtres ;
    // - la fiche détail complète pour l'espèce sélectionnée.
    //
    // On évite ainsi tout cache parallèle "enabled" ou "draft saved" qui
    // pourrait diverger du JSON réellement persisté.
    setState(() {
      _entriesFuture = _buildEntriesFuture();
      if (_selectedSpeciesId == speciesId.trim()) {
        _detailFuture = widget.detailLoader(workspace, speciesId);
      }
    });
  }
}

```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart`

```dart
import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart'
    show
        ControlSize,
        MacosIcon,
        MacosPopupButton,
        MacosPopupMenuItem,
        ProgressCircle,
        PushButton;
import 'package:path/path.dart' as p;

import '../../../app/providers/pokedex_providers.dart';
import '../../../application/errors/application_errors.dart';
import '../../../application/models/pokedex_species_detail.dart';
import '../../../application/models/pokemon_database_index.dart';
import '../../../application/models/pokemon_project_data_models.dart';
import '../../../application/ports/project_workspace.dart';
import '../../../application/use_cases/import_external_pokemon_use_cases.dart';
import '../../../application/use_cases/import_pokemon_json_bundle_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_evolution_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_forms_classification_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_learnset_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_media_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_metadata_use_case.dart';
import '../../../features/editor/state/editor_notifier.dart';
import '../../../infrastructure/filesystem/project_filesystem.dart';
import '../pokedex_workspace_loader.dart';
import '../../shared/cupertino_editor_widgets.dart';

part 'pokedex_workspace_body.dart';
part 'pokedex_workspace_logic.dart';
part 'pokedex_empty_state.dart';
part 'pokedex_feedback_banner.dart';
part 'pokedex_list_panel.dart';
part 'pokedex_toolbar.dart';
part 'pokedex_filters_panel.dart';
part 'pokedex_list_row.dart';
part 'pokedex_import_flow.dart';
part 'pokedex_import_flow_steps.dart';
part 'pokedex_import_flow_support.dart';
part 'pokedex_detail_panel.dart';
part 'pokedex_overview_panel.dart';
part 'pokedex_metadata_editor.dart';
part 'pokedex_metadata_editor_fields.dart';
part 'pokedex_forms_panel.dart';
part 'pokedex_learnset_panel.dart';
part 'pokedex_learnset_sections.dart';
part 'pokedex_evolution_panel.dart';
part 'pokedex_media_panel.dart';
part 'pokedex_common_widgets.dart';
part 'pokedex_formatters.dart';

const String _allTypesFilterValue = '__all_types__';
const String _allGenerationsFilterValue = '__all_generations__';
const String _allStatusesFilterValue = '__all_statuses__';
const String _enabledStatusFilterValue = '__enabled_only__';
const String _overviewTabId = 'overview';
const MethodChannel _macOsImportFileAccessChannel =
    MethodChannel('map_editor/file_access');

// Bibliothèque racine du workspace Pokédex.
//
// Toute la logique métier reste hors de l'UI :
// - les use cases et loaders sont injectés depuis les providers existants ;
// - cette couche orchestre uniquement l'affichage, la sélection locale et les
//   transitions utilisateur du workspace ;
// - le découpage en `part` garde les widgets privés déjà en place tout en
//   rendant l'écran maintenable et lisible pour l'équipe.
/// Workspace central Pokédex du lot 13.
///
/// Le widget public reste volontairement lisible :
/// - il lit le contexte éditeur existant ;
/// - il délègue le chargement par défaut à un helper local dédié ;
/// - il compose les quatre états UI strictement nécessaires.
///
/// On évite ainsi deux extrêmes :
/// - un gros widget fourre-tout mêlant UI et instanciation infra ;
/// - une nouvelle architecture Pokédex "future-ready" disproportionnée.
class PokedexWorkspace extends ConsumerWidget {
  const PokedexWorkspace({
    super.key,
    this.loader,
    this.detailLoader,
    this.importPreviewer,
    this.importer,
    this.externalImportPreviewer,
    this.externalImporter,
    this.pickJsonImportFile,
    this.metadataSaver,
    this.formsClassificationSaver,
    this.learnsetSaver,
    this.evolutionSaver,
    this.mediaSaver,
  });

  /// Injection locale utile aux tests ciblés du lot 13.
  ///
  /// On garde cette extension volontairement minimale : elle permet de tester
  /// le rendu des états UI sans introduire de notifier dédié supplémentaire.
  final PokedexEntryLoader? loader;
  final PokedexSpeciesDetailLoader? detailLoader;
  final PokedexImportPreviewer? importPreviewer;
  final PokedexImporter? importer;
  final PokedexExternalImportPreviewer? externalImportPreviewer;
  final PokedexExternalImporter? externalImporter;
  final Future<String?> Function()? pickJsonImportFile;
  final PokedexSpeciesMetadataSaver? metadataSaver;
  final PokedexSpeciesFormsClassificationSaver? formsClassificationSaver;
  final PokedexSpeciesLearnsetSaver? learnsetSaver;
  final PokedexSpeciesEvolutionSaver? evolutionSaver;
  final PokedexSpeciesMediaSaver? mediaSaver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectRootPath =
        ref.watch(editorNotifierProvider.select((s) => s.projectRootPath));
    final PokedexEntryLoader resolvedLoader =
        loader ?? ref.watch(pokedexEntryLoaderProvider);
    final PokedexSpeciesDetailLoader resolvedDetailLoader =
        detailLoader ?? ref.watch(pokedexSpeciesDetailLoaderProvider);
    final PokedexImportPreviewer resolvedImportPreviewer =
        importPreviewer ?? ref.watch(pokedexImportPreviewerProvider);
    final PokedexImporter resolvedImporter =
        importer ?? ref.watch(pokedexImporterProvider);
    final PokedexExternalImportPreviewer resolvedExternalImportPreviewer =
        externalImportPreviewer ??
            ref.watch(pokedexExternalImportPreviewerProvider);
    final PokedexExternalImporter resolvedExternalImporter =
        externalImporter ?? ref.watch(pokedexExternalImporterProvider);
    final PokedexSpeciesMetadataSaver resolvedMetadataSaver =
        metadataSaver ?? ref.watch(pokedexSpeciesMetadataSaverProvider);
    final PokedexSpeciesFormsClassificationSaver
        resolvedFormsClassificationSaver = formsClassificationSaver ??
            ref.watch(pokedexSpeciesFormsClassificationSaverProvider);
    final PokedexSpeciesLearnsetSaver resolvedLearnsetSaver =
        learnsetSaver ?? ref.watch(pokedexSpeciesLearnsetSaverProvider);
    final PokedexSpeciesEvolutionSaver resolvedEvolutionSaver =
        evolutionSaver ?? ref.watch(pokedexSpeciesEvolutionSaverProvider);
    final PokedexSpeciesMediaSaver resolvedMediaSaver =
        mediaSaver ?? ref.watch(pokedexSpeciesMediaSaverProvider);

    return _PokedexWorkspaceBody(
      projectRootPath: projectRootPath,
      loader: resolvedLoader,
      detailLoader: resolvedDetailLoader,
      importPreviewer: resolvedImportPreviewer,
      importer: resolvedImporter,
      externalImportPreviewer: resolvedExternalImportPreviewer,
      externalImporter: resolvedExternalImporter,
      pickJsonImportFile: pickJsonImportFile,
      metadataSaver: resolvedMetadataSaver,
      formsClassificationSaver: resolvedFormsClassificationSaver,
      learnsetSaver: resolvedLearnsetSaver,
      evolutionSaver: resolvedEvolutionSaver,
      mediaSaver: resolvedMediaSaver,
    );
  }
}

class _PokedexWorkspaceBody extends StatefulWidget {
  const _PokedexWorkspaceBody({
    required this.projectRootPath,
    required this.loader,
    required this.detailLoader,
    required this.importPreviewer,
    required this.importer,
    required this.externalImportPreviewer,
    required this.externalImporter,
    required this.pickJsonImportFile,
    required this.metadataSaver,
    required this.formsClassificationSaver,
    required this.learnsetSaver,
    required this.evolutionSaver,
    required this.mediaSaver,
  });

  final String? projectRootPath;
  final PokedexEntryLoader loader;
  final PokedexSpeciesDetailLoader detailLoader;
  final PokedexImportPreviewer importPreviewer;
  final PokedexImporter importer;
  final PokedexExternalImportPreviewer externalImportPreviewer;
  final PokedexExternalImporter externalImporter;
  final Future<String?> Function()? pickJsonImportFile;
  final PokedexSpeciesMetadataSaver metadataSaver;
  final PokedexSpeciesFormsClassificationSaver formsClassificationSaver;
  final PokedexSpeciesLearnsetSaver learnsetSaver;
  final PokedexSpeciesEvolutionSaver evolutionSaver;
  final PokedexSpeciesMediaSaver mediaSaver;

  @override
  State<_PokedexWorkspaceBody> createState() => _PokedexWorkspaceBodyState();
}

```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart`

```dart
import 'dart:io';

import '../../application/models/pokemon_database_index.dart';
import '../../application/models/pokedex_species_detail.dart';
import '../../application/ports/project_workspace.dart';
import '../../application/use_cases/import_external_pokemon_use_cases.dart';
import '../../application/use_cases/import_pokemon_json_bundle_use_case.dart';
import '../../application/services/pokemon_database_index.dart';
import '../../domain/repositories/repositories.dart';

typedef PokedexEntryLoader = Future<List<PokemonDatabaseIndexEntry>> Function(
  ProjectWorkspace workspace,
);

typedef PokedexSpeciesDetailLoader = Future<PokedexSpeciesDetail> Function(
  ProjectWorkspace workspace,
  String speciesId,
);

typedef PokedexImportPreviewer = Future<PokemonJsonImportPreview> Function(
  ProjectWorkspace workspace,
  String absoluteSpeciesSourcePath,
);

typedef PokedexImporter = Future<PokemonJsonImportResult> Function(
  ProjectWorkspace workspace,
  String absoluteSpeciesSourcePath,
);

typedef PokedexExternalImportPreviewer = Future<PokemonExternalImportResult>
    Function(
  ProjectWorkspace workspace,
  String speciesQuery,
);

typedef PokedexExternalImporter = Future<PokemonExternalImportResult> Function(
  ProjectWorkspace workspace,
  String speciesQuery,
);

/// Construit un chargeur d'entrées Pokédex à partir de dépendances injectées.
///
/// Ce helper reste volontairement petit :
/// - l'UI ne compose plus directement l'infrastructure ;
/// - la logique produit locale du workspace Pokédex reste centralisée ;
/// - les tests peuvent injecter des dépendances concrètes ou fake sans devoir
///   reconstruire tout le wiring applicatif.
///
/// Important :
/// - la logique "species absent => liste vide" est traitée ici de façon
///   explicite, avant l'appel au service ;
/// - on ne dépend donc plus d'un `contains(...)` sur le message d'une
///   exception ;
/// - le service applicatif d'indexation garde sa responsabilité actuelle ;
/// - ce helper ne fait que l'adapter au besoin UI local.
PokedexEntryLoader createPokedexEntryLoader({
  required ProjectRepository projectRepository,
  required PokemonDatabaseIndex databaseIndex,
}) {
  return (ProjectWorkspace workspace) async {
    final project =
        await projectRepository.loadProject(workspace.projectManifestPath);
    final speciesDirectoryRelativePath = project.pokemon.speciesDir.trim();

    // On garde volontairement la validation "speciesDir vide" au niveau du
    // service du lot 11. Ici, on ne pré-traite qu'un seul cas produit très
    // précis du lot 13 : un dossier `species/` simplement absent dans un
    // projet encore vide doit rendre un état vide honnête, pas une erreur
    // technique.
    if (speciesDirectoryRelativePath.isNotEmpty) {
      final speciesDirectoryPath = workspace.resolveProjectRelativePath(
        speciesDirectoryRelativePath,
      );
      if (!await Directory(speciesDirectoryPath).exists()) {
        return const <PokemonDatabaseIndexEntry>[];
      }
    }

    return databaseIndex.build(workspace);
  };
}

```

### `packages/map_editor/test/http_pokemon_external_source_repository_test.dart`

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:map_editor/src/infrastructure/external/pokeapi_live_source.dart';
import 'package:map_editor/src/infrastructure/external/showdown_snapshot_source.dart';
import 'package:map_editor/src/infrastructure/repositories/http_pokemon_external_source_repository.dart';

void main() {
  test('HttpPokemonExternalSourceRepository composes Showdown and PokeAPI',
      () async {
    final client = MockClient((request) async {
      if (request.url.toString() == 'https://showdown.test/data/pokedex.json') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'bulbasaur': <String, Object?>{
              'name': 'Bulbasaur',
              'num': 1,
              'types': <String>['Grass', 'Poison'],
            },
          }),
          200,
          headers: const <String, String>{
            'content-type': 'application/json',
          },
        );
      }
      if (request.url.toString() ==
          'https://pokeapi.test/api/v2/pokemon-species/bulbasaur') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'name': 'bulbasaur',
            'evolution_chain': <String, Object?>{
              'url': 'https://pokeapi.test/api/v2/evolution-chain/1/',
            },
          }),
          200,
          headers: const <String, String>{
            'content-type': 'application/json',
          },
        );
      }
      if (request.url.toString() ==
          'https://pokeapi.test/api/v2/pokemon/bulbasaur') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'name': 'bulbasaur',
            'moves': <Object?>[],
          }),
          200,
          headers: const <String, String>{
            'content-type': 'application/json',
          },
        );
      }
      if (request.url.toString() ==
          'https://pokeapi.test/api/v2/evolution-chain/1/') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'chain': <String, Object?>{
              'species': <String, Object?>{'name': 'bulbasaur'},
              'evolves_to': <Object?>[],
            },
          }),
          200,
          headers: const <String, String>{
            'content-type': 'application/json',
          },
        );
      }
      if (request.url.toString() == 'https://assets.test/front.png') {
        return http.Response.bytes(
          <int>[1, 2, 3, 4],
          200,
          headers: const <String, String>{
            'content-type': 'image/png',
          },
        );
      }
      return http.Response('not found', 404);
    });

    final repository = HttpPokemonExternalSourceRepository(
      pokeApiSource: PokeApiLiveSource(
        client: client,
        baseUri: 'https://pokeapi.test/api/v2',
      ),
      showdownSource: ShowdownSnapshotSource(
        client: client,
        baseUri: 'https://showdown.test/data',
      ),
    );

    final showdown = await repository.fetchShowdownSpeciesPayload('bulbasaur');
    final pokemon = await repository.fetchPokeApiPokemonPayload('bulbasaur');
    final pokemonSpecies =
        await repository.fetchPokeApiPokemonSpeciesPayload('bulbasaur');
    final evolution =
        await repository.fetchPokeApiEvolutionChainPayload('bulbasaur');
    final asset = await repository.fetchBinaryAsset(
      'https://assets.test/front.png',
    );

    expect(showdown['name'], 'Bulbasaur');
    expect(pokemon['name'], 'bulbasaur');
    expect(pokemonSpecies['name'], 'bulbasaur');
    expect(
      ((evolution['chain'] as Map<String, dynamic>)['species']
          as Map<String, dynamic>)['name'],
      'bulbasaur',
    );
    expect(asset.contentType, 'image/png');
  });
}

```

### `packages/map_editor/test/import_external_pokemon_use_cases_test.dart`

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/pokemon_external_source_repository.dart';
import 'package:map_editor/src/application/services/pokeapi_pokemon_learnset_converter.dart';
import 'package:map_editor/src/application/services/showdown_pokemon_species_converter.dart';
import 'package:map_editor/src/application/use_cases/import_external_pokemon_use_cases.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late ImportExternalPokemonSpeciesUseCase singleUseCase;
  late BatchImportExternalPokemonSpeciesUseCase batchUseCase;
  late _FakePokemonExternalSourceRepository externalSourceRepository;
  late FilePokemonReadRepository readRepository;
  late FilePokemonWriteRepository writeRepository;
  late File projectFile;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp(
      'pokemon_external_import_project_',
    );
    workspace = ProjectFileSystem(tempProjectRoot.path);
    externalSourceRepository = _FakePokemonExternalSourceRepository(
      showdownSpeciesPayloads: <String, Map<String, dynamic>>{
        'bulbasaur':
            jsonDecode(_bulbasaurShowdownPayload) as Map<String, dynamic>,
        'ivysaur': jsonDecode(_ivysaurShowdownPayload) as Map<String, dynamic>,
      },
      pokeApiPokemonSpeciesPayloads: <String, Map<String, dynamic>>{
        '1':
            jsonDecode(_bulbasaurPokemonSpeciesPayload) as Map<String, dynamic>,
        'bulbasaur':
            jsonDecode(_bulbasaurPokemonSpeciesPayload) as Map<String, dynamic>,
        '2': jsonDecode(_ivysaurPokemonSpeciesPayload) as Map<String, dynamic>,
        'ivysaur':
            jsonDecode(_ivysaurPokemonSpeciesPayload) as Map<String, dynamic>,
      },
      pokeApiPokemonPayloads: <String, Map<String, dynamic>>{
        'bulbasaur':
            jsonDecode(_bulbasaurPokemonPayload) as Map<String, dynamic>,
        'ivysaur': jsonDecode(_ivysaurPokemonPayload) as Map<String, dynamic>,
      },
      pokeApiEvolutionChainPayloads: <String, Map<String, dynamic>>{
        'bulbasaur':
            jsonDecode(_bulbasaurEvolutionChainPayload) as Map<String, dynamic>,
        'ivysaur':
            jsonDecode(_bulbasaurEvolutionChainPayload) as Map<String, dynamic>,
      },
      binaryAssets: <String, PokemonExternalBinaryAsset>{
        'https://assets.example.test/bulbasaur/portrait.png':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/portrait.png',
          bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
          contentType: 'image/png',
        ),
        'https://assets.example.test/bulbasaur/front.png':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/front.png',
          bytes: Uint8List.fromList(<int>[5, 6, 7, 8]),
          contentType: 'image/png',
        ),
        'https://assets.example.test/bulbasaur/back.png':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/back.png',
          bytes: Uint8List.fromList(<int>[9, 10, 11, 12]),
          contentType: 'image/png',
        ),
        'https://assets.example.test/bulbasaur/front_shiny.png':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/front_shiny.png',
          bytes: Uint8List.fromList(<int>[13, 14, 15, 16]),
          contentType: 'image/png',
        ),
        'https://assets.example.test/bulbasaur/back_shiny.png':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/back_shiny.png',
          bytes: Uint8List.fromList(<int>[17, 18, 19, 20]),
          contentType: 'image/png',
        ),
        'https://assets.example.test/bulbasaur/cry.ogg':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/cry.ogg',
          bytes: Uint8List.fromList(<int>[21, 22, 23, 24]),
          contentType: 'audio/ogg',
        ),
      },
    );
    writeRepository = const FilePokemonWriteRepository();
    readRepository = const FilePokemonReadRepository();
    singleUseCase = ImportExternalPokemonSpeciesUseCase(
      externalSourceRepository: externalSourceRepository,
      writeRepository: writeRepository,
    );
    batchUseCase = BatchImportExternalPokemonSpeciesUseCase(singleUseCase);

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Pokemon External Import Project',
      tempProjectRoot.path,
    );
    await const InitializePokemonProjectStorageUseCase().execute(workspace);
    projectFile = File(workspace.projectManifestPath);
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('ImportExternalPokemonSpeciesUseCase', () {
    test('imports one species from external payloads into local storage',
        () async {
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(workspace, speciesId: '1');

      expect(result.importedSpeciesId, 'bulbasaur');
      expect(result.dryRun, isFalse);
      expect(result.hasConflicts, isFalse);
      expect(result.preview.primaryName, 'Bulbasaur');
      expect(result.preview.cries.isAvailable, isTrue);
      expect(result.downloadedAssetCount, 6);
      expect(
        result.artifacts.map((artifact) => artifact.action).toList(),
        <PokemonExternalImportArtifactAction>[
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
        ],
      );

      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/0001-bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/learnsets/bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/evolutions/bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/media/bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );

      final species =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');
      final learnset =
          await readRepository.readLearnsetById(workspace, 'bulbasaur');
      final evolution =
          await readRepository.readEvolutionById(workspace, 'bulbasaur');
      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(species.typing.types, <String>['grass', 'poison']);
      expect(learnset.tm.single.moveId, 'solar_beam');
      expect(evolution.evolutions.single.targetSpeciesId, 'ivysaur');
      expect(
        media.variants['base']?.portrait,
        'assets/pokemon/portraits/bulbasaur.png',
      );
      expect(species.names['fr'], 'Bulbizarre');
      expect(species.progression.growthRateId, 'medium_slow');
      expect(species.progression.baseFriendship, 50);
      expect(species.dexContent.color, 'green');
      expect(species.dexContent.flavorText,
          'A strange seed was planted on its back at birth.');
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isTrue,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/cries/bulbasaur.ogg',
          ),
        ).exists(),
        isTrue,
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('dry-run resolves everything but writes nothing', () async {
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
        dryRun: true,
      );

      expect(result.dryRun, isTrue);
      expect(result.hasWritesApplied, isFalse);
      expect(result.downloadedAssetCount, 0);
      expect(
        result.artifacts.map((artifact) => artifact.action).toList(),
        <PokemonExternalImportArtifactAction>[
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
        ],
      );

      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/0001-bulbasaur.json',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('fail_on_conflict reports conflicts and writes nothing', () async {
      await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
      );

      expect(result.hasConflicts, isTrue);
      expect(result.hasWritesApplied, isFalse);
      expect(
        result.artifacts.map((artifact) => artifact.action).toList(),
        <PokemonExternalImportArtifactAction>[
          PokemonExternalImportArtifactAction.conflict,
          PokemonExternalImportArtifactAction.conflict,
          PokemonExternalImportArtifactAction.conflict,
          PokemonExternalImportArtifactAction.conflict,
        ],
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'skip_existing skips files already present and still writes missing ones',
        () async {
      await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        dryRun: true,
      );
      await writeRepository.saveSpecies(
        workspace,
        const ShowdownPokemonSpeciesConverter().convert(
          jsonDecode(_bulbasaurShowdownPayload) as Map<String, dynamic>,
        ),
      );
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.skipExisting,
      );

      expect(
        result.artifacts.map((artifact) => artifact.action).toList(),
        <PokemonExternalImportArtifactAction>[
          PokemonExternalImportArtifactAction.skip,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
        ],
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('overwrite_existing replaces an existing artefact', () async {
      await writeRepository.saveLearnset(
        workspace,
        const PokeApiPokemonLearnsetConverter().convert(
          speciesId: 'bulbasaur',
          payload: jsonDecode(_legacyBulbasaurPokemonPayload)
              as Map<String, dynamic>,
        ),
      );
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
      );

      final learnset =
          await readRepository.readLearnsetById(workspace, 'bulbasaur');

      expect(
        result.artifacts
            .firstWhere(
              (artifact) =>
                  artifact.kind == PokemonExternalImportArtifactKind.learnset,
            )
            .action,
        PokemonExternalImportArtifactAction.overwrite,
      );
      expect(learnset.tm.single.moveId, 'solar_beam');
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'overwrite_existing reuses an existing non-canonical species path '
        'without creating a duplicate canonical file', () async {
      await writeRepository.saveSpecies(
        workspace,
        _customSlugBulbasaurSpecies,
      );
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
      );

      final speciesArtifact = result.artifacts.firstWhere(
        (artifact) =>
            artifact.kind == PokemonExternalImportArtifactKind.species,
      );
      final customFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbizarre-custom.json',
        ),
      );
      final canonicalFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      final species =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');

      expect(speciesArtifact.action,
          PokemonExternalImportArtifactAction.overwrite);
      expect(
        speciesArtifact.relativePath,
        'data/pokemon/species/0001-bulbizarre-custom.json',
      );
      expect(await customFile.exists(), isTrue);
      expect(await canonicalFile.exists(), isFalse);
      expect(species.slug, 'bulbasaur');
      expect(species.names['en'], 'Bulbasaur');
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'overwrite_existing ignores a misleading basename with another json id',
        () async {
      await writeRepository.saveSpecies(
        workspace,
        _customSlugBulbasaurSpecies,
      );

      final misleadingFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/9999-bulbasaur.json',
        ),
      );
      await misleadingFile.parent.create(recursive: true);
      final misleadingJson = _customSlugBulbasaurSpecies.toJson()
        ..['id'] = 'something_else'
        ..['slug'] = 'something-else';
      await misleadingFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(misleadingJson),
      );
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
      );

      final speciesArtifact = result.artifacts.firstWhere(
        (artifact) =>
            artifact.kind == PokemonExternalImportArtifactKind.species,
      );
      final customFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbizarre-custom.json',
        ),
      );
      final canonicalFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      final species =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');

      expect(speciesArtifact.action,
          PokemonExternalImportArtifactAction.overwrite);
      expect(
        speciesArtifact.relativePath,
        'data/pokemon/species/0001-bulbizarre-custom.json',
      );
      expect(await customFile.exists(), isTrue);
      expect(await canonicalFile.exists(), isFalse);
      expect(await misleadingFile.exists(), isTrue);
      expect(species.slug, 'bulbasaur');
      expect(species.names['en'], 'Bulbasaur');
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('surfaces external source errors clearly', () async {
      externalSourceRepository.pokeApiPokemonSpeciesPayloads
          .remove('bulbasaur');

      await expectLater(
        () => singleUseCase.execute(
          workspace,
          speciesId: 'bulbasaur',
        ),
        throwsA(
          isA<EditorNotFoundException>().having(
            (error) => error.message,
            'message',
            'External PokeAPI pokemon-species payload not found for species "bulbasaur"',
          ),
        ),
      );
    });

    test('continues when optional pokemon payload is unavailable', () async {
      externalSourceRepository.pokeApiPokemonPayloads.remove('bulbasaur');

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      expect(result.hasConflicts, isFalse);
      expect(result.importedSpecies, isTrue);
      expect(result.importedLearnset, isFalse);
      expect(result.importedEvolution, isTrue);
      expect(result.importedMedia, isTrue);
      expect(result.preview.learnset.isAvailable, isFalse);
      expect(result.preview.media.isAvailable, isFalse);
      expect(result.preview.cries.isAvailable, isFalse);
      expect(
        result.warnings.join('\n'),
        contains('Learnset and media payload unavailable for "bulbasaur"'),
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/0001-bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/learnsets/bulbasaur.json',
          ),
        ).exists(),
        isFalse,
      );
    });
  });

  group('BatchImportExternalPokemonSpeciesUseCase', () {
    test('imports a batch successfully with deterministic ordering', () async {
      final beforeProjectJson = await projectFile.readAsString();

      final result = await batchUseCase.execute(
        workspace,
        speciesIds: <String>['ivysaur', 'bulbasaur', 'ivysaur'],
      );

      expect(
        result.entries.map((entry) => entry.speciesId).toList(),
        <String>['bulbasaur', 'ivysaur'],
      );
      expect(result.successfulCount, 2);
      expect(result.failedCount, 0);
      expect(result.conflictCount, 0);
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('continues on partial failures and reports them by species', () async {
      externalSourceRepository.showdownSpeciesPayloads.remove('ivysaur');

      final result = await batchUseCase.execute(
        workspace,
        speciesIds: <String>['bulbasaur', 'ivysaur'],
      );

      expect(result.successfulCount, 1);
      expect(result.failedCount, 1);
      expect(
        result.entries
            .firstWhere((entry) => entry.speciesId == 'ivysaur')
            .errorMessage,
        'External Showdown species payload not found for species "ivysaur"',
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/0001-bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );
    });
  });
}

class _FakePokemonExternalSourceRepository
    implements PokemonExternalSourceRepository {
  _FakePokemonExternalSourceRepository({
    required this.showdownSpeciesPayloads,
    required this.pokeApiPokemonSpeciesPayloads,
    required this.pokeApiPokemonPayloads,
    required this.pokeApiEvolutionChainPayloads,
    required this.binaryAssets,
  });

  final Map<String, Map<String, dynamic>> showdownSpeciesPayloads;
  final Map<String, Map<String, dynamic>> pokeApiPokemonSpeciesPayloads;
  final Map<String, Map<String, dynamic>> pokeApiPokemonPayloads;
  final Map<String, Map<String, dynamic>> pokeApiEvolutionChainPayloads;
  final Map<String, PokemonExternalBinaryAsset> binaryAssets;

  @override
  Future<Map<String, dynamic>> fetchPokeApiEvolutionChainPayload(
    String speciesId,
  ) async {
    final payload = pokeApiEvolutionChainPayloads[speciesId];
    if (payload == null) {
      throw EditorNotFoundException(
        'External PokeAPI evolution chain payload not found for species '
        '"$speciesId"',
      );
    }
    return _deepCopy(payload);
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonPayload(
    String speciesId,
  ) async {
    final payload = pokeApiPokemonPayloads[speciesId];
    if (payload == null) {
      throw EditorNotFoundException(
        'External PokeAPI pokemon payload not found for species "$speciesId"',
      );
    }
    return _deepCopy(payload);
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonSpeciesPayload(
    String speciesId,
  ) async {
    final payload = pokeApiPokemonSpeciesPayloads[speciesId];
    if (payload == null) {
      throw EditorNotFoundException(
        'External PokeAPI pokemon-species payload not found for species "$speciesId"',
      );
    }
    return _deepCopy(payload);
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownSpeciesPayload(
    String speciesId,
  ) async {
    final payload = showdownSpeciesPayloads[speciesId];
    if (payload == null) {
      throw EditorNotFoundException(
        'External Showdown species payload not found for species "$speciesId"',
      );
    }
    return _deepCopy(payload);
  }

  @override
  Future<PokemonExternalBinaryAsset> fetchBinaryAsset(String sourceUrl) async {
    final asset = binaryAssets[sourceUrl];
    if (asset == null) {
      throw EditorNotFoundException('External asset not found: $sourceUrl');
    }
    return PokemonExternalBinaryAsset(
      sourceUrl: asset.sourceUrl,
      bytes: Uint8List.fromList(asset.bytes),
      contentType: asset.contentType,
    );
  }

  Map<String, dynamic> _deepCopy(Map<String, dynamic> source) {
    return jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
  }
}

const String _bulbasaurShowdownPayload = '''
{
  "name": "Bulbasaur",
  "num": 1,
  "gen": 1,
  "types": ["Grass", "Poison"],
  "baseStats": {
    "hp": 45,
    "atk": 49,
    "def": 49,
    "spa": 65,
    "spd": 65,
    "spe": 45
  },
  "abilities": {
    "0": "Overgrow",
    "H": "Chlorophyll"
  },
  "eggGroups": ["Monster", "Grass"],
  "expType": "Medium Slow",
  "baseExp": 64,
  "catchRate": 45,
  "baseFriendship": 50,
  "heightm": 0.7,
  "weightkg": 6.9
}
''';

const String _bulbasaurPokemonSpeciesPayload = '''
{
  "name": "bulbasaur",
  "generation": {"name": "generation-i"},
  "capture_rate": 45,
  "base_happiness": 50,
  "is_baby": false,
  "is_legendary": false,
  "is_mythical": false,
  "growth_rate": {"name": "medium-slow"},
  "egg_groups": [
    {"name": "monster"},
    {"name": "grass"}
  ],
  "color": {"name": "green"},
  "names": [
    {"language": {"name": "en"}, "name": "Bulbasaur"},
    {"language": {"name": "fr"}, "name": "Bulbizarre"}
  ],
  "genera": [
    {"language": {"name": "en"}, "genus": "Seed Pokémon"},
    {"language": {"name": "fr"}, "genus": "Pokémon Graine"}
  ],
  "flavor_text_entries": [
    {
      "language": {"name": "en"},
      "flavor_text": "A strange seed was planted on its back at birth."
    }
  ],
  "evolution_chain": {
    "url": "https://pokeapi.example.test/api/v2/evolution-chain/1/"
  }
}
''';

const String _ivysaurPokemonSpeciesPayload = '''
{
  "name": "ivysaur",
  "generation": {"name": "generation-i"},
  "capture_rate": 45,
  "base_happiness": 50,
  "is_baby": false,
  "is_legendary": false,
  "is_mythical": false,
  "growth_rate": {"name": "medium-slow"},
  "egg_groups": [
    {"name": "monster"},
    {"name": "grass"}
  ],
  "color": {"name": "green"},
  "names": [
    {"language": {"name": "en"}, "name": "Ivysaur"},
    {"language": {"name": "fr"}, "name": "Herbizarre"}
  ],
  "genera": [
    {"language": {"name": "en"}, "genus": "Seed Pokémon"},
    {"language": {"name": "fr"}, "genus": "Pokémon Graine"}
  ],
  "flavor_text_entries": [
    {
      "language": {"name": "en"},
      "flavor_text": "When the bulb on its back grows large, it appears to lose the ability to stand."
    }
  ],
  "evolution_chain": {
    "url": "https://pokeapi.example.test/api/v2/evolution-chain/1/"
  }
}
''';

const String _ivysaurShowdownPayload = '''
{
  "name": "Ivysaur",
  "num": 2,
  "gen": 1,
  "types": ["Grass", "Poison"],
  "baseStats": {
    "hp": 60,
    "atk": 62,
    "def": 63,
    "spa": 80,
    "spd": 80,
    "spe": 60
  },
  "abilities": {
    "0": "Overgrow",
    "H": "Chlorophyll"
  },
  "eggGroups": ["Monster", "Grass"],
  "expType": "Medium Slow",
  "baseExp": 142,
  "catchRate": 45,
  "baseFriendship": 50,
  "heightm": 1.0,
  "weightkg": 13.0
}
''';

const PokemonSpeciesFile _customSlugBulbasaurSpecies = PokemonSpeciesFile(
  id: 'bulbasaur',
  slug: 'bulbizarre-custom',
  nationalDex: 1,
  names: <String, String>{'en': 'Bulbasaur Custom'},
  speciesName: <String, String>{},
  genIntroduced: 1,
  typing: PokemonSpeciesTyping(types: <String>['grass', 'poison']),
  baseStats: PokemonSpeciesBaseStats(
    hp: 45,
    atk: 49,
    def: 49,
    spa: 65,
    spd: 65,
    spe: 45,
    bst: 318,
  ),
  abilities: PokemonSpeciesAbilities(
    primary: 'overgrow',
    hidden: 'chlorophyll',
  ),
  breeding: PokemonSpeciesBreeding(
    genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
    eggGroups: <String>['monster', 'grass'],
    hatchCycles: 20,
  ),
  progression: PokemonSpeciesProgression(
    growthRateId: 'medium_slow',
    baseExp: 64,
    catchRate: 45,
    baseFriendship: 50,
  ),
  refs: PokemonSpeciesRefs(
    learnset: 'bulbasaur',
    evolution: 'bulbasaur',
    media: 'bulbasaur',
  ),
  dexContent: PokemonSpeciesDexContent(
    heightM: 0.7,
    weightKg: 6.9,
    color: 'green',
    flavorText: 'Custom slug seed for overwrite proof.',
  ),
  gameplayFlags: PokemonSpeciesGameplayFlags(),
  sourceMeta: PokemonSpeciesSourceMeta(
    seededBy: 'test',
    seedVersion: 1,
  ),
);

const String _bulbasaurPokemonPayload = '''
{
  "name": "bulbasaur",
  "base_experience": 64,
  "height": 7,
  "weight": 69,
  "sprites": {
    "front_default": "https://assets.example.test/bulbasaur/front.png",
    "back_default": "https://assets.example.test/bulbasaur/back.png",
    "front_shiny": "https://assets.example.test/bulbasaur/front_shiny.png",
    "back_shiny": "https://assets.example.test/bulbasaur/back_shiny.png",
    "other": {
      "official-artwork": {
        "front_default": "https://assets.example.test/bulbasaur/portrait.png"
      }
    }
  },
  "cries": {
    "latest": "https://assets.example.test/bulbasaur/cry.ogg"
  },
  "moves": [
    {
      "move": {"name": "vine-whip"},
      "version_group_details": [
        {
          "level_learned_at": 7,
          "move_learn_method": {"name": "level-up"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    },
    {
      "move": {"name": "tackle"},
      "version_group_details": [
        {
          "level_learned_at": 1,
          "move_learn_method": {"name": "level-up"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    },
    {
      "move": {"name": "growl"},
      "version_group_details": [
        {
          "level_learned_at": 1,
          "move_learn_method": {"name": "level-up"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    },
    {
      "move": {"name": "solar-beam"},
      "version_group_details": [
        {
          "level_learned_at": 0,
          "move_learn_method": {"name": "machine"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    }
  ]
}
''';

const String _legacyBulbasaurPokemonPayload = '''
{
  "name": "bulbasaur",
  "moves": [
    {
      "move": {"name": "cut"},
      "version_group_details": [
        {
          "level_learned_at": 0,
          "move_learn_method": {"name": "machine"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    }
  ]
}
''';

const String _ivysaurPokemonPayload = '''
{
  "name": "ivysaur",
  "base_experience": 142,
  "height": 10,
  "weight": 130,
  "sprites": {
    "front_default": null,
    "back_default": null,
    "front_shiny": null,
    "back_shiny": null,
    "other": {
      "official-artwork": {
        "front_default": null
      }
    }
  },
  "cries": {
    "latest": null
  },
  "moves": [
    {
      "move": {"name": "razor-leaf"},
      "version_group_details": [
        {
          "level_learned_at": 20,
          "move_learn_method": {"name": "level-up"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    }
  ]
}
''';

const String _bulbasaurEvolutionChainPayload = '''
{
  "chain": {
    "species": {"name": "bulbasaur"},
    "evolution_details": [],
    "evolves_to": [
      {
        "species": {"name": "ivysaur"},
        "evolution_details": [
          {
            "trigger": {"name": "level-up"},
            "min_level": 16
          }
        ],
        "evolves_to": [
          {
            "species": {"name": "venusaur"},
            "evolution_details": [
              {
                "trigger": {"name": "use-item"},
                "item": {"name": "leaf-stone"},
                "known_move": {"name": "solar-beam"},
                "location": {"name": "special-garden"}
              }
            ],
            "evolves_to": []
          }
        ]
      }
    ]
  }
}
''';

```

### `packages/map_editor/test/pokeapi_live_source_test.dart`

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/infrastructure/external/pokeapi_live_source.dart';

void main() {
  group('PokeApiLiveSource', () {
    test('fetches pokemon, pokemon-species and evolution-chain payloads',
        () async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/pokemon/bulbasaur')) {
          return http.Response(
            jsonEncode(<String, Object?>{
              'name': 'bulbasaur',
              'base_experience': 64,
            }),
            200,
            headers: <String, String>{
              'content-type': 'application/json',
            },
          );
        }
        if (request.url.path.endsWith('/pokemon-species/bulbasaur')) {
          return http.Response(
            jsonEncode(<String, Object?>{
              'name': 'bulbasaur',
              'evolution_chain': <String, Object?>{
                'url': 'https://pokeapi.test/api/v2/evolution-chain/1/',
              },
            }),
            200,
            headers: <String, String>{
              'content-type': 'application/json',
            },
          );
        }
        if (request.url.path.endsWith('/evolution-chain/1/')) {
          return http.Response(
            jsonEncode(<String, Object?>{
              'chain': <String, Object?>{
                'species': <String, Object?>{'name': 'bulbasaur'},
                'evolves_to': <Object?>[],
              },
            }),
            200,
            headers: <String, String>{
              'content-type': 'application/json',
            },
          );
        }
        return http.Response('not found', 404);
      });

      final source = PokeApiLiveSource(
        client: client,
        baseUri: 'https://pokeapi.test/api/v2',
      );

      final pokemon = await source.fetchPokemon('bulbasaur');
      final pokemonSpecies = await source.fetchPokemonSpecies('bulbasaur');
      final evolution = await source.fetchEvolutionChainForSpecies('bulbasaur');

      expect(pokemon['name'], 'bulbasaur');
      expect(pokemonSpecies['name'], 'bulbasaur');
      expect(
        ((evolution['chain'] as Map<String, dynamic>)['species']
            as Map<String, dynamic>)['name'],
        'bulbasaur',
      );
    });

    test('surfaces 404 as EditorNotFoundException', () async {
      final source = PokeApiLiveSource(
        client: MockClient((request) async => http.Response('missing', 404)),
        baseUri: 'https://pokeapi.test/api/v2',
      );

      await expectLater(
        () => source.fetchPokemon('missingno'),
        throwsA(
          isA<EditorNotFoundException>().having(
            (error) => error.message,
            'message',
            'External PokeAPI pokemon payload not found for species "missingno"',
          ),
        ),
      );
    });

    test('downloads a binary asset with content type', () async {
      final source = PokeApiLiveSource(
        client: MockClient((request) async {
          return http.Response.bytes(
            Uint8List.fromList(<int>[1, 2, 3, 4]),
            200,
            headers: <String, String>{
              'content-type': 'image/png',
            },
          );
        }),
        baseUri: 'https://pokeapi.test/api/v2',
      );

      final asset = await source.fetchBinaryAsset(
        'https://assets.test/bulbasaur/front.png',
      );

      expect(asset.sourceUrl, 'https://assets.test/bulbasaur/front.png');
      expect(asset.contentType, 'image/png');
      expect(asset.bytes.toList(), <int>[1, 2, 3, 4]);
    });
  });
}

```

### `packages/map_editor/test/pokedex_workspace_ui_test.dart`

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/pokedex_providers.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/models/pokedex_species_detail.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/services/pokemon_database_index.dart';
import 'package:map_editor/src/application/use_cases/import_external_pokemon_use_cases.dart';
import 'package:map_editor/src/application/use_cases/import_pokemon_json_bundle_use_case.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_evolution_use_case.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_forms_classification_use_case.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_learnset_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_metadata_use_case.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_media_use_case.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/ui/canvas/pokedex_workspace.dart';
import 'package:map_editor/src/ui/canvas/pokedex_workspace_loader.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';

void main() {
  const sampleProject = ProjectManifest(
    name: 'pokedex_ui_test',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
  );

  Future<void> pumpPokedexWidget(
    WidgetTester tester,
    ProviderContainer container, {
    required Widget child,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 980);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 1280,
                height: 900,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  PokemonDatabaseIndexEntry buildEntry({
    required String id,
    required int nationalDex,
    required String primaryName,
    required List<String> types,
    required int genIntroduced,
    bool isEnabledInProject = true,
  }) {
    return PokemonDatabaseIndexEntry(
      id: id,
      nationalDex: nationalDex,
      primaryName: primaryName,
      genIntroduced: genIntroduced,
      types: types,
      isEnabledInProject: isEnabledInProject,
      refs: PokemonDatabaseIndexRefs(
        learnset: id,
        evolution: id,
        media: id,
      ),
    );
  }

  PokedexSpeciesDetail buildDetail({
    required String id,
    int nationalDex = 1,
    int genIntroduced = 1,
    List<String> types = const <String>['grass', 'poison'],
    String primaryAbility = 'overgrow',
    String? secondaryAbility,
    String? hiddenAbility = 'chlorophyll',
    List<String> otherForms = const <String>[],
    bool isEnabledInProject = true,
    Map<String, String> names = const <String, String>{
      'fr': 'Bulbizarre',
      'en': 'Bulbasaur',
    },
    String? flavorText =
        'Une étrange graine a été plantée sur son dos à la naissance.',
    bool starterEligible = true,
    bool giftOnly = false,
    bool tradeOnly = false,
    PokemonLearnsetFile? learnset,
    PokemonEvolutionFile? evolution,
    PokemonMediaFile? media,
  }) {
    return PokedexSpeciesDetail(
      species: PokemonSpeciesFile(
        id: id,
        slug: id,
        nationalDex: nationalDex,
        names: names,
        speciesName: const <String, String>{
          'fr': 'Pokémon Graine',
          'en': 'Seed Pokemon',
        },
        genIntroduced: genIntroduced,
        typing: PokemonSpeciesTyping(
          types: types,
        ),
        baseStats: const PokemonSpeciesBaseStats(
          hp: 45,
          atk: 49,
          def: 49,
          spa: 65,
          spd: 65,
          spe: 45,
          bst: 318,
        ),
        abilities: PokemonSpeciesAbilities(
          primary: primaryAbility,
          secondary: secondaryAbility,
          hidden: hiddenAbility,
        ),
        breeding: const PokemonSpeciesBreeding(
          genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
          eggGroups: <String>['monster', 'grass'],
          hatchCycles: 20,
        ),
        progression: const PokemonSpeciesProgression(
          growthRateId: 'medium_slow',
          baseExp: 64,
          catchRate: 45,
          baseFriendship: 50,
        ),
        forms: PokemonSpeciesForms(
          baseFormId: id,
          isBaseForm: true,
          formId: 'base',
          otherForms: otherForms,
        ),
        classification: PokemonSpeciesClassification(
          isEnabledInProject: isEnabledInProject,
          isObtainable: true,
        ),
        refs: PokemonSpeciesRefs(
          learnset: id,
          evolution: id,
          media: id,
        ),
        dexContent: PokemonSpeciesDexContent(
          heightM: 0.7,
          weightKg: 6.9,
          color: 'green',
          flavorText: flavorText,
        ),
        gameplayFlags: PokemonSpeciesGameplayFlags(
          starterEligible: starterEligible,
          giftOnly: giftOnly,
          tradeOnly: tradeOnly,
        ),
        sourceMeta: const PokemonSpeciesSourceMeta(
          seededBy: 'ui-test',
          seedVersion: 1,
        ),
      ),
      learnset: learnset ??
          PokemonLearnsetFile(
            speciesId: id,
            startingMoves: const <String>['tackle', 'growl'],
            relearnMoves: const <String>['vine_whip'],
            levelUp: const <PokemonLearnsetLevelUpEntry>[
              PokemonLearnsetLevelUpEntry(
                moveId: 'vine_whip',
                level: 7,
                source: 'level_up',
                versionGroup: 'scarlet-violet',
              ),
            ],
            tm: const <PokemonLearnsetMoveEntry>[
              PokemonLearnsetMoveEntry(
                moveId: 'protect',
                versionGroup: 'scarlet-violet',
              ),
            ],
          ),
      evolution: evolution ??
          const PokemonEvolutionFile(
            speciesId: 'bulbasaur',
            preEvolution: null,
            evolutions: <PokemonEvolutionEntry>[
              PokemonEvolutionEntry(
                targetSpeciesId: 'ivysaur',
                method: 'level_up',
                minLevel: 16,
                conditionText: <String, String>{
                  'fr': 'Évolue au niveau 16',
                  'en': 'Evolves at level 16',
                },
              ),
            ],
          ),
      media: media ??
          PokemonMediaFile(
            speciesId: id,
            defaultFormId: 'base',
            variants: <String, PokemonMediaVariant>{
              'base': PokemonMediaVariant(
                frontStatic: 'assets/pokemon/sprites/$id/front.png',
                backStatic: 'assets/pokemon/sprites/$id/back.png',
                frontShinyStatic: 'assets/pokemon/sprites/$id/front_shiny.png',
                backShinyStatic: 'assets/pokemon/sprites/$id/back_shiny.png',
                icon: 'assets/pokemon/sprites/$id/icon.png',
                party: 'assets/pokemon/sprites/$id/party.png',
                portrait: 'assets/pokemon/portraits/$id.png',
                cry: 'assets/pokemon/cries/$id.ogg',
                animations: <String, PokemonMediaAnimationRef>{
                  'battleFront': PokemonMediaAnimationRef(
                    sheet: 'assets/pokemon/sprites/$id/battle_front_sheet.png',
                    animationId: 'battle_front',
                  ),
                },
              ),
            },
          ),
    );
  }

  Future<void> selectPopupFilter(
    WidgetTester tester, {
    required Key popupKey,
    required String itemLabel,
  }) async {
    if (find.byKey(popupKey).evaluate().isEmpty) {
      final toggleFinder =
          find.byKey(const Key('pokedex-toggle-filters-button'));
      if (toggleFinder.evaluate().isNotEmpty) {
        await tester.tap(toggleFinder);
        await tester.pumpAndSettle();
      }
    }
    await tester.ensureVisible(find.byKey(popupKey));
    await tester.tap(find.byKey(popupKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text(itemLabel).last);
    await tester.pumpAndSettle();
  }

  PokemonDatabaseIndexEntry buildEntryFromSpecies(PokemonSpeciesFile species) {
    final speciesIndexEntry = PokemonSpeciesIndexEntry.fromSpeciesFile(
      species,
      relativePath:
          'data/pokemon/species/${species.nationalDex.toString().padLeft(4, '0')}-${species.slug}.json',
    );
    return PokemonDatabaseIndexEntry.fromSpeciesEntry(
      speciesIndexEntry: speciesIndexEntry,
      species: species,
    );
  }

  PokemonSpeciesFile applyMetadataUpdate(
    PokemonSpeciesFile species,
    UpdatePokedexSpeciesMetadataRequest request,
  ) {
    final normalizedTypes = request.types
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
    return PokemonSpeciesFile(
      id: species.id,
      slug: species.slug,
      nationalDex: species.nationalDex,
      names: Map<String, String>.from(request.names),
      speciesName: species.speciesName,
      genIntroduced: species.genIntroduced,
      typing: PokemonSpeciesTyping(
        types: normalizedTypes,
      ),
      baseStats: species.baseStats,
      abilities: species.abilities,
      breeding: species.breeding,
      progression: species.progression,
      forms: species.forms,
      classification: PokemonSpeciesClassification(
        isEnabledInProject: request.isEnabledInProject,
        isObtainable: species.classification.isObtainable,
        isLegendary: species.classification.isLegendary,
        isMythical: species.classification.isMythical,
        isBaby: species.classification.isBaby,
      ),
      refs: species.refs,
      dexContent: PokemonSpeciesDexContent(
        heightM: species.dexContent.heightM,
        weightKg: species.dexContent.weightKg,
        color: species.dexContent.color,
        flavorText: request.flavorText?.trim().isEmpty ?? true
            ? null
            : request.flavorText?.trim(),
      ),
      gameplayFlags: PokemonSpeciesGameplayFlags(
        starterEligible: request.starterEligible,
        giftOnly: request.giftOnly,
        tradeOnly: request.tradeOnly,
      ),
      sourceMeta: species.sourceMeta,
    );
  }

  PokemonSpeciesFile applyFormsClassificationUpdate(
    PokemonSpeciesFile species,
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) {
    return PokemonSpeciesFile(
      id: species.id,
      slug: species.slug,
      nationalDex: species.nationalDex,
      names: species.names,
      speciesName: species.speciesName,
      genIntroduced: species.genIntroduced,
      typing: species.typing,
      baseStats: species.baseStats,
      abilities: species.abilities,
      breeding: species.breeding,
      progression: species.progression,
      forms: PokemonSpeciesForms(
        baseFormId: request.isBaseForm ? species.id : request.baseFormId.trim(),
        isBaseForm: request.isBaseForm,
        formId: request.formId.trim(),
        formName: request.formName?.trim().isEmpty ?? true
            ? null
            : request.formName?.trim(),
        otherForms: request.otherForms
            .map((value) => value.trim())
            .where(
              (value) => value.isNotEmpty && value != request.formId.trim(),
            )
            .toSet()
            .toList(growable: false),
      ),
      classification: PokemonSpeciesClassification(
        isEnabledInProject: species.classification.isEnabledInProject,
        isObtainable: request.isObtainable,
        isLegendary: request.isLegendary,
        isMythical: request.isMythical,
        isBaby: request.isBaby,
      ),
      refs: species.refs,
      dexContent: species.dexContent,
      gameplayFlags: species.gameplayFlags,
      sourceMeta: species.sourceMeta,
    );
  }

  PokemonLearnsetFile applyLearnsetUpdate(
    PokedexSpeciesDetail detail,
    UpdatePokedexSpeciesLearnsetRequest request,
  ) {
    final learnsetRef = detail.species.refs.learnset.trim();
    return PokemonLearnsetFile(
      speciesId: learnsetRef.isEmpty ? detail.species.id : learnsetRef,
      startingMoves: request.startingMoves
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(growable: false),
      relearnMoves: request.relearnMoves
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(growable: false),
      levelUp: request.levelUp,
      tm: request.tm,
      tutor: request.tutor,
      egg: request.egg,
      event: request.event,
      transfer: request.transfer,
    );
  }

  PokemonEvolutionFile applyEvolutionUpdate(
    PokedexSpeciesDetail detail,
    UpdatePokedexSpeciesEvolutionRequest request,
  ) {
    final evolutionRef = detail.species.refs.evolution.trim();
    return PokemonEvolutionFile(
      speciesId: evolutionRef.isEmpty ? detail.species.id : evolutionRef,
      preEvolution: request.preEvolution?.trim().isEmpty ?? true
          ? null
          : request.preEvolution?.trim(),
      evolutions: request.evolutions,
    );
  }

  PokemonMediaFile applyMediaUpdate(
    PokedexSpeciesDetail detail,
    UpdatePokedexSpeciesMediaRequest request,
  ) {
    final mediaRef = detail.species.refs.media.trim();
    return PokemonMediaFile(
      speciesId: mediaRef.isEmpty ? detail.species.id : mediaRef,
      defaultFormId: request.defaultFormId.trim(),
      variants: request.variants,
    );
  }

  _FakePokedexWorkspaceStore buildStore({
    required List<PokedexSpeciesDetail> details,
  }) {
    return _FakePokedexWorkspaceStore(
      detailsById: <String, PokedexSpeciesDetail>{
        for (final detail in details) detail.species.id: detail,
      },
      entryBuilder: buildEntryFromSpecies,
      metadataUpdater: applyMetadataUpdate,
      formsClassificationUpdater: applyFormsClassificationUpdate,
      learnsetUpdater: applyLearnsetUpdate,
      evolutionUpdater: applyEvolutionUpdate,
      mediaUpdater: applyMediaUpdate,
    );
  }

  testWidgets('ProjectExplorerPanel shows a Pokédex entry tile',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Ce test verrouille seulement la présence de l'entrée UI dans l'éditeur.
    // Il reste volontairement purement en mémoire pour éviter tout bruit
    // filesystem inutile dans un contrôle aussi simple.
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 420,
                height: 980,
                child: ProjectExplorerPanel(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('pokedex-explorer-entry')), findsOneWidget);
    expect(find.text('Pokédex'), findsWidgets);
    expect(
      find.textContaining('Recherche, import, détail et édition locale'),
      findsOneWidget,
    );
  });

  testWidgets(
      'uses the provider-backed loader by default when no explicit loader is injected',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => <PokemonDatabaseIndexEntry>[
            buildEntry(
              id: 'treecko',
              nationalDex: 252,
              primaryName: 'Treecko',
              types: <String>['grass'],
              genIntroduced: 3,
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: const PokedexWorkspace(),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Treecko'), findsOneWidget);
    expect(find.text('treecko'), findsOneWidget);
    expect(find.byKey(const Key('pokedex-species-list')), findsOneWidget);
  });

  testWidgets(
      'prefers the explicitly injected loader over the provider-backed default',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => <PokemonDatabaseIndexEntry>[
            buildEntry(
              id: 'treecko',
              nationalDex: 252,
              primaryName: 'Treecko',
              types: <String>['grass'],
              genIntroduced: 3,
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'torchic',
            nationalDex: 255,
            primaryName: 'Torchic',
            types: <String>['fire'],
            genIntroduced: 3,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Torchic'), findsOneWidget);
    expect(find.text('torchic'), findsOneWidget);
    expect(find.text('Treecko'), findsNothing);
    expect(find.text('treecko'), findsNothing);
  });

  testWidgets(
      'renders the editor list shell with import and collapsible filters',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-species-list')), findsOneWidget);
    expect(find.text('Numéro'), findsOneWidget);
    expect(find.text('Nom'), findsOneWidget);
    expect(find.text('ID'), findsOneWidget);
    expect(find.text('Types'), findsOneWidget);
    expect(find.text('#0001'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('bulbasaur'), findsOneWidget);
    expect(find.text('grass'), findsWidgets);
    expect(find.text('poison'), findsWidgets);
    expect(find.byKey(const Key('pokedex-import-button')), findsOneWidget);
    expect(
      find.byKey(const Key('pokedex-toggle-filters-button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('pokedex-filters-panel')), findsNothing);
    expect(find.byKey(const Key('pokedex-detail-empty-state')), findsOneWidget);
  });

  testWidgets('selects a species row and shows the overview detail pane',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
        detailLoader: (_, speciesId) async => buildDetail(id: speciesId),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-detail-empty-state')), findsOneWidget);

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-detail-pane')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-overview-tab')), findsOneWidget);
    expect(find.text('Nom principal'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsWidgets);
    expect(find.text('Talent principal'), findsOneWidget);
    expect(find.text('overgrow'), findsOneWidget);
    expect(find.text('Références locales'), findsOneWidget);
    expect(find.text('bulbasaur'), findsWidgets);
  });

  testWidgets('switches to forms learnset evolutions and media tabs',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
        detailLoader: (_, speciesId) async => buildDetail(
          id: speciesId,
          otherForms: const <String>['mega'],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-tab-forms')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-forms-tab')), findsOneWidget);
    expect(find.text('Forme courante'), findsOneWidget);
    expect(find.textContaining('mega'), findsOneWidget);
    expect(find.text('Formes et classification'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pokedex-tab-learnset')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-learnset-tab')), findsOneWidget);
    expect(find.text('vine_whip • niveau 7'), findsOneWidget);
    expect(find.text('scarlet-violet • source level_up'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pokedex-tab-evolutions')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-evolutions-tab')), findsOneWidget);
    expect(find.text('Pré-évolution'), findsOneWidget);
    expect(find.text('Évolue au niveau 16'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pokedex-tab-media')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-media-tab')), findsOneWidget);
    expect(
      find.text('assets/pokemon/sprites/bulbasaur/front.png'),
      findsOneWidget,
    );
    expect(
      find.text('assets/pokemon/portraits/bulbasaur.png'),
      findsOneWidget,
    );
    expect(find.textContaining('battleFront: battle_front'), findsOneWidget);
  });

  testWidgets(
      'clears the selection and resets the detail pane when search hides it',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
        detailLoader: (_, speciesId) async => buildDetail(id: speciesId),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-media')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-media-tab')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'ivy',
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('pokedex-detail-empty-state')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-detail-pane')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      '',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pokedex-overview-tab')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-media-tab')), findsNothing);
  });

  testWidgets(
      'clears the selection and resets the detail pane when filters hide it',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
          ),
        ],
        detailLoader: (_, speciesId) async => buildDetail(id: speciesId),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-learnset')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-learnset-tab')), findsOneWidget);

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 3',
    );
    await tester.pump();

    expect(find.byKey(const Key('pokedex-detail-empty-state')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-detail-pane')), findsNothing);

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Toutes gén.',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pokedex-overview-tab')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-learnset-tab')), findsNothing);
  });

  testWidgets(
      'shows the search field and simple filters in the Pokédex workspace',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-search-field')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-filters-panel')), findsNothing);
    await tester.tap(find.byKey(const Key('pokedex-toggle-filters-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-filters-panel')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-type-filter')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-generation-filter')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-status-filter')), findsOneWidget);
  });

  testWidgets('filters instantly by species primary name', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'ivy',
    );
    await tester.pump();

    expect(find.text('Ivysaur'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
  });

  testWidgets('filters instantly by species id', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'bulb',
    );
    await tester.pump();

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Ivysaur'), findsNothing);
  });

  testWidgets('filters instantly by dex number with exact matching only',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 10,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      '#0001',
    );
    await tester.pump();

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Ivysaur'), findsNothing);
  });

  testWidgets('empty query restores the full list', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'ivy',
    );
    await tester.pump();
    expect(find.text('Ivysaur'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      '   ',
    );
    await tester.pump();

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Ivysaur'), findsOneWidget);
  });

  testWidgets('shows a dedicated no results state when search matches nothing',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'zzz',
    );
    await tester.pump();

    expect(find.byKey(const Key('pokedex-no-results-state')), findsOneWidget);
    expect(
      find.textContaining('Aucun résultat avec les critères actuels.'),
      findsOneWidget,
    );
    expect(find.textContaining('Recherche actuelle : "zzz"'), findsOneWidget);
    // Le champ reste visible pour corriger immédiatement la query.
    expect(find.byKey(const Key('pokedex-search-field')), findsOneWidget);
  });

  testWidgets('filters instantly by type', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'charmander',
            nationalDex: 4,
            primaryName: 'Charmander',
            types: <String>['fire'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-type-filter'),
      itemLabel: 'fire',
    );

    expect(find.text('Charmander'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
  });

  testWidgets('filters instantly by generation', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 3',
    );

    expect(find.text('Treecko'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
  });

  testWidgets('combines text search with simple filters', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'bellsprout',
            nationalDex: 69,
            primaryName: 'Bellsprout',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'tree',
    );
    await tester.pump();
    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-type-filter'),
      itemLabel: 'grass',
    );
    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 3',
    );

    expect(find.text('Treecko'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
    expect(find.text('Bellsprout'), findsNothing);
  });

  testWidgets('combines simple filters together', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
          ),
          buildEntry(
            id: 'torchic',
            nationalDex: 255,
            primaryName: 'Torchic',
            types: <String>['fire'],
            genIntroduced: 3,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-type-filter'),
      itemLabel: 'grass',
    );
    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 3',
    );

    expect(find.text('Treecko'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
    expect(find.text('Torchic'), findsNothing);
  });

  testWidgets('clearing all filters restores the full list', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 3',
    );
    expect(find.text('Treecko'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Toutes gén.',
    );

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Treecko'), findsOneWidget);
  });

  testWidgets('shows no results when simple filters eliminate the list',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-type-filter'),
      itemLabel: 'poison',
    );
    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 1',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'zzz',
    );
    await tester.pump();

    expect(find.byKey(const Key('pokedex-no-results-state')), findsOneWidget);
    expect(find.textContaining('Aucun résultat avec les critères actuels.'),
        findsOneWidget);
    expect(find.textContaining('Recherche actuelle : "zzz".'), findsOneWidget);
    expect(find.textContaining('Type : poison.'), findsOneWidget);
    expect(find.textContaining('Génération : 1.'), findsOneWidget);
    expect(find.byKey(const Key('pokedex-search-field')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-type-filter')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-generation-filter')), findsOneWidget);
  });

  testWidgets('filters instantly by enabled status', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
            isEnabledInProject: true,
          ),
          buildEntry(
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
            isEnabledInProject: false,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-status-filter'),
      itemLabel: 'Activées',
    );

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Treecko'), findsNothing);

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-status-filter'),
      itemLabel: 'Désactivées',
    );

    expect(find.text('Bulbasaur'), findsNothing);
    expect(find.text('Treecko'), findsOneWidget);
  });

  testWidgets(
      'enters edit mode saves simple metadata and keeps generation filtering stable',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          nationalDex: 1,
          genIntroduced: 1,
          names: const <String, String>{
            'fr': 'Bulbizarre',
            'en': 'Bulbasaur',
          },
          isEnabledInProject: true,
          starterEligible: true,
        ),
        buildDetail(
          id: 'treecko',
          nationalDex: 252,
          genIntroduced: 3,
          types: const <String>['grass'],
          names: const <String, String>{
            'fr': 'Arcko',
            'en': 'Treecko',
          },
        ),
      ],
    );

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: store.save,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 1',
    );
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Treecko'), findsNothing);

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.tap(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('pokedex-name-field-fr')),
      'Bulbizarre Projet',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-name-field-en')),
      'Bulbasaur Project',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-type-field-0')),
      'electric',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-type-field-1')),
      'fairy',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-flavor-text-field')),
      'Texte édité depuis la fiche locale.',
    );
    await tester.tap(find.byKey(const Key('pokedex-gift-only-switch')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-save-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-save-metadata-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(store.saveCallCount, 1);
    expect(store.speciesById('bulbasaur').classification.isEnabledInProject,
        isFalse);
    expect(store.speciesById('bulbasaur').names['fr'], 'Bulbizarre Projet');
    expect(store.speciesById('bulbasaur').names['en'], 'Bulbasaur Project');
    expect(
      store.speciesById('bulbasaur').typing.types,
      <String>['electric', 'fairy'],
    );
    expect(
      store.speciesById('bulbasaur').dexContent.flavorText,
      'Texte édité depuis la fiche locale.',
    );
    expect(store.speciesById('bulbasaur').gameplayFlags.giftOnly, isTrue);

    expect(find.text('Bulbasaur Project'), findsWidgets);
    expect(find.text('electric'), findsWidgets);
    expect(find.text('fairy'), findsWidgets);
    expect(find.text('Treecko'), findsNothing);
    expect(find.byKey(const Key('pokedex-name-field-fr')), findsNothing);
  });

  testWidgets('imports a pokemon from the wizard and refreshes the workspace',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final importedDetailsById = <String, PokedexSpeciesDetail>{};
    var entries = <PokemonDatabaseIndexEntry>[];
    var previewCallCount = 0;
    var importCallCount = 0;
    String? selectedPathSeenByPreview;
    String? selectedPathSeenByImport;

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_import_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => entries,
        detailLoader: (_, speciesId) async => importedDetailsById[speciesId]!,
        pickJsonImportFile: () async => '/tmp/source/species/pikachu.json',
        importPreviewer: (_, absoluteSpeciesSourcePath) async {
          previewCallCount += 1;
          selectedPathSeenByPreview = absoluteSpeciesSourcePath;
          return const PokemonJsonImportPreview(
            speciesId: 'pikachu',
            nationalDex: 25,
            primaryName: 'Pikachu',
            types: <String>['electric'],
            learnset: PokemonImportArtifactPreview(
              label: 'Learnset',
              refId: 'pikachu',
              status: PokemonImportPreviewStatus.found,
              absoluteSourcePath: '/tmp/source/learnsets/pikachu.json',
            ),
            evolution: PokemonImportArtifactPreview(
              label: 'Évolutions',
              refId: 'pikachu',
              status: PokemonImportPreviewStatus.found,
              absoluteSourcePath: '/tmp/source/evolutions/pikachu.json',
            ),
            media: PokemonImportArtifactPreview(
              label: 'Médias',
              refId: 'pikachu',
              status: PokemonImportPreviewStatus.missing,
            ),
          );
        },
        importer: (_, absoluteSpeciesSourcePath) async {
          importCallCount += 1;
          selectedPathSeenByImport = absoluteSpeciesSourcePath;
          final detail = buildDetail(
            id: 'pikachu',
            nationalDex: 25,
            types: const <String>['electric'],
            primaryAbility: 'static',
            hiddenAbility: 'lightning_rod',
            names: const <String, String>{
              'fr': 'Pikachu',
              'en': 'Pikachu',
            },
            flavorText: 'Il emmagasine l’électricité dans ses joues.',
          );
          importedDetailsById['pikachu'] = detail;
          entries = <PokemonDatabaseIndexEntry>[
            buildEntryFromSpecies(detail.species),
          ];
          return const PokemonJsonImportResult(
            preview: PokemonJsonImportPreview(
              speciesId: 'pikachu',
              nationalDex: 25,
              primaryName: 'Pikachu',
              types: <String>['electric'],
              learnset: PokemonImportArtifactPreview(
                label: 'Learnset',
                refId: 'pikachu',
                status: PokemonImportPreviewStatus.found,
              ),
              evolution: PokemonImportArtifactPreview(
                label: 'Évolutions',
                refId: 'pikachu',
                status: PokemonImportPreviewStatus.found,
              ),
              media: PokemonImportArtifactPreview(
                label: 'Médias',
                refId: 'pikachu',
                status: PokemonImportPreviewStatus.missing,
              ),
            ),
            importedSpecies: true,
            importedLearnset: true,
            importedEvolution: true,
            importedMedia: false,
          );
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-empty-state')), findsOneWidget);
    await tester
        .tap(find.byKey(const Key('pokedex-empty-state-import-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pokedex-import-source-step')), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('pokedex-import-source-continue-button')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pokedex-import-json-step')), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('pokedex-import-pick-json-file-button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('pikachu.json'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('pokedex-import-json-continue-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(previewCallCount, 1);
    expect(selectedPathSeenByPreview, '/tmp/source/species/pikachu.json');
    expect(
        find.byKey(const Key('pokedex-import-preview-step')), findsOneWidget);
    expect(
        find.byKey(const Key('pokedex-import-preview-title')), findsOneWidget);
    expect(find.text('#025 Pikachu'), findsOneWidget);
    expect(find.text('Type : electric'), findsOneWidget);
    expect(find.text('Learnset trouvé'), findsOneWidget);
    expect(find.text('Évolutions trouvées'), findsOneWidget);
    expect(find.text('Médias manquants'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pokedex-import-confirm-button')));
    await tester.pumpAndSettle();

    expect(importCallCount, 1);
    expect(selectedPathSeenByImport, '/tmp/source/species/pikachu.json');
    expect(find.byKey(const Key('pokedex-feedback-banner')), findsOneWidget);
    expect(find.textContaining('Pikachu'), findsWidgets);
    expect(find.byKey(const Key('pokedex-row-pikachu')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-detail-pane')), findsOneWidget);
    expect(find.text('electric'), findsWidgets);
  });

  testWidgets('imports a pokemon from API externe and refreshes the workspace',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final importedDetailsById = <String, PokedexSpeciesDetail>{};
    var entries = <PokemonDatabaseIndexEntry>[];
    var previewCallCount = 0;
    var importCallCount = 0;
    String? querySeenByPreview;
    String? querySeenByImport;

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_external_import_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => entries,
        detailLoader: (_, speciesId) async => importedDetailsById[speciesId]!,
        externalImportPreviewer: (_, speciesQuery) async {
          previewCallCount += 1;
          querySeenByPreview = speciesQuery;
          return const PokemonExternalImportResult(
            requestedSpeciesId: '25',
            importedSpeciesId: 'pikachu',
            preview: PokemonExternalImportPreview(
              speciesId: 'pikachu',
              nationalDex: 25,
              primaryName: 'Pikachu',
              types: <String>['electric'],
              learnset: PokemonExternalImportPreviewArtifact(
                label: 'Learnset',
                isAvailable: true,
              ),
              evolution: PokemonExternalImportPreviewArtifact(
                label: 'Évolutions',
                isAvailable: true,
              ),
              media: PokemonExternalImportPreviewArtifact(
                label: 'Médias',
                isAvailable: true,
              ),
              cries: PokemonExternalImportPreviewArtifact(
                label: 'Cri',
                isAvailable: true,
              ),
            ),
            dryRun: true,
            mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
            artifacts: <PokemonExternalImportArtifactResult>[
              PokemonExternalImportArtifactResult(
                kind: PokemonExternalImportArtifactKind.species,
                relativePath: 'data/pokemon/species/0025-pikachu.json',
                action: PokemonExternalImportArtifactAction.create,
                existedBefore: false,
              ),
              PokemonExternalImportArtifactResult(
                kind: PokemonExternalImportArtifactKind.learnset,
                relativePath: 'data/pokemon/learnsets/pikachu.json',
                action: PokemonExternalImportArtifactAction.create,
                existedBefore: false,
              ),
              PokemonExternalImportArtifactResult(
                kind: PokemonExternalImportArtifactKind.evolution,
                relativePath: 'data/pokemon/evolutions/pikachu.json',
                action: PokemonExternalImportArtifactAction.create,
                existedBefore: false,
              ),
              PokemonExternalImportArtifactResult(
                kind: PokemonExternalImportArtifactKind.media,
                relativePath: 'data/pokemon/media/pikachu.json',
                action: PokemonExternalImportArtifactAction.create,
                existedBefore: false,
              ),
            ],
          );
        },
        externalImporter: (_, speciesQuery) async {
          importCallCount += 1;
          querySeenByImport = speciesQuery;
          final detail = buildDetail(
            id: 'pikachu',
            nationalDex: 25,
            types: const <String>['electric'],
            primaryAbility: 'static',
            hiddenAbility: 'lightning_rod',
            names: const <String, String>{
              'fr': 'Pikachu',
              'en': 'Pikachu',
            },
            flavorText: 'Il emmagasine l’électricité dans ses joues.',
          );
          importedDetailsById['pikachu'] = detail;
          entries = <PokemonDatabaseIndexEntry>[
            buildEntryFromSpecies(detail.species),
          ];
          return const PokemonExternalImportResult(
            requestedSpeciesId: '25',
            importedSpeciesId: 'pikachu',
            preview: PokemonExternalImportPreview(
              speciesId: 'pikachu',
              nationalDex: 25,
              primaryName: 'Pikachu',
              types: <String>['electric'],
              learnset: PokemonExternalImportPreviewArtifact(
                label: 'Learnset',
                isAvailable: true,
              ),
              evolution: PokemonExternalImportPreviewArtifact(
                label: 'Évolutions',
                isAvailable: true,
              ),
              media: PokemonExternalImportPreviewArtifact(
                label: 'Médias',
                isAvailable: true,
              ),
              cries: PokemonExternalImportPreviewArtifact(
                label: 'Cri',
                isAvailable: true,
              ),
            ),
            dryRun: false,
            mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
            artifacts: <PokemonExternalImportArtifactResult>[
              PokemonExternalImportArtifactResult(
                kind: PokemonExternalImportArtifactKind.species,
                relativePath: 'data/pokemon/species/0025-pikachu.json',
                action: PokemonExternalImportArtifactAction.create,
                existedBefore: false,
              ),
              PokemonExternalImportArtifactResult(
                kind: PokemonExternalImportArtifactKind.learnset,
                relativePath: 'data/pokemon/learnsets/pikachu.json',
                action: PokemonExternalImportArtifactAction.create,
                existedBefore: false,
              ),
              PokemonExternalImportArtifactResult(
                kind: PokemonExternalImportArtifactKind.evolution,
                relativePath: 'data/pokemon/evolutions/pikachu.json',
                action: PokemonExternalImportArtifactAction.create,
                existedBefore: false,
              ),
              PokemonExternalImportArtifactResult(
                kind: PokemonExternalImportArtifactKind.media,
                relativePath: 'data/pokemon/media/pikachu.json',
                action: PokemonExternalImportArtifactAction.create,
                existedBefore: false,
              ),
            ],
            downloadedAssets: <PokemonExternalAssetDownloadResult>[
              PokemonExternalAssetDownloadResult(
                label: 'Portrait',
                relativePath: 'assets/pokemon/portraits/pikachu.png',
                sourceUrl: 'https://assets.example.test/pikachu/portrait.png',
                wasWritten: true,
              ),
            ],
          );
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester
        .tap(find.byKey(const Key('pokedex-empty-state-import-button')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('pokedex-import-external-api-source-card')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('pokedex-import-source-continue-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('pokedex-import-external-query-step')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-import-external-query-field')),
      '25',
    );
    await tester.tap(
      find.byKey(const Key('pokedex-import-external-preview-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(previewCallCount, 1);
    expect(querySeenByPreview, '25');
    expect(
      find.byKey(const Key('pokedex-import-external-preview-step')),
      findsOneWidget,
    );
    expect(find.text('#025 Pikachu'), findsOneWidget);
    expect(find.text('Type : electric'), findsOneWidget);
    expect(find.text('Learnset trouvé'), findsOneWidget);
    expect(find.text('Évolutions trouvées'), findsOneWidget);
    expect(find.text('Médias trouvés'), findsOneWidget);
    expect(find.text('Cri trouvé'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pokedex-import-confirm-button')));
    await tester.pumpAndSettle();

    expect(importCallCount, 1);
    expect(querySeenByImport, '25');
    expect(find.byKey(const Key('pokedex-feedback-banner')), findsOneWidget);
    expect(find.textContaining('Pikachu'), findsWidgets);
    expect(find.byKey(const Key('pokedex-row-pikachu')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-detail-pane')), findsOneWidget);
  });

  testWidgets('cancel discards metadata changes without writing',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          names: const <String, String>{
            'fr': 'Bulbizarre',
            'en': 'Bulbasaur',
          },
          isEnabledInProject: true,
        ),
      ],
    );

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: store.save,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.tap(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('pokedex-name-field-fr')),
      'Bulbizarre Temporaire',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-flavor-text-field')),
      'Changement non enregistré.',
    );
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-cancel-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-cancel-metadata-button')));
    await tester.pumpAndSettle();

    expect(store.saveCallCount, 0);
    expect(store.speciesById('bulbasaur').classification.isEnabledInProject,
        isTrue);
    expect(store.speciesById('bulbasaur').names['fr'], 'Bulbizarre');
    expect(
      store.speciesById('bulbasaur').dexContent.flavorText,
      'Une étrange graine a été plantée sur son dos à la naissance.',
    );
    expect(find.text('Bulbizarre Temporaire'), findsNothing);
    expect(
        find.byKey(const Key('pokedex-edit-metadata-button')), findsOneWidget);
  });

  testWidgets(
      'keeps edit mode and shows a save error when all editable names are cleared without persisting anything',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          names: const <String, String>{
            'fr': 'Bulbizarre',
            'en': 'Bulbasaur',
          },
          isEnabledInProject: true,
        ),
      ],
    );
    var attemptedSaves = 0;

    Future<PokemonSpeciesFile> saveWithValidation(
      ProjectWorkspace workspace,
      UpdatePokedexSpeciesMetadataRequest request,
    ) async {
      attemptedSaves += 1;

      // Le use case applicatif couvre déjà le non-write disque réel.
      // Ici, le test UI verrouille le contrat d'interaction :
      // - l'erreur remonte lisiblement ;
      // - le formulaire reste ouvert ;
      // - la backing store locale n'est pas mutée.
      final normalizedNames = <String, String>{
        for (final entry in request.names.entries)
          if (entry.key.trim().isNotEmpty) entry.key.trim(): entry.value.trim(),
      };
      final hasUsableName = normalizedNames.values.any(
        (value) => value.isNotEmpty,
      );
      if (!hasUsableName) {
        throw const EditorValidationException(
          'Pokemon species names must contain at least one non-empty value',
        );
      }

      return store.save(workspace, request);
    }

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    final persistedBefore = buildDetail(
      id: 'bulbasaur',
      names: const <String, String>{
        'fr': 'Bulbizarre',
        'en': 'Bulbasaur',
      },
      isEnabledInProject: true,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: saveWithValidation,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('pokedex-name-field-fr')),
      '   ',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-name-field-en')),
      ' \n ',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-flavor-text-field')),
      'Tentative refusée localement.',
    );
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-save-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-save-metadata-button')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));

    expect(attemptedSaves, 1);
    expect(find.byKey(const Key('pokedex-name-field-fr')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-name-field-en')), findsOneWidget);
    expect(
        find.byKey(const Key('pokedex-save-metadata-button')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-edit-metadata-button')), findsNothing);
    expect(
        find.byKey(const Key('pokedex-metadata-save-error')), findsOneWidget);
    expect(
      find.text(
          'Pokemon species names must contain at least one non-empty value'),
      findsOneWidget,
    );

    final readBack = store.speciesById('bulbasaur');
    expect(readBack.names, persistedBefore.species.names);
    expect(
      readBack.dexContent.flavorText,
      persistedBefore.species.dexContent.flavorText,
    );
    expect(
      readBack.classification.isEnabledInProject,
      persistedBefore.species.classification.isEnabledInProject,
    );
    expect(store.saveCallCount, 0);
  });

  testWidgets(
      'saving a disable under the enabled filter clears the current selection cleanly',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          nationalDex: 1,
          genIntroduced: 1,
          names: const <String, String>{
            'fr': 'Bulbizarre',
            'en': 'Bulbasaur',
          },
          isEnabledInProject: true,
        ),
        buildDetail(
          id: 'ivysaur',
          nationalDex: 2,
          genIntroduced: 1,
          names: const <String, String>{
            'fr': 'Herbizarre',
            'en': 'Ivysaur',
          },
          isEnabledInProject: true,
        ),
      ],
    );

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: store.save,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-status-filter'),
      itemLabel: 'Activées',
    );
    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-detail-pane')), findsOneWidget);

    await tester
        .ensureVisible(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.tap(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-save-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-save-metadata-button')));
    await tester.pumpAndSettle();

    expect(store.speciesById('bulbasaur').classification.isEnabledInProject,
        isFalse);
    expect(find.byKey(const Key('pokedex-detail-empty-state')), findsOneWidget);
    expect(find.text('Ivysaur'), findsOneWidget);
    expect(find.text('Bulbizarre'), findsNothing);
  });

  testWidgets('edits forms and classification from the dedicated tab',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          names: const <String, String>{
            'fr': 'Bulbizarre',
            'en': 'Bulbasaur',
          },
        ),
      ],
    );

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: store.save,
        formsClassificationSaver: store.saveFormsClassification,
        learnsetSaver: store.saveLearnset,
        evolutionSaver: store.saveEvolution,
        mediaSaver: store.saveMedia,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-forms')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-edit-forms-button')));
    await tester.tap(find.byKey(const Key('pokedex-edit-forms-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pokedex-is-base-form-switch')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('pokedex-form-id-field')),
      'mega',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-form-name-field')),
      'Méga',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-other-forms-field')),
      'base\ngmax',
    );
    await tester.ensureVisible(
      find.byKey(const Key('pokedex-is-legendary-switch')),
    );
    await tester.tap(find.byKey(const Key('pokedex-is-legendary-switch')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-save-forms-button')));
    await tester.tap(find.byKey(const Key('pokedex-save-forms-button')));
    await tester.pumpAndSettle();

    expect(store.formsSaveCallCount, 1);
    expect(store.speciesById('bulbasaur').forms.formId, 'mega');
    expect(store.speciesById('bulbasaur').forms.formName, 'Méga');
    expect(store.speciesById('bulbasaur').classification.isLegendary, isTrue);
    expect(find.text('Méga (mega)'), findsOneWidget);
    expect(find.byKey(const Key('pokedex-edit-forms-button')), findsOneWidget);
  });

  testWidgets('creates a learnset locally from the dedicated tab',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          learnset: null,
        ),
      ],
    );

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: store.save,
        formsClassificationSaver: store.saveFormsClassification,
        learnsetSaver: store.saveLearnset,
        evolutionSaver: store.saveEvolution,
        mediaSaver: store.saveMedia,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-learnset')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('pokedex-edit-learnset-button')),
    );
    await tester.tap(find.byKey(const Key('pokedex-edit-learnset-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('pokedex-learnset-starting-field')),
      'tackle\ngrowl',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-learnset-level-up-field')),
      'vine_whip|7|level_up|scarlet-violet',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-learnset-tm-field')),
      'protect|scarlet-violet',
    );
    await tester.ensureVisible(
      find.byKey(const Key('pokedex-save-learnset-button')),
    );
    await tester.tap(find.byKey(const Key('pokedex-save-learnset-button')));
    await tester.pumpAndSettle();

    expect(store.learnsetSaveCallCount, 1);
    expect(store.learnsetById('bulbasaur')?.startingMoves, <String>[
      'tackle',
      'growl',
    ]);
    expect(
      store.learnsetById('bulbasaur')?.levelUp.single.moveId,
      'vine_whip',
    );
    expect(find.text('tackle, growl'), findsOneWidget);
  });

  testWidgets('creates an evolution locally from the dedicated tab',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          evolution: null,
        ),
      ],
    );

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: store.save,
        formsClassificationSaver: store.saveFormsClassification,
        learnsetSaver: store.saveLearnset,
        evolutionSaver: store.saveEvolution,
        mediaSaver: store.saveMedia,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-evolutions')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('pokedex-edit-evolution-button')),
    );
    await tester.tap(find.byKey(const Key('pokedex-edit-evolution-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('pokedex-evolution-entries-field')),
      'ivysaur|level_up|16|||Évolue au niveau 16|Evolves at level 16',
    );
    await tester.ensureVisible(
      find.byKey(const Key('pokedex-save-evolution-button')),
    );
    await tester.tap(find.byKey(const Key('pokedex-save-evolution-button')));
    await tester.pumpAndSettle();

    expect(store.evolutionSaveCallCount, 1);
    expect(
      store.evolutionById('bulbasaur')?.evolutions.single.targetSpeciesId,
      'ivysaur',
    );
    expect(find.textContaining('Évolue au niveau 16'), findsOneWidget);
  });

  testWidgets('creates media references locally from the dedicated tab',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          media: null,
        ),
      ],
    );

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: store.save,
        formsClassificationSaver: store.saveFormsClassification,
        learnsetSaver: store.saveLearnset,
        evolutionSaver: store.saveEvolution,
        mediaSaver: store.saveMedia,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-media')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-edit-media-button')));
    await tester.tap(find.byKey(const Key('pokedex-edit-media-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('pokedex-media-default-form-field')),
      'base',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-media-variants-field')),
      'base|assets/pokemon/sprites/bulbasaur/front.png|assets/pokemon/sprites/bulbasaur/back.png|||assets/pokemon/sprites/bulbasaur/icon.png|assets/pokemon/sprites/bulbasaur/party.png||assets/pokemon/portraits/bulbasaur.png|assets/pokemon/cries/bulbasaur.ogg',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-media-animations-field')),
      'base|battleFront|assets/pokemon/sprites/bulbasaur/battle_front_sheet.png|battle_front',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('pokedex-save-media-button')),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-save-media-button')));
    final saveMediaButton = tester.widget<CupertinoButton>(
      find.byKey(const Key('pokedex-save-media-button')),
    );
    saveMediaButton.onPressed!.call();
    await tester.pumpAndSettle();

    expect(store.mediaSaveCallCount, 1);
    expect(store.mediaById('bulbasaur')?.defaultFormId, 'base');
    expect(
      store.mediaById('bulbasaur')?.variants['base']?.portrait,
      'assets/pokemon/portraits/bulbasaur.png',
    );
    expect(find.text('assets/pokemon/portraits/bulbasaur.png'), findsOneWidget);
  });

  testWidgets('shows a loading state before the species list resolves',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final completer = Completer<List<PokemonDatabaseIndexEntry>>();

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_loading_test',
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) => completer.future,
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('pokedex-loading-label')), findsOneWidget);

    // On prouve l'existence de l'état loading, puis on résout explicitement le
    // future avant teardown pour éviter de laisser un timer autoDispose Riverpod
    // en attente à la fin du test.
    completer.complete(const <PokemonDatabaseIndexEntry>[]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('shows an empty state when no species files are present',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => const <PokemonDatabaseIndexEntry>[],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-empty-state')), findsOneWidget);
    expect(find.textContaining('Pokédex est encore vide'), findsOneWidget);
  });

  testWidgets('shows an error state when species loading fails',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) => Future<List<PokemonDatabaseIndexEntry>>.error(
          const EditorPersistenceException(
            'Invalid JSON in Pokemon species file',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-error-state')), findsOneWidget);
    expect(find.textContaining('Impossible de charger'), findsOneWidget);
    expect(find.textContaining('Invalid JSON'), findsOneWidget);
  });

  test(
    'returns an empty list when the configured species directory does not exist yet',
    () async {
      final tempProjectRoot =
          await Directory.systemTemp.createTemp('pokedex_loader_test_');
      try {
        final workspace = ProjectFileSystem(tempProjectRoot.path);
        final createProjectUseCase = CreateProjectUseCase(
          FileProjectRepository(),
          const FileProjectWorkspaceFactory(),
        );

        await createProjectUseCase.execute(
          'Pokedex Loader Project',
          tempProjectRoot.path,
        );

        final loader = createPokedexEntryLoader(
          projectRepository: FileProjectRepository(),
          databaseIndex: PokemonDatabaseIndex(
            projectRepository: FileProjectRepository(),
            pokemonReadRepository: const FilePokemonReadRepository(),
          ),
        );

        // Ce test verrouille le vrai nettoyage du mini-fix :
        // l'absence du dossier `species/` doit produire une liste vide
        // explicitement, sans dépendre du texte d'une exception remontée.
        final entries = await loader(workspace);
        expect(entries, isEmpty);
      } finally {
        if (await tempProjectRoot.exists()) {
          await tempProjectRoot.delete(recursive: true);
        }
      }
    },
  );
}

class _FakePokedexWorkspaceStore {
  _FakePokedexWorkspaceStore({
    required Map<String, PokedexSpeciesDetail> detailsById,
    required this.entryBuilder,
    required this.metadataUpdater,
    required this.formsClassificationUpdater,
    required this.learnsetUpdater,
    required this.evolutionUpdater,
    required this.mediaUpdater,
  }) : _detailsById = Map<String, PokedexSpeciesDetail>.from(detailsById);

  final Map<String, PokedexSpeciesDetail> _detailsById;
  final PokemonDatabaseIndexEntry Function(PokemonSpeciesFile species)
      entryBuilder;
  final PokemonSpeciesFile Function(
    PokemonSpeciesFile species,
    UpdatePokedexSpeciesMetadataRequest request,
  ) metadataUpdater;
  final PokemonSpeciesFile Function(
    PokemonSpeciesFile species,
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) formsClassificationUpdater;
  final PokemonLearnsetFile Function(
    PokedexSpeciesDetail detail,
    UpdatePokedexSpeciesLearnsetRequest request,
  ) learnsetUpdater;
  final PokemonEvolutionFile Function(
    PokedexSpeciesDetail detail,
    UpdatePokedexSpeciesEvolutionRequest request,
  ) evolutionUpdater;
  final PokemonMediaFile Function(
    PokedexSpeciesDetail detail,
    UpdatePokedexSpeciesMediaRequest request,
  ) mediaUpdater;

  int saveCallCount = 0;
  int formsSaveCallCount = 0;
  int learnsetSaveCallCount = 0;
  int evolutionSaveCallCount = 0;
  int mediaSaveCallCount = 0;

  Future<List<PokemonDatabaseIndexEntry>> loadEntries(
    ProjectWorkspace workspace,
  ) async {
    final entries = _detailsById.values
        .map((detail) => entryBuilder(detail.species))
        .toList(growable: false)
      ..sort((left, right) {
        final dexCompare = left.nationalDex.compareTo(right.nationalDex);
        if (dexCompare != 0) {
          return dexCompare;
        }
        return left.id.compareTo(right.id);
      });
    return entries;
  }

  Future<PokedexSpeciesDetail> loadDetail(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    return _detailsById[speciesId]!;
  }

  Future<PokemonSpeciesFile> save(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesMetadataRequest request,
  ) async {
    saveCallCount += 1;
    final current = _detailsById[request.speciesId]!;
    final updatedSpecies = metadataUpdater(current.species, request);
    _detailsById[request.speciesId] = PokedexSpeciesDetail(
      species: updatedSpecies,
      learnset: current.learnset,
      evolution: current.evolution,
      media: current.media,
    );
    return updatedSpecies;
  }

  PokemonSpeciesFile speciesById(String speciesId) {
    return _detailsById[speciesId]!.species;
  }

  Future<PokemonSpeciesFile> saveFormsClassification(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) async {
    formsSaveCallCount += 1;
    final current = _detailsById[request.speciesId]!;
    final updatedSpecies = formsClassificationUpdater(current.species, request);
    _detailsById[request.speciesId] = PokedexSpeciesDetail(
      species: updatedSpecies,
      learnset: current.learnset,
      evolution: current.evolution,
      media: current.media,
    );
    return updatedSpecies;
  }

  Future<PokemonLearnsetFile> saveLearnset(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesLearnsetRequest request,
  ) async {
    learnsetSaveCallCount += 1;
    final current = _detailsById[request.speciesId]!;
    final updatedLearnset = learnsetUpdater(current, request);
    _detailsById[request.speciesId] = PokedexSpeciesDetail(
      species: current.species,
      learnset: updatedLearnset,
      evolution: current.evolution,
      media: current.media,
    );
    return updatedLearnset;
  }

  Future<PokemonEvolutionFile> saveEvolution(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesEvolutionRequest request,
  ) async {
    evolutionSaveCallCount += 1;
    final current = _detailsById[request.speciesId]!;
    final updatedEvolution = evolutionUpdater(current, request);
    _detailsById[request.speciesId] = PokedexSpeciesDetail(
      species: current.species,
      learnset: current.learnset,
      evolution: updatedEvolution,
      media: current.media,
    );
    return updatedEvolution;
  }

  Future<PokemonMediaFile> saveMedia(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesMediaRequest request,
  ) async {
    mediaSaveCallCount += 1;
    final current = _detailsById[request.speciesId]!;
    final updatedMedia = mediaUpdater(current, request);
    _detailsById[request.speciesId] = PokedexSpeciesDetail(
      species: current.species,
      learnset: current.learnset,
      evolution: current.evolution,
      media: updatedMedia,
    );
    return updatedMedia;
  }

  PokemonLearnsetFile? learnsetById(String speciesId) {
    return _detailsById[speciesId]!.learnset;
  }

  PokemonEvolutionFile? evolutionById(String speciesId) {
    return _detailsById[speciesId]!.evolution;
  }

  PokemonMediaFile? mediaById(String speciesId) {
    return _detailsById[speciesId]!.media;
  }
}

```

### `packages/map_editor/test/provider_wiring_test.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/content_studio_providers.dart';
import 'package:map_editor/src/app/providers/core_providers.dart';
import 'package:map_editor/src/app/providers/editor_workspace_providers.dart';
import 'package:map_editor/src/app/providers/pokedex_providers.dart';
import 'package:map_editor/src/app/providers/use_case_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_workspace_providers.dart';
import 'package:map_editor/src/features/narrative/state/narrative_workspace_state.dart';

void main() {
  group('provider wiring', () {
    test('resolves thematic controllers from a ProviderContainer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(projectRepositoryProvider), isNotNull);
      expect(container.read(terrainPresetResolverProvider), isNotNull);
      expect(container.read(createProjectDialogueUseCaseProvider), isNotNull);
      expect(container.read(pokemonDatabaseIndexProvider), isNotNull);
      expect(container.read(pokeApiLiveSourceProvider), isNotNull);
      expect(container.read(showdownSnapshotSourceProvider), isNotNull);
      expect(
          container.read(pokemonExternalSourceRepositoryProvider), isNotNull);
      expect(
        container.read(importExternalPokemonSpeciesUseCaseProvider),
        isNotNull,
      );
      expect(container.read(pokedexExternalImportPreviewerProvider), isNotNull);
      expect(container.read(pokedexExternalImporterProvider), isNotNull);
      expect(container.read(editorWorkspaceControllerProvider), isNotNull);
      expect(container.read(projectContentControllerProvider), isNotNull);
    });

    test('derives selected narrative summaries from controller + projection',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          scenarios: <ScenarioAsset>[
            ScenarioAsset(
              id: 'global_intro',
              name: 'Global Intro',
              scope: ScenarioScope.globalStory,
              entryNodeId: 'start',
              metadata: <String, String>{
                'step.id': 'step.professor_intro',
                'step.name': 'Rencontrer le professeur',
              },
            ),
            ScenarioAsset(
              id: 'local_intro',
              name: 'Local Intro',
              scope: ScenarioScope.localEventFlow,
              entryNodeId: 'start',
              declaredOutcomes: <String>['story.started'],
            ),
          ],
        ),
      );

      final narrativeNotifier =
          container.read(narrativeWorkspaceControllerProvider.notifier);
      narrativeNotifier.openGlobalStory(scenarioId: 'global_intro');
      narrativeNotifier.openStep(
        stepId: 'step.professor_intro',
        globalScenarioId: 'global_intro',
      );
      narrativeNotifier.openCutscene(cutsceneScenarioId: 'local_intro');
      narrativeNotifier.selectOutcome('story.started');

      expect(
        container.read(selectedGlobalStorySummaryProvider)?.id,
        'global_intro',
      );
      expect(
        container.read(selectedCutsceneSummaryProvider)?.id,
        'local_intro',
      );
      expect(
        container.read(selectedNarrativeStepSummaryProvider)?.id,
        'step.professor_intro',
      );
      expect(
        container.read(selectedNarrativeOutcomeSummaryProvider)?.id,
        'story.started',
      );
    });
  });
}

```

### `packages/map_editor/test/showdown_snapshot_source_test.dart`

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/infrastructure/external/showdown_snapshot_source.dart';

void main() {
  group('ShowdownSnapshotSource', () {
    test('extracts species and loads structured snapshots', () async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/pokedex.json')) {
          return http.Response(
            jsonEncode(<String, Object?>{
              'bulbasaur': <String, Object?>{
                'name': 'Bulbasaur',
                'num': 1,
                'types': <String>['Grass', 'Poison'],
              },
            }),
            200,
            headers: const <String, String>{
              'content-type': 'application/json',
            },
          );
        }
        if (request.url.path.endsWith('/learnsets.json')) {
          return http.Response(
            jsonEncode(<String, Object?>{
              'bulbasaur': <String, Object?>{
                'learnset': <String, Object?>{
                  'tackle': <String>['9L1']
                },
              },
            }),
            200,
            headers: const <String, String>{
              'content-type': 'application/json',
            },
          );
        }
        if (request.url.path.endsWith('/moves.json')) {
          return http.Response(
            jsonEncode(<String, Object?>{
              'tackle': <String, Object?>{'name': 'Tackle'},
            }),
            200,
            headers: const <String, String>{
              'content-type': 'application/json',
            },
          );
        }
        return http.Response('not found', 404);
      });

      final source = ShowdownSnapshotSource(
        client: client,
        baseUri: 'https://showdown.test/data',
      );

      final species = await source.fetchSpecies('bulbasaur');
      final learnsets = await source.fetchLearnsetsSnapshot();
      final moves = await source.fetchMovesSnapshot();

      expect(species['id'], 'bulbasaur');
      expect(species['name'], 'Bulbasaur');
      expect(learnsets.containsKey('bulbasaur'), isTrue);
      expect(moves.containsKey('tackle'), isTrue);
    });

    test('surfaces a missing species cleanly', () async {
      final source = ShowdownSnapshotSource(
        client: MockClient((request) async {
          return http.Response(
            jsonEncode(<String, Object?>{}),
            200,
            headers: const <String, String>{
              'content-type': 'application/json',
            },
          );
        }),
        baseUri: 'https://showdown.test/data',
      );

      await expectLater(
        () => source.fetchSpecies('missingno'),
        throwsA(
          isA<EditorNotFoundException>().having(
            (error) => error.message,
            'message',
            'External Showdown species payload not found for species "missingno"',
          ),
        ),
      );
    });
  });
}

```

