import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../app/providers/core_providers.dart';
import '../../application/services/narrative_activity_journal.dart';
import '../../application/services/narrative_diagnostic_suppression_service.dart';
import '../../application/services/narrative_project_snapshot_loader.dart';
import '../../application/services/narrative_template_catalog.dart';
import '../../application/models/narrative_authoring_transaction.dart';
import '../../domain/repositories/repositories.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/narrative/application/overview/narrative_overview_read_model.dart';
import '../../features/narrative/application/narrative_workspace_projection.dart';
import '../../features/narrative/state/narrative_workspace_providers.dart';
import '../../features/narrative/state/narrative_workspace_state.dart';
import '../../features/narrative/state/narrative_scene_focus_provider.dart';
import '../../features/narrative/state/narrative_event_builder_v2_providers.dart';
import '../../features/narrative/state/narrative_event_map_bridge_state.dart';
import '../../features/narrative/state/narrative_validator_providers.dart';
import '../../features/narrative/state/scene_consequence_catalog_providers.dart';
import '../../theme/theme.dart';
import '../design_system/design_system.dart';
import 'cinematics/cinematics_library_workspace.dart';
import 'cutscene_studio_workspace.dart';
import 'dialogue_studio_workspace.dart';
import 'events/event_builder_workspace.dart';
import 'events_v2/event_builder_v2_product_route.dart';
import 'events_v2/map_events_workspace.dart';
import 'facts_world_rules/facts_world_rules_workspace.dart';
import 'narrative_overview_workspace.dart';
import 'narrative_validator_workspace.dart';
import 'narrative_studio/narrative_studio_destination.dart';
import 'narrative_studio/narrative_studio_navigation.dart';
import 'narrative_studio/narrative_studio_route_presentation.dart';
import 'narrative_studio/narrative_studio_workspace_page.dart';
import 'scenes/scene_action_builder.dart';
import 'scenes/scene_node_read_only_inspector.dart';
import 'scenes_workspace.dart';
import 'step_studio_workspace.dart';
import 'storylines_workspace.dart';

