# NS-EVENT-11 - Event Builder Scene Action Authoring V0

## 1. Resume executif

Statut : DONE.

NS-EVENT-11 ajoute l'edition bornee de l'action principale d'un event dans le
workspace Evenements : choisir une Scene existante et l'ecrire dans
`MapEventPage.sceneTarget`.

Le lot ne cree pas de Scene, n'edite pas les conditions, n'ouvre pas le Scene
Builder, ne modifie pas le runtime, ne modifie pas Selbrume, et ne change pas
`map_core`.

Comportement livre :

- un brouillon sans Scene affiche `Choisir une scene` ;
- le picker inline liste les Scenes existantes du `ProjectManifest` ;
- selectionner une Scene ecrit `MapEventPage.sceneTarget.sceneId` ;
- l'ID technique, le titre, la position, le type, les metadata, les conditions,
  le script et le message sont preserves ;
- le read model reconstruit ensuite `Jouer la scene "..."` et le statut
  `Actif` si aucun diagnostic bloquant ne reste ;
- les cas `sceneId` vide, scene inconnue, event inconnu et event sans page sont
  refuses proprement.

## 2. Decision page cible

Decision : cibler la page d'event au plus petit `pageNumber`.

Raison :

- `readEventBuilderContractFromMapEvent(...)` et `EventBuilderReadModel`
  selectionnent deja la page au plus petit `pageNumber` ;
- les drafts NS-EVENT-06/08/09 creent une page `pageNumber = 0` ;
- des events plus anciens peuvent avoir des pages non ordonnees ;
- creer automatiquement une page aurait elargi le lot.

Reponses audit :

- page cible : plus petit `pageNumber` ;
- page 0 : oui pour les drafts recents, non garanti pour tout l'historique ;
- event sans page : refus lisible, aucune creation implicite ;
- validation Scene : `sceneId.trim()` doit correspondre a `project.scenes` ;
- `Retirer la scene` : non livre dans NS-EVENT-11, a garder pour un lot dedie.

## 3. Operation notifier ajoutee

Fichier :

`packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`

Zone ajoutee :

```dart
bool updateEventBuilderEventSceneAction({
  required String eventId,
  required String sceneId,
}) {
  final map = state.activeMap;
  if (map == null) {
    state = state.copyWith(
      errorMessage:
          'Aucune map active pour modifier la scène de l’événement.',
    );
    return false;
  }
  final project = state.project;
  if (project == null) {
    state = state.copyWith(
      errorMessage: 'Aucun projet actif pour choisir une scène.',
    );
    return false;
  }
  final trimmedSceneId = sceneId.trim();
  if (trimmedSceneId.isEmpty) {
    state = state.copyWith(errorMessage: 'Scène d’événement obligatoire.');
    return false;
  }
  final event = findMapEventById(map, eventId);
  if (event == null) {
    state = state.copyWith(errorMessage: 'Événement introuvable : $eventId');
    return false;
  }
  if (event.pages.isEmpty) {
    state = state.copyWith(
      errorMessage: 'Cet événement ne contient aucune page authorable.',
    );
    return false;
  }
  final sceneExists =
      project.scenes.any((scene) => scene.id == trimmedSceneId);
  if (!sceneExists) {
    state = state.copyWith(
      errorMessage: 'Scène introuvable : $trimmedSceneId',
    );
    return false;
  }

  // NS-EVENT-11 reste aligné avec le read model Event Builder : on écrit
  // uniquement la page authorable canonique, sans créer de page implicite.
  final pageNumber = _eventBuilderAuthorablePageNumber(event);
  try {
    final updated = setMapEventPageSceneTarget(
      map,
      eventId: eventId,
      pageNumber: pageNumber,
      sceneId: trimmedSceneId,
    );
    MapValidator.validate(
      updated,
      projectDialogueContext: project,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updated,
      preferredActiveLayerId: state.activeLayerId,
      preferredSelectedMapEventId: eventId,
      statusMessage: 'Scène d’événement mise à jour',
    );
    return true;
  } catch (e) {
    state = state.copyWith(
      errorMessage:
          'Impossible de mettre à jour la scène de l’événement : $e',
    );
    return false;
  }
}
```

