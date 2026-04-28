# Lot 94-pack — Runtime Surface Closure Report + Gameplay Semantics Decision V0

## 1. Résumé exécutif honnête

Le bloc Runtime Surface V0 peut être considéré fermé pour son périmètre visuel : le runtime collecte les tilesets Surface, résout les placements en instructions, dessine les vraies tiles Surface dans Flame, anime via `_animElapsed`, respecte l'ordre de rendu, résiste aux références manquantes, charge un projet disque réel, démarre `RuntimeMapGame`, et accepte une map Surface dans `PlayableMapGame`.

Ce lot ne code aucune fonctionnalité. Il clôture le bloc runtime Surface V0 et pose une décision de suite : **SurfaceCatalog doit rester principalement visuel**. Le gameplay surf, tall grass, encounters, effets de pas, modificateurs de mouvement et prérequis doivent vivre dans une future couche de semantics gameplay qui référence les presets Surface au lieu de polluer les atlas/animations.

Les tests runtime Surface ont été relancés et restent verts :

- `flutter test test/surface` : `+29 All tests passed!`
- `flutter test test/runtime_manifest_tilesets_surface_layer_test.dart` : `+1 All tests passed!`
- `flutter test test/map_layers_component_render_pass_test.dart` : `+2 All tests passed!`

## 2. Périmètre

Inclus :

- audit des lots runtime Surface 89 à 93 ;
- synthèse des garanties et limites ;
- décision architecture produit Visual Surface / Gameplay Semantics ;
- roadmap post Runtime Surface V0 ;
- relance des tests runtime Surface de clôture.

Exclus :

- aucune modification de code de production ;
- aucun nouveau test Dart ;
- aucun gameplay surf ;
- aucun tall grass encounter ;
- aucune collision Surface ;
- aucune migration legacy ;
- aucun changement JSON ;
- aucun changement `ProjectManifest`.

## 3. Gate 0 — status initial

Commande obligatoire exécutée depuis la racine :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
```

`git status --short --untracked-files=all` initial :

```text
```

`git diff --stat` initial :

```text
```

`git log --oneline -n 10` initial :

```text
83654389 feat: add surface runtime test files and golden slice reports
1f900e67 feat(map_runtime): render surface layers
da2b244d feat(map_runtime): add surface runtime resolver
32fbb0b5 feat(map_editor): improve surface mapping editor
d5561df7 feat(map_editor): edit surface role animation mapping
935a0036 feat(map_editor): animate surface editor previews
fe03b827 feat(map_editor): render surface atlas tile previews
5814f6e9 feat(map): add surface role resolver preview
f8859a06 feat(map_editor): improve surface painter and studio workflow ux
b20287da feat(map_editor): redesign surface studio workflow
```

Changements préexistants : aucun dans le status initial.

## 4. Audit des lots 89–93

Commandes d'audit obligatoires lancées :

```bash
rg -n "SurfaceRuntimeRenderInstruction|resolveSurfaceRuntimeRenderInstructions|collectSurfaceRuntimeTilesetIds|_paintSurfaceLayer|SurfaceLayer|surfaceCatalog" packages/map_runtime/lib packages/map_runtime/test
rg -n "surface_runtime_golden_slice|surface_runtime_ordering|surface_runtime_missing_assets|surface_runtime_playable_host_smoke|runtime_manifest_tilesets_surface_layer" packages/map_runtime/test reports/surface
rg -n "PlayableMapGame|RuntimeMapGame|MapLayersComponent|loadRuntimeMapBundle|loadTilesetImagesById|GameWidget" packages/map_runtime/lib packages/map_runtime/test examples
```

Fichiers runtime Surface existants aujourd'hui :

- `packages/map_runtime/lib/src/surface/surface_runtime_render_instruction.dart`
- `packages/map_runtime/lib/src/surface/surface_runtime_resolver.dart`
- `packages/map_runtime/lib/src/surface/surface_runtime_tileset_collector.dart`
- `packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart`
- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`

