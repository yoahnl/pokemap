# NS-EVENT-04 — Event Builder Workspace Shell + Read-only Event List V0

## 1. Résumé exécutif

Verdict : **NS-EVENT-04 DONE**.

Le Narrative Studio expose maintenant une entrée **Événements** et un workspace read-only alimenté par `buildEventBuilderReadModel(...)`.

Le workspace affiche :

- le titre `Événements` ;
- le sous-titre demandé ;
- un badge `Lecture seule` ;
- un empty state si la map active ne contient aucun event ;
- une liste d’événements triée par le read model ;
- les statuts `Actif`, `Brouillon`, `Inactif`, `Invalide` ;
- le déclencheur, l’action principale, le nombre de conditions et le nombre de diagnostics ;
- le message `conditionEditingLocked` pour les conditions legacy mixtes ;
- un panneau de détail read-only avec ID technique secondaire.

Aucune édition, sauvegarde, création, persistence ou logique runtime n’a été ajoutée.

## 2. UI ajoutée / modifiée

Fichier créé :

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`

Zones structurantes :

```dart
class EventBuilderWorkspace extends StatefulWidget {
  const EventBuilderWorkspace({
    super.key,
    required this.readModel,
  });

  final EventBuilderReadModel readModel;
}
```

Le widget reçoit uniquement un `EventBuilderReadModel`. Il ne lit pas les `MapEventPage`, `condition`, `sceneTarget`, `metadata`, `script` ou `message` legacy. La conversion métier reste côté `map_core`.

Surface principale :

```dart
return PokeMapPageSurface(
  key: const ValueKey('event-builder-workspace'),
  padding: const EdgeInsets.all(18),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Header no-code + badge lecture seule.
      // KPIs : total, diagnostics, portée map.
      // Empty state ou liste + détail.
    ],
  ),
);
```

Le panneau de détail utilise les sections déjà préparées par le read model :

```dart
_EventDetailsPanel(event: selected)
```

et affiche notamment :

- `event.trigger.label`
- `event.conditions`
- `event.mainAction`
- `event.behavior`
- `event.worldImpacts`
- `event.diagnostics`
- `event.conditionEditingMessage`

## 3. Intégration Narrative Studio

Fichiers modifiés :

- `packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart`
- `packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`
- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`

Mode ajouté :

```dart
enum EditorWorkspaceMode {
  // ...
  scenes,
  events,
  cutscene,
  dialogue,
  // ...
}
```

Navigation ajoutée :

```dart
void selectEventsWorkspace() {
  _openWorkspace(EditorWorkspaceMode.events);
}
```

Entrée sidebar Narrative Studio :

```dart
_SidebarItem(
  key: const ValueKey('narrative-studio-sidebar-events'),
  icon: CupertinoIcons.bolt_horizontal_circle,
  label: 'Événements',
  subtitle: 'Déclencheurs',
  selected: selectedMode == EditorWorkspaceMode.events,
  onTap: onSelectEvents,
)
```

Le top toolbar expose aussi un raccourci vers le workspace, mais aucun bouton d’édition d’événement n’a été ajouté.

## 4. Consommation du read model NS-EVENT-03

Le point d’intégration est dans `narrative_workspace_canvas.dart` :

```dart
EditorWorkspaceMode.events => EventBuilderWorkspace(
  readModel: _buildEventBuilderWorkspaceReadModel(editor),
),
```

L’adaptateur reste read-only et délègue l’analyse métier à `map_core` :

```dart
EventBuilderReadModel _buildEventBuilderWorkspaceReadModel(
  EditorState editor,
) {
  final project = editor.project;
  final activeMap = editor.activeMap;
  return buildEventBuilderReadModel(
    events: activeMap?.events ?? const <MapEventDefinition>[],
    mapId: activeMap?.id,
    mapTitle: activeMap?.name,
    sceneLabels: {
      for (final scene in project?.scenes ?? const <SceneAsset>[])
        scene.id: scene.name,
    },
    factLabels: {
      for (final fact
          in project?.facts ?? const <NarrativeFactDefinition>[])
        fact.id: fact.label,
    },
    eventLabels: {
      for (final event
          in activeMap?.events ?? const <MapEventDefinition>[])
        event.id: event.title.trim().isEmpty ? event.id : event.title,
    },
  );
}
```

Passe de contrôle :

```bash
rg -n "MapEventPage|sceneTarget|metadata|script|message" \
  packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart \
  packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
```

