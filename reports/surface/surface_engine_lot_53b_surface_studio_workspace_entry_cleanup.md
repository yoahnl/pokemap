# Lot 53-bis — Surface Studio Workspace Entry cleanup / evidence sync

## 1. Résumé exécutif

Correction **minimale** sur `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart` : suppression des **9 infos** `prefer_const_*` signalées par `flutter analyze` après les retouches DA, **sans** changement de comportement, de design, ni refactor. Les tests ciblés Surface Studio (`map_editor`) et le test de non-régression `map_core` `surface_studio_read_model_test` sont **verts**. Ce lot **ne crée pas** de rapport Evidence supplémentaire pour le gel Lot 53 : il documente l’état final et une **liste de fichiers Surface Studio** explicite (§9).

## 2. Lot 53 : fonctionnel mais non « fermé »

Le Lot 53 (entrée workspace Surface Studio) est **correct fonctionnellement** : mode `surfaceStudio`, navigation, panneau read-only. Il manquait toutefois une **clôture technique** : (1) analyse non vide sur le panneau, (2) evidence / statut git imprécis pour l’audit. Le 53-bis adresse le point (1) dans le code ; le point (2) est traité par ce **rapport** et la §9.

## 3. Fichiers modifiés par le Lot 53-bis (strict)

| Fichier | Rôle |
|---------|------|
| `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart` | Seul fichier **édité** dans ce lot : `const` / `const TextStyle` / `const Row` pour satisfaire l’analyseur. |

Aucun autre fichier n’a été modifié pour le 53-bis.

## 4. Diff réel complet — modifications 53-bis uniquement

Le dépôt peut contenir d’autres changements non commités (Lot 52/53/DA) sur le même fichier. Le **diff 53-bis** correspond à la transition *avant cleanup `prefer_const`* → *après cleanup*, **uniquement** via const-correctness.

```diff
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
@@ -216,7 +216,7 @@ class _ReadOnlyBadge extends StatelessWidget {
   @override
   Widget build(BuildContext context) {
-    final accent = _surfaceStudioAccent;
+    const accent = _surfaceStudioAccent;
     final fill = Color.lerp(
       EditorChrome.islandFillElevated(context),
       accent,
@@ -231,10 +231,10 @@ class _ReadOnlyBadge extends StatelessWidget {
       child: Text(
         label,
-        style: TextStyle(
-          color: accent,
+        style: const TextStyle(
+          color: _surfaceStudioAccent,
           fontSize: 11,
           fontWeight: FontWeight.w800,
           letterSpacing: 0.2,
         ),
       ),
@@ -354,8 +354,8 @@ class _DiagnosticsSummary extends StatelessWidget {
     if (d.isClean) {
       children.add(
-        Row(
+        const Row(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             MacosIcon(
@@ -364,7 +364,7 @@ class _DiagnosticsSummary extends StatelessWidget {
               color: EditorChrome.inspectorJoyCyan,
               size: 18,
             ),
-            const SizedBox(width: 8),
+            SizedBox(width: 8),
             Expanded(
               child: Text(
                 SurfaceStudioPanel.diagnosticsCleanText,
@@ -384,7 +384,7 @@ class _DiagnosticsSummary extends StatelessWidget {
           Text(
             '$err — ${SurfaceStudioPanel.diagnosticsErrorsText}',
-            style: TextStyle(
+            style: const TextStyle(
               color: EditorChrome.inspectorJoyCoral,
               fontSize: 14,
               fontWeight: FontWeight.w600,
@@ -398,7 +398,7 @@ class _DiagnosticsSummary extends StatelessWidget {
             child: Text(
               '$warn — ${SurfaceStudioPanel.diagnosticsWarningsText}',
-              style: TextStyle(
+              style: const TextStyle(
                 color: EditorChrome.accentWarm,
                 fontSize: 14,
                 fontWeight: FontWeight.w600,
```

*Remarque* : le `TextStyle` du texte « clean » reste **non-`const`** (enfant du `const Row`) car l’analyseur l’accepte ainsi ; les 9 signalements d’origine concernaient surtout `accent`, le `Row`, et les `TextStyle` des branches erreur / avertissement / badge.

## 5. Sortie exacte — `flutter analyze` (cible Lot 53-bis)

Commande :

```bash
cd packages/map_editor
flutter analyze \
  lib/src/features/surface_studio/surface_studio_panel.dart \
  test/surface_studio/surface_studio_panel_test.dart \
  test/surface_studio/surface_studio_workspace_entry_test.dart
```

Sortie **exacte** (exit code 0) :

```text
Analyzing 3 items...                                            
No issues found! (ran in 1.6s)
```

## 6. Sorties exactes — tests ciblés

### `surface_studio_workspace_entry_test.dart`

```bash
cd packages/map_editor
flutter test test/surface_studio/surface_studio_workspace_entry_test.dart
```

Dernière ligne :

```text
00:05 +11: All tests passed!
```

### `surface_studio_panel_test.dart`

```bash
cd packages/map_editor
flutter test test/surface_studio/surface_studio_panel_test.dart
```

Dernière ligne :

```text
00:03 +23: All tests passed!
```

