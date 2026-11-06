import 'package:avelune_rendering/avelune_rendering.dart';
import 'package:avelune_studio/features/rendering/application/studio_rendering_preferences.dart';
import 'package:avelune_studio/presentation/features/rendering/studio_display_preferences.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_application_frame.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _destinations = [
  ('Accueil', 'home'),
  ('Carte', 'map'),
  ('Carte régionale', 'regionalMap'),
  ('Ressources', 'resources'),
  ('Histoire', 'story'),
  ('Pokémon', 'pokemon'),
  ('Réglages du projet', 'projectSettings'),
  ('Test du jeu', 'test'),
];

void main() {
  setUp(() => AveluneFrameRate.setLimit(60));
  tearDown(() => AveluneFrameRate.setLimit(60));

  for (final size in [const Size(1280, 720), const Size(960, 640)]) {
    testWidgets('eight destinations are named buttons with selection $size', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _mount(tester, size, active: 'map');
      for (final (label, _) in _destinations) {
        expect(
          tester.getSemantics(
            find.descendant(of: _entry(label), matching: find.byType(InkWell)),
          ),
          isSemantics(
            label: label,
            isButton: true,
            isSelected: label == 'Carte',
            hasEnabledState: true,
            isEnabled: label != 'Test du jeu',
          ),
          reason: label,
        );
      }
      handle.dispose();
    });

    testWidgets('selection is shown by a marker, not only colour $size', (
      tester,
    ) async {
      await _mount(tester, size, active: 'regionalMap');
      final markers = find.byKey(
        const ValueKey('studio-navigation-selected-marker'),
      );
      expect(markers, findsOneWidget);
      expect(
        find.descendant(of: _entry('Carte régionale'), matching: markers),
        findsOneWidget,
      );
    });

    testWidgets('keyboard reaches and opens every destination $size', (
      tester,
    ) async {
      final opened = <String>[];
      await _mount(
        tester,
        size,
        active: 'home',
        canTest: true,
        onDestination: opened.add,
      );
      final reached = <String>{};
      for (var i = 0; i < 40 && reached.length < _destinations.length; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final focused = _focusedDestination(tester);
        if (focused != null) reached.add(focused);
      }
      expect(reached, {for (final (label, _) in _destinations) label});
      await _tabTo(tester, 'Pokémon');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(opened, ['pokemon']);
    });
  }

  testWidgets('keyboard focus draws a visible ring on the destination', (
    tester,
  ) async {
    await _mount(tester, const Size(1280, 720), active: 'home');
    expect(_ring('Ressources'), findsNothing);
    await _tabTo(tester, 'Ressources');
    expect(_ring('Ressources'), findsOneWidget);
    expect(_ring('Carte'), findsNothing);
  });

  testWidgets('unavailable destination explains why it is unavailable', (
    tester,
  ) async {
    await _mount(tester, const Size(1280, 720), active: 'home');
    expect(
      find.byTooltip(
        'Test du jeu — ouvrez une carte du projet pour lancer un test',
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Ressources'), findsOneWidget);
  });

  testWidgets('escape closes a modal, keeps the draft and returns focus', (
    tester,
  ) async {
    final preferences = StudioRenderingPreferences(_Store());
    addTearDown(preferences.dispose);
    final draft = TextEditingController();
    addTearDown(draft.dispose);
    await _mount(
      tester,
      const Size(1280, 720),
      active: 'map',
      preferences: preferences,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: TextField(
          key: const ValueKey('business-draft'),
          controller: draft,
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('business-draft')),
      'Bourg',
    );
    final trigger = find.byTooltip('Affichage');
    final triggerFocus = Focus.of(
      tester.element(
        find.descendant(of: trigger, matching: find.byType(Icon)).first,
      ),
    );
    triggerFocus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(
      find.byTooltip('Fermer les préférences d’affichage'),
      findsOneWidget,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Fermer les préférences d’affichage'), findsNothing);
    expect(draft.text, 'Bourg');
    expect(triggerFocus.hasFocus, isTrue);
  });
}

Future<void> _tabTo(WidgetTester tester, String label) async {
  for (var i = 0; i < 40; i++) {
    if (_focusedDestination(tester) == label) return;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  fail('$label never received keyboard focus');
}

Finder _entry(String label) => find.byKey(ValueKey('studio-navigation-$label'));

Finder _ring(String label) => find.descendant(
  of: _entry(label),
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is Material &&
        widget.shape is RoundedRectangleBorder &&
        (widget.shape! as RoundedRectangleBorder).side.width == 2,
  ),
);

String? _focusedDestination(WidgetTester tester) {
  final focus = FocusManager.instance.primaryFocus?.context;
  if (focus == null) return null;
  for (final (label, _) in _destinations) {
    final entry = _entry(label);
    if (entry.evaluate().isEmpty) continue;
    final element = entry.evaluate().single;
    var inside = false;
    focus.visitAncestorElements((ancestor) {
      if (ancestor == element) {
        inside = true;
        return false;
      }
      return true;
    });
    if (inside) return label;
  }
  return null;
}

Future<void> _mount(
  WidgetTester tester,
  Size size, {
  required String active,
  ValueChanged<String>? onDestination,
  bool canTest = false,
  StudioRenderingPreferences? preferences,
  Widget child = const SizedBox.expand(),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final search = TextEditingController();
  addTearDown(search.dispose);
  final app = MaterialApp(
    theme: studioTheme(),
    home: StudioApplicationFrame(
      search: search,
      onSearch: (_) {},
      onDestination: onDestination ?? (_) {},
      projectName: 'Projet de test',
      active: active,
      canTest: canTest,
      child: child,
    ),
  );
  await tester.pumpWidget(
    preferences == null
        ? app
        : StudioRenderingPreferencesScope(preferences: preferences, child: app),
  );
  await tester.pumpAndSettle();
  expect(find.byType(StudioPrimaryNavigation), findsOneWidget);
}

final class _Store implements StudioRenderingPreferencesStore {
  @override
  Future<int?> load() async => null;

  @override
  Future<void> save(int limit) async {}
}
