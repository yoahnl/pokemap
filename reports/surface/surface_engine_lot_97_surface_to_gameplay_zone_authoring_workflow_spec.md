# Lot 97 — Surface → GameplayZone Authoring Workflow Spec V1

## 1. Résumé exécutif honnête

Le Lot 97 précise l'UX no-code du pont décidé au Lot 96 :

```text
SurfaceLayer peinte
→ action utilisateur explicite
→ assistant no-code
→ preview de génération
→ création de MapGameplayZone existantes
```

Décision principale : le futur workflow doit s'appeler **Créer un comportement depuis une surface** côté utilisateur. Il doit éviter les termes `MapGameplayZone`, `payload`, `enum`, `surfacePresetId`, et présenter des cartes métier : herbe haute, eau surfable, lave dangereuse, glace, boue/marais, comportement scripté.

Le workflow ne doit jamais créer une zone automatiquement en arrière-plan. La génération doit être visible, prévisualisée et confirmée.

Le point technique délicat reste la conversion :

```text
SurfaceLayer sparse cellule par cellule
→ MapGameplayZone area rectangulaire
```

La recommandation V0 est :

- calculer plusieurs candidats de génération ;
- préférer la décomposition en rectangles pour surfaces irrégulières raisonnables ;
- permettre un bounding box unique seulement si la couverture en trop est faible et explicitement visible ;
- rejeter l'option "une zone par cellule" sauf cas tiny/debug ;
- reporter le filtre `surfacePresetId` dans `MapGameplayZone` à un lot de décision ultérieur.

Ce lot ne code rien et ne crée aucun modèle.

## 2. Périmètre

Inclus :

- audit Surface Painter / SurfaceLayer ;
- audit GameplayZone editor ;
- audit UX existante ;
- audit runtime gameplay utile ;
- spécification du workflow assistant ;
- stratégie par comportement ;
- diagnostics UX ;
- architecture future conceptuelle ;
- roadmap post Lot 97.

Exclus :

- aucun code de production ;
- aucun modèle Dart ;
- aucun JSON codec ;
- aucune modification `ProjectManifest` ;
- aucune modification `MapGameplayZone` ;
- aucune modification `SurfaceLayer` ;
- aucun champ `surfacePresetId` dans `MapGameplayZone` ;
- aucun gameplay surf/tallGrass codé ;
- aucun runtime renderer ;
- aucune modification Surface Studio / Surface Painter.

## 3. Gate 0 — status initial

Commandes exécutées avant modification :

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
ac7984f2 lot 96/95: Surface Gameplay - Zones Bridge Decision Report
a4d62f39 lot 94/95: Surface Gameplay
83654389 feat: add surface runtime test files and golden slice reports
1f900e67 feat(map_runtime): render surface layers
da2b244d feat(map_runtime): add surface runtime resolver
32fbb0b5 feat(map_editor): improve surface mapping editor
d5561df7 feat(map_editor): edit surface role animation mapping
935a0036 feat(map_editor): animate surface editor previews
fe03b827 feat(map_editor): render surface atlas tile previews
5814f6e9 feat(map): add surface role resolver preview
```

Changements préexistants : aucun.

## 4. Context Mode usage

Context Mode a été utilisé pour :

- Gate 0 ;
- recherches `rg` larges ;
- lectures multi-fichiers ;
- inspection du rapport Lot 96 ;
- gate final ;
- `ctx_stats`.

Commandes d'audit indexées :

```bash
rg -n "SurfaceLayer|SurfaceCellPlacement|surfacePresetId|SurfacePainter|surface_painter|SurfacePaintingController|SurfacePalette|paintSurface|eraseSurface" packages/map_core/lib packages/map_editor/lib packages/map_editor/test
rg -n "GameplayZone|GameplayZoneKind|EncounterZonePayload|MovementZonePayload|HazardZonePayload|SpecialZonePayload|addGameplayZone|updateGameplayZone|selectGameplayZone|gameplay_zone" packages/map_core/lib packages/map_editor/lib packages/map_editor/test
rg -n "surface|Surface|gameplay zone|GameplayZone|zone|Zone|panel|workflow|assistant|wizard|dialog|preview|diagnostic" packages/map_editor/lib/src/features packages/map_editor/lib/src/ui packages/map_editor/test
rg -n "checkEncounterAtPlayerPosition|GameplayEncounter|EncounterKind|MovementMode|evaluateSurfAttempt|surf|HazardKind|gameplayZones|movement|hazard" packages/map_gameplay/lib packages/map_runtime/lib packages/map_core/lib
```

Résumé Context Mode :

- 16 commandes d'audit initiales ;
- 11 267 lignes indexées ;
- environ 1.2 MB de sortie gardée hors conversation ;
- 66 sections indexées.

Limite : le binaire shell `ctx` n'est pas garanti dans le `PATH`. Les outils MCP Context Mode sont disponibles et utilisés.

## 5. Audit Surface Painter / SurfaceLayer

Fichiers pertinents :

- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/operations/surface_layer_placements.dart`
- `packages/map_editor/lib/src/features/surface_painter/surface_painting_controller.dart`
- `packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart`
- `packages/map_editor/test/surface_painter/editor_notifier_surface_paint_test.dart`
- `packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart`

