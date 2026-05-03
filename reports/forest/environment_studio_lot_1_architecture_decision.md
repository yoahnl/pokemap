# Environment Studio Lot 1 — Architecture Decision V0

## 1. Résumé exécutif

Ce lot audite le dépôt **sans modifier le code de production** et tranche une architecture **Environment Studio** : presets d’environnement réutilisables, **Environment Layer** sur les cartes, **Environment Areas** (zones + paramètres + traçabilité), et génération produisant des placements compatibles avec **`MapPlacedElement`** et les **`TileLayer`** existants.

**Décision principale retenue** : un workspace **Environment Studio** (sur le modèle Path Studio / Dialogue Studio), un **nouveau type de layer** dédié sur la carte pour porter les zones et la référence aux presets, une **Environment Area** comme unité de masque + paramètres + liste d’objets générés, et une génération qui produit **`MapPlacedElement`** avec marquage via `properties`, conjointement aux **patchs de tuiles** sur la **`TileLayer`** cible — aligné sur le rendu runtime et l’indexeur d’instances existants.

La **forêt dense** est traitée comme **premier preset / template**, pas comme nom du système.

---

## 2. Périmètre du lot

- **Inclus** : audit du code listé, comparaison des options A–J, décisions structurantes, modèle conceptuel (sans code Dart), UX cible, frontière V0, roadmap indicative, risques.
- **Exclu** : ajout ou modification de modèles, JSON, Freezed, UI, générateur, runtime, `ProjectManifest`, `MapData`, `MapLayer`, tests, `build_runner`, tout fichier generated.

**Livrable unique** : ce fichier sous `reports/forest/environment_studio_lot_1_architecture_decision.md`.

---

## 3. Vision produit validée

La vision suivante est **compatible** avec l’architecture existante si l’on sépare clairement :

| Concept | Rôle |
|--------|------|
| **Environment Studio** | Création et gestion des **presets** (recettes, palettes pondérées, paramètres par défaut). |
| **Environment Preset** | Document projet (futur) référencé par `presetId`. |
| **Environment Layer** | Layer de carte listé avec les autres layers ; porte les **areas** et l’état de travail. |
| **Environment Area** | Zone sur la carte + `presetId` + graine + overrides + **ids des placements générés**. |
| **Objets générés** | Instances réelles sur la carte (`MapPlacedElement` + tuiles associées), traçables et purgeables sans toucher le manuel. |

---

## 4. Fichiers inspectés

Liste **minimale demandée** ; lecture effective par extraits ou fichier complet selon le besoin de preuve.

