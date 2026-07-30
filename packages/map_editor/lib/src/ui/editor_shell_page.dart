import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Dialog, Icons, Material, MaterialType, showDialog;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import '../../l10n/l10n.dart';
import 'shared/pokemap_macos_ui_shim.dart';
import 'package:map_editor/src/ui/canvas/editor_canvas_host.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_destination.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_command_palette.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_navigation.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_route_presentation.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_shell_policy.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_workspace_page.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';
import 'package:map_editor/src/ui/panels/tileset_palette_panel.dart';
import 'package:map_editor/src/ui/shared/cupertino_editor_widgets.dart';
import 'package:map_editor/src/ui/shared/status_bar.dart';
import 'package:map_editor/src/ui/shared/top_toolbar.dart';
import 'package:map_editor/src/ui/shared/top_toolbar/dialogs/top_toolbar_dialogs.dart';
import 'design_system/design_system.dart';
import '../theme/theme.dart';

import '../features/border_map_editing/presentation/pending_border_save_dialog.dart';
import '../features/editor/application/map_activation_coordinator.dart';
import '../features/editor/presentation/map_activation_guard.dart';
import '../features/editor/presentation/world_map/world_map_toolbelt.dart';
import '../features/editor/presentation/world_map/world_map_workspace.dart';
import '../features/editor/presentation/world_map/world_map_workspace_session.dart';
import '../features/editor/state/editor_notifier.dart';
import '../features/editor/state/editor_selectors.dart';
import '../features/editor/state/editor_state.dart';
import '../features/narrative/state/narrative_event_builder_v2_providers.dart';
import '../features/narrative/state/narrative_validator_providers.dart';
import '../application/services/narrative_document_session.dart';
import '../features/border_studio/state/border_studio_providers.dart';

const double _kRightInspectorDefaultWidth = 336;
const double _kRightInspectorMinWidth = 280;
const double _kRightInspectorMaxWidth = 560;
const double _kRightInspectorResizeHandleWidth = 12;
const double _kCenterStageMinWidth = 320;
const narrativeDocumentUndoActionKey =
    ValueKey<String>('narrative-document-undo-action');
const narrativeDocumentRedoActionKey =
    ValueKey<String>('narrative-document-redo-action');
const narrativeDocumentSaveActionKey =
    ValueKey<String>('narrative-document-save-action');
const narrativeDocumentAutosaveActionKey =
    ValueKey<String>('narrative-document-autosave-action');
const narrativeDocumentCompareActionKey =
    ValueKey<String>('narrative-document-compare-action');
const narrativeDocumentReloadActionKey =
    ValueKey<String>('narrative-document-reload-action');
const narrativeDocumentKeepLocalActionKey =
    ValueKey<String>('narrative-document-keep-local-action');
const narrativeDocumentDiscardActionKey =
    ValueKey<String>('narrative-document-discard-action');

class EditorShellPage extends ConsumerStatefulWidget {
  const EditorShellPage({super.key});

  @override
  ConsumerState<EditorShellPage> createState() => _EditorShellPageState();
}

class _EditorShellPageState extends ConsumerState<EditorShellPage> {
  Timer? _toastTimer;
  final GlobalKey _projectExplorerKey =
      GlobalKey(debugLabel: 'shared-project-explorer');
  String? _toastMessage;
  bool _toastIsError = false;
  bool _didAttemptProjectAutoRestore = false;

  /// When false, the right ResizablePane (map / tileset / narrative inspector) is omitted so the center stage uses full width.
  bool _rightInspectorVisible = true;

  /// Preferred right inspector width, retained while the shell stays mounted.
  double _rightInspectorWidth = _kRightInspectorDefaultWidth;

  /// When false, the left ResizablePane is collapsed to a narrow toggle strip.
  bool _leftSidebarVisible = true;
  bool _isHandlingBorderExit = false;
  ProjectManifest? _indexedNarrativeProject;
  MapData? _indexedNarrativeMap;
  String? _indexedNarrativeDiagnostics;
  int _narrativeSearchRevision = 0;
  NarrativeGlobalSearchIndex _narrativeSearchIndex =
      NarrativeGlobalSearchIndex.fromEntries(revision: 0, entries: const []);

  NarrativeGlobalSearchIndex _globalSearchIndexFor({
    required ProjectManifest project,
    required MapData? activeMap,
    required List<NarrativeProjectDiagnostic> diagnostics,
  }) {
    final diagnosticsFingerprint =
        diagnostics.map((item) => item.stableKey).join('\n');
    if (identical(_indexedNarrativeProject, project) &&
        identical(_indexedNarrativeMap, activeMap) &&
        _indexedNarrativeDiagnostics == diagnosticsFingerprint) {
      return _narrativeSearchIndex;
    }
    _indexedNarrativeProject = project;
    _indexedNarrativeMap = activeMap;
    _indexedNarrativeDiagnostics = diagnosticsFingerprint;
    _narrativeSearchRevision++;
    final dependencyIndex = buildNarrativeDependencyIndex(
      project: project,
      maps: [if (activeMap != null) activeMap],
    );
    _narrativeSearchIndex = buildNarrativeGlobalSearchIndex(
      project: project,
      dependencyIndex: dependencyIndex,
      diagnostics: diagnostics,
      revision: _narrativeSearchRevision,
    );
    return _narrativeSearchIndex;
  }

