import 'package:map_core/map_core.dart';

import 'dialogue_runtime_models.dart';

List<YarnNode> parseYarnFile(String content) =>
    runtimeDialogueNodesFromDocument(
      const YarnDialogueCompiler().compile(content),
    );

List<YarnNode> runtimeDialogueNodesFromDocument(
  RuntimeDialogueDocument document, {
  DialogueLocalization? localization,
  String? preferredLocale,
  ProjectLocalePolicy? locales,
}) {
  if (localization != null && locales == null) {
    throw const FormatException(
      'Localized dialogue requires the project locale policy.',
    );
  }
  final localized = localization == null
      ? document
      : resolveRuntimeDialogueLocalization(
          document,
          localization,
          preferredLocale: preferredLocale ?? locales!.fallbackLocale,
          locales: locales!,
        );
  return [
    for (final (index, node) in localized.nodes.indexed)
      _node(node, document.nodes[index]),
  ];
}

YarnNode _node(RuntimeDialogueNode node, RuntimeDialogueNode source) =>
    YarnNode(
      title: node.title,
      steps: [
        for (final (index, step) in node.steps.indexed)
          _step(step, source.steps[index]),
      ],
    );

YarnStep _step(RuntimeDialogueStep step, RuntimeDialogueStep source) =>
    switch (step) {
      RuntimeDialogueLine() => YarnStepLine(
        step.text,
        characterId: step.characterId,
        portraitStateId: step.portraitStateId,
        feedback: step.feedback,
        sourceText: step.text == (source as RuntimeDialogueLine).text
            ? null
            : source.text,
        sourceFeedback: source.feedback,
      ),
      RuntimeDialogueJump() => YarnStepJump(step.targetNode),
      RuntimeDialogueChoiceBlock() => YarnStepChoiceBlock([
        for (final (index, choice) in step.choices.indexed)
          YarnChoice(
            text: choice.text,
            steps: [
              for (final (innerIndex, inner) in choice.steps.indexed)
                _step(
                  inner,
                  (source as RuntimeDialogueChoiceBlock)
                      .choices[index]
                      .steps[innerIndex],
                ),
            ],
            outcomeId: choice.outcomeId,
          ),
      ]),
    };