Résultat utile :

```text
event_builder_workspace.dart ne contient aucune lecture de MapEventPage / sceneTarget / metadata / script.
Les occurrences dans narrative_workspace_canvas.dart concernent d’autres surfaces narratives existantes, pas l’adaptateur Event Builder.
```

## 5. États affichés

Les statuts viennent de `EventBuilderEventStatus` :

| Read model | Badge UI |
|---|---|
| `active` | `Actif` |
| `draft` | `Brouillon` |
| `inactive` | `Inactif` |
| `invalid` | `Invalide` |

La Visual Gate montre les quatre états dans la liste.

## 6. Diagnostics affichés

Les diagnostics du read model sont affichés en no-code, avec sévérité visuelle :

- `Aucun diagnostic` si l’événement sélectionné est sain ;
- diagnostic warning/error si le read model en fournit ;
- le compteur de diagnostics est visible dans la liste.

Exemple testé :

```text
Action principale manquante
1 diagnostic
```

## 7. Condition legacy verrouillée

Le widget affiche `conditionEditingLocked` sans tenter de débloquer l’édition :

```text
Conditions verrouillées
Cette condition contient une partie avancée préservée. Elle ne peut pas être éditée partiellement.
Condition avancée préservée
```

Ce comportement respecte NS-EVENT-02-bis : la condition legacy mixte reste préservée, et le lot UI ne la modifie pas.

## 8. Empty states

Test couvert :

```text
Aucun événement sur cette map
Le Builder d’événements affichera ici les déclencheurs authorés depuis la carte active.
```

Le test vérifie aussi l’absence de boutons d’édition :

```text
Nouvel événement : absent
Sauvegarder : absent
```

## 9. Design system / tokens utilisés

Le nouveau widget utilise les primitives existantes :

- `PokeMapPageSurface`
- `PokeMapPanel`
- `PokeMapBadge`
- `PokeMapStatusTile`
- `PokeMapIconTile`
- `PokeMapCard`
- `PokeMapEmptyState`
- `PokeMapTone`
- `context.pokeMapColors`

Contrôle anti-couleurs hardcodées :

```bash
rg -n "Color\\(|Colors\\." \
  packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart \
  packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart \
  packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
```

Résultat utile :

```text
event_builder_workspace.dart:618:          color: toneColors.soft,
event_builder_workspace.dart:620:          border: Border.all(color: toneColors.border),
event_builder_workspace.dart:626:            Icon(CupertinoIcons.info_circle, size: 15, color: toneColors.icon),
```

Ces occurrences utilisent des couleurs de thème/tone, pas de `Color(0x...)` ou `Colors.*` dans la feature.

## 10. Tests ajoutés

Fichier créé :

- `packages/map_editor/test/event_builder_workspace_test.dart`

Tests ajoutés :

```text
NS-EVENT-04 shows a readable empty state
NS-EVENT-04 renders statuses and no-code details
captures NS-EVENT-04 workspace visual gate
```

Fichier modifié :

- `packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart`

Couverture ajoutée :

- l’entrée `Événements` apparaît dans la sidebar Narrative Studio ;
- le tap route vers `workspace:events` ;
- le workspace porte la key `event-builder-workspace`.

## 11. Visual Gate

Capture :

```text
reports/narrativeStudio/events/screenshots/ns_event_04_workspace_list_readonly_v0.png
```

Métadonnées :

```text
-rw-r--r--  1 karim  staff   154K Jun 17 01:44 reports/narrativeStudio/events/screenshots/ns_event_04_workspace_list_readonly_v0.png
reports/narrativeStudio/events/screenshots/ns_event_04_workspace_list_readonly_v0.png: PNG image data, 1280 x 820, 8-bit/color RGBA, non-interlaced
11c009b4cba6ed595324fea7316ded91c2ea1b7d04cc898860f2c4fd72fd6f33  reports/narrativeStudio/events/screenshots/ns_event_04_workspace_list_readonly_v0.png
```

La capture montre :

- header `Événements` ;
- badge `Lecture seule` ;
- KPIs total/diagnostics/portée ;
- liste read-only ;
- événements actif/brouillon/inactif/invalide ;
- diagnostic count ;
- conditions verrouillées ;
- panneau détail read-only.

## 12. Validations exécutées

