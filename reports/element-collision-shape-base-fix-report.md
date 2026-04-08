# Rapport — Correction métier du bug “base padding pleine + lasso décoratif”

## 1. Résumé exécutif

Le vrai bug n’était ni la fermeture du polygone, ni la seule persistance JSON, ni le painter.

Le bug réel était dans le **modèle de reconstruction** de `ElementCollisionProfile` :

- la couche d’authoring repartait toujours d’une base calculée depuis le `padding`
- avec `padding = 0`, cette base était toute la grille source
- le lasso/polygone était ensuite traité comme un simple ajout
- la collision runtime restait donc pleine, même quand l’auteur avait dessiné une forme fine

La correction retenue est une correction **métier** et non cosmétique :

- on distingue maintenant explicitement deux bases possibles
  - base générée depuis le padding
  - base dessinée par l’auteur
- on persiste cette base auteur dans `shapeCells`
- `collisionProfile.cells` reste l’unique vérité runtime
- le runtime n’a pas été modifié

## 2. Diagnostic précis du bug réel

### 2.1 Constat observé dans le projet utilisateur

Dans `/Users/karim/Desktop/my_new_project/project.json`, l’élément `petite_maison_toit_bleu` contenait :

- `padding = { top: 0, right: 0, bottom: 0, left: 0 }`
- `cells` = toute la grille `6 x 7`, soit `42` cellules
- `manualAddedCells` = seulement la forme du bâtiment
- `manualRemovedCells = []`

Extrait observé :

```json
"collisionProfile": {
  "source": "manual",
  "padding": { "top": 0, "right": 0, "bottom": 0, "left": 0 },
  "cells": [ /* 42 cellules = toute la grille 6x7 */ ],
  "manualAddedCells": [ /* 14 cellules = forme maison */ ],
  "manualRemovedCells": []
}
```

### 2.2 Pourquoi cela rendait toute la maison collidable

Le flux réel était :

1. `describe()` reconstruisait la base via `ElementCollisionBaseCellsFromPaddingService`
2. avec `padding = 0`, cette base valait **toute la source**
3. `manualAddedCells` était appliqué **par-dessus**
4. comme la base contenait déjà toute la grille, ajouter la forme ne changeait rien
5. `cells` finale restait pleine
6. le runtime lisait `collisionProfile.cells`
7. donc toute la maison bloquait

La racine du bug était donc bien :

> le lasso n’était pas traité comme la base logique de collision, mais comme un simple ajout au-dessus d’une base padding déjà pleine

## 3. Endroit exact où ça cassait

Le problème était dans :

- [/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/element_collision_authoring_service.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/element_collision_authoring_service.dart)

Avant correction, `describe()` et `rebuild()` repartaient systématiquement de :

```dart
final baseCells = baseCellsFromPaddingService.derive(...)
final finalCells = cellsOverlayService.apply(
  baseCells: baseCells,
  manualAddedCells: manualAdded,
  manualRemovedCells: manualRemoved,
)
```

Donc, avec `padding = 0` :

- `baseCells == toute la grille`
- un polygone “ajout” ne pouvait jamais devenir la vraie base de collision

## 4. Solution d’architecture retenue

### 4.1 Option choisie

J’ai retenu l’équivalent de l’**Option 1** demandée :

- distinction claire entre collision générée par padding et collision définie principalement par forme

Sans introduire un nouveau runtime ni une seconde vérité gameplay, la solution prend cette forme :

- `source == generated`
  - base = padding
- `source == manual`
  - base = `shapeCells`

Le runtime continue à lire uniquement :

- `collisionProfile.cells`

### 4.2 Pourquoi ce choix est le bon

Cette option est plus propre que de remplir automatiquement `manualRemovedCells` contre une base padding pleine, parce que :

- elle correspond au vrai modèle mental auteur
- elle évite un hack implicite difficile à maintenir
- elle permet de distinguer clairement les deux cas produit :
  - “je pars du padding”
  - “je définis la forme principale”
- elle rend le JSON lisible et honnête

## 5. Nouveau modèle métier

Fichier :

- [/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/element_collision_profile.dart](/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/element_collision_profile.dart)

Champ ajouté :

```dart
@Default([]) List<GridPos> shapeCells,
```

Rôle :

- `shapeCells` stocke la **base auteur** quand la collision est principalement définie par une forme
- `cells` reste la **vérité runtime finale**

Le profil a donc maintenant ces rôles :

- `padding`
  - base auto potentielle
- `shapeCells`
  - base auteur potentielle
- `manualAddedCells`
  - retouches ajout
- `manualRemovedCells`
  - retouches retrait
- `cells`
  - vérité runtime finale

## 6. Nouvelle logique de reconstruction

### 6.1 Cas A — source générée

Si `source == generated` :

```text
baseCells = baseCellsFromPaddingService.derive(...)
finalCells = (baseCells + manualAddedCells) - manualRemovedCells
```

