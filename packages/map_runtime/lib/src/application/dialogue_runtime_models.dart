sealed class YarnStep {}

class YarnStepLine extends YarnStep {
  YarnStepLine(
    this.text, {
    this.characterId,
    this.portraitStateId,
  });
  final String text;
  final String? characterId;
  final String? portraitStateId;
}

class YarnStepJump extends YarnStep {
  YarnStepJump(this.targetNode);
  final String targetNode;
}

class YarnStepChoiceBlock extends YarnStep {
  YarnStepChoiceBlock(this.choices);
  final List<YarnChoice> choices;
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
  });
  final String text;
  final String? characterId;
  final String? portraitStateId;
}

class DialogueWaitingForChoice extends DialogueSessionState {
  DialogueWaitingForChoice(
      {required this.choices, required this.selectedIndex});
  final List<YarnChoice> choices;
  final int selectedIndex;
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

  String? get currentNodeTitle => _currentNodeTitle;
  String? get selectedOutcomeId => _selectedOutcomeId;

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
        ) =>
          DialogueShowingLine(
            text: transform(text),
            characterId: characterId,
            portraitStateId: portraitStateId,
          ),
        DialogueWaitingForChoice(:final choices, :final selectedIndex) =>
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
    );
  }

  DialogueSession moveChoiceCursor(int delta) {
    final s = state;
    if (s is! DialogueWaitingForChoice) return this;
    final newIndex = (s.selectedIndex + delta).clamp(0, s.choices.length - 1);
    return DialogueSession._(
      nodes: nodes,
      state:
          DialogueWaitingForChoice(choices: s.choices, selectedIndex: newIndex),
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
            ) =>
              YarnStepLine(
                transform(text),
                characterId: characterId,
                portraitStateId: portraitStateId,
              ),
            YarnStepJump(:final targetNode) => YarnStepJump(targetNode),
            YarnStepChoiceBlock(:final choices) => YarnStepChoiceBlock(
                choices
                    .map(
                      (choice) => YarnChoice(
                        text: transform(choice.text),
                        steps: _mapSteps(choice.steps, transform),
                        outcomeId: choice.outcomeId,
                      ),
                    )
                    .toList(growable: false),
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
            selectedIndex: 0,
          ),
          currentNodeTitle: currentTitle,
          currentSteps: currentSteps,
          stepIndex: currentIndex,
          selectedOutcomeId: selectedOutcomeId,
        );
    }
  }
}
