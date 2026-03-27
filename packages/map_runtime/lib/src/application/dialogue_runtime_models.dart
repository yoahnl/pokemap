sealed class YarnStep {}

class YarnStepLine extends YarnStep {
  YarnStepLine(this.text);
  final String text;
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
  YarnChoice({required this.text, required this.steps});
  final String text;
  final List<YarnStep> steps;
}

class YarnNode {
  const YarnNode({required this.title, required this.steps});
  final String title;
  final List<YarnStep> steps;
}

sealed class DialogueSessionState {}

class DialogueShowingLine extends DialogueSessionState {
  DialogueShowingLine({required this.text});
  final String text;
}

class DialogueWaitingForChoice extends DialogueSessionState {
  DialogueWaitingForChoice({required this.choices, required this.selectedIndex});
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
  })  : _currentNodeTitle = currentNodeTitle,
        _currentSteps = currentSteps,
        _stepIndex = stepIndex;

  final List<YarnNode> nodes;
  final DialogueSessionState state;
  final String? _currentNodeTitle;
  final List<YarnStep> _currentSteps;
  final int _stepIndex;

  String? get currentNodeTitle => _currentNodeTitle;

  bool get isLastContent {
    if (state is! DialogueShowingLine) return false;
    return _resolveStep(_currentSteps, _stepIndex + 1, nodes) == null;
  }

  DialogueSession? advance() {
    if (state is! DialogueShowingLine) return this;
    return _resolveStep(_currentSteps, _stepIndex + 1, nodes);
  }

  DialogueSession moveChoiceCursor(int delta) {
    final s = state;
    if (s is! DialogueWaitingForChoice) return this;
    final newIndex = (s.selectedIndex + delta).clamp(0, s.choices.length - 1);
    return DialogueSession._(
      nodes: nodes,
      state: DialogueWaitingForChoice(choices: s.choices, selectedIndex: newIndex),
      currentNodeTitle: _currentNodeTitle,
      currentSteps: _currentSteps,
      stepIndex: _stepIndex,
    );
  }

  DialogueSession? confirmChoice() {
    final s = state;
    if (s is! DialogueWaitingForChoice) return this;
    return _resolveStep(s.choices[s.selectedIndex].steps, 0, nodes);
  }

  static DialogueSession? start(List<YarnNode> nodes, String? startNodeTitle) {
    if (nodes.isEmpty) return null;
    int index = 0;
    if (startNodeTitle != null && startNodeTitle.isNotEmpty) {
      final found = nodes.indexWhere((n) => n.title == startNodeTitle);
      if (found != -1) index = found;
    }
    final node = nodes[index];
    return _resolveStep(node.steps, 0, nodes, nodeTitle: node.title);
  }
}

DialogueSession? _resolveStep(
  List<YarnStep> steps,
  int index,
  List<YarnNode> nodes, {
  String? nodeTitle,
}) {
  var currentSteps = steps;
  var currentIndex = index;
  var currentTitle = nodeTitle;

  for (;;) {
    if (currentIndex >= currentSteps.length) return null;
    final step = currentSteps[currentIndex];
    switch (step) {
      case YarnStepLine():
        return DialogueSession._(
          nodes: nodes,
          state: DialogueShowingLine(text: step.text),
          currentNodeTitle: currentTitle,
          currentSteps: currentSteps,
          stepIndex: currentIndex,
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
        );
    }
  }
}
