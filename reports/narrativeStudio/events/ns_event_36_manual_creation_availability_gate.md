# NS-EVENT-36 — Event Builder Real App Manual Creation Availability Fix / Layer Gate UX

## 1. Résumé exécutif

Manual Creation : PASS

Cause racine finale : le premier correctif NS-EVENT-36 réglait le cas “une `ObjectLayer` existe mais aucune couche active utile n’est sélectionnée”. La capture réelle du 19 juin 2026 montre un cas plus dur : la map Selbrume chargée ne contient aucune couche objet. Le panneau affichait donc un état honnête techniquement, mais inutilisable en no-code : l’utilisateur restait bloqué devant `Couche objet absente`.

Correction : le panneau de création propose maintenant une action locale `Créer la couche Événements` quand aucune `ObjectLayer` n’existe. Cette action crée une couche objet dédiée dans la map active, la sélectionne comme destination, affiche la grille de position, puis permet de créer le draft normalement.

Ce qui est prouvé :

- map avec une seule couche objet : destination auto-résolue, draft créé ;
- map avec couche active tile : l’unique couche objet est utilisée, draft créé ;
- map sans couche objet : bouton local de création de couche, couche `Événements` créée, position sélectionnable, draft créé et sélectionné ;
- map avec plusieurs couches objet : choix local explicite ;
- aucune modification runtime/gameplay/battle/core/Selbrume/project.json.

Prochain lot recommandé : NS-EVENT-37 — TriggerZone Runtime Entry Bridge / Runtime Movement Handoff.

Blockers : aucun blocker restant pour la création manuelle MVP.

## 2. Usage du MCP Dart

MCP Dart demandé par le prompt NS-EVENT-36, mais indisponible dans cette session. Vérifications de remplacement :

- navigation symboles avec `rg` / `sed` ;
- diagnostics CLI avec `flutter analyze --no-fatal-infos` ;
- tests widget/state/core ;
- build macOS debug.

## 3. Sous-agents utilisés

Synthèse des passes spécialisées :

| Sous-agent | Conclusion |
|---|---|
| A — Real App UX / Manual Flow | Le bouton était perçu comme inerte parce que l’écran ne fournissait pas de chemin pour satisfaire la couche manquante. |
| B — Editor State / Layer Resolution | Le gate dépendait d’une `ObjectLayer` existante ; Selbrume en était dépourvue. |
| C — No-code Product Boundary | Si une couche objet manque, l’Event Builder doit proposer une création explicite et locale, pas envoyer l’utilisateur deviner ailleurs. |
| D — Tests / Real Harness | Le test doit passer par `NarrativeWorkspaceCanvas` + `EditorNotifier`, pas par un gate isolé déjà valide. |
| E — Design System | Le correctif utilise les primitives PokeMap existantes et n’ajoute pas de couleur brute. |
| F — Reviewer contradictoire | A refusé le simple wording, le fallback silencieux sur `map.layers.first`, et la mutation automatique sans clic utilisateur. |

Arbitrage : création explicite d’une couche objet dédiée depuis le panneau Event Builder. Pas de création automatique silencieuse.

## 4. Observation utilisateur / bug réel

Symptôme observé dans l’app réelle :

```text
Workspace Événements ouvert
Map Selbrume chargée
0 événements
Bouton Nouvel événement grisé/inutile
Badge : Couche objet absente
Panneau : Aucune couche objet disponible sur cette map.
```

Impact produit : l’utilisateur ne pouvait pas créer le premier événement de Selbrume sans connaître la mécanique interne des couches.

## 5. Audit initial

Gate 0 de la reprise après capture :

```text
/Users/karim/Project/pokemonProject
main
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/event_builder_draft_creation_notifier_test.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
?? reports/narrativeStudio/events/ns_event_36_manual_creation_availability_gate.md
?? reports/narrativeStudio/events/screenshots/ns_event_36_manual_creation_availability_gate.png
```

