# NS-EVENT-31 — Event Builder Passive World Rules Projection UI V0

## 1. Résumé exécutif

Verdict : **DONE**.

NS-EVENT-31 branche les `ProjectManifest.worldRules` dans le read model Event Builder et affiche `EventBuilderEventSummary.worldRules` dans l’UI `map_editor`.

Le lot reste strictement read-only :

- aucune modification `map_core` ;
- aucune modification runtime/gameplay/battle ;
- aucune simulation de règle du monde ;
- aucune application d’effet ;
- aucun authoring World Rule ;
- aucun bouton `Créer une règle monde`, `Ajouter une règle`, `Éditer règle` ;
- aucun drag/drop.

Comportement livré :

- le bloc `Changements du monde` affiche une sous-section `Règles du monde concernées` ;
- les états `noWorldImpacts`, `noMatchingRules`, `hasMatchingRules` sont rendus en wording no-code ;
- chaque règle projetée affiche son label, son statut activée/désactivée, sa condition observée, sa cible, son effet déclaré, sa raison, et les badges `Lecture seule` / `Projection passive` ;
- l’inspecteur droit affiche un résumé `Règles monde`.

## 2. Usage du MCP Dart

MCP Dart utilisé.

Symboles inspectés :

- `EventBuilderWorldRulesProjection` ;
- `EventBuilderWorldRulesProjectionStatus` ;
- `EventBuilderWorkspace` ;
- `_buildEventBuilderWorkspaceReadModel(...)` ;
- `EventBuilderInspectorPanel`.

Commandes MCP effectuées :

```text
mcp__dart.roots add:
file:///Users/karim/Project/pokemonProject/packages/map_editor
file:///Users/karim/Project/pokemonProject/packages/map_core
=> Success

mcp__dart.lsp resolveWorkspaceSymbol EventBuilderWorldRulesProjection
=> event_builder_read_model.dart lines 298-342
=> EventBuilderWorldRulesProjectionStatus lines 59-63

mcp__dart.lsp resolveWorkspaceSymbol EventBuilderWorkspace
=> narrative_workspace_canvas.dart _buildEventBuilderWorkspaceReadModel lines 655-682
=> event_builder_workspace.dart EventBuilderWorkspace lines 90-127

mcp__dart.lsp resolveWorkspaceSymbol EventBuilderInspectorPanel
=> event_builder_inspector_panel.dart lines 6-166

mcp__dart.analyze_files on:
lib/src/ui/canvas/events/event_builder_workspace.dart
lib/src/ui/canvas/events/event_builder_inspector_panel.dart
lib/src/ui/canvas/events/event_builder_element_library.dart
lib/src/ui/canvas/narrative_workspace_canvas.dart
test/event_builder_workspace_test.dart
=> No errors
```

Vérifications CLI complémentaires exécutées :

- tests widget ciblés ;
- suite complète `event_builder_workspace_test.dart` ;
- régression `map_core` read model ;
- analyse Flutter ciblée ;
- build macOS debug.

## 3. Sous-agents utilisés

Sous-agents obligatoires utilisés : 4 spécialistes + 1 reviewer contradictoire + orchestrateur principal.

### Sous-agent A — UI Structure / World Rules Block

Conclusion :

- afficher les règles projetées dans le bloc existant `Changements du monde` ;
- ne pas créer de top-level block séparé ;
- placer `Règles du monde concernées` après les impacts directs ;
- ne pas dupliquer `worldImpacts` ;
- corriger le wording qui laissait entendre que les impacts étaient déduits des règles du monde.

Décision appliquée :

- `_WorldImpactsProjectionBlock` reçoit maintenant `selected.worldRules` ;
- une sous-section `_WorldRulesProjectionBlock` est ajoutée après les impacts directs.

### Sous-agent B — Read Model Consumer / Data Binding

Conclusion :

- `project.worldRules` n’était pas passé à `buildEventBuilderReadModel(...)` ;
- le point de branchement correct est `_buildEventBuilderWorkspaceReadModel(...)` dans `narrative_workspace_canvas.dart` ;
- l’UI doit consommer `selected.worldRules`, pas recalculer les règles depuis `ProjectManifest`.

Décision appliquée :

```dart
worldRules: project?.worldRules ?? const <WorldRuleDefinition>[],
```

