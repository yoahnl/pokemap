# 1. Résumé exécutif honnête

Le lot 6 a été implémenté en restant petit, `moves-first`, et sans créer de stack parallèle.

La décision finale a été :
- **ne pas** construire une plateforme de recherche catalogue globale ;
- **ne pas** ajouter de provider/use case/repository supplémentaires ;
- **ne pas** réécrire l’UI du lot 5 ;
- introduire uniquement un **socle générique minimal** de lookup local en mémoire ;
- faire converger `PokemonMovesCatalogLookupService` dessus comme **première implémentation réelle**.

Résultat concret :
- il existe désormais un contrat réutilisable et testable de recherche catalogue locale via `ProgressiveLocalCatalogLookupService<TEntry>` ;
- `PokemonMovesCatalogLookupService` reste la surface `moves` concrète, mais repose maintenant sur ce socle commun ;
- l’assistance learnset du lot 5 continue de fonctionner sans changement de comportement visible ;
- aucun deuxième système de lookup `moves` n’a été créé.

Le lot 6 reste volontairement borné :
- pas d’ouverture abilities/items/types ;
- pas de trainers ;
- pas de refonte du learnset editor ;
- pas de nouveau wiring applicatif ;
- pas de logique métier déplacée dans l’UI.

# 2. État initial audité

Avant modification, l’audit du vrai code a montré :

