# Evidence Pack — NS-SCENES-V1-97

Lot : `NS-SCENES-V1-97 — Cinematic Actor Display Preview Sprite Resolver Prep Contract`  
Date : 2026-06-08  
Demandeur : Karim  
Objectif : Cadrer précisément comment résoudre des sprites acteurs statiques depuis les sources du projet sans modifier de code de production ni démarrer de runtime Flame/gameplay.

## Gate 0 complet

```text
/Users/karim/Project/pokemonProject
main
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
cdd653e5 feat(narrative): auto-commit changes
50d3ca85 remove failures
48d6398d ui: collapse project explorer accordions by default and fix tests
4dbebbfe feat(narrative): auto-commit changes
```

Statut Git initial :
```text
On branch main
Your branch is ahead of 'origin/main' by 2 commits.
  (use "git push" to publish your local commits)

nothing to commit, working tree clean
```

---

## Liste des fichiers lus

Les fichiers suivants ont été consultés pour l'audit et la conception de ce lot :
- [cinematic_actor_display_preview_model.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart)
- [cinematic_asset.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/cinematic_asset.dart)
- [project_manifest.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/project_manifest.dart)
- [map_data.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_data.dart)
- [cinematic_actor_display_preview_overlay.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart)
- [cinematic_tileset_asset_registry.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_tileset_asset_registry.dart)
- [cinematic_map_backdrop_layer_render_plan.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart)
- [playable_map_game.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart)
- [runtime_map_game.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart)
- [player_component.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/player_component.dart)
- [overworld_actor_component.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart)

---

## Notes des sub-agents / passes spécialisées

- **Pass A — Actor Display Read Model Audit** : Le read model de `map_core` est très complet, mais il est indépendant du système de fichiers Flutter. Il fournira la fiche symbolique nécessaire. Un resolver editor-only partagé de `map_editor` consommera ce modèle.
- **Pass B — Character Library Audit** : La fiche personnage (`ProjectCharacterEntry`) lie l'acteur à son `tilesetId`, et définit ses animations `idle` pour chaque direction (`EntityFacing`). La frame d'orientation statique est extraite en sélectionnant l'index 0 de l'animation idle ciblée.
- **Pass C — Appearance Sources Resolution** : Le resolver sélectionne la source d'apparence en cascade : Settings pour le player, data NPC/Trainer pour la MapEntity, et bindings cinématiques pour les CinematicOnly.
- **Pass D — Cache & Asset Resolution Audit** : Réutilisation recommandée de `CinematicTilesetAssetRegistry` (Option A/C). Elle dispose d'une gestion complète du cache PNG sur disque et de la transparence PNG par couleur clé, éliminant les lectures disques superflues dans les méthodes build/paint.
- **Pass E — Static Sprite / Direction Resolver** : Le mapping utilise le facing par défaut ou la métadonnée d'orientation de l'instruction `actorFace`. Aucun minuteur n'est requis.
- **Pass F — Future Overlay Integration** : L'overlay Flutter de placeholders (V1-92) est conservé et intègre le RawImage du sprite découpé à la place du cercle standard.
- **Pass G — Anti-scope Audit** : Garantie d'absence de toute dépendance de map_runtime ou de composants de moteur Flame.
- **Pass H — Tests and Future Validation** : Planification des tests unitaires pures (V1-98) et du golden file de rendu final (V1-99).
- **Pass I — UX and Product Review** : Recommandations sur les étiquettes textuelles et les statuts visuels d'avertissement.

---

## Résultats des recherches rg structurantes

1. **Recherche CinematicActorDisplayPreviewModel** :
   Le read model est défini dans `packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart` et contient les énumérations `CinematicActorDisplayBindingStatus`, `CinematicActorPreviewPositionStatus`, et `CinematicActorPreviewAppearanceStatus`.
2. **Recherche ProjectCharacterEntry** :
   Le personnage est décrit dans `packages/map_core/lib/src/models/project_manifest.dart` à la ligne 827 avec la structure `animations`, `frameWidth`, `frameHeight` et `tilesetId`.
3. **Recherche appearance settings & bindings** :
   Les configurations de liaison apparence/character se trouvent dans `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart` via `UpsertCinematicActorAppearanceBindingCallback`.

---

## Arbitrage final

L'**Option C (Resolver séparé V1-98)** et l'**Option A (Réutilisation de CinematicTilesetAssetRegistry)** sont retenues pour leur modularité, leur performance et leur testabilité unitaire sans démarrer de boucle de jeu ni de widgets complexes.

---

## Hunks complets des roadmaps modifiées

### 1. road_map_scene_builder_authoring.md

