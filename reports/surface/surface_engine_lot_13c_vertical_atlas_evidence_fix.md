# Surface Engine Lot 13-ter - Evidence Fix du cleanup Vertical Atlas

## 1. Resume executif

Lot 13-ter limite au correctif documentaire et aux preuves des Lots 11 a 13. Aucun code Dart n'a ete modifie.

Verdict : les helpers Lots 11, 12 et 13 sont deja nettoyes cote `ignore_for_file: invalid_annotation_target`. Les tests actuels prouvent :

- Lot 11 cible : `+23: All tests passed!`
- Lot 12 cible : `+28: All tests passed!`
- Lot 13 cible : `+34: All tests passed!`
- Commande groupee Lots 11-13 : `+85: All tests passed!`
- Suite complete `map_core` : `+370: All tests passed!`
- Analyse ciblee : `No issues found!`

Le total exact actuel est donc 85 pour les trois fichiers cibles et 370 pour `dart test` complet.

## 2. Pourquoi le Lot 13-bis n'etait pas suffisant

Le Lot 13-bis n'etait pas suffisamment prouvant pour validation finale car il ne fournissait pas les sorties de commandes detaillees demandees, ne donnait pas les diffs complets ni le contenu complet des fichiers modifies, et laissait une ambiguite entre l'ancienne review Lot 13 et l'etat courant.

Constat important de ce Lot 13-ter : dans le workspace courant, `reports/surface/surface_engine_lot_13b_vertical_atlas_cleanup.md` ne contient plus la contradiction `+85` contre `24 + 28 + 34 = 86`; il indique deja `23 + 28 + 34 = 85`. La review Lot 13, elle, contient toujours l'ancien calcul `24 + 28 + 34 + 285 = 371`. Le present rapport fixe l'evidence en repartant des fichiers et commandes actuels.

## 3. Fichiers inspectes

Helpers Dart inspectes :

- `packages/map_core/lib/src/operations/tile_visual_frame_vertical_atlas.dart`
- `packages/map_core/lib/src/operations/path_variant_vertical_atlas_mapping.dart`
- `packages/map_core/lib/src/operations/path_preset_vertical_atlas_builder.dart`

Tests inspectes :

- `packages/map_core/test/tile_visual_frame_vertical_atlas_test.dart`
- `packages/map_core/test/path_variant_vertical_atlas_mapping_test.dart`
- `packages/map_core/test/path_preset_vertical_atlas_builder_test.dart`

Rapports inspectes :

- `reports/surface/surface_engine_lot_11_tile_visual_frame_vertical_atlas.md`
- `reports/surface/surface_engine_lot_12_path_variant_vertical_atlas_mapping.md`
- `reports/surface/surface_engine_lot_13_path_preset_vertical_atlas_builder.md`
- `reports/surface/surface_engine_lot_13b_vertical_atlas_cleanup.md`
- `reports/surface/surface_engine_lot_13_review.md`
- `reports/surface/surface_engine_lot_13c_vertical_atlas_evidence_fix.md`

Regles inspectees :

- `AGENTS.md`
- `.cursor/rules/codex-lot-workflow.mdc`
- `karpathy-guidelines/SKILL.md`

## 4. Fichiers modifies

Un seul fichier a ete modifie :

- `reports/surface/surface_engine_lot_13c_vertical_atlas_evidence_fix.md`

Aucun helper Dart n'a ete modifie. Aucun autre rapport Surface n'a ete modifie par ce Lot 13-ter.

## 5. Chemins exacts des fichiers modifies

Chemin modifie par ce lot :

```text
reports/surface/surface_engine_lot_13c_vertical_atlas_evidence_fix.md
```

Chemins reels des rapports Lots 11 a 13 existants dans ce workspace :

```text
reports/surface/surface_engine_lot_11_tile_visual_frame_vertical_atlas.md
reports/surface/surface_engine_lot_12_path_variant_vertical_atlas_mapping.md
reports/surface/surface_engine_lot_13_path_preset_vertical_atlas_builder.md
reports/surface/surface_engine_lot_13b_vertical_atlas_cleanup.md
reports/surface/surface_engine_lot_13_review.md
reports/surface/surface_engine_lot_13c_vertical_atlas_evidence_fix.md
```