Helper ajoute :

```dart
/// Retourne la même page cible que le contrat Event Builder.
///
/// Les drafts actuels utilisent pageNumber 0, mais les anciens events peuvent
/// contenir des pages non ordonnées ; on préserve donc la règle "plus petit
/// pageNumber" au lieu de supposer que l'index 0 est toujours canonique.
int _eventBuilderAuthorablePageNumber(MapEventDefinition event) {
  var selected = event.pages.first.pageNumber;
  for (final page in event.pages.skip(1)) {
    if (page.pageNumber < selected) {
      selected = page.pageNumber;
    }
  }
  return selected;
}
```

## 4. UI Scene action ajoutee

Fichier :

`packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`

Zones ajoutees :

```dart
typedef EventBuilderSceneActionUpdateCallback = bool Function({
  required String eventId,
  required String sceneId,
});

class EventBuilderSceneOption {
  const EventBuilderSceneOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}
```

Le panneau detail recoit maintenant :

```dart
final List<EventBuilderSceneOption> sceneOptions;
final EventBuilderSceneActionUpdateCallback? onUpdateSceneAction;
```

La section `Action principale` utilise un bloc borne :

```dart
_DetailLine(
  label: selected.sceneAction.isMissing ? 'État' : 'Scène',
  value: selected.sceneAction.label,
),
PokeMapButton(
  key: const ValueKey('event-builder-choose-scene-button'),
  onPressed: () => _startSceneChoice(),
  variant: PokeMapButtonVariant.secondary,
  size: PokeMapButtonSize.small,
  leading: const Icon(CupertinoIcons.play_rectangle),
  child: Text(sceneButtonLabel),
),
```

Le picker affiche seulement des Scenes existantes :

```dart
// Picker borné : les options viennent du ProjectManifest et
// l'utilisateur ne saisit jamais de sceneId à la main dans ce lot.
PokeMapCard(
  padding: const EdgeInsets.all(10),
  borderRadius: 8,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Scènes disponibles', ...),
      Wrap(
        children: [
          for (final option in widget.sceneOptions)
            PokeMapButton(
              key: ValueKey('event-builder-scene-option-${option.id}'),
              onPressed: () => _selectScene(selected, option),
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.small,
              isSelected: selected.sceneAction.sceneId == option.id,
              leading: const Icon(CupertinoIcons.film),
              child: Text(option.label),
            ),
        ],
      ),
    ],
  ),
)
```

Etat vide :

```dart
const _DiagnosticNotice(
  title: 'Aucune scène disponible.',
  message:
      'Créez une scène dans le workspace Scènes avant de choisir '
      'l’action principale de cet événement.',
  tone: PokeMapTone.warning,
  severityLabel: 'Action indisponible',
  details: ['Aucune création de scène dans ce lot'],
)
```

## 5. Options Scene / labels

Fichier :

`packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`

Zone ajoutee :

```dart
List<EventBuilderSceneOption> _buildEventBuilderSceneOptions(
  ProjectManifest? project,
) {
  return [
    for (final scene in project?.scenes ?? const <SceneAsset>[])
      EventBuilderSceneOption(
        id: scene.id,
        label: scene.name.trim().isEmpty ? scene.id : scene.name.trim(),
      ),
  ];
}
```

Le workspace Event Builder recoit :

```dart
sceneOptions: _buildEventBuilderSceneOptions(editor.project),
onUpdateSceneAction:
    editorNotifier.updateEventBuilderEventSceneAction,
```

Le label principal est `scene.name.trim()` ; l'ID sert seulement de fallback si
le nom est vide.

## 6. Validation Scene existante

Validation ajoutee dans le notifier :

- activeMap requise ;
- projet actif requis ;
- `sceneId.trim()` non vide ;
- event existant ;
- au moins une page authorable ;
- Scene existante dans `project.scenes` ;
- mutation via `setMapEventPageSceneTarget(...)` ;
- validation finale via `MapValidator.validate(...)` ;
- selection event preservee via `preferredSelectedMapEventId`.

