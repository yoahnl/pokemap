import 'package:map_core/map_core_domain.dart';

import '../domain/map_connection_port.dart';
import 'map_workspace_controller.dart';

List<ProjectMapEntry> mapConnectionDestinations(
  ProjectManifest project,
  String sourceMapId,
) => project.maps.where((entry) => entry.id != sourceMapId).toList();

String? mapConnectionTarget(
  List<ProjectMapEntry> destinations,
  String? selectedId,
) => destinations.any((entry) => entry.id == selectedId)
    ? selectedId
    : destinations.firstOrNull?.id;

int? mapConnectionOffset(String text) => int.tryParse(text.trim());

class MapWorkspaceConnectionActions {
  MapWorkspaceConnectionActions({
    required this.controller,
    required this.port,
    required this.isActive,
    required this.changed,
  });

  final MapWorkspaceController controller;
  final MapConnectionPort? port;
  final bool Function() isActive;
  final void Function() changed;
  bool busy = false;
  String? error;

  Future<void> link(
    MapConnectionDirection direction,
    String targetMapId,
    int offset,
  ) => mutate(
    direction: direction,
    targetMapId: targetMapId,
    offset: offset,
    remove: false,
  );

  Future<void> unlink(MapConnectionDirection direction) {
    final connection = controller.active?.current.connections
        .where((value) => value.direction == direction)
        .firstOrNull;
    if (connection == null) return Future.value();
    return mutate(
      direction: direction,
      targetMapId: connection.targetMapId,
      offset: connection.offset,
      remove: true,
    );
  }

  Future<void> mutate({
    required MapConnectionDirection direction,
    required String targetMapId,
    required int offset,
    required bool remove,
  }) async {
    final port = this.port;
    final document = controller.active;
    final targetDocument = controller.documents[targetMapId];
    if (port == null || document == null || busy) return;
    if (document.dirty || targetDocument?.dirty == true) {
      error = 'Enregistrez les brouillons des deux cartes avant de modifier leur liaison.';
      changed();
      return;
    }
    final source = document.current;
    busy = true;
    error = null;
    changed();
    try {
      final saved = remove
          ? await port.unlink(
              session: controller.session,
              source: source,
              direction: direction,
              expectedTarget: targetDocument?.current,
            )
          : await port.link(
              session: controller.session,
              source: source,
              direction: direction,
              targetMapId: targetMapId,
              offset: offset,
              expectedTarget: targetDocument?.current,
            );
      if (!isActive() || controller.isDisposed) return;
      controller.acceptSavedMaps(saved);
    } on Object catch (failure) {
      if (isActive() && !controller.isDisposed) {
        error = failure.toString();
      }
    } finally {
      if (isActive() && !controller.isDisposed) {
        busy = false;
        changed();
      }
    }
  }
}
