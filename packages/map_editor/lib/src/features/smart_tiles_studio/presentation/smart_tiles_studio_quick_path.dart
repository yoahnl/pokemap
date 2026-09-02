part of 'smart_tiles_studio_panel.dart';

extension _SmartTilesStudioQuickPath on _SmartTilesStudioPanelState {
  List<ProjectSmartTileAtlas> _spritePreviewAtlases() {
    final draftState = _authoring.state;
    final draftAtlas =
        _session.state.isCreating &&
            draftState.atlasId.trim().isNotEmpty &&
            draftState.atlasName.trim().isNotEmpty &&
            draftState.tilesetId.trim().isNotEmpty &&
            draftState.gridGeometry != null
        ? _authoring.compileAtlas()
        : null;
    return <ProjectSmartTileAtlas>[
      for (final atlas in widget.manifest.smartTileCatalog.atlases)
        if (atlas.id != draftAtlas?.id) atlas,
      ?draftAtlas,
    ];
  }

  Widget? _buildQuickPathFillStage({
    required List<SmartTileFormReadModel> forms,
    required ProjectSmartTilePreset preset,
    required SmartTileGridGeometry geometry,
  }) {
    final pathPatternId = _selectedPathPatternId;
    if (_session.state.usage != SmartTileUsage.path ||
        _useAdvancedPathFlow ||
        pathPatternId == null) {
      return null;
    }
    final pattern = smartTilePathPatternById(pathPatternId);
    final mappedMasks = <int>{
      for (final form in forms)
        if (form.candidates.isNotEmpty) form.mask,
    };
    final quickPathComplete = pattern.requiredMasks.every(mappedMasks.contains);
    return SmartTilePathFillStage(
      pattern: pattern,
      forms: forms,
      selectedMask: _selectedMask,
      atlasWorkbench: _SmartTileAtlasMappingViewport(
        geometry: geometry,
        image: _sourceImageResult?.image,
        selectedFrame: _pendingAtlasFrame ?? _lastMappedFrame,
        enabled: true,
        onCellSelected: (cell) {
          _selectFormsAtlasCell(column: cell.column, row: cell.row);
        },
      ),
      automaticPreview: SmartTilePathAutomaticPreview(
        pattern: pattern,
        mappedMasks: mappedMasks,
        slotPreviewBuilder: (mask) => _quickPathSlotPreview(
          forms: forms,
          mask: mask,
          topology: preset.topology,
        ),
      ),
      slotPreviewBuilder: (mask) => _quickPathSlotPreview(
        forms: forms,
        mask: mask,
        topology: preset.topology,
      ),
      onSlotSelected: _selectForm,
      onChangeImage: _resetQuickPathSource,
      onReset: _resetQuickPathMappings,
      onContinue: quickPathComplete ? _moveToTest : null,
    );
  }

  Future<void> _selectPathPattern(SmartTilePathPatternId patternId) async {
    final pattern = smartTilePathPatternById(patternId);
    final state = _authoring.state;
    final changesContract =
        state.topology != pattern.configuration.topology ||
        state.templateHint != pattern.configuration.templateHint;
    var clearMappings = false;
    if (changesContract &&
        (state.mappings.isNotEmpty || state.transitionCases.isNotEmpty)) {
      clearMappings = await showPokeMapBinaryConfirmationDialog(
        context,
        title: 'Changer de patron ?',
        message:
            'Les morceaux déjà associés appartiennent à un autre patron. Les retirer pour utiliser « ${pattern.label} » ?',
        secondaryLabel: 'Conserver le patron actuel',
        primaryLabel: 'Changer de patron',
        primaryIsDestructive: true,
        icon: CupertinoIcons.square_grid_3x2,
      );
      if (!clearMappings || !mounted) return;
    }
    _setQuickPathState(() {
      _authoring.configureConnections(
        pattern.configuration,
        clearMappings: clearMappings,
      );
      _selectedPathPatternId = patternId;
      _selectedConnectionProfileId = SmartTileConnectionProfileId.custom;
      _customConnectionTopology = pattern.configuration.topology;
      _selectedMask = null;
      _pendingAtlasFrame = null;
      _testLabController = null;
    });
    _notifyDraftChanged();
  }

  void _continueQuickPathPattern() {
    if (_selectedPathPatternId == null) return;
    _setQuickPathState(() {
      _session.moveToVariants();
      _session.moveToForms();
      _selectedMask = null;
      _pendingAtlasFrame = null;
    });
    _flushDraftAfterStepChange();
  }

  void _startAdvancedPathFlow() {
    _setQuickPathState(() {
      _useAdvancedPathFlow = true;
      _selectedPathPatternId = null;
      _selectedMask = null;
      _pendingAtlasFrame = null;
      _authoring.clearMappings();
      _session.returnToGrid();
    });
    _flushDraftAfterStepChange();
  }

  void _resetQuickPathSource() {
    _setQuickPathState(() {
      _session.returnToImage();
      _clearSourceImageSelection();
      _selectedRegisteredAtlasId = null;
      _selectedMask = null;
      _pendingAtlasFrame = null;
      _lastMappedFrame = null;
      _authoring.clearMappings();
      _testLabController = null;
    });
    _notifyDraftChanged();
  }

  void _resetQuickPathMappings() {
    _setQuickPathState(() {
      _authoring.clearMappings();
      _selectedMask = null;
      _pendingAtlasFrame = null;
      _lastMappedFrame = null;
      _testLabController = null;
    });
    _notifyDraftChanged();
  }

  Widget _quickPathSlotPreview({
    required List<SmartTileFormReadModel> forms,
    required int mask,
    required SmartTileTopology topology,
  }) {
    final form = forms.where((candidate) => candidate.mask == mask).firstOrNull;
    final candidate = form?.candidates.firstOrNull;
    final frame = candidate == null
        ? null
        : firstSmartTileFrameOf(
            candidate,
            animations: _authoring.state.animations,
          );
    if (frame != null) {
      return _spritePreview(
        frame,
        size: 54,
        semanticLabel: form?.label ?? 'Morceau du chemin',
      );
    }
    return SmartTileFormGlyph(mask: mask, topology: topology, dimension: 42);
  }
}
