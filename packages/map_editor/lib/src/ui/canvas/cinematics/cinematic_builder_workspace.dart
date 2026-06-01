import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

typedef AddCinematicDraftStepCallback = Future<String?> Function({
  required String cinematicId,
  String? afterStepId,
});

typedef RemoveCinematicDraftStepCallback = Future<bool> Function({
  required String cinematicId,
  required String stepId,
});

typedef AddCinematicBasicBlockStepCallback = Future<String?> Function({
  required String cinematicId,
  required CinematicTimelineBasicBlockKind blockKind,
  String? afterStepId,
});

typedef UpdateCinematicBasicBlockStepCallback = Future<bool> Function({
  required String cinematicId,
  required String stepId,
  int? durationMs,
  CinematicTimelineFadeMode? fadeMode,
  CinematicTimelineCameraMode? cameraMode,
});

typedef AddCinematicRequiredActorCallback = Future<String?> Function({
  required String cinematicId,
});

typedef AddCinematicMovementTargetCallback = Future<String?> Function({
  required String cinematicId,
});

typedef UpdateCinematicMovementTargetCallback = Future<bool> Function({
  required String cinematicId,
  required String targetId,
  required String label,
  String? description,
});

typedef RemoveCinematicMovementTargetCallback = Future<bool> Function({
  required String cinematicId,
  required String targetId,
});

typedef AddCinematicActorFacingStepCallback = Future<String?> Function({
  required String cinematicId,
  required String actorId,
  required CinematicTimelineActorFacingDirection direction,
  String? afterStepId,
});

typedef UpdateCinematicActorFacingStepCallback = Future<bool> Function({
  required String cinematicId,
  required String stepId,
  String? actorId,
  CinematicTimelineActorFacingDirection? direction,
});

typedef AddCinematicActorMoveStepCallback = Future<String?> Function({
  required String cinematicId,
  required String actorId,
  required String targetId,
  required int durationMs,
  required CinematicTimelineActorMovementMode movementMode,
  String? afterStepId,
});

typedef UpdateCinematicActorMoveStepCallback = Future<bool> Function({
  required String cinematicId,
  required String stepId,
  String? actorId,
  String? targetId,
  int? durationMs,
  CinematicTimelineActorMovementMode? movementMode,
});

typedef RemoveCinematicAuthoringStepCallback = Future<bool> Function({
  required String cinematicId,
  required String stepId,
});

typedef _UpdateBasicBlockCallback = Future<void> Function(
  CinematicTimelineStep step, {
  int? durationMs,
  CinematicTimelineFadeMode? fadeMode,
  CinematicTimelineCameraMode? cameraMode,
});

typedef _UpdateActorFacingCallback = Future<void> Function(
  CinematicTimelineStep step, {
  String? actorId,
  CinematicTimelineActorFacingDirection? direction,
});

typedef _UpdateActorMoveCallback = Future<void> Function(
  CinematicTimelineStep step, {
  String? actorId,
  String? targetId,
  int? durationMs,
  CinematicTimelineActorMovementMode? movementMode,
});

typedef _AddBasicBlockCallback = Future<void> Function(
  CinematicTimelineBasicBlockKind blockKind,
);

typedef _AddRequiredActorCallback = Future<void> Function();

typedef _AddMovementTargetCallback = Future<void> Function();

typedef _UpdateMovementTargetCallback = Future<bool> Function(
  CinematicMovementTargetRef target, {
  required String label,
  String? description,
});

typedef _RemoveMovementTargetCallback = Future<bool> Function(
  CinematicMovementTargetRef target,
);

typedef _AddActorFacingCallback = Future<void> Function();

typedef _AddActorMoveCallback = Future<void> Function();

typedef _RemoveAuthoringStepCallback = Future<void> Function(
  CinematicTimelineStep step,
);

class CinematicBuilderWorkspace extends StatefulWidget {
  const CinematicBuilderWorkspace({
    super.key,
    required this.entry,
    required this.asset,
    required this.onBackToLibrary,
    required this.onAddDraftStep,
    required this.onRemoveDraftStep,
    required this.onAddBasicBlockStep,
    required this.onUpdateBasicBlockStep,
    required this.onAddRequiredActor,
    required this.onAddMovementTarget,
    required this.onUpdateMovementTarget,
    required this.onRemoveMovementTarget,
    required this.onAddActorFacingStep,
    required this.onUpdateActorFacingStep,
    required this.onAddActorMoveStep,
    required this.onUpdateActorMoveStep,
    required this.onRemoveAuthoringStep,
  });

  final CinematicsLibraryEntry entry;
  final CinematicAsset asset;
  final VoidCallback onBackToLibrary;
  final AddCinematicDraftStepCallback onAddDraftStep;
  final RemoveCinematicDraftStepCallback onRemoveDraftStep;
  final AddCinematicBasicBlockStepCallback onAddBasicBlockStep;
  final UpdateCinematicBasicBlockStepCallback onUpdateBasicBlockStep;
  final AddCinematicRequiredActorCallback onAddRequiredActor;
  final AddCinematicMovementTargetCallback onAddMovementTarget;
  final UpdateCinematicMovementTargetCallback onUpdateMovementTarget;
  final RemoveCinematicMovementTargetCallback onRemoveMovementTarget;
  final AddCinematicActorFacingStepCallback onAddActorFacingStep;
  final UpdateCinematicActorFacingStepCallback onUpdateActorFacingStep;
  final AddCinematicActorMoveStepCallback onAddActorMoveStep;
  final UpdateCinematicActorMoveStepCallback onUpdateActorMoveStep;
  final RemoveCinematicAuthoringStepCallback onRemoveAuthoringStep;

  @override
  State<CinematicBuilderWorkspace> createState() =>
      _CinematicBuilderWorkspaceState();
}

class _CinematicBuilderWorkspaceState extends State<CinematicBuilderWorkspace> {
  String? _selectedStepId;