## 7. Tests ajoutes/modifies

Fichiers :

- `packages/map_editor/test/event_builder_draft_creation_notifier_test.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

Tests notifier ajoutes :

- `NS-EVENT-11 EditorNotifier scene action authoring writes the scene target on the lowest page without changing identity`
- `rejects an empty scene id without mutating the event`
- `rejects an unknown scene without mutating the event`
- `rejects an unknown event without mutating the map`
- `rejects an event without page without mutating the map`

Tests UI ajoutes :

- `NS-EVENT-11 selects a scene action for a draft event without changing id`
- `NS-EVENT-11 shows an empty scene picker message`
- `captures NS-EVENT-11 scene action authoring visual gate`

## 8. Visual Gate

Capture creee :

`reports/narrativeStudio/events/screenshots/ns_event_11_scene_action_authoring_v0.png`

Preuve fichier :

```text
-rw-r--r--  1 karim  staff   161K Jun 17 19:51 reports/narrativeStudio/events/screenshots/ns_event_11_scene_action_authoring_v0.png
reports/narrativeStudio/events/screenshots/ns_event_11_scene_action_authoring_v0.png: PNG image data, 1440 x 900, 8-bit/color RGBA, non-interlaced
84c3e4df38a7aad15628ea543c61382448ad7d0f52fddf10798dfb59ba984f4d  reports/narrativeStudio/events/screenshots/ns_event_11_scene_action_authoring_v0.png
```

Commande :

```bash
cd packages/map_editor
flutter test --update-goldens --reporter=compact test/event_builder_workspace_test.dart --name "captures NS-EVENT-11" --dart-define=NS_EVENT_11_CAPTURE_WORKSPACE=true
```

Resultat exact utile :

```text
00:03 +1: captures NS-EVENT-11 scene action authoring visual gate
00:03 +1: All tests passed!
```

## 9. Validations executees

### RED notifier

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_draft_creation_notifier_test.dart --name "NS-EVENT-11"
```

Sortie utile exacte :

```text
test/event_builder_draft_creation_notifier_test.dart:171:32: Error: The method 'updateEventBuilderEventSceneAction' isn't defined for the type 'EditorNotifier'.
test/event_builder_draft_creation_notifier_test.dart:210:32: Error: The method 'updateEventBuilderEventSceneAction' isn't defined for the type 'EditorNotifier'.
test/event_builder_draft_creation_notifier_test.dart:234:32: Error: The method 'updateEventBuilderEventSceneAction' isn't defined for the type 'EditorNotifier'.
test/event_builder_draft_creation_notifier_test.dart:258:32: Error: The method 'updateEventBuilderEventSceneAction' isn't defined for the type 'EditorNotifier'.
test/event_builder_draft_creation_notifier_test.dart:282:32: Error: The method 'updateEventBuilderEventSceneAction' isn't defined for the type 'EditorNotifier'.
00:07 +0 -1: Some tests failed.
```

### RED UI

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-11"
```

Sortie utile exacte :

```text
test/event_builder_workspace_test.dart:959:8: Error: Type 'EventBuilderSceneOption' not found.
test/event_builder_workspace_test.dart:960:3: Error: Type 'EventBuilderSceneActionUpdateCallback' not found.
test/event_builder_workspace_test.dart:990:15: Error: No named parameter with the name 'sceneOptions'.
00:05 +0 -1: Some tests failed.
```

### GREEN cible notifier

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_draft_creation_notifier_test.dart --name "NS-EVENT-11"
```

Resultat exact utile :

```text
00:04 +5: NS-EVENT-11 EditorNotifier scene action authoring rejects an event without page without mutating the map
00:04 +5: All tests passed!
```

### GREEN cible UI

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-11"
```

Resultat exact utile :

```text
00:05 +3: captures NS-EVENT-11 scene action authoring visual gate
00:05 +3: All tests passed!
```

### Suite workspace complete

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart
```