/// Workspace central du studio narratif.
///
/// Ce widget est la "surface de création" principale pour:
/// - Global Story
/// - Step
/// - Cutscene
///
/// Intention produit:
/// - éviter un modèle "inspecteur de champs à droite"
/// - rendre la narration éditable dans l'îlot central, comme un vrai workspace
class NarrativeWorkspaceCanvas extends ConsumerWidget {
  const NarrativeWorkspaceCanvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorNotifierProvider);
    final editorNotifier = ref.read(editorNotifierProvider.notifier);
    final narrative = ref.watch(narrativeWorkspaceControllerProvider);
    final narrativeController =
        ref.read(narrativeWorkspaceControllerProvider.notifier);
    final projection = ref.watch(narrativeWorkspaceProjectionProvider);
    final sceneFocus = ref.watch(narrativeSceneFocusProvider);
    final studioNavigation =
        ref.watch(narrativeStudioNavigationControllerProvider);
    final sceneConsequenceCatalogsAsync =
        editor.workspaceMode == EditorWorkspaceMode.scenes
            ? ref.watch(
                sceneConsequenceCatalogsProvider(editor.projectRootPath),
              )
            : const AsyncValue<SceneConsequenceCatalogs>.data(
                SceneConsequenceCatalogs.unavailable(),
              );
    final baseSceneConsequenceCatalogs = sceneConsequenceCatalogsAsync.when(
      data: (catalogs) => catalogs,
      loading: () => const SceneConsequenceCatalogs.loading(),
      error: (_, __) => const SceneConsequenceCatalogs(
        items: SceneConsequenceCatalogSection(
          status: SceneConsequenceCatalogStatus.failed,
          options: <SceneConsequenceCatalogOption>[],
          message: 'Impossible de charger le catalogue local des objets.',
        ),
        species: SceneConsequenceCatalogSection(
          status: SceneConsequenceCatalogStatus.failed,
          options: <SceneConsequenceCatalogOption>[],
          message: 'Impossible de charger les espèces locales du projet.',
        ),
      ),
    );
    final project = editor.project;
    final catalogsWithStarters =
        baseSceneConsequenceCatalogs.withConfiguredStarters(
      project?.newGame.starterOptions ?? const <ProjectStarterOption>[],
    );
    final sceneConsequenceCatalogs = project == null
        ? catalogsWithStarters
        : catalogsWithStarters.withProjectStorySteps(project);

    final showsMapEvents = editor.workspaceMode == EditorWorkspaceMode.events &&
        studioNavigation.location.destination ==
            NarrativeStudioDestination.events &&
        studioNavigation.location.childRoute ==
            NarrativeStudioChildRoute.mapEvents;

    if (showsMapEvents) {
      final project = editor.project;
      final projectRootPath = editor.projectRootPath?.trim();
      if (project == null ||
          projectRootPath == null ||
          projectRootPath.isEmpty) {
        return const PokeMapEmptyState(
          title: 'Aucun projet chargé',
          description:
              'Chargez un projet pour regrouper ses événements par map.',
          icon: Icon(CupertinoIcons.map),
        );
      }
      final request = NarrativeEventBuilderV2SnapshotRequest.fromProject(
        projectRootPath: projectRootPath,
        project: project,
      );
      final readModel = ref.watch(narrativeMapEventsReadModelProvider(request));
      final restoration = studioNavigation.restorationRequest;
      final mapRestoration = restoration != null &&
              restoration.expectation.location.destination ==
                  NarrativeStudioDestination.events &&
              restoration.expectation.location.childRoute ==
                  NarrativeStudioChildRoute.mapEvents
          ? restoration
          : null;

      Future<void> openSource(NarrativeMapEventSourceRow row) async {
        final source = row.option.source;
        if (source == null || !row.option.selectable) return;
        final current = ref.read(editorNotifierProvider);
        final sameMap = current.activeMap?.id == row.option.mapId;
        if (!sameMap && current.isDirty) return;
        final targetMap = sameMap
            ? current.activeMap
            : await editorNotifier.loadMapSnapshotById(row.option.mapId);
        if (targetMap == null) return;
        final navigation = buildNarrativeEventNavigationIndex(
          project: project,
          maps: [targetMap],
        ).mapNavigationForSource(source);
        final focus = navigation.focusTarget;
        if (!navigation.available || focus == null) return;
        if (!sameMap &&
            !editorNotifier.activateNarrativeEventMapSnapshot(targetMap)) {
          return;
        }
        if (!editorNotifier.focusNarrativeEventMapSource(focus)) return;
        ref
            .read(narrativeStudioNavigationControllerProvider.notifier)
            .rememberExternalReturn(
              NarrativeStudioReturnExpectation(
                location: NarrativeStudioRouteLocation.events(
                  childRoute: NarrativeStudioChildRoute.mapEvents,
                  selection: NarrativeStudioAssetSelection(
                    kind: NarrativeStudioAssetKind.map,
                    assetId: row.option.mapId,
                  ),
                ),
                focusAnchorId: row.stableKey,
              ),
            );
        editorNotifier.selectMapWorkspace();
      }

      void openEvent(String eventId) {
        final selected = ref
            .read(narrativeEventMapBridgeControllerProvider.notifier)
            .selectNarrativeEventV2(project, eventId);
        if (selected) {
          ref
              .read(narrativeStudioNavigationControllerProvider.notifier)
              .replace(
                NarrativeStudioRouteLocation.events(
                  selection: NarrativeStudioAssetSelection(
                    kind: NarrativeStudioAssetKind.event,
                    assetId: eventId,
                  ),
                ),
              );
          editorNotifier.selectEventsWorkspace();
        }
      }

      void openScene(String sceneId) {
        ref.read(narrativeSceneFocusProvider.notifier).focus(sceneId);
        ref.read(narrativeStudioNavigationControllerProvider.notifier).replace(
              NarrativeStudioRouteLocation.scenes(
                selection: NarrativeStudioAssetSelection(
                  kind: NarrativeStudioAssetKind.scene,
                  assetId: sceneId,
                ),
              ),
            );
        editorNotifier.selectScenesWorkspace();
      }

      void openFact(String factId) {
        ref.read(narrativeStudioNavigationControllerProvider.notifier).replace(
              NarrativeStudioRouteLocation.facts(
                selection: NarrativeStudioAssetSelection(
                  kind: NarrativeStudioAssetKind.fact,
                  assetId: factId,
                ),
              ),
            );
        editorNotifier.selectFactsWorkspace();
      }

      void openRule(String ruleId) {
        ref.read(narrativeStudioNavigationControllerProvider.notifier).replace(
              NarrativeStudioRouteLocation.worldRules(
                selection: NarrativeStudioAssetSelection(
                  kind: NarrativeStudioAssetKind.worldRule,
                  assetId: ruleId,
                ),
              ),
            );
        editorNotifier.selectWorldRulesWorkspace();
      }

      return readModel.when(
        data: (value) {
          if (mapRestoration != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref
                  .read(narrativeStudioNavigationControllerProvider.notifier)
                  .consumeRestoration(mapRestoration.revision);
            });
          }
          final routeSelection = studioNavigation.location.selection;
          return MapEventsWorkspace(
            readModel: value,
            requestedMapId: routeSelection?.kind == NarrativeStudioAssetKind.map
                ? routeSelection?.assetId
                : null,
            requestedFocusAnchorId: mapRestoration?.expectation.focusAnchorId,
            requestedSelectionNonce:
                mapRestoration?.revision ?? studioNavigation.revision,
            onOpenSource: openSource,
            onOpenEvent: openEvent,
            onOpenScene: openScene,
            onOpenFact: openFact,
            onOpenWorldRule: openRule,
          );
        },
        loading: () => const PokeMapEmptyState(
          title: 'Analyse des événements…',
          description: 'Chargement des sources, Events et règles du projet.',
          icon: Icon(CupertinoIcons.hourglass),
        ),
        error: (error, _) => PokeMapEmptyState(
          title: 'Events par map indisponibles',
          description: error.toString(),
          icon: const Icon(CupertinoIcons.exclamationmark_triangle),
          action: PokeMapButton(
            onPressed: () =>
                ref.invalidate(narrativeMapEventsReadModelProvider(request)),
            size: PokeMapButtonSize.compact,
            child: const Text('Réessayer'),
          ),
        ),
      );
    }

    if (editor.workspaceMode == EditorWorkspaceMode.narrativeValidator) {
      final project = editor.project;
      final projectRootPath = editor.projectRootPath?.trim();
      if (project == null ||
          projectRootPath == null ||
          projectRootPath.isEmpty) {
        return NarrativeStudioWorkspacePage(
          presentation: narrativeStudioRoutePresentationFor(
            EditorWorkspaceMode.narrativeValidator,
          )!,
          body: const PokeMapEmptyState(
            title: 'Aucun projet chargé',
            description:
                'Chargez un projet pour calculer son verdict de jouabilité narrative.',
            icon: Icon(CupertinoIcons.checkmark_shield),
          ),
        );
      }
      final request = NarrativeValidatorSnapshotRequest.fromProject(
        projectRootPath: projectRootPath,
        project: project,
        activeMap: editor.activeMap,
      );
      final pokemonCatalogRequest =
          NarrativeValidatorPokemonCatalogRequest.fromValidationRequest(
        request,
      );
      final requestedDiagnosticKey = studioNavigation.location.destination ==
                  NarrativeStudioDestination.validator &&
              studioNavigation.location.selection?.kind ==
                  NarrativeStudioAssetKind.diagnostic
          ? studioNavigation.location.selection?.assetId
          : null;
      final validatorRestoration = studioNavigation.restorationRequest;
      final report = ref.watch(narrativeValidatorReportProvider(request));
      final multidimensionalReport =
          ref.watch(narrativeStudioValidationReportProvider(request));

      void refreshReport() {
        ref.invalidate(
          narrativeValidatorPokemonCatalogSnapshotProvider(
            pokemonCatalogRequest,
          ),
        );
        ref.invalidate(narrativeValidatorReportProvider(request));
        ref.invalidate(narrativeStudioValidationReportProvider(request));
      }

      Future<void> suppressDiagnostic(
        NarrativeProjectDiagnostic diagnostic,
      ) async {
        final reasonController = TextEditingController();
        final accepted = await showPokeMapPromptDialog(
          context,
          title: 'Justifier le masquage',
          controller: reasonController,
          placeholder: 'Raison traçable',
          cancelLabel: 'Annuler',
          confirmLabel: 'Continuer',
        );
        if (!accepted || !context.mounted) {
          reasonController.dispose();
          return;
        }
        final authorController = TextEditingController();
        final authorAccepted = await showPokeMapPromptDialog(
          context,
          title: 'Signer la décision',
          controller: authorController,
          placeholder: 'Nom de l’auteur',
          cancelLabel: 'Annuler',
          confirmLabel: 'Masquer',
        );
        final reason = reasonController.text;
        final author = authorController.text;
        reasonController.dispose();
        authorController.dispose();
        if (!authorAccepted || !context.mounted) return;
        final service = ref.read(narrativeDiagnosticSuppressionServiceProvider);
        final result = await editorNotifier.executeNarrativeAuthoringMutation(
          (current) {
            final next = service.planSuppression(
              project: current,
              diagnostic: diagnostic,
              reason: reason,
              author: author,
            );
            return NarrativeDiagnosticSuppressionsUpdated(
              before: current,
              after: next,
            );
          },
          operationId:
              'suppress-narrative-diagnostic-${service.fingerprint(diagnostic)}',
        );
        if (result?.succeeded == true) refreshReport();
      }

      Future<void> removeSuppression(String diagnosticId) async {
        final service = ref.read(narrativeDiagnosticSuppressionServiceProvider);
        final result = await editorNotifier.executeNarrativeAuthoringMutation(
          (current) => NarrativeDiagnosticSuppressionsUpdated(
            before: current,
            after: service.planRemoval(
              project: current,
              diagnosticId: diagnosticId,
            ),
          ),
          operationId:
              'remove-narrative-diagnostic-suppression-${narrativeValidationPayloadFingerprint({
                'diagnosticId': diagnosticId
              })}',
        );
        if (result?.succeeded == true) refreshReport();
      }

      Future<bool> loadMapForNavigation(String mapId) async {
        final entry = _findProjectMapById(project, mapId);
        if (entry == null) return false;
        await editorNotifier.loadMap(entry.relativePath);
        if (!context.mounted) return false;
        final currentEditor = ref.read(editorNotifierProvider);
        return currentEditor.projectRootPath == projectRootPath &&
            currentEditor.activeMap?.id == mapId;
      }

      Future<void> openMap(String mapId) async {
        if (!await loadMapForNavigation(mapId)) return;
        editorNotifier.selectMapWorkspace();
      }

      Future<bool> openEvent(String eventId, {String? mapId}) async {
        final selected = ref
            .read(narrativeEventMapBridgeControllerProvider.notifier)
            .selectNarrativeEventV2(project, eventId);
        if (selected) {
          editorNotifier.selectEventsWorkspace();
          return true;
        }
        if (mapId == null) return false;
        final entry = _findProjectMapById(project, mapId);
        if (entry == null) return false;
        await editorNotifier.loadMap(entry.relativePath);
        if (!context.mounted) return false;
        final loadedMap = ref.read(editorNotifierProvider).activeMap;
        if (loadedMap?.id != mapId ||
            findMapEventById(loadedMap!, eventId) == null) {
          return false;
        }
        editorNotifier.selectMapEvent(eventId);
        editorNotifier.selectEventsWorkspace();
        return true;
      }

      Future<void> openDiagnostic(
        NarrativeProjectDiagnostic diagnostic,
      ) async {
        final resolution = resolveNarrativeProjectDiagnostic(diagnostic);
        if (resolution.kind ==
            NarrativeStudioNavigationResolutionKind.unavailable) {
          editorNotifier.reportNarrativeNavigationFailure(
            resolution.reason ?? 'La cible du diagnostic est indisponible.',
          );
          return;
        }
        if (diagnostic.destination ==
            NarrativeProjectDiagnosticDestination.dialogue) {
          final dialogueId = diagnostic.dialogueId?.trim();
          if (dialogueId == null ||
              dialogueId.isEmpty ||
              !project.dialogues.any((entry) => entry.id == dialogueId)) {
            editorNotifier.reportNarrativeNavigationFailure(
              'Dialogue introuvable : ${dialogueId ?? 'identifiant absent'}.',
            );
            return;
          }
        }
        if (diagnostic.destination ==
            NarrativeProjectDiagnosticDestination.event) {
          final eventId = diagnostic.eventId?.trim();
          if (eventId == null ||
              eventId.isEmpty ||
              !await openEvent(eventId, mapId: diagnostic.mapId)) {
            editorNotifier.reportNarrativeNavigationFailure(
              'Event introuvable : ${eventId ?? 'identifiant absent'}.',
            );
            return;
          }
        }
        if (!context.mounted) {
          return;
        }
        final returnExpectation = NarrativeStudioReturnExpectation(
          location: NarrativeStudioRouteLocation.validator(
            selection: NarrativeStudioAssetSelection(
              kind: NarrativeStudioAssetKind.diagnostic,
              assetId: diagnostic.stableKey,
              sourceContext: diagnostic.path,
            ),
          ),
          focusAnchorId: diagnostic.stableKey,
        );
        if (resolution.kind ==
            NarrativeStudioNavigationResolutionKind.externalMap) {
          final mapId = resolution.externalMapTarget?.mapId;
          if (mapId == null || !await loadMapForNavigation(mapId)) return;
          ref
              .read(narrativeStudioNavigationControllerProvider.notifier)
              .rememberExternalReturn(returnExpectation);
          editorNotifier.selectMapWorkspace();
          return;
        }
        final target = resolution.location;
        if (target == null) return;
        ref
            .read(narrativeStudioNavigationControllerProvider.notifier)
            .navigate(target, returnExpectation: returnExpectation);
        switch (diagnostic.destination) {
          case NarrativeProjectDiagnosticDestination.map:
            final mapId = diagnostic.mapId;
            if (mapId != null) openMap(mapId);
          case NarrativeProjectDiagnosticDestination.event:
            break;
          case NarrativeProjectDiagnosticDestination.scene:
            final sceneId = diagnostic.sceneId;
            if (sceneId != null) {
              ref.read(narrativeSceneFocusProvider.notifier).focus(sceneId);
              editorNotifier.selectScenesWorkspace();
            }
          case NarrativeProjectDiagnosticDestination.storyline:
            narrativeController.openGlobalStory(
              scenarioId: diagnostic.storylineId,
            );
            editorNotifier.selectGlobalStoryWorkspace();
          case NarrativeProjectDiagnosticDestination.dialogue:
            editorNotifier.selectProjectDialogue(diagnostic.dialogueId);
            editorNotifier.selectDialogueWorkspace();
          case NarrativeProjectDiagnosticDestination.cinematic:
            final cinematicId = diagnostic.cinematicId;
            if (cinematicId != null) {
              narrativeController.openCutscene(
                cutsceneScenarioId: cinematicId,
              );
            }
            editorNotifier.selectCutsceneWorkspace();
          case NarrativeProjectDiagnosticDestination.fact:
            editorNotifier.selectFactsWorkspace();
          case NarrativeProjectDiagnosticDestination.worldRule:
            editorNotifier.selectWorldRulesWorkspace();
          case NarrativeProjectDiagnosticDestination.overview:
            editorNotifier.selectNarrativeOverviewWorkspace();
        }
      }

      return NarrativeStudioWorkspacePage(
        presentation: narrativeStudioRoutePresentationFor(
          EditorWorkspaceMode.narrativeValidator,
        )!,
        actions: [
          PokeMapButton(
            key: const ValueKey('narrative-validator-refresh'),
            onPressed: refreshReport,
            size: PokeMapButtonSize.compact,
            variant: PokeMapButtonVariant.secondary,
            leading: const Icon(CupertinoIcons.refresh),
            child: const Text('Actualiser'),
          ),
        ],
        body: report.when(
          data: (value) {
            final publication = multidimensionalReport.when(
              data: (publication) => publication,
              loading: () => null,
              error: (_, __) => null,
            );
            final mergedReport = mergeNarrativePublicationDiagnostics(
              authoringReport: value,
              publicationReport: publication,
            );
            return NarrativeValidatorWorkspace(
              report: mergedReport,
              multidimensionalReport: publication,
              suppressionSnapshot: ref
                  .read(narrativeDiagnosticSuppressionServiceProvider)
                  .buildSnapshot(
                    project: project,
                    diagnostics: mergedReport.diagnostics,
                  ),
              onSuppressDiagnostic: suppressDiagnostic,
              onRemoveSuppression: removeSuppression,
              requestedDiagnosticKey: requestedDiagnosticKey,
              requestedDiagnosticNonce: studioNavigation.revision,
              requestedRestorationRevision:
                  validatorRestoration?.expectation.location.destination ==
                          NarrativeStudioDestination.validator
                      ? validatorRestoration?.revision
                      : null,
              onRestorationApplied: (revision) => ref
                  .read(narrativeStudioNavigationControllerProvider.notifier)
                  .consumeRestoration(revision),
              onOpenDiagnostic: openDiagnostic,
              onOpenEvent: openEvent,
              onOpenMap: openMap,
            );
          },
          loading: () => const PokeMapEmptyState(
            title: 'Analyse du projet…',
            description:
                'Chargement des maps et agrégation des diagnostics narratifs.',
            icon: Icon(CupertinoIcons.hourglass),
          ),
          error: (error, _) => PokeMapEmptyState(
            title: 'Validation indisponible',
            description: error.toString(),
            icon: const Icon(CupertinoIcons.exclamationmark_triangle),
            action: PokeMapButton(
              onPressed: refreshReport,
              size: PokeMapButtonSize.compact,
              child: const Text('Réessayer'),
            ),
          ),
        ),
      );
    }

    if (projection == null) {
      switch (editor.workspaceMode) {
        case EditorWorkspaceMode.narrativeOverview:
          // Overview owns the honest project-unavailable state. Keeping it
          // here also preserves the shared route context when no project is
          // loaded instead of replacing it with historical placeholder copy.
          return const NarrativeOverviewWorkspace(readModel: null);
        case EditorWorkspaceMode.dialogue:
          // Dialogue Studio hides its real creation action until a project is
          // available and presents its own no-project empty state.
          return const DialogueStudioWorkspace();
        case EditorWorkspaceMode.globalStory:
          return NarrativeStudioWorkspacePage(
            presentation: narrativeStudioRoutePresentationFor(
              EditorWorkspaceMode.globalStory,
            )!,
            body: const PokeMapEmptyState(
              title: 'Aucun projet chargé',
              description: 'Chargez un projet pour structurer ses storylines.',
              icon: Icon(CupertinoIcons.rectangle_grid_1x2),
            ),
          );
        case EditorWorkspaceMode.scenes:
          return NarrativeStudioWorkspacePage(
            presentation: narrativeStudioRoutePresentationFor(
              EditorWorkspaceMode.scenes,
            )!,
            body: const PokeMapEmptyState(
              title: 'Aucun projet chargé',
              description: 'Chargez un projet pour créer et relier ses scènes.',
              icon: Icon(CupertinoIcons.photo),
            ),
          );
        case EditorWorkspaceMode.step:
          return NarrativeStudioWorkspacePage(
            presentation: narrativeStudioRoutePresentationFor(
              EditorWorkspaceMode.step,
            )!,
            body: const PokeMapEmptyState(
              title: 'Aucun projet chargé',
              description:
                  'Chargez un projet pour ouvrir une étape de storyline.',
              icon: Icon(CupertinoIcons.flag),
            ),
          );
        case EditorWorkspaceMode.events:
          // EditorShellPage already owns the Event workspace context bar.
          return const PokeMapEmptyState(
            title: 'Aucun projet chargé',
            description: 'Chargez un projet pour configurer ses événements.',
            icon: Icon(CupertinoIcons.bolt_horizontal_circle),
          );
        case EditorWorkspaceMode.facts:
        case EditorWorkspaceMode.worldRules:
          return NarrativeStudioWorkspacePage(
            presentation: narrativeStudioRoutePresentationFor(
              editor.workspaceMode,
            )!,
            body: const PokeMapEmptyState(
              title: 'Aucun projet chargé',
              description:
                  'Chargez un projet pour gérer ses faits et règles du monde.',
              icon: Icon(CupertinoIcons.doc_text),
            ),
          );
        case EditorWorkspaceMode.cutscene:
          return NarrativeStudioWorkspacePage(
            presentation: narrativeStudioRoutePresentationFor(
              EditorWorkspaceMode.cutscene,
            )!,
            body: const PokeMapEmptyState(
              title: 'Aucun projet chargé',
              description:
                  'Chargez un projet pour ouvrir la bibliothèque et les outils cinématiques.',
              icon: Icon(CupertinoIcons.film),
            ),
          );
        default:
          break;
      }
      return const SizedBox.shrink();
    }

    final selectedGlobal = _resolveScenarioById(
      projection,
      narrative.selectedGlobalStoryId,
      fallback: projection.globalStories.isNotEmpty
          ? projection.globalStories.first
          : null,
    );
    final selectedCutscene = _resolveScenarioById(
      projection,
      narrative.selectedCutsceneId,
      fallback: projection.localEventFlows.isNotEmpty
          ? projection.localEventFlows.first
          : null,
    );
    final selectedStep = _resolveStepById(
      projection,
      narrative.selectedStepId,
      fallback: projection.steps.isNotEmpty ? projection.steps.first : null,
    );

    void openGlobalStory() {
      editorNotifier.selectGlobalStoryWorkspace();
      narrativeController.openGlobalStory(
        scenarioId: selectedGlobal?.id,
      );
    }

    void openScenes() {
      editorNotifier.selectScenesWorkspace();
      narrativeController.openScenes();
    }

    void openCutscene() {
      editorNotifier.selectCutsceneWorkspace();
      narrativeController.openCutscene(
        cutsceneScenarioId: selectedCutscene?.id,
      );
    }

    void openDialogue() {
      editorNotifier.selectDialogueWorkspace();
    }

    void openFacts() {
      editorNotifier.selectFactsWorkspace();
    }

    void openWorldRules() {
      editorNotifier.selectWorldRulesWorkspace();
    }

    AsyncValue<NarrativeActivityJournal>? overviewActivityAsync;
    AsyncValue<NarrativeProjectValidationReport>? overviewValidatorAsync;
    final overviewRootPath = editor.projectRootPath?.trim();
    if (editor.workspaceMode == EditorWorkspaceMode.narrativeOverview &&
        overviewRootPath != null &&
        overviewRootPath.isNotEmpty) {
      overviewActivityAsync = ref.watch(
        narrativeActivityJournalProvider(overviewRootPath),
      );
      overviewValidatorAsync = ref.watch(
        narrativeValidatorReportProvider(
          NarrativeValidatorSnapshotRequest.fromProject(
            projectRootPath: overviewRootPath,
            project: editor.project!,
            activeMap: editor.activeMap,
          ),
        ),
      );
    }

    void openOverviewValidator() {
      ref
          .read(narrativeStudioNavigationControllerProvider.notifier)
          .replace(NarrativeStudioRouteLocation.validator());
      editorNotifier.selectNarrativeValidatorWorkspace();
    }

    void openOverviewDiagnostic(NarrativeOverviewDiagnosticSummary item) {
      ref.read(narrativeStudioNavigationControllerProvider.notifier).replace(
            NarrativeStudioRouteLocation.validator(
              selection: NarrativeStudioAssetSelection(
                kind: NarrativeStudioAssetKind.diagnostic,
                assetId: item.diagnostic.stableKey,
                sourceContext: item.diagnostic.path,
              ),
            ),
          );
      editorNotifier.selectNarrativeValidatorWorkspace();
    }

    void openResumeTarget(NarrativeOverviewResumeTarget target) {
      final assetId = target.assetId?.trim();
      final navigation =
          ref.read(narrativeStudioNavigationControllerProvider.notifier);
      switch (target.destination) {
        case NarrativeActivityDestination.overview:
          editorNotifier.selectNarrativeOverviewWorkspace();
          return;
        case NarrativeActivityDestination.storylines:
          navigation.replace(
            NarrativeStudioRouteLocation.storylines(
              selection: assetId == null || assetId.isEmpty
                  ? null
                  : NarrativeStudioAssetSelection(
                      kind: NarrativeStudioAssetKind.storyline,
                      assetId: assetId,
                    ),
            ),
          );
          editorNotifier.selectGlobalStoryWorkspace();
          return;
        case NarrativeActivityDestination.scenes:
          navigation.replace(
            NarrativeStudioRouteLocation.scenes(
              selection: assetId == null || assetId.isEmpty
                  ? null
                  : NarrativeStudioAssetSelection(
                      kind: NarrativeStudioAssetKind.scene,
                      assetId: assetId,
                    ),
            ),
          );
          editorNotifier.selectScenesWorkspace();
          return;
        case NarrativeActivityDestination.events:
          navigation.replace(
            NarrativeStudioRouteLocation.events(
              selection: assetId == null || assetId.isEmpty
                  ? null
                  : NarrativeStudioAssetSelection(
                      kind: NarrativeStudioAssetKind.event,
                      assetId: assetId,
                    ),
            ),
          );
          editorNotifier.selectEventsWorkspace();
          return;
        case NarrativeActivityDestination.cinematics:
          navigation.replace(
            NarrativeStudioRouteLocation.cinematics(
              selection: assetId == null || assetId.isEmpty
                  ? null
                  : NarrativeStudioAssetSelection(
                      kind: NarrativeStudioAssetKind.cinematic,
                      assetId: assetId,
                    ),
            ),
          );
          editorNotifier.selectCutsceneWorkspace();
          return;
        case NarrativeActivityDestination.dialogues:
          navigation.replace(
            NarrativeStudioRouteLocation.dialogues(
              selection: assetId == null || assetId.isEmpty
                  ? null
                  : NarrativeStudioAssetSelection(
                      kind: NarrativeStudioAssetKind.dialogue,
                      assetId: assetId,
                    ),
            ),
          );
          if (assetId != null && assetId.isNotEmpty) {
            editorNotifier.selectProjectDialogue(assetId);
          }
          editorNotifier.selectDialogueWorkspace();
          return;
        case NarrativeActivityDestination.facts:
          navigation.replace(
            NarrativeStudioRouteLocation.facts(
              selection: assetId == null || assetId.isEmpty
                  ? null
                  : NarrativeStudioAssetSelection(
                      kind: NarrativeStudioAssetKind.fact,
                      assetId: assetId,
                    ),
            ),
          );
          editorNotifier.selectFactsWorkspace();
          return;
        case NarrativeActivityDestination.worldRules:
          navigation.replace(
            NarrativeStudioRouteLocation.worldRules(
              selection: assetId == null || assetId.isEmpty
                  ? null
                  : NarrativeStudioAssetSelection(
                      kind: NarrativeStudioAssetKind.worldRule,
                      assetId: assetId,
                    ),
            ),
          );
          editorNotifier.selectWorldRulesWorkspace();
          return;
        case NarrativeActivityDestination.validator:
          openOverviewValidator();
          return;
      }
    }

    NarrativeStudioReturnExpectation sceneReturnExpectation({
      required String sceneId,
      required String nodeId,
    }) =>
        NarrativeStudioReturnExpectation(
          location: NarrativeStudioRouteLocation.scenes(
            selection: NarrativeStudioAssetSelection(
              kind: NarrativeStudioAssetKind.scene,
              assetId: sceneId,
              focusId: nodeId,
            ),
          ),
          focusAnchorId: nodeId,
        );

    void openSceneDialogue({
      required String sceneId,
      required String nodeId,
      required String assetId,
    }) {
      final project = editor.project;
      if (project == null ||
          !project.dialogues.any((dialogue) => dialogue.id == assetId)) {
        return;
      }
      ref.read(narrativeStudioNavigationControllerProvider.notifier).navigate(
            NarrativeStudioRouteLocation.dialogues(
              selection: NarrativeStudioAssetSelection(
                kind: NarrativeStudioAssetKind.dialogue,
                assetId: assetId,
                parentId: sceneId,
                focusId: nodeId,
              ),
            ),
            returnExpectation: sceneReturnExpectation(
              sceneId: sceneId,
              nodeId: nodeId,
            ),
          );
      editorNotifier.selectProjectDialogue(assetId);
      editorNotifier.selectDialogueWorkspace();
    }

    void openSceneCinematic({
      required String sceneId,
      required String nodeId,
      required String assetId,
    }) {
      final project = editor.project;
      if (project == null ||
          !project.cinematics.any((cinematic) => cinematic.id == assetId)) {
        return;
      }
      ref.read(narrativeStudioNavigationControllerProvider.notifier).navigate(
            NarrativeStudioRouteLocation.cinematics(
              childRoute: NarrativeStudioChildRoute.cinematicBuilder,
              selection: NarrativeStudioAssetSelection(
                kind: NarrativeStudioAssetKind.cinematic,
                assetId: assetId,
                parentId: sceneId,
                focusId: nodeId,
              ),
            ),
            returnExpectation: sceneReturnExpectation(
              sceneId: sceneId,
              nodeId: nodeId,
            ),
          );
      editorNotifier.selectCutsceneWorkspace();
    }

    final selectedSceneRoute = studioNavigation.location.destination ==
                NarrativeStudioDestination.scenes &&
            studioNavigation.location.selection?.kind ==
                NarrativeStudioAssetKind.scene
        ? studioNavigation.location.selection
        : null;
    final sceneRestoration = studioNavigation.restorationRequest;
    final requestedSceneRestoration =
        sceneRestoration?.expectation.location.destination ==
                NarrativeStudioDestination.scenes
            ? sceneRestoration
            : null;

    final mainContent = switch (editor.workspaceMode) {
      EditorWorkspaceMode.narrativeOverview => NarrativeOverviewWorkspace(
          readModel: buildNarrativeOverviewReadModel(
            project: editor.project!,
            activityJournal: overviewActivityAsync?.asData?.value,
            activityJournalAvailability:
                overviewActivityAsync == null || overviewActivityAsync.hasError
                    ? NarrativeOverviewAvailability.unavailable
                    : NarrativeOverviewAvailability.notEvaluated,
            activityJournalStatusMessage: overviewActivityAsync == null
                ? 'Enregistrez le projet pour activer le journal durable.'
                : overviewActivityAsync.hasError
                    ? 'Journal d’activité indisponible : '
                        '${overviewActivityAsync.error}'
                    : 'Chargement du journal d’activité…',
            projectValidationReport: overviewValidatorAsync?.asData?.value,
            validatorAvailability: overviewValidatorAsync == null ||
                    overviewValidatorAsync.hasError
                ? NarrativeOverviewAvailability.unavailable
                : NarrativeOverviewAvailability.notEvaluated,
            validatorStatusMessage: overviewValidatorAsync == null
                ? 'Enregistrez le projet pour lancer le Validator global.'
                : overviewValidatorAsync.hasError
                    ? 'Validator indisponible : ${overviewValidatorAsync.error}'
                    : 'Validation globale en cours…',
          ),
          onOpenStorylines: openGlobalStory,
          onOpenScenes: openScenes,
          onOpenCutscenes: openCutscene,
          onOpenDialogues: openDialogue,
          onOpenFacts: openFacts,
          onOpenWorldRules: openWorldRules,
          onResumeEditing: openResumeTarget,
          onOpenActivity: (entry) => openResumeTarget(
            NarrativeOverviewResumeTarget(
              label: entry.label,
              destination: entry.destination,
              sourceLabel: 'Journal d’activité durable',
              assetId: entry.assetId,
            ),
          ),
          onOpenDiagnostic: openOverviewDiagnostic,
          onOpenValidator: openOverviewValidator,
        ),
      EditorWorkspaceMode.globalStory => StorylinesWorkspace(
          projection: projection,
          selectedGlobalStoryId: narrative.selectedGlobalStoryId,
          requestedSelection: studioNavigation.location.destination ==
                  NarrativeStudioDestination.storylines
              ? studioNavigation.location.selection
              : null,
          requestedSelectionNonce: studioNavigation.revision,
        ),
      EditorWorkspaceMode.scenes => ScenesWorkspace(
          scenes: projection.scenes,
          requestedSceneId: selectedSceneRoute?.assetId ?? sceneFocus?.sceneId,
          requestedNodeId: selectedSceneRoute?.focusId,
          requestedSceneFocusNonce: selectedSceneRoute == null
              ? sceneFocus?.nonce
              : studioNavigation.revision,
          strictRequestedSceneFocus: selectedSceneRoute != null,
          requestedFocusAnchorId:
              requestedSceneRestoration?.expectation.focusAnchorId,
          requestedRestorationRevision: requestedSceneRestoration?.revision,
          onRestorationApplied: (revision) => ref
              .read(narrativeStudioNavigationControllerProvider.notifier)
              .consumeRestoration(revision),
          linkedAssetContracts: editor.project == null
              ? null
              : buildLinkedAssetContractsSnapshot(editor.project!),
          cinematicsLibrary: editor.project == null
              ? null
              : buildCinematicsLibraryReadModel(editor.project!),
          conditionSourceOptions: editor.project == null
              ? const []
              : _buildSceneConditionSourceOptions(
                  editor.project!,
                  activeMap: editor.activeMap,
                ),
          consequenceFactOptions: editor.project == null
              ? const []
              : _buildSceneConsequenceFactOptions(editor.project!),
          consequenceEventOptions: editor.project == null
              ? const []
              : _buildSceneConsequenceEventOptions(
                  editor.project!,
                  activeMap: editor.activeMap,
                ),
          consequenceCatalogs: sceneConsequenceCatalogs,
          actionPickerOptions: editor.project == null
              ? const {}
              : _buildSceneActionPickerOptions(
                  editor.project!,
                  sceneConsequenceCatalogs,
                  activeMap: editor.activeMap,
                ),
          sceneConsumerPaths: editor.project == null
              ? const <String, List<String>>{}
              : _buildSceneConsumerPaths(
                  editor.project!,
                  activeMap: editor.activeMap,
                ),
          onEditScene: ({
            required String sceneId,
            required String name,
            required SceneLibraryLocation location,
            required List<String> tags,
            required List<SceneOutcome> declaredOutcomes,
          }) async {
            final project = editor.project;
            if (project == null) return null;
            final renamed = renameSceneInProject(
              project,
              sceneId: sceneId,
              name: name,
            );
            if (renamed.disposition ==
                SceneLibraryMutationDisposition.rejected) {
              return renamed;
            }
            final classified = updateSceneLibraryClassification(
              renamed.after,
              sceneId: sceneId,
              location: location,
              tags: tags,
              declaredOutcomes: declaredOutcomes,
            );
            if (classified.disposition ==
                SceneLibraryMutationDisposition.rejected) {
              return classified;
            }
            editorNotifier.applyInMemoryProjectManifest(
              classified.after,
              statusMessage: 'Scene library metadata updated',
            );
            return classified;
          },
          onDuplicateScene: ({required String sceneId}) async {
            final project = editor.project;
            if (project == null) return null;
            final result = duplicateSceneInProject(project, sceneId: sceneId);
            if (result.isApplied) {
              editorNotifier.applyInMemoryProjectManifest(
                result.after,
                statusMessage: 'Scene duplicated',
              );
            }
            return result;
          },
          onToggleArchiveScene: ({
            required String sceneId,
            required bool archived,
          }) async {
            final project = editor.project;
            if (project == null) return null;
            final result = archived
                ? archiveSceneInProject(project, sceneId: sceneId)
                : restoreSceneInProject(project, sceneId: sceneId);
            if (result.isApplied) {
              editorNotifier.applyInMemoryProjectManifest(
                result.after,
                statusMessage: archived ? 'Scene archived' : 'Scene restored',
              );
            }
            return result;
          },
          onDeleteScene: ({
            required String sceneId,
            String? replacementSceneId,
          }) async {
            final project = editor.project;
            if (project == null) return null;
            final maps = editor.activeMap == null
                ? const <MapData>[]
                : <MapData>[editor.activeMap!];
            final result = deleteSceneFromProject(
              project,
              sceneId: sceneId,
              replacementSceneId: replacementSceneId,
              dependencyIndex: buildNarrativeDependencyIndex(
                project: project,
                maps: maps,
              ),
            );
            if (result.isApplied) {
              editorNotifier.applyInMemoryProjectManifest(
                result.after,
                statusMessage: 'Scene deleted safely',
              );
            }
            return result;
          },
          onCreateSceneDraft: ({
            required String name,
            String? description,
          }) async {
            final project = editor.project;
            if (project == null) {
              return null;
            }
            final result = createSceneDraftInProject(
              project,
              name: name,
              description: description,
            );
            editorNotifier.applyInMemoryProjectManifest(
              result.updatedProject,
              statusMessage: 'Scene draft created',
            );
            return result.createdScene.id;
          },
          onAddNodeDraft: ({
            required String sceneId,
            required SceneNodeKind kind,
          }) async {
            final project = editor.project;
            if (project == null) {
              return null;
            }
            final sceneIndex =
                project.scenes.indexWhere((scene) => scene.id == sceneId);
            if (sceneIndex < 0) {
              return null;
            }
            final result = addSceneNodeDraft(
              project.scenes[sceneIndex],
              kind: kind,
            );
            final scenes = project.scenes.toList(growable: true);
            scenes[sceneIndex] = result.updatedScene;
            editorNotifier.applyInMemoryProjectManifest(
              project.copyWith(scenes: scenes),
              statusMessage: 'Scene node draft added',
            );
            return result.createdNode.id;
          },
          onAddLinkedAssetNodeDraft: ({
            required String sceneId,
            required SceneNodePayload payload,
            String? title,
          }) async {
            final project = editor.project;
            if (project == null) {
              return null;
            }
            final sceneIndex =
                project.scenes.indexWhere((scene) => scene.id == sceneId);
            if (sceneIndex < 0) {
              return null;
            }
            try {
              final result = switch (payload) {
                SceneActionPayload() => () {
                    final created = addSceneCommandActionNodeDraft(
                      project.scenes[sceneIndex],
                      payload: payload,
                      title: title,
                    );
                    return (
                      updatedScene: created.updatedScene,
                      createdNode: created.createdNode,
                    );
                  }(),
                SceneCinematicPayload() => () {
                    final created = addSceneCinematicNodeDraft(
                      project.scenes[sceneIndex],
                      project: project,
                      cinematicId: payload.cinematicId,
                      title: title,
                    );
                    return (
                      updatedScene: created.updatedScene,
                      createdNode: created.createdNode,
                    );
                  }(),
                _ => () {
                    final created = addSceneLinkedAssetNodeDraft(
                      project.scenes[sceneIndex],
                      payload: payload,
                      title: title,
                    );
                    return (
                      updatedScene: created.updatedScene,
                      createdNode: created.createdNode,
                    );
                  }(),
              };
              final scenes = project.scenes.toList(growable: true);
              scenes[sceneIndex] = result.updatedScene;
              editorNotifier.applyInMemoryProjectManifest(
                project.copyWith(scenes: scenes),
                statusMessage: 'Scene linked asset node draft added',
              );
              return result.createdNode.id;
            } on ArgumentError {
              return null;
            }
          },
          onAddConsequenceActionNodeDraft: ({
            required String sceneId,
            required SceneConsequence consequence,
            String? title,
          }) async {
            final project = editor.project;
            if (project == null) {
              return null;
            }
            final sceneIndex =
                project.scenes.indexWhere((scene) => scene.id == sceneId);
            if (sceneIndex < 0) {
              return null;
            }
            try {
              final result = addSceneConsequenceActionNodeDraft(
                project.scenes[sceneIndex],
                consequence: consequence,
                title: title,
              );
              final scenes = project.scenes.toList(growable: true);
              scenes[sceneIndex] = result.updatedScene;
              editorNotifier.applyInMemoryProjectManifest(
                project.copyWith(scenes: scenes),
                statusMessage: 'Scene consequence action node added',
              );
              return result.createdNode.id;
            } on ArgumentError {
              return null;
            }
          },
          onAddEdgeDraft: ({
            required String sceneId,
            required String fromNodeId,
            required String fromPortId,
            required String toNodeId,
          }) async {
            final project = editor.project;
            if (project == null) {
              return null;
            }
            final sceneIndex =
                project.scenes.indexWhere((scene) => scene.id == sceneId);
            if (sceneIndex < 0) {
              return null;
            }
            try {
              final result = addSceneEdgeDraft(
                project.scenes[sceneIndex],
                fromNodeId: fromNodeId,
                fromPortId: fromPortId,
                toNodeId: toNodeId,
              );
              final scenes = project.scenes.toList(growable: true);
              scenes[sceneIndex] = result.updatedScene;
              editorNotifier.applyInMemoryProjectManifest(
                project.copyWith(scenes: scenes),
                statusMessage: 'Scene edge draft added',
              );
              return result.createdEdge.id;
            } on ArgumentError {
              return null;
            }
          },
          onRemoveEdgeDraft: ({
            required String sceneId,
            required String edgeId,
          }) async {
            final project = editor.project;
            if (project == null) {
              return false;
            }
            final sceneIndex =
                project.scenes.indexWhere((scene) => scene.id == sceneId);
            if (sceneIndex < 0) {
              return false;
            }
            try {
              final result = removeSceneEdgeDraft(
                project.scenes[sceneIndex],
                edgeId,
              );
              final scenes = project.scenes.toList(growable: true);
              scenes[sceneIndex] = result.updatedScene;
              editorNotifier.applyInMemoryProjectManifest(
                project.copyWith(scenes: scenes),
                statusMessage: 'Scene edge draft removed',
              );
              return true;
            } on ArgumentError {
              return false;
            }
          },
          onRemoveNodeDraft: ({
            required String sceneId,
            required String nodeId,
          }) async {
            final project = editor.project;
            if (project == null) {
              return false;
            }
            final sceneIndex =
                project.scenes.indexWhere((scene) => scene.id == sceneId);
            if (sceneIndex < 0) {
              return false;
            }
            try {
              final result = removeSceneNodeDraft(
                project.scenes[sceneIndex],
                nodeId,
              );
              final scenes = project.scenes.toList(growable: true);
              scenes[sceneIndex] = result.updatedScene;
              editorNotifier.applyInMemoryProjectManifest(
                project.copyWith(scenes: scenes),
                statusMessage: 'Scene node draft removed',
              );
              return true;
            } on ArgumentError {
              return false;
            }
          },
          onDuplicateNodeDraft: ({
            required String sceneId,
            required String nodeId,
          }) async {
            final project = editor.project;
            if (project == null) return null;
            final sceneIndex =
                project.scenes.indexWhere((scene) => scene.id == sceneId);
            if (sceneIndex < 0) return null;
            try {
              final result = duplicateSceneNodeDraft(
                project.scenes[sceneIndex],
                nodeId,
              );
              final scenes = project.scenes.toList(growable: true);
              scenes[sceneIndex] = result.updatedScene;
              editorNotifier.applyInMemoryProjectManifest(
                project.copyWith(scenes: scenes),
                statusMessage: 'Scene node draft duplicated',
              );
              return result.createdNode.id;
            } on ArgumentError {
              return null;
            }
          },
          onUpdateNodeLayout: ({
            required String sceneId,
            required String nodeId,
            required double x,
            required double y,
          }) async {
            final project = editor.project;
            if (project == null) {
              return;
            }
            final sceneIndex =
                project.scenes.indexWhere((scene) => scene.id == sceneId);
            if (sceneIndex < 0) {
              return;
            }
            try {
              final result = updateSceneNodeLayout(
                project.scenes[sceneIndex],
                nodeId: nodeId,
                x: x,
                y: y,
              );
              final scenes = project.scenes.toList(growable: true);
              scenes[sceneIndex] = result.updatedScene;
              editorNotifier.applyInMemoryProjectManifest(
                project.copyWith(scenes: scenes),
                statusMessage: 'Scene node layout updated',
              );
            } on ArgumentError {
              return;
            }
          },
          onUpdateConditionSource: ({
            required String sceneId,
            required String nodeId,
            required SceneConditionSource source,
          }) async {
            final project = editor.project;
            if (project == null) {
              return false;
            }
            final sceneIndex =
                project.scenes.indexWhere((scene) => scene.id == sceneId);
            if (sceneIndex < 0) {
              return false;
            }
            try {
              final result = updateSceneConditionSource(
                project.scenes[sceneIndex],
                nodeId: nodeId,
                source: source,
              );
              final scenes = project.scenes.toList(growable: true);
              scenes[sceneIndex] = result.updatedScene;
              editorNotifier.applyInMemoryProjectManifest(
                project.copyWith(scenes: scenes),
                statusMessage: 'Scene condition source updated',
              );
              return true;
            } on ArgumentError {
              return false;
            }
          },
          onUpdateYarnDialoguePayload: ({
            required String sceneId,
            required String nodeId,
            required String dialogueId,
            String? yarnNodeName,
            required List<String> expectedOutcomes,
          }) async {
            final project = editor.project;
            if (project == null) {
              return false;
            }
            final sceneIndex =
                project.scenes.indexWhere((scene) => scene.id == sceneId);
            if (sceneIndex < 0) {
              return false;
            }
            try {
              final result = updateSceneYarnDialoguePayload(
                project.scenes[sceneIndex],
                nodeId: nodeId,
                dialogueId: dialogueId,
                yarnNodeName: yarnNodeName,
                expectedOutcomes: expectedOutcomes,
              );
              final scenes = project.scenes.toList(growable: true);
              scenes[sceneIndex] = result.updatedScene;
              editorNotifier.applyInMemoryProjectManifest(
                project.copyWith(scenes: scenes),
                statusMessage: 'Scene dialogue payload updated',
              );
              return true;
            } on ArgumentError {
              return false;
            }
          },
          onUpdateEndPayload: ({
            required String sceneId,
            required String nodeId,
            String? sceneOutcomeId,
            required SceneOutcomePolicy? outcomePolicy,
          }) async {
            final project = editor.project;
            if (project == null) return false;
            final sceneIndex =
                project.scenes.indexWhere((scene) => scene.id == sceneId);
            if (sceneIndex < 0) return false;
            try {
              final result = updateSceneEndPayload(
                project.scenes[sceneIndex],
                nodeId: nodeId,
                sceneOutcomeId: sceneOutcomeId,
                outcomePolicy: outcomePolicy,
              );
              final scenes = project.scenes.toList(growable: true);
              scenes[sceneIndex] = result.updatedScene;
              editorNotifier.applyInMemoryProjectManifest(
                project.copyWith(scenes: scenes),
                statusMessage: 'Scene outcome policy updated',
              );
              return true;
            } on ArgumentError {
              return false;
            }
          },
          onUpdateBattlePayload: ({
            required String sceneId,
            required String nodeId,
            required String trainerId,
          }) async {
            final project = editor.project;
            if (project == null) {
              return false;
            }
            final sceneIndex =
                project.scenes.indexWhere((scene) => scene.id == sceneId);
            if (sceneIndex < 0) {
              return false;
            }
            try {
              final result = updateSceneBattlePayload(
                project.scenes[sceneIndex],
                nodeId: nodeId,
                trainerId: trainerId,
              );
              final scenes = project.scenes.toList(growable: true);
              scenes[sceneIndex] = result.updatedScene;
              editorNotifier.applyInMemoryProjectManifest(
                project.copyWith(scenes: scenes),
                statusMessage: 'Scene battle payload updated',
              );
              return true;
            } on ArgumentError {
              return false;
            }
          },
          onUpdateCinematicPayload: ({
            required String sceneId,
            required String nodeId,
            required String cinematicId,
          }) async {
            final project = editor.project;
            if (project == null) {
              return false;
            }
            final sceneIndex =
                project.scenes.indexWhere((scene) => scene.id == sceneId);
            if (sceneIndex < 0) {
              return false;
            }
            try {
              final result = updateSceneCinematicPayload(
                project.scenes[sceneIndex],
                nodeId: nodeId,
                cinematicId: cinematicId,
                project: project,
              );
              final scenes = project.scenes.toList(growable: true);
              scenes[sceneIndex] = result.updatedScene;
              editorNotifier.applyInMemoryProjectManifest(
                project.copyWith(scenes: scenes),
                statusMessage: 'Scene cinematic payload updated',
              );
              return true;
            } on ArgumentError {
              return false;
            }
          },
          onUpdateActionConsequence: ({
            required String sceneId,
            required String nodeId,
            required SceneConsequence consequence,
          }) async {
            final project = editor.project;
            if (project == null) {
              return false;
            }
            final sceneIndex =
                project.scenes.indexWhere((scene) => scene.id == sceneId);
            if (sceneIndex < 0) {
              return false;
            }
            try {
              final result = updateSceneActionConsequencePayload(
                project.scenes[sceneIndex],
                nodeId: nodeId,
                consequence: consequence,
              );
              final scenes = project.scenes.toList(growable: true);
              scenes[sceneIndex] = result.updatedScene;
              editorNotifier.applyInMemoryProjectManifest(
                project.copyWith(scenes: scenes),
                statusMessage: 'Scene consequence payload updated',
              );
              return true;
            } on ArgumentError {
              return false;
            }
          },
          onOpenDialogue: openSceneDialogue,
          onOpenCinematic: openSceneCinematic,
        ),
      EditorWorkspaceMode.events => LayoutBuilder(
          builder: (context, constraints) => EventBuilderV2ProductRoute(
            viewportWidth: MediaQuery.sizeOf(context).width,
            availableWidth: constraints.maxWidth,
            legacyWorkspace: (editor.project?.eventRegistry?.mode ??
                        EventSystemMode.legacyOnly) ==
                    EventSystemMode.legacyOnly
                ? EventBuilderWorkspace(
                    readModel: _buildEventBuilderWorkspaceReadModel(editor),
                    selectedEventId: editor.selectedMapEventId,
                    draftCreationGate: _buildEventBuilderDraftCreationGate(
                      editor,
                      editorNotifier,
                    ),
                    sceneOptions:
                        _buildEventBuilderSceneOptions(editor.project),
                    factOptions: _buildEventBuilderFactOptions(editor.project),
                    eventConditionOptions:
                        _buildEventBuilderConditionEventOptions(
                            editor.activeMap),
                    mapOptions: _buildEventBuilderMapOptions(editor.project),
                    onOpenMap: (mapId) async {
                      final entry = _findProjectMapById(editor.project, mapId);
                      if (entry == null) {
                        return;
                      }
                      await editorNotifier.loadMap(entry.relativePath);
                      editorNotifier.selectEventsWorkspace();
                    },
                    onSelectEvent: editorNotifier.selectMapEvent,
                    onRenameEventTitle:
                        editorNotifier.renameEventBuilderEventTitle,
                    onUpdateTriggerType:
                        editorNotifier.updateEventBuilderTriggerType,
                    onUpdateSceneAction:
                        editorNotifier.updateEventBuilderEventSceneAction,
                    onUpdateReusePolicy:
                        editorNotifier.updateEventBuilderEventReusePolicy,
                    onAddFactCondition:
                        editorNotifier.addEventBuilderFactCondition,
                    onAddEventConsumedCondition:
                        editorNotifier.addEventBuilderEventConsumedCondition,
                    onRemoveCondition:
                        editorNotifier.removeEventBuilderConditionAt,
                    onCreateDestinationLayer:
                        editorNotifier.ensureEventBuilderObjectLayer,
                  )
                : null,
          ),
        ),
      EditorWorkspaceMode.step => _StepWorkspaceBody(
          projection: projection,
          selectedStep: selectedStep,
          onSelectStep: (stepId) {
            final step = projection.steps
                .where((s) => s.id == stepId)
                .cast<NarrativeStepSummary?>()
                .firstWhere((s) => s != null, orElse: () => null);
            narrativeController.selectStep(stepId);
            narrativeController.openStep(
              stepId: stepId,
              globalScenarioId: step?.globalScenarioId,
            );
          },
          onSelectOutcome: narrativeController.selectOutcome,
          onOpenCutsceneStudio: (cutsceneScenarioId) {
            // Même séquence que la bibliothèque narrative : sélection +
            // état de vue, puis bascule du workspace éditeur.
            narrativeController.selectCutscene(cutsceneScenarioId);
            narrativeController.openCutscene(
              cutsceneScenarioId: cutsceneScenarioId,
            );
            editorNotifier.selectCutsceneWorkspace();
          },
          editorNotifier: editorNotifier,
          project: editor.project,
          activeMap: editor.activeMap,
        ),
      EditorWorkspaceMode.cutscene => _CinematicsWorkspaceBody(
          editorNotifier: editorNotifier,
          projectRootPath: editor.projectRootPath,
          project: editor.project,
          activeMap: editor.activeMap,
          projection: projection,
          selectedCutscene: selectedCutscene,
          requestedCinematicId: studioNavigation.location.destination ==
                      NarrativeStudioDestination.cinematics &&
                  studioNavigation.location.selection?.kind ==
                      NarrativeStudioAssetKind.cinematic
              ? studioNavigation.location.selection?.assetId
              : null,
          requestedCinematicNonce: studioNavigation.revision,
          requestedCinematicChildRoute: studioNavigation.location.destination ==
                  NarrativeStudioDestination.cinematics
              ? studioNavigation.location.childRoute
              : NarrativeStudioChildRoute.cinematicLibrary,
          onRouteChanged: ref
              .read(narrativeStudioNavigationControllerProvider.notifier)
              .replace,
          onSelectCutscene: (scenarioId) {
            narrativeController.selectCutscene(scenarioId);
            narrativeController.openCutscene(
              cutsceneScenarioId: scenarioId,
            );
          },
          onSelectOutcome: narrativeController.selectOutcome,
          onOpenSceneUsage: ({required sceneId, required nodeId}) {
            ref
                .read(narrativeStudioNavigationControllerProvider.notifier)
                .replace(
                  NarrativeStudioRouteLocation.scenes(
                    selection: NarrativeStudioAssetSelection(
                      kind: NarrativeStudioAssetKind.scene,
                      assetId: sceneId,
                      focusId: nodeId,
                    ),
                  ),
                );
            editorNotifier.selectScenesWorkspace();
          },
        ),
      EditorWorkspaceMode.dialogue => const DialogueStudioWorkspace(),
      EditorWorkspaceMode.facts => _buildFactsWorldRulesWorkspace(
          editor: editor,
          editorNotifier: editorNotifier,
          mapRepository: ref.read(mapRepositoryProvider),
          readLatestProject: () => ref.read(editorNotifierProvider).project,
          initialMode: FactsWorldRulesWorkspaceMode.facts,
          requestedFactId: studioNavigation.location.destination ==
                      NarrativeStudioDestination.facts &&
                  studioNavigation.location.selection?.kind ==
                      NarrativeStudioAssetKind.fact
              ? studioNavigation.location.selection?.assetId
              : null,
          requestedSelectionNonce: studioNavigation.revision,
        ),
      EditorWorkspaceMode.worldRules => _buildFactsWorldRulesWorkspace(
          editor: editor,
          editorNotifier: editorNotifier,
          mapRepository: ref.read(mapRepositoryProvider),
          readLatestProject: () => ref.read(editorNotifierProvider).project,
          initialMode: FactsWorldRulesWorkspaceMode.worldRules,
          requestedWorldRuleId: studioNavigation.location.destination ==
                      NarrativeStudioDestination.worldRules &&
                  studioNavigation.location.selection?.kind ==
                      NarrativeStudioAssetKind.worldRule
              ? studioNavigation.location.selection?.assetId
              : null,
          requestedSelectionNonce: studioNavigation.revision,
        ),
      // Workspaces non narratifs: ce widget ne doit pas être utilisé.
      _ => const SizedBox.shrink(),
    };

    // Every Narrative Studio destination now owns its shared inner page and is
    // mounted in the single product shell by EditorShellPage. Returning the
    // business route directly makes the historical nested shell impossible.
    return mainContent;
  }
}