### 6.2 Cas B — source auteur / forme principale

Si `source == manual` :

```text
baseCells = shapeCells
finalCells = (shapeCells + manualAddedCells) - manualRemovedCells
```

### 6.3 Conséquence produit

Quand l’auteur dessine un polygone principal sur un bâtiment :

- ce polygone devient la base métier
- il n’est plus ajouté sur un rectangle plein
- `cells` finale correspond réellement à la forme dessinée, convertie en cellules

## 7. Nouveau comportement du polygone

Le polygone `+` n’est plus traité comme un simple “ajout de cellules” sur la base padding.

Il sert maintenant à :

- définir/remplacer la **forme principale** de collision

Concrètement :

- `polygonAdd` rasterize la forme
- puis appelle `setPrimaryShape(...)`
- ce qui reconstruit un profil `source: manual`
- avec :
  - `shapeCells = cellules du polygone`
  - `manualAddedCells = []`
  - `manualRemovedCells = []`
  - `cells = shapeCells`

Le pinceau reste, lui, un outil de retouche locale :

- pinceau `+` = ajout
- pinceau `-` = retrait

## 8. Migration douce des profils déjà cassés

Le correctif ne se contente pas de corriger les nouveaux profils.

Il contient aussi une logique de migration douce dans `describe()` pour les profils déjà enregistrés avec l’ancien bug.

Cas migré explicitement :

- `source == manual`
- `shapeCells` vide
- `manualAddedCells` non vide
- `manualRemovedCells` vide
- `cells == base padding pleine`

Dans ce cas, on réinterprète le profil comme :

- `shapeCells = manualAddedCells`
- `manualAddedCells = []`
- `manualRemovedCells = []`

Autrement dit :

- on considère que l’intention réelle de l’auteur était bien la forme du lasso
- pas le rectangle plein

Cette migration est volontairement ciblée pour ne pas casser les anciens profils réellement fondés sur :

- base padding + overrides classiques

## 9. Exemple concret avant / après

### 9.1 Avant correction

Cas `petite_maison_toit_bleu` observé :

```json
{
  "source": "manual",
  "padding": { "top": 0, "right": 0, "bottom": 0, "left": 0 },
  "cells": [ /* 42 cellules = toute la grille 6x7 */ ],
  "manualAddedCells": [ /* 14 cellules = forme de la maison */ ],
  "manualRemovedCells": []
}
```

Effet runtime :

- collision pleine

### 9.2 Après correction logique

Le profil cible reconstruit/sauvé est maintenant de cette nature :

```json
{
  "source": "manual",
  "padding": { "top": 0, "right": 0, "bottom": 0, "left": 0 },
  "shapeCells": [ /* 14 cellules = forme auteur */ ],
  "cells": [ /* 14 cellules = forme runtime finale */ ],
  "manualAddedCells": [],
  "manualRemovedCells": []
}
```

Effet runtime :

- seule la forme réellement dessinée reste collidable

## 10. Fichiers créés

- [/Users/karim/Project/pokemonProject/reports/element-collision-shape-base-fix-report.md](/Users/karim/Project/pokemonProject/reports/element-collision-shape-base-fix-report.md)

## 11. Fichiers modifiés

### Core

- [/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/element_collision_profile.dart](/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/element_collision_profile.dart)
  - ajout de `shapeCells`
- [/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/element_collision_profile.freezed.dart](/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/element_collision_profile.freezed.dart)
  - régénéré
- [/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/element_collision_profile.g.dart](/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/element_collision_profile.g.dart)
  - régénéré
- [/Users/karim/Project/pokemonProject/packages/map_core/lib/src/validation/validators.dart](/Users/karim/Project/pokemonProject/packages/map_core/lib/src/validation/validators.dart)
  - validation de `shapeCells`
- [/Users/karim/Project/pokemonProject/packages/map_core/test/element_collision_profile_model_test.dart](/Users/karim/Project/pokemonProject/packages/map_core/test/element_collision_profile_model_test.dart)
  - tests de roundtrip modèle

### Editor / application

- [/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/element_collision_authoring_service.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/element_collision_authoring_service.dart)
  - résolution de base générée vs base auteur
  - migration douce des profils cassés
  - `setPrimaryShape(...)`
  - `applyPolygon(...)` qui remplace maintenant la base principale
- [/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart)
  - le save passe désormais `sourceMode` et `shapeCells`
  - l’aide et les labels reflètent la vraie logique métier
- [/Users/karim/Project/pokemonProject/packages/map_editor/test/element_collision_authoring_service_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/element_collision_authoring_service_test.dart)
  - tests métier sur le bug réel
- [/Users/karim/Project/pokemonProject/packages/map_editor/test/project_element_collision_persistence_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/project_element_collision_persistence_test.dart)
  - tests de roundtrip avec `shapeCells`

## 12. Invariants métier conservés

