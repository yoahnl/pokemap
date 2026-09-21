import 'dart:io';
import 'package:avelune_studio/features/presentations/application/presentation_preview_transport.dart';
import 'package:avelune_studio/features/presentations/domain/presentation_port.dart';
import 'package:avelune_studio/platform/rendering/presentation_workspace_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_player_ui/presentation_renderer.dart';

void main() {
  late Directory root;
  late List<int> bytes;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('ui11_visual_');
    bytes = await File('assets/home/hero_landscape.png').readAsBytes();
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });

  testWidgets(
    'staged illustration renders through shared canvas without project writes',
    (tester) async {
      final media = ProjectMediaAsset(
        id: 'picture',
        label: 'Illustration',
        kind: ProjectMediaKind.image,
        sourceAssetId: 'picture-asset',
      );
      final visuals = StudioPresentationVisuals(
        projectRoot: root.path,
        revision: 'r1',
        catalog: ProjectMediaCatalog(entries: [media]),
        imports: [
          PresentationStagedMedia(
            media: media,
            parameters: {},
            previewBytes: bytes,
          ),
        ],
      );
      final transport = PresentationPreviewTransport()..install(_asset());
      visuals.bindTransport(transport);
      await tester.runAsync(() => visuals.prepare(_asset(), portrait: false));
      final geometry = PresentationFrameGeometryController();
      await tester.pumpWidget(
        MaterialApp(
          home: visuals.frame(
            asset: _asset(),
            frame: transport.frame!,
            portrait: false,
            geometry: geometry,
          ),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      expect(find.byType(PresentationFrameRenderer), findsOneWidget);
      expect(find.text('Introduction'), findsOneWidget);
      expect(
        geometry.snapshot().map((item) => item.clipId),
        containsAll(['picture-clip', 'title']),
      );
      expect(visuals.diagnostic, isNull);
      final reads = visuals.mediaReads;
      for (var i = 1; i < 15; i++) {
        transport.seek(i * 10000);
        await tester.pumpWidget(
          MaterialApp(
            home: visuals.frame(
              asset: _asset(),
              frame: transport.frame!,
              portrait: false,
              geometry: geometry,
            ),
          ),
        );
      }
      expect(visuals.mediaReads, reads);
      expect(root.listSync(), isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      transport.dispose();
      await _close(tester, visuals);
      visuals.dispose();
    },
  );

  testWidgets(
    'missing unrelated media does not prevent text or stale source recovery',
    (tester) async {
      final missing = ProjectMediaAsset(
        id: 'picture',
        label: 'Absent',
        kind: ProjectMediaKind.image,
        sourceAssetId: 'absent',
      );
      final visuals = StudioPresentationVisuals(
        projectRoot: root.path,
        revision: 'r1',
        catalog: ProjectMediaCatalog(entries: [missing]),
      );
      await tester.runAsync(() => visuals.prepare(_asset(), portrait: false));
      expect(visuals.diagnostic, contains('Source absente'));
      expect(visuals.diagnosticIsFailure, isTrue);
      final textOnly = _asset(includePicture: false);
      await tester.runAsync(() => visuals.prepare(textOnly, portrait: false));
      expect(visuals.diagnostic, isNull);
      expect(visuals.diagnosticIsFailure, isFalse);
      await tester.pumpWidget(
        MaterialApp(
          home: visuals.frame(
            asset: textOnly,
            frame: const PresentationCinematicEvaluator().evaluate(
              textOnly,
              timeUs: 0,
            ),
            portrait: false,
          ),
        ),
      );
      expect(find.text('Introduction'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      await _close(tester, visuals);
      visuals.dispose();
    },
  );
}

PresentationCinematicAsset _asset({bool includePicture = true}) =>
    PresentationCinematicAsset(
      id: 'intro',
      title: 'Introduction',
      durationUs: 1000000,
      layers: [
        PresentationLayer(id: 'background', label: 'Image', zIndex: 0),
        PresentationLayer(id: 'title-layer', label: 'Titre', zIndex: 1),
      ],
      tracks: [
        PresentationTrack(
          id: 'visuals',
          label: 'Visuels',
          kind: PresentationTrackKind.visual,
          clips: [
            if (includePicture)
              PresentationVisualClip(
                id: 'picture-clip',
                startUs: 0,
                durationUs: 1000000,
                layerId: 'background',
                resourceId: 'picture',
                mediaKind: PresentationVisualMediaKind.image,
              ),
            PresentationTextClip(
              id: 'title',
              startUs: 0,
              durationUs: 1000000,
              layerId: 'title-layer',
              text: 'Introduction',
            ),
          ],
        ),
      ],
    );

Future<void> _close(
  WidgetTester tester,
  StudioPresentationVisuals visuals,
) async {
  var done = false;
  final closing = visuals.close().then((_) => done = true);
  for (var i = 0; i < 50 && !done; i++) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  expect(done, isTrue);
  await closing;
}
