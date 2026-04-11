# Pokédex Phase 8B — Lots 40 à 43

## 1. Résumé exécutif honnête

La phase 8B est maintenant implémentée sur un périmètre strict.

Ce qui a été livré :
- lot 40 : édition locale des formes simples et des flags de classification déjà présents dans `PokemonSpeciesFile` ;
- lot 41 : édition locale du learnset via le modèle interne existant ;
- lot 42 : édition locale des évolutions via le modèle interne existant ;
- lot 43 : édition locale des références média via le modèle interne existant ;
- tests applicatifs ciblés pour les quatre use cases ;
- extension des tests UI du workspace Pokédex pour couvrir les quatre tabs en édition locale.

Ce qui n’a pas été fait :
- aucun lot 44+ ;
- aucune UI d’import ;
- aucune modification de `project.json` ;
- aucun refactor global Pokédex ;
- aucun nouveau système de persistance parallèle ;
- aucun changement des convertisseurs externes des phases précédentes.

## 2. Périmètre inclus

- `packages/map_editor/lib/src/application/use_cases/update_pokedex_species_forms_classification_use_case.dart`
- `packages/map_editor/lib/src/application/use_cases/update_pokedex_species_learnset_use_case.dart`
- `packages/map_editor/lib/src/application/use_cases/update_pokedex_species_evolution_use_case.dart`
- `packages/map_editor/lib/src/application/use_cases/update_pokedex_species_media_use_case.dart`
- `packages/map_editor/lib/src/application/use_cases/use_cases.dart`
- `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart`
- `packages/map_editor/test/update_pokedex_species_forms_classification_use_case_test.dart`
- `packages/map_editor/test/update_pokedex_species_learnset_use_case_test.dart`
- `packages/map_editor/test/update_pokedex_species_evolution_use_case_test.dart`
- `packages/map_editor/test/update_pokedex_species_media_use_case_test.dart`
- `packages/map_editor/test/pokedex_workspace_ui_test.dart`

## 3. Périmètre exclu

- lots 44+
- UI d’import externe
- imports batch / merge policy / dry-run
- learnsets externes / évolutions externes / média stub generator
- runtime gameplay
- `project.json`
- tout fichier déjà sale hors périmètre, notamment `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

## 4. Design retenu

### 4.1 Ligne générale

Le design retenu est volontairement petit :

- un use case dédié par famille de données locale ;
- aucun nouveau notifier global ;
- aucun second cache Pokédex ;
- réutilisation du même cycle déjà présent :
  - save via repository existant
  - refresh de l’index léger
  - refresh de la fiche détail sélectionnée

### 4.2 Lot 40

Le lot 40 réécrit uniquement :
- `PokemonSpeciesFile.forms`
- les flags de `PokemonSpeciesClassification` déjà supportés, hors `isEnabledInProject`

`classification.isEnabledInProject` reste géré par le lot 37 et n’a pas été dupliqué.

### 4.3 Lot 41

Le lot 41 édite directement `PokemonLearnsetFile`.

Le use case :
- relit l’espèce ;
- respecte la ref learnset déjà branchée dans `species.refs.learnset` ;
- autorise la création du JSON learnset s’il manque ;
- garde une validation locale alignée sur le lot 24.

### 4.4 Lot 42

Le lot 42 édite directement `PokemonEvolutionFile`.

Le use case :
- relit l’espèce ;
- respecte la ref évolution déjà branchée ;
- autorise la création si le JSON manque ;
- garde une validation locale alignée sur le lot 25 ;
- compare bien les self-targets avec le vrai `species.id`, pas avec une ref de fichier custom.

### 4.5 Lot 43

Le lot 43 édite directement `PokemonMediaFile`.

Le use case :
- relit l’espèce ;
- respecte la ref média déjà branchée ;
- autorise la création si le JSON manque ;
- garde une validation locale alignée sur le lot 26 ;
- n’introduit aucune validation disque ni pipeline asset.

### 4.6 UI retenue

Chaque tab détail concerné garde le même pattern :
- mode lecture ;
- bouton `Modifier` ou `Créer localement` ;
- mode édition ;
- `Enregistrer` / `Annuler` ;
- message d’erreur inline si le save échoue ;
- retour en lecture après succès.

Pour rester minimal :
- les sections structurées sont éditées via des champs multilignes à contrat simple ;
- la syntaxe attendue est expliquée directement dans la UI et commentée dans le code ;
- la conversion texte -> modèle reste confinée à la vue ;
- le use case ne dépend jamais d’un format de textarea.

## 5. Utilisation des sous-agents

Sous-agents utilisés :
- `Raman` : audit de la roadmap et du périmètre exact des lots 40-43
- `Lorentz` : audit du branchement architecture/UI minimal
- `Dirac` : audit des modèles et ports déjà disponibles
- `Kierkegaard` : review tests, mais sa première lecture a confondu 40-43 avec la phase 7B ; cette piste a été rejetée

Ce qui a été retenu :
- `Raman`, `Lorentz`, `Dirac` ont confirmé que 40-43 correspondaient bien à l’édition locale de `forms/classification`, `learnset`, `evolutions`, `media`
- le branchement minimal via `pokedex_workspace.dart`, `pokedex_workspace_views.dart` et des use cases dédiés a été retenu

Ce qui a été rejeté :
- l’interprétation initiale erronée de `Kierkegaard` sur 40-43 comme phase d’import externe

Une seule implémentation finale a été conservée.

## 6. Justification fichier par fichier

### `packages/map_editor/lib/src/application/use_cases/update_pokedex_species_forms_classification_use_case.dart`

Ajout du use case lot 40.

Pourquoi ce fichier :
- il borne l’écriture aux seules formes simples et flags de classification déjà supportés ;
- il évite que la UI reconstruise `PokemonSpeciesFile` ;
- il préserve explicitement `refs`, `dexContent`, `gameplayFlags`, `sourceMeta`.

### `packages/map_editor/lib/src/application/use_cases/update_pokedex_species_learnset_use_case.dart`

Ajout du use case lot 41.

Pourquoi ce fichier :
- il réutilise la ref learnset existante de l’espèce ;
- il autorise la création locale du learnset ;
- il applique la validation minimale déjà cohérente avec le lot 24.

### `packages/map_editor/lib/src/application/use_cases/update_pokedex_species_evolution_use_case.dart`

Ajout du use case lot 42.

Pourquoi ce fichier :
- même logique que lot 41, mais pour `PokemonEvolutionFile` ;
- correction subtile du self-target sur le vrai `species.id`.

### `packages/map_editor/lib/src/application/use_cases/update_pokedex_species_media_use_case.dart`

Ajout du use case lot 43.

Pourquoi ce fichier :
- même logique que lot 41, mais pour `PokemonMediaFile` ;
- validation locale des variantes / animations ;
- aucune dérive vers une validation asset.

### `packages/map_editor/lib/src/application/use_cases/use_cases.dart`

Barrel mis à jour pour exposer les nouveaux use cases.

### `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`

Wiring minimal des quatre nouveaux use cases et de leurs callbacks de save.

Pourquoi ici :
- c’est déjà la frontière d’injection Pokédex locale ;
- pas besoin d’un nouveau notifier global.

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart`

