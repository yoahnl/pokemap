# Environment Studio Map-centric Workflow Review

## 1. Résumé exécutif

Verdict court : **oui, la vision map-centric est la bonne direction produit**, mais elle doit être réduite à un V1 strict :

- `EnvironmentPreset` reste une **recette globale**.
- `EnvironmentLayer` + `EnvironmentArea` restent l’**application map-specific**.
- `EnvironmentAreaMask` reste l’entrée auteur.
- `MapPlacedElement` reste le résultat appliqué et consommable par éditeur/runtime/gameplay.
- Preview / Generate / Save doivent être explicitement séparés.

Le repo a déjà une base étonnamment avancée : modèle core, EnvironmentLayer, areas, masque booléen, génération déterministe, application en `MapPlacedElement`, clear/regenerate/shuffle, inspector, canvas overlay, golden slice éditeur. Le vrai trou n’est pas le domaine : c’est l’UX map-centric unifiée et le vocabulaire créateur.

Le piège majeur : transformer Environment Studio en **deuxième Map Editor**. À éviter. Environment Studio doit éditer seulement des applications d’environnement : carte cible, zone, masque, paramètres locaux, preview, placements générés. Pas tiles, paths, events, collisions générales, ni prop editor complet.

Prochain lot conseillé : **Environment-30 — Map-centric Environment Workspace Read Model**. Avant de refaire l’UI, créer un read model qui dit : carte active, EnvironmentLayer actif, area active, preset actif, état preview/génération/save. Sans nouvelle mutation.

## 2. Audit de l’existant

### Commandes principales utilisées

```text
git status --short --untracked-files=all
git log --oneline -n 20
git ls-files | rg '(^packages/(map_core|map_editor|map_runtime|map_gameplay)/|^reports/).*([Ee]nvironment|environment|map_canvas|editor_notifier|manifest|project_session|map_editing|MapData|MapPlacedElement|collision|runtime)'
rg -n "EnvironmentStudio|EnvironmentLayer|EnvironmentPreset|EnvironmentArea|EnvironmentMask|generatedPlacement|GeneratedPlacement|EnvironmentGenerated|environmentMask|environmentPresets|MapPlacedElement|placedElements|targetTileLayerId" packages/map_core/lib packages/map_editor/lib packages/map_runtime/lib packages/map_gameplay/lib reports
sed -n '1,460p' packages/map_core/lib/src/models/environment.dart
sed -n '4580,5328p' packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
sed -n '6720,7170p' packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
find reports -maxdepth 3 -type f | rg -i 'environment|surface|pathpattern'
```

### Git status initial

Le dépôt était déjà sale avant cette review. Changements notables observés :

```text
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart
?? packages/map_editor/lib/src/application/services/environment_generated_placement_hover_resolver.dart
?? packages/map_editor/lib/src/ui/canvas/tileset_grid_metrics.dart
?? packages/map_editor/test/environment_studio/environment_generated_placement_hover_preview_test.dart
?? packages/map_editor/test/tileset_grid_metrics_test.dart
```

Interprétation : ces fichiers viennent du travail précédent dans cette session : preview add/delete d’éléments générés et correction tileset grid. Cette review n’a pas modifié de fichier de production.

### Fichiers importants inspectés

