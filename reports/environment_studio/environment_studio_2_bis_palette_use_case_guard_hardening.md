# EnvironmentStudio-2-bis — Palette Use Case Guard Hardening V0

## 1. Résumé

EnvironmentStudio-2-bis durcit et clarifie deux réserves de review du Lot 2 :

- le poids des items de palette est bien validé hors UI par le modèle domaine `EnvironmentPaletteItem` ;
- les tests use case caractérisent le refus de `weight == 0` et `weight < 0` avant toute mutation ;
- le contrat palette vide est clarifié : elle reste refusée dans ce mini-lot car `map_core.EnvironmentPreset` la refuse déjà et `map_core` est hors périmètre ;
- aucun code produit n’a été modifié dans ce bis ;
- aucun workflow map, peinture, génération, canvas ou TileLayer inspector n’a été touché.

## 2. Contexte EnvironmentStudio-2

EnvironmentStudio-2 avait ajouté le flow palette draft/save en mémoire :

- brouillon local dans `EnvironmentStudioPanel` ;
- bouton `Modifier la palette` ;
- bouton `Enregistrer la palette` ;
- bouton `Annuler les changements` ;
- `UpdateEnvironmentPresetPaletteUseCase` ;
- guard anti-mélange de tilesets ;
- picker compatible tileset ;
- sauvegarde mémoire via `onEnvironmentPresetSaved`.

Le worktree au début du bis contenait encore les fichiers du Lot 2 non commités et non ajoutés à Git. Le bis travaille donc au-dessus de cet état, sans utiliser `git add`, commit ou push.

## 3. Réserves traitées

Réserve 1 :

```text
Le use case ne semble pas valider explicitement le poids des items de palette hors UI.
```

Résolution :

- audit du modèle `EnvironmentPaletteItem` ;
- confirmation que `weight < 1` est déjà refusé par le modèle domaine ;
- ajout de tests côté use case prouvant que `weight == 0` et `weight < 0` ne peuvent pas atteindre une sauvegarde palette.

Réserve 2 :

```text
Le prompt initial demandait d’autoriser la palette vide, mais map_core.EnvironmentPreset semble actuellement la refuser.
```

Résolution :

- confirmation que `EnvironmentPreset` refuse `palette.isEmpty` ;
- conservation du comportement actuel sans modifier `map_core` ;
- test maintenu et renforcé pour prouver que la palette vide est refusée sans mutation du `ProjectManifest`.

## 4. Audit du modèle EnvironmentPaletteItem / EnvironmentPreset

Fichiers inspectés :

- `packages/map_core/lib/src/models/environment.dart`
- `packages/map_editor/lib/src/features/environment_studio/authoring/environment_preset_palette_use_cases.dart`
- `packages/map_editor/lib/src/features/environment_studio/authoring/environment_preset_draft.dart`
- `packages/map_editor/test/environment_studio/environment_preset_palette_use_case_test.dart`
- `packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart`

Extrait modèle poids :

```dart
if (weight < 1) {
  throw ArgumentError.value(
    weight,
    'weight',
    'EnvironmentPaletteItem weight must be >= 1.',
  );
}
```

Extrait modèle palette vide :

```dart
if (palette.isEmpty) {
  throw ArgumentError.value(
    palette,
    'palette',
    'EnvironmentPreset palette must not be empty.',
  );
}
```

Extrait validation UI/draft existante :

```dart
if (item.weight <= 0) {
  add(EnvironmentPresetDraftIssue(
    severity: EnvironmentPresetDraftIssueSeverity.error,
    kind: EnvironmentPresetDraftIssueKind.invalidPaletteWeight,
    message:
        'Environment preset draft palette item weight must be >= 1 (index $i).',
    elementId: eid.isEmpty ? null : eid,
    paletteIndex: i,
  ));
}
```

Conclusion :

