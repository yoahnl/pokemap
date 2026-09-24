import 'package:http/http.dart' as http;
import 'package:map_authoring/map_authoring.dart';

import 'http_pokemon_external_transport.dart';

final class PokemonExternalSourceSession {
  PokemonExternalSourceSession(PokemonExternalSourceRepository? provided)
    : _client = provided == null ? http.Client() : null {
    source =
        provided ??
        HttpPokemonExternalSourceRepository(
          pokeApiSource: PokeApiLiveSource(
            client: HttpPokemonExternalTransport(_client!),
          ),
          showdownSource: ShowdownSnapshotSource(
            client: HttpPokemonExternalTransport(_client),
          ),
        );
  }

  final http.Client? _client;
  late final PokemonExternalSourceRepository source;

  void dispose() => _client?.close();
}
