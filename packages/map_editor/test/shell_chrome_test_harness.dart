import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, MaterialApp, SizedBox;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:map_core/map_core.dart';
import 'package:map_editor/main.dart' show MapEditorApp;
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor_updates/application/editor_update_providers.dart';
import 'package:map_editor/src/infrastructure/riverpod_retry_policy.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/editor_canvas_host.dart';
import 'package:map_editor/src/ui/editor_shell_page.dart';
import 'package:map_editor/src/ui/shared/status_bar.dart';
import 'package:map_editor/src/ui/shared/top_toolbar.dart';
import 'package:pub_semver/pub_semver.dart';

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
  List<EnvironmentPreset> environmentPresets = const <EnvironmentPreset>[],
  List<ProjectElementEntry> elements = const <ProjectElementEntry>[],
  List<ProjectEncounterTable> encounterTables = const <ProjectEncounterTable>[],
}) {
  return ProjectManifest(
    name: name,
    version: ProjectVersion.v6,
    maps: maps,
    tilesets: tilesets,
    environmentPresets: environmentPresets,
    elements: elements,
    encounterTables: encounterTables,
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
    version: ProjectVersion.v6,
    size: GridSize(width: width, height: height),
    layers: layers,
  );
}

Future<ProviderContainer> pumpEditorShellPage(
  WidgetTester tester, {
  required EditorState initialState,
  Size surfaceSize = const Size(1800, 1000),
  bool useLightTheme = false,
  String? fontFamily,
  String? cupertinoFontFamily,
  List<Override> overrides = const <Override>[],
  bool settleInitialFrame = true,
  bool useMapEditorApp = false,
  bool enableEditorUpdateHost = true,
  bool restoreLastOpenedProjectOnStartup = true,
}) async {
  _installMacosAccentColorMock();
  final container = ProviderContainer(
    overrides: overrides,
    retry: disableAutomaticProviderRetry,
  );
  final editorStateSubscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, _) {},
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

  final baseTheme = useLightTheme ? PokeMapTheme.light() : PokeMapTheme.dark();
  final theme = fontFamily == null
      ? baseTheme
      : baseTheme.copyWith(
          textTheme: baseTheme.textTheme.apply(fontFamily: fontFamily),
          primaryTextTheme: baseTheme.primaryTextTheme.apply(
            fontFamily: fontFamily,
          ),
        );
  final shell = EditorShellPage(
    restoreLastOpenedProjectOnStartup: restoreLastOpenedProjectOnStartup,
  );
  final app = useMapEditorApp
      ? MapEditorApp(
          enableEditorUpdateHost: enableEditorUpdateHost,
          restoreLastOpenedProjectOnStartup:
              restoreLastOpenedProjectOnStartup,
        )
      : MaterialApp(
        theme: theme,
        builder: (context, child) {
          Widget result = PokeMapMacosCompatibilityBridge(
            child: child ?? const SizedBox.shrink(),
          );
          if (cupertinoFontFamily != null) {
            final cupertinoTheme = CupertinoTheme.of(context);
            result = CupertinoTheme(
              data: cupertinoTheme.copyWith(
                textTheme: _cupertinoTextThemeWithFontFamily(
                  cupertinoTheme.textTheme,
                  cupertinoTheme.primaryColor,
                  cupertinoFontFamily,
                ),
              ),
              child: result,
            );
          }
          return result;
        },
        home: shell,
      );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: app,
    ),
  );
  await tester.pump();
  if (settleInitialFrame) {
    await tester.pumpAndSettle(const Duration(milliseconds: 1));
  } else {
    await tester.pump(const Duration(milliseconds: 220));
  }
  if (fontFamily != null) {
    final context = tester.element(find.byType(EditorShellPage));
    await tester.runAsync(() async {
      for (final asset in const <String>[
        'assets/branding/pokemap_event_builder_mark.png',
        'assets/branding/pokemap_event_builder_project_thumb.png',
      ]) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    await tester.pump();
  }
  return container;
}

CupertinoTextThemeData _cupertinoTextThemeWithFontFamily(
  CupertinoTextThemeData source,
  Color primaryColor,
  String fontFamily,
) {
  TextStyle withFamily(TextStyle style) =>
      style.copyWith(fontFamily: fontFamily);

  return CupertinoTextThemeData(
    primaryColor: primaryColor,
    textStyle: withFamily(source.textStyle),
    actionTextStyle: withFamily(source.actionTextStyle),
    actionSmallTextStyle: withFamily(source.actionSmallTextStyle),
    tabLabelTextStyle: withFamily(source.tabLabelTextStyle),
    navTitleTextStyle: withFamily(source.navTitleTextStyle),
    navLargeTitleTextStyle: withFamily(source.navLargeTitleTextStyle),
    navActionTextStyle: withFamily(source.navActionTextStyle),
    pickerTextStyle: withFamily(source.pickerTextStyle),
    dateTimePickerTextStyle: withFamily(source.dateTimePickerTextStyle),
  );
}

Future<ProviderContainer> pumpEditorCanvasHostHarness(
  WidgetTester tester, {
  required EditorState initialState,
  Size surfaceSize = const Size(960, 640),
  bool useLightTheme = false,
  List<Override> overrides = const <Override>[],
}) async {
  _installMacosAccentColorMock();
  final container = ProviderContainer(overrides: overrides);
  final editorStateSubscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, _) {},
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
        theme: useLightTheme ? PokeMapTheme.light() : PokeMapTheme.dark(),
        builder: (context, child) {
          return PokeMapMacosCompatibilityBridge(
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const CupertinoPageScaffold(child: EditorCanvasHost()),
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
    (_, _) {},
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
        // Contextual pulldowns use Material's PopupMenuButton through the
        // macOS compatibility shim, so the isolated toolbar needs this sheet.
        home: const Material(child: _TopToolbarHarness()),
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
  final container = ProviderContainer(
    overrides: [
      editorInstalledVersionProvider.overrideWith(
        (ref) async => Version.parse('0.3.0'),
      ),
    ],
  );
  final editorStateSubscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, _) {},
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
        child: TopToolbar(key: Key('top-toolbar-under-test')),
      ),
    );
  }
}

class _StatusBarHarness extends StatelessWidget {
  const _StatusBarHarness();

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      child: Align(alignment: Alignment.bottomCenter, child: StatusBar()),
    );
  }
}
