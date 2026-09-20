import 'cinematic_transport_listenable.dart';
import 'package:flutter/material.dart';
import '../../../features/cinematics/application/cinematic_preview_transport.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import 'cinematic_labels.dart';

class CinematicTransportBar extends StatelessWidget {
  const CinematicTransportBar({
    super.key,
    required this.transport,
    required this.onPlay,
    required this.scale,
    required this.onScale,
    required this.onFit,
  });
  final CinematicPreviewTransport transport;
  final VoidCallback onPlay, onFit;
  final double scale;
  final ValueChanged<double> onScale;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Timeline', style: Theme.of(context).textTheme.titleSmall),
        AnimatedBuilder(
          animation: CinematicTransportListenable(transport),
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StudioTool(
                label: 'Arrêter et revenir au début',
                icon: Icons.skip_previous,
                onPressed: transport.stop,
              ),
              StudioTool(
                label: transport.playing ? 'Pause' : 'Lire la cinématique',
                selected: transport.playing,
                icon: transport.playing ? Icons.pause : Icons.play_arrow,
                onPressed: transport.playing ? transport.pause : onPlay,
              ),
              const SizedBox(width: 6),
              Text(
                '${cinematicTime(transport.timeMs)} / ${cinematicTime(transport.durationMs)}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
        StudioTool(
          label: 'Réduire le zoom temporel',
          icon: Icons.zoom_out,
          onPressed: () => onScale((scale * .8).clamp(.008, .5)),
        ),
        StudioTool(
          label: 'Agrandir le zoom temporel',
          icon: Icons.zoom_in,
          onPressed: () => onScale((scale * 1.25).clamp(.008, .5)),
        ),
        StudioTool(
          label: 'Cadrer la séquence',
          icon: Icons.fit_screen,
          onPressed: onFit,
        ),
      ],
    ),
  );
}
