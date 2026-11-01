const scopedPokemonMediaHistoryKey = 'pokemonMediaScopedHistory';

bool isPokemonMediaStoragePath(String directory, String relativePath) {
  if (directory.isEmpty || directory == '.') {
    return !relativePath.contains('/') &&
        !relativePath.contains(r'\') &&
        relativePath.toLowerCase() != 'project.json';
  }
  return relativePath.startsWith('$directory/');
}

bool isCanonicalPokemonMediaStoragePath(
  String directory,
  String relativePath,
  String speciesId,
) {
  if (speciesId.isEmpty ||
      speciesId != speciesId.trim() ||
      speciesId == '.' ||
      speciesId == '..' ||
      speciesId.contains('/') ||
      speciesId.contains(r'\')) {
    return false;
  }
  final prefix = directory.isEmpty || directory == '.' ? '' : '$directory/';
  return isPokemonMediaStoragePath(directory, relativePath) &&
      relativePath == '$prefix$speciesId.json';
}
