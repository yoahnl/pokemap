# LOT 59 — Full Rollback `Scenario Graph` / `Scenario Scripts` (map_editor)

## 1. Résumé exécutif honnête
Le rollback demandé a été appliqué de manière large dans `map_editor`:
- suppression complète des surfaces UI `Scenario Graph` et `Scenario Scripts` (gauche/centre/droite/toolbar),
- suppression des fichiers UI associés,
- suppression de la logique applicative `map_editor` dédiée (use cases + providers + notifier methods),
- nettoyage des tests liés à cette couche.

Le runtime (`map_runtime`) n’a pas été touché.

## 2. Type exact de travail réalisé
- Audit ciblé de la couche scénario/scripts dans `map_editor`.
- Implémentation d’un rollback structurel (pas un simple renommage UI).
- Nettoyage du code mort associé.
- Régénération des fichiers générés (`build_runner`) après suppression de champs/providers.

## 3. Audit initial précis
### 3.1 Constat au démarrage
La capture fournie confirmait que l’UI affichait toujours:
- `Scenario Graphs`
- `Scenario Scripts`

dans le panneau gauche.

### 3.2 Points d’ancrage identifiés
Les entrées étaient branchées principalement via:
- `project_explorer_panel.dart` (tuiles gauche),
- `editor_shell_page.dart` (mode workspace + inspector scénario),
- `editor_canvas_host.dart` (canvas scénario),
- `top_toolbar.dart` (switch workspace scénario),
- `editor_notifier.dart` (méthodes scénario/scripts),
- `use_case_providers.dart` + use cases dédiés.

### 3.3 Diagnostic
Le système n’était pas un reliquat purement visuel: il restait des points d’entrée UI + logique côté éditeur.

## 4. Principes de rollback appliqués
- Retirer les points d’accès utilisateur avant tout (navigation + workspace + inspector + canvas).
- Retirer la logique `map_editor` dédiée (méthodes notifier + use cases + providers).
- Nettoyer les fichiers morts (UI + tests + use cases dédiés).
- Conserver le reste du projet (runtime, map_core) pour éviter un rollback destructif hors périmètre.

## 5. Liste exhaustive des fichiers réellement modifiés
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.freezed.dart` (généré)
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.g.dart` (généré)
- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/lib/src/app/providers/use_case_providers.dart`
- `packages/map_editor/lib/src/app/providers/use_case_providers.g.dart` (généré)
- `packages/map_editor/lib/src/application/use_cases/use_cases.dart`

## 6. Liste exhaustive des fichiers réellement supprimés
- `packages/map_editor/lib/src/ui/canvas/scenario_graph_canvas.dart`
- `packages/map_editor/lib/src/ui/panels/scenario_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/panels/scenario_library_panel.dart`
- `packages/map_editor/lib/src/ui/panels/script_library_panel.dart`
- `packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/project_script_use_cases.dart`
- `packages/map_editor/lib/src/features/scenario/scenario_authoring_ux.dart`
- `packages/map_editor/lib/src/features/scenario/scenario_flow_diagnostics.dart`
- `packages/map_editor/test/project_scenario_use_cases_test.dart`
- `packages/map_editor/test/project_script_use_cases_test.dart`
- `packages/map_editor/test/scenario_authoring_ux_test.dart`
- `packages/map_editor/test/scenario_flow_diagnostics_test.dart`

## 6.b Fichiers créés
- `reports/lots/lot_59_scenario_graph_script_full_rollback/LOT_59_SCENARIO_GRAPH_SCRIPT_FULL_ROLLBACK_REPORT.md`

## 7. Liste des fichiers analysés mais non modifiés (audit)
- `packages/map_editor/lib/src/ui/panels/event_properties_panel.dart`
- `packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart`
- `packages/map_editor/lib/src/application/ports/project_workspace.dart`

## 8. Extraits de code importants avec explications
### 8.1 Suppression du mode workspace scénario
Dans `editor_state.dart`, l’enum a été réduit:

```dart
enum EditorWorkspaceMode {
  map,
  // Rollback UI scénario:
  // Le workspace "scenario" est volontairement retiré de l’éditeur...
  tileset,
}
```

Effet: plus de branche UI officielle vers un espace scénario.

### 8.2 Retrait du switch toolbar vers scénario
Dans `top_toolbar.dart`, le bouton scénario a été supprimé du groupe `Workspace`.

Effet: impossible de basculer vers un mode scénario depuis la barre.

### 8.3 Retrait des tuiles gauche `Scenario Graphs` / `Scenario Scripts`
Dans `project_explorer_panel.dart`, les `InspectorSectionCard` dédiées ont été retirées et le sous-titre du bloc Explorer a été nettoyé.

Effet: la navigation gauche ne montre plus ces éléments.

### 8.4 Retrait de la logique notifier
Dans `editor_notifier.dart`, les blocs:
- `Project scenarios (workspace graph)`
- `Project scenario scripts (bibliothèque runtime)`

ont été supprimés, avec un commentaire explicite de rollback.

Effet: plus d’API de mutation scénario/scripts côté notifier éditeur.

### 8.5 Retrait providers/use-cases dédiés
Dans `use_case_providers.dart`, suppression:
- imports `project_scenario_use_cases.dart` / `project_script_use_cases.dart`,
- providers scénario/scripts runtime.

Effet: la couche application `map_editor` n’expose plus ces use cases.

## 9. Validations réellement exécutées
### 9.1 Génération de code
Commande:
```bash
cd packages/map_editor
flutter pub run build_runner build --delete-conflicting-outputs
```
Résultat: succès (`Built with build_runner ... wrote 8 outputs`).

### 9.2 Format
Commande:
```bash
dart format packages/map_editor/lib/src/app/providers/use_case_providers.dart \
  packages/map_editor/lib/src/application/use_cases/use_cases.dart \
  packages/map_editor/lib/src/features/editor/state/editor_notifier.dart \
  packages/map_editor/lib/src/features/editor/state/editor_state.dart \
  packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart \
  packages/map_editor/lib/src/ui/editor_shell_page.dart \
  packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart \
  packages/map_editor/lib/src/ui/shared/top_toolbar.dart