### Sous-agent C — UX No-code / Wording

Conclusion :

- utiliser un wording non simulateur : `potentiellement concernée`, `projection passive`, `lecture seule`, `condition observée`, `effet déclaré` ;
- éviter les promesses de type `sera active`, `effet appliqué`, `résultat garanti`.

Décision appliquée :

- le bloc affiche `Projection passive : le Builder liste les règles qui observent les mêmes sources. Il ne simule pas la partie et n’applique aucun effet.` ;
- les règles désactivées affichent `Ne produit pas d’effet tant qu’elle reste inactive.` ;
- les tests verrouillent l’absence de `Cette règle sera active` et `Effet appliqué`.

### Sous-agent D — Tests / Regression

Conclusion :

- ajouter des tests widget `NS-EVENT-31` ;
- couvrir le branchement `project.worldRules` ;
- couvrir les états `noWorldImpacts`, `noMatchingRules`, `hasMatchingRules` ;
- couvrir enabled/disabled, predicate, target, effect, read-only, projection passive ;
- conserver les régressions NS-EVENT-27/28.

Décision appliquée :

- 5 tests widget NS-EVENT-31 ajoutés ;
- 1 test de capture NS-EVENT-31 ajouté ;
- suite complète `event_builder_workspace_test.dart` exécutée.

### Sous-agent E — Reviewer contradictoire

Conclusion :

- rejeter toute modification `map_core` pour NS-EVENT-31 ;
- rejeter runtime/gameplay/battle ;
- rejeter World Rule simulation/application ;
- rejeter reuse des widgets d’authoring `WorldRuleTargetSection` ;
- alerter que les tests doivent injecter explicitement `worldRules` pour ne pas tomber sur le fallback `noWorldImpacts`.

Décision appliquée :

- aucun fichier `map_core` modifié ;
- aucun widget d’authoring World Rule réutilisé ;
- helpers de test dédiés `_readModelWithWorldRules(...)` et `_eventProjectWithWorldRules()` ajoutés.

### Arbitrage orchestrateur

Arbitrage retenu :

- affichage sous-section dans le bloc Monde ;
- data-binding par read model uniquement ;
- inspecteur synthétique seulement ;
- pas de calcul World Rule dans `map_editor` ;
- pas de changement de bibliothèque Monde hors test de non-régression.

## 4. Audit initial

### Gate 0

Commandes exécutées avant modification :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 20
```

Sorties utiles exactes :

```text
/Users/karim/Project/pokemonProject
main
git status --short --untracked-files=all => <vide>
git diff --stat => <vide>
git diff --name-only => <vide>

a1480aeb NS-EVENT-30: Implement Passive World Rules Projection Read Model V0
3502ca74 NS-EVENT-29: Implement Linked Scene Consequences World Impact Projection Read Model V0
906809bb NS-EVENT-28: Polish Event Builder World Changes Read-only Projection UI
e13ebb6e NS-EVENT-27: Implement Event Builder Scene Outcomes and Lifecycle Projection UI V0
b7fce79e NS-EVENT-26: Implement Event Builder Scene Outcomes and Lifecycle Projection Read Model V0
36a8f362 NS-EVENT-25: Add outcomes, reactions, and consequences contract alignment audit report
8c2bb4b2 ns_event_v1: Ajout des composants de l'éditeur d'événements et rapports associés
54c59fba ns_event_16: Consolidation de la disposition des blocs et disponibilité de la création d'activation de carte
8b3866a8 ns_event_15: Ajout de l'auteur des types de déclencheurs pour les événements
8a5996be ns_event_14: Ajout des conditions de consommation d'événements
7f490b9e ns_event_13: Ajout de l'auteur des conditions de fait pour les événements
26bec474 ns_event_12: Ajout de l'auteur des comportements pour les événements
00698aea ns_event_11: Ajout de l'auteur des actions de scène pour les événements
fc0e0be0 ns_event_10: Ajout de la saisie du titre pour les brouillons d'événements
cdedbe6e ns_event_09: Fermeture du flux de création de brouillon
d3f1866f ns_event_08: Ajout du sélecteur de position explicite sur la carte pour la création de brouillon
30ae9429 ns_event_07: Ajout de l'entrée UI explicite pour la création de brouillon avec position
3bd06d2b ns_event_06: Ajout des opérations de création de brouillon pour l'éditeur d'événements
6fe430d9 ns_event_05: Polissage des détails en lecture seule et diagnostics
1a551f41 ns_event_04: Ajout de l'espace de travail pour l'éditeur d'événements en lecture seule
```

### Fichiers lus

Règles et compétences :

- `AGENTS.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`

Rapports :

- `reports/narrativeStudio/events/ns_event_25_outcomes_reactions_consequences_contract_alignment_audit.md`
- `reports/narrativeStudio/events/ns_event_26_scene_outcomes_lifecycle_projection_read_model_v0.md`
- `reports/narrativeStudio/events/ns_event_27_scene_outcomes_lifecycle_projection_ui_v0.md`
- `reports/narrativeStudio/events/ns_event_28_world_changes_readonly_projection_polish_v0.md`
- `reports/narrativeStudio/events/ns_event_29_linked_scene_consequences_world_impact_projection_v0.md`
- `reports/narrativeStudio/events/ns_event_30_passive_world_rules_projection_read_model_v0.md`

Code :

- `packages/map_core/lib/src/read_models/event_builder_read_model.dart`
- `packages/map_core/lib/src/models/world_rule.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/test/event_builder_read_model_test.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

