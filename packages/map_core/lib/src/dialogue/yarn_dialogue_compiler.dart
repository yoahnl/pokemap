import 'runtime_dialogue_document.dart';

final class YarnDialogueFormatException extends FormatException {
  YarnDialogueFormatException(
    String message, {
    required this.lineNumber,
    required this.sourceLine,
  }) : super('$message (line $lineNumber)', sourceLine, lineNumber);

  final int lineNumber;
  final String sourceLine;
}

final class _PortraitDirective {
  const _PortraitDirective({
    required this.characterId,
    required this.portraitStateId,
    required this.lineNumber,
    required this.sourceLine,
  });

  final String characterId;
  final String portraitStateId;
  final int lineNumber;
  final String sourceLine;
}

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
    _PortraitDirective? pendingPortrait;

    Never invalidPortrait(String message, int lineNumber, String sourceLine) {
      throw YarnDialogueFormatException(
        message,
        lineNumber: lineNumber,
        sourceLine: sourceLine,
      );
    }

    void requirePortraitConsumed() {
      final pending = pendingPortrait;
      if (pending == null) return;
      invalidPortrait(
        'A portrait directive must be followed by a dialogue line.',
        pending.lineNumber,
        pending.sourceLine,
      );
    }

    _PortraitDirective? consumePortrait() {
      final result = pendingPortrait;
      pendingPortrait = null;
      return result;
    }

    void readPortraitDirective(
      String value,
      int lineNumber,
      String sourceLine,
    ) {
      if (!value.startsWith('<<portrait')) return;
      if (pendingPortrait != null) requirePortraitConsumed();
      final match = RegExp(
        r'^<<portrait\s+([^\s>]+)\s+([^\s>]+)>>$',
      ).firstMatch(value);
      if (match == null) {
        invalidPortrait(
          'Invalid portrait directive. Expected <<portrait characterId portraitStateId>>.',
          lineNumber,
          sourceLine,
        );
      }
      pendingPortrait = _PortraitDirective(
        characterId: match.group(1)!,
        portraitStateId: match.group(2)!,
        lineNumber: lineNumber,
        sourceLine: sourceLine,
      );
    }

    RuntimeDialogueLine dialogueLine(String text) {
      final portrait = consumePortrait();
      return RuntimeDialogueLine(
        text,
        characterId: portrait?.characterId,
        portraitStateId: portrait?.portraitStateId,
      );
    }

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
      requirePortraitConsumed();
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
      requirePortraitConsumed();
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
      pendingPortrait = null;
    }

    final sourceLines = source.split('\n');
    for (var lineIndex = 0; lineIndex < sourceLines.length; lineIndex++) {
      final raw = sourceLines[lineIndex];
      final lineNumber = lineIndex + 1;
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
          pendingPortrait = null;
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
        if (trimmed.startsWith('<<portrait')) {
          readPortraitDirective(trimmed, lineNumber, line);
        } else if (trimmed.startsWith('<<outcome ') && trimmed.endsWith('>>')) {
          requirePortraitConsumed();
          final outcomeId = trimmed
              .substring('<<outcome '.length, trimmed.length - 2)
              .trim();
          if (outcomeId.isNotEmpty) currentChoiceOutcomeId = outcomeId;
        } else if (trimmed.startsWith('<<jump ') && trimmed.endsWith('>>')) {
          requirePortraitConsumed();
          currentChoiceSteps.add(
            RuntimeDialogueJump(
              trimmed.substring('<<jump '.length, trimmed.length - 2),
            ),
          );
        } else if (!(trimmed.startsWith('<<') && trimmed.endsWith('>>'))) {
          currentChoiceSteps.add(dialogueLine(trimmed));
        } else {
          requirePortraitConsumed();
        }
      } else if (trimmed.startsWith('->')) {
        requirePortraitConsumed();
        if (!inChoiceBlock) {
          inChoiceBlock = true;
        } else {
          closeChoiceOption();
        }
        currentChoiceText = trimmed.substring(2).trim();
      } else if (trimmed.startsWith('<<jump ') && trimmed.endsWith('>>')) {
        requirePortraitConsumed();
        if (inChoiceBlock) closeChoiceBlock();
        rootSteps.add(
          RuntimeDialogueJump(
            trimmed.substring('<<jump '.length, trimmed.length - 2),
          ),
        );
      } else if (trimmed.startsWith('<<portrait')) {
        if (inChoiceBlock) closeChoiceBlock();
        readPortraitDirective(trimmed, lineNumber, line);
      } else if (trimmed.startsWith('<<') && trimmed.endsWith('>>')) {
        requirePortraitConsumed();
        if (inChoiceBlock) closeChoiceBlock();
      } else {
        if (inChoiceBlock) closeChoiceBlock();
        rootSteps.add(dialogueLine(trimmed));
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
