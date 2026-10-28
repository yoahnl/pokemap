import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:avelune_studio/presentation/features/resources/model_light_controls.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_color_picker.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';

void main() {
  testWidgets(
    'color wheel and pastel presets update draft values without persistence',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        var color = 0xffd59a, changes = 0, starts = 0, ends = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: StatefulBuilder(
                  builder: (context, setState) => StudioColorPicker(
                    label: 'Couleur',
                    colorRgb: color,
                    presets: SpatialFireflyColor.values
                        .map((v) => v.rgb)
                        .toList(),
                    onChangeStart: () => starts++,
                    onChangeEnd: () => ends++,
                    onChanged: (v) {
                      setState(() => color = v);
                      changes++;
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.textContaining('Couleur ·'));
        await tester.pump();
        final wheel = find.byKey(const ValueKey('studio-color-wheel'));
        await tester.drag(wheel, const Offset(70, 35));
        await tester.pump();
        expect(changes, greaterThan(0));
        expect(starts, 1);
        expect(ends, 1);
        expect(color, inInclusiveRange(0, 0xffffff));
        await tester.ensureVisible(find.bySemanticsLabel('Couleur #bddfff'));
        await tester.tap(find.bySemanticsLabel('Couleur #bddfff'));
        await tester.pump();
        expect(color, SpatialFireflyColor.blue.rgb);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );
  testWidgets(
    'lamp preview edits stay local until save and preserve cycle and proximity',
    (tester) async {
      final light = Model3dPointLight(
        localPosition: Model3dVector3(x: 0, y: 2, z: 0),
        colorCycle: ModelLightColorCycle(colors: [0xffd59a, 0xbddfff]),
        proximity: ModelLightProximity(mode: ModelLightProximityMode.near),
      );
      final model = ProjectModel3dEntry(
        id: 'lamp',
        name: 'Lamp',
        sourceAssetId: 'model3d_lamp',
        relativePath: 'assets/models3d/lamp.glb',
        light: light,
        inspection: Model3dInspection(
          bounds: Model3dBounds(
            min: Model3dVector3.zero,
            max: Model3dVector3(x: 1, y: 3, z: 1),
          ),
          meshCount: 1,
          triangleCount: 4,
        ),
      );
      final preview = ModelPreviewController()..setLight(light);
      addTearDown(preview.dispose);
      var saves = 0;
      Model3dPointLight? persisted;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ModelLightControls(
                model: model,
                previewController: preview,
                onSave: (value) async {
                  saves++;
                  persisted = value;
                },
              ),
            ),
          ),
        ),
      );
      final height = find.descendant(
        of: find.byKey(const ValueKey('model-light-y')),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(height);
      await tester.enterText(height, '2.75');
      await tester.pump();
      expect(preview.light!.localPosition.y, 2.75);
      expect(saves, 0);
      final flame = find.byKey(const ValueKey('model-light-flame'));
      await tester.ensureVisible(flame);
      await tester.tap(flame);
      await tester.pump();
      expect(preview.light!.flame, isNotNull);
      final style = find.byKey(const ValueKey('model-light-flame-style'));
      await tester.ensureVisible(style);
      await tester.tap(style);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Brasier').last);
      await tester.pumpAndSettle();
      expect(preview.light!.flame!.style, ModelLightFlameStyle.brazier);
      final crackle = find.descendant(of: find.byKey(const ValueKey('model-light-flame-crackle')), matching: find.byType(Slider));
      await tester.ensureVisible(crackle);
      tester.widget<Slider>(crackle).onChanged!(.75);
      await tester.pump();
      expect(preview.light!.flame!.crackleVolume, .75);
      expect(saves, 0);
      expect(saves, 0);
      preview.setLight(
        preview.light!.copyWith(
          localPosition: Model3dVector3(x: 1, y: 3, z: 2),
        ),
      );
      await tester.pump();
      expect(tester.widget<TextField>(height).controller!.text, '3.0000');
      final save = find.byKey(const ValueKey('model-light-save'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump();
      expect(saves, 1);
      expect(persisted!.localPosition, Model3dVector3(x: 1, y: 3, z: 2));
      expect(persisted!.colorCycle, light.colorCycle);
      expect(persisted!.proximity, light.proximity);
      expect(persisted!.flame, isNotNull);
      expect(persisted!.flame!.crackleVolume, .75);
      await tester.ensureVisible(flame);
      await tester.tap(flame);
      await tester.pump();
      expect(preview.light!.flame, isNull);
      expect(saves, 1);
      expect(find.byType(StudioSelect), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
