import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_action_builder.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/panels/moving_prop_panel.dart';

void main() {
  test(
    'editor projects open initial state and undoes the prop with its placement',
    () {
      final container = ProviderContainer();
      final keepAlive = container.listen(editorNotifierProvider, (_, _) {});
      addTearDown(() {
        keepAlive.close();
        container.dispose();
      });
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      notifier.state = EditorState(
        project: _project(),
        activeMap: map,
        savedMapSnapshot: map,
      );
      notifier.upsertMovingProp(
        MovingPropDefinition(
          id: 'gate',
          placedElementId: 'visual',
          closedPositionPx: const PixelOffset(x: 64, y: 64),
          openPositionPx: const PixelOffset(x: 96, y: 64),
          collisionRect: const PixelRect(
            leftPx: 0,
            topPx: 0,
            widthPx: 32,
            heightPx: 32,
          ),
          initialState: MovingPropState.open,
        ),
      );
      expect(notifier.state.errorMessage, isNull);
      expect(
        notifier.state.activeMap!.placedElements.single.pos,
        const GridPos(x: 3, y: 2),
      );
      expect(
        notifier.state.activeMap!.movingProps.single.initialState,
        MovingPropState.open,
      );
      notifier.undoMap();
      expect(notifier.state.activeMap, map);
    },
  );

  testWidgets('decor properties configure a rail without identifiers or JSON', (
    tester,
  ) async {
    final map = _map();
    MovingPropDefinition? configured;
    await tester.pumpWidget(
      _shell(
        MovingPropPanel(
          map: map,
          project: _project(),
          placement: map.placedElements.single,
          onApply: (value) => configured = value,
          onDelete: (_) {},
        ),
      ),
    );
    await tester.ensureVisible(find.byKey(const ValueKey('prop-save')));
    await tester.tap(find.byKey(const ValueKey('prop-save')));
    await tester.pumpAndSettle();
    expect(configured!.placedElementId, 'visual');
    expect(configured!.closedPositionPx, const PixelOffset(x: 64, y: 64));
    expect(configured!.openPositionPx, const PixelOffset(x: 96, y: 64));
  });

  testWidgets(
    'scene selects a synchronized prop group and preserves it on reopen',
    (tester) async {
      SceneNodePayload? submitted;
      await tester.pumpWidget(
        _shell(
          SceneActionBuilder(
            project: _project(),
            initialPayload: SceneActionPayload.interactive(
              SceneInteractiveCommand.setPropState(
                mapId: 'hall',
                propIds: ['gate'],
                state: MovingPropState.open,
              ),
            ),
            pickerOptions: const {
              NarrativeCommandParameterKind.map: [
                SceneActionPickerOption(id: 'hall', label: 'Hall'),
              ],
              NarrativeCommandParameterKind.movingProps: [
                SceneActionPickerOption(
                  id: 'gate',
                  label: 'Grille gauche',
                  parentId: 'hall',
                ),
                SceneActionPickerOption(
                  id: 'gate-two',
                  label: 'Grille droite',
                  parentId: 'hall',
                ),
              ],
            },
            onSubmit: (value) => submitted = value,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final second = tester.widget<PokeMapToggleTile>(
        find.byKey(const ValueKey('scene-prop-gate-two')),
      );
      second.onChanged(true);
      await tester.pumpAndSettle();
      final duration = find.byKey(
        const ValueKey('scene-action-parameter-durationMs'),
      );
      await tester.enterText(duration, '15');
      await tester.pump();
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('scene-action-submit')),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(duration, '350');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('scene-action-submit')),
      );
      await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
      final command =
          (submitted as SceneActionPayload).interactiveCommand!
              as SceneSetPropStateInteractiveCommand;
      expect(command.propIds, ['gate', 'gate-two']);
      expect(command.durationMs, 350);
      expect(command.state, MovingPropState.open);
    },
  );

  testWidgets('deleted props block publication', (tester) async {
    await tester.pumpWidget(
      _shell(
        SceneActionBuilder(
          project: _project(),
          initialPayload: SceneActionPayload.interactive(
            SceneInteractiveCommand.setPropState(
              mapId: 'hall',
              propIds: ['removed'],
              state: MovingPropState.open,
            ),
          ),
          pickerOptions: const {
            NarrativeCommandParameterKind.map: [
              SceneActionPickerOption(id: 'hall', label: 'Hall'),
            ],
          },
          onSubmit: (_) => fail('Missing prop'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Décor supprimé'), findsOneWidget);
    final button = tester.widget<PokeMapButton>(
      find.byKey(const ValueKey('scene-action-submit')),
    );
    expect(button.onPressed, isNull);
  });
}

Widget _shell(Widget child) => MaterialApp(
  theme: PokeMapTheme.light(),
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

MapData _map() => MapData(
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
  ],
);
