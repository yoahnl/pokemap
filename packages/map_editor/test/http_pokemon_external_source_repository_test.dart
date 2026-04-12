import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:map_editor/src/infrastructure/external/pokeapi_live_source.dart';
import 'package:map_editor/src/infrastructure/external/showdown_snapshot_source.dart';
import 'package:map_editor/src/infrastructure/repositories/http_pokemon_external_source_repository.dart';

void main() {
  test('HttpPokemonExternalSourceRepository composes Showdown and PokeAPI',
      () async {
    final client = MockClient((request) async {
      if (request.url.toString() == 'https://showdown.test/data/pokedex.json') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'bulbasaur': <String, Object?>{
              'name': 'Bulbasaur',
              'num': 1,
              'types': <String>['Grass', 'Poison'],
            },
          }),
          200,
          headers: const <String, String>{
            'content-type': 'application/json',
          },
        );
      }
      if (request.url.toString() == 'https://showdown.test/data/moves.json') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'thunderbolt': <String, Object?>{'name': 'Thunderbolt'},
          }),
          200,
          headers: const <String, String>{
            'content-type': 'application/json',
          },
        );
      }
      if (request.url.toString() ==
          'https://pokeapi.test/api/v2/pokemon-species/bulbasaur') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'name': 'bulbasaur',
            'evolution_chain': <String, Object?>{
              'url': 'https://pokeapi.test/api/v2/evolution-chain/1/',
            },
          }),
          200,
          headers: const <String, String>{
            'content-type': 'application/json',
          },
        );
      }
      if (request.url.toString() ==
          'https://pokeapi.test/api/v2/pokemon/bulbasaur') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'name': 'bulbasaur',
            'moves': <Object?>[],
          }),
          200,
          headers: const <String, String>{
            'content-type': 'application/json',
          },
        );
      }
      if (request.url.toString() ==
          'https://pokeapi.test/api/v2/evolution-chain/1/') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'chain': <String, Object?>{
              'species': <String, Object?>{'name': 'bulbasaur'},
              'evolves_to': <Object?>[],
            },
          }),
          200,
          headers: const <String, String>{
            'content-type': 'application/json',
          },
        );
      }
      if (request.url.toString() == 'https://assets.test/front.png') {
        return http.Response.bytes(
          <int>[1, 2, 3, 4],
          200,
          headers: const <String, String>{
            'content-type': 'image/png',
          },
        );
      }
      return http.Response('not found', 404);
    });

    final repository = HttpPokemonExternalSourceRepository(
      pokeApiSource: PokeApiLiveSource(
        client: client,
        baseUri: 'https://pokeapi.test/api/v2',
      ),
      showdownSource: ShowdownSnapshotSource(
        client: client,
        baseUri: 'https://showdown.test/data',
      ),
    );

    final pokedexSnapshot = await repository.fetchShowdownPokedexSnapshot();
    final showdown = await repository.fetchShowdownSpeciesPayload('bulbasaur');
    final movesSnapshot = await repository.fetchShowdownMovesSnapshot();
    final pokemon = await repository.fetchPokeApiPokemonPayload('bulbasaur');
    final pokemonSpecies =
        await repository.fetchPokeApiPokemonSpeciesPayload('bulbasaur');
    final evolution =
        await repository.fetchPokeApiEvolutionChainPayload('bulbasaur');
    final asset = await repository.fetchBinaryAsset(
      'https://assets.test/front.png',
    );

    expect(pokedexSnapshot.containsKey('bulbasaur'), isTrue);
    expect(showdown['name'], 'Bulbasaur');
    expect(movesSnapshot.containsKey('thunderbolt'), isTrue);
    expect(pokemon['name'], 'bulbasaur');
    expect(pokemonSpecies['name'], 'bulbasaur');
    expect(
      ((evolution['chain'] as Map<String, dynamic>)['species']
          as Map<String, dynamic>)['name'],
      'bulbasaur',
    );
    expect(asset.contentType, 'image/png');
  });
}
