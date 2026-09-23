import 'package:avelune_studio/features/home/domain/recent_studio_project.dart';
import 'package:avelune_studio/presentation/features/home/studio_home_screen.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('compact home builds long recent collections on demand', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: StudioHomeScreen(
          projectName: 'Projet de test',
          onOpen: () {},
          onResume: () {},
          onDestination: (_) {},
          onRecent: (_) {},
          onRemoveRecent: (_) {},
          onMap: (_) {},
          recentProjects: [
            for (var i = 0; i < 100; i++)
              RecentStudioProject(
                name: 'Projet $i',
                directoryPath: '/tmp/project-$i',
                lastOpenedAt: DateTime(2026, 9, 23),
              ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final frame = tester.getRect(find.byType(StudioPrimaryNavigation));
    final outer = find.descendant(
      of: find.byKey(const ValueKey('home-local-content-scroll')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('home-recent-projects-list')),
      200,
      scrollable: outer,
    );
    expect(find.text('Projet 99'), findsNothing);
    final recent = find.descendant(
      of: find.byKey(const ValueKey('home-recent-projects-list')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Projet 99'),
      200,
      scrollable: recent,
    );
    expect(find.text('Projet 99'), findsOneWidget);
    expect(tester.getRect(find.byType(StudioPrimaryNavigation)), frame);
    expect(tester.takeException(), isNull);
  });
}
