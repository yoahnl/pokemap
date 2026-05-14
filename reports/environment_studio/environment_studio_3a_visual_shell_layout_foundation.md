# EnvironmentStudio-3A — Visual Shell & Layout Foundation V0

## 1. Résumé

EnvironmentStudio-3A pose la fondation visuelle du nouvel Environment Studio :

- shell principal identifié et plus large ;
- suppression du centrage `maxWidth: 1040` qui comprimait l’écran ;
- header compact avec icône, titre et compteur ;
- bannière produit plus propre ;
- layout principal en deux colonnes explicites ;
- colonne `Presets` encadrée comme navigation ;
- panneau `Éditer le preset` identifié comme surface principale ;
- sections `Identité`, `Paramètres par défaut`, `Palette du preset` numérotées ;
- comportements palette EnvironmentStudio-2/2-bis préservés.

Ce lot ne change aucune règle métier et ne remet aucune peinture/génération dans Environment Studio.

## 2. Objectif du lot

Objectif exécuté :

```text
Transformer la structure générale de l’écran Environment Studio pour qu’il commence à ressembler au mockup cible, sans polish fin de la palette.
```

Ce lot reste un lot UI/layout :

- pas de création réelle nouvelle de preset ;
- pas de suppression ou duplication de preset ;
- pas d’édition persistée identité/default params ;
- pas de changement `map_core` ;
- pas de workflow map ;
- pas de TileLayer inspector.

## 3. Références screenshots A/B

Référence A :

```text
UI existante : écran encore trop centré, trop étroit, avec effet de carte molle et peu d’impression workspace.
```

Référence B :

```text
UI cible : dark macOS-like, header compact, bannière info, deux colonnes, colonne Presets crédible, panneau détail structuré.
```

Décision pour 3A :

```text
Converger sur la structure générale seulement : shell, header, banner, colonnes, sections numérotées.
```

## 4. Audit de l’écran actuel

Fichiers inspectés :

- `packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_list.dart`
- `packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart`
- `packages/map_editor/pubspec.yaml`

Constats :

- `EnvironmentStudioPanel` utilisait un `Center` + `ConstrainedBox(maxWidth: 1040)`, ce qui renforçait l’impression d’écran étroit.
- Le header était vertical et moins proche du mockup cible.
- La bannière existait déjà, mais sous forme d’un bloc texte simple.
- Le layout deux colonnes existait en partie, mais sans clés/tests de structure et avec une colonne Presets moins assumée comme navigation.
- `EnvironmentPresetDetail` avait déjà les sections métier, mais sans numérotation visuelle.
- `EnvironmentPresetList` portait sa propre carte interne ; 3A déplace l’encadrement vers la colonne Presets pour réduire l’empilement visuel.

## 5. Nouvelle structure UI

Structure retenue :

```text
EnvironmentStudioPanel
  environment-studio-shell
    Header compact
    Info banner
    environment-studio-main-layout
      environment-studio-preset-column
        Presets
        Nouveau preset
        EnvironmentPresetList
        Diagnostics projet
      environment-studio-editor-panel
        Éditer le preset
        Tileset source
        [1] Identité
        [2] Paramètres par défaut
        [3] Palette du preset
        Diagnostics preset
```

Cette structure garde les contrôles existants, mais leur donne une hiérarchie plus lisible.

## 6. Changements par zone

Header :

- passage à un `Row` compact ;
- ajout d’une icône `CupertinoIcons.tree` ;
- titre unique `Environment Studio` ;
- sous-titre `Presets d’environnements réutilisables` ;
- compteur de presets en badge.

Bannière produit :

- texte conservé ;
- ajout d’une icône info ;
- bordure et rayon plus compacts.

Workspace :

- suppression du `Center` et du `ConstrainedBox(maxWidth: 1040)` ;
- padding global réduit ;
- ajout de la clé `environment-studio-shell` ;
- ajout de la clé `environment-studio-main-layout`.

Colonne Presets :

- largeur portée à `320` ;
- surface encadrée avec clé `environment-studio-preset-column` ;
- titre et bouton regroupés ;
- diagnostics projet conservés en bas de colonne ;
- liste sans carte interne supplémentaire.

Panneau Éditer le preset :

- surface droite identifiée par `environment-studio-editor-panel` ;
- sections existantes conservées ;
- `Tileset source` placé en tête de détail ;
- sections 1/2/3 numérotées.

## 7. Comportements préservés

Préservé :

