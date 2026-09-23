import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/game_export/domain/studio_game_export_port.dart';
import '../../features/project_session/domain/project_session.dart';

final gameExportPortProvider = Provider.autoDispose
    .family<StudioGameExportPort, ProjectSession>(
      (ref, session) => throw StateError('Game export port must be configured'),
    );

final gameExportPickerProvider = Provider<PickGameExportFile>(
  (ref) => throw StateError('Game export picker must be configured'),
);
