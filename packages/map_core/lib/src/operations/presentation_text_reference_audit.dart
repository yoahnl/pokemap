import 'package:meta/meta.dart' show immutable;

import '../models/presentation_text_interpolation.dart';

/// Ce qu'un audit peut reprocher à une référence d'interpolation.
enum PresentationTextReferenceDefect {
  /// Une seule accolade là où la forme canonique en veut deux. L'interpolateur
  /// ne reconnaît pas la référence, la laisse littérale par doctrine, et le
  /// joueur lit `{draft.playerName}`.
  singleBrace,

  /// Deux accolades, mais un espace de noms que l'interpolateur ne connaît pas.
  /// Même conséquence : le texte reste littéral.
  unknownNamespace,

  /// `draft` est un ensemble FERMÉ : le champ n'existe pas, donc rien ne le
  /// résoudra jamais, quel que soit l'état du joueur.
  unknownDraftField,
}

@immutable
final class PresentationTextReferenceIssue {
  const PresentationTextReferenceIssue({
    required this.defect,
    required this.reference,
  });

  final PresentationTextReferenceDefect defect;

  /// La référence telle qu'elle est écrite, `namespace.name`. Jamais une
  /// valeur : ce texte part dans des diagnostics et des reçus.
  final String reference;

  String get message => switch (defect) {
        PresentationTextReferenceDefect.singleBrace =>
          '« {$reference} » s’écrit « {{$reference}} ». Avec une seule '
              'accolade, la référence reste affichée telle quelle au joueur.',
        PresentationTextReferenceDefect.unknownNamespace =>
          '« {{$reference}} » ne désigne aucun espace de noms connu '
              '(draft, scene, execution). Le texte restera littéral.',
        PresentationTextReferenceDefect.unknownDraftField =>
          '« {{$reference}} » ne correspond à aucun champ de brouillon. '
              'Les champs disponibles sont ${_knownDraftFields.join(', ')}.',
      };

  @override
  bool operator ==(Object other) =>
      other is PresentationTextReferenceIssue &&
      other.defect == defect &&
      other.reference == reference;

  @override
  int get hashCode => Object.hash(defect, reference);

  @override
  String toString() => 'PresentationTextReferenceIssue(${defect.name}, '
      '$reference)';
}

/// Les défauts d'interpolation d'un texte authoré, avant qu'il n'atteigne un
/// joueur.
///
/// L'interpolateur de BETA-CIN-071 laisse littérale toute référence qu'il ne
/// reconnaît pas, et c'est délibéré : un nom silencieusement vide est un bug
/// d'authoring caché à l'auteur. Sauf que rien ne regardait ce texte avant la
/// certification, donc le placeholder était révélé au joueur plutôt qu'à
/// l'auteur — c'est exactement ce qui est arrivé à la fixture Night Watch.
///
/// La grammaire reproduite ici est celle de `interpolatePresentationText`, pas
/// une approximation : un audit qui ne serait pas d'accord avec l'interpolateur
/// produirait des faux positifs sur du texte parfaitement valide.
///
/// `scene` et `execution` sont des ensembles OUVERTS, peuplés à l'exécution :
/// leurs noms ne peuvent pas être vérifiés statiquement et ne le sont pas.
List<PresentationTextReferenceIssue> auditPresentationTextReferences(
  String text,
) {
  final issues = <PresentationTextReferenceIssue>[];

  // Les formes canoniques d'abord, puis on les efface : sans cela le motif à
  // une accolade retrouverait l'intérieur de `{{draft.playerName}}`.
  var residue = text.replaceAllMapped(_canonicalPattern, (match) {
    if (match.group(1) == null) {
      final namespace = match.group(2)!;
      final name = match.group(3)!;
      if (namespace == 'draft' && !_knownDraftFields.contains(name)) {
        issues.add(
          PresentationTextReferenceIssue(
            defect: PresentationTextReferenceDefect.unknownDraftField,
            reference: '$namespace.$name',
          ),
        );
      }
    }
    return _erase(match.group(0)!);
  });

  residue = residue.replaceAllMapped(_foreignNamespacePattern, (match) {
    if (match.group(1) == null) {
      issues.add(
        PresentationTextReferenceIssue(
          defect: PresentationTextReferenceDefect.unknownNamespace,
          reference: '${match.group(2)!}.${match.group(3)!}',
        ),
      );
    }
    return _erase(match.group(0)!);
  });

  for (final match in _singleBracePattern.allMatches(residue)) {
    if (match.group(1) != null) continue;
    issues.add(
      PresentationTextReferenceIssue(
        defect: PresentationTextReferenceDefect.singleBrace,
        reference: '${match.group(2)!}.${match.group(3)!}',
      ),
    );
  }

  return List<PresentationTextReferenceIssue>.unmodifiable(issues);
}

/// Remplace une occurrence par un blanc de même longueur : les positions des
/// références restantes ne bougent pas, et il ne reste aucune accolade pour
/// faire tomber le motif suivant dans le piège.
String _erase(String match) => ' ' * match.length;

final _knownDraftFields = <String>{
  for (final field in PresentationDraftInterpolationField.values)
    field.referenceName,
};

/// Le motif de `interpolatePresentationText`, à l'identique.
final _canonicalPattern = RegExp(
  r'(\\)?\{\{\s*(draft|scene|execution)\.([A-Za-z_][A-Za-z0-9_-]*)\s*\}\}',
);

final _foreignNamespacePattern = RegExp(
  r'(\\)?\{\{\s*([A-Za-z_][A-Za-z0-9_-]*)\.([A-Za-z_][A-Za-z0-9_-]*)\s*\}\}',
);

final _singleBracePattern = RegExp(
  r'(\\)?\{\s*(draft|scene|execution)\.([A-Za-z_][A-Za-z0-9_-]*)\s*\}',
);
