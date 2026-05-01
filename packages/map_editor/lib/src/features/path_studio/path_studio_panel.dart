import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../editor/state/editor_notifier.dart';
import '../editor/state/editor_selectors.dart';
import 'path_pattern_draft.dart';
import 'path_pattern_diagnostics.dart';
import 'path_pattern_editor_read_model.dart';
import 'path_studio_edit_path_build_request.dart';
import 'path_studio_new_path_build_request.dart';
import 'path_studio_new_path_draft.dart';
import 'path_studio_save_flow.dart';
import 'path_studio_save_plan.dart';
import 'path_studio_theme.dart';
import 'path_studio_tileset_image_picker.dart';

part 'path_studio_saved_preset_detail.dart';
part 'path_studio_new_path_editor.dart';

/// Workspace branché au shell global de l'éditeur.
///
/// Ce wrapper Riverpod reste volontairement fin : il lit seulement le manifest
/// courant et délègue tout le rendu read-only à [PathStudioPanel]. Le lot 13 ne
/// crée ni repository, ni provider dédié, ni contrôleur de sauvegarde.
class PathStudioWorkspace extends ConsumerWidget {
  const PathStudioWorkspace({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manifest = ref.watch(editorProjectManifestProvider);
    final projectRootPath = ref.watch(editorProjectRootPathProvider);
    if (manifest == null) {
      return const _PathStudioProjectMissingState();
    }
    return PathStudioPanel(
      manifest: manifest,
      projectRootPath: projectRootPath,
      onPathPatternPresetSaveRequested: (preset) {
        final currentManifest = ref.read(editorProjectManifestProvider);
        if (currentManifest == null) return;
        final updatedManifest = applyLegacyPathPatternSaveToManifest(
          manifest: currentManifest,
          preset: preset,
        );
        ref
            .read(editorNotifierProvider.notifier)
            .applyInMemoryProjectManifest(updatedManifest);
      },
      onNewPathSaveRequested: (request) {
        final currentManifest = ref.read(editorProjectManifestProvider);
        if (currentManifest == null) return;
        final updatedManifest = applyNewPathBuildRequestToManifest(
          manifest: currentManifest,
          request: request,
        );
        ref
            .read(editorNotifierProvider.notifier)
            .applyInMemoryProjectManifest(updatedManifest);
      },
      onEditPathSaveRequested: (request) {
        final currentManifest = ref.read(editorProjectManifestProvider);
        if (currentManifest == null) return;
        final updatedManifest = applyPathPatternEditRequestToManifest(
          manifest: currentManifest,
          request: request,
        );
        ref
            .read(editorNotifierProvider.notifier)
            .applyInMemoryProjectManifest(updatedManifest);
      },
    );
  }
}

/// Shell visuel read-only du Path Studio.
///
/// Le widget reçoit un [ProjectManifest] explicite pour rester testable sans
/// dépendance à l'infrastructure éditeur. Toute l'information métier affichée
/// passe par le read model du lot 12 : aucune logique de diagnostic PathPattern
/// n'est recalculée ici.
class PathStudioPanel extends StatefulWidget {
  const PathStudioPanel({
    super.key,
    required this.manifest,
    this.projectRootPath,
    this.onPathPatternPresetSaveRequested,
    this.onNewPathSaveRequested,
    this.onEditPathSaveRequested,
  });

  final ProjectManifest manifest;
  final String? projectRootPath;
  final ValueChanged<ProjectPathPatternPreset>?
      onPathPatternPresetSaveRequested;
  final ValueChanged<PathStudioNewPathBuildRequest>? onNewPathSaveRequested;
  final ValueChanged<PathStudioEditPathBuildRequest>? onEditPathSaveRequested;

  @override
  State<PathStudioPanel> createState() => _PathStudioPanelState();
}

class _PathStudioPanelState extends State<PathStudioPanel> {
  String _searchQuery = '';
  PathStudioNewPathDraft? _newPathDraft;
  bool _newPathDraftSelected = false;
  PathPatternDraft? _draft;
  bool _draftSelected = false;
  String? _draftMessage;
  String? _saveFeedbackMessage;
  String? _saveErrorMessage;
  String? _pendingSavedPathPatternId;
  String? _pendingSavedSuccessMessage;
  String? _newPathCenterSeqFeedback;
  String? _draftCancelFeedbackMessage;
  bool _newPathCancelConfirmVisible = false;
  int? _selectionSourceIndexBeforeNewPathDraft;
  int? _editCancelRestoreSourceIndex;

  /// Index dans `readModel.presets`, pas id métier.
  ///
  /// Les ids dupliqués sont précisément un diagnostic V0 ; sélectionner par id
  /// rendrait une card ambiguë. L'index source garde donc une sélection stable
  /// même quand deux presets portent le même identifiant.
  int? _selectedSourceIndex;

