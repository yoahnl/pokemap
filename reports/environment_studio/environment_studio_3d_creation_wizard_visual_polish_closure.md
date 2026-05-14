# EnvironmentStudio-3D — Creation Wizard Visual Polish / Closure V0

## 1. Résumé

EnvironmentStudio-3D finalise le polish visuel du wizard de création livré en 3C.

Le lot ajoute :
- un stepper compact étape 1 / étape 2 ;
- un résumé du tileset choisi en étape 2 ;
- des panneaux identifiables pour éléments compatibles, palette sélectionnée et barre d’action ;
- des cards d’éléments compatibles plus riches avec preview locale, métadonnées, tags et état ajouté ;
- un état vide de palette plus pédagogique ;
- une barre d’action finale claire et responsive ;
- un style de champs moins noir et plus intégré au thème ;
- un nettoyage de wording bas niveau dans le wizard et les brouillons Environment Studio.

Aucune logique map, génération, peinture, sauvegarde disque, migration ou modification `map_core` n’a été ajoutée.

## 2. Objectif du lot

Objectif strict :
- rendre le wizard de création 3C plus beau, dense et lisible ;
- préserver le workflow tileset-first ;
- préserver la création en mémoire ;
- préserver les guards anti-mélange de tilesets ;
- fermer le sous-chantier UI principal Environment Studio sauf bug réel.

## 3. État avant 3D

État hérité de 3C :
- `Nouveau preset` ouvrait bien un wizard guidé ;
- l’étape 1 forçait le choix d’un tileset ;
- l’étape 2 filtrait les éléments compatibles ;
- la palette vide bloquait la création ;
- le save restait en mémoire ;
- les éléments forcés hors tileset source étaient bloqués.

Réserves visuelles restantes :
- progression peu matérialisée ;
- cards d’éléments compatibles pauvres ;
- palette sélectionnée pas assez visible ;
- barre d’action finale trop simple ;
- champs encore trop bruts ;
- wording technique `Retour au browser` et `Aucun item pour l’instant.` encore présent dans des surfaces Environment Studio.

## 4. Polish du wizard de création

Le wizard conserve son point d’entrée `EnvironmentPresetCreationWizard`.

Changements principaux :
- ajout de `_buildStepper` et `_buildStepperItem` ;
- ajout de `_buildTilesetSummary` ;
- ajout de clés de structure testables :
  - `environment-creation-stepper`
  - `environment-creation-tileset-step`
  - `environment-creation-elements-step`
  - `environment-creation-tileset-summary`
  - `environment-compatible-elements-panel`
  - `environment-selected-palette-panel`
  - `environment-creation-action-bar`
  - `environment-creation-final-submit`
  - `environment-creation-empty-palette`
- maintien des anciennes clés critiques utilisées par les tests historiques :
  - `environment-studio-draft-save-project`
  - `environment-studio-draft-reset`
  - `environment-studio-creation-back-to-tilesets`
  - `environment-studio-creation-add-element-*`
  - `environment-studio-palette-draft-*`

## 5. Suppression des textes legacy

Dans le code source Environment Studio, la recherche ciblée ne trouve plus :
- `shell read-only`
- `lecture seule`
- `diagnostics — shell read-only`
- `génération sur carte arrive bientôt`
- `renommage d'id arrive bientôt`
- `Retour au browser`
- `Aucun item`

Commande :

```bash
rg -n "shell read-only|lecture seule|diagnostics — shell read-only|génération sur carte arrive bientôt|renommage d.id arrive bientôt|Retour au browser|Aucun item" packages/map_editor/lib/src/features/environment_studio packages/map_editor/test/environment_studio
```

Résultat exact :

```text
packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart:73:      expect(find.textContaining('shell read-only'), findsNothing);
packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart:74:      expect(find.textContaining('lecture seule'), findsNothing);
packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart:75:      expect(find.textContaining('génération sur carte arrive bientôt'),
packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart:121:      expect(find.textContaining('shell read-only'), findsNothing);
packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart:122:      expect(find.textContaining('lecture seule'), findsNothing);
packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart:76:      expect(find.textContaining('shell read-only'), findsNothing);
packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart:77:      expect(find.textContaining('génération sur carte arrive bientôt'),
```

Les seules occurrences restantes sont des assertions de non-présence dans les tests.

## 6. Stepper / progression