Les rapports de cette roadmap Surface Engine sont bien conserves sous `reports/surface/`.

## 6. Verification des `ignore_for_file`

Les trois helpers Dart Lots 11 a 13 ne contiennent pas de directive `ignore_for_file`.

Commande de verification par recherche :

```text
rg "ignore_for_file" packages/map_core/lib/src/operations
```

Sortie pertinente :

```text
packages/map_core/lib/src/operations/legacy_surface_usage_view.dart
  1:// ignore_for_file: invalid_annotation_target
```

Cette sortie ne concerne aucun des trois helpers autorises. Les trois tests cibles contiennent encore `// ignore_for_file: prefer_const_literals_to_create_immutables`, mais la demande de cleanup concernait les helpers Dart et l'analyse ciblee passe.

## 7. Resultats exacts des tests separes

### Lot 11

Commande :

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/tile_visual_frame_vertical_atlas_test.dart
```

Sortie finale exacte :

```text
00:00 +23: All tests passed!
```

Nombre de tests verifie par recherche `test\(` dans le fichier : 23.

### Lot 12

Commande :

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/path_variant_vertical_atlas_mapping_test.dart
```

Sortie finale exacte :

```text
00:00 +28: All tests passed!
```

Nombre de tests verifie par recherche `test\(` dans le fichier : 28.

### Lot 13

Commande :

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/path_preset_vertical_atlas_builder_test.dart
```

Sortie finale exacte :

```text
00:00 +34: All tests passed!
```

Nombre de tests verifie par recherche `test\(` dans le fichier : 34.

## 8. Resultat exact de la commande groupee

Commande :

```bash
cd packages/map_core
/opt/homebrew/bin/dart test \
  test/tile_visual_frame_vertical_atlas_test.dart \
  test/path_variant_vertical_atlas_mapping_test.dart \
  test/path_preset_vertical_atlas_builder_test.dart
```

Sortie finale exacte :

```text
00:00 +85: All tests passed!
```

## 9. Difference entre somme separee et total groupe

Il n'y a pas de difference dans l'etat courant :

```text
23 + 28 + 34 = 85
commande groupee = 85
```

La contradiction `+85` contre `24 + 28 + 34 = 86` signalee pour le Lot 13-bis ne correspond plus au contenu actuel de `reports/surface/surface_engine_lot_13b_vertical_atlas_cleanup.md`, qui indique deja `23 + 28 + 34 = 85`. L'evidence actuelle confirme que le chiffre correct est 85.

## 10. Resultat exact du test complet `map_core`

Commande :

```bash
cd packages/map_core
/opt/homebrew/bin/dart test
```

Dernieres lignes exactes de la sortie compacte :

```text
00:01 +368: test/legacy_editor_json_compat_collision_test.dart: legacy collision profile compat unknown legacy keys do not prevent manifest parsing
00:01 +369: test/legacy_editor_json_compat_collision_test.dart: legacy collision profile compat unknown legacy keys do not prevent manifest parsing
00:01 +369: test/legacy_editor_json_compat_collision_test.dart: legacy collision profile compat missing pokemon config still falls back to the manifest default
00:01 +370: test/legacy_editor_json_compat_collision_test.dart: legacy collision profile compat missing pokemon config still falls back to the manifest default
00:01 +370: All tests passed!
```

## 11. Explication du total final

Le total complet actuel est `+370: All tests passed!`.

La review Lot 13 indiquait `+371: All tests passed!` et calculait :

```text
24 + 28 + 34 + 285 = 371
```

Ce calcul dependait d'un Lot 11 a 24 tests. Or l'etat courant prouve :

```text
Lot 11 = 23 tests
Lot 12 = 28 tests
Lot 13 = 34 tests
Autres tests map_core = 285
285 + 23 + 28 + 34 = 370
```

La difference `371 -> 370` vient donc du chiffre Lot 11 de la review. Dans ce workspace, le fichier `test/tile_visual_frame_vertical_atlas_test.dart` contient 23 appels `test(` et la commande separee confirme `+23`. Le total faisant foi est celui de la commande complete actuelle : 370.

## 12. Corrections documentaires effectuees

Corrections effectuees par ce Lot 13-ter :

- Remplacement du rapport d'evidence au bon emplacement : `reports/surface/surface_engine_lot_13c_vertical_atlas_evidence_fix.md`.
- Clarification des chemins reels : les rapports existants Lots 11 a 13 sont sous `reports/surface/`.
- Clarification du total cible : 85, sans difference entre somme separee et commande groupee.
- Clarification du total complet : 370, avec explication de l'ancienne valeur 371.
- Confirmation que les helpers Dart n'ont pas de `ignore_for_file`.
- Confirmation qu'aucun code runtime/editor/gameplay, modele persistant, fichier Freezed/JSON ou API helper n'a ete touche.

## 13. Diffs complets

Le diff complet de ce rapport est fourni dans la reponse finale du Lot 13-ter. Le fichier documentaire temporairement cree sous `reports/analysis/` a ete supprime pour respecter l'emplacement attendu `reports/surface/`.

## 14. Contenu complet des fichiers modifies

Le seul fichier modifie est ce rapport :

```text
reports/surface/surface_engine_lot_13c_vertical_atlas_evidence_fix.md
```

Son contenu complet est le present document et est fourni dans la reponse finale du Lot 13-ter.

## 15. Analyse statique

Commande :

```bash
cd packages/map_core
/opt/homebrew/bin/dart analyze \
  lib/src/operations/tile_visual_frame_vertical_atlas.dart \
  lib/src/operations/path_variant_vertical_atlas_mapping.dart \
  lib/src/operations/path_preset_vertical_atlas_builder.dart \
  test/tile_visual_frame_vertical_atlas_test.dart \
  test/path_variant_vertical_atlas_mapping_test.dart \
  test/path_preset_vertical_atlas_builder_test.dart \
  lib/map_core.dart
```

Sortie exacte :

```text
Analyzing tile_visual_frame_vertical_atlas.dart, path_variant_vertical_atlas_mapping.dart, path_preset_vertical_atlas_builder.dart, tile_visual_frame_vertical_atlas_test.dart, path_variant_vertical_atlas_mapping_test.dart, path_preset_vertical_atlas_builder_test.dart, map_core.dart...
No issues found!
```

## 16. Etat Git et commandes Git

Commandes Git autorisees lancees :

```bash
git status --short
git diff --stat
git diff
git log --oneline -5
```

Sorties initiales avant correction du chemin :

```text
git status --short
(aucune sortie)

git diff --stat
(aucune sortie)

git diff
(aucune sortie)

git log --oneline -5
5f9a1736 update lot 13
fcad54ba lot 11
301048c6 lot 8 - 10
29ff071b lot 1 - 8: refactor runtime
c70d249b Surface Engine Lot 0: Initial audit and characterization
```

Aucune commande Git d'ecriture interdite n'a ete utilisee.

## 17. Auto-review

- Lot limite a l'evidence/documentation fix : oui.
- Rapport place sous `reports/surface/` : oui.
- Aucun modele Surface persistant cree : oui.
- Aucun fichier Freezed/JSON, `.g.dart` ou `.freezed.dart` modifie : oui.
- Aucun `map_runtime`, `map_editor`, `map_gameplay` ou `map_battle` modifie : oui.
- Aucun `ProjectManifest`, `MapData`, `TerrainLayer` ou `PathLayer` modifie : oui.
- APIs des helpers Lots 11, 12, 13 inchangees : oui.
- Chemins de fichiers exacts documentes : oui.
- Sorties de tests exactes documentees : oui, avec lignes finales des commandes obligatoires.
- Contradiction 85/86 expliquee : oui, le total courant est 85.
- Contradiction 370/371 expliquee : oui, la review Lot 13 utilisait un Lot 11 a 24 tests, l'etat courant en a 23.
- Diffs complets : oui, fournis en reponse finale.
- Contenu complet des fichiers modifies : oui, fourni en reponse finale.
- Aucune commande Git interdite utilisee : oui.

## 18. Verdict

Lot 13-ter termine et limite au correctif de preuves/documentation. Les preuves actuelles valident `+85` pour les tests cibles Lots 11 a 13 et `+370` pour le `dart test` complet de `map_core`.
