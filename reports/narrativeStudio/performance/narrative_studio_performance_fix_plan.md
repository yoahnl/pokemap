# Plan d'implémentation — Corrections de performance Narrative Studio

Ce document décrit les modifications exactes à apporter pour corriger les 7 problèmes de performance identifiés. Chaque étape est indépendante et peut être réalisée séparément.

---

## Étape 1 : Pré-normaliser les entrées du Global Search Index

**Priorité :** Haute
**Fichier :** `packages/map_core/lib/src/read_models/narrative_global_search_index.dart`
**Fichiers de test à adapter :** `packages/map_editor/test/narrative_global_search_performance_test.dart`

### 1.1 Ajouter des champs pré-normalisés dans `NarrativeGlobalSearchEntry`

À la ligne 25, la classe `NarrativeGlobalSearchEntry` a un constructeur `const`. Il faut ajouter des champs pour les valeurs pré-normalisées.

**Actuellement (lignes 25-57) :**
```dart
@immutable
final class NarrativeGlobalSearchEntry {
  const NarrativeGlobalSearchEntry({
    required this.kind,
    required this.technicalId,
    required this.label,
    this.description,
    this.tags = const [],
    this.keywords = const [],
    this.consumerLabels = const [],
    // ... autres champs
  });

  final String label;
  final String? description;
  final List<String> tags;
  final List<String> keywords;
  final List<String> consumerLabels;
  // ...
}
```

**À modifier :** Ajouter un second constructeur nommé qui pré-normalise tout :

```dart
@immutable
final class NarrativeGlobalSearchEntry {
  const NarrativeGlobalSearchEntry({
    required this.kind,
    required this.technicalId,
    required this.label,
    this.description,
    this.tags = const [],
    this.keywords = const [],
    this.consumerLabels = const [],
    this.mapId,
    this.storylineId,
    this.parentId,
    this.rootId,
    this.navigationIntent,
    this.diagnostic,
  })  : normalizedLabel = label,       // sera écrasé par le factory
        normalizedTechnicalId = technicalId,
        normalizedDescription = null,
        normalizedTags = const [],
        normalizedKeywords = const [],
        normalizedConsumerLabels = const [];

  /// Constructeur qui pré-normalise tous les champs texte pour la recherche.
  factory NarrativeGlobalSearchEntry.normalized({
    required NarrativeGlobalSearchKind kind,
    required String technicalId,
    required String label,
    String? description,
    List<String> tags = const [],
    List<String> keywords = const [],
    List<String> consumerLabels = const [],
    String? mapId,
    String? storylineId,
    String? parentId,
    String? rootId,
    NarrativeDependencyNavigationIntent? navigationIntent,
    NarrativeProjectDiagnostic? diagnostic,
  }) {
    return NarrativeGlobalSearchEntry(
      kind: kind,
      technicalId: technicalId,
      label: label,
      description: description,
      tags: tags,
      keywords: keywords,
      consumerLabels: consumerLabels,
      mapId: mapId,
      storylineId: storylineId,
      parentId: parentId,
      rootId: rootId,
      navigationIntent: navigationIntent,
      diagnostic: diagnostic,
    )
      ..normalizedLabel = _normalize(label)
      ..normalizedTechnicalId = _normalize(technicalId)
      ..normalizedDescription =
          description == null ? null : _normalize(description)
      ..normalizedTags = tags.map(_normalize).toList(growable: false)
      ..normalizedKeywords = keywords.map(_normalize).toList(growable: false)
      ..normalizedConsumerLabels =
          consumerLabels.map(_normalize).toList(growable: false);
  }

  final NarrativeGlobalSearchKind kind;
  final String technicalId;
  final String label;
  final String? description;
  final List<String> tags;
  final List<String> keywords;
  final List<String> consumerLabels;
  final String? mapId;
  final String? storylineId;
  final String? parentId;
  final String? rootId;
  final NarrativeDependencyNavigationIntent? navigationIntent;
  final NarrativeProjectDiagnostic? diagnostic;

  // Champs pré-normalisés (remplis par le factory .normalized)
  late final String normalizedLabel;
  late final String normalizedTechnicalId;
  late final String? normalizedDescription;
  late final List<String> normalizedTags;
  late final List<String> normalizedKeywords;
  late final List<String> normalizedConsumerLabels;

  String get stableKey => '${kind.name}:$technicalId';
}
```

