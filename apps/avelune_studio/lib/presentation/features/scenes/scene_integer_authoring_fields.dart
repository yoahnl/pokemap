import 'package:map_core/map_core.dart';

bool isIntegerSceneCommand(String? id) => const {
  NarrativeCommandIds.calculateIntegerFacts, NarrativeCommandIds.adjustMoney,
  NarrativeCommandIds.inputIntegerToFact, NarrativeCommandIds.tryPayMoney,
}.contains(id);

bool integerSceneParameterVisible(String id, Map<String, String> values) => switch (id) {
  'operandValue' => values['operandSource'] == 'literal',
  'operandFactId' => values['operandSource'] == 'integerFact',
  'operandItemId' => values['operandSource'] == 'itemCount',
  'randomMinimum' || 'randomMaximum' => values['operandSource'] == 'random',
  'zeroDivisorPolicy' => values['operation'] == 'floorDivide' || values['operation'] == 'modulo',
  _ => true,
};

Object? integerSceneStoredParameter(Map<String, dynamic> data, String id) {
  final operand = data['operand'] ?? data['amount'];
  if (operand is Map) {
    if (id == 'operandSource') return operand['kind'] == 'gameRead' ? operand['read'] : operand['kind'];
    if (id == 'operandValue') return operand['value'];
    if (id == 'operandFactId') return operand['factId'];
    if (id == 'operandItemId') return operand['itemId'];
    if (id == 'randomMinimum') return operand['minimum'];
    if (id == 'randomMaximum') return operand['maximum'];
  }
  final value = data[id];
  if (value is Map && (id == 'prompt' || id == 'confirmationPrompt')) return value['fallbackText'];
  return value;
}

Map<String, String>? integerSceneOptions(NarrativeCommandParameterKind kind, {required ProjectManifest project, required String? commandId}) => switch (kind) {
  NarrativeCommandParameterKind.integerFacts => {for (final fact in project.facts)
    if (fact.valueKind == NarrativeValueKind.integer && project.facts.where((other) => other.id == fact.id).length == 1) fact.id: fact.label},
  NarrativeCommandParameterKind.fact when isIntegerSceneCommand(commandId) => {for (final fact in project.facts)
    if (fact.valueKind == NarrativeValueKind.integer && project.facts.where((other) => other.id == fact.id).length == 1) fact.id: fact.label},
  NarrativeCommandParameterKind.integerOperation => const {'assign': 'Affecter', 'add': 'Ajouter', 'subtract': 'Soustraire', 'multiply': 'Multiplier', 'floorDivide': 'Diviser (arrondi inférieur)', 'modulo': 'Reste de division'},
  NarrativeCommandParameterKind.moneyOperation => const {'add': 'Ajouter', 'subtract': 'Retirer'},
  NarrativeCommandParameterKind.integerOperandSource => {
    'literal': 'Nombre fixe', 'integerFact': 'Compteur', 'money': 'Argent du joueur', 'partyCount': 'Taille de l’équipe', 'itemCount': 'Quantité d’un objet',
    if (commandId == NarrativeCommandIds.calculateIntegerFacts) 'random': 'Tirage aléatoire sauvegardé',
  },
  NarrativeCommandParameterKind.integerZeroPolicy => const {'reject': 'Refuser si nul', 'keepValue': 'Conserver si nul', 'keepValueForZeroOrOne': 'Conserver si nul ou égal à un'},
  NarrativeCommandParameterKind.integerBoundaryPolicy => const {'clamp': 'Limiter le résultat', 'preserveSaturated': 'Conserver les limites et opérations sans changement'},
  NarrativeCommandParameterKind.integerCancellationPolicy => const {'leaveUnchanged': 'Conserver le compteur et suivre Annulé', 'restoreInitialAndComplete': 'Écrire la valeur initiale et continuer'},
  _ => null,
};
