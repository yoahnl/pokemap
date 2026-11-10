import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_distribution/map_distribution.dart';

import '../../../documents/document_errors.dart';
import 'avelune_catalog_release.dart';
import 'pokemon_external_http_transport.dart';

enum PokemonPngRole {
  frontStatic, backStatic, frontShinyStatic, backShinyStatic, icon, overworld,
}

final class PokemonPngFile {
  PokemonPngFile._(AvelunePokemonMedia media, Uint8List data)
      : id = media.id,
        sha256 = media.sha256,
        bytes = Uint8List.fromList(data).asUnmodifiableView();
  final String id;
  final String sha256;
  final Uint8List bytes;
}

final class PokemonPngSelection {
  PokemonPngSelection._(Map<PokemonPngRole, PokemonPngFile> media)
      : media = Map.unmodifiable(media);
  final Map<PokemonPngRole, PokemonPngFile> media;
}

final class AvelunePokemonPngSource {
  const AvelunePokemonPngSource({required this.media});
  final AvelunePokemonMediaSource media;

  Future<PokemonPngSelection> fetch({required String speciesId, required String formId}) async {
    final identity = RegExp(r'^[a-z0-9][a-z0-9-]{0,127}$');
    if (!identity.hasMatch(speciesId) || !identity.hasMatch(formId)) {
      throw ArgumentError('Invalid Pokemon image identity.');
    }
    const battleStyles = [
      'gen5', 'pokeapi-default', 'gen4-heartgold-soulsilver',
      'gba-emerald', 'gba-firered-leafgreen', 'gba-ruby-sapphire',
    ];
    const menuStyles = [
      'gen5', 'gen3', 'scarlet-violet', 'sword-shield', 'legends-za',
      'pokemon-home', 'official-artwork',
    ];
    final candidates = <PokemonPngRole, AvelunePokemonMedia>{};
    final priorities = <PokemonPngRole, int>{};
    final ambiguous = <PokemonPngRole>{};
    for (final item in await media.listPokemonMedia(speciesId)) {
      if (item.contentType != 'image/png' || item.representation != 'sprite2d' ||
          item.metadata['formId'] != formId || item.metadata['gender'] != null ||
          item.metadata['animationFormat'] != null) {
        continue;
      }
      PokemonPngRole? role;
      var priority = -1;
      if (item.usage == 'battle') {
        priority = battleStyles.indexOf(item.style);
        final shiny = item.metadata['shiny'];
        if (shiny != null && shiny is! bool) {
          throw const FormatException('Invalid Pokemon shiny metadata.');
        }
        role = switch ((item.metadata['view'], shiny == true)) {
          ('front', false) => PokemonPngRole.frontStatic,
          ('back', false) => PokemonPngRole.backStatic,
          ('front', true) => PokemonPngRole.frontShinyStatic,
          ('back', true) => PokemonPngRole.backShinyStatic,
          _ => null,
        };
      } else if (item.usage == 'menu') {
        if (item.metadata['shiny'] == true) continue;
        priority = menuStyles.indexOf(item.style);
        role = PokemonPngRole.icon;
      } else if (item.usage == 'overworld' && item.style == 'hgss-inspired' &&
          item.metadata['variant'] == 'regular' && item.metadata['atlas'] is Map) {
        priority = 0;
        role = PokemonPngRole.overworld;
      }
      if (role == null || priority < 0) continue;
      final previous = priorities[role];
      if (previous == priority && candidates[role]!.sha256 != item.sha256) {
        ambiguous.add(role);
      }
      if (previous == null || priority < previous) {
        priorities[role] = priority;
        candidates[role] = item;
        ambiguous.remove(role);
      }
    }
    if (ambiguous.isNotEmpty) {
      throw const FormatException('Ambiguous Pokemon PNG selection.');
    }
    final selected = <PokemonPngRole, PokemonPngFile>{};
    for (final entry in candidates.entries) {
      final bytes = await media.readMedia(entry.value, maximumBytes: 8 * 1024 * 1024);
      final dimensions = decodeRasterImageDimensions(bytes, mediaType: 'image/png');
      if (dimensions == null || dimensions.width * dimensions.height > 16777216) {
        throw const FormatException('Invalid Pokemon PNG.');
      }
      final decoder = validatedStaticPngDecoder(bytes,
          maxDimension: 16384, maxPixels: 16777216);
      if (decoder.decodeFrame(0) == null) {
        throw const FormatException('Invalid Pokemon PNG.');
      }
      final metadata = entry.value.metadata;
      if ((metadata['width'] != null && metadata['width'] != dimensions.width) ||
          (metadata['height'] != null && metadata['height'] != dimensions.height)) {
        throw const FormatException('Pokemon PNG dimensions differ from metadata.');
      }
      if (entry.key == PokemonPngRole.overworld) {
        final atlas = metadata['atlas'] as Map;
        final rows = atlas['rows'];
        final columns = atlas['columns'];
        final width = atlas['tileWidth'];
        final height = atlas['tileHeight'];
        if (rows is! int || columns is! int || width is! int || height is! int ||
            rows != 4 || columns != 4 || width < 1 || height < 1 ||
            width * columns != dimensions.width || height * rows != dimensions.height) {
          throw const FormatException('Invalid Pokemon overworld atlas.');
        }
      }
      selected[entry.key] = PokemonPngFile._(entry.value, bytes);
    }
    return PokemonPngSelection._(selected);
  }
}

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

