# M2-bis — Mini-fix canonique du modèle moves dans `map_core`

## 1. Résumé exécutif honnête

M2-bis a été livré strictement dans `packages/map_core`.

Ce mini-fix a réellement fait quatre choses :

- ajout de `setPseudoWeather` dans les effets structurés ;
- suppression de l'ambiguïté `basePower` / `dealDamage` en supprimant `dealDamage` et en assumant explicitement que le flow de dégâts standard est porté par les champs natifs du move ;
- ajout d'une normalisation / validation défensive minimale sur `PokemonMove`, `PokemonMoveAccuracy` et `PokemonMoveEffect` ;
- renforcement des tests sur les variants peu ou pas couverts.

Correction supplémentaire appliquée après relecture séparée :

- la normalisation n'est plus seulement opt-in ;
- `fromJson` applique désormais la normalisation sur `PokemonMove`, `PokemonMoveAccuracy` et `PokemonMoveEffect`.

Ce qui n'a pas été fait :

- aucun changement dans `map_editor` ;
- aucun changement dans `map_runtime` ;
- aucun changement dans `map_battle` ;
- aucun enrichissement du convertisseur Showdown ;
- aucun seed ;
- aucun bootstrap projet ;
- aucune logique moteur d'exécution.

## 2. Problèmes confirmés

Les problèmes suivants étaient réels dans l'état précédent du modèle M2 :

- `setPseudoWeather` manquait alors qu'il était explicitement présent dans la spec M1 ;
- `basePower` et `dealDamage` créaient une semi-duplication sémantique ;
- la validation défensive existait peu ou pas ;
- la couverture de tests sur plusieurs variants d'effets restait trop partielle ;
- après première passe M2-bis, la validation était réelle mais encore opt-in, ce qu'un reviewer séparé a correctement signalé.

## 3. Décisions retenues / rejetées

### Décisions retenues

- ajouter `PokemonMoveEffect.setPseudoWeather` ;
- supprimer `PokemonMoveEffect.dealDamage` ;
- faire de `basePower` + `category` le support canonique des dégâts standards ;
- ajouter un getter explicite `usesStandardDamageFlow` dans `PokemonMove` pour rendre cette décision lisible ;
- ajouter une validation/normalisation minimale locale ;
- durcir aussi l'entrée JSON en faisant passer `fromJson` par `normalized()`.

### Décisions rejetées

- ne pas garder `dealDamage` avec une sémantique floue ;
- ne pas introduire de callbacks sérialisés ;
- ne pas créer une nouvelle hiérarchie de fichiers ;
- ne pas ouvrir M3, M4, M5 ou M8 ;
- ne pas déplacer la validation dans un autre package ;
- ne pas toucher aux convertisseurs ou loaders existants.

## 4. Périmètre inclus / exclu

### Inclus

- `packages/map_core/lib/src/models/pokemon_move.dart`
- `packages/map_core/lib/src/models/pokemon_move_accuracy.dart`
- `packages/map_core/lib/src/models/pokemon_move_effect.dart`
- fichiers générés Freezed/JSON associés qui ont réellement changé
- `packages/map_core/test/pokemon_move_test.dart`
- report markdown de ce lot
- relecture par agent séparé

### Exclu

- tout `packages/map_editor/...`
- tout `packages/map_runtime/...`
- tout `packages/map_battle/...`
- seed projet
- bootstrap projet
- convertisseur Showdown
- runtime loader
- exécution moteur battle

## 5. Justification fichier par fichier

### `packages/map_core/lib/src/models/pokemon_move.dart`

Modifié pour :

- supprimer l'ambiguïté conceptuelle autour des dégâts standards ;
- exposer explicitement `usesStandardDamageFlow` ;
- ajouter `normalized()` ;
- faire passer `fromJson` par `normalized()` ;
- dédupliquer `flags` et `unsupportedReasons` ;
- valider les champs textuels requis.

### `packages/map_core/lib/src/models/pokemon_move_accuracy.dart`

Modifié pour :

- ajouter `normalized()` ;
- borner `percent` à une plage raisonnable ;
- faire passer `fromJson` par `normalized()`.

### `packages/map_core/lib/src/models/pokemon_move_effect.dart`

Modifié pour :

- ajouter `setPseudoWeather` ;
- supprimer `dealDamage` ;
- ajouter `normalized()` ;
- valider `chance`, `multiHit`, `fixedDamage`, fractions, ids requis, etc. ;
- faire passer `fromJson` par `normalized()`.

### `packages/map_core/lib/src/models/pokemon_move.freezed.dart`

Régénéré pour refléter les ajustements du modèle `PokemonMove`.

### `packages/map_core/lib/src/models/pokemon_move_effect.freezed.dart`

Régénéré pour refléter :

- la suppression de `dealDamage` ;
- l'ajout de `setPseudoWeather` ;
- les variantes effectivement présentes après M2-bis.

### `packages/map_core/lib/src/models/pokemon_move_effect.g.dart`

Régénéré pour la sérialisation JSON des variants mis à jour.

### `packages/map_core/test/pokemon_move_test.dart`

Modifié pour :

- retirer les usages de `dealDamage` ;
- couvrir les nouveaux variants demandés ;
- tester la normalisation/validation ;
- tester le durcissement de `fromJson`.

### `reports/phase-moves-m2-bis-model-hardening-report.md`

Nouveau report ultra complet pour tracer honnêtement le mini-fix, la review séparée et les corrections intégrées.

## 6. Commandes réellement exécutées

### Audit

`git status --short`
`git diff --stat`
`git ls-files --others --exclude-standard`
`sed -n '1,260p' 'packages/map_core/lib/src/models/pokemon_move.dart'`
`sed -n '1,320p' 'packages/map_core/lib/src/models/pokemon_move_effect.dart'`
`sed -n '1,220p' 'packages/map_core/lib/src/models/pokemon_move_accuracy.dart'`
`sed -n '1,260p' 'packages/map_core/test/pokemon_move_test.dart'`

### Génération

`/opt/homebrew/bin/dart run build_runner build --delete-conflicting-outputs`

### Format

`/opt/homebrew/bin/dart format lib/src/models/pokemon_move.dart lib/src/models/pokemon_move_accuracy.dart lib/src/models/pokemon_move_effect.dart test/pokemon_move_test.dart`

### Analyze

`/opt/homebrew/bin/dart analyze`

### Tests

`/opt/homebrew/bin/dart test test/pokemon_move_test.dart`
`/opt/homebrew/bin/dart test`

### Relecture séparée

Outils réellement utilisés :

- `spawn_agent`
- `wait_agent`
- `send_input`
- `wait_agent`

## 7. Résultats réels de format / analyze / tests

### Génération

Résultat : succès.

Sortie utile :

`Built with build_runner in 5s; wrote 9 outputs.`

Warnings non bloquants observés :

- version langage SDK plus récente que la version langage de `analyzer` ;
- warning `json_annotation` autorisant des versions avant 4.9.0.

### Format

Résultat : succès.

Sortie utile :

`Formatted 4 files (0 changed) in 0.01 seconds.`

### Analyze

Résultat : succès avec 2 infos préexistantes hors scope.

Sortie utile :

`Analyzing map_core...`

Puis :

- `lib/src/models/enums.dart:34:3 - upper_floor - constant_identifier_names`
- `lib/src/models/enums.dart:44:3 - sub_area - constant_identifier_names`

Aucune erreur ni warning sur le mini-fix M2-bis lui-même.

### Tests ciblés

Résultat : succès.

Sortie utile de fin :

`All tests passed!`

### Tests package complets

Résultat : succès.

Sortie utile de fin :

`All tests passed!`

## 8. Incidents rencontrés

- warning `build_runner` sur la version langage `analyzer` ;
- warning `json_annotation` non bloquant ;
- 2 infos de lint préexistantes dans `lib/src/models/enums.dart` ;
- reviewer séparé a signalé un vrai point faible initial : la validation était encore opt-in ; cette critique a été retenue puis corrigée dans ce lot.

Aucun incident bloquant.

## 9. État git utile

### `git status --short`

```text
 M packages/map_core/lib/src/models/pokemon_move.dart
 M packages/map_core/lib/src/models/pokemon_move.freezed.dart
 M packages/map_core/lib/src/models/pokemon_move_accuracy.dart
 M packages/map_core/lib/src/models/pokemon_move_effect.dart
 M packages/map_core/lib/src/models/pokemon_move_effect.freezed.dart
 M packages/map_core/lib/src/models/pokemon_move_effect.g.dart
 M packages/map_core/test/pokemon_move_test.dart
?? .DS_Store
?? reports/phase-moves-m2-bis-model-hardening-report.md
```

### `git diff --stat`

```text
 packages/map_core/lib/src/models/pokemon_move.dart |  118 +-
 .../lib/src/models/pokemon_move.freezed.dart       |   16 +-
 .../lib/src/models/pokemon_move_accuracy.dart      |   22 +-
 .../lib/src/models/pokemon_move_effect.dart        |  242 ++-
 .../src/models/pokemon_move_effect.freezed.dart    | 1669 +++++++++++---------
 .../lib/src/models/pokemon_move_effect.g.dart      |   57 +-
 packages/map_core/test/pokemon_move_test.dart      |  198 ++-
 7 files changed, 1483 insertions(+), 839 deletions(-)
```

Note honnête :

- `git diff --stat` n'affiche pas les fichiers non suivis ;
- le report lui-même et le fichier `.DS_Store` ne sont donc visibles que dans `git status --short`.

## 10. Checklist finale

- [x] je me suis basé sur le code réel, pas sur les reports précédents
- [x] je n'ai pas ouvert M3
- [x] je n'ai touché qu'à `map_core`
- [x] `setPseudoWeather` est bien ajouté
- [x] la question `basePower` / `dealDamage` est réellement tranchée
- [x] la normalisation/validation minimale est réelle
- [x] la normalisation n'est plus seulement opt-in sur le modèle canonique
- [x] les tests couvrent les variants demandés
- [x] j'ai exécuté génération
- [x] j'ai exécuté format
- [x] j'ai exécuté analyze
- [x] j'ai exécuté les tests utiles
- [x] aucune écriture git interdite n'a été faite
- [x] le report contient une autocritique du reviewer séparé
- [x] le report contient les corrections appliquées suite à cette autocritique
- [x] le report contient le contenu complet de tous les fichiers texte touchés

## 11. Autocritique du reviewer séparé

### Relecture initiale du reviewer

Le reviewer séparé a remonté les points suivants :

1. `setPseudoWeather` était bien ajouté correctement.
2. La question `basePower` / `dealDamage` était bien tranchée.
3. La normalisation/validation était réelle et non cosmétique.
4. Les variants demandés étaient bien couverts par les tests.
5. Le point faible principal restant était l'ingress `fromJson` : la normalisation restait opt-in.
6. Le scope était resté strictement borné à `map_core`.

### Revérification après correction

Le reviewer a ensuite confirmé :

1. le point `fromJson` était effectivement corrigé ;
2. aucun bug concret nouveau n'avait été introduit ;
3. le comportement devenait volontairement fail-fast sur JSON invalide ;
4. le scope restait borné ;
5. la couverture demandée était bien là.

## 12. Corrections appliquées suite à l’autocritique

Suite à la critique du reviewer, j'ai appliqué les corrections suivantes :

- `PokemonMove.fromJson(...)` appelle maintenant `normalized()` ;
- `PokemonMoveAccuracy.fromJson(...)` appelle maintenant `normalized()` ;
- `PokemonMoveEffect.fromJson(...)` appelle maintenant `normalized()` ;
- ajout de tests dédiés pour prouver que `fromJson` rejette désormais :
  - un `id` vide ;
  - une accuracy `percent` hors bornes ;
  - un `multiHit` invalide.

Conséquence assumée :

- le modèle échoue désormais plus tôt sur des données invalides ;
- c'est un changement volontairement plus strict et jugé correct pour M2-bis.

## 13. Limites restantes

Les limites restantes, volontairement hors scope, sont :

- le convertisseur Showdown n'utilise pas encore ce modèle enrichi ;
- le seed projet n'est pas encore branché ;
- le runtime ne charge pas encore ce modèle ;
- `map_battle` ne consomme pas encore ces structures ;
- le support moteur reste descriptif, pas exécutable ;
- la validation n'est toujours pas un validateur projet global : elle est locale au modèle.

## 14. Conclusion honnête

M2-bis est fermé proprement.

Le modèle canonique des moves dans `map_core` est maintenant plus cohérent avec M1, plus strict, mieux couvert, et moins ambigu. Le mini-fix est resté strictement borné à `map_core`, a intégré une vraie autocritique séparée, et n'a rouvert aucun lot voisin.

## 15. Annexe — contenu complet de tous les fichiers texte touchés

Note :

- cette annexe inclut le contenu complet de tous les fichiers texte modifiés
  par M2-bis ;
- le report s'exclut lui-même volontairement pour éviter une récursion
  infinie.

### `packages/map_core/lib/src/models/pokemon_move.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'pokemon_move_accuracy.dart';
import 'pokemon_move_effect.dart';

part 'pokemon_move.freezed.dart';
part 'pokemon_move.g.dart';

/// Catégorie de move utilisée par la donnée projet.
///
/// On garde ici une projection petite et stable :
/// - directement sérialisable ;
/// - alignée avec la distinction battle la plus fondamentale ;
/// - indépendante de la future implémentation du moteur.
enum PokemonMoveCategory {
  @JsonValue('physical')
  physical,
  @JsonValue('special')
  special,
  @JsonValue('status')
  status,
}

/// Target canonique du move projet.
///
/// On reprend le vocabulaire structurel de Showdown parce qu'il est déjà
/// présent dans les données source et qu'il sera relu plus tard par le
/// convertisseur/runtime loader. Cela évite d'inventer une deuxième taxonomie.
enum PokemonMoveTarget {
  @JsonValue('adjacentAlly')
  adjacentAlly,
  @JsonValue('adjacentAllyOrSelf')
  adjacentAllyOrSelf,
  @JsonValue('adjacentFoe')
  adjacentFoe,
  @JsonValue('all')
  all,
  @JsonValue('allAdjacent')
  allAdjacent,
  @JsonValue('allAdjacentFoes')
  allAdjacentFoes,
  @JsonValue('allies')
  allies,
  @JsonValue('allySide')
  allySide,
  @JsonValue('allyTeam')
  allyTeam,
  @JsonValue('any')
  any,
  @JsonValue('foeSide')
  foeSide,
  @JsonValue('normal')
  normal,
  @JsonValue('randomNormal')
  randomNormal,
  @JsonValue('scripted')
  scripted,
  @JsonValue('self')
  self,
}

/// Flag métier de move.
///
/// Le modèle n'éparpille pas ces marqueurs en dizaines de booléens sur
/// `PokemonMove`. On les garde comme une collection d'identifiants typés,
/// ce qui donne une sérialisation propre et une extension future simple.
enum PokemonMoveFlag {
  @JsonValue('allyanim')
  allyAnim,
  @JsonValue('bypasssub')
  bypassSubstitute,
  @JsonValue('bite')
  bite,
  @JsonValue('bullet')
  bullet,
  @JsonValue('cantusetwice')
  cantUseTwice,
  @JsonValue('charge')
  charge,
  @JsonValue('contact')
  contact,
  @JsonValue('dance')
  dance,
  @JsonValue('defrost')
  defrost,
  @JsonValue('distance')
  distance,
  @JsonValue('failcopycat')
  failCopycat,
  @JsonValue('failencore')
  failEncore,
  @JsonValue('failinstruct')
  failInstruct,
  @JsonValue('failmefirst')
  failMeFirst,
  @JsonValue('failmimic')
  failMimic,
  @JsonValue('futuremove')
  futureMove,
  @JsonValue('gravity')
  gravity,
  @JsonValue('heal')
  heal,
  @JsonValue('metronome')
  metronome,
  @JsonValue('minimize')
  minimize,
  @JsonValue('mirror')
  mirror,
  @JsonValue('mustpressure')
  mustPressure,
  @JsonValue('noassist')
  noAssist,
  @JsonValue('nonsky')
  nonSky,
  @JsonValue('noparentalbond')
  noParentalBond,
  @JsonValue('nosketch')
  noSketch,
  @JsonValue('nosleeptalk')
  noSleepTalk,
  @JsonValue('pledgecombo')
  pledgeCombo,
  @JsonValue('powder')
  powder,
  @JsonValue('protect')
  protect,
  @JsonValue('pulse')
  pulse,
  @JsonValue('punch')
  punch,
  @JsonValue('recharge')
  recharge,
  @JsonValue('reflectable')
  reflectable,
  @JsonValue('slicing')
  slicing,
  @JsonValue('snatch')
  snatch,
  @JsonValue('sound')
  sound,
  @JsonValue('wind')
  wind,
}

/// Niveau de support structurel connu pour le moteur.
///
/// Ce champ sert à être honnête :
/// - un move peut être catalogué sans être prêt pour le moteur ;
/// - un move peut être partiellement structuré ;
/// - un move peut être entièrement structuré du point de vue du modèle,
///   sans pour autant signifier que tout est déjà branché côté `map_battle`.
enum PokemonMoveEngineSupportLevel {
  @JsonValue('catalog_only')
  catalogOnly,
  @JsonValue('structured_partial')
  structuredPartial,
  @JsonValue('structured_supported')
  structuredSupported,
}

/// Traçabilité minimale vers la source Showdown.
///
/// On garde cette structure locale au modèle de données :
/// - elle ne transporte pas de callbacks ;
/// - elle documente uniquement l'origine et les hooks détectés ;
/// - elle aidera plus tard le convertisseur enrichi, la validation et le debug.
@freezed
class PokemonMoveSourceRefs with _$PokemonMoveSourceRefs {
  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveSourceRefs({
    String? showdownMoveId,
    @Default(<String>[]) List<String> showdownHooksPresent,
  }) = _PokemonMoveSourceRefs;

  factory PokemonMoveSourceRefs.fromJson(Map<String, dynamic> json) =>
      _$PokemonMoveSourceRefsFromJson(json);

  const PokemonMoveSourceRefs._();

