# Phase R1 — Lot 1 — Résolveur de requête externe Pokédex

## 1. Résumé exécutif honnête

Le lot 1 est **terminé dans son scope**.

Un résolveur applicatif pur a été ajouté dans `map_editor` pour transformer une saisie brute d'import Pokédex en **intention structurée**. Ce lot ne touche ni le pipeline d'import 11A, ni le réseau, ni l'UI du wizard, ni le bridge runtime -> battle.

Le résultat couvre bien les intentions prévues :

- mono-espèce textuelle ;
- numéro dex unitaire ;
- plage dex ;
- génération ;
- liste explicite séparée par des virgules ;
- erreurs structurées en cas de vide, ambiguïté ou format invalide.

Le choix d'architecture retenu a été volontairement minimal :

- **modèles applicatifs dédiés** pour la résolution ;
- **service pur** `PokemonExternalQueryResolver` ;
- **provider Riverpod léger** pour préparer le wiring ;
- **aucun use case artificiel** ajouté, car il n'était pas justifié dans ce lot.

Validation réelle :

- `dart format` ciblé ;
- `flutter analyze --no-pub` ciblé ;
- `flutter test` ciblé ;
- tous verts après un mini-fix de commentaire de fichier.

## 2. État initial audité

Avant modification, l'existant montrait ceci :

- le pipeline d'import externe Pokémon de la phase 11A existait déjà dans `import_external_pokemon_use_cases.dart` ;
- les providers Pokédex existaient déjà dans `pokedex_providers.dart` ;
- le wizard Pokédex existait déjà dans `pokedex_import_flow.dart` et `pokedex_import_flow_steps.dart` ;
- la logique du wizard ne disposait pas encore d'un **résolveur applicatif dédié** pour convertir une saisie utilisateur en intention structurée ;
- aucun modèle applicatif clair n'exprimait encore les formes `single / list / range / generation / invalid` ;
- le wiring DI Pokédex n'exposait pas encore de provider de résolveur dédié ;
- le lot 11B avait déjà introduit le moves catalog local, mais cela était hors scope pour ce lot 1.

Conclusion d'audit retenue :

- la responsabilité correcte vit dans `map_editor`, côté `application/services` et `application/models` ;
- il ne fallait pas ajouter de parsing métier dans l'UI ;
- il ne fallait pas toucher le pipeline d'import existant ;
- un **service pur** suffisait pour ce lot.

## 3. Périmètre inclus / exclu

### Inclus

- modèles applicatifs de résolution de requête ;
- service applicatif pur de résolution ;
- provider Riverpod minimal pour l'exposer proprement ;
- tests dédiés au résolveur ;
- test de wiring provider ;
- report final complet.

### Exclu

- auto-complétion UI ;
- dry-run batch ;
- exécution batch ;
- import réseau ;
- modifications du pipeline 11A ;
- modifications du wizard complet ;
- bridge runtime -> battle ;
- runtime, save, battle, gameplay ;
- catalogues abilities/items/types/etc. ;
- tout autre lot de la roadmap.

## 4. Décisions d’architecture

### Décision 1 — Pas de nouveau pipeline

Le résolveur n'importe rien. Il ne preview rien. Il ne batch rien. Il exprime seulement une intention structurée.

Cette décision respecte la roadmap et évite de rouvrir artificiellement la 11A.

### Décision 2 — Pas de use case artificiel

Un use case séparé a été envisagé, puis rejeté.

Raison :

- le besoin de ce lot est une logique pure, déterministe, sans orchestration ;
- ajouter un use case uniquement pour envelopper un service aurait créé une couche de plus sans gain réel ;
- le style existant du repo tolère très bien un service applicatif pur exposé via provider lorsqu'il n'y a ni IO ni orchestration métier plus large.

### Décision 3 — Modèles dédiés à l'intention, pas à l'import

Les modèles ajoutés ne représentent ni un import, ni une preview, ni une espèce résolue côté source externe.

Ils représentent uniquement :

- une intention unitaire ;
- une liste explicite ;
- une plage dex ;
- une génération ;
- ou une invalidité structurée.

### Décision 4 — Refus des ambiguïtés

Le résolveur est volontairement conservateur :

- `pikachu, eevee, abra` est accepté comme liste explicite ;
- `pikachu eevee abra` est refusé comme ambigu ;
- les requêtes malformed de type `1-`, `151-1`, `generation x` sont refusées explicitement.

Le but est d'éviter que le futur wizard recode des heuristiques floues.

### Décision 5 — Wiring DI minimal uniquement

Le provider ajouté ne branche pas encore l'UI. Il expose juste le résolveur pour les prochains lots.

## 5. Liste exacte des fichiers modifiés / créés / supprimés

### Créés

- `packages/map_editor/lib/src/application/models/pokemon_external_query_resolution.dart`
- `packages/map_editor/lib/src/application/services/pokemon_external_query_resolver.dart`
- `packages/map_editor/test/pokemon_external_query_resolver_test.dart`
- `reports/phase-r1-lot-1-pokedex-query-resolver-report.md`

### Modifiés

- `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`
- `packages/map_editor/test/provider_wiring_test.dart`

### Supprimés

- aucun

## 6. Justification fichier par fichier

### `packages/map_editor/lib/src/application/models/pokemon_external_query_resolution.dart`

Ajout nécessaire pour exprimer proprement l'intention structurée.

Pourquoi c'est minimal :

- pas de JSON ajouté ;
- pas de modèle d'import ;
- pas de dépendance réseau ;
- seulement les formes nécessaires au lot 1.

### `packages/map_editor/lib/src/application/services/pokemon_external_query_resolver.dart`

Ajout du coeur du lot.

Pourquoi c'est minimal :

- service pur ;
- aucune dépendance UI ;
- aucune dépendance repository externe ;
- aucune écriture projet ;
- aucune lecture PokeAPI / Showdown ;
- uniquement parsing, normalisation, classification, déduplication et erreurs structurées.

### `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`

Modification minimale pour exposer le résolveur via Riverpod.

Pourquoi c'est minimal :

- simple import ;
- simple provider ;
- aucun nouveau notifier ;
- aucune logique métier ajoutée au provider.

### `packages/map_editor/test/pokemon_external_query_resolver_test.dart`

Ajout de la couverture centrale du lot.

Pourquoi c'est nécessaire :

- prouve les formats supportés ;
- prouve les refus de cas ambigus ;
- prouve la normalisation ;
- prouve la déduplication ;
- verrouille le scope du service.

### `packages/map_editor/test/provider_wiring_test.dart`

Modification minimale pour vérifier que le provider DI se résout correctement.

Pourquoi c'est minimal :

- un seul `expect` ajouté ;
- pas de refonte du test existant.

### `reports/phase-r1-lot-1-pokedex-query-resolver-report.md`

Ajout du report demandé.

Pourquoi il est nécessaire :

- le prompt l'exige explicitement ;
- il documente l'audit, les choix, les commandes, les résultats et l'annexe complète des fichiers texte touchés.

## 7. Sub-agents utilisés et conclusions

### Boyle — `019d81fd-7906-74c1-9005-b84399f7700e`

Mission :

- audit strict de scope et de placement architectural.

Conclusion retenue :

- le résolveur doit vivre dans `application/services` ;
- un provider DI minimal est cohérent ;
- il ne faut ni toucher au réseau, ni à l'UI, ni au pipeline d'import ;
- un service suffit, sans use case artificiel.

