import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/presentation_renderer.dart';

import '../../../../application/authoring_api/presentation_studio_property_command.dart';
import '../../../design_system/design_system.dart';
import '../cinematic_studio_localizations.dart';
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
    this.cueViews = const <String, PresentationCueAuthoringView>{},
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

  /// The Scene side of every linked cue of this cinematic, keyed by marker id
  /// (BETA-CIN-079).
  final Map<String, PresentationCueAuthoringView> cueViews;
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
        key: ValueKey<String>('text-${clip.id}-${orientation.name}'),
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
      if (clip.markerKind == PresentationMarkerKind.interactionCue) ...<Widget>[
        const SizedBox(height: 12),
        PresentationCueBranchesInspectorSection(
          key: ValueKey<String>('cue-branches-${clip.id}'),
          clip: clip,
          view: cueViews[clip.id],
          markers: _markersOf(asset),
          onCommand: onCommand,
        ),
      ],
    ],
  };
}

List<PresentationMarkerClip> _markersOf(PresentationCinematicAsset asset) {
  final markers = <PresentationMarkerClip>[
    for (final track in asset.tracks)
      for (final clip in track.clips)
        if (clip is PresentationMarkerClip) clip,
  ]..sort((left, right) {
      final time = left.startUs.compareTo(right.startUs);
      return time != 0 ? time : left.id.compareTo(right.id);
    });
  return List<PresentationMarkerClip>.unmodifiable(markers);
}

class _MixedSelectionInspector extends StatelessWidget {
  const _MixedSelectionInspector({required this.selectedClipIds});

  final Set<String> selectedClipIds;

