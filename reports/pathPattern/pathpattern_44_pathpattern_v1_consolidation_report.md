# PathPattern V1 — Rapport de consolidation (Lot PathPattern-44)

## 1. Résumé exécutif

**PathPattern V1** est le socle PokeMap pour associer un **preset de path de base** (`ProjectPathPreset`) à un **motif de centre local** (`PathCenterPattern`) via un **`ProjectPathPatternPreset`**, sérialisé dans le manifest (`pathPatternPresets`) et le fichier **`project.json`**.

Le cas prioritaire documenté et couvert par tests est **l’eau animée center-only 2×2** (style *deep_water*) : centre multi-cellules, frames multi-sources, animation pilotée par le temps (`elapsedMs`), variants legacy partiels ou absents avec **repli sur le centre**, et **cross** toujours résolu par le **centerPattern**.

**Path Studio** (éditeur `map_editor`) permet la **création** d’un nouveau chemin, l’**édition** d’un PathPattern existant, les **diagnostics** (manifest + assets/bounds), l’**assistant de séquence** d’animation, l’**annulation** des brouillons, l’**application en mémoire** au manifest, puis la **sauvegarde disque** du projet. Le **dirty state** (`isProjectDirty`) distingue explicitement « mémoire » et **`project.json`**.

Le **rendu éditeur** et le **rendu runtime** réutilisent la même politique de résolution (`resolvePathPatternVisual` côté cœur, enveloppes éditeur/runtime), avec **golden slices** pour l’eau 2×2 animée.

Ce document fige la **vérité V1** pour reprise humaine ou agent : périmètre, glossaire, flux, fichiers, tests, limites, historique des lots **27 → 44**.

---

## 2. Périmètre V1

### Inclus

- `PathCenterPattern` **1×1** et **2×2** (tailles valides côté contrat).
- Mode **center-only** : le rendu répète le motif de centre sur la tuile path (pas de frames legacy par variante requises pour l’affichage du centre).
- **Variants legacy partiels** : certaines directions ont encore des frames dans le `ProjectPathPreset` de base ; les manques se comportent comme indiqué par les diagnostics / repli center.
- **Centre animé** : plusieurs `TilesetVisualFrame` par cellule, `durationMs`, sélection de frame par temps.
- **Assistant « Générer une séquence »** : remplissage géométrique des frames (ex. pas 3×0 pour *deep_water*).
- **Création** « Nouveau chemin », **édition** « Modifier », **annulation / revert** avec confirmation si brouillon dirty.
- **Apply mémoire** : mutation du `ProjectManifest` en RAM, **sans** écrire `project.json`.
- **Save Project** : écriture `project.json` (et remise à plat de `isProjectDirty` si succès).
- **Dirty project** : signal UI + tests de non-régression navigation (`openMapDocument`).
- **Diagnostics manifest** : intégrité base, unicité, tuilesets, variants, ambiguïté multi-PathPattern, stats centre.
- **Diagnostics asset/bounds** : fichier image, décodage, rect source hors atlas, taille frame ≠ 1×1 pour aperçu V0, validation indisponible.
- **Rendu éditeur** : `MapGridPainter` + `resolvePathPatternEditorRenderResolution`.
- **Rendu runtime** : `MapLayersComponent` + `resolvePathPatternRuntimeRenderResolution`.
- **JSON roundtrip** : `project_manifest_path_pattern_save_reload_test.dart` + golden manifest animé 2×2.
- **Golden slice eau animée** : tests `map_core`, `map_editor`, `map_runtime` listés en §14.

### Exclu (hors scope V1 / non promis par ce rapport)

- Tall Grass, Surface Studio, système générique de surfaces.
- TSX / TMX, import automatique d’animations depuis atlas externe.
- Génération automatique de bords, coins, jonctions path.
- Animation des **variants legacy** via l’assistant (l’assistant cible le **centerPattern**).
- Validation asset **temps réel** sur le brouillon actif (le read model / carte peut signaler `assetValidationUnavailable` sans carte d’images).
- Cache async avancé des infos image (hors chargement synchrone actuel).
- Gameplay zones, combat, runtime hors rendu path.

