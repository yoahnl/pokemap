import 'package:map_core/map_core_domain.dart';

import 'scene_integer_authoring_fields.dart';

class SceneIntegerConditionDraft {
  SceneIntegerConditionDraft({
    required this.project,
    required this.changed,
    this.current,
    this.loadItems,
  }) {
    reset();
  }

  ProjectManifest project;
  SceneConditionSource? current;
  Future<Map<String, String>> Function()? loadItems;
  final void Function() changed;
  SceneIntegerOperand? left, right;
  NarrativeFactOperator comparison = NarrativeFactOperator.equals;
  Map<String, String> items = const {};
  bool loading = false;
  int _request = 0;
  bool _disposed = false;

  Map<String, String> get facts => integerSceneOptions(
    NarrativeCommandParameterKind.integerFacts,
    project: project,
    commandId: null,
  )!;

  void configure({
    required ProjectManifest project,
    required SceneConditionSource? current,
    required Future<Map<String, String>> Function()? loadItems,
  }) {
    final shouldReset =
        this.project != project ||
        this.current != current ||
        this.loadItems != loadItems;
    this.project = project;
    this.current = current;
    this.loadItems = loadItems;
    if (shouldReset) reset();
  }

  void reset() {
    left = current?.integerLeft ?? SceneIntegerOperand.literal(0);
    right = current?.integerRight ?? SceneIntegerOperand.literal(0);
    comparison =
        current?.integerComparisonOperator ?? NarrativeFactOperator.equals;
    refreshItems();
  }

  Future<void> refreshItems() async {
    final request = ++_request;
    items = const {};
    loading = loadItems != null;
    try {
      final result = await loadItems?.call() ?? const <String, String>{};
      if (!_disposed && request == _request) {
        items = result;
        changed();
      }
    } on Object {
      if (!_disposed && request == _request) {
        items = const {};
        changed();
      }
    } finally {
      if (!_disposed && request == _request) {
        loading = false;
        changed();
      }
    }
  }

  bool valid(SceneIntegerOperand? operand) =>
      operand != null &&
      (operand.factId == null || facts.containsKey(operand.factId)) &&
      (operand.itemId == null || !loading && items.containsKey(operand.itemId));

  SceneConditionSource? get prepared => !valid(left) || !valid(right)
      ? null
      : SceneConditionSource.integerComparison(
          left: left!,
          comparison: comparison,
          right: right!,
          label: current?.label,
          debugTechnicalLabel: current?.debugTechnicalLabel,
        );

  void dispose() {
    _disposed = true;
    _request++;
  }
}

class SceneIntegerOperandDraft {
  SceneIntegerOperandDraft({
    required SceneIntegerOperand value,
    required Map<String, String> facts,
    required Map<String, String> items,
  }) : source = value.kind == SceneIntegerOperandKind.gameRead
           ? value.read!.name
           : value.kind.name,
       number = '${value.value ?? 0}',
       factId = value.factId ?? facts.keys.firstOrNull,
       itemId = value.itemId ?? items.keys.firstOrNull;

  String source, number;
  String? factId, itemId;

  SceneIntegerOperand? prepare({
    required Map<String, String> facts,
    required Map<String, String> items,
  }) {
    try {
      return switch (source) {
        'literal' =>
          int.tryParse(number) == null
              ? null
              : SceneIntegerOperand.literal(int.parse(number)),
        'integerFact' =>
          facts.containsKey(factId)
              ? SceneIntegerOperand.integerFact(factId!)
              : null,
        'money' => SceneIntegerOperand.gameRead(SceneIntegerGameRead.money),
        'partyCount' => SceneIntegerOperand.gameRead(
          SceneIntegerGameRead.partyCount,
        ),
        'itemCount' =>
          items.containsKey(itemId)
              ? SceneIntegerOperand.gameRead(
                  SceneIntegerGameRead.itemCount,
                  itemId: itemId,
                )
              : null,
        _ => null,
      };
    } on ArgumentError {
      return null;
    }
  }
}
