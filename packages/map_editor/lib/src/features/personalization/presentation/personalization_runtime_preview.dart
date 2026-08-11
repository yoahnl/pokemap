import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/personalization_preview_projection.dart';
import '../application/personalization_preview_scenario.dart';
import '../application/personalization_preview_surface_descriptor.dart';
import 'personalization_preview_canvas.dart';
import 'personalization_preview_controls.dart';
import 'personalization_player_surface_adapter.dart';
import 'personalization_title_preview_controls.dart';

/// Runtime-shaped preview surface driven by the current presentation draft.
///
/// The preview reads the same `ProjectPresentationProfile` contract that is
/// packaged for the player. Simulation controls added around this widget stay
/// editor-local and never mutate that contract.
class PersonalizationRuntimePreview extends StatefulWidget {
  const PersonalizationRuntimePreview({
    super.key,
    required this.profile,
    required this.projectName,
    required this.projectRootPath,
    this.baselineProfile,
    this.initialSurface = PersonalizationStudioScene.title,
    this.initialViewport = PersonalizationPreviewViewport.landscape,
    this.introDriverFactory,
  });

  final ProjectPresentationProfile profile;
  final ProjectPresentationProfile? baselineProfile;
  final String projectName;
  final String projectRootPath;
  final PersonalizationStudioScene initialSurface;
  final PersonalizationPreviewViewport initialViewport;
  final PlayerIntroPlaybackFactory? introDriverFactory;

  @override
  State<PersonalizationRuntimePreview> createState() =>
      _PersonalizationRuntimePreviewState();
}

class _PersonalizationRuntimePreviewState
    extends State<PersonalizationRuntimePreview> {
  late PersonalizationStudioScene _surface;
  late PersonalizationPreviewViewport _viewport;
  double _textScale = 1;
  bool _reducedMotion = false;
  bool _comparisonEnabled = false;
  PersonalizationTitlePreviewStage _titleStage =
      PersonalizationTitlePreviewStage.menu;
  final PlayerTitleMotionController _titleMotionController =
      PlayerTitleMotionController();
  final PlayerIntroVideoPreviewController _introPreviewController =
      PlayerIntroVideoPreviewController();

  @override
  void initState() {
    super.initState();
    _surface = widget.initialSurface;
    _viewport = widget.initialViewport;
  }

  @override
  void didUpdateWidget(covariant PersonalizationRuntimePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSurface != widget.initialSurface) {
      _surface = widget.initialSurface;
      _comparisonEnabled = false;
      unawaited(_titleMotionController.releasePlayback());
      unawaited(_introPreviewController.releasePlayback());
    }
    if (oldWidget.initialViewport != widget.initialViewport) {
      _viewport = widget.initialViewport;
      _comparisonEnabled = false;
    }
  }

  @override
  void dispose() {
    unawaited(_titleMotionController.releasePlayback());
    unawaited(_introPreviewController.releasePlayback());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scenario = PersonalizationPreviewScenario(
      draftProfile: widget.profile,
      baselineProfile: widget.baselineProfile,
      surface: _surface,
      viewport: _viewport,
      textScale: _textScale,
      reducedMotion: _reducedMotion,
      comparisonEnabled: _comparisonEnabled,
    );
    final surfaceProjection = PersonalizationPreviewProjection(
      widget.profile,
    ).surface(_surface);
    return PokeMapPanel(
      key: const ValueKey<String>('personalization-runtime-preview'),
      header: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                'Aperçu dans le jeu',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            PokeMapBadge(
              label: surfaceProjection.fontFamily,
              variant: PokeMapBadgeVariant.info,
            ),
            const SizedBox(width: 8),
            PokeMapBadge(
              label: 'Texte ${(_textScale * 100).round()} %',
              variant: PokeMapBadgeVariant.info,
            ),
            if (_reducedMotion) ...<Widget>[
              const SizedBox(width: 8),
              const PokeMapBadge(
                label: 'Mouvement réduit actif',
                variant: PokeMapBadgeVariant.warning,
              ),
            ],
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final descriptor in personalizationPreviewSurfaceDescriptors)
                PokeMapButton(
                  key: ValueKey<String>(
                    'personalization-preview-${descriptor.surface.name}',
                  ),
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.secondary,
                  isSelected: _surface == descriptor.surface,
                  onPressed: () => _selectSurface(descriptor.surface),
                  child: Text(descriptor.label),
                ),
            ],
          ),
          const SizedBox(height: 12),
          PersonalizationPreviewControls(
            scenario: scenario,
            onChanged: (value) => setState(() {
              _surface = value.surface;
              _viewport = value.viewport;
              _textScale = value.textScale;
              _reducedMotion = value.reducedMotion;
              _comparisonEnabled = value.comparisonEnabled;
            }),
          ),
          if (_surface == PersonalizationStudioScene.title) ...<Widget>[
            const SizedBox(height: 12),
            PersonalizationTitlePreviewControls(
              stage: _titleStage,
              onChanged: (stage) => setState(() => _titleStage = stage),
            ),
          ],
          const SizedBox(height: 12),
          PersonalizationPreviewCanvas(
            scenario: scenario,
            surfaceBuilder: _buildSurfacePreview,
          ),
        ],
      ),
    );
  }

  Widget _buildSurfacePreview({
    required ProjectPresentationProfile profile,
    required PersonalizationStudioScene scene,
    required double aspectRatio,
    required bool reducedMotion,
  }) => PersonalizationPlayerSurfaceAdapter(
    profile: profile,
    projectName: widget.projectName,
    projectRootPath: widget.projectRootPath,
    scene: scene,
    aspectRatio: aspectRatio,
    reducedMotion: reducedMotion,
    titleStage: _titleStage,
    titleMotionController: _comparisonEnabled ? null : _titleMotionController,
    allowMediaPlayback: !_comparisonEnabled,
    introPreviewController: _comparisonEnabled ? null : _introPreviewController,
    introDriverFactory: widget.introDriverFactory,
  );

  void _selectSurface(PersonalizationStudioScene surface) {
    if (_surface == surface) return;
    unawaited(_titleMotionController.releasePlayback());
    unawaited(_introPreviewController.releasePlayback());
    setState(() => _surface = surface);
  }
}