- la règle UI actuelle est bien alignée sur `weight >= 1` ;
- le modèle domaine applique la même règle hors UI ;
- le use case reçoit une `List<EnvironmentPaletteItem>`, donc un item invalide ne peut pas être construit par l’API publique actuelle ;
- le bis ajoute une preuve de caractérisation côté test use case au lieu de dupliquer une validation complexe.

## 5. Décision poids

Décision retenue :

```text
weight >= 1
```

Comportements validés :

- `weight == 0` est refusé par `EnvironmentPaletteItem` ;
- `weight < 0` est refusé par `EnvironmentPaletteItem` ;
- le use case n’est pas atteint dans ces deux cas ;
- le `ProjectManifest` original reste inchangé ;
- un poids positif est accepté quand les autres validations sont satisfaites.

Cette protection est hors UI : elle vient du modèle domaine, pas du picker ni d’un warning visuel.

## 6. Décision palette vide

Décision retenue :

```text
palette vide refusée dans EnvironmentStudio-2-bis
```

Justification :

- le prompt EnvironmentStudio-2 souhaitait autoriser une palette vide ;
- `map_core.EnvironmentPreset` refuse déjà une palette vide ;
- EnvironmentStudio-2-bis interdit de modifier `map_core` ;
- le bis ne change donc pas le modèle domaine ;
- le comportement réel est documenté comme limitation actuelle.

Conséquence :

- une sauvegarde palette vide est refusée ;
- le `ProjectManifest` original reste inchangé ;
- les autres presets ne sont pas modifiés.

Point à trancher plus tard :

- si le produit veut réellement des presets vides, il faudra un lot explicite qui modifie le contrat `map_core.EnvironmentPreset` et ses tests.

## 7. Changements réalisés

Changements EnvironmentStudio-2-bis :

- ajout du test `refuse poids zéro avant toute mutation` ;
- ajout du test `refuse poids négatif avant toute mutation` ;
- renforcement du test palette vide avec vérification de non-mutation ;
- renommage du test positif en `accepte poids positif et plusieurs éléments du même tileset` ;
- ajout du helper test `_expectOriginalProjectUnchanged`.

Aucun changement réalisé dans :

- `map_core` ;
- code UI ;
- use case production ;
- notifier ;
- canvas ;
- TileLayer inspector ;
- generated files.

## 8. Tests

Commande lancée par erreur en parallèle avec une autre commande Flutter :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_preset_palette_use_case_test.dart
```

Résultat exact :

```text
Waiting for another flutter command to release the startup lock...
Unable to delete file or directory at "/Users/karim/Project/pokemonProject/packages/map_editor/macos/Flutter/ephemeral/Packages/.packages". This may be due to the project being in a read-only volume. Consider relocating the project and trying again.
```

Cause identifiée :

```text
Deux commandes flutter test ont été lancées en parallèle. La deuxième a échoué sur le lock Flutter startup/ephemeral.
```

Action prise :

```text
Relance séquentielle des commandes Flutter.
```

Commande use case relancée séquentiellement :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_preset_palette_use_case_test.dart
```

Résultat exact :

```text
00:00 +0: UpdateEnvironmentPresetPaletteUseCase update palette modifie uniquement le preset ciblé
00:00 +1: UpdateEnvironmentPresetPaletteUseCase préserve les autres presets et ne mute pas le project original
00:00 +2: UpdateEnvironmentPresetPaletteUseCase refuse presetId vide
00:00 +3: UpdateEnvironmentPresetPaletteUseCase refuse preset introuvable
00:00 +4: UpdateEnvironmentPresetPaletteUseCase refuse élément introuvable
00:00 +5: UpdateEnvironmentPresetPaletteUseCase refuse palette mélangeant deux tilesets
00:00 +6: UpdateEnvironmentPresetPaletteUseCase refuse élément sans tileset source
00:00 +7: UpdateEnvironmentPresetPaletteUseCase refuse poids zéro avant toute mutation
00:00 +8: UpdateEnvironmentPresetPaletteUseCase refuse poids négatif avant toute mutation
00:00 +9: UpdateEnvironmentPresetPaletteUseCase refuse palette vide car EnvironmentPreset map_core la rejette
00:00 +10: UpdateEnvironmentPresetPaletteUseCase accepte poids positif et plusieurs éléments du même tileset
00:00 +11: All tests passed!
```

