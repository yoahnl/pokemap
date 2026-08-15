import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../../application/authoring_api/presentation_studio_add_authoring_gateway.dart';
import '../../../design_system/design_system.dart';

class PresentationStudioAddPanel extends StatefulWidget {
  const PresentationStudioAddPanel({
    super.key,
    required this.gateway,
    required this.mediaPicker,
    required this.projectRootPath,
    required this.expectedProject,
    required this.asset,
    required this.playheadUs,
    required this.onProjectChanged,
    required this.onInserted,
    this.targetVisualFolderId,
  });

  final PresentationStudioAddAuthoringGateway gateway;
  final PresentationStudioMediaPicker mediaPicker;
  final String projectRootPath;
  final ProjectManifest expectedProject;
  final PresentationCinematicAsset asset;
  final int playheadUs;
  final String? targetVisualFolderId;
  final ValueChanged<ProjectManifest> onProjectChanged;
  final ValueChanged<PresentationStudioInsertionResult> onInserted;

  @override
  State<PresentationStudioAddPanel> createState() =>
      _PresentationStudioAddPanelState();
}

class _PresentationStudioAddPanelState
    extends State<PresentationStudioAddPanel> {
  PresentationStudioAddCategory _category =
      PresentationStudioAddCategory.visual;
  ProjectManifest? _currentProject;
  List<PresentationStudioMediaCatalogItem> _media = const [];
  PresentationStudioMediaCatalogItem? _selectedMedia;
  String _query = '';
  String? _loadError;
  String? _mutationError;
  bool _loading = true;
  bool _importing = false;
  bool _inserting = false;
  bool _insertionComplete = false;
  bool _durationAdjusted = false;
  int _importGeneration = 0;
  late int _frozenPlayheadUs;
  late String? _frozenTargetVisualFolderId;

  ProjectManifest get _project => _currentProject ?? widget.expectedProject;
  PresentationCinematicAsset get _asset => _project.presentationCinematics
      .singleWhere((item) => item.id == widget.asset.id);

  @override
  void initState() {
    super.initState();
    _freezeTarget();
    unawaited(_loadMedia());
  }

  @override
  void didUpdateWidget(covariant PresentationStudioAddPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectRootPath != widget.projectRootPath) {
      _currentProject = null;
      _selectedMedia = null;
      _freezeTarget();
      unawaited(_loadMedia());
    } else if (oldWidget.asset.id != widget.asset.id) {
      _currentProject = null;
      _selectedMedia = null;
      _freezeTarget();
      unawaited(_loadMedia());
    } else if (oldWidget.expectedProject != widget.expectedProject &&
        _currentProject == null) {
      _currentProject = widget.expectedProject;
    }
  }

  Future<void> _loadMedia() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final media = await widget.gateway.loadMedia(widget.projectRootPath);
      if (!mounted) return;
      setState(() {
        _media = media;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = _message(error);
        _loading = false;
      });
    }
  }

  Future<void> _importMedia() async {
    final picked = await widget.mediaPicker.pick(_category);
    if (picked == null || !mounted) return;
    final generation = ++_importGeneration;
    setState(() {
      _importing = true;
      _mutationError = null;
    });
    try {
      final result = await widget.gateway.importMedia(
        widget.projectRootPath,
        expectedProject: _project,
        request: PresentationStudioMediaImportRequest(
          category: _category,
          picked: picked,
        ),
        isCancelled: () => generation != _importGeneration,
      );
      if (!mounted || generation != _importGeneration) return;
      setState(() {
        _currentProject = result.manifest;
        _media = <PresentationStudioMediaCatalogItem>[
          ..._media.where((item) => item.id != result.media.id),
          result.media,
        ]..sort((left, right) => left.label.compareTo(right.label));
        _selectedMedia = result.media;
        _importing = false;
        _insertionComplete = false;
      });
      widget.onProjectChanged(result.manifest);
    } on PresentationStudioImportCancelled {
      if (!mounted || generation != _importGeneration) return;
      setState(() => _importing = false);
    } on Object catch (error) {
      if (!mounted || generation != _importGeneration) return;
      setState(() {
        _importing = false;
        _mutationError = _message(error);
      });
    }
  }

  void _cancelImport() {
    _importGeneration += 1;
    setState(() => _importing = false);
  }

  Future<void> _insert() async {
    if (!_canInsert) return;
    final media = _selectedMedia;
    final durationUs = _effectiveDurationUs;
    setState(() {
      _inserting = true;
      _mutationError = null;
    });
    try {
      final result = await widget.gateway.insert(
        widget.projectRootPath,
        expectedProject: _project,
        request: PresentationStudioInsertionRequest(
          asset: _asset,
          category: _category,
          playheadUs: _frozenPlayheadUs,
          durationUs: durationUs,
          label: media?.label ?? _quickLabel(_category),
          mediaId: media?.id,
          targetVisualFolderId: _frozenTargetVisualFolderId,
        ),
      );
      if (!mounted) return;
      setState(() {
        _currentProject = result.manifest;
        _inserting = false;
        _insertionComplete = true;
      });
      widget.onProjectChanged(result.manifest);
      widget.onInserted(result);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _inserting = false;
        _mutationError = _message(error);
      });
    }
  }

  bool get _isQuickCategory =>
      _category == PresentationStudioAddCategory.text ||
      _category == PresentationStudioAddCategory.marker;

  bool get _durationConflict {
    final duration = _proposedDurationUs;
    return duration > _remainingDurationUs;
  }

  bool get _canInsert =>
      !_loading &&
      !_importing &&
      !_inserting &&
      !_insertionComplete &&
      (_isQuickCategory ||
          _selectedMedia?.availability ==
              PresentationStudioMediaAvailability.ready) &&
      (!_durationConflict || _durationAdjusted) &&
      (_category == PresentationStudioAddCategory.marker ||
          _remainingDurationUs > 0);

  int get _remainingDurationUs =>
      (_asset.durationUs - _frozenPlayheadUs).clamp(0, _asset.durationUs);

  int get _proposedDurationUs {
    if (_category == PresentationStudioAddCategory.marker) return 0;
    return _selectedMedia?.durationUs ?? 5000000;
  }

  int get _effectiveDurationUs => _durationAdjusted
      ? _remainingDurationUs
      : _proposedDurationUs.clamp(1, _remainingDurationUs);

  List<PresentationStudioMediaCatalogItem> get _visibleMedia {
    final query = _query.trim().toLowerCase();
    return <PresentationStudioMediaCatalogItem>[
      for (final item in _media)
        if (_belongsToCategory(item, _category) &&
            (query.isEmpty || item.label.toLowerCase().contains(query)))
          item,
    ];
  }

  @override
  Widget build(BuildContext context) => FocusTraversalGroup(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PokeMapSearchField(
                key: const ValueKey<String>('presentation-add-search'),
                hintText: 'Rechercher dans les médias…',
                semanticLabel: 'Rechercher un média à ajouter',
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (final category in PresentationStudioAddCategory.values)
                    PokeMapButton(
                      key: ValueKey<String>(
                        'presentation-add-category-${category.name}',
                      ),
                      onPressed: () => _selectCategory(category),
                      variant: PokeMapButtonVariant.ghost,
                      size: PokeMapButtonSize.small,
                      isSelected: _category == category,
                      child: Text(_categoryLabel(category)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Insertion à ${_formatTime(_frozenPlayheadUs)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  if (_frozenTargetVisualFolderId != null)
                    PokeMapBadge(
                      label: 'Dossier $_frozenTargetVisualFolderId',
                      variant: PokeMapBadgeVariant.info,
                    ),
                ],
              ),
              if (!_isQuickCategory) ...<Widget>[
                const SizedBox(height: 10),
                PokeMapButton(
                  key: const ValueKey<String>('presentation-add-import'),
                  onPressed: _importing
                      ? null
                      : () => unawaited(_importMedia()),
                  leading: const Icon(Icons.file_upload_outlined),
                  size: PokeMapButtonSize.small,
                  child: const Text('Importer un média'),
                ),
              ],
              if (_importing) ...<Widget>[
                const SizedBox(height: 10),
                Semantics(
                  liveRegion: true,
                  label: 'Import en cours',
                  child: const Text('Import en cours…'),
                ),
                const SizedBox(height: 6),
                const PokeMapProgressBar(
                  value: 0.5,
                  semanticLabel: 'Progression de l’import',
                ),
                const SizedBox(height: 6),
                PokeMapButton(
                  onPressed: _cancelImport,
                  variant: PokeMapButtonVariant.ghost,
                  size: PokeMapButtonSize.small,
                  child: const Text('Annuler l’import'),
                ),
              ],
            ],
          ),
        ),
        Expanded(child: _catalogBody()),
        if (_durationConflict)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.warning,
              title: 'Conflit de durée',
              message: 'Ce média dépasse la durée restante de la cinématique.',
              actionLabel: 'Ajuster à la durée restante',
              onAction: () => setState(() => _durationAdjusted = true),
            ),
          ),
        if (_mutationError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.error,
              title: 'Action impossible',
              message: _mutationError!,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: PokeMapButton(
            key: const ValueKey<String>('presentation-add-confirm'),
            onPressed: _canInsert ? () => unawaited(_insert()) : null,
            isLoading: _inserting,
            leading: const Icon(Icons.add_to_queue_rounded),
            child: Text(
              _insertionComplete
                  ? 'Ajouté à la timeline'
                  : 'Ajouter à la timeline',
            ),
          ),
        ),
      ],
    ),
  );

  Widget _catalogBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            PokeMapProgressBar(
              value: 0.5,
              semanticLabel: 'Chargement du catalogue média',
            ),
            SizedBox(height: 10),
            Text('Chargement du catalogue…'),
          ],
        ),
      );
    }
    if (_loadError != null) {
      return PokeMapEmptyState(
        compact: true,
        icon: const Icon(Icons.cloud_off_outlined),
        title: 'Catalogue indisponible',
        description: _loadError,
        action: PokeMapButton(
          onPressed: () => unawaited(_loadMedia()),
          size: PokeMapButtonSize.small,
          child: const Text('Réessayer'),
        ),
      );
    }
    if (_isQuickCategory) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        children: <Widget>[
          PokeMapCinematicMediaCatalogCard(
            title: _quickLabel(_category),
            metadata: _category == PresentationStudioAddCategory.text
                ? 'Bloc texte éditable après insertion'
                : 'Repère à la tête de lecture',
            preview: Icon(
              _category == PresentationStudioAddCategory.text
                  ? Icons.text_fields_rounded
                  : Icons.bookmark_add_outlined,
            ),
            selected: true,
            onPressed: () => setState(() {}),
          ),
        ],
      );
    }
    final visible = _visibleMedia;
    if (visible.isEmpty) {
      return PokeMapEmptyState(
        compact: true,
        icon: const Icon(Icons.perm_media_outlined),
        title: _query.trim().isEmpty
            ? 'Aucun média dans cette catégorie'
            : 'Aucun résultat',
        description: _query.trim().isEmpty
            ? 'Importez un média pour commencer.'
            : 'Essayez une autre recherche.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      itemCount: visible.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = visible[index];
        final ready =
            item.availability == PresentationStudioMediaAvailability.ready;
        return PokeMapCinematicMediaCatalogCard(
          key: ValueKey<String>('presentation-add-media-${item.id}'),
          title: item.label,
          metadata: item.metadataLabel,
          preview: Icon(_mediaIcon(item.kind)),
          selected: _selectedMedia?.id == item.id,
          onPressed: ready ? () => _selectMedia(item) : null,
          disabledReason: ready ? null : _availabilityLabel(item.availability),
          status: PokeMapBadge(
            label: _availabilityLabel(item.availability),
            variant: _availabilityVariant(item.availability),
            icon: Icon(_availabilityIcon(item.availability)),
          ),
        );
      },
    );
  }

  void _selectCategory(PresentationStudioAddCategory category) {
    setState(() {
      _category = category;
      _selectedMedia = null;
      _insertionComplete = false;
      _durationAdjusted = false;
      _mutationError = null;
    });
  }

  void _selectMedia(PresentationStudioMediaCatalogItem item) {
    setState(() {
      _selectedMedia = item;
      _insertionComplete = false;
      _durationAdjusted = false;
      _mutationError = null;
    });
  }

  void _freezeTarget() {
    _frozenPlayheadUs = widget.playheadUs;
    _frozenTargetVisualFolderId = widget.targetVisualFolderId;
    _insertionComplete = false;
  }
}

