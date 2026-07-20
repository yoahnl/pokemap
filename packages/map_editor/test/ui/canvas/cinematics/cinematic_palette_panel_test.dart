import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/ui/canvas/cinematics/builder/cinematic_palette_panel.dart';

void main() {
  testWidgets('owns a stable palette boundary without changing its child', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: CinematicPalettePanel(child: Text('Palette child')),
      ),
    );

    expect(find.byKey(CinematicPalettePanel.surfaceKey), findsOneWidget);
    expect(find.text('Palette child'), findsOneWidget);
  });
}
