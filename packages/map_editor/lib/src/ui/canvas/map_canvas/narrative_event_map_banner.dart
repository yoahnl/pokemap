import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../design_system/design_system.dart';
import '../narrative_studio/narrative_studio_destination.dart';
import '../narrative_studio/narrative_studio_navigation.dart';
import '../../../application/models/narrative_event_map_bridge_models.dart';
import '../../../application/models/narrative_event_spatial_link_journal_models.dart';
import '../../../application/models/narrative_event_spatial_source_creation_models.dart';
import '../../../application/use_cases/narrative_event_explicit_source_creation_use_case.dart';
import '../../../application/use_cases/narrative_event_spatial_source_link_use_case.dart';
import '../../../features/border_map_editing/state/border_preview_providers.dart';
import '../../../features/editor/state/editor_notifier.dart';
import '../../../features/narrative/state/narrative_event_map_bridge_state.dart';
import '../../../theme/theme.dart';

class NarrativeEventMapBanner extends ConsumerWidget {
  const NarrativeEventMapBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorNotifierProvider);
    final bridge = ref.watch(narrativeEventMapBridgeControllerProvider);
    final token = bridge.pendingReturn;
    final narrativeReturn =
        ref.watch(narrativeStudioNavigationControllerProvider).pendingReturn;
    final map = editor.activeMap;
    final project = editor.project;
    if (token == null) {
      return narrativeReturn == null
          ? const SizedBox.shrink()
          : _NarrativeMapReturnBanner(expectation: narrativeReturn);
    }
    if (map == null ||
        project == null ||
        token.groupContext.kind != NarrativeEventGroupContextKind.map ||
        token.groupContext.mapId != map.id) {
      return const SizedBox.shrink();
    }
    final record = _recordById(project.eventRegistry, token.eventId);
    final eventName = record?.draftOrNull?.name ??
        record?.definitionOrNull?.name ??
        'Event supprimé';
    final isCreate =
        bridge.navigationMode == NarrativeEventMapNavigationMode.create;
    final hasBlockingSourceRecovery = bridge.lastSourceCreationResult?.status ==
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired;
    final cleanupRequiresReload = hasBlockingSourceRecovery &&
        bridge.lastSourceCreationResult?.code == 'cleanedMapOutOfSync';
    final recoveryRequiresReload = hasBlockingSourceRecovery &&
        (bridge.lastSourceCreationResult?.journal?.state ==
                NarrativeEventSpatialLinkJournalState.eventCommitted ||
            cleanupRequiresReload);
    final hasPendingBorderPreview =
        ref.watch(borderPreviewControllerProvider).hasPendingPreview;
    final reloadIsBlocked = editor.isSaving ||
        bridge.isSourceCreationBusy ||
        hasPendingBorderPreview ||
        (!cleanupRequiresReload && (editor.isDirty || editor.isProjectDirty));
    final candidate =
        bridge.navigationMode == NarrativeEventMapNavigationMode.choose
            ? _selectedCandidate(editor.activeMap!, editor.selectedEntityId,
                editor.selectedTriggerId)
            : null;
    final colors = context.pokeMapColors;
    final controller =
        ref.read(narrativeEventMapBridgeControllerProvider.notifier);
    final notifier = ref.read(editorNotifierProvider.notifier);

    void returnToExactEvent() {
      final currentProject = ref.read(editorNotifierProvider).project;
      if (currentProject == null) return;
      controller.returnToEvent(
        project: currentProject,
        openExactEvent: ({required eventId, required groupContext}) {
          final studioNavigation = ref.read(
            narrativeStudioNavigationControllerProvider.notifier,
          );
          final restored = studioNavigation.restoreReturn();
          if (restored == null) {
            studioNavigation.replace(
              NarrativeStudioRouteLocation.events(
                selection: NarrativeStudioAssetSelection(
                  kind: NarrativeStudioAssetKind.event,
                  assetId: eventId,
                  parentId: groupContext.mapId,
                ),
              ),
            );
          }
          notifier.selectEventsWorkspace();
        },
      );
    }

    Future<void> confirmCandidate() async {
      final source = candidate?.source;
      final current = ref.read(editorNotifierProvider);
      final currentProject = current.project;
      final currentMap = current.activeMap;
      if (source == null || currentProject == null || currentMap == null) {
        return;
      }
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
      if (result?.status == NarrativeEventSpatialSourceLinkStatus.committed ||
          result?.status == NarrativeEventSpatialSourceLinkStatus.noOp) {
        returnToExactEvent();
      }
    }

    bool adoptPersistedMap(
      NarrativeEventCreatedSourceProposal proposal, {
      Object? mapWriteLeaseToken,
    }) {
      final current = ref.read(editorNotifierProvider);
      if (identical(current.activeMap, proposal.afterMap)) return true;
      return notifier.adoptPersistedNarrativeEventSourceProposal(
        proposal,
        mapWriteLeaseToken: mapWriteLeaseToken,
      );
    }

    bool applyPersistedRegistry({
      required String expectedProjectRootPath,
      required NarrativeEventRegistry? expectedPreviousRegistry,
      required NarrativeEventRegistry nextRegistry,
    }) {
      final current = ref.read(editorNotifierProvider);
      if (current.project?.eventRegistry == nextRegistry) return true;
      return notifier.applyPersistedNarrativeEventRegistry(
        expectedProjectRootPath: expectedProjectRootPath,
        expectedPreviousRegistry: expectedPreviousRegistry,
        nextRegistry: nextRegistry,
      );
    }

    Future<void> confirmCreatedSource() async {
      final current = ref.read(editorNotifierProvider);
      final currentProject = current.project;
      if (currentProject == null) return;
      final writeLease = notifier.beginNarrativeEventSourceMapWriteLease();
      if (writeLease == null) return;
      NarrativeEventExplicitSourceCreationResult? result;
      try {
        result = await controller.confirmSourceCreation(
          projectRootPath: current.projectRootPath,
          project: currentProject,
          mapDirty: current.isDirty,
          projectDirty: current.isProjectDirty,
          saving: current.isSaving,
          adoptPersistedMap: (proposal) => adoptPersistedMap(
            proposal,
            mapWriteLeaseToken: writeLease,
          ),
          applyPersistedRegistry: applyPersistedRegistry,
        );
      } finally {
        notifier.endNarrativeEventSourceMapWriteLease(writeLease);
      }
      if (result?.status ==
          NarrativeEventExplicitSourceCreationStatus.committed) {
        returnToExactEvent();
      }
    }

    Future<void> retryCreatedSource() async {
      final current = ref.read(editorNotifierProvider);
      final currentProject = current.project;
      final currentMap = current.activeMap;
      if (currentProject == null || currentMap == null) return;
      final writeLease = notifier.beginNarrativeEventSourceMapWriteLease();
      if (writeLease == null) return;
      NarrativeEventExplicitSourceCreationResult? result;
      try {
        result = await controller.retrySourceCreation(
          projectRootPath: current.projectRootPath,
          project: currentProject,
          activeMap: currentMap,
          mapDirty: current.isDirty,
          projectDirty: current.isProjectDirty,
          saving: current.isSaving,
          adoptPersistedMap: (proposal) => adoptPersistedMap(
            proposal,
            mapWriteLeaseToken: writeLease,
          ),
          applyPersistedRegistry: applyPersistedRegistry,
        );
      } finally {
        notifier.endNarrativeEventSourceMapWriteLease(writeLease);
      }
      if (result?.status ==
          NarrativeEventExplicitSourceCreationStatus.committed) {
        returnToExactEvent();
      }
    }

    Future<void> cleanupCreatedSource() async {
      final current = ref.read(editorNotifierProvider);
      final currentMap = current.activeMap;
      if (currentMap == null) return;
      await controller.cleanupCreatedSource(
        projectRootPath: current.projectRootPath,
        activeMap: currentMap,
        mapDirty: current.isDirty,
        projectDirty: current.isProjectDirty,
        saving: current.isSaving,
        beginCleanupInterlock:
            notifier.beginNarrativeEventSourceCleanupInterlock,
        releaseCleanupInterlock:
            notifier.releaseNarrativeEventSourceCleanupInterlock,
        adoptPersistedCleanup:
            notifier.adoptPersistedNarrativeEventSourceCleanup,
      );
    }

    Future<void> reloadCommittedSource() async {
      final recovery = ref
          .read(narrativeEventMapBridgeControllerProvider)
          .lastSourceCreationResult;
      final journal = recovery?.journal;
      final current = ref.read(editorNotifierProvider);
      final root = current.projectRootPath;
      final cleanupReload = recovery?.code == 'cleanedMapOutOfSync';
      if (recovery?.status !=
              NarrativeEventExplicitSourceCreationStatus.recoveryRequired ||
          journal == null ||
          (!cleanupReload &&
              journal.state !=
                  NarrativeEventSpatialLinkJournalState.eventCommitted) ||
          root == null ||
          current.isSaving ||
          ref.read(borderPreviewControllerProvider).hasPendingPreview ||
          (!cleanupReload && (current.isDirty || current.isProjectDirty))) {
        return;
      }
      if (cleanupReload) {
        final currentProject = current.project;
        if (currentProject == null ||
            current.projectRootPath == null ||
            p.normalize(current.projectRootPath!) != p.normalize(root)) {
          return;
        }
        ProjectMapEntry? mapEntry;
        for (final entry in currentProject.maps) {
          if (entry.id == journal.mapId) {
            mapEntry = entry;
            break;
          }
        }
        if (mapEntry == null) return;
        await notifier.loadMap(
          mapEntry.relativePath,
          forceReload: true,
        );
        final reloaded = ref.read(editorNotifierProvider);
        final reloadedMap = reloaded.activeMap;
        if (reloadedMap == null || reloadedMap.id != journal.mapId) return;
        controller.completeSourceCleanupReload(
          projectRootPath: reloaded.projectRootPath,
          activeMap: reloadedMap,
        );
        return;
      }
      final writeLease = notifier.beginNarrativeEventSourceMapWriteLease();
      if (writeLease == null) return;
      try {
        await notifier.loadProject(
          p.join(root, 'project.json'),
          rememberAsRecent: false,
          mapWriteLeaseToken: writeLease,
        );
        var reloaded = ref.read(editorNotifierProvider);
        final reloadedProject = reloaded.project;
        if (reloadedProject == null ||
            reloaded.projectRootPath == null ||
            p.normalize(reloaded.projectRootPath!) != p.normalize(root)) {
          return;
        }
        ProjectMapEntry? mapEntry;
        for (final entry in reloadedProject.maps) {
          if (entry.id == journal.mapId) {
            mapEntry = entry;
            break;
          }
        }
        if (mapEntry == null) return;
        await notifier.loadMap(
          mapEntry.relativePath,
          mapWriteLeaseToken: writeLease,
        );
        reloaded = ref.read(editorNotifierProvider);
        final reloadedMap = reloaded.activeMap;
        final projectAfterMapLoad = reloaded.project;
        if (reloadedMap == null ||
            reloadedMap.id != journal.mapId ||
            projectAfterMapLoad == null) {
          return;
        }
        await controller.retrySourceCreation(
          projectRootPath: reloaded.projectRootPath,
          project: projectAfterMapLoad,
          activeMap: reloadedMap,
          mapDirty: reloaded.isDirty,
          projectDirty: reloaded.isProjectDirty,
          saving: current.isSaving,
          adoptPersistedMap: (proposal) => adoptPersistedMap(
            proposal,
            mapWriteLeaseToken: writeLease,
          ),
          applyPersistedRegistry: applyPersistedRegistry,
        );
      } finally {
        notifier.endNarrativeEventSourceMapWriteLease(writeLease);
      }
    }

    return SizedBox(
      width: 480,
      child: PokeMapPanel(
        key: const ValueKey('narrative-event-map-banner'),
        padding: const EdgeInsets.all(12),
        header: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Icon(CupertinoIcons.scope, color: colors.narrative, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  eventName,
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
                label: switch (bridge.navigationMode) {
                  NarrativeEventMapNavigationMode.choose =>
                    'Choisir une source',
                  NarrativeEventMapNavigationMode.create => 'Créer une source',
                  _ => 'Voir la source',
                },
                variant: PokeMapBadgeVariant.narrative,
              ),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isCreate
                  ? bridge.sourceCreationKind == null
                      ? 'Choisissez un type physique. Le prochain clic sur la '
                          'map préparera uniquement un aperçu.'
                      : bridge.sourceCreationProposal == null
                          ? 'Cliquez sur la map pour prévisualiser la source. '
                              'Rien ne sera écrit avant confirmation.'
                          : 'Vérifiez l’aperçu puis confirmez la création et '
                              'la liaison à cet Event.'
                  : bridge.navigationMode ==
                          NarrativeEventMapNavigationMode.choose
                      ? 'Sélectionnez une entité ou une zone existante, ou utilisez '
                          'la map elle-même. Aucun élément physique n’est créé ici.'
                      : 'La source liée reste surlignée jusqu’au retour.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            if (isCreate) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final kind in NarrativeEventPhysicalSourceKind.values)
                    PokeMapButton(
                      key: ValueKey(
                        'narrative-event-create-kind-${kind.name}',
                      ),
                      onPressed: bridge.isSourceCreationBusy ||
                              hasBlockingSourceRecovery
                          ? null
                          : () => controller.selectPhysicalSourceKind(kind),
                      variant: bridge.sourceCreationKind == kind
                          ? PokeMapButtonVariant.primary
                          : PokeMapButtonVariant.secondary,
                      size: PokeMapButtonSize.small,
                      child: Text(_physicalKindLabel(kind)),
                    ),
                ],
              ),
              if (bridge.sourceCreationProposal != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: PokeMapButton(
                        key: const ValueKey(
                          'narrative-event-create-cancel-preview',
                        ),
                        onPressed: bridge.isSourceCreationBusy ||
                                hasBlockingSourceRecovery
                            ? null
                            : controller.cancelSourceCreationProposal,
                        variant: PokeMapButtonVariant.ghost,
                        size: PokeMapButtonSize.small,
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PokeMapButton(
                        key: const ValueKey(
                          'narrative-event-create-confirm',
                        ),
                        onPressed: editor.isSaving ||
                                bridge.isSourceCreationBusy ||
                                hasBlockingSourceRecovery ||
                                editor.isDirty ||
                                editor.isProjectDirty
                            ? null
                            : confirmCreatedSource,
                        isLoading: bridge.isSourceCreationBusy,
                        size: PokeMapButtonSize.small,
                        leading: const Icon(CupertinoIcons.check_mark),
                        child: const Text('Enregistrer et lier'),
                      ),
                    ),
                  ],
                ),
              ],
              if (bridge.lastSourceCreationResult != null) ...[
                const SizedBox(height: 8),
                Text(
                  bridge.lastSourceCreationResult!.message,
                  style: TextStyle(
                    color: bridge.lastSourceCreationResult!.status ==
                            NarrativeEventExplicitSourceCreationStatus.cleaned
                        ? colors.textSecondary
                        : colors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (bridge.lastSourceCreationResult?.status ==
                      NarrativeEventExplicitSourceCreationStatus
                          .recoveryRequired &&
                  !recoveryRequiresReload) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: PokeMapButton(
                        key: const ValueKey(
                          'narrative-event-create-retry',
                        ),
                        onPressed: bridge.isSourceCreationBusy
                            ? null
                            : retryCreatedSource,
                        variant: PokeMapButtonVariant.secondary,
                        size: PokeMapButtonSize.small,
                        child: const Text('Réessayer'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PokeMapButton(
                        key: const ValueKey(
                          'narrative-event-create-cleanup-request',
                        ),
                        onPressed: bridge.isSourceCreationBusy
                            ? null
                            : controller.requestSourceCleanupConfirmation,
                        variant: PokeMapButtonVariant.ghost,
                        size: PokeMapButtonSize.small,
                        child: const Text('Supprimer la source'),
                      ),
                    ),
                  ],
                ),
              ],
              if (recoveryRequiresReload) ...[
                const SizedBox(height: 8),
                PokeMapButton(
                  key: const ValueKey('narrative-event-create-reload'),
                  onPressed: reloadIsBlocked ? null : reloadCommittedSource,
                  size: PokeMapButtonSize.small,
                  leading: const Icon(CupertinoIcons.refresh),
                  child: Text(
                    cleanupRequiresReload
                        ? 'Recharger la map'
                        : 'Recharger le projet',
                  ),
                ),
              ],
              if (bridge.cleanupConfirmationRequested) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: PokeMapButton(
                        key: const ValueKey(
                          'narrative-event-create-cleanup-cancel',
                        ),
                        onPressed: bridge.isSourceCreationBusy
                            ? null
                            : controller.cancelSourceCleanupConfirmation,
                        variant: PokeMapButtonVariant.ghost,
                        size: PokeMapButtonSize.small,
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PokeMapButton(
                        key: const ValueKey(
                          'narrative-event-create-cleanup-confirm',
                        ),
                        onPressed: bridge.isSourceCreationBusy
                            ? null
                            : cleanupCreatedSource,
                        variant: PokeMapButtonVariant.danger,
                        size: PokeMapButtonSize.small,
                        child: const Text('Confirmer la suppression'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
            if (!isCreate && bridge.lastSourceCreationResult != null) ...[
              const SizedBox(height: 8),
              Text(
                bridge.lastSourceCreationResult!.message,
                style: TextStyle(
                  color: colors.error,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (!isCreate && recoveryRequiresReload) ...[
              const SizedBox(height: 8),
              PokeMapButton(
                key: const ValueKey('narrative-event-create-reload'),
                onPressed: reloadIsBlocked ? null : reloadCommittedSource,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.refresh),
                child: Text(
                  cleanupRequiresReload
                      ? 'Recharger la map'
                      : 'Recharger le projet',
                ),
              ),
            ],
            if (candidate != null) ...[
              const SizedBox(height: 8),
              PokeMapButton(
                key: const ValueKey('narrative-event-map-confirm-candidate'),
                onPressed: editor.isSaving ||
                        bridge.isLinkingSource ||
                        hasBlockingSourceRecovery
                    ? null
                    : confirmCandidate,
                isLoading: bridge.isLinkingSource,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.link),
                child: Text('Utiliser ${candidate.label}'),
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
            if (bridge.lastSourceLinkResult != null &&
                bridge.lastSourceLinkResult!.status !=
                    NarrativeEventSpatialSourceLinkStatus.committed &&
                bridge.lastSourceLinkResult!.status !=
                    NarrativeEventSpatialSourceLinkStatus.noOp) ...[
              const SizedBox(height: 8),
              Text(
                bridge.lastSourceLinkResult!.message,
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
                    key: const ValueKey('narrative-event-map-cancel'),
                    onPressed: bridge.isLinkingSource ||
                            bridge.isSourceCreationBusy ||
                            hasBlockingSourceRecovery
                        ? null
                        : () {
                            controller.cancelMapNavigation();
                            ref
                                .read(
                                  narrativeStudioNavigationControllerProvider
                                      .notifier,
                                )
                                .restoreReturn();
                            notifier.selectEventsWorkspace();
                          },
                    variant: PokeMapButtonVariant.ghost,
                    size: PokeMapButtonSize.small,
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PokeMapButton(
                    key: const ValueKey('narrative-event-map-return'),
                    onPressed: bridge.isLinkingSource ||
                            bridge.isSourceCreationBusy ||
                            hasBlockingSourceRecovery
                        ? null
                        : returnToExactEvent,
                    variant: PokeMapButtonVariant.secondary,
                    size: PokeMapButtonSize.small,
                    leading: const Icon(CupertinoIcons.chevron_left),
                    child: const Text('Retour à l’Event'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NarrativeMapReturnBanner extends ConsumerWidget {
  const _NarrativeMapReturnBanner({required this.expectation});

  final NarrativeStudioReturnExpectation expectation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.pokeMapColors;
    final label = switch (expectation.location.destination) {
      NarrativeStudioDestination.overview => 'l’aperçu',
      NarrativeStudioDestination.storylines => 'la Storyline',
      NarrativeStudioDestination.scenes => 'la Scene',
      NarrativeStudioDestination.events => 'l’Event Builder',
      NarrativeStudioDestination.cinematics => 'la cinématique',
      NarrativeStudioDestination.dialogues => 'le dialogue',
      NarrativeStudioDestination.facts => 'la Fact',
      NarrativeStudioDestination.shops => 'la boutique',
      NarrativeStudioDestination.worldRules => 'la règle du monde',
      NarrativeStudioDestination.validator => 'le diagnostic',
    };

    void restore() {
      final controller =
          ref.read(narrativeStudioNavigationControllerProvider.notifier);
      final restored = controller.restoreReturn();
      if (restored == null) return;
      final notifier = ref.read(editorNotifierProvider.notifier);
      switch (restored.location.childRoute) {
        case NarrativeStudioChildRoute.storylineStep:
          notifier.selectStepWorkspace();
        case NarrativeStudioChildRoute.overview:
          notifier.selectNarrativeOverviewWorkspace();
        case NarrativeStudioChildRoute.storylineLibrary:
          notifier.selectGlobalStoryWorkspace();
        case NarrativeStudioChildRoute.sceneBuilder:
          notifier.selectScenesWorkspace();
        case NarrativeStudioChildRoute.eventBuilder:
        case NarrativeStudioChildRoute.mapEvents:
          notifier.selectEventsWorkspace();
        case NarrativeStudioChildRoute.cinematicLibrary:
        case NarrativeStudioChildRoute.cinematicBuilder:
          notifier.selectCinematicsWorkspace();
        case NarrativeStudioChildRoute.dialogueEditor:
          notifier.selectDialogueWorkspace();
        case NarrativeStudioChildRoute.factsManager:
          notifier.selectFactsWorkspace();
        case NarrativeStudioChildRoute.shopBuilder:
          notifier.selectShopsWorkspace();
        case NarrativeStudioChildRoute.worldRulesManager:
          notifier.selectWorldRulesWorkspace();
        case NarrativeStudioChildRoute.validatorDiagnostics:
          notifier.selectNarrativeValidatorWorkspace();
      }
    }

    return SizedBox(
      width: 360,
      child: PokeMapPanel(
        key: const ValueKey('narrative-map-generic-return-banner'),
        padding: const EdgeInsets.all(12),
        header: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Icon(CupertinoIcons.link, color: colors.narrative, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Navigation narrative',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        child: PokeMapButton(
          key: const ValueKey('narrative-map-generic-return'),
          onPressed: restore,
          variant: PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.small,
          leading: const Icon(CupertinoIcons.chevron_left),
          child: Text('Retour à $label'),
        ),
      ),
    );
  }
}

final class _Candidate {
  const _Candidate(this.source, this.label);

  final NarrativeEventSourceRef source;
  final String label;
}

_Candidate _selectedCandidate(
  MapData map,
  String? selectedEntityId,
  String? selectedTriggerId,
) {
  if (selectedEntityId != null) {
    for (final entity in map.entities) {
      if (entity.id == selectedEntityId && entity.kind != MapEntityKind.spawn) {
        return _Candidate(
          NarrativeEventSourceRef.entityInteract(map.id, entity.id),
          'l’entité sélectionnée',
        );
      }
    }
  }
  if (selectedTriggerId != null) {
    for (final trigger in map.triggers) {
      if (trigger.id == selectedTriggerId &&
          (trigger.type == TriggerType.event ||
              trigger.type == TriggerType.custom)) {
        return _Candidate(
          NarrativeEventSourceRef.triggerEnter(map.id, trigger.id),
          'la zone sélectionnée',
        );
      }
    }
  }
  return _Candidate(
    NarrativeEventSourceRef.mapEnter(map.id),
    'cette map',
  );
}

NarrativeEventRecord? _recordById(
  NarrativeEventRegistry? registry,
  String eventId,
) {
  NarrativeEventRecord? match;
  for (final record in registry?.records ?? const <NarrativeEventRecord>[]) {
    if (record.id != eventId) continue;
    if (match != null) return null;
    match = record;
  }
  return match;
}

String _physicalKindLabel(NarrativeEventPhysicalSourceKind kind) {
  return switch (kind) {
    NarrativeEventPhysicalSourceKind.npc => 'PNJ',
    NarrativeEventPhysicalSourceKind.sign => 'Panneau',
    NarrativeEventPhysicalSourceKind.item => 'Objet',
    NarrativeEventPhysicalSourceKind.invisible => 'Invisible',
    NarrativeEventPhysicalSourceKind.zone1x1 => 'Zone 1×1',
  };
}
