import 'package:map_core/map_core_domain.dart';

import '../../project_session/domain/project_session.dart';
import 'map_workspace_port.dart';

final class MapEditorWorkspaceState {
  const MapEditorWorkspaceState({required this.state, required this.revision});
  final MapEditorState state;
  final String revision;
}

abstract interface class MapEditorPort {
  Future<MapEditorWorkspaceState> loadEditorState(
    ProjectSession session,
    String mapId,
  );
  Future<MapEditorWorkspaceState> saveEditorState(
    ProjectSession session,
    String mapId,
    MapEditorState state,
    String expectedRevision,
  );
}

final class MapElementOrderWorkspaceReceipt {
  const MapElementOrderWorkspaceReceipt({
    required this.document,
    required this.receiptId,
    required this.documentRevision,
  });
  final MapWorkspaceDocument document;
  final String receiptId, documentRevision;
}

abstract interface class MapElementOrderPort {
  Future<MapElementOrderWorkspaceReceipt> reorderMapElements(
    ProjectSession session,
    MapWorkspaceDocument base,
    String kind,
    List<String> frontFirstIds,
    String? layerId,
  );
  Future<MapElementOrderWorkspaceReceipt> undoMapElementOrder(
    ProjectSession session,
    MapWorkspaceDocument base,
    MapElementOrderWorkspaceReceipt receipt,
  );
}
