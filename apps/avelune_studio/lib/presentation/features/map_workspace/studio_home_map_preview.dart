import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/map_workspace/application/map_workspace_controller.dart';
import 'map_workspace_visuals.dart';

class StudioHomeMapPreview extends StatefulWidget {
  const StudioHomeMapPreview({
    super.key,
    required this.controller,
    required this.visuals,
    required this.mapId,
  });

  final MapWorkspaceController controller;
  final MapWorkspaceVisuals visuals;
  final String mapId;

  @override
  State<StudioHomeMapPreview> createState() => _StudioHomeMapPreviewState();
}

class _StudioHomeMapPreviewState extends State<StudioHomeMapPreview> {
  late Future<MapData?> _savedMap = widget.controller.previewMap(widget.mapId);

  @override
  void didUpdateWidget(StudioHomeMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.mapId != widget.mapId) {
      _savedMap = widget.controller.previewMap(widget.mapId);
    }
  }

  Widget _empty(String message) =>
      Center(child: Text(message, style: const TextStyle(fontSize: 11)));

  Widget _canvas(MapData map) {
    final settings = widget.controller.project?.settings;
    if (settings == null) return _empty('Aperçu indisponible');
    final width = map.size.width * settings.tileWidth * settings.displayScale;
    final height =
        map.size.height * settings.tileHeight * settings.displayScale;
    if (width <= 0 || height <= 0) return _empty('Aperçu indisponible');
    final canvas = widget.visuals is MapWorkspacePreviewVisuals
        ? (widget.visuals as MapWorkspacePreviewVisuals).previewCanvas(map)
        : widget.visuals.canvas(map);
    return Semantics(
      label: 'Aperçu de ${map.name}',
      child: ClipRect(
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: width,
              height: height,
              child: RepaintBoundary(child: canvas),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.controller.documents[widget.mapId]?.current;
    if (current != null) return _canvas(current);
    return FutureBuilder<MapData?>(
      future: _savedMap,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: Text('Chargement de l’aperçu…'));
        }
        final map = snapshot.data;
        return map == null ? _empty('Aperçu indisponible') : _canvas(map);
      },
    );
  }
}
