import 'package:map_core/map_core.dart';

/// Immutable intent captured when Smart Tiles Studio is opened.
///
/// A map target is never recomputed from the editor's later active map. This
/// prevents a long-running authoring session from publishing into a different
/// document merely because the user changed tabs.
sealed class SmartTilesStudioLaunchContext {
  const SmartTilesStudioLaunchContext();

  const factory SmartTilesStudioLaunchContext.library() =
      SmartTilesStudioLibraryContext;

  const factory SmartTilesStudioLaunchContext.map({required String mapId}) =
      SmartTilesStudioMapContext;

  String? get capturedMapId => switch (this) {
        SmartTilesStudioLibraryContext() => null,
        SmartTilesStudioMapContext(:final mapId) => mapId,
      };

  bool isCapturedMapAvailable(MapData? activeMap) {
    final mapId = capturedMapId;
    return mapId != null && activeMap?.id == mapId;
  }
}

final class SmartTilesStudioLibraryContext
    extends SmartTilesStudioLaunchContext {
  const SmartTilesStudioLibraryContext();

  @override
  bool operator ==(Object other) => other is SmartTilesStudioLibraryContext;

  @override
  int get hashCode => Object.hash(SmartTilesStudioLibraryContext, 0);
}

final class SmartTilesStudioMapContext extends SmartTilesStudioLaunchContext {
  const SmartTilesStudioMapContext({required String mapId})
      : mapId = mapId,
        assert(mapId != '', 'mapId must not be empty');

  final String mapId;

  @override
  bool operator ==(Object other) =>
      other is SmartTilesStudioMapContext && other.mapId == mapId;

  @override
  int get hashCode => Object.hash(SmartTilesStudioMapContext, mapId);
}
