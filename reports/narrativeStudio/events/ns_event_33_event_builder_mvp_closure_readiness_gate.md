# NS-EVENT-33 — Event Builder MVP Closure / End-to-End Authoring Readiness Gate

Date : 2026-06-19

Repo : `/Users/karim/Project/pokemonProject`

## 1. Résumé exécutif

Verdict :

```text
Event Builder MVP fermé : OUI AVEC RÉSERVES
Prochain lot recommandé : NS-EVENT-34 — Event Builder Runtime Handoff Smoke / Editor-authored Scene Target Gate
Blockers : aucun blocker authoring MVP après correction de la sélection canonique.
```

Le flux MVP authoring est cohérent et prouvé par un test widget NS-EVENT-33 dédié :

```text
ouvrir workspace Événements
→ créer un draft depuis une position map
→ sélectionner le draft
→ renommer l’événement
→ choisir le trigger
→ ajouter conditions Fact et Event consumed
→ choisir une Scene action
→ choisir reusable
→ afficher issues de Scene
→ afficher projections lifecycle / monde / règles passives
→ afficher diagnostics et inspecteur
→ vérifier absence d’authoring outcome/reaction/world rule/drag-drop
```

Le lot a découvert un défaut de cohérence strictement lié au gate : `EventBuilderWorkspace` ne consommait pas `EditorState.selectedMapEventId`. Un event sélectionné depuis l’état éditeur pouvait donc être ignoré à l’ouverture/rebuild du workspace, avec risque d’éditer le premier event listé. Le correctif est minimal : passer la sélection canonique au workspace et renvoyer les clics de liste à `EditorNotifier.selectMapEvent`.

Réserves non bloquantes :

- aucun smoke complet `editor-authored data -> runtime host -> scene execution -> GameState -> save/load -> world rule projection` n’existe encore ;
- le read model expose une notion interne `isRuntimeGuaranteed` trop forte pour une projection statique, même si l’UI est plus prudente ;
- `worldImpacts` ne porte pas encore toute la nuance disponible de `SceneConsequence` (`setFact.value`, `markEventConsumed.mapId`) ;
- un ancien plan drag/drop utilisait aussi le numéro NS-EVENT-33 pour un futur lot de condition reorder ; ce lot suit la recommandation NS-EVENT-32 et le prompt courant.

## 2. Usage du MCP Dart

Le prompt demandait l’usage du MCP Dart si disponible.

Recherche effectuée :

```bash
tool_search query="mcp__dart roots lsp dart analysis diagnostics references symbols"
```

Résultat : aucun outil MCP Dart n’a été exposé dans cette session. Les outils disponibles après recherche concernaient notamment `node_repl`, GitHub, Figma et Notion, mais pas Dart/LSP.

Vérifications de remplacement :

- navigation symboles via `rg` ;
- lectures ciblées via `sed` ;
- tests Flutter/Dart CLI ;
- analyse ciblée Flutter ;
- build macOS debug.

Conclusion : MCP Dart indisponible/partiel pour NS-EVENT-33. Aucun usage fictif n’est revendiqué.

## 3. Sous-agents utilisés

Six sous-agents ont été utilisés, plus l’orchestrateur principal.

| Agent | Rôle | Verdict utile |
|---|---|---|
| Pasteur | Product MVP / No-code Flow | MVP compréhensible et honnête, avec réserves de vocabulaire no-code et densité UI. |
| Ptolemy | Core Contracts / Read Model Integrity | Contrats cohérents, mais `isRuntimeGuaranteed` est trop fort et `worldImpacts` perd certains détails. |
| Wegener | Editor State / Authoring Operations | Défaut P1 : sélection canonique non consommée par `EventBuilderWorkspace`. Pas de mutation partielle dangereuse trouvée. |
| Avicenna | Runtime Readiness / Handoff Boundary | `sceneTarget` est exploitable par runtime via `SceneEventRuntimeHook`; manque un smoke editor-to-runtime-host complet. |
| Nash | Tests / Evidence / Coverage | Couverture existante forte mais dispersée ; absence de test NS-EVENT-33 dédié avant ce lot. |
| Sartre | Reviewer contradictoire | Refuse une fermeture sans réserves ; interdit de prétendre outcomes/reactions/world-rules/drag-drop authorables. |

