const _maxIdLength = 64;

const _accents = {
  'à': 'a',
  'â': 'a',
  'ä': 'a',
  'á': 'a',
  'ã': 'a',
  'å': 'a',
  'ç': 'c',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'î': 'i',
  'ï': 'i',
  'í': 'i',
  'ì': 'i',
  'ñ': 'n',
  'ô': 'o',
  'ö': 'o',
  'ó': 'o',
  'ò': 'o',
  'õ': 'o',
  'œ': 'oe',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ú': 'u',
  'ÿ': 'y',
  'æ': 'ae',
};

String mapLibraryIdFor(
  String name,
  Set<String> existing, {
  String fallback = 'carte',
}) {
  final buffer = StringBuffer();
  for (final rune in name.toLowerCase().runes) {
    final character = String.fromCharCode(rune);
    final plain = _accents[character] ?? character;
    buffer.write(RegExp(r'^[a-z0-9]+$').hasMatch(plain) ? plain : '-');
  }
  var base = buffer
      .toString()
      .replaceAll(RegExp('-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  if (base.isEmpty) base = fallback;
  if (base.length > _maxIdLength - 4) {
    base = base.substring(0, _maxIdLength - 4).replaceAll(RegExp(r'-$'), '');
  }
  if (!existing.contains(base)) return base;
  for (var index = 2; ; index++) {
    final candidate = '$base-$index';
    if (!existing.contains(candidate)) return candidate;
  }
}
