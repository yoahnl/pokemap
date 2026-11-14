import '../domain/pokemon_workspace_models.dart';

final class PokemonDocumentWriteRequest {
  const PokemonDocumentWriteRequest({
    required this.family,
    required this.relativePath,
    required this.beforeBytes,
    required this.document,
  });

  final PokemonDocumentFamily family;
  final String relativePath;
  final List<int>? beforeBytes;
  final Map<String, dynamic> document;
}

typedef PokemonDocumentReadDependency = ({
  String resourceIdentity,
  String relativePath,
  List<int> beforeBytes,
});