final class AvelunePokemonCry {
  const AvelunePokemonCry(
      {required this.sha256, required this.mediaType, required this.bytes});

  final String sha256;
  final String mediaType;
  final Uint8List bytes;
}

final class AvelunePokemonCrySource {
  const AvelunePokemonCrySource({required this.media});

  final AvelunePokemonMediaSource media;

  Future<AvelunePokemonCry?> fetch({
    required String speciesId,
    required String formId,
  }) async {
    final identity = RegExp(r'^[a-z0-9][a-z0-9-]{0,127}$');
    if (!identity.hasMatch(speciesId) || !identity.hasMatch(formId)) {
      throw ArgumentError('Invalid Pokemon cry identity.');
    }
    final candidates = (await media.listPokemonMedia(speciesId))
        .where((item) =>
            item.usage == 'cry' &&
            item.representation == 'audio' &&
            item.metadata['formId'] == formId &&
            item.metadata['gender'] == null &&
            const {'latest', 'legacy'}.contains(item.style) &&
            const {'audio/wav', 'audio/mpeg'}.contains(item.contentType))
        .toList();
    for (final style in ['latest', 'legacy']) {
      for (final mime in ['audio/wav', 'audio/mpeg']) {
        var matching = candidates
            .where((item) => item.style == style && item.contentType == mime)
            .toList();
        if (mime == 'audio/wav' && matching.length > 1) {
          final converted = matching.where((item) {
            final provenance = item.metadata['provenance'];
            return provenance is Map &&
                provenance['source'] == 'avelune/cry-wav';
          }).toList();
          if (converted.isNotEmpty) matching = converted;
        }
        if (matching.length > 1) {
          throw const FormatException('Ambiguous Pokemon cry selection.');
        }
        if (matching.isEmpty) continue;
        final item = matching.single;
        final bytes = await media.readMedia(item,
            maximumBytes: maxBattleRecipeSoundBytes);
        inspectBattleRecipeSound(bytes, mime);
        return AvelunePokemonCry(
          sha256: item.sha256,
          mediaType: mime,
          bytes: bytes.asUnmodifiableView(),
        );
      }
    }
    return null;
  }
}

final class AvelunePokemonMediaSource {
  AvelunePokemonMediaSource({
    required PokemonBoundedExternalHttpTransport client,
    this.baseUri = const String.fromEnvironment(
      'AVELUNE_MEDIA_BASE_URI',
      defaultValue: 'https://pokemon-api.yoahn.me/v1/media',
    ),
    this.release = aveluneCatalogRelease,
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

  Future<List<AvelunePokemonMedia>> listPokemonMedia(String speciesId) =>
      _listMedia('pokemon', speciesId);

  Future<List<AvelunePokemonMedia>> listMoveMedia(String moveId,
          {void Function()? check}) =>
      _listMedia('move', moveId, check: check);

  Future<List<AvelunePokemonMedia>> _listMedia(String kind, String ownerId,
      {void Function()? check}) async {
    _identifier(ownerId);
    final entries = <AvelunePokemonMedia>[];
    final seen = <String>{};
    var after = '';
    while (true) {
      check?.call();
      final response = await _get(
          _uri('$release/owners/$kind/$ownerId', {
            'limit': '100',
            if (after.isNotEmpty) 'after': after,
          }),
          8 * 1024 * 1024);
      check?.call();
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

  Future<Uint8List> readMedia(AvelunePokemonMedia media,
      {int maximumBytes = 64 * 1024 * 1024, void Function()? check}) async {
    if (media.release != release) throw ArgumentError('Media release differs.');
    if (maximumBytes < 1 || maximumBytes > 64 * 1024 * 1024) {
      throw ArgumentError.value(maximumBytes, 'maximumBytes');
    }
    check?.call();
    final response = await _get(_uri('$release/${media.id}'), maximumBytes);
    check?.call();
    if (response.bodyBytes.isEmpty ||
        response.bodyBytes.length > maximumBytes ||
        sha256.convert(response.bodyBytes).toString() != media.sha256) {
      throw const FormatException('Media content or digest is invalid.');
    }
    return Uint8List.fromList(response.bodyBytes);
  }
}
