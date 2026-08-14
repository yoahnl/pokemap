import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/presentation_renderer.dart';

class PresentationFramePreview extends StatelessWidget {
  const PresentationFramePreview({
    super.key,
    required this.frame,
    required this.orientation,
    required this.contentPort,
    required this.playerTheme,
  });

  final PresentationFrame frame;
  final PresentationFrameOrientation orientation;
  final PresentationFrameContentPort contentPort;
  final ThemeData playerTheme;

  @override
  Widget build(BuildContext context) => Theme(
    data: playerTheme,
    child: PresentationFrameRenderer(
      frame: frame,
      orientation: orientation,
      contentPort: contentPort,
    ),
  );
}
