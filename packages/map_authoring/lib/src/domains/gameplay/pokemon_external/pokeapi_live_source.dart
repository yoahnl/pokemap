import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../../documents/document_errors.dart';
import 'pokemon_external_http_transport.dart';
import 'pokemon_external_source_repository.dart';

class PokeApiLiveSource {
  PokeApiLiveSource({
    required PokemonExternalHttpTransport client,
    this.baseUri = const String.fromEnvironment(
      'POKEAPI_BASE_URI',
      defaultValue: 'https://pokeapi.co/api/v2',
    ),
    this.requestTimeout = const Duration(seconds: 20),
    this.userAgent = _defaultUserAgent,
  }) : _client = client;

  static const String _defaultUserAgent =
      'PokeMapEditor/0.1 (+https://pokemap.local)';
  static const Map<String, String> _canonicalSpeciesIdentifiers =
      <String, String>{
    'nidoranf': 'nidoran-f',
    'nidoranm': 'nidoran-m',
    'mrmime': 'mr-mime',
    'hooh': 'ho-oh',
    'mimejr': 'mime-jr',
    'porygonz': 'porygon-z',
  };

  final PokemonExternalHttpTransport _client;
  final String baseUri;
  final Duration requestTimeout;
  final String userAgent;

  final Map<String, Map<String, dynamic>> _pokemonCache =
      <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> _pokemonSpeciesCache =
      <String, Map<String, dynamic>>{};
  final Map<String, String> _defaultPokemonBySpecies = <String, String>{};
  final Map<String, Map<String, dynamic>> _evolutionChainCache =
      <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> _itemCache =
      <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> _itemListCache =
      <String, Map<String, dynamic>>{};
  final Map<String, PokemonExternalBinaryAsset> _assetCache =
      <String, PokemonExternalBinaryAsset>{};

  Future<Map<String, dynamic>> fetchPokemon(String speciesId) async {
    final cacheKey = _normalizeKey(speciesId);
    final cached = _pokemonCache[cacheKey];
    if (cached != null) {
      return _deepCopy(cached);
    }
    final apiKey = _defaultPokemonBySpecies[cacheKey] ??
        _canonicalSpeciesIdentifiers[cacheKey] ??
        cacheKey;

    final payload = await _getJsonObject(
      _resolveApiUri('pokemon/$apiKey'),
      notFoundMessage:
          'External PokeAPI pokemon payload not found for species "$speciesId"',
      contextLabel: 'PokeAPI pokemon payload',
    );
    _pokemonCache[cacheKey] = payload;
    final canonicalName = _readNamedResourceName(payload['name']);
    if (canonicalName.isNotEmpty) {
      _pokemonCache.putIfAbsent(canonicalName, () => payload);
    }
    return _deepCopy(payload);
  }

  Future<Map<String, dynamic>> fetchPokemonSpecies(String speciesId) async {
    final cacheKey = _normalizeKey(speciesId);
    final cached = _pokemonSpeciesCache[cacheKey];
    if (cached != null) {
      return _deepCopy(cached);
    }
    final apiKey = _canonicalSpeciesIdentifiers[cacheKey] ?? cacheKey;

    final payload = await _getJsonObject(
      _resolveApiUri('pokemon-species/$apiKey'),
      notFoundMessage:
          'External PokeAPI pokemon-species payload not found for species "$speciesId"',
      contextLabel: 'PokeAPI pokemon-species payload',
    );
    _pokemonSpeciesCache[cacheKey] = payload;

    final canonicalName = _readNamedResourceName(payload['name']);
    if (canonicalName.isNotEmpty) {
      _pokemonSpeciesCache.putIfAbsent(canonicalName, () => payload);
      final defaultPokemon = _readDefaultPokemonName(payload);
      if (defaultPokemon.isNotEmpty) {
        _defaultPokemonBySpecies[cacheKey] = defaultPokemon;
        _defaultPokemonBySpecies[canonicalName] = defaultPokemon;
      }
    }

    return _deepCopy(payload);
  }

  Future<Map<String, dynamic>> fetchEvolutionChainForSpecies(
    String speciesId,
  ) async {
    final speciesPayload = await fetchPokemonSpecies(speciesId);
    final rawEvolutionChain = speciesPayload['evolution_chain'];
    if (rawEvolutionChain is! Map) {
      throw const EditorPersistenceException(
        'PokeAPI pokemon-species payload must contain an evolution_chain object',
      );
    }

    final evolutionChainUrl = (rawEvolutionChain['url'] as String?)?.trim();
    if (evolutionChainUrl == null || evolutionChainUrl.isEmpty) {
      throw const EditorPersistenceException(
        'PokeAPI pokemon-species payload must contain an evolution chain URL',
      );
    }

    final cached = _evolutionChainCache[evolutionChainUrl];
    if (cached != null) {
      return _deepCopy(cached);
    }

    final payload = await _getJsonObject(
      Uri.parse(evolutionChainUrl),
      notFoundMessage:
          'External PokeAPI evolution chain payload not found for species "$speciesId"',
      contextLabel: 'PokeAPI evolution-chain payload',
    );
    _evolutionChainCache[evolutionChainUrl] = payload;
    return _deepCopy(payload);
  }