EventBuilderReadModel _buildEventBuilderWorkspaceReadModel(
  EditorState editor,
) {
  final project = editor.project;
  final activeMap = editor.activeMap;
  return buildEventBuilderReadModel(
    events: activeMap?.events ?? const <MapEventDefinition>[],
    mapId: activeMap?.id,
    mapTitle: activeMap?.name,
    sceneLabels: {
      for (final scene in project?.scenes ?? const <SceneAsset>[])
        scene.id: scene.name,
    },
    scenes: {
      for (final scene in project?.scenes ?? const <SceneAsset>[])
        scene.id: scene,
    },
    worldRules: project?.worldRules ?? const <WorldRuleDefinition>[],
    factLabels: {
      for (final fact in project?.facts ?? const <NarrativeFactDefinition>[])
        fact.id: fact.label.trim().isEmpty ? fact.id : fact.label.trim(),
    },
    eventLabels: {
      for (final event in activeMap?.events ?? const <MapEventDefinition>[])
        event.id: event.title.trim().isEmpty ? event.id : event.title,
    },
  );
}

EventBuilderDraftCreationGate _buildEventBuilderDraftCreationGate(
  EditorState editor,
  EditorNotifier editorNotifier,
) {
  final activeMap = editor.activeMap;
  if (activeMap == null) {
    return const EventBuilderDraftCreationGate.disabled(
      disabledReason:
          'Ouvrez une map active pour choisir la position de l’événement.',
    );
  }
  final activeLayerId = editor.activeLayerId?.trim();
  final activeLayer = activeLayerId == null || activeLayerId.isEmpty
      ? null
      : _findMapLayerById(activeMap, activeLayerId);
  final destinationLayers = _buildEventDestinationLayerOptions(activeMap);
  final activeObjectLayer = activeLayer is ObjectLayer
      ? EventBuilderDestinationLayerOption(
          id: activeLayer.id,
          label: _mapLayerLabel(activeLayer),
        )
      : null;
  final autoResolvedLayer = destinationLayers.length == 1;
  final resolvedLayer = activeObjectLayer ??
      (autoResolvedLayer ? destinationLayers.single : null);
  return EventBuilderDraftCreationGate.positionPicker(
    mapId: activeMap.id,
    mapWidth: activeMap.size.width,
    mapHeight: activeMap.size.height,
    layerId: resolvedLayer?.id,
    layerLabel: resolvedLayer?.label,
    layerValid: resolvedLayer != null,
    destinationLayerOptions: destinationLayers,
    autoResolvedLayer: autoResolvedLayer,
    onCreateDraftAt: (position) {
      return editorNotifier
          .createEventBuilderDraftEventAt(position: position)
          ?.id;
    },
  );
}

