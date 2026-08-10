import 'package:map_core/map_core.dart';

import 'dialogue_runtime_models.dart';

List<YarnNode> parseYarnFile(String content) =>
    runtimeDialogueNodesFromDocument(
      const YarnDialogueCompiler().compile(content),
    );

List<YarnNode> runtimeDialogueNodesFromDocument(
  RuntimeDialogueDocument document,
) =>
    document.nodes.map(_node).toList(growable: false);

YarnNode _node(RuntimeDialogueNode node) => YarnNode(
      title: node.title,
      steps: node.steps.map(_step).toList(growable: false),
    );

YarnStep _step(RuntimeDialogueStep step) => switch (step) {
      RuntimeDialogueLine() => YarnStepLine(
          step.text,
          characterId: step.characterId,
          portraitStateId: step.portraitStateId,
        ),
      RuntimeDialogueJump() => YarnStepJump(step.targetNode),
      RuntimeDialogueChoiceBlock() => YarnStepChoiceBlock(
          step.choices
              .map(
                (choice) => YarnChoice(
                  text: choice.text,
                  steps: choice.steps.map(_step).toList(growable: false),
                  outcomeId: choice.outcomeId,
                ),
              )
              .toList(growable: false),
        ),
    };
