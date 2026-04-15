# M3-bis — Durcissement canonique vs legacy dans la lecture locale du catalogue moves

## 1. Résumé exécutif honnête

M3-bis a été livré comme un mini-fix strictement borné.

Le problème traité était unique :
- la lecture locale du catalogue moves pouvait encore laisser une entrée partiellement canonique glisser vers le fallback legacy si elle n'activait pas la détection canonique trop stricte.

Le correctif appliqué :
- remplace la détection canonique stricte par une détection canonique volontairement large ;
- introduit une détection legacy volontairement étroite ;
- fait échouer explicitement toute entrée qui ressemble au canonique mais ne parse pas ;
- fait échouer explicitement toute forme inconnue ou ambiguë ;
- laisse le fallback legacy uniquement aux vraies entrées legacy ;
- ne touche qu'aux deux fichiers autorisés.

Ce que le lot ne fait pas :
- aucun changement dans le convertisseur Showdown ;
- aucun changement dans `map_core` ;
- aucun changement dans `map_runtime` ;
- aucun changement dans `map_battle` ;
- aucun seed / bootstrap / UI / validation globale ;
- aucune écriture Git.

## 2. Problème réel traité

Le point faible restant après M3 était dans `LoadPokemonMovesCatalogUseCase._projectEntry(...)`.

État réel avant M3-bis :
- une entrée n'était traitée comme canonique que si plusieurs marqueurs précis étaient déjà tous présents ;
- sinon, elle retombait vers la projection legacy ;
- donc une entrée partiellement canonique mais incomplète pouvait encore être silencieusement lue comme legacy.

Exemple de trou métier :
- une entrée avec `basePower` mais `accuracy` scalaire n'est pas une vraie entrée legacy ;
- c'est une entrée canonique cassée ;
- pourtant la logique précédente pouvait encore la laisser passer côté fallback legacy si elle ne cochait pas tous les critères stricts du détecteur canonique.

M3-bis ferme précisément cette brèche.

## 3. Périmètre inclus / exclu

### 3.1. Inclus

- `packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart`
- `packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart`
- report final

### 3.2. Exclus

- `packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart`
- `packages/map_core/...`
- `packages/map_runtime/...`
- `packages/map_battle/...`
- seed
- bootstrap projet
- UI
- convertisseur Showdown
- merge policy générale hors stricte classification canonique vs legacy
- nouvelles abstractions publiques
- Git

## 4. Fichiers modifiés / créés

### 4.1. Modifiés

- `packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart`
- `packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart`

### 4.2. Créés

- `reports/phase-moves-m3-bis-canonical-legacy-hardening-report.md`

### 4.3. Supprimés

- aucun

## 5. Justification fichier par fichier

### `packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart`

Modifications apportées :
- remplacement de `_isCanonicalMoveEntry(...)` par :
  - `_looksLikeCanonicalMoveEntry(...)`
  - `_looksLikeLegacyMoveEntry(...)`
- durcissement de `_projectEntry(...)` avec logique stricte :
  1. si l'entrée ressemble au canonique, on tente `PokemonMove.fromJson(entry)` ;
  2. si le parse échoue, on jette une `EditorPersistenceException` explicite ;
  3. sinon, seulement si l'entrée ressemble au legacy, on utilise la projection legacy ;
  4. sinon, on jette une erreur explicite de forme inconnue/non supportée.
- remplacement de la vérification de merge pour réutiliser la détection canonique large.

Raison :
- c'est le seul seam métier qui devait être durci pour empêcher la rétrogradation silencieuse canonique -> legacy.

### `packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart`

Modifications apportées :
- ajout d'un helper local pour charger rapidement une vue à partir d'un catalogue synthétique ;
- conservation des tests M3 déjà utiles ;
- ajout de preuves ciblées M3-bis pour :
  - une entrée canonique valide ;
  - une entrée `basePower` + `accuracy` scalaire qui doit échouer comme canonique invalide ;
  - une entrée avec autre marqueur canonique (`effects`) qui doit aussi échouer ;
  - une vraie entrée legacy qui continue à passer ;
  - une forme inconnue qui échoue explicitement.

Raison :
- le mini-fix n'est crédible que si la frontière canonique vs legacy est prouvée explicitement par les tests.

## 6. Commandes réellement exécutées

### 6.1. Audit

```bash
git status --short
sed -n '160,280p' packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart
sed -n '1,260p' packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart
sed -n '260,420p' packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart
rg -n "_isCanonicalMoveEntry|_obsoleteLegacyMoveFields|_encodeTarget" packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart
sed -n '520,550p' packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart
```

### 6.2. Format

```bash
/opt/homebrew/bin/dart format packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart
```

### 6.3. Analyze

```bash
/opt/homebrew/bin/flutter analyze --no-pub lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart test/sync_pokemon_moves_catalog_use_case_test.dart
```

### 6.4. Tests

```bash
/opt/homebrew/bin/flutter test test/sync_pokemon_moves_catalog_use_case_test.dart
```

### 6.5. Review séparée

Reviewer séparé utilisé pour relire strictement :
- `packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart`
- `packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart`

### 6.6. État git final

```bash
git status --short
git diff --stat -- packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart
git ls-files --others --exclude-standard
wc -l packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart
```

## 7. Résultats réels de format / analyze / tests

### 7.1. Format

Résultat : OK

Sortie utile :

```text
Formatted packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart
Formatted 2 files (1 changed) in 0.01 seconds.
```

