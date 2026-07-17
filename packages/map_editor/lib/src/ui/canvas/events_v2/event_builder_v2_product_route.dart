import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../application/models/narrative_event_map_bridge_models.dart';
import '../../../application/models/narrative_event_authoring_session.dart';
import '../../../application/models/narrative_event_migration_persistence_models.dart';
import '../../../application/services/narrative_event_validation_coordinator.dart';
import '../../../application/use_cases/narrative_event_migration_preview_use_case.dart';
import '../../../application/use_cases/narrative_event_v2_mode_activation_use_case.dart';
import '../../../application/use_cases/narrative_event_builder_v2_use_case.dart';
import '../../../app/providers/core/repository_providers.dart';
import '../../../features/editor/state/editor_notifier.dart';
import '../../../features/editor/state/editor_state.dart';
import '../../../features/narrative/state/narrative_event_builder_v2_providers.dart';
import '../../../features/narrative/state/narrative_event_builder_v2_state.dart';
import '../../../features/narrative/state/narrative_event_map_bridge_state.dart';
import '../../../features/narrative/state/narrative_event_validation_state.dart';
import '../../../features/narrative/state/narrative_scene_focus_provider.dart';
import '../../design_system/design_system.dart';
import 'event_builder_v2_authoring_sheets.dart';
import 'event_builder_v2_element_library.dart';
import 'event_builder_v2_migration_sheet.dart';
import 'event_builder_v2_workspace.dart';

/// Production composition boundary for Event Builder V2.
///
/// This widget reads one complete, attested project snapshot and delegates all
/// Map navigation/selection to the Phase G bridge. It deliberately contains no
/// registry writer and no active-map-derived list fallback.
class EventBuilderV2ProductRoute extends ConsumerStatefulWidget {
  const EventBuilderV2ProductRoute({
    super.key,
    required this.viewportWidth,
    required this.availableWidth,
    this.legacyWorkspace,
  });

  /// Width of the complete desktop viewport, used for reference layout tiers.
  final double viewportWidth;

  /// Width left to the Event workspace after shell and Narrative chrome.
  final double availableWidth;
  final Widget? legacyWorkspace;

  @override
  ConsumerState<EventBuilderV2ProductRoute> createState() =>
      _EventBuilderV2ProductRouteState();
}

