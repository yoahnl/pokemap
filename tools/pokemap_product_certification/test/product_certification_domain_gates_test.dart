import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

/// Le registre des Golden Gates répond au dépôt — BETA-SYS-007.
///
/// « Assembler les Golden Gates des dix domaines » ne peut pas être fermé tant
/// que quatre gates de domaine n'existent pas. Ce que ce registre rend
/// impossible, c'est de s'en apercevoir trop tard : chaque chemin déclaré doit
/// exister sur disque, chaque dette est figée avec son ticket, et le verdict
/// d'assemblage est CALCULÉ — il restera NO-GO tant qu'une dette subsiste.
void main() {
  final repositoryRoot = p.normalize(p.join(Directory.current.path, '../..'));

  group('BETA-SYS-007 the domain gate registry answers to the repository', () {
    test('every declared gate file really exists', () {
      // Une gate fantôme est pire qu'une dette : elle a l'air de couvrir.
      final missing = <String>[
        for (final gate in productCertificationDomainGates)
          for (final path in gate.gateTestPaths)
            if (!File(p.join(repositoryRoot, path)).existsSync())
              '${gate.domain}: $path',
      ];

      expect(missing, isEmpty, reason: 'Gates fantômes :\n${missing.join('\n')}');
    });

    test('the registry is sorted and names every cockpit domain once', () {
      final domains = productCertificationDomainGates
          .map((gate) => gate.domain)
          .toList(growable: false);

      expect(domains.toSet(), hasLength(domains.length));
      expect(domains, orderedEquals(<String>[...domains]..sort()));
      // Douze familles au cockpit, moins l'agrégat gouvernance qui n'est pas un
      // domaine de gameplay : le registre doit rester exhaustif quand une
      // famille s'ajoute, et ce plancher le tient.
      expect(domains, hasLength(greaterThanOrEqualTo(11)));
    });

    test('a gated domain has gates, a pending one has a ticket', () {
      for (final gate in productCertificationDomainGates) {
        expect(gate.rationale, isNotEmpty, reason: gate.domain);
        switch (gate.coverage) {
          case DomainGateCoverage.gated:
            expect(gate.gateTestPaths, isNotEmpty, reason: gate.domain);
            expect(gate.pendingTicket, isNull,
                reason: '${gate.domain} se dit couvert ET endetté');
          case DomainGateCoverage.partial:
            expect(gate.gateTestPaths, isNotEmpty, reason: gate.domain);
            expect(gate.pendingTicket, isNotNull, reason: gate.domain);
          case DomainGateCoverage.pendingGate:
            expect(gate.gateTestPaths, isEmpty, reason: gate.domain);
            expect(gate.pendingTicket, isNotNull, reason: gate.domain);
        }
      }
    });

    test('the recorded debt is exactly these two tickets', () {
      // Figé à l'identique : livrer une golden gate de domaine sans reclasser
      // son entrée fait échouer la suite, donc l'assemblage ne peut ni se
      // dégrader ni se compléter en silence.
      final pending = <String>{
        for (final gate in productCertificationDomainGates)
          if (gate.pendingTicket != null) gate.pendingTicket!,
      };

      expect(pending, <String>{
        'BETA-ITM-008',
        'BETA-PRG-006',
      });
    });

    test('the assembled verdict stays NO-GO while any debt remains', () {
      // Le verdict est calculé, pas déclaré. Le jour où les quatre gates
      // livrent, ce cas s'inverse volontairement : il faudra alors l'assumer en
      // le retournant, ce qui est exactement le moment de prononcer le GO.
      expect(productCertificationDomainGatesComplete, isFalse);
    });

    test('every golden gate file in this package is declared in the registry',
        () {
      // Trou découvert en livrant la gate Party/PC : le registre figeait la
      // DÉCLARATION, mais une gate qui NAÎT sans être déclarée ne cassait
      // rien — elle couvrait son domaine en silence, invisible du verdict
      // d'assemblage. Les golden gates de ce paquet suivent une convention de
      // nom : le répertoire fait donc autorité, comme pour la composition de
      // la gate de jouabilité.
      final gateFiles = Directory('test')
          .listSync()
          .whereType<File>()
          .map((file) => p.basename(file.path))
          .where(
            (name) =>
                name.startsWith('golden_') && name.endsWith('_gate_test.dart'),
          )
          .toSet();
      final declared = <String>{
        for (final gate in productCertificationDomainGates)
          for (final path in gate.gateTestPaths)
            if (path.startsWith('tools/pokemap_product_certification/test/'))
              p.basename(path),
      };

      expect(gateFiles, isNotEmpty);
      expect(
        gateFiles.difference(declared),
        isEmpty,
        reason: 'une golden gate née sans être déclarée couvre son domaine en '
            'silence, hors du verdict d’assemblage',
      );
    });

    test('every package gate the registry declares is executed by the CI', () {
      // Le trou qui a motivé la lane : les Golden Gates de packages/ ne
      // tournaient JAMAIS en CI — le combat, le plus gros domaine de la bêta,
      // n'était exécuté sur aucun push. Ce cas interdit au registre et au
      // workflow de diverger : déclarer une gate sans l'exécuter fait échouer
      // la suite, dans les deux sens du fil.
      //
      // Les gates de tools/pokemap_product_certification sont couvertes par la
      // lane contracts (`flutter test` sur le paquet entier) et les workflows
      // se couvrent eux-mêmes : seuls les chemins packages/ exigent une mention
      // explicite.
      final workflow = File(
        p.join(
          repositoryRoot,
          '.github/workflows/pokemap_hub_product_certification.yml',
        ),
      ).readAsStringSync();

      final unexecuted = <String>[
        for (final gate in productCertificationDomainGates)
          for (final path in gate.gateTestPaths)
            if (path.startsWith('packages/') &&
                !workflow.contains(path.split('/').last))
              '${gate.domain}: $path',
      ];

      expect(
        unexecuted,
        isEmpty,
        reason: 'Gates déclarées mais jamais exécutées en CI :\n'
            '${unexecuted.join('\n')}',
      );
    });
  });
}
