import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/warp_transition_overlay_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('HGSS departure fades uniformly and arrival opens full-width scanline bands', () async {
    final overlay = WarpTransitionOverlayComponent(
      viewportSize: Vector2(256, 192),
      transition: const MapWarpTransition(type: MapWarpTransitionType.hgss),
    );
    final departure = overlay.fadeOut();
    overlay.update(.1);
    final departing = await _pixels(overlay);
    expect(_blue(departing, 0, 0), inInclusiveRange(126, 129));
    expect(_blue(departing, 128, 96), _blue(departing, 0, 0));
    overlay.update(.1);
    await departure;
    final arrival = overlay.fadeIn();
    overlay.update(.1);
    final revealing = await _pixels(overlay);
    for (final x in [0, 127, 255]) {
      expect(_blue(revealing, x, 47), 0);
      expect(_blue(revealing, x, 48), 255);
      expect(_blue(revealing, x, 143), 255);
      expect(_blue(revealing, x, 144), 0);
    }
    overlay.update(.1);
    await arrival;
    expect(_blue(await _pixels(overlay), 0, 0), 255);
    overlay.close();
  });

  test(
    'HGSS reveal interpolates smoothly between each original source step',
    () async {
      for (var halfStep = 1; halfStep < 12; halfStep += 2) {
        final overlay = WarpTransitionOverlayComponent(
          viewportSize: Vector2(256, 192),
          transition: const MapWarpTransition(type: MapWarpTransitionType.hgss),
        );
        await overlay.fadeOut(duration: Duration.zero);
        final arrival = overlay.fadeIn();
        overlay.update(.2 * halfStep / 12);
        final pixels = await _pixels(overlay);
        final top = 96 - 8 * halfStep;
        final bottom = 96 + 8 * halfStep;
        for (final x in [0, 127, 255]) {
          expect(_blue(pixels, x, top - 1), 0);
          expect(_blue(pixels, x, top), 255);
          expect(_blue(pixels, x, bottom - 1), 255);
          expect(_blue(pixels, x, bottom), 0);
        }
        overlay.close();
        await arrival;
      }
    },
  );

  test(
    'HGSS smooth reveal keeps all six original source boundary positions',
    () async {
      for (var step = 0; step <= 6; step++) {
        final overlay = WarpTransitionOverlayComponent(
          viewportSize: Vector2(256, 192),
          transition: const MapWarpTransition(type: MapWarpTransitionType.hgss),
        );
        await overlay.fadeOut(duration: Duration.zero);
        final arrival = overlay.fadeIn();
        overlay.update(.2 * step / 6);
        final pixels = await _pixels(overlay);
        final top = 96 - 16 * step;
        final bottom = 96 + 16 * step;
        for (final x in [0, 127, 255]) {
          if (top > 0) expect(_blue(pixels, x, top - 1), 0);
          if (step > 0) {
            expect(_blue(pixels, x, top), 255);
            expect(_blue(pixels, x, bottom - 1), 255);
          }
          if (bottom < 192) expect(_blue(pixels, x, bottom), 0);
        }
        overlay.close();
        await arrival;
      }
    },
  );

  test(
    'fade remains spatially uniform during reveal at authored duration',
    () async {
      final overlay = WarpTransitionOverlayComponent(
        viewportSize: Vector2(256, 192),
        transition: const MapWarpTransition(durationSeconds: .8),
      );
      await overlay.fadeOut(duration: Duration.zero);
      final arrival = overlay.fadeIn();
      overlay.update(.2);
      final pixels = await _pixels(overlay);
      expect(_blue(pixels, 0, 0), inInclusiveRange(62, 65));
      expect(_blue(pixels, 128, 96), _blue(pixels, 0, 0));
      overlay.close();
      await arrival;
    },
  );

  test('none never covers the world or waits for an update', () async {
    final overlay = WarpTransitionOverlayComponent(
      viewportSize: Vector2(256, 192),
      transition: const MapWarpTransition(
        type: MapWarpTransitionType.none,
        durationSeconds: 5,
      ),
    );
    await overlay.fadeOut();
    expect(_blue(await _pixels(overlay), 128, 96), 255);
    await overlay.fadeIn();
    overlay.close();
  });

  test(
    'replacing a running animation with immediate reveal releases its waiter',
    () async {
      final overlay = WarpTransitionOverlayComponent(
        viewportSize: Vector2(256, 192),
      );
      final old = overlay.fadeOut();
      await overlay.fadeIn(duration: Duration.zero);
      await old;
      expect(_blue(await _pixels(overlay), 128, 96), 255);
      overlay.close();
    },
  );
}

int _blue(Uint8List pixels, int x, int y) => pixels[(y * 256 + x) * 4 + 2];

Future<Uint8List> _pixels(WarpTransitionOverlayComponent overlay) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawColor(const ui.Color(0xff0000ff), ui.BlendMode.src);
  overlay.render(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(256, 192);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final pixels = Uint8List.fromList(data!.buffer.asUint8List());
  image.dispose();
  picture.dispose();
  return pixels;
}
