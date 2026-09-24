import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring.dart'
    show PokemonExternalSourceRepository, PokemonExternalBinaryAsset;

class PokemonExternalSourceFixture implements PokemonExternalSourceRepository {
  const PokemonExternalSourceFixture({this.networkFailure = false});

  final bool networkFailure;

  Future<Map<String, dynamic>> _read(String name) async {
    if (networkFailure) throw const SocketException('source indisponible');
    final file = File('test/fixtures/pokemon_external/$name.json');
    return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownPokedexSnapshot() async => {
    'bulbasaur': await _read('bulbasaur_showdown'),
  };

  @override
  Future<Map<String, dynamic>> fetchShowdownSpeciesPayload(String id) async {
    if (id != 'bulbasaur') throw StateError('Espèce absente : $id');
    return {'id': id, ...await _read('bulbasaur_showdown')};
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonSpeciesPayload(String id) =>
      _read('bulbasaur_pokeapi_species');

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonPayload(String id) =>
      _read('bulbasaur_pokeapi_pokemon');

  @override
  Future<Map<String, dynamic>> fetchPokeApiEvolutionChainPayload(String id) =>
      _read('bulbasaur_pokeapi_evolution');

  @override
  Future<Map<String, dynamic>> fetchShowdownMovesSnapshot() =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> fetchPokeApiItemsResourceList({
    required int limit,
    required int offset,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> fetchPokeApiItemPayload(String id) =>
      throw UnimplementedError();

  @override
  Future<PokemonExternalBinaryAsset> fetchBinaryAsset(String url) async =>
      PokemonExternalBinaryAsset(sourceUrl: url, bytes: Uint8List(0));
}

class HeldPokemonExternalSourceFixture extends PokemonExternalSourceFixture {
  final gate = Completer<void>();

  @override
  Future<Map<String, dynamic>> fetchShowdownPokedexSnapshot() async {
    await gate.future;
    return super.fetchShowdownPokedexSnapshot();
  }
}