- sélection de preset ;
- ouverture du brouillon complet ;
- ouverture du brouillon palette ;
- dirty state palette ;
- `Enregistrer la palette` ;
- `Annuler les changements` ;
- picker compatible tileset ;
- diagnostic de preset mixte ;
- guard anti-mélange tilesets ;
- use case palette ;
- absence de peinture/génération dans Environment Studio.

Non modifié :

- `map_core` ;
- runtime/gameplay/battle ;
- canvas ;
- TileLayer inspector ;
- modèles JSON ;
- save disque.

## 8. Tests

RED initial :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_preset_palette_draft_editor_test.dart
```

Résultat exact :

```text
00:00 +0 -1: EnvironmentStudioPanel — visual shell layout (EnvironmentStudio-3A) affiche le shell large, la bannière et le layout 2 colonnes [E]
Expected: exactly one matching candidate
  Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'environment-studio-shell'>]: []>
00:00 +0 -2: EnvironmentStudioPanel — visual shell layout (EnvironmentStudio-3A) structure les sections numérotées du preset sélectionné [E]
Expected: exactly one matching candidate
  Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'environment-studio-section-number-1'>]: []>
00:03 +17 -2: Some tests failed.
```

Commande widget finale :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_preset_palette_draft_editor_test.dart
```

Résultat exact :

```text
00:00 +0: EnvironmentStudioPanel — visual shell layout (EnvironmentStudio-3A) affiche le shell large, la bannière et le layout 2 colonnes
00:00 +1: EnvironmentStudioPanel — visual shell layout (EnvironmentStudio-3A) structure les sections numérotées du preset sélectionné
00:00 +2: EnvironmentStudioPanel — visual shell layout (EnvironmentStudio-3A) garde Studio limité aux presets sans commandes de map
00:00 +3: EnvironmentStudioPanel — palette brouillon (Lot 14) ajouter un item : emptyPalette disparaît, emptyPaletteElementId
00:00 +4: EnvironmentStudioPanel — palette brouillon (Lot 14) elementId connu : plus d’emptyPaletteElementId ni missingPaletteElement
00:01 +5: EnvironmentStudioPanel — palette brouillon (Lot 14) picker bibliothèque remplit elementId
00:01 +6: EnvironmentStudioPanel — palette brouillon (Lot 14) picker bibliothèque filtre les éléments du tileset source
00:01 +7: EnvironmentStudioPanel — palette brouillon (Lot 14) saisie manuelle incompatible déclenche Tilesets mélangés
00:01 +8: EnvironmentStudioPanel — palette brouillon (Lot 14) elementId absent : Élément introuvable
00:01 +9: EnvironmentStudioPanel — palette brouillon (Lot 14) poids 3 valide, poids 0 invalide, texte non numérique inchangé
00:01 +10: EnvironmentStudioPanel — palette brouillon (Lot 14) collision : bascule Collision forcée puis Collision désactivée
00:02 +11: EnvironmentStudioPanel — palette brouillon (Lot 14) tags : tree, canopy OK ; tree, , canopy → Tag vide
00:02 +12: EnvironmentStudioPanel — palette brouillon (Lot 14) Retirer : palette vide, emptyPalette revient
00:02 +13: EnvironmentStudioPanel — palette brouillon (Lot 14) deux items même elementId : Élément dupliqué
00:02 +14: EnvironmentStudioPanel — palette brouillon (Lot 14) édition palette + retour browser : manifest.environmentPresets inchangé
00:02 +15: EnvironmentStudioPanel — palette save flow (EnvironmentStudio-2) modifier palette affiche un brouillon sale puis annuler restaure
00:02 +16: EnvironmentStudioPanel — palette save flow (EnvironmentStudio-2) enregistrer la palette appelle le callback et garde le preset
00:02 +17: EnvironmentStudioPanel — palette save flow (EnvironmentStudio-2) picker palette exclut un élément incompatible
00:02 +18: EnvironmentStudioPanel — palette save flow (EnvironmentStudio-2) preset mixte bloque save mais permet retirer incompatible
00:02 +19: All tests passed!
```

Commande use case palette :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_preset_palette_use_case_test.dart
```

Résultat exact :

```text
00:00 +11: All tests passed!
```

Commande régression TileLayer inspector :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Résultat exact :

```text
00:02 +59: All tests passed!
```

Commande régression Golden Slice :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_golden_slice_workflow_test.dart
```

Résultat exact :

```text
00:00 +6: All tests passed!
```

Commande optionnelle non lancée :

```bash
cd packages/map_editor
flutter test test/environment_studio
```

Raison :

```text
Le full environment_studio est déjà documenté comme non vert sur deux dettes hors lot dans les rapports EnvironmentStudio-2 / 2-bis. Les tests ciblés et les régressions critiques demandées ont été relancés.
```

