import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../../app/providers/core/repository_providers.dart';
import '../../application/world_map_connection_context.dart';
import '../../application/world_map_connection_context_loader.dart';

final class WorldMapConnectionContextRequest {
  const WorldMapConnectionContextRequest({
    required this.projectRootPath,
    required this.project,
    required this.sourceMap,
  });

  final String projectRootPath;
  final ProjectManifest project;
  final MapData sourceMap;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorldMapConnectionContextRequest &&
          other.projectRootPath == projectRootPath &&
          other.project == project &&
          other.sourceMap == sourceMap;

  @override
  int get hashCode => Object.hash(projectRootPath, project, sourceMap);
}

final worldMapConnectionContextProvider = FutureProvider.autoDispose
    .family<WorldMapConnectionContext, WorldMapConnectionContextRequest>(
  (ref, request) {
    final workspace = ref
        .watch(projectWorkspaceFactoryProvider)
        .create(request.projectRootPath);
    return WorldMapConnectionContextLoader(
      mapRepository: ref.watch(mapRepositoryProvider),
    ).load(
      workspace: workspace,
      project: request.project,
      sourceMap: request.sourceMap,
    );
  },
);

final worldMapConnectionDirectionProvider = NotifierProvider.autoDispose<
    WorldMapConnectionDirectionController, MapConnectionDirection>(
  WorldMapConnectionDirectionController.new,
);

/// Keeps the compass selection scoped to the active inspector lifecycle.
final class WorldMapConnectionDirectionController
    extends Notifier<MapConnectionDirection> {
  @override
  MapConnectionDirection build() => MapConnectionDirection.north;

  void select(MapConnectionDirection direction) {
    if (state == direction) return;
    state = direction;
  }
}
