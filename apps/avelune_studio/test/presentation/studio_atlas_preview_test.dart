import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/rendering/contracts/workspace_resource_diagnostic.dart';
import 'package:avelune_studio/platform/rendering/studio_atlas_preview.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/platform/rendering/studio_thumbnail_resources.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_runtime/map_runtime_authoring.dart';

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

  testWidgets('the tile grid follows the fitted image, margins and gaps', (
    tester,
  ) async {
    final image = (await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawColor(Colors.orange, ui.BlendMode.src);
      final picture = recorder.endRecording();
      final image = await picture.toImage(160, 64);
      picture.dispose();
      return image;
    }))!;
    addTearDown(image.dispose);
    final resources = _AtlasResources(RuntimeTilesetImage.borrowed(image));
    const layout = ProjectRegularAtlasTilesetSource(
      assetId: 'test',
      pixelWidth: 160,
      pixelHeight: 64,
      tileWidth: 24,
      tileHeight: 16,
      marginX: 8,
      marginY: 4,
      spacingX: 6,
      spacingY: 4,
    );

    await tester.pumpWidget(_preview(resources));
    final unmarked = (await tester.runAsync(() => _paintAtlas(tester)))!;
    await tester.pumpWidget(_preview(resources, grid: layout));
    final marked = (await tester.runAsync(() => _paintAtlas(tester)))!;

    int px(ByteData data, int x, int y) => data.getUint32((y * 200 + x) * 4);
    expect(px(marked, 10, 70), isNot(px(unmarked, 10, 70)));
    expect(px(marked, 40, 70), isNot(px(unmarked, 40, 70)));
    expect(px(marked, 44, 70), px(unmarked, 44, 70));
    expect(px(marked, 10, 87), px(unmarked, 10, 87));
    expect(px(marked, 5, 70), px(unmarked, 5, 70));
    expect(px(marked, 10, 20), px(unmarked, 10, 20));

    await tester.pumpWidget(
      _preview(
        resources,
        grid: const ProjectRegularAtlasTilesetSource(
          assetId: 'test',
          pixelWidth: 320,
          pixelHeight: 64,
          tileWidth: 32,
          tileHeight: 16,
        ),
      ),
    );
    expect(find.textContaining('Le fichier mesure 160 × 64 px.'), findsOne);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a missing path ends the atlas loading state', (tester) async {
    await tester.pumpWidget(_preview(_AtlasResources(null)));
    expect(find.text('Aperçu indisponible'), findsOneWidget);
    expect(find.text('Chargement de la planche…'), findsNothing);
  });
}

Future<ByteData> _paintAtlas(WidgetTester tester) async {
  final painter = tester
      .widget<CustomPaint>(
        find.descendant(
          of: find.byType(StudioAtlasPreview),
          matching: find.byType(CustomPaint),
        ),
      )
      .painter!;
  final recorder = ui.PictureRecorder();
  painter.paint(ui.Canvas(recorder), const Size(200, 200));
  final picture = recorder.endRecording();
  final image = await picture.toImage(200, 200);
  picture.dispose();
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  image.dispose();
  return bytes;
}

Widget _preview(
  StudioThumbnailResources resources, {
  ProjectRegularAtlasTilesetSource? grid,
}) => MaterialApp(
  home: Center(
    child: SizedBox.square(
      dimension: 200,
      child: StudioAtlasPreview(
        resources: resources,
        tilesetId: 'test',
        grid: grid,
      ),
    ),
  ),
);

class _AtlasResources extends Fake implements StudioThumbnailResources {
  _AtlasResources(this.image);

  final RuntimeTilesetImage? image;

  @override
  Map<String, RuntimeTilesetImage> get images => {'test': ?image};
  @override
  List<WorkspaceResourceDiagnostic> get diagnostics => const [];
  @override
  bool hasFailure(Iterable<String> ids) => image == null;
  @override
  void retain(Object owner, Set<String> ids) {}
  @override
  void release(Object owner) {}
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}