### 7.2. Analyze

Résultat : OK

Sortie utile :

```text
Analyzing 2 items...
No issues found! (ran in 2.1s)
```

### 7.3. Tests

Résultat : OK

Sortie utile :

```text
00:01 +8: All tests passed!
```

## 8. Incidents rencontrés

1. `flutter analyze` et `flutter test` se sont brièvement sérialisés via le startup lock Flutter :

```text
Waiting for another flutter command to release the startup lock...
```

Cela s'est résolu proprement sans intervention particulière.

2. Aucun incident métier ou de compilation supplémentaire après le patch.

## 9. État git utile

### `git status --short`

```text
 M packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart
 M packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart
?? .DS_Store
?? reports/phase-moves-m3-bis-canonical-legacy-hardening-report.md
```

### `git diff --stat -- ...`

```text
 .../sync_pokemon_moves_catalog_use_case.dart       |  62 ++++--
 .../sync_pokemon_moves_catalog_use_case_test.dart  | 210 +++++++++++++++++++--
 2 files changed, 248 insertions(+), 24 deletions(-)
```

### Fichiers non suivis

```text
.DS_Store
reports/phase-moves-m3-bis-canonical-legacy-hardening-report.md
```

Note honnête :
- `.DS_Store` était déjà non suivi et hors scope ;
- aucune écriture Git n'a été faite.

## 10. Checklist finale

- [x] une entrée partiellement canonique ne peut plus être rétrogradée silencieusement en legacy
- [x] une vraie entrée legacy continue à fonctionner
- [x] une forme ambiguë ou invalide échoue honnêtement
- [x] le scope reste strictement borné aux deux fichiers autorisés
- [x] le reviewer séparé n’a pas trouvé de fuite non corrigée
- [x] analyze ciblé est vert
- [x] tests ciblés sont verts
- [x] aucune écriture Git interdite n’a été faite
- [x] le report est honnête
- [x] le report contient le contenu complet des fichiers texte touchés

## 11. Retour du reviewer séparé

Retour du reviewer séparé :

```text
No material findings.

The mini-fix does what it claims for the requested boundary: canonical-looking entries are now broad-gated before legacy projection, true legacy rows still pass, unknown/ambiguous shapes fail explicitly, and the diff stayed confined to the two requested files. The only unrelated workspace noise is the pre-existing untracked `.DS_Store`.
```

## 12. Corrections appliquées après review

Aucune correction supplémentaire n'a été nécessaire.

Le reviewer n'a relevé :
- aucune fuite de downgrade silencieux restante ;
- aucune régression du fallback legacy ;
- aucun débordement de scope ;
- aucun changement parasite.

## 13. Limites restantes

Limites volontairement hors scope :
- le convertisseur Showdown lui-même n'a pas été modifié ;
- la validation projet globale n'a pas été enrichie ;
- le runtime et le battle engine n'ont pas été touchés ;
- ce mini-fix ne traite que la frontière de lecture locale canonique vs legacy.

## 14. Conclusion honnête

M3-bis ferme proprement le dernier trou de classification locale identifié après M3.

Le comportement final est maintenant celui demandé :
- dès qu'une entrée ressemble au canonique, elle est traitée comme candidate canonique ;
- si elle ne parse pas, on échoue explicitement ;
- le fallback legacy reste réservé aux vraies formes legacy ;
- une forme inconnue échoue honnêtement ;
- aucun scope adjacent n'a été rouvert.

## 15. Annexe — contenu complet de tous les fichiers texte touchés

Le report s'exclut lui-même de cette annexe pour éviter la récursion infinie.

### `packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart`

