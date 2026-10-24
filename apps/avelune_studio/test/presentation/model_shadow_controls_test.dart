import 'package:avelune_studio/presentation/features/resources/model_shadow_controls.dart';
import 'package:avelune_studio/presentation/features/resources/resource_detail_panel.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_toggle_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_environment_fixture.dart';

void main() {
  testWidgets('resource sheet exposes shadows for 3D models', (
    tester,
  ) async {
    final project = spatialEnvironmentProject();
    final model = project.models3d.single;
    bool? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResourceDetailPanel(
            item: ResourceItem(
              id: model.id,
              name: model.name,
              kind: ResourceKind.decors,
              model3d: model,
            ),
            project: project,
            preview: const SizedBox(),
            onUse: (_) {},
            onEdit: (_) {},
            onTerrain: (_) {},
            onModelShadowsChanged: (entry, value) async {
              expect(entry.id, model.id);
              saved = value;
            },
          ),
        ),
      ),
    );
    final control = find.byKey(const ValueKey('model-casts-shadows-default'));
    await tester.ensureVisible(control);
    await tester.tap(control);
    await tester.pump();
    expect(saved, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failed resource save retains the old value and explains failure',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelShadowControls(
              model: spatialEnvironmentProject().models3d.single,
              onChanged: (_) async => throw StateError('Enregistrement refusé'),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();
      expect(
        tester.widget<StudioToggleRow>(find.byType(StudioToggleRow)).value,
        isFalse,
      );
      expect(find.textContaining('Enregistrement refusé'), findsOneWidget);
    },
  );

  testWidgets('resource shadows start disabled and save the selected default', (
    tester,
  ) async {
    var model = spatialEnvironmentProject().models3d.single;
    bool? saved;
    Widget panel({bool busy = false}) => MaterialApp(
      home: Scaffold(
        body: ModelShadowControls(
          model: model,
          busy: busy,
          onChanged: (value) => saved = value,
        ),
      ),
    );
    await tester.pumpWidget(panel());
    expect(
      tester.widget<StudioToggleRow>(find.byType(StudioToggleRow)).value,
      isFalse,
    );
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    expect(saved, isTrue);
    model = model.copyWith(castsShadowsByDefault: true);
    await tester.pumpWidget(panel(busy: true));
    final toggle = tester.widget<StudioToggleRow>(find.byType(StudioToggleRow));
    expect(toggle.value, isTrue);
    expect(toggle.onChanged, isNull);
  });

  testWidgets(
    'placed decor follows its resource until overridden and can reset',
    (tester) async {
      var model = spatialEnvironmentProject().models3d.single;
      var instance = SpatialModelInstance(
        id: 'house',
        modelId: model.id,
        position: Model3dVector3.zero,
      );
      Widget panel({bool missing = false}) => MaterialApp(
        home: Scaffold(
          body: ModelInstanceShadowControls(
            model: missing ? null : model,
            instance: instance,
            onChanged: (value) => instance = instance.copyWith(
              castsShadows: value,
              clearCastsShadows: value == null,
            ),
          ),
        ),
      );
      bool enabled() =>
          tester.widget<StudioToggleRow>(find.byType(StudioToggleRow)).value;
      await tester.pumpWidget(panel());
      expect(enabled(), isFalse);
      expect(find.text('Suit la ressource · désactivées'), findsOneWidget);
      model = model.copyWith(castsShadowsByDefault: true);
      await tester.pumpWidget(panel());
      expect(enabled(), isTrue);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpWidget(panel());
      expect(instance.castsShadows, isFalse);
      expect(enabled(), isFalse);
      expect(find.text('Réglage propre à ce décor.'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('instance-casts-shadows-inherit')),
      );
      await tester.pumpWidget(panel());
      expect(instance.castsShadows, isNull);
      expect(enabled(), isTrue);
      await tester.pumpWidget(panel(missing: true));
      expect(
        tester.widget<StudioToggleRow>(find.byType(StudioToggleRow)).onChanged,
        isNull,
      );
      expect(enabled(), isFalse);
    },
  );
}