Resultat exact utile :

```text
00:05 +27: captures NS-EVENT-05 readonly diagnostics visual gate
00:05 +27: All tests passed!
```

### Suite notifier complete

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_draft_creation_notifier_test.dart
```

Resultat exact utile :

```text
00:02 +10: NS-EVENT-11 EditorNotifier scene action authoring rejects an event without page without mutating the map
00:02 +10: All tests passed!
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

Resultat exact utile :

```text
00:00 +40: test/event_builder_draft_creation_operations_test.dart: Event Builder draft creation operations preserves existing events unchanged
00:00 +40: All tests passed!
```

### Analyse ciblee

Commande :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos \
  lib/src/features/editor/state/editor_notifier.dart \
  lib/src/ui/canvas/events/event_builder_workspace.dart \
  lib/src/ui/canvas/narrative_workspace_canvas.dart \
  test/event_builder_workspace_test.dart \
  test/event_builder_draft_creation_notifier_test.dart
```

Resultat exact :

```text
Analyzing 5 items...
No issues found! (ran in 2.9s)
```

### Build macOS debug

Commande :

```bash
cd packages/map_editor
flutter build macos --debug
```

Resultat exact utile :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 10. Non-objectifs respectes

Confirme :

- aucune creation de Scene ;
- aucune edition de Scene ;
- aucun Scene Builder ouvert ;
- aucune edition de trigger ;
- aucune edition de condition ;
- aucune edition de behavior/outcome/world rule ;
- aucun picker Fact/Step ;
- aucune bibliotheque de blocs ;
- aucun flow editor ;
- aucun drag/drop ;
- aucune modification runtime/gameplay/battle/GameState ;
- aucune modification Selbrume/project.json ;
- aucun build_runner ;
- aucun fichier genere modifie ;
- aucun commit.

## 11. Impact sur NS-EVENT-12

NS-EVENT-12 peut maintenant partir de l'hypothese suivante :

- un event draft peut recevoir une action principale `Scene` depuis l'UI ;
- le lien est stocke dans `MapEventPage.sceneTarget` ;
- le read model affiche `Actif` et `Jouer la scene "..."` si le lien est
  valide ;
- le picker Scene est volontairement minimal et ne gere ni creation, ni edition,
  ni retrait de Scene.

Prochain lot probable : conditions simples ou une premiere edition de
comportement, selon la roadmap Event Builder. Ne pas demarrer ces sujets dans
NS-EVENT-11.

## 12. Limites restantes

- Pas de bouton `Retirer la scene`.
- Pas de creation/edition Scene depuis le picker.
- Pas d'edition conditions/actions/outcomes.
- Pas de preview runtime de l'event.
- L'ID technique est verifie par les tests, mais la Visual Gate recadree montre
  surtout l'action principale et le statut actif.

## 13. Evidence Pack complet

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

Sorties :

```text
/Users/karim/Project/pokemonProject
main
git status --short --untracked-files=all : <vide>
git diff --stat : <vide>
git diff --name-only : <vide>
fc0e0be0 ns_event_10: Ajout de la saisie du titre pour les brouillons d'événements
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
```

### Regles lues

- `AGENTS.md` fourni dans le thread ;
- `codex_rule.md` ;
- `skills/README.md` ;
- `skills/using-superpowers/SKILL.md` ;
- `skills/test-driven-development/SKILL.md` ;
- `skills/verification-before-completion/SKILL.md` ;
- prompt joint `NS-EVENT-11`.

### Fichiers lus / audites

- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/operations/map_events.dart`
- `packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart`
- `packages/map_core/lib/src/read_models/event_builder_read_model.dart`
- `packages/map_core/lib/src/validation/validators.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`
- `packages/map_editor/test/event_builder_draft_creation_notifier_test.dart`

### Fichiers crees

- `reports/narrativeStudio/events/ns_event_11_scene_action_authoring_v0.md`
- `reports/narrativeStudio/events/screenshots/ns_event_11_scene_action_authoring_v0.png`

Contenu complet du fichier Markdown cree : ce document.

