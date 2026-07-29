import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/pokemap_button.dart';
import 'package:map_editor/src/ui/design_system/pokemap_eraser_footprint_dialog.dart';

void main() {
  testWidgets('exposes the three modes and returns the previous brush size',
      (tester) async {
    PokeMapEraserFootprintResult? result;
    await _pumpLauncher(
      tester,
      onLaunch: (context) async {
        result = await showPokeMapEraserFootprintDialog(
          context,
          initialValue: const PokeMapEraserFootprintResult.singleTile(),
          previousBrushSize: (width: 3, height: 2),
          maxDimension: 8,
        );
      },
    );

    await tester.tap(find.text('Configurer la gomme'));
    await tester.pumpAndSettle();

    expect(find.byKey(pokeMapEraserFootprintDialogKey), findsOneWidget);
    expect(find.text('Une case'), findsOneWidget);
    expect(find.text('Pinceau précédent'), findsOneWidget);
    expect(find.text('Personnalisée'), findsOneWidget);
    expect(find.text('3 × 2 cases'), findsOneWidget);

    await tester.tap(find.byKey(pokeMapEraserPreviousBrushChoiceKey));
    await tester.pump();
    await tester.tap(find.byKey(pokeMapEraserFootprintApplyButtonKey));
    await tester.pumpAndSettle();

    expect(
      result,
      const PokeMapEraserFootprintResult.previousBrush(
        width: 3,
        height: 2,
      ),
    );
  });

  testWidgets('keeps the previous brush choice disabled when unavailable',
      (tester) async {
    await _pumpLauncher(
      tester,
      onLaunch: (context) => showPokeMapEraserFootprintDialog(
        context,
        initialValue: const PokeMapEraserFootprintResult.singleTile(),
        maxDimension: 8,
      ),
    );

    await tester.tap(find.text('Configurer la gomme'));
    await tester.pumpAndSettle();

    final previousButton = tester.widget<PokeMapButton>(
      find.byKey(pokeMapEraserPreviousBrushChoiceKey),
    );
    expect(previousButton.onPressed, isNull);
    expect(find.text('Aucun pinceau à reprendre'), findsOneWidget);
  });

  testWidgets('validates custom dimensions and submits valid values with Enter',
      (tester) async {
    PokeMapEraserFootprintResult? result;
    await _pumpLauncher(
      tester,
      onLaunch: (context) async {
        result = await showPokeMapEraserFootprintDialog(
          context,
          initialValue: const PokeMapEraserFootprintResult.singleTile(),
          previousBrushSize: (width: 2, height: 2),
          maxDimension: 8,
        );
      },
    );

    await tester.tap(find.text('Configurer la gomme'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(pokeMapEraserCustomChoiceKey));
    await tester.pump();

    await tester.enterText(find.byKey(pokeMapEraserWidthFieldKey), '0');
    await tester.enterText(find.byKey(pokeMapEraserHeightFieldKey), '9');
    await tester.pump();

    expect(
      find.text('Entrez un entier entre 1 et 8.'),
      findsNWidgets(2),
    );
    expect(_applyButton(tester).onPressed, isNull);

    await tester.enterText(find.byKey(pokeMapEraserWidthFieldKey), '4');
    await tester.enterText(find.byKey(pokeMapEraserHeightFieldKey), '3');
    await tester.pump();
    expect(_applyButton(tester).onPressed, isNotNull);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(
      result,
      const PokeMapEraserFootprintResult.custom(width: 4, height: 3),
    );
    expect(find.byKey(pokeMapEraserFootprintDialogKey), findsNothing);
  });

  testWidgets('cancel returns null', (tester) async {
    PokeMapEraserFootprintResult? result;
    var completed = false;
    await _pumpLauncher(
      tester,
      onLaunch: (context) async {
        result = await showPokeMapEraserFootprintDialog(
          context,
          initialValue: const PokeMapEraserFootprintResult.custom(
            width: 2,
            height: 3,
          ),
          maxDimension: 8,
        );
        completed = true;
      },
    );

    await tester.tap(find.text('Configurer la gomme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(result, isNull);
  });

  testWidgets('Escape returns null', (tester) async {
    PokeMapEraserFootprintResult? result;
    var completed = false;
    await _pumpLauncher(
      tester,
      onLaunch: (context) async {
        result = await showPokeMapEraserFootprintDialog(
          context,
          initialValue: const PokeMapEraserFootprintResult.singleTile(),
          maxDimension: 8,
        );
        completed = true;
      },
    );

    await tester.tap(find.text('Configurer la gomme'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(result, isNull);
    expect(tester.takeException(), isNull);
  });
}

PokeMapButton _applyButton(WidgetTester tester) => tester.widget<PokeMapButton>(
      find.byKey(pokeMapEraserFootprintApplyButtonKey),
    );

Future<void> _pumpLauncher(
  WidgetTester tester, {
  required Future<void> Function(BuildContext context) onLaunch,
}) async {
  tester.view.physicalSize = const Size(1000, 760);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => onLaunch(context),
            child: const Text('Configurer la gomme'),
          ),
        ),
      ),
    ),
  );
}