> **Note :** `late final` fonctionne ici car les champs sont assignés exactement une fois dans le factory constructor. L'ancien constructeur `const` assigne des valeurs par défaut (identiques aux originales) qui seront écrasées par le factory.

### 1.2 Modifier `_scoreEntry` pour utiliser les champs pré-normalisés

**Actuellement (lignes 522-551) :**
```dart
int? _scoreEntry(
  NarrativeGlobalSearchEntry entry,
  String query,
  List<String> tokens,
) {
  if (tokens.isEmpty) return 0;
  final label = _normalize(entry.label);           // ← SUPPRIMER
  final id = _normalize(entry.technicalId);         // ← SUPPRIMER
  final fields = <String>[
    label,
    id,
    if (entry.description != null) _normalize(entry.description!),  // ← SUPPRIMER
    ...entry.tags.map(_normalize),                                  // ← SUPPRIMER
    ...entry.keywords.map(_normalize),                              // ← SUPPRIMER
    ...entry.consumerLabels.map(_normalize),                        // ← SUPPRIMER
  ];
  // ... reste identique
  if (label == query) score += 1200;
  if (id == query) score += 1100;
  return score;
}
```

**À modifier :**
```dart
int? _scoreEntry(
  NarrativeGlobalSearchEntry entry,
  String query,
  List<String> tokens,
) {
  if (tokens.isEmpty) return 0;
  final label = entry.normalizedLabel;
  final id = entry.normalizedTechnicalId;
  final fields = <String>[
    label,
    id,
    if (entry.normalizedDescription != null) entry.normalizedDescription!,
    ...entry.normalizedTags,
    ...entry.normalizedKeywords,
    ...entry.normalizedConsumerLabels,
  ];
  var score = 0;
  for (final token in tokens) {
    var best = -1;
    for (var index = 0; index < fields.length; index++) {
      final field = fields[index];
      final candidate = _fieldScore(field, token, index);
      if (candidate > best) best = candidate;
    }
    if (best < 0) return null;
    score += best;
  }
  if (label == query) score += 1200;
  if (id == query) score += 1100;
  return score;
}
```

### 1.3 Modifier `buildNarrativeGlobalSearchIndex` pour utiliser le factory

Dans la fonction `buildNarrativeGlobalSearchIndex` (ligne 163), la closure interne `add()` crée des `NarrativeGlobalSearchEntry`. Remplacer l'appel au constructeur par le factory `.normalized()`.

**Actuellement (ligne 202) :**
```dart
entries.add(
  NarrativeGlobalSearchEntry(
    kind: kind,
    id: id,
    label: label,
    // ...
  ),
);
```

**À modifier :**
```dart
entries.add(
  NarrativeGlobalSearchEntry.normalized(
    kind: kind,
    technicalId: id,
    label: label,
    // ... tous les autres paramètres identiques
  ),
);
```

### 1.4 Vérification

Lancer le test de performance existant :
```bash
cd packages/map_editor && flutter test test/narrative_global_search_performance_test.dart
```

Le budget p95 de 220 000 µs doit toujours passer. Avec la pré-normalisation, le temps de recherche devrait chuter de ~50k µs à ~10k µs.

---

## Étape 2 : Cache des items dans le Command Palette

**Priorité :** Haute
**Fichier :** `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_command_palette.dart`

### 2.1 Ajouter un cache dans `_NarrativeCommandPaletteState`

**Actuellement (lignes 125-131) :**
```dart
class _NarrativeCommandPaletteState extends State<NarrativeCommandPalette> {
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _searchFocus = FocusNode(debugLabel: 'command-palette');
  String _query = '';
  int _queryRevision = 0;
  int _selectedIndex = -1;
```

**À modifier :**
```dart
class _NarrativeCommandPaletteState extends State<NarrativeCommandPalette> {
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _searchFocus = FocusNode(debugLabel: 'command-palette');
  String _query = '';
  int _queryRevision = 0;
  int _selectedIndex = -1;

  // Cache pour éviter les recalculs multiples par frame
  List<_PaletteItem>? _cachedItems;
  int _cachedItemsRevision = -1;
```