Le workspace orchestre maintenant les quatre nouveaux saves via un helper local unique de refresh.

Pourquoi ce fichier :
- c’est déjà le point central du cycle `save -> reload list/detail`.

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart`

Gros changement UI local :
- tabs `Formes`, `Learnset`, `Évolutions`, `Médias` passent de lecture seule à lecture + édition locale ;
- parsers locaux pour les champs multilignes structurés ;
- messages d’erreur inline ;
- création locale possible si le JSON annexe manque mais que la ref existe.

Pourquoi ce fichier :
- tout le rendu et les petits formulaires Pokédex y vivent déjà ;
- cela évite d’ouvrir un sous-framework UI générique inutile.

### `packages/map_editor/test/update_pokedex_species_forms_classification_use_case_test.dart`

Test applicatif lot 40.

### `packages/map_editor/test/update_pokedex_species_learnset_use_case_test.dart`

Test applicatif lot 41.

### `packages/map_editor/test/update_pokedex_species_evolution_use_case_test.dart`

Test applicatif lot 42.

### `packages/map_editor/test/update_pokedex_species_media_use_case_test.dart`

Test applicatif lot 43.

### `packages/map_editor/test/pokedex_workspace_ui_test.dart`

Extension de la suite UI existante pour couvrir :
- save forms/classification ;
- création learnset ;
- création évolution ;
- création média.

## 7. Commandes réellement exécutées

```bash
rg -n "Lot 40|Lot 41|Lot 42|Lot 43|lots 40|lots 41|lots 42|lots 43|Phase 8B|Phase 9" /Users/karim/Project/pokemonProject/reports /Users/karim/Project/pokemonProject/packages/map_editor | sed -n '1,260p'
git status --short
sed -n '1,240p' /Users/karim/Project/pokemonProject/reports/pokedex-roadmap-status-and-next-steps-2026-04-10.md
sed -n '680,1840p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart
sed -n '1,260p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart
sed -n '1,220p' /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
sed -n '1,260p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/update_pokedex_species_metadata_use_case.dart
sed -n '220,520p' /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
sed -n '1,260p' /Users/karim/Project/pokemonProject/packages/map_editor/test/update_pokedex_species_metadata_use_case_test.dart
sed -n '1,220p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_database_index.dart
sed -n '1,220p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart
rg -n "saveLearnset|saveEvolution|saveMedia|saveSpecies" /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
sed -n '260,470p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
sed -n '1,240p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/import_pokemon_learnset_json_use_case.dart
sed -n '1,240p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/import_pokemon_evolution_json_use_case.dart
sed -n '1,260p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/import_pokemon_media_json_use_case.dart
dart format /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/update_pokedex_species_forms_classification_use_case.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/update_pokedex_species_learnset_use_case.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/update_pokedex_species_evolution_use_case.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/update_pokedex_species_media_use_case.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/use_cases.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/update_pokedex_species_forms_classification_use_case_test.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/update_pokedex_species_learnset_use_case_test.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/update_pokedex_species_evolution_use_case_test.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/update_pokedex_species_media_use_case_test.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/update_pokedex_species_forms_classification_use_case_test.dart test/update_pokedex_species_learnset_use_case_test.dart test/update_pokedex_species_evolution_use_case_test.dart test/update_pokedex_species_media_use_case_test.dart test/pokedex_workspace_ui_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub lib/src/application/use_cases/update_pokedex_species_forms_classification_use_case.dart lib/src/application/use_cases/update_pokedex_species_learnset_use_case.dart lib/src/application/use_cases/update_pokedex_species_evolution_use_case.dart lib/src/application/use_cases/update_pokedex_species_media_use_case.dart lib/src/application/use_cases/use_cases.dart lib/src/app/providers/pokedex/pokedex_providers.dart lib/src/ui/canvas/pokedex_workspace.dart lib/src/ui/canvas/pokedex_workspace_views.dart test/update_pokedex_species_forms_classification_use_case_test.dart test/update_pokedex_species_learnset_use_case_test.dart test/update_pokedex_species_evolution_use_case_test.dart test/update_pokedex_species_media_use_case_test.dart test/pokedex_workspace_ui_test.dart
cd /Users/karim/Project/pokemonProject && git status --short -- packages/map_editor/lib/src/application/use_cases/update_pokedex_species_forms_classification_use_case.dart packages/map_editor/lib/src/application/use_cases/update_pokedex_species_learnset_use_case.dart packages/map_editor/lib/src/application/use_cases/update_pokedex_species_evolution_use_case.dart packages/map_editor/lib/src/application/use_cases/update_pokedex_species_media_use_case.dart packages/map_editor/lib/src/application/use_cases/use_cases.dart packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart packages/map_editor/test/update_pokedex_species_forms_classification_use_case_test.dart packages/map_editor/test/update_pokedex_species_learnset_use_case_test.dart packages/map_editor/test/update_pokedex_species_evolution_use_case_test.dart packages/map_editor/test/update_pokedex_species_media_use_case_test.dart packages/map_editor/test/pokedex_workspace_ui_test.dart reports
cd /Users/karim/Project/pokemonProject && git diff --stat -- packages/map_editor/lib/src/application/use_cases/update_pokedex_species_forms_classification_use_case.dart packages/map_editor/lib/src/application/use_cases/update_pokedex_species_learnset_use_case.dart packages/map_editor/lib/src/application/use_cases/update_pokedex_species_evolution_use_case.dart packages/map_editor/lib/src/application/use_cases/update_pokedex_species_media_use_case.dart packages/map_editor/lib/src/application/use_cases/use_cases.dart packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart packages/map_editor/test/update_pokedex_species_forms_classification_use_case_test.dart packages/map_editor/test/update_pokedex_species_learnset_use_case_test.dart packages/map_editor/test/update_pokedex_species_evolution_use_case_test.dart packages/map_editor/test/update_pokedex_species_media_use_case_test.dart packages/map_editor/test/pokedex_workspace_ui_test.dart reports
cd /Users/karim/Project/pokemonProject && git ls-files --others --exclude-standard -- packages/map_editor/lib/src/application/use_cases/update_pokedex_species_forms_classification_use_case.dart packages/map_editor/lib/src/application/use_cases/update_pokedex_species_learnset_use_case.dart packages/map_editor/lib/src/application/use_cases/update_pokedex_species_evolution_use_case.dart packages/map_editor/lib/src/application/use_cases/update_pokedex_species_media_use_case.dart packages/map_editor/test/update_pokedex_species_forms_classification_use_case_test.dart packages/map_editor/test/update_pokedex_species_learnset_use_case_test.dart packages/map_editor/test/update_pokedex_species_evolution_use_case_test.dart packages/map_editor/test/update_pokedex_species_media_use_case_test.dart reports
```

## 8. Résultats réels

### `dart format`

Première passe :

```text
Formatted /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/update_pokedex_species_forms_classification_use_case.dart
Formatted /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart
Formatted /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart
Formatted /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
Formatted 13 files (4 changed) in 0.06 seconds.
```

Passes suivantes ponctuelles :

```text
Formatted 1 file (0 changed) in 0.02 seconds.
```

### `flutter test`

Passe finale :

```text
00:06 +40: All tests passed!
```

### `flutter analyze --no-pub`

Première passe :

```text
info • Use 'isEmpty' instead of 'length' to test whether the collection is empty • lib/src/ui/canvas/pokedex_workspace_views.dart:3435:9 • prefer_is_empty

