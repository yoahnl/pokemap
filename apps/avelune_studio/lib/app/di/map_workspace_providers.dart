import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';

final mapWorkspacePortProvider = Provider.autoDispose
    .family<MapWorkspacePort, ProjectSession>(
      (ref, session) =>
          throw StateError('Map workspace port must be configured'),
    );

final mapWorkspaceControllerProvider = Provider.autoDispose
    .family<MapWorkspaceController, ProjectSession>((ref, session) {
      final controller = MapWorkspaceController(
        session,
        ref.watch(mapWorkspacePortProvider(session)),
      );
      ref.onDispose(controller.dispose);
      return controller;
    });

final workspaceVisualsLoaderProvider = Provider<LoadWorkspaceVisuals>(
  (ref) => throw StateError('Workspace visuals loader must be configured'),
);

final workspaceRuntimeBuilderProvider =
    Provider<StudioRuntimeBuilder Function(ProjectSession, MapWorkspacePort)>(
      (ref) => throw StateError('Workspace runtime builder must be configured'),
    );