Findings :

- `SurfaceCellPlacement` contient `x`, `y`, `surfacePresetId`.
- `SurfaceLayer` stocke une liste sparse de placements.
- Une cellule ne porte qu'un placement Surface V0.
- `paintSurfacePlacement` remplace le preset à coordonnée identique.
- `eraseSurfacePlacement` retire une coordonnée, sans effet si elle est vide.
- `clearSurfacePlacements` existe côté opérations.
- `SurfacePaintingController` choisit ou crée le calque Surface cible.
- Le premier paint peut créer automatiquement `surface-main`.
- `EditorNotifier` marque la map dirty après peinture.
- Le palette panel sélectionne un `ProjectSurfacePreset.id`, pas un atlas ni une animation.
- La palette sait lister les presets peignables et créer/activer un SurfaceLayer.

Informations disponibles pour le futur workflow :

- SurfaceLayer active ;
- toutes les SurfaceLayer de la map ;
- liste des placements par `surfacePresetId` ;
- catalogue Surface du projet ;
- preset sélectionné ;
- map size ;
- dirty state existant ;
- mécanisme existant de création/selection de SurfaceLayer.

Conclusion :

La source de génération peut être construite sans modifier `SurfaceLayer` :

```text
map.layers.whereType<SurfaceLayer>()
→ placements groupés par surfacePresetId
→ surface source candidate
```

## 6. Audit GameplayZone editor

Fichiers pertinents :

- `packages/map_core/lib/src/models/map_gameplay_zone_payloads.dart`
- `packages/map_core/lib/src/operations/map_gameplay_zones.dart`
- `packages/map_editor/lib/src/application/services/gameplay_zone_editing_service.dart`
- `packages/map_editor/lib/src/application/services/gameplay_zone_editing_coordinator.dart`
- `packages/map_editor/lib/src/application/use_cases/gameplay_zone_use_cases.dart`
- `packages/map_editor/lib/src/ui/panels/gameplay_zone_properties_panel.dart`

Findings :

- `MapData` porte déjà `gameplayZones`.
- `MapGameplayZone` possède `id`, `name`, `kind`, `area`, `priority`, et payloads typés.
- `area` est rectangulaire via `MapRect`.
- `findGameplayZoneAtPos` résout par priorité.
- `addGameplayZoneToMap` et `updateGameplayZoneOnMap` normalisent/valident.
- L'éditeur crée déjà une zone 1x1 ou rectangulaire.
- La zone par défaut est `GameplayZoneKind.encounter`.
- Le panel actuel expose les champs id/nom/kind/priorité.
- Le panel expose encounter, movement, hazard, special.
- Encounter expose `encounterTableId`, `encounterKind`, `battleBackgroundRelativePath`.
- Movement expose `requiredMode`.
- Hazard expose `hazardKind`, `damagePerStep`.
- Special expose `scriptKey`.