Commande widget palette :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_preset_palette_draft_editor_test.dart
```

Résultat exact :

```text
00:00 +0: EnvironmentStudioPanel — palette brouillon (Lot 14) ajouter un item : emptyPalette disparaît, emptyPaletteElementId
00:00 +1: EnvironmentStudioPanel — palette brouillon (Lot 14) elementId connu : plus d’emptyPaletteElementId ni missingPaletteElement
00:00 +2: EnvironmentStudioPanel — palette brouillon (Lot 14) picker bibliothèque remplit elementId
00:01 +3: EnvironmentStudioPanel — palette brouillon (Lot 14) picker bibliothèque filtre les éléments du tileset source
00:01 +4: EnvironmentStudioPanel — palette brouillon (Lot 14) saisie manuelle incompatible déclenche Tilesets mélangés
00:01 +5: EnvironmentStudioPanel — palette brouillon (Lot 14) elementId absent : Élément introuvable
00:01 +6: EnvironmentStudioPanel — palette brouillon (Lot 14) poids 3 valide, poids 0 invalide, texte non numérique inchangé
00:01 +7: EnvironmentStudioPanel — palette brouillon (Lot 14) collision : bascule Collision forcée puis Collision désactivée
00:02 +8: EnvironmentStudioPanel — palette brouillon (Lot 14) tags : tree, canopy OK ; tree, , canopy → Tag vide
00:02 +9: EnvironmentStudioPanel — palette brouillon (Lot 14) Retirer : palette vide, emptyPalette revient
00:02 +10: EnvironmentStudioPanel — palette brouillon (Lot 14) deux items même elementId : Élément dupliqué
00:02 +11: EnvironmentStudioPanel — palette brouillon (Lot 14) édition palette + retour browser : manifest.environmentPresets inchangé
00:02 +12: EnvironmentStudioPanel — palette save flow (EnvironmentStudio-2) modifier palette affiche un brouillon sale puis annuler restaure
00:02 +13: EnvironmentStudioPanel — palette save flow (EnvironmentStudio-2) enregistrer la palette appelle le callback et garde le preset
00:02 +14: EnvironmentStudioPanel — palette save flow (EnvironmentStudio-2) picker palette exclut un élément incompatible
00:03 +15: EnvironmentStudioPanel — palette save flow (EnvironmentStudio-2) preset mixte bloque save mais permet retirer incompatible
00:03 +16: All tests passed!
```

Vérification du fichier `environment_studio_panel_test.dart` :

```bash
if [ -f packages/map_editor/test/environment_studio/environment_studio_panel_test.dart ]; then echo exists; else echo missing; fi
```

Résultat exact :

```text
missing
```

Fichier équivalent réel relancé :

```text
packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart
```

Régression TileLayer inspector :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Résultat exact :

```text
00:02 +59: All tests passed!
```

Régression Golden Slice :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_golden_slice_workflow_test.dart
```

Résultat exact :

```text
00:00 +6: All tests passed!
```

## 9. Analyse ciblée

Commande :

```bash
cd packages/map_editor
flutter analyze lib/src/features/environment_studio/authoring/environment_preset_palette_use_cases.dart test/environment_studio/environment_preset_palette_use_case_test.dart
```

Résultat exact :

```text
Analyzing 2 items...
No issues found! (ran in 1.4s)
```

## 10. Fichiers créés/modifiés

Fichiers déjà présents/modifiés avant EnvironmentStudio-2-bis :