## 5. Décision UI World Rules

Décision :

```text
Afficher les World Rules comme sous-section read-only du bloc “Changements du monde”,
après les impacts directs.
```

Raison :

- `worldImpacts` sont les sources d’état projetées ;
- `worldRules` sont les règles qui observent ces sources ;
- les afficher ensemble donne une lecture logique sans créer un éditeur de règles.

États UI :

- `noWorldImpacts` : `Aucune source d’état projetée` ;
- `noMatchingRules` : `Aucune règle du monde liée` ;
- `hasMatchingRules` : liste des règles potentiellement concernées.

## 6. Décision no-simulation / wording

Wording livré :

- `Projection passive`
- `Lecture seule`
- `Condition observée`
- `Effet déclaré`
- `Règles du monde concernées`
- `Ne produit pas d’effet tant qu’elle reste inactive.`

Wording explicitement évité et testé :

- `Cette règle sera active`
- `Effet appliqué`
- `Créer une règle monde`
- `Ajouter une règle`
- `Éditer règle`
- `Drag/drop`

## 7. Branchement project.worldRules

Fichier modifié :

- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`

Section modifiée complète :

```dart
return buildEventBuilderReadModel(
  events: activeMap?.events ?? const <MapEventDefinition>[],
  mapId: activeMap?.id,
  mapTitle: activeMap?.name,
  sceneLabels: {
    for (final scene in project?.scenes ?? const <SceneAsset>[])
      scene.id: scene.name,
  },
  scenes: {
    for (final scene in project?.scenes ?? const <SceneAsset>[])
      scene.id: scene,
  },
  worldRules: project?.worldRules ?? const <WorldRuleDefinition>[],
  factLabels: {
    for (final fact in project?.facts ?? const <NarrativeFactDefinition>[])
      fact.id: fact.label.trim().isEmpty ? fact.id : fact.label.trim(),
  },
  eventLabels: {
    for (final event in activeMap?.events ?? const <MapEventDefinition>[])
      event.id: event.title.trim().isEmpty ? event.id : event.title,
  },
);
```

## 8. Modifications Event Builder

Fichiers modifiés :

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

Fichiers créés :

- `reports/narrativeStudio/events/screenshots/ns_event_31_passive_world_rules_projection_ui_v0.png`
- `reports/narrativeStudio/events/ns_event_31_passive_world_rules_projection_ui_v0.md`

Fichiers supprimés :

- aucun.

Diffs pertinents :

```diff
_WorldImpactsProjectionBlock(
  impacts: selected.worldImpacts,
+ worldRules: selected.worldRules,
)
```

```diff
+ worldRules: project?.worldRules ?? const <WorldRuleDefinition>[],
```

```diff
+ _InspectorLine(
+   label: 'Règles monde',
+   value: _worldRulesInspectorLabel(event.worldRules),
+ ),
```

Nouveau rendu principal :

```dart
class _WorldRulesProjectionBlock extends StatelessWidget {
  const _WorldRulesProjectionBlock({
    required this.projection,
  });

