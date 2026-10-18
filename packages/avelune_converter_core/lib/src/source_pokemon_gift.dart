part of '../avelune_converter_core.dart';

final class SourcePokemonGiftNode extends SourceEventNode {
  const SourcePokemonGiftNode._(
    super.span, {
    required this.sourceSpeciesSymbol,
    required this.level,
    required this.rawDataRef,
    required this.sourceSnapshotHash,
    required this.normalizationHash,
    required this.profileHash,
  });

  final String sourceSpeciesSymbol;
  final int level;
  final SourcePreservedData rawDataRef;
  final Sha256Hash sourceSnapshotHash, normalizationHash, profileHash;

  Map<String, Object?> toJson() => {
        'kind': 'literalPokemonGift',
        'helper': 'pbAddPokemon',
        'sourceSpeciesSymbol': sourceSpeciesSymbol,
        'level': level,
        'span': span.toJson(),
        'rawDataRef': rawDataRef.toJson(),
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'profileHash': profileHash.value,
        'sourceScriptsExecuted': 0,
        'nativeExecutionQualified': false,
      };
}

final class _SourcePokemonGiftLiteral {
  _SourcePokemonGiftLiteral(this.source);
  final String source;
  var index = 0;

  void whitespace() {
    while (index < source.length &&
        const [9, 32].contains(source.codeUnitAt(index))) {
      index++;
    }
  }

  bool token(String token) {
    whitespace();
    if (!source.startsWith(token, index)) return false;
    index += token.length;
    return true;
  }

  (String, int)? parse() {
    if (source.length > 512 ||
        !token('pbAddPokemon') ||
        !token('(') ||
        !token(':')) {
      return null;
    }
    final symbolStart = index;
    while (index < source.length) {
      final c = source.codeUnitAt(index);
      if (!(c >= 65 && c <= 90 ||
          index > symbolStart && (c >= 48 && c <= 57 || c == 95))) {
        break;
      }
      index++;
    }
    final symbol = source.substring(symbolStart, index);
    if (symbol.isEmpty || symbol.length > 192 || !token(',')) {
      return null;
    }
    whitespace();
    final levelStart = index;
    while (index < source.length &&
        source.codeUnitAt(index) >= 48 &&
        source.codeUnitAt(index) <= 57) {
      index++;
    }
    final digits = source.substring(levelStart, index);
    if (digits.isEmpty || digits.length > 3 || digits.startsWith('0')) {
      return null;
    }
    final level = int.parse(digits);
    if (level < 1 || level > 100 || !token(')')) {
      return null;
    }
    whitespace();
    return index == source.length ? (symbol, level) : null;
  }
}