### Fichiers modifies

- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/event_builder_draft_creation_notifier_test.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

### Fichiers supprimes

Aucun.

### Anti-scope final

Commande :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle packages/map_core examples assets selbrume pubspec.yaml
```

Sortie :

```text
<vide>
```

### git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
<vide>
```

### Etat git final

```text
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/event_builder_draft_creation_notifier_test.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
?? reports/narrativeStudio/events/ns_event_11_scene_action_authoring_v0.md
?? reports/narrativeStudio/events/screenshots/ns_event_11_scene_action_authoring_v0.png
```

### git diff --stat final

```text
 .../src/features/editor/state/editor_notifier.dart |  90 ++++++++
 .../ui/canvas/events/event_builder_workspace.dart  | 190 ++++++++++++++-
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  15 ++
 ...event_builder_draft_creation_notifier_test.dart | 257 +++++++++++++++++++++
 .../test/event_builder_workspace_test.dart         | 155 +++++++++++++
 5 files changed, 703 insertions(+), 4 deletions(-)
```

### git diff --name-only final

```text
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/event_builder_draft_creation_notifier_test.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

Note : `git diff --name-only` ne liste pas les fichiers non suivis. Ils sont
visibles dans le `git status` final ci-dessus.

### Verification screenshots hors lot suivant

Commandes :

```bash
find reports/narrativeStudio/events/screenshots -maxdepth 1 -name '*ns_event_11*' -print
find reports/narrativeStudio/events/screenshots -maxdepth 1 -name '*ns_event_12*' -print
```

Sorties :

```text
reports/narrativeStudio/events/screenshots/ns_event_11_scene_action_authoring_v0.png
<vide pour ns_event_12>
```

## 14. Verdict des passes type sub-agent

### Sub-agent Audit / Architecture

Verdict : OK.

Le prompt est coherent avec le repo. Le core possede deja `MapEventSceneTarget`,
`setMapEventPageSceneTarget`, le contrat Event Builder et le read model. La
bonne strategie est donc editor-only, sans second modele et sans changement
`map_core`.

### Sub-agent Implementation

Verdict : OK.

Implementation limitee a :

- une methode notifier ;
- un helper de selection de page ;
- un type option Scene UI ;
- un picker inline ;
- le branchement du shell narratif.

### Sub-agent Tests

Verdict : OK.

TDD respecte : tests RED observes avant implementation, puis GREEN cible et
suites completes.

### Sub-agent Build / Validation

Verdict : OK.

Analyse ciblee et build macOS debug executes avec succes.

### Sub-agent Critique finale

Verdict : OK avec reserve mineure.

La Visual Gate ne montre pas simultanement tous les details techniques, mais les
tests prouvent que l'ID technique reste inchange. La capture montre le flux
principal attendu : event actif, action principale Scene choisie, pas d'editeur
conditions/actions.

## 15. Auto-review critique

Points verifies :

- aucune modification `map_core` ;
- aucune modification runtime/gameplay/battle/Selbrume ;
- page cible coherente avec le contrat existant ;
- `sceneId` non expose comme saisie utilisateur ;
- Scene existante obligatoire ;
- champs legacy preserves ;
- pas de bouton condition/action/Scene Builder ;
- tests negatifs presents ;
- build macOS debug lance.

Risques restants :

- le retrait de Scene n'est pas supporte ;
- le picker est une liste inline, pas encore un composant dropdown reutilisable ;
- le workspace peut necessiter un polish UX plus tard si la liste de Scenes
  devient longue.

## 16. Critique du prompt

Le prompt est bien borne et realiste pour NS-EVENT-11. Le point a surveiller est
le wording `Retirer la scene` : il est recommande mais optionnel ; ne pas le
faire dans ce lot etait le choix le plus sur pour eviter de rouvrir les
diagnostics/UX du passage Actif vers Brouillon.

Le prompt demande aussi une Visual Gate montrant idealement l'ID technique
inchange. La capture finale privilegie la section action principale ; l'ID
technique est couvert par les tests UI et notifier.
