final class RuntimePlayerLanguageChoice {
  const RuntimePlayerLanguageChoice.followApplication() : this._(null);

  const RuntimePlayerLanguageChoice._(this.languageTag);

  factory RuntimePlayerLanguageChoice.explicit(String languageTag) {
    final normalized = tryNormalizeLanguageTag(languageTag);
    if (normalized == null) {
      throw FormatException('Invalid Player language tag.', languageTag);
    }
    return RuntimePlayerLanguageChoice._(normalized);
  }

  final String? languageTag;

  static const _grandfatheredRegionTags = {
    'en-gb-oed': 'en-GB-oed',
    'sgn-be-fr': 'sgn-BE-FR',
    'sgn-be-nl': 'sgn-BE-NL',
    'sgn-ch-de': 'sgn-CH-DE',
  };

  static final _languageTagPattern = RegExp(
    r'^(?:'
    r'(?<language>[a-z]{2,3}(?:-[a-z]{3}){0,3}|[a-z]{4,8})'
    r'(?<script>-[a-z]{4})?'
    r'(?<region>-(?:[a-z]{2}|[0-9]{3}))?'
    r'(?<variants>(?:-(?:[a-z0-9]{5,8}|[0-9][a-z0-9]{3}))*)'
    r'(?<extensions>(?:-[a-wy-z0-9](?:-[a-z0-9]{2,8})+)*)'
    r'(?:-x(?:-[a-z0-9]{1,8})+)?'
    r'|x(?:-[a-z0-9]{1,8})+'
    r'|i-(?:ami|bnn|default|enochian|hak|klingon|lux|mingo|navajo|pwn|tao|tay|tsu)'
    r')$',
  );

  static String? tryNormalizeLanguageTag(String languageTag) {
    final normalized = languageTag.trim().replaceAll('_', '-').toLowerCase();
    final grandfathered = _grandfatheredRegionTags[normalized];
    if (grandfathered != null) return grandfathered;

    final match = _languageTagPattern.firstMatch(normalized);
    if (match == null) return null;
    final language = match.namedGroup('language');
    if (language == null) return normalized;

    final variants = match.namedGroup('variants')!.split('-').skip(1);
    final extensions = match
        .namedGroup('extensions')!
        .split('-')
        .where((subtag) => subtag.length == 1);
    if (variants.toSet().length != variants.length ||
        extensions.toSet().length != extensions.length) {
      return null;
    }

    final script = match.namedGroup('script') ?? '';
    final region = match.namedGroup('region') ?? '';
    final titleCaseScript = script.isEmpty
        ? ''
        : '-${script[1].toUpperCase()}${script.substring(2)}';
    return normalized.replaceRange(
      language.length,
      language.length + script.length + region.length,
      '$titleCaseScript${region.toUpperCase()}',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RuntimePlayerLanguageChoice && languageTag == other.languageTag;

  @override
  int get hashCode => languageTag.hashCode;
}
