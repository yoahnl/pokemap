import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/src/foundation/player_image.dart';

Future<ui.Image> _image() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const ui.Rect.fromLTWH(0, 0, 2, 2),
    ui.Paint()..color = const ui.Color(0xff008800),
  );
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(2, 2);
  } finally {
    picture.dispose();
  }
}

void main() {
  testWidgets('scoped images reserve shared bytes and release on removal', (
    tester,
  ) async {
    final image = (await tester.runAsync(_image))!;
    addTearDown(image.dispose);
    final budget = RuntimeResourceBudget();
    var loads = 0;
    Future<PlayerImageLease> loader(
      String path, {
      required bool Function() isCurrent,
    }) async {
      loads++;
      final reservation = await budget.acquire(
        residentBytes: 16,
        isCurrent: isCurrent,
      );
      reservation.commit();
      final owned = image.clone();
      return PlayerImageLease(
        image: owned,
        onDispose: () {
          owned.dispose();
          reservation.release();
        },
      );
    }

    Widget host(PlayerImageLoader callback, Object identity) => Directionality(
      textDirection: TextDirection.ltr,
      child: PlayerImageScope(
        identity: identity,
        loader: callback,
        child: PlayerProvidedImage(
          image: ResizeImage(FileImage(File('/portrait.png')), width: 20),
        ),
      ),
    );
    await tester.pumpWidget(host(loader, budget));
    await tester.pump();
    expect(find.byType(RawImage), findsOneWidget);
    expect(budget.residentBytes, 16);
    await tester.pumpWidget(
      host(
        (path, {required isCurrent}) => loader(path, isCurrent: isCurrent),
        budget,
      ),
    );
    await tester.pump();
    expect(loads, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(budget.residentBytes, 0);
  });

  testWidgets('late leases release after path replacement or removal', (
    tester,
  ) async {
    final image = (await tester.runAsync(_image))!;
    addTearDown(image.dispose);
    final pending = <String, Completer<PlayerImageLease>>{};
    final released = <String>[];
    Future<PlayerImageLease> loader(
      String path, {
      required bool Function() isCurrent,
    }) => (pending[path] ??= Completer<PlayerImageLease>()).future;
    PlayerImageLease lease(String path) {
      final owned = image.clone();
      return PlayerImageLease(
        image: owned,
        onDispose: () {
          released.add(path);
          owned.dispose();
        },
      );
    }

    Widget host(String path) => Directionality(
      textDirection: TextDirection.ltr,
      child: PlayerImageScope(
        identity: 'session',
        loader: loader,
        child: PlayerFileImage(path: path),
      ),
    );
    await tester.pumpWidget(host('/a.png'));
    await tester.pumpWidget(host('/b.png'));
    pending['/a.png']!.complete(lease('/a.png'));
    await tester.pump();
    expect(released, ['/a.png']);
    expect(find.byType(RawImage), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    pending['/b.png']!.complete(lease('/b.png'));
    await tester.pump();
    expect(released, ['/a.png', '/b.png']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing scope or rejected admission stays on fallback', (
    tester,
  ) async {
    const fallback = SizedBox(key: ValueKey('fallback'));
    var rejectedLoads = 0;
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: PlayerImageScope(
          identity: 'blocked',
          loader: null,
          child: PlayerFileImage(path: '/untrusted.png', fallback: fallback),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('fallback')), findsOneWidget);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PlayerImageScope(
          identity: 'blocked',
          loader: (path, {required isCurrent}) async {
            rejectedLoads++;
            throw const RuntimeResourceAdmissionException('resident_bytes');
          },
          child: const PlayerFileImage(
            path: '/untrusted.png',
            fallback: fallback,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('fallback')), findsOneWidget);
    expect(rejectedLoads, 1);
    expect(find.byType(RawImage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
