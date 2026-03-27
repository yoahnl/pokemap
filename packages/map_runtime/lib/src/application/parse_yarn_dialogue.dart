import 'dialogue_runtime_models.dart';

List<YarnNode> parseYarnFile(String content) {
  final nodes = <YarnNode>[];
  String? currentTitle;
  bool inBody = false;
  final rootSteps = <YarnStep>[];
  bool inChoiceBlock = false;
  final currentChoices = <YarnChoice>[];
  String? currentChoiceText;
  final currentChoiceSteps = <YarnStep>[];

  void closeChoiceOption() {
    if (currentChoiceText != null) {
      currentChoices.add(YarnChoice(
        text: currentChoiceText!,
        steps: List.unmodifiable(currentChoiceSteps),
      ));
      currentChoiceText = null;
      currentChoiceSteps.clear();
    }
  }

  void closeChoiceBlock() {
    closeChoiceOption();
    if (currentChoices.isNotEmpty) {
      rootSteps.add(YarnStepChoiceBlock(List.unmodifiable(currentChoices)));
      currentChoices.clear();
    }
    inChoiceBlock = false;
  }

  for (final raw in content.split('\n')) {
    final line = raw.trimRight();

    if (!inBody) {
      final trimmed = line.trim();
      if (trimmed.startsWith('title:')) {
        currentTitle = trimmed.substring('title:'.length).trim();
      } else if (trimmed == '---') {
        inBody = true;
        rootSteps.clear();
        inChoiceBlock = false;
        currentChoices.clear();
        currentChoiceText = null;
        currentChoiceSteps.clear();
      }
    } else {
      final trimmed = line.trim();
      if (trimmed == '===') {
        if (inChoiceBlock) closeChoiceBlock();
        if (currentTitle != null && rootSteps.isNotEmpty) {
          nodes.add(YarnNode(
            title: currentTitle,
            steps: List.unmodifiable(rootSteps),
          ));
        }
        currentTitle = null;
        rootSteps.clear();
        inBody = false;
      } else if (trimmed.isEmpty) {
        // skip
      } else if (line.startsWith(' ') || line.startsWith('\t')) {
        if (trimmed.startsWith('<<jump ') && trimmed.endsWith('>>')) {
          final target =
              trimmed.substring('<<jump '.length, trimmed.length - 2).trim();
          currentChoiceSteps.add(YarnStepJump(target));
        } else if (!(trimmed.startsWith('<<') && trimmed.endsWith('>>'))) {
          currentChoiceSteps.add(YarnStepLine(trimmed));
        }
      } else if (trimmed.startsWith('->')) {
        if (!inChoiceBlock) {
          inChoiceBlock = true;
        } else {
          closeChoiceOption();
        }
        currentChoiceText = trimmed.substring(2).trim();
      } else if (trimmed.startsWith('<<jump ') && trimmed.endsWith('>>')) {
        if (inChoiceBlock) closeChoiceBlock();
        final target =
            trimmed.substring('<<jump '.length, trimmed.length - 2).trim();
        rootSteps.add(YarnStepJump(target));
      } else if (trimmed.startsWith('<<') && trimmed.endsWith('>>')) {
        if (inChoiceBlock) closeChoiceBlock();
      } else {
        if (inChoiceBlock) closeChoiceBlock();
        rootSteps.add(YarnStepLine(trimmed));
      }
    }
  }

  return nodes;
}
