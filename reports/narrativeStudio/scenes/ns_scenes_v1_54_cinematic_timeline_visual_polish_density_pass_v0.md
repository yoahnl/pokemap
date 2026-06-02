# NS-SCENES-V1-54 — Cinematic Timeline Visual Polish / Density Pass V0

Date : 2026-06-02  
Statut propose : DONE  
Lot precedent : `NS-SCENES-V1-53 — Cinematic Timeline Transport Controls Placeholder V0`  
Prochain lot recommande : `NS-SCENES-V1-55 — Cinematic Timeline Interaction Polish / Hover Details V0`

## 1. Resume executif

V1-54 polit la densite visuelle de la timeline du Cinematic Builder sans lui donner de nouveau pouvoir.

Le rendu reste editor-only et non runtime : les lanes sont plus compactes, les barres plus basses, les labels de pistes vides sont raccourcis, les controles transport prennent moins d'espace vertical et le strip de metadata des barres retire les IDs/bruits redondants.

L'objectif image demande par Karim est respecte sur le point vise par ce lot : preview sandbox gardee compacte, timeline agrandie/lisible, proportions controlees en surface 1663x926 et Visual Gate dedie.

Evidence Pack : `reports/narrativeStudio/scenes/ns_scenes_v1_54_evidence_pack.md`.

## 2. Scope realise

- Timeline panel densifie via padding/spacing plus courts.
- Largeur header lane reduite de `154` a `146`.
- Axe reduit de `28` a `24`.
- Hauteur lane reduite de `30` a `28`.
- Hauteur de barre explicite `22`.
- Empty state de lane : `Aucun step` au lieu d'une phrase longue.
- Controles transport V1-53 passes en `PokeMapButtonSize.medium`, largeur `76`, spacing plus compact.
- Metadata strip allegee : kind, duree, direction/mode/path diagnostics/selection, sans IDs acteur/cible/assetRef visibles dans les barres.
- Test de densite visuelle sur surface reference.
- Screenshot Visual Gate V1-54.

## 3. Contrat

Confirme :

- pas de playback ;
- pas de timer ;
- pas de seek ;
- pas de scrubber ;
- pas de drag/drop ;
- pas de resize/reorder ;
- pas de mutation JSON ;
- pas de build_runner ;
- pas de changement runtime/gameplay/battle/examples ;
- pas de changement de read model core.

## 4. Design system

Le lot reste dans les primitives existantes :

- `PokeMapPanel`
- `PokeMapCard`
- `PokeMapBadge`
- `PokeMapButton`
- `context.pokeMapColors`
- `CupertinoIcons`

Recherche anti-couleurs hardcodees sur les fichiers modifies : sortie vide.

## 5. Tests ajoutes ou modifies

Ajoute :

- `renders polished dense timeline on reference surface`
- `captures V1-54 timeline visual polish density pass when requested`

Le test de densite verifie :

- preview `<= 450`;
- timeline `>= 390`;
- lane camera `<= 28`;
- barre selectionnee `<= 22`;
- bouton Reset `<= 40`;
- curseur aligne sur la barre selectionnee ;
- axe/ticks/badge selection visibles ;
- labels actorMove `Professor -> Centre scene`, `Marche`, `Direct` visibles ;
- transport Reset/Play/Stop visible et toujours disabled par les tests V1-53 ;
- aucune mutation `ProjectManifest`.

## 6. Visual Gate

Capture :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_54_cinematic_timeline_visual_polish_density_pass_v0.png
```

Commande :

```bash
cd packages/map_editor
flutter test --update-goldens --dart-define=NS_SCENES_V1_54_CAPTURE_CINEMATIC_TIMELINE_VISUAL_POLISH=true --reporter=compact test/cinematic_builder_workspace_test.dart
```

Resultat : `All tests passed!`

## 7. Validation

Verts :

- `cd packages/map_core && dart test test/cinematic_timeline_time_layout_read_model_test.dart`
- `cd packages/map_core && dart test test/cinematic_timeline_lane_read_model_test.dart`
- `cd packages/map_core && dart analyze`
- `cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart`
- `cd packages/map_editor && flutter analyze lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart`
- Visual Gate V1-54 ci-dessus

Analyse complete `map_editor` :

- `cd packages/map_editor && flutter analyze`
- Resultat : echec hors scope avec 344 issues preexistantes, principalement `pokemon_sdk_move_catalog_converter.dart` / `sync_pokemon_sdk_moves_catalog_use_case.dart` et warnings historiques.
- Les fichiers modifies par V1-54 passent l'analyse ciblee sans issue.

## 8. Fichiers modifies

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_54_cinematic_timeline_visual_polish_density_pass_v0.png`
- `reports/narrativeStudio/scenes/ns_scenes_v1_54_cinematic_timeline_visual_polish_density_pass_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_54_evidence_pack.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 9. Limites

La timeline est plus lisible et plus dense, mais elle reste une projection derivee :

- pas editable temporellement ;
- pas de hover details ;
- pas de tooltip avance sur barres ;
- pas de zoom temporel ;
- pas de selection multi-bloc ;
- pas de player.

## 10. Prochain lot

`NS-SCENES-V1-55 — Cinematic Timeline Interaction Polish / Hover Details V0`

Objectif recommande : ajouter des affordances d'inspection legere au survol/tap sans ouvrir le playback ni l'edition temporelle.