Tests Surface runtime existants :

- `packages/map_runtime/test/surface/surface_runtime_resolver_test.dart`
- `packages/map_runtime/test/surface/surface_runtime_tileset_collector_test.dart`
- `packages/map_runtime/test/surface/surface_runtime_renderer_test.dart`
- `packages/map_runtime/test/surface/surface_runtime_golden_slice_test.dart`
- `packages/map_runtime/test/surface/surface_runtime_ordering_test.dart`
- `packages/map_runtime/test/surface/surface_runtime_missing_assets_test.dart`
- `packages/map_runtime/test/surface/surface_runtime_playable_host_smoke_test.dart`
- `packages/map_runtime/test/runtime_manifest_tilesets_surface_layer_test.dart`
- `packages/map_runtime/test/map_layers_component_render_pass_test.dart`

Intégration host constatée :

- `examples/playable_runtime_host/lib/main.dart` charge un `project.json` via `loadRuntimeMapBundle`.
- Le host construit ensuite `PlayableMapGame`.
- Le host affiche le jeu via `GameWidget(game: game)`.
- `RuntimeMapGame` est le viewer Flame léger qui charge les images via `loadTilesetImagesById` et monte `MapLayersComponent`.
- `PlayableMapGame` monte deux `MapLayersComponent` : background et foreground.

## 5. Runtime Surface V0 — garanties obtenues

Garanties runtime maintenant couvertes :

- Les tilesets Surface nécessaires sont collectés depuis les `SurfaceLayer`.
- La collecte déduplique les `tilesetId`.
- La collecte scanne toutes les frames d'animation.
- `SurfaceLayer -> SurfaceRuntimeRenderInstruction` existe et reste pur.
- Le rôle Surface est résolu depuis les voisins ayant le même `surfacePresetId`.
- Deux surfaces différentes adjacentes ne se connectent pas.
- Les placements invisibles ou d'opacité zéro sont ignorés.
- Les instructions produisent `x/y`, `surfacePresetId`, `role`, `animationId`, `atlasId`, `tilesetId`, source coordinates et tile size.
- `MapLayersComponent` dessine les vraies tiles via `RuntimeTilesetImage.drawImageRect`.
- La frame courante suit `_animElapsed`, sans nouvelle clock runtime.
- Le rendu Surface reste background-only en V0.
- L'ordre terrain/path -> surface -> tile -> entities -> collision overlay est verrouillé par tests.
- Les références incomplètes ne crashent pas.
- Le runtime ne dessine aucun fallback debug jaune en production.
- Le pipeline disque réel fonctionne : `project.json`, map JSON, PNG, loader, images, composant, pixel.
- `RuntimeMapGame` charge un projet Surface disque réel et rend rouge puis bleu.
- `PlayableMapGame` démarre avec une map Surface et ticke sans crash en phase `overworld`.

## 6. Runtime Surface V0 — limites restantes

Limites explicites :

- Pas de gameplay surf.
- Pas de tall grass encounters.
- Pas de collision Surface.
- Pas de migration legacy.
- Pas de screenshot `GameWidget` complet.
- Pas de culling/performance avancée.
- Pas de multi-map/multi-atlas avancé au-delà des cas couverts par collecte/résolution.
- Pas de diagnostics utilisateur runtime riches.
- Pas de random/weighted center variants.
- Pas de semantics gameplay persistantes.
- Pas de décision codée pour water/lava/ice/tallGrass.

## 7. Tests existants et couverture

