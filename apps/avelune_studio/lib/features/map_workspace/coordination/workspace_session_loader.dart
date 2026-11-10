import 'package:map_core/map_core_domain.dart';

import '../../narrative/domain/narrative_port.dart';
import '../../resources/domain/resource_port.dart';
import '../../resources/domain/resource_pack_port.dart';

import 'package:flutter/foundation.dart';

import '../../narrative/application/narrative_workspace_controller.dart';

import 'package:avelune_studio/features/narrative/application/narrative_navigation.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';

import '../../map_workspace/application/map_workspace_controller.dart';

import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';

import '../application/map_workspace_editing_state.dart';
import '../../../platform/rendering/contracts/character_workspace_visuals.dart';
import '../../resources/domain/resource_usage_port.dart';

void retainWorkspaceBrush(
  MapWorkspaceVisuals? visuals,
  MapWorkspaceEditingState? view,
) {
  if (visuals case final CharacterWorkspaceVisuals characters
      when view?.character != null) {
    characters.setCharacterBrush(view?.character);
  } else if (visuals case final ResourceWorkspaceVisuals resources
      when view?.terrain != null) {
    resources.setTerrainBrush(view?.terrain);
  } else {
    visuals?.setBrush(view?.brush, view?.tile);
  }
}

Future<LoadedWorkspaceSession?> loadWorkspaceSession({
  required MapWorkspaceController workspace,
  required LoadWorkspaceVisuals loadVisuals,
  NarrativePort? narrativePort,
  ResourcePort? resourcePort,
  ResourcePackPort? resourcePackPort,
  PickResourcePack? resourcePackPicker,
  PickResourcePackLicenses? resourcePackLicensePicker,
  ResourcePackExportSink? resourcePackExportSink,
  required bool Function() isActive,
  required VoidCallback changed,
  required Future<void> Function(ResourceItem) onUse,
  Future<bool> Function(ResourceUsageEntry)? openUsage,
  bool Function(ResourceUsageEntry)? canOpenUsage,
  List<String> Function()? additionalDraftOwners,
}) async {
  await workspace.initialize();
  final project = workspace.project;
  if (!isActive() || project == null) return null;
  final visuals = await loadVisuals(workspace.session, project);
  if (!isActive()) {
    await visuals.dispose();
    return null;
  }
  final narrative = narrativePort == null
      ? null
      : NarrativeWorkspaceController(workspace, narrativePort, changed, (
          manifest,
          paths,
        ) async {
          if (visuals is ResourceWorkspaceVisuals) {
            await (visuals as ResourceWorkspaceVisuals).updateCatalog(
              manifest,
              changedRelativePaths: paths,
            );
          }
        });
  String? Function(MapData, MapData)? historyGuard;
  if (narrative != null) {
    historyGuard = (before, after) =>
        guardNarrativeHistory(narrative, before, after);
    workspace.historyGuard = historyGuard;
  }
  final resources = resourcePort == null
      ? null
      : ResourceNavigation(
          workspace: workspace,
          port: resourcePort,
          packPort: resourcePackPort,
          packPicker: resourcePackPicker,
          packLicensePicker: resourcePackLicensePicker,
          packExportSink: resourcePackExportSink,
          visuals: visuals,
          onUse: onUse,
          openUsage: openUsage,
          canOpenUsage: canOpenUsage,
          additionalDraftOwners: additionalDraftOwners,
        );
  resources?.addListener(changed);
  visuals.addListener(changed);
  return LoadedWorkspaceSession(
    workspace: workspace,
    visuals: visuals,
    resources: resources,
    narrative: narrative,
    historyGuard: historyGuard,
    changed: changed,
  );
}

class LoadedWorkspaceSession {
  LoadedWorkspaceSession({
    required this.workspace,
    required this.visuals,
    required this.resources,
    required this.narrative,
    required this.historyGuard,
    required this.changed,
  });

  final MapWorkspaceController workspace;
  final MapWorkspaceVisuals visuals;
  final ResourceNavigation? resources;
  final NarrativeWorkspaceController? narrative;
  final String? Function(MapData, MapData)? historyGuard;
  final void Function() changed;
  Future<void>? _disposal;

  Future<void> dispose() => _disposal ??= _dispose();

  Future<void> _dispose() async {
    if (identical(workspace.historyGuard, historyGuard)) {
      workspace.historyGuard = null;
    }
    visuals.removeListener(changed);
    final releasingVisuals = visuals.dispose();
    resources?.removeListener(changed);
    resources?.dispose();
    narrative?.dispose();
    await releasingVisuals;
  }
}
