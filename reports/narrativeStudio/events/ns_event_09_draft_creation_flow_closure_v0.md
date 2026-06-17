# NS-EVENT-09 — Event Builder Draft Creation Flow Closure V0

## 1. Résumé exécutif

Verdict : `NS-EVENT-09 — DONE`.

Le flux de création de brouillon est fermé côté `map_editor` :

- position explicite choisie dans le workspace Événements ;
- couche active valide de type `ObjectLayer` ;
- clic `Nouvel événement` ;
- création réelle via `EditorNotifier.createEventBuilderDraftEventAt(...)` et `map_core.createEventBuilderDraftEventOnMap(...)` ;
- reconstruction du read model par `NarrativeWorkspaceCanvas` ;
- nouveau draft visible dans la liste ;
- nouveau draft sélectionné ;
- panneau détail affichant le draft ;
- statut `Brouillon` ;
- diagnostic `Action principale manquante` visible ;
- aucun bouton d’édition trigger/condition/action/scene exposé ;
- feedback utilisateur local visible ;
- position réinitialisée après succès pour éviter une double création involontaire sur la même cellule.

## 2. Scope confirmé

Scope exécuté : UI/state integration `map_editor` uniquement.

Non-objectifs respectés :

- pas d’édition de nom ;
- pas d’édition de trigger ;
- pas d’édition de conditions ;
- pas d’édition d’action Scene ;
- pas de picker Scene/Fact/Step ;
- pas de bibliothèque de blocs ;
- pas de flow editor ;
- pas de drag/drop ;
- pas de runtime/gameplay/battle/GameState ;
- pas de Selbrume/project.json ;
- pas de build_runner ;
- pas de commit.

## 3. Règles lues

Fichiers/règles lus avant modification :

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `skills/README.md`
- `superpowers:test-driven-development`
- `superpowers:verification-before-completion`

Note : `codex_rules.md` au pluriel n’a pas été utilisé ; le fichier repo attendu et présent est `codex_rule.md`.

## 4. Gate 0

Commandes initiales :

```bash
pwd
```

Sortie :

```text
/Users/karim/Project/pokemonProject
```

```bash
git branch --show-current
```

Sortie :

```text
main
```

```bash
git status --short --untracked-files=all
```

Sortie :

```text
```

```bash
git diff --stat
```

Sortie :

```text
```

```bash
git diff --name-only
```

Sortie :

```text
```

```bash
git log --oneline -n 20
```

Sortie :

```text
d3f1866f ns_event_08: Ajout du sélecteur de position explicite sur la carte pour la création de brouillon
30ae9429 ns_event_07: Ajout de l'entrée UI explicite pour la création de brouillon avec position
3bd06d2b ns_event_06: Ajout des opérations de création de brouillon pour l'éditeur d'événements
6fe430d9 ns_event_05: Polissage des détails en lecture seule et diagnostics
1a551f41 ns_event_04: Ajout de l'espace de travail pour l'éditeur d'événements en lecture seule
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
```

## 5. Audit du flux NS-EVENT-08