| Fichier | Rôle | Conclusion |
|---|---|---|
| `packages/map_core/lib/src/models/environment.dart` | Modèles purs Environment : `EnvironmentPreset`, `EnvironmentPaletteItem`, `EnvironmentGenerationParams`, `EnvironmentAreaMask`, `EnvironmentArea` | Bonne base. Le masque booléen row-major existe déjà. `generatedPlacementIds` sépare bien masque et placements appliqués. |
| `packages/map_core/lib/src/operations/environment_layer_content_json_codec.dart` | Codec JSON EnvironmentLayerContent | Confirme persistance map-specific possible dans `MapData.layers`. Les rapports indiquent durcissement codec déjà fait. |
| `packages/map_core/lib/src/operations/environment_preset_json_codec.dart` | Codec JSON des presets | Confirme que les presets sont catalogués dans le manifest, séparés des applications map. |
| `packages/map_core/lib/src/operations/environment_preset_diagnostics.dart` | Diagnostics preset | Utile pour UI no-code : avertir sans exposer JSON. |
| `packages/map_core/lib/src/operations/environment_layer_usage_diagnostics.dart` | Diagnostics d’usage des layers | Utile pour statuts “Prêt à générer” / erreurs. |
| `packages/map_core/lib/src/validation/validators.dart` | Validation `MapData`, `EnvironmentLayer`, `MapPlacedElement` | Valide `targetTileLayerId`, masks, placed elements. Bon garde-fou. |
| `packages/map_core/lib/src/models/map_data.dart` | `MapData`, `MapPlacedElement` | `MapPlacedElement` est déjà le bon conteneur appliqué : id, layerId, elementId, pos, applyCollision, animation/behaviors. |
| `packages/map_editor/lib/src/application/use_cases/environment_generator_use_cases.dart` | Génération déterministe de candidats | Déjà pur côté éditeur, non-mutant, basé sur mask/params/seed/preset. Bon pour preview. |
| `packages/map_editor/lib/src/application/use_cases/environment_generator_apply_use_cases.dart` | Application candidates -> `MapPlacedElement` + `generatedPlacementIds` | Transactionnel, sépare candidats temporaires et placements persistés. Bon socle Generate. |
| `packages/map_editor/lib/src/application/use_cases/environment_generator_clear_use_cases.dart` | Clear generated placements | Supprime les placements référencés, pas le masque. Bonne frontière. |
| `packages/map_editor/lib/src/application/use_cases/environment_generator_regenerate_use_cases.dart` | Regenerate / shuffle seed | Confirme seed comme mécanisme de reproduction/régénération. |
| `packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart` | Peinture/effacement du masque | Bon : mutation pure, index `y * width + x`, compatible undo via map mutation. |
| `packages/map_editor/lib/src/application/models/environment_area_generation_readiness.dart` | Readiness generate | Déjà proche du futur statut “Prêt à générer”. |
| `packages/map_editor/lib/src/application/services/placed_element_instance_indexer.dart` | Indexation/sync `MapPlacedElement` | Important pour cohérence avec TileLayer et sélection. À ne pas dupliquer dans Environment Studio. |
| `packages/map_editor/lib/src/features/environment_studio/environment_studio_workspace.dart` | Workspace preset/catalogue | Existe comme studio, mais surtout orienté catalogue/preset, pas encore canvas map-centric dominant. |
| `packages/map_editor/lib/src/ui/panels/environment_layer_inspector_panel.dart` | UI actuelle de l’application map | Contient déjà zone, masque, generate, clear, regenerate, shuffle, add/delete individuel. Mais c’est enfoui dans inspector, pas un workflow studio clair. |
| `packages/map_editor/lib/src/ui/canvas/map_canvas.dart` | Interactions map | Peinture masque et add/delete générés passent déjà par la map réelle. Bon signal pour la vision. |
| `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart` | Rendu terrain, tiles, placed elements, mask overlay | Déjà capable d’afficher map réelle + mask + placed elements. Base réutilisable. |
| `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` | Orchestration editor | Beaucoup de logique Environment déjà là. Risque de grossir encore. Besoin de read models/services avant nouvelle UI. |
| `packages/map_editor/lib/src/features/editor/state/editor_state.dart` | État editor | `selectedEnvironmentAreaId`, `environmentMaskEditMode`, dirty state existent. Pas encore d’état preview transient riche. |
| `packages/map_editor/lib/src/features/editor/application/project_session_controller.dart` | Load/save project/map/session | Confirme working copy + dirty + save manifest. |
| `packages/map_editor/lib/src/features/editor/application/map_editing_controller.dart` | Mutations map, undo/redo, snapshots | Bon point d’intégration pour Generate/Apply en état de travail. |
| `packages/map_runtime/lib` | Runtime Flame | Références à `MapPlacedElement`, surfaces, paths. EnvironmentLayer no-op ou pass-through selon rapports. Runtime ne doit pas régénérer. |
| `packages/map_gameplay/lib/src/gameplay_world_state.dart` | Collisions/triggers runtime gameplay | Consomme `MapPlacedElement` pour comportements et collisions logiques. Confirme intérêt de persister placements générés comme objets map. |

