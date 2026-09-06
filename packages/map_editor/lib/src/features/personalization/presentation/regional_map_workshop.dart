import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

import '../../../application/authoring_api/editor_receipt_presenter.dart';
import '../../../application/authoring_api/presentation_studio_add_authoring_gateway.dart';
import '../../../application/authoring_api/regional_map_authoring_gateway.dart';
import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';

class RegionalMapWorkshop extends StatefulWidget {
  const RegionalMapWorkshop({
    super.key,
    required this.projectRootPath,
    required this.gateway,
    required this.onProjectChanged,
    this.mediaPicker = const FilePickerPresentationStudioMediaPicker(),
  });

  final String projectRootPath;
  final RegionalMapAuthoringGateway gateway;
  final ValueChanged<ProjectManifest> onProjectChanged;
  final PresentationStudioMediaPicker mediaPicker;

  @override
  State<RegionalMapWorkshop> createState() => _RegionalMapWorkshopState();
}

class _RegionalMapWorkshopState extends State<RegionalMapWorkshop> {
  final _regionName = TextEditingController();
  final _pointName = TextEditingController();
  final _description = TextEditingController();
  RegionalMapAuthoringSnapshot? _snapshot;
  String? _regionId;
  String? _pointId;
  String? _regionImage;
  String? _thumbnail;
  ProjectMenuImageSampling _sampling = ProjectMenuImageSampling.smooth;
  ProjectRegionPointVisibility _visibility =
      ProjectRegionPointVisibility.always;
  ProjectRegionPointDiscovery _discovery =
      ProjectRegionPointDiscovery.onMapVisit;
  Set<String> _mapIds = {};
  double _u = .5;
  double _v = .5;
  String _mapSearch = '';
  String _previewMapId = '';
  bool _previewVisited = false;
  bool _showPreview = false;
  bool _busy = true;
  bool _dirty = false;
  String? _error;
  String? _feedback;
  Future<_RegionalImage?>? _image;
  Future<RuntimePlayerPauseDetailSnapshot>? _preview;
  String? _previewError;

