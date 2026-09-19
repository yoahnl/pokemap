import 'package:map_core/map_core_domain.dart';

bool canCreateDecor(ProjectTilesetEntry tileset, ProjectManifest manifest) =>
    decorConversionProblem(tileset, manifest) == null;

String? decorConversionProblem(
  ProjectTilesetEntry tileset,
  ProjectManifest manifest,
) {
  final source = tileset.source;
  if (source is! ProjectRegularAtlasTilesetSource) {
    return 'La création de décor nécessite une planche à grille régulière. Cette ressource reste utilisable en tuiles.';
  }
  if (source.tileWidth <= 0 ||
      source.tileHeight <= 0 ||
      source.columns <= 0 ||
      source.rows <= 0) {
    return 'La planche ne contient aucune cellule complète utilisable.';
  }
  if (source.marginX != 0 ||
      source.marginY != 0 ||
      source.spacingX != 0 ||
      source.spacingY != 0) {
    return 'Les marges et espacements de cette planche sont pris en charge en tuiles, mais pas pour créer un décor.';
  }
  if (source.pixelOffsetX != 0 || source.pixelOffsetY != 0) {
    return 'Le décalage visuel de cette planche est pris en charge en tuiles, mais pas pour créer un décor.';
  }
  if (source.tileWidth != manifest.settings.tileWidth ||
      source.tileHeight != manifest.settings.tileHeight) {
    return 'La grille de cette planche diffère de celle du projet (${manifest.settings.tileWidth} × ${manifest.settings.tileHeight}). Utilisez cette ressource en tuiles.';
  }
  return null;
}
