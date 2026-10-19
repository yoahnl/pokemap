import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:map_authoring/map_authoring_editing.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_moving_prop_panel.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_action_form.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_toggle_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  test('open prop stays visible and dragging translates the complete rail with undo', () {
    final map = _map(withProps: true);
    final open = MovingPropDefinition.fromJson({
      ...map.movingProps.first.toJson(),
      'initialState': 'open',
    });
    final authored = const MovingPropEditing().upsert(
      map: map,
      project: _project(),
      prop: open,
    );
    expect(authored.placedElements.first.pos, const GridPos(x: 3, y: 2));
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: authored, mapId: authored.id, revision: 'open'),
    );
    final commands = MapEditingCommands(document, _project());
    commands.move('visual', const GridPos(x: 5, y: 3));
    final dragged = document.current;
    expect(
      dragged.movingProps
          .singleWhere((prop) => prop.id == 'gate')
          .closedPositionPx,
      const PixelOffset(x: 128, y: 96),
    );
    expect(
      dragged.movingProps
          .singleWhere((prop) => prop.id == 'gate')
          .openPositionPx,
      const PixelOffset(x: 160, y: 96),
    );
    expect(dragged.placedElements.first.pos, const GridPos(x: 5, y: 3));
    expect(commands.setGeometry('visual', x: 192, y: 96, size: null), isTrue);
    expect(
      document.current.movingProps
          .singleWhere((prop) => prop.id == 'gate')
          .closedPositionPx,
      const PixelOffset(x: 160, y: 96),
    );
    expect(
      document.current.movingProps
          .singleWhere((prop) => prop.id == 'gate')
          .openPositionPx,
      const PixelOffset(x: 192, y: 96),
    );
    document.restore(redo: false);
    expect(document.current, dragged);
    expect(commands.setGeometry('visual', x: 0, y: 96, size: null), isFalse);
    expect(document.current, dragged);
    document.restore(redo: false);
    expect(document.current, authored);
  });

  testWidgets(
    'selected decor configures a rail with undo and serialized reopen',
    (tester) async {
      final source = _map();
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: source, mapId: source.id, revision: 'test'),
      );
      await tester.pumpWidget(
        _shell(
          MapMovingPropPanel(
            document: document,
            project: _project(),
            placement: source.placedElements.first,
            onChanged: () {},
          ),
        ),
      );
      await tester.ensureVisible(find.byKey(const ValueKey('prop-save')));
      await tester.tap(find.byKey(const ValueKey('prop-save')));
      await tester.pumpAndSettle();
      final prop = document.current.movingProps.single;
      expect(prop.placedElementId, 'visual');
      expect(prop.closedPositionPx, const PixelOffset(x: 64, y: 64));
      expect(prop.openPositionPx, const PixelOffset(x: 96, y: 64));
      expect(MapData.fromJson(document.current.toJson()).movingProps, [prop]);
      expect(document.canUndo, isTrue);
      document.restore(redo: false);
      expect(document.current, source);
    },
  );

  testWidgets('scene form selects synchronized props without raw identifiers', (
    tester,
  ) async {
    final map = _map(withProps: true);
    SceneNodePayload? published;
    await tester.pumpWidget(
      _shell(
        SceneActionForm(
          project: _project(),
          current: SceneActionPayload.interactive(
            SceneInteractiveCommand.setPropState(
              mapId: 'hall',
              propIds: ['gate'],
              state: MovingPropState.open,
            ),
          ),
          loadMap: (_) async => map,
          onApply: (value) => published = value,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final toggle = tester.widget<StudioToggleRow>(
      find.byKey(const ValueKey('scene-prop-gate-two')),
    );
    toggle.onChanged!(true);
    await tester.pumpAndSettle();
    final apply = find.byWidgetPredicate(
      (widget) =>
          widget is StudioButton && widget.label == 'Appliquer l’action',
    );
    final duration = find.descendant(
      of: find.byKey(const ValueKey('action-setPropState-durationMs')),
      matching: find.byType(TextField),
    );
    await tester.enterText(duration, '10001');
    await tester.pump();
    expect(tester.widget<StudioButton>(apply).onPressed, isNull);
    await tester.enterText(duration, '350');
    await tester.pump();
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pumpAndSettle();
    final command =
        (published as SceneActionPayload).interactiveCommand!
            as SceneSetPropStateInteractiveCommand;
    expect(command.propIds, ['gate', 'gate-two']);
    expect(command.durationMs, 350);
    expect(command.state, MovingPropState.open);
  });

  testWidgets('missing props stay visible and prevent scene publication', (
    tester,
  ) async {
    await tester.pumpWidget(
      _shell(
        SceneActionForm(
          project: _project(),
          current: SceneActionPayload.interactive(
            SceneInteractiveCommand.setPropState(
              mapId: 'hall',
              propIds: ['removed'],
              state: MovingPropState.open,
            ),
          ),
          loadMap: (_) async => _map(withProps: true),
          onApply: (_) => fail('Missing reference'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Un décor sélectionné n’existe plus'),
      findsOneWidget,
    );
    final apply = tester.widget<StudioButton>(
      find.byWidgetPredicate(
        (widget) =>
            widget is StudioButton && widget.label == 'Appliquer l’action',
      ),
    );
    expect(apply.onPressed, isNull);
  });
}

Widget _shell(Widget child) => MaterialApp(
  theme: studioTheme(),
  home: Scaffold(
    body: SingleChildScrollView(child: SizedBox(width: 420, child: child)),
  ),
);

ProjectManifest _project() => const ProjectManifest(
  name: 'Props',
  maps: [ProjectMapEntry(id: 'hall', name: 'Hall', relativePath: 'hall.json')],
  settings: ProjectSettings(tileWidth: 32, tileHeight: 32),
  tilesets: [],
  elements: [
    ProjectElementEntry(
      id: 'gate-art',
      name: 'Grille',
      tilesetId: 'tiles',
      categoryId: 'decor',
      frames: [
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
        ),
      ],
    ),
  ],
);

MapData _map({bool withProps = false}) => MapData(
  id: 'hall',
  name: 'Hall',
  size: const GridSize(width: 10, height: 10),
  placedElements: const [
    MapPlacedElement(
      id: 'visual',
      elementId: 'gate-art',
      layerId: 'art',
      pos: GridPos(x: 2, y: 2),
      properties: {
        pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored,
      },
    ),
    MapPlacedElement(
      id: 'visual-two',
      elementId: 'gate-art',
      layerId: 'art',
      pos: GridPos(x: 4, y: 2),
      properties: {
        pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored,
      },
    ),
  ],
  movingProps: [
    if (withProps)
      for (final (id, visual, x) in [
        ('gate', 'visual', 64),
        ('gate-two', 'visual-two', 128),
      ])
        MovingPropDefinition(
          id: id,
          placedElementId: visual,
          closedPositionPx: PixelOffset(x: x, y: 64),
          openPositionPx: PixelOffset(x: x + 32, y: 64),
          collisionRect: const PixelRect(
            leftPx: 0,
            topPx: 0,
            widthPx: 32,
            heightPx: 32,
          ),
        ),
  ],
);
