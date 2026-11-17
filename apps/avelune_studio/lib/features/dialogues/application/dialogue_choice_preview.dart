import 'package:map_authoring/map_authoring_dialogue.dart';

import '../../story_draft/domain/story_dialogue_source.dart';
import '../domain/dialogue_catalog_port.dart';

final class DialogueChoicePreview {
  const DialogueChoicePreview(this.labels, this.fallbackLocales);

  final Map<String, String> labels;
  final Set<String> fallbackLocales;
}

DialogueChoicePreview previewDialogueChoices(
  StoryDialogueSource dialogue,
  String language,
  DialogueCatalogLanguages languages,
) {
  final labels = <String, String>{
    for (final outcome in dialogue.entry.declaredOutcomes)
      outcome.id: outcome.label,
  };
  final fallbackLocales = <String>{};
  try {
    final localization = dialogue.entry.localization;
    final parsed = readLocalizedDialogue(
      source: dialogue.source,
      sourceLocale: localization?.sourceLocale ?? 'und',
      localization: localization,
      entryNodeTitle: dialogue.entry.defaultStartNode,
    );
    final fallback = languages.fallback ?? parsed.localization.sourceLocale;
    final supported = {
      ...languages.locales,
      parsed.localization.sourceLocale,
      fallback,
      if (languages.locales.isEmpty) ...[
        language,
        for (final unit in parsed.localization.units) ...unit.translations.keys,
      ],
    };
    final resolvedLabels = <String, String>{};
    final ambiguous = <String>{};

    void walk(List<DialogueEditorStep> steps) {
      for (final step in steps.whereType<DeChoiceStep>()) {
        for (final branch in step.branches) {
          final id = branch.outcomeId;
          if (id != null) {
            var title = branch.label;
            if (language != 'source' && localization != null) {
              final resolved = localization.resolve(
                branch.id,
                preferredLocale: language,
                supportedLocales: supported,
                fallbackLocale: fallback,
              );
              title = resolved.text;
              if (resolved.usedFallback) {
                fallbackLocales.add(resolved.textLocale);
              }
            }
            final previous = resolvedLabels.putIfAbsent(id, () => title);
            if (previous != title) ambiguous.add(id);
          }
          walk(branch.steps);
        }
      }
    }

    for (final node in parsed.document.nodes) {
      walk(node.steps);
    }
    labels.addAll({
      for (final entry in resolvedLabels.entries)
        if (!ambiguous.contains(entry.key)) entry.key: entry.value,
    });
  } on FormatException {
    return DialogueChoicePreview(labels, const {});
  }
  return DialogueChoicePreview(labels, fallbackLocales);
}
