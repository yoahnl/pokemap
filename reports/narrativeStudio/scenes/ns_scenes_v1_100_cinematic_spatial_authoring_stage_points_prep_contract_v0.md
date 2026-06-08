# NS-SCENES-V1-100 — Cinematic Spatial Authoring / Stage Points Prep Contract V0

> [!IMPORTANT]
> **Phrase canonique obligatoire :**
> V1-100 prépare l’édition spatiale cinématique directement dans la preview.
> V1-100 ne lance toujours pas la cinématique.

## 1. Résumé exécutif

Ce lot est un document de cadrage d'architecture et de design produit, préparant l'édition spatiale des cinématiques directement dans la preview du Cinematic Builder de PokeMap. 
Afin d'éviter l'écueil d'un système de playback qui s'exécuterait sur des acteurs mal positionnés ou configurés indirectement via des menus textuels fastidieux, nous introduisons le concept de **Stage Point** (repère spatial local propre à la cinématique).
Ce contrat définit de manière exhaustive :
- Le modèle de stockage logique des Stage Points, découplé de la map de fond (`MapData`).
- La transformation mathématique bidirectionnelle permettant de convertir un clic de souris sur l'écran en coordonnées cartographiques précises.
- Les modèles UX/UI pour le placement, le déplacement à la souris (drag) et la gestion de ces points.
- L'intégration de ces repères avec les structures existantes d'acteurs (`initialPlacements`) et de cibles (`movementTargetBindings`).
- Le cadre préparatoire des futurs chemins complexes (waypoints / manual paths).
- Les diagnostics statiques et la stratégie de tests unitaires et widget pour les lots suivants (V1-101 à V1-108).

Ce lot est strictement documentaire. Aucun fichier sous `packages/` n'a été modifié, aucun test n'a été exécuté, aucune modification de map ou de base de données n'a été effectuée.

## 2. Gate 0

Voici la trace exacte des commandes de lecture Git exécutées à la racine du projet avant toute modification :

```text
/Users/karim/Project/pokemonProject
main
d0c4d3f2 feat(narrativeStudio): resolve NS-SCENES-V1-99-bis visual polish and fidelity
2ecd9f5f fix(cinematic): fix centering and coordinate mappings for actor sprite preview renderer, resolve rival south/north animation inversion
c920f5ef feat(map_editor): add cinematic actor sprite preview, refine UI, and update project files
343bb31a doc(cinematics): document cinematic actor display preview sprite resolver contract (V1-97)
de216dc0 feat(cinematics): implement cinematic backdrop real map editor ordering fix (V1-96-bis)
89f172b7 feat(cinematics): implement cinematic backdrop depth / Z-order parity polish V0
0d95818f update selbrume
0ccc4c33 update selbrume
b3477664 feat(map_editor): refine cinematic backdrop preview and update scene reports
e093213f update selbrume
5b6822e7 feat(map_editor): refactor UI, add cinematic backdrop preview, and update tests
adc0b197 update selbrume
35415a41 feat(map_editor): smooth left sidebar transitions & refactored narrative studio quick actions
0f1cce5c Merge branch 'feature/stabilize-sidebar'
cf774aef ui: stabilize World Explorer sidebar width and card ordering in Narrative Studio
```

Le working tree était entièrement propre et sans modifications en cours.

## 3. Fichiers lus

Les fichiers de référence du dépôt ont été audités pour assurer la cohérence avec les implémentations existantes :