Ce qui manque pour créer une zone depuis SurfaceLayer :

- un objet de preview avant mutation ;
- une liste de surfaces candidates ;
- un choix comportement métier ;
- un choix de stratégie de découpage ;
- un résumé de payload ;
- un mécanisme "appliquer" qui crée des `MapGameplayZone` normales ;
- diagnostics sur coverage et overlaps.

## 7. Audit UX existante

Findings :

- `EditorToolType.surfacePaint` et `EditorToolType.gameplayZonePlacement` existent déjà.
- `surfacePaint` exige un `SurfaceLayer` actif.
- `gameplayZonePlacement` est compatible avec tout layer.
- `MapCanvas` route déjà les interactions surface paint et gameplay zone placement.
- `SurfacePalettePanel` est un bon point d'entrée pour l'action future.
- `GameplayZonePropertiesPanel` est un bon point de sortie après confirmation.
- Le repo contient déjà des panels/assistants Surface Studio, mais l'UX Surface Studio est connue comme perfectible.

Points d'accroche recommandés :

1. Dans `SurfacePalettePanel`, près de la surface sélectionnée :

```text
Créer un comportement depuis cette surface
```

2. Dans le menu contextuel / inspector d'un SurfaceLayer :

```text
Créer une zone gameplay depuis ce calque
```

3. Dans le panel GameplayZone, empty state :

```text
Vous avez déjà peint des surfaces ? Créez une zone depuis une surface.
```

Éviter :

- un formulaire technique géant ;
- un dropdown principal de `GameplayZoneKind`;
- une action cachée dans Surface Studio.

## 8. Audit runtime gameplay utile

Fichiers pertinents :

