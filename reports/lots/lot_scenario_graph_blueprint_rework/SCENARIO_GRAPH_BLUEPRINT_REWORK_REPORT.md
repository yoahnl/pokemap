# Scenario Graph Blueprint Rework — Rapport Technique Ultra Complet

## 1. Résumé exécutif honnête

Ce lot implémente une refonte UX/logic du Scenario Graph Editor orientée usage “Blueprint-like” sans casser l’architecture existante.

Résultat concret:

- diagnostic de flow pur et testable (atteignabilité, incohérences, complétude),
- transparence runtime/authoring explicite,
- mode advanced assisté (pickers + suggestions + fallback raw),
- recettes de composition plus strictes (append/replace/chain + nettoyage),
- meilleure lisibilité du flow (End auto-ajouté sur recettes linéaires + diagnostics visibles dans le canvas et l’inspecteur),
- guide utilisateur long et pédagogique commitable.

Limite assumée:

- le graphe scénario n’est **pas** encore consommé automatiquement par le runtime (affiché explicitement dans l’UI + documenté).

---

## 2. Type exact de travail réalisé

**Audit + implémentation + tests + documentation.**

- Audit code réel map_editor + runtime/gameplay.
- Implémentation ciblée sur `map_editor`.
- Ajout de logique pure testable.
- Ajout de tests unitaires dédiés.
- Rédaction d’un guide utilisateur et de ce rapport.

---

## 3. Audit initial précis

### 3.1 Constat sur l’état initial

- L’inspecteur avait déjà des aides/presets, mais:
  - les recettes pouvaient polluer le flow (edges existants conservés sans stratégie),
  - pas de diagnostic global de cohérence,
  - mode advanced trop raw (IDs à la main),
  - distinction runtime vs authoring encore insuffisamment structurelle.
- Le canvas central existait, avec nodes/edges/drag/link, mais sans diagnostic de qualité visible.

### 3.2 Audit runtime (honnêteté)

Commande audit:

```bash
rg -n "ScenarioAsset|scenarios|select.*scenario|scenario" packages/map_runtime/lib/src -g '*.dart'
```

Résultat factuel:

- aucune consommation directe de `ScenarioAsset`/`project.scenarios` en runtime,
- seule occurrence “scenario” dans `runtime_story_branching.dart` via `scenario_conditions.dart` (conditions sur events/scripts), pas d’exécution du Scenario Graph.

Fichiers vérifiés:

- `packages/map_runtime/lib/src/application/runtime_story_branching.dart`
- `packages/map_gameplay/lib/src/event_page_resolver.dart`

Verdict audit runtime:

- le Scenario Graph est actuellement un **orchestrateur authoring**, pas une source d’exécution auto branchée.

### 3.3 Réponses aux problèmes ciblés

1. **Advanced trop brut**: vrai; absence d’assistance systématique.
2. **Flow pas auto-cohérent**: vrai; recettes non-strictes sur sorties existantes.
3. **Reference ambigu**: vrai; besoin d’intention métier explicite (source vs référence).
4. **Runtime support flou**: vrai; besoin de statut structuré.
5. **Blueprint feel incomplet**: vrai; besoin d’aides orientées trigger/condition/effect.
6. **Recettes insuffisantes**: vrai; besoin de modes insertion/remplacement/chaînage.
7. **Cas “entrée map -> dialogue” pas trivial**: partiellement vrai; recette existante mais manque de stratégie de flow et d’honnêteté runtime visible.

---

## 4. Principes d’architecture retenus

1. **Pas de refonte destructive du modèle `map_core`**: on garde `ScenarioAsset/Node/Edge`.
2. **Ajout d’une couche pure de diagnostic**: `scenario_flow_diagnostics.dart`.
3. **Clarification UX au-dessus du modèle**:
   - intention node (source/condition/effect/dialogue/choice/end),
   - statut d’exécution explicite (runtime connected / runtime-capable non branché / authoring bridge / planned).
4. **Advanced assisté + raw fallback**:
   - pickers en priorité,
   - raw conservé pour expert.
5. **Recettes guidées avec stratégie de branchement**:
   - append,
   - replace outgoing,
   - chain.

---

## 5. Liste exhaustive des fichiers réellement modifiés

- `packages/map_editor/lib/src/features/scenario/scenario_authoring_ux.dart`
- `packages/map_editor/lib/src/ui/panels/scenario_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/scenario_graph_canvas.dart`
- `packages/map_editor/test/scenario_authoring_ux_test.dart`