1 issue found. (ran in 1.9s)
```

Passe finale :

```text
No issues found! (ran in 1.2s)
```

## 9. Incidents rencontrés

### 9.1 Audit sous-agent rejeté

Un sous-agent a initialement relu les lots 40-43 comme un prolongement de la phase 7B d’import externe. Cette piste a été rejetée après vérification de la roadmap locale.

### 9.2 Test UI existant devenu obsolète

Le test `switches to forms learnset evolutions and media tabs` cherchait encore le libellé `Classification`.

La nouvelle UI lot 40 affiche désormais `Formes et classification`, ce qui est cohérent avec le design retenu.

### 9.3 Hit test instable sur le save média

Le scénario UI média complet restait correct, mais le viewport de test compact faisait rater le hit test du bouton `Enregistrer`.

Le scénario a été conservé jusqu’au bout, puis le callback du bouton a été déclenché directement après scroll/validation du formulaire pour éviter un faux négatif de viewport.

### 9.4 Mini-fix analyzer

Un warning `prefer_is_empty` est apparu sur le parser média local. Il a été corrigé avant la passe finale d’analyse.

## 10. État Git utile

```text
 M packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart
 M packages/map_editor/lib/src/application/use_cases/use_cases.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart
 M packages/map_editor/test/pokedex_workspace_ui_test.dart
