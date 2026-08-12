import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';

void main() {
  testWidgets('offers guided presets and a project-default reset', (
    tester,
  ) async {
    ProjectPresentationWindowsProfile? value;
    await tester.pumpWidget(
      _app(
        ProjectWindowStudio(
          profile: legacyProjectPresentationWindows,
          onChanged: (next) => value = next,
        ),
      ),
    );

    expect(find.text('Classique PokeMap'), findsOneWidget);
    expect(find.text('Compact lisible'), findsOneWidget);
    expect(find.text('Doux'), findsOneWidget);
    expect(find.text('Contour renforcé'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('window-preset-compact')),
    );
    expect(value, compactProjectWindowStylePreset.profile);

    await tester.tap(
      find.byKey(const ValueKey<String>('window-reset-project')),
    );
    expect(value, isNull);
  });

  testWidgets('edits Pause and Dialogue as independent targets', (
    tester,
  ) async {
    ProjectPresentationWindowsProfile? value;
    await tester.pumpWidget(
      _app(
        ProjectWindowStudio(
          profile: legacyProjectPresentationWindows,
          onChanged: (next) => value = next,
        ),
      ),
    );

    _changeDropdown<int>(
      tester,
      const ValueKey<String>('window-field-corner-radius'),
      24,
    );
    expect(value?.resolve(ProjectWindowRole.pauseMenu).cornerRadius, 24);
    expect(value?.resolve(ProjectWindowRole.dialogue).cornerRadius, 16);

    await tester.tap(
      find.byKey(const ValueKey<String>('window-target-dialogue')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('window-field-backdrop')),
      findsNothing,
    );

    _changeDropdown<int>(
      tester,
      const ValueKey<String>('window-field-content-padding'),
      12,
    );
    expect(value?.resolve(ProjectWindowRole.dialogue).contentPadding, 12);
  });

  testWidgets('authors every role and isolates a capsule from battle', (
    tester,
  ) async {
    ProjectPresentationWindowsProfile profile =
        legacyProjectPresentationWindows;
    late StateSetter setHostState;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return ProjectWindowStudio(
              profile: profile,
              onChanged: (next) => setHostState(
                () => profile = next ?? legacyProjectPresentationWindows,
              ),
            );
          },
        ),
      ),
    );

    for (final role in <String>['standard', 'pause', 'dialogue', 'battle']) {
      expect(
        find.byKey(ValueKey<String>('window-target-$role')),
        findsOneWidget,
      );
    }

    await tester.tap(
      find.byKey(const ValueKey<String>('window-target-standard')),
    );
    await tester.pump();
    _changeDropdown<ProjectWindowShape>(
      tester,
      const ValueKey<String>('window-field-shape'),
      ProjectWindowShape.capsule,
    );
    await tester.pump();

    expect(
      profile.resolve(ProjectWindowRole.standard).shape,
      ProjectWindowShape.capsule,
    );
    expect(
      profile.resolve(ProjectWindowRole.battle).shape,
      ProjectWindowShape.rounded,
    );
    expect(
      validateProjectPresentationProfile(
        ProjectPresentationProfile(windows: profile),
      ),
      isEmpty,
    );
  });

  testWidgets('remains usable at 200 percent text scale', (tester) async {
    tester.view.physicalSize = const Size(720, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        ProjectWindowStudio(
          profile: softProjectWindowStylePreset.profile,
          onChanged: (_) {},
        ),
        textScaler: const TextScaler.linear(2),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('window-field-corner-radius')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('authors dialogue silhouettes and fill opacity', (tester) async {
    ProjectPresentationWindowsProfile? value;
    await tester.pumpWidget(
      _app(
        ProjectWindowStudio(
          profile: legacyProjectPresentationWindows,
          fixedRole: ProjectWindowRole.dialogue,
          onChanged: (next) => value = next,
        ),
      ),
    );

    _changeDropdown<ProjectWindowShape>(
      tester,
      const ValueKey<String>('window-field-shape'),
      ProjectWindowShape.speech,
    );
    expect(
      value?.resolve(ProjectWindowRole.dialogue).shape,
      ProjectWindowShape.speech,
    );

    _changeDropdown<double>(
      tester,
      const ValueKey<String>('window-field-fill-opacity'),
      .8,
    );
    expect(value?.resolve(ProjectWindowRole.dialogue).fillOpacity, .8);
  });

  testWidgets('offers both supported fill opacity boundaries', (tester) async {
    ProjectPresentationWindowsProfile? value;
    await tester.pumpWidget(
      _app(
        ProjectWindowStudio(
          profile: legacyProjectPresentationWindows,
          fixedRole: ProjectWindowRole.dialogue,
          onChanged: (next) => value = next,
        ),
      ),
    );

    _changeDropdown<double>(
      tester,
      const ValueKey<String>('window-field-fill-opacity'),
      projectWindowMinFillOpacity,
    );
    expect(
      value?.resolve(ProjectWindowRole.dialogue).fillOpacity,
      projectWindowMinFillOpacity,
    );
    _changeDropdown<double>(
      tester,
      const ValueKey<String>('window-field-fill-opacity'),
      projectWindowMaxFillOpacity,
    );
    expect(
      value?.resolve(ProjectWindowRole.dialogue).fillOpacity,
      projectWindowMaxFillOpacity,
    );
  });

  testWidgets('hides shapes that are invalid for a multiline Pause window', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        ProjectWindowStudio(
          profile: legacyProjectPresentationWindows,
          fixedRole: ProjectWindowRole.pauseMenu,
          onChanged: (_) {},
        ),
      ),
    );

    final dropdown = tester.widget<DropdownButton<ProjectWindowShape>>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('window-field-shape')),
        matching: find.byType(DropdownButton<ProjectWindowShape>),
      ),
    );
    final values = dropdown.items!.map((item) => item.value).toSet();

    expect(values, contains(ProjectWindowShape.rectangle));
    expect(values, contains(ProjectWindowShape.rounded));
    expect(values, contains(ProjectWindowShape.cutCorner));
    expect(values, isNot(contains(ProjectWindowShape.speech)));
    expect(values, isNot(contains(ProjectWindowShape.capsule)));
  });

  testWidgets('opens every valid custom measure from a reloaded project', (
    tester,
  ) async {
    const custom = ProjectPresentationWindowsProfile(
      styles: <ProjectWindowStyleProfile>[
        ProjectWindowStyleProfile(
          id: 'custom',
          fillToken: 'menuSurface',
          borderToken: 'outline',
          borderWidth: 3,
          cornerRadius: 13,
          contentPadding: 13,
          shadowElevation: 5,
          fillOpacity: .82,
        ),
      ],
      defaultStyleId: 'custom',
      pauseMenuStyleId: 'custom',
      dialogueStyleId: 'custom',
      battleStyleId: 'custom',
      pauseBackdropOpacity: .73,
    );

    await tester.pumpWidget(
      _app(
        ProjectWindowStudio(
          profile: custom,
          fixedRole: ProjectWindowRole.pauseMenu,
          onChanged: (_) {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(_dropdownValue<double>(tester, 'window-field-fill-opacity'), .82);
    expect(_dropdownValue<int>(tester, 'window-field-corner-radius'), 13);
    expect(_dropdownValue<int>(tester, 'window-field-content-padding'), 13);
    expect(_dropdownValue<int>(tester, 'window-field-shadow'), 5);
    expect(_dropdownValue<double>(tester, 'window-field-backdrop'), .73);
  });
}

T? _dropdownValue<T>(WidgetTester tester, String key) => tester
    .widget<DropdownButton<T>>(
      find.descendant(
        of: find.byKey(ValueKey<String>(key)),
        matching: find.byType(DropdownButton<T>),
      ),
    )
    .value;

void _changeDropdown<T>(WidgetTester tester, Key fieldKey, T value) {
  final dropdown = tester.widget<DropdownButton<T>>(
    find.descendant(
      of: find.byKey(fieldKey),
      matching: find.byType(DropdownButton<T>),
    ),
  );
  dropdown.onChanged!(value);
}

Widget _app(Widget child, {TextScaler textScaler = TextScaler.noScaling}) =>
    MaterialApp(
      theme: PokeMapTheme.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