  PokemonMoveSourceRefs normalized() {
    final normalizedShowdownMoveId = showdownMoveId?.trim();
    final normalizedHooks = <String>[];
    final seen = <String>{};
    for (final hook in showdownHooksPresent) {
      final trimmed = hook.trim();
      if (trimmed.isEmpty || !seen.add(trimmed)) {
        continue;
      }
      normalizedHooks.add(trimmed);
    }
    return copyWith(
      showdownMoveId:
          normalizedShowdownMoveId == null || normalizedShowdownMoveId.isEmpty
              ? null
              : normalizedShowdownMoveId,
      showdownHooksPresent: normalizedHooks,
    );
  }
}

/// Modèle canonique spécialisé d'un move Pokémon.
///
/// Invariants de M2 :
/// - c'est la structure de vérité sérialisable côté `map_core` ;
/// - elle sert plus tard à l'éditeur, au runtime et au pont battle ;
/// - elle ne contient ni code Showdown ni logique d'exécution ;
/// - les comportements de résolution sont décrits dans `effects`.
@freezed
class PokemonMove with _$PokemonMove {
  const PokemonMove._();

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMove({
    required String id,
    required String name,
    @Default(<String, String>{}) Map<String, String> names,
    int? generation,

    /// `showdown`, `seed`, `project_custom`, etc.
    @Default('') String source,
    required String type,
    required PokemonMoveCategory category,
    @Default(PokemonMoveTarget.normal) PokemonMoveTarget target,
    @Default(0) int basePower,
    required PokemonMoveAccuracy accuracy,
    @Default(0) int pp,
    @Default(false) bool noPpBoosts,
    @Default(0) int priority,
    @Default(1) int critRatio,

    /// Sémantiquement un ensemble, stocké comme liste sérialisable stable.
    @Default(<PokemonMoveFlag>[]) List<PokemonMoveFlag> flags,

    /// Tous les comportements applicatifs vivent ici.
    @Default(<PokemonMoveEffect>[]) List<PokemonMoveEffect> effects,
    @Default('') String shortDescription,
    @Default('') String description,
    @Default(PokemonMoveEngineSupportLevel.catalogOnly)
    PokemonMoveEngineSupportLevel engineSupportLevel,
    @Default(<String>[]) List<String> unsupportedReasons,
    @Default(PokemonMoveSourceRefs()) PokemonMoveSourceRefs sourceRefs,
  }) = _PokemonMove;

  factory PokemonMove.fromJson(Map<String, dynamic> json) =>
      _$PokemonMoveFromJson(json).normalized();

  /// Sémantique tranchée de M2-bis :
  ///
  /// - `basePower` reste le marqueur canonique des dégâts standards ;
  /// - il n'y a plus d'effet `dealDamage` séparé ;
  /// - un move suit le flow de dégâts standard quand il n'est pas `status`
  ///   et qu'il a une `basePower` strictement positive.
  ///
  /// Cette décision retire l'ambiguïté du doublon `basePower` + `dealDamage`
  /// tout en gardant une lecture simple pour les futurs convertisseurs.
  bool get usesStandardDamageFlow =>
      category != PokemonMoveCategory.status && basePower > 0;

  /// Normalisation et validation défensive minimale.
  ///
  /// Le but n'est pas d'ouvrir un gros chantier de validation, mais de
  /// protéger le modèle contre les cas absurdes les plus évidents avant M3 :
  /// - ids et noms vides ;
  /// - type vide ;
  /// - accuracy incohérente ;
  /// - doublons dans `flags` et `unsupportedReasons` ;
  /// - effets incohérents localement.
  PokemonMove normalized() {
    String normalizeRequiredString(String label, String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        throw StateError('$label must not be empty');
      }
      return trimmed;
    }

    List<T> dedupePreserveOrder<T>(List<T> values) {
      final normalized = <T>[];
      final seen = <T>{};
      for (final value in values) {
        if (!seen.add(value)) {
          continue;
        }
        normalized.add(value);
      }
      return List.unmodifiable(normalized);
    }

    List<String> normalizeStringList(List<String> values) {
      final normalized = <String>[];
      final seen = <String>{};
      for (final value in values) {
        final trimmed = value.trim();
        if (trimmed.isEmpty || !seen.add(trimmed)) {
          continue;
        }
        normalized.add(trimmed);
      }
      return List.unmodifiable(normalized);
    }

    Map<String, String> normalizeNames(Map<String, String> values) {
      final entries = values.entries
          .map((entry) => MapEntry(entry.key.trim(), entry.value.trim()))
          .where((entry) => entry.key.isNotEmpty && entry.value.isNotEmpty)
          .toList(growable: false)
        ..sort((left, right) => left.key.compareTo(right.key));
      return Map<String, String>.fromEntries(entries);
    }

    final normalizedBasePower = basePower;
    if (normalizedBasePower < 0) {
      throw StateError('PokemonMove basePower must be non-negative');
    }
    if (pp < 0) {
      throw StateError('PokemonMove pp must be non-negative');
    }
    if (critRatio <= 0) {
      throw StateError('PokemonMove critRatio must be strictly positive');
    }

    return copyWith(
      id: normalizeRequiredString('PokemonMove id', id),
      name: normalizeRequiredString('PokemonMove name', name),
      names: normalizeNames(names),
      source: source.trim(),
      type: normalizeRequiredString('PokemonMove type', type),
      accuracy: accuracy.normalized(),
      flags: dedupePreserveOrder(flags),
      effects:
          effects.map((effect) => effect.normalized()).toList(growable: false),
      shortDescription: shortDescription.trim(),
      description: description.trim(),
      unsupportedReasons: normalizeStringList(unsupportedReasons),
      sourceRefs: sourceRefs.normalized(),
    );
  }
}

```

### `packages/map_core/lib/src/models/pokemon_move.freezed.dart`

```dart
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pokemon_move.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PokemonMoveSourceRefs _$PokemonMoveSourceRefsFromJson(
    Map<String, dynamic> json) {
  return _PokemonMoveSourceRefs.fromJson(json);
}

/// @nodoc
mixin _$PokemonMoveSourceRefs {
  String? get showdownMoveId => throw _privateConstructorUsedError;
  List<String> get showdownHooksPresent => throw _privateConstructorUsedError;

  /// Serializes this PokemonMoveSourceRefs to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PokemonMoveSourceRefs
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PokemonMoveSourceRefsCopyWith<PokemonMoveSourceRefs> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PokemonMoveSourceRefsCopyWith<$Res> {
  factory $PokemonMoveSourceRefsCopyWith(PokemonMoveSourceRefs value,
          $Res Function(PokemonMoveSourceRefs) then) =
      _$PokemonMoveSourceRefsCopyWithImpl<$Res, PokemonMoveSourceRefs>;
  @useResult
  $Res call({String? showdownMoveId, List<String> showdownHooksPresent});
}

/// @nodoc
class _$PokemonMoveSourceRefsCopyWithImpl<$Res,
        $Val extends PokemonMoveSourceRefs>
    implements $PokemonMoveSourceRefsCopyWith<$Res> {
  _$PokemonMoveSourceRefsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PokemonMoveSourceRefs
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? showdownMoveId = freezed,
    Object? showdownHooksPresent = null,
  }) {
    return _then(_value.copyWith(
      showdownMoveId: freezed == showdownMoveId
          ? _value.showdownMoveId
          : showdownMoveId // ignore: cast_nullable_to_non_nullable
              as String?,
      showdownHooksPresent: null == showdownHooksPresent
          ? _value.showdownHooksPresent
          : showdownHooksPresent // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PokemonMoveSourceRefsImplCopyWith<$Res>
    implements $PokemonMoveSourceRefsCopyWith<$Res> {
  factory _$$PokemonMoveSourceRefsImplCopyWith(
          _$PokemonMoveSourceRefsImpl value,
          $Res Function(_$PokemonMoveSourceRefsImpl) then) =
      __$$PokemonMoveSourceRefsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? showdownMoveId, List<String> showdownHooksPresent});
}

/// @nodoc
class __$$PokemonMoveSourceRefsImplCopyWithImpl<$Res>
    extends _$PokemonMoveSourceRefsCopyWithImpl<$Res,
        _$PokemonMoveSourceRefsImpl>
    implements _$$PokemonMoveSourceRefsImplCopyWith<$Res> {
  __$$PokemonMoveSourceRefsImplCopyWithImpl(_$PokemonMoveSourceRefsImpl _value,
      $Res Function(_$PokemonMoveSourceRefsImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveSourceRefs
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? showdownMoveId = freezed,
    Object? showdownHooksPresent = null,
  }) {
    return _then(_$PokemonMoveSourceRefsImpl(
      showdownMoveId: freezed == showdownMoveId
          ? _value.showdownMoveId
          : showdownMoveId // ignore: cast_nullable_to_non_nullable
              as String?,
      showdownHooksPresent: null == showdownHooksPresent
          ? _value._showdownHooksPresent
          : showdownHooksPresent // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveSourceRefsImpl extends _PokemonMoveSourceRefs {
  const _$PokemonMoveSourceRefsImpl(
      {this.showdownMoveId,
      final List<String> showdownHooksPresent = const <String>[]})
      : _showdownHooksPresent = showdownHooksPresent,
        super._();

  factory _$PokemonMoveSourceRefsImpl.fromJson(Map<String, dynamic> json) =>
      _$$PokemonMoveSourceRefsImplFromJson(json);

  @override
  final String? showdownMoveId;
  final List<String> _showdownHooksPresent;
  @override
  @JsonKey()
  List<String> get showdownHooksPresent {
    if (_showdownHooksPresent is EqualUnmodifiableListView)
      return _showdownHooksPresent;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_showdownHooksPresent);
  }

  @override
  String toString() {
    return 'PokemonMoveSourceRefs(showdownMoveId: $showdownMoveId, showdownHooksPresent: $showdownHooksPresent)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveSourceRefsImpl &&
            (identical(other.showdownMoveId, showdownMoveId) ||
                other.showdownMoveId == showdownMoveId) &&
            const DeepCollectionEquality()
                .equals(other._showdownHooksPresent, _showdownHooksPresent));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, showdownMoveId,
      const DeepCollectionEquality().hash(_showdownHooksPresent));

  /// Create a copy of PokemonMoveSourceRefs
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveSourceRefsImplCopyWith<_$PokemonMoveSourceRefsImpl>
      get copyWith => __$$PokemonMoveSourceRefsImplCopyWithImpl<
          _$PokemonMoveSourceRefsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveSourceRefsImplToJson(
      this,
    );
  }
}

abstract class _PokemonMoveSourceRefs extends PokemonMoveSourceRefs {
  const factory _PokemonMoveSourceRefs(
      {final String? showdownMoveId,
      final List<String> showdownHooksPresent}) = _$PokemonMoveSourceRefsImpl;
  const _PokemonMoveSourceRefs._() : super._();

  factory _PokemonMoveSourceRefs.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveSourceRefsImpl.fromJson;

  @override
  String? get showdownMoveId;
  @override
  List<String> get showdownHooksPresent;

  /// Create a copy of PokemonMoveSourceRefs
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveSourceRefsImplCopyWith<_$PokemonMoveSourceRefsImpl>
      get copyWith => throw _privateConstructorUsedError;
}

PokemonMove _$PokemonMoveFromJson(Map<String, dynamic> json) {
  return _PokemonMove.fromJson(json);
}

/// @nodoc
mixin _$PokemonMove {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  Map<String, String> get names => throw _privateConstructorUsedError;
  int? get generation => throw _privateConstructorUsedError;

  /// `showdown`, `seed`, `project_custom`, etc.
  String get source => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  PokemonMoveCategory get category => throw _privateConstructorUsedError;
  PokemonMoveTarget get target => throw _privateConstructorUsedError;
  int get basePower => throw _privateConstructorUsedError;
  PokemonMoveAccuracy get accuracy => throw _privateConstructorUsedError;
  int get pp => throw _privateConstructorUsedError;
  bool get noPpBoosts => throw _privateConstructorUsedError;
  int get priority => throw _privateConstructorUsedError;
  int get critRatio => throw _privateConstructorUsedError;

  /// Sémantiquement un ensemble, stocké comme liste sérialisable stable.
  List<PokemonMoveFlag> get flags => throw _privateConstructorUsedError;

  /// Tous les comportements applicatifs vivent ici.
  List<PokemonMoveEffect> get effects => throw _privateConstructorUsedError;
  String get shortDescription => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  PokemonMoveEngineSupportLevel get engineSupportLevel =>
      throw _privateConstructorUsedError;
  List<String> get unsupportedReasons => throw _privateConstructorUsedError;
  PokemonMoveSourceRefs get sourceRefs => throw _privateConstructorUsedError;

  /// Serializes this PokemonMove to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PokemonMove
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PokemonMoveCopyWith<PokemonMove> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PokemonMoveCopyWith<$Res> {
  factory $PokemonMoveCopyWith(
          PokemonMove value, $Res Function(PokemonMove) then) =
      _$PokemonMoveCopyWithImpl<$Res, PokemonMove>;
  @useResult
  $Res call(
      {String id,
      String name,
      Map<String, String> names,
      int? generation,
      String source,
      String type,
      PokemonMoveCategory category,
      PokemonMoveTarget target,
      int basePower,
      PokemonMoveAccuracy accuracy,
      int pp,
      bool noPpBoosts,
      int priority,
      int critRatio,
      List<PokemonMoveFlag> flags,
      List<PokemonMoveEffect> effects,
      String shortDescription,
      String description,
      PokemonMoveEngineSupportLevel engineSupportLevel,
      List<String> unsupportedReasons,
      PokemonMoveSourceRefs sourceRefs});

  $PokemonMoveAccuracyCopyWith<$Res> get accuracy;
  $PokemonMoveSourceRefsCopyWith<$Res> get sourceRefs;
}

/// @nodoc
class _$PokemonMoveCopyWithImpl<$Res, $Val extends PokemonMove>
    implements $PokemonMoveCopyWith<$Res> {
  _$PokemonMoveCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PokemonMove
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? names = null,
    Object? generation = freezed,
    Object? source = null,
    Object? type = null,
    Object? category = null,
    Object? target = null,
    Object? basePower = null,
    Object? accuracy = null,
    Object? pp = null,
    Object? noPpBoosts = null,
    Object? priority = null,
    Object? critRatio = null,
    Object? flags = null,
    Object? effects = null,
    Object? shortDescription = null,
    Object? description = null,
    Object? engineSupportLevel = null,
    Object? unsupportedReasons = null,
    Object? sourceRefs = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      names: null == names
          ? _value.names
          : names // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      generation: freezed == generation
          ? _value.generation
          : generation // ignore: cast_nullable_to_non_nullable
              as int?,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as PokemonMoveCategory,
      target: null == target
          ? _value.target
          : target // ignore: cast_nullable_to_non_nullable
              as PokemonMoveTarget,
      basePower: null == basePower
          ? _value.basePower
          : basePower // ignore: cast_nullable_to_non_nullable
              as int,
      accuracy: null == accuracy
          ? _value.accuracy
          : accuracy // ignore: cast_nullable_to_non_nullable
              as PokemonMoveAccuracy,
      pp: null == pp
          ? _value.pp
          : pp // ignore: cast_nullable_to_non_nullable
              as int,
      noPpBoosts: null == noPpBoosts
          ? _value.noPpBoosts
          : noPpBoosts // ignore: cast_nullable_to_non_nullable
              as bool,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
      critRatio: null == critRatio
          ? _value.critRatio
          : critRatio // ignore: cast_nullable_to_non_nullable
              as int,
      flags: null == flags
          ? _value.flags
          : flags // ignore: cast_nullable_to_non_nullable
              as List<PokemonMoveFlag>,
      effects: null == effects
          ? _value.effects
          : effects // ignore: cast_nullable_to_non_nullable
              as List<PokemonMoveEffect>,
      shortDescription: null == shortDescription
          ? _value.shortDescription
          : shortDescription // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      engineSupportLevel: null == engineSupportLevel
          ? _value.engineSupportLevel
          : engineSupportLevel // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEngineSupportLevel,
      unsupportedReasons: null == unsupportedReasons
          ? _value.unsupportedReasons
          : unsupportedReasons // ignore: cast_nullable_to_non_nullable
              as List<String>,
      sourceRefs: null == sourceRefs
          ? _value.sourceRefs
          : sourceRefs // ignore: cast_nullable_to_non_nullable
              as PokemonMoveSourceRefs,
    ) as $Val);
  }

  /// Create a copy of PokemonMove
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PokemonMoveAccuracyCopyWith<$Res> get accuracy {
    return $PokemonMoveAccuracyCopyWith<$Res>(_value.accuracy, (value) {
      return _then(_value.copyWith(accuracy: value) as $Val);
    });
  }

  /// Create a copy of PokemonMove
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PokemonMoveSourceRefsCopyWith<$Res> get sourceRefs {
    return $PokemonMoveSourceRefsCopyWith<$Res>(_value.sourceRefs, (value) {
      return _then(_value.copyWith(sourceRefs: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PokemonMoveImplCopyWith<$Res>
    implements $PokemonMoveCopyWith<$Res> {
  factory _$$PokemonMoveImplCopyWith(
          _$PokemonMoveImpl value, $Res Function(_$PokemonMoveImpl) then) =
      __$$PokemonMoveImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      Map<String, String> names,
      int? generation,
      String source,
      String type,
      PokemonMoveCategory category,
      PokemonMoveTarget target,
      int basePower,
      PokemonMoveAccuracy accuracy,
      int pp,
      bool noPpBoosts,
      int priority,
      int critRatio,
      List<PokemonMoveFlag> flags,
      List<PokemonMoveEffect> effects,
      String shortDescription,
      String description,
      PokemonMoveEngineSupportLevel engineSupportLevel,
      List<String> unsupportedReasons,
      PokemonMoveSourceRefs sourceRefs});

  @override
  $PokemonMoveAccuracyCopyWith<$Res> get accuracy;
  @override
  $PokemonMoveSourceRefsCopyWith<$Res> get sourceRefs;
}

/// @nodoc
class __$$PokemonMoveImplCopyWithImpl<$Res>
    extends _$PokemonMoveCopyWithImpl<$Res, _$PokemonMoveImpl>
    implements _$$PokemonMoveImplCopyWith<$Res> {
  __$$PokemonMoveImplCopyWithImpl(
      _$PokemonMoveImpl _value, $Res Function(_$PokemonMoveImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMove
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? names = null,
    Object? generation = freezed,
    Object? source = null,
    Object? type = null,
    Object? category = null,
    Object? target = null,
    Object? basePower = null,
    Object? accuracy = null,
    Object? pp = null,
    Object? noPpBoosts = null,
    Object? priority = null,
    Object? critRatio = null,
    Object? flags = null,
    Object? effects = null,
    Object? shortDescription = null,
    Object? description = null,
    Object? engineSupportLevel = null,
    Object? unsupportedReasons = null,
    Object? sourceRefs = null,
  }) {
    return _then(_$PokemonMoveImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      names: null == names
          ? _value._names
          : names // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      generation: freezed == generation
          ? _value.generation
          : generation // ignore: cast_nullable_to_non_nullable
              as int?,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as PokemonMoveCategory,
      target: null == target
          ? _value.target
          : target // ignore: cast_nullable_to_non_nullable
              as PokemonMoveTarget,
      basePower: null == basePower
          ? _value.basePower
          : basePower // ignore: cast_nullable_to_non_nullable
              as int,
      accuracy: null == accuracy
          ? _value.accuracy
          : accuracy // ignore: cast_nullable_to_non_nullable
              as PokemonMoveAccuracy,
      pp: null == pp
          ? _value.pp
          : pp // ignore: cast_nullable_to_non_nullable
              as int,
      noPpBoosts: null == noPpBoosts
          ? _value.noPpBoosts
          : noPpBoosts // ignore: cast_nullable_to_non_nullable
              as bool,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
      critRatio: null == critRatio
          ? _value.critRatio
          : critRatio // ignore: cast_nullable_to_non_nullable
              as int,
      flags: null == flags
          ? _value._flags
          : flags // ignore: cast_nullable_to_non_nullable
              as List<PokemonMoveFlag>,
      effects: null == effects
          ? _value._effects
          : effects // ignore: cast_nullable_to_non_nullable
              as List<PokemonMoveEffect>,
      shortDescription: null == shortDescription
          ? _value.shortDescription
          : shortDescription // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      engineSupportLevel: null == engineSupportLevel
          ? _value.engineSupportLevel
          : engineSupportLevel // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEngineSupportLevel,
      unsupportedReasons: null == unsupportedReasons
          ? _value._unsupportedReasons
          : unsupportedReasons // ignore: cast_nullable_to_non_nullable
              as List<String>,
      sourceRefs: null == sourceRefs
          ? _value.sourceRefs
          : sourceRefs // ignore: cast_nullable_to_non_nullable
              as PokemonMoveSourceRefs,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveImpl extends _PokemonMove {
  const _$PokemonMoveImpl(
      {required this.id,
      required this.name,
      final Map<String, String> names = const <String, String>{},
      this.generation,
      this.source = '',
      required this.type,
      required this.category,
      this.target = PokemonMoveTarget.normal,
      this.basePower = 0,
      required this.accuracy,
      this.pp = 0,
      this.noPpBoosts = false,
      this.priority = 0,
      this.critRatio = 1,
      final List<PokemonMoveFlag> flags = const <PokemonMoveFlag>[],
      final List<PokemonMoveEffect> effects = const <PokemonMoveEffect>[],
      this.shortDescription = '',
      this.description = '',
      this.engineSupportLevel = PokemonMoveEngineSupportLevel.catalogOnly,
      final List<String> unsupportedReasons = const <String>[],
      this.sourceRefs = const PokemonMoveSourceRefs()})
      : _names = names,
        _flags = flags,
        _effects = effects,
        _unsupportedReasons = unsupportedReasons,
        super._();

  factory _$PokemonMoveImpl.fromJson(Map<String, dynamic> json) =>
      _$$PokemonMoveImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  final Map<String, String> _names;
  @override
  @JsonKey()
  Map<String, String> get names {
    if (_names is EqualUnmodifiableMapView) return _names;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_names);
  }

  @override
  final int? generation;

  /// `showdown`, `seed`, `project_custom`, etc.
  @override
  @JsonKey()
  final String source;
  @override
  final String type;
  @override
  final PokemonMoveCategory category;
  @override
  @JsonKey()
  final PokemonMoveTarget target;
  @override
  @JsonKey()
  final int basePower;
  @override
  final PokemonMoveAccuracy accuracy;
  @override
  @JsonKey()
  final int pp;
  @override
  @JsonKey()
  final bool noPpBoosts;
  @override
  @JsonKey()
  final int priority;
  @override
  @JsonKey()
  final int critRatio;

  /// Sémantiquement un ensemble, stocké comme liste sérialisable stable.
  final List<PokemonMoveFlag> _flags;

  /// Sémantiquement un ensemble, stocké comme liste sérialisable stable.
  @override
  @JsonKey()
  List<PokemonMoveFlag> get flags {
    if (_flags is EqualUnmodifiableListView) return _flags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_flags);
  }

  /// Tous les comportements applicatifs vivent ici.
  final List<PokemonMoveEffect> _effects;

  /// Tous les comportements applicatifs vivent ici.
  @override
  @JsonKey()
  List<PokemonMoveEffect> get effects {
    if (_effects is EqualUnmodifiableListView) return _effects;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_effects);
  }

  @override
  @JsonKey()
  final String shortDescription;
  @override
  @JsonKey()
  final String description;
  @override
  @JsonKey()
  final PokemonMoveEngineSupportLevel engineSupportLevel;
  final List<String> _unsupportedReasons;
  @override
  @JsonKey()
  List<String> get unsupportedReasons {
    if (_unsupportedReasons is EqualUnmodifiableListView)
      return _unsupportedReasons;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_unsupportedReasons);
  }

  @override
  @JsonKey()
  final PokemonMoveSourceRefs sourceRefs;

  @override
  String toString() {
    return 'PokemonMove(id: $id, name: $name, names: $names, generation: $generation, source: $source, type: $type, category: $category, target: $target, basePower: $basePower, accuracy: $accuracy, pp: $pp, noPpBoosts: $noPpBoosts, priority: $priority, critRatio: $critRatio, flags: $flags, effects: $effects, shortDescription: $shortDescription, description: $description, engineSupportLevel: $engineSupportLevel, unsupportedReasons: $unsupportedReasons, sourceRefs: $sourceRefs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._names, _names) &&
            (identical(other.generation, generation) ||
                other.generation == generation) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.target, target) || other.target == target) &&
            (identical(other.basePower, basePower) ||
                other.basePower == basePower) &&
            (identical(other.accuracy, accuracy) ||
                other.accuracy == accuracy) &&
            (identical(other.pp, pp) || other.pp == pp) &&
            (identical(other.noPpBoosts, noPpBoosts) ||
                other.noPpBoosts == noPpBoosts) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.critRatio, critRatio) ||
                other.critRatio == critRatio) &&
            const DeepCollectionEquality().equals(other._flags, _flags) &&
            const DeepCollectionEquality().equals(other._effects, _effects) &&
            (identical(other.shortDescription, shortDescription) ||
                other.shortDescription == shortDescription) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.engineSupportLevel, engineSupportLevel) ||
                other.engineSupportLevel == engineSupportLevel) &&
            const DeepCollectionEquality()
                .equals(other._unsupportedReasons, _unsupportedReasons) &&
            (identical(other.sourceRefs, sourceRefs) ||
                other.sourceRefs == sourceRefs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        name,
        const DeepCollectionEquality().hash(_names),
        generation,
        source,
        type,
        category,
        target,
        basePower,
        accuracy,
        pp,
        noPpBoosts,
        priority,
        critRatio,
        const DeepCollectionEquality().hash(_flags),
        const DeepCollectionEquality().hash(_effects),
        shortDescription,
        description,
        engineSupportLevel,
        const DeepCollectionEquality().hash(_unsupportedReasons),
        sourceRefs
      ]);

  /// Create a copy of PokemonMove
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveImplCopyWith<_$PokemonMoveImpl> get copyWith =>
      __$$PokemonMoveImplCopyWithImpl<_$PokemonMoveImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveImplToJson(
      this,
    );
  }
}

