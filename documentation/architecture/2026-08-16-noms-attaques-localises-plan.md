# Noms d'attaques localisés — plan d'implémentation

> **Pour les agents :** SOUS-SKILL REQUISE — utiliser `superpowers:subagent-driven-development`
> (recommandé) ou `superpowers:executing-plans` pour exécuter ce plan tâche par tâche. Les étapes
> utilisent la syntaxe `- [ ]` pour le suivi.

**Objectif :** afficher les noms d'attaques en français dans le jeu et dans l'éditeur, à partir
d'une table de traductions versionnée, sans faire entrer la notion de langue dans le domaine
battle.

**Architecture :** un outil hors ligne interroge PokeAPI et génère une table Dart versionnée. Cette
table alimente en écriture le converter Showdown et le seed bootstrap, qui remplissent la map
`names` du catalogue projet. À la lecture, `map_core` résout `names[locale]` avec repli sur `name`,
et la couche présentation applique cette résolution — le domaine `map_battle` reste intact.

**Stack :** Dart / Flutter, `package:test` (map_core, map_editor), `package:flutter_test`
(map_runtime, map_player_ui), `package:http`, PokeAPI v2, snapshot Pokémon Showdown.

**Design de référence :** `documentation/architecture/2026-08-16-noms-attaques-localises-design.md`

## Contraintes globales

- **Français uniquement livré**, mais aucune structure ne doit coder `fr` en dur : la map `names`
  reste `Map<String, String>` ouverte à toute langue.
- **Le domaine `map_battle` ne doit pas être modifié.** Aucun import de `map_core` ne doit y être
  ajouté, aucune notion de langue ne doit y entrer.
- **Aucune dépendance réseau ne doit être introduite en production.** Seul le `tool/` parle à
  PokeAPI.
- **Le seed bootstrap ne doit acquérir ni `rootBundle` ni accès réseau** (contrainte inscrite dans
  son propre en-tête).
- **`name` reste l'anglais canonique.** Il ne doit jamais recevoir une valeur traduite : c'est la
  clé utilisée par le pont battle et les logs.
- **Commits chirurgicaux, fichier par fichier.** Une autre session travaille dans le même arbre ;
  `git add -A` est proscrit.
- Travailler sur `main`, sans créer de branche ni de worktree, et sans `git push`.

---

## Structure des fichiers

| Fichier | Responsabilité | Action |
|---|---|---|
| `packages/map_core/lib/src/localization/localized_names.dart` | Résolution `names[locale] → fallback` | Créer |
| `packages/map_core/lib/map_core.dart` | Export du nouveau fichier | Modifier |
| `packages/map_core/lib/src/models/pokemon_move.dart` | Méthode `displayName(locale)` | Modifier |
| `packages/map_core/test/localized_names_test.dart` | Tests de résolution | Créer |
| `packages/map_editor/lib/src/application/services/pokemon_move_local_id.dart` | Normalisation d'id partagée | Créer |
| `packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart` | Utilise la normalisation extraite, enrichit `names` | Modifier |
| `packages/map_editor/lib/src/application/seeds/pokemon_move_localized_names.dart` | Table générée | Créer (généré) |
| `packages/map_editor/tool/generate_pokemon_move_localized_names.dart` | Génération hors ligne | Créer |
| `packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart` | Seed enrichi | Modifier |
| `packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart` | Applique le resolver | Modifier |
| `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart` | Transporte le resolver | Modifier |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | Construit le resolver | Modifier |
| `packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart` | `names` dans la vue projetée | Modifier |
| `packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace/moves_catalog_workspace.dart` | Affichage, recherche, badge | Modifier |

---

## Task 1 : résolution des noms localisés dans `map_core`

**Fichiers :**
- Créer : `packages/map_core/lib/src/localization/localized_names.dart`
- Modifier : `packages/map_core/lib/map_core.dart`
- Modifier : `packages/map_core/lib/src/models/pokemon_move.dart`
- Test : `packages/map_core/test/localized_names_test.dart`

**Interfaces :**
- Consomme : rien.
- Produit :
  - `String resolveLocalizedName({required Map<String, String> names, required String locale, required String fallback})`
  - `PokemonMove.displayName(String locale) → String`

Ces deux signatures sont utilisées telles quelles par les tâches 4, 5 et 6.

- [ ] **Étape 1 : écrire le test qui échoue**

Créer `packages/map_core/test/localized_names_test.dart` :

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('resolveLocalizedName', () {
    const names = <String, String>{'en': 'Thunderbolt', 'fr': 'Tonnerre'};

    test('returns the exact locale match', () {
      expect(
        resolveLocalizedName(names: names, locale: 'fr', fallback: 'X'),
        'Tonnerre',
      );
    });

    test('falls back to the language code of a regional locale', () {
      expect(
        resolveLocalizedName(names: names, locale: 'fr-CA', fallback: 'X'),
        'Tonnerre',
      );
    });

    test('normalizes underscore separators and casing', () {
      expect(
        resolveLocalizedName(names: names, locale: 'FR_ca', fallback: 'X'),
        'Tonnerre',
      );
    });

    test('returns the fallback for an unknown locale', () {
      expect(
        resolveLocalizedName(names: names, locale: 'de', fallback: 'X'),
        'X',
      );
    });

    test('returns the fallback for an empty map', () {
      expect(
        resolveLocalizedName(
          names: const <String, String>{},
          locale: 'fr',
          fallback: 'X',
        ),
        'X',
      );
    });

    test('ignores a blank translation and returns the fallback', () {
      expect(
        resolveLocalizedName(
          names: const <String, String>{'fr': '   '},
          locale: 'fr',
          fallback: 'X',
        ),
        'X',
      );
    });

    test('returns the fallback for a malformed locale', () {
      expect(
        resolveLocalizedName(names: names, locale: '', fallback: 'X'),
        'X',
      );
    });
  });

  group('PokemonMove.displayName', () {
    test('prefers the localized name over the canonical name', () {
      final move = _move(
        name: 'Thunderbolt',
        names: const <String, String>{'en': 'Thunderbolt', 'fr': 'Tonnerre'},
      );
      expect(move.displayName('fr'), 'Tonnerre');
    });

    test('falls back to the canonical name when the locale is missing', () {
      final move = _move(
        name: 'Thunderbolt',
        names: const <String, String>{'en': 'Thunderbolt'},
      );
      expect(move.displayName('fr'), 'Thunderbolt');
    });
  });
}

