import 'dart:io';
import 'dart:typed_data';

import 'package:flame_audio/flame_audio.dart';

final class BattleRecipeSoundSource {
  BattleRecipeSoundSource._(this.source, this._directory);

  final Source source;
  final Directory _directory;

  static Future<BattleRecipeSoundSource> create(
    Uint8List bytes,
    String mediaType,
  ) async {
    final extension = switch (mediaType) {
      'audio/wav' => 'wav',
      'audio/ogg' => 'ogg',
      'audio/mpeg' => 'mp3',
      _ => throw const FormatException('Unsupported recipe sound format'),
    };
    final directory = await Directory.systemTemp.createTemp(
      'avelune-battle-sound-',
    );
    try {
      final file = File('${directory.path}/sound.$extension');
      await file.writeAsBytes(bytes, flush: true);
      return BattleRecipeSoundSource._(
        DeviceFileSource(file.path, mimeType: mediaType),
        directory,
      );
    } catch (_) {
      await directory.delete(recursive: true);
      rethrow;
    }
  }

  Future<void> dispose() async {
    await _directory.delete(recursive: true);
  }
}