```dart
import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_external_source_repository.dart';
import '../ports/pokemon_read_repository.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';
import '../services/showdown_move_catalog_converter.dart';

/// Projection légère d'une entrée du catalogue local des attaques.
///
/// Cette vue existe pour deux besoins strictement 11B :
/// - afficher une liste locale lisible dans l'éditeur ;
/// - éviter que l'UI reparte du JSON brut pour interpréter les champs.
///
/// Non-objectifs assumés :
/// - ce n'est pas un nouveau modèle métier transverse ;
/// - ce n'est pas une "Move Library" complète ;
/// - on ne cherche pas à capturer toutes les subtilités battle de Showdown.
class PokemonMoveCatalogEntryView {
  const PokemonMoveCatalogEntryView({
    required this.id,
    required this.name,
    this.type,
    this.category,
    this.power,
    this.accuracy,
    this.accuracyText,
    this.pp,
    this.priority,
    this.target,
    this.shortDesc,
    this.generation,
  });

  final String id;
  final String name;
  final String? type;
  final String? category;
  final int? power;
  final num? accuracy;
  final String? accuracyText;
  final int? pp;
  final int? priority;
  final String? target;
  final String? shortDesc;
  final int? generation;

  String get accuracyLabel {
    if (accuracy != null) {
      return accuracy!.toString();
    }
    if (accuracyText != null && accuracyText!.trim().isNotEmpty) {
      return accuracyText!;
    }
    return '-';
  }
}

/// État lisible du catalogue moves local pour l'éditeur.
///
/// L'UI a besoin d'une réponse honnête sur deux choses distinctes :
/// - le catalogue existe-t-il et a-t-il pu être lu ;
/// - quelles entrées locales sont effectivement disponibles.
///
/// On sépare donc clairement le message de statut des entrées elles-mêmes.
class PokemonMovesCatalogView {
  const PokemonMovesCatalogView({
    required this.entries,
    required this.isAvailable,
    required this.description,
    this.message,
  });

  final List<PokemonMoveCatalogEntryView> entries;
  final bool isAvailable;
  final String description;
  final String? message;
}

/// Résultat d'une preview ou d'une synchronisation réelle du catalogue moves.
///
/// Le use case reste volontairement déterministe :
/// - aucune merge policy "UI-configurable" supplémentaire n'est introduite ;
/// - la stratégie retenue est un merge par id, avec préservation des entrées
///   locales absentes de la source distante et des champs locaux non gérés ;
/// - le résultat expose donc uniquement les compteurs et ids utiles à l'UI.
class PokemonMovesCatalogSyncResult {
  const PokemonMovesCatalogSyncResult({
    required this.dryRun,
    required this.externalEntryCount,
    required this.createdIds,
    required this.updatedIds,
    required this.unchangedIds,
    required this.preservedLocalOnlyIds,
    required this.resultingEntryCount,
    this.warnings = const <String>[],
  });

  final bool dryRun;
  final int externalEntryCount;
  final List<String> createdIds;
  final List<String> updatedIds;
  final List<String> unchangedIds;
  final List<String> preservedLocalOnlyIds;
  final int resultingEntryCount;
  final List<String> warnings;

  int get createdCount => createdIds.length;
  int get updatedCount => updatedIds.length;
  int get unchangedCount => unchangedIds.length;
  int get preservedLocalOnlyCount => preservedLocalOnlyIds.length;
}

/// Charge le catalogue local des attaques pour la surface éditeur minimale.
///
/// Ce use case reste volontairement simple :
/// - il lit exclusivement `catalogs/moves.json` via le repository existant ;
/// - il projette des entrées lisibles ;
/// - il ne tente aucune réparation automatique ni enrichissement externe.
class LoadPokemonMovesCatalogUseCase {
  const LoadPokemonMovesCatalogUseCase({
    required this.readRepository,
  });

  final PokemonReadRepository readRepository;

  Future<PokemonMovesCatalogView> execute(ProjectWorkspace workspace) async {
    try {
      final catalog = await readRepository.readCatalogByKey(workspace, 'moves');
      return PokemonMovesCatalogView(
        entries: _projectEntries(catalog),
        isAvailable: true,
        description: catalog.meta.description.trim().isEmpty
            ? 'Catalogue local des attaques.'
            : catalog.meta.description.trim(),
      );
    } on EditorNotFoundException catch (error) {
      return PokemonMovesCatalogView(
        entries: const <PokemonMoveCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des attaques indisponible.',
        message: error.message,
      );
    } on EditorApplicationException catch (error) {
      return PokemonMovesCatalogView(
        entries: const <PokemonMoveCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des attaques illisible.',
        message: error.message,
      );
    }
  }

  List<PokemonMoveCatalogEntryView> _projectEntries(
      PokemonCatalogFile catalog) {
    final entries = catalog.entries
        .map(_projectEntry)
        .whereType<PokemonMoveCatalogEntryView>()
        .toList(growable: false)
      ..sort((left, right) {
        final nameCompare = left.name.compareTo(right.name);
        if (nameCompare != 0) {
          return nameCompare;
        }
        return left.id.compareTo(right.id);
      });
    return entries;
  }

  PokemonMoveCatalogEntryView? _projectEntry(Map<String, dynamic> entry) {
    // M3 introduit des entrées canoniques `PokemonMove.toJson()`, mais le
    // catalogue projet peut encore contenir des entrées legacy locales non
    // resynchronisées.
    //
    // M3-bis durcit volontairement la frontière :
    // - la détection canonique devient large ;
    // - la détection legacy devient étroite ;
    // - si une entrée "sent" le canonique, on la traite comme canonique ;
    // - si le parse canonique échoue, on remonte une erreur explicite ;
    // - le fallback legacy ne sert plus qu'aux vraies formes legacy.
    //
    // Cette asymétrie est voulue :
    // - mieux vaut échouer tôt sur une entrée canonique cassée ;
    // - que la dégrader silencieusement vers la vieille projection legacy.
    if (_looksLikeCanonicalMoveEntry(entry)) {
      try {
        final move = PokemonMove.fromJson(entry);
        return PokemonMoveCatalogEntryView(
          id: move.id,
          name: move.name,
          type: move.type,
          category: move.category.name,
          power: move.usesStandardDamageFlow ? move.basePower : null,
          accuracy: move.accuracy.map(
            percent: (value) => value.value,
            alwaysHits: (_) => null,
          ),
          accuracyText: move.accuracy.maybeMap(
            alwaysHits: (_) => 'always',
            orElse: () => null,
          ),
          pp: move.pp,
          priority: move.priority,
          target: _encodeTarget(move.target),
          shortDesc:
              move.shortDescription.isEmpty ? null : move.shortDescription,
          generation: move.generation,
        );
      } on Object catch (error) {
        throw EditorPersistenceException(
          'Moves catalog contains an invalid canonical PokemonMove entry: $error',
        );
      }
    }

    if (!_looksLikeLegacyMoveEntry(entry)) {
      throw const EditorPersistenceException(
        'Moves catalog contains an entry with an unknown or unsupported move shape.',
      );
    }

    final id = (entry['id'] as String?)?.trim() ?? '';
    if (id.isEmpty) {
      return null;
    }

    final explicitName = (entry['name'] as String?)?.trim();
    final localizedNames = (entry['names'] as Map?)?.cast<String, dynamic>();
    final fallbackName = (localizedNames?['en'] as String?)?.trim();
    final name =
        explicitName?.isNotEmpty == true ? explicitName! : fallbackName;

    return PokemonMoveCatalogEntryView(
      id: id,
      name: name?.isNotEmpty == true ? name! : id,
      type: (entry['type'] as String?)?.trim(),
      category: (entry['category'] as String?)?.trim(),
      power: (entry['power'] as num?)?.toInt(),
      accuracy: entry['accuracy'] as num?,
      accuracyText: (entry['accuracyText'] as String?)?.trim(),
      pp: (entry['pp'] as num?)?.toInt(),
      priority: (entry['priority'] as num?)?.toInt(),
      target: (entry['target'] as String?)?.trim(),
      shortDesc: (entry['shortDesc'] as String?)?.trim(),
      generation: (entry['generation'] as num?)?.toInt(),
    );
  }
}

/// Synchronise le catalogue local `moves.json` depuis la source externe retenue.
///
/// Choix produit et technique de la 11B :
/// - on réutilise le port externe 11A existant, étendu minimalement ;
/// - la source bulk retenue est Showdown `moves.json` ;
/// - l'écriture locale continue de passer par le repository Pokémon existant ;
/// - `project.json` n'est jamais touché ;
/// - aucun pipeline parallèle n'est créé.
class SyncExternalPokemonMovesCatalogUseCase {
  const SyncExternalPokemonMovesCatalogUseCase({
    required this.externalSourceRepository,
    required this.readRepository,
    required this.writeRepository,
    this.converter = const ShowdownMoveCatalogConverter(),
  });

  final PokemonExternalSourceRepository externalSourceRepository;
  final PokemonReadRepository readRepository;
  final PokemonWriteRepository writeRepository;
  final ShowdownMoveCatalogConverter converter;

  Future<PokemonMovesCatalogSyncResult> execute(
    ProjectWorkspace workspace, {
    bool dryRun = false,
  }) async {
    final externalCatalog = converter.convert(
      await externalSourceRepository.fetchShowdownMovesSnapshot(),
    );
    final localCatalog = await _readLocalCatalogIfAvailable(workspace);
    final merge = _mergeCatalogs(
      localCatalog: localCatalog,
      externalCatalog: externalCatalog,
    );

    if (!dryRun) {
      await writeRepository.saveCatalogByKey(workspace, 'moves', merge.catalog);
    }

    return PokemonMovesCatalogSyncResult(
      dryRun: dryRun,
      externalEntryCount: externalCatalog.entries.length,
      createdIds: merge.createdIds,
      updatedIds: merge.updatedIds,
      unchangedIds: merge.unchangedIds,
      preservedLocalOnlyIds: merge.preservedLocalOnlyIds,
      resultingEntryCount: merge.catalog.entries.length,
      warnings: merge.warnings,
    );
  }

  Future<PokemonCatalogFile?> _readLocalCatalogIfAvailable(
    ProjectWorkspace workspace,
  ) async {
    try {
      return await readRepository.readCatalogByKey(workspace, 'moves');
    } on EditorNotFoundException {
      // Le storage 11A/11B initialise normalement le fichier, mais on garde ce
      // fallback local pour éviter qu'une absence de catalogue ne bloque
      // complètement un premier sync sur un workspace partiellement initialisé.
      return null;
    }
  }

  _MovesCatalogMerge _mergeCatalogs({
    required PokemonCatalogFile? localCatalog,
    required PokemonCatalogFile externalCatalog,
  }) {
    final localById = <String, Map<String, dynamic>>{
      for (final entry
          in localCatalog?.entries ?? const <Map<String, dynamic>>[])
        ((entry['id'] as String?)?.trim() ?? ''): _deepCopy(entry),
    }..remove('');
    final externalById = <String, Map<String, dynamic>>{
      for (final entry in externalCatalog.entries)
        ((entry['id'] as String?)?.trim() ?? ''): _deepCopy(entry),
    }..remove('');

    final createdIds = <String>[];
    final updatedIds = <String>[];
    final unchangedIds = <String>[];
    final mergedEntries = <Map<String, dynamic>>[];

    for (final externalEntry in externalById.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key))) {
      final id = externalEntry.key;
      final localEntry = localById.remove(id);
      if (localEntry == null) {
        createdIds.add(id);
        mergedEntries.add(_deepCopy(externalEntry.value));
        continue;
      }

      final mergedEntry = _mergeEntry(
        localEntry: localEntry,
        externalEntry: externalEntry.value,
      );
      if (_jsonDeepEquals(localEntry, mergedEntry)) {
        unchangedIds.add(id);
      } else {
        updatedIds.add(id);
      }
      mergedEntries.add(mergedEntry);
    }

    final preservedLocalOnlyIds = localById.keys.toList(growable: false)
      ..sort();
    for (final id in preservedLocalOnlyIds) {
      mergedEntries.add(_deepCopy(localById[id]!));
    }

    mergedEntries.sort(
      (left, right) => ((left['id'] as String?) ?? '').compareTo(
        (right['id'] as String?) ?? '',
      ),
    );

    final catalog = PokemonCatalogFile(
      schemaVersion: externalCatalog.schemaVersion,
      kind: externalCatalog.kind,
      catalog: externalCatalog.catalog,
      meta: _buildMergedMeta(
        localMeta: localCatalog?.meta,
        externalMeta: externalCatalog.meta,
      ),
      entries: mergedEntries,
    );

    return _MovesCatalogMerge(
      catalog: catalog,
      createdIds: createdIds,
      updatedIds: updatedIds,
      unchangedIds: unchangedIds,
      preservedLocalOnlyIds: preservedLocalOnlyIds,
      warnings: preservedLocalOnlyIds.isEmpty
          ? const <String>[]
          : <String>[
              'Local move entries absent from the external snapshot were preserved unchanged.',
            ],
    );
  }

  PokemonDataMeta _buildMergedMeta({
    required PokemonDataMeta? localMeta,
    required PokemonDataMeta externalMeta,
  }) {
    final notes = <String>[
      ...externalMeta.notes,
      if (localMeta != null)
        ...localMeta.notes.where(
          (note) => !externalMeta.notes.contains(note),
        ),
    ];

    return PokemonDataMeta(
      description: externalMeta.description,
      sourcePriority: externalMeta.sourcePriority,
      notes: notes,
    );
  }

  Map<String, dynamic> _mergeEntry({
    required Map<String, dynamic> localEntry,
    required Map<String, dynamic> externalEntry,
  }) {
    final merged = <String, dynamic>{};

    for (final externalField in externalEntry.entries) {
      final key = externalField.key;
      final externalValue = externalField.value;
      final localValue = localEntry[key];

      if (key == 'names' &&
          localValue is Map &&
          externalValue is Map<String, dynamic>) {
        merged[key] = _mergeNames(localValue, externalValue);
        continue;
      }

      // Règle de merge locale et volontairement conservative :
      // - l'externe garde la priorité sur les champs qu'on sait produire ;
      // - si la valeur externe vaut `null`, on conserve une valeur locale
      //   existante plutôt que d'effacer une information déjà utile ;
      // - les champs purement locaux non gérés par 11B sont préservés plus bas.
      merged[key] = externalValue ?? _deepCopyValue(localValue);
    }

    for (final localField in localEntry.entries) {
      if (_looksLikeCanonicalMoveEntry(externalEntry) &&
          _obsoleteLegacyMoveFields.contains(localField.key)) {
        // M3 ne doit pas laisser les anciens alias légers (`power`,
        // `accuracyText`, `shortDesc`) se réinjecter sur une entrée maintenant
        // canonique. On continue toutefois de préserver les vrais champs
        // locaux additionnels (`names.fr`, `editorNote`, etc.).
        continue;
      }
      merged.putIfAbsent(
          localField.key, () => _deepCopyValue(localField.value));
    }

    return merged;
  }

  Map<String, dynamic> _mergeNames(
    Map localValue,
    Map<String, dynamic> externalValue,
  ) {
    final merged = <String, dynamic>{
      for (final entry in localValue.entries)
        if (entry.key is String)
          entry.key as String: _deepCopyValue(entry.value),
    };
    for (final entry in externalValue.entries) {
      merged[entry.key] = _deepCopyValue(entry.value);
    }
    return merged;
  }

  Map<String, dynamic> _deepCopy(Map<String, dynamic> source) {
    return (jsonDecode(jsonEncode(source)) as Map).cast<String, dynamic>();
  }

  Object? _deepCopyValue(Object? value) {
    if (value == null) {
      return null;
    }
    return jsonDecode(jsonEncode(value));
  }

  bool _jsonDeepEquals(Object? left, Object? right) {
    if (left is Map && right is Map) {
      if (left.length != right.length) {
        return false;
      }
      for (final key in left.keys) {
        if (!right.containsKey(key)) {
          return false;
        }
        if (!_jsonDeepEquals(left[key], right[key])) {
          return false;
        }
      }
      return true;
    }
    if (left is List && right is List) {
      if (left.length != right.length) {
        return false;
      }
      for (var index = 0; index < left.length; index++) {
        if (!_jsonDeepEquals(left[index], right[index])) {
          return false;
        }
      }
      return true;
    }
    return left == right;
  }
}

String _encodeTarget(PokemonMoveTarget target) {
  switch (target) {
    case PokemonMoveTarget.adjacentAlly:
      return 'adjacentAlly';
    case PokemonMoveTarget.adjacentAllyOrSelf:
      return 'adjacentAllyOrSelf';
    case PokemonMoveTarget.adjacentFoe:
      return 'adjacentFoe';
    case PokemonMoveTarget.all:
      return 'all';
    case PokemonMoveTarget.allAdjacent:
      return 'allAdjacent';
    case PokemonMoveTarget.allAdjacentFoes:
      return 'allAdjacentFoes';
    case PokemonMoveTarget.allies:
      return 'allies';
    case PokemonMoveTarget.allySide:
      return 'allySide';
    case PokemonMoveTarget.allyTeam:
      return 'allyTeam';
    case PokemonMoveTarget.any:
      return 'any';
    case PokemonMoveTarget.foeSide:
      return 'foeSide';
    case PokemonMoveTarget.normal:
      return 'normal';
    case PokemonMoveTarget.randomNormal:
      return 'randomNormal';
    case PokemonMoveTarget.scripted:
      return 'scripted';
    case PokemonMoveTarget.self:
      return 'self';
  }
}

bool _looksLikeCanonicalMoveEntry(Map<String, dynamic> entry) {
  // Détection volontairement large :
  // - toute présence d'un vrai marqueur canonique doit suffire ;
  // - une entrée partiellement migrée ou partiellement cassée doit être
  //   traitée comme une candidate canonique, puis échouer explicitement ;
  // - on évite ainsi tout downgrade silencieux vers le fallback legacy.
  return entry.containsKey('basePower') ||
      entry.containsKey('effects') ||
      entry.containsKey('sourceRefs') ||
      entry.containsKey('engineSupportLevel') ||
      entry.containsKey('unsupportedReasons') ||
      entry.containsKey('noPpBoosts') ||
      entry.containsKey('critRatio') ||
      entry['accuracy'] is Map;
}

bool _looksLikeLegacyMoveEntry(Map<String, dynamic> entry) {
  // Détection volontairement étroite :
  // - on ne classe legacy que les formes explicitement héritées de l'ancien
  //   catalogue léger ;
  // - la présence d'un signal canonique exclut immédiatement le chemin legacy ;
  // - `accuracy` scalaire seule n'est acceptée en legacy que s'il n'existe
  //   aucun signal canonique concurrent.
  if (_looksLikeCanonicalMoveEntry(entry)) {
    return false;
  }

  return entry.containsKey('power') ||
      entry.containsKey('accuracyText') ||
      entry.containsKey('shortDesc') ||
      entry['accuracy'] is num;
}

const Set<String> _obsoleteLegacyMoveFields = <String>{
  'power',
  'accuracyText',
  'shortDesc',
};

class _MovesCatalogMerge {
  const _MovesCatalogMerge({
    required this.catalog,
    required this.createdIds,
    required this.updatedIds,
    required this.unchangedIds,
    required this.preservedLocalOnlyIds,
    required this.warnings,
  });

  final PokemonCatalogFile catalog;
  final List<String> createdIds;
  final List<String> updatedIds;
  final List<String> unchangedIds;
  final List<String> preservedLocalOnlyIds;
  final List<String> warnings;
}
```

