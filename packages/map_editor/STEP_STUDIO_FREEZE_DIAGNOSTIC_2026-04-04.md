# Diagnostic Incident Critique — Freeze + Explosion RAM (Step Studio)
Date: 2026-04-04  
Périmètre: `packages/map_editor` (workspace narratif / Step Studio)

---

## 1) Résumé exécutif

Un loop de chargements asynchrones a été identifié dans le Step Studio, combiné à des mutations UI non bornées, ce qui peut provoquer:
- blocage UI macOS (roulette colorée),
- montée mémoire extrême (tempête de Futures / snapshots map / rebuilds),
- sensation de freeze lors des clics sur des boutons “Ajouter …”.

Le correctif appliqué est **ciblé**, **minimal**, et **sans refonte**:
- suppression des side-effects async dans `build`,
- ajout d’un garde anti-concurrence des chargements map,
- arrêt du préchargement global agressif,
- arrêt des mutations locales redondantes (`setState` no-op),
- conservation de l’UX Step Studio (mêmes boutons / mêmes sections).

---

## 2) Symptôme utilisateur

Symptôme reporté:
- clic sur `Ajouter une cutscene liée`, `Ajouter un résultat`, `Ajouter un changement monde`,
- app macOS qui fige,
- RAM qui grimpe en boucle (jusqu’à des centaines de Go).

---

## 3) Cause racine (prouvée par lecture de code)

## Cause racine A — side-effects async dans `build`

Dans `StepStudioWorkspace`, deux sections lançaient des chargements async pendant le rendu:

- `_buildCompletionSection`  
  déclenchait `unawaited(_ensureEntitiesLoadedForMap(...))`
- `_buildWorldPersistenceSection`  
  déclenchait `unawaited(_ensureEntitiesLoadedForMap(...))` dans une boucle

Conséquence: chaque rebuild pouvait replanifier des chargements.

## Cause racine B — chargements concurrents non bornés

`_ensureEntitiesLoadedForMap` n’avait pas de protection “in-flight” avant correction.
Donc, tant que le premier chargement n’avait pas rempli le cache, plusieurs appels identiques pouvaient être lancés en parallèle.

Conséquence: tempête de lectures map + allocations + setState successifs.

## Cause racine C — préchargement agressif + warmup trop large

Deux amplificateurs existaient:
- préchargement de **toutes** les maps des world changes dans `_hydrateFromProject`,
- warmup entités déclenché sur mutations de step non map-centric (actions “add” génériques).

Conséquence: actions qui ne devraient modifier que le draft (ex. add cutscene/résultat) pouvaient déclencher des chargements map.

## Cause racine D — mutations UI redondantes

`_replaceDraft` / `_replaceSelectedStep` pouvaient pousser des `setState` même sans changement effectif.
En présence de callbacks UI bavards, cela peut amplifier la fréquence de rebuild.

---

## 4) Chaîne de déclenchement (boucle)

Chaîne principale observée (avant correction), cas typique:

1. Clic `Ajouter un changement monde`  
2. Handler bouton -> `_replaceSelectedStep(...)` -> `setState`  
3. Rebuild widget  
4. `build` relance `unawaited(_ensureEntitiesLoadedForMap(...))` (side-effect pendant rendu)  
5. `_ensureEntitiesLoadedForMap` lance des loads concurrents (pas de garde in-flight) + `setState` loading  
6. Nouveaux rebuilds -> replanification des mêmes loads  
7. Multiplication des snapshots/load + allocations + setState -> montée RAM + freeze UI

Chaîne indirecte (actions “Ajouter cutscene/résultat”):

1. Clic bouton add non map-centric  
2. mutation draft  
3. warmup trop large / préchargement agressif (avant fix) pouvait quand même déclencher des loads map  
4. même spirale que ci-dessus.

---

## 5) Pourquoi la RAM explose

L’explosion RAM n’est pas due à un seul objet géant mais à une **accumulation en boucle**:
- nombreux Futures de chargement map actifs en parallèle,
- snapshots / structures map/entités relues répétitivement,
- rebuilds et copies d’état répétées,
- pression GC croissante jusqu’au blocage UI.

---

## 6) Correctif appliqué (minimal et sûr)

