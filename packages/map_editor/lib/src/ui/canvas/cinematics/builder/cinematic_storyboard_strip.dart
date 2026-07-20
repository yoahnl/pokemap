import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../design_system/design_system.dart';
import '../../../../theme/theme.dart';

typedef ApplyCinematicBlockingPresetCallback = Future<bool> Function(
  CinematicBlockingPresetPreview preview,
);

/// Plan-by-plan navigation and guided blocking presets derived from a
/// Cinematic's canonical linear timeline.
final class CinematicStoryboardStrip extends StatelessWidget {
  const CinematicStoryboardStrip({
    super.key,
    required this.cinematic,
    this.selectedShotId,
    this.onSelectShot,
    this.onApplyPreset,
  });

  static const stripKey = ValueKey<String>('cinematic-storyboard-strip');

  final CinematicAsset cinematic;
  final String? selectedShotId;
  final ValueChanged<CinematicStoryboardShot>? onSelectShot;
  final ApplyCinematicBlockingPresetCallback? onApplyPreset;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final storyboard = buildCinematicStoryboardReadModel(cinematic);
    return Container(
      key: stripKey,
      height: 116,
      decoration: BoxDecoration(
        color: colors.cardSurface,
        border: Border(bottom: BorderSide(color: colors.borderSubtle)),
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 122,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STORYBOARD',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${storyboard.shots.length} plan${storyboard.shots.length > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  storyboard.locationLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
                const Spacer(),
                PokeMapButton(
                  key: const ValueKey('cinematic-blocking-presets-button'),
                  onPressed: onApplyPreset == null
                      ? null
                      : () => _showPresetPicker(context),
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.secondary,
                  leading: const Icon(CupertinoIcons.sparkles, size: 14),
                  child: const Text('Presets'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: storyboard.shots.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final shot = storyboard.shots[index];
                final isSelected = selectedShotId == shot.id ||
                    (selectedShotId == null && index == 0);
                return SizedBox(
                  width: 190,
                  child: PokeMapCard(
                    key: ValueKey('cinematic-storyboard-shot-${shot.id}'),
                    onTap:
                        onSelectShot == null ? null : () => onSelectShot!(shot),
                    selected: isSelected,
                    padding: const EdgeInsets.all(9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${index + 1}. ${shot.label}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            if (shot.diagnostics.isNotEmpty)
                              Icon(
                                CupertinoIcons.exclamationmark_triangle_fill,
                                size: 13,
                                color: colors.warning,
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          shot.cameraFraming,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                        ),
                        Text(
                          shot.actorLabels.isEmpty
                              ? 'Aucun acteur cadré'
                              : shot.actorLabels.join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: colors.textMuted,
                                  ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDuration(shot.startMs, shot.durationMs),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.textMuted,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
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
        ],
      ),
    );
  }

  Future<void> _showPresetPicker(BuildContext context) async {
    final selected = await showDialog<CinematicBlockingPresetKind>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ajouter un blocking guidé'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final kind in CinematicBlockingPresetKind.values) ...[
                PokeMapButton(
                  key: ValueKey('cinematic-blocking-preset-${kind.name}'),
                  onPressed: () => Navigator.of(dialogContext).pop(kind),
                  variant: PokeMapButtonVariant.secondary,
                  child: Text(_presetLabel(kind)),
                ),
                if (kind != CinematicBlockingPresetKind.values.last)
                  const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
    if (selected == null || !context.mounted) return;
    final preview = _previewFor(selected);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Prévisualiser · ${_presetLabel(selected)}'),
        content: Text(
          preview.canApply
              ? '${preview.diff.addedStepCount} blocs seront ajoutés en une transaction.\n\n${preview.proposedSteps.map((step) => '• ${step.label ?? step.kind.name}').join('\n')}'
              : 'Preset incompatible avec ce plan : ${preview.diagnostics.map((diagnostic) => diagnostic.name).join(', ')}.',
        ),
        actions: [
          PokeMapButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            variant: PokeMapButtonVariant.ghost,
            size: PokeMapButtonSize.small,
            child: const Text('Annuler'),
          ),
          PokeMapButton(
            key: const ValueKey('cinematic-blocking-preset-apply'),
            onPressed: preview.canApply
                ? () => Navigator.of(dialogContext).pop(true)
                : null,
            size: PokeMapButtonSize.small,
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
    if (confirmed == true) await onApplyPreset!(preview);
  }

  CinematicBlockingPresetPreview _previewFor(
    CinematicBlockingPresetKind kind,
  ) {
    final actors =
        cinematic.requiredActors.map((actor) => actor.actorId).toList();
    final targets =
        cinematic.movementTargets.map((target) => target.targetId).toList();
    final points =
        cinematic.stageContext?.stagePoints.map((point) => point.id).toList() ??
            const <String>[];
    return previewCinematicBlockingPreset(
      cinematic,
      kind: kind,
      actorIds: switch (kind) {
        CinematicBlockingPresetKind.movingCrowd => actors,
        CinematicBlockingPresetKind.npcEntrance ||
        CinematicBlockingPresetKind.dramaticArrival =>
          actors.take(1).toList(),
        _ => const [],
      },
      targetIds: switch (kind) {
        CinematicBlockingPresetKind.movingCrowd =>
          targets.take(actors.length).toList(),
        CinematicBlockingPresetKind.npcEntrance => targets.take(1).toList(),
        _ => const [],
      },
      stagePointIds: kind == CinematicBlockingPresetKind.cameraPan
          ? points.take(2).toList()
          : const [],
    );
  }
}

String _presetLabel(CinematicBlockingPresetKind kind) => switch (kind) {
      CinematicBlockingPresetKind.npcEntrance => 'Entrée PNJ',
      CinematicBlockingPresetKind.dramaticArrival => 'Arrivée dramatique',
      CinematicBlockingPresetKind.cameraPan => 'Pan caméra',
      CinematicBlockingPresetKind.fadeTransition => 'Transition en fondu',
      CinematicBlockingPresetKind.movingCrowd => 'Foule en mouvement',
    };

String _formatDuration(int startMs, int durationMs) =>
    '${(startMs / 1000).toStringAsFixed(1)} s · ${(durationMs / 1000).toStringAsFixed(1)} s';
