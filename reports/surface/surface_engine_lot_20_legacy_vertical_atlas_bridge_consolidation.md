# Lot 20 — Legacy Vertical Atlas Bridge Consolidation Report V0

**Date (rédaction)** : 2026-04-26  
**Type** : lot **documentaire uniquement** (aucun fichier Dart modifié, aucun modèle Freezed, aucun test ajouté).  
**Phase consolidée** : **P0.5 — Legacy Surface / Vertical Atlas Bridge** (préparatoire, non équivalente au Surface Engine persistant).

---

## 1. Résumé exécutif

- La **passerelle** entre le modèle path legacy (`ProjectPathPreset`, `TilesetVisualFrame`, `PathSurfaceKind`) et la convention d’**atlas vertical** (« colonnes = variantes de path, bande = frames d’animation ») est **en place et caractérisée** dans `map_core` (Lots 11–19, plus audit/vues/diagnostics des lots 0–10).
- On peut aujourd’hui **générer** des `ProjectPathPreset` animés compatibles des vues legacy, à partir d’un **layout d’atlas vertical** explicite ou du **layout standard** (Lot 14), y compris via des **wrappers produit** `water` / `lava` / `ice` / `tallGrass` (Lots 16–19) qui ne font que fixer l’`enum` `PathSurfaceKind` et déléguer au Lot 15.
- Cette couche **ne remplace pas** le futur **Surface Engine** (pas de `SurfaceDefinition`, pas de `SurfaceLayer`, pas de persistance Surface dédiée). Elle **sécurise l’existant** et donne un **pont d’authoring** vers les mêmes données legacy que l’éditeur/runtime consomment déjà via `PathLayer` / autotile path.
- **Décision (voir §18)** : considérer la passerelle vertical-atlas + wrappers `water/lava/ice/tallGrass` comme **suffisante pour l’instant** ; la **suite** doit s’orienter vers les **modèles Surface minimaux** (alignement roadmap **P1.01** dans `surface project/pokemap_surface_engine_micro_lots.md`).

---

## 2. Pourquoi ce lot existe

Après quatre wrappers « produit » successifs (Lots 16–19), le risque est :

- **prolifération** de wrappers one-liner par `PathSurfaceKind` (swamp, rails, bridge, …) ;
- **dilution** du message d’architecture : on ne remplace pas le Surface Engine par plus de glue legacy.

Ce rapport **consolide** ce qui a été construit, **fixe la frontière** (arrêt volontaire des wrappers), et **cible** la prochaine phase utile (modèles Surface **sans** alourdir encore `ProjectManifest` tant que le lot ne le demande pas).

---

## 3. Phase réalisée : P0.5 — Legacy Surface / Vertical Atlas Bridge

Sous-blocs (ordre logique, pas strictement l’ordre d’exécution des tickets) :

| Bloc | Contenu (référence lots / livrables) |
|------|--------------------------------------|
| Audit & caractérisation | État initial, autotile, JSON manifest, timeline frames (rapports d’analyse + lots 1–3, etc.) |
| Vues & diagnostics legacy | `LegacyPathSurfaceView`, terrain, catalog, diagnostics, usage, audit report (lots 4–10) |
| Vertical atlas (fondation) | `createTileVisualFramesFromVerticalAtlas` (11) ; mapping variant → colonne (12) ; preset complet (13) |
| Layout standard | `standardTerrainPathVariantVerticalAtlasOrder`, `createStandardTerrainPathVariantVerticalAtlasColumns` (14) |
| Builder standard générique | `createStandardProjectPathPresetFromVerticalAtlas` (15) |
| Wrappers produit | eau, lave, glace, hautes herbes (16–19) : fixent seulement `PathSurfaceKind` |

**Emplacement des rapports** : une partie des rapports a été regroupée sous `reports/surface/` plutôt que `reports/analysis/` pour certains numéros de lot (voir **Annexe A — Fichiers de rapport**). Les intitulés listés au prompt sous `reports/analysis/surface_engine_lot_1_...` ne correspondent pas toujours au chemin actuel : **le dépôt fait foi**.

---

## 4. Chaîne technique complète

Chaîne **verticale** (une colonne = un `TerrainPathVariant`, frames empilées) :

```text
createTileVisualFramesFromVerticalAtlas
        →  List<TilesetVisualFrame> pour UNE colonne (x fixe, y = frames)
        ↓
createPathVariantMappingsFromVerticalAtlas
        →  une liste de PathPresetVariantMapping (par colonne) en réutilisant le helper ci-dessus
        ↓
createProjectPathPresetFromVerticalAtlas
        →  ProjectPathPreset complet (surfaceKind explicite) à partir d’une liste de colonnes
```

