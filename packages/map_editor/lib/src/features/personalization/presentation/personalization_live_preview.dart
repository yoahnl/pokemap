import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/personalization_character_preview_source.dart';
import '../application/personalization_inspector_target.dart';
import '../application/personalization_preview_projection.dart';
import '../application/personalization_preview_scenario.dart';
import '../application/personalization_preview_surface_descriptor.dart';
import 'personalization_player_surface_adapter.dart';
import 'personalization_preview_canvas.dart';
import 'personalization_preview_controls.dart';

class PersonalizationLivePreview extends StatefulWidget {
  const PersonalizationLivePreview({
    super.key,
    required this.profile,
    required this.projectName,
    required this.projectRootPath,
    required this.scene,
    this.baselineProfile,
    this.initialViewport = PersonalizationPreviewViewport.landscape,
    this.onTargeted,
    this.dialogueCharacter,
    this.showDialoguePortrait = true,
    this.showDialogueName = true,
    this.showDialogueChoices = false,
  });

  final ProjectPresentationProfile profile;
  final ProjectPresentationProfile? baselineProfile;
  final String projectName;
  final String projectRootPath;
  final PersonalizationStudioScene scene;
  final PersonalizationPreviewViewport initialViewport;
  final ValueChanged<PersonalizationInspectorTarget>? onTargeted;
  final PersonalizationCharacterPreviewOption? dialogueCharacter;
  final bool showDialoguePortrait;
  final bool showDialogueName;
  final bool showDialogueChoices;

  @override
  State<PersonalizationLivePreview> createState() =>
      _PersonalizationLivePreviewState();
}

class _PersonalizationLivePreviewState
    extends State<PersonalizationLivePreview> {
  late PersonalizationPreviewViewport _viewport;
  double _textScale = 1;
  bool _reducedMotion = false;
  bool _comparisonEnabled = false;

  @override
  void initState() {
    super.initState();
    _viewport = widget.initialViewport;
  }

  @override
  void didUpdateWidget(covariant PersonalizationLivePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialViewport != widget.initialViewport) {
      _viewport = widget.initialViewport;
      _comparisonEnabled = false;
    }
    if (oldWidget.scene != widget.scene) {
      _comparisonEnabled = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scenario = PersonalizationPreviewScenario(
      draftProfile: widget.profile,
      baselineProfile: widget.baselineProfile,
      surface: widget.scene,
      viewport: _viewport,
      textScale: _textScale,
      reducedMotion: _reducedMotion,
      comparisonEnabled: _comparisonEnabled,
    );
    return PokeMapPanel(
      key: const ValueKey<String>('personalization-live-preview'),
      expandChild: true,
      padding: const EdgeInsets.all(12),
      header: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Aperçu en direct',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            PersonalizationPreviewControls(
              scenario: scenario,
              onChanged: _applyScenario,
            ),
          ],
        ),
      ),
      child: PersonalizationPreviewCanvas(
        scenario: scenario,
        surfaceBuilder:
            ({
              required profile,
              required scene,
              required aspectRatio,
              required reducedMotion,
            }) => PersonalizationPlayerSurfaceAdapter(
              profile: profile,
              projectName: widget.projectName,
              projectRootPath: widget.projectRootPath,
              scene: scene,
              aspectRatio: aspectRatio,
              reducedMotion: reducedMotion,
              onTargeted: widget.onTargeted,
              dialogueCharacter: widget.dialogueCharacter,
              showDialoguePortrait: widget.showDialoguePortrait,
              showDialogueName: widget.showDialogueName,
              showDialogueChoices: widget.showDialogueChoices,
            ),
      ),
    );
  }

  void _applyScenario(PersonalizationPreviewScenario value) {
    setState(() {
      _viewport = value.viewport;
      _textScale = value.textScale;
      _reducedMotion = value.reducedMotion;
      _comparisonEnabled = value.comparisonEnabled;
    });
  }
}
