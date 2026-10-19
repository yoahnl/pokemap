import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/map_workspace/workspace_resource_diagnostic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/scoped_map_workspace_port.dart';

void main() {
  testWidgets(
    'map rendering follows its selection and complete workshops require an explicit choice',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1500, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final port = ScopedTestMapPort();
      final controller = MapWorkspaceController(scopedMapSession, port);
      addTearDown(controller.dispose);
      final visualContexts = <List<String>>[];
      final visuals = <_Visuals>[];
      await tester.pumpWidget(
        MaterialApp(
          home: MapWorkspaceScreen(
            controller: controller,
            loadVisuals:
                (ProjectSession session, ProjectManifest project) async {
                  visualContexts.add(
                    project.tilesets.map((item) => item.id).toList(),
                  );
                  final instance = _Visuals(visualContexts);
                  visuals.add(instance);
                  return instance;
                },
            runtimeBuilder: (_, _, _) => const SizedBox(),
            onClose: () async {},
            registerExitGuard: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(port.fullReads, 0);
      expect(visualContexts.single, ['first']);
      final delayed = Completer<void>();
      visuals.first.nextUpdate = delayed;
      await controller.activate(secondScopedMap);
      await tester.pump();
      await controller.activate(firstScopedMap);
      await tester.pump();
      delayed.complete();
      await tester.pumpAndSettle();
      expect(visualContexts.last, ['first']);
      await controller.activate(secondScopedMap);
      await tester.pumpAndSettle();
      expect(visualContexts.last, ['second']);
      expect(find.text('Carte second'), findsWidgets);
      await tester.tap(
        find.byKey(const ValueKey('workspace-materialize-workshops')),
      );
      await tester.pumpAndSettle();
      expect(port.fullReads, 0);
      expect(
        find.text('Charger tous les ateliers du projet ?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Charger les ateliers'));
      await tester.pumpAndSettle();
      expect(port.fullReads, 1);
      expect(visualContexts.last, ['first', 'second']);
      expect(visuals.first.disposed, isTrue);
      expect(controller.active?.base.mapId, 'second');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

class _Visuals extends ChangeNotifier
    implements MapWorkspaceVisuals, ResourceWorkspaceVisuals {
  _Visuals(this.contexts);
  final List<List<String>> contexts;
  bool disposed = false;
  Completer<void>? nextUpdate;
  @override
  Future<void> updateCatalog(
    ProjectManifest manifest, {
    Set<String> changedRelativePaths = const {},
  }) async {
    final delayed = nextUpdate;
    nextUpdate = null;
    await delayed?.future;
    contexts.add(manifest.tilesets.map((e) => e.id).toList());
  }

  @override
  Widget canvas(
    MapData map, {
    MapPlacedElement? placedElementPreview,
    Color? collisionColor,
  }) => Text('Carte ${map.id}');
  @override
  List<WorkspaceResourceDiagnostic> get diagnostics => const [];
  @override
  Set<String> get activeResourceIds => const {};
  @override
  List<String> get warnings => const [];
  @override
  void setActiveMap(MapData map) {}
  @override
  void setBrush(ProjectElementEntry? element, TileLayerPaletteEntry? tile) {}
  @override
  void setTerrainBrush(ProjectSmartTilePreset? preset) {}
  @override
  Future<void> retryResources(Iterable<String> resourceIds) async {}
  @override
  Widget thumbnail(ProjectElementEntry element, {double size = 48}) =>
      const SizedBox();
  @override
  Widget placementPreview(ProjectElementEntry element, Size size) =>
      const SizedBox();
  @override
  Widget tileThumbnail(TileLayerPaletteEntry tile, {double size = 48}) =>
      const SizedBox();
  @override
  Widget atlasPreview(String tilesetId) => const SizedBox();
  @override
  Future<void> dispose() async {
    disposed = true;
    super.dispose();
  }
}
