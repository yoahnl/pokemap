/// Normalise un libellé d'attaque vers l'identifiant local du catalogue.
///
/// Cette fonction est partagée entre le converter Showdown et l'outil de
/// génération des noms localisés : les deux doivent produire exactement le même
/// identifiant à partir du même nom anglais, sinon la table de traductions ne
/// peut plus être indexée de façon fiable.
String normalizePokemonMoveLocalId(String rawValue) {
  final lowerCase = rawValue.trim().toLowerCase();
  if (lowerCase.isEmpty) {
    return '';
  }

  final separated = lowerCase.replaceAll(RegExp(r'[\s-]+'), '_');
  final asciiSafe = separated.replaceAll(RegExp(r'[^a-z0-9_]+'), '');
  final collapsed = asciiSafe.replaceAll(RegExp(r'_+'), '_');
  return collapsed.replaceAll(RegExp(r'^_|_$'), '');
}
