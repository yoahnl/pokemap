# NS-SCENES-V1-94 — Cinematic Map Backdrop Layer Fidelity Renderer V0

## 1. Résumé exécutif

V1-94 rend le décor cinematic beaucoup plus proche du Map Editor. Le Cinematic Builder ne se limite plus au rendu bitmap des `TileLayer` : il sait maintenant préparer et afficher un plan multi-layer statique avec terrain, chemins, TileLayer background/foreground, surfaces, éléments placés et placements générés par l'environnement quand les données/assets existent.

V1-94 ne lance toujours pas la cinématique. Aucun runtime, aucun Flame, aucun playback, aucun MapCanvas complet.

## 2. Gate 0

Gate 0 a été exécuté avant modification dans `/Users/karim/Project/pokemonProject`.

Sorties observées :

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
<aucune sortie avant modifications V1-94>

git diff --stat
<aucune sortie avant modifications V1-94>

git diff --name-only
<aucune sortie avant modifications V1-94>
```

Le log HEAD lu pendant le lot commence par :

```text
76a312ec feat(narrative): auto-commit changes
9c5db6f0 feat(narrative): auto-commit changes
eb05d109 feat(narrative): auto-commit changes
```

## 3. Fichiers lus

- `AGENTS.md`
- `skills/README.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `skills/requesting-code-review/SKILL.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_93_cinematic_map_backdrop_layer_fidelity_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_93_evidence_pack.md`
- fichiers cinematic existants V1-88/V1-89/V1-92 dans `packages/map_editor/lib/src/ui/canvas/cinematics/`
- tests `cinematic_builder_workspace_test.dart` et `cinematics_library_workspace_test.dart`

## 4. Synthèse des sub-agents et arbitrages

Les sub-agents réels n'étaient pas exposés dans cette session ; j'ai donc exécuté des passes spécialisées séparées et documentées.

- Sub-agent A — audit renderer existant : V1-89 rendait surtout les TileLayer ; les assets étaient résolus via `CinematicTilesetAssetRegistry`; l'overlay acteur V1-92 était dans le panel.
- Sub-agent B — design plan : Option E confirmée, plan `CinematicMapBackdropLayerRenderPlan` séparé pour migration douce.
- Sub-agent C — terrain/path : résolution déterministe via presets existants, sans fake terrain/path.
- Sub-agent D — surfaces/placed elements : surfaces via helper editor existant, placements via `ProjectElementEntry`/frames.
- Sub-agent E — environment : aucun masque brut ; uniquement `generatedPlacementIds -> MapPlacedElement`.
- Sub-agent F — painter/composition : background passes, Actor Display V1-92, puis foreground passes.
- Sub-agent G — tests/anti-scope : tests ajoutés pour plan, rendu, partial render, exclusions, non-mutation et visual gate.
- Sub-agent H — UX produit : le décor devient plus proche Map Editor sans promettre de runtime.
- Reviewer final — pas de runtime/Flame/MapCanvas complet/playback ; limites V1-95 maintenues.

Divergence identifiée : le `flutter test` global `map_editor` reste rouge hors lot sur des golden anciens et le convertisseur Pokémon SDK. Arbitrage : garder les preuves ciblées vertes et documenter le blocage global.

## 5. Design Gate — Cinematic Map Backdrop Layer Fidelity Renderer V0

Le design gate retenu est un renderer bitmap cinematic dédié, editor-only/read-only. Il consomme un plan déjà construit avec des images résolues en amont ; il ne lit pas le disque dans `build()` ou `paint()`.

## 6. Contrat V1-93 implémenté

V1-93 demandait un plan multi-layer dédié avant le Sprite Resolver. V1-94 implémente ce plan sans remplacer brutalement le plan V1-89 : l'ancien `CinematicMapBackdropTileRenderPlan` reste accepté par le panel et les tests legacy restent verts.

## 7. Scope réalisé

- Plan `CinematicMapBackdropLayerRenderPlan`.
- Loader `CinematicMapBackdropLayerPlanLoader`.
- Painter `CinematicMapBackdropLayerRenderPainter`.
- Branching Library/Builder/Preview Panel.
- Tests de plan, rendu, fallback, diagnostics, exclusions, non-mutation, overlay acteur, timeline et pickers.
- Visual Gate 1663x926.

## 8. Plan cinematic multi-layer

Ordre appliqué :