Chaîne **layout standard** (Lot 14 + 15) :

```text
createStandardTerrainPathVariantVerticalAtlasColumns
        →  columns pour les variants (ordre V0 = standardTerrainPathVariantVerticalAtlasOrder ou sous-ensemble)
        ↓
createStandardProjectPathPresetFromVerticalAtlas
        →  compose 13+14 : génère le preset standard pour un surfaceKind arbitraire
```

**Wrappers produit** (Lots 16–19) — chacun = **déléguer à `createStandardProjectPathPresetFromVerticalAtlas`** en fixant **un** `PathSurfaceKind` :

```text
createStandardWaterPathPresetFromVerticalAtlas
createStandardLavaPathPresetFromVerticalAtlas
createStandardIcePathPresetFromVerticalAtlas
createStandardTallGrassPathPresetFromVerticalAtlas
```

**Lecture / compat** (non exclusifs de la chaîne ci-dessus) :

- `resolveTileVisualFrameTimeline` — choix d’index de frame à partir de durées + mode (loop / oneShot, etc.).
- `createLegacyPathSurfaceView` / `createLegacyProjectSurfaceCatalogView` — vues read-only sur les presets déjà présents dans le manifeste (côté appelant).

---

## 5. APIs disponibles (périmètre « bridge vertical atlas + legacy surface »)

Exportées par `map_core.dart` (extraits **périmètre lot** ; le barrel exporte aussi le reste du monorepo).

| API / symbole principal | Rôle | Niveau | Ce que l’API ne fait pas |
|-------------------------|------|--------|---------------------------|
| `createTileVisualFramesFromVerticalAtlas` | Frames verticales sur une colonne | Atlas | Ne mappe pas les variants, ne connaît pas `PathSurfaceKind` path |
| `createPathVariantMappingsFromVerticalAtlas` | Colonnes → `PathPresetVariantMapping` | Atlas + path | Ne crée pas un preset complet seul (sans builder Lot 13) |
| `createProjectPathPresetFromVerticalAtlas` | `ProjectPathPreset` à partir de colonnes explicites | Builder legacy | N’impose pas l’ordre standard (Lot 14) |
| `standardTerrainPathVariantVerticalAtlasOrder` | Ordre V0 des variants | Layout | N’est pas le gameplay |
| `createStandardTerrainPathVariantVerticalAtlasColumns` | Colonnes standard (+ sous-layout) | Layout | Valide; ne génère pas d’image |
| `createStandardProjectPathPresetFromVerticalAtlas` | `ProjectPathPreset` + layout standard + kind arbitraire | Builder | N’ajoute pas surf / hazard / etc. |
| `createStandardWaterPathPresetFromVerticalAtlas` | Idem, `PathSurfaceKind.water` | Wrapper produit | Pas d’eau « physique », pas de surf (Lots futurs) |
| `createStandardLavaPathPresetFromVerticalAtlas` | `PathSurfaceKind.lava` | Wrapper produit | Pas de dégâts / hazard |
| `createStandardIcePathPresetFromVerticalAtlas` | `PathSurfaceKind.ice` | Wrapper produit | Pas de glissade |
| `createStandardTallGrassPathPresetFromVerticalAtlas` | `PathSurfaceKind.tallGrass` | Wrapper produit | Pas d’encounter / overlay / bruissement |
| `createLegacyPathSurfaceView` | Vue path surface legacy | Vue read-only | Ne rend pas, ne moteur pas |
| `createLegacyTerrainSurfaceView` / `createLegacyProjectSurfaceCatalogView` | Vues / catalogue | Vue | Pas de stockage Surface nouveau |
| `createLegacySurfaceCatalogDiagnostics` / usage / audit | Diagnostics | Rapport / audit | N’impose pas de migration |
| `resolveTileVisualFrameTimeline` | Résolution frame dans le temps | Timeline | Ne charge pas de textures, ne sait pas du tileset réel |

---

## 6. Tests de protection (tableau)

Compteurs obtenus **lors de la rédaction de ce rapport** par exécution ciblée :  
`dart test <fichier>` (dernier `+N` avant `All tests passed!`).  
**Total** : `dart test` sur **tout** `map_core` → **`+524`**, `All tests passed!` (même exécution, 2026-04-26).

