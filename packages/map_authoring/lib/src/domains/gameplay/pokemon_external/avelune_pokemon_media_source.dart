import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../../documents/document_errors.dart';
import 'pokemon_external_http_transport.dart';

final class AvelunePokemonMedia {
  const AvelunePokemonMedia._({
    required this.id,
    required this.sha256,
    required this.contentType,
    required this.usage,
    required this.representation,
    required this.style,
    required this.metadata,
    required this.release,
  });

  final String id;
  final String sha256;
  final String contentType;
  final String usage;
  final String representation;
  final String style;
  final Map<String, dynamic> metadata;
  final String release;
}

final class AvelunePokemonMediaSource {
  AvelunePokemonMediaSource({
    required PokemonBoundedExternalHttpTransport client,
    this.baseUri = const String.fromEnvironment(
      'AVELUNE_MEDIA_BASE_URI',
      defaultValue: 'https://pokemon-api.yoahn.me/v1/media',
    ),
    this.release = 'public-2026-10',
    this.requestTimeout = const Duration(seconds: 20),
  }) : _client = client {
    _identifier(release);
    final uri = Uri.parse(baseUri);
    if (uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw ArgumentError.value(baseUri, 'baseUri');
    }
  }

  final PokemonBoundedExternalHttpTransport _client;
  final String baseUri;
  final String release;
  final Duration requestTimeout;
  static final _idPattern = RegExp(r'^[a-z0-9][a-z0-9-]{0,127}$');
  static final _hashPattern = RegExp(r'^[a-f0-9]{64}$');

  static void _identifier(String value) {
    if (!_idPattern.hasMatch(value)) throw ArgumentError.value(value);
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse(baseUri.endsWith('/') ? baseUri : '$baseUri/');
    return base.resolve(path).replace(queryParameters: query);
  }

  Future<PokemonExternalHttpResponse> _get(Uri uri, int maximumBytes) async {
    final response = await _client.getBounded(uri,
        headers: const {
          'accept': 'application/json, application/octet-stream, */*',
        },
        maximumBytes: maximumBytes,
        timeout: requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EditorPersistenceException(
          'Media request failed with HTTP ${response.statusCode}');
    }
    return response;
  }

  Future<List<AvelunePokemonMedia>> listPokemonMedia(String speciesId) async {
    _identifier(speciesId);
    final entries = <AvelunePokemonMedia>[];
    final seen = <String>{};
    var after = '';
    while (true) {
      final response = await _get(
          _uri('$release/owners/pokemon/$speciesId', {
            'limit': '100',
            if (after.isNotEmpty) 'after': after,
          }),
          8 * 1024 * 1024);
      if (response.bodyBytes.length > 8 * 1024 * 1024) {
        throw const FormatException('Media catalog page is too large.');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.length > 100) {
        throw const FormatException('Invalid media catalog page.');
      }
      for (final value in decoded) {
        if (value is! Map ||
            value['id'] is! String ||
            value['sha256'] is! String ||
            value['contentType'] is! String ||
            value['usage'] is! String ||
            value['representation'] is! String ||
            value['style'] is! String ||
            value['metadata'] is! Map) {
          throw const FormatException('Invalid media catalog entry.');
        }
        final id = value['id'] as String;
        if (!_idPattern.hasMatch(id) ||
            !seen.add(id) ||
            !_hashPattern.hasMatch(value['sha256'] as String)) {
          throw const FormatException('Invalid or duplicate media identity.');
        }
        entries.add(AvelunePokemonMedia._(
          id: id,
          sha256: value['sha256'] as String,
          contentType: value['contentType'] as String,
          usage: value['usage'] as String,
          representation: value['representation'] as String,
          style: value['style'] as String,
          metadata: Map<String, dynamic>.unmodifiable(
              Map<String, dynamic>.from(value['metadata'] as Map)),
          release: release,
        ));
        after = id;
        if (entries.length > 10000) {
          throw const FormatException('Media catalog is too large.');
        }
      }
      if (decoded.length < 100) return List.unmodifiable(entries);
    }
  }

  Future<Uint8List> readMedia(AvelunePokemonMedia media) async {
    if (media.release != release) throw ArgumentError('Media release differs.');
    final response = await _get(_uri('$release/${media.id}'), 64 * 1024 * 1024);
    if (response.bodyBytes.isEmpty ||
        response.bodyBytes.length > 64 * 1024 * 1024 ||
        sha256.convert(response.bodyBytes).toString() != media.sha256) {
      throw const FormatException('Media content or digest is invalid.');
    }
    return Uint8List.fromList(response.bodyBytes);
  }
}