Le wizard affiche désormais une progression compacte :
- étape 1 : `Tileset source`, active tant que le tileset n’est pas choisi ;
- étape 2 : `Éléments du preset`, active après `Continuer` ;
- état terminé / actif visualisé par accent et badge ;
- résumé du tileset choisi en étape 2 avec `Changer de tileset`.

Le retour à l’étape 1 continue d’utiliser le callback existant `_goToTilesetStep`.

## 7. Champs identité / paramètres

Les champs existants ne changent pas de logique :
- `Id`
- `Nom`
- `Template`
- `Catégorie`
- `Ordre d’affichage`
- `Densité`
- `Variation`
- `Densité des bords`
- `Espacement min.`

Leur style passe par `_inputDecoration` :
- fond discret via `EditorChrome.badgeFill` ;
- bordure fine ;
- rayon modéré ;
- texte plus lisible ;
- placeholder moins agressif.

## 8. Éléments compatibles

La section `Éléments compatibles` devient un panneau testable et plus riche :
- champ de filtre avec icône de recherche ;
- cards en largeur 300 ;
- preview locale par placeholder coloré ;
- nom + id hiérarchisés ;
- méta `Collision par défaut` ou `Collision définie` ;
- tags sous forme de pills ;
- état `Ajouté à la palette` quand l’élément est déjà dans la palette ;
- bouton `Ajouter` désactivé quand l’élément est déjà ajouté.

La compatibilité tileset reste calculée par `_compatibleElements` et `resolveEnvironmentPresetElementTilesetId`.

## 9. Palette sélectionnée

La palette sélectionnée devient un panneau séparé :
- `Palette du preset` avec compteur quand elle contient des éléments ;
- état vide :

```text
Aucun élément sélectionné. Ajoutez au moins un élément compatible pour créer le preset.
```

La table existante `EnvironmentPaletteItemDraftEditor` est conservée.

## 10. Barre d’action finale

La barre finale est maintenant un bloc séparé :
- texte d’aide :

```text
Le preset sera ajouté au projet en mémoire. Aucune sauvegarde disque automatique.
```

- actions :
  - `Retour`
  - `Annuler`
  - `Ajouter au projet en mémoire`

La barre utilise un `Wrap` pour éviter les overflows à largeur réduite. Une première exécution de régression avait révélé un overflow de 6.2 px sur l’ancienne `Row`; le correctif 3D remplace la ligne rigide par une colonne + `Wrap`.

## 11. Sécurité anti-mélange tilesets

Préservé :
- étape 2 alimentée uniquement par `_compatibleElements(selectedTilesetId)` ;
- ajout refusé si `resolveEnvironmentPresetElementTilesetId(element) != _selectedTilesetId` ;
- doublons refusés ;
- `_sourceGuardIssues` bloque un brouillon manipulé avec un élément hors source ;
- `validateEnvironmentPresetDraft` continue de bloquer les erreurs de brouillon ;
- `buildEnvironmentPresetFromDraft` et `upsertProjectEnvironmentPreset` restent inchangés.

## 12. Comportements préservés

Préservé par tests :
- `Continuer` reste désactivé sans tileset ;
- l’étape 2 n’affiche pas les éléments d’autres tilesets ;
- la palette vide désactive le bouton final ;
- un élément ajouté apparaît dans le brouillon ;
- retirer un élément restaure l’état vide ;
- changer de tileset vide la palette ;
- un élément forcé hors tileset source bloque le save ;
- `EnvironmentPresetMemoryWriteKind.create` est toujours émis au save mémoire ;
- le flow palette draft/save existant passe ;
- le TileLayer inspector et le Golden Slice Environment passent.

## 13. Tests

### RED TDD

Commande :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_studio_preset_creation_form_test.dart
```

Résultat exact initial :

```text
00:00 +1 -1: EnvironmentStudioPanel — création tileset-first (3C) Nouveau preset ouvre un wizard et bloque Continuer sans tileset [E]
Expected: exactly one matching candidate
  Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'environment-creation-stepper'>]: []>
00:01 +1 -2: EnvironmentStudioPanel — création tileset-first (3C) sélectionner un tileset active l’étape éléments compatibles [E]
Expected: exactly one matching candidate
  Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'environment-creation-elements-step'>]: []>