  Future<Map<String, dynamic>> fetchItemsResourceList({
    required int limit,
    required int offset,
  }) async {
    final cacheKey = '$limit:$offset';
    final cached = _itemListCache[cacheKey];
    if (cached != null) {
      return _deepCopy(cached);
    }

    final payload = await _getJsonObject(
      _resolveApiUri('item?limit=$limit&offset=$offset'),
      notFoundMessage:
          'External PokeAPI item list payload not found for limit=$limit offset=$offset',
      contextLabel: 'PokeAPI item list payload',
    );
    _itemListCache[cacheKey] = payload;
    return _deepCopy(payload);
  }

  Future<Map<String, dynamic>> fetchItem(String itemIdOrName) async {
    final cacheKey = _normalizeKey(itemIdOrName);
    final cached = _itemCache[cacheKey];
    if (cached != null) {
      return _deepCopy(cached);
    }

    final payload = await _getJsonObject(
      _resolveApiUri('item/$cacheKey'),
      notFoundMessage:
          'External PokeAPI item payload not found for item "$itemIdOrName"',
      contextLabel: 'PokeAPI item payload',
    );
    _itemCache[cacheKey] = payload;

    final canonicalName = _readNamedResourceName(payload['name']);
    if (canonicalName.isNotEmpty) {
      _itemCache.putIfAbsent(canonicalName, () => payload);
    }

    return _deepCopy(payload);
  }

  Future<PokemonExternalBinaryAsset> fetchBinaryAsset(String sourceUrl) async {
    final normalizedUrl = sourceUrl.trim();
    if (normalizedUrl.isEmpty) {
      throw const EditorValidationException(
        'External asset sourceUrl cannot be empty',
      );
    }

    final cached = _assetCache[normalizedUrl];
    if (cached != null) {
      return cached;
    }

    final response = await _sendRequest(
      Uri.parse(normalizedUrl),
      contextLabel: 'external binary asset',
      notFoundMessage: 'External asset not found: $normalizedUrl',
    );
    final contentType = response.headers['content-type']?.trim();
    final asset = PokemonExternalBinaryAsset(
      sourceUrl: normalizedUrl,
      bytes: Uint8List.fromList(response.bodyBytes),
      contentType: contentType?.isEmpty ?? true ? null : contentType,
    );
    _assetCache[normalizedUrl] = asset;
    return asset;
  }

  Uri _resolveApiUri(String relativePath) {
    final normalizedBase = baseUri.endsWith('/') ? baseUri : '$baseUri/';
    return Uri.parse(normalizedBase).resolve(relativePath);
  }

  Future<Map<String, dynamic>> _getJsonObject(
    Uri uri, {
    required String notFoundMessage,
    required String contextLabel,
  }) async {
    final response = await _sendRequest(
      uri,
      contextLabel: contextLabel,
      notFoundMessage: notFoundMessage,
    );

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException catch (error) {
      throw EditorPersistenceException(
        '$contextLabel is not valid JSON: ${error.message}',
      );
    }

    if (decoded is! Map) {
      throw EditorPersistenceException(
        '$contextLabel must decode to a JSON object',
      );
    }

    return decoded.cast<String, dynamic>();
  }

  Future<PokemonExternalHttpResponse> _sendRequest(
    Uri uri, {
    required String contextLabel,
    required String notFoundMessage,
  }) async {
    final response = await _sendWithTimeout(
      () => _client.get(uri, headers: {
        'accept': 'application/json, text/plain, */*',
        'user-agent': userAgent,
      }),
      contextLabel,
    );

    if (response.statusCode == 404) {
      throw EditorNotFoundException(notFoundMessage);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EditorPersistenceException(
        '$contextLabel request failed with HTTP ${response.statusCode}',
      );
    }

    return response;
  }

  Future<T> _sendWithTimeout<T>(
    Future<T> Function() action,
    String contextLabel,
  ) async {
    try {
      return await action().timeout(requestTimeout);
    } on TimeoutException {
      throw EditorPersistenceException(
        '$contextLabel request timed out after ${requestTimeout.inSeconds}s',
      );
    } on EditorApplicationException {
      rethrow;
    } catch (error) {
      throw EditorPersistenceException('$contextLabel request failed: $error');
    }
  }

  String _normalizeKey(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw const EditorValidationException(
        'External species identifier cannot be empty',
      );
    }
    return trimmed.toLowerCase();
  }

  String _readNamedResourceName(Object? raw) {
    if (raw is String) {
      return raw.trim().toLowerCase();
    }
    if (raw is! Map) {
      return '';
    }
    return (raw['name'] as String?)?.trim().toLowerCase() ?? '';
  }

  String _readDefaultPokemonName(Map<String, dynamic> payload) {
    final varieties = payload['varieties'];
    if (varieties is! List) {
      return '';
    }
    for (final rawVariety in varieties) {
      if (rawVariety is! Map || rawVariety['is_default'] != true) {
        continue;
      }
      return _readNamedResourceName(rawVariety['pokemon']);
    }
    return '';
  }

  Map<String, dynamic> _deepCopy(Map<String, dynamic> source) {
    return jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
  }
}