| Zone | Tests principaux | Couverture |
| --- | --- | --- |
| Collecte tilesets | `surface_runtime_tileset_collector_test.dart`, `runtime_manifest_tilesets_surface_layer_test.dart` | SurfaceLayer -> presets -> animations -> frames -> atlas -> tilesetId |
| Resolver | `surface_runtime_resolver_test.dart` | rôles par voisins, surfaces différentes, fallback, elapsedMs, ordre stable |
| Renderer Flame | `surface_runtime_renderer_test.dart` | drawImageRect, animation, foreground ignored, missing image, invalid sourceRect, visibility/opacity |
| Golden slice disque | `surface_runtime_golden_slice_test.dart` | projet temporaire, PNG réel, load bundle, load images, pixel rouge/bleu |
| Ordering/hardening | `surface_runtime_ordering_test.dart`, `surface_runtime_missing_assets_test.dart` | ordre de rendu, foreground, collision overlay, assets manquants, catalogue incomplet |
| Host proche réel | `surface_runtime_playable_host_smoke_test.dart` | `RuntimeMapGame` pixel rouge/bleu, `PlayableMapGame` onLoad/update |

Ce qui manque encore :

- un screenshot widget complet via `GameWidget` ;
- un test de gameplay surf/tallGrass, volontairement hors périmètre ;
- une suite perf/culling pour grandes maps Surface.

## 8. Décision : Runtime Surface V0 fermé ou non

Décision : **Oui, Runtime Surface V0 est fermé pour le rendu visuel runtime.**

Raison :

- Le pipeline complet fonctionne de la donnée projet au pixel runtime.
- Les cas d'erreur courants sont couverts.
- Le host jouable accepte une map Surface.
- Les limites restantes sont des lots nouveaux : gameplay semantics, diagnostics, perf, migration, ou screenshots app complets.

Ce que cette fermeture ne veut pas dire :

- Elle ne valide pas surf.
- Elle ne valide pas tallGrass.
- Elle ne valide pas encounters.
- Elle ne valide pas une UX Surface Studio parfaite.
- Elle ne valide pas un modèle gameplay persistant.

## 9. Surface Gameplay Semantics Decision V0

Questions tranchées :

1. **Est-ce qu'une Surface est seulement visuelle ou peut porter du gameplay ?**  
   Une Surface peut être associée à du gameplay côté produit, mais le modèle visuel actuel doit rester visuel. Le gameplay doit être attaché par une couche semantics séparée.

2. **Est-ce que le gameplay doit être porté par ProjectSurfacePreset ou par une autre couche ?**  
   Recommandation : autre couche. `ProjectSurfacePreset` doit rester le preset visuel, référençable par une semantics gameplay.

3. **Est-ce que surf / tallGrass / encounter doivent être dans SurfaceCatalog ?**  
   Non en V0. `SurfaceCatalog` doit rester atlas / animations / presets. Surf, tallGrass et encounters doivent référencer les presets mais ne pas être codés dans les animations.

4. **Est-ce qu'il faut éviter de mélanger rendu Surface et gameplay ?**  
   Oui. Le renderer runtime doit rester indépendant des règles gameplay.

5. **Comment gérer water / lava / ice / tallGrass ?**  
   Comme des semantics gameplay distinctes pouvant référencer un ou plusieurs presets Surface visuels. Exemple : water peut être surfable, lava peut blesser, ice peut modifier le mouvement, tallGrass peut déclencher des encounters.

6. **Comment garder le système no-code lisible ?**  
   Exposer un langage utilisateur clair : "Surface visuelle" d'un côté, "Comportement de terrain" de l'autre. L'utilisateur associe ensuite un comportement à des surfaces peignables sans manipuler des enums ou JSON.

## 10. Séparation Visual Surface / Gameplay Semantics

Décision proposée :

```text
Surface Visual Layer
- atlas
- animation
- preset
- placement
- rendering

Surface Gameplay Semantics
- surfacePresetId references
- isWater
- isSurfable
- isTallGrass
- encounterTableId
- footstepEffectId
- movementModifier
- damagePerStep / hazardEffectId éventuel
- requiresAbility / requiresBadge / requiresFlag éventuel
```

Principe :

- Le rendu lit `SurfaceLayer` et `SurfaceCatalog`.
- Le gameplay lit une future couche semantics.
- La semantics peut référencer `surfacePresetId`, mais ne doit pas connaître les colonnes d'atlas, frames, ou `SurfaceVariantRole`.

## 11. Recommandation produit no-code