---

## 3. Glossaire

| Terme | Définition |
|--------|--------------|
| **ProjectPathPreset** | Preset de path « classique » dans le manifest : autotile, **variants** (`TerrainPathVariant` → frames legacy). Identifié par `id`. |
| **ProjectPathPatternPreset** | Extension **par base** : pour un `basePathPresetId` donné, définit un **`PathCenterPattern`** (grille locale de cellules, chacune avec des `TilesetVisualFrame`). Optionnellement `transparentColor`, métadonnées d’édition. |
| **PathCenterPattern** | Grille locale (ex. 2×2) de **`PathCenterPatternCell`**, chacune avec une liste non vide de **frames** (sources tuile + durée). |
| **TilesetVisualFrame** | Référence visuelle : `tilesetId`, rectangle source dans l’image tuile, `durationMs`, etc. |
| **`TerrainPathVariant.cross`** | Variante « croisement » du path legacy ; **en PathPattern V1 le rendu visuel cross utilise le centerPattern** (voir `resolvePathPatternVisual` : branche legacy ignorée pour `cross`). |
| **center-only** | Le preset de base n’a **pas** de frames legacy pour une variante donnée ; le rendu PathPattern utilise **uniquement** le centre pour cette tuile (diagnostic `centerOnly` possible selon configuration). |
| **variants partiels** | Le base path a des variantes legacy **incomplètes** ; le moteur peut encore s’appuyer sur le centre ; diagnostic **`partialVariantCoverage`** (warning typique). |
| **basePathPresetId** | Lien **`ProjectPathPatternPreset` → `ProjectPathPreset.id`** (une base, au plus un PathPattern actif par base en V1 « sain » ; plusieurs → ambiguïté / fallback). |
| **Apply (mémoire)** | Action Path Studio / shell : applique un `ProjectPathPatternPreset` (ou remplacement édition) au **`ProjectManifest` en mémoire** via callback / notifier — **ne persiste pas** le JSON. |
| **Save Project** | Action barre d’outils : écrit le manifest sur disque (**`project.json`**). |
| **`isProjectDirty`** | Flag **`EditorState`** : `true` après mutation manifeste en mémoire non sauvegardée ; `false` après chargement / session propre / sauvegarde réussie. |

---

## 4. Architecture globale

### Rôles par package

| Package | Rôle PathPattern |
|---------|------------------|
| **map_core** | Modèles purs (`PathCenterPattern`, `ProjectPathPatternPreset`, …), **JSON** (`project_path_pattern_preset_json_codec`), **`resolvePathPatternVisual`**, **`resolvePathCenterPatternCell`**, tests de roundtrip et résolution. |
| **map_editor** | **Path Studio** : brouillon (`path_studio_new_path_draft.dart`), UI (`path_studio_panel.dart` + `part`), plans (`path_studio_save_plan.dart`), flux (`path_studio_save_flow.dart`), build requests, **read model** + diagnostics manifest + asset, **résolution rendu éditeur** (`path_pattern_editor_render_resolution.dart`), peinture (`map_grid_painter.dart`). |
| **map_runtime** | **Résolution rendu runtime** (`path_pattern_runtime_render_resolution.dart`), intégration **Flame** (`map_layers_component.dart`). |

### Chaîne mentale (création → affichage)

```text
Path Studio (draft UI)
  → build request / save plan (map_editor)
  → ProjectPathPatternPreset (+ ProjectPathPreset inchangé ou étendu)
  → ProjectManifest en mémoire (applyInMemoryProjectManifest)
  → Save Project → project.json
  → rechargement / runtime load
  → resolvePathPatternEditorRenderResolution (mapX, mapY, elapsedMs, variant)
  → resolvePathPatternRuntimeRenderResolution (même logique de matching / fallback)
```

