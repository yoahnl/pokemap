import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'surface_studio_rebuild_test_harness.dart';

void main() {
  testWidgets('premium wizard shell mirrors the reference structure',
      (tester) async {
    await pumpSurfaceStudioForTest(tester);
    await tester.pump();

    expect(find.byKey(const Key('surfaceStudio.shell')), findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.header')), findsOneWidget);
    expect(
      find.text('Surface Studio — Assistant de mapping d’atlas'),
      findsOneWidget,
    );

    for (final label in [
      'Importer',
      'Découper',
      'Mapper',
      'Prévisualiser',
      'Enregistrer',
    ]) {
      expect(find.text(label), findsWidgets);
    }

    expect(find.byKey(const Key('surfaceStudio.stepper')), findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.step.mapper.active')),
        findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.sidebar')), findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.atlas.panel')), findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.schema.panel')), findsOneWidget);
    expect(
        find.byKey(const Key('surfaceStudio.preview.panel')), findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.bottomBar')), findsOneWidget);
  });

  testWidgets('sidebar and right dock collapse and expand with sliding panels',
      (
    tester,
  ) async {
    await pumpSurfaceStudioForTest(tester);
    await tester.pump();

    expect(find.byKey(const Key('surfaceStudio.sidebar.expanded')),
        findsOneWidget);
    await tester
        .tap(find.byKey(const Key('surfaceStudio.sidebar.collapseButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('surfaceStudio.sidebar.collapsed')),
        findsOneWidget);
    expect(find.byTooltip('Importer'), findsOneWidget);

    await tester
        .tap(find.byKey(const Key('surfaceStudio.sidebar.collapseButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('surfaceStudio.sidebar.expanded')),
        findsOneWidget);

    expect(
        find.byKey(const Key('surfaceStudio.schema.expanded')), findsOneWidget);
    await tester
        .tap(find.byKey(const Key('surfaceStudio.schema.collapseButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('surfaceStudio.schema.collapsed')),
        findsOneWidget);
  });

  testWidgets('stepper allows previous steps and blocks locked future steps', (
    tester,
  ) async {
    await pumpSurfaceStudioForTest(tester);
    await tester.pump();

    await tester.tap(find.byKey(const Key('surfaceStudio.step.import')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('surfaceStudio.step.import.active')),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('surfaceStudio.step.save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('surfaceStudio.step.import.active')),
        findsOneWidget);
    expect(find.text('Terminez les étapes précédentes avant d’avancer.'),
        findsOneWidget);
  });

  testWidgets('bottom action bar exposes the required commands',
      (tester) async {
    await pumpSurfaceStudioForTest(tester);
    await tester.pump();

    expect(find.byKey(const Key('surfaceStudio.action.back')), findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.action.autoSuggest')),
        findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.action.applyMapping')),
        findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.action.next')), findsOneWidget);
    expect(find.text('Retour'), findsOneWidget);
    expect(find.text('Suggestion auto'), findsOneWidget);
    expect(find.text('Appliquer le mapping'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
  });
}