### 2.2 Modifier `_items()` pour utiliser le cache

**Actuellement (lignes 139-161) :**
```dart
List<_PaletteItem> _items() {
  final normalized = _query.trim().toLowerCase();
  final actions = widget.actions.where((action) { ... });
  final response = widget.index.search(...);
  if (response.isStaleComparedTo(widget.index) || ...) {
    return const [];
  }
  return [ ... ];
}
```

**À modifier :**
```dart
List<_PaletteItem> _items() {
  if (_cachedItemsRevision == _queryRevision && _cachedItems != null) {
    return _cachedItems!;
  }
  final normalized = _query.trim().toLowerCase();
  final actions = widget.actions.where((action) {
    if (normalized.isEmpty) return true;
    return action.label.toLowerCase().contains(normalized) ||
        action.id.toLowerCase().contains(normalized);
  });
  final response = widget.index.search(
    NarrativeGlobalSearchQuery(
      text: _query,
      limit: 40,
      requestRevision: _queryRevision,
    ),
  );
  if (response.isStaleComparedTo(widget.index) ||
      response.requestRevision != _queryRevision) {
    _cachedItems = const [];
    _cachedItemsRevision = _queryRevision;
    return _cachedItems!;
  }
  _cachedItems = [
    for (final action in actions) _PaletteItem.action(action),
    for (final result in response.results) _PaletteItem.entry(result.entry),
  ];
  _cachedItemsRevision = _queryRevision;
  return _cachedItems!;
}
```

### 2.3 Invalider le cache dans `_setQuery`

**Actuellement (lignes 163-169) :**
```dart
void _setQuery(String value) {
  setState(() {
    _query = value;
    _queryRevision++;
    _selectedIndex = -1;
  });
}
```

**À modifier :** Pas de changement nécessaire — `_queryRevision++` suffit car `_items()` compare `_cachedItemsRevision` avec `_queryRevision`.

### 2.4 Vérification

Lancer les tests du Command Palette :
```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_command_palette_test.dart
```

---

## Étape 3 : Cache de session avec fingerprint pour les mutations Event

**Priorité :** Haute
**Fichiers :**
- `packages/map_editor/lib/src/application/use_cases/narrative_event_builder_v2_use_case.dart`
- `packages/map_editor/lib/src/features/narrative/state/narrative_event_builder_v2_providers.dart`

### 3.1 Ajouter un cache de session dans le use case

**Actuellement (lignes 183-199) :**
```dart
final class NarrativeEventBuilderV2UseCase {
  NarrativeEventBuilderV2UseCase({
    required NarrativeEventRegistryPersistenceGateway persistenceGateway,
    PrepareNarrativeEventBuilderV2Session? prepareSession,
    // ...
  })  : _persistenceGateway = persistenceGateway,
        _prepareSession = prepareSession ?? NarrativeEventAuthoringSession.prepare,
        // ...

  final NarrativeEventRegistryPersistenceGateway _persistenceGateway;
  final PrepareNarrativeEventBuilderV2Session _prepareSession;
  // ...
```

**À modifier :** Ajouter un cache interne avec fingerprint :