| Fichier | Inspection |
|---------|------------|
| `packages/map_core/lib/src/models/map_data.dart` | Lu : `MapData` avec `layers`, `placedElements`, `gameplayZones`, `properties`. |
| `packages/map_core/lib/src/models/map_layer.dart` | Lu : unions `TileLayer`, `CollisionLayer`, `TerrainLayer`, `PathLayer`, `SurfaceLayer`, `ObjectLayer`. |
| `packages/map_core/lib/src/models/project_manifest.dart` | Lu (entête) : listes `elements`, `terrainPresets`, `pathPresets`, `pathPatternPresets`, `surfaceCatalog`, etc. |
| `packages/map_core/lib/src/models/tileset.dart` | Lu : `TilesetConfig` / `TileProperties` (config legacy simple). |
| `packages/map_core/lib/src/models/element_collision_profile.dart` | Lu : `ElementCollisionProfile` avec `cells`, masques, champs runtime vs authoring. |
| `packages/map_core/lib/src/operations/map_layers.dart` | Lu : `addMapLayer` (switch sur `MapLayerKind`), `removeMapLayer` supprime aussi les `placedElements` du `layerId`. |
| `packages/map_core/lib/src/operations/map_placed_elements.dart` | Lu : `upsertMapPlacedElement`, `removeMapPlacedElement`, `replaceMapPlacedElementsForLayer`, etc. |
| `packages/map_core/lib/src/operations/map_paint.dart` | Lu : `paintTileOnLayer` / `paintTilePatternOnLayer` sur `TileLayer` uniquement. |
| `packages/map_core/lib/src/operations/map_collision.dart` | Lu : peinture sur `CollisionLayer`. |
| `packages/map_core/lib/src/operations/path_pattern_visual_resolution.dart` | Lu : résolution visuelle **PathPattern** (`resolvePathPatternVisual`), sans lien direct Environment. |
| `packages/map_editor/lib/src/features/editor/state/editor_state.dart` | Lu : `EditorWorkspaceMode`, `activeLayerId`, sélections carte. |
| `packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart` | Lu : enum incluant `pathStudio`, narratif, `map`, etc. |
| `packages/map_editor/lib/src/ui/editor_shell_page.dart` | Lu : `supportsRightInspector` faux pour `pathStudio` et `pokedex`. |
| `packages/map_editor/lib/src/ui/panels/layers_panel.dart` | Non relu en entier dans ce lot ; patterns connus via `map_layers` et usages établis (création de layers). |
| `packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart` | Non relu en entier ; volumineux ; rôle connu : instances placées, collisions. |
| `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart` | Lu : `switch (workspaceMode)` → `MapCanvas`, `PathStudioWorkspace`, etc. |
| `packages/map_editor/lib/src/ui/canvas/map_canvas.dart` | Non relu en entier ; partiellement via `map_grid_painter` dans audits antérieurs — painter tuiles / paths. |
| `packages/map_editor/lib/src/ui/canvas/map_canvas/map_canvas_assets.dart` | Non ouvert dans ce lot. |
| `packages/map_editor/lib/src/application/services/placed_element_instance_indexer.dart` | Lu (segment clé) : sync tuiles → instances par `TileLayer` + tileset. |
| `packages/map_editor/lib/src/application/services/element_collision_authoring_service.dart` | Non ouvert dans ce lot. |
| `packages/map_editor/lib/src/application/services/element_collision_profile_generator.dart` | Non ouvert dans ce lot. |
| `packages/map_editor/lib/src/application/collision_generation/` | Non parcouru fichier par fichier dans ce lot. |
| `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/` | Non ouvert dans ce lot. |
| `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/collision/` | Non ouvert dans ce lot. |
| `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart` | Lu (entête + `PathStudioWorkspace`) : sauvegarde manifest via `applyInMemoryProjectManifest`. |
| `packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace.dart` | Non ouvert ; référencé par `EditorCanvasHost`. |
| `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` | Non ouvert ; référencé par `EditorCanvasHost`. |
| `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart` | Audit antérieur session : rendu `TileLayer` cellule par cellule ; `placedElements` pour masques animés / foreground. |
| `packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart` | Lu : occlusion par **instance** `MapPlacedElement` + `ProjectElementEntry`. |

**Fichiers additionnels utiles à la décision** :

| Fichier | Inspection |
|---------|------------|
| `packages/map_core/lib/src/models/enums.dart` | Lu : `MapLayerKind` — valeurs `tile`, `collision`, `terrain`, `path`, `object` uniquement. |
| `packages/map_editor/lib/src/ui/shared/top_toolbar.dart` | Lu : entrées de workspace dont `pathStudio` → libellé « Path Studio ». |
| `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart` | Lu (entête) : arbre World / tilesets / sections terrains & paths. |

**Inconnu / non tranché dans ce lot** :

- Contenu exact de `element_collision_authoring_service`, `collision_generation/`, widgets collision : **raison** — hors décision structurelle V0 ; **fichiers à auditer** — au lot implémentation collision fine ; **impact** — finesse des garde-fous « ne pas générer sur collision existante ».
- `map_canvas_assets.dart` : **raison** — non ouvert ; **impact** — chargement textures pour preview Environment sur canvas.

---

## 5. État actuel du code pertinent

### 5.1 Données carte

- **`MapData`** (`map_data.dart`) : `List<MapLayer> layers`, `List<MapPlacedElement> placedElements`, extensible via `properties` au niveau carte.
- **`MapPlacedElement`** : `id`, `layerId`, `elementId`, `GridPos pos`, `applyCollision`, `behaviors`, **`Map<String, String> properties`** — convient au **taggage** des objets générés sans nouveau champ obligatoire immédiat.
- **`MapLayer`** (`map_layer.dart`) : `ObjectLayer` = métadonnées seules (**pas** de grille ni liste d’objets). Les zones Environment **ne peuvent pas** vivre dans `ObjectLayer` tel quel.

### 5.2 Opérations placement