- `packages/map_editor/lib/src/application/services/pokemon_moves_catalog_lookup_service.dart` contenait déjà la logique de recherche locale introduite au lot 5.
- Cette logique était **bonne** pour `moves`, mais restait **totalement spécifique** au premier usage.
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_move_assist.dart` et `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_moves_catalog_section.dart` consommaient déjà ce service concret.
- Le lot 5 avait donc apporté une vraie valeur produit, mais il manquait encore une forme plus stable pour la réutilisation future.

Ce qui était déjà bon :
- recherche locale pure, sans réseau ;
- lookup strict par `id` ;
- ranking simple et déterministe ;
- pas de logique métier déplacée dans les widgets.

Ce qui restait trop spécifique :
- l’algorithme de lookup vivait uniquement dans le service `moves` ;
- il n’existait pas encore de forme réutilisable pour un futur catalogue `species`, `items`, etc. ;
- la convergence vers la suite se ferait sinon par copier-coller.

Ce qu’il ne fallait surtout pas toucher :
- le comportement du learnset editor lot 5 ;
- la validation métier du save learnset ;
- le sync/load du catalogue `moves` ;
- les flows lots 1 à 4.

# 3. Périmètre inclus / exclu

## Inclus

- création d’un petit socle réutilisable de recherche catalogue locale ;
- adaptation minimale du service `moves` existant ;
- tests du nouveau socle ;
- tests moves spécifiques ;
- non-régressions ciblées sur le lot 5 et sur le catalogue `moves`.

## Exclu

- ajout d’abilities/items/egg groups/etc. ;
- changement visible du learnset editor ;
- nouveau provider / use case / repository ;
- trainers / encounters ;
- runtime / battle / save ;
- refonte massive de l’architecture.

# 4. Décisions d’architecture

## 4.1. Rejet d’une interface supplémentaire

J’ai d’abord considéré une petite interface générique + une implémentation générique.

Après relecture contradictoire, ce choix a été rejeté :
- il n’existe encore qu’un premier consommateur concret ;
- une interface séparée aurait ajouté une couche de plus sans vrai besoin immédiat ;
- cela aurait été un pas vers la sur-ingénierie que le lot 6 devait justement éviter.

## 4.2. Choix retenu : un socle générique concret, pas une plateforme

Le lot 6 introduit uniquement :
- `ProgressiveLocalCatalogLookupService<TEntry>`
- trois extracteurs configurables : `idOf`, `labelOf`, `searchTermsOf`

Ce socle reste :
- en mémoire ;
- synchrone ;
- sans état ;
- sans cache ;
- sans IO ;
- sans awareness UI.

C’est suffisant pour servir de **contrat stable** sans devenir un framework.

## 4.3. `moves` reste la première implémentation réelle

`PokemonMovesCatalogLookupService` n’a pas été remplacé.
Il a été **convergé** :
- il reste la surface concrète `moves-first` ;
- il étend maintenant `ProgressiveLocalCatalogLookupService<PokemonMoveCatalogEntryView>` ;
- l’UI continue donc d’utiliser la même entrée concrète sans refonte.

## 4.4. Aucun changement de wiring

Décision retenue :
- aucun provider nouveau ;
- aucun use case nouveau ;
- aucun repository nouveau.

Pourquoi :
- le lookup reste une pure logique locale sur des entrées déjà chargées ;
- tout wiring supplémentaire aurait été artificiel.

# 5. Liste exacte des fichiers modifiés / créés / supprimés

## Modifiés

- `packages/map_editor/lib/src/application/services/pokemon_moves_catalog_lookup_service.dart`
- `packages/map_editor/test/pokemon_moves_catalog_lookup_service_test.dart`

## Créés

- `packages/map_editor/lib/src/application/services/local_catalog_lookup_service.dart`
- `packages/map_editor/test/local_catalog_lookup_service_test.dart`

## Supprimés

- aucun

# 6. Justification fichier par fichier

## `packages/map_editor/lib/src/application/services/local_catalog_lookup_service.dart`

Ajout du socle progressif réutilisable de recherche locale.

Rôle :
- offrir une forme simple et stable pour la recherche catalogue future ;
- rester suffisamment petite pour ne pas devenir une “catalog search platform”.

## `packages/map_editor/lib/src/application/services/pokemon_moves_catalog_lookup_service.dart`

Convergence du service `moves` existant vers le nouveau socle.

Rôle :
- garder la surface `moves-first` actuelle ;
- supprimer le risque de duplication future de l’algorithme ;
- ne rien casser côté UI.

## `packages/map_editor/test/local_catalog_lookup_service_test.dart`

Tests du socle générique :
- lookup exact par id ;
- ranking ;
- ordre stable ;
- limite zéro.

## `packages/map_editor/test/pokemon_moves_catalog_lookup_service_test.dart`

Tests du service `moves` après convergence :
- il réutilise bien le socle progressif ;
- son comportement local `moves` reste inchangé.

# 7. Sub-agents utilisés, conclusions, retenu / rejeté

La limite de threads empêchant la création de nouveaux agents, j’ai réutilisé honnêtement des threads existants.

## Scope / architecture reviewer

Thread réutilisé : `019d81fd-7906-74c1-9005-b84399f7700e`

Conclusion principale :
- une interface générique supplémentaire serait déjà trop abstraite ;
- le plus petit pas honnête est un socle pur de ranking/lookup réutilisable ;
- aucun provider/use case supplémentaire n’est justifié.

Retenu :
- socle générique concret, sans wiring ;
- conservation du service `moves` concret.

Rejeté :
- interface + implémentation + provider ;
- toute généralisation cross-catalogues prématurée.

## UX / flow auteur reviewer

Thread réutilisé : `019d81fd-7b05-7302-8681-e779fd0d6a36`

Conclusion principale :
- garder l’UI du lot 5 inchangée ;
- faire converger l’interne, pas réécrire la surface auteur.

Retenu :
- aucune refonte visible du learnset editor ;
- aucun changement du flow explicite de sélection.

Rejeté :
- ajustement UX gratuit “pour le lot 6”.

## Test matrix reviewer

Thread réutilisé : `019d81fd-79ff-7213-9215-a788ac13b984`

Conclusion principale :
- un test du contrat générique ;
- un test du service `moves` comme adapter ;
- une non-régression UI lot 5 ;
- inutile de retester le contrat générique via toute l’arborescence widget.

Retenu :
- `local_catalog_lookup_service_test.dart`
- `pokemon_moves_catalog_lookup_service_test.dart`
- smoke UI lot 5
- smoke `moves catalog` sync
- smoke lot 4 batch.

## Reviewer contradicteur anti-sur-ingénierie

Thread réutilisé : `019d821b-9941-71c1-9001-d32c767ea874`

Conclusion principale :
- rejeter une interface générique de plus ;
- ne pas rendre le lookup responsable du refresh, du chargement, ou de la sélection implicite ;
- ne pas laisser le contrat glisser vers une plateforme.

Retenu :
- lookup pur et synchrone ;
- pas d’état ;
- pas de réécriture UI.

Rejeté :
- contrat asynchrone/provider-backed ;
- auto-sélection/auto-normalisation ;
- plateforme de recherche multi-catalogues.

# 8. Commandes réellement exécutées

## Audit

```bash
sed -n '1,240p' packages/map_editor/lib/src/application/services/pokemon_moves_catalog_lookup_service.dart
sed -n '1,260p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_move_assist.dart
sed -n '1,260p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_sections.dart
sed -n '1,260p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_moves_catalog_section.dart
```

## Validation

```bash
dart format packages/map_editor/lib/src/application/services/local_catalog_lookup_service.dart packages/map_editor/lib/src/application/services/pokemon_moves_catalog_lookup_service.dart packages/map_editor/test/local_catalog_lookup_service_test.dart packages/map_editor/test/pokemon_moves_catalog_lookup_service_test.dart
flutter analyze --no-pub lib/src/application/services/local_catalog_lookup_service.dart lib/src/application/services/pokemon_moves_catalog_lookup_service.dart test/local_catalog_lookup_service_test.dart test/pokemon_moves_catalog_lookup_service_test.dart test/pokedex_learnset_moves_assist_ui_test.dart
flutter test test/local_catalog_lookup_service_test.dart test/pokemon_moves_catalog_lookup_service_test.dart test/pokedex_learnset_moves_assist_ui_test.dart
flutter test test/sync_pokemon_moves_catalog_use_case_test.dart
flutter test test/pokedex_workspace_ui_test.dart --plain-name "shows the local moves catalog section in the learnset tab and allows preview + sync"
flutter test test/pokedex_external_batch_execute_ui_test.dart --plain-name "keeps dry-run and batch execution separate and shows a final report"
```

## Git

```bash
git status --short
git diff --stat -- packages/map_editor/lib/src/application/services/local_catalog_lookup_service.dart packages/map_editor/lib/src/application/services/pokemon_moves_catalog_lookup_service.dart packages/map_editor/test/local_catalog_lookup_service_test.dart packages/map_editor/test/pokemon_moves_catalog_lookup_service_test.dart
git ls-files --others --exclude-standard
```

# 9. Résultats réels

## `dart format`

```text
Formatted packages/map_editor/lib/src/application/services/local_catalog_lookup_service.dart
Formatted packages/map_editor/test/pokemon_moves_catalog_lookup_service_test.dart
Formatted 4 files (2 changed) in 0.02 seconds.
```

## `flutter analyze --no-pub`

```text
Analyzing 5 items...
No issues found! (ran in 1.9s)
```

## `flutter test test/local_catalog_lookup_service_test.dart test/pokemon_moves_catalog_lookup_service_test.dart test/pokedex_learnset_moves_assist_ui_test.dart`

```text
00:05 +11: All tests passed!
```

## `flutter test test/sync_pokemon_moves_catalog_use_case_test.dart`

```text
00:02 +2: All tests passed!
```

## `flutter test test/pokedex_workspace_ui_test.dart --plain-name "shows the local moves catalog section in the learnset tab and allows preview + sync"`

```text
00:03 +1: All tests passed!
```

## `flutter test test/pokedex_external_batch_execute_ui_test.dart --plain-name "keeps dry-run and batch execution separate and shows a final report"`

```text
00:03 +1: All tests passed!
```

# 10. Incidents rencontrés

## 10.1. Première tentative trop abstraite

J’ai d’abord tenté une version avec interface + implémentation générique.

Après relecture contradictoire, j’ai réduit ce design :
- l’interface supplémentaire a été supprimée ;
- seul le socle générique concret a été conservé.

## 10.2. Analyse Flutter : deux petits correctifs

L’analyse a signalé :
- un commentaire de fichier au mauvais format ;
- un `const <TEntry>[]` interdit sur générique.

Correction immédiate, sans impact de scope.

## 10.3. Une invocation `flutter test` mal filtrée

J’ai tenté une seule invocation avec deux filtres `--plain-name` différents.
Résultat : aucun test n’a matché.

Correction :
- relance des non-régressions une par une.

## 10.4. Startup lock Flutter

La relance parallèle de plusieurs tests ciblés a déclenché le startup lock Flutter.

Correction :
- j’ai attendu la libération du lock puis laissé les commandes se terminer proprement.

# 11. État git utile

## `git status --short`

```text
 M packages/map_editor/lib/src/application/services/pokemon_moves_catalog_lookup_service.dart
 M packages/map_editor/test/pokemon_moves_catalog_lookup_service_test.dart
