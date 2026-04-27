# Phase R1 — Lot 2 — Auto-complétion mono-espèce dans le wizard Pokédex

## 1. Résumé exécutif

Le lot 2 est livré strictement dans son périmètre.

Le wizard Pokédex, branche `API externe`, n’accepte plus une simple chaîne libre comme cible implicite. Il passe maintenant par un searcher mono-espèce qui réutilise le résolveur du lot 1, affiche des suggestions concrètes, exige une sélection explicite et bloque preview/import tant qu’aucune espèce réelle n’a été choisie.

Je n’ai pas rouvert 11A, je n’ai pas réécrit le pipeline d’import externe, je n’ai pas ajouté de batch, et je n’ai pas créé de stack parallèle de recherche. L’extension appliquée est volontairement petite : un use case de suggestion mono-espèce, une extension minimale du repository externe existant, le wiring provider nécessaire, le branchement du wizard, puis les tests ciblés.

## 2. État initial audité

- Le lot 1 était déjà présent avec :
  - les modèles de résolution de requête externe ;
  - un résolveur pur côté application ;
  - un provider DI du résolveur.
- Le wizard Pokédex existant branchait déjà :
  - la source locale JSON ;
  - la source `API externe` ;
  - les previewers / importers 11A.
- Avant ce lot 2, la branche `API externe` utilisait encore un champ texte libre :
  - la saisie brute alimentait directement preview/import ;
  - aucune suggestion mono-espèce n’était visible ;
  - aucune sélection explicite n’était imposée ;
  - le résolveur du lot 1 n’était pas encore branché au wizard.
- L’infra externe existante fournissait déjà les briques utiles :
  - `ShowdownSnapshotSource.fetchPokedexSnapshot()` ;
  - `HttpPokemonExternalSourceRepository` ;
  - le pipeline d’import externe 11A.

## 3. Périmètre inclus / exclu

### Inclus

- auto-complétion mono-espèce dans la branche `API externe` du wizard Pokédex ;
- sélection explicite obligatoire avant preview/import ;
- états UI propres : vide, loading, no result, invalid, hors-scope, erreur ;
- navigation souris et clavier honnête ;
- use case applicatif léger de suggestion mono-espèce ;
- wiring provider minimal ;
- tests applicatifs, wiring et widget ;
- report final complet.

### Exclu

- batch preview ;
- batch execution ;
- import par génération / plage / liste ;
- refonte du pipeline 11A ;
- réécriture du lot 1 ;
- runtime / battle / save ;
- trainers / encounters ;
- moves catalog hors non-régression des tests existants ;
- refonte globale du wizard.

## 4. Décisions d’architecture

1. Réutiliser le résolveur du lot 1 comme seule couche de compréhension de la requête.
2. Étendre très légèrement le port externe existant pour exposer `fetchShowdownPokedexSnapshot()` au lieu d’introduire une stack de recherche concurrente.
3. Ajouter un use case minimal `SearchExternalPokemonSpeciesUseCase` parce que ce lot a un vrai besoin d’orchestration applicative :
   - il réutilise le résolveur du lot 1 ;
   - il charge un snapshot déjà disponible côté infra ;
   - il transforme le tout en état UI structuré et stable.
4. Garder l’UI strictement dans son rôle :
   - debounce local ;
   - affichage des états ;
   - liste de suggestions ;
   - sélection explicite ;
   - verrouillage du bouton preview/import.
5. Ne pas accepter les intentions hors-scope du lot 2 : génération, range, liste explicite restent reconnues mais refusées proprement avec message clair.

## 5. Liste exacte des fichiers modifiés / créés / supprimés

### Modifiés

- `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`
- `packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart`
- `packages/map_editor/lib/src/application/use_cases/use_cases.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart`
- `packages/map_editor/test/http_pokemon_external_source_repository_test.dart`
- `packages/map_editor/test/import_external_pokemon_use_cases_test.dart`
- `packages/map_editor/test/pokedex_workspace_ui_test.dart`
- `packages/map_editor/test/provider_wiring_test.dart`
- `packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart`

### Créés

- `packages/map_editor/lib/src/application/models/pokemon_external_species_search_result.dart`
- `packages/map_editor/lib/src/application/use_cases/search_external_pokemon_species_use_case.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_external_search_field.dart`
- `packages/map_editor/test/pokedex_external_autocomplete_ui_test.dart`
- `packages/map_editor/test/search_external_pokemon_species_use_case_test.dart`

### Supprimés

- Aucun

## 6. Justification fichier par fichier

- `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart` : Ajout du use case de recherche mono-espèce et du provider léger réutilisable par le wizard, sans créer de stack parallèle.
- `packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart` : Extension minimale du port externe existant pour exposer le snapshot Showdown Pokédex déjà cohérent avec l’infra 11A.
- `packages/map_editor/lib/src/application/use_cases/use_cases.dart` : Export du nouveau use case pour rester aligné avec la façade applicative existante.
- `packages/map_editor/lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart` : Implémentation concrète du nouvel accès snapshot via les sources déjà branchées.
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart` : Orchestration locale de la recherche debounce, de la sélection explicite et du verrouillage preview/import sur sélection réelle.
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart` : Branchement UI de l’étape mono-espèce sur le nouveau champ assisté et désactivation honnête du bouton tant qu’aucune espèce n’est choisie.
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart` : Passage de l’injection du searcher au wizard sans refonte du workspace.
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart` : Injection du searcher via provider ou override de test, toujours dans le widget public existant.
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart` : Ajout du typedef de callback partagé pour garder un contrat UI minimal et lisible.
- `packages/map_editor/test/http_pokemon_external_source_repository_test.dart` : Validation que le repository externe compose bien aussi le snapshot Pokédex utilisé pour les suggestions.
- `packages/map_editor/test/import_external_pokemon_use_cases_test.dart` : Mise à niveau du fake repository après l’extension minimale du port existant.
- `packages/map_editor/test/pokedex_workspace_ui_test.dart` : Non-régression du wizard existant avec sélection explicite avant preview/import.
- `packages/map_editor/test/provider_wiring_test.dart` : Validation du wiring Riverpod des nouvelles briques du lot 2.
- `packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart` : Mise à niveau du fake repository pour rester compatible avec le port étendu.
- `packages/map_editor/lib/src/application/models/pokemon_external_species_search_result.dart` : Nouveau modèle applicatif structuré pour exprimer suggestions, vide, hors-scope, invalidité et erreur sans fuite UI.
- `packages/map_editor/lib/src/application/use_cases/search_external_pokemon_species_use_case.dart` : Nouveau use case minimalement justifié qui combine résolveur du lot 1 et snapshot externe existant pour la recherche mono-espèce.
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_external_search_field.dart` : Nouveau widget fortement commenté de saisie assistée mono-espèce avec liste de suggestions explicite et navigation clavier/souris.
- `packages/map_editor/test/pokedex_external_autocomplete_ui_test.dart` : Nouveaux tests widget du contrat utilisateur du lot 2.
- `packages/map_editor/test/search_external_pokemon_species_use_case_test.dart` : Nouveaux tests applicatifs du use case de suggestions mono-espèce.

## 7. Sub-agents utilisés, conclusions, retenu / rejeté

- `Boyle` — audit architecture / scope
  - Conclusion : rester sur le port externe existant, accepter un use case mince uniquement parce que ce lot a besoin d’orchestrer le résolveur du lot 1 avec une source externe déjà branchée, et injecter le résultat dans le wizard sans nouveau pipeline.
  - Retenu : extension minimale du repository externe existant + use case applicatif fin.
  - Rejeté : nouveau port de recherche externe ou logique réseau dans les widgets.
- `Avicenna` — audit UX wizard
  - Conclusion : la saisie ne doit jamais valoir sélection, et le flow doit rendre visibles les états vide, loading, pending selection, no result, invalid et hors-scope.
  - Retenu : sélection explicite obligatoire, message clair pour hors-scope mono-espèce, pas de preview implicite.
  - Rejeté : champ texte “magique” qui auto-valide une espèce sans clic ou action clavier explicite.
- `Mendel` — audit test matrix
  - Conclusion : combiner tests applicatifs du searcher, test de wiring Riverpod et tests widget centrés sur les vrais contrats utilisateurs.
  - Retenu : couverture du vide, loading, no-result, invalid, hors-scope, sélection explicite et non-régression du wizard existant.
  - Rejeté : tests décoratifs ne prouvant pas le verrouillage preview/import.
- `Banach` — review contradictoire
  - Conclusion : il faut refuser toute dérive vers du batch ou une “recherche intelligente” cachée dans le lot 2.
  - Retenu : scope strict mono-espèce, aucune ouverture du lot 3, pas de logique d’import dans la suggestion.
  - Rejeté : accepter silencieusement des requêtes `gen 1`, `1-151` ou `pikachu,eevee` comme si ce lot les supportait.

## 8. Commandes réellement exécutées

- `sed -n '1,260p' packages/map_editor/lib/src/application/models/pokemon_external_query_resolution.dart`
- `sed -n '1,320p' packages/map_editor/lib/src/application/services/pokemon_external_query_resolver.dart`
- `sed -n '1,340p' packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`
- `sed -n '1,320p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart`
- `sed -n '320,640p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart`
- `sed -n '1,340p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart`
- `sed -n '1,320p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_support.dart`
- `sed -n '1,320p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart`
- `sed -n '1,320p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart`
- `sed -n '1,320p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart`
- `rg -n "pokedex-import-external|Import depuis API externe|API externe|Prévisualiser" packages/map_editor/test -g '*.dart'`
- `sed -n '1,320p' packages/map_editor/test/pokedex_workspace_ui_test.dart`
- `sed -n '2000,2285p' packages/map_editor/test/pokedex_workspace_ui_test.dart`
- `sed -n '1,260p' packages/map_editor/test/pokemon_external_query_resolver_test.dart`
- `sed -n '1,320p' packages/map_editor/lib/src/infrastructure/external/pokeapi_live_source.dart`
- `sed -n '1,340p' packages/map_editor/lib/src/infrastructure/external/showdown_snapshot_source.dart`
- `sed -n '1,320p' packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart`
- `sed -n '1,380p' packages/map_editor/lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart`
- `rg -n "fetchPokedexSnapshot|fetchSpecies\(|movesSnapshot|autocomplete|suggest" packages/map_editor/lib packages/map_editor/test -g '*.dart'`
- `sed -n '1,240p' packages/map_editor/test/showdown_snapshot_source_test.dart`
- `sed -n '1,220p' packages/map_editor/test/http_pokemon_external_source_repository_test.dart`
- `sed -n '1,240p' packages/map_editor/lib/src/application/use_cases/use_cases.dart`
- `rg -n "implements PokemonExternalSourceRepository" packages/map_editor/test packages/map_editor/lib -g '*.dart'`
- `rg -n "ProgressCircle\(|AutocompleteHighlightedOption|RawAutocomplete|dividerSubtle\(|subtleLabelStatic" packages/map_editor/lib/src/ui/canvas/pokedex_workspace packages/map_editor/lib/src/ui/shared -g '*.dart'`
- `sed -n '1,220p' packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart`
- `sed -n '1110,1215p' packages/map_editor/test/import_external_pokemon_use_cases_test.dart`
- `sed -n '120,230p' packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart`
- `sed -n '12,45p' packages/map_editor/test/provider_wiring_test.dart`
- `sed -n '1,220p' packages/map_editor/test/pokedex_external_autocomplete_ui_test.dart`
- `sed -n '220,420p' packages/map_editor/test/pokedex_external_autocomplete_ui_test.dart`
- `sed -n '1,320p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_external_search_field.dart`
- `sed -n '1,260p' packages/map_editor/lib/src/application/use_cases/search_external_pokemon_species_use_case.dart`
- `dart format <fichiers touchés du lot 2>`
- `flutter analyze --no-pub lib/src/application/models/pokemon_external_species_search_result.dart lib/src/application/use_cases/search_external_pokemon_species_use_case.dart lib/src/application/ports/pokemon_external_source_repository.dart lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart lib/src/application/use_cases/use_cases.dart lib/src/ui/canvas/pokedex_workspace_loader.dart lib/src/app/providers/pokedex/pokedex_providers.dart lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart test/search_external_pokemon_species_use_case_test.dart test/http_pokemon_external_source_repository_test.dart test/import_external_pokemon_use_cases_test.dart test/sync_pokemon_moves_catalog_use_case_test.dart test/provider_wiring_test.dart test/pokedex_workspace_ui_test.dart test/pokedex_external_autocomplete_ui_test.dart`
- `flutter test test/search_external_pokemon_species_use_case_test.dart test/http_pokemon_external_source_repository_test.dart test/provider_wiring_test.dart test/pokedex_external_autocomplete_ui_test.dart`
- `flutter test test/pokedex_workspace_ui_test.dart --plain-name "imports a pokemon from API externe and refreshes the workspace"`
- `git status --short`
- `git diff --stat`
- `git ls-files --others --exclude-standard`

## 9. Résultats réels

- `dart format ...`
  - `Formatted /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart`
  - `Formatted /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart`
  - `Formatted /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_external_search_field.dart`
  - `Formatted /Users/karim/Project/pokemonProject/packages/map_editor/test/search_external_pokemon_species_use_case_test.dart`
  - `Formatted /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart`
  - `Formatted /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_external_autocomplete_ui_test.dart`
  - `Formatted 19 files (6 changed) in 0.06 seconds.`
  - puis `Formatted 2 files (0 changed) in 0.01 seconds.`
  - puis `Formatted 1 file (0 changed) in 0.01 seconds.`
  - puis `Formatted 1 file (1 changed) in 0.01 seconds.`
  - puis plusieurs relances ciblées `Formatted 1 file (0 changed) in 0.01 seconds.` après ajustements.