  final EventBuilderWorldRulesProjection projection;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Column(
      key: const ValueKey('event-builder-world-rules-projection'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Règles du monde concernées',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Projection passive : le Builder liste les règles qui observent les mêmes sources. Il ne simule pas la partie et n’applique aucun effet.',
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 9),
        switch (projection.status) {
          EventBuilderWorldRulesProjectionStatus.noWorldImpacts =>
            const _DiagnosticNotice(
              title: 'Aucune source d’état projetée',
              message:
                  'Aucune règle du monde ne peut être reliée tant qu’aucun changement d’état n’est visible.',
              tone: PokeMapTone.info,
              severityLabel: 'Lecture seule',
            ),
          EventBuilderWorldRulesProjectionStatus.noMatchingRules =>
            const _DiagnosticNotice(
              title: 'Aucune règle du monde liée',
              message:
                  'Aucune règle du monde ne lit les sources d’état affichées ci-dessus.\n'
                  'Ce n’est pas une erreur.',
              tone: PokeMapTone.info,
              severityLabel: 'Projection passive',
            ),
          EventBuilderWorldRulesProjectionStatus.hasMatchingRules => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  projection.label,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                for (final rule in projection.rules)
                  _WorldRuleProjectionRow(rule: rule),
              ],
            ),
        },
      ],
    );
  }
}
```

## 9. Tests ajoutés/modifiés

Tests NS-EVENT-31 ajoutés :

- `NS-EVENT-31 passes project world rules into read model`
- `NS-EVENT-31 renders no world impacts state`
- `NS-EVENT-31 renders no matching world rules state`
- `NS-EVENT-31 renders passive world rules without simulation`
- `NS-EVENT-31 updates inspector world rules summary`
- `captures NS-EVENT-31 passive world rules visual gate`

Helpers ajoutés :

- `_readModelWithWorldRules(...)`
- `_eventProjectWithWorldRules()`
- `_eventSceneWithSetFact(...)`

## 10. Visual Gate

Capture créée :

```text
reports/narrativeStudio/events/screenshots/ns_event_31_passive_world_rules_projection_ui_v0.png
```

Taille et hash :

```text
-rw-r--r--  1 karim  staff  267400 Jun 19 01:53 reports/narrativeStudio/events/screenshots/ns_event_31_passive_world_rules_projection_ui_v0.png
b58398c018694206e2a6d461fc9a4a915aed562f2764437de88690eb85a362eb  reports/narrativeStudio/events/screenshots/ns_event_31_passive_world_rules_projection_ui_v0.png
```

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact --update-goldens --dart-define=NS_EVENT_31_CAPTURE_WORKSPACE=true test/event_builder_workspace_test.dart --name "captures NS-EVENT-31"
```

Sortie utile exacte :

```text
00:10 +0: captures NS-EVENT-31 passive world rules visual gate
00:11 +1: captures NS-EVENT-31 passive world rules visual gate
00:11 +1: All tests passed!
```

## 11. Validations exécutées

### RED initial

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-31"
```

Sortie utile exacte :

```text
NS-EVENT-31 passes project world rules into read model [E]
Bad state: No element

NS-EVENT-31 renders no world impacts state [E]
Expected: exactly one matching candidate
Actual: Found 0 widgets with text "Règles du monde concernées"

NS-EVENT-31 renders no matching world rules state [E]
Expected: exactly one matching candidate
Actual: Found 0 widgets with text "Règles du monde concernées"

NS-EVENT-31 renders passive world rules without simulation [E]
Expected: at least one matching candidate
Actual: Found 0 widgets with text "2 règle(s) du monde potentiellement concernée(s)."

NS-EVENT-31 updates inspector world rules summary [E]
Expected: exactly one matching candidate
Actual: Found 0 widgets with text "Règles monde"
```

### GREEN ciblé

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-31"
```

Sortie utile exacte :

```text
00:02 +0: NS-EVENT-31 passes project world rules into read model
00:03 +1: NS-EVENT-31 passes project world rules into read model
00:03 +1: NS-EVENT-31 renders no world impacts state
00:04 +2: NS-EVENT-31 renders no world impacts state
00:04 +2: NS-EVENT-31 renders no matching world rules state
00:04 +3: NS-EVENT-31 renders no matching world rules state
00:04 +3: NS-EVENT-31 renders passive world rules without simulation
00:04 +4: NS-EVENT-31 renders passive world rules without simulation
00:04 +4: NS-EVENT-31 updates inspector world rules summary
00:04 +5: NS-EVENT-31 updates inspector world rules summary
00:04 +5: captures NS-EVENT-31 passive world rules visual gate
00:04 +6: captures NS-EVENT-31 passive world rules visual gate
00:04 +6: All tests passed!
```

