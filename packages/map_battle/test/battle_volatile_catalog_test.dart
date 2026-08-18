import 'dart:io';

import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

/// Identifiants d'effets déclarés par les familles de volatiles du moteur.
///
/// Lus dans la source plutôt que recopiés : un catalogue confronté à une liste
/// écrite à la main ne prouve que l'accord de deux listes écrites à la main.
///
/// Les trois formes de déclaration sont couvertes, et il a fallu les trouver.
/// Une première version ne lisait que `id: '...'` et rendait SIX familles
/// invisibles à son propre garde, dont `bind` et `cant_switch`, c'est-à-dire le
/// trapping que le ticket exige nommément, et `protect` lui-même :
///   id: 'confusion'                     -> littéral
///   String id = 'protect'               -> paramètre par défaut
///   id: PsdkBattleEffectIds.bind        -> constante, résolue depuis la source
Set<String> _engineFamilyIds() {
  final directory = Directory('lib/src/domain/effect/move');
  if (!directory.existsSync()) {
    throw StateError('Run this suite from packages/map_battle.');
  }
  final constants = _effectIdConstants();
  final ids = <String>{};
  for (final source in _effectSources(directory)) {
    for (final match in RegExp("id: '([a-z_]+)'").allMatches(source)) {
      ids.add(match.group(1)!);
    }
    for (final match in RegExp("String id = '([a-z_]+)'").allMatches(source)) {
      ids.add(match.group(1)!);
    }
    for (final match
        in RegExp(r'id: PsdkBattleEffectIds\.(\w+)').allMatches(source)) {
      final resolved = constants[match.group(1)];
      if (resolved != null) ids.add(resolved);
    }
  }
  return ids;
}

Map<String, String> _effectIdConstants() {
  final source =
      File('lib/src/psdk/domain/psdk_battle_combatant.dart').readAsStringSync();
  return <String, String>{
    for (final match
        in RegExp("static const String (\\w+) = '([a-z_]+)';").allMatches(source))
      match.group(1)!: match.group(2)!,
  };
}

List<String> _effectSources(Directory directory) {
  return directory
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .map((file) => file.readAsStringSync())
      .toList(growable: false);
}

/// Classes d'effets déclarées, pour reconnaître une famille exercée par sa
/// classe plutôt que par son identifiant.
Set<String> _effectClassNames() {
  final source =
      _effectSources(Directory('lib/src/domain/effect/move')).join('\n');
  return RegExp(r'class (\w+Effect)\b')
      .allMatches(source)
      .map((match) => match.group(1)!)
      .toSet();
}

String _pascalCase(String id) => id
    .split('_')
    .map((part) => part.isEmpty
        ? part
        : '${part[0].toUpperCase()}${part.substring(1)}')
    .join();

/// Familles nommées par au moins un fichier de test.
///
/// Deux signaux, parce qu'un seul mentait : `two_turn_charge` n'apparaît dans
/// aucun test sous forme de chaîne, mais `TwoTurnChargeEffect` y est bien
/// exercé. Le compter comme non couvert aurait été un faux constat.
Set<String> _testedFamilyIds(Set<String> candidates) {
  final classes = _effectClassNames();
  final sources = <String>[];
  for (final entity in Directory('test').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (entity.path.endsWith('battle_volatile_catalog_test.dart')) continue;
    sources.add(entity.readAsStringSync());
  }

  final tested = <String>{};
  for (final id in candidates) {
    final className = '${_pascalCase(id)}Effect';
    final hasClass = classes.contains(className);
    for (final source in sources) {
      if (source.contains("'$id'") ||
          (hasClass && source.contains(className))) {
        tested.add(id);
        break;
      }
    }
  }
  return tested;
}