### Mendel — `019d81fd-79ff-7213-9215-a788ac13b984`

Mission :

- audit de matrice de tests.

Conclusion retenue :

- couvrir séparément les cas single, dex, range, generation, explicit list ;
- couvrir les cas invalides et ambigus ;
- couvrir la déduplication.

### Avicenna — `019d81fd-7b05-7302-8681-e779fd0d6a36`

Mission :

- audit du modèle applicatif minimal.

Conclusion retenue :

- garder les modèles petits ;
- ne pas mélanger résolution d'intention et existence réelle d'une espèce source ;
- éviter d'introduire des statuts qui relèvent de lots ultérieurs.

### Note honnête sur l'usage des sub-agents

Le pool de threads existant était déjà ouvert. J'ai donc réutilisé des sub-agents existants via `send_input` plutôt que de repartir sur de nouvelles créations.

Un des retours réutilisés a partiellement dérivé vers un contexte plus ancien d'import externe ; cette partie a été explicitement rejetée et n'a pas été retenue pour ce lot 1.

## 8. Commandes réellement exécutées

### Audit initial

```bash
ls -la
git status --short
rg -n "phase 11A|phase 11B|moves catalog|roadmap|clôturable|final closure" reports packages -g '*.md' -g '*.dart'
find . -maxdepth 1 -type f | sort
sed -n '1,260p' packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart
sed -n '1,260p' packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart
sed -n '1,260p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart
sed -n '1,260p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart
sed -n '1,260p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart
sed -n '260,520p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart
sed -n '1,260p' packages/map_editor/lib/src/application/use_cases/use_cases.dart
ls packages/map_editor/lib/src/application/models
ls packages/map_editor/lib/src/application/services
sed -n '1,260p' packages/map_editor/test/provider_wiring_test.dart
sed -n '1,260p' packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart
sed -n '1,260p' packages/map_editor/test/import_external_pokemon_use_cases_test.dart
rg -n "class .*UseCase|typedef .*Loader|Provider<.*UseCase|search.*catalog|query" packages/map_editor/lib/src/application packages/map_editor/lib/src/app/providers -g '*.dart'
ls packages/map_editor/lib/src/app/providers | sed -n '1,120p'
sed -n '1,220p' packages/map_editor/lib/src/app/providers/pokedex_providers.dart
rg --files -g 'AGENTS.md'
```

### Validation et captures finales

```bash
dart format /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_external_query_resolution.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_external_query_resolver.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_external_query_resolver_test.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/provider_wiring_test.dart

cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub lib/src/application/models/pokemon_external_query_resolution.dart lib/src/application/services/pokemon_external_query_resolver.dart lib/src/app/providers/pokedex/pokedex_providers.dart test/pokemon_external_query_resolver_test.dart test/provider_wiring_test.dart

dart format /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_external_query_resolution.dart

cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub lib/src/application/models/pokemon_external_query_resolution.dart lib/src/application/services/pokemon_external_query_resolver.dart lib/src/app/providers/pokedex/pokedex_providers.dart test/pokemon_external_query_resolver_test.dart test/provider_wiring_test.dart

cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/pokemon_external_query_resolver_test.dart test/provider_wiring_test.dart

git status --short -- packages/map_editor/lib/src/application/models/pokemon_external_query_resolution.dart packages/map_editor/lib/src/application/services/pokemon_external_query_resolver.dart packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart packages/map_editor/test/pokemon_external_query_resolver_test.dart packages/map_editor/test/provider_wiring_test.dart reports/phase-r1-lot-1-pokedex-query-resolver-report.md

git diff --stat -- packages/map_editor/lib/src/application/models/pokemon_external_query_resolution.dart packages/map_editor/lib/src/application/services/pokemon_external_query_resolver.dart packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart packages/map_editor/test/pokemon_external_query_resolver_test.dart packages/map_editor/test/provider_wiring_test.dart reports/phase-r1-lot-1-pokedex-query-resolver-report.md

git ls-files --others --exclude-standard -- reports/phase-r1-lot-1-pokedex-query-resolver-report.md

cat packages/map_editor/lib/src/application/models/pokemon_external_query_resolution.dart
cat packages/map_editor/lib/src/application/services/pokemon_external_query_resolver.dart
cat packages/map_editor/test/pokemon_external_query_resolver_test.dart
cat packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart
cat packages/map_editor/test/provider_wiring_test.dart

dart format /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_external_query_resolver.dart

cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub lib/src/application/models/pokemon_external_query_resolution.dart lib/src/application/services/pokemon_external_query_resolver.dart lib/src/app/providers/pokedex/pokedex_providers.dart test/pokemon_external_query_resolver_test.dart test/provider_wiring_test.dart

cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/pokemon_external_query_resolver_test.dart test/provider_wiring_test.dart
```

## 9. Résultats réels

### Résultats fonctionnels

Le résolveur gère maintenant proprement :

- `bulbasaur`
- `Bulbasaur`
- `  bulbasaur  `
- `1`
- `001`
- `0001`
- `1-151`
- `1 - 151`
- `gen 1`
- `Gen 1`
- `generation 1`
- `pikachu,eevee,abra`
- `pikachu, eevee, abra`
- déduplication des doublons dans les listes explicites.

Et il refuse explicitement :

- vide ;
- espaces seuls ;
- `pikachu eevee abra` ;
- `1-` ;
- `151-1` ;
- `gen 0` ;
- `generation x` ;
- listes explicites incohérentes.

### Résultats des validations

#### `dart format`

Premier run :

```text
Formatted /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_external_query_resolver.dart
Formatted 5 files (1 changed) in 0.02 seconds.
```

Deuxième run après mini-nettoyage :

```text
Formatted 1 file (0 changed) in 0.01 seconds.
```

#### `flutter analyze --no-pub`

Premier run :

```text
info • Dangling library doc comment • lib/src/application/models/pokemon_external_query_resolution.dart:19:1 • dangling_library_doc_comments
```

Après correction :

```text
No issues found! (ran in 1.2s)
```

Puis revalidation finale après mini-nettoyage du service :

```text
No issues found! (ran in 1.5s)
```

#### `flutter test`

Premier run vert :

```text
00:01 +24: All tests passed!
```

Revalidation finale après mini-nettoyage du service :

```text
00:01 +24: All tests passed!
```

## 10. Incidents rencontrés

### Incident 1 — Commentaire de bibliothèque mal reconnu par l'analyseur

Le premier `flutter analyze --no-pub` a signalé :

- `dangling_library_doc_comments`

Cause :

- un commentaire doc de tête dans `pokemon_external_query_resolution.dart` n'était pas attaché à une déclaration de bibliothèque.

Correction :

- conversion en commentaires classiques de fichier.

### Incident 2 — Lock de démarrage Flutter

Le deuxième cycle `analyze` + `test` a brièvement attendu :

```text
Waiting for another flutter command to release the startup lock...
```

Ce n'était pas bloquant. Les deux commandes ont fini correctement.

### Incident 3 — Réutilisation de sub-agent avec contexte ancien

Un retour de sub-agent réutilisé a partiellement reflété un ancien contexte d'import externe plus large.

Décision :

- cette partie a été rejetée ;
- seules les conclusions utiles au lot 1 ont été conservées.

## 11. État git utile

### `git status --short -- ...`