1. [AGENTS.md](file:///Users/karim/Project/pokemonProject/AGENTS.md) : Règles d'hygiène, non-objectifs et boundaries de packages.
2. [cinematic_asset.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/cinematic_asset.dart) : Modèle core contenant `CinematicAsset`, `CinematicStageContext`, `CinematicActorInitialPlacement` et `CinematicMovementTargetBinding`.
3. [cinematic_actor_display_preview_model.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart) : Logique de projection des acteurs de preview et résolution des coordonnées.
4. [cinematic_map_backdrop_viewport_transform.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart) : Modèle géométrique et transformations viewport <-> coordonnées de map.
5. [cinematic_actor_display_preview_overlay.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart) : Couche d'affichage Flutter (CustomPaint et widgets de fallback).
6. [cinematic_map_backdrop_preview_panel.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart) : Conteneur principal de la preview avec gestion du pan, zoom et grille.
7. [road_map_scenes.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/road_map_scenes.md) & [road_map_scene_builder_authoring.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md) : Suivi global de la roadmap Scenes.

## 4. Synthèse des sub-agents et arbitrages

- **Sub-agent A (Stage Context Audit) :** A validé que l'insertion des Stage Points s'intègre harmonieusement dans `CinematicStageContext` via une nouvelle liste ordonnée `stagePoints`. L'abstraction `abstractPoint` actuelle sera conservée en legacy/fallback pour les cinématiques n'ayant pas encore configuré de coordonnées physiques.
- **Sub-agent B (Viewport Click Mapping) :** A formalisé l'inversion géométrique du transform. Le clic en coordonnées logiques d'écran (via `GestureDetector` locale) sera transformé en coordonnées cartésiennes de tuiles (`double`) en gérant le pan, le zoom et le cadre de rendu (crop).
- **Sub-agent C (Product UX / Interaction Model) :** A comparé les options d'interaction et a retenu l'**Option C (Mode outil dédié dans la preview)**. Elle offre le workflow le plus propre et prépare le dessin des futurs chemins complexes.
- **Sub-agent D (Data Model Options) :** A rejeté le stockage dans `MapData` (pollution de la map commune) ou la création de fausses entités de map temporaires. L'**Option A (stageContext.points)** est retenue sous le nom de modèle `CinematicStagePoint`.
- **Sub-agent E (Initial Placement / Movement Integration) :** A défini les nouvelles extensions de kinds pour `CinematicActorInitialPlacementKind.fromStagePoint` et `CinematicMovementTargetBindingKind.stagePoint`.
- **Sub-agent F (Manual Path Future Contract) :** A cadré le futur modèle de chemin de manière prudente : pas de pathfinding dynamique ni de collisions au runtime pour les cinématiques, le chemin manuel n'étant qu'une liste ordonnée d'identifiants de `CinematicStagePoint`.
- **Sub-agent G (Diagnostics / Validation) :** A défini 14 diagnostics statiques essentiels pour garantir la robustesse avant toute phase d'exécution.
- **Sub-agent H (Tests & Visual Gate Strategy) :** A planifié la validation technique des lots V1-101 à V1-107 avec des tests unitaires et widget-tests ciblés.
- **Sub-agent I (Product Reviewer) :** A confirmé la pertinence ergonomique de poser d'abord les "marques au sol" directement à l'écran plutôt que de manipuler des listes d'IDs bruts.

## 5. Pourquoi V1-100 remplace temporairement le Playback Prep

La roadmap prévoyait initialement `NS-SCENES-V1-100 — Cinematic Preview Playback Prep Contract` comme suite logique directe après le polissage visuel des sprites d'acteurs (V1-99-bis).
Toutefois, démarrer le playback interactif à ce stade poserait un problème produit majeur : l'utilisateur ne dispose d'aucun moyen simple pour placer les acteurs sur la scène ou spécifier des cibles de déplacement sur le décor réel. Les acteurs se retrouveraient tous empilés au point (0, 0) ou dépendraient de pickers indirects d'entités de map (qui nécessitent d'ouvrir le Map Editor pour créer des objets factices).
En intercalant ce lot d'édition spatiale (`NS-SCENES-V1-100 — Cinematic Spatial Authoring`), nous donnons la priorité aux interactions d'auteur : poser les marques physiques de mise en scène à l'écran. Une fois ces points spatialisés, le playback pourra s'appuyer sur des données de placement robustes et éditées visuellement.

## 6. Problème produit actuel