### Tests existants pertinents

| Test | Couverture utile |
|---|---|
| `packages/map_core/test/environment_core_models_test.dart` | Invariants `EnvironmentPreset`, `EnvironmentAreaMask`, `EnvironmentArea`. |
| `packages/map_core/test/environment_layer_content_json_codec_test.dart` | Sérialisation EnvironmentLayerContent. |
| `packages/map_core/test/environment_layer_map_layer_integration_test.dart` | Intégration `MapLayer.environment`. |
| `packages/map_core/test/environment_preset_json_codec_test.dart` | Sérialisation preset. |
| `packages/map_core/test/environment_preset_diagnostics_test.dart` | Diagnostics presets. |
| `packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart` | CRUD areas via inspector/use cases. |
| `packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart` | Brush mask + canvas routing. |
| `packages/map_editor/test/environment_studio/environment_generator_deterministic_core_test.dart` | Déterminisme génération. |
| `packages/map_editor/test/environment_studio/environment_generator_apply_candidates_test.dart` | Application transactionnelle candidates -> placements. |
| `packages/map_editor/test/environment_studio/environment_generate_button_wiring_test.dart` | Bouton generate dans map. |
| `packages/map_editor/test/environment_studio/environment_generated_placements_clear_test.dart` | Clear placements générés. |
| `packages/map_editor/test/environment_studio/environment_regenerate_shuffle_test.dart` | Regenerate/shuffle seed. |
| `packages/map_editor/test/environment_studio/environment_golden_slice_workflow_test.dart` | Workflow golden slice. |
| `packages/map_editor/test/map_grid_painter_test.dart` | Rendu canvas, placed elements, previews proches. |

### Rapports existants pertinents

Les rapports `reports/forest/environment_studio_lot_1_*` à `lot_29_*` existent. Points clés :

- Lot 1 : décision architecture V0, déjà proche de la vision actuelle.
- Lots 2-8 : modèles core, codecs, diagnostics.
- Lots 9-18 : workspace/preset browser/édition/sauvegarde manifest en mémoire.
- Lots 19-22 : EnvironmentLayer, target tile layer, areas, mask brush.
- Lots 23-27 : génération déterministe, apply, generate button, clear, regenerate/shuffle.
- Lots 28-29 : golden slice hardening/final validation.

Conclusion audit : **le chantier de 40 lots a déjà mangé une bonne partie du domaine**. Il ne faut pas recommencer. Il faut consolider et remonter l’UX.

## 3. Vision proposée reformulée

Vision saine reformulée :

> Environment Studio devient le cockpit créateur d’une application d’environnement sur une carte : choisir la carte, choisir la recette, peindre la zone autorisée, prévisualiser sans mutation, générer dans l’état de travail, puis sauvegarder la map/projet via le save flow existant.

Ce n’est pas :

- un éditeur de tiles ;
- un éditeur de paths ;
- un éditeur de props manuel complet ;
- un moteur runtime procédural ;
- un nouveau système d’assets ;
- un clone du Map Editor avec une UI plus verte.

Le mockup est bon comme intention : canvas dominant, map réelle, masque visible, palette lisible, inspector créateur. Il est dangereux comme spec complète si on tente tout d’un coup.

## 4. Verdict sur la cohérence produit

**Oui, mais réduire.**

Produit : cohérent avec PokeMap no-code. La personne crée une forêt sur une carte, pas une structure JSON. La séparation carte / preset / zone / masque / génération est compréhensible.

Ce qui est fort :

- Le mental model “je peins sur Selbrume” est meilleur que “je configure un layer obscur”.
- Les mots métier existent déjà : preset, zone, masque, générer, placements.
- La visualisation directe évite les allers-retours.

Ce qui est fragile :