### Suite widget complète

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart
```

Sortie utile exacte :

```text
00:12 +65: NS-EVENT-31 passes project world rules into read model
00:12 +66: NS-EVENT-31 passes project world rules into read model
00:12 +66: NS-EVENT-31 renders no world impacts state
00:12 +67: NS-EVENT-31 renders no world impacts state
00:12 +67: NS-EVENT-31 renders no matching world rules state
00:12 +68: NS-EVENT-31 renders no matching world rules state
00:12 +68: NS-EVENT-31 renders passive world rules without simulation
00:12 +69: NS-EVENT-31 renders passive world rules without simulation
00:12 +69: NS-EVENT-31 updates inspector world rules summary
00:12 +70: NS-EVENT-31 updates inspector world rules summary
00:12 +72: captures NS-EVENT-31 passive world rules visual gate
00:12 +73: captures NS-EVENT-31 passive world rules visual gate
00:12 +92: All tests passed!
```

### Régression core

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/event_builder_read_model_test.dart
```

Sortie utile exacte :

```text
00:00 +25: Event Builder read model projects matching fact world rules without evaluating predicate
00:00 +26: Event Builder read model projects matching fact world rules without evaluating predicate
00:00 +26: Event Builder read model projects consumed event world rules including disabled rules
00:00 +27: Event Builder read model projects consumed event world rules including disabled rules
00:00 +27: Event Builder read model does not project non matching world rules
00:00 +28: Event Builder read model does not project non matching world rules
00:00 +28: Event Builder read model orders projected world rules by impacts then world rule order
00:00 +29: Event Builder read model orders projected world rules by impacts then world rule order
00:00 +29: Event Builder read model reports no world rule projection when there is no world impact
00:00 +30: Event Builder read model reports no world rule projection when there is no world impact
00:00 +34: All tests passed!
```

### Analyse ciblée

Commande :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos \
  lib/src/ui/canvas/events/event_builder_workspace.dart \
  lib/src/ui/canvas/events/event_builder_inspector_panel.dart \
  lib/src/ui/canvas/events/event_builder_element_library.dart \
  lib/src/ui/canvas/narrative_workspace_canvas.dart \
  test/event_builder_workspace_test.dart
```

Sortie exacte :

```text
Analyzing 5 items...
No issues found! (ran in 1.9s)
```

### Build macOS debug

Commande :

```bash
cd packages/map_editor
flutter build macos --debug
```

Sortie utile exacte :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

### Format

Commande :

```bash
dart format packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart packages/map_editor/test/event_builder_workspace_test.dart
```

Sortie exacte :

```text
Formatted 4 files (0 changed) in 0.11 seconds.
```

## 12. Non-objectifs respectés

Respecté :

- pas de modification `map_core` ;
- pas de modification `map_runtime` ;
- pas de modification `map_gameplay` ;
- pas de modification `map_battle` ;
- pas de modification `GameState` ;
- pas de modification `WorldRuleDefinition` ;
- pas de simulation de World Rules ;
- pas d’application de `WorldRuleEffect` ;
- pas d’authoring World Rule ;
- pas de bouton création/édition World Rule ;
- pas de drag/drop ;
- pas de modification Selbrume ;
- pas de `build_runner` ;
- pas de fichiers générés modifiés ;
- pas de commit.

## 13. Impact sur NS-EVENT-32

NS-EVENT-32 peut partir d’un Event Builder qui affiche maintenant :

- impacts directs ;
- règles du monde qui observent les sources projetées ;
- états vides propres ;
- résumé inspecteur.

Prochain lot recommandé :

```text
NS-EVENT-32 — Event Builder World Rules Projection UX Closure / Validation Gate
```

Objectif probable :

- fermer la cohérence UX de la projection Monde ;
- vérifier no-code wording global ;
- couvrir edge cases d’affichage dense ;
- décider si la bibliothèque Monde doit rester read-only ou pointer vers le workspace Règles du monde.

Ne pas démarrer NS-EVENT-32 dans ce lot.

## 14. Limites restantes

- L’UI affiche ce que le read model projette ; elle ne sait pas calculer une règle non fournie par `map_core`.
- Les World Rules restent passives : aucun effet n’est appliqué ni simulé.
- Les catégories futures `completeStep`, item, money, quest unlock ne sont pas affichées tant que le read model ne les expose pas.
- La capture montre les règles dans la zone centrale ; l’inspecteur conserve volontairement un résumé court.

## 15. Evidence Pack

### Fichiers modifiés

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

### Fichiers créés

```text
reports/narrativeStudio/events/screenshots/ns_event_31_passive_world_rules_projection_ui_v0.png
reports/narrativeStudio/events/ns_event_31_passive_world_rules_projection_ui_v0.md
```

### Statut git avant rapport final

```text
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
?? reports/narrativeStudio/events/screenshots/ns_event_31_passive_world_rules_projection_ui_v0.png
```

### Diff stat avant rapport final

```text
 .../events/event_builder_inspector_panel.dart      |  15 +
 .../ui/canvas/events/event_builder_workspace.dart  | 231 +++++++++++-
 .../src/ui/canvas/narrative_workspace_canvas.dart  |   1 +
 .../test/event_builder_workspace_test.dart         | 408 +++++++++++++++++++++
 4 files changed, 654 insertions(+), 1 deletion(-)