List<EventBuilderSceneOption> _buildEventBuilderSceneOptions(
  ProjectManifest? project,
) {
  return [
    for (final scene in project?.scenes ?? const <SceneAsset>[])
      EventBuilderSceneOption(
        id: scene.id,
        label: scene.name.trim().isEmpty ? scene.id : scene.name.trim(),
      ),
  ];
}

List<EventBuilderMapOption> _buildEventBuilderMapOptions(
  ProjectManifest? project,
) {
  return [
    for (final map in project?.maps ?? const <ProjectMapEntry>[])
      EventBuilderMapOption(
        id: map.id,
        label: map.name.trim().isEmpty ? map.id : map.name.trim(),
      ),
  ];
}

ProjectMapEntry? _findProjectMapById(ProjectManifest? project, String mapId) {
  final normalizedMapId = mapId.trim();
  if (project == null || normalizedMapId.isEmpty) {
    return null;
  }
  for (final map in project.maps) {
    if (map.id == normalizedMapId) {
      return map;
    }
  }
  return null;
}

List<EventBuilderFactOption> _buildEventBuilderFactOptions(
  ProjectManifest? project,
) {
  return [
    for (final fact in project?.facts ?? const <NarrativeFactDefinition>[])
      EventBuilderFactOption(
        id: fact.id,
        label: fact.label.trim().isEmpty ? fact.id : fact.label.trim(),
      ),
  ];
}

