import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/gameplay/items/item_definition_editor.dart';
import 'package:map_editor/src/features/gameplay/items/item_studio_gateway.dart';
import 'package:map_editor/src/theme/theme.dart';

void main() {
  testWidgets('creates a canonical definition without asking for a raw id', (
    tester,
  ) async {
    ProjectItemDefinition? saved;

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ItemDefinitionEditor(
              initialDefinition: null,
              onSaved: (definition) => saved = definition,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('item-definition-name-field')),
      'Super Potion',
    );
    await tester.pump();

    expect(find.text('super-potion'), findsOneWidget);

    await _tapVisible(
      tester,
      find.byKey(const Key('item-definition-save-button')),
    );
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.id, 'super-potion');
    expect(saved!.displayName, 'Super Potion');
    expect(saved!.pocketId, 'items');
  });

  testWidgets('shows inline validation and does not submit an empty name', (
    tester,
  ) async {
    var saveCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ItemDefinitionEditor(
              initialDefinition: null,
              onSaved: (_) => saveCount++,
            ),
          ),
        ),
      ),
    );

    await _tapVisible(
      tester,
      find.byKey(const Key('item-definition-save-button')),
    );
    await tester.pump();

    expect(find.text('Le nom est obligatoire.'), findsOneWidget);
    expect(saveCount, 0);
  });

  testWidgets('edits effects, capture, machine and held capabilities', (
    tester,
  ) async {
    ProjectItemDefinition? saved;
    const definition = ProjectItemDefinition(
      id: 'utility-orb',
      displayName: 'Utility Orb',
      pocketId: 'items',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ItemDefinitionEditor(
              initialDefinition: definition,
              heldEffectOptions: const <ItemStudioOption>[
                ItemStudioOption(id: 'leftovers', label: 'Régénération'),
              ],
              moveOptions: const <ItemStudioOption>[
                ItemStudioOption(id: 'cut', label: 'Coupe'),
              ],
              onSaved: (value) => saved = value,
            ),
          ),
        ),
      ),
    );

    await _tapVisible(
      tester,
      find.byKey(const Key('item-effect-overworld-toggle')),
    );
    await _tapVisible(
      tester,
      find.byKey(const Key('item-effect-capture-toggle')),
    );
    await _tapVisible(
      tester,
      find.byKey(const Key('item-effect-machine-toggle')),
    );
    await _tapVisible(tester, find.byKey(const Key('item-effect-held-toggle')));
    await tester.pump();
    await _tapVisible(
      tester,
      find.byKey(const Key('item-definition-save-button')),
    );
    await tester.pump();

    expect(saved!.uses, hasLength(1));
    expect(
      saved!.uses.single.contexts,
      contains(ProjectItemUseContext.overworld),
    );
    expect(saved!.capture, isNotNull);
    expect(saved!.machine!.moveId, 'cut');
    expect(saved!.heldEffectId, 'leftovers');
  });

  testWidgets('offers only runtime-supported effects for each context', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ItemDefinitionEditor(
              initialDefinition: const ProjectItemDefinition(
                id: 'context-tonic',
                displayName: 'Context Tonic',
                pocketId: 'items',
              ),
              onSaved: (_) {},
            ),
          ),
        ),
      ),
    );

    await _tapVisible(
      tester,
      find.byKey(const Key('item-effect-overworld-toggle')),
    );
    await _tapVisible(
      tester,
      find.byKey(const Key('item-effect-battle-toggle')),
    );

    await _tapVisible(
      tester,
      find.byKey(const Key('item-effect-overworld-effect-dropdown')),
    );
    expect(find.text('Restaure 10 PP'), findsOneWidget);
    expect(find.text('Repousse 100 pas'), findsNothing);
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    await _tapVisible(
      tester,
      find.byKey(const Key('item-effect-battle-effect-dropdown')),
    );
    expect(find.text('Restaure 10 PP'), findsNothing);
    expect(find.text('Repousse 100 pas'), findsNothing);
  });
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}