Diff initial de reprise :

```text
.../ui/canvas/events/event_builder_workspace.dart  | 240 +++++++++++++++--
.../src/ui/canvas/narrative_workspace_canvas.dart  |  42 ++-
...event_builder_draft_creation_notifier_test.dart |  39 +++
.../test/event_builder_workspace_test.dart         | 295 +++++++++++++++++++--
4 files changed, 575 insertions(+), 41 deletions(-)
```

Fichiers lus :

- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`
- `packages/map_editor/test/event_builder_draft_creation_notifier_test.dart`
- `packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart`
- `packages/map_editor/lib/src/app/providers/editor/map_use_case_providers.dart`
- `selbrume/maps/Selbrume.json`

Preuve Selbrume :

```text
selbrume/maps/Selbrume.json : 17 layers, 0 ObjectLayer, events: []
```

## 6. Cause racine

Deux causes se superposaient :

1. `NarrativeWorkspaceCanvas` devait résoudre une couche objet même si `activeLayerId` était `null` ou pointait vers une couche tile.
2. Selbrume ne possède aucune `ObjectLayer`; le premier correctif expliquait mieux l’état, mais ne donnait pas de chemin no-code pour créer la couche nécessaire.

La cause finale du blocage utilisateur était donc : absence de couche objet + absence d’action locale de préparation.

## 7. Décision UX couche de destination

Règle canonique retenue :

| État map | Comportement Event Builder |
|---|---|
| Une seule `ObjectLayer` | Auto-résolution, `Couche de destination : <nom>`, grille utilisable. |
| Plusieurs `ObjectLayer` | Sélecteur local `Couche de destination`, pas de grille tant qu’aucune couche n’est choisie. |
| Aucune `ObjectLayer` | Message clair + bouton `Créer la couche Événements`; pas de grille trompeuse avant création. |

Décisions refusées :

- créer une couche automatiquement sans clic ;
- fallback silencieux sur la première couche de la map ;
- modifier les fichiers Selbrume/project.json directement ;
- obliger l’utilisateur à passer par le panneau global des couches pour une action MVP évidente.

## 8. Correction appliquée

### EditorNotifier

Ajout :

```dart
String? ensureEventBuilderObjectLayer()
```

Comportement :

- refuse proprement si aucune map active ;
- si une `ObjectLayer` existe, la sélectionne comme couche active ;
- si aucune n’existe, crée une `ObjectLayer` nommée `Événements` via `AddMapLayerUseCase` ;
- applique la mutation via `_applyMapMutation` ;
- ne crée aucun event ;
- pose `statusMessage: 'Couche d’événements créée'`.

### EventBuilderWorkspace

Ajouts :

- callback `onCreateDestinationLayer` ;
- bouton `Créer la couche Événements` dans le panneau destination quand aucune couche objet n’existe ;
- wording no-code : `Créez une couche dédiée ici, puis choisissez une position.`

### NarrativeWorkspaceCanvas

Branchement :

```dart
onCreateDestinationLayer: editorNotifier.ensureEventBuilderObjectLayer
```

La règle d’auto-résolution considère maintenant qu’une destination unique est auto-résolue même si elle vient d’être activée par l’action de préparation.

## 9. Tests ajoutés/modifiés

Tests state :

- `prepares a default object layer when a real imported map has none`

Tests UI :

- `NS-EVENT-36 real app event creation resolves an object layer and creates a draft`
- `NS-EVENT-36 ignores a tile active layer when one object layer is available`
- `NS-EVENT-36 creates an event layer from the real app panel before drafting`
- `NS-EVENT-36 lets user choose destination object layer when several exist`
- Visual Gate mise à jour pour partir d’une map sans couche objet.

## 10. Visual Gate

Capture créée/mise à jour :

```text
reports/narrativeStudio/events/screenshots/ns_event_36_manual_creation_availability_gate.png
```

Propriétés :

```text
PNG image data, 1440 x 1100, 8-bit/color RGBA, non-interlaced
Taille : 114K
```

La capture montre le chemin corrigé : map sans couche objet initiale, couche `Événements` créée, destination affichée, position sélectionnée, création prête.

## 11. Validations exécutées

TDD RED :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_draft_creation_notifier_test.dart --name "prepares a default object layer"
```