```text
 M packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart
 M packages/map_editor/test/provider_wiring_test.dart
?? packages/map_editor/lib/src/application/models/pokemon_external_query_resolution.dart
?? packages/map_editor/lib/src/application/services/pokemon_external_query_resolver.dart
?? packages/map_editor/test/pokemon_external_query_resolver_test.dart
?? reports/phase-r1-lot-1-pokedex-query-resolver-report.md
```

### `git diff --stat -- ...`

```text
 .../lib/src/app/providers/pokedex/pokedex_providers.dart     | 12 ++++++++++++
 packages/map_editor/test/provider_wiring_test.dart           |  1 +
 2 files changed, 13 insertions(+)
```

Note honnête :

- ce `git diff --stat` standard n'inclut que les fichiers déjà suivis par git ;
- les nouveaux fichiers du lot apparaissent bien dans `git status --short` ;
- le report non tracké apparaît aussi dans `git ls-files --others --exclude-standard`.

### `git ls-files --others --exclude-standard -- reports/phase-r1-lot-1-pokedex-query-resolver-report.md`

```text
reports/phase-r1-lot-1-pokedex-query-resolver-report.md
```

## 12. Checklist finale

- [x] audit initial de l'existant effectué
- [x] scope resté strictement limité au lot 1
- [x] aucun nouveau pipeline d'import créé
- [x] aucune logique réseau ajoutée
- [x] aucune logique métier déplacée dans l'UI
- [x] modèles applicatifs de résolution ajoutés
- [x] service pur de résolution ajouté
- [x] provider DI minimal ajouté
- [x] tests dédiés ajoutés
- [x] ambiguïtés refusées explicitement
- [x] `dart format` exécuté
- [x] `flutter analyze --no-pub` exécuté
- [x] `flutter test` ciblé exécuté
- [x] report final créé
- [x] contenu complet des fichiers texte modifiés/créés annexé
- [x] aucune écriture git de type commit/merge/rebase/push/tag/amend

## 13. Contenu complet de tous les fichiers texte modifiés / créés

Note explicite :

- cette annexe inclut l'intégralité des fichiers texte modifiés/créés par ce lot ;
- **le report lui-même n'est pas recopié dans sa propre annexe** pour éviter une récursion infinie.

### 13.1 `packages/map_editor/lib/src/application/models/pokemon_external_query_resolution.dart`

```dart
// Modèles de résolution d'une requête d'import Pokédex externe.
//
// Ce fichier ne représente PAS un import, une preview, un batch exécuté
// ni une interaction réseau.
//
// Il représente seulement l'intention utilisateur telle qu'elle a été
// comprise par le résolveur du lot 1 :
// - une cible unitaire par nom/id ;
// - un numéro Pokédex unique ;
// - une plage dex ;
// - une génération ;
// - une liste explicite séparée par des virgules ;
// - ou une requête invalide/ambiguë.
//
// Cette séparation est importante pour la suite de la roadmap :
// - l'UI n'a pas à parser la saisie ;
// - le pipeline d'import 11A n'a pas à être réécrit ;
// - le lot 1 fournit uniquement une base stable réutilisable par
//   l'auto-complétion mono-espèce, le batch preview et l'exécution batch.

/// Nature de la résolution produite par le résolveur.
///
/// L'objectif est de permettre à l'UI et aux use cases futurs de raisonner
/// sur une intention claire sans réinterpréter la string d'origine.
enum PokemonExternalQueryResolutionKind {
  singleQuery,
  explicitList,
  nationalDexRange,
  generation,
  invalid,
}

/// Type d'une cible unitaire dans la saisie.
///
/// Une cible unitaire peut être :
/// - une requête textuelle d'espèce (`bulbasaur`, `porygon-z`) ;
/// - un numéro Pokédex (`1`, `001`, `0001`).
///
/// On garde explicitement cette distinction parce qu'un batch explicite peut
/// mélanger les deux sans que cela doive devenir un problème UI.
enum PokemonExternalSingleQueryKind {
  species,
  nationalDex,
}

/// Codes d'erreur structurés pour les requêtes invalides.
///
/// Ces codes évitent de dépendre de simples messages texte dans les tests ou
/// dans l'UI future. Le message reste fourni pour l'utilisateur, mais le code
/// constitue la vraie convention stable.
enum PokemonExternalInvalidQueryCode {
  emptyQuery,
  ambiguousWhitespaceSeparatedTerms,
  invalidNationalDex,
  invalidNationalDexRange,
  invalidGeneration,
  invalidExplicitList,
  unsupportedFormat,
}

/// Représente une cible unitaire déjà normalisée.
///
/// Elle reste volontairement minimale :
/// - pas d'information réseau ;
/// - pas de résolution vers une vraie espèce projet/source ;
/// - seulement une expression canonique locale de la saisie utilisateur.
class PokemonExternalSingleQuery {
  /// Construit une cible unitaire textuelle.
  const PokemonExternalSingleQuery.species({
    required this.rawValue,
    required this.normalizedValue,
  })  : kind = PokemonExternalSingleQueryKind.species,
        nationalDex = null;

  /// Construit une cible unitaire de type numéro Pokédex.
  const PokemonExternalSingleQuery.nationalDex({
    required this.rawValue,
    required this.nationalDex,
  })  : kind = PokemonExternalSingleQueryKind.nationalDex,
        normalizedValue = null;

  final PokemonExternalSingleQueryKind kind;

  /// Fragment brut après nettoyage local de son entrée de liste éventuelle.
  final String rawValue;

  /// Valeur textuelle normalisée pour une requête d'espèce.
  ///
  /// Toujours en minuscules, avec espaces parasites supprimés.
  final String? normalizedValue;

  /// Numéro dex normalisé pour une requête numérique.
  final int? nationalDex;

  /// Clé stable de déduplication.
  ///
  /// La déduplication du lot 1 ne repose pas sur le texte brut saisi, mais sur
  /// l'intention canonique :
  /// - `001` et `1` doivent être vus comme la même cible ;
  /// - `Pikachu` et `pikachu` aussi.
  String get deduplicationKey => switch (kind) {
        PokemonExternalSingleQueryKind.species => 'species:$normalizedValue',
        PokemonExternalSingleQueryKind.nationalDex => 'dex:$nationalDex',
      };
}

/// Base commune de toutes les résolutions.
///
/// Toute résolution conserve :
/// - la saisie brute ;
/// - la saisie normalisée au niveau global ;
/// - le type de résolution obtenu.
sealed class PokemonExternalQueryResolution {
  const PokemonExternalQueryResolution({
    required this.rawQuery,
    required this.normalizedQuery,
  });

  final String rawQuery;
  final String normalizedQuery;

  PokemonExternalQueryResolutionKind get kind;
}

/// Résolution vers une seule cible.
final class PokemonExternalSingleQueryResolution
    extends PokemonExternalQueryResolution {
  const PokemonExternalSingleQueryResolution({
    required super.rawQuery,
    required super.normalizedQuery,
    required this.query,
  });

  final PokemonExternalSingleQuery query;

  @override
  PokemonExternalQueryResolutionKind get kind =>
      PokemonExternalQueryResolutionKind.singleQuery;
}

/// Résolution vers une liste explicite séparée par virgules.
final class PokemonExternalExplicitListQueryResolution
    extends PokemonExternalQueryResolution {
  PokemonExternalExplicitListQueryResolution({
    required super.rawQuery,
    required super.normalizedQuery,
    required List<PokemonExternalSingleQuery> queries,
  }) : queries = List<PokemonExternalSingleQuery>.unmodifiable(queries);

  /// Liste finale dédupliquée, dans l'ordre utilisateur stable.
  final List<PokemonExternalSingleQuery> queries;

  @override
  PokemonExternalQueryResolutionKind get kind =>
      PokemonExternalQueryResolutionKind.explicitList;
}

/// Résolution vers une plage dex.
final class PokemonExternalNationalDexRangeQueryResolution
    extends PokemonExternalQueryResolution {
  const PokemonExternalNationalDexRangeQueryResolution({
    required super.rawQuery,
    required super.normalizedQuery,
    required this.startNationalDex,
    required this.endNationalDex,
  });

  final int startNationalDex;
  final int endNationalDex;

  @override
  PokemonExternalQueryResolutionKind get kind =>
      PokemonExternalQueryResolutionKind.nationalDexRange;
}

/// Résolution vers une génération entière.
final class PokemonExternalGenerationQueryResolution
    extends PokemonExternalQueryResolution {
  const PokemonExternalGenerationQueryResolution({
    required super.rawQuery,
    required super.normalizedQuery,
    required this.generation,
  });

  final int generation;

  @override
  PokemonExternalQueryResolutionKind get kind =>
      PokemonExternalQueryResolutionKind.generation;
}

/// Résolution invalide ou ambiguë.
///
/// Ce type existe pour une raison de produit :
/// le lot 1 ne doit pas "deviner" silencieusement ce que l'utilisateur voulait
/// dire si la saisie est ambiguë. Il doit au contraire l'exprimer clairement.
final class PokemonExternalInvalidQueryResolution
    extends PokemonExternalQueryResolution {
  const PokemonExternalInvalidQueryResolution({
    required super.rawQuery,
    required super.normalizedQuery,
    required this.code,
    required this.message,
  });

  final PokemonExternalInvalidQueryCode code;
  final String message;

  @override
  PokemonExternalQueryResolutionKind get kind =>
      PokemonExternalQueryResolutionKind.invalid;
}
```

