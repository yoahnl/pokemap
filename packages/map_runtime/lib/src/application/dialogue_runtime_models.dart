import 'package:map_core/map_core.dart';

sealed class YarnStep {}

class YarnStepLine extends YarnStep {
  YarnStepLine(
    this.text, {
    this.characterId,
    this.portraitStateId,
    this.feedback,
  }) {
    feedback?.validateText(text);
  }
  final String text;
  final String? characterId;
  final String? portraitStateId;
  final DialogueLineFeedback? feedback;
}

class YarnStepJump extends YarnStep {
  YarnStepJump(this.targetNode);
  final String targetNode;
}

class YarnStepChoiceBlock extends YarnStep {
  YarnStepChoiceBlock(this.choices, {this.policy});
  final List<YarnChoice> choices;
  final SceneDialogueChoicePolicy? policy;
}

class YarnChoice {
  YarnChoice({required this.text, required this.steps, this.outcomeId});
  final String text;
  final List<YarnStep> steps;
  final String? outcomeId;
}

class YarnNode {
  const YarnNode({required this.title, required this.steps});
  final String title;
  final List<YarnStep> steps;
}

sealed class DialogueSessionState {}

class DialogueShowingLine extends DialogueSessionState {
  DialogueShowingLine({
    required this.text,
    this.characterId,
    this.portraitStateId,
    this.feedback,
  }) {
    feedback?.validateText(text);
  }
  final String text;
  final String? characterId;
  final String? portraitStateId;
  final DialogueLineFeedback? feedback;
}

class DialogueWaitingForChoice extends DialogueSessionState {
  DialogueWaitingForChoice(
      {required this.choices, required this.selectedIndex, this.policy});
  final List<YarnChoice> choices;
  final int selectedIndex;
  final SceneDialogueChoicePolicy? policy;
}

class DialogueSession {
  DialogueSession._({
    required this.nodes,
    required this.state,
    required String? currentNodeTitle,
    required List<YarnStep> currentSteps,
    required int stepIndex,
    required String? selectedOutcomeId,
  })  : _currentNodeTitle = currentNodeTitle,
        _currentSteps = currentSteps,
        _stepIndex = stepIndex,
        _selectedOutcomeId = selectedOutcomeId;

  final List<YarnNode> nodes;
  final DialogueSessionState state;
  final String? _currentNodeTitle;
  final List<YarnStep> _currentSteps;
  final int _stepIndex;
  final String? _selectedOutcomeId;

  DialogueSession withLinePolicies(List<SceneDialogueLinePolicy> policies) {
    final scopes = <SceneDialogueLineScope>[];
    final mappedLists = Map<List<YarnStep>, List<YarnStep>>.identity();
    final byScope = {for (final policy in policies) (policy.nodeName, policy.lineIndex): policy.feedback};
    final configured = <YarnNode>[];
    for (final node in nodes) {
      var lineIndex = 0;
      List<YarnStep> visit(List<YarnStep> steps) {
        final result = <YarnStep>[];
        mappedLists[steps] = result;
        for (final step in steps) {
          switch (step) {
            case YarnStepLine():
              final index = lineIndex++;
              scopes.add(SceneDialogueLineScope(nodeName: node.title, lineIndex: index,
                text: step.text, feedback: step.feedback));
              result.add(YarnStepLine(step.text, characterId: step.characterId,
                portraitStateId: step.portraitStateId,
                feedback: byScope[(node.title, index)] ?? step.feedback));
            case YarnStepChoiceBlock():
              result.add(YarnStepChoiceBlock([
                for (final choice in step.choices)
                  YarnChoice(text: choice.text, outcomeId: choice.outcomeId, steps: visit(choice.steps)),
              ], policy: step.policy));
            case YarnStepJump():
              result.add(step);
          }
        }
        return result;
      }
      configured.add(YarnNode(title: node.title, steps: visit(node.steps)));
    }
    validateSceneDialogueLinePolicies(scopes, policies);
    final current = mappedLists[_currentSteps];
    if (current == null) throw ArgumentError('Dialogue line policy requires a current node scope.');
    final step = current[_stepIndex];
    return DialogueSession._(nodes: configured,
      state: step is YarnStepLine
          ? DialogueShowingLine(text: step.text, characterId: step.characterId,
              portraitStateId: step.portraitStateId, feedback: step.feedback)
          : state,
      currentNodeTitle: _currentNodeTitle, currentSteps: current,
      stepIndex: _stepIndex, selectedOutcomeId: _selectedOutcomeId);
  }

  Iterable<DialogueLineFeedback> get lineFeedback sync* {
    Iterable<DialogueLineFeedback> visit(List<YarnStep> steps) sync* {
      for (final step in steps) {
        if (step is YarnStepLine && step.feedback != null) yield step.feedback!;
        if (step is YarnStepChoiceBlock) {
          for (final choice in step.choices) {
            yield* visit(choice.steps);
          }
        }
      }
    }
    for (final node in nodes) {
      yield* visit(node.steps);
    }
  }

