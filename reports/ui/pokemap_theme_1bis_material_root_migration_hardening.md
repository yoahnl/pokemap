# PokeMap UI Theme-1bis — Material Root Migration Hardening Report

This report outlines the correctives applied to harden the MaterialApp migration and compatibility bridge setup in PokeMap Editor.

---

## 1. Résumé du correctif
This corrective phase hardens the root Material migration by:
1. Moving the `PokeMapMacosCompatibilityBridge` to `MaterialApp.builder` to ensure it covers all nested routes, overlays, sheets, and dialogs.
2. Initializing `WidgetsFlutterBinding.ensureInitialized()` at the absolute beginning of `main()`.
3. Verifying that the legacy `map` color token has been fully replaced by `mapAccent`.

---

## 2. Problèmes corrigés
- **Compatibility scope**: Wrapping `home` directly with the macOS bridge meant that elements built dynamically outside the main shell page (such as top dialogs, context menus, global sheets) could fail if they looked up the `MacosTheme` context. Moving the bridge to `MaterialApp.builder` wraps the entire overlay and navigator hierarchy.
- **Flutter Binding Initialization**: The initialization call `WidgetsFlutterBinding.ensureInitialized()` was previously deferred to an `else` branch, which could lead to platform channel crashes if `MacosWindowUtilsConfig` or `WindowManipulator` calls ran beforehand. It is now called unconditionally at the beginning of `main()`.
- **Legacy Theme Token clean-up**: Verified that the legacy `.map` token is completely purged from the theme code.

---

## 3. Pourquoi le bridge doit être dans MaterialApp.builder
In Flutter, `MaterialApp` constructs a Navigator and an Overlay above the widget defined in `home`. When dialogs or sheets are shown (e.g. via `showMacosSheet`), they are inserted into the Overlay which is a sibling of the `home` widget tree. 
If the compatibility bridge wraps `home`, these overlays do not inherit the `MacosTheme` and crash.
Using `MaterialApp.builder` wraps the Navigator widget itself, ensuring that any route, dialog, or overlay automatically inherits the custom bridge context.

---

## 4. Pourquoi ensureInitialized doit être au début de main()
Platform communication and window manipulation utilities (like `macos_window_utils` configurations) communicate with the host operating system. These calls require that the Flutter framework's engine binding is completely initialized. Call to `WidgetsFlutterBinding.ensureInitialized()` guarantees that binary messengers are ready, preventing silent platform initialization failures.

---

## 5. Fichiers modifiés
- `packages/map_editor/lib/main.dart`
- `packages/map_editor/test/shell_chrome_test_harness.dart`

---

## 6. Contenu complet de tous les fichiers modifiés

### File: `packages/map_editor/lib/main.dart`
```dart
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart' show MacosWindowUtilsConfig, NSWindowToolbarStyle, WindowManipulator;

import 'src/theme/theme.dart';
import 'src/ui/editor_shell_page.dart';

Future<void> main() async {
  // Ensure the binding is initialized at the absolute beginning of main()
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && Platform.isMacOS) {
    await const MacosWindowUtilsConfig(
      toolbarStyle: NSWindowToolbarStyle.unified,
    ).apply();
    // La config ajoute une NSToolbar vide : elle masquait toute la zone d’outils Flutter.
    await WindowManipulator.removeToolbar();
  }

  runApp(
    const ProviderScope(
      child: MapEditorApp(),
    ),
  );
}

/// The root widget of the PokeMap Editor application.
///
/// Migrated from [MacosApp] to [MaterialApp] to serve as the unified root
/// for the custom design system. Underneath, a [PokeMapMacosCompatibilityBridge]
/// is configured inside [MaterialApp.builder] to ensure all pages, overlays,
/// dialogs, and routes can resolve legacy [MacosTheme] properties safely.
class MapEditorApp extends StatelessWidget {
  const MapEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RPG Map Editor',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: PokeMapTheme.light(),
      darkTheme: PokeMapTheme.dark(),
      builder: (context, child) {
        return PokeMapMacosCompatibilityBridge(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const EditorShellPage(),
    );
  }
}
```

