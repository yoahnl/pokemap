import 'package:map_core/map_core.dart';

final class TiledTsxCatalogAppendResult {
  const TiledTsxCatalogAppendResult({
    required this.catalog,
    required this.errors,
    this.warnings = const <String>[],
  });

  final ProjectSurfaceCatalog? catalog;
  final List<String> errors;
  final List<String> warnings;

  bool get hasErrors => errors.isNotEmpty;
}

TiledTsxCatalogAppendResult appendTiledTsxSurfaceImportToCatalog({
  required ProjectSurfaceCatalog catalog,
  required ProjectSurfaceAtlas atlas,
  required List<ProjectSurfaceAnimation> animations,
}) {
  final errors = <String>[];
  if (catalog.containsAtlas(atlas.id)) {
    errors.add('Atlas TSX déjà présent dans le catalogue : ${atlas.id}.');
  }
  for (final animation in animations) {
    if (catalog.containsAnimation(animation.id)) {
      errors.add(
        'Animation TSX déjà présente dans le catalogue : ${animation.id}.',
      );
    }
  }
  final incomingAnimationIds = <String>{};
  for (final animation in animations) {
    if (!incomingAnimationIds.add(animation.id)) {
      errors.add(
        'Animation TSX dupliquée dans l’import : ${animation.id}.',
      );
    }
  }
  if (errors.isNotEmpty) {
    return TiledTsxCatalogAppendResult(
      catalog: null,
      errors: List<String>.unmodifiable(errors),
    );
  }

  return TiledTsxCatalogAppendResult(
    catalog: ProjectSurfaceCatalog(
      atlases: [...catalog.atlases, atlas],
      animations: [...catalog.animations, ...animations],
      presets: catalog.presets,
    ),
    errors: const <String>[],
  );
}
