# NS-SCENES-V1-89 — Cinematic Map Backdrop Real Tile Renderer Integration / Fidelity Polish V0

Date : 2026-06-06

## 1. Résumé exécutif

Statut : `DONE` avec limites explicites.

Phrase canonique : V1-89 connecte le renderer réel au projet réel. V1-89 ne fait toujours pas entrer les acteurs.

Demande : Karim a fourni le prompt V1-89 et a demandé explicitement des sub-agents/passes, une preuve visuelle et des manipulations de test. Le lot suspend volontairement l'ancien V1-89 Actor Display pour consolider le décor de map réel avant les acteurs.

Décision retenue : le Builder reste consommateur read-only. La Library possède le snapshot `MapData`, reçoit un resolver de chemin tileset depuis le parent editor, charge le plan bitmap via un loader editor-only, puis transmet le `CinematicMapBackdropTileRenderPlan` au Builder. Aucun chargement image dans `build()` ou `paint()`.

Prochain lot recommandé : `NS-SCENES-V1-90 — Cinematic Actor Display Preview Prep Contract`.

## 2. Gate 0

Sorties avant modifications :

```text
pwd
/Users/karim/Project/pokemonProject
```

```text
git branch --show-current
main
```

```text
git status --short --untracked-files=all
(aucune sortie)
```

```text
git diff --stat
(aucune sortie)
```

```text
git diff --name-only
(aucune sortie)
```

```text
git log --oneline -n 15
a085d128 feat(narrative): auto-commit changes
103cc837 feat(narrative): auto-commit changes
fd10cce7 feat(narrative): auto-commit changes
c730bef3 feat(narrative): auto-commit changes
3b73a8fd feat(narrative): auto-commit changes
587b47f6 update selbrume
50a43df8 feat(narrative): add cinematic map backdrop preview model, tests, and roadmap updates (NS-SCENES-V1-83)
c76550a6 feat(narrative): update cinematic workspaces, tests, and roadmap reports (NS-SCENES-V1-82)
e32d5f2a update screenshot failures for ns_scenes_v1_29_storyline_step_scene_link_v0
1b311e81 feat(narrative): update cinematic workspace and add test failure assets (NS-SCENES-V1-29-81)
122fe0c7 feat(narrative): update cinematic builder workspace (NS-SCENES-V1-81-BIS)
747aa6e6 feat(narrative): add cinematic builder workspace updates and test failure assets (NS-SCENES-V1-35)
2da49606 feat(narrative): add cinematic actor appearance drift diagnostics polish v0 (NS-SCENES-V1-81)
eea6dbff feat(narrative): add cinematic character library picker v0 (NS-SCENES-V1-80)
eb7d47aa feat(narrative): add cinematic character library binding core model v0 (NS-SCENES-V1-79)
```

Note : pendant le travail, deux commits externes `update selbrume` sont apparus dans `git log`. Je n'ai exécuté aucune commande Git d'écriture.

## 3. Fichiers lus

Fichiers et zones lus : prompt V1-89 attaché, `AGENTS.md`, `skills/README.md`, skills `systematic-debugging`, `test-driven-development`, `verification-before-completion`, `writing-plans`, `subagent-driven-development`, roadmaps Scenes, rapports V1-86/V1-87/V1-88, fichiers cinematics du Builder/Library/panel/renderer/registry, `narrative_workspace_canvas.dart`, `editor_notifier.dart`, `map_canvas`/assets/painter en audit, tests builder/library, modèles core `MapData`, `MapLayer`, `ProjectManifest`, `CinematicMapBackdropPreviewModel`.

## 4. Synthèse des sub-agents et arbitrages

Sub-agent A — conclusion : le vrai point de wiring est `NarrativeWorkspaceCanvas -> CinematicsLibraryWorkspace`. `EditorNotifier.getTilesetAbsolutePathById` existe déjà et sait résoudre les chemins via `ProjectWorkspace`. La Library possède le `ProjectManifest` et le snapshot `MapData`, donc elle peut charger le plan sans coupler le Builder au parent.

Sub-agent B — conclusion : V1-88 rend correctement les `TileLayer` visibles mais manque le wiring produit, des diagnostics de métriques, et des preuves pour fallback `mapData.tilesetId` / assets absents. Les surfaces/objets/environnement restent hors scope.

Sub-agent C — conclusion : l'UI V1-88 est acceptable si le badge `Fallback structurel` n'est affiché que quand il y a vraiment fallback. Les diagnostics partiels doivent rester visibles même si certaines tiles sont rendues.

