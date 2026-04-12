import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../application/errors/application_errors.dart';

/// Adaptateur snapshot/data pour Pokémon Showdown.
///
/// L'objectif de cette couche n'est pas d'exposer Showdown comme produit
/// visible dans l'éditeur. Elle sert uniquement d'alimentation complémentaire
/// et structurée pour l'import externe :
/// - `pokedex.json` pour le core species ;
/// - `learnsets.json` et `moves.json` pour les audits et l'extension future ;
/// - aucun parsing Showdown n'est fait dans l'UI.
///
/// Important :
/// - on privilégie les snapshots JSON quand ils existent ;
/// - on garde un cache mémoire simple pour éviter les refetchs ;
/// - on ne vendorise pas de dump tiers massif dans le repo pour cette phase.
class ShowdownSnapshotSource {
  ShowdownSnapshotSource({
    required http.Client client,
    this.baseUri = const String.fromEnvironment(
      'SHOWDOWN_DATA_BASE_URI',
      defaultValue: 'https://play.pokemonshowdown.com/data',
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

  Map<String, dynamic>? _pokedexSnapshot;
  Map<String, dynamic>? _learnsetsSnapshot;
  Map<String, dynamic>? _movesSnapshot;

  /// Extrait une entrée espèce unique depuis le snapshot `pokedex.json`.
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
    return <String, dynamic>{
      'id': normalizedId,
      ..._deepCopy(entry),
    };
  }

  /// Charge le snapshot Pokédex structuré utilisé par le converter species.
  Future<Map<String, dynamic>> fetchPokedexSnapshot() async {
    _pokedexSnapshot ??= await _getSnapshot(
      'pokedex.json',
      contextLabel: 'Showdown pokedex snapshot',
    );
    return _deepCopy(_pokedexSnapshot!);
  }

  /// Charge le snapshot learnsets pour audit, QA et extension future.
  Future<Map<String, dynamic>> fetchLearnsetsSnapshot() async {
    _learnsetsSnapshot ??= await _getSnapshot(
      'learnsets.json',
      contextLabel: 'Showdown learnsets snapshot',
    );
    return _deepCopy(_learnsetsSnapshot!);
  }

  /// Charge le snapshot moves pour garder la donnée structurée accessible.
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
    final request = http.Request('GET', uri)
      ..headers['accept'] = 'application/json, text/plain, */*'
      ..headers['user-agent'] = userAgent;

    final streamedResponse = await _sendWithTimeout(
      () => _client.send(request),
      contextLabel,
    );
    final response = await http.Response.fromStream(streamedResponse);

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
      throw EditorPersistenceException(
        '$contextLabel request failed: $error',
      );
    }
  }

  String _normalizeIdentifier(String value) {
    final normalized = value.trim().toLowerCase();
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
