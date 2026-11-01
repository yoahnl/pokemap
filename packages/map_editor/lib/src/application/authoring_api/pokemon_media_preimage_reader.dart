import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../models/pokemon_media_preimage.dart';

final class PokemonMediaPreimageReader {
  const PokemonMediaPreimageReader();

  Future<PokemonMediaPreimage> read({
    required String projectRoot,
    required String mediaDirectory,
    required String mediaId,
  }) async {
    final relativePath = _mediaPath(mediaDirectory, mediaId);
    final gateway = await LocalTransactionFileGateway.open(
      projectRoot: projectRoot,
    );
    final bytes = await gateway.readResource(relativePath);
    if (bytes == null) {
      return PokemonMediaPreimage(
        relativePath: relativePath,
        bytes: null,
        media: null,
      );
    }
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Pokemon media must be a JSON object.');
    }
    final media = PokemonMediaFile.fromJson(decoded);
    if (media.speciesId != mediaId) {
      throw const FormatException(
        'Pokemon media identity does not match its file.',
      );
    }
    return PokemonMediaPreimage(
      relativePath: relativePath,
      bytes: bytes,
      media: media,
    );
  }

  String _mediaPath(String directory, String id) {
    if (id.isEmpty ||
        id != id.trim() ||
        id == '.' ||
        id == '..' ||
        id.contains('/') ||
        id.contains(r'\') ||
        id.contains('\u0000')) {
      throw const FormatException('Pokemon media identity is invalid.');
    }
    if (directory != directory.trim() || directory.contains(r'\')) {
      throw const FormatException('Pokemon media directory is invalid.');
    }
    final root = directory.isEmpty || directory == '.';
    if (root && id.toLowerCase() == 'project') {
      throw const FormatException(
        'Pokemon media cannot replace the project document.',
      );
    }
    if (!root) {
      try {
        final segments = validateProjectRelativePath(directory);
        final first = segments.first.toLowerCase();
        if (segments.join('/') != directory ||
            first == 'catalog' ||
            first == '.pokemap') {
          throw const FormatException('Pokemon media directory is invalid.');
        }
      } on WorkspaceAccessException {
        throw const FormatException('Pokemon media directory is invalid.');
      }
    }
    return root ? '$id.json' : '$directory/$id.json';
  }
}
