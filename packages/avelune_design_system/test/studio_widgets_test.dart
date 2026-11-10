import 'package:avelune_design_system/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_design_system/presentation/shared/widgets/inputs/studio_search_field.dart';
import 'package:avelune_design_system/presentation/shared/widgets/layout/studio_panel.dart';
import 'package:avelune_design_system/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normal text and primary action text retain readable contrast', () {
    final colors = studioTheme().colorScheme;
    for (final (foreground, background) in [
      (colors.onPrimary, colors.primary),
      (colors.onSurface, colors.surface),
      (colors.onSurfaceVariant, colors.surface),
    ]) {
      final foregroundLuminance = foreground.computeLuminance();
      final backgroundLuminance = background.computeLuminance();
      final lighter = foregroundLuminance > backgroundLuminance
          ? foregroundLuminance
          : backgroundLuminance;
      final darker = foregroundLuminance < backgroundLuminance
          ? foregroundLuminance
          : backgroundLuminance;
      expect((lighter + 0.05) / (darker + 0.05), greaterThanOrEqualTo(4.5));
    }
  });

  for (final variant in StudioButtonVariant.values) {
    testWidgets(
      '${variant.name} button blocks repeated actions while loading',
      (tester) async {
        var calls = 0;
        var loading = true;
        late StateSetter rebuild;
        await tester.pumpWidget(
          _app(
            StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return Center(
                  child: StudioButton(
                    label: 'Enregistrer',
                    variant: variant,
                    loading: loading,
                    onPressed: () => calls++,
                  ),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Enregistrer'));
        await tester.pump();
        expect(calls, 0);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        rebuild(() => loading = false);
        await tester.pumpAndSettle();
        expect(find.byType(CircularProgressIndicator), findsNothing);
        await tester.tap(find.text('Enregistrer'));
        expect(calls, 1);
      },
    );
  }

  testWidgets('clearing a search resets the query and notifies its consumer', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final queries = <String>[];
    await tester.pumpWidget(
      _app(StudioSearchField(controller: controller, onChanged: queries.add)),
    );

    expect(find.byTooltip('Effacer la recherche'), findsNothing);
    await tester.enterText(find.byType(TextField), 'Forêt');
    await tester.pump();
    expect(queries, ['Forêt']);
    await tester.tap(find.byTooltip('Effacer la recherche'));
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(queries, ['Forêt', '']);
    expect(find.byTooltip('Effacer la recherche'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a narrow panel wraps its title and actions at large text size', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var imports = 0;
    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: StudioPanel(
            title: 'Ressources du projet',
            actions: [
              StudioButton(label: 'Importer', onPressed: () => imports++),
            ],
            children: const [
              Text('Choisissez une ressource pour la placer sur votre carte.'),
            ],
          ),
        ),
        textScale: 1.75,
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Importer'));
    expect(imports, 1);
  });


}

Widget _app(Widget child, {double textScale = 1}) => MaterialApp(
  theme: studioTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(body: child),
);