- `packages/map_gameplay/lib/src/gameplay_encounter.dart`
- `packages/map_gameplay/lib/src/surf_evaluation.dart`
- `packages/map_gameplay/lib/src/gameplay_world_state.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

Findings :

- Les encounters sont réellement consommés par `checkEncounterAtPlayerPosition`.
- Les encounters filtrent par zone, kind, table et roll.
- `PlayableMapGame` choisit `EncounterKind.surf` si le joueur est en mode surf, sinon walk.
- `evaluateSurfAttempt` existe et évalue l'état surf.
- `GameplayWorldState` sait déjà considérer les zones movement surf comme eau/mouvement surf.
- Hazards sont modélisés, mais la consommation runtime complète n'est pas démontrée au même niveau.
- Ice/glissade et mud ralentissant ne semblent pas pleinement modélisés.

Conséquence produit :

- tall grass peut viser un comportement immédiatement utile via `encounter`.
- water/surf peut viser `movement` mais demande prudence sur l'UX et les bords.
- lava peut être spécifié via `hazard`, mais son runtime réel doit être confirmé plus tard.
- ice/mud doivent être marqués comme "préparation / futur comportement" si l'existant ne suffit pas.

## 9. Problème UX à résoudre

Aujourd'hui, l'utilisateur peut :

```text
peindre une surface visuelle
dessiner une zone gameplay
```

Mais il ne peut pas encore dire simplement :

```text
Cette surface d'herbe haute déclenche des rencontres.
Cette eau est surfable.
Cette lave fait des dégâts.
```

Le workflow Lot 97 doit supprimer la double saisie mentale :

```text
je peins la surface
je redessine la même forme comme zone gameplay
```

Le futur outil doit transformer une surface déjà peinte en proposition de zones gameplay, en laissant l'utilisateur confirmer.

## 10. Workflow cible Surface → GameplayZone

Nom comparé :

| Nom | Avantage | Limite |
| --- | --- | --- |
| Créer une zone gameplay depuis cette surface | précis pour l'équipe | expose "zone gameplay" |
| Transformer cette surface en zone gameplay | clair mais laisse croire que la surface change | ambigu sur la mutation |
| Associer un comportement à cette surface | bon mental model | peut laisser croire à un lien live |
| Créer un comportement depuis une surface | no-code, action explicite | demande une phrase secondaire |

Recommandation :

```text
Créer un comportement depuis une surface
```

Sous-texte :

```text
PokeMap va proposer des zones gameplay à partir des cellules peintes. Vous pourrez vérifier avant de créer.
```

Workflow assistant :

1. Choisir la surface source.
2. Choisir le comportement.
3. Paramétrer.
4. Choisir/inspecter la génération.
5. Prévisualiser.
6. Confirmer.
7. Ouvrir le panel GameplayZone sur la zone créée.

## 11. Étape 1 — Choisir surface source

Entrées :

- map active ;
- SurfaceLayer(s) ;
- placements ;
- catalogue Surface ;
- presets ;
- sélection cellulaire éventuelle future.

Liste candidate :

```text
Surface : Water
Preset : water
Calque : Surfaces
Cellules peintes : 42
```

Cas particuliers :

- plusieurs SurfaceLayer ;
- même `surfacePresetId` peint sur plusieurs calques ;
- preset absent du catalogue ;
- surface sans placement ;
- map sans SurfaceLayer.

UX :

- carte par surface candidate ;
- nom humain du preset en premier ;
- id technique en secondaire ;
- nombre de cellules ;
- mini aperçu si disponible ;
- badge "preset manquant" si nécessaire ;
- bouton "Utiliser cette surface".

Messages vides :

```text
Aucune surface peinte sur cette map.
Peignez d'abord une surface, puis revenez créer son comportement.
```

```text
Cette surface référence un preset absent du catalogue.
Corrigez le catalogue Surface avant de créer un comportement.
```

## 12. Étape 2 — Choisir comportement

Présenter des cartes métier :

| Carte | Zone cible | Payload cible | État V1 |
| --- | --- | --- | --- |
| Herbe haute avec rencontres | `encounter` | `EncounterZonePayload` | supportable maintenant |
| Eau surfable | `movement` | `MovementZonePayload(requiredMode: surf)` | supportable avec prudence |
| Lave dangereuse | `hazard` | `HazardZonePayload(lava)` | modèle existe, runtime à confirmer |
| Glace glissante | `movement` ou `special` | à préciser | futur / préparation |
| Boue ralentissante | `hazard(swamp)` ou movement futur | à préciser | partiel |
| Comportement personnalisé | `special` | `SpecialZonePayload` | avancé |

Chaque carte doit afficher :

- pictogramme ;
- phrase utilisateur ;
- comportement créé ;
- niveau de support.

Exemples de microcopy :

```text
Herbe haute avec rencontres
Crée une zone de rencontre sur les cellules de cette surface.
```

```text
Eau surfable
Crée une zone de déplacement Surf sur cette eau.
```

```text
Glace glissante
Prépare une zone de mouvement spécial. La glissade complète sera activée dans un futur lot.
```

## 13. Étape 3 — Paramétrer

### Herbe haute

Champs :

- table de rencontres ;
- type de rencontre : `walk` par défaut ;
- background de combat optionnel.

Recommandation :

- `encounterTableId` obligatoire pour confirmer ;
- `battleBackgroundRelativePath` optionnel ;
- `EncounterKind.walk` par défaut.

### Eau surfable

Champs :

- mode requis : Surf ;
- description utilisateur ;
- future condition capacité/badge/flag hors V1.

Recommandation :

- utiliser `MovementZonePayload(requiredMode: MovementMode.surf)` en première cible ;
- ne pas promettre de résoudre toutes les règles de bord ou transition de locomotion dans cette spec ;
- prévisualiser précisément la couverture.

### Lave dangereuse

Champs :

- danger : lave ;
- dégâts par pas.

Recommandation :

- `damagePerStep` obligatoire et supérieur à 0 côté UX ;
- avertir que le runtime hazard complet doit être vérifié dans un lot dédié.

### Glace

Champs :

- aucun champ définitif V1 ;
- option "préparer une zone spéciale" possible.

Recommandation :

- ne pas la présenter comme pleinement supportée ;
- l'indiquer "futur comportement" tant qu'il n'existe pas de modèle de glissade.

### Boue / marais

Champs :

- marais/danger via `HazardKind.swamp` possible ;
- ralentissement précis futur.

Recommandation :

- distinguer "marais dangereux" et "boue ralentissante" ;
- ne pas mapper automatiquement mud vers swamp si le produit veut seulement un slow.

## 14. Étape 4 — Génération / découpage des zones

Le conflit central :

```text
SurfaceLayer = sparse cells
MapGameplayZone = MapRect area
```

### Option A — Bounding box unique

Principe :

```text
prendre toutes les cellules Surface
générer un rectangle englobant
```

Avantages :

- très simple ;
- une seule zone ;
- lisible dans le panel actuel.

Inconvénients :

- peut couvrir des cellules sans surface ;
- dangereux pour eau/lave/rencontres ;
- mauvaise UX si surface organique.

Usage recommandé :

- seulement si couverture en trop faible ;
- toujours montrer le nombre de cellules hors surface incluses.

### Option B — Une zone par cellule

Avantages :

- exact ;
- pas de couverture hors surface.

Inconvénients :

- explosion de zones ;
- panel ingérable ;
- IDs/noms inutilisables ;
- maintenance mauvaise.

Usage recommandé :

- à éviter en V0 ;
- acceptable seulement comme fallback technique pour surfaces minuscules si aucune autre stratégie ne passe.

### Option C — Décomposition en rectangles

Principe :

```text
regrouper les cellules contiguës en rectangles
```

Avantages :

- compromis précision/lisibilité ;
- réutilise `MapGameplayZone`;
- limite la couverture en trop ;
- garde des zones éditables.

Inconvénients :

- algorithme à spécifier ;
- nombre de rectangles variable ;
- surfaces complexes nécessitent diagnostics.

Usage recommandé :

- stratégie principale V0 pour formes non triviales ;
- seuils UX à définir au Lot 98/99.

### Option D — Zone rectangulaire + futur filtre surfacePresetId

Avantages :

- modèle long terme plus précis ;
- évite explosion de zones ;
- permet "dans cette zone, seulement l'eau est surfable".

Inconvénients :

- demande modification modèle + JSON ;
- migration/diagnostics ;
- pas autorisé V0.

Verdict Lot 97 :

```text
V0 spec :
- proposer bounding box unique pour surfaces compactes ;
- proposer décomposition rectangles pour surfaces irrégulières ;
- afficher coverage avant confirmation ;
- refuser génération silencieuse ;
- reporter filtre surfacePresetId.
```

## 15. Étape 5 — Preview avant confirmation

La preview est obligatoire.

Elle doit afficher :

- cellules Surface source ;
- rectangles GameplayZone proposés ;
- cellules couvertes exactement ;
- cellules hors surface incluses ;
- cellules surface non couvertes ;
- nombre de zones ;
- comportement choisi ;
- payload résumé ;
- overlaps avec zones existantes.

Messages :

```text
Cette génération couvre exactement 42 cellules.
```

```text
Attention : 6 cellules hors surface seront incluses par la zone rectangulaire.
```

```text
Cette surface est irrégulière : 8 zones seront créées.
```

```text
2 zones existantes chevauchent cette génération.
```

Règle produit :

```text
Pas de confirmation sans preview lisible.
```

## 16. Étape 6 — Confirmation

À la confirmation :

- créer des `MapGameplayZone` existantes ;
- générer id/name stables et humains ;
- appliquer le payload choisi ;
- préserver le dirty state map existant ;
- sélectionner la première zone créée ou un groupe de résultat ;
- ouvrir le `GameplayZonePropertiesPanel` pour édition fine ;
- afficher un résumé post-action.

Exemple de résumé :

```text
3 zones de rencontre créées depuis Tall Grass.
Vous pouvez ajuster leurs paramètres dans le panneau Zone.
```

La génération est one-shot. Modifier la Surface plus tard ne modifie pas automatiquement les zones.

## 17. Stratégie tall grass

Workflow recommandé :

```text
Surface tall_grass
→ Herbe haute avec rencontres
→ MapGameplayZone(kind: encounter)
→ EncounterZonePayload(encounterKind: walk)
```

Décisions UX :

- `encounterTableId` obligatoire avant confirmation ;
- `battleBackgroundRelativePath` optionnel ;
- warning si aucune table de rencontres disponible ;
- warning si la surface générée chevauche une zone encounter existante ;
- priorité par défaut à définir au Lot 98/100.

Statut : meilleur premier comportement à coder plus tard, car encounters sont déjà consommés.

## 18. Stratégie surfable water

Workflow recommandé :

```text
Surface water
→ Eau surfable
→ MapGameplayZone(kind: movement)
→ MovementZonePayload(requiredMode: surf)
```

Décisions UX :

- ne pas mettre surf dans `ProjectSurfacePreset` ;
- ne pas rendre toute bounding box surfable sans avertissement ;
- préférer rectangles précis ;
- afficher les cellules hors eau couvertes ;
- conditions badge/ability/flag restent futures.

Question ouverte :

```text
requiredMode: surf
```

est le meilleur mapping initial observé, mais le comportement exact autour de `allowedModes` doit être verrouillé par le lot d'implémentation.

## 19. Stratégie lava

Workflow recommandé :

```text
Surface lava
→ Lave dangereuse
→ MapGameplayZone(kind: hazard)
→ HazardZonePayload(hazardKind: lava, damagePerStep: X)
```

Décisions UX :

- `damagePerStep` obligatoire ;
- valeur par défaut prudente à décider plus tard ;
- warning si hazard runtime non encore branché ;
- preview précise pour éviter des dégâts hors lave.

Statut : modèle existant, runtime à vérifier avant de promettre un effet en jeu.

## 20. Stratégie ice

Workflow recommandé :

```text
Surface ice
→ Glace glissante
→ futur movement/special
```

Décision :

- ne pas présenter la glissade comme supportée maintenant ;
- utiliser éventuellement `SpecialZonePayload(scriptKey: ...)` pour projets avancés ;
- garder un label "préparation seulement" dans l'assistant tant qu'un modèle de glissade n'existe pas.

Statut : futur comportement.

## 21. Stratégie mud/swamp

Workflow recommandé :

```text
Surface swamp
→ Marais dangereux
→ HazardZonePayload(hazardKind: swamp)
```

Pour mud ralentissant :

```text
Surface mud
→ Boue ralentissante
→ futur movement modifier
```

Décision :

- `HazardKind.swamp` peut couvrir marais/danger ;
- ralentissement sans dégâts n'est pas clairement modélisé ;
- ne pas mapper mud slow vers hazard par défaut.

## 22. UX no-code recommandée

Layout conceptuel :

```text
┌─────────────────────────────────────────────────────────────┐
│ Créer un comportement depuis une surface                    │
├───────────────────────┬─────────────────────────────────────┤
│ 1. Surface source      │ Aperçu map                         │
│ 2. Comportement        │ - cellules surface                 │
│ 3. Paramètres          │ - zones générées                   │
│ 4. Prévisualisation    │ - couverture en trop / manquante   │
│ 5. Confirmation        │                                    │
└───────────────────────┴─────────────────────────────────────┘
```

Principes :

- assistant large, pas panneau droit étroit ;
- étapes visibles ;
- cartes métier ;
- preview carte/cellules ;
- diagnostics avant confirmation ;
- sortie vers le panel GameplayZone existant.

Textes utilisateur :

- "Choisissez la surface peinte à utiliser."
- "Choisissez ce que cette surface doit faire en jeu."
- "Vérifiez les cellules couvertes avant de créer la zone."
- "Cette action crée une zone gameplay modifiable. Elle ne synchronise pas automatiquement la surface."

Ne pas faire :

- "EncounterZonePayload" dans l'interface ;
- dropdown technique comme point d'entrée ;
- génération sans preview ;
- lien live implicite.

## 23. Diagnostics UX à prévoir

Blocking :

- aucune map active ;
- aucune SurfaceLayer ;
- surface sans placement ;
- `surfacePresetId` absent du catalogue ;
- `encounterTableId` manquant pour tall grass ;
- `damagePerStep` manquant ou invalide pour lave ;
- génération produit zéro zone ;
- id de zone déjà utilisé et non résolu.

Warning :

- surface irrégulière ;
- trop de rectangles générés ;
- bounding box couvre des cellules hors surface ;
- zones générées chevauchent des zones existantes ;
- hazard modélisé mais runtime non garanti ;
- ice/mud slow pas encore supportés pleinement ;
- surface modifiée depuis une précédente génération.

Info :

- nombre de cellules source ;
- nombre de zones proposées ;
- nombre de cellules couvertes exactement ;
- priorité par défaut ;
- possibilité d'éditer les zones après création.

## 24. Architecture future suggérée

Noms conceptuels, non codés :

- `SurfaceGameplayZoneGenerationPlan`
- `SurfaceGameplayZoneGenerationCandidate`
- `SurfaceGameplayZoneCoverageReport`
- `SurfaceToGameplayZoneGenerationOptions`
- `SurfaceToGameplayZoneGenerator`
- `SurfaceGameplayZoneBehaviorTemplate`

Responsabilités futures :

- lire une Surface source ;
- grouper les cellules par preset/layer ;
- produire un ou plusieurs candidats de zones ;
- calculer coverage ;
- lister diagnostics ;
- préparer payloads `MapGameplayZone` existants ;
- ne pas muter la map avant confirmation.

Point important :

```text
Le Lot 98 décidera les noms réels si on code.
```

## 25. Roadmap post Lot 97

Roadmap recommandée :

| Lot | Sujet |
| --- | --- |
| Lot 98 | Surface to GameplayZone Generation Plan Model V0 |
| Lot 99 | Surface to GameplayZone Coverage / Diagnostics V0 |
| Lot 100 | Editor Generate Gameplay Zone from Surface V0 |
| Lot 101 | Tall Grass from Surface Workflow V0 |
| Lot 102 | Surfable Water from Surface Workflow V0 |
| Lot 103 | Runtime Surface Position Query Helper V0 |
| Lot 104 | GameplayZone surfacePresetId Filter Decision V0 |

Prochain lot recommandé :

```text
Lot 98 — Surface to GameplayZone Generation Plan Model V0
```

Condition : valider cette spec UX avant de coder.

## 26. Tests relancés

Commandes prévues :

```bash
cd packages/map_core && dart test test/map_gameplay_zone_validation_test.dart
cd packages/map_gameplay && dart test test/surf_evaluation_test.dart test/script_system_integration_test.dart
cd packages/map_runtime && flutter test test/surface
```

Analyse Dart ciblée :

```text
Aucune analyse Dart ciblée nécessaire : aucun fichier Dart modifié.
```

## 27. Résultats

`map_core` gameplay zone validation :

```text
00:00 +1: All tests passed!
```

`map_gameplay` surf + script integration ciblé :

```text
00:00 +31: All tests passed!
```

`map_runtime` Surface suite :

```text
00:01 +29: All tests passed!
```

Ligne finale exacte de la relance runtime en reporter expanded :

```text
00:01 +29: All tests passed!
```

## 28. Fichiers créés

- `reports/surface/surface_engine_lot_97_surface_to_gameplay_zone_authoring_workflow_spec.md`

## 29. Fichiers modifiés

Aucun fichier existant modifié.

## 30. Fichiers supprimés

Aucun.

## 31. Git status final

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
?? reports/surface/surface_engine_lot_97_surface_to_gameplay_zone_authoring_workflow_spec.md

DIFF_STAT

TEMP_FILES

DIFF_CHECK
DONE
```

