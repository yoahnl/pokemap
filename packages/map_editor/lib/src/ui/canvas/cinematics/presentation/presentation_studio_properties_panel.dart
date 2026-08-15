import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/presentation_renderer.dart';

import '../../../../application/authoring_api/presentation_studio_property_command.dart';
import '../../../design_system/design_system.dart';
import 'presentation_studio_layer_tree.dart';

const _unsetProperty = Object();

class PresentationStudioPropertiesPanel extends StatelessWidget {
  const PresentationStudioPropertiesPanel({
    super.key,
    required this.asset,
    required this.selectionController,
    required this.orientation,
    required this.onCommand,
    this.selectedClipIds = const <String>{},
    this.markerUsageCountById = const <String, int>{},
    this.mutationPending = false,
    this.canUndo = false,
    this.canRedo = false,
    this.onUndo,
    this.onRedo,
  });

  final PresentationCinematicAsset asset;
  final PresentationStudioSelectionController selectionController;
  final PresentationFrameOrientation orientation;
  final ValueChanged<PresentationStudioPropertyCommand> onCommand;
  final Set<String> selectedClipIds;
  final Map<String, int> markerUsageCountById;
  final bool mutationPending;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: selectionController,
    builder: (context, _) {
      final selection = selectionController.value;
      final located = selection?.clipId == null
          ? null
          : _locateClip(asset, selection!.clipId!);
      final layer = selection?.layerId == null
          ? null
          : _findLayer(asset, selection!.layerId!);
      return Column(
        children: <Widget>[
          _InspectorToolbar(
            mutationPending: mutationPending,
            canUndo: canUndo,
            canRedo: canRedo,
            onUndo: onUndo,
            onRedo: onRedo,
          ),
          Expanded(
            child: SingleChildScrollView(
              key: ValueKey<String>(
                'presentation-properties-${selection?.clipId ?? selection?.layerId ?? 'document'}',
              ),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (selectedClipIds.length > 1)
                    _MixedSelectionInspector(selectedClipIds: selectedClipIds)
                  else if (located == null && layer == null)
                    PresentationDocumentInspectorSection(
                      key: ValueKey<String>('document-${asset.id}'),
                      asset: asset,
                      onCommand: onCommand,
                    )
                  else if (located == null)
                    PresentationLayerInspectorSection(
                      key: ValueKey<String>('layer-${layer!.id}'),
                      cinematicId: asset.id,
                      layer: layer,
                      onCommand: onCommand,
                    )
                  else
                    ..._clipSections(located),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );

  List<Widget> _clipSections(_LocatedClip located) => switch (located.clip) {
    final PresentationVisualClip clip => <Widget>[
      PresentationVisualInspectorSection(
        key: ValueKey<String>('visual-${clip.id}-${orientation.name}'),
        cinematicId: asset.id,
        trackId: located.track.id,
        clip: clip,
        orientation: orientation,
        onCommand: onCommand,
      ),
      const SizedBox(height: 12),
      PresentationTransitionInspectorSection(
        key: ValueKey<String>('transition-${clip.id}'),
        cinematicId: asset.id,
        trackId: located.track.id,
        clip: clip,
        onCommand: onCommand,
      ),
    ],
    final PresentationTextClip clip => <Widget>[
      PresentationTextInspectorSection(
        key: ValueKey<String>('text-${clip.id}'),
        cinematicId: asset.id,
        trackId: located.track.id,
        clip: clip,
        onCommand: onCommand,
      ),
      const SizedBox(height: 12),
      PresentationTransitionInspectorSection(
        key: ValueKey<String>('transition-${clip.id}'),
        cinematicId: asset.id,
        trackId: located.track.id,
        clip: clip,
        onCommand: onCommand,
      ),
    ],
    final PresentationAudioClip clip => <Widget>[
      PresentationAudioInspectorSection(
        key: ValueKey<String>('audio-${clip.id}'),
        cinematicId: asset.id,
        trackId: located.track.id,
        clip: clip,
        onCommand: onCommand,
      ),
    ],
    final PresentationCaptionClip clip => <Widget>[
      PresentationCaptionInspectorSection(
        key: ValueKey<String>('caption-${clip.id}'),
        cinematicId: asset.id,
        cinematicDurationUs: asset.durationUs,
        trackId: located.track.id,
        clip: clip,
        onCommand: onCommand,
      ),
    ],
    final PresentationMarkerClip clip => <Widget>[
      PresentationMarkerInspectorSection(
        key: ValueKey<String>('marker-${clip.id}'),
        cinematicId: asset.id,
        trackId: located.track.id,
        clip: clip,
        sceneUsageCount: markerUsageCountById[clip.id] ?? 0,
        onCommand: onCommand,
      ),
    ],
  };
}

class _MixedSelectionInspector extends StatelessWidget {
  const _MixedSelectionInspector({required this.selectedClipIds});

  final Set<String> selectedClipIds;

  @override
  Widget build(BuildContext context) => PokeMapCinematicInspectorSection(
    title: 'Sélection multiple',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PokeMapBadge(
          label: '${selectedClipIds.length} clips sélectionnés',
          variant: PokeMapBadgeVariant.info,
        ),
        const SizedBox(height: 8),
        const Text(
          'Les déplacements et suppressions groupés restent disponibles dans '
          'la timeline. Sélectionnez un seul clip pour modifier ses propriétés.',
        ),
      ],
    ),
  );
}

class PresentationDocumentInspectorSection extends StatefulWidget {
  const PresentationDocumentInspectorSection({
    super.key,
    required this.asset,
    required this.onCommand,
  });

  final PresentationCinematicAsset asset;
  final ValueChanged<PresentationStudioPropertyCommand> onCommand;

  @override
  State<PresentationDocumentInspectorSection> createState() =>
      _PresentationDocumentInspectorSectionState();
}

class _PresentationDocumentInspectorSectionState
    extends State<PresentationDocumentInspectorSection> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _duration;
  String? _titleError;
  String? _durationError;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.asset.title);
    _description = TextEditingController(text: widget.asset.description ?? '');
    _duration = TextEditingController(
      text: _formatSeconds(widget.asset.durationUs),
    );
  }

  @override
  void didUpdateWidget(
    covariant PresentationDocumentInspectorSection oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.title != widget.asset.title) {
      _title.text = widget.asset.title;
      _titleError = null;
    }
    if (oldWidget.asset.description != widget.asset.description) {
      _description.text = widget.asset.description ?? '';
    }
    if (oldWidget.asset.durationUs != widget.asset.durationUs) {
      _duration.text = _formatSeconds(widget.asset.durationUs);
      _durationError = null;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _duration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PokeMapCinematicInspectorSection(
    title: 'Document',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PokeMapTextField(
          label: 'Titre',
          controller: _title,
          fieldKey: const ValueKey<String>('presentation-property-title'),
          errorText: _titleError,
          onSubmitted: (_) => _commitMetadata(),
        ),
        const SizedBox(height: 10),
        PokeMapTextField(
          label: 'Description',
          controller: _description,
          maxLines: 3,
          textInputAction: TextInputAction.newline,
          onSubmitted: (_) => _commitMetadata(),
        ),
        const SizedBox(height: 10),
        PokeMapTextField(
          label: 'Durée (secondes)',
          controller: _duration,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          errorText: _durationError,
          onSubmitted: (_) => _commitMetadata(),
        ),
        const SizedBox(height: 12),
        const _ReadOnlyProperty(
          title: 'Composition responsive',
          value: 'Document unique · 16:9 et 9:16',
        ),
        const SizedBox(height: 8),
        const _ReadOnlyProperty(
          title: 'Zones sûres',
          value: 'Actives dans les deux orientations',
        ),
        const SizedBox(height: 8),
        const _ReadOnlyProperty(
          title: 'Fond',
          value: 'Transparent jusqu’au premier calque visuel',
        ),
      ],
    ),
  );

  void _commitMetadata() {
    final title = _title.text.trim();
    final seconds = double.tryParse(_duration.text.replaceAll(',', '.'));
    setState(() {
      _titleError = title.isEmpty ? 'Le titre est obligatoire.' : null;
      _durationError = seconds == null || seconds <= 0
          ? 'Saisissez une durée supérieure à zéro.'
          : null;
    });
    if (_titleError != null || _durationError != null) return;
    final updated = PresentationCinematicAsset(
      id: widget.asset.id,
      title: title,
      description: _description.text,
      durationUs: (seconds! * Duration.microsecondsPerSecond).round(),
      layers: widget.asset.layers,
      visualFolders: widget.asset.visualFolders,
      tracks: widget.asset.tracks,
    );
    widget.onCommand(
      PresentationStudioPropertyCommand.updateCinematic(cinematic: updated),
    );
  }
}

