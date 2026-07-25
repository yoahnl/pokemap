# Rapport d'analyse de performance — Narrative Studio

**Date :** 2026-07-24
**Scope :** Analyse complète des problèmes de performance dans le Narrative Studio (packages `map_editor` et `map_core`)
**Type :** Audit de performance read-only — aucune modification de code

---

## Résumé exécutif

L'analyse a identifié **7 problèmes de performance significatifs** dans le Narrative Studio, allant de la recomputation inutile de la recherche floue à des rechargements disque complets à chaque mutation d'Event. Les problèmes les plus critiques concernent :

1. Le **Global Search Index** qui normalise les entrées à chaque recherche au lieu de les pré-normaliser
2. Le **Command Palette** qui appelle `_items()` plusieurs fois par frame
3. Les **read models** qui reconstruisent intégralement à chaque mutation au lieu d'être incrémentaux
4. Le **validation snapshot provider** qui re-lit le disque même quand le manifest n'a pas changé

---

## Problème 1 : Normalisation répétée dans le Global Search Index

**Fichier :** `packages/map_core/lib/src/read_models/narrative_global_search_index.dart:141-160`
**Sévérité :** Élevée (impact direct sur la fluidité de la palette de commandes)

### Diagnostic

La méthode `search()` de `NarrativeGlobalSearchIndex` appelle `_normalize()` sur **chaque champ de chaque entrée** à chaque recherche. Pour un index de 10 000 entrées, cela signifie :

- 10 000 × ~6 champs = ~60 000 appels à `_normalize()` par recherche
- Chaque `_normalize()` alloue un `StringBuffer`, itère rune par rune, applique `_foldedRune()`, et exécute une regex `RegExp(r'\s+')`

```dart
// narrative_global_search_index.dart:522-551
int? _scoreEntry(...) {
  final fields = <String>[
    label,                    // ← _normalize() appelé ici
    id,                       // ← _normalize() appelé ici
    if (entry.description != null) _normalize(entry.description!),
    ...entry.tags.map(_normalize),
    ...entry.keywords.map(_normalize),
    ...entry.consumerLabels.map(_normalize),
  ];
  // ...
}
```

### Impact

Le test de performance (`narrative_global_search_performance_test.dart`) montre que la recherche "fuzzy" sur 10k entrées prend p95 = 51 825 µs. La normalisation représente une part significative de ce temps.

### Solution

Pré-normaliser les entrées **à la construction de l'index** et stocker les valeurs normalisées dans `NarrativeGlobalSearchEntry`. La recherche ne ferait alors que des comparaisons directes sur des chaînes déjà normalisées.

```dart
// Dans NarrativeGlobalSearchEntry, ajouter :
final String normalizedLabel;
final String normalizedId;
final String? normalizedDescription;
final List<String> normalizedTags;
final List<String> normalizedKeywords;
final List<String> normalizedConsumerLabels;
```

**Gain estimé :** Réduction de 60-80% du temps de recherche sur de gros index.

---

## Problème 2 : Command Palette appelle `_items()` plusieurs fois par frame

**Fichier :** `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_command_palette.dart:139-184`
**Sévérité :** Moyenne

### Diagnostic

`_items()` est une méthode coûteuse (appelle `widget.index.search()`) mais elle est appelée :
1. Dans `build()` (ligne 190)
2. Dans `_moveSelection()` (ligne 172)
3. Dans `_activateSelected()` (ligne 180)

Quand l'utilisateur tape une lettre, `_setQuery()` appelle `setState()`, puis `build()` appelle `_items()`. Si l'utilisateur navigue avec les flèches, `_moveSelection()` appelle `_items()` **puis** `setState()` qui rappelle `build()` qui rappelle `_items()`.

```dart
void _moveSelection(int delta) {
  final items = _items(); // ← Premier appel coûteux
  if (items.isEmpty) return;
  setState(() {            // ← Déclenche build() → _items() à nouveau
    _selectedIndex = (_selectedIndex + delta).clamp(0, items.length - 1);
  });
}
```

### Solution

Mettre en cache le résultat de `_items()` dans un champ et ne le recalculer que quand `_query` ou `_queryRevision` changent :

```dart
List<_PaletteItem>? _cachedItems;
int _cachedQueryRevision = -1;

List<_PaletteItem> _items() {
  if (_cachedQueryRevision == _queryRevision && _cachedItems != null) {
    return _cachedItems!;
  }
  _cachedQueryRevision = _queryRevision;
  _cachedItems = _computeItems();
  return _cachedItems!;
}
```

**Gain estimé :** Division par 2 du nombre de recherches par interaction clavier.

---

## Problème 3 : Rechargement disque complet à chaque mutation d'Event

**Fichier :** `packages/map_editor/lib/src/application/use_cases/narrative_event_builder_v2_use_case.dart:764-835`
**Fichier :** `packages/map_editor/lib/src/features/narrative/state/narrative_event_builder_v2_providers.dart:72-93`
**Sévérité :** Élevée

### Diagnostic

