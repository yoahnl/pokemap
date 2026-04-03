# LOT 58 — UI Scenario Full Rollback (map_editor)

## 1. Résumé exécutif honnête
Rollback UI large effectué dans `map_editor` pour supprimer la surcouche scénario récente.

Ce qui a été réellement fait:
- suppression des helpers UI/storytelling avancés (`scenario_authoring_ux.dart`, `scenario_flow_diagnostics.dart`);
- suppression des tests associés devenus hors-scope UI rollback;
- simplification forte de `ScenarioInspectorPanel` vers une version minimale;
- simplification du `ScenarioGraphCanvas` (retrait des diagnostics/story support UI);
- conservation d’une `ScenarioLibraryPanel` simple (liste/scénario CRUD basique) sans Story Navigator.

Ce qui a été volontairement conservé:
- logique runtime dans `map_runtime` (non touchée);
- modèles `map_core` et use cases runtime/persistance;
- structure scénario de base (nodes/edges/entry), avec UI minimale pour l’éditer.

## 2. Audit — surcouche UI parasite identifiée

### 2.1 Cibles auditées (priorité demandée)
- `packages/map_editor/lib/src/ui/panels/scenario_library_panel.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/lib/src/ui/panels/scenario_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/scenario_graph_canvas.dart`
- `packages/map_editor/lib/src/features/scenario/scenario_authoring_ux.dart`
- `packages/map_editor/lib/src/features/scenario/scenario_flow_diagnostics.dart`
- `packages/map_editor/lib/src/features/scenario/scenario_story_navigator.dart` (déjà retiré avant ce lot)
- `packages/map_editor/lib/src/app/providers/use_case_providers.dart`
- `packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/test/...` lié scénario UI

### 2.2 Constat factuel
La surcouche UI/éditeur se trouvait principalement dans:
1. `scenario_inspector_panel.dart` (très volumineux, orienté narration guidée, outcomes/global/local, recettes, diagnostics UX);
2. `scenario_graph_canvas.dart` (dépendance aux diagnostics/story helpers);
3. helpers dédiés:
   - `scenario_authoring_ux.dart`
   - `scenario_flow_diagnostics.dart`
4. tests uniquement liés à cette couche:
   - `scenario_authoring_ux_test.dart`
   - `scenario_flow_diagnostics_test.dart`

### 2.3 Diagnostic produit
Le système UI de `map_editor` exposait des concepts narratifs avancés (global/local/outcomes) sans base produit stabilisée, ce qui augmentait fortement la complexité UI et la dette de conception.

## 3. Stratégie de rollback retenue

Approche appliquée:
1. **Supprimer** les fichiers purement dédiés à la surcouche UI narrative.
2. **Réécrire** les panneaux centraux/inspecteur en version simple et stable.
3. **Conserver** le runtime et la logique non-UI.
4. **Nettoyer** imports/usages/tests morts.

Objectif: revenir à une base neutre et maintenable, pas créer une “v2 simplifiée” de la surcouche.

## 4. Liste exhaustive des fichiers audités
- `packages/map_editor/lib/src/ui/panels/scenario_library_panel.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/lib/src/ui/panels/scenario_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/scenario_graph_canvas.dart`
- `packages/map_editor/lib/src/features/scenario/scenario_authoring_ux.dart`
- `packages/map_editor/lib/src/features/scenario/scenario_flow_diagnostics.dart`
- `packages/map_editor/lib/src/app/providers/use_case_providers.dart`
- `packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/test/scenario_authoring_ux_test.dart`
- `packages/map_editor/test/scenario_flow_diagnostics_test.dart`
- `packages/map_editor/test/project_scenario_use_cases_test.dart`
- `packages/map_editor/test/project_script_use_cases_test.dart`

## 5. Liste exhaustive des fichiers modifiés
- `packages/map_editor/lib/src/ui/panels/scenario_library_panel.dart`
- `packages/map_editor/lib/src/ui/panels/scenario_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/scenario_graph_canvas.dart`

## 6. Liste exhaustive des fichiers supprimés
- `packages/map_editor/lib/src/features/scenario/scenario_authoring_ux.dart`
- `packages/map_editor/lib/src/features/scenario/scenario_flow_diagnostics.dart`
- `packages/map_editor/test/scenario_authoring_ux_test.dart`
- `packages/map_editor/test/scenario_flow_diagnostics_test.dart`

## 7. Liste exhaustive des fichiers conservés volontairement
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
  - Conservé: section scénario reste simple, pas de Story Navigator complexe.
- `packages/map_editor/lib/src/app/providers/use_case_providers.dart`
  - Conservé: pas de casse transversale; rollback strict UI.
- `packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart`
  - Conservé: logique application non-UI, même si des champs avancés existent.
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
  - Conservé: API complète côté state, non exposée par la nouvelle UI minimale.
- tests:
  - `packages/map_editor/test/project_scenario_use_cases_test.dart`
  - `packages/map_editor/test/project_script_use_cases_test.dart`
  - Conservés: tests applicatifs utiles hors surcouche UI retirée.

## 8. Détails des changements et justification

### 8.1 `scenario_library_panel.dart`
Actions:
- retrait de la dépendance `scenario_authoring_ux.dart`;
- retrait de l’affichage “scope global/local” dans la liste;
- conservation d’une liste simple avec create/select/open/rename/delete.

Justification:
- la colonne gauche doit rester sobre;
- pas de pseudo narration globale injectée dans la navigation.

### 8.2 `scenario_inspector_panel.dart`
Action majeure:
- remplacement complet par une version rollback minimaliste.