bool _belongsToCategory(
  PresentationStudioMediaCatalogItem item,
  PresentationStudioAddCategory category,
) => switch (category) {
  PresentationStudioAddCategory.visual =>
    item.kind == ProjectMediaKind.image || item.kind == ProjectMediaKind.poster,
  PresentationStudioAddCategory.audio => item.kind == ProjectMediaKind.audio,
  PresentationStudioAddCategory.video => item.kind == ProjectMediaKind.video,
  PresentationStudioAddCategory.accessibility =>
    item.kind == ProjectMediaKind.captions,
  PresentationStudioAddCategory.text ||
  PresentationStudioAddCategory.marker => false,
};

String _categoryLabel(PresentationStudioAddCategory category) =>
    switch (category) {
      PresentationStudioAddCategory.visual => 'Visuel',
      PresentationStudioAddCategory.text => 'Texte',
      PresentationStudioAddCategory.audio => 'Audio',
      PresentationStudioAddCategory.video => 'Vidéo',
      PresentationStudioAddCategory.accessibility => 'Accessibilité',
      PresentationStudioAddCategory.marker => 'Repères',
    };

String _quickLabel(PresentationStudioAddCategory category) =>
    switch (category) {
      PresentationStudioAddCategory.text => 'Nouveau texte',
      PresentationStudioAddCategory.marker => 'Nouveau repère',
      _ => throw ArgumentError.value(category, 'category'),
    };