PokemonMove _move({
  required String name,
  required Map<String, String> names,
}) {
  return PokemonMove(
    id: 'thunderbolt',
    name: name,
    names: names,
    type: 'electric',
    category: PokemonMoveCategory.special,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
  );
}
```

- [ ] **Étape 2 : lancer le test pour vérifier qu'il échoue**

```bash
cd packages/map_core && dart test test/localized_names_test.dart
```

Attendu : ÉCHEC à la compilation, `resolveLocalizedName` et `displayName` non définis.

- [ ] **Étape 3 : implémenter la résolution**

Créer `packages/map_core/lib/src/localization/localized_names.dart` :

```dart
/// Résout un nom localisé depuis une map de traductions.
///
/// La sémantique reprend celle déjà retenue par `SceneLocalizedText.resolve` :
/// correspondance exacte, puis code langue, puis repli. Une traduction vide est
/// traitée comme absente afin qu'une entrée mal renseignée n'efface jamais un
/// libellé affichable.
String resolveLocalizedName({
  required Map<String, String> names,
  required String locale,
  required String fallback,
}) {
  final normalized = locale.trim().replaceAll('_', '-').toLowerCase();
  if (normalized.isEmpty) {
    return fallback;
  }

  final exact = names[normalized];
  if (exact != null && exact.trim().isNotEmpty) {
    return exact;
  }

  final separator = normalized.indexOf('-');
  if (separator > 0) {
    final language = names[normalized.substring(0, separator)];
    if (language != null && language.trim().isNotEmpty) {
      return language;
    }
  }

  return fallback;
}
```

- [ ] **Étape 4 : exporter le fichier**

Dans `packages/map_core/lib/map_core.dart`, après la ligne 8 :

```dart
export 'src/localization/localized_names.dart';
```

- [ ] **Étape 5 : ajouter `displayName` au modèle**

Dans `packages/map_core/lib/src/models/pokemon_move.dart`, ajouter l'import en tête de fichier :

```dart
import '../localization/localized_names.dart';
```

Puis, dans le corps de `abstract class PokemonMove` (qui dispose déjà de `const PokemonMove._()`),
après le constructeur factory :

```dart
  /// Libellé affichable pour une locale donnée.
  ///
  /// `name` reste l'anglais canonique et sert de repli : il ne doit jamais être
  /// remplacé par une traduction.
  String displayName(String locale) => resolveLocalizedName(
        names: names,
        locale: locale,
        fallback: name,
      );
```

- [ ] **Étape 6 : lancer le test pour vérifier qu'il passe**

```bash
cd packages/map_core && dart test test/localized_names_test.dart
```

Attendu : SUCCÈS, 9 tests.

- [ ] **Étape 7 : vérifier l'absence de régression sur le modèle**

```bash
cd packages/map_core && dart test test/ --name pokemon_move
```

Attendu : SUCCÈS. Aucun test existant ne doit changer de comportement.

- [ ] **Étape 8 : analyse statique**

```bash
cd packages/map_core && dart analyze lib/src/localization/ lib/src/models/pokemon_move.dart
```

Attendu : `No issues found!`

- [ ] **Étape 9 : commit**

```bash
git add packages/map_core/lib/src/localization/localized_names.dart packages/map_core/lib/map_core.dart packages/map_core/lib/src/models/pokemon_move.dart packages/map_core/test/localized_names_test.dart && git commit -m "feat(core): résoudre un nom d'attaque selon la locale"
```

---

## Task 2 : extraire la normalisation d'identifiant de move

Refactor pur, sans changement de comportement. Il est indispensable : le tool de la tâche 3 doit
normaliser **exactement** comme le converter, sinon la table ne peut pas être indexée de façon
fiable.

**Fichiers :**
- Créer : `packages/map_editor/lib/src/application/services/pokemon_move_local_id.dart`
- Modifier : `packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart:1252-1262`
- Test : `packages/map_editor/test/pokemon_move_local_id_test.dart`

**Interfaces :**
- Consomme : rien.
- Produit : `String normalizePokemonMoveLocalId(String rawValue)` — fonction de niveau supérieur,
  utilisée par la tâche 3 et par le converter.

- [ ] **Étape 1 : écrire le test qui échoue**

Créer `packages/map_editor/test/pokemon_move_local_id_test.dart` :

```dart
import 'package:map_editor/src/application/services/pokemon_move_local_id.dart';
import 'package:test/test.dart';

void main() {
  group('normalizePokemonMoveLocalId', () {
    test('lowercases a simple name', () {
      expect(normalizePokemonMoveLocalId('Thunderbolt'), 'thunderbolt');
    });

    test('turns hyphens into underscores', () {
      expect(normalizePokemonMoveLocalId('U-turn'), 'u_turn');
    });

    test('drops apostrophes without leaving a separator', () {
      expect(normalizePokemonMoveLocalId("King's Shield"), 'kings_shield');
    });

    test('drops commas inside numbers', () {
      expect(
        normalizePokemonMoveLocalId('10,000,000 Volt Thunderbolt'),
        '10000000_volt_thunderbolt',
      );
    });

    test('handles repeated hyphens as a single separator', () {
      expect(normalizePokemonMoveLocalId('Will-O-Wisp'), 'will_o_wisp');
    });

    test('collapses consecutive separators', () {
      expect(normalizePokemonMoveLocalId('Double  -  Edge'), 'double_edge');
    });

    test('trims leading and trailing separators', () {
      expect(normalizePokemonMoveLocalId(' -Tackle- '), 'tackle');
    });

    test('returns an empty string for blank input', () {
      expect(normalizePokemonMoveLocalId('   '), '');
    });
  });
}
```

- [ ] **Étape 2 : lancer le test pour vérifier qu'il échoue**

```bash
cd packages/map_editor && dart test test/pokemon_move_local_id_test.dart
```

Attendu : ÉCHEC, fichier `pokemon_move_local_id.dart` introuvable.

- [ ] **Étape 3 : créer la fonction extraite**

Créer `packages/map_editor/lib/src/application/services/pokemon_move_local_id.dart` avec le corps
existant, inchangé :

```dart
/// Normalise un libellé d'attaque vers l'identifiant local du catalogue.
///
/// Cette fonction est partagée entre le converter Showdown et l'outil de
/// génération des noms localisés : les deux doivent produire exactement le même
/// identifiant à partir du même nom anglais, sinon la table de traductions ne
/// peut plus être indexée de façon fiable.
String normalizePokemonMoveLocalId(String rawValue) {
  final lowerCase = rawValue.trim().toLowerCase();
  if (lowerCase.isEmpty) {
    return '';
  }

  final separated = lowerCase.replaceAll(RegExp(r'[\s-]+'), '_');
  final asciiSafe = separated.replaceAll(RegExp(r'[^a-z0-9_]+'), '');
  final collapsed = asciiSafe.replaceAll(RegExp(r'_+'), '_');
  return collapsed.replaceAll(RegExp(r'^_|_$'), '');
}
```

- [ ] **Étape 4 : lancer le test pour vérifier qu'il passe**

```bash
cd packages/map_editor && dart test test/pokemon_move_local_id_test.dart
```

Attendu : SUCCÈS, 8 tests.

- [ ] **Étape 5 : brancher le converter sur la fonction extraite**

Dans `showdown_move_catalog_converter.dart`, ajouter l'import :

```dart
import 'pokemon_move_local_id.dart';
```

Supprimer la méthode privée `_normalizeSnakeCaseId` (lignes 1252-1262) et remplacer son unique
appel, ligne 80 :

```dart
    final localId = normalizePokemonMoveLocalId(displayName);
