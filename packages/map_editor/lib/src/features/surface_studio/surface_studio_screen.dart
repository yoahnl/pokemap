import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show
        DropdownButton,
        DropdownMenuItem,
        InputDecoration,
        Material,
        MaterialType,
        OutlineInputBorder,
        TextField;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_role_mapping_editor.dart';

import '../editor/application/editor_ai_settings.dart';
import 'atlas/surface_studio_atlas_panel.dart';
import 'preview/surface_studio_preview_panel.dart';
import 'schema/surface_studio_schema_panel.dart';
import 'shell/surface_studio_bottom_action_bar.dart';
import 'shell/surface_studio_header.dart';
import 'shell/surface_studio_shell.dart';
import 'shell/surface_studio_sidebar.dart';
import 'surface_studio_atlas_authoring_prep.dart';
import 'surface_studio_atlas_grid_overlay.dart';
import 'surface_studio_atlas_grid_preview.dart';
import 'surface_studio_atlas_image_preview.dart';
import 'surface_studio_atlas_source_picker.dart';
import 'surface_studio_ai_mapping_suggester.dart';
import 'surface_studio_column_selection.dart';
import 'surface_studio_design_tokens.dart';
import 'surface_studio_drag_payload.dart';
import 'surface_studio_mapping_suggestion_controller.dart';
import 'surface_studio_mapping_suggestion_models.dart';
import 'surface_studio_mistral_mapping_suggester.dart';
import 'surface_studio_role_assignment_draft.dart';
import 'surface_studio_step.dart';
import 'surface_studio_vertical_atlas_animation_generation_plan.dart';
import 'surface_studio_vertical_atlas_animation_generator.dart';
import 'surface_studio_vertical_atlas_preset_generator.dart';
import 'surface_studio_vertical_atlas_role_mapping.dart';

class SurfaceStudioScreen extends StatefulWidget {
  const SurfaceStudioScreen({
    super.key,
    required this.readModel,
    this.projectSettings,
    this.projectTilesets = const <ProjectTilesetEntry>[],
    this.projectRootPath,
    this.surfaceMappingImageLoader,
    this.hasWorkCatalogChanges = false,
    this.saveFlowPrepNote,
    this.projectSaveDiskNote,
    this.onSurfaceCatalogChanged,
    this.onWorkCatalogAnimationsCreated,
    this.onWorkCatalogPresetCreated,
    this.onResetWorkCatalog,
    this.onSurfaceCatalogSavePrep,
    this.onRequestProjectSave,
    this.advancedDrawer,
    this.aiMappingSuggester,
  });

  final SurfaceStudioReadModel readModel;
  final ProjectSettings? projectSettings;
  final List<ProjectTilesetEntry> projectTilesets;
  final String? projectRootPath;
  final SurfaceStudioAtlasUiImageLoader? surfaceMappingImageLoader;
  final bool hasWorkCatalogChanges;
  final String? saveFlowPrepNote;
  final String? projectSaveDiskNote;
  final ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogChanged;
  final ValueChanged<List<String>>? onWorkCatalogAnimationsCreated;
  final ValueChanged<String>? onWorkCatalogPresetCreated;
  final VoidCallback? onResetWorkCatalog;
  final VoidCallback? onSurfaceCatalogSavePrep;
  final Future<void> Function()? onRequestProjectSave;
  final Widget? advancedDrawer;
  final SurfaceStudioAiMappingSuggester? aiMappingSuggester;

  @override
  State<SurfaceStudioScreen> createState() => _SurfaceStudioScreenState();
}

