import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/ui/canvas/cinematics/builder/cinematic_inspector_panel.dart';

void main() {
  testWidgets('owns a stable inspector boundary without changing its child', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: CinematicInspectorPanel(child: Text('Inspector child')),
      ),
    );

    expect(find.byKey(CinematicInspectorPanel.surfaceKey), findsOneWidget);
    expect(find.text('Inspector child'), findsOneWidget);
  });
}
