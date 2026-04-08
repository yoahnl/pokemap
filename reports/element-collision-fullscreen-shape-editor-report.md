# Rapport — Éditeur de collisions d’éléments plein cadre (pinceau + polygone)

## 1. Résumé exécutif

Ce lot refond l’expérience d’édition des collisions d’éléments dans `map_editor` sans toucher au runtime gameplay.

Le contrat produit reste volontairement simple :

- le runtime continue à lire uniquement `collisionProfile.cells`
- le `padding` reste la base automatique
- l’auteur édite visuellement une forme
- cette forme est convertie en cellules de collision
- aucune logique pixel-perfect ou d’analyse d’image n’est introduite

La refonte se concentre donc sur trois points :

1. une couche d’authoring où l’auteur dessine temporairement une forme
2. une couche applicative propre qui convertit cette forme en cellules runtime
3. une vraie UI dédiée, large, lisible et outillée, au lieu d’un mini bloc compressé dans le formulaire d’élément

## 2. Diagnostic du problème initial

Le système précédent avait deux défauts majeurs.

### 2.1 Le modèle runtime était bon, mais l’authoring trop pauvre

Le projet disposait déjà de bonnes bases :

- un runtime basé sur une liste finale de cellules
- un `padding` capable de générer une base automatique
- une couche d’overrides manuels déjà introduite localement :
  - `manualAddedCells`
  - `manualRemovedCells`

Cette direction était saine, parce qu’elle gardait une seule vérité runtime.

### 2.2 Le backend de conversion restait trop brutal

Le vrai échec métier du premier lot n’était pas la fermeture du polygone ni la seule persistance JSON.

Le problème était plus profond :

- l’auteur dessinait une silhouette plausible
- puis la conversion vers la grille reprenait trop vite la main
- le résultat final redevenait une masse de grosses cellules
- la silhouette perçue du bâtiment était dégradée

Autrement dit, on avait encore un “éditeur de cases avec décoration polygonale”, alors que le besoin produit est l’inverse :

- UX = forme
- backend = conversion
- runtime = cellules

### 2.3 L’UX d’édition restait trop petite et trop “grille brute”

Le vrai point faible était l’expérience d’édition :

- collision éditée dans un bloc compact
- canevas trop petit
- sensation immédiate de manipuler des cases “brutes”
- pas de geste naturel de dessin
- pas de polygone/lasso
- pas de drag continu au pinceau

En pratique, l’utilisateur voyait surtout les limites de la grille, alors que l’objectif produit est de lui faire manipuler une forme visuelle, avec une conversion interne vers des cellules.

## 3. Pourquoi la direction “magique” a été explicitement refusée

Ce lot refuse explicitement :

- pixel-perfect collision
- alpha sampling
- analyse d’image
- occlusion
- masques visuels séparés
- ML / IA / OpenCV / segmentation
- refonte du runtime Flame
- deuxième vérité métier côté gameplay

Pourquoi :

- ce n’est pas nécessaire pour le besoin
- ce serait plus fragile
- ce serait plus difficile à expliquer à l’auteur
- ce serait plus coûteux à maintenir
- cela casserait la clarté du contrat runtime actuel

La solution retenue reste donc volontairement explicite :

`final cells = base padding cells + ajouts manuels - retraits manuels`

## 4. Invariants métier conservés

Les invariants suivants restent vrais après ce lot :

- la vérité runtime reste `ElementCollisionProfile.cells`
- le runtime/gameplay ne connaît pas le pinceau, le polygone, ni les overrides auteur
- le `padding` continue à représenter la base automatique, mais il redevient un mécanisme secondaire d’ajustement
- les retouches auteur restent des corrections locales et déterministes
- un rechargement d’élément reconstruit toujours la même forme finale
- changer le padding recalcule la base, puis réapplique les retouches

## 5. Architecture choisie

## 5.1 Core / modèle

Aucune nouvelle vérité runtime n’a été introduite.

Le modèle utilisé par ce lot reste celui déjà présent localement :

- `padding`
- `cells`
- `manualAddedCells`
- `manualRemovedCells`

Ce lot n’a pas modifié `map_core`.

## 5.2 Application

Trois services sont maintenant utilisés pour couvrir toute la logique auteur :

### `ElementCollisionBaseCellsFromPaddingService`

Responsabilité :