### Gate 0

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 20
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
<git status initial vide>
<git diff --stat initial vide>
<git diff --name-only initial vide>
7eed36b2 FG-NS-EVENT-003: Ajout du read model et diagnostics pour le builder d'événements
93b655dd FG-NS-EVENT-002-BIS: Préservation des conditions legacy et corrections dans le builder d'événements
6279df74 Remove legacy Narrative Studio steps entry
f54a8243 FG-NS-EVENT-002: Ajout des contrats et opérations pour le builder d'événements (core + tests)
410be446 FG-NS-EVENT-001: Alignement des contrats existants pour le builder d'événements
7b3b2151 FG-NS-EVENT-001: Ajout du plan MVP v1 pour le builder d'événements Narrative Studio
05e70a57 NS-STUDIO-PRODUCT-BETA-READINESS — Audit de préparation pour la bêta de Narrative Studio
da9cce15 NS-SCENES-V1-138 — Selbrume Golden Slice Content Inventory Asset Gap Audit
80dd997a NS-SCENES-V1-137 — Narrative Studio Golden Slice Authoring Readiness Selbrume Demo Content Plan
703c5702 NS-SCENES-V1-136-BIS — Cinematic Builder Legacy Widget Expectations Cleanup
0f9c5cfe NS-SCENES-V1-136 — Cinematic Builder V1 Closure Readiness Audit
2bd11dda NS-SCENES-V1-135 — Cinematic Builder V1 Camera Closure Polish Gate
179cd6aa NS-SCENES-V1-134 — Cinematic Camera Geometry Preview UI V0
28d0e46e NS-SCENES-V1-133 — Cinematic Camera Geometry Playback State V0
d4e0b28b NS-SCENES-V1-132 — Cinematic Camera Target Zoom Editor UI V0
882c2c23 NS-SCENES-V1-131 — Cinematic Camera Target Zoom Core Model V0
a7bb9b42 update selbrume
4c3040a3 update selbrume
47660d78 NS-SCENES-V1-130 — Cinematic Camera Target Zoom Authoring Prep Contract
2344303e update selbrume
```

### RED

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart
```

Résultat initial :

```text
Échec attendu : Target of URI doesn't exist: package:map_editor/src/ui/canvas/events/event_builder_workspace.dart
Échec attendu : Method not found / type not found EventBuilderWorkspace
```

### GREEN widget / navigation

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Résultat final :

```text
00:09 +23: All tests passed!
```

### Visual Gate

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact --update-goldens --dart-define=NS_EVENT_04_CAPTURE_WORKSPACE=true test/event_builder_workspace_test.dart --name "captures NS-EVENT-04 workspace visual gate"
```

Résultat :

```text
00:02 +1: All tests passed!
```

### Core Event Builder

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/event_builder_contract_test.dart test/event_builder_authoring_operations_test.dart test/event_builder_read_model_test.dart
```

Résultat :

```text
00:00 +28: All tests passed!
```

### Analyse ciblée

Commande :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos \
  lib/src/ui/canvas/events/event_builder_workspace.dart \
  lib/src/ui/canvas/narrative_workspace_canvas.dart \
  lib/src/ui/canvas/narrative_studio_sidebar.dart \
  lib/src/ui/canvas/narrative_studio_shell.dart \
  lib/src/ui/canvas/editor_canvas_host.dart \
  lib/src/features/editor/state/models/editor_workspace_mode.dart \
  lib/src/features/editor/application/editor_workspace_controller.dart \
  lib/src/features/editor/state/editor_notifier.dart \
  lib/src/features/editor/state/editor_selectors.dart \
  lib/src/ui/editor_shell_page.dart \
  lib/src/ui/shared/top_toolbar.dart \
  lib/src/ui/panels/project_explorer_panel.dart \
  test/event_builder_workspace_test.dart \
  test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Résultat :

```text
Analyzing 14 items...
No issues found! (ran in 1.6s)
```

### Analyse globale map_editor

Commande :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos
```

Résultat :

```text
439 issues found.
```

État : dette préexistante hors lot. Les premières erreurs sont dans :

```text
lib/src/application/services/pokemon_sdk_move_catalog_converter.dart
lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart
```

Elles concernent des types/paramètres Pokémon SDK absents (`PokemonMoveAimedTarget`, `PokemonMoveFlags`, `fetchPokemonSdkStudioProjectPayload`, etc.) et ne proviennent pas des fichiers NS-EVENT-04.

### Build macOS debug

Commande :

```bash
cd packages/map_editor
flutter build macos --debug
```

Résultat :

```text
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 13. Non-objectifs respectés

