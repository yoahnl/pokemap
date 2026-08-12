import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/personalization_preview.dart';

import '../../../ui/canvas/cinematics/cinematic_map_backdrop_layer_plan_loader.dart';
import '../../../ui/design_system/design_system.dart';
import '../application/personalization_capability_descriptor.dart';
import '../application/personalization_character_preview_source.dart';
import '../application/personalization_inspector_target.dart';
import '../application/personalization_preview_context_source.dart';
import '../application/personalization_preview_projection.dart';
import '../application/personalization_preview_scenario.dart';
import '../application/personalization_preview_surface_descriptor.dart';
import '../application/personalization_project_preview_projection.dart';
import 'personalization_player_surface_adapter.dart';
import 'personalization_layout_overlay.dart';
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
    this.contentSource = PersonalizationPreviewContentSource.project,
    this.surfaceFidelity =
        PersonalizationPreviewSurfaceFidelity.playerInterface,
    this.contexts = const <PersonalizationPreviewContextOption>[],
    this.contextsLoading = false,
    this.contextsErrorMessage,
    this.projectManifest,
    this.resolveTilesetPath,
    this.mapBackdropPlanLoader,
    this.titleMotionDriverFactory,
    this.introDriverFactory,
    this.onLayoutPreviewChanged,
    this.onLayoutCommitted,
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
  final CinematicMapBackdropLayerPlanLoader? mapBackdropPlanLoader;
  final PlayerIntroPlaybackFactory? titleMotionDriverFactory;
  final PlayerIntroPlaybackFactory? introDriverFactory;
  final ValueChanged<ProjectPresentationLayoutsProfile>? onLayoutPreviewChanged;
  final ValueChanged<ProjectPresentationLayoutsProfile>? onLayoutCommitted;

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
  String? _selectedEnemySpeciesId;
  String? _selectedPlayerSpeciesId;
  ProjectPresentationLayoutsProfile? _previewLayouts;

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
      _previewLayouts = null;
      unawaited(_titleMotionController.releasePlayback());
      unawaited(_introPreviewController.releasePlayback());
    }
    if (oldWidget.profile != widget.profile) {
      _previewLayouts = null;
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
    final dialogueScenario = _context(
      PersonalizationPreviewContextKind.dialogueScenario,
    );
    final legacyDialogueContext = _context(
      PersonalizationPreviewContextKind.dialogue,
    );
    final dialogueContext = dialogueScenario ?? legacyDialogueContext;
    final scenarioCharacterId = dialogueScenario?.detail['characterId'];
    final portraitContext = scenarioCharacterId is String
        ? dialogueScenario
        : dialogueScenario == null
        ? _context(
            PersonalizationPreviewContextKind.characterPortrait,
            preferredSourceId: widget.dialogueCharacter?.characterId,
          )
        : null;
    final encounterContext = _context(
      PersonalizationPreviewContextKind.encounter,
    );
    final enemyOptions = _battleOptions(encounterContext, 'entries');
    final playerOptions = _battleOptions(
      encounterContext,
      'playerPokemonOptions',
      fallbackKey: 'playerPokemon',
    );
    final selectedEnemySpeciesId = _selectedBattleSpeciesId(
      enemyOptions,
      _selectedEnemySpeciesId,
    );
    final selectedPlayerSpeciesId = _selectedBattleSpeciesId(
      playerOptions,
      _selectedPlayerSpeciesId,
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
      presentation: widget.profile.battle,
      enemySpeciesId: selectedEnemySpeciesId,
      playerSpeciesId: selectedPlayerSpeciesId,
    );
    final battleSprites =
        PersonalizationProjectPreviewProjection.battleSpritePaths(
          encounterContext,
          enemySpeciesId: selectedEnemySpeciesId,
          playerSpeciesId: selectedPlayerSpeciesId,
        );
    final battleBackdropPath =
        PersonalizationProjectPreviewProjection.battleBackdropPath(
          projectMap,
          encounterContext,
        );
    final portraitCharacterId = portraitContext?.detail['characterId'];
    final dialogueCharacter =
        portraitContext == null || portraitCharacterId is! String
        ? widget.dialogueCharacter
        : PersonalizationCharacterPreviewOption(
            id: portraitContext.id,
            characterId: portraitCharacterId,
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
    final previewProfile = _previewLayouts == null
        ? widget.profile
        : widget.profile.copyWith(layouts: _previewLayouts);
    final scenario = PersonalizationPreviewScenario(
      draftProfile: previewProfile,
      baselineProfile: widget.baselineProfile,
      surface: widget.scene,
      viewport: _viewport,
      textScale: _textScale,
      reducedMotion: _reducedMotion,
      comparisonEnabled: _comparisonEnabled,
    );
    return LayoutBuilder(
      builder: (context, constraints) => PokeMapPanel(
        key: const ValueKey<String>('personalization-live-preview'),
        expandChild: true,
        padding: const EdgeInsets.all(12),
        header: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: (constraints.maxHeight * .55)
                .clamp(160.0, 420.0)
                .toDouble(),
          ),
          child: SingleChildScrollView(
            key: const ValueKey<String>(
              'personalization-preview-settings-scroll',
            ),
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
                if (widget.scene ==
                    PersonalizationStudioScene.title) ...<Widget>[
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
                    setState(() {
                      _selectedContextIds[kind] = id;
                      if (kind == PersonalizationPreviewContextKind.encounter) {
                        _selectedEnemySpeciesId = null;
                        _selectedPlayerSpeciesId = null;
                      }
                    });
                  },
                  isLoading: widget.contextsLoading,
                  errorMessage: widget.contextsErrorMessage,
                ),
                if (widget.scene == PersonalizationStudioScene.battle &&
                    encounterContext != null) ...<Widget>[
                  const SizedBox(height: 8),
                  _PersonalizationBattleContextControls(
                    enemyOptions: enemyOptions,
                    playerOptions: playerOptions,
                    selectedEnemySpeciesId: selectedEnemySpeciesId,
                    selectedPlayerSpeciesId: selectedPlayerSpeciesId,
                    onEnemyChanged: (value) {
                      setState(() => _selectedEnemySpeciesId = value);
                    },
                    onPlayerChanged: (value) {
                      setState(() => _selectedPlayerSpeciesId = value);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        child: PersonalizationPreviewCanvas(
          scenario: scenario,
          contentBuilder:
              _layoutRole == null || widget.onLayoutCommitted == null
              ? null
              : (context, breakpoint, child) => PersonalizationLayoutOverlay(
                  surface: _layoutRole!,
                  breakpoint: breakpoint,
                  profile:
                      previewProfile.layouts ??
                      suggestedProjectPresentationLayouts(
                        previewProfile.branding.layoutVariant,
                      ),
                  textScale: scenario.textScale,
                  onPreviewChanged: _previewLayout,
                  onCommitted: _commitLayout,
                  dragBounds: _layoutDragBounds(previewProfile),
                  child: child,
                ),
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
                battleBackdropPath: battleBackdropPath,
                enemyBattleSpritePath: battleSprites.enemy,
                playerBattleSpritePath: battleSprites.player,
                mapBackdropPlanLoader: widget.mapBackdropPlanLoader,
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
      ),
    );
  }

  ProjectPresentationSurfaceRole? get _layoutRole => switch (widget.scene) {
    PersonalizationStudioScene.title => ProjectPresentationSurfaceRole.title,
    PersonalizationStudioScene.pause =>
      ProjectPresentationSurfaceRole.pauseMenu,
    PersonalizationStudioScene.dialogue =>
      ProjectPresentationSurfaceRole.dialogue,
    PersonalizationStudioScene.battle =>
      ProjectPresentationSurfaceRole.battleHud,
    _ => null,
  };

  Rect _layoutDragBounds(
    ProjectPresentationProfile profile,
  ) => switch (widget.scene) {
    PersonalizationStudioScene.dialogue =>
      switch (profile.dialogue?.placement ?? ProjectDialoguePlacement.bottom) {
        ProjectDialoguePlacement.top => const Rect.fromLTWH(.02, .02, .96, .34),
        ProjectDialoguePlacement.center => const Rect.fromLTWH(
          .02,
          .33,
          .96,
          .34,
        ),
        ProjectDialoguePlacement.bottom => const Rect.fromLTWH(
          .02,
          .64,
          .96,
          .34,
        ),
      },
    PersonalizationStudioScene.battle => const Rect.fromLTWH(.02, .7, .96, .28),
    _ => const Rect.fromLTWH(0, 0, 1, 1),
  };

  void _previewLayout(ProjectPresentationLayoutsProfile layouts) {
    setState(() => _previewLayouts = layouts);
    widget.onLayoutPreviewChanged?.call(layouts);
  }

  void _commitLayout(ProjectPresentationLayoutsProfile layouts) {
    setState(() => _previewLayouts = null);
    widget.onLayoutCommitted?.call(layouts);
  }

  List<Map<Object?, Object?>> _battleOptions(
    PersonalizationPreviewContextOption? context,
    String key, {
    String? fallbackKey,
  }) {
    final value = context?.detail[key];
    final options = value is List
        ? value.whereType<Map>().cast<Map<Object?, Object?>>().toList()
        : <Map<Object?, Object?>>[];
    if (options.isEmpty && fallbackKey != null) {
      final fallback = context?.detail[fallbackKey];
      if (fallback is Map) options.add(fallback.cast<Object?, Object?>());
    }
    final unique = <String, Map<Object?, Object?>>{};
    for (final option in options) {
      final speciesId = option['speciesId'];
      if (speciesId is String) unique.putIfAbsent(speciesId, () => option);
    }
    return unique.values.toList(growable: false);
  }

  String? _selectedBattleSpeciesId(
    List<Map<Object?, Object?>> options,
    String? selected,
  ) {
    if (options.any((option) => option['speciesId'] == selected)) {
      return selected;
    }
    return options.firstOrNull?['speciesId'] as String?;
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

class _PersonalizationBattleContextControls extends StatelessWidget {
  const _PersonalizationBattleContextControls({
    required this.enemyOptions,
    required this.playerOptions,
    required this.selectedEnemySpeciesId,
    required this.selectedPlayerSpeciesId,
    required this.onEnemyChanged,
    required this.onPlayerChanged,
  });

  final List<Map<Object?, Object?>> enemyOptions;
  final List<Map<Object?, Object?>> playerOptions;
  final String? selectedEnemySpeciesId;
  final String? selectedPlayerSpeciesId;
  final ValueChanged<String> onEnemyChanged;
  final ValueChanged<String> onPlayerChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        if (selectedEnemySpeciesId case final enemySpeciesId?)
          SizedBox(
            width: 240,
            child: PokeMapDropdownField<String>(
              key: const ValueKey<String>('battle-preview-enemy'),
              label: 'Créature adverse',
              value: enemySpeciesId,
              items: _items(enemyOptions),
              onChanged: onEnemyChanged,
            ),
          ),
        if (selectedPlayerSpeciesId case final playerSpeciesId?)
          SizedBox(
            width: 240,
            child: PokeMapDropdownField<String>(
              key: const ValueKey<String>('battle-preview-player'),
              label: 'Créature du joueur',
              value: playerSpeciesId,
              items: _items(playerOptions),
              onChanged: onPlayerChanged,
            ),
          ),
        if (selectedEnemySpeciesId == null)
          const PokeMapBadge(
            label: 'Aucune créature dans cette rencontre',
            variant: PokeMapBadgeVariant.warning,
          ),
        if (selectedPlayerSpeciesId == null)
          const PokeMapBadge(
            label: 'Aucune créature jouable dans le projet',
            variant: PokeMapBadgeVariant.warning,
          ),
      ],
    );
  }

  List<PokeMapDropdownItem<String>> _items(
    List<Map<Object?, Object?>> options,
  ) => <PokeMapDropdownItem<String>>[
    for (final option in options)
      if (option['speciesId'] case final String speciesId)
        PokeMapDropdownItem<String>(
          value: speciesId,
          label: switch (option['displayName']) {
            final String name when name.trim().isNotEmpty => name,
            _ => speciesId,
          },
        ),
  ];
}
