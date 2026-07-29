import 'package:flutter/widgets.dart';

import '../../../../ui/canvas/editor_canvas_host.dart';
import '../../../../ui/design_system/design_system.dart';

/// Tokenized frame around the existing World Map canvas.
///
/// This component is intentionally structural: map behavior continues to live
/// in [EditorCanvasHost] and [MapCanvas].
class WorldMapCanvasRegion extends StatelessWidget {
  const WorldMapCanvasRegion({super.key});

  @override
  Widget build(BuildContext context) {
    return const PokeMapPanel(
      padding: EdgeInsets.all(14),
      expandChild: true,
      borderRadius: 20,
      child: EditorCanvasHost(),
    );
  }
}