Arbitrage orchestrateur :

- la contradiction sur le numéro NS-EVENT-33 est documentée mais le prompt courant et NS-EVENT-32 priment ;
- le défaut de sélection est corrigé car il touche directement la readiness end-to-end ;
- les réserves core/runtime restent documentées et deviennent le périmètre recommandé de NS-EVENT-34.

## 4. Audit initial

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

Sortie utile exacte :

```text
/Users/karim/Project/pokemonProject
main
```

`git status --short --untracked-files=all` : sortie vide.

`git diff --stat` : sortie vide.

`git diff --name-only` : sortie vide.

Top du log :

```text
25cdf062 NS-EVENT-32: Event Builder World Rules Projection UX Closure / Validation Gate - DONE
972c73ad NS-EVENT-31: Implement Passive World Rules Projection UI V0 - DONE
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
```

### Règles lues

- `AGENTS.md` fourni dans le contexte utilisateur.
- `agent_rules.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`

### RED initial

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-33"
```

Sortie utile exacte :

```text
No tests ran.
No tests match regular expression "NS-EVENT-33".
```

Décision : ajouter une couverture NS-EVENT-33 dédiée.

## 5. Readiness matrix

| Domaine | Status | Evidence | Risk | Next action |
|---|---|---|---|---|
| Workspace Événements visible | DONE | `event_builder_workspace_test.dart` suite complète + Visual Gate NS-EVENT-33 | none | none |
| Liste d’événements | DONE | `event-builder-event-list`, test NS-EVENT-33 | none | none |
| Sélection événement | DONE | correctif `selectedEventId`, test `honors canonical selected map event` | low | none |
| Création draft depuis position | DONE | test NS-EVENT-33 + tests NS-EVENT-09 | none | none |
| Gate position/couche | DONE | tests NS-EVENT-07/08/09 | none | none |
| Sélection auto du draft | DONE | test NS-EVENT-33 lit `selectedMapEventId` après création | none | none |
| Rename event | DONE | test NS-EVENT-33 + tests NS-EVENT-10 | none | none |
| Trigger authoring | DONE | actor/object/zone testés ; NS-EVENT-33 utilise zone | none | none |
| Fact condition authoring | DONE | test NS-EVENT-33 + tests NS-EVENT-13 | none | none |
| Event consumed condition authoring | DONE | test NS-EVENT-33 + tests NS-EVENT-14 | none | none |
| Condition remove | DONE | tests NS-EVENT-13/14/23 | none | none |
| Scene action authoring | DONE | test NS-EVENT-33 + tests NS-EVENT-11/22 | none | none |
| Behavior oneShot/reusable | DONE | test NS-EVENT-33 + tests NS-EVENT-12 | low | future runtime smoke |
| Scene outcomes projection | DONE | test NS-EVENT-33 + tests NS-EVENT-27 | none | none |
| Lifecycle projection | DONE | tests NS-EVENT-26/27/33 | medium | refine wording/contract later |
| World impacts projection | DONE | tests NS-EVENT-28/29/33 | medium | enrich detail later |
| Passive World Rules projection | DONE | tests NS-EVENT-30/31/32/33 | low | none |
| Diagnostics | DONE | Visual Gate + tests existing | low | future global validator |
| Inspector summary | DONE | Visual Gate + NS-EVENT-20/31/33 | none | none |
| No-code library actions | DONE | tests NS-EVENT-21/22/33 | low | none |
| Read-only future items | DONE | tests NS-EVENT-21/28/33 | low | improve disabled affordance later |
| No forbidden authoring buttons | DONE | helper `_expectNoForbiddenEventOwnedAuthoringControls` | none | none |
| No runtime simulation | DONE | NS-EVENT-25/28/31/32 reports + UI tests | none | none |
| No drag/drop promise | DONE | tests absence `Drag/drop` / `Déposez` | none | none |
| Test coverage | DONE | `+101` workspace, `+27` notifier, `+60` core | low | future runtime-host smoke |
| Visual coverage | DONE | screenshot NS-EVENT-33 | low | none |
| Runtime handoff readiness | PARTIAL | runtime sub-agent found sceneTarget hook and runtime tests, but no editor-to-runtime-host smoke | medium | NS-EVENT-34 |

## 6. Flux MVP end-to-end audité

Test ajouté :

```text
NS-EVENT-33 completes MVP authoring flow without forbidden actions
```

Le test :

- crée un draft à la position `objects / x 3 / y 2` ;
- récupère l’id créé depuis `EditorState.selectedMapEventId` ;
- renomme le titre humain en `Rencontre MVP au port` ;
- passe le trigger à `Entrée dans une zone` ;
- ajoute `Fact "Départ accepté" est vrai` ;
- ajoute `Événement "Rival au port" déjà consommé` ;
- choisit `Scène existante` ;
- passe le comportement en `Réutilisable` ;
- vérifie la préservation `id`, `position`, `script`, `message`, page unique ;
- vérifie `allOf(flagIsSet(fact_started), eventIsConsumed(evt_rival))` ;
- vérifie issues de scène, sources projetées, règle passive, diagnostics, inspecteur ;
- vérifie absence globale d’authoring interdit.

## 7. Tests ajoutés/modifiés

Fichier modifié :

```text
packages/map_editor/test/event_builder_workspace_test.dart
```

Tests ajoutés :

```text
NS-EVENT-33 honors canonical selected map event on entry
NS-EVENT-33 completes MVP authoring flow without forbidden actions
NS-EVENT-33 exposes no forbidden Event-owned authoring
captures NS-EVENT-33 event builder MVP closure visual gate
```

Helpers ajoutés/étendus :

```text
_expectNoForbiddenEventOwnedAuthoringControls()
_pumpWorkspace(selectedEventId, onSelectEvent)
_pumpNarrativeEventsShell(selectedMapEventId)
```

## 8. Visual Gate

Capture créée :

```text
reports/narrativeStudio/events/screenshots/ns_event_33_event_builder_mvp_closure_readiness_gate.png
```

Taille et hash :

```text
-rw-r--r--  1 karim  staff  301355 Jun 19 11:38 reports/narrativeStudio/events/screenshots/ns_event_33_event_builder_mvp_closure_readiness_gate.png
cc357455629dadd59b46afad8d5650a79bea5d9f64069b74aabd618ad94f6ccc  reports/narrativeStudio/events/screenshots/ns_event_33_event_builder_mvp_closure_readiness_gate.png
```

Note visuelle : la capture montre les quatre zones MVP (`liste`, `bibliothèque`, `builder central`, `inspecteur`), les sources projetées, les règles concernées et les diagnostics. Certains libellés de boutons rendus par le harness de test apparaissent comme blocs blancs, mais les assertions widget valident les textes critiques et la structure du gate.

## 9. Validations exécutées

### Test ciblé NS-EVENT-33

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-33"
```