Recommandation UX :

- Surface Studio reste l'endroit où créer des surfaces visuelles.
- Un futur écran "Comportements de surface" ou "Règles de terrain" doit permettre d'associer des comportements no-code à une surface.
- L'utilisateur ne doit pas choisir entre `SurfaceVariantRole`, `ProjectSurfacePreset`, ou des champs JSON.
- Les libellés attendus : "Eau surfable", "Herbe haute avec rencontres", "Glace glissante", "Lave dangereuse", "Boue ralentissante".

Ne pas présenter les règles gameplay comme des propriétés d'atlas. L'atlas est une image ; le comportement est une règle.

## 12. Roadmap post-runtime V0

Roadmap recommandée :

| Lot | Sujet | Raison |
| --- | --- | --- |
| Lot 95 | Surface Gameplay Semantics Spec / No-Code Design V1 | Décider précisément le modèle utilisateur avant de toucher aux contrats |
| Lot 96 | Surface Placement Diagnostics Runtime/Editor Bridge V0 | Donner une visibilité aux surfaces sans ouvrir gameplay |
| Lot 97 | Surface Gameplay Tags Model V0 | Introduire la couche semantics minimale, séparée du catalogue visuel |
| Lot 98 | Tall Grass Encounter Semantics V0 | Premier comportement gameplay testable mais borné |
| Lot 99 | Surfable Water Semantics V0 | Surf gating, conditions, movement mode |
| Lot 100 | Legacy Water/Grass Migration Audit V0 | Vérifier comment migrer sans casser les projets |
| Lot 101 | Surface Performance / Culling V0 | Traiter les grandes maps après stabilisation sémantique |

Prochain lot recommandé : **Lot 95 — Surface Gameplay Semantics Spec / No-Code Design V1**.

Pourquoi : coder directement surf/tallGrass maintenant risquerait de salir `ProjectSurfacePreset` ou de mélanger rendu et gameplay.

## 13. Tests relancés

Commandes obligatoires relancées :

```bash
cd packages/map_runtime && flutter test test/surface
cd packages/map_runtime && flutter test test/runtime_manifest_tilesets_surface_layer_test.dart
cd packages/map_runtime && flutter test test/map_layers_component_render_pass_test.dart
```

Analyse Dart ciblée :

```text
Aucune analyse Dart ciblée nécessaire : ce lot ne crée ni ne modifie aucun fichier Dart.
```

## 14. Résultats

### `flutter test test/surface`

Sortie finale :

```text
00:04 +29: All tests passed!
```

Points couverts dans la sortie :

```text
resolveSurfaceRuntimeRenderInstructions resolves one isolated placement into a runtime instruction
resolveSurfaceRuntimeRenderInstructions uses same-preset neighbors to resolve the role
resolveSurfaceRuntimeRenderInstructions does not connect adjacent placements from different Surface presets
resolveSurfaceRuntimeRenderInstructions falls back to isolated animation when the resolved role is uncovered
resolveSurfaceRuntimeRenderInstructions uses elapsedMs to select a frame without owning a runtime clock
resolveSurfaceRuntimeRenderInstructions skips unresolved preset animation atlas and out-of-atlas frames
resolveSurfaceRuntimeRenderInstructions returns stable y/x/preset order and ignores hidden layers
surface_runtime_missing_assets_test skips missing Surface tileset image and keeps other layers rendering
surface_runtime_renderer_test rendering uses _animElapsed to render the current Surface animation frame
surface_runtime_ordering_test keeps SurfaceLayer out of foreground pass
surface_runtime_golden_slice_test loads a disk project and renders an animated SurfaceLayer pixel
surface_runtime_playable_host_smoke_test RuntimeMapGame renders animated pixels
surface_runtime_playable_host_smoke_test PlayableMapGame starts and ticks with a disk SurfaceLayer project
```

### `flutter test test/runtime_manifest_tilesets_surface_layer_test.dart`