class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
  static const int _defaultDurationMsPerFrame = 120;

  SurfaceStudioWizardStep _currentStep = SurfaceStudioWizardStep.map;
  bool _sidebarCollapsed = false;
  bool _rightPanelCollapsed = false;
  bool _advancedDrawerOpen = false;
  bool _suggestionReviewOpen = false;
  bool _aiConfirmationOpen = false;
  bool _mergeAiAfterConfirmation = false;
  bool _suggestionRunning = false;
  String? _mistralProgressMessage;
  Set<String> _openSchemaGroups = const {
    'surfaceMain',
    'edges',
    'externalCorners',
    'internalCorners',
    'junctions',
  };
  SurfaceStudioColumnSelection _selectedColumns =
      const SurfaceStudioColumnSelection(<int>[4, 5]);
  SurfaceStudioRoleAssignmentDraft _assignmentDraft =
      const SurfaceStudioRoleAssignmentDraft.empty();
  double _zoomPercent = 100;
  bool _previewPlaying = false;
  int _previewFrameIndex = 0;
  bool _previewLoop = true;
  bool _previewGridVisible = true;
  int _previewSize = 10;
  String? _statusMessage;
  String? _lastGenerationMessage;
  String? _lastPresetMessage;
  SurfaceStudioMappingSuggestionResult? _suggestionResult;
  Timer? _previewTimer;
  String? _cachedAtlasImagePath;
  Uint8List? _cachedAtlasImageBytes;

  final TextEditingController _atlasId = TextEditingController();
  final TextEditingController _atlasName = TextEditingController();
  final TextEditingController _tilesetId = TextEditingController();
  final TextEditingController _tileWidth = TextEditingController();
  final TextEditingController _tileHeight = TextEditingController();
  final TextEditingController _columns = TextEditingController();
  final TextEditingController _rows = TextEditingController();
  final TextEditingController _sortOrder = TextEditingController();
  final TextEditingController _categoryId = TextEditingController();
  SurfaceAtlasLayout _layout =
      SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames;
  String? _selectedAtlasId;

  @override
  void initState() {
    super.initState();
    _selectedAtlasId = widget.readModel.atlases.isNotEmpty
        ? widget.readModel.atlases.first.id
        : null;
    if (widget.readModel.atlases.isEmpty) {
      _currentStep = SurfaceStudioWizardStep.importAtlas;
    }
    _syncFormFromSelectedAtlas();
    _syncSelectionToColumnCount();
  }

  @override
  void didUpdateWidget(covariant SurfaceStudioScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.readModel != oldWidget.readModel) {
      if (_selectedAtlasId == null ||
          widget.readModel.catalog.atlasById(_selectedAtlasId!) == null) {
        _selectedAtlasId = widget.readModel.atlases.isNotEmpty
            ? widget.readModel.atlases.first.id
            : null;
      }
      _syncFormFromSelectedAtlas();
      _syncSelectionToColumnCount();
    }
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _atlasId.dispose();
    _atlasName.dispose();
    _tilesetId.dispose();
    _tileWidth.dispose();
    _tileHeight.dispose();
    _columns.dispose();
    _rows.dispose();
    _sortOrder.dispose();
    _categoryId.dispose();
    super.dispose();
  }

  ProjectSurfaceAtlas? get _selectedAtlas {
    final id = _selectedAtlasId;
    if (id == null) {
      return null;
    }
    return widget.readModel.catalog.atlasById(id);
  }

  SurfaceStudioAtlasReadModel? get _selectedAtlasRow {
    final id = _selectedAtlasId;
    if (id == null) {
      return null;
    }
    for (final row in widget.readModel.atlases) {
      if (row.id == id) {
        return row;
      }
    }
    return null;
  }

  SurfaceStudioMappingSuggestionController get _suggestionController =>
      const SurfaceStudioMappingSuggestionController();

  SurfaceStudioAtlasImagePreviewResolution get _atlasImageResolution =>
      resolveSurfaceStudioAtlasImagePreview(
        projectRootPath: widget.projectRootPath,
        projectTilesets: widget.projectTilesets,
        technicalTilesetId: _tilesetId.text,
      );

  Uint8List? _atlasImageBytes() {
    final path = _atlasImageResolution.resolvedAbsolutePath;
    if (path == null || path.isEmpty) {
      _cachedAtlasImagePath = null;
      _cachedAtlasImageBytes = null;
      return null;
    }
    if (_cachedAtlasImagePath == path && _cachedAtlasImageBytes != null) {
      return _cachedAtlasImageBytes;
    }
    try {
      final bytes = File(path).readAsBytesSync();
      _cachedAtlasImagePath = path;
      _cachedAtlasImageBytes = bytes;
      return bytes;
    } catch (_) {
      _cachedAtlasImagePath = path;
      _cachedAtlasImageBytes = null;
      return null;
    }
  }

  int get _columnCount {
    final parsed = int.tryParse(_columns.text.trim());
    if (parsed != null && parsed > 0) {
      return parsed.clamp(1, 48).toInt();
    }
    final row = _selectedAtlasRow;
    return (row?.columns ?? 12).clamp(1, 48).toInt();
  }

  int get _frameCount {
    final parsed = int.tryParse(_rows.text.trim());
    if (parsed != null && parsed > 0) {
      return parsed.clamp(1, 128).toInt();
    }
    final row = _selectedAtlasRow;
    return (row?.rows ?? 32).clamp(1, 128).toInt();
  }

  int get _tileWidthValue {
    final parsed = int.tryParse(_tileWidth.text.trim());
    if (parsed != null && parsed > 0) {
      return parsed;
    }
    return _selectedAtlasRow?.tileWidth ?? 32;
  }

  int get _tileHeightValue {
    final parsed = int.tryParse(_tileHeight.text.trim());
    if (parsed != null && parsed > 0) {
      return parsed;
    }
    return _selectedAtlasRow?.tileHeight ?? 32;
  }

  bool get _gridValid => surfaceStudioAtlasGridOverlayDraftValid(
        _tileWidthValue,
        _tileHeightValue,
        _columnCount,
        _frameCount,
      );

  Set<SurfaceStudioWizardStep> get _completedSteps => {
        if (widget.readModel.atlases.isNotEmpty)
          SurfaceStudioWizardStep.importAtlas,
        if (_gridValid) SurfaceStudioWizardStep.slice,
        if (_assignmentDraft.isAssigned(SurfaceVariantRole.isolated))
          SurfaceStudioWizardStep.map,
        if (_generationPlan.summary.readyAnimationCount > 0)
          SurfaceStudioWizardStep.preview,
      };

  bool get _canGoNext {
    return switch (_currentStep) {
      SurfaceStudioWizardStep.importAtlas =>
        widget.readModel.atlases.isNotEmpty,
      SurfaceStudioWizardStep.slice => _gridValid,
      SurfaceStudioWizardStep.map =>
        _assignmentDraft.isAssigned(SurfaceVariantRole.isolated),
      SurfaceStudioWizardStep.preview => true,
      SurfaceStudioWizardStep.save => false,
    };
  }

  SurfaceStudioColumnRoleMappingDraft get _columnRoleMappingDraft {
    final assignments = <SurfaceStudioColumnRoleAssignment>[];
    for (final role in standardSurfaceVariantRoleOrder) {
      final columns = _assignmentDraft.columnsForRole(role);
      if (columns.isEmpty) {
        continue;
      }
      assignments.add(
        SurfaceStudioColumnRoleAssignment(
          columnIndex: (columns.first - 1).clamp(0, _columnCount - 1).toInt(),
          role: role,
        ),
      );
    }
    return SurfaceStudioColumnRoleMappingDraft(
      columnCount: _columnCount,
      assignments: List<SurfaceStudioColumnRoleAssignment>.unmodifiable(
        assignments,
      ),
    );
  }

  SurfaceStudioVerticalAtlasAnimationGenerationPlan get _generationPlan {
    final existingIds = <String>{
      for (final row in widget.readModel.animations) row.id,
    };
    return buildSurfaceStudioVerticalAtlasAnimationGenerationPlan(
      atlasIdRaw: _atlasId.text,
      mappingDraft: _columnRoleMappingDraft,
      tileWidth: _tileWidthValue,
      tileHeight: _tileHeightValue,
      columns: _columnCount,
      rows: _frameCount,
      durationMsPerFrame: _defaultDurationMsPerFrame,
      existingAnimationIds: existingIds,
    );
  }

  void _syncFormFromSelectedAtlas() {
    final atlas = _selectedAtlas;
    if (atlas == null) {
      _atlasId.text = '';
      _atlasName.text = '';
      _tilesetId.text = widget.projectTilesets.isNotEmpty
          ? widget.projectTilesets.first.id
          : '';
      _tileWidth.text = '32';
      _tileHeight.text = '32';
      _columns.text = '12';
      _rows.text = '32';
      _sortOrder.text = '${widget.readModel.catalog.atlases.length}';
      _categoryId.text = '';
      _layout = SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames;
      return;
    }
    _atlasId.text = atlas.id;
    _atlasName.text = atlas.name;
    _tilesetId.text = atlas.tilesetId;
    _tileWidth.text = '${atlas.geometry.tileSize.width}';
    _tileHeight.text = '${atlas.geometry.tileSize.height}';
    _columns.text = '${atlas.geometry.gridSize.columns}';
    _rows.text = '${atlas.geometry.gridSize.rows}';
    _sortOrder.text = '${atlas.sortOrder}';
    _categoryId.text = atlas.categoryId ?? '';
    _layout = atlas.geometry.layout;
  }

  void _syncSelectionToColumnCount() {
    final count = _columnCount;
    final valid = _selectedColumns.columns
        .where((column) => column >= 1 && column <= count)
        .toList();
    if (valid.isEmpty && count >= 1) {
      _selectedColumns = SurfaceStudioColumnSelection(<int>[
        count >= 5 ? 4 : 1,
        if (count >= 5) 5,
      ]);
    } else {
      _selectedColumns = SurfaceStudioColumnSelection(valid);
    }
  }

  void _selectStep(SurfaceStudioWizardStep step) {
    if (step == _currentStep) {
      return;
    }
    if (step.index <= _currentStep.index || _completedSteps.contains(step)) {
      setState(() {
        _currentStep = step;
        _statusMessage = null;
      });
      return;
    }
    setState(() {
      _statusMessage = 'Terminez les étapes précédentes avant d’avancer.';
    });
  }

  void _nextStep() {
    if (!_canGoNext) {
      setState(() {
        _statusMessage = switch (_currentStep) {
          SurfaceStudioWizardStep.importAtlas =>
            'Créez ou sélectionnez un atlas avant de continuer.',
          SurfaceStudioWizardStep.slice =>
            'Corrigez la grille avant de continuer.',
          SurfaceStudioWizardStep.map =>
            'Assignez au moins le rôle “Plein” avant de continuer.',
          SurfaceStudioWizardStep.preview ||
          SurfaceStudioWizardStep.save =>
            'Cette étape ne peut pas avancer.',
        };
      });
      return;
    }
    setState(() {
      _currentStep = SurfaceStudioWizardStep.values[(_currentStep.index + 1)
          .clamp(0, SurfaceStudioWizardStep.values.length - 1)
          .toInt()];
      _statusMessage = null;
    });
  }

  void _previousStep() {
    if (_currentStep == SurfaceStudioWizardStep.importAtlas) {
      return;
    }
    setState(() {
      _currentStep = SurfaceStudioWizardStep.values[_currentStep.index - 1];
      _statusMessage = null;
    });
  }

  void _togglePreviewPlaying() {
    setState(() {
      _previewPlaying = !_previewPlaying;
    });
    _syncPreviewTimer();
  }

  void _syncPreviewTimer() {
    _previewTimer?.cancel();
    _previewTimer = null;
    if (!_previewPlaying) {
      return;
    }
    _previewTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (_previewFrameIndex >= _frameCount - 1) {
          _previewFrameIndex = _previewLoop ? 0 : _frameCount - 1;
          if (!_previewLoop) {
            _previewPlaying = false;
            _syncPreviewTimer();
          }
        } else {
          _previewFrameIndex += 1;
        }
      });
    });
  }

  void _createOrUpdateAtlas() {
    final editingAtlasId = _selectedAtlasId;
    final errors = validateSurfaceStudioAtlasDraft(
      readModel: widget.readModel,
      idRaw: _atlasId.text,
      nameRaw: _atlasName.text,
      tilesetIdRaw: _tilesetId.text,
      tileWidthRaw: _tileWidth.text,
      tileHeightRaw: _tileHeight.text,
      columnsRaw: _columns.text,
      rowsRaw: _rows.text,
      sortOrderRaw: _sortOrder.text,
      categoryIdRaw: _categoryId.text,
      editingExistingAtlasId: editingAtlasId,
    );
    if (errors.isNotEmpty) {
      setState(() {
        _statusMessage = errors.first;
      });
      return;
    }
    final draft = tryBuildDraftFromForm(
      idRaw: _atlasId.text,
      nameRaw: _atlasName.text,
      tilesetIdRaw: _tilesetId.text,
      tileWidthRaw: _tileWidth.text,
      tileHeightRaw: _tileHeight.text,
      columnsRaw: _columns.text,
      rowsRaw: _rows.text,
      sortOrderRaw: _sortOrder.text,
      categoryIdRaw: _categoryId.text,
      layout: _layout,
    );
    final atlas =
        draft == null ? null : tryBuildProjectSurfaceAtlasFromDraft(draft);
    if (atlas == null) {
      setState(() {
        _statusMessage = 'Brouillon atlas invalide.';
      });
      return;
    }

    final atlases = List<ProjectSurfaceAtlas>.from(
      widget.readModel.catalog.atlases,
    );
    final existingIndex =
        atlases.indexWhere((candidate) => candidate.id == editingAtlasId);
    if (existingIndex >= 0) {
      atlases[existingIndex] = atlas;
    } else {
      atlases.add(atlas);
    }
    final next = ProjectSurfaceCatalog(
      atlases: atlases,
      animations: List<ProjectSurfaceAnimation>.from(
        widget.readModel.catalog.animations,
      ),
      presets: List<ProjectSurfacePreset>.from(
        widget.readModel.catalog.presets,
      ),
    );
    widget.onSurfaceCatalogChanged?.call(next);
    setState(() {
      _selectedAtlasId = atlas.id;
      _statusMessage = 'Atlas ajouté au catalogue de travail.';
      _currentStep = SurfaceStudioWizardStep.slice;
      _syncSelectionToColumnCount();
    });
  }

  void _openSuggestionReview() {
    _runLocalSuggestion(openReview: true);
  }

  void _runLocalSuggestion({bool openReview = false}) {
    final result = _suggestionController.suggestLocal(
      columnCount: _columnCount,
    );
    setState(() {
      _suggestionResult = result;
      _suggestionReviewOpen = openReview || _suggestionReviewOpen;
      _aiConfirmationOpen = false;
      _mistralProgressMessage = null;
      _statusMessage =
          'Suggestions locales prêtes — validation utilisateur requise.';
    });
  }

  void _requestAiSuggestion({bool mergeWithLocal = false}) {
    setState(() {
      _suggestionReviewOpen = true;
      _aiConfirmationOpen = true;
      _mergeAiAfterConfirmation = mergeWithLocal;
      _mistralProgressMessage = null;
      _statusMessage = 'Confirmation IA requise avant envoi.';
    });
  }

  Future<void> _confirmAiSuggestion({required bool mergeWithLocal}) async {
    final apiKey = resolveEditorMistralApiKey(widget.projectSettings);
    final imageBytes = _atlasImageBytes();
    final hasApiKey = apiKey.trim().isNotEmpty;
    if (!hasApiKey || imageBytes == null) {
      setState(() {
        _aiConfirmationOpen = false;
        _mistralProgressMessage = null;
        _suggestionResult = SurfaceStudioMappingSuggestionResult(
          suggestions: _suggestionResult?.suggestions ??
              const <SurfaceStudioRoleSuggestion>[],
          warnings: <String>[
            if (_suggestionResult != null) ..._suggestionResult!.warnings,
            if (!hasApiKey) 'Clé Mistral absente.',
            if (imageBytes == null) 'Image source indisponible pour Mistral.',
          ],
          source: _suggestionResult?.source ??
              SurfaceStudioMappingSuggestionSource.local,
        );
      });
      return;
    }
    setState(() {
      _suggestionRunning = true;
      _aiConfirmationOpen = false;
      _mistralProgressMessage = 'Analyse visuelle approfondie…';
    });
    final aiController = SurfaceStudioMappingSuggestionController(
      aiSuggester:
          widget.aiMappingSuggester ?? SurfaceStudioMistralMappingSuggester(),
    );
    late final SurfaceStudioMappingSuggestionResult ai;
    try {
      ai = await aiController.suggestMistral(
        apiKey: apiKey,
        imageBytes: imageBytes,
        tileWidth: _tileWidthValue,
        tileHeight: _tileHeightValue,
        columnCount: _columnCount,
        frameCount: _frameCount,
      );
    } on TimeoutException {
      ai = const SurfaceStudioMappingSuggestionResult(
        suggestions: <SurfaceStudioRoleSuggestion>[],
        warnings: <String>[
          'Mistral n’a pas répondu à temps. Aucune modification n’a été appliquée.',
        ],
        source: SurfaceStudioMappingSuggestionSource.mistral,
      );
    } catch (_) {
      ai = const SurfaceStudioMappingSuggestionResult(
        suggestions: <SurfaceStudioRoleSuggestion>[],
        warnings: <String>[
          'Analyse Mistral impossible. Aucune modification n’a été appliquée.',
        ],
        source: SurfaceStudioMappingSuggestionSource.mistral,
      );
    }
    if (!mounted) {
      return;
    }
    final result = mergeWithLocal && _suggestionResult != null
        ? SurfaceStudioMappingSuggestionResult(
            suggestions: <SurfaceStudioRoleSuggestion>[
              ..._suggestionResult!.suggestions,
              ...ai.suggestions,
            ],
            warnings: <String>[
              ..._suggestionResult!.warnings,
              ...ai.warnings,
            ],
            source: SurfaceStudioMappingSuggestionSource.merged,
          )
        : ai;
    setState(() {
      _suggestionRunning = false;
      _mistralProgressMessage = null;
      _suggestionResult = result;
      _suggestionReviewOpen = true;
      _statusMessage =
          'Suggestions IA prêtes — validation utilisateur requise.';
    });
  }

  void _applySuggestions({required bool reliableOnly}) {
    final result = _suggestionResult;
    if (result == null) {
      return;
    }
    final suggestions =
        reliableOnly ? result.reliableSuggestions : result.suggestions;
    var draft = _assignmentDraft;
    for (final suggestion in suggestions) {
      draft = draft.assignColumns(suggestion.role, suggestion.columns);
    }
    setState(() {
      _assignmentDraft = draft;
      _suggestionReviewOpen = false;
      _statusMessage = 'Suggestions appliquées au mapping de travail.';
    });
  }

  void _applySingleSuggestion(SurfaceStudioRoleSuggestion suggestion) {
    setState(() {
      _assignmentDraft =
          _assignmentDraft.assignColumns(suggestion.role, suggestion.columns);
      _statusMessage = 'Suggestion appliquée au mapping de travail.';
    });
  }

  void _useSelectionAsCenter() {
    final columns = _selectedColumns.columns;
    if (columns.isEmpty) {
      setState(() {
        _statusMessage = 'Sélectionnez au moins une colonne à assigner.';
      });
      return;
    }
    setState(() {
      _assignmentDraft =
          _assignmentDraft.assignColumns(SurfaceVariantRole.isolated, columns);
      _statusMessage = 'Colonnes sélectionnées assignées à Plein(center).';
    });
  }

  void _applyMapping() {
    setState(() {
      _statusMessage =
          'Mapping appliqué au plan de génération local — aucune sauvegarde disque.';
    });
  }

  void _acceptDrop(
    SurfaceVariantRole role,
    SurfaceStudioColumnDragPayload payload,
  ) {
    final validation = validateSurfaceStudioRoleDrop(
      role: role,
      payload: payload,
      draft: _assignmentDraft,
    );
    if (validation != SurfaceStudioDropValidation.valid) {
      setState(() {
        _statusMessage =
            validation == SurfaceStudioDropValidation.invalidNoColumn
                ? 'Aucune colonne à déposer.'
                : 'Ce rôle attend une seule colonne.';
      });
      return;
    }
    setState(() {
      _assignmentDraft = _assignmentDraft.assignColumns(role, payload.columns);
      _statusMessage = 'Colonnes déposées sur le rôle sélectionné.';
    });
  }

  void _appendReadyAnimations() {
    final plan = _generationPlan;
    if (plan.summary.readyAnimationCount == 0) {
      setState(() {
        _lastGenerationMessage = 'Aucune animation prête à créer.';
      });
      return;
    }
    final outcome = surfaceStudioCollectNewAnimationsFromReadyPlan(
      plan: plan,
      atlasIdForTileRefs: _atlasId.text.trim(),
      animationDisplayNamePrefix: _atlasName.text.trim(),
      categoryId:
          _categoryId.text.trim().isEmpty ? null : _categoryId.text.trim(),
      sortOrderBase: widget.readModel.catalog.animations.length,
    );
    if (outcome.newAnimations.isEmpty) {
      setState(() {
        _lastGenerationMessage = 'Aucune animation nouvelle à ajouter.';
      });
      return;
    }
    final next = surfaceStudioAppendAnimationsToWorkCatalog(
      catalog: widget.readModel.catalog,
      newAnimations: outcome.newAnimations,
    );
    widget.onSurfaceCatalogChanged?.call(next);
    widget.onWorkCatalogAnimationsCreated?.call(
      outcome.newAnimations.map((animation) => animation.id).toList(),
    );
    setState(() {
      _lastGenerationMessage =
          'Animations créées dans le catalogue de travail (${outcome.newAnimations.length}).';
    });
  }

  void _appendPreset() {
    final gridOk = _gridValid;
    final plan = surfaceStudioPlanVerticalAtlasPresetAppend(
      catalog: widget.readModel.catalog,
      atlasIdRaw: _atlasId.text,
      atlasDisplayName: _atlasName.text,
      atlasCategoryDraft: _categoryId.text,
      mappingDraft: _columnRoleMappingDraft,
      gridValid: gridOk,
    );
    if (!plan.canCreate) {
      setState(() {
        _lastPresetMessage =
            'Surface non créée : ${_presetPlanStatusLabel(plan.status)}.';
      });
      return;
    }
    try {
      final preset = surfaceStudioBuildVerticalAtlasPreset(
        catalog: widget.readModel.catalog,
        atlasIdRaw: _atlasId.text,
        atlasDisplayName: _atlasName.text,
        atlasCategoryDraft: _categoryId.text,
        mappingDraft: _columnRoleMappingDraft,
        gridValid: gridOk,
      );
      final next = surfaceStudioAppendPresetToWorkCatalog(
        catalog: widget.readModel.catalog,
        preset: preset,
      );
      widget.onSurfaceCatalogChanged?.call(next);
      widget.onWorkCatalogPresetCreated?.call(preset.id);
      setState(() {
        _lastPresetMessage = 'Surface prête à peindre créée : ${preset.name}.';
      });
    } on Object {
      setState(() {
        _lastPresetMessage =
            'Impossible de créer la surface peignable dans l’état actuel.';
      });
    }
  }

  String _presetPlanStatusLabel(
      SurfaceStudioVerticalAtlasPresetPlanStatus status) {
    return switch (status) {
      SurfaceStudioVerticalAtlasPresetPlanStatus.blockedEmptyAtlasId =>
        'atlas manquant',
      SurfaceStudioVerticalAtlasPresetPlanStatus.blockedInvalidGrid =>
        'grille invalide',
      SurfaceStudioVerticalAtlasPresetPlanStatus.blockedNoMapping =>
        'mapping absent',
      SurfaceStudioVerticalAtlasPresetPlanStatus.blockedMissingAnimations =>
        'animations manquantes',
      SurfaceStudioVerticalAtlasPresetPlanStatus.blockedDuplicatePresetId =>
        'surface déjà existante',
      SurfaceStudioVerticalAtlasPresetPlanStatus.incomplete => 'incomplet',
      SurfaceStudioVerticalAtlasPresetPlanStatus.ready => 'prêt',
    };
  }

  @override
  Widget build(BuildContext context) {
    final frameCount = _frameCount;
    return Stack(
      children: [
        SurfaceStudioShell(
          header: SurfaceStudioHeader(
            currentStep: _currentStep,
            completedSteps: _completedSteps,
            onStepSelected: _selectStep,
            onOpenAdvanced: () {
              setState(() => _advancedDrawerOpen = true);
            },
          ),
          sidebar: SurfaceStudioSidebar(
            collapsed: _sidebarCollapsed,
            currentStep: _currentStep,
            completedSteps: _completedSteps,
            onToggleCollapsed: () {
              setState(() => _sidebarCollapsed = !_sidebarCollapsed);
            },
            onStepSelected: _selectStep,
          ),
          workspacePanel: _buildWorkspacePanel(),
          rightDock: _buildRightDock(frameCount),
          bottomBar: SurfaceStudioBottomActionBar(
            canGoBack: _currentStep != SurfaceStudioWizardStep.importAtlas,
            canAutoSuggest: _columnCount > 0 && frameCount > 0,
            canApplyMapping:
                _assignmentDraft.isAssigned(SurfaceVariantRole.isolated),
            canGoNext: _canGoNext,
            canSaveCatalog: widget.hasWorkCatalogChanges &&
                widget.onSurfaceCatalogSavePrep != null,
            onBack: _previousStep,
            onAutoSuggest: _openSuggestionReview,
            onApplyMapping: _applyMapping,
            onNext: _nextStep,
            onSaveCatalog: widget.onSurfaceCatalogSavePrep,
          ),
        ),
        if (_statusMessage != null)
          Positioned(
            left: 318,
            bottom: 86,
            child: _StatusToast(message: _statusMessage!),
          ),
        if (widget.hasWorkCatalogChanges)
          const Positioned(
            left: 318,
            top: 76,
            child: _StatusToast(
              message:
                  'Catalogue de travail modifié — sauvegarde projet non effectuée.',
            ),
          ),
        if (_suggestionReviewOpen && _suggestionResult != null)
          Positioned.fill(
            child: _SuggestionReviewScrim(
              result: _suggestionResult!,
              mistralKeyConfigured:
                  hasEditorMistralApiKey(widget.projectSettings),
              aiConfirmationOpen: _aiConfirmationOpen,
              running: _suggestionRunning,
              progressMessage: _mistralProgressMessage,
              onCancel: () {
                setState(() {
                  _suggestionReviewOpen = false;
                  _aiConfirmationOpen = false;
                  _mistralProgressMessage = null;
                });
              },
              onRunLocal: () => _runLocalSuggestion(),
              onRequestAi: () => _requestAiSuggestion(),
              onCancelAi: () => setState(() => _aiConfirmationOpen = false),
              onConfirmAi: () => _confirmAiSuggestion(
                mergeWithLocal: _mergeAiAfterConfirmation,
              ),
              onCompare: () => _requestAiSuggestion(mergeWithLocal: true),
              onApplySuggestion: _applySingleSuggestion,
              onApplyReliable: () => _applySuggestions(reliableOnly: true),
              onApplyAll: () => _applySuggestions(reliableOnly: false),
            ),
          ),
        if (_advancedDrawerOpen && widget.advancedDrawer != null)
          Positioned.fill(
            child: _AdvancedDrawerScrim(
              child: widget.advancedDrawer!,
              onClose: () {
                setState(() => _advancedDrawerOpen = false);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildWorkspacePanel() {
    final frameCount = _frameCount;
    return switch (_currentStep) {
      SurfaceStudioWizardStep.importAtlas => _ImportStepPanel(
          readModel: widget.readModel,
          projectTilesets: widget.projectTilesets,
          projectRootPath: widget.projectRootPath,
          atlasId: _atlasId,
          atlasName: _atlasName,
          tilesetId: _tilesetId,
          tileWidth: _tileWidth,
          tileHeight: _tileHeight,
          columns: _columns,
          rows: _rows,
          sortOrder: _sortOrder,
          categoryId: _categoryId,
          layout: _layout,
          onLayoutChanged: (layout) => setState(() => _layout = layout),
          onCreateAtlas: _createOrUpdateAtlas,
          onTilesetChanged: (value) {
            setState(() {
              _tilesetId.text = value ?? '';
            });
          },
        ),
      SurfaceStudioWizardStep.slice => _SliceStepPanel(
          projectTilesets: widget.projectTilesets,
          projectRootPath: widget.projectRootPath,
          atlasId: _atlasId,
          atlasName: _atlasName,
          tilesetId: _tilesetId,
          tileWidth: _tileWidth,
          tileHeight: _tileHeight,
          columns: _columns,
          rows: _rows,
          layout: _layout,
          onChanged: () => setState(() {}),
          onApplyGrid: _createOrUpdateAtlas,
          onResetGrid: () {
            setState(() {
              _tileWidth.text = '32';
              _tileHeight.text = '32';
              _columns.text = '12';
              _rows.text = '32';
              _zoomPercent = 100;
              _statusMessage = 'Grille réinitialisée.';
            });
          },
        ),
      SurfaceStudioWizardStep.map => SurfaceStudioAtlasPanel(
          columnCount: _columnCount,
          frameCount: _frameCount,
          tileWidth: _tileWidthValue,
          tileHeight: _tileHeightValue,
          atlasImageBytes: _atlasImageBytes(),
          atlasImageFallbackLabel: _atlasImageBytes() == null
              ? 'Image source indisponible — aperçu illustratif.'
              : null,
          selection: _selectedColumns,
          centerAssigned:
              _assignmentDraft.isAssigned(SurfaceVariantRole.isolated),
          centerColumns:
              _assignmentDraft.columnsForRole(SurfaceVariantRole.isolated),
          zoomPercent: _zoomPercent,
          onColumnSelectionChanged: (selection) {
            setState(() => _selectedColumns = selection);
          },
          onUseSelectionAsCenter: _useSelectionAsCenter,
          onZoomChanged: (value) {
            setState(() => _zoomPercent = value.clamp(25, 400).toDouble());
          },
          onReset: () {
            setState(() {
              _selectedColumns = const SurfaceStudioColumnSelection.empty();
              _zoomPercent = 100;
              _statusMessage = 'Sélection et zoom réinitialisés.';
            });
          },
          onAutoSuggest: _openSuggestionReview,
        ),
      SurfaceStudioWizardStep.preview => _buildPreviewWorkspace(frameCount),
      SurfaceStudioWizardStep.save => _SaveStepPanel(
          readModel: widget.readModel,
          generationPlan: _generationPlan,
          presetPlan: surfaceStudioPlanVerticalAtlasPresetAppend(
            catalog: widget.readModel.catalog,
            atlasIdRaw: _atlasId.text,
            atlasDisplayName: _atlasName.text,
            atlasCategoryDraft: _categoryId.text,
            mappingDraft: _columnRoleMappingDraft,
            gridValid: _gridValid,
          ),
          hasWorkCatalogChanges: widget.hasWorkCatalogChanges,
          saveFlowPrepNote: widget.saveFlowPrepNote,
          projectSaveDiskNote: widget.projectSaveDiskNote,
          generationMessage: _lastGenerationMessage,
          presetMessage: _lastPresetMessage,
          onGenerateAnimations: _appendReadyAnimations,
          onCreatePreset: _appendPreset,
          onSaveCatalog: widget.onSurfaceCatalogSavePrep,
          onProjectSave: widget.onRequestProjectSave,
          onResetWorkCatalog: widget.onResetWorkCatalog,
        ),
    };
  }

  Widget _buildPreviewWorkspace(int frameCount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: SurfaceStudioPreviewPanel(
            frameCount: frameCount,
            frameIndex: _previewFrameIndex.clamp(0, frameCount - 1).toInt(),
            playing: _previewPlaying,
            loop: _previewLoop,
            gridVisible: _previewGridVisible,
            previewSize: _previewSize,
            tileWidth: _tileWidthValue,
            tileHeight: _tileHeightValue,
            columnCount: _columnCount,
            assignmentDraft: _assignmentDraft,
            atlasImageBytes: _atlasImageBytes(),
            atlasFallbackMessage: _atlasImageBytes() == null
                ? 'Image source indisponible — aperçu illustratif.'
                : null,
            onPrevious: () {
              setState(() {
                _previewPlaying = false;
                _previewFrameIndex =
                    (_previewFrameIndex - 1).clamp(0, frameCount - 1).toInt();
              });
              _syncPreviewTimer();
            },
            onNext: () {
              setState(() {
                _previewPlaying = false;
                _previewFrameIndex =
                    (_previewFrameIndex + 1).clamp(0, frameCount - 1).toInt();
              });
              _syncPreviewTimer();
            },
            onTogglePlaying: _togglePreviewPlaying,
            onFrameChanged: (value) {
              setState(() {
                _previewPlaying = false;
                _previewFrameIndex = value.clamp(0, frameCount - 1).toInt();
              });
              _syncPreviewTimer();
            },
            onLoopChanged: (value) => setState(() => _previewLoop = value),
            onGridChanged: (value) =>
                setState(() => _previewGridVisible = value),
            onPreviewSizeChanged: (value) =>
                setState(() => _previewSize = value),
          ),
        ),
        const SizedBox(width: SurfaceStudioDesignTokens.gapMd),
        SizedBox(
          width: 430,
          child: _PreviewPlanPanel(
            generationPlan: _generationPlan,
            multiCenterColumns:
                _assignmentDraft.columnsForRole(SurfaceVariantRole.isolated),
            onGenerateAnimations: _appendReadyAnimations,
            message: _lastGenerationMessage,
          ),
        ),
      ],
    );
  }

  Widget? _buildRightDock(int frameCount) {
    if (_currentStep != SurfaceStudioWizardStep.map) {
      return null;
    }
    return _RightDockFrame(
      children: [
        Expanded(
          flex: 3,
          child: SurfaceStudioSchemaPanel(
            collapsed: _rightPanelCollapsed,
            openGroups: _openSchemaGroups,
            assignmentDraft: _assignmentDraft,
            onToggleCollapsed: () {
              setState(() => _rightPanelCollapsed = !_rightPanelCollapsed);
            },
            onToggleGroup: (id) {
              setState(() {
                final next = Set<String>.of(_openSchemaGroups);
                if (!next.add(id)) {
                  next.remove(id);
                }
                _openSchemaGroups = next;
              });
            },
            onDrop: _acceptDrop,
            onClearRole: (role) {
              setState(
                () => _assignmentDraft = _assignmentDraft.clearRole(role),
              );
            },
            onClearColumn: (role, column) {
              setState(
                () => _assignmentDraft =
                    _assignmentDraft.clearColumn(role, column),
              );
            },
          ),
        ),
        const SizedBox(height: SurfaceStudioDesignTokens.gapSm),
        Expanded(
          flex: 2,
          child: SurfaceStudioPreviewPanel(
            frameCount: frameCount,
            frameIndex: _previewFrameIndex.clamp(0, frameCount - 1).toInt(),
            playing: _previewPlaying,
            loop: _previewLoop,
            gridVisible: _previewGridVisible,
            previewSize: _previewSize,
            tileWidth: _tileWidthValue,
            tileHeight: _tileHeightValue,
            columnCount: _columnCount,
            assignmentDraft: _assignmentDraft,
            atlasImageBytes: _atlasImageBytes(),
            atlasFallbackMessage: _atlasImageBytes() == null
                ? 'Image source indisponible — aperçu illustratif.'
                : null,
            onPrevious: () {
              setState(() {
                _previewPlaying = false;
                _previewFrameIndex =
                    (_previewFrameIndex - 1).clamp(0, frameCount - 1).toInt();
              });
              _syncPreviewTimer();
            },
            onNext: () {
              setState(() {
                _previewPlaying = false;
                _previewFrameIndex =
                    (_previewFrameIndex + 1).clamp(0, frameCount - 1).toInt();
              });
              _syncPreviewTimer();
            },
            onTogglePlaying: _togglePreviewPlaying,
            onFrameChanged: (value) {
              setState(() {
                _previewPlaying = false;
                _previewFrameIndex = value.clamp(0, frameCount - 1).toInt();
              });
              _syncPreviewTimer();
            },
            onLoopChanged: (value) => setState(() => _previewLoop = value),
            onGridChanged: (value) =>
                setState(() => _previewGridVisible = value),
            onPreviewSizeChanged: (value) =>
                setState(() => _previewSize = value),
          ),
        ),
      ],
    );
  }
}

class _ImportStepPanel extends StatelessWidget {
  const _ImportStepPanel({
    required this.readModel,
    required this.projectTilesets,
    required this.projectRootPath,
    required this.atlasId,
    required this.atlasName,
    required this.tilesetId,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
    required this.rows,
    required this.sortOrder,
    required this.categoryId,
    required this.layout,
    required this.onLayoutChanged,
    required this.onCreateAtlas,
    required this.onTilesetChanged,
  });

  final SurfaceStudioReadModel readModel;
  final List<ProjectTilesetEntry> projectTilesets;
  final String? projectRootPath;
  final TextEditingController atlasId;
  final TextEditingController atlasName;
  final TextEditingController tilesetId;
  final TextEditingController tileWidth;
  final TextEditingController tileHeight;
  final TextEditingController columns;
  final TextEditingController rows;
  final TextEditingController sortOrder;
  final TextEditingController categoryId;
  final SurfaceAtlasLayout layout;
  final ValueChanged<SurfaceAtlasLayout> onLayoutChanged;
  final VoidCallback onCreateAtlas;
  final ValueChanged<String?> onTilesetChanged;

  @override
  Widget build(BuildContext context) {
    final sorted = sortedTilesetChoices(projectTilesets);
    final resolution = resolveSurfaceStudioAtlasImagePreview(
      projectRootPath: projectRootPath,
      projectTilesets: projectTilesets,
      technicalTilesetId: tilesetId.text,
    );
    final form = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SurfaceStudioAtlasImageSourceBlock(
            hasPicker: sorted.isNotEmpty,
            sortedTilesets: sorted,
            selectedTilesetId: tilesetId.text.isEmpty ? null : tilesetId.text,
            onSelectTilesetId: onTilesetChanged,
            label: SurfaceStudioDesignTokens.textPrimary,
            subtle: SurfaceStudioDesignTokens.textSecondary,
          ),
          const SizedBox(height: 14),
          _Field(
            keyName: 'surfaceStudio.import.atlasId',
            label: 'Identifiant atlas',
            controller: atlasId,
          ),
          _Field(
            keyName: 'surfaceStudio.import.atlasName',
            label: 'Nom atlas',
            controller: atlasName,
          ),
          _Field(
            keyName: 'surfaceStudio.import.tilesetId',
            label: 'Source technique',
            controller: tilesetId,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SmallField(label: 'Tuile W', controller: tileWidth),
              _SmallField(label: 'Tuile H', controller: tileHeight),
              _SmallField(label: 'Colonnes', controller: columns),
              _SmallField(label: 'Frames', controller: rows),
              _SmallField(label: 'Ordre', controller: sortOrder),
            ],
          ),
          const SizedBox(height: 10),
          _Field(
            keyName: 'surfaceStudio.import.categoryId',
            label: 'Catégorie',
            controller: categoryId,
          ),
          const SizedBox(height: 10),
          Material(
            type: MaterialType.transparency,
            child: DropdownButton<SurfaceAtlasLayout>(
              key: const ValueKey('surfaceStudio.import.layout'),
              isExpanded: true,
              value: layout,
              dropdownColor: SurfaceStudioDesignTokens.backgroundElevated,
              style: const TextStyle(
                color: SurfaceStudioDesignTokens.textPrimary,
              ),
              items: const [
                DropdownMenuItem(
                  value: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
                  child: Text('Colonnes = rôles'),
                ),
                DropdownMenuItem(
                  value: SurfaceAtlasLayout.grid,
                  child: Text('Grille libre'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  onLayoutChanged(value);
                }
              },
            ),
          ),
          const SizedBox(height: 14),
          CupertinoButton(
            key: const ValueKey('surfaceStudio.import.createAtlas'),
            color: SurfaceStudioDesignTokens.accentGoldSoft,
            onPressed: onCreateAtlas,
            child: Text(
              readModel.atlases.isEmpty
                  ? 'Créer l’atlas de travail'
                  : 'Appliquer au catalogue de travail',
            ),
          ),
        ],
      ),
    );
    final preview = SurfaceStudioAtlasImagePreview(
      resolution: resolution,
      label: SurfaceStudioDesignTokens.textPrimary,
      subtle: SurfaceStudioDesignTokens.textSecondary,
      draftTileWidth: int.tryParse(tileWidth.text),
      draftTileHeight: int.tryParse(tileHeight.text),
      draftColumns: int.tryParse(columns.text),
      draftRows: int.tryParse(rows.text),
      draftLayoutLabel: 'Colonnes → rôles',
      largeFormat: true,
    );
    return _PanelFrame(
      keyName: 'surfaceStudio.import.panel',
      title: 'Importer',
      subtitle: 'Choisissez une source réelle et préparez le brouillon atlas.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 720) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  form,
                  const SizedBox(height: 16),
                  SizedBox(height: 340, child: preview),
                ],
              ),
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: form),
              const SizedBox(width: 16),
              Expanded(child: preview),
            ],
          );
        },
      ),
    );
  }
}