?? packages/map_editor/lib/src/application/services/local_catalog_lookup_service.dart
?? packages/map_editor/test/local_catalog_lookup_service_test.dart
```

## `git diff --stat` ciblé

```text
 .../pokemon_moves_catalog_lookup_service.dart      | 134 +++++----------------
 .../pokemon_moves_catalog_lookup_service_test.dart |  10 ++
 2 files changed, 37 insertions(+), 107 deletions(-)
```

## `git ls-files --others --exclude-standard`

```text
packages/map_editor/lib/src/application/services/local_catalog_lookup_service.dart
packages/map_editor/test/local_catalog_lookup_service_test.dart
```

# 12. Checklist finale

- [x] je n’ai pas créé de stack parallèle
- [x] je n’ai pas réécrit 11A / 11B / lots 1 à 5
- [x] je n’ai pas déplacé de logique métier dans l’UI
- [x] j’ai réutilisé le service `moves` existant au lieu de le dupliquer
- [x] le lot 5 continue de fonctionner
- [x] le lot 6 reste `moves-first`
- [x] je n’ai pas créé de plateforme générique disproportionnée
- [x] `dart format` a été exécuté
- [x] `flutter analyze --no-pub` a été exécuté
- [x] les tests ciblés ont été exécutés
- [x] aucun commit / merge / rebase / push / tag / stash / reset / amend n’a été fait
- [x] le report final markdown a bien été créé
- [x] le report contient bien les fichiers texte modifiés / créés en intégralité

# 13. Annexe — contenu complet des fichiers texte modifiés / créés / supprimés

Note explicite :
- cette annexe inclut le contenu complet de tous les fichiers texte modifiés ou créés pour ce lot ;
- le report lui-même n’est pas recopié dans sa propre annexe pour éviter une récursion infinie ;
- aucune écriture git interdite n’a été faite.


## `packages/map_editor/lib/src/application/services/local_catalog_lookup_service.dart`

```dart
// Socle progressif de recherche dans un catalogue local déjà chargé.
//
// Intention du lot 6 :
// - offrir un point commun réutilisable entre catalogues locaux ;
// - partir de `moves` sans forcer un framework multi-catalogues ;
// - rester purement en mémoire, sans loader ni repository supplémentaire.
//
// On évite volontairement une interface séparée ici :
// - il n'existe encore qu'un premier consommateur concret (`moves`) ;
// - ajouter une couche d'abstraction de plus serait de la sur-ingénierie ;
// - ce service générique suffit déjà comme contrat stable et testable.