| Fichier de test | Lot / thème (approx.) | +N (preuve) | Rôle |
|-----------------|------------------------|------------|------|
| `tile_visual_frame_timeline_test.dart` | 2 (timeline) | +16 | Frame index, modes |
| `tile_visual_frame_vertical_atlas_test.dart` | 11 | +23 | Frames verticales, durées |
| `path_variant_vertical_atlas_mapping_test.dart` | 12 | +28 | Mappings, validations |
| `path_preset_vertical_atlas_builder_test.dart` | 13 | +34 | Preset explicite, validations |
| `terrain_path_variant_vertical_atlas_layout_test.dart` | 14 | +14 | Ordre V0, colonnes |
| `standard_path_preset_vertical_atlas_builder_test.dart` | 15 | +28 | Preset standard, surfaceKind var. |
| `standard_water_path_preset_vertical_atlas_builder_test.dart` | 16 | +28 | Eau, compat legacy |
| `standard_lava_path_preset_vertical_atlas_builder_test.dart` | 17 | +28 | Lave |
| `standard_ice_path_preset_vertical_atlas_builder_test.dart` | 18 | +28 | Glace |
| `standard_tall_grass_path_preset_vertical_atlas_builder_test.dart` | 19 | +28 | Hautes herbes |
| `legacy_path_surface_view_test.dart` | 4 | +11 | Vue path |
| `legacy_terrain_surface_view_test.dart` | 5 | +12 | Vue terrain |
| `legacy_project_surface_catalog_view_test.dart` | 6 | +12 | Catalog |
| `legacy_surface_catalog_diagnostics_test.dart` | 7 | +17 | Diagnostics |
| `legacy_surface_usage_view_test.dart` | 8 | +22 | Usage |
| `legacy_surface_usage_diagnostics_test.dart` | 9 | +15 | Usage diagnostic |
| `legacy_surface_audit_report_test.dart` | 10 | +8 | Rapport audit |

*Remarque* : d’autres tests existent dans `map_core` (hors tableau) ; le **total agrégé** est **524** pour la suite complète.

---

## 7. État des wrappers produits (Lots 16–19)

| surfaceKind | Helper | Statut | Gameplay ajouté ? | Runtime / rendu ajouté ? |
|-------------|--------|--------|-------------------|--------------------------|
| `PathSurfaceKind.water` | `createStandardWaterPathPresetFromVerticalAtlas` | fait | **non** | **non** |
| `PathSurfaceKind.lava` | `createStandardLavaPathPresetFromVerticalAtlas` | fait | **non** | **non** |
| `PathSurfaceKind.ice` | `createStandardIcePathPresetFromVerticalAtlas` | fait | **non** | **non** |
| `PathSurfaceKind.tallGrass` | `createStandardTallGrassPathPresetFromVerticalAtlas` | fait | **non** | **non** |

Ces helpers **ne font** qu’appeler le Lot 15 avec le bon `PathSurfaceKind` (et documentent ce qu’ils n’inventent pas).

---

## 8. Ce que cette passerelle permet réellement

- Produire un **`ProjectPathPreset` legacy** avec des **frames d’animation** cohérentes avec un **atlas vertical** (convention type SDK Pokémon / colonne unique par variant autotile path).
- Utiliser le **layout standard** `TerrainPathVariant` → colonne (Lot 14) sans recoder la table à la main.
- Générer rapidement des presets d’eau / lave / glace / hautes herbes **au sens enum uniquement** pour l’authoring outil / glue / tests.
- Rester **compatible** avec :
  - `LegacyPathSurfaceView` / `LegacyProjectSurfaceCatalogView` (si le preset est injecté côté manifeste par l’appelant) ;
  - `resolveTileVisualFrameTimeline` sur les `TilesetVisualFrame` générés.
- **Ne pas** dépendre de Tiled comme source de vérité : tout reste en **data PokeMap** + helpers Dart.

---

## 9. Ce que cette passerelle ne permet volontairement pas

- Pas de types **`ProjectSurfaceAtlas`**, **`ProjectSurfaceAnimation`**, **`ProjectSurfacePreset`**, **`SurfaceLayer`** tels que décrits dans la spec long terme.
- Pas de **`SurfaceDefinition`** persistante ni liste `surfaceDefinitions` sur le manifeste (interdit explicite dans les lots surface jusqu’ici).
- Pas de **runtime Surface** : pas de `RuntimeSurface*`, pas d’intégration `map_runtime` ici.
- Pas de **Surface Studio** : pas d’UI dédiée.
- Pas d’**automatismes gameplay** : surf, encounters herbes, hazard lave, glissade, overlay pieds, bruissement, **son**, **particules** — hors scope.
- Pas de **migration destructive** des projets : les lots ont pris l’option **caractérisation + compat** avant bascule modèle.
- **Ne pas** valider qu’un rectangle source tient dans une image réelle (pas de chargement binaire ici).

---

