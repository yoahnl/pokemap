# Stabilisation ciblée — Régressions Step Studio
Date: 2026-04-04  
Périmètre: corrections chirurgicales post-lot Step Studio (sans rollback global)

---

## Résumé exécutif

Deux régressions majeures ont été corrigées sans changer l’architecture produit:

1. **Crash Riverpod** (`Tried to modify a provider while the widget tree was building`) causé par une notification de sélection step pendant l’hydratation (`initState/build`).
2. **Overflow UI** (`RenderFlex overflowed`) causé par des composants de ligne/capsule trop compacts pour leur contenu (vertical et horizontal).

La correction garde le paradigme existant:

- Workspaces narratifs au centre.
- `Global Story` / `Step` / `Cutscene` inchangés conceptuellement.
- Pas de rollback du lot Step Studio.

---

## Symptômes observés

## 1) Riverpod / provider modified during build

Stack signalée:

- `StepStudioWorkspace._hydrateFromProject`
- callback `onSelectStep`
- `NarrativeWorkspaceCanvas` -> `NarrativeWorkspaceController.selectStep/openStep`

Concrètement, une auto-sélection était poussée vers un provider global pendant les phases interdites.

## 2) RenderFlex overflow

Deux zones:

- Overflow vertical dans `EditorSidebarListRow` (titre + sous-titre dans une hauteur fixe trop faible).
- Overflow horizontal dans `InspectorEmbeddedPrimaryCapsule` (Row `mainAxisSize.min` + texte non flexible en largeur réduite).

---

## Cause racine #1 (Riverpod)

Dans `step_studio_workspace.dart`, l’hydratation appelait directement:

```dart
widget.onSelectStep(resolvedSelection);
```

depuis `_hydrateFromProject()` appelé en `initState`/`didUpdateWidget`.

Cette callback mutait le provider narratif parent pendant la construction de l’arbre, ce qui viole les invariants Riverpod.

---

## Cause racine #2 (Overflow layout)

## 2.1 Overflow vertical list row

Dans `cupertino_editor_widgets.dart`, `EditorSidebarListRow` imposait une hauteur compacte quasi fixe même quand un sous-titre est présent:

- `SizedBox(height: ~30)`
- `Column(title + subtitle)`

=> le contenu dépasse verticalement.

## 2.2 Overflow horizontal capsule

Dans `inspector_embedded_widgets.dart`, `InspectorEmbeddedPrimaryCapsule` utilisait:

- `Row(mainAxisSize: MainAxisSize.min)`
- `Text(label)` non flexible

=> le label pouvait déborder en largeur contrainte.

---

## Stratégie de correction

Approche volontairement **chirurgicale**:

- corriger le timing de mutation provider (post-frame + déduplication),
- rendre les composants incriminés robustes en layout compact,
- ne pas modifier la structure métier ni le shell.

---

## Fichiers modifiés

- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/shared/inspector_embedded_widgets.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/step_studio_workspace_regression_test.dart`

---

## Détail des corrections

## A. Correction provider-safe de la sélection Step

Fichier: `step_studio_workspace.dart`

### Changement clé

Ajout d’un mécanisme de synchronisation différée:

```dart
void _dispatchSelectionAfterFrame(String? stepId) {
  _queuedSelectionToDispatch = stepId;
  if (_selectionDispatchScheduled) return;
  _selectionDispatchScheduled = true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _selectionDispatchScheduled = false;
    if (!mounted) return;
    final nextSelection = _queuedSelectionToDispatch;
    _queuedSelectionToDispatch = null;
    if (nextSelection == _lastDispatchedSelection) return;
    _lastDispatchedSelection = nextSelection;
    widget.onSelectStep(nextSelection);
  });
}
```

### Pourquoi c’est nécessaire

- Empêche toute mutation provider pendant `initState/build/didUpdateWidget`.
- Préserve l’auto-sélection initiale attendue produit.
- Évite les notifications redondantes (déduplication).

### Zones mises à jour

- branch `project == null` de `_hydrateFromProject`
- branch `globalScenarios.isEmpty`
- branch nominale d’hydratation

En remplacement des appels synchrones à `widget.onSelectStep(...)`.

---

## B. Correction overflow vertical de `EditorSidebarListRow`

Fichier: `cupertino_editor_widgets.dart`

### Changement clé

Hauteur adaptative selon présence du sous-titre + fallback compact:

```dart
final hasSubtitle = widget.subtitle != null;
final baseRowHeight = hasSubtitle ? 42.0 : 30.0;
...
final canShowSubtitle = widget.subtitle != null && constraints.maxHeight >= 36;
```

et:

- `Column(mainAxisSize: MainAxisSize.min)`
- sous-titre affiché seulement si hauteur suffisante (`canShowSubtitle`)
- `Flexible` sur le sous-titre.

### Pourquoi c’est nécessaire

- Supprime la contradiction “2 lignes de contenu dans une hauteur 1-ligne”.
- Garde un mode compact lisible sans masquer arbitrairement via clipping.

---

## C. Correction overflow horizontal de `InspectorEmbeddedPrimaryCapsule`

Fichier: `inspector_embedded_widgets.dart`

### Changement clé

Passage de:

- `Row(mainAxisSize: MainAxisSize.min)` + `Text` brut

à:

- `Row(mainAxisSize: MainAxisSize.max)`
- `Flexible(child: Text(maxLines: 1, overflow: TextOverflow.ellipsis))`

### Pourquoi c’est nécessaire

- En largeur contrainte, le label se compacte proprement au lieu de générer un overflow.

---

## D. Test de régression ajouté

Fichier: `test/step_studio_workspace_regression_test.dart`

### Test 1

- Vérifie que la callback d’auto-sélection step n’est **pas** exécutée en phase `SchedulerPhase.persistentCallbacks` (phase build).

### Test 2

- Vérifie qu’une ligne `EditorSidebarListRow` avec sous-titre ne génère pas d’exception d’overflow.

---

## Ce que j’ai volontairement choisi de ne pas changer

1. Aucune refonte du modèle métier Step Studio.
2. Aucune suppression des workspaces narratifs centraux.
3. Aucune modification de la séparation `Global Story / Step / Cutscene`.
4. Aucun changement structurel côté shell gauche/centre/droite.
5. Aucun rollback des ajouts du lot précédent.

Objectif respecté: stabilisation ciblée, pas de redesign.

---

## Validations exécutées

## 1) Format

Exécuté:

```bash
dart format \
  packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart \
  packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart \
  packages/map_editor/lib/src/ui/shared/inspector_embedded_widgets.dart \
  packages/map_editor/test/step_studio_workspace_regression_test.dart
```

## 2) Tests ciblés

Exécuté:

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test \
  test/narrative_workspace_projection_test.dart \
  test/step_studio_authoring_test.dart \
  test/step_studio_workspace_regression_test.dart
```

Résultat: **OK (all tests passed)**.

## 3) Analyze ciblé

Exécuté:

```bash
cd /Users/karim/Project/pokemonProject
flutter analyze \
  packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart \
  packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart \
  packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart \
  packages/map_editor/lib/src/ui/shared/inspector_embedded_widgets.dart \
  packages/map_editor/test/step_studio_workspace_regression_test.dart
```

Résultat: pas d’erreur bloquante sur ces corrections.  
Des `info` de lint subsistent (principalement `prefer_const_*` + un `deprecated_member_use_from_same_package` pré-existant).

---

## Limites restantes (honnêtes)

1. Le ciblage analyze retourne encore des infos lint non bloquantes.
2. La stabilisation règle les causes directes observées, mais un audit responsive global du design system peut encore révéler d’autres cas limites d’espace.
3. Le test provider-safe verrouille le timing de callback, mais ne remplace pas une batterie complète d’intégration UI sur tous workflows narratifs.

---

## Contrainte Git respectée

Aucune opération Git d’écriture n’a été effectuée:

- pas de commit
- pas d’amend
- pas de merge
- pas de rebase
- pas de push
- pas de tag
- pas de stash