typedef LocalCatalogIdOf<TEntry> = String Function(TEntry entry);
typedef LocalCatalogLabelOf<TEntry> = String Function(TEntry entry);
typedef LocalCatalogSearchTermsOf<TEntry> = Iterable<String> Function(
  TEntry entry,
);

/// Implémentation progressive et réutilisable du contrat de recherche locale.
///
/// Décisions assumées :
/// - l'algorithme reste simple et stable ;
/// - pas de fuzzy matching ;
/// - pas de normalisation destructive ;
/// - l'ordre des résultats reste prédictible.
///
/// Cela suffit pour préparer trainers / encounters plus tard sans imposer une
/// architecture générique disproportionnée dès maintenant.
class ProgressiveLocalCatalogLookupService<TEntry> {
  const ProgressiveLocalCatalogLookupService({
    required this.idOf,
    required this.labelOf,
    required this.searchTermsOf,
  });

  final LocalCatalogIdOf<TEntry> idOf;
  final LocalCatalogLabelOf<TEntry> labelOf;
  final LocalCatalogSearchTermsOf<TEntry> searchTermsOf;

  TEntry? findById(
    Iterable<TEntry> entries,
    String id,
  ) {
    final normalizedId = id.trim().toLowerCase();
    if (normalizedId.isEmpty) {
      return null;
    }

    for (final entry in entries) {
      if (idOf(entry).trim().toLowerCase() == normalizedId) {
        return entry;
      }
    }
    return null;
  }