void main() {
  group('BETA-BAT-005 the volatile catalog answers to the engine', () {
    late final Set<String> engineIds;
    late final Set<String> catalogIds;

    setUpAll(() {
      engineIds = _engineFamilyIds();
      catalogIds = battleVolatileCatalog.map((family) => family.id).toSet();
    });

    test('the engine declares families at all', () {
      // Garde-fou du garde-fou : si la lecture de la source rendait un ensemble
      // vide, tous les tests suivants passeraient sans rien vérifier.
      expect(engineIds, hasLength(greaterThan(40)));
      expect(engineIds, contains('confusion'));
    });

    test('no volatile family exists in the engine without being catalogued',
        () {
      // C'est le sens qui compte : ajouter une famille sans la classer devient
      // impossible, donc le catalogue ne peut pas promettre moins que ce que le
      // moteur sait faire.
      expect(engineIds.difference(catalogIds), isEmpty);
    });

    test('the catalog promises no family the engine does not have', () {
      expect(catalogIds.difference(engineIds), isEmpty);
    });

    test('the catalog has no duplicate entry and stays sorted', () {
      final ids = battleVolatileCatalog.map((family) => family.id).toList();
      expect(ids, hasLength(catalogIds.length));
      expect(ids, orderedEquals(<String>[...ids]..sort()));
    });

    test('a family claiming a test is one a test actually exercises', () {
      // Le niveau de support est MESURÉ, pas déclaré. Supprimer le dernier test
      // d'une famille certifiée fait échouer ce cas, au lieu de laisser une
      // promesse tenir toute seule.
      final tested = _testedFamilyIds(engineIds);
      final claimed = battleVolatileCatalog
          .where((family) =>
              family.support == BattleVolatileSupport.certified ||
              family.support == BattleVolatileSupport.partial)
          .map((family) => family.id)
          .toSet();

      expect(claimed.difference(tested), isEmpty);
    });

    test('every partial family says which gap it records', () {
      // `partial` sans explication serait pire que `certified` : une promesse
      // affaiblie que personne ne peut interpréter.
      for (final family in battleVolatileCatalog.where(
        (family) => family.support == BattleVolatileSupport.partial,
      )) {
        expect(family.note, isNotNull, reason: family.id);
        expect(family.note, isNotEmpty, reason: family.id);
      }
    });

    test('an implemented family is one no test names yet', () {
      // L'autre sens : écrire un test pour une famille encore `implemented`
      // fait échouer ce cas jusqu'à ce que son niveau soit relevé. La dette ne
      // peut donc pas être payée en silence, ni rester en place après avoir été
      // payée.
      final tested = _testedFamilyIds(engineIds);
      final implemented = battleVolatileCatalog
          .where(
              (family) => family.support == BattleVolatileSupport.implemented)
          .map((family) => family.id)
          .toSet();

      expect(implemented.intersection(tested), isEmpty);
    });

    test('every implemented family carries a note saying why it is one', () {
      // Une dette sans explication redevient un oubli au bout de deux mois.
      for (final family in battleVolatileCatalog.where(
        (family) => family.support == BattleVolatileSupport.implemented,
      )) {
        expect(family.note, isNotNull, reason: family.id);
        expect(family.note, isNotEmpty, reason: family.id);
      }
    });

    test('every volatile a move can request is certified, not merely present',
        () {
      // PsdkBattleVolatileStatus est le vocabulaire qu'une capacité importée
      // peut demander. Une valeur seulement `implemented` voudrait dire qu'une
      // capacité du catalogue pose une volatile dont personne n'a vérifié le
      // cycle de vie.
      for (final status in PsdkBattleVolatileStatus.values) {
        final family = battleVolatileCatalog
            .where((family) => family.id == status.name)
            .toList();
        expect(family, hasLength(1), reason: status.name);
        expect(
          family.single.support,
          BattleVolatileSupport.certified,
          reason: '${status.name} is a vocabulary a move can request, so a '
              'recorded gap on it would mean shipping a silent no-op',
        );
      }
    });

    test('the protection family is fully certified or fully accounted for', () {
      // « Protection » fait partie du minimum exigé par le ticket. Trois de ses
      // membres étaient atteignables sans aucun test le 2026-08-18 ; ce cas
      // empêche qu'un quatrième s'ajoute sans qu'on le remarque.
      const protection = <String>[
        'protect',
        'baneful_bunker',
        'burning_bulwark',
        'king_s_shield',
        'obstruct',
        'silk_trap',
        'spiky_shield',
      ];
      for (final id in protection) {
        final family =
            battleVolatileCatalog.where((family) => family.id == id).toList();
        expect(
          family,
          hasLength(1),
          reason: '$id must be catalogued as part of the protection family',
        );
      }
    });
  });
}