  @override
  Widget build(BuildContext context) {
    final copy = CinematicStudioCopy.of(context);
    return PokeMapCinematicInspectorSection(
      title: copy.multipleSelection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PokeMapBadge(
            label: copy.selectedClipCount(selectedClipIds.length),
            variant: PokeMapBadgeVariant.info,
          ),
          const SizedBox(height: 8),
          Text(copy.multipleSelectionMessage),
        ],
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final copy = CinematicStudioCopy.of(context);
    return PokeMapCinematicInspectorSection(
      title: copy.document,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PokeMapTextField(
            label: copy.title,
            controller: _title,
            fieldKey: const ValueKey<String>('presentation-property-title'),
            errorText: _titleError,
            onSubmitted: (_) => _commitMetadata(),
          ),
          const SizedBox(height: 10),
          PokeMapTextField(
            label: copy.description,
            controller: _description,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            onSubmitted: (_) => _commitMetadata(),
          ),
          const SizedBox(height: 10),
          PokeMapTextField(
            label: copy.durationSeconds,
            controller: _duration,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            errorText: _durationError,
            onSubmitted: (_) => _commitMetadata(),
          ),
          const SizedBox(height: 12),
          _ReadOnlyProperty(
            title: copy.responsiveComposition,
            value: copy.oneDocumentBothOrientations,
          ),
          const SizedBox(height: 8),
          _ReadOnlyProperty(
            title: copy.safeAreas,
            value: copy.activeBothOrientations,
          ),
          const SizedBox(height: 8),
          _ReadOnlyProperty(
            title: copy.background,
            value: copy.transparentUntilVisual,
          ),
        ],
      ),
    );
  }

  void _commitMetadata() {
    final copy = CinematicStudioCopy.of(context);
    final title = _title.text.trim();
    final seconds = double.tryParse(_duration.text.replaceAll(',', '.'));
    setState(() {
      _titleError = title.isEmpty ? copy.titleRequired : null;
      _durationError = seconds == null || seconds <= 0
          ? copy.positiveDurationRequired
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
  Widget build(BuildContext context) {
    final copy = CinematicStudioCopy.of(context);
    return PokeMapCinematicInspectorSection(
      title: copy.visualLayer,
      child: Column(
        children: <Widget>[
          PokeMapTextField(
            label: copy.name,
            controller: _label,
            errorText: _labelError,
            onSubmitted: (_) => _commit(),
          ),
          const SizedBox(height: 10),
          PokeMapTextField(
            label: copy.zOrder,
            controller: _zIndex,
            keyboardType: TextInputType.number,
            errorText: _zIndexError,
            onSubmitted: (_) => _commit(),
          ),
          const SizedBox(height: 10),
          PokeMapToggleTile(
            label: copy.visible,
            value: widget.layer.visible,
            onChanged: (value) => _emit(visible: value),
          ),
          const SizedBox(height: 8),
          PokeMapToggleTile(
            label: copy.locked,
            value: widget.layer.locked,
            onChanged: (value) => _emit(locked: value),
          ),
        ],
      ),
    );
  }

  void _commit() {
    final copy = CinematicStudioCopy.of(context);
    final label = _label.text.trim();
    final zIndex = int.tryParse(_zIndex.text);
    setState(() {
      _labelError = label.isEmpty ? copy.nameRequired : null;
      _zIndexError = zIndex == null ? copy.integerRequired : null;
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
    final copy = CinematicStudioCopy.of(context);
    final override = orientation == PresentationFrameOrientation.landscape
        ? clip.landscapeCompositionOverride
        : clip.portraitCompositionOverride;
    final composition = override ?? clip.to;
    final orientationLabel =
        orientation == PresentationFrameOrientation.landscape
        ? copy.landscapeOrientation
        : copy.portraitOrientation;
    return Column(
      children: <Widget>[
        PokeMapCinematicInspectorSection(
          title: copy.responsiveMedia,
          child: Column(
            children: <Widget>[
              PokeMapDropdownField<PresentationVisualMediaKind>(
                label: copy.mediaType,
                value: clip.mediaKind,
                items: <PokeMapDropdownItem<PresentationVisualMediaKind>>[
                  PokeMapDropdownItem(
                    value: PresentationVisualMediaKind.image,
                    label: copy.image,
                  ),
                  PokeMapDropdownItem(
                    value: PresentationVisualMediaKind.video,
                    label: copy.video,
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
                title: copy.sharedSource,
                value: clip.resourceId,
              ),
              const SizedBox(height: 8),
              _OptionalResourceControl(
                label: copy.landscapeSource,
                resourceId: clip.landscapeResourceId,
                fallbackLabel: copy.usesSharedSource,
                onReset: clip.landscapeResourceId == null
                    ? null
                    : () => _emit(_copyVisual(clip, landscapeResourceId: null)),
              ),
              const SizedBox(height: 8),
              _OptionalResourceControl(
                label: copy.portraitSource,
                resourceId: clip.portraitResourceId,
                fallbackLabel: copy.usesSharedSource,
                onReset: clip.portraitResourceId == null
                    ? null
                    : () => _emit(_copyVisual(clip, portraitResourceId: null)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PokeMapCinematicInspectorSection(
          title: copy.compositionFor(orientationLabel),
          child: Column(
            children: <Widget>[
              if (override == null)
                PokeMapBadge(
                  label: copy.sharedValues,
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
                    child: Text(copy.resetToShared),
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
    required this.orientation,
    required this.onCommand,
  });

  final String cinematicId;
  final String trackId;
  final PresentationTextClip clip;
  final PresentationFrameOrientation orientation;
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
  String? _textError;
  String? _fontSizeError;

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
  }

  @override
  void dispose() {
    _text.dispose();
    _localizationKey.dispose();
    _fontSize.dispose();
    _fontFamily.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = CinematicStudioCopy.of(context);
    final composition = switch (widget.orientation) {
      PresentationFrameOrientation.landscape =>
        widget.clip.landscapeCompositionOverride ?? widget.clip.to,
      PresentationFrameOrientation.portrait =>
        widget.clip.portraitCompositionOverride ?? widget.clip.to,
    };
    final hasOverride = switch (widget.orientation) {
      PresentationFrameOrientation.landscape =>
        widget.clip.landscapeCompositionOverride != null,
      PresentationFrameOrientation.portrait =>
        widget.clip.portraitCompositionOverride != null,
    };
    return PokeMapCinematicInspectorSection(
      title: copy.text,
      child: Column(
        children: <Widget>[
          PokeMapTextField(
            label: copy.content,
            controller: _text,
            fieldKey: const ValueKey<String>('presentation-property-text'),
            maxLines: 4,
            errorText: _textError,
            onSubmitted: (_) => _commit(),
          ),
          const SizedBox(height: 10),
          PokeMapTextField(
            label: copy.localizationKey,
            controller: _localizationKey,
            onSubmitted: (_) => _commit(),
          ),
          const SizedBox(height: 10),
          PokeMapTextField(
            label: copy.size,
            controller: _fontSize,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            errorText: _fontSizeError,
            onSubmitted: (_) => _commit(),
          ),
          const SizedBox(height: 10),
          PokeMapTextField(
            label: copy.font,
            controller: _fontFamily,
            onSubmitted: (_) => _commit(),
          ),
          const SizedBox(height: 10),
          _NumberPropertyField(
            label: copy.positionX,
            value: composition.translateX,
            fieldKey: const ValueKey<String>(
              'presentation-property-text-position-x',
            ),
            onChanged: (value) => _moveTo(translateX: value),
          ),
          const SizedBox(height: 10),
          _NumberPropertyField(
            label: copy.positionY,
            value: composition.translateY,
            fieldKey: const ValueKey<String>(
              'presentation-property-text-position-y',
            ),
            onChanged: (value) => _moveTo(translateY: value),
          ),
          if (hasOverride) ...<Widget>[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: PokeMapButton(
                size: PokeMapButtonSize.small,
                variant: PokeMapButtonVariant.ghost,
                onPressed: () => _emitClip(
                  widget.orientation == PresentationFrameOrientation.landscape
                      ? _copyText(
                          widget.clip,
                          landscapeCompositionOverride: null,
                        )
                      : _copyText(
                          widget.clip,
                          portraitCompositionOverride: null,
                        ),
                ),
                child: Text(copy.resetToShared),
              ),
            ),
          ],
          const SizedBox(height: 10),
          PokeMapColorPicker(
            label: copy.color,
            valueHex: widget.clip.style.colorHex,
            buttonKey: const ValueKey<String>(
              'presentation-property-text-color-picker',
            ),
            dialogTitle: copy.textColor,
            cancelLabel: copy.cancel,
            applyLabel: copy.apply,
            hueLabel: copy.hue,
            saturationLabel: copy.saturation,
            brightnessLabel: copy.brightness,
            opacityLabel: copy.opacity,
            hexLabel: copy.hexadecimal,
            invalidHexLabel: copy.invalidColorHex,
            onChanged: (value) =>
                _emit(_copyTextStyle(widget.clip.style, colorHex: value)),
          ),
          const SizedBox(height: 10),
          PokeMapDropdownField<PresentationTextWeight>(
            label: copy.weight,
            value: widget.clip.style.weight,
            items: <PokeMapDropdownItem<PresentationTextWeight>>[
              PokeMapDropdownItem(
                value: PresentationTextWeight.regular,
                label: copy.regular,
              ),
              PokeMapDropdownItem(
                value: PresentationTextWeight.medium,
                label: copy.medium,
              ),
              PokeMapDropdownItem(
                value: PresentationTextWeight.bold,
                label: copy.bold,
              ),
            ],
            onChanged: (value) =>
                _emit(_copyTextStyle(widget.clip.style, weight: value)),
          ),
          const SizedBox(height: 10),
          PokeMapDropdownField<PresentationTextAlignment>(
            label: copy.alignment,
            value: widget.clip.style.alignment,
            items: <PokeMapDropdownItem<PresentationTextAlignment>>[
              for (final value in PresentationTextAlignment.values)
                PokeMapDropdownItem<PresentationTextAlignment>(
                  value: value,
                  label: switch (value) {
                    PresentationTextAlignment.start => copy.start,
                    PresentationTextAlignment.center => copy.centered,
                    PresentationTextAlignment.end => copy.end,
                  },
                ),
            ],
            onChanged: (value) =>
                _emit(_copyTextStyle(widget.clip.style, alignment: value)),
          ),
          const SizedBox(height: 10),
          PokeMapDropdownField<PresentationTextWrapping>(
            label: copy.wrapping,
            value: widget.clip.style.wrapping,
            items: <PokeMapDropdownItem<PresentationTextWrapping>>[
              PokeMapDropdownItem<PresentationTextWrapping>(
                value: PresentationTextWrapping.wrap,
                label: copy.automatic,
              ),
              PokeMapDropdownItem<PresentationTextWrapping>(
                value: PresentationTextWrapping.noWrap,
                label: copy.oneLine,
              ),
            ],
            onChanged: (value) =>
                _emit(_copyTextStyle(widget.clip.style, wrapping: value)),
          ),
          const SizedBox(height: 10),
          PokeMapToggleTile(
            label: copy.respectSafeAreas,
            value: widget.clip.style.respectSafeArea,
            onChanged: (value) => _emit(
              _copyTextStyle(widget.clip.style, respectSafeArea: value),
            ),
          ),
        ],
      ),
    );
  }

  void _commit() {
    final copy = CinematicStudioCopy.of(context);
    final text = _text.text.trim();
    final fontSize = double.tryParse(_fontSize.text.replaceAll(',', '.'));
    setState(() {
      _textError = text.isEmpty ? copy.textRequired : null;
      _fontSizeError = fontSize == null || fontSize <= 0
          ? copy.positiveSizeRequired
          : null;
    });
    if (_textError != null || _fontSizeError != null) {
      return;
    }
    _emit(
      _copyTextStyle(
        widget.clip.style,
        fontSize: fontSize,
        fontFamily: _fontFamily.text,
      ),
      text: text,
      localizationKey: _localizationKey.text,
    );
  }

  void _emit(
    PresentationTextStyle style, {
    String? text,
    String? localizationKey,
    PresentationVisualComposition? from,
    PresentationVisualComposition? to,
  }) {
    _emitClip(
      _copyText(
        widget.clip,
        text: text,
        localizationKey: localizationKey,
        style: style,
        from: from,
        to: to,
      ),
    );
  }

  void _emitClip(PresentationTextClip clip) {
    widget.onCommand(
      PresentationStudioPropertyCommand.updateClip(
        cinematicId: widget.cinematicId,
        trackId: widget.trackId,
        clip: clip,
      ),
    );
  }

  void _moveTo({double? translateX, double? translateY}) {
    final current = switch (widget.orientation) {
      PresentationFrameOrientation.landscape =>
        widget.clip.landscapeCompositionOverride ?? widget.clip.to,
      PresentationFrameOrientation.portrait =>
        widget.clip.portraitCompositionOverride ?? widget.clip.to,
    };
    final next = _copyComposition(
      current,
      translateX: translateX,
      translateY: translateY,
    );
    _emitClip(
      widget.orientation == PresentationFrameOrientation.landscape
          ? _copyText(widget.clip, landscapeCompositionOverride: next)
          : _copyText(widget.clip, portraitCompositionOverride: next),
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
  Widget build(BuildContext context) {
    final copy = CinematicStudioCopy.of(context);
    return PokeMapCinematicInspectorSection(
      title: 'Audio',
      child: Column(
        children: <Widget>[
          PokeMapDropdownField<PresentationAudioKind>(
            label: copy.type,
            value: clip.audioKind,
            items: <PokeMapDropdownItem<PresentationAudioKind>>[
              PokeMapDropdownItem(
                value: PresentationAudioKind.music,
                label: copy.music,
              ),
              PokeMapDropdownItem(
                value: PresentationAudioKind.voice,
                label: copy.voice,
              ),
              PokeMapDropdownItem(
                value: PresentationAudioKind.soundEffect,
                label: copy.soundEffect,
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
          _ReadOnlyProperty(title: copy.sharedSource, value: clip.resourceId),
          if (clip.audioKind != PresentationAudioKind.music) ...<Widget>[
            const SizedBox(height: 8),
            _OptionalResourceControl(
              label: copy.landscapeSource,
              resourceId: clip.landscapeResourceId,
              fallbackLabel: copy.usesSharedSource,
              onReset: clip.landscapeResourceId == null
                  ? null
                  : () => _emit(_copyAudio(clip, landscapeResourceId: null)),
            ),
            const SizedBox(height: 8),
            _OptionalResourceControl(
              label: copy.portraitSource,
              resourceId: clip.portraitResourceId,
              fallbackLabel: copy.usesSharedSource,
              onReset: clip.portraitResourceId == null
                  ? null
                  : () => _emit(_copyAudio(clip, portraitResourceId: null)),
            ),
          ],
          const SizedBox(height: 10),
          PokeMapGuidedSlider(
            label: copy.volume,
            value: (clip.volume * 100).round(),
            min: 0,
            max: 100,
            onChanged: (value) => _emit(_copyAudio(clip, volume: value / 100)),
          ),
          const SizedBox(height: 10),
          PokeMapToggleTile(
            label: copy.loop,
            value: clip.loop,
            onChanged: (value) => _emit(_copyAudio(clip, loop: value)),
          ),
          const SizedBox(height: 10),
          _NumberPropertyField(
            label: copy.fadeInSeconds,
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
            label: copy.fadeOutSeconds,
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
                PokeMapDropdownItem(
                  value: value,
                  label: copy.audioBusLabel(value.name),
                ),
            ],
            onChanged: (value) => _emit(_copyAudio(clip, bus: value)),
          ),
        ],
      ),
    );
  }

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
  Widget build(BuildContext context) {
    final copy = CinematicStudioCopy.of(context);
    return PokeMapCinematicInspectorSection(
      title: copy.captions,
      child: Column(
        children: <Widget>[
          _ReadOnlyProperty(title: copy.resource, value: clip.captionId),
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
            label: copy.startSeconds,
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
            label: copy.durationSeconds,
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
            label: copy.accessibleStyle,
            value: widget.clip.style,
            items: <PokeMapDropdownItem<PresentationCaptionStyle>>[
              PokeMapDropdownItem(
                value: PresentationCaptionStyle.standard,
                label: 'Standard',
              ),
              PokeMapDropdownItem(
                value: PresentationCaptionStyle.highContrast,
                label: copy.highContrast,
              ),
            ],
            onChanged: (value) =>
                _emit(_copyCaption(widget.clip, style: value)),
          ),
          const SizedBox(height: 10),
          PokeMapToggleTile(
            label: copy.projectLocaleFallback,
            value: widget.clip.fallbackToProjectDefault,
            onChanged: (value) => _emit(
              _copyCaption(widget.clip, fallbackToProjectDefault: value),
            ),
          ),
        ],
      ),
    );
  }

  PresentationCaptionClip get clip => widget.clip;

  void _commitTiming() {
    final copy = CinematicStudioCopy.of(context);
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
      _localeError = locale.isEmpty ? copy.localeRequired : null;
      _timingError = validStart && validDuration && fitsDocument
          ? null
          : copy.timingMustFit;
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
  Widget build(BuildContext context) {
    final copy = CinematicStudioCopy.of(context);
    return PokeMapCinematicInspectorSection(
      title: copy.markerAndInteraction,
      child: Column(
        children: <Widget>[
          _ReadOnlyProperty(title: copy.stableIdentity, value: clip.id),
          const SizedBox(height: 8),
          _MarkerNameField(
            value: clip.label,
            onChanged: (value) => _emit(_copyMarker(clip, label: value)),
          ),
          const SizedBox(height: 8),
          _ReadOnlyProperty(
            title: copy.usages,
            value: copy.usageInScene(sceneUsageCount),
          ),
          const SizedBox(height: 10),
          PokeMapDropdownField<PresentationMarkerKind>(
            label: copy.type,
            value: clip.markerKind,
            items: <PokeMapDropdownItem<PresentationMarkerKind>>[
              PokeMapDropdownItem(
                value: PresentationMarkerKind.ordinary,
                label: copy.ordinaryMarker,
              ),
              PokeMapDropdownItem(
                value: PresentationMarkerKind.interactionCue,
                label: copy.sceneInteractionPoint,
              ),
            ],
            onChanged: (value) => _emit(_copyMarker(clip, markerKind: value)),
          ),
          const SizedBox(height: 10),
          PokeMapToggleTile(
            label: copy.required,
            description: copy.requiredCueValidation,
            value: clip.required,
            onChanged: (value) => _emit(_copyMarker(clip, required: value)),
          ),
        ],
      ),
    );
  }

  void _emit(PresentationMarkerClip value) => onCommand(
    PresentationStudioPropertyCommand.updateClip(
      cinematicId: cinematicId,
      trackId: trackId,
      clip: value,
    ),
  );
}

/// The branches of one interaction cue — BETA-CIN-079.
///
/// Sits right under the cue card, in the same field grammar as the rest of
/// the panel. One row per output port of the bound Scene node; "Continue" is
/// stored as no route at all, so an untouched cue keeps a clean document.
class PresentationCueBranchesInspectorSection extends StatelessWidget {
  const PresentationCueBranchesInspectorSection({
    super.key,
    required this.clip,
    required this.view,
    required this.markers,
    required this.onCommand,
  });

  final PresentationMarkerClip clip;

  /// Null when no Scene links this cue yet — the card then explains that
  /// instead of pretending an empty binding exists.
  final PresentationCueAuthoringView? view;
  final List<PresentationMarkerClip> markers;
  final ValueChanged<PresentationStudioPropertyCommand> onCommand;

  @override
  Widget build(BuildContext context) {
    final copy = CinematicStudioCopy.of(context);
    final resolved = view;
    if (resolved == null) {
      return PokeMapCinematicInspectorSection(
        title: copy.branches,
        child: Text(
          copy.cueNotLinked,
          key: const ValueKey<String>('cue-branches-unlinked'),
          style: const TextStyle(fontSize: 11),
        ),
      );
    }
    return PokeMapCinematicInspectorSection(
      title: copy.branches,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _ReadOnlyProperty(
            title: copy.linkedNode,
            value: '${resolved.awaitableLabel} · '
                '${copy.outputsCount(resolved.outputPortIds.length)}',
          ),
          const SizedBox(height: 4),
          Text(
            copy.branchesHint,
            style: const TextStyle(fontSize: 10),
          ),
          for (final portId in resolved.outputPortIds) ...<Widget>[
            const SizedBox(height: 10),
            PokeMapDropdownField<PresentationInteractionOutcomeKind>(
              key: ValueKey<String>('cue-branch-outcome-$portId'),
              label: copy.outputPortLabel(portId),
              value: resolved.routeFor(portId)?.outcome.kind ??
                  PresentationInteractionOutcomeKind.continueTimeline,
              items: <PokeMapDropdownItem<PresentationInteractionOutcomeKind>>[
                PokeMapDropdownItem(
                  value: PresentationInteractionOutcomeKind.continueTimeline,
                  label: copy.outcomeContinue,
                ),
                PokeMapDropdownItem(
                  value: PresentationInteractionOutcomeKind.repeatFromMarker,
                  label: copy.outcomeReplay,
                ),
                PokeMapDropdownItem(
                  value: PresentationInteractionOutcomeKind.seekMarker,
                  label: copy.outcomeSkip,
                ),
                PokeMapDropdownItem(
                  value: PresentationInteractionOutcomeKind.stop,
                  label: copy.outcomeStop,
                ),
                PokeMapDropdownItem(
                  value: PresentationInteractionOutcomeKind.cancelled,
                  label: copy.outcomeCancel,
                ),
                PokeMapDropdownItem(
                  value: PresentationInteractionOutcomeKind.failed,
                  label: copy.outcomeFail,
                ),
              ],
              onChanged: (value) => _changeKind(resolved, portId, value),
            ),
            if (_needsDestination(resolved.routeFor(portId)?.outcome.kind))
              ...<Widget>[
                const SizedBox(height: 6),
                PokeMapDropdownField<String>(
                  key: ValueKey<String>('cue-branch-destination-$portId'),
                  label: copy.destinationCue,
                  value: _destinationOf(resolved, portId) ??
                      (markers.isEmpty ? '' : markers.first.id),
                  items: <PokeMapDropdownItem<String>>[
                    for (final marker in markers)
                      PokeMapDropdownItem(
                        value: marker.id,
                        label: '${marker.label} — '
                            '${_formatMarkerTime(marker.startUs)}',
                      ),
                  ],
                  onChanged: (value) =>
                      _changeDestination(resolved, portId, value),
                ),
              ],
          ],
          const SizedBox(height: 10),
          Text(
            copy.transitionBudgetNote,
            key: const ValueKey<String>('cue-branches-budget'),
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  static bool _needsDestination(PresentationInteractionOutcomeKind? kind) =>
      kind == PresentationInteractionOutcomeKind.seekMarker ||
      kind == PresentationInteractionOutcomeKind.repeatFromMarker;

  String? _destinationOf(PresentationCueAuthoringView view, String portId) {
    final outcome = view.routeFor(portId)?.outcome;
    return switch (outcome) {
      PresentationSeekMarkerOutcome(:final markerId) => markerId,
      PresentationRepeatFromMarkerOutcome(:final markerId) => markerId,
      _ => null,
    };
  }

  void _changeKind(
    PresentationCueAuthoringView view,
    String portId,
    PresentationInteractionOutcomeKind kind,
  ) {
    // Continuing is the default: it is stored as the absence of a route, so
    // an untouched cue never bloats the Scene document.
    if (kind == PresentationInteractionOutcomeKind.continueTimeline) {
      _emit(view, _withoutPort(view, portId));
      return;
    }
    final destination = _destinationOf(view, portId) ??
        (markers.isEmpty ? null : markers.first.id);
    final outcome = switch (kind) {
      PresentationInteractionOutcomeKind.seekMarker => destination == null
          ? null
          : PresentationInteractionOutcome.seekMarker(markerId: destination),
      PresentationInteractionOutcomeKind.repeatFromMarker =>
        destination == null
            ? null
            : PresentationInteractionOutcome.repeatFromMarker(
                markerId: destination,
              ),
      PresentationInteractionOutcomeKind.stop =>
        const PresentationInteractionOutcome.stop(),
      PresentationInteractionOutcomeKind.cancelled =>
        const PresentationInteractionOutcome.cancelled(),
      PresentationInteractionOutcomeKind.failed =>
        const PresentationInteractionOutcome.failed(),
      PresentationInteractionOutcomeKind.continueTimeline => null,
    };
    if (outcome == null) return;
    _emit(view, <ScenePresentationCueOutcomeRoute>[
      ..._withoutPort(view, portId),
      ScenePresentationCueOutcomeRoute(
        outputPortId: portId,
        outcome: outcome,
      ),
    ]);
  }

  void _changeDestination(
    PresentationCueAuthoringView view,
    String portId,
    String markerId,
  ) {
    final kind = view.routeFor(portId)?.outcome.kind;
    if (!_needsDestination(kind)) return;
    _emit(view, <ScenePresentationCueOutcomeRoute>[
      ..._withoutPort(view, portId),
      ScenePresentationCueOutcomeRoute(
        outputPortId: portId,
        outcome: kind == PresentationInteractionOutcomeKind.seekMarker
            ? PresentationInteractionOutcome.seekMarker(markerId: markerId)
            : PresentationInteractionOutcome.repeatFromMarker(
                markerId: markerId,
              ),
      ),
    ]);
  }

  List<ScenePresentationCueOutcomeRoute> _withoutPort(
    PresentationCueAuthoringView view,
    String portId,
  ) => <ScenePresentationCueOutcomeRoute>[
    for (final route in view.routes)
      if (route.outputPortId != portId) route,
  ];

  void _emit(
    PresentationCueAuthoringView view,
    List<ScenePresentationCueOutcomeRoute> routes,
  ) => onCommand(
    PresentationStudioPropertyCommand.setCueRoutes(
      sceneId: view.sceneId,
      presentationNodeId: view.presentationNodeId,
      markerId: view.markerId,
      routes: routes,
    ),
  );
}

String _formatMarkerTime(int startUs) {
  final totalMs = startUs ~/ 1000;
  final minutes = totalMs ~/ 60000;
  final seconds = (totalMs % 60000) ~/ 1000;
  final millis = totalMs % 1000;
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}.'
      '${millis.toString().padLeft(3, '0')}';
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
  Widget build(BuildContext context) {
    final copy = CinematicStudioCopy.of(context);
    return PokeMapTextField(
      label: copy.name,
      controller: _controller,
      fieldKey: const ValueKey<String>('presentation-property-marker-name'),
      errorText: _error,
      onSubmitted: (_) {
        final value = _controller.text.trim();
        setState(() => _error = value.isEmpty ? copy.nameRequired : null);
        if (_error == null) widget.onChanged(value);
      },
    );
  }
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
    final copy = CinematicStudioCopy.of(context);
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
      title: copy.transitionsAndAnimation,
      child: Column(
        children: <Widget>[
          PokeMapDropdownField<PresentationEasing>(
            label: copy.curve,
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
            label: copy.transitionIn,
            value: transitionIn.kind,
            items: _transitionItems(copy),
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
              label: copy.transitionInDuration,
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
            label: copy.transitionOut,
            value: transitionOut.kind,
            items: _transitionItems(copy),
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
              label: copy.transitionOutDuration,
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
          _ReadOnlyProperty(
            title: 'Reduced motion',
            value: copy.reducedMotionDescription,
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

  List<PokeMapDropdownItem<PresentationVisualTransitionKind>> _transitionItems(
    CinematicStudioCopy copy,
  ) => <PokeMapDropdownItem<PresentationVisualTransitionKind>>[
    for (final value in PresentationVisualTransitionKind.values)
      PokeMapDropdownItem(
        value: value,
        label: copy.transitionLabel(value.name),
      ),
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
  Widget build(BuildContext context) {
    final copy = CinematicStudioCopy.of(context);
    return Column(
      children: <Widget>[
        _NumberPropertyField(
          label: copy.positionX,
          value: composition.translateX,
          onChanged: (value) =>
              onChanged(_copyComposition(composition, translateX: value)),
        ),
        const SizedBox(height: 8),
        _NumberPropertyField(
          label: copy.positionY,
          value: composition.translateY,
          onChanged: (value) =>
              onChanged(_copyComposition(composition, translateY: value)),
        ),
        const SizedBox(height: 8),
        _NumberPropertyField(
          label: copy.scale,
          value: composition.scaleX,
          minimumExclusive: 0,
          onChanged: (value) => onChanged(
            _copyComposition(composition, scaleX: value, scaleY: value),
          ),
        ),
        const SizedBox(height: 8),
        _NumberPropertyField(
          label: copy.rotationTurns,
          value: composition.rotationTurns,
          onChanged: (value) =>
              onChanged(_copyComposition(composition, rotationTurns: value)),
        ),
        const SizedBox(height: 8),
        PokeMapGuidedSlider(
          label: copy.opacity,
          value: (composition.opacity * 100).round(),
          min: 0,
          max: 100,
          onChanged: (value) =>
              onChanged(_copyComposition(composition, opacity: value / 100)),
        ),
        const SizedBox(height: 8),
        _NumberPropertyField(
          label: copy.cropLeft,
          value: composition.cropLeft,
          minimumInclusive: 0,
          maximumExclusive: 1 - composition.cropRight,
          onChanged: (value) =>
              onChanged(_copyComposition(composition, cropLeft: value)),
        ),
        const SizedBox(height: 8),
        _NumberPropertyField(
          label: copy.cropTop,
          value: composition.cropTop,
          minimumInclusive: 0,
          maximumExclusive: 1 - composition.cropBottom,
          onChanged: (value) =>
              onChanged(_copyComposition(composition, cropTop: value)),
        ),
        const SizedBox(height: 8),
        _NumberPropertyField(
          label: copy.cropRight,
          value: composition.cropRight,
          minimumInclusive: 0,
          maximumExclusive: 1 - composition.cropLeft,
          onChanged: (value) =>
              onChanged(_copyComposition(composition, cropRight: value)),
        ),
        const SizedBox(height: 8),
        _NumberPropertyField(
          label: copy.cropBottom,
          value: composition.cropBottom,
          minimumInclusive: 0,
          maximumExclusive: 1 - composition.cropTop,
          onChanged: (value) =>
              onChanged(_copyComposition(composition, cropBottom: value)),
        ),
      ],
    );
  }
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
  Widget build(BuildContext context) {
    final copy = CinematicStudioCopy.of(context);
    return PokeMapTextField(
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
            (widget.maximumInclusive != null &&
                value > widget.maximumInclusive!);
        setState(() {
          _error = invalid ? copy.invalidNumber : null;
        });
        if (!invalid) widget.onChanged(value);
      },
    );
  }
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
  Widget build(BuildContext context) {
    final copy = CinematicStudioCopy.of(context);
    return Row(
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
          tooltip: copy.resetSharedSource,
          semanticLabel: copy.resetSharedSourceFor(label),
          icon: const Icon(Icons.restart_alt_rounded),
        ),
      ],
    );
  }
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
  Widget build(BuildContext context) {
    final copy = CinematicStudioCopy.of(context);
    return PokeMapToolbarSurface(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              copy.properties,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (mutationPending)
            PokeMapBadge(label: copy.saving, variant: PokeMapBadgeVariant.info),
          PokeMapIconButton(
            onPressed: canUndo ? onUndo : null,
            tooltip: copy.undoProperty,
            icon: const Icon(Icons.undo_rounded),
          ),
          PokeMapIconButton(
            onPressed: canRedo ? onRedo : null,
            tooltip: copy.redoProperty,
            icon: const Icon(Icons.redo_rounded),
          ),
        ],
      ),
    );
  }
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
  PresentationVisualComposition? from,
  PresentationVisualComposition? to,
  Object? landscapeCompositionOverride = _unsetProperty,
  Object? portraitCompositionOverride = _unsetProperty,
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
  from: from ?? clip.from,
  to: to ?? clip.to,
  landscapeCompositionOverride:
      identical(landscapeCompositionOverride, _unsetProperty)
      ? clip.landscapeCompositionOverride
      : landscapeCompositionOverride as PresentationVisualComposition?,
  portraitCompositionOverride:
      identical(portraitCompositionOverride, _unsetProperty)
      ? clip.portraitCompositionOverride
      : portraitCompositionOverride as PresentationVisualComposition?,
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