class PresentationLayerInspectorSection extends StatefulWidget {
  const PresentationLayerInspectorSection({
    super.key,
    required this.cinematicId,
    required this.layer,
    required this.onCommand,
  });

  final String cinematicId;
  final PresentationLayer layer;
  final ValueChanged<PresentationStudioPropertyCommand> onCommand;

  @override
  State<PresentationLayerInspectorSection> createState() =>
      _PresentationLayerInspectorSectionState();
}

class _PresentationLayerInspectorSectionState
    extends State<PresentationLayerInspectorSection> {
  late final TextEditingController _label;
  late final TextEditingController _zIndex;
  String? _labelError;
  String? _zIndexError;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(text: widget.layer.label);
    _zIndex = TextEditingController(text: '${widget.layer.zIndex}');
  }

  @override
  void didUpdateWidget(covariant PresentationLayerInspectorSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layer.label != widget.layer.label) {
      _label.text = widget.layer.label;
      _labelError = null;
    }
    if (oldWidget.layer.zIndex != widget.layer.zIndex) {
      _zIndex.text = '${widget.layer.zIndex}';
      _zIndexError = null;
    }
  }

  @override
  void dispose() {
    _label.dispose();
    _zIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PokeMapCinematicInspectorSection(
    title: 'Calque visuel',
    child: Column(
      children: <Widget>[
        PokeMapTextField(
          label: 'Nom',
          controller: _label,
          errorText: _labelError,
          onSubmitted: (_) => _commit(),
        ),
        const SizedBox(height: 10),
        PokeMapTextField(
          label: 'Ordre Z',
          controller: _zIndex,
          keyboardType: TextInputType.number,
          errorText: _zIndexError,
          onSubmitted: (_) => _commit(),
        ),
        const SizedBox(height: 10),
        PokeMapToggleTile(
          label: 'Visible',
          value: widget.layer.visible,
          onChanged: (value) => _emit(visible: value),
        ),
        const SizedBox(height: 8),
        PokeMapToggleTile(
          label: 'Verrouillé',
          value: widget.layer.locked,
          onChanged: (value) => _emit(locked: value),
        ),
      ],
    ),
  );

  void _commit() {
    final label = _label.text.trim();
    final zIndex = int.tryParse(_zIndex.text);
    setState(() {
      _labelError = label.isEmpty ? 'Le nom est obligatoire.' : null;
      _zIndexError = zIndex == null ? 'Saisissez un entier.' : null;
    });
    if (_labelError != null || _zIndexError != null) return;
    _emit(label: label, zIndex: zIndex);
  }

  void _emit({String? label, int? zIndex, bool? visible, bool? locked}) {
    widget.onCommand(
      PresentationStudioPropertyCommand.updateLayer(
        cinematicId: widget.cinematicId,
        layer: PresentationLayer(
          id: widget.layer.id,
          label: label ?? widget.layer.label,
          zIndex: zIndex ?? widget.layer.zIndex,
          visible: visible ?? widget.layer.visible,
          locked: locked ?? widget.layer.locked,
        ),
      ),
    );
  }
}

class PresentationVisualInspectorSection extends StatelessWidget {
  const PresentationVisualInspectorSection({
    super.key,
    required this.cinematicId,
    required this.trackId,
    required this.clip,
    required this.orientation,
    required this.onCommand,
  });

  final String cinematicId;
  final String trackId;
  final PresentationVisualClip clip;
  final PresentationFrameOrientation orientation;
  final ValueChanged<PresentationStudioPropertyCommand> onCommand;