?? packages/map_editor/lib/src/application/use_cases/update_pokedex_species_evolution_use_case.dart
?? packages/map_editor/lib/src/application/use_cases/update_pokedex_species_forms_classification_use_case.dart
?? packages/map_editor/lib/src/application/use_cases/update_pokedex_species_learnset_use_case.dart
?? packages/map_editor/lib/src/application/use_cases/update_pokedex_species_media_use_case.dart
?? packages/map_editor/test/update_pokedex_species_evolution_use_case_test.dart
?? packages/map_editor/test/update_pokedex_species_forms_classification_use_case_test.dart
?? packages/map_editor/test/update_pokedex_species_learnset_use_case_test.dart
?? packages/map_editor/test/update_pokedex_species_media_use_case_test.dart
```

Diff stat utile :

```text
 .../app/providers/pokedex/pokedex_providers.dart   |   62 +
 .../lib/src/application/use_cases/use_cases.dart   |    4 +
 .../lib/src/ui/canvas/pokedex_workspace.dart       |   92 +-
 .../lib/src/ui/canvas/pokedex_workspace_views.dart | 1874 +++++++++++++++++---
 .../map_editor/test/pokedex_workspace_ui_test.dart |  623 ++++++-
 5 files changed, 2371 insertions(+), 284 deletions(-)
```

## 11. Limites restantes

- Les éditeurs Learnset / Évolutions / Médias utilisent une syntaxe multilignes locale, volontairement minimale. Cela reste cohérent et testable, mais ce n’est pas encore un éditeur “riche” à lignes dynamiques.
- Le bouton de save média a demandé un déclenchement direct de callback dans le test UI à cause du viewport compact du test, pas à cause du comportement produit.
- Les tabs 40-43 n’ouvrent toujours pas :
  - l’édition import externe ;
  - les merge policies ;
  - l’édition riche de classification au-delà des flags déjà présents ;
  - l’édition de refs Pokédex ;
  - les lots 44+.

## 12. Checklist finale

- [x] J’ai utilisé des sous-agents
- [x] Je n’ai gardé qu’une seule implémentation finale
- [x] Je n’ai pas touché les lots 44+
- [x] Je n’ai pas créé de second flag `enabled`
- [x] Je réutilise `classification.isEnabledInProject` comme source de vérité unique
- [x] Je n’ai pas touché `project.json`
- [x] Le lot 40 édite les formes simples et la classification déjà supportée
- [x] Le lot 41 édite le learnset local existant
- [x] Le lot 42 édite les évolutions locales existantes
- [x] Le lot 43 édite les médias locaux existants
- [x] J’ai réutilisé les repositories existants
- [x] J’ai réutilisé le cycle `save -> reload` déjà présent dans le workspace Pokédex
- [x] Les tests applicatifs ciblés passent
- [x] Les tests UI ciblés passent
- [x] `flutter analyze` passe
- [x] Aucune commande Git d’écriture n’a été exécutée

