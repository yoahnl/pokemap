import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/layout/studio_asset_preview.dart';
import '../events/event_map_loader.dart';
import '../map_workspace/map_workspace_visuals.dart';

class CinematicLibraryThumbnail extends StatefulWidget {
  const CinematicLibraryThumbnail({
    super.key,
    required this.mapId,
    required this.loader,
    required this.visuals,
  });
  final String? mapId;
  final EventMapLoader loader;
  final MapWorkspaceVisuals visuals;
  @override
  State<CinematicLibraryThumbnail> createState() =>
      _CinematicLibraryThumbnailState();
}

class _CinematicLibraryThumbnailState extends State<CinematicLibraryThumbnail> {
  Future<MapData>? future;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    future = widget.mapId == null ? null : widget.loader.load(widget.mapId!);
  }

  @override
  void didUpdateWidget(CinematicLibraryThumbnail old) {
    super.didUpdateWidget(old);
    if (old.mapId != widget.mapId || old.loader != widget.loader) load();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 70,
    height: 62,
    child: StudioAssetPreview(
      checkerboard: false,
      child: FutureBuilder<MapData>(
        future: future,
        builder: (context, snapshot) {
          final open = widget.loader.workspace.documents[widget.mapId]?.current;
          final loaded = snapshot.connectionState == ConnectionState.done
              ? snapshot.data
              : null;
          final candidate = open ?? loaded;
          final map = widget.mapId != null && candidate?.id == widget.mapId
              ? candidate
              : null;
          final settings = widget.loader.workspace.project?.settings;
          if (map == null || settings == null) {
            return Tooltip(
              message: snapshot.hasError
                  ? 'Carte indisponible'
                  : widget.mapId == null
                  ? 'Aucune carte choisie'
                  : 'Chargement de l’aperçu',
              child: Icon(
                snapshot.hasError
                    ? Icons.broken_image_outlined
                    : Icons.movie_outlined,
              ),
            );
          }
          return FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width:
                  map.size.width *
                  settings.tileWidth *
                  settings.displayScale.toDouble(),
              height:
                  map.size.height *
                  settings.tileHeight *
                  settings.displayScale.toDouble(),
              child: widget.visuals.canvas(map),
            ),
          );
        },
      ),
    ),
  );
}