```

- [ ] **Étape 6 : vérifier que le converter n'a pas régressé**

```bash
cd packages/map_editor && dart test test/showdown_move_catalog_converter_test.dart test/sync_pokemon_moves_catalog_use_case_test.dart
```

Attendu : SUCCÈS. Si le premier fichier n'existe pas sous ce nom, lancer
`dart test test/ --name showdown` et vérifier que tout passe.

- [ ] **Étape 7 : commit**

```bash
git add packages/map_editor/lib/src/application/services/pokemon_move_local_id.dart packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart packages/map_editor/test/pokemon_move_local_id_test.dart && git commit -m "refactor(editor): partager la normalisation d'identifiant d'attaque"
```

---

## Task 3 : outil de génération et table de traductions

C'est la tâche à risque du plan. Elle produit une donnée, et la qualité de cette donnée est le
livrable.

**Fichiers :**
- Créer : `packages/map_editor/tool/generate_pokemon_move_localized_names.dart`
- Créer (généré) : `packages/map_editor/lib/src/application/seeds/pokemon_move_localized_names.dart`
- Test : `packages/map_editor/test/pokemon_move_localized_names_test.dart`

**Interfaces :**
- Consomme : `normalizePokemonMoveLocalId` (tâche 2).
- Produit :
  - `const Map<String, Map<String, String>> pokemonMoveLocalizedNames` — indexé par identifiant
    local, chaque valeur étant une map `langue → nom`.
  - `Map<String, String> localizedNamesForMove(String localId)` — renvoie une map vide si inconnu.

- [ ] **Étape 1 : écrire le test qui échoue**

Ce test porte sur le **contrat** de la table, pas sur son volume : il doit rester vrai après chaque
régénération.

Créer `packages/map_editor/test/pokemon_move_localized_names_test.dart` :

```dart
import 'package:map_editor/src/application/seeds/pokemon_move_localized_names.dart';
import 'package:map_editor/src/application/services/pokemon_move_local_id.dart';
import 'package:test/test.dart';

void main() {
  group('pokemonMoveLocalizedNames', () {
    test('is not empty', () {
      expect(pokemonMoveLocalizedNames, isNotEmpty);
    });

    test('every key is already a normalized local id', () {
      for (final key in pokemonMoveLocalizedNames.keys) {
        expect(
          normalizePokemonMoveLocalId(key),
          key,
          reason: 'Key "$key" is not a normalized local id.',
        );
      }
    });

    test('every entry exposes a non-empty french name', () {
      for (final entry in pokemonMoveLocalizedNames.entries) {
        final french = entry.value['fr'];
        expect(
          french,
          isNotNull,
          reason: 'Entry "${entry.key}" has no french name.',
        );
        expect(
          french!.trim(),
          isNotEmpty,
          reason: 'Entry "${entry.key}" has a blank french name.',
        );
      }
    });

    test('covers a few well-known moves', () {
      expect(pokemonMoveLocalizedNames['thunderbolt']?['fr'], 'Tonnerre');
      expect(pokemonMoveLocalizedNames['u_turn']?['fr'], isNotNull);
      expect(pokemonMoveLocalizedNames['kings_shield']?['fr'], isNotNull);
    });
  });

  group('localizedNamesForMove', () {
    test('returns the translations of a known move', () {
      expect(localizedNamesForMove('thunderbolt')['fr'], 'Tonnerre');
    });

    test('returns an empty map for an unknown move', () {
      expect(localizedNamesForMove('definitely_not_a_move'), isEmpty);
    });
  });
}
```

- [ ] **Étape 2 : lancer le test pour vérifier qu'il échoue**

```bash
cd packages/map_editor && dart test test/pokemon_move_localized_names_test.dart
```

Attendu : ÉCHEC, `pokemon_move_localized_names.dart` introuvable.

- [ ] **Étape 3 : écrire l'outil de génération**

Créer `packages/map_editor/tool/generate_pokemon_move_localized_names.dart` :

```dart
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:map_editor/src/application/services/pokemon_move_local_id.dart';

/// Génère la table des noms d'attaques localisés depuis PokeAPI.
///
/// Le matching passe volontairement par le **nom anglais** et non par le slug
/// PokeAPI : le converter Showdown dérive son identifiant local du nom anglais,
/// et les slugs divergent sur la ponctuation (`10-000-000-volt-thunderbolt`
/// contre `10,000,000 Volt Thunderbolt`).
///
/// Usage :
///   dart run tool/generate_pokemon_move_localized_names.dart \
///     > lib/src/application/seeds/pokemon_move_localized_names.dart
///
/// Le rapport de génération est écrit sur stderr et ne pollue donc pas le
/// fichier produit.
const _languages = <String>['fr'];
const _baseUri = 'https://pokeapi.co/api/v2';
const _pageSize = 200;
const _concurrency = 8;