  @override
  void didUpdateWidget(CinematicBuilderWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sameCinematic = oldWidget.asset.id == widget.asset.id;
    if (!sameCinematic || !_hasStep(widget.asset, _selectedStepId)) {
      _selectedStepId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedStep = _selectedStep(widget.asset, _selectedStepId);
    final selectedStepIndex = selectedStep == null
        ? null
        : widget.asset.timeline.steps.indexOf(selectedStep);
    return Material(
      type: MaterialType.transparency,
      child: PokeMapPageSurface(
        key: const ValueKey('cinematic-builder-workspace'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BuilderHeader(
              entry: widget.entry,
              onBackToLibrary: widget.onBackToLibrary,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 250,
                    child: _BlockPalette(
                      entry: widget.entry,
                      asset: widget.asset,
                      onAddBasicBlock: _addBasicBlock,
                      onAddRequiredActor: _addRequiredActor,
                      onAddMovementTarget: _addMovementTarget,
                      onUpdateMovementTarget: _updateMovementTarget,
                      onRemoveMovementTarget: _removeMovementTarget,
                      onAddActorFacing: _addActorFacing,
                      onAddActorMove: _addActorMove,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _PreviewSandbox(
                            entry: widget.entry,
                            asset: widget.asset,
                            selectedStep: selectedStep,
                            selectedStepIndex: selectedStepIndex,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 390,
                          child: _TimelinePlaceholder(
                            entry: widget.entry,
                            asset: widget.asset,
                            selectedStepId: _selectedStepId,
                            onStepSelected: (step) {
                              setState(() => _selectedStepId = step.id);
                            },
                            onAddDraftStep: _addDraftStep,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 300,
                    child: _InspectorPlaceholder(
                      entry: widget.entry,
                      asset: widget.asset,
                      selectedStep: selectedStep,
                      selectedStepIndex: selectedStepIndex,
                      onRemoveDraftStep: _removeDraftStep,
                      onUpdateBasicBlock: _updateBasicBlock,
                      onUpdateActorFacing: _updateActorFacing,
                      onUpdateActorMove: _updateActorMove,
                      onRemoveAuthoringStep: _removeAuthoringStep,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addDraftStep() async {
    final createdStepId = await widget.onAddDraftStep(
      cinematicId: widget.asset.id,
      afterStepId: _selectedStepId,
    );
    if (!mounted || createdStepId == null) {
      return;
    }
    setState(() => _selectedStepId = createdStepId);
  }

  Future<void> _removeDraftStep(CinematicTimelineStep step) async {
    if (!isCinematicTimelineDraftStep(step)) {
      return;
    }
    final removed = await widget.onRemoveDraftStep(
      cinematicId: widget.asset.id,
      stepId: step.id,
    );
    if (!mounted || !removed) {
      return;
    }
    setState(() => _selectedStepId = null);
  }

  Future<void> _addBasicBlock(
    CinematicTimelineBasicBlockKind blockKind,
  ) async {
    final createdStepId = await widget.onAddBasicBlockStep(
      cinematicId: widget.asset.id,
      blockKind: blockKind,
      afterStepId: _selectedStepId,
    );
    if (!mounted || createdStepId == null) {
      return;
    }
    setState(() => _selectedStepId = createdStepId);
  }

  Future<void> _updateBasicBlock(
    CinematicTimelineStep step, {
    int? durationMs,
    CinematicTimelineFadeMode? fadeMode,
    CinematicTimelineCameraMode? cameraMode,
  }) async {
    if (!isCinematicTimelineBasicBlockStep(step)) {
      return;
    }
    await widget.onUpdateBasicBlockStep(
      cinematicId: widget.asset.id,
      stepId: step.id,
      durationMs: durationMs,
      fadeMode: fadeMode,
      cameraMode: cameraMode,
    );
  }

  Future<void> _addRequiredActor() async {
    await widget.onAddRequiredActor(cinematicId: widget.asset.id);
  }

  Future<void> _addMovementTarget() async {
    await widget.onAddMovementTarget(cinematicId: widget.asset.id);
  }

  Future<bool> _updateMovementTarget(
    CinematicMovementTargetRef target, {
    required String label,
    String? description,
  }) {
    return widget.onUpdateMovementTarget(
      cinematicId: widget.asset.id,
      targetId: target.targetId,
      label: label,
      description: description,
    );
  }

  Future<bool> _removeMovementTarget(CinematicMovementTargetRef target) {
    return widget.onRemoveMovementTarget(
      cinematicId: widget.asset.id,
      targetId: target.targetId,
    );
  }

  Future<void> _addActorFacing() async {
    final actor = widget.asset.requiredActors.isEmpty
        ? null
        : widget.asset.requiredActors.first;
    if (actor == null) {
      return;
    }
    final createdStepId = await widget.onAddActorFacingStep(
      cinematicId: widget.asset.id,
      actorId: actor.actorId,
      direction: CinematicTimelineActorFacingDirection.down,
      afterStepId: _selectedStepId,
    );
    if (!mounted || createdStepId == null) {
      return;
    }
    setState(() => _selectedStepId = createdStepId);
  }

  Future<void> _addActorMove() async {
    final actor = widget.asset.requiredActors.isEmpty
        ? null
        : widget.asset.requiredActors.first;
    final target = widget.asset.movementTargets.isEmpty
        ? null
        : widget.asset.movementTargets.first;
    if (actor == null || target == null) {
      return;
    }
    final createdStepId = await widget.onAddActorMoveStep(
      cinematicId: widget.asset.id,
      actorId: actor.actorId,
      targetId: target.targetId,
      durationMs: cinematicTimelineDefaultActorMoveDurationMs,
      movementMode: CinematicTimelineActorMovementMode.walk,
      afterStepId: _selectedStepId,
    );
    if (!mounted || createdStepId == null) {
      return;
    }
    setState(() => _selectedStepId = createdStepId);
  }

  Future<void> _updateActorFacing(
    CinematicTimelineStep step, {
    String? actorId,
    CinematicTimelineActorFacingDirection? direction,
  }) async {
    if (!isCinematicTimelineActorFacingStep(step)) {
      return;
    }
    await widget.onUpdateActorFacingStep(
      cinematicId: widget.asset.id,
      stepId: step.id,
      actorId: actorId,
      direction: direction,
    );
  }

  Future<void> _updateActorMove(
    CinematicTimelineStep step, {
    String? actorId,
    String? targetId,
    int? durationMs,
    CinematicTimelineActorMovementMode? movementMode,
  }) async {
    if (!isCinematicTimelineActorMoveStep(step)) {
      return;
    }
    await widget.onUpdateActorMoveStep(
      cinematicId: widget.asset.id,
      stepId: step.id,
      actorId: actorId,
      targetId: targetId,
      durationMs: durationMs,
      movementMode: movementMode,
    );
  }

  Future<void> _removeAuthoringStep(CinematicTimelineStep step) async {
    if (!isCinematicTimelineAuthoringStep(step)) {
      return;
    }
    final removed = await widget.onRemoveAuthoringStep(
      cinematicId: widget.asset.id,
      stepId: step.id,
    );
    if (!mounted || !removed) {
      return;
    }
    setState(() => _selectedStepId = null);
  }
}

class _BuilderHeader extends StatelessWidget {
  const _BuilderHeader({
    required this.entry,
    required this.onBackToLibrary,
  });

  final CinematicsLibraryEntry entry;
  final VoidCallback onBackToLibrary;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final backAction = _HeaderAction(
      label: 'Retour Library',
      button: PokeMapButton(
        key: const ValueKey('cinematic-builder-back-button'),
        onPressed: onBackToLibrary,
        variant: PokeMapButtonVariant.secondary,
        size: PokeMapButtonSize.small,
        leading: const Icon(CupertinoIcons.chevron_left),
        child: const SizedBox.shrink(),
      ),
    );
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cinematic Builder V0',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DefaultTextStyle.of(context).style.copyWith(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          '${entry.title} • ${entry.id}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DefaultTextStyle.of(context).style.copyWith(
                color: colors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
    final badges = Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        const PokeMapBadge(
          label: 'Authoring V0 borné',
          variant: PokeMapBadgeVariant.info,
        ),
        PokeMapBadge(
          label: entry.diagnostics.isEmpty
              ? 'Aucun diagnostic'
              : '${entry.diagnostics.length} diagnostic(s)',
          variant: entry.diagnostics.isEmpty
              ? PokeMapBadgeVariant.success
              : PokeMapBadgeVariant.warning,
        ),
        PokeMapBadge(
          label: '${entry.timeline.stepCount} step(s)',
          variant: PokeMapBadgeVariant.neutral,
        ),
      ],
    );
    const actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        _HeaderAction(
          label: 'Valider',
          button: PokeMapButton(
            key: ValueKey('cinematic-builder-validate-button'),
            onPressed: null,
            variant: PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.small,
            leading: Icon(CupertinoIcons.check_mark_circled),
            child: SizedBox.shrink(),
          ),
        ),
        _HeaderAction(
          label: 'Aperçu',
          button: PokeMapButton(
            key: ValueKey('cinematic-builder-preview-button'),
            onPressed: null,
            variant: PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.small,
            leading: Icon(CupertinoIcons.play),
            child: SizedBox.shrink(),
          ),
        ),
        _HeaderAction(
          label: 'Sauvegarder',
          button: PokeMapButton(
            key: ValueKey('cinematic-builder-save-button'),
            onPressed: null,
            variant: PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.small,
            leading: Icon(CupertinoIcons.tray_arrow_down),
            child: SizedBox.shrink(),
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1300) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  backAction,
                  const SizedBox(width: 10),
                  const PokeMapIconTile(
                    icon: CupertinoIcons.film,
                    tone: PokeMapTone.cinematic,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: title),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: badges),
                  const SizedBox(width: 10),
                  actions,
                ],
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            backAction,
            const SizedBox(width: 10),
            const PokeMapIconTile(
              icon: CupertinoIcons.film,
              tone: PokeMapTone.cinematic,
            ),
            const SizedBox(width: 10),
            Expanded(child: title),
            const SizedBox(width: 10),
            badges,
            const SizedBox(width: 10),
            actions,
          ],
        );
      },
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.label,
    required this.button,
  });

  final String label;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        const SizedBox(width: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DefaultTextStyle.of(context).style.copyWith(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _BlockPalette extends StatelessWidget {
  const _BlockPalette({
    required this.entry,
    required this.asset,
    required this.onAddBasicBlock,
    required this.onAddRequiredActor,
    required this.onAddMovementTarget,
    required this.onUpdateMovementTarget,
    required this.onRemoveMovementTarget,
    required this.onAddActorFacing,
    required this.onAddActorMove,
  });

  final CinematicsLibraryEntry entry;
  final CinematicAsset asset;
  final _AddBasicBlockCallback onAddBasicBlock;
  final _AddRequiredActorCallback onAddRequiredActor;
  final _AddMovementTargetCallback onAddMovementTarget;
  final _UpdateMovementTargetCallback onUpdateMovementTarget;
  final _RemoveMovementTargetCallback onRemoveMovementTarget;
  final _AddActorFacingCallback onAddActorFacing;
  final _AddActorMoveCallback onAddActorMove;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      expandChild: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(
            title: 'Palette de blocs',
            subtitle: 'Blocs V0 bornés',
          ),
          const SizedBox(height: 10),
          const PokeMapBadge(
            label: 'Authoring V0',
            variant: PokeMapBadgeVariant.info,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _RequiredActorsCard(
                    asset: asset,
                    onAddRequiredActor: onAddRequiredActor,
                  ),
                  const SizedBox(height: 8),
                  _MovementTargetsCard(
                    asset: asset,
                    onAddMovementTarget: onAddMovementTarget,
                    onUpdateMovementTarget: onUpdateMovementTarget,
                    onRemoveMovementTarget: onRemoveMovementTarget,
                  ),
                  const SizedBox(height: 8),
                  for (final block in _paletteBlocks) ...[
                    _PaletteBlockTile(
                      block: block,
                      onAddBasicBlock: onAddBasicBlock,
                    ),
                    const SizedBox(height: 8),
                  ],
                  _ActorFacingPaletteTile(
                    asset: asset,
                    onAddActorFacing: onAddActorFacing,
                  ),
                  const SizedBox(height: 8),
                  _ActorMovePaletteTile(
                    asset: asset,
                    onAddActorMove: onAddActorMove,
                  ),
                  const SizedBox(height: 8),
                  for (final block in _lockedPaletteBlocks) ...[
                    _PaletteBlockTile(
                      block: block,
                      onAddBasicBlock: onAddBasicBlock,
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _MutedText(
            '${entry.timeline.stepCount} bloc(s) lu(s) depuis la timeline.',
          ),
        ],
      ),
    );
  }
}

class _RequiredActorsCard extends StatelessWidget {
  const _RequiredActorsCard({
    required this.asset,
    required this.onAddRequiredActor,
  });

  final CinematicAsset asset;
  final _AddRequiredActorCallback onAddRequiredActor;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StrongText('Acteurs requis'),
          const SizedBox(height: 4),
          if (asset.requiredActors.isEmpty)
            const _MutedText('Aucun acteur requis')
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final actor in asset.requiredActors)
                  PokeMapBadge(
                    label: _actorDisplayLabel(actor),
                    variant: PokeMapBadgeVariant.narrative,
                  ),
              ],
            ),
          const SizedBox(height: 8),
          _InlineControlAction(
            label: 'Acteur',
            button: PokeMapButton(
              key: const ValueKey(
                'cinematic-builder-add-required-actor-button',
              ),
              onPressed: onAddRequiredActor,
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.small,
              leading: const Icon(CupertinoIcons.person_add),
              child: const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementTargetsCard extends StatelessWidget {
  const _MovementTargetsCard({
    required this.asset,
    required this.onAddMovementTarget,
    required this.onUpdateMovementTarget,
    required this.onRemoveMovementTarget,
  });

  final CinematicAsset asset;
  final _AddMovementTargetCallback onAddMovementTarget;
  final _UpdateMovementTargetCallback onUpdateMovementTarget;
  final _RemoveMovementTargetCallback onRemoveMovementTarget;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StrongText('Cibles de déplacement'),
          const SizedBox(height: 4),
          if (asset.movementTargets.isEmpty)
            const _MutedText('Aucune cible authoring')
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final target in asset.movementTargets) ...[
                  _MovementTargetEditorRow(
                    key: ValueKey(
                      'cinematic-builder-movement-target-row-'
                      '${target.targetId}',
                    ),
                    asset: asset,
                    target: target,
                    onUpdateMovementTarget: onUpdateMovementTarget,
                    onRemoveMovementTarget: onRemoveMovementTarget,
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          const SizedBox(height: 8),
          _InlineControlAction(
            label: 'Cible',
            button: PokeMapButton(
              key: const ValueKey(
                'cinematic-builder-add-movement-target-button',
              ),
              onPressed: onAddMovementTarget,
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.small,
              leading: const Icon(CupertinoIcons.location),
              child: const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementTargetEditorRow extends StatefulWidget {
  const _MovementTargetEditorRow({
    super.key,
    required this.asset,
    required this.target,
    required this.onUpdateMovementTarget,
    required this.onRemoveMovementTarget,
  });

  final CinematicAsset asset;
  final CinematicMovementTargetRef target;
  final _UpdateMovementTargetCallback onUpdateMovementTarget;
  final _RemoveMovementTargetCallback onRemoveMovementTarget;

  @override
  State<_MovementTargetEditorRow> createState() =>
      _MovementTargetEditorRowState();
}

class _MovementTargetEditorRowState extends State<_MovementTargetEditorRow> {
  late final TextEditingController _labelController;
  late final TextEditingController _descriptionController;
  String? _feedback;
  bool _isSaving = false;
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.target.label);
    _descriptionController =
        TextEditingController(text: widget.target.description ?? '');
  }

  @override
  void didUpdateWidget(covariant _MovementTargetEditorRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target.label != widget.target.label) {
      _labelController.text = widget.target.label;
    }
    final description = widget.target.description ?? '';
    if ((oldWidget.target.description ?? '') != description) {
      _descriptionController.text = description;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final usageCount = _movementTargetUsageCount(
      widget.asset,
      widget.target.targetId,
    );
    final isUsed = usageCount > 0;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        border: Border.all(color: colors.borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _StrongText(widget.target.label)),
              const SizedBox(width: 6),
              PokeMapBadge(
                label: isUsed ? 'Utilisée' : 'Libre',
                variant: isUsed
                    ? PokeMapBadgeVariant.info
                    : PokeMapBadgeVariant.neutral,
              ),
            ],
          ),
          const SizedBox(height: 3),
          _MutedText('Id: ${widget.target.targetId}'),
          if (widget.target.description != null) ...[
            const SizedBox(height: 3),
            _MutedText(widget.target.description!),
          ],
          const SizedBox(height: 8),
          _MovementTargetTextField(
            key: ValueKey(
              'cinematic-builder-movement-target-label-'
              '${widget.target.targetId}',
            ),
            controller: _labelController,
            placeholder: 'Label cible',
          ),
          const SizedBox(height: 6),
          _MovementTargetTextField(
            key: ValueKey(
              'cinematic-builder-movement-target-description-'
              '${widget.target.targetId}',
            ),
            controller: _descriptionController,
            placeholder: 'Description optionnelle',
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _InlineControlAction(
                label: 'Enregistrer',
                button: PokeMapButton(
                  key: ValueKey(
                    'cinematic-builder-save-movement-target-'
                    '${widget.target.targetId}',
                  ),
                  onPressed: _isSaving ? null : _save,
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  isLoading: _isSaving,
                  leading: const Icon(CupertinoIcons.check_mark),
                  child: const SizedBox.shrink(),
                ),
              ),
              _InlineControlAction(
                label: 'Supprimer',
                button: PokeMapButton(
                  key: ValueKey(
                    'cinematic-builder-delete-movement-target-'
                    '${widget.target.targetId}',
                  ),
                  onPressed: isUsed || _isRemoving ? null : _remove,
                  variant: PokeMapButtonVariant.danger,
                  size: PokeMapButtonSize.small,
                  isLoading: _isRemoving,
                  leading: const Icon(CupertinoIcons.trash),
                  child: const SizedBox.shrink(),
                ),
              ),
            ],
          ),
          if (isUsed) ...[
            const SizedBox(height: 6),
            const _MutedText(
              'Cette cible est utilisée par un bloc Déplacement acteur.',
            ),
          ],
          if (_feedback != null) ...[
            const SizedBox(height: 6),
            _MutedText(_feedback!),
          ],
        ],
      ),
    );
  }

  Future<void> _save() async {
    final label = _labelController.text.trim();
    if (label.isEmpty) {
      setState(() => _feedback = 'Label cible obligatoire');
      return;
    }
    final description = _descriptionController.text.trim();
    setState(() {
      _isSaving = true;
      _feedback = null;
    });
    final saved = await widget.onUpdateMovementTarget(
      widget.target,
      label: label,
      description: description.isEmpty ? null : description,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isSaving = false;
      _feedback = saved ? null : 'Cible introuvable';
    });
  }