### 13.2 `packages/map_editor/lib/src/application/services/pokemon_external_query_resolver.dart`

```dart
import '../models/pokemon_external_query_resolution.dart';

/// Résolveur pur de requête d'import Pokédex externe.
///
/// Ce service ne fait qu'une chose :
/// transformer une string utilisateur brute en intention structurée.
///
/// Non-objectifs explicites du lot 1 :
/// - aucun accès réseau ;
/// - aucune lecture PokeAPI / Showdown ;
/// - aucune écriture projet ;
/// - aucune preview d'import ;
/// - aucune exécution batch ;
/// - aucune logique UI.
///
/// Ce résolveur est volontairement conservateur :
/// - il accepte les formes explicitement supportées ;
/// - il refuse les saisies ambiguës plutôt que de deviner ;
/// - il déduplique les listes explicites ;
/// - il garde une sémantique strictement déterministe.
class PokemonExternalQueryResolver {
  const PokemonExternalQueryResolver();

  static final RegExp _digitsPattern = RegExp(r'^\d+$');
  static final RegExp _nationalDexRangePattern = RegExp(r'^(\d+)\s*-\s*(\d+)$');
  static final RegExp _generationPattern =
      RegExp(r'^(?:gen|generation)\s+(\d+)$');

  /// Règle volontairement stricte pour les requêtes unitaires textuelles.
  ///
  /// On accepte les ids/noms simples de type slug/identifiant. En revanche,
  /// une suite de mots séparés par des espaces sans virgule explicite est
  /// refusée pour éviter de prendre silencieusement une liste ambiguë pour une
  /// espèce unique.
  static final RegExp _singleSpeciesTokenPattern =
      RegExp(r"^[a-z0-9][a-z0-9._'-]*$");

  /// Résout une saisie brute en intention structurée.
  PokemonExternalQueryResolution resolve(String rawQuery) {
    final normalizedQuery = _normalizeGlobalInput(rawQuery);
    final loweredQuery = normalizedQuery.toLowerCase();

    if (normalizedQuery.isEmpty) {
      return PokemonExternalInvalidQueryResolution(
        rawQuery: rawQuery,
        normalizedQuery: normalizedQuery,
        code: PokemonExternalInvalidQueryCode.emptyQuery,
        message: 'La requête est vide.',
      );
    }

    // Une liste n'est reconnue que si le séparateur est explicite.
    // Cela évite qu'une saisie du type "pikachu eevee abra" soit interprétée
    // silencieusement comme un batch, ce que le lot 1 doit refuser.
    if (normalizedQuery.contains(',')) {
      return _resolveExplicitList(rawQuery, normalizedQuery);
    }

    final rangeMatch = _nationalDexRangePattern.firstMatch(loweredQuery);
    if (rangeMatch != null) {
      return _resolveNationalDexRange(rawQuery, normalizedQuery, rangeMatch);
    }
    if (_looksLikeNationalDexRangeCandidate(loweredQuery)) {
      return PokemonExternalInvalidQueryResolution(
        rawQuery: rawQuery,
        normalizedQuery: normalizedQuery,
        code: PokemonExternalInvalidQueryCode.invalidNationalDexRange,
        message:
            'La plage Pokédex demandée est invalide. Utilisez une forme du '
            'type `1-151`.',
      );
    }

    final generationMatch = _generationPattern.firstMatch(loweredQuery);
    if (generationMatch != null) {
      return _resolveGeneration(rawQuery, normalizedQuery, generationMatch);
    }
    if (_looksLikeGenerationCandidate(loweredQuery)) {
      return PokemonExternalInvalidQueryResolution(
        rawQuery: rawQuery,
        normalizedQuery: normalizedQuery,
        code: PokemonExternalInvalidQueryCode.invalidGeneration,
        message: 'La génération demandée est invalide. Utilisez une forme du '
            'type `gen 1` ou `generation 1`.',
      );
    }

    if (_looksLikeAmbiguousWhitespaceSeparatedTerms(normalizedQuery)) {
      return PokemonExternalInvalidQueryResolution(
        rawQuery: rawQuery,
        normalizedQuery: normalizedQuery,
        code: PokemonExternalInvalidQueryCode.ambiguousWhitespaceSeparatedTerms,
        message:
            'La requête contient plusieurs termes séparés par des espaces. '
            'Utilisez des virgules pour une liste explicite.',
      );
    }

    final singleQuery = _resolveSingleQuery(rawValue: normalizedQuery);

    if (singleQuery == null) {
      return PokemonExternalInvalidQueryResolution(
        rawQuery: rawQuery,
        normalizedQuery: normalizedQuery,
        code: PokemonExternalInvalidQueryCode.unsupportedFormat,
        message:
            'Le format de requête n’est pas reconnu pour un import externe.',
      );
    }

    return PokemonExternalSingleQueryResolution(
      rawQuery: rawQuery,
      normalizedQuery: normalizedQuery,
      query: singleQuery,
    );
  }

  PokemonExternalQueryResolution _resolveExplicitList(
    String rawQuery,
    String normalizedQuery,
  ) {
    final rawEntries = normalizedQuery.split(',');
    final queries = <PokemonExternalSingleQuery>[];
    final seenKeys = <String>{};

    for (final rawEntry in rawEntries) {
      final normalizedEntry = _normalizeGlobalInput(rawEntry);
      if (normalizedEntry.isEmpty) {
        return PokemonExternalInvalidQueryResolution(
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
          code: PokemonExternalInvalidQueryCode.invalidExplicitList,
          message: 'La liste explicite contient au moins une entrée vide ou un '
              'séparateur incohérent.',
        );
      }

      final loweredEntry = normalizedEntry.toLowerCase();
      if (_nationalDexRangePattern.hasMatch(loweredEntry) ||
          _generationPattern.hasMatch(loweredEntry) ||
          _looksLikeAmbiguousWhitespaceSeparatedTerms(normalizedEntry)) {
        return PokemonExternalInvalidQueryResolution(
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
          code: PokemonExternalInvalidQueryCode.invalidExplicitList,
          message: 'Chaque entrée de la liste doit être une cible simple '
              '(espèce ou numéro dex), séparée par des virgules.',
        );
      }

      final query = _resolveSingleQuery(rawValue: normalizedEntry);
      if (query == null) {
        return PokemonExternalInvalidQueryResolution(
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
          code: PokemonExternalInvalidQueryCode.invalidExplicitList,
          message: 'La liste explicite contient au moins une entrée invalide.',
        );
      }

      if (seenKeys.add(query.deduplicationKey)) {
        queries.add(query);
      }
    }

    return PokemonExternalExplicitListQueryResolution(
      rawQuery: rawQuery,
      normalizedQuery: normalizedQuery,
      queries: queries,
    );
  }

  PokemonExternalQueryResolution _resolveNationalDexRange(
    String rawQuery,
    String normalizedQuery,
    RegExpMatch rangeMatch,
  ) {
    final start = int.tryParse(rangeMatch.group(1)!);
    final end = int.tryParse(rangeMatch.group(2)!);

    if (start == null ||
        end == null ||
        start <= 0 ||
        end <= 0 ||
        start >= end) {
      return PokemonExternalInvalidQueryResolution(
        rawQuery: rawQuery,
        normalizedQuery: normalizedQuery,
        code: PokemonExternalInvalidQueryCode.invalidNationalDexRange,
        message: 'La plage Pokédex doit contenir deux nombres positifs dans '
            'l’ordre croissant.',
      );
    }

    return PokemonExternalNationalDexRangeQueryResolution(
      rawQuery: rawQuery,
      normalizedQuery: normalizedQuery,
      startNationalDex: start,
      endNationalDex: end,
    );
  }

  PokemonExternalQueryResolution _resolveGeneration(
    String rawQuery,
    String normalizedQuery,
    RegExpMatch generationMatch,
  ) {
    final generation = int.tryParse(generationMatch.group(1)!);
    if (generation == null || generation <= 0) {
      return PokemonExternalInvalidQueryResolution(
        rawQuery: rawQuery,
        normalizedQuery: normalizedQuery,
        code: PokemonExternalInvalidQueryCode.invalidGeneration,
        message: 'La génération demandée est invalide.',
      );
    }

    return PokemonExternalGenerationQueryResolution(
      rawQuery: rawQuery,
      normalizedQuery: normalizedQuery,
      generation: generation,
    );
  }

  PokemonExternalSingleQuery? _resolveSingleQuery({
    required String rawValue,
  }) {
    final normalizedValue = _normalizeGlobalInput(rawValue);
    if (normalizedValue.isEmpty) {
      return null;
    }

    if (_digitsPattern.hasMatch(normalizedValue)) {
      final nationalDex = int.tryParse(normalizedValue);
      if (nationalDex == null || nationalDex <= 0) {
        return null;
      }
      return PokemonExternalSingleQuery.nationalDex(
        rawValue: normalizedValue,
        nationalDex: nationalDex,
      );
    }

    final loweredValue = normalizedValue.toLowerCase();
    if (!_singleSpeciesTokenPattern.hasMatch(loweredValue)) {
      return null;
    }

    return PokemonExternalSingleQuery.species(
      rawValue: normalizedValue,
      normalizedValue: loweredValue,
    );
  }

  bool _looksLikeAmbiguousWhitespaceSeparatedTerms(String value) {
    final collapsed = _normalizeGlobalInput(value);
    if (!collapsed.contains(' ')) {
      return false;
    }

    // Toute suite de plusieurs termes séparés par espaces, sans séparateur
    // explicite de liste, est traitée comme ambiguë dans ce lot. On préfère
    // refuser et demander des virgules plutôt que de parser silencieusement
    // une pseudo-liste dans l'UI.
    return collapsed.split(' ').where((token) => token.isNotEmpty).length > 1;
  }

  bool _looksLikeNationalDexRangeCandidate(String loweredValue) {
    return loweredValue.contains('-') &&
        RegExp(r'^[\d\s-]+$').hasMatch(loweredValue);
  }

  bool _looksLikeGenerationCandidate(String loweredValue) {
    return loweredValue == 'gen' ||
        loweredValue == 'generation' ||
        loweredValue.startsWith('gen ') ||
        loweredValue.startsWith('generation ');
  }

  String _normalizeGlobalInput(String rawValue) {
    return rawValue.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
```