Chaque appel à `_execute()` dans `NarrativeEventBuilderV2UseCase` :
1. Appelle `_prepareSession(projectPath)` qui lit `project.json` depuis le disque
2. Reconstruit le `NarrativeEventAuthoringSession` complet (spatial catalog, outcome catalog, etc.)
3. Applique la mutation
4. Persiste le résultat

De plus, le provider Riverpod `narrativeEventBuilderV2ReadModelProvider` est un `FutureProvider.autoDispose` — chaque navigation vers la route Event Builder déclenche un nouveau chargement disque complet.

Le test de performance (`narrative_event_authoring_snapshot_performance_test.dart`) montre que `session_prepare` pour 500 maps prend p95 = 1 250 000 µs (1.25 seconde).

### Solution

Maintenir un cache en mémoire de la session avec un fingerprint du manifest. Ne recharger depuis le disque que si le fingerprint a changé :

```dart
// Cache conceptuel dans le provider :
String? _cachedProjectPath;
String? _cachedFingerprint;
NarrativeEventAuthoringSession? _cachedSession;

Future<NarrativeEventAuthoringSession> _getSession(String projectPath) async {
  final currentFingerprint = /* hash du manifest en mémoire */;
  if (_cachedProjectPath == projectPath && 
      _cachedFingerprint == currentFingerprint &&
      _cachedSession != null) {
    return _cachedSession!;
  }
  _cachedSession = await NarrativeEventAuthoringSession.prepare(projectPath);
  _cachedFingerprint = currentFingerprint;
  _cachedProjectPath = projectPath;
  return _cachedSession!;
}
```

**Gain estimé :** Réduction de 80-90% du temps de mutation quand le manifest n'a pas changé.

---

## Problème 4 : Validation snapshot provider re-lit le disque inutilement

**Fichier :** `packages/map_editor/lib/src/features/narrative/state/narrative_event_builder_v2_providers.dart:130-177`
**Sévérité :** Moyenne

### Diagnostic

Le provider `narrativeEventValidationSnapshotLoaderProvider` appelle `NarrativeEventAuthoringSession.prepare()` à chaque invocation, même quand le manifest en mémoire n'a pas changé. Le fingerprint est vérifié **après** le chargement disque, ce qui annule le bénéfice du cache incrémental de validation.

```dart
return (request) async {
  final session = await NarrativeEventAuthoringSession.prepare( // ← Disque à chaque fois
    p.join(request.projectRootPath, 'project.json'),
  );
  if (narrativeEventBuilderV2ManifestFingerprint(session.manifest) !=
      request.expectedManifestFingerprint) {
    throw const NarrativeEventBuilderV2SnapshotMismatch();
  }
  // ... validation incrémentale ici
};
```

### Solution

Le fingerprint devrait être vérifié **avant** le chargement disque. Si le `request.expectedManifestFingerprint` correspond au cache, retourner directement le résultat de validation incrémentale sans recharger.

**Gain estimé :** Évitement d'un I/O disque complet sur les validations successives sans mutation.

---

## Problème 5 : `buildNarrativeDependencyIndex` itère toutes les maps à chaque appel

**Fichier :** `packages/map_core/lib/src/read_models/narrative_dependency_index.dart:467-472`
**Fichier :** `packages/map_editor/lib/src/application/use_cases/narrative_event_builder_v2_use_case.dart:456-458`
**Sévérité :** Moyenne

### Diagnostic

`buildNarrativeDependencyIndex()` est appelé dans `delete()` et `previewDelete()` du use case. Pour chaque appel, il :
- Itère toutes les maps, tous les entities, tous les triggers, tous les warps, toutes les connections
- Itère tous les events, toutes les scenes, tous les storylines, tous les cinematics
- Construit des listes triées et des maps de lookup

Pour un gros projet (500+ maps), c'est un O(n × m) significatif.

```dart
// narrative_event_builder_v2_use_case.dart:456
dependencyIndex: buildNarrativeDependencyIndex(
  project: session.manifest,
  maps: session.maps,        // ← Reconstruit à chaque delete
),
```

### Solution

Le `NarrativeDependencyIndex` devrait être construit une fois par session et mis en cache. Il ne change que quand le manifest ou les maps changent.

**Gain estimé :** Suppression d'un O(n × m) redondant par opération de suppression.

---

## Problème 6 : `narrativeWorkspaceProjectionProvider` se reconstruit sur tout changement de projet

**Fichier :** `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart:12-19`
**Sévérité :** Faible à Moyenne

### Diagnostic

Le provider utilise `ref.watch(editorNotifierProvider.select((s) => s.project))` — cela signifie que **tout changement** dans le projet (même sur des parties non narratives) déclenche une reconstruction complète de la projection narrative.

```dart
final narrativeWorkspaceProjectionProvider =
    Provider<NarrativeWorkspaceProjection?>((ref) {
  final project = ref.watch(editorNotifierProvider.select((s) => s.project));
  if (project == null) return null;
  return buildNarrativeWorkspaceProjection(project); // ← Reconstruction complète
});
```

