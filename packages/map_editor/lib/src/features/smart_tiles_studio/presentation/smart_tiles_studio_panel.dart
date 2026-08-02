import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';
import '../application/smart_tile_atlas_image_loader.dart';
import '../application/smart_tile_authoring_controller.dart';
import '../application/smart_tile_grid_detector.dart';
import '../application/smart_tile_guide.dart';
import '../application/smart_tile_guide_placement.dart';
import '../application/smart_tile_studio_library.dart';
import '../application/smart_tile_studio_session.dart';
import 'smart_tile_guide_diagram.dart';
import 'smart_tile_guide_overlay_painter.dart';

enum SmartTilesStudioTab { atlas, rules, animations, testBench, validation }

enum _LibraryUsageFilter { all, terrain, path, forestSurface }

class SmartTilesStudioPanel extends StatefulWidget {
  const SmartTilesStudioPanel({
    super.key,
    required this.manifest,
    this.projectRootPath,
    this.imageLoader = const FileSmartTileAtlasImageLoader(),
    this.onManifestChanged,
    this.onAddToActiveMap,
  });

  final ProjectManifest manifest;
  final String? projectRootPath;
  final SmartTileAtlasImageLoader imageLoader;
  final ValueChanged<ProjectManifest>? onManifestChanged;
  final ValueChanged<ProjectSmartTilePreset>? onAddToActiveMap;

  @override
  State<SmartTilesStudioPanel> createState() => _SmartTilesStudioPanelState();
}

class _SmartTilesStudioPanelState extends State<SmartTilesStudioPanel> {
  final SmartTileStudioSession _session = SmartTileStudioSession();
  final SmartTileGridDetector _gridDetector = const SmartTileGridDetector();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, TextEditingController> _gridControllers =
      <String, TextEditingController>{};
  SmartTileAuthoringController _authoring =
      SmartTileAuthoringController.blank();