```dart
final class NarrativeEventBuilderV2UseCase {
  NarrativeEventBuilderV2UseCase({
    required NarrativeEventRegistryPersistenceGateway persistenceGateway,
    PrepareNarrativeEventBuilderV2Session? prepareSession,
    NarrativeEventBuilderV2IdGeneratorFactory? idGeneratorFactory,
    String Function()? operationIdFactory,
  })  : _persistenceGateway = persistenceGateway,
        _prepareSession = prepareSession ?? NarrativeEventAuthoringSession.prepare,
        _idGeneratorFactory = idGeneratorFactory ?? NarrativeEventIdGenerator.new,
        _operationIdFactory = operationIdFactory ?? _defaultOperationId;

  final NarrativeEventRegistryPersistenceGateway _persistenceGateway;
  final PrepareNarrativeEventBuilderV2Session _prepareSession;
  final NarrativeEventBuilderV2IdGeneratorFactory _idGeneratorFactory;
  final String Function() _operationIdFactory;

  // --- Cache de session ---
  String? _cachedProjectPath;
  String? _cachedFingerprint;
  NarrativeEventAuthoringSession? _cachedSession;

  Future<NarrativeEventAuthoringSession> _getOrCreateSession(
    String projectPath,
  ) async {
    final normalizedPath = projectPath; // déjà normalisé par l'appelant
    final session = _cachedSession;
    if (session != null && _cachedProjectPath == normalizedPath) {
      // Vérifier que le manifest en mémoire correspond toujours
      final currentFingerprint = narrativeEventBuilderV2ManifestFingerprint(
        session.manifest,
      );
      if (currentFingerprint == _cachedFingerprint) {
        return session;
      }
    }
    final freshSession = await _prepareSession(normalizedPath);
    _cachedProjectPath = normalizedPath;
    _cachedFingerprint = narrativeEventBuilderV2ManifestFingerprint(
      freshSession.manifest,
    );
    _cachedSession = freshSession;
    return freshSession;
  }

  /// À appeler après une écriture réussie pour invalider le cache.
  void invalidateSessionCache() {
    _cachedSession = null;
    _cachedFingerprint = null;
    _cachedProjectPath = null;
  }
```

### 3.2 Remplacer les appels à `_prepareSession` par `_getOrCreateSession`

Dans `_execute()` (ligne 776) :
```dart
// AVANT :
session = await _prepareSession(projectPath);

// APRÈS :
session = await _getOrCreateSession(projectPath);
```

Dans `loadEditorSnapshot()` (ligne 205) :
```dart
// AVANT :
final session = await _prepareSession(projectPath);

// APRÈS :
final session = await _getOrCreateSession(projectPath);
```

Dans `simulate()` (ligne 238) :
```dart
// AVANT :
final session = await _prepareSession(projectPath);

// APRÈS :
final session = await _getOrCreateSession(projectPath);
```

### 3.3 Invalider le cache après une écriture réussie

Dans `_execute()`, après la persistance réussie (ligne 827), ajouter l'invalidation :

```dart
// Après persistence réussie :
invalidateSessionCache();

return NarrativeEventBuilderV2WriteResult(
  status: _writeStatus(persistence),
  // ...
);
```

### 3.4 Adapter le provider de validation

Dans `narrative_event_builder_v2_providers.dart`, le provider `narrativeEventValidationSnapshotLoaderProvider` (ligne 130) fait aussi un `prepare()`. Le cache du use case ne couvre pas ce provider car c'est une closure séparée. Pour ce provider, la solution est de vérifier le fingerprint **avant** de lire le disque :

**Actuellement (lignes 136-177) :**
```dart
return (request) async {
  final session = await NarrativeEventAuthoringSession.prepare(
    p.join(request.projectRootPath, 'project.json'),
  );
  if (narrativeEventBuilderV2ManifestFingerprint(session.manifest) !=
      request.expectedManifestFingerprint) {
    throw const NarrativeEventBuilderV2SnapshotMismatch();
  }
  // ... validation
};
```

**À modifier :** Ajouter un cache local dans la closure :

```dart
return (request) async {
  // Cache local : si le fingerprint n'a pas changé, on peut réutiliser
  // le résultat de validation incrémentale précédent
  if (cachedRequest != null &&
      cachedRequest!.projectRootPath == request.projectRootPath &&
      cachedRequest!.expectedManifestFingerprint ==
          request.expectedManifestFingerprint &&
      cachedSnapshot != null) {
    return cachedSnapshot!;
  }

  final session = await NarrativeEventAuthoringSession.prepare(
    p.join(request.projectRootPath, 'project.json'),
  );
  if (narrativeEventBuilderV2ManifestFingerprint(session.manifest) !=
      request.expectedManifestFingerprint) {
    throw const NarrativeEventBuilderV2SnapshotMismatch();
  }
  // ... validation existante ...

  cachedRequest = request;
  cachedSnapshot = result;
  return result;
};
```