- Trop d’actions : Prévisualiser, Générer, Régénérer, Shuffle, Effacer, Appliquer, Sauvegarder. Si tout est visible sans hiérarchie, UI anxiogène.
- Palette en inspector peut redevenir technique si elle expose `elementId`, `tilesetId`, ids layer.
- “Apply” risque d’être incompris si l’app a déjà un bouton “Save”.

Recommandation UX :

- V1 affiche trois actions principales : **Prévisualiser**, **Générer dans la carte**, **Sauvegarder**.
- `Régénérer`, `Shuffle`, `Effacer placements` restent secondaires.
- “Appliquer” doit être évité si `Générer dans la carte` veut déjà dire mutation de working copy.

## 5. Verdict sur la cohérence architecture

**Oui, et le repo l’a déjà choisi implicitement.**

Architecture actuelle alignée :

- Preset global : `ProjectManifest.environmentPresets`.
- Application map : `MapLayer.environment` -> `EnvironmentLayerContent` -> `EnvironmentArea`.
- Masque : `EnvironmentArea.mask`.
- Seed/overrides/params : `EnvironmentArea.seed`, `paramsOverride`.
- Résultat appliqué : `MapData.placedElements` + `EnvironmentArea.generatedPlacementIds`.
- Runtime/gameplay : consommer `MapPlacedElement`, pas relancer le générateur.

Point d’attention : la génération pure vit actuellement dans `map_editor`, pas `map_core`. Les rapports Lot 23 justifient cela pour éviter de polluer `map_core` trop tôt avec les dépendances manifest/ProjectElement. C’est acceptable V1. À terme, extraire un noyau pur vers `map_core` serait sain seulement si la runtime ou des scripts headless doivent générer. Pas maintenant.

Risque architectural principal : `EditorNotifier` accumule trop de responsabilités. La prochaine UI map-centric ne doit pas ajouter 1000 lignes dedans. Il faut créer des read models/services de présentation.

## 6. Modèle de données recommandé

### `EnvironmentPreset`

- Responsabilité : recette globale.
- Où : `map_core`, persisté dans `ProjectManifest.environmentPresets`.
- Map-specific : non.
- Contient : palette, params par défaut, template/category, sortOrder.
- Invariants : id non vide/unique, palette non vide, weights >= 1, params unit interval, items référencent des éléments valides via diagnostics.
- Avis : déjà bon.

### `EnvironmentPaletteItem`

- Responsabilité : entrée générable d’une recette.
- Où : `map_core`, dans `EnvironmentPreset`.
- Persisté : oui.
- Map-specific : non.
- Contient : `elementId`, `weight`, `collisionMode`, tags.
- Invariants : `elementId` non vide, weight >= 1, tags non vides.
- Avis : bon. Pour UI, afficher nom/thumbnail/catégorie, pas l’id brut en premier.

### `EnvironmentLayerContent`

- Responsabilité : conteneur map-specific des applications d’environnement.
- Où : `map_core`, payload de `MapLayer.environment`.
- Persisté : oui dans map JSON.
- Map-specific : oui.
- Contient : `targetTileLayerId`, `areas`.
- Invariants : target absent ou `TileLayer` existant, pas self-target, areas valides.
- Avis : meilleur emplacement actuel pour l’application. Garder.

### `EnvironmentArea`

- Responsabilité : application d’un preset à une zone de carte.
- Où : `map_core`, dans `EnvironmentLayerContent`.
- Persisté : oui.
- Map-specific : oui.
- Contient : id, name, presetId, mask, seed, paramsOverride, generatedPlacementIds.
- Invariants : presetId non vide, mask dimensions = map size via validator, generatedPlacementIds propres.
- Avis : c’est le modèle clef. Il correspond exactement au concept “application de preset sur map”.

### `EnvironmentAreaMask`

- Responsabilité : entrée auteur “où générer”.
- Où : `map_core`, dans `EnvironmentArea`.
- Persisté : oui.
- Map-specific : oui.
- Format actuel : grille booléenne row-major.
- Invariants : width > 0, height > 0, `cells.length == width * height`.
- Avis : garder V1. Simple, testable, compatible undo/redo, diagnostics, génération déterministe.
- Limite : taille JSON sur très grandes maps. Pas urgent. Compression spans/bitmap plus tard seulement si mesure réelle.