- `flutter analyze --no-pub ...`
  - premier passage utile après mise en place : `No issues found! (ran in 1.7s)`
  - passage final après correctifs du widget : `No issues found! (ran in 1.5s)`
- `flutter test test/search_external_pokemon_species_use_case_test.dart test/http_pokemon_external_source_repository_test.dart test/provider_wiring_test.dart test/pokedex_external_autocomplete_ui_test.dart`
  - résultat final : `00:03 +14: All tests passed!`
- `flutter test test/pokedex_workspace_ui_test.dart --plain-name "imports a pokemon from API externe and refreshes the workspace"`
  - résultat final : `00:02 +1: All tests passed!`

## 10. Incidents rencontrés

1. Premier essai de validation en parallèle : Flutter a bloqué sur un verrou de démarrage et une suppression dans `macos/Flutter/ephemeral/Packages/.packages`. J’ai basculé sur des validations séquentielles pour garder des résultats fiables.
2. Premier harness du nouveau test widget : le sheet macOS exigeait `MaterialLocalizations`. Le harness a été corrigé pour utiliser `MacosApp` au lieu d’un host Cupertino trop léger.
3. Première implémentation UI via `RawAutocomplete` : les suggestions asynchrones n’apparaissaient pas de façon fiable. J’ai remplacé cette dépendance par une liste locale contrôlée, plus honnête pour ce wizard précis et plus testable, tout en gardant navigation clavier/souris et sélection explicite.

## 11. État git utile

### `git status --short`

```text
M packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart
 M packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart
 M packages/map_editor/lib/src/application/use_cases/use_cases.dart
 M packages/map_editor/lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart
 M packages/map_editor/test/http_pokemon_external_source_repository_test.dart
 M packages/map_editor/test/import_external_pokemon_use_cases_test.dart
 M packages/map_editor/test/pokedex_workspace_ui_test.dart
 M packages/map_editor/test/provider_wiring_test.dart
 M packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart
?? packages/map_editor/lib/src/application/models/pokemon_external_species_search_result.dart
?? packages/map_editor/lib/src/application/use_cases/search_external_pokemon_species_use_case.dart
?? packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_external_search_field.dart
?? packages/map_editor/test/pokedex_external_autocomplete_ui_test.dart
?? packages/map_editor/test/search_external_pokemon_species_use_case_test.dart
?? reports/phase-r1-lot-2-pokedex-external-autocomplete-report.md
```

### `git diff --stat`

```text
.../app/providers/pokedex/pokedex_providers.dart   |  22 +++++
 .../ports/pokemon_external_source_repository.dart  |   8 ++
 .../lib/src/application/use_cases/use_cases.dart   |   1 +
 .../http_pokemon_external_source_repository.dart   |   5 +
 .../pokedex_workspace/pokedex_import_flow.dart     | 101 +++++++++++++++++++--
 .../pokedex_import_flow_steps.dart                 |  31 +++++--
 .../pokedex_workspace/pokedex_workspace_body.dart  |   1 +
 .../pokedex_workspace/pokedex_workspace_page.dart  |  10 ++
 .../src/ui/canvas/pokedex_workspace_loader.dart    |   6 ++
 ...tp_pokemon_external_source_repository_test.dart |   2 +
 .../import_external_pokemon_use_cases_test.dart    |  12 +++
 .../map_editor/test/pokedex_workspace_ui_test.dart |  77 +++++++++++++++-
 packages/map_editor/test/provider_wiring_test.dart |   5 +
 .../sync_pokemon_moves_catalog_use_case_test.dart  |   5 +
 14 files changed, 269 insertions(+), 17 deletions(-)
```

### `git ls-files --others --exclude-standard`

```text
packages/map_editor/lib/src/application/models/pokemon_external_species_search_result.dart
packages/map_editor/lib/src/application/use_cases/search_external_pokemon_species_use_case.dart
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_external_search_field.dart
packages/map_editor/test/pokedex_external_autocomplete_ui_test.dart
packages/map_editor/test/search_external_pokemon_species_use_case_test.dart
reports/phase-r1-lot-2-pokedex-external-autocomplete-report.md
```

## 12. Checklist finale

- [x] Le résolveur du lot 1 est réutilisé
- [x] Aucun second pipeline Pokédex n’a été créé
- [x] Aucune logique métier significative n’a été déplacée dans l’UI
- [x] La branche `API externe` propose des suggestions mono-espèce
- [x] Une sélection explicite est obligatoire avant preview/import
- [x] Les requêtes hors-scope (`gen 1`, `1-151`, `pikachu,eevee`) sont reconnues et refusées proprement
- [x] Les états vide / loading / no result / invalid / hors-scope sont visibles
- [x] Navigation souris OK
- [x] Navigation clavier honnête au minimum OK
- [x] `dart format` exécuté
- [x] `flutter analyze --no-pub` ciblé exécuté et vert
- [x] `flutter test` ciblé exécuté et vert
- [x] Aucun commit git n’a été fait

## 13. Annexe — contenu complet de tous les fichiers texte modifiés / créés


### `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../application/ports/pokemon_read_repository.dart';
import '../../../application/ports/pokemon_external_source_repository.dart';
import '../../../application/ports/pokemon_write_repository.dart';
import '../../../application/services/pokemon_database_index.dart';
import '../../../application/services/pokemon_external_query_resolver.dart';
import '../../../application/use_cases/import_external_pokemon_use_cases.dart';
import '../../../application/use_cases/import_pokemon_evolution_json_use_case.dart';
import '../../../application/use_cases/import_pokemon_json_bundle_use_case.dart';
import '../../../application/use_cases/import_pokemon_learnset_json_use_case.dart';
import '../../../application/use_cases/import_pokemon_media_json_use_case.dart';
import '../../../application/use_cases/import_pokemon_species_json_use_case.dart';
import '../../../application/use_cases/search_external_pokemon_species_use_case.dart';
import '../../../application/use_cases/delete_pokedex_species_use_case.dart';
import '../../../application/use_cases/load_pokedex_species_detail_use_case.dart';
import '../../../application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
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

/// Résolveur de requête brute -> intention structurée pour l'import externe.
///
/// Ce provider est volontairement minimal pour le lot 1 :
/// - il expose une logique pure ;
/// - il n'ajoute ni réseau, ni preview, ni import ;
/// - il prépare simplement le wiring propre des lots UI suivants.
final pokemonExternalQueryResolverProvider =
    Provider<PokemonExternalQueryResolver>((ref) {
  return const PokemonExternalQueryResolver();
});

/// Recherche mono-espèce appliquée au wizard Pokédex.
///
/// On garde cette couche très petite :
/// - elle réutilise le résolveur du lot 1 ;
/// - elle réutilise le port externe déjà en place ;
/// - elle ne crée pas de pipeline de recherche parallèle.
final searchExternalPokemonSpeciesUseCaseProvider =
    Provider<SearchExternalPokemonSpeciesUseCase>((ref) {
  return SearchExternalPokemonSpeciesUseCase(
    externalSourceRepository:
        ref.watch(pokemonExternalSourceRepositoryProvider),
    queryResolver: ref.watch(pokemonExternalQueryResolverProvider),
  );
});