### `packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart`

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/pokemon_external_source_repository.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late FilePokemonReadRepository readRepository;
  late FilePokemonWriteRepository writeRepository;
  late _FakePokemonExternalSourceRepository externalRepository;
  late SyncExternalPokemonMovesCatalogUseCase syncUseCase;
  late LoadPokemonMovesCatalogUseCase loadUseCase;

  setUp(() async {
    tempProjectRoot =
        await Directory.systemTemp.createTemp('moves_catalog_sync_');
    workspace = ProjectFileSystem(tempProjectRoot.path);
    readRepository = const FilePokemonReadRepository();
    writeRepository = const FilePokemonWriteRepository();
    externalRepository = _FakePokemonExternalSourceRepository();
    syncUseCase = SyncExternalPokemonMovesCatalogUseCase(
      externalSourceRepository: externalRepository,
      readRepository: readRepository,
      writeRepository: writeRepository,
    );
    loadUseCase = LoadPokemonMovesCatalogUseCase(
      readRepository: readRepository,
    );

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Moves Catalog Sync Project',
      tempProjectRoot.path,
    );
    await const InitializePokemonProjectStorageUseCase().execute(workspace);
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  Future<PokemonMovesCatalogView> loadViewFromCatalog(
    PokemonCatalogFile catalog,
  ) async {
    await writeRepository.saveCatalogByKey(
      workspace,
      'moves',
      catalog,
    );
    return loadUseCase.execute(workspace);
  }

  test('dry-run previews the sync without writing the local catalog', () async {
    await writeRepository.saveCatalogByKey(
      workspace,
      'moves',
      _localMovesCatalogBeforeSync,
    );

    final catalogFile = File(
      workspace.resolveProjectRelativePath('data/pokemon/catalogs/moves.json'),
    );
    final beforeCatalogJson = await catalogFile.readAsString();
    final projectFile = File(workspace.projectManifestPath);
    final beforeProjectJson = await projectFile.readAsString();

    final result = await syncUseCase.execute(workspace, dryRun: true);

    expect(result.dryRun, isTrue);
    expect(result.createdIds, containsAll(<String>['swift', 'thunderbolt']));
    expect(result.updatedIds, contains('vine_whip'));
    expect(result.preservedLocalOnlyIds, contains('custom_move'));
    expect(await catalogFile.readAsString(), beforeCatalogJson);
    expect(await projectFile.readAsString(), beforeProjectJson);
  });

  test(
      'sync merges Showdown moves into the local catalog and preserves local-only metadata',
      () async {
    await writeRepository.saveCatalogByKey(
      workspace,
      'moves',
      _localMovesCatalogBeforeSync,
    );

    final projectFile = File(workspace.projectManifestPath);
    final beforeProjectJson = await projectFile.readAsString();

    final result = await syncUseCase.execute(workspace);
    final syncedCatalog = await readRepository.readCatalogByKey(
      workspace,
      'moves',
    );
    final loadedView = await loadUseCase.execute(workspace);

    expect(result.dryRun, isFalse);
    expect(result.createdIds, containsAll(<String>['swift', 'thunderbolt']));
    expect(result.updatedIds, contains('vine_whip'));
    expect(result.preservedLocalOnlyIds, contains('custom_move'));
    expect(
      syncedCatalog.entries.map((entry) => entry['id']),
      containsAll(<String>['custom_move', 'swift', 'thunderbolt', 'vine_whip']),
    );

    final vineWhip = syncedCatalog.entries.firstWhere(
      (entry) => entry['id'] == 'vine_whip',
    );
    final canonicalVineWhip = PokemonMove.fromJson(vineWhip);
    expect(canonicalVineWhip.name, 'Vine Whip');
    expect(canonicalVineWhip.type, 'grass');
    expect(canonicalVineWhip.basePower, 45);
    expect(canonicalVineWhip.generation, 1);
    expect(canonicalVineWhip.source, 'showdown');
    expect(vineWhip.containsKey('power'), isFalse);
    expect(vineWhip.containsKey('accuracyText'), isFalse);
    expect(vineWhip.containsKey('shortDesc'), isFalse);
    expect(
      ((vineWhip['names'] as Map<String, dynamic>)['fr'] as String),
      'Fouet Lianes',
    );
    expect(vineWhip['editorNote'], 'Keep this local-only field after sync.');

    final swift = syncedCatalog.entries.firstWhere(
      (entry) => entry['id'] == 'swift',
    );
    final canonicalSwift = PokemonMove.fromJson(swift);
    expect(
      canonicalSwift.accuracy,
      const PokemonMoveAccuracy.alwaysHits(),
    );

    expect(loadedView.isAvailable, isTrue);
    final thunderboltView = loadedView.entries.firstWhere(
      (entry) => entry.id == 'thunderbolt',
    );
    expect(thunderboltView.power, 90);
    expect(thunderboltView.accuracyLabel, '100');
    expect(thunderboltView.shortDesc, 'May paralyze the target.');

    final swiftView = loadedView.entries.firstWhere(
      (entry) => entry.id == 'swift',
    );
    expect(swiftView.accuracyLabel, 'always');
    expect(await projectFile.readAsString(), beforeProjectJson);
  });

  test(
      'load use case does not silently downgrade an invalid canonical move to legacy projection',
      () async {
    final loadedView = await loadViewFromCatalog(
      _catalogWithEntries(
        <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'broken_move',
            'name': 'Broken Move',
            'names': <String, String>{'en': 'Broken Move'},
            'source': 'showdown',
            'type': 'normal',
            'category': 'physical',
            'target': 'normal',
            'basePower': 40,
            'accuracy': <String, dynamic>{'kind': 'percent', 'value': 0},
            'pp': 10,
            'priority': 0,
            'critRatio': 1,
            'flags': <String>[],
            'effects': <Map<String, dynamic>>[],
            'shortDescription': 'Broken canonical payload.',
            'description': 'Broken canonical payload.',
            'engineSupportLevel': 'structured_supported',
            'unsupportedReasons': <String>[],
            'sourceRefs': <String, dynamic>{
              'showdownMoveId': 'brokenmove',
              'showdownHooksPresent': <String>[],
            },
          },
        ],
        description: 'Broken canonical move catalog.',
      ),
    );

    expect(loadedView.isAvailable, isFalse);
    expect(loadedView.description, 'Catalogue local des attaques illisible.');
    expect(
      loadedView.message,
      contains('invalid canonical PokemonMove entry'),
    );
  });

  test('load use case reads a valid canonical move entry correctly', () async {
    final loadedView = await loadViewFromCatalog(
      _catalogWithEntries(
        <Map<String, dynamic>>[
          _canonicalMoveEntry(
            const PokemonMove(
              id: 'thunderbolt',
              name: 'Thunderbolt',
              names: <String, String>{'en': 'Thunderbolt'},
              generation: 1,
              source: 'showdown',
              type: 'electric',
              category: PokemonMoveCategory.special,
              target: PokemonMoveTarget.normal,
              basePower: 90,
              accuracy: PokemonMoveAccuracy.percent(value: 100),
              pp: 15,
              priority: 0,
              critRatio: 1,
              effects: <PokemonMoveEffect>[
                PokemonMoveEffect.applyStatus(
                  chance: 10,
                  statusId: 'par',
                ),
              ],
              shortDescription: 'May paralyze the target.',
              description:
                  'A strong electric blast crashes down on the target.',
              engineSupportLevel:
                  PokemonMoveEngineSupportLevel.structuredSupported,
              sourceRefs: PokemonMoveSourceRefs(
                showdownMoveId: 'thunderbolt',
              ),
            ),
          ),
        ],
        description: 'Valid canonical move catalog.',
      ),
    );

    expect(loadedView.isAvailable, isTrue);
    expect(loadedView.entries, hasLength(1));
    expect(loadedView.entries.single.id, 'thunderbolt');
    expect(loadedView.entries.single.power, 90);
    expect(loadedView.entries.single.accuracyLabel, '100');
    expect(loadedView.entries.single.shortDesc, 'May paralyze the target.');
  });

  test(
      'load use case treats basePower plus scalar accuracy as invalid canonical instead of legacy',
      () async {
    final loadedView = await loadViewFromCatalog(
      _catalogWithEntries(
        <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'broken_base_power_move',
            'name': 'Broken Base Power Move',
            'names': <String, String>{'en': 'Broken Base Power Move'},
            'type': 'normal',
            'category': 'physical',
            'target': 'normal',
            'basePower': 40,
            'accuracy': 95,
            'pp': 15,
            'priority': 0,
          },
        ],
        description: 'Broken canonical candidate by basePower.',
      ),
    );

    expect(loadedView.isAvailable, isFalse);
    expect(
      loadedView.message,
      contains('invalid canonical PokemonMove entry'),
    );
  });

  test(
      'load use case treats other canonical markers as invalid canonical instead of legacy',
      () async {
    final loadedView = await loadViewFromCatalog(
      _catalogWithEntries(
        <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'broken_effects_move',
            'name': 'Broken Effects Move',
            'names': <String, String>{'en': 'Broken Effects Move'},
            'type': 'psychic',
            'category': 'status',
            'accuracy': <String, dynamic>{'kind': 'always_hits'},
            'effects': <Map<String, dynamic>>[
              <String, dynamic>{
                'kind': 'set_weather',
              },
            ],
          },
        ],
        description: 'Broken canonical candidate by effects.',
      ),
    );

    expect(loadedView.isAvailable, isFalse);
    expect(
      loadedView.message,
      contains('invalid canonical PokemonMove entry'),
    );
  });

  test('load use case still accepts a true legacy move entry', () async {
    final loadedView = await loadViewFromCatalog(
      _catalogWithEntries(
        const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'legacy_move',
            'name': 'Legacy Move',
            'names': <String, String>{'en': 'Legacy Move'},
            'type': 'normal',
            'category': 'physical',
            'power': 50,
            'accuracy': 95,
            'pp': 20,
            'priority': 0,
            'target': 'normal',
            'shortDesc': 'A true legacy move entry.',
            'generation': 3,
          },
        ],
        description: 'Legacy move catalog.',
      ),
    );

    expect(loadedView.isAvailable, isTrue);
    expect(loadedView.entries, hasLength(1));
    expect(loadedView.entries.single.id, 'legacy_move');
    expect(loadedView.entries.single.power, 50);
    expect(loadedView.entries.single.accuracyLabel, '95');
    expect(loadedView.entries.single.shortDesc, 'A true legacy move entry.');
  });

  test('load use case rejects an unknown move entry shape explicitly',
      () async {
    final loadedView = await loadViewFromCatalog(
      _catalogWithEntries(
        const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'unknown_shape_move',
            'name': 'Unknown Shape Move',
            'names': <String, String>{'en': 'Unknown Shape Move'},
            'type': 'normal',
            'category': 'status',
            'target': 'normal',
          },
        ],
        description: 'Unknown move catalog shape.',
      ),
    );

    expect(loadedView.isAvailable, isFalse);
    expect(
      loadedView.message,
      contains('unknown or unsupported move shape'),
    );
  });
}