### 13.3 `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../application/ports/pokemon_read_repository.dart';
import '../../../application/ports/pokemon_external_source_repository.dart';
import '../../../application/ports/pokemon_write_repository.dart';
import '../../../application/services/pokemon_database_index.dart';
import '../../../application/services/pokemon_external_query_resolver.dart';
import '../../../application/use_cases/import_external_pokemon_use_cases.dart';
import '../../../application/use_cases/import_pokemon_evolution_json_use_case.dart';
import '../../../application/use_cases/import_pokemon_json_bundle_use_case.dart';
import '../../../application/use_cases/import_pokemon_learnset_json_use_case.dart';
import '../../../application/use_cases/import_pokemon_media_json_use_case.dart';
import '../../../application/use_cases/import_pokemon_species_json_use_case.dart';
import '../../../application/use_cases/delete_pokedex_species_use_case.dart';
import '../../../application/use_cases/load_pokedex_species_detail_use_case.dart';
import '../../../application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_evolution_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_forms_classification_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_learnset_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_metadata_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_media_use_case.dart';
import '../../../infrastructure/external/pokeapi_live_source.dart';
import '../../../infrastructure/external/showdown_snapshot_source.dart';
import '../../../infrastructure/repositories/http_pokemon_external_source_repository.dart';
import '../../../infrastructure/repositories/file_repositories.dart';
import '../../../ui/canvas/pokedex_workspace_loader.dart';
import '../core/repository_providers.dart';

/// Wiring Pokédex local minimal.
///
/// Ce fichier reste volontairement petit et thématique :
/// - le workspace Pokédex n'instancie plus l'infrastructure directement ;
/// - on réutilise les repositories/services existants ;
/// - on ne crée pas un nouveau notifier ni une couche "future-proof" inutile.
final pokemonReadRepositoryProvider = Provider<PokemonReadRepository>((ref) {
  return const FilePokemonReadRepository();
});

final pokemonWriteRepositoryProvider = Provider<PokemonWriteRepository>((ref) {
  return const FilePokemonWriteRepository();
});

final pokemonExternalHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final pokeApiLiveSourceProvider = Provider<PokeApiLiveSource>((ref) {
  return PokeApiLiveSource(
    client: ref.watch(pokemonExternalHttpClientProvider),
  );
});

final showdownSnapshotSourceProvider = Provider<ShowdownSnapshotSource>((ref) {
  return ShowdownSnapshotSource(
    client: ref.watch(pokemonExternalHttpClientProvider),
  );
});