Changements préexistants : aucun.

Changements du Lot 97 : création du rapport Markdown uniquement.

Fichiers temporaires : aucun.

`git diff --check` : aucune erreur.

## 32. Périmètre explicitement non touché

Confirmé :

- `map_core` non modifié ;
- `map_editor` non modifié ;
- `map_runtime` production non modifié ;
- `map_gameplay` non modifié ;
- `map_battle` non modifié ;
- `ProjectManifest` non modifié ;
- `surface.dart` non modifié ;
- `surface_catalog.dart` non modifié ;
- `map_layer.dart` non modifié ;
- `map_gameplay_zone_payloads.dart` non modifié ;
- aucun JSON ;
- aucun generated/build_runner ;
- aucune migration legacy ;
- aucun gameplay surf codé ;
- aucun tall grass encounter codé ;
- aucune collision Surface codée ;
- aucun Surface Studio ;
- aucun Surface Painter ;
- aucun modèle de génération codé.

## 33. ctx stats

Commande demandée :

```bash
ctx stats
```

Note : le binaire shell `ctx` n'est pas garanti dans le `PATH` de cette session, mais les outils MCP Context Mode sont disponibles. Le résumé final ci-dessous vient de `ctx_stats`.

Résumé compact :

```text
506.8K tokens saved
94.2% reduction
2.1 MB without context-mode
121.0 KB with context-mode
1.9 MB kept out of conversation
44 calls
v1.0.100
Update available: v1.0.100 -> v1.0.103
```

