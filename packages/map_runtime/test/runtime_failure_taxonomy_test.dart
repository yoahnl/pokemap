import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

/// La taxonomie des défaillances est déclarée, confrontée, et tenue —
/// BETA-SYS-006.
///
/// Deux familles de cas. La première confronte l'inventaire à la source, pour
/// qu'il ne devienne pas une fiction. La seconde est le garde de NON-FUITE :
/// il lit les fichiers porteurs des canaux joueur et interdit les deux classes
/// de fuite réellement observées avant ce lot —
///   1. une interpolation dans un littéral versé à un canal joueur
///      (« Dialogue introuvable: ${request.dialogueId} ») ;
///   2. un message joueur rédigé en anglais, 63 occurrences, que le repli l10n
///      ne rattrape pas puisqu'il ne joue que sur null.
///
/// Le garde est lexical et ciblé : il ne couvre que les littéraux, pas les
/// variables. C'est assumé — la classe de bug observée était littérale, et un
/// garde plus large serait un analyseur sémantique fragile.
void main() {
  group('BETA-SYS-006 the taxonomy answers to the source', () {
    test('every declared carrier type exists in the exported API or source',
        () {
      // Un inventaire qui nomme des types disparus est pire qu'aucun
      // inventaire : il documente un monde qui n'existe plus.
      // projectValidation est porté par map_core ; les autres par map_runtime.
      // Le test lit les deux paquets — c'est un test de dépôt, comme le garde.
      final sources = <String>[
        ..._libSources().values,
        ..._packageSources('../map_core/lib/src/validation').values,
      ].join('\n');
      for (final contract in runtimeFailureTaxonomy) {
        final name = contract.carrierTypeName.split(' ').first;
        expect(
          sources.contains('class $name') || sources.contains('$name('),
          isTrue,
          reason: '${contract.domain}: $name introuvable',
        );
      }
    });

    test('the taxonomy is sorted and has one entry per domain', () {
      final domains = runtimeFailureTaxonomy
          .map((contract) => contract.domain)
          .toList(growable: false);

      expect(domains.toSet(), hasLength(domains.length));
      expect(domains, orderedEquals(<String>[...domains]..sort()));
    });

    test('every entry says how it recovers and what not to break', () {
      for (final contract in runtimeFailureTaxonomy) {
        expect(contract.notes, isNotEmpty, reason: contract.domain);
        expect(contract.playerChannelField, isNotEmpty,
            reason: contract.domain);
        expect(contract.debugChannelField, isNotEmpty,
            reason: contract.domain);
      }
    });
  });

  group('BETA-SYS-006 the player channels leak nothing', () {
    test('no literal handed to a player channel interpolates anything', () {
      // La fuite n°1 : « Dialogue introuvable: ${request.dialogueId} ». Un
      // identifiant d'authoring sur l'écran du joueur. Toute interpolation dans
      // un littéral de canal joueur est interdite : le détail technique va en
      // debugPrint, le joueur reçoit un texte stable.
      final offenders = <String>[];
      for (final entry in _libSources().entries) {
        for (final literal in _playerChannelLiterals(entry.value)) {
          if (literal.contains(r'$')) {
            offenders.add('${entry.key}: $literal');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'Un canal joueur interpole du contenu dynamique :\n'
            '${offenders.join('\n')}',
      );
    });

    test('no literal handed to a player channel is written in English', () {
      // La fuite n°2 : 63 messages joueur codés en anglais sur un produit dont
      // le canal joueur est français. Le repli l10n ne joue que sur null, donc
      // un texte anglais arrivait tel quel. Détection par mots-outils anglais
      // entourés d'espaces — insensible aux identifiants et aux noms propres.
      const englishMarkers = <String>[
        ' could not ',
        ' cannot ',
        ' is unavailable',
        ' are unavailable',
        ' failed',
        ' did not ',
        ' the game',
        'The ',
        'No ',
      ];
      final offenders = <String>[];
      for (final entry in _libSources().entries) {
        for (final literal in _playerChannelLiterals(entry.value)) {
          for (final marker in englishMarkers) {
            if (literal.contains(marker)) {
              offenders.add('${entry.key}: $literal');
              break;
            }
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'Un canal joueur porte un texte anglais :\n'
            '${offenders.join('\n')}',
      );
    });

    test('the guard reads real player channel literals at all', () {
      // Garde du garde : si l'extraction rendait une liste vide, les deux cas
      // précédents passeraient sans rien vérifier.
      final literals = <String>[
        for (final source in _libSources().values)
          ..._playerChannelLiterals(source),
      ];

      expect(literals, hasLength(greaterThan(80)));
      expect(
        literals.any(
          (literal) => literal.contains('Le sac est occupé pour le moment.'),
        ),
        isTrue,
        reason: 'un littéral connu du canal joueur doit être vu par le garde',
      );
    });
  });
}

Map<String, String> _packageSources(String root) {
  final directory = Directory(root);
  if (!directory.existsSync()) {
    throw StateError('Missing sibling package directory: $root');
  }
  return <String, String>{
    for (final entity in directory.listSync(recursive: true))
      if (entity is File && entity.path.endsWith('.dart'))
        entity.path: entity.readAsStringSync(),
  };
}

Map<String, String> _libSources() {
  final directory = Directory('lib');
  if (!directory.existsSync()) {
    throw StateError('Run this suite from packages/map_runtime.');
  }
  return <String, String>{
    for (final entity in directory.listSync(recursive: true))
      if (entity is File && entity.path.endsWith('.dart'))
        entity.path: entity.readAsStringSync(),
  };
}

/// Littéraux versés aux canaux joueur : `safeMessage: '…'` et
/// `_showNotification('…')`.
///
/// Les apostrophes françaises étant des caractères à part entière, la capture
/// s'arrête au premier guillemet simple NON échappé — les textes du dépôt
/// utilisent l'apostrophe typographique U+2019, jamais l'échappement.
Iterable<String> _playerChannelLiterals(String source) sync* {
  final patterns = <RegExp>[
    RegExp(r"safeMessage:\s*'([^']*)'"),
    RegExp(r"_showNotification\(\s*'([^']*)'"),
  ];
  for (final pattern in patterns) {
    for (final match in pattern.allMatches(source)) {
      yield match.group(1)!;
    }
  }
}
