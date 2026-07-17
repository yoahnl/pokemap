import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../design_system/design_system.dart';
import '../../../application/models/narrative_event_map_bridge_models.dart';
import '../../../features/editor/state/editor_notifier.dart';
import '../../../features/narrative/state/narrative_event_map_bridge_state.dart';
import '../../../theme/theme.dart';

/// Temporary V2 source summary embedded above the legacy Event Builder.
///
/// Phase H will replace the surrounding workspace. This panel deliberately
/// owns no map/source picker: it only navigates from the selected typed source.
class NarrativeEventMapReturnPanel extends ConsumerWidget {
  const NarrativeEventMapReturnPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorNotifierProvider);
    final bridge = ref.watch(narrativeEventMapBridgeControllerProvider);
    final project = editor.project;
    final eventId = bridge.selectedNarrativeEventV2Id;
    final record = _recordById(project?.eventRegistry, eventId);
    if (project == null || eventId == null || record == null) {
      return const SizedBox.shrink();
    }
    final source =
        record.draftOrNull?.source ?? record.definitionOrNull?.source;
    final sourceMissing = source == null;
    final spatial = source != null &&
        source.kind != NarrativeEventSourceKind.outcomeReceived;
    final selectedGroup = bridge.selectedGroupContext;
    final missingSourceMapContext = sourceMissing &&
        selectedGroup?.kind == NarrativeEventGroupContextKind.map;
    final colors = context.pokeMapColors;
    final name = record.draftOrNull?.name ?? record.definitionOrNull!.name;

    Future<void> open(NarrativeEventMapNavigationMode mode) async {
      if (!spatial) return;
      final current = ref.read(editorNotifierProvider);
      final currentProject = current.project;
      if (currentProject == null) return;
      final group = NarrativeEventGroupContext.map(_mapId(source));
      final notifier = ref.read(editorNotifierProvider.notifier);
      final result = await ref
          .read(narrativeEventMapBridgeControllerProvider.notifier)
          .openMapForEvent(
            eventId: eventId,
            groupContext: group,
            mode: mode,
            project: currentProject,
            activeMap: current.activeMap,
            mapDirty: current.isDirty,
            loadMapSnapshot: notifier.loadMapSnapshotById,
            activateMapSnapshot: notifier.activateNarrativeEventMapSnapshot,
            applyFocus: notifier.focusNarrativeEventMapSource,
          );
      if (!result.succeeded) return;
      final afterNavigation = ref.read(editorNotifierProvider);
      await ref
          .read(narrativeEventMapBridgeControllerProvider.notifier)
          .inspectPendingSourceCreation(
            projectRootPath: afterNavigation.projectRootPath,
            mapDirty: afterNavigation.isDirty,
            projectDirty: afterNavigation.isProjectDirty,
            saving: afterNavigation.isSaving,
          );
      notifier.selectMapWorkspace();
    }

    Future<void> createSourceOnMap() async {
      if (!missingSourceMapContext || record.draftOrNull == null) return;
      final current = ref.read(editorNotifierProvider);
      final currentProject = current.project;
      if (currentProject == null) return;
      final notifier = ref.read(editorNotifierProvider.notifier);
      final controller =
          ref.read(narrativeEventMapBridgeControllerProvider.notifier);
      final result = await controller.openMapForMissingSource(
        eventId: eventId,
        groupContext: selectedGroup!,
        project: currentProject,
        activeMap: current.activeMap,
        mapDirty: current.isDirty,
        loadMapSnapshot: notifier.loadMapSnapshotById,
        activateMapSnapshot: notifier.activateNarrativeEventMapSnapshot,
      );
      if (!result.succeeded) return;
      await controller.inspectPendingSourceCreation(
        projectRootPath: current.projectRootPath,
        mapDirty: current.isDirty,
        projectDirty: current.isProjectDirty,
        saving: current.isSaving,
      );
      notifier.selectMapWorkspace();
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: PokeMapPanel(
        key: const ValueKey('narrative-event-map-return-panel'),
        padding: const EdgeInsets.all(12),
        header: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Icon(CupertinoIcons.link, color: colors.narrative, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const PokeMapBadge(
                label: 'Event V2',
                variant: PokeMapBadgeVariant.narrative,
              ),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              sourceMissing
                  ? missingSourceMapContext
                      ? 'Source manquante · ${_mapName(project, selectedGroup!.mapId!)}'
                      : 'Source manquante · choisissez cet Event depuis son groupe de map'
                  : spatial
                      ? _spatialSourceLabel(project, source)
                      : 'Event global · aucune position sur une map',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (spatial) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: PokeMapButton(
                      key: const ValueKey('narrative-event-view-on-map'),
                      onPressed: () =>
                          open(NarrativeEventMapNavigationMode.view),
                      size: PokeMapButtonSize.small,
                      leading: const Icon(CupertinoIcons.eye),
                      child: const Text('Voir sur la carte'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PokeMapButton(
                      key: const ValueKey('narrative-event-choose-on-map'),
                      onPressed: () =>
                          open(NarrativeEventMapNavigationMode.choose),
                      variant: PokeMapButtonVariant.secondary,
                      size: PokeMapButtonSize.small,
                      leading: const Icon(CupertinoIcons.scope),
                      child: const Text('Choisir / changer'),
                    ),
                  ),
                ],
              ),
            ],
            if (missingSourceMapContext && record.draftOrNull != null) ...[
              const SizedBox(height: 10),
              PokeMapButton(
                key: const ValueKey('narrative-event-create-source-on-map'),
                onPressed:
                    bridge.isSourceCreationBusy ? null : createSourceOnMap,
                variant: PokeMapButtonVariant.ghost,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.add_circled),
                child: const Text('Créer une source sur la carte'),
              ),
            ],
            if (bridge.lastNavigationResult != null &&
                !bridge.lastNavigationResult!.succeeded) ...[
              const SizedBox(height: 8),
              Text(
                bridge.lastNavigationResult!.message,
                style: TextStyle(
                  color: colors.error,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

NarrativeEventRecord? _recordById(
  NarrativeEventRegistry? registry,
  String? eventId,
) {
  if (eventId == null) return null;
  NarrativeEventRecord? match;
  for (final record in registry?.records ?? const <NarrativeEventRecord>[]) {
    if (record.id != eventId) continue;
    if (match != null) return null;
    match = record;
  }
  return match;
}

String _mapId(NarrativeEventSourceRef source) {
  return source.when(
    entityInteract: (mapId, _) => mapId,
    triggerEnter: (mapId, _) => mapId,
    mapEnter: (mapId) => mapId,
    outcomeReceived: (_) => throw StateError('A global source has no map.'),
  );
}

String _spatialSourceLabel(
  ProjectManifest project,
  NarrativeEventSourceRef source,
) {
  final mapId = _mapId(source);
  final mapName = _mapName(project, mapId);
  return source.when(
    entityInteract: (_, __) => 'Interaction avec une entité · $mapName',
    triggerEnter: (_, __) => 'Entrée dans une zone · $mapName',
    mapEnter: (_) => 'Entrée sur la map · $mapName',
    outcomeReceived: (_) => 'Event global',
  );
}

String _mapName(ProjectManifest project, String mapId) {
  for (final entry in project.maps) {
    if (entry.id == mapId) {
      return entry.name;
    }
  }
  return 'Map liée';
}