## 10. Pourquoi arrêter les wrappers legacy ici

- Les quatre **surfaces animées** les plus mentionnées dans la roadmap et les specs d’inspiration (eau, lave, glace, herbes) ont chacun un **point d’entrée** stable.
- Les autres `PathSurfaceKind` (`swamp`, `rails`, `bridge`, `custom`, …) peuvent utiliser **directement** `createStandardProjectPathPresetFromVerticalAtlas` (Lot 15) **sans** multiplier les fichiers « standard-X ».
- Le **prochain gain marginal** d’un 5e wrapper n’est **pas** comparable au gain d’introduire le **noyau Surface** (schéma, atlasses, animation, liens vers tiles) de façon **contrôlée** (P1+).
- Éviter l’**usine à clones** et la dette de noms pour des one-liners.

---

## 11. Alignement avec la roadmap initiale

Référence lue : `surface project/pokemap_surface_engine_micro_lots.md` (v0.1, 2026-04-26).

- **Phase P1 — Modèle core Surface minimal** (à partir de **Lot P1.01** : fichier `surface.dart` minimal, câblé, **sans** modifier `ProjectManifest` dans un premier temps selon le lot).
- Les lots **0–19** (P0.5) **ne remplacent pas** P1 : ils **préparent** P1 (contrats de frames, de variants, de presets path) et éclairent P3 (tile animation) / P10 (migration) / P12 (nettoyage) **plus tard**.

**P0.5** est une **phase additionnelle** : audit + pont legacy + verticale atlas, **explicite** dans ce rapport même si le libellé « P0.5 » n’apparaissait pas en tête du micro-fichier roadmap au §0.

---

## 12. État recommandé avant le prochain lot

**Recommandation (alignée P1.01 + demande lot 20)** :

```text
Lot 21 — Surface Model Entrypoint V0
```

**Objectif** (cible) :

- Créer `packages/map_core/lib/src/models/surface.dart` (ou nom équivalent **cohérent** avec le monorepo) ;
- L’**exporter** dans `map_core.dart` ;
- N’y mettre d’abord que des **types simples** (enums / typedefs) **non dangereux** pour le JSON existant ;
- **Ne pas** modifier `ProjectManifest` dans le même lot si le besoin d’y accrocher des listes n’est pas encore cadré ;
- **Ne pas** activer de runtime ni d’éditeur.

*Pourquoi pas « P1.01 » en titre strict ?* — Le dépôt nomme déjà des « Lot 20 », « Lot 19 » côté surface : **Lot 21** garde la continuité des livrables `reports/surface/` tout en recouvrant l’**intention** du micro-lot **P1.01** du document `pokemap_surface_engine_micro_lots.md`.

**Alternative prudente** (si l’équipe veut d’abord seulement un ADR) : un lot « décision surface.dart fields » sans fichier code — **non retenu ici** car le micro-roadmap exige déjà P1.01 exécutable.

---

## 13. Règles de preuve à conserver pour la suite

- **Contenu complet ou diff complet** des fichiers créés/modifiés quand le lot touche le code.
- **Compteurs exacts** des `dart test` ciblés + **total** de la suite package quand c’est exigible.
- Ne **pas** conclure « vert » sans commande reproductible.
- Ne **pas** affirmer **100% couverture** sans outil de coverage dédié.
- Ne **pas** affirmer **absence de fuite mémoire** / perf sans mesure.
- Distinguer **ce qui est prouvé par test** de ce qui est **déductible** ou **hors lot**.
- Honnêteté : si un rapport historique manque ou est **déplacé** (chemins `reports/analysis/` vs `reports/surface/`), le **signaler** (cf. annexe A).

---

## 14. Risques restants (techniques / produit)

- **Duplication conceptuelle** : plusieurs entrées (Lot 15 vs wrappers 16–19) — mitigé par l’arrêt des nouveaux wrappers.
- **Centrage persistant** sur `ProjectPathPreset` : le cœur migration reste **path**, pas **Surface** — jusqu’à P1+.
- **Absence** de `SurfaceDefinition` / manifest Surface : **pas** de validation unifiée « surface projet » côté JSON.
- **Absence** de runtime Surface : séparation visuel/gameplay **incomplète** pour le produit final.
- **tallGrass** : pas d’**overlay** joueur / **encounter** distincts des données path — par design dans cette phase.
- **water** : pas de **surf** explicite dans ces helpers.
- **lava** : pas de **hazard** explicite.
- **ice** : pas de **glissade** explicite.
- **Gouvernance** : sans discipline, revenir à des wrappers pour chaque `PathSurfaceKind` recrée la dette qu’on veut **stopper ici**.