```text
 M packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart
 M packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart
?? packages/map_editor/lib/src/features/environment_studio/authoring/environment_preset_palette_use_cases.dart
?? packages/map_editor/test/environment_studio/environment_preset_palette_use_case_test.dart
?? reports/environment_studio/environment_studio_2_preset_palette_editor_save_flow.md
```

Fichiers créés par EnvironmentStudio-2-bis :

- `reports/environment_studio/environment_studio_2_bis_palette_use_case_guard_hardening.md`

Fichiers modifiés par EnvironmentStudio-2-bis :

- `packages/map_editor/test/environment_studio/environment_preset_palette_use_case_test.dart`

Fichiers préexistants dans le worktree non touchés par EnvironmentStudio-2-bis :

- `packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart`
- `packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart`
- `packages/map_editor/lib/src/features/environment_studio/authoring/environment_preset_palette_use_cases.dart`
- `reports/environment_studio/environment_studio_2_preset_palette_editor_save_flow.md`

Dettes préexistantes hors lot :

- Le rapport EnvironmentStudio-2 documentait déjà deux échecs hors lot dans la commande globale `flutter test test/environment_studio` :
  - `environment_layer_area_model_editing_test.dart` : tap offscreen puis `Bad state: No element` ;
  - `tile_layer_environment_erase_mode_test.dart` : expectation historique `environmentMaskEditMode == null`, état actuel `erase`.

Problèmes introduits par EnvironmentStudio-2-bis :

- Aucun identifié par les tests ciblés, l’analyse ciblée et `git diff --check`.

## 11. Non-objectifs respectés

- Pas de modification `map_core`.
- Pas de modification du modèle `ProjectManifest`.
- Pas de modification `EnvironmentPreset`.
- Pas de modification `EnvironmentPaletteItem`.
- Pas de build_runner.
- Pas de generated file.
- Pas de changement JSON.
- Pas de champ persistant `sourceTilesetId`.
- Pas de sauvegarde disque.
- Pas de modification TileLayer inspector.
- Pas de modification canvas.
- Pas de peinture/génération dans Environment Studio.
- Pas de création/suppression/duplication de preset.
- Pas de modification identité/default params.
- Pas de refonte UI.

## 12. Evidence Pack

Git status initial :

```bash
git status --short --untracked-files=all
```

Résultat exact :

```text
 M packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart
 M packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart
?? packages/map_editor/lib/src/features/environment_studio/authoring/environment_preset_palette_use_cases.dart
?? packages/map_editor/test/environment_studio/environment_preset_palette_use_case_test.dart
?? reports/environment_studio/environment_studio_2_preset_palette_editor_save_flow.md
```

Git status final :

```bash
git status --short --untracked-files=all
```

Résultat exact :

```text
 M packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart
 M packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart
?? packages/map_editor/lib/src/features/environment_studio/authoring/environment_preset_palette_use_cases.dart
?? packages/map_editor/test/environment_studio/environment_preset_palette_use_case_test.dart
?? reports/environment_studio/environment_studio_2_bis_palette_use_case_guard_hardening.md
?? reports/environment_studio/environment_studio_2_preset_palette_editor_save_flow.md
```

Diff stat :

```bash
git diff --stat
```

Résultat exact :

```text
 .../environment_studio_panel.dart                  | 497 ++++++++++++++++++++-
 .../widgets/environment_preset_detail.dart         |  56 ++-
 ...vironment_preset_palette_draft_editor_test.dart | 239 +++++++++-
 3 files changed, 753 insertions(+), 39 deletions(-)
```

Diff name-only :

```bash
git diff --name-only
```

Résultat exact :

```text
packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart
packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart
```

Note factuelle :

```text
git diff --stat et git diff --name-only ne listent pas les fichiers non suivis. Les fichiers non suivis sont présents dans git status initial/final.
```

Diff check :

```bash
git diff --check
```

Résultat exact :

```text
```

Commandes tests exactes :

