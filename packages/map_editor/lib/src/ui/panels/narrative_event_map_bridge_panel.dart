import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/models/narrative_event_map_bridge_models.dart';
import '../../application/use_cases/narrative_event_spatial_source_link_use_case.dart';
import '../../features/border_map_editing/state/border_preview_providers.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/narrative/state/narrative_event_map_bridge_state.dart';
import '../../theme/theme.dart';
import '../design_system/design_system.dart';

class NarrativeEventMapBridgePanel extends ConsumerWidget {
  const NarrativeEventMapBridgePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorNotifierProvider);
    final bridgeState = ref.watch(narrativeEventMapBridgeControllerProvider);
    final hasPendingBorderPreview =
        ref.watch(borderPreviewControllerProvider).hasPendingPreview;
    final map = editorState.activeMap;
    if (map == null) return const SizedBox.shrink();

    final selectedEntity = _selectedEntity(
      map,
      editorState.selectedEntityId,
    );
    final selectedTrigger = _selectedTrigger(
      map,
      editorState.selectedTriggerId,
    );
    final controller =
        ref.read(narrativeEventMapBridgeControllerProvider.notifier);
    final colors = context.pokeMapColors;

    Future<void> chooseSource(NarrativeEventSourceRef source) async {
      final current = ref.read(editorNotifierProvider);
      final currentProject = current.project;
      final currentMap = current.activeMap;
      if (currentProject == null || currentMap == null) return;
      final notifier = ref.read(editorNotifierProvider.notifier);
      final result = await controller.linkChosenSource(
        projectRootPath: current.projectRootPath,
        project: currentProject,
        activeMap: currentMap,
        source: source,
        mapDirty: current.isDirty,
        projectDirty: current.isProjectDirty,
        saving: current.isSaving,
        applyPersistedRegistry: notifier.applyPersistedNarrativeEventRegistry,
      );
      if (result?.status != NarrativeEventSpatialSourceLinkStatus.committed &&
          result?.status != NarrativeEventSpatialSourceLinkStatus.noOp) {
        return;
      }
      final updatedProject = ref.read(editorNotifierProvider).project;
      if (updatedProject == null) return;
      controller.returnToEvent(
        project: updatedProject,
        openExactEvent: ({required eventId, required groupContext}) {
          notifier.selectEventsWorkspace();
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 12),
      child: PokeMapPanel(
        padding: const EdgeInsets.all(12),
        header: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                Icon(
                  CupertinoIcons.link,
                  color: colors.narrative,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Events V2 depuis la map',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                PokeMapBadge(
                  label: constraints.maxWidth < 240
                      ? 'Source'
                      : 'Source existante',
                  variant: PokeMapBadgeVariant.narrative,
                ),
              ],
            ),
          ),
        ),
        child: bridgeState.pendingReturn != null &&
                bridgeState.navigationMode ==
                    NarrativeEventMapNavigationMode.choose
            ? _ChooseSourceActions(
                map: map,
                selectedEntity: selectedEntity,
                selectedTrigger: selectedTrigger,
                result: bridgeState.lastSourceLinkResult,
                isBusy: bridgeState.isLinkingSource,
                onChoose: bridgeState.isLinkingSource ? null : chooseSource,
              )
            : bridgeState.recovery != null
                ? _OutOfSyncRecovery(
                    recovery: bridgeState.recovery!,
                    reloadBlocked: editorState.isDirty ||
                        editorState.isProjectDirty ||
                        editorState.isSaving ||
                        hasPendingBorderPreview,
                    onCancel: () => controller.dismissRecovery(
                      projectRootPath: editorState.projectRootPath,
                    ),
                    onReload: editorState.isDirty ||
                            editorState.isProjectDirty ||
                            editorState.isSaving ||
                            hasPendingBorderPreview
                        ? null
                        : () async {
                            final recovery = bridgeState.recovery!;
                            final current = ref.read(editorNotifierProvider);
                            final currentRoot = current.projectRootPath;
                            if (current.isDirty ||
                                current.isProjectDirty ||
                                current.isSaving ||
                                ref
                                    .read(borderPreviewControllerProvider)
                                    .hasPendingPreview ||
                                currentRoot == null ||
                                p.normalize(currentRoot) !=
                                    recovery.projectRootPath) {
                              return;
                            }
                            final notifier =
                                ref.read(editorNotifierProvider.notifier);
                            await notifier.loadProject(
                              p.join(recovery.projectRootPath, 'project.json'),
                              rememberAsRecent: false,
                            );
                            final reloaded = ref.read(editorNotifierProvider);
                            controller.finishRecoveryReload(
                              projectRootPath: reloaded.projectRootPath,
                              loadedRegistry: reloaded.project?.eventRegistry,
                            );
                          },
                  )
                : bridgeState.pendingIntent != null
                    ? _PendingIntent(
                        state: bridgeState,
                        onCancel: controller.cancel,
                        onConfirm: editorState.projectRootPath == null
                            ? null
                            : () async {
                                final result = await controller.confirm(
                                  projectRootPath: editorState.projectRootPath,
                                  mapDirty: editorState.isDirty,
                                  projectDirty: editorState.isProjectDirty,
                                  saving: editorState.isSaving,
                                  applyPersistedRegistry: ref
                                      .read(editorNotifierProvider.notifier)
                                      .applyPersistedNarrativeEventRegistry,
                                );
                                if (result?.status ==
                                    NarrativeEventMapCreationStatus.committed) {
                                  final current =
                                      ref.read(editorNotifierProvider);
                                  final project = current.project;
                                  final eventId = result?.eventId;
                                  if (project != null && eventId != null) {
                                    controller.selectNarrativeEventV2(
                                      project,
                                      eventId,
                                    );
                                    ref
                                        .read(editorNotifierProvider.notifier)
                                        .selectEventsWorkspace();
                                  }
                                }
                              },
                      )
                    : bridgeState.linkedEvents.isNotEmpty
                        ? _ExistingLinks(
                            state: bridgeState,
                            onSelect: (eventId) {
                              final project = editorState.project;
                              if (project == null ||
                                  !controller.selectNarrativeEventV2(
                                    project,
                                    eventId,
                                  )) {
                                return;
                              }
                              ref
                                  .read(editorNotifierProvider.notifier)
                                  .selectEventsWorkspace();
                            },
                            onCreateAdditional:
                                controller.requestAdditionalEvent,
                            onBack: controller.clearLinkedEvents,
                          )
                        : _SourceActions(
                            map: map,
                            selectedEntity: selectedEntity,
                            selectedTrigger: selectedTrigger,
                            result: bridgeState.lastResult,
                            onRequest: (intent) {
                              controller.request(
                                intent,
                                projectRootPath: editorState.projectRootPath,
                              );
                            },
                          ),
      ),
    );
  }
}

