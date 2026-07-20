import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/ui/canvas/cinematics/builder/cinematic_stage_panel.dart';

void main() {
  testWidgets('owns a stable stage boundary without changing its child', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: CinematicStagePanel(child: Text('Stage child')),
      ),
    );

    expect(find.byKey(CinematicStagePanel.surfaceKey), findsOneWidget);
    expect(find.text('Stage child'), findsOneWidget);
  });
}
