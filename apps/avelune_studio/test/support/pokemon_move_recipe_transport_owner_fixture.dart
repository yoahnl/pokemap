import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';

final class CountingRecipeReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final paths = <String>[];
  final delegate = const LocalProjectFileReader();

  @override
  bool get supportsStreamingResources => true;

  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    paths.add(relativePath);
    return delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  Stream<List<int>> openRead({
    required String projectRoot,
    required String relativePath,
  }) {
    paths.add(relativePath);
    return delegate.openRead(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) => delegate.probeResource(
    projectRoot: projectRoot,
    relativePath: relativePath,
  );
}

final class RecipeOwnerTransport
    implements PokemonBoundedExternalHttpTransport {
  RecipeOwnerTransport(this.particle, this.texture, {this.sound}) {
    recipe = utf8.encode(
      jsonEncode({
        'schemaVersion': 1,
        'recipeId': 'flame',
        'revision': '1',
        'moveSourceId': 'flamethrower',
        'variant': 'default',
        'requiredCapabilities': [
          'startParticle',
          'splParticleV2',
          if (sound != null) 'sequence',
          if (sound != null) 'sound',
        ],
        'provenance': {
          'source': 'synthetic',
          'sourceRevision': '1',
          'sourcePaths': <String>[],
          'converter': 'test',
        },
        'resources': [
          _resource('tex', texture, 'texture', 'image/png'),
          {
            ..._resource(
              'particle',
              particle,
              'particleDefinition',
              'application/vnd.avelune.particle+json',
            ),
            'definitionVersion': 2,
            'dependencies': ['tex'],
          },
          if (sound != null) _resource('sound', sound!, 'sound', 'audio/wav'),
        ],
        'program': sound == null
            ? {
                'kind': 'startParticle',
                'resourceId': 'particle',
                'from': 'userMouth',
                'to': 'targetImpact',
              }
            : {
                'kind': 'sequence',
                'steps': [
                  {'kind': 'sound', 'resourceId': 'sound'},
                  {
                    'kind': 'startParticle',
                    'resourceId': 'particle',
                    'from': 'userMouth',
                    'to': 'targetImpact',
                  },
                ],
              },
      }),
    );
  }

  final List<int> particle;
  final List<int> texture;
  final List<int>? sound;
  late List<int> recipe;
  String style = 'gen5';
  bool corruptTexture = false;
  Completer<void>? textureStarted;
  Completer<void>? textureGate;

  static Map<String, Object> _resource(
    String id,
    List<int> bytes,
    String role,
    String type,
  ) => {
    'id': id,
    'role': role,
    'mediaType': type,
    'sizeBytes': bytes.length,
    'sha256': sha256.convert(bytes).toString(),
  };

  @override
  Future<PokemonExternalHttpResponse> getBounded(
    Uri uri, {
    required Map<String, String> headers,
    required int maximumBytes,
    required Duration timeout,
  }) async {
    if (uri.path.endsWith('/texture') && textureGate != null) {
      textureStarted?.complete();
      await textureGate!.future;
    }
    Map<String, Object> item(
      String id,
      List<int> bytes,
      String type,
      String representation,
      Map<String, Object> metadata,
    ) => {
      'id': id,
      'sha256': sha256.convert(bytes).toString(),
      'contentType': type,
      'usage': 'battle',
      'representation': representation,
      'style': style,
      'metadata': metadata,
    };
    final listing = uri.path.endsWith('/owners/move/flamethrower');
    final bytes = listing
        ? utf8.encode(
            jsonEncode([
              item(
                'flame',
                recipe,
                'application/vnd.avelune.battle-recipe+json',
                'recipe',
                {
                  'recipeId': 'flame',
                  'revision': '1',
                  'moveSourceId': 'flamethrower',
                  'variant': 'default',
                  'bindings': {
                    'tex': 'texture',
                    'particle': 'particle',
                    if (sound != null) 'sound': 'sound',
                  },
                },
              ),
              item(
                'particle',
                particle,
                'application/vnd.avelune.particle+json',
                'particle',
                {},
              ),
              if (sound != null)
                item('sound', sound!, 'audio/wav', 'audio', {}),
              item('texture', texture, 'image/png', 'sprite2d', {}),
            ]),
          )
        : uri.path.endsWith('/flame')
        ? recipe
        : uri.path.endsWith('/particle')
        ? particle
        : uri.path.endsWith('/sound')
        ? sound!
        : corruptTexture
        ? List<int>.filled(texture.length, 0)
        : texture;
    return PokemonExternalHttpResponse(
      statusCode: 200,
      headers: const {},
      body: listing ? utf8.decode(bytes) : '',
      bodyBytes: Uint8List.fromList(bytes),
    );
  }
}

