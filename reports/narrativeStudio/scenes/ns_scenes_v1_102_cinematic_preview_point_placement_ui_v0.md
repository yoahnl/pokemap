# NS-SCENES-V1-102 — Cinematic Preview Point Placement UI V0

Statut : **DONE**

## Description

Ce lot implémente l'interface utilisateur pour visualiser, créer, sélectionner, déplacer par drag-and-drop, renommer et supprimer des Stage Points cinématiques directement au sein du panneau de preview et de la barre d'outils/inspecteur du Cinematic Builder.

Toutes ces interactions s'effectuent sans effets de bord extérieurs (aucune modification directe dans `MapData` ni création de `mapEntity`/`mapEvent` physiques au runtime).

## Scope Réalisé

1. **Intégration d'outils et de modes dans le Workspace (`packages/map_editor`) :**
   - Ajout du mode d'édition `"Points de scène"` à la barre d'outils du Cinematic Builder.
   - Contrôle d'état : le mode Outil n'est activé que si un arrière-plan cartographique valide (`mapId` résolu) est présent et disponible.

2. **Overlay interactif sur le Canvas (`CinematicStagePointPreviewOverlay`) :**
   - **Rendu visuel :** Représentation de chaque point par une épingle positionnée géométriquement sur le canvas (via conversion des coordonnées logiques de tuiles en coordonnées physiques de preview). Le style utilise les jetons de thème du PokeMap design system (`context.pokeMapColors`).
   - **Création au clic :** Le tap sur une case vide du canvas en mode "Points de scène" ajoute un nouveau point avec un identifiant unique auto-incrémenté (`point_1`, `point_2`, etc.) et le nomme automatiquement (ex. `"Point 1"`).
   - **Snapping et limites :** Toutes les positions sont contraintes aux limites physiques de la carte et snappées précisément au centre de la tuile (`floor(x) + 0.5`, `floor(y) + 0.5`).
   - **Drag-and-Drop sans Touch Slop :** Le drag calcule la position globale de point de départ dès l'interaction touch-down pour éliminer les retards de défilement (touch slop) natifs de Flutter. La position en cours de drag est fluide et réactive, et n'est validée qu'à la fin de l'interaction (end-of-drag) sous forme de commit de modification immuable dans le `ProjectManifest` en mémoire.

3. **Inspecteur Inspecteur de point dans la barre latérale droite :**
   - Affichage d'une carte d'édition dédiée lorsqu'un Stage Point est sélectionné.
   - Permet de modifier son label via un champ texte interactif et de supprimer le point via une action de zone de danger.

4. **Résolution du Hit-Testing et des alignements de coordonnées :**
   - Un composant foreground de peinture (`CustomPaint` sans `IgnorePointer`) bloquait auparavant les taps sur le canvas. L'ajout de `IgnorePointer` a rétabli l'interactivité.
   - Les décalages de coordonnées logiques liés au pan, zoom et cadrage responsive de la map ont été éliminés en passant la taille locale du conteneur de preview comme fill transform.

## Preuves et Validation

### Tests Automatisés et Non-Régression
La suite de tests unitaires et d'intégration passe à 100% au vert :
- `cinematic_builder_workspace_test.dart` valide le workflow complet d'édition interactive (sélection, création au tap, drag positionnel, renommage, suppression).
- Les tests de non-régression s'exécutent avec succès sur l'ensemble de `packages/map_editor` et `packages/map_core`.

### Rendu Visual Gate
La Visual Gate a été générée via test de golden file et est enregistrée à l'emplacement suivant :
`reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_102_cinematic_preview_point_placement_ui_v0.png`

Elle démontre l'overlay des points de scène avec le pin sélectionné et l'inspecteur d'édition actif dans la barre latérale.

### Commandes exécutées
```bash
cd packages/map_editor
flutter test test/cinematic_builder_workspace_test.dart
flutter analyze
```

Résultats :
- **Tests :** 196 tests de workspace passent proprement.
- **Analyse :** 0 erreur.

## Limites

- Ce lot ne gère pas le rattachement d'un acteur ou d'une cible `actorMove` aux points de scène.
- Aucune modification n'a été apportée au runtime gameplay de Flame ou à la persistance générale.

## Prochain lot recommandé

`NS-SCENES-V1-103 — Cinematic Actor Initial Placement from Stage Points V0` : Permettre d'utiliser ces points de scène comme références de positionnement initial pour les acteurs dans la timeline cinématique.