### Combiné (panneau + workspace entry)

```bash
cd packages/map_editor
flutter test test/surface_studio/surface_studio_panel_test.dart test/surface_studio/surface_studio_workspace_entry_test.dart
```

Dernière ligne :

```text
00:06 +34: All tests passed!
```

### `map_core` — read model (non-régression)

```bash
cd packages/map_core
dart test test/surface_studio_read_model_test.dart
```

Dernière ligne :

```text
00:00 +30: All tests passed!
```

## 7. `git status --short --untracked-files=all` **initial** (début de la mission 53-bis, avant toute édition agent)

*Capturé avant modification de `surface_studio_panel.dart` pour ce lot.*

```text
 M packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
 M packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
 M packages/map_editor/lib/src/ui/shared/top_toolbar.dart
 M packages/map_editor/test/editor_selectors_test.dart
 M packages/map_editor/test/editor_workspace_controller_test.dart
 M packages/map_editor/test/shell_chrome_test_harness.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
?? packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
?? reports/surface/surface_engine_lot_53_surface_studio_workspace_entry.md
```

## 8. `git status --short --untracked-files=all` **final** (après 53-bis + création de ce rapport)

```text
 M packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
 M packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
 M packages/map_editor/lib/src/ui/shared/top_toolbar.dart
 M packages/map_editor/test/editor_selectors_test.dart
 M packages/map_editor/test/editor_workspace_controller_test.dart
 M packages/map_editor/test/shell_chrome_test_harness.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
?? packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
?? reports/surface/surface_engine_lot_53_surface_studio_workspace_entry.md
?? reports/surface/surface_engine_lot_53b_surface_studio_workspace_entry_cleanup.md
```

## 9. Fichiers Surface Studio (Lot 53 + 53-bis) — inventaire **précis** dans l’arbre de travail

Fichiers **liés** à Surface Studio / entrée workspace (hors `map_core`), tels qu’observés sur la base du statut initial §7, complété par le rapport 53-bis §8 :

| Chemin | Statut type |
|--------|-------------|
| `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart` | modifié (52 + DA + **53-bis const**) |
| `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart` | modifié (entrée `surfaceStudio`) |
| `packages/map_editor/lib/src/ui/editor_shell_page.dart` | modifié (tint / inspecteur Surface) |
| `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart` | modifié (tuile World Explorer) |
| `packages/map_editor/lib/src/ui/shared/top_toolbar.dart` | modifié (bouton workspace) |
| `packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart` | modifié (`surfaceStudio`) |
| `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart` | modifié (libellés shell) |
| `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` | modifié |
| `packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart` | modifié |
| `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart` | modifié |
| `packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart` | non suivi (au moment du statut initial) |
| `packages/map_editor/test/shell_chrome_test_harness.dart` | modifié (`ProjectSurfaceCatalog` test harness) |
| `packages/map_editor/test/editor_selectors_test.dart` | modifié (assertions / `surfaceCatalog`) |
| `packages/map_editor/test/editor_workspace_controller_test.dart` | modifié |
| `reports/surface/surface_engine_lot_53_surface_studio_workspace_entry.md` | non suivi (au moment des statuts §7–§8) |
| `reports/surface/surface_engine_lot_53b_surface_studio_workspace_entry_cleanup.md` | non suivi (ce rapport ; présent au §8) |

Fichiers **non Surface** apparaissent dans `git status` (même branche) au titre du Lot 53 ; le 53-bis n’en a touché **aucun**.

## 10. Périmètre non modifié (confirmations)

- **`map_core`** : aucun fichier modifié pour le 53-bis ; test `surface_studio_read_model_test` relancé, vert.
- **`ProjectManifest`** (fichier / schéma / générateur) : non modifié.
- **Codecs JSON Surface, fixtures Lot 47, runtime, gameplay, battle** : non modifiés par le 53-bis.
- **`build_runner`** : non lancé.

## 11. Comportement produit (confirmations)

- Aucun **provider Riverpod** ajouté.
- Aucune **édition** ni **sauvegarde** Surface, aucun **repository** Surface, dans ce lot.

## 12. Auto-review finale

- [x] `prefer_const` corrigé uniquement dans `surface_studio_panel.dart`, sans refactor ni changement d’apparence fonctionnelle.
- [x] `flutter analyze` cible Lot 53-bis : `No issues found!`.
- [x] Tests : 11 + 23 + 34 (combiné) + 30 `map_core` : verts (sorties §6).
- [x] `map_core` intact ; branchement Lot 53 inchangé par le 53-bis.
- [x] Aucune commande Git d’écriture utilisée.
- [x] Rapport 53-bis : fichiers, diff 53-bis, commandes, sorties, listes de statut / Surface Studio, périmètre.

**Risque résiduel** : si le diff `git` de `surface_studio_panel.dart` par rapport à `HEAD` est volumineux, il inclut d’autres lots non commités — le **§4** isole le patch const-only du 53-bis.

**Prochaine étape recommandée** (hors 53-bis) : commit groupé côté utilisateur, puis alignement optionnel du rapport Lot 53 (Evidence) sur l’analyse zéro défaut, si souhaité.
