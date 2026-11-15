import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/shell/studio_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, StudioSaveState state) =>
    tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: studioTheme(),
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StudioTopBar(
              projectName: 'HGSS',
              maps: const [],
              activeMapId: null,
              onSelectMap: null,
              onUndo: () {},
              onRedo: () {},
              saveState: state,
              onSave: () {},
              onTestMap: () {},
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('undo and redo stay in place whatever the save state says', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final places = <StudioSaveState, (Offset, Offset)>{};

    for (final state in StudioSaveState.values) {
      await _pump(tester, state);
      places[state] = (
        tester.getCenter(find.byIcon(Icons.undo)),
        tester.getCenter(find.byIcon(Icons.redo)),
      );
    }

    expect(places.values.toSet(), hasLength(1));
    expect(find.text('Échec de l’enregistrement'), findsOneWidget);
    expect(find.text('Enregistré'), findsNothing);
  });
}
