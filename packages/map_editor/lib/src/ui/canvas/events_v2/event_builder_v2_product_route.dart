import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../application/models/narrative_event_map_bridge_models.dart';
import '../../../application/models/narrative_event_authoring_session.dart';
import '../../../application/models/narrative_event_migration_persistence_models.dart';
import '../../../application/services/narrative_event_validation_coordinator.dart';
import '../../../application/services/narrative_template_catalog.dart';
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
import '../../../features/narrative/state/scene_consequence_catalog_providers.dart';
import '../../../infrastructure/repositories/narrative_template_transaction_file_gateway.dart';
import '../../design_system/design_system.dart';
import '../narrative_studio/narrative_studio_destination.dart';
import '../narrative_studio/narrative_studio_navigation.dart';
import '../scenes/scene_action_builder.dart';
import 'event_builder_v2_authoring_sheets.dart';
import 'event_builder_v2_element_library.dart';
import 'event_builder_v2_migration_sheet.dart';
import 'event_builder_v2_simulation_sheet.dart';
import 'event_builder_v2_template_sheet.dart';
import 'event_builder_v2_workspace.dart';

final _eventBuilderV2TemplateDraftProvider =
    StateProvider<_PendingEventBuilderV2TemplateDraft?>((ref) => null);

class _PendingEventBuilderV2TemplateDraft {
  const _PendingEventBuilderV2TemplateDraft({
    required this.projectPath,
    required this.draft,
  });