  @override
  void didUpdateWidget(covariant PathStudioPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.manifest != widget.manifest) {
      final pendingSavedId = _pendingSavedPathPatternId;
      if (pendingSavedId != null) {
        final savedPresetIndex = _indexOfPathPatternPresetById(
          widget.manifest.pathPatternPresets,
          pendingSavedId,
        );
        if (savedPresetIndex != null) {
          _selectedSourceIndex = savedPresetIndex;
          _newPathDraft = null;
          _newPathDraftSelected = false;
          _draft = null;
          _draftSelected = false;
          _draftMessage = null;
          _saveFeedbackMessage = _pendingSavedSuccessMessage ??
              'Modification appliquée au projet en mémoire. Sauvegardez le projet avec la disquette pour l’écrire dans project.json.';
          _saveErrorMessage = null;
          _pendingSavedPathPatternId = null;
          _pendingSavedSuccessMessage = null;
          _newPathCenterSeqFeedback = null;
          _draftCancelFeedbackMessage = null;
          _newPathCancelConfirmVisible = false;
          _selectionSourceIndexBeforeNewPathDraft = null;
          _editCancelRestoreSourceIndex = null;
          return;
        }
      }
      _selectedSourceIndex = null;
      _newPathDraft = null;
      _newPathDraftSelected = false;
      _draft = null;
      _draftSelected = false;
      _draftMessage = null;
      _saveFeedbackMessage = null;
      _saveErrorMessage = null;
      _pendingSavedPathPatternId = null;
      _pendingSavedSuccessMessage = null;
      _newPathCenterSeqFeedback = null;
      _draftCancelFeedbackMessage = null;
      _newPathCancelConfirmVisible = false;
      _selectionSourceIndexBeforeNewPathDraft = null;
      _editCancelRestoreSourceIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final readModel = createPathPatternEditorReadModel(
      manifest: widget.manifest,
    );
    final query = _searchQuery.trim().toLowerCase();
    final filtered = _filteredCards(readModel, query);
    final selected = _newPathDraftSelected || _draftSelected
        ? null
        : _selectedCard(filtered);
    final selectedPreset = selected == null
        ? null
        : _pathPatternPresetBySourceIndex(selected.sourceIndex);
    final selectedNewPathDraft = _newPathDraftSelected ? _newPathDraft : null;
    final selectedDraft = _draftSelected ? _draft : null;
    final newPathSavePlan = selectedNewPathDraft == null
        ? null
        : createPathStudioNewPathBuildPlan(
            manifest: widget.manifest,
            draft: selectedNewPathDraft,
          );
    final editPathSavePlan =
        selectedNewPathDraft == null || !selectedNewPathDraft.isEditMode
            ? null
            : createPathStudioEditPathBuildPlan(
                manifest: widget.manifest,
                draft: selectedNewPathDraft,
              );
    final legacySavePlan = selectedDraft == null
        ? null
        : createPathStudioLegacyPathPatternSavePlan(
            manifest: widget.manifest,
            draft: selectedDraft,
          );
    final legacySaveCallback = widget.onPathPatternPresetSaveRequested;
    final newPathSaveCallback = widget.onNewPathSaveRequested;
    final editPathSaveCallback = widget.onEditPathSaveRequested;
    final onSavePressed = newPathSavePlan != null
        ? (selectedNewPathDraft?.isEditMode == true
            ? (editPathSavePlan?.canBuildRequest == true &&
                    editPathSaveCallback != null
                ? _requestEditPathSave
                : null)
            : (newPathSavePlan.canBuildRequest && newPathSaveCallback != null
                ? _requestNewPathSave
                : null))
        : (legacySavePlan?.canSaveNow == true && legacySaveCallback != null
            ? _requestLegacyPathPatternSave
            : null);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: PathStudioTheme.backgroundGradient,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PathStudioHeader(
              summary: readModel.summary,
              onCreateNewPathDraft: _createNewPathDraft,
              onCreateLegacyDraft: _createLegacyDraft,
              onSavePressed: onSavePressed,
              saveButtonLabel: _saveButtonLabel(
                newPathSavePlan: newPathSavePlan,
                editPathSavePlan: editPathSavePlan,
                legacySavePlan: legacySavePlan,
              ),
              saveHint: _saveButtonHint(
                newPathSavePlan: newPathSavePlan,
                editPathSavePlan: editPathSavePlan,
                legacySavePlan: legacySavePlan,
                hasNewPathSaveCallback: newPathSaveCallback != null,
                hasEditPathSaveCallback: editPathSaveCallback != null,
                hasLegacySaveCallback: legacySaveCallback != null,
              ),
              showNewPathDraftCancel: selectedNewPathDraft != null &&
                  _newPathDraftSelected,
              cancelDraftLabel: selectedNewPathDraft?.isEditMode == true
                  ? 'Annuler les modifications'
                  : 'Annuler la création',
              onCancelNewPathDraftPressed:
                  selectedNewPathDraft != null && _newPathDraftSelected
                      ? _requestCancelNewPathDraft
                      : null,
            ),
            if (_newPathCancelConfirmVisible &&
                selectedNewPathDraft != null) ...[
              const SizedBox(height: 10),
              _DraftCancelConfirmationBanner(
                isEditMode: selectedNewPathDraft.isEditMode,
                onContinueEditing: _dismissNewPathDraftCancelConfirmation,
                onConfirmDiscard: _confirmCancelNewPathDraft,
              ),
            ],
            if (_draftCancelFeedbackMessage != null) ...[
              const SizedBox(height: 10),
              _DraftCancelFeedbackBanner(message: _draftCancelFeedbackMessage!),
            ],
            if (_saveFeedbackMessage != null) ...[
              const SizedBox(height: 10),
              _SaveFeedbackBanner(message: _saveFeedbackMessage!),
            ],
            if (_saveErrorMessage != null) ...[
              const SizedBox(height: 10),
              _SaveErrorBanner(message: _saveErrorMessage!),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 292,
                    child: _PresetSidebar(
                      readModel: readModel,
                      filteredCards: filtered,
                      newPathDraft: _newPathDraft,
                      newPathDraftSelected: _newPathDraftSelected,
                      newPathDraftMatchesQuery: _newPathDraft == null ||
                          query.isEmpty ||
                          _matchesNewPathDraftQuery(_newPathDraft!, query),
                      draft: _draft,
                      draftSelected: _draftSelected,
                      draftMatchesQuery: _draft == null ||
                          query.isEmpty ||
                          _matchesDraftQuery(_draft!, query),
                      draftMessage: _draftMessage,
                      selectedSourceIndex: selected?.sourceIndex,
                      onQueryChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                      onSelectNewPathDraft: () {
                        setState(() {
                          _newPathDraftSelected = true;
                          _draftSelected = false;
                        });
                      },
                      onSelectDraft: () {
                        setState(() {
                          _newPathDraftSelected = false;
                          _draftSelected = true;
                        });
                      },
                      onSelect: (sourceIndex) {
                        setState(() {
                          _newPathDraftSelected = false;
                          _draftSelected = false;
                          _selectedSourceIndex = sourceIndex;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _CenterWorkspace(
                      manifest: widget.manifest,
                      tilesets: widget.manifest.tilesets,
                      settings: widget.manifest.settings,
                      projectRootPath: widget.projectRootPath,
                      newPathDraft: selectedNewPathDraft,
                      newPathSavePlan: newPathSavePlan,
                      editPathSavePlan: editPathSavePlan,
                      draft: selectedDraft,
                      legacySavePlan: legacySavePlan,
                      hasSaveCallback: legacySaveCallback != null,
                      hasNewPathSaveCallback: newPathSaveCallback != null,
                      saveFeedbackMessage: _saveFeedbackMessage,
                      selected: selected?.card,
                      selectedPreset: selectedPreset,
                      hasAnyPreset: readModel.presets.isNotEmpty,
                      onSavedPresetEditRequested: _openSavedPathPatternForEdit,
                      onNewPathSizeChanged: _resizeNewPathDraft,
                      onNewPathSurfaceKindChanged:
                          _selectNewPathDraftSurfaceKind,
                      onNewPathCellSelected: _selectNewPathDraftCell,
                      onNewPathVariantSelected: _selectNewPathDraftVariant,
                      onNewPathTileSelected: _assignNewPathDraftTile,
                      onNewPathCenterFrameSelected:
                          _selectNewPathDraftCenterFrame,
                      onNewPathCenterFrameAdded: _appendNewPathDraftCenterFrame,
                      onNewPathCenterFrameRemoved:
                          _removeNewPathDraftCenterFrame,
                      onNewPathCenterFrameDurationChanged:
                          _updateNewPathDraftCenterFrameDuration,
                      onNewPathCellCleared: _clearNewPathDraftCell,
                      onNewPathVariantCleared: _clearNewPathDraftVariant,
                      newPathCenterSeqFeedback: _newPathCenterSeqFeedback,
                      onNewPathCenterAnimationSequenceRequested:
                          _generateNewPathDraftCenterAnimationSequence,
                      onDraftSizeChanged: _resizeDraft,
                      onDraftCellSelected: _selectDraftCell,
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 326,
                    child: _PresetInspector(
                      manifest: widget.manifest,
                      newPathDraft: selectedNewPathDraft,
                      draft: selectedDraft,
                      selected: selected?.card,
                      selectedPreset: selectedPreset,
                      onNewPathNameChanged: _renameNewPathDraft,
                      onNewPathTilesetChanged: _selectNewPathDraftTileset,
                      onNewPathSurfaceKindChanged:
                          _selectNewPathDraftSurfaceKind,
                      onNewPathSizeChanged: _resizeNewPathDraft,
                      onDraftNameChanged: _renameDraft,
                      onDraftBaseChanged: _changeDraftBase,
                      onDraftSizeChanged: _resizeDraft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_IndexedPresetCard> _filteredCards(
    PathPatternEditorReadModel readModel,
    String query,
  ) {
    final indexed = <_IndexedPresetCard>[];
    for (var index = 0; index < readModel.presets.length; index += 1) {
      final card = readModel.presets[index];
      if (query.isEmpty || _matchesQuery(card, query)) {
        indexed.add(_IndexedPresetCard(index, card));
      }
    }
    return indexed;
  }

  bool _matchesQuery(PathPatternPresetCardModel card, String query) {
    final fields = [
      card.name,
      card.id,
      card.basePathPresetId,
      card.basePathPresetName,
      card.basePathSurfaceKindLabel,
      card.centerPatternLabel,
    ];
    return fields
        .whereType<String>()
        .any((field) => field.toLowerCase().contains(query));
  }

  bool _matchesDraftQuery(PathPatternDraft draft, String query) {
    final fields = [
      draft.name,
      draft.id,
      draft.basePathPresetId,
      draft.centerPatternLabel,
    ];
    return fields.any((field) => field.toLowerCase().contains(query));
  }

  bool _matchesNewPathDraftQuery(
    PathStudioNewPathDraft draft,
    String query,
  ) {
    final fields = [
      draft.name,
      draft.id,
      draft.centerPatternLabel,
      'nouveau chemin',
    ];
    return fields.any((field) => field.toLowerCase().contains(query));
  }

  _IndexedPresetCard? _selectedCard(List<_IndexedPresetCard> filtered) {
    if (filtered.isEmpty) {
      return null;
    }
    for (final entry in filtered) {
      if (entry.sourceIndex == _selectedSourceIndex) {
        return entry;
      }
    }
    return filtered.first;
  }

  /// Efface le bandeau « annulation » et la confirmation sans toucher au manifest.
  void _clearNewPathDraftTransientChrome() {
    _newPathCancelConfirmVisible = false;
    _draftCancelFeedbackMessage = null;
  }

  int? _findSourceIndexForPathPatternId(String pathPatternId) {
    final readModel =
        createPathPatternEditorReadModel(manifest: widget.manifest);
    for (var i = 0; i < readModel.presets.length; i++) {
      if (readModel.presets[i].id == pathPatternId) {
        return i;
      }
    }
    return null;
  }

  void _requestCancelNewPathDraft() {
    final draft = _newPathDraft;
    if (draft == null || !_newPathDraftSelected) {
      return;
    }
    if (!draft.isDirty) {
      _discardCurrentNewPathDraft();
      return;
    }
    setState(() {
      _newPathCancelConfirmVisible = true;
      _draftCancelFeedbackMessage = null;
    });
  }

  void _dismissNewPathDraftCancelConfirmation() {
    setState(() => _newPathCancelConfirmVisible = false);
  }

  void _confirmCancelNewPathDraft() {
    _discardCurrentNewPathDraft();
  }

  void _discardCurrentNewPathDraft() {
    final draft = _newPathDraft;
    if (draft == null) {
      return;
    }
    final wasEditMode = draft.isEditMode;
    setState(() {
      _newPathDraft = null;
      _newPathDraftSelected = false;
      _newPathCancelConfirmVisible = false;
      _newPathCenterSeqFeedback = null;
      _saveFeedbackMessage = null;
      if (wasEditMode) {
        _selectedSourceIndex = _editCancelRestoreSourceIndex;
        _editCancelRestoreSourceIndex = null;
        _selectionSourceIndexBeforeNewPathDraft = null;
        _draftCancelFeedbackMessage = 'Modifications annulées.';
      } else {
        _selectedSourceIndex = _selectionSourceIndexBeforeNewPathDraft;
        _selectionSourceIndexBeforeNewPathDraft = null;
        _editCancelRestoreSourceIndex = null;
        _draftCancelFeedbackMessage = 'Brouillon annulé.';
      }
    });
  }

  void _createNewPathDraft() {
    setState(() {
      if (!_newPathDraftSelected) {
        _selectionSourceIndexBeforeNewPathDraft = _selectedSourceIndex;
      }
      _newPathDraft = createInitialPathStudioNewPathDraft();
      _newPathDraftSelected = true;
      _draftSelected = false;
      _draftMessage = null;
      _clearNewPathDraftTransientChrome();
      _saveFeedbackMessage = null;
      _newPathCenterSeqFeedback = null;
      _pendingSavedPathPatternId = null;
    });
  }

  void _openSavedPathPatternForEdit(ProjectPathPatternPreset preset) {
    final resolution = _resolveEditAvailabilityForSelection(preset);
    if (!resolution.canEdit || resolution.basePathPreset == null) {
      return;
    }
    setState(() {
      _clearNewPathDraftTransientChrome();
      _editCancelRestoreSourceIndex =
          _findSourceIndexForPathPatternId(preset.id);
      _newPathDraft = createPathStudioEditDraftFromExistingPathPattern(
        pathPatternPreset: preset,
        basePathPreset: resolution.basePathPreset!,
      );
      _newPathDraftSelected = true;
      _draftSelected = false;
      _draftMessage = null;
      _saveFeedbackMessage = null;
      _saveErrorMessage = null;
      _pendingSavedPathPatternId = null;
      _pendingSavedSuccessMessage = null;
      _newPathCenterSeqFeedback = null;
    });
  }

  void _createLegacyDraft() {
    if (widget.manifest.pathPresets.isEmpty) {
      setState(() {
        _draftMessage = 'Aucun path existant disponible';
        _saveFeedbackMessage = null;
        _pendingSavedPathPatternId = null;
        _newPathDraftSelected = false;
        _draftSelected = false;
      });
      return;
    }
    try {
      final draft = createInitialPathPatternDraftFromManifest(
        manifest: widget.manifest,
      );
      setState(() {
        _draft = draft;
        _newPathDraftSelected = false;
        _draftSelected = draft != null;
        _draftMessage = draft == null
            ? 'Aucun path existant disponible'
            : 'Brouillon non sauvegardé';
        _saveFeedbackMessage = null;
        _pendingSavedPathPatternId = null;
      });
    } on ArgumentError {
      setState(() {
        _draftMessage =
            'Le preset Path de base ne contient pas de centre cross';
        _saveFeedbackMessage = null;
        _pendingSavedPathPatternId = null;
        _newPathDraftSelected = false;
        _draftSelected = false;
      });
    }
  }

  void _renameNewPathDraft(String name) {
    final draft = _newPathDraft;
    if (draft == null) {
      return;
    }
    setState(() {
      _newPathDraft = renamePathStudioNewPathDraft(draft, name);
      _clearNewPathDraftTransientChrome();
      _saveFeedbackMessage = null;
      _newPathCenterSeqFeedback = null;
    });
  }

  void _resizeNewPathDraft(int width, int height) {
    final draft = _newPathDraft;
    if (draft == null) {
      return;
    }
    setState(() {
      _newPathDraft = resizePathStudioNewPathDraftCenter(
        draft: draft,
        width: width,
        height: height,
      );
      _clearNewPathDraftTransientChrome();
      _saveFeedbackMessage = null;
      _newPathCenterSeqFeedback = null;
    });
  }

  void _selectNewPathDraftTileset(String tilesetId) {
    final draft = _newPathDraft;
    if (draft == null) {
      return;
    }
    setState(() {
      _newPathDraft = selectPathStudioNewPathDraftTileset(draft, tilesetId);
      _clearNewPathDraftTransientChrome();
      _saveFeedbackMessage = null;
      _newPathCenterSeqFeedback = null;
    });
  }

  void _selectNewPathDraftSurfaceKind(PathSurfaceKind surfaceKind) {
    final draft = _newPathDraft;
    if (draft == null) {
      return;
    }
    setState(() {
      _newPathDraft = selectPathStudioNewPathDraftSurfaceKind(
        draft: draft,
        surfaceKind: surfaceKind,
      );
      _clearNewPathDraftTransientChrome();
      _saveFeedbackMessage = null;
      _newPathCenterSeqFeedback = null;
    });
  }

  void _selectNewPathDraftCell(int localX, int localY) {
    final draft = _newPathDraft;
    if (draft == null) {
      return;
    }
    setState(() {
      _newPathDraft = selectPathStudioNewPathDraftCell(
        draft: draft,
        localX: localX,
        localY: localY,
      );
      _clearNewPathDraftTransientChrome();
      _saveFeedbackMessage = null;
      _newPathCenterSeqFeedback = null;
    });
  }

  void _assignNewPathDraftTile(int sourceX, int sourceY) {
    final draft = _newPathDraft;
    if (draft == null) {
      return;
    }
    setState(() {
      _newPathDraft = draft.selectedTarget ==
              PathStudioNewPathDraftSelectionTarget.centerCell
          ? assignPathStudioNewPathDraftCellTile(
              draft: draft,
              localX: draft.selectedCellX,
              localY: draft.selectedCellY,
              sourceX: sourceX,
              sourceY: sourceY,
            )
          : assignPathStudioNewPathDraftVariantTile(
              draft: draft,
              variant: draft.selectedVariant,
              sourceX: sourceX,
              sourceY: sourceY,
            );
      _clearNewPathDraftTransientChrome();
      _saveFeedbackMessage = null;
      _newPathCenterSeqFeedback = null;
    });
  }

  void _selectNewPathDraftCenterFrame(int frameIndex) {
    final draft = _newPathDraft;
    if (draft == null) {
      return;
    }
    setState(() {
      _newPathDraft = selectPathStudioNewPathDraftCenterFrame(
        draft: draft,
        localX: draft.selectedCellX,
        localY: draft.selectedCellY,
        frameIndex: frameIndex,
      );
      _clearNewPathDraftTransientChrome();
      _saveFeedbackMessage = null;
      _newPathCenterSeqFeedback = null;
    });
  }

  void _appendNewPathDraftCenterFrame() {
    final draft = _newPathDraft;
    if (draft == null) {
      return;
    }
    setState(() {
      _newPathDraft = appendPathStudioNewPathDraftCenterFrame(
        draft: draft,
        localX: draft.selectedCellX,
        localY: draft.selectedCellY,
      );
      _clearNewPathDraftTransientChrome();
      _saveFeedbackMessage = null;
      _newPathCenterSeqFeedback = null;
    });
  }

  void _removeNewPathDraftCenterFrame(int frameIndex) {
    final draft = _newPathDraft;
    if (draft == null) {
      return;
    }
    setState(() {
      _newPathDraft = removePathStudioNewPathDraftCenterFrame(
        draft: draft,
        localX: draft.selectedCellX,
        localY: draft.selectedCellY,
        frameIndex: frameIndex,
      );
      _clearNewPathDraftTransientChrome();
      _saveFeedbackMessage = null;
      _newPathCenterSeqFeedback = null;
    });
  }

  void _updateNewPathDraftCenterFrameDuration(int frameIndex, int durationMs) {
    final draft = _newPathDraft;
    if (draft == null) {
      return;
    }
    setState(() {
      _newPathDraft = updatePathStudioNewPathDraftCenterFrameDuration(
        draft: draft,
        localX: draft.selectedCellX,
        localY: draft.selectedCellY,
        frameIndex: frameIndex,
        durationMs: durationMs,
      );
      _clearNewPathDraftTransientChrome();
      _saveFeedbackMessage = null;
      _newPathCenterSeqFeedback = null;
    });
  }

  void _clearNewPathDraftCell(int localX, int localY) {
    final draft = _newPathDraft;
    if (draft == null) {
      return;
    }
    setState(() {
      _newPathDraft = clearPathStudioNewPathDraftCell(
        draft: draft,
        localX: localX,
        localY: localY,
      );
      _clearNewPathDraftTransientChrome();
      _saveFeedbackMessage = null;
      _newPathCenterSeqFeedback = null;
    });
  }

  void _selectNewPathDraftVariant(TerrainPathVariant variant) {
    final draft = _newPathDraft;
    if (draft == null) {
      return;
    }
    setState(() {
      _newPathDraft = selectPathStudioNewPathDraftVariant(
        draft: draft,
        variant: variant,
      );
      _clearNewPathDraftTransientChrome();
      _saveFeedbackMessage = null;
      _newPathCenterSeqFeedback = null;
    });
  }

  void _clearNewPathDraftVariant(TerrainPathVariant variant) {
    final draft = _newPathDraft;
    if (draft == null) {
      return;
    }
    setState(() {
      _newPathDraft = clearPathStudioNewPathDraftVariant(
        draft: draft,
        variant: variant,
      );
      _clearNewPathDraftTransientChrome();
      _saveFeedbackMessage = null;
      _newPathCenterSeqFeedback = null;
    });
  }

  void _generateNewPathDraftCenterAnimationSequence(
    PathStudioCenterAnimationSequenceTarget target,
    int frameCount,
    int stepX,
    int stepY,
    int durationMs,
  ) {
    final draft = _newPathDraft;
    if (draft == null) {
      return;
    }
    final result = generatePathStudioCenterAnimationSequence(
      draft: draft,
      target: target,
      frameCount: frameCount,
      stepX: stepX,
      stepY: stepY,
      durationMs: durationMs,
    );
    setState(() {
      _clearNewPathDraftTransientChrome();
      switch (result) {
        case PathStudioCenterAnimationSequenceSuccess(:final draft, :final message):
          _newPathDraft = draft;
          _newPathCenterSeqFeedback = message;
        case PathStudioCenterAnimationSequenceFailure(:final message):
          _newPathCenterSeqFeedback = message;
      }
      _saveFeedbackMessage = null;
    });
  }

  void _renameDraft(String name) {
    final draft = _draft;
    if (draft == null) {
      return;
    }
    setState(() {
      _draft = renamePathPatternDraft(draft, name);
      _saveFeedbackMessage = null;
    });
  }

  void _resizeDraft(int width, int height) {
    final draft = _draft;
    final base = _basePathPresetForDraft(draft);
    if (draft == null || base == null) {
      return;
    }
    setState(() {
      _draft = resizePathPatternDraftCenter(
        draft: draft,
        basePathPreset: base,
        width: width,
        height: height,
      );
      _saveFeedbackMessage = null;
    });
  }

  void _changeDraftBase(String basePathPresetId) {
    final draft = _draft;
    if (draft == null) {
      return;
    }
    final base = _basePathPresetById(basePathPresetId);
    if (base == null) {
      return;
    }
    setState(() {
      _draft = changePathPatternDraftBase(
        draft: draft,
        basePathPreset: base,
      );
      _saveFeedbackMessage = null;
    });
  }

  void _selectDraftCell(int localX, int localY) {
    final draft = _draft;
    if (draft == null) {
      return;
    }
    setState(() {
      _draft = selectPathPatternDraftCell(
        draft: draft,
        localX: localX,
        localY: localY,
      );
      _saveFeedbackMessage = null;
    });
  }

  void _requestLegacyPathPatternSave() {
    final draft = _draft;
    final callback = widget.onPathPatternPresetSaveRequested;
    if (draft == null || !_draftSelected || callback == null) {
      return;
    }
    final plan = createPathStudioLegacyPathPatternSavePlan(
      manifest: widget.manifest,
      draft: draft,
    );
    final request = plan.request;
    if (request == null) {
      return;
    }
    setState(() {
      _pendingSavedPathPatternId = request.preset.id;
      _pendingSavedSuccessMessage =
          'Modification appliquée au projet en mémoire. Sauvegardez le projet avec la disquette pour l’écrire dans project.json.';
      _saveFeedbackMessage = null;
      _saveErrorMessage = null;
    });
    try {
      callback(request.preset);
    } catch (_) {
      setState(() {
        _pendingSavedPathPatternId = null;
        _pendingSavedSuccessMessage = null;
        _saveFeedbackMessage = null;
        _saveErrorMessage = 'La sauvegarde a échoué';
      });
    }
  }

  void _requestNewPathSave() {
    final draft = _newPathDraft;
    final callback = widget.onNewPathSaveRequested;
    if (draft == null || !_newPathDraftSelected || callback == null) {
      return;
    }
    final plan = createPathStudioNewPathBuildPlan(
      manifest: widget.manifest,
      draft: draft,
    );
    final request = plan.buildRequest;
    if (!plan.canBuildRequest || request == null) {
      return;
    }
    setState(() {
      _pendingSavedPathPatternId = request.pathPatternPreset.id;
      _pendingSavedSuccessMessage =
          'Chemin ajouté au projet en mémoire. Sauvegardez le projet avec la disquette pour l’écrire dans project.json.';
      _saveFeedbackMessage = null;
      _saveErrorMessage = null;
    });
    try {
      callback(request);
    } catch (_) {
      setState(() {
        _pendingSavedPathPatternId = null;
        _pendingSavedSuccessMessage = null;
        _saveFeedbackMessage = null;
        _saveErrorMessage = 'La création du nouveau chemin a échoué';
      });
    }
  }

  void _requestEditPathSave() {
    final draft = _newPathDraft;
    final callback = widget.onEditPathSaveRequested;
    if (draft == null ||
        !_newPathDraftSelected ||
        !draft.isEditMode ||
        callback == null) {
      return;
    }
    final plan = createPathStudioEditPathBuildPlan(
      manifest: widget.manifest,
      draft: draft,
    );
    final request = plan.buildRequest;
    if (!plan.canBuildRequest || request == null) {
      return;
    }
    setState(() {
      _pendingSavedPathPatternId = request.updatedPathPatternPreset.id;
      _pendingSavedSuccessMessage =
          'Chemin modifié en mémoire. Sauvegardez le projet avec la disquette pour l’écrire dans project.json.';
      _saveFeedbackMessage = null;
      _saveErrorMessage = null;
    });
    try {
      callback(request);
    } catch (_) {
      setState(() {
        _pendingSavedPathPatternId = null;
        _pendingSavedSuccessMessage = null;
        _saveFeedbackMessage = null;
        _saveErrorMessage = 'La modification du chemin a échoué';
      });
    }
  }

  String _saveButtonLabel({
    required PathStudioNewPathBuildPlan? newPathSavePlan,
    required PathStudioEditPathBuildPlan? editPathSavePlan,
    required PathStudioLegacyPathPatternSavePlan? legacySavePlan,
  }) {
    if (newPathSavePlan != null) {
      return editPathSavePlan != null
          ? 'Appliquer les modifications'
          : 'Appliquer au projet';
    }
    if (legacySavePlan != null) {
      return 'Appliquer au projet';
    }
    return 'Appliquer au projet';
  }

  String _saveButtonHint({
    required PathStudioNewPathBuildPlan? newPathSavePlan,
    required PathStudioEditPathBuildPlan? editPathSavePlan,
    required PathStudioLegacyPathPatternSavePlan? legacySavePlan,
    required bool hasNewPathSaveCallback,
    required bool hasEditPathSaveCallback,
    required bool hasLegacySaveCallback,
  }) {
    if (newPathSavePlan != null) {
      if (editPathSavePlan != null) {
        if (!editPathSavePlan.canBuildRequest) {
          return 'non sauvegardable';
        }
        return hasEditPathSaveCallback
            ? 'application en mémoire prête'
            : 'callback absent';
      }
      if (!newPathSavePlan.canBuildRequest) {
        return 'non sauvegardable';
      }
      return hasNewPathSaveCallback
          ? 'application en mémoire prête'
          : 'callback absent';
    }
    if (legacySavePlan != null) {
      if (!legacySavePlan.canSaveNow) {
        return 'à corriger';
      }
      return hasLegacySaveCallback ? 'préparer' : 'callback absent';
    }
    return 'aucun brouillon';
  }

  _EditAvailability _resolveEditAvailabilityForSelection(
    ProjectPathPatternPreset preset,
  ) {
    return _resolveEditAvailability(manifest: widget.manifest, preset: preset);
  }

  ProjectPathPreset? _basePathPresetForDraft(PathPatternDraft? draft) {
    if (draft == null) {
      return null;
    }
    return _basePathPresetById(draft.basePathPresetId);
  }

  ProjectPathPreset? _basePathPresetById(String id) {
    for (final preset in widget.manifest.pathPresets) {
      if (preset.id == id) {
        return preset;
      }
    }
    return null;
  }

  int? _indexOfPathPatternPresetById(
    List<ProjectPathPatternPreset> presets,
    String id,
  ) {
    for (var index = 0; index < presets.length; index += 1) {
      if (presets[index].id == id) {
        return index;
      }
    }
    return null;
  }

  ProjectPathPatternPreset? _pathPatternPresetBySourceIndex(int sourceIndex) {
    if (sourceIndex < 0 ||
        sourceIndex >= widget.manifest.pathPatternPresets.length) {
      return null;
    }
    return widget.manifest.pathPatternPresets[sourceIndex];
  }
}

class _DraftCancelFeedbackBanner extends StatelessWidget {
  const _DraftCancelFeedbackBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('path-studio-draft-cancel-feedback'),
      decoration: PathStudioTheme.panelDecoration(
        color: PathStudioTheme.warning.withValues(alpha: 0.14),
        radius: 14,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const MacosIcon(
            CupertinoIcons.info,
            size: 16,
            color: PathStudioTheme.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Confirmation Lot PathPattern-40 : abandon du brouillon avec perte des edits locaux.
class _DraftCancelConfirmationBanner extends StatelessWidget {
  const _DraftCancelConfirmationBanner({
    required this.isEditMode,
    required this.onContinueEditing,
    required this.onConfirmDiscard,
  });

  final bool isEditMode;
  final VoidCallback onContinueEditing;
  final VoidCallback onConfirmDiscard;

  @override
  Widget build(BuildContext context) {
    final secondary = isEditMode
        ? 'Annuler ces modifications restaurera le chemin sauvegardé.'
        : 'Annuler ce brouillon supprimera le nouveau chemin non appliqué.';
    return Container(
      key: const Key('path-studio-cancel-draft-confirmation'),
      decoration: PathStudioTheme.panelDecoration(
        color: PathStudioTheme.warning.withValues(alpha: 0.12),
        radius: 14,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Des modifications non appliquées seront perdues.',
            style: TextStyle(
              color: PathStudioTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            secondary,
            style: const TextStyle(
              color: PathStudioTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                onPressed: onContinueEditing,
                color: PathStudioTheme.surfaceStrong,
                borderRadius: BorderRadius.circular(12),
                child: const Text(
                  'Continuer l’édition',
                  style: TextStyle(
                    color: PathStudioTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              CupertinoButton(
                key: const Key('path-studio-cancel-draft-confirm-button'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                onPressed: onConfirmDiscard,
                color: PathStudioTheme.warning.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(12),
                child: Text(
                  isEditMode
                      ? 'Annuler les modifications'
                      : 'Annuler la création',
                  style: const TextStyle(
                    color: Color(0xFF1A1528),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SaveFeedbackBanner extends StatelessWidget {
  const _SaveFeedbackBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('path-studio-save-success-message'),
      decoration: PathStudioTheme.panelDecoration(
        color: PathStudioTheme.success.withValues(alpha: 0.14),
        radius: 14,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const MacosIcon(
            CupertinoIcons.check_mark_circled_solid,
            size: 16,
            color: PathStudioTheme.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveErrorBanner extends StatelessWidget {
  const _SaveErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('path-studio-save-error-message'),
      decoration: PathStudioTheme.panelDecoration(
        color: PathStudioTheme.error.withValues(alpha: 0.14),
        radius: 14,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const MacosIcon(
            CupertinoIcons.exclamationmark_triangle_fill,
            size: 16,
            color: PathStudioTheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IndexedPresetCard {
  const _IndexedPresetCard(this.sourceIndex, this.card);

  final int sourceIndex;
  final PathPatternPresetCardModel card;
}

final class _EditAvailability {
  const _EditAvailability({
    required this.canEdit,
    this.reason,
    this.basePathPreset,
  });

  final bool canEdit;
  final String? reason;
  final ProjectPathPreset? basePathPreset;
}

_EditAvailability _resolveEditAvailability({
  required ProjectManifest manifest,
  required ProjectPathPatternPreset preset,
}) {
  final presetMatches = manifest.pathPatternPresets
      .where((candidate) => candidate.id == preset.id)
      .toList(growable: false);
  if (presetMatches.length != 1) {
    return const _EditAvailability(
      canEdit: false,
      reason: 'PathPattern introuvable',
    );
  }
  final baseMatches = manifest.pathPresets
      .where((candidate) => candidate.id == preset.basePathPresetId)
      .toList(growable: false);
  if (baseMatches.isEmpty) {
    return const _EditAvailability(
      canEdit: false,
      reason: 'Base path introuvable',
    );
  }
  if (baseMatches.length > 1) {
    return const _EditAvailability(
      canEdit: false,
      reason: 'Base path ambiguë',
    );
  }
  return _EditAvailability(canEdit: true, basePathPreset: baseMatches.single);
}

class _PathStudioProjectMissingState extends StatelessWidget {
  const _PathStudioProjectMissingState();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: PathStudioTheme.background,
      child: Center(
        child: Text(
          'Charger un projet pour ouvrir Path Studio.',
          style: TextStyle(
            color: PathStudioTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PathStudioHeader extends StatelessWidget {
  const _PathStudioHeader({
    required this.summary,
    required this.onCreateNewPathDraft,
    required this.onCreateLegacyDraft,
    required this.onSavePressed,
    required this.saveButtonLabel,
    required this.saveHint,
    required this.showNewPathDraftCancel,
    required this.cancelDraftLabel,
    this.onCancelNewPathDraftPressed,
  });

  final PathPatternEditorSummary summary;
  final VoidCallback onCreateNewPathDraft;
  final VoidCallback onCreateLegacyDraft;
  final VoidCallback? onSavePressed;
  final String saveButtonLabel;
  final String saveHint;
  final bool showNewPathDraftCancel;
  final String cancelDraftLabel;
  final VoidCallback? onCancelNewPathDraftPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PathStudioTheme.panelDecoration(
        color: PathStudioTheme.surface,
        radius: 24,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  PathStudioTheme.accentHover,
                  PathStudioTheme.accent,
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: PathStudioTheme.accentHover.withValues(alpha: 0.8),
              ),
            ),
            child: const MacosIcon(
              CupertinoIcons.arrow_branch,
              color: CupertinoColors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Path Studio',
                  style: TextStyle(
                    color: PathStudioTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Créer des motifs de chemin',
                  style: TextStyle(
                    color: PathStudioTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            flex: 2,
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _SummaryPill(label: 'Presets', value: '${summary.totalCount}'),
                _SummaryPill(label: 'Prêts', value: '${summary.readyCount}'),
                _ShellActionButton(
                  icon: CupertinoIcons.plus,
                  label: 'Nouveau chemin',
                  hint: 'nouveau brouillon',
                  onPressed: onCreateNewPathDraft,
                ),
                _ShellActionButton(
                  icon: CupertinoIcons.arrow_down_doc,
                  label: 'Depuis un path existant',
                  hint: 'flux avancé',
                  onPressed: onCreateLegacyDraft,
                ),
                const _ShellActionButton(
                  icon: CupertinoIcons.square_on_square,
                  label: 'Dupliquer',
                  hint: 'lot futur',
                ),
                if (showNewPathDraftCancel &&
                    onCancelNewPathDraftPressed != null)
                  _ShellActionButton(
                    icon: CupertinoIcons.xmark_circle_fill,
                    label: cancelDraftLabel,
                    hint: 'sans appliquer au projet',
                    buttonKey: const Key('path-studio-cancel-draft-button'),
                    onPressed: onCancelNewPathDraftPressed,
                    backgroundColor: PathStudioTheme.surfaceStrong,
                    foregroundColor: PathStudioTheme.warning,
                  ),
                _ShellActionButton(
                  icon: CupertinoIcons.floppy_disk,
                  label: saveButtonLabel,
                  hint: saveHint,
                  buttonKey: const Key('path-studio-save-button'),
                  onPressed: onSavePressed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: PathStudioTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: PathStudioTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: PathStudioTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: PathStudioTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShellActionButton extends StatelessWidget {
  const _ShellActionButton({
    required this.icon,
    required this.label,
    this.hint = 'lot futur',
    this.buttonKey,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final String hint;
  final Key? buttonKey;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? PathStudioTheme.accent;
    final fg = foregroundColor;
    final titleColor = onPressed == null
        ? PathStudioTheme.textSecondary.withValues(alpha: 0.7)
        : (fg ?? CupertinoColors.white);
    final subtitleColor = onPressed == null
        ? PathStudioTheme.textMuted
        : (fg?.withValues(alpha: 0.85) ??
            CupertinoColors.white.withValues(alpha: 0.72));
    final iconColor = onPressed == null
        ? PathStudioTheme.textMuted.withValues(alpha: 0.72)
        : (fg ?? CupertinoColors.white);

    return CupertinoButton(
      key: buttonKey,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      minimumSize: Size.zero,
      onPressed: onPressed,
      disabledColor: PathStudioTheme.surfaceRaised.withValues(alpha: 0.72),
      color: bg,
      borderRadius: BorderRadius.circular(13),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MacosIcon(
            icon,
            color: iconColor,
            size: 15,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                hint,
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PresetSidebar extends StatelessWidget {
  const _PresetSidebar({
    required this.readModel,
    required this.filteredCards,
    required this.newPathDraft,
    required this.newPathDraftSelected,
    required this.newPathDraftMatchesQuery,
    required this.draft,
    required this.draftSelected,
    required this.draftMatchesQuery,
    required this.draftMessage,
    required this.selectedSourceIndex,
    required this.onQueryChanged,
    required this.onSelectNewPathDraft,
    required this.onSelectDraft,
    required this.onSelect,
  });

  final PathPatternEditorReadModel readModel;
  final List<_IndexedPresetCard> filteredCards;
  final PathStudioNewPathDraft? newPathDraft;
  final bool newPathDraftSelected;
  final bool newPathDraftMatchesQuery;
  final PathPatternDraft? draft;
  final bool draftSelected;
  final bool draftMatchesQuery;
  final String? draftMessage;
  final int? selectedSourceIndex;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onSelectNewPathDraft;
  final VoidCallback onSelectDraft;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PathStudioTheme.panelDecoration(),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Presets',
                  style: TextStyle(
                    color: PathStudioTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _SidebarCounter(value: readModel.summary.totalCount),
            ],
          ),
          const SizedBox(height: 12),
          CupertinoTextField(
            key: const Key('path-studio-search-field'),
            onChanged: onQueryChanged,
            placeholder: 'Rechercher un preset...',
            prefix: const Padding(
              padding: EdgeInsets.only(left: 10),
              child: MacosIcon(
                CupertinoIcons.search,
                size: 15,
                color: PathStudioTheme.textMuted,
              ),
            ),
            style: const TextStyle(
              color: PathStudioTheme.textPrimary,
              fontSize: 13,
            ),
            placeholderStyle: const TextStyle(
              color: PathStudioTheme.textMuted,
              fontSize: 13,
            ),
            decoration: BoxDecoration(
              color: PathStudioTheme.surfaceStrong,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: PathStudioTheme.border),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildPresetList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetList() {
    final newPathDraftCard = newPathDraft;
    final draftCard = draft;
    if (readModel.presets.isEmpty &&
        newPathDraftCard == null &&
        draftCard == null) {
      return _SidebarNotice(
        title: 'Aucun motif PathPattern',
        message: draftMessage ??
            'Cliquez sur Nouveau chemin pour créer un brouillon local.',
      );
    }
    final newPathVisible = newPathDraftCard != null && newPathDraftMatchesQuery;
    final legacyDraftVisible = draftCard != null && draftMatchesQuery;
    if (filteredCards.isEmpty && !newPathVisible && !legacyDraftVisible) {
      return const _SidebarNotice(
        title: 'Aucun preset trouvé',
        message: 'Essayez un autre nom, id ou preset de base.',
      );
    }
    final draftCount = (newPathVisible ? 1 : 0) + (legacyDraftVisible ? 1 : 0);
    return ListView.separated(
      itemCount: filteredCards.length + draftCount,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (newPathDraftCard != null && newPathVisible && index == 0) {
          return _NewPathDraftListCard(
            draft: newPathDraftCard,
            selected: newPathDraftSelected,
            onTap: onSelectNewPathDraft,
          );
        }
        final legacyIndex = newPathVisible ? 1 : 0;
        if (draftCard != null && legacyDraftVisible && index == legacyIndex) {
          return _DraftListCard(
            draft: draftCard,
            selected: draftSelected,
            onTap: onSelectDraft,
          );
        }
        final presetIndex = index - draftCount;
        final entry = filteredCards[presetIndex];
        return _PresetListCard(
          key: Key('path-studio-preset-card-${entry.sourceIndex}'),
          card: entry.card,
          selected: entry.sourceIndex == selectedSourceIndex,
          onTap: () => onSelect(entry.sourceIndex),
        );
      },
    );
  }
}

class _NewPathDraftListCard extends StatelessWidget {
  const _NewPathDraftListCard({
    required this.draft,
    required this.selected,
    required this.onTap,
  });

  final PathStudioNewPathDraft draft;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: const Key('path-studio-new-path-draft-card'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? Color.lerp(
                  PathStudioTheme.surfaceStrong,
                  PathStudioTheme.accentCyan,
                  0.22,
                )
              : PathStudioTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? PathStudioTheme.accentCyan
                : PathStudioTheme.accentCyan.withValues(alpha: 0.4),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    draft.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PathStudioTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StatusChip(
                  label: draft.isEditMode ? 'Modification' : 'Nouveau chemin',
                  color: PathStudioTheme.accentCyan,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              draft.isEditMode
                  ? 'Brouillon de modification • Non sauvegardé'
                  : 'Brouillon chemin • Non sauvegardé',
              style: const TextStyle(
                color: PathStudioTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _MiniMetric(
                  icon: CupertinoIcons.square_grid_2x2,
                  label: draft.centerPatternLabel,
                ),
                const SizedBox(width: 8),
                const _MiniMetric(
                  icon: CupertinoIcons.wand_stars,
                  label: 'à configurer',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftListCard extends StatelessWidget {
  const _DraftListCard({
    required this.draft,
    required this.selected,
    required this.onTap,
  });

  final PathPatternDraft draft;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: const Key('path-studio-draft-card'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? Color.lerp(
                  PathStudioTheme.surfaceStrong,
                  PathStudioTheme.accentCyan,
                  0.22,
                )
              : PathStudioTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? PathStudioTheme.accentCyan
                : PathStudioTheme.accentCyan.withValues(alpha: 0.4),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    draft.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PathStudioTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const _StatusChip(
                  label: 'Depuis path existant',
                  color: PathStudioTheme.accentCyan,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Structure héritée • Non sauvegardé',
              style: TextStyle(
                color: PathStudioTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _MiniMetric(
                  icon: CupertinoIcons.square_grid_2x2,
                  label: draft.centerPatternLabel,
                ),
                const SizedBox(width: 8),
                _MiniMetric(
                  icon: draft.animatedCellCount > 0
                      ? CupertinoIcons.play_circle
                      : CupertinoIcons.circle,
                  label: draft.animatedCellCount > 0 ? 'animé' : 'statique',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarCounter extends StatelessWidget {
  const _SidebarCounter({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: PathStudioTheme.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border:
            Border.all(color: PathStudioTheme.accent.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$value',
        style: const TextStyle(
          color: PathStudioTheme.accentHover,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SidebarNotice extends StatelessWidget {
  const _SidebarNotice({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: PathStudioTheme.subtleDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MacosIcon(
              CupertinoIcons.tray,
              color: PathStudioTheme.textMuted,
              size: 26,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PathStudioTheme.textMuted,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetListCard extends StatefulWidget {
  const _PresetListCard({
    super.key,
    required this.card,
    required this.selected,
    required this.onTap,
  });

  final PathPatternPresetCardModel card;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PresetListCard> createState() => _PresetListCardState();
}

class _PresetListCardState extends State<_PresetListCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final status = _statusPresentation(widget.card.status);
    final borderColor = widget.selected
        ? PathStudioTheme.accentHover
        : widget.card.status == PathPatternPresetReadinessStatus.blocked
            ? PathStudioTheme.error.withValues(alpha: 0.45)
            : PathStudioTheme.border;
    final fill = widget.selected
        ? Color.lerp(
            PathStudioTheme.surfaceStrong, PathStudioTheme.accent, 0.2)!
        : _hovered
            ? Color.lerp(
                PathStudioTheme.surfaceRaised,
                PathStudioTheme.accent,
                0.08,
              )!
            : PathStudioTheme.surfaceRaised;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: borderColor, width: widget.selected ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.card.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PathStudioTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _StatusChip(label: status.label, color: status.color),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.card.id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PathStudioTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _MiniMetric(
                    icon: CupertinoIcons.square_grid_2x2,
                    label: widget.card.centerPatternLabel,
                  ),
                  const SizedBox(width: 8),
                  _MiniMetric(
                    icon: widget.card.animatedCellCount > 0
                        ? CupertinoIcons.play_circle
                        : CupertinoIcons.circle,
                    label: widget.card.animatedCellCount > 0
                        ? 'animé'
                        : 'statique',
                  ),
                ],
              ),
              if (widget.card.hasBlockingDiagnostics ||
                  widget.card.warningCount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  widget.card.hasBlockingDiagnostics
                      ? '${widget.card.diagnostics.where((d) => d.severity == PathPatternDiagnosticSeverity.blocking).length} blocage(s)'
                      : '${widget.card.warningCount} warning(s)',
                  style: TextStyle(
                    color: widget.card.hasBlockingDiagnostics
                        ? PathStudioTheme.error
                        : PathStudioTheme.warning,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.48)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MacosIcon(icon, size: 12, color: PathStudioTheme.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: PathStudioTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CenterWorkspace extends StatelessWidget {
  const _CenterWorkspace({
    required this.manifest,
    required this.tilesets,
    required this.settings,
    required this.projectRootPath,
    required this.newPathDraft,
    required this.newPathSavePlan,
    required this.editPathSavePlan,
    required this.draft,
    required this.legacySavePlan,
    required this.hasSaveCallback,
    required this.hasNewPathSaveCallback,
    required this.saveFeedbackMessage,
    required this.selected,
    required this.selectedPreset,
    required this.hasAnyPreset,
    required this.onSavedPresetEditRequested,
    required this.onNewPathSizeChanged,
    required this.onNewPathSurfaceKindChanged,
    required this.onNewPathCellSelected,
    required this.onNewPathVariantSelected,
    required this.onNewPathTileSelected,
    required this.onNewPathCenterFrameSelected,
    required this.onNewPathCenterFrameAdded,
    required this.onNewPathCenterFrameRemoved,
    required this.onNewPathCenterFrameDurationChanged,
    required this.onNewPathCellCleared,
    required this.onNewPathVariantCleared,
    this.newPathCenterSeqFeedback,
    required this.onNewPathCenterAnimationSequenceRequested,
    required this.onDraftSizeChanged,
    required this.onDraftCellSelected,
  });

  final ProjectManifest manifest;
  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final String? projectRootPath;
  final PathStudioNewPathDraft? newPathDraft;
  final PathStudioNewPathBuildPlan? newPathSavePlan;
  final PathStudioEditPathBuildPlan? editPathSavePlan;
  final PathPatternDraft? draft;
  final PathStudioLegacyPathPatternSavePlan? legacySavePlan;
  final bool hasSaveCallback;
  final bool hasNewPathSaveCallback;
  final String? saveFeedbackMessage;
  final PathPatternPresetCardModel? selected;
  final ProjectPathPatternPreset? selectedPreset;
  final bool hasAnyPreset;
  final ValueChanged<ProjectPathPatternPreset> onSavedPresetEditRequested;
  final void Function(int width, int height) onNewPathSizeChanged;
  final ValueChanged<PathSurfaceKind> onNewPathSurfaceKindChanged;
  final void Function(int localX, int localY) onNewPathCellSelected;
  final ValueChanged<TerrainPathVariant> onNewPathVariantSelected;
  final void Function(int sourceX, int sourceY) onNewPathTileSelected;
  final ValueChanged<int> onNewPathCenterFrameSelected;
  final VoidCallback onNewPathCenterFrameAdded;
  final ValueChanged<int> onNewPathCenterFrameRemoved;
  final void Function(int frameIndex, int durationMs)
      onNewPathCenterFrameDurationChanged;
  final void Function(int localX, int localY) onNewPathCellCleared;
  final ValueChanged<TerrainPathVariant> onNewPathVariantCleared;
  final String? newPathCenterSeqFeedback;
  final void Function(
    PathStudioCenterAnimationSequenceTarget target,
    int frameCount,
    int stepX,
    int stepY,
    int durationMs,
  ) onNewPathCenterAnimationSequenceRequested;
  final void Function(int width, int height) onDraftSizeChanged;
  final void Function(int localX, int localY) onDraftCellSelected;

  @override
  Widget build(BuildContext context) {
    final newPathDraft = this.newPathDraft;
    final newPathSavePlan = this.newPathSavePlan;
    if (newPathDraft != null && newPathSavePlan != null) {
      return _NewPathCenterWorkspace(
        tilesets: tilesets,
        settings: settings,
        projectRootPath: projectRootPath,
        draft: newPathDraft,
        savePlan: newPathSavePlan,
        editSavePlan: editPathSavePlan,
        hasSaveCallback: hasNewPathSaveCallback,
        onSizeChanged: onNewPathSizeChanged,
        onSurfaceKindChanged: onNewPathSurfaceKindChanged,
        onCellSelected: onNewPathCellSelected,
        onVariantSelected: onNewPathVariantSelected,
        onTileSelected: onNewPathTileSelected,
        onCenterFrameSelected: onNewPathCenterFrameSelected,
        onCenterFrameAdded: onNewPathCenterFrameAdded,
        onCenterFrameRemoved: onNewPathCenterFrameRemoved,
        onCenterFrameDurationChanged: onNewPathCenterFrameDurationChanged,
        onCellCleared: onNewPathCellCleared,
        onVariantCleared: onNewPathVariantCleared,
        centerSequenceFeedback: newPathCenterSeqFeedback,
        onCenterAnimationSequenceRequested:
            onNewPathCenterAnimationSequenceRequested,
      );
    }
    final draft = this.draft;
    final legacySavePlan = this.legacySavePlan;
    if (draft != null && legacySavePlan != null) {
      return _DraftCenterWorkspace(
        draft: draft,
        savePlan: legacySavePlan,
        hasSaveCallback: hasSaveCallback,
        saveFeedbackMessage: saveFeedbackMessage,
        onSizeChanged: onDraftSizeChanged,
        onCellSelected: onDraftCellSelected,
      );
    }
    final card = selected;
    if (card == null) {
      return _NoSelectionCenter(hasAnyPreset: hasAnyPreset);
    }

    final preset = selectedPreset;
    if (preset == null) {
      return _NoSelectionCenter(hasAnyPreset: hasAnyPreset);
    }
    final detail = _createSavedPathPatternDetail(
      manifest: manifest,
      preset: preset,
    );
    final editAvailability = _resolveEditAvailability(
      manifest: manifest,
      preset: preset,
    );
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WorkflowSteps(status: card.status),
          const SizedBox(height: 14),
          _SelectedSummary(card: card),
          const SizedBox(height: 14),
          _SavedPresetCenterDetail(
            detail: detail,
            editAvailability: editAvailability,
            tilesets: tilesets,
            settings: settings,
            projectRootPath: projectRootPath,
            onEditRequested: () => onSavedPresetEditRequested(preset),
          ),
          const SizedBox(height: 14),
          _DiagnosticsCard(card: card),
        ],
      ),
    );
  }
}

class _DraftCenterWorkspace extends StatelessWidget {
  const _DraftCenterWorkspace({
    required this.draft,
    required this.savePlan,
    required this.hasSaveCallback,
    required this.saveFeedbackMessage,
    required this.onSizeChanged,
    required this.onCellSelected,
  });

  final PathPatternDraft draft;
  final PathStudioLegacyPathPatternSavePlan savePlan;
  final bool hasSaveCallback;
  final String? saveFeedbackMessage;
  final void Function(int width, int height) onSizeChanged;
  final void Function(int localX, int localY) onCellSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _DraftBanner(),
          const SizedBox(height: 14),
          const _WorkflowSteps(
            status: PathPatternPresetReadinessStatus.needsReview,
          ),
          const SizedBox(height: 14),
          _DraftSummary(draft: draft),
          const SizedBox(height: 14),
          _DraftCenterPatternEditor(
            draft: draft,
            onSizeChanged: onSizeChanged,
            onCellSelected: onCellSelected,
          ),
          const SizedBox(height: 14),
          _DraftDiagnosticsCard(draft: draft),
          const SizedBox(height: 14),
          _LegacyPathSaveStatusCard(
            plan: savePlan,
            hasSaveCallback: hasSaveCallback,
            feedbackMessage: saveFeedbackMessage,
          ),
        ],
      ),
    );
  }
}

class _DraftBanner extends StatelessWidget {
  const _DraftBanner();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: 'Motif depuis path existant',
      icon: CupertinoIcons.pencil_outline,
      trailing: _StatusChip(
        label: 'Non sauvegardé',
        color: PathStudioTheme.warning,
      ),
      child: Text(
        'Ce brouillon réutilise temporairement une structure héritée. Il reste local et non sauvegardé.',
        style: TextStyle(
          color: PathStudioTheme.textSecondary,
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }
}

class _DraftSummary extends StatelessWidget {
  const _DraftSummary({required this.draft});

  final PathPatternDraft draft;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Résumé du brouillon',
      icon: CupertinoIcons.doc_text,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _InfoTile(label: 'Nom', value: draft.name),
          _InfoTile(label: 'Structure héritée', value: draft.basePathPresetId),
          _InfoTile(label: 'Centre', value: draft.centerPatternLabel),
          _InfoTile(label: 'Cellules', value: '${draft.centerCellCount}'),
          _InfoTile(label: 'Frames', value: '${draft.centerFrameCount}'),
          _InfoTile(
            label: 'Animation',
            value: '${draft.animatedCellCount} cellules',
          ),
          const _InfoTile(label: 'État', value: 'Brouillon non sauvegardé'),
        ],
      ),
    );
  }
}

class _DraftCenterPatternEditor extends StatelessWidget {
  const _DraftCenterPatternEditor({
    required this.draft,
    required this.onSizeChanged,
    required this.onCellSelected,
  });

  final PathPatternDraft draft;
  final void Function(int width, int height) onSizeChanged;
  final void Function(int localX, int localY) onCellSelected;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Motif du centre',
      icon: CupertinoIcons.square_grid_2x2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Le motif du centre sera répété dans les grandes zones pleines.',
            style: TextStyle(
              color: PathStudioTheme.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          CupertinoSlidingSegmentedControl<String>(
            key: const Key('path-studio-draft-size-control'),
            groupValue: draft.centerPatternLabel,
            onValueChanged: (value) {
              if (value == '1×1') {
                onSizeChanged(1, 1);
              } else if (value == '2×2') {
                onSizeChanged(2, 2);
              }
            },
            children: const {
              '1×1': Padding(
                key: Key('path-studio-draft-size-1x1'),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Text('1×1'),
              ),
              '2×2': Padding(
                key: Key('path-studio-draft-size-2x2'),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Text('2×2'),
              ),
            },
          ),
          const SizedBox(height: 18),
          _DraftPatternGrid(
            draft: draft,
            onCellSelected: onCellSelected,
          ),
          const SizedBox(height: 14),
          _DraftSelectedCellDetails(draft: draft),
        ],
      ),
    );
  }
}

class _DraftPatternGrid extends StatelessWidget {
  const _DraftPatternGrid({
    required this.draft,
    required this.onCellSelected,
  });

  final PathPatternDraft draft;
  final void Function(int localX, int localY) onCellSelected;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    var labelCode = 'A'.codeUnitAt(0);
    for (var y = 0; y < draft.centerPattern.size.height; y += 1) {
      final cells = <Widget>[];
      for (var x = 0; x < draft.centerPattern.size.width; x += 1) {
        final cell = draft.centerPattern.cellAt(x, y);
        cells.add(
          _DraftPatternCell(
            key: Key('path-studio-draft-cell-$x-$y'),
            label: String.fromCharCode(labelCode),
            cell: cell,
            selected: draft.selectedCellX == x && draft.selectedCellY == y,
            onTap: () => onCellSelected(x, y),
          ),
        );
        labelCode += 1;
      }
      rows.add(Row(mainAxisSize: MainAxisSize.min, children: cells));
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(
        color: PathStudioTheme.backgroundAlt,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

class _DraftPatternCell extends StatelessWidget {
  const _DraftPatternCell({
    super.key,
    required this.label,
    required this.cell,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final PathCenterPatternCell cell;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final source = cell.frames.first.source;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 112,
        height: 92,
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Color.lerp(
            PathStudioTheme.surfaceStrong,
            selected ? PathStudioTheme.accent : PathStudioTheme.accentCyan,
            selected ? 0.32 : 0.16,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? PathStudioTheme.accentHover
                : PathStudioTheme.accentCyan.withValues(alpha: 0.45),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text(
              '${cell.frames.length} frame${cell.frames.length > 1 ? 's' : ''}',
              style: const TextStyle(
                color: PathStudioTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              cell.frames.length > 1 ? 'animé' : 'statique',
              style: const TextStyle(
                color: PathStudioTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'source ${source.x},${source.y}',
              style: const TextStyle(
                color: PathStudioTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftSelectedCellDetails extends StatelessWidget {
  const _DraftSelectedCellDetails({required this.draft});

  final PathPatternDraft draft;

  @override
  Widget build(BuildContext context) {
    final cell = draft.selectedCell;
    final source = cell.frames.first.source;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cellule sélectionnée',
            style: TextStyle(
              color: PathStudioTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Position ${cell.localX},${cell.localY}',
            style: const TextStyle(
              color: PathStudioTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${cell.frames.length} frame${cell.frames.length > 1 ? 's' : ''} • source ${source.x},${source.y}',
            style: const TextStyle(
              color: PathStudioTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftDiagnosticsCard extends StatelessWidget {
  const _DraftDiagnosticsCard({required this.draft});

  final PathPatternDraft draft;

  @override
  Widget build(BuildContext context) {
    final issues = draft.issues;
    return _SectionCard(
      title: 'Diagnostics locaux',
      icon: CupertinoIcons.check_mark_circled,
      child: issues.isEmpty
          ? const _DiagnosticRow(
              icon: CupertinoIcons.check_mark_circled_solid,
              color: PathStudioTheme.success,
              title: 'Aucune erreur locale',
              message: 'Le brouillon est éditable en mémoire.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: issues
                  .map(
                    (issue) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DiagnosticRow(
                        icon: CupertinoIcons.exclamationmark_triangle_fill,
                        color: PathStudioTheme.warning,
                        title: _draftIssueLabel(issue),
                        message: _draftIssueDescription(issue),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _LegacyPathSaveStatusCard extends StatelessWidget {
  const _LegacyPathSaveStatusCard({
    required this.plan,
    required this.hasSaveCallback,
    required this.feedbackMessage,
  });

  final PathStudioLegacyPathPatternSavePlan plan;
  final bool hasSaveCallback;
  final String? feedbackMessage;

  @override
  Widget build(BuildContext context) {
    final ready = plan.canSaveNow;
    return _SectionCard(
      key: const Key('path-studio-save-status-card'),
      title: 'Sauvegarde',
      icon: CupertinoIcons.floppy_disk,
      trailing: _StatusChip(
        label: ready ? 'Requête prête' : 'Bloquée',
        color: ready ? PathStudioTheme.success : PathStudioTheme.warning,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              const _InfoTile(
                label: 'État',
                value: 'Motif PathPattern depuis path existant',
              ),
              _InfoTile(
                label: 'ID proposé',
                value: plan.proposedPathPatternPresetId,
              ),
              _InfoTile(label: 'Base', value: plan.basePathPresetId),
              _InfoTile(
                label: 'Action',
                value: ready ? 'Requête prête' : 'À corriger',
              ),
            ],
          ),
          if (feedbackMessage != null) ...[
            const SizedBox(height: 12),
            _DiagnosticRow(
              icon: CupertinoIcons.check_mark_circled_solid,
              color: PathStudioTheme.success,
              title: feedbackMessage!,
              message:
                  'Le callback a reçu le ProjectPathPatternPreset préparé. Le manifest reste inchangé.',
            ),
          ],
          if (ready && !hasSaveCallback) ...[
            const SizedBox(height: 12),
            const _DiagnosticRow(
              icon: CupertinoIcons.info_circle_fill,
              color: PathStudioTheme.warning,
              title: 'Callback de sauvegarde absent',
              message:
                  'La requête locale est prête, mais aucun callback externe ne l’utilise encore.',
            ),
          ],
          if (plan.issues.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SaveIssueList(issues: plan.issues),
          ],
        ],
      ),
    );
  }
}

class _SaveIssueList extends StatelessWidget {
  const _SaveIssueList({required this.issues});

  final List<PathStudioSaveIssueCode> issues;

  @override
  Widget build(BuildContext context) {
    if (issues.isEmpty) {
      return const _DiagnosticRow(
        icon: CupertinoIcons.check_mark_circled_solid,
        color: PathStudioTheme.success,
        title: 'Aucune issue de sauvegarde locale',
        message: 'La préparation locale ne signale aucun blocage.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final issue in issues)
          Padding(
            key: Key('path-studio-save-issue-${issue.name}'),
            padding: const EdgeInsets.only(bottom: 8),
            child: _DiagnosticRow(
              icon: CupertinoIcons.exclamationmark_triangle_fill,
              color: issue == PathStudioSaveIssueCode.pathVariantMappingRequired
                  ? PathStudioTheme.warning
                  : PathStudioTheme.accentCyan,
              title: pathStudioSaveIssueLabel(issue),
              message: pathStudioSaveIssueDescription(issue),
            ),
          ),
      ],
    );
  }
}

class _NoSelectionCenter extends StatelessWidget {
  const _NoSelectionCenter({required this.hasAnyPreset});

  final bool hasAnyPreset;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PathStudioTheme.panelDecoration(
        color: PathStudioTheme.surface,
      ),
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MacosIcon(
              CupertinoIcons.square_grid_2x2,
              color: PathStudioTheme.accentCyan,
              size: 44,
            ),
            const SizedBox(height: 16),
            Text(
              hasAnyPreset
                  ? 'Aucun preset sélectionné'
                  : 'Aucun motif PathPattern',
              style: const TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasAnyPreset
                  ? 'Sélectionnez un preset dans la liste pour inspecter sa structure.'
                  : 'Les futurs lots permettront de créer un premier motif de centre.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PathStudioTheme.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkflowSteps extends StatelessWidget {
  const _WorkflowSteps({required this.status});

  final PathPatternPresetReadinessStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PathStudioTheme.panelDecoration(
        color: PathStudioTheme.surface,
        radius: 18,
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                const _StepPill(
                  index: 1,
                  label: 'Base',
                  active: false,
                  complete: true,
                ),
                const _StepArrow(),
                const _StepPill(
                  index: 2,
                  label: 'Motif du centre',
                  active: true,
                ),
                const _StepArrow(),
                _StepPill(
                  index: 3,
                  label: 'Aperçu',
                  active: false,
                  complete: status == PathPatternPresetReadinessStatus.ready,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({
    required this.index,
    required this.label,
    required this.active,
    this.complete = false,
  });

  final int index;
  final String label;
  final bool active;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? PathStudioTheme.accentHover
        : complete
            ? PathStudioTheme.success
            : PathStudioTheme.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: active ? 0.2 : 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              complete ? '✓' : '$index',
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: active ? PathStudioTheme.textPrimary : color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepArrow extends StatelessWidget {
  const _StepArrow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 10),
      child: MacosIcon(
        CupertinoIcons.chevron_right,
        size: 13,
        color: PathStudioTheme.textMuted,
      ),
    );
  }
}

class _SelectedSummary extends StatelessWidget {
  const _SelectedSummary({required this.card});

  final PathPatternPresetCardModel card;

  @override
  Widget build(BuildContext context) {
    final status = _statusPresentation(card.status);
    return _SectionCard(
      title: 'Résumé du preset',
      icon: CupertinoIcons.doc_text,
      trailing: _StatusChip(label: status.label, color: status.color),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _InfoTile(label: 'Nom', value: card.name),
          _InfoTile(
              label: 'Base', value: card.basePathPresetName ?? 'Introuvable'),
          _InfoTile(label: 'Centre', value: card.centerPatternLabel),
          _InfoTile(label: 'Cellules', value: '${card.centerCellCount}'),
          _InfoTile(label: 'Frames', value: '${card.centerFrameCount}'),
          _InfoTile(
              label: 'Animation', value: '${card.animatedCellCount} cellules'),
          _InfoTile(
            label: 'Transparent',
            value: card.transparentColorHex ?? 'Absent',
          ),
        ],
      ),
    );
  }
}

class _DiagnosticsCard extends StatelessWidget {
  const _DiagnosticsCard({required this.card});

  final PathPatternPresetCardModel card;

  @override
  Widget build(BuildContext context) {
    final diagnostics = List<PathPatternDiagnostic>.from(card.diagnostics)
      ..sort((left, right) {
        final severityCompare = _diagnosticSortWeight(left.severity).compareTo(
          _diagnosticSortWeight(right.severity),
        );
        if (severityCompare != 0) {
          return severityCompare;
        }
        return left.title.compareTo(right.title);
      });
    return _SectionCard(
      title: 'Diagnostics',
      icon: CupertinoIcons.check_mark_circled,
      child: diagnostics.isEmpty
          ? const _DiagnosticRow(
              icon: CupertinoIcons.check_mark_circled_solid,
              color: PathStudioTheme.success,
              title: 'Prêt',
              message: 'Aucun diagnostic bloquant ou warning détecté.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: diagnostics
                  .map(
                    (diagnostic) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DiagnosticRow(
                        icon: _diagnosticIcon(diagnostic.severity),
                        color: _diagnosticColor(diagnostic.severity),
                        title: diagnostic.title,
                        message: diagnostic.suggestion == null
                            ? diagnostic.description
                            : '${diagnostic.description}\n${diagnostic.suggestion!}',
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _PresetInspector extends StatelessWidget {
  const _PresetInspector({
    required this.manifest,
    required this.newPathDraft,
    required this.draft,
    required this.selected,
    required this.selectedPreset,
    required this.onNewPathNameChanged,
    required this.onNewPathTilesetChanged,
    required this.onNewPathSurfaceKindChanged,
    required this.onNewPathSizeChanged,
    required this.onDraftNameChanged,
    required this.onDraftBaseChanged,
    required this.onDraftSizeChanged,
  });

  final ProjectManifest manifest;
  final PathStudioNewPathDraft? newPathDraft;
  final PathPatternDraft? draft;
  final PathPatternPresetCardModel? selected;
  final ProjectPathPatternPreset? selectedPreset;
  final ValueChanged<String> onNewPathNameChanged;
  final ValueChanged<String> onNewPathTilesetChanged;
  final ValueChanged<PathSurfaceKind> onNewPathSurfaceKindChanged;
  final void Function(int width, int height) onNewPathSizeChanged;
  final ValueChanged<String> onDraftNameChanged;
  final ValueChanged<String> onDraftBaseChanged;
  final void Function(int width, int height) onDraftSizeChanged;

  @override
  Widget build(BuildContext context) {
    final newPathDraft = this.newPathDraft;
    if (newPathDraft != null) {
      return _NewPathInspector(
        tilesets: manifest.tilesets,
        draft: newPathDraft,
        onNameChanged: onNewPathNameChanged,
        onTilesetChanged: onNewPathTilesetChanged,
        onSurfaceKindChanged: onNewPathSurfaceKindChanged,
        onSizeChanged: onNewPathSizeChanged,
      );
    }
    final draft = this.draft;
    if (draft != null) {
      return _LegacyDraftInspector(
        manifest: manifest,
        draft: draft,
        onNameChanged: onDraftNameChanged,
        onBaseChanged: onDraftBaseChanged,
        onSizeChanged: onDraftSizeChanged,
      );
    }
    final card = selected;
    final preset = selectedPreset;
    final basePathPreset = preset == null
        ? null
        : _resolveBasePathPreset(
            manifest: manifest,
            basePathPresetId: preset.basePathPresetId,
          );
    final baseTilesetId = basePathPreset?.tilesetId.trim() ?? '';
    return Container(
      decoration: PathStudioTheme.panelDecoration(),
      padding: const EdgeInsets.all(16),
      child: card == null || preset == null
          ? const _InspectorEmptyState()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Propriétés du preset',
                    style: TextStyle(
                      color: PathStudioTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _StatusChip(
                    label: 'Present dans le projet',
                    color: PathStudioTheme.success,
                  ),
                  const SizedBox(height: 12),
                  _InspectorRow(label: 'Nom', value: preset.name),
                  _InspectorRow(label: 'ID', value: preset.id),
                  _InspectorRow(
                    label: 'Base path preset id',
                    value: preset.basePathPresetId,
                  ),
                  _InspectorRow(
                    label: 'Base path name',
                    value: card.basePathPresetName ?? 'Introuvable',
                  ),
                  _InspectorRow(
                    label: 'Tileset de base',
                    value: baseTilesetId.isEmpty
                        ? 'Non disponible'
                        : baseTilesetId,
                  ),
                  _InspectorRow(
                    label: 'Taille du centre',
                    value:
                        '${preset.centerPattern.size.width}×${preset.centerPattern.size.height}',
                  ),
                  _InspectorRow(
                      label: 'Cellules', value: '${card.centerCellCount}'),
                  _InspectorRow(
                      label: 'Frames', value: '${card.centerFrameCount}'),
                  _InspectorRow(
                    label: 'Cellules animees',
                    value: '${card.animatedCellCount}',
                  ),
                  _InspectorRow(
                    label: 'Transparent color',
                    value: preset.transparentColor?.toHexRgb() ?? 'Aucune',
                  ),
                  const _InspectorRow(
                    label: 'Statut',
                    value: 'Present dans le projet',
                  ),
                  const SizedBox(height: 14),
                  _DiagnosticsCard(card: card),
                ],
              ),
            ),
    );
  }
}

class _LegacyDraftInspector extends StatelessWidget {
  const _LegacyDraftInspector({
    required this.manifest,
    required this.draft,
    required this.onNameChanged,
    required this.onBaseChanged,
    required this.onSizeChanged,
  });

  final ProjectManifest manifest;
  final PathPatternDraft draft;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onBaseChanged;
  final void Function(int width, int height) onSizeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PathStudioTheme.panelDecoration(),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Propriétés du motif depuis path existant',
              style: TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            const _StatusChip(
              label: 'Brouillon non sauvegardé',
              color: PathStudioTheme.warning,
            ),
            const SizedBox(height: 14),
            const _InspectorLabel('Nom'),
            CupertinoTextField(
              key: const Key('path-studio-draft-name-field'),
              placeholder: draft.name,
              onChanged: onNameChanged,
              style: const TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              placeholderStyle: const TextStyle(
                color: PathStudioTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              decoration: BoxDecoration(
                color: PathStudioTheme.surfaceRaised,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PathStudioTheme.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            ),
            const SizedBox(height: 12),
            const _InspectorLabel('Structure héritée'),
            _DraftBasePopup(
              manifest: manifest,
              draft: draft,
              onBaseChanged: onBaseChanged,
            ),
            const SizedBox(height: 12),
            const _InspectorLabel('Taille du centre'),
            CupertinoSlidingSegmentedControl<String>(
              groupValue: draft.centerPatternLabel,
              onValueChanged: (value) {
                if (value == '1×1') {
                  onSizeChanged(1, 1);
                } else if (value == '2×2') {
                  onSizeChanged(2, 2);
                }
              },
              children: const {
                '1×1': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text('1×1'),
                ),
                '2×2': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text('2×2'),
                ),
              },
            ),
            const SizedBox(height: 14),
            _InspectorRow(label: 'ID temporaire', value: draft.id),
            _InspectorRow(
              label: 'Path existant réutilisé',
              value: draft.basePathPresetId,
            ),
            _InspectorRow(label: 'Cellules', value: '${draft.centerCellCount}'),
            _InspectorRow(label: 'Frames', value: '${draft.centerFrameCount}'),
            _InspectorRow(
              label: 'Cellules animées',
              value: '${draft.animatedCellCount}',
            ),
            _InspectorRow(
              label: 'Transparent color',
              value: draft.transparentColor?.toHexRgb() ?? 'Aucune',
            ),
            const _InspectorRow(
              label: 'État',
              value: 'Brouillon non sauvegardé',
            ),
            const SizedBox(height: 14),
            _DraftDiagnosticsCard(draft: draft),
          ],
        ),
      ),
    );
  }
}

class _DraftBasePopup extends StatelessWidget {
  const _DraftBasePopup({
    required this.manifest,
    required this.draft,
    required this.onBaseChanged,
  });

  final ProjectManifest manifest;
  final PathPatternDraft draft;
  final ValueChanged<String> onBaseChanged;

  @override
  Widget build(BuildContext context) {
    return MacosPopupButton<String>(
      key: const Key('path-studio-draft-base-popup'),
      value: draft.basePathPresetId,
      onChanged: (value) {
        if (value != null) {
          onBaseChanged(value);
        }
      },
      items: [
        for (final preset in manifest.pathPresets)
          MacosPopupMenuItem<String>(
            value: preset.id,
            child: SizedBox(
              width: 220,
              child: Text(
                '${preset.name} (${preset.id})',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }
}

class _InspectorLabel extends StatelessWidget {
  const _InspectorLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: PathStudioTheme.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InspectorEmptyState extends StatelessWidget {
  const _InspectorEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Propriétés du preset',
          style: TextStyle(
            color: PathStudioTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 18),
        _SidebarNotice(
          title: 'Aucun preset sélectionné',
          message: 'Les détails s’afficheront ici après sélection.',
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PathStudioTheme.panelDecoration(
        color: PathStudioTheme.surface,
        radius: 20,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MacosIcon(icon, color: PathStudioTheme.accentCyan, size: 18),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: PathStudioTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: PathStudioTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PathStudioTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectorRow extends StatelessWidget {
  const _InspectorRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(
        color: PathStudioTheme.surfaceRaised,
        radius: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: PathStudioTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: PathStudioTheme.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MacosIcon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: PathStudioTheme.textSecondary,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

_StatusPresentation _statusPresentation(
  PathPatternPresetReadinessStatus status,
) {
  return switch (status) {
    PathPatternPresetReadinessStatus.ready => const _StatusPresentation(
        label: 'Prêt',
        color: PathStudioTheme.success,
      ),
    PathPatternPresetReadinessStatus.needsReview => const _StatusPresentation(
        label: 'À vérifier',
        color: PathStudioTheme.warning,
      ),
    PathPatternPresetReadinessStatus.blocked => const _StatusPresentation(
        label: 'Bloqué',
        color: PathStudioTheme.error,
      ),
  };
}

class _StatusPresentation {
  const _StatusPresentation({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;
}

int _diagnosticSortWeight(PathPatternDiagnosticSeverity severity) {
  return switch (severity) {
    PathPatternDiagnosticSeverity.blocking => 0,
    PathPatternDiagnosticSeverity.warning => 1,
    PathPatternDiagnosticSeverity.info => 2,
  };
}

Color _diagnosticColor(PathPatternDiagnosticSeverity severity) {
  return switch (severity) {
    PathPatternDiagnosticSeverity.blocking => PathStudioTheme.error,
    PathPatternDiagnosticSeverity.warning => PathStudioTheme.warning,
    PathPatternDiagnosticSeverity.info => PathStudioTheme.accent,
  };
}

IconData _diagnosticIcon(PathPatternDiagnosticSeverity severity) {
  return switch (severity) {
    PathPatternDiagnosticSeverity.blocking =>
      CupertinoIcons.exclamationmark_triangle_fill,
    PathPatternDiagnosticSeverity.warning =>
      CupertinoIcons.exclamationmark_triangle,
    PathPatternDiagnosticSeverity.info => CupertinoIcons.info_circle_fill,
  };
}

String _draftIssueLabel(PathPatternDraftIssueCode issue) {
  return switch (issue) {
    PathPatternDraftIssueCode.nameRequired => 'Nom requis',
  };
}

String _draftIssueDescription(PathPatternDraftIssueCode issue) {
  return switch (issue) {
    PathPatternDraftIssueCode.nameRequired =>
      'Le brouillon peut rester éditable, mais son nom devra être renseigné avant une future sauvegarde.',
  };
}