final pokedexExternalSpeciesSearcherProvider =
    Provider<PokedexExternalSpeciesSearcher>((ref) {
  final useCase = ref.watch(searchExternalPokemonSpeciesUseCaseProvider);
  return useCase.execute;
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

final deletePokedexSpeciesUseCaseProvider =
    Provider<DeletePokedexSpeciesUseCase>((ref) {
  return DeletePokedexSpeciesUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
  );
});

final pokedexSpeciesDeleterProvider = Provider<PokedexSpeciesDeleter>((ref) {
  final useCase = ref.watch(deletePokedexSpeciesUseCaseProvider);
  return (workspace, speciesId) => useCase.execute(workspace, speciesId);
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

final loadPokemonMovesCatalogUseCaseProvider =
    Provider<LoadPokemonMovesCatalogUseCase>((ref) {
  return LoadPokemonMovesCatalogUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
  );
});

final syncExternalPokemonMovesCatalogUseCaseProvider =
    Provider<SyncExternalPokemonMovesCatalogUseCase>((ref) {
  return SyncExternalPokemonMovesCatalogUseCase(
    externalSourceRepository:
        ref.watch(pokemonExternalSourceRepositoryProvider),
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexMovesCatalogLoaderProvider =
    Provider<PokedexMovesCatalogLoader>((ref) {
  final useCase = ref.watch(loadPokemonMovesCatalogUseCaseProvider);
  return (workspace) => useCase.execute(workspace);
});

final pokedexMovesCatalogPreviewerProvider =
    Provider<PokedexMovesCatalogPreviewer>((ref) {
  final useCase = ref.watch(syncExternalPokemonMovesCatalogUseCaseProvider);
  return (workspace) => useCase.execute(workspace, dryRun: true);
});

final pokedexMovesCatalogSyncerProvider =
    Provider<PokedexMovesCatalogSyncer>((ref) {
  final useCase = ref.watch(syncExternalPokemonMovesCatalogUseCaseProvider);
  return (workspace) => useCase.execute(workspace);
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
  /// Charge le snapshot Pokédex global structuré depuis la source Showdown.
  ///
  /// Cette lecture supplémentaire reste dans le même port externe historique :
  /// - on ne crée pas un second système de recherche externe ;
  /// - le wizard mono-espèce peut réutiliser la source snapshot existante ;
  /// - la logique de suggestion reste applicative, pas UI.
  Future<Map<String, dynamic>> fetchShowdownPokedexSnapshot();

  Future<Map<String, dynamic>> fetchShowdownSpeciesPayload(String speciesId);

  /// Charge le snapshot global des moves depuis la source structurée
  /// complémentaire déjà utilisée par la 11A.
  ///
  /// Cette extension est volontairement minimale :
  /// - on n'introduit pas un second port "catalogue moves" parallèle ;
  /// - on réutilise la même frontière externe que l'import Pokémon 11A ;
  /// - l'orchestration 11B reste ainsi branchée sur le pipeline existant.
  ///
  /// Non-objectifs explicites :
  /// - aucun parsing dans l'UI ;
  /// - aucune logique de merge ici ;
  /// - aucune dépendance directe de l'application à l'URL Showdown.
  Future<Map<String, dynamic>> fetchShowdownMovesSnapshot();

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

### `packages/map_editor/lib/src/application/use_cases/use_cases.dart`

```dart
export 'character_use_cases.dart';
export 'collision_use_cases.dart';
export 'delete_pokedex_species_use_case.dart';
export 'encounter_table_use_cases.dart';
export 'trainer_use_cases.dart';
export 'gameplay_zone_use_cases.dart';
export 'initialize_pokemon_project_storage_use_case.dart';
export 'import_pokemon_catalog_json_use_case.dart';
export 'import_pokemon_evolution_json_use_case.dart';
export 'import_pokemon_json_bundle_use_case.dart';
export 'import_external_pokemon_use_cases.dart';
export 'import_pokemon_learnset_json_use_case.dart';
export 'import_pokemon_media_json_use_case.dart';
export 'import_pokemon_species_json_use_case.dart';
export 'layer_use_cases.dart';
export 'list_pokedex_entries_use_case.dart';
export 'load_pokedex_species_detail_use_case.dart';
export 'map_use_cases.dart';
export 'paint_use_cases.dart';
export 'path_layer_use_cases.dart';
export 'project_element_use_cases.dart';
export 'project_group_use_cases.dart';
export 'project_management_use_cases.dart';
export 'project_scenario_use_cases.dart';
export 'project_tileset_use_cases.dart';
export 'seed_pokemon_demo_data_use_case.dart';
export 'search_external_pokemon_species_use_case.dart';
export 'sync_pokemon_moves_catalog_use_case.dart';
export 'terrain_preset_use_cases.dart';
export 'terrain_use_cases.dart';
export 'update_pokedex_species_evolution_use_case.dart';
export 'update_pokedex_species_forms_classification_use_case.dart';
export 'update_pokedex_species_learnset_use_case.dart';
export 'update_pokedex_species_metadata_use_case.dart';
export 'update_pokedex_species_media_use_case.dart';
export 'validate_pokemon_project_data_use_case.dart';
export 'warp_use_cases.dart';

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
  Future<Map<String, dynamic>> fetchShowdownPokedexSnapshot() {
    return showdownSource.fetchPokedexSnapshot();
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownSpeciesPayload(
    String speciesId,
  ) {
    return showdownSource.fetchSpecies(speciesId);
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownMovesSnapshot() {
    return showdownSource.fetchMovesSnapshot();
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
  required PokedexExternalSpeciesSearcher searchExternalSpecies,
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
      searchExternalSpecies: searchExternalSpecies,
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
    required this.searchExternalSpecies,
    required this.previewExternalImport,
    required this.importExternalPokemon,
    required this.pickJsonSourceFile,
  });

  final ProjectWorkspace workspace;
  final PokedexImportPreviewer previewImport;
  final PokedexImporter importPokemon;
  final PokedexExternalSpeciesSearcher searchExternalSpecies;
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
  bool _isSearchingExternalSpecies = false;
  String? _errorMessage;
  late final TextEditingController _externalQueryController;
  late final FocusNode _externalQueryFocusNode;
  Timer? _externalQueryDebounceTimer;
  int _externalQuerySearchRequestId = 0;
  PokemonExternalSpeciesSearchResult _externalSpeciesSearchResult =
      const PokemonExternalSpeciesSearchResult.empty(
    rawQuery: '',
    normalizedQuery: '',
  );
  PokemonExternalSpeciesSuggestion? _selectedExternalSuggestion;

  @override
  void initState() {
    super.initState();
    _externalQueryController = TextEditingController();
    _externalQueryFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _externalQueryDebounceTimer?.cancel();
    _externalQueryController.dispose();
    _externalQueryFocusNode.dispose();
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

  void _handleExternalQueryChanged(String rawQuery) {
    _externalQueryDebounceTimer?.cancel();
    final normalizedQuery = rawQuery.trim();

    if (normalizedQuery.isEmpty) {
      setState(() {
        _selectedExternalSuggestion = null;
        _isSearchingExternalSpecies = false;
        _externalSpeciesSearchResult = PokemonExternalSpeciesSearchResult.empty(
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
        );
        _errorMessage = null;
      });
      return;
    }

    final requestId = ++_externalQuerySearchRequestId;
    setState(() {
      _selectedExternalSuggestion = null;
      _isSearchingExternalSpecies = true;
      _externalSpeciesSearchResult = PokemonExternalSpeciesSearchResult.empty(
        rawQuery: rawQuery,
        normalizedQuery: normalizedQuery,
      );
      _errorMessage = null;
    });

    // Un petit debounce UI suffit ici :
    // - il évite de re-solliciter la recherche à chaque caractère sur desktop ;
    // - il ne déplace aucune logique métier dans l'UI ;
    // - le vrai contrat métier reste dans le résolveur + use case applicatif.
    _externalQueryDebounceTimer =
        Timer(const Duration(milliseconds: 180), () async {
      final result = await widget.searchExternalSpecies(rawQuery);
      if (!mounted || requestId != _externalQuerySearchRequestId) {
        return;
      }
      setState(() {
        _isSearchingExternalSpecies = false;
        _externalSpeciesSearchResult = result;
      });
      // `RawAutocomplete` écoute d'abord le contrôleur texte.
      // Les suggestions de cette étape arrivent après un aller-retour
      // asynchrone ; on réémet donc explicitement l'état du champ pour que
      // l'overlay se recalculе sans inventer de logique métier côté widget.
      _externalQueryController.notifyListeners();
    });
  }

  void _handleExternalSuggestionSelected(
    PokemonExternalSpeciesSuggestion suggestion,
  ) {
    _externalQueryDebounceTimer?.cancel();
    _externalQuerySearchRequestId += 1;
    setState(() {
      _selectedExternalSuggestion = suggestion;
      _isSearchingExternalSpecies = false;
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
          final selectedSuggestion = _selectedExternalSuggestion;
          if (selectedSuggestion == null) {
            throw const EditorValidationException(
              'Sélectionnez explicitement une espèce externe avant de prévisualiser.',
            );
          }
          final preview = await widget.previewExternalImport(
            widget.workspace,
            selectedSuggestion.speciesId,
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
          final selectedSuggestion = _selectedExternalSuggestion;
          if (selectedSuggestion == null) {
            throw const EditorValidationException(
              'Sélectionnez explicitement une espèce externe avant d’importer.',
            );
          }
          final result = await widget.importExternalPokemon(
            widget.workspace,
            selectedSuggestion.speciesId,
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
    // Le sheet macOS fournit le cadre général, mais pas de marge interne forte.
    // On ajoute donc ici un padding commun à tout le wizard :
    // - même respiration sur chaque étape ;
    // - aucun besoin de répéter des `Padding` différents dans chaque widget ;
    // - correction purement visuelle, sans toucher à la logique du flow.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: switch (_step) {
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
        _PokedexImportWizardStep.externalQuery =>
          _PokedexImportExternalQueryStep(
            controller: _externalQueryController,
            focusNode: _externalQueryFocusNode,
            isBusy: _isBusy,
            isSearching: _isSearchingExternalSpecies,
            errorMessage: _errorMessage,
            searchResult: _externalSpeciesSearchResult,
            selectedSuggestion: _selectedExternalSuggestion,
            onQueryChanged: _handleExternalQueryChanged,
            onSuggestionSelected: _handleExternalSuggestionSelected,
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
      },
    );
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
    required this.focusNode,
    required this.isBusy,
    required this.isSearching,
    required this.errorMessage,
    required this.searchResult,
    required this.selectedSuggestion,
    required this.onQueryChanged,
    required this.onSuggestionSelected,
    required this.onContinue,
    required this.onCancel,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isBusy;
  final bool isSearching;
  final String? errorMessage;
  final PokemonExternalSpeciesSearchResult searchResult;
  final PokemonExternalSpeciesSuggestion? selectedSuggestion;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<PokemonExternalSpeciesSuggestion> onSuggestionSelected;
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
        _PokedexExternalSpeciesAutocompleteField(
          controller: controller,
          focusNode: focusNode,
          isBusy: isBusy,
          isSearching: isSearching,
          searchResult: searchResult,
          selectedSuggestion: selectedSuggestion,
          onQueryChanged: onQueryChanged,
          onSuggestionSelected: onSuggestionSelected,
        ),
        const SizedBox(height: 10),
        Text(
          'La source visible reste “API externe”. Les détails techniques PokeAPI / Showdown restent internes au pipeline. La prévisualisation reste bloquée tant qu’une suggestion n’a pas été sélectionnée explicitement.',
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
              onPressed: isBusy || isSearching || selectedSuggestion == null
                  ? null
                  : onContinue,
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
                projectRootPath: projectRootPath,
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
                onDeleteSpecies: _deleteSpecies,
                onSaveMetadata: _saveMetadata,
                onSaveFormsClassification: _saveFormsClassification,
                onSaveLearnset: _saveLearnset,
                onSaveEvolution: _saveEvolution,
                onSaveMedia: _saveMedia,
                onLoadMovesCatalog: _loadMovesCatalog,
                onPreviewMovesCatalogSync: _previewMovesCatalogSync,
                onSyncMovesCatalog: _syncMovesCatalog,
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
      searchExternalSpecies: widget.externalSpeciesSearcher,
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

  Future<PokemonMovesCatalogView> _loadMovesCatalog() async {
    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      throw StateError(
        'Cannot load the local moves catalog without a loaded project',
      );
    }

    return widget.movesCatalogLoader(ProjectFileSystem(projectRootPath));
  }

  Future<PokemonMovesCatalogSyncResult> _previewMovesCatalogSync() async {
    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      throw StateError(
        'Cannot preview the moves catalog sync without a loaded project',
      );
    }

    return widget.movesCatalogPreviewer(ProjectFileSystem(projectRootPath));
  }

  Future<PokemonMovesCatalogSyncResult> _syncMovesCatalog() async {
    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      throw StateError(
        'Cannot sync the moves catalog without a loaded project',
      );
    }

    return widget.movesCatalogSyncer(ProjectFileSystem(projectRootPath));
  }

  Future<void> _deleteSpecies(PokemonDatabaseIndexEntry entry) async {
    final confirmed = await showMacosEditorTwoChoiceAlert(
      context,
      title: 'Supprimer cette espèce ?',
      message:
          'Supprimer ${entry.primaryName} effacera l’espèce locale et ses fichiers Pokédex associés (learnset, évolutions, médias référencés). Cette action ne touche pas au runtime ni à project.json.',
      primaryLabel: 'Supprimer',
      secondaryLabel: 'Annuler',
      primaryIsDestructive: true,
      icon: CupertinoIcons.delete_solid,
    );
    if (!confirmed || !mounted) {
      return;
    }

    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      throw StateError(
        'Cannot delete local Pokemon data without a loaded project',
      );
    }

    final workspace = ProjectFileSystem(projectRootPath);
    try {
      final result = await widget.deleteSpecies(workspace, entry.id);
      if (!mounted) {
        return;
      }

      // La suppression doit recharger la liste depuis la même source de vérité
      // disque que le reste du workspace.
      //
      // On ne tente pas d'enlever la ligne "à la main" dans l'état local,
      // parce que cela créerait immédiatement un cache parallèle fragile.
      setState(() {
        _entriesFuture = _buildEntriesFuture();
        _selectedSpeciesId = null;
        _detailFuture = null;
        _selectedDetailTabId = _overviewTabId;
      });
      _showFeedback(
        '${result.primaryName} a été supprimé du Pokédex local.',
        isError: false,
      );
    } on EditorApplicationException catch (error) {
      if (!mounted) {
        return;
      }
      _showFeedback(error.message, isError: true);
    }
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
import 'dart:io';

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
import '../../../application/models/pokemon_external_species_search_result.dart';
import '../../../application/models/pokemon_project_data_models.dart';
import '../../../application/ports/project_workspace.dart';
import '../../../application/use_cases/delete_pokedex_species_use_case.dart';
import '../../../application/use_cases/import_external_pokemon_use_cases.dart';
import '../../../application/use_cases/import_pokemon_json_bundle_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_evolution_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_forms_classification_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_learnset_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_media_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_metadata_use_case.dart';
import '../../../application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
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
part 'pokedex_external_search_field.dart';
part 'pokedex_detail_panel.dart';
part 'pokedex_overview_panel.dart';
part 'pokedex_metadata_editor.dart';
part 'pokedex_metadata_editor_fields.dart';
part 'pokedex_forms_panel.dart';
part 'pokedex_learnset_panel.dart';
part 'pokedex_learnset_sections.dart';
part 'pokedex_moves_catalog_section.dart';
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
    this.externalSpeciesSearcher,
    this.pickJsonImportFile,
    this.deleteSpecies,
    this.metadataSaver,
    this.formsClassificationSaver,
    this.learnsetSaver,
    this.evolutionSaver,
    this.mediaSaver,
    this.movesCatalogLoader,
    this.movesCatalogPreviewer,
    this.movesCatalogSyncer,
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
  final PokedexExternalSpeciesSearcher? externalSpeciesSearcher;
  final Future<String?> Function()? pickJsonImportFile;
  final PokedexSpeciesDeleter? deleteSpecies;
  final PokedexSpeciesMetadataSaver? metadataSaver;
  final PokedexSpeciesFormsClassificationSaver? formsClassificationSaver;
  final PokedexSpeciesLearnsetSaver? learnsetSaver;
  final PokedexSpeciesEvolutionSaver? evolutionSaver;
  final PokedexSpeciesMediaSaver? mediaSaver;
  final PokedexMovesCatalogLoader? movesCatalogLoader;
  final PokedexMovesCatalogPreviewer? movesCatalogPreviewer;
  final PokedexMovesCatalogSyncer? movesCatalogSyncer;

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
    final PokedexExternalSpeciesSearcher resolvedExternalSpeciesSearcher =
        externalSpeciesSearcher ??
            ref.watch(pokedexExternalSpeciesSearcherProvider);
    final PokedexSpeciesDeleter resolvedDeleteSpecies =
        deleteSpecies ?? ref.watch(pokedexSpeciesDeleterProvider);
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
    final PokedexMovesCatalogLoader resolvedMovesCatalogLoader =
        movesCatalogLoader ?? ref.watch(pokedexMovesCatalogLoaderProvider);
    final PokedexMovesCatalogPreviewer resolvedMovesCatalogPreviewer =
        movesCatalogPreviewer ??
            ref.watch(pokedexMovesCatalogPreviewerProvider);
    final PokedexMovesCatalogSyncer resolvedMovesCatalogSyncer =
        movesCatalogSyncer ?? ref.watch(pokedexMovesCatalogSyncerProvider);

    return _PokedexWorkspaceBody(
      projectRootPath: projectRootPath,
      loader: resolvedLoader,
      detailLoader: resolvedDetailLoader,
      importPreviewer: resolvedImportPreviewer,
      importer: resolvedImporter,
      externalImportPreviewer: resolvedExternalImportPreviewer,
      externalImporter: resolvedExternalImporter,
      externalSpeciesSearcher: resolvedExternalSpeciesSearcher,
      pickJsonImportFile: pickJsonImportFile,
      deleteSpecies: resolvedDeleteSpecies,
      metadataSaver: resolvedMetadataSaver,
      formsClassificationSaver: resolvedFormsClassificationSaver,
      learnsetSaver: resolvedLearnsetSaver,
      evolutionSaver: resolvedEvolutionSaver,
      mediaSaver: resolvedMediaSaver,
      movesCatalogLoader: resolvedMovesCatalogLoader,
      movesCatalogPreviewer: resolvedMovesCatalogPreviewer,
      movesCatalogSyncer: resolvedMovesCatalogSyncer,
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
    required this.externalSpeciesSearcher,
    required this.pickJsonImportFile,
    required this.deleteSpecies,
    required this.metadataSaver,
    required this.formsClassificationSaver,
    required this.learnsetSaver,
    required this.evolutionSaver,
    required this.mediaSaver,
    required this.movesCatalogLoader,
    required this.movesCatalogPreviewer,
    required this.movesCatalogSyncer,
  });

  final String? projectRootPath;
  final PokedexEntryLoader loader;
  final PokedexSpeciesDetailLoader detailLoader;
  final PokedexImportPreviewer importPreviewer;
  final PokedexImporter importer;
  final PokedexExternalImportPreviewer externalImportPreviewer;
  final PokedexExternalImporter externalImporter;
  final PokedexExternalSpeciesSearcher externalSpeciesSearcher;
  final Future<String?> Function()? pickJsonImportFile;
  final PokedexSpeciesDeleter deleteSpecies;
  final PokedexSpeciesMetadataSaver metadataSaver;
  final PokedexSpeciesFormsClassificationSaver formsClassificationSaver;
  final PokedexSpeciesLearnsetSaver learnsetSaver;
  final PokedexSpeciesEvolutionSaver evolutionSaver;
  final PokedexSpeciesMediaSaver mediaSaver;
  final PokedexMovesCatalogLoader movesCatalogLoader;
  final PokedexMovesCatalogPreviewer movesCatalogPreviewer;
  final PokedexMovesCatalogSyncer movesCatalogSyncer;

  @override
  State<_PokedexWorkspaceBody> createState() => _PokedexWorkspaceBodyState();
}

```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart`

```dart
import 'dart:io';

import '../../application/models/pokemon_database_index.dart';
import '../../application/models/pokemon_external_species_search_result.dart';
import '../../application/models/pokedex_species_detail.dart';
import '../../application/ports/project_workspace.dart';
import '../../application/use_cases/import_external_pokemon_use_cases.dart';
import '../../application/use_cases/import_pokemon_json_bundle_use_case.dart';
import '../../application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
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

typedef PokedexExternalSpeciesSearcher
    = Future<PokemonExternalSpeciesSearchResult> Function(
  String rawQuery,
);

typedef PokedexMovesCatalogLoader = Future<PokemonMovesCatalogView> Function(
  ProjectWorkspace workspace,
);

typedef PokedexMovesCatalogPreviewer = Future<PokemonMovesCatalogSyncResult>
    Function(
  ProjectWorkspace workspace,
);

typedef PokedexMovesCatalogSyncer = Future<PokemonMovesCatalogSyncResult>
    Function(
  ProjectWorkspace workspace,
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
      if (request.url.toString() == 'https://showdown.test/data/moves.json') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'thunderbolt': <String, Object?>{'name': 'Thunderbolt'},
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

    final pokedexSnapshot = await repository.fetchShowdownPokedexSnapshot();
    final showdown = await repository.fetchShowdownSpeciesPayload('bulbasaur');
    final movesSnapshot = await repository.fetchShowdownMovesSnapshot();
    final pokemon = await repository.fetchPokeApiPokemonPayload('bulbasaur');
    final pokemonSpecies =
        await repository.fetchPokeApiPokemonSpeciesPayload('bulbasaur');
    final evolution =
        await repository.fetchPokeApiEvolutionChainPayload('bulbasaur');
    final asset = await repository.fetchBinaryAsset(
      'https://assets.test/front.png',
    );

    expect(pokedexSnapshot.containsKey('bulbasaur'), isTrue);
    expect(showdown['name'], 'Bulbasaur');
    expect(movesSnapshot.containsKey('thunderbolt'), isTrue);
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
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/ports/pokemon_write_repository.dart';
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
        'fail_on_conflict stays atomic even when only one artefact already exists',
        () async {
      final beforeProjectJson = await projectFile.readAsString();

      // On provoque ici le cas le plus intéressant du point de vue produit :
      // un conflit partiel. Si l'atomicité promise par le use case casse,
      // l'import pourrait écrire learnset/evolution/media alors que l'espèce
      // principale est en conflit, ce qui rendrait le résultat trompeur.
      await writeRepository.saveSpecies(
        workspace,
        const ShowdownPokemonSpeciesConverter().convert(
          jsonDecode(_bulbasaurShowdownPayload) as Map<String, dynamic>,
        ),
      );

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
      );

      expect(result.hasConflicts, isTrue);
      expect(result.hasWritesApplied, isFalse);
      expect(
        result.artifacts
            .firstWhere(
              (artifact) =>
                  artifact.kind == PokemonExternalImportArtifactKind.species,
            )
            .action,
        PokemonExternalImportArtifactAction.conflict,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/learnsets/bulbasaur.json',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/evolutions/bulbasaur.json',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/media/bulbasaur.json',
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

    test(
        'omits a missing media asset ref from media.json while keeping the rest coherent',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository.binaryAssets
          .remove('https://assets.example.test/bulbasaur/portrait.png');

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');
      final baseVariant = media.variants['base']!;

      expect(baseVariant.portrait, isNull);
      expect(baseVariant.frontStatic,
          'assets/pokemon/sprites/bulbasaur/front.png');
      expect(baseVariant.cry, 'assets/pokemon/cries/bulbasaur.ogg');
      expect(baseVariant.icon, isNull);
      expect(baseVariant.party, isNull);
      expect(baseVariant.overworld, isNull);
      expect(baseVariant.animations, isEmpty);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        result.warnings.join('\n'),
        contains('Portrait download failed'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'keeps species learnset and evolution when all media downloads fail and writes no ghost refs',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository.binaryAssets.clear();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');
      final baseVariant = media.variants['base']!;

      expect(result.importedSpecies, isTrue);
      expect(result.importedLearnset, isTrue);
      expect(result.importedEvolution, isTrue);
      expect(result.downloadedAssetCount, 0);
      expect(baseVariant.portrait, isNull);
      expect(baseVariant.frontStatic, isNull);
      expect(baseVariant.backStatic, isNull);
      expect(baseVariant.frontShinyStatic, isNull);
      expect(baseVariant.backShinyStatic, isNull);
      expect(baseVariant.icon, isNull);
      expect(baseVariant.party, isNull);
      expect(baseVariant.overworld, isNull);
      expect(baseVariant.cry, isNull);
      expect(baseVariant.animations, isEmpty);
      expect(result.warnings.join('\n'), contains('download failed'));
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'skip_existing does not download new assets when media.json is already skipped',
        () async {
      final beforeProjectJson = await projectFile.readAsString();

      // Ce cas verrouille précisément le coin restant du mini-fix 2 :
      // - `media.json` existe déjà, donc l'artefact media doit être `skip` ;
      // - aucun asset local n'existe encore ;
      // - si le pipeline continue malgré tout à télécharger les binaires,
      //   ils deviennent orphelins parce que le `media.json` conservé ne sera
      //   jamais réécrit dans ce run.
      //
      // On prépare donc volontairement un `media.json` minimal qui ne référence
      // aucun asset. Si l'import écrit ensuite des portraits/sprites/cries alors
      // que le JSON média est skippé, le bug est réel et reproductible.
      await writeRepository.saveMedia(
        workspace,
        const PokemonMediaFile(
          speciesId: 'bulbasaur',
          defaultFormId: 'base',
          variants: <String, PokemonMediaVariant>{
            'base': PokemonMediaVariant(),
          },
        ),
      );

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.skipExisting,
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(
        result.artifacts
            .firstWhere(
              (artifact) =>
                  artifact.kind == PokemonExternalImportArtifactKind.media,
            )
            .action,
        PokemonExternalImportArtifactAction.skip,
      );
      expect(result.downloadedAssetCount, 0);
      expect(result.downloadedAssets, isEmpty);
      expect(media.variants['base']?.portrait, isNull);
      expect(media.variants['base']?.frontStatic, isNull);
      expect(media.variants['base']?.backStatic, isNull);
      expect(media.variants['base']?.cry, isNull);
      expect(
        result.warnings.join('\n'),
        contains('media.json'),
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/sprites/bulbasaur/front.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/cries/bulbasaur.ogg',
          ),
        ).exists(),
        isFalse,
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'skip_existing keeps a pre-existing local asset ref without re-downloading it',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      final portraitFile = File(
        workspace.resolveProjectRelativePath(
          'assets/pokemon/portraits/bulbasaur.png',
        ),
      );
      await portraitFile.parent.create(recursive: true);
      await portraitFile.writeAsBytes(const <int>[200, 201, 202]);

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.skipExisting,
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');
      final portraitResult = result.downloadedAssets.firstWhere(
        (asset) => asset.label == 'Portrait',
      );

      expect(media.variants['base']?.portrait,
          'assets/pokemon/portraits/bulbasaur.png');
      expect(await portraitFile.readAsBytes(), const <int>[200, 201, 202]);
      expect(portraitResult.wasWritten, isFalse);
      expect(portraitResult.existedBefore, isTrue);
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'overwrite_existing keeps an existing local asset ref when redownload fails',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      final portraitFile = File(
        workspace.resolveProjectRelativePath(
          'assets/pokemon/portraits/bulbasaur.png',
        ),
      );
      await portraitFile.parent.create(recursive: true);
      await portraitFile.writeAsBytes(const <int>[77, 88, 99]);
      externalSourceRepository.binaryAssets
          .remove('https://assets.example.test/bulbasaur/portrait.png');

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.portrait,
          'assets/pokemon/portraits/bulbasaur.png');
      expect(await portraitFile.readAsBytes(), const <int>[77, 88, 99]);
      expect(
        result.warnings.join('\n'),
        contains('existing local asset was kept'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('rejects incompatible image content-types without persisting a ref',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository.binaryAssets[
              'https://assets.example.test/bulbasaur/portrait.png'] =
          PokemonExternalBinaryAsset(
        sourceUrl: 'https://assets.example.test/bulbasaur/portrait.png',
        bytes: Uint8List.fromList(<int>[9, 9, 9, 9]),
        contentType: 'image/jpeg',
      );

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.portrait, isNull);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        result.warnings.join('\n'),
        contains('incompatible content-type (image/jpeg)'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'overwrite_existing keeps a local image when redownload content-type is incompatible',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      final portraitFile = File(
        workspace.resolveProjectRelativePath(
          'assets/pokemon/portraits/bulbasaur.png',
        ),
      );
      await portraitFile.parent.create(recursive: true);
      await portraitFile.writeAsBytes(const <int>[17, 18, 19]);
      externalSourceRepository.binaryAssets[
              'https://assets.example.test/bulbasaur/portrait.png'] =
          PokemonExternalBinaryAsset(
        sourceUrl: 'https://assets.example.test/bulbasaur/portrait.png',
        bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
        contentType: 'image/jpeg',
      );

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.portrait,
          'assets/pokemon/portraits/bulbasaur.png');
      expect(await portraitFile.readAsBytes(), const <int>[17, 18, 19]);
      expect(
        result.warnings.join('\n'),
        contains('existing local asset was kept'),
      );
      expect(
        result.warnings.join('\n'),
        contains('incompatible content-type (image/jpeg)'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('rejects incompatible cry content-types without persisting a ref',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository
              .binaryAssets['https://assets.example.test/bulbasaur/cry.ogg'] =
          PokemonExternalBinaryAsset(
        sourceUrl: 'https://assets.example.test/bulbasaur/cry.ogg',
        bytes: Uint8List.fromList(<int>[4, 4, 4, 4]),
        contentType: 'audio/mpeg',
      );

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.cry, isNull);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/cries/bulbasaur.ogg',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        result.warnings.join('\n'),
        contains('incompatible content-type (audio/mpeg)'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('refuses GIF assets without persisting a ghost media ref', () async {
      final beforeProjectJson = await projectFile.readAsString();
      final payload =
          jsonDecode(_bulbasaurPokemonPayload) as Map<String, dynamic>;
      final sprites = payload['sprites'] as Map<String, dynamic>;
      final other = sprites['other'] as Map<String, dynamic>;
      final officialArtwork = other['official-artwork'] as Map<String, dynamic>;
      officialArtwork['front_default'] =
          'https://assets.example.test/bulbasaur/portrait.gif';
      externalSourceRepository.pokeApiPokemonPayloads['bulbasaur'] = payload;

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.portrait, isNull);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        result.warnings.join('\n'),
        contains('GIF assets are explicitly excluded'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('applies the same no-ghost rule to cries', () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository.binaryAssets
          .remove('https://assets.example.test/bulbasaur/cry.ogg');

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.cry, isNull);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/cries/bulbasaur.ogg',
          ),
        ).exists(),
        isFalse,
      );
      expect(result.warnings.join('\n'), contains('Cri download failed'));
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('cleans up newly written media assets if media.json persistence fails',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      final useCase = ImportExternalPokemonSpeciesUseCase(
        externalSourceRepository: externalSourceRepository,
        writeRepository: _ThrowingMediaWriteRepository(
          delegate: writeRepository,
        ),
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          speciesId: 'bulbasaur',
        ),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Simulated media write failure'),
          ),
        ),
      );

      // Ce test verrouille un invariant subtil de clôture 11A :
      // si le `media.json` final ne peut pas être écrit, on ne doit pas laisser
      // derrière nous des assets binaires fraîchement créés qui ne seront
      // référencés par aucun JSON local.
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/sprites/bulbasaur/front.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/cries/bulbasaur.ogg',
          ),
        ).exists(),
        isFalse,
      );

      // Le mini-fix ne touche pas à `project.json`. On le reverrouille ici
      // même sur un échec tardif du pipeline.
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'rejects a headerless incompatible image payload without persisting a ref',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository.binaryAssets[
              'https://assets.example.test/bulbasaur/portrait.png'] =
          PokemonExternalBinaryAsset(
        sourceUrl: 'https://assets.example.test/bulbasaur/portrait.png',
        // Signature JPEG volontairement incompatible.
        bytes: Uint8List.fromList(
          <int>[0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46],
        ),
        contentType: null,
      );

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.portrait, isNull);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        result.warnings.join('\n'),
        contains('missing or incompatible content-type'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
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
  Future<Map<String, dynamic>> fetchShowdownPokedexSnapshot() async {
    return showdownSpeciesPayloads.map(
      (key, value) => MapEntry<String, dynamic>(key, _deepCopy(value)),
    );
  }

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
  Future<Map<String, dynamic>> fetchShowdownMovesSnapshot() {
    throw UnimplementedError();
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

/// Repository décorateur volontairement minuscule pour reproduire un échec
/// tardif sur `saveMedia`.
///
/// Ce fake sert uniquement à prouver un invariant de clôture 11A :
/// si l'écriture finale du `media.json` casse, le pipeline ne doit pas laisser
/// d'assets binaires nouvellement créés sans référence locale persistée.
///
/// Non-objectifs explicites :
/// - ne pas changer la sémantique des autres écritures ;
/// - ne pas simuler un filesystem complet ;
/// - ne pas introduire une nouvelle abstraction de prod.
class _ThrowingMediaWriteRepository implements PokemonWriteRepository {
  const _ThrowingMediaWriteRepository({
    required this.delegate,
  });

  final PokemonWriteRepository delegate;

  @override
  Future<void> saveBinaryAsset(
    ProjectWorkspace workspace, {
    required String relativePath,
    required List<int> bytes,
  }) {
    return delegate.saveBinaryAsset(
      workspace,
      relativePath: relativePath,
      bytes: bytes,
    );
  }

  @override
  Future<void> saveCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
    PokemonCatalogFile catalog,
  ) {
    return delegate.saveCatalogByKey(workspace, catalogKey, catalog);
  }

  @override
  Future<void> saveEvolution(
    ProjectWorkspace workspace,
    PokemonEvolutionFile evolution,
  ) {
    return delegate.saveEvolution(workspace, evolution);
  }

  @override
  Future<void> saveLearnset(
    ProjectWorkspace workspace,
    PokemonLearnsetFile learnset,
  ) {
    return delegate.saveLearnset(workspace, learnset);
  }

  @override
  Future<void> saveMedia(
    ProjectWorkspace workspace,
    PokemonMediaFile media,
  ) {
    throw const EditorPersistenceException(
      'Simulated media write failure',
    );
  }

  @override
  Future<void> saveSpecies(
    ProjectWorkspace workspace,
    PokemonSpeciesFile species,
  ) {
    return delegate.saveSpecies(workspace, species);
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
import 'package:map_editor/src/application/models/pokemon_external_query_resolution.dart';
import 'package:map_editor/src/application/models/pokemon_external_species_search_result.dart';
import 'package:map_editor/src/application/models/pokedex_species_detail.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/services/pokemon_database_index.dart';
import 'package:map_editor/src/application/use_cases/delete_pokedex_species_use_case.dart';
import 'package:map_editor/src/application/use_cases/import_external_pokemon_use_cases.dart';
import 'package:map_editor/src/application/use_cases/import_pokemon_json_bundle_use_case.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_evolution_use_case.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_forms_classification_use_case.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_learnset_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
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
    String? portraitRelativePath,
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
      portraitRelativePath: portraitRelativePath,
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
    expect(find.text('Portrait'), findsOneWidget);
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

  testWidgets(
      'renders a portrait thumbnail in the list when the entry exposes a portrait path',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Ce test UI reste volontairement léger :
    // - le service `PokemonProjectDataReader` prouve déjà qu'on ne projette un
    //   portrait que si le fichier existe réellement sur disque ;
    // - ici, on veut seulement verrouiller le rendu du workspace quand un
    //   chemin portrait a déjà été résolu par la couche applicative.
    //
    // On évite donc un vrai décodage image dans le test widget, qui n'apporte
    // aucune valeur supplémentaire au contrat UI et peut rendre le runner
    // desktop inutilement fragile.
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
            id: 'pikachu',
            nationalDex: 25,
            primaryName: 'Pikachu',
            types: const <String>['electric'],
            genIntroduced: 1,
            portraitRelativePath: 'assets/pokemon/portraits/pikachu.png',
          ),
          buildEntry(
            id: 'eevee',
            nationalDex: 133,
            primaryName: 'Eevee',
            types: const <String>['normal'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const Key('pokedex-row-portrait-pikachu')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('pokedex-row-portrait-placeholder-pikachu')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('pokedex-row-portrait-placeholder-eevee')),
      findsOneWidget,
    );
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
      'shows the local moves catalog section in the learnset tab and allows preview + sync',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    var previewCallCount = 0;
    var syncCallCount = 0;
    var catalogEntries = <PokemonMoveCatalogEntryView>[
      const PokemonMoveCatalogEntryView(
        id: 'tackle',
        name: 'Tackle',
        type: 'normal',
        category: 'physical',
        power: 40,
        accuracy: 100,
        pp: 35,
      ),
    ];

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: const <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
        detailLoader: (_, speciesId) async => buildDetail(id: speciesId),
        movesCatalogLoader: (_) async => PokemonMovesCatalogView(
          entries: List<PokemonMoveCatalogEntryView>.from(catalogEntries),
          isAvailable: true,
          description: 'Catalogue local des attaques pour le learnset.',
        ),
        movesCatalogPreviewer: (_) async {
          previewCallCount += 1;
          return const PokemonMovesCatalogSyncResult(
            dryRun: true,
            externalEntryCount: 2,
            createdIds: <String>['thunderbolt'],
            updatedIds: <String>['tackle'],
            unchangedIds: <String>[],
            preservedLocalOnlyIds: <String>[],
            resultingEntryCount: 2,
          );
        },
        movesCatalogSyncer: (_) async {
          syncCallCount += 1;
          catalogEntries = <PokemonMoveCatalogEntryView>[
            ...catalogEntries,
            const PokemonMoveCatalogEntryView(
              id: 'thunderbolt',
              name: 'Thunderbolt',
              type: 'electric',
              category: 'special',
              power: 90,
              accuracy: 100,
              pp: 15,
            ),
          ];
          return const PokemonMovesCatalogSyncResult(
            dryRun: false,
            externalEntryCount: 2,
            createdIds: <String>['thunderbolt'],
            updatedIds: <String>['tackle'],
            unchangedIds: <String>[],
            preservedLocalOnlyIds: <String>[],
            resultingEntryCount: 2,
          );
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-learnset')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('pokedex-moves-catalog-section')),
      findsOneWidget,
    );
    expect(find.text('Attaques locales : 1'), findsOneWidget);
    expect(find.text('Tackle • tackle'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('pokedex-moves-catalog-preview-button')),
    );
    await tester.pumpAndSettle();
    expect(previewCallCount, 1);
    expect(
      find.byKey(const Key('pokedex-moves-catalog-preview-summary')),
      findsOneWidget,
    );
    expect(find.textContaining('Prévisualisation : 2 moves externes analysés.'),
        findsOneWidget);

    await tester
        .tap(find.byKey(const Key('pokedex-moves-catalog-sync-button')));
    await tester.pumpAndSettle();
    expect(syncCallCount, 1);
    expect(find.text('Attaques locales : 2'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('pokedex-moves-catalog-search-field')),
      'thunder',
    );
    await tester.pumpAndSettle();
    expect(find.text('Thunderbolt • thunderbolt'), findsOneWidget);
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
        deleteSpecies: store.deleteSpecies,
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

  testWidgets(
      'deletes the selected species from the detail pane after confirmation',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          nationalDex: 1,
          names: const <String, String>{
            'fr': 'Bulbizarre',
            'en': 'Bulbasaur',
          },
        ),
        buildDetail(
          id: 'ivysaur',
          nationalDex: 2,
          names: const <String, String>{
            'fr': 'Herbizarre',
            'en': 'Ivysaur',
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
        deleteSpecies: store.deleteSpecies,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pokedex-detail-pane')), findsOneWidget);
    expect(
        find.byKey(const Key('pokedex-delete-species-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('pokedex-delete-species-button')));
    await tester.pumpAndSettle();

    expect(find.text('Supprimer cette espèce ?'), findsOneWidget);
    expect(find.textContaining('Bulbizarre'), findsWidgets);

    await tester.tap(find.text('Supprimer').last);
    await tester.pumpAndSettle();

    expect(store.deleteCallCount, 1);
    expect(find.byKey(const Key('pokedex-row-bulbasaur')), findsNothing);
    expect(find.byKey(const Key('pokedex-row-ivysaur')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-detail-empty-state')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-feedback-banner')), findsOneWidget);
    expect(find.textContaining('Bulbizarre a été supprimé'), findsOneWidget);
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
    var searchCallCount = 0;
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
        externalSpeciesSearcher: (rawQuery) async {
          searchCallCount += 1;
          if (rawQuery.trim() != '25') {
            return PokemonExternalSpeciesSearchResult.noResults(
              rawQuery: rawQuery,
              normalizedQuery: rawQuery.trim(),
              resolution: const PokemonExternalSingleQueryResolution(
                rawQuery: '25',
                normalizedQuery: '25',
                query: PokemonExternalSingleQuery.nationalDex(
                  rawValue: '25',
                  nationalDex: 25,
                ),
              ),
              message:
                  'Aucun Pokémon externe trouvé pour cette requête mono-espèce.',
            );
          }
          return PokemonExternalSpeciesSearchResult.suggestions(
            rawQuery: rawQuery,
            normalizedQuery: rawQuery.trim(),
            resolution: const PokemonExternalSingleQueryResolution(
              rawQuery: '25',
              normalizedQuery: '25',
              query: PokemonExternalSingleQuery.nationalDex(
                rawValue: '25',
                nationalDex: 25,
              ),
            ),
            suggestions: const <PokemonExternalSpeciesSuggestion>[
              PokemonExternalSpeciesSuggestion(
                speciesId: 'pikachu',
                primaryName: 'Pikachu',
                nationalDex: 25,
                generation: 1,
              ),
            ],
          );
        },
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    expect(searchCallCount, 1);
    expect(
      find.byKey(const Key('pokedex-import-external-suggestion-pikachu')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<PushButton>(
            find.byKey(const Key('pokedex-import-external-preview-button')),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(
      find.byKey(const Key('pokedex-import-external-suggestion-pikachu')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('pokedex-import-external-selected-suggestion')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<PushButton>(
            find.byKey(const Key('pokedex-import-external-preview-button')),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(
      find.byKey(const Key('pokedex-import-external-preview-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(previewCallCount, 1);
    expect(querySeenByPreview, 'pikachu');
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
    expect(querySeenByImport, 'pikachu');
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
  int deleteCallCount = 0;

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

  Future<DeletedPokedexSpeciesResult> deleteSpecies(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    deleteCallCount += 1;
    final removed = _detailsById.remove(speciesId);
    if (removed == null) {
      throw EditorNotFoundException('Pokemon species not found: $speciesId');
    }
    final primaryName =
        removed.species.names['fr'] ?? removed.species.names['en'] ?? speciesId;
    return DeletedPokedexSpeciesResult(
      speciesId: speciesId,
      primaryName: primaryName,
      deletedRelativePaths: const <String>[],
    );
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
      expect(container.read(pokemonExternalQueryResolverProvider), isNotNull);
      expect(
        container.read(searchExternalPokemonSpeciesUseCaseProvider),
        isNotNull,
      );
      expect(container.read(pokedexExternalSpeciesSearcherProvider), isNotNull);
      expect(
        container.read(importExternalPokemonSpeciesUseCaseProvider),
        isNotNull,
      );
      expect(
        container.read(loadPokemonMovesCatalogUseCaseProvider),
        isNotNull,
      );
      expect(
        container.read(syncExternalPokemonMovesCatalogUseCaseProvider),
        isNotNull,
      );
      expect(container.read(pokedexMovesCatalogLoaderProvider), isNotNull);
      expect(container.read(pokedexMovesCatalogPreviewerProvider), isNotNull);
      expect(container.read(pokedexMovesCatalogSyncerProvider), isNotNull);
      expect(container.read(deletePokedexSpeciesUseCaseProvider), isNotNull);
      expect(container.read(pokedexSpeciesDeleterProvider), isNotNull);
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

### `packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart`

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/pokemon_external_source_repository.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late FilePokemonReadRepository readRepository;
  late FilePokemonWriteRepository writeRepository;
  late _FakePokemonExternalSourceRepository externalRepository;
  late SyncExternalPokemonMovesCatalogUseCase syncUseCase;
  late LoadPokemonMovesCatalogUseCase loadUseCase;

  setUp(() async {
    tempProjectRoot =
        await Directory.systemTemp.createTemp('moves_catalog_sync_');
    workspace = ProjectFileSystem(tempProjectRoot.path);
    readRepository = const FilePokemonReadRepository();
    writeRepository = const FilePokemonWriteRepository();
    externalRepository = _FakePokemonExternalSourceRepository();
    syncUseCase = SyncExternalPokemonMovesCatalogUseCase(
      externalSourceRepository: externalRepository,
      readRepository: readRepository,
      writeRepository: writeRepository,
    );
    loadUseCase = LoadPokemonMovesCatalogUseCase(
      readRepository: readRepository,
    );

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Moves Catalog Sync Project',
      tempProjectRoot.path,
    );
    await const InitializePokemonProjectStorageUseCase().execute(workspace);
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  test('dry-run previews the sync without writing the local catalog', () async {
    await writeRepository.saveCatalogByKey(
      workspace,
      'moves',
      _localMovesCatalogBeforeSync,
    );

    final catalogFile = File(
      workspace.resolveProjectRelativePath('data/pokemon/catalogs/moves.json'),
    );
    final beforeCatalogJson = await catalogFile.readAsString();
    final projectFile = File(workspace.projectManifestPath);
    final beforeProjectJson = await projectFile.readAsString();

    final result = await syncUseCase.execute(workspace, dryRun: true);

    expect(result.dryRun, isTrue);
    expect(result.createdIds, containsAll(<String>['swift', 'thunderbolt']));
    expect(result.updatedIds, contains('vine_whip'));
    expect(result.preservedLocalOnlyIds, contains('custom_move'));
    expect(await catalogFile.readAsString(), beforeCatalogJson);
    expect(await projectFile.readAsString(), beforeProjectJson);
  });

  test(
      'sync merges Showdown moves into the local catalog and preserves local-only metadata',
      () async {
    await writeRepository.saveCatalogByKey(
      workspace,
      'moves',
      _localMovesCatalogBeforeSync,
    );

    final projectFile = File(workspace.projectManifestPath);
    final beforeProjectJson = await projectFile.readAsString();

    final result = await syncUseCase.execute(workspace);
    final syncedCatalog = await readRepository.readCatalogByKey(
      workspace,
      'moves',
    );
    final loadedView = await loadUseCase.execute(workspace);

    expect(result.dryRun, isFalse);
    expect(result.createdIds, containsAll(<String>['swift', 'thunderbolt']));
    expect(result.updatedIds, contains('vine_whip'));
    expect(result.preservedLocalOnlyIds, contains('custom_move'));
    expect(
      syncedCatalog.entries.map((entry) => entry['id']),
      containsAll(<String>['custom_move', 'swift', 'thunderbolt', 'vine_whip']),
    );

    final vineWhip = syncedCatalog.entries.firstWhere(
      (entry) => entry['id'] == 'vine_whip',
    );
    expect(vineWhip['name'], 'Vine Whip');
    expect(vineWhip['type'], 'grass');
    expect(vineWhip['power'], 45);
    expect(vineWhip['generation'], 1);
    expect(
      ((vineWhip['names'] as Map<String, dynamic>)['fr'] as String),
      'Fouet Lianes',
    );

    final swift = syncedCatalog.entries.firstWhere(
      (entry) => entry['id'] == 'swift',
    );
    expect(swift['accuracy'], isNull);
    expect(swift['accuracyText'], 'always');

    expect(loadedView.isAvailable, isTrue);
    expect(
        loadedView.entries.map((entry) => entry.id), contains('thunderbolt'));
    expect(await projectFile.readAsString(), beforeProjectJson);
  });
}

class _FakePokemonExternalSourceRepository
    implements PokemonExternalSourceRepository {
  @override
  Future<Map<String, dynamic>> fetchShowdownPokedexSnapshot() {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownMovesSnapshot() async {
    return <String, dynamic>{
      'vinewhip': <String, dynamic>{
        'name': 'Vine Whip',
        'type': 'Grass',
        'category': 'Physical',
        'basePower': 45,
        'accuracy': 100,
        'pp': 25,
        'priority': 0,
        'target': 'normal',
        'shortDesc': 'Strikes the target with slender, whiplike vines.',
        'desc': 'The target is struck with slender, whiplike vines.',
        'gen': 1,
      },
      'thunderbolt': <String, dynamic>{
        'name': 'Thunderbolt',
        'type': 'Electric',
        'category': 'Special',
        'basePower': 90,
        'accuracy': 100,
        'pp': 15,
        'priority': 0,
        'target': 'normal',
        'shortDesc': 'May paralyze the target.',
        'desc': 'A strong electric blast crashes down on the target.',
        'gen': 1,
      },
      'swift': <String, dynamic>{
        'name': 'Swift',
        'type': 'Normal',
        'category': 'Special',
        'basePower': 60,
        'accuracy': true,
        'pp': 20,
        'priority': 0,
        'target': 'allAdjacentFoes',
        'shortDesc': 'This move does not check accuracy.',
        'desc': 'Star-shaped rays are shot at opposing Pokémon.',
        'gen': 1,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownSpeciesPayload(String speciesId) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonPayload(String speciesId) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonSpeciesPayload(
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiEvolutionChainPayload(
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonExternalBinaryAsset> fetchBinaryAsset(String sourceUrl) {
    throw UnimplementedError();
  }
}

const PokemonCatalogFile _localMovesCatalogBeforeSync = PokemonCatalogFile(
  schemaVersion: 1,
  kind: 'pokemon_catalog',
  catalog: 'moves',
  meta: PokemonDataMeta(
    description: 'Local moves catalog before external sync.',
  ),
  entries: <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'custom_move',
      'name': 'Custom Move',
      'names': <String, String>{'en': 'Custom Move'},
      'type': 'normal',
      'category': 'status',
      'power': null,
      'accuracy': 100,
      'pp': 5,
      'priority': 0,
      'target': 'self',
      'shortDesc': 'A local-only move that must be preserved.',
      'generation': 9,
    },
    <String, dynamic>{
      'id': 'vine_whip',
      'name': 'Liane',
      'names': <String, String>{
        'en': 'Vine Whip',
        'fr': 'Fouet Lianes',
      },
      'type': 'grass',
      'category': 'physical',
      'power': 40,
      'accuracy': 95,
      'pp': 20,
      'priority': 0,
      'target': 'normal',
      'shortDesc': 'Old local description.',
      'generation': 3,
      'editorNote': 'Keep this local-only field after sync.',
    },
  ],
);

```

### `packages/map_editor/lib/src/application/models/pokemon_external_species_search_result.dart`

```dart
import 'pokemon_external_query_resolution.dart';

/// Suggestion concrète affichable dans l'auto-complétion mono-espèce.
///
/// Ce modèle reste volontairement léger :
/// - il ne représente pas un payload externe complet ;
/// - il ne représente pas non plus une espèce locale importée ;
/// - il sert uniquement à afficher une suggestion sélectionnable dans le
///   wizard Pokédex.
///
/// Les champs retenus sont ceux qui apportent une vraie valeur UX immédiate :
/// - l'id canonique à réutiliser pour preview/import ;
/// - le nom principal pour l'affichage ;
/// - le numéro dex pour aider la désambiguïsation ;
/// - la génération quand elle est connue dans le snapshot source.
class PokemonExternalSpeciesSuggestion {
  const PokemonExternalSpeciesSuggestion({
    required this.speciesId,
    required this.primaryName,
    required this.nationalDex,
    this.generation,
  });

  final String speciesId;
  final String primaryName;
  final int nationalDex;
  final int? generation;
}

/// État applicatif de la recherche mono-espèce.
///
/// Important :
/// - `loading` n'apparaît pas ici, car c'est un état d'interaction UI ;
/// - ce résultat ne fait qu'exprimer ce que la couche applicative a compris ;
/// - l'UI peut ensuite afficher un état vide, une erreur ou une liste sans
///   devoir réinterpréter la requête brute.
enum PokemonExternalSpeciesSearchResultKind {
  empty,
  suggestions,
  noResults,
  invalidQuery,
  outOfScopeQuery,
  error,
}

/// Résultat structuré de la recherche mono-espèce.
///
/// Le contrat est volontairement explicite :
/// - `empty` : rien à rechercher ;
/// - `suggestions` : la requête mono-espèce a produit des suggestions ;
/// - `noResults` : la requête mono-espèce est valide mais ne matche rien ;
/// - `invalidQuery` : la requête n'est pas comprise proprement ;
/// - `outOfScopeQuery` : la requête est comprise, mais relève d'un autre lot ;
/// - `error` : l'infrastructure de suggestion n'a pas pu répondre.
class PokemonExternalSpeciesSearchResult {
  const PokemonExternalSpeciesSearchResult._({
    required this.kind,
    required this.rawQuery,
    required this.normalizedQuery,
    this.resolution,
    this.suggestions = const <PokemonExternalSpeciesSuggestion>[],
    this.message,
  });

  const PokemonExternalSpeciesSearchResult.empty({
    required String rawQuery,
    required String normalizedQuery,
  }) : this._(
          kind: PokemonExternalSpeciesSearchResultKind.empty,
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
        );

  const PokemonExternalSpeciesSearchResult.suggestions({
    required String rawQuery,
    required String normalizedQuery,
    required PokemonExternalQueryResolution resolution,
    required List<PokemonExternalSpeciesSuggestion> suggestions,
  }) : this._(
          kind: PokemonExternalSpeciesSearchResultKind.suggestions,
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
          resolution: resolution,
          suggestions: suggestions,
        );

  const PokemonExternalSpeciesSearchResult.noResults({
    required String rawQuery,
    required String normalizedQuery,
    required PokemonExternalQueryResolution resolution,
    required String message,
  }) : this._(
          kind: PokemonExternalSpeciesSearchResultKind.noResults,
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
          resolution: resolution,
          message: message,
        );

  const PokemonExternalSpeciesSearchResult.invalidQuery({
    required String rawQuery,
    required String normalizedQuery,
    required PokemonExternalQueryResolution resolution,
    required String message,
  }) : this._(
          kind: PokemonExternalSpeciesSearchResultKind.invalidQuery,
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
          resolution: resolution,
          message: message,
        );

  const PokemonExternalSpeciesSearchResult.outOfScopeQuery({
    required String rawQuery,
    required String normalizedQuery,
    required PokemonExternalQueryResolution resolution,
    required String message,
  }) : this._(
          kind: PokemonExternalSpeciesSearchResultKind.outOfScopeQuery,
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
          resolution: resolution,
          message: message,
        );

  const PokemonExternalSpeciesSearchResult.error({
    required String rawQuery,
    required String normalizedQuery,
    required PokemonExternalQueryResolution resolution,
    required String message,
  }) : this._(
          kind: PokemonExternalSpeciesSearchResultKind.error,
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
          resolution: resolution,
          message: message,
        );

  final PokemonExternalSpeciesSearchResultKind kind;
  final String rawQuery;
  final String normalizedQuery;

  /// Résolution issue du lot 1 quand une résolution existe vraiment.
  ///
  /// `null` est réservé au cas `empty`, où l'utilisateur n'a pas encore saisi
  /// de requête exploitable.
  final PokemonExternalQueryResolution? resolution;

  /// Suggestions concrètes uniquement pour l'état `suggestions`.
  final List<PokemonExternalSpeciesSuggestion> suggestions;

  /// Message lisible pour les états non-suggestions.
  final String? message;

  bool get hasSuggestions =>
      kind == PokemonExternalSpeciesSearchResultKind.suggestions &&
      suggestions.isNotEmpty;
}

```

### `packages/map_editor/lib/src/application/use_cases/search_external_pokemon_species_use_case.dart`

```dart
import '../errors/application_errors.dart';
import '../models/pokemon_external_query_resolution.dart';
import '../models/pokemon_external_species_search_result.dart';
import '../ports/pokemon_external_source_repository.dart';
import '../services/pokemon_external_query_resolver.dart';

/// Recherche applicative mono-espèce pour le wizard Pokédex.
///
/// Ce use case prolonge le lot 1 sans le contourner :
/// - le résolveur du lot 1 comprend la saisie brute ;
/// - ce use case décide si cette saisie relève bien du flux mono-espèce ;
/// - puis il interroge une source légère de suggestions déjà présente dans le
///   pipeline externe existant.
///
/// Non-objectifs explicites :
/// - aucun import ;
/// - aucune preview d'import ;
/// - aucune logique batch ;
/// - aucune logique UI ;
/// - aucun nouveau port externe parallèle.
class SearchExternalPokemonSpeciesUseCase {
  SearchExternalPokemonSpeciesUseCase({
    required this.externalSourceRepository,
    required this.queryResolver,
    this.maxSuggestions = 8,
  });

  final PokemonExternalSourceRepository externalSourceRepository;
  final PokemonExternalQueryResolver queryResolver;
  final int maxSuggestions;

  Future<List<_IndexedExternalSpeciesSuggestion>>? _cachedIndexFuture;

  /// Exécute une recherche mono-espèce structurée.
  Future<PokemonExternalSpeciesSearchResult> execute(String rawQuery) async {
    final resolution = queryResolver.resolve(rawQuery);

    if (resolution is PokemonExternalInvalidQueryResolution) {
      if (resolution.code == PokemonExternalInvalidQueryCode.emptyQuery) {
        return PokemonExternalSpeciesSearchResult.empty(
          rawQuery: resolution.rawQuery,
          normalizedQuery: resolution.normalizedQuery,
        );
      }
      return PokemonExternalSpeciesSearchResult.invalidQuery(
        rawQuery: resolution.rawQuery,
        normalizedQuery: resolution.normalizedQuery,
        resolution: resolution,
        message: resolution.message,
      );
    }

    if (resolution is! PokemonExternalSingleQueryResolution) {
      return PokemonExternalSpeciesSearchResult.outOfScopeQuery(
        rawQuery: resolution.rawQuery,
        normalizedQuery: resolution.normalizedQuery,
        resolution: resolution,
        message: _buildOutOfScopeMessage(resolution.kind),
      );
    }

    try {
      final index = await _loadSuggestionIndex();
      final suggestions = _searchSuggestions(
        index,
        resolution.query,
      );

      if (suggestions.isEmpty) {
        return PokemonExternalSpeciesSearchResult.noResults(
          rawQuery: resolution.rawQuery,
          normalizedQuery: resolution.normalizedQuery,
          resolution: resolution,
          message:
              'Aucun Pokémon externe trouvé pour cette requête mono-espèce.',
        );
      }

      return PokemonExternalSpeciesSearchResult.suggestions(
        rawQuery: resolution.rawQuery,
        normalizedQuery: resolution.normalizedQuery,
        resolution: resolution,
        suggestions: suggestions,
      );
    } on EditorApplicationException catch (error) {
      return PokemonExternalSpeciesSearchResult.error(
        rawQuery: resolution.rawQuery,
        normalizedQuery: resolution.normalizedQuery,
        resolution: resolution,
        message: error.message,
      );
    } catch (error) {
      return PokemonExternalSpeciesSearchResult.error(
        rawQuery: resolution.rawQuery,
        normalizedQuery: resolution.normalizedQuery,
        resolution: resolution,
        message: 'Recherche externe indisponible : $error',
      );
    }
  }

  String _buildOutOfScopeMessage(PokemonExternalQueryResolutionKind kind) {
    return switch (kind) {
      PokemonExternalQueryResolutionKind.explicitList =>
        'Cette étape ne gère qu’une espèce à la fois. Les listes explicites '
            'ne sont pas prises en charge ici.',
      PokemonExternalQueryResolutionKind.nationalDexRange =>
        'Cette étape mono-espèce ne gère pas encore les plages Pokédex.',
      PokemonExternalQueryResolutionKind.generation =>
        'Cette étape mono-espèce ne gère pas encore les imports par '
            'génération.',
      PokemonExternalQueryResolutionKind.singleQuery ||
      PokemonExternalQueryResolutionKind.invalid =>
        'La requête ne relève pas de cette étape mono-espèce.',
    };
  }

  Future<List<_IndexedExternalSpeciesSuggestion>> _loadSuggestionIndex() {
    final cached = _cachedIndexFuture;
    if (cached != null) {
      return cached;
    }

    final future = () async {
      final snapshot =
          await externalSourceRepository.fetchShowdownPokedexSnapshot();
      return _buildSuggestionIndex(snapshot);
    }();

    _cachedIndexFuture = future;
    return future;
  }

  List<_IndexedExternalSpeciesSuggestion> _buildSuggestionIndex(
    Map<String, dynamic> snapshot,
  ) {
    final indexedSuggestions = <_IndexedExternalSpeciesSuggestion>[];

    for (final entry in snapshot.entries) {
      final rawPayload = entry.value;
      if (rawPayload is! Map) {
        continue;
      }

      final speciesId = entry.key.trim().toLowerCase();
      if (speciesId.isEmpty) {
        continue;
      }

      final payload = rawPayload.cast<String, dynamic>();
      final nationalDex = (payload['num'] as num?)?.toInt() ?? 0;
      if (nationalDex <= 0) {
        // Le lot 2 veut une surface mono-espèce honnête. On ignore donc les
        // entrées Showdown qui ne décrivent pas une espèce exploitable
        // simplement côté dex produit.
        continue;
      }

      final primaryName = (payload['name'] as String?)?.trim();
      if (primaryName == null || primaryName.isEmpty) {
        continue;
      }

      final generation = (payload['gen'] as num?)?.toInt();
      final suggestion = PokemonExternalSpeciesSuggestion(
        speciesId: speciesId,
        primaryName: primaryName,
        nationalDex: nationalDex,
        generation: generation,
      );
      indexedSuggestions.add(
        _IndexedExternalSpeciesSuggestion(
          suggestion: suggestion,
          normalizedSpeciesId: _normalizeLookupToken(speciesId),
          normalizedPrimaryName: _normalizeLookupToken(primaryName),
        ),
      );
    }

    indexedSuggestions.sort((left, right) {
      final dexCompare =
          left.suggestion.nationalDex.compareTo(right.suggestion.nationalDex);
      if (dexCompare != 0) {
        return dexCompare;
      }
      return left.suggestion.speciesId.compareTo(right.suggestion.speciesId);
    });
    return List<_IndexedExternalSpeciesSuggestion>.unmodifiable(
      indexedSuggestions,
    );
  }

  List<PokemonExternalSpeciesSuggestion> _searchSuggestions(
    List<_IndexedExternalSpeciesSuggestion> index,
    PokemonExternalSingleQuery query,
  ) {
    return switch (query.kind) {
      PokemonExternalSingleQueryKind.nationalDex =>
        _searchByNationalDex(index, query.nationalDex!),
      PokemonExternalSingleQueryKind.species =>
        _searchBySpeciesTerm(index, query.normalizedValue!),
    };
  }

  List<PokemonExternalSpeciesSuggestion> _searchByNationalDex(
    List<_IndexedExternalSpeciesSuggestion> index,
    int nationalDex,
  ) {
    final matches = index
        .where((entry) => entry.suggestion.nationalDex == nationalDex)
        .take(maxSuggestions)
        .map((entry) => entry.suggestion)
        .toList(growable: false);
    return matches;
  }

  List<PokemonExternalSpeciesSuggestion> _searchBySpeciesTerm(
    List<_IndexedExternalSpeciesSuggestion> index,
    String rawTerm,
  ) {
    final normalizedTerm = _normalizeLookupToken(rawTerm);
    if (normalizedTerm.isEmpty) {
      return const <PokemonExternalSpeciesSuggestion>[];
    }

    final matches = <_RankedExternalSpeciesSuggestion>[];
    for (final entry in index) {
      final score = _computeMatchScore(entry, normalizedTerm);
      if (score == null) {
        continue;
      }
      matches.add(
        _RankedExternalSpeciesSuggestion(
          suggestion: entry.suggestion,
          score: score,
        ),
      );
    }

    matches.sort((left, right) {
      final scoreCompare = left.score.compareTo(right.score);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      final dexCompare =
          left.suggestion.nationalDex.compareTo(right.suggestion.nationalDex);
      if (dexCompare != 0) {
        return dexCompare;
      }
      return left.suggestion.speciesId.compareTo(right.suggestion.speciesId);
    });

    return matches
        .take(maxSuggestions)
        .map((match) => match.suggestion)
        .toList(growable: false);
  }

  int? _computeMatchScore(
    _IndexedExternalSpeciesSuggestion entry,
    String normalizedTerm,
  ) {
    final id = entry.normalizedSpeciesId;
    final name = entry.normalizedPrimaryName;

    if (id == normalizedTerm || name == normalizedTerm) {
      return 0;
    }
    if (id.startsWith(normalizedTerm) || name.startsWith(normalizedTerm)) {
      return 1;
    }
    if (id.contains(normalizedTerm) || name.contains(normalizedTerm)) {
      return 2;
    }
    return null;
  }

  String _normalizeLookupToken(String rawValue) {
    final lowered = rawValue.trim().toLowerCase();
    return lowered.replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }
}

class _IndexedExternalSpeciesSuggestion {
  const _IndexedExternalSpeciesSuggestion({
    required this.suggestion,
    required this.normalizedSpeciesId,
    required this.normalizedPrimaryName,
  });

  final PokemonExternalSpeciesSuggestion suggestion;
  final String normalizedSpeciesId;
  final String normalizedPrimaryName;
}

class _RankedExternalSpeciesSuggestion {
  const _RankedExternalSpeciesSuggestion({
    required this.suggestion,
    required this.score,
  });

  final PokemonExternalSpeciesSuggestion suggestion;
  final int score;
}

```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_external_search_field.dart`

```dart
part of 'pokedex_workspace_page.dart';

/// Champ d'auto-complétion mono-espèce du wizard externe.
///
/// Ce widget reste volontairement présentation + interaction locale :
/// - il n'analyse pas la requête ;
/// - il ne parle pas au réseau ;
/// - il n'importe rien ;
/// - il reflète simplement le résultat applicatif reçu du use case.
///
/// On utilise `RawAutocomplete` pour une raison précise :
/// - navigation clavier honnête sans réinventer un mini-système focus ;
/// - sélection souris explicite ;
/// - aucune sélection implicite tant que l'utilisateur n'agit pas.
class _PokedexExternalSpeciesAutocompleteField extends StatefulWidget {
  const _PokedexExternalSpeciesAutocompleteField({
    required this.controller,
    required this.focusNode,
    required this.isBusy,
    required this.isSearching,
    required this.searchResult,
    required this.selectedSuggestion,
    required this.onQueryChanged,
    required this.onSuggestionSelected,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isBusy;
  final bool isSearching;
  final PokemonExternalSpeciesSearchResult searchResult;
  final PokemonExternalSpeciesSuggestion? selectedSuggestion;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<PokemonExternalSpeciesSuggestion> onSuggestionSelected;

  @override
  State<_PokedexExternalSpeciesAutocompleteField> createState() =>
      _PokedexExternalSpeciesAutocompleteFieldState();
}

class _PokedexExternalSpeciesAutocompleteFieldState
    extends State<_PokedexExternalSpeciesAutocompleteField> {
  int? _highlightedSuggestionIndex;

  List<PokemonExternalSpeciesSuggestion> get _visibleSuggestions =>
      widget.searchResult.hasSuggestions && widget.selectedSuggestion == null
          ? widget.searchResult.suggestions
          : const <PokemonExternalSpeciesSuggestion>[];

  @override
  void initState() {
    super.initState();
    _syncHighlightedSuggestion();
  }

  @override
  void didUpdateWidget(_PokedexExternalSpeciesAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchResult.kind != widget.searchResult.kind ||
        !listEquals(
          oldWidget.searchResult.suggestions,
          widget.searchResult.suggestions,
        ) ||
        oldWidget.selectedSuggestion != widget.selectedSuggestion) {
      _syncHighlightedSuggestion();
    }
  }

  void _syncHighlightedSuggestion() {
    final suggestions = _visibleSuggestions;
    if (suggestions.isEmpty) {
      _highlightedSuggestionIndex = null;
      return;
    }
    if (_highlightedSuggestionIndex == null ||
        _highlightedSuggestionIndex! >= suggestions.length) {
      _highlightedSuggestionIndex = 0;
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final suggestions = _visibleSuggestions;
    if (suggestions.isEmpty || widget.selectedSuggestion != null) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        final currentIndex = _highlightedSuggestionIndex ?? -1;
        _highlightedSuggestionIndex =
            (currentIndex + 1).clamp(0, suggestions.length - 1);
      });
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        final currentIndex = _highlightedSuggestionIndex ?? 0;
        _highlightedSuggestionIndex =
            (currentIndex - 1).clamp(0, suggestions.length - 1);
      });
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final selectedIndex = _highlightedSuggestionIndex ?? 0;
      widget.onSuggestionSelected(suggestions[selectedIndex]);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _visibleSuggestions;

    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CupertinoTextField(
            key: const Key('pokedex-import-external-query-field'),
            controller: widget.controller,
            focusNode: widget.focusNode,
            placeholder: 'Ex. pikachu, bulbasaur ou 25',
            enabled: !widget.isBusy,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            onChanged: widget.onQueryChanged,
            onSubmitted: (_) {
              final selectedIndex = _highlightedSuggestionIndex;
              if (selectedIndex == null ||
                  selectedIndex < 0 ||
                  selectedIndex >= suggestions.length) {
                return;
              }
              widget.onSuggestionSelected(suggestions[selectedIndex]);
            },
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              key: const Key('pokedex-import-external-suggestions-list'),
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 260),
              decoration: BoxDecoration(
                color: EditorChrome.islandFillElevated(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: EditorChrome.accentJade.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => Container(
                  height: 1,
                  color: EditorChrome.subtleSeparator(context),
                ),
                itemBuilder: (context, index) {
                  final option = suggestions[index];
                  final isHighlighted = _highlightedSuggestionIndex == index;
                  return MouseRegion(
                    onEnter: (_) {
                      if (_highlightedSuggestionIndex == index) {
                        return;
                      }
                      setState(() {
                        _highlightedSuggestionIndex = index;
                      });
                    },
                    child: GestureDetector(
                      key: Key(
                        'pokedex-import-external-suggestion-${option.speciesId}',
                      ),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onSuggestionSelected(option),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: isHighlighted
                              ? EditorChrome.accentJade.withValues(alpha: 0.16)
                              : CupertinoColors.transparent,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Text(
                                '#${option.nationalDex.toString().padLeft(4, '0')}',
                                style: TextStyle(
                                  color: EditorChrome.subtleLabel(context),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option.primaryName,
                                      style: TextStyle(
                                        color: EditorChrome.primaryLabel(
                                          context,
                                        ),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      option.speciesId,
                                      style: TextStyle(
                                        color: EditorChrome.subtleLabel(
                                          context,
                                        ),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (option.generation != null)
                                Text(
                                  'Gen ${option.generation}',
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
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (widget.selectedSuggestion != null) ...[
            Container(
              key: const Key('pokedex-import-external-selected-suggestion'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: EditorChrome.accentJade.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: EditorChrome.accentJade.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.check_mark_circled_solid,
                    size: 18,
                    color: EditorChrome.accentJade,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sélection retenue : #${widget.selectedSuggestion!.nationalDex.toString().padLeft(4, '0')} ${widget.selectedSuggestion!.primaryName} · ${widget.selectedSuggestion!.speciesId}',
                      style: TextStyle(
                        color: EditorChrome.primaryLabel(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (widget.isSearching)
            Row(
              key: const Key('pokedex-import-external-search-loading'),
              children: const [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: ProgressCircle(),
                ),
                SizedBox(width: 10),
                Text(
                  'Recherche des suggestions externes…',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          else
            _PokedexExternalSpeciesSearchMessage(
              searchResult: widget.searchResult,
              selectedSuggestion: widget.selectedSuggestion,
            ),
        ],
      ),
    );
  }
}

class _PokedexExternalSpeciesSearchMessage extends StatelessWidget {
  const _PokedexExternalSpeciesSearchMessage({
    required this.searchResult,
    required this.selectedSuggestion,
  });

  final PokemonExternalSpeciesSearchResult searchResult;
  final PokemonExternalSpeciesSuggestion? selectedSuggestion;

  @override
  Widget build(BuildContext context) {
    if (selectedSuggestion != null) {
      return Text(
        'La prévisualisation utilisera uniquement l’espèce explicitement sélectionnée ci-dessus.',
        style: TextStyle(
          color: EditorChrome.subtleLabel(context),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      );
    }

    if (searchResult.kind == PokemonExternalSpeciesSearchResultKind.empty) {
      return Text(
        'Tapez un nom, un slug ou un numéro dex, puis sélectionnez explicitement une suggestion.',
        key: const Key('pokedex-import-external-search-idle-message'),
        style: TextStyle(
          color: EditorChrome.subtleLabel(context),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      );
    }

    if (searchResult.kind ==
        PokemonExternalSpeciesSearchResultKind.suggestions) {
      return Text(
        'Choisissez explicitement une suggestion pour débloquer la prévisualisation.',
        key: const Key(
            'pokedex-import-external-search-pending-selection-message'),
        style: TextStyle(
          color: EditorChrome.subtleLabel(context),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      );
    }

    final isError = searchResult.kind ==
            PokemonExternalSpeciesSearchResultKind.invalidQuery ||
        searchResult.kind == PokemonExternalSpeciesSearchResultKind.error;
    final accent =
        isError ? EditorChrome.inspectorJoyCoral : EditorChrome.accentWarm;

    return Container(
      key: const Key('pokedex-import-external-search-message'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        searchResult.message ?? 'Aucune suggestion disponible.',
        style: TextStyle(
          color: CupertinoColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}

```

### `packages/map_editor/test/pokedex_external_autocomplete_ui_test.dart`

```dart
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/models/pokedex_species_detail.dart';
import 'package:map_editor/src/application/models/pokemon_external_query_resolution.dart';
import 'package:map_editor/src/application/models/pokemon_external_species_search_result.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/pokedex_workspace.dart';

void main() {
  const sampleProject = ProjectManifest(
    name: 'pokedex_external_autocomplete_test',
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
          child: MacosApp(
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

  Future<void> openExternalImportStep(WidgetTester tester) async {
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
  }

  PokedexWorkspace buildWorkspace({
    required Future<PokemonExternalSpeciesSearchResult> Function(
            String rawQuery)
        externalSpeciesSearcher,
  }) {
    return PokedexWorkspace(
      loader: (_) async => const <PokemonDatabaseIndexEntry>[],
      detailLoader: (_, __) async => _unusedDetail(),
      importPreviewer: (_, __) async => throw UnimplementedError(),
      importer: (_, __) async => throw UnimplementedError(),
      externalSpeciesSearcher: externalSpeciesSearcher,
      externalImportPreviewer: (_, __) async => throw UnimplementedError(),
      externalImporter: (_, __) async => throw UnimplementedError(),
    );
  }

  testWidgets('shows loading then allows keyboard selection of a suggestion',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final completer = Completer<PokemonExternalSpeciesSearchResult>();

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_external_autocomplete_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: buildWorkspace(
        externalSpeciesSearcher: (_) => completer.future,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await openExternalImportStep(tester);

    await tester.enterText(
      find.byKey(const Key('pokedex-import-external-query-field')),
      '25',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(
      find.byKey(const Key('pokedex-import-external-search-loading')),
      findsOneWidget,
    );

    completer.complete(
      const PokemonExternalSpeciesSearchResult.suggestions(
        rawQuery: '25',
        normalizedQuery: '25',
        resolution: PokemonExternalSingleQueryResolution(
          rawQuery: '25',
          normalizedQuery: '25',
          query: PokemonExternalSingleQuery.nationalDex(
            rawValue: '25',
            nationalDex: 25,
          ),
        ),
        suggestions: <PokemonExternalSpeciesSuggestion>[
          PokemonExternalSpeciesSuggestion(
            speciesId: 'pikachu',
            primaryName: 'Pikachu',
            nationalDex: 25,
            generation: 1,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('pokedex-import-external-suggestion-pikachu')),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('pokedex-import-external-selected-suggestion')),
      findsOneWidget,
    );
  });

  testWidgets('shows a clean no-result state', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_external_autocomplete_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: buildWorkspace(
        externalSpeciesSearcher: (rawQuery) async =>
            PokemonExternalSpeciesSearchResult.noResults(
          rawQuery: rawQuery,
          normalizedQuery: rawQuery.trim(),
          resolution: const PokemonExternalSingleQueryResolution(
            rawQuery: 'bulbasaur',
            normalizedQuery: 'bulbasaur',
            query: PokemonExternalSingleQuery.species(
              rawValue: 'bulbasaur',
              normalizedValue: 'bulbasaur',
            ),
          ),
          message:
              'Aucun Pokémon externe trouvé pour cette requête mono-espèce.',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await openExternalImportStep(tester);

    await tester.enterText(
      find.byKey(const Key('pokedex-import-external-query-field')),
      'bulbasaur',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(
      find.byKey(const Key('pokedex-import-external-search-message')),
      findsOneWidget,
    );
    expect(
      find.text('Aucun Pokémon externe trouvé pour cette requête mono-espèce.'),
      findsOneWidget,
    );
  });

  testWidgets('shows a clean out-of-scope message for generation queries',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_external_autocomplete_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: buildWorkspace(
        externalSpeciesSearcher: (rawQuery) async =>
            const PokemonExternalSpeciesSearchResult.outOfScopeQuery(
          rawQuery: 'gen 1',
          normalizedQuery: 'gen 1',
          resolution: PokemonExternalGenerationQueryResolution(
            rawQuery: 'gen 1',
            normalizedQuery: 'gen 1',
            generation: 1,
          ),
          message:
              'Cette étape mono-espèce ne gère pas encore les imports par génération.',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await openExternalImportStep(tester);

    await tester.enterText(
      find.byKey(const Key('pokedex-import-external-query-field')),
      'gen 1',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(
      find.text(
        'Cette étape mono-espèce ne gère pas encore les imports par génération.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows a clean invalid message for ambiguous queries',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_external_autocomplete_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: buildWorkspace(
        externalSpeciesSearcher: (rawQuery) async =>
            const PokemonExternalSpeciesSearchResult.invalidQuery(
          rawQuery: 'pikachu eevee abra',
          normalizedQuery: 'pikachu eevee abra',
          resolution: PokemonExternalInvalidQueryResolution(
            rawQuery: 'pikachu eevee abra',
            normalizedQuery: 'pikachu eevee abra',
            code: PokemonExternalInvalidQueryCode
                .ambiguousWhitespaceSeparatedTerms,
            message:
                'La requête contient plusieurs termes séparés par des espaces. Utilisez des virgules pour une liste explicite.',
          ),
          message:
              'La requête contient plusieurs termes séparés par des espaces. Utilisez des virgules pour une liste explicite.',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await openExternalImportStep(tester);

    await tester.enterText(
      find.byKey(const Key('pokedex-import-external-query-field')),
      'pikachu eevee abra',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(
      find.textContaining('Utilisez des virgules pour une liste explicite'),
      findsOneWidget,
    );
  });
}

PokedexSpeciesDetail _unusedDetail() {
  return const PokedexSpeciesDetail(
    species: PokemonSpeciesFile(
      id: 'bulbasaur',
      slug: 'bulbasaur',
      nationalDex: 1,
      names: <String, String>{
        'fr': 'Bulbizarre',
        'en': 'Bulbasaur',
      },
      speciesName: <String, String>{
        'fr': 'Pokémon Graine',
        'en': 'Seed Pokemon',
      },
      genIntroduced: 1,
      typing: PokemonSpeciesTyping(types: <String>['grass']),
      baseStats: PokemonSpeciesBaseStats(
        hp: 45,
        atk: 49,
        def: 49,
        spa: 65,
        spd: 65,
        spe: 45,
        bst: 318,
      ),
      abilities: PokemonSpeciesAbilities(primary: 'overgrow'),
      breeding: PokemonSpeciesBreeding(
        genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
        eggGroups: <String>['monster'],
        hatchCycles: 20,
      ),
      progression: PokemonSpeciesProgression(
        growthRateId: 'medium_slow',
        baseExp: 64,
        catchRate: 45,
        baseFriendship: 50,
      ),
      forms: PokemonSpeciesForms(
        baseFormId: 'bulbasaur',
        isBaseForm: true,
        formId: 'base',
        otherForms: <String>[],
      ),
      classification: PokemonSpeciesClassification(
        isEnabledInProject: true,
        isObtainable: true,
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
      ),
      gameplayFlags: PokemonSpeciesGameplayFlags(),
      sourceMeta: PokemonSpeciesSourceMeta(
        seededBy: 'test',
        seedVersion: 1,
      ),
    ),
    learnset: PokemonLearnsetFile(
      speciesId: 'bulbasaur',
      startingMoves: <String>['tackle'],
    ),
    evolution: PokemonEvolutionFile(
      speciesId: 'bulbasaur',
      preEvolution: null,
      evolutions: <PokemonEvolutionEntry>[],
    ),
    media: PokemonMediaFile(
      speciesId: 'bulbasaur',
      defaultFormId: 'base',
      variants: <String, PokemonMediaVariant>{},
    ),
  );
}

```

### `packages/map_editor/test/search_external_pokemon_species_use_case_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_external_species_search_result.dart';
import 'package:map_editor/src/application/ports/pokemon_external_source_repository.dart';
import 'package:map_editor/src/application/use_cases/search_external_pokemon_species_use_case.dart';
import 'package:map_editor/src/application/services/pokemon_external_query_resolver.dart';

void main() {
  group('SearchExternalPokemonSpeciesUseCase', () {
    test('returns empty without hitting the external repository', () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshot: const <String, dynamic>{},
      );
      final useCase = SearchExternalPokemonSpeciesUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('   ');

      expect(result.kind, PokemonExternalSpeciesSearchResultKind.empty);
      expect(repository.fetchShowdownPokedexSnapshotCallCount, 0);
    });

    test('returns invalid for an ambiguous whitespace query', () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshot: const <String, dynamic>{},
      );
      final useCase = SearchExternalPokemonSpeciesUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('pikachu eevee abra');

      expect(result.kind, PokemonExternalSpeciesSearchResultKind.invalidQuery);
      expect(result.message, contains('Utilisez des virgules'));
      expect(repository.fetchShowdownPokedexSnapshotCallCount, 0);
    });

    test('returns out-of-scope for a dex range query', () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshot: const <String, dynamic>{},
      );
      final useCase = SearchExternalPokemonSpeciesUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('1-151');

      expect(
          result.kind, PokemonExternalSpeciesSearchResultKind.outOfScopeQuery);
      expect(result.message, contains('plages Pokédex'));
      expect(repository.fetchShowdownPokedexSnapshotCallCount, 0);
    });

    test('returns suggestions for a mono-species textual query', () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshot: <String, dynamic>{
          'bulbasaur': <String, dynamic>{
            'name': 'Bulbasaur',
            'num': 1,
            'gen': 1,
          },
          'ivysaur': <String, dynamic>{
            'name': 'Ivysaur',
            'num': 2,
            'gen': 1,
          },
          'pikachu': <String, dynamic>{
            'name': 'Pikachu',
            'num': 25,
            'gen': 1,
          },
        },
      );
      final useCase = SearchExternalPokemonSpeciesUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('bulb');

      expect(result.kind, PokemonExternalSpeciesSearchResultKind.suggestions);
      expect(result.suggestions.length, 1);
      expect(result.suggestions.single.speciesId, 'bulbasaur');
      expect(result.suggestions.single.primaryName, 'Bulbasaur');
      expect(result.suggestions.single.nationalDex, 1);
      expect(repository.fetchShowdownPokedexSnapshotCallCount, 1);
    });

    test('returns suggestions for a dex query', () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshot: <String, dynamic>{
          'pikachu': <String, dynamic>{
            'name': 'Pikachu',
            'num': 25,
            'gen': 1,
          },
          'raichu': <String, dynamic>{
            'name': 'Raichu',
            'num': 26,
            'gen': 1,
          },
        },
      );
      final useCase = SearchExternalPokemonSpeciesUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('025');

      expect(result.kind, PokemonExternalSpeciesSearchResultKind.suggestions);
      expect(result.suggestions.map((entry) => entry.speciesId), <String>[
        'pikachu',
      ]);
    });

    test('returns noResults for a valid mono-species query with no match',
        () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshot: <String, dynamic>{
          'pikachu': <String, dynamic>{
            'name': 'Pikachu',
            'num': 25,
            'gen': 1,
          },
        },
      );
      final useCase = SearchExternalPokemonSpeciesUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('bulbasaur');

      expect(result.kind, PokemonExternalSpeciesSearchResultKind.noResults);
      expect(result.message, contains('Aucun Pokémon externe trouvé'));
    });

    test('maps repository failures to an error result', () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshotError: const EditorPersistenceException(
          'Showdown snapshot indisponible',
        ),
      );
      final useCase = SearchExternalPokemonSpeciesUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('pikachu');

      expect(result.kind, PokemonExternalSpeciesSearchResultKind.error);
      expect(result.message, 'Showdown snapshot indisponible');
    });
  });
}

class _FakePokemonExternalSourceRepository
    implements PokemonExternalSourceRepository {
  _FakePokemonExternalSourceRepository({
    this.showdownPokedexSnapshot = const <String, dynamic>{},
    this.showdownPokedexSnapshotError,
  });

  final Map<String, dynamic> showdownPokedexSnapshot;
  final EditorApplicationException? showdownPokedexSnapshotError;
  int fetchShowdownPokedexSnapshotCallCount = 0;

  @override
  Future<Map<String, dynamic>> fetchShowdownPokedexSnapshot() async {
    fetchShowdownPokedexSnapshotCallCount += 1;
    final error = showdownPokedexSnapshotError;
    if (error != null) {
      throw error;
    }
    return showdownPokedexSnapshot;
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownSpeciesPayload(String speciesId) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownMovesSnapshot() {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonPayload(String speciesId) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonSpeciesPayload(
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiEvolutionChainPayload(
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonExternalBinaryAsset> fetchBinaryAsset(String sourceUrl) {
    throw UnimplementedError();
  }
}

```

## 14. Note explicite sur le report lui-même

Ce report n’inclut pas sa propre copie intégrale dans son annexe pour éviter une récursion infinie.

## 15. Note explicite sur git

Aucun commit git, amend, rebase, merge, push, tag, stash ou autre écriture git n’a été effectué pendant ce lot.