List<EventBuilderConditionEventOption> _buildEventBuilderConditionEventOptions(
  MapData? map,
) {
  return [
    for (final event in map?.events ?? const <MapEventDefinition>[])
      EventBuilderConditionEventOption(
        id: event.id,
        label: event.title.trim().isEmpty ? event.id : event.title.trim(),
      ),
  ];
}

MapLayer? _findMapLayerById(MapData map, String layerId) {
  for (final layer in map.layers) {
    if (layer.id == layerId) {
      return layer;
    }
  }
  return null;
}

List<EventBuilderDestinationLayerOption> _buildEventDestinationLayerOptions(
  MapData map,
) {
  return [
    for (final layer in map.layers)
      if (layer is ObjectLayer)
        EventBuilderDestinationLayerOption(
          id: layer.id,
          label: _mapLayerLabel(layer),
        ),
  ];
}

String _mapLayerLabel(MapLayer layer) {
  final label = layer.name.trim();
  return label.isEmpty ? layer.id : label;
}

Widget _buildFactsWorldRulesWorkspace({
  required EditorState editor,
  required EditorNotifier editorNotifier,
  required MapRepository mapRepository,
  required ProjectManifest? Function() readLatestProject,
  required FactsWorldRulesWorkspaceMode initialMode,
  String? requestedFactId,
  String? requestedWorldRuleId,
  int? requestedSelectionNonce,
}) {
  final project = editor.project;
  if (project == null) {
    return const SizedBox.shrink();
  }
  final projectRootPath = editor.projectRootPath;
  if (projectRootPath == null || projectRootPath.trim().isEmpty) {
    return _buildFactsWorldRulesWorkspaceFromSnapshot(
      editor: editor,
      editorNotifier: editorNotifier,
      readLatestProject: readLatestProject,
      project: project,
      maps: editor.activeMap == null ? const [] : [editor.activeMap!],
      initialMode: initialMode,
      requestedFactId: requestedFactId,
      requestedWorldRuleId: requestedWorldRuleId,
      requestedSelectionNonce: requestedSelectionNonce,
    );
  }
  return FutureBuilder<NarrativeProjectSnapshot>(
    future: NarrativeProjectSnapshotLoader(mapRepository: mapRepository).load(
      project: project,
      projectRootPath: projectRootPath,
      activeMap: editor.activeMap,
    ),
    builder: (context, snapshot) {
      if (!snapshot.hasData && !snapshot.hasError) {
        return const Center(
          child: PokeMapEmptyState(
            title: 'Chargement du projet narratif',
            description: 'Lecture des maps du projet…',
            icon: Icon(CupertinoIcons.arrow_2_circlepath),
          ),
        );
      }
      if (snapshot.hasError) {
        return const Center(
          child: PokeMapEmptyState(
            title: 'Projet narratif incomplet',
            description:
                'Impossible de charger toutes les maps. Corrigez le manifeste avant d’éditer les règles du monde.',
            icon: Icon(CupertinoIcons.exclamationmark_triangle),
          ),
        );
      }
      final maps = snapshot.requireData.maps;
      return _buildFactsWorldRulesWorkspaceFromSnapshot(
        editor: editor,
        editorNotifier: editorNotifier,
        readLatestProject: readLatestProject,
        project: project,
        maps: maps,
        initialMode: initialMode,
        requestedFactId: requestedFactId,
        requestedWorldRuleId: requestedWorldRuleId,
        requestedSelectionNonce: requestedSelectionNonce,
      );
    },
  );
}

Widget _buildFactsWorldRulesWorkspaceFromSnapshot({
  required EditorState editor,
  required EditorNotifier editorNotifier,
  required ProjectManifest? Function() readLatestProject,
  required ProjectManifest project,
  required List<MapData> maps,
  required FactsWorldRulesWorkspaceMode initialMode,
  String? requestedFactId,
  String? requestedWorldRuleId,
  int? requestedSelectionNonce,
}) {
  return FactsWorldRulesWorkspace(
    project: project,
    activeMap: editor.activeMap,
    maps: maps,
    initialMode: initialMode,
    requestedFactId: requestedFactId,
    requestedWorldRuleId: requestedWorldRuleId,
    requestedSelectionNonce: requestedSelectionNonce,
    onCreateFact: ({required String label}) async {
      try {
        final result = addNarrativeFact(project, label: label);
        editorNotifier.applyInMemoryProjectManifest(
          result.updatedProject,
          statusMessage: 'Fact created',
        );
        return result.createdFact.id;
      } on ArgumentError {
        return null;
      }
    },
    onDuplicateFact: ({required String factId}) async {
      try {
        final latest = readLatestProject();
        if (latest == null) {
          return null;
        }
        final result = duplicateNarrativeFact(latest, factId: factId);
        editorNotifier.applyInMemoryProjectManifest(
          result.updatedProject,
          statusMessage: 'Fact duplicated',
        );
        return result.createdFact.id;
      } on ArgumentError {
        return null;
      }
    },
    onUpdateFact: ({
      required String factId,
      required String label,
      required String description,
      required String category,
      required NarrativeValue initialValue,
    }) async {
      try {
        final latest = readLatestProject();
        if (latest == null) {
          return false;
        }
        final current = latest.facts.firstWhere((fact) => fact.id == factId);
        final preview = current.valueKind == initialValue.kind
            ? null
            : previewNarrativeFactTypeChange(
                latest,
                factId: factId,
                nextKind: initialValue.kind,
                maps: maps,
              );
        final result = updateNarrativeFact(
          latest,
          factId: factId,
          label: label,
          description: description,
          category: category,
          initialValue: initialValue,
          typeChangePreview: preview,
        );
        editorNotifier.applyInMemoryProjectManifest(
          result.updatedProject,
          statusMessage: 'Fact updated',
        );
        return true;
      } on ArgumentError {
        return false;
      }
    },
    onRemoveFact: ({required String factId}) async {
      try {
        final latest = readLatestProject();
        if (latest == null) {
          return false;
        }
        final result = removeNarrativeFact(
          latest,
          factId: factId,
          maps: maps,
          dependencyIndex: buildNarrativeDependencyIndex(
            project: latest,
            maps: maps,
          ),
        );
        editorNotifier.applyInMemoryProjectManifest(
          result.updatedProject,
          statusMessage: 'Fact removed',
        );
        return true;
      } on ArgumentError {
        return false;
      }
    },
    onCreateWorldRule: ({
      required String label,
      required String description,
      required bool enabled,
      required WorldRuleSource source,
      required WorldRuleTarget target,
      required WorldRuleEffect effect,
      required int priority,
    }) async {
      try {
        final latest = readLatestProject();
        if (latest == null) {
          return null;
        }
        final result = addWorldRule(
          latest,
          label: label,
          description: description,
          enabled: enabled,
          source: source,
          target: target,
          effect: effect,
          priority: priority,
          maps: maps,
        );
        editorNotifier.applyInMemoryProjectManifest(
          result.updatedProject,
          statusMessage: 'World rule created',
        );
        return result.createdRule.id;
      } on ArgumentError {
        return null;
      }
    },
    onUpdateWorldRule: ({
      required String ruleId,
      required String label,
      required String description,
      required bool enabled,
      required WorldRuleSource source,
      required WorldRuleTarget target,
      required WorldRuleEffect effect,
      required int priority,
    }) async {
      try {
        final latest = readLatestProject();
        if (latest == null) {
          return false;
        }
        final result = updateWorldRule(
          latest,
          ruleId: ruleId,
          label: label,
          description: description,
          enabled: enabled,
          source: source,
          target: target,
          effect: effect,
          priority: priority,
          maps: maps,
        );
        editorNotifier.applyInMemoryProjectManifest(
          result.updatedProject,
          statusMessage: 'World rule updated',
        );
        return true;
      } on ArgumentError {
        return false;
      }
    },
    onRemoveWorldRule: ({required String ruleId}) async {
      try {
        final latest = readLatestProject();
        if (latest == null) {
          return false;
        }
        final result = removeWorldRule(latest, ruleId: ruleId);
        editorNotifier.applyInMemoryProjectManifest(
          result.updatedProject,
          statusMessage: 'World rule removed',
        );
        return true;
      } on ArgumentError {
        return false;
      }
    },
  );
}