Dans la version actuelle du Cinematic Builder :
- Un auteur peut choisir une map de fond (`mapId`) et voir les décors réels s'afficher.
- Les acteurs requis s'affichent soit sous forme de placeholders, soit sous forme de sprites statiques (comme Timi).
- **Mais :** Le placement initial de ces acteurs dépend exclusivement de `CinematicActorInitialPlacementKind.fromMapEntity` (liant l'acteur à une entité déjà présente sur la map) ou reste non configuré. Il est impossible de dire "Cet acteur démarre ici sur cette tuile d'herbe" sans aller créer manuellement un NPC dans le Map Editor général.
- Les déplacements temporels (`actorMove`) doivent cibler des objets map-aware existants (entités, événements). Il est impossible de pointer vers une cible libre de mise en scène.
- Il n'y a aucun outil de drag-and-drop ou de clic sur la preview pour positionner les acteurs ou les cibles.

## 7. Pass A — Current Stage Context Audit

L'audit de [cinematic_asset.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/cinematic_asset.dart) révèle la structure suivante :
- `CinematicAsset.movementTargets` liste les définitions de cibles de mouvement (`CinematicMovementTargetRef`), associées à un `targetId` et un `label` textuel.
- `CinematicStageContext` contient :
  - `initialPlacements` : Liste de `CinematicActorInitialPlacement` (kind: `unset`, `fromMapEntity`, `fromMovementTarget`).
  - `movementTargetBindings` : Liste de `CinematicMovementTargetBinding` (kind: `abstractPoint`, `mapEntity`, `mapEvent`).

**Gaps identifiés :**
- `abstractPoint` est résolu comme une cible "sans coordonnées" physiques dans la preview, déclenchant un warning dans `CinematicActorDisplayPreviewModel`.
- Il n'y a aucune structure pour stocker des coordonnées libres `(x, y)` locales au stage de la cinématique.
- Si un acteur utilise un placement initial basé sur une cible de mouvement, celle-ci doit être de type `mapEntity` ou `mapEvent` pour avoir des coordonnées résolues via la map.

**Recommandation d'insertion (V1-101) :**
Nous devons enrichir le modèle core en ajoutant :
1. `CinematicStagePoint` : Une structure simple `(id, label, x, y)`.
2. Une liste `stagePoints` dans `CinematicStageContext`.
3. Un nouveau kind `CinematicActorInitialPlacementKind.fromStagePoint`.
4. Un nouveau kind `CinematicMovementTargetBindingKind.stagePoint`, associant une cible de mouvement `targetId` à un `stagePointId` physique local.
Cette architecture préserve une compatibilité ascendante totale : les anciens mappings `abstractPoint`, `mapEntity` et `mapEvent` continuent de fonctionner à l'identique.

## 8. Pass B — Preview Transform / Click Mapping Audit

La transformation géométrique de la preview est gérée dans [cinematic_map_backdrop_viewport_transform.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart) :
- Le repère d'écran local est délimité par `transform.frame` (un `Rect` positionné sur l'écran).
- La taille de la map en tuiles est définie par `mapWidth` et `mapHeight`.
- La taille d'une cellule de grille à l'écran est calculée comme suit :
  `cellWidth = frame.width / mapWidth`
  `cellHeight = frame.height / mapHeight`

### Contrat de transformation Viewport -> Map Tile
Pour convertir un point cliqué `Offset localOffset` (relatif au coin supérieur gauche du widget de preview) :
1. Soustraire le décalage de la frame du backdrop pour se situer dans la zone de la carte :
   `dxOnMap = localOffset.dx - frame.left`
   `dyOnMap = localOffset.dy - frame.top`
2. Diviser par la taille d'une tuile pour obtenir les coordonnées de grille :
   `tileX = dxOnMap / cellWidth`
   `tileY = dyOnMap / cellHeight`
3. Ajuster en fonction du mode de cadrage :
   - En mode **Carte entière**, le transform représente la totalité de la carte.
   - En mode **Vue scène**, le viewport subit un zoom (`framingState.zoom`) et un décalage (`framingState.panTiles`). Il faut donc ajuster la formule en réintégrant le pan de caméra :
     `tileX = (dxOnMap / cellWidth) + panTiles.dx`
     `tileY = (dyOnMap / cellHeight) + panTiles.dy`
4. Clamper les coordonnées finales pour éviter de placer des points hors-limites de la map :
   `tileX = tileX.clamp(0.0, mapWidth.toDouble())`
   `tileY = tileY.clamp(0.0, mapHeight.toDouble())`

### Snap à la grille
Par défaut, les Stage Points sont stockés avec des coordonnées décimales (`double`). Pour un placement propre de type "tuile entière", le clic sera projeté au centre de la tuile cliquée :
`snappedX = tileX.floor() + 0.5`
`snappedY = tileY.floor() + 0.5`
Ceci positionne idéalement le point au centre de la case sélectionnée. Le modèle conservera des doubles pour permettre, à l'avenir, des placements plus précis (sub-tile).

## 9. Pass C — Product UX / Interaction Model

Pour préserver l'aspect no-code et éviter les manipulations complexes de saisies d'identifiants, l'ergonomie d'édition spatiale doit s'intégrer directement sur le canvas.