final pokemonExternalSourceRepositoryProvider =
    Provider<PokemonExternalSourceRepository>((ref) {
  return HttpPokemonExternalSourceRepository(
    pokeApiSource: ref.watch(pokeApiLiveSourceProvider),
    showdownSource: ref.watch(showdownSnapshotSourceProvider),
  );
});

final pokemonDatabaseIndexProvider = Provider<PokemonDatabaseIndex>((ref) {
  return PokemonDatabaseIndex(
    projectRepository: ref.watch(projectRepositoryProvider),
    pokemonReadRepository: ref.watch(pokemonReadRepositoryProvider),
  );
});

/// Résolveur de requête brute -> intention structurée pour l'import externe.
///
/// Ce provider est volontairement minimal pour le lot 1 :
/// - il expose une logique pure ;
/// - il n'ajoute ni réseau, ni preview, ni import ;
/// - il prépare simplement le wiring propre des lots UI suivants.
final pokemonExternalQueryResolverProvider =
    Provider<PokemonExternalQueryResolver>((ref) {
  return const PokemonExternalQueryResolver();
});

final pokedexEntryLoaderProvider = Provider<PokedexEntryLoader>((ref) {
  return createPokedexEntryLoader(
    projectRepository: ref.watch(projectRepositoryProvider),
    databaseIndex: ref.watch(pokemonDatabaseIndexProvider),
  );
});

final pokedexListProvider = Provider<PokedexEntryLoader>((ref) {
  return ref.watch(pokedexEntryLoaderProvider);
});

final loadPokedexSpeciesDetailUseCaseProvider =
    Provider<LoadPokedexSpeciesDetailUseCase>((ref) {
  return LoadPokedexSpeciesDetailUseCase(
    ref.watch(pokemonReadRepositoryProvider),
  );
});

final deletePokedexSpeciesUseCaseProvider =
    Provider<DeletePokedexSpeciesUseCase>((ref) {
  return DeletePokedexSpeciesUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
  );
});

final pokedexSpeciesDeleterProvider = Provider<PokedexSpeciesDeleter>((ref) {
  final useCase = ref.watch(deletePokedexSpeciesUseCaseProvider);
  return (workspace, speciesId) => useCase.execute(workspace, speciesId);
});

final pokedexSpeciesDetailLoaderProvider =
    Provider<PokedexSpeciesDetailLoader>((ref) {
  final useCase = ref.watch(loadPokedexSpeciesDetailUseCaseProvider);
  return (workspace, speciesId) => useCase.execute(workspace, speciesId);
});

final importPokemonSpeciesJsonUseCaseProvider =
    Provider<ImportPokemonSpeciesJsonUseCase>((ref) {
  return ImportPokemonSpeciesJsonUseCase(
    ref.watch(pokemonWriteRepositoryProvider),
  );
});

final importPokemonLearnsetJsonUseCaseProvider =
    Provider<ImportPokemonLearnsetJsonUseCase>((ref) {
  return ImportPokemonLearnsetJsonUseCase(
    ref.watch(pokemonWriteRepositoryProvider),
  );
});

final importPokemonEvolutionJsonUseCaseProvider =
    Provider<ImportPokemonEvolutionJsonUseCase>((ref) {
  return ImportPokemonEvolutionJsonUseCase(
    ref.watch(pokemonWriteRepositoryProvider),
  );
});

final importPokemonMediaJsonUseCaseProvider =
    Provider<ImportPokemonMediaJsonUseCase>((ref) {
  return ImportPokemonMediaJsonUseCase(
    ref.watch(pokemonWriteRepositoryProvider),
  );
});

final importPokemonJsonBundleUseCaseProvider =
    Provider<ImportPokemonJsonBundleUseCase>((ref) {
  return ImportPokemonJsonBundleUseCase(
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
    speciesImportUseCase: ref.watch(importPokemonSpeciesJsonUseCaseProvider),
    learnsetImportUseCase: ref.watch(importPokemonLearnsetJsonUseCaseProvider),
    evolutionImportUseCase:
        ref.watch(importPokemonEvolutionJsonUseCaseProvider),
    mediaImportUseCase: ref.watch(importPokemonMediaJsonUseCaseProvider),
  );
});

final pokedexImportPreviewerProvider = Provider<PokedexImportPreviewer>((ref) {
  final useCase = ref.watch(importPokemonJsonBundleUseCaseProvider);
  return (workspace, absoluteSpeciesSourcePath) => useCase.preview(
        workspace,
        absoluteSpeciesSourcePath: absoluteSpeciesSourcePath,
      );
});

final pokedexImporterProvider = Provider<PokedexImporter>((ref) {
  final useCase = ref.watch(importPokemonJsonBundleUseCaseProvider);
  return (workspace, absoluteSpeciesSourcePath) => useCase.execute(
        workspace,
        absoluteSpeciesSourcePath: absoluteSpeciesSourcePath,
      );
});