- dériver la base cellulaire depuis `padding`

Fichier :

- [/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/element_collision_base_cells_from_padding_service.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/element_collision_base_cells_from_padding_service.dart)

### `ElementCollisionShapeRasterizerService`

Responsabilité :

- convertir une forme auteur en cellules
- supporter :
  - polygone
  - pinceau drag continu

Fichier :

- [/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/element_collision_shape_rasterizer_service.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/element_collision_shape_rasterizer_service.dart)

### `ElementCollisionAuthoringService`

Responsabilité :

- centraliser l’orchestration complète
- décrire l’état auteur courant
- appliquer une liste de cellules en mode ajout/retrait
- appliquer un stroke de pinceau
- appliquer un polygone
- recalculer depuis le padding
- réinitialiser les retouches
- vider toute collision

Fichier :

- [/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/element_collision_authoring_service.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/element_collision_authoring_service.dart)

## 5.3 UI

La logique d’édition détaillée a été sortie du petit bloc inline pour devenir un véritable éditeur dédié.

Fichiers :

- [/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart)
- [/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart)

## 6. Flux de données

Le flux complet est maintenant le suivant :

1. le formulaire d’élément affiche un résumé de collision
2. l’utilisateur ouvre l’éditeur dédié
3. l’éditeur charge :
   - image source
   - `padding`
   - `manualAddedCells`
   - `manualRemovedCells`
4. l’auteur manipule une forme transitoire côté éditeur :
   - points de pinceau
   - sommets de polygone
5. `ElementCollisionAuthoringService.describe(...)` calcule :
   - `baseCells`
   - `finalCells`
6. `ElementCollisionShapeRasterizerService` convertit ces formes en `GridPos`
7. `ElementCollisionAuthoringService` applique les cellules en mode ajout/retrait
8. le profil sauvegardé contient toujours `cells` comme vérité finale
9. le runtime continue à lire uniquement `cells`

Important :

- la forme auteur est aujourd’hui une vérité **transitoire d’édition**
- elle n’est pas persistée comme vérité runtime
- la persistance reste volontairement alignée sur le contrat du moteur : `collisionProfile.cells`

## 7. Fonctionnement du pinceau

Le pinceau utilise un drag continu :

- au début du drag, un point grille est capturé
- à chaque update, le segment `point précédent -> point courant` est rasterisé
- le rasterizer produit toutes les cellules traversées
- l’orchestrateur applique ces cellules en mode :
  - ajout
  - retrait

Important :

- l’opération est idempotente
- repeindre une cellule ne la “toggle” pas
- le pinceau exprime un état voulu, pas un clic inversant un booléen

Extrait clé :

```dart
ElementCollisionProfile applyBrushStroke({
  required TilesetSourceRect source,
  required int tileWidth,
  required int tileHeight,
  required List<Offset> points,
  required ElementCollisionAuthoringOperation operation,
  ElementCollisionProfile? current,
  WarpTriggerPadding fallbackPadding = const WarpTriggerPadding(),
}) {
  final cells = shapeRasterizerService.rasterizeBrushStroke(
    points: points,
    gridWidth: source.width,
    gridHeight: source.height,
  );
  return applyCells(
    source: source,
    tileWidth: tileWidth,
    tileHeight: tileHeight,
    cells: cells,
    operation: operation,
    current: current,
    fallbackPadding: fallbackPadding,
  );
}
```

## 8. Fonctionnement du polygone / lasso

Le mode polygone reprend désormais une interaction explicitement inspirée de Tiled :

- clic pour poser des points
- l’utilisateur visualise le contour en cours
- le premier point reste visuellement identifiable
- si le curseur revient près du premier point, un feedback de fermeture apparaît
- la fermeture peut se faire de quatre façons :
  - cliquer près du premier point
  - double-clic
  - touche `Enter`
  - bouton `Fermer le polygone`
- une fois fermé, le polygone est immédiatement rasterisé en cellules
- ces cellules sont appliquées en ajout ou en retrait
- `Escape` annule le polygone en cours

### Règle de rasterisation retenue

La logique retenue n’est plus :

- “toute cellule touchée par la forme est prise”

Cette règle était précisément la cause des gros débordements visuels.

La logique livrée est maintenant une règle hybride :

- une cellule est retenue si son **centre** est dans le polygone
- ou si sa **couverture estimée** par le polygone atteint un seuil minimal