class _SliceStepPanel extends StatelessWidget {
  const _SliceStepPanel({
    required this.projectTilesets,
    required this.projectRootPath,
    required this.atlasId,
    required this.atlasName,
    required this.tilesetId,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
    required this.rows,
    required this.layout,
    required this.onChanged,
    required this.onApplyGrid,
    required this.onResetGrid,
  });

  final List<ProjectTilesetEntry> projectTilesets;
  final String? projectRootPath;
  final TextEditingController atlasId;
  final TextEditingController atlasName;
  final TextEditingController tilesetId;
  final TextEditingController tileWidth;
  final TextEditingController tileHeight;
  final TextEditingController columns;
  final TextEditingController rows;
  final SurfaceAtlasLayout layout;
  final VoidCallback onChanged;
  final VoidCallback onApplyGrid;
  final VoidCallback onResetGrid;

  @override
  Widget build(BuildContext context) {
    final resolution = resolveSurfaceStudioAtlasImagePreview(
      projectRootPath: projectRootPath,
      projectTilesets: projectTilesets,
      technicalTilesetId: tilesetId.text,
    );
    return _PanelFrame(
      keyName: 'surfaceStudio.slice.panel',
      title: 'Découper',
      subtitle: 'Ajustez la grille qui alimentera le mapping et la génération.',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: SurfaceStudioAtlasImagePreview(
              resolution: resolution,
              label: SurfaceStudioDesignTokens.textPrimary,
              subtle: SurfaceStudioDesignTokens.textSecondary,
              draftTileWidth: int.tryParse(tileWidth.text),
              draftTileHeight: int.tryParse(tileHeight.text),
              draftColumns: int.tryParse(columns.text),
              draftRows: int.tryParse(rows.text),
              draftLayoutLabel: layout.name,
              largeFormat: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    atlasName.text.isEmpty ? atlasId.text : atlasName.text,
                    style: const TextStyle(
                      color: SurfaceStudioDesignTokens.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _SmallField(
                        label: 'Tuile W',
                        controller: tileWidth,
                        onChanged: (_) => onChanged(),
                      ),
                      _SmallField(
                        label: 'Tuile H',
                        controller: tileHeight,
                        onChanged: (_) => onChanged(),
                      ),
                      _SmallField(
                        label: 'Colonnes',
                        controller: columns,
                        onChanged: (_) => onChanged(),
                      ),
                      _SmallField(
                        label: 'Frames',
                        controller: rows,
                        onChanged: (_) => onChanged(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SurfaceStudioAtlasGridPreview(
                    sourceLabel: tilesetId.text,
                    tileWidth: int.tryParse(tileWidth.text),
                    tileHeight: int.tryParse(tileHeight.text),
                    columns: int.tryParse(columns.text),
                    rows: int.tryParse(rows.text),
                    layoutLabel: layout.name,
                  ),
                  const SizedBox(height: 14),
                  CupertinoButton(
                    color: SurfaceStudioDesignTokens.accentTealSoft,
                    onPressed: onApplyGrid,
                    child: const Text('Appliquer la grille'),
                  ),
                  const SizedBox(height: 8),
                  CupertinoButton(
                    onPressed: onResetGrid,
                    child: const Text('Réinitialiser'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPlanPanel extends StatelessWidget {
  const _PreviewPlanPanel({
    required this.generationPlan,
    required this.multiCenterColumns,
    required this.onGenerateAnimations,
    required this.message,
  });

  final SurfaceStudioVerticalAtlasAnimationGenerationPlan generationPlan;
  final List<int> multiCenterColumns;
  final VoidCallback onGenerateAnimations;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final summary = generationPlan.summary;
    return _PanelFrame(
      keyName: 'surfaceStudio.previewPlan.panel',
      title: 'Prévisualiser',
      subtitle: 'Plan réel de génération depuis le mapping courant.',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MetricRow(
              metrics: {
                'Assignées': '${summary.assignedColumnCount}',
                'Prêtes': '${summary.readyAnimationCount}',
                'À corriger': '${summary.errorAnimationCount}',
                'Frame': '${summary.durationMsPerFrame} ms',
              },
            ),
            if (multiCenterColumns.length > 1) ...[
              const SizedBox(height: 10),
              const _WarningBox(
                text:
                    'Plein contient plusieurs colonnes. V2.1 conserve l’UX multi-colonnes, mais la génération réelle utilise la première colonne tant qu’un modèle de variantes multiples n’existe pas.',
              ),
            ],
            const SizedBox(height: 14),
            CupertinoButton(
              key: const ValueKey('surfaceStudio.preview.generateAnimations'),
              color: SurfaceStudioDesignTokens.accentTealSoft,
              onPressed:
                  summary.readyAnimationCount > 0 ? onGenerateAnimations : null,
              child: const Text('Générer les animations prêtes'),
            ),
            if (message != null) ...[
              const SizedBox(height: 10),
              Text(
                message!,
                style: const TextStyle(
                  color: SurfaceStudioDesignTokens.accentTeal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 14),
            for (final item in generationPlan.items) _PlanItemRow(item: item),
          ],
        ),
      ),
    );
  }
}

class _SaveStepPanel extends StatelessWidget {
  const _SaveStepPanel({
    required this.readModel,
    required this.generationPlan,
    required this.presetPlan,
    required this.hasWorkCatalogChanges,
    required this.saveFlowPrepNote,
    required this.projectSaveDiskNote,
    required this.generationMessage,
    required this.presetMessage,
    required this.onGenerateAnimations,
    required this.onCreatePreset,
    required this.onSaveCatalog,
    required this.onProjectSave,
    required this.onResetWorkCatalog,
  });

  final SurfaceStudioReadModel readModel;
  final SurfaceStudioVerticalAtlasAnimationGenerationPlan generationPlan;
  final SurfaceStudioVerticalAtlasPresetAppendPlan presetPlan;
  final bool hasWorkCatalogChanges;
  final String? saveFlowPrepNote;
  final String? projectSaveDiskNote;
  final String? generationMessage;
  final String? presetMessage;
  final VoidCallback onGenerateAnimations;
  final VoidCallback onCreatePreset;
  final VoidCallback? onSaveCatalog;
  final Future<void> Function()? onProjectSave;
  final VoidCallback? onResetWorkCatalog;

  @override
  Widget build(BuildContext context) {
    return _PanelFrame(
      keyName: 'surfaceStudio.save.panel',
      title: 'Enregistrer',
      subtitle: 'Générez les artefacts Surface, puis préparez la sauvegarde.',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MetricRow(
              metrics: {
                'Atlas': '${readModel.summary.atlasCount}',
                'Animations': '${readModel.summary.animationCount}',
                'Surfaces': '${readModel.summary.presetCount}',
                'Dirty': hasWorkCatalogChanges ? 'oui' : 'non',
              },
            ),
            const SizedBox(height: 14),
            CupertinoButton(
              key: const ValueKey('surfaceStudio.save.generateAnimations'),
              color: SurfaceStudioDesignTokens.accentTealSoft,
              onPressed: generationPlan.summary.readyAnimationCount > 0
                  ? onGenerateAnimations
                  : null,
              child: const Text('Générer les animations'),
            ),
            const SizedBox(height: 8),
            CupertinoButton(
              key: const ValueKey('surfaceStudio.save.createPreset'),
              color: SurfaceStudioDesignTokens.accentGoldSoft,
              onPressed: presetPlan.canCreate ? onCreatePreset : null,
              child: const Text('Créer la surface peignable'),
            ),
            const SizedBox(height: 8),
            CupertinoButton(
              key: const ValueKey('surfaceStudio.action.saveCatalog'),
              onPressed: hasWorkCatalogChanges ? onSaveCatalog : null,
              child: const Text('Préparer la sauvegarde du catalogue'),
            ),
            if (onProjectSave != null) ...[
              const SizedBox(height: 8),
              CupertinoButton(
                key: const ValueKey('surfaceStudio.save.project'),
                onPressed: onProjectSave,
                child: const Text('Sauvegarder le projet via le flux existant'),
              ),
            ],
            if (onResetWorkCatalog != null) ...[
              const SizedBox(height: 8),
              CupertinoButton(
                key: const ValueKey('surfaceStudio.save.resetWorkCatalog'),
                onPressed: onResetWorkCatalog,
                child: const Text('Réinitialiser le catalogue de travail'),
              ),
            ],
            for (final message in [
              generationMessage,
              presetMessage,
              saveFlowPrepNote,
              projectSaveDiskNote,
            ])
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(
                    color: SurfaceStudioDesignTokens.accentTeal,
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

class _RightDockFrame extends StatelessWidget {
  const _RightDockFrame({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(children: children);
  }
}

class _PanelFrame extends StatelessWidget {
  const _PanelFrame({
    required this.keyName,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String keyName;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(keyName),
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundPanel,
        borderRadius:
            BorderRadius.circular(SurfaceStudioDesignTokens.panelRadius),
        border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: SurfaceStudioDesignTokens.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: SurfaceStudioDesignTokens.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.keyName,
    required this.label,
    required this.controller,
  });

  final String keyName;
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        type: MaterialType.transparency,
        child: TextField(
          key: ValueKey(keyName),
          controller: controller,
          style: const TextStyle(color: SurfaceStudioDesignTokens.textPrimary),
          decoration: _fieldDecoration(label),
        ),
      ),
    );
  }
}

class _SmallField extends StatelessWidget {
  const _SmallField({
    required this.label,
    required this.controller,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: Material(
        type: MaterialType.transparency,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(color: SurfaceStudioDesignTokens.textPrimary),
          decoration: _fieldDecoration(label),
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: SurfaceStudioDesignTokens.textSecondary),
    filled: true,
    fillColor: SurfaceStudioDesignTokens.backgroundElevated,
    enabledBorder: OutlineInputBorder(
      borderSide:
          const BorderSide(color: SurfaceStudioDesignTokens.borderSubtle),
      borderRadius: BorderRadius.circular(9),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: SurfaceStudioDesignTokens.accentGold),
      borderRadius: BorderRadius.circular(9),
    ),
  );
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.metrics});

  final Map<String, String> metrics;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final metric in metrics.entries)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: SurfaceStudioDesignTokens.backgroundElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
            ),
            child: Text(
              '${metric.key}  ${metric.value}',
              style: const TextStyle(
                color: SurfaceStudioDesignTokens.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _WarningBox extends StatelessWidget {
  const _WarningBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.accentGoldSoft.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SurfaceStudioDesignTokens.accentGold),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: SurfaceStudioDesignTokens.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PlanItemRow extends StatelessWidget {
  const _PlanItemRow({required this.item});

  final SurfaceStudioVerticalAtlasAnimationGenerationItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: item.isReady
              ? SurfaceStudioDesignTokens.accentTeal.withValues(alpha: 0.5)
              : SurfaceStudioDesignTokens.borderSubtle,
        ),
      ),
      child: Text(
        '${SurfaceStudioRoleLabels.labelForRole(item.role)} · colonne ${item.columnIndex + 1} · ${item.isReady ? 'prête' : item.problems.join(', ')}',
        style: const TextStyle(
          color: SurfaceStudioDesignTokens.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusToast extends StatelessWidget {
  const _StatusToast({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: SurfaceStudioDesignTokens.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SuggestionReviewScrim extends StatelessWidget {
  const _SuggestionReviewScrim({
    required this.result,
    required this.mistralKeyConfigured,
    required this.aiConfirmationOpen,
    required this.running,
    required this.progressMessage,
    required this.onCancel,
    required this.onRunLocal,
    required this.onRequestAi,
    required this.onCancelAi,
    required this.onConfirmAi,
    required this.onCompare,
    required this.onApplySuggestion,
    required this.onApplyReliable,
    required this.onApplyAll,
  });

  final SurfaceStudioMappingSuggestionResult result;
  final bool mistralKeyConfigured;
  final bool aiConfirmationOpen;
  final bool running;
  final String? progressMessage;
  final VoidCallback onCancel;
  final VoidCallback onRunLocal;
  final VoidCallback onRequestAi;
  final VoidCallback onCancelAi;
  final VoidCallback onConfirmAi;
  final VoidCallback onCompare;
  final ValueChanged<SurfaceStudioRoleSuggestion> onApplySuggestion;
  final VoidCallback onApplyReliable;
  final VoidCallback onApplyAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x990B1020),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.all(18),
      child: Container(
        key: const ValueKey('surfaceStudio.suggestion.review'),
        width: 520,
        decoration: BoxDecoration(
          color: SurfaceStudioDesignTokens.backgroundPanel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Suggestions détectées',
              style: TextStyle(
                color: SurfaceStudioDesignTokens.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Source : ${_sourceLabel(result.source)}',
              style: const TextStyle(
                color: SurfaceStudioDesignTokens.accentTeal,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final warning in result.warnings) ...[
                      _WarningBox(text: warning),
                      const SizedBox(height: 8),
                    ],
                    for (final suggestion in result.suggestions)
                      _SuggestionRow(
                        suggestion: suggestion,
                        onApply: () => onApplySuggestion(suggestion),
                      ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SurfaceStudioDesignTokens.backgroundElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: SurfaceStudioDesignTokens.borderSubtle,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Analyse IA Mistral',
                            style: TextStyle(
                              color: SurfaceStudioDesignTokens.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            mistralKeyConfigured
                                ? 'Clé Mistral configurée.'
                                : 'Clé Mistral absente : Projet → Paramètres (IA) ou MISTRAL_API_KEY',
                            style: const TextStyle(
                              color: SurfaceStudioDesignTokens.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'L’analyse IA peut envoyer l’image de l’atlas au fournisseur configuré. Rien n’est envoyé sans confirmation.',
                            style: TextStyle(
                              color: SurfaceStudioDesignTokens.textMuted,
                              height: 1.3,
                            ),
                          ),
                          if (running) ...[
                            const SizedBox(height: 10),
                            Container(
                              key: const ValueKey(
                                'surfaceStudio.suggestion.mistralProgress',
                              ),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: SurfaceStudioDesignTokens.backgroundDeep,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      SurfaceStudioDesignTokens.accentGoldSoft,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const CupertinoActivityIndicator(radius: 10),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Mistral analyse l’atlas avec un niveau de réflexion élevé. Cela peut prendre quelques secondes.',
                                          style: TextStyle(
                                            color: SurfaceStudioDesignTokens
                                                .textSecondary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          progressMessage ??
                                              'Analyse visuelle approfondie…',
                                          style: const TextStyle(
                                            color: SurfaceStudioDesignTokens
                                                .accentGold,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              CupertinoButton(
                                key: const ValueKey(
                                  'surfaceStudio.suggestion.local',
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                color: SurfaceStudioDesignTokens.accentTealSoft,
                                onPressed: running ? null : onRunLocal,
                                child: const Text('Analyse locale'),
                              ),
                              CupertinoButton(
                                key: const ValueKey(
                                  'surfaceStudio.suggestion.mistral',
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                color: mistralKeyConfigured
                                    ? SurfaceStudioDesignTokens.accentGoldSoft
                                    : SurfaceStudioDesignTokens.borderSubtle,
                                onPressed: running || !mistralKeyConfigured
                                    ? null
                                    : onRequestAi,
                                child: Text(
                                  running
                                      ? 'Analyse IA...'
                                      : 'Analyse IA Mistral',
                                ),
                              ),
                              CupertinoButton(
                                key: const ValueKey(
                                  'surfaceStudio.suggestion.compare',
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                color: SurfaceStudioDesignTokens
                                    .backgroundPanelAlt,
                                onPressed: running || !mistralKeyConfigured
                                    ? null
                                    : onCompare,
                                child: const Text('Comparer local + IA'),
                              ),
                            ],
                          ),
                          if (aiConfirmationOpen) ...[
                            const SizedBox(height: 10),
                            const _WarningBox(
                              text:
                                  'Confirmez l’envoi de l’image atlas à Mistral. Aucune suggestion ne sera appliquée automatiquement.',
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                CupertinoButton(
                                  key: const ValueKey(
                                    'surfaceStudio.suggestion.confirmAi',
                                  ),
                                  color:
                                      SurfaceStudioDesignTokens.accentGoldSoft,
                                  onPressed: onConfirmAi,
                                  child: const Text('Confirmer l’analyse IA'),
                                ),
                                CupertinoButton(
                                  onPressed: onCancelAi,
                                  child: const Text('Annuler l’analyse IA'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 8,
              children: [
                CupertinoButton(
                  onPressed: onCancel,
                  child: const Text('Annuler'),
                ),
                CupertinoButton(
                  color: SurfaceStudioDesignTokens.accentTealSoft,
                  onPressed: onApplyReliable,
                  child: const Text('Appliquer les suggestions fiables'),
                ),
                CupertinoButton(
                  color: SurfaceStudioDesignTokens.accentGoldSoft,
                  onPressed: onApplyAll,
                  child: const Text('Tout appliquer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _sourceLabel(SurfaceStudioMappingSuggestionSource source) {
    return switch (source) {
      SurfaceStudioMappingSuggestionSource.local => 'Local',
      SurfaceStudioMappingSuggestionSource.mistral => 'Mistral',
      SurfaceStudioMappingSuggestionSource.merged => 'Fusion',
    };
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.suggestion,
    required this.onApply,
  });

  final SurfaceStudioRoleSuggestion suggestion;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            SurfaceStudioRoleLabels.labelForRole(suggestion.role),
            style: const TextStyle(
              color: SurfaceStudioDesignTokens.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Colonnes : ${suggestion.columns.join(', ')} · confiance : ${suggestion.confidence.name}',
            style: const TextStyle(
              color: SurfaceStudioDesignTokens.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            suggestion.reason,
            style: const TextStyle(
              color: SurfaceStudioDesignTokens.textMuted,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: CupertinoButton(
              key: ValueKey(
                'surfaceStudio.suggestion.accept.${suggestion.role.name}',
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: SurfaceStudioDesignTokens.accentTealSoft,
              onPressed: onApply,
              child: const Text('Accepter'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvancedDrawerScrim extends StatelessWidget {
  const _AdvancedDrawerScrim({
    required this.child,
    required this.onClose,
  });

  final Widget child;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x770B1020),
      alignment: Alignment.centerRight,
      child: Container(
        key: const ValueKey('surfaceStudio.advanced.drawer'),
        width: 620,
        margin: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: SurfaceStudioDesignTokens.backgroundPanel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Catalogue & diagnostics',
                      style: TextStyle(
                        color: SurfaceStudioDesignTokens.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size.square(36),
                    onPressed: onClose,
                    child: const Icon(
                      CupertinoIcons.xmark,
                      color: SurfaceStudioDesignTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
