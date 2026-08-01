import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flutter/battle_mobile_command_overlay.dart';

Future<Uint8List> _pngBytes(ui.Color color) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 2, 2),
    ui.Paint()..color = color,
  );
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(2, 2);
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
  }
}

Widget _hostedIcon({
  required String imagePath,
  required BattleMobileItemIconBytesLoader bytesLoader,
}) {
  return MaterialApp(
    home: Center(
      child: BattleMobileItemIcon(
        key: const Key('item-icon'),
        imagePath: imagePath,
        bytesLoader: bytesLoader,
      ),
    ),
  );
}

void main() {
  testWidgets('keeps fallback while async bytes are pending then shows image',
      (tester) async {
    final imageBytes = await tester.runAsync(
      () => _pngBytes(const ui.Color(0xFF55AAFF)),
    );
    final pending = Completer<Uint8List?>();
    var loadCount = 0;

    await tester.pumpWidget(
      _hostedIcon(
        imagePath: '/tmp/potion.png',
        bytesLoader: (_) {
          loadCount += 1;
          return pending.future;
        },
      ),
    );

    expect(loadCount, equals(1));
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);

    pending.complete(imageBytes!);
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('keeps fallback when async bytes loading fails', (tester) async {
    final pending = Completer<Uint8List?>();

    await tester.pumpWidget(
      _hostedIcon(
        imagePath: '/tmp/missing.png',
        bytesLoader: (_) => pending.future,
      ),
    );
    pending.completeError(StateError('missing'));
    await tester.pump();

    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps fallback when async bytes loader returns null',
      (tester) async {
    var loadCount = 0;

    await tester.pumpWidget(
      _hostedIcon(
        imagePath: '/tmp/missing.png',
        bytesLoader: (_) async {
          loadCount += 1;
          return null;
        },
      ),
    );
    await tester.pump();

    expect(loadCount, equals(1));
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('path change ignores stale A after B finishes first',
      (tester) async {
    final aBytes = await tester.runAsync(
      () => _pngBytes(const ui.Color(0xFFFF5533)),
    );
    final bBytes = await tester.runAsync(
      () => _pngBytes(const ui.Color(0xFF3366FF)),
    );
    final pendingByPath = <String, Completer<Uint8List?>>{};
    final loadedPaths = <String>[];
    Future<Uint8List?> loader(String path) {
      loadedPaths.add(path);
      return (pendingByPath[path] ??= Completer<Uint8List?>()).future;
    }

    await tester.pumpWidget(
      _hostedIcon(imagePath: '/tmp/a.png', bytesLoader: loader),
    );
    await tester.pumpWidget(
      _hostedIcon(imagePath: '/tmp/b.png', bytesLoader: loader),
    );

    pendingByPath['/tmp/b.png']!.complete(bBytes!);
    await tester.pumpAndSettle();
    var image = tester.widget<Image>(find.byType(Image));
    expect((image.image as MemoryImage).bytes, same(bBytes));

    pendingByPath['/tmp/a.png']!.complete(aBytes!);
    await tester.pump();
    image = tester.widget<Image>(find.byType(Image));

    expect(loadedPaths, equals(<String>['/tmp/a.png', '/tmp/b.png']));
    expect((image.image as MemoryImage).bytes, same(bBytes));
  });

  testWidgets('path change replaces a displayed image with pending fallback',
      (tester) async {
    final aBytes = await tester.runAsync(
      () => _pngBytes(const ui.Color(0xFFFF5533)),
    );
    final pendingB = Completer<Uint8List?>();
    final loadedPaths = <String>[];
    Future<Uint8List?> loader(String path) {
      loadedPaths.add(path);
      if (path == '/tmp/a.png') {
        return Future<Uint8List?>.value(aBytes);
      }
      return pendingB.future;
    }

    await tester.pumpWidget(
      _hostedIcon(imagePath: '/tmp/a.png', bytesLoader: loader),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);

    await tester.pumpWidget(
      _hostedIcon(imagePath: '/tmp/a.png', bytesLoader: loader),
    );
    expect(loadedPaths, equals(<String>['/tmp/a.png']));

    await tester.pumpWidget(
      _hostedIcon(imagePath: '/tmp/b.png', bytesLoader: loader),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
  });

  testWidgets('completion after unmount does not update disposed state',
      (tester) async {
    final imageBytes = await tester.runAsync(
      () => _pngBytes(const ui.Color(0xFF55AAFF)),
    );
    final pending = Completer<Uint8List?>();

    await tester.pumpWidget(
      _hostedIcon(
        imagePath: '/tmp/potion.png',
        bytesLoader: (_) => pending.future,
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(imageBytes!);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
