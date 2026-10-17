import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/presentation/features/resources/model_ramp_controls.dart';

void main() {
  testWidgets('the stair controls propose bounds and save a reusable profile', (
    tester,
  ) async {
    Model3dRampProfile? saved;
    final model = ProjectModel3dEntry(
      id: 'stairs',
      name: 'Escalier',
      sourceAssetId: 'stairs-source',
      relativePath: 'assets/models3d/stairs.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3(x: -.5, y: 0, z: -2),
          max: Model3dVector3(x: .5, y: 1, z: 0),
        ),
        meshCount: 1,
        triangleCount: 4,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: ModelRampControls(
                model: model,
                onSave: (value) async => saved = value,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Décor classique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escalier · pente automatiquement liée').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Appliquer le comportement'));
    await tester.tap(find.text('Appliquer le comportement'));
    await tester.pumpAndSettle();
    expect(saved!.width, 1);
    expect(saved!.depth, 2);
    expect(saved!.highHeight, 1);
    expect(saved!.direction, SpatialRampDirection.north);
    expect(tester.takeException(), isNull);
  });
}