Sub-agent D — conclusion : les tests doivent prouver success path, fallback asset manquant, collecteur de tilesets, diagnostics plan, transports disabled, non-mutation, non-runtime et Visual Gate.

Sub-agent E — conclusion : on peut passer à Actor Display seulement après preuve que le décor réel est câblé depuis le parent. Après V1-89, Actor Display Prep devient raisonnable, avec la limite TileLayer encore déclarée.

Divergences identifiées : le prompt voulait une preview type Selbrume mais interdisait toute donnée Selbrume hardcodée ou modification `selbrume`. Arbitrage : utiliser une fixture PNG neutre pour le test/Visual Gate et brancher le resolver réel du workspace pour que Selbrume fonctionne quand ses assets existent.

Option retenue : loader editor-only dans `cinematic_map_backdrop_tile_plan_loader.dart`, alimenté par `CinematicsLibraryWorkspace`, resolver fourni par `NarrativeWorkspaceCanvas`, Builder inchangé comme consommateur.

## 5. Design Gate — Cinematic Map Backdrop Real Tile Renderer Integration / Fidelity Polish V0

1. Limite V1-88 corrigée : le plan bitmap n'était pas câblé automatiquement au workspace parent.
2. Plan V1-88 : construit par callback optionnel ou tests, pas par le vrai parent.
3. Callback : `BuildCinematicBackdropTileRenderPlanCallback` dans `cinematics_library_workspace.dart`.
4. `ProjectManifest` : disponible dans `CinematicsLibraryWorkspace` via `widget.project`.
5. `ProjectWorkspace` / root : accessible indirectement via `EditorNotifier`.
6. `MapData` snapshot : chargé par `onLoadStageMapSnapshot`.
7. Registry : stocké dans un loader d'état Library, pas dans Builder/painter.
8. Pas de chargement dans `build()` : `build()` ne fait qu'armer des futures et consommer l'état chargé.
9. Pas de chargement dans `paint()` : le painter ne reçoit que `ui.Image` déjà résolues.
10. Collecte IDs : `TileLayer` visibles, opacité > 0, tiles non nulles.
11. Résolution IDs : `layer.tilesetId ?? mapData.tilesetId`.
12. Tileset absent manifest : diagnostic `missingTilesetEntry`.
13. Fichier absent : diagnostic `missingFile`.
14. Decode failure : diagnostic `decodeFailed` dans le registry existant.
15. Aucune instruction : diagnostic `noBitmapInstructions`.
16. Fallback structurel : seulement si pas d'instructions bitmap ou modèle indisponible.
17. Vraie carte statique : quand le plan existe et contient des instructions bitmap.
18. Proportions V1-86 : preview/panel existants préservés, Visual Gate 1663x926.
19. Timeline : tests builder complets verts, timeline visible dans screenshot.
20. Transports disabled : assertions sur reset/play/stop sans callback.
21. Pickers mapEntity/mapEvent : tests builder existants complets verts.
22. Character Library picker : tests builder existants complets verts.
23. Aucun acteur : aucun rendu acteur ajouté, screenshot sans acteur, scans anti-actor propres.
24. Aucun runtime/Flame : scans anti-runtime propres sur code V1-89.
25. Aucun MapCanvas complet : scan `MapCanvas(`/`MapGridPainter(` vide.
26. Aucun chargement build/paint : seul `CinematicTilesetAssetRegistry` lit/décode.
27. Visual Gate : PNG V1-89 sous `reports/narrativeStudio/scenes/screenshots/`.
28. Prochain lot : `NS-SCENES-V1-90 — Cinematic Actor Display Preview Prep Contract`.

## 6. Problème produit après V1-88

V1-88 prouvait le renderer, mais principalement par injection de tests. Dans le produit, le parent ne fournissait pas encore un plan alimenté par les vrais assets du workspace. Le résultat risquait donc de rester en fallback structurel alors que les tilesets existaient.

## 7. Scope réalisé

Réalisation V1-89 : loader editor-only, collecteur de tilesets, wiring parent `EditorNotifier`, cache de plan dans la Library, diagnostics plan enrichis, diagnostics partiels visibles, tests success/fallback/fidelity, Visual Gate et roadmaps mises à jour.

## 8. Wiring workspace / assets