### `EnvironmentGeneratedPlacementCandidate`

- Responsabilité : résultat temporaire de preview/génération avant mutation.
- Où : `map_editor` V1.
- Persisté : non.
- Map-specific : oui, transient.
- Invariants : ids déterministes, target layer, elementId valides, pos/footprint in-bounds.
- Avis : bon pour Preview. Ne pas stocker dans core tant que runtime ne génère pas.

### `MapPlacedElement`

- Responsabilité : résultat appliqué et consommable.
- Où : `map_core`, dans `MapData.placedElements`.
- Persisté : oui.
- Map-specific : oui.
- Invariants : id unique, layerId tile target, elementId existant, footprint valide, applyCollision explicite.
- Avis : utiliser pour V1. C’est le pont le plus simple vers rendu, collision, gameplay.

### `generatedPlacementIds`

- Responsabilité : rattacher les placements appliqués à l’area qui les a produits.
- Où : `EnvironmentArea`.
- Persisté : oui.
- Map-specific : oui.
- Avis : nécessaire. C’est ce qui permet clear/regenerate sans supprimer les objets manuels.

## 7. Flux UX recommandé

1. Ouvrir Environment Studio.
2. Si aucun projet : écran vide “Ouvrez un projet”.
3. Choisir carte cible. Par défaut : map active si elle existe.
4. Choisir ou créer EnvironmentLayer. UI doit dire “Application d’environnement”, pas “Layer id”.
5. Choisir preset.
6. Créer ou sélectionner zone.
7. Peindre le masque sur la vraie map.
8. Prévisualiser : candidats temporaires affichés, aucune mutation.
9. Ajuster densité, bords, seed, palette.
10. Générer dans la carte : écrit `MapPlacedElement` + `generatedPlacementIds` dans working copy.
11. Inspecter / supprimer / régénérer.
12. Sauvegarder : save flow existant écrit disque.
13. Revenir modifier : masque + params + seed + placements persistés rechargés.

États UI nécessaires :

- Aucun projet : pas de canvas.
- Aucune carte : picker map en état requis.
- Aucun preset : palette/brush disabled.
- Pas d’EnvironmentLayer : CTA “Créer une application d’environnement sur cette carte”.
- Pas d’area : CTA “Ajouter une zone”.
- Masque vide : preview/generate disabled ou warning clair.
- Preview dirty : paramètres/masque changés depuis la dernière preview.
- Génération prête : statut vert.
- Placements existants : statut “Déjà généré”, actions régénérer/effacer visibles.
- Erreurs : preset manquant, target layer manquant, élément introuvable, tileset mismatch, out-of-bounds.
- Sauvegarde nécessaire : s’appuyer sur dirty global.

## 8. Preview / Generate / Apply / Save : frontières recommandées

### Preview

Définition : calcule des `EnvironmentGeneratedPlacementCandidate` temporaires et les affiche en overlay.

- Ne modifie pas `MapData`.
- Ne modifie pas `ProjectManifest`.
- Ne crée pas `MapPlacedElement`.
- Peut être recalculé automatiquement ou par bouton.
- Peut être invalidé par changement mask/preset/params/seed/map.

### Generate

Définition recommandée : applique le preview ou recalcule puis applique dans la working copy.

- Crée/remplace des `MapPlacedElement`.
- Met à jour `EnvironmentArea.generatedPlacementIds`.
- Marque la map dirty via `_applyMapMutation`.
- Ne sauvegarde pas disque.

Nom UI conseillé : **Générer dans la carte**.

### Apply

Recommandation : éviter en V1.

Si `Apply` existe, il doit vouloir dire “prendre le preview temporaire et le transformer en placements de working copy”. Mais c’est exactement `Generate` si preview est optionnel. Deux verbes doublons = confusion.

### Save

Définition : écrit disque via save flow existant.

- Persiste map/project.
- Ne régénère rien.
- Ne change pas seed.
- Ne recalcule pas les placements.

## 9. Collisions, assets et runtime

### Collisions