Respecté :

- pas de `map_runtime` ;
- pas de `map_gameplay` ;
- pas de `map_battle` ;
- pas de `map_core` modifié ;
- pas de `GameState` ;
- pas de `SceneEventRuntimeHook` ;
- pas de `SceneConsequenceRuntimeWriter` ;
- pas de `EventAsset` ;
- pas de provider/repository/persistence ;
- pas d’édition d’event ;
- pas de bouton `Nouvel événement` fonctionnel ;
- pas de sauvegarde d’événement ;
- pas de modification Selbrume ;
- pas de fixture Selbrume ;
- pas de drag/drop ;
- pas de bibliothèque de blocs ;
- pas de flow editor complet ;
- pas de `build_runner` ;
- pas de commit.

## 14. Impact sur NS-EVENT-05

NS-EVENT-04 rend l’Event Builder visible plus tôt que le plan initial NS-EVENT-06, mais uniquement en lecture seule.

Conséquence recommandée :

- NS-EVENT-05 peut se concentrer sur les diagnostics manquants ou le détail read-only enrichi ;
- il ne doit pas encore introduire l’édition ;
- la prochaine étape utile est d’élargir la qualité des diagnostics et des labels avant d’ouvrir les commandes d’authoring.

## 15. Possibilité de grouper NS-EVENT-05 + NS-EVENT-06

Verdict : **grouper seulement si les deux restent read-only**.

Le plan historique décrit :

- NS-EVENT-05 : diagnostics Event Builder ;
- NS-EVENT-06 : workspace shell UI.

Comme NS-EVENT-04 a déjà absorbé le shell/list read-only, il reste raisonnable de fusionner un petit lot de diagnostics read-only avec un polish UI read-only.

Je déconseille de grouper si le prochain lot introduit :

- création d’événement ;
- édition de trigger ;
- édition de conditions ;
- édition de Scene action ;
- persistence ;
- runtime bridge ;
- drag/drop ;
- flow editor ;
- validator global.

Dans ces cas, il faut garder un lot séparé.

## 16. Evidence Pack complet

### Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `/Users/karim/.codex/skills/flutter-add-widget-test/SKILL.md`
- `reports/narrativeStudio/events/ns_event_builder_mvp_v1_lot_plan.md`
- `reports/narrativeStudio/events/ns_event_01_existing_surface_contract_alignment.md`
- `reports/narrativeStudio/events/ns_event_02_event_builder_core_contract_typed_authoring_bindings.md`
- `reports/narrativeStudio/events/ns_event_02_bis_mixed_legacy_condition_preservation.md`
- `reports/narrativeStudio/events/ns_event_03_event_builder_read_model_diagnostics_v0.md`
- fichiers UI Narrative Studio et shell listés plus haut.

### Fichiers créés

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`
- `reports/narrativeStudio/events/screenshots/ns_event_04_workspace_list_readonly_v0.png`
- `reports/narrativeStudio/events/ns_event_04_workspace_shell_event_list_readonly_v0.md`

### Fichiers modifiés

- `packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`
- `packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart`
- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- `packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart`

### Fichiers supprimés

Aucun.

### Diff stat avant rapport

```text
 .../application/editor_workspace_controller.dart   |  4 +++
 .../src/features/editor/state/editor_notifier.dart |  5 ++++
 .../features/editor/state/editor_selectors.dart    |  3 ++
 .../editor/state/models/editor_workspace_mode.dart |  1 +
 .../lib/src/ui/canvas/editor_canvas_host.dart      |  1 +
 .../lib/src/ui/canvas/narrative_studio_shell.dart  |  3 ++
 .../src/ui/canvas/narrative_studio_sidebar.dart    | 10 +++++++
 .../src/ui/canvas/narrative_workspace_canvas.dart  | 33 ++++++++++++++++++++++
 .../map_editor/lib/src/ui/editor_shell_page.dart   | 10 +++++++
 .../lib/src/ui/panels/project_explorer_panel.dart  |  4 +--
 .../map_editor/lib/src/ui/shared/top_toolbar.dart  |  9 ++++++
 .../narrative_overview_shell_navigation_test.dart  | 27 +++++++++++++++---
 12 files changed, 104 insertions(+), 6 deletions(-)
