import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';

/// The console must never be drawn distorted.
///
/// Its layers are painted with `BoxFit.fill`, so the box has to carry the
/// asset's own aspect ratio. The widget and the home geometry each hardcoded
/// 3.08 while `console/body.webp` is 1200x360 (3.3333), stretching the hardware
/// vertically by just over 8 percent on every screen.
void main() {
  testWidgets('the console body renders at the asset aspect ratio',
      (tester) async {
    final intrinsic = await _intrinsicRatio(
      tester,
      AveluneMaterialCatalog.consoleBody.path,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: applyAveluneTheme(PokeMapPlayerTheme.dark(reducedMotion: true)),
        home: const Center(
          child: SizedBox(width: 600, child: AveluneConsole()),
        ),
      ),
    );
    await tester.pump();

    final body = tester.getSize(
      find.byKey(const ValueKey<String>('avelune-console-body-layer')),
    );

    expect(
      body.width / body.height,
      closeTo(intrinsic, 0.001),
      reason: 'BoxFit.fill maps the whole canvas onto the box, so any other '
          'ratio squashes or stretches the hardware.',
    );
  });

  testWidgets('the wear layer shares the body canvas exactly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: applyAveluneTheme(PokeMapPlayerTheme.dark(reducedMotion: true)),
        home: const Center(
          child: SizedBox(width: 600, child: AveluneConsole()),
        ),
      ),
    );
    await tester.pump();

    final body = tester.getRect(
      find.byKey(const ValueKey<String>('avelune-console-body-layer')),
    );
    final wear = tester.getRect(
      find.byKey(const ValueKey<String>('avelune-console-wear-layer')),
    );

    expect(
      wear,
      body,
      reason: 'The wear pass is authored on the body canvas; any offset between '
          'them slides the scratches off the panels they belong to.',
    );
  });

  test('the home geometry sizes the console with the widget ratio', () {
    final geometry = AveluneHomeGeometry.resolve(
      viewportSize: const Size(393, 852),
      safeArea: const EdgeInsets.only(top: 47, bottom: 34),
    );

    expect(
      geometry.consoleRect.width / geometry.consoleRect.height,
      closeTo(kAveluneConsoleAspectRatio, 0.001),
      reason: 'The geometry used to keep a private copy of the ratio, so the '
          'two could drift apart silently.',
    );
  });
}

Future<double> _intrinsicRatio(WidgetTester tester, String assetPath) async {
  late double ratio;
  await tester.runAsync(() async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
    );
    try {
      final frame = await codec.getNextFrame();
      ratio = frame.image.width / frame.image.height;
      frame.image.dispose();
    } finally {
      codec.dispose();
    }
  });
  return ratio;
}
