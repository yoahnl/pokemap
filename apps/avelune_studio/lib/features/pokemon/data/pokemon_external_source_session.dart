import 'package:http/http.dart' as http;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart'
    show aveluneCatalogRelease;

import 'http_pokemon_external_transport.dart';

final class PokemonExternalSourceSession {
  PokemonExternalSourceSession(
    PokemonExternalSourceRepository? provided, {
    String release = aveluneCatalogRelease,
  }) : _client = provided == null ? http.Client() : null {
    source =
        provided ??
        HttpPokemonExternalSourceRepository(
          pokeApiSource: PokeApiLiveSource(
            client: HttpPokemonExternalTransport(_client!),
            release: release,
          ),
          showdownSource: ShowdownSnapshotSource(
            client: HttpPokemonExternalTransport(_client),
            release: release,
          ),
        );
  }

  final http.Client? _client;
  late final PokemonExternalSourceRepository source;

  void dispose() => _client?.close();
}
