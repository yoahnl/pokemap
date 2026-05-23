import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';

Future<void> _pumpInBridge(
  WidgetTester tester,
  Widget child, {
  required ThemeData theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme.copyWith(splashFactory: NoSplash.splashFactory),
      builder: (context, innerChild) {
        return PokeMapMacosCompatibilityBridge(
          child: innerChild ?? const SizedBox.shrink(),
        );
      },
      home: Scaffold(
        body: SizedBox(width: 320, child: child),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('ProjectExplorerModuleCard Widget Tests', () {
    testWidgets('renders basic properties (title, description, icon)', (tester) async {
      await _pumpInBridge(
        tester,
        const ProjectExplorerModuleCard(
          title: 'Tileset Studio',
          description: 'Custom Tileset Description',
          icon: CupertinoIcons.square_grid_2x2,
          accentColor: Colors.orange,
        ),
        theme: PokeMapTheme.light(),
      );

      expect(find.text('Tileset Studio'), findsOneWidget);
      expect(find.text('Custom Tileset Description'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.square_grid_2x2), findsOneWidget);
    });

    testWidgets('renders numeric count badge correctly', (tester) async {
      await _pumpInBridge(
        tester,
        const ProjectExplorerModuleCard(
          title: 'Narrative Unit',
          description: 'Description',
          icon: CupertinoIcons.link,
          accentColor: Colors.blue,
          count: 42,
        ),
        theme: PokeMapTheme.dark(),
      );

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('renders string countLabel badge correctly', (tester) async {
      await _pumpInBridge(
        tester,
        const ProjectExplorerModuleCard(
          title: 'Paths Unit',
          description: 'Description',
          icon: CupertinoIcons.arrow_branch,
          accentColor: Colors.green,
          countLabel: '4/12',
        ),
        theme: PokeMapTheme.dark(),
      );

      expect(find.text('4/12'), findsOneWidget);
    });

    testWidgets('triggers onTap and onExpandToggle callbacks', (tester) async {
      bool tapped = false;
      bool expandedToggled = false;

      await _pumpInBridge(
        tester,
        ProjectExplorerModuleCard(
          title: 'Interactive Card',
          description: 'Description',
          icon: CupertinoIcons.person,
          accentColor: Colors.red,
          onTap: () => tapped = true,
          onExpandToggle: () => expandedToggled = true,
          expanded: false,
          child: const Text('Expanded Content'),
        ),
        theme: PokeMapTheme.light(),
      );

      // Tap on title area (will fire onTap)
      await tester.tap(find.text('Interactive Card'));
      await tester.pump();
      expect(tapped, isTrue);

      // Tap on Chevron to toggle expansion (will fire onExpandToggle)
      await tester.tap(find.byIcon(CupertinoIcons.chevron_down));
      await tester.pump();
      expect(expandedToggled, isTrue);
    });

    testWidgets('renders children when expanded', (tester) async {
      await _pumpInBridge(
        tester,
        const ProjectExplorerModuleCard(
          title: 'Expanded Card',
          description: 'Description',
          icon: CupertinoIcons.person,
          accentColor: Colors.red,
          expanded: true,
          children: [
            Text('Child Item A'),
            Text('Child Item B'),
          ],
        ),
        theme: PokeMapTheme.light(),
      );

      expect(find.text('Child Item A'), findsOneWidget);
      expect(find.text('Child Item B'), findsOneWidget);
    });
  });

  group('ProjectExplorerPanel Integration Smoke Test', () {
    late Directory tempProjectRoot;

    setUp(() async {
      tempProjectRoot = await Directory.systemTemp.createTemp('explorer_panel_tests_');
      final yarn = File('${tempProjectRoot.path}/dialogues/pnj/dlg_hi.yarn');
      await yarn.parent.create(recursive: true);
      await yarn.writeAsString('title: Salut\n---\n<<jump End>>\n===\n');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    testWidgets('ProjectExplorerPanel renders all module cards', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const project = ProjectManifest(
        surfaceCatalog: ProjectSurfaceCatalog.empty(),
        name: 'test_project',
        maps: [
          ProjectMapEntry(
            id: 'map_1',
            name: 'Map One',
            relativePath: 'maps/map_1.json',
          ),
        ],
        tilesets: [
          ProjectTilesetEntry(
            id: 'tileset_1',
            name: 'Tileset One',
            relativePath: 'tilesets/1.png',
          ),
        ],
        terrainPresets: [],
        pathPresets: [],
        dialogueFolders: [],
        dialogues: [],
        scenarios: [],
      );

      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: tempProjectRoot.path,
        project: project,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: MaterialApp(
              theme: PokeMapTheme.dark(),
              home: const Scaffold(
                body: SizedBox(
                  width: 360,
                  height: 1000,
                  child: PokeMapMacosCompatibilityBridge(
                    child: ProjectExplorerPanel(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('World Explorer'), findsOneWidget);
      expect(find.text('Tileset Library'), findsOneWidget);
      expect(find.text('Catalogues Pokémon'), findsOneWidget);
      expect(find.text('Narrative Studio'), findsOneWidget);
      expect(find.text('World Maps'), findsOneWidget);
      expect(find.text('Terrain Library'), findsOneWidget);
      expect(find.text('Path Library'), findsOneWidget);
      expect(find.text('Environment Studio'), findsAtLeastNWidgets(1));
      expect(find.text('Trainer Studio'), findsAtLeastNWidgets(1));
      expect(find.text('Character Library'), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);
    });
  });
}
