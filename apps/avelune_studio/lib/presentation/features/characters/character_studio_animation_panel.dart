import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'character_studio_controller.dart';
import '../../../features/characters/application/character_studio_draft.dart';
import '../../shared/widgets/layout/studio_asset_preview.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../map_workspace/map_workspace_visuals.dart';
import 'character_workspace_visuals.dart';
import 'character_studio_source_panel.dart';
import 'character_studio_frame_thumbnail.dart';
import 'character_studio_matrix_actions.dart';

class CharacterStudioAnimationPanel extends StatefulWidget {
  const CharacterStudioAnimationPanel({
    super.key,
    required this.project,
    required this.character,
    required this.draft,
    required this.controller,
    required this.visuals,
    required this.elapsedMs,
    required this.compact,
  });

  final ProjectManifest project;
  final ProjectCharacterEntry character;
  final CharacterStudioDraft draft;
  final CharacterStudioController controller;
  final MapWorkspaceVisuals visuals;
  final int elapsedMs;
  final bool compact;

  @override
  State<CharacterStudioAnimationPanel> createState() =>
      _CharacterStudioAnimationPanelState();
}

class _CharacterStudioAnimationPanelState
    extends State<CharacterStudioAnimationPanel> {
  TilesetSourceRect? _pickedSource;

  ProjectRegularAtlasTilesetSource? get _atlas {
    final source = widget.project.tilesets
        .where((entry) => entry.id == widget.character.tilesetId)
        .firstOrNull
        ?.source;
    final loaded = widget.visuals is CharacterWorkspaceVisuals
        ? (widget.visuals as CharacterWorkspaceVisuals).characterAtlas(
            widget.character,
          )
        : null;
    return loaded ??
        (source is ProjectRegularAtlasTilesetSource ? source : null);
  }

  static const _directions = [
    (EntityFacing.south, 'Bas', Icons.arrow_downward),
    (EntityFacing.west, 'Gauche', Icons.arrow_back),
    (EntityFacing.east, 'Droite', Icons.arrow_forward),
    (EntityFacing.north, 'Haut', Icons.arrow_upward),
  ];

  @override
  Widget build(BuildContext context) {
    final visuals = widget.visuals;
    return visuals is CharacterWorkspaceVisuals
        ? AnimatedBuilder(
            animation: visuals,
            builder: (context, _) => _buildContent(context),
          )
        : _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    final source = _atlas;
    if (source == null) {
      final hasAtlas = widget.project.tilesets.any(
        (entry) => entry.id == widget.character.tilesetId,
      );
      return _surface('Planche indisponible', [
        Text(
          hasAtlas
              ? 'La planche de ce personnage ne peut pas être lue. Les animations existantes sont conservées.'
              : 'Ce personnage utilise des images dédiées. La planche guidée accepte une source de type atlas ; ses animations existantes sont conservées.',
        ),
      ]);
    }
    return widget.compact
        ? ListView(
            children: [
              SizedBox(height: 650, child: _matrix(source)),
              const SizedBox(height: 12),
              SizedBox(height: 600, child: _sourcePanel(source)),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _matrix(source)),
              const SizedBox(width: 12),
              SizedBox(width: 300, child: _sourcePanel(source)),
            ],
          );
  }

  Widget _matrix(ProjectRegularAtlasTilesetSource source) {
    final state = widget.controller.animationState;
    final count = _directions
        .map(
          (direction) => widget.draft.framesFor((state, direction.$1)).length,
        )
        .fold<int>(3, (current, next) => next > current ? next : current);
    return _surface('Planche guidée', [
      Row(
        children: [
          const Expanded(child: Text('Déposez une image dans chaque pose.')),
          DropdownButton<CharacterAnimationState>(
            value: state,
            items: const [
              DropdownMenuItem(
                value: CharacterAnimationState.walk,
                child: Text('Marche'),
              ),
              DropdownMenuItem(
                value: CharacterAnimationState.idle,
                child: Text('Repos'),
              ),
              DropdownMenuItem(
                value: CharacterAnimationState.run,
                child: Text('Course'),
              ),
            ],
            onChanged: (value) {
              if (value != null) widget.controller.setAnimationState(value);
            },
          ),
        ],
      ),
      const SizedBox(height: 8),
      Expanded(
        child: LayoutBuilder(
          builder: (context, bounds) {
            final cellWidth = ((bounds.maxWidth - 84) / count).clamp(
              65.0,
              240.0,
            );
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 84 + count * cellWidth,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 84),
                        for (var index = 0; index < count; index++)
                          SizedBox(
                            width: cellWidth,
                            child: Center(
                              child: Text(index == 0 ? 'Repos' : 'Pas $index'),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        children: [
                          for (final direction in _directions)
                            SizedBox(
                              height: 132,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 84,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(direction.$3, size: 20),
                                        Text(direction.$2),
                                      ],
                                    ),
                                  ),
                                  for (var index = 0; index < count; index++)
                                    SizedBox(
                                      width: cellWidth,
                                      child: _target(direction.$1, index),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 10),
      CharacterStudioMatrixActions(
        project: widget.project,
        character: widget.character,
        source: source,
        draft: widget.draft,
        controller: widget.controller,
      ),
    ]);
  }

  Widget _target(EntityFacing direction, int index) {
    final key = (widget.controller.animationState, direction);
    final frames = widget.draft.framesFor(key);
    final frame = index < frames.length ? frames[index] : null;
    return Padding(
      padding: const EdgeInsets.all(3),
      child: DragTarget<TilesetSourceRect>(
        onAcceptWithDetails: (details) =>
            widget.controller.assign(direction, index, details.data),
        builder: (context, candidates, rejected) => Material(
          color: candidates.isNotEmpty || _pickedSource != null && frame == null
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Tooltip(
            message: frame == null
                ? 'Déposer ou choisir une pose'
                : 'Maintenir pour retirer cette pose',
            child: InkWell(
              key: ValueKey('character-slot-${direction.name}-$index'),
              onTap: _pickedSource == null
                  ? null
                  : () => widget.controller.assign(
                      direction,
                      index,
                      _pickedSource!,
                    ),
              onLongPress: frame == null
                  ? null
                  : () => widget.controller.clear(direction, index),
              child: StudioAssetPreview(
                child: frame == null
                    ? const Icon(Icons.add_photo_alternate_outlined)
                    : _frame(frame, direction, size: 78),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _frame(
    CharacterAnimationFrame frame,
    EntityFacing direction, {
    double size = 56,
    bool sourcePicker = false,
  }) => characterStudioFrameThumbnail(
    visuals: widget.visuals,
    character: widget.draft.previewCharacter,
    frame: frame,
    sourceAssetId: sourcePicker
        ? null
        : widget.draft.sourceAssetIdFor((
            widget.controller.animationState,
            direction,
          )),
    direction: direction,
    state: widget.controller.animationState,
    size: size,
  );
  Widget _sourcePanel(ProjectRegularAtlasTilesetSource source) =>
      CharacterStudioSourcePanel(
        source: source,
        draft: widget.draft,
        controller: widget.controller,
        visuals: widget.visuals,
        elapsedMs: widget.elapsedMs,
        pickedSource: _pickedSource,
        onPick: (value) => setState(() => _pickedSource = value),
        frameBuilder: (frame, direction, size) =>
            _frame(frame, direction, size: size, sourcePicker: true),
      );
  Widget _surface(String title, List<Widget> children) =>
      StudioPanel(title: title, compact: true, children: children);
}