  String? get currentNodeTitle => _currentNodeTitle;
  String? get selectedOutcomeId => _selectedOutcomeId;

  DialogueSession withChoicePolicies(List<SceneDialogueChoicePolicy> policies) {
    final scopes = <SceneDialogueChoiceScope>[];
    final mappedLists = Map<List<YarnStep>, List<YarnStep>>.identity();
    final byScope = {for (final policy in policies) (policy.nodeName, policy.choiceIndex): policy};
    final configured = <YarnNode>[];
    for (final node in nodes) {
      var choiceIndex = 0;
      List<YarnStep> visit(List<YarnStep> steps) {
        final result = <YarnStep>[];
        mappedLists[steps] = result;
        for (final step in steps) {
          if (step is! YarnStepChoiceBlock) {
            result.add(step);
            continue;
          }
          final index = choiceIndex++;
          scopes.add(SceneDialogueChoiceScope(nodeName: node.title, choiceIndex: index,
              outcomeIds: step.choices.map((choice) => choice.outcomeId).toList(growable: false)));
          result.add(YarnStepChoiceBlock([
            for (final choice in step.choices)
              YarnChoice(text: choice.text, outcomeId: choice.outcomeId, steps: visit(choice.steps)),
          ], policy: byScope[(node.title, index)]));
        }
        return result;
      }
      configured.add(YarnNode(title: node.title, steps: visit(node.steps)));
    }
    validateSceneDialogueChoicePolicies(scopes, policies);
    final current = mappedLists[_currentSteps];
    if (current == null) throw ArgumentError('Dialogue choice policy requires a current node scope.');
    final step = current[_stepIndex];
    return DialogueSession._(
      nodes: configured,
      state: step is YarnStepChoiceBlock
          ? DialogueWaitingForChoice(choices: step.choices,
              selectedIndex: step.policy?.defaultOutcomeId == null
                  ? (state as DialogueWaitingForChoice).selectedIndex
                  : step.choices.indexWhere((choice) => choice.outcomeId == step.policy!.defaultOutcomeId),
              policy: step.policy)
          : step is YarnStepLine
              ? DialogueShowingLine(text: step.text, characterId: step.characterId,
                  portraitStateId: step.portraitStateId, feedback: step.feedback)
              : state,
      currentNodeTitle: _currentNodeTitle, currentSteps: current,
      stepIndex: _stepIndex, selectedOutcomeId: _selectedOutcomeId,
    );
  }

  String? get choiceCancellationOutcomeId => switch (state) {
    DialogueWaitingForChoice(:final policy) => policy?.cancellation.outcomeId,
    _ => null,
  };

  DialogueSession? cancelChoice() {
    final current = state;
    if (current is! DialogueWaitingForChoice) return this;
    final cancellation = current.policy?.cancellation;
    if (cancellation == null || cancellation.kind == SceneDialogueChoiceCancellationKind.disabled) return this;
    if (cancellation.kind == SceneDialogueChoiceCancellationKind.branch) return null;
    final choice = current.choices.singleWhere((choice) => choice.outcomeId == cancellation.outcomeId);
    return _resolveStep(choice.steps, 0, nodes, nodeTitle: _currentNodeTitle,
        selectedOutcomeId: choice.outcomeId ?? _selectedOutcomeId);
  }

  /// Returns an equivalent session whose visible lines and choices have been
  /// transformed without changing navigation or outcome IDs.
  DialogueSession mapText(String Function(String text) transform) {
    final mappedNodes = nodes.map(
      (node) => YarnNode(
        title: node.title,
        steps: _mapSteps(node.steps, transform),
      ),
    );
    final mappedCurrentSteps = _mapSteps(_currentSteps, transform);
    return DialogueSession._(
      nodes: mappedNodes.toList(growable: false),
      state: switch (state) {
        DialogueShowingLine(
          :final text,
          :final characterId,
          :final portraitStateId,
          :final feedback,
        ) =>
          DialogueShowingLine(
            text: transform(text),
            characterId: characterId,
            portraitStateId: portraitStateId,
            feedback: feedback?.mapText(transform),
          ),
        DialogueWaitingForChoice(:final choices, :final selectedIndex, :final policy) =>
          DialogueWaitingForChoice(
            choices: choices
                .map(
                  (choice) => YarnChoice(
                    text: transform(choice.text),
                    steps: _mapSteps(choice.steps, transform),
                    outcomeId: choice.outcomeId,
                  ),
                )
                .toList(growable: false),
            selectedIndex: selectedIndex,
            policy: policy,
          ),
      },
      currentNodeTitle: _currentNodeTitle,
      currentSteps: mappedCurrentSteps,
      stepIndex: _stepIndex,
      selectedOutcomeId: _selectedOutcomeId,
    );
  }

