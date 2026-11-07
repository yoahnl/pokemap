import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<StateSetter> pumpScrollPage(
    WidgetTester tester, {
    Key? sectionKey,
  }) async {
    late StateSetter setShown;
    var shown = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setShown = (change) => setState(() {
                change();
                shown = !shown;
              });
              return shown
                  ? ListView(
                      key: const PageStorageKey<String>('page-scroll'),
                      children: [
                        StudioSection(
                          key: sectionKey,
                          title: 'Options avancées',
                          collapsible: true,
                          initiallyExpanded: false,
                          children: const [Text('Détail avancé')],
                        ),
                        for (var index = 0; index < 30; index++)
                          SizedBox(height: 80, child: Text('Ligne $index')),
                      ],
                    )
                  : const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return setShown;
  }

  Future<void> remount(WidgetTester tester, StateSetter toggle) async {
    toggle(() {});
    await tester.pump();
    toggle(() {});
    await tester.pumpAndSettle();
  }

  testWidgets(
    'opening a section inside a remembered scroll page never corrupts its scroll position',
    (tester) async {
      final toggle = await pumpScrollPage(tester);
      await tester.tap(find.text('Options avancées'));
      await tester.pumpAndSettle();
      expect(find.text('Détail avancé'), findsOneWidget);

      await remount(tester, toggle);

      expect(tester.takeException(), isNull);
      expect(find.text('Options avancées'), findsOneWidget);
      expect(find.text('Détail avancé'), findsNothing);
    },
  );

  testWidgets(
    'a scrolled page reopens its sections without reading the scroll offset as their state',
    (tester) async {
      final toggle = await pumpScrollPage(tester);
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pumpAndSettle();

      await remount(tester, toggle);

      expect(tester.takeException(), isNull);
      expect(find.text('Options avancées'), findsOneWidget);
    },
  );

  testWidgets(
    'a section given its own storage key still remembers that it was opened',
    (tester) async {
      final toggle = await pumpScrollPage(
        tester,
        sectionKey: const PageStorageKey<String>('advanced-options'),
      );
      await tester.tap(find.text('Options avancées'));
      await tester.pumpAndSettle();

      await remount(tester, toggle);

      expect(tester.takeException(), isNull);
      expect(find.text('Détail avancé'), findsOneWidget);
    },
  );
}
