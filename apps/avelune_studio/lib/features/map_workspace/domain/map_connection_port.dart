import 'package:map_core/map_core_domain.dart';

import '../../project_session/domain/project_session.dart';

abstract interface class MapConnectionPort {
  Future<void> link({
    required ProjectSession session,
    required MapData source,
    required MapConnectionDirection direction,
    required String targetMapId,
    required int offset,
    MapData? expectedTarget,
  });

  Future<void> unlink({
    required ProjectSession session,
    required MapData source,
    required MapConnectionDirection direction,
    MapData? expectedTarget,
  });
}
