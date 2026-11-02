import 'dart:convert';
import 'dart:typed_data';

import 'package:map_distribution/map_distribution.dart';

import 'avelune_catalog_release.dart';
import 'avelune_pokemon_media_source.dart';
import 'pokemon_external_http_transport.dart';

enum PokemonBattleGifRole {
  frontAnimated,
  backAnimated,
  frontShinyAnimated,
  backShinyAnimated,
}

final class PokemonBattleGif {
  PokemonBattleGif._(AvelunePokemonMedia media, Uint8List bytes)
      : id = media.id,
        sha256 = media.sha256,
        release = media.release,
        bytes = Uint8List.fromList(bytes).asUnmodifiableView();

  final String id;
  final String sha256;
  final String release;
  final Uint8List bytes;
}

final class PokemonBattleGifSelection {
  PokemonBattleGifSelection._({
    required this.speciesId,
    required this.defaultFormId,
    required Map<PokemonBattleGifRole, PokemonBattleGif> media,
    required Set<PokemonBattleGifRole> requested,
  })  : media = Map.unmodifiable(media),
        missing = Set.unmodifiable(requested.difference(media.keys.toSet()));

  final String speciesId;
  final String defaultFormId;
  final Map<PokemonBattleGifRole, PokemonBattleGif> media;
  final Set<PokemonBattleGifRole> missing;
}

final class AveluneBattleGifSource {
  AveluneBattleGifSource({
    required PokemonBoundedExternalHttpTransport client,
    this.release = aveluneCatalogRelease,
    this.mediaBaseUri = const String.fromEnvironment(
      'AVELUNE_MEDIA_BASE_URI',
      defaultValue: 'https://pokemon-api.yoahn.me/v1/media',
    ),
    String? compatBaseUri,
    this.requestTimeout = const Duration(seconds: 20),
  })  : compatBaseUri = compatBaseUri ?? _compatBase(mediaBaseUri, release),
        _client = client,
        _media = AvelunePokemonMediaSource(
          client: client,
          baseUri: mediaBaseUri,
          release: release,
          requestTimeout: requestTimeout,
        ) {
    final compat = Uri.parse(this.compatBaseUri);
    final media = Uri.parse(mediaBaseUri);
    final segments =
        compat.pathSegments.where((part) => part.isNotEmpty).toList();
    if (compat.scheme != 'https' ||
        compat.host.isEmpty ||
        compat.userInfo.isNotEmpty ||
        compat.hasQuery ||
        compat.hasFragment ||
        compat.origin != media.origin ||
        segments.length < 3 ||
        segments[segments.length - 3] != 'compat' ||
        segments[segments.length - 2] != release ||
        segments.last != 'pokeapi') {
      throw ArgumentError.value(this.compatBaseUri, 'compatBaseUri');
    }
  }

  final PokemonBoundedExternalHttpTransport _client;
  final AvelunePokemonMediaSource _media;
  final String release;
  final String mediaBaseUri;
  final String compatBaseUri;
  final Duration requestTimeout;
  static final _identity = RegExp(r'^[a-z0-9][a-z0-9-]{0,127}$');
  static const _speciesLimit = 1024 * 1024;
  static const _totalLimit = 64 * 1024 * 1024;

  static String _compatBase(String mediaBaseUri, String release) {
    const configured = String.fromEnvironment('POKEAPI_BASE_URI');
    if (configured.isNotEmpty) return configured;
    return '${Uri.parse(mediaBaseUri).origin}/v1/compat/$release/pokeapi';
  }