Ce que fait la nouvelle version:
- header scénario simple (create/switch/rename/delete);
- résumé scénario simple (description/entry/nodes/links);
- liste de nodes simple;
- éditeur node brut minimal (title/description/actionKind/message + IDs de binding);
- liste des edges sortants avec suppression.

Ce qui est explicitement retiré:
- recettes storytelling;
- diagnostics narratifs;
- logique UI outcomes/global/local;
- cartes relationnelles et logique d’assistance narrative.

### 8.3 `scenario_graph_canvas.dart`
Actions:
- retrait des imports `scenario_authoring_ux.dart` et `scenario_flow_diagnostics.dart`;
- retrait des diagnostics dans la toolbar;
- retrait de l’affichage scope global/local dans la toolbar;
- ajout de labels locaux simples pour type de node.

Justification:
- canvas recentré sur édition graphe basique (nodes/edges), sans surcouche narrative.

### 8.4 Suppression des helpers et tests de surcouche
Supprimés:
- `scenario_authoring_ux.dart`
- `scenario_flow_diagnostics.dart`
- tests associés.

Justification:
- code mort ou orienté mauvaise direction produit UI;
- éviter le maintien de dette “au cas où”.

## 9. Extraits de code clés (après rollback)

### 9.1 Frontière explicitement documentée (inspector)
```dart
/// Cette version est volontairement minimale:
/// - pas de Story Navigator;
/// - pas de grouping global/local dans l’inspecteur;
/// - pas de cartes relationnelles outcome;
/// - pas de recettes/storytelling assisté.
```

### 9.2 Canvas sans surcouche diagnostique
```dart
_ScenarioGraphToolbar(
  scenario: scenario,
  pendingFromNodeId: pendingFromNodeId,
  onAddNode: () => _promptAddNode(context, notifier, scenario),
  ...
)
```

### 9.3 Liste scénario simplifiée
```dart
'${scenario.id} · ${scenario.nodes.length} nodes · ${scenario.edges.length} links'
```

## 10. Validations exécutées

### 10.1 Format
Commande:
```bash
dart format \
  packages/map_editor/lib/src/ui/panels/scenario_library_panel.dart \
  packages/map_editor/lib/src/ui/panels/scenario_inspector_panel.dart \
  packages/map_editor/lib/src/ui/canvas/scenario_graph_canvas.dart \
  packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
```
Résultat: ✅

### 10.2 Analyze ciblé (fichiers touchés)
Commande:
```bash
cd packages/map_editor
dart analyze \
  lib/src/ui/panels/scenario_library_panel.dart \
  lib/src/ui/panels/scenario_inspector_panel.dart \
  lib/src/ui/canvas/scenario_graph_canvas.dart \
  lib/src/ui/panels/project_explorer_panel.dart
```
Résultat: ✅ No issues found.

### 10.3 Flutter analyze ciblé (fichiers touchés)
Commande:
```bash
cd packages/map_editor
flutter analyze --no-pub \
  lib/src/ui/panels/scenario_library_panel.dart \
  lib/src/ui/panels/scenario_inspector_panel.dart \
  lib/src/ui/canvas/scenario_graph_canvas.dart \
  lib/src/ui/panels/project_explorer_panel.dart
```
Résultat: ✅ No issues found.

### 10.4 Tests ciblés
Commande:
```bash
cd packages/map_editor
flutter test \
  test/project_scenario_use_cases_test.dart \
  test/project_script_use_cases_test.dart
```
Résultat: ✅ All tests passed.

### 10.5 Analyze large (panels/canvas/scenario/test)
Commande:
```bash
cd packages/map_editor
dart analyze lib/src/ui/panels lib/src/ui/canvas lib/src/features/scenario test
```
Résultat: ⚠️ warnings/infos préexistants hors périmètre (terrain/tileset/trainer/character...), pas d’erreur bloquante liée aux fichiers rollback.

## 11. Ce qui n’a PAS été fait
- aucun changement runtime (`map_runtime`) ;
- aucune refonte produit de remplacement ;
- aucune tentative de nouvelle UX “narrative” ;
- aucun commit / amend / rebase / merge / push / tag / stash / reset.

## 12. Limites restantes
1. Les use cases/notifier `updateProjectScenarioMetadata` (scope/outcomes/activationCondition) existent encore côté application `map_editor`, mais ne sont plus exposés par la UI rollback.
2. Le modèle de données conserve des champs avancés (normal; non-UI).
3. La future refonte devra redéfinir une UX propre depuis cette base minimaliste.

## 13. État git final exact
```bash
 D packages/map_editor/lib/src/features/scenario/scenario_authoring_ux.dart
 D packages/map_editor/lib/src/features/scenario/scenario_flow_diagnostics.dart
 M packages/map_editor/lib/src/ui/canvas/scenario_graph_canvas.dart
 M packages/map_editor/lib/src/ui/panels/scenario_inspector_panel.dart
 M packages/map_editor/lib/src/ui/panels/scenario_library_panel.dart
 D packages/map_editor/test/scenario_authoring_ux_test.dart
 D packages/map_editor/test/scenario_flow_diagnostics_test.dart
?? reports/lots/lot_58_ui_scenario_full_rollback/
```

## 14. Verdict final
Le rollback UI scénario dans `map_editor` est **réel et large**:
- la surcouche narrative UI récente a été retirée;
- la base est redevenue simple/minimale;
- la logique runtime utile n’a pas été touchée;
- la dette UI parasite a été réduite pour repartir sur une conception propre.
