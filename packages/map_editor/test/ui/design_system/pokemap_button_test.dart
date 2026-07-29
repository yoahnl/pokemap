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

    testWidgets('PokeMapButton pumps correctly under light & dark theme',
        (tester) async {
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

    testWidgets('PokeMapButton supports the compact success toolbar variant',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.dark(),
          child: PokeMapButton(
            key: const ValueKey('compact-success-toolbar-button'),
            onPressed: () {},
            size: PokeMapButtonSize.compact,
            variant: PokeMapButtonVariant.successOutline,
            leading: const Icon(Icons.verified_user_outlined),
            child: const Text('Validate'),
          ),
        ),
      );

      // The Event Builder header needs a 36px target. This focused contract
      // protects that new design-system density without changing `small` or
      // `medium` buttons used by existing forms.
      expect(
        tester
            .getSize(
              find.byKey(const ValueKey('compact-success-toolbar-button')),
            )
            .height,
        36,
      );
      expect(find.text('Validate'), findsOneWidget);
    });

    testWidgets('PokeMapButton displays spinner when isLoading is true',
        (tester) async {
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

    testWidgets('PokeMapButton focuses an external launcher before activation',
        (tester) async {
      final focusNode = FocusNode(debugLabel: 'modal launcher');
      addTearDown(focusNode.dispose);
      var wasFocusedDuringActivation = false;

      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.dark(),
          child: PokeMapButton(
            focusNode: focusNode,
            onPressed: () {
              wasFocusedDuringActivation = focusNode.hasFocus;
            },
            child: const Text('Open modal'),
          ),
        ),
      );

      await tester.tap(find.text('Open modal'));
      await tester.pump();

      expect(wasFocusedDuringActivation, isTrue);
      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets(
        'PokeMapIconButton tooltip is displayed and works with variants',
        (tester) async {
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

    testWidgets(
        'PokeMapButton and PokeMapIconButton provide Semantics information',
        (tester) async {
      // 1. PokeMapButton
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: PokeMapButton(
            onPressed: () {},
            child: const Text('Semantics Button'),
          ),
        ),
      );

      final buttonSemanticsFinder = find.byWidgetPredicate((widget) =>
          widget is Semantics &&
          widget.properties.button == true &&
          widget.properties.enabled == true);
      expect(buttonSemanticsFinder, findsOneWidget);

      // 2. PokeMapIconButton
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: PokeMapIconButton(
            onPressed: () {},
            icon: const Icon(Icons.add),
          ),
        ),
      );

      final iconSemanticsFinder = find.byWidgetPredicate((widget) =>
          widget is Semantics &&
          widget.properties.button == true &&
          widget.properties.enabled == true);
      expect(iconSemanticsFinder, findsOneWidget);
    });

    testWidgets('PokeMapButton exposes its selected state to semantics',
        (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.dark(),
          child: PokeMapButton(
            onPressed: () {},
            isSelected: true,
            child: const Text('Sélection'),
          ),
        ),
      );

      final selectedButton = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.button == true &&
            widget.properties.selected == true,
      );
      expect(selectedButton, findsOneWidget);
      semantics.dispose();
    });
  });
}
