import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/infrastructure/external/pokeapi_live_source.dart';

void main() {
  group('PokeApiLiveSource', () {
    test('fetches pokemon, pokemon-species and evolution-chain payloads',
        () async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/pokemon/bulbasaur')) {
          return http.Response(
            jsonEncode(<String, Object?>{
              'name': 'bulbasaur',
              'base_experience': 64,
            }),
            200,
            headers: <String, String>{
              'content-type': 'application/json',
            },
          );
        }
        if (request.url.path.endsWith('/pokemon-species/bulbasaur')) {
          return http.Response(
            jsonEncode(<String, Object?>{
              'name': 'bulbasaur',
              'evolution_chain': <String, Object?>{
                'url': 'https://pokeapi.test/api/v2/evolution-chain/1/',
              },
            }),
            200,
            headers: <String, String>{
              'content-type': 'application/json',
            },
          );
        }
        if (request.url.path.endsWith('/evolution-chain/1/')) {
          return http.Response(
            jsonEncode(<String, Object?>{
              'chain': <String, Object?>{
                'species': <String, Object?>{'name': 'bulbasaur'},
                'evolves_to': <Object?>[],
              },
            }),
            200,
            headers: <String, String>{
              'content-type': 'application/json',
            },
          );
        }
        return http.Response('not found', 404);
      });

      final source = PokeApiLiveSource(
        client: client,
        baseUri: 'https://pokeapi.test/api/v2',
      );

      final pokemon = await source.fetchPokemon('bulbasaur');
      final pokemonSpecies = await source.fetchPokemonSpecies('bulbasaur');
      final evolution = await source.fetchEvolutionChainForSpecies('bulbasaur');

      expect(pokemon['name'], 'bulbasaur');
      expect(pokemonSpecies['name'], 'bulbasaur');
      expect(
        ((evolution['chain'] as Map<String, dynamic>)['species']
            as Map<String, dynamic>)['name'],
        'bulbasaur',
      );
    });

    test('surfaces 404 as EditorNotFoundException', () async {
      final source = PokeApiLiveSource(
        client: MockClient((request) async => http.Response('missing', 404)),
        baseUri: 'https://pokeapi.test/api/v2',
      );

      await expectLater(
        () => source.fetchPokemon('missingno'),
        throwsA(
          isA<EditorNotFoundException>().having(
            (error) => error.message,
            'message',
            'External PokeAPI pokemon payload not found for species "missingno"',
          ),
        ),
      );
    });

    test('downloads a binary asset with content type', () async {
      final source = PokeApiLiveSource(
        client: MockClient((request) async {
          return http.Response.bytes(
            Uint8List.fromList(<int>[1, 2, 3, 4]),
            200,
            headers: <String, String>{
              'content-type': 'image/png',
            },
          );
        }),
        baseUri: 'https://pokeapi.test/api/v2',
      );

      final asset = await source.fetchBinaryAsset(
        'https://assets.test/bulbasaur/front.png',
      );

      expect(asset.sourceUrl, 'https://assets.test/bulbasaur/front.png');
      expect(asset.contentType, 'image/png');
      expect(asset.bytes.toList(), <int>[1, 2, 3, 4]);
    });
  });
}