00:01 +1 -3: EnvironmentStudioPanel — création tileset-first (3C) ajout, retrait et création mémoire restent guidés par le tileset [E]
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Ajouté à la palette": []>
00:02 +4 -3: Some tests failed.
```

### Test wizard ciblé après correction

Commande :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_studio_preset_creation_form_test.dart
```

Résultat exact :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart
00:00 +0: environmentPresetDraftIssueKindLabel libellés FR attendus (extrait)
00:00 +1: EnvironmentStudioPanel — création tileset-first (3C) Nouveau preset ouvre un wizard et bloque Continuer sans tileset
00:00 +2: EnvironmentStudioPanel — création tileset-first (3C) sélectionner un tileset active l’étape éléments compatibles
00:00 +3: EnvironmentStudioPanel — création tileset-first (3C) ajout, retrait et création mémoire restent guidés par le tileset
00:01 +4: EnvironmentStudioPanel — création tileset-first (3C) changer de tileset vide la palette du brouillon
00:01 +5: EnvironmentStudioPanel — création tileset-first (3C) un élément forcé hors tileset source bloque la création
00:02 +6: EnvironmentStudioPanel — création tileset-first (3C) catégorie optionnelle : champ compact vide
00:02 +7: All tests passed!
```

### Bundle final ciblé

Commande :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_studio_preset_creation_form_test.dart test/environment_studio/environment_preset_palette_draft_editor_test.dart test/environment_studio/environment_preset_save_to_manifest_test.dart test/environment_studio/environment_preset_palette_use_case_test.dart test/environment_studio/environment_preset_tileset_compatibility_test.dart test/environment_studio/environment_studio_preset_browser_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart test/environment_studio/environment_golden_slice_workflow_test.dart
```

Résultat exact utile :

```text
00:05 +133: All tests passed!
```

### Tests individuels passants lancés

```text
flutter test test/environment_studio/environment_preset_palette_draft_editor_test.dart
00:04 +21: All tests passed!

flutter test test/environment_studio/environment_preset_save_to_manifest_test.dart
00:03 +13: All tests passed!

flutter test test/environment_studio/environment_preset_palette_use_case_test.dart
00:00 +11: All tests passed!

flutter test test/environment_studio/environment_preset_tileset_compatibility_test.dart
00:00 +7: All tests passed!

flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
00:02 +59: All tests passed!

flutter test test/environment_studio/environment_golden_slice_workflow_test.dart
00:00 +6: All tests passed!

flutter test test/environment_studio/environment_studio_preset_browser_test.dart
00:00 +9: All tests passed!
```

### Tests optionnels en échec, hors critères 3D

Commande :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_generation_params_draft_editor_test.dart
```

Résultat exact utile :

```text
00:00 +0 -1: EnvironmentStudioPanel — params génération brouillon (Lot 15) affichage initial : titres et valeurs standard [E]
Expected: exactly one matching candidate
  Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'environment-studio-draft-params-editor'>]: []>
00:01 +0 -8: Some tests failed.
```

Analyse : ce test ouvre `Nouveau preset` et attend l’ancien éditeur de paramètres direct. Depuis 3C, `Nouveau preset` ouvre le wizard tileset-first ; le test doit être réécrit pour sélectionner un tileset puis passer à l’étape 2, ou être reclassé legacy.

Commande :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_studio_workspace_test.dart
```

Résultat exact utile :

```text
00:00 +0 -1: EnvironmentStudioPanel état vide : titre, banner actuel, pas de liste ni détail [E]
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "0 erreur(s) · 0 avertissement(s)": []>
00:00 +3 -1: Some tests failed.
```

Analyse : échec d’attente d’état vide workspace, non touché par 3D.

## 14. Analyse ciblée

Commande :

```bash
cd packages/map_editor
flutter analyze lib/src/features/environment_studio/environment_studio_panel.dart lib/src/features/environment_studio/widgets/environment_preset_creation_wizard.dart lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart test/environment_studio/environment_studio_preset_creation_form_test.dart
```

Résultat exact :

```text
Analyzing 4 items...                                            
No issues found! (ran in 1.8s)
```

## 15. Fichiers créés/modifiés

Fichier créé par EnvironmentStudio-3D :
- `reports/environment_studio/environment_studio_3d_creation_wizard_visual_polish_closure.md`

