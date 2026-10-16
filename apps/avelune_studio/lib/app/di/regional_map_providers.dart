import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/project_session/domain/project_session.dart';
import '../../features/regional_map/domain/regional_map_port.dart';

final regionalMapPortProvider = Provider.autoDispose
    .family<RegionalMapPort, ProjectSession>(
      (ref, session) =>
          throw StateError('Regional map port must be configured'),
    );