  List<ProjectRegionDefinition> get _regions =>
      _snapshot?.manifest.regionalMap?.regions ?? const [];
  List<ProjectRegionPointOfInterest> get _points =>
      _snapshot?.manifest.regionalMap?.pointsOfInterest ?? const [];
  ProjectRegionDefinition? get _savedRegion =>
      _regions.where((r) => r.id == _regionId).firstOrNull;
  ProjectRegionPointOfInterest? get _savedPoint =>
      _points.where((p) => p.id == _pointId).firstOrNull;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _regionName.dispose();
    _pointName.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final loaded = await widget.gateway.load(widget.projectRootPath);
      if (!mounted) return;
      setState(() {
        _snapshot = loaded;
        _previewMapId = loaded.manifest.newGame.startMapId;
        if (!loaded.manifest.maps.any((m) => m.id == _previewMapId)) {
          _previewMapId = '';
        }
        _selectRegion(_regions.firstOrNull);
        _error = null;
      });
    } on Object catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _selectRegion(ProjectRegionDefinition? region) {
    _regionId = region?.id ?? widget.gateway.createIdentity('region');
    _regionName.text = region?.label ?? '';
    _regionImage = region?.imagePath;
    _sampling = region?.sampling ?? ProjectMenuImageSampling.smooth;
    _pointId = null;
    _dirty = false;
    _mapIds = {};
    _previewVisited = false;
    _error = null;
    _image = _readImage();
    _refreshPreview();
  }

  void _selectPoint(ProjectRegionPointOfInterest? point) {
    final region = _savedRegion;
    if (region != null) {
      _regionName.text = region.label;
      _sampling = region.sampling;
      if (_regionImage != region.imagePath) {
        _regionImage = region.imagePath;
        _image = _readImage();
      }
    }
    _pointId = point?.id ?? widget.gateway.createIdentity('place');
    _pointName.text = point?.label ?? '';
    _description.text = point?.description ?? '';
    _thumbnail = point?.thumbnailPath;
    _u = point?.u ?? .5;
    _v = point?.v ?? .5;
    _visibility = point?.visibility ?? ProjectRegionPointVisibility.always;
    _discovery = point?.discovery ?? ProjectRegionPointDiscovery.onMapVisit;
    _mapIds = {...?point?.mapIds};
    _mapSearch = '';
    _previewVisited = false;
    _dirty = false;
    _error = null;
    _refreshPreview();
  }

  ProjectRegionDefinition _regionDraft() => ProjectRegionDefinition(
    id: _regionId!,
    label: _regionName.text.trim(),
    labels: _savedRegion?.labels ?? const {},
    imagePath: _regionImage,
    sampling: _sampling,
    sortOrder: _savedRegion?.sortOrder ?? _regions.length,
  );

  ProjectRegionPointOfInterest _pointDraft() => ProjectRegionPointOfInterest(
    id: _pointId!,
    regionId: _regionId!,
    label: _pointName.text.trim(),
    labels: _savedPoint?.labels ?? const {},
    u: _u,
    v: _v,
    visibility: _visibility,
    discovery: _discovery,
    mapIds: _mapIds.toList(),
    description: _description.text.trim().isEmpty
        ? null
        : _description.text.trim(),
    descriptions: _description.text.trim().isEmpty
        ? const {}
        : _savedPoint?.descriptions ?? const {},
    thumbnailPath: _thumbnail,
    destination: _savedPoint?.destination,
    sortOrder: _savedPoint?.sortOrder ?? _points.length,
  );

  ProjectRegionalMapCatalog _draftCatalog() => ProjectRegionalMapCatalog(
    regions: [..._regions.where((r) => r.id != _regionId), _regionDraft()],
    pointsOfInterest: [
      ..._points.where((p) => p.id != _pointId),
      if (_pointId != null) _pointDraft(),
    ],
  );

  void _refreshPreview() {
    if (!_showPreview || _snapshot == null) return;
    try {
      _previewError = null;
      _preview = const RuntimeRegionalMapBuilder().build(
        gameState: GameState(
          saveId: 'editor-regional-preview',
          currentMapId: _previewMapId,
          narrativeEventProgress: NarrativeEventProgress(
            visitedNarrativeMapIds: _previewVisited ? _mapIds : const {},
          ),
        ),
        projectRootDirectory: widget.projectRootPath,
        locale: Localizations.localeOf(context).toLanguageTag(),
        catalog: _draftCatalog(),
        projectMaps: _snapshot!.manifest.maps,
      );
    } on Object catch (error) {
      _previewError = _message(error);
      _preview = null;
    }
  }

  void _edit(VoidCallback change) {
    setState(() {
      change();
      _dirty = true;
      _feedback = null;
      _refreshPreview();
    });
  }

  Future<bool> _discard() async =>
      !_dirty ||
      await showPokeMapBinaryConfirmationDialog(
        context,
        title: 'Modifications non enregistrées',
        message: 'Les changements du formulaire seront abandonnés.',
        secondaryLabel: 'Continuer à modifier',
        primaryLabel: 'Abandonner les changements',
      );

  Future<void> _navigate(VoidCallback change) async {
    if (!await _discard() || !mounted) return;
    setState(change);
  }

  Future<void> _reload() async {
    if (!await _discard() || !mounted) return;
    await _load();
  }

  Future<void> _close() async {
    if (_busy || !await _discard() || !mounted) return;
    setState(() => _dirty = false);
    Navigator.of(context).pop();
  }

  String _message(Object error) {
    if (error is FormatException) {
      if ((_pointId == null ? _regionName : _pointName).text.trim().isEmpty) {
        return 'Saisissez un nom avant de continuer.';
      }
      if (_pointId != null &&
          _discovery == ProjectRegionPointDiscovery.onMapVisit &&
          _mapIds.isEmpty) {
        return 'Choisissez au moins une carte pour découvrir ce lieu à la visite.';
      }
      return error.message;
    }
    final failure = EditorAuthoringMutationFailure.capture(error);
    return switch (failure.code) {
      'plan.stale' || 'plan.revision_mismatch' =>
        'Le projet a changé ailleurs. Rechargez l’atelier avant de réessayer.',
      'regional_map.region_referenced' =>
        'Cette région contient encore des lieux. Déplacez-les ou supprimez-les avant de retirer la région.',
      'regional_map.image_missing' =>
        'L’image n’est plus disponible dans la bibliothèque du projet.',
      _ => failure.message,
    };
  }

  Future<void> _save() async {
    if (_snapshot == null || _busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final after = _pointId == null
          ? await widget.gateway.saveRegion(
              widget.projectRootPath,
              _snapshot!,
              _regionDraft(),
            )
          : await widget.gateway.savePoint(
              widget.projectRootPath,
              _snapshot!,
              _pointDraft(),
            );
      if (!mounted) return;
      widget.onProjectChanged(after.manifest);
      setState(() {
        _snapshot = after;
        _dirty = false;
        _feedback = 'Enregistré et relu dans le projet.';
        _refreshPreview();
      });
    } on Object catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showPokeMapBinaryConfirmationDialog(
      context,
      title: _pointId == null ? 'Supprimer la région ?' : 'Supprimer le lieu ?',
      message:
          'La configuration sélectionnée sera retirée de la carte régionale.',
      secondaryLabel: 'Conserver',
      primaryLabel: 'Supprimer',
      primaryIsDestructive: true,
    );
    if (!confirmed || !mounted || _snapshot == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final after = _pointId == null
          ? await widget.gateway.deleteRegion(
              widget.projectRootPath,
              _snapshot!,
              _regionId!,
            )
          : await widget.gateway.deletePoint(
              widget.projectRootPath,
              _snapshot!,
              _pointId!,
            );
      if (!mounted) return;
      widget.onProjectChanged(after.manifest);
      setState(() {
        _snapshot = after;
        _selectRegion(_savedRegion ?? _regions.firstOrNull);
        _feedback = 'Suppression enregistrée et relue.';
      });
    } on Object catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importImage() async {
    final picked = await widget.mediaPicker.pick(
      PresentationStudioAddCategory.visual,
    );
    if (picked == null || !mounted || _snapshot == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final previousIds = _snapshot!.images.map((i) => i.assetId).toSet();
      final after = await widget.gateway.importImage(
        widget.projectRootPath,
        _snapshot!,
        picked,
      );
      if (!mounted) return;
      widget.onProjectChanged(after.manifest);
      final imported = after.images.singleWhere(
        (i) => !previousIds.contains(i.assetId),
      );
      setState(() {
        _snapshot = after;
        if (_pointId == null) {
          _regionImage = imported.path;
          _image = _readImage();
        } else {
          _thumbnail = imported.path;
        }
        _dirty = true;
        _feedback =
            'Image importée. Enregistrez le formulaire pour l’associer.';
        _refreshPreview();
      });
    } on Object catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<_RegionalImage?> _readImage() async {
    final path = _regionImage;
    if (path == null) return null;
    final bytes = await widget.gateway.imageBytes(widget.projectRootPath, path);
    if (bytes == null) {
      throw const FormatException('Image introuvable dans la bibliothèque.');
    }
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      try {
        return _RegionalImage(
          bytes,
          Size(frame.image.width.toDouble(), frame.image.height.toDouble()),
        );
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_dirty && !_busy,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) unawaited(_close());
    },
    child: PokeMapDialog(
      title: 'Carte régionale et lieux',
      maxWidth: 1140,
      footer: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          PokeMapButton(
            onPressed: _busy ? null : () => unawaited(_reload()),
            variant: PokeMapButtonVariant.ghost,
            child: const Text('Recharger'),
          ),
          if ((_pointId == null ? _savedRegion : _savedPoint) != null)
            PokeMapButton(
              onPressed: _busy ? null : () => unawaited(_delete()),
              variant: PokeMapButtonVariant.danger,
              child: const Text('Supprimer'),
            ),
          PokeMapButton(
            onPressed: _busy ? null : () => unawaited(_close()),
            variant: PokeMapButtonVariant.secondary,
            child: const Text('Fermer'),
          ),
          PokeMapButton(
            key: const ValueKey('regional-authoring-save'),
            onPressed: _snapshot == null || _busy
                ? null
                : () => unawaited(_save()),
            isLoading: _busy,
            child: Text(
              _pointId == null
                  ? 'Enregistrer la région'
                  : 'Enregistrer le lieu',
            ),
          ),
        ],
      ),
      child: SizedBox(
        width: 1100,
        height: math.max(
          220,
          math.min(690, MediaQuery.sizeOf(context).height - 210),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null)
              PokeMapDiagnosticCallout(
                key: const ValueKey('regional-authoring-error'),
                severity: PokeMapDiagnosticSeverity.error,
                message: _error!,
              ),
            if (_feedback != null)
              PokeMapDiagnosticCallout(
                severity: PokeMapDiagnosticSeverity.info,
                message: _feedback!,
              ),
            if (_snapshot != null)
              Expanded(
                child: ExcludeFocus(
                  excluding: _busy,
                  child: IgnorePointer(ignoring: _busy, child: _content()),
                ),
              )
            else
              const PokeMapDiagnosticCallout(
                severity: PokeMapDiagnosticSeverity.info,
                message: 'Chargement du projet…',
              ),
          ],
        ),
      ),
    ),
  );

  Widget _content() => LayoutBuilder(
    builder: (context, constraints) {
      final form = SingleChildScrollView(child: _form());
      final preview = PokeMapPanel(
        padding: const EdgeInsets.all(12),
        expandChild: true,
        child: _previewPanel(),
      );
      if (constraints.maxWidth < 800) {
        return Column(
          children: [
            SizedBox(height: constraints.maxHeight * .48, child: form),
            const SizedBox(height: 12),
            Expanded(child: preview),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 320, child: form),
          const SizedBox(width: 16),
          Expanded(child: preview),
        ],
      );
    },
  );

  Widget _form() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_regions.isNotEmpty)
        PokeMapDropdownField<String>(
          label: 'Région',
          value: _regionId!,
          items: [
            for (final region in _regions)
              PokeMapDropdownItem(value: region.id, label: region.label),
          ],
          onChanged: (id) => unawaited(
            _navigate(
              () => _selectRegion(_regions.singleWhere((r) => r.id == id)),
            ),
          ),
        ),
      const SizedBox(height: 8),
      PokeMapButton(
        key: const ValueKey('regional-authoring-new-region'),
        variant: PokeMapButtonVariant.secondary,
        onPressed: () => unawaited(_navigate(() => _selectRegion(null))),
        child: const Text('Nouvelle région'),
      ),
      if (_savedRegion != null) ...[
        const SizedBox(height: 12),
        PokeMapDropdownField<String>(
          key: const ValueKey('regional-authoring-selection'),
          label: 'Élément à modifier',
          value: _pointId ?? '',
          items: [
            const PokeMapDropdownItem(
              value: '',
              label: 'Région et illustration',
            ),
            for (final point in _points.where((p) => p.regionId == _regionId))
              PokeMapDropdownItem(value: point.id, label: point.label),
          ],
          onChanged: (id) => unawaited(
            _navigate(
              () => id.isEmpty
                  ? _selectRegion(_savedRegion)
                  : _selectPoint(_points.singleWhere((p) => p.id == id)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        PokeMapButton(
          key: const ValueKey('regional-authoring-new-point'),
          variant: PokeMapButtonVariant.secondary,
          onPressed: () => unawaited(_navigate(() => _selectPoint(null))),
          child: const Text('Ajouter un lieu'),
        ),
      ],
      const SizedBox(height: 16),
      if (_pointId == null) ...[
        PokeMapTextField(
          fieldKey: const ValueKey('regional-authoring-region-name'),
          label: 'Nom de la région',
          controller: _regionName,
          onChanged: (_) => _edit(() {}),
        ),
        const SizedBox(height: 12),
        _imageField('Illustration de la région', _regionImage, (path) {
          _regionImage = path;
          _image = _readImage();
        }),
        const SizedBox(height: 12),
        PokeMapDropdownField<ProjectMenuImageSampling>(
          label: 'Rendu de l’image',
          value: _sampling,
          items: const [
            PokeMapDropdownItem(
              value: ProjectMenuImageSampling.smooth,
              label: 'Illustration',
            ),
            PokeMapDropdownItem(
              value: ProjectMenuImageSampling.pixelArt,
              label: 'Pixel art',
            ),
          ],
          onChanged: (value) => _edit(() => _sampling = value),
        ),
      ] else ...[
        PokeMapTextField(
          fieldKey: const ValueKey('regional-authoring-point-name'),
          label: 'Nom du lieu',
          controller: _pointName,
          onChanged: (_) => _edit(() {}),
        ),
        const SizedBox(height: 12),
        PokeMapTextField(
          label: 'Description publique',
          controller: _description,
          minLines: 2,
          maxLines: 4,
          onChanged: (_) => _edit(() {}),
        ),
        const SizedBox(height: 12),
        _imageField(
          'Vignette facultative',
          _thumbnail,
          (path) => _thumbnail = path,
        ),
        const SizedBox(height: 12),
        PokeMapDropdownField<ProjectRegionPointVisibility>(
          label: 'Afficher le lieu',
          value: _visibility,
          items: const [
            PokeMapDropdownItem(
              value: ProjectRegionPointVisibility.always,
              label: 'Toujours, nom masqué avant découverte',
            ),
            PokeMapDropdownItem(
              value: ProjectRegionPointVisibility.discoveredOnly,
              label: 'Après sa découverte',
            ),
            PokeMapDropdownItem(
              value: ProjectRegionPointVisibility.hidden,
              label: 'Caché',
            ),
          ],
          onChanged: (value) => _edit(() => _visibility = value),
        ),
        const SizedBox(height: 12),
        PokeMapDropdownField<ProjectRegionPointDiscovery>(
          label: 'Connaissance du lieu',
          value: _discovery,
          items: const [
            PokeMapDropdownItem(
              value: ProjectRegionPointDiscovery.onMapVisit,
              label: 'Lors de la visite d’une carte liée',
            ),
            PokeMapDropdownItem(
              value: ProjectRegionPointDiscovery.always,
              label: 'Connu dès le début',
            ),
          ],
          onChanged: (value) => _edit(() => _discovery = value),
        ),
        const SizedBox(height: 12),
        PokeMapGuidedSlider(
          label: 'Position horizontale',
          value: (_u * 1000).round(),
          max: 1000,
          valueFormatter: (value) => '${(value / 10).toStringAsFixed(1)} %',
          onChanged: (value) => _edit(() => _u = value / 1000),
        ),
        PokeMapGuidedSlider(
          label: 'Position verticale',
          value: (_v * 1000).round(),
          max: 1000,
          valueFormatter: (value) => '${(value / 10).toStringAsFixed(1)} %',
          onChanged: (value) => _edit(() => _v = value / 1000),
        ),
        const SizedBox(height: 12),
        Text(
          'Cartes liées · ${_mapIds.length}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        PokeMapSearchField(
          key: ValueKey('regional-map-search-$_pointId'),
          hintText: 'Rechercher une carte…',
          onChanged: (value) =>
              setState(() => _mapSearch = value.toLowerCase()),
        ),
        const SizedBox(height: 8),
        for (final map in _snapshot!.manifest.maps.where(
          (m) => m.name.toLowerCase().contains(_mapSearch),
        )) ...[
          PokeMapToggleTile(
            key: ValueKey('regional-authoring-map-${map.id}'),
            label: map.name,
            value: _mapIds.contains(map.id),
            onChanged: (selected) => _edit(() {
              if (selected) {
                _mapIds.add(map.id);
              } else {
                _mapIds.remove(map.id);
              }
            }),
          ),
          const SizedBox(height: 6),
        ],
      ],
    ],
  );

  Widget _imageField(
    String label,
    String? value,
    ValueChanged<String?> changed,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      PokeMapDropdownField<String>(
        label: label,
        value: value ?? '',
        items: [
          const PokeMapDropdownItem(value: '', label: 'Aucune image'),
          for (final image in _snapshot!.images)
            PokeMapDropdownItem(value: image.path, label: image.label),
        ],
        onChanged: (path) => _edit(() => changed(path.isEmpty ? null : path)),
      ),
      const SizedBox(height: 8),
      PokeMapButton(
        variant: PokeMapButtonVariant.ghost,
        onPressed: () => unawaited(_importImage()),
        child: const Text('Importer une image…'),
      ),
    ],
  );

  Widget _previewPanel() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          PokeMapButton(
            variant: PokeMapButtonVariant.secondary,
            isSelected: !_showPreview,
            onPressed: () => setState(() => _showPreview = false),
            child: const Text('Placer les lieux'),
          ),
          PokeMapButton(
            key: const ValueKey('regional-authoring-player-preview'),
            variant: PokeMapButtonVariant.secondary,
            isSelected: _showPreview,
            onPressed: () => setState(() {
              _showPreview = true;
              _refreshPreview();
            }),
            child: const Text('Aperçu Player'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (_showPreview) ...[
        PokeMapDropdownField<String>(
          label: 'Position simulée',
          value: _previewMapId,
          items: [
            const PokeMapDropdownItem(value: '', label: 'Aucune position'),
            for (final map in _snapshot!.manifest.maps)
              PokeMapDropdownItem(value: map.id, label: map.name),
          ],
          onChanged: (id) => setState(() {
            _previewMapId = id;
            _refreshPreview();
          }),
        ),
        if (_pointId != null) ...[
          const SizedBox(height: 8),
          PokeMapToggleTile(
            key: const ValueKey('regional-authoring-preview-visited'),
            label: 'Simuler les cartes de ce lieu déjà visitées',
            value: _previewVisited,
            onChanged: (value) => setState(() {
              _previewVisited = value;
              _refreshPreview();
            }),
          ),
        ],
        const SizedBox(height: 12),
        Expanded(child: _playerPreview()),
      ] else ...[
        Text(
          _pointId == null
              ? 'Choisissez une illustration, puis ajoutez les lieux.'
              : 'Cliquez sur l’image pour placer le lieu. Les marges sont ignorées.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.pokeMapColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _placement()),
      ],
    ],
  );

  Widget _playerPreview() {
    if (_previewError != null) {
      return PokeMapDiagnosticCallout(
        severity: PokeMapDiagnosticSeverity.warning,
        message: _previewError!,
      );
    }
    return FutureBuilder<RuntimePlayerPauseDetailSnapshot>(
      future: _preview,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.error,
            message: _message(snapshot.error!),
          );
        }
        if (snapshot.connectionState != ConnectionState.done ||
            !snapshot.hasData) {
          return const Center(child: Text('Préparation de l’aperçu…'));
        }
        return Theme(
          data: RuntimePlayerPresentation.fromProfile(
            _snapshot!.manifest.presentation ??
                const ProjectPresentationProfile(),
          ).applyTo(PokeMapPlayerTheme.dark()),
          child: PlayerMenuThemeScope(
            role: ProjectPresentationSurfaceRole.map,
            child: RuntimePlayerRegionMap(
              detail: snapshot.data!,
              hardwareGamepadEnabled: false,
            ),
          ),
        );
      },
    );
  }

  Widget _placement() => FutureBuilder<_RegionalImage?>(
    future: _image,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: Text('Chargement de l’illustration…'));
      }
      if (snapshot.hasError) {
        return PokeMapDiagnosticCallout(
          severity: PokeMapDiagnosticSeverity.error,
          message:
              'Cette illustration ne peut pas être affichée. Choisissez une autre image.',
        );
      }
      final image = snapshot.data;
      if (image == null) {
        return const Center(
          child: Text('Aucune illustration régionale sélectionnée.'),
        );
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          final geometry = RegionMapGeometry(
            viewport: constraints.biggest,
            imageSize: image.size,
          );
          final points = <({String id, String name, double u, double v})>[
            for (final point in _points.where(
              (p) => p.regionId == _regionId && p.id != _pointId,
            ))
              (id: point.id, name: point.label, u: point.u, v: point.v),
            if (_pointId != null)
              (id: _pointId!, name: _pointName.text.trim(), u: _u, v: _v),
          ];
          return GestureDetector(
            key: const ValueKey('regional-authoring-placement'),
            behavior: HitTestBehavior.opaque,
            onTapUp: _pointId == null
                ? null
                : (event) {
                    if (!geometry.transformedImageRect.contains(
                      event.localPosition,
                    )) {
                      return;
                    }
                    final position = geometry.unproject(event.localPosition);
                    _edit(() {
                      _u = position.dx;
                      _v = position.dy;
                    });
                  },
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: Image.memory(
                    image.bytes,
                    fit: BoxFit.contain,
                    filterQuality:
                        _sampling == ProjectMenuImageSampling.pixelArt
                        ? FilterQuality.none
                        : FilterQuality.medium,
                  ),
                ),
                for (final point in points)
                  Positioned(
                    left: geometry.project(Offset(point.u, point.v)).dx,
                    top: geometry.project(Offset(point.u, point.v)).dy,
                    child: FractionalTranslation(
                      translation: const Offset(-.5, -.5),
                      child: IgnorePointer(
                        child: Tooltip(
                          message: point.name,
                          child: PokeMapBadge(
                            key: ValueKey('regional-authoring-pin-${point.id}'),
                            label: '●',
                            variant: point.id == _pointId
                                ? PokeMapBadgeVariant.info
                                : PokeMapBadgeVariant.neutral,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}

final class _RegionalImage {
  const _RegionalImage(this.bytes, this.size);
  final Uint8List bytes;
  final Size size;
}