final importExternalPokemonSpeciesUseCaseProvider =
    Provider<ImportExternalPokemonSpeciesUseCase>((ref) {
  return ImportExternalPokemonSpeciesUseCase(
    externalSourceRepository:
        ref.watch(pokemonExternalSourceRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final batchImportExternalPokemonSpeciesUseCaseProvider =
    Provider<BatchImportExternalPokemonSpeciesUseCase>((ref) {
  return BatchImportExternalPokemonSpeciesUseCase(
    ref.watch(importExternalPokemonSpeciesUseCaseProvider),
  );
});

final pokedexExternalImportPreviewerProvider =
    Provider<PokedexExternalImportPreviewer>((ref) {
  final useCase = ref.watch(importExternalPokemonSpeciesUseCaseProvider);
  return (workspace, speciesQuery) => useCase.execute(
        workspace,
        speciesId: speciesQuery,
        dryRun: true,
      );
});

final pokedexExternalImporterProvider =
    Provider<PokedexExternalImporter>((ref) {
  final useCase = ref.watch(importExternalPokemonSpeciesUseCaseProvider);
  return (workspace, speciesQuery) => useCase.execute(
        workspace,
        speciesId: speciesQuery,
      );
});

final loadPokemonMovesCatalogUseCaseProvider =
    Provider<LoadPokemonMovesCatalogUseCase>((ref) {
  return LoadPokemonMovesCatalogUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
  );
});

final syncExternalPokemonMovesCatalogUseCaseProvider =
    Provider<SyncExternalPokemonMovesCatalogUseCase>((ref) {
  return SyncExternalPokemonMovesCatalogUseCase(
    externalSourceRepository:
        ref.watch(pokemonExternalSourceRepositoryProvider),
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexMovesCatalogLoaderProvider =
    Provider<PokedexMovesCatalogLoader>((ref) {
  final useCase = ref.watch(loadPokemonMovesCatalogUseCaseProvider);
  return (workspace) => useCase.execute(workspace);
});

final pokedexMovesCatalogPreviewerProvider =
    Provider<PokedexMovesCatalogPreviewer>((ref) {
  final useCase = ref.watch(syncExternalPokemonMovesCatalogUseCaseProvider);
  return (workspace) => useCase.execute(workspace, dryRun: true);
});

final pokedexMovesCatalogSyncerProvider =
    Provider<PokedexMovesCatalogSyncer>((ref) {
  final useCase = ref.watch(syncExternalPokemonMovesCatalogUseCaseProvider);
  return (workspace) => useCase.execute(workspace);
});

final updatePokedexSpeciesMetadataUseCaseProvider =
    Provider<UpdatePokedexSpeciesMetadataUseCase>((ref) {
  return UpdatePokedexSpeciesMetadataUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexSpeciesMetadataSaverProvider =
    Provider<PokedexSpeciesMetadataSaver>((ref) {
  final useCase = ref.watch(updatePokedexSpeciesMetadataUseCaseProvider);
  return (workspace, request) => useCase.execute(workspace, request);
});

final updatePokedexSpeciesFormsClassificationUseCaseProvider =
    Provider<UpdatePokedexSpeciesFormsClassificationUseCase>((ref) {
  return UpdatePokedexSpeciesFormsClassificationUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexSpeciesFormsClassificationSaverProvider =
    Provider<PokedexSpeciesFormsClassificationSaver>((ref) {
  final useCase = ref.watch(
    updatePokedexSpeciesFormsClassificationUseCaseProvider,
  );
  return (workspace, request) => useCase.execute(workspace, request);
});

final updatePokedexSpeciesLearnsetUseCaseProvider =
    Provider<UpdatePokedexSpeciesLearnsetUseCase>((ref) {
  return UpdatePokedexSpeciesLearnsetUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexSpeciesLearnsetSaverProvider =
    Provider<PokedexSpeciesLearnsetSaver>((ref) {
  final useCase = ref.watch(updatePokedexSpeciesLearnsetUseCaseProvider);
  return (workspace, request) => useCase.execute(workspace, request);
});

final updatePokedexSpeciesEvolutionUseCaseProvider =
    Provider<UpdatePokedexSpeciesEvolutionUseCase>((ref) {
  return UpdatePokedexSpeciesEvolutionUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexSpeciesEvolutionSaverProvider =
    Provider<PokedexSpeciesEvolutionSaver>((ref) {
  final useCase = ref.watch(updatePokedexSpeciesEvolutionUseCaseProvider);
  return (workspace, request) => useCase.execute(workspace, request);
});

final updatePokedexSpeciesMediaUseCaseProvider =
    Provider<UpdatePokedexSpeciesMediaUseCase>((ref) {
  return UpdatePokedexSpeciesMediaUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexSpeciesMediaSaverProvider =
    Provider<PokedexSpeciesMediaSaver>((ref) {
  final useCase = ref.watch(updatePokedexSpeciesMediaUseCaseProvider);
  return (workspace, request) => useCase.execute(workspace, request);
});
```

### 13.4 `packages/map_editor/test/pokemon_external_query_resolver_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/models/pokemon_external_query_resolution.dart';
import 'package:map_editor/src/application/services/pokemon_external_query_resolver.dart';

void main() {
  const resolver = PokemonExternalQueryResolver();

  group('PokemonExternalQueryResolver', () {
    group('single species queries', () {
      test('resolves a lowercase species name', () {
        final result = resolver.resolve('bulbasaur');

        expect(result, isA<PokemonExternalSingleQueryResolution>());
        final single = result as PokemonExternalSingleQueryResolution;
        expect(single.kind, PokemonExternalQueryResolutionKind.singleQuery);
        expect(single.normalizedQuery, 'bulbasaur');
        expect(single.query.kind, PokemonExternalSingleQueryKind.species);
        expect(single.query.normalizedValue, 'bulbasaur');
      });

      test('normalizes case and surrounding spaces for a species query', () {
        final result = resolver.resolve('  Bulbasaur  ');

        expect(result, isA<PokemonExternalSingleQueryResolution>());
        final single = result as PokemonExternalSingleQueryResolution;
        expect(single.normalizedQuery, 'Bulbasaur');
        expect(single.query.normalizedValue, 'bulbasaur');
      });
    });

    group('single national dex queries', () {
      test('resolves a raw dex number', () {
        final result = resolver.resolve('1');

        expect(result, isA<PokemonExternalSingleQueryResolution>());
        final single = result as PokemonExternalSingleQueryResolution;
        expect(single.query.kind, PokemonExternalSingleQueryKind.nationalDex);
        expect(single.query.nationalDex, 1);
      });

      test('resolves a zero-padded dex number', () {
        final result = resolver.resolve('001');

        expect(result, isA<PokemonExternalSingleQueryResolution>());
        final single = result as PokemonExternalSingleQueryResolution;
        expect(single.query.kind, PokemonExternalSingleQueryKind.nationalDex);
        expect(single.query.nationalDex, 1);
      });

      test('resolves a four-digit zero-padded dex number', () {
        final result = resolver.resolve('0001');

        expect(result, isA<PokemonExternalSingleQueryResolution>());
        final single = result as PokemonExternalSingleQueryResolution;
        expect(single.query.kind, PokemonExternalSingleQueryKind.nationalDex);
        expect(single.query.nationalDex, 1);
      });
    });

    group('national dex ranges', () {
      test('resolves a compact dex range', () {
        final result = resolver.resolve('1-151');

        expect(result, isA<PokemonExternalNationalDexRangeQueryResolution>());
        final range = result as PokemonExternalNationalDexRangeQueryResolution;
        expect(range.kind, PokemonExternalQueryResolutionKind.nationalDexRange);
        expect(range.startNationalDex, 1);
        expect(range.endNationalDex, 151);
      });

      test('resolves a dex range with spaces around the hyphen', () {
        final result = resolver.resolve('1 - 151');

        expect(result, isA<PokemonExternalNationalDexRangeQueryResolution>());
        final range = result as PokemonExternalNationalDexRangeQueryResolution;
        expect(range.startNationalDex, 1);
        expect(range.endNationalDex, 151);
      });

      test('rejects a descending dex range', () {
        final result = resolver.resolve('151-1');

        expect(result, isA<PokemonExternalInvalidQueryResolution>());
        final invalid = result as PokemonExternalInvalidQueryResolution;
        expect(
          invalid.code,
          PokemonExternalInvalidQueryCode.invalidNationalDexRange,
        );
      });

      test('rejects an invalid dex range with a missing end', () {
        final result = resolver.resolve('1-');

        expect(result, isA<PokemonExternalInvalidQueryResolution>());
        final invalid = result as PokemonExternalInvalidQueryResolution;
        expect(
          invalid.code,
          PokemonExternalInvalidQueryCode.invalidNationalDexRange,
        );
      });
    });

    group('generation queries', () {
      test('resolves a lower-case generation query', () {
        final result = resolver.resolve('gen 1');

        expect(result, isA<PokemonExternalGenerationQueryResolution>());
        final generation = result as PokemonExternalGenerationQueryResolution;
        expect(generation.kind, PokemonExternalQueryResolutionKind.generation);
        expect(generation.generation, 1);
      });

      test('resolves a mixed-case generation query', () {
        final result = resolver.resolve('Gen 1');

        expect(result, isA<PokemonExternalGenerationQueryResolution>());
        final generation = result as PokemonExternalGenerationQueryResolution;
        expect(generation.generation, 1);
      });

      test('resolves a long-form generation query', () {
        final result = resolver.resolve('generation 1');

        expect(result, isA<PokemonExternalGenerationQueryResolution>());
        final generation = result as PokemonExternalGenerationQueryResolution;
        expect(generation.generation, 1);
      });

      test('rejects an invalid generation number', () {
        final result = resolver.resolve('gen 0');

        expect(result, isA<PokemonExternalInvalidQueryResolution>());
        final invalid = result as PokemonExternalInvalidQueryResolution;
        expect(
          invalid.code,
          PokemonExternalInvalidQueryCode.invalidGeneration,
        );
      });
    });

    group('explicit lists', () {
      test('resolves a compact explicit list', () {
        final result = resolver.resolve('pikachu,eevee,abra');

        expect(result, isA<PokemonExternalExplicitListQueryResolution>());
        final list = result as PokemonExternalExplicitListQueryResolution;
        expect(
          list.kind,
          PokemonExternalQueryResolutionKind.explicitList,
        );
        expect(list.queries.map((query) => query.normalizedValue).toList(),
            <String?>['pikachu', 'eevee', 'abra']);
      });

      test('resolves a spaced explicit list', () {
        final result = resolver.resolve('pikachu, eevee, abra');

        expect(result, isA<PokemonExternalExplicitListQueryResolution>());
        final list = result as PokemonExternalExplicitListQueryResolution;
        expect(list.queries.map((query) => query.normalizedValue).toList(),
            <String?>['pikachu', 'eevee', 'abra']);
      });

      test('deduplicates explicit list entries while preserving order', () {
        final result = resolver.resolve(
          'pikachu, eevee, pikachu, 025, 25, abra',
        );

        expect(result, isA<PokemonExternalExplicitListQueryResolution>());
        final list = result as PokemonExternalExplicitListQueryResolution;
        expect(list.queries.length, 4);
        expect(list.queries[0].normalizedValue, 'pikachu');
        expect(list.queries[1].normalizedValue, 'eevee');
        expect(list.queries[2].nationalDex, 25);
        expect(list.queries[3].normalizedValue, 'abra');
      });
    });

    group('ambiguous or invalid queries', () {
      test('rejects an empty query', () {
        final result = resolver.resolve('');

        expect(result, isA<PokemonExternalInvalidQueryResolution>());
        final invalid = result as PokemonExternalInvalidQueryResolution;
        expect(invalid.code, PokemonExternalInvalidQueryCode.emptyQuery);
      });

      test('rejects a query containing only spaces', () {
        final result = resolver.resolve('   ');

        expect(result, isA<PokemonExternalInvalidQueryResolution>());
        final invalid = result as PokemonExternalInvalidQueryResolution;
        expect(invalid.code, PokemonExternalInvalidQueryCode.emptyQuery);
      });

      test('rejects an ambiguous whitespace-separated list candidate', () {
        final result = resolver.resolve('pikachu eevee abra');

        expect(result, isA<PokemonExternalInvalidQueryResolution>());
        final invalid = result as PokemonExternalInvalidQueryResolution;
        expect(
          invalid.code,
          PokemonExternalInvalidQueryCode.ambiguousWhitespaceSeparatedTerms,
        );
      });

      test('rejects an explicit list with empty entries', () {
        final result = resolver.resolve('pikachu, , abra');

        expect(result, isA<PokemonExternalInvalidQueryResolution>());
        final invalid = result as PokemonExternalInvalidQueryResolution;
        expect(
          invalid.code,
          PokemonExternalInvalidQueryCode.invalidExplicitList,
        );
      });

      test('rejects an explicit list with inconsistent separators', () {
        final result = resolver.resolve('pikachu, eevee abra');

        expect(result, isA<PokemonExternalInvalidQueryResolution>());
        final invalid = result as PokemonExternalInvalidQueryResolution;
        expect(
          invalid.code,
          PokemonExternalInvalidQueryCode.invalidExplicitList,
        );
      });

      test('rejects a malformed generation query', () {
        final result = resolver.resolve('generation x');

        expect(result, isA<PokemonExternalInvalidQueryResolution>());
        final invalid = result as PokemonExternalInvalidQueryResolution;
        expect(
          invalid.code,
          PokemonExternalInvalidQueryCode.invalidGeneration,
        );
      });
    });
  });
}
```

### 13.5 `packages/map_editor/test/provider_wiring_test.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/content_studio_providers.dart';
import 'package:map_editor/src/app/providers/core_providers.dart';
import 'package:map_editor/src/app/providers/editor_workspace_providers.dart';
import 'package:map_editor/src/app/providers/pokedex_providers.dart';
import 'package:map_editor/src/app/providers/use_case_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_workspace_providers.dart';
import 'package:map_editor/src/features/narrative/state/narrative_workspace_state.dart';

void main() {
  group('provider wiring', () {
    test('resolves thematic controllers from a ProviderContainer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(projectRepositoryProvider), isNotNull);
      expect(container.read(terrainPresetResolverProvider), isNotNull);
      expect(container.read(createProjectDialogueUseCaseProvider), isNotNull);
      expect(container.read(pokemonDatabaseIndexProvider), isNotNull);
      expect(container.read(pokeApiLiveSourceProvider), isNotNull);
      expect(container.read(showdownSnapshotSourceProvider), isNotNull);
      expect(
          container.read(pokemonExternalSourceRepositoryProvider), isNotNull);
      expect(container.read(pokemonExternalQueryResolverProvider), isNotNull);
      expect(
        container.read(importExternalPokemonSpeciesUseCaseProvider),
        isNotNull,
      );
      expect(
        container.read(loadPokemonMovesCatalogUseCaseProvider),
        isNotNull,
      );
      expect(
        container.read(syncExternalPokemonMovesCatalogUseCaseProvider),
        isNotNull,
      );
      expect(container.read(pokedexMovesCatalogLoaderProvider), isNotNull);
      expect(container.read(pokedexMovesCatalogPreviewerProvider), isNotNull);
      expect(container.read(pokedexMovesCatalogSyncerProvider), isNotNull);
      expect(container.read(deletePokedexSpeciesUseCaseProvider), isNotNull);
      expect(container.read(pokedexSpeciesDeleterProvider), isNotNull);
      expect(container.read(pokedexExternalImportPreviewerProvider), isNotNull);
      expect(container.read(pokedexExternalImporterProvider), isNotNull);
      expect(container.read(editorWorkspaceControllerProvider), isNotNull);
      expect(container.read(projectContentControllerProvider), isNotNull);
    });

    test('derives selected narrative summaries from controller + projection',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          scenarios: <ScenarioAsset>[
            ScenarioAsset(
              id: 'global_intro',
              name: 'Global Intro',
              scope: ScenarioScope.globalStory,
              entryNodeId: 'start',
              metadata: <String, String>{
                'step.id': 'step.professor_intro',
                'step.name': 'Rencontrer le professeur',
              },
            ),
            ScenarioAsset(
              id: 'local_intro',
              name: 'Local Intro',
              scope: ScenarioScope.localEventFlow,
              entryNodeId: 'start',
              declaredOutcomes: <String>['story.started'],
            ),
          ],
        ),
      );

      final narrativeNotifier =
          container.read(narrativeWorkspaceControllerProvider.notifier);
      narrativeNotifier.openGlobalStory(scenarioId: 'global_intro');
      narrativeNotifier.openStep(
        stepId: 'step.professor_intro',
        globalScenarioId: 'global_intro',
      );
      narrativeNotifier.openCutscene(cutsceneScenarioId: 'local_intro');
      narrativeNotifier.selectOutcome('story.started');

      expect(
        container.read(selectedGlobalStorySummaryProvider)?.id,
        'global_intro',
      );
      expect(
        container.read(selectedCutsceneSummaryProvider)?.id,
        'local_intro',
      );
      expect(
        container.read(selectedNarrativeStepSummaryProvider)?.id,
        'step.professor_intro',
      );
      expect(
        container.read(selectedNarrativeOutcomeSummaryProvider)?.id,
        'story.started',
      );
    });
  });
}
```