- **`map_placed_elements.dart`** : manipulation par **instance** ; `replaceMapPlacedElementsForLayer` remplace toutes les instances d’un `layerId` ; suppression ciblée par `removeMapPlacedElement`.
- **`buildMapPlacedElementId`** (même fichier) : identifiant dérivé de `layerId`, `pos.x`, `pos.y` — **une position + layer définit un id canonique** ; un **upsert** régénère au même endroit sans multiplier les ids.

### 5.3 Layers

- **`addMapLayer`** (`map_layers.dart`) : pattern **switch exhaustif** sur `MapLayerKind` ; tout nouveau type impose **nouveau kind + factory `MapLayer.*` + branches**.
- **`removeMapLayer`** : supprime **toutes** les instances `placedElements` dont `layerId` correspond — à prendre en compte si la **TileLayer décor** est le même id qu’un layer « logique » Environment (risque de couplage).

### 5.4 Rendu runtime (synthèse audit)

- **`MapLayersComponent`** : peinture **par scan des cellules** des `TileLayer` ; cas spéciaux pour animations et cellules « foreground » liées aux elements multi-cellules ; **priorité / Y-sort** fines pour joueur via autres composants (`PlacedElementOcclusionPatchComponent` utilise `MapPlacedElement` + bas du sprite en pixels).

### 5.5 Éditeur — workspaces

- **`EditorWorkspaceMode`** inclut déjà **`pathStudio`** (`editor_workspace_mode.dart`).
- **`EditorCanvasHost`** (`editor_canvas_host.dart`) : route le centre selon le mode ; **`PathStudioWorkspace`** est l’analogie directe pour **Environment Studio**.
- **`EditorShellPage`** : désactive l’inspecteur droit pour certains modes (`pathStudio`, `pokedex`) — pattern réutilisable pour un mode Environment si besoin de stage plein écran.

### 5.6 Manifest projet

- **`ProjectManifest`** (`project_manifest.dart`) : agrège déjà **presets** (`terrainPresets`, `pathPresets`, `pathPatternPresets`) et **`elements`** — **modèle d’extension naturel** pour une liste `environmentPresets` ou équivalent **dans un lot futur** (hors périmètre Lot 1).

### 5.7 Indexeur instances placées

- **`PlacedElementInstanceIndexer.syncLayer`** (`placed_element_instance_indexer.dart`) : reconstruit des **`MapPlacedElement`** à partir des **tuiles** d’une `TileLayer` et du **tileset** du layer — preuve que **tuiles + instances** sont couplées dans le flux éditeur actuel.

---

## 6. Options d’architecture étudiées

| Option | Description courte | Avantages | Limites | Complexité | Compatibilité code actuel | No-code | Dette | Recommandation |
|--------|-------------------|-----------|---------|------------|---------------------------|---------|-------|----------------|
| **A** ForestGenerator only | Outil spécifique forêt | Rapide à prototyper | Ne scale pas aux autres biomes | Faible | Moyenne | Faible | Refonte probable | **Éviter** comme cœur système |
| **B** Environment Studio générique + preset « Forêt dense » | Presets extensibles | Aligné produit | Plus de conception initiale | Moyenne | Bonne | Élevée | Faible si modèle stable | **Retenir** |
| **C** Nouveau type dans `MapLayer` | `environment` union | Zones co-localisées avec la carte ; ordre Z avec autres layers | Refonte schéma + sérialisation | Moyenne–Élevée | Nécessite extension `MapLayer` / `MapLayerKind` | Bon | Maîtrisée si lot dédié | **Retenir V0** (objectif) |
| **D** Areas hors layers (`MapData.properties` ou side-car) | Zones uniquement dans carte | Moins toucher `MapLayer` | UX Layers confuse ; ordre rendu flou | Moyenne | Possible via `properties` | Moyenne | Risque de patch JSON opaque | **Plus tard ou complément** |
| **E** Générer uniquement `MapPlacedElement` | Pas de tuiles | Simple liste | **Runtime/éditeur** dépendent fortement des **tuiles** sur `TileLayer` pour le rendu statique multi-cellules ; indexer part des tuiles | Faible | **Incomplète** avec rendu actuel | Moyenne | Élevée si seule | **Rejeter seule** |
| **F** TileLayer patch + `MapPlacedElement` | Tuiles + instances | Cohérent avec `paintTilePatternOnLayer`, indexer, runtime | Deux surfaces à mettre à jour atomiquement | Moyenne | **Très bonne** | Bonne | Faible si transaction map unifiée | **Retenir V0** |
| **G** `ObjectLayer` seul | Stocker Environment dedans | Aucun | **`ObjectLayer` sans payload** (`map_layer.dart`) | — | **Non viable** | — | — | **Éviter** |
| **H** PathLayer / PathPattern pour templates futurs | Réutiliser chemins | Autotile puissant pour routes / rivières | Sémantique différente (path ≠ biome) ; `path_pattern_visual_resolution.dart` est **PathPattern** uniquement | Variable | Possible en **complément** futur | Bon pour certains cas | Confusion si mélangé trop tôt | **Plus tard (templates spécifiques)** |
| **I** Un layer par objet généré | Isolation | Aucun | **Explosion** de layers ; `removeMapLayer` purge tout un layer — mauvais fit | Très élevée | Contre `addMapLayer` usage | Très faible | Très élevée | **Rejeter** |
| **J** Composite Preset + Layer + Area + generated | Système complet | Couvre produit | Implémentation par phases | Élevée cumulée | Bonne si phases respectées | Très bonne | Faible si discipliné | **Retenir comme north star** |

