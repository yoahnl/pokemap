import 'dart:typed_data';

import 'package:flame_audio/flame_audio.dart';

final class BattleRecipeSoundSource {
  BattleRecipeSoundSource._(this.source);

  final Source source;

  static Future<BattleRecipeSoundSource> create(
    Uint8List bytes,
    String mediaType,
  ) async => BattleRecipeSoundSource._(BytesSource(bytes, mimeType: mediaType));

  Future<void> dispose() async {}
}