### Solution

Soit utiliser un sélecteur plus fin (un fingerprint des parties narratives du projet), soit mettre en cache la projection avec un hash de comparaison.

**Gain estimé :** Élimination des reconstructions inutiles lors d'éditions non-narratives (maps, tilesets, etc.).

---

## Problème 7 : `_items()` dans le Command Palette crée des listes à chaque appel

**Fichier :** `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_command_palette.dart:139-161`
**Sévérité :** Faible

### Diagnostic

Chaque appel à `_items()` crée une nouvelle liste avec des `_PaletteItem` et appelle `widget.index.search()` qui crée une nouvelle `NarrativeGlobalSearchResponse` avec des listes triées et tronquées. Aucun de ces résultats n'est mis en cache.

De plus, `_moveSelection` appelle `_items()` pour obtenir la longueur, puis `setState()` redéclenche `build()` qui rappelle `_items()`.

### Solution

Combiné avec le Problème 2 : mettre en cache les items et ne les recalculer que sur changement de requête.

---

## Tableau récapitulatif

| # | Problème | Fichier | Sévérité | Gain estimé |
|---|----------|---------|----------|-------------|
| 1 | Normalisation répétée dans search | `narrative_global_search_index.dart` | Élevée | 60-80% recherche |
| 2 | `_items()` appelé plusieurs fois/frame | `narrative_command_palette.dart` | Moyenne | 50% recherches |
| 3 | Rechargement disque à chaque mutation | `narrative_event_builder_v2_use_case.dart` | Élevée | 80-90% mutation |
| 4 | Validation re-lit le disque inutilement | `narrative_event_builder_v2_providers.dart` | Moyenne | I/O évité |
| 5 | Dependency index reconstruit à chaque delete | `narrative_dependency_index.dart` | Moyenne | O(n×m) évité |
| 6 | Workspace projection trop réactive | `narrative_workspace_providers.dart` | Faible-Moyenne | Rebuilds évités |
| 7 | Listes recréées dans palette | `narrative_command_palette.dart` | Faible | GC réduit |

---

## Recommandations prioritaires

1. **Court terme (Problèmes 1 + 2)** : Pré-normaliser les entrées du search index + cacher les items du Command Palette. Impact immédiat sur la fluidité de la palette.

2. **Moyen terme (Problèmes 3 + 4)** : Introduire un cache de session avec fingerprint pour éviter les rechargements disque redondants. Impact majeur sur les opérations d'édition.

3. **Long terme (Problèmes 5 + 6)** : Mettre en cache le dependency index et raffiner la réactivité du workspace provider. Impact cumulatif sur les gros projets.

---

## Auto-critique

- Cette analyse est **read-only** : aucun code n'a été modifié, aucun test n'a été exécuté.
- Les gains estimés sont basés sur l'analyse statique du code et les résultats des tests de performance existants (budgets NSC-74). Les mesures réelles peuvent varier.
- Les tests de performance existants (`narrative_global_search_performance_test.dart`, `narrative_large_project_workspace_performance_test.dart`, `narrative_event_validation_incremental_performance_test.dart`) ont des budgets gelés qui passent — les problèmes identifiés sont donc des **optimisations possibles** plutôt que des **dépassements de budget**.
- Le problème 3 (rechargement disque) est le plus impactant en termes d'UX mais aussi le plus risqué à corriger (concurrence, cache invalidation).

---

## Fichiers analysés

### map_editor (UI + application)
- `lib/src/ui/canvas/narrative_studio/narrative_command_palette.dart`
- `lib/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart`
- `lib/src/ui/canvas/narrative_studio/narrative_studio_workspace_page.dart`
- `lib/src/ui/canvas/narrative_studio/narrative_studio_navigation.dart`
- `lib/src/application/services/narrative_event_validation_coordinator.dart`
- `lib/src/application/services/narrative_studio_validation_coordinator.dart`
- `lib/src/application/services/narrative_document_session.dart`
- `lib/src/application/use_cases/narrative_event_builder_v2_use_case.dart`
- `lib/src/features/narrative/state/narrative_workspace_providers.dart`
- `lib/src/features/narrative/state/narrative_event_builder_v2_providers.dart`

### map_core (read models)
- `lib/src/read_models/narrative_global_search_index.dart`
- `lib/src/read_models/narrative_event_validation_read_model.dart`
- `lib/src/read_models/narrative_event_source_index.dart`
- `lib/src/read_models/narrative_dependency_index.dart`
- `lib/src/read_models/narrative_event_builder_project_read_model.dart`
- `lib/src/read_models/narrative_event_reachability_report.dart`
- `lib/src/read_models/narrative_world_state_simulation.dart`

### Tests de performance existants
- `test/narrative_large_project_workspace_performance_test.dart`
- `test/narrative_global_search_performance_test.dart`
- `test/narrative_event_validation_incremental_performance_test.dart`
- `test/narrative_event_authoring_snapshot_performance_test.dart`
- `tool/narrative_event_phase_d_performance.dart`
