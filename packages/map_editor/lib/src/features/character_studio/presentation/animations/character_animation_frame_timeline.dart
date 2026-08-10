import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../application/character_animation_source_slicing.dart';

class CharacterAnimationFrameTimeline extends StatelessWidget {
  const CharacterAnimationFrameTimeline({
    super.key,
    required this.frames,
    required this.dimensions,
    required this.enabled,
    required this.onChanged,
  });

  final List<CharacterAnimationFrame> frames;
  final CharacterAnimationSourceDimensions dimensions;
  final bool enabled;
  final ValueChanged<List<CharacterAnimationFrame>> onChanged;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      key: const ValueKey<String>('animation-frame-timeline'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Timeline · ${frames.length} frame${frames.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: context.pokeMapColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              PokeMapIconButton(
                key: const ValueKey<String>('animation-frame-add'),
                onPressed: enabled ? _add : null,
                icon: const Icon(CupertinoIcons.add),
                tooltip: 'Ajouter une frame',
                variant: PokeMapIconButtonVariant.soft,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (frames.isEmpty)
            const PokeMapEmptyState(
              title: 'Aucune frame',
              description: 'Découpez la grille ou ajoutez une première frame.',
              icon: Icon(CupertinoIcons.rectangle_stack_badge_plus),
              compact: true,
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < frames.length; index++) ...[
                    SizedBox(
                      width: 196,
                      child: _FrameCard(
                        key: ValueKey<String>('animation-frame-card-$index'),
                        index: index,
                        frame: frames[index],
                        enabled: enabled,
                        canMoveLeft: index > 0,
                        canMoveRight: index < frames.length - 1,
                        onDuplicate: () => onChanged(
                          CharacterAnimationTimelineEditing.duplicate(
                            frames,
                            index: index,
                            dimensions: dimensions,
                          ),
                        ),
                        onMoveLeft: () => onChanged(
                          CharacterAnimationTimelineEditing.reorder(
                            frames,
                            fromIndex: index,
                            toIndex: index - 1,
                            dimensions: dimensions,
                          ),
                        ),
                        onMoveRight: () => onChanged(
                          CharacterAnimationTimelineEditing.reorder(
                            frames,
                            fromIndex: index,
                            toIndex: index + 1,
                            dimensions: dimensions,
                          ),
                        ),
                        onDelete: () => onChanged(
                          CharacterAnimationTimelineEditing.delete(
                            frames,
                            index: index,
                            dimensions: dimensions,
                          ),
                        ),
                        onDurationChanged: (durationMs) => onChanged(
                          CharacterAnimationTimelineEditing.updateDuration(
                            frames,
                            index: index,
                            durationMs: durationMs,
                            dimensions: dimensions,
                          ),
                        ),
                      ),
                    ),
                    if (index != frames.length - 1) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _add() {
    final frame =
        frames.lastOrNull ??
        CharacterAnimationFrame(
          source: TilesetSourceRect(
            x: 0,
            y: 0,
            width: dimensions.width,
            height: dimensions.height,
          ),
        );
    onChanged(
      CharacterAnimationTimelineEditing.add(
        frames,
        frame: frame,
        dimensions: dimensions,
      ),
    );
  }
}

class _FrameCard extends StatefulWidget {
  const _FrameCard({
    super.key,
    required this.index,
    required this.frame,
    required this.enabled,
    required this.canMoveLeft,
    required this.canMoveRight,
    required this.onDuplicate,
    required this.onMoveLeft,
    required this.onMoveRight,
    required this.onDelete,
    required this.onDurationChanged,
  });

  final int index;
  final CharacterAnimationFrame frame;
  final bool enabled;
  final bool canMoveLeft;
  final bool canMoveRight;
  final VoidCallback onDuplicate;
  final VoidCallback onMoveLeft;
  final VoidCallback onMoveRight;
  final VoidCallback onDelete;
  final ValueChanged<int> onDurationChanged;

  @override
  State<_FrameCard> createState() => _FrameCardState();
}

class _FrameCardState extends State<_FrameCard> {
  late final TextEditingController _durationController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _durationController = TextEditingController(
      text: widget.frame.durationMs.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _FrameCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frame.durationMs != widget.frame.durationMs) {
      _durationController.text = widget.frame.durationMs.toString();
      _error = null;
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.frame.source;
    return PokeMapCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              PokeMapBadge(
                label: '#${widget.index + 1}',
                variant: PokeMapBadgeVariant.info,
              ),
              const Spacer(),
              PokeMapIconButton(
                key: ValueKey<String>(
                  'animation-frame-move-left-${widget.index}',
                ),
                onPressed: widget.enabled && widget.canMoveLeft
                    ? widget.onMoveLeft
                    : null,
                icon: const Icon(CupertinoIcons.arrow_left),
                tooltip: 'Déplacer à gauche',
                size: 28,
              ),
              PokeMapIconButton(
                key: ValueKey<String>(
                  'animation-frame-move-right-${widget.index}',
                ),
                onPressed: widget.enabled && widget.canMoveRight
                    ? widget.onMoveRight
                    : null,
                icon: const Icon(CupertinoIcons.arrow_right),
                tooltip: 'Déplacer à droite',
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'x ${source.x} · y ${source.y}\n${source.width} × ${source.height} px',
            style: TextStyle(
              color: context.pokeMapColors.textSecondary,
              fontSize: 11,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          PokeMapTextField(
            label: 'Durée (ms)',
            fieldKey: ValueKey<String>(
              'animation-frame-duration-${widget.index}',
            ),
            controller: _durationController,
            enabled: widget.enabled,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            errorText: _error,
            onSubmitted: _submitDuration,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PokeMapIconButton(
                key: ValueKey<String>(
                  'animation-frame-duplicate-${widget.index}',
                ),
                onPressed: widget.enabled ? widget.onDuplicate : null,
                icon: const Icon(CupertinoIcons.square_on_square),
                tooltip: 'Dupliquer',
                size: 28,
              ),
              PokeMapIconButton(
                key: ValueKey<String>('animation-frame-delete-${widget.index}'),
                onPressed: widget.enabled ? widget.onDelete : null,
                icon: const Icon(CupertinoIcons.delete),
                tooltip: 'Supprimer',
                variant: PokeMapIconButtonVariant.danger,
                size: 28,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submitDuration(String value) {
    final duration = int.tryParse(value);
    if (duration == null || duration <= 0) {
      setState(() => _error = 'La durée doit être supérieure à 0 ms.');
      return;
    }
    setState(() => _error = null);
    widget.onDurationChanged(duration);
  }
}
