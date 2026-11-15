import 'package:map_core/map_core_domain.dart';

import '../../project_session/domain/project_session.dart';
import 'map_catalog_port.dart';
import 'map_workspace_port.dart';

final class MapConnectionReceipt {
  const MapConnectionReceipt(this.documents, {this.history});

  final List<MapWorkspaceDocument> documents;
  final MapCatalogReceipt? history;
}

abstract interface class MapConnectionPort {
  Future<MapConnectionReceipt> link({
    required ProjectSession session,
    required MapData source,
    required MapConnectionDirection direction,
    required String targetMapId,
    required int offset,
    MapData? expectedTarget,
  });

  Future<MapConnectionReceipt> unlink({
    required ProjectSession session,
    required MapData source,
    required MapConnectionDirection direction,
    MapData? expectedTarget,
  });
}
