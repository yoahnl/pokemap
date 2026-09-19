import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/rendering/studio_atlas_preview.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../../tool/create_example_project.dart';

void main() {
  testWidgets('rectangular atlas fits a square preview without stretching', (
    tester,
  ) async {
    late Directory directory;
    late StudioMapResources resources;
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('studio_atlas_ratio_');
      await writeExampleProject(directory);
      final root = await directory.resolveSymbolicLinks();
      final project = ProjectManifest.fromJson(
        jsonDecode(await File('$root/project.json').readAsString())
            as Map<String, dynamic>,
      );
      resources = await StudioMapResources.load(
        ProjectSession(
          sessionId: 'atlas-ratio',
          name: 'Test',
          directoryPath: root,
        ),
        project,
      );
      resources.retain(Object(), {'atelier'});
      await resources.settled;
    });
    addTearDown(() async {
      await resources.dispose();
      await directory.delete(recursive: true);
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: StudioAtlasPreview(
              resources: resources,
              tilesetId: 'atelier',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final painter = tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byType(StudioAtlasPreview),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter!;
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      painter.paint(ui.Canvas(recorder), const Size(200, 200));
      final picture = recorder.endRecording();
      final image = await picture.toImage(200, 200);
      picture.dispose();
      final data = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      image.dispose();
      int alpha(int x, int y) => data.getUint8((y * 200 + x) * 4 + 3);
      expect(
        alpha(10, 20),
        0,
        reason: 'Transparent margin above a 160×64 atlas fitted into 200×200',
      );
      expect(
        alpha(10, 70),
        255,
        reason: 'The atlas occupies the centered 200×80 destination',
      );
      expect(alpha(10, 180), 0);
    });
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