final class BundleRecipeOwnerTransport
    implements PokemonBoundedExternalHttpTransport {
  BundleRecipeOwnerTransport(
    this.move,
    this.recipe,
    Map<String, List<int>> resources,
  ) {
    final definition = jsonDecode(utf8.decode(recipe)) as Map<String, dynamic>;
    final declared = (definition['resources'] as List)
        .cast<Map<String, dynamic>>();
    final bindings = <String, String>{};
    for (var i = 0; i < declared.length; i++) {
      final resource = declared[i];
      final id = 'resource-$i';
      final data = resources[resource['id']]!;
      bindings[resource['id'] as String] = id;
      files[id] = data;
      listing.add({
        'id': id,
        'sha256': sha256.convert(data).toString(),
        'contentType': resource['mediaType'],
        'usage': 'battle',
        'representation': switch (resource['role']) {
          'texture' => 'sprite2d',
          'particleDefinition' => 'particle',
          'sound' => 'audio',
          _ => throw StateError('Unexpected media'),
        },
        'style': 'gen5-bw2',
        'metadata': <String, Object>{},
      });
    }
    files['recipe'] = recipe;
    listing.add({
      'id': 'recipe',
      'sha256': sha256.convert(recipe).toString(),
      'contentType': 'application/vnd.avelune.battle-recipe+json',
      'usage': 'battle',
      'representation': 'recipe',
      'style': 'gen5-bw2',
      'metadata': {
        'recipeId': definition['recipeId'],
        'revision': definition['revision'],
        'moveSourceId': definition['moveSourceId'],
        'variant': definition['variant'],
        'bindings': bindings,
      },
    });
  }

  final String move;
  final List<int> recipe;
  final files = <String, List<int>>{};
  final listing = <Map<String, Object?>>[];

  @override
  Future<PokemonExternalHttpResponse> getBounded(
    Uri uri, {
    required Map<String, String> headers,
    required int maximumBytes,
    required Duration timeout,
  }) async {
    final isListing = uri.path.endsWith('/owners/move/$move');
    final bytes = isListing
        ? utf8.encode(jsonEncode(listing))
        : files[uri.pathSegments.last]!;
    if (bytes.length > maximumBytes) {
      throw const FormatException('Media exceeds limit');
    }
    return PokemonExternalHttpResponse(
      statusCode: 200,
      headers: const {},
      body: isListing ? utf8.decode(bytes) : '',
      bodyBytes: Uint8List.fromList(bytes),
    );
  }
}

Uint8List largeRecipeWav() {
  const samples = 300000;
  final bytes = Uint8List(44 + samples);
  final data = ByteData.sublistView(bytes);
  bytes.setRange(0, 4, ascii.encode('RIFF'));
  data.setUint32(4, bytes.length - 8, Endian.little);
  bytes.setRange(8, 16, ascii.encode('WAVEfmt '));
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, 8000, Endian.little);
  data.setUint32(28, 8000, Endian.little);
  data.setUint16(32, 1, Endian.little);
  data.setUint16(34, 8, Endian.little);
  bytes.setRange(36, 40, ascii.encode('data'));
  data.setUint32(40, samples, Endian.little);
  return bytes;
}
