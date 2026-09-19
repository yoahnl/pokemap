import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_choice.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_resource_card.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_search_field.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_tabs.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_app_shell.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_panel.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_resource_grid.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  testWidgets('a narrow top bar keeps multiple large-text actions usable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final actions = <String>[];
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            StudioTopBar(
              projectName: 'Les Brumes de Selbrume — projet de démonstration',
              actions: [
                StudioButton(
                  label: 'Enregistrer',
                  icon: Icons.save_outlined,
                  onPressed: () => actions.add('save'),
                ),
                StudioButton(
                  label: 'Tester',
                  secondary: true,
                  icon: Icons.play_arrow,
                  onPressed: () => actions.add('test'),
                ),
              ],
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
        textScale: 1.75,
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Enregistrer'));
    await tester.tap(find.text('Tester'));
    expect(actions, ['save', 'test']);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
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

  testWidgets('tabs select by pointer and keyboard without losing the choice', (
    tester,
  ) async {
    var selected = 'preview';
    final selections = <String>[];
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => StudioTabs<String>(
            items: const {
              'preview': 'Aperçu',
              'information': 'Informations',
              'variants': 'Variantes',
            },
            selected: selected,
            onChanged: (value) {
              selections.add(value);
              setState(() => selected = value);
            },
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(selected, 'information');
    expect(selections, ['information']);

    await tester.tap(find.text('Variantes'));
    await tester.pumpAndSettle();
    expect(selected, 'variants');
    expect(
      tester
          .widgetList<StudioChoice>(find.byType(StudioChoice))
          .where((choice) => choice.selected)
          .single
          .label,
      'Variantes',
    );
    expect(tester.takeException(), isNull);
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

  for (final width in [480.0, 1024.0]) {
    testWidgets('shell and resource cards stay usable at width $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final opened = <int>[];
      var navigations = 0;
      var builds = 0;
      await tester.pumpWidget(
        _app(
          StudioAppShell(
            projectName: 'Les Brumes de Selbrume',
            destinations: [
              StudioDestination(
                label: 'Carte',
                icon: Icons.map_outlined,
                selected: true,
                onTap: () => navigations++,
              ),
              StudioDestination(
                label: 'Personnages',
                icon: Icons.person_outline,
                onTap: () => navigations++,
              ),
            ],
            child: StudioResourceGrid(
              controller: controller,
              itemCount: 300,
              itemBuilder: (context, index) {
                builds++;
                return StudioResourceCard(
                  name: 'Ressource $index',
                  preview: const Icon(Icons.park_outlined),
                  category: 'Nature',
                  metadata: '32 × 32 · 256 tuiles',
                  selected: index == 0,
                  onTap: () => opened.add(index),
                );
              },
            ),
          ),
          textScale: 1.75,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(builds, lessThan(300));
      await tester.tap(find.text('Ressource 0'));
      expect(opened, [0]);
      await tester.tap(find.byTooltip('Personnages'));
      expect(navigations, 1);

      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(find.text('Ressource 299'), findsOneWidget);
      await tester.tap(find.text('Ressource 299'));
      expect(opened, [0, 299]);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
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