  List<TEntry> search(
    Iterable<TEntry> entries,
    String rawQuery, {
    int limit = 8,
  }) {
    final safeLimit = limit <= 0 ? 0 : limit;
    if (safeLimit == 0) {
      return <TEntry>[];
    }

    final materializedEntries = entries.toList(growable: false);
    final normalizedQuery = rawQuery.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return materializedEntries.take(safeLimit).toList(growable: false);
    }

    final rankedEntries = materializedEntries
        .map(
          (entry) => (
            entry: entry,
            rank: _rankEntry(entry, normalizedQuery),
          ),
        )
        .where((candidate) => candidate.rank != null)
        .cast<({TEntry entry, int rank})>()
        .toList(growable: false)
      ..sort((left, right) {
        final rankCompare = left.rank.compareTo(right.rank);
        if (rankCompare != 0) {
          return rankCompare;
        }
        final labelCompare =
            labelOf(left.entry).compareTo(labelOf(right.entry));
        if (labelCompare != 0) {
          return labelCompare;
        }
        return idOf(left.entry).compareTo(idOf(right.entry));
      });

    return rankedEntries
        .take(safeLimit)
        .map((candidate) => candidate.entry)
        .toList(growable: false);
  }

  int? _rankEntry(TEntry entry, String normalizedQuery) {
    final normalizedId = idOf(entry).trim().toLowerCase();
    final normalizedLabel = labelOf(entry).trim().toLowerCase();
    final haystack = searchTermsOf(entry)
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join(' ')
        .toLowerCase();

    if (normalizedId == normalizedQuery) {
      return 0;
    }
    if (normalizedLabel == normalizedQuery) {
      return 1;
    }
    if (normalizedId.startsWith(normalizedQuery)) {
      return 2;
    }
    if (normalizedLabel.startsWith(normalizedQuery)) {
      return 3;
    }
    if (haystack.contains(normalizedQuery)) {
      return 4;
    }
    return null;
  }
}

```

## `packages/map_editor/lib/src/application/services/pokemon_moves_catalog_lookup_service.dart`

```dart
import 'local_catalog_lookup_service.dart';
import '../use_cases/sync_pokemon_moves_catalog_use_case.dart';

/// Recherche locale ciblée sur le catalogue `moves` déjà synchronisé.
///
/// Le lot 5 l'avait introduit comme helper local `moves-first`. Le lot 6 le
/// fait désormais converger vers le contrat progressif commun de recherche
/// catalogue locale, sans changer son rôle produit :
/// - il reste branché exclusivement sur le catalogue `moves` existant ;
/// - il ne recharge rien depuis le disque ;
/// - il ne crée toujours aucune stack parallèle.
///
/// Le lot 5 en a besoin pour deux usages strictement locaux :
/// - retrouver rapidement un move connu par `id` exact ;
/// - filtrer des suggestions lisibles à partir du catalogue moves existant.
class PokemonMovesCatalogLookupService
    extends ProgressiveLocalCatalogLookupService<PokemonMoveCatalogEntryView> {
  const PokemonMovesCatalogLookupService()
      : super(
          idOf: _moveCatalogEntryId,
          labelOf: _moveCatalogEntryLabel,
          searchTermsOf: _moveCatalogEntrySearchTerms,
        );
}

String _moveCatalogEntryId(PokemonMoveCatalogEntryView entry) => entry.id;

String _moveCatalogEntryLabel(PokemonMoveCatalogEntryView entry) => entry.name;

Iterable<String> _moveCatalogEntrySearchTerms(
  PokemonMoveCatalogEntryView entry,
) {
  return <String>[
    entry.id,
    entry.name,
    entry.type ?? '',
    entry.category ?? '',
    entry.shortDesc ?? '',
  ];
}