String _availabilityLabel(PresentationStudioMediaAvailability availability) =>
    switch (availability) {
      PresentationStudioMediaAvailability.ready => 'Prêt',
      PresentationStudioMediaAvailability.missing => 'Manquant',
      PresentationStudioMediaAvailability.corrupt => 'Corrompu',
      PresentationStudioMediaAvailability.unsupported => 'Non supporté',
    };

PokeMapBadgeVariant _availabilityVariant(
  PresentationStudioMediaAvailability availability,
) => switch (availability) {
  PresentationStudioMediaAvailability.ready => PokeMapBadgeVariant.success,
  PresentationStudioMediaAvailability.missing => PokeMapBadgeVariant.warning,
  PresentationStudioMediaAvailability.corrupt => PokeMapBadgeVariant.error,
  PresentationStudioMediaAvailability.unsupported =>
    PokeMapBadgeVariant.warning,
};

IconData _availabilityIcon(PresentationStudioMediaAvailability availability) =>
    switch (availability) {
      PresentationStudioMediaAvailability.ready => Icons.check_circle_outline,
      PresentationStudioMediaAvailability.missing => Icons.link_off_rounded,
      PresentationStudioMediaAvailability.corrupt =>
        Icons.broken_image_outlined,
      PresentationStudioMediaAvailability.unsupported => Icons.block_rounded,
    };

IconData _mediaIcon(ProjectMediaKind kind) {
  if (kind == ProjectMediaKind.video) return Icons.movie_outlined;
  if (kind == ProjectMediaKind.audio) return Icons.music_note_rounded;
  if (kind == ProjectMediaKind.captions) return Icons.closed_caption_outlined;
  return Icons.image_outlined;
}

String _formatTime(int microseconds) {
  final duration = Duration(microseconds: microseconds);
  final minutes = duration.inMinutes.toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  final milliseconds = (duration.inMilliseconds % 1000) ~/ 10;
  return '$minutes:$seconds.${milliseconds.toString().padLeft(2, '0')}';
}

String _message(Object error) {
  final value = error.toString().trim();
  return value.isEmpty ? 'Une erreur inconnue est survenue.' : value;
}
