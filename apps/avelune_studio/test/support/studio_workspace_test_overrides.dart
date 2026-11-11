import 'package:avelune_studio/app/di/map_workspace_providers.dart';
import 'package:flutter_riverpod/misc.dart';

import 'map_workspace_fixture.dart';

List<Override> studioWorkspaceTestOverrides() => [
  mapWorkspacePortProvider.overrideWith(
    (ref, session) => WorkspaceMemoryPort(),
  ),
  workspaceVisualsLoaderProvider.overrideWithValue(
    (session, manifest) async => WorkspaceTestVisuals(),
  ),
];