Fichiers audités :

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`
- `packages/map_editor/test/event_builder_draft_creation_notifier_test.dart`

Constats :

- `EventBuilderWorkspace` possédait déjà `_selectedDraftPosition`, la grille de position et un gate strict.
- `_createDraftAction` appelait déjà `EventBuilderDraftCreationGate.onCreateDraftAt`.
- `NarrativeWorkspaceCanvas._buildEventBuilderDraftCreationGate` passait déjà par `EditorNotifier.createEventBuilderDraftEventAt(position: position)`.
- `EditorNotifier.createEventBuilderDraftEventAt` vérifiait déjà map active, `layerId`, existence de la couche et type `ObjectLayer`.
- `EditorNotifier.createEventBuilderDraftEventAt` sélectionnait déjà le draft côté `EditorState.selectedMapEventId`.
- Le `statusMessage` était déjà écrit dans l’état : `Brouillon d’événement créé`.
- Le feedback status est visible via `EditorShellPage` en toast, mais le workspace n’avait pas de feedback local durable.
- La position choisie restait active dans le workspace après création, ce qui laissait un risque de double création au même endroit.
- Le workspace pouvait sélectionner l’ID retourné, mais aucun test ne prouvait le flux complet `NarrativeWorkspaceCanvas + EditorNotifier + read model reconstruit`.

Réponses aux questions obligatoires :

- Draft déjà sélectionné côté `EditorState` : oui, via `preferredSelectedMapEventId: result.createdEvent.id`.
- Workspace sélectionne réellement après reconstruction : oui après correction, prouvé par le test NS-EVENT-09 sur `NarrativeWorkspaceCanvas`.
- Feedback visible ou seulement stocké : avant NS-EVENT-09, stocké + toast shell ; après NS-EVENT-09, feedback local visible dans le workspace.
- Position reste active après création : avant NS-EVENT-09, oui ; après NS-EVENT-09, non.
- Risque de double création involontaire : avant NS-EVENT-09, oui ; après NS-EVENT-09, limité par reset de position et bouton rebloqué.

## 6. Décision post-création

Décision retenue : reset de la position après création réussie.

Raison :

- évite la double création involontaire sur la même cellule ;
- remet immédiatement le gate en état `Position requise` ;
- garde le flux explicite : chaque draft nécessite une position volontaire ;
- respecte le lot, sans introduire édition de contenu.

En cas d’échec, la position reste sélectionnée et un message d’erreur local indique de vérifier la position et la couche.

## 7. Fichiers modifiés et créés

Modifiés :

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

Créés :

- `reports/narrativeStudio/events/screenshots/ns_event_09_draft_creation_flow_closure_v0.png`
- `reports/narrativeStudio/events/ns_event_09_draft_creation_flow_closure_v0.md`

Supprimés : aucun.

## 8. Changements code principaux

### `event_builder_workspace.dart`

Zones modifiées :

- état local `_draftCreationFeedback` / `_draftCreationFeedbackTone` ;
- reset du feedback quand la position ou le contexte change ;
- reset de `_selectedDraftPosition` après création réussie ;
- feedback succès / échec ;
- empty state rendu scrollable pour éviter un overflow quand le gate affiche des messages ;
- wording de la liste : création de brouillon uniquement, édition verrouillée.

Hunk pertinent :

```diff
+  String? _draftCreationFeedback;
+  PokeMapTone _draftCreationFeedbackTone = PokeMapTone.success;
...
+          if (_draftCreationFeedback != null) ...[
+            const SizedBox(height: 12),
+            _DraftCreationFeedbackNotice(
+              message: _draftCreationFeedback!,
+              tone: _draftCreationFeedbackTone,
+            ),
+          ],
...
       if (eventId != null && eventId.trim().isNotEmpty) {
-        setState(() => _selectedEventId = eventId);
+        setState(() {
+          _selectedEventId = eventId;
+          _selectedDraftPosition = null;
+          _draftCreationFeedback =
+              'Brouillon d’événement créé. Sélectionnez une nouvelle position '
+              'pour en créer un autre.';
+          _draftCreationFeedbackTone = PokeMapTone.success;
+        });
+        return;
       }
+      setState(() {
+        _draftCreationFeedback =
+            'Impossible de créer le brouillon. Vérifiez la position et la '
+            'couche, puis réessayez.';
+        _draftCreationFeedbackTone = PokeMapTone.warning;
+      });
```

Nouveau widget ajouté :

```dart
class _DraftCreationFeedbackNotice extends StatelessWidget {
  const _DraftCreationFeedbackNotice({
    required this.message,
    required this.tone,
  });

