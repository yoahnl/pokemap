import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../features/resources/application/resource_preview_source.dart';
import 'studio_atlas_preview.dart';
import 'studio_character_thumbnail.dart';
import 'studio_library_image_cache.dart';
import 'studio_resource_thumbnail.dart';
import 'studio_thumbnail_resources.dart';

class StudioLibraryImagePreview extends StatefulWidget {
  const StudioLibraryImagePreview({
    super.key,
    required this.cache,
    required this.source,
    required this.project,
    required this.size,
  });

  final StudioLibraryImageCache cache;
  final ResourcePreviewSource source;
  final ProjectManifest project;
  final double size;

  @override
  State<StudioLibraryImagePreview> createState() =>
      _StudioLibraryImagePreviewState();
}

class _StudioLibraryImagePreviewState extends State<StudioLibraryImagePreview> {
  late Future<StudioThumbnailResources?> _scope = _load();

  Future<StudioThumbnailResources?> _load() =>
      widget.cache.scope(widget.source, widget.project);

  @override
  void didUpdateWidget(StudioLibraryImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.cache, widget.cache) ||
        !identical(oldWidget.project, widget.project) ||
        _identity(oldWidget.source) != _identity(widget.source)) {
      _scope = _load();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _scope,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: Icon(Icons.hourglass_empty, size: 18));
      }
      final resources = snapshot.data;
      if (resources == null) return _unavailable;
      final size = widget.size;
      return switch (widget.source) {
        CharacterPreviewSource(:final character) => StudioCharacterThumbnail(
          resources: resources,
          character: character,
          size: size,
          facing: EntityFacing.south,
        ),
        AtlasPreviewSource(:final tilesetId) => StudioAtlasPreview(
          resources: resources,
          tilesetId: studioLibraryAtlasImageId(widget.project, tilesetId),
        ),
        ElementPreviewSource(:final element) => StudioResourceThumbnail(
          resources: resources,
          element: element,
          size: size,
        ),
        TileFramePreviewSource(:final entry) => StudioResourceThumbnail(
          resources: resources,
          tile: entry,
          size: size,
          showTransparentIndicator: true,
        ),
        _ => _unavailable,
      };
    },
  );

  Widget get _unavailable => const Center(
    child: Tooltip(
      message: 'Aperçu indisponible',
      child: Icon(Icons.image_not_supported_outlined, size: 18),
    ),
  );
}

Object? _identity(ResourcePreviewSource source) => switch (source) {
  CharacterPreviewSource(:final character) => character,
  AtlasPreviewSource(:final tilesetId) => tilesetId,
  ElementPreviewSource(:final element) => element,
  TileFramePreviewSource(:final entry) => entry,
  _ => null,
};