Répartition :

```text
ctx_batch_execute  2 calls  1.3 MB saved
ctx_search         3 calls  337.2 KB saved
ctx_execute       10 calls  217.7 KB saved
ctx_index         20 calls   60.6 KB saved
ctx_stats          5 calls   49.1 KB saved
ctx_doctor         3 calls   18.0 KB saved
ctx_upgrade        1 call     8.2 KB saved
```

## 34. Limites restantes

- Cette spec ne choisit pas encore l'algorithme précis de décomposition en rectangles.
- Les seuils "surface trop irrégulière" et "trop de rectangles" restent à fixer.
- Le comportement exact `MovementZonePayload(requiredMode: surf)` vs `allowedModes` doit être confirmé en Lot 98/102.
- Hazards sont cadrés UX, mais leur consommation runtime complète reste à vérifier.
- Ice et mud ralentissant restent futurs.
- Aucun écran n'est implémenté.

## 35. Auto-critique

La spec tranche l'expérience utilisateur sans surcoder. C'est la bonne granularité après le Lot 96.

Le risque principal est de sous-estimer la conversion sparse → rectangles. Si le Lot 98 code trop vite, l'éditeur pourrait générer des zones illisibles. Le prochain lot doit donc commencer par un plan de génération pur et testable, pas par une UI.