La couverture est estimée par supersampling :

- `sampleResolution = 7`
- donc `49` sous-échantillons par cellule
- `minimumCoverage = 0.32`

Ce compromis a été retenu parce qu’il règle les deux extrêmes :

- les cellules juste effleurées par un coin du polygone restent vides
- une silhouette fine ne s’élargit plus en gros bloc 3x3
- les parties étroites mais réellement portées par la forme restent possibles via le test du centre

Extrait clé :

```dart
final center = Offset(cellRect.left + 0.5, cellRect.top + 0.5);
if (_pointInPolygon(center, vertices)) {
  return true;
}

final coverage = _estimateCellCoverage(vertices, cellRect);
return coverage >= polygonPolicy.minimumCoverage;
```

## 9. Stratégie de conversion forme -> cellules

## 9.1 Polygone

Entrée :

- liste de `Offset` en espace grille

Sortie :

- liste triée et unique de `GridPos`

Étapes :

1. clamp des points dans la zone source
2. calcul de la bounding box du polygone
3. balayage uniquement des cellules dans cette boîte
4. test du centre
5. si besoin, estimation de couverture par supersampling
6. sélection si la couverture atteint le seuil
7. tri stable par `y`, puis `x`

## 9.2 Pinceau

Entrée :

- suite de points de drag en espace grille

Sortie :

- liste triée et unique de `GridPos`

Étapes :

1. conversion des points en cellules
2. rasterisation de chaque segment avec un parcours de grille de type Bresenham
3. déduplication
4. tri stable

## 10. Persistance de `cells`

Le point le plus sensible de ce lot est la garantie suivante :

> la forme finale affichée dans l’éditeur est exactement celle qui est persistée dans `collisionProfile.cells`

Pour verrouiller cela, la sauvegarde ne renvoie plus directement `_draftProfile`.

Au moment du clic sur `Sauvegarder`, l’éditeur :

1. reconstruit un snapshot métier via `describe(...)`
2. relit :
   - `padding`
   - `manualAddedCells`
   - `manualRemovedCells`
3. reconstruit un `ElementCollisionProfile` neuf via `rebuild(...)`
4. ce `rebuild(...)` recalcule `cells` depuis :
   - base padding
   - ajouts
   - retraits

Ainsi, `cells` est réaligné sur le snapshot visible au moment exact de la sauvegarde.

Extrait clé :

```dart
ElementCollisionProfile _buildSavedProfile() {
  final snapshot = _describe();
  return _authoringService.rebuild(
    source: widget.source,
    tileWidth: widget.tileWidth,
    tileHeight: widget.tileHeight,
    padding: snapshot.padding,
    manualAddedCells: snapshot.manualAddedCells,
    manualRemovedCells: snapshot.manualRemovedCells,
  );
}
```

## 11. Choix UI

L’éditeur dédié adopte une structure explicite :

### Header

- nom de l’élément
- taille source
- nombre de cellules finales
- annuler / sauvegarder

### Toolbar

- aperçu
- pinceau +
- pinceau -
- polygone +
- polygone -
- fermer/effacer le polygone
- réinitialiser retouches
- restaurer base padding
- vider toute collision

### Zone centrale

- grand canevas
- sprite visible
- grille discrète
- overlays lisibles
- contour du polygone en cours
- premier point du polygone identifiable
- feedback visuel de fermeture
- preview des cellules backend que le polygone fermé produira

### Panneau latéral

- résumé base / ajouts / retraits / final
- édition du padding
- options d’affichage
- aide contextuelle

## 12. Pourquoi le formulaire d’élément a été simplifié

Le formulaire d’élément dans `tileset_palette_panel.dart` n’essaie plus d’éditer toute la collision inline.

Il affiche maintenant :

- un résumé
- les compteurs utiles
- un bouton pour ouvrir l’éditeur dédié
- un bouton pour effacer le profil

Ce choix est important produit :

- le formulaire reste lisible
- la collision devient un workflow spécialisé
- l’auteur n’est plus contraint dans un petit bloc vertical

## 13. Fichiers créés