### Options d'interaction comparées
- **Option A :** Créer uniquement depuis l'inspecteur à droite via un bouton "Ajouter un point", puis cliquer dans la preview pour placer le point actif.
- **Option B :** Clic droit sur la preview pour ouvrir un menu contextuel "Créer un point ici...".
- **Option C (Recommandée pour V0) :** Mode outil dans une barre d'outils locale de la preview. Une petite toolbar flottante propose :
  - Outil **Sélection / Pan** (défaut) : Permet de déplacer la caméra (pan), zoomer, et sélectionner un acteur ou un point existant pour voir ses propriétés dans l'inspecteur.
  - Outil **Ajouter un Point** (icône marqueur) : Active un mode où le survol de la preview affiche un marqueur fantôme (ghost marker) snapped sur la grille. Un clic gauche pose le point physiques immédiatement, ouvre une invite rapide pour renseigner un label (ex: "Départ Professeur") puis réactive l'outil Sélection.
- **Option D :** Palette d'acteurs/points à glisser-déposer (drag-and-drop) depuis la barre latérale vers le canvas. (Trop lourde pour une V0).

### Déplacements et suppressions
- **Déplacement :** En mode Sélection, un Stage Point peut être cliqué et glissé (drag-and-drop) directement à la souris. La mise à jour des coordonnées `(x, y)` dans le modèle `stageContext` se fait en temps réel ou à la fin du drag (onDragEnd).
- **Suppression :** Sélectionner un point affiche un bouton de suppression dans l'inspecteur à droite, ou permet d'appuyer sur la touche `Suppr / Backspace` du clavier. Une popup de confirmation est affichée si le point est référencé par un placement initial d'acteur ou un déplacement de la timeline.
- **Renommage :** Directement depuis le panneau d'inspection des détails du point sélectionné.

## 10. Pass D — Data Model Options

Où stocker ces nouvelles coordonnées ?

| Option | Description | Avantages | Inconvénients | Verdict |
|---|---|---|---|---|
| **Option A** | Ajouter `stagePoints` dans `CinematicStageContext`. | Localisé, propre au contexte de la cinématique. Pas d'effet de bord sur le reste du projet. | Nécessite d'adapter le parseur JSON de la cinématique. | **Retenu (V1-101)** |
| **Option B** | Réutiliser `movementTargetBindings` en y ajoutant des champs `x` et `y`. | Évite une nouvelle liste dans le modèle. | Mélange la déclaration géométrique avec le binding d'acteurs. Moins évolutif pour les points génériques. | *Rejeté* |
| **Option C** | Créer une collection `stageContext.spatialMarkers`. | Nom sémantique fort. | Plus long, s'éloigne du terme technique validé par Karim. | *Rejeté au profit de l'Option A* |
| **Option D** | Stocker les points dans `MapData` (comme entités temporaires). | Réutilise les primitives existantes du Map Editor. | Modifie et pollue le fichier de map. Interdit par la charte d'anti-scope. | **Rejeté strictement** |
| **Option E** | Créer des `mapEntities` virtuelles à la volée uniquement en mémoire runtime. | Pas de persistance. | Complique la sérialisation de la cinématique. Perte de contrôle pour l'auteur. | **Rejeté strictement** |

Le futur modèle recommandé en V1-101 est donc `CinematicStagePoint` stocké dans la liste `stagePoints` du `stageContext` de l'asset.

## 11. Pass E — Initial Placement / Movement Target Integration

Une fois créés, les Stage Points doivent pouvoir être consommés par les configurations existantes :

1. **Placements Initiaux (`CinematicActorInitialPlacement`) :**
   Actuellement, un acteur démarre soit via `unset`, soit à la position d'une entité de map (`fromMapEntity`), soit à une cible de mouvement (`fromMovementTarget`).
   Nous ajouterons `CinematicActorInitialPlacementKind.fromStagePoint`.
   Dans ce cas, l'acteur fait référence au `stagePointId` et se positionne précisément sur ses coordonnées `(x, y)`.

2. **Cibles de Mouvement (`CinematicMovementTargetBinding`) :**
   Une cible de mouvement (`CinematicMovementTargetRef`) déclarée dans la cinématique (consommée par les blocs `actorMove` de la timeline) pourra être liée à un Stage Point physique local via un binding de type `CinematicMovementTargetBindingKind.stagePoint`.
   Lors de la preview, l'acteur en mouvement interpolera sa position depuis son point de départ jusqu'aux coordonnées `(x, y)` du Stage Point résolu.

**Gestion du Legacy :**
L'ancien type de binding `abstractPoint` est préservé. S'il est utilisé, l'acteur affiche un warning d'authoring classique indiquant que la cible est abstraite, mais ne plante pas.

## 12. Pass F — Manual Path Future Contract

