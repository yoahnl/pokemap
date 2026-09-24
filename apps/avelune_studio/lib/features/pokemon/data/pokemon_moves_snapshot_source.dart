import 'package:map_authoring/map_authoring.dart'
    show PokemonExternalSourceRepository;

abstract interface class PokemonMovesSnapshotSource {
  Future<Map<String, dynamic>> fetch();
}

final class ExternalPokemonMovesSnapshotSource
    implements PokemonMovesSnapshotSource {
  const ExternalPokemonMovesSnapshotSource(this.source);

  final PokemonExternalSourceRepository source;

  @override
  Future<Map<String, dynamic>> fetch() => source.fetchShowdownMovesSnapshot();
}