Ajouter les variables de cache au début de la closure (ligne 132) :
```dart
return (request) async {
  NarrativeEventBuilderV2SnapshotRequest? cachedRequest;
  NarrativeEventValidationSnapshot? cachedSnapshot;
  // ... existing cache variables
```

### 3.5 Vérification

```bash
cd packages/map_editor && flutter test test/narrative_event_authoring_snapshot_performance_test.dart
cd packages/map_editor && flutter test test/narrative_event_builder_v2_use_case_test.dart
```

---

## Étape 4 : Ne pas reconstruire le Dependency Index à chaque delete

**Priorité :** Moyenne
**Fichier :** `packages/map_editor/lib/src/application/use_cases/narrative_event_builder_v2_use_case.dart`

### 4.1 Passer le dependency index en paramètre optionnel

**Actuellement (lignes 443-462) :**
```dart
Future<NarrativeEventBuilderV2WriteResult> delete({
  required String projectPath,
  required String eventId,
  required NarrativeEventBuilderV2WriteEnvironment environment,
}) {
  return _executeForEvent(
    projectPath: projectPath,
    eventId: eventId,
    environment: environment,
    author: (session) => deleteNarrativeEvent(
      context: session.context,
      expectedRevision: session.projectRevision,
      eventId: eventId,
      dependencyIndex: buildNarrativeDependencyIndex(
        project: session.manifest,
        maps: session.maps,
      ),
    ),
  );
}
```

**À modifier :** Utiliser un dependency index mis en cache dans le use case :

```dart
// Ajouter un champ cache dans NarrativeEventBuilderV2UseCase :
NarrativeDependencyIndex? _cachedDependencyIndex;
String? _dependencyIndexProjectPath;

Future<NarrativeEventBuilderV2WriteResult> delete({
  required String projectPath,
  required String eventId,
  required NarrativeEventBuilderV2WriteEnvironment environment,
  NarrativeDependencyIndex? dependencyIndex,
}) {
  return _executeForEvent(
    projectPath: projectPath,
    eventId: eventId,
    environment: environment,
    author: (session) {
      final index = dependencyIndex ?? _getOrCreateDependencyIndex(
        projectPath,
        session.manifest,
        session.maps,
      );
      return deleteNarrativeEvent(
        context: session.context,
        expectedRevision: session.projectRevision,
        eventId: eventId,
        dependencyIndex: index,
      );
    },
  );
}

NarrativeDependencyIndex _getOrCreateDependencyIndex(
  String projectPath,
  ProjectManifest manifest,
  List<MapData> maps,
) {
  if (_cachedDependencyIndex != null && _dependencyIndexProjectPath == projectPath) {
    return _cachedDependencyIndex!;
  }
  _cachedDependencyIndex = buildNarrativeDependencyIndex(
    project: manifest,
    maps: maps,
  );
  _dependencyIndexProjectPath = projectPath;
  return _cachedDependencyIndex!;
}
```

Invalider `_cachedDependencyIndex` dans `invalidateSessionCache()`.

### 4.2 Vérification

```bash
cd packages/map_editor && flutter test test/narrative_event_lifecycle_authoring_test.dart
```

---

## Étape 5 : Affiner la réactivité du workspace projection provider

**Priorité :** Faible-Moyenne
**Fichier :** `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart`

### 5.1 Utiliser un sélecteur plus fin

**Actuellement (lignes 12-19) :**
```dart
final narrativeWorkspaceProjectionProvider =
    Provider<NarrativeWorkspaceProjection?>((ref) {
  final project = ref.watch(editorNotifierProvider.select((s) => s.project));
  if (project == null) return null;
  return buildNarrativeWorkspaceProjection(project);
});
```

**À modifier :** Sélectionner uniquement les parties narratives du projet pour éviter les reconstructions sur des changements non-narratifs :

