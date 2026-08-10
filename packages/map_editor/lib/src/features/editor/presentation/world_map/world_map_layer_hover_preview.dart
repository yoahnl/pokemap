import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/editor_notifier.dart';

typedef _WorldMapHoverDocumentScope = ({
  String? projectRootPath,
  String? mapId,
});

final worldMapHoveredTileLayerIdProvider =
    NotifierProvider<WorldMapLayerHoverPreviewController, String?>(
  WorldMapLayerHoverPreviewController.new,
);

final class WorldMapLayerHoverPreviewController extends Notifier<String?> {
  @override
  String? build() {
    ref.listen<_WorldMapHoverDocumentScope>(
      editorNotifierProvider.select(
        (state) => (
          projectRootPath: state.projectRootPath,
          mapId: state.activeMap?.id,
        ),
      ),
      (_, _) => state = null,
    );
    return null;
  }

  void show(String layerId) {
    final normalized = layerId.trim();
    if (normalized.isEmpty || state == normalized) return;
    state = normalized;
  }

  void clear(String layerId) {
    if (state == layerId.trim()) state = null;
  }
}