- [/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/element_collision_shape_rasterizer_service.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/element_collision_shape_rasterizer_service.dart)
- [/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart)
- [/Users/karim/Project/pokemonProject/packages/map_editor/test/element_collision_shape_rasterizer_service_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/element_collision_shape_rasterizer_service_test.dart)
- [/Users/karim/Project/pokemonProject/packages/map_editor/test/project_element_collision_persistence_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/project_element_collision_persistence_test.dart)
- [/Users/karim/Project/pokemonProject/reports/element-collision-fullscreen-shape-editor-report.md](/Users/karim/Project/pokemonProject/reports/element-collision-fullscreen-shape-editor-report.md)

## 14. Fichiers modifiés

### [/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/element_collision_authoring_service.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/element_collision_authoring_service.dart)

Raison :

- ajout des opérations haut niveau :
  - `applyCells`
  - `applyBrushStroke`
  - `applyPolygon`
- orchestration idempotente des retouches

### [/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart)

Raison :

- remplacement du mini éditeur inline par une carte résumé
- ouverture du nouvel éditeur dédié plein cadre

### [/Users/karim/Project/pokemonProject/packages/map_editor/test/element_collision_authoring_service_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/element_collision_authoring_service_test.dart)

Raison :

- ajout de tests sur :
  - `applyCells`
  - `applyPolygon`
  - `applyBrushStroke`

### [/Users/karim/Project/pokemonProject/packages/map_editor/test/project_element_collision_persistence_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/project_element_collision_persistence_test.dart)

Raison :

- ajout de tests de persistance JSON sur :
  - création d’élément
  - mise à jour d’élément
  - conservation de `padding`
  - conservation de `cells`

## 15. Ce que le runtime lit toujours

Le runtime n’a pas été modifié dans ce lot.

Le consommateur gameplay continue à lire la vérité finale seulement.

Références utiles :

- [/Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/gameplay_world_state.dart](/Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/gameplay_world_state.dart)
- [/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart)

Ce lot change donc l’authoring, pas le contrat runtime.

## 16. Cas limites couverts

Les cas suivants sont gérés explicitement :

- padding extrême qui vide la base
- points de pinceau hors bornes
- polygone hors bornes
- doublons de cellules
- ordre stable des cellules
- rechargement après changement de padding
- fermeture de polygone près du premier point
- clear all
- reset overrides
- restore base
- formes concaves simples

## 17. Tests ajoutés / renforcés

### Rasterizer

Fichier :

- [/Users/karim/Project/pokemonProject/packages/map_editor/test/element_collision_shape_rasterizer_service_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/element_collision_shape_rasterizer_service_test.dart)

Cas couverts :

- rectangle simple
- polygone concave
- polygone très ras qui ne doit pas capturer de cellules effleurées
- silhouette étroite qui doit rester plus fine qu’un remplissage “tout contact”
- stroke continu
- clamp + unicité + tri

### Authoring

Fichier :

- [/Users/karim/Project/pokemonProject/packages/map_editor/test/element_collision_authoring_service_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/element_collision_authoring_service_test.dart)

Cas couverts :

- dérivation depuis padding
- overlay base + ajouts - retraits
- recalcul après changement de padding
- reset overrides
- clear all
- application déterministe d’un lot de cellules
- application d’un polygone
- application d’un stroke

### Persistance

Fichier :

- [/Users/karim/Project/pokemonProject/packages/map_editor/test/project_element_collision_persistence_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/project_element_collision_persistence_test.dart)

Cas couverts :

- création d’un élément avec `collisionProfile`
- sérialisation `toJson()`
- relecture `fromJson()`
- conservation de :
  - `padding`
  - `cells`
  - `manualAddedCells`
  - `manualRemovedCells`
- mise à jour d’un élément existant avec roundtrip JSON

### Non-régression gameplay

Fichier exécuté :

- `/Users/karim/Project/pokemonProject/packages/map_gameplay/test/placed_elements_collision_test.dart`

Objectif :

- confirmer que les collisions d’éléments restent consommées de la même façon côté gameplay

## 18. Validations réellement exécutées

### Format

Commandes :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
dart format lib/src/application/services/element_collision_authoring_service.dart
dart format lib/src/application/services/element_collision_shape_rasterizer_service.dart
dart format lib/src/ui/panels/element_collision_editor_sheet.dart
dart format lib/src/ui/panels/tileset_palette_panel.dart
dart format test/element_collision_authoring_service_test.dart
dart format test/element_collision_shape_rasterizer_service_test.dart
```

### Tests map_editor

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test test/element_collision_shape_rasterizer_service_test.dart test/element_collision_authoring_service_test.dart test/project_element_collision_persistence_test.dart
```

