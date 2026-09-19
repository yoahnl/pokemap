import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avelune_studio/app/di/providers.dart';
import 'package:avelune_studio/app/studio_app.dart';
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
      workspaceVisualsLoaderProvider.overrideWithValue(StudioMapResources.load),
      workspaceRuntimeBuilderProvider.overrideWithValue(
        (session, port) =>
            (entry, revision, close) => StudioPlaytestView(
              session: session,
              entry: entry,
              expectedRevision: revision,
              port: port,
              onClose: close,
            ),
      ),
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
