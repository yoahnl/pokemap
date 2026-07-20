# NSC-64 — Montage timeline professionnel

Date : 2026-07-20

Statut proposé : **DONE**

## Audit initial et verdict

La timeline possédait déjà lanes, temps proportionnel, zoom, scrub, clavier unitaire et resize. Elle ne possédait aucun contrat pur pour déplacer une sélection, cloner, copier/coller ou supprimer en groupe, aucun ordre stable explicite et aucun état de piste collapse/lock/mute/solo.

Aucun sub-agent n'a été lancé conformément à l'instruction active. Passes domaine, échelle, contrôleur clavier et régression ciblée : **GO**.

## Fichiers modifiés

- `packages/map_core/lib/map_core.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart`
- `packages/map_core/test/cinematic_timeline_lane_read_model_test.dart`
- `packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/builder/cinematic_timeline_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`

## Fichiers créés

- `packages/map_core/lib/src/authoring/cinematic_timeline_editing_operations.dart`
- `packages/map_core/test/cinematic_timeline_editing_operations_test.dart`
- `packages/map_editor/test/ui/canvas/cinematics/cinematic_timeline_editing_test.dart`
- `reports/narrativeStudio/completion/nsc_64_professional_timeline_evidence_pack.md`

Le contenu complet des fichiers créés est versionné dans le commit du lot ; aucun fichier généré ou binaire n'est inclus.

## Zones et comportement

- Move multi-sélection : IDs et ordre relatif préservés.
- Duplicate/copy/paste : IDs réécrits uniquement pour les clones, déterministes en cas de collision.
- Delete groupé : validation de toute la sélection avant création du nouvel asset.
- Clipboard JSON versionné et round-trip pur.
- `stableOrder` explicite pour départager tous les blocs.
- États de piste immuables : collapsed, locked, muted, solo.
- Contrôleur UI : sélection additive et raccourcis Cmd/Ctrl+D/C/V, Delete, Cmd/Ctrl+flèches.
- Toutes les mutations du workspace repassent par `onUpdateCinematicAsset`, donc par la transaction undo/redo existante.
- Fixture 1 000 blocs vérifie copy/paste/delete sans mutation de la source.

## TDD et preuves

RED : APIs d'édition, état de piste et stableOrder absents. GREEN :

```text
cd packages/map_core
dart analyze [6 fichiers NSC-64]
No issues found!

dart test test/cinematic_timeline_editing_operations_test.dart test/cinematic_timeline_lane_read_model_test.dart test/cinematic_timeline_time_layout_read_model_test.dart
+14: All tests passed!

cd packages/map_editor
flutter test test/ui/canvas/cinematics/cinematic_timeline_editing_test.dart test/ui/canvas/cinematics/cinematic_timeline_panel_test.dart test/cinematic_timeline_zoom_controller_test.dart
+7: All tests passed!

flutter test test/cinematic_builder_workspace_test.dart --plain-name 'shows populated cinematic builder in the shared workspace page'
+1: All tests passed!

flutter test test/cinematic_builder_workspace_test.dart --plain-name 'keyboard navigation remains functional after resize'
+1: All tests passed!

flutter analyze [3 fichiers NSC-64]
No issues found!
```

## Non-objectifs, risques et auto-critique

Le modèle V1 reste séquentiel : le snap temporel et les collisions sont donc résolus dans l'ordre canonique, pas sur une horloge multipiste persistée. Mute/solo sont des états de preview du contrôleur et ne modifient jamais l'asset. La sélection additive est disponible par Shift/Cmd/Ctrl et le montage clavier ; une poignée drag multi-blocs pourra plus tard réutiliser exactement l'opération pure livrée ici. Les raccourcis sont volontairement raccordés au point de sauvegarde canonique plutôt que de modifier la liste locale du widget.

État Git initial : propre après `c591b329`. État avant commit : uniquement les fichiers NSC-64 listés.