Résultat :

- OK, tous les tests passent

### Analyze ciblé map_editor

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter analyze \
  lib/src/application/services/element_collision_authoring_service.dart \
  lib/src/application/services/element_collision_shape_rasterizer_service.dart \
  lib/src/ui/panels/element_collision_editor_sheet.dart \
  lib/src/ui/panels/tileset_palette_panel.dart \
  test/element_collision_authoring_service_test.dart \
  test/element_collision_shape_rasterizer_service_test.dart \
  test/project_element_collision_persistence_test.dart \
  --no-fatal-infos
```

Résultat :

- exit code `0`
- quelques infos historiques subsistent dans `tileset_palette_panel.dart`
  - `prefer_const_*`
  - `minSize` déprécié
- ces infos ne sont pas introduites par ce lot

### Test gameplay ciblé

```bash
cd /Users/karim/Project/pokemonProject/packages/map_gameplay
dart test test/placed_elements_collision_test.dart
```

Résultat :

- OK, tous les tests passent

## 19. Ce qui a été explicitement refusé

Ce lot refuse explicitement :

- collision pixel-perfect
- analyse alpha
- heuristique d’image
- occlusion visuelle
- profondeur runtime
- refonte Flame
- deuxième système de collision runtime
- dépendance lourde supplémentaire

## 20. Limites connues

Les limites restantes sont assumées :

- le canevas reste basé sur une grille discrète, même si l’UX la masque mieux
- il n’y a pas encore d’historique undo/redo local spécifique à cet éditeur
- les anciens widgets inline sont encore présents dans `tileset_palette_panel.dart` pour limiter le risque de refonte trop large, même s’ils ne sont plus utilisés par le flux principal
- il n’y a pas encore de test widget automatisé pilotant la sheet au clic près ; la chaîne de persistance est verrouillée par les tests de use case + roundtrip JSON

## 21. Ce que je n’ai volontairement pas changé

- aucun contrat runtime
- aucune consommation gameplay
- aucune logique Flame
- aucune dépendance
- aucune tentative d’analyse automatique du sprite
- aucune migration de modèle supplémentaire

## 22. Checklist de validation manuelle

À vérifier dans l’éditeur :

1. créer un élément depuis un tileset
2. ouvrir “Ouvrir l’éditeur de collision”
3. peindre au pinceau en ajout
4. peindre au pinceau en retrait
5. tracer un polygone, le fermer en cliquant le premier point, puis vérifier l’ajout
6. tracer un polygone, le fermer avec `Enter` ou double-clic, puis vérifier le retrait
7. modifier le padding et vérifier que les retouches restent cohérentes
8. utiliser “Réinitialiser retouches”
9. utiliser “Restaurer base padding”
10. utiliser “Vider toute collision”
11. sauvegarder, fermer, réouvrir l’élément
12. vérifier que la collision affichée est identique
13. placer l’élément sur une map et confirmer que le runtime bloque selon `cells`

## 23. Checklist de fin demandée

- [x] le polygone est un vrai polygone fermé
- [x] le pinceau add fonctionne en drag
- [x] le pinceau remove fonctionne en drag
- [x] le padding produit une base visible
- [x] les retouches s’appliquent sur cette base
- [x] la forme finale affichée est reconstruite dans `collisionProfile.cells` au save
- [x] après sauvegarde logique, le JSON conserve bien les cellules finales
- [x] après rechargement logique, la forme est identique
- [x] le runtime bloque effectivement selon cette forme
- [x] aucun système parasite ne remplace `cells`

Note honnête :

- la vérification “UI complète ouverte puis projet réécrit sur disque puis rechargé via interaction widget” n’a pas été automatisée en test widget ; elle est couverte par les tests de persistance JSON, la reconstruction au save, et le test gameplay ciblé.

## 24. Conclusion

Le lot apporte exactement ce qui manquait :

- plus de contrôle auteur
- une UX bien plus lisible
- un vrai geste de dessin
- aucun impact runtime inutile

La solution reste simple, déterministe, maintenable, et fidèle à la direction voulue :

- authoring visuel
- stockage en cellules
- runtime inchangé
