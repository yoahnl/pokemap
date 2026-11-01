import 'dart:convert';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

class _Transport implements PokemonExternalHttpTransport {
  final requests = <Uri>[];

  @override
  Future<PokemonExternalHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    requests.add(uri);
    final body = uri.path.endsWith('/pokemon-species/bulbasaur')
        ? jsonEncode({
            'name': 'bulbasaur',
            'evolution_chain': {
              'url': 'https://pokemon-api.yoahn.me/v1/compat/'
                  'public-2026-11/pokeapi/evolution-chain/1',
            },
          })
        : uri.path.endsWith('/pokedex.json')
            ? jsonEncode({
                'bulbasaur': {'name': 'Bulbasaur'}
              })
            : '{}';
    return PokemonExternalHttpResponse(
      statusCode: 200,
      headers: const {'content-type': 'application/json'},
      body: body,
      bodyBytes: Uint8List.fromList(utf8.encode(body)),
    );
  }
}

void main() {
  test('default Pokemon sources use the published Avelune catalog', () async {
    final transport = _Transport();
    final repository = HttpPokemonExternalSourceRepository(
      pokeApiSource: PokeApiLiveSource(client: transport),
      showdownSource: ShowdownSnapshotSource(client: transport),
    );

    await repository.fetchPokeApiPokemonSpeciesPayload('bulbasaur');
    await repository.fetchPokeApiEvolutionChainPayload('bulbasaur');
    await repository.fetchPokeApiPokemonPayload('bulbasaur');
    await repository.fetchPokeApiItemsResourceList(limit: 2, offset: 0);
    await repository.fetchShowdownSpeciesPayload('bulbasaur');
    await repository.fetchShowdownMovesSnapshot();

    expect(transport.requests.map((uri) => uri.origin).toSet(), {
      'https://pokemon-api.yoahn.me',
    });
    expect(
        transport.requests.map((uri) => uri.path),
        containsAll([
          '/v1/compat/public-2026-11/pokeapi/pokemon-species/bulbasaur',
          '/v1/compat/public-2026-11/pokeapi/evolution-chain/1',
          '/v1/compat/public-2026-11/pokeapi/pokemon/bulbasaur',
          '/v1/compat/public-2026-11/pokeapi/item',
          '/v1/compat/public-2026-11/showdown/pokedex.json',
          '/v1/compat/public-2026-11/showdown/moves.json',
        ]));
  });
}