## 9. Analyse ciblée

Commande :

```bash
cd packages/map_editor
flutter analyze lib/src/features/environment_studio/environment_studio_panel.dart lib/src/features/environment_studio/widgets/environment_preset_detail.dart lib/src/features/environment_studio/widgets/environment_preset_list.dart test/environment_studio/environment_preset_palette_draft_editor_test.dart
```

Résultat exact :

```text
Analyzing 4 items...
No issues found! (ran in 1.4s)
```

## 10. Fichiers créés/modifiés

Fichiers déjà présents/modifiés avant EnvironmentStudio-3A :

```text
 M packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart
 M packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart
?? packages/map_editor/lib/src/features/environment_studio/authoring/environment_preset_palette_use_cases.dart
?? packages/map_editor/test/environment_studio/environment_preset_palette_use_case_test.dart
?? reports/environment_studio/environment_studio_2_bis_palette_use_case_guard_hardening.md
?? reports/environment_studio/environment_studio_2_preset_palette_editor_save_flow.md
```

Fichiers créés par EnvironmentStudio-3A :

- `reports/environment_studio/environment_studio_3a_visual_shell_layout_foundation.md`

Fichiers modifiés par EnvironmentStudio-3A :

- `packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_list.dart`
- `packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart`

Fichiers déjà modifiés avant 3A et retouchés par 3A :

- `packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart`
- `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart`
- `packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart`

Fichiers préexistants dans le worktree non touchés par 3A :

- `packages/map_editor/lib/src/features/environment_studio/authoring/environment_preset_palette_use_cases.dart`
- `packages/map_editor/test/environment_studio/environment_preset_palette_use_case_test.dart`
- `reports/environment_studio/environment_studio_2_bis_palette_use_case_guard_hardening.md`
- `reports/environment_studio/environment_studio_2_preset_palette_editor_save_flow.md`

Dettes préexistantes hors lot :

- `environment_layer_area_model_editing_test.dart` : tap offscreen puis `Bad state: No element`, documenté avant 3A ;
- `tile_layer_environment_erase_mode_test.dart` : expectation historique `environmentMaskEditMode == null`, état actuel `erase`, documenté avant 3A.

Problèmes introduits par 3A :

- Aucun identifié par les tests ciblés, l’analyse ciblée et `git diff --check`.

## 11. Non-objectifs respectés

- Pas de refonte fine de la palette.
- Pas de création réelle nouvelle de preset.
- Pas de suppression de preset.
- Pas de duplication de preset.
- Pas d’édition persistée identité/default params.
- Pas de modification `map_core`.
- Pas de modification `ProjectManifest`.
- Pas de modification des modèles JSON.
- Pas de modification runtime/gameplay/battle.
- Pas de modification canvas.
- Pas de modification TileLayer inspector.
- Pas de peinture/génération dans Environment Studio.
- Pas de build_runner.
- Pas de generated file.
- Pas de commit, `git add`, push, reset, checkout, restore ou stash.

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
?? reports/environment_studio/environment_studio_2_bis_palette_use_case_guard_hardening.md
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
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_list.dart
 M packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart
?? packages/map_editor/lib/src/features/environment_studio/authoring/environment_preset_palette_use_cases.dart
?? packages/map_editor/test/environment_studio/environment_preset_palette_use_case_test.dart
?? reports/environment_studio/environment_studio_2_bis_palette_use_case_guard_hardening.md
?? reports/environment_studio/environment_studio_2_preset_palette_editor_save_flow.md
?? reports/environment_studio/environment_studio_3a_visual_shell_layout_foundation.md
```

Diff stat :

```bash
git diff --stat
```

Résultat exact :

```text
 .../environment_studio_panel.dart                  | 807 +++++++++++++++++----
 .../widgets/environment_preset_detail.dart         | 149 +++-
 .../widgets/environment_preset_list.dart           |  61 +-
 ...vironment_preset_palette_draft_editor_test.dart | 314 +++++++-
 4 files changed, 1117 insertions(+), 214 deletions(-)
```

Diff name-only :

```bash
git diff --name-only
```

Résultat exact :

```text
packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart
packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_list.dart
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

Commande format :

```bash
cd packages/map_editor
dart format lib/src/features/environment_studio/environment_studio_panel.dart lib/src/features/environment_studio/widgets/environment_preset_detail.dart lib/src/features/environment_studio/widgets/environment_preset_list.dart test/environment_studio/environment_preset_palette_draft_editor_test.dart
```

Résultat exact :