Fichier corrigé:
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart`

### 6.1 Retrait des side-effects async du `build`

Supprimé:
- appels à `_ensureEntitiesLoadedForMap(...)` depuis:
  - `_buildCompletionSection`
  - `_buildWorldPersistenceSection`

Le `build` redevient lecture/rendu, pas pilotage.

### 6.2 Garde anti-concurrence des chargements map

Ajout:
- `final Set<String> _entityMapsLoading`

Dans `_ensureEntitiesLoadedForMap`:
- si map déjà chargée OU déjà en cours: return immédiat,
- tracking propre de début/fin de chargement,
- `_isLoadingEntities` dérivé du set in-flight.

### 6.3 Warmup borné et pertinent

Ajout helper:
- `_warmupEntityLookupsForStep(...)`

Règles:
- ne prime la map d’interaction que si `completion.mode == whenInteractionDone`,
- prime les maps des world changes de la step active,
- pas de warmup déclenché pour toute mutation locale générique.

### 6.4 Suppression du préchargement global agressif

Dans `_hydrateFromProject`:
- suppression du preload “toutes steps / toutes maps”.
- only targeted warmup (step active + actions utilisateur map-centric).

### 6.5 Garde anti setState no-op (anti tempête de rebuild)

Ajout:
- `_replaceDraft`: ignore si draft inchangé (`==`)
- `_replaceSelectedStep`: ignore si step strictement identique
- `_selectStep`: ignore re-sélection identique

---

## 7) Extraits de correction importants

Extrait (anti-concurrence):

```dart
if (_entitiesByMapId.containsKey(normalizedMapId) ||
    _entityMapsLoading.contains(normalizedMapId)) {
  return;
}
```

Extrait (anti no-op):

```dart
if (_draftDocument == next) {
  return;
}
```

Extrait (warmup borné au mode interaction):

```dart
if (step.completion.mode == StepStudioCompletionMode.whenInteractionDone) {
  final interactionRef = _decodeInteractionRef(step.completion.interactionId);
  ...
}
```

---

## 8) Ce qui est volontairement NON changé

- aucun rollback de l’architecture Step Studio,
- aucun changement de paradigme Global Story / Step / Cutscene,
- aucun déplacement hors workspace central,
- aucune suppression fonctionnelle des boutons “Ajouter …”,
- aucune écriture Git (commit/amend/rebase/merge/push/tag/stash).

---

## 9) Fichiers inspectés (audit demandé)

- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/narrative_inspector_panel.dart`

---

## 10) Validations exécutées

### Format

```bash
/opt/homebrew/Caskroom/flutter/3.38.4/flutter/bin/dart format \
  packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart
```

### Tests ciblés

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
/opt/homebrew/Caskroom/flutter/3.38.4/flutter/bin/flutter test \
  test/narrative_workspace_projection_test.dart \
  test/step_studio_authoring_test.dart \
  test/step_studio_workspace_regression_test.dart
```

Résultat: **All tests passed**.

### Analyze ciblé

```bash
cd /Users/karim/Project/pokemonProject
/opt/homebrew/Caskroom/flutter/3.38.4/flutter/bin/flutter analyze \
  packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart \
  packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart \
  packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart \
  packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart \
  packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart \
  packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart \
  packages/map_editor/lib/src/ui/panels/narrative_inspector_panel.dart \
  packages/map_editor/test/step_studio_workspace_regression_test.dart
```

Résultat: pas d’erreur bloquante sur ce correctif; lints `info` restants (`prefer_const_*`).

---

## 11) Niveau de certitude (honnête)

### Prouvé
- Side-effects async existaient dans `build`.
- Absence de garde in-flight sur chargements map.
- Préchargement global agressif + warmup large.
- Ces patterns sont suffisants pour créer des tempêtes rebuild/load.

### Très probable
- C’est la cause principale de l’explosion RAM observée sur clic “Ajouter …”.

### Non prouvé à 100% en local
- Reproduction GUI macOS exacte dans cette session (pas de run interactif complet ici).

---

## 12) Prochaine étape recommandée

Faire une vérification manuelle runtime immédiate sur macOS:

1. Ouvrir Step Studio.
2. Cliquer `Ajouter une cutscene liée`, `Ajouter un résultat`, `Ajouter un changement monde`.
3. Observer:
   - absence de spinner persistant,
   - RAM stable (pas de montée infinie),
   - UI réactive.

Si une montée mémoire persiste, ajouter un tracing ciblé temporaire autour de:
- `_replaceSelectedStep`,
- `_replaceDraft`,
- `_ensureEntitiesLoadedForMap`,
- nombre d’items `worldChanges/cutscenes/outcomes` par step.

---

## 13) Contrainte Git respectée

Aucune écriture Git effectuée:
- pas de commit
- pas d’amend
- pas de rebase
- pas de merge
- pas de push
- pas de tag
- pas de stash

