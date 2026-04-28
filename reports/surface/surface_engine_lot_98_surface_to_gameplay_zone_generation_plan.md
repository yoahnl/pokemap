# Lot 98 — Surface to GameplayZone Generation Plan Model V0

## 1. Résumé exécutif honnête

Le Lot 98 ajoute dans `map_core` une brique pure de planification :

```text
SurfaceLayer / SurfaceCellPlacement
→ SurfaceGameplayZoneGenerationSource
→ SurfaceGameplayZoneGenerationPlan
→ MapGameplayZone candidates
```

La map réelle n'est jamais mutée. Aucune UI n'est branchée. Aucun runtime ni gameplay n'est modifié.

L'opération permet maintenant :

- de normaliser une source de cellules Surface ;
- de produire des rectangles candidats selon `boundingBox` ou `greedyRectangles` ;
- de produire des `MapGameplayZone` prêtes à ajouter plus tard ;
- de mesurer la couverture ;
- de signaler cellules en trop, trop de rectangles, overlaps existants et collisions d'ID ;
- de supporter les drafts behavior encounter/tall grass, movement/surf et hazard/lava avec les payloads existants.

## 2. Périmètre

Inclus :

- opération pure dans `map_core` ;
- modèles de plan non persistants ;
- tests ciblés ;
- export public via `map_core.dart` ;
- rapport.

Exclus :

- aucune modification `MapData` ;
- aucune modification `MapGameplayZone` ;
- aucune modification `SurfaceLayer` / `SurfaceCellPlacement` ;
- aucun JSON ;
- aucun generated/build_runner ;
- aucun `map_editor` ;
- aucune UI ;
- aucun runtime ;
- aucun gameplay surf/tallGrass/hazard codé.

## 3. Gate 0 — status initial

Commandes :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
```

Résultat :

```text
PWD
/Users/karim/Project/pokemonProject

BRANCH
main

STATUS

DIFF_STAT

LOG
8d62718f lot 97/95: Surface Gameplay - Surface to Gameplay Zone Authoring Workflow Spec
ac7984f2 lot 96/95: Surface Gameplay - Zones Bridge Decision Report
a4d62f39 lot 94/95: Surface Gameplay
83654389 feat: add surface runtime test files and golden slice reports
1f900e67 feat(map_runtime): render surface layers
da2b244d feat(map_runtime): add surface runtime resolver
32fbb0b5 feat(map_editor): improve surface mapping editor
d5561df7 feat(map_editor): edit surface role animation mapping
935a0036 feat(map_editor): animate surface editor previews
fe03b827 feat(map_editor): render surface atlas tile previews
```

Changements préexistants : aucun.

## 4. Context Mode usage

Context Mode utilisé pour :

- Gate 0 ;
- audit large ;
- lectures multi-fichiers ;
- sorties tests/analyze ;
- review des sorties volumineuses ;
- gate final ;
- `ctx_stats`.

Audit initial :

```text
12 commandes
4 576 lignes
455.5 KB indexés
21 sections indexées
5 recherches Context Mode
```

## 5. Audit SurfaceLayer / placements

Fichiers audités :

- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/operations/surface_layer_placements.dart`
- tests SurfaceLayer existants.

Findings :

- `SurfaceCellPlacement` contient `x`, `y`, `surfacePresetId`.
- `SurfaceLayer` stocke une liste sparse.
- Une coordonnée ne doit contenir qu'un placement en V0.
- `paintSurfacePlacement` remplace la coordonnée existante au lieu de dupliquer.
- `replaceSurfacePlacements` refuse les coordonnées dupliquées.
- Les opérations trient par `y`, puis `x`, puis preset pour garder des diffs stables.
- Les validations de bounds existent déjà quand l'opération reçoit `mapSize`.

Source fiable pour Lot 98 :

```text
placements dédupliqués
surfacePresetId non vide
coordonnées en ordre stable
```

## 6. Audit MapGameplayZone / MapRect

Fichiers audités :

- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_gameplay_zone_payloads.dart`
- `packages/map_core/lib/src/operations/map_gameplay_zones.dart`
- `packages/map_core/lib/src/models/geometry.dart`

Findings :

- `MapData` contient déjà `gameplayZones`.
- `MapGameplayZone` a `id`, `name`, `kind`, `area`, `priority`, et payloads typés.
- `area` est `MapRect(pos: GridPos, size: GridSize)`.
- `GameplayZoneKind.encounter` utilise `EncounterZonePayload`.
- `GameplayZoneKind.movement` utilise `MovementZonePayload`.
- `GameplayZoneKind.hazard` utilise `HazardZonePayload`.
- `GameplayZoneKind.special/custom` utilise `SpecialZonePayload`.
- Les opérations `addGameplayZoneToMap` / `updateGameplayZoneOnMap` normalisent et valident.
- La priorité existe déjà, mais Lot 98 ne résout pas le gameplay : il prépare seulement des zones.

Contraintes respectées :

- produire des `MapGameplayZone` valides ;
- ne pas les ajouter à la map ;
- ne pas changer les modèles existants.

## 7. Audit conventions map_core

Conventions observées :

- opérations pures sous `lib/src/operations`;
- export public via `packages/map_core/lib/map_core.dart`;
- modèles persistants avec Freezed, mais opérations/helpers manuels acceptés ;
- `ValidationException` utilisée pour les refus métier ;
- listes immuables exposées via `List.unmodifiable`;
- ordre stable important pour JSON/diffs.

Décision :

```text
Créer des classes manuelles immuables non persistantes.
Ne pas lancer build_runner.
Ne pas créer de JSON.
```

## 8. Décision de design

Le Lot 98 crée un modèle de planification non persistant.

API principale :

```dart
createSurfaceGameplayZoneGenerationPlan(...)
```

Entrées :

- source Surface ;
- behavior draft utilisant les payloads existants ;
- stratégie de génération ;
- préfixes ID/nom ;
- priorité ;
- zones existantes optionnelles ;
- seuil warning pour rectangles.

Sortie :

```text
SurfaceGameplayZoneGenerationPlan
```

Le plan contient :

- source ;
- behavior ;
- strategy ;
- generatedZones ;
- rectangles ;
- coverage ;
- diagnostics.

## 9. Modèles / opérations créés

Fichier créé :

```text
packages/map_core/lib/src/operations/surface_to_gameplay_zone_generation_plan.dart
```

Types créés :

- `SurfaceGameplayZoneGenerationStrategy`
- `SurfaceGameplayZoneGenerationDiagnosticSeverity`
- `SurfaceGameplayZoneGenerationDiagnosticKind`
- `SurfaceGameplayZoneGenerationSource`
- `SurfaceGameplayZoneBehaviorDraft`
- `SurfaceGameplayZoneCoverageReport`
- `SurfaceGameplayZoneGenerationDiagnostic`
- `SurfaceGameplayZoneGenerationPlan`

Fonction créée :

- `createSurfaceGameplayZoneGenerationPlan(...)`

Export ajouté :

```dart
export 'src/operations/surface_to_gameplay_zone_generation_plan.dart';
```

## 10. Stratégie boundingBox

Algorithme :

```text
minX, minY, maxX, maxY
→ MapRect englobant
```

Coverage :

- toutes les cellules source sont couvertes ;
- `missingSourceCellCount = 0` ;
- `extraCellCount = aire du rectangle - cellules source`.

Diagnostic :

- `extraCellsIncluded` warning si `extraCellCount > 0`.

Testé :

- rectangle plein → couverture exacte ;
- forme en L → une zone, une cellule extra, warning.

## 11. Stratégie greedyRectangles

Algorithme V0 :

```text
scanner y/x
prendre première cellule non couverte
étendre horizontalement au maximum
étendre verticalement tant que toutes les lignes contiennent cette largeur
produire un rectangle
retirer les cellules couvertes
continuer
```

But :

- exactitude ;
- déterminisme ;
- lisibilité ;
- pas d'optimal minimal.

Testé :

- rectangle plein → une zone ;
- forme en L → deux rectangles exacts ;
- deux îlots → deux zones ;
- ordre d'entrée sans influence.

## 12. Coverage report

Type créé :

```text
SurfaceGameplayZoneCoverageReport
```

Champs :

- `sourceCellCount`
- `coveredSourceCellCount`
- `missingSourceCellCount`
- `extraCellCount`
- `zoneCount`
- `isExact`

Usage UI futur :

```text
Cette génération couvre exactement 42 cellules.
Attention : 6 cellules hors surface seront incluses.
Cette surface est irrégulière : 8 zones seront créées.
```

## 13. Diagnostics

Types créés :

- `SurfaceGameplayZoneGenerationDiagnostic`
- `SurfaceGameplayZoneGenerationDiagnosticSeverity`
- `SurfaceGameplayZoneGenerationDiagnosticKind`

Severities :

- `error`
- `warning`
- `info`

Kinds V0 :

- `emptySource`
- `missingSurfacePresetId`
- `noGeneratedZone`
- `extraCellsIncluded`
- `tooManyRectangles`
- `overlapsExistingGameplayZone`
- `unsupportedBehavior`
- `zoneIdCollisionResolved`

Note :

`emptySource` et `missingSurfacePresetId` existent pour l'UI/diagnostic futur, mais la source V0 refuse déjà ces cas via `ValidationException`.

## 14. Behavior drafts supportés

Type créé :

```text
SurfaceGameplayZoneBehaviorDraft
```

Constructeurs :

- `.encounter(EncounterZonePayload)`
- `.movement(MovementZonePayload)`
- `.hazard(HazardZonePayload)`
- `.special(SpecialZonePayload)`

Tests explicites :

- tallGrass → `GameplayZoneKind.encounter` + `EncounterZonePayload(encounterKind: walk)`;
- surfableWater → `GameplayZoneKind.movement` + `MovementZonePayload(requiredMode: surf)`;
- lava → `GameplayZoneKind.hazard` + `HazardZonePayload(hazardKind: lava)`.

## 15. ID / naming strategy

Règle :

- une zone : `id = zoneIdPrefix`, `name = zoneNamePrefix` ;
- plusieurs zones : suffixes `-1`, `-2`, etc. et noms `1`, `2`, etc. ;
- si collision avec `existingZones`, suffixer jusqu'à trouver un ID libre ;
- diagnostic info `zoneIdCollisionResolved` si un ID a été ajusté.

Exemple :

```text
grass
grass-1 si grass existe déjà
```

## 16. Overlap strategy

Si `existingZones` est fourni :

- chaque rectangle généré est comparé aux `area` existantes ;
- les overlaps ne bloquent pas ;
- un warning `overlapsExistingGameplayZone` est ajouté.

Décision :

```text
Lot 98 prépare le diagnostic, mais ne décide pas de fusion/suppression.
```

## 17. Fichiers créés

- `packages/map_core/lib/src/operations/surface_to_gameplay_zone_generation_plan.dart`
- `packages/map_core/test/surface_to_gameplay_zone_generation_plan_test.dart`
- `reports/surface/surface_engine_lot_98_surface_to_gameplay_zone_generation_plan.md`

## 18. Fichiers modifiés

- `packages/map_core/lib/map_core.dart`

## 19. Fichiers supprimés

Aucun.

## 20. Tests lancés

RED TDD :

```bash
cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_plan_test.dart
```

Tests finaux :

```bash
cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_plan_test.dart
cd packages/map_core && dart test test/map_gameplay_zone_validation_test.dart
cd packages/map_core && dart test test/surface_layer_placements_test.dart
cd packages/map_core && dart test
```

## 21. Résultats

RED TDD :

```text
Échec attendu : symboles Lot 98 absents.
Exemples : SurfaceGameplayZoneGenerationSource, SurfaceGameplayZoneBehaviorDraft,
SurfaceGameplayZoneGenerationDiagnosticKind, createSurfaceGameplayZoneGenerationPlan.
```

Test ciblé Lot 98 :

```text
00:00 +16: All tests passed!
```

Gameplay zone validation :

```text
00:00 +1: All tests passed!
```

SurfaceLayer placements :

```text
00:00 +14: All tests passed!
```

`map_core` complet :

```text
00:01 +1271: All tests passed!
```

## 22. Analyse lancée

Commande :

```bash
cd packages/map_core && dart analyze lib/src/operations/surface_to_gameplay_zone_generation_plan.dart test/surface_to_gameplay_zone_generation_plan_test.dart lib/map_core.dart
```

## 23. Résultats analyze

```text
Analyzing surface_to_gameplay_zone_generation_plan.dart, surface_to_gameplay_zone_generation_plan_test.dart, map_core.dart...
No issues found!
```

## 24. Git status final

Commandes :

```bash
git status --short --untracked-files=all
git diff --stat
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
git diff --check
```

Résultat :

```text
STATUS
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/surface_to_gameplay_zone_generation_plan.dart
?? packages/map_core/test/surface_to_gameplay_zone_generation_plan_test.dart
?? reports/surface/surface_engine_lot_98_surface_to_gameplay_zone_generation_plan.md

