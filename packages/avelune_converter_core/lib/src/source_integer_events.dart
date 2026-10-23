part of '../avelune_converter_core.dart';

enum SourceIntegerOperandKind { literal, variable, partyCount, money, random }

final class SourceIntegerOperand {
  const SourceIntegerOperand._(this.kind, {this.value, this.variableId,
      this.factId, this.minimum, this.maximum});
  const SourceIntegerOperand.literal(int value)
      : this._(SourceIntegerOperandKind.literal, value: value);
  const SourceIntegerOperand.variable(int variableId, String factId)
      : this._(SourceIntegerOperandKind.variable, variableId: variableId, factId: factId);
  const SourceIntegerOperand.partyCount() : this._(SourceIntegerOperandKind.partyCount);
  const SourceIntegerOperand.money() : this._(SourceIntegerOperandKind.money);
  const SourceIntegerOperand.random(int minimum, int maximum)
      : this._(SourceIntegerOperandKind.random, minimum: minimum, maximum: maximum);
  final SourceIntegerOperandKind kind;
  final int? value, variableId, minimum, maximum;
  final String? factId;
  bool get isQualified => switch (kind) {
    SourceIntegerOperandKind.literal => value != null && value!.abs() <= 9007199254740991,
    SourceIntegerOperandKind.variable => variableId != null && variableId! > 0 && factId != null,
    SourceIntegerOperandKind.partyCount || SourceIntegerOperandKind.money => true,
    SourceIntegerOperandKind.random => minimum != null && maximum != null &&
      minimum! <= maximum! && minimum!.abs() <= 9007199254740991 && maximum!.abs() <= 9007199254740991 &&
      BigInt.from(maximum!) - BigInt.from(minimum!) + BigInt.one <= BigInt.from(4294967296),
  };
  int? evaluate({Map<int, int> variables = const {}, int? money, int? partyCount}) => switch (kind) {
    SourceIntegerOperandKind.literal => value,
    SourceIntegerOperandKind.variable => variables[variableId] ?? 0,
    SourceIntegerOperandKind.money => money,
    SourceIntegerOperandKind.partyCount => partyCount,
    SourceIntegerOperandKind.random => null,
  };
  Map<String, Object?> toJson() => {
    'kind': kind.name, if (value != null) 'value': value,
    if (variableId != null) 'variableId': variableId, if (factId != null) 'factId': factId,
    if (minimum != null) 'minimum': minimum, if (maximum != null) 'maximum': maximum,
  };
}

final class SourceVariableCalculationNode extends SourceEventNode {
  SourceVariableCalculationNode(super.span, {required this.firstId, required this.lastId,
      required this.operation, required this.operand, required List<String> factIds,
      required this.profileHash}) : factIds = List.unmodifiable(factIds);
  final int firstId, lastId, operation;
  final SourceIntegerOperand operand;
  final List<String> factIds;
  final Sha256Hash profileHash;
  Map<String, Object?> toJson() => {
    'kind': 'integerVariableCalculation', 'span': span.toJson(),
    'firstId': firstId, 'lastId': lastId, 'operation': operation,
    'operand': operand.toJson(), 'factIds': factIds,
    'minimum': -99999999, 'maximum': 99999999,
    'boundaryPolicy': 'preserveSaturated', 'zeroDivisorPolicy': 'keepValueForZeroOrOne',
    'operandEvaluation': 'onceBeforeTargetRange', 'profileHash': profileHash.value,
  };
}

final class SourceIntegerInputNode extends SourceEventNode {
  const SourceIntegerInputNode(super.span, {required this.variableId,
      required this.factId, required this.digits, required this.profileHash});
  final int variableId, digits;
  final String factId;
  final Sha256Hash profileHash;
  int get maximum => math.pow(10, digits).toInt() - 1;
  Map<String, Object?> toJson() => {
    'kind': 'integerInput', 'span': span.toJson(), 'variableId': variableId,
    'factId': factId, 'digits': digits, 'minimum': 0, 'maximum': maximum,
    'initialValue': 'clampedCurrentVariable', 'cancellation': 'restoreInitialAndComplete',
    'profileHash': profileHash.value,
  };
}

final class SourceMoneyAdjustmentNode extends SourceEventNode {
  const SourceMoneyAdjustmentNode(super.span, {required this.subtract,
      required this.operand, required this.maximum, required this.profileHash});
  final bool subtract;
  final SourceIntegerOperand operand;
  final int maximum;
  final Sha256Hash profileHash;
  Map<String, Object?> toJson() => {
    'kind': 'moneyAdjustment', 'span': span.toJson(), 'subtract': subtract,
    'operand': operand.toJson(), 'minimum': 0, 'maximum': maximum,
    'insufficientFunds': 'clampAndContinue', 'profileHash': profileHash.value,
  };
}

int? sourceEventMoneyMaximum(NormalizedSourceProject source) {
  final profile = source.interpretationProfile;
  final pin = profile?.sections['events.Settings'];
  if (profile == null || pin == null) return null;
  final files = source.sourceFiles.values.where((file) =>
      file.entry.relativePath == profile.scriptsRelativePath &&
      profile.matchesArchive(file.contentHash) && !file.isAdapted).toList();
  if (files.length != 1) return null;
  try {
    final doc = files.single.document;
    final root = doc.node(doc.rootId);
    final index = pin['index'] as int;
    if (root.kind != MarshalKind.array || index >= root.elements.length) return null;
    final row = doc.node(root.elements[index]);
    if (row.kind != MarshalKind.array || row.elements.length != 3) return null;
    final data = doc.node(row.elements[2]);
    if (data.kind != MarshalKind.string || data.bytes == null) return null;
    final bytes = const BoundedZlibDecoder().decode(data.bytes!);
    if (sha256.convert(bytes).toString() != pin['sha256']) return null;
    final text = utf8.decode(bytes, allowMalformed: false);
    final matches = RegExp(r'^\s*MAX_MONEY\s*=\s*([0-9][0-9_]*)\s*(?:#[^\r\n]*)?$', multiLine: true)
        .allMatches(text.replaceAll('\r', '')).toList();
    if (matches.length != 1) return null;
    final value = BigInt.tryParse(matches.single.group(1)!.replaceAll('_', ''));
    if (value == null || value < BigInt.zero || value > BigInt.from(9007199254740991)) return null;
    return value.toInt();
  } on Object {
    return null;
  }
}