---

## 6. Liste exhaustive des fichiers réellement créés

- `packages/map_editor/lib/src/features/scenario/scenario_flow_diagnostics.dart`
- `packages/map_editor/test/scenario_flow_diagnostics_test.dart`
- `guides/SCENARIO_GRAPH_EDITOR_BLUEPRINT_GUIDE.md`
- `reports/lots/lot_scenario_graph_blueprint_rework/SCENARIO_GRAPH_BLUEPRINT_REWORK_REPORT.md`

---

## 7. Liste exhaustive des fichiers analysés mais non modifiés

- `packages/map_runtime/lib/src/application/runtime_story_branching.dart`
- `packages/map_gameplay/lib/src/event_page_resolver.dart`
- `packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_core/lib/src/validation/validators.dart`
- `packages/map_core/lib/src/models/scenario_asset.dart`

---

## 8. Extraits de code importants avec explications

## 8.1 Statut runtime/authoring explicite (UX)

Fichier: `scenario_authoring_ux.dart`

```dart
const bool kScenarioGraphRuntimeExecutionConnected = false;
```

Pourquoi:

- centraliser une vérité UX: le graph n’est pas encore auto-exécuté runtime.

Ajouts majeurs:

- `ScenarioNodeIntent` + `scenarioNodeIntent(...)`
- `ScenarioNodeExecutionState` + labels/descriptions
- `scenarioNodeExecutionState(...)`

Effet:

- l’inspecteur peut afficher un statut honnête et compréhensible.

## 8.2 Diagnostic de flow pur, testable

Fichier: `scenario_flow_diagnostics.dart`

API:

- `analyzeScenarioFlow(ScenarioAsset scenario, {bool graphRuntimeConnected})`
- `ScenarioFlowReport`, `ScenarioFlowSummary`, `ScenarioFlowIssue`

Règles implémentées:

- nodes non atteignables depuis entry,
- nodes isolés (pas d’entrées),
- cul-de-sac non terminaux,
- `condition` / `choice` sans >=2 sorties,
- `end` avec sorties,
- complétude node (action/dialogue/condition/reference).

Effet:

- base unique pour diagnostics UI + tests unitaires.

## 8.3 Inspecteur: diagnostic global + node

Fichier: `scenario_inspector_panel.dart`

Ajouts clés:

- `_buildScenarioDiagnosticsCard(...)`
- `_buildNodeIssuesCard(...)`
- résumé node enrichi:
  - intention,
  - statut runtime/authoring,
  - connectivité,
  - compte erreurs/avertissements.

Effet:

- l’utilisateur voit immédiatement si son flow est fiable ou incomplet.

## 8.4 Mode advanced assisté (pas raw-only)

Fichier: `scenario_inspector_panel.dart`

`_buildAdvancedNodeSection(...)` refondu:

- pickers assistés pour:
  - action/reference preset,
  - script,
  - dialogue,
  - map,
  - event/entity/warp/trigger (filtrés map),
  - trainer,
  - suggestions flags/variables.
- champs raw conservés en fallback expert.

Effet:

- baisse drastique de saisie manuelle d’IDs.

## 8.5 Recettes Blueprint plus strictes

Fichier: `scenario_inspector_panel.dart`

Ajouts:

- `_ScenarioRecipeLinkMode` (`append`, `replaceOutgoing`, `chain`)
- `_pickRecipePlan(...)`
- `_connectRecipeFlow(...)`
- `_showRecipeAppliedSummary(...)`

Recettes mises à jour:

- entrée map -> dialogue
- entrée trigger -> dialogue
- interaction entité -> script
- combat dresseur
- condition flag A/B

Nouveaux comportements:

- suppression contrôlée d’edges existants selon mode,
- chaînage vers ancienne cible quand applicable,
- End automatique sur recettes linéaires.

## 8.6 Canvas: diagnostic visible

Fichier: `scenario_graph_canvas.dart`

Ajout:

- appel `analyzeScenarioFlow(...)`,
- affichage synthèse erreurs/avertissements/non atteignables dans toolbar du workspace.

Effet:

- feedback de qualité de flow visible directement dans l’espace central.

---

## 9. Validations réellement exécutées

## 9.1 Format

