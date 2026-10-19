import 'package:avelune_studio/presentation/features/resources/model_collision_controls.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_toggle_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_environment_fixture.dart';

void main() {
  testWidgets('resource collision exposes the default for future placements', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModelCollisionControls(
            model: spatialEnvironmentProject().models3d.single,
            onSave: (_, _) async {},
          ),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('model-blocks-movement-default')),
      findsOneWidget,
    );
    expect(find.text('Bloque le passage à la pose'), findsOneWidget);
  });

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
            onSave: (bounds, blocksMovementByDefault) async {
              saved.add(bounds);
              model = model.copyWith(
                blocksMovementByDefault: blocksMovementByDefault,
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
      final savedDefaults = <bool>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ModelCollisionControls(
                model: spatialEnvironmentProject().models3d.single,
                onSave: (bounds, blocksMovementByDefault) async {
                  if (fails) throw StateError('Révision modifiée');
                  saved.add(bounds);
                  savedDefaults.add(blocksMovementByDefault);
                },
              ),
            ),
          ),
        ),
      );
      tester
          .widget<StudioSelect>(
            find.byKey(const ValueKey('model-collision-mode')),
          )
          .onChanged!('custom');
      tester
          .widget<StudioToggleRow>(
            find.byKey(const ValueKey('model-blocks-movement-default')),
          )
          .onChanged!(false);
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('model-collision-save')),
      );
      await tester.tap(find.byKey(const ValueKey('model-collision-save')));
      await tester.pump();
      expect(find.textContaining('Révision modifiée'), findsOneWidget);
      expect(
        tester
            .widget<StudioToggleRow>(
              find.byKey(const ValueKey('model-blocks-movement-default')),
            )
            .value,
        isFalse,
      );
      expect(
        find.byKey(const ValueKey('model-collision-min-x')),
        findsOneWidget,
      );
      fails = false;
      await tester.ensureVisible(
        find.byKey(const ValueKey('model-collision-save')),
      );
      await tester.tap(find.byKey(const ValueKey('model-collision-save')));
      await tester.pump();
      expect(saved, hasLength(1));
      expect(savedDefaults, [false]);
      await tester.ensureVisible(find.text('Annuler les modifications'));
      await tester.tap(find.text('Annuler les modifications'));
      await tester.pump();
      expect(find.byKey(const ValueKey('model-collision-min-x')), findsNothing);
    },
  );

  testWidgets(
    'placement default saves independently of the volume and supports cancel and busy state',
    (tester) async {
      var model = spatialEnvironmentProject().models3d.single.copyWith(
        collisionBounds: Model3dBounds(
          min: Model3dVector3(x: -.1, y: 0, z: -.1),
          max: Model3dVector3(x: .1, y: 1, z: .1),
        ),
      );
      final originalBounds = model.collisionBounds;
      final saved = <bool>[];
      Widget panel({bool busy = false}) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ModelCollisionControls(
              model: model,
              busy: busy,
              onSave: (bounds, blocksMovementByDefault) async {
                saved.add(blocksMovementByDefault);
                model = model.copyWith(
                  collisionBounds: bounds,
                  blocksMovementByDefault: blocksMovementByDefault,
                );
              },
            ),
          ),
        ),
      );
      final key = find.byKey(const ValueKey('model-blocks-movement-default'));
      StudioToggleRow toggle() => tester.widget<StudioToggleRow>(key);
      await tester.pumpWidget(panel());
      expect(toggle().value, isTrue);
      toggle().onChanged!(false);
      await tester.pump();
      expect(toggle().value, isFalse);
      await tester.ensureVisible(find.text('Annuler les modifications'));
      await tester.tap(find.text('Annuler les modifications'));
      await tester.pump();
      expect(toggle().value, isTrue);
      expect(saved, isEmpty);
      toggle().onChanged!(false);
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('model-collision-save')),
      );
      await tester.tap(find.byKey(const ValueKey('model-collision-save')));
      await tester.pumpWidget(panel());
      expect(saved, [false]);
      expect(model.collisionBounds, originalBounds);
      expect(model.blocksMovementByDefault, isFalse);
      expect(toggle().value, isFalse);
      await tester.pumpWidget(panel(busy: true));
      expect(toggle().onChanged, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
