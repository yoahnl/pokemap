# Lot TSX-4 — Build Surface preset from selected TSX animations V0

## 1. Verdict

V0 implémentée.

Surface Studio peut maintenant créer un `ProjectSurfacePreset` depuis des animations TSX sélectionnées, uniquement après un mapping explicite `SurfaceVariantRole -> ProjectSurfaceAnimation.id`. Le preset est ajouté au catalogue de travail en mémoire via le flux Surface Studio existant ; aucune sauvegarde disque, aucune mutation directe du `ProjectManifest`, aucun gameplay et aucun appel IA / PixelLab / MCP ne sont introduits.

Context Mode : indisponible dans cet environnement. La commande `ctx stats` retourne `zsh:1: command not found: ctx`.

## 2. Audit initial

Commande initiale :

```text
pwd
/Users/karim/Project/pokemonProject
```

`git status --short --untracked-files=all` initial :

```text
 M packages/map_runtime/test/battle_overlay_component_test.dart
 M packages/map_runtime/test/npc_runtime_presence_test.dart
 M packages/map_runtime/test/playable_map_game_input_test.dart
 M packages/map_runtime/test/trainer_battle_request_test.dart
 M packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
```

`git diff --stat` initial :

```text
 packages/map_runtime/test/battle_overlay_component_test.dart    | 4 +---
 packages/map_runtime/test/npc_runtime_presence_test.dart        | 3 +--
 packages/map_runtime/test/playable_map_game_input_test.dart     | 3 +--
 packages/map_runtime/test/trainer_battle_request_test.dart      | 2 +-
 packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart | 5 ++---
 5 files changed, 6 insertions(+), 11 deletions(-)
```

Ces changements `map_runtime/test/*` étaient préexistants et hors périmètre. Ils n’ont pas été modifiés.

Fichiers audités :

```text
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_animated_tileset_parser.dart
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_surface_animation_importer.dart
packages/map_editor/lib/src/features/surface_studio/importers/
packages/map_editor/test/surface_studio/tiled_tsx_animated_tileset_parser_test.dart
packages/map_editor/test/surface_studio/tiled_tsx_surface_animation_importer_test.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_preset_generator.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_preset_creation_section.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_role_assignment_draft.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_role_mapping_editor.dart
packages/map_editor/lib/src/features/surface_studio/schema/surface_studio_schema_panel.dart
packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart
packages/map_core/lib/src/models/surface.dart
packages/map_core/lib/src/models/surface_catalog.dart
packages/map_core/lib/src/operations/surface_studio_read_model.dart
reports/surface/surface_studio_tiled_tsx_animation_browser_v0.md
```

Réponses d’audit :

1. TSX-3 a livré un browser `TiledTsxAnimationBrowser` dans le drawer avancé, avec recherche, sélection locale multi-animation et preview `TiledTsxSurfaceAnimationPreview`.
2. Le browser d’animations TSX existe dans `packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_animation_browser.dart`.
3. La sélection TSX est un `Set<String>` local `_selectedIds` dans le widget ; elle peut notifier `onSelectionChanged` mais ne mute pas le catalogue.
4. Aucun modèle persistant ne représente cette sélection. C’est volontairement un état UI local.
5. La preview d’animation TSX existe et lit les `SurfaceAnimationFrame.tileRef.column,row` exacts.
6. Il n’existait pas de mapping `role -> animation` dans l’UI TSX.
7. `ProjectSurfacePreset` référence ses animations via `SurfaceVariantAnimationRefSet`, contenant des `SurfaceVariantAnimationRef(role, animationId)`.
8. Le modèle core d’association est `SurfaceVariantAnimationRef`.
9. Le générateur vertical atlas n’est pas réutilisable pour le build TSX car il reconstruit des ids d’animations depuis une convention d’atlas vertical. Seule sa fonction `surfaceStudioAppendPresetToWorkCatalog(...)` est réutilisée.
10. Un générateur spécifique TSX était nécessaire pour construire un preset depuis des ids d’animations arbitraires déjà importés.
11. L’action est intégrée au browser TSX sous forme de bouton `Créer une surface depuis la sélection`.
12. L’ajout au work catalog passe par `surfaceStudioAppendPresetToWorkCatalog(...)` puis `onSurfaceCatalogChanged`, sans sauvegarde disque.

## 3. Modèles / fonctions ajoutés

Fichier ajouté :

```text
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_surface_preset_draft.dart
```

API ajoutée :

```text
TiledTsxSurfacePresetDraft
TiledTsxSurfacePresetDraftValidation
validateTiledTsxSurfacePresetDraft(...)
buildTiledTsxSurfacePresetFromDraft(...)
```

Le draft contient :

```text
id
name
categoryId
sortOrder
roleAnimationIds: Map<SurfaceVariantRole, String>
```

## 4. Validation du draft

Règles implémentées :

```text
- id obligatoire ;
- name obligatoire ;
- duplicate preset id interdit ;
- isolated / Plein(center) obligatoire ;
- chaque animation référencée doit exister dans ProjectSurfaceCatalog.animations ;
- rôles non mappés autorisés ;
- warning si surface partielle ;
- aucune animation ni rôle n’est inventé.
```

Exemples d’erreurs :

```text
Identifiant surface obligatoire.
Nom surface obligatoire.
Plein(center) obligatoire.
Identifiant de preset déjà utilisé.
Animation inconnue pour Plein : missing-animation.
```

## 5. Construction du ProjectSurfacePreset

`buildTiledTsxSurfacePresetFromDraft(...)` produit :