Fichiers modifiés par EnvironmentStudio-3D :
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_creation_wizard.dart`
- `packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart`
- `packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart`

Fichiers préexistants dans le worktree avant 3D :
- aucun fichier modifié ou non suivi au démarrage ; `git status --short --untracked-files=all` n’a imprimé aucune ligne.

## 16. Non-objectifs respectés

- Pas de modification `map_core`.
- Pas de modification `ProjectManifest` model.
- Pas de modification runtime/gameplay/battle.
- Pas de modification canvas.
- Pas de modification TileLayer inspector.
- Pas de génération ou peinture dans Environment Studio.
- Pas de save disque.
- Pas de migration JSON.
- Pas de build_runner.
- Pas de generated file.
- Pas de nouveau repository/service/provider.
- Pas de nouveau champ `sourceTilesetId`.
- Pas de commit.
- Pas de `git add`.
- Pas de push.

## 17. Evidence Pack

### git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Résultat exact :

```text
```

### git status final

Commande :

```bash
git status --short --untracked-files=all
```

Résultat exact :

```text
 M packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_creation_wizard.dart
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
 M packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart
?? reports/environment_studio/environment_studio_3d_creation_wizard_visual_polish_closure.md
```

### git diff --stat

Commande :

```bash
git diff --stat
```

Résultat exact avant ajout du rapport non suivi :

```text
 .../environment_studio_panel.dart                  |   2 +-
 .../environment_preset_creation_wizard.dart        | 790 ++++++++++++++++-----
 .../widgets/environment_preset_draft_form.dart     |   4 +-
 ...vironment_studio_preset_creation_form_test.dart |  50 ++
 4 files changed, 673 insertions(+), 173 deletions(-)
```

### git diff --name-only

Commande :

```bash
git diff --name-only
```

Résultat exact avant ajout du rapport non suivi :

```text
packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_creation_wizard.dart
packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart
```

### git diff --check

Commande :

```bash
git diff --check
```

Résultat exact :

```text
```

## 18. Diff pertinent

### Stepper et header

```diff
@@
           _buildWizardHeader(context, label, subtle),
           const SizedBox(height: 16),
+          _buildStepper(context, label, subtle),
+          const SizedBox(height: 16),
           if (_step == 0)
             _buildTilesetStep(context, label, subtle)
