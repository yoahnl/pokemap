import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/gameplay/items/bag_capacity_editor.dart';
import 'package:map_editor/src/features/gameplay/items/item_studio_gateway.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('defaults unlimited and saves independent per-pocket bounds', (
    tester,
  ) async {
    ProjectBagCapacity? saved;
    await _pump(
      tester,
      onSaved: (value) async {
        saved = value;
        return const ItemStudioMutationReceipt(receiptId: 'capacity');
      },
    );
    expect(_save(tester).onPressed, isNull);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('bag-capacity-distinct-mode')),
        matching: find.byType(DropdownButton<bool>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limité').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('bag-capacity-distinct-value')),
      '2',
    );
    await _mode(tester, 'quantity', true);
    await tester.enterText(
      find.byKey(const Key('bag-capacity-quantity-value')),
      '99',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('bag-capacity-save')));
    await tester.pumpAndSettle();
    expect(saved!.pockets, {
      'medicine': const BagPocketCapacity(
        maxDistinctItems: 2,
        maxQuantityPerItem: 99,
      ),
    });
  });

  testWidgets(
    'invalid raw survives reselection and other pockets block saving',
    (tester) async {
      await _pump(tester);
      await _mode(tester, 'quantity', true);
      await tester.enterText(
        find.byKey(const Key('bag-capacity-quantity-value')),
        '2.5',
      );
      await _mode(tester, 'quantity', true);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('bag-capacity-quantity-value')),
            )
            .controller!
            .text,
        '2.5',
      );
      final pocket = tester.widget<PokeMapDropdownField<String>>(
        find.byKey(const Key('bag-capacity-pocket')),
      );
      pocket.onChanged('tools');
      await tester.pump();
      expect(_save(tester).onPressed, isNull);
      tester
          .widget<PokeMapDropdownField<String>>(
            find.byKey(const Key('bag-capacity-pocket')),
          )
          .onChanged('medicine');
      await tester.pump();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('bag-capacity-quantity-value')),
            )
            .controller!
            .text,
        '2.5',
      );
      await tester.tap(find.byKey(const Key('bag-capacity-reset')));
      await tester.pump();
      expect(
        find.byKey(const Key('bag-capacity-quantity-value')),
        findsNothing,
      );
      expect(_save(tester).onPressed, isNull);
    },
  );

  testWidgets(
    'orphan configured pockets remain editable and reset explicitly',
    (tester) async {
      ProjectBagCapacity? saved;
      await _pump(
        tester,
        initial: const ProjectBagCapacity(
          pockets: {'orphan': BagPocketCapacity(maxDistinctItems: 1)},
        ),
        onSaved: (value) async {
          saved = value;
          return const ItemStudioMutationReceipt(receiptId: 'reset');
        },
      );
      final selector = tester.widget<PokeMapDropdownField<String>>(
        find.byKey(const Key('bag-capacity-pocket')),
      );
      expect(
        selector.items.map((item) => item.value),
        containsAll(['medicine', 'orphan', 'tools']),
      );
      await tester.tap(find.byKey(const Key('bag-capacity-reset')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('bag-capacity-save')));
      await tester.pumpAndSettle();
      expect(saved, const ProjectBagCapacity.unlimited());
    },
  );

  testWidgets('save rejection preserves input and cancel never writes', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      onSaved: (value) async {
        calls++;
        throw StateError('Revision changed');
      },
    );
    await _mode(tester, 'distinct', true);
    await tester.enterText(
      find.byKey(const Key('bag-capacity-distinct-value')),
      '7',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('bag-capacity-save')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Revision changed'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('bag-capacity-distinct-value')),
          )
          .controller!
          .text,
      '7',
    );
    await tester.tap(find.byKey(const Key('bag-capacity-cancel')));
    await tester.pumpAndSettle();
    expect(calls, 1);
  });
}

PokeMapButton _save(WidgetTester tester) =>
    tester.widget(find.byKey(const Key('bag-capacity-save')));

Future<void> _mode(WidgetTester tester, String field, bool limited) async {
  tester
      .widget<PokeMapDropdownField<bool>>(
        find.byKey(ValueKey('bag-capacity-$field-mode')),
      )
      .onChanged(limited);
  await tester.pump();
}

Future<void> _pump(
  WidgetTester tester, {
  ProjectBagCapacity initial = const ProjectBagCapacity.unlimited(),
  Future<ItemStudioMutationReceipt> Function(ProjectBagCapacity)? onSaved,
}) async {
  await tester.binding.setSurfaceSize(const Size(1100, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.light(),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => BagCapacityEditor(
                initial: initial,
                pocketIds: const ['medicine', 'tools'],
                onSaved:
                    onSaved ??
                    (_) async =>
                        const ItemStudioMutationReceipt(receiptId: 'capacity'),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}
