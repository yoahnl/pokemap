import 'package:flutter/widgets.dart';
import 'package:map_core/map_core_domain.dart';

import '../../project_session/application/project_session.dart';

abstract interface class MapWorkspaceVisuals {
  Widget canvas(MapData map);
  Widget thumbnail(ProjectElementEntry element, {double size = 48});
  List<String> get warnings;
  Future<void> dispose();
}

typedef LoadWorkspaceVisuals =
    Future<MapWorkspaceVisuals> Function(
      ProjectSession session,
      ProjectManifest manifest,
    );