---

## 5. Modèles et fichiers clés

| Fichier | Rôle |
|---------|------|
| `map_core/lib/src/models/path_center_pattern.dart` | Taille du motif, cellules, égalité / hash pour tests et persistance. |
| `map_core/lib/src/models/project_path_pattern_preset.dart` | Agrégat **`ProjectPathPatternPreset`** (id, nom, base, centre, transparent…). |
| `map_core/lib/src/operations/path_center_pattern_resolver.dart` | Projection **(mapX, mapY) → cellule locale** du center pattern (répétition du bloc). |
| `map_core/lib/src/operations/path_pattern_visual_resolution.dart` | **Cœur** : variant legacy si frames présentes **et** variante ≠ `cross` ; sinon **frames du center** (y compris `cross`). |
| `map_core/lib/src/operations/project_path_pattern_preset_json_codec.dart` | Sérialisation JSON du preset PathPattern. |
| `map_core/lib/src/models/project_manifest.dart` | Champ `pathPatternPresets` + liste `pathPresets`. |
| `map_editor/.../path_studio_new_path_draft.dart` | État brouillon, mutations tuiles centre, **`generatePathStudioCenterAnimationSequence`**. |
| `map_editor/.../path_studio_save_flow.dart` | Orchestration apply / merge manifest / callbacks. |
| `map_editor/.../path_studio_save_plan.dart` | Préparation **`ProjectPathPatternPreset`**, issues de sauvegarde. |
| `map_editor/.../path_studio_panel.dart` | Shell Path Studio + `part` (`path_studio_common_widgets.dart`, `path_studio_preset_card.dart`, `path_studio_diagnostics_view.dart`, …). |
| `map_editor/.../path_pattern_editor_read_model.dart` | Cartes liste, diagnostics, résumés pour l’UI. |
| `map_editor/.../path_pattern_asset_diagnostics.dart` | Couche diagnostics **fichier image + rects**. |
| `map_editor/.../path_pattern_tileset_image_info_loader.dart` | Chargement synchrone d’infos image pour la validation asset. |
| `map_editor/.../path_pattern/path_pattern_editor_render_resolution.dart` | Matching PathPattern, fallbacks **legacy / ambigu**, appel `resolvePathPatternVisual`, choix frame animée. |
| `map_editor/.../map_canvas/map_grid_painter.dart` | Application des rects résolus sur la grille éditeur. |
| `map_runtime/.../path_pattern_runtime_render_resolution.dart` | Parité de politique avec l’éditeur (legacy / PathPattern / ambigu). |
| `map_runtime/.../map_layers_component.dart` | Consommation runtime des tuiles path. |

---

## 6. Politique de rendu (éditeur = runtime)

Règles alignées **map_core** + enveloppes **éditeur** / **runtime** :

| Situation | Comportement |
|-----------|----------------|
| **0** `ProjectPathPatternPreset` pour la base | **Rendu legacy** (autotile path historique). |
| **1** preset PathPattern pour la base | **Rendu PathPattern** via `resolvePathPatternVisual` + frame animée. |
| **>1** presets pour la même `basePathPresetId` | **Fallback legacy** + source **`ambiguousPathPatternFallback`** (diagnostic `pathPatternRenderAmbiguous` côté read model). |
| Variant legacy **configuré** avec frames | **Frames variant** (`legacyVariant`) sauf `cross` (voir ci-dessous). |
| Variant **sans** mapping legacy utilisable | **Repli sur `centerPattern`** (cellule résolue par `(mapX, mapY)`). |
| **`TerrainPathVariant.cross`** | **Toujours** résolution **`centerPattern`** (branche dédiée dans `resolvePathPatternVisual`). |
| **center-only** | Le centre porte tout le visuel répété ; les variants manquants ne bloquent pas ce mode pour le rendu du centre. |