List<SceneConditionSourcePickerOption> _buildSceneConditionSourceOptions(
  ProjectManifest project, {
  MapData? activeMap,
}) {
  final optionsByKey = <String, SceneConditionSourcePickerOption>{};

  void add(SceneConditionSourcePickerOption option) {
    final sourceId = option.sourceId.trim();
    if (sourceId.isEmpty) {
      return;
    }
    optionsByKey.putIfAbsent(
      '${option.sourceKind.name}:$sourceId',
      () => option,
    );
  }

  for (final fact in project.facts) {
    add(
      SceneConditionSourcePickerOption(
        sourceKind: SceneConditionSourceKind.fact,
        sourceId: fact.id,
        label: fact.label,
        debugTechnicalLabel: fact.legacyFlagName ?? fact.id,
        valueKind: fact.valueKind,
        initialValue: fact.initialValue,
        description: fact.description,
        category: fact.category,
      ),
    );
  }

  for (final reference in buildNarrativePredicateReferencePickerOptions(
    project,
  )) {
    if (reference.referenceKind != NarrativePredicateReferenceKind.storyFlag) {
      continue;
    }
    add(
      SceneConditionSourcePickerOption(
        sourceKind: SceneConditionSourceKind.factLikeStoryFlag,
        sourceId: reference.referenceId,
        label: reference.humanLabel,
        debugTechnicalLabel: reference.debugTechnicalLabel,
      ),
    );
  }

  for (final storyline in project.storylines) {
    for (final chapter in storyline.chapters) {
      for (final step in chapter.steps) {
        add(
          SceneConditionSourcePickerOption(
            sourceKind: SceneConditionSourceKind.storyStepCompletion,
            sourceId: step.id,
            label: step.title,
            debugTechnicalLabel: '${storyline.id}:${chapter.id}:${step.id}',
          ),
        );
      }
    }
  }
  for (final step in buildNarrativeStoryStepPickerOptions(project)) {
    add(
      SceneConditionSourcePickerOption(
        sourceKind: SceneConditionSourceKind.storyStepCompletion,
        sourceId: step.stepId,
        label: step.humanLabel,
        debugTechnicalLabel: step.debugTechnicalLabel,
      ),
    );
  }

  final maps = activeMap == null ? const <MapData>[] : [activeMap];
  for (final eventSource in buildNarrativeEventSourcePickerOptions(
    project,
    maps: maps,
  )) {
    add(
      SceneConditionSourcePickerOption(
        sourceKind: SceneConditionSourceKind.consumedEvent,
        sourceId: eventSource.sourceId,
        label: eventSource.humanLabel,
        debugTechnicalLabel: eventSource.debugTechnicalLabel,
      ),
    );
  }

  final options = optionsByKey.values.toList(growable: false);
  options.sort((a, b) {
    final byKind = a.sourceKind.index.compareTo(b.sourceKind.index);
    if (byKind != 0) {
      return byKind;
    }
    final byLabel = a.label.toLowerCase().compareTo(b.label.toLowerCase());
    if (byLabel != 0) {
      return byLabel;
    }
    return a.sourceId.toLowerCase().compareTo(b.sourceId.toLowerCase());
  });
  return List<SceneConditionSourcePickerOption>.unmodifiable(options);
}

List<SceneConsequenceFactPickerOption> _buildSceneConsequenceFactOptions(
  ProjectManifest project,
) {
  final options = [
    for (final fact in project.facts)
      if (fact.id.trim().isNotEmpty)
        SceneConsequenceFactPickerOption(
          factId: fact.id,
          label: fact.label,
          description: fact.description,
          category: fact.category,
          debugTechnicalLabel: fact.legacyFlagName ?? fact.id,
          valueKind: fact.valueKind,
          initialValue: fact.initialValue,
        ),
  ];
  options.sort((a, b) {
    final byLabel = a.label.toLowerCase().compareTo(b.label.toLowerCase());
    if (byLabel != 0) {
      return byLabel;
    }
    return a.factId.toLowerCase().compareTo(b.factId.toLowerCase());
  });
  return List<SceneConsequenceFactPickerOption>.unmodifiable(options);
}

List<SceneConsequenceEventPickerOption> _buildSceneConsequenceEventOptions(
  ProjectManifest project, {
  MapData? activeMap,
}) {
  if (activeMap == null) {
    return const [];
  }
  final mapEntry = project.maps
      .where((entry) => entry.id == activeMap.id)
      .cast<ProjectMapEntry?>()
      .firstWhere((entry) => entry != null, orElse: () => null);
  final mapLabel = mapEntry?.name ?? activeMap.name;
  final options = [
    for (final event in activeMap.events)
      if (event.id.trim().isNotEmpty)
        SceneConsequenceEventPickerOption(
          mapId: activeMap.id,
          mapLabel: mapLabel,
          eventId: event.id,
          eventLabel: event.title.trim().isEmpty ? event.id : event.title,
          debugTechnicalLabel: '${activeMap.id}:${event.id}',
        ),
  ];
  options.sort((a, b) {
    final byMap = a.mapLabel.toLowerCase().compareTo(b.mapLabel.toLowerCase());
    if (byMap != 0) {
      return byMap;
    }
    final byEvent =
        a.eventLabel.toLowerCase().compareTo(b.eventLabel.toLowerCase());
    if (byEvent != 0) {
      return byEvent;
    }
    return a.eventId.toLowerCase().compareTo(b.eventId.toLowerCase());
  });
  return List<SceneConsequenceEventPickerOption>.unmodifiable(options);
}

NarrativeScenarioSummary? _resolveScenarioById(
  NarrativeWorkspaceProjection projection,
  String? id, {
  NarrativeScenarioSummary? fallback,
}) {
  if (id == null || id.trim().isEmpty) {
    return fallback;
  }
  return projection.scenarioById[id] ?? fallback;
}

NarrativeStepSummary? _resolveStepById(
  NarrativeWorkspaceProjection projection,
  String? id, {
  NarrativeStepSummary? fallback,
}) {
  if (id == null || id.trim().isEmpty) {
    return fallback;
  }
  for (final step in projection.steps) {
    if (step.id == id) {
      return step;
    }
  }
  return fallback;
}

class _StepWorkspaceBody extends StatelessWidget {
  const _StepWorkspaceBody({
    required this.editorNotifier,
    required this.project,
    required this.activeMap,
    required this.projection,
    required this.selectedStep,
    required this.onSelectStep,
    required this.onSelectOutcome,
    required this.onOpenCutsceneStudio,
  });

  final EditorNotifier editorNotifier;
  final ProjectManifest? project;
  final MapData? activeMap;
  final NarrativeWorkspaceProjection projection;
  final NarrativeStepSummary? selectedStep;
  final ValueChanged<String> onSelectStep;
  final ValueChanged<String?> onSelectOutcome;

  /// Depuis Step Studio : ouvrir la mise en scène sans l’éditer dans la step.
  final ValueChanged<String> onOpenCutsceneStudio;

  @override
  Widget build(BuildContext context) {
    return StepStudioWorkspace(
      editorNotifier: editorNotifier,
      project: project,
      activeMap: activeMap,
      projection: projection,
      selectedStepId: selectedStep?.id,
      onSelectStep: (stepId) {
        if (stepId == null) {
          return;
        }
        onSelectStep(stepId);
      },
      onSelectOutcome: onSelectOutcome,
      onOpenCutsceneStudio: onOpenCutsceneStudio,
    );
  }
}

class _CinematicsWorkspaceBody extends StatefulWidget {
  const _CinematicsWorkspaceBody({
    required this.editorNotifier,
    required this.projectRootPath,
    required this.project,
    required this.activeMap,
    required this.projection,
    required this.selectedCutscene,
    required this.requestedCinematicId,
    required this.requestedCinematicNonce,
    required this.requestedCinematicChildRoute,
    required this.onRouteChanged,
    required this.onSelectCutscene,
    required this.onSelectOutcome,
    required this.onOpenSceneUsage,
  });

  final EditorNotifier editorNotifier;
  final String? projectRootPath;
  final ProjectManifest? project;
  final MapData? activeMap;
  final NarrativeWorkspaceProjection projection;
  final NarrativeScenarioSummary? selectedCutscene;
  final String? requestedCinematicId;
  final int requestedCinematicNonce;
  final NarrativeStudioChildRoute requestedCinematicChildRoute;
  final ValueChanged<NarrativeStudioRouteLocation> onRouteChanged;
  final ValueChanged<String> onSelectCutscene;
  final ValueChanged<String?> onSelectOutcome;
  final OpenCinematicSceneUsageCallback onOpenSceneUsage;

  @override
  State<_CinematicsWorkspaceBody> createState() =>
      _CinematicsWorkspaceBodyState();
}

class _CinematicsWorkspaceBodyState extends State<_CinematicsWorkspaceBody> {
  bool _showLegacyCutsceneStudio = false;

  @override
  void initState() {
    super.initState();
    _syncRequestedChildRoute();
  }