@@
+  Widget _buildStepper(BuildContext context, Color label, Color subtle) {
+    return DecoratedBox(
+      key: const Key('environment-creation-stepper'),
+      decoration: BoxDecoration(
+        color: EditorChrome.chipFill(context).withValues(alpha: 0.72),
+        borderRadius: BorderRadius.circular(12),
+        border: Border.all(
+          color: CupertinoColors.separator.resolveFrom(context),
+        ),
+      ),
+      child: Padding(
+        padding: const EdgeInsets.all(10),
+        child: Row(
+          children: [
+            Expanded(
+              child: _buildStepperItem(
+                context,
+                number: '1',
+                title: 'Tileset source',
+                helper: _selectedTilesetId ?? 'À choisir',
+                active: _step == 0,
+                done: _selectedTilesetId != null,
+                label: label,
+                subtle: subtle,
+              ),
+            ),
+            const SizedBox(width: 8),
+            Expanded(
+              child: _buildStepperItem(
+                context,
+                number: '2',
+                title: 'Éléments du preset',
+                helper: widget.draft.palette.isEmpty
+                    ? 'Aucun élément choisi'
+                    : '${widget.draft.palette.length} élément(s)',
+                active: _step == 1,
+                done: widget.draft.palette.isNotEmpty,
+                label: label,
+                subtle: subtle,
+              ),
+            ),
+          ],
+        ),
+      ),
+    );
+  }
@@
-                  child: const Text('Retour au browser'),
+                  child: const Text('Retour aux presets'),
```

### Étapes et résumé tileset

```diff
@@
-    return Column(
-      key: const Key('environment-studio-creation-step-tileset'),
+    return KeyedSubtree(
+      key: const Key('environment-creation-tileset-step'),
+      child: Column(
+        key: const Key('environment-studio-creation-step-tileset'),
@@
-    return Column(
-      key: const Key('environment-studio-creation-step-elements'),
+    return KeyedSubtree(
+      key: const Key('environment-creation-elements-step'),
+      child: Column(
+        key: const Key('environment-studio-creation-step-elements'),
@@
+          if (selectedTilesetId != null) ...[
+            const SizedBox(height: 12),
+            _buildTilesetSummary(
+              context,
+              selectedTilesetId,
+              compatibleElements.length,
+              label,
+              subtle,
+            ),
+          ],
@@
+  Widget _buildTilesetSummary(
+    BuildContext context,
+    String tilesetId,
+    int compatibleCount,
+    Color label,
+    Color subtle,
+  ) {
+    return DecoratedBox(
+      key: const Key('environment-creation-tileset-summary'),
+      decoration: BoxDecoration(
+        color: EditorChrome.accentJade.withValues(alpha: 0.09),
+        borderRadius: BorderRadius.circular(10),
+        border: Border.all(
+          color: EditorChrome.accentJade.withValues(alpha: 0.32),
+        ),
+      ),
+      child: Padding(
+        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
+        child: Row(
+          children: [
+            const Icon(
+              CupertinoIcons.lock_shield,
+              size: 18,
+              color: EditorChrome.accentJade,
+            ),
+            Expanded(
+              child: Column(
+                crossAxisAlignment: CrossAxisAlignment.stretch,
+                children: [
+                  Text('Tileset source : $tilesetId'),
+                  Text('$compatibleCount éléments compatibles'),
+                ],
+              ),
+            ),
+            CupertinoButton(
+              key: const Key('environment-creation-change-tileset'),
+              onPressed: _goToTilesetStep,
+              child: const Text('Changer de tileset'),
+            ),
+          ],
+        ),
+      ),
+    );
+  }
```

### Éléments compatibles

```diff
@@
     return _panel(
       context,
+      key: const Key('environment-compatible-elements-panel'),
@@
-                width: 260,
+                width: 300,
                 child: CupertinoTextField(
@@
+                  prefix: Padding(
+                    padding: const EdgeInsets.only(left: 9),
+                    child: Icon(
+                      CupertinoIcons.search,
+                      size: 15,
+                      color: subtle,
+                    ),
+                  ),
+                  decoration: _inputDecoration(context),
@@
     final alreadyAdded =
         widget.draft.palette.any((item) => item.elementId == element.id);
+    final accent = _elementAccent(element.id);
@@
-      width: 260,
+      width: 300,
@@
-          color: EditorChrome.chipFill(context),
-          borderRadius: BorderRadius.circular(8),
+          color: alreadyAdded
+              ? EditorChrome.accentJade.withValues(alpha: 0.11)
+              : EditorChrome.chipFill(context).withValues(alpha: 0.82),
+          borderRadius: BorderRadius.circular(10),
@@
+                  _buildElementPreview(context, element, accent),
@@
+                  _metaPill(
+                    context,
+                    element.collisionProfile == null
+                        ? 'Collision par défaut'
+                        : 'Collision définie',
+                  ),
+                  if (alreadyAdded) _metaPill(context, 'Ajouté à la palette'),
@@
+                    for (final tag in element.tags.take(3))
+                      _tagPill(context, tag),
```

### Palette et action bar

```diff
@@
     return _panel(
       context,
+      key: const Key('environment-selected-palette-panel'),
@@
-                  'Palette du preset',
+                  widget.draft.palette.isEmpty
+                      ? 'Palette du preset'
+                      : 'Palette du preset • ${widget.draft.palette.length} élément(s)',
@@
           if (widget.draft.palette.isEmpty)
-            Text(
-              'Aucun item pour l’instant.',
-              key: const Key('environment-studio-draft-palette-no-items'),
-              style: TextStyle(color: subtle, fontSize: 13),
-            )
+            _buildEmptyPaletteState(context, subtle)
@@
-          Wrap(
-            spacing: 8,
-            runSpacing: 8,
-            alignment: WrapAlignment.end,
-            children: [
-              CupertinoButton(
-                key: const Key('environment-studio-creation-back-to-tilesets'),
-                child: const Text('Retour au choix du tileset'),
-              ),
-              CupertinoButton(
-                key: const Key('environment-studio-draft-reset'),
-                child: const Text('Réinitialiser brouillon'),
-              ),
-              CupertinoButton(
-                key: const Key('environment-studio-draft-save-project'),
-                child: const Text('Ajouter au projet en mémoire'),
-              ),
-            ],
+          _buildCreationActionBar(
+            context,
+            canSave: canSave,
+            label: label,
+            subtle: subtle,
           ),
@@
+  Widget _buildEmptyPaletteState(BuildContext context, Color subtle) {
+    return DecoratedBox(
+      key: const Key('environment-creation-empty-palette'),
+      child: Padding(
+        padding: const EdgeInsets.all(12),
+        child: Text(
+          'Aucun élément sélectionné. Ajoutez au moins un élément compatible pour créer le preset.',
+          key: const Key('environment-studio-draft-palette-no-items'),
+        ),
+      ),
+    );
+  }
@@
+  Widget _buildCreationActionBar(
+    BuildContext context, {
+    required bool canSave,
+    required Color label,
+    required Color subtle,
+  }) {
+    return DecoratedBox(
+      key: const Key('environment-creation-action-bar'),
+      child: Padding(
+        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.stretch,
+          children: [
+            Text(
+              'Le preset sera ajouté au projet en mémoire. Aucune sauvegarde disque automatique.',
+            ),
+            const SizedBox(height: 10),
+            Wrap(
+              spacing: 8,
+              runSpacing: 8,
+              alignment: WrapAlignment.end,
+              children: [
+                CupertinoButton(
+                  key: const Key('environment-studio-creation-back-to-tilesets'),
+                  onPressed: _goToTilesetStep,
+                  child: const Text('Retour'),
+                ),
+                CupertinoButton(
+                  key: const Key('environment-studio-draft-reset'),
+                  onPressed: widget.onReset,
+                  child: const Text('Annuler'),
+                ),
+                KeyedSubtree(
+                  key: const Key('environment-creation-final-submit'),
+                  child: CupertinoButton(
+                    key: const Key('environment-studio-draft-save-project'),
+                    onPressed: canSave ? _saveDraftToProject : null,
+                    child: const Text('Ajouter au projet en mémoire'),
+                  ),
+                ),
+              ],
+            ),
+          ],
+        ),
+      ),
+    );
+  }
```

### Champs et wording brouillon

```diff
@@
-  Widget _panel(BuildContext context, {required Widget child}) {
+  Widget _panel(BuildContext context, {Key? key, required Widget child}) {
     return DecoratedBox(
+      key: key,
@@
-        color: EditorChrome.chipFill(context),
+        color: EditorChrome.chipFill(context).withValues(alpha: 0.78),
@@
             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
+            decoration: _inputDecoration(context),
+            style: TextStyle(
+              color: EditorChrome.primaryLabel(context),
+              fontSize: 12,
+              fontWeight: FontWeight.w700,
+            ),
+            placeholderStyle: TextStyle(
+              color: EditorChrome.subtleLabel(context).withValues(alpha: 0.78),
+              fontSize: 12,
+            ),
@@
+  BoxDecoration _inputDecoration(BuildContext context) {
+    return BoxDecoration(
+      color: EditorChrome.badgeFill(context).withValues(alpha: 0.48),
+      borderRadius: BorderRadius.circular(8),
+      border: Border.all(
+        color: CupertinoColors.separator.resolveFrom(context),
+      ),
+    );
+  }
```

```diff
diff --git a/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart b/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
@@
-            'Aucun item pour l’instant.',
+            'Aucun élément sélectionné.',
diff --git a/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart b/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
@@
-              'Aucun item pour l’instant.',
+              'Aucun élément sélectionné.',
@@
-                child: const Text('Retour au browser'),
+                child: const Text('Retour aux presets'),
```

### Tests

```diff
@@
       expect(
         find.byKey(const Key('environment-studio-creation-wizard')),
         findsOneWidget,
       );
+      expect(
+        find.byKey(const Key('environment-creation-stepper')),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(const Key('environment-creation-tileset-step')),
+        findsOneWidget,
+      );
@@
+      expect(
+        find.byKey(const Key('environment-creation-elements-step')),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(const Key('environment-creation-tileset-summary')),
+        findsOneWidget,
+      );
+      expect(find.text('Tileset source : grass'), findsOneWidget);
+      expect(find.text('1 éléments compatibles'), findsOneWidget);
+      expect(find.text('Changer de tileset'), findsOneWidget);
@@
+      expect(
+        find.byKey(const Key('environment-compatible-elements-panel')),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(const Key('environment-selected-palette-panel')),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(const Key('environment-creation-action-bar')),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(const Key('environment-creation-final-submit')),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(const Key('environment-creation-empty-palette')),
+        findsOneWidget,
+      );
+      expect(
+        find.text(
+          'Aucun élément sélectionné. Ajoutez au moins un élément compatible pour créer le preset.',
+        ),
+        findsOneWidget,
+      );
@@
+      expect(
+        find.byKey(const Key('environment-creation-element-preview-grass_a')),
+        findsOneWidget,
+      );
@@
+      expect(find.text('Ajouté à la palette'), findsOneWidget);
```

## 19. Auto-review

- Le wizard est-il plus beau qu’après 3C ? Oui : stepper, summary, cards enrichies, panneaux séparés, action bar.
- Les champs noirs ont-ils disparu ou été fortement atténués ? Oui : `_inputDecoration` applique un fond `badgeFill` plus discret.
- Les étapes sont-elles plus lisibles ? Oui : stepper + clés d’étape + titres conservés.
- Le tileset choisi est-il clairement résumé en étape 2 ? Oui : `Tileset source : <id>` + compteur compatible.
- Les éléments compatibles sont-ils plus lisibles ? Oui : preview, hiérarchie nom/id, méta collision, tags.
- Les éléments déjà ajoutés sont-ils clairement identifiables ? Oui : `Ajouté à la palette` + bouton désactivé `Ajouté`.
- La palette sélectionnée est-elle clairement visible ? Oui : panneau dédié `environment-selected-palette-panel`.
- L’état vide de palette est-il pédagogique ? Oui : message complet demandant au moins un élément compatible.
- La barre d’action finale est-elle claire ? Oui : helper mémoire + `Retour` + `Annuler` + `Ajouter au projet en mémoire`.
- Le bouton final est-il protégé contre une création invalide ? Oui, `canSave` reste calculé depuis validation + source guard.
- Les textes legacy `shell read-only` ont-ils disparu du contenu principal ? Oui ; seules les assertions de non-présence les mentionnent.
- Le guard anti-mélange tileset est-il préservé hors UI ? Oui, `_sourceGuardIssues` et les use case tests passent.
- Les flows d’édition palette existants sont-ils préservés ? Oui, `environment_preset_palette_draft_editor_test.dart` passe.
- Environment Studio reste-t-il un atelier de presets ? Oui.
- Aucune peinture/génération sur map ? Oui.
- Aucun `map_core` modifié ? Oui.
- Aucun `ProjectManifest` model modifié ? Oui.
- Aucun generated file ? Oui.
- Aucun build_runner ? Oui.
- Aucun TileLayer inspector modifié ? Oui.
- Aucun canvas modifié ? Oui.

## 20. Critique du prompt et du lot

Clair :
- le lot devait rester UI/polish ;
- le workflow tileset-first 3C devait être préservé ;
- le guard anti-mélange tilesets ne devait pas devenir uniquement visuel ;
- les textes legacy principaux devaient disparaître.

Ambigu :
- le prompt demande beaucoup de commentaires utiles dans le code, alors que le même bloc interdit tout commentaire dans le code. La règle appliquée est l’interdiction de commentaires.
- le prompt demande le contenu complet de tous les fichiers modifiés, mais les fichiers touchés sont des fichiers UI existants volumineux. Le rapport fournit les hunks complets des zones modifiées et les commandes exactes qui bornent le périmètre.

À trancher après fermeture :
- réécrire ou supprimer les tests optionnels legacy qui ouvrent `Nouveau preset` en attendant encore l’ancien formulaire direct ;
- décider si `Ajouter au projet en mémoire` doit devenir `Créer le preset` côté wording final, en gardant ou non le rappel mémoire.

## 21. Verdict de fermeture

```text
EnvironmentStudio-3D livré
Code produit modifié : oui
Code UI modifié : oui
Tests ciblés : pass
Analyze ciblé : pass
git diff --check : pass
Création reste en mémoire uniquement : oui
Palette vide reste refusée : oui
Mélange de tilesets reste bloqué : oui
map_core modifié : non
ProjectManifest model modifié : non
generated/build_runner : non
commit effectué : non
Environment Studio UI principale : clôturable oui
Prochain lot recommandé : aucun lot Environment Studio obligatoire ; seulement correction optionnelle des tests legacy ou micro-polish si bug visuel démontré.
```

Note post-livraison : le lot a été produit sans `git add`, commit ni push. Le commit/push peut être effectué ensuite uniquement sur demande explicite de Karim.