`NarrativeWorkspaceCanvas` passe maintenant `widget.editorNotifier.getTilesetAbsolutePathById` à `CinematicsLibraryWorkspace`. La Library utilise ce resolver après chargement du snapshot map, puis charge le plan via `CinematicMapBackdropTilePlanLoader`.

## 9. Registry / cache tilesets

Le loader réutilise `CinematicTilesetAssetRegistry`. Le registry reste l'unique endroit source où apparaissent `File`, `readAsBytes` et `instantiateImageCodec`. Il est vidé à `dispose()`.

## 10. Plan de rendu bitmap intégré

Le plan est construit depuis `MapData`, `ProjectManifest` et les assets résolus. Le collecteur résout les IDs nécessaires depuis `TileLayer.tilesetId` ou `mapData.tilesetId`. Les métriques incompatibles produisent `tileMetricMismatch`.

## 11. Fallback structurel et diagnostics

Le fallback structurel reste disponible quand le plan est absent ou sans instruction. Le meta bar affiche désormais les diagnostics du plan même s'il y a aussi des instructions bitmap, afin de ne pas cacher les problèmes partiels.

## 12. Fidélité visuelle / composition

La composition V1-86/V1-88 est conservée : carte statique, badges `Tiles réelles affichées`, `Décor seul`, `Sans acteurs`, `Sans lecture`, timeline visible et inspecteur visible. La Visual Gate est une vraie capture Flutter 1663 x 926.

## 13. Préservation timeline / duration / resize / probe

Le fichier complet `cinematic_builder_workspace_test.dart` passe avec `+155`. Il couvre les chemins existants de timeline, duration editing, resize handles, mouse probe, keyboard/help et transport placeholders autour du backdrop.

## 14. Préservation pickers map-aware / Character Library

Les tests builder existants qui couvrent `mapEntity`, `mapEvent`, mouvement target et Character Library restent verts dans la suite complète.

## 15. Restrictions anti-runtime / anti-Flame / anti-playback

Aucun fichier runtime/gameplay/battle/examples n'est modifié. Les scans anti-runtime/Flame sont vides sur les fichiers source V1-89. Le scan anti-playback ne remonte que deux assertions historiques `findsNothing` sur `seek`/`scrub` dans un test.

## 16. Design system

Aucune couleur hardcodée n'a été ajoutée. Le panel continue d'utiliser les tokens et primitives existantes : `context.pokeMapColors`, `PokeMapBadge`, `PokeMapTone`, `PokeMapButton`, surfaces et palettes passées au painter.

## 17. Tests ajoutés ou modifiés

Tests clés ajoutés/modifiés :

- `wires project tileset assets into cinematic real tile backdrop plan`
- `falls back structurally when project tileset asset is missing`
- `loads project tileset assets into a cinematic tile render plan`
- `collects visible tile layer tilesets from layer and map defaults`
- extension de `builds bitmap instructions only from visible tile layers` avec `sourceRectOutOfBounds` et `tileMetricMismatch`
- Visual Gate V1-89 conditionnelle.

## 18. Visual Gate

Artefact :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_89_cinematic_map_backdrop_real_tile_renderer_integration_fidelity_polish_v0.png
```

Preuve :

```text
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
SHA-256 ef160c2febfd96a9fbc8cdcfe8d2e140238bf7f12020e6c4892df5226ef1844f
```

Observation : la capture montre le Builder ouvert, `Carte du projet (statique)`, `Tiles réelles affichées`, `2 tuile(s) bitmap`, timeline et inspecteur visibles, transports disabled, aucun acteur rendu.

Limite visuelle : dans le golden Flutter, certaines icônes apparaissent sous forme de carrés faute de police d'icônes chargée. Les textes et proportions restent exploitables.

## 19. Commandes exécutées

Voir l'Evidence Pack pour les sorties détaillées. Principales commandes : tests targeted, suites builder/library, Visual Gate, tests core, analyze core, analyze ciblée editor, analyze globale editor, scans anti-scope, `git diff --check`, `git diff --stat`, `git diff --name-only`, `git status --short --untracked-files=all`.

## 20. Résultats des tests

Verts :

- `cinematics_library_workspace_test.dart` : `00:06 +20: All tests passed!`
- `cinematic_builder_workspace_test.dart` : `00:24 +155: All tests passed!`
- core backdrop preview : `+19`
- core stage map source catalog : `+7`
- core cinematic asset : `+14`
- core project manifest cinematics : `+9`
- Visual Gate V1-89 : `+1`

## 21. Analyze

`packages/map_core` :

```text
Analyzing map_core...
No issues found!
```

Analyse ciblée editor :

```text
Analyzing 10 items...
No issues found! (ran in 2.0s)
```

Analyse globale editor :

```text
344 issues found. (ran in 2.9s)
```

Limite : les erreurs globales sont hors scope V1-89, principalement `pokemon_sdk_move_catalog_converter.dart` et `sync_pokemon_sdk_moves_catalog_use_case.dart`.

## 22. Checks anti-scope

Résultats : pas de diff runtime/gameplay/battle/examples/selbrume, pas de runtime/Flame, pas d'acteur, pas de `MapCanvas`, pas de `MapGridPainter`, pas de couleurs hardcodées. Le chargement image reste limité au registry. Les mentions `gpt-image-2` restantes sont historiques dans les roadmaps, pas une utilisation d'image IA.

## 23. Fichiers créés

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_plan_loader.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_89_cinematic_map_backdrop_real_tile_renderer_integration_fidelity_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_89_evidence_pack.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_89_cinematic_map_backdrop_real_tile_renderer_integration_fidelity_polish_v0.png`

