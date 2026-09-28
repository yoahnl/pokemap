import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'character_studio_controller.dart';
import '../../../features/characters/application/character_studio_draft.dart';
import '../../shared/widgets/layout/studio_asset_preview.dart';
import '../map_workspace/map_workspace_visuals.dart';
import 'character_workspace_visuals.dart';

typedef CharacterFrameBuilder =
    Widget Function(
      CharacterAnimationFrame frame,
      EntityFacing direction,
      double size,
    );

class CharacterStudioSourcePanel extends StatelessWidget {
  const CharacterStudioSourcePanel({
    super.key,
    required this.source,
    required this.draft,
    required this.controller,
    required this.visuals,
    required this.elapsedMs,
    required this.pickedSource,
    required this.onPick,
    required this.frameBuilder,
  });

  final ProjectRegularAtlasTilesetSource source;
  final CharacterStudioDraft draft;
  final CharacterStudioController controller;
  final MapWorkspaceVisuals visuals;
  final int elapsedMs;
  final TilesetSourceRect? pickedSource;
  final ValueChanged<TilesetSourceRect> onPick;
  final CharacterFrameBuilder frameBuilder;

  @override
  Widget build(BuildContext context) {
    final frameWidth =
        controller.project().settings.tileWidth *
        draft.frameWidth.clamp(2, 1 << 20);
    final frameHeight =
        controller.project().settings.tileHeight *
        draft.frameHeight.clamp(2, 1 << 20);
    final columns =
        (source.pixelWidth - source.marginX + source.spacingX) ~/
        (frameWidth + source.spacingX);
    final rows =
        (source.pixelHeight - source.marginY + source.spacingY) ~/
        (frameHeight + source.spacingY);
    final count = (columns * rows).clamp(0, 96);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Aperçu de l’animation',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 185,
              child: StudioAssetPreview(
                child:
                    draft.previewCharacter.animations.any(
                          (animation) =>
                              animation.state == controller.animationState &&
                              animation.direction ==
                                  controller.previewDirection &&
                              animation.frames.isNotEmpty,
                        ) &&
                        visuals is CharacterWorkspaceVisuals
                    ? (visuals as CharacterWorkspaceVisuals)
                          .characterAnimationThumbnail(
                            draft.previewCharacter,
                            size: 155,
                            facing: controller.previewDirection,
                            state: controller.animationState,
                            elapsedMs: (elapsedMs * controller.playbackSpeed)
                                .round(),
                          )
                    : const Text('Aucune pose pour cette direction'),
              ),
            ),
            Row(
              children: [
                IconButton(
                  tooltip: controller.playing ? 'Mettre en pause' : 'Lire',
                  onPressed: () => controller.setPlaying(!controller.playing),
                  icon: Icon(
                    controller.playing ? Icons.pause : Icons.play_arrow,
                  ),
                ),
                for (final direction in const [
                  (EntityFacing.south, 'Bas', Icons.arrow_downward),
                  (EntityFacing.west, 'Gauche', Icons.arrow_back),
                  (EntityFacing.east, 'Droite', Icons.arrow_forward),
                  (EntityFacing.north, 'Haut', Icons.arrow_upward),
                ])
                  IconButton(
                    tooltip: direction.$2,
                    onPressed: () =>
                        controller.setPreviewDirection(direction.$1),
                    icon: Icon(
                      direction.$3,
                      color: direction.$1 == controller.previewDirection
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Vitesse de l’aperçu'),
                DropdownButton<double>(
                  value: controller.playbackSpeed,
                  items: const [
                    DropdownMenuItem(value: 0.5, child: Text('Lente')),
                    DropdownMenuItem(value: 1, child: Text('Normale')),
                    DropdownMenuItem(value: 2, child: Text('Rapide')),
                  ],
                  onChanged: (value) {
                    if (value != null) controller.setPlaybackSpeed(value);
                  },
                ),
              ],
            ),
            const Divider(),
            Text(
              'Images de la planche',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            const Text(
              'Cliquez sur une image puis une pose, ou faites-la glisser.',
            ),
            if (pickedSource != null)
              Text(
                'Sélection : colonne ${pickedSource!.x + 1}, ligne ${pickedSource!.y + 1} '
                '· $frameWidth × $frameHeight px',
              ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                key: const ValueKey('character-source-grid'),
                itemCount: count,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                ),
                itemBuilder: (context, index) {
                  final rect = TilesetSourceRect(
                    x: index % columns,
                    y: index ~/ columns,
                  );
                  final child = Material(
                    color: rect == pickedSource
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerLow,
                    child: InkWell(
                      key: ValueKey('character-source-$index'),
                      onTap: () => onPick(rect),
                      child: Center(
                        child: frameBuilder(
                          CharacterAnimationFrame(source: rect),
                          EntityFacing.south,
                          56,
                        ),
                      ),
                    ),
                  );
                  return Draggable<TilesetSourceRect>(
                    data: rect,
                    feedback: Material(
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: frameBuilder(
                          CharacterAnimationFrame(source: rect),
                          EntityFacing.south,
                          56,
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(opacity: 0.4, child: child),
                    child: child,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