---

## 7. Décisions structurantes

1. **Environment Studio** : **workspace dédié** (comme Path Studio), pas un simple sous-panneau dans World Maps.
2. **Environment Layer** : **nouveau type de layer** dans `MapLayer` / `MapLayerKind` (**lot code futur** — ici décision seulement).
3. **Environment Area** : **stockée dans le Environment Layer** (liste structurée dans le layer), pas dispersée uniquement dans `MapData.properties`.
4. **Generate** : produit **`MapPlacedElement`** **et** **mise à jour des tuiles** de la **`TileLayer`** de référence (patch), avec **`properties`** normalisées pour traçabilité.
5. **Manuel vs généré** : tout placement généré porte des **clés `properties`** préfixées / convention stable ; **Clear** agit **uniquement** sur les ids enregistrés dans l’Area ; les autres instances / tuiles **non taguées** ne sont pas effacées.
6. **Freeze** : opération **produit** « promouvoir en manuel » = retirer les tags générateur des instances concernées + retirer les ids de l’Area (détails lot UX).
7. **Surface Engine legacy** : **hors architecture principale** ; pas de dépendance pour Environment (section 20).

---

## 8. Environment Studio comme workspace de presets

**Décision §8.1 : Oui** — workspace séparé.

**Justification code** :

- `EditorCanvasHost` (`editor_canvas_host.dart`) route déjà `EditorWorkspaceMode.pathStudio` vers `PathStudioWorkspace`.
- `EditorWorkspaceMode` (`editor_workspace_mode.dart`) est l’extension naturelle pour **`environmentStudio`** (nom indicatif).
- `top_toolbar.dart` ajoute des boutons de mode ; un libellé du type « Environment Studio » suit le pattern « Path Studio ».

**V0 contenu suggéré** :

- Liste de presets du projet (lecture manifest futur) ; création / édition minimaliste d’un preset : nom, **palette** (références `ProjectElementEntry.id`), **poids**, **paramètres par défaut** (densité, graine par défaut, flags collision par catégorie).
- Pas encore : simulation écologique, multi-biomes chainés, preview 3D.

**Ne contient pas V0** : génération sur carte (reste dans World Maps avec layer actif).

---

## 9. Environment Layer comme nouveau type de layer de map

**Décision §8.2 : Oui** (implémentation dans un lot schéma séparé).

**Intégration** :

- Nouvelle variante **`MapLayer.environment`** (nom final à figer en Lot 2) avec au minimum : `id`, `name`, visibilité, **`List<EnvironmentArea>`** (conceptuel), **référence optionnelle** vers **`TileLayer`** cible pour les placements (ID de layer décor).
- `MapLayerKind` (`enums.dart`) : nouvelle valeur pour `addMapLayer` (`map_layers.dart`).

**Panneau Layers** : même liste que les autres — **ording** entre environment et tile à définir (souvent environment « meta » au-dessus ou sous terrain selon produit).

**Panneau droit en mode map** : lorsque `activeLayerId` pointe sur un Environment Layer, afficher **Environment** (preset, zone, params, actions) — même logique conditionnelle que les autres outils par layer.