```text
Formatted lib/src/features/environment_studio/environment_studio_panel.dart
Formatted lib/src/features/environment_studio/widgets/environment_preset_detail.dart
Formatted 4 files (2 changed) in 0.02 seconds.
```

## 13. Diff pertinent

Hunks pertinents `environment_studio_panel.dart` :

```diff
+    return DecoratedBox(
+      key: const Key('environment-studio-shell'),
+      decoration: BoxDecoration(
+        color: EditorChrome.largeIslandSurfaceColor(
+          context,
+          tint: EditorChrome.accentJade.withValues(alpha: 0.05),
+        ),
+      ),
+      child: SafeArea(
+        child: Padding(
+          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
+          child: Column(
+            crossAxisAlignment: CrossAxisAlignment.stretch,
+            children: [
+              _buildHeader(context, label, subtle, n),
+              const SizedBox(height: 12),
+              _buildInfoBanner(context),
+              const SizedBox(height: 14),
```

```diff
+  Widget _buildHeader(
+    BuildContext context,
+    Color label,
+    Color subtle,
+    int presetCount,
+  ) {
+    return Row(
+      key: const Key('environment-studio-header'),
+      crossAxisAlignment: CrossAxisAlignment.center,
+      children: [
+        Container(
+          width: 44,
+          height: 44,
+          decoration: BoxDecoration(
+            color: EditorChrome.accentJade.withValues(alpha: 0.18),
+            borderRadius: BorderRadius.circular(10),
+            border: Border.all(
+              color: EditorChrome.accentJade.withValues(alpha: 0.42),
+            ),
+          ),
+          child: const Icon(
+            CupertinoIcons.tree,
+            color: EditorChrome.accentJade,
+            size: 24,
+          ),
+        ),
```

```diff
+        Expanded(
+          child: Row(
+            key: const Key('environment-studio-main-layout'),
+            crossAxisAlignment: CrossAxisAlignment.stretch,
+            children: [
+              SizedBox(
+                width: 320,
+                child: DecoratedBox(
+                  key: const Key('environment-studio-preset-column'),
...
+              Expanded(
+                child: DecoratedBox(
+                  key: const Key('environment-studio-editor-panel'),
```

Hunks pertinents `environment_preset_detail.dart` :

```diff
+        _tilesetSourcePanel(context, tilesetCompatibility, fill, border),
         const SizedBox(height: 14),
         _sectionCard(
           context,
           key: const Key('environment-studio-section-identity'),
+          number: 1,
           title: 'Identité',
...
         _sectionCard(
           context,
           key: const Key('environment-studio-section-params'),
+          number: 2,
           title: 'Paramètres par défaut',
...
         _sectionCard(
           context,
           key: const Key('environment-studio-section-palette'),
+          number: 3,
           title: 'Palette du preset',
```

```diff
+                if (number != null) ...[
+                  Container(
+                    key: Key('environment-studio-section-number-$number'),
+                    width: 22,
+                    height: 22,
+                    alignment: Alignment.center,
+                    decoration: BoxDecoration(
+                      color: EditorChrome.accentJade.withValues(alpha: 0.12),
+                      borderRadius: BorderRadius.circular(6),
+                      border: Border.all(
+                        color: EditorChrome.accentJade.withValues(alpha: 0.45),
+                      ),
+                    ),
+                    child: Text(
+                      '$number',
+                      style: const TextStyle(
+                        color: EditorChrome.accentJade,
+                        fontSize: 12,
+                        fontWeight: FontWeight.w800,
+                      ),
+                    ),
+                  ),
+                  const SizedBox(width: 8),
+                ],
```

Hunks pertinents `environment_preset_list.dart` :

```diff
-    return DecoratedBox(
-      decoration: BoxDecoration(
-        color: EditorChrome.chipFill(context),
-        borderRadius: BorderRadius.circular(12),
-        border: Border.all(
-          color: CupertinoColors.separator.resolveFrom(context),
-        ),
-      ),
-      child: ListView.builder(
+    return ListView.builder(
       key: const Key('environment-studio-preset-list'),
-        padding: const EdgeInsets.symmetric(vertical: 8),
+      padding: EdgeInsets.zero,
```

Hunks pertinents test widget :

