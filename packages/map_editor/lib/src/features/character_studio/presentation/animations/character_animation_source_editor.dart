import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../application/character_animation_matrix_model.dart';
import '../../application/character_animation_source_slicing.dart';
import '../../application/character_studio_media_resolver.dart';
import 'character_animation_frame_timeline.dart';
import 'character_animation_preview.dart';

class CharacterAnimationSourceEditor extends StatefulWidget {
  const CharacterAnimationSourceEditor({
    super.key,
    required this.slot,
    required this.projectRootPath,
    required this.projectRevision,
    required this.mediaResolver,
    required this.enabled,
    required this.onImportSource,
    required this.onFramesChanged,
    required this.onLoopChanged,
    this.animationLabel,
    this.legacySourcePath,
    this.legacyFrameWidth,
    this.legacyFrameHeight,
    this.legacySourceLoader,
  });

  final CharacterAnimationMatrixSlot slot;
  final String projectRootPath;
  final String projectRevision;
  final CharacterStudioMediaResolverContract mediaResolver;
  final bool enabled;
  final Future<void> Function() onImportSource;
  final Future<void> Function(List<CharacterAnimationFrame> frames)
  onFramesChanged;
  final Future<void> Function(bool loop) onLoopChanged;
  final String? animationLabel;
  final String? legacySourcePath;
  final int? legacyFrameWidth;
  final int? legacyFrameHeight;
  final Future<Uint8List> Function(String path)? legacySourceLoader;

  @override
  State<CharacterAnimationSourceEditor> createState() =>
      _CharacterAnimationSourceEditorState();
}

