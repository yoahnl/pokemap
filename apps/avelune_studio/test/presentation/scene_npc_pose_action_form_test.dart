import 'package:avelune_studio/presentation/features/scenes/scene_action_form.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  for (final onlyFacing in [false, true]) {
    testWidgets('guided NPC pose edits both modes facingOnly=$onlyFacing', (
      tester,
    ) async {
      SceneNodePayload? applied;
      final original = SceneConsequence.setNpcPose(
        mapId: 'room',
        entityId: 'actor',
        x: onlyFacing ? null : 3,
        y: onlyFacing ? null : 2,
        facing: EntityFacing.west,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SceneActionForm(
                project: _project(),
                loadMap: (_) async => _map(),
                current: SceneActionPayload.consequence(original),
                onApply: (value) => applied = value,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('PNJ test'), findsOneWidget);
      final mode = find.byWidgetPredicate(
        (widget) =>
            widget is StudioSelect && widget.label == 'Modification du PNJ',
      );
      await tester.tap(mode);
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .text(onlyFacing ? 'Position et direction' : 'Direction uniquement')
            .last,
      );
      await tester.pumpAndSettle();
      if (onlyFacing) {
        for (final (label, value) in [('Case X', '4'), ('Case Y', '3')]) {
          await tester.enterText(find.widgetWithText(TextField, label), value);
          await tester.pump();
        }
      } else {
        expect(find.widgetWithText(TextField, 'Case X'), findsNothing);
      }
      final apply = find.byWidgetPredicate(
        (widget) =>
            widget is StudioButton && widget.label == 'Appliquer l’action',
      );
      expect(tester.widget<StudioButton>(apply).onPressed, isNotNull);
      await tester.ensureVisible(apply);
      await tester.tap(apply);
      final result =
          (applied as SceneActionPayload).consequence
              as SceneSetNpcPoseConsequence;
      expect(result.mapId, 'room');
      expect(result.entityId, 'actor');
      expect(result.facing, EntityFacing.west);
      expect(result.x, onlyFacing ? 4 : null);
      expect(result.y, onlyFacing ? 3 : null);
    });
  }
  testWidgets(
    'guided NPC pose refuses unknown character without discarding its reference',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SceneActionForm(
              project: _project(),
              loadMap: (_) async => _map(character: 'missing'),
              current: SceneActionPayload.consequence(
                SceneConsequence.setNpcPose(
                  mapId: 'room',
                  entityId: 'actor',
                  facing: EntityFacing.east,
                ),
              ),
              onApply: (_) => fail('Unavailable owner'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Référence introuvable : actor'),
        findsOneWidget,
      );
      final apply = find.byWidgetPredicate(
        (widget) =>
            widget is StudioButton && widget.label == 'Appliquer l’action',
      );
      expect(tester.widget<StudioButton>(apply).onPressed, isNull);
    },
  );
}

ProjectManifest _project() => ProjectManifest(
  name: 'Pose',
  maps: const [
    ProjectMapEntry(id: 'room', name: 'Pièce', relativePath: 'room.json'),
  ],
  tilesets: const [],
  characters: const [
    ProjectCharacterEntry(id: 'known', name: 'Personnage', tilesetId: 'actors'),
  ],
);

MapData _map({String character = 'known'}) => MapData(
  id: 'room',
  name: 'Pièce',
  size: const GridSize(width: 8, height: 8),
  entities: [
    MapEntity(
      id: 'actor',
      name: 'PNJ test',
      kind: MapEntityKind.custom,
      pos: const GridPos(x: 2, y: 2),
      presentation: MapEntityPresentation(
        variants: [
          MapEntityPresentationVariant(
            id: 'visible',
            characterId: character,
            condition: NarrativeEventConditionExpression.all(const []),
            blocksMovement: false,
          ),
        ],
      ),
    ),
  ],
);