  Future<PokemonBattleGifSelection> fetch({
    required String speciesId,
    required int nationalDex,
    Set<PokemonBattleGifRole> roles = const {
      PokemonBattleGifRole.frontAnimated,
      PokemonBattleGifRole.backAnimated,
      PokemonBattleGifRole.frontShinyAnimated,
      PokemonBattleGifRole.backShinyAnimated,
    },
  }) async {
    if (!_identity.hasMatch(speciesId) ||
        nationalDex < 1 ||
        nationalDex > 649) {
      throw ArgumentError('Invalid base species identity.');
    }
    final requested = Set<PokemonBattleGifRole>.of(roles);
    final base = Uri.parse(
        compatBaseUri.endsWith('/') ? compatBaseUri : '$compatBaseUri/');
    final response = await _client.getBounded(
      base.resolve('pokemon-species/$nationalDex'),
      headers: const {'accept': 'application/json'},
      maximumBytes: _speciesLimit,
      timeout: requestTimeout,
    );
    if (response.statusCode != 200 ||
        response.bodyBytes.isEmpty ||
        response.bodyBytes.length > _speciesLimit) {
      throw const FormatException(
          'Species source is unavailable or too large.');
    }
    final raw = jsonDecode(utf8.decode(response.bodyBytes));
    if (raw is! Map ||
        raw['id'] != nationalDex ||
        raw['name'] is! String ||
        !_identity.hasMatch(raw['name'] as String) ||
        (raw['name'] as String).replaceAll('-', '') !=
            speciesId.replaceAll('-', '') ||
        raw['varieties'] is! List ||
        (raw['varieties'] as List)
            .any((entry) => entry is! Map || entry['is_default'] is! bool)) {
      throw const FormatException('Species identity or varieties are invalid.');
    }
    final defaults = (raw['varieties'] as List)
        .where((entry) => entry is Map && entry['is_default'] == true)
        .toList();
    if (defaults.length != 1 ||
        (defaults.single as Map)['pokemon'] is! Map ||
        ((defaults.single as Map)['pokemon'] as Map)['name'] is! String) {
      throw const FormatException('The default form is missing or ambiguous.');
    }
    final form = ((defaults.single as Map)['pokemon'] as Map)['name'] as String;
    if (!_identity.hasMatch(form)) {
      throw const FormatException('The default form identity is invalid.');
    }
    final canonicalSpecies = raw['name'] as String;
    final candidates = <PokemonBattleGifRole, AvelunePokemonMedia>{};
    for (final item in await _media.listPokemonMedia(canonicalSpecies)) {
      if (item.contentType != 'image/gif' ||
          item.usage != 'battle' ||
          item.representation != 'sprite2d' ||
          item.style != 'gen5' ||
          item.metadata['formId'] != form ||
          item.metadata['gender'] != null) {
        continue;
      }
      final view = item.metadata['view'];
      final shiny = item.metadata['shiny'];
      if (shiny != null && shiny is! bool) {
        throw const FormatException('GIF shiny metadata is invalid.');
      }
      final role = switch ((view, shiny == true)) {
        ('front', false) => PokemonBattleGifRole.frontAnimated,
        ('back', false) => PokemonBattleGifRole.backAnimated,
        ('front', true) => PokemonBattleGifRole.frontShinyAnimated,
        ('back', true) => PokemonBattleGifRole.backShinyAnimated,
        _ => null,
      };
      if (role == null || !requested.contains(role)) {
        continue;
      }
      if (candidates.containsKey(role)) {
        throw const FormatException('GIF media role is ambiguous.');
      }
      candidates[role] = item;
    }
    final selected = <PokemonBattleGifRole, PokemonBattleGif>{};
    var total = 0;
    for (final role in PokemonBattleGifRole.values) {
      final item = candidates[role];
      if (item == null) {
        continue;
      }
      final bytes = await _media.readMedia(item,
          maximumBytes: PokemonGifInspector.maxEncodedBytes);
      total += bytes.length;
      if (total > _totalLimit) {
        throw const FormatException('GIF selection is too large.');
      }
      final info =
          const PokemonGifInspector(maxFrames: 500, maxCanvasPixels: 16777216)
              .inspect(bytes);
      if ((item.metadata['width'] != null &&
              item.metadata['width'] != info.width) ||
          (item.metadata['height'] != null &&
              item.metadata['height'] != info.height) ||
          (item.metadata['frameCount'] != null &&
              item.metadata['frameCount'] != info.frameCount)) {
        throw const FormatException('GIF metadata differs from the content.');
      }
      selected[role] = PokemonBattleGif._(item, bytes);
    }
    return PokemonBattleGifSelection._(
      speciesId: canonicalSpecies,
      defaultFormId: form,
      media: selected,
      requested: requested,
    );
  }
}