```
Résultat: succès (`Formatted 8 files (0 changed)`).

### 9.3 Analyse statique
Commande:
```bash
flutter analyze packages/map_editor
```
Résultat:
- pas d’erreur bloquante liée au rollback,
- sortie en `info`/`warning` préexistants et globaux (Riverpod deprecated refs, lint divers, warnings hors périmètre).

### 9.4 Tests
Commande 1:
```bash
flutter test packages/map_editor
```
Résultat: échec (commande lancée depuis la racine monorepo sans pubspec Flutter racine).

Commande 2:
```bash
cd packages/map_editor
flutter test
```
Résultat: échec attendu (`test` ne contient plus de fichiers de test après suppression ciblée des tests scénario/scripts).

## 10. Ce qui a été vérifié manuellement
- Vérification statique des références import/symboles supprimés (`rg`) dans `map_editor`.
- Vérification de disparition des occurrences `Scenario Graphs` / `Scenario Scripts` dans le code source de l’éditeur.

## 11. Ce qui n’a PAS été vérifié
- Test manuel visuel en lançant l’app desktop Flutter (non exécuté dans cette passe).
- Validation end-to-end d’un projet utilisateur existant contenant déjà `scenarios` / `scripts` dans son manifest.

## 12. Limites restantes
- Le schéma `ProjectManifest` dans `map_core` contient toujours les structures `scenarios` / `scripts`.
- Certaines UI hors scope rollback peuvent encore référencer des scripts projet existants (ex: pages d’events), mais sans bibliothèque dédiée supprimée.
- Le runtime n’a pas été modifié (intentionnel).

## 13. Verdict final honnête
Rollback **profond et réel** effectué côté `map_editor`:
- les éléments `Scenario Graph` et `Scenario Scripts` ne sont plus exposés en UI,
- leur logique applicative dédiée a été retirée du flux éditeur,
- le code mort associé a été supprimé.

Ce n’est pas un rollback global monorepo (`map_core`/`map_runtime` inchangés), mais un rollback complet de la couche éditeur demandée.

## 14. État git final exact
Sortie `git status --short` à la fin de cette intervention:

```text
 A AGENTS.md
 M packages/map_editor/lib/src/app/providers/use_case_providers.dart
 M packages/map_editor/lib/src/app/providers/use_case_providers.g.dart
D  packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart
D  packages/map_editor/lib/src/application/use_cases/project_script_use_cases.dart
 M packages/map_editor/lib/src/application/use_cases/use_cases.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.g.dart
 M packages/map_editor/lib/src/features/editor/state/editor_state.dart
 M packages/map_editor/lib/src/features/editor/state/editor_state.freezed.dart
 D packages/map_editor/lib/src/features/scenario/scenario_authoring_ux.dart
 D packages/map_editor/lib/src/features/scenario/scenario_flow_diagnostics.dart
 M packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
D  packages/map_editor/lib/src/ui/canvas/scenario_graph_canvas.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
D  packages/map_editor/lib/src/ui/panels/scenario_inspector_panel.dart
D  packages/map_editor/lib/src/ui/panels/scenario_library_panel.dart
D  packages/map_editor/lib/src/ui/panels/script_library_panel.dart
 M packages/map_editor/lib/src/ui/shared/top_toolbar.dart
D  packages/map_editor/test/project_scenario_use_cases_test.dart
D  packages/map_editor/test/project_script_use_cases_test.dart
 D packages/map_editor/test/scenario_authoring_ux_test.dart
 D packages/map_editor/test/scenario_flow_diagnostics_test.dart
?? reports/lots/lot_58_ui_scenario_full_rollback/
?? reports/lots/lot_59_scenario_graph_script_full_rollback/
```

Note:
- `AGENTS.md` était déjà présent comme fichier ajouté hors scope de cette intervention.
- Le dossier `reports/lots/lot_58_ui_scenario_full_rollback/` est un untracked préexistant de la passe précédente.