  @override
  void initState() {
    super.initState();
    // Provider mutations are intentionally deferred after the first frame:
    // auto-restore loads a project (state mutation), and Riverpod disallows
    // mutating providers during build/init lifecycle phases.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _didAttemptProjectAutoRestore) {
        return;
      }
      _didAttemptProjectAutoRestore = true;
      await ref
          .read(editorNotifierProvider.notifier)
          .restoreLastOpenedProjectIfAny();
    });
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  void _flashToast(String message, {required bool isError}) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
      _toastIsError = isError;
    });
    _toastTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _toastMessage = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final shell = ref.watch(editorShellSnapshotProvider);
    final project = ref.watch(editorProjectManifestProvider);
    final projectRootPath = ref.watch(
      editorNotifierProvider.select((state) => state.projectRootPath),
    );
    final projectIsDirty = ref.watch(
      editorNotifierProvider.select(
        (state) => state.isDirty || state.isProjectDirty,
      ),
    );
    final activeMap =
        ref.watch(editorNotifierProvider.select((s) => s.activeMap));
    final workspaceMode = shell.workspaceMode;
    final navigationState =
        ref.watch(narrativeStudioNavigationControllerProvider);
    final workspaceLocation = narrativeStudioRouteLocationFor(workspaceMode);
    final selectedNarrativeLocation = workspaceLocation == null
        ? navigationState.location
        : navigationState.location.destination == workspaceLocation.destination
            ? navigationState.location
            : workspaceLocation;
    final notifier = ref.read(editorNotifierProvider.notifier);
    final eventSystemMode =
        project?.eventRegistry?.mode ?? EventSystemMode.legacyOnly;
    final usesNarrativeStudioProductShell =
        NarrativeStudioShellPolicy.shouldUseProductShell(
      workspaceMode: workspaceMode,
      eventSystemMode: eventSystemMode,
    );
    final canRevalidateEventProject =
        project != null && (projectRootPath?.trim().isNotEmpty ?? false);
    final narrativeValidatorRequest = usesNarrativeStudioProductShell &&
            project != null &&
            (projectRootPath?.trim().isNotEmpty ?? false)
        ? NarrativeValidatorSnapshotRequest.fromProject(
            projectRootPath: projectRootPath!.trim(),
            project: project,
            activeMap: activeMap,
          )
        : null;
    final narrativeDiagnostics = narrativeValidatorRequest == null
        ? const <NarrativeProjectDiagnostic>[]
        : ref
                .watch(
                  narrativeValidatorReportProvider(narrativeValidatorRequest),
                )
                .asData
                ?.value
                .diagnostics ??
            const <NarrativeProjectDiagnostic>[];
    final narrativeSearchIndex = project == null
        ? null
        : _globalSearchIndexFor(
            project: project,
            activeMap: activeMap,
            diagnostics: narrativeDiagnostics,
          );

    void revalidateEventProject() {
      final root = projectRootPath?.trim();
      if (project == null || root == null || root.isEmpty) return;
      final request = NarrativeEventBuilderV2SnapshotRequest.fromProject(
        projectRootPath: root,
        project: project,
      );
      ref.invalidate(narrativeEventValidationSnapshotProvider(request));
    }

    Future<bool> guardNarrativeNavigation() async {
      if (!notifier.narrativeDocumentBlocksNavigation) return true;
      final l10n = context.pokeMapL10n;
      final choice = await showPokeMapConfirmationDialog<_UnsavedChoice>(
        context: context,
        title: l10n.narrativeUnsavedTitle,
        message: l10n.narrativeUnsavedMessage,
        actions: [
          PokeMapDialogAction(
            label: l10n.narrativeStayHere,
            value: _UnsavedChoice.cancel,
          ),
          PokeMapDialogAction(
            label: l10n.narrativeDiscard,
            value: _UnsavedChoice.discard,
            variant: PokeMapButtonVariant.danger,
          ),
          PokeMapDialogAction(
            label: l10n.narrativeSave,
            value: _UnsavedChoice.save,
            variant: PokeMapButtonVariant.success,
          ),
        ],
      );
      return switch (choice) {
        _UnsavedChoice.save => await notifier.saveNarrativeDocument(),
        _UnsavedChoice.discard => await notifier.discardNarrativeDocument(),
        _ => false,
      };
    }

    void applyNarrativeDestination(
      NarrativeStudioDestination destination,
    ) {
      switch (destination) {
        case NarrativeStudioDestination.overview:
          notifier.selectNarrativeOverviewWorkspace();
        case NarrativeStudioDestination.storylines:
          notifier.selectGlobalStoryWorkspace();
        case NarrativeStudioDestination.scenes:
          notifier.selectScenesWorkspace();
        case NarrativeStudioDestination.events:
          notifier.selectEventsWorkspace();
        case NarrativeStudioDestination.cinematics:
          notifier.selectCutsceneWorkspace();
        case NarrativeStudioDestination.dialogues:
          notifier.selectDialogueWorkspace();
        case NarrativeStudioDestination.facts:
          notifier.selectFactsWorkspace();
        case NarrativeStudioDestination.shops:
          notifier.selectShopsWorkspace();
        case NarrativeStudioDestination.worldRules:
          notifier.selectWorldRulesWorkspace();
        case NarrativeStudioDestination.validator:
          notifier.selectNarrativeValidatorWorkspace();
      }
    }

    Future<void> selectNarrativeDestination(
      NarrativeStudioDestination destination,
    ) async {
      if (!await guardNarrativeNavigation()) return;
      applyNarrativeDestination(destination);
    }

    void openNarrativeWorkspaceForLocation(
      NarrativeStudioRouteLocation location,
    ) {
      switch (location.childRoute) {
        case NarrativeStudioChildRoute.storylineStep:
          notifier.selectStepWorkspace();
        case NarrativeStudioChildRoute.cinematicLegacy:
        case NarrativeStudioChildRoute.cinematicLibrary:
        case NarrativeStudioChildRoute.cinematicBuilder:
          notifier.selectCutsceneWorkspace();
        default:
          applyNarrativeDestination(location.destination);
      }
    }

    Future<void> selectNarrativeLocation(
      NarrativeStudioRouteLocation location,
    ) async {
      if (!await guardNarrativeNavigation()) return;
      ref
          .read(narrativeStudioNavigationControllerProvider.notifier)
          .replace(location);
      openNarrativeWorkspaceForLocation(location);
    }

    Future<void> openNarrativeResolution(
      NarrativeStudioNavigationResolution resolution,
    ) async {
      final location = resolution.location;
      if (resolution.kind == NarrativeStudioNavigationResolutionKind.internal &&
          location != null) {
        await selectNarrativeLocation(location);
        return;
      }
      final mapTarget = resolution.externalMapTarget;
      if (resolution.kind !=
              NarrativeStudioNavigationResolutionKind.externalMap ||
          mapTarget == null) {
        _flashToast(
          resolution.reason ?? 'Cette destination ne peut pas être ouverte.',
          isError: true,
        );
        return;
      }
      if (!await guardNarrativeNavigation()) return;
      if (!context.mounted) return;
      final currentEditor = ref.read(editorNotifierProvider);
      final project = currentEditor.project;
      ProjectMapEntry? targetEntry;
      for (final entry in project?.maps ?? const <ProjectMapEntry>[]) {
        if (entry.id == mapTarget.mapId) {
          targetEntry = entry;
          break;
        }
      }
      if (targetEntry == null) {
        _flashToast(
          'Impossible de trouver la map ${mapTarget.mapId} dans le projet.',
          isError: true,
        );
        return;
      }
      final activationOutcome = await requestEditorMapActivation(
        context: context,
        notifier: notifier,
        relativePath: targetEntry.relativePath,
      );
      if (activationOutcome != MapActivationOutcome.activated) {
        _flashToast(
          'Impossible d’ouvrir la map ${mapTarget.mapId}.',
          isError: true,
        );
        return;
      }
      notifier.focusNarrativeEventMapSource(
        NarrativeEditorFocusTarget.map(mapTarget.mapId),
      );
      switch (mapTarget.sourceKind) {
        case 'entity':
          notifier.selectEntity(mapTarget.sourceId);
        case 'trigger':
          notifier.selectTrigger(mapTarget.sourceId);
        case 'event':
          notifier.selectMapEvent(mapTarget.sourceId);
        case 'warp':
          notifier.selectWarp(mapTarget.sourceId);
      }
      ref
          .read(narrativeStudioNavigationControllerProvider.notifier)
          .rememberExternalReturn(
            NarrativeStudioReturnExpectation(
              location: selectedNarrativeLocation,
            ),
          );
    }

    Future<void> openNarrativeDependencyIntent(
      NarrativeDependencyNavigationIntent intent,
    ) {
      return openNarrativeResolution(
        resolveNarrativeDependencyNavigationIntent(intent),
      );
    }

    Future<void> openNarrativeSearchEntry(
      NarrativeGlobalSearchEntry entry,
    ) {
      final diagnostic = entry.diagnostic;
      final resolution = diagnostic == null
          ? entry.navigationIntent == null
              ? const NarrativeStudioNavigationResolution.unavailable(
                  'Cet élément ne possède pas encore de destination ouvrable.',
                )
              : resolveNarrativeDependencyNavigationIntent(
                  entry.navigationIntent!,
                )
          : resolveNarrativeProjectDiagnostic(diagnostic);
      return openNarrativeResolution(resolution);
    }

    Future<void> restoreNarrativeLocation() async {
      if (!await guardNarrativeNavigation()) return;
      final expectation = ref
          .read(narrativeStudioNavigationControllerProvider.notifier)
          .restoreReturn();
      if (expectation == null) return;
      openNarrativeWorkspaceForLocation(expectation.location);
    }

    final narrativeCommandPaletteActions = <NarrativeCommandPaletteAction>[
      for (final destination in NarrativeStudioDestination.values)
        if (destination != NarrativeStudioDestination.validator)
          NarrativeCommandPaletteAction(
            id: 'navigate.${destination.name}',
            label: _narrativeDestinationCommandLabel(destination),
            description: 'Ouvrir cet espace du Narrative Studio',
            kind: NarrativeCommandPaletteActionKind.navigation,
            onInvoke: () => unawaited(
              selectNarrativeDestination(destination),
            ),
          ),
      NarrativeCommandPaletteAction(
        id: 'project.validate',
        label: 'Valider le projet narratif',
        description: 'Ouvrir le Validateur et ses diagnostics',
        kind: NarrativeCommandPaletteActionKind.validate,
        onInvoke: () => unawaited(
          selectNarrativeDestination(NarrativeStudioDestination.validator),
        ),
      ),
      NarrativeCommandPaletteAction(
        id: 'project.save',
        label: 'Enregistrer le projet',
        description: 'Sauvegarder les changements narratifs courants',
        shortcutLabel: '⌘ S',
        kind: NarrativeCommandPaletteActionKind.save,
        enabled: project != null,
        onInvoke: () {
          if (notifier.narrativeDocumentBlocksNavigation) {
            unawaited(notifier.saveNarrativeDocument());
          } else {
            unawaited(notifier.saveProjectManifest());
          }
        },
      ),
    ];

    final normalizedProjectIdentity = _narrativeProjectIdentity(
      projectRootPath: projectRootPath,
      project: project,
      projectSessionRevision: notifier.projectSessionRevision,
    );
    if (navigationState.projectIdentity != normalizedProjectIdentity) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(narrativeStudioNavigationControllerProvider.notifier)
            .resetForProject(
              normalizedProjectIdentity,
              initialLocation: workspaceLocation,
            );
      });
    }

    final isNarrativeWorkspace = switch (workspaceMode) {
      EditorWorkspaceMode.narrativeOverview ||
      EditorWorkspaceMode.globalStory ||
      EditorWorkspaceMode.scenes ||
      EditorWorkspaceMode.events ||
      EditorWorkspaceMode.step ||
      EditorWorkspaceMode.cutscene ||
      EditorWorkspaceMode.dialogue ||
      EditorWorkspaceMode.facts ||
      EditorWorkspaceMode.shops ||
      EditorWorkspaceMode.worldRules =>
        true,
      EditorWorkspaceMode.narrativeValidator => true,
      _ => false,
    };
    // NSC-13 adopts only Cinematics. Other Narrative Studio destinations keep
    // their existing undo stack until a later lot opts into this contract.
    final usesNarrativeDocumentSession =
        workspaceMode == EditorWorkspaceMode.cutscene;

    final supportsRightInspector = switch (workspaceMode) {
      _ when isNarrativeWorkspace => false,
      EditorWorkspaceMode.pokedex => false,
      EditorWorkspaceMode.pathStudio => false,
      EditorWorkspaceMode.environmentStudio => false,
      EditorWorkspaceMode.personalizationStudio => false,
      EditorWorkspaceMode.borderStudio => false,
      _ => true,
    };

    ref.listen(editorNotifierProvider.select((s) => s.errorMessage),
        (prev, next) {
      if (next != null) {
        _flashToast(next, isError: true);
      }
    });

    ref.listen(editorNotifierProvider.select((s) => s.statusMessage),
        (prev, next) {
      if (next != null) {
        _flashToast(next, isError: false);
      }
    });

    ref.listen(editorShellSnapshotProvider.select((s) => s.workspaceMode),
        (prev, next) {
      if (prev == EditorWorkspaceMode.borderStudio &&
          next != EditorWorkspaceMode.borderStudio) {
        unawaited(_confirmBorderStudioExit());
      }
      final wasNarrative = prev != null &&
          switch (prev) {
            EditorWorkspaceMode.narrativeOverview ||
            EditorWorkspaceMode.globalStory ||
            EditorWorkspaceMode.scenes ||
            EditorWorkspaceMode.events ||
            EditorWorkspaceMode.step ||
            EditorWorkspaceMode.cutscene ||
            EditorWorkspaceMode.dialogue ||
            EditorWorkspaceMode.facts ||
            EditorWorkspaceMode.shops ||
            EditorWorkspaceMode.worldRules =>
              true,
            EditorWorkspaceMode.narrativeValidator => true,
            _ => false,
          };
      final isNarrative = switch (next) {
        EditorWorkspaceMode.narrativeOverview ||
        EditorWorkspaceMode.globalStory ||
        EditorWorkspaceMode.scenes ||
        EditorWorkspaceMode.events ||
        EditorWorkspaceMode.step ||
        EditorWorkspaceMode.cutscene ||
        EditorWorkspaceMode.dialogue ||
        EditorWorkspaceMode.facts ||
        EditorWorkspaceMode.shops ||
        EditorWorkspaceMode.worldRules =>
          true,
        EditorWorkspaceMode.narrativeValidator => true,
        _ => false,
      };
      if (isNarrative && (prev == null || !wasNarrative)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _leftSidebarVisible = false;
            });
          }
        });
      }
      final location = narrativeStudioRouteLocationFor(next);
      if (location != null) {
        final navigation =
            ref.read(narrativeStudioNavigationControllerProvider);
        if (!_narrativeLocationMatchesWorkspace(
          navigation.location,
          next,
        )) {
          ref
              .read(narrativeStudioNavigationControllerProvider.notifier)
              .replace(location);
        }
      }
    });

    const double expandedWidth = 344.0;

    return Material(
      type: MaterialType.transparency,
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.keyZ, meta: true): _UndoIntent(),
          SingleActivator(LogicalKeyboardKey.keyZ, control: true):
              _UndoIntent(),
          SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
              _RedoIntent(),
          SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true):
              _RedoIntent(),
          SingleActivator(LogicalKeyboardKey.keyY, meta: true): _RedoIntent(),
          SingleActivator(LogicalKeyboardKey.keyY, control: true):
              _RedoIntent(),
          SingleActivator(LogicalKeyboardKey.keyS, meta: true): _SaveIntent(),
          SingleActivator(LogicalKeyboardKey.keyS, control: true):
              _SaveIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _UndoIntent: CallbackAction<_UndoIntent>(
              onInvoke: (_) {
                if (_isTextInputFocused()) return null;
                if (usesNarrativeDocumentSession &&
                    notifier.canUndoNarrativeDocument) {
                  unawaited(notifier.undoNarrativeDocument());
                  return null;
                }
                if (!shell.canUndoMap) return null;
                notifier.undoMap();
                return null;
              },
            ),
            _RedoIntent: CallbackAction<_RedoIntent>(
              onInvoke: (_) {
                if (_isTextInputFocused()) return null;
                if (usesNarrativeDocumentSession &&
                    notifier.canRedoNarrativeDocument) {
                  unawaited(notifier.redoNarrativeDocument());
                  return null;
                }
                if (!shell.canRedoMap) return null;
                notifier.redoMap();
                return null;
              },
            ),
            _SaveIntent: CallbackAction<_SaveIntent>(
              onInvoke: (_) {
                if (_isTextInputFocused()) return null;
                if (workspaceMode == EditorWorkspaceMode.map) {
                  if (!shell.canSaveMap) return null;
                  requestActiveMapSaveWithBorderPreviewGuard(
                    context: context,
                    notifier: notifier,
                  );
                  return null;
                }
                if (project == null) return null;
                if (notifier.narrativeDocumentBlocksNavigation) {
                  unawaited(notifier.saveNarrativeDocument());
                } else {
                  unawaited(notifier.saveProjectManifest());
                }
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: true,
            child: usesNarrativeStudioProductShell
                ? Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      NarrativeStudioProductShell(
                        selectedDestination:
                            selectedNarrativeLocation.destination,
                        selectedLocation: selectedNarrativeLocation,
                        onSelectDestination: selectNarrativeDestination,
                        onSelectLocation: selectNarrativeLocation,
                        globalSearchIndex: narrativeSearchIndex,
                        onOpenSearchEntry: (entry) =>
                            unawaited(openNarrativeSearchEntry(entry)),
                        commandPaletteActions: narrativeCommandPaletteActions,
                        onReturn: navigationState.pendingReturn == null
                            ? null
                            : () => unawaited(restoreNarrativeLocation()),
                        onOpenMaps: () async {
                          if (await guardNarrativeNavigation()) {
                            notifier.selectMapWorkspace();
                          }
                        },
                        project: project == null
                            ? null
                            : _NarrativeStudioProjectCard(
                                projectName: project.name,
                              ),
                        status: project == null
                            ? null
                            : _NarrativeStudioSaveStatus(
                                isDirty: projectIsDirty,
                              ),
                        documentActions: project == null ||
                                (!usesNarrativeDocumentSession &&
                                    !notifier.narrativeDocumentBlocksNavigation)
                            ? null
                            : const _NarrativeDocumentActions(),
                        workspace: workspaceMode == EditorWorkspaceMode.events
                            ? NarrativeStudioWorkspacePage(
                                presentation:
                                    narrativeStudioRoutePresentationForLocation(
                                  selectedNarrativeLocation,
                                ),
                                actions: eventSystemMode ==
                                        EventSystemMode.legacyOnly
                                    ? const []
                                    : [
                                        PokeMapButton(
                                          key: const ValueKey(
                                            'event-builder-v2-validate-project',
                                          ),
                                          onPressed: canRevalidateEventProject
                                              ? revalidateEventProject
                                              : null,
                                          size: PokeMapButtonSize.compact,
                                          variant: PokeMapButtonVariant
                                              .successOutline,
                                          leading: const Icon(
                                            CupertinoIcons.checkmark_shield,
                                          ),
                                          child: Text(
                                            context.pokeMapL10n.validate,
                                          ),
                                        ),
                                      ],
                                body: const EditorCanvasHost(),
                              )
                            : const EditorCanvasHost(),
                      ),
                      if (_toastMessage != null)
                        Positioned(
                          right: 24,
                          bottom: 24,
                          child: _EditorToastBanner(
                            message: _toastMessage!,
                            isError: _toastIsError,
                          ),
                        ),
                    ],
                  )
                : Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      DecoratedBox(
                        decoration: EditorChrome.appRootDecoration(context),
                        child: Stack(
                          children: [
                            const Positioned(
                              left: -120,
                              top: -120,
                              child: _AmbientGlow(
                                size: 460,
                                color: EditorChrome.accentPrimary,
                                opacity: 0.14,
                              ),
                            ),
                            const Positioned(
                              right: -100,
                              top: 40,
                              child: _AmbientGlow(
                                size: 400,
                                color: EditorChrome.accentLilac,
                                opacity: 0.1,
                              ),
                            ),
                            const Positioned(
                              right: -120,
                              top: 90,
                              child: _AmbientGlow(
                                size: 420,
                                color: EditorChrome.accentWarm,
                                opacity: 0.13,
                              ),
                            ),
                            const Positioned(
                              left: 140,
                              bottom: -160,
                              child: _AmbientGlow(
                                size: 520,
                                color: EditorChrome.accentJade,
                                opacity: 0.1,
                              ),
                            ),
                            const Positioned(
                              right: 220,
                              bottom: -140,
                              child: _AmbientGlow(
                                size: 420,
                                color: EditorChrome.accentCoral,
                                opacity: 0.09,
                              ),
                            ),
                            Builder(
                              builder: (context) {
                                if (workspaceMode == EditorWorkspaceMode.map) {
                                  return Column(
                                    children: [
                                      Expanded(
                                        child: WorldMapWorkspace(
                                          toolSlot: WorldMapToolbelt(
                                            onSave: () =>
                                                requestActiveMapSaveWithBorderPreviewGuard(
                                              context: context,
                                              notifier: notifier,
                                            ),
                                            onUndo: notifier.undoMap,
                                            onRedo: notifier.redoMap,
                                            onNewProject: () =>
                                                showTopToolbarNewProjectDialog(
                                              context,
                                              notifier,
                                            ),
                                            onOpenProject: () =>
                                                showTopToolbarOpenProjectDialog(
                                              context,
                                              notifier,
                                            ),
                                            onProjectSettings: project == null
                                                ? null
                                                : () =>
                                                    showTopToolbarProjectSettingsDialog(
                                                      context,
                                                      notifier,
                                                      project,
                                                    ),
                                            onExportGame: project == null ||
                                                    projectRootPath == null
                                                ? null
                                                : () =>
                                                    showTopToolbarGameExportDialog(
                                                      context,
                                                      projectRootPath:
                                                          projectRootPath,
                                                      projectName: project.name,
                                                    ),
                                            onNewMap: project == null ||
                                                    projectRootPath == null
                                                ? null
                                                : () =>
                                                    showTopToolbarNewMapDialog(
                                                      context,
                                                      notifier,
                                                      defaultWidth: project
                                                          .settings
                                                          .defaultMapWidth,
                                                      defaultHeight: project
                                                          .settings
                                                          .defaultMapHeight,
                                                    ),
                                            onResizeMap: activeMap == null
                                                ? null
                                                : () =>
                                                    showTopToolbarResizeMapDialog(
                                                      context,
                                                      notifier,
                                                      currentWidth:
                                                          activeMap.size.width,
                                                      currentHeight:
                                                          activeMap.size.height,
                                                    ),
                                            onActivationRejected: (reason) =>
                                                _flashToast(
                                              reason,
                                              isError: true,
                                            ),
                                          ),
                                          stageHeaderSlot: Consumer(
                                            builder: (context, ref, child) {
                                              final session = ref.watch(
                                                worldMapWorkspaceSessionProvider,
                                              );
                                              return _WorkspaceStageHeader(
                                                title: shell.workspaceTitle,
                                                subtitle:
                                                    shell.workspaceSubtitle,
                                                workspaceMode: workspaceMode,
                                                rightPanelVisible:
                                                    session.inspectorVisible,
                                                showRightPanelToggle: true,
                                                onToggleRightPanel: () {
                                                  ref
                                                      .read(
                                                        worldMapWorkspaceSessionProvider
                                                            .notifier,
                                                      )
                                                      .setInspectorVisible(
                                                        !session
                                                            .inspectorVisible,
                                                      );
                                                },
                                              );
                                            },
                                          ),
                                          explorerBuilder:
                                              (context, onCollapse) {
                                            return ProjectExplorerPanel(
                                              key: _projectExplorerKey,
                                              onOpenDependency: (intent) =>
                                                  unawaited(
                                                openNarrativeDependencyIntent(
                                                  intent,
                                                ),
                                              ),
                                              onCollapse: onCollapse,
                                            );
                                          },
                                          explorerRailBuilder:
                                              (context, onReopen) {
                                            return _CollapsedExpandButton(
                                              key: const ValueKey<String>(
                                                'project-explorer-reopen-toggle',
                                              ),
                                              onTap: onReopen,
                                            );
                                          },
                                        ),
                                      ),
                                      const StatusBar(),
                                    ],
                                  );
                                }
                                final colors = context.pokeMapColors;
                                return Column(
                                  children: [
                                    TopToolbar(
                                      onToggleRightPanel: () {
                                        setState(() {
                                          _rightInspectorVisible =
                                              !_rightInspectorVisible;
                                        });
                                      },
                                      rightPanelVisible: _rightInspectorVisible,
                                    ),
                                    Expanded(
                                      child: TweenAnimationBuilder<double>(
                                        tween: Tween<double>(
                                          begin: _leftSidebarVisible
                                              ? expandedWidth
                                              : 52.0,
                                          end: _leftSidebarVisible
                                              ? expandedWidth
                                              : 52.0,
                                        ),
                                        duration:
                                            const Duration(milliseconds: 150),
                                        curve: Curves.easeInOutCubic,
                                        builder: (context, animWidth, child) {
                                          return LayoutBuilder(
                                            builder:
                                                (context, stageConstraints) {
                                              final compactExplorerForStage =
                                                  _leftSidebarVisible &&
                                                      supportsRightInspector &&
                                                      _rightInspectorVisible &&
                                                      stageConstraints
                                                              .maxWidth <
                                                          expandedWidth +
                                                              _kRightInspectorMinWidth +
                                                              _kRightInspectorResizeHandleWidth +
                                                              _kCenterStageMinWidth;
                                              final effectiveExplorerExpanded =
                                                  _leftSidebarVisible &&
                                                      !compactExplorerForStage;
                                              final effectiveExplorerWidth =
                                                  compactExplorerForStage
                                                      ? 52.0
                                                      : animWidth;
                                              final availableInspectorMaxWidth =
                                                  math.max(
                                                _kRightInspectorMinWidth,
                                                math.min(
                                                  _kRightInspectorMaxWidth,
                                                  stageConstraints.maxWidth -
                                                      effectiveExplorerWidth -
                                                      _kRightInspectorResizeHandleWidth -
                                                      _kCenterStageMinWidth,
                                                ),
                                              );
                                              final effectiveInspectorWidth =
                                                  _rightInspectorWidth
                                                      .clamp(
                                                        _kRightInspectorMinWidth,
                                                        availableInspectorMaxWidth,
                                                      )
                                                      .toDouble();
                                              return Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  SizedBox(
                                                    width:
                                                        effectiveExplorerWidth,
                                                    child: KeyedSubtree(
                                                      key: const ValueKey<
                                                          String>(
                                                        'project-explorer-region',
                                                      ),
                                                      child: OverflowBox(
                                                        minWidth: 52,
                                                        maxWidth:
                                                            isNarrativeWorkspace
                                                                ? 460
                                                                : 520,
                                                        alignment:
                                                            Alignment.topLeft,
                                                        child: SizedBox(
                                                          width:
                                                              effectiveExplorerWidth,
                                                          child: Stack(
                                                            clipBehavior:
                                                                Clip.hardEdge,
                                                            children: [
                                                              Positioned(
                                                                left: 0,
                                                                top: 0,
                                                                bottom: 0,
                                                                width:
                                                                    expandedWidth,
                                                                child:
                                                                    AnimatedOpacity(
                                                                  key: const ValueKey<
                                                                      String>(
                                                                    'project-explorer-expanded-state',
                                                                  ),
                                                                  duration:
                                                                      const Duration(
                                                                    milliseconds:
                                                                        100,
                                                                  ),
                                                                  opacity:
                                                                      effectiveExplorerExpanded
                                                                          ? 1.0
                                                                          : 0.0,
                                                                  child:
                                                                      IgnorePointer(
                                                                    ignoring:
                                                                        !effectiveExplorerExpanded,
                                                                    child:
                                                                        KeyedSubtree(
                                                                      key: const ValueKey<
                                                                          String>(
                                                                        'project-explorer-expanded',
                                                                      ),
                                                                      child:
                                                                          Padding(
                                                                        padding:
                                                                            const EdgeInsets.fromLTRB(
                                                                          16,
                                                                          18,
                                                                          12,
                                                                          18,
                                                                        ),
                                                                        child:
                                                                            ProjectExplorerPanel(
                                                                          key:
                                                                              _projectExplorerKey,
                                                                          onOpenDependency: (intent) =>
                                                                              unawaited(
                                                                            openNarrativeDependencyIntent(
                                                                              intent,
                                                                            ),
                                                                          ),
                                                                          onCollapse:
                                                                              () {
                                                                            setState(() {
                                                                              _leftSidebarVisible = false;
                                                                              if (workspaceMode == EditorWorkspaceMode.map && activeMap != null) {
                                                                                _rightInspectorWidth = _kRightInspectorMaxWidth;
                                                                              }
                                                                            });
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              Positioned(
                                                                left: 0,
                                                                right: 0,
                                                                top: 14,
                                                                child:
                                                                    AnimatedOpacity(
                                                                  key: const ValueKey<
                                                                      String>(
                                                                    'project-explorer-reduced-state',
                                                                  ),
                                                                  duration:
                                                                      const Duration(
                                                                    milliseconds:
                                                                        100,
                                                                  ),
                                                                  opacity:
                                                                      !effectiveExplorerExpanded
                                                                          ? 1.0
                                                                          : 0.0,
                                                                  child:
                                                                      IgnorePointer(
                                                                    ignoring:
                                                                        effectiveExplorerExpanded,
                                                                    child:
                                                                        KeyedSubtree(
                                                                      key: const ValueKey<
                                                                          String>(
                                                                        'project-explorer-reduced',
                                                                      ),
                                                                      child:
                                                                          Column(
                                                                        children: [
                                                                          _CollapsedExpandButton(
                                                                            key:
                                                                                const ValueKey<String>(
                                                                              'project-explorer-reopen-toggle',
                                                                            ),
                                                                            onTap:
                                                                                () {
                                                                              setState(() {
                                                                                _leftSidebarVisible = true;
                                                                                if (compactExplorerForStage) {
                                                                                  _rightInspectorVisible = false;
                                                                                }
                                                                              });
                                                                            },
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.fromLTRB(
                                                        isNarrativeWorkspace
                                                            ? 10
                                                            : 18,
                                                        isNarrativeWorkspace
                                                            ? 12
                                                            : 18,
                                                        isNarrativeWorkspace
                                                            ? 10
                                                            : 18,
                                                        isNarrativeWorkspace
                                                            ? 6
                                                            : 8,
                                                      ),
                                                      child: EditorIsland(
                                                        radius: 36,
                                                        tint: EditorChrome
                                                            .islandCoolTint,
                                                        child: Padding(
                                                          padding: EdgeInsets
                                                              .fromLTRB(
                                                            isNarrativeWorkspace
                                                                ? 12
                                                                : 18,
                                                            isNarrativeWorkspace
                                                                ? 12
                                                                : 18,
                                                            isNarrativeWorkspace
                                                                ? 12
                                                                : 18,
                                                            isNarrativeWorkspace
                                                                ? 10
                                                                : 16,
                                                          ),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .stretch,
                                                            children: [
                                                              if (!isNarrativeWorkspace) ...[
                                                                _WorkspaceStageHeader(
                                                                  title: shell
                                                                      .workspaceTitle,
                                                                  subtitle: shell
                                                                      .workspaceSubtitle,
                                                                  workspaceMode:
                                                                      workspaceMode,
                                                                  rightPanelVisible:
                                                                      _rightInspectorVisible,
                                                                  showRightPanelToggle:
                                                                      supportsRightInspector,
                                                                  onToggleRightPanel:
                                                                      () {
                                                                    setState(
                                                                        () {
                                                                      _rightInspectorVisible =
                                                                          !_rightInspectorVisible;
                                                                    });
                                                                  },
                                                                ),
                                                                const SizedBox(
                                                                    height: 18),
                                                              ],
                                                              Expanded(
                                                                child: workspaceMode ==
                                                                            EditorWorkspaceMode
                                                                                .map &&
                                                                        activeMap !=
                                                                            null
                                                                    ? Container(
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          color:
                                                                              colors.backgroundApp,
                                                                          borderRadius:
                                                                              BorderRadius.circular(20),
                                                                          border:
                                                                              Border.all(
                                                                            color:
                                                                                colors.borderSubtle,
                                                                            width:
                                                                                1.5,
                                                                          ),
                                                                          boxShadow: const [
                                                                            BoxShadow(
                                                                              color: Color(0x1F000000),
                                                                              blurRadius: 8,
                                                                              offset: Offset(0, 4),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        child:
                                                                            ClipRRect(
                                                                          borderRadius:
                                                                              BorderRadius.circular(19),
                                                                          child:
                                                                              Padding(
                                                                            padding:
                                                                                EdgeInsets.all(
                                                                              isNarrativeWorkspace ? 8 : 14,
                                                                            ),
                                                                            child:
                                                                                const EditorCanvasHost(),
                                                                          ),
                                                                        ),
                                                                      )
                                                                    : ClipRRect(
                                                                        borderRadius:
                                                                            BorderRadius.circular(26),
                                                                        child:
                                                                            Padding(
                                                                          padding:
                                                                              EdgeInsets.all(
                                                                            isNarrativeWorkspace
                                                                                ? 8
                                                                                : 14,
                                                                          ),
                                                                          child:
                                                                              const EditorCanvasHost(),
                                                                        ),
                                                                      ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  if (supportsRightInspector &&
                                                      _rightInspectorVisible) ...[
                                                    PokeMapHorizontalResizeHandle(
                                                      key: const ValueKey<
                                                          String>(
                                                        'right-inspector-resize-handle',
                                                      ),
                                                      tooltip:
                                                          'Redimensionner le panneau droit',
                                                      width:
                                                          _kRightInspectorResizeHandleWidth,
                                                      onDrag: (delta) {
                                                        setState(() {
                                                          _rightInspectorWidth =
                                                              (effectiveInspectorWidth -
                                                                      delta)
                                                                  .clamp(
                                                                    _kRightInspectorMinWidth,
                                                                    availableInspectorMaxWidth,
                                                                  )
                                                                  .toDouble();
                                                        });
                                                      },
                                                    ),
                                                    SizedBox(
                                                      key: const ValueKey<
                                                          String>(
                                                        'right-inspector-region',
                                                      ),
                                                      width:
                                                          effectiveInspectorWidth,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .fromLTRB(
                                                                12, 18, 16, 18),
                                                        child: EditorIsland(
                                                          radius: 32,
                                                          tint: switch (
                                                              workspaceMode) {
                                                            EditorWorkspaceMode
                                                                  .map =>
                                                              EditorChrome
                                                                  .islandNeutralTint,
                                                            EditorWorkspaceMode
                                                                  .tileset =>
                                                              EditorChrome
                                                                  .islandWarmTint,
                                                            EditorWorkspaceMode
                                                                  .trainer =>
                                                              EditorChrome
                                                                  .islandWarmTint,
                                                            EditorWorkspaceMode
                                                                  .pokedex =>
                                                              EditorChrome
                                                                  .islandWarmTint,
                                                            EditorWorkspaceMode
                                                                  .narrativeOverview =>
                                                              EditorChrome
                                                                  .islandCoolTint,
                                                            EditorWorkspaceMode
                                                                  .globalStory =>
                                                              EditorChrome
                                                                  .islandCoolTint,
                                                            EditorWorkspaceMode
                                                                  .scenes =>
                                                              EditorChrome
                                                                  .islandCoolTint,
                                                            EditorWorkspaceMode
                                                                  .events =>
                                                              EditorChrome
                                                                  .islandCoolTint,
                                                            EditorWorkspaceMode
                                                                  .step =>
                                                              EditorChrome
                                                                  .islandWarmTint,
                                                            EditorWorkspaceMode
                                                                  .cutscene =>
                                                              EditorChrome
                                                                  .islandNeutralTint,
                                                            EditorWorkspaceMode
                                                                  .dialogue =>
                                                              EditorChrome
                                                                  .islandCoolTint,
                                                            EditorWorkspaceMode
                                                                  .facts =>
                                                              EditorChrome
                                                                  .islandCoolTint,
                                                            EditorWorkspaceMode
                                                                  .shops =>
                                                              EditorChrome
                                                                  .islandCoolTint,
                                                            EditorWorkspaceMode
                                                                  .worldRules =>
                                                              EditorChrome
                                                                  .islandCoolTint,
                                                            EditorWorkspaceMode
                                                                  .narrativeValidator =>
                                                              EditorChrome
                                                                  .islandCoolTint,
                                                            EditorWorkspaceMode
                                                                  .pathStudio =>
                                                              EditorChrome
                                                                  .islandCoolTint,
                                                            EditorWorkspaceMode
                                                                  .environmentStudio =>
                                                              EditorChrome
                                                                  .islandWarmTint,
                                                            EditorWorkspaceMode
                                                                  .personalizationStudio =>
                                                              EditorChrome
                                                                  .islandWarmTint,
                                                            EditorWorkspaceMode
                                                                  .borderStudio =>
                                                              EditorChrome
                                                                  .islandCoolTint,
                                                          },
                                                          child: switch (
                                                              workspaceMode) {
                                                            EditorWorkspaceMode
                                                                  .map =>
                                                              const SizedBox
                                                                  .shrink(),
                                                            EditorWorkspaceMode
                                                                  .tileset =>
                                                              const TilesetPalettePanel(),
                                                            EditorWorkspaceMode
                                                                  .trainer =>
                                                              const _EmptyWorkspaceInspector(),
                                                            EditorWorkspaceMode
                                                                  .pokedex =>
                                                              const _EmptyWorkspaceInspector(),
                                                            EditorWorkspaceMode
                                                                  .narrativeOverview =>
                                                              const _EmptyWorkspaceInspector(),
                                                            EditorWorkspaceMode
                                                                  .scenes =>
                                                              const _EmptyWorkspaceInspector(),
                                                            EditorWorkspaceMode
                                                                  .events =>
                                                              const _EmptyWorkspaceInspector(),
                                                            EditorWorkspaceMode
                                                                  .facts =>
                                                              const _EmptyWorkspaceInspector(),
                                                            EditorWorkspaceMode
                                                                  .shops =>
                                                              const _EmptyWorkspaceInspector(),
                                                            EditorWorkspaceMode
                                                                  .worldRules =>
                                                              const _EmptyWorkspaceInspector(),
                                                            EditorWorkspaceMode
                                                                  .narrativeValidator =>
                                                              const _EmptyWorkspaceInspector(),
                                                            EditorWorkspaceMode
                                                                  .pathStudio =>
                                                              const _EmptyWorkspaceInspector(),
                                                            EditorWorkspaceMode
                                                                  .environmentStudio =>
                                                              const _EmptyWorkspaceInspector(),
                                                            EditorWorkspaceMode
                                                                  .personalizationStudio =>
                                                              const _EmptyWorkspaceInspector(),
                                                            EditorWorkspaceMode
                                                                  .borderStudio =>
                                                              const _EmptyWorkspaceInspector(),
                                                            EditorWorkspaceMode
                                                                .globalStory ||
                                                            EditorWorkspaceMode
                                                                .step ||
                                                            EditorWorkspaceMode
                                                                .cutscene ||
                                                            EditorWorkspaceMode
                                                                  .dialogue =>
                                                              const _EmptyWorkspaceInspector(),
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                    const StatusBar(),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      if (_toastMessage != null)
                        Positioned(
                          right: 24,
                          bottom: 72,
                          child: _EditorToastBanner(
                            message: _toastMessage!,
                            isError: _toastIsError,
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmBorderStudioExit() async {
    if (_isHandlingBorderExit) return;
    final draftState = ref.read(borderStudioDraftControllerProvider);
    if (!draftState.isDirty) return;
    _isHandlingBorderExit = true;
    final choice = await showDialog<_BorderStudioExitChoice>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final colors = dialogContext.pokeMapColors;
        return Dialog(
          backgroundColor: colors.cardSurface,
          child: SizedBox(
            width: 520,
            child: PokeMapPanel(
              header: const Padding(
                padding: EdgeInsets.all(16),
                child: PokeMapSectionHeader(
                  title: 'Brouillon non enregistré',
                  description:
                      'Choisissez explicitement quoi faire avant de quitter Border Studio.',
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Aucun changement ne sera publié automatiquement.',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      PokeMapButton(
                        onPressed: () => Navigator.of(dialogContext).pop(
                          _BorderStudioExitChoice.stay,
                        ),
                        variant: PokeMapButtonVariant.secondary,
                        child: const Text('Rester'),
                      ),
                      PokeMapButton(
                        onPressed: () => Navigator.of(dialogContext).pop(
                          _BorderStudioExitChoice.discard,
                        ),
                        variant: PokeMapButtonVariant.danger,
                        child: const Text('Abandonner les modifications'),
                      ),
                      PokeMapButton(
                        onPressed: () => Navigator.of(dialogContext).pop(
                          _BorderStudioExitChoice.save,
                        ),
                        child: const Text('Enregistrer'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (!mounted) return;
    final controller = ref.read(borderStudioDraftControllerProvider.notifier);
    switch (choice) {
      case _BorderStudioExitChoice.save:
        final updated = controller.saveDraft();
        ref.read(editorNotifierProvider.notifier).applyInMemoryProjectManifest(
              updated,
              statusMessage: 'Brouillon Border enregistré dans le projet.',
            );
      case _BorderStudioExitChoice.discard:
        controller.reloadFromManifest(ref.read(editorProjectManifestProvider));
      case _BorderStudioExitChoice.stay:
      case null:
        ref.read(editorNotifierProvider.notifier).selectBorderStudioWorkspace();
    }
    _isHandlingBorderExit = false;
  }
}

bool _narrativeLocationMatchesWorkspace(
  NarrativeStudioRouteLocation location,
  EditorWorkspaceMode workspaceMode,
) {
  return switch (workspaceMode) {
    EditorWorkspaceMode.narrativeOverview =>
      location.destination == NarrativeStudioDestination.overview,
    EditorWorkspaceMode.globalStory =>
      location.childRoute == NarrativeStudioChildRoute.storylineLibrary,
    EditorWorkspaceMode.step =>
      location.childRoute == NarrativeStudioChildRoute.storylineStep,
    EditorWorkspaceMode.scenes =>
      location.destination == NarrativeStudioDestination.scenes,
    EditorWorkspaceMode.events =>
      location.destination == NarrativeStudioDestination.events,
    EditorWorkspaceMode.cutscene =>
      location.destination == NarrativeStudioDestination.cinematics,
    EditorWorkspaceMode.dialogue =>
      location.destination == NarrativeStudioDestination.dialogues,
    EditorWorkspaceMode.facts =>
      location.destination == NarrativeStudioDestination.facts,
    EditorWorkspaceMode.shops =>
      location.destination == NarrativeStudioDestination.shops,
    EditorWorkspaceMode.worldRules =>
      location.destination == NarrativeStudioDestination.worldRules,
    EditorWorkspaceMode.narrativeValidator =>
      location.destination == NarrativeStudioDestination.validator,
    _ => false,
  };
}

String? _narrativeProjectIdentity({
  required String? projectRootPath,
  required ProjectManifest? project,
  required int projectSessionRevision,
}) {
  final normalizedRoot = projectRootPath?.trim();
  if (normalizedRoot != null && normalizedRoot.isNotEmpty) {
    return 'disk:$normalizedRoot\u001esession:$projectSessionRevision';
  }
  if (project == null) return null;
  final mapIds = project.maps.map((entry) => entry.id).join('\u001f');
  return 'memory:${project.name.trim()}\u001e$mapIds'
      '\u001esession:$projectSessionRevision';
}

class _NarrativeStudioProjectCard extends StatelessWidget {
  const _NarrativeStudioProjectCard({required this.projectName});

  final String projectName;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/branding/pokemap_event_builder_project_thumb.png',
              width: 26,
              height: 26,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              projectName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NarrativeStudioSaveStatus extends StatelessWidget {
  const _NarrativeStudioSaveStatus({required this.isDirty});

  final bool isDirty;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.circle_fill,
            size: 7,
            color: isDirty ? colors.warning : colors.success,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              isDirty
                  ? context.pokeMapL10n.unsavedChanges
                  : context.pokeMapL10n.allChangesSaved,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorToastBanner extends StatelessWidget {
  const _EditorToastBanner({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final tint = isError
        ? EditorChrome.errorTint(context)
        : EditorChrome.statusTint(context);
    final accent = isError
        ? EditorChrome.inspectorJoyCoral
        : EditorChrome.inspectorJoyMint;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: EditorIsland(
        radius: 18,
        tint: tint,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(CupertinoColors.white, accent, 0.75)!,
                      Color.lerp(accent, const Color(0xFF102010), 0.35)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.88),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: MacosIcon(
                  isError
                      ? CupertinoIcons.exclamationmark_triangle_fill
                      : CupertinoIcons.check_mark_circled_solid,
                  color: CupertinoColors.white,
                  size: 15,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkspaceStageHeader extends ConsumerWidget {
  const _WorkspaceStageHeader({
    required this.title,
    required this.subtitle,
    required this.workspaceMode,
    required this.rightPanelVisible,
    required this.showRightPanelToggle,
    required this.onToggleRightPanel,
  });

  final String title;
  final String subtitle;
  final EditorWorkspaceMode workspaceMode;
  final bool rightPanelVisible;
  final bool showRightPanelToggle;
  final VoidCallback onToggleRightPanel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.pokeMapColors;
    final activeMap =
        ref.watch(editorNotifierProvider.select((s) => s.activeMap));
    final notifier = ref.read(editorNotifierProvider.notifier);

    final chipAccent = switch (workspaceMode) {
      EditorWorkspaceMode.map => colors.brandPrimary,
      EditorWorkspaceMode.tileset => colors.brandCyan,
      EditorWorkspaceMode.trainer => colors.combat,
      EditorWorkspaceMode.pokedex => colors.reward,
      EditorWorkspaceMode.narrativeOverview ||
      EditorWorkspaceMode.globalStory ||
      EditorWorkspaceMode.scenes ||
      EditorWorkspaceMode.events ||
      EditorWorkspaceMode.step ||
      EditorWorkspaceMode.cutscene ||
      EditorWorkspaceMode.dialogue ||
      EditorWorkspaceMode.facts ||
      EditorWorkspaceMode.shops ||
      EditorWorkspaceMode.worldRules ||
      EditorWorkspaceMode.narrativeValidator =>
        colors.narrative,
      EditorWorkspaceMode.pathStudio => colors.brandPrimary,
      EditorWorkspaceMode.environmentStudio => colors.mapAccent,
      EditorWorkspaceMode.personalizationStudio => colors.reward,
      EditorWorkspaceMode.borderStudio => colors.brandCyan,
    };

    final badgeVariant = switch (workspaceMode) {
      EditorWorkspaceMode.map => PokeMapBadgeVariant.mapAccent,
      EditorWorkspaceMode.tileset => PokeMapBadgeVariant.neutral,
      EditorWorkspaceMode.trainer => PokeMapBadgeVariant.combat,
      EditorWorkspaceMode.pokedex => PokeMapBadgeVariant.info,
      EditorWorkspaceMode.narrativeOverview ||
      EditorWorkspaceMode.globalStory ||
      EditorWorkspaceMode.scenes ||
      EditorWorkspaceMode.events ||
      EditorWorkspaceMode.step ||
      EditorWorkspaceMode.cutscene ||
      EditorWorkspaceMode.dialogue ||
      EditorWorkspaceMode.facts ||
      EditorWorkspaceMode.shops ||
      EditorWorkspaceMode.worldRules ||
      EditorWorkspaceMode.narrativeValidator =>
        PokeMapBadgeVariant.narrative,
      _ => PokeMapBadgeVariant.neutral,
    };

    final badgeLabel = switch (workspaceMode) {
      EditorWorkspaceMode.map => 'Scène',
      EditorWorkspaceMode.tileset => 'Bibliothèque',
      EditorWorkspaceMode.trainer => 'Dresseurs',
      EditorWorkspaceMode.pokedex => 'Catalogues',
      EditorWorkspaceMode.narrativeOverview => 'Aperçu',
      EditorWorkspaceMode.globalStory => 'Macro-Récit',
      EditorWorkspaceMode.scenes => 'Scènes',
      EditorWorkspaceMode.events => 'Événements',
      EditorWorkspaceMode.step => 'Étapes',
      EditorWorkspaceMode.cutscene => 'Cinématiques',
      EditorWorkspaceMode.dialogue => 'Dialogue',
      EditorWorkspaceMode.facts => 'Facts',
      EditorWorkspaceMode.shops => 'Boutiques',
      EditorWorkspaceMode.worldRules => 'Règles',
      EditorWorkspaceMode.narrativeValidator => 'Validateur',
      EditorWorkspaceMode.pathStudio => 'Chemins',
      EditorWorkspaceMode.environmentStudio => 'Envs',
      EditorWorkspaceMode.personalizationStudio => 'Style',
      EditorWorkspaceMode.borderStudio => 'Bordures',
    };

    if (workspaceMode == EditorWorkspaceMode.map && activeMap != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colors.borderSubtle,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: MacosIcon(
                  CupertinoIcons.map,
                  color: chipAccent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 46),
            child: Text(
              subtitle,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 46),
            child: Row(
              children: [
                const PokeMapBadge(
                  label: 'Scène',
                  variant: PokeMapBadgeVariant.mapAccent,
                ),
                const SizedBox(width: 8),
                if (showRightPanelToggle) ...[
                  MacosTooltip(
                    message: rightPanelVisible
                        ? 'Masquer le panneau'
                        : 'Afficher le panneau',
                    child: MacosIconButton(
                      semanticLabel: rightPanelVisible
                          ? 'Hide right panel'
                          : 'Show right panel',
                      icon: MacosIcon(
                        rightPanelVisible
                            ? Icons.open_in_full
                            : Icons.close_fullscreen,
                        color: colors.textPrimary.withValues(alpha: 0.85),
                        size: 14,
                      ),
                      backgroundColor: colors.surfaceSubtle,
                      hoverColor: colors.surfaceHover,
                      onPressed: onToggleRightPanel,
                      boxConstraints: const BoxConstraints(
                        minWidth: 28,
                        maxWidth: 28,
                        minHeight: 28,
                        maxHeight: 28,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                MacosTooltip(
                  message: 'Options de carte',
                  child: MacosPulldownButton(
                    icon: CupertinoIcons.ellipsis,
                    items: [
                      MacosPulldownMenuItem(
                        label: 'Redimensionner la carte',
                        title: const Text('Redimensionner la carte'),
                        onTap: () {
                          showTopToolbarResizeMapDialog(
                            context,
                            notifier,
                            currentWidth: activeMap.size.width,
                            currentHeight: activeMap.size.height,
                          );
                        },
                      ),
                      if (activeMap.visualStack !=
                          MapVisualStackConfig.canonicalV1)
                        MacosPulldownMenuItem(
                          label: 'Migrer la pile visuelle',
                          title: const Text('Migrer la pile visuelle'),
                          onTap: () {
                            showTopToolbarVisualStackMigrationDialog(
                              context,
                              notifier,
                            );
                          },
                        ),
                      MacosPulldownMenuItem(
                        label: 'Sauvegarder la carte',
                        title: const Text('Sauvegarder la carte'),
                        onTap: () => requestActiveMapSaveWithBorderPreviewGuard(
                          context: context,
                          notifier: notifier,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.surfaceSubtle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.borderSubtle,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: MacosIcon(
            switch (workspaceMode) {
              EditorWorkspaceMode.map => CupertinoIcons.map,
              EditorWorkspaceMode.tileset => CupertinoIcons.square_grid_2x2,
              EditorWorkspaceMode.trainer => CupertinoIcons.person_3_fill,
              EditorWorkspaceMode.pokedex => CupertinoIcons.book,
              EditorWorkspaceMode.narrativeOverview => CupertinoIcons.house,
              EditorWorkspaceMode.globalStory => CupertinoIcons.link,
              EditorWorkspaceMode.scenes => CupertinoIcons.square_stack_3d_up,
              EditorWorkspaceMode.events =>
                CupertinoIcons.bolt_horizontal_circle,
              EditorWorkspaceMode.step => CupertinoIcons.flag,
              EditorWorkspaceMode.cutscene => CupertinoIcons.play_rectangle,
              EditorWorkspaceMode.dialogue => CupertinoIcons.text_bubble,
              EditorWorkspaceMode.facts => CupertinoIcons.doc_text,
              EditorWorkspaceMode.shops => CupertinoIcons.cart,
              EditorWorkspaceMode.worldRules => CupertinoIcons.checkmark_seal,
              EditorWorkspaceMode.narrativeValidator =>
                CupertinoIcons.checkmark_shield,
              EditorWorkspaceMode.pathStudio => CupertinoIcons.arrow_branch,
              EditorWorkspaceMode.environmentStudio => CupertinoIcons.tree,
              EditorWorkspaceMode.personalizationStudio =>
                CupertinoIcons.paintbrush,
              EditorWorkspaceMode.borderStudio =>
                CupertinoIcons.square_on_square,
            },
            color: chipAccent,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                key: workspaceMode == EditorWorkspaceMode.environmentStudio
                    ? const Key('environment-studio-title')
                    : (workspaceMode ==
                            EditorWorkspaceMode.personalizationStudio
                        ? const Key('personalization-studio-title')
                        : (workspaceMode == EditorWorkspaceMode.borderStudio
                            ? const Key('border-studio-title')
                            : (workspaceMode == EditorWorkspaceMode.trainer
                                ? const Key('trainer-studio-title')
                                : null))),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
        if (showRightPanelToggle) ...[
          MacosTooltip(
            message: rightPanelVisible
                ? 'Masquer le panneau'
                : 'Afficher le panneau',
            child: MacosIconButton(
              semanticLabel:
                  rightPanelVisible ? 'Hide right panel' : 'Show right panel',
              icon: MacosIcon(
                rightPanelVisible ? Icons.open_in_full : Icons.close_fullscreen,
                color: colors.textPrimary.withValues(alpha: 0.85),
                size: 16,
              ),
              backgroundColor: CupertinoColors.transparent,
              hoverColor: colors.surfaceHover,
              onPressed: onToggleRightPanel,
              boxConstraints: const BoxConstraints(
                minWidth: 32,
                maxWidth: 32,
                minHeight: 32,
                maxHeight: 32,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 8),
        ],
        PokeMapBadge(
          label: badgeLabel,
          variant: badgeVariant,
        ),
      ],
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: opacity * 0.4),
              color.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.38, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Panneau droit volontairement neutre pour les workspaces qui n'ont pas
/// encore d'inspecteur réel.
///
/// Pour le lot 12, cela permet de garder la structure visuelle existante de
/// l'éditeur sans inventer un inspecteur Pokédex artificiel, ni brancher une
/// logique future avant l'heure.
class _EmptyWorkspaceInspector extends StatelessWidget {
  const _EmptyWorkspaceInspector();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Cette section n’a pas encore d’inspecteur dédié.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: CupertinoColors.placeholderText.resolveFrom(context),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

bool _isTextInputFocused() {
  final focusedContext = FocusManager.instance.primaryFocus?.context;
  if (focusedContext == null) return false;
  return focusedContext.widget is EditableText ||
      focusedContext.findAncestorWidgetOfExactType<EditableText>() != null;
}

enum _UnsavedChoice { cancel, discard, save }

class _NarrativeDocumentActions extends ConsumerWidget {
  const _NarrativeDocumentActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The session lives beside EditorState, so observing the state keeps these
    // controls synchronized with session notifications without exposing a
    // second Riverpod source of truth.
    ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final l10n = context.pokeMapL10n;
    final status = notifier.narrativeDocumentStatus;
    if (status == null) return const SizedBox.shrink();
    final isSaving = status == NarrativeDocumentSessionStatus.saving;
    final isConflicted = status == NarrativeDocumentSessionStatus.conflicted;
    final blocksNavigation = notifier.narrativeDocumentBlocksNavigation;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PokeMapBadge(
          label: _narrativeDocumentStatusLabel(context, status),
          variant: _narrativeDocumentStatusVariant(status),
        ),
        const SizedBox(width: 8),
        PokeMapIconButton(
          key: narrativeDocumentUndoActionKey,
          onPressed: !isSaving && notifier.canUndoNarrativeDocument
              ? () => unawaited(notifier.undoNarrativeDocument())
              : null,
          tooltip: l10n.narrativeUndoTooltip,
          variant: PokeMapIconButtonVariant.soft,
          icon: const Icon(CupertinoIcons.arrow_uturn_left),
        ),
        const SizedBox(width: 4),
        PokeMapIconButton(
          key: narrativeDocumentRedoActionKey,
          onPressed: !isSaving && notifier.canRedoNarrativeDocument
              ? () => unawaited(notifier.redoNarrativeDocument())
              : null,
          tooltip: l10n.narrativeRedoTooltip,
          variant: PokeMapIconButtonVariant.soft,
          icon: const Icon(CupertinoIcons.arrow_uturn_right),
        ),
        const SizedBox(width: 4),
        PokeMapIconButton(
          key: narrativeDocumentSaveActionKey,
          onPressed: !isSaving && !isConflicted && blocksNavigation
              ? () => unawaited(notifier.saveNarrativeDocument())
              : null,
          tooltip: l10n.narrativeSaveTooltip,
          variant: PokeMapIconButtonVariant.soft,
          icon: const Icon(CupertinoIcons.floppy_disk),
        ),
        const SizedBox(width: 4),
        PokeMapIconButton(
          key: narrativeDocumentAutosaveActionKey,
          onPressed: isSaving
              ? null
              : () => unawaited(
                    notifier.setNarrativeDocumentAutosaveEnabled(
                      !notifier.narrativeDocumentAutosaveEnabled,
                    ),
                  ),
          tooltip: notifier.narrativeDocumentAutosaveEnabled
              ? l10n.narrativeAutosaveDisableTooltip
              : l10n.narrativeAutosaveEnableTooltip,
          variant: PokeMapIconButtonVariant.soft,
          isSelected: notifier.narrativeDocumentAutosaveEnabled,
          icon: const Icon(CupertinoIcons.arrow_2_circlepath),
        ),
        if (isConflicted) ...[
          const SizedBox(width: 4),
          PokeMapIconButton(
            key: narrativeDocumentCompareActionKey,
            onPressed: () => _showNarrativeDocumentComparison(
              context,
              notifier.narrativeDocumentComparison,
            ),
            tooltip: l10n.narrativeCompareTooltip,
            variant: PokeMapIconButtonVariant.soft,
            icon: const Icon(CupertinoIcons.rectangle_split_3x1),
          ),
          const SizedBox(width: 4),
          PokeMapIconButton(
            key: narrativeDocumentReloadActionKey,
            onPressed: () =>
                unawaited(notifier.reloadExternalNarrativeDocument()),
            tooltip: l10n.narrativeReloadTooltip,
            variant: PokeMapIconButtonVariant.soft,
            icon: const Icon(CupertinoIcons.arrow_clockwise),
          ),
          const SizedBox(width: 4),
          PokeMapIconButton(
            key: narrativeDocumentKeepLocalActionKey,
            onPressed: () => unawaited(notifier.keepLocalNarrativeDocument()),
            tooltip: l10n.narrativeKeepLocalTooltip,
            variant: PokeMapIconButtonVariant.soft,
            icon: const Icon(CupertinoIcons.square_arrow_down),
          ),
        ],
        if (blocksNavigation) ...[
          const SizedBox(width: 4),
          PokeMapIconButton(
            key: narrativeDocumentDiscardActionKey,
            onPressed: isSaving
                ? null
                : () => unawaited(notifier.discardNarrativeDocument()),
            tooltip: l10n.narrativeDiscardTooltip,
            variant: PokeMapIconButtonVariant.danger,
            icon: const Icon(CupertinoIcons.trash),
          ),
        ],
      ],
    );
  }
}

String _narrativeDocumentStatusLabel(
  BuildContext context,
  NarrativeDocumentSessionStatus status,
) {
  final l10n = context.pokeMapL10n;
  return switch (status) {
    NarrativeDocumentSessionStatus.saved => l10n.narrativeStatusSaved,
    NarrativeDocumentSessionStatus.dirty => l10n.narrativeStatusDirty,
    NarrativeDocumentSessionStatus.saving => l10n.narrativeStatusSaving,
    NarrativeDocumentSessionStatus.failed => l10n.narrativeStatusFailed,
    NarrativeDocumentSessionStatus.conflicted => l10n.narrativeStatusConflicted,
    NarrativeDocumentSessionStatus.recovered => l10n.narrativeStatusRecovered,
  };
}

String _narrativeDestinationCommandLabel(
  NarrativeStudioDestination destination,
) =>
    switch (destination) {
      NarrativeStudioDestination.overview => 'Ouvrir l’aperçu narratif',
      NarrativeStudioDestination.storylines => 'Ouvrir les storylines',
      NarrativeStudioDestination.scenes => 'Ouvrir les scènes',
      NarrativeStudioDestination.events => 'Ouvrir les événements',
      NarrativeStudioDestination.cinematics => 'Ouvrir les cinématiques',
      NarrativeStudioDestination.dialogues => 'Ouvrir les dialogues',
      NarrativeStudioDestination.facts => 'Ouvrir les facts',
      NarrativeStudioDestination.shops => 'Ouvrir les boutiques',
      NarrativeStudioDestination.worldRules => 'Ouvrir les règles du monde',
      NarrativeStudioDestination.validator => 'Ouvrir le validateur',
    };

PokeMapBadgeVariant _narrativeDocumentStatusVariant(
  NarrativeDocumentSessionStatus status,
) {
  return switch (status) {
    NarrativeDocumentSessionStatus.saved => PokeMapBadgeVariant.success,
    NarrativeDocumentSessionStatus.dirty => PokeMapBadgeVariant.warning,
    NarrativeDocumentSessionStatus.saving => PokeMapBadgeVariant.info,
    NarrativeDocumentSessionStatus.failed => PokeMapBadgeVariant.error,
    NarrativeDocumentSessionStatus.conflicted => PokeMapBadgeVariant.error,
    NarrativeDocumentSessionStatus.recovered => PokeMapBadgeVariant.warning,
  };
}

void _showNarrativeDocumentComparison(
  BuildContext context,
  NarrativeDocumentComparison<ProjectManifest>? comparison,
) {
  if (comparison == null) return;
  final l10n = context.pokeMapL10n;
  unawaited(
    showPokeMapDesktopSideSheet<void>(
      context: context,
      title: l10n.narrativeCompareTitle,
      semanticLabel: l10n.narrativeCompareSemantics,
      width: 520,
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _NarrativeManifestComparisonCard(
              title: l10n.narrativeCompareBaseline,
              manifest: comparison.baseline,
            ),
            const SizedBox(height: 12),
            _NarrativeManifestComparisonCard(
              title: l10n.narrativeCompareLocal,
              manifest: comparison.local,
            ),
            const SizedBox(height: 12),
            _NarrativeManifestComparisonCard(
              title: l10n.narrativeCompareExternal,
              manifest: comparison.external,
            ),
          ],
        ),
      ),
    ),
  );
}

class _NarrativeManifestComparisonCard extends StatelessWidget {
  const _NarrativeManifestComparisonCard({
    required this.title,
    required this.manifest,
  });

  final String title;
  final ProjectManifest manifest;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapSectionHeader(
            title: title,
            description: context.pokeMapL10n.narrativeCinematicCount(
              manifest.cinematics.length,
            ),
          ),
          if (manifest.cinematics.isEmpty)
            Text(
              context.pokeMapL10n.narrativeNoCinematics,
              style: TextStyle(color: context.pokeMapColors.textMuted),
            )
          else
            for (final cinematic in manifest.cinematics)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${cinematic.title} · ${cinematic.id}',
                  style: TextStyle(
                    color: context.pokeMapColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _UndoIntent extends Intent {
  const _UndoIntent();
}

class _RedoIntent extends Intent {
  const _RedoIntent();
}

class _SaveIntent extends Intent {
  const _SaveIntent();
}

class _CollapsedExpandButton extends StatefulWidget {
  const _CollapsedExpandButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CollapsedExpandButton> createState() => _CollapsedExpandButtonState();
}

class _CollapsedExpandButtonState extends State<_CollapsedExpandButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Semantics(
      button: true,
      label: 'Rouvrir l’explorateur global',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _hovered
                    ? colors.brandPrimary.withValues(alpha: 0.8)
                    : colors.borderStrong.withValues(alpha: 0.6),
                width: 1.25,
              ),
              color: _hovered ? colors.surfaceHover : colors.surfaceBase,
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: colors.brandPrimary.withValues(alpha: 0.15),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: _hovered ? colors.brandPrimary : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

enum _BorderStudioExitChoice { save, discard, stay }