  @override
  void didUpdateWidget(covariant _CinematicsWorkspaceBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requestedCinematicChildRoute !=
        widget.requestedCinematicChildRoute) {
      _syncRequestedChildRoute();
    }
  }

  void _syncRequestedChildRoute() {
    _showLegacyCutsceneStudio = widget.requestedCinematicChildRoute ==
        NarrativeStudioChildRoute.cinematicLegacy;
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    if (project == null) {
      return Center(
        child: Text(
          'Load a project to browse CinematicAsset.',
          textAlign: TextAlign.center,
          style: DefaultTextStyle.of(context).style.copyWith(
                color: context.pokeMapColors.textMuted,
              ),
        ),
      );
    }

    if (_showLegacyCutsceneStudio) {
      return NarrativeStudioWorkspacePage(
        presentation: const NarrativeStudioRoutePresentation(
          destination: NarrativeStudioDestination.cinematics,
          label: 'Cinématiques',
          breadcrumbLabels: ['Cinématiques', 'Ancien studio'],
        ),
        leading: PokeMapIconButton(
          key: const ValueKey('cinematics-library-back-button'),
          onPressed: () {
            setState(() => _showLegacyCutsceneStudio = false);
            widget.onRouteChanged(NarrativeStudioRouteLocation.cinematics());
          },
          tooltip: 'Retour à la bibliothèque de cinématiques',
          variant: PokeMapIconButtonVariant.soft,
          icon: const Icon(CupertinoIcons.chevron_left),
        ),
        body: PokeMapPageSurface(
          child: _CutsceneWorkspaceBody(
            editorNotifier: widget.editorNotifier,
            project: project,
            activeMap: widget.activeMap,
            projection: widget.projection,
            selectedCutscene: widget.selectedCutscene,
            onSelectCutscene: widget.onSelectCutscene,
            onSelectOutcome: widget.onSelectOutcome,
          ),
        ),
      );
    }

    return CinematicsLibraryWorkspace(
      project: project,
      projectRootPath: widget.projectRootPath,
      requestedEntryId: widget.requestedCinematicId,
      requestedEntryNonce: widget.requestedCinematicNonce,
      openRequestedEntryInBuilder: true,
      onBuilderEntryChanged: (cinematicId) {
        widget.onRouteChanged(
          NarrativeStudioRouteLocation.cinematics(
            childRoute: cinematicId == null
                ? NarrativeStudioChildRoute.cinematicLibrary
                : NarrativeStudioChildRoute.cinematicBuilder,
            selection: cinematicId == null
                ? null
                : NarrativeStudioAssetSelection(
                    kind: NarrativeStudioAssetKind.cinematic,
                    assetId: cinematicId,
                  ),
          ),
        );
      },
      onCreateCinematicShell: _createCinematicShell,
      onUpdateCinematicMetadata: _updateCinematicMetadata,
      onDuplicateCinematic: _duplicateCinematic,
      onToggleCinematicArchive: _toggleCinematicArchive,
      onBulkTagCinematics: _bulkTagCinematics,
      onBulkArchiveCinematics: _bulkArchiveCinematics,
      onRemoveCinematic: _removeCinematic,
      onAddTimelineDraft: _addCinematicTimelineDraft,
      onRemoveTimelineDraft: _removeCinematicTimelineDraft,
      onAddTimelineBasicBlock: _addCinematicTimelineBasicBlock,
      onUpdateTimelineBasicBlock: _updateCinematicTimelineBasicBlock,
      onAddRequiredActor: _addCinematicRequiredActor,
      onRenameRequiredActor: _renameCinematicRequiredActor,
      onRemoveRequiredActor: _removeCinematicRequiredActor,
      onAddMovementTarget: _addCinematicMovementTarget,
      onUpdateMovementTarget: _updateCinematicMovementTarget,
      onRemoveMovementTarget: _removeCinematicMovementTarget,
      onAddTimelineActorFacing: _addCinematicTimelineActorFacing,
      onUpdateTimelineActorFacing: _updateCinematicTimelineActorFacing,
      onAddTimelineActorMove: _addCinematicTimelineActorMove,
      onUpdateTimelineActorMove: _updateCinematicTimelineActorMove,
      onAddTimelineActorEmote: _addCinematicTimelineActorEmote,
      onUpdateTimelineActorEmote: _updateCinematicTimelineActorEmote,
      onRemoveTimelineAuthoringStep: _removeCinematicTimelineAuthoringStep,
      onUpdateStageMap: _updateCinematicStageMap,
      onUpdateStageContext: _updateCinematicStageContext,
      onUpdateCinematicAsset: _updateCinematicAsset,
      onUpsertActorBinding: _upsertCinematicActorBinding,
      onUpsertActorAppearanceBinding: _upsertCinematicActorAppearanceBinding,
      onRemoveActorAppearanceBinding: _removeCinematicActorAppearanceBinding,
      onUpsertActorInitialPlacement: _upsertCinematicActorInitialPlacement,
      onUpsertMovementTargetBinding: _upsertCinematicMovementTargetBinding,
      onLoadStageMapSnapshot: widget.editorNotifier.loadMapSnapshotById,
      onResolveBackdropTilesetPath:
          widget.editorNotifier.getTilesetAbsolutePathById,
      onOpenSceneUsage: widget.onOpenSceneUsage,
      onOpenLegacyCutsceneStudio: () {
        setState(() => _showLegacyCutsceneStudio = true);
        widget.onRouteChanged(
          NarrativeStudioRouteLocation.cinematics(
            childRoute: NarrativeStudioChildRoute.cinematicLegacy,
          ),
        );
      },
    );
  }

  Future<String?> _createCinematicShell({
    required String title,
    NarrativeTemplateKind? templateKind,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      return null;
    }
    final result =
        await widget.editorNotifier.executeNarrativeAuthoringMutation(
      (project) => NarrativeAssetMutation.createCinematic(
        project,
        title: cleanTitle,
        timeline: templateKind == null
            ? null
            : buildNarrativeCinematicTemplateTimeline(templateKind),
      ),
      operationId: _cinematicAuthoringOperationId('create'),
    );
    if (result == null) {
      return null;
    }
    final mutation = result.transaction.mutation;
    if (result.status != NarrativeAuthoringTransactionStatus.committed ||
        mutation is! NarrativeAssetCreated) {
      return null;
    }
    return mutation.asset.id;
  }

  Future<bool> _updateCinematicMetadata({
    required String cinematicId,
    required String title,
    required String description,
    required String notes,
    required String? mapId,
    required String? storylineId,
    required String? chapterId,
    required List<String> tags,
    required bool archived,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    final existing = findCinematicById(project, cinematicId);
    if (existing == null) {
      widget.editorNotifier.reportNarrativeNavigationFailure(
        'La cinématique à modifier est introuvable.',
      );
      return false;
    }
    final metadata = Map<String, String>.from(existing.metadata);
    if (archived) {
      metadata[cinematicLibraryArchivedMetadataKey] = 'true';
    } else {
      metadata.remove(cinematicLibraryArchivedMetadataKey);
    }
    final mutation = NarrativeAssetMutation.updateCinematic(
      project,
      cinematicId: cinematicId,
      cinematic: CinematicAsset(
        id: existing.id,
        title: title.trim(),
        description: description.trim(),
        storylineId: storylineId,
        chapterId: chapterId,
        mapId: mapId,
        tags: tags,
        requiredActors: existing.requiredActors,
        movementTargets: existing.movementTargets,
        stageContext: existing.stageContext,
        timeline: existing.timeline,
        notes: notes.trim(),
        metadata: metadata,
        legacyBridge: existing.legacyBridge,
      ),
    );
    if (mutation is NarrativeAssetRejected) {
      widget.editorNotifier.reportNarrativeNavigationFailure(mutation.message);
      return false;
    }
    if (mutation is NarrativeAssetNoChange) {
      if (widget.editorNotifier.narrativeDocumentBlocksNavigation) {
        return widget.editorNotifier.saveNarrativeDocument();
      }
      return true;
    }
    final applied = await _applyCinematicDocumentEdit(
      mutation.after,
      action: 'metadata',
      label: 'Modifier les informations de la cinématique',
      statusMessage: 'Informations de la cinématique modifiées.',
    );
    if (!applied) return false;
    // The metadata form exposes an explicit "save" action. Preserve that
    // durable contract while still recording the intention in the shared
    // document history before persistence.
    return widget.editorNotifier.saveNarrativeDocument();
  }

  Future<String?> _duplicateCinematic({required String cinematicId}) async {
    final project = widget.project;
    if (project == null) return null;
    try {
      final result = duplicateCinematicAsset(
        project,
        cinematicId: cinematicId,
      );
      final applied = await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: 'library_duplicate',
        label: 'Dupliquer une cinématique',
        statusMessage: 'Cinématique dupliquée.',
      );
      return applied ? result.cinematic.id : null;
    } on ArgumentError {
      return null;
    }
  }

  Future<bool> _toggleCinematicArchive({
    required String cinematicId,
    required bool archived,
  }) async {
    final project = widget.project;
    if (project == null) return false;
    try {
      final result = setCinematicArchived(
        project,
        cinematicId: cinematicId,
        archived: archived,
      );
      return await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: archived ? 'library_archive' : 'library_restore',
        label:
            archived ? 'Archiver une cinématique' : 'Restaurer une cinématique',
        statusMessage:
            archived ? 'Cinématique archivée.' : 'Cinématique restaurée.',
      );
    } on ArgumentError {
      return false;
    }
  }

  Future<bool> _bulkTagCinematics({
    required Set<String> cinematicIds,
    required List<String> tags,
  }) async {
    final project = widget.project;
    if (project == null) return false;
    try {
      final result = bulkTagCinematics(
        project,
        cinematicIds: cinematicIds,
        tags: tags,
      );
      return await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: 'library_bulk_tags',
        label: 'Classer plusieurs cinématiques',
        statusMessage: 'Tags appliqués aux cinématiques.',
      );
    } on ArgumentError {
      return false;
    }
  }

  Future<bool> _bulkArchiveCinematics({
    required Set<String> cinematicIds,
    required bool archived,
  }) async {
    final project = widget.project;
    if (project == null) return false;
    try {
      final result = bulkSetCinematicsArchived(
        project,
        cinematicIds: cinematicIds,
        archived: archived,
      );
      return await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: archived ? 'library_bulk_archive' : 'library_bulk_restore',
        label: archived
            ? 'Archiver plusieurs cinématiques'
            : 'Restaurer plusieurs cinématiques',
        statusMessage:
            archived ? 'Cinématiques archivées.' : 'Cinématiques restaurées.',
      );
    } on ArgumentError {
      return false;
    }
  }

  Future<bool> _removeCinematic({required String cinematicId}) async {
    final result =
        await widget.editorNotifier.executeNarrativeAuthoringMutation(
      (project) => NarrativeAssetMutation.deleteCinematic(
        project,
        cinematicId: cinematicId,
      ),
      operationId: _cinematicAuthoringOperationId('delete'),
    );
    if (result == null) {
      return false;
    }
    return result.status == NarrativeAuthoringTransactionStatus.committed;
  }

  Future<String?> _addCinematicTimelineDraft({
    required String cinematicId,
    String? afterStepId,
  }) async {
    final project = widget.project;
    if (project == null) {
      return null;
    }
    try {
      final result = addCinematicTimelineDraftStep(
        project,
        cinematicId: cinematicId,
        afterStepId: afterStepId,
      );
      final applied = await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: 'timeline_draft_add',
        label: 'Ajouter une étape brouillon',
        statusMessage: 'Étape brouillon ajoutée.',
      );
      if (!applied) return null;
      return result.step.id;
    } on ArgumentError {
      return null;
    }
  }

  Future<bool> _removeCinematicTimelineDraft({
    required String cinematicId,
    required String stepId,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = removeCinematicTimelineDraftStep(
        project,
        cinematicId: cinematicId,
        stepId: stepId,
      );
      final applied = await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: 'timeline_draft_remove',
        label: 'Supprimer une étape brouillon',
        statusMessage: 'Étape brouillon supprimée.',
      );
      return applied;
    } on ArgumentError {
      return false;
    }
  }

  Future<String?> _addCinematicTimelineBasicBlock({
    required String cinematicId,
    required CinematicTimelineBasicBlockKind blockKind,
    String? afterStepId,
  }) async {
    final project = widget.project;
    if (project == null) {
      return null;
    }
    try {
      final result = addCinematicTimelineBasicBlockStep(
        project,
        cinematicId: cinematicId,
        blockKind: blockKind,
        afterStepId: afterStepId,
      );
      final applied = await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: 'timeline_block_add',
        label: 'Ajouter un bloc de timeline',
        statusMessage: 'Bloc de timeline ajouté.',
      );
      if (!applied) return null;
      return result.step.id;
    } on ArgumentError {
      return null;
    }
  }

  Future<bool> _updateCinematicTimelineBasicBlock({
    required String cinematicId,
    required String stepId,
    int? durationMs,
    CinematicTimelineFadeMode? fadeMode,
    CinematicTimelineCameraMode? cameraMode,
    CinematicTimelineCameraFocusBinding? cameraFocusBinding,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = updateCinematicTimelineBasicBlockStep(
        project,
        cinematicId: cinematicId,
        stepId: stepId,
        durationMs: durationMs,
        fadeMode: fadeMode,
        cameraMode: cameraMode,
        cameraFocusBinding: cameraFocusBinding,
      );
      final applied = await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: 'timeline_block_update',
        label: 'Modifier un bloc de timeline',
        statusMessage: 'Bloc de timeline modifié.',
      );
      return applied;
    } on ArgumentError {
      return false;
    }
  }

  Future<String?> _addCinematicRequiredActor({
    required String cinematicId,
    String? label,
  }) async {
    final project = widget.project;
    if (project == null) {
      return null;
    }
    try {
      final result = addCinematicRequiredActor(
        project,
        cinematicId: cinematicId,
        label: label ?? 'Acteur',
      );
      final applied = await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: 'actor_add',
        label: 'Ajouter un acteur requis',
        statusMessage: 'Acteur requis ajouté.',
      );
      if (!applied) return null;
      return result.actor.actorId;
    } on ArgumentError {
      return null;
    }
  }

  Future<bool> _renameCinematicRequiredActor({
    required String cinematicId,
    required String actorId,
    required String label,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = renameCinematicRequiredActor(
        project,
        cinematicId: cinematicId,
        actorId: actorId,
        label: label,
      );
      final applied = await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: 'actor_rename',
        label: 'Renommer un acteur requis',
        statusMessage: 'Acteur requis renommé.',
      );
      return applied;
    } on ArgumentError {
      return false;
    }
  }

  Future<bool> _removeCinematicRequiredActor({
    required String cinematicId,
    required String actorId,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = removeCinematicRequiredActor(
        project,
        cinematicId: cinematicId,
        actorId: actorId,
      );
      final applied = await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: 'actor_remove',
        label: 'Supprimer un acteur requis',
        statusMessage: 'Acteur requis supprimé.',
      );
      return applied;
    } on ArgumentError {
      return false;
    }
  }

  Future<String?> _addCinematicMovementTarget({
    required String cinematicId,
  }) async {
    final project = widget.project;
    if (project == null) {
      return null;
    }
    try {
      final result = addCinematicMovementTarget(
        project,
        cinematicId: cinematicId,
        label: 'Destination',
      );
      final applied = await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: 'target_add',
        label: 'Ajouter une destination',
        statusMessage: 'Destination ajoutée.',
      );
      if (!applied) return null;
      return result.target.targetId;
    } on ArgumentError {
      return null;
    }
  }

  Future<bool> _updateCinematicMovementTarget({
    required String cinematicId,
    required String targetId,
    required String label,
    String? description,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = updateCinematicMovementTarget(
        project,
        cinematicId: cinematicId,
        targetId: targetId,
        label: label,
        description: description,
      );
      final applied = await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: 'target_update',
        label: 'Modifier une destination',
        statusMessage: 'Destination modifiée.',
      );
      return applied && result.target.targetId == targetId;
    } on ArgumentError {
      return false;
    }
  }

  Future<bool> _removeCinematicMovementTarget({
    required String cinematicId,
    required String targetId,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = removeCinematicMovementTarget(
        project,
        cinematicId: cinematicId,
        targetId: targetId,
      );
      final applied = await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: 'target_remove',
        label: 'Supprimer une destination',
        statusMessage: 'Destination supprimée.',
      );
      return applied && result.removedTarget.targetId == targetId;
    } on ArgumentError {
      return false;
    }
  }

  Future<String?> _addCinematicTimelineActorFacing({
    required String cinematicId,
    required String actorId,
    required CinematicTimelineActorFacingDirection direction,
    String? afterStepId,
  }) async {
    final project = widget.project;
    if (project == null) {
      return null;
    }
    try {
      final result = addCinematicTimelineActorFacingStep(
        project,
        cinematicId: cinematicId,
        actorId: actorId,
        direction: direction,
        afterStepId: afterStepId,
      );
      final applied = await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: 'actor_facing_add',
        label: 'Ajouter une orientation d’acteur',
        statusMessage: 'Orientation d’acteur ajoutée.',
      );
      if (!applied) return null;
      return result.step.id;
    } on ArgumentError {
      return null;
    }
  }

  Future<bool> _updateCinematicTimelineActorFacing({
    required String cinematicId,
    required String stepId,
    String? actorId,
    CinematicTimelineActorFacingDirection? direction,
    int? durationMs,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = updateCinematicTimelineActorFacingStep(
        project,
        cinematicId: cinematicId,
        stepId: stepId,
        actorId: actorId,
        direction: direction,
        durationMs: durationMs,
      );
      final applied = await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: 'actor_facing_update',
        label: 'Modifier une orientation d’acteur',
        statusMessage: 'Orientation d’acteur modifiée.',
      );
      return applied && result.step.id == stepId;
    } on ArgumentError {
      return false;
    }
  }

  Future<String?> _addCinematicTimelineActorMove({
    required String cinematicId,
    required String actorId,
    required String targetId,
    required int durationMs,
    required CinematicTimelineActorMovementMode movementMode,
    String? afterStepId,
  }) async {
    final project = widget.project;
    if (project == null) {
      return null;
    }
    try {
      final result = addCinematicTimelineActorMoveStep(
        project,
        cinematicId: cinematicId,
        actorId: actorId,
        targetId: targetId,
        durationMs: durationMs,
        movementMode: movementMode,
        afterStepId: afterStepId,
      );
      final applied = await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: 'actor_move_add',
        label: 'Ajouter un déplacement d’acteur',
        statusMessage: 'Déplacement d’acteur ajouté.',
      );
      if (!applied) return null;
      return result.step.id;
    } on ArgumentError {
      return null;
    }
  }

  Future<bool> _updateCinematicTimelineActorMove({
    required String cinematicId,
    required String stepId,
    String? actorId,
    String? targetId,
    int? durationMs,
    CinematicTimelineActorMovementMode? movementMode,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = updateCinematicTimelineActorMoveStep(
        project,
        cinematicId: cinematicId,
        stepId: stepId,
        actorId: actorId,
        targetId: targetId,
        durationMs: durationMs,
        movementMode: movementMode,
      );
      final applied = await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: 'actor_move_update',
        label: 'Modifier un déplacement d’acteur',
        statusMessage: 'Déplacement d’acteur modifié.',
      );
      return applied && result.step.id == stepId;
    } on ArgumentError {
      return false;
    }
  }

  Future<String?> _addCinematicTimelineActorEmote({
    required String cinematicId,
    required String actorId,
    required String emoteId,
    int? durationMs,
    String? afterStepId,
  }) async {
    final project = widget.project;
    if (project == null) {
      return null;
    }
    try {
      final result = addCinematicTimelineActorEmoteStep(
        project,
        cinematicId: cinematicId,
        actorId: actorId,
        emoteId: emoteId,
        durationMs: durationMs,
        afterStepId: afterStepId,
      );
      final applied = await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: 'actor_emote_add',
        label: 'Ajouter une emote d’acteur',
        statusMessage: 'Emote d’acteur ajoutée.',
      );
      if (!applied) return null;
      return result.step.id;
    } on ArgumentError {
      return null;
    }
  }

  Future<bool> _updateCinematicTimelineActorEmote({
    required String cinematicId,
    required String stepId,
    String? actorId,
    String? emoteId,
    int? durationMs,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = updateCinematicTimelineActorEmoteStep(
        project,
        cinematicId: cinematicId,
        stepId: stepId,
        actorId: actorId,
        emoteId: emoteId,
        durationMs: durationMs,
      );
      final applied = await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: 'actor_emote_update',
        label: 'Modifier une emote d’acteur',
        statusMessage: 'Emote d’acteur modifiée.',
      );
      return applied && result.step.id == stepId;
    } on ArgumentError {
      return false;
    }
  }

  Future<bool> _removeCinematicTimelineAuthoringStep({
    required String cinematicId,
    required String stepId,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = removeCinematicTimelineAuthoringStep(
        project,
        cinematicId: cinematicId,
        stepId: stepId,
      );
      final applied = await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: 'timeline_step_remove',
        label: 'Supprimer une étape de timeline',
        statusMessage: 'Étape de timeline supprimée.',
      );
      return applied && result.removedStep.id == stepId;
    } on ArgumentError {
      return false;
    }
  }

  Future<bool> _updateCinematicStageMap({
    required String cinematicId,
    String? mapId,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = updateCinematicStageMap(
        project,
        cinematicId: cinematicId,
        mapId: mapId,
      );
      final applied = await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: 'stage_map_update',
        label: 'Modifier la carte de mise en scène',
        statusMessage: 'Carte de mise en scène modifiée.',
      );
      return applied;
    } on ArgumentError {
      return false;
    }
  }

  Future<bool> _updateCinematicStageContext({
    required String cinematicId,
    required CinematicStageContext stageContext,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = updateCinematicStageContext(
        project,
        cinematicId: cinematicId,
        stageContext: stageContext,
      );
      final applied = await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: 'stage_context_update',
        label: 'Modifier le contexte de mise en scène',
        statusMessage: 'Contexte de mise en scène modifié.',
      );
      return applied;
    } on ArgumentError {
      return false;
    }
  }

  Future<bool> _updateCinematicAsset({
    required String cinematicId,
    required CinematicAsset cinematic,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = updateCinematicAsset(
        project,
        cinematic,
      );
      final applied = await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: 'asset_update',
        label: 'Modifier la cinématique',
        statusMessage: 'Cinématique modifiée.',
      );
      return applied;
    } on ArgumentError {
      return false;
    }
  }

  Future<bool> _upsertCinematicActorBinding({
    required String cinematicId,
    required CinematicActorBinding binding,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = upsertCinematicActorBinding(
        project,
        cinematicId: cinematicId,
        binding: binding,
      );
      final applied = await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: 'actor_binding_update',
        label: 'Modifier la liaison d’un acteur',
        statusMessage: 'Liaison d’acteur modifiée.',
      );
      return applied;
    } on ArgumentError {
      return false;
    }
  }

  Future<bool> _upsertCinematicActorAppearanceBinding({
    required String cinematicId,
    required CinematicActorAppearanceBinding binding,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = upsertCinematicActorAppearanceBinding(
        project,
        cinematicId: cinematicId,
        binding: binding,
      );
      final applied = await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: 'actor_appearance_update',
        label: 'Modifier l’apparence d’un acteur',
        statusMessage: 'Apparence d’acteur modifiée.',
      );
      return applied;
    } on ArgumentError {
      return false;
    }
  }

  Future<bool> _removeCinematicActorAppearanceBinding({
    required String cinematicId,
    required String actorId,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = removeCinematicActorAppearanceBinding(
        project,
        cinematicId: cinematicId,
        actorId: actorId,
      );
      final applied = await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: 'actor_appearance_remove',
        label: 'Retirer l’apparence d’un acteur',
        statusMessage: 'Apparence d’acteur retirée.',
      );
      return applied;
    } on ArgumentError {
      return false;
    }
  }

  Future<bool> _upsertCinematicActorInitialPlacement({
    required String cinematicId,
    required CinematicActorInitialPlacement placement,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = upsertCinematicActorInitialPlacement(
        project,
        cinematicId: cinematicId,
        placement: placement,
      );
      final applied = await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: 'actor_placement_update',
        label: 'Modifier le placement d’un acteur',
        statusMessage: 'Placement d’acteur modifié.',
      );
      return applied;
    } on ArgumentError {
      return false;
    }
  }

  Future<bool> _upsertCinematicMovementTargetBinding({
    required String cinematicId,
    required CinematicMovementTargetBinding binding,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = upsertCinematicMovementTargetBinding(
        project,
        cinematicId: cinematicId,
        binding: binding,
      );
      final applied = await _applyCinematicDocumentEdit(
        result.updatedProject,
        action: 'target_binding_update',
        label: 'Modifier la liaison d’une destination',
        statusMessage: 'Liaison de destination modifiée.',
      );
      return applied;
    } on ArgumentError {
      return false;
    }
  }

  Future<bool> _applyCinematicDocumentEdit(
    ProjectManifest project, {
    required String action,
    required String label,
    required String statusMessage,
  }) {
    return widget.editorNotifier.applyNarrativeDocumentEdit(
      project,
      operationId: _cinematicAuthoringOperationId(action),
      label: label,
      statusMessage: statusMessage,
    );
  }
}