---

## 15. Commandes lancées (ce lot)

```text
cd packages/map_core
/opt/homebrew/bin/dart test
→ dernière progression relevée : +524, puis "All tests passed!"
```

(Exécution effectuée pour **documenter** l’état actuel — **aucun fichier Dart n’a été modifié** par ce lot.)

```text
cd /Users/karim/Project/pokemonProject
git status --short
?? reports/surface/surface_engine_lot_20_legacy_vertical_atlas_bridge_consolidation.md

git diff --stat
(aucune sortie : pas de diff sur fichiers suivis modifiés ; le rapport est non indexé)
```

**Tests** : la suite **complète** a été relancée **à titre de preuve d’état** ; le lot n’imposait pas de test si zéro changement Dart (ici : **0 changement Dart**). La **dernière preuve** de lot code reste cohérente avec le Lot 19 **+524** — **reconfirmé** par l’exécution ci-dessus au moment de la rédaction.

---

## 16. Fichiers créés / modifiés (lot 20)

| Action | Fichier |
|--------|---------|
| **Créé** | `reports/surface/surface_engine_lot_20_legacy_vertical_atlas_bridge_consolidation.md` |
| **Modifié** | **Aucun autre** (hors suivi git du fichier rapport ci-dessus) |

**Confirmation** : **aucun** fichier **`.dart`** modifié pour le Lot 20.

---

## 17. Ce qui n’a volontairement pas été fait

- Aucun code, aucun test ajouté, aucun `build_runner`, aucun modèle Freezed, aucun manifeste / layer modifié, aucun package hors `reports/`.

---

## 18. Décision finale

**La passerelle legacy vertical atlas est considérée terminée pour le moment. La suite doit basculer vers les modèles Surface persistants (à partir d’un lot type P1.01 / Lot 21), sans continuer la série de wrappers `PathSurfaceKind`.**

---

## 19. Autocritique finale

- Ce rapport **agrège** des sources **présentes dans le dépôt** et une **exécution de tests** au moment de la rédaction ; un rapport de lot **plus ancien** peut diverger sur le détail d’un compteur si la suite a évolué — la **preuve** reste : `cd packages/map_core && dart test` + git sur la branche courante.
- Les chemins `reports/analysis/surface_engine_lot_*` listés au prompt ne recouvrent pas toujours l’arbo actuelle (voir **Annexe A**).

---

## 20. Auto-review indépendante (réponses explicites)

| Question | Réponse |
|----------|---------|
| Lot documentaire uniquement ? | **Oui** |
| Aucun code Dart modifié ? | **Oui** (hors **création** d’un **fichier .md** uniquement) |
| Aucun modèle Surface persistant créé ? | **Oui** |
| Phase P0.5 clairement préparatoire ? | **Oui** |
| Wrappers legacy volontairement stoppés après `tallGrass` ? | **Oui** (recommandation explicite) |
| Prochaine étape claire (Lot 21 / P1.01) ? | **Oui** |
| Limites de la passerelle clairement documentées ? | **Oui** |
| Règles de preuve rappelées ? | **Oui** |
| Commandes Git d’écriture interdites non utilisées ? | **Oui** |
| Le rapport ne prétend pas que le Surface Engine complet existe ? | **Oui** (il le dit explicite) |

---

## Annexe A — Rapports : chemins du prompt vs dépôt (audit partiel)

**Présent sous `reports/analysis/`** (extrait) :

- `surface_engine_initial_audit.md` ✓

**Beaucoup de rapports listés** dans le prompt comme `reports/analysis/surface_engine_lot_1_...` existent en pratique sous **`reports/surface/`** avec un nom du type `surface_engine_lot_<n>_...md` (ex. lots 11, 12, 14–19). **Ne pas** considérer qu’un rapport est « manquant » sans vérifier `reports/surface/`.

**Exemples de divergences de nom** :

- Prompt : `surface_engine_lot_3_project_manifest_surface_json_...` — dépôt : `surface/surface_engine_lot_3_project_manifest_json_characterization.md` (intitulé proche, chemin `surface/`).

*Si un fichier listé au prompt est introuvable partout* : le statut est **absent** (ne pas le recréer ici — Lot 20 interdit de réécrire l’histoire en ajoutant de faux rapports).

---

## Annexe B — `git diff` attendu pour ce lot

Un fichier unique ajouté :

- `reports/surface/surface_engine_lot_20_legacy_vertical_atlas_bridge_consolidation.md`

Le **diff** complet vis-à-vis de `/dev/null` est le **contenu intégral** du présent document (v0 rédaction unique).

---

*Fin du rapport Lot 20.*