```text
terrain -> path -> tileBackground -> surface -> placedBackground -> actorOverlayV1-92 -> tileForeground -> placedForeground
```

`actorOverlayV1-92` reste une composition widget, pas une instruction du backdrop painter.

## 9. Resolver terrain / path

Terrain :

- ignore les cellules non paintables ;
- résout `ProjectTerrainPreset`;
- choisit une frame déterministe ;
- ajoute diagnostics si preset/frame/tileset/source rect manque.

Path :

- lit les cellules actives ;
- résout `ProjectPathPreset` / pattern ;
- choisit une frame stable par cellule ;
- ne fait aucun pathfinding.

## 10. Resolver surfaces

Les surfaces utilisent les helpers editor existants de preview statique. Si un atlas/preset/source rect manque, le plan garde les autres familles visibles et ajoute un diagnostic.

## 11. Resolver placed elements / generated placements

Les `MapPlacedElement` sont rendus depuis `ProjectElementEntry`, frame primaire et source rect déterministe. Les placements générés environment sont rendus seulement quand un `EnvironmentLayer.content.generatedPlacementIds` pointe vers un vrai `MapPlacedElement`.

## 12. TileLayer background / foreground

Le rendu V1-89 est conservé. V1-94 ajoute une séparation background/foreground quand les données le permettent, notamment via les masques dérivés des éléments multi-cellules et collisions d'éléments.

## 13. Layer ordering

Chaque instruction porte une passe et un `zOrder`. Les instructions sont triées par `renderPass.order`, puis par `zOrder`, pour garder un ordre stable et proche du Map Editor.

## 14. Painter / composition visuelle

Le panel dessine :

1. les passes background ;
2. l'overlay `CinematicActorDisplayPreviewOverlay` V1-92 ;
3. les passes foreground.

Le painter reçoit les couleurs depuis le design system via la palette déjà existante.

## 15. Actor Display V1-92 préservé

Les placeholders acteurs restent statiques, labels courts et direction hints inclus. Aucun sprite acteur final, aucune interpolation `actorMove`, aucun `currentTimeMs`, `playbackTimeMs` ou `isPlaying` n'est ajouté.

## 16. Fallbacks et partial render

Une famille manquante ne masque pas les autres familles. Les diagnostics restent attachés au plan ; si aucune instruction bitmap valide n'existe, le fallback structurel historique reste disponible.

## 17. Diagnostics backdrop fidelity

Diagnostics ajoutés ou conservés : taille de tuile invalide, preset terrain manquant, frame terrain/path manquante, tileset manquant, image tileset indisponible, source rect hors atlas, element frame manquante, generated placement inconnu, aucune instruction bitmap.

## 18. Préservation timeline / duration / resize / probe

Tests verts pour :

- transports disabled ;
- timeline visible ;
- duration editor ;
- resize handle ;
- mouse probe.

## 19. Préservation pickers map-aware / Character Library

Tests verts pour :

- actor picker `mapEntity` ;
- movement target `mapEntity`/`mapEvent` ;
- Character Library picker avec backdrop étendu.

## 20. Restrictions anti-runtime / anti-Flame / anti-MapCanvas

Checks anti-scope : aucun diff dans `map_runtime`, `map_gameplay`, `map_battle`, `examples` ou `selbrume`. Aucun import Flame/runtime, aucun `GameWidget`, `PlayableMapGame`, `GameState`, `MapCanvas(`, `MapGridPainter(` ou playback ajouté.

## 21. Design system

V1-94 n'ajoute aucune couleur hardcodée dans le diff. Le scan brut trouve des `Colors.*`/`Color(0x...)` préexistants dans `cinematic_builder_workspace.dart`, mais le diff V1-94 n'en ajoute pas.

## 22. Tests ajoutés ou modifiés

Ajouts principaux dans `cinematic_builder_workspace_test.dart` :

- plan terrain/path/surface/placed elements ;
- rendu extended backdrop ;
- actor placeholders préservés ;
- real tile visible avec plan étendu ;
- diagnostics partial render ;
- transports/timeline/duration/resize/probe ;
- pickers map-aware et Character Library ;
- exclusions runtime entities/events/triggers/collisions/warps ;
- non-mutation projet/map ;
- Visual Gate V1-94.

`cinematics_library_workspace_test.dart` a été ajusté pour le nouveau wording `2 couche(s) bitmap`.

## 23. Visual Gate