En V1-100, nous préparons l'architecture des chemins manuels (waypoint paths) qui feront l'objet de lots ultérieurs (V1-105 à V1-107).

### Principes retenus pour les futurs chemins
- Un chemin manuel (`CinematicManualPath`) appartiendra à la cinématique et sera stocké dans le `stageContext`.
- Il sera défini comme une séquence ordonnée de références à des Stage Points existants :
  `Path = [StagePointRef("point_depart"), StagePointRef("waypoint_1"), StagePointRef("waypoint_2"), StagePointRef("cible_arrivee")]`
- Dans un bloc de la timeline `actorMove`, au lieu de simplement sélectionner une cible finale unique, l'auteur pourra configurer le champ `pathMode` en `manual` et lier l'étape au `manualPathId` correspondant.
- **Absence de pathfinding et de collision :** Les cinématiques PokeMap se déroulent dans un cadre contrôlé par l'auteur (scripté). Il n'y aura aucun algorithme de pathfinding automatique (comme A*) ni de détection de collision dynamique lors du playback de la preview. L'acteur suivra de façon linéaire et interpolée la suite de points tracée par l'auteur.
- **Drawing UI futur :** L'auteur cliquera sur un bouton "Dessiner un chemin" dans la preview, cliquera sur plusieurs tuiles successives (ce qui créera des waypoints Stage Points invisibles ou discrets connectés par des lignes de rappel colorées), facilitant grandement la mise en scène.

## 13. Pass G — Diagnostics / Validation

L'introduction des coordonnées physiques éditables nécessite d'étendre la couche de validation du Narrative Studio afin de détecter les incohérences structurelles. Les futurs diagnostics (V1-101) comprendront :

- `stagePointMissingId` (Erreur) : Un Stage Point a un identifiant vide.
- `stagePointDuplicateId` (Erreur) : Plusieurs Stage Points partagent le même identifiant.
- `stagePointEmptyLabel` (Warning) : Un Stage Point n'a pas de nom lisible pour l'auteur.
- `stagePointOutOfMap` (Warning) : Le Stage Point est placé en dehors des dimensions actuelles de la carte.
- `stagePointMapMismatch` (Warning) : Le Stage Point fait référence à des tuiles qui n'existent pas sur la map stage actuellement chargée.
- `stagePointWithoutStageMap` (Info) : Un Stage Point existe mais aucune map de scène n'est configurée dans la cinématique.
- `stagePointUnused` (Info) : Un Stage Point est défini mais n'est utilisé ni comme départ d'acteur, ni comme cible de mouvement, ni comme waypoint.
- `actorInitialPlacementStagePointMissing` (Erreur) : L'acteur est configuré pour démarrer sur un Stage Point qui a été supprimé.
- `movementTargetBindingStagePointMissing` (Erreur) : Une cible de mouvement est liée à un Stage Point introuvable.
- `manualPathMissingPoint` (Erreur) : Un chemin fait référence à un Stage Point inexistant.
- `manualPathTooFewPoints` (Warning) : Un chemin manuel contient moins de 2 points.

## 14. Pass H — Tests / Visual Gate Future

Pour valider l'implémentation des lots V1-101 à V1-107, les tests automatisés suivants devront être mis en œuvre :

### Tests Core (V1-101)
- Validation de la sérialisation / désérialisation JSON de `CinematicStagePoint` et de sa présence dans `stageContext`.
- Tests des opérations pures d'authoring dans `CinematicAuthoringOperations` : `addStagePoint`, `updateStagePointPosition`, `renameStagePoint`, `removeStagePoint`.
- Tests unitaires des diagnostics statiques de validation dans `CinematicDiagnostics`.

### Tests Widget / UX (V1-102 à V1-104)
- Tests de détection de clics sur le widget de preview et validation de la conversion mathématique en coordonnées de tuiles (mockant `CinematicMapBackdropViewportTransform`).
- Tests widget confirmant que l'activation du mode outil "Ajouter un Point" permet de capturer un clic et d'insérer un marqueur dans l'état de l'éditeur.
- Tests widget validant le drag-and-drop d'un marqueur sur le canvas de preview avec mise à jour des coordonnées.
- Validation géométrique : test unitaire garantissant qu'aucune coordonnée n'induit de mutation directe ou indirecte de l'état `MapData` (protection de la map de fond).

## 15. Pass I — Product Reviewer