---

## 10. Environment Area comme zone dessinée dans le layer

**Décision §8.3 : Oui** — l’area vit **dans** le Environment Layer.

**Forme V0 recommandée** : **masque booléen** ou liste de **cellules / rectangle aligné grille** — même primitives que `PathLayer.cells` (`map_layer.dart` : `List<bool> cells`) pour la familiarité code ; extension polygon **plus tard**.

**Données minimales (conceptuel)** :

- `id`, `name` optionnel
- `presetId`
- `seed` (entier ou string stable)
- `params` (overrides)
- `generatedInstanceIds` **ou** équivalent pour purge ciblée
- statut : `draft` | `generated` | `frozen` (optionnel V0 ; peut être dérivé des tags sur instances)

---

## 11. Génération et traçabilité des objets générés

**Décision §8.4 : Oui** — **`MapPlacedElement`** est le véhicule principal des objets générés.

**Pourquoi** : déjà sérialisé dans `MapData` ; `upsertMapPlacedElement` / `removeMapPlacedElement` ; runtime et occlusion déjà branchés sur **`MapPlacedElement`**.

**Traçage** : utiliser **`MapPlacedElement.properties`** (clés/valeurs **string**, `map_data.dart`) avec convention du type :

- `environment.areaId` = identifiant d’area ;
- `environment.presetId` = preset ;
- `environment.generator` = version du moteur ;
- `environment.generated` = `1` ou `true` équivalent string.

**Clear** : supprimer les instances dont id ∈ `generatedInstanceIds` **et** `environment.generated` présent ; effacer les **tuiles** correspondantes sur la `TileLayer` cible pour les cellules couvertes (sinon fantômes visuels).

**Regenerate** : même area + nouvelle seed → supprimer **uniquement** le lot tagué, régénérer.

**Manuel** : absence de tags → jamais supprimé par Clear de l’area.

**Idempotence** : `buildMapPlacedElementId` (`map_placed_elements.dart`) ancre id à `(layerId, x, y)` — une regen au même slot **remplace** l’instance si upsert cohérent.

---

## 12. Stratégie de rendu V0

**Décision §8.5** : **oui**, les **patchs de `TileLayer`** sont **nécessaires** pour un rendu aligné éditeur/runtime pour les **éléments multi-tuiles statiques**, car :

- `MapLayersComponent` peint les **`TileLayer`** cellule par cellule (session d’audit).
- **`PlacedElementInstanceIndexer`** déduit les instances **depuis les tuiles** (`placed_element_instance_indexer.dart`).

**V0 pragmatique** : **Option F** — **`paintTilePatternOnLayer`** (`map_paint.dart`) pour appliquer les tuiles + **`upsertMapPlacedElement`** pour métadonnées / collision / tags.

**Fallback** si un jour rendu « instances seules » : évolution runtime — **hors Lot 1**.

---

## 13. Stratégie de collision V0

- Réutiliser **`ElementCollisionProfile`** sur chaque **`ProjectElementEntry`** (`element_collision_profile.dart`) — `cells` consommés runtime.
- Respecter **`applyCollision`** sur `MapPlacedElement` pour les cas « décor pur ».
- Garde-fou éditeur : avant placement aléatoire, tester chevauchement avec **collision layer** et instances existantes — détail algo **Lot collision**.

---

## 14. Stratégie de persistance V0 / V1

| Élément | V0 | V1 |
|---------|----|----|
| Presets Environment | **À ajouter au manifest** (`ProjectManifest`) — lot schéma dédié | Catégories, migration, bibliothèques partagées |
| Environment Layer | **Nouveau type `MapLayer`** + JSON | Évolution backwards-compatible |
| Areas | **Dans le layer** | Polygones, scripts |
| Tags génération | **`properties` sur instances** | Champs typés optionnels sur `MapPlacedElement` si friction |

---

## 15. UX cible

### 15.1 Création de preset (Environment Studio)

1. Ouvrir **Environment Studio** depuis la barre / sélecteur de workspace (comme Path Studio).
2. Créer un preset « Forêt dense de Selbrume ».
3. Choisir des **éléments projet** existants (arbres, buissons).
4. Définir des **poids** (grand arbre 5, etc.).
5. Définir **paramètres par défaut** (densité, irrégularité, bords).
6. **Enregistrer** le projet (manifest).

