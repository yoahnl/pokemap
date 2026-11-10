import 'package:map_core/map_core.dart';

class SceneDialogueChoicePolicyDraft {
  SceneDialogueChoicePolicyDraft({
    required this.scene,
    required this.nodeId,
    required this.payload,
    required this.document,
  }) {
    readDocument();
  }
  SceneAsset scene;
  String nodeId;
  SceneYarnDialoguePayload payload;
  RuntimeDialogueDocument document;
  void configure({
    required SceneAsset scene,
    required String nodeId,
    required SceneYarnDialoguePayload payload,
    required RuntimeDialogueDocument document,
  }) {
    final changed =
        this.scene != scene ||
        this.nodeId != nodeId ||
        this.payload != payload ||
        this.document != document;
    if (this.nodeId != nodeId || this.document != document) scopeIndex = 0;
    this.scene = scene;
    this.nodeId = nodeId;
    this.payload = payload;
    this.document = document;
    if (changed) readDocument();
  }

  SceneDialogueChoicePolicy? get prepared =>
      scopes.isEmpty || !defaultValid || !targetValid
      ? null
      : SceneDialogueChoicePolicy(
          nodeName: scope.nodeName,
          choiceIndex: scope.choiceIndex,
          defaultOutcomeId: defaultOutcome.isEmpty ? null : defaultOutcome,
          cancellation: switch (cancellation) {
            SceneDialogueChoiceCancellationKind.disabled =>
              const SceneDialogueChoiceCancellation.disabled(),
            SceneDialogueChoiceCancellationKind.choice =>
              SceneDialogueChoiceCancellation.choice(target!),
            SceneDialogueChoiceCancellationKind.branch =>
              SceneDialogueChoiceCancellation.branch(target!),
          },
        );
  List<SceneDialogueChoiceScope> scopes = const [];
  final blocks = <(String, int), RuntimeDialogueChoiceBlock>{};
  Map<String, String> branches = const {};
  int scopeIndex = 0;
  String defaultOutcome = '';
  SceneDialogueChoiceCancellationKind cancellation =
      SceneDialogueChoiceCancellationKind.disabled;
  String? target;

  SceneDialogueChoiceScope get scope => scopes[scopeIndex];

  RuntimeDialogueChoiceBlock get block =>
      blocks[(scope.nodeName, scope.choiceIndex)]!;

  void readDocument() {
    scopes = sceneDialogueChoiceScopes(document);
    blocks.clear();
    for (final node in document.nodes) {
      var index = 0;
      void visit(List<RuntimeDialogueStep> steps) {
        for (final step in steps) {
          if (step is! RuntimeDialogueChoiceBlock) continue;
          blocks[(node.title, index++)] = step;
          for (final choice in step.choices) {
            visit(choice.steps);
          }
        }
      }

      visit(node.steps);
    }
    final emitted = {
      for (final block in blocks.values)
        for (final choice in block.choices) choice.outcomeId,
    };
    branches = {};
    for (final outcome in payload.expectedOutcomes) {
      if (emitted.contains(outcome)) continue;
      final edges = scene.graph.edges.where(
        (edge) =>
            edge.fromNodeId == nodeId &&
            edge.fromPortId == outcome &&
            edge.kind == SceneEdgeKind.dialogueOutcome,
      );
      if (edges.length != 1) continue;
      final target = scene.graph.nodes
          .where((node) => node.id == edges.single.toNodeId)
          .firstOrNull;
      if (target == null) continue;
      final title = target.title?.trim();
      branches[outcome] = title == null || title.isEmpty
          ? 'Branche ${branches.length + 1}'
          : title;
    }
    if (scopeIndex >= scopes.length) scopeIndex = 0;
    if (scopes.isNotEmpty) readPolicy();
  }

  void readPolicy() {
    final current = payload.choicePolicies
        .where(
          (policy) =>
              policy.nodeName == scope.nodeName &&
              policy.choiceIndex == scope.choiceIndex,
        )
        .firstOrNull;
    defaultOutcome = current?.defaultOutcomeId ?? '';
    cancellation =
        current?.cancellation.kind ??
        SceneDialogueChoiceCancellationKind.disabled;
    target = current?.cancellation.outcomeId;
  }

  Map<String, String> get choices => {
    for (final choice in block.choices)
      if (choice.outcomeId != null &&
          payload.expectedOutcomes.contains(choice.outcomeId) &&
          block.choices
                  .where((other) => other.outcomeId == choice.outcomeId)
                  .length ==
              1)
        choice.outcomeId!: choice.text,
  };

  Map<String, String> get targets => switch (cancellation) {
    SceneDialogueChoiceCancellationKind.disabled => const {},
    SceneDialogueChoiceCancellationKind.choice => choices,
    SceneDialogueChoiceCancellationKind.branch => branches,
  };

  bool get defaultValid =>
      defaultOutcome.isEmpty || choices.containsKey(defaultOutcome);

  bool get targetValid =>
      cancellation == SceneDialogueChoiceCancellationKind.disabled ||
      targets.containsKey(target);
}
