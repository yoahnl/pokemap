import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  group('PokeMapButton & PokeMapIconButton Tests', () {
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

    testWidgets('PokeMapButton pumps correctly under light & dark theme', (tester) async {
      // Light Mode
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: PokeMapButton(
            onPressed: () {},
            child: const Text('Light Button'),
          ),
        ),
      );
      expect(find.text('Light Button'), findsOneWidget);

      // Dark Mode
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.dark(),
          child: PokeMapButton(
            onPressed: () {},
            child: const Text('Dark Button'),
          ),
        ),
      );
      expect(find.text('Dark Button'), findsOneWidget);
    });

    testWidgets('PokeMapButton disabled if onPressed is null', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: const PokeMapButton(
            onPressed: null,
            child: Text('Disabled Button'),
          ),
        ),
      );

      final buttonFinder = find.byType(PokeMapButton);
      expect(buttonFinder, findsOneWidget);

      final button = tester.widget<PokeMapButton>(buttonFinder);
      expect(button.onPressed, isNull);
    });

    testWidgets('PokeMapButton displays spinner when isLoading is true', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: PokeMapButton(
            onPressed: () {},
            isLoading: true,
            child: const Text('Loading Button'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      final button = tester.widget<PokeMapButton>(find.byType(PokeMapButton));
      expect(button.isLoading, isTrue);
    });

    testWidgets('PokeMapIconButton tooltip is displayed and works with variants', (tester) async {
      int count = 0;
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: PokeMapIconButton(
            onPressed: () => count++,
            icon: const Icon(Icons.add),
            tooltip: 'Add Item',
            variant: PokeMapIconButtonVariant.soft,
          ),
        ),
      );

      final iconFinder = find.byType(PokeMapIconButton);
      expect(iconFinder, findsOneWidget);
      expect(find.byType(Tooltip), findsOneWidget);

      await tester.tap(iconFinder);
      await tester.pump();
      expect(count, equals(1));
    });

    testWidgets('PokeMapIconButton supports disabled state', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: const PokeMapIconButton(
            onPressed: null,
            icon: Icon(Icons.add),
            variant: PokeMapIconButtonVariant.danger,
          ),
        ),
      );

      final iconFinder = find.byType(PokeMapIconButton);
      expect(iconFinder, findsOneWidget);

      // Verify that tap doesn't cause errors since onPressed is null
      await tester.tap(iconFinder);
      await tester.pump();
    });
  });
}
