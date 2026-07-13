import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('dropdown field exposes its value and opens an anchored menu',
      (tester) async {
    var selected = 'grass';

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: PokeMapDropdownField<String>(
                  key: const ValueKey<String>('base-type-dropdown'),
                  label: 'Base type',
                  value: selected,
                  items: const <PokeMapDropdownItem<String>>[
                    PokeMapDropdownItem(value: 'grass', label: 'Grass Base'),
                    PokeMapDropdownItem(value: 'dirt', label: 'Dirt Base'),
                  ],
                  onChanged: (value) => setState(() => selected = value),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Base type'), findsOneWidget);
    expect(find.text('Grass Base'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.chevron_down), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('base-type-dropdown')));
    await tester.pumpAndSettle();

    expect(find.text('Dirt Base'), findsOneWidget);
    await tester.tap(find.text('Dirt Base'));
    await tester.pumpAndSettle();

    expect(selected, 'dirt');
    expect(find.text('Dirt Base'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