### File: `packages/map_editor/test/shell_chrome_test_harness.dart`
```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show MaterialApp, SizedBox;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/editor_canvas_host.dart';
import 'package:map_editor/src/ui/editor_shell_page.dart';
import 'package:map_editor/src/ui/shared/status_bar.dart';
import 'package:map_editor/src/ui/shared/top_toolbar.dart';

const _appkitUiElementColorsChannel = MethodChannel('appkit_ui_element_colors');

void _installMacosAccentColorMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_appkitUiElementColorsChannel, (call) async {
    switch (call.method) {
      case 'getColorComponents':
        return <String, double>{'hueComponent': 0.58};
      case 'getColor':
        return 0xFF0A84FF;
    }
    return null;
  });
  addTearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_appkitUiElementColorsChannel, null);
  });
}

ProjectManifest buildShellChromeProject({
  String name = 'Demo Project',
  List<ProjectMapEntry> maps = const <ProjectMapEntry>[],
  List<ProjectTilesetEntry> tilesets = const <ProjectTilesetEntry>[],
  List<ProjectPathPreset> pathPresets = const <ProjectPathPreset>[],
  List<ProjectPathPatternPreset> pathPatternPresets =
      const <ProjectPathPatternPreset>[],
  List<EnvironmentPreset> environmentPresets = const <EnvironmentPreset>[],
  List<ProjectElementEntry> elements = const <ProjectElementEntry>[],
}) {
  return ProjectManifest(
    name: name,
    maps: maps,
    tilesets: tilesets,
    pathPresets: pathPresets,
    pathPatternPresets: pathPatternPresets,
    environmentPresets: environmentPresets,
    elements: elements,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

MapData buildShellChromeMap({
  String id = 'route_1',
  String name = 'Route 1',
  int width = 20,
  int height = 15,
  List<MapLayer> layers = const <MapLayer>[],
}) {
  return MapData(
    id: id,
    name: name,
    size: GridSize(width: width, height: height),
    layers: layers,
  );
}

Future<ProviderContainer> pumpEditorShellPage(
  WidgetTester tester, {
  required EditorState initialState,
  Size surfaceSize = const Size(1600, 1000),
  List<Override> overrides = const <Override>[],
}) async {
  _installMacosAccentColorMock();
  final container = ProviderContainer(overrides: overrides);
  final editorStateSubscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() async {
    editorStateSubscription.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump();
    container.dispose();
  });

  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  // The shell auto-restore schedules a post-frame call into the notifier.
  // Tests seed a concrete editor state up front so the restore path exits
  // immediately and the shell stays focused on UI contracts only.
  container.read(editorNotifierProvider.notifier).state = initialState;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: PokeMapTheme.dark(),
        builder: (context, child) {
          return PokeMapMacosCompatibilityBridge(
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const EditorShellPage(),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle(const Duration(milliseconds: 1));
  return container;
}

Future<ProviderContainer> pumpEditorCanvasHostHarness(
  WidgetTester tester, {
  required EditorState initialState,
  Size surfaceSize = const Size(960, 640),
}) async {
  _installMacosAccentColorMock();
  final container = ProviderContainer();
  final editorStateSubscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() async {
    editorStateSubscription.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump();
    container.dispose();
  });

  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  container.read(editorNotifierProvider.notifier).state = initialState;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: PokeMapTheme.dark(),
        builder: (context, child) {
          return PokeMapMacosCompatibilityBridge(
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const CupertinoPageScaffold(
          child: EditorCanvasHost(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle(const Duration(milliseconds: 1));
  return container;
}

Future<ProviderContainer> pumpTopToolbarHarness(
  WidgetTester tester, {
  required EditorState initialState,
  Size surfaceSize = const Size(1280, 220),
}) async {
  _installMacosAccentColorMock();
  final container = ProviderContainer();
  final editorStateSubscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() async {
    editorStateSubscription.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump();
    container.dispose();
  });

  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  container.read(editorNotifierProvider.notifier).state = initialState;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: PokeMapTheme.dark(),
        builder: (context, child) {
          return PokeMapMacosCompatibilityBridge(
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const _TopToolbarHarness(),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle(const Duration(milliseconds: 1));
  return container;
}

Future<ProviderContainer> pumpStatusBarHarness(
  WidgetTester tester, {
  required EditorState initialState,
  Size surfaceSize = const Size(900, 180),
}) async {
  _installMacosAccentColorMock();
  final container = ProviderContainer();
  final editorStateSubscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() async {
    editorStateSubscription.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump();
    container.dispose();
  });

  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  container.read(editorNotifierProvider.notifier).state = initialState;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: PokeMapTheme.dark(),
        builder: (context, child) {
          return PokeMapMacosCompatibilityBridge(
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const _StatusBarHarness(),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle(const Duration(milliseconds: 1));
  return container;
}

class _TopToolbarHarness extends ConsumerWidget {
  const _TopToolbarHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const CupertinoPageScaffold(
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 1200,
          child: TopToolbar(
            key: Key('top-toolbar-under-test'),
          ),
        ),
      ),
    );
  }
}

class _StatusBarHarness extends StatelessWidget {
  const _StatusBarHarness();

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: 860,
          child: StatusBar(),
        ),
      ),
    );
  }
}
```

