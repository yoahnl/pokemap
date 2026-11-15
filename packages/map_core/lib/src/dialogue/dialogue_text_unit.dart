part of 'dialogue_localization.dart';

enum DialogueTextKind { line, narration, choice }

enum DialogueTranslationStatus { source, translated, missing, needsReview }

final class DialogueTranslation {
  DialogueTranslation({required String text, required String source})
    : text = _text(text),
      source = _text(source);
  final String text;
  final String source;
  @override
  bool operator ==(Object other) =>
      other is DialogueTranslation &&
      text == other.text &&
      source == other.source;
  @override
  int get hashCode => Object.hash(text, source);
  Map<String, dynamic> toJson() => {'text': text, 'source': source};
}

final class DialogueTextUnit {
  DialogueTextUnit({
    required String id,
    required String binding,
    required this.kind,
    required String source,
    Map<String, DialogueTranslation> translations = const {},
  }) : id = _identifier(id),
       binding = _identifier(binding),
       source = _text(source),
       translations = Map.unmodifiable(_translations(translations));
  final String id;
  final String binding;
  final DialogueTextKind kind;
  final String source;
  final Map<String, DialogueTranslation> translations;

  @override
  bool operator ==(Object other) =>
      other is DialogueTextUnit &&
      id == other.id &&
      binding == other.binding &&
      kind == other.kind &&
      source == other.source &&
      translations.length == other.translations.length &&
      translations.entries.every(
        (entry) => entry.value == other.translations[entry.key],
      );
  @override
  int get hashCode => Object.hash(
    id,
    binding,
    kind,
    source,
    Object.hashAllUnordered(
      translations.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
  );

  DialogueTextUnit copyWith({
    String? id,
    String? binding,
    String? source,
    Map<String, DialogueTranslation>? translations,
  }) => DialogueTextUnit(
    id: id ?? this.id,
    binding: binding ?? this.binding,
    kind: kind,
    source: source ?? this.source,
    translations: translations ?? this.translations,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'binding': binding,
    'kind': kind.name,
    'source': source,
    'translations': {
      for (final locale in translations.keys.toList()..sort())
        locale: translations[locale]!.toJson(),
    },
  };
}

final class DialogueTextResolution {
  const DialogueTextResolution({
    required this.text,
    required this.effectiveLocale,
    required this.textLocale,
    required this.status,
    this.needsReview = false,
  });
  final String text;
  final String effectiveLocale;
  final String textLocale;
  final DialogueTranslationStatus status;
  final bool needsReview;
  bool get usedFallback => effectiveLocale != textLocale;
}

Map<String, DialogueTranslation> _translations(
  Map<String, DialogueTranslation> values,
) {
  final result = <String, DialogueTranslation>{};
  for (final entry in values.entries) {
    if (result.containsKey(_locale(entry.key))) {
      throw ArgumentError('Duplicate translation locale.');
    }
    result[_locale(entry.key)] = entry.value;
  }
  return result;
}