- le runtime lit toujours uniquement `collisionProfile.cells`
- aucune logique pixel-perfect n’a été introduite
- aucune analyse d’image n’a été introduite
- aucune logique Flame/gameplay n’a été modifiée
- `padding` reste supporté
- le système garde un comportement déterministe

## 13. Tests ajoutés / renforcés

### Modèle

- roundtrip JSON avec `shapeCells`
- compatibilité payload legacy sans `shapeCells`

### Authoring service

- rebuild en mode généré
- rebuild en mode forme auteur
- migration d’un ancien profil cassé
- reproduction du cas réel `6x7` de maison qui ne doit plus redevenir pleine
- différence de comportement entre padding-base et shape-base

### Persistance

- create use case avec `shapeCells`
- update use case avec `shapeCells`
- roundtrip JSON d’un profil forme auteur qui ne retombe pas sur la base padding pleine

### Runtime safety

- `packages/map_gameplay/test/placed_elements_collision_test.dart`
- confirme que le runtime continue à bloquer à partir de `collisionProfile.cells`

## 14. Commandes réellement exécutées

### map_core

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core
dart run build_runner build --delete-conflicting-outputs
dart format lib/src/models/element_collision_profile.dart lib/src/validation/validators.dart test/element_collision_profile_model_test.dart
dart test test/element_collision_profile_model_test.dart
dart analyze lib/src/models/element_collision_profile.dart lib/src/models/element_collision_profile.freezed.dart lib/src/models/element_collision_profile.g.dart lib/src/validation/validators.dart test/element_collision_profile_model_test.dart
```

Résultat :

- OK

### map_editor

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
dart format lib/src/application/services/element_collision_authoring_service.dart lib/src/ui/panels/element_collision_editor_sheet.dart test/element_collision_authoring_service_test.dart test/project_element_collision_persistence_test.dart
flutter test test/element_collision_authoring_service_test.dart test/element_collision_shape_rasterizer_service_test.dart test/project_element_collision_persistence_test.dart
flutter analyze lib/src/application/services/element_collision_authoring_service.dart lib/src/application/services/element_collision_shape_rasterizer_service.dart lib/src/ui/panels/element_collision_editor_sheet.dart lib/src/ui/panels/tileset_palette_panel.dart test/element_collision_authoring_service_test.dart test/element_collision_shape_rasterizer_service_test.dart test/project_element_collision_persistence_test.dart --no-fatal-infos
```

Résultat :

- tests OK
- analyze exit code `0`
- il reste des infos historiques dans `tileset_palette_panel.dart` et quelques suggestions `const`

### map_gameplay

```bash
cd /Users/karim/Project/pokemonProject/packages/map_gameplay
dart test test/placed_elements_collision_test.dart
```

Résultat :

- OK

## 15. Ce que j’ai explicitement refusé de faire

- pixel-perfect runtime
- occlusion
- alpha sampling
- analyse d’image
- IA / ML / segmentation
- changement du contrat gameplay
- refonte Flame
- seconde vérité collision côté runtime

## 16. Limites restantes

- `shapeCells` stocke aujourd’hui une base discrète en cellules, pas le polygone géométrique original
- on a donc une vraie base auteur propre côté runtime/editor, mais pas encore un historique vectoriel complet du lasso
- le pinceau reste une retouche sur la base existante, pas une édition vectorielle
- l’éditeur ne propose pas encore explicitement un switch visuel “padding base” / “forme principale” : le comportement vient aujourd’hui de l’outil utilisé, avec `polygonAdd` qui remplace la base

## 17. Pourquoi le runtime n’a pas besoin d’être modifié

Le runtime ne connaît ni :

- `shapeCells`
- `manualAddedCells`
- `manualRemovedCells`
- le lasso
- le pinceau

Il lit seulement :

```dart
for (final localCell in profile.cells) {
  ...
}
```

Donc le bon endroit pour corriger le bug était bien :

- le modèle
- le service d’authoring
- la reconstruction au save

et non le runtime.

## 18. Checklist manuelle recommandée

1. ouvrir `petite_maison_toit_bleu` dans l’éditeur
2. tracer un polygone principal autour de la base de la maison
3. sauvegarder
4. ouvrir `project.json`
5. vérifier que :
   - `shapeCells` correspond à la forme
   - `cells` correspond à la forme
   - `cells` ne contient plus les `42` cellules de la grille complète
6. recharger le projet
7. vérifier que la collision affichée reste identique
8. placer la maison sur une map
9. vérifier que le runtime ne bloque plus le toit entier

## 19. Conclusion

Le problème a été corrigé à la bonne profondeur :

- on n’a pas juste amélioré la preview
- on n’a pas juste embelli l’UI
- on a corrigé la **source métier** de la collision finale

La collision principale d’un bâtiment peut maintenant venir d’une vraie forme auteur, sans être écrasée par une base padding pleine au moment du rebuild.
