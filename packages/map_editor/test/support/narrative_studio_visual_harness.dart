import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

import '../shell_chrome_test_harness.dart';

const narrativeStudioRealRouteModes = <EditorWorkspaceMode>[
  EditorWorkspaceMode.narrativeOverview,
  EditorWorkspaceMode.globalStory,
  EditorWorkspaceMode.step,
  EditorWorkspaceMode.scenes,
  EditorWorkspaceMode.events,
  EditorWorkspaceMode.cutscene,
  EditorWorkspaceMode.dialogue,
  EditorWorkspaceMode.facts,
  EditorWorkspaceMode.worldRules,
  EditorWorkspaceMode.narrativeValidator,
];

ProjectManifest buildNarrativeStudioVisualProject({
  EventSystemMode eventSystemMode = EventSystemMode.legacyOnly,
}) {
  return ProjectManifest(
    name: 'Narrative visual contract',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'map_contract',
        name: 'Contract Map',
        relativePath: 'maps/contract.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: eventSystemMode,
      records: const <NarrativeEventRecord>[],
      legacyClaims: const <LegacySourceClaim>[],
    ),
  );
}

const narrativeStudioVisualMap = MapData(
  id: 'map_contract',
  name: 'Contract Map',
  size: GridSize(width: 12, height: 10),
);

Future<ProviderContainer> pumpNarrativeStudioRealRoute(
  WidgetTester tester, {
  required EditorWorkspaceMode mode,
  required ProjectManifest? project,
  String? projectRootPath,
  MapData? activeMap,
  Size surfaceSize = const Size(1672, 941),
  bool isProjectDirty = false,
}) {
  return pumpEditorShellPage(
    tester,
    initialState: EditorState(
      projectRootPath: projectRootPath,
      project: project,
      activeMap: activeMap,
      workspaceMode: mode,
      isProjectDirty: isProjectDirty,
    ),
    surfaceSize: surfaceSize,
  );
}
