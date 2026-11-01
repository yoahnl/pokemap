import 'dart:typed_data';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_recipe_sound_source_web.dart';

void main() {
  test('web source keeps the verified bytes and declared media type', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    final prepared = await BattleRecipeSoundSource.create(bytes, 'audio/mpeg');
    final source = prepared.source as BytesSource;
    expect(source.bytes, orderedEquals(bytes));
    expect(source.mimeType, 'audio/mpeg');
    await prepared.dispose();
  });
}
