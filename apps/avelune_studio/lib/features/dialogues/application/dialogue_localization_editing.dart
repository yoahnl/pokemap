import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core_domain.dart';

import '../../story_draft/domain/story_dialogue_source.dart';

typedef _EditedTranslation = ({String text, String source});

final class DialogueTextUnrepresentable implements Exception {}

final class DialogueLocalizationEditing {
  DialogueLocalizationEditing(this.base)
    : sourceLocale = base.entry.localization?.sourceLocale {
    _opened = readLocalizedDialogue(
      source: base.source,
      sourceLocale: sourceLocale ?? 'und',
      localization: base.entry.localization,
      entryNodeTitle: base.entry.defaultStartNode,
    );
  }

  final StoryDialogueSource base;
  late final LocalizedDialogueDocument _opened;
  String? sourceLocale;
  final _sources = <String, String>{};
  final _translations = <String, Map<String, _EditedTranslation>>{};

  DialogueLocalization get localization => _project(preview: true);

  String sourceText(String id) =>
      _sources[id] ?? _opened.localization.unit(id).source;

  String translationText(String id, String locale) =>
      _translations[id]?[locale]?.text ??
      _opened.localization.unit(id).translations[locale]?.text ??
      '';

  void writeSource(String id, String text) {
    _opened.localization.unit(id);
    _sources[id] = text;
  }

  void writeTranslation(String id, String locale, String text) {
    _opened.localization.unit(id);
    if (sourceLocale == null || locale == sourceLocale) {
      throw StateError('Choose a source locale before translating.');
    }
    _translations.putIfAbsent(id, () => {})[locale] = (
      text: text,
      source: sourceText(id),
    );
  }

  void declareSourceLocale(String locale) {
    if (base.entry.localization != null && locale != sourceLocale) {
      throw StateError('An existing source locale cannot be replaced here.');
    }
    final candidate = DialogueLocalization(
      sourceLocale: locale,
      units: localization.units,
    );
    sourceLocale = candidate.sourceLocale;
  }

  DialogueTextResolution resolve(
    String id,
    String locale, {
    Iterable<String> locales = const [],
    String? fallback,
  }) {
    final current = localization;
    final supported = {
      ...locales,
      locale,
      current.sourceLocale,
      for (final unit in current.units) ...unit.translations.keys,
      ?fallback,
    };
    return current.resolve(
      id,
      preferredLocale: locale,
      supportedLocales: supported,
      fallbackLocale: fallback ?? current.sourceLocale,
    );
  }

  StoryDialogueSource build() {
    final current = _project(preview: false);
    final parsed = readLocalizedDialogue(
      source: base.source,
      sourceLocale: _opened.localization.sourceLocale,
      localization: _opened.localization,
      entryNodeTitle: base.entry.defaultStartNode,
    );
    void walk(List<DialogueEditorStep> steps) {
      for (final step in steps) {
        switch (step) {
          case DeLineStep():
            step.body = current.unit(step.id).source;
          case DeNarrationStep():
            step.text = current.unit(step.id).source;
          case DeChoiceStep():
            for (final branch in step.branches) {
              branch.label = current.unit(branch.id).source;
              walk(branch.steps);
            }
          default:
            break;
        }
      }
    }

    for (final node in parsed.document.nodes) {
      walk(node.steps);
    }
    final updated = writeLocalizedDialogue(parsed.document, previous: current);
    final source = updated.source;
    try {
      readLocalizedDialogue(
        source: source,
        sourceLocale: current.sourceLocale,
        localization: updated.localization,
        entryNodeTitle: base.entry.defaultStartNode,
      );
    } on FormatException {
      throw DialogueTextUnrepresentable();
    }
    return StoryDialogueSource(
      entry: base.entry.copyWith(
        localization: sourceLocale == null ? null : updated.localization,
      ),
      source: source,
      revision: base.revision,
    );
  }

  StoryDialogueSource duplicate({required String id, required String name}) {
    final current = build();
    final copied = duplicateLocalizedDialogue(
      readLocalizedDialogue(
        source: current.source,
        sourceLocale: sourceLocale ?? 'und',
        localization: current.entry.localization,
        entryNodeTitle: current.entry.defaultStartNode,
      ),
    );
    return StoryDialogueSource(
      entry: current.entry.copyWith(
        id: id,
        name: name,
        relativePath: 'dialogues/$id.yarn',
        localization: sourceLocale == null ? null : copied.localization,
      ),
      source: copied.source,
    );
  }

  DialogueLocalization _project({required bool preview}) {
    final original = _opened.localization;
    return DialogueLocalization(
      sourceLocale: sourceLocale ?? original.sourceLocale,
      units: [
        for (final unit in original.units)
          unit.copyWith(
            source: _previewText(sourceText(unit.id), unit.source, preview),
            translations:
                {
                  ...unit.translations,
                  for (final entry
                      in _translations[unit.id]?.entries ??
                          const <MapEntry<String, _EditedTranslation>>[])
                    if (entry.value.text.isNotEmpty)
                      entry.key: DialogueTranslation(
                        text: _previewText(
                          entry.value.text,
                          unit.translations[entry.key]?.text ?? unit.source,
                          preview,
                        ),
                        source: _previewText(
                          entry.value.source,
                          unit.source,
                          preview,
                        ),
                      ),
                }..removeWhere(
                  (locale, _) =>
                      _translations[unit.id]?[locale]?.text.isEmpty ?? false,
                ),
          ),
      ],
    );
  }

  String _previewText(String value, String previous, bool preview) {
    if (preview && (value.trim().isEmpty || value.contains('\u0000'))) {
      return previous;
    }
    return value;
  }
}
