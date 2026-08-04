import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';
import '../../../application/authoring_api/editor_receipt_presenter.dart';
import '../application/smart_tile_atlas_image_loader.dart';
import '../application/smart_tile_atlas_selection.dart';
import '../application/smart_tile_authoring_controller.dart';
import '../application/smart_tile_connection_profile.dart';
import '../application/smart_tile_draft_persistence_state.dart';
import '../application/smart_tile_form_projection.dart';
import '../application/smart_tile_grid_detector.dart';
import '../application/smart_tile_guide.dart';
import '../application/smart_tile_guide_placement.dart';
import '../application/smart_tile_pattern_authoring.dart';
import '../application/smart_tile_publication_service.dart';
import '../application/smart_tile_studio_library.dart';
import '../application/smart_tile_studio_launch_context.dart';
import '../application/smart_tile_studio_session.dart';
import '../application/smart_tile_source_asset_import_service.dart';
import '../application/smart_tile_tiled_wang_import_service.dart';
import '../application/smart_tile_test_layer_controller.dart';
import 'smart_tile_guide_diagram.dart';
import 'smart_tile_guide_overlay_painter.dart';
import 'smart_tile_pattern_editor.dart';
import 'smart_tile_tiled_wang_import_editor.dart';
import 'smart_tiles_studio_shell.dart';
import 'smart_tiles_studio_stage_header.dart';
import 'stages/smart_tile_grid_stage.dart';
import 'stages/smart_tile_image_stage.dart';
import 'stages/smart_tile_connections_stage.dart';
import 'stages/smart_tile_forms_stage.dart';
import 'stages/smart_tile_material_picker.dart';
import 'stages/smart_tile_materials_stage.dart';
import 'stages/smart_tile_publish_stage.dart';
import 'stages/smart_tile_test_stage.dart';
import 'stages/smart_tile_usage_stage.dart';
import 'stages/smart_tile_variants_stage.dart';

enum SmartTilesStudioTab { atlas, rules, animations, testBench, validation }

enum _LibraryUsageFilter { all, terrain, path, forestSurface }

class SmartTilesStudioPanel extends StatefulWidget {
  const SmartTilesStudioPanel({
    super.key,
    required this.manifest,
    this.projectRootPath,
    this.imageLoader = const FileSmartTileAtlasImageLoader(),
    this.launchContext = const SmartTilesStudioLaunchContext.library(),
    this.isCapturedMapAvailable = false,
    this.capturedMap,
    this.canonicalDraft,
    this.persistenceState,
    this.onDraftChanged,
    this.onDraftFlush,
    this.onImportProjectImage,
    this.onPickTiledWangSource,
    this.onImportTiledWang,
    this.publicationService,
    this.onPublicationApplied,
    this.onAddPresetToCapturedMap,
    this.onUpsertPattern,
  });

  final ProjectManifest manifest;
  final String? projectRootPath;
  final SmartTileAtlasImageLoader imageLoader;
  final SmartTilesStudioLaunchContext launchContext;
  final bool isCapturedMapAvailable;
  final MapData? capturedMap;
  final ProjectSmartTileAuthoringDraft? canonicalDraft;
  final SmartTileDraftPersistenceState? persistenceState;
  final ValueChanged<ProjectSmartTileAuthoringDraft>? onDraftChanged;
  final Future<void> Function()? onDraftFlush;
  final Future<SmartTileSourceImportResult?> Function()? onImportProjectImage;
  final Future<SmartTileTiledWangSource?> Function()? onPickTiledWangSource;
  final Future<SmartTileTiledWangImportResult> Function(
    SmartTileTiledWangSource source,
    List<TiledWangSetSelection> selections,
  )? onImportTiledWang;
  final SmartTilePublicationService? publicationService;
  final Future<void> Function(SmartTilePublicationResult result)?
      onPublicationApplied;
  final Future<bool> Function(ProjectSmartTilePreset preset)?
      onAddPresetToCapturedMap;
  final Future<void> Function(ProjectSmartTilePattern pattern)? onUpsertPattern;

  @override
  State<SmartTilesStudioPanel> createState() => _SmartTilesStudioPanelState();
}

class _SmartTilesStudioPanelState extends State<SmartTilesStudioPanel> {
  final SmartTileStudioSession _session = SmartTileStudioSession();
  final SmartTileGridDetector _gridDetector = const SmartTileGridDetector();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _newMaterialNameController =
      TextEditingController();
  final TextEditingController _animationNameController =
      TextEditingController();
  final TextEditingController _animationDurationController =
      TextEditingController(text: '180');
  final TextEditingController _publicationLayerIdController =
      TextEditingController();
  final TextEditingController _publicationLayerNameController =
      TextEditingController();
  final Map<String, TextEditingController> _gridControllers =
      <String, TextEditingController>{};
  SmartTileAuthoringController _authoring =
      SmartTileAuthoringController.blank();

  SmartTilesStudioTab _tab = SmartTilesStudioTab.atlas;
  _LibraryUsageFilter _usageFilter = _LibraryUsageFilter.all;
  String _query = '';
  String? _selectedItemKey;
  String? _resumedDraftId;
  int? _selectedMask;
  String? _selectedTransitionCaseId;
  SmartTileFrameRef? _lastMappedFrame;
  SmartTileFrameRef? _pendingAtlasFrame;
  SmartTileAtlasSelectionMode _atlasSelectionMode =
      SmartTileAtlasSelectionMode.singleCell;
  GridPos? _atlasSelectionStart;
  List<SmartTileFrameRef> _animationFrames = const <SmartTileFrameRef>[];
  String? _lastCandidateId;
  SmartTileRenderChannel _selectedRenderChannel = SmartTileRenderChannel.ground;
  SmartTileGuidePlacementResult? _guidePlacement;
  int? _correctionNumber;
  String? _placementMessage;
  String? _draftMessage;
  String? _focusedRuleId;
  int? _focusedMask;
  String? _selectedSourceTilesetId;
  String? _selectedRegisteredAtlasId;
  SmartTileAtlasImageLoadResult? _sourceImageResult;
  bool _isLoadingSourceImage = false;
  bool _isImportingSourceImage = false;
  int _sourceLoadRevision = 0;
  List<SmartTileGridCandidate> _gridProposals =
      const <SmartTileGridCandidate>[];
  int _selectedGridProposal = 0;
  SmartTileGridGeometry? _pendingGridGeometry;
  SmartTileConnectionProfileId? _selectedConnectionProfileId;
  SmartTileTopology? _customConnectionTopology;
  SmartTileTestLayerController? _testLabController;
  SmartTileLabTool _testLabTool = SmartTileLabTool.pencil;
  SmartTileTransformProposal? _transformProposal;
  SmartTilePublicationTargetKind _publicationTargetKind =
      SmartTilePublicationTargetKind.library;
  SmartTilePublicationPlan? _publicationPlan;
  bool _publicationBusy = false;
  bool _publicationApplied = false;
  bool _addingSelectedPreset = false;
  String? _publicationErrorCode;
  String? _publicationErrorMessage;
  ProjectSmartTilePattern? _editingPattern;
  String? _newPatternId;
  bool _patternSaving = false;
  String? _patternError;
  SmartTileTiledWangSource? _tiledWangSource;
  bool _tiledWangPicking = false;
  bool _tiledWangImporting = false;
  String? _tiledWangError;

  @override
  void initState() {
    super.initState();
    final items = buildSmartTileStudioLibrary(widget.manifest);
    _selectedItemKey = items.isEmpty ? null : items.first.key;
  }

