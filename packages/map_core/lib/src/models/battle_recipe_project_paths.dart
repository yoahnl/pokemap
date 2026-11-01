import 'dart:convert';

import 'package:crypto/crypto.dart';

String battleRecipeBindingPath(String projectMoveId) {
  final digest = _moveDigest(projectMoveId);
  return 'data/pokemon/battle_recipes/bindings/$digest.json';
}

String _moveDigest(String projectMoveId) {
  if (projectMoveId.isEmpty ||
      projectMoveId.length > 512 ||
      projectMoveId.trim() != projectMoveId ||
      utf8.decode(utf8.encode(projectMoveId)) != projectMoveId) {
    throw const FormatException('Invalid project move identity');
  }
  return sha256.convert(utf8.encode(projectMoveId)).toString();
}

String battleRecipeBlobPath(
  String digest,
  String mediaType, {
  required String projectMoveId,
}) {
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(digest)) {
    throw const FormatException('Invalid battle recipe digest');
  }
  final extension = switch (mediaType) {
    'image/png' => 'png',
    'application/vnd.avelune.particle+json' ||
    'application/vnd.avelune.battle-recipe+json' => 'json',
    _ => throw const FormatException('Unsupported battle recipe media type'),
  };
  return 'data/pokemon/battle_recipes/blobs/${_moveDigest(projectMoveId)}/$digest.$extension';
}
