# NS-EVENT-10 — Event Builder Draft Title Authoring V0

## 1. Résumé exécutif

NS-EVENT-10 ajoute la première édition no-code minimale d’un événement dans le workspace Événements : renommer le titre humain d’un event sélectionné.

Verdict : DONE côté implémentation et validations ciblées.

Ce qui est livré :
- le titre humain `MapEventDefinition.title` est éditable depuis le panneau détail ;
- l’ID technique `MapEventDefinition.id` n’est jamais éditable ni régénéré ;
- le renommage trim le titre, refuse le vide et conserve pages, position, type, metadata, `sceneTarget`, `script`, `message` et `condition` ;
- la liste et le détail affichent le nouveau `displayName` ;
- un feedback no-code confirme le succès ;
- une Visual Gate NS-EVENT-10 a été générée.

## 2. Décision : titre éditable, ID non éditable

Décision retenue :
- exposer uniquement le champ `Titre de l’événement` ;
- garder l’ID dans `Informations techniques` et sous le titre comme information secondaire ;
- ne pas ajouter de champ ID ;
- ne pas déclencher de slug/regeneration ;
- ne pas ouvrir conditions/actions/scène/comportement.

Le titre humain devient donc la première surface d’authoring, tandis que l’ID reste un invariant technique.

## 3. Audit initial

Gate 0 :

```bash
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
<vide>

git diff --stat
<vide>

git diff --name-only
<vide>

git log --oneline -n 20
cdedbe6e ns_event_09: Fermeture du flux de création de brouillon
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
```

Fichiers lus :
- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `skills/systematic-debugging/SKILL.md`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_core/lib/src/operations/map_events.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`
- `packages/map_editor/test/event_builder_draft_creation_notifier_test.dart`

Risques identifiés :
- ne pas confondre titre humain et ID technique ;
- éviter une mutation cachée des pages ou du `sceneTarget` ;
- ne pas ouvrir un éditeur conditions/actions/scène dans ce lot ;
- conserver la validation map/projet existante ;
- éviter les fixtures invalides qui donnent de faux négatifs.

## 4. Verdict des passes / sub-agents

Sub-agent Audit / Architecture :
- Verdict : OK.
- Le repo dispose déjà de `updateMapEventOnMap(...)`, qui met à jour le titre sans imposer de changement d’ID.
- L’UI Event Builder est encore volontairement bornée ; le bon point d’entrée est le panneau détail existant.

Sub-agent Implémentation :
- Verdict : OK.
- Ajout minimal dans `EditorNotifier` + callback vers `EventBuilderWorkspace`.
- Aucun fichier runtime/gameplay/battle/core/Selbrume modifié.

Sub-agent Tests :
- Verdict : OK.
- Tests RED ajoutés avant le code ; GREEN obtenu après correction du notifier et des fixtures.

Sub-agent Build / Validation :
- Verdict : OK.
- Tests ciblés, tests complets demandés, analyse ciblée et build macOS debug exécutés.

Sub-agent Critique finale :
- Verdict : OK avec réserve mineure.
- La sélection locale du workspace et la sélection globale `selectedMapEventId` restent séparées tant qu’aucune mutation notifier n’est lancée. Le test UI de titre vide vérifie donc la non-mutation locale, tandis que les tests state vérifient la préservation de sélection côté notifier.

## 5. Opération notifier ajoutée

Fichier : `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`

Zone ajoutée :

```dart
  bool renameEventBuilderEventTitle({
    required String eventId,
    required String title,
  }) {
    final map = state.activeMap;
    if (map == null) {
      state = state.copyWith(
        errorMessage: 'Aucune map active pour renommer l’événement.',
      );
      return false;
    }
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      state = state.copyWith(errorMessage: 'Titre d’événement obligatoire.');
      return false;
    }
    final event = findMapEventById(map, eventId);
    if (event == null) {
      state = state.copyWith(errorMessage: 'Événement introuvable : $eventId');
      return false;
    }
    if (event.title.trim() == trimmedTitle) {
      return true;
    }

    try {
      final updated = updateMapEventOnMap(
        map,
        eventId: eventId,
        title: trimmedTitle,
      );
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: eventId,
        statusMessage: 'Événement renommé',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de renommer l’événement : $e',
      );
      return false;
    }
  }
```

Impact attendu :
- `MapEventDefinition.title` est modifié ;
- `MapEventDefinition.id` est conservé ;
- `selectedMapEventId` reste l’event renommé après mutation ;
- l’état expose `statusMessage: Événement renommé`.

## 6. UI titre ajoutée

Fichier : `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`

Zones ajoutées :

```dart
typedef EventBuilderTitleRenameCallback = bool Function({
  required String eventId,
  required String title,
});
```

```dart
class EventBuilderWorkspace extends StatefulWidget {
  const EventBuilderWorkspace({
    super.key,
    required this.readModel,
    this.draftCreationGate = const EventBuilderDraftCreationGate.disabled(),
    this.onRenameEventTitle,
  });