Sortie exacte :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_manifest_tilesets_surface_layer_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_manifest_tilesets_surface_layer_test.dart
00:01 +0: runtime manifest tileset collection with SurfaceLayer collects Surface atlas tilesets through the runtime manifest path
00:01 +1: runtime manifest tileset collection with SurfaceLayer collects Surface atlas tilesets through the runtime manifest path
00:01 +1: All tests passed!
```

### `flutter test test/map_layers_component_render_pass_test.dart`

Sortie exacte :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/map_layers_component_render_pass_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/map_layers_component_render_pass_test.dart
00:01 +0: MapLayersComponent project-element entity render pass keeps default entities in the background pass
00:01 +1: MapLayersComponent project-element entity render pass keeps default entities in the background pass
00:01 +1: MapLayersComponent project-element entity render pass moves flagged props to the foreground pass
00:01 +2: MapLayersComponent project-element entity render pass moves flagged props to the foreground pass
00:01 +2: All tests passed!
```

## 15. Fichiers créés

- `reports/surface/surface_engine_lot_94_pack_runtime_surface_closure_and_gameplay_semantics_decision.md`

## 16. Fichiers modifiés

Aucun fichier existant modifié.

## 17. Fichiers supprimés

Aucun.

## 18. Evidence Pack

Status initial : voir section 3.