V0 recommandé :

- `EnvironmentPaletteItem.collisionMode` pilote `MapPlacedElement.applyCollision`.
- `ProjectElementEntry.collisionProfile` donne la géométrie quand elle existe.
- Pas de nouveau système de collision Environment.

Pourquoi :

- `MapPlacedElement` est déjà validé et consommé.
- `map_gameplay` connaît les placed elements/triggers.
- `map_core` a déjà `ElementCollisionProfile`.

À éviter :

- Peindre une `CollisionLayer` séparée en parallèle des arbres.
- Copier des collisions dans des tiles invisibles.
- Stocker un bool global “collides” sans lien avec le profil élément.

### Assets

V1 recommandé :

- Palette item référence `ProjectElementEntry.elementId`.
- `ProjectElementEntry` référence déjà tileset/source/collision.
- L’UI affiche thumbnail + nom humain + poids + collision.

À éviter :

- Nouveau `assetId` Environment.
- Chemins image directs dans le preset.
- Deuxième système de sprites pour les props environnementaux.

### Runtime

V1 recommandé :

- Runtime lit `MapPlacedElement`.
- Runtime ignore ou utilise `EnvironmentLayer` seulement comme metadata auteur.
- Runtime ne relance jamais le générateur au chargement.

Pourquoi stocker les placements générés :

- Stabilité éditoriale : changement d’algorithme ne modifie pas silencieusement les maps.
- Débug simple : un arbre existe comme instance inspectable.
- Runtime simple : rend et collide comme tout placed element.
- Clear/regenerate possible via `generatedPlacementIds`.

Seed + mask seuls ne suffisent pas pour V1. Ils sont bons pour régénérer, pas pour représenter l’état final du jeu.

## 10. Risques et mitigations

| Risque | Gravité | Probabilité | Mitigation |
|---|---:|---:|---|
| Confusion preset vs application map | Haute | Haute | UI : deux zones séparées. “Recette” vs “Sur cette carte”. Données : `EnvironmentPreset` vs `EnvironmentArea`. |
| Preview qui mute les données | Haute | Moyenne | DTO transient + tests “preview preserves map identity/data”. |
| Génération non déterministe | Haute | Moyenne | Tests snapshot candidats avec seed/mask/params/version. Stocker placements appliqués. |
| Modèle trop générique trop tôt | Haute | Haute | Garder V1 : preset, area, mask, placed elements. Pas biome engine. |
| UI trop dense | Moyenne | Haute | Primary actions limitées. Sections repliables. Advanced controls cachés. |
| Performance grandes maps | Moyenne | Moyenne | Bool mask V1, mesurer avant compression. Preview throttle/debounce. Dirty region plus tard. |
| Collisions mal intégrées | Haute | Moyenne | Réutiliser `ElementCollisionProfile` + `MapPlacedElement.applyCollision`. Tests gameplay/runtime ciblés plus tard. |
| Runtime ne sait pas consommer EnvironmentLayer | Moyenne | Moyenne | Ne pas dépendre d’EnvironmentLayer runtime. Consommer `MapPlacedElement`. |
| Duplication avec Path/Surface/Painter | Moyenne | Haute | Réutiliser `MapCanvas` rendering/read models. Ne pas recoder un canvas dans Environment Studio. |
| Dette save flow | Haute | Moyenne | Generate = working copy dirty ; Save = disque. Tests project session. |
| Migration JSON | Haute | Basse/Moyenne | Éviter schema change maintenant. Utiliser modèles existants. Versionner plus tard si compression mask. |
| Deuxième Map Editor | Haute | Haute | Frontière dure : seulement zones env, presets, preview, placements générés. Pas tile/path/event/collision editing général. |
| `EditorNotifier` obèse | Moyenne | Haute | Extraire read models/resolvers côté application/presentation avant grosse UI. |
| Suppression d’objets manuels | Haute | Moyenne | Toujours filtrer par `generatedPlacementIds`. Tests topmost + manual unaffected. |

## 11. Roadmap par micro-lots

### Environment-30 — Map-centric Environment Workspace Read Model

