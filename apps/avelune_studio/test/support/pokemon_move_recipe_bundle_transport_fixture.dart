import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';

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