L'intégration de la spatialisation dans la preview répond directement aux exigences du manifeste PokeMap :
- **No-code first :** L'auteur place ses personnages et ses cibles à la souris sur une représentation visuelle fidèle de la carte du projet, plutôt que d'écrire des coordonnées numériques `(X, Y)` dans un formulaire ou de devoir manipuler des identifiants d'entités de carte complexes.
- **Découplage de la map :** Le Cinematic Builder n'altère pas les calques du Map Editor. Une cinématique peut impliquer 10 personnages temporaires se déplaçant dans une pièce sans polluer le fichier de carte global.
- **Workflow séquentiel propre :** L'auteur définit les points géographiques clés de sa mise en scène, puis s'en sert pour configurer la timeline (départs d'acteurs, cibles de déplacements). Le playback pourra ensuite s'exécuter de manière fluide et prévisible sur ces coordonnées réelles.

---

## 16. Options comparées

Pour le stockage et l'association des points de scène, nous avons évalué :
1. **Option A (Ajout d'une liste `stagePoints` autonome dans le Stage Context) :**
   - *Description :* Les Stage Points forment une bibliothèque spatiale locale à la cinématique. Les placements d'acteurs et les cibles de mouvement y font référence par identifiant.
   - *Avantages :* Conception propre et modulaire. Réutilisabilité aisée d'un même point pour plusieurs acteurs ou étapes chronologiques de la timeline.
   - *Inconvénients :* Légère augmentation de la taille du schéma JSON de la cinématique.
2. **Option B (Stockage inline dans les bindings existants) :**
   - *Description :* Ajouter directement des propriétés optionnelles `double? x` et `double? y` dans `CinematicActorInitialPlacement` et `CinematicMovementTargetBinding`.
   - *Avantages :* Pas de nouvelle classe de données.
   - *Inconvénients :* Empêche la réutilisation d'un même repère de scène. Impossible de définir un point générique (comme une caméra ou un waypoint intermédiaire) qui ne soit pas explicitement un départ d'acteur ou une cible finale.
3. **Option D (Stockage dans MapData) :**
   - *Description :* Utiliser le modèle de données de carte pour déclarer des entités spéciales.
   - *Verdict :* Rejeté strictement car viole l'isolation de la cinématique par rapport au monde de jeu partagé.

## 17. Option retenue

L'**Option A (stagePoints dans CinematicStageContext)** est officiellement retenue.
Elle offre le meilleur équilibre entre extensibilité (pour les futurs chemins complexes et points de caméra) et propreté de l'architecture.

---

## 18. Contrat futur Stage Point

Le modèle de données `CinematicStagePoint` (à créer dans `packages/map_core/lib/src/models/cinematic_asset.dart` en V1-101) respectera le contrat suivant :

```dart
@immutable
final class CinematicStagePoint {
  const CinematicStagePoint({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    this.description,
    this.metadata = const <String, String>{},
  });

  final String id;          // Identifiant stable et unique au sein de la cinématique
  final String label;       // Label affiché à l'auteur dans l'éditeur
  final double x;           // Coordonnée sur l'axe X de la carte (en unités de tuile)
  final double y;           // Coordonnée sur l'axe Y de la carte (en unités de tuile)
  final String? description; // Note explicative facultative pour l'auteur
  final Map<String, String> metadata; // Métadonnées extensibles
}
```

La sérialisation JSON correspondante sera :

```json
{
  "id": "depart_timi",
  "label": "Départ de Timi",
  "x": 12.5,
  "y": 8.0,
  "description": "Près de la barrière en bois",
  "metadata": {}
}
```

## 19. Contrat futur placement preview

Lorsqu'un clic gauche est détecté sur la preview en mode "Ajout de Point" :
1. Calcul de la position cartographique brute :
   `tileX = (localClick.dx - frame.left) / cellWidth`
   `tileY = (localClick.dy - frame.top) / cellHeight`
2. Application du snap par défaut :
   `snappedX = tileX.floorToDouble() + 0.5`
   `snappedY = tileY.floorToDouble() + 0.5`
3. Clamping strict dans les dimensions de la carte `[0, mapWidth]` et `[0, mapHeight]`.
4. Ajout immédiat dans le modèle via l'opération pure :
   `stageContext = stageContext.copyWith(stagePoints: [...stageContext.stagePoints, newPoint])`
5. L'affichage de la preview est immédiatement rafraîchi et fait apparaître le nouveau marqueur graphique (un pion de couleur spécifique, avec le label affiché au-dessus).

## 20. Contrat futur initialPlacement from stagePoint

L'énumération `CinematicActorInitialPlacementKind` sera enrichie du cas `fromStagePoint` :

```dart
enum CinematicActorInitialPlacementKind {
  unset,
  fromMapEntity,
  fromMovementTarget,
  fromStagePoint, // Nouveau
}
```

Si le placement initial d'un acteur est de type `fromStagePoint` :
- Le champ `targetId` de `CinematicActorInitialPlacement` portera l'identifiant du Stage Point ciblé.
- La méthode `_resolvePosition` de `CinematicActorDisplayPreviewModel` localisera le Stage Point dans la liste `stagePoints`, extraira ses coordonnées `x` et `y` et retournera un statut `CinematicActorPreviewPositionStatus.resolved` avec les coordonnées associées.

## 21. Contrat futur actorMove target from stagePoint

Pour les déplacements temporels configurés dans la timeline :
- La cible de mouvement (`CinematicMovementTargetRef`) référencée par l'étape `actorMove` de la timeline sera liée au Stage Point via `CinematicMovementTargetBinding` :
  ```dart
  enum CinematicMovementTargetBindingKind {
    abstractPoint,
    mapEntity,
    mapEvent,
    stagePoint, // Nouveau
  }
  ```
- Lorsque le binding est de type `stagePoint`, le champ `sourceId` stocke le `stagePointId`.
- Le résolveur géométrique extrait les coordonnées `x` et `y` du Stage Point correspondant pour calculer le déplacement physique de l'acteur de preview.

## 22. Contrat futur manual path

Pour le futur tracé de chemins complexes (waypoint paths) :
- Un chemin manuel est représenté par une structure logique optionnelle `CinematicManualPath` :
  ```dart
  @immutable
  final class CinematicManualPath {
    const CinematicManualPath({
      required this.id,
      required this.label,
      required this.actorId,
      this.waypointPointIds = const <String>[],
    });

    final String id;
    final String label;
    final String actorId;
    final List<String> waypointPointIds; // Liste ordonnée de stagePointId
  }
  ```
- Durant la phase de pré-visualisation (et plus tard le playback), le déplacement de l'acteur se fait de manière rectiligne et interpolée d'un point à un autre dans l'ordre de la liste, sans calcul d'évitement d'obstacles ou de dérive.

---

## 23. Diagnostics futurs

Les diagnostics introduits en V1-101 s'assureront qu'aucune erreur de modélisation narrative n'altère la stabilité de l'éditeur :

```dart
enum CinematicDiagnosticCode {
  // ... codes existants ...
  stagePointMissingId,
  stagePointDuplicateId,
  stagePointEmptyLabel,
  stagePointOutOfMap,
  stagePointMapMismatch,
  stagePointUnused,
  actorInitialPlacementStagePointMissing,
  movementTargetBindingStagePointMissing,
}
```

Ces erreurs seront projetées en temps réel dans le panneau "Préparation preview" et bloqueront le futur bouton d'activation du Playback.

## 24. Tests futurs

La suite de tests unitaires couvrira en V1-101 :
- `cinematic_stage_point_test.dart` : Tests unitaires de validation JSON pour la nouvelle structure `CinematicStagePoint`.
- `cinematic_authoring_operations_stage_point_test.dart` : Validation des modifications fonctionnelles de l'état (ajout, modification, suppression de points, gestion des cascade-deletes sur les bindings).
- `cinematic_diagnostics_stage_point_test.dart` : Couverture exhaustive des nouveaux codes de diagnostics en injectant des configurations erronées (points hors-limites, IDs dupliqués, bindings orphelins).

---

## 25. Roadmaps mises à jour

Les plans de développement régionaux de PokeMap ont été révisés afin d'insérer cette étape essentielle avant le playback physique :
1. [road_map_scenes.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/road_map_scenes.md)
2. [road_map_scene_builder_authoring.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md)

Le lot V1-100 y est déclaré comme **DONE**, et le prochain lot immédiat recommandé est **NS-SCENES-V1-101 — Cinematic Stage Point Core Model V0**.

## 26. Non-objectifs confirmés

Pour garantir le respect strict des limites géographiques de ce lot documentaire :
- **Aucune écriture de code Dart produit :** Aucun fichier d'implémentation dans `packages/` n'a été altéré.
- **Aucune modification d'UI :** Pas d'icône d'outil de placement ajoutée, pas de boutons de drag sur le CustomPaint.
- **Aucune création d'entité de map :** Les fichiers cartographiques `*.json` du projet restent intouchés.
- **Pas de Flame/Runtime :** Le playback temporel interactif n'est pas activé et aucune instance de moteur de jeu n'a été instanciée.
- **Pas de pathfinding/collision :** Aucun algorithme d'évitement d'obstacles n'est modélisé.

## 27. Commandes exécutées

Toutes les vérifications préalables ont été menées à l'aide de commandes Git en lecture seule depuis la racine :
- `git status --short --untracked-files=all`
- `git diff --stat`
- `git diff --name-only`
- `git log --oneline -n 15`

## 28. Checks anti-scope

Une analyse statique confirme que le répertoire `packages/` n'a subi aucune modification. 
De plus, la commande suivante a été exécutée pour valider l'absence de termes techniques interdits (tels que FlameGame, GameWidget, pathfinding, ou des mutations réelles de MapData) au sein du présent document :
```bash
rg -n "PlayableMapGame|RuntimeMapGame|GameWidget|FlameGame|GameState|map_runtime|currentTimeMs|playbackTimeMs|isPlaying|Timer\(|Ticker|AnimationController|pathfinding|collision|MapData mutation|mapEntity created|mapEvent created" reports/narrativeStudio/scenes/ns_scenes_v1_100_cinematic_spatial_authoring_stage_points_prep_contract_v0.md
```
Les occurrences trouvées appartiennent uniquement aux sections de documentation de non-objectifs et aux descriptions de la roadmap future.

## 29. Evidence Pack

L'ensemble des traces d'exécution, analyses géométriques et hunks de modifications des roadmaps est regroupé dans le document :
[ns_scenes_v1_100_evidence_pack.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/ns_scenes_v1_100_evidence_pack.md).

## 30. Auto-review critique

1. **Est-ce que V1-100 a modifié du code produit ?** Non.
2. **Est-ce que V1-100 a modifié packages/ ?** Non.
3. **Est-ce que V1-100 a créé un test ?** Non.
4. **Est-ce que V1-100 a généré un screenshot ?** Non.
5. **Est-ce que V1-100 a ajouté un modèle core ?** Non.
6. **Est-ce que V1-100 a ajouté une UI ?** Non.
7. **Est-ce que V1-100 a lancé du playback ?** Non.
8. **Est-ce que V1-100 a importé runtime/Flame ?** Non.
9. **Est-ce que V1-100 a modifié MapData ?** Non.
10. **Est-ce que V1-100 a créé une mapEntity ?** Non.
11. **Est-ce que V1-100 a créé un mapEvent ?** Non.
12. **Est-ce que V1-100 a expliqué pourquoi playback est repoussé ?** Oui, pour éviter un playback avec des acteurs mal positionnés ou configurés indirectement.
13. **Est-ce que V1-100 a cadré les Stage Points ?** Oui, modèle `CinematicStagePoint` autonome.
14. **Est-ce que V1-100 a cadré le click preview -> tile ?** Oui, formules inverses de transformation géométrique intégrant le pan/zoom.
15. **Est-ce que V1-100 a cadré initialPlacement from stagePoint ?** Oui, avec l'énumération kind mise à jour.
16. **Est-ce que V1-100 a cadré actorMove target from stagePoint ?** Oui, résolution via `CinematicMovementTargetBindingKind.stagePoint`.
17. **Est-ce que V1-100 a cadré manual path future ?** Oui, modèle de chemin manuel rectiligne, ordonné et sans obstacle.
18. **Est-ce que V1-100 a listé les diagnostics futurs ?** Oui, 8 nouveaux diagnostics d'édition spatiale définis.
19. **Est-ce que V1-100 a listé les tests futurs ?** Oui, tests core, d'opérations pures et widget-tests de drag-and-drop.
20. **Est-ce que V1-100 a mis à jour les roadmaps ?** Oui.
21. **Est-ce que l’Evidence Pack est complet ?** Oui.
22. **Quel est le prochain lot exact recommandé ?** `NS-SCENES-V1-101 — Cinematic Stage Point Core Model V0`.

## 31. Recommandation pour le prochain lot

Nous recommandons d'engager immédiatement le lot :
**NS-SCENES-V1-101 — Cinematic Stage Point Core Model V0**

**Objectif :**
Ajouter au modèle d'authoring core la classe `CinematicStagePoint` dans `packages/map_core/lib/src/models/cinematic_asset.dart`, la désérialisation JSON associée, les opérations d'édition pures sans UI, et l'implémentation de la validation statique des diagnostics. Aucun composant de rendu ou de placement d'acteur interactif ne sera codé à cette étape.