- Objectif : produire un read model unique pour l’écran map-centric.
- Fichiers probables : `packages/map_editor/lib/src/application/models/environment_workspace_read_model.dart`, `environment_studio_workspace.dart`, tests dédiés.
- Tests : aucun projet, aucune carte, map active, env layer absent, preset absent, area active, generated ids.
- Non-objectifs : aucun nouveau widget lourd, aucune mutation.
- Risque principal : coupler trop tôt à Riverpod/widget.
- Validation : read model pur testé.

### Environment-31 — Target Map and Environment Application Selector

- Objectif : choisir carte cible + EnvironmentLayer/area existants sans jargon.
- Fichiers probables : workspace + petit widget selector.
- Tests : sélection map active, création CTA disabled/enabled.
- Non-objectifs : pas de peinture.
- Risque : exposer layerId.
- Validation : UI ne montre pas d’id technique comme action principale.

### Environment-32 — Preview State V0

- Objectif : état transient des candidats de preview, séparé de `MapData`.
- Fichiers probables : application model + notifier method ou controller léger.
- Tests : preview ne modifie pas map/project, invalidation si mask/params changent.
- Non-objectifs : pas d’apply.
- Risque : mélanger preview avec `generatedPlacementIds`.
- Validation : map equality avant/après preview.

### Environment-33 — Canvas Overlay Controls V0

- Objectif : canvas dominant avec toggles mask/generated/collisions/brush.
- Fichiers probables : `MapCanvas`, `MapGridPainter`, workspace controls.
- Tests : painter overlay flags, brush cursor.
- Non-objectifs : minimap, before/after.
- Risque : rendre MapCanvas encore trop gros.
- Validation : flags testés, pas de nouvelle logique métier dans painter.

### Environment-34 — Brush Size and Opacity V0

- Objectif : taille pinceau > 1 et opacité masque UI.
- Fichiers probables : `environment_mask_use_cases.dart`, editor state, inspector/workspace controls.
- Tests : brush disk/square défini, bornes, undo stroke.
- Non-objectifs : brushes custom.
- Risque : comportement flou aux bords.
- Validation : tests de cellules exactes.

### Environment-35 — Generate from Preview Boundary

- Objectif : clarifier Preview vs Generate ; Generate applique candidats ou recalcule de façon déterministe.
- Fichiers probables : generator/apply use cases, notifier orchestration.
- Tests : preview puis generate même ids ; generate sans preview possible ; dirty true.
- Non-objectifs : save disque.
- Risque : double source de vérité.
- Validation : candidats preview = placements appliqués.

### Environment-36 — Creator Inspector V0

- Objectif : inspector orienté créateur : densité, variation, bords, seed, palette lisible.
- Fichiers probables : widgets environment studio, presentation helpers.
- Tests : labels FR/no-code, warnings.
- Non-objectifs : édition complète de preset depuis cet inspector.
- Risque : dupliquer preset editor.
- Validation : palette affiche noms et thumbnails, ids secondaires.

### Environment-37 — Generated Placement Management V0

- Objectif : add/delete individuel visible, clear, regenerate, shuffle dans workflow studio.
- Fichiers probables : resolver hover déjà présent dans working tree, painter, inspector/workspace.
- Tests : manual unaffected, topmost generated deletion, preview hover.
- Non-objectifs : prop editor manuel avancé.
- Risque : deuxième editor de props.
- Validation : seules instances référencées `generatedPlacementIds` modifiables.

### Environment-38 — Save Flow Hardening

- Objectif : messages clairs “généré mais non sauvegardé”, save disque sans régénérer.
- Fichiers probables : project session/editor notifier tests.
- Tests : generate marks dirty, save clears dirty, reload preserves placements/mask/seed.
- Non-objectifs : cloud/autosave.
- Risque : confusion Apply/Save.
- Validation : golden save/reload.

### Environment-39 — Runtime Read-only Golden Slice

- Objectif : vérifier runtime rend/collide les `MapPlacedElement` issus Environment.
- Fichiers probables : map_runtime tests/fixtures.
- Tests : generated tree rendered as placed element, collision respected if profile/applyCollision.
- Non-objectifs : runtime generation.
- Risque : runtime ignore placed elements layer target nuance.
- Validation : smoke runtime with generated placement.

