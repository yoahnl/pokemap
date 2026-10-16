import 'package:map_core/map_core_domain.dart';

import '../../project_session/domain/project_session.dart';

abstract interface class MapDivePairPort {
  Future<void> publishDivePair({
    required ProjectSession session,
    required MapData source,
    required MapData expectedTarget,
    required String zoneId,
    required String targetZoneId,
    required bool unlink,
  });
}