```diff
@@ -136,2 +136,3 @@
-| NS-SCENES-V1-97 | Cinematic Actor Display Preview Sprite Resolver Prep Contract | doc-only / architecture-review | Cadrer le futur resolver de sprites statiques apres preview backdrop lisible et triee V1-96 : sources Character Library/player/mapEntity, frames idle, fallback, diagnostics, cache et anti-scope runtime. | Pas de renderer sprite actif, playback, runtime/Flame, actorMove interpolation, pathfinding/collision, mutation Character Library, generation image IA ou donnees Selbrume. | Rapport V1-97, evidence pack, roadmaps. | TODO : contrat sprite resolver editor-only. | Charger trop tot des sprites dans core ; confondre sprite statique et animation runtime ; masquer les placeholders incomplets. | TODO : contrat pret pour afficher des acteurs reconnaissables sans lancer la cinematique. | V1-96-bis. |
+| NS-SCENES-V1-97 | Cinematic Actor Display Preview Sprite Resolver Prep Contract | doc-only / architecture-review | Cadrer le futur resolver de sprites statiques apres preview backdrop lisible et triee V1-96 : sources Character Library/player/mapEntity, frames idle, fallback, diagnostics, cache et anti-scope runtime. | Pas de renderer sprite actif, playback, runtime/Flame, actorMove interpolation, pathfinding/collision, mutation Character Library, generation image IA ou donnees Selbrume. | Rapport V1-97, evidence pack, roadmaps. | DONE : contrat sprite resolver editor-only, diagnostic et tests futures. | Charger trop tot des sprites dans core ; confondre sprite statique et animation runtime ; masquer les placeholders incomplets. | DONE : contrat pret pour afficher des acteurs reconnaissables sans lancer la cinematique. | V1-96-bis. |
+| NS-SCENES-V1-98 | Cinematic Actor Display Preview Sprite Resolver V0 | editor / pure-resolver | Implémenter le resolver purement logique et ses tests unitaires de parité associés sans rendu visuel. | Pas de renderer sprite actif, playback, runtime/Flame, actorMove interpolation, pathfinding/collision, mutation Character Library, generation image IA ou donnees Selbrume. | Resolver, tests unitaires, rapports, roadmaps. | TODO : resolver et tests associés. | Coupler le resolver à la couche UI ; importer map_runtime ; casser les fallbacks de placeholders. | TODO : resolver logique capable d'associer un acteur à ses coordonnées d'atlas et son tileset. | V1-97. |
 
@@ -148,7 +149,21 @@
 
 Limites : V1-94 ne lance toujours pas la cinematique. Aucun runtime, aucun Flame, aucun playback, aucun MapCanvas complet, aucun sprite acteur final.
 
-Prochain lot exact recommande : `NS-SCENES-V1-97 — Cinematic Actor Display Preview Sprite Resolver Prep Contract`.
+Prochain lot exact recommande : `NS-SCENES-V1-98 — Cinematic Actor Display Preview Sprite Resolver V0`.
+
+## Mise a jour V1-97
+
+Statut : `NS-SCENES-V1-97 — Cinematic Actor Display Preview Sprite Resolver Prep Contract` est DONE.
+
+Demande : Karim a demandé d'auditer et cadrer la résolution asynchrone des sprites d'acteurs statiques depuis le ProjectManifest (Character Library, settings.defaultPlayerCharacterId, npc/trainer mapEntity) sans modifier de code produit ni importer de runtime Flame/gameplay.
+
+Decision : Option C (Resolver séparé) et Option A (Réutilisation de CinematicTilesetAssetRegistry) retenues. Les métadonnées symboliques de map_core suffisent à guider la recherche de tilesets. La frame 0 d'une animation idle déterminée par direction sera découpée et mise en cache. Si indisponible, le fallback pastille V1-92 est conservé.
+
+Preuve : Rapport de contrat V1-97 rédigé, diagnostics et tests unitaires V1-98 planifiés, checks anti-scope passés propres.
+
+Limites : Lot documentaire de design-first uniquement. Aucun code produit modifié.
+
+Prochain lot exact recommande : `NS-SCENES-V1-98 — Cinematic Actor Display Preview Sprite Resolver V0`.
 
 ## Mise a jour V1-96 bis
```

### 2. road_map_scenes.md

```diff
@@ -157,15 +157,30 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propre
-| NS-SCENES-V1-97 — Cinematic Actor Display Preview Sprite Resolver Prep Contract | TODO | Cadrer le futur resolver de sprites actor display statique apres preview backdrop lisible et triee V1-96 : sources Character Library/player/mapEntity, frames idle, fallbacks, diagnostics, cache et anti-scope runtime. |
+| NS-SCENES-V1-97 — Cinematic Actor Display Preview Sprite Resolver Prep Contract | DONE | Cadrage documentaire et design-first du futur resolver de sprites d'acteurs statiques. Définition des sources (player settings, npc/trainer mapEntity, cinematicOnly) et de la méthode de résolution de la première frame de l'animation idle. Analyse de la réutilisation de `CinematicTilesetAssetRegistry` pour le chargement d'image asynchrone hors build/paint. Identification des diagnostics et planification des tests V1-98 et Visual Gate V1-99. Aucun code produit modifié, pas de runtime, pas de Flame, pas de playback. |
+| NS-SCENES-V1-98 — Cinematic Actor Display Preview Sprite Resolver V0 | TODO | Implémenter le resolver purement logique et ses tests unitaires de parité associés sans rendu visuel. |
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-97 — Cinematic Actor Display Preview Sprite Resolver Prep Contract`
+`NS-SCENES-V1-98 — Cinematic Actor Display Preview Sprite Resolver V0`
 
