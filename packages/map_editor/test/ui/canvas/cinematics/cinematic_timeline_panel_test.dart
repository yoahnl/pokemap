import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/ui/canvas/cinematics/builder/cinematic_timeline_panel.dart';

void main() {
  testWidgets('owns a stable timeline boundary without changing its child', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: CinematicTimelinePanel(child: Text('Timeline child')),
      ),
    );

    expect(find.byKey(CinematicTimelinePanel.surfaceKey), findsOneWidget);
    expect(find.text('Timeline child'), findsOneWidget);
  });
}