class _CharacterAnimationSourceEditorState
    extends State<CharacterAnimationSourceEditor> {
  final TextEditingController _columnsController = TextEditingController(
    text: '1',
  );
  final TextEditingController _rowsController = TextEditingController(
    text: '1',
  );
  final TextEditingController _durationController = TextEditingController(
    text: '150',
  );
  Future<Uint8List>? _source;
  String? _sourceIdentity;
  bool _usesLegacyGrid = false;
  String? _gridError;

  @override
  void initState() {
    super.initState();
    _refreshSource();
  }

  @override
  void didUpdateWidget(covariant CharacterAnimationSourceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshSource();
  }

  @override
  void dispose() {
    _columnsController.dispose();
    _rowsController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final source = _source;
    if (source == null) {
      return PokeMapPanel(
        key: const ValueKey<String>('animation-source-editor-empty'),
        padding: const EdgeInsets.all(20),
        expandChild: true,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PokeMapEmptyState(
                title: 'Animation à configurer',
                description:
                    '1. Choisissez un PNG. 2. Indiquez ses colonnes et lignes. 3. Appliquez la grille pour créer les frames.',
                icon: Icon(CupertinoIcons.photo_on_rectangle),
                compact: true,
              ),
              const SizedBox(height: 8),
              PokeMapBadge(
                label: _slotDisplayLabel,
                variant: PokeMapBadgeVariant.info,
              ),
              const SizedBox(height: 14),
              PokeMapButton(
                key: const ValueKey<String>('animation-source-import'),
                onPressed: widget.enabled ? _requestSourceImport : null,
                leading: const Icon(CupertinoIcons.folder_open),
                child: const Text('Importer un PNG'),
              ),
            ],
          ),
        ),
      );
    }
    return FutureBuilder<Uint8List>(
      future: source,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const PokeMapPanel(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return PokeMapPanel(
            key: const ValueKey<String>('animation-source-editor-error'),
            child: PokeMapEmptyState(
              title: _usesLegacyGrid
                  ? 'Tileset historique indisponible'
                  : 'Source indisponible',
              description: _usesLegacyGrid
                  ? 'Le tileset du personnage ne peut pas être chargé. ${snapshot.error ?? ''}'
                  : 'Le PNG portable ne peut pas être chargé. ${snapshot.error ?? ''}',
              icon: const Icon(CupertinoIcons.exclamationmark_triangle),
              action: PokeMapButton(
                onPressed: widget.enabled ? _requestSourceImport : null,
                child: Text(
                  _usesLegacyGrid
                      ? 'Importer un PNG portable'
                      : 'Remplacer la source',
                ),
              ),
            ),
          );
        }
        try {
          final dimensions = CharacterAnimationSourceDimensions.fromPng(
            snapshot.data!,
          );
          return _usesLegacyGrid
              ? _legacyContent(context, snapshot.data!)
              : _content(context, snapshot.data!, dimensions);
        } on CharacterAnimationSlicingException catch (error) {
          return PokeMapPanel(
            child: PokeMapEmptyState(
              title: 'Source PNG invalide',
              description: error.message,
              icon: const Icon(CupertinoIcons.exclamationmark_triangle),
              action: PokeMapButton(
                onPressed: widget.enabled ? _requestSourceImport : null,
                child: const Text('Importer un autre PNG'),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _content(
    BuildContext context,
    Uint8List bytes,
    CharacterAnimationSourceDimensions dimensions,
  ) {
    return SingleChildScrollView(
      key: const ValueKey<String>('animation-source-editor'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CharacterAnimationPreview(
            sourceBytes: bytes,
            frames: widget.slot.frames,
            loop: widget.slot.loop,
            slotIdentity: widget.slot.key.stableId,
            directionLabel: _slotDisplayLabel,
            enabled: widget.enabled,
            onLoopChanged: widget.onLoopChanged,
          ),
          const SizedBox(height: 10),
          PokeMapPanel(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Source et découpe',
                            style: TextStyle(
                              color: context.pokeMapColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${dimensions.width} × ${dimensions.height} px · PNG',
                            key: const ValueKey<String>(
                              'animation-source-dimensions',
                            ),
                            style: TextStyle(
                              color: context.pokeMapColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PokeMapButton(
                      key: const ValueKey<String>('animation-source-replace'),
                      onPressed: widget.enabled ? _requestSourceImport : null,
                      variant: PokeMapButtonVariant.secondary,
                      leading: const Icon(CupertinoIcons.arrow_2_circlepath),
                      child: const Text('Remplacer'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  height: 150,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.pokeMapColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: context.pokeMapColors.borderSubtle,
                    ),
                  ),
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                    gaplessPlayback: true,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: PokeMapTextField(
                        label: 'Colonnes',
                        fieldKey: const ValueKey<String>(
                          'animation-grid-columns',
                        ),
                        controller: _columnsController,
                        enabled: widget.enabled,
                        keyboardType: TextInputType.number,
                        inputFormatters: _digitsOnly,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PokeMapTextField(
                        label: 'Lignes',
                        fieldKey: const ValueKey<String>('animation-grid-rows'),
                        controller: _rowsController,
                        enabled: widget.enabled,
                        keyboardType: TextInputType.number,
                        inputFormatters: _digitsOnly,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PokeMapTextField(
                        label: 'Durée (ms)',
                        fieldKey: const ValueKey<String>(
                          'animation-grid-duration',
                        ),
                        controller: _durationController,
                        enabled: widget.enabled,
                        keyboardType: TextInputType.number,
                        inputFormatters: _digitsOnly,
                      ),
                    ),
                  ],
                ),
                if (_gridError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _gridError!,
                    key: const ValueKey<String>('animation-grid-error'),
                    style: TextStyle(
                      color: context.pokeMapColors.error,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: PokeMapButton(
                    key: const ValueKey<String>('animation-grid-apply'),
                    onPressed: widget.enabled
                        ? () => _applyGrid(dimensions)
                        : null,
                    leading: const Icon(CupertinoIcons.square_grid_3x2),
                    child: const Text('Appliquer la grille'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          CharacterAnimationFrameTimeline(
            frames: widget.slot.frames,
            dimensions: dimensions,
            enabled: widget.enabled,
            onChanged: (frames) => widget.onFramesChanged(frames),
          ),
        ],
      ),
    );
  }

  Future<void> _applyGrid(CharacterAnimationSourceDimensions dimensions) async {
    try {
      final frames = CharacterAnimationSourceSlicing.grid(
        dimensions: dimensions,
        columns: int.tryParse(_columnsController.text) ?? 0,
        rows: int.tryParse(_rowsController.text) ?? 0,
        durationMs: int.tryParse(_durationController.text) ?? 0,
      );
      setState(() => _gridError = null);
      await widget.onFramesChanged(frames);
    } on CharacterAnimationSlicingException catch (error) {
      setState(() => _gridError = error.message);
    }
  }

  void _refreshSource() {
    final assetId = widget.slot.sourceAssetId?.trim();
    final portableAssetId = assetId == null || assetId.isEmpty ? null : assetId;
    final legacyPath = portableAssetId == null && widget.slot.frames.isNotEmpty
        ? widget.legacySourcePath?.trim()
        : null;
    final identity = portableAssetId != null
        ? 'portable|${widget.projectRootPath}|$portableAssetId|${widget.projectRevision}'
        : legacyPath == null || legacyPath.isEmpty
        ? null
        : 'legacy|$legacyPath|${widget.projectRevision}';
    if (identity == _sourceIdentity) return;
    _sourceIdentity = identity;
    _usesLegacyGrid = portableAssetId == null && identity != null;
    _source = portableAssetId != null
        ? widget.mediaResolver.resolve(
            CharacterStudioMediaRequest(
              projectRootPath: widget.projectRootPath,
              assetId: portableAssetId,
              projectRevision: widget.projectRevision,
            ),
          )
        : legacyPath == null || legacyPath.isEmpty
        ? null
        : (widget.legacySourceLoader ?? _readLegacySource)(legacyPath);
  }

  Widget _legacyContent(BuildContext context, Uint8List bytes) {
    return SingleChildScrollView(
      key: const ValueKey<String>('animation-source-editor-legacy'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CharacterAnimationPreview(
            sourceBytes: bytes,
            frames: _legacyPreviewFrames(),
            loop: widget.slot.loop,
            slotIdentity: 'legacy-${widget.slot.key.stableId}',
            directionLabel: _slotDisplayLabel,
            enabled: widget.enabled,
            onLoopChanged: widget.onLoopChanged,
          ),
          const SizedBox(height: 10),
          PokeMapPanel(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Source historique du tileset',
                  style: TextStyle(
                    color: context.pokeMapColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cette animation fonctionne déjà et peut être prévisualisée. Importez un PNG uniquement si vous voulez la redécouper ou utiliser une source dédiée.',
                  style: TextStyle(
                    color: context.pokeMapColors.textSecondary,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: PokeMapButton(
                    key: const ValueKey<String>('animation-source-replace'),
                    onPressed: widget.enabled ? _requestSourceImport : null,
                    leading: const Icon(CupertinoIcons.folder_open),
                    child: const Text('Utiliser un PNG dédié'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<CharacterAnimationFrame> _legacyPreviewFrames() {
    final frameWidth = widget.legacyFrameWidth;
    final frameHeight = widget.legacyFrameHeight;
    if (frameWidth == null || frameHeight == null) {
      return const <CharacterAnimationFrame>[];
    }
    return <CharacterAnimationFrame>[
      for (final frame in widget.slot.frames)
        frame.copyWith(
          source: TilesetSourceRect(
            x: frame.source.x * frameWidth,
            y: frame.source.y * frameHeight,
            width: frameWidth,
            height: frameHeight,
          ),
        ),
    ];
  }

  Future<void> _requestSourceImport() async {
    if (widget.slot.frames.isEmpty) {
      await widget.onImportSource();
      return;
    }
    final confirmed = await showPokeMapBinaryConfirmationDialog(
      context,
      title: 'Remplacer cette source ?',
      message:
          'Les ${widget.slot.frames.length} frame(s) actuelles seront réinitialisées. Vous devrez ensuite appliquer la grille du nouveau PNG.',
      secondaryLabel: 'Annuler',
      primaryLabel: 'Remplacer quand même',
      primaryIsDestructive: true,
      icon: CupertinoIcons.exclamationmark_triangle,
    );
    if (!confirmed || !mounted) return;
    await widget.onImportSource();
  }

  String get _slotDisplayLabel {
    final animation = widget.animationLabel?.trim();
    if (animation == null || animation.isEmpty) return widget.slot.label;
    return '$animation · ${widget.slot.label}';
  }
}

final List<TextInputFormatter> _digitsOnly = <TextInputFormatter>[
  FilteringTextInputFormatter.digitsOnly,
];

Future<Uint8List> _readLegacySource(String path) => File(path).readAsBytes();