  final String message;
  final PokeMapTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final toneColors = tone.resolve(context);
    return PokeMapPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            tone == PokeMapTone.success
                ? CupertinoIcons.checkmark_circle
                : CupertinoIcons.exclamationmark_triangle,
            color: toneColors.icon,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### `event_builder_workspace_test.dart`

Zones modifiées :

- imports Riverpod / EditorNotifier / EditorState / NarrativeWorkspaceCanvas ;
- test NS-EVENT-09 sur le flux proche production ;
- test de capture Visual Gate NS-EVENT-09 ;
- helper `_pumpNarrativeEventsShell` ;
- fixtures `_eventProject` et `_mapWithObjectLayer`.

Hunk principal :

```diff
+  testWidgets(
+      'NS-EVENT-09 creates a draft through the narrative workspace and resets position',
+      (tester) async {
+    final container = await _pumpNarrativeEventsShell(tester);
+    ...
+    await tester.tap(find.byKey(const ValueKey('event-builder-position-2-1')));
+    ...
+    await tester
+        .tap(find.byKey(const ValueKey('event-builder-new-event-button')));
+    ...
+    final state = container.read(editorNotifierProvider);
+    final events = state.activeMap!.events;
+    expect(events, hasLength(2));
+    final created = events.last;
+    expect(state.selectedMapEventId, created.id);
+    expect(state.statusMessage, 'Brouillon d’événement créé');
+    expect(created.title, 'Nouvel événement');
+    expect(created.pages.single.sceneTarget, isNull);
+    expect(created.pages.single.script, isNull);
+    expect(created.pages.single.message, isNull);
+    expect(created.pages.single.condition, isNull);
+    ...
+    expect(find.text('Position sélectionnée : aucune'), findsOneWidget);
+    expect(find.text('Position requise'), findsOneWidget);
+    expect(find.text('Ajouter une condition'), findsNothing);
+    expect(find.text('Ajouter une action'), findsNothing);
+    expect(find.text('Sauvegarder'), findsNothing);
+    ...
+    expect(
+        container.read(editorNotifierProvider).activeMap!.events, hasLength(2));
+  });
```

Le test prouve :

- création via `NarrativeWorkspaceCanvas` ;
- mutation `EditorNotifier` ;
- read model reconstruit ;
- draft visible/sélectionné ;
- détail affiché ;
- draft sans `sceneTarget`, `script`, `message`, `condition` ;
- position reset ;
- second clic sans nouvelle position ne crée pas de second event.

## 9. Test RED

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-09 creates a draft through the narrative workspace and resets position"
```

Sortie utile exacte :

```text
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Brouillon d’événement créé. Sélectionnez une
nouvelle position pour en créer un autre.": []>
   Which: means none were found but one was expected

The test description was:
  NS-EVENT-09 creates a draft through the narrative workspace and resets position
```

Interprétation : le test échouait bien sur le manque NS-EVENT-09 attendu : absence de feedback local post-création.

## 10. Tests GREEN et validations

### Test ciblé NS-EVENT-09

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-09 creates a draft through the narrative workspace and resets position"
```

Sortie :

```text
00:05 +1: All tests passed!
```

### Suite workspace Event Builder

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart
```

Sortie :

```text
00:04 +20: All tests passed!
```

Note : un premier passage de cette suite a révélé un overflow de l’état vide après ajout du feedback. Le correctif a rendu l’empty state scrollable dans son panneau, puis la suite complète est passée.

### Test notifier

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_draft_creation_notifier_test.dart
```

Sortie :

```text
00:02 +2: All tests passed!
```

### Tests core Event Builder

Commande :

```bash
cd packages/map_core
dart test --reporter=compact \
  test/event_builder_contract_test.dart \
  test/event_builder_authoring_operations_test.dart \
  test/event_builder_read_model_test.dart \
  test/event_builder_draft_creation_operations_test.dart
```

Sortie :

```text
00:00 +40: All tests passed!
```

### Analyse ciblée

Commande :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos \
  lib/src/ui/canvas/events/event_builder_workspace.dart \
  lib/src/ui/canvas/narrative_workspace_canvas.dart \
  lib/src/features/editor/state/editor_notifier.dart \
  test/event_builder_workspace_test.dart \
  test/event_builder_draft_creation_notifier_test.dart
```

Sortie :

```text
Analyzing 5 items...
No issues found! (ran in 1.8s)
```

### Build macOS debug

Commande :

```bash
cd packages/map_editor
flutter build macos --debug
```

Sortie :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

### Visual Gate

Commande :

```bash
cd packages/map_editor
flutter test --update-goldens --reporter=compact test/event_builder_workspace_test.dart --name "captures NS-EVENT-09 draft creation closure visual gate" -D NS_EVENT_09_CAPTURE_WORKSPACE=true
```

Sortie :

```text
00:13 +1: All tests passed!
```

Fichier :

```text
reports/narrativeStudio/events/screenshots/ns_event_09_draft_creation_flow_closure_v0.png
```

Preuves fichier :

```bash
ls -lh reports/narrativeStudio/events/screenshots/ns_event_09_draft_creation_flow_closure_v0.png
```

```text
-rw-r--r--  1 karim  staff   159K Jun 17 18:20 reports/narrativeStudio/events/screenshots/ns_event_09_draft_creation_flow_closure_v0.png
```

```bash
file reports/narrativeStudio/events/screenshots/ns_event_09_draft_creation_flow_closure_v0.png
```

```text
reports/narrativeStudio/events/screenshots/ns_event_09_draft_creation_flow_closure_v0.png: PNG image data, 1440 x 900, 8-bit/color RGBA, non-interlaced
```

```bash
shasum -a 256 reports/narrativeStudio/events/screenshots/ns_event_09_draft_creation_flow_closure_v0.png
```

```text
da191c46050f7c4316024f0efa4ff452a4cfd4e9b09be91d34000571e825d8ff  reports/narrativeStudio/events/screenshots/ns_event_09_draft_creation_flow_closure_v0.png
```

Observation Visual Gate : le PNG montre le draft `Nouvel événement`, son statut `Brouillon`, le détail sélectionné, le diagnostic `Action principale manquante`, le message de succès et le retour à `Position requise`. Quelques labels de boutons de la capture gardent un artefact de rendu de police propre au harness golden ; le flux et les libellés principaux restent lisibles.

## 11. Feedback utilisateur

Feedback local ajouté après succès :

```text
Brouillon d’événement créé. Sélectionnez une nouvelle position pour en créer un autre.
```

Feedback local ajouté après échec :

```text
Impossible de créer le brouillon. Vérifiez la position et la couche, puis réessayez.
```

Le `statusMessage` applicatif reste :

```text
Brouillon d’événement créé
```

## 12. Impact sur NS-EVENT-10

NS-EVENT-10 peut partir d’un flux de création stable :

- le draft existe dans la map active ;
- le draft est sélectionné ;
- la fiche détail se reconstruit sur le read model ;
- le statut/diagnostic de draft est visible ;
- le workspace reste fermé à l’édition du contenu.

Prochain lot probable : première édition no-code ciblée du draft, par exemple nom ou source/trigger, mais pas les deux si le lot veut rester petit.

## 13. Sub-agents / passes séparées

Sub-agent Audit / Architecture :

- verdict : OK ;
- preuve : flux `EventBuilderWorkspace` → `NarrativeWorkspaceCanvas` → `EditorNotifier` → `map_core` existant et cohérent ;
- risque trouvé : position non reset + feedback local absent.

Sub-agent Implémentation :

- verdict : OK ;
- modification minimale dans `event_builder_workspace.dart` ;
- pas de modification `map_core`, `map_runtime`, `map_gameplay`, `map_battle`, `Selbrume`.

Sub-agent Tests :

- verdict : OK ;
- test RED observé sur feedback local manquant ;
- GREEN sur test ciblé, suite workspace, notifier, core.

Sub-agent Build / Validation :

- verdict : OK ;
- analyse ciblée sans issue ;
- build macOS debug réussi ;
- Visual Gate générée.

Sub-agent Critique finale :

- verdict : OK avec réserve mineure ;
- réserve : la capture golden affiche encore quelques artefacts de police dans des labels de boutons, déjà visible dans ce type de harness ; cela ne bloque pas le lot car les preuves principales sont lisibles et les tests fonctionnels couvrent le flux.

## 14. Auto-review critique

Ce qui est prouvé :

- création par le vrai `EditorNotifier` depuis `NarrativeWorkspaceCanvas` ;
- mutation de `activeMap.events` ;
- sélection de `selectedMapEventId` ;
- reconstruction UI avec draft visible ;
- détail du draft affiché ;
- position reset après succès ;
- second clic sans nouvelle position ne crée pas de doublon ;
- aucun bouton d’édition condition/action/save n’est exposé ;
- tests core Event Builder inchangés et verts.

Ce qui n’est pas fait volontairement :

- édition de l’événement ;
- configuration de scène ;
- actions/conditions/réactions ;
- persistence disque ;
- runtime.

Risques restants :

- le feedback local est stocké dans l’état widget, donc il disparaît si le workspace est entièrement reconstruit ; le `statusMessage` global reste la source applicative durable.
- la Visual Gate est un harness golden, pas une capture d’une app manipulée manuellement.

## 15. Critique du prompt

Le prompt est cohérent avec l’état du repo et la continuité NS-EVENT-06 à 08.

Point adapté : le test complet via canvas réel a été fait avec `NarrativeWorkspaceCanvas` et un `ProviderContainer`, ce qui couvre mieux la production que le fallback `EventBuilderWorkspace callback`. Le notifier existant complète la preuve core de mutation.

Point à surveiller : demander “feedback visible” peut être interprété comme toast global ou message dans le workspace. Ce lot a choisi les deux niveaux : `statusMessage` conservé et feedback local ajouté.

## 16. Gate final

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
?? reports/narrativeStudio/events/ns_event_09_draft_creation_flow_closure_v0.md
?? reports/narrativeStudio/events/screenshots/ns_event_09_draft_creation_flow_closure_v0.png
```

```bash
git diff --stat
```

Sortie :

```text
 .../ui/canvas/events/event_builder_workspace.dart  | 107 ++++++++++--
 .../test/event_builder_workspace_test.dart         | 192 +++++++++++++++++++++
 2 files changed, 285 insertions(+), 14 deletions(-)
```

Note : `git diff --stat` ne liste que les fichiers suivis modifiés. Les deux nouveaux fichiers de rapport/capture apparaissent dans `git status --short --untracked-files=all`.

```bash
git diff --name-only
```

Sortie :

```text
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

```bash
git diff --check
```

Sortie :

```text
```

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle packages/map_core examples assets selbrume pubspec.yaml
```

Sortie :

```text
```