Future<void> main(List<String> arguments) async {
  final client = http.Client();
  try {
    final moveUrls = await _fetchAllMoveUrls(client);
    stderr.writeln('PokeAPI exposes ${moveUrls.length} moves.');

    final table = <String, Map<String, String>>{};
    final skippedNoEnglishName = <String>[];
    final collisions = <String, List<String>>{};
    final missingTranslation = <String>[];

    for (var start = 0; start < moveUrls.length; start += _concurrency) {
      final slice = moveUrls.skip(start).take(_concurrency);
      final payloads = await Future.wait(
        slice.map((url) => _fetchJson(client, url)),
      );

      for (final payload in payloads) {
        final names = _readNamesByLanguage(payload);
        final englishName = names['en'];
        final slug = (payload['name'] as String?)?.trim() ?? '';

        if (englishName == null || englishName.isEmpty) {
          skippedNoEnglishName.add(slug.isEmpty ? '<unnamed>' : slug);
          continue;
        }

        final localId = normalizePokemonMoveLocalId(englishName);
        if (localId.isEmpty) {
          skippedNoEnglishName.add(slug);
          continue;
        }

        final translations = <String, String>{
          'en': englishName,
          for (final language in _languages)
            if ((names[language] ?? '').isNotEmpty)
              language: names[language]!,
        };

        if (!translations.containsKey('fr')) {
          missingTranslation.add(localId);
        }

        final existing = table[localId];
        if (existing != null && existing['en'] != englishName) {
          collisions.putIfAbsent(localId, () => <String>[existing['en']!])
              .add(englishName);
          continue;
        }
        table[localId] = translations;
      }

      stderr.writeln(
        'Fetched ${(start + _concurrency).clamp(0, moveUrls.length)}'
        '/${moveUrls.length}',
      );
    }

    stdout.write(_renderDartFile(table));

    stderr.writeln('');
    stderr.writeln('=== Rapport de génération ===');
    stderr.writeln('Entrées produites          : ${table.length}');
    stderr.writeln('Sans nom anglais (ignorées): ${skippedNoEnglishName.length}');
    for (final slug in skippedNoEnglishName) {
      stderr.writeln('  - $slug');
    }
    stderr.writeln('Sans traduction française  : ${missingTranslation.length}');
    for (final localId in missingTranslation) {
      stderr.writeln('  - $localId');
    }
    stderr.writeln('Collisions d\'identifiant   : ${collisions.length}');
    for (final entry in collisions.entries) {
      stderr.writeln('  - ${entry.key}: ${entry.value.join(" / ")}');
    }
  } finally {
    client.close();
  }
}

Future<List<String>> _fetchAllMoveUrls(http.Client client) async {
  final urls = <String>[];
  var offset = 0;
  while (true) {
    final payload = await _fetchJson(
      client,
      '$_baseUri/move?limit=$_pageSize&offset=$offset',
    );
    final results = payload['results'];
    if (results is! List || results.isEmpty) {
      break;
    }
    for (final result in results) {
      if (result is Map && result['url'] is String) {
        urls.add(result['url'] as String);
      }
    }
    if (payload['next'] == null) {
      break;
    }
    offset += _pageSize;
  }
  return urls;
}

Future<Map<String, dynamic>> _fetchJson(http.Client client, String url) async {
  final response = await client
      .get(Uri.parse(url), headers: const <String, String>{
        'User-Agent': 'PokeMapEditor/0.1 (+https://pokemap.local)',
      })
      .timeout(const Duration(seconds: 30));
  if (response.statusCode != 200) {
    throw StateError('GET $url failed with ${response.statusCode}');
  }
  return (jsonDecode(response.body) as Map).cast<String, dynamic>();
}

Map<String, String> _readNamesByLanguage(Map<String, dynamic> payload) {
  final raw = payload['names'];
  if (raw is! List) {
    return const <String, String>{};
  }
  final names = <String, String>{};
  for (final entry in raw) {
    if (entry is! Map) {
      continue;
    }
    final language = entry['language'];
    final languageId = language is Map ? language['name'] : null;
    final value = entry['name'];
    if (languageId is String && value is String && value.trim().isNotEmpty) {
      names[languageId.trim()] = value.trim();
    }
  }
  return names;
}

String _renderDartFile(Map<String, Map<String, String>> table) {
  final sortedIds = table.keys.toList()..sort();
  final buffer = StringBuffer()
    ..writeln('// GENERATED FILE - DO NOT EDIT BY HAND.')
    ..writeln('//')
    ..writeln('// Régénérer avec :')
    ..writeln('//   cd packages/map_editor && dart run \\')
    ..writeln('//     tool/generate_pokemon_move_localized_names.dart \\')
    ..writeln('//     > lib/src/application/seeds/pokemon_move_localized_names.dart')
    ..writeln('//')
    ..writeln('// Source : PokeAPI v2. Indexé par identifiant local du')
    ..writeln('// catalogue, dérivé du nom anglais via')
    ..writeln('// normalizePokemonMoveLocalId.')
    ..writeln('')
    ..writeln('const Map<String, Map<String, String>> pokemonMoveLocalizedNames =')
    ..writeln('    <String, Map<String, String>>{');

  for (final id in sortedIds) {
    final translations = table[id]!;
    final languages = translations.keys.toList()..sort();
    buffer.writeln("  '$id': <String, String>{");
    for (final language in languages) {
      buffer.writeln(
        "    '$language': '${_escape(translations[language]!)}',",
      );
    }
    buffer.writeln('  },');
  }

  buffer
    ..writeln('};')
    ..writeln('')
    ..writeln('/// Traductions connues pour un identifiant local de move.')
    ..writeln('///')
    ..writeln('/// Renvoie une map vide quand le move est inconnu de la table,')
    ..writeln('/// ce qui laisse le libellé anglais canonique en place.')
    ..writeln('Map<String, String> localizedNamesForMove(String localId) =>')
    ..writeln('    pokemonMoveLocalizedNames[localId] ?? const <String, String>{};');

  return buffer.toString();
}

String _escape(String value) =>
    value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
