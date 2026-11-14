import 'package:avelune_studio/app/di/language_providers.dart';
import 'package:avelune_studio/features/language/coordination/studio_language_preferences.dart';
import 'package:avelune_studio/platform/files/local_language_preferences_store.dart';
import 'dart:async';
import 'dart:io';

import '../platform/mcp/studio_mcp_project_access.dart';

import '../platform/files/native_resource_pack_export_sink.dart';

import 'package:map_authoring/map_authoring_local.dart';

import '../platform/files/native_project_creation_picker.dart';

import '../platform/files/scoped_project_session_adapter.dart';

import 'package:flutter/widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'di/home_providers.dart';
import 'di/rendering_providers.dart';
import 'di/studio_mcp_providers.dart';
import '../platform/mcp/studio_mcp_process.dart';
import '../platform/mcp/studio_mcp_service.dart';
import '../features/rendering/coordination/studio_rendering_preferences.dart';
import '../platform/files/local_rendering_preferences_store.dart';
import '../platform/files/local_map_layout_preferences_store.dart';
import '../features/map_workspace/coordination/map_layout_preferences.dart';
import '../platform/files/studio_preferences.dart';
import '../features/project_session/application/project_session_controller.dart';

import 'package:avelune_studio/app/di/providers.dart';
import 'package:avelune_studio/app/studio_app.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/platform/files/native_project_directory_picker.dart';
import 'studio_session_adapter_overrides.dart';

class StudioBootstrap extends StatelessWidget {
  const StudioBootstrap({
    super.key,
    this.debugSession,
    this.templateCatalog = const ProjectTemplateCatalog.empty(),
    this.readTemplate,
    this.renderingPreferences,
    this.mcpService,
  });

  final ProjectSessionController? debugSession;
  final ProjectTemplateCatalog templateCatalog;
  final Future<List<int>> Function(Uri)? readTemplate;
  final StudioRenderingPreferences? renderingPreferences;
  final StudioMcpService? mcpService;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      studioMcpExternalMutations,
      studioMcpServiceProvider.overrideWith((ref) {
        final service =
            mcpService ??
            StudioMcpService(
              launch: launchStudioMcpProcess,
              projectBookmark: Platform.isMacOS
                  ? createStudioMcpProjectBookmark
                  : null,
            );
        ref.onDispose(service.dispose);
        return service;
      }),
      studioMapLayoutPreferencesProvider.overrideWith((ref) {
        final preferences = MapLayoutPreferences(
          studioMapLayoutPreferencesStore(),
        );
        unawaited(preferences.load());
        ref.onDispose(preferences.dispose);
        return preferences;
      }),
      studioLanguagePreferencesProvider.overrideWith((ref) {
        final preferences = StudioLanguagePreferences(studioLanguageStore());
        unawaited(preferences.load());
        ref.onDispose(preferences.dispose);
        return preferences;
      }),
      studioRenderingPreferencesProvider.overrideWith((ref) {
        final supplied = renderingPreferences;
        if (supplied != null) return supplied;
        final preferences = StudioRenderingPreferences(
          studioRenderingPreferencesStore(),
        );
        ref.onDispose(preferences.dispose);
        return preferences;
      }),
      if (Platform.isMacOS)
        resourcePackExportSinkProvider.overrideWith(
          (ref) => NativeResourcePackExportSink(),
        ),
      projectCreationPortProvider.overrideWithValue(
        LocalProjectCreationService(
          templateCatalog: templateCatalog,
          readTemplate: readTemplate,
        ),
      ),
      projectCreationPickerProvider.overrideWithValue(
        const NativeProjectCreationPicker().choose,
      ),
      projectCreationReleaseProvider.overrideWithValue(
        const NativeProjectCreationPicker().release,
      ),
      if (debugSession != null)
        projectSessionControllerProvider.overrideWithValue(debugSession!),
      recentProjectsPortProvider.overrideWith((ref) => studioRecentProjects()),
      projectSessionPortProvider.overrideWith((ref) {
        final local = LocalProjectSessionAdapter();
        return Platform.isMacOS ? ScopedProjectSessionAdapter(local) : local;
      }),
      projectDirectoryPickerProvider.overrideWithValue(
        const NativeProjectDirectoryPicker().choose,
      ),
      ...studioSessionAdapterOverrides(),
    ],
    child: const StudioApp(),
  );
}
