# NS-SCENES-V1-103 — Cinematic Actor Initial Placement from Stage Points V0

Statut : **DONE**

## Description

Ce lot permet d'utiliser un `CinematicStagePoint` existant comme position initiale d'un acteur cinématique. Au lieu de dupliquer les coordonnées géométriques (lignes/colonnes) de l'acteur, celui-ci référence l'identifiant du point de scène (`stagePointId`), tout en conservant une rétrocompatibilité JSON descendante complète.

À la suite des retours utilisateurs, un bouton de fermeture a également été ajouté dans l'inspecteur de Stage Point sélectionné pour revenir à l'inspecteur global.

## Scope Réalisé

1. **Modèles Core et Sérialisation (`packages/map_core`) :**
   - Extension de `CinematicActorInitialPlacementKind` avec le cas `stagePoint`.
   - Ajout du champ `stagePointId` à `CinematicActorInitialPlacement` avec validation du format non vide lors de l'authoring.
   - Préservation de la compatibilité JSON : les anciens JSON sans placement de type `stagePoint` sont décodés correctement sans perte de données.
   - Durcissement d'authoring dans `cinematic_authoring_operations.dart` : correction d'un bug critique où les stage points n'étaient pas propagés lors de l'édition d'autres propriétés de l'acteur (bindings, placements, target bindings, etc.).

2. **Diagnostics Statiques et Dynamiques (`packages/map_core` et `packages/map_editor`) :**
   - Implémentation des diagnostics statiques et validation de cohérence :
     - `actorInitialPlacementStagePointMissing` (Erreur) : Si le point référencé est inexistant ou a été supprimé.
     - `actorInitialPlacementStagePointWithoutStageMap` (Avertissement) : Si un point est choisi mais qu'aucune map d'arrière-plan n'est associée.
     - `actorInitialPlacementStagePointOutOfMap` (Erreur) : Si le point référencé est hors des dimensions physiques de la carte.
   - Intégration dans le read model de readiness `CinematicStagePreviewReadiness` avec des messages clairs et des icônes d'erreur associées.

3. **Read Model de Rendu (`CinematicActorDisplayPreviewModel`) :**
   - Résolution géométrique : Si le placement initial pointe vers un point de scène, ses coordonnées sont résolues dynamiquement à partir de `CinematicStagePoint` (avec arrondi correct).
   - Rendu en preview : L'acteur est dessiné au bon emplacement et se met à jour instantanément si le point de scène est déplacé par drag-and-drop.
   - Si le point de scène référencé est inexistant, le moteur ne produit aucune coordonnée fictive et lève une erreur de diagnostic claire.

4. **Interface d'Inspecteur Latérale (`packages/map_editor`) :**
   - Ajout d'une option par bouton radio `"Point de scène"` dans la section de placement initial de l'inspecteur latéral.
   - Si cette option est active, affiche un bouton de sous-sélection montrant le nom du point en cours.
   - Cliquer sur la sous-sélection ouvre une pop-up d'Overlay (`_StagePointDropdownPopup`) listant les points de scène existants avec leurs coordonnées réelles. Cliquer sur un point met à jour l'acteur immuablement en mémoire.
   - **Bouton de fermeture (Désélection)** : Ajout d'une icône de fermeture (`CupertinoIcons.xmark_circle`) dans l'inspecteur de Stage Point sélectionné pour réinitialiser la sélection et retourner à l'inspecteur global de la scène cinématique.

## Preuves et Validation

### Tests Automatisés
- **Tests Core (`map_core`) :** Ajout de tests unitaires couvrant le décodage/encodage JSON de placements par Stage Points, la résolution correcte de position via `CinematicActorDisplayPreviewModel`, et les différents cas de diagnostics (valide, manquant, hors map, sans map).
- **Tests Widget (`map_editor`) :** Ajout de tests de widget dans `cinematic_builder_workspace_test.dart` simulant l'interaction de sélection de Stage Point dans la sidebar, la validation que le dropdown affiche les bons labels, et la mise à jour correspondante.

### Rendu Visual Gate
La Visual Gate de non-régression visuelle a été générée avec succès via test golden file sous :
`reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_103_cinematic_actor_initial_placement_from_stage_points_v0.png`

Elle affiche le sprite réel du professeur Timi positionné sur le Point de Scène sélectionné, ainsi que l'inspecteur latéral configuré sur l'option "Point de scène" avec le bouton sous-sélecteur actif.

## Limites
- Pas de playback interactif ou d'interpolation de mouvement lors des timelines d'instructions `actorMove` (non-goal, prévu pour le lot V1-104).
- Aucune interaction avec le moteur runtime Flame de gameplay réel.

## Prochain lot recommandé
`NS-SCENES-V1-104 — Cinematic ActorMove Target from Stage Points V0` : Permettre d'utiliser également les points de scène comme cibles de mouvement (`actorMove`) dans les timelines cinématiques.
