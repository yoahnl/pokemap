import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  group('PokeMapSidebarItem Tests', () {
    Widget buildTestWidget({
      required ThemeData theme,
      required Widget child,
    }) {
      return MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(child: child),
        ),
      );
    }

    testWidgets('PokeMapSidebarItem pumps correctly under light & dark theme', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: PokeMapSidebarItem(
            label: 'Home',
            icon: const Icon(Icons.home),
            onTap: () {},
          ),
        ),
      );
      expect(find.text('Home'), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);

      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.dark(),
          child: PokeMapSidebarItem(
            label: 'Home',
            icon: const Icon(Icons.home),
            onTap: () {},
          ),
        ),
      );
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('PokeMapSidebarItem selected displays active state styles', (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                capturedContext = context;
                return PokeMapSidebarItem(
                  label: 'Selected Tab',
                  selected: true,
                  icon: const Icon(Icons.star),
                  onTap: () {},
                );
              },
            ),
          ),
        ),
      );

      final textFinder = find.text('Selected Tab');
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.color, equals(capturedContext.pokeMapColors.brandPrimary));
      expect(textWidget.style?.fontWeight, equals(FontWeight.w600));
    });

    testWidgets('PokeMapSidebarItem disabled does not trigger onTap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: PokeMapSidebarItem(
            label: 'Disabled Tab',
            disabled: true,
            icon: const Icon(Icons.block),
            onTap: () => tapped = true,
          ),
        ),
      );

      final itemFinder = find.byType(PokeMapSidebarItem);
      expect(itemFinder, findsOneWidget);

      await tester.tap(itemFinder);
      await tester.pump();
      expect(tapped, isFalse);
    });
  });
}