-Raison : V1-96-bis apporte la parité de profondeur (Z-Order et boucle de calques inversée) entre le décor et l'overlay des acteurs. Le prochain verrou logique est donc de cadrer le futur resolver de sprites statiques des acteurs (V1-97), tout en conservant les placeholders V1-92 tant que le contrat n'est pas valide.
+Raison : V1-97 a posé le contrat documentaire d'architecture et de diagnostic pour la résolution des sprites. Le prochain verrou logique est d'implémenter le resolver purement logique et ses tests unitaires dans la V1-98, puis le rendu visuel dans la V1-99.
 
-Ordre apres V1-96-bis : `NS-SCENES-V1-97 — Cinematic Actor Display Preview Sprite Resolver Prep Contract`, puis seulement un renderer sprite statique si le contrat V1-97 est valide. Le polish timeline scroll/visibility reste un backlog futur.
+Ordre apres V1-97 : `NS-SCENES-V1-98 — Cinematic Actor Display Preview Sprite Resolver V0`, puis `NS-SCENES-V1-99 — Cinematic Actor Display Preview Sprite Renderer V0` pour le rendu final avec fallback placeholders.
+
+## Mise a jour V1-97
+
+Statut : `NS-SCENES-V1-97 — Cinematic Actor Display Preview Sprite Resolver Prep Contract` est DONE.
+
+Demande : Karim a demandé d'auditer et cadrer la résolution asynchrone des sprites d'acteurs statiques depuis le ProjectManifest (Character Library, settings.defaultPlayerCharacterId, npc/trainer mapEntity) sans modifier de code produit ni importer de runtime Flame/gameplay.
+
+Decision : Option C (Resolver séparé) et Option A (Réutilisation de CinematicTilesetAssetRegistry) retenues. Les métadonnées symboliques de map_core suffisent à guider la recherche de tilesets. La frame 0 d'une animation idle déterminée par direction sera découpée et mise en cache. Si indisponible, le fallback pastille V1-92 est conservé.
+
+Preuve : Rapport de contrat V1-97 rédigé, diagnostics et tests unitaires V1-98 planifiés, checks anti-scope passés propres.
+
+Limites : Lot documentaire de design-first uniquement. Aucun code produit modifié.
+
+Prochain lot exact recommande : `NS-SCENES-V1-98 — Cinematic Actor Display Preview Sprite Resolver V0`.
 
 ## Mise a jour V1-96 bis
```

---

## Sortie git diff --check

*(Sortie vide, aucun marqueur de conflit ni d'espace terminal indésirable)*
```text
```

---

## Sortie git diff --stat

```text
 reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md | 19 ++++++++++++++++--
 reports/narrativeStudio/scenes/road_map_scenes.md  | 23 ++++++++++++++++++----
 2 files changed, 36 insertions(+), 6 deletions(-)
```

---

## Sortie git diff --name-only

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

---

## Sortie git status --short --untracked-files=all final

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_97_cinematic_actor_display_preview_sprite_resolver_prep_contract.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_97_evidence_pack.md
```

---

## Auto-review critique

1. **Est-ce que V1-97 a modifié du code produit ?** Non.
2. **Est-ce que V1-97 a modifié packages/ ?** Non.
3. **Est-ce que V1-97 a créé un test ?** Non.
4. **Est-ce que V1-97 a généré un screenshot ?** Non.
5. **Est-ce que V1-97 a rendu un sprite acteur ?** Non.
6. **Est-ce que V1-97 a chargé une image acteur ?** Non.
7. **Est-ce que V1-97 a modifié l’overlay V1-92 ?** Non.
8. **Est-ce que V1-97 a modifié le backdrop V1-96-bis ?** Non.
9. **Est-ce que V1-97 a utilisé runtime/Flame ?** Non.
10. **Est-ce que V1-97 a utilisé GameState ?** Non.
11. **Est-ce que V1-97 a ajouté du playback ?** Non.
12. **Est-ce que V1-97 a comparé les sources player/mapEntity/cinematicOnly ?** Oui.
13. **Est-ce que V1-97 a cadré ProjectCharacterEntry ?** Oui.
14. **Est-ce que V1-97 a cadré l’asset resolution ?** Oui.
15. **Est-ce que V1-97 a cadré idle/direction frame ?** Oui.
16. **Est-ce que V1-97 a cadré les fallbacks placeholders ?** Oui.
17. **Est-ce que V1-97 a défini les diagnostics futurs ?** Oui.
18. **Est-ce que V1-97 a défini les tests V1-98 ?** Oui.
19. **Est-ce que V1-97 a défini la Visual Gate V1-99 ?** Oui.
20. **Est-ce que V1-97 a modifié les roadmaps ?** Oui.
21. **Est-ce que l’Evidence Pack est complet ?** Oui.
22. **Quel est le prochain lot exact recommandé ?** `NS-SCENES-V1-98 — Cinematic Actor Display Preview Sprite Resolver V0`.