class _EventBuilderV2ProductRouteState
    extends ConsumerState<EventBuilderV2ProductRoute> {
  String _query = '';
  NarrativeEventBuilderV2Filter _filter = NarrativeEventBuilderV2Filter.all;
  String? _selectedCompatibilityStableKey;
  final _sourceLessMapContexts = <String, NarrativeEventGroupContext>{};
  String? _sourceLessContextProjectRoot;
  bool _isAuthoring = false;
  String? _authoringMessage;
  NarrativeEventBuilderV2WriteStatus? _authoringStatus;
  String? _pendingSelectionEventId;
  String? _validationNavigationMessage;
  bool _migrationBusy = false;
  String? _migrationMessage;

  @override
  Widget build(BuildContext context) {
    final editor = ref.watch(editorNotifierProvider);
    final project = editor.project;
    final projectRootPath = editor.projectRootPath?.trim();
    if (project == null) {
      return const PokeMapPageSurface(
        child: PokeMapEmptyState(
          title: 'Projet indisponible',
          description:
              'Ouvrez un projet enregistré pour charger ses événements.',
          icon: Icon(CupertinoIcons.folder),
        ),
      );
    }
    final mode = project.eventRegistry?.mode ?? EventSystemMode.legacyOnly;
    if (mode == EventSystemMode.legacyOnly &&
        (projectRootPath == null || projectRootPath.isEmpty)) {
      return widget.legacyWorkspace ??
          const PokeMapPageSurface(
            child: PokeMapEmptyState(
              title: 'Projet non enregistré',
              description: 'Enregistrez le projet pour préparer sa conversion '
                  'vers Event V2.',
              icon: Icon(CupertinoIcons.floppy_disk),
            ),
          );
    }
    if (projectRootPath == null || projectRootPath.isEmpty) {
      return const PokeMapPageSurface(
        child: PokeMapEmptyState(
          title: 'Projet indisponible',
          description:
              'Ouvrez un projet enregistré pour charger ses événements.',
          icon: Icon(CupertinoIcons.folder),
        ),
      );
    }
    if (_sourceLessContextProjectRoot != projectRootPath) {
      _sourceLessContextProjectRoot = projectRootPath;
      _sourceLessMapContexts.clear();
    }

    if (mode == EventSystemMode.legacyOnly) {
      return _buildLegacyMigrationLanding(
        projectRootPath: projectRootPath,
        editor: editor,
      );
    }
    if (widget.availableWidth < kEventBuilderV2MinimumViewportWidth) {
      return const EventBuilderV2NarrowViewportGate();
    }
    if (editor.isDirty) {
      return const PokeMapPageSurface(
        key: ValueKey('event-builder-v2-unsaved-map-gate'),
        child: Center(
          child: PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.warning,
            title: 'Map non enregistrée',
            message: 'Enregistrez la map active avant de charger les '
                'événements du projet. La vue Event ne réutilise jamais un '
                'snapshot disque devenu obsolète.',
          ),
        ),
      );
    }

    final request = NarrativeEventBuilderV2SnapshotRequest.fromProject(
      projectRootPath: projectRootPath,
      project: project,
    );
    final readModel = ref.watch(
      narrativeEventBuilderV2ReadModelProvider(request),
    );
    final validationSnapshot = ref.watch(
      narrativeEventValidationSnapshotProvider(request),
    );
    return readModel.when(
      loading: _buildLoading,
      error: (error, _) => _buildError(error, request),
      data: (value) => validationSnapshot.when(
        loading: _buildLoading,
        error: (error, _) => _buildValidationError(error, request),
        data: (validation) => _buildWorkspace(
          context,
          editor: editor,
          readModel: value,
          mode: mode,
          validationSnapshot: validation,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return PokeMapPageSurface(
      key: const ValueKey('event-builder-v2-product-loading'),
      child: Center(
        child: Semantics(
          label: 'Chargement des événements du projet',
          child: const CupertinoActivityIndicator(),
        ),
      ),
    );
  }

  Widget _buildError(
    Object error,
    NarrativeEventBuilderV2SnapshotRequest request,
  ) {
    final mismatch = error is NarrativeEventBuilderV2SnapshotMismatch;
    return PokeMapPageSurface(
      key: const ValueKey('event-builder-v2-product-error'),
      child: Center(
        child: PokeMapDiagnosticCallout(
          severity: PokeMapDiagnosticSeverity.error,
          title: mismatch
              ? 'Projet modifié pendant le chargement'
              : 'Événements indisponibles',
          message: mismatch
              ? 'Enregistrez ou rechargez le projet avant de continuer.'
              : 'Le projet ne peut pas préparer une vue Event V2 sûre. '
                  'Aucun éditeur historique n’a été ouvert à la place.',
          actionLabel: 'Réessayer',
          onAction: () => ref.invalidate(
            narrativeEventBuilderV2ReadModelProvider(request),
          ),
        ),
      ),
    );
  }

  Widget _buildValidationError(
    Object error,
    NarrativeEventBuilderV2SnapshotRequest request,
  ) {
    final mismatch = error is NarrativeEventBuilderV2SnapshotMismatch;
    return PokeMapPageSurface(
      key: const ValueKey('event-builder-v2-validation-error'),
      child: Center(
        child: PokeMapDiagnosticCallout(
          severity: PokeMapDiagnosticSeverity.error,
          title: mismatch
              ? 'Projet modifié pendant la validation'
              : 'Validation des événements indisponible',
          message: mismatch
              ? 'Enregistrez ou rechargez le projet avant de continuer.'
              : 'Les diagnostics ne peuvent pas être garantis. L’éditeur '
                  'reste fermé pour éviter de masquer un Event invalide.',
          actionLabel: 'Réessayer',
          onAction: () => ref.invalidate(
            narrativeEventValidationSnapshotProvider(request),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkspace(
    BuildContext context, {
    required EditorState editor,
    required NarrativeEventBuilderProjectReadModel readModel,
    required EventSystemMode mode,
    required NarrativeEventValidationSnapshot? validationSnapshot,
  }) {
    final bridge = ref.watch(narrativeEventMapBridgeControllerProvider);
    final state = NarrativeEventBuilderV2State(
      readModel: readModel,
      query: _query,
      filter: _filter,
      selectedCompatibilityStableKey: _selectedCompatibilityStableKey,
    );
    final selected = selectedNarrativeEventBuilderV2Event(
      state: state,
      bridgeState: bridge,
    );
    final canMutateSelected = !state.isReadOnly && selected?.readOnly == false;
    final validationItems = validationSnapshot?.state.forEvent(
          selected?.eventId,
        ) ??
        const <NarrativeEventValidationItem>[];
    final pendingEventId = _pendingSelectionEventId;
    if (pendingEventId != null) {
      final pending = readModel.eventByStableKey('v2:$pendingEventId');
      if (pending != null) {
        _pendingSelectionEventId = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _selectEvent(pending);
        });
      }
    }

    final workspace = EventBuilderV2Workspace(
      state: state,
      mode: mode,
      selectedStableKey: selected?.stableKey,
      viewportWidth: widget.viewportWidth,
      onQueryChanged: (value) => setState(() => _query = value),
      onFilterChanged: (value) => setState(() => _filter = value),
      onSelectEvent: _selectEvent,
      onCreateEvent:
          state.isReadOnly || _isAuthoring ? null : _openCreationSheet,
      onOpenLibrary: () => _openLibrary(context, selected),
      onChangeSource: canMutateSelected && !_isAuthoring
          ? () => selected!.source.source == null &&
                  bridge.selectedNarrativeEventV2Id == selected.eventId &&
                  bridge.selectedGroupContext?.kind ==
                      NarrativeEventGroupContextKind.map
              ? _openMapForMissingSource(selected)
              : _openSourceSheet(selected)
          : null,
      onSeeOnMap: _canSeeOnMap(selected)
          ? () => _openMapForEvent(
                selected!,
                NarrativeEventMapNavigationMode.view,
              )
          : null,
      onAddCondition: canMutateSelected && !_isAuthoring
          ? () => _openConditionsSheet(selected!)
          : null,
      onChangeScene: canMutateSelected && !_isAuthoring
          ? () => _openSceneSheet(selected!)
          : null,
      onOpenScene: selected?.scene.sceneId == null
          ? null
          : () => _openSceneById(selected!.scene.sceneId!),
      onChangeBehavior: canMutateSelected && !_isAuthoring
          ? () => _openBehaviorSheet(selected!)
          : null,
      onManageEvaluationOrder: canMutateSelected && !_isAuthoring
          ? () => _openBehaviorSheet(selected!)
          : null,
      validationItems: validationItems,
      onValidationAction: validationSnapshot == null
          ? null
          : (item) => _navigateFromValidation(
                item,
                readModel: readModel,
              ),
    );
    final navigationFailure = bridge.lastNavigationResult;
    final notices = <Widget>[];
    for (final item in validationSnapshot?.state.global ??
        const <NarrativeEventValidationItem>[]) {
      notices.add(
        PokeMapDiagnosticCallout(
          key: ValueKey(
            'event-builder-v2-global-diagnostic-'
            '${item.diagnostic.stableKey}',
          ),
          severity: _validationDiagnosticSeverity(item.diagnostic.severity),
          title: 'Diagnostic du registre Event',
          message: item.diagnostic.message,
          actionLabel: item.actionable ? 'Examiner' : null,
          onAction: item.actionable
              ? () => _navigateFromValidation(
                    item,
                    readModel: readModel,
                  )
              : null,
        ),
      );
    }
    if (_isAuthoring) {
      notices.add(
        const PokeMapDiagnosticCallout(
          key: ValueKey('event-builder-v2-saving'),
          severity: PokeMapDiagnosticSeverity.info,
          title: 'Enregistrement en cours',
          message: 'Le registre Event V2 est mis à jour en toute sécurité.',
          semanticLabel: 'Enregistrement de l’événement en cours',
        ),
      );
    } else if (_authoringMessage != null) {
      notices.add(
        PokeMapDiagnosticCallout(
          key: const ValueKey('event-builder-v2-authoring-feedback'),
          severity: _feedbackSeverity(_authoringStatus),
          title: _feedbackTitle(_authoringStatus),
          message: _authoringMessage!,
          actionLabel:
              _authoringStatus == NarrativeEventBuilderV2WriteStatus.conflict ||
                      _authoringStatus ==
                          NarrativeEventBuilderV2WriteStatus.recoveryRequired
                  ? 'Recharger les événements'
                  : null,
          onAction:
              _authoringStatus == NarrativeEventBuilderV2WriteStatus.conflict ||
                      _authoringStatus ==
                          NarrativeEventBuilderV2WriteStatus.recoveryRequired
                  ? () => ref.invalidate(
                        narrativeEventBuilderV2ReadModelProvider(
                          NarrativeEventBuilderV2SnapshotRequest.fromProject(
                            projectRootPath: editor.projectRootPath!,
                            project: editor.project!,
                          ),
                        ),
                      )
                  : null,
        ),
      );
    }
    if (navigationFailure != null && !navigationFailure.succeeded) {
      notices.add(
        PokeMapDiagnosticCallout(
          key: const ValueKey('event-builder-v2-navigation-error'),
          severity: PokeMapDiagnosticSeverity.warning,
          title: 'Navigation vers la map impossible',
          message: navigationFailure.message,
        ),
      );
    }
    if (_validationNavigationMessage != null) {
      notices.add(
        PokeMapDiagnosticCallout(
          key: const ValueKey('event-builder-v2-validation-navigation'),
          severity: PokeMapDiagnosticSeverity.warning,
          title: 'Destination devenue indisponible',
          message: _validationNavigationMessage!,
        ),
      );
    }
    if (mode == EventSystemMode.dualRead &&
        readModel.events.any(
          (event) => event.origin != NarrativeEventProjectOrigin.v2,
        )) {
      notices.add(
        PokeMapDiagnosticCallout(
          key: const ValueKey('event-builder-v2-migration-available'),
          severity: PokeMapDiagnosticSeverity.info,
          title: 'Événements historiques détectés',
          message: 'Prévisualisez leur conversion sans modifier les maps.',
          actionLabel: 'Prévisualiser',
          onAction: _migrationBusy
              ? null
              : () => _openMigrationSheet(editor.projectRootPath!),
        ),
      );
    }
    if (notices.isEmpty) return workspace;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final notice in notices)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: notice,
          ),
        Expanded(child: workspace),
      ],
    );
  }

  Widget _buildLegacyMigrationLanding({
    required String projectRootPath,
    required EditorState editor,
  }) {
    final blocked = editor.isDirty || editor.isProjectDirty || editor.isSaving;
    final legacyWorkspace = widget.legacyWorkspace;
    if (legacyWorkspace != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: PokeMapDiagnosticCallout(
              key: const ValueKey('event-builder-v2-legacy-migration-entry'),
              severity: blocked
                  ? PokeMapDiagnosticSeverity.warning
                  : PokeMapDiagnosticSeverity.info,
              title: blocked
                  ? 'Enregistrez le projet avant la conversion'
                  : 'Conversion Event V2 disponible',
              message: blocked
                  ? 'La prévisualisation exige un projet et des maps '
                      'enregistrés pour garantir les hashes.'
                  : 'Prévisualisez une conversion vérifiable. Le mode de jeu '
                      'restera inchangé tant que vous ne l’activez pas.',
              actionLabel: blocked || _migrationBusy
                  ? null
                  : 'Prévisualiser la conversion',
              onAction: blocked || _migrationBusy
                  ? null
                  : () => _openMigrationSheet(projectRootPath),
            ),
          ),
          if (_migrationMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: PokeMapDiagnosticCallout(
                key: const ValueKey('event-builder-v2-migration-feedback'),
                severity: PokeMapDiagnosticSeverity.warning,
                title: 'État de la conversion',
                message: _migrationMessage!,
              ),
            ),
          Expanded(child: legacyWorkspace),
        ],
      );
    }
    return PokeMapPageSurface(
      key: const ValueKey('event-builder-v2-legacy-migration-landing'),
      child: Center(
        child: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PokeMapDiagnosticCallout(
                severity: blocked
                    ? PokeMapDiagnosticSeverity.warning
                    : PokeMapDiagnosticSeverity.info,
                title: blocked
                    ? 'Enregistrez le projet avant la conversion'
                    : 'Projet en mode historique',
                message: blocked
                    ? 'La prévisualisation exige un projet et des maps '
                        'enregistrés pour garantir les hashes.'
                    : 'Préparez une conversion vérifiable vers Event V2. '
                        'Le mode de jeu ne sera pas changé automatiquement.',
              ),
              if (_migrationMessage != null) ...[
                const SizedBox(height: 10),
                PokeMapDiagnosticCallout(
                  key: const ValueKey('event-builder-v2-migration-feedback'),
                  severity: PokeMapDiagnosticSeverity.warning,
                  title: 'État de la conversion',
                  message: _migrationMessage!,
                ),
              ],
              const SizedBox(height: 12),
              PokeMapButton(
                key: const ValueKey('event-builder-v2-open-migration'),
                onPressed: blocked || _migrationBusy
                    ? null
                    : () => _openMigrationSheet(projectRootPath),
                variant: PokeMapButtonVariant.primary,
                leading: _migrationBusy
                    ? const CupertinoActivityIndicator()
                    : const Icon(CupertinoIcons.arrow_2_circlepath),
                child: Text(
                  _migrationBusy
                      ? 'Préparation…'
                      : 'Prévisualiser la conversion',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openMigrationSheet(String projectRootPath) async {
    if (_migrationBusy) return;
    setState(() {
      _migrationBusy = true;
      _migrationMessage = null;
    });
    final projectPath = p.join(projectRootPath, 'project.json');
    final gateway = ref.read(
      narrativeEventMigrationPersistenceGatewayProvider,
    );
    try {
      final inspection = await gateway.inspect(projectPath);
      if (inspection.status ==
          NarrativeEventMigrationInspectionStatus.blocked) {
        if (mounted) {
          setState(() {
            _migrationBusy = false;
            _migrationMessage = inspection.message;
          });
        }
        return;
      }
      if (inspection.status ==
          NarrativeEventMigrationInspectionStatus.recoveryRequired) {
        final result = await gateway.recover(projectPath);
        var message = result.message;
        if (result.succeeded && result.code == 'preparedMigrationFinalized') {
          final session = await NarrativeEventAuthoringSession.prepare(
            projectPath,
          );
          final recoveredRegistry = session.manifest.eventRegistry;
          final currentRegistry =
              ref.read(editorNotifierProvider).project?.eventRegistry;
          final adopted = recoveredRegistry != null &&
              ref
                  .read(editorNotifierProvider.notifier)
                  .applyPersistedNarrativeEventRegistry(
                    expectedProjectRootPath: projectRootPath,
                    expectedPreviousRegistry: currentRegistry,
                    nextRegistry: recoveredRegistry,
                  );
          if (!adopted) {
            message = 'La migration récupérée est sur disque; rechargez le '
                'projet avant de continuer.';
          }
        }
        if (mounted) {
          setState(() {
            _migrationBusy = false;
            _migrationMessage = message;
          });
        }
        return;
      }
      if (inspection.status ==
          NarrativeEventMigrationInspectionStatus.committed) {
        if (mounted) {
          setState(() {
            _migrationBusy = false;
            _migrationMessage = inspection.message;
          });
        }
        return;
      }
      final preview = await NarrativeEventMigrationPreviewUseCase().preview(
        projectPath,
      );
      if (!mounted) return;
      setState(() => _migrationBusy = false);
      await showPokeMapDesktopSideSheet<void>(
        context: context,
        title: 'Conversion Event V2',
        semanticLabel: 'Prévisualiser la conversion des événements',
        barrierLabel: 'Fermer la prévisualisation de conversion',
        width: 520,
        builder: (sheetContext) => EventBuilderV2MigrationSheet(
          preview: preview,
          onCancel: () => Navigator.of(sheetContext).pop(),
          onRecover: null,
          onActivateV2: () async {
            final result = await NarrativeEventV2ModeActivationUseCase(
              gateway: gateway,
            ).activate(projectPath);
            if (!mounted) return result;
            if (result.succeeded) {
              final session = await NarrativeEventAuthoringSession.prepare(
                projectPath,
              );
              final nextRegistry = session.manifest.eventRegistry;
              final currentRegistry =
                  ref.read(editorNotifierProvider).project?.eventRegistry;
              final adopted = nextRegistry != null &&
                  ref
                      .read(editorNotifierProvider.notifier)
                      .applyPersistedNarrativeEventRegistry(
                        expectedProjectRootPath: projectRootPath,
                        expectedPreviousRegistry: currentRegistry,
                        nextRegistry: nextRegistry,
                      );
              setState(() {
                _migrationMessage = adopted
                    ? result.message
                    : 'Event V2 est actif sur disque; rechargez le projet.';
              });
            } else {
              setState(() => _migrationMessage = result.message);
            }
            return result;
          },
          onCommit: () async {
            final result = await gateway.commit(
              NarrativeEventMigrationCommitRequest(preview: preview),
            );
            if (!mounted) return result;
            if (result.succeeded) {
              final adopted = ref
                  .read(editorNotifierProvider.notifier)
                  .applyPersistedNarrativeEventRegistry(
                    expectedProjectRootPath: projectRootPath,
                    expectedPreviousRegistry: preview.project.eventRegistry,
                    nextRegistry: preview.registryAfter,
                  );
              setState(() {
                _migrationMessage = adopted
                    ? result.message
                    : 'La migration est sur disque; rechargez le projet.';
              });
            } else {
              setState(() => _migrationMessage = result.message);
            }
            return result;
          },
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _migrationBusy = false;
        _migrationMessage =
            'La prévisualisation ne peut pas être préparée: $error';
      });
    }
  }

  void _openSceneById(String sceneId) {
    ref.read(narrativeSceneFocusProvider.notifier).focus(sceneId);
    ref.read(editorNotifierProvider.notifier).selectScenesWorkspace();
  }

  Future<void> _navigateFromValidation(
    NarrativeEventValidationItem item, {
    required NarrativeEventBuilderProjectReadModel readModel,
  }) async {
    final editor = ref.read(editorNotifierProvider);
    final project = editor.project;
    final projectRootPath = editor.projectRootPath?.trim();
    if (project == null || projectRootPath == null || projectRootPath.isEmpty) {
      if (mounted) {
        setState(() {
          _validationNavigationMessage =
              'Le projet courant n’est plus disponible pour revalider ce lien.';
        });
      }
      return;
    }
    NarrativeEventValidationSnapshot currentSnapshot;
    try {
      currentSnapshot = await ref.read(
        narrativeEventValidationSnapshotLoaderProvider,
      )(
        NarrativeEventBuilderV2SnapshotRequest.fromProject(
          projectRootPath: projectRootPath,
          project: project,
        ),
      );
    } on Object {
      if (mounted) {
        setState(() {
          _validationNavigationMessage =
              'La destination ne peut pas être revalidée dans le projet courant.';
        });
      }
      return;
    }
    final result = const NarrativeEventValidationCoordinator().resolve(
      diagnostic: item.diagnostic,
      registry: currentSnapshot.registry,
      catalog: currentSnapshot.catalog,
    );
    if (result.status != NarrativeEventValidationNavigationStatus.ready) {
      if (mounted) {
        setState(() => _validationNavigationMessage = result.message);
      }
      return;
    }
    final command = result.command!;
    final event = command.eventId == null
        ? null
        : readModel.eventByStableKey('v2:${command.eventId}');
    if (command.eventId != null && event == null) {
      if (mounted) {
        setState(() {
          _validationNavigationMessage =
              'L’événement ciblé n’existe plus dans la vue courante.';
        });
      }
      return;
    }
    if (event != null) _selectEvent(event);
    if (!mounted) return;
    setState(() => _validationNavigationMessage = null);
    switch (command.kind) {
      case NarrativeEventValidationNavigationKind.selectEvent:
        if (event == null) return;
        switch (command.section) {
          case NarrativeEventValidationSection.source:
            await _openSourceSheet(event);
            return;
          case NarrativeEventValidationSection.scene:
            await _openSceneSheet(event);
            return;
          case NarrativeEventValidationSection.overview:
          case NarrativeEventValidationSection.claim:
            return;
        }
      case NarrativeEventValidationNavigationKind.reviewClaim:
      case NarrativeEventValidationNavigationKind.reviewRegistry:
        await _openMigrationSheet(projectRootPath);
        return;
      case NarrativeEventValidationNavigationKind.openScene:
        _openSceneById(command.sceneId!);
        return;
      case NarrativeEventValidationNavigationKind.openMapSource:
        if (event == null || !_canSeeOnMap(event)) {
          setState(() {
            _validationNavigationMessage =
                'L’élément de map ciblé n’est plus ouvrable.';
          });
          return;
        }
        await _openMapForEvent(event, NarrativeEventMapNavigationMode.view);
        return;
    }
  }

  void _selectEvent(NarrativeEventProjectSummary event) {
    if (event.readOnly || event.eventId == null) {
      setState(() => _selectedCompatibilityStableKey = event.stableKey);
      return;
    }

    final editor = ref.read(editorNotifierProvider);
    final project = editor.project;
    if (project == null) return;
    final bridge = ref.read(narrativeEventMapBridgeControllerProvider);
    final previousEventId = bridge.selectedNarrativeEventV2Id;
    final previousGroup = bridge.selectedGroupContext;
    if (previousEventId != null &&
        previousGroup?.kind == NarrativeEventGroupContextKind.map) {
      _sourceLessMapContexts[previousEventId] = previousGroup!;
    }
    var groupContext = narrativeEventGroupContextForSummary(event);
    // A source-less draft created from Map Editor carries its intended map in
    // the bridge. Preserve that atomic context instead of inventing a picker.
    if (event.source.source == null &&
        bridge.selectedNarrativeEventV2Id == event.eventId &&
        bridge.selectedGroupContext != null) {
      groupContext = bridge.selectedGroupContext!;
    } else if (event.source.source == null) {
      groupContext = _sourceLessMapContexts[event.eventId] ?? groupContext;
    }
    final selected = ref
        .read(narrativeEventMapBridgeControllerProvider.notifier)
        .selectNarrativeEventV2(
          project,
          event.eventId!,
          groupContext: groupContext,
        );
    if (selected) {
      if (event.source.source == null &&
          groupContext.kind == NarrativeEventGroupContextKind.map) {
        _sourceLessMapContexts[event.eventId!] = groupContext;
      }
      setState(() => _selectedCompatibilityStableKey = null);
    }
  }

  bool _canSeeOnMap(NarrativeEventProjectSummary? event) {
    final source = event?.source.source;
    return event?.eventId != null &&
        event?.source.available == true &&
        source != null &&
        source.kind != NarrativeEventSourceKind.outcomeReceived;
  }

  Future<void> _openMapForEvent(
    NarrativeEventProjectSummary event,
    NarrativeEventMapNavigationMode mode,
  ) async {
    final eventId = event.eventId;
    final project = ref.read(editorNotifierProvider).project;
    if (eventId == null || project == null || !_canSeeOnMap(event)) return;
    final editor = ref.read(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final controller = ref.read(
      narrativeEventMapBridgeControllerProvider.notifier,
    );
    final result = await controller.openMapForEvent(
      eventId: eventId,
      groupContext: narrativeEventGroupContextForSummary(event),
      mode: mode,
      project: project,
      activeMap: editor.activeMap,
      mapDirty: editor.isDirty,
      loadMapSnapshot: notifier.loadMapSnapshotById,
      activateMapSnapshot: notifier.activateNarrativeEventMapSnapshot,
      applyFocus: notifier.focusNarrativeEventMapSource,
    );
    if (!result.succeeded || !mounted) return;
    await _inspectPendingSourceCreation(controller);
    if (mounted) notifier.selectMapWorkspace();
  }

  /// Opens Map Editor only for the explicit "create a physical source" path.
  /// Existing PNJs/zones/maps are otherwise selected directly in Event Builder.
  Future<void> _openMapForMissingSource(
    NarrativeEventProjectSummary event,
  ) async {
    final eventId = event.eventId;
    final editor = ref.read(editorNotifierProvider);
    final project = editor.project;
    final groupContext = ref
        .read(narrativeEventMapBridgeControllerProvider)
        .selectedGroupContext;
    if (eventId == null ||
        project == null ||
        groupContext?.kind != NarrativeEventGroupContextKind.map) {
      return;
    }
    final notifier = ref.read(editorNotifierProvider.notifier);
    final controller = ref.read(
      narrativeEventMapBridgeControllerProvider.notifier,
    );
    final result = await controller.openMapForMissingSource(
      eventId: eventId,
      groupContext: groupContext!,
      project: project,
      activeMap: editor.activeMap,
      mapDirty: editor.isDirty,
      loadMapSnapshot: notifier.loadMapSnapshotById,
      activateMapSnapshot: notifier.activateNarrativeEventMapSnapshot,
    );
    if (!result.succeeded || !mounted) return;
    await _inspectPendingSourceCreation(controller);
    if (mounted) notifier.selectMapWorkspace();
  }

  Future<void> _inspectPendingSourceCreation(
    NarrativeEventMapBridgeController controller,
  ) async {
    final editor = ref.read(editorNotifierProvider);
    await controller.inspectPendingSourceCreation(
      projectRootPath: editor.projectRootPath,
      mapDirty: editor.isDirty,
      projectDirty: editor.isProjectDirty,
      saving: editor.isSaving,
    );
  }

  NarrativeEventBuilderV2UseCase _authoringUseCase() {
    return NarrativeEventBuilderV2UseCase(
      persistenceGateway: ref.read(
        narrativeEventRegistryPersistenceGatewayProvider,
      ),
    );
  }

  String? _projectFilePath() {
    final root = ref.read(editorNotifierProvider).projectRootPath?.trim();
    if (root == null || root.isEmpty) return null;
    return p.join(root, 'project.json');
  }

  NarrativeEventBuilderV2WriteEnvironment _writeEnvironment(
    EditorState editor,
  ) {
    return NarrativeEventBuilderV2WriteEnvironment(
      mapDirty: editor.isDirty,
      projectDirty: editor.isProjectDirty,
      saving: editor.isSaving,
    );
  }

  Future<NarrativeEventBuilderV2EditorSnapshot?> _loadAuthoringSnapshot({
    String? eventId,
  }) async {
    final projectPath = _projectFilePath();
    if (projectPath == null) return null;
    setState(() {
      _isAuthoring = true;
      _authoringMessage = null;
      _authoringStatus = null;
    });
    try {
      final snapshot = await _authoringUseCase().loadEditorSnapshot(
        projectPath: projectPath,
        eventId: eventId,
      );
      if (mounted) setState(() => _isAuthoring = false);
      return snapshot;
    } on Object {
      if (mounted) {
        setState(() {
          _isAuthoring = false;
          _authoringStatus = NarrativeEventBuilderV2WriteStatus.failed;
          _authoringMessage =
              'Les données d’édition ne peuvent pas être préparées.';
        });
      }
      return null;
    }
  }

  Future<void> _openCreationSheet() async {
    final snapshot = await _loadAuthoringSnapshot();
    if (!mounted || snapshot == null) return;
    await showPokeMapDesktopSideSheet<void>(
      context: context,
      title: 'Nouvel événement',
      semanticLabel: 'Créer un événement V2',
      barrierLabel: 'Annuler la création de l’événement',
      width: 460,
      builder: (_) => EventBuilderV2CreationSheet(
        snapshot: snapshot,
        onSubmit: _createEvent,
      ),
    );
  }

  Future<String?> _createEvent(
    NarrativeEventBuilderV2CreationRequest request,
  ) async {
    final projectPath = _projectFilePath();
    if (projectPath == null) return 'Le projet enregistré est indisponible.';
    final editor = ref.read(editorNotifierProvider);
    setState(() {
      _isAuthoring = true;
      _authoringMessage = null;
      _authoringStatus = null;
    });
    final result = await _authoringUseCase().create(
      projectPath: projectPath,
      request: request,
      environment: _writeEnvironment(editor),
    );
    var adopted = true;
    final finalRegistry = result.finalRegistry;
    if (finalRegistry != null) {
      adopted = ref
          .read(editorNotifierProvider.notifier)
          .applyPersistedNarrativeEventRegistry(
            expectedProjectRootPath: editor.projectRootPath!,
            expectedPreviousRegistry: result.initialRegistry,
            nextRegistry: finalRegistry,
          );
    }
    if (!mounted) return result.message;
    if (result.succeeded && adopted) {
      setState(() {
        _isAuthoring = false;
        _authoringStatus = NarrativeEventBuilderV2WriteStatus.committed;
        _authoringMessage = request.publish
            ? 'L’événement est publié, désactivé et prêt à être relu.'
            : 'Le brouillon est enregistré et peut être repris plus tard.';
        _pendingSelectionEventId = result.eventId;
      });
      return null;
    }
    final status = !adopted
        ? NarrativeEventBuilderV2WriteStatus.recoveryRequired
        : result.status;
    final message = !adopted
        ? 'L’événement est enregistré sur disque, mais la vue doit être '
            'rechargée avant de continuer.'
        : result.message;
    setState(() {
      _isAuthoring = false;
      _authoringStatus = status;
      _authoringMessage = message;
      if (result.hasDurableDraft) _pendingSelectionEventId = result.eventId;
    });
    return message;
  }

  Future<String?> _runWrite(
    Future<NarrativeEventBuilderV2WriteResult> Function(
      NarrativeEventBuilderV2UseCase useCase,
      String projectPath,
      NarrativeEventBuilderV2WriteEnvironment environment,
    ) action,
  ) async {
    final projectPath = _projectFilePath();
    if (projectPath == null) return 'Le projet enregistré est indisponible.';
    final editor = ref.read(editorNotifierProvider);
    setState(() {
      _isAuthoring = true;
      _authoringMessage = null;
      _authoringStatus = null;
    });
    final result = await action(
      _authoringUseCase(),
      projectPath,
      _writeEnvironment(editor),
    );
    var adopted = true;
    final authoring = result.authoringResult;
    final nextRegistry = authoring?.nextRegistry;
    if (result.succeeded && nextRegistry != null) {
      adopted = ref
          .read(editorNotifierProvider.notifier)
          .applyPersistedNarrativeEventRegistry(
            expectedProjectRootPath: editor.projectRootPath!,
            expectedPreviousRegistry: authoring?.previousRegistry,
            nextRegistry: nextRegistry,
          );
    }
    if (!mounted) return result.message;
    if (result.succeeded && adopted) {
      setState(() {
        _isAuthoring = false;
        _authoringStatus = result.status;
        _authoringMessage =
            result.status == NarrativeEventBuilderV2WriteStatus.noOp
                ? 'Aucune modification n’était nécessaire.'
                : 'La modification est enregistrée.';
        _pendingSelectionEventId = result.eventId;
      });
      return null;
    }
    final status = !adopted
        ? NarrativeEventBuilderV2WriteStatus.recoveryRequired
        : result.status;
    final message = !adopted
        ? 'La modification est sur disque, mais la vue doit être rechargée.'
        : result.message;
    setState(() {
      _isAuthoring = false;
      _authoringStatus = status;
      _authoringMessage = message;
    });
    return message;
  }

  Future<void> _openSourceSheet(
    NarrativeEventProjectSummary event,
  ) async {
    final eventId = event.eventId;
    if (eventId == null) return;
    final snapshot = await _loadAuthoringSnapshot(eventId: eventId);
    if (!mounted || snapshot == null) return;
    await showPokeMapDesktopSideSheet<void>(
      context: context,
      title: 'Choisir le déclencheur',
      semanticLabel: 'Choisir un élément existant du projet',
      width: 460,
      builder: (_) => EventBuilderV2SourceSheet(
        snapshot: snapshot,
        currentSource: snapshot.record?.draftOrNull?.source ??
            snapshot.record?.definitionOrNull?.source,
        onSubmit: (source) => _runWrite(
          (useCase, path, environment) => useCase.setSource(
            projectPath: path,
            eventId: eventId,
            source: source,
            environment: environment,
          ),
        ),
      ),
    );
  }

  Future<void> _openConditionsSheet(
    NarrativeEventProjectSummary event,
  ) async {
    final eventId = event.eventId;
    if (eventId == null) return;
    final snapshot = await _loadAuthoringSnapshot(eventId: eventId);
    if (!mounted || snapshot == null) return;
    await showPokeMapDesktopSideSheet<void>(
      context: context,
      title: 'Conditions de l’événement',
      semanticLabel: 'Modifier les conditions ordonnées',
      width: 480,
      builder: (_) => EventBuilderV2ConditionsSheet(
        snapshot: snapshot,
        onSubmit: (conditions) => _runWrite(
          (useCase, path, environment) => useCase.setConditions(
            projectPath: path,
            eventId: eventId,
            conditions: conditions,
            environment: environment,
          ),
        ),
      ),
    );
  }

  Future<void> _openSceneSheet(
    NarrativeEventProjectSummary event,
  ) async {
    final eventId = event.eventId;
    if (eventId == null) return;
    final snapshot = await _loadAuthoringSnapshot(eventId: eventId);
    if (!mounted || snapshot == null) return;
    final record = snapshot.record;
    await showPokeMapDesktopSideSheet<void>(
      context: context,
      title: 'Scene à jouer',
      semanticLabel: 'Choisir la Scene de l’événement',
      width: 440,
      builder: (_) => EventBuilderV2SceneSheet(
        snapshot: snapshot,
        currentSceneId:
            record?.draftOrNull?.sceneId ?? record?.definitionOrNull?.sceneId,
        onSubmit: (sceneId) => _runWrite(
          (useCase, path, environment) => sceneId == null
              ? useCase.removeScene(
                  projectPath: path,
                  eventId: eventId,
                  environment: environment,
                )
              : useCase.setScene(
                  projectPath: path,
                  eventId: eventId,
                  sceneId: sceneId,
                  environment: environment,
                ),
        ),
      ),
    );
  }

  Future<void> _openBehaviorSheet(
    NarrativeEventProjectSummary event,
  ) async {
    final eventId = event.eventId;
    if (eventId == null) return;
    final snapshot = await _loadAuthoringSnapshot(eventId: eventId);
    final record = snapshot?.record;
    if (!mounted || snapshot == null || record == null) return;
    await showPokeMapDesktopSideSheet<void>(
      context: context,
      title: 'Comportement de l’événement',
      semanticLabel: 'Modifier le comportement et l’activation',
      width: 460,
      builder: (_) => EventBuilderV2BehaviorSheet(
        record: record,
        onSave: (update) => _saveBehavior(eventId, update),
        onPublish: () => _runWrite(
          (useCase, path, environment) => useCase.publish(
            projectPath: path,
            eventId: eventId,
            environment: environment,
          ),
        ),
        onSetEnabled: (enabled) => _runWrite(
          (useCase, path, environment) => useCase.setEnabled(
            projectPath: path,
            eventId: eventId,
            enabled: enabled,
            environment: environment,
          ),
        ),
      ),
    );
  }

  Future<String?> _saveBehavior(
    String eventId,
    EventBuilderV2BehaviorUpdate update,
  ) async {
    final actions = <Future<String?> Function()>[
      () => _runWrite(
            (useCase, path, environment) => useCase.rename(
              projectPath: path,
              eventId: eventId,
              name: update.name,
              environment: environment,
            ),
          ),
      if (update.reusePolicy != null)
        () => _runWrite(
              (useCase, path, environment) => useCase.setReusePolicy(
                projectPath: path,
                eventId: eventId,
                reusePolicy: update.reusePolicy!,
                environment: environment,
              ),
            ),
      () => _runWrite(
            (useCase, path, environment) => useCase.setPriority(
              projectPath: path,
              eventId: eventId,
              priority: update.priority,
              environment: environment,
            ),
          ),
      () => _runWrite(
            (useCase, path, environment) => useCase.setOrder(
              projectPath: path,
              eventId: eventId,
              order: update.order,
              environment: environment,
            ),
          ),
    ];
    for (final action in actions) {
      final error = await action();
      if (error != null) return error;
    }
    return null;
  }

  Future<void> _openLibrary(
    BuildContext context,
    NarrativeEventProjectSummary? selected,
  ) {
    return showPokeMapDesktopSideSheet<void>(
      context: context,
      title: 'Bibliothèque d’éléments',
      semanticLabel: 'Bibliothèque d’éléments de l’événement',
      barrierLabel: 'Fermer la bibliothèque d’éléments',
      width: 420,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(8),
        child: EventBuilderV2ElementLibrary(
          hasLinkedScene: selected?.scene.sceneId != null,
          onOpenScene: null,
        ),
      ),
    );
  }
}

PokeMapDiagnosticSeverity _feedbackSeverity(
  NarrativeEventBuilderV2WriteStatus? status,
) {
  return switch (status) {
    NarrativeEventBuilderV2WriteStatus.committed ||
    NarrativeEventBuilderV2WriteStatus.noOp =>
      PokeMapDiagnosticSeverity.info,
    NarrativeEventBuilderV2WriteStatus.blocked ||
    NarrativeEventBuilderV2WriteStatus.conflict ||
    NarrativeEventBuilderV2WriteStatus.recoveryRequired =>
      PokeMapDiagnosticSeverity.warning,
    NarrativeEventBuilderV2WriteStatus.rejected ||
    NarrativeEventBuilderV2WriteStatus.failed ||
    null =>
      PokeMapDiagnosticSeverity.error,
  };
}

PokeMapDiagnosticSeverity _validationDiagnosticSeverity(
  NarrativeEventValidationSeverity severity,
) {
  return switch (severity) {
    NarrativeEventValidationSeverity.info => PokeMapDiagnosticSeverity.info,
    NarrativeEventValidationSeverity.warning =>
      PokeMapDiagnosticSeverity.warning,
    NarrativeEventValidationSeverity.error => PokeMapDiagnosticSeverity.error,
  };
}

String _feedbackTitle(NarrativeEventBuilderV2WriteStatus? status) {
  return switch (status) {
    NarrativeEventBuilderV2WriteStatus.committed => 'Événement enregistré',
    NarrativeEventBuilderV2WriteStatus.noOp => 'Événement à jour',
    NarrativeEventBuilderV2WriteStatus.blocked => 'Enregistrement bloqué',
    NarrativeEventBuilderV2WriteStatus.conflict =>
      'Une version plus récente existe',
    NarrativeEventBuilderV2WriteStatus.recoveryRequired =>
      'Rechargement nécessaire',
    NarrativeEventBuilderV2WriteStatus.rejected =>
      'Modification non applicable',
    NarrativeEventBuilderV2WriteStatus.failed ||
    null =>
      'Enregistrement impossible',
  };
}