```text
flutter test test/environment_studio/environment_preset_palette_use_case_test.dart
flutter test test/environment_studio/environment_preset_palette_draft_editor_test.dart
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
flutter test test/environment_studio/environment_golden_slice_workflow_test.dart
```

Résultats tests exacts :

```text
environment_preset_palette_use_case_test.dart : 00:00 +11: All tests passed!
environment_preset_palette_draft_editor_test.dart : 00:03 +16: All tests passed!
tile_layer_environment_inspector_section_test.dart : 00:02 +59: All tests passed!
environment_golden_slice_workflow_test.dart : 00:00 +6: All tests passed!
```

Commande analyze exacte :

```text
flutter analyze lib/src/features/environment_studio/authoring/environment_preset_palette_use_cases.dart test/environment_studio/environment_preset_palette_use_case_test.dart
```

Résultat analyze exact :

```text
Analyzing 2 items...
No issues found! (ran in 1.4s)
```

## 13. Diff pertinent

Fichier modifié par EnvironmentStudio-2-bis : `packages/map_editor/test/environment_studio/environment_preset_palette_use_case_test.dart`

Hunk pertinent :

```diff
+    test('refuse poids zéro avant toute mutation', () {
+      final project = _project();
+      var reachedUseCase = false;
+
+      expect(
+        () {
+          final item = EnvironmentPaletteItem(elementId: 'grass_a', weight: 0);
+          reachedUseCase = true;
+          useCase(
+            manifest: project,
+            presetId: 'forest',
+            palette: [item],
+          );
+        },
+        throwsArgumentError,
+      );
+
+      expect(reachedUseCase, isFalse);
+      _expectOriginalProjectUnchanged(project);
+    });
+
+    test('refuse poids négatif avant toute mutation', () {
+      final project = _project();
+      var reachedUseCase = false;
+
+      expect(
+        () {
+          final item = EnvironmentPaletteItem(elementId: 'grass_a', weight: -1);
+          reachedUseCase = true;
+          useCase(
+            manifest: project,
+            presetId: 'forest',
+            palette: [item],
+          );
+        },
+        throwsArgumentError,
+      );
+
+      expect(reachedUseCase, isFalse);
+      _expectOriginalProjectUnchanged(project);
+    });
+
     test('refuse palette vide car EnvironmentPreset map_core la rejette', () {
+      final project = _project();
+
       expect(
         () => useCase(
-          manifest: _project(),
+          manifest: project,
           presetId: 'forest',
           palette: const [],
         ),
         throwsArgumentError,
       );
+      _expectOriginalProjectUnchanged(project);
     });
 
-    test('accepte plusieurs éléments du même tileset', () {
+    test('accepte poids positif et plusieurs éléments du même tileset', () {
       final result = useCase(
         manifest: _project(),
         presetId: 'forest',
@@
   });
 }
 
+void _expectOriginalProjectUnchanged(ProjectManifest project) {
+  expect(findProjectEnvironmentPresetById(project, 'forest')!.palette
+      .map((item) => item.elementId), ['grass_a']);
+  expect(findProjectEnvironmentPresetById(project, 'props')!.palette
+      .map((item) => item.elementId), ['rock_a']);
+}
+
 final _forestParams = EnvironmentGenerationParams(
   density: 0.2,
   variation: 0.3,
```

Nouveau fichier créé par EnvironmentStudio-2-bis :

```text
reports/environment_studio/environment_studio_2_bis_palette_use_case_guard_hardening.md
```

Ce fichier est le rapport courant. Son contenu est directement inclus dans ce document.

## 14. Auto-review

