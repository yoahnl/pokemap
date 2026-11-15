import '../localization/project_locale_resolver.dart';

part 'dialogue_localization_codec.dart';
part 'dialogue_text_unit.dart';

const dialogueLocalizationCapability = 'project.dialogue-localization@1';

final class DialogueLocalization {
  DialogueLocalization({
    required String sourceLocale,
    required List<DialogueTextUnit> units,
  }) : sourceLocale = _locale(sourceLocale),
       units = List.unmodifiable(units) {
    final ids = <String>{};
    final bindings = <String>{};
    for (final unit in units) {
      if (!ids.add(unit.id) || !bindings.add(unit.binding)) {
        throw ArgumentError(
          'Dialogue text identities and bindings must be unique.',
        );
      }
      if (unit.translations.containsKey(this.sourceLocale)) {
        throw ArgumentError('The source locale cannot also be a translation.');
      }
    }
  }

  factory DialogueLocalization.fromJson(Map<String, dynamic> json) =>
      _decodeLocalization(json);

  final String sourceLocale;
  final List<DialogueTextUnit> units;

  @override
  bool operator ==(Object other) =>
      other is DialogueLocalization &&
      sourceLocale == other.sourceLocale &&
      units.length == other.units.length &&
      units.indexed.every((entry) => entry.$2 == other.units[entry.$1]);

  @override
  int get hashCode => Object.hash(sourceLocale, Object.hashAll(units));

  DialogueTextUnit unit(String id) => units.firstWhere(
    (unit) => unit.id == id,
    orElse: () => throw ArgumentError.value(id, 'id', 'Unknown dialogue text'),
  );

  DialogueLocalization withUnits(List<DialogueTextUnit> units) =>
      DialogueLocalization(sourceLocale: sourceLocale, units: units);

  DialogueLocalization translate(String id, String locale, String text) {
    final target = unit(id);
    final language = _locale(locale);
    if (language == sourceLocale) {
      throw ArgumentError('Edit the source text in its dialogue document.');
    }
    return withUnits([
      for (final current in units)
        current.id != id
            ? current
            : target.copyWith(
                translations: {
                  ...target.translations,
                  language: DialogueTranslation(
                    text: text,
                    source: target.source,
                  ),
                },
              ),
    ]);
  }

  DialogueTextResolution resolve(
    String id, {
    required String preferredLocale,
    required Iterable<String> supportedLocales,
    required String fallbackLocale,
  }) {
    final supported = supportedLocales.map(_locale).toList();
    final fallback = _locale(fallbackLocale);
    if (!supported.contains(sourceLocale) || !supported.contains(fallback)) {
      throw ArgumentError(
        'Project locales must include source and fallback locales.',
      );
    }
    final effective = ProjectLocaleResolver.resolve(
      preferredLocale: preferredLocale,
      supportedLocales: supported,
      fallbackLocale: fallback,
    );
    final target = unit(id);
    if (effective == sourceLocale) {
      return DialogueTextResolution(
        text: target.source,
        effectiveLocale: effective,
        textLocale: sourceLocale,
        status: DialogueTranslationStatus.source,
      );
    }
    final translation = target.translations[effective];
    final used = translation ?? target.translations[fallback];
    return DialogueTextResolution(
      text: used?.text ?? target.source,
      effectiveLocale: effective,
      textLocale: translation != null
          ? effective
          : used != null
          ? fallback
          : sourceLocale,
      status: translation == null
          ? DialogueTranslationStatus.missing
          : translation.source != target.source
          ? DialogueTranslationStatus.needsReview
          : DialogueTranslationStatus.translated,
      needsReview: used != null && used.source != target.source,
    );
  }

  Map<String, dynamic> toJson() => {
    'format': 1,
    'sourceLocale': sourceLocale,
    'units': [for (final unit in units) unit.toJson()],
  };
}