```dart
final narrativeWorkspaceProjectionProvider =
    Provider<NarrativeWorkspaceProjection?>((ref) {
  final project = ref.watch(editorNotifierProvider.select((s) => s.project));
  if (project == null) return null;

  // Construire un fingerprint léger des seules parties narratives
  final narrativeFingerprint = _narrativeFingerprint(project);
  final previous = ref.read(_narrativeFingerprintProvider);
  if (previous == narrativeFingerprint) {
    return ref.read(_cachedProjectionProvider);
  }

  final projection = buildNarrativeWorkspaceProjection(project);
  ref.read(_narrativeFingerprintProvider.notifier).state = narrativeFingerprint;
  ref.read(_cachedProjectionProvider.notifier).state = projection;
  return projection;
});

// Providers internes de cache
final _narrativeFingerprintProvider = StateProvider<String?>((ref) => null);
final _cachedProjectionProvider = StateProvider<NarrativeWorkspaceProjection?>((ref) => null);

String _narrativeFingerprint(ProjectManifest project) {
  // Hash léger des seules propriétés narratives
  final buffer = StringBuffer()
    ..write(project.storylines.length)
    ..write(':')
    ..write(project.scenes.length)
    ..write(':')
    ..write(project.eventRegistry?.records.length ?? 0)
    ..write(':')
    ..write(project.facts.length)
    ..write(':')
    ..write(project.worldRules.length)
    ..write(':')
    ..write(project.cinematics.length)
    ..write(':')
    ..write(project.dialogues.length);
  return buffer.toString();
}
```

> **Attention :** Ce fingerprint est volontairement grossier — il détecte les changements de taille mais pas les modifications internes. Si un storyline est renommé sans changer la taille, le fingerprint ne changera pas. C'est acceptable pour la projection workspace qui est une vue d'ensemble.

### 5.2 Vérification

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart
```

---

## Étape 6 : Vérification globale

Après toutes les modifications, lancer la suite complète :

```bash
# Tests map_core
cd packages/map_core && dart test && dart analyze

# Tests map_editor
cd packages/map_editor && flutter test && flutter analyze

# Tests de performance spécifiques
cd packages/map_editor && flutter test test/narrative_global_search_performance_test.dart
cd packages/map_editor && flutter test test/narrative_large_project_workspace_performance_test.dart
cd packages/map_editor && flutter test test/narrative_event_validation_incremental_performance_test.dart
cd packages/map_editor && flutter test test/narrative_event_authoring_snapshot_performance_test.dart
```

---

## Résumé des modifications par fichier

| Fichier | Étape | Nature du changement |
|---------|-------|---------------------|
| `map_core/.../narrative_global_search_index.dart` | 1 | Ajouter factory `.normalized()`, champs `normalizedXxx`, modifier `_scoreEntry` |
| `map_editor/.../narrative_command_palette.dart` | 2 | Ajouter `_cachedItems`/`_cachedItemsRevision`, modifier `_items()` |
| `map_editor/.../narrative_event_builder_v2_use_case.dart` | 3+4 | Ajouter cache session + dependency index, invalider après écriture |
| `map_editor/.../narrative_event_builder_v2_providers.dart` | 3 | Ajouter cache fingerprint dans la closure du loader |
| `map_editor/.../narrative_workspace_providers.dart` | 5 | Sélecteur plus fin avec fingerprint narrative |

---

## Risques et garde-fous

1. **Cache invalidation** : Le risque principal est de servir des données périmées. Les invalidations sont déclenchées après chaque écriture réussie (`invalidateSessionCache()`). Si un doute existe, mieux vaut invalider trop que pas assez.

2. **`late final` dans `NarrativeGlobalSearchEntry`** : Le constructeur `const` existant assigne des valeurs par défaut aux champs `normalizedXxx`. Ces valeurs seront identiques aux originales (pas de normalisation). Seul le factory `.normalized()` produit les vraies valeurs normalisées. C'est acceptable car `buildNarrativeGlobalSearchIndex` utilise le factory, et les tests directs qui utilisent le constructeur `const` fonctionnent toujours (la recherche retourne les mêmes résultats, juste sans le gain de performance).

3. **Fingerprint grossier (étape 5)** : Le workspace projection pourrait ne pas se reconstruire si un champ interne change sans changer la taille. C'est un compromis acceptable pour cette vue d'ensemble.

4. **Tests existants** : Aucun test de comportement ne devrait casser. Les tests de performance devraient montrer des améliorations ou rester dans les budgets.
