final class PokedexSpeciesRange {
  PokedexSpeciesRange({
    required this.firstNationalDex,
    required this.lastNationalDex,
  }) {
    if (firstNationalDex < 1 ||
        lastNationalDex < firstNationalDex ||
        lastNationalDex > 65535) {
      throw ArgumentError(
        'A Pokédex species range requires ordered national numbers in 1..65535.',
      );
    }
  }

  final int firstNationalDex, lastNationalDex;
  static const dialogueVariablePrefix = 'pokedex_caught_national_';
  String get key => 'national:$firstNationalDex:$lastNationalDex';
  String get dialogueVariableName =>
      '$dialogueVariablePrefix${firstNationalDex}_$lastNationalDex';
  String get dialoguePlaceholder => '{{ $dialogueVariableName }}';

  static PokedexSpeciesRange? tryFromKey(String value) =>
      _parse(value, RegExp(r'^national:([1-9][0-9]*):([1-9][0-9]*)$'));

  static PokedexSpeciesRange? tryFromDialogueVariableName(String value) =>
      _parse(
        value,
        RegExp(r'^pokedex_caught_national_([1-9][0-9]*)_([1-9][0-9]*)$'),
      );

  static PokedexSpeciesRange? _parse(String value, RegExp pattern) {
    final match = pattern.firstMatch(value);
    if (match == null || match.end != value.length) return null;
    final first = int.tryParse(match[1]!), last = int.tryParse(match[2]!);
    if (first == null ||
        last == null ||
        first < 1 ||
        last < first ||
        last > 65535) {
      return null;
    }
    return PokedexSpeciesRange(firstNationalDex: first, lastNationalDex: last);
  }

  bool contains(int nationalDex) =>
      nationalDex >= firstNationalDex && nationalDex <= lastNationalDex;

  @override
  bool operator ==(Object other) =>
      other is PokedexSpeciesRange &&
      firstNationalDex == other.firstNationalDex &&
      lastNationalDex == other.lastNationalDex;

  @override
  int get hashCode => Object.hash(firstNationalDex, lastNationalDex);
}