```

## `packages/map_editor/test/local_catalog_lookup_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/services/local_catalog_lookup_service.dart';

void main() {
  const service = ProgressiveLocalCatalogLookupService<_FakeCatalogEntry>(
    idOf: _entryId,
    labelOf: _entryLabel,
    searchTermsOf: _entrySearchTerms,
  );

  group('ProgressiveLocalCatalogLookupService', () {
    test('finds an entry by exact local id', () {
      final entry = service.findById(_entries, 'tackle');

      expect(entry, isNotNull);
      expect(entry!.name, 'Tackle');
    });

    test('search ranks exact label before partial matches', () {
      final results = service.search(_entries, 'growl');

      expect(results.first.id, 'growl');
    });

    test('search returns prefix then partial matches with stable ordering', () {
      final results = service.search(_entries, 'vi');

      expect(
        results.map((entry) => entry.id).toList(growable: false),
        <String>['vine_whip', 'vital_throw'],
      );
    });

    test('returns an empty result when limit is zero', () {
      final results = service.search(_entries, 'tackle', limit: 0);

      expect(results, isEmpty);
    });
  });
}

class _FakeCatalogEntry {
  const _FakeCatalogEntry({
    required this.id,
    required this.name,
    this.tags = const <String>[],
  });

  final String id;
  final String name;
  final List<String> tags;
}

const List<_FakeCatalogEntry> _entries = <_FakeCatalogEntry>[
  _FakeCatalogEntry(id: 'growl', name: 'Growl', tags: <String>['status']),
  _FakeCatalogEntry(id: 'tackle', name: 'Tackle', tags: <String>['physical']),
  _FakeCatalogEntry(
    id: 'vital_throw',
    name: 'Vital Throw',
    tags: <String>['fighting'],
  ),
  _FakeCatalogEntry(
    id: 'vine_whip',
    name: 'Vine Whip',
    tags: <String>['grass'],
  ),
];

String _entryId(_FakeCatalogEntry entry) => entry.id;

String _entryLabel(_FakeCatalogEntry entry) => entry.name;

Iterable<String> _entrySearchTerms(_FakeCatalogEntry entry) {
  return <String>[entry.id, entry.name, ...entry.tags];
}

```

## `packages/map_editor/test/pokemon_moves_catalog_lookup_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/services/local_catalog_lookup_service.dart';
import 'package:map_editor/src/application/services/pokemon_moves_catalog_lookup_service.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';

void main() {
  const service = PokemonMovesCatalogLookupService();

  group('PokemonMovesCatalogLookupService', () {
    test('reuses the shared progressive local catalog lookup service', () {
      expect(
        service,
        isA<
            ProgressiveLocalCatalogLookupService<
                PokemonMoveCatalogEntryView>>(),
      );
    });

    test('finds a move by its exact local id', () {
      final entry = service.findById(_entries, 'vine_whip');

      expect(entry, isNotNull);
      expect(entry!.name, 'Vine Whip');
    });

    test('searches by move id and name with stable local results', () {
      final idResults = service.search(_entries, 'vine');
      final nameResults = service.search(_entries, 'tackle');

      expect(
        idResults.map((entry) => entry.id).toList(growable: false),
        contains('vine_whip'),
      );
      expect(nameResults.first.id, 'tackle');
    });

    test('returns no result for an unknown local move query', () {
      final results = service.search(_entries, 'missing_move');

      expect(results, isEmpty);
    });
  });
}

const List<PokemonMoveCatalogEntryView> _entries =
    <PokemonMoveCatalogEntryView>[
  PokemonMoveCatalogEntryView(
    id: 'growl',
    name: 'Growl',
    type: 'normal',
    category: 'status',
    pp: 40,
  ),
  PokemonMoveCatalogEntryView(
    id: 'tackle',
    name: 'Tackle',
    type: 'normal',
    category: 'physical',
    power: 40,
    accuracy: 100,
    pp: 35,
  ),
  PokemonMoveCatalogEntryView(
    id: 'vine_whip',
    name: 'Vine Whip',
    type: 'grass',
    category: 'physical',
    power: 45,
    accuracy: 100,
    pp: 25,
  ),
];

```
