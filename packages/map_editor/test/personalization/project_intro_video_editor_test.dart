import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';

void main() {
  testWidgets('guides a first intro import with the supported limits',
      (tester) async {
    var importCount = 0;

    await tester.pumpWidget(
      _app(
        ProjectIntroVideoEditor(
          profile: null,
          onImportPressed: () => importCount++,
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Importer une vidéo'), findsOneWidget);
    expect(find.textContaining('MP4 · H.264'), findsOneWidget);
    expect(find.textContaining('2 minutes'), findsOneWidget);

    await tester.tap(find.text('Importer une vidéo'));
    expect(importCount, 1);
  });

  testWidgets('shows metadata and emits accessible playback preferences',
      (tester) async {
    final changes = <ProjectIntroVideoProfile>[];
    const profile = ProjectIntroVideoProfile(
      videoPath: 'assets/presentation/intro/intro.mp4',
      posterPath: 'assets/presentation/intro/poster.png',
      captionsPath: 'assets/presentation/intro/captions.vtt',
      durationMilliseconds: 12500,
      width: 1280,
      height: 720,
      bitrateKbps: 2400,
      sizeBytes: 5000000,
      videoCodec: 'h264',
      audioCodec: 'aac',
    );

    await tester.pumpWidget(
      _app(
        ProjectIntroVideoEditor(
          profile: profile,
          onImportPressed: () {},
          onChanged: changes.add,
          onRemove: () {},
        ),
      ),
    );

    expect(find.text('00:12'), findsOneWidget);
    expect(find.text('1280 × 720'), findsOneWidget);
    expect(find.text('Sous-titres WebVTT'), findsOneWidget);

    await tester.tap(find.text('Autoriser “Rejouer”'));
    await tester.pump();
    expect(changes.single.allowReplay, isFalse);

    await tester.tap(find.text('Passer l’intro'));
    await tester.pump();
    expect(changes.last.reducedMotionBehavior, 'skip');
  });
}

Widget _app(Widget child) => MaterialApp(
      theme: PokeMapTheme.light(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
