import 'runtime_dialogue_document.dart';

/// Compiles the deliberately small Yarn subset supported by PokeMap runtime.
final class YarnDialogueCompiler {
  const YarnDialogueCompiler();

  RuntimeDialogueDocument compile(String source) {
    final nodes = <RuntimeDialogueNode>[];
    String? currentTitle;
    var inBody = false;
    final rootSteps = <RuntimeDialogueStep>[];
    var inChoiceBlock = false;
    final currentChoices = <RuntimeDialogueChoice>[];
    String? currentChoiceText;
    String? currentChoiceOutcomeId;
    final currentChoiceSteps = <RuntimeDialogueStep>[];

    void closeChoiceOption() {
      if (currentChoiceText != null) {
        currentChoices.add(
          RuntimeDialogueChoice(
            text: currentChoiceText!,
            steps: List.unmodifiable(currentChoiceSteps),
            outcomeId: currentChoiceOutcomeId,
          ),
        );
        currentChoiceText = null;
        currentChoiceOutcomeId = null;
        currentChoiceSteps.clear();
      }
    }

    void closeChoiceBlock() {
      closeChoiceOption();
      if (currentChoices.isNotEmpty) {
        rootSteps.add(
          RuntimeDialogueChoiceBlock(List.unmodifiable(currentChoices)),
        );
        currentChoices.clear();
      }
      inChoiceBlock = false;
    }

    void closeNode() {
      if (inChoiceBlock) closeChoiceBlock();
      if (currentTitle != null && rootSteps.isNotEmpty) {
        nodes.add(
          RuntimeDialogueNode(
            title: currentTitle!,
            steps: List.unmodifiable(rootSteps),
          ),
        );
      }
      currentTitle = null;
      rootSteps.clear();
      inBody = false;
    }

    for (final raw in source.split('\n')) {
      final line = raw.trimRight();
      final trimmed = line.trim();
      if (!inBody) {
        if (trimmed.startsWith('title:')) {
          currentTitle = trimmed.substring('title:'.length).trim();
        } else if (trimmed == '---') {
          if (currentTitle == null || currentTitle!.isEmpty) {
            throw const FormatException(
              'Yarn dialogue node requires a title before its body.',
            );
          }
          inBody = true;
          rootSteps.clear();
          inChoiceBlock = false;
          currentChoices.clear();
          currentChoiceText = null;
          currentChoiceOutcomeId = null;
          currentChoiceSteps.clear();
        }
        continue;
      }

      if (trimmed == '===') {
        closeNode();
      } else if (trimmed.isEmpty) {
        continue;
      } else if (line.startsWith(' ') || line.startsWith('\t')) {
        if (currentChoiceText == null) {
          throw const FormatException(
            'Indented Yarn content must belong to a choice.',
          );
        }
        if (trimmed.startsWith('<<outcome ') && trimmed.endsWith('>>')) {
          final outcomeId =
              trimmed.substring('<<outcome '.length, trimmed.length - 2).trim();
          if (outcomeId.isNotEmpty) currentChoiceOutcomeId = outcomeId;
        } else if (trimmed.startsWith('<<jump ') && trimmed.endsWith('>>')) {
          currentChoiceSteps.add(
            RuntimeDialogueJump(
              trimmed.substring('<<jump '.length, trimmed.length - 2),
            ),
          );
        } else if (!(trimmed.startsWith('<<') && trimmed.endsWith('>>'))) {
          currentChoiceSteps.add(RuntimeDialogueLine(trimmed));
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
        rootSteps.add(
          RuntimeDialogueJump(
            trimmed.substring('<<jump '.length, trimmed.length - 2),
          ),
        );
      } else if (trimmed.startsWith('<<') && trimmed.endsWith('>>')) {
        if (inChoiceBlock) closeChoiceBlock();
      } else {
        if (inChoiceBlock) closeChoiceBlock();
        rootSteps.add(RuntimeDialogueLine(trimmed));
      }
    }
    if (inBody) {
      throw const FormatException(
        'Yarn dialogue node is missing its closing marker.',
      );
    }
    return RuntimeDialogueDocument(nodes: nodes);
  }
}
