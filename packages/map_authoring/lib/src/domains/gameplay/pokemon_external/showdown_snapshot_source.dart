import 'dart:async';
import 'dart:convert';

import '../../../documents/document_errors.dart';
import 'pokemon_external_http_transport.dart';

class ShowdownSnapshotSource {
  ShowdownSnapshotSource({
    required PokemonExternalHttpTransport client,
    this.baseUri = const String.fromEnvironment(
      'SHOWDOWN_DATA_BASE_URI',
      defaultValue: 'https://play.pokemonshowdown.com/data',
    ),
    this.requestTimeout = const Duration(seconds: 20),
    this.userAgent = _defaultUserAgent,
  }) : _client = client;

  static const String _defaultUserAgent =
      'PokeMapEditor/0.1 (+https://pokemap.local)';

  final PokemonExternalHttpTransport _client;
  final String baseUri;
  final Duration requestTimeout;
  final String userAgent;

  Map<String, dynamic>? _pokedexSnapshot;
  Map<String, dynamic>? _learnsetsSnapshot;
  Map<String, dynamic>? _movesSnapshot;

  Future<Map<String, dynamic>> fetchSpecies(String speciesId) async {
    final normalizedId = _normalizeIdentifier(speciesId);
    final snapshot = await fetchPokedexSnapshot();
    final rawEntry = snapshot[normalizedId];
    if (rawEntry is! Map) {
      throw EditorNotFoundException(
        'External Showdown species payload not found for species "$speciesId"',
      );
    }

    final entry = rawEntry.cast<String, dynamic>();
    return <String, dynamic>{'id': normalizedId, ..._deepCopy(entry)};
  }

  Future<Map<String, dynamic>> fetchPokedexSnapshot() async {
    _pokedexSnapshot ??= await _getSnapshot(
      'pokedex.json',
      contextLabel: 'Showdown pokedex snapshot',
    );
    return _deepCopy(_pokedexSnapshot!);
  }

  Future<Map<String, dynamic>> fetchLearnsetsSnapshot() async {
    _learnsetsSnapshot ??= await _getSnapshot(
      'learnsets.json',
      contextLabel: 'Showdown learnsets snapshot',
    );
    return _deepCopy(_learnsetsSnapshot!);
  }

  Future<Map<String, dynamic>> fetchMovesSnapshot() async {
    _movesSnapshot ??= await _getSnapshot(
      'moves.json',
      contextLabel: 'Showdown moves snapshot',
    );
    return _deepCopy(_movesSnapshot!);
  }

  Future<Map<String, dynamic>> _getSnapshot(
    String relativePath, {
    required String contextLabel,
  }) async {
    final uri = _resolveUri(relativePath);
    final response = await _sendWithTimeout(
      () => _client.get(uri, headers: {
        'accept': 'application/json, text/plain, */*',
        'user-agent': userAgent,
      }),
      contextLabel,
    );

    if (response.statusCode == 404) {
      throw EditorNotFoundException('$contextLabel not found');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EditorPersistenceException(
        '$contextLabel request failed with HTTP ${response.statusCode}',
      );
    }

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

  Uri _resolveUri(String relativePath) {
    final normalizedBase = baseUri.endsWith('/') ? baseUri : '$baseUri/';
    return Uri.parse(normalizedBase).resolve(relativePath);
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

  String _normalizeIdentifier(String value) {
    final normalized = value.trim().toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]+'),
          '',
        );
    if (normalized.isEmpty) {
      throw const EditorValidationException(
        'Showdown species identifier cannot be empty',
      );
    }
    return normalized;
  }

  Map<String, dynamic> _deepCopy(Map<String, dynamic> source) {
    return jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
  }
}