DIFF_STAT
 packages/map_core/lib/map_core.dart | 1 +
 1 file changed, 1 insertion(+)

TEMP_FILES

DIFF_CHECK
DONE
```

Note : `git diff --stat` ne compte pas les fichiers non trackés. Ils sont listés dans le status final.

Changements préexistants : aucun.

Changements du Lot 98 :

- export `map_core.dart` ;
- opération pure Surface → GameplayZone ;
- tests Lot 98 ;
- rapport Lot 98.

Fichiers temporaires : aucun.

`git diff --check` : clean.

## 25. Périmètre explicitement non touché

Confirmé :

- `MapData` non modifié ;
- `MapGameplayZone` non modifié ;
- `SurfaceLayer` non modifié ;
- `SurfaceCellPlacement` non modifié ;
- `ProjectManifest` non modifié ;
- `surface.dart` non modifié ;
- `surface_catalog.dart` non modifié ;
- `map_layer.dart` non modifié ;
- `map_gameplay_zone_payloads.dart` non modifié ;
- `map_editor` non modifié ;
- `map_runtime` non modifié ;
- `map_gameplay` non modifié ;
- `map_battle` non modifié ;
- aucun JSON ;
- aucun generated/build_runner ;
- aucun gameplay surf codé ;
- aucun tall grass encounter codé ;
- aucune collision Surface codée ;
- aucun Surface Studio ;
- aucun Surface Painter ;
- aucune migration legacy.

Note :

```text
map_core.dart modifié uniquement pour exporter la nouvelle opération.
```

## 26. ctx stats

Résumé compact :

```text
717.6K tokens saved
94.0% reduction
2.9 MB without context-mode
177.8 KB with context-mode
2.7 MB kept out of conversation
63 calls
v1.0.100
Update available: v1.0.100 -> v1.0.103
```

Répartition :

```text
ctx_batch_execute  3 calls  1.8 MB saved
ctx_search         7 calls  441.6 KB saved
ctx_execute       22 calls  312.3 KB saved
ctx_stats          7 calls   74.1 KB saved
ctx_index         20 calls   58.4 KB saved
ctx_doctor         3 calls   17.3 KB saved
ctx_upgrade        1 call     7.9 KB saved
```

## 27. Limites restantes

- L'algorithme greedy n'optimise pas le nombre minimal global de rectangles.
- `emptySource` et `missingSurfacePresetId` sont disponibles comme diagnostic kinds, mais la source V0 rejette ces cas avant plan.
- Les seuils UX définitifs restent à décider côté editor.
- Aucun plan n'est appliqué à une map dans ce lot.
- Aucun helper Surface-position runtime n'est ajouté.

## 28. Auto-critique

Le lot respecte bien la frontière `map_core` et ne crée pas de gameplay parallèle. Le choix de classes manuelles évite build_runner et JSON, ce qui est adapté à une brique de planification.

La limite honnête est que la surface sparse vers rectangles exacts reste un compromis : greedy est stable et testable, mais pas optimal. C'est acceptable V0 si l'UI expose le nombre de rectangles et les diagnostics.

## 29. Regard critique sur le prompt

Le prompt est très bien borné. Il force la brique pure avant l'UI, et empêche les dérives habituelles : modèle persistant, JSON, Surface Studio, runtime ou gameplay.

Point discutable : il demande des diagnostic kinds `emptySource` / `missingSurfacePresetId` tout en demandant des sources rejetées. J'ai conservé les kinds pour l'UI future, mais le constructeur V0 refuse les sources invalides afin que le plan ne se construise jamais sur une entrée vide.

## Evidence Pack

Status initial : section 3.

Commandes d'audit : sections 4 à 8.

Fichiers créés/modifiés : sections 17 à 18.

Tests et analyse : sections 20 à 23.

Contenu complet des fichiers : non recopié dans le rapport pour éviter de transformer l'Evidence Pack en doublon massif du diff ; les fichiers créés sont listés précisément et couverts par tests/analyze.

## Auto-review obligatoire

- Est-ce qu'un plan pur Surface → GameplayZone existe ? Oui.
- Est-ce qu'aucune map réelle n'est mutée ? Oui.
- Est-ce que SurfaceLayer reste visuel ? Oui.
- Est-ce que MapGameplayZone est réutilisé au lieu de dupliqué ? Oui.
- Est-ce que boundingBox est supporté ? Oui.
- Est-ce que greedyRectangles est supporté ? Oui.
- Est-ce que la couverture est mesurée ? Oui.
- Est-ce que les cellules en trop sont détectées ? Oui.
- Est-ce que tooManyRectangles est détecté ? Oui.
- Est-ce que les overlaps avec zones existantes sont détectés ? Oui.
- Est-ce que tallGrass / surfableWater / lava sont supportés comme drafts ? Oui.
- Est-ce que les tests ciblés passent ? Oui.
- Est-ce que map_core complet passe ? Oui.
- Est-ce que dart analyze ciblé passe ? Oui.
- Est-ce que Context Mode a été utilisé agressivement ? Oui.
- Est-ce que ctx stats est inclus ? Oui.
- Est-ce qu'un Lot 98-bis est nécessaire ? Non.
