import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/personalization_capability_descriptor.dart';
import '../application/personalization_character_preview_source.dart';
import '../application/personalization_inspector_target.dart';
import '../application/personalization_preview_context_source.dart';
import '../application/personalization_preview_fixtures.dart';
import '../application/personalization_preview_projection.dart';
import '../application/personalization_preview_scenario.dart';
import '../application/personalization_preview_surface_descriptor.dart';
import '../application/personalization_project_preview_projection.dart';
import 'personalization_player_surface_adapter.dart';
import 'personalization_preview_canvas.dart';
import 'personalization_preview_context_picker.dart';
import 'personalization_preview_controls.dart';
import 'personalization_title_preview_controls.dart';

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
    this.battleState = PersonalizationBattlePreviewState.commands,
    this.contentSource = PersonalizationPreviewContentSource.demonstration,
    this.surfaceFidelity =
        PersonalizationPreviewSurfaceFidelity.playerInterface,
    this.contexts = const <PersonalizationPreviewContextOption>[],
    this.contextsLoading = false,
    this.contextsErrorMessage,
    this.projectManifest,
    this.resolveTilesetPath,
    this.titleMotionDriverFactory,
    this.introDriverFactory,
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
  final PersonalizationBattlePreviewState battleState;
  final PersonalizationPreviewContentSource contentSource;
  final PersonalizationPreviewSurfaceFidelity surfaceFidelity;
  final List<PersonalizationPreviewContextOption> contexts;
  final bool contextsLoading;
  final String? contextsErrorMessage;
  final ProjectManifest? projectManifest;
  final String? Function(String tilesetId)? resolveTilesetPath;
  final PlayerIntroPlaybackFactory? titleMotionDriverFactory;
  final PlayerIntroPlaybackFactory? introDriverFactory;

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
  PersonalizationTitlePreviewStage _titleStage =
      PersonalizationTitlePreviewStage.menu;
  int _titleStageSelectionRevision = 0;
  final PlayerTitleMotionController _titleMotionController =
      PlayerTitleMotionController();
  final PlayerIntroVideoPreviewController _introPreviewController =
      PlayerIntroVideoPreviewController();
  final Map<PersonalizationPreviewContextKind, String?> _selectedContextIds =
      <PersonalizationPreviewContextKind, String?>{};

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
      _titleStageSelectionRevision++;
      _comparisonEnabled = false;
      unawaited(_titleMotionController.releasePlayback());
      unawaited(_introPreviewController.releasePlayback());
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
    final mapContext = _context(PersonalizationPreviewContextKind.map);
    final dialogueContext = _context(
      PersonalizationPreviewContextKind.dialogue,
    );
    final portraitContext = _context(
      PersonalizationPreviewContextKind.characterPortrait,
      preferredSourceId: widget.dialogueCharacter?.characterId,
    );
    final encounterContext = _context(
      PersonalizationPreviewContextKind.encounter,
    );
    final projectMap = PersonalizationProjectPreviewProjection.map(mapContext);
    final dialogueData = PersonalizationProjectPreviewProjection.dialogue(
      dialogueContext,
      portrait: portraitContext,
      showChoices: widget.showDialogueChoices,
    );
    final battleData = PersonalizationProjectPreviewProjection.battle(
      encounterContext,
      state: widget.battleState,
    );
    final dialogueCharacter = portraitContext == null
        ? widget.dialogueCharacter
        : PersonalizationCharacterPreviewOption(
            id: portraitContext.id,
            characterId: portraitContext.sourceId,
            displayName:
                portraitContext.detail['characterName'] as String? ??
                portraitContext.label,
            portraitPath: portraitContext.detail['portraitPath'] as String?,
            expressionId: portraitContext.detail['portraitStateId'] as String?,
            expressionLabel:
                portraitContext.detail['portraitStateLabel'] as String? ??
                portraitContext.detail['portraitStateId'] as String? ??
                'Portrait',
            workspaceRevision:
                portraitContext.detail['workspaceRevision'] as String? ?? '',
            portraitBytes: portraitContext.mediaBytes,
            diagnosticCodes: portraitContext.diagnosticCodes,
          );
    final surfaceFidelity =
        projectMap != null &&
            widget.scene != PersonalizationStudioScene.title &&
            widget.scene != PersonalizationStudioScene.intro
        ? PersonalizationPreviewSurfaceFidelity.editorBackdrop
        : widget.surfaceFidelity;
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  'Aperçu en direct',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                PokeMapBadge(
                  key: const ValueKey<String>(
                    'personalization-preview-content-source',
                  ),
                  label: switch (widget.contentSource) {
                    PersonalizationPreviewContentSource.demonstration =>
                      'Démonstration',
                    PersonalizationPreviewContentSource.project =>
                      'Projet réel',
                  },
                  variant:
                      widget.contentSource ==
                          PersonalizationPreviewContentSource.project
                      ? PokeMapBadgeVariant.success
                      : PokeMapBadgeVariant.warning,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  switch (surfaceFidelity) {
                    PersonalizationPreviewSurfaceFidelity.playerInterface =>
                      'Widgets du jeu',
                    PersonalizationPreviewSurfaceFidelity.editorBackdrop =>
                      'Widgets du jeu sur la carte du projet',
                  },
                  key: const ValueKey<String>(
                    'personalization-preview-surface-fidelity',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const PokeMapBadge(
                  key: ValueKey<String>(
                    'personalization-preview-local-controls',
                  ),
                  label: 'Réglages d’essai',
                  variant: PokeMapBadgeVariant.info,
                ),
              ],
            ),
            const SizedBox(height: 8),
            PersonalizationPreviewControls(
              scenario: scenario,
              onChanged: _applyScenario,
            ),
            if (widget.scene == PersonalizationStudioScene.title) ...<Widget>[
              const SizedBox(height: 8),
              PersonalizationTitlePreviewControls(
                stage: _titleStage,
                onChanged: (stage) => unawaited(_selectTitleStage(stage)),
              ),
            ],
            PersonalizationPreviewContextPicker(
              scene: widget.scene,
              contexts: widget.contexts,
              selectedIds: <PersonalizationPreviewContextKind, String?>{
                for (final kind in PersonalizationPreviewContextKind.values)
                  kind: _context(kind)?.id,
              },
              onSelected: (kind, id) {
                setState(() => _selectedContextIds[kind] = id);
              },
              isLoading: widget.contextsLoading,
              errorMessage: widget.contextsErrorMessage,
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
              dialogueCharacter: dialogueCharacter,
              showDialoguePortrait: widget.showDialoguePortrait,
              showDialogueName: widget.showDialogueName,
              showDialogueChoices: widget.showDialogueChoices,
              battleState: widget.battleState,
              mapContext: projectMap,
              dialogueData: dialogueData,
              battleData: battleData,
              useProjectContent:
                  widget.contentSource ==
                  PersonalizationPreviewContentSource.project,
              projectManifest: widget.projectManifest,
              resolveTilesetPath: widget.resolveTilesetPath,
              titleStage: _titleStage,
              titleMotionController: scenario.showComparison
                  ? null
                  : _titleMotionController,
              titleMotionDriverFactory: widget.titleMotionDriverFactory,
              allowMediaPlayback: !scenario.showComparison,
              introPreviewController: scenario.showComparison
                  ? null
                  : _introPreviewController,
              introDriverFactory: widget.introDriverFactory,
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

  Future<void> _selectTitleStage(PersonalizationTitlePreviewStage stage) async {
    final revision = ++_titleStageSelectionRevision;
    if (_titleStage == stage) return;
    await _titleMotionController.releasePlayback();
    if (!mounted || revision != _titleStageSelectionRevision) return;
    setState(() => _titleStage = stage);
  }

  PersonalizationPreviewContextOption? _context(
    PersonalizationPreviewContextKind kind, {
    String? preferredSourceId,
  }) {
    final options = widget.contexts
        .where((option) => option.kind == kind)
        .toList(growable: false);
    if (options.isEmpty) return null;
    final selectedId = _selectedContextIds[kind];
    final selected = options
        .where((option) => option.id == selectedId)
        .firstOrNull;
    if (selected != null) return selected;
    final preferred = options
        .where(
          (option) => option.sourceId == preferredSourceId && option.isReady,
        )
        .firstOrNull;
    return preferred ??
        options.where((option) => option.isReady).firstOrNull ??
        options.first;
  }
}
