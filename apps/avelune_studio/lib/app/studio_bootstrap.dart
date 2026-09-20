import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'di/home_providers.dart';
import '../features/scenes/data/local_scene_adapter.dart';
import '../platform/files/studio_preferences.dart';

import 'package:avelune_studio/app/di/providers.dart';
import 'package:avelune_studio/app/studio_app.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/platform/files/native_project_directory_picker.dart';
import 'package:avelune_studio/platform/files/native_resource_image_picker.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/platform/playtest/studio_playtest_view.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/shell/studio_workspace_host.dart';

class StudioBootstrap extends StatelessWidget {
  const StudioBootstrap({super.key});

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      recentProjectsPortProvider.overrideWith((ref) => studioRecentProjects()),
      projectSessionPortProvider.overrideWith(
        (ref) => LocalProjectSessionAdapter(),
      ),
      projectDirectoryPickerProvider.overrideWithValue(
        const NativeProjectDirectoryPicker().choose,
      ),
      mapWorkspacePortProvider.overrideWith(
        (ref, session) => LocalMapWorkspaceAdapter(),
      ),
      resourcePortProvider.overrideWith((ref, session) {
        final port = LocalResourceAdapter(
          session: session,
          mapAdapter:
              ref.watch(mapWorkspacePortProvider(session))
                  as LocalMapWorkspaceAdapter,
        );
        ref.onDispose(port.dispose);
        return port;
      }),
      resourceImagePickerProvider.overrideWithValue(
        const NativeResourceImagePicker().choose,
      ),
      narrativePortProvider.overrideWith(
        (ref, session) => LocalNarrativeAdapter(
          session: session,
          mapAdapter:
              ref.watch(mapWorkspacePortProvider(session))
                  as LocalMapWorkspaceAdapter,
        ),
      ),
      workspaceVisualsLoaderProvider.overrideWithValue(StudioMapResources.load),
      scenePortProvider.overrideWith(
        (ref, session) => LocalSceneAdapter(
          session: session,
          mapAdapter:
              ref.watch(mapWorkspacePortProvider(session))
                  as LocalMapWorkspaceAdapter,
        ),
      ),
      workspaceRuntimeBuilderProvider.overrideWithValue((session, port) {
        final testSession = StudioPlaytestSession();
        return (entry, revision, close) => StudioPlaytestView(
          session: session,
          entry: entry,
          expectedRevision: revision,
          port: port,
          onClose: close,
          testSession: testSession,
        );
      }),
    ],
    child: StudioApp(
      workspaceBuilder: (session, close, guard) => StudioWorkspaceHost(
        key: ValueKey(session.sessionId),
        session: session,
        onClose: close,
        registerExitGuard: guard,
      ),
    ),
  );
}