```

Les fichiers non suivis ne sont pas comptés par `git diff --stat`, mais ils sont listés dans `git status`.

### Gate final

Commande :

```bash
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

Sortie :

```text
 M packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
 M packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
 M packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
 M packages/map_editor/lib/src/ui/shared/top_toolbar.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
?? packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
?? packages/map_editor/test/event_builder_workspace_test.dart
?? reports/narrativeStudio/events/ns_event_04_workspace_shell_event_list_readonly_v0.md
?? reports/narrativeStudio/events/screenshots/ns_event_04_workspace_list_readonly_v0.png
 .../application/editor_workspace_controller.dart   |  4 +++
 .../src/features/editor/state/editor_notifier.dart |  5 ++++
 .../features/editor/state/editor_selectors.dart    |  3 ++
 .../editor/state/models/editor_workspace_mode.dart |  1 +
 .../lib/src/ui/canvas/editor_canvas_host.dart      |  1 +
 .../lib/src/ui/canvas/narrative_studio_shell.dart  |  3 ++
 .../src/ui/canvas/narrative_studio_sidebar.dart    | 10 +++++++
 .../src/ui/canvas/narrative_workspace_canvas.dart  | 33 ++++++++++++++++++++++
 .../map_editor/lib/src/ui/editor_shell_page.dart   | 10 +++++++
 .../lib/src/ui/panels/project_explorer_panel.dart  |  4 +--
 .../map_editor/lib/src/ui/shared/top_toolbar.dart  |  9 ++++++
 .../narrative_overview_shell_navigation_test.dart  | 27 +++++++++++++++---
 12 files changed, 104 insertions(+), 6 deletions(-)
packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/editor_shell_page.dart
packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
packages/map_editor/lib/src/ui/shared/top_toolbar.dart
packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
<git diff --check : sortie vide>
```

Commande anti-scope :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples assets selbrume pubspec.yaml
find reports/narrativeStudio/events/screenshots -maxdepth 1 -name '*ns_event_04*' -print
find reports/narrativeStudio/events/screenshots -maxdepth 1 -name '*ns_event_05*' -print
```

Sortie :

```text
<anti-scope packages/runtime/assets/selbrume/pubspec : sortie vide>
reports/narrativeStudio/events/screenshots/ns_event_04_workspace_list_readonly_v0.png
<screenshots ns_event_05 : sortie vide>
```

### Sub-agent / passes séparées

Sub-agent Audit / Architecture :

- verdict : architecture existante adaptée ;
- décision : ajouter `EditorWorkspaceMode.events`, brancher le shell Narrative Studio, créer un widget isolé alimenté par le read model.

Sub-agent Implémentation :

- verdict : workspace read-only livré ;
- décision : aucune logique métier dupliquée dans l’UI.

Sub-agent Tests :

- verdict : tests widget ciblés + navigation verts ;
- réserve : la première passe RED a bien échoué sur widget absent.

Sub-agent Build / Validation :

- verdict : build macOS debug OK, analyse ciblée OK, analyse globale bloquée par dette Pokémon SDK hors lot.

Sub-agent Critique finale :

- verdict : le scope reste strict ;
- correction effectuée : réduction du diff parasite dans `editor_shell_page.dart` après un reformat trop large.

## 17. Auto-review critique

Points solides :

- l’UI consomme `EventBuilderReadModel` ;
- les statuts et diagnostics sont visibles ;
- le verrou legacy est visible ;
- aucune commande d’édition n’est exposée ;
- la navigation Narrative Studio est branchée au bon niveau ;
- la Visual Gate est lisible et vérifiée.

Risques restants :

- le workspace ne groupe pas encore les events par map/zone comme l’image V1 cible ;
- le détail reste volontairement read-only et simple ;
- la liste utilise la map active uniquement ;
- l’analyse globale `map_editor` garde une dette hors lot sur Pokémon SDK ;
- le prochain lot devra éviter de transformer ce workspace en flow editor trop tôt.

Critique du prompt :

- le prompt est cohérent avec NS-EVENT-03 ;
- il mélange légèrement le shell visible et une partie du futur NS-EVENT-06 historique, mais cela reste acceptable parce que tout est read-only ;
- la Visual Gate automatisée est utile, mais nécessite le chargement explicite d’une police réelle pour produire une preuve humainement lisible ;
- la question NS-EVENT-05 + 06 doit être tranchée selon le scope réel du prochain prompt, pas par numéro seul.
