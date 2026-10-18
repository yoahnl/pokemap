part of '../avelune_converter_core.dart';

final class SourceShopProgramNode extends SourceEventNode {
  SourceShopProgramNode._(super.span,
      {required List<String> sourceItemSymbols,
      required this.rawDataRef,
      required this.sourceSnapshotHash,
      required this.normalizationHash,
      required this.profileHash})
      : sourceItemSymbols = List.unmodifiable(sourceItemSymbols);

  final List<String> sourceItemSymbols;
  final SourcePreservedData rawDataRef;
  final Sha256Hash sourceSnapshotHash, normalizationHash, profileHash;

  Map<String, Object?> toJson() => {
        'kind': 'literalPokemonMart',
        'helper': 'pbPokemonMart',
        'sourceItemSymbols': sourceItemSymbols,
        'span': span.toJson(),
        'rawDataRef': rawDataRef.toJson(),
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'profileHash': profileHash.value,
        'sourceScriptsExecuted': 0,
        'nativeExecutionQualified': false,
      };
}

List<String>? _sourceShopLiteral(String source) {
  if (source.length > 16384) return null;
  final match = RegExp(
          r'^\s*pbPokemonMart\s*\(\s*\[\s*(:[A-Z][A-Z0-9_]{0,127}(?:\s*,\s*:[A-Z][A-Z0-9_]{0,127})*\s*,?)\s*\]\s*\)\s*$')
      .firstMatch(source);
  if (match == null) return null;
  final symbols = RegExp(r':([A-Z][A-Z0-9_]*)')
      .allMatches(match[1]!)
      .map((entry) => entry[1]!)
      .toList();
  if (symbols.isEmpty ||
      symbols.length > 128 ||
      symbols.toSet().length != symbols.length) {
    return null;
  }
  return symbols;
}
