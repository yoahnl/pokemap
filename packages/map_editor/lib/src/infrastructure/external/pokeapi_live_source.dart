import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../application/errors/application_errors.dart';
import '../../application/ports/pokemon_external_source_repository.dart';

/// Adaptateur HTTP concret vers PokeAPI.
///
/// Cette couche reste purement infrastructure :
/// - elle parle HTTP et JSON ;
/// - elle applique une politique réseau sobre avec cache mémoire simple ;
/// - elle ne convertit pas les payloads vers les modèles métier du projet.
///
/// Le use case externe garde ainsi une seule responsabilité :
/// orchestrer l'import Pokémon à partir de payloads déjà décodés.
class PokeApiLiveSource {
  PokeApiLiveSource({
    required http.Client client,
    this.baseUri = const String.fromEnvironment(
      'POKEAPI_BASE_URI',
      defaultValue: 'https://pokeapi.co/api/v2',
    ),
    this.requestTimeout = const Duration(seconds: 20),
    this.userAgent = _defaultUserAgent,
  }) : _client = client;

  static const String _defaultUserAgent =
      'PokeMapEditor/0.1 (+https://pokemap.local)';

  final http.Client _client;
  final String baseUri;
  final Duration requestTimeout;
  final String userAgent;

  final Map<String, Map<String, dynamic>> _pokemonCache =
      <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> _pokemonSpeciesCache =
      <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> _evolutionChainCache =
      <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> _itemCache =
      <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> _itemListCache =
      <String, Map<String, dynamic>>{};
  final Map<String, PokemonExternalBinaryAsset> _assetCache =
      <String, PokemonExternalBinaryAsset>{};

  /// Lit `/pokemon/{id or name}` avec un cache mémoire par clé normalisée.
  Future<Map<String, dynamic>> fetchPokemon(String speciesId) async {
    final cacheKey = _normalizeKey(speciesId);
    final cached = _pokemonCache[cacheKey];
    if (cached != null) {
      return _deepCopy(cached);
    }

    final payload = await _getJsonObject(
      _resolveApiUri('pokemon/$cacheKey'),
      notFoundMessage:
          'External PokeAPI pokemon payload not found for species "$speciesId"',
      contextLabel: 'PokeAPI pokemon payload',
    );
    _pokemonCache[cacheKey] = payload;
    return _deepCopy(payload);
  }

  /// Lit `/pokemon-species/{id or name}` avec un cache mémoire par clé.
  Future<Map<String, dynamic>> fetchPokemonSpecies(String speciesId) async {
    final cacheKey = _normalizeKey(speciesId);
    final cached = _pokemonSpeciesCache[cacheKey];
    if (cached != null) {
      return _deepCopy(cached);
    }

    final payload = await _getJsonObject(
      _resolveApiUri('pokemon-species/$cacheKey'),
      notFoundMessage:
          'External PokeAPI pokemon-species payload not found for species "$speciesId"',
      contextLabel: 'PokeAPI pokemon-species payload',
    );
    _pokemonSpeciesCache[cacheKey] = payload;

    final canonicalName = _readNamedResourceName(payload['name']);
    if (canonicalName.isNotEmpty) {
      _pokemonSpeciesCache.putIfAbsent(canonicalName, () => payload);
    }

    return _deepCopy(payload);
  }

  /// Lit la chaîne d'évolution en partant d'un payload `pokemon-species`.
  ///
  /// Le lot 11A garde cette étape dans l'adaptateur réseau pour éviter de
  /// remonter des détails d'URL PokeAPI au use case applicatif.
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

  /// Télécharge un asset binaire distant.
  ///
  /// Cette méthode est réutilisée pour les sprites PNG et les cries OGG. Le
  /// cache mémoire évite les doublons pendant une session d'import ou un test.
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

  Future<http.Response> _sendRequest(
    Uri uri, {
    required String contextLabel,
    required String notFoundMessage,
  }) async {
    final request = http.Request('GET', uri)
      ..headers['accept'] = 'application/json, text/plain, */*'
      ..headers['user-agent'] = userAgent;

    final streamedResponse = await _sendWithTimeout(
      () => _client.send(request),
      contextLabel,
    );
    final response = await http.Response.fromStream(streamedResponse);

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
      throw EditorPersistenceException(
        '$contextLabel request failed: $error',
      );
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

  Map<String, dynamic> _deepCopy(Map<String, dynamic> source) {
    return jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
  }
}