Screenshot :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_94_cinematic_extended_map_backdrop_visual_gate_v0.png
```

Preuve :

```text
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
sha256 3cc17a0b4a9d986df0bf9b262014489185693b473501f52436c8ebde4dfa649c
```

## 24. Commandes exécutées

Commandes clés :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
flutter test --reporter=compact test/cinematics_library_workspace_test.dart
flutter analyze --no-fatal-infos <14 fichiers V1-94>
dart test --reporter=compact
flutter test --update-goldens --dart-define=NS_SCENES_V1_94_CAPTURE_CINEMATIC_EXTENDED_MAP_BACKDROP=true --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'captures V1-94 cinematic extended map backdrop visual gate when requested'
flutter test --reporter=compact
flutter analyze
```

## 25. Résultats des tests

Verts :

```text
map_core dart test --reporter=compact -> +2438, All tests passed!
cinematic_builder_workspace_test.dart -> +174, All tests passed!
cinematics_library_workspace_test.dart -> +21, All tests passed!
Visual Gate V1-94 ciblé -> All tests passed!
```

Global editor tenté :

```text
flutter test --reporter=compact -> +2220 -18, Some tests failed.
```

Échecs hors V1-94 observés : golden V1-29 et compilation du convertisseur Pokémon SDK.

## 26. Analyze

Analyse ciblée V1-94 :

```text
Analyzing 14 items...
No issues found! (ran in 1.5s)
```

Analyse globale editor :

```text
flutter analyze -> 344 issues found.
```

Blocage hors V1-94 : `pokemon_sdk_move_catalog_converter.dart` et `sync_pokemon_sdk_moves_catalog_use_case.dart`, plus infos/lints existants.

## 27. Checks anti-scope

Résultats :

- aucun diff runtime/gameplay/battle/examples/selbrume ;
- aucun Flame/runtime/MapCanvas brut ;
- aucun chargement image en build/paint ;
- aucune donnée Selbrume hardcodée ;
- aucune image IA ou `gpt-image-2` ;
- aucun ajout de couleur hardcodée dans le diff ;
- un hit `seek/scrub` uniquement dans un test négatif ;
- un hit `characterAssetMissingSprite` uniquement dans un code diagnostic existant.

## 28. Fichiers créés

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_render_pass.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_renderer.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_plan_loader.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_94_cinematic_map_backdrop_layer_fidelity_renderer_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_94_evidence_pack.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_94_cinematic_extended_map_backdrop_visual_gate_v0.png`

## 29. Fichiers modifiés

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 30. Roadmaps mises à jour

V1-94 est passé en DONE dans les deux roadmaps. Le prochain lot recommandé est maintenant :

```text
NS-SCENES-V1-95 — Cinematic Actor Display Preview Sprite Resolver Prep Contract
```

## 31. Limites connues

- Pas de shadow pass dédiée dans V1-94.
- Le split foreground reste borné aux données raisonnablement dérivables.
- Les sprites acteurs finaux restent placeholders V1-92.
- Le global `map_editor` reste rouge hors lot.

## 32. Non-objectifs confirmés

Pas de runtime, pas de Flame, pas de playback, pas de MapCanvas complet, pas de MapGridPainter brut, pas de pathfinding/collision runtime, pas de mutation `ProjectManifest`/`MapData`, pas de modification Selbrume, pas d'image IA.

## 33. Evidence Pack

Evidence pack associé :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_94_evidence_pack.md
```

Il contient les sorties de commandes, les checks anti-scope et le code généré principal.

## 34. Auto-review critique

Questions de contrôle :

- `map_runtime` modifié ? Non.
- `map_gameplay`, `map_battle`, `examples`, `selbrume` modifiés ? Non.
- Flame/runtime/MapCanvas complet utilisé ? Non.
- Playback/currentTime/isPlaying ajouté ? Non.
- Terrain/path/surface/placed elements rendus ? Oui.
- Environment rendu brut ? Non, uniquement placements générés réels.
- Actor Display V1-92 préservé ? Oui.
- Visual Gate pertinente ? Oui, 1663x926.
- Tests suffisants ? Oui pour le lot ciblé ; global editor reste bloqué hors lot.

## 35. Recommandation pour le prochain lot

Prochain lot recommandé :

```text
NS-SCENES-V1-95 — Cinematic Actor Display Preview Sprite Resolver Prep Contract
```

Objectif : cadrer les sources de sprites statiques acteur, frames idle, fallbacks, diagnostics et cache, sans encore transformer la preview en runtime.