### 15.2 Utilisation sur une map

1. **World Maps** → ouvrir une carte.
2. **Ajouter un layer Environment**.
3. Sélectionner ce layer.
4. Panneau droit : **preset**, **dessin de zone**, **seed / sliders**.
5. **Generate** → résultat visible sur la carte.
6. **Shuffle** → nouvelle seed ou régénération.
7. **Clear generated** → retire uniquement le cycle généré pour l’area active.
8. **Freeze** → le décor devient « posé à la main » (tags retirés).

Vocabulaire utilisateur : éviter « TileLayer » ; parler de **calque décor**, **objets posés**, **zone nature**.

---

## 16. Modèle conceptuel recommandé

| Nom | Recommandation |
|-----|----------------|
| `EnvironmentPreset` | **Oui** — document projet. |
| `EnvironmentPresetCatalog` ou catégories | **Plus tard** |
| `EnvironmentRecipe` | **Optionnel** — alias logique du preset ou sous-objet « règles » |
| `EnvironmentPalette` | **Oui** — liste `{ elementId, weight, tags }` |
| `EnvironmentPaletteItem` | **Oui** |
| `EnvironmentGenerationParams` | **Oui** — densité, edge bias, etc. |
| `EnvironmentLayer` | **Oui** — type de layer |
| `EnvironmentArea` | **Oui** |
| `EnvironmentAreaMask` | **Oui** — booléens ou RLE plus tard |
| `EnvironmentGenerationResult` | **Optionnel** — retour outil pur |
| `EnvironmentGeneratedPlacement` | **Optionnel** — si séparation stricte avant map write |
| `EnvironmentGeneratedTilePatch` | **Utile** en interne pour atomicité |

Éviter comme **noms de domaine** : `ForestPreset`, `ForestArea` — réservés à **templates** ou **exemples**.

---

## 17. Frontière V0

**Inclure** :

- Concepts Preset / Layer / Area.
- Template « **Forêt dense** » comme preset exemple.
- Générateur déterministe minimal (graine + tirages pondérés + espacement).
- **Generate**, **Clear generated**, **seed**, traçabilité `properties`.

**Exclure** (confirmé) :

- Clairières intelligentes, chemins internes, gameplay zones, rencontres, IA généérative, biomes multi-cartes, rendu runtime dédié complexe.

---

## 18. Risques et inconnues

1. **Double écriture tuiles + instances** : risque d’états incohérents si une branche échoue — mitigation : opération map atomique côté notifier (lot implémentation).
2. **`removeMapLayer`** supprime toutes les instances du `layerId` — ne pas utiliser le même id pour **Environment meta layer** et **TileLayer décor** sans distinction claire.
3. **IDs placés** dérivés position : deux générations distinctes sur la même case du même layer décor **écrasent** — acceptable si Clear avant regen.
4. **Surface / anciens systèmes** : non utilisés pour la décision (section 20).

---

## 19. Roadmap recommandée Environment-2 à Environment-12

| Lot | Sujet indicatif |
|-----|-----------------|
| **Environment-2** | Schéma `MapLayer` + `MapLayerKind` + sérialisation + validation |
| **Environment-3** | Schéma `EnvironmentPreset` dans manifest + CRUD projet |
| **Environment-4** | Workspace UI Environment Studio (lecture/édition presets) |
| **Environment-5** | Environment Layer dans Layers panel + création |
| **Environment-6** | Environment inspector (droite) + dessin de zone V0 |
| **Environment-7** | Opération `map_core` : generate deterministic + patch tuiles + instances |
| **Environment-8** | Clear / Regenerate / Freeze + tests map_core |
| **Environment-9** | Intégration indexer / collision guards éditeur |
| **Environment-10** | Preview canvas & polish UX |
| **Environment-11** | Runtime — vérification passive (pas de passe spéciale si tuiles OK) |
| **Environment-12** | Templates additionnels (haie, bord de chemin) + polish |

(La numérotation est indicative ; certains lots peuvent fusionner.)

---

## 20. Non-objectifs confirmés

- Pas d’architecture fondée sur un **legacy surface** à retirer — `surfaceCatalog` dans `ProjectManifest` existe pour les surfaces **carte** ; **Environment** est orthogonal.
- Pas de générateur « forêt seule » comme socle unique (Option A rejetée comme cœur).

