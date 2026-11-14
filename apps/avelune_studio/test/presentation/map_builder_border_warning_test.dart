import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_canvas.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  required Locale locale,
  String? error,
  Set<String> borderWarnings = const {},
}) => tester.pumpWidget(
  MaterialApp(
    theme: studioTheme(),
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: MapBuilderCanvas(
        space: MapBuilderSpace.construction,
        onSpace: (_) {},
        entry: null,
        tool: StudioMapTool.border,
        onTool: (_) {},
        inspectorOpen: false,
        onToggleInspector: () {},
        error: error,
        borderWarnings: borderWarnings,
        surface: const SizedBox(),
        statusBar: const SizedBox(),
      ),
    ),
  ),
);

void main() {
  testWidgets('a buried relief is explained in French and English', (
    tester,
  ) async {
    await _pump(
      tester,
      locale: const Locale('fr'),
      borderWarnings: {'border.spatial.face_base_mismatch'},
    );
    expect(
      find.text(
        'Ce relief est sous le sol : il n’y a pas de dénivelé ici, '
        'il restera invisible.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('border.spatial'), findsNothing);

    await _pump(
      tester,
      locale: const Locale('en'),
      borderWarnings: {'border.spatial.face_base_mismatch'},
    );
    expect(
      find.text(
        'This relief is under the ground: there is no height difference '
        'here, so it will stay invisible.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('other warnings get a plain message without raw codes', (
    tester,
  ) async {
    await _pump(
      tester,
      locale: const Locale('fr'),
      borderWarnings: {'border.spatial.materialization_stale'},
    );
    expect(
      find.text(
        'Ce relief est posé, mais il risque de mal s’afficher à cet endroit.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('border.spatial'), findsNothing);
  });

  testWidgets('an error takes the notice place and no warning shows', (
    tester,
  ) async {
    await _pump(
      tester,
      locale: const Locale('fr'),
      error: 'Échec',
      borderWarnings: {'border.spatial.face_base_mismatch'},
    );
    expect(find.text('Échec'), findsOneWidget);
    expect(find.byKey(const ValueKey('map-border-warning')), findsNothing);

    await _pump(tester, locale: const Locale('fr'));
    expect(find.byKey(const ValueKey('map-border-warning')), findsNothing);
  });
}