abstract class _PokemonMove extends PokemonMove {
  const factory _PokemonMove(
      {required final String id,
      required final String name,
      final Map<String, String> names,
      final int? generation,
      final String source,
      required final String type,
      required final PokemonMoveCategory category,
      final PokemonMoveTarget target,
      final int basePower,
      required final PokemonMoveAccuracy accuracy,
      final int pp,
      final bool noPpBoosts,
      final int priority,
      final int critRatio,
      final List<PokemonMoveFlag> flags,
      final List<PokemonMoveEffect> effects,
      final String shortDescription,
      final String description,
      final PokemonMoveEngineSupportLevel engineSupportLevel,
      final List<String> unsupportedReasons,
      final PokemonMoveSourceRefs sourceRefs}) = _$PokemonMoveImpl;
  const _PokemonMove._() : super._();

  factory _PokemonMove.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  Map<String, String> get names;
  @override
  int? get generation;

  /// `showdown`, `seed`, `project_custom`, etc.
  @override
  String get source;
  @override
  String get type;
  @override
  PokemonMoveCategory get category;
  @override
  PokemonMoveTarget get target;
  @override
  int get basePower;
  @override
  PokemonMoveAccuracy get accuracy;
  @override
  int get pp;
  @override
  bool get noPpBoosts;
  @override
  int get priority;
  @override
  int get critRatio;

  /// Sémantiquement un ensemble, stocké comme liste sérialisable stable.
  @override
  List<PokemonMoveFlag> get flags;

  /// Tous les comportements applicatifs vivent ici.
  @override
  List<PokemonMoveEffect> get effects;
  @override
  String get shortDescription;
  @override
  String get description;
  @override
  PokemonMoveEngineSupportLevel get engineSupportLevel;
  @override
  List<String> get unsupportedReasons;
  @override
  PokemonMoveSourceRefs get sourceRefs;

  /// Create a copy of PokemonMove
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveImplCopyWith<_$PokemonMoveImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

```

### `packages/map_core/lib/src/models/pokemon_move_accuracy.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pokemon_move_accuracy.freezed.dart';
part 'pokemon_move_accuracy.g.dart';

/// Représentation canonique de la précision d'un move.
///
/// Le lot M2 tranche explicitement contre l'ancien duo ambigu
/// `accuracy` + `accuracyText` :
/// - un move touche soit toujours ;
/// - soit il utilise une précision en pourcentage.
///
/// On garde ce type très petit volontairement :
/// - il est sérialisable ;
/// - il est lisible ;
/// - il suffit pour le futur convertisseur, le seed et le runtime loader ;
/// - il n'embarque encore aucune logique moteur.
@Freezed(unionKey: 'kind', unionValueCase: FreezedUnionCase.snake)
class PokemonMoveAccuracy with _$PokemonMoveAccuracy {
  const PokemonMoveAccuracy._();

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveAccuracy.percent({
    required int value,
  }) = PokemonMoveAccuracyPercent;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveAccuracy.alwaysHits() =
      PokemonMoveAccuracyAlwaysHits;

  factory PokemonMoveAccuracy.fromJson(Map<String, dynamic> json) =>
      _$PokemonMoveAccuracyFromJson(json).normalized();

  /// Validation minimale locale du contrat `accuracy`.
  ///
  /// Le modèle de données doit déjà se défendre contre les cas absurdes les
  /// plus simples avant même tout loader runtime ou bridge battle :
  /// - `percent` doit rester dans une plage raisonnable ;
  /// - `alwaysHits` ne porte aucune donnée supplémentaire.
  PokemonMoveAccuracy normalized() {
    return map(
      percent: (accuracy) {
        if (accuracy.value < 1 || accuracy.value > 100) {
          throw StateError(
            'PokemonMoveAccuracy.percent value must be between 1 and 100',
          );
        }
        return accuracy;
      },
      alwaysHits: (accuracy) => accuracy,
    );
  }
}

```

### `packages/map_core/lib/src/models/pokemon_move_effect.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pokemon_move_effect.freezed.dart';
part 'pokemon_move_effect.g.dart';

/// Portée logique d'un effet structuré.
///
/// On ne copie pas ici la totalité du système de targeting Showdown :
/// - le move lui-même garde déjà son `target` natif ;
/// - les effets ont seulement besoin d'une portée de résolution lisible ;
/// - cela suffit pour la donnée projet et pour un futur bridge runtime -> battle.
enum PokemonMoveEffectTargetScope {
  @JsonValue('self')
  self,
  @JsonValue('target')
  target,
  @JsonValue('field')
  field,
  @JsonValue('ally_side')
  allySide,
  @JsonValue('foe_side')
  foeSide,
  @JsonValue('slot')
  slot,
}

/// Identifiant de stat utilisé par les effets de boost / baisse de stats.
///
/// Le modèle canonique reste volontairement plus lisible que les abréviations
/// internes de Showdown (`atk`, `spa`, etc.). Le convertisseur futur assumera
/// la traduction entre les deux représentations.
enum PokemonMoveStatId {
  @JsonValue('attack')
  attack,
  @JsonValue('defense')
  defense,
  @JsonValue('special_attack')
  specialAttack,
  @JsonValue('special_defense')
  specialDefense,
  @JsonValue('speed')
  speed,
  @JsonValue('accuracy')
  accuracy,
  @JsonValue('evasion')
  evasion,
}

/// Petite structure dédiée pour éviter un payload "Map<String, int>" flou.
///
/// Le lot M2 veut un modèle descriptif mais solide :
/// - un changement de stats doit être typé ;
/// - il doit rester simple à sérialiser ;
/// - il ne doit pas dépendre d'une clé texte magique.
@freezed
class PokemonMoveStatStageChange with _$PokemonMoveStatStageChange {
  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveStatStageChange({
    required PokemonMoveStatId stat,
    required int stages,
  }) = _PokemonMoveStatStageChange;

  factory PokemonMoveStatStageChange.fromJson(Map<String, dynamic> json) =>
      _$PokemonMoveStatStageChangeFromJson(json);
}

/// Effet structuré d'un move.
///
/// Décision centrale de M2 :
/// - les comportements de résolution vivent ici ;
/// - les champs natifs (`type`, `basePower`, `accuracy`, etc.) restent sur
///   `PokemonMove` ;
/// - on ne duplique pas une mécanique à la fois en champ natif et en payload
///   libre concurrent.
///
/// Important :
/// - ceci est une capacité de représentation ;
/// - ce n'est pas encore un moteur d'exécution ;
/// - chaque variant embarque seulement le payload nécessaire à la donnée.
@Freezed(unionKey: 'kind', unionValueCase: FreezedUnionCase.snake)
class PokemonMoveEffect with _$PokemonMoveEffect {
  const PokemonMoveEffect._();

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.fixedDamage({
    @Default(PokemonMoveEffectTargetScope.target)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,

    /// Valeur fixe exacte quand le move inflige un montant constant.
    int? value,

    /// Garde-fou minimal pour les cas "fixed damage = niveau du lanceur".
    @Default(false) bool usesUserLevel,
  }) = PokemonMoveEffectFixedDamage;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.multiHit({
    @Default(PokemonMoveEffectTargetScope.target)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
    required int minHits,
    required int maxHits,
  }) = PokemonMoveEffectMultiHit;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.applyStatus({
    @Default(PokemonMoveEffectTargetScope.target)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
    required String statusId,
  }) = PokemonMoveEffectApplyStatus;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.applyVolatileStatus({
    @Default(PokemonMoveEffectTargetScope.target)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
    required String volatileStatusId,
  }) = PokemonMoveEffectApplyVolatileStatus;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.modifyStats({
    @Default(PokemonMoveEffectTargetScope.target)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
    @Default(<PokemonMoveStatStageChange>[])
    List<PokemonMoveStatStageChange> stageChanges,
  }) = PokemonMoveEffectModifyStats;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.heal({
    @Default(PokemonMoveEffectTargetScope.self)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
    required int numerator,
    required int denominator,
  }) = PokemonMoveEffectHeal;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.drain({
    @Default(PokemonMoveEffectTargetScope.self)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
    required int numerator,
    required int denominator,
  }) = PokemonMoveEffectDrain;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.recoil({
    @Default(PokemonMoveEffectTargetScope.self)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
    required int numerator,
    required int denominator,
  }) = PokemonMoveEffectRecoil;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.setWeather({
    @Default(PokemonMoveEffectTargetScope.field)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
    required String weatherId,
  }) = PokemonMoveEffectSetWeather;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.setTerrain({
    @Default(PokemonMoveEffectTargetScope.field)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
    required String terrainId,
  }) = PokemonMoveEffectSetTerrain;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.setPseudoWeather({
    @Default(PokemonMoveEffectTargetScope.field)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
    required String pseudoWeatherId,
  }) = PokemonMoveEffectSetPseudoWeather;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.selfSwitch({
    @Default(PokemonMoveEffectTargetScope.self)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,

    /// Exemples futurs : `copyvolatile`, `shedtail`, `simple`.
    String? mode,
  }) = PokemonMoveEffectSelfSwitch;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.forceSwitch({
    @Default(PokemonMoveEffectTargetScope.target)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
  }) = PokemonMoveEffectForceSwitch;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.breakProtect({
    @Default(PokemonMoveEffectTargetScope.target)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
  }) = PokemonMoveEffectBreakProtect;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.requireRecharge({
    @Default(PokemonMoveEffectTargetScope.self)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
  }) = PokemonMoveEffectRequireRecharge;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.chargeThenStrike({
    @Default(PokemonMoveEffectTargetScope.self)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,

    /// Permet plus tard d'associer un volatile ou un marqueur de charge.
    String? chargeStateId,
  }) = PokemonMoveEffectChargeThenStrike;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.setSideCondition({
    @Default(PokemonMoveEffectTargetScope.foeSide)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
    required String conditionId,
  }) = PokemonMoveEffectSetSideCondition;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.setSlotCondition({
    @Default(PokemonMoveEffectTargetScope.slot)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
    required String conditionId,
  }) = PokemonMoveEffectSetSlotCondition;

  factory PokemonMoveEffect.fromJson(Map<String, dynamic> json) =>
      _$PokemonMoveEffectFromJson(json).normalized();