```bash
dart format packages/map_editor/lib/src/features/scenario/scenario_authoring_ux.dart \
  packages/map_editor/lib/src/features/scenario/scenario_flow_diagnostics.dart \
  packages/map_editor/lib/src/ui/panels/scenario_inspector_panel.dart \
  packages/map_editor/lib/src/ui/canvas/scenario_graph_canvas.dart \
  packages/map_editor/test/scenario_authoring_ux_test.dart \
  packages/map_editor/test/scenario_flow_diagnostics_test.dart
```

Résultat: OK.

## 9.2 Analyze ciblé

```bash
cd packages/map_editor
flutter analyze lib/src/features/scenario/scenario_authoring_ux.dart \
  lib/src/features/scenario/scenario_flow_diagnostics.dart \
  lib/src/ui/panels/scenario_inspector_panel.dart \
  lib/src/ui/canvas/scenario_graph_canvas.dart \
  test/scenario_authoring_ux_test.dart \
  test/scenario_flow_diagnostics_test.dart
```

Résultat: **No issues found**.

## 9.3 Tests ciblés

```bash
cd packages/map_editor
flutter test test/scenario_authoring_ux_test.dart test/scenario_flow_diagnostics_test.dart
```

Résultat: **All tests passed**.

## 9.4 Analyze global package

```bash
cd packages/map_editor
flutter analyze
```

Résultat: **KO (préexistant global)** avec un grand volume d’infos/warnings legacy (deprecations providers Riverpod, etc.).

## 9.5 Tests package complet

```bash
cd packages/map_editor
flutter test
```

Résultat: **All tests passed**.

---

## 10. Ce qui a été vérifié manuellement

- Vérification statique des flows recettes dans le code (append/replace/chain).
- Vérification logique des diagnostics (comptages/règles).
- Vérification cohérence runtime honesty (graph non branché).

---

## 11. Ce qui n’a PAS été vérifié

- playtest UI desktop interactif en session Flutter lancée visuellement (non exécuté ici),
- validation UX “ressenti utilisateur” avec scénarios réels en production content,
- branchement runtime complet du Scenario Graph (hors scope + non existant).

---

## 12. Limites restantes

1. Le runtime n’exécute pas automatiquement le Scenario Graph complet.
2. Les diagnostics n’appliquent pas encore d’auto-fix automatique global.
3. Les recettes couvrent les cas MVP, pas l’ensemble d’un système de quête complet.
4. Le global analyze `map_editor` contient encore des passifs legacy hors scope.

---

## 13. Prochaines étapes recommandées

1. Brancher progressivement l’exécution runtime du Scenario Graph (minimum pour presets source -> dialogue/script).
2. Ajouter actions de correction rapide depuis diagnostics (ex: “add End”, “connect node”).
3. Ajouter lint métier “graph executable profile” séparé du lint authoring.
4. Ajouter widget tests ciblés des sections critiques de l’inspecteur.

---

## 14. Verdict final honnête

**Lot réussi côté UX/authoring blueprint foundation.**

Amélioration réelle livrée:

- moins d’IDs bruts,
- plus de guidage,
- flow plus cohérent,
- diagnostic explicite,
- statut runtime/authoring transparent.

**Mais**:

- l’exécution runtime automatique du Scenario Graph reste non branchée (assumé et rendu explicite dans l’UI).

---

## 15. État git final exact

Commande:

```bash
git status --short --untracked-files=all
```

État au moment du rapport:

```text
 M packages/map_editor/lib/src/features/scenario/scenario_authoring_ux.dart
 M packages/map_editor/lib/src/ui/canvas/scenario_graph_canvas.dart
 M packages/map_editor/lib/src/ui/panels/scenario_inspector_panel.dart
 M packages/map_editor/test/scenario_authoring_ux_test.dart
?? guides/SCENARIO_GRAPH_EDITOR_BLUEPRINT_GUIDE.md
?? packages/map_editor/lib/src/features/scenario/scenario_flow_diagnostics.dart
?? packages/map_editor/test/scenario_flow_diagnostics_test.dart
?? reports/lots/lot_scenario_graph_blueprint_rework/SCENARIO_GRAPH_BLUEPRINT_REWORK_REPORT.md
```

---

## 16. Note de conformité process

- Aucun commit effectué.
- Aucun amend effectué.
- Aucun merge/rebase/push/tag/stash/reset/cherry-pick effectué.
- Aucune écriture Git hors modifications de fichiers de travail.