```text
ProjectSurfacePreset(
  id: draft.id.trim(),
  name: draft.name.trim(),
  categoryId: draft.categoryId?.trim() non vide,
  sortOrder: draft.sortOrder,
  variantAnimations: SurfaceVariantAnimationRefSet(...)
)
```

Les refs sont ordonnées selon `standardSurfaceVariantRoleOrder`.

Le preset ne contient que les rôles explicitement mappés. Les rôles absents ne sont pas remplacés par un fallback caché.

## 6. Intégration work catalog

`TiledTsxAnimationBrowser` reçoit maintenant :

```text
ProjectSurfaceCatalog? catalog
ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogChanged
```

Quand un preset est validé :

```text
1. validation du draft ;
2. build ProjectSurfacePreset ;
3. append au catalogue de travail via surfaceStudioAppendPresetToWorkCatalog ;
4. callback onSurfaceCatalogChanged(nextCatalog).
```

Le bouton est désactivé si aucune animation n’est sélectionnée ou si aucun callback de changement catalogue n’est fourni. Cela évite une fausse création dans les contextes lecture seule.

## 7. UI ajoutée

Dans `TiledTsxAnimationBrowser` :

```text
- bouton Créer une surface depuis la sélection ;
- formulaire inline Créer une surface depuis animations TSX ;
- champs Identifiant surface / Nom surface / Catégorie / Ordre ;
- mapping manuel par rôle via champs animation id ;
- chips des animations sélectionnées ;
- erreurs et warnings visibles ;
- bouton Créer le preset.
```

Le formulaire reste volontairement V0 : il n’essaie pas de deviner les rôles et n’impose pas encore un drag & drop sophistiqué.

Le browser est devenu scrollable en hauteur et la barre d’actions selection/recherche est responsive pour éviter les overflows dans le drawer avancé.

## 8. Exemple de preset

Exemple testé avec le TSX Pokémon SDK importé :

```text
Preset id = water-tsx-surface
name = Water TSX Surface
isolated -> tech-animations-tile-99
horizontal -> tech-animations-tile-100
```

Résultat :

```text
ProjectSurfacePreset.variantAnimations
- SurfaceVariantRole.isolated : tech-animations-tile-99
- SurfaceVariantRole.horizontal : tech-animations-tile-100
```

`tech-animations-tile-105` n’est pas utilisé comme animation dans le test d’intégration, car `105` est une frame tile id de l’animation 99, pas une animation de base importée par TSX-2.

## 9. Tests

Commande :

```text
cd packages/map_editor && flutter test test/surface_studio/tiled_tsx_animated_tileset_parser_test.dart --no-pub --reporter expanded
```

Sortie finale exacte :

```text
00:00 +7: All tests passed!
```

Commande :

```text
cd packages/map_editor && flutter test test/surface_studio/tiled_tsx_surface_animation_importer_test.dart --no-pub --reporter expanded
```

Sortie finale exacte :

```text
00:00 +7: All tests passed!
```

Commande :

```text
cd packages/map_editor && flutter test test/surface_studio/tiled_tsx_animation_browser_test.dart --no-pub --reporter expanded
```

Sortie finale exacte :

```text
00:01 +7: All tests passed!
```

Commande :

```text
cd packages/map_editor && flutter test test/surface_studio/tiled_tsx_surface_preset_builder_test.dart --no-pub --reporter expanded
```

Sortie finale exacte :

```text
00:00 +5: All tests passed!
```

Commande :

```text
cd packages/map_editor && flutter test test/surface_studio/tiled_tsx_surface_preset_builder_ui_test.dart --no-pub --reporter expanded
```

Sortie finale exacte :

```text
00:01 +1: All tests passed!
```

Commande :

```text
cd packages/map_editor && flutter test test/surface_studio --no-pub --reporter expanded
```

Sortie finale exacte :

```text
00:18 +390: All tests passed!
```

## 10. Analyze

Commande :

```text
cd packages/map_editor && flutter analyze lib/src/features/surface_studio
```

Résultat exact :

```text
Analyzing surface_studio...
No issues found! (ran in 2.2s)
```

## 11. Non-objectifs confirmés

Non faits :

```text
- pas de ProjectSurfacePreset créé automatiquement depuis une simple sélection ;
- pas de rôle Surface deviné ;
- pas de Mistral ;
- pas de PixelLab ;
- pas de MCP ;
- pas de génération d’image ;
- pas de runtime Flame ;
- pas de gameplay ;
- pas de SurfaceLayer gameplay ;
- pas de MapGameplayZone ;
- pas de movementEffect ;
- pas de modification map_gameplay ;
- pas de modification map_runtime ;
- pas de modification map_battle ;
- pas de sauvegarde disque automatique ;
- pas de mutation ProjectManifest directe ;
- pas de modèle Surface parallèle.
```

## 12. Limites restantes

Limites V0 :

```text
- mapping UI par champs texte, pas encore dropdown riche ni drag & drop ;
- preview de preset TSX non spécialisée dans le formulaire ;
- pas encore de picker régional / grouping visuel ;
- pas encore d’assistant optionnel de grouping ;
- le preset créé reste partiel si seuls quelques rôles sont explicitement mappés.
```

## 13. Roadmap suivante

Suite logique :

```text
TSX-5 — Improve TSX region picker / visual grouping UX
```

ou :

```text
TSX-5 — Optional Mistral grouping assistant for TSX animations
```

La priorité produit semble être un mapping UX plus confortable : dropdowns depuis la sélection, mini-previews par animation dans chaque rôle, puis seulement après un assistant IA optionnel pour proposer des groupes.
