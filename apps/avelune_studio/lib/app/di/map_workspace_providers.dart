import 'dart:async';

import '../../features/playtest/contracts/studio_playtest_builders.dart';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_connection_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_catalog_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';

final mapWorkspacePortProvider = Provider.autoDispose
    .family<MapWorkspacePort, ProjectSession>(
      (ref, session) =>
          throw StateError('Map workspace port must be configured'),
    );

final mapCatalogPortProvider = Provider.autoDispose
    .family<MapCatalogPort?, ProjectSession>((ref, session) => null);

final mapConnectionPortProvider = Provider.autoDispose
    .family<MapConnectionPort, ProjectSession>(
      (ref, session) =>
          throw StateError('Map connection port must be configured'),
    );

typedef ExternalProjectMutation = ({
  String projectRoot,
  Set<({String kind, String id})> resources,
});

final externalProjectMutationsProvider =
    Provider<Stream<ExternalProjectMutation>>((ref) => const Stream.empty());

final mapWorkspaceControllerProvider = Provider.autoDispose
    .family<MapWorkspaceController, ProjectSession>((ref, session) {
      final controller = MapWorkspaceController(
        session,
        ref.watch(mapWorkspacePortProvider(session)),
        catalogPort: ref.watch(mapCatalogPortProvider(session)),
      );
      final changes = ref.watch(externalProjectMutationsProvider).listen((
        mutation,
      ) {
        if (mutation.projectRoot != session.directoryPath) return;
        unawaited(controller.acceptExternalMutation(mutation.resources));
      });
      ref.onDispose(() {
        unawaited(changes.cancel());
        controller.dispose();
      });
      return controller;
    });

final workspaceVisualsLoaderProvider = Provider<LoadWorkspaceVisuals>(
  (ref) => throw StateError('Workspace visuals loader must be configured'),
);

final workspaceRuntimeBuilderProvider =
    Provider<StudioRuntimeBuilder Function(ProjectSession, MapWorkspacePort)>(
      (ref) => throw StateError('Workspace runtime builder must be configured'),
    );

final projectRuntimeBuilderProvider =
    Provider<Widget Function(ProjectSession, VoidCallback)?>((ref) => null);