  /// Normalisation et validation défensive minimale.
  ///
  /// M2-bis ne transforme pas ce modèle en moteur, mais il doit déjà éviter
  /// les payloads les plus incohérents :
  /// - ids et chaînes obligatoires non vides ;
  /// - `chance` dans une plage raisonnable ;
  /// - `multiHit` cohérent ;
  /// - fractions strictement positives ;
  /// - `fixedDamage` non ambigu.
  PokemonMoveEffect normalized() {
    void validateChance(int? chance) {
      if (chance == null) {
        return;
      }
      if (chance < 1 || chance > 100) {
        throw StateError('PokemonMoveEffect chance must be between 1 and 100');
      }
    }

    int normalizePositivePart(String label, int value) {
      if (value <= 0) {
        throw StateError('$label must be strictly positive');
      }
      return value;
    }

    String normalizeRequiredId(String label, String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        throw StateError('$label must not be empty');
      }
      return trimmed;
    }

    return map(
      fixedDamage: (effect) {
        validateChance(effect.chance);
        final normalizedValue = effect.value;
        if (effect.usesUserLevel) {
          if (normalizedValue != null) {
            throw StateError(
              'PokemonMoveEffect.fixedDamage cannot define both value and usesUserLevel',
            );
          }
          return effect;
        }
        final value = normalizedValue;
        if (value == null || value <= 0) {
          throw StateError(
            'PokemonMoveEffect.fixedDamage requires a strictly positive value when usesUserLevel is false',
          );
        }
        return effect.copyWith(value: value);
      },
      multiHit: (effect) {
        validateChance(effect.chance);
        final minHits = normalizePositivePart(
            'PokemonMoveEffect.multiHit minHits', effect.minHits);
        final maxHits = normalizePositivePart(
            'PokemonMoveEffect.multiHit maxHits', effect.maxHits);
        if (minHits > maxHits) {
          throw StateError(
            'PokemonMoveEffect.multiHit minHits must be less than or equal to maxHits',
          );
        }
        return effect.copyWith(
          minHits: minHits,
          maxHits: maxHits,
        );
      },
      applyStatus: (effect) {
        validateChance(effect.chance);
        return effect.copyWith(
          statusId: normalizeRequiredId(
            'PokemonMoveEffect.applyStatus statusId',
            effect.statusId,
          ),
        );
      },
      applyVolatileStatus: (effect) {
        validateChance(effect.chance);
        return effect.copyWith(
          volatileStatusId: normalizeRequiredId(
            'PokemonMoveEffect.applyVolatileStatus volatileStatusId',
            effect.volatileStatusId,
          ),
        );
      },
      modifyStats: (effect) {
        validateChance(effect.chance);
        final stageChanges = effect.stageChanges;
        if (stageChanges.isEmpty) {
          throw StateError(
            'PokemonMoveEffect.modifyStats stageChanges must not be empty',
          );
        }
        final seen = <PokemonMoveStatId>{};
        for (final stageChange in stageChanges) {
          if (stageChange.stages == 0) {
            throw StateError(
              'PokemonMoveEffect.modifyStats stageChanges must not contain zero stages',
            );
          }
          if (!seen.add(stageChange.stat)) {
            throw StateError(
              'PokemonMoveEffect.modifyStats stageChanges must not contain duplicate stats',
            );
          }
        }
        return effect;
      },
      heal: (effect) {
        validateChance(effect.chance);
        return effect.copyWith(
          numerator: normalizePositivePart(
              'PokemonMoveEffect.heal numerator', effect.numerator),
          denominator: normalizePositivePart(
            'PokemonMoveEffect.heal denominator',
            effect.denominator,
          ),
        );
      },
      drain: (effect) {
        validateChance(effect.chance);
        return effect.copyWith(
          numerator: normalizePositivePart(
              'PokemonMoveEffect.drain numerator', effect.numerator),
          denominator: normalizePositivePart(
            'PokemonMoveEffect.drain denominator',
            effect.denominator,
          ),
        );
      },
      recoil: (effect) {
        validateChance(effect.chance);
        return effect.copyWith(
          numerator: normalizePositivePart(
            'PokemonMoveEffect.recoil numerator',
            effect.numerator,
          ),
          denominator: normalizePositivePart(
            'PokemonMoveEffect.recoil denominator',
            effect.denominator,
          ),
        );
      },
      setWeather: (effect) {
        validateChance(effect.chance);
        return effect.copyWith(
          weatherId: normalizeRequiredId(
            'PokemonMoveEffect.setWeather weatherId',
            effect.weatherId,
          ),
        );
      },
      setTerrain: (effect) {
        validateChance(effect.chance);
        return effect.copyWith(
          terrainId: normalizeRequiredId(
            'PokemonMoveEffect.setTerrain terrainId',
            effect.terrainId,
          ),
        );
      },
      setPseudoWeather: (effect) {
        validateChance(effect.chance);
        return effect.copyWith(
          pseudoWeatherId: normalizeRequiredId(
            'PokemonMoveEffect.setPseudoWeather pseudoWeatherId',
            effect.pseudoWeatherId,
          ),
        );
      },
      selfSwitch: (effect) {
        validateChance(effect.chance);
        final normalizedMode = effect.mode?.trim();
        return effect.copyWith(
          mode: normalizedMode == null || normalizedMode.isEmpty
              ? null
              : normalizedMode,
        );
      },
      forceSwitch: (effect) {
        validateChance(effect.chance);
        return effect;
      },
      breakProtect: (effect) {
        validateChance(effect.chance);
        return effect;
      },
      requireRecharge: (effect) {
        validateChance(effect.chance);
        return effect;
      },
      chargeThenStrike: (effect) {
        validateChance(effect.chance);
        final normalizedChargeStateId = effect.chargeStateId?.trim();
        return effect.copyWith(
          chargeStateId:
              normalizedChargeStateId == null || normalizedChargeStateId.isEmpty
                  ? null
                  : normalizedChargeStateId,
        );
      },
      setSideCondition: (effect) {
        validateChance(effect.chance);
        return effect.copyWith(
          conditionId: normalizeRequiredId(
            'PokemonMoveEffect.setSideCondition conditionId',
            effect.conditionId,
          ),
        );
      },
      setSlotCondition: (effect) {
        validateChance(effect.chance);
        return effect.copyWith(
          conditionId: normalizeRequiredId(
            'PokemonMoveEffect.setSlotCondition conditionId',
            effect.conditionId,
          ),
        );
      },
    );
  }
}

```

### `packages/map_core/lib/src/models/pokemon_move_effect.freezed.dart`

```dart
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pokemon_move_effect.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PokemonMoveStatStageChange _$PokemonMoveStatStageChangeFromJson(
    Map<String, dynamic> json) {
  return _PokemonMoveStatStageChange.fromJson(json);
}

/// @nodoc
mixin _$PokemonMoveStatStageChange {
  PokemonMoveStatId get stat => throw _privateConstructorUsedError;
  int get stages => throw _privateConstructorUsedError;

  /// Serializes this PokemonMoveStatStageChange to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PokemonMoveStatStageChange
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PokemonMoveStatStageChangeCopyWith<PokemonMoveStatStageChange>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PokemonMoveStatStageChangeCopyWith<$Res> {
  factory $PokemonMoveStatStageChangeCopyWith(PokemonMoveStatStageChange value,
          $Res Function(PokemonMoveStatStageChange) then) =
      _$PokemonMoveStatStageChangeCopyWithImpl<$Res,
          PokemonMoveStatStageChange>;
  @useResult
  $Res call({PokemonMoveStatId stat, int stages});
}

/// @nodoc
class _$PokemonMoveStatStageChangeCopyWithImpl<$Res,
        $Val extends PokemonMoveStatStageChange>
    implements $PokemonMoveStatStageChangeCopyWith<$Res> {
  _$PokemonMoveStatStageChangeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PokemonMoveStatStageChange
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stat = null,
    Object? stages = null,
  }) {
    return _then(_value.copyWith(
      stat: null == stat
          ? _value.stat
          : stat // ignore: cast_nullable_to_non_nullable
              as PokemonMoveStatId,
      stages: null == stages
          ? _value.stages
          : stages // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PokemonMoveStatStageChangeImplCopyWith<$Res>
    implements $PokemonMoveStatStageChangeCopyWith<$Res> {
  factory _$$PokemonMoveStatStageChangeImplCopyWith(
          _$PokemonMoveStatStageChangeImpl value,
          $Res Function(_$PokemonMoveStatStageChangeImpl) then) =
      __$$PokemonMoveStatStageChangeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({PokemonMoveStatId stat, int stages});
}

/// @nodoc
class __$$PokemonMoveStatStageChangeImplCopyWithImpl<$Res>
    extends _$PokemonMoveStatStageChangeCopyWithImpl<$Res,
        _$PokemonMoveStatStageChangeImpl>
    implements _$$PokemonMoveStatStageChangeImplCopyWith<$Res> {
  __$$PokemonMoveStatStageChangeImplCopyWithImpl(
      _$PokemonMoveStatStageChangeImpl _value,
      $Res Function(_$PokemonMoveStatStageChangeImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveStatStageChange
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stat = null,
    Object? stages = null,
  }) {
    return _then(_$PokemonMoveStatStageChangeImpl(
      stat: null == stat
          ? _value.stat
          : stat // ignore: cast_nullable_to_non_nullable
              as PokemonMoveStatId,
      stages: null == stages
          ? _value.stages
          : stages // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveStatStageChangeImpl implements _PokemonMoveStatStageChange {
  const _$PokemonMoveStatStageChangeImpl(
      {required this.stat, required this.stages});

  factory _$PokemonMoveStatStageChangeImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveStatStageChangeImplFromJson(json);

  @override
  final PokemonMoveStatId stat;
  @override
  final int stages;

  @override
  String toString() {
    return 'PokemonMoveStatStageChange(stat: $stat, stages: $stages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveStatStageChangeImpl &&
            (identical(other.stat, stat) || other.stat == stat) &&
            (identical(other.stages, stages) || other.stages == stages));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, stat, stages);

  /// Create a copy of PokemonMoveStatStageChange
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveStatStageChangeImplCopyWith<_$PokemonMoveStatStageChangeImpl>
      get copyWith => __$$PokemonMoveStatStageChangeImplCopyWithImpl<
          _$PokemonMoveStatStageChangeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveStatStageChangeImplToJson(
      this,
    );
  }
}

abstract class _PokemonMoveStatStageChange
    implements PokemonMoveStatStageChange {
  const factory _PokemonMoveStatStageChange(
      {required final PokemonMoveStatId stat,
      required final int stages}) = _$PokemonMoveStatStageChangeImpl;

  factory _PokemonMoveStatStageChange.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveStatStageChangeImpl.fromJson;

  @override
  PokemonMoveStatId get stat;
  @override
  int get stages;

  /// Create a copy of PokemonMoveStatStageChange
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveStatStageChangeImplCopyWith<_$PokemonMoveStatStageChangeImpl>
      get copyWith => throw _privateConstructorUsedError;
}

PokemonMoveEffect _$PokemonMoveEffectFromJson(Map<String, dynamic> json) {
  switch (json['kind']) {
    case 'fixed_damage':
      return PokemonMoveEffectFixedDamage.fromJson(json);
    case 'multi_hit':
      return PokemonMoveEffectMultiHit.fromJson(json);
    case 'apply_status':
      return PokemonMoveEffectApplyStatus.fromJson(json);
    case 'apply_volatile_status':
      return PokemonMoveEffectApplyVolatileStatus.fromJson(json);
    case 'modify_stats':
      return PokemonMoveEffectModifyStats.fromJson(json);
    case 'heal':
      return PokemonMoveEffectHeal.fromJson(json);
    case 'drain':
      return PokemonMoveEffectDrain.fromJson(json);
    case 'recoil':
      return PokemonMoveEffectRecoil.fromJson(json);
    case 'set_weather':
      return PokemonMoveEffectSetWeather.fromJson(json);
    case 'set_terrain':
      return PokemonMoveEffectSetTerrain.fromJson(json);
    case 'set_pseudo_weather':
      return PokemonMoveEffectSetPseudoWeather.fromJson(json);
    case 'self_switch':
      return PokemonMoveEffectSelfSwitch.fromJson(json);
    case 'force_switch':
      return PokemonMoveEffectForceSwitch.fromJson(json);
    case 'break_protect':
      return PokemonMoveEffectBreakProtect.fromJson(json);
    case 'require_recharge':
      return PokemonMoveEffectRequireRecharge.fromJson(json);
    case 'charge_then_strike':
      return PokemonMoveEffectChargeThenStrike.fromJson(json);
    case 'set_side_condition':
      return PokemonMoveEffectSetSideCondition.fromJson(json);
    case 'set_slot_condition':
      return PokemonMoveEffectSetSlotCondition.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'kind', 'PokemonMoveEffect',
          'Invalid union type "${json['kind']}"!');
  }
}

/// @nodoc
mixin _$PokemonMoveEffect {
  PokemonMoveEffectTargetScope get targetScope =>
      throw _privateConstructorUsedError;
  int? get chance => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String pseudoWeatherId)
        setPseudoWeather,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSetPseudoWeather value)
        setPseudoWeather,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSetPseudoWeather value)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSetPseudoWeather value)? setPseudoWeather,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this PokemonMoveEffect to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PokemonMoveEffectCopyWith<PokemonMoveEffect> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PokemonMoveEffectCopyWith<$Res> {
  factory $PokemonMoveEffectCopyWith(
          PokemonMoveEffect value, $Res Function(PokemonMoveEffect) then) =
      _$PokemonMoveEffectCopyWithImpl<$Res, PokemonMoveEffect>;
  @useResult
  $Res call({PokemonMoveEffectTargetScope targetScope, int? chance});
}

/// @nodoc
class _$PokemonMoveEffectCopyWithImpl<$Res, $Val extends PokemonMoveEffect>
    implements $PokemonMoveEffectCopyWith<$Res> {
  _$PokemonMoveEffectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
  }) {
    return _then(_value.copyWith(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PokemonMoveEffectFixedDamageImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectFixedDamageImplCopyWith(
          _$PokemonMoveEffectFixedDamageImpl value,
          $Res Function(_$PokemonMoveEffectFixedDamageImpl) then) =
      __$$PokemonMoveEffectFixedDamageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope,
      int? chance,
      int? value,
      bool usesUserLevel});
}

/// @nodoc
class __$$PokemonMoveEffectFixedDamageImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectFixedDamageImpl>
    implements _$$PokemonMoveEffectFixedDamageImplCopyWith<$Res> {
  __$$PokemonMoveEffectFixedDamageImplCopyWithImpl(
      _$PokemonMoveEffectFixedDamageImpl _value,
      $Res Function(_$PokemonMoveEffectFixedDamageImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? value = freezed,
    Object? usesUserLevel = null,
  }) {
    return _then(_$PokemonMoveEffectFixedDamageImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      value: freezed == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as int?,
      usesUserLevel: null == usesUserLevel
          ? _value.usesUserLevel
          : usesUserLevel // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectFixedDamageImpl extends PokemonMoveEffectFixedDamage {
  const _$PokemonMoveEffectFixedDamageImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.target,
      this.chance,
      this.value,
      this.usesUserLevel = false,
      final String? $type})
      : $type = $type ?? 'fixed_damage',
        super._();

  factory _$PokemonMoveEffectFixedDamageImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveEffectFixedDamageImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;

  /// Valeur fixe exacte quand le move inflige un montant constant.
  @override
  final int? value;

  /// Garde-fou minimal pour les cas "fixed damage = niveau du lanceur".
  @override
  @JsonKey()
  final bool usesUserLevel;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.fixedDamage(targetScope: $targetScope, chance: $chance, value: $value, usesUserLevel: $usesUserLevel)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectFixedDamageImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.usesUserLevel, usesUserLevel) ||
                other.usesUserLevel == usesUserLevel));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, targetScope, chance, value, usesUserLevel);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectFixedDamageImplCopyWith<
          _$PokemonMoveEffectFixedDamageImpl>
      get copyWith => __$$PokemonMoveEffectFixedDamageImplCopyWithImpl<
          _$PokemonMoveEffectFixedDamageImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String pseudoWeatherId)
        setPseudoWeather,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return fixedDamage(targetScope, chance, value, usesUserLevel);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return fixedDamage?.call(targetScope, chance, value, usesUserLevel);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (fixedDamage != null) {
      return fixedDamage(targetScope, chance, value, usesUserLevel);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSetPseudoWeather value)
        setPseudoWeather,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return fixedDamage(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSetPseudoWeather value)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return fixedDamage?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSetPseudoWeather value)? setPseudoWeather,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (fixedDamage != null) {
      return fixedDamage(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectFixedDamageImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectFixedDamage extends PokemonMoveEffect {
  const factory PokemonMoveEffectFixedDamage(
      {final PokemonMoveEffectTargetScope targetScope,
      final int? chance,
      final int? value,
      final bool usesUserLevel}) = _$PokemonMoveEffectFixedDamageImpl;
  const PokemonMoveEffectFixedDamage._() : super._();

  factory PokemonMoveEffectFixedDamage.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveEffectFixedDamageImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;

  /// Valeur fixe exacte quand le move inflige un montant constant.
  int? get value;

  /// Garde-fou minimal pour les cas "fixed damage = niveau du lanceur".
  bool get usesUserLevel;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectFixedDamageImplCopyWith<
          _$PokemonMoveEffectFixedDamageImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectMultiHitImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectMultiHitImplCopyWith(
          _$PokemonMoveEffectMultiHitImpl value,
          $Res Function(_$PokemonMoveEffectMultiHitImpl) then) =
      __$$PokemonMoveEffectMultiHitImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope,
      int? chance,
      int minHits,
      int maxHits});
}

