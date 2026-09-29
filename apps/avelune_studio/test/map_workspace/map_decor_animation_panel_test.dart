import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_decor_animation_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets('animated decor configures runtime triggers and survives JSON', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(700, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final project = workspaceProject.copyWith(
      elements: [
        workspaceElement.copyWith(
          frames: [
            ...workspaceElement.frames,
            const TilesetVisualFrame(
              source: TilesetSourceRect(x: 2, y: 0, width: 2, height: 2),
            ),
          ],
        ),
      ],
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(
        map: workspaceMap('a').copyWith(
          placedElements: const [
            MapPlacedElement(
              id: 'tree-1',
              layerId: 'ground',
              elementId: 'tree',
              pos: GridPos(x: 2, y: 2),
            ),
          ],
        ),
        revision: 'r0',
        mapId: 'a',
      ),
    )..selectedId = 'tree-1';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: MapDecorAnimationPanel(
              document: document,
              project: project,
              onChanged: () {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Animation active'));
    await tester.pump();
    expect(document.selected!.animation!.enabled, isTrue);
    expect(
      document.selected!.animation!.mode,
      MapPlacedElementAnimationMode.loop,
    );
    await tester.tap(find.text('Aller-retour'));
    await tester.pump();
    expect(
      document.selected!.animation!.mode,
      MapPlacedElementAnimationMode.pingPong,
    );
    await tester.ensureVisible(find.text('Ajouter le déclencheur'));
    await tester.tap(find.text('Ajouter le déclencheur'));
    await tester.pump();
    expect(
      document.selected!.behaviors.single.effect.type,
      MapPlacedElementEffectType.playAnimationOnce,
    );
    final reopened = MapData.fromJson(document.current.toJson());
    expect(reopened.placedElements.single.animation!.enabled, isTrue);
    expect(
      reopened.placedElements.single.animation!.mode,
      MapPlacedElementAnimationMode.pingPong,
    );
    expect(reopened.placedElements.single.behaviors, hasLength(1));
  });
}
