import 'dart:typed_data';

import 'package:map_core/map_core.dart';

final class RegionalMapSource {
  RegionalMapSource({
    required this.project,
    required this.revision,
    required Map<String, MapData> maps,
    required Map<String, String> images,
  }) : maps = Map.unmodifiable(maps),
       images = Map.unmodifiable(images);
  final ProjectManifest project;
  final String revision;
  final Map<String, MapData> maps;
  final Map<String, String> images;
}

abstract interface class RegionalMapPort {
  Future<RegionalMapSource> load();
  Future<Uint8List?> readImage(String path);
  Future<RegionalMapSource> publish({
    required RegionalMapSource base,
    required String actionId,
    required Map<String, Object?> parameters,
  });
}
