import 'dart:io';

import 'package:image/image.dart' as image;
import 'package:map_core/map_core_domain.dart';

Future<Map<String, List<int>>> seedNarrativeArtworkFixture(
  String root,
  List<SceneAsset> scenes,
) async {
  final files = <String, String>{
    'hero.png': 'hero.png',
    'stories/departure.png': 'scenes/campaign-opening.png',
    'stories/garden-traces.png': 'scenes/campaign-shizune.png',
    for (final pair in scenes.take(4).indexed)
      'scenes/${pair.$2.id}.png': [
        'scenes/campaign-box-home.png',
        'scenes/campaign-opening.png',
        'scenes/campaign-shizune.png',
        'scenes/campaign-photo-home.png',
      ][pair.$1],
  };
  final bytes = <String, List<int>>{};
  for (final entry in files.entries) {
    final shade =
        entry.value.codeUnits.fold(0, (sum, unit) => sum + unit) % 200;
    final artwork = image.Image(width: 64, height: 36)
      ..clear(image.ColorRgb8(40 + shade, 80, 160 - shade ~/ 2));
    final content = image.encodePng(artwork);
    final destination = File('$root/assets/studio/narrative/${entry.key}');
    await destination.parent.create(recursive: true);
    await destination.writeAsBytes(content);
    bytes[entry.key] = content;
  }
  return bytes;
}