```

- [ ] **Étape 4 : générer la table**

```bash
cd packages/map_editor && dart run tool/generate_pokemon_move_localized_names.dart > lib/src/application/seeds/pokemon_move_localized_names.dart
```

Attendu : le rapport s'affiche sur stderr, le fichier est écrit. La commande prend plusieurs
minutes (~900 requêtes).

- [ ] **Étape 5 : lire le rapport — POINT D'ARRÊT**

Relire le rapport affiché à l'étape précédente et vérifier :
- le nombre d'entrées produites est cohérent (ordre de grandeur : 900) ;
- la liste « sans traduction française » est courte ;
- la liste « collisions d'identifiant » est **vide**. Une collision signifie que deux moves
  distincts produisent le même identifiant local, ce qui ferait afficher un mauvais nom.

**Ne pas poursuivre si des collisions existent.** Les remonter avant d'aller plus loin.

- [ ] **Étape 6 : vérifier le fichier généré**

```bash
cd packages/map_editor && head -20 lib/src/application/seeds/pokemon_move_localized_names.dart && grep -c "': <String, String>{" lib/src/application/seeds/pokemon_move_localized_names.dart
```

Attendu : l'en-tête « GENERATED FILE » et un compte d'entrées cohérent avec le rapport.

- [ ] **Étape 7 : lancer le test de contrat**

```bash
cd packages/map_editor && dart test test/pokemon_move_localized_names_test.dart
```

Attendu : SUCCÈS, 6 tests.

- [ ] **Étape 8 : analyse statique du fichier généré**

```bash
cd packages/map_editor && dart analyze lib/src/application/seeds/pokemon_move_localized_names.dart tool/generate_pokemon_move_localized_names.dart
```

Attendu : `No issues found!`

- [ ] **Étape 9 : commit**

```bash
git add packages/map_editor/tool/generate_pokemon_move_localized_names.dart packages/map_editor/lib/src/application/seeds/pokemon_move_localized_names.dart packages/map_editor/test/pokemon_move_localized_names_test.dart && git commit -m "feat(editor): générer la table des noms d'attaques localisés"
```

---

## Task 4 : alimenter le converter et le seed bootstrap

**Fichiers :**
- Modifier : `packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart:142`
- Modifier : `packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart:870`
- Test : `packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart` (existant, à compléter)
- Test : `packages/map_editor/test/showdown_move_catalog_converter_localization_test.dart` (créer)

**Interfaces :**
- Consomme : `localizedNamesForMove(String localId)` (tâche 3).
- Produit : les entrées de catalogue portent désormais `names['fr']` quand la table le connaît.

- [ ] **Étape 1 : écrire le test qui échoue pour le converter**

Créer `packages/map_editor/test/showdown_move_catalog_converter_localization_test.dart` :

```dart
import 'package:map_editor/src/application/services/showdown_move_catalog_converter.dart';
import 'package:test/test.dart';

void main() {
  const converter = ShowdownMoveCatalogConverter();

  Map<String, dynamic> entryFor(String id) {
    final catalog = converter.convert(<String, dynamic>{
      'thunderbolt': <String, dynamic>{
        'name': 'Thunderbolt',
        'type': 'Electric',
        'category': 'Special',
        'target': 'normal',
        'basePower': 90,
        'accuracy': 100,
        'pp': 15,
      },
      'quiverdance': <String, dynamic>{
        'name': 'Quiver Dance',
        'type': 'Bug',
        'category': 'Status',
        'target': 'self',
        'basePower': 0,
        'accuracy': true,
        'pp': 20,
      },
    });
    return catalog.entries.firstWhere((entry) => entry['id'] == id);
  }

  test('a converted move carries its french name', () {
    final names = (entryFor('thunderbolt')['names'] as Map)
        .cast<String, dynamic>();
    expect(names['en'], 'Thunderbolt');
    expect(names['fr'], 'Tonnerre');
  });

  test('the canonical name stays english', () {
    expect(entryFor('thunderbolt')['name'], 'Thunderbolt');
  });

  test('a move absent from the table keeps only its english name', () {
    final names =
        (entryFor('quiver_dance')['names'] as Map).cast<String, dynamic>();
    expect(names['en'], 'Quiver Dance');
  });
}
```

- [ ] **Étape 2 : lancer le test pour vérifier qu'il échoue**

```bash
cd packages/map_editor && dart test test/showdown_move_catalog_converter_localization_test.dart
```

Attendu : ÉCHEC sur `names['fr']`, qui vaut `null`.

- [ ] **Étape 3 : enrichir le converter**

Dans `showdown_move_catalog_converter.dart`, ajouter l'import :

```dart
import '../seeds/pokemon_move_localized_names.dart';
```

Remplacer la ligne 142 :

```dart
      names: <String, String>{'en': displayName},
```

par :

```dart
      names: <String, String>{
        'en': displayName,
        for (final entry in localizedNamesForMove(localId).entries)
          if (entry.key != 'en') entry.key: entry.value,
      },
```

Deux points à ne pas rater :

- Le `'en'` de la table est délibérément écarté. Le nom anglais reste celui de Showdown, qui fait
  autorité puisque c'est lui qui a produit `name` et l'identifiant local.
- Ne pas écrire `...localizedNamesForMove(localId)..remove('en')` : la fonction renvoie une map
  `const`, et `remove` lèverait une erreur à l'exécution.

- [ ] **Étape 4 : lancer le test pour vérifier qu'il passe**

```bash
cd packages/map_editor && dart test test/showdown_move_catalog_converter_localization_test.dart
```

Attendu : SUCCÈS, 3 tests.

- [ ] **Étape 5 : écrire le test qui échoue pour le seed bootstrap**

Ajouter dans `packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart` :

```dart
  test('every bootstrap move carries a french name', () {
    final catalog = buildEmbeddedPokemonMovesBootstrapSeed();
    for (final entry in catalog.entries) {
      final id = entry['id'] as String;
      final names = (entry['names'] as Map).cast<String, dynamic>();
      expect(
        names['fr'],
        isNotNull,
        reason: 'Bootstrap move "$id" has no french name.',
      );
    }
  });
```

- [ ] **Étape 6 : lancer le test pour vérifier qu'il échoue**

```bash
cd packages/map_editor && dart test test/pokemon_moves_bootstrap_seed_test.dart
```

Attendu : ÉCHEC, les 28 moves n'ont que `en`.

- [ ] **Étape 7 : enrichir le seed**

Dans `pokemon_moves_bootstrap_seed.dart`, ajouter l'import :

```dart
import 'pokemon_move_localized_names.dart';
```

Remplacer la ligne 870, dans le helper `_showdownSeedMove` :

```dart
    names: <String, String>{'en': name},
