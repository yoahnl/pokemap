import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

const gen5BattleSourceAssetNames = <String>[
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

Map<String, Uint8List> verifyGen5SourceAssets(Map<String, Object?> document) {
  final species = document['species'];
  final dex = document['nationalDex'];
  if (document['format'] != 'gen5-battle-source-v1' ||
      document['game'] != 'black2-white2' ||
      document['scope'] != 'default-form' ||
      species is! String ||
      !RegExp(r'^[a-z0-9][a-z0-9-]{0,99}$').hasMatch(species) ||
      dex is! int ||
      dex < 1 ||
      dex > 649) {
    throw const FormatException('Invalid Gen 5 source identity');
  }
  final assets = document['assets'];
  if (assets is! Map || assets.length != gen5BattleSourceAssetNames.length) {
    throw const FormatException('Invalid Gen 5 source asset set');
  }
  final verified = <String, Uint8List>{};
  for (final name in gen5BattleSourceAssetNames) {
    final entry = assets[name];
    if (entry is! Map) throw FormatException('Missing source asset: $name');
    final size = entry['size'];
    final digest = entry['sha256'];
    final data = entry['data'];
    if (entry['encoding'] != 'base64' ||
        size is! int ||
        size < 1 ||
        size > 1048576 ||
        digest is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(digest) ||
        data is! String ||
        data.length != ((size + 2) ~/ 3) * 4) {
      throw FormatException('Invalid source asset metadata: $name');
    }
    Uint8List bytes;
    try {
      bytes = base64.decode(data);
    } on FormatException {
      throw FormatException('Invalid source asset base64: $name');
    }
    if (bytes.length != size ||
        base64.encode(bytes) != data ||
        sha256.convert(bytes).toString() != digest) {
      throw FormatException('Corrupt source asset: $name');
    }
    verified[name] = bytes;
  }
  return Map.unmodifiable(verified);
}