### Environment-40 — UX Polish and Copy Pass

- Objectif : retirer jargon, polish macOS, statuts.
- Fichiers probables : workspace/widgets/presentation labels.
- Tests : smoke UI + golden-ish text assertions.
- Non-objectifs : nouvelle architecture.
- Risque : pure cosmétique qui cache dette.
- Validation : parcours créateur complet sans ids techniques principaux.

## 12. Points à trancher avec l’humain

1. Le bouton principal doit-il s’appeler **Générer** ou **Générer dans la carte** ? Je recommande le second.
2. Faut-il garder un bouton **Prévisualiser** manuel ou preview auto debounce ? Je recommande manuel V1, auto plus tard.
3. Une map peut-elle avoir plusieurs EnvironmentLayers ou un seul “Environnements” par défaut ? Je recommande supporter plusieurs techniquement, mais UI propose un layer par défaut.
4. Brush V1 : carré ou cercle ? Tests plus simples en carré ; mockup montre cercle. À décider.
5. Palette dans inspector : éditer les poids du preset global ou override local par area ? Je recommande override local plus tard, pas V1.
6. Nom utilisateur : “Zone”, “Application”, “Bosquet” ? Je recommande “Zone” dans V1.
7. Doit-on masquer `targetTileLayerId` derrière “Layer de rendu” automatique ? Oui pour no-code.

## 13. Critique du prompt et de la vision

La vision est bonne. Le prompt est utile. Mais il pousse vers trop de surface UI en une fois.

Critiques :

- Le mockup donne envie de faire la refonte visuelle avant de verrouiller le read model. Mauvais ordre.
- La liste de contrôles mélange V1 et V2 : minimap, before/after, opacité, collisions visibles, palette weights, apply/save. Trop pour un premier lot.
- “Appliquer” est conceptuellement dangereux dans une app qui a déjà “Sauvegarder”.
- “Éléments générés visibles en overlay” est ambigu : dans le repo, les éléments générés sont de vrais `MapPlacedElement`, pas juste overlay. Il faut distinguer preview overlay vs placements appliqués.
- Le risque “deuxième Map Editor” est réel. Il faut une règle produit : Environment Studio ne modifie jamais tiles/path/events/collisions générales directement.

Ce qu’il faut absolument éviter :

- Nouveau modèle persistant parallèle à `MapPlacedElement`.
- Génération runtime à chaque chargement.
- Compression mask prématurée.
- Refonte globale shell + domaine dans le même lot.
- Ajouter encore beaucoup de logique dans `EditorNotifier`.
- Exposer `layerId`, `targetTileLayerId`, `elementId` comme vocabulaire principal.

## 14. Auto-review finale

- [x] Je n’ai modifié aucun fichier de production dans cette review. Note : le working tree contenait déjà des modifications de production avant ce rapport.
- [x] Je n’ai fait aucun commit.
- [x] J’ai audité les fichiers réellement liés à Environment Studio.
- [x] J’ai distingué preset d’environnement et application sur map.
- [x] J’ai traité la question du masque.
- [x] J’ai traité la question des placements générés.
- [x] J’ai traité la question preview/generate/apply/save.
- [x] J’ai traité la question des collisions.
- [x] J’ai traité la question du runtime.
- [x] J’ai proposé une roadmap en micro-lots.
- [x] J’ai critiqué la vision et pas seulement résumé.
- [x] J’ai listé les risques.
- [x] J’ai indiqué le prochain lot recommandé.

## Git status final

```text
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart
?? packages/map_editor/lib/src/application/services/environment_generated_placement_hover_resolver.dart
?? packages/map_editor/lib/src/ui/canvas/tileset_grid_metrics.dart
?? packages/map_editor/test/environment_studio/environment_generated_placement_hover_preview_test.dart
?? packages/map_editor/test/tileset_grid_metrics_test.dart
?? reports/environment_studio/environment_studio_map_centric_workflow_review.md
```