  final EventBuilderReadModel readModel;
  final EventBuilderDraftCreationGate draftCreationGate;
  final EventBuilderTitleRenameCallback? onRenameEventTitle;
```

Le panneau détail est passé en `StatefulWidget` pour porter uniquement l’état local d’édition du titre :

```dart
class _EventDetailsPanelState extends State<_EventDetailsPanel> {
  late final TextEditingController _titleController;
  bool _isEditingTitle = false;
  String? _titleError;
  String? _titleFeedback;
```

Bloc édition titre :

```dart
          CupertinoTextField(
            key: const ValueKey('event-builder-title-field'),
            controller: _titleController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveTitle(selected),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            placeholder: 'Titre de l’événement',
            placeholderStyle: TextStyle(
              color: colors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.controlSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _titleError == null
                    ? colors.borderSubtle
                    : colors.errorBorder,
              ),
            ),
          ),
```

Sauvegarde bornée :

```dart
  void _saveTitle(EventBuilderEventSummary selected) {
    final trimmedTitle = _titleController.text.trim();
    if (trimmedTitle.isEmpty) {
      setState(() {
        _titleError = 'Le titre est obligatoire.';
        _titleFeedback = null;
      });
      return;
    }
    if (trimmedTitle == selected.displayName.trim()) {
      setState(() {
        _isEditingTitle = false;
        _titleError = null;
        _titleFeedback = null;
        _titleController.text = selected.displayName;
      });
      return;
    }
    final renamed = widget.onRenameTitle?.call(
          eventId: selected.eventId,
          title: trimmedTitle,
        ) ??
        false;
    if (!renamed) {
      setState(() {
        _titleError = 'Impossible de renommer cet événement.';
        _titleFeedback = null;
      });
      return;
    }
    setState(() {
      _isEditingTitle = false;
      _titleError = null;
      _titleFeedback = 'Titre mis à jour.';
      _titleController.text = trimmedTitle;
    });
  }
```

L’ID technique reste affiché via `_TechnicalIdHint` et n’est pas éditable.

## 7. Wiring workspace

Fichier : `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`

Zone modifiée :

```dart
      EditorWorkspaceMode.events => EventBuilderWorkspace(
          readModel: _buildEventBuilderWorkspaceReadModel(editor),
          draftCreationGate: _buildEventBuilderDraftCreationGate(
            editor,
            editorNotifier,
          ),
          onRenameEventTitle: editorNotifier.renameEventBuilderEventTitle,
        ),
```

## 8. Comportement validation / annulation

Validation :
- trim du titre ;
- refus local UI si vide ;
- refus notifier si vide ;
- refus notifier si event introuvable ;
- mutation via `updateMapEventOnMap(...)` ;
- validation via `MapValidator.validate(...)`.

Annulation :
- ferme le mode édition ;
- restaure le titre courant dans le champ ;
- ne modifie pas l’event.

Aucun contrôle ajouté :
- `Ajouter une condition` ;
- `Ajouter une action` ;
- `Choisir une scène` ;
- `Sauvegarder`.

## 9. Tests ajoutés / modifiés

Fichier : `packages/map_editor/test/event_builder_draft_creation_notifier_test.dart`

Tests NS-EVENT-10 ajoutés :
- `renames the human title without changing the technical id or page`
- `rejects an empty title without mutating the event`
- `rejects an unknown event without mutating the map`

Extrait de garde-fous :

```dart
      expect(event.id, 'evt_existing');
      expect(event.title, 'Rencontre rival au port');
      expect(event.position, original.position);
      expect(event.type, original.type);
      expect(event.metadata, original.metadata);
      expect(event.pages, hasLength(1));
      expect(event.pages.single.sceneTarget, originalPage.sceneTarget);
      expect(event.pages.single.script, originalPage.script);
      expect(event.pages.single.message, originalPage.message);
      expect(event.pages.single.condition, originalPage.condition);
      expect(state.selectedMapEventId, 'evt_existing');
      expect(state.statusMessage, 'Événement renommé');
```

Fichier : `packages/map_editor/test/event_builder_workspace_test.dart`

Tests NS-EVENT-10 ajoutés :
- `renames the selected event title without changing id`
- `canceling title edit keeps event unchanged`
- `empty title is refused in the details panel`
- `captures NS-EVENT-10 draft title authoring visual gate`

Extrait de garde-fous UI :

```dart
    expect(find.text('Rencontre rival au port'), findsWidgets);
    expect(find.text('Événement existant'), findsNothing);
    expect(find.text('Titre mis à jour.'), findsOneWidget);
    expect(find.text('evt_existing'), findsWidgets);
    expect(find.text('Ajouter une condition'), findsNothing);
    expect(find.text('Ajouter une action'), findsNothing);
    expect(find.text('Choisir une scène'), findsNothing);
    expect(find.text('Sauvegarder'), findsNothing);
```

Fixtures ajustées :
- ajout de 12 tiles sur les maps 4x3 des tests pour respecter `MapValidator` ;
- ajout d’une `SceneAsset` `scene_existing` dans le shell UI pour que la scène référencée reste valide pendant la mutation.

## 10. Visual Gate

Capture générée :

```text
reports/narrativeStudio/events/screenshots/ns_event_10_draft_title_authoring_v0.png
```

Preuves fichier :

```bash
ls -lh reports/narrativeStudio/events/screenshots/ns_event_10_draft_title_authoring_v0.png
-rw-r--r--  1 karim  staff   143K Jun 17 19:11 reports/narrativeStudio/events/screenshots/ns_event_10_draft_title_authoring_v0.png

file reports/narrativeStudio/events/screenshots/ns_event_10_draft_title_authoring_v0.png
reports/narrativeStudio/events/screenshots/ns_event_10_draft_title_authoring_v0.png: PNG image data, 1440 x 900, 8-bit/color RGBA, non-interlaced

shasum -a 256 reports/narrativeStudio/events/screenshots/ns_event_10_draft_title_authoring_v0.png
f62a7fce47610a8661109ca731444f7bf8dc52ffdb2e3e3c8333f8ce94eeef40  reports/narrativeStudio/events/screenshots/ns_event_10_draft_title_authoring_v0.png
```

Vérification visuelle manuelle :
- event sélectionné visible ;
- titre humain renommé `Rencontre rival au port` ;
- ID technique `evt_existing` inchangé ;
- panneau détail visible ;
- aucun éditeur conditions/action/scène.

## 11. Validations exécutées

RED initial notifier :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_draft_creation_notifier_test.dart --name "NS-EVENT-10"
```

Résultat utile :

```text
Error: The method 'renameEventBuilderEventTitle' isn't defined for the type 'EditorNotifier'.
```

Diagnostic intermédiaire après ajout du notifier :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_draft_creation_notifier_test.dart --name "renames the human"
```

Résultat utile :

```text
Expected: null
Actual: 'Impossible de renommer l’événement : Tile layer ground has invalid tile count: expected 12, got 0'
```

Correction : fixture de test rendue valide avec 12 tiles pour une map 4x3.

Tests ciblés NS-EVENT-10 notifier :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_draft_creation_notifier_test.dart --name "NS-EVENT-10"
```

Résultat :

```text
00:02 +3: All tests passed!
```

Tests ciblés NS-EVENT-10 widget :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-10"
```

Résultat :

```text
00:03 +4: All tests passed!
```

Visual Gate :

```bash
cd packages/map_editor
flutter test --reporter=compact --update-goldens --dart-define=NS_EVENT_10_CAPTURE_WORKSPACE=true test/event_builder_workspace_test.dart --name "captures NS-EVENT-10"
```

Résultat :

```text
00:21 +1: All tests passed!
```

Suite workspace complète :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart
```

Résultat :

```text
00:06 +24: All tests passed!
```

Suite notifier complète :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_draft_creation_notifier_test.dart
```

Résultat :

```text
00:03 +5: All tests passed!
```

Tests core Event Builder :

```bash
cd packages/map_core
dart test --reporter=compact \
  test/event_builder_contract_test.dart \
  test/event_builder_authoring_operations_test.dart \
  test/event_builder_read_model_test.dart \
  test/event_builder_draft_creation_operations_test.dart
```

Résultat :

```text
00:00 +40: All tests passed!
```

Analyse ciblée :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos \
  lib/src/features/editor/state/editor_notifier.dart \
  lib/src/ui/canvas/events/event_builder_workspace.dart \
  lib/src/ui/canvas/narrative_workspace_canvas.dart \
  test/event_builder_workspace_test.dart \
  test/event_builder_draft_creation_notifier_test.dart
```

Résultat :

```text
Analyzing 5 items...
No issues found! (ran in 2.7s)
```

Build macOS debug :

```bash
cd packages/map_editor
flutter build macos --debug
```

Résultat :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 12. Non-objectifs respectés

Confirmé :
- pas de modification de l’ID technique ;
- pas de slug régénéré ;
- pas de renommage de références ;
- pas d’édition trigger/conditions/scène/comportement ;
- pas d’édition position/couche ;
- pas de picker Scene/Fact/Step ;
- pas de bibliothèque de blocs ;
- pas de flow editor ;
- pas de drag/drop ;
- pas de runtime/gameplay/battle/GameState ;
- pas de modification Selbrume/project.json ;
- pas de build_runner ;
- pas de commit.

## 13. Impact sur NS-EVENT-11

NS-EVENT-11 peut partir sur une prochaine édition bornée, par exemple :
- description no-code ;
- statut brouillon/actif ;
- trigger simple ;
- lien scène simple.

Précondition utile acquise :
- le workspace sait maintenant porter une micro-édition locale validée par notifier sans exposer l’ID.

## 14. Limites restantes

- Le workspace ne synchronise pas encore chaque sélection locale d’event vers `EditorState.selectedMapEventId` tant qu’aucune mutation notifier n’a lieu.
- Les triggers, conditions, actions, scènes et comportements restent en lecture seule.
- La Visual Gate utilise le harness de test widget, pas une manipulation manuelle de l’app macOS.

## 15. Auto-review critique

Points vérifiés :
- le lot ne modifie que `map_editor` + rapport/capture ;
- `map_core` n’est pas modifié ;
- l’ID technique reste non éditable ;
- `updateMapEventOnMap(...)` ne reçoit aucun nouvel ID ;
- `MapValidator.validate(...)` reste utilisé ;
- le refus vide est testé côté notifier et côté UI ;
- aucun contrôle conditions/actions/scène n’apparaît ;
- les fixtures ont été corrigées pour être validables au lieu de contourner la validation.

Risque mineur :
- la séparation sélection locale / sélection globale pourrait devenir confuse dans un prochain lot si l’Event Builder ajoute des opérations multi-events. Ce n’est pas bloquant pour NS-EVENT-10, car le renommage réussi force la sélection via `_applyMapMutation`.

## 16. Evidence Pack complet

Fichiers créés :
- `reports/narrativeStudio/events/ns_event_10_draft_title_authoring_v0.md`
- `reports/narrativeStudio/events/screenshots/ns_event_10_draft_title_authoring_v0.png`

Fichiers modifiés :
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/event_builder_draft_creation_notifier_test.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

Fichiers supprimés :
- aucun.

Diff stat avant création du rapport :

```bash
git diff --stat
 .../src/features/editor/state/editor_notifier.dart |  51 ++++
 .../ui/canvas/events/event_builder_workspace.dart  | 313 ++++++++++++++++++---
 .../src/ui/canvas/narrative_workspace_canvas.dart  |   1 +
 ...event_builder_draft_creation_notifier_test.dart |  90 +++++-
 .../test/event_builder_workspace_test.dart         | 165 ++++++++++-
 5 files changed, 580 insertions(+), 40 deletions(-)
```

Diff name-only avant création du rapport :

```bash
git diff --name-only
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/event_builder_draft_creation_notifier_test.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

Anti-scope avant création du rapport :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle packages/map_core examples assets selbrume pubspec.yaml
<vide>
```

Gate final après création du rapport :

```bash
git status --short --untracked-files=all
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/event_builder_draft_creation_notifier_test.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
?? reports/narrativeStudio/events/ns_event_10_draft_title_authoring_v0.md
?? reports/narrativeStudio/events/screenshots/ns_event_10_draft_title_authoring_v0.png

git diff --stat
 .../src/features/editor/state/editor_notifier.dart |  51 ++++
 .../ui/canvas/events/event_builder_workspace.dart  | 313 ++++++++++++++++++---
 .../src/ui/canvas/narrative_workspace_canvas.dart  |   1 +
 ...event_builder_draft_creation_notifier_test.dart |  90 +++++-
 .../test/event_builder_workspace_test.dart         | 165 ++++++++++-
 5 files changed, 580 insertions(+), 40 deletions(-)

git diff --name-only
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/event_builder_draft_creation_notifier_test.dart
packages/map_editor/test/event_builder_workspace_test.dart

git diff --check
<vide>
```

Anti-scope final :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle packages/map_core examples assets selbrume pubspec.yaml
<vide>
```

Critique du prompt :
- Le scope est cohérent et suffisamment borné.
- Le prompt demande un build macOS debug, pertinent car `EventBuilderWorkspace` et `EditorNotifier` changent.
- Le seul point à surveiller pour la suite est la sélection locale/globale : le prompt suppose implicitement un event sélectionné côté état, alors que l’UI actuelle sélectionne localement le premier event affiché. Ce lot reste correct car la mutation réussie remet `selectedMapEventId` sur l’event renommé.