- Le poids est-il validé hors UI ? Oui, par `EnvironmentPaletteItem`.
- Le poids négatif est-il refusé ? Oui, test `refuse poids négatif avant toute mutation`.
- Le poids zéro est-il refusé si l’UI actuelle refuse `< 1` ? Oui, test `refuse poids zéro avant toute mutation`.
- Un poids positif est-il accepté ? Oui, test `accepte poids positif et plusieurs éléments du même tileset`.
- Une erreur de poids empêche-t-elle toute mutation `ProjectManifest` ? Oui, le use case n’est pas atteint et le manifest original est vérifié inchangé.
- La palette vide est-elle clarifiée honnêtement ? Oui.
- La palette vide reste-t-elle refusée sans modifier `map_core` ? Oui.
- Le guard anti-mélange tilesets reste-t-il actif ? Oui, test existant toujours passant.
- Le picker UI n’est-il pas la seule sécurité ? Oui, le modèle domaine et le use case tileset protègent hors UI.
- Seule `EnvironmentPreset.palette` peut-elle être modifiée au save ? Oui, comportement du Lot 2 conservé.
- Les autres presets sont-ils préservés ? Oui.
- `id/name/category/defaultParams/sortOrder` sont-ils préservés ? Oui.
- Le `ProjectManifest` original reste-t-il immuté ? Oui.
- Aucun `map_core` modifié ? Oui.
- Aucun `ProjectManifest` model modifié ? Oui.
- Aucun generated file ? Oui.
- Aucun build_runner ? Oui.
- Aucune sauvegarde disque ? Oui.
- Aucune peinture/génération dans Environment Studio ? Oui.
- Aucun TileLayer inspector modifié ? Oui.
- Aucun canvas modifié ? Oui.

## 15. Critique du prompt et du lot

Clair :

- périmètre mini-lot très borné ;
- interdiction de modifier `map_core` ;
- validation du poids attendue à `weight >= 1` ;
- obligation de clarifier le contrat palette vide.

Ambigu :

- le prompt demande de prouver qu’un appel direct au use case ne peut pas sauver un poids invalide, mais le type d’entrée `List<EnvironmentPaletteItem>` empêche déjà de construire un item invalide par l’API publique. Le test prouve donc que le use case n’est pas atteint et qu’aucune mutation n’a lieu.

À trancher avant EnvironmentStudio-3 :

- décider si les presets vides doivent devenir un vrai état produit ;
- si oui, ouvrir un lot `map_core` dédié pour modifier `EnvironmentPreset`, diagnostics, sérialisation et tests ;
- décider si le use case palette doit accepter un draft brut plutôt qu’une liste d’items domaine déjà validés.

## 16. Verdict

```text
EnvironmentStudio-2-bis livré
Code produit modifié : non
Code UI modifié : non
Tests ciblés : pass
Analyze ciblé : pass
Prochain lot recommandé : EnvironmentStudio-3 — Preset Identity / Default Params Save Flow V0
```

## Checklist finale

- [x] Je n’ai fait aucun commit.
- [x] Je n’ai pas utilisé git add.
- [x] Je n’ai pas utilisé git push.
- [x] Je n’ai pas utilisé git reset/checkout/restore/stash.
- [x] Je n’ai pas lancé build_runner.
- [x] Je n’ai modifié aucun generated file.
- [x] Je n’ai modifié aucun commentaire dans le code.
- [x] Je n’ai pas modifié map_core.
- [x] Je n’ai pas modifié ProjectManifest model.
- [x] Je n’ai pas modifié EnvironmentPreset model.
- [x] Je n’ai pas modifié EnvironmentPaletteItem model.
- [x] Le poids est validé hors UI.
- [x] Le poids zéro est refusé.
- [x] Le poids négatif est refusé.
- [x] Le poids positif est accepté.
- [x] La palette vide est clarifiée comme refusée actuellement.
- [x] Aucune sauvegarde disque n’a été ajoutée.
- [x] Aucune peinture/génération n’a été ajoutée dans Environment Studio.
- [x] Les tests ciblés passent.
- [x] L’analyse ciblée est documentée.
- [x] Le rapport distingue les fichiers préexistants des fichiers du lot.