  @override
  Widget build(BuildContext context) {
    final override = orientation == PresentationFrameOrientation.landscape
        ? clip.landscapeCompositionOverride
        : clip.portraitCompositionOverride;
    final composition = override ?? clip.to;
    final orientationLabel =
        orientation == PresentationFrameOrientation.landscape
        ? 'Paysage 16:9'
        : 'Portrait 9:16';
    return Column(
      children: <Widget>[
        PokeMapCinematicInspectorSection(
          title: 'Média responsive',
          child: Column(
            children: <Widget>[
              PokeMapDropdownField<PresentationVisualMediaKind>(
                label: 'Type de média',
                value: clip.mediaKind,
                items: const <PokeMapDropdownItem<PresentationVisualMediaKind>>[
                  PokeMapDropdownItem(
                    value: PresentationVisualMediaKind.image,
                    label: 'Image',
                  ),
                  PokeMapDropdownItem(
                    value: PresentationVisualMediaKind.video,
                    label: 'Vidéo',
                  ),
                  PokeMapDropdownItem(
                    value: PresentationVisualMediaKind.poster,
                    label: 'Poster',
                  ),
                ],
                onChanged: (value) =>
                    _emit(_copyVisual(clip, mediaKind: value)),
              ),
              const SizedBox(height: 10),
              _ReadOnlyProperty(
                title: 'Source partagée',
                value: clip.resourceId,
              ),
              const SizedBox(height: 8),
              _OptionalResourceControl(
                label: 'Source paysage',
                resourceId: clip.landscapeResourceId,
                fallbackLabel: 'Utilise la source partagée',
                onReset: clip.landscapeResourceId == null
                    ? null
                    : () => _emit(_copyVisual(clip, landscapeResourceId: null)),
              ),
              const SizedBox(height: 8),
              _OptionalResourceControl(
                label: 'Source portrait',
                resourceId: clip.portraitResourceId,
                fallbackLabel: 'Utilise la source partagée',
                onReset: clip.portraitResourceId == null
                    ? null
                    : () => _emit(_copyVisual(clip, portraitResourceId: null)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PokeMapCinematicInspectorSection(
          title: 'Composition · $orientationLabel',
          child: Column(
            children: <Widget>[
              if (override == null)
                const PokeMapBadge(
                  label: 'Valeurs partagées',
                  variant: PokeMapBadgeVariant.neutral,
                )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: PokeMapButton(
                    key: const ValueKey<String>(
                      'presentation-property-reset-composition',
                    ),
                    size: PokeMapButtonSize.small,
                    variant: PokeMapButtonVariant.ghost,
                    onPressed: () => _emit(
                      orientation == PresentationFrameOrientation.landscape
                          ? _copyVisual(
                              clip,
                              landscapeCompositionOverride: null,
                            )
                          : _copyVisual(
                              clip,
                              portraitCompositionOverride: null,
                            ),
                    ),
                    child: const Text('Revenir au partagé'),
                  ),
                ),
              const SizedBox(height: 8),
              _CompositionFields(
                composition: composition,
                onChanged: (value) => _emit(
                  orientation == PresentationFrameOrientation.landscape
                      ? _copyVisual(clip, landscapeCompositionOverride: value)
                      : _copyVisual(clip, portraitCompositionOverride: value),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _emit(PresentationVisualClip value) => onCommand(
    PresentationStudioPropertyCommand.updateClip(
      cinematicId: cinematicId,
      trackId: trackId,
      clip: value,
    ),
  );
}

class PresentationTextInspectorSection extends StatefulWidget {
  const PresentationTextInspectorSection({
    super.key,
    required this.cinematicId,
    required this.trackId,
    required this.clip,
    required this.onCommand,
  });

  final String cinematicId;
  final String trackId;
  final PresentationTextClip clip;
  final ValueChanged<PresentationStudioPropertyCommand> onCommand;

  @override
  State<PresentationTextInspectorSection> createState() =>
      _PresentationTextInspectorSectionState();
}

class _PresentationTextInspectorSectionState
    extends State<PresentationTextInspectorSection> {
  late final TextEditingController _text;
  late final TextEditingController _localizationKey;
  late final TextEditingController _fontSize;
  late final TextEditingController _fontFamily;
  late final TextEditingController _colorHex;
  String? _textError;
  String? _fontSizeError;
  String? _colorHexError;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.clip.text);
    _localizationKey = TextEditingController(
      text: widget.clip.localizationKey ?? '',
    );
    _fontSize = TextEditingController(text: '${widget.clip.style.fontSize}');
    _fontFamily = TextEditingController(
      text: widget.clip.style.fontFamily ?? '',
    );
    _colorHex = TextEditingController(text: widget.clip.style.colorHex);
  }

  @override
  void didUpdateWidget(covariant PresentationTextInspectorSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clip.text != widget.clip.text) {
      _text.text = widget.clip.text;
      _textError = null;
    }
    if (oldWidget.clip.localizationKey != widget.clip.localizationKey) {
      _localizationKey.text = widget.clip.localizationKey ?? '';
    }
    if (oldWidget.clip.style.fontSize != widget.clip.style.fontSize) {
      _fontSize.text = '${widget.clip.style.fontSize}';
      _fontSizeError = null;
    }
    if (oldWidget.clip.style.fontFamily != widget.clip.style.fontFamily) {
      _fontFamily.text = widget.clip.style.fontFamily ?? '';
    }
    if (oldWidget.clip.style.colorHex != widget.clip.style.colorHex) {
      _colorHex.text = widget.clip.style.colorHex;
      _colorHexError = null;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _localizationKey.dispose();
    _fontSize.dispose();
    _fontFamily.dispose();
    _colorHex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PokeMapCinematicInspectorSection(
    title: 'Texte',
    child: Column(
      children: <Widget>[
        PokeMapTextField(
          label: 'Contenu',
          controller: _text,
          fieldKey: const ValueKey<String>('presentation-property-text'),
          maxLines: 4,
          errorText: _textError,
          onSubmitted: (_) => _commit(),
        ),
        const SizedBox(height: 10),
        PokeMapTextField(
          label: 'Clé de localisation',
          controller: _localizationKey,
          onSubmitted: (_) => _commit(),
        ),
        const SizedBox(height: 10),
        PokeMapTextField(
          label: 'Taille',
          controller: _fontSize,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: _fontSizeError,
          onSubmitted: (_) => _commit(),
        ),
        const SizedBox(height: 10),
        PokeMapTextField(
          label: 'Police',
          controller: _fontFamily,
          onSubmitted: (_) => _commit(),
        ),
        const SizedBox(height: 10),
        PokeMapTextField(
          label: 'Couleur',
          controller: _colorHex,
          fieldKey: const ValueKey<String>('presentation-property-text-color'),
          errorText: _colorHexError,
          onSubmitted: (_) => _commit(),
        ),
        const SizedBox(height: 10),
        PokeMapDropdownField<PresentationTextWeight>(
          label: 'Graisse',
          value: widget.clip.style.weight,
          items: const <PokeMapDropdownItem<PresentationTextWeight>>[
            PokeMapDropdownItem(
              value: PresentationTextWeight.regular,
              label: 'Normale',
            ),
            PokeMapDropdownItem(
              value: PresentationTextWeight.medium,
              label: 'Moyenne',
            ),
            PokeMapDropdownItem(
              value: PresentationTextWeight.bold,
              label: 'Grasse',
            ),
          ],
          onChanged: (value) =>
              _emit(_copyTextStyle(widget.clip.style, weight: value)),
        ),
        const SizedBox(height: 10),
        PokeMapDropdownField<PresentationTextAlignment>(
          label: 'Alignement',
          value: widget.clip.style.alignment,
          items: <PokeMapDropdownItem<PresentationTextAlignment>>[
            for (final value in PresentationTextAlignment.values)
              PokeMapDropdownItem<PresentationTextAlignment>(
                value: value,
                label: switch (value) {
                  PresentationTextAlignment.start => 'Début',
                  PresentationTextAlignment.center => 'Centré',
                  PresentationTextAlignment.end => 'Fin',
                },
              ),
          ],
          onChanged: (value) =>
              _emit(_copyTextStyle(widget.clip.style, alignment: value)),
        ),
        const SizedBox(height: 10),
        PokeMapDropdownField<PresentationTextWrapping>(
          label: 'Retour à la ligne',
          value: widget.clip.style.wrapping,
          items: const <PokeMapDropdownItem<PresentationTextWrapping>>[
            PokeMapDropdownItem<PresentationTextWrapping>(
              value: PresentationTextWrapping.wrap,
              label: 'Automatique',
            ),
            PokeMapDropdownItem<PresentationTextWrapping>(
              value: PresentationTextWrapping.noWrap,
              label: 'Une ligne',
            ),
          ],
          onChanged: (value) =>
              _emit(_copyTextStyle(widget.clip.style, wrapping: value)),
        ),
        const SizedBox(height: 10),
        PokeMapToggleTile(
          label: 'Respecter les zones sûres',
          value: widget.clip.style.respectSafeArea,
          onChanged: (value) =>
              _emit(_copyTextStyle(widget.clip.style, respectSafeArea: value)),
        ),
      ],
    ),
  );

  void _commit() {
    final text = _text.text.trim();
    final fontSize = double.tryParse(_fontSize.text.replaceAll(',', '.'));
    final colorHex = _colorHex.text.trim();
    setState(() {
      _textError = text.isEmpty ? 'Le texte est obligatoire.' : null;
      _fontSizeError = fontSize == null || fontSize <= 0
          ? 'Saisissez une taille supérieure à zéro.'
          : null;
      _colorHexError =
          RegExp(r'^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$').hasMatch(colorHex)
          ? null
          : 'Utilisez #RRGGBB ou #RRGGBBAA.';
    });
    if (_textError != null ||
        _fontSizeError != null ||
        _colorHexError != null) {
      return;
    }
    _emit(
      _copyTextStyle(
        widget.clip.style,
        fontSize: fontSize,
        fontFamily: _fontFamily.text,
        colorHex: colorHex,
      ),
      text: text,
      localizationKey: _localizationKey.text,
    );
  }

  void _emit(
    PresentationTextStyle style, {
    String? text,
    String? localizationKey,
  }) {
    widget.onCommand(
      PresentationStudioPropertyCommand.updateClip(
        cinematicId: widget.cinematicId,
        trackId: widget.trackId,
        clip: _copyText(
          widget.clip,
          text: text,
          localizationKey: localizationKey,
          style: style,
        ),
      ),
    );
  }
}

class PresentationAudioInspectorSection extends StatelessWidget {
  const PresentationAudioInspectorSection({
    super.key,
    required this.cinematicId,
    required this.trackId,
    required this.clip,
    required this.onCommand,
  });

  final String cinematicId;
  final String trackId;
  final PresentationAudioClip clip;
  final ValueChanged<PresentationStudioPropertyCommand> onCommand;

  @override
  Widget build(BuildContext context) => PokeMapCinematicInspectorSection(
    title: 'Audio',
    child: Column(
      children: <Widget>[
        PokeMapDropdownField<PresentationAudioKind>(
          label: 'Type',
          value: clip.audioKind,
          items: const <PokeMapDropdownItem<PresentationAudioKind>>[
            PokeMapDropdownItem(
              value: PresentationAudioKind.music,
              label: 'Musique',
            ),
            PokeMapDropdownItem(
              value: PresentationAudioKind.voice,
              label: 'Voix',
            ),
            PokeMapDropdownItem(
              value: PresentationAudioKind.soundEffect,
              label: 'Effet sonore',
            ),
          ],
          onChanged: (value) => _emit(
            _copyAudio(
              clip,
              audioKind: value,
              landscapeResourceId: value == PresentationAudioKind.music
                  ? null
                  : clip.landscapeResourceId,
              portraitResourceId: value == PresentationAudioKind.music
                  ? null
                  : clip.portraitResourceId,
              bus: switch (value) {
                PresentationAudioKind.music => PresentationAudioBus.music,
                PresentationAudioKind.voice => PresentationAudioBus.voice,
                PresentationAudioKind.soundEffect =>
                  PresentationAudioBus.effects,
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        _ReadOnlyProperty(title: 'Source partagée', value: clip.resourceId),
        if (clip.audioKind != PresentationAudioKind.music) ...<Widget>[
          const SizedBox(height: 8),
          _OptionalResourceControl(
            label: 'Source paysage',
            resourceId: clip.landscapeResourceId,
            fallbackLabel: 'Utilise la source partagée',
            onReset: clip.landscapeResourceId == null
                ? null
                : () => _emit(_copyAudio(clip, landscapeResourceId: null)),
          ),
          const SizedBox(height: 8),
          _OptionalResourceControl(
            label: 'Source portrait',
            resourceId: clip.portraitResourceId,
            fallbackLabel: 'Utilise la source partagée',
            onReset: clip.portraitResourceId == null
                ? null
                : () => _emit(_copyAudio(clip, portraitResourceId: null)),
          ),
        ],
        const SizedBox(height: 10),
        PokeMapGuidedSlider(
          label: 'Volume',
          value: (clip.volume * 100).round(),
          min: 0,
          max: 100,
          onChanged: (value) => _emit(_copyAudio(clip, volume: value / 100)),
        ),
        const SizedBox(height: 10),
        PokeMapToggleTile(
          label: 'Boucle',
          value: clip.loop,
          onChanged: (value) => _emit(_copyAudio(clip, loop: value)),
        ),
        const SizedBox(height: 10),
        _NumberPropertyField(
          label: 'Fondu d’entrée (secondes)',
          value: clip.fadeInUs / Duration.microsecondsPerSecond,
          fieldKey: const ValueKey<String>('presentation-property-fade-in'),
          minimumInclusive: 0,
          maximumInclusive: clip.durationUs / Duration.microsecondsPerSecond,
          onChanged: (value) => _emit(
            _copyAudio(
              clip,
              fadeInUs: (value * Duration.microsecondsPerSecond).round(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _NumberPropertyField(
          label: 'Fondu de sortie (secondes)',
          value: clip.fadeOutUs / Duration.microsecondsPerSecond,
          fieldKey: const ValueKey<String>('presentation-property-fade-out'),
          minimumInclusive: 0,
          maximumInclusive: clip.durationUs / Duration.microsecondsPerSecond,
          onChanged: (value) => _emit(
            _copyAudio(
              clip,
              fadeOutUs: (value * Duration.microsecondsPerSecond).round(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        PokeMapDropdownField<PresentationAudioBus>(
          label: 'Bus',
          value: clip.bus,
          items: <PokeMapDropdownItem<PresentationAudioBus>>[
            for (final value in PresentationAudioBus.values)
              PokeMapDropdownItem(value: value, label: _audioBusLabel(value)),
          ],
          onChanged: (value) => _emit(_copyAudio(clip, bus: value)),
        ),
      ],
    ),
  );

  void _emit(PresentationAudioClip value) => onCommand(
    PresentationStudioPropertyCommand.updateClip(
      cinematicId: cinematicId,
      trackId: trackId,
      clip: value,
    ),
  );
}

class PresentationCaptionInspectorSection extends StatefulWidget {
  const PresentationCaptionInspectorSection({
    super.key,
    required this.cinematicId,
    required this.cinematicDurationUs,
    required this.trackId,
    required this.clip,
    required this.onCommand,
  });

  final String cinematicId;
  final int cinematicDurationUs;
  final String trackId;
  final PresentationCaptionClip clip;
  final ValueChanged<PresentationStudioPropertyCommand> onCommand;

  @override
  State<PresentationCaptionInspectorSection> createState() =>
      _PresentationCaptionInspectorSectionState();
}

class _PresentationCaptionInspectorSectionState
    extends State<PresentationCaptionInspectorSection> {
  late final TextEditingController _locale;
  late final TextEditingController _start;
  late final TextEditingController _duration;
  String? _localeError;
  String? _timingError;

  @override
  void initState() {
    super.initState();
    _locale = TextEditingController(text: widget.clip.locale);
    _start = TextEditingController(text: _formatSeconds(widget.clip.startUs));
    _duration = TextEditingController(
      text: _formatSeconds(widget.clip.durationUs),
    );
  }

  @override
  void didUpdateWidget(
    covariant PresentationCaptionInspectorSection oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clip.locale != widget.clip.locale) {
      _locale.text = widget.clip.locale;
      _localeError = null;
    }
    if (oldWidget.clip.startUs != widget.clip.startUs) {
      _start.text = _formatSeconds(widget.clip.startUs);
      _timingError = null;
    }
    if (oldWidget.clip.durationUs != widget.clip.durationUs) {
      _duration.text = _formatSeconds(widget.clip.durationUs);
      _timingError = null;
    }
  }

  @override
  void dispose() {
    _locale.dispose();
    _start.dispose();
    _duration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PokeMapCinematicInspectorSection(
    title: 'Sous-titres',
    child: Column(
      children: <Widget>[
        _ReadOnlyProperty(title: 'Ressource', value: clip.captionId),
        const SizedBox(height: 8),
        PokeMapTextField(
          label: 'Locale',
          controller: _locale,
          fieldKey: const ValueKey<String>(
            'presentation-property-caption-locale',
          ),
          errorText: _localeError,
          onSubmitted: (_) => _commitTiming(),
        ),
        const SizedBox(height: 8),
        PokeMapTextField(
          label: 'Début (secondes)',
          controller: _start,
          fieldKey: const ValueKey<String>(
            'presentation-property-caption-start',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: _timingError,
          onSubmitted: (_) => _commitTiming(),
        ),
        const SizedBox(height: 8),
        PokeMapTextField(
          label: 'Durée (secondes)',
          controller: _duration,
          fieldKey: const ValueKey<String>(
            'presentation-property-caption-duration',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: _timingError,
          onSubmitted: (_) => _commitTiming(),
        ),
        const SizedBox(height: 10),
        PokeMapDropdownField<PresentationCaptionStyle>(
          label: 'Style accessible',
          value: widget.clip.style,
          items: const <PokeMapDropdownItem<PresentationCaptionStyle>>[
            PokeMapDropdownItem(
              value: PresentationCaptionStyle.standard,
              label: 'Standard',
            ),
            PokeMapDropdownItem(
              value: PresentationCaptionStyle.highContrast,
              label: 'Contraste renforcé',
            ),
          ],
          onChanged: (value) => _emit(_copyCaption(widget.clip, style: value)),
        ),
        const SizedBox(height: 10),
        PokeMapToggleTile(
          label: 'Fallback locale projet',
          value: widget.clip.fallbackToProjectDefault,
          onChanged: (value) =>
              _emit(_copyCaption(widget.clip, fallbackToProjectDefault: value)),
        ),
      ],
    ),
  );

  PresentationCaptionClip get clip => widget.clip;

  void _commitTiming() {
    final locale = _locale.text.trim();
    final startSeconds = double.tryParse(_start.text.replaceAll(',', '.'));
    final durationSeconds = double.tryParse(
      _duration.text.replaceAll(',', '.'),
    );
    final validStart = startSeconds != null && startSeconds >= 0;
    final validDuration = durationSeconds != null && durationSeconds > 0;
    final startUs = startSeconds != null && startSeconds >= 0
        ? (startSeconds * Duration.microsecondsPerSecond).round()
        : null;
    final durationUs = durationSeconds != null && durationSeconds > 0
        ? (durationSeconds * Duration.microsecondsPerSecond).round()
        : null;
    final fitsDocument =
        startUs != null &&
        durationUs != null &&
        startUs + durationUs <= widget.cinematicDurationUs;
    setState(() {
      _localeError = locale.isEmpty ? 'La locale est obligatoire.' : null;
      _timingError = validStart && validDuration && fitsDocument
          ? null
          : 'Le timing doit être positif et rester dans le document.';
    });
    if (_localeError != null || _timingError != null) return;
    _emit(
      _copyCaption(
        widget.clip,
        locale: locale,
        startUs: startUs,
        durationUs: durationUs,
      ),
    );
  }

  void _emit(PresentationCaptionClip value) => widget.onCommand(
    PresentationStudioPropertyCommand.updateClip(
      cinematicId: widget.cinematicId,
      trackId: widget.trackId,
      clip: value,
    ),
  );
}

class PresentationMarkerInspectorSection extends StatelessWidget {
  const PresentationMarkerInspectorSection({
    super.key,
    required this.cinematicId,
    required this.trackId,
    required this.clip,
    required this.sceneUsageCount,
    required this.onCommand,
  });

  final String cinematicId;
  final String trackId;
  final PresentationMarkerClip clip;
  final int sceneUsageCount;
  final ValueChanged<PresentationStudioPropertyCommand> onCommand;

  @override
  Widget build(BuildContext context) => PokeMapCinematicInspectorSection(
    title: 'Repère et interaction',
    child: Column(
      children: <Widget>[
        _ReadOnlyProperty(title: 'Identité stable', value: clip.id),
        const SizedBox(height: 8),
        _MarkerNameField(
          value: clip.label,
          onChanged: (value) => _emit(_copyMarker(clip, label: value)),
        ),
        const SizedBox(height: 8),
        _ReadOnlyProperty(
          title: 'Usages',
          value:
              '$sceneUsageCount ${sceneUsageCount == 1 ? 'usage' : 'usages'} dans Scene',
        ),
        const SizedBox(height: 10),
        PokeMapDropdownField<PresentationMarkerKind>(
          label: 'Type',
          value: clip.markerKind,
          items: const <PokeMapDropdownItem<PresentationMarkerKind>>[
            PokeMapDropdownItem(
              value: PresentationMarkerKind.ordinary,
              label: 'Repère ordinaire',
            ),
            PokeMapDropdownItem(
              value: PresentationMarkerKind.interactionCue,
              label: 'Point d’interaction Scene',
            ),
          ],
          onChanged: (value) => _emit(_copyMarker(clip, markerKind: value)),
        ),
        const SizedBox(height: 10),
        PokeMapToggleTile(
          label: 'Requis',
          description:
              'La validation bloque si ce cue n’est relié à aucune Scene.',
          value: clip.required,
          onChanged: (value) => _emit(_copyMarker(clip, required: value)),
        ),
      ],
    ),
  );

  void _emit(PresentationMarkerClip value) => onCommand(
    PresentationStudioPropertyCommand.updateClip(
      cinematicId: cinematicId,
      trackId: trackId,
      clip: value,
    ),
  );
}

class _MarkerNameField extends StatefulWidget {
  const _MarkerNameField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_MarkerNameField> createState() => _MarkerNameFieldState();
}

class _MarkerNameFieldState extends State<_MarkerNameField> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _MarkerNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value;
      _error = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PokeMapTextField(
    label: 'Nom',
    controller: _controller,
    fieldKey: const ValueKey<String>('presentation-property-marker-name'),
    errorText: _error,
    onSubmitted: (_) {
      final value = _controller.text.trim();
      setState(() => _error = value.isEmpty ? 'Le nom est obligatoire.' : null);
      if (_error == null) widget.onChanged(value);
    },
  );
}

class PresentationTransitionInspectorSection extends StatelessWidget {
  const PresentationTransitionInspectorSection({
    super.key,
    required this.cinematicId,
    required this.trackId,
    required this.clip,
    required this.onCommand,
  });

  final String cinematicId;
  final String trackId;
  final PresentationClip clip;
  final ValueChanged<PresentationStudioPropertyCommand> onCommand;

  @override
  Widget build(BuildContext context) {
    final easing = switch (clip) {
      final PresentationVisualClip visual => visual.easing,
      final PresentationTextClip text => text.easing,
      _ => throw StateError('Transitions require a visual or text clip.'),
    };
    final transitionIn = switch (clip) {
      final PresentationVisualClip visual => visual.transitionIn,
      final PresentationTextClip text => text.transitionIn,
      _ => PresentationVisualTransition.none,
    };
    final transitionOut = switch (clip) {
      final PresentationVisualClip visual => visual.transitionOut,
      final PresentationTextClip text => text.transitionOut,
      _ => PresentationVisualTransition.none,
    };
    return PokeMapCinematicInspectorSection(
      title: 'Transitions et animation',
      child: Column(
        children: <Widget>[
          PokeMapDropdownField<PresentationEasing>(
            label: 'Courbe',
            value: easing,
            items: <PokeMapDropdownItem<PresentationEasing>>[
              for (final value in PresentationEasing.values)
                PokeMapDropdownItem<PresentationEasing>(
                  value: value,
                  label: value.name,
                ),
            ],
            onChanged: (value) =>
                _emit(_copyTransitionClip(clip, easing: value)),
          ),
          const SizedBox(height: 10),
          PokeMapDropdownField<PresentationVisualTransitionKind>(
            label: 'Transition d’entrée',
            value: transitionIn.kind,
            items: _transitionItems(),
            onChanged: (value) => _emit(
              _copyTransitionClip(
                clip,
                transitionIn: _transitionForKind(value, transitionIn),
              ),
            ),
          ),
          if (transitionIn.kind != PresentationVisualTransitionKind.none) ...[
            const SizedBox(height: 8),
            _NumberPropertyField(
              label: 'Durée d’entrée (secondes)',
              value: transitionIn.durationUs / Duration.microsecondsPerSecond,
              fieldKey: const ValueKey<String>(
                'presentation-property-transition-in-duration',
              ),
              minimumExclusive: 0,
              maximumInclusive:
                  clip.durationUs / Duration.microsecondsPerSecond,
              onChanged: (value) => _emit(
                _copyTransitionClip(
                  clip,
                  transitionIn: PresentationVisualTransition(
                    kind: transitionIn.kind,
                    durationUs: (value * Duration.microsecondsPerSecond)
                        .round(),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          PokeMapDropdownField<PresentationVisualTransitionKind>(
            label: 'Transition de sortie',
            value: transitionOut.kind,
            items: _transitionItems(),
            onChanged: (value) => _emit(
              _copyTransitionClip(
                clip,
                transitionOut: _transitionForKind(value, transitionOut),
              ),
            ),
          ),
          if (transitionOut.kind != PresentationVisualTransitionKind.none) ...[
            const SizedBox(height: 8),
            _NumberPropertyField(
              label: 'Durée de sortie (secondes)',
              value: transitionOut.durationUs / Duration.microsecondsPerSecond,
              fieldKey: const ValueKey<String>(
                'presentation-property-transition-out-duration',
              ),
              minimumExclusive: 0,
              maximumInclusive:
                  clip.durationUs / Duration.microsecondsPerSecond,
              onChanged: (value) => _emit(
                _copyTransitionClip(
                  clip,
                  transitionOut: PresentationVisualTransition(
                    kind: transitionOut.kind,
                    durationUs: (value * Duration.microsecondsPerSecond)
                        .round(),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          const _ReadOnlyProperty(
            title: 'Reduced motion',
            value: 'Aperçu final sans translation ni rotation animée',
          ),
        ],
      ),
    );
  }

  void _emit(PresentationClip value) => onCommand(
    PresentationStudioPropertyCommand.updateClip(
      cinematicId: cinematicId,
      trackId: trackId,
      clip: value,
    ),
  );

  List<PokeMapDropdownItem<PresentationVisualTransitionKind>>
  _transitionItems() => <PokeMapDropdownItem<PresentationVisualTransitionKind>>[
    for (final value in PresentationVisualTransitionKind.values)
      PokeMapDropdownItem(value: value, label: _transitionLabel(value)),
  ];

  PresentationVisualTransition _transitionForKind(
    PresentationVisualTransitionKind kind,
    PresentationVisualTransition current,
  ) {
    if (kind == PresentationVisualTransitionKind.none) {
      return PresentationVisualTransition.none;
    }
    return PresentationVisualTransition(
      kind: kind,
      durationUs: current.durationUs > 0
          ? current.durationUs
          : clip.durationUs.clamp(1, 300000).toInt(),
    );
  }
}

class _CompositionFields extends StatelessWidget {
  const _CompositionFields({
    required this.composition,
    required this.onChanged,
  });

  final PresentationVisualComposition composition;
  final ValueChanged<PresentationVisualComposition> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      _NumberPropertyField(
        label: 'Position X',
        value: composition.translateX,
        onChanged: (value) =>
            onChanged(_copyComposition(composition, translateX: value)),
      ),
      const SizedBox(height: 8),
      _NumberPropertyField(
        label: 'Position Y',
        value: composition.translateY,
        onChanged: (value) =>
            onChanged(_copyComposition(composition, translateY: value)),
      ),
      const SizedBox(height: 8),
      _NumberPropertyField(
        label: 'Échelle',
        value: composition.scaleX,
        minimumExclusive: 0,
        onChanged: (value) => onChanged(
          _copyComposition(composition, scaleX: value, scaleY: value),
        ),
      ),
      const SizedBox(height: 8),
      _NumberPropertyField(
        label: 'Rotation (tours)',
        value: composition.rotationTurns,
        onChanged: (value) =>
            onChanged(_copyComposition(composition, rotationTurns: value)),
      ),
      const SizedBox(height: 8),
      PokeMapGuidedSlider(
        label: 'Opacité',
        value: (composition.opacity * 100).round(),
        min: 0,
        max: 100,
        onChanged: (value) =>
            onChanged(_copyComposition(composition, opacity: value / 100)),
      ),
      const SizedBox(height: 8),
      _NumberPropertyField(
        label: 'Recadrage gauche',
        value: composition.cropLeft,
        minimumInclusive: 0,
        maximumExclusive: 1 - composition.cropRight,
        onChanged: (value) =>
            onChanged(_copyComposition(composition, cropLeft: value)),
      ),
      const SizedBox(height: 8),
      _NumberPropertyField(
        label: 'Recadrage haut',
        value: composition.cropTop,
        minimumInclusive: 0,
        maximumExclusive: 1 - composition.cropBottom,
        onChanged: (value) =>
            onChanged(_copyComposition(composition, cropTop: value)),
      ),
      const SizedBox(height: 8),
      _NumberPropertyField(
        label: 'Recadrage droit',
        value: composition.cropRight,
        minimumInclusive: 0,
        maximumExclusive: 1 - composition.cropLeft,
        onChanged: (value) =>
            onChanged(_copyComposition(composition, cropRight: value)),
      ),
      const SizedBox(height: 8),
      _NumberPropertyField(
        label: 'Recadrage bas',
        value: composition.cropBottom,
        minimumInclusive: 0,
        maximumExclusive: 1 - composition.cropTop,
        onChanged: (value) =>
            onChanged(_copyComposition(composition, cropBottom: value)),
      ),
    ],
  );
}

class _NumberPropertyField extends StatefulWidget {
  const _NumberPropertyField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.fieldKey,
    this.minimumExclusive,
    this.minimumInclusive,
    this.maximumExclusive,
    this.maximumInclusive,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final Key? fieldKey;
  final double? minimumExclusive;
  final double? minimumInclusive;
  final double? maximumExclusive;
  final double? maximumInclusive;

  @override
  State<_NumberPropertyField> createState() => _NumberPropertyFieldState();
}

class _NumberPropertyFieldState extends State<_NumberPropertyField> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
  }

  @override
  void didUpdateWidget(covariant _NumberPropertyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = '${widget.value}';
      _error = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PokeMapTextField(
    label: widget.label,
    controller: _controller,
    fieldKey: widget.fieldKey,
    keyboardType: const TextInputType.numberWithOptions(
      signed: true,
      decimal: true,
    ),
    errorText: _error,
    onSubmitted: (_) {
      final value = double.tryParse(_controller.text.replaceAll(',', '.'));
      final invalid =
          value == null ||
          !value.isFinite ||
          (widget.minimumExclusive != null &&
              value <= widget.minimumExclusive!) ||
          (widget.minimumInclusive != null &&
              value < widget.minimumInclusive!) ||
          (widget.maximumExclusive != null &&
              value >= widget.maximumExclusive!) ||
          (widget.maximumInclusive != null && value > widget.maximumInclusive!);
      setState(() {
        _error = invalid ? 'Valeur numérique invalide.' : null;
      });
      if (!invalid) widget.onChanged(value);
    },
  );
}

class _ReadOnlyProperty extends StatelessWidget {
  const _ReadOnlyProperty({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$title: $value',
    readOnly: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(title, style: const TextStyle(fontSize: 10)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _OptionalResourceControl extends StatelessWidget {
  const _OptionalResourceControl({
    required this.label,
    required this.resourceId,
    required this.fallbackLabel,
    required this.onReset,
  });

  final String label;
  final String? resourceId;
  final String fallbackLabel;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: _ReadOnlyProperty(
          title: label,
          value: resourceId ?? fallbackLabel,
        ),
      ),
      const SizedBox(width: 6),
      PokeMapIconButton(
        onPressed: onReset,
        tooltip: 'Revenir à la source partagée',
        semanticLabel: 'Revenir à la source partagée pour $label',
        icon: const Icon(Icons.restart_alt_rounded),
      ),
    ],
  );
}

class _InspectorToolbar extends StatelessWidget {
  const _InspectorToolbar({
    required this.mutationPending,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
  });

  final bool mutationPending;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;

  @override
  Widget build(BuildContext context) => PokeMapToolbarSurface(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    child: Row(
      children: <Widget>[
        const Expanded(
          child: Text(
            'Propriétés',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        if (mutationPending)
          const PokeMapBadge(
            label: 'Enregistrement…',
            variant: PokeMapBadgeVariant.info,
          ),
        PokeMapIconButton(
          onPressed: canUndo ? onUndo : null,
          tooltip: 'Annuler la propriété',
          icon: const Icon(Icons.undo_rounded),
        ),
        PokeMapIconButton(
          onPressed: canRedo ? onRedo : null,
          tooltip: 'Rétablir la propriété',
          icon: const Icon(Icons.redo_rounded),
        ),
      ],
    ),
  );
}

_LocatedClip? _locateClip(PresentationCinematicAsset asset, String clipId) {
  for (final track in asset.tracks) {
    for (final clip in track.clips) {
      if (clip.id == clipId) return _LocatedClip(track: track, clip: clip);
    }
  }
  return null;
}

PresentationLayer? _findLayer(PresentationCinematicAsset asset, String id) {
  for (final layer in asset.layers) {
    if (layer.id == id) return layer;
  }
  return null;
}

final class _LocatedClip {
  const _LocatedClip({required this.track, required this.clip});

  final PresentationTrack track;
  final PresentationClip clip;
}

PresentationVisualClip _copyVisual(
  PresentationVisualClip clip, {
  Object? landscapeResourceId = _unsetProperty,
  Object? portraitResourceId = _unsetProperty,
  Object? landscapeCompositionOverride = _unsetProperty,
  Object? portraitCompositionOverride = _unsetProperty,
  PresentationEasing? easing,
  PresentationVisualMediaKind? mediaKind,
  PresentationVisualTransition? transitionIn,
  PresentationVisualTransition? transitionOut,
}) => PresentationVisualClip(
  id: clip.id,
  startUs: clip.startUs,
  durationUs: clip.durationUs,
  layerId: clip.layerId,
  resourceId: clip.resourceId,
  mediaKind: mediaKind ?? clip.mediaKind,
  landscapeResourceId: identical(landscapeResourceId, _unsetProperty)
      ? clip.landscapeResourceId
      : landscapeResourceId as String?,
  portraitResourceId: identical(portraitResourceId, _unsetProperty)
      ? clip.portraitResourceId
      : portraitResourceId as String?,
  landscapeCompositionOverride:
      identical(landscapeCompositionOverride, _unsetProperty)
      ? clip.landscapeCompositionOverride
      : landscapeCompositionOverride as PresentationVisualComposition?,
  portraitCompositionOverride:
      identical(portraitCompositionOverride, _unsetProperty)
      ? clip.portraitCompositionOverride
      : portraitCompositionOverride as PresentationVisualComposition?,
  easing: easing ?? clip.easing,
  from: clip.from,
  to: clip.to,
  transitionIn: transitionIn ?? clip.transitionIn,
  transitionOut: transitionOut ?? clip.transitionOut,
);

PresentationTextClip _copyText(
  PresentationTextClip clip, {
  String? text,
  Object? localizationKey = _unsetProperty,
  PresentationTextStyle? style,
  PresentationEasing? easing,
  PresentationVisualTransition? transitionIn,
  PresentationVisualTransition? transitionOut,
}) => PresentationTextClip(
  id: clip.id,
  startUs: clip.startUs,
  durationUs: clip.durationUs,
  layerId: clip.layerId,
  text: text ?? clip.text,
  localizationKey: identical(localizationKey, _unsetProperty)
      ? clip.localizationKey
      : localizationKey as String?,
  style: style ?? clip.style,
  easing: easing ?? clip.easing,
  from: clip.from,
  to: clip.to,
  transitionIn: transitionIn ?? clip.transitionIn,
  transitionOut: transitionOut ?? clip.transitionOut,
);

PresentationAudioClip _copyAudio(
  PresentationAudioClip clip, {
  PresentationAudioKind? audioKind,
  Object? landscapeResourceId = _unsetProperty,
  Object? portraitResourceId = _unsetProperty,
  double? volume,
  bool? loop,
  int? fadeInUs,
  int? fadeOutUs,
  PresentationAudioBus? bus,
}) => PresentationAudioClip(
  id: clip.id,
  startUs: clip.startUs,
  durationUs: clip.durationUs,
  resourceId: clip.resourceId,
  audioKind: audioKind ?? clip.audioKind,
  landscapeResourceId: identical(landscapeResourceId, _unsetProperty)
      ? clip.landscapeResourceId
      : landscapeResourceId as String?,
  portraitResourceId: identical(portraitResourceId, _unsetProperty)
      ? clip.portraitResourceId
      : portraitResourceId as String?,
  volume: volume ?? clip.volume,
  loop: loop ?? clip.loop,
  fadeInUs: fadeInUs ?? clip.fadeInUs,
  fadeOutUs: fadeOutUs ?? clip.fadeOutUs,
  bus: bus ?? clip.bus,
);

PresentationCaptionClip _copyCaption(
  PresentationCaptionClip clip, {
  int? startUs,
  int? durationUs,
  String? locale,
  PresentationCaptionStyle? style,
  bool? fallbackToProjectDefault,
}) => PresentationCaptionClip(
  id: clip.id,
  startUs: startUs ?? clip.startUs,
  durationUs: durationUs ?? clip.durationUs,
  captionId: clip.captionId,
  locale: locale ?? clip.locale,
  style: style ?? clip.style,
  fallbackToProjectDefault:
      fallbackToProjectDefault ?? clip.fallbackToProjectDefault,
);

PresentationMarkerClip _copyMarker(
  PresentationMarkerClip clip, {
  String? label,
  PresentationMarkerKind? markerKind,
  bool? required,
}) => PresentationMarkerClip(
  id: clip.id,
  startUs: clip.startUs,
  label: label ?? clip.label,
  markerKind: markerKind ?? clip.markerKind,
  required: required ?? clip.required,
);

PresentationClip _copyTransitionClip(
  PresentationClip clip, {
  PresentationEasing? easing,
  PresentationVisualTransition? transitionIn,
  PresentationVisualTransition? transitionOut,
}) => switch (clip) {
  PresentationVisualClip() => _copyVisual(
    clip,
    easing: easing,
    transitionIn: transitionIn,
    transitionOut: transitionOut,
  ),
  PresentationTextClip() => _copyText(
    clip,
    easing: easing,
    transitionIn: transitionIn,
    transitionOut: transitionOut,
  ),
  _ => throw ArgumentError.value(clip, 'clip', 'must support transitions'),
};

PresentationTextStyle _copyTextStyle(
  PresentationTextStyle style, {
  String? fontFamily,
  double? fontSize,
  PresentationTextWeight? weight,
  PresentationTextAlignment? alignment,
  PresentationTextWrapping? wrapping,
  String? colorHex,
  bool? respectSafeArea,
}) => PresentationTextStyle(
  fontFamily: fontFamily ?? style.fontFamily,
  fontSize: fontSize ?? style.fontSize,
  weight: weight ?? style.weight,
  alignment: alignment ?? style.alignment,
  wrapping: wrapping ?? style.wrapping,
  colorHex: colorHex ?? style.colorHex,
  respectSafeArea: respectSafeArea ?? style.respectSafeArea,
);

PresentationVisualComposition _copyComposition(
  PresentationVisualComposition value, {
  double? translateX,
  double? translateY,
  double? scaleX,
  double? scaleY,
  double? rotationTurns,
  double? opacity,
  double? cropLeft,
  double? cropTop,
  double? cropRight,
  double? cropBottom,
}) => PresentationVisualComposition(
  translateX: translateX ?? value.translateX,
  translateY: translateY ?? value.translateY,
  scaleX: scaleX ?? value.scaleX,
  scaleY: scaleY ?? value.scaleY,
  rotationTurns: rotationTurns ?? value.rotationTurns,
  opacity: opacity ?? value.opacity,
  cropLeft: cropLeft ?? value.cropLeft,
  cropTop: cropTop ?? value.cropTop,
  cropRight: cropRight ?? value.cropRight,
  cropBottom: cropBottom ?? value.cropBottom,
);

String _formatSeconds(int microseconds) =>
    (microseconds / Duration.microsecondsPerSecond).toStringAsFixed(2);

String _audioBusLabel(PresentationAudioBus bus) => switch (bus) {
  PresentationAudioBus.music => 'Musique',
  PresentationAudioBus.voice => 'Voix',
  PresentationAudioBus.effects => 'Effets',
};

String _transitionLabel(PresentationVisualTransitionKind kind) =>
    switch (kind) {
      PresentationVisualTransitionKind.none => 'Aucune',
      PresentationVisualTransitionKind.fade => 'Fondu',
      PresentationVisualTransitionKind.slideLeft => 'Glisse gauche',
      PresentationVisualTransitionKind.slideRight => 'Glisse droite',
      PresentationVisualTransitionKind.slideUp => 'Glisse haut',
      PresentationVisualTransitionKind.slideDown => 'Glisse bas',
    };
