part of 'project_character_animation_editor.dart';

extension _CharacterAnimationLayout on _ProjectCharacterAnimationEditorState {
  Widget _buildEditor(BuildContext context) {
    final preview = _previewCharacter;
    final atlas = _poseAtlas;
    return CallbackShortcuts(
      bindings: {
        if (_canSave) ...{
          const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _save,
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
        },
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ProjectCharacterWorkspaceLayout(
              sidebar: _animationSidebar(context),
              compactSelector: _animationPicker(),
              content: LayoutBuilder(
                builder: (context, bounds) {
                  final main = _animationStage(context, preview, atlas);
                  final settings = _animationSettings(context, atlas);
                  if (bounds.maxWidth < 600) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        main,
                        const SizedBox(height: StudioSpacing.l),
                        settings,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: main),
                      const SizedBox(width: StudioSpacing.l),
                      SizedBox(width: 220, child: settings),
                    ],
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1),
          _saveBar(),
        ],
      ),
    );
  }

  Widget _animationStage(
    BuildContext context,
    ProjectCharacterEntry preview,
    ProjectRegularAtlasTilesetSource? atlas,
  ) => StudioPanel(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              _custom?.displayName ?? characterAnimationLabel(_state),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (_poses.isNotEmpty || atlas != null)
            StudioContextMenuButton(
              tooltip: 'Actions de l’animation',
              items: () => [
                StudioContextMenuEntry(
                  label: _poses.isEmpty
                      ? 'Importer une planche PNG'
                      : 'Importer une autre planche PNG',
                  icon: Icons.upload_file_outlined,
                  onSelected: _canNavigate ? _import : null,
                ),
              ],
            ),
        ],
      ),
      if (!_single) ...[
        const SizedBox(height: StudioSpacing.m),
        StudioTabBar(
          selected: _facing,
          height: StudioMetrics.controlHeight,
          tabs: [
            for (final direction in _workshopDirections)
              StudioTab(
                value: direction,
                label: characterFacingLabel(direction),
                enabled: _canNavigate || _facing == direction,
                key: ValueKey('character-direction-${direction.name}'),
              ),
          ],
          onSelected: _selectDirection,
        ),
      ],
      const SizedBox(height: StudioSpacing.l),
      if (_problem case final problem?) StudioNotice(problem, isError: true),
      if (_poses.isEmpty)
        StudioAssetPreview(
          height: 250,
          child: StudioEmptyState(
            title: 'Aucune pose pour cette animation',
            description: atlas == null
                ? 'Importez une planche PNG pour commencer.'
                : 'Choisissez une image dans la planche du personnage.',
            action: StudioButton(
              label: atlas == null
                  ? 'Importer une planche PNG'
                  : 'Choisir une pose',
              icon: atlas == null ? Icons.upload_file_outlined : Icons.add,
              onPressed: atlas == null
                  ? (_canNavigate ? _import : null)
                  : (widget.enabled ? () => _choosePose(0, atlas) : null),
            ),
          ),
        )
      else ...[
        ProjectCharacterWorkshopPreview(
          key: ValueKey((_selection, _facing, _position)),
          character: preview,
          project: widget.project,
          visuals: widget.visuals,
          active: widget.enabled,
          showSelectors: false,
          initialElapsedMs: _poses
              .take(_position)
              .fold(0, (time, pose) => time + pose.durationMs),
        ),
        const SizedBox(height: StudioSpacing.l),
        _timeline(context, preview, atlas),
      ],
    ],
  );

  Widget _animationSettings(
    BuildContext context,
    ProjectRegularAtlasTilesetSource? atlas,
  ) {
    final pose = _poses.elementAtOrNull(_position);
    final text = Theme.of(context).textTheme;
    return StudioPanel(
      title: 'Réglages',
      compact: true,
      children: [
        if (pose == null)
          Text(
            'Sélectionnez une pose pour régler sa durée.',
            style: text.bodySmall,
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: Text('Pose ${_position + 1}', style: text.labelLarge),
              ),
              _poseActions(),
            ],
          ),
          const SizedBox(height: StudioSpacing.s),
          StudioDraftField(
            key: const ValueKey('character-pose-duration'),
            label: 'Durée de la pose (ms)',
            value: _invalidDuration ?? pose.durationMs.toString(),
            errorText: _invalidDuration == null ? null : 'Entre 1 et 60 000 ms',
            keyboardType: TextInputType.number,
            onChanged: _setDuration,
            enabled: widget.enabled,
          ),
          if (atlas != null)
            StudioButton(
              label: 'Changer l’image',
              icon: Icons.image_outlined,
              variant: StudioButtonVariant.quiet,
              onPressed: widget.enabled
                  ? () => _choosePose(_position, atlas)
                  : null,
            ),
          const SizedBox(height: StudioSpacing.m),
          const Divider(height: 1),
          StudioToggleRow(
            label: 'Lecture en boucle',
            value: _loop ?? _savedLoop,
            onChanged: widget.enabled ? _setLoop : null,
          ),
        ],
      ],
    );
  }

  Widget _saveBar() => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: StudioSpacing.xl,
      vertical: StudioSpacing.m,
    ),
    child: Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: StudioSpacing.l,
      runSpacing: StudioSpacing.s,
      children: [
        if (_dirty) ...[
          StudioBadge(
            _poses.isEmpty
                ? 'Animation à retirer'
                : 'Modifications à enregistrer',
            tone: StudioTone.warning,
          ),
          StudioButton(
            label: 'Annuler les modifications',
            variant: StudioButtonVariant.quiet,
            onPressed: widget.enabled ? _discard : null,
          ),
        ],
        StudioButton(
          label: 'Enregistrer l’animation',
          icon: Icons.save_outlined,
          onPressed: _canSave ? _save : null,
        ),
      ],
    ),
  );
}