String _cinematicAuthoringOperationId(String action) =>
    'cinematic_${action}_${DateTime.now().microsecondsSinceEpoch}';

class _CutsceneWorkspaceBody extends StatelessWidget {
  const _CutsceneWorkspaceBody({
    required this.editorNotifier,
    required this.project,
    required this.activeMap,
    required this.projection,
    required this.selectedCutscene,
    required this.onSelectCutscene,
    required this.onSelectOutcome,
  });

  final EditorNotifier editorNotifier;
  final ProjectManifest? project;
  final MapData? activeMap;
  final NarrativeWorkspaceProjection projection;
  final NarrativeScenarioSummary? selectedCutscene;
  final ValueChanged<String> onSelectCutscene;
  final ValueChanged<String?> onSelectOutcome;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 310,
          child: _NarrativeListCard(
            title: 'Local Event Flows / Cutscenes',
            subtitle: 'Scene execution layer',
            emptyText: 'No local flow available.',
            children: projection.localEventFlows
                .map(
                  (scenario) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: PokeMapSidebarItem(
                      selected: selectedCutscene?.id == scenario.id,
                      compact: true,
                      growForTextScale: true,
                      onTap: () => onSelectCutscene(scenario.id),
                      icon: const Icon(CupertinoIcons.play_rectangle),
                      label: scenario.name,
                      subtitle:
                          '${scenario.nodeCount} nodes • entry: ${scenario.entryNodeId}',
                      trailing: PokeMapIconButton(
                        tooltip: 'Supprimer cette cutscene',
                        variant: PokeMapIconButtonVariant.danger,
                        size: 32,
                        onPressed: () async {
                          await deleteCutsceneWithUserConfirmation(
                            context: context,
                            editorNotifier: editorNotifier,
                            projection: projection,
                            scenarioId: scenario.id,
                            selectedScenarioId: selectedCutscene?.id,
                            onSelectReplacement: onSelectCutscene,
                          );
                        },
                        icon: const Icon(CupertinoIcons.trash, size: 17),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: project == null
              ? const PokeMapPanel(
                  borderRadius: 20,
                  expandChild: true,
                  child: Center(
                    child: Text('Load a project to edit cutscenes.'),
                  ),
                )
              : CutsceneStudioWorkspace(
                  editorNotifier: editorNotifier,
                  project: project!,
                  activeMap: activeMap,
                  projection: projection,
                  selectedCutscene: selectedCutscene,
                  onSelectCutscene: onSelectCutscene,
                  onSelectOutcome: onSelectOutcome,
                  onOpenDialogueStudio: (dialogueId) {
                    editorNotifier.selectProjectDialogue(dialogueId);
                    editorNotifier.selectDialogueWorkspace();
                  },
                ),
        ),
      ],
    );
  }
}

Map<String, List<String>> _buildSceneConsumerPaths(
  ProjectManifest project, {
  MapData? activeMap,
}) {
  final index = buildNarrativeDependencyIndex(
    project: project,
    maps: activeMap == null ? const <MapData>[] : <MapData>[activeMap],
  );
  return {
    for (final scene in project.scenes)
      scene.id: [
        for (final usage
            in index.usagesFor(NarrativeDependencyKey.scene(scene.id)))
          if (usage.owner != NarrativeDependencyKey.scene(scene.id)) usage.path,
      ],
  };
}

Map<NarrativeCommandParameterKind, List<SceneActionPickerOption>>
    _buildSceneActionPickerOptions(
  ProjectManifest project,
  SceneConsequenceCatalogs catalogs, {
  MapData? activeMap,
}) {
  final eventOptions = _buildSceneConsequenceEventOptions(
    project,
    activeMap: activeMap,
  );
  List<SceneActionPickerOption> fromCatalog(
    SceneConsequenceCatalogSection section,
  ) =>
      [
        for (final option in section.options)
          SceneActionPickerOption(id: option.id, label: option.label),
      ];

  return <NarrativeCommandParameterKind, List<SceneActionPickerOption>>{
    NarrativeCommandParameterKind.fact: [
      for (final fact in project.facts)
        SceneActionPickerOption(id: fact.id, label: fact.label),
    ],
    NarrativeCommandParameterKind.event: [
      for (final event in eventOptions)
        SceneActionPickerOption(
          id: event.eventId,
          label: '${event.mapLabel} · ${event.eventLabel}',
        ),
    ],
    NarrativeCommandParameterKind.storyStep: fromCatalog(catalogs.storySteps),
    NarrativeCommandParameterKind.item: fromCatalog(catalogs.items),
    NarrativeCommandParameterKind.species: fromCatalog(catalogs.species),
    NarrativeCommandParameterKind.starter:
        fromCatalog(catalogs.configuredStarters),
    NarrativeCommandParameterKind.map: [
      for (final map in project.maps)
        SceneActionPickerOption(id: map.id, label: map.name),
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

class _NarrativeListCard extends StatelessWidget {
  const _NarrativeListCard({
    required this.title,
    required this.subtitle,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final String subtitle;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      borderRadius: 20,
      expandChild: true,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: DefaultTextStyle.of(context).style.copyWith(
                  color: context.pokeMapColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: DefaultTextStyle.of(context).style.copyWith(
                  color: context.pokeMapColors.textMuted,
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: children.isEmpty
                ? Center(
                    child: Text(
                      emptyText,
                      textAlign: TextAlign.center,
                      style: DefaultTextStyle.of(context).style.copyWith(
                            color: context.pokeMapColors.textMuted,
                            fontSize: 12,
                          ),
                    ),
                  )
                : ListView.separated(
                    itemBuilder: (context, index) => children[index],
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemCount: children.length,
                  ),
          ),
        ],
      ),
    );
  }
}
