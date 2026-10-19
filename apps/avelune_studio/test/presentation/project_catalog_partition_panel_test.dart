import 'package:avelune_studio/presentation/features/resources/project_catalog_partition_panel.dart';
import 'package:avelune_studio/presentation/features/home/studio_home_screen.dart';
import 'package:avelune_studio/presentation/shell/studio_home_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'optimization lives in home without reserving workspace space and remains guarded',
    (tester) async {
      var allowed = false;
      var partitions = 0;
      var reopens = 0;
      final home = StudioHomeNavigation()..resume();
      addTearDown(home.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: AnimatedBuilder(
            animation: home,
            builder: (context, _) => Stack(
              children: [
                Positioned.fill(
                  child: Offstage(
                    offstage: home.visible,
                    child: ProjectCatalogPartitionPanel(
                      home: home,
                      registerExitGuard: (_) {},
                      partition: () async {
                        partitions++;
                      },
                      reopen: () async {
                        reopens++;
                      },
                      childBuilder: (guard) {
                        guard(() async => allowed);
                        return const SizedBox.expand(
                          key: ValueKey('workspace-content'),
                        );
                      },
                    ),
                  ),
                ),
                if (home.visible)
                  Positioned.fill(
                    child: StudioHomeScreen(
                      projectName: 'Projet',
                      onOpen: () {},
                      onDestination: (_) {},
                      onRecent: (_) {},
                      onRemoveRecent: (_) {},
                      onMap: (_) {},
                      onOptimizeLibrary: home.onOptimizeLibrary,
                      busy: home.optimizingLibrary,
                      optimizingLibrary: home.optimizingLibrary,
                      libraryOptimizationError: home.libraryOptimizationError,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Optimiser la bibliothèque'), findsNothing);
      expect(
        tester.getRect(find.byKey(const ValueKey('workspace-content'))),
        const Rect.fromLTWH(0, 0, 800, 600),
      );
      home.showHome();
      await tester.pumpAndSettle();
      expect(find.text('Optimiser la bibliothèque'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('project-catalog-partition')),
      );
      await tester.tap(find.byKey(const ValueKey('project-catalog-partition')));
      await tester.pumpAndSettle();
      expect(find.text('Optimiser la bibliothèque ?'), findsNothing);
      expect(partitions, 0);
      allowed = true;
      await tester.tap(find.byKey(const ValueKey('project-catalog-partition')));
      await tester.pumpAndSettle();
      expect(partitions, 0);
      await tester.tap(find.text('Optimiser et rouvrir'));
      await tester.pumpAndSettle();
      expect(partitions, 1);
      expect(reopens, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
