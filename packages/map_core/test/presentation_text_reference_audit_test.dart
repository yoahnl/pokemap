import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

/// L'audit doit être d'accord avec `interpolatePresentationText`.
///
/// Un audit plus strict que l'interpolateur refuserait du texte parfaitement
/// valide, et un audit plus permissif laisserait passer ce qu'il est là pour
/// attraper. Les deux moitiés sont donc testées : ce qui doit être signalé, et
/// ce qui doit rester silencieux.
void main() {
  group('ce que l’audit doit attraper', () {
    test('une seule accolade, la faute qui a atteint un vrai joueur', () {
      expect(
        auditPresentationTextReferences(
          'Le registre dira donc {draft.playerName}. C’est bien cela ?',
        ),
        const <PresentationTextReferenceIssue>[
          PresentationTextReferenceIssue(
            defect: PresentationTextReferenceDefect.singleBrace,
            reference: 'draft.playerName',
          ),
        ],
      );
    });

    test('un champ de brouillon qui n’existe pas', () {
      expect(
        auditPresentationTextReferences('Bonjour {{draft.nickname}}.'),
        const <PresentationTextReferenceIssue>[
          PresentationTextReferenceIssue(
            defect: PresentationTextReferenceDefect.unknownDraftField,
            reference: 'draft.nickname',
          ),
        ],
      );
    });

    test('un espace de noms inconnu', () {
      expect(
        auditPresentationTextReferences('Tu as reçu {{item.name}}.'),
        const <PresentationTextReferenceIssue>[
          PresentationTextReferenceIssue(
            defect: PresentationTextReferenceDefect.unknownNamespace,
            reference: 'item.name',
          ),
        ],
      );
    });

    test('plusieurs fautes dans la même phrase sont toutes rapportées', () {
      final issues = auditPresentationTextReferences(
        '{draft.playerName} et {{draft.nickname}} et {{item.name}}.',
      );
      expect(
        issues.map((issue) => issue.defect).toSet(),
        PresentationTextReferenceDefect.values.toSet(),
      );
    });

    test('le message dit comment corriger, pas seulement que c’est faux', () {
      final issue = auditPresentationTextReferences(
        '{draft.playerName}',
      ).single;
      expect(issue.message, contains('{{draft.playerName}}'));
    });
  });

  group('ce que l’audit doit laisser passer', () {
    test('la forme canonique — le faux positif à ne jamais produire', () {
      // `{{draft.playerName}}` CONTIENT `{draft.playerName}` : un motif naïf à
      // une accolade retrouve l'intérieur de la forme correcte et refuse le
      // texte valide.
      expect(
        auditPresentationTextReferences(
          'Le registre dira donc {{draft.playerName}}. C’est bien cela ?',
        ),
        isEmpty,
      );
    });

    test('les espaces internes, que la grammaire autorise', () {
      expect(
        auditPresentationTextReferences('Bonjour {{ draft.playerName }}.'),
        isEmpty,
      );
    });

    test('une référence échappée est un littéral voulu', () {
      expect(
        auditPresentationTextReferences(r'Écris \{{draft.playerName}} ainsi.'),
        isEmpty,
      );
    });

    test('scene et execution sont des ensembles ouverts', () {
      expect(
        auditPresentationTextReferences(
          '{{scene.rivalName}} arrive en {{execution.locale}}.',
        ),
        isEmpty,
      );
    });

    test('chaque champ de brouillon déclaré est accepté', () {
      for (final field in PresentationDraftInterpolationField.values) {
        expect(
          auditPresentationTextReferences('Salut ${field.placeholder}.'),
          isEmpty,
          reason: '${field.name} est un champ déclaré',
        );
      }
    });

    test('du texte sans référence, accolades comprises', () {
      expect(auditPresentationTextReferences('Un { et un } tout seuls.'), isEmpty);
      expect(auditPresentationTextReferences('{}'), isEmpty);
      expect(auditPresentationTextReferences(''), isEmpty);
      expect(auditPresentationTextReferences('{notanamespace.field}'), isEmpty);
    });
  });
}