Sortie utile :

```text
Error: The method 'ensureEventBuilderObjectLayer' isn't defined for the type 'EditorNotifier'.
```

GREEN ciblé state :

```bash
cd packages/map_editor
/opt/homebrew/bin/flutter test --reporter=compact test/event_builder_draft_creation_notifier_test.dart --name "prepares a default object layer"
```

Sortie exacte utile :

```text
00:02 +1: All tests passed!
```

GREEN ciblé UI :

```bash
cd packages/map_editor
/opt/homebrew/bin/flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-36 creates an event layer"
```

Sortie exacte utile :

```text
00:03 +1: All tests passed!
```

Groupe NS-EVENT-36 :

```bash
cd packages/map_editor
/opt/homebrew/bin/flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-36"
```

Sortie exacte utile :

```text
00:06 +5: All tests passed!
```

Suite workspace complète :

```bash
cd packages/map_editor
/opt/homebrew/bin/flutter test --reporter=compact test/event_builder_workspace_test.dart
```

Sortie exacte utile :

```text
00:12 +106: All tests passed!
```

Notifier complet :

```bash
cd packages/map_editor
/opt/homebrew/bin/flutter test --reporter=compact test/event_builder_draft_creation_notifier_test.dart
```

Sortie exacte utile :

```text
00:01 +28: All tests passed!
```

Core authoring :

```bash
cd packages/map_core
/opt/homebrew/share/flutter/bin/cache/dart-sdk/bin/dart test --reporter=compact test/event_builder_authoring_operations_test.dart
```

Sortie exacte utile :

```text
00:00 +11: All tests passed!
```

Visual Gate :

```bash
cd packages/map_editor
/opt/homebrew/bin/flutter test --reporter=compact --update-goldens --dart-define=NS_EVENT_36_CAPTURE_WORKSPACE=true test/event_builder_workspace_test.dart --name "captures NS-EVENT-36"
```

Sortie exacte utile :

```text
00:04 +1: All tests passed!
```

Analyse ciblée :

```bash
cd packages/map_editor
/opt/homebrew/bin/flutter analyze --no-fatal-infos \
  lib/src/ui/canvas/narrative_workspace_canvas.dart \
  lib/src/ui/canvas/events/event_builder_workspace.dart \
  lib/src/features/editor/state/editor_notifier.dart \
  test/event_builder_workspace_test.dart \
  test/event_builder_draft_creation_notifier_test.dart
```

Sortie exacte :

```text
Analyzing 5 items...
No issues found! (ran in 1.6s)
```

Build macOS debug :

```bash
cd packages/map_editor
/opt/homebrew/bin/flutter build macos --debug
```

Sortie exacte :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 12. Verdict Manual Creation

Manual Creation : PASS

La création manuelle n’est plus bloquée pour les maps importées sans couche objet : l’Event Builder propose explicitement de préparer la couche, puis le flux normal position -> draft fonctionne.

## 13. Non-objectifs respectés

Respecté :

- pas de modification `map_runtime` ;
- pas de modification `map_gameplay` ;
- pas de modification `map_battle` ;
- pas de modification `map_core` ;
- pas de modification Selbrume / examples / assets / pubspec ;
- pas de modification `project.json` final ;
- pas de drag/drop ;
- pas d’authoring outcome/reaction/world rule ;
- pas de nouveau `SceneConsequenceKind` ;
- pas de `build_runner` ;
- pas de commit.

## 14. Risques résiduels