  bool get isLastContent {
    if (state is! DialogueShowingLine) return false;
    return _resolveStep(_currentSteps, _stepIndex + 1, nodes) == null;
  }

  DialogueSession? advance() {
    if (state is! DialogueShowingLine) return this;
    return _resolveStep(
      _currentSteps,
      _stepIndex + 1,
      nodes,
      selectedOutcomeId: _selectedOutcomeId,
      nodeTitle: _currentNodeTitle,
    );
  }

  DialogueSession moveChoiceCursor(int delta) {
    final s = state;
    if (s is! DialogueWaitingForChoice) return this;
    final newIndex = (s.selectedIndex + delta).clamp(0, s.choices.length - 1);
    return DialogueSession._(
      nodes: nodes,
      state:
          DialogueWaitingForChoice(choices: s.choices, selectedIndex: newIndex, policy: s.policy),
      currentNodeTitle: _currentNodeTitle,
      currentSteps: _currentSteps,
      stepIndex: _stepIndex,
      selectedOutcomeId: _selectedOutcomeId,
    );
  }

  DialogueSession? confirmChoice() {
    final s = state;
    if (s is! DialogueWaitingForChoice) return this;
    final choice = s.choices[s.selectedIndex];
    return _resolveStep(
      choice.steps,
      0,
      nodes,
      selectedOutcomeId: choice.outcomeId ?? _selectedOutcomeId,
      nodeTitle: _currentNodeTitle,
    );
  }

  static DialogueSession? start(List<YarnNode> nodes, String? startNodeTitle) {
    if (nodes.isEmpty) return null;
    int index = 0;
    if (startNodeTitle != null && startNodeTitle.isNotEmpty) {
      final found = nodes.indexWhere((n) => n.title == startNodeTitle);
      if (found != -1) index = found;
    }
    final node = nodes[index];
    return _resolveStep(
      node.steps,
      0,
      nodes,
      nodeTitle: node.title,
    );
  }
}

List<YarnStep> _mapSteps(
  List<YarnStep> steps,
  String Function(String text) transform,
) =>
    steps
        .map(
          (step) => switch (step) {
            YarnStepLine(
              :final text,
              :final characterId,
              :final portraitStateId,
              :final feedback,
            ) =>
              YarnStepLine(
                transform(text),
                characterId: characterId,
                portraitStateId: portraitStateId,
                feedback: feedback?.mapText(transform),
              ),
            YarnStepJump(:final targetNode) => YarnStepJump(targetNode),
            YarnStepChoiceBlock(:final choices, :final policy) => YarnStepChoiceBlock(
                choices
                    .map(
                      (choice) => YarnChoice(
                        text: transform(choice.text),
                        steps: _mapSteps(choice.steps, transform),
                        outcomeId: choice.outcomeId,
                      ),
                    )
                    .toList(growable: false),
                policy: policy,
              ),
          },
        )
        .toList(growable: false);

DialogueSession? _resolveStep(
  List<YarnStep> steps,
  int index,
  List<YarnNode> nodes, {
  String? nodeTitle,
  String? selectedOutcomeId,
}) {
  var currentSteps = steps;
  var currentIndex = index;
  var currentTitle = nodeTitle;

  for (;;) {
    if (currentIndex >= currentSteps.length) return null;
    final step = currentSteps[currentIndex];
    switch (step) {
      case YarnStepLine(:final characterId, :final portraitStateId):
        return DialogueSession._(
          nodes: nodes,
          state: DialogueShowingLine(
            text: step.text,
            characterId: characterId,
            portraitStateId: portraitStateId,
            feedback: step.feedback,
          ),
          currentNodeTitle: currentTitle,
          currentSteps: currentSteps,
          stepIndex: currentIndex,
          selectedOutcomeId: selectedOutcomeId,
        );
      case YarnStepJump():
        final nodeIndex = nodes.indexWhere((n) => n.title == step.targetNode);
        if (nodeIndex == -1) return null;
        final target = nodes[nodeIndex];
        currentSteps = target.steps;
        currentTitle = target.title;
        currentIndex = 0;
      case YarnStepChoiceBlock():
        return DialogueSession._(
          nodes: nodes,
          state: DialogueWaitingForChoice(
            choices: step.choices,
            selectedIndex: step.policy?.defaultOutcomeId == null ? 0
                : step.choices.indexWhere((choice) => choice.outcomeId == step.policy!.defaultOutcomeId),
            policy: step.policy,
          ),
          currentNodeTitle: currentTitle,
          currentSteps: currentSteps,
          stepIndex: currentIndex,
          selectedOutcomeId: selectedOutcomeId,
        );
    }
  }
}
