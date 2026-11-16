import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core_domain.dart';

import '../../story_draft/domain/story_dialogue_source.dart';
import '../domain/dialogue_catalog_port.dart';

enum DialogueCatalogStatus {
  source,
  translated,
  missing,
  needsReview,
  unlocalized,
  unsupported,
}

final class DialogueCatalogPreview {
  const DialogueCatalogPreview({
    required this.texts,
    required this.status,
    this.textLocales = const {},
    this.fallback = false,
  });

  final List<String> texts;
  final DialogueCatalogStatus status;
  final Set<String> textLocales;
  final bool fallback;
}

DialogueCatalogPreview previewDialogue(
  StoryDialogueSource dialogue,
  String language,
  DialogueCatalogLanguages languages,
) {
  try {
    final localization = dialogue.entry.localization;
    if (localization == null) {
      final document = readLocalizedDialogue(
        source: dialogue.source,
        sourceLocale: 'und',
        entryNodeTitle: dialogue.entry.defaultStartNode,
      ).document;
      if (document.nodes.isEmpty) throw const FormatException();
      final texts = <String>[];
      void walk(List<DialogueEditorStep> steps) {
        for (final step in steps) {
          switch (step) {
            case DeLineStep(:final body):
              texts.add(body);
            case DeNarrationStep(:final text):
              texts.add(text);
            case DeChoiceStep(:final branches):
              for (final branch in branches) {
                texts.add(branch.label);
                walk(branch.steps);
              }
            default:
              break;
          }
        }
      }

      for (final node in document.nodes) {
        walk(node.steps);
      }
      return DialogueCatalogPreview(
        texts: texts,
        status: DialogueCatalogStatus.unlocalized,
      );
    }
    readLocalizedDialogue(
      source: dialogue.source,
      sourceLocale: localization.sourceLocale,
      localization: localization,
      entryNodeTitle: dialogue.entry.defaultStartNode,
    );
    if (language == 'source') {
      return DialogueCatalogPreview(
        texts: localization.units.map((unit) => unit.source).toList(),
        status: DialogueCatalogStatus.source,
        textLocales: {localization.sourceLocale},
      );
    }
    final supported = languages.locales.isEmpty
        ? {
            localization.sourceLocale,
            language,
            for (final unit in localization.units) ...unit.translations.keys,
          }
        : languages.locales.toSet();
    final resolved = [
      for (final unit in localization.units)
        localization.resolve(
          unit.id,
          preferredLocale: language,
          supportedLocales: supported,
          fallbackLocale: languages.fallback ?? localization.sourceLocale,
        ),
    ];
    final status =
        resolved.any((text) => text.status == DialogueTranslationStatus.missing)
        ? DialogueCatalogStatus.missing
        : resolved.any((text) => text.needsReview)
        ? DialogueCatalogStatus.needsReview
        : resolved.every(
            (text) => text.status == DialogueTranslationStatus.source,
          )
        ? DialogueCatalogStatus.source
        : DialogueCatalogStatus.translated;
    return DialogueCatalogPreview(
      texts: resolved.map((text) => text.text).toList(),
      status: status,
      textLocales: resolved.map((text) => text.textLocale).toSet(),
      fallback: resolved.any((text) => text.usedFallback),
    );
  } on Object {
    return const DialogueCatalogPreview(
      texts: [],
      status: DialogueCatalogStatus.unsupported,
    );
  }
}