/// @nodoc
class __$$PokemonMoveEffectMultiHitImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectMultiHitImpl>
    implements _$$PokemonMoveEffectMultiHitImplCopyWith<$Res> {
  __$$PokemonMoveEffectMultiHitImplCopyWithImpl(
      _$PokemonMoveEffectMultiHitImpl _value,
      $Res Function(_$PokemonMoveEffectMultiHitImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? minHits = null,
    Object? maxHits = null,
  }) {
    return _then(_$PokemonMoveEffectMultiHitImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      minHits: null == minHits
          ? _value.minHits
          : minHits // ignore: cast_nullable_to_non_nullable
              as int,
      maxHits: null == maxHits
          ? _value.maxHits
          : maxHits // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectMultiHitImpl extends PokemonMoveEffectMultiHit {
  const _$PokemonMoveEffectMultiHitImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.target,
      this.chance,
      required this.minHits,
      required this.maxHits,
      final String? $type})
      : $type = $type ?? 'multi_hit',
        super._();

  factory _$PokemonMoveEffectMultiHitImpl.fromJson(Map<String, dynamic> json) =>
      _$$PokemonMoveEffectMultiHitImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;
  @override
  final int minHits;
  @override
  final int maxHits;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.multiHit(targetScope: $targetScope, chance: $chance, minHits: $minHits, maxHits: $maxHits)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectMultiHitImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            (identical(other.minHits, minHits) || other.minHits == minHits) &&
            (identical(other.maxHits, maxHits) || other.maxHits == maxHits));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, targetScope, chance, minHits, maxHits);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectMultiHitImplCopyWith<_$PokemonMoveEffectMultiHitImpl>
      get copyWith => __$$PokemonMoveEffectMultiHitImplCopyWithImpl<
          _$PokemonMoveEffectMultiHitImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String pseudoWeatherId)
        setPseudoWeather,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return multiHit(targetScope, chance, minHits, maxHits);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return multiHit?.call(targetScope, chance, minHits, maxHits);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (multiHit != null) {
      return multiHit(targetScope, chance, minHits, maxHits);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSetPseudoWeather value)
        setPseudoWeather,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return multiHit(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSetPseudoWeather value)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return multiHit?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSetPseudoWeather value)? setPseudoWeather,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (multiHit != null) {
      return multiHit(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectMultiHitImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectMultiHit extends PokemonMoveEffect {
  const factory PokemonMoveEffectMultiHit(
      {final PokemonMoveEffectTargetScope targetScope,
      final int? chance,
      required final int minHits,
      required final int maxHits}) = _$PokemonMoveEffectMultiHitImpl;
  const PokemonMoveEffectMultiHit._() : super._();

  factory PokemonMoveEffectMultiHit.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveEffectMultiHitImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;
  int get minHits;
  int get maxHits;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectMultiHitImplCopyWith<_$PokemonMoveEffectMultiHitImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectApplyStatusImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectApplyStatusImplCopyWith(
          _$PokemonMoveEffectApplyStatusImpl value,
          $Res Function(_$PokemonMoveEffectApplyStatusImpl) then) =
      __$$PokemonMoveEffectApplyStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope, int? chance, String statusId});
}

/// @nodoc
class __$$PokemonMoveEffectApplyStatusImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectApplyStatusImpl>
    implements _$$PokemonMoveEffectApplyStatusImplCopyWith<$Res> {
  __$$PokemonMoveEffectApplyStatusImplCopyWithImpl(
      _$PokemonMoveEffectApplyStatusImpl _value,
      $Res Function(_$PokemonMoveEffectApplyStatusImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? statusId = null,
  }) {
    return _then(_$PokemonMoveEffectApplyStatusImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      statusId: null == statusId
          ? _value.statusId
          : statusId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectApplyStatusImpl extends PokemonMoveEffectApplyStatus {
  const _$PokemonMoveEffectApplyStatusImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.target,
      this.chance,
      required this.statusId,
      final String? $type})
      : $type = $type ?? 'apply_status',
        super._();

  factory _$PokemonMoveEffectApplyStatusImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveEffectApplyStatusImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;
  @override
  final String statusId;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.applyStatus(targetScope: $targetScope, chance: $chance, statusId: $statusId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectApplyStatusImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            (identical(other.statusId, statusId) ||
                other.statusId == statusId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, targetScope, chance, statusId);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectApplyStatusImplCopyWith<
          _$PokemonMoveEffectApplyStatusImpl>
      get copyWith => __$$PokemonMoveEffectApplyStatusImplCopyWithImpl<
          _$PokemonMoveEffectApplyStatusImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String pseudoWeatherId)
        setPseudoWeather,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return applyStatus(targetScope, chance, statusId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return applyStatus?.call(targetScope, chance, statusId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (applyStatus != null) {
      return applyStatus(targetScope, chance, statusId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSetPseudoWeather value)
        setPseudoWeather,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return applyStatus(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSetPseudoWeather value)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return applyStatus?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSetPseudoWeather value)? setPseudoWeather,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (applyStatus != null) {
      return applyStatus(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectApplyStatusImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectApplyStatus extends PokemonMoveEffect {
  const factory PokemonMoveEffectApplyStatus(
      {final PokemonMoveEffectTargetScope targetScope,
      final int? chance,
      required final String statusId}) = _$PokemonMoveEffectApplyStatusImpl;
  const PokemonMoveEffectApplyStatus._() : super._();

  factory PokemonMoveEffectApplyStatus.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveEffectApplyStatusImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;
  String get statusId;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectApplyStatusImplCopyWith<
          _$PokemonMoveEffectApplyStatusImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectApplyVolatileStatusImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectApplyVolatileStatusImplCopyWith(
          _$PokemonMoveEffectApplyVolatileStatusImpl value,
          $Res Function(_$PokemonMoveEffectApplyVolatileStatusImpl) then) =
      __$$PokemonMoveEffectApplyVolatileStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope,
      int? chance,
      String volatileStatusId});
}

/// @nodoc
class __$$PokemonMoveEffectApplyVolatileStatusImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectApplyVolatileStatusImpl>
    implements _$$PokemonMoveEffectApplyVolatileStatusImplCopyWith<$Res> {
  __$$PokemonMoveEffectApplyVolatileStatusImplCopyWithImpl(
      _$PokemonMoveEffectApplyVolatileStatusImpl _value,
      $Res Function(_$PokemonMoveEffectApplyVolatileStatusImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? volatileStatusId = null,
  }) {
    return _then(_$PokemonMoveEffectApplyVolatileStatusImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      volatileStatusId: null == volatileStatusId
          ? _value.volatileStatusId
          : volatileStatusId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectApplyVolatileStatusImpl
    extends PokemonMoveEffectApplyVolatileStatus {
  const _$PokemonMoveEffectApplyVolatileStatusImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.target,
      this.chance,
      required this.volatileStatusId,
      final String? $type})
      : $type = $type ?? 'apply_volatile_status',
        super._();

  factory _$PokemonMoveEffectApplyVolatileStatusImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveEffectApplyVolatileStatusImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;
  @override
  final String volatileStatusId;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.applyVolatileStatus(targetScope: $targetScope, chance: $chance, volatileStatusId: $volatileStatusId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectApplyVolatileStatusImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            (identical(other.volatileStatusId, volatileStatusId) ||
                other.volatileStatusId == volatileStatusId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, targetScope, chance, volatileStatusId);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectApplyVolatileStatusImplCopyWith<
          _$PokemonMoveEffectApplyVolatileStatusImpl>
      get copyWith => __$$PokemonMoveEffectApplyVolatileStatusImplCopyWithImpl<
          _$PokemonMoveEffectApplyVolatileStatusImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String pseudoWeatherId)
        setPseudoWeather,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return applyVolatileStatus(targetScope, chance, volatileStatusId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return applyVolatileStatus?.call(targetScope, chance, volatileStatusId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (applyVolatileStatus != null) {
      return applyVolatileStatus(targetScope, chance, volatileStatusId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSetPseudoWeather value)
        setPseudoWeather,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return applyVolatileStatus(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSetPseudoWeather value)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return applyVolatileStatus?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSetPseudoWeather value)? setPseudoWeather,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (applyVolatileStatus != null) {
      return applyVolatileStatus(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectApplyVolatileStatusImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectApplyVolatileStatus extends PokemonMoveEffect {
  const factory PokemonMoveEffectApplyVolatileStatus(
          {final PokemonMoveEffectTargetScope targetScope,
          final int? chance,
          required final String volatileStatusId}) =
      _$PokemonMoveEffectApplyVolatileStatusImpl;
  const PokemonMoveEffectApplyVolatileStatus._() : super._();

  factory PokemonMoveEffectApplyVolatileStatus.fromJson(
          Map<String, dynamic> json) =
      _$PokemonMoveEffectApplyVolatileStatusImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;
  String get volatileStatusId;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectApplyVolatileStatusImplCopyWith<
          _$PokemonMoveEffectApplyVolatileStatusImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectModifyStatsImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectModifyStatsImplCopyWith(
          _$PokemonMoveEffectModifyStatsImpl value,
          $Res Function(_$PokemonMoveEffectModifyStatsImpl) then) =
      __$$PokemonMoveEffectModifyStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope,
      int? chance,
      List<PokemonMoveStatStageChange> stageChanges});
}

/// @nodoc
class __$$PokemonMoveEffectModifyStatsImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectModifyStatsImpl>
    implements _$$PokemonMoveEffectModifyStatsImplCopyWith<$Res> {
  __$$PokemonMoveEffectModifyStatsImplCopyWithImpl(
      _$PokemonMoveEffectModifyStatsImpl _value,
      $Res Function(_$PokemonMoveEffectModifyStatsImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? stageChanges = null,
  }) {
    return _then(_$PokemonMoveEffectModifyStatsImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      stageChanges: null == stageChanges
          ? _value._stageChanges
          : stageChanges // ignore: cast_nullable_to_non_nullable
              as List<PokemonMoveStatStageChange>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectModifyStatsImpl extends PokemonMoveEffectModifyStats {
  const _$PokemonMoveEffectModifyStatsImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.target,
      this.chance,
      final List<PokemonMoveStatStageChange> stageChanges =
          const <PokemonMoveStatStageChange>[],
      final String? $type})
      : _stageChanges = stageChanges,
        $type = $type ?? 'modify_stats',
        super._();

  factory _$PokemonMoveEffectModifyStatsImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveEffectModifyStatsImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;
  final List<PokemonMoveStatStageChange> _stageChanges;
  @override
  @JsonKey()
  List<PokemonMoveStatStageChange> get stageChanges {
    if (_stageChanges is EqualUnmodifiableListView) return _stageChanges;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_stageChanges);
  }

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.modifyStats(targetScope: $targetScope, chance: $chance, stageChanges: $stageChanges)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectModifyStatsImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            const DeepCollectionEquality()
                .equals(other._stageChanges, _stageChanges));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, targetScope, chance,
      const DeepCollectionEquality().hash(_stageChanges));

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectModifyStatsImplCopyWith<
          _$PokemonMoveEffectModifyStatsImpl>
      get copyWith => __$$PokemonMoveEffectModifyStatsImplCopyWithImpl<
          _$PokemonMoveEffectModifyStatsImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String pseudoWeatherId)
        setPseudoWeather,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return modifyStats(targetScope, chance, stageChanges);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return modifyStats?.call(targetScope, chance, stageChanges);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (modifyStats != null) {
      return modifyStats(targetScope, chance, stageChanges);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSetPseudoWeather value)
        setPseudoWeather,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return modifyStats(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSetPseudoWeather value)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return modifyStats?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSetPseudoWeather value)? setPseudoWeather,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (modifyStats != null) {
      return modifyStats(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectModifyStatsImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectModifyStats extends PokemonMoveEffect {
  const factory PokemonMoveEffectModifyStats(
          {final PokemonMoveEffectTargetScope targetScope,
          final int? chance,
          final List<PokemonMoveStatStageChange> stageChanges}) =
      _$PokemonMoveEffectModifyStatsImpl;
  const PokemonMoveEffectModifyStats._() : super._();

  factory PokemonMoveEffectModifyStats.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveEffectModifyStatsImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;
  List<PokemonMoveStatStageChange> get stageChanges;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectModifyStatsImplCopyWith<
          _$PokemonMoveEffectModifyStatsImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectHealImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectHealImplCopyWith(
          _$PokemonMoveEffectHealImpl value,
          $Res Function(_$PokemonMoveEffectHealImpl) then) =
      __$$PokemonMoveEffectHealImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope,
      int? chance,
      int numerator,
      int denominator});
}

/// @nodoc
class __$$PokemonMoveEffectHealImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res, _$PokemonMoveEffectHealImpl>
    implements _$$PokemonMoveEffectHealImplCopyWith<$Res> {
  __$$PokemonMoveEffectHealImplCopyWithImpl(_$PokemonMoveEffectHealImpl _value,
      $Res Function(_$PokemonMoveEffectHealImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? numerator = null,
    Object? denominator = null,
  }) {
    return _then(_$PokemonMoveEffectHealImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      numerator: null == numerator
          ? _value.numerator
          : numerator // ignore: cast_nullable_to_non_nullable
              as int,
      denominator: null == denominator
          ? _value.denominator
          : denominator // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectHealImpl extends PokemonMoveEffectHeal {
  const _$PokemonMoveEffectHealImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.self,
      this.chance,
      required this.numerator,
      required this.denominator,
      final String? $type})
      : $type = $type ?? 'heal',
        super._();

  factory _$PokemonMoveEffectHealImpl.fromJson(Map<String, dynamic> json) =>
      _$$PokemonMoveEffectHealImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;
  @override
  final int numerator;
  @override
  final int denominator;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.heal(targetScope: $targetScope, chance: $chance, numerator: $numerator, denominator: $denominator)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectHealImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            (identical(other.numerator, numerator) ||
                other.numerator == numerator) &&
            (identical(other.denominator, denominator) ||
                other.denominator == denominator));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, targetScope, chance, numerator, denominator);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectHealImplCopyWith<_$PokemonMoveEffectHealImpl>
      get copyWith => __$$PokemonMoveEffectHealImplCopyWithImpl<
          _$PokemonMoveEffectHealImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String pseudoWeatherId)
        setPseudoWeather,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return heal(targetScope, chance, numerator, denominator);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return heal?.call(targetScope, chance, numerator, denominator);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (heal != null) {
      return heal(targetScope, chance, numerator, denominator);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSetPseudoWeather value)
        setPseudoWeather,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return heal(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSetPseudoWeather value)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return heal?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSetPseudoWeather value)? setPseudoWeather,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (heal != null) {
      return heal(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectHealImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectHeal extends PokemonMoveEffect {
  const factory PokemonMoveEffectHeal(
      {final PokemonMoveEffectTargetScope targetScope,
      final int? chance,
      required final int numerator,
      required final int denominator}) = _$PokemonMoveEffectHealImpl;
  const PokemonMoveEffectHeal._() : super._();

  factory PokemonMoveEffectHeal.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveEffectHealImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;
  int get numerator;
  int get denominator;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectHealImplCopyWith<_$PokemonMoveEffectHealImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectDrainImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectDrainImplCopyWith(
          _$PokemonMoveEffectDrainImpl value,
          $Res Function(_$PokemonMoveEffectDrainImpl) then) =
      __$$PokemonMoveEffectDrainImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope,
      int? chance,
      int numerator,
      int denominator});
}

/// @nodoc
class __$$PokemonMoveEffectDrainImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res, _$PokemonMoveEffectDrainImpl>
    implements _$$PokemonMoveEffectDrainImplCopyWith<$Res> {
  __$$PokemonMoveEffectDrainImplCopyWithImpl(
      _$PokemonMoveEffectDrainImpl _value,
      $Res Function(_$PokemonMoveEffectDrainImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? numerator = null,
    Object? denominator = null,
  }) {
    return _then(_$PokemonMoveEffectDrainImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      numerator: null == numerator
          ? _value.numerator
          : numerator // ignore: cast_nullable_to_non_nullable
              as int,
      denominator: null == denominator
          ? _value.denominator
          : denominator // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectDrainImpl extends PokemonMoveEffectDrain {
  const _$PokemonMoveEffectDrainImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.self,
      this.chance,
      required this.numerator,
      required this.denominator,
      final String? $type})
      : $type = $type ?? 'drain',
        super._();

  factory _$PokemonMoveEffectDrainImpl.fromJson(Map<String, dynamic> json) =>
      _$$PokemonMoveEffectDrainImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;
  @override
  final int numerator;
  @override
  final int denominator;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.drain(targetScope: $targetScope, chance: $chance, numerator: $numerator, denominator: $denominator)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectDrainImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            (identical(other.numerator, numerator) ||
                other.numerator == numerator) &&
            (identical(other.denominator, denominator) ||
                other.denominator == denominator));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, targetScope, chance, numerator, denominator);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectDrainImplCopyWith<_$PokemonMoveEffectDrainImpl>
      get copyWith => __$$PokemonMoveEffectDrainImplCopyWithImpl<
          _$PokemonMoveEffectDrainImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String pseudoWeatherId)
        setPseudoWeather,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return drain(targetScope, chance, numerator, denominator);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return drain?.call(targetScope, chance, numerator, denominator);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (drain != null) {
      return drain(targetScope, chance, numerator, denominator);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSetPseudoWeather value)
        setPseudoWeather,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return drain(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSetPseudoWeather value)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return drain?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSetPseudoWeather value)? setPseudoWeather,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (drain != null) {
      return drain(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectDrainImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectDrain extends PokemonMoveEffect {
  const factory PokemonMoveEffectDrain(
      {final PokemonMoveEffectTargetScope targetScope,
      final int? chance,
      required final int numerator,
      required final int denominator}) = _$PokemonMoveEffectDrainImpl;
  const PokemonMoveEffectDrain._() : super._();

  factory PokemonMoveEffectDrain.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveEffectDrainImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;
  int get numerator;
  int get denominator;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectDrainImplCopyWith<_$PokemonMoveEffectDrainImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectRecoilImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectRecoilImplCopyWith(
          _$PokemonMoveEffectRecoilImpl value,
          $Res Function(_$PokemonMoveEffectRecoilImpl) then) =
      __$$PokemonMoveEffectRecoilImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope,
      int? chance,
      int numerator,
      int denominator});
}