> À vérifier si besoin : détails exacts des combinaisons « variant vide + center vide » — les tests `path_pattern_editor_render_resolution_test` / runtime miroir couvrent les branches principales.

---

## 7. Création d’une eau animée 2×2 (workflow utilisateur)

1. Ouvrir l’éditeur et passer en **Path Studio**.
2. **Nouveau chemin** : choisir un nom, un **tileset** projet (ex. **`deep_water`**), une **surface** compatible, taille de centre **2×2**.
3. Pour chaque cellule A/B/C/D du centre, assigner les tuiles sources (picker image ou liste).
4. Ouvrir **« Générer une séquence »** : renseigner **nombre de frames**, **Pas X**, **Pas Y**, **Durée par frame (ms)**, cible **cellule active** ou **toutes les cellules**.
5. Exemple **deep_water** (convention fréquente dans les tests) :  
   - `frameCount` ≥ 4  
   - **`stepX = 3`**, **`stepY = 0`**  
   - **`durationMs = 200`**  
   - Enchaînement logique des offsets pour reproduire la grille régulière, par cellule :  
     - **A** : (0,0) → (3,0) → (6,0)  
     - **B** : (1,0) → (4,0) → (7,0)  
     - **C** : (0,1) → (3,1) → (6,1)  
     - **D** : (1,1) → (4,1) → (7,1)