```

par :

```dart
    names: <String, String>{
      'en': name,
      for (final entry in localizedNamesForMove(id).entries)
        if (entry.key != 'en') entry.key: entry.value,
    },
```

Le helper reçoit déjà `id` en paramètre nommé, aucun changement de signature n'est nécessaire.

- [ ] **Étape 8 : lancer les tests du seed**

```bash
cd packages/map_editor && dart test test/pokemon_moves_bootstrap_seed_test.dart
```

Attendu : SUCCÈS. Si un move du seed n'a pas de nom français, c'est un trou réel de la table : le
noter et vérifier son identifiant dans le rapport de la tâche 3.

- [ ] **Étape 9 : figer le comportement du merge**

Ce test fige une décision de design qui serait autrement invisible : la source externe fait
autorité sur les langues qu'elle fournit, donc une surcharge manuelle de `names.fr` est écrasée.
Sans ce test, un futur contributeur pourrait « corriger » ce comportement en croyant à un bug.

Ajouter dans `packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart`, en
réutilisant les helpers de workspace et de repository déjà présents en tête du fichier :

```dart
  test('an external french name overwrites the local one', () async {
    // Décision de design assumée, voir
    // documentation/architecture/2026-08-16-noms-attaques-localises-design.md
    final workspace = await _workspaceWithMovesCatalog(<Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'thunderbolt',
        'name': 'Thunderbolt',
        'names': <String, String>{
          'en': 'Thunderbolt',
          'fr': 'Éclair Maison',
        },
        'type': 'electric',
        'category': 'special',
        'basePower': 90,
        'accuracy': <String, dynamic>{'type': 'percent', 'value': 100},
        'pp': 15,
      },
    ]);

    final result = await _syncUseCase(workspace, showdownSnapshot: <String, dynamic>{
      'thunderbolt': <String, dynamic>{
        'name': 'Thunderbolt',
        'type': 'Electric',
        'category': 'Special',
        'target': 'normal',
        'basePower': 90,
        'accuracy': 100,
        'pp': 15,
      },
    }).execute(workspace);

    expect(result.updatedIds, contains('thunderbolt'));

    final catalog = await _readMovesCatalog(workspace);
    final entry = catalog.entries.single;
    final names = (entry['names'] as Map).cast<String, dynamic>();
    expect(names['fr'], 'Tonnerre');
  });
```

Les noms `_workspaceWithMovesCatalog`, `_syncUseCase` et `_readMovesCatalog` désignent les helpers
équivalents déjà utilisés par les autres tests de merge de ce fichier — reprendre leurs noms réels
au moment de l'écriture plutôt que d'en créer de nouveaux.

- [ ] **Étape 10 : lancer les tests de synchronisation**

```bash
cd packages/map_editor && dart test test/sync_pokemon_moves_catalog_use_case_test.dart
```

Attendu : SUCCÈS.

- [ ] **Étape 11 : commit**

```bash
git add packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart packages/map_editor/test/showdown_move_catalog_converter_localization_test.dart packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart && git commit -m "feat(editor): renseigner les noms français dans le catalogue d'attaques"
```

---

## Task 5 : afficher les noms français en combat

**Fichiers :**
- Modifier : `packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart:100,265,318`
- Modifier : `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart:1945`
- Modifier : `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:7591`
- Test : `packages/map_runtime/test/battle_command_menu_model_localization_test.dart` (créer)

**Interfaces :**
- Consomme : `PokemonMove.displayName(locale)` (tâche 1), `RuntimeMoveCatalog.entriesById`.
- Produit : `typedef BattleMoveDisplayNameResolver = String Function(String moveId, String fallbackName);`

Rappel de la contrainte : `BattleMove` (`map_battle`) ne porte pas de map `names`, et `map_battle`
ne doit pas être modifié. La résolution se fait donc par `moveId`, via une fonction injectée.

- [ ] **Étape 1 : écrire le test qui échoue**

Créer `packages/map_runtime/test/battle_command_menu_model_localization_test.dart`. Construire une
`BattleSession` avec un move `thunderbolt` nommé `Thunderbolt`, en suivant les helpers de setup déjà
utilisés dans `packages/map_runtime/test/battle_mobile_command_overlay_test.dart` :

```dart
  test('a move entry uses the resolved display name', () {
    final model = buildBattleCommandMenuModel(
      session: session,
      mode: BattleCommandMenuMode.fight,
      selectedRootIndex: 0,
      selectedChoiceIndex: 0,
      resolveMoveDisplayName: (moveId, fallbackName) =>
          moveId == 'thunderbolt' ? 'Tonnerre' : fallbackName,
    );

    expect(model.choiceEntries.first.title, 'Tonnerre');
  });

  test('a move entry falls back to the battle name', () {
    final model = buildBattleCommandMenuModel(
      session: session,
      mode: BattleCommandMenuMode.fight,
      selectedRootIndex: 0,
      selectedChoiceIndex: 0,
      resolveMoveDisplayName: (moveId, fallbackName) => fallbackName,
    );

    expect(model.choiceEntries.first.title, 'Thunderbolt');
  });

  test('the resolver is optional and defaults to the battle name', () {
    final model = buildBattleCommandMenuModel(
      session: session,
      mode: BattleCommandMenuMode.fight,
      selectedRootIndex: 0,
      selectedChoiceIndex: 0,
    );

    expect(model.choiceEntries.first.title, 'Thunderbolt');
  });
```

Le paramètre optionnel est délibéré : il évite de casser les appels existants dans les tests du
package.

- [ ] **Étape 2 : lancer le test pour vérifier qu'il échoue**

```bash
cd packages/map_runtime && flutter test test/battle_command_menu_model_localization_test.dart
```

Attendu : ÉCHEC, paramètre `resolveMoveDisplayName` inconnu.

- [ ] **Étape 3 : ajouter le typedef et le paramètre**

En tête de `battle_command_menu_model.dart` :

```dart
/// Résout le libellé affiché d'une attaque à partir de son identifiant.
///
/// `map_battle` reste volontairement pur et ne transporte pas de traductions :
/// la résolution est donc injectée par la couche qui détient le catalogue
/// projet et la locale courante.
typedef BattleMoveDisplayNameResolver = String Function(
  String moveId,
  String fallbackName,
);