- La couche est créée dans la map active en mémoire via l’éditeur. L’utilisateur devra sauvegarder le projet comme pour toute modification de map.
- La vérification automatique reproduit le parcours réel via `NarrativeWorkspaceCanvas`, mais il reste utile de confirmer manuellement dans l’app déjà ouverte.
- Si plusieurs couches objet ont des conventions métier, le picker laisse choisir mais ne documente pas encore ces conventions.

## 15. Prochain lot recommandé

NS-EVENT-37 — TriggerZone Runtime Entry Bridge / Runtime Movement Handoff.

Raison : le verrou UX de création est levé ; on peut reprendre le risque runtime laissé PARTIAL par NS-EVENT-35.

## 16. Evidence Pack

Fichiers modifiés :

- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/event_builder_draft_creation_notifier_test.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

Fichiers créés :

- `reports/narrativeStudio/events/ns_event_36_manual_creation_availability_gate.md`
- `reports/narrativeStudio/events/screenshots/ns_event_36_manual_creation_availability_gate.png`

Diff stat avant rapport :

```text
.../src/features/editor/state/editor_notifier.dart |  41 +++
.../ui/canvas/events/event_builder_workspace.dart  | 259 ++++++++++++++++--
.../src/ui/canvas/narrative_workspace_canvas.dart  |  43 ++-
...event_builder_draft_creation_notifier_test.dart |  39 +++
.../test/event_builder_workspace_test.dart         | 301 +++++++++++++++++++--
5 files changed, 642 insertions(+), 41 deletions(-)
```

Zones importantes :

- `EditorNotifier.ensureEventBuilderObjectLayer`
- `EventBuilderWorkspace.onCreateDestinationLayer`
- `_DraftDestinationLayerPanel` bouton `event-builder-create-destination-layer`
- `_buildEventBuilderDraftCreationGate` auto-résolution d’unique couche objet
- tests `NS-EVENT-36 creates an event layer from the real app panel before drafting`

Gate final :

```bash
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

Sortie exacte utile :

```text
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/event_builder_draft_creation_notifier_test.dart
 M packages/map_editor/test/event_builder_workspace_test.dart
?? reports/narrativeStudio/events/ns_event_36_manual_creation_availability_gate.md
?? reports/narrativeStudio/events/screenshots/ns_event_36_manual_creation_availability_gate.png

.../src/features/editor/state/editor_notifier.dart |  41 +++
.../ui/canvas/events/event_builder_workspace.dart  | 259 ++++++++++++++++--
.../src/ui/canvas/narrative_workspace_canvas.dart  |  43 ++-
...event_builder_draft_creation_notifier_test.dart |  39 +++
.../test/event_builder_workspace_test.dart         | 301 +++++++++++++++++++--
5 files changed, 642 insertions(+), 41 deletions(-)

packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/event_builder_draft_creation_notifier_test.dart
packages/map_editor/test/event_builder_workspace_test.dart
```

`git diff --check` final : aucune sortie.

Anti-scope :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle
git diff --name-only -- examples assets selbrume pubspec.yaml
git diff --name-only -- packages/map_core
```

Sortie exacte : vide.

## 17. Auto-review critique

- Le correctif traite le vrai cas Selbrume observé : oui, map sans `ObjectLayer`.
- Le bouton ne ment pas : oui, il crée uniquement une couche objet, pas un event.
- L’action est explicite : oui, aucune mutation silencieuse.
- Le flux complet est prouvé : oui, couche créée -> position -> draft -> sélection.
- Le scope est tenu : oui, uniquement `map_editor` et tests.
- Limite : pas de test automatisé qui ouvre le fichier Selbrume réel dans l’app déjà lancée.

## 18. Critique du prompt

Le prompt initial NS-EVENT-36 était bon mais sous-estimait le cas réel : il supposait qu’une couche objet pouvait exister et être mal résolue. La capture utilisateur a révélé un second cas plus important : certaines maps importées n’ont aucune `ObjectLayer`. La bonne réponse produit n’était donc pas seulement “meilleur message”, mais “action locale explicite de préparation”.