  @override
  void didUpdateWidget(covariant SmartTilesStudioPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.manifest != widget.manifest) {
      _testLabController = null;
      final keys = buildSmartTileStudioLibrary(widget.manifest)
          .map((item) => item.key)
          .toSet();
      if (!keys.contains(_selectedItemKey)) {
        _selectedItemKey = keys.firstOrNull;
      }
      if (!widget.manifest.tilesets
          .any((tileset) => tileset.id == _selectedSourceTilesetId)) {
        _clearSourceImageSelection();
      }
      if (!widget.manifest.smartTileCatalog.atlases
          .any((atlas) => atlas.id == _selectedRegisteredAtlasId)) {
        _selectedRegisteredAtlasId = null;
      }
    }
    if (oldWidget.projectRootPath != widget.projectRootPath) {
      _clearSourceImageSelection();
    }
    final canonicalDraft = widget.canonicalDraft;
    if (canonicalDraft != null &&
        canonicalDraft != oldWidget.canonicalDraft &&
        canonicalDraft.targetPresetId == _authoring.state.id) {
      _authoring.replaceFromCanonicalDraft(
        canonicalDraft,
        catalogMaterials: widget.manifest.smartTileCatalog.materials,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newMaterialNameController.dispose();
    _animationNameController.dispose();
    _animationDurationController.dispose();
    _publicationLayerIdController.dispose();
    _publicationLayerNameController.dispose();
    for (final controller in _gridControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final items = buildSmartTileStudioLibrary(widget.manifest);
    final visibleItems = _filterItems(items);
    final selectedItem =
        items.where((item) => item.key == _selectedItemKey).firstOrNull;

    return Material(
      type: MaterialType.transparency,
      child: ColoredBox(
        color: colors.backgroundApp,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SmartTilesStudioShell(
            library: _buildLibrary(visibleItems),
            workbench: _buildWorkbench(selectedItem),
            inspector: _buildInspector(selectedItem),
          ),
        ),
      ),
    );
  }

  Widget _buildLibrary(List<SmartTileLibraryItem> items) {
    return PokeMapPanel(
      expandChild: true,
      padding: const EdgeInsets.all(12),
      header: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: PokeMapSectionHeader(
          title: 'Bibliothèque',
          description: 'Terrain, chemins et surfaces forestières',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: <Widget>[
              PokeMapIconButton(
                key: const Key('smart-tiles-import-tiled-wang'),
                onPressed: widget.onPickTiledWangSource == null ||
                        widget.onImportTiledWang == null ||
                        _tiledWangPicking ||
                        _tiledWangImporting
                    ? null
                    : () => unawaited(_pickTiledWangSource()),
                tooltip: 'Importer un TSX / Wang Set',
                semanticLabel: 'Importer un TSX / Wang Set',
                variant: PokeMapIconButtonVariant.soft,
                icon: const Icon(CupertinoIcons.arrow_down_doc, size: 15),
              ),
              PokeMapIconButton(
                key: const Key('smart-tiles-new-pattern'),
                onPressed:
                    widget.onUpsertPattern == null ? null : _startNewPattern,
                tooltip: 'Nouveau motif réutilisable',
                semanticLabel: 'Nouveau motif réutilisable',
                variant: PokeMapIconButtonVariant.soft,
                icon: const Icon(CupertinoIcons.square_grid_2x2, size: 15),
              ),
              PokeMapIconButton(
                key: const Key('smart-tiles-new-preset'),
                onPressed: _startDraft,
                tooltip: 'Nouveau Smart Tile',
                semanticLabel: 'Nouveau Smart Tile',
                variant: PokeMapIconButtonVariant.soft,
                icon: const Icon(CupertinoIcons.add, size: 15),
              ),
            ],
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PokeMapSearchField(
            controller: _searchController,
            hintText: 'Rechercher un preset…',
            onChanged: (value) => setState(() => _query = value),
          ),
          if (_tiledWangError != null && _tiledWangSource == null) ...[
            const SizedBox(height: 10),
            PokeMapDiagnosticCallout(
              key: const Key('smart-tiles-tiled-wang-picker-error'),
              severity: PokeMapDiagnosticSeverity.error,
              message: _tiledWangError!,
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _LibraryUsageFilter.values.map((filter) {
              return PokeMapButton(
                key: Key('smart-tiles-filter-${filter.name}'),
                onPressed: () => setState(() => _usageFilter = filter),
                variant: PokeMapButtonVariant.ghost,
                size: PokeMapButtonSize.small,
                isSelected: _usageFilter == filter,
                child: Text(_usageFilterLabel(filter)),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: items.isEmpty
                ? const PokeMapEmptyState(
                    title: 'Aucun Smart Tile',
                    description:
                        'Créez un preset natif ou recherchez un preset historique.',
                    icon: Icon(CupertinoIcons.square_grid_3x2),
                    compact: true,
                  )
                : ListView.separated(
                    key: const Key('smart-tiles-library-list'),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return PokeMapAssetCard(
                        key: Key('smart-tiles-library-item-${item.key}'),
                        thumbnail: Icon(
                          item.isPattern
                              ? CupertinoIcons.square_grid_2x2
                              : CupertinoIcons.square_grid_3x2,
                          size: 20,
                        ),
                        label: item.name,
                        description: '${item.usageLabel} • ${item.statusLabel}',
                        onPressed: item.isResumableDraft
                            ? () =>
                                unawaited(_resumeDraft(item.canonicalDraft!))
                            : () => setState(() {
                                  _session.cancelDraft();
                                  _editingPattern = null;
                                  _newPatternId = null;
                                  _patternError = null;
                                  _tiledWangSource = null;
                                  _tiledWangError = null;
                                  _selectedItemKey = item.key;
                                  _focusedRuleId = null;
                                  _focusedMask = null;
                                  _testLabController = null;
                                  _testLabTool = SmartTileLabTool.pencil;
                                }),
                        selected: !_session.state.isCreating &&
                            _selectedItemKey == item.key,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkbench(SmartTileLibraryItem? selectedItem) {
    final isEditingPattern = _editingPattern != null || _newPatternId != null;
    final isImportingTiledWang = _tiledWangSource != null;
    return PokeMapPanel(
      expandChild: true,
      padding: EdgeInsets.zero,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (_session.state.isCreating)
              SmartTilesStudioStageHeader(
                step: _session.state.wizardStep,
                launchContext: widget.launchContext,
                persistenceState: widget.persistenceState,
              )
            else if (!isEditingPattern && !isImportingTiledWang)
              PokeMapSectionHeader(
                title: 'Smart Tiles Studio',
                description: selectedItem?.name ??
                    'Sélectionnez un preset dans la bibliothèque.',
              ),
            if (!_session.state.isCreating &&
                !isEditingPattern &&
                !isImportingTiledWang) ...[
              const SizedBox(height: 8),
              if (selectedItem?.isPattern != true) _buildTabs(),
            ],
          ],
        ),
      ),
      child: isImportingTiledWang
          ? SmartTileTiledWangImportEditor(
              source: _tiledWangSource!,
              isImporting: _tiledWangImporting,
              externalError: _tiledWangError,
              onCancel: _cancelTiledWangImport,
              onImport: _importTiledWang,
            )
          : _session.state.isCreating
              ? _buildWizard()
              : isEditingPattern
                  ? SmartTilePatternEditor(
                      key: ValueKey<String>(
                        'smart-tile-pattern-editor-${_editingPattern?.id ?? _newPatternId}',
                      ),
                      manifest: widget.manifest,
                      projectRootPath: widget.projectRootPath,
                      patternId: _editingPattern?.id ?? _newPatternId!,
                      imageLoader: widget.imageLoader,
                      initialPattern: _editingPattern,
                      isSaving: _patternSaving,
                      externalError: _patternError,
                      onCancel: _cancelPatternEditing,
                      onSave: _savePattern,
                    )
                  : _buildSelectedTab(selectedItem),
    );
  }

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: SmartTilesStudioTab.values.map((tab) {
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: PokeMapButton(
              key: Key('smart-tiles-tab-${tab.name}'),
              onPressed: () => setState(() => _tab = tab),
              variant: PokeMapButtonVariant.ghost,
              size: PokeMapButtonSize.small,
              isSelected: _tab == tab,
              child: Text(_tabLabel(tab)),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  Widget _buildSelectedTab(SmartTileLibraryItem? selectedItem) {
    if (selectedItem == null) {
      return const PokeMapEmptyState(
        title: 'Aucun preset sélectionné',
        description: 'La bibliothèque reste disponible en permanence à gauche.',
        icon: Icon(CupertinoIcons.square_grid_3x2),
      );
    }
    if (selectedItem.pattern case final pattern?) {
      return _buildPatternOverview(pattern);
    }
    return switch (_tab) {
      SmartTilesStudioTab.atlas => _buildAtlasTab(selectedItem),
      SmartTilesStudioTab.rules => _buildRulesTab(selectedItem),
      SmartTilesStudioTab.animations => _buildAnimationsTab(selectedItem),
      SmartTilesStudioTab.testBench => _buildTestBenchTab(selectedItem),
      SmartTilesStudioTab.validation => _buildValidationTab(selectedItem),
    };
  }

  Widget _buildPatternOverview(ProjectSmartTilePattern pattern) {
    final projection = projectSmartTilePatternAtlasSelection(pattern);
    final atlas = projection == null
        ? null
        : widget.manifest.smartTileCatalog.atlases
            .where((candidate) => candidate.id == projection.atlasId)
            .firstOrNull;
    final canEdit = projection != null &&
        atlas != null &&
        widget.onUpsertPattern != null &&
        !_patternSaving;
    return ListView(
      key: const Key('smart-tiles-pattern-overview'),
      padding: const EdgeInsets.all(18),
      children: <Widget>[
        PokeMapSectionHeader(
          title: pattern.name,
          description:
              'Motif prêt à être sélectionné dans la palette de peinture Monde.',
          trailing: PokeMapBadge(
            label: pattern.repeatMode == SmartTilePatternRepeatMode.stamp
                ? 'Tampon'
                : 'Répétable',
            variant: PokeMapBadgeVariant.info,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            PokeMapBadge(
              label: '${pattern.width} × ${pattern.height} cellules',
              variant: PokeMapBadgeVariant.neutral,
            ),
            PokeMapBadge(
              label: 'Ancrage ${pattern.anchorX + 1},${pattern.anchorY + 1}',
              variant: PokeMapBadgeVariant.neutral,
            ),
            if (atlas != null)
              PokeMapBadge(
                label: atlas.name,
                variant: PokeMapBadgeVariant.neutral,
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (projection == null)
          const PokeMapEmptyState(
            title: 'Motif avancé en lecture seule',
            description:
                'Ce motif contient plusieurs couches, animations ou collisions. Le Studio le conserve sans l’aplatir.',
            icon: Icon(CupertinoIcons.layers_alt),
            compact: true,
          )
        else
          PokeMapAssetCard(
            thumbnail: const Icon(CupertinoIcons.photo, size: 20),
            label: atlas?.name ?? 'Atlas indisponible',
            description: 'Zone ${projection.selection.left + 1},'
                '${projection.selection.top + 1} → '
                '${projection.selection.right + 1},'
                '${projection.selection.bottom + 1}',
            onPressed: null,
          ),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerRight,
          child: PokeMapButton(
            key: const Key('smart-tiles-edit-pattern'),
            onPressed: canEdit ? () => _startPatternEditing(pattern) : null,
            disabledReason: projection == null
                ? 'L’éditeur simple ne doit pas aplatir ce motif avancé.'
                : atlas == null
                    ? 'L’atlas source de ce motif est indisponible.'
                    : widget.onUpsertPattern == null
                        ? 'La session canonique du projet est indisponible.'
                        : null,
            leading: const Icon(CupertinoIcons.pencil, size: 15),
            child: const Text('Modifier le motif'),
          ),
        ),
      ],
    );
  }

  Widget _buildInspector(SmartTileLibraryItem? selectedItem) {
    final diagnostics = validateProjectSmartTileCatalog(
      catalog: widget.manifest.smartTileCatalog,
      projectTilesetIds: widget.manifest.tilesets.map((tileset) => tileset.id),
    );
    return PokeMapPanel(
      expandChild: true,
      padding: const EdgeInsets.all(14),
      header: const Padding(
        padding: EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: PokeMapSectionHeader(
          title: 'Inspecteur',
          description: 'Propriétés et validation contextuelle',
        ),
      ),
      child: ListView(
        children: <Widget>[
          if (_session.state.isCreating) ...[
            PokeMapBadge(
              key: const Key('smart-tiles-active-draft-kind'),
              label: _resumedDraftId == null
                  ? 'Brouillon de session'
                  : 'Brouillon repris',
              variant: PokeMapBadgeVariant.warning,
            ),
            const SizedBox(height: 12),
            _InspectorValue(
              label: 'Étape',
              value: _wizardStepLabel(_session.state.wizardStep),
            ),
            _InspectorValue(
              label: 'Source',
              value: _sourceChoiceLabel(_session.state.sourceChoice),
            ),
          ] else if (selectedItem != null) ...[
            PokeMapBadge(
              label: selectedItem.statusLabel,
              variant: selectedItem.isPattern
                  ? PokeMapBadgeVariant.info
                  : selectedItem.statusLabel == 'Publié'
                      ? PokeMapBadgeVariant.success
                      : PokeMapBadgeVariant.warning,
            ),
            const SizedBox(height: 12),
            _InspectorValue(label: 'Nom', value: selectedItem.name),
            if (!selectedItem.isPattern)
              _InspectorValue(label: 'Identifiant', value: selectedItem.id),
            _InspectorValue(label: 'Usage', value: selectedItem.usageLabel),
            _InspectorValue(
              label: 'Origine',
              value: selectedItem.isPattern ? 'Motif natif' : 'Natif v6',
            ),
            if (selectedItem.nativePreset != null) ...[
              const SizedBox(height: 12),
              PokeMapButton(
                key: const Key('smart-tiles-add-to-active-map'),
                onPressed: _canAddSelectedPresetToMap(selectedItem)
                    ? () => unawaited(_addSelectedPresetToMap(selectedItem))
                    : null,
                disabledReason: _addSelectedPresetDisabledReason(selectedItem),
                leading: _addingSelectedPreset
                    ? const CupertinoActivityIndicator(radius: 7)
                    : const Icon(CupertinoIcons.square_grid_3x2, size: 15),
                child: const Text('Ajouter à la map active'),
              ),
            ],
          ] else
            const PokeMapEmptyState(
              title: 'Rien à inspecter',
              description: 'Sélectionnez un preset ou créez un brouillon.',
            ),
          const SizedBox(height: 18),
          PokeMapSectionHeader(
            title: 'Diagnostics du catalogue',
            description: diagnostics.isEmpty
                ? 'Aucune erreur structurelle.'
                : '${diagnostics.length} diagnostic(s) à examiner.',
          ),
          PokeMapBadge(
            label: diagnostics.isEmpty
                ? 'Structure valide'
                : '${diagnostics.length} diagnostic(s)',
            variant: diagnostics.any((item) => item.isError)
                ? PokeMapBadgeVariant.error
                : PokeMapBadgeVariant.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildWizard() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: <Widget>[
        if (_session.state.wizardStep == SmartTileStudioWizardStep.usage)
          _buildUsageStep()
        else if (_session.state.wizardStep == SmartTileStudioWizardStep.image)
          _buildSourceStep()
        else if (_session.state.wizardStep == SmartTileStudioWizardStep.grid)
          _buildGridStep()
        else if (_session.state.wizardStep ==
            SmartTileStudioWizardStep.materials)
          _buildMaterialsStep()
        else if (_session.state.wizardStep ==
            SmartTileStudioWizardStep.connections)
          _buildConnectionsStep()
        else if (_session.state.wizardStep ==
            SmartTileStudioWizardStep.variants)
          _buildVariantsStep()
        else if (_session.state.wizardStep == SmartTileStudioWizardStep.forms)
          _buildPlacementStep()
        else if (_session.state.wizardStep == SmartTileStudioWizardStep.test)
          _buildTestStep(),
        if (_session.state.wizardStep == SmartTileStudioWizardStep.publish)
          _buildPublishStep(),
      ],
    );
  }

  Widget _buildSourceStep() {
    final selectedTileset = _selectedSourceTileset;
    final selectedAtlas = _selectedRegisteredAtlas;
    final loadedImage = _sourceImageResult?.image;
    return SmartTileImageStage(
      selectedChoice: _session.state.sourceChoice,
      isBusy: _isLoadingSourceImage || _isImportingSourceImage,
      canContinue: _canMoveToGrid,
      onChoiceSelected: _chooseSource,
      onChooseProjectImage: _chooseProjectImage,
      onChooseRegisteredAtlas: _chooseRegisteredAtlas,
      onImportImage:
          widget.onImportProjectImage == null ? null : _importProjectImage,
      onContinue: _moveToGrid,
      selectedSource: selectedTileset == null
          ? null
          : _buildSelectedSourcePreview(
              tileset: selectedTileset,
              registeredAtlas: selectedAtlas,
              image: loadedImage,
            ),
      errorMessage: _sourceImageResult != null &&
              !_sourceImageResult!.isLoaded &&
              !_isLoadingSourceImage
          ? _sourceImageResult!.message
          : null,
    );
  }

  Widget _buildSelectedSourcePreview({
    required ProjectTilesetEntry tileset,
    required ProjectSmartTileAtlas? registeredAtlas,
    required SmartTileAtlasImage? image,
  }) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      registeredAtlas?.name ?? tileset.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tileset.relativePath,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (image != null)
                PokeMapBadge(
                  label: '${image.width} × ${image.height} px',
                  variant: PokeMapBadgeVariant.info,
                ),
            ],
          ),
          if (image != null) ...[
            const SizedBox(height: 10),
            Container(
              key: const Key('smart-tiles-source-image-preview'),
              height: 180,
              decoration: BoxDecoration(
                color: colors.surfaceSubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.borderSubtle),
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: Image.memory(
                image.bytes,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) => PokeMapEmptyState(
                  title: 'Aperçu indisponible',
                  description: 'Les dimensions restent exploitables.',
                  icon: Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    color: colors.warning,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              registeredAtlas == null
                  ? '${image.width ~/ 32} × ${image.height ~/ 32} cellules à 32 px'
                  : '${registeredAtlas.columns} × ${registeredAtlas.rows} cellules enregistrées',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGridStep() {
    final geometry = _pendingGridGeometry;
    if (geometry == null || _gridProposals.isEmpty) {
      return const PokeMapEmptyState(
        title: 'Aucune grille proposée',
        description: 'Revenez à l’image et choisissez une source lisible.',
      );
    }
    return SmartTileGridStage(
      proposals: _gridProposals,
      selectedProposal: _selectedGridProposal,
      geometry: geometry,
      controllers: _gridControllers,
      onProposalSelected: _selectGridProposal,
      onChanged: _updateGridValue,
      onConfirm: geometry.isWithinImage ? _confirmGrid : null,
      atlasPreview: _SmartTileAtlasMappingViewport(
        geometry: geometry,
        image: _sourceImageResult?.image,
        selectedFrame: null,
        enabled: false,
        onCellSelected: (_) {},
      ),
    );
  }

  Widget _buildUsageStep() {
    return SmartTileUsageStage(
      selectedUsage: _session.state.usage,
      onSelected: _selectUsage,
      onContinue: _session.state.usage == null ? null : _moveToImage,
    );
  }

  Widget _buildMaterialsStep() {
    final state = _authoring.state;
    return SmartTileMaterialsStage(
      items: _materialPickerItems(),
      defaultMaterialId: state.defaultMaterialId,
      activeMaterialId: state.activeMaterialId,
      newMaterialNameController: _newMaterialNameController,
      canCreateMaterial: _newMaterialNameController.text.trim().isNotEmpty,
      canContinue: state.materials.isNotEmpty &&
          state.defaultMaterialId.isNotEmpty &&
          state.activeMaterialId.isNotEmpty,
      onActivate: _activateMaterial,
      onSetDefault: _setDefaultMaterial,
      onToggleAllowed: _toggleMaterial,
      onNewMaterialNameChanged: (_) => setState(() {}),
      onCreateMaterial: _createMaterial,
      onContinue: _moveToConnections,
    );
  }

  Widget _buildConnectionsStep() {
    final usage = _session.state.usage!;
    final hasSelection = _selectedConnectionProfileId != null &&
        (_selectedConnectionProfileId != SmartTileConnectionProfileId.custom ||
            _customConnectionTopology != null);
    return SmartTileConnectionsStage(
      usage: usage,
      coveragePolicy: _authoring.state.coveragePolicy,
      selectedProfileId: _selectedConnectionProfileId,
      customTopology: _customConnectionTopology,
      onProfileSelected: (profile) {
        unawaited(_selectConnectionProfile(profile));
      },
      onCustomTopologySelected: (topology) {
        unawaited(_selectCustomConnectionTopology(topology));
      },
      onCoveragePolicySelected: _selectCoveragePolicy,
      onContinue: hasSelection ? _moveToVariants : null,
      guidePicker: _buildOptionalGuidePicker(),
    );
  }

  Widget _buildOptionalGuidePicker() {
    final usage = _session.state.usage!;
    final guides = smartTileGuidesForUsage(usage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const PokeMapSectionHeader(
          title: 'Guide de placement (optionnel)',
          description:
              'Si votre atlas suit un dessin connu, le guide préremplira les formes sans devenir obligatoire.',
        ),
        const SizedBox(height: 12),
        PokeMapAssetCard(
          key: const Key('smart-tiles-guide-none'),
          thumbnail: const Icon(CupertinoIcons.hand_raised, size: 20),
          label: 'Sans guide',
          description:
              'Associer librement les cellules de l’atlas aux formes attendues.',
          selected: _session.state.guideId == null,
          onPressed: _disableGuide,
        ),
        const SizedBox(height: 8),
        if (guides.isEmpty)
          const PokeMapEmptyState(
            title: 'Aucun guide guidé pour cet usage',
            description:
                'Ce parcours sera ajouté dans un lot dédié ; PokeMap ne prétend pas deviner un format inconnu.',
          )
        else
          for (final guide in guides) ...[
            PokeMapAssetCard(
              key: Key('smart-tiles-guide-${guide.id.name}'),
              thumbnail: SmartTileGuideDiagram(
                guide: guide,
                compact: true,
              ),
              label: guide.name,
              description: guide.description,
              selected: _session.state.guideId == guide.id,
              onPressed: () => unawaited(_selectGuide(guide.id)),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _buildVariantsStep() {
    final geometry = _session.state.gridGeometry!;
    final proposal = _transformProposal;
    final displayedPolicy =
        proposal?.proposedPolicy ?? _authoring.state.transformPolicy;
    return SmartTileVariantsStage(
      transformPolicy: displayedPolicy,
      currentTransformPolicy: _authoring.state.transformPolicy,
      allowedTransforms: smartTileAllowedTransforms(displayedPolicy),
      topology: _authoring.state.topology!,
      transformProposal: proposal,
      animations: _authoring.state.animations,
      selectedAnimationFrames: _animationFrames,
      animationNameController: _animationNameController,
      animationDurationController: _animationDurationController,
      atlasPreview: _SmartTileAtlasMappingViewport(
        geometry: geometry,
        image: _sourceImageResult?.image,
        selectedFrame: _animationFrames.isEmpty ? null : _animationFrames.last,
        enabled: true,
        onCellSelected: (cell) => _toggleAnimationFrame(
          column: cell.column,
          row: cell.row,
        ),
      ),
      onTransformPolicyChanged: _proposeTransformPolicy,
      onAcceptTransformProposal: _acceptTransformProposal,
      onDiscardTransformProposal: _discardTransformProposal,
      onAnimationNameChanged: (_) => setState(() {}),
      onAnimationDurationChanged: (_) => setState(() {}),
      onRemoveAnimationFrame: _removeAnimationFrame,
      onClearAnimationFrames: _clearAnimationFrames,
      onCreateAnimation: _canCreateAnimation ? _createAnimation : null,
      onContinue: proposal == null ? _moveToForms : null,
    );
  }

  Widget _buildPlacementStep() {
    if (_session.state.gridGeometry == null) {
      return _buildSourceStep();
    }
    final catalog = _authoring.compileCatalog();
    final preset = catalog.presets.single;
    final forms = projectSmartTileForms(
      preset: preset,
      materials: catalog.materials,
      atlases: catalog.atlases,
      animations: catalog.animations,
    );
    final coverage = analyzeSmartTileCoverage(
      preset: preset,
      materials: catalog.materials,
      atlases: catalog.atlases,
      animations: catalog.animations,
    );
    final hasVisualCandidate = preset.rules.any(
      (rule) => rule.candidates.any((candidate) => candidate.parts.isNotEmpty),
    );
    final hasBlockingCoverage = coverage.cases.any(
      (item) =>
          item.status == SmartTileCoverageStatus.ambiguous ||
          item.status == SmartTileCoverageStatus.missing ||
          item.status == SmartTileCoverageStatus.noCandidate ||
          item.status == SmartTileCoverageStatus.missingVisualSource ||
          item.status == SmartTileCoverageStatus.outOfAtlasGrid,
    );
    final canContinue = hasVisualCandidate && !hasBlockingCoverage;
    final guideId = _session.state.guideId;
    final guide = guideId == null ? null : smartTileGuideById(guideId);
    final geometry = _session.state.gridGeometry!;
    return SmartTileFormsStage(
      usage: _session.state.usage!,
      topology: preset.topology,
      forms: forms,
      materials: _authoring.state.materials,
      transitionCases: _authoring.state.transitionCases,
      selectedMask: _selectedMask,
      selectedTransitionCaseId: _selectedTransitionCaseId,
      pendingAtlasFrame: _pendingAtlasFrame,
      atlasSelectionMode: _atlasSelectionMode,
      selectedChannel: _selectedRenderChannel,
      animations: catalog.animations,
      guideWorkbench: guide == null ? null : _buildGuideFormsWorkbench(guide),
      atlasWorkbench: _SmartTileAtlasMappingViewport(
        geometry: geometry,
        image: _sourceImageResult?.image,
        selectedFrame: _pendingAtlasFrame ?? _lastMappedFrame,
        enabled: true,
        guide: guide,
        placement: _guidePlacement,
        onCellSelected: (cell) {
          if (guide != null &&
              (_guidePlacement?.isValid != true || _correctionNumber != null)) {
            _selectGuideAtlasCell(
              guide: guide,
              column: cell.column,
              row: cell.row,
            );
            return;
          }
          _selectFormsAtlasCell(column: cell.column, row: cell.row);
        },
      ),
      onFormSelected: _selectForm,
      onCreateTransitionCase: _createTransitionCase,
      onTransitionCaseSelected: _selectTransitionCase,
      onTransitionCaseRemoved: _removeTransitionCase,
      onTransitionCaseCenterChanged: _setTransitionCaseCenter,
      onTransitionCaseSlotChanged: _setTransitionCaseSlot,
      onClearPendingFrame: _clearPendingAtlasFrame,
      onAtlasSelectionModeChanged: _changeAtlasSelectionMode,
      onChannelSelected: (channel) {
        setState(() => _selectedRenderChannel = channel);
      },
      onAnimationSelected: _mapAnimationToForm,
      onTransitionCaseAnimationSelected: _mapAnimationToTransitionCase,
      onWeightChanged: _updateVariantWeight,
      onTransitionCaseWeightChanged: _updateTransitionCaseVariantWeight,
      onVisualPartChanged: _updateVariantVisualPart,
      onTransitionCaseVisualPartChanged: _updateTransitionCaseVariantVisualPart,
      onMoveVariant: _moveVariant,
      onMoveTransitionCaseVariant: _moveTransitionCaseVariant,
      onRemoveVariant: _removeVariant,
      onRemoveTransitionCaseVariant: _removeTransitionCaseVariant,
      onContinue: canContinue ? _moveToTest : null,
    );
  }

  Widget _buildGuideFormsWorkbench(SmartTileGuideDefinition guide) {
    final placement = _guidePlacement;
    final isPlaced = placement?.isValid == true;
    return PokeMapPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PokeMapSectionHeader(
            title: isPlaced
                ? '${guide.name} a prérempli les formes'
                : 'Préremplir avec ${guide.name}',
            description: isPlaced
                ? 'Le guide reste une aide : chaque forme et chaque variante demeure modifiable.'
                : 'Cliquez la cellule nº 1 dans l’atlas. Le préremplissage conservera les variantes déjà créées.',
            trailing: PokeMapBadge(
              label: isPlaced ? 'Prérempli' : 'Facultatif',
              variant: isPlaced
                  ? PokeMapBadgeVariant.success
                  : PokeMapBadgeVariant.info,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: PokeMapBadge(
              label:
                  '${placement?.frames.length ?? 0} cellules • ${_authoring.state.mappings.length} raccords',
              variant: isPlaced
                  ? PokeMapBadgeVariant.success
                  : PokeMapBadgeVariant.warning,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              SmartTileGuideDiagram(guide: guide),
              if (isPlaced)
                PokeMapButton(
                  key: const Key('smart-tiles-disable-guide'),
                  onPressed: _disableGuide,
                  variant: PokeMapButtonVariant.ghost,
                  size: PokeMapButtonSize.small,
                  child: const Text('Désactiver le guide'),
                ),
            ],
          ),
          if (_placementMessage case final message?) ...[
            const SizedBox(height: 8),
            PokeMapBadge(
              label: message,
              variant: isPlaced
                  ? PokeMapBadgeVariant.success
                  : PokeMapBadgeVariant.warning,
            ),
          ],
          if (isPlaced) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final cell in guide.cells)
                  PokeMapButton(
                    key: Key('smart-tiles-correction-${cell.number}'),
                    onPressed: () => setState(() {
                      _correctionNumber =
                          _correctionNumber == cell.number ? null : cell.number;
                    }),
                    variant: PokeMapButtonVariant.ghost,
                    size: PokeMapButtonSize.small,
                    isSelected: _correctionNumber == cell.number,
                    child: Text('Corriger ${cell.roleLabel}'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Kept until the legacy cutover lot removes the former guided renderer.
  // ignore: unused_element
  Widget _buildGuidedPlacementMapping(SmartTileGuideDefinition guide) {
    final geometry = _session.state.gridGeometry!;
    final placement = _guidePlacement;
    final mappedCount = _authoring.state.mappings.length;
    final placedCellCount = placement?.frames.length ?? 0;
    final isComplete = placement?.isValid == true &&
        placedCellCount == guide.cells.length &&
        mappedCount == guide.requiredMasks.length &&
        smartTileCanonicalMasks(guide.templateHint)
            .every(_authoring.state.mappings.containsKey);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PokeMapSectionHeader(
          title: 'Placer ${guide.name}',
          description:
              'Cliquez sur la cellule nº 1 de votre atlas. Les quinze autres associations seront posées ensemble.',
          trailing: PokeMapBadge(
            label: '$placedCellCount cellules • $mappedCount raccords',
            variant: isComplete
                ? PokeMapBadgeVariant.success
                : PokeMapBadgeVariant.warning,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            SmartTileGuideDiagram(guide: guide),
            SizedBox(
              width: 360,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'La case 1 est l’ancre. Le contour numéroté apparaît sur l’image avant l’essai.',
                    style: TextStyle(
                      color: context.pokeMapColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  PokeMapButton(
                    key: const Key('smart-tiles-change-source'),
                    onPressed: _resetPlacementSource,
                    variant: PokeMapButtonVariant.secondary,
                    size: PokeMapButtonSize.small,
                    child: const Text('Changer d’atlas'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        PokeMapPanel(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              const Icon(CupertinoIcons.check_mark_circled_solid, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Grille confirmée : ${geometry.columns} × ${geometry.rows} cellules de ${geometry.cellWidth} × ${geometry.cellHeight} px.',
                  style: TextStyle(
                    color: context.pokeMapColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SmartTileAtlasMappingViewport(
          geometry: geometry,
          image: _sourceImageResult?.image,
          selectedFrame: null,
          enabled: true,
          guide: guide,
          placement: placement,
          onCellSelected: (cell) => _selectGuideAtlasCell(
            guide: guide,
            column: cell.column,
            row: cell.row,
          ),
        ),
        if (_placementMessage != null) ...[
          const SizedBox(height: 10),
          PokeMapBadge(
            label: _placementMessage!,
            variant: isComplete
                ? PokeMapBadgeVariant.success
                : PokeMapBadgeVariant.warning,
          ),
        ],
        if (placement?.isValid == true) ...[
          const SizedBox(height: 16),
          const PokeMapSectionHeader(
            title: 'Corriger une cellule',
            description:
                'Optionnel : choisissez son numéro, puis cliquez sa vraie position dans l’atlas.',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final cell in guide.cells)
                PokeMapButton(
                  key: Key('smart-tiles-correction-${cell.number}'),
                  onPressed: () => setState(() {
                    _correctionNumber =
                        _correctionNumber == cell.number ? null : cell.number;
                  }),
                  variant: PokeMapButtonVariant.ghost,
                  size: PokeMapButtonSize.small,
                  isSelected: _correctionNumber == cell.number,
                  child: Text('Case ${cell.number} — ${cell.roleLabel}'),
                ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerRight,
          child: PokeMapButton(
            key: const Key('smart-tiles-mapping-next-step'),
            onPressed: isComplete ? _moveToTest : null,
            trailing: const Icon(CupertinoIcons.chevron_right, size: 14),
            child: const Text('Ouvrir le banc d’essai'),
          ),
        ),
      ],
    );
  }

  // Kept until the legacy cutover lot removes the former mask renderer.
  // ignore: unused_element
  Widget _buildLegacyMappingStep() {
    final geometry = _session.state.gridGeometry!;
    final template = _authoring.state.templateHint;
    final masks = smartTileCanonicalMasks(template);
    final mappedCount = _authoring.state.mappings.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PokeMapSectionHeader(
          title: 'Mapping ${_templateLabel(template)}',
          description: '${masks.length} signatures attendues',
          trailing: PokeMapBadge(
            label: '$mappedCount / ${masks.length}',
            variant: mappedCount == masks.length
                ? PokeMapBadgeVariant.success
                : PokeMapBadgeVariant.warning,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$mappedCount ${mappedCount == 1 ? 'signature mappée' : 'signatures mappées'}',
        ),
        const SizedBox(height: 14),
        const PokeMapSectionHeader(
          title: '1. Signature',
          description:
              'Les masques sont normalisés par le même moteur que le runtime.',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final mask in masks)
              PokeMapButton(
                key: Key('smart-tiles-mapping-mask-$mask'),
                onPressed: () => setState(() => _selectedMask = mask),
                variant: PokeMapButtonVariant.ghost,
                size: PokeMapButtonSize.small,
                isSelected: _selectedMask == mask,
                child: Text(
                  '0x${mask.toRadixString(16).padLeft(2, '0').toUpperCase()}',
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        const PokeMapSectionHeader(
          title: '2. Cellule de l’atlas',
          description:
              'Le placement source est indépendant de l’ordre des signatures.',
        ),
        const SizedBox(height: 8),
        _SmartTileAtlasMappingViewport(
          geometry: geometry,
          image: _sourceImageResult?.image,
          selectedFrame: _lastMappedFrame,
          enabled: _selectedMask != null,
          onCellSelected: (cell) => _mapAtlasFrame(
            frame: SmartTileFrameRef(
              atlasId: _authoring.state.atlasId,
              column: cell.column,
              row: cell.row,
            ),
          ),
        ),
        if (_session.state.usage == SmartTileUsage.forestSurface &&
            _lastCandidateId != null) ...[
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: PokeMapButton(
              key: const Key('smart-tiles-add-canopy-part'),
              onPressed: _addCanopyPart,
              variant: PokeMapButtonVariant.secondary,
              leading: const Icon(CupertinoIcons.tree, size: 15),
              child: const Text('Ajouter une couche de canopée'),
            ),
          ),
        ],
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerRight,
          child: PokeMapButton(
            key: const Key('smart-tiles-mapping-next-step'),
            onPressed: mappedCount == 0 ? null : _moveToTest,
            trailing: const Icon(CupertinoIcons.chevron_right, size: 14),
            child: const Text('Tester le preset'),
          ),
        ),
      ],
    );
  }

  Widget _buildTestStep() {
    final catalog = _authoring.compileCatalog();
    final preset = catalog.presets.single;
    final controller = _testLabFor(preset: preset, catalog: catalog);
    final scenarios = controller.runCanonicalScenarios();
    final isComplete = _labIsPublishable(
      preset: preset,
      scenarios: scenarios,
    );
    final forms = projectSmartTileForms(
      preset: preset,
      materials: catalog.materials,
      atlases: catalog.atlases,
      animations: catalog.animations,
    );
    final guideId = _session.state.guideId;
    final guide = guideId == null ? null : smartTileGuideById(guideId);
    final variantCount = preset.rules.fold<int>(
      0,
      (count, rule) => count + math.max(0, rule.candidates.length - 1),
    );
    return SmartTileTestStage(
      controller: controller,
      tool: _testLabTool,
      forms: forms,
      scenarios: scenarios,
      isPublishable: isComplete,
      variantCount: variantCount,
      guideSummaryLabels: guide == null
          ? const <String>[]
          : const <String>[
              '4 coins extérieurs',
              '4 bords',
              '4 coins intérieurs',
            ],
      onToolChanged: (tool) => setState(() => _testLabTool = tool),
      onTargetPressed: _applyLabTarget,
      onReset: _resetLab,
      onScenarioSelected: _loadLabScenario,
      onContinue: _moveToPublish,
    );
  }

  Widget _buildPublishStep() {
    final guideId = _session.state.guideId;
    final guide = guideId == null ? null : smartTileGuideById(guideId);
    final geometry = _session.state.gridGeometry!;
    final compiled = _authoring.compileCatalog();
    final diagnostics = validateProjectSmartTileCatalog(
      catalog: compiled,
      projectTilesetIds: widget.manifest.tilesets.map((tileset) => tileset.id),
    );
    final blocking = diagnostics.where((item) => item.isError).toList();
    final warnings = diagnostics.where((item) => !item.isError).toList();
    return SmartTilePublishStage(
      name: _authoring.state.name,
      usage: _authoring.state.usage!,
      atlasSummary: _authoring.state.atlasName,
      gridSummary:
          '${geometry.cellWidth} × ${geometry.cellHeight} px — ${geometry.columns} × ${geometry.rows} cellules',
      guideSummary: guide?.name ?? 'Aucun — associations libres',
      mappingSummary: guide == null
          ? _authoring.state.transitionCases.isEmpty
              ? '${_authoring.state.mappings.length} formes • ${_authoring.state.mappings.values.expand((variants) => variants).length} variantes'
              : '${_authoring.state.mappings.length} formes relatives • '
                  '${_authoring.state.transitionCases.length} cas exacts • '
                  '${compiled.presets.single.rules.expand((rule) => rule.candidates).length} variantes'
          : '${guide.cells.length} cellules • '
              '${guide.requiredMasks.length} raccords • '
              '${guide.cells.length - guide.requiredMasks.length} variantes'
              '${_authoring.state.transitionCases.isEmpty ? '' : ' • ${_authoring.state.transitionCases.length} cas exacts'}',
      targetKind: _publicationTargetKind,
      mapId: widget.launchContext.capturedMapId,
      mapAvailable: widget.isCapturedMapAvailable && widget.capturedMap != null,
      layerIdController: _publicationLayerIdController,
      layerNameController: _publicationLayerNameController,
      blockingDiagnostics: blocking,
      warningDiagnostics: warnings,
      busy: _publicationBusy,
      plan: _publicationPlan,
      errorCode: _publicationErrorCode,
      errorMessage: _publicationErrorMessage,
      published: _publicationApplied,
      onTargetChanged: _changePublicationTarget,
      onLayerIdentityChanged: _clearPublicationPlan,
      onPlan: () => unawaited(_planPublication(diagnostics)),
      onApply: () => unawaited(_applyPublication()),
    );
  }

  Widget _buildAtlasTab(SmartTileLibraryItem selectedItem) {
    final atlases = widget.manifest.smartTileCatalog.atlases;
    if (atlases.isEmpty) {
      return const PokeMapEmptyState(
        title: 'Aucun atlas natif',
        description: 'Ajoutez une source dans le flux de création.',
        icon: Icon(CupertinoIcons.photo),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: atlases.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final atlas = atlases[index];
        return PokeMapAssetCard(
          thumbnail: const Icon(CupertinoIcons.photo, size: 20),
          label: atlas.name,
          description: '${atlas.columns} × ${atlas.rows} cellules • '
              '${atlas.cellWidth} × ${atlas.cellHeight} px • '
              'origine ${atlas.originX},${atlas.originY} • '
              'espacement ${atlas.spacingX},${atlas.spacingY}',
          onPressed: null,
        );
      },
    );
  }

  Widget _buildRulesTab(SmartTileLibraryItem selectedItem) {
    final preset = selectedItem.nativePreset;
    if (preset == null) {
      return const PokeMapEmptyState(
        title: 'Règles historiques',
        description:
            'Lecture seule : aucune règle native n’est inventée pendant la migration.',
        icon: Icon(CupertinoIcons.arrow_branch),
      );
    }
    if (preset.rules.isEmpty) {
      return const PokeMapEmptyState(
        title: 'Aucune règle',
        description: 'Le mapping du preset est encore vide.',
        icon: Icon(CupertinoIcons.arrow_branch),
      );
    }
    final formsByMask = <int, SmartTileFormReadModel>{
      for (final form in projectSmartTileForms(
        preset: preset,
        materials: widget.manifest.smartTileCatalog.materials,
        atlases: widget.manifest.smartTileCatalog.atlases,
        animations: widget.manifest.smartTileCatalog.animations,
      ))
        form.mask: form,
    };
    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: preset.rules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final rule = preset.rules[index];
        final mask = smartTileMaskForSignature(
          rule.signature,
          topology: preset.topology,
        );
        final form = mask == null ? null : formsByMask[mask];
        return PokeMapAssetCard(
          key: Key('smart-tiles-rule-${rule.id}'),
          thumbnail: const Icon(CupertinoIcons.arrow_branch, size: 20),
          label: form?.label ?? 'Forme personnalisée',
          description: form?.description ??
              'Cette règle avancée ne correspond pas à une forme standard.',
          selected: _focusedRuleId == rule.id ||
              (_focusedRuleId == null && _focusedMask == mask),
          onPressed: () => setState(() {
            _focusedRuleId = rule.id;
            _focusedMask = mask;
          }),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              PokeMapBadge(
                label: '${rule.candidates.length} variante(s)',
                variant: PokeMapBadgeVariant.neutral,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTestBenchTab(SmartTileLibraryItem selectedItem) {
    final preset = selectedItem.nativePreset;
    if (preset == null) {
      return const PokeMapEmptyState(
        title: 'Banc d’essai natif indisponible',
        description:
            'Convertissez explicitement le preset historique avant de le tester avec le résolveur Smart Tiles.',
        icon: Icon(CupertinoIcons.hammer),
      );
    }
    final catalog = widget.manifest.smartTileCatalog;
    final controller = _testLabFor(preset: preset, catalog: catalog);
    final scenarios = controller.runCanonicalScenarios();
    final forms = projectSmartTileForms(
      preset: preset,
      materials: catalog.materials,
      atlases: catalog.atlases,
      animations: catalog.animations,
    );
    final variantCount = preset.rules.fold<int>(
      0,
      (count, rule) => count + math.max(0, rule.candidates.length - 1),
    );
    return ListView(
      padding: const EdgeInsets.all(18),
      children: <Widget>[
        SmartTileTestStage(
          controller: controller,
          tool: _testLabTool,
          forms: forms,
          scenarios: scenarios,
          isPublishable: _labIsPublishable(
            preset: preset,
            scenarios: scenarios,
          ),
          variantCount: variantCount,
          onToolChanged: (tool) => setState(() => _testLabTool = tool),
          onTargetPressed: _applyLabTarget,
          onReset: _resetLab,
          onScenarioSelected: _loadLabScenario,
        ),
      ],
    );
  }

  Widget _buildValidationTab(SmartTileLibraryItem selectedItem) {
    final diagnostics = validateProjectSmartTileCatalog(
      catalog: widget.manifest.smartTileCatalog,
      projectTilesetIds: widget.manifest.tilesets.map((tileset) => tileset.id),
    );
    final blocking = diagnostics.where((item) => item.isError).length;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: <Widget>[
        PokeMapSectionHeader(
          title: 'Validation du preset',
          description:
              'Couverture, ambiguïtés, références, poids, durées et limites d’atlas.',
          trailing: PokeMapBadge(
            label: blocking == 0
                ? selectedItem.statusLabel == 'Publié'
                    ? 'Preset publié et valide'
                    : 'Brouillon valide'
                : '$blocking erreur(s) bloquante(s)',
            variant: blocking == 0
                ? selectedItem.statusLabel == 'Publié'
                    ? PokeMapBadgeVariant.success
                    : PokeMapBadgeVariant.info
                : PokeMapBadgeVariant.error,
          ),
        ),
        if (_draftMessage != null) ...[
          const SizedBox(height: 10),
          PokeMapBadge(
            label: _draftMessage!,
            variant: PokeMapBadgeVariant.warning,
          ),
        ],
        const SizedBox(height: 12),
        if (diagnostics.isEmpty)
          const PokeMapEmptyState(
            title: 'Tout est valide',
            description: 'Le preset peut être publié.',
            icon: Icon(CupertinoIcons.check_mark_circled),
          )
        else
          for (final diagnostic in diagnostics) ...[
            PokeMapAssetCard(
              key: Key(
                'smart-tiles-diagnostic-${diagnostic.code}-${diagnostic.path}',
              ),
              thumbnail: Icon(
                diagnostic.isError
                    ? CupertinoIcons.exclamationmark_triangle
                    : CupertinoIcons.info_circle,
                size: 18,
              ),
              label: diagnostic.code,
              description: diagnostic.message,
              onPressed: () => _openDiagnostic(diagnostic),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  bool _canAddSelectedPresetToMap(SmartTileLibraryItem item) {
    return !_addingSelectedPreset &&
        item.nativePreset?.status == SmartTilePresetStatus.published &&
        widget.isCapturedMapAvailable &&
        widget.onAddPresetToCapturedMap != null;
  }

  String? _addSelectedPresetDisabledReason(SmartTileLibraryItem item) {
    if (_addingSelectedPreset) return 'Ajout de la couche en cours.';
    if (item.nativePreset?.status != SmartTilePresetStatus.published) {
      return 'Publiez ce preset avant de l’ajouter à une carte.';
    }
    if (!widget.isCapturedMapAvailable) {
      return 'Ouvrez une carte enregistrée depuis laquelle le Studio a été lancé.';
    }
    if (widget.onAddPresetToCapturedMap == null) {
      return 'La session canonique de la carte n’est pas disponible.';
    }
    return null;
  }

  Future<void> _addSelectedPresetToMap(SmartTileLibraryItem item) async {
    final preset = item.nativePreset;
    final callback = widget.onAddPresetToCapturedMap;
    if (preset == null || callback == null || _addingSelectedPreset) return;
    setState(() {
      _addingSelectedPreset = true;
      _draftMessage = null;
    });
    try {
      final added = await callback(preset);
      if (!mounted) return;
      setState(() {
        _draftMessage = added
            ? 'Couche « ${preset.name} » ajoutée et sélectionnée.'
            : 'La couche n’a pas pu être ajoutée à la carte.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _draftMessage = 'Échec de l’ajout : $error');
    } finally {
      if (mounted) setState(() => _addingSelectedPreset = false);
    }
  }

  Widget _buildAnimationsTab(SmartTileLibraryItem selectedItem) {
    final animations = widget.manifest.smartTileCatalog.animations;
    if (animations.isEmpty) {
      return const PokeMapEmptyState(
        title: 'Aucune animation native',
        description:
            'Les timelines sont séparées des variantes et de leurs poids.',
        icon: Icon(CupertinoIcons.play_circle),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: animations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final animation = animations[index];
        final duration = animation.frames.fold<int>(
          0,
          (sum, frame) => sum + frame.durationMs,
        );
        return PokeMapAssetCard(
          thumbnail: const Icon(CupertinoIcons.play_circle, size: 20),
          label: animation.name,
          onPressed: null,
          trailing: PokeMapBadge(
            label: '${animation.frames.length} frames • $duration ms',
            variant: PokeMapBadgeVariant.info,
          ),
        );
      },
    );
  }

  Future<void> _pickTiledWangSource() async {
    final callback = widget.onPickTiledWangSource;
    if (callback == null || _tiledWangPicking || _tiledWangImporting) return;
    setState(() {
      _tiledWangPicking = true;
      _tiledWangError = null;
    });
    try {
      final source = await callback();
      if (!mounted || source == null) return;
      setState(() {
        _session.cancelDraft();
        _editingPattern = null;
        _newPatternId = null;
        _patternError = null;
        _tiledWangSource = source;
        _selectedItemKey = null;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _tiledWangError = _tiledWangFailureMessage(error));
    } finally {
      if (mounted) setState(() => _tiledWangPicking = false);
    }
  }

  void _cancelTiledWangImport() {
    if (_tiledWangImporting) return;
    setState(() {
      _tiledWangSource = null;
      _tiledWangError = null;
      _selectedItemKey =
          buildSmartTileStudioLibrary(widget.manifest).firstOrNull?.key;
    });
  }

  Future<void> _importTiledWang(
    List<TiledWangSetSelection> selections,
  ) async {
    final callback = widget.onImportTiledWang;
    final source = _tiledWangSource;
    if (callback == null || source == null || _tiledWangImporting) return;
    setState(() {
      _tiledWangImporting = true;
      _tiledWangError = null;
    });
    try {
      final result = await callback(source, selections);
      if (!mounted) return;
      setState(() {
        _selectedItemKey = result.presetIds.isEmpty
            ? null
            : 'native:${result.presetIds.first}';
        _tiledWangSource = null;
        _draftMessage = result.presetIds.length == 1
            ? 'Wang Set importé comme brouillon Smart Tile.'
            : '${result.presetIds.length} Wang Sets importés comme brouillons Smart Tiles.';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _tiledWangError = _tiledWangFailureMessage(error));
    } finally {
      if (mounted) setState(() => _tiledWangImporting = false);
    }
  }

  void _startNewPattern() {
    setState(() {
      _session.cancelDraft();
      _tiledWangSource = null;
      _tiledWangError = null;
      _editingPattern = null;
      _newPatternId = _nextPatternId();
      _patternSaving = false;
      _patternError = null;
    });
  }

  void _startPatternEditing(ProjectSmartTilePattern pattern) {
    setState(() {
      _session.cancelDraft();
      _tiledWangSource = null;
      _tiledWangError = null;
      _editingPattern = pattern;
      _newPatternId = null;
      _patternSaving = false;
      _patternError = null;
    });
  }

  void _cancelPatternEditing() {
    setState(() {
      _editingPattern = null;
      _newPatternId = null;
      _patternSaving = false;
      _patternError = null;
    });
  }

  Future<void> _savePattern(ProjectSmartTilePattern pattern) async {
    final callback = widget.onUpsertPattern;
    if (callback == null || _patternSaving) return;
    setState(() {
      _patternSaving = true;
      _patternError = null;
    });
    try {
      await callback(pattern);
      if (!mounted) return;
      setState(() {
        _selectedItemKey = 'pattern:${pattern.id}';
        _editingPattern = null;
        _newPatternId = null;
        _draftMessage = 'Motif « ${pattern.name} » enregistré.';
      });
    } on Object catch (error) {
      if (!mounted) return;
      final failure = EditorAuthoringMutationFailure.capture(error);
      setState(() => _patternError = failure.message);
    } finally {
      if (mounted) setState(() => _patternSaving = false);
    }
  }

  void _startDraft() {
    setState(() {
      _tiledWangSource = null;
      _tiledWangError = null;
      _editingPattern = null;
      _newPatternId = null;
      _patternError = null;
      _session.startDraft();
      _resumedDraftId = null;
      final id = _nextDraftId();
      _authoring = SmartTileAuthoringController.blank()
        ..configureIdentity(
          id: id,
          name: 'Nouveau Smart Tile',
        );
      _newMaterialNameController.clear();
      _animationNameController.clear();
      _animationDurationController.text = '180';
      _selectedMask = null;
      _selectedTransitionCaseId = null;
      _lastMappedFrame = null;
      _pendingAtlasFrame = null;
      _animationFrames = const <SmartTileFrameRef>[];
      _lastCandidateId = null;
      _selectedRenderChannel = SmartTileRenderChannel.ground;
      _guidePlacement = null;
      _correctionNumber = null;
      _placementMessage = null;
      _draftMessage = null;
      _clearSourceImageSelection();
      _selectedRegisteredAtlasId = null;
      _selectedConnectionProfileId = null;
      _customConnectionTopology = null;
      _testLabController = null;
      _testLabTool = SmartTileLabTool.pencil;
      _transformProposal = null;
      _resetPublicationState();
      _tab = SmartTilesStudioTab.atlas;
    });
  }

  Future<void> _resumeDraft(ProjectSmartTileAuthoringDraft draft) async {
    final authoring = SmartTileAuthoringController.fromCanonicalDraft(
      draft,
      catalogMaterials: widget.manifest.smartTileCatalog.materials,
    );
    final connectionProfile = smartTileConnectionProfileForConfiguration(
      topology: draft.topology,
      templateHint: draft.templateHint,
    );
    final atlas = draft.atlases
        .where((candidate) => candidate.id == draft.primaryAtlasId)
        .firstOrNull;
    final tilesetId = atlas?.tilesetId ?? draft.sourceTilesetIds.firstOrNull;
    final tileset = widget.manifest.tilesets
        .where((candidate) => candidate.id == tilesetId)
        .firstOrNull;
    setState(() {
      _tiledWangSource = null;
      _tiledWangError = null;
      _editingPattern = null;
      _newPatternId = null;
      _patternError = null;
      _authoring = authoring;
      _resumedDraftId = draft.id;
      _session.resumeDraft(
        draft,
        gridGeometry: authoring.state.gridGeometry,
      );
      _selectedItemKey = 'draft:${draft.id}';
      _newMaterialNameController.clear();
      _animationNameController.clear();
      _animationDurationController.text = '180';
      _selectedMask = null;
      _selectedTransitionCaseId = null;
      _lastMappedFrame = null;
      _pendingAtlasFrame = null;
      _animationFrames = const <SmartTileFrameRef>[];
      _lastCandidateId = null;
      _selectedRenderChannel = SmartTileRenderChannel.ground;
      _guidePlacement = null;
      _correctionNumber = null;
      _placementMessage = 'Brouillon repris à l’étape « '
          '${_wizardStepLabel(_session.state.wizardStep)} ».';
      _draftMessage = null;
      _clearSourceImageSelection();
      _selectedSourceTilesetId = tilesetId;
      _selectedRegisteredAtlasId = widget.manifest.smartTileCatalog.atlases
              .any((candidate) => candidate.id == atlas?.id)
          ? atlas?.id
          : null;
      _selectedConnectionProfileId =
          connectionProfile?.id ?? SmartTileConnectionProfileId.custom;
      _customConnectionTopology =
          connectionProfile == null ? draft.topology : null;
      _testLabController = null;
      _testLabTool = SmartTileLabTool.pencil;
      _transformProposal = null;
      _resetPublicationState();
      _tab = SmartTilesStudioTab.atlas;
    });
    if (tileset == null) return;
    await _loadSourceImage(tileset);
    if (!mounted ||
        _session.state.wizardStep != SmartTileStudioWizardStep.grid) {
      return;
    }
    final image = _sourceImageResult?.image;
    if (image == null) return;
    final canonical = authoring.state.gridGeometry;
    final proposals = canonical == null
        ? _gridDetector.detect(
            SmartTileGridDetectionInput(
              imageWidth: image.width,
              imageHeight: image.height,
              columnAlphaCoverage: image.columnAlphaCoverage,
              rowAlphaCoverage: image.rowAlphaCoverage,
            ),
          )
        : <SmartTileGridCandidate>[
            SmartTileGridCandidate(
              geometry: canonical.copyWith(
                imageWidth: image.width,
                imageHeight: image.height,
              ),
              confidence: 1,
              reason: 'Grille restaurée depuis le brouillon canonique.',
            ),
          ];
    final geometry = proposals.first.geometry;
    _setGridControllers(geometry);
    setState(() {
      _gridProposals = proposals;
      _selectedGridProposal = 0;
      _pendingGridGeometry = geometry;
      _session.resumeDraft(draft, gridGeometry: geometry);
    });
  }

  ProjectTilesetEntry? get _selectedSourceTileset => widget.manifest.tilesets
      .where((tileset) => tileset.id == _selectedSourceTilesetId)
      .firstOrNull;

  ProjectSmartTileAtlas? get _selectedRegisteredAtlas =>
      widget.manifest.smartTileCatalog.atlases
          .where((atlas) => atlas.id == _selectedRegisteredAtlasId)
          .firstOrNull;

  bool get _canMoveToGrid {
    return switch (_session.state.sourceChoice) {
      SmartTileStudioSourceChoice.emptyPreset => true,
      SmartTileStudioSourceChoice.projectImage ||
      SmartTileStudioSourceChoice.registeredAtlas =>
        _selectedSourceTilesetId != null &&
            _sourceImageResult?.isLoaded == true &&
            !_isLoadingSourceImage &&
            !_isImportingSourceImage,
      null => false,
    };
  }

  void _clearSourceImageSelection() {
    _sourceLoadRevision += 1;
    _selectedSourceTilesetId = null;
    _sourceImageResult = null;
    _isLoadingSourceImage = false;
    _isImportingSourceImage = false;
    _gridProposals = const <SmartTileGridCandidate>[];
    _pendingGridGeometry = null;
  }

  void _chooseSource(SmartTileStudioSourceChoice choice) {
    setState(() {
      _session.chooseSource(choice);
      _clearSourceImageSelection();
      _selectedRegisteredAtlasId = null;
    });
    _notifyDraftChanged();
  }

  Future<void> _chooseProjectImage() async {
    if (widget.manifest.tilesets.isEmpty) {
      setState(() {
        _sourceImageResult = const SmartTileAtlasImageLoadResult(
          status: SmartTileAtlasImageLoadStatus.missingFile,
          message: 'Le projet ne contient aucun tileset.',
        );
      });
      return;
    }
    final selected = await showPokeMapDesktopSideSheet<ProjectTilesetEntry>(
      context: context,
      title: 'Choisir une image du projet',
      semanticLabel: 'Sélecteur de tileset Smart Tiles',
      width: 520,
      builder: (context) => _SmartTileProjectImagePicker(
        key: const Key('smart-tiles-source-picker'),
        tilesets: widget.manifest.tilesets,
      ),
    );
    if (!mounted || selected == null) {
      return;
    }
    await _loadSourceImage(selected);
  }

  Future<void> _importProjectImage() async {
    final importImage = widget.onImportProjectImage;
    if (importImage == null || _isImportingSourceImage) return;
    setState(() {
      _isImportingSourceImage = true;
      _sourceImageResult = null;
    });
    try {
      final imported = await importImage();
      if (!mounted || imported == null) return;
      setState(() {
        _selectedSourceTilesetId = imported.tileset.id;
        _selectedRegisteredAtlasId = null;
        _sourceImageResult = SmartTileAtlasImageLoadResult(
          status: SmartTileAtlasImageLoadStatus.loaded,
          message: 'Image importée dans le projet.',
          image: imported.image,
        );
      });
      _notifyDraftChanged();
    } on SmartTileSourceImportException catch (error) {
      if (!mounted) return;
      setState(() {
        _sourceImageResult = SmartTileAtlasImageLoadResult(
          status: SmartTileAtlasImageLoadStatus.invalidImage,
          message: error.message,
        );
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _sourceImageResult = const SmartTileAtlasImageLoadResult(
          status: SmartTileAtlasImageLoadStatus.invalidImage,
          message: 'L’import canonique de l’image a échoué.',
        );
      });
    } finally {
      if (mounted) setState(() => _isImportingSourceImage = false);
    }
  }

  Future<void> _chooseRegisteredAtlas() async {
    final atlases = widget.manifest.smartTileCatalog.atlases;
    if (atlases.isEmpty) {
      setState(() {
        _sourceImageResult = const SmartTileAtlasImageLoadResult(
          status: SmartTileAtlasImageLoadStatus.missingFile,
          message: 'Le projet ne contient aucun atlas Smart Tile enregistré.',
        );
      });
      return;
    }
    final selected = await showPokeMapDesktopSideSheet<ProjectSmartTileAtlas>(
      context: context,
      title: 'Choisir un atlas enregistré',
      semanticLabel: 'Sélecteur d’atlas Smart Tiles',
      width: 520,
      builder: (context) => _SmartTileRegisteredAtlasPicker(
        atlases: atlases,
      ),
    );
    if (!mounted || selected == null) {
      return;
    }
    final tileset = widget.manifest.tilesets
        .where((entry) => entry.id == selected.tilesetId)
        .firstOrNull;
    if (tileset == null) {
      setState(() {
        _selectedRegisteredAtlasId = selected.id;
        _sourceImageResult = const SmartTileAtlasImageLoadResult(
          status: SmartTileAtlasImageLoadStatus.missingFile,
          message: 'Le tileset de cet atlas est absent du projet.',
        );
      });
      return;
    }
    _selectedRegisteredAtlasId = selected.id;
    await _loadSourceImage(tileset);
  }

  Future<void> _loadSourceImage(ProjectTilesetEntry tileset) async {
    final revision = ++_sourceLoadRevision;
    setState(() {
      _selectedSourceTilesetId = tileset.id;
      _sourceImageResult = null;
      _isLoadingSourceImage = true;
    });
    final result = await widget.imageLoader.load(
      projectRootPath: widget.projectRootPath,
      tileset: tileset,
    );
    if (!mounted || revision != _sourceLoadRevision) {
      return;
    }
    setState(() {
      _sourceImageResult = result;
      _isLoadingSourceImage = false;
    });
    _notifyDraftChanged();
  }

  void _moveToGrid() {
    final image = _sourceImageResult?.image;
    final registeredAtlas = _selectedRegisteredAtlas;
    final proposals = switch (_session.state.sourceChoice) {
      SmartTileStudioSourceChoice.emptyPreset => _gridDetector.detect(
          const SmartTileGridDetectionInput(
            imageWidth: 160,
            imageHeight: 96,
          ),
        ),
      SmartTileStudioSourceChoice.registeredAtlas
          when image != null && registeredAtlas != null =>
        <SmartTileGridCandidate>[
          SmartTileGridCandidate(
            geometry: SmartTileGridGeometry(
              imageWidth: image.width,
              imageHeight: image.height,
              cellWidth: registeredAtlas.cellWidth,
              cellHeight: registeredAtlas.cellHeight,
              originX: registeredAtlas.originX,
              originY: registeredAtlas.originY,
              marginX: registeredAtlas.marginX,
              marginY: registeredAtlas.marginY,
              spacingX: registeredAtlas.spacingX,
              spacingY: registeredAtlas.spacingY,
              explicitColumns: registeredAtlas.columns,
              explicitRows: registeredAtlas.rows,
            ),
            confidence: 1,
            reason: 'Grille confirmée de l’atlas enregistré.',
          ),
        ],
      SmartTileStudioSourceChoice.projectImage when image != null =>
        _gridDetector.detect(
          SmartTileGridDetectionInput(
            imageWidth: image.width,
            imageHeight: image.height,
            columnAlphaCoverage: image.columnAlphaCoverage,
            rowAlphaCoverage: image.rowAlphaCoverage,
          ),
        ),
      _ => throw StateError('Choose a readable Smart Tile source first.'),
    };
    final detected = proposals.first.geometry;
    _setGridControllers(detected);
    setState(() {
      _gridProposals = proposals;
      _selectedGridProposal = 0;
      _pendingGridGeometry = detected;
      _session.moveToGrid();
    });
    _flushDraftAfterStepChange();
  }

  void _setGridControllers(SmartTileGridGeometry geometry) {
    final values = <String, int>{
      'cellWidth': geometry.cellWidth,
      'cellHeight': geometry.cellHeight,
      'columns': geometry.columns,
      'rows': geometry.rows,
      'originX': geometry.originX,
      'originY': geometry.originY,
      'marginX': geometry.marginX,
      'marginY': geometry.marginY,
      'spacingX': geometry.spacingX,
      'spacingY': geometry.spacingY,
    };
    for (final entry in values.entries) {
      final controller =
          _gridControllers.putIfAbsent(entry.key, TextEditingController.new);
      controller.text = '${entry.value}';
    }
  }

  void _updateGridValue(String field, String value) {
    final parsed = int.tryParse(value);
    final current = _pendingGridGeometry;
    if (parsed == null || parsed < 0 || current == null) {
      return;
    }
    final next = switch (field) {
      'cellWidth' when parsed > 0 => current.copyWith(cellWidth: parsed),
      'cellHeight' when parsed > 0 => current.copyWith(cellHeight: parsed),
      'columns' when parsed > 0 => current.copyWith(explicitColumns: parsed),
      'rows' when parsed > 0 => current.copyWith(explicitRows: parsed),
      'originX' => current.copyWith(originX: parsed),
      'originY' => current.copyWith(originY: parsed),
      'marginX' => current.copyWith(marginX: parsed),
      'marginY' => current.copyWith(marginY: parsed),
      'spacingX' => current.copyWith(spacingX: parsed),
      'spacingY' => current.copyWith(spacingY: parsed),
      _ => current,
    };
    setState(() {
      _pendingGridGeometry = next;
      _guidePlacement = null;
      _correctionNumber = null;
    });
  }

  void _selectGridProposal(int index) {
    final geometry = _gridProposals[index].geometry;
    _setGridControllers(geometry);
    setState(() {
      _selectedGridProposal = index;
      _pendingGridGeometry = geometry;
    });
  }

  void _confirmGrid() {
    final geometry = _pendingGridGeometry;
    if (geometry == null || !geometry.isWithinImage) return;
    _configureDraftAtlas(geometry);
    setState(() {
      _session.configureGrid(geometry);
      _authoring.clearMappings();
      _session.moveToMaterials();
    });
    _flushDraftAfterStepChange();
  }

  void _moveToImage() {
    setState(_session.moveToImage);
    _flushDraftAfterStepChange();
  }

  void _moveToConnections() {
    if (_authoring.state.materials.isEmpty ||
        _authoring.state.defaultMaterialId.isEmpty ||
        _authoring.state.activeMaterialId.isEmpty) {
      return;
    }
    setState(() {
      if (_selectedConnectionProfileId == null) {
        final recommended = recommendedSmartTileConnectionProfile(
          _session.state.usage!,
        );
        _selectedConnectionProfileId = recommended.id;
        _customConnectionTopology = null;
        _authoring.configureConnections(
          recommended.resolve(),
          clearMappings: _authoring.state.mappings.isNotEmpty ||
              _authoring.state.transitionCases.isNotEmpty,
        );
      }
      _session.moveToConnections();
    });
    _flushDraftAfterStepChange();
  }

  void _moveToVariants() {
    setState(_session.moveToVariants);
    _flushDraftAfterStepChange();
  }

  void _moveToForms() {
    setState(_session.moveToForms);
    _flushDraftAfterStepChange();
  }

  bool get _canCreateAnimation {
    final duration = int.tryParse(_animationDurationController.text);
    return _animationNameController.text.trim().isNotEmpty &&
        _animationFrames.length >= 2 &&
        duration != null &&
        duration >= 1 &&
        duration <= 60000;
  }

  void _proposeTransformPolicy(SmartTileTransformPolicy policy) {
    setState(() {
      _transformProposal = _authoring.proposeTransformPolicy(policy);
    });
  }

  void _acceptTransformProposal() {
    final proposal = _transformProposal;
    if (proposal == null || !proposal.hasChanges) return;
    setState(() {
      _authoring.setTransformPolicy(proposal.proposedPolicy);
      _transformProposal = null;
    });
    _notifyDraftChanged();
  }

  void _discardTransformProposal() {
    if (_transformProposal == null) return;
    setState(() => _transformProposal = null);
  }

  void _toggleAnimationFrame({required int column, required int row}) {
    final frame = SmartTileFrameRef(
      atlasId: _authoring.state.atlasId,
      column: column,
      row: row,
    );
    setState(() {
      final frames = List<SmartTileFrameRef>.from(_animationFrames);
      final index = frames.indexOf(frame);
      if (index < 0) {
        frames.add(frame);
      } else {
        frames.removeAt(index);
      }
      _animationFrames = List<SmartTileFrameRef>.unmodifiable(frames);
    });
  }

  void _removeAnimationFrame(int index) {
    if (index < 0 || index >= _animationFrames.length) return;
    setState(() {
      final frames = List<SmartTileFrameRef>.from(_animationFrames)
        ..removeAt(index);
      _animationFrames = List<SmartTileFrameRef>.unmodifiable(frames);
    });
  }

  void _clearAnimationFrames() {
    setState(() => _animationFrames = const <SmartTileFrameRef>[]);
  }

  void _createAnimation() {
    if (!_canCreateAnimation) return;
    final duration = int.parse(_animationDurationController.text);
    final animation = _authoring.createAnimation(
      name: _animationNameController.text,
      frames: _animationFrames,
      durationMs: duration,
    );
    setState(() {
      _animationNameController.clear();
      _animationFrames = const <SmartTileFrameRef>[];
      _draftMessage = 'Animation « ${animation.name} » créée.';
    });
    _notifyDraftChanged();
  }

  List<SmartTileMaterialPickerItem> _materialPickerItems() {
    final allowed = <String, ProjectSmartTileMaterial>{
      for (final material in _authoring.state.materials) material.id: material,
    };
    final projectIds = widget.manifest.smartTileCatalog.materials
        .map((material) => material.id)
        .toSet();
    final all = <String, ProjectSmartTileMaterial>{
      for (final material in widget.manifest.smartTileCatalog.materials)
        material.id: material,
      ...allowed,
    }.values.toList()
      ..sort((left, right) => left.name.compareTo(right.name));
    return <SmartTileMaterialPickerItem>[
      for (final material in all)
        SmartTileMaterialPickerItem(
          material: material,
          isFromProject: projectIds.contains(material.id),
          isAllowed: allowed.containsKey(material.id),
          removalBlockedReason: allowed.containsKey(material.id)
              ? _materialRemovalReason(material.id)
              : null,
        ),
    ];
  }

  String? _materialRemovalReason(String materialId) {
    return switch (_authoring.materialRemovalBlocker(materialId)) {
      SmartTileMaterialRemovalBlocker.defaultMaterial =>
        'Choisissez d’abord une autre matière par défaut.',
      SmartTileMaterialRemovalBlocker.activeMaterial =>
        'Activez d’abord une autre matière.',
      SmartTileMaterialRemovalBlocker.mappedMaterial =>
        'Cette matière est encore utilisée par une forme.',
      null => null,
    };
  }

  void _activateMaterial(ProjectSmartTileMaterial material) {
    setState(() {
      if (!_authoring.state.materials
          .any((candidate) => candidate.id == material.id)) {
        _authoring.addMaterial(material);
      } else {
        _authoring.setActiveMaterial(material.id);
      }
    });
    _notifyDraftChanged();
  }

  void _setDefaultMaterial(String materialId) {
    setState(() => _authoring.setDefaultMaterial(materialId));
    _notifyDraftChanged();
  }

  void _toggleMaterial(String materialId) {
    final available = _materialPickerItems()
        .where((item) => item.material.id == materialId)
        .firstOrNull;
    if (available == null) return;
    setState(() {
      if (available.isAllowed) {
        _authoring.removeMaterial(materialId);
      } else {
        _authoring.addMaterial(available.material);
      }
    });
    _notifyDraftChanged();
  }

  void _createMaterial() {
    final name = _newMaterialNameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _authoring.createMaterial(name: name);
      _newMaterialNameController.clear();
    });
    _notifyDraftChanged();
  }

  Future<void> _selectConnectionProfile(
    SmartTileConnectionProfile profile,
  ) async {
    if (profile.id == SmartTileConnectionProfileId.custom) {
      setState(() {
        _selectedConnectionProfileId = profile.id;
        _customConnectionTopology = null;
      });
      return;
    }
    await _applyConnectionProfile(profile, profile.resolve());
  }

  void _selectCoveragePolicy(SmartTileCoveragePolicy policy) {
    setState(() => _authoring.setCoveragePolicy(policy));
    _notifyDraftChanged();
  }

  Future<void> _selectCustomConnectionTopology(
    SmartTileTopology topology,
  ) async {
    final profile = smartTileConnectionProfileById(
      SmartTileConnectionProfileId.custom,
    );
    await _applyConnectionProfile(
      profile,
      profile.resolve(customTopology: topology),
      customTopology: topology,
    );
  }

  Future<void> _applyConnectionProfile(
    SmartTileConnectionProfile profile,
    SmartTileConnectionConfiguration configuration, {
    SmartTileTopology? customTopology,
  }) async {
    final state = _authoring.state;
    final changesContract = state.topology != configuration.topology ||
        state.templateHint != configuration.templateHint;
    var clearMappings = false;
    if (changesContract &&
        (state.mappings.isNotEmpty || state.transitionCases.isNotEmpty)) {
      clearMappings = await showPokeMapBinaryConfirmationDialog(
        context,
        title: 'Changer le style de raccord',
        message:
            'Les formes déjà associées ne décrivent pas la même structure. Les retirer et appliquer « ${profile.label} » ?',
        secondaryLabel: 'Conserver le style actuel',
        primaryLabel: 'Changer et retirer les associations',
        primaryIsDestructive: true,
        icon: CupertinoIcons.arrow_2_circlepath,
      );
      if (!clearMappings || !mounted) return;
    }
    setState(() {
      _authoring.configureConnections(
        configuration,
        clearMappings: clearMappings,
      );
      _selectedConnectionProfileId = profile.id;
      _customConnectionTopology = customTopology;
      if (changesContract) {
        if (_session.state.guideId != null) {
          _session.clearGuideChoice();
        }
        _guidePlacement = null;
        _correctionNumber = null;
        _pendingAtlasFrame = null;
        _selectedTransitionCaseId = null;
      }
    });
    _notifyDraftChanged();
  }

  void _selectUsage(SmartTileUsage usage) {
    setState(() {
      _session.chooseUsage(usage);
      _authoring.selectUsage(usage);
      _selectedMask = null;
      _selectedTransitionCaseId = null;
      _lastMappedFrame = null;
      _pendingAtlasFrame = null;
      _animationFrames = const <SmartTileFrameRef>[];
      _lastCandidateId = null;
      _selectedRenderChannel = SmartTileRenderChannel.ground;
      _guidePlacement = null;
      _correctionNumber = null;
      _placementMessage = null;
      _selectedConnectionProfileId = null;
      _customConnectionTopology = null;
      _testLabController = null;
      _testLabTool = SmartTileLabTool.pencil;
    });
    _notifyDraftChanged();
  }

  void _disableGuide() {
    if (_session.state.guideId == null) return;
    setState(() {
      _session.clearGuideChoice();
      _guidePlacement = null;
      _correctionNumber = null;
      _placementMessage = null;
    });
    _notifyDraftChanged();
  }

  Future<void> _selectGuide(SmartTileGuideId guideId) async {
    const configuration = SmartTileConnectionConfiguration(
      topology: SmartTileTopology.wangCorner4,
      templateHint: SmartTileTemplateHint.corner12,
      coveragePolicy: SmartTileCoveragePolicy.complete,
    );
    final state = _authoring.state;
    final changesContract = state.topology != configuration.topology ||
        state.templateHint != configuration.templateHint;
    var clearMappings = false;
    if (changesContract &&
        (state.mappings.isNotEmpty || state.transitionCases.isNotEmpty)) {
      clearMappings = await showPokeMapBinaryConfirmationDialog(
        context,
        title: 'Adapter les formes au guide ERW ?',
        message:
            'Le guide utilise une structure par coins. Les associations incompatibles devront être retirées.',
        secondaryLabel: 'Conserver mes formes',
        primaryLabel: 'Adapter et continuer',
        primaryIsDestructive: true,
        icon: CupertinoIcons.square_grid_3x2,
      );
      if (!clearMappings || !mounted) return;
    }
    setState(() {
      final profile = smartTileConnectionProfileById(
        SmartTileConnectionProfileId.corners,
      );
      _authoring.configureConnections(
        configuration,
        clearMappings: clearMappings,
      );
      _selectedConnectionProfileId = profile.id;
      _customConnectionTopology = null;
      _session.chooseGuide(guideId);
      _guidePlacement = null;
      _correctionNumber = null;
      _placementMessage = null;
      _selectedTransitionCaseId = null;
    });
    _notifyDraftChanged();
  }

  void _resetPlacementSource() {
    setState(() {
      _session.resetPlacementSource();
      _clearSourceImageSelection();
      _selectedRegisteredAtlasId = null;
      _guidePlacement = null;
      _correctionNumber = null;
      _placementMessage = null;
      _authoring.clearMappings();
    });
    _notifyDraftChanged();
  }

  void _selectGuideAtlasCell({
    required SmartTileGuideDefinition guide,
    required int column,
    required int row,
  }) {
    final correctionNumber = _correctionNumber;
    final currentPlacement = _guidePlacement;
    if (correctionNumber != null && currentPlacement?.isValid == true) {
      final guideCell = guide.cellByNumber(correctionNumber);
      _authoring.replaceAtlasCandidate(
        mask: guideCell.mask,
        column: column,
        row: row,
        candidateId: 'guide_cell_${guideCell.number}',
      );
      final correctedFrames = <SmartTileGuidePlacedFrame>[
        for (final frame in currentPlacement!.frames)
          if (frame.guideCell.number == correctionNumber)
            SmartTileGuidePlacedFrame(
              guideCell: frame.guideCell,
              column: column,
              row: row,
            )
          else
            frame,
      ];
      setState(() {
        _guidePlacement = SmartTileGuidePlacementResult(
          frames: correctedFrames,
          outOfBoundsNumbers: const <int>[],
        );
        _correctionNumber = null;
        _placementMessage = 'Case $correctionNumber corrigée.';
      });
      _notifyDraftChanged();
      return;
    }

    final placement = placeSmartTileGuide(
      guide: guide,
      geometry: _session.state.gridGeometry!,
      anchorColumn: column,
      anchorRow: row,
    );
    if (!placement.isValid) {
      setState(() {
        _guidePlacement = placement;
        _correctionNumber = null;
        _placementMessage =
            'Le guide dépasse l’atlas (cases ${placement.outOfBoundsNumbers.join(', ')}). Choisissez la vraie case nº 1.';
        _session.clearAnchor();
      });
      _notifyDraftChanged();
      return;
    }

    _session.placeGuide(anchorColumn: column, anchorRow: row);
    _authoring.applyGuidePlacement(guide: guide, placement: placement);
    setState(() {
      _guidePlacement = placement;
      _correctionNumber = null;
      _placementMessage =
          '${placement.frames.length} cellules associées — prêt pour le banc d’essai.';
    });
    _notifyDraftChanged();
  }

  void _selectFormsAtlasCell({required int column, required int row}) {
    final cell = GridPos(x: column, y: row);
    final selectionStart =
        _atlasSelectionMode == SmartTileAtlasSelectionMode.rectangle
            ? _atlasSelectionStart
            : null;
    if (_atlasSelectionMode == SmartTileAtlasSelectionMode.rectangle &&
        selectionStart == null) {
      setState(() {
        _atlasSelectionStart = cell;
        _pendingAtlasFrame = SmartTileFrameRef(
          atlasId: _authoring.state.atlasId,
          column: column,
          row: row,
        );
      });
      return;
    }
    final geometry = _session.state.gridGeometry!;
    final frame = selectSmartTileAtlasFrame(
      atlasId: _authoring.state.atlasId,
      start: selectionStart ?? cell,
      end: cell,
      columns: geometry.columns,
      rows: geometry.rows,
    );
    if (selectionStart != null) {
      setState(() => _atlasSelectionStart = null);
    }
    _selectFormsAtlasFrame(frame);
  }

  void _selectFormsAtlasFrame(SmartTileFrameRef frame) {
    final transitionCaseId = _selectedTransitionCaseId;
    if (transitionCaseId != null) {
      _mapTransitionAtlasFrame(
        caseId: transitionCaseId,
        frame: frame,
        addVariant: HardwareKeyboard.instance.isShiftPressed,
      );
      return;
    }
    if (_selectedMask == null) {
      setState(() {
        _pendingAtlasFrame = frame;
      });
      return;
    }
    _mapAtlasFrame(
      frame: frame,
      addVariant: HardwareKeyboard.instance.isShiftPressed,
    );
  }

  void _selectForm(int mask) {
    final pending = _pendingAtlasFrame;
    setState(() {
      _selectedMask = mask;
      _selectedTransitionCaseId = null;
    });
    if (pending == null) return;
    _mapAtlasFrame(
      frame: pending,
      explicitMask: mask,
      addVariant: HardwareKeyboard.instance.isShiftPressed,
    );
  }

  void _clearPendingAtlasFrame() {
    setState(() {
      _pendingAtlasFrame = null;
      _atlasSelectionStart = null;
    });
  }

  void _changeAtlasSelectionMode(SmartTileAtlasSelectionMode mode) {
    if (_atlasSelectionMode == mode) return;
    setState(() {
      _atlasSelectionMode = mode;
      _atlasSelectionStart = null;
      _pendingAtlasFrame = null;
    });
  }

  void _createTransitionCase() {
    final rule = _authoring.createTransitionCase();
    setState(() {
      _selectedTransitionCaseId = rule.id;
      _selectedMask = null;
    });
    _notifyDraftChanged();
  }

  void _selectTransitionCase(String caseId) {
    setState(() {
      _selectedTransitionCaseId = caseId;
      _selectedMask = null;
    });
  }

  void _removeTransitionCase(String caseId) {
    _authoring.removeTransitionCase(caseId);
    setState(() {
      if (_selectedTransitionCaseId == caseId) {
        _selectedTransitionCaseId = null;
      }
    });
    _notifyDraftChanged();
  }

  void _setTransitionCaseCenter(
    String caseId,
    SmartTileSlotMatch match,
  ) {
    setState(() {
      _authoring.setTransitionCaseCenter(caseId: caseId, match: match);
    });
    _notifyDraftChanged();
  }

  void _setTransitionCaseSlot(
    String caseId,
    SmartTileAuthoringSlot slot,
    SmartTileSlotMatch match,
  ) {
    setState(() {
      _authoring.setTransitionCaseSlot(
        caseId: caseId,
        slot: slot,
        match: match,
      );
    });
    _notifyDraftChanged();
  }

  void _mapTransitionAtlasFrame({
    required String caseId,
    required SmartTileFrameRef frame,
    bool addVariant = false,
  }) {
    final rule = _authoring.state.transitionCases
        .where((candidate) => candidate.id == caseId)
        .first;
    final candidates = rule.candidates;
    final column = frame.column;
    final row = frame.row;
    String candidateId;
    if (candidates.isNotEmpty && !addVariant) {
      candidateId = candidates.first.id;
      _authoring.replaceTransitionCaseAtlasCandidate(
        caseId: caseId,
        column: column,
        row: row,
        candidateId: candidateId,
        channel: _selectedRenderChannel,
        columnSpan: frame.columnSpan,
        rowSpan: frame.rowSpan,
      );
    } else {
      var sequence = candidates.length + 1;
      var proposed = 'transition_${column}_${row}_$sequence';
      while (candidates.any((candidate) => candidate.id == proposed)) {
        sequence += 1;
        proposed = 'transition_${column}_${row}_$sequence';
      }
      candidateId = proposed;
      _authoring.addTransitionCaseAtlasVariant(
        caseId: caseId,
        column: column,
        row: row,
        candidateId: candidateId,
        channel: _selectedRenderChannel,
        columnSpan: frame.columnSpan,
        rowSpan: frame.rowSpan,
      );
    }
    setState(() {
      _lastMappedFrame = frame;
      _pendingAtlasFrame = null;
      _lastCandidateId = candidateId;
    });
    _notifyDraftChanged();
  }

  void _mapAtlasFrame({
    required SmartTileFrameRef frame,
    int? explicitMask,
    bool addVariant = false,
  }) {
    final mask = explicitMask ?? _selectedMask;
    if (mask == null) {
      return;
    }
    final candidates =
        _authoring.state.mappings[mask] ?? const <SmartTileCandidate>[];
    final column = frame.column;
    final row = frame.row;
    String candidateId;
    if (_session.state.usage == SmartTileUsage.forestSurface &&
        _selectedRenderChannel != SmartTileRenderChannel.ground &&
        candidates.isNotEmpty) {
      candidateId = candidates.last.id;
      _authoring.addVisualPart(
        mask: mask,
        candidateId: candidateId,
        part: SmartTileVisualPart(
          source: SmartTileVisualSource.frame(frame: frame),
          channel: _selectedRenderChannel,
          footprintWidth: frame.columnSpan,
          footprintHeight: frame.rowSpan,
          drawOrder:
              _selectedRenderChannel == SmartTileRenderChannel.canopy ? 10 : 0,
        ),
      );
    } else if (candidates.isNotEmpty && !addVariant) {
      candidateId = candidates.first.id;
      _authoring.replaceAtlasCandidate(
        mask: mask,
        column: column,
        row: row,
        candidateId: candidateId,
        channel: _selectedRenderChannel,
        columnSpan: frame.columnSpan,
        rowSpan: frame.rowSpan,
      );
    } else {
      var sequence = candidates.length + 1;
      var proposed = 'cell_${column}_${row}_$sequence';
      while (candidates.any((candidate) => candidate.id == proposed)) {
        sequence += 1;
        proposed = 'cell_${column}_${row}_$sequence';
      }
      candidateId = proposed;
      _authoring.addAtlasVariant(
        mask: mask,
        column: column,
        row: row,
        candidateId: candidateId,
        channel: _selectedRenderChannel,
        columnSpan: frame.columnSpan,
        rowSpan: frame.rowSpan,
      );
    }
    setState(() {
      _lastMappedFrame = frame;
      _pendingAtlasFrame = null;
      _lastCandidateId = candidateId;
    });
    _notifyDraftChanged();
  }

  void _mapAnimationToForm(int mask, String animationId) {
    final variants =
        _authoring.state.mappings[mask] ?? const <SmartTileCandidate>[];
    final candidateId = 'animation_${animationId}_${variants.length + 1}';
    _authoring.addAnimationVariant(
      mask: mask,
      animationId: animationId,
      candidateId: candidateId,
      channel: _selectedRenderChannel,
    );
    setState(() {
      _selectedMask = mask;
      _lastCandidateId = candidateId;
      _pendingAtlasFrame = null;
    });
    _notifyDraftChanged();
  }

  void _mapAnimationToTransitionCase(String caseId, String animationId) {
    final rule = _authoring.state.transitionCases
        .where((candidate) => candidate.id == caseId)
        .first;
    final candidateId =
        'transition_animation_${animationId}_${rule.candidates.length + 1}';
    _authoring.addTransitionCaseAnimationVariant(
      caseId: caseId,
      animationId: animationId,
      candidateId: candidateId,
      channel: _selectedRenderChannel,
    );
    setState(() {
      _selectedTransitionCaseId = caseId;
      _selectedMask = null;
      _lastCandidateId = candidateId;
      _pendingAtlasFrame = null;
    });
    _notifyDraftChanged();
  }

  void _updateVariantWeight(int mask, String candidateId, int weight) {
    setState(() {
      _authoring.updateCandidateWeight(
        mask: mask,
        candidateId: candidateId,
        weight: weight,
      );
    });
    _notifyDraftChanged();
  }

  void _updateTransitionCaseVariantWeight(
    String caseId,
    String candidateId,
    int weight,
  ) {
    setState(() {
      _authoring.updateTransitionCaseCandidateWeight(
        caseId: caseId,
        candidateId: candidateId,
        weight: weight,
      );
    });
    _notifyDraftChanged();
  }

  void _updateVariantVisualPart(
    int mask,
    String candidateId,
    int partIndex,
    SmartTileVisualPart part,
  ) {
    setState(() {
      _authoring.updateCandidateVisualPart(
        mask: mask,
        candidateId: candidateId,
        partIndex: partIndex,
        part: part,
      );
    });
    _notifyDraftChanged();
  }

  void _updateTransitionCaseVariantVisualPart(
    String caseId,
    String candidateId,
    int partIndex,
    SmartTileVisualPart part,
  ) {
    setState(() {
      _authoring.updateTransitionCaseCandidateVisualPart(
        caseId: caseId,
        candidateId: candidateId,
        partIndex: partIndex,
        part: part,
      );
    });
    _notifyDraftChanged();
  }

  void _moveVariant(int mask, String candidateId, int newIndex) {
    setState(() {
      _authoring.reorderCandidate(
        mask: mask,
        candidateId: candidateId,
        newIndex: newIndex,
      );
    });
    _notifyDraftChanged();
  }

  void _moveTransitionCaseVariant(
    String caseId,
    String candidateId,
    int newIndex,
  ) {
    setState(() {
      _authoring.reorderTransitionCaseCandidate(
        caseId: caseId,
        candidateId: candidateId,
        newIndex: newIndex,
      );
    });
    _notifyDraftChanged();
  }

  void _removeVariant(int mask, String candidateId) {
    setState(() {
      _authoring.removeCandidate(mask: mask, candidateId: candidateId);
      if (_lastCandidateId == candidateId) _lastCandidateId = null;
    });
    _notifyDraftChanged();
  }

  void _removeTransitionCaseVariant(String caseId, String candidateId) {
    setState(() {
      _authoring.removeTransitionCaseCandidate(
        caseId: caseId,
        candidateId: candidateId,
      );
      if (_lastCandidateId == candidateId) _lastCandidateId = null;
    });
    _notifyDraftChanged();
  }

  void _addCanopyPart() {
    final mask = _selectedMask;
    final frame = _lastMappedFrame;
    final candidateId = _lastCandidateId;
    if (mask == null || frame == null || candidateId == null) {
      return;
    }
    _authoring.addVisualPart(
      mask: mask,
      candidateId: candidateId,
      part: SmartTileVisualPart(
        source: SmartTileVisualSource.frame(frame: frame),
        channel: SmartTileRenderChannel.canopy,
        offsetY: -frame.rowSpan * 32,
        footprintWidth: frame.columnSpan,
        footprintHeight: frame.rowSpan,
        anchorX: frame.columnSpan * 16,
        anchorY: frame.rowSpan * 32,
        drawOrder: 10,
      ),
    );
    setState(() {
      _draftMessage = 'Couche de canopée ajoutée au candidat.';
    });
    _notifyDraftChanged();
  }

  void _moveToTest() {
    setState(() {
      _testLabController = null;
      _testLabTool = SmartTileLabTool.pencil;
      _session.moveToTest();
    });
    _flushDraftAfterStepChange();
  }

  void _moveToPublish() {
    setState(() {
      _session.moveToPublish();
      _seedPublicationTarget();
    });
    _flushDraftAfterStepChange();
  }

  void _seedPublicationTarget() {
    final capturedMap = widget.capturedMap;
    final canUseMap = widget.isCapturedMapAvailable && capturedMap != null;
    _publicationTargetKind = canUseMap
        ? SmartTilePublicationTargetKind.map
        : SmartTilePublicationTargetKind.library;
    _publicationLayerIdController.text =
        SmartTilePublicationService.suggestLayerId(
      presetId: _authoring.state.id,
      existingLayerIds:
          capturedMap?.layers.map((layer) => layer.id) ?? const <String>[],
    );
    _publicationLayerNameController.text = _authoring.state.name;
    _clearPublicationPlanState();
  }

  void _changePublicationTarget(SmartTilePublicationTargetKind target) {
    if (_publicationTargetKind == target) return;
    setState(() {
      _publicationTargetKind = target;
      _clearPublicationPlanState();
    });
  }

  void _clearPublicationPlan() {
    if (_publicationPlan == null &&
        _publicationErrorCode == null &&
        _publicationErrorMessage == null) {
      return;
    }
    setState(_clearPublicationPlanState);
  }

  void _clearPublicationPlanState() {
    _publicationPlan = null;
    _publicationApplied = false;
    _publicationErrorCode = null;
    _publicationErrorMessage = null;
  }

  void _resetPublicationState() {
    _publicationTargetKind = SmartTilePublicationTargetKind.library;
    _publicationLayerIdController.clear();
    _publicationLayerNameController.clear();
    _publicationBusy = false;
    _clearPublicationPlanState();
  }

  Future<void> _planPublication(List<SmartTileDiagnostic> diagnostics) async {
    final service = widget.publicationService;
    final projectRootPath = widget.projectRootPath;
    final flush = widget.onDraftFlush;
    if (service == null || projectRootPath == null || flush == null) {
      setState(() {
        _publicationErrorCode = 'smart_tile.publish.session_unavailable';
        _publicationErrorMessage =
            'La session canonique du projet n’est pas disponible.';
      });
      return;
    }
    final draft = _currentAuthoringDraft();
    final target = switch (_publicationTargetKind) {
      SmartTilePublicationTargetKind.library =>
        const SmartTilePublicationTarget.library(),
      SmartTilePublicationTargetKind.map => SmartTilePublicationTarget.map(
          mapId: widget.launchContext.capturedMapId ?? '',
          layerId: _publicationLayerIdController.text,
          layerName: _publicationLayerNameController.text,
        ),
    };
    setState(() {
      _publicationBusy = true;
      _publicationErrorCode = null;
      _publicationErrorMessage = null;
    });
    try {
      _notifyDraftChanged();
      final plan = await service.plan(
        projectRootPath: projectRootPath,
        draftId: draft.id,
        presetId: draft.targetPresetId,
        target: target,
        flushDraft: flush,
        diagnostics: diagnostics,
      );
      if (!mounted) return;
      setState(() => _publicationPlan = plan);
    } on Object catch (error) {
      if (!mounted) return;
      _acceptPublicationFailure(error);
    } finally {
      if (mounted) setState(() => _publicationBusy = false);
    }
  }

  Future<void> _applyPublication() async {
    final service = widget.publicationService;
    final projectRootPath = widget.projectRootPath;
    final plan = _publicationPlan;
    if (service == null || projectRootPath == null || plan == null) return;
    setState(() {
      _publicationBusy = true;
      _publicationErrorCode = null;
      _publicationErrorMessage = null;
    });
    try {
      final result = await service.apply(
        plan,
        projectRootPath: projectRootPath,
      );
      await widget.onPublicationApplied?.call(result);
      if (!mounted) return;
      setState(() {
        _publicationApplied = true;
        _draftMessage = plan.layerId == null
            ? 'Smart Tile publié dans la bibliothèque.'
            : 'Smart Tile publié et couche « ${plan.layerId} » ouverte.';
      });
    } on Object catch (error) {
      if (!mounted) return;
      _acceptPublicationFailure(error);
    } finally {
      if (mounted) setState(() => _publicationBusy = false);
    }
  }

  void _acceptPublicationFailure(Object error) {
    if (error is SmartTilePublicationException) {
      setState(() {
        _publicationErrorCode = error.code;
        _publicationErrorMessage = error.message;
      });
      return;
    }
    final failure = EditorAuthoringMutationFailure.capture(error);
    setState(() {
      _publicationErrorCode = failure.code;
      _publicationErrorMessage = failure.message;
    });
  }

  ProjectSmartTileAuthoringDraft _currentAuthoringDraft() {
    final stage = SmartTileAuthoringStage.values.byName(
      _session.state.wizardStep.name,
    );
    return _authoring.compileAuthoringDraft(
      lastStage: stage,
      guideId: _session.state.guideId?.name,
      clearGuide: _session.state.guideId == null,
      sourceTilesetIds: <String>[
        if (_selectedSourceTilesetId case final id?) id,
      ],
    );
  }

  void _notifyDraftChanged() {
    final callback = widget.onDraftChanged;
    if (callback == null || _authoring.state.usage == null) return;
    callback(_currentAuthoringDraft());
  }

  void _flushDraftAfterStepChange() {
    _notifyDraftChanged();
    final flush = widget.onDraftFlush;
    if (flush != null) unawaited(flush());
  }

  SmartTileTestLayerController _testLabFor({
    required ProjectSmartTilePreset preset,
    required ProjectSmartTileCatalog catalog,
  }) {
    final current = _testLabController;
    if (current != null && current.preset == preset) {
      return current;
    }
    final next = SmartTileTestLayerController(
      preset: preset,
      catalog: catalog,
    );
    _testLabController = next;
    _testLabTool = SmartTileLabTool.pencil;
    return next;
  }

  bool _labIsPublishable({
    required ProjectSmartTilePreset preset,
    required List<SmartTileLabScenarioResult> scenarios,
  }) {
    if (scenarios.isEmpty) return false;
    final resolved = scenarios.where((scenario) => scenario.isResolved).length;
    if (preset.coveragePolicy == SmartTileCoveragePolicy.sparse) {
      final hasBlockingResolution = scenarios.any(
        (scenario) => switch (scenario.inspection.resolution.status) {
          SmartTileResolutionStatus.ambiguousRule ||
          SmartTileResolutionStatus.noCandidate ||
          SmartTileResolutionStatus.invalidRule =>
            true,
          SmartTileResolutionStatus.resolved ||
          SmartTileResolutionStatus.noIntent ||
          SmartTileResolutionStatus.noMatchingRule =>
            false,
        },
      );
      return resolved > 0 && !hasBlockingResolution;
    }
    return resolved == scenarios.length;
  }

  void _applyLabTarget(SmartTileLabTarget target) {
    final controller = _testLabController;
    if (controller == null) return;
    setState(() => controller.applyTarget(target, tool: _testLabTool));
  }

  void _resetLab() {
    final controller = _testLabController;
    if (controller == null) return;
    setState(controller.reset);
  }

  void _loadLabScenario(int mask) {
    final controller = _testLabController;
    if (controller == null) return;
    setState(() => controller.loadCanonicalScenario(mask));
  }

  void _openDiagnostic(SmartTileDiagnostic diagnostic) {
    setState(() {
      _focusedMask = diagnostic.mask ?? diagnostic.missingMasks.firstOrNull;
      _focusedRuleId = diagnostic.ruleId;
      _tab = SmartTilesStudioTab.rules;
    });
  }

  void _configureDraftAtlas(SmartTileGridGeometry geometry) {
    final id = _authoring.state.id;
    _authoring.configureAtlas(
      atlasId: '$id-atlas',
      atlasName: 'Atlas — ${_authoring.state.name}',
      tilesetId: _selectedSourceTilesetId ?? '',
      geometry: geometry,
    );
  }

  String _nextDraftId() {
    const base = 'smart-tile';
    final occupied = widget.manifest.smartTileCatalog.presets
        .map((preset) => preset.id)
        .toSet();
    if (!occupied.contains(base)) {
      return base;
    }
    var suffix = 2;
    while (occupied.contains('$base-$suffix')) {
      suffix += 1;
    }
    return '$base-$suffix';
  }

  String _nextPatternId() {
    const base = 'motif';
    final occupied = widget.manifest.smartTileCatalog.patterns
        .map((pattern) => pattern.id)
        .toSet();
    if (!occupied.contains(base)) return base;
    var suffix = 2;
    while (occupied.contains('$base-$suffix')) {
      suffix += 1;
    }
    return '$base-$suffix';
  }

  List<SmartTileLibraryItem> _filterItems(
    List<SmartTileLibraryItem> items,
  ) {
    final normalizedQuery = _query.trim().toLowerCase();
    return items.where((item) {
      final usageMatches = switch (_usageFilter) {
        _LibraryUsageFilter.all => true,
        _LibraryUsageFilter.terrain => item.usage == SmartTileUsage.terrain,
        _LibraryUsageFilter.path => item.usage == SmartTileUsage.path,
        _LibraryUsageFilter.forestSurface =>
          item.usage == SmartTileUsage.forestSurface,
      };
      return usageMatches &&
          (normalizedQuery.isEmpty ||
              item.name.toLowerCase().contains(normalizedQuery) ||
              item.id.toLowerCase().contains(normalizedQuery));
    }).toList(growable: false);
  }
}

class _SmartTileProjectImagePicker extends StatefulWidget {
  const _SmartTileProjectImagePicker({
    super.key,
    required this.tilesets,
  });

  final List<ProjectTilesetEntry> tilesets;

  @override
  State<_SmartTileProjectImagePicker> createState() =>
      _SmartTileProjectImagePickerState();
}

class _SmartTileProjectImagePickerState
    extends State<_SmartTileProjectImagePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final normalizedQuery = _query.trim().toLowerCase();
    final visibleTilesets = widget.tilesets.where((tileset) {
      if (normalizedQuery.isEmpty) {
        return true;
      }
      return tileset.name.toLowerCase().contains(normalizedQuery) ||
          tileset.id.toLowerCase().contains(normalizedQuery) ||
          tileset.relativePath.toLowerCase().contains(normalizedQuery);
    }).toList(growable: false)
      ..sort((left, right) => left.name.compareTo(right.name));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PokeMapTextField(
            label: 'Rechercher',
            fieldKey: const Key('smart-tiles-source-search'),
            autofocus: true,
            placeholder: 'Nom, identifiant ou chemin du tileset',
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          Text(
            '${visibleTilesets.length} résultat(s) sur ${widget.tilesets.length}',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: visibleTilesets.isEmpty
                ? const PokeMapEmptyState(
                    title: 'Aucun tileset trouvé',
                    description: 'Essayez un autre nom ou chemin.',
                    icon: Icon(CupertinoIcons.search),
                  )
                : ListView.builder(
                    itemCount: visibleTilesets.length,
                    itemBuilder: (context, index) {
                      final tileset = visibleTilesets[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: PokeMapAssetCard(
                          key: Key(
                            'smart-tiles-source-tileset-${tileset.id}',
                          ),
                          thumbnail: const Icon(
                            CupertinoIcons.photo_on_rectangle,
                            size: 20,
                          ),
                          label: tileset.name,
                          description: tileset.relativePath,
                          onPressed: () => Navigator.of(context).pop(tileset),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SmartTileRegisteredAtlasPicker extends StatefulWidget {
  const _SmartTileRegisteredAtlasPicker({required this.atlases});

  final List<ProjectSmartTileAtlas> atlases;

  @override
  State<_SmartTileRegisteredAtlasPicker> createState() =>
      _SmartTileRegisteredAtlasPickerState();
}

class _SmartTileRegisteredAtlasPickerState
    extends State<_SmartTileRegisteredAtlasPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final visibleAtlases = widget.atlases.where((atlas) {
      return normalizedQuery.isEmpty ||
          atlas.name.toLowerCase().contains(normalizedQuery) ||
          atlas.id.toLowerCase().contains(normalizedQuery) ||
          atlas.tilesetId.toLowerCase().contains(normalizedQuery);
    }).toList(growable: false)
      ..sort((left, right) => left.name.compareTo(right.name));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PokeMapTextField(
            label: 'Rechercher',
            fieldKey: const Key('smart-tiles-registered-atlas-search'),
            autofocus: true,
            placeholder: 'Nom ou identifiant de l’atlas',
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: visibleAtlases.isEmpty
                ? const PokeMapEmptyState(
                    title: 'Aucun atlas trouvé',
                    description: 'Essayez un autre nom.',
                    icon: Icon(CupertinoIcons.search),
                  )
                : ListView.builder(
                    itemCount: visibleAtlases.length,
                    itemBuilder: (context, index) {
                      final atlas = visibleAtlases[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: PokeMapAssetCard(
                          key: Key(
                            'smart-tiles-registered-atlas-${atlas.id}',
                          ),
                          thumbnail: const Icon(
                            CupertinoIcons.square_grid_3x2,
                            size: 20,
                          ),
                          label: atlas.name,
                          onPressed: () => Navigator.of(context).pop(atlas),
                          trailing: PokeMapBadge(
                            label: '${atlas.columns} × ${atlas.rows}',
                            variant: PokeMapBadgeVariant.info,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

typedef _SmartTileAtlasCell = ({int column, int row});

class _SmartTileAtlasMappingViewport extends StatelessWidget {
  const _SmartTileAtlasMappingViewport({
    required this.geometry,
    required this.image,
    required this.selectedFrame,
    required this.enabled,
    required this.onCellSelected,
    this.guide,
    this.placement,
  });

  final SmartTileGridGeometry geometry;
  final SmartTileAtlasImage? image;
  final SmartTileFrameRef? selectedFrame;
  final bool enabled;
  final ValueChanged<_SmartTileAtlasCell> onCellSelected;
  final SmartTileGuideDefinition? guide;
  final SmartTileGuidePlacementResult? placement;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        const viewportHeight = 420.0;
        final availableWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 720.0;
        final sourceWidth = geometry.imageWidth.toDouble();
        final sourceHeight = geometry.imageHeight.toDouble();
        final scale = math.min(
          availableWidth / sourceWidth,
          viewportHeight / sourceHeight,
        );
        final displayWidth = math.max(1.0, sourceWidth * scale);
        final displayHeight = math.max(1.0, sourceHeight * scale);

        return Container(
          height: viewportHeight,
          decoration: BoxDecoration(
            color: colors.surfaceSubtle,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.borderSubtle),
          ),
          clipBehavior: Clip.antiAlias,
          child: InteractiveViewer(
            constrained: false,
            alignment: Alignment.center,
            minScale: 0.5,
            maxScale: 16,
            boundaryMargin: const EdgeInsets.all(160),
            child: Semantics(
              button: enabled,
              enabled: enabled,
              label: enabled
                  ? 'Atlas ${geometry.columns} par ${geometry.rows}, choisir une cellule'
                  : 'Atlas ${geometry.columns} par ${geometry.rows}, choisir d’abord une signature',
              child: GestureDetector(
                key: const Key('smart-tiles-atlas-viewport'),
                behavior: HitTestBehavior.opaque,
                onTapDown: enabled
                    ? (details) {
                        final cell = _atlasCellAt(
                          localPosition: details.localPosition,
                          displaySize: Size(displayWidth, displayHeight),
                          geometry: geometry,
                        );
                        if (cell != null) {
                          onCellSelected(cell);
                        }
                      }
                    : null,
                child: SizedBox(
                  width: displayWidth,
                  height: displayHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      if (image != null)
                        Image.memory(
                          image!.bytes,
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.none,
                          gaplessPlayback: true,
                          errorBuilder: (context, error, stackTrace) =>
                              ColoredBox(color: colors.surfaceSubtle),
                        )
                      else
                        ColoredBox(color: colors.surfaceSubtle),
                      CustomPaint(
                        painter: _SmartTileAtlasGridPainter(
                          geometry: geometry,
                          selectedFrame: selectedFrame,
                          lineColor:
                              colors.borderStrong.withValues(alpha: 0.62),
                          selectionColor:
                              colors.brandPrimary.withValues(alpha: 0.24),
                          selectionBorderColor: colors.brandPrimary,
                        ),
                      ),
                      if (guide != null && placement?.isValid == true)
                        IgnorePointer(
                          child: CustomPaint(
                            key: const Key('smart-tiles-guide-overlay'),
                            painter: SmartTileGuideOverlayPainter(
                              geometry: geometry,
                              placement: placement!,
                              fillColor: colors.brandPrimarySoft
                                  .withValues(alpha: 0.58),
                              borderColor: colors.brandPrimary,
                              anchorColor:
                                  colors.success.withValues(alpha: 0.58),
                              textColor: colors.textPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

_SmartTileAtlasCell? _atlasCellAt({
  required Offset localPosition,
  required Size displaySize,
  required SmartTileGridGeometry geometry,
}) {
  if (displaySize.width <= 0 || displaySize.height <= 0) {
    return null;
  }
  final pixelX = localPosition.dx / displaySize.width * geometry.imageWidth;
  final pixelY = localPosition.dy / displaySize.height * geometry.imageHeight;
  final relativeX = pixelX - geometry.originX - geometry.marginX;
  final relativeY = pixelY - geometry.originY - geometry.marginY;
  if (relativeX < 0 || relativeY < 0) {
    return null;
  }
  final stepX = geometry.cellWidth + geometry.spacingX;
  final stepY = geometry.cellHeight + geometry.spacingY;
  final column = relativeX ~/ stepX;
  final row = relativeY ~/ stepY;
  if (column < 0 ||
      row < 0 ||
      column >= geometry.columns ||
      row >= geometry.rows) {
    return null;
  }
  final withinCellX = relativeX - column * stepX;
  final withinCellY = relativeY - row * stepY;
  if (withinCellX >= geometry.cellWidth || withinCellY >= geometry.cellHeight) {
    return null;
  }
  return (column: column, row: row);
}

class _SmartTileAtlasGridPainter extends CustomPainter {
  const _SmartTileAtlasGridPainter({
    required this.geometry,
    required this.selectedFrame,
    required this.lineColor,
    required this.selectionColor,
    required this.selectionBorderColor,
  });

  final SmartTileGridGeometry geometry;
  final SmartTileFrameRef? selectedFrame;
  final Color lineColor;
  final Color selectionColor;
  final Color selectionBorderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / geometry.imageWidth;
    final scaleY = size.height / geometry.imageHeight;
    final originX = (geometry.originX + geometry.marginX) * scaleX;
    final originY = (geometry.originY + geometry.marginY) * scaleY;
    final stepX = (geometry.cellWidth + geometry.spacingX) * scaleX;
    final stepY = (geometry.cellHeight + geometry.spacingY) * scaleY;
    final cellWidth = geometry.cellWidth * scaleX;
    final cellHeight = geometry.cellHeight * scaleY;
    final gridPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..isAntiAlias = false;

    for (var column = 0; column < geometry.columns; column += 1) {
      final left = originX + column * stepX;
      canvas.drawLine(
        Offset(left, originY),
        Offset(left, originY + (geometry.rows - 1) * stepY + cellHeight),
        gridPaint,
      );
      canvas.drawLine(
        Offset(left + cellWidth, originY),
        Offset(
          left + cellWidth,
          originY + (geometry.rows - 1) * stepY + cellHeight,
        ),
        gridPaint,
      );
    }
    for (var row = 0; row < geometry.rows; row += 1) {
      final top = originY + row * stepY;
      canvas.drawLine(
        Offset(originX, top),
        Offset(originX + (geometry.columns - 1) * stepX + cellWidth, top),
        gridPaint,
      );
      canvas.drawLine(
        Offset(originX, top + cellHeight),
        Offset(
          originX + (geometry.columns - 1) * stepX + cellWidth,
          top + cellHeight,
        ),
        gridPaint,
      );
    }

    final selected = selectedFrame;
    if (selected == null ||
        selected.column >= geometry.columns ||
        selected.row >= geometry.rows) {
      return;
    }
    final selectedRect = Rect.fromLTWH(
      originX + selected.column * stepX,
      originY + selected.row * stepY,
      cellWidth,
      cellHeight,
    );
    canvas.drawRect(
      selectedRect,
      Paint()
        ..color = selectionColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = false,
    );
    canvas.drawRect(
      selectedRect,
      Paint()
        ..color = selectionBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..isAntiAlias = false,
    );
  }

  @override
  bool shouldRepaint(covariant _SmartTileAtlasGridPainter oldDelegate) {
    return oldDelegate.geometry != geometry ||
        oldDelegate.selectedFrame != selectedFrame ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.selectionColor != selectionColor ||
        oldDelegate.selectionBorderColor != selectionBorderColor;
  }
}

class _InspectorValue extends StatelessWidget {
  const _InspectorValue({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _tabLabel(SmartTilesStudioTab tab) => switch (tab) {
      SmartTilesStudioTab.atlas => 'Atlas',
      SmartTilesStudioTab.rules => 'Règles',
      SmartTilesStudioTab.animations => 'Animations',
      SmartTilesStudioTab.testBench => 'Banc d’essai',
      SmartTilesStudioTab.validation => 'Validation',
    };

String _usageFilterLabel(_LibraryUsageFilter filter) => switch (filter) {
      _LibraryUsageFilter.all => 'Tous',
      _LibraryUsageFilter.terrain => 'Terrain',
      _LibraryUsageFilter.path => 'Chemin',
      _LibraryUsageFilter.forestSurface => 'Forêt',
    };

String _templateLabel(SmartTileTemplateHint template) => switch (template) {
      SmartTileTemplateHint.simple => 'Simple',
      SmartTileTemplateHint.legacy20 => 'Legacy 20',
      SmartTileTemplateHint.edge16 => 'Edge 16',
      SmartTileTemplateHint.corner16 => 'Corner 16',
      SmartTileTemplateHint.corner12 => 'Corner 12',
      SmartTileTemplateHint.blob47 => 'Blob 47',
      SmartTileTemplateHint.mixed256 => 'Mixed 256',
      SmartTileTemplateHint.free => 'Libre',
    };

String _wizardStepLabel(SmartTileStudioWizardStep step) =>
    smartTileWizardStepLabel(step);

String _sourceChoiceLabel(SmartTileStudioSourceChoice? choice) =>
    switch (choice) {
      SmartTileStudioSourceChoice.projectImage => 'Image du projet',
      SmartTileStudioSourceChoice.registeredAtlas => 'Atlas enregistré',
      SmartTileStudioSourceChoice.emptyPreset => 'Preset vide',
      null => 'Non choisie',
    };

String _tiledWangFailureMessage(Object error) {
  if (error is SmartTileTiledWangImportServiceException) {
    return error.message;
  }
  return EditorAuthoringMutationFailure.capture(error).message;
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
