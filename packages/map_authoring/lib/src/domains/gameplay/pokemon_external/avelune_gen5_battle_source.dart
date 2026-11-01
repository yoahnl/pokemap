import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../../documents/document_errors.dart';
import 'avelune_catalog_release.dart';
import 'pokemon_external_http_transport.dart';

final class AveluneGen5BattleSourceSnapshot {
  const AveluneGen5BattleSourceSnapshot._({
    required this.species,
    required this.nationalDex,
    required this.release,
    required this.sourceRepository,
    required this.sourceRevision,
    required this.sourceDirectory,
    required this.reconstruction,
    required this.redistributionStatus,
    required this.assets,
  });

  final String species;
  final int nationalDex;
  final String release;
  final String sourceRepository;
  final String sourceRevision;
  final String sourceDirectory;
  final String reconstruction;
  final String redistributionStatus;
  final Map<String, Uint8List> assets;
}

final class AveluneGen5BattleSource {
  AveluneGen5BattleSource({
    required PokemonBoundedExternalHttpTransport client,
    this.baseUri = const String.fromEnvironment(
      'AVELUNE_SNAPSHOT_BASE_URI',
      defaultValue: 'https://pokemon-api.yoahn.me/v1/snapshots',
    ),
    this.release = aveluneCatalogRelease,
    this.requestTimeout = const Duration(seconds: 20),
    this.maximumBytes = 20 * 1024 * 1024,
  }) : _client = client {
    final uri = Uri.parse(baseUri);
    if (uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw ArgumentError.value(baseUri, 'baseUri');
    }
    if (!_releaseIdentifier.hasMatch(release)) {
      throw ArgumentError.value(release, 'release');
    }
    if (requestTimeout <= Duration.zero ||
        maximumBytes < 1 ||
        maximumBytes > 20 * 1024 * 1024) {
      throw ArgumentError('Invalid source request limits');
    }
  }

  final PokemonBoundedExternalHttpTransport _client;
  final String baseUri;
  final String release;
  final Duration requestTimeout;
  final int maximumBytes;

  static final _identifier = RegExp(r'^[a-z0-9][a-z0-9-]{0,99}$');
  static final _releaseIdentifier = RegExp(r'^[a-z0-9][a-z0-9-]{0,127}$');
  static final _revision = RegExp(r'^[a-f0-9]{40}$');
  static final _sha256 = RegExp(r'^[a-f0-9]{64}$');
  static const _assetNames = [
    'front.png',
    'back.png',
    'front_animations.nanr.lz11',
    'back_animations.nanr.lz11',
    'front_cells.ncer',
    'back_cells.ncer',
    'front_multi_cells.nmcr',
    'back_multi_cells.nmcr',
    'front_multi_animations.nmar',
    'back_multi_animations.nmar',
    'front_info.bin',
    'back_info.bin',
    'normal.pal',
    'shiny.pal',
  ];

  Future<AveluneGen5BattleSourceSnapshot?> fetch({
    required String species,
    required int nationalDex,
  }) async {
    if (!_identifier.hasMatch(species)) {
      throw ArgumentError.value(species, 'species');
    }
    if (nationalDex < 1 || nationalDex > 649) {
      throw ArgumentError.value(nationalDex, 'nationalDex');
    }
    final base = Uri.parse(baseUri.endsWith('/') ? baseUri : '$baseUri/');
    final response = await _client.getBounded(
      base.resolve('$release/gen5-battle/$nationalDex'),
      headers: const {'accept': 'application/json'},
      maximumBytes: maximumBytes,
      timeout: requestTimeout,
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EditorPersistenceException(
        'Gen 5 source request failed with HTTP ${response.statusCode}',
      );
    }
    if (response.bodyBytes.length > maximumBytes) {
      throw const FormatException('Gen 5 source response exceeds limit');
    }
    final revisions = response.headers.entries
        .where((entry) => entry.key.toLowerCase() == 'x-source-revision')
        .map((entry) => entry.value)
        .toList();
    if (revisions.length != 1 || !_revision.hasMatch(revisions.single)) {
      throw const FormatException('Invalid Gen 5 source revision header');
    }
    final document = jsonDecode(utf8.decode(response.bodyBytes));
    if (document is! Map<String, dynamic> ||
        document['format'] != 'gen5-battle-source-v1' ||
        document['game'] != 'black2-white2' ||
        document['scope'] != 'default-form' ||
        document['species'] != species ||
        document['nationalDex'] is! int ||
        document['nationalDex'] != nationalDex) {
      throw const FormatException('Invalid Gen 5 source identity');
    }
    final source = document['source'];
    final reconstruction = document['reconstruction'];
    if (source is! Map ||
        source['repository'] != 'fuddlesworth/pokebw2' ||
        source['revision'] != revisions.single ||
        source['directory'] != 'res/pokemon/${species.replaceAll('-', '_')}' ||
        source['redistributionStatus'] is! String ||
        (source['redistributionStatus'] as String).isEmpty ||
        (source['redistributionStatus'] as String).length > 100 ||
        reconstruction is! String ||
        reconstruction.isEmpty ||
        reconstruction.length > 100) {
      throw const FormatException('Invalid Gen 5 source provenance');
    }
    final rawAssets = document['assets'];
    if (rawAssets is! Map || rawAssets.length != _assetNames.length) {
      throw const FormatException('Invalid Gen 5 source assets');
    }
    final assets = <String, Uint8List>{};
    for (final name in _assetNames) {
      final item = rawAssets[name];
      if (item is! Map) throw FormatException('Missing Gen 5 asset: $name');
      final size = item['size'];
      final digest = item['sha256'];
      final encoded = item['data'];
      if (item['encoding'] != 'base64' ||
          size is! int ||
          size < 1 ||
          size > 1024 * 1024 ||
          digest is! String ||
          !_sha256.hasMatch(digest) ||
          encoded is! String ||
          encoded.length != ((size + 2) ~/ 3) * 4) {
        throw FormatException('Invalid Gen 5 asset metadata: $name');
      }
      final bytes = base64.decode(encoded);
      if (bytes.length != size ||
          base64.encode(bytes) != encoded ||
          sha256.convert(bytes).toString() != digest) {
        throw FormatException('Invalid Gen 5 asset content: $name');
      }
      assets[name] = bytes.asUnmodifiableView();
    }
    return AveluneGen5BattleSourceSnapshot._(
      species: species,
      nationalDex: nationalDex,
      release: release,
      sourceRepository: source['repository'] as String,
      sourceRevision: revisions.single,
      sourceDirectory: source['directory'] as String,
      reconstruction: reconstruction,
      redistributionStatus: source['redistributionStatus'] as String,
      assets: Map.unmodifiable(assets),
    );
  }
}