---

## 21. Commandes exécutées

```text
cd /Users/karim/Project/pokemonProject && git status --short --untracked-files=all
(sortie vide : arbre de travail propre au moment de l’audit)

cd /Users/karim/Project/pokemonProject && git status
→ On branch main, ahead of origin/main by 96 commits, nothing to commit, working tree clean

cd /Users/karim/Project/pokemonProject && ls -la reports/forest
→ No such file or directory (avant création du rapport)
```

**Note** : au démarrage de la conversation utilisateur, un `git status` pouvait montrer des fichiers modifiés ; **au moment de l’exécution de ce lot**, le dépôt était **clean**. Le delta est documenté en §22.

---

## 22. Git status initial et final

**État initial (exécution lot)** :

```text
On branch main
Your branch is ahead of 'origin/main' by 96 commits.
nothing to commit, working tree clean
```

**État final attendu après ajout du seul rapport** :

```text
?? reports/forest/environment_studio_lot_1_architecture_decision.md
```
(ou `A` si le dossier est tracké différemment selon configuration git ; fichier non tracké typique.)

**Différences préexistantes vs ce lot** : aucune modification préexistante détectée au moment des commandes ; seule addition du fichier sous `reports/forest/`.

---

## 23. Auto-review

**Points solides** :

- Distinction **Studio / Layer / Area / placement** alignée sur `MapData`, `MapLayer`, `MapPlacedElement`.
- Option **tuiles + instances** étayée par `map_paint.dart`, `map_layers_component` (audit), `PlacedElementInstanceIndexer`.
- Rejet factuel d’**ObjectLayer** comme stockage (`map_layer.dart`).
- Surface legacy **explicitement** hors chemin principal.

**Points incertains** :

- Collision « ne pas chevaucher un bâtiment » sans lire `element_collision_authoring_service` — **Lot Environment-9**.
- Ordre Z parfait entre grands arbres — limites runtime documentées dans `PlacedElementOcclusionPatchComponent` ; **pas résolu V0**.

**À auditer au prochain lot** :

- `layers_panel.dart` / `addMapLayer` UI pour insertion exacte du nouveau kind.
- `map_canvas.dart` outils de peinture pour réutiliser la boucle hit-test.

---

## 24. Verdict

Décision Environment Studio V0 :

- [ ] ForestGenerator spécifique
- [ ] Layer par objet généré
- [ ] ObjectLayer direct uniquement
- [ ] MapPlacedElement uniquement sans Environment Layer
- [ ] TileLayer généré + MapPlacedElement associés uniquement
- [x] Environment Studio workspace + Environment Layer + Environment Area + generated MapPlacedElement
- [ ] autre : …

Recommandation principale retenue :

```text
Environment Studio (workspace dédié) + Environment Presets au manifest (lot schéma ultérieur) + nouveau Environment Layer sur la carte portant des Environment Areas + génération produisant MapPlacedElement tagués et patch de TileLayer associé — premier template « Forêt dense ».
```

Raison courte :

```text
Le code actuel lie fortement TileLayer et MapPlacedElement pour le décor multi-tuiles ; ObjectLayer ne stocke pas de données ; les opérations map_core existantes permettent placement et purge ciblée sans multiplier les layers.
```

Premier preset/template recommandé :

```text
Forêt dense (palette arbres + sous-bois + contrôle densité/seed).
```

Prochain lot recommandé :

```text
Environment-2 — Extension schéma MapLayer / MapLayerKind / JSON + validation pour Environment Layer et Areas (sans générateur ni UI carte).
```

---

## Evidence Pack (checklist)

- **git status initial** : arbre propre au moment des commandes (§21–22).
- **git status final** : fichier rapport non tracké sous `reports/forest/` attendu.
- **Fichiers inspectés** : §4 liste complète avec statut lecture.
- **Décision finale** : §24.
- **Roadmap** : §19.
- **Aucun code de production modifié** : seul ajout du rapport Markdown autorisé par le lot.
- **Aucun fichier generated modifié** : confirmé.
- **Aucun test ajouté ou modifié** : confirmé.
- **Seul fichier créé/modifié par ce lot** : `reports/forest/environment_studio_lot_1_architecture_decision.md` (dossier `reports/forest/` créé si absent).