6. Mapper les **variants path** requis pour la sauvegarde (au minimum ce que le plan de save exige).
7. **« Appliquer au projet »** : le manifest mémoire est mis à jour ; **`isProjectDirty` → true**.
8. **Save Project** (disquette) : écriture **`project.json`** ; **`isProjectDirty` → false`** si succès.
9. Vérifier **Map** (éditeur) et **runtime host** : eau animée conforme aux goldens.

---

## 8. Édition d’un PathPattern existant

1. Sélectionner un preset PathPattern dans la liste.
2. **« Modifier »** : ouverture d’un **brouillon d’édition** avec **id / frames / variants** issus du manifest (read-only source → draft mutable).
3. Modifier centre, noms, ou mappings ; les **ids** restent ceux du preset cible jusqu’à apply (slug / unicité gérés par le plan de save).
4. **« Appliquer les modifications »** : remplace le preset en mémoire ; dirty à true.
5. **Save Project** pour persister.
6. **Annuler les modifications** : retour état liste / fiche **sans** mutation manifest si confirmé — tests `path_studio_panel_test.dart` (Lot 40).

---

## 9. Annulation / revert

| Action | Effet |
|--------|--------|
| **Annuler la création** | Ferme le brouillon **nouveau chemin** ; pas d’apply ; pas de `project.json`. |
| **Annuler les modifications** | Ferme le brouillon **édition** ; restaure la vue **read-only** ; pas d’apply. |
| Brouillon **dirty** + annulation | **Dialogue** « Des modifications non appliquées seront perdues. » — boutons **Continuer l’édition** / confirmer annulation (`path-studio-cancel-draft-*`). |
| Manifest | **Jamais** muté par seul « Annuler » (sans apply intermédiaire). |

---

## 10. Apply mémoire vs Save Project

| | **Appliquer au projet / Appliquer les modifications** | **Save Project** |
|--|------------------------------------------------------|------------------|
| **Cible** | `ProjectManifest` **en RAM** (via `EditorNotifier.applyInMemoryProjectManifest`). | Fichier **`project.json`** sur disque. |
| **`isProjectDirty`** | Passe à **`true`** (mutation non persistée). | **`false`** si sauvegarde **réussie** ; inchangé / **`true`** si échec. |
| **Wording** | Cartes « **Application au projet (mémoire)** », aide contextuelle **Save Project + disquette**. | Toolbar + raccourcis habituels. |

**Historique (Lot 36-bis)** : avant clarification, un libellé type « Enregistrer » pouvait laisser croire que l’action persistait le disque ; **V1** sépare explicitement **apply mémoire** vs **Save Project → `project.json`**.

---

## 11. Dirty project state

| Événement | `isProjectDirty` |
|-----------|------------------|
| `applyInMemoryProjectManifest` | **`true`** |
| `saveProjectManifest` **succès** | **`false`** |
| `saveProjectManifest` **échec** | **reste `true`** |
| `openProjectSession` / chargement projet (`loadProject` → session) | **`false`** (état propre chargé) |
| `openMapDocument` | **Ne modifie pas** le flag (test `editor_project_session_controller_test.dart`) |

Implémentation : `project_session_controller.dart` (`openProjectSession` force `isProjectDirty: false` à l’ouverture projet ; `openMapDocument` ne touche pas à ce champ).

---

## 12. Diagnostics PathPattern

### Manifest / structure (`PathPatternDiagnosticCode`)

`missingBasePathPreset`, `duplicateBasePathPresetId`, `duplicatePathPatternForBase`, `duplicatePathPatternId`, `missingBaseTileset`, `missingFrameTileset`, `centerPatternEmpty`, `cellWithoutFrames`, `centerOnly`, `partialVariantCoverage`, `noVariantCoverage`, `crossHandledByCenterPattern`, `pathPatternRenderAmbiguous`, `centerPatternStats`, puis Lot 41 : `missingTilesetImageFile`, `unreadableTilesetImageFile`, `frameSourceOutOfBounds`, `unsupportedPathPatternFrameSize`, `assetValidationUnavailable`.

### Sévérités

`PathPatternDiagnosticSeverity` : **`blocking`**, **`warning`**, **`info`** — tri et résumés dans l’UI (`path_studio_diagnostics_view.dart`, `path_studio_fr_copy.dart`).

### Règle frame / tileset (Lot 41)

- `frame.tilesetId` **vide** → résolution **tileset du base path** pour cette frame.  
- `frame.tilesetId` **non vide** mais tuileset absent du manifest → diagnostic **`missingFrameTileset`** (cf. tests `path_pattern_asset_diagnostics_test.dart`).

---

## 13. Tests et garanties

| Sujet | Test(s) (principaux) | Garantie |
|--------|----------------------|----------|
| JSON roundtrip | `map_core/test/project_manifest_path_pattern_save_reload_test.dart` | Schéma `pathPatternPresets` stable lecture/écriture. |
| Résolution visuelle | `map_core/test/path_pattern_visual_resolution_test.dart` | `resolvePathPatternVisual` (cross, variants, center). |
| Golden manifest eau | `map_core/test/path_pattern_water_animated_golden_slice_test.dart` + fixture `test/fixtures/path_pattern/project_manifest_pathpattern_animated_2x2.json` | Données canoniques eau 2×2 animée. |
| Rendu éditeur | `map_editor/test/path_pattern/path_pattern_water_animated_editor_golden_slice_test.dart`, `path_pattern_editor_render_resolution_test.dart`, `map_grid_painter_test.dart` | Peinture + résolution + golden. |
| Rendu runtime | `map_runtime/test/path_pattern_water_animated_runtime_golden_slice_test.dart`, `path_pattern_runtime_render_resolution_test.dart` | Parité runtime / JSON. |
| Persistance deep_water | `map_editor/test/path_pattern/path_pattern_deep_water_persistence_bug_test.dart` | Bug multi-frame corrigé, save manifest. |
| Dirty + navigation | `map_editor/test/editor_notifier_project_dirty_state_test.dart`, `editor_project_session_controller_test.dart`, `top_toolbar_test.dart`, `status_bar_test.dart` | UX dirty + `openMapDocument`. |
| Diagnostics | `path_pattern_editor_read_model_test.dart`, `path_studio_panel_test.dart` | Liste / blocages / résumé. |
| Asset bounds | `path_pattern_asset_diagnostics_test.dart`, scénarios panel | Hors image, hors rect, etc. |
| Assistant séquence | `path_studio_new_path_draft_test.dart`, `path_studio_panel_test.dart` | Génération géométrique + UI. |
| Cancel / revert | `path_studio_panel_test.dart` | Pas d’apply intempestif. |
| FR / polish | `path_studio_fr_copy_test.dart`, tests ergonomie panel | Pluriels, résumés diagnostics. |
| Save flows | `path_studio_new_path_save_flow_test.dart`, `path_studio_edit_path_save_flow_test.dart`, build requests | Apply + merge. |
| Extraction + audit | Rapports 43 / 43-bis + `flutter test test/path_pattern/` | Pas de régression post-refactor panel. |

---

## 14. Golden slices

| Élément | Rôle |
|---------|------|
| **`packages/map_core/test/fixtures/path_pattern/project_manifest_pathpattern_animated_2x2.json`** | Fixture **source de vérité** JSON eau 2×2 animée (variants partiels, cross, override). |
| **`path_pattern_water_animated_golden_slice_test.dart`** (`map_core`) | Roundtrip JSON + invariants données. |
| **`path_pattern_water_animated_editor_golden_slice_test.dart`** (`map_editor`) | `MapGridPainter` reproduit la fixture. |
| **`path_pattern_water_animated_runtime_golden_slice_test.dart`** (`map_runtime`) | `MapLayersComponent` reproduit la fixture côté jeu. |

Ces trois tests **alignent** manifest → éditeur → runtime pour le **cas eau** documenté.

---

## 15. Limites connues V1

- Pas d’import TSX/TMX ni pipeline atlas externe.
- Assistant = **géométrie de frames** sur le center, pas d’IA / d’inférence de bords.
- Variants legacy **non animés** par l’assistant (animation = center multi-frames).
- Validation asset **dépendante** d’une carte d’images projet ; sinon `assetValidationUnavailable`.
- Plusieurs PathPattern sur une même base : **ambiguïté** → fallback legacy + diagnostic.
- Tall Grass / Surface Studio : **hors scope** PathPattern V1.

---

## 16. Recommandations futures (sans ouvrir de lot ici)

- Validation asset **sur le brouillon actif** (chargement image paresseux).
- Cache / invalidation **`PathPatternTilesetImageInfo`** pour gros projets.
- Import atlas / feuille de sprites **piloté utilisateur**.
- Assistant étendu (**variants**, **bords**) si besoin produit.
- Guide utilisateur **non développeur** (court PDF / aide in-app).
- Tall Grass : chantier **isolé**.
- Profiling si latence Path Studio sur projets massifs.

---

## 17. Historique des lots (timeline 27 → 44)

Les intitulés suivent les fichiers `reports/pathPattern/pathpattern_*.md` (référence vérifiable).

| Lot | Rapport (extrait titre) |
|-----|-------------------------|
| **27** | `pathpattern_27_new_path_save_flow_v0` — save flow nouveau chemin |
| **28** | `pathpattern_28_center_only_rendering_policy_painter_prep_v0` — politique center-only / prep painter |
| **29** | `pathpattern_29_editor_painter_center_only_rendering_v0` — rendu éditeur |
| **30** | `pathpattern_30_center_pattern_animation_draft_v0` — animation centre (draft) |
| **31** | `pathpattern_31_runtime_pathpattern_render_v0` — rendu runtime |
| **32** | `pathpattern_32_center_animation_ux_clarification_v0` — UX animation |
| **33** | `pathpattern_33_edit_existing_pathpattern_draft_v0` — édition existante |
| **34** | `pathpattern_34_save_reload_json_regression_v0` — JSON save/reload |
| **35** | `pathpattern_35_animated_water_golden_slice_v0` — golden slice eau |
| **36** | `pathpattern_36_deep_water_center_animation_persistence_bugfix_v0` — persistance deep_water |
| **36-bis** | `pathpattern_36_bis_apply_vs_save_project_ux_clarification_v0` — apply vs Save Project |
| **37** | `pathpattern_37_project_dirty_save_pending_ux_v0` — dirty project |
| **37-bis** | `pathpattern_37_bis_project_dirty_navigation_safety_v0` — navigation safety |
| **38** | `pathpattern_38_pathpattern_diagnostics_ux_v0` — diagnostics UX |
| **39** | `pathpattern_39_center_animation_sequence_assistant_v0` — assistant séquence |
| **40** | `pathpattern_40_draft_cancel_revert_safety_v0` — cancel/revert |
| **41** | `pathpattern_41_asset_bounds_validation_v0` — asset / bounds |
| **42** | `pathpattern_42_path_studio_ergonomics_polish_v0` — polish FR / UI |
| **43** | `pathpattern_43_path_studio_cleanup_component_extraction_v0` — extraction `part` |
| **43-bis** | `pathpattern_43_bis_extraction_safety_audit_v0` — audit sécurité extraction |
| **44** | *Ce document* — consolidation V1 |

*(Les lots **20–26** existent dans `reports/pathPattern/` et préparent Path Studio / variantes ; la chaîne **27+** couvre la maturation jusqu’à V1.)*

---

## 18. Procédure de reprise

1. **Lire** ce rapport + `AGENTS.md` (frontières packages).
2. **Lancer** les garde-fous ci-dessous.
3. **Vérifier** manuellement Path Studio (nouveau chemin, apply, Save Project, dirty).
4. **Ne pas** mélanger Tall Grass / Surface dans ce périmètre.
5. En cas de doute régression : comparer avec la **fixture golden** §14.

### Commandes de reprise recommandées

```bash
cd packages/map_editor
flutter test test/path_pattern/ --reporter compact
flutter test test/top_toolbar_test.dart test/status_bar_test.dart test/editor_notifier_project_dirty_state_test.dart test/editor_project_session_controller_test.dart --reporter compact