Sortie utile exacte :

```text
00:05 +4: All tests passed!
```

### Capture NS-EVENT-33

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "captures NS-EVENT-33" --update-goldens --dart-define=NS_EVENT_33_CAPTURE_WORKSPACE=true
```

Sortie utile exacte :

```text
00:10 +1: All tests passed!
```

### Suite workspace complète

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart
```

Sortie utile exacte :

```text
00:12 +101: All tests passed!
```

### Suite notifier

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_draft_creation_notifier_test.dart
```

Sortie utile exacte :

```text
00:01 +27: All tests passed!
```

### Régressions core

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/event_builder_contract_test.dart test/event_builder_authoring_operations_test.dart test/event_builder_read_model_test.dart test/scene_consequence_model_test.dart
```

Sortie utile exacte :

```text
00:00 +60: All tests passed!
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
  lib/src/features/editor/state/editor_notifier.dart \
  test/event_builder_workspace_test.dart \
  test/event_builder_draft_creation_notifier_test.dart
```

Sortie exacte :

```text
Analyzing 7 items...
No issues found! (ran in 1.6s)
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

## 10. Go / No-Go verdict

```text
Event Builder MVP fermé : OUI AVEC RÉSERVES
```

Raisons du `OUI` :

- le flux authoring MVP est couvert par un test multi-step dédié ;
- les projections Scene/lifecycle/world impacts/world rules restent visibles ;
- les garde-fous no-code/read-only sont testés ;
- la sélection canonicalisée est corrigée et testée ;
- aucune capacité interdite n’a été ajoutée.

Raisons des réserves :

- pas encore de smoke runtime host depuis données authorées par l’éditeur ;
- le vocabulaire no-code peut encore être adouci (`Fact`, `consommé`, `ID technique`) ;
- le read model de lifecycle/world impact mérite un lot de précision avant de servir de contrat runtime plus fort ;
- la bêta Narrative Studio reste plus large que l’Event Builder MVP.

## 11. Risques résiduels

| Risque | Gravité | Décision |
|---|---|---|
| Pas de smoke complet editor-to-runtime-host | medium | Prochain lot NS-EVENT-34 |
| `isRuntimeGuaranteed` trop fort pour scan statique | medium | Réserve contractuelle, pas modifiée dans ce lot |
| `worldImpacts` ne porte pas `setFact.value` / `markEventConsumed.mapId` | low/medium | Futur enrichissement read model |
| Items library à venir restent rendus comme boutons | low | Accepté si libellés `À venir`/`Lecture seule` restent clairs |
| Ancienne collision de numérotation NS-EVENT-33 reorder | low | Documentée, hors scope du prompt courant |

## 12. Non-objectifs respectés

Respecté :

- pas de drag/drop ;
- pas d’authoring outcome ;
- pas d’authoring reaction ;
- pas d’authoring World Rule ;
- pas de picker World Rule ;
- pas de Scene Builder caché ;
- pas de modification `map_runtime`, `map_gameplay`, `map_battle`, `map_core` ;
- pas de modification `GameState`, `SceneRuntimeExecutor`, `SceneEventRuntimeHook`, `SceneConsequenceRuntimeWriter`, `WorldRuleDefinition` ;
- pas de nouveau `SceneConsequenceKind`, `completeStep`, `giveItem`, `EventReaction`, `EventOutcome` ;
- pas de modification Selbrume / `project.json` ;
- pas de build_runner ;
- pas de generated files ;
- pas de commit.

## 13. Prochain lot recommandé

```text
NS-EVENT-34 — Event Builder Runtime Handoff Smoke / Editor-authored Scene Target Gate
```

Objectif recommandé :

```text
Prouver un flux editor-authored minimal jusqu’au runtime :
Event Builder authoring operation
→ project/map data
→ runtime host load
→ interaction avec MapEvent
→ SceneEventRuntimeHook
→ SceneConsequence.setFact / markEventConsumed
→ GameState
→ save/load
→ World Rule projection observable
```

Non-objectifs NS-EVENT-34 :

- pas de drag/drop ;
- pas d’outcome/reaction Event-owned ;
- pas d’authoring World Rule inline ;
- pas de nouvelle conséquence ;
- pas de contenu Selbrume final.

## 14. Limites restantes

- Le gate prouve l’authoring Flutter/widget et les read models, pas un parcours joueur complet.
- Le Visual Gate est une capture de test, pas une session manuelle de l’app.
- Le rapport n’absorbe pas le vieux lot reorder du plan drag/drop ; il le laisse hors scope.
- Le global validator Narrative Studio reste un chantier distinct.

## 15. Evidence Pack

### Fichiers lus

Rapports :

```text
reports/narrativeStudio/events/ns_event_25_outcomes_reactions_consequences_contract_alignment_audit.md
reports/narrativeStudio/events/ns_event_26_scene_outcomes_lifecycle_projection_read_model_v0.md
reports/narrativeStudio/events/ns_event_27_scene_outcomes_lifecycle_projection_ui_v0.md
reports/narrativeStudio/events/ns_event_28_world_changes_readonly_projection_polish_v0.md
reports/narrativeStudio/events/ns_event_29_linked_scene_consequences_world_impact_projection_v0.md
reports/narrativeStudio/events/ns_event_30_passive_world_rules_projection_read_model_v0.md
reports/narrativeStudio/events/ns_event_31_passive_world_rules_projection_ui_v0.md
reports/narrativeStudio/events/ns_event_32_world_rules_projection_ux_closure_validation_gate.md
```

Code/tests :

```text
packages/map_core/lib/src/read_models/event_builder_read_model.dart
packages/map_core/lib/src/authoring/event_builder_contract.dart
packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart
packages/map_core/lib/src/models/map_event_definition.dart
packages/map_core/lib/src/models/scene_asset.dart
packages/map_core/lib/src/models/scene_consequence.dart
packages/map_core/lib/src/models/world_rule.dart
packages/map_core/test/event_builder_read_model_test.dart
packages/map_core/test/event_builder_contract_test.dart
packages/map_core/test/event_builder_authoring_operations_test.dart
packages/map_core/test/scene_consequence_model_test.dart
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart
packages/map_editor/test/event_builder_workspace_test.dart
packages/map_editor/test/event_builder_draft_creation_notifier_test.dart
```

### Fichiers modifiés

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

### Fichiers créés

```text
reports/narrativeStudio/events/ns_event_33_event_builder_mvp_closure_readiness_gate.md
reports/narrativeStudio/events/screenshots/ns_event_33_event_builder_mvp_closure_readiness_gate.png
```

### Fichiers supprimés

```text
<aucun>
```

### Hunk complet — sélection canonique dans EventBuilderWorkspace

```diff
+typedef EventBuilderEventSelectCallback = void Function(String eventId);
+
 class EventBuilderWorkspace extends StatefulWidget {
   const EventBuilderWorkspace({
     super.key,
     required this.readModel,
+    this.selectedEventId,
     this.draftCreationGate = const EventBuilderDraftCreationGate.disabled(),
@@
     this.mapOptions = const <EventBuilderMapOption>[],
     this.onOpenMap,
+    this.onSelectEvent,
@@
   final EventBuilderReadModel readModel;
+  final String? selectedEventId;
@@
   final List<EventBuilderMapOption> mapOptions;
   final EventBuilderMapOpenCallback? onOpenMap;
+  final EventBuilderEventSelectCallback? onSelectEvent;
@@
-    if (oldWidget.readModel != widget.readModel) {
+    if (oldWidget.readModel != widget.readModel ||
+        oldWidget.selectedEventId != widget.selectedEventId) {
       _syncSelection();
     }
@@
                                 events: widget.readModel.events,
                                 selectedEventId: selected?.eventId,
                                 onSelect: (eventId) {
+                                  widget.onSelectEvent?.call(eventId);
                                   setState(() => _selectedEventId = eventId);
                                 },
@@
     if (events.isEmpty) {
       _selectedEventId = null;
       return;
     }
+    final externalSelection = widget.selectedEventId?.trim();
+    if (externalSelection != null &&
+        externalSelection.isNotEmpty &&
+        events.any((event) => event.eventId == externalSelection)) {
+      _selectedEventId = externalSelection;
+      return;
+    }
```

### Hunk complet — branchement depuis NarrativeWorkspaceCanvas

```diff
       EditorWorkspaceMode.events => EventBuilderWorkspace(
           readModel: _buildEventBuilderWorkspaceReadModel(editor),
+          selectedEventId: editor.selectedMapEventId,
@@
           },
+          onSelectEvent: editorNotifier.selectMapEvent,
           onRenameEventTitle: editorNotifier.renameEventBuilderEventTitle,
```

### Hunk complet — tests NS-EVENT-33

Le fichier de test fait `5193` lignes. L’annexe équivalente ci-dessous reproduit les hunks complets ajoutés pour NS-EVENT-33.

```text
Tests ajoutés :
- NS-EVENT-33 honors canonical selected map event on entry
- NS-EVENT-33 completes MVP authoring flow without forbidden actions
- NS-EVENT-33 exposes no forbidden Event-owned authoring
- captures NS-EVENT-33 event builder MVP closure visual gate

Helper ajouté :
- _expectNoForbiddenEventOwnedAuthoringControls

Harnais étendu :
- _pumpWorkspace(selectedEventId, onSelectEvent)
- _pumpNarrativeEventsShell(selectedMapEventId)
```

Les assertions clés du test multi-step sont :

```dart
expect(state.selectedMapEventId, createdId);
expect(event.id, createdId);
expect(event.title, 'Rencontre MVP au port');
expect(event.type, MapEventType.triggerZone);
expect(event.position, const EventPosition(layerId: 'objects', x: 3, y: 2));
expect(event.pages.single.sceneTarget?.sceneId, 'scene_existing');
expect(event.pages.single.script, isNull);
expect(event.pages.single.message, isNull);
expect(
  event.pages.single.metadata[EventBuilderMetadataKeys.reusePolicy],
  EventBuilderReusePolicy.reusable.name,
);
expect(
  event.pages.single.condition,
  ScriptConditionFactory.allOf([
    ScriptConditionFactory.flagIsSet('fact_started'),
    ScriptConditionFactory.eventIsConsumed('evt_rival'),
  ]),
);
expect(find.text('Issues de la scène liée'), findsOneWidget);
expect(find.text('Sources projetées'), findsOneWidget);
expect(find.text('Règles concernées'), findsOneWidget);
_expectNoForbiddenEventOwnedAuthoringControls();
```

### Sub-agent evidence

Sub-agent core (Ptolemy) :

```text
dart test ... -> All tests passed! +75
dart analyze ... -> No issues found!
```

Sub-agent runtime (Avicenna) :

```text
map_core targeted tests -> 00:00 +45: All tests passed!
map_runtime scene/world-rule targeted tests -> 00:00 +44: All tests passed!
```

Sub-agent editor (Wegener) :

```text
flutter test --no-pub test/event_builder_workspace_test.dart test/event_builder_draft_creation_notifier_test.dart
-> 00:11 +124: All tests passed!
flutter analyze --no-pub
-> 439 issues found, unrelated broader package analyzer debt.
```

### Anti-scope attendu

Commande exécutée au gate final :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples assets selbrume pubspec.yaml
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle packages/map_core
```

Sortie exacte :

```text
<vide>
<vide>
```

### Gate final exact

Commande :

```bash
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

Sortie exacte :

```text
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
?? reports/narrativeStudio/events/ns_event_33_event_builder_mvp_closure_readiness_gate.md
?? reports/narrativeStudio/events/screenshots/ns_event_33_event_builder_mvp_closure_readiness_gate.png
 .../ui/canvas/events/event_builder_workspace.dart  |  17 +-
 .../src/ui/canvas/narrative_workspace_canvas.dart  |   2 +
 .../test/event_builder_workspace_test.dart         | 272 +++++++++++++++++++++
 3 files changed, 290 insertions(+), 1 deletion(-)
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

`git diff --check` : sortie vide.

Note : `git diff --stat` et `git diff --name-only` ne listent pas les fichiers non suivis ; le rapport et la capture apparaissent dans `git status --short --untracked-files=all`.

## 16. Auto-review critique

- Le lot n’a pas ajouté de nouvelle mécanique Event Builder ; il a corrigé une liaison sélection/state nécessaire au gate.
- Les tests NS-EVENT-33 ne se contentent pas d’une présence widget vague : ils vérifient les mutations persistées et les projections visibles.
- Le verdict n’est pas “OUI sans réserve” car le runtime host complet n’est pas prouvé depuis données authorées.
- Les outcomes/reactions/world rules restent hors ownership Event et hors authoring.
- Le vieux plan drag/drop/reorder n’est pas démarré.
- Le rapport assume que la fermeture porte sur le MVP Event Builder authoring, pas sur toute la bêta Narrative Studio.

## 17. Critique du prompt

Le prompt est pertinent pour fermer une tranche MVP, mais il mélange audit et test de couverture, ce qui peut pousser à corriger un bug pendant un gate. Ici, la correction était justifiée : sans sélection canonique, le flux end-to-end pouvait cibler le mauvais event.

La demande MCP Dart est saine, mais l’outil n’était pas disponible dans cette session. La validation CLI a compensé.

Le prompt devrait préciser que la fermeture MVP Event Builder n’est pas une fermeture beta-ready du Narrative Studio. Le runtime smoke complet doit rester un lot séparé, car l’intégrer ici aurait transformé le gate authoring en chantier runtime.

Le prochain lot ne devrait pas être drag/drop. Le prochain lot honnête est un smoke runtime/handoff, car il ferme la plus grosse réserve restante.