  final String projectPath;
  final EventBuilderV2TemplateDraft draft;
}

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
  bool _globalDiagnosticsExpanded = false;
  NarrativeTemplatePreview? _lastTemplatePreview;
  String? _lastEventUndoPath;
  final ScrollController _eventListScrollController = ScrollController();
  final Map<String, FocusNode> _eventFocusNodes = <String, FocusNode>{};
  int? _eventRestorationRevisionInFlight;

  @override
  void dispose() {
    _eventListScrollController.dispose();
    for (final node in _eventFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

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
    final pendingTemplate = ref.watch(_eventBuilderV2TemplateDraftProvider);
    final currentProjectPath = _projectFilePath();
    final pendingTemplateDraft =
        pendingTemplate?.projectPath == currentProjectPath
            ? pendingTemplate?.draft
            : null;
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

    final restoration = ref
        .watch(narrativeStudioNavigationControllerProvider)
        .restorationRequest;
    if (restoration != null &&
        restoration.expectation.location.destination ==
            NarrativeStudioDestination.events &&
        restoration.expectation.location.selection?.assetId ==
            selected?.eventId &&
        (restoration.expectation.focusAnchorId == null ||
            restoration.expectation.focusAnchorId == selected?.stableKey)) {
      _scheduleEventReturnRestoration(restoration);
    }

    final workspace = EventBuilderV2Workspace(
      state: state,
      mode: mode,
      selectedStableKey: selected?.stableKey,
      viewportWidth: widget.viewportWidth,
      onQueryChanged: (value) => setState(() => _query = value),
      onFilterChanged: (value) => setState(() => _filter = value),
      onSelectEvent: _selectEvent,
      onOpenLifecycleActions:
          canMutateSelected && !_isAuthoring ? _openLifecycleSheet : null,
      onCreateEvent:
          state.isReadOnly || _isAuthoring ? null : _openCreationSheet,
      onCreateTemplate:
          state.isReadOnly || _isAuthoring ? null : _openTemplateSheet,
      hasPendingTemplate: pendingTemplateDraft != null,
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
      onSimulate:
          selected?.eventId == null || selected!.readOnly || _isAuthoring
              ? null
              : () => _openSimulationSheet(selected),
      onManageEvaluationOrder: canMutateSelected && !_isAuthoring
          ? () => _openBehaviorSheet(selected!)
          : null,
      validationItems: validationItems,
      eventListScrollController: _eventListScrollController,
      eventFocusNodeForStableKey: _eventFocusNodeFor,
      onValidationAction: validationSnapshot == null
          ? null
          : (item) => _navigateFromValidation(
                item,
                readModel: readModel,
              ),
    );
    final navigationFailure = bridge.lastNavigationResult;
    final notices = <Widget>[];
    if (_lastTemplatePreview != null && !_isAuthoring) {
      notices.add(
        PokeMapDiagnosticCallout(
          key: const ValueKey('event-builder-v2-template-undo'),
          severity: PokeMapDiagnosticSeverity.info,
          title: 'Gabarit créé',
          message: 'L’Event et sa Scene ont été enregistrés ensemble.',
          actionLabel: 'Annuler la création',
          onAction: _undoLastTemplate,
        ),
      );
    }
    final globalDiagnostics = validationSnapshot?.state.global ??
        const <NarrativeEventValidationItem>[];
    if (globalDiagnostics.isNotEmpty) {
      notices.add(
        _GlobalDiagnosticsPanel(
          diagnostics: globalDiagnostics,
          expanded: _globalDiagnosticsExpanded,
          onToggle: () => setState(
            () => _globalDiagnosticsExpanded = !_globalDiagnosticsExpanded,
          ),
          onAction: (item) => _navigateFromValidation(
            item,
            readModel: readModel,
          ),
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
    _rememberEventReturn(event);
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
    _rememberEventReturn(event);
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

  FocusNode _eventFocusNodeFor(String stableKey) =>
      _eventFocusNodes.putIfAbsent(
        stableKey,
        () => FocusNode(debugLabel: 'Event Builder item $stableKey'),
      );

  void _scheduleEventReturnRestoration(
    NarrativeStudioRestorationRequest restoration,
  ) {
    if (_eventRestorationRevisionInFlight == restoration.revision) return;
    _eventRestorationRevisionInFlight = restoration.revision;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreEventReturn(restoration, attempt: 0);
    });
  }

  void _restoreEventReturn(
    NarrativeStudioRestorationRequest restoration, {
    required int attempt,
  }) {
    if (!mounted) return;
    final current = ref
        .read(narrativeStudioNavigationControllerProvider)
        .restorationRequest;
    if (current?.revision != restoration.revision) {
      if (_eventRestorationRevisionInFlight == restoration.revision) {
        _eventRestorationRevisionInFlight = null;
      }
      return;
    }
    if (!_eventListScrollController.hasClients) {
      _retryEventReturn(restoration, attempt: attempt);
      return;
    }

    final position = _eventListScrollController.position;
    final expectedOffset = restoration.expectation.scrollOffset?.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (expectedOffset != null &&
        (_eventListScrollController.offset - expectedOffset).abs() > 0.01) {
      _eventListScrollController.jumpTo(expectedOffset);
    }

    final focusAnchor = restoration.expectation.focusAnchorId;
    if (focusAnchor != null) {
      final focusNode = _eventFocusNodes[focusAnchor];
      if (focusNode?.context == null) {
        _retryEventReturn(restoration, attempt: attempt);
        return;
      }
      if (!focusNode!.hasFocus) {
        focusNode.requestFocus();
        _retryEventReturn(restoration, attempt: attempt);
        return;
      }
    }

    if (expectedOffset != null &&
        (_eventListScrollController.offset - expectedOffset).abs() > 0.01) {
      _eventListScrollController.jumpTo(expectedOffset);
      _retryEventReturn(restoration, attempt: attempt);
      return;
    }

    ref
        .read(narrativeStudioNavigationControllerProvider.notifier)
        .consumeRestoration(restoration.revision);
    _eventRestorationRevisionInFlight = null;
  }

  void _retryEventReturn(
    NarrativeStudioRestorationRequest restoration, {
    required int attempt,
  }) {
    if (attempt >= 12) {
      if (_eventRestorationRevisionInFlight == restoration.revision) {
        _eventRestorationRevisionInFlight = null;
      }
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreEventReturn(restoration, attempt: attempt + 1);
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  void _rememberEventReturn(NarrativeEventProjectSummary event) {
    final eventId = event.eventId;
    if (eventId == null) return;
    final group = narrativeEventGroupContextForSummary(event);
    ref
        .read(narrativeStudioNavigationControllerProvider.notifier)
        .rememberExternalReturn(
          NarrativeStudioReturnExpectation(
            location: NarrativeStudioRouteLocation.events(
              selection: NarrativeStudioAssetSelection(
                kind: NarrativeStudioAssetKind.event,
                assetId: eventId,
                parentId: group.mapId,
              ),
            ),
            scrollOffset: _eventListScrollController.hasClients
                ? _eventListScrollController.offset
                : 0,
            focusAnchorId: event.stableKey,
          ),
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

  Future<void> _openSimulationSheet(
    NarrativeEventProjectSummary event,
  ) async {
    final eventId = event.eventId;
    final projectPath = _projectFilePath();
    if (eventId == null || projectPath == null) return;
    final snapshot = await _loadAuthoringSnapshot(eventId: eventId);
    if (!mounted || snapshot == null) return;
    await showPokeMapDesktopSideSheet<void>(
      context: context,
      title: 'Tester le déclenchement',
      semanticLabel: 'Simuler ${event.title} avec l’autorité du jeu',
      barrierLabel: 'Fermer la simulation Event',
      width: 500,
      builder: (_) => EventBuilderV2SimulationSheet(
        snapshot: snapshot,
        eventId: eventId,
        onRun: (input) => _authoringUseCase().simulate(
          projectPath: projectPath,
          input: input,
        ),
      ),
    );
  }

  Future<void> _openTemplateSheet() async {
    final projectPath = _projectFilePath();
    final editor = ref.read(editorNotifierProvider);
    if (projectPath == null || editor.project == null) return;
    if (editor.isDirty || editor.isProjectDirty || editor.isSaving) {
      setState(() {
        _authoringStatus = NarrativeEventBuilderV2WriteStatus.blocked;
        _authoringMessage =
            'Enregistrez les changements en cours avant de créer un gabarit.';
      });
      return;
    }
    setState(() {
      _isAuthoring = true;
      _authoringMessage = null;
      _authoringStatus = null;
    });
    try {
      final session = await NarrativeEventAuthoringSession.prepare(projectPath);
      final baseCatalogs = await ref.read(
        sceneConsequenceCatalogsProvider(editor.projectRootPath).future,
      );
      final catalogs = baseCatalogs
          .withConfiguredStarters(session.manifest.newGame.starterOptions)
          .withProjectStorySteps(session.manifest);
      final eventId = NarrativeEventIdGenerator().generate(
        existingRecords: session.manifest.eventRegistry?.records ??
            const <NarrativeEventRecord>[],
      );
      final sceneId = 'scene.template.${eventId.substring(4)}';
      final pendingTemplate = ref.read(_eventBuilderV2TemplateDraftProvider);
      final pendingTemplateDraft = pendingTemplate?.projectPath == projectPath
          ? pendingTemplate?.draft
          : null;
      if (!mounted) return;
      setState(() => _isAuthoring = false);
      await showPokeMapDesktopSideSheet<void>(
        context: context,
        title: 'Gabarit narratif',
        semanticLabel: 'Créer un Event et sa Scene depuis un gabarit',
        barrierLabel: 'Annuler le gabarit narratif',
        width: 520,
        builder: (_) => EventBuilderV2TemplateSheet(
          project: session.manifest,
          eventId: eventId,
          sceneId: sceneId,
          spatialSources:
              session.context.catalog.spatialSources.selectableOptions,
          physicalSourceKinds: _templatePhysicalSourceKinds(session.maps),
          actionPickerOptions: _templateActionPickerOptions(
            project: session.manifest,
            maps: session.maps,
            catalogs: catalogs,
          ),
          onApply: _applyTemplate,
          initialDraft: pendingTemplateDraft,
          onOpenMapEditor: (draft) {
            ref.read(_eventBuilderV2TemplateDraftProvider.notifier).state =
                _PendingEventBuilderV2TemplateDraft(
              projectPath: projectPath,
              draft: draft,
            );
            ref.read(editorNotifierProvider.notifier).selectMapWorkspace();
          },
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isAuthoring = false;
        _authoringStatus = NarrativeEventBuilderV2WriteStatus.failed;
        _authoringMessage =
            'Le catalogue des gabarits ne peut pas être préparé : $error';
      });
    }
  }

  Future<String?> _applyTemplate(NarrativeTemplatePreview preview) async {
    final projectPath = _projectFilePath();
    if (projectPath == null) return 'Le projet enregistré est indisponible.';
    setState(() {
      _isAuthoring = true;
      _authoringMessage = null;
      _authoringStatus = null;
    });
    try {
      final gateway = NarrativeTemplateTransactionFileGateway(
        projectPath: projectPath,
      );
      final coordinator = NarrativeTemplateTransactionCoordinator(gateway);
      await coordinator.recover();
      await coordinator.apply(
        transactionId: 'template-${DateTime.now().microsecondsSinceEpoch}',
        preview: preview,
      );
      await ref.read(editorNotifierProvider.notifier).loadProject(
            projectPath,
            rememberAsRecent: false,
          );
      if (!mounted) return null;
      setState(() {
        _isAuthoring = false;
        _authoringStatus = NarrativeEventBuilderV2WriteStatus.committed;
        _authoringMessage =
            'Le gabarit a créé un Event et une Scene sans modifier la map.';
        _pendingSelectionEventId = preview.event?.id;
        _lastTemplatePreview = preview;
      });
      ref.read(_eventBuilderV2TemplateDraftProvider.notifier).state = null;
      return null;
    } on Object catch (error) {
      if (!mounted) return error.toString();
      setState(() {
        _isAuthoring = false;
        _authoringStatus = NarrativeEventBuilderV2WriteStatus.failed;
        _authoringMessage = 'La transaction du gabarit a échoué : $error';
      });
      return _authoringMessage;
    }
  }

  Future<void> _undoLastTemplate() async {
    final preview = _lastTemplatePreview;
    final projectPath = _projectFilePath();
    if (preview == null || projectPath == null) return;
    setState(() => _isAuthoring = true);
    try {
      final coordinator = NarrativeTemplateTransactionCoordinator(
        NarrativeTemplateTransactionFileGateway(projectPath: projectPath),
      );
      await coordinator.undo(preview);
      await ref.read(editorNotifierProvider.notifier).loadProject(
            projectPath,
            rememberAsRecent: false,
          );
      if (!mounted) return;
      setState(() {
        _isAuthoring = false;
        _lastTemplatePreview = null;
        _authoringStatus = NarrativeEventBuilderV2WriteStatus.committed;
        _authoringMessage = 'La création Event + Scene a été annulée.';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isAuthoring = false;
        _authoringStatus = NarrativeEventBuilderV2WriteStatus.failed;
        _authoringMessage = 'L’annulation a été refusée : $error';
      });
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
        _pendingSelectionEventId =
            authoring?.nextRecord == null ? null : result.eventId;
        _lastEventUndoPath = result.persistenceResult?.undoPath;
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

  Future<void> _openLifecycleSheet(
    NarrativeEventProjectSummary event,
  ) {
    final eventId = event.eventId;
    if (eventId == null || event.readOnly) return Future.value();
    final lifecycle = narrativeEventLifecyclePresentation(event);
    return showPokeMapDesktopSideSheet<void>(
      context: context,
      title: 'Cycle de vie de l’événement',
      semanticLabel: 'Actions de cycle de vie pour ${event.title}',
      width: 440,
      builder: (sheetContext) => _EventLifecycleSheet(
        event: event,
        lifecycle: lifecycle,
        canUndo: _lastEventUndoPath != null,
        onRename: () async {
          Navigator.of(sheetContext).pop();
          await _renameLifecycleEvent(event);
        },
        onDuplicate: () async {
          Navigator.of(sheetContext).pop();
          await _runWrite(
            (useCase, path, environment) => useCase.duplicate(
              projectPath: path,
              eventId: eventId,
              environment: environment,
            ),
          );
        },
        onPublish: lifecycle.isDraft
            ? () async {
                Navigator.of(sheetContext).pop();
                await _runWrite(
                  (useCase, path, environment) => useCase.publish(
                    projectPath: path,
                    eventId: eventId,
                    environment: environment,
                  ),
                );
              }
            : null,
        onSetEnabled: lifecycle.isPublished
            ? () async {
                Navigator.of(sheetContext).pop();
                await _runWrite(
                  (useCase, path, environment) => useCase.setEnabled(
                    projectPath: path,
                    eventId: eventId,
                    enabled: !lifecycle.isRuntimeEnabled,
                    environment: environment,
                  ),
                );
              }
            : null,
        onUnpublish: lifecycle.isPublished
            ? () async {
                Navigator.of(sheetContext).pop();
                final confirmed = await showPokeMapBinaryConfirmationDialog(
                  context,
                  title: 'Dépublier ${event.title} ?',
                  message: lifecycle.isRuntimeEnabled
                      ? 'L’événement actif redeviendra un brouillon et ne sera '
                          'plus joué. Sa source, ses conditions, sa Scene et '
                          'son comportement seront conservés.'
                      : 'L’événement redeviendra un brouillon. Sa source, ses '
                          'conditions, sa Scene et son comportement seront '
                          'conservés.',
                  secondaryLabel: 'Annuler',
                  primaryLabel: 'Dépublier',
                );
                if (!confirmed) return;
                await _runWrite(
                  (useCase, path, environment) => useCase.unpublish(
                    projectPath: path,
                    eventId: eventId,
                    environment: environment,
                  ),
                );
              }
            : null,
        onDelete: () async {
          Navigator.of(sheetContext).pop();
          await _deleteLifecycleEvent(event);
        },
        onUndo: _lastEventUndoPath == null
            ? null
            : () async {
                Navigator.of(sheetContext).pop();
                await _undoLastEventWrite();
              },
      ),
    );
  }

  Future<void> _renameLifecycleEvent(
    NarrativeEventProjectSummary event,
  ) async {
    final eventId = event.eventId;
    if (eventId == null) return;
    final controller = TextEditingController(text: event.title);
    final confirmed = await showPokeMapPromptDialog(
      context,
      title: 'Renommer l’événement',
      controller: controller,
      placeholder: 'Nom lisible',
      cancelLabel: 'Annuler',
      confirmLabel: 'Renommer',
    );
    final name = controller.text;
    controller.dispose();
    if (!confirmed) return;
    await _runWrite(
      (useCase, path, environment) => useCase.rename(
        projectPath: path,
        eventId: eventId,
        name: name,
        environment: environment,
      ),
    );
  }

  Future<void> _deleteLifecycleEvent(
    NarrativeEventProjectSummary event,
  ) async {
    final projectPath = _projectFilePath();
    final eventId = event.eventId;
    if (projectPath == null || eventId == null) return;
    setState(() {
      _isAuthoring = true;
      _authoringMessage = null;
      _authoringStatus = null;
    });
    late final NarrativeEventAuthoringResult inspection;
    try {
      inspection = await _authoringUseCase().previewDelete(
        projectPath: projectPath,
        eventId: eventId,
      );
    } on Object {
      if (!mounted) return;
      setState(() {
        _isAuthoring = false;
        _authoringStatus = NarrativeEventBuilderV2WriteStatus.failed;
        _authoringMessage =
            'Les dépendances de cet événement ne peuvent pas être inspectées.';
      });
      return;
    }
    if (!mounted) return;
    setState(() => _isAuthoring = false);
    final preview = inspection.deletionPreview;
    if (preview != null && !preview.canDelete) {
      final consumers = preview.consumers
          .map((usage) => '• ${usage.owner}\n  ${usage.path}')
          .join('\n');
      await showPokeMapConfirmationDialog<bool>(
        context: context,
        title: 'Suppression bloquée',
        message: 'Cet événement est encore utilisé par :\n\n$consumers',
        actions: const [
          PokeMapDialogAction(label: 'Compris', value: false),
        ],
      );
      return;
    }
    final confirmed = await showPokeMapBinaryConfirmationDialog(
      context,
      title: 'Supprimer ${event.title} ?',
      message: 'Cette suppression retire uniquement l’Event V2. '
          'L’élément physique de la map n’est pas supprimé.',
      secondaryLabel: 'Annuler',
      primaryLabel: 'Supprimer',
      primaryIsDestructive: true,
      icon: CupertinoIcons.trash,
    );
    if (!confirmed) return;
    await _runWrite(
      (useCase, path, environment) => useCase.delete(
        projectPath: path,
        eventId: eventId,
        environment: environment,
      ),
    );
  }

  Future<void> _undoLastEventWrite() async {
    final undoPath = _lastEventUndoPath;
    if (undoPath == null) return;
    final editor = ref.read(editorNotifierProvider);
    setState(() {
      _isAuthoring = true;
      _authoringMessage = null;
      _authoringStatus = null;
    });
    final result = await _authoringUseCase().undo(undoPath: undoPath);
    final entry = result.persistenceResult?.undoEntry;
    final nextRegistry = entry?.nextRegistry;
    var adopted = true;
    if (result.succeeded && entry != null && nextRegistry != null) {
      adopted = ref
          .read(editorNotifierProvider.notifier)
          .applyPersistedNarrativeEventRegistry(
            expectedProjectRootPath: editor.projectRootPath!,
            expectedPreviousRegistry: entry.previousRegistry,
            nextRegistry: nextRegistry,
          );
    }
    if (!mounted) return;
    final status = adopted
        ? result.status
        : NarrativeEventBuilderV2WriteStatus.recoveryRequired;
    final eventId = result.eventId;
    final restored = eventId != null &&
        nextRegistry?.records.any((record) => record.id == eventId) == true;
    setState(() {
      _isAuthoring = false;
      _authoringStatus = status;
      _authoringMessage = result.succeeded && adopted
          ? 'La dernière modification de l’événement a été annulée.'
          : adopted
              ? result.message
              : 'L’annulation est sur disque, mais la vue doit être rechargée.';
      _pendingSelectionEventId = restored ? eventId : null;
      _lastEventUndoPath = result.persistenceResult?.undoPath;
    });
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
        onSubmit: (expression) => _runWrite(
          (useCase, path, environment) => useCase.setConditionExpression(
            projectPath: path,
            eventId: eventId,
            expression: expression,
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
        outcomeSources: snapshot.outcomeSources,
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
      if (update.reusePolicy == NarrativeEventReusePolicy.reusable)
        () => _runWrite(
              (useCase, path, environment) => useCase.setResetPolicy(
                projectPath: path,
                eventId: eventId,
                resetPolicy: const NarrativeEventResetPolicy.never(),
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
      if (update.reusePolicy != NarrativeEventReusePolicy.reusable)
        () => _runWrite(
              (useCase, path, environment) => useCase.setResetPolicy(
                projectPath: path,
                eventId: eventId,
                resetPolicy: update.resetPolicy,
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
          onCreateTemplate: _isAuthoring ? null : _openTemplateSheet,
          hasPendingTemplate:
              ref.read(_eventBuilderV2TemplateDraftProvider) != null,
        ),
      ),
    );
  }
}

Map<NarrativeCommandParameterKind, List<SceneActionPickerOption>>
    _templateActionPickerOptions({
  required ProjectManifest project,
  required List<MapData> maps,
  required SceneConsequenceCatalogs catalogs,
}) {
  List<SceneActionPickerOption> section(
    SceneConsequenceCatalogSection value,
  ) =>
      [
        for (final option in value.options)
          SceneActionPickerOption(id: option.id, label: option.label),
      ];
  final shops = <String>{};
  for (final scene in project.scenes) {
    for (final node in scene.graph.nodes) {
      final command = node.payload is SceneActionPayload
          ? (node.payload as SceneActionPayload).interactiveCommand
          : null;
      if (command is SceneOpenShopInteractiveCommand) shops.add(command.shopId);
    }
  }
  return <NarrativeCommandParameterKind, List<SceneActionPickerOption>>{
    NarrativeCommandParameterKind.fact: [
      for (final fact in project.facts)
        SceneActionPickerOption(id: fact.id, label: fact.label),
    ],
    NarrativeCommandParameterKind.event: [
      for (final record
          in project.eventRegistry?.records ?? const <NarrativeEventRecord>[])
        SceneActionPickerOption(
          id: record.id,
          label: record.when(
            draft: (draft) => draft.name,
            configured: (definition, _) => definition.name,
          ),
        ),
    ],
    NarrativeCommandParameterKind.storyStep: section(catalogs.storySteps),
    NarrativeCommandParameterKind.item: section(catalogs.items),
    NarrativeCommandParameterKind.species: section(catalogs.species),
    NarrativeCommandParameterKind.starter: section(catalogs.configuredStarters),
    NarrativeCommandParameterKind.map: [
      for (final map in project.maps)
        SceneActionPickerOption(id: map.id, label: map.name),
    ],
    NarrativeCommandParameterKind.warp: [
      for (final map in maps)
        for (final warp in map.warps)
          SceneActionPickerOption(
            id: warp.id,
            label: '${map.name} → ${warp.targetMapId}',
          ),
    ],
    NarrativeCommandParameterKind.shop: [
      for (final shopId in shops)
        SceneActionPickerOption(id: shopId, label: shopId),
    ],
    NarrativeCommandParameterKind.trainer: [
      for (final trainer in project.trainers)
        SceneActionPickerOption(id: trainer.id, label: trainer.name),
    ],
    NarrativeCommandParameterKind.dialogue: [
      for (final dialogue in project.dialogues)
        SceneActionPickerOption(id: dialogue.id, label: dialogue.name),
    ],
    NarrativeCommandParameterKind.cinematic: [
      for (final cinematic in project.cinematics)
        SceneActionPickerOption(id: cinematic.id, label: cinematic.title),
    ],
  };
}

Map<String, NarrativeTemplatePhysicalSourceKind> _templatePhysicalSourceKinds(
  List<MapData> maps,
) {
  final result = <String, NarrativeTemplatePhysicalSourceKind>{};
  for (final map in maps) {
    for (final entity in map.entities) {
      if (entity.kind == MapEntityKind.spawn) continue;
      result['entity:${map.id}:${entity.id}'] = entity.kind == MapEntityKind.npc
          ? NarrativeTemplatePhysicalSourceKind.entity
          : NarrativeTemplatePhysicalSourceKind.object;
    }
    for (final trigger in map.triggers) {
      result['trigger:${map.id}:${trigger.id}'] =
          trigger.type == TriggerType.warp
              ? NarrativeTemplatePhysicalSourceKind.warp
              : NarrativeTemplatePhysicalSourceKind.zone;
    }
  }
  return Map<String, NarrativeTemplatePhysicalSourceKind>.unmodifiable(result);
}

class _EventLifecycleSheet extends StatelessWidget {
  const _EventLifecycleSheet({
    required this.event,
    required this.lifecycle,
    required this.canUndo,
    required this.onRename,
    required this.onDuplicate,
    required this.onPublish,
    required this.onSetEnabled,
    required this.onUnpublish,
    required this.onDelete,
    required this.onUndo,
  });

  final NarrativeEventProjectSummary event;
  final NarrativeEventLifecyclePresentation lifecycle;
  final bool canUndo;
  final VoidCallback onRename;
  final VoidCallback onDuplicate;
  final VoidCallback? onPublish;
  final VoidCallback? onSetEnabled;
  final VoidCallback? onUnpublish;
  final VoidCallback onDelete;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('event-builder-v2-lifecycle-actions'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                PokeMapStatusLabel(
                  label: lifecycle.label,
                  tone: lifecycle.isRuntimeEnabled
                      ? PokeMapTone.success
                      : lifecycle.isDraft
                          ? PokeMapTone.warning
                          : PokeMapTone.neutral,
                  icon: lifecycle.isRuntimeEnabled
                      ? CupertinoIcons.play_fill
                      : lifecycle.isDraft
                          ? CupertinoIcons.pencil
                          : CupertinoIcons.pause_fill,
                ),
                const SizedBox(height: 8),
                Text(
                  lifecycle.description,
                  style: const TextStyle(fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _lifecycleButton(
            key: const ValueKey('event-builder-v2-lifecycle-rename'),
            label: 'Renommer',
            icon: CupertinoIcons.pencil,
            onPressed: onRename,
          ),
          const SizedBox(height: 8),
          _lifecycleButton(
            key: const ValueKey('event-builder-v2-lifecycle-duplicate'),
            label: 'Dupliquer',
            icon: CupertinoIcons.square_on_square,
            onPressed: onDuplicate,
          ),
          if (onPublish != null) ...[
            const SizedBox(height: 8),
            _lifecycleButton(
              key: const ValueKey('event-builder-v2-lifecycle-publish'),
              label: 'Publier',
              icon: CupertinoIcons.check_mark_circled,
              onPressed: onPublish!,
              variant: PokeMapButtonVariant.successOutline,
            ),
          ],
          if (onSetEnabled != null) ...[
            const SizedBox(height: 8),
            _lifecycleButton(
              key: const ValueKey('event-builder-v2-lifecycle-enabled'),
              label: lifecycle.isRuntimeEnabled ? 'Désactiver' : 'Activer',
              icon: lifecycle.isRuntimeEnabled
                  ? CupertinoIcons.pause_fill
                  : CupertinoIcons.play_fill,
              onPressed: onSetEnabled!,
              variant: lifecycle.isRuntimeEnabled
                  ? PokeMapButtonVariant.secondary
                  : PokeMapButtonVariant.successOutline,
            ),
          ],
          if (onUnpublish != null) ...[
            const SizedBox(height: 8),
            _lifecycleButton(
              key: const ValueKey('event-builder-v2-lifecycle-unpublish'),
              label: 'Dépublier',
              icon: CupertinoIcons.arrow_uturn_left_circle,
              onPressed: onUnpublish!,
            ),
          ],
          const SizedBox(height: 16),
          const PokeMapSectionHeader(title: 'Actions protégées'),
          const SizedBox(height: 8),
          if (canUndo && onUndo != null) ...[
            _lifecycleButton(
              key: const ValueKey('event-builder-v2-lifecycle-undo'),
              label: 'Annuler la dernière modification',
              icon: CupertinoIcons.arrow_uturn_left,
              onPressed: onUndo!,
            ),
            const SizedBox(height: 8),
          ],
          _lifecycleButton(
            key: const ValueKey('event-builder-v2-lifecycle-delete'),
            label: 'Supprimer',
            icon: CupertinoIcons.trash,
            onPressed: onDelete,
            variant: PokeMapButtonVariant.danger,
          ),
          const SizedBox(height: 10),
          const Text(
            'Supprimer l’Event ne supprime jamais le PNJ, l’objet ou la zone '
            'placé sur la map.',
            style: TextStyle(fontSize: 11, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _lifecycleButton({
    required Key key,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    PokeMapButtonVariant variant = PokeMapButtonVariant.secondary,
  }) {
    return SizedBox(
      width: double.infinity,
      child: PokeMapButton(
        key: key,
        onPressed: onPressed,
        variant: variant,
        leading: Icon(icon),
        child: Text(label),
      ),
    );
  }
}

class _GlobalDiagnosticsPanel extends StatelessWidget {
  const _GlobalDiagnosticsPanel({
    required this.diagnostics,
    required this.expanded,
    required this.onToggle,
    required this.onAction,
  });

  final List<NarrativeEventValidationItem> diagnostics;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<NarrativeEventValidationItem> onAction;

  @override
  Widget build(BuildContext context) {
    final groups = _deduplicateGlobalDiagnostics(diagnostics);
    final errorCount = diagnostics.where(_isErrorDiagnostic).length;
    final warningCount = diagnostics.where(_isWarningDiagnostic).length;
    final infoCount = diagnostics.length - errorCount - warningCount;
    final visibleGroups = expanded
        ? groups
        : groups.where(
            (group) => _isErrorDiagnostic(group.item),
          );
    final hasHiddenGroups = groups.any(
      (group) => !_isErrorDiagnostic(group.item),
    );

    return Semantics(
      key: const ValueKey('event-builder-v2-global-diagnostics'),
      container: true,
      liveRegion: errorCount > 0,
      label: 'Diagnostics du registre Event',
      child: PokeMapCard(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                PokeMapIconTile(
                  key: const ValueKey(
                    'event-builder-v2-global-diagnostics-icon',
                  ),
                  icon: errorCount > 0
                      ? CupertinoIcons.exclamationmark_octagon_fill
                      : warningCount > 0
                          ? CupertinoIcons.exclamationmark_triangle_fill
                          : CupertinoIcons.info_circle_fill,
                  tone: errorCount > 0
                      ? PokeMapTone.danger
                      : warningCount > 0
                          ? PokeMapTone.warning
                          : PokeMapTone.info,
                  size: 28,
                  iconSize: 14,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Diagnostics du registre Event',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (errorCount > 0) ...[
                  PokeMapBadge(
                    label: _diagnosticCountLabel(
                      errorCount,
                      singular: 'erreur',
                      plural: 'erreurs',
                    ),
                    variant: PokeMapBadgeVariant.error,
                  ),
                  const SizedBox(width: 6),
                ],
                if (warningCount > 0) ...[
                  PokeMapBadge(
                    label: _diagnosticCountLabel(
                      warningCount,
                      singular: 'avertissement',
                      plural: 'avertissements',
                    ),
                    variant: PokeMapBadgeVariant.warning,
                  ),
                  const SizedBox(width: 6),
                ],
                if (infoCount > 0) ...[
                  PokeMapBadge(
                    label: _diagnosticCountLabel(
                      infoCount,
                      singular: 'information',
                      plural: 'informations',
                    ),
                    variant: PokeMapBadgeVariant.info,
                  ),
                  const SizedBox(width: 6),
                ],
                if (hasHiddenGroups)
                  PokeMapButton(
                    key: const ValueKey(
                      'event-builder-v2-global-diagnostics-toggle',
                    ),
                    onPressed: onToggle,
                    size: PokeMapButtonSize.small,
                    variant: PokeMapButtonVariant.ghost,
                    leading: Icon(
                      expanded
                          ? CupertinoIcons.chevron_up
                          : CupertinoIcons.chevron_down,
                    ),
                    child: Text(
                      expanded ? 'Replier les détails' : 'Afficher les détails',
                    ),
                  ),
              ],
            ),
            for (final group in visibleGroups) ...[
              const SizedBox(height: 8),
              PokeMapDiagnosticCallout(
                key: ValueKey(
                  'event-builder-v2-global-diagnostic-'
                  '${group.item.diagnostic.stableKey}',
                ),
                severity: _validationDiagnosticSeverity(
                  group.item.diagnostic.severity,
                ),
                title: 'Diagnostic du registre Event',
                message: group.item.diagnostic.message,
                actionLabel: group.item.actionable ? 'Examiner' : null,
                onAction:
                    group.item.actionable ? () => onAction(group.item) : null,
              ),
              if (group.occurrences > 1) ...[
                const SizedBox(height: 5),
                Align(
                  alignment: Alignment.centerLeft,
                  child: PokeMapBadge(
                    label: '${group.occurrences} occurrences',
                    variant: PokeMapBadgeVariant.neutral,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _GlobalDiagnosticGroup {
  const _GlobalDiagnosticGroup({
    required this.item,
    required this.occurrences,
  });

  final NarrativeEventValidationItem item;
  final int occurrences;
}

List<_GlobalDiagnosticGroup> _deduplicateGlobalDiagnostics(
  List<NarrativeEventValidationItem> diagnostics,
) {
  final groups = <String, _GlobalDiagnosticGroup>{};
  for (final item in diagnostics) {
    final diagnostic = item.diagnostic;
    final key = <String>[
      diagnostic.severity.name,
      diagnostic.message,
      diagnostic.action.name,
      diagnostic.destination.stableKey,
    ].join('\u001f');
    final previous = groups[key];
    groups[key] = _GlobalDiagnosticGroup(
      item: previous?.item ?? item,
      occurrences: (previous?.occurrences ?? 0) + 1,
    );
  }
  return List<_GlobalDiagnosticGroup>.unmodifiable(groups.values);
}

bool _isErrorDiagnostic(NarrativeEventValidationItem item) =>
    item.diagnostic.severity == NarrativeEventValidationSeverity.error;

bool _isWarningDiagnostic(NarrativeEventValidationItem item) =>
    item.diagnostic.severity == NarrativeEventValidationSeverity.warning;

String _diagnosticCountLabel(
  int count, {
  required String singular,
  required String plural,
}) =>
    '$count ${count == 1 ? singular : plural}';

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