String _defaultMoveDisplayName(String moveId, String fallbackName) =>
    fallbackName;
```

Modifier la signature ligne 100 :

```dart
BattleCommandMenuModel buildBattleCommandMenuModel({
  required BattleSession session,
  required BattleCommandMenuMode mode,
  required int selectedRootIndex,
  required int selectedChoiceIndex,
  BattleMoveDisplayNameResolver resolveMoveDisplayName =
      _defaultMoveDisplayName,
}) {
```

Propager à l'appel de `_buildChoiceEntries` ligne 142 :

```dart
  final choiceEntries = _buildChoiceEntries(
    session: session,
    mode: safeMode,
    resolveMoveDisplayName: resolveMoveDisplayName,
  );
```

- [ ] **Étape 4 : propager jusqu'à `_entryForChoice`**

Signature de `_buildChoiceEntries` ligne 265 :

```dart
List<BattleCommandChoiceEntry> _buildChoiceEntries({
  required BattleSession session,
  required BattleCommandMenuMode mode,
  required BattleMoveDisplayNameResolver resolveMoveDisplayName,
}) {
```

Les deux appels à `_entryForChoice` (modes `fight` et `pokemon`) deviennent :

```dart
            (choice) => _entryForChoice(
              session,
              choice,
              resolveMoveDisplayName,
            ),
```

Signature de `_entryForChoice` :

```dart
BattleCommandChoiceEntry _entryForChoice(
  BattleSession session,
  PlayerBattleChoice choice,
  BattleMoveDisplayNameResolver resolveMoveDisplayName,
) {
```

Et dans la branche `PlayerBattleChoiceFight`, remplacer `title: move.name` par :

```dart
      title: resolveMoveDisplayName(move.id, move.name),
```

- [ ] **Étape 5 : lancer le test pour vérifier qu'il passe**

```bash
cd packages/map_runtime && flutter test test/battle_command_menu_model_localization_test.dart
```

Attendu : SUCCÈS, 3 tests.

- [ ] **Étape 6 : transporter le resolver dans le composant overlay**

Dans `battle_overlay_component.dart`, ajouter un champ au constructeur de
`BattleOverlayComponent` :

```dart
    this.resolveMoveDisplayName = _defaultBattleMoveDisplayName,
```

et la déclaration :

```dart
  final BattleMoveDisplayNameResolver resolveMoveDisplayName;
```

avec, au niveau du fichier :

```dart
String _defaultBattleMoveDisplayName(String moveId, String fallbackName) =>
    fallbackName;
```

Puis, dans `_currentMenuModel()` ligne 1945 :

```dart
  BattleCommandMenuModel _currentMenuModel() {
    return buildBattleCommandMenuModel(
      session: _session,
      mode: _effectiveMenuMode(),
      selectedRootIndex: _selectedRootIndex,
      selectedChoiceIndex: _selectedChoiceIndex,
      resolveMoveDisplayName: resolveMoveDisplayName,
    );
  }
```

- [ ] **Étape 7 : construire le resolver dans le jeu**

Dans `playable_map_game.dart`, ajouter un champ à côté de `_battleMoveCatalogLoader` (ligne 536) :

```dart
  RuntimeMoveCatalog? _battleMovesCatalog;
```

L'affecter à l'endroit où le catalogue est chargé pour le setup battle (recherche :
`_battleMoveCatalogLoader.load(`), en conservant la valeur résolue :

```dart
    _battleMovesCatalog = movesCatalog;
```

Puis, dans la construction du `BattleOverlayComponent` ligne 7591, ajouter :

```dart
          resolveMoveDisplayName: _resolveBattleMoveDisplayName,
```

et la méthode :

```dart
  String _resolveBattleMoveDisplayName(String moveId, String fallbackName) {
    final move = _battleMovesCatalog?.entriesById[moveId];
    if (move == null) {
      return fallbackName;
    }
    return move.displayName(runtimeLocale);
  }
```

- [ ] **Étape 8 : lancer les tests battle du runtime**

```bash
cd packages/map_runtime && flutter test test/battle_command_menu_model_localization_test.dart test/battle_mobile_command_overlay_test.dart test/battle_overlay_component_test.dart test/battle_presentation_command_contract_test.dart
```

Attendu : SUCCÈS. Le paramètre étant optionnel, les appels existants restent valides.

- [ ] **Étape 9 : vérifier les goldens du joueur**

```bash
cd packages/map_player_ui && flutter test test/player_battle_overlay_test.dart
```

Attendu : SUCCÈS. Le golden `separated_command_dock_508x379.png` rend le menu racine et non la
liste des attaques ; il ne doit pas bouger. S'il bouge, **ne pas régénérer sans vérifier** ce qui a
changé.

- [ ] **Étape 10 : analyse statique**

```bash
cd packages/map_runtime && dart analyze lib/src/presentation/flame/battle_command_menu_model.dart lib/src/presentation/flame/battle_overlay_component.dart lib/src/presentation/flame/playable_map_game.dart
```

Attendu : `No issues found!`

- [ ] **Étape 11 : commit**

```bash
git add packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart packages/map_runtime/test/battle_command_menu_model_localization_test.dart && git commit -m "feat(runtime): afficher les noms d'attaques dans la langue du joueur"
```

---

## Task 6 : affichage et recherche dans l'éditeur

**Fichiers :**
- Modifier : `packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart:23-67,269,339`
- Modifier : `packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace/moves_catalog_workspace.dart`
- Test : `packages/map_editor/test/pokemon_moves_catalog_loader_test.dart` (existant, à compléter)

**Interfaces :**
- Consomme : `resolveLocalizedName` (tâche 1).
- Produit : `PokemonMoveCatalogEntryView.names`, `.displayName(locale)`, `.hasLocalizedName(locale)`.

- [ ] **Étape 1 : écrire le test qui échoue**

Ajouter dans `packages/map_editor/test/pokemon_moves_catalog_loader_test.dart` :

```dart
  test('a projected entry exposes its localized names', () async {
    // Construire un catalogue dont l'entrée porte
    // names: {'en': 'Thunderbolt', 'fr': 'Tonnerre'} en suivant les helpers
    // de fixture déjà présents dans ce fichier, puis :
    final entry = view.entries.single;
    expect(entry.names['fr'], 'Tonnerre');
    expect(entry.displayName('fr'), 'Tonnerre');
    expect(entry.displayName('en'), 'Thunderbolt');
    expect(entry.hasLocalizedName('fr'), isTrue);
  });

  test('an entry without translation reports it', () async {
    // Même fixture, mais names: {'en': 'Thunderbolt'} :
    final entry = view.entries.single;
    expect(entry.displayName('fr'), 'Thunderbolt');
    expect(entry.hasLocalizedName('fr'), isFalse);
  });
```

- [ ] **Étape 2 : lancer le test pour vérifier qu'il échoue**

```bash
cd packages/map_editor && dart test test/pokemon_moves_catalog_loader_test.dart
```

Attendu : ÉCHEC, `names` n'existe pas sur la vue.

- [ ] **Étape 3 : porter `names` dans la vue projetée**

Dans `sync_pokemon_moves_catalog_use_case.dart`, ajouter au constructeur de
`PokemonMoveCatalogEntryView` (ligne 24) :

```dart
    this.names = const <String, String>{},
```

au champ (après `final String name;`) :

```dart
  final Map<String, String> names;
```

et les deux accesseurs :

```dart
  String displayName(String locale) => resolveLocalizedName(
        names: names,
        locale: locale,
        fallback: name,
      );

  bool hasLocalizedName(String locale) =>
      displayName(locale) != name || names.containsKey(locale);
```

Dans la branche canonique (ligne 269), ajouter `names: move.names,`. Dans la branche legacy
(ligne 339), ajouter `names: localizedNames ?? const <String, String>{},` — la variable
`localizedNames` est déjà lue ligne 313.

- [ ] **Étape 4 : lancer le test pour vérifier qu'il passe**

```bash
cd packages/map_editor && dart test test/pokemon_moves_catalog_loader_test.dart
```

Attendu : SUCCÈS.

- [ ] **Étape 5 : afficher le nom résolu dans le workspace**

Dans `moves_catalog_workspace.dart`, résoudre la locale une fois dans `build`, à côté de la ligne
103 :

```dart
    final locale = Localizations.localeOf(context).toLanguageTag();
```

Puis remplacer les deux affichages du nom :
- ligne 707, `entry.name` dans la ligne de liste ;
- ligne 888, `entry!.name` dans le panneau de détail ;

par `entry.displayName(locale)` et `entry!.displayName(locale)`. La locale doit être passée aux
sous-widgets concernés, qui reçoivent déjà `entries` et `searchController` par paramètre nommé.

Le tri des entrées reste dans le use case ; ne pas le déplacer dans ce lot.

- [ ] **Étape 6 : étendre la recherche au nom français**

`_filterEntries` (ligne 368) cherche déjà sur `name`, `id`, `type` et `category`. Il suffit d'y
ajouter le nom localisé, en passant la locale en paramètre :

```dart
  List<PokemonMoveCatalogEntryView> _filterEntries(
    List<PokemonMoveCatalogEntryView> entries,
    String query,
    String locale,
  ) {
    if (query.isEmpty) {
      return entries;
    }
    final normalizedQuery = query.toLowerCase();
    return entries.where((entry) {
      return entry.name.toLowerCase().contains(normalizedQuery) ||
          entry.displayName(locale).toLowerCase().contains(normalizedQuery) ||
          entry.id.toLowerCase().contains(normalizedQuery) ||
          (entry.type?.toLowerCase().contains(normalizedQuery) ?? false) ||
          (entry.category?.toLowerCase().contains(normalizedQuery) ?? false);
    }).toList(growable: false);
  }
```

Mettre à jour l'appel ligne 104 : `_filterEntries(view.entries, query, locale)`.

Conserver `entry.name` dans le prédicat est délibéré : c'est ce qui permet de continuer à trouver
un move en tapant son nom anglais alors que l'affichage est en français.

- [ ] **Étape 7 : ajouter le badge d'absence de traduction**

Dans la ligne de chaque entrée, afficher un badge discret lorsque
`!entry.hasLocalizedName(locale)`. Utiliser un rôle de surface existant du Personalization Studio
plutôt qu'une couleur en dur.

Afficher également, en en-tête du workspace, le nombre d'entrées concernées :

```dart
final missingCount =
    view.entries.where((entry) => !entry.hasLocalizedName(locale)).length;
```

C'est le seul chemin par lequel l'auteur apprend qu'une resynchronisation est nécessaire.

- [ ] **Étape 8 : lancer les tests du workspace**

```bash
cd packages/map_editor && flutter test test/pokemon_catalogs_workspace_ui_test.dart test/pokemon_moves_catalog_loader_test.dart
```

Attendu : SUCCÈS.

- [ ] **Étape 9 : vérification visuelle dans l'éditeur**

Lancer l'éditeur, ouvrir le catalogue moves et vérifier de visu :
- les noms s'affichent en français ;
- saisir `thunderbolt` trouve bien Tonnerre ;
- le compteur d'entrées sans traduction est cohérent avec le rapport de la tâche 3.

Des tests verts ne prouvent rien sur l'ergonomie réelle de l'éditeur.

- [ ] **Étape 10 : commit**

```bash
git add packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace/moves_catalog_workspace.dart packages/map_editor/test/pokemon_moves_catalog_loader_test.dart && git commit -m "feat(editor): afficher et rechercher les attaques en français"
```

---

## Vérification finale

- [ ] **Suite complète des packages touchés**

```bash
cd packages/map_core && dart test && cd ../map_editor && flutter test && cd ../map_runtime && flutter test && cd ../map_player_ui && flutter test
```

Attendu : SUCCÈS partout. Reporter honnêtement tout échec plutôt que de le contourner.

- [ ] **Analyse statique globale**

```bash
cd packages/map_core && dart analyze && cd ../map_editor && dart analyze && cd ../map_runtime && dart analyze
```

Attendu : `No issues found!`

- [ ] **Contrôle du périmètre du diff**

```bash
git diff --stat 01bc94915..HEAD -- packages/
```

Attendu : aucun fichier de `packages/map_battle/` ne doit apparaître. Sa présence signalerait une
violation de la contrainte de pureté du domaine.
