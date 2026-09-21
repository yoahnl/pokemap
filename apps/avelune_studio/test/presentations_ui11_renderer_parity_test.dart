import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:avelune_studio/platform/rendering/presentation_workspace_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/presentation_renderer.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_core/map_core_domain.dart';
import 'support/ui11_runtime_fixture.dart';

void main() {
  late Ui11RuntimeFixture fixture;
  setUp(() async {
    fixture = await Ui11RuntimeFixture.create();
  });
  tearDown(() async => fixture.dispose());
  for (final portrait in [false, true]) {
    testWidgets(
      'shared montage equals actual runtime frames portrait=$portrait',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(960, 640));
        tester.view.devicePixelRatio = 1;
        addTearDown(() async {
          tester.view.resetDevicePixelRatio();
          await tester.binding.setSurfaceSize(null);
        });
        final before = File('${fixture.root}/project.json').readAsBytesSync();
        late StudioPresentationVisuals visuals;
        await tester.runAsync(() async {
          visuals = StudioPresentationVisuals(
            projectRoot: fixture.root,
            revision: fixture.revision,
            catalog: fixture.media.catalog,
          );
          await visuals.prepare(fixture.asset, portrait: portrait);
        });
        final deltas = StreamController<int>();
        final runtime = RuntimePresentationSurfaceController(
          catalog: fixture.media.catalog,
          mediaUris: fixture.media.mediaUris,
          targetPlatform: PresentationMediaTargetPlatform.macos,
          videoDriver: VideoPlayerPresentationPlaybackDriver(),
          orientation: portrait
              ? PresentationFrameOrientation.portrait
              : PresentationFrameOrientation.landscape,
          frameDeltas: (_) => deltas.stream,
          beforeTerminal: () async {},
        );
        late Future<RuntimePresentationExecutionTerminal> playing;
        await tester.runAsync(() async {
          playing = runtime.playPresentationCinematic(
            ScenePresentationCinematicRuntimeRequest(
              requestId: 'ui11-parity',
              createdAtEpochMs: 1,
              projectRevision: fixture.revision,
              contentHash: fixture.revision,
              presentationCinematicId: fixture.asset.id,
              asset: fixture.asset,
            ),
          );
          await _until(() => runtime.value != null);
        });
        final boundary = GlobalKey();
        await tester.pumpWidget(_app(boundary, const SizedBox.expand()));
        final context = tester.element(find.byType(Scaffold));
        await tester.runAsync(() async {
          final uri = fixture.media.mediaUris[fixture.source.mediaId]!;
          final bytes = await File.fromUri(uri).readAsBytes();
          await precacheImage(FileImage(File.fromUri(uri)), context);
          await precacheImage(MemoryImage(bytes), context);
        });
        var previous = 0;
        for (final time in [
          0,
          249999,
          250000,
          500000,
          750000,
          1000000,
          2749999,
          2750000,
          2999999,
        ]) {
          if (time > previous) {
            await tester.runAsync(() async {
              deltas.add(time - previous);
              await _until(() => runtime.value?.frame.timeUs == time);
            });
          }
          previous = time;
          final snapshot = runtime.value!;
          final expected = const PresentationCinematicEvaluator().evaluate(
            fixture.asset,
            timeUs: time,
          );
          expect(snapshot.frame, expected);
          final prefix =
              'ui11-parity-${portrait ? 'portrait' : 'landscape'}-$time';
          final preview = await _render(
            tester,
            boundary,
            visuals.frame(
              asset: fixture.asset,
              frame: expected,
              portrait: portrait,
            ),
            time == 500000 ? '$prefix-montage' : null,
          );
          final played = await _render(
            tester,
            boundary,
            RuntimePresentationFrameSurface(
              snapshot: snapshot,
              contentPort: runtime,
            ),
            time == 500000 ? '$prefix-runtime' : null,
          );
          var differing = 0;
          for (var index = 0; index < preview.length; index++) {
            if (preview[index] != played[index]) differing++;
          }
          expect(
            differing,
            0,
            reason:
                'Same asset, viewport 960x640 DPR1 theme/time=$time; complete RGBA compared',
          );
        }
        RuntimePresentationExecutionTerminal? terminal;
        unawaited(playing.then((value) => terminal = value));
        await tester.runAsync(() async {
          deltas.add(1);
        });
        for (var i = 0; i < 100 && terminal == null; i++) {
          await tester.pump();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
        }
        expect(terminal?.result, RuntimePresentationExecutionResult.completed);
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(() async {
          await runtime.close();
          await deltas.close();
          await visuals.close();
        });
        expect(File('${fixture.root}/project.json').readAsBytesSync(), before);
        expect(tester.takeException(), isNull);
        runtime.dispose();
        visuals.dispose();
        await tester.pump(const Duration(milliseconds: 1));
      },
    );
  }
}

Widget _app(GlobalKey key, Widget child) => MaterialApp(
  theme: PokeMapPlayerTheme.dark(),
  home: Scaffold(
    body: RepaintBoundary(
      key: key,
      child: SizedBox(width: 960, height: 640, child: child),
    ),
  ),
);

Future<Uint8List> _render(
  WidgetTester tester,
  GlobalKey key,
  Widget child,
  String? capture,
) async {
  await tester.pumpWidget(_app(key, child));
  final images = tester.widgetList<Image>(find.byType(Image)).toList();
  if (images.isNotEmpty) {
    final context = tester.element(find.byType(Image).first);
    await tester.runAsync(
      () => Future.wait(
        images.map((image) => precacheImage(image.image, context)),
      ),
    );
  }
  await tester.pump();
  return (await tester.runAsync(() async {
    final image =
        await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary)
            .toImage(pixelRatio: 1);
    final data = (await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!.buffer.asUint8List();
    final directory = Platform.environment['AVELUNE_CAPTURE_DIR'];
    if (directory != null && capture != null) {
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List();
      await Directory(directory).create(recursive: true);
      await File('$directory/$capture.png').writeAsBytes(bytes);
    }
    image.dispose();
    return data;
  }))!;
}

Future<void> _until(bool Function() ready) async {
  for (var i = 0; i < 2000; i++) {
    if (ready()) return;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  throw StateError('Runtime frame did not arrive');
}