  SmartTilesStudioTab _tab = SmartTilesStudioTab.atlas;
  _LibraryUsageFilter _usageFilter = _LibraryUsageFilter.all;
  String _query = '';
  String? _selectedItemKey;
  int? _selectedMask;
  SmartTileFrameRef? _lastMappedFrame;
  String? _lastCandidateId;
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
  int _sourceLoadRevision = 0;
  SmartTileTestGrid _testGrid = SmartTileTestGrid.empty(width: 7, height: 7);

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
  }

  @override
  void dispose() {
    _searchController.dispose();
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 760) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SizedBox(
                      key: const Key('smart-tiles-library-column'),
                      height: 250,
                      child: _buildLibrary(visibleItems),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      key: const Key('smart-tiles-workbench-column'),
                      child: _buildWorkbench(selectedItem),
                    ),
                  ],
                );
              }
              if (constraints.maxWidth < 1100) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SizedBox(
                      key: const Key('smart-tiles-library-column'),
                      width: 240,
                      child: _buildLibrary(visibleItems),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      key: const Key('smart-tiles-workbench-column'),
                      child: _buildWorkbench(selectedItem),
                    ),
                  ],
                );
              }
              final inspectorWidth =
                  constraints.maxWidth >= 1220 ? 300.0 : 260.0;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(
                    key: const Key('smart-tiles-library-column'),
                    width: 280,
                    child: _buildLibrary(visibleItems),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    key: const Key('smart-tiles-workbench-column'),
                    child: _buildWorkbench(selectedItem),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    key: const Key('smart-tiles-inspector-column'),
                    width: inspectorWidth,
                    child: _buildInspector(selectedItem),
                  ),
                ],
              );
            },
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
          trailing: PokeMapButton(
            key: const Key('smart-tiles-new-preset'),
            onPressed: _startDraft,
            size: PokeMapButtonSize.small,
            leading: const Icon(CupertinoIcons.add, size: 14),
            child: const Text('Nouveau'),
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
                        thumbnail: const Icon(
                          CupertinoIcons.square_grid_3x2,
                          size: 20,
                        ),
                        label: item.name,
                        description: '${item.usageLabel} • ${item.statusLabel}',
                        onPressed: () => setState(() {
                          _session.cancelDraft();
                          _selectedItemKey = item.key;
                          _focusedRuleId = null;
                          _focusedMask = null;
                          _testGrid =
                              SmartTileTestGrid.empty(width: 7, height: 7);
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
    return PokeMapPanel(
      expandChild: true,
      padding: EdgeInsets.zero,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            PokeMapSectionHeader(
              title: _session.state.isCreating
                  ? 'Nouveau Smart Tile'
                  : 'Smart Tiles Studio',
              description: _session.state.isCreating
                  ? 'Création native en cinq étapes'
                  : selectedItem?.name ??
                      'Sélectionnez un preset dans la bibliothèque.',
            ),
            const SizedBox(height: 8),
            _buildTabs(),
          ],
        ),
      ),
      child: _session.state.isCreating
          ? _buildWizard()
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
    return switch (_tab) {
      SmartTilesStudioTab.atlas => _buildAtlasTab(selectedItem),
      SmartTilesStudioTab.rules => _buildRulesTab(selectedItem),
      SmartTilesStudioTab.animations => _buildAnimationsTab(selectedItem),
      SmartTilesStudioTab.testBench => _buildTestBenchTab(selectedItem),
      SmartTilesStudioTab.validation => _buildValidationTab(selectedItem),
    };
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
            const PokeMapBadge(
              label: 'Brouillon de session',
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
              variant: selectedItem.isLegacy
                  ? PokeMapBadgeVariant.neutral
                  : selectedItem.statusLabel == 'Publié'
                      ? PokeMapBadgeVariant.success
                      : PokeMapBadgeVariant.warning,
            ),
            const SizedBox(height: 12),
            _InspectorValue(label: 'Nom', value: selectedItem.name),
            _InspectorValue(label: 'Identifiant', value: selectedItem.id),
            _InspectorValue(label: 'Usage', value: selectedItem.usageLabel),
            _InspectorValue(
              label: 'Origine',
              value: selectedItem.isLegacy ? 'Historique' : 'Natif v5',
            ),
            if (selectedItem.nativePreset != null) ...[
              const SizedBox(height: 12),
              const PokeMapButton(
                key: Key('smart-tiles-add-to-active-map'),
                onPressed: null,
                disabledReason:
                    smartTileNativeCatalogAuthoringRequiresStn03Code,
                leading: Icon(CupertinoIcons.square_grid_3x2, size: 15),
                child: Text('Ajouter à la map active'),
              ),
              const SizedBox(height: 8),
              const PokeMapBadge(
                label: smartTileNativeCatalogAuthoringRequiresStn03Code,
                variant: PokeMapBadgeVariant.warning,
              ),
              const SizedBox(height: 6),
              Text(
                'L’ajout à une map sera disponible avec le contrat natif STN-03.',
                style: TextStyle(color: context.pokeMapColors.textSecondary),
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SmartTileStudioWizardStep.values.map((step) {
            final index = step.index + 1;
            return PokeMapBadge(
              label: '$index. ${_wizardStepLabel(step)}',
              variant: _session.state.wizardStep == step
                  ? PokeMapBadgeVariant.info
                  : PokeMapBadgeVariant.neutral,
            );
          }).toList(growable: false),
        ),
        const SizedBox(height: 22),
        if (_session.state.wizardStep == SmartTileStudioWizardStep.usage)
          _buildUsageStep()
        else if (_session.state.wizardStep == SmartTileStudioWizardStep.guide)
          _buildGuideStep()
        else if (_session.state.wizardStep ==
            SmartTileStudioWizardStep.placement)
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const PokeMapSectionHeader(
          title: 'Choisir une source',
          description:
              'PokeMap référence une image du projet, jamais un chemin machine.',
        ),
        const SizedBox(height: 10),
        for (final choice in const <SmartTileStudioSourceChoice>[
          SmartTileStudioSourceChoice.projectImage,
          SmartTileStudioSourceChoice.registeredAtlas,
        ]) ...[
          PokeMapAssetCard(
            thumbnail: Icon(_sourceChoiceIcon(choice), size: 22),
            label: _sourceChoiceLabel(choice),
            onPressed: () => _chooseSource(choice),
            selected: _session.state.sourceChoice == choice,
          ),
          const SizedBox(height: 8),
        ],
        if (_session.state.sourceChoice ==
            SmartTileStudioSourceChoice.projectImage) ...[
          const SizedBox(height: 4),
          PokeMapButton(
            key: const Key('smart-tiles-choose-project-image'),
            onPressed: _isLoadingSourceImage ? null : _chooseProjectImage,
            isLoading: _isLoadingSourceImage,
            variant: PokeMapButtonVariant.secondary,
            leading: const Icon(CupertinoIcons.photo_on_rectangle, size: 15),
            child: Text(
              selectedTileset == null
                  ? 'Choisir un tileset du projet'
                  : 'Changer de tileset',
            ),
          ),
        ],
        if (_session.state.sourceChoice ==
            SmartTileStudioSourceChoice.registeredAtlas) ...[
          const SizedBox(height: 4),
          PokeMapButton(
            key: const Key('smart-tiles-choose-registered-atlas'),
            onPressed: _isLoadingSourceImage ? null : _chooseRegisteredAtlas,
            isLoading: _isLoadingSourceImage,
            variant: PokeMapButtonVariant.secondary,
            leading: const Icon(CupertinoIcons.square_grid_3x2, size: 15),
            child: Text(
              selectedAtlas == null
                  ? 'Choisir un atlas enregistré'
                  : 'Changer d’atlas',
            ),
          ),
        ],
        if (selectedTileset != null &&
            _session.state.sourceChoice !=
                SmartTileStudioSourceChoice.emptyPreset) ...[
          const SizedBox(height: 12),
          _buildSelectedSourcePreview(
            tileset: selectedTileset,
            registeredAtlas: selectedAtlas,
            image: loadedImage,
          ),
        ],
        if (_sourceImageResult != null &&
            !_sourceImageResult!.isLoaded &&
            !_isLoadingSourceImage) ...[
          const SizedBox(height: 8),
          PokeMapBadge(
            label: _sourceImageResult!.message,
            variant: PokeMapBadgeVariant.warning,
          ),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: PokeMapButton(
            key: const Key('smart-tiles-next-step'),
            onPressed: _canMoveToGrid ? _moveToGrid : null,
            trailing: const Icon(CupertinoIcons.chevron_right, size: 14),
            child: const Text('Détecter la grille'),
          ),
        ),
      ],
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
    final geometry = _session.state.gridGeometry!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PokeMapSectionHeader(
          title: 'Grille détectée',
          description:
              '${geometry.columns} × ${geometry.rows} cellules — chaque valeur reste modifiable.',
          trailing: PokeMapBadge(
            label: geometry.hasPartialCells
                ? 'Cellules partielles'
                : 'Alignement exact',
            variant: geometry.hasPartialCells
                ? PokeMapBadgeVariant.warning
                : PokeMapBadgeVariant.success,
          ),
        ),
        const SizedBox(height: 14),
        _GridFields(
          controllers: _gridControllers,
          geometry: geometry,
          onChanged: _updateGridValue,
        ),
        const SizedBox(height: 12),
        const Align(
          alignment: Alignment.centerRight,
          child: PokeMapBadge(
            label: 'Grille prête pour le placement',
            variant: PokeMapBadgeVariant.success,
          ),
        ),
      ],
    );
  }

  Widget _buildUsageStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const PokeMapSectionHeader(
          title: 'Choisir l’usage',
          description:
              'Un preset a un rôle explicite : terrain, chemin ou forêt.',
        ),
        const SizedBox(height: 12),
        for (final usage in SmartTileUsage.values) ...[
          PokeMapAssetCard(
            key: Key('smart-tiles-usage-${usage.name}'),
            thumbnail: Icon(_usageIcon(usage), size: 22),
            label: _usageLabel(usage),
            description: usage == SmartTileUsage.path
                ? _usageDescription(usage)
                : '${_usageDescription(usage)} Guide guidé à venir.',
            selected: _session.state.usage == usage,
            onPressed:
                usage == SmartTileUsage.path ? () => _selectUsage(usage) : null,
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: PokeMapButton(
            key: const Key('smart-tiles-usage-next-step'),
            onPressed: _session.state.usage == null ? null : _moveToGuide,
            trailing: const Icon(CupertinoIcons.chevron_right, size: 14),
            child: const Text('Choisir un guide'),
          ),
        ),
      ],
    );
  }

  Widget _buildGuideStep() {
    final usage = _session.state.usage!;
    final guides = smartTileGuidesForUsage(usage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const PokeMapSectionHeader(
          title: 'Reconnaître la disposition',
          description:
              'Choisissez le dessin qui ressemble à l’organisation de votre atlas. Aucun code technique à saisir.',
        ),
        const SizedBox(height: 12),
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
              onPressed: () => _selectGuide(guide.id),
            ),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: PokeMapButton(
            key: const Key('smart-tiles-guide-next-step'),
            onPressed: _session.state.guideId == null ? null : _moveToPlacement,
            trailing: const Icon(CupertinoIcons.chevron_right, size: 14),
            child: const Text('Placer sur l’atlas'),
          ),
        ),
      ],
    );
  }

  Widget _buildPlacementStep() {
    if (_session.state.gridGeometry == null) {
      return _buildSourceStep();
    }
    final guideId = _session.state.guideId;
    if (guideId == null) {
      return const PokeMapEmptyState(
        title: 'Guide manquant',
        description: 'Revenez à l’étape Guide avant de placer l’atlas.',
      );
    }
    if (guideId != SmartTileGuideId.erwCorner16) {
      return _buildLegacyMappingStep();
    }
    return _buildGuidedPlacementMapping(smartTileGuideById(guideId));
  }

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
        _buildGridStep(),
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
          onCellSelected: (cell) => _mapAtlasCell(
            column: cell.column,
            row: cell.row,
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
    final results = runSmartTileTemplateBench(
      preset: preset,
      materials: catalog.materials,
      materialId: preset.defaultMaterialId,
      mapId: 'guided-authoring-bench',
      layerId: preset.id,
    );
    final resolved = results
        .where(
          (result) =>
              result.resolution.status == SmartTileResolutionStatus.resolved,
        )
        .length;
    final isComplete = results.isNotEmpty && resolved == results.length;
    final guide = smartTileGuideById(_session.state.guideId!);
    final variantCount = guide.cells.length - guide.requiredMasks.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PokeMapSectionHeader(
          title: 'Banc d’essai du chemin',
          description:
              'PokeMap vérifie les mêmes raccords que ceux utilisés sur une vraie map.',
          trailing: PokeMapBadge(
            label: '$resolved / ${results.length} résolus',
            variant: isComplete
                ? PokeMapBadgeVariant.success
                : PokeMapBadgeVariant.error,
          ),
        ),
        const SizedBox(height: 14),
        PokeMapBadge(
          label: isComplete
              ? 'Aucune forme manquante'
              : '${results.length - resolved} forme(s) manquante(s)',
          variant: isComplete
              ? PokeMapBadgeVariant.success
              : PokeMapBadgeVariant.error,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            const PokeMapBadge(label: '4 coins extérieurs'),
            const PokeMapBadge(label: '4 bords'),
            const PokeMapBadge(label: '4 coins intérieurs'),
            PokeMapBadge(label: '$variantCount variantes supplémentaires'),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: PokeMapButton(
            key: const Key('smart-tiles-go-to-publish'),
            onPressed: isComplete ? _moveToPublish : null,
            trailing: const Icon(CupertinoIcons.chevron_right, size: 14),
            child: const Text('Vérifier avant publication'),
          ),
        ),
      ],
    );
  }

  Widget _buildPublishStep() {
    final guide = smartTileGuideById(_session.state.guideId!);
    final geometry = _session.state.gridGeometry!;
    final compiled = _authoring.compileCatalog();
    final diagnostics = validateProjectSmartTileCatalog(
      catalog: compiled,
      projectTilesetIds: widget.manifest.tilesets.map((tileset) => tileset.id),
    );
    final blocking = diagnostics.where((item) => item.isError).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PokeMapSectionHeader(
          title: 'Publier le Smart Tile',
          description:
              'Dernière vérification humaine avant d’ajouter le preset au projet.',
          trailing: PokeMapBadge(
            label: blocking == 0
                ? 'Publication après STN-03'
                : '$blocking erreur(s) bloquante(s)',
            variant: blocking == 0
                ? PokeMapBadgeVariant.warning
                : PokeMapBadgeVariant.error,
          ),
        ),
        const SizedBox(height: 14),
        PokeMapPanel(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _InspectorValue(label: 'Nom', value: _authoring.state.name),
              const SizedBox(height: 8),
              const _InspectorValue(label: 'Usage', value: 'Chemin'),
              const SizedBox(height: 8),
              _InspectorValue(
                label: 'Atlas',
                value: _authoring.state.atlasName,
              ),
              const SizedBox(height: 8),
              _InspectorValue(
                label: 'Grille',
                value:
                    '${geometry.cellWidth} × ${geometry.cellHeight} px — ${geometry.columns} × ${geometry.rows} cellules',
              ),
              const SizedBox(height: 8),
              _InspectorValue(label: 'Guide', value: guide.name),
              const SizedBox(height: 8),
              _InspectorValue(
                label: 'Associations',
                value: '${guide.cells.length} cellules • '
                    '${guide.requiredMasks.length} raccords • '
                    '${guide.cells.length - guide.requiredMasks.length} variantes',
              ),
            ],
          ),
        ),
        if (_draftMessage != null) ...[
          const SizedBox(height: 10),
          PokeMapBadge(
            label: _draftMessage!,
            variant: PokeMapBadgeVariant.warning,
          ),
        ],
        const SizedBox(height: 10),
        const PokeMapBadge(
          label: smartTileNativeCatalogAuthoringRequiresStn03Code,
          variant: PokeMapBadgeVariant.warning,
        ),
        const SizedBox(height: 6),
        Text(
          'La publication dans le catalogue sera activée par STN-03.',
          style: TextStyle(color: context.pokeMapColors.textSecondary),
        ),
        const SizedBox(height: 16),
        const Align(
          alignment: Alignment.centerRight,
          child: PokeMapButton(
            key: Key('smart-tiles-publish-guided'),
            onPressed: null,
            disabledReason: smartTileNativeCatalogAuthoringRequiresStn03Code,
            leading: Icon(CupertinoIcons.check_mark_circled, size: 15),
            child: Text('Publier et utiliser dans une map'),
          ),
        ),
      ],
    );
  }

  Widget _buildAtlasTab(SmartTileLibraryItem selectedItem) {
    if (selectedItem.isLegacy) {
      return const PokeMapEmptyState(
        title: 'Source historique',
        description:
            'Le preset reste sur son résolveur historique jusqu’à une conversion explicite.',
        icon: Icon(CupertinoIcons.photo),
      );
    }
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
        return PokeMapAssetCard(
          key: Key('smart-tiles-rule-${rule.id}'),
          thumbnail: const Icon(CupertinoIcons.arrow_branch, size: 20),
          label: rule.id,
          selected: _focusedRuleId == rule.id ||
              (_focusedRuleId == null && _focusedMask == mask),
          onPressed: () => setState(() {
            _focusedRuleId = rule.id;
            _focusedMask = mask;
          }),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (mask != null)
                PokeMapBadge(
                  label:
                      '0x${mask.toRadixString(16).padLeft(2, '0').toUpperCase()}',
                  variant: PokeMapBadgeVariant.info,
                ),
              const SizedBox(width: 6),
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
    final results = runSmartTileTemplateBench(
      preset: preset,
      materials: widget.manifest.smartTileCatalog.materials,
      materialId: preset.defaultMaterialId,
      mapId: 'studio-test-bench',
      layerId: preset.id,
    );
    final resolved = results
        .where(
          (item) =>
              item.resolution.status == SmartTileResolutionStatus.resolved,
        )
        .length;
    final supportsManualGrid =
        smartTileTestGridSupportsTopology(preset.topology);
    return ListView(
      padding: const EdgeInsets.all(18),
      children: <Widget>[
        PokeMapSectionHeader(
          title: 'Peinture manuelle',
          description:
              'Cliquez pour peindre ou effacer le matériau du preset sur une grille logique 7 × 7.',
          trailing: PokeMapBadge(
            label: preset.defaultMaterialId,
            variant: PokeMapBadgeVariant.mapAccent,
          ),
        ),
        const SizedBox(height: 10),
        if (!supportsManualGrid)
          const PokeMapEmptyState(
            key: Key('smart-tiles-wang-manual-bench-deferred'),
            title: 'Grille Wang dédiée',
            description:
                'Cette topologie utilise ses propres arêtes et coins. Les scénarios canoniques ci-dessous sont exacts ; la peinture libre arrivera avec le compilateur Wang STN-05.',
            icon: Icon(CupertinoIcons.square_grid_3x2),
          )
        else
          Center(
            child: SizedBox(
              width: 7 * 38,
              child: Wrap(
                spacing: 2,
                runSpacing: 2,
                children: <Widget>[
                  for (var y = 0; y < _testGrid.height; y += 1)
                    for (var x = 0; x < _testGrid.width; x += 1)
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: PokeMapButton(
                          key: Key('smart-tiles-test-cell-$x-$y'),
                          onPressed: () => _paintTestCell(
                            x: x,
                            y: y,
                            materialId: preset.defaultMaterialId,
                          ),
                          variant: PokeMapButtonVariant.ghost,
                          size: PokeMapButtonSize.small,
                          isSelected: _testGrid.materialAt(x, y) != null,
                          child: Text(_testCellLabel(
                            x: x,
                            y: y,
                            preset: preset,
                          )),
                        ),
                      ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        PokeMapSectionHeader(
          title: 'Scénarios générés',
          description:
              'Chaque cas appelle directement resolveSmartTile, comme l’éditeur et le runtime.',
          trailing: PokeMapBadge(
            key: const Key('smart-tiles-generated-bench-result'),
            label: '$resolved / ${results.length} résolus',
            variant: resolved == results.length
                ? PokeMapBadgeVariant.success
                : PokeMapBadgeVariant.error,
          ),
        ),
        const SizedBox(height: 10),
        if (results.isEmpty)
          const PokeMapEmptyState(
            title: 'Aucun scénario canonique',
            description:
                'Le gabarit Libre se vérifie uniquement sur la grille manuelle.',
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final result in results)
                PokeMapButton(
                  key: Key('smart-tiles-bench-mask-${result.mask}'),
                  onPressed: () => _openBenchResult(result),
                  variant: PokeMapButtonVariant.ghost,
                  size: PokeMapButtonSize.small,
                  isSelected: result.resolution.status ==
                      SmartTileResolutionStatus.resolved,
                  child: Text(
                    '0x${result.mask.toRadixString(16).padLeft(2, '0').toUpperCase()}',
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildValidationTab(SmartTileLibraryItem selectedItem) {
    if (selectedItem.isLegacy) {
      return const PokeMapEmptyState(
        title: 'Validation historique',
        description:
            'La compatibilité est contrôlée sans publier automatiquement un preset natif.',
        icon: Icon(CupertinoIcons.check_mark_circled),
      );
    }
    final diagnostics = validateProjectSmartTileCatalog(
      catalog: widget.manifest.smartTileCatalog,
      projectTilesetIds: widget.manifest.tilesets.map((tileset) => tileset.id),
    );
    final blocking = diagnostics.where((item) => item.isError).length;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: <Widget>[
        PokeMapSectionHeader(
          title: 'Validation avant publication',
          description:
              'Couverture, ambiguïtés, références, poids, durées et limites d’atlas.',
          trailing: PokeMapBadge(
            label: blocking == 0
                ? 'Publication après STN-03'
                : '$blocking erreur(s) bloquante(s)',
            variant: blocking == 0
                ? PokeMapBadgeVariant.warning
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
        const SizedBox(height: 10),
        const PokeMapBadge(
          label: smartTileNativeCatalogAuthoringRequiresStn03Code,
          variant: PokeMapBadgeVariant.warning,
        ),
        const SizedBox(height: 6),
        Text(
          'La publication dans le catalogue sera activée par STN-03.',
          style: TextStyle(color: context.pokeMapColors.textSecondary),
        ),
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
        const SizedBox(height: 14),
        const Align(
          alignment: Alignment.centerRight,
          child: PokeMapButton(
            key: Key('smart-tiles-publish'),
            onPressed: null,
            disabledReason: smartTileNativeCatalogAuthoringRequiresStn03Code,
            leading: Icon(CupertinoIcons.check_mark_circled, size: 15),
            child: Text('Publier'),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimationsTab(SmartTileLibraryItem selectedItem) {
    final animations = widget.manifest.smartTileCatalog.animations;
    if (selectedItem.isLegacy || animations.isEmpty) {
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

  void _startDraft() {
    setState(() {
      _session.startDraft();
      final id = _nextDraftId();
      _authoring = SmartTileAuthoringController.blank()
        ..configureIdentity(
          id: id,
          name: 'Nouveau Smart Tile',
          materialId: '$id-material',
          materialName: 'Matériau du preset',
        );
      _selectedMask = null;
      _lastMappedFrame = null;
      _lastCandidateId = null;
      _guidePlacement = null;
      _correctionNumber = null;
      _placementMessage = null;
      _draftMessage = null;
      _clearSourceImageSelection();
      _selectedRegisteredAtlasId = null;
      _tab = SmartTilesStudioTab.atlas;
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
        _selectedSourceTileset != null &&
            _sourceImageResult?.isLoaded == true &&
            !_isLoadingSourceImage,
      null => false,
    };
  }

  void _clearSourceImageSelection() {
    _sourceLoadRevision += 1;
    _selectedSourceTilesetId = null;
    _sourceImageResult = null;
    _isLoadingSourceImage = false;
  }

  void _chooseSource(SmartTileStudioSourceChoice choice) {
    setState(() {
      _session.chooseSource(choice);
      _clearSourceImageSelection();
      _selectedRegisteredAtlasId = null;
    });
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
  }

  void _moveToGrid() {
    final image = _sourceImageResult?.image;
    final registeredAtlas = _selectedRegisteredAtlas;
    final detected = switch (_session.state.sourceChoice) {
      SmartTileStudioSourceChoice.emptyPreset => _gridDetector
          .detect(
            const SmartTileGridDetectionInput(
              imageWidth: 160,
              imageHeight: 96,
            ),
          )
          .first
          .geometry,
      SmartTileStudioSourceChoice.registeredAtlas
          when image != null && registeredAtlas != null =>
        SmartTileGridGeometry(
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
        ),
      SmartTileStudioSourceChoice.projectImage when image != null =>
        _gridDetector
            .detect(
              SmartTileGridDetectionInput(
                imageWidth: image.width,
                imageHeight: image.height,
                columnAlphaCoverage: image.columnAlphaCoverage,
                rowAlphaCoverage: image.rowAlphaCoverage,
              ),
            )
            .first
            .geometry,
      _ => throw StateError('Choose a readable Smart Tile source first.'),
    };
    _setGridControllers(detected);
    _configureDraftAtlas(detected);
    setState(() => _session.configureGrid(detected));
  }

  void _setGridControllers(SmartTileGridGeometry geometry) {
    final values = <String, int>{
      'cellWidth': geometry.cellWidth,
      'cellHeight': geometry.cellHeight,
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
    final current = _session.state.gridGeometry;
    if (parsed == null || parsed < 0 || current == null) {
      return;
    }
    final next = switch (field) {
      'cellWidth' when parsed > 0 => current.copyWith(cellWidth: parsed),
      'cellHeight' when parsed > 0 => current.copyWith(cellHeight: parsed),
      'originX' => current.copyWith(originX: parsed),
      'originY' => current.copyWith(originY: parsed),
      'marginX' => current.copyWith(marginX: parsed),
      'marginY' => current.copyWith(marginY: parsed),
      'spacingX' => current.copyWith(spacingX: parsed),
      'spacingY' => current.copyWith(spacingY: parsed),
      _ => current,
    };
    _configureDraftAtlas(next);
    setState(() {
      _session.updateGrid(next);
      _guidePlacement = null;
      _correctionNumber = null;
      _placementMessage = 'Grille modifiée : replacez la cellule nº 1.';
      _authoring.clearMappings();
    });
  }

  void _moveToGuide() {
    setState(_session.moveToGuide);
  }

  void _selectUsage(SmartTileUsage usage) {
    setState(() {
      _session.chooseUsage(usage);
      _authoring.selectUsage(usage);
      _selectedMask = null;
      _lastMappedFrame = null;
      _lastCandidateId = null;
      _guidePlacement = null;
      _correctionNumber = null;
      _placementMessage = null;
    });
  }

  void _selectGuide(SmartTileGuideId guideId) {
    setState(() {
      _session.chooseGuide(guideId);
      _guidePlacement = null;
      _correctionNumber = null;
      _placementMessage = null;
      _authoring.clearMappings();
    });
  }

  void _moveToPlacement() {
    setState(_session.moveToPlacement);
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
        _authoring.clearMappings();
        _session.clearAnchor();
      });
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
  }

  void _mapAtlasCell({
    required int column,
    required int row,
  }) {
    final mask = _selectedMask;
    if (mask == null) {
      return;
    }
    final variantIndex = _authoring.state.mappings[mask]?.length ?? 0;
    final candidateId = 'cell_${column}_${row}_$variantIndex';
    _authoring.addAtlasVariant(
      mask: mask,
      column: column,
      row: row,
      candidateId: candidateId,
      channel: _session.state.usage == SmartTileUsage.forestSurface
          ? SmartTileRenderChannel.understory
          : SmartTileRenderChannel.ground,
    );
    setState(() {
      _lastMappedFrame = SmartTileFrameRef(
        atlasId: _authoring.state.atlasId,
        column: column,
        row: row,
      );
      _lastCandidateId = candidateId;
    });
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
  }

  void _moveToTest() {
    setState(_session.moveToTest);
  }

  void _moveToPublish() {
    setState(_session.moveToPublish);
  }

  void _paintTestCell({
    required int x,
    required int y,
    required String materialId,
  }) {
    setState(() {
      _testGrid = _testGrid.paint(
        x: x,
        y: y,
        materialId: _testGrid.materialAt(x, y) == null ? materialId : null,
      );
    });
  }

  String _testCellLabel({
    required int x,
    required int y,
    required ProjectSmartTilePreset preset,
  }) {
    if (_testGrid.materialAt(x, y) == null) {
      return '·';
    }
    final resolution = _testGrid.resolveAt(
      x: x,
      y: y,
      preset: preset,
      materials: widget.manifest.smartTileCatalog.materials,
      mapId: 'studio-test-bench',
      layerId: preset.id,
    );
    return resolution.status == SmartTileResolutionStatus.resolved ? '✓' : '!';
  }

  void _openBenchResult(SmartTileTemplateBenchResult result) {
    setState(() {
      _focusedMask = result.mask;
      _focusedRuleId = result.resolution.ruleId;
      _tab = SmartTilesStudioTab.rules;
    });
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
      tilesetId: _selectedSourceTileset?.id ?? '',
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

class _GridFields extends StatelessWidget {
  const _GridFields({
    required this.controllers,
    required this.geometry,
    required this.onChanged,
  });

  final Map<String, TextEditingController> controllers;
  final SmartTileGridGeometry geometry;
  final void Function(String field, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    final fields = <({String id, String label})>[
      (id: 'cellWidth', label: 'Largeur cellule'),
      (id: 'cellHeight', label: 'Hauteur cellule'),
      (id: 'originX', label: 'Origine X'),
      (id: 'originY', label: 'Origine Y'),
      (id: 'marginX', label: 'Marge X'),
      (id: 'marginY', label: 'Marge Y'),
      (id: 'spacingX', label: 'Espacement X'),
      (id: 'spacingY', label: 'Espacement Y'),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: fields.map((field) {
        return SizedBox(
          width: 160,
          child: PokeMapTextField(
            label: field.label,
            controller: controllers[field.id],
            fieldKey: Key(
              'smart-tiles-${_gridFieldKeySuffix(field.id)}',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) => onChanged(field.id, value),
          ),
        );
      }).toList(growable: false),
    );
  }
}

String _gridFieldKeySuffix(String id) => switch (id) {
      'cellWidth' => 'cell-width',
      'cellHeight' => 'cell-height',
      'originX' => 'origin-x',
      'originY' => 'origin-y',
      'marginX' => 'margin-x',
      'marginY' => 'margin-y',
      'spacingX' => 'spacing-x',
      'spacingY' => 'spacing-y',
      _ => id,
    };

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

String _usageLabel(SmartTileUsage usage) => switch (usage) {
      SmartTileUsage.terrain => 'Terrain',
      SmartTileUsage.path => 'Chemin',
      SmartTileUsage.forestSurface => 'Surface forestière',
    };

String _usageDescription(SmartTileUsage usage) => switch (usage) {
      SmartTileUsage.terrain =>
        'Une matière de base couvrant intégralement la map.',
      SmartTileUsage.path =>
        'Un réseau peint au-dessus du terrain avec raccords automatiques.',
      SmartTileUsage.forestSurface =>
        'Sous-bois et canopée multi-couches pour construire les forêts.',
    };

IconData _usageIcon(SmartTileUsage usage) => switch (usage) {
      SmartTileUsage.terrain => CupertinoIcons.map,
      SmartTileUsage.path => CupertinoIcons.arrow_branch,
      SmartTileUsage.forestSurface => CupertinoIcons.tree,
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

String _wizardStepLabel(SmartTileStudioWizardStep step) => switch (step) {
      SmartTileStudioWizardStep.usage => 'Usage',
      SmartTileStudioWizardStep.guide => 'Guide',
      SmartTileStudioWizardStep.placement => 'Placement',
      SmartTileStudioWizardStep.test => 'Essai',
      SmartTileStudioWizardStep.publish => 'Publier',
    };

String _sourceChoiceLabel(SmartTileStudioSourceChoice? choice) =>
    switch (choice) {
      SmartTileStudioSourceChoice.projectImage => 'Image du projet',
      SmartTileStudioSourceChoice.registeredAtlas => 'Atlas enregistré',
      SmartTileStudioSourceChoice.emptyPreset => 'Preset vide',
      null => 'Non choisie',
    };

IconData _sourceChoiceIcon(SmartTileStudioSourceChoice choice) =>
    switch (choice) {
      SmartTileStudioSourceChoice.projectImage => CupertinoIcons.photo,
      SmartTileStudioSourceChoice.registeredAtlas =>
        CupertinoIcons.square_grid_3x2,
      SmartTileStudioSourceChoice.emptyPreset => CupertinoIcons.square,
    };

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
