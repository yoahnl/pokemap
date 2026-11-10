import 'package:map_core/map_core_domain.dart';

List<ProjectTilesetEntry> compatibleCharacterStudioTilesets(
  ProjectManifest project,
) => project.tilesets.where((entry) {
  final source = entry.source;
  return source is ProjectRegularAtlasTilesetSource &&
      source.pixelWidth >= project.settings.tileWidth * 2 &&
      source.pixelHeight >= project.settings.tileHeight * 2 &&
      source.marginX == 0 &&
      source.marginY == 0 &&
      source.spacingX == 0 &&
      source.spacingY == 0;
}).toList();