## 36. Regard critique sur le prompt

Le prompt est bien cadré : il interdit les nouveaux modèles persistants et force l'UX avant code. C'est exactement le bon ordre.

Point à surveiller : il demande de spécifier lava/ice/mud, alors que le support runtime n'est pas au même niveau que tallGrass/surf. La spec doit donc rester honnête et marquer ces comportements comme partiels/futurs quand nécessaire.

## Evidence Pack

Status initial : section 3.

Commandes d'audit : sections 4 à 8.

Findings importants : sections 5 à 24.

Tests relancés : sections 26 et 27.

Contenu du rapport créé : non recopié récursivement.

## Auto-review obligatoire

- Est-ce que le workflow Surface → GameplayZone est décrit ? Oui.
- Est-ce que l'UX no-code est claire ? Oui.
- Est-ce que la sélection de surface source est spécifiée ? Oui.
- Est-ce que les comportements proposés sont spécifiés ? Oui.
- Est-ce que la génération sparse → rectangles est analysée ? Oui.
- Est-ce que la preview avant confirmation est obligatoire ? Oui.
- Est-ce que tallGrass est cadré ? Oui.
- Est-ce que surfable water est cadré ? Oui.
- Est-ce que lava/ice/mud sont cadrés ? Oui.
- Est-ce qu'aucun code n'a été modifié ? Oui.
- Est-ce que les tests pertinents ont été relancés ? Oui.
- Est-ce que Context Mode a été utilisé agressivement ? Oui.
- Est-ce que ctx stats est inclus ? Oui.
- Est-ce qu'un Lot 97-bis est nécessaire ? Non anticipé. Le prochain lot recommandé est Lot 98 si cette spec est validée.
