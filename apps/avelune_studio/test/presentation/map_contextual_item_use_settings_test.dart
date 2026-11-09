import 'package:avelune_studio/presentation/features/map_workspace/map_escape_rope_settings.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_toggle_row.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  testWidgets(
    'guided item scene cell and direction produce canonical metadata',
    (tester) async {
      tester.view.resetPhysicalSize();
      tester.view.physicalSize = const Size(1200, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Map<String, Object?>? saved;
      var loads = 0;
      final project = ProjectManifest(
        name: 'Alpha',
        maps: [],
        tilesets: [],
        scenes: [
          SceneAsset(
            id: 'wall-scene',
            name: 'Ouvrir le mur',
            graph: SceneGraph(
              startNodeId: 'start',
              nodes: [
                SceneNode(id: 'start', kind: SceneNodeKind.start),
                SceneNode(id: 'end', kind: SceneNodeKind.end),
              ],
              edges: [
                SceneEdge(
                  id: 'edge',
                  fromNodeId: 'start',
                  fromPortId: 'completed',
                  toNodeId: 'end',
                  kind: SceneEdgeKind.defaultFlow,
                ),
              ],
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showEscapeRopeMapSettings(
                  context,
                  map: const MapData(
                    id: 'alpha',
                    name: 'Alpha',
                    size: GridSize(width: 12, height: 12),
                  ),
                  project: project,
                  loadItems: () async {
                    loads++;
                    return {'rope': 'Corde Sortie'};
                  },
                  save: (values) async {
                    saved = values;
                    return null;
                  },
                ),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      expect(loads, 0);
      await tester.tap(find.text('Configurer les objets dans le décor'));
      await tester.pumpAndSettle();
      expect(loads, 1);
      await tester.tap(find.text('Ajouter une utilisation'));
      await tester.pumpAndSettle();
      Future<void> choose(String label, String value) async {
        final field = find.byWidgetPredicate(
          (widget) => widget is StudioSelect && widget.label == label,
        );
        await tester.ensureVisible(field);
        await tester.tap(field);
        await tester.pumpAndSettle();
        await tester.tap(find.text(value).last);
        await tester.pumpAndSettle();
      }

      await choose('Objet 1', 'Corde Sortie');
      await choose('Scène 1', 'Ouvrir le mur');
      final precise = find.byWidgetPredicate(
        (widget) =>
            widget is StudioToggleRow && widget.label == 'Sur une case précise',
      );
      await tester.ensureVisible(precise);
      await tester.tap(precise);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), '6');
      await tester.enterText(find.byType(TextField).at(1), '3');
      await choose('Direction 1', 'Nord');
      await tester.enterText(find.byType(TextField).at(2), '10');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Appliquer aux paramètres'));
      await tester.tap(find.text('Appliquer aux paramètres'));
      await tester.pumpAndSettle();
      expect(saved, isNull);
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      final rules = saved!['contextualItemUses'] as List;
      final rule = ContextualItemUseRule.fromJson(
        Map<String, dynamic>.from(rules.single as Map),
      );
      expect(rule.itemId, 'rope');
      expect(rule.sceneId, 'wall-scene');
      expect(rule.position, const GridPos(x: 6, y: 3));
      expect(rule.facing, EntityFacing.north);
      expect(rule.priority, 10);
    },
  );
}
