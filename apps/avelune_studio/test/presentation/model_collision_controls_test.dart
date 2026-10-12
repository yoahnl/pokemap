import 'package:avelune_studio/presentation/features/resources/model_collision_controls.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_environment_fixture.dart';

void main() {
  testWidgets(
    'custom collision validates six local coordinates and saves an independent volume',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var model = spatialEnvironmentProject().models3d.single.copyWith(
        scale: 2,
      );
      final visualBounds = model.inspection.bounds;
      final saved = <Model3dBounds?>[];
      Widget panel({bool busy = false}) => MaterialApp(
        home: Scaffold(
          body: ModelCollisionControls(
            model: model,
            busy: busy,
            onSave: (bounds) async {
              saved.add(bounds);
              model = model.copyWith(
                collisionBounds: bounds,
                clearCollisionBounds: bounds == null,
              );
            },
          ),
        ),
      );
      await tester.pumpWidget(panel());
      tester
          .widget<StudioSelect>(
            find.byKey(const ValueKey('model-collision-mode')),
          )
          .onChanged!('custom');
      await tester.pump();
      expect(
        find.textContaining('1 unité source = 2.0 case(s)'),
        findsOneWidget,
      );
      Finder field(String key) => find.descendant(
        of: find.byKey(ValueKey('model-collision-$key')),
        matching: find.byType(TextField),
      );
      await tester.enterText(field('min-x'), '0,1');
      await tester.enterText(field('max-x'), '0');
      await tester.tap(find.byKey(const ValueKey('model-collision-save')));
      await tester.pump();
      expect(saved, isEmpty);
      expect(
        find.text(
          'Chaque maximum doit être supérieur au minimum correspondant.',
        ),
        findsOneWidget,
      );
      await tester.enterText(field('max-x'), 'NaN');
      await tester.tap(find.byKey(const ValueKey('model-collision-save')));
      await tester.pump();
      expect(saved, isEmpty);
      expect(
        find.text('Saisissez six nombres valides pour le volume.'),
        findsOneWidget,
      );
      await tester.enterText(field('min-x'), '-0,1');
      await tester.enterText(field('max-x'), '0,1');
      await tester.enterText(field('min-y'), '0');
      await tester.enterText(field('max-y'), '1,5');
      await tester.enterText(field('min-z'), '-0,1');
      await tester.enterText(field('max-z'), '0,1');
      await tester.tap(find.byKey(const ValueKey('model-collision-save')));
      await tester.pumpWidget(panel());
      expect(saved.single!.toJson(), {
        'min': {'x': -.1, 'y': 0.0, 'z': -.1},
        'max': {'x': .1, 'y': 1.5, 'z': .1},
      });
      expect(model.inspection.bounds, visualBounds);
      tester
          .widget<StudioSelect>(
            find.byKey(const ValueKey('model-collision-mode')),
          )
          .onChanged!('model');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('model-collision-save')));
      await tester.pumpWidget(panel());
      expect(saved.last, isNull);
      expect(model.collisionBounds, isNull);
      expect(model.inspection.bounds, visualBounds);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'collision changes cancel locally and remote failures retain the draft',
    (tester) async {
      var fails = true;
      final saved = <Model3dBounds?>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelCollisionControls(
              model: spatialEnvironmentProject().models3d.single,
              onSave: (bounds) async {
                if (fails) throw StateError('Révision modifiée');
                saved.add(bounds);
              },
            ),
          ),
        ),
      );
      tester
          .widget<StudioSelect>(
            find.byKey(const ValueKey('model-collision-mode')),
          )
          .onChanged!('custom');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('model-collision-save')));
      await tester.pump();
      expect(find.textContaining('Révision modifiée'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('model-collision-min-x')),
        findsOneWidget,
      );
      fails = false;
      await tester.tap(find.byKey(const ValueKey('model-collision-save')));
      await tester.pump();
      expect(saved, hasLength(1));
      await tester.tap(find.text('Annuler les modifications'));
      await tester.pump();
      expect(find.byKey(const ValueKey('model-collision-min-x')), findsNothing);
    },
  );
}