Commandes lancées :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
rg -n "SurfaceRuntimeRenderInstruction|resolveSurfaceRuntimeRenderInstructions|collectSurfaceRuntimeTilesetIds|_paintSurfaceLayer|SurfaceLayer|surfaceCatalog" packages/map_runtime/lib packages/map_runtime/test
rg -n "surface_runtime_golden_slice|surface_runtime_ordering|surface_runtime_missing_assets|surface_runtime_playable_host_smoke|runtime_manifest_tilesets_surface_layer" packages/map_runtime/test reports/surface
rg -n "PlayableMapGame|RuntimeMapGame|MapLayersComponent|loadRuntimeMapBundle|loadTilesetImagesById|GameWidget" packages/map_runtime/lib packages/map_runtime/test examples
cd packages/map_runtime && flutter test test/surface
cd packages/map_runtime && flutter test test/runtime_manifest_tilesets_surface_layer_test.dart
cd packages/map_runtime && flutter test test/map_layers_component_render_pass_test.dart
```

Sorties test : voir section 14.

Contenu complet du rapport créé : le rapport lui-même n'est pas recopié récursivement, conformément à l'exception demandée.

## 19. Git status final

Gate final exécuté après écriture du rapport :

```text
?? reports/surface/surface_engine_lot_94_pack_runtime_surface_closure_and_gameplay_semantics_decision.md
```

`git diff --stat` final :

```text
```

Recherche de fichiers temporaires :

```text
```

`git diff --check` :

```text
```

## 20. Périmètre explicitement non touché

Confirmé par le périmètre des changements :

- `map_core` non modifié.
- `map_editor` non modifié.
- `map_gameplay` non modifié.
- `map_battle` non modifié.
- `map_runtime` production non modifié.
- `ProjectManifest` non modifié.
- `surface.dart` non modifié.
- `surface_catalog.dart` non modifié.
- codecs Surface non modifiés.
- aucune migration legacy.
- aucun gameplay surf.
- aucun tall grass encounter.
- aucune nouvelle clock runtime.
- aucun changement JSON volontaire.
- aucun changement Surface Studio.
- aucun changement Surface Painter.

## 21. Limites restantes

Limites restantes après clôture :

- GameWidget screenshot complet encore absent.
- Gameplay surf non spécifié.
- Tall grass encounters non spécifiés.
- Collision Surface non spécifiée.
- Semantics gameplay non persistées.
- Performance/culling non traités.
- Diagnostics runtime utilisateur encore minimaux.

Ces limites relèvent de nouveaux lots et ne remettent pas en cause la fermeture du Runtime Surface V0 visuel.

## 22. Auto-critique

Le rapport ferme proprement le runtime visuel, mais il reste documentaire : il ne renforce pas la couverture `GameWidget`. Ce choix est volontaire, car le prompt demande une clôture/décision et pas un nouveau test.

La décision semantics reste une recommandation V0. Elle devra être transformée en spec plus concrète avant de toucher aux modèles persistants.

## 23. Regard critique sur le prompt

Le pack est bien choisi : fermer le runtime et décider la séparation gameplay au même moment évite d'enchaîner immédiatement sur surf/tallGrass avec une architecture confuse.

Le seul point à surveiller : la roadmap proposée mentionne des numéros de lots futurs qui peuvent entrer en conflit avec des lots déjà planifiés ailleurs. Il faudra traiter ces numéros comme une suggestion d'ordre, pas comme un contrat absolu.

## Table de synthèse lots 89–93

| Lot | Sujet | Fichiers principaux | Tests principaux | Garantie obtenue | Limites restantes | Statut |
| --- | --- | --- | --- | --- | --- | --- |
| 89 | Runtime Surface Tileset Collection + Resolver V0 | `surface_runtime_render_instruction.dart`, `surface_runtime_resolver.dart`, `surface_runtime_tileset_collector.dart`, `runtime_manifest_tilesets.dart` | `surface_runtime_resolver_test.dart`, `surface_runtime_tileset_collector_test.dart`, `runtime_manifest_tilesets_surface_layer_test.dart` | Le runtime collecte les tilesets Surface et produit des instructions pures | Pas de dessin Flame dans ce lot | Fermé |
| 90 | Runtime Surface Flame Renderer V0 | `map_layers_component.dart` | `surface_runtime_renderer_test.dart`, `map_layers_component_render_pass_test.dart` | `MapLayersComponent` dessine les vraies tiles Surface et anime via `_animElapsed` | Pas de projet disque réel dans ce lot | Fermé |
| 91 | Runtime Surface Golden Slice / Project Fixture E2E V0 | `surface_runtime_golden_slice_test.dart` | `surface_runtime_golden_slice_test.dart` | Projet disque réel -> PNG -> loader -> pixel rouge/bleu | Pas de host jouable complet | Fermé |
| 92-pack | Runtime Surface Ordering / Regression / Missing Asset Hardening V0 | `surface_runtime_ordering_test.dart`, `surface_runtime_missing_assets_test.dart`, `surface_runtime_test_support.dart` | `test/surface`, `runtime_manifest_tilesets_surface_layer_test.dart`, `map_layers_component_render_pass_test.dart` | Ordre, visibilité/opacité, assets manquants, catalogue incomplet verrouillés | Pas de gameplay ni diagnostics riches | Fermé |
| 93-pack | Surface Runtime Playable Host Smoke / Real App Integration V0 | `surface_runtime_playable_host_smoke_test.dart` | `surface_runtime_playable_host_smoke_test.dart`, `test/surface` | `RuntimeMapGame` rend rouge/bleu, `PlayableMapGame` démarre/ticke avec SurfaceLayer | Pas de screenshot `GameWidget` complet | Fermé |

## Auto-review obligatoire

- Est-ce que les lots 89–93 sont synthétisés ? Oui.
- Est-ce que les garanties runtime Surface V0 sont listées ? Oui.
- Est-ce que les limites sont listées honnêtement ? Oui.
- Est-ce que Runtime Surface V0 peut être considéré fermé ? Oui, pour le rendu visuel runtime V0 ; non pour gameplay.
- Est-ce que la séparation visual/gameplay est décidée ? Oui.
- Est-ce que le prochain lot recommandé est clair ? Oui : Lot 95 — Surface Gameplay Semantics Spec / No-Code Design V1.
- Est-ce que les tests runtime Surface ont été relancés ? Oui.
- Est-ce que map_core est inchangé ? Oui.
- Est-ce que map_editor est inchangé ? Oui.
- Est-ce qu’un Lot 94-bis est nécessaire ? Non. Le prochain vrai besoin est une spec semantics gameplay, pas un correctif de clôture.
