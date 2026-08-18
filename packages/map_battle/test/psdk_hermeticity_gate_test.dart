import 'dart:io';

import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

/// Herméticité de la suite (BETA-BAT-008).
///
/// L'exigence du ticket est explicite : « la gate ne doit pas nécessiter un
/// checkout PSDK externe, le réseau ou un cache développeur ».
///
/// Or `resolvePsdkSourceDirectories` rend TOUJOURS des chemins, présents ou non :
/// il cherche l'arborescence Ruby de PSDK dans un dossier voisin du dépôt. Sur la
/// machine de développement ce voisin existe, donc les suites qui la lisent
/// passent ; sur une machine propre, elles échouent au lieu de se déclarer non
/// applicables. Mesuré le 2026-08-18 : avec une racine de dépôt isolée, le
/// répertoire résolu n'existe pas et la vérification des chemins source rend
/// faux.
///
/// Quatre suites de ce paquet lisaient l'arborescence externe sans se garder, et
/// les 18 vecteurs de dégâts ajoutés pour BETA-BAT-002 avaient multiplié cette
/// dépendance. Elles déclarent désormais `skip: psdkSourcesAvailable() ? ...`.
///
/// Ce fichier empêche la dépendance de revenir en silence : il relit la source
/// des tests et exige que tout fichier appelant le résolveur SANS racine
/// explicite déclare aussi le prédicat de disponibilité.
void main() {
  group('BETA-BAT-008 the suite runs without an external PSDK checkout', () {
    test('the availability predicate answers no on a bare repository', () {
      final bare = Directory.systemTemp.createTempSync('psdk_absent_');
      addTearDown(() => bare.deleteSync(recursive: true));

      expect(psdkSourcesAvailable(repositoryRoot: bare), isFalse);
    });

    test('the availability predicate answers yes on a populated sibling', () {
      // Contraste : sans lui, le prédicat pourrait rendre faux partout et le
      // premier cas passerait pour la mauvaise raison.
      final temp = Directory.systemTemp.createTempSync('psdk_present_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final repository = Directory('${temp.path}/repo')..createSync();
      final container = Directory('${temp.path}/sibling');
      Directory('${container.path}/pokémon_sdk_test_project/Data/Studio/moves')
          .createSync(recursive: true);
      Directory('${container.path}/pokemonsdk-development/scripts/5 Battle')
          .createSync(recursive: true);

      expect(psdkSourcesAvailable(repositoryRoot: repository), isTrue);
    });

    test('no suite reads the external tree without declaring it skippable', () {
      final offenders = <String>[];
      for (final file in _testSources()) {
        final source = file.readAsStringSync();
        if (!_readsExternalTree(source)) continue;
        if (source.contains('psdkSourcesAvailable')) continue;
        offenders.add(file.path.split('/').last);
      }

      expect(
        offenders,
        isEmpty,
        reason: 'these suites would fail on a machine without the PSDK sources '
            'instead of skipping: ${offenders.join(', ')}',
      );
    });

    test('the scan recognises a suite that does read the external tree', () {
      // Garde-fou du garde-fou : si `_readsExternalTree` cessait de reconnaître
      // quoi que ce soit, le cas précédent deviendrait vide.
      final matching = _testSources()
          .where((file) => _readsExternalTree(file.readAsStringSync()))
          .length;

      expect(
        matching,
        greaterThanOrEqualTo(4),
        reason: 'four suites read the Ruby tree as of 2026-08-18',
      );
    });
  });
}

/// Un fichier lit-il l'arborescence externe ?
///
/// Le critère est l'appel au résolveur SANS `repositoryRoot`. Avec une racine
/// explicite, le test fabrique ses propres dossiers et reste hermétique — c'est
/// le cas de `psdk_source_locator_test`, qu'il ne faut pas compter comme
/// coupable.
bool _readsExternalTree(String source) {
  for (final match
      in RegExp(r'resolvePsdkSourceDirectories\(([^)]*)\)').allMatches(source)) {
    if (!(match.group(1) ?? '').contains('repositoryRoot')) {
      return true;
    }
  }
  return false;
}

List<File> _testSources() {
  final directory = Directory('test');
  if (!directory.existsSync()) {
    throw StateError('Run this suite from packages/map_battle.');
  }
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('_test.dart'))
      .where((file) => !file.path.endsWith('psdk_hermeticity_gate_test.dart'))
      .toList(growable: false);
}