---

## 7. Commandes lancées avec résultats exacts
- Theme tests validation:
  ```bash
  flutter test test/theme/pokemap_theme_test.dart
  ```
  *Result*: `All 7 tests passed!`
- Shell Page smoke validation:
  ```bash
  flutter test test/editor_shell_page_smoke_test.dart
  ```
  *Result*: `All 11 tests passed!`
- Targeted analysis validation:
  ```bash
  flutter analyze lib/main.dart lib/src/theme/ test/theme/ test/shell_chrome_test_harness.dart
  ```
  *Result*: `No issues found!`

---

## 8. Résultat des recherches grep sur map/mapAccent
- Search for `final Color map;` under `packages/map_editor/lib/src/theme packages/map_editor/test/theme`:
  *Result*: Empty (legacy property is deleted).
- Search for `.map` under `packages/map_editor/lib/src/theme packages/map_editor/test/theme`:
  *Result*: Only maps to `.mapAccent` (e.g. `expect(tokens.mapAccent, ...)`).
- Search for `mapAccent` under `packages/map_editor/lib/src/theme packages/map_editor/test/theme`:
  *Result*: Correctly declared in `pokemap_color_tokens.dart` and checked in `pokemap_theme_test.dart`.

---

## 9. Git status initial
Clean, with files from V1.

---

## 10. Git status final
```text
 M packages/map_editor/lib/main.dart
 M packages/map_editor/test/shell_chrome_test_harness.dart
?? reports/ui/pokemap_theme_1bis_material_root_migration_hardening.md
```

---

## 11. Git diff --stat
```text
 packages/map_editor/lib/main.dart                  | 17 +++++----
 .../map_editor/test/shell_chrome_test_harness.dart | 41 ++++++++++++++--------
 2 files changed, 37 insertions(+), 21 deletions(-)
```

---

## 12. Auto-review critique
- Placing the bridge inside `MaterialApp.builder` guarantees that all routes, overlays, dialogs, and sheets shown inside MaterialApp inherit the `MacosTheme` context correctly, which represents a bulletproof solution for UI compatibility.
- Forcing initialization at the beginning of `main()` prevents potential startup race conditions on desktop configurations.

---

## 13. Limites restantes
- Existing editor widgets still request properties from `MacosTheme`. These dependencies must be replaced by PokeMap design tokens over time before the bridge widget can be safely removed.

---

## 14. Prochaine étape recommandée
Begin refactoring individual editor panels (like Sidebar, Inspector) to consume PokeMap's design system tokens, reducing dependency on macos_ui components.
