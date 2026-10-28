import 'dart:convert';

import 'game_package_security_policy.dart';
import 'package_path_policy.dart';

Map<String, GamePackageSourceAsset> readGamePackageSourceAssetCatalog(
  List<int> bytes,
  GamePackageSecurityPolicy policy,
) {
  if (bytes.length > policy.maxJsonBytes) {
    throw const FormatException('JSON quota exceeded.');
  }
  final json = _object(jsonDecode(utf8.decode(bytes, allowMalformed: false)));
  _keys(json, {'schemaVersion', 'records'});
  if (json['schemaVersion'] != 1 || json['records'] is! List) {
    throw const FormatException('Invalid asset catalogue.');
  }
  final result = <String, GamePackageSourceAsset>{};
  final logicalPaths = <String>{};
  for (final raw in json['records'] as List) {
    final record = _object(raw);
    _keys(record, {'id', 'logicalPath', 'artifact', 'usages', 'tags'});
    final artifact = _object(record['artifact']);
    _keys(artifact, {'digest', 'handle', 'mediaType', 'byteLength'});
    final id = record['id'] as String;
    final path = record['logicalPath'] as String;
    final digest = artifact['digest'] as String;
    final length = artifact['byteLength'] as int;
    final mediaType = artifact['mediaType'] as String;
    PackagePathPolicy.validate('project/$path', errorPath: path);
    if (id.isEmpty ||
        id.trim() != id ||
        !RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(digest) ||
        artifact['handle'] != 'artifact://sha256/${digest.substring(7)}' ||
        !RegExp(r'^[a-z0-9][a-z0-9!#$&^_.+-]*/[a-z0-9][a-z0-9!#$&^_.+-]*$')
            .hasMatch(mediaType) ||
        length < 0 ||
        length > policy.maxFileBytes ||
        result.containsKey(id) ||
        !logicalPaths.add(PackagePathPolicy.collisionKey(path))) {
      throw const FormatException('Invalid canonical asset record.');
    }
    for (final field in ['usages', 'tags']) {
      if (record[field] is! List ||
          (record[field] as List).any((v) => v is! String)) {
        throw const FormatException('Invalid asset record strings.');
      }
    }
    result[id] = GamePackageSourceAsset(path, digest, mediaType, length);
  }
  return result;
}

Map<String, dynamic> _object(Object? value) =>
    Map<String, dynamic>.from(value as Map);
void _keys(Map<String, dynamic> value, Set<String> allowed) {
  if (value.keys.any((key) => !allowed.contains(key)) ||
      allowed.any((key) => !value.containsKey(key))) {
    throw const FormatException('Unexpected canonical catalogue fields.');
  }
}

final class GamePackageSourceAsset {
  const GamePackageSourceAsset(
      this.logicalPath, this.digest, this.mediaType, this.byteLength);
  final String logicalPath, digest, mediaType;
  final int byteLength;
  String get blobPath =>
      'project/assets/.pokemap-store/${digest.substring(7)}.blob';
}