cd ../map_core
dart test test/project_manifest_path_pattern_save_reload_test.dart test/path_pattern_water_animated_golden_slice_test.dart test/path_pattern_visual_resolution_test.dart --reporter compact --no-color
dart analyze lib/src/models lib/src/operations test/project_manifest_path_pattern_save_reload_test.dart

cd ../map_runtime
flutter test test/path_pattern_water_animated_runtime_golden_slice_test.dart test/path_pattern_runtime_render_resolution_test.dart --reporter compact
```

---

## 19. État final certifié

**PathPattern V1** est considéré **stable** pour le cas **eau animée center-only 2×2** et les flux Path Studio associés (création, édition, diagnostics, apply, save, dirty, cancel, assistant), **sous réserve** des limites §15.

Les évolutions futures doivent **partir de cette vérité** et d’une **non-régression** des tests §13.

---

## 20. Réponses aux 20 questions (index rapide)

1. **PathPattern** : association **base path** + **motif de centre** (`ProjectPathPatternPreset`) pour le rendu des tuiles path.  
2. **`ProjectPathPreset`** : autotile + variants legacy ; **`ProjectPathPatternPreset`** : centre local + lien `basePathPresetId`.  
3. **`centerPattern`** : autoriser un **bloc 1×1 / 2×2** répété sur la carte avec frames **indépendantes** du catalogue legacy.  
4. **`cross`** : le legacy ne porte pas le cas cross de façon fiable pour le nouveau pipeline → **forcer le centerPattern**.  
5. **center-only** : rendu entièrement porté par le **centre** pour la tuile (variants legacy vides pour ce besoin).  
6. **variants partiels** : certaines directions legacy ont des frames, d’autres non → **warnings** + repli possible centre.  
7. **Fallbacks** : pas de PathPattern / base absente / frame résolution impossible → **legacy** ; ambiguïté multi-PathPattern → **legacy** ; variant manquant → **center** ; cross → **center**.  
8. **Eau 2×2** : §7.  
9. **Édition** : §8.  
10. **Annuler** : §9.  
11. **Séquence** : assistant §7 + `generatePathStudioCenterAnimationSequence` dans `path_studio_new_path_draft.dart`.  
12. **Apply vs Save** : §10.  
13. **`isProjectDirty` true** : apply mémoire (et mutations manifeste équivalentes).  
14. **`isProjectDirty` false** : chargement session, sauvegarde projet réussie.  
15. **JSON** : tests `project_manifest_path_pattern_save_reload_test` + golden slice.  
16. **Éditeur** : `resolvePathPatternEditorRenderResolution` + `MapGridPainter` + golden editor.  
17. **Runtime** : `resolvePathPatternRuntimeRenderResolution` + `MapLayersComponent` + golden runtime.  
18. **Diagnostics** : §12.  
19. **Sévérités** : `blocking` / `warning` / `info` (tri + UI).  
20. **Limites** : §15.

---

## Evidence Pack (Lot 44)

### git status initial

```text
(arbre propre au lancement de la rédaction : aucune entrée `git status --short`)
```

### git status final

```text
?? reports/pathPattern/pathpattern_44_pathpattern_v1_consolidation_report.md
```

### git diff --stat / git diff --name-status

```text
(vide — aucun fichier tracké modifié)
```

### Tests exécutés (résultats)

| Commande | Résultat |
|----------|----------|
| `cd packages/map_editor && flutter test test/path_pattern/ test/top_toolbar_test.dart test/status_bar_test.dart test/editor_notifier_project_dirty_state_test.dart test/editor_project_session_controller_test.dart --reporter compact` | **`All tests passed!`** (compteur final **+254**) |
| `cd packages/map_core && dart test test/project_manifest_path_pattern_save_reload_test.dart test/path_pattern_water_animated_golden_slice_test.dart test/path_pattern_visual_resolution_test.dart --reporter compact --no-color` | **`All tests passed!`** (**+14**) |
| `cd packages/map_runtime && flutter test test/path_pattern_water_animated_runtime_golden_slice_test.dart test/path_pattern_runtime_render_resolution_test.dart --reporter compact` | **`All tests passed!`** (**+10**) |

### Analyse statique

| Commande | Résultat |
|----------|----------|
| `flutter analyze lib/src/features/path_studio lib/src/features/path_pattern test/path_pattern` | **11 × info** `prefer_const_constructors` dans des **fichiers de test** existants uniquement (exit code 1) — **aucune erreur** sur les sources `lib/`. |
| `dart analyze lib/src/models lib/src/operations test/project_manifest_path_pattern_save_reload_test.dart` (`map_core`) | **No issues found!** |

### Auto-review

- Aucun fichier de production modifié ; uniquement ce rapport.
- Les affirmations « prouvées » renvoient à des **tests** ou **chemins de fichier** explicites.
- Les lots **< 27** ne sont pas détaillés ici (hors demande stricte 27–44) mais signalés.

---

## Checklist finale (Lot 44)

- [x] Audit initial réalisé.
- [x] AGENTS.md et agent_rules.md pris en compte (règles dépôt : pas de git write, pas de faux tests).
- [x] Aucun code de production modifié.
- [x] Aucun map_core modifié.
- [x] Aucun runtime modifié.
- [x] Aucun format JSON modifié.
- [x] Aucun provider/repository/service ajouté.
- [x] Rapport de consolidation créé.
- [x] Périmètre V1 documenté.
- [x] Exclusions documentées.
- [x] Architecture documentée.
- [x] Workflow eau 2×2 animée documenté.
- [x] Apply vs Save Project documenté.
- [x] Dirty project documenté.
- [x] Diagnostics documentés.
- [x] Tests et garanties documentés.
- [x] Golden slices documentées.
- [x] Limites connues documentées.
- [x] Recommandations futures documentées.
- [x] Timeline des lots documentée.
- [x] Tests garde-fous lancés.
- [x] Analyse lancée ; dette `info` tests documentée.
- [x] git status final inclus.
- [x] Auto-review faite.