  Future<void> _remove() async {
    setState(() {
      _isRemoving = true;
      _feedback = null;
    });
    final removed = await widget.onRemoveMovementTarget(widget.target);
    if (!mounted) {
      return;
    }
    setState(() {
      _isRemoving = false;
      _feedback = removed ? null : 'Suppression impossible';
    });
  }
}

class _MovementTargetTextField extends StatelessWidget {
  const _MovementTargetTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String placeholder;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final textStyle = DefaultTextStyle.of(context).style;
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      maxLines: maxLines,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      style: textStyle.copyWith(
        color: colors.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      placeholderStyle: textStyle.copyWith(
        color: colors.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceBase,
        border: Border.all(color: colors.borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _ActorFacingPaletteTile extends StatelessWidget {
  const _ActorFacingPaletteTile({
    required this.asset,
    required this.onAddActorFacing,
  });

  final CinematicAsset asset;
  final _AddActorFacingCallback onAddActorFacing;

  @override
  Widget build(BuildContext context) {
    final hasActors = asset.requiredActors.isNotEmpty;
    final description = hasActors
        ? 'Acteur requis + direction.'
        : 'Ajoutez d’abord un acteur requis';
    return PokeMapCard(
      child: Row(
        children: [
          const PokeMapIconTile(
            icon: CupertinoIcons.arrow_turn_up_right,
            tone: PokeMapTone.neutral,
            size: 30,
            iconSize: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _StrongText('Orientation acteur'),
                const SizedBox(height: 2),
                _MutedText(description),
              ],
            ),
          ),
          const SizedBox(width: 6),
          PokeMapButton(
            key: const ValueKey('cinematic-builder-palette-actorFace-button'),
            onPressed: hasActors ? onAddActorFacing : null,
            variant: PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.small,
            leading: const Icon(CupertinoIcons.plus),
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ActorMovePaletteTile extends StatelessWidget {
  const _ActorMovePaletteTile({
    required this.asset,
    required this.onAddActorMove,
  });

  final CinematicAsset asset;
  final _AddActorMoveCallback onAddActorMove;

  @override
  Widget build(BuildContext context) {
    final hasActors = asset.requiredActors.isNotEmpty;
    final hasTargets = asset.movementTargets.isNotEmpty;
    final description = !hasActors
        ? 'Ajoutez d’abord un acteur'
        : !hasTargets
            ? 'Ajoutez d’abord une cible'
            : 'Acteur + cible + durée.';
    return PokeMapCard(
      child: Row(
        children: [
          const PokeMapIconTile(
            icon: CupertinoIcons.person_crop_square,
            tone: PokeMapTone.neutral,
            size: 30,
            iconSize: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _StrongText('Déplacement acteur'),
                const SizedBox(height: 2),
                _MutedText(description),
              ],
            ),
          ),
          const SizedBox(width: 6),
          PokeMapButton(
            key: const ValueKey('cinematic-builder-palette-actorMove-button'),
            onPressed: hasActors && hasTargets ? onAddActorMove : null,
            variant: PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.small,
            leading: const Icon(CupertinoIcons.plus),
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _PaletteBlockTile extends StatelessWidget {
  const _PaletteBlockTile({
    required this.block,
    required this.onAddBasicBlock,
  });

  final _PaletteBlock block;
  final _AddBasicBlockCallback onAddBasicBlock;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final blockKind = block.blockKind;
    return PokeMapCard(
      child: Row(
        children: [
          PokeMapIconTile(
            icon: block.icon,
            tone: PokeMapTone.neutral,
            size: 30,
            iconSize: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StrongText(block.label),
                const SizedBox(height: 2),
                _MutedText(block.description),
              ],
            ),
          ),
          const SizedBox(width: 6),
          if (blockKind == null)
            Icon(
              CupertinoIcons.lock_fill,
              color: colors.textMuted,
              size: 13,
            )
          else
            PokeMapButton(
              key: ValueKey(
                  'cinematic-builder-palette-${blockKind.name}-button'),
              onPressed: () {
                onAddBasicBlock(blockKind);
              },
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.small,
              leading: const Icon(CupertinoIcons.plus),
              child: const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

class _PreviewSandbox extends StatelessWidget {
  const _PreviewSandbox({
    required this.entry,
    required this.asset,
    required this.selectedStep,
    required this.selectedStepIndex,
  });

  final CinematicsLibraryEntry entry;
  final CinematicAsset asset;
  final CinematicTimelineStep? selectedStep;
  final int? selectedStepIndex;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      key: const ValueKey('cinematic-builder-preview-placeholder'),
      expandChild: true,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.rectangle_on_rectangle,
                color: colors.textMuted,
                size: 34,
              ),
              const SizedBox(height: 10),
              Text(
                'Aperçu sandbox',
                textAlign: TextAlign.center,
                style: DefaultTextStyle.of(context).style.copyWith(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'La preview in-engine n’est pas disponible dans ce lot. '
                'Cette zone reste une sandbox visuelle sans runtime.',
                textAlign: TextAlign.center,
                style: DefaultTextStyle.of(context).style.copyWith(
                      color: colors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  PokeMapBadge(
                    label: '${entry.timeline.stepCount} step(s)',
                    variant: PokeMapBadgeVariant.neutral,
                  ),
                  PokeMapBadge(
                    label: _durationLabel(entry.timeline),
                    variant: PokeMapBadgeVariant.info,
                  ),
                ],
              ),
              if (selectedStep != null && selectedStepIndex != null) ...[
                const SizedBox(height: 12),
                const _MutedText('Preview réelle à venir. Bloc sélectionné :'),
                const SizedBox(height: 6),
                PokeMapBadge(
                  label: '${selectedStepIndex! + 1}. '
                      '${_stepDisplayTitle(
                    asset,
                    selectedStep!,
                    selectedStepIndex!,
                  )} • '
                      '${selectedStep!.kind.name}',
                  variant: PokeMapBadgeVariant.info,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

const _timelineLaneHeaderWidth = 154.0;
const _timelineAxisHeight = 28.0;
const _timelineLaneRowHeight = 30.0;
const _timelineBarMinWidth = 96.0;
const _timelineFallbackPixelsPerMs =
    _timelineBarMinWidth / cinematicTimelineFallbackVisualDurationMs;

class _TimelinePlaceholder extends StatelessWidget {
  const _TimelinePlaceholder({
    required this.entry,
    required this.asset,
    required this.selectedStepId,
    required this.onStepSelected,
    required this.onAddDraftStep,
  });

  final CinematicsLibraryEntry entry;
  final CinematicAsset asset;
  final String? selectedStepId;
  final ValueChanged<CinematicTimelineStep> onStepSelected;
  final VoidCallback onAddDraftStep;

  @override
  Widget build(BuildContext context) {
    final timeline = entry.timeline;
    final steps = asset.timeline.steps;
    final timeLayout = buildCinematicTimelineTimeLayoutReadModel(asset);
    final stepsById = {
      for (final step in steps) step.id: step,
    };
    return PokeMapPanel(
      key: const ValueKey('cinematic-builder-timeline-placeholder'),
      expandChild: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: _SectionTitle(
                  title: 'Timeline par pistes',
                  subtitle: 'Projection temporelle dérivée du déroulé linéaire',
                ),
              ),
              const SizedBox(width: 8),
              _HeaderAction(
                label: 'Ajouter un brouillon',
                button: PokeMapButton(
                  key: const ValueKey('cinematic-builder-add-draft-button'),
                  onPressed: onAddDraftStep,
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  leading: const Icon(CupertinoIcons.plus),
                  child: const SizedBox.shrink(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              PokeMapBadge(
                label: '${timeline.stepCount} step(s)',
                variant: PokeMapBadgeVariant.info,
              ),
              PokeMapBadge(
                label: _durationLabel(timeline),
                variant: PokeMapBadgeVariant.neutral,
              ),
              PokeMapBadge(
                label: _timelineTotalLabel(timeLayout.totalDurationMs),
                variant: PokeMapBadgeVariant.info,
              ),
              PokeMapBadge(
                label: '${timeLayout.laneCount} piste(s)',
                variant: PokeMapBadgeVariant.narrative,
              ),
              const PokeMapBadge(
                label: 'Ordre linéaire conservé',
                variant: PokeMapBadgeVariant.neutral,
              ),
              const PokeMapBadge(
                label: 'Layout temporel dérivé',
                variant: PokeMapBadgeVariant.success,
              ),
              if (timeLayout.blocks.any(
                (block) =>
                    block.durationSource ==
                    CinematicTimelineVisualDurationSource.fallback,
              ))
                const PokeMapBadge(
                  label: 'Fallback visuel',
                  variant: PokeMapBadgeVariant.warning,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: steps.isEmpty
                ? const _EmptyTimelineState()
                : _TimelineTimeGrid(
                    asset: asset,
                    timeLayout: timeLayout,
                    stepsById: stepsById,
                    selectedStepId: selectedStepId,
                    onStepSelected: onStepSelected,
                  ),
          ),
        ],
      ),
    );
  }
}

class _TimelineTimeGrid extends StatelessWidget {
  const _TimelineTimeGrid({
    required this.asset,
    required this.timeLayout,
    required this.stepsById,
    required this.selectedStepId,
    required this.onStepSelected,
  });

  final CinematicAsset asset;
  final CinematicTimelineTimeLayoutReadModel timeLayout;
  final Map<String, CinematicTimelineStep> stepsById;
  final String? selectedStepId;
  final ValueChanged<CinematicTimelineStep> onStepSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackViewportWidth = math.max(
          360.0,
          constraints.maxWidth - _timelineLaneHeaderWidth - 10,
        );
        final contentWidth = _timelineContentWidth(
          timeLayout.totalDurationMs,
          trackViewportWidth,
        );
        final pixelsPerMs = timeLayout.totalDurationMs <= 0
            ? 1.0
            : contentWidth / timeLayout.totalDurationMs;
        return SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _timelineLaneHeaderWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _TimelineLaneHeaderCell(),
                    for (final lane in timeLayout.lanes)
                      _TimelineLaneLabelCell(lane: lane),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: contentWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TimelineAxis(
                          ticks: timeLayout.ticks,
                          pixelsPerMs: pixelsPerMs,
                          contentWidth: contentWidth,
                        ),
                        for (final lane in timeLayout.lanes)
                          _TimelineTrackRow(
                            asset: asset,
                            lane: lane,
                            ticks: timeLayout.ticks,
                            stepsById: stepsById,
                            selectedStepId: selectedStepId,
                            pixelsPerMs: pixelsPerMs,
                            onStepSelected: onStepSelected,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimelineLaneHeaderCell extends StatelessWidget {
  const _TimelineLaneHeaderCell();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Container(
      height: _timelineAxisHeight,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        border: Border(
          bottom: BorderSide(color: colors.borderSubtle),
        ),
      ),
      child: Text(
        'Pistes',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: DefaultTextStyle.of(context).style.copyWith(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _TimelineLaneLabelCell extends StatelessWidget {
  const _TimelineLaneLabelCell({required this.lane});

  final CinematicTimelineTimeLane lane;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final tone = _laneTone(lane.laneKind).resolve(context);
    final laneMeta =
        lane.actorId == null ? '${lane.blocks.length} bloc(s)' : 'Acteur';
    return Container(
      key: ValueKey('cinematic-builder-lane-${lane.laneId}'),
      height: _timelineLaneRowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        border: Border(
          bottom: BorderSide(color: colors.borderSubtle),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _laneIcon(lane.laneKind),
            size: 15,
            color: tone.icon,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              lane.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DefaultTextStyle.of(context).style.copyWith(
                    color: colors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              laneMeta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DefaultTextStyle.of(context).style.copyWith(
                    color: colors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineAxis extends StatelessWidget {
  const _TimelineAxis({
    required this.ticks,
    required this.pixelsPerMs,
    required this.contentWidth,
  });

  final List<CinematicTimelineTimeTick> ticks;
  final double pixelsPerMs;
  final double contentWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Container(
      height: _timelineAxisHeight,
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        border: Border(
          bottom: BorderSide(color: colors.borderSubtle),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          for (final tick in ticks)
            Positioned(
              left: _tickLeft(tick.timeMs, pixelsPerMs, contentWidth),
              top: 0,
              bottom: 0,
              child: Container(
                width: 1,
                color: colors.borderSubtle.withValues(alpha: 0.72),
              ),
            ),
          for (final tick in ticks)
            Positioned(
              left: math.min(
                _tickLeft(tick.timeMs, pixelsPerMs, contentWidth) + 5,
                math.max(0, contentWidth - 58),
              ),
              top: 8,
              child: SizedBox(
                width: 56,
                child: Text(
                  tick.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DefaultTextStyle.of(context).style.copyWith(
                        color: tick.isMajor
                            ? colors.textSecondary
                            : colors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineTrackRow extends StatelessWidget {
  const _TimelineTrackRow({
    required this.asset,
    required this.lane,
    required this.ticks,
    required this.stepsById,
    required this.selectedStepId,
    required this.pixelsPerMs,
    required this.onStepSelected,
  });

  final CinematicAsset asset;
  final CinematicTimelineTimeLane lane;
  final List<CinematicTimelineTimeTick> ticks;
  final Map<String, CinematicTimelineStep> stepsById;
  final String? selectedStepId;
  final double pixelsPerMs;
  final ValueChanged<CinematicTimelineStep> onStepSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return SizedBox(
      height: _timelineLaneRowHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.borderSubtle),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            for (final tick in ticks)
              Positioned(
                left: tick.timeMs * pixelsPerMs,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 1,
                  color: colors.borderSubtle.withValues(alpha: 0.36),
                ),
              ),
            if (lane.blocks.isEmpty)
              const Positioned.fill(
                left: 8,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _MutedText('Aucun step dans cette piste.'),
                ),
              )
            else
              for (final block in lane.blocks)
                if (stepsById[block.stepId] case final step?)
                  Positioned(
                    left: block.startMs * pixelsPerMs,
                    top: 3,
                    width: math.max(
                      _timelineBarMinWidth,
                      block.visualDurationMs * pixelsPerMs,
                    ),
                    height: 24,
                    child: _TimelineStepCard(
                      asset: asset,
                      block: block,
                      step: step,
                      selected: selectedStepId == block.stepId,
                      onTap: () => onStepSelected(step),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStepCard extends StatelessWidget {
  const _TimelineStepCard({
    required this.asset,
    required this.block,
    required this.step,
    required this.selected,
    required this.onTap,
  });

  final CinematicAsset asset;
  final CinematicTimelineTimeBlock block;
  final CinematicTimelineStep step;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final diagnostics = _stepDiagnostics(asset, step);
    final movementMode = cinematicTimelineActorMovementModeOf(step);
    final pathMode = cinematicTimelineActorPathModeOf(step);
    final colors = context.pokeMapColors;
    final tone = _blockTone(block.kind).resolve(context);
    return PokeMapCard(
      key: ValueKey('cinematic-builder-step-card-${block.stepId}'),
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: SizedBox(
        key: ValueKey('cinematic-builder-time-block-${block.stepId}'),
        child: ClipRect(
          child: Row(
            children: [
              PokeMapBadge(
                label: '${block.stepIndex + 1}',
                variant: selected
                    ? PokeMapBadgeVariant.info
                    : PokeMapBadgeVariant.neutral,
              ),
              const SizedBox(width: 5),
              Icon(
                _stepIcon(block.kind),
                color: tone.icon,
                size: 13,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  block.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DefaultTextStyle.of(context).style.copyWith(
                        color: colors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: SizedBox(
                  height: 12,
                  child: _TimelineBarMetaStrip(
                    block: block,
                    step: step,
                    asset: asset,
                    selected: selected,
                    diagnostics: diagnostics,
                    movementMode: movementMode,
                    pathMode: pathMode,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineBarMetaStrip extends StatelessWidget {
  const _TimelineBarMetaStrip({
    required this.block,
    required this.step,
    required this.asset,
    required this.selected,
    required this.diagnostics,
    required this.movementMode,
    required this.pathMode,
  });

  final CinematicTimelineTimeBlock block;
  final CinematicTimelineStep step;
  final CinematicAsset asset;
  final bool selected;
  final List<CinematicDiagnostic> diagnostics;
  final CinematicTimelineActorMovementMode? movementMode;
  final CinematicTimelineActorPathMode? pathMode;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TimelineBarMetaText(block.kind.name),
          _TimelineBarMetaText(_blockDurationBadgeLabel(block)),
          if (isCinematicTimelineDraftStep(step))
            const _TimelineBarMetaText('Brouillon'),
          if (block.isAuthoringOwned && !isCinematicTimelineDraftStep(step))
            const _TimelineBarMetaText('Builder V0'),
          if (block.actorId != null) _TimelineBarMetaText(block.actorId!),
          if (block.actorId != null)
            _TimelineBarMetaText(
              'Acteur: ${_actorDisplayLabelForId(asset, block.actorId!)}',
            ),
          if (isCinematicTimelineActorFacingStep(step))
            _TimelineBarMetaText(
              _actorDirectionLabel(
                cinematicTimelineActorFacingDirectionOf(step),
              ),
            ),
          if (block.targetId != null)
            _TimelineBarMetaText(
              block.kind == CinematicTimelineStepKind.actorMove
                  ? _movementTargetBadgeLabel(asset, block.targetId!)
                  : block.targetId!,
            ),
          if (movementMode != null)
            _TimelineBarMetaText(_actorMovementModeLabel(movementMode!)),
          if (pathMode != null)
            _TimelineBarMetaText(_actorPathModeLabel(pathMode!)),
          if (step.assetRef != null) _TimelineBarMetaText(step.assetRef!),
          if (diagnostics.isNotEmpty)
            _TimelineBarMetaText('${diagnostics.length} diagnostic(s)'),
          if (selected) const _TimelineBarMetaText('Sélectionné'),
        ],
      ),
    );
  }
}

class _TimelineBarMetaText extends StatelessWidget {
  const _TimelineBarMetaText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: DefaultTextStyle.of(context).style.copyWith(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _EmptyTimelineState extends StatelessWidget {
  const _EmptyTimelineState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SectionTitle(
          title: 'Timeline vide',
          subtitle: 'Timeline par pistes',
        ),
        SizedBox(height: 10),
        _BodyText('Cette cinématique ne contient encore aucun bloc.'),
        SizedBox(height: 4),
        _MutedText('La construction de timeline arrive dans un lot futur.'),
      ],
    );
  }
}

class _InspectorPlaceholder extends StatelessWidget {
  const _InspectorPlaceholder({
    required this.entry,
    required this.asset,
    required this.selectedStep,
    required this.selectedStepIndex,
    required this.onRemoveDraftStep,
    required this.onUpdateBasicBlock,
    required this.onUpdateActorFacing,
    required this.onUpdateActorMove,
    required this.onRemoveAuthoringStep,
  });

  final CinematicsLibraryEntry entry;
  final CinematicAsset asset;
  final CinematicTimelineStep? selectedStep;
  final int? selectedStepIndex;
  final ValueChanged<CinematicTimelineStep> onRemoveDraftStep;
  final _UpdateBasicBlockCallback onUpdateBasicBlock;
  final _UpdateActorFacingCallback onUpdateActorFacing;
  final _UpdateActorMoveCallback onUpdateActorMove;
  final _RemoveAuthoringStepCallback onRemoveAuthoringStep;

  @override
  Widget build(BuildContext context) {
    final selected = selectedStep;
    final selectedIndex = selectedStepIndex;
    return PokeMapPanel(
      key: const ValueKey('cinematic-builder-inspector-placeholder'),
      expandChild: true,
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle(
              title: 'Inspecteur',
              subtitle: 'Bloc sélectionné',
            ),
            const SizedBox(height: 10),
            if (selected == null || selectedIndex == null)
              const _EmptySelectionCard()
            else
              _SelectedStepInspector(
                asset: asset,
                step: selected,
                index: selectedIndex,
                onRemoveDraftStep: onRemoveDraftStep,
                onUpdateBasicBlock: onUpdateBasicBlock,
                onUpdateActorFacing: onUpdateActorFacing,
                onUpdateActorMove: onUpdateActorMove,
                onRemoveAuthoringStep: onRemoveAuthoringStep,
              ),
            const SizedBox(height: 12),
            const _SectionTitle(
              title: 'Métadonnées',
              subtitle: 'Lecture seule',
            ),
            const SizedBox(height: 8),
            _KeyValue(label: 'Titre', value: entry.title),
            _KeyValue(label: 'Id', value: entry.id),
            _KeyValue(
              label: 'Description',
              value: entry.description?.isEmpty ?? true
                  ? 'Aucune description'
                  : entry.description!,
            ),
            _KeyValue(label: 'Map', value: entry.mapId ?? 'Aucune map'),
            _KeyValue(
              label: 'Acteurs',
              value: entry.requiredActors.isEmpty
                  ? 'Aucun acteur requis'
                  : entry.requiredActors
                      .map((actor) => actor.displayLabel)
                      .join(', '),
            ),
            _KeyValue(
              label: 'Timeline',
              value: '${entry.timeline.stepCount} step(s)',
            ),
            _KeyValue(label: 'Durée', value: _durationLabel(entry.timeline)),
            _KeyValue(
              label: 'Usages',
              value: entry.usages.isEmpty
                  ? 'Aucun usage'
                  : entry.usages.map((usage) => usage.sceneTitle).join(', '),
            ),
            const SizedBox(height: 8),
            _DiagnosticsSummary(
              entry: entry,
              selectedStepId: selected?.id,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedStepInspector extends StatelessWidget {
  const _SelectedStepInspector({
    required this.asset,
    required this.step,
    required this.index,
    required this.onRemoveDraftStep,
    required this.onUpdateBasicBlock,
    required this.onUpdateActorFacing,
    required this.onUpdateActorMove,
    required this.onRemoveAuthoringStep,
  });

  final CinematicAsset asset;
  final CinematicTimelineStep step;
  final int index;
  final ValueChanged<CinematicTimelineStep> onRemoveDraftStep;
  final _UpdateBasicBlockCallback onUpdateBasicBlock;
  final _UpdateActorFacingCallback onUpdateActorFacing;
  final _UpdateActorMoveCallback onUpdateActorMove;
  final _RemoveAuthoringStepCallback onRemoveAuthoringStep;

  @override
  Widget build(BuildContext context) {
    final diagnostics = _stepDiagnostics(asset, step);
    final isDraft = isCinematicTimelineDraftStep(step);
    final basicBlockKind = cinematicTimelineBasicBlockKindOf(step);
    final isActorFacing = isCinematicTimelineActorFacingStep(step);
    final isActorMove = isCinematicTimelineActorMoveStep(step);
    final isAuthoringOwned = isCinematicTimelineAuthoringStep(step);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          title: 'Bloc sélectionné',
          subtitle: step.id,
        ),
        const SizedBox(height: 8),
        _KeyValue(label: 'Titre', value: _stepDisplayTitle(asset, step, index)),
        _KeyValue(label: 'Id', value: step.id),
        _KeyValue(label: 'Index', value: '${index + 1}'),
        _KeyValue(label: 'Kind', value: step.kind.name),
        _KeyValue(label: 'Durée', value: _stepDurationLabel(step)),
        _KeyValue(
          label: 'Acteur',
          value: step.actorId == null
              ? 'Aucun acteur'
              : _actorDisplayLabelForId(asset, step.actorId!),
        ),
        _KeyValue(
          label: 'Cible',
          value: step.targetId == null
              ? 'Aucune cible'
              : _movementTargetLabelForId(asset, step.targetId!),
        ),
        _KeyValue(
          label: 'Dialogue',
          value: step.dialogueText ?? 'Aucun texte cinematic',
        ),
        _KeyValue(label: 'Asset', value: step.assetRef ?? 'Aucun assetRef'),
        _KeyValue(label: 'Metadata', value: _metadataLabel(step.metadata)),
        if (basicBlockKind != null) ...[
          const _KeyValue(
            label: 'Statut',
            value: 'Bloc authoring V0',
          ),
          _BasicBlockControls(
            step: step,
            blockKind: basicBlockKind,
            onUpdateBasicBlock: onUpdateBasicBlock,
          ),
          const SizedBox(height: 8),
        ],
        if (isActorFacing) ...[
          const _KeyValue(
            label: 'Statut',
            value: 'Bloc authoring V0',
          ),
          _ActorFacingControls(
            asset: asset,
            step: step,
            onUpdateActorFacing: onUpdateActorFacing,
          ),
          const SizedBox(height: 8),
        ],
        if (isActorMove) ...[
          const _KeyValue(
            label: 'Statut',
            value: 'Bloc authoring V0',
          ),
          _KeyValue(label: 'Résumé', value: _actorMoveSummary(asset, step)),
          _ActorMoveControls(
            asset: asset,
            step: step,
            onUpdateActorMove: onUpdateActorMove,
          ),
          const SizedBox(height: 8),
        ],
        if (isDraft) ...[
          const _KeyValue(
            label: 'Statut',
            value: 'Placeholder authoring',
          ),
          const _BodyText(
            'Ce bloc est un placeholder authoring. '
            'Les vrais blocs arrivent dans un lot futur.',
          ),
          const SizedBox(height: 8),
        ],
        if (isAuthoringOwned) ...[
          PokeMapButton(
            key: const ValueKey(
              'cinematic-builder-remove-authoring-step-button',
            ),
            onPressed: () {
              if (isDraft) {
                onRemoveDraftStep(step);
              } else {
                onRemoveAuthoringStep(step);
              }
            },
            variant: PokeMapButtonVariant.danger,
            size: PokeMapButtonSize.small,
            leading: const Icon(CupertinoIcons.trash),
            child: const SizedBox.shrink(),
          ),
          const SizedBox(height: 4),
          _MutedText(
            isDraft ? 'Supprimer ce brouillon' : 'Supprimer ce bloc',
          ),
          const SizedBox(height: 8),
        ],
        const _KeyValue(
          label: 'Preview',
          value: 'Preview réelle à venir.',
        ),
        const _KeyValue(
          label: 'Statut runtime',
          value: 'Lecture read-only dans ce lot.',
        ),
        const SizedBox(height: 8),
        _StepDiagnosticsSummary(diagnostics: diagnostics),
      ],
    );
  }
}

class _StepDiagnosticsSummary extends StatelessWidget {
  const _StepDiagnosticsSummary({required this.diagnostics});

  final List<CinematicDiagnostic> diagnostics;

  @override
  Widget build(BuildContext context) {
    if (diagnostics.isEmpty) {
      return const PokeMapBadge(
        label: 'Bloc OK',
        variant: PokeMapBadgeVariant.success,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(
          title: 'Diagnostics',
          subtitle: 'Contexte du bloc',
        ),
        const SizedBox(height: 8),
        for (final diagnostic in diagnostics) ...[
          PokeMapBadge(
            label: _diagnosticSeverityLabel(diagnostic.severity),
            variant: _diagnosticVariant(diagnostic.severity),
          ),
          const SizedBox(height: 6),
          _KeyValue(label: 'Code', value: diagnostic.code.name),
          _MutedText(diagnostic.message),
          const SizedBox(height: 4),
          const _MutedText('Aucune action de correction dans ce lot.'),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _BasicBlockControls extends StatelessWidget {
  const _BasicBlockControls({
    required this.step,
    required this.blockKind,
    required this.onUpdateBasicBlock,
  });

  final CinematicTimelineStep step;
  final CinematicTimelineBasicBlockKind blockKind;
  final _UpdateBasicBlockCallback onUpdateBasicBlock;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const _SectionTitle(
          title: 'Paramètres V0',
          subtitle: 'Contrôles bornés',
        ),
        const SizedBox(height: 8),
        _KeyValue(label: 'Bloc', value: _basicBlockLabel(blockKind)),
        _DurationPresetControls(
          step: step,
          onUpdateBasicBlock: onUpdateBasicBlock,
        ),
        if (blockKind == CinematicTimelineBasicBlockKind.fade) ...[
          const SizedBox(height: 8),
          _FadeModeControls(
            step: step,
            onUpdateBasicBlock: onUpdateBasicBlock,
          ),
        ],
        if (blockKind == CinematicTimelineBasicBlockKind.camera) ...[
          const SizedBox(height: 8),
          _CameraModeControls(
            step: step,
            onUpdateBasicBlock: onUpdateBasicBlock,
          ),
        ],
      ],
    );
  }
}

class _DurationPresetControls extends StatelessWidget {
  const _DurationPresetControls({
    required this.step,
    required this.onUpdateBasicBlock,
  });

  final CinematicTimelineStep step;
  final _UpdateBasicBlockCallback onUpdateBasicBlock;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _KeyValue(label: 'Durée', value: 'Presets no-code'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final preset in _durationPresetsMs)
              _InlineControlAction(
                label: '$preset ms',
                button: PokeMapButton(
                  key: ValueKey('cinematic-builder-duration-preset-$preset'),
                  onPressed: () {
                    onUpdateBasicBlock(step, durationMs: preset);
                  },
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  isSelected: step.durationMs == preset,
                  leading: const Icon(CupertinoIcons.clock),
                  child: const SizedBox.shrink(),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _FadeModeControls extends StatelessWidget {
  const _FadeModeControls({
    required this.step,
    required this.onUpdateBasicBlock,
  });

  final CinematicTimelineStep step;
  final _UpdateBasicBlockCallback onUpdateBasicBlock;

  @override
  Widget build(BuildContext context) {
    final currentMode = step.metadata[cinematicTimelineFadeModeMetadataKey];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _KeyValue(label: 'Mode fondu', value: 'Entrant ou sortant'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final mode in CinematicTimelineFadeMode.values)
              _InlineControlAction(
                label: _fadeModeLabel(mode),
                button: PokeMapButton(
                  key: ValueKey('cinematic-builder-fade-mode-${mode.name}'),
                  onPressed: () {
                    onUpdateBasicBlock(step, fadeMode: mode);
                  },
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  isSelected: currentMode == mode.name,
                  leading: const Icon(CupertinoIcons.layers_alt),
                  child: const SizedBox.shrink(),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CameraModeControls extends StatelessWidget {
  const _CameraModeControls({
    required this.step,
    required this.onUpdateBasicBlock,
  });

  final CinematicTimelineStep step;
  final _UpdateBasicBlockCallback onUpdateBasicBlock;

  @override
  Widget build(BuildContext context) {
    final currentMode = step.metadata[cinematicTimelineCameraModeMetadataKey];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _KeyValue(label: 'Mode caméra', value: 'Basique uniquement'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final mode in CinematicTimelineCameraMode.values)
              _InlineControlAction(
                label: _cameraModeLabel(mode),
                button: PokeMapButton(
                  key: ValueKey('cinematic-builder-camera-mode-${mode.name}'),
                  onPressed: () {
                    onUpdateBasicBlock(step, cameraMode: mode);
                  },
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  isSelected: currentMode == mode.name,
                  leading: const Icon(CupertinoIcons.video_camera),
                  child: const SizedBox.shrink(),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ActorFacingControls extends StatelessWidget {
  const _ActorFacingControls({
    required this.asset,
    required this.step,
    required this.onUpdateActorFacing,
  });

  final CinematicAsset asset;
  final CinematicTimelineStep step;
  final _UpdateActorFacingCallback onUpdateActorFacing;

  @override
  Widget build(BuildContext context) {
    final currentDirection = cinematicTimelineActorFacingDirectionOf(step);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const _SectionTitle(
          title: 'Acteur',
          subtitle: 'Picker requis',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final actor in asset.requiredActors)
              _InlineControlAction(
                label: _actorDisplayLabel(actor),
                button: PokeMapButton(
                  key: ValueKey(
                    'cinematic-builder-actor-picker-${actor.actorId}',
                  ),
                  onPressed: () {
                    onUpdateActorFacing(step, actorId: actor.actorId);
                  },
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  isSelected: step.actorId == actor.actorId,
                  leading: const Icon(CupertinoIcons.person_crop_circle),
                  child: const SizedBox.shrink(),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const _KeyValue(label: 'Direction', value: 'Haut, bas, gauche, droite'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final direction
                in CinematicTimelineActorFacingDirection.values)
              _InlineControlAction(
                label: _actorDirectionLabel(direction),
                button: PokeMapButton(
                  key: ValueKey(
                    'cinematic-builder-actor-direction-${direction.name}',
                  ),
                  onPressed: () {
                    onUpdateActorFacing(step, direction: direction);
                  },
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  isSelected: currentDirection == direction,
                  leading: Icon(_actorDirectionIcon(direction)),
                  child: const SizedBox.shrink(),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ActorMoveControls extends StatelessWidget {
  const _ActorMoveControls({
    required this.asset,
    required this.step,
    required this.onUpdateActorMove,
  });

  final CinematicAsset asset;
  final CinematicTimelineStep step;
  final _UpdateActorMoveCallback onUpdateActorMove;

  @override
  Widget build(BuildContext context) {
    final currentMovementMode = cinematicTimelineActorMovementModeOf(step);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const _KeyValue(
          label: 'Chemin direct verrouillé',
          value: 'Le chemin direct est un contrat authoring V0.',
        ),
        const _KeyValue(
          label: 'Intention',
          value: 'Intention visuelle, sans vitesse runtime.',
        ),
        const SizedBox(height: 8),
        const _KeyValue(label: 'Mode mouvement', value: 'Marche ou course'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final mode in CinematicTimelineActorMovementMode.values)
              _InlineControlAction(
                label: _actorMovementModeLabel(mode),
                button: PokeMapButton(
                  key: ValueKey(
                    'cinematic-builder-actor-move-mode-${mode.name}',
                  ),
                  onPressed: () {
                    onUpdateActorMove(step, movementMode: mode);
                  },
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  isSelected: currentMovementMode == mode,
                  leading: Icon(_actorMovementModeIcon(mode)),
                  child: const SizedBox.shrink(),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const _SectionTitle(
          title: 'Acteur',
          subtitle: 'Picker requis',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final actor in asset.requiredActors)
              _InlineControlAction(
                label: _actorDisplayLabel(actor),
                button: PokeMapButton(
                  key: ValueKey(
                    'cinematic-builder-actor-picker-${actor.actorId}',
                  ),
                  onPressed: () {
                    onUpdateActorMove(step, actorId: actor.actorId);
                  },
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  isSelected: step.actorId == actor.actorId,
                  leading: const Icon(CupertinoIcons.person_crop_circle),
                  child: const SizedBox.shrink(),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const _SectionTitle(
          title: 'Cible',
          subtitle: 'Picker label + id stable',
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final target in asset.movementTargets)
              _InlineControlAction(
                label: target.label,
                button: PokeMapButton(
                  key: ValueKey(
                    'cinematic-builder-target-picker-${target.targetId}',
                  ),
                  onPressed: () {
                    onUpdateActorMove(step, targetId: target.targetId);
                  },
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  isSelected: step.targetId == target.targetId,
                  leading: const Icon(CupertinoIcons.location),
                  child: const SizedBox.shrink(),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const _KeyValue(label: 'Durée', value: 'Presets no-code'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final preset in _durationPresetsMs)
              _InlineControlAction(
                label: '$preset ms',
                button: PokeMapButton(
                  key: ValueKey(
                    'cinematic-builder-actor-move-duration-preset-$preset',
                  ),
                  onPressed: () {
                    onUpdateActorMove(step, durationMs: preset);
                  },
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  isSelected: step.durationMs == preset,
                  leading: const Icon(CupertinoIcons.clock),
                  child: const SizedBox.shrink(),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _InlineControlAction extends StatelessWidget {
  const _InlineControlAction({
    required this.label,
    required this.button,
  });

  final String label;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        const SizedBox(width: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DefaultTextStyle.of(context).style.copyWith(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _EmptySelectionCard extends StatelessWidget {
  const _EmptySelectionCard();

  @override
  Widget build(BuildContext context) {
    return const PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StrongText('Aucun bloc sélectionné'),
          SizedBox(height: 4),
          _MutedText('Sélection de bloc à venir'),
          SizedBox(height: 4),
          _MutedText('Sélectionnez un bloc existant dans le déroulé.'),
        ],
      ),
    );
  }
}

class _DiagnosticsSummary extends StatelessWidget {
  const _DiagnosticsSummary({
    required this.entry,
    required this.selectedStepId,
  });

  final CinematicsLibraryEntry entry;
  final String? selectedStepId;

  @override
  Widget build(BuildContext context) {
    final diagnostics = entry.diagnostics
        .where((diagnostic) => diagnostic.sourceId != selectedStepId)
        .toList(growable: false);
    if (diagnostics.isEmpty) {
      return const PokeMapBadge(
        label: 'Aucun diagnostic',
        variant: PokeMapBadgeVariant.success,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final diagnostic in diagnostics) ...[
          PokeMapBadge(
            label: _libraryDiagnosticSeverityLabel(diagnostic.severity),
            variant: switch (diagnostic.severity) {
              CinematicsLibraryDiagnosticSeverity.error =>
                PokeMapBadgeVariant.error,
              CinematicsLibraryDiagnosticSeverity.warning =>
                PokeMapBadgeVariant.warning,
              CinematicsLibraryDiagnosticSeverity.info =>
                PokeMapBadgeVariant.info,
            },
          ),
          const SizedBox(height: 6),
          _KeyValue(label: 'Code', value: diagnostic.code),
          _MutedText(diagnostic.message),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DefaultTextStyle.of(context).style.copyWith(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: DefaultTextStyle.of(context).style.copyWith(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DefaultTextStyle.of(context).style.copyWith(
                  color: colors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: DefaultTextStyle.of(context).style.copyWith(
                  color: colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _StrongText extends StatelessWidget {
  const _StrongText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Text(
      value,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: DefaultTextStyle.of(context).style.copyWith(
            color: colors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Text(
      value,
      style: DefaultTextStyle.of(context).style.copyWith(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Text(
      value,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: DefaultTextStyle.of(context).style.copyWith(
            color: colors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _PaletteBlock {
  const _PaletteBlock({
    required this.label,
    required this.icon,
    required this.description,
    this.blockKind,
  });

  final String label;
  final IconData icon;
  final String description;
  final CinematicTimelineBasicBlockKind? blockKind;
}

const _paletteBlocks = [
  _PaletteBlock(
    label: 'Attente',
    icon: CupertinoIcons.timer,
    description: 'Durée par preset.',
    blockKind: CinematicTimelineBasicBlockKind.wait,
  ),
  _PaletteBlock(
    label: 'Fondu',
    icon: CupertinoIcons.layers_alt,
    description: 'Entrant/sortant V0.',
    blockKind: CinematicTimelineBasicBlockKind.fade,
  ),
  _PaletteBlock(
    label: 'Caméra',
    icon: CupertinoIcons.video_camera,
    description: 'Reset/hold basique.',
    blockKind: CinematicTimelineBasicBlockKind.camera,
  ),
];

const _lockedPaletteBlocks = [
  _PaletteBlock(
    label: 'Dialogue',
    icon: CupertinoIcons.text_bubble,
    description: 'Non authorable dans ce lot.',
  ),
  _PaletteBlock(
    label: 'FX',
    icon: CupertinoIcons.sparkles,
    description: 'Non authorable dans ce lot.',
  ),
  _PaletteBlock(
    label: 'Son',
    icon: CupertinoIcons.speaker_2,
    description: 'Non authorable dans ce lot.',
  ),
];

const _durationPresetsMs = [500, 1000, 1500, 2000, 3000];

String _durationLabel(CinematicTimelineSummary timeline) {
  final duration = timeline.estimatedDurationMs;
  return duration == null ? 'Durée non calculable' : '$duration ms estimé(s)';
}

String _timelineTotalLabel(int totalDurationMs) {
  if (totalDurationMs <= 0) {
    return '0 ms dérivé';
  }
  return '${_shortTimeLabel(totalDurationMs)} dérivé';
}

String _shortTimeLabel(int durationMs) {
  if (durationMs < 1000) {
    return '$durationMs ms';
  }
  if (durationMs % 1000 == 0) {
    return '${durationMs ~/ 1000} s';
  }
  final decimals = durationMs % 100 == 0 ? 1 : 2;
  var seconds = (durationMs / 1000).toStringAsFixed(decimals);
  while (seconds.endsWith('0')) {
    seconds = seconds.substring(0, seconds.length - 1);
  }
  if (seconds.endsWith('.')) {
    seconds = seconds.substring(0, seconds.length - 1);
  }
  return '$seconds s';
}

double _timelineContentWidth(int totalDurationMs, double viewportWidth) {
  if (totalDurationMs <= 0) {
    return viewportWidth;
  }
  return math.max(
    viewportWidth,
    totalDurationMs * _timelineFallbackPixelsPerMs,
  );
}

double _tickLeft(int timeMs, double pixelsPerMs, double contentWidth) {
  return math.max(0, math.min(timeMs * pixelsPerMs, contentWidth - 1));
}

String _blockDurationBadgeLabel(CinematicTimelineTimeBlock block) {
  if (block.durationSource == CinematicTimelineVisualDurationSource.fallback) {
    return '${block.visualDurationMs} ms visuel';
  }
  return '${block.visualDurationMs} ms';
}

bool _hasStep(CinematicAsset asset, String? stepId) {
  if (stepId == null) {
    return true;
  }
  return asset.timeline.steps.any((step) => step.id == stepId);
}

CinematicTimelineStep? _selectedStep(CinematicAsset asset, String? stepId) {
  if (stepId == null) {
    return null;
  }
  for (final step in asset.timeline.steps) {
    if (step.id == stepId) {
      return step;
    }
  }
  return null;
}

String _stepTitle(CinematicTimelineStep step, int index) {
  final label = step.label;
  if (label != null && label.trim().isNotEmpty) {
    return label;
  }
  return 'Step ${index + 1}';
}

String _stepDisplayTitle(
  CinematicAsset asset,
  CinematicTimelineStep step,
  int index,
) {
  if (isCinematicTimelineActorMoveStep(step) &&
      step.actorId != null &&
      step.targetId != null) {
    return '${_actorDisplayLabelForId(asset, step.actorId!)} → '
        '${_movementTargetLabelForId(asset, step.targetId!)}';
  }
  return _stepTitle(step, index);
}

String _actorMoveSummary(CinematicAsset asset, CinematicTimelineStep step) {
  final actor = step.actorId == null
      ? 'Acteur'
      : _actorDisplayLabelForId(asset, step.actorId!);
  final target = step.targetId == null
      ? 'cible non définie'
      : _movementTargetLabelForId(asset, step.targetId!);
  final movementMode = cinematicTimelineActorMovementModeOf(step);
  final duration = step.durationMs == null
      ? 'durée non renseignée'
      : '${step.durationMs} ms';
  return '$actor ${_actorMovementVerb(movementMode)} vers $target en '
      '$duration.';
}

String _actorMovementVerb(CinematicTimelineActorMovementMode? mode) {
  return switch (mode) {
    CinematicTimelineActorMovementMode.walk => 'marche',
    CinematicTimelineActorMovementMode.run => 'court',
    null => 'se déplace',
  };
}

String _stepDurationLabel(CinematicTimelineStep step) {
  final duration = step.durationMs;
  return duration == null ? 'Durée non renseignée' : '$duration ms';
}

String _metadataLabel(Map<String, String> metadata) {
  if (metadata.isEmpty) {
    return 'Aucune metadata';
  }
  final entries = metadata.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return entries.map((entry) => '${entry.key} = ${entry.value}').join(', ');
}

String _basicBlockLabel(CinematicTimelineBasicBlockKind blockKind) {
  return switch (blockKind) {
    CinematicTimelineBasicBlockKind.wait => 'Attente',
    CinematicTimelineBasicBlockKind.fade => 'Fondu',
    CinematicTimelineBasicBlockKind.camera => 'Caméra basique',
  };
}

String _fadeModeLabel(CinematicTimelineFadeMode mode) {
  return switch (mode) {
    CinematicTimelineFadeMode.fadeIn => 'Entrant',
    CinematicTimelineFadeMode.fadeOut => 'Sortant',
  };
}

String _cameraModeLabel(CinematicTimelineCameraMode mode) {
  return switch (mode) {
    CinematicTimelineCameraMode.reset => 'Reset',
    CinematicTimelineCameraMode.hold => 'Hold',
  };
}

String _actorDisplayLabel(CinematicActorRef actor) {
  return actor.label ?? actor.actorId;
}

String _actorDisplayLabelForId(CinematicAsset asset, String actorId) {
  for (final actor in asset.requiredActors) {
    if (actor.actorId == actorId) {
      return _actorDisplayLabel(actor);
    }
  }
  return actorId;
}

String _movementTargetLabelForId(CinematicAsset asset, String targetId) {
  for (final target in asset.movementTargets) {
    if (target.targetId == targetId) {
      return target.label;
    }
  }
  return targetId;
}

String _movementTargetBadgeLabel(CinematicAsset asset, String targetId) {
  final label = _movementTargetLabelForId(asset, targetId);
  if (label.length <= 12) {
    return 'Cible: $label';
  }
  return 'Cible: ${label.substring(0, 10)}...';
}

int _movementTargetUsageCount(CinematicAsset asset, String targetId) {
  return asset.timeline.steps
      .where(
        (step) =>
            step.kind == CinematicTimelineStepKind.actorMove &&
            step.targetId == targetId,
      )
      .length;
}

String _actorDirectionLabel(CinematicTimelineActorFacingDirection? direction) {
  return switch (direction) {
    CinematicTimelineActorFacingDirection.up => 'Haut',
    CinematicTimelineActorFacingDirection.down => 'Bas',
    CinematicTimelineActorFacingDirection.left => 'Gauche',
    CinematicTimelineActorFacingDirection.right => 'Droite',
    null => 'Direction inconnue',
  };
}

String _actorMovementModeLabel(CinematicTimelineActorMovementMode mode) {
  return switch (mode) {
    CinematicTimelineActorMovementMode.walk => 'Marche',
    CinematicTimelineActorMovementMode.run => 'Course',
  };
}

String _actorPathModeLabel(CinematicTimelineActorPathMode mode) {
  return switch (mode) {
    CinematicTimelineActorPathMode.direct => 'Direct',
  };
}

IconData _actorDirectionIcon(CinematicTimelineActorFacingDirection direction) {
  return switch (direction) {
    CinematicTimelineActorFacingDirection.up => CupertinoIcons.arrow_up,
    CinematicTimelineActorFacingDirection.down => CupertinoIcons.arrow_down,
    CinematicTimelineActorFacingDirection.left => CupertinoIcons.arrow_left,
    CinematicTimelineActorFacingDirection.right => CupertinoIcons.arrow_right,
  };
}

IconData _actorMovementModeIcon(CinematicTimelineActorMovementMode mode) {
  return switch (mode) {
    CinematicTimelineActorMovementMode.walk => CupertinoIcons.arrow_right,
    CinematicTimelineActorMovementMode.run => CupertinoIcons.forward,
  };
}

IconData _stepIcon(CinematicTimelineStepKind kind) {
  return switch (kind) {
    CinematicTimelineStepKind.camera => CupertinoIcons.video_camera,
    CinematicTimelineStepKind.actorMove => CupertinoIcons.arrow_right,
    CinematicTimelineStepKind.actorFace => CupertinoIcons.arrow_turn_up_right,
    CinematicTimelineStepKind.actorEmote => CupertinoIcons.person_crop_circle,
    CinematicTimelineStepKind.dialogueLine => CupertinoIcons.text_bubble,
    CinematicTimelineStepKind.sound => CupertinoIcons.speaker_2,
    CinematicTimelineStepKind.music => CupertinoIcons.music_note_2,
    CinematicTimelineStepKind.fade => CupertinoIcons.layers_alt,
    CinematicTimelineStepKind.shake => CupertinoIcons.waveform_path,
    CinematicTimelineStepKind.fx => CupertinoIcons.sparkles,
    CinematicTimelineStepKind.wait => CupertinoIcons.timer,
    CinematicTimelineStepKind.marker => CupertinoIcons.flag,
  };
}

IconData _laneIcon(CinematicTimelineLaneKind laneKind) {
  return switch (laneKind) {
    CinematicTimelineLaneKind.camera => CupertinoIcons.video_camera,
    CinematicTimelineLaneKind.actor => CupertinoIcons.person_crop_square,
    CinematicTimelineLaneKind.dialogue => CupertinoIcons.text_bubble,
    CinematicTimelineLaneKind.fx => CupertinoIcons.sparkles,
    CinematicTimelineLaneKind.audio => CupertinoIcons.speaker_2,
    CinematicTimelineLaneKind.transitions => CupertinoIcons.layers_alt,
    CinematicTimelineLaneKind.timeGlobal => CupertinoIcons.timer,
    CinematicTimelineLaneKind.other => CupertinoIcons.question_circle,
  };
}

List<CinematicDiagnostic> _stepDiagnostics(
  CinematicAsset asset,
  CinematicTimelineStep step,
) {
  return diagnoseCinematicAsset(asset)
      .diagnostics
      .where((diagnostic) => diagnostic.stepId == step.id)
      .toList(growable: false);
}

PokeMapBadgeVariant _diagnosticVariant(CinematicDiagnosticSeverity severity) {
  return switch (severity) {
    CinematicDiagnosticSeverity.error => PokeMapBadgeVariant.error,
    CinematicDiagnosticSeverity.warning => PokeMapBadgeVariant.warning,
    CinematicDiagnosticSeverity.info => PokeMapBadgeVariant.info,
  };
}

PokeMapTone _laneTone(CinematicTimelineLaneKind laneKind) {
  return switch (laneKind) {
    CinematicTimelineLaneKind.camera => PokeMapTone.cinematic,
    CinematicTimelineLaneKind.actor => PokeMapTone.narrative,
    CinematicTimelineLaneKind.dialogue => PokeMapTone.dialogue,
    CinematicTimelineLaneKind.fx => PokeMapTone.warning,
    CinematicTimelineLaneKind.audio => PokeMapTone.info,
    CinematicTimelineLaneKind.transitions => PokeMapTone.neutral,
    CinematicTimelineLaneKind.timeGlobal => PokeMapTone.success,
    CinematicTimelineLaneKind.other => PokeMapTone.neutral,
  };
}

PokeMapTone _blockTone(CinematicTimelineStepKind kind) {
  return switch (kind) {
    CinematicTimelineStepKind.camera => PokeMapTone.cinematic,
    CinematicTimelineStepKind.actorMove ||
    CinematicTimelineStepKind.actorFace ||
    CinematicTimelineStepKind.actorEmote =>
      PokeMapTone.narrative,
    CinematicTimelineStepKind.dialogueLine => PokeMapTone.dialogue,
    CinematicTimelineStepKind.fx ||
    CinematicTimelineStepKind.shake =>
      PokeMapTone.warning,
    CinematicTimelineStepKind.sound ||
    CinematicTimelineStepKind.music =>
      PokeMapTone.info,
    CinematicTimelineStepKind.fade => PokeMapTone.neutral,
    CinematicTimelineStepKind.wait => PokeMapTone.success,
    CinematicTimelineStepKind.marker => PokeMapTone.neutral,
  };
}

String _diagnosticSeverityLabel(CinematicDiagnosticSeverity severity) {
  return switch (severity) {
    CinematicDiagnosticSeverity.error => 'Erreur',
    CinematicDiagnosticSeverity.warning => 'Attention',
    CinematicDiagnosticSeverity.info => 'Info',
  };
}

String _libraryDiagnosticSeverityLabel(
  CinematicsLibraryDiagnosticSeverity severity,
) {
  return switch (severity) {
    CinematicsLibraryDiagnosticSeverity.error => 'Erreur',
    CinematicsLibraryDiagnosticSeverity.warning => 'Attention',
    CinematicsLibraryDiagnosticSeverity.info => 'Info',
  };
}