```

### git diff --check

Commande :

```bash
git diff --check
```

Sortie exacte :

```text
<vide>
```

### Anti-scope attendu

Commande exécutée après écriture du rapport :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle packages/map_core examples assets selbrume pubspec.yaml
```

Résultat exact :

```text
<vide>
```

### Gate final après création du rapport

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
?? reports/narrativeStudio/events/ns_event_31_passive_world_rules_projection_ui_v0.md
?? reports/narrativeStudio/events/screenshots/ns_event_31_passive_world_rules_projection_ui_v0.png
```

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
 .../events/event_builder_inspector_panel.dart      |  15 +
 .../ui/canvas/events/event_builder_workspace.dart  | 231 +++++++++++-
 .../src/ui/canvas/narrative_workspace_canvas.dart  |   1 +
 .../test/event_builder_workspace_test.dart         | 408 +++++++++++++++++++++
 4 files changed, 654 insertions(+), 1 deletion(-)
```

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

Commande :

```bash
git diff --check
```

Sortie exacte :

```text
<vide>
```

## 16. Auto-review critique

Checklist indépendante :

- le lot reste UI read-only : oui ;
- `ProjectManifest.worldRules` est passé au read model : oui ;
- l’UI consomme `selected.worldRules` : oui ;
- l’UI ne recalcule pas les World Rules : oui ;
- noWorldImpacts est explicite : oui ;
- noMatchingRules est explicite : oui ;
- hasMatchingRules affiche enabled/disabled, predicate, cible, effet, raison : oui ;
- le wording ne promet ni activation ni effet appliqué : oui, tests dédiés ;
- aucun bouton authoring World Rule : oui, tests dédiés ;
- aucun drag/drop : oui, tests dédiés ;
- aucun `map_core` modifié : oui ;
- Visual Gate créée : oui ;
- tests/analyse/build verts : oui.

Risque restant :

- le bloc Monde contient désormais plus de contenu vertical. C’est cohérent avec la direction V0/V1, mais un futur lot UX pourra densifier ou replier les règles si le nombre de règles devient élevé.

## 17. Critique du prompt

Le prompt est cohérent avec NS-EVENT-30 et protège bien la frontière produit.

Point dur :

- il demande un usage MCP Dart, sous-agents, tests complets, analyse, build, Visual Gate et rapport détaillé pour une modification UI relativement bornée. C’est lourd mais utile ici, car le risque principal était de glisser vers de l’authoring ou de la simulation World Rule.

Point à clarifier plus tard :

- le prochain lot devrait éviter d’ajouter encore plus de texte au bloc Monde sans traiter la densité visuelle. La projection passive est maintenant lisible, mais un grand projet avec beaucoup de règles aura besoin d’un compactage ou d’un filtre read-only.

Décision finale :

```text
NS-EVENT-31 — DONE
NS-EVENT-32 — recommandé, non démarré
```
