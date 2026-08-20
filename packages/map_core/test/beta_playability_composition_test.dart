import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

/// Le catalogue de composition est confronté au répertoire — BETA-SYS-005.
///
/// Le ticket existe parce que la gate de jouabilité bêta ne composait AUCUN des
/// validateurs de domaine du dépôt, et que rien ne le signalait : ne pas
/// composer un validateur ne casse rien, ça rend juste un verdict trop
/// optimiste.
///
/// Ces cas lisent le vrai dossier plutôt qu'une liste recopiée. Un catalogue
/// confronté à une liste écrite à la main ne prouverait que l'accord de deux
/// listes écrites à la main.
Set<String> _validationSourceFileNames() {
  final directory = Directory('lib/src/validation');
  if (!directory.existsSync()) {
    throw StateError('Run this suite from packages/map_core.');
  }
  return directory
      .listSync()
      .whereType<File>()
      .map((file) => file.uri.pathSegments.last)
      .where((name) => name.endsWith('.dart'))
      .toSet();
}

void main() {
  group('BETA-SYS-005 the beta gate composition is declared and checked', () {
    late final Set<String> sourceFileNames;
    late final Set<String> catalogued;

    setUpAll(() {
      sourceFileNames = _validationSourceFileNames();
      catalogued = betaPlayabilityComposition
          .map((entry) => entry.sourceFileName)
          .toSet();
    });

    test('the directory holds validators at all', () {
      // Garde du garde : une lecture rendant un ensemble vide ferait passer
      // tous les cas suivants sans rien vérifier.
      expect(sourceFileNames, hasLength(greaterThan(5)));
      expect(sourceFileNames, contains('beta_playability_validator.dart'));
    });

    test('no validator exists without a declared place in the gate', () {
      // C'est le sens qui compte : ajouter un validateur sans décider s'il
      // entre dans la gate devient impossible en silence.
      expect(sourceFileNames.difference(catalogued), isEmpty);
    });

    test('the catalogue names no file the directory does not have', () {
      expect(catalogued.difference(sourceFileNames), isEmpty);
    });

    test('the catalogue has no duplicate and stays sorted', () {
      final names = betaPlayabilityComposition
          .map((entry) => entry.sourceFileName)
          .toList();

      expect(names, hasLength(catalogued.length));
      expect(names, orderedEquals(<String>[...names]..sort()));
    });

    test('every entry explains its place', () {
      // Une dette sans explication redevient un oubli au bout de deux mois, et
      // un « hors périmètre » sans raison est indiscutable donc inutile.
      for (final entry in betaPlayabilityComposition) {
        expect(entry.rationale, isNotEmpty, reason: entry.sourceFileName);
      }
    });

    test('the recorded debt is exactly these four validators', () {
      // Figé à l'identique, pas par un compteur : en composer un fait échouer
      // ce cas, ce qui force à mettre le catalogue à jour au lieu de payer la
      // dette en silence. En laisser un nouveau de côté le fait échouer aussi.
      final pending = betaPlayabilityComposition
          .where(
            (entry) =>
                entry.role ==
                BetaPlayabilityCompositionRole.pendingComposition,
          )
          .map((entry) => entry.sourceFileName)
          .toSet();

      expect(pending, <String>{
        'player_roster_validation.dart',
        'pokemon_catalog_coherence_validator.dart',
        'project_item_catalog_validator.dart',
        'shop_state_validator.dart',
      });
    });

    test('nothing claims to be composed while the gate ignores it', () {
      // BETA-SYS-005 ne compose encore aucun validateur externe : la gate a
      // gagné sa propre règle de capacité terrain, pas un appel vers un
      // validateur voisin. Déclarer `composed` aujourd'hui serait une promesse
      // fausse, et ce cas l'interdit jusqu'à ce que ce soit vrai.
      final composed = betaPlayabilityComposition
          .where(
            (entry) =>
                entry.role == BetaPlayabilityCompositionRole.composed,
          )
          .toList();

      expect(
        composed,
        isEmpty,
        reason: 'composing one means also proving it from the gate',
      );
    });
  });
}