class _ChooseSourceActions extends StatelessWidget {
  const _ChooseSourceActions({
    required this.map,
    required this.selectedEntity,
    required this.selectedTrigger,
    required this.result,
    required this.isBusy,
    required this.onChoose,
  });

  final MapData map;
  final MapEntity? selectedEntity;
  final MapTrigger? selectedTrigger;
  final NarrativeEventSpatialSourceLinkResult? result;
  final bool isBusy;
  final ValueChanged<NarrativeEventSourceRef>? onChoose;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Choisissez la source physique déjà présente. Sa map est reprise '
          'automatiquement.',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        if (selectedEntity != null) ...[
          PokeMapButton(
            key: ValueKey(
              'narrative-event-choose-source-entity-${selectedEntity!.id}',
            ),
            onPressed: onChoose == null
                ? null
                : () => onChoose!(
                      NarrativeEventSourceRef.entityInteract(
                        map.id,
                        selectedEntity!.id,
                      ),
                    ),
            isLoading: isBusy,
            size: PokeMapButtonSize.small,
            leading: const Icon(CupertinoIcons.person_crop_circle),
            child: const Text('Utiliser l’entité sélectionnée'),
          ),
          const SizedBox(height: 8),
        ],
        if (selectedTrigger != null) ...[
          PokeMapButton(
            key: ValueKey(
              'narrative-event-choose-source-trigger-${selectedTrigger!.id}',
            ),
            onPressed: onChoose == null
                ? null
                : () => onChoose!(
                      NarrativeEventSourceRef.triggerEnter(
                        map.id,
                        selectedTrigger!.id,
                      ),
                    ),
            isLoading: isBusy,
            size: PokeMapButtonSize.small,
            leading: const Icon(CupertinoIcons.square),
            child: const Text('Utiliser la zone sélectionnée'),
          ),
          const SizedBox(height: 8),
        ],
        PokeMapButton(
          key: ValueKey('narrative-event-choose-source-map-${map.id}'),
          onPressed: onChoose == null
              ? null
              : () => onChoose!(NarrativeEventSourceRef.mapEnter(map.id)),
          isLoading: isBusy,
          variant: PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.small,
          leading: const Icon(CupertinoIcons.map),
          child: const Text('Utiliser cette map'),
        ),
        if (result != null &&
            result!.status != NarrativeEventSpatialSourceLinkStatus.committed &&
            result!.status != NarrativeEventSpatialSourceLinkStatus.noOp) ...[
          const SizedBox(height: 8),
          Text(
            result!.message,
            style: TextStyle(
              color: colors.error,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _OutOfSyncRecovery extends StatelessWidget {
  const _OutOfSyncRecovery({
    required this.recovery,
    required this.reloadBlocked,
    required this.onReload,
    required this.onCancel,
  });

  final NarrativeEventMapBridgeRecovery recovery;
  final bool reloadBlocked;
  final Future<void> Function()? onReload;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          recovery.result.message,
          style: TextStyle(
            color: colors.error,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        if (reloadBlocked) ...[
          const SizedBox(height: 8),
          Text(
            'Enregistrez les modifications en cours avant de recharger.',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 10),
        PokeMapButton(
          key: const ValueKey('narrative-event-map-recovery-reload'),
          onPressed: onReload,
          size: PokeMapButtonSize.small,
          leading: const Icon(CupertinoIcons.refresh),
          child: const Text('Recharger le projet'),
        ),
        const SizedBox(height: 8),
        PokeMapButton(
          key: const ValueKey('narrative-event-map-recovery-cancel'),
          onPressed: onCancel,
          variant: PokeMapButtonVariant.ghost,
          size: PokeMapButtonSize.small,
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}

class _SourceActions extends StatelessWidget {
  const _SourceActions({
    required this.map,
    required this.selectedEntity,
    required this.selectedTrigger,
    required this.result,
    required this.onRequest,
  });

  final MapData map;
  final MapEntity? selectedEntity;
  final MapTrigger? selectedTrigger;
  final NarrativeEventMapCreationResult? result;
  final ValueChanged<NarrativeEventMapCreationIntent> onRequest;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final resultColor =
        result?.status == NarrativeEventMapCreationStatus.committed
            ? colors.success
            : colors.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Créez un Event V2 ou ouvrez les Events déjà liés. La map et '
          'l’identité de la source sont reprises automatiquement.',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        PokeMapButton(
          key: ValueKey('narrative-event-map-source-map-${map.id}'),
          onPressed: () => onRequest(
            NarrativeEventMapCreationIntent(
              source: NarrativeEventSourceRef.mapEnter(map.id),
              humanName: 'Entrée dans ${map.name}',
            ),
          ),
          variant: PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.small,
          leading: const Icon(CupertinoIcons.map),
          child: Text('Entrée dans ${map.name}'),
        ),
        if (selectedEntity != null) ...[
          const SizedBox(height: 8),
          PokeMapButton(
            key: ValueKey(
              'narrative-event-map-source-entity-${selectedEntity!.id}',
            ),
            onPressed: () => onRequest(
              NarrativeEventMapCreationIntent(
                source: NarrativeEventSourceRef.entityInteract(
                  map.id,
                  selectedEntity!.id,
                ),
                humanName:
                    'Interaction avec ${selectedEntity!.inspectorHeadline}',
              ),
            ),
            variant: PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.small,
            leading: const Icon(CupertinoIcons.person_crop_circle),
            child: Text(
              'Interaction avec ${selectedEntity!.inspectorHeadline}',
            ),
          ),
        ],
        if (selectedTrigger != null) ...[
          const SizedBox(height: 8),
          PokeMapButton(
            key: ValueKey(
              'narrative-event-map-source-trigger-${selectedTrigger!.id}',
            ),
            onPressed: () => onRequest(
              NarrativeEventMapCreationIntent(
                source: NarrativeEventSourceRef.triggerEnter(
                  map.id,
                  selectedTrigger!.id,
                ),
                humanName: 'Entrée dans ${_triggerLabel(selectedTrigger!)}',
              ),
            ),
            variant: PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.small,
            leading: const Icon(CupertinoIcons.square),
            child: Text('Entrée dans ${_triggerLabel(selectedTrigger!)}'),
          ),
        ],
        if (result != null) ...[
          const SizedBox(height: 10),
          Text(
            result!.message,
            style: TextStyle(
              color: resultColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class _PendingIntent extends StatelessWidget {
  const _PendingIntent({
    required this.state,
    required this.onCancel,
    required this.onConfirm,
  });

  final NarrativeEventMapBridgeState state;
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final intent = state.pendingIntent!;
    final isAdditional = state.isAdditionalEventRequest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isAdditional) ...[
          Text(
            'Confirmer l’Event supplémentaire',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          intent.humanName,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isAdditional
              ? 'Un nouvel Event sera lié à cette même source. Les Events '
                  'déjà liés resteront inchangés.'
              : 'La source existante sera liée atomiquement. Aucun placement '
                  'de map ne sera créé ou déplacé.',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        if (state.lastResult != null) ...[
          const SizedBox(height: 8),
          Text(
            state.lastResult!.message,
            style: TextStyle(
              color: colors.error,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: PokeMapButton(
                key: const ValueKey('narrative-event-map-bridge-cancel'),
                onPressed: state.isSubmitting ? null : onCancel,
                variant: PokeMapButtonVariant.ghost,
                size: PokeMapButtonSize.small,
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PokeMapButton(
                key: const ValueKey('narrative-event-map-bridge-confirm'),
                onPressed: state.isSubmitting ? null : onConfirm,
                isLoading: state.isSubmitting,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.link),
                child: Text(
                  isAdditional
                      ? 'Créer l’Event supplémentaire'
                      : 'Créer ou ouvrir',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExistingLinks extends StatelessWidget {
  const _ExistingLinks({
    required this.state,
    required this.onSelect,
    required this.onCreateAdditional,
    required this.onBack,
  });

  final NarrativeEventMapBridgeState state;
  final ValueChanged<String> onSelect;
  final VoidCallback onCreateAdditional;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          state.lastResult?.message ?? 'Events liés à cette source',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < state.linkedEvents.length; index++) ...[
          if (index > 0) const SizedBox(height: 8),
          PokeMapButton(
            key: ValueKey(
              'narrative-event-map-existing-'
              '${state.linkedEvents[index].eventId}',
            ),
            onPressed: () => onSelect(state.linkedEvents[index].eventId),
            variant: PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.small,
            isSelected: state.selectedNarrativeEventV2Id ==
                state.linkedEvents[index].eventId,
            leading: const Icon(CupertinoIcons.arrow_right_circle),
            child: Text(state.linkedEvents[index].name),
          ),
        ],
        const SizedBox(height: 8),
        PokeMapButton(
          key: const ValueKey(
            'narrative-event-map-existing-create-additional',
          ),
          onPressed: onCreateAdditional,
          variant: PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.small,
          leading: const Icon(CupertinoIcons.add_circled),
          child: const Text('Créer un Event supplémentaire'),
        ),
        const SizedBox(height: 8),
        PokeMapButton(
          key: const ValueKey('narrative-event-map-existing-back'),
          onPressed: onBack,
          variant: PokeMapButtonVariant.ghost,
          size: PokeMapButtonSize.small,
          leading: const Icon(CupertinoIcons.chevron_left),
          child: const Text('Retour aux sources'),
        ),
      ],
    );
  }
}

MapEntity? _selectedEntity(MapData map, String? entityId) {
  if (entityId == null) return null;
  for (final entity in map.entities) {
    if (entity.id == entityId && entity.kind != MapEntityKind.spawn) {
      return entity;
    }
  }
  return null;
}

MapTrigger? _selectedTrigger(MapData map, String? triggerId) {
  if (triggerId == null) return null;
  for (final trigger in map.triggers) {
    if (trigger.id == triggerId &&
        (trigger.type == TriggerType.event ||
            trigger.type == TriggerType.custom)) {
      return trigger;
    }
  }
  return null;
}

String _triggerLabel(MapTrigger trigger) {
  final name = trigger.name.trim();
  return name.isEmpty ? trigger.id : name;
}