## 24. Fichiers modifiés

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 25. Roadmaps mises à jour

Les deux roadmaps déclarent maintenant :

- V1-89 DONE : Real Tile Renderer Integration / Fidelity Polish V0.
- V1-90 TODO : Actor Display Preview Prep Contract.
- V1-91 TODO : Timeline Scroll / Visibility Polish V0.

## 26. Limites connues

Le rendu bitmap couvre les `TileLayer`. Les surfaces, objets, environnement et autres overlays restent hors V1-89 ou dans le fallback structurel. La Visual Gate utilise une fixture neutre de test plutôt qu'une map Selbrume hardcodée, conformément aux non-objectifs.

## 27. Non-objectifs confirmés

Pas d'acteurs, pas de player, pas de mapEntity rendu, pas de sprite Character Library, pas de playback, pas de runtime, pas de Flame, pas de `PlayableMapGame`, pas de `MapCanvas` complet, pas de `MapGridPainter`, pas de mutation `ProjectManifest` ou `MapData`, pas de donnée Selbrume hardcodée, pas d'image IA.

## 28. Evidence Pack

Voir :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_89_evidence_pack.md
```

Il inclut le code complet du nouveau helper `cinematic_map_backdrop_tile_plan_loader.dart`.

## 29. Auto-review critique

1. map_runtime modifié ? Non.
2. map_gameplay/map_battle/examples modifiés ? Non.
3. selbrume modifié par V1-89 ? Non ; un fichier non suivi `selbrume/assets/tilesets/bateau_selbrume.png` existe hors diff V1-89.
4. Flame importé ? Non.
5. map_runtime importé ? Non.
6. PlayableMapGame utilisé ? Non.
7. MapCanvas complet branché ? Non.
8. MapGridPainter brut instancié ? Non.
9. Image chargée dans `build()` ? Non.
10. Image chargée dans `paint()` ? Non.
11. Preview jouable/playback ajouté ? Non.
12. currentTimeMs/playbackTimeMs/isPlaying ajoutés ? Non.
13. Acteurs rendus ? Non.
14. Collisions/triggers/events/entities rendus ? Non.
15. Registry réel câblé depuis le parent ? Oui, via `EditorNotifier.getTilesetAbsolutePathById`.
16. TileLayer utilise les vraies images projet quand disponibles ? Oui.
17. Fallback structurel seulement quand nécessaire ? Oui pour les cas V1-89 couverts.
18. Diagnostics asset visibles ? Oui.
19. Timeline visible ? Oui.
20. Transports disabled ? Oui.
21. Duration editor et resize encore couverts ? Oui via suite builder.
22. Probe souris/navigation clavier encore couverts ? Oui via suite builder.
23. Pickers mapEntity/mapEvent couverts ? Oui via suite builder.
24. Character Library picker couvert ? Oui via suite builder.
25. Visual Gate prouve une amélioration ? Oui : plan bitmap intégré par parent.
26. Evidence Pack sans placeholders ? Oui.
27. Prochain lot exact ? `NS-SCENES-V1-90 — Cinematic Actor Display Preview Prep Contract`.

## 30. Recommandation pour le prochain lot

Recommandation : `NS-SCENES-V1-90 — Cinematic Actor Display Preview Prep Contract`.

Objectif : cadrer l'affichage statique des acteurs maintenant que le décor réel est disponible, sans playback, interpolation, runtime, pathfinding ou mutation gameplay.
