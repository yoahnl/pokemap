import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_builder_page.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_graph_canvas.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

class Ui06SceneConstructionDriver {
  Ui06SceneConstructionDriver(this.tester, this.controller, this.views);
  final WidgetTester tester;
  final SceneWorkspaceController controller;
  final SceneBuilderViewStore views;
  Offset get origin =>
      tester.getTopLeft(find.byKey(const ValueKey('scene-graph-pan-surface')));
  SceneGraphViewport get viewport =>
      views.forScene(controller.active!.current.id).viewport;
  Future<void> tap(String label) async {
    final target = find.text(label).last;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> select(String label, String choice) async {
    final target = find.byWidgetPredicate(
      (w) => w is StudioSelect && w.label == label,
    );
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
    await tester.tap(find.text(choice).last);
    await tester.pumpAndSettle();
  }

  Future<void> node(String id) async {
    await tester.tap(find.byKey(ValueKey('scene-graph-node-drag-target-$id')));
    await tester.pumpAndSettle();
  }

  Future<void> clear() async {
    await tester.tapAt(origin + const Offset(850, 700));
    await tester.pumpAndSettle();
  }

  Future<void> move(String id, Offset position) async {
    final target = find.byKey(ValueKey('scene-graph-node-drag-target-$id'));
    final size = SceneCanvasGeometry(controller.active!.current).nodeSize(id);
    final gesture = await tester.startGesture(tester.getCenter(target));
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.moveTo(
      origin + viewport.worldToLocal(position + size.center(Offset.zero)),
    );
    await gesture.up();
    await tester.pumpAndSettle();
  }

  Future<String> add(
    SceneNodeKind kind,
    Offset position, {
    String? document,
  }) async {
    final before = controller.active!.current.graph.nodes
        .map((n) => n.id)
        .toSet();
    final palette = find.byKey(ValueKey('scene-palette-${kind.name}'));
    await tester.ensureVisible(palette);
    await tester.tap(palette);
    await tester.pumpAndSettle();
    if (document != null) {
      await tap(document);
    }
    if (kind == SceneNodeKind.action) {
      await select('Commande', 'Définir un Fact');
      await select('Fact', 'Départ autorisé');
      await tap('Ajouter l’action');
    }
    final id = controller.active!.current.graph.nodes
        .singleWhere((n) => !before.contains(n.id))
        .id;
    await move(id, position);
    return id;
  }

  Future<void> wire(String from, String port, String to) async {
    final before = controller.active!.current.graph.edges.length;
    final gesture = await tester.startGesture(
      tester.getCenter(
        find.byKey(ValueKey('scene-graph-output-port-$from-$port')),
      ),
    );
    await gesture.moveTo(
      tester.getCenter(find.byKey(ValueKey('scene-graph-input-port-$to-in'))),
    );
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.active!.error, isNull);
    expect(controller.active!.current.graph.edges, hasLength(before + 1));
  }
}
