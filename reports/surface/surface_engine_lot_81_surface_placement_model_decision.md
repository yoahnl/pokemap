# Lot 81 — Surface Placement Model Decision V0

## Résumé exécutif

Le Lot 80 a prouvé que Surface Studio peut produire et sauvegarder un `ProjectManifest.surfaceCatalog` cohérent : atlas, animations et preset Surface sont persistés puis relus par `ProjectManifest.fromJson`.

Le Lot 81 tranche la question suivante : comment une map doit-elle utiliser ce catalogue ?

Décision recommandée :

- créer un `SurfaceLayer` dédié dans les maps ;
- stocker les placements Surface en sparse, pas en grille complète ;
- chaque placement référence un `ProjectSurfacePreset` via `surfacePresetId` ;
- ne pas persister le rôle autotile calculé en V0 ;
- résoudre le rôle au rendu/preview à partir des voisins ayant le même `surfacePresetId` ;
- garder `TerrainLayer` et `PathLayer` legacy intacts ;
- brancher editor/runtime progressivement dans des lots séparés.

Ce lot ne crée aucun modèle, ne modifie aucun code et ne lance pas `build_runner`.

## Périmètre

Autorisé :

- lire le repo ;
- produire une décision d’architecture ;
- créer uniquement ce rapport.

Interdit et respecté :

- aucun `SurfaceLayer` créé ;
- aucun `SurfaceCell` / `SurfacePlacement` créé ;
- aucun fichier Dart modifié ;
- aucun modèle Freezed/JSON modifié ;
- aucun fichier generated modifié ;
- aucun runtime renderer créé ;
- aucun painter map créé ;
- aucun provider/repository/service Surface créé ;
- aucune migration legacy codée ;
- aucun test ou fixture modifié.

## Gate 0 — Status initial avant modification