/// @nodoc
class __$$PokemonMoveEffectRecoilImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res, _$PokemonMoveEffectRecoilImpl>
    implements _$$PokemonMoveEffectRecoilImplCopyWith<$Res> {
  __$$PokemonMoveEffectRecoilImplCopyWithImpl(
      _$PokemonMoveEffectRecoilImpl _value,
      $Res Function(_$PokemonMoveEffectRecoilImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? numerator = null,
    Object? denominator = null,
  }) {
    return _then(_$PokemonMoveEffectRecoilImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      numerator: null == numerator
          ? _value.numerator
          : numerator // ignore: cast_nullable_to_non_nullable
              as int,
      denominator: null == denominator
          ? _value.denominator
          : denominator // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectRecoilImpl extends PokemonMoveEffectRecoil {
  const _$PokemonMoveEffectRecoilImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.self,
      this.chance,
      required this.numerator,
      required this.denominator,
      final String? $type})
      : $type = $type ?? 'recoil',
        super._();

  factory _$PokemonMoveEffectRecoilImpl.fromJson(Map<String, dynamic> json) =>
      _$$PokemonMoveEffectRecoilImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;
  @override
  final int numerator;
  @override
  final int denominator;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.recoil(targetScope: $targetScope, chance: $chance, numerator: $numerator, denominator: $denominator)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectRecoilImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            (identical(other.numerator, numerator) ||
                other.numerator == numerator) &&
            (identical(other.denominator, denominator) ||
                other.denominator == denominator));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, targetScope, chance, numerator, denominator);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectRecoilImplCopyWith<_$PokemonMoveEffectRecoilImpl>
      get copyWith => __$$PokemonMoveEffectRecoilImplCopyWithImpl<
          _$PokemonMoveEffectRecoilImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String pseudoWeatherId)
        setPseudoWeather,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return recoil(targetScope, chance, numerator, denominator);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return recoil?.call(targetScope, chance, numerator, denominator);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (recoil != null) {
      return recoil(targetScope, chance, numerator, denominator);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSetPseudoWeather value)
        setPseudoWeather,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return recoil(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSetPseudoWeather value)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return recoil?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSetPseudoWeather value)? setPseudoWeather,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (recoil != null) {
      return recoil(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectRecoilImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectRecoil extends PokemonMoveEffect {
  const factory PokemonMoveEffectRecoil(
      {final PokemonMoveEffectTargetScope targetScope,
      final int? chance,
      required final int numerator,
      required final int denominator}) = _$PokemonMoveEffectRecoilImpl;
  const PokemonMoveEffectRecoil._() : super._();

  factory PokemonMoveEffectRecoil.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveEffectRecoilImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;
  int get numerator;
  int get denominator;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectRecoilImplCopyWith<_$PokemonMoveEffectRecoilImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectSetWeatherImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectSetWeatherImplCopyWith(
          _$PokemonMoveEffectSetWeatherImpl value,
          $Res Function(_$PokemonMoveEffectSetWeatherImpl) then) =
      __$$PokemonMoveEffectSetWeatherImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope,
      int? chance,
      String weatherId});
}

