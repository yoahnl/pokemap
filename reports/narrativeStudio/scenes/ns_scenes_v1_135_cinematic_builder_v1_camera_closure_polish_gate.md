# NS-SCENES-V1-135 — Cinematic Builder V1 Camera Closure / Polish Gate

## 1. Résumé exécutif

Statut : **DONE**.

V1-135 ferme la séquence caméra V1 par une passe ciblée de polish/gate. Le lot n'ajoute pas de capacité caméra majeure : il harmonise le wording visible entre inspecteur, overlay symbolique et overlay géométrique, ajoute des tests de fermeture V1-135, régénère une Visual Gate finale et aligne les roadmaps vers V1-136.

Verdict : la preview affiche toujours le cadrage caméra editor-only issu de `cameraPose.geometry`, sans piloter la vue, sans runtime, sans Flame, sans GameState et sans mutation du viewport editor.

## 2. Rappel V1-130 à V1-134

- V1-130 : contrat Camera Target / Zoom, cible `Centre de la scene / Acteur / Repere`, plans `Plan large / Plan moyen / Gros plan`.
- V1-131 : core model, bindings typés, opérations pures et diagnostics camera target/zoom.
- V1-132 : UI d'authoring Camera Target / Zoom dans l'inspecteur.
- V1-133 : `cameraPose.geometry` expose une géométrie camera dérivée dans le read model playback.
- V1-134 : preview editor-only avec cadre caméra, marqueur cible, labels no-code et diagnostics lisibles.

## 3. Audit initial

Préconditions V1-134 vérifiées :

- `CinematicCameraGeometryPreviewOverlay` présent.
- Clés widget `cinematic-builder-camera-geometry-overlay`, `cinematic-builder-camera-geometry-frame`, `cinematic-builder-camera-geometry-target-marker` présentes.
- Wording canonique `Cadrage affiché, vue non pilotée.` présent.
- `cameraPose.geometry` consommé par l'UI.
- Rapport, Evidence Pack et capture V1-134 présents.

Constat produit :

- L'overlay géométrique affichait déjà le bon statut canonique.
- L'overlay symbolique réutilisait exactement la même phrase, créant un doublon visuel.
- L'inspecteur focus conservait `Cadrage configuré, preview réelle à venir.`, devenu ambigu depuis V1-134 puisque le cadrage est désormais visible.

## 4. Décisions de polish

Décision retenue : conserver la phrase canonique sur l'overlay géométrique, rendre l'overlay symbolique plus secondaire, et faire dire à l'inspecteur que le cadrage est visible sans promettre une vraie caméra.

Wording final :

- Overlay géométrique : `Cadrage affiché, vue non pilotée.`
- Overlay symbolique : `Cadrage visible dans la preview.`
- Inspecteur Camera focus : `Cadrage visible dans la preview. La vue reste non pilotée.`

## 5. Wording final caméra

Le wording indique explicitement que :

- le cadrage camera est visible ;
- la vue de l'éditeur reste contrôlée par l'éditeur ;
- aucune caméra runtime, aucun pan et aucun zoom réel ne sont actifs.

Les formulations suivantes ne sont plus attendues en focus avec géométrie visible :

- `Caméra non prévisualisée dans cette version.`
- `Cadrage configuré, preview réelle à venir.`

## 6. Fichiers modifiés

Code editor :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_camera_preview_overlay.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`

Documentation et preuves :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_135_cinematic_builder_v1_camera_closure_polish_gate.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_135_evidence_pack.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_135_cinematic_builder_v1_camera_closure_polish_gate.png`

## 7. Tests exécutés

Depuis `packages/map_editor` :

```bash
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-135"
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-134"
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-132"
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-124"
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-129"
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_camera_geometry_preview_overlay.dart lib/src/ui/canvas/cinematics/cinematic_camera_preview_overlay.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
flutter build macos --debug
```

Résultats :

- V1-135 : `All tests passed!`
- V1-134 : `All tests passed!`
- V1-132 : `All tests passed!`
- V1-124 : `All tests passed!`
- V1-129 : `All tests passed!`
- Analyse ciblée : exit 0 avec infos `prefer_const_*` historiques/non fatales.
- Build macOS debug : `✓ Built build/macos/Build/Products/Debug/map_editor.app`

## 8. Visual Gate

Capture finale :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_135_cinematic_builder_v1_camera_closure_polish_gate.png
```

Preuve fichier :

```text
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
SHA-256: 788b64ab4fbe297c3d461fa97b4fb1c793a6201e3b7038ae82c6af4c7dbef123
```

La capture montre le Cinematic Builder, un bloc Camera focus sélectionné, le cadre caméra visible, le marqueur cible, le wording final cohérent, l'inspecteur et la timeline.

## 9. Anti-scope

Confirmé :

- aucun runtime camera ;
- aucun Flame ;
- aucun GameState ;
- aucun `map_runtime`, `map_gameplay`, `map_battle` ;
- aucun `map_core` modifié par V1-135 ;
- aucune mutation viewport editor ;
- aucun pan/zoom réel ;
- aucune Visual Gate V1-136 ;
- aucun fichier Selbrume modifié.

## 10. Limites caméra V1 assumées

V1 ferme :

- authoring cible/zoom ;
- modèle core ;
- read model geometry ;
- preview editor-only du cadrage ;
- diagnostics no-code ;
- compatibilité seek/scrub avec preview.

V1 ne fait pas :

- vraie caméra runtime ;
- vue pilotée ;
- pan/zoom réel ;
- interpolation caméra ;
- follow actor permanent ;
- overlap temporel avancé ;
- timeline parallèle ;
- runtime cinematic complet.

## 11. Backlog caméra V2 explicite

Backlog volontairement non démarré :

- vraie caméra runtime ;
- translation de presets en zoom/pan réel ;
- interpolation temporelle de caméra ;
- follow actor continu ;
- gestion avancée de plans superposés ;
- caméra côté Flame/runtime ;
- pilotage effectif du viewport.

## 12. Prochain lot recommandé

`NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit`

Objectif recommandé : fermer officiellement le Cinematic Builder V1 avec une matrice de readiness, les limites assumées, le backlog V2 et les validations finales. V1-136 est recommandé, non démarré.

## 13. Auto-critique finale

Le lot reste volontairement petit. Le polish corrige le point de contradiction visible sans étendre la caméra. La Visual Gate générée par widget test est claire pour le cadrage et la timeline, même si le rendu de test ne remplace pas une session manuelle exhaustive dans l'app desktop. Les diagnostics humains couvrent les cas clés testés, mais le futur audit V1-136 devra décider si la fermeture globale du Builder impose une passe visuelle plus large hors caméra.
