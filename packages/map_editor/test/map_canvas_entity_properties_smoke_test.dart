import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/panels/entity_properties_panel.dart';

void main() {
  group('MapCanvas and EntityPropertiesPanel smoke tests', () {
    late Directory tempProjectRoot;

    setUp(() async {
      tempProjectRoot =
          await Directory.systemTemp.createTemp('map_editor_canvas_panel_');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    Future<void> pumpEditorSurface(
      WidgetTester tester,
      ProviderContainer container, {
      required Widget child,
      Size surfaceSize = const Size(1400, 1000),
    }) async {
      await tester.binding.setSurfaceSize(surfaceSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: MaterialApp(
              home: CupertinoPageScaffold(
                child: Center(
                  child: SizedBox(
                    width: surfaceSize.width,
                    height: surfaceSize.height,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    EditorState buildEditorState() {
      const activeMap = MapData(
        id: 'route_1',
        name: 'Route 1',
        size: GridSize(width: 4, height: 4),
        layers: <MapLayer>[
          TileLayer(
            id: 'ground',
            name: 'Ground',
            tiles: <int>[
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
            ],
          ),
        ],
        entities: <MapEntity>[
          MapEntity(
            id: 'npc_1',
            name: 'Guide',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 1, y: 1),
            npc: MapEntityNpcData(
              displayName: 'Guide',
            ),
          ),
        ],
      );

      return EditorState(
        projectRootPath: tempProjectRoot.path,
        project: ProjectManifest(
          surfaceCatalog: const ProjectSurfaceCatalog.empty(),
          name: 'smoke_project',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          facts: [
            NarrativeFactDefinition(
              id: 'fact_guide_hidden',
              label: 'Guide hidden fact',
            ),
          ],
          dialogues: const [
            ProjectDialogueEntry(
              id: 'dialogue_guide_after',
              name: 'Guide after',
              relativePath: 'dialogues/guide_after.yarn',
            ),
          ],
          worldRules: [
            _entityWorldRule(
              id: 'rule_hide_guide',
              label: 'Guide hidden',
              targetKind: WorldRuleTargetKind.mapEntity,
              effectKind: WorldRuleEffectKind.entityHidden,
            ),
            _entityWorldRule(
              id: 'rule_guide_dialogue',
              label: 'Guide dialogue',
              targetKind: WorldRuleTargetKind.npcDialogue,
              effectKind: WorldRuleEffectKind.npcDialogueOverride,
              dialogueId: 'dialogue_guide_after',
            ),
          ],
        ),
        activeMap: activeMap,
        activeLayerId: 'ground',
        selectedEntityId: 'npc_1',
      );
    }

    testWidgets('MapCanvas renders an active map without crashing',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state =
          buildEditorState();

      await pumpEditorSurface(
        tester,
        container,
        child: const SizedBox(
          width: 900,
          height: 700,
          child: MapCanvas(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('EntityPropertiesPanel renders the selected NPC inspector',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state =
          buildEditorState();

      await pumpEditorSurface(
        tester,
        container,
        child: const SizedBox(
          width: 560,
          height: 980,
          child: EntityPropertiesPanel(embedded: true),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('PNJ'), findsWidgets);
      expect(find.text('Enregistrer'), findsOneWidget);
      expect(find.text('Guide hidden'), findsOneWidget);
      expect(find.text('Guide dialogue'), findsOneWidget);
      expect(find.textContaining('Entité cachée'), findsOneWidget);
      expect(find.textContaining('Dialogue remplacé par Guide after'),
          findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.byKey(const ValueKey('world-rule-toggle-rule_hide_guide')),
      );
      await tester.pumpAndSettle();

      final rule = container
          .read(editorNotifierProvider)
          .project!
          .worldRules
          .firstWhere((worldRule) => worldRule.id == 'rule_hide_guide');
      expect(rule.enabled, isFalse);
    });
  });
}

WorldRuleDefinition _entityWorldRule({
  required String id,
  required String label,
  required WorldRuleTargetKind targetKind,
  required WorldRuleEffectKind effectKind,
  String? dialogueId,
}) {
  return WorldRuleDefinition(
    id: id,
    label: label,
    source: const WorldRuleSource(
      kind: WorldRuleSourceKind.fact,
      sourceId: 'fact_guide_hidden',
      predicate: WorldRuleSourcePredicate.isTrue,
    ),
    target: WorldRuleTarget(
      kind: targetKind,
      mapId: 'route_1',
      entityId: 'npc_1',
      label: 'Guide',
    ),
    effect: WorldRuleEffect(
      kind: effectKind,
      dialogueId: dialogueId,
    ),
  );
}