/// @nodoc
class __$$PokemonMoveEffectSetWeatherImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectSetWeatherImpl>
    implements _$$PokemonMoveEffectSetWeatherImplCopyWith<$Res> {
  __$$PokemonMoveEffectSetWeatherImplCopyWithImpl(
      _$PokemonMoveEffectSetWeatherImpl _value,
      $Res Function(_$PokemonMoveEffectSetWeatherImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? weatherId = null,
  }) {
    return _then(_$PokemonMoveEffectSetWeatherImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      weatherId: null == weatherId
          ? _value.weatherId
          : weatherId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectSetWeatherImpl extends PokemonMoveEffectSetWeather {
  const _$PokemonMoveEffectSetWeatherImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.field,
      this.chance,
      required this.weatherId,
      final String? $type})
      : $type = $type ?? 'set_weather',
        super._();

  factory _$PokemonMoveEffectSetWeatherImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveEffectSetWeatherImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;
  @override
  final String weatherId;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.setWeather(targetScope: $targetScope, chance: $chance, weatherId: $weatherId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectSetWeatherImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            (identical(other.weatherId, weatherId) ||
                other.weatherId == weatherId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, targetScope, chance, weatherId);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectSetWeatherImplCopyWith<_$PokemonMoveEffectSetWeatherImpl>
      get copyWith => __$$PokemonMoveEffectSetWeatherImplCopyWithImpl<
          _$PokemonMoveEffectSetWeatherImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String pseudoWeatherId)
        setPseudoWeather,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return setWeather(targetScope, chance, weatherId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return setWeather?.call(targetScope, chance, weatherId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (setWeather != null) {
      return setWeather(targetScope, chance, weatherId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSetPseudoWeather value)
        setPseudoWeather,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return setWeather(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSetPseudoWeather value)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return setWeather?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSetPseudoWeather value)? setPseudoWeather,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (setWeather != null) {
      return setWeather(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectSetWeatherImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectSetWeather extends PokemonMoveEffect {
  const factory PokemonMoveEffectSetWeather(
      {final PokemonMoveEffectTargetScope targetScope,
      final int? chance,
      required final String weatherId}) = _$PokemonMoveEffectSetWeatherImpl;
  const PokemonMoveEffectSetWeather._() : super._();

  factory PokemonMoveEffectSetWeather.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveEffectSetWeatherImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;
  String get weatherId;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectSetWeatherImplCopyWith<_$PokemonMoveEffectSetWeatherImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectSetTerrainImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectSetTerrainImplCopyWith(
          _$PokemonMoveEffectSetTerrainImpl value,
          $Res Function(_$PokemonMoveEffectSetTerrainImpl) then) =
      __$$PokemonMoveEffectSetTerrainImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope,
      int? chance,
      String terrainId});
}

/// @nodoc
class __$$PokemonMoveEffectSetTerrainImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectSetTerrainImpl>
    implements _$$PokemonMoveEffectSetTerrainImplCopyWith<$Res> {
  __$$PokemonMoveEffectSetTerrainImplCopyWithImpl(
      _$PokemonMoveEffectSetTerrainImpl _value,
      $Res Function(_$PokemonMoveEffectSetTerrainImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? terrainId = null,
  }) {
    return _then(_$PokemonMoveEffectSetTerrainImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      terrainId: null == terrainId
          ? _value.terrainId
          : terrainId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectSetTerrainImpl extends PokemonMoveEffectSetTerrain {
  const _$PokemonMoveEffectSetTerrainImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.field,
      this.chance,
      required this.terrainId,
      final String? $type})
      : $type = $type ?? 'set_terrain',
        super._();

  factory _$PokemonMoveEffectSetTerrainImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveEffectSetTerrainImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;
  @override
  final String terrainId;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.setTerrain(targetScope: $targetScope, chance: $chance, terrainId: $terrainId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectSetTerrainImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            (identical(other.terrainId, terrainId) ||
                other.terrainId == terrainId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, targetScope, chance, terrainId);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectSetTerrainImplCopyWith<_$PokemonMoveEffectSetTerrainImpl>
      get copyWith => __$$PokemonMoveEffectSetTerrainImplCopyWithImpl<
          _$PokemonMoveEffectSetTerrainImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String pseudoWeatherId)
        setPseudoWeather,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return setTerrain(targetScope, chance, terrainId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return setTerrain?.call(targetScope, chance, terrainId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (setTerrain != null) {
      return setTerrain(targetScope, chance, terrainId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSetPseudoWeather value)
        setPseudoWeather,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return setTerrain(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSetPseudoWeather value)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return setTerrain?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSetPseudoWeather value)? setPseudoWeather,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (setTerrain != null) {
      return setTerrain(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectSetTerrainImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectSetTerrain extends PokemonMoveEffect {
  const factory PokemonMoveEffectSetTerrain(
      {final PokemonMoveEffectTargetScope targetScope,
      final int? chance,
      required final String terrainId}) = _$PokemonMoveEffectSetTerrainImpl;
  const PokemonMoveEffectSetTerrain._() : super._();

  factory PokemonMoveEffectSetTerrain.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveEffectSetTerrainImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;
  String get terrainId;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectSetTerrainImplCopyWith<_$PokemonMoveEffectSetTerrainImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectSetPseudoWeatherImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectSetPseudoWeatherImplCopyWith(
          _$PokemonMoveEffectSetPseudoWeatherImpl value,
          $Res Function(_$PokemonMoveEffectSetPseudoWeatherImpl) then) =
      __$$PokemonMoveEffectSetPseudoWeatherImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope,
      int? chance,
      String pseudoWeatherId});
}

/// @nodoc
class __$$PokemonMoveEffectSetPseudoWeatherImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectSetPseudoWeatherImpl>
    implements _$$PokemonMoveEffectSetPseudoWeatherImplCopyWith<$Res> {
  __$$PokemonMoveEffectSetPseudoWeatherImplCopyWithImpl(
      _$PokemonMoveEffectSetPseudoWeatherImpl _value,
      $Res Function(_$PokemonMoveEffectSetPseudoWeatherImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? pseudoWeatherId = null,
  }) {
    return _then(_$PokemonMoveEffectSetPseudoWeatherImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      pseudoWeatherId: null == pseudoWeatherId
          ? _value.pseudoWeatherId
          : pseudoWeatherId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectSetPseudoWeatherImpl
    extends PokemonMoveEffectSetPseudoWeather {
  const _$PokemonMoveEffectSetPseudoWeatherImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.field,
      this.chance,
      required this.pseudoWeatherId,
      final String? $type})
      : $type = $type ?? 'set_pseudo_weather',
        super._();

  factory _$PokemonMoveEffectSetPseudoWeatherImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveEffectSetPseudoWeatherImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;
  @override
  final String pseudoWeatherId;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.setPseudoWeather(targetScope: $targetScope, chance: $chance, pseudoWeatherId: $pseudoWeatherId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectSetPseudoWeatherImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            (identical(other.pseudoWeatherId, pseudoWeatherId) ||
                other.pseudoWeatherId == pseudoWeatherId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, targetScope, chance, pseudoWeatherId);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectSetPseudoWeatherImplCopyWith<
          _$PokemonMoveEffectSetPseudoWeatherImpl>
      get copyWith => __$$PokemonMoveEffectSetPseudoWeatherImplCopyWithImpl<
          _$PokemonMoveEffectSetPseudoWeatherImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String pseudoWeatherId)
        setPseudoWeather,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return setPseudoWeather(targetScope, chance, pseudoWeatherId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return setPseudoWeather?.call(targetScope, chance, pseudoWeatherId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (setPseudoWeather != null) {
      return setPseudoWeather(targetScope, chance, pseudoWeatherId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSetPseudoWeather value)
        setPseudoWeather,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return setPseudoWeather(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSetPseudoWeather value)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return setPseudoWeather?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSetPseudoWeather value)? setPseudoWeather,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (setPseudoWeather != null) {
      return setPseudoWeather(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectSetPseudoWeatherImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectSetPseudoWeather extends PokemonMoveEffect {
  const factory PokemonMoveEffectSetPseudoWeather(
          {final PokemonMoveEffectTargetScope targetScope,
          final int? chance,
          required final String pseudoWeatherId}) =
      _$PokemonMoveEffectSetPseudoWeatherImpl;
  const PokemonMoveEffectSetPseudoWeather._() : super._();

  factory PokemonMoveEffectSetPseudoWeather.fromJson(
          Map<String, dynamic> json) =
      _$PokemonMoveEffectSetPseudoWeatherImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;
  String get pseudoWeatherId;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectSetPseudoWeatherImplCopyWith<
          _$PokemonMoveEffectSetPseudoWeatherImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectSelfSwitchImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectSelfSwitchImplCopyWith(
          _$PokemonMoveEffectSelfSwitchImpl value,
          $Res Function(_$PokemonMoveEffectSelfSwitchImpl) then) =
      __$$PokemonMoveEffectSelfSwitchImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope, int? chance, String? mode});
}

/// @nodoc
class __$$PokemonMoveEffectSelfSwitchImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectSelfSwitchImpl>
    implements _$$PokemonMoveEffectSelfSwitchImplCopyWith<$Res> {
  __$$PokemonMoveEffectSelfSwitchImplCopyWithImpl(
      _$PokemonMoveEffectSelfSwitchImpl _value,
      $Res Function(_$PokemonMoveEffectSelfSwitchImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? mode = freezed,
  }) {
    return _then(_$PokemonMoveEffectSelfSwitchImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      mode: freezed == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectSelfSwitchImpl extends PokemonMoveEffectSelfSwitch {
  const _$PokemonMoveEffectSelfSwitchImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.self,
      this.chance,
      this.mode,
      final String? $type})
      : $type = $type ?? 'self_switch',
        super._();

  factory _$PokemonMoveEffectSelfSwitchImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveEffectSelfSwitchImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;

  /// Exemples futurs : `copyvolatile`, `shedtail`, `simple`.
  @override
  final String? mode;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.selfSwitch(targetScope: $targetScope, chance: $chance, mode: $mode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectSelfSwitchImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            (identical(other.mode, mode) || other.mode == mode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, targetScope, chance, mode);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectSelfSwitchImplCopyWith<_$PokemonMoveEffectSelfSwitchImpl>
      get copyWith => __$$PokemonMoveEffectSelfSwitchImplCopyWithImpl<
          _$PokemonMoveEffectSelfSwitchImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String pseudoWeatherId)
        setPseudoWeather,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return selfSwitch(targetScope, chance, mode);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return selfSwitch?.call(targetScope, chance, mode);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (selfSwitch != null) {
      return selfSwitch(targetScope, chance, mode);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSetPseudoWeather value)
        setPseudoWeather,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return selfSwitch(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSetPseudoWeather value)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return selfSwitch?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSetPseudoWeather value)? setPseudoWeather,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (selfSwitch != null) {
      return selfSwitch(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectSelfSwitchImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectSelfSwitch extends PokemonMoveEffect {
  const factory PokemonMoveEffectSelfSwitch(
      {final PokemonMoveEffectTargetScope targetScope,
      final int? chance,
      final String? mode}) = _$PokemonMoveEffectSelfSwitchImpl;
  const PokemonMoveEffectSelfSwitch._() : super._();

  factory PokemonMoveEffectSelfSwitch.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveEffectSelfSwitchImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;

  /// Exemples futurs : `copyvolatile`, `shedtail`, `simple`.
  String? get mode;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectSelfSwitchImplCopyWith<_$PokemonMoveEffectSelfSwitchImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectForceSwitchImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectForceSwitchImplCopyWith(
          _$PokemonMoveEffectForceSwitchImpl value,
          $Res Function(_$PokemonMoveEffectForceSwitchImpl) then) =
      __$$PokemonMoveEffectForceSwitchImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({PokemonMoveEffectTargetScope targetScope, int? chance});
}

/// @nodoc
class __$$PokemonMoveEffectForceSwitchImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectForceSwitchImpl>
    implements _$$PokemonMoveEffectForceSwitchImplCopyWith<$Res> {
  __$$PokemonMoveEffectForceSwitchImplCopyWithImpl(
      _$PokemonMoveEffectForceSwitchImpl _value,
      $Res Function(_$PokemonMoveEffectForceSwitchImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
  }) {
    return _then(_$PokemonMoveEffectForceSwitchImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectForceSwitchImpl extends PokemonMoveEffectForceSwitch {
  const _$PokemonMoveEffectForceSwitchImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.target,
      this.chance,
      final String? $type})
      : $type = $type ?? 'force_switch',
        super._();

  factory _$PokemonMoveEffectForceSwitchImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveEffectForceSwitchImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.forceSwitch(targetScope: $targetScope, chance: $chance)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectForceSwitchImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, targetScope, chance);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectForceSwitchImplCopyWith<
          _$PokemonMoveEffectForceSwitchImpl>
      get copyWith => __$$PokemonMoveEffectForceSwitchImplCopyWithImpl<
          _$PokemonMoveEffectForceSwitchImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String pseudoWeatherId)
        setPseudoWeather,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return forceSwitch(targetScope, chance);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return forceSwitch?.call(targetScope, chance);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (forceSwitch != null) {
      return forceSwitch(targetScope, chance);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSetPseudoWeather value)
        setPseudoWeather,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return forceSwitch(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSetPseudoWeather value)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return forceSwitch?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSetPseudoWeather value)? setPseudoWeather,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (forceSwitch != null) {
      return forceSwitch(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectForceSwitchImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectForceSwitch extends PokemonMoveEffect {
  const factory PokemonMoveEffectForceSwitch(
      {final PokemonMoveEffectTargetScope targetScope,
      final int? chance}) = _$PokemonMoveEffectForceSwitchImpl;
  const PokemonMoveEffectForceSwitch._() : super._();

  factory PokemonMoveEffectForceSwitch.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveEffectForceSwitchImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectForceSwitchImplCopyWith<
          _$PokemonMoveEffectForceSwitchImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectBreakProtectImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectBreakProtectImplCopyWith(
          _$PokemonMoveEffectBreakProtectImpl value,
          $Res Function(_$PokemonMoveEffectBreakProtectImpl) then) =
      __$$PokemonMoveEffectBreakProtectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({PokemonMoveEffectTargetScope targetScope, int? chance});
}

/// @nodoc
class __$$PokemonMoveEffectBreakProtectImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectBreakProtectImpl>
    implements _$$PokemonMoveEffectBreakProtectImplCopyWith<$Res> {
  __$$PokemonMoveEffectBreakProtectImplCopyWithImpl(
      _$PokemonMoveEffectBreakProtectImpl _value,
      $Res Function(_$PokemonMoveEffectBreakProtectImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
  }) {
    return _then(_$PokemonMoveEffectBreakProtectImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectBreakProtectImpl
    extends PokemonMoveEffectBreakProtect {
  const _$PokemonMoveEffectBreakProtectImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.target,
      this.chance,
      final String? $type})
      : $type = $type ?? 'break_protect',
        super._();

  factory _$PokemonMoveEffectBreakProtectImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveEffectBreakProtectImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.breakProtect(targetScope: $targetScope, chance: $chance)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectBreakProtectImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, targetScope, chance);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectBreakProtectImplCopyWith<
          _$PokemonMoveEffectBreakProtectImpl>
      get copyWith => __$$PokemonMoveEffectBreakProtectImplCopyWithImpl<
          _$PokemonMoveEffectBreakProtectImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String pseudoWeatherId)
        setPseudoWeather,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return breakProtect(targetScope, chance);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return breakProtect?.call(targetScope, chance);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (breakProtect != null) {
      return breakProtect(targetScope, chance);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSetPseudoWeather value)
        setPseudoWeather,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return breakProtect(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSetPseudoWeather value)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return breakProtect?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSetPseudoWeather value)? setPseudoWeather,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (breakProtect != null) {
      return breakProtect(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectBreakProtectImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectBreakProtect extends PokemonMoveEffect {
  const factory PokemonMoveEffectBreakProtect(
      {final PokemonMoveEffectTargetScope targetScope,
      final int? chance}) = _$PokemonMoveEffectBreakProtectImpl;
  const PokemonMoveEffectBreakProtect._() : super._();

  factory PokemonMoveEffectBreakProtect.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveEffectBreakProtectImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectBreakProtectImplCopyWith<
          _$PokemonMoveEffectBreakProtectImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectRequireRechargeImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectRequireRechargeImplCopyWith(
          _$PokemonMoveEffectRequireRechargeImpl value,
          $Res Function(_$PokemonMoveEffectRequireRechargeImpl) then) =
      __$$PokemonMoveEffectRequireRechargeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({PokemonMoveEffectTargetScope targetScope, int? chance});
}

/// @nodoc
class __$$PokemonMoveEffectRequireRechargeImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectRequireRechargeImpl>
    implements _$$PokemonMoveEffectRequireRechargeImplCopyWith<$Res> {
  __$$PokemonMoveEffectRequireRechargeImplCopyWithImpl(
      _$PokemonMoveEffectRequireRechargeImpl _value,
      $Res Function(_$PokemonMoveEffectRequireRechargeImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
  }) {
    return _then(_$PokemonMoveEffectRequireRechargeImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectRequireRechargeImpl
    extends PokemonMoveEffectRequireRecharge {
  const _$PokemonMoveEffectRequireRechargeImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.self,
      this.chance,
      final String? $type})
      : $type = $type ?? 'require_recharge',
        super._();

  factory _$PokemonMoveEffectRequireRechargeImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveEffectRequireRechargeImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.requireRecharge(targetScope: $targetScope, chance: $chance)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectRequireRechargeImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, targetScope, chance);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectRequireRechargeImplCopyWith<
          _$PokemonMoveEffectRequireRechargeImpl>
      get copyWith => __$$PokemonMoveEffectRequireRechargeImplCopyWithImpl<
          _$PokemonMoveEffectRequireRechargeImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String pseudoWeatherId)
        setPseudoWeather,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return requireRecharge(targetScope, chance);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return requireRecharge?.call(targetScope, chance);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (requireRecharge != null) {
      return requireRecharge(targetScope, chance);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSetPseudoWeather value)
        setPseudoWeather,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return requireRecharge(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSetPseudoWeather value)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return requireRecharge?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSetPseudoWeather value)? setPseudoWeather,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (requireRecharge != null) {
      return requireRecharge(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectRequireRechargeImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectRequireRecharge extends PokemonMoveEffect {
  const factory PokemonMoveEffectRequireRecharge(
      {final PokemonMoveEffectTargetScope targetScope,
      final int? chance}) = _$PokemonMoveEffectRequireRechargeImpl;
  const PokemonMoveEffectRequireRecharge._() : super._();

  factory PokemonMoveEffectRequireRecharge.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveEffectRequireRechargeImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectRequireRechargeImplCopyWith<
          _$PokemonMoveEffectRequireRechargeImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectChargeThenStrikeImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectChargeThenStrikeImplCopyWith(
          _$PokemonMoveEffectChargeThenStrikeImpl value,
          $Res Function(_$PokemonMoveEffectChargeThenStrikeImpl) then) =
      __$$PokemonMoveEffectChargeThenStrikeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope,
      int? chance,
      String? chargeStateId});
}

/// @nodoc
class __$$PokemonMoveEffectChargeThenStrikeImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectChargeThenStrikeImpl>
    implements _$$PokemonMoveEffectChargeThenStrikeImplCopyWith<$Res> {
  __$$PokemonMoveEffectChargeThenStrikeImplCopyWithImpl(
      _$PokemonMoveEffectChargeThenStrikeImpl _value,
      $Res Function(_$PokemonMoveEffectChargeThenStrikeImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? chargeStateId = freezed,
  }) {
    return _then(_$PokemonMoveEffectChargeThenStrikeImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      chargeStateId: freezed == chargeStateId
          ? _value.chargeStateId
          : chargeStateId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectChargeThenStrikeImpl
    extends PokemonMoveEffectChargeThenStrike {
  const _$PokemonMoveEffectChargeThenStrikeImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.self,
      this.chance,
      this.chargeStateId,
      final String? $type})
      : $type = $type ?? 'charge_then_strike',
        super._();

  factory _$PokemonMoveEffectChargeThenStrikeImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveEffectChargeThenStrikeImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;

  /// Permet plus tard d'associer un volatile ou un marqueur de charge.
  @override
  final String? chargeStateId;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.chargeThenStrike(targetScope: $targetScope, chance: $chance, chargeStateId: $chargeStateId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectChargeThenStrikeImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            (identical(other.chargeStateId, chargeStateId) ||
                other.chargeStateId == chargeStateId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, targetScope, chance, chargeStateId);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectChargeThenStrikeImplCopyWith<
          _$PokemonMoveEffectChargeThenStrikeImpl>
      get copyWith => __$$PokemonMoveEffectChargeThenStrikeImplCopyWithImpl<
          _$PokemonMoveEffectChargeThenStrikeImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String pseudoWeatherId)
        setPseudoWeather,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return chargeThenStrike(targetScope, chance, chargeStateId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return chargeThenStrike?.call(targetScope, chance, chargeStateId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (chargeThenStrike != null) {
      return chargeThenStrike(targetScope, chance, chargeStateId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSetPseudoWeather value)
        setPseudoWeather,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return chargeThenStrike(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSetPseudoWeather value)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return chargeThenStrike?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSetPseudoWeather value)? setPseudoWeather,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (chargeThenStrike != null) {
      return chargeThenStrike(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectChargeThenStrikeImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectChargeThenStrike extends PokemonMoveEffect {
  const factory PokemonMoveEffectChargeThenStrike(
      {final PokemonMoveEffectTargetScope targetScope,
      final int? chance,
      final String? chargeStateId}) = _$PokemonMoveEffectChargeThenStrikeImpl;
  const PokemonMoveEffectChargeThenStrike._() : super._();

  factory PokemonMoveEffectChargeThenStrike.fromJson(
          Map<String, dynamic> json) =
      _$PokemonMoveEffectChargeThenStrikeImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;

  /// Permet plus tard d'associer un volatile ou un marqueur de charge.
  String? get chargeStateId;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectChargeThenStrikeImplCopyWith<
          _$PokemonMoveEffectChargeThenStrikeImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectSetSideConditionImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectSetSideConditionImplCopyWith(
          _$PokemonMoveEffectSetSideConditionImpl value,
          $Res Function(_$PokemonMoveEffectSetSideConditionImpl) then) =
      __$$PokemonMoveEffectSetSideConditionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope,
      int? chance,
      String conditionId});
}

/// @nodoc
class __$$PokemonMoveEffectSetSideConditionImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectSetSideConditionImpl>
    implements _$$PokemonMoveEffectSetSideConditionImplCopyWith<$Res> {
  __$$PokemonMoveEffectSetSideConditionImplCopyWithImpl(
      _$PokemonMoveEffectSetSideConditionImpl _value,
      $Res Function(_$PokemonMoveEffectSetSideConditionImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? conditionId = null,
  }) {
    return _then(_$PokemonMoveEffectSetSideConditionImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      conditionId: null == conditionId
          ? _value.conditionId
          : conditionId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectSetSideConditionImpl
    extends PokemonMoveEffectSetSideCondition {
  const _$PokemonMoveEffectSetSideConditionImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.foeSide,
      this.chance,
      required this.conditionId,
      final String? $type})
      : $type = $type ?? 'set_side_condition',
        super._();

  factory _$PokemonMoveEffectSetSideConditionImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveEffectSetSideConditionImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;
  @override
  final String conditionId;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.setSideCondition(targetScope: $targetScope, chance: $chance, conditionId: $conditionId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectSetSideConditionImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            (identical(other.conditionId, conditionId) ||
                other.conditionId == conditionId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, targetScope, chance, conditionId);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectSetSideConditionImplCopyWith<
          _$PokemonMoveEffectSetSideConditionImpl>
      get copyWith => __$$PokemonMoveEffectSetSideConditionImplCopyWithImpl<
          _$PokemonMoveEffectSetSideConditionImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String pseudoWeatherId)
        setPseudoWeather,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return setSideCondition(targetScope, chance, conditionId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return setSideCondition?.call(targetScope, chance, conditionId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (setSideCondition != null) {
      return setSideCondition(targetScope, chance, conditionId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSetPseudoWeather value)
        setPseudoWeather,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return setSideCondition(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSetPseudoWeather value)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return setSideCondition?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSetPseudoWeather value)? setPseudoWeather,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (setSideCondition != null) {
      return setSideCondition(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectSetSideConditionImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectSetSideCondition extends PokemonMoveEffect {
  const factory PokemonMoveEffectSetSideCondition(
          {final PokemonMoveEffectTargetScope targetScope,
          final int? chance,
          required final String conditionId}) =
      _$PokemonMoveEffectSetSideConditionImpl;
  const PokemonMoveEffectSetSideCondition._() : super._();

  factory PokemonMoveEffectSetSideCondition.fromJson(
          Map<String, dynamic> json) =
      _$PokemonMoveEffectSetSideConditionImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;
  String get conditionId;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectSetSideConditionImplCopyWith<
          _$PokemonMoveEffectSetSideConditionImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectSetSlotConditionImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectSetSlotConditionImplCopyWith(
          _$PokemonMoveEffectSetSlotConditionImpl value,
          $Res Function(_$PokemonMoveEffectSetSlotConditionImpl) then) =
      __$$PokemonMoveEffectSetSlotConditionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope,
      int? chance,
      String conditionId});
}

/// @nodoc
class __$$PokemonMoveEffectSetSlotConditionImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectSetSlotConditionImpl>
    implements _$$PokemonMoveEffectSetSlotConditionImplCopyWith<$Res> {
  __$$PokemonMoveEffectSetSlotConditionImplCopyWithImpl(
      _$PokemonMoveEffectSetSlotConditionImpl _value,
      $Res Function(_$PokemonMoveEffectSetSlotConditionImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? conditionId = null,
  }) {
    return _then(_$PokemonMoveEffectSetSlotConditionImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      conditionId: null == conditionId
          ? _value.conditionId
          : conditionId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectSetSlotConditionImpl
    extends PokemonMoveEffectSetSlotCondition {
  const _$PokemonMoveEffectSetSlotConditionImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.slot,
      this.chance,
      required this.conditionId,
      final String? $type})
      : $type = $type ?? 'set_slot_condition',
        super._();

  factory _$PokemonMoveEffectSetSlotConditionImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveEffectSetSlotConditionImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;
  @override
  final String conditionId;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.setSlotCondition(targetScope: $targetScope, chance: $chance, conditionId: $conditionId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectSetSlotConditionImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            (identical(other.conditionId, conditionId) ||
                other.conditionId == conditionId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, targetScope, chance, conditionId);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectSetSlotConditionImplCopyWith<
          _$PokemonMoveEffectSetSlotConditionImpl>
      get copyWith => __$$PokemonMoveEffectSetSlotConditionImplCopyWithImpl<
          _$PokemonMoveEffectSetSlotConditionImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String pseudoWeatherId)
        setPseudoWeather,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return setSlotCondition(targetScope, chance, conditionId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return setSlotCondition?.call(targetScope, chance, conditionId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String pseudoWeatherId)?
        setPseudoWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (setSlotCondition != null) {
      return setSlotCondition(targetScope, chance, conditionId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSetPseudoWeather value)
        setPseudoWeather,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return setSlotCondition(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSetPseudoWeather value)?
        setPseudoWeather,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return setSlotCondition?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSetPseudoWeather value)? setPseudoWeather,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (setSlotCondition != null) {
      return setSlotCondition(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectSetSlotConditionImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectSetSlotCondition extends PokemonMoveEffect {
  const factory PokemonMoveEffectSetSlotCondition(
          {final PokemonMoveEffectTargetScope targetScope,
          final int? chance,
          required final String conditionId}) =
      _$PokemonMoveEffectSetSlotConditionImpl;
  const PokemonMoveEffectSetSlotCondition._() : super._();

  factory PokemonMoveEffectSetSlotCondition.fromJson(
          Map<String, dynamic> json) =
      _$PokemonMoveEffectSetSlotConditionImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;
  String get conditionId;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectSetSlotConditionImplCopyWith<
          _$PokemonMoveEffectSetSlotConditionImpl>
      get copyWith => throw _privateConstructorUsedError;
}

```

### `packages/map_core/lib/src/models/pokemon_move_effect.g.dart`

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pokemon_move_effect.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PokemonMoveStatStageChangeImpl _$$PokemonMoveStatStageChangeImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonMoveStatStageChangeImpl(
      stat: $enumDecode(_$PokemonMoveStatIdEnumMap, json['stat']),
      stages: (json['stages'] as num).toInt(),
    );

Map<String, dynamic> _$$PokemonMoveStatStageChangeImplToJson(
        _$PokemonMoveStatStageChangeImpl instance) =>
    <String, dynamic>{
      'stat': _$PokemonMoveStatIdEnumMap[instance.stat]!,
      'stages': instance.stages,
    };

const _$PokemonMoveStatIdEnumMap = {
  PokemonMoveStatId.attack: 'attack',
  PokemonMoveStatId.defense: 'defense',
  PokemonMoveStatId.specialAttack: 'special_attack',
  PokemonMoveStatId.specialDefense: 'special_defense',
  PokemonMoveStatId.speed: 'speed',
  PokemonMoveStatId.accuracy: 'accuracy',
  PokemonMoveStatId.evasion: 'evasion',
};

_$PokemonMoveEffectFixedDamageImpl _$$PokemonMoveEffectFixedDamageImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonMoveEffectFixedDamageImpl(
      targetScope: $enumDecodeNullable(
              _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
          PokemonMoveEffectTargetScope.target,
      chance: (json['chance'] as num?)?.toInt(),
      value: (json['value'] as num?)?.toInt(),
      usesUserLevel: json['usesUserLevel'] as bool? ?? false,
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$PokemonMoveEffectFixedDamageImplToJson(
        _$PokemonMoveEffectFixedDamageImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'value': instance.value,
      'usesUserLevel': instance.usesUserLevel,
      'kind': instance.$type,
    };

const _$PokemonMoveEffectTargetScopeEnumMap = {
  PokemonMoveEffectTargetScope.self: 'self',
  PokemonMoveEffectTargetScope.target: 'target',
  PokemonMoveEffectTargetScope.field: 'field',
  PokemonMoveEffectTargetScope.allySide: 'ally_side',
  PokemonMoveEffectTargetScope.foeSide: 'foe_side',
  PokemonMoveEffectTargetScope.slot: 'slot',
};

_$PokemonMoveEffectMultiHitImpl _$$PokemonMoveEffectMultiHitImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonMoveEffectMultiHitImpl(
      targetScope: $enumDecodeNullable(
              _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
          PokemonMoveEffectTargetScope.target,
      chance: (json['chance'] as num?)?.toInt(),
      minHits: (json['minHits'] as num).toInt(),
      maxHits: (json['maxHits'] as num).toInt(),
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$PokemonMoveEffectMultiHitImplToJson(
        _$PokemonMoveEffectMultiHitImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'minHits': instance.minHits,
      'maxHits': instance.maxHits,
      'kind': instance.$type,
    };

_$PokemonMoveEffectApplyStatusImpl _$$PokemonMoveEffectApplyStatusImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonMoveEffectApplyStatusImpl(
      targetScope: $enumDecodeNullable(
              _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
          PokemonMoveEffectTargetScope.target,
      chance: (json['chance'] as num?)?.toInt(),
      statusId: json['statusId'] as String,
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$PokemonMoveEffectApplyStatusImplToJson(
        _$PokemonMoveEffectApplyStatusImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'statusId': instance.statusId,
      'kind': instance.$type,
    };

_$PokemonMoveEffectApplyVolatileStatusImpl
    _$$PokemonMoveEffectApplyVolatileStatusImplFromJson(
            Map<String, dynamic> json) =>
        _$PokemonMoveEffectApplyVolatileStatusImpl(
          targetScope: $enumDecodeNullable(
                  _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
              PokemonMoveEffectTargetScope.target,
          chance: (json['chance'] as num?)?.toInt(),
          volatileStatusId: json['volatileStatusId'] as String,
          $type: json['kind'] as String?,
        );

Map<String, dynamic> _$$PokemonMoveEffectApplyVolatileStatusImplToJson(
        _$PokemonMoveEffectApplyVolatileStatusImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'volatileStatusId': instance.volatileStatusId,
      'kind': instance.$type,
    };

_$PokemonMoveEffectModifyStatsImpl _$$PokemonMoveEffectModifyStatsImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonMoveEffectModifyStatsImpl(
      targetScope: $enumDecodeNullable(
              _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
          PokemonMoveEffectTargetScope.target,
      chance: (json['chance'] as num?)?.toInt(),
      stageChanges: (json['stageChanges'] as List<dynamic>?)
              ?.map((e) => PokemonMoveStatStageChange.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const <PokemonMoveStatStageChange>[],
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$PokemonMoveEffectModifyStatsImplToJson(
        _$PokemonMoveEffectModifyStatsImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'stageChanges': instance.stageChanges.map((e) => e.toJson()).toList(),
      'kind': instance.$type,
    };

_$PokemonMoveEffectHealImpl _$$PokemonMoveEffectHealImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonMoveEffectHealImpl(
      targetScope: $enumDecodeNullable(
              _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
          PokemonMoveEffectTargetScope.self,
      chance: (json['chance'] as num?)?.toInt(),
      numerator: (json['numerator'] as num).toInt(),
      denominator: (json['denominator'] as num).toInt(),
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$PokemonMoveEffectHealImplToJson(
        _$PokemonMoveEffectHealImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'numerator': instance.numerator,
      'denominator': instance.denominator,
      'kind': instance.$type,
    };

_$PokemonMoveEffectDrainImpl _$$PokemonMoveEffectDrainImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonMoveEffectDrainImpl(
      targetScope: $enumDecodeNullable(
              _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
          PokemonMoveEffectTargetScope.self,
      chance: (json['chance'] as num?)?.toInt(),
      numerator: (json['numerator'] as num).toInt(),
      denominator: (json['denominator'] as num).toInt(),
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$PokemonMoveEffectDrainImplToJson(
        _$PokemonMoveEffectDrainImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'numerator': instance.numerator,
      'denominator': instance.denominator,
      'kind': instance.$type,
    };

_$PokemonMoveEffectRecoilImpl _$$PokemonMoveEffectRecoilImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonMoveEffectRecoilImpl(
      targetScope: $enumDecodeNullable(
              _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
          PokemonMoveEffectTargetScope.self,
      chance: (json['chance'] as num?)?.toInt(),
      numerator: (json['numerator'] as num).toInt(),
      denominator: (json['denominator'] as num).toInt(),
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$PokemonMoveEffectRecoilImplToJson(
        _$PokemonMoveEffectRecoilImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'numerator': instance.numerator,
      'denominator': instance.denominator,
      'kind': instance.$type,
    };

_$PokemonMoveEffectSetWeatherImpl _$$PokemonMoveEffectSetWeatherImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonMoveEffectSetWeatherImpl(
      targetScope: $enumDecodeNullable(
              _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
          PokemonMoveEffectTargetScope.field,
      chance: (json['chance'] as num?)?.toInt(),
      weatherId: json['weatherId'] as String,
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$PokemonMoveEffectSetWeatherImplToJson(
        _$PokemonMoveEffectSetWeatherImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'weatherId': instance.weatherId,
      'kind': instance.$type,
    };

_$PokemonMoveEffectSetTerrainImpl _$$PokemonMoveEffectSetTerrainImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonMoveEffectSetTerrainImpl(
      targetScope: $enumDecodeNullable(
              _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
          PokemonMoveEffectTargetScope.field,
      chance: (json['chance'] as num?)?.toInt(),
      terrainId: json['terrainId'] as String,
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$PokemonMoveEffectSetTerrainImplToJson(
        _$PokemonMoveEffectSetTerrainImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'terrainId': instance.terrainId,
      'kind': instance.$type,
    };

_$PokemonMoveEffectSetPseudoWeatherImpl
    _$$PokemonMoveEffectSetPseudoWeatherImplFromJson(
            Map<String, dynamic> json) =>
        _$PokemonMoveEffectSetPseudoWeatherImpl(
          targetScope: $enumDecodeNullable(
                  _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
              PokemonMoveEffectTargetScope.field,
          chance: (json['chance'] as num?)?.toInt(),
          pseudoWeatherId: json['pseudoWeatherId'] as String,
          $type: json['kind'] as String?,
        );

Map<String, dynamic> _$$PokemonMoveEffectSetPseudoWeatherImplToJson(
        _$PokemonMoveEffectSetPseudoWeatherImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'pseudoWeatherId': instance.pseudoWeatherId,
      'kind': instance.$type,
    };

_$PokemonMoveEffectSelfSwitchImpl _$$PokemonMoveEffectSelfSwitchImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonMoveEffectSelfSwitchImpl(
      targetScope: $enumDecodeNullable(
              _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
          PokemonMoveEffectTargetScope.self,
      chance: (json['chance'] as num?)?.toInt(),
      mode: json['mode'] as String?,
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$PokemonMoveEffectSelfSwitchImplToJson(
        _$PokemonMoveEffectSelfSwitchImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'mode': instance.mode,
      'kind': instance.$type,
    };

_$PokemonMoveEffectForceSwitchImpl _$$PokemonMoveEffectForceSwitchImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonMoveEffectForceSwitchImpl(
      targetScope: $enumDecodeNullable(
              _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
          PokemonMoveEffectTargetScope.target,
      chance: (json['chance'] as num?)?.toInt(),
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$PokemonMoveEffectForceSwitchImplToJson(
        _$PokemonMoveEffectForceSwitchImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'kind': instance.$type,
    };

_$PokemonMoveEffectBreakProtectImpl
    _$$PokemonMoveEffectBreakProtectImplFromJson(Map<String, dynamic> json) =>
        _$PokemonMoveEffectBreakProtectImpl(
          targetScope: $enumDecodeNullable(
                  _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
              PokemonMoveEffectTargetScope.target,
          chance: (json['chance'] as num?)?.toInt(),
          $type: json['kind'] as String?,
        );

Map<String, dynamic> _$$PokemonMoveEffectBreakProtectImplToJson(
        _$PokemonMoveEffectBreakProtectImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'kind': instance.$type,
    };

_$PokemonMoveEffectRequireRechargeImpl
    _$$PokemonMoveEffectRequireRechargeImplFromJson(
            Map<String, dynamic> json) =>
        _$PokemonMoveEffectRequireRechargeImpl(
          targetScope: $enumDecodeNullable(
                  _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
              PokemonMoveEffectTargetScope.self,
          chance: (json['chance'] as num?)?.toInt(),
          $type: json['kind'] as String?,
        );

Map<String, dynamic> _$$PokemonMoveEffectRequireRechargeImplToJson(
        _$PokemonMoveEffectRequireRechargeImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'kind': instance.$type,
    };

_$PokemonMoveEffectChargeThenStrikeImpl
    _$$PokemonMoveEffectChargeThenStrikeImplFromJson(
            Map<String, dynamic> json) =>
        _$PokemonMoveEffectChargeThenStrikeImpl(
          targetScope: $enumDecodeNullable(
                  _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
              PokemonMoveEffectTargetScope.self,
          chance: (json['chance'] as num?)?.toInt(),
          chargeStateId: json['chargeStateId'] as String?,
          $type: json['kind'] as String?,
        );

Map<String, dynamic> _$$PokemonMoveEffectChargeThenStrikeImplToJson(
        _$PokemonMoveEffectChargeThenStrikeImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'chargeStateId': instance.chargeStateId,
      'kind': instance.$type,
    };

_$PokemonMoveEffectSetSideConditionImpl
    _$$PokemonMoveEffectSetSideConditionImplFromJson(
            Map<String, dynamic> json) =>
        _$PokemonMoveEffectSetSideConditionImpl(
          targetScope: $enumDecodeNullable(
                  _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
              PokemonMoveEffectTargetScope.foeSide,
          chance: (json['chance'] as num?)?.toInt(),
          conditionId: json['conditionId'] as String,
          $type: json['kind'] as String?,
        );

Map<String, dynamic> _$$PokemonMoveEffectSetSideConditionImplToJson(
        _$PokemonMoveEffectSetSideConditionImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'conditionId': instance.conditionId,
      'kind': instance.$type,
    };

_$PokemonMoveEffectSetSlotConditionImpl
    _$$PokemonMoveEffectSetSlotConditionImplFromJson(
            Map<String, dynamic> json) =>
        _$PokemonMoveEffectSetSlotConditionImpl(
          targetScope: $enumDecodeNullable(
                  _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
              PokemonMoveEffectTargetScope.slot,
          chance: (json['chance'] as num?)?.toInt(),
          conditionId: json['conditionId'] as String,
          $type: json['kind'] as String?,
        );

Map<String, dynamic> _$$PokemonMoveEffectSetSlotConditionImplToJson(
        _$PokemonMoveEffectSetSlotConditionImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'conditionId': instance.conditionId,
      'kind': instance.$type,
    };

```

### `packages/map_core/test/pokemon_move_test.dart`

```dart
import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

PokemonMove _roundTrip(PokemonMove move) {
  final encoded = jsonEncode(move.toJson());
  final decoded = jsonDecode(encoded) as Map<String, dynamic>;
  return PokemonMove.fromJson(decoded);
}

void main() {
  group('PokemonMove', () {
    test('round-trip JSON for a simple damage move', () {
      const move = PokemonMove(
        id: 'thunderbolt',
        name: 'Thunderbolt',
        names: {'en': 'Thunderbolt', 'fr': 'Tonnerre'},
        generation: 1,
        source: 'showdown',
        type: 'electric',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 90,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 15,
        priority: 0,
        flags: [
          PokemonMoveFlag.protect,
          PokemonMoveFlag.mirror,
        ],
        shortDescription: '10% chance to paralyze the target.',
        description: 'A strong electric blast crashes down on the target.',
      );

      expect(_roundTrip(move), move);
      expect(move.usesStandardDamageFlow, isTrue);
    });

    test('round-trip JSON for a move with a secondary status effect', () {
      const move = PokemonMove(
        id: 'thunderbolt',
        name: 'Thunderbolt',
        source: 'showdown',
        type: 'electric',
        category: PokemonMoveCategory.special,
        basePower: 90,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 15,
        effects: [
          PokemonMoveEffect.applyStatus(
            chance: 10,
            statusId: 'par',
          ),
        ],
      );

      expect(_roundTrip(move), move);
    });

    test('round-trip JSON for a move with drain', () {
      const move = PokemonMove(
        id: 'absorb',
        name: 'Absorb',
        source: 'showdown',
        type: 'grass',
        category: PokemonMoveCategory.special,
        basePower: 20,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 25,
        effects: [
          PokemonMoveEffect.drain(
            numerator: 1,
            denominator: 2,
          ),
        ],
      );

      expect(_roundTrip(move), move);
    });

    test('round-trip JSON for a multi-hit move', () {
      const move = PokemonMove(
        id: 'double-slap',
        name: 'Double Slap',
        source: 'showdown',
        type: 'normal',
        category: PokemonMoveCategory.physical,
        basePower: 15,
        accuracy: PokemonMoveAccuracy.percent(value: 85),
        pp: 10,
        effects: [
          PokemonMoveEffect.multiHit(
            minHits: 2,
            maxHits: 5,
          ),
        ],
      );

      expect(_roundTrip(move), move);
    });

    test('round-trip JSON keeps engine support metadata', () {
      const move = PokemonMove(
        id: 'acrobatics',
        name: 'Acrobatics',
        source: 'showdown',
        type: 'flying',
        category: PokemonMoveCategory.physical,
        basePower: 55,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 15,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
        unsupportedReasons: ['showdown_callback:basePowerCallback'],
        sourceRefs: PokemonMoveSourceRefs(
          showdownMoveId: 'acrobatics',
          showdownHooksPresent: ['basePowerCallback'],
        ),
      );

      expect(_roundTrip(move), move);
    });

    test('deserialization works when optional fields are absent', () {
      final restored = PokemonMove.fromJson({
        'id': 'swift',
        'name': 'Swift',
        'type': 'normal',
        'category': 'special',
        'accuracy': {
          'kind': 'always_hits',
        },
        'pp': 20,
      });

      expect(restored.id, 'swift');
      expect(restored.names, isEmpty);
      expect(restored.target, PokemonMoveTarget.normal);
      expect(restored.basePower, 0);
      expect(restored.flags, isEmpty);
      expect(restored.effects, isEmpty);
      expect(
        restored.engineSupportLevel,
        PokemonMoveEngineSupportLevel.catalogOnly,
      );
      expect(restored.sourceRefs.showdownMoveId, isNull);
    });

    test('fromJson enforces normalization for blank ids', () {
      expect(
        () => PokemonMove.fromJson({
          'id': '   ',
          'name': 'Swift',
          'type': 'normal',
          'category': 'special',
          'accuracy': {
            'kind': 'always_hits',
          },
        }),
        throwsStateError,
      );
    });

    test('can represent a move with stat changes and recoil', () {
      const move = PokemonMove(
        id: 'close-combat-plus',
        name: 'Close Combat Plus',
        source: 'test',
        type: 'fighting',
        category: PokemonMoveCategory.physical,
        basePower: 120,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 5,
        effects: [
          PokemonMoveEffect.modifyStats(
            targetScope: PokemonMoveEffectTargetScope.self,
            stageChanges: [
              PokemonMoveStatStageChange(
                stat: PokemonMoveStatId.defense,
                stages: -1,
              ),
              PokemonMoveStatStageChange(
                stat: PokemonMoveStatId.specialDefense,
                stages: -1,
              ),
            ],
          ),
          PokemonMoveEffect.recoil(
            numerator: 1,
            denominator: 3,
          ),
        ],
      );

      expect(_roundTrip(move), move);
    });

    test('normalized trims ids and dedupes flags and unsupported reasons', () {
      const move = PokemonMove(
        id: '  thunderbolt  ',
        name: '  Thunderbolt  ',
        names: {
          ' fr ': ' Tonnerre ',
          'en': ' Thunderbolt ',
          '': 'ignored',
        },
        source: ' showdown ',
        type: ' electric ',
        category: PokemonMoveCategory.special,
        basePower: 90,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        flags: [
          PokemonMoveFlag.protect,
          PokemonMoveFlag.protect,
          PokemonMoveFlag.mirror,
        ],
        unsupportedReasons: [
          ' showdown_callback:onHit ',
          'showdown_callback:onHit',
          '   ',
        ],
        sourceRefs: PokemonMoveSourceRefs(
          showdownMoveId: ' thunderbolt ',
          showdownHooksPresent: [
            ' onHit ',
            'onHit',
            '  ',
          ],
        ),
      );

      final normalized = move.normalized();

      expect(normalized.id, 'thunderbolt');
      expect(normalized.name, 'Thunderbolt');
      expect(normalized.names, {
        'en': 'Thunderbolt',
        'fr': 'Tonnerre',
      });
      expect(normalized.source, 'showdown');
      expect(normalized.type, 'electric');
      expect(normalized.flags, [
        PokemonMoveFlag.protect,
        PokemonMoveFlag.mirror,
      ]);
      expect(normalized.unsupportedReasons, ['showdown_callback:onHit']);
      expect(normalized.sourceRefs.showdownMoveId, 'thunderbolt');
      expect(normalized.sourceRefs.showdownHooksPresent, ['onHit']);
    });

    test('normalized rejects blank id', () {
      const move = PokemonMove(
        id: '   ',
        name: 'Move',
        type: 'normal',
        category: PokemonMoveCategory.status,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
      );

      expect(() => move.normalized(), throwsStateError);
    });

    test('normalized rejects blank name', () {
      const move = PokemonMove(
        id: 'move',
        name: '   ',
        type: 'normal',
        category: PokemonMoveCategory.status,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
      );

      expect(() => move.normalized(), throwsStateError);
    });
  });

  group('PokemonMoveAccuracy', () {
    test('serializes percent accuracy', () {
      const accuracy = PokemonMoveAccuracy.percent(value: 85);

      expect(
        PokemonMoveAccuracy.fromJson(accuracy.toJson()),
        accuracy,
      );
    });

    test('serializes always hits accuracy', () {
      const accuracy = PokemonMoveAccuracy.alwaysHits();

      expect(
        PokemonMoveAccuracy.fromJson(accuracy.toJson()),
        accuracy,
      );
    });

    test('normalized rejects out-of-range percent accuracy', () {
      const accuracy = PokemonMoveAccuracy.percent(value: 101);

      expect(() => accuracy.normalized(), throwsStateError);
    });

    test('fromJson rejects out-of-range percent accuracy', () {
      expect(
        () => PokemonMoveAccuracy.fromJson({
          'kind': 'percent',
          'value': 101,
        }),
        throwsStateError,
      );
    });
  });

  group('PokemonMoveEffect', () {
    PokemonMoveEffect roundTripEffect(PokemonMoveEffect effect) {
      final encoded = jsonEncode(effect.toJson());
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      return PokemonMoveEffect.fromJson(decoded);
    }

    test('round-trip JSON for fixed damage', () {
      const effect = PokemonMoveEffect.fixedDamage(value: 40);
      expect(roundTripEffect(effect), effect);
    });

    test('round-trip JSON for setWeather', () {
      const effect = PokemonMoveEffect.setWeather(weatherId: 'rain-dance');
      expect(roundTripEffect(effect), effect);
    });

    test('round-trip JSON for setTerrain', () {
      const effect =
          PokemonMoveEffect.setTerrain(terrainId: 'electric-terrain');
      expect(roundTripEffect(effect), effect);
    });

    test('round-trip JSON for setPseudoWeather', () {
      const effect =
          PokemonMoveEffect.setPseudoWeather(pseudoWeatherId: 'trick-room');
      expect(roundTripEffect(effect), effect);
    });

    test('round-trip JSON for setSideCondition', () {
      const effect = PokemonMoveEffect.setSideCondition(conditionId: 'spikes');
      expect(roundTripEffect(effect), effect);
    });

    test('round-trip JSON for setSlotCondition', () {
      const effect =
          PokemonMoveEffect.setSlotCondition(conditionId: 'futuremove');
      expect(roundTripEffect(effect), effect);
    });

    test('round-trip JSON for forceSwitch', () {
      const effect = PokemonMoveEffect.forceSwitch();
      expect(roundTripEffect(effect), effect);
    });

    test('round-trip JSON for requireRecharge', () {
      const effect = PokemonMoveEffect.requireRecharge();
      expect(roundTripEffect(effect), effect);
    });

    test('round-trip JSON for chargeThenStrike', () {
      const effect = PokemonMoveEffect.chargeThenStrike(
        chargeStateId: 'solar-beam-charge',
      );
      expect(roundTripEffect(effect), effect);
    });

    test('normalized rejects invalid multiHit range', () {
      const effect = PokemonMoveEffect.multiHit(
        minHits: 5,
        maxHits: 2,
      );

      expect(() => effect.normalized(), throwsStateError);
    });

    test('fromJson rejects invalid multiHit range', () {
      expect(
        () => PokemonMoveEffect.fromJson({
          'kind': 'multi_hit',
          'targetScope': 'target',
          'minHits': 5,
          'maxHits': 2,
        }),
        throwsStateError,
      );
    });
  });
}

```