PokemonCatalogFile _catalogWithEntries(
  List<Map<String, dynamic>> entries, {
  required String description,
}) {
  return PokemonCatalogFile(
    schemaVersion: 1,
    kind: 'pokemon_catalog',
    catalog: 'moves',
    meta: PokemonDataMeta(
      description: description,
    ),
    entries: entries,
  );
}

Map<String, dynamic> _canonicalMoveEntry(PokemonMove move) => move.toJson();

class _FakePokemonExternalSourceRepository
    implements PokemonExternalSourceRepository {
  @override
  Future<Map<String, dynamic>> fetchShowdownPokedexSnapshot() {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownMovesSnapshot() async {
    return <String, dynamic>{
      'vinewhip': <String, dynamic>{
        'name': 'Vine Whip',
        'type': 'Grass',
        'category': 'Physical',
        'basePower': 45,
        'accuracy': 100,
        'pp': 25,
        'priority': 0,
        'target': 'normal',
        'shortDesc': 'Strikes the target with slender, whiplike vines.',
        'desc': 'The target is struck with slender, whiplike vines.',
        'gen': 1,
      },
      'thunderbolt': <String, dynamic>{
        'name': 'Thunderbolt',
        'type': 'Electric',
        'category': 'Special',
        'basePower': 90,
        'accuracy': 100,
        'pp': 15,
        'priority': 0,
        'target': 'normal',
        'secondary': <String, dynamic>{
          'chance': 10,
          'status': 'par',
        },
        'shortDesc': 'May paralyze the target.',
        'desc': 'A strong electric blast crashes down on the target.',
        'gen': 1,
      },
      'swift': <String, dynamic>{
        'name': 'Swift',
        'type': 'Normal',
        'category': 'Special',
        'basePower': 60,
        'accuracy': true,
        'pp': 20,
        'priority': 0,
        'target': 'allAdjacentFoes',
        'shortDesc': 'This move does not check accuracy.',
        'desc': 'Star-shaped rays are shot at opposing Pokémon.',
        'gen': 1,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownSpeciesPayload(String speciesId) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonPayload(String speciesId) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonSpeciesPayload(
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiEvolutionChainPayload(
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonExternalBinaryAsset> fetchBinaryAsset(String sourceUrl) {
    throw UnimplementedError();
  }
}

const PokemonCatalogFile _localMovesCatalogBeforeSync = PokemonCatalogFile(
  schemaVersion: 1,
  kind: 'pokemon_catalog',
  catalog: 'moves',
  meta: PokemonDataMeta(
    description: 'Local moves catalog before external sync.',
  ),
  entries: <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'custom_move',
      'name': 'Custom Move',
      'names': <String, String>{'en': 'Custom Move'},
      'type': 'normal',
      'category': 'status',
      'power': null,
      'accuracy': 100,
      'pp': 5,
      'priority': 0,
      'target': 'self',
      'shortDesc': 'A local-only move that must be preserved.',
      'generation': 9,
    },
    <String, dynamic>{
      'id': 'vine_whip',
      'name': 'Liane',
      'names': <String, String>{
        'en': 'Vine Whip',
        'fr': 'Fouet Lianes',
      },
      'type': 'grass',
      'category': 'physical',
      'power': 40,
      'accuracy': 95,
      'pp': 20,
      'priority': 0,
      'target': 'normal',
      'shortDesc': 'Old local description.',
      'generation': 3,
      'editorNote': 'Keep this local-only field after sync.',
    },
  ],
);
```
