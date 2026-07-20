# NSC-66 — Catalogue authorable Dialogue, Shake, Audio, Music, FX et Marker

Date : 2026-07-20

Statut proposé : **DONE**

## Audit initial et verdict

Le contrat `CinematicTimelineStep` savait sérialiser les kinds avancés, mais le
Builder les présentait encore comme verrouillés. Il n'existait ni opération
d'authoring atomique, ni picker typé, ni validation projet des références
Dialogue/média, ni dépendance enregistrée depuis une commande.

Aucun sub-agent n'a été lancé conformément à l'instruction active. Passes
domaine, sérialisation, diagnostics, dépendances, UI no-code, rechargement et
régression Builder : **GO**.

## Fichiers modifiés

- `packages/map_core/lib/map_core.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/lib/src/read_models/narrative_dependency_index.dart`
- `packages/map_core/test/cinematic_authoring_operations_test.dart`
- `packages/map_core/test/cinematic_diagnostics_test.dart`
- `packages/map_core/test/narrative_dependency_index_test.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_navigation.dart`
- `packages/map_editor/lib/src/ui/design_system/narrative/pokemap_dependency_inspector.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`

## Fichiers créés

- `packages/map_core/lib/src/authoring/cinematic_command_authoring_operations.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/builder/cinematic_media_picker.dart`
- `packages/map_editor/test/ui/canvas/cinematics/cinematic_media_picker_test.dart`
- `reports/narrativeStudio/completion/nsc_66_cinematic_command_authoring_evidence_pack.md`

Le contenu complet des fichiers créés est versionné dans le commit du lot ;
aucun fichier généré, binaire ou dépendant de la machine n'est inclus.

## Zones précises et comportement livré

- Opérations pures add/update/remove pour `dialogueLine`, `shake`, `sound`,
  `music`, `fx` et `marker`, avec insertion déterministe et IDs sans collision.
- Round-trip JSON de toutes les commandes, paramètres compris : acteur,
  dialogue, média, durée, volume, fondu, boucle et intensité.
- Validation atomique du kind média, des acteurs, durées et bornes numériques.
- Blocage explicite de publication pour les commandes runtime encore en
  attente de NSC-67 ; `marker` est déclaré éditorial et non exécutable.
- Diagnostics projet pour dialogue/média supprimé, type média incompatible,
  volume/fondu/intensité invalides et statut runtime pending.
- Index de dépendances runtime-blocking de la Cinematic vers le Dialogue ou le
  média sélectionné.
- Palette Builder complète et honnête : les six commandes sont visibles ; les
  commandes dépendantes sont désactivées lorsque leur bibliothèque est vide.
- Inspecteur token-driven fondé uniquement sur le design system : pickers
  Dialogue, intervenant et média, sliders volume/intensité, fondu et boucle.
- Aucun chemin de fichier ni ID libre n'est exposé dans le flux normal.
- Le type de dépendance `media` est lisible dans l'inspecteur et navigue vers la
  bibliothèque Cinematics.

## TDD et preuves exactes

```text
cd packages/map_core
dart test
+4298: All tests passed!

dart analyze
No issues found!

cd packages/map_editor
flutter test test/cinematic_builder_workspace_test.dart
+294: All tests passed!

flutter test test/ui/canvas/cinematics/cinematic_media_picker_test.dart
+2: All tests passed!

flutter test test/ui/design_system/pokemap_dependency_inspector_test.dart test/ui/canvas/narrative_studio_navigation_test.dart
+17: All tests passed!

flutter analyze [7 fichiers NSC-66]
No issues found!

flutter analyze
11 warnings préexistants, tous dans
lib/src/ui/canvas/dialogue_studio/dialogs/dialogue_studio_dialogs.dart ;
aucun warning dans les fichiers NSC-66.

git diff --check
aucune erreur
```

## Décisions, non-objectifs, risques et auto-critique

NSC-66 ne prétend pas jouer ces commandes. Les commandes exécutables portent
donc un statut `draftUntilNsc67` et restent bloquantes pour la publication ;
lever ce statut sans la preuve preview/runtime commune de NSC-67 serait
mensonger. Le picker média consomme le catalogue canonique du projet et ne
permet volontairement ni chemin arbitraire ni ID technique. Le texte inline
libre d'une commande Dialogue n'est pas le workflow principal : le Dialogue
canonique est la source.

La suite Editor complète n'est pas verte à cause de 11 warnings existants dans
Dialogue Studio, hors périmètre et non modifiés. Les tests complets du Builder,
les tests ciblés de navigation/design system et l'analyse de tous les fichiers
touchés sont verts. Le prochain risque principal est l'orchestration temporelle
et le rollback audio/caméra de NSC-67.

État Git initial : propre après `7e495705`. État avant commit : uniquement les
fichiers NSC-66 listés ci-dessus.