Commandes exécutées avant toute création de fichier :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
```

Sortie complète :

```text
/Users/karim/Project/pokemonProject
codex/psdk-fight-next-move-wave
19c75e77 feat(map_editor): ajouter preset vertical atlas et golden slice e2e
ccdf1094 fix(map_editor): lisibilité et ergonomie sélecteur colonne aperçu atlas
33d776aa feat(map_editor): Lot 78 — animations Surface depuis atlas vertical
1a92a64e feat(map_editor): Surface Studio Lot 77 — plan génération animations atlas vertical
021abf5f feat(map_editor): Surface Studio Lots 75–76 — mapping colonnes + preview animation
cd9bf788 feat(map_editor): Surface Studio Lot 74 — assistant atlas vertical + preview grand format
13569f30 feat(map_editor): Surface Studio Lot 73 — grille sur aperçu image source
24467c67 feat(map_editor): Surface Studio Lot 72 — aperçu image source (résolution disque)
fcdc064d feat(map_editor): Surface Studio Lot 71 — aperçu grille atlas (preview V0)
1c763366 fix(map_editor): thème Material local pour Préparation atlas Surface Studio
```

Notes :

- `git status --short --untracked-files=all` : aucune sortie.
- `git diff --stat` : aucune sortie.
- Status initial vide.
- Aucun changement préexistant détecté.

## Passes Composer 2

### Pass 1 — Gate 0 + analyse du worktree

Gate 0 exécuté avant modification. La branche courante est `codex/psdk-fight-next-move-wave`. Le status initial et le diff stat initial sont vides.

### Pass 2 — Audit des modèles map actuels

`MapData` stocke :

- `id`, `name`, `size`, `version`, `tilesetId` ;
- `layers: List<MapLayer>` ;
- `placedElements`, `entities`, `connections`, `warps`, `triggers`, `gameplayZones`, `events`.

Fichier clé : `packages/map_core/lib/src/models/map_data.dart`.

Observation importante : les comportements gameplay existent déjà sous forme de `MapGameplayZone`. Le commentaire du modèle sépare explicitement gameplay et visuel. Une future Surface ne doit donc pas embarquer directement toutes les règles de rencontre, surf ou hazard dans la cellule visuelle V0.

### Pass 3 — Audit TerrainLayer / PathLayer / TileLayer

Fichier clé : `packages/map_core/lib/src/models/map_layer.dart`.

Layers existants :

- `TileLayer` :
  - `tilesetId?`;
  - `tiles: List<int>`;
  - grille complète `width * height`.
- `CollisionLayer` :
  - `collisions: List<bool>`;
  - grille complète.
- `TerrainLayer` :
  - `terrains: List<TerrainType>`;
  - grille complète ;
  - chaque cellule stocke un enum de terrain, pas un preset.
- `PathLayer` :
  - `presetId: String`;
  - `cells: List<bool>`;
  - grille complète ;
  - un preset par layer, pas par cellule ;
  - `properties`, `animationMode`, `animationTriggers`.
- `ObjectLayer` :
  - couche nominale sans grille interne.

Opérations auditées :

- `map_paint.dart` : peinture tile complète par index ;
- `map_terrain.dart` : peinture terrain, effacement par `TerrainType.none` ;
- `map_path.dart` : peinture path booléenne, affectation d’un `presetId` au layer ;
- `map_terrain_autotile.dart` : résolution de variantes à partir des voisins.

Constat : `PathLayer` est proche d’une surface legacy, mais sa structure ne suffit pas au modèle Surface cible parce que le preset est porté par le layer entier. Une couche Surface moderne doit pouvoir stocker plusieurs placements de presets différents ou, au minimum, ne pas figer le choix architectural à “un preset par layer”.

### Pass 4 — Audit serialization map / manifest / project

`MapLayer` est une union Freezed sérialisée via `runtimeType`.

Fichier generated lu en lecture seule : `packages/map_core/lib/src/models/map_layer.g.dart`.

Valeurs connues actuellement :

- `tile`
- `collision`
- `terrain`
- `path`
- `object`

Conséquence : un futur `runtimeType: surface` ne sera pas lisible par les anciens binaires. C’est un risque de compatibilité forward, mais il est attendu pour une vraie nouvelle couche de map. Il faudra éviter toute migration automatique destructive des maps legacy et garder `PathLayer`/`TerrainLayer` supportés.

`ProjectManifest.surfaceCatalog` existe déjà :

- absent ou `null` en JSON -> `ProjectSurfaceCatalog()` ;
- non-object -> `ValidationException`;
- object -> `decodeProjectSurfaceCatalog`.

Fichier clé : `packages/map_core/lib/src/models/project_manifest.dart`.

`FileMapRepository` sauvegarde les maps via `MapData.toJson()` après `MapValidator.validate(map)`. Toute intégration future de `SurfaceLayer` devra donc mettre à jour le modèle, le generated JSON et le validator dans un lot dédié.

### Pass 5 — Audit editor painter / tools existants

Fichiers clés :

- `packages/map_editor/lib/src/features/editor/application/map_selection_controller.dart`
- `packages/map_editor/lib/src/application/services/terrain_painting_coordinator.dart`
- `packages/map_editor/lib/src/application/services/path_layer_editing_coordinator.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/lib/src/features/surface_studio/*`

Constats :

- l’outil `terrainPaint` couvre actuellement `TerrainLayer` et `PathLayer` ;
- l’eraser couvre tile/collision/terrain/path ;
- Surface Studio existe comme workspace séparé, pas comme outil de peinture map ;
- `MapGridPainter` rend les terrains, puis les paths, puis les tile layers, puis les entités et overlays ;
- les previews path/terrain réutilisent les resolvers legacy ;
- aucun outil `surfacePaint` n’existe encore ;
- aucun painter Surface dans la map n’existe encore.

Impact : l’éditeur devra ajouter une palette Surface issue de `ProjectSurfaceCatalog.presets`, puis un outil de peinture dédié. Il ne faut pas réutiliser silencieusement le mode `terrainPaint`, sinon l’UX restera ambiguë entre terrain legacy, path legacy et Surface native.

### Pass 6 — Audit runtime Flame / renderer existant

Fichiers clés :

- `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/application/runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart`
- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/runtime_path_autotile.dart`

Constats :

- le runtime charge `ProjectManifest` puis `MapData` ;
- `collectAllRuntimeTilesetIds` collecte les tilesets des tile layers, terrain presets, path presets, éléments et personnages ;
- il ne collecte pas encore les tilesets référencés par `ProjectManifest.surfaceCatalog` parce qu’aucune map ne référence encore ce catalogue ;
- `MapLayersComponent` construit :
  - `_terrainPresetsByType`;
  - `_pathAutotileByPresetId`;
  - règles d’animation path ;
- le rendu background fait actuellement :
  1. terrain ;
  2. path ;
  3. tile ;
  4. entités ;
  5. collision overlay si demandé ;
- aucun renderer Surface n’existe.

Impact : la future intégration runtime doit ajouter une chaîne dédiée :

```text
SurfaceLayer
→ ProjectManifest.surfaceCatalog
→ resolver preset → animation → atlas
→ clock/timeline
→ source rect
→ Flame drawImageRect
```

Elle ne doit pas passer par `RuntimePathAutotileSet`, qui reste legacy.

### Pass 7 — Comparaison des options de modèle Surface

Options étudiées :

- Option A — réutiliser `PathLayer`
- Option B — étendre `TerrainLayer`
- Option C — créer `SurfaceLayer` dédié
- Option D — stocker des overlays Surface dans un layer générique ou dans `properties`

### Pass 8 — Décision recommandée

Décision : créer un `SurfaceLayer` dédié, sparse, référencé par `surfacePresetId`, avec résolution d’autotile au rendu/preview.

### Pass 9 — Roadmap Lots 82+

Voir section dédiée.

### Pass 10 — Auto-review critique

Voir section dédiée.

## Audit des modèles map actuels

`MapData.layers` est le point d’insertion naturel. Les layers sont déjà le mécanisme de composition visuelle d’une map. Ajouter une Surface ailleurs, par exemple dans `MapData.properties`, contournerait les outils existants et rendrait la validation fragile.

Le modèle map distingue déjà :

- données visuelles : `MapLayer`;
- entités : `MapEntity`, `MapPlacedElement`;
- gameplay zones : `MapGameplayZone`;
- triggers/warps/events.

Cette séparation soutient la décision suivante : la Surface V0 est une couche visuelle animée/autotilée. Le gameplay associé doit rester dans des contrats séparés tant que le modèle Surface gameplay n’est pas explicitement conçu.

## Audit TerrainLayer / PathLayer / TileLayer

### TileLayer

`TileLayer` est une grille complète d’ids de tiles. Elle est trop bas niveau pour Surface :

- elle référence des ids numériques, pas des presets ;
- elle fige le résultat visuel plutôt qu’une intention Surface ;
- elle ne permet pas de recalculer l’autotile proprement.

### TerrainLayer

`TerrainLayer` stocke un `TerrainType` par cellule. Avantages :

- simple ;
- compact conceptuellement ;
- déjà validé comme grille complète.

Limites pour Surface :

- `TerrainType` est un enum fermé et trop générique ;
- plusieurs presets peuvent partager un même `TerrainType`;
- la couche ne référence pas `ProjectSurfacePreset`;
- elle ne peut pas exprimer eau/lave/glace/pont/surface custom correctement ;
- elle mélange terrain de fond et surfaces animées.

### PathLayer

`PathLayer` est le legacy le plus proche :

- `presetId`;
- cellules booléennes ;
- autotile runtime ;
- animation path.

Mais ses limites sont précisément celles que la roadmap Surface cherche à dépasser :

- un seul `presetId` pour toute la couche ;
- stockage dense booléen ;
- sémantique legacy path/surface overlay ;
- animation path portée par le layer, pas par un preset Surface natif ;
- pas de référence au `ProjectSurfaceCatalog`.

### Conclusion

`SurfaceLayer` doit être un nouveau type de layer, pas une mutation de `TerrainLayer` ou `PathLayer`.

## Audit sérialisation map

Les maps sont sérialisées via `MapData.toJson()` et `MapLayer.toJson()`. `MapLayer` utilise `runtimeType`.

Effet pour un futur `SurfaceLayer` :

- ajout d’un cas Freezed obligatoire ;
- génération `map_layer.freezed.dart` / `map_layer.g.dart` dans un lot futur ;
- mise à jour de `MapValidator`;
- tests JSON de round-trip ;
- stratégie de compatibilité forward à documenter.

Risque important : les anciens binaires ne sauront pas parser `runtimeType: surface`. Le choix reste acceptable si :

- aucune migration automatique des maps legacy n’est faite au moment d’introduire le type ;
- `PathLayer` reste supporté ;
- l’éditeur avertit lorsqu’une map utilise des Surface layers ;
- les tests de compatibilité old manifest restent séparés des tests de nouvelle map Surface.

## Audit éditeur

Surface Studio produit le catalogue, mais la map ne sait pas encore peindre ce catalogue.

Les lots suivants devront ajouter :

- sélection d’un `ProjectSurfacePreset`;
- outil Surface Painter distinct ;
- création de `SurfaceLayer`;
- paint / erase sparse ;
- preview statique ;
- preview animée ;
- diagnostics de placement ;
- save/reload de maps contenant des Surface layers.

Le point à ne pas rater : Surface Studio et Map Canvas doivent rester deux expériences coordonnées mais distinctes.

Surface Studio sert à créer la bibliothèque.
Le Map Canvas sert à placer des usages concrets de cette bibliothèque.

## Audit runtime

Le runtime actuel est centré sur :

- `TerrainLayer` -> `ProjectTerrainPreset` par `TerrainType`;
- `PathLayer` -> `ProjectPathPreset` par `presetId`;
- `RuntimePathAutotileSet` pour les paths legacy.

Le futur runtime Surface doit éviter de réutiliser `RuntimePathAutotileSet` directement, car le modèle Surface natif utilise :

- `ProjectSurfacePreset`;
- `SurfaceVariantRole`;
- `ProjectSurfaceAnimation`;
- `ProjectSurfaceAtlas`;
- `SurfaceAnimationFrame`.

Il faudra donc une chaîne runtime dédiée :

```text
SurfaceLayer placement
→ surfacePresetId
→ ProjectSurfacePreset
→ SurfaceVariantRole résolu par voisins
→ animationId
→ ProjectSurfaceAnimation
→ frame courante
→ SurfaceAtlasTileRef
→ ProjectSurfaceAtlas.tilesetId + géométrie
→ RuntimeTilesetImage
```

## Options étudiées

### Option A — Réutiliser PathLayer

Principe : continuer à stocker les surfaces animées comme `PathLayer`.

Avantages :

- peu de changement immédiat ;
- le runtime path sait déjà dessiner des autotiles animés ;
- l’éditeur sait déjà peindre des cellules path ;
- migration courte pour eau/lave/glace.

Inconvénients :

- garde la limite “un preset par layer” ;
- continue à confondre path legacy et Surface native ;
- réutilise `TerrainPathVariant` au lieu de `SurfaceVariantRole`;
- empêche de représenter proprement des surfaces personnalisées par cellule ;
- rend hautes herbes/eau trop semblables ;
- repousse encore la vraie migration.

Risques :

- dette legacy prolongée ;
- Surface Studio produit des `ProjectSurfacePreset`, mais les maps continuent à référencer `ProjectPathPreset`;
- runtime Surface jamais vraiment introduit.

Impact editor :

- rapide mais ambigu ;
- palette Surface devrait convertir vers path presets ou dupliquer les données.

Impact runtime :

- peu de travail court terme ;
- dette forte long terme.

Impact JSON :

- pas de nouveau type de layer ;
- mais pas de représentation native Surface.

Impact migration legacy :

- migration quasi nulle ;
- mais aucune vraie sortie du legacy.

Verdict : rejetée.

### Option B — Étendre TerrainLayer

Principe : faire porter les surfaces par `TerrainLayer`, par exemple via nouveaux `TerrainType` ou propriétés associées.

Avantages :

- couche déjà dense par cellule ;
- intégration peinture terrain existante ;
- logique gameplay zones déjà conceptuellement séparée.

Inconvénients :

- `TerrainType` est trop limité ;
- un type ne désigne pas un preset ;
- impossible de choisir entre plusieurs presets pour le même type ;
- ne couvre pas eau/lave/glace/rails/custom sans élargir excessivement l’enum ;
- pousse des surfaces animées dans un modèle de terrain de fond.

Risques :

- explosion d’enums ;
- mauvaise compatibilité avec Surface Studio ;
- confusion entre classification terrain et placement visuel.

Impact editor :

- l’outil terrain deviendrait encore plus chargé.

Impact runtime :

- renderer terrain deviendrait un renderer Surface déguisé.

Impact JSON :

- changement plus discret mais sémantiquement confus.

Impact migration legacy :

- difficile, car `PathLayer.water` ne migre pas naturellement vers `TerrainType`.

Verdict : rejetée.

### Option C — Créer SurfaceLayer dédié

Principe : ajouter un nouveau type de `MapLayer` pour les surfaces placées dans une map.

Avantages :

- modèle explicite ;
- référence directe à `ProjectSurfacePreset`;
- sépare Surface native de legacy path/terrain ;
- compatible avec Surface Studio ;
- laisse `PathLayer` et `TerrainLayer` intacts ;
- ouvre la voie à un runtime dédié ;
- permet de choisir sparse et par-cellule.

Inconvénients :

- nouveau cas Freezed/JSON ;
- anciens binaires ne liront pas `runtimeType: surface`;
- nécessite nouveaux outils éditeur ;
- nécessite renderer runtime dédié ;
- nécessite diagnostics de références.

Risques :

- si introduit trop vite, les maps Surface deviennent invisibles en runtime ;
- si les cellules sont mal conçues, migration compliquée.

Impact editor :

- nécessite palette et painter Surface ;
- mais l’UX devient claire.

Impact runtime :

- nécessite `SurfaceResolver`, `SurfaceAnimationClock`, renderer Flame ;
- mais la séparation est saine.

Impact JSON :

- ajout d’un nouveau union case dans `MapLayer`;
- tests JSON obligatoires.

Impact migration legacy :

- migration plus claire :
  - `PathLayer.presetId` legacy -> `SurfaceLayer.placements[].surfacePresetId`;
  - `cells == true` -> placements sparse.

Verdict : recommandée.

### Option D — Layer générique / overlays dans properties

Principe : stocker des surfaces dans un layer générique, `MapData.properties`, ou une structure ad hoc hors union.

Avantages :

- évite temporairement Freezed/build_runner ;
- possible pour expérimentation rapide.

Inconvénients :

- schema caché ;
- validation faible ;
- tooling difficile ;
- runtime/editor doivent connaître une convention implicite ;
- tests JSON moins fiables ;
- dette technique immédiate.

Risques :

- données Surface invisibles aux validators ;
- bugs silencieux ;
- migration future plus coûteuse.

Impact editor :

- implémentation initiale rapide mais UX et maintenance faibles.

Impact runtime :

- parsing manuel non typé.

Impact JSON :

- faible bruit apparent, forte dette.

Impact migration legacy :

- chemin de migration flou.

Verdict : rejetée.

## Comparaison des options

| Option | Clarté métier | Compatibilité Surface Studio | Runtime futur | Compat legacy | Dette |
| --- | --- | --- | --- | --- | --- |
| Réutiliser PathLayer | faible | faible | moyenne court terme, faible long terme | bonne court terme | élevée |
| Étendre TerrainLayer | faible | faible | faible | faible | élevée |
| SurfaceLayer dédié | forte | forte | forte | bonne avec migration explicite | maîtrisée |
| Layer générique/properties | faible | moyenne court terme | faible | faible | très élevée |

Conclusion : `SurfaceLayer` dédié est la seule option qui aligne le modèle map avec `ProjectManifest.surfaceCatalog`.

## Décision recommandée

Créer un `SurfaceLayer` dédié, stocké dans `MapData.layers`, avec des placements sparse par coordonnées.

Chaque placement référence un `ProjectSurfacePreset` via `surfacePresetId`.

Le rôle de variante n’est pas persisté en V0. Il est résolu par un resolver selon les voisins, en comparant les placements du même `surfacePresetId` dans le même `SurfaceLayer`.

Les overrides de rôle, overlays tall grass, gameplay surf/encounter/hazard, ponts et migrations legacy sont réservés à des lots futurs.

## Modèle conceptuel proposé

Nom conceptuel recommandé :

```text
MapLayer.surface
```

Structure conceptuelle V0 :

```text
SurfaceLayer
- id
- name
- isVisible
- opacity
- placements: List<SurfaceCellPlacement>
```

Cellule conceptuelle V0 :

```text
SurfaceCellPlacement
- x
- y
- surfacePresetId
```

Règles V0 recommandées :

- `x >= 0`, `y >= 0`;
- coordonnées dans la map ;
- `surfacePresetId` non vide ;
- un seul placement par coordonnée dans un même `SurfaceLayer`;
- peindre une surface sur une cellule remplace le placement existant de cette cellule dans ce layer ;
- effacer une surface supprime le placement à cette coordonnée ;
- les placements sont sérialisés dans un ordre déterministe, recommandé : `y`, puis `x`, puis `surfacePresetId`.

Hors scope V0 :

```text
variantRoleOverride
metadata
gameplay behavior
render band per cell
overlay player
multi-surface same cell in one layer
weighted visual alternatives per placement
```

Ces besoins sont réels, mais ne doivent pas entrer dans le premier modèle de placement.

## Règles d’autotile recommandées

Décision V0 :

- ne pas stocker le rôle calculé ;
- calculer le rôle depuis les voisins au preview/rendu ;
- connecter uniquement les cellules du même `surfacePresetId` dans le même `SurfaceLayer`;
- utiliser le vocabulaire `SurfaceVariantRole`, pas `TerrainPathVariant`;
- produire un fallback si le preset ne couvre pas le rôle résolu ;
- documenter les rôles manquants via diagnostics.

Pourquoi ne pas persister le rôle calculé :

- le JSON resterait obsolète après chaque paint/erase voisin ;
- la migration serait plus fragile ;
- les rôles dépendent de règles de resolver qui peuvent évoluer ;
- l’utilisateur veut placer une intention Surface, pas une tuile technique.

Override futur :

```text
variantRoleOverride?: SurfaceVariantRole
```

Mais pas en V0. Il faudra d’abord stabiliser les règles automatiques.

## Référencement du catalogue Surface

La map doit référencer :

```text
surfacePresetId
```

Elle ne doit pas référencer directement :

```text
animationId
atlasId
tilesetId
```

Justification :

- `ProjectSurfacePreset` est l’unité auteur qui représente une surface utilisable ;
- le preset encapsule les rôles visuels ;
- les animations et atlas sont des détails internes de rendu ;
- changer une animation ou un atlas ne doit pas forcer à réécrire toutes les maps ;
- le runtime peut diagnostiquer proprement un preset manquant ;
- Surface Studio expose déjà des presets comme objets finaux.

## Ordre de rendu recommandé

Ordre runtime/editor V0 recommandé pour la passe background :

```text
TerrainLayer
SurfaceLayer
PathLayer legacy
TileLayer background
Entities background
TileLayer foreground
Entities foreground
Editor overlays / collision overlays
```

Justification :

- les surfaces comme eau/lave/glace doivent être au-dessus du terrain de fond ;
- elles doivent rester sous les tiles décoratives et personnages en V0 ;
- les `PathLayer` legacy restent visibles pendant la transition ;
- on évite de traiter les hautes herbes comme overlay joueur dès V0.

Limites assumées :

- hautes herbes : pas encore d’overlay devant le bas du joueur ;
- ponts : pas encore de règle de rendu spéciale ;
- surf/encounter : pas encore intégré ;
- surfaces au-dessus du joueur : hors scope V0.

## Impact JSON

Impact futur attendu :

- ajout d’un union case `surface` dans `MapLayer`;
- ajout de modèles de placement ;
- mise à jour generated Freezed/JSON via `build_runner`;
- tests de round-trip `MapData`;
- tests de rejection/validation des coordonnées invalides ;
- tests de compatibilité sur maps legacy sans `SurfaceLayer`.

Risque forward :

- anciens binaires ne liront pas `runtimeType: surface`.

Mitigation :

- ne pas convertir automatiquement les maps existantes ;
- garder `PathLayer` et `TerrainLayer` supportés ;
- documenter que les maps Surface nécessitent un binaire compatible ;
- prévoir des diagnostics avant migration legacy.

## Impact éditeur

Lots futurs nécessaires :

- palette Surface depuis `ProjectManifest.surfaceCatalog.presets`;
- sélection de `ProjectSurfacePreset`;
- création de `SurfaceLayer`;
- outil `surfacePaint`;
- paint / erase sparse ;
- preview statique ;
- preview animée ;
- diagnostics de placement :
  - preset manquant ;
  - preset sans rôle requis ;
  - animation manquante ;
  - atlas manquant ;
  - frame hors géométrie ;
  - placement hors map ;
  - doublon de coordonnée.

À éviter :

- réutiliser le mode `terrainPaint` pour Surface ;
- écrire dans `PathLayer` depuis la palette Surface ;
- faire dépendre le painter map de Surface Studio UI.

## Impact runtime

Lots futurs nécessaires :

- collecte des tilesets utilisés par les placements Surface ;
- `SurfaceResolver` pur ;
- `SurfaceAnimationClock` ou réutilisation contrôlée d’une primitive de timeline ;
- `SurfaceFrameResolver`;
- renderer Flame dédié ;
- culling caméra ;
- fallback visuel en cas de référence manquante ;
- tests runtime golden slice.

Le runtime doit lire :

```text
MapData.layers.whereType<SurfaceLayer>
ProjectManifest.surfaceCatalog
```

Puis résoudre :

```text
surfacePresetId
→ ProjectSurfacePreset
→ SurfaceVariantRole
→ animationId
→ ProjectSurfaceAnimation
→ SurfaceAnimationFrame
→ SurfaceAtlasTileRef
→ ProjectSurfaceAtlas
→ tileset image
```

## Impact migration legacy

Migration future possible :

```text
PathLayer water/lava/ice/tallGrass legacy
→ SurfaceLayer
→ placements sparse
→ surfacePresetId
```

Règles de migration à ne pas coder maintenant :

- ne migrer qu’après renderer Surface fiable ;
- migrer opt-in ou via outil explicite ;
- garder l’ancien `PathLayer` tant que l’utilisateur n’a pas validé ;
- créer d’abord les `ProjectSurfacePreset` équivalents dans `surfaceCatalog`;
- convertir chaque cellule `true` en placement sparse ;
- préserver l’ordre visuel autant que possible ;
- documenter les pertes possibles :
  - triggers path animation ;
  - properties legacy ;
  - comportements gameplay non portés.

## Roadmap Lots 82+

### Lot 82 — SurfaceLayer Model V0

Objectif : ajouter les modèles conceptuels dans `map_core`.

Périmètre :

- `SurfaceLayer` comme nouveau case `MapLayer.surface`;
- `SurfaceCellPlacement` minimal ;
- validations constructeur si le style choisi le permet.

Ne doit pas faire :

- pas de runtime ;
- pas d’éditeur ;
- pas de migration legacy ;
- pas de gameplay.

Tests attendus :

- construction ;
- immutabilité ;
- coordonnées invalides ;
- `surfacePresetId` vide ;
- absence de doublons si validé au modèle.

### Lot 83 — SurfaceLayer JSON Codec V0

Objectif : stabiliser la sérialisation.

Périmètre :

- generated Freezed/JSON ;
- round-trip `SurfaceLayer`;
- round-trip `MapData` avec et sans SurfaceLayer.

Ne doit pas faire :

- pas de renderer ;
- pas de Surface painter.

Tests attendus :

- JSON minimal ;
- placements triés ou ordre documenté ;
- champs inconnus caractérisés ;
- maps legacy toujours lisibles.

### Lot 84 — MapData SurfaceLayer Integration V0

Objectif : intégrer `SurfaceLayer` aux helpers de layer.

Périmètre :

- `MapLayerKind.surface` si retenu ;
- `addMapLayer`;
- `rename/remove/move/reorder/visibility/opacity`;
- `MapValidator`.

Ne doit pas faire :

- pas de peinture ;
- pas de resolver autotile.

Tests attendus :

- ajout/suppression ;
- validation coordonnées ;
- validation longueurs non applicable au sparse ;
- layer ids uniques.

### Lot 85 — Surface Placement Operations V0

Objectif : peindre/effacer des placements sparse en pur `map_core`.

Périmètre :

- paint single cell ;
- erase single cell ;
- paint pattern simple ;
- overwrite même coordonnée.

Ne doit pas faire :

- pas d’éditeur ;
- pas de runtime.

Tests attendus :

- paint ;
- erase ;
- hors map ;
- doublon évité ;
- ordre déterministe.

### Lot 86 — Surface Placement Diagnostics V0

Objectif : diagnostiquer une map Surface contre `ProjectSurfaceCatalog`.

Périmètre :

- preset manquant ;
- placement hors map ;
- doublon coordonnée ;
- preset sans rôle standard minimal ;
- animation/atlas manquants via diagnostics catalog existants.

Ne doit pas faire :

- pas de correction automatique.

Tests attendus :

- warnings/errors déterministes ;
- listes non mutables.

### Lot 87 — Surface Palette From Catalog V0

Objectif : exposer une palette Surface dans l’éditeur.

Périmètre :

- liste des `ProjectSurfacePreset`;
- sélection d’un preset ;
- état UI minimal.

Ne doit pas faire :

- pas de paint ;
- pas de preview animée.

Tests attendus :

- catalogue vide ;
- sélection ;
- preset supprimé du catalogue.

### Lot 88 — Surface Painter Shell V0

Objectif : ajouter un outil Surface sans peindre encore.

Périmètre :

- `EditorToolType.surfacePaint` ou équivalent ;
- compatibilité avec `SurfaceLayer`;
- messages d’état.

Ne doit pas faire :

- pas de rendu Surface final ;
- pas de runtime.

Tests attendus :

- outil compatible seulement SurfaceLayer ;
- active tool coercion.

### Lot 89 — Surface Paint / Erase V0

Objectif : brancher les opérations de paint/erase dans l’éditeur.

Périmètre :

- clic paint ;
- drag paint ;
- eraser ;
- save/reload map.

Ne doit pas faire :

- pas d’animation preview.

Tests attendus :

- paint sur map ;
- erase ;
- persistence map JSON ;
- no mutation hors layer ciblé.

### Lot 90 — Surface Neighbor Role Resolver V0

Objectif : créer le resolver pur `SurfaceVariantRole`.

Périmètre :

- voisins cardinaux ;
- diagonales pour coins intérieurs ;
- bords de map ;
- same `surfacePresetId` only.

Ne doit pas faire :

- pas de renderer.

Tests attendus :

- cellule isolée ;
- lignes ;
- coins ;
- T ;
- croix ;
- coins intérieurs ;
- bords de carte ;
- surfaces différentes adjacentes non connectées.

### Lot 91 — Surface Editor Static Preview V0

Objectif : afficher les placements Surface dans `MapGridPainter`.

Périmètre :

- résoudre preset/role/animation première frame ;
- fallback visuel ;
- rendu statique.

Ne doit pas faire :

- pas d’horloge runtime ;
- pas de gameplay.

Tests attendus :

- painter ne crashe pas ;
- preview avec preset valide ;
- fallback preset manquant.

### Lot 92 — Surface Editor Animated Preview V0

Objectif : animer les surfaces dans l’éditeur.

Périmètre :

- réutiliser timer existant ou clock dédiée ;
- loop global pour animations Surface.

Ne doit pas faire :

- pas de runtime Flame.

Tests attendus :

- frame change selon elapsed ;
- pas d’animation si une seule frame ;
- respects durations.

### Lot 93 — Runtime Surface Tileset Collection V0

Objectif : charger les tilesets nécessaires aux surfaces.

Périmètre :

- collecte via placements Surface ;
- résolution atlas -> tilesetId ;
- overrides futurs non concernés.

Ne doit pas faire :

- pas de rendu.

Tests attendus :

- tileset d’atlas collecté ;
- preset non utilisé non collecté ;
- missing atlas/preset documenté.

### Lot 94 — Runtime Surface Resolver V0

Objectif : résoudre les frames Surface côté runtime sans dessiner.

Périmètre :

- `SurfaceLayer` + catalog -> frame source ;
- rôle voisin ;
- timeline loop ;
- fallbacks.

Ne doit pas faire :

- pas de Flame renderer.

Tests attendus :

- résolution frame ;
- animation ;
- preset manquant ;
- role manquant.

### Lot 95 — Runtime Surface Renderer V0

Objectif : dessiner les surfaces dans Flame.

Périmètre :

- intégrer dans `MapLayersComponent` ou composant dédié ;
- drawImageRect no filtering ;
- ordre de rendu V0.

Ne doit pas faire :

- pas de gameplay surf/encounter.

Tests attendus :

- smoke renderer ;
- source rect ;
- ordre avec terrain/path/tile.

### Lot 96 — Water Surface Runtime Golden Slice V0

Objectif : prouver une eau animée placée dans une map.

Périmètre :

- projet fixture minimal ;
- surfaceCatalog ;
- SurfaceLayer sparse ;
- rendu animé.

Ne doit pas faire :

- pas de migration automatique ;
- pas de surf gameplay.

Tests attendus :

- full load ;
- tileset collection ;
- renderer frame stable ;
- animation progression.

### Lot 97 — Tall Grass Surface Placement Design V0

Objectif : décider le modèle spécifique hautes herbes.

Périmètre :

- overlay joueur ;
- local rustle ;
- encounter zones ;
- séparation visuel/gameplay.

Ne doit pas faire :

- pas de runtime final.

Tests attendus :

- rapport décision ;
- compatibilité avec SurfaceLayer V0.

## Fichiers créés

- `reports/surface/surface_engine_lot_81_surface_placement_model_decision.md`

## Fichiers modifiés

- Aucun fichier de code.
- Aucun fichier de test.
- Aucun JSON.
- Seul ce rapport est créé.

## Fichiers supprimés

- Aucun.

## Evidence Pack

### Fichiers lus / audités

Surface roadmap :

- `surface project/pokemap_surface_engine_spec.md`
- `surface project/pokemap_surface_engine_micro_lots.md`
- `reports/surface/surface_engine_lot_80_vertical_atlas_golden_slice.md`

Modèles core :

- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/models/map_layer.g.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/enums.dart`
- `packages/map_core/lib/src/models/surface.dart`
- `packages/map_core/lib/src/models/surface_catalog.dart`
- `packages/map_core/lib/map_core.dart`

Opérations core :

- `packages/map_core/lib/src/operations/map_layers.dart`
- `packages/map_core/lib/src/operations/map_paint.dart`
- `packages/map_core/lib/src/operations/map_terrain.dart`
- `packages/map_core/lib/src/operations/map_path.dart`
- `packages/map_core/lib/src/operations/map_terrain_autotile.dart`
- `packages/map_core/lib/src/operations/project_manifest_surface_catalog_operations.dart`
- `packages/map_core/lib/src/operations/project_surface_catalog_json_codec.dart`
- `packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart`
- `packages/map_core/lib/src/operations/surface_studio_read_model.dart`
- `packages/map_core/lib/src/io/legacy_editor_json_compat.dart`
- `packages/map_core/lib/src/validation/validators.dart`

Éditeur :

- `packages/map_editor/lib/src/application/services/terrain_painting_coordinator.dart`
- `packages/map_editor/lib/src/application/services/path_layer_editing_coordinator.dart`
- `packages/map_editor/lib/src/application/use_cases/terrain_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/path_layer_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/application/map_selection_controller.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generation_plan.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generator.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_preset_generator.dart`

Runtime :

- `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/application/runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart`
- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/runtime_path_autotile.dart`

### Commandes de lecture exécutées

- `pwd`
- `git branch --show-current`
- `git status --short --untracked-files=all`
- `git diff --stat`
- `git log --oneline -n 10`
- `rg --files ...`
- `rg -n ...`
- `find reports/surface ...`
- `sed -n ...`
- `nl -ba ...`

Tests non lancés : aucun test n’est requis parce que le lot est strictement documentaire et ne modifie aucun Dart.

Analyse statique non lancée : aucun fichier Dart n’est modifié.

## Git status final

Commandes Gate final exécutées :

```bash
git status --short --untracked-files=all
git diff --stat
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
```

Sortie `git status --short --untracked-files=all` :

```text
?? reports/surface/surface_engine_lot_81_surface_placement_model_decision.md
```

Sortie `git diff --stat` :

```text

```

Interprétation :

- le status initial était vide ;
- le status final contient uniquement le rapport autorisé du Lot 81 ;
- `git diff --stat` est vide parce qu’aucun fichier suivi n’a été modifié ;
- aucun fichier préexistant au Gate 0 n’a disparu.

## Changements préexistants

Aucun changement préexistant au Gate 0.

## Changements du Lot 81

- Création du rapport `reports/surface/surface_engine_lot_81_surface_placement_model_decision.md`.

## Périmètre explicitement non touché

Confirmé :

- `map_core` non modifié ;
- `map_editor` non modifié hors rapport ;
- `map_runtime` non modifié ;
- `map_gameplay` non modifié ;
- `map_battle` non modifié ;
- `ProjectManifest` non modifié ;
- generated files non modifiés ;
- `build_runner` non lancé ;
- aucun modèle `SurfaceLayer` créé ;
- aucun codec JSON créé ;
- aucun provider Surface créé ;
- aucun repository/service Surface créé ;
- aucun runtime renderer créé ;
- aucun painter map créé ;
- aucune migration legacy codée ;
- `Runner.xcscheme` non modifié par ce lot.

## Vérification fichiers temporaires

Sortie de la commande :

```bash
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
```

```text

```

Aucun fichier temporaire correspondant aux patterns demandés n’est présent.

## Vérification mojibake

Lecture visuelle du rapport : aucune mojibake détectée.

## Auto-review

- Est-ce que ce lot modifie du code ? Non.
- Est-ce qu’une décision claire est prise ? Oui : `SurfaceLayer` dédié.
- Est-ce que SurfaceLayer dédié est recommandé ou rejeté ? Recommandé.
- Est-ce que le stockage sparse vs grille complète est tranché ? Oui : sparse V0.
- Est-ce que la cellule Surface V0 est décrite ? Oui : `x`, `y`, `surfacePresetId`.
- Est-ce que l’autotile V0 est clarifié ? Oui : résolu depuis les voisins, non persisté.
- Est-ce que le référencement par surfacePresetId est clarifié ? Oui.
- Est-ce que l’ordre de rendu est discuté ? Oui.
- Est-ce que l’impact editor est décrit ? Oui.
- Est-ce que l’impact runtime est décrit ? Oui.
- Est-ce que la migration legacy est discutée ? Oui.
- Est-ce qu’une roadmap Lots 82+ est fournie ? Oui.
- Est-ce qu’un fichier présent au status initial a disparu du status final ? Non.
- Est-ce qu’un fichier hors périmètre a été modifié ? Non. Le seul fichier apparu est le rapport autorisé du Lot 81.
- Est-ce qu’un 81-bis est nécessaire ? Non. La décision est claire, le modèle conceptuel V0 est décrit et la roadmap suivante est exploitable.

## Critique du prompt

Le prompt est cohérent avec l’état du projet après Lot 80. La recommandation `SurfaceLayer` dédié est effectivement la plus probable, mais il était important de démontrer pourquoi `PathLayer` ne suffit pas.

Point discutable : demander une décision sur le placement avant tout test de prototype runtime implique une part d’anticipation. La mitigation proposée est de garder le V0 minimal : sparse placements + `surfacePresetId` + resolver non persistant. Cela limite le coût si le runtime impose des ajustements.

Autre point à surveiller : l’ajout d’un nouveau case `MapLayer.surface` cassera la lecture par anciens binaires. Le rapport recommande d’assumer ce coût, mais seulement après tests JSON et sans migration automatique.