```diff
+  group('EnvironmentStudioPanel — visual shell layout (EnvironmentStudio-3A)',
+      () {
+    testWidgets('affiche le shell large, la bannière et le layout 2 colonnes',
+        (tester) async {
+      await _pumpWithSave(
+        tester,
+        _manifest(
+          environmentPresets: [_preset(id: 'forest')],
+          elements: [_element(id: 'elm')],
+        ),
+      );
+
+      expect(find.byKey(const Key('environment-studio-shell')), findsOneWidget);
+      expect(find.text('Environment Studio'), findsOneWidget);
+      expect(
+          find.text('Presets d’environnements réutilisables'), findsOneWidget);
+      expect(find.byKey(const Key('environment-studio-main-layout')),
+          findsOneWidget);
+      expect(find.byKey(const Key('environment-studio-preset-column')),
+          findsOneWidget);
+      expect(find.byKey(const Key('environment-studio-editor-panel')),
+          findsOneWidget);
+    });
+    testWidgets('structure les sections numérotées du preset sélectionné',
+        (tester) async {
+      expect(find.byKey(const Key('environment-studio-section-number-1')),
+          findsOneWidget);
+      expect(find.byKey(const Key('environment-studio-section-number-2')),
+          findsOneWidget);
+      expect(find.byKey(const Key('environment-studio-section-number-3')),
+          findsOneWidget);
+    });
+    testWidgets('garde Studio limité aux presets sans commandes de map',
+        (tester) async {
+      expect(find.text('Generate'), findsNothing);
+      expect(find.text('Regenerate'), findsNothing);
+      expect(find.text('Clear'), findsNothing);
+      expect(find.text('Peindre le masque'), findsNothing);
+    });
+  });
```

## 14. Auto-review

- L’écran a-t-il visiblement changé ? Oui : shell large, header compact, colonnes, surfaces identifiées.
- L’écran exploite-t-il mieux la largeur disponible ? Oui : suppression du `Center` + `ConstrainedBox(maxWidth: 1040)`.
- Le header est-il plus compact ? Oui.
- La bannière produit est-elle propre ? Oui.
- La colonne Presets ressemble-t-elle davantage à une vraie navigation ? Oui.
- Le panneau Éditer le preset est-il mieux structuré ? Oui.
- Les sections numérotées sont-elles présentes ? Oui, sections 1/2/3.
- Les textes obsolètes ont-ils disparu du contenu principal ? Oui, tests anti-régression.
- Les comportements palette existants sont-ils préservés ? Oui, tests palette +19.
- Le guard anti-mélange tileset est-il préservé ? Oui, tests palette/use case passent.
- Environment Studio reste-t-il un atelier de presets ? Oui.
- Aucune peinture/génération sur map ? Oui.
- Aucun `map_core` modifié ? Oui.
- Aucun generated file ? Oui.
- Aucun build_runner ? Oui.
- Aucun TileLayer inspector modifié ? Oui.
- Aucun canvas modifié ? Oui.

## 15. Critique du prompt et du lot

Clair :

- objectif visuel structurel ;
- non-objectifs métier ;
- priorité aux colonnes/header/banner/sections ;
- besoin de préserver les flows palette précédents.

Ambigu :

- le prompt mentionne deux screenshots A/B, mais seul le mockup cible était présent dans le contexte visible de cette session. J’ai donc aligné sur les éléments explicitement décrits : header, bannière, deux colonnes, sections numérotées.

À trancher avant EnvironmentStudio-3B :

- densité exacte de la table palette ;
- emplacement final du bloc diagnostics projet : colonne gauche, bas du panneau droit ou panneau latéral ;
- traitement visuel des thumbnails/tilesets dans les rows de palette.

## 16. Verdict

```text
EnvironmentStudio-3A livré
Code produit modifié : oui
Code UI modifié : oui
Tests ciblés : pass
Analyze ciblé : pass
Prochain lot recommandé : EnvironmentStudio-3B — Palette Table & Diagnostics Polish V0
```

## Checklist finale

- [x] Je n’ai fait aucun commit.
- [x] Je n’ai pas utilisé git add.
- [x] Je n’ai pas utilisé git push.
- [x] Je n’ai pas utilisé git reset/checkout/restore/stash.
- [x] Je n’ai pas lancé build_runner.
- [x] Je n’ai modifié aucun generated file.
- [x] Je n’ai pas ajouté de commentaire dans le code.
- [x] Je n’ai pas modifié map_core.
- [x] Je n’ai pas modifié runtime/gameplay/battle.
- [x] Je n’ai pas modifié le workflow TileLayer Environment.
- [x] Je n’ai pas ajouté de peinture/génération dans Environment Studio.
- [x] Le shell visuel a changé.
- [x] Le layout deux colonnes est présent.
- [x] Le header et la bannière sont présents.
- [x] Les sections numérotées sont présentes.
- [x] Les comportements palette existants sont préservés.
- [x] Les tests ciblés passent.
- [x] L’analyse ciblée est documentée.
- [x] Le rapport distingue les fichiers préexistants des fichiers du lot.
