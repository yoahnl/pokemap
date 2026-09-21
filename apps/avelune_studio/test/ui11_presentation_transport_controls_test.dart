import 'package:avelune_studio/presentation/features/presentations/presentation_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/ui11_workspace_harness.dart';

void main() {
  Future<Ui11WorkspaceHarness> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = (await tester.runAsync(
      () => Ui11WorkspaceHarness.create(tester),
    ))!;
    addTearDown(() => harness.shutdown(tester));
    await tester.pumpWidget(harness.app());
    await harness.settle(tester);
    return harness;
  }

  int timeUs(WidgetTester tester) => tester
      .widget<PresentationTimeline>(find.byType(PresentationTimeline))
      .transport
      .timeUs;

  bool playing(WidgetTester tester) => tester
      .widget<PresentationTimeline>(find.byType(PresentationTimeline))
      .transport
      .playing;

  testWidgets('UI11 the playhead follows a drag on the ruler', (tester) async {
    final harness = await open(tester);
    final ruler = find.byKey(const ValueKey('presentation-timeline-ruler'));
    expect(ruler, findsOneWidget);
    expect(timeUs(tester), 0);

    final origin = tester.getTopLeft(ruler) + const Offset(4, 12);
    final gesture = await tester.startGesture(origin);
    await gesture.moveBy(const Offset(120, 0));
    await tester.pump();
    final scrubbed = timeUs(tester);
    expect(
      scrubbed,
      greaterThan(0),
      reason: 'Dragging the ruler must move the playhead, not only tapping it',
    );
    await gesture.moveBy(const Offset(60, 0));
    await tester.pump();
    expect(timeUs(tester), greaterThan(scrubbed));
    await harness.capture(tester, 'ui11-08-playhead-scrub');
    await gesture.up();
    await harness.settle(tester);

    await tester.tapAt(tester.getTopLeft(ruler) + const Offset(4, 12));
    await harness.settle(tester);
    expect(timeUs(tester), lessThan(scrubbed));
    expect(harness.controller.active!.dirty, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('UI11 scrubbing does not churn the media between frames', (
    tester,
  ) async {
    final harness = await open(tester);
    final ruler = find.byKey(const ValueKey('presentation-timeline-ruler'));
    final transport = tester
        .widget<PresentationTimeline>(find.byType(PresentationTimeline))
        .transport;
    final applied = harness.visuals.appliedMediaEpoch;

    final gesture = await tester.startGesture(
      tester.getTopLeft(ruler) + const Offset(4, 12),
    );
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
    }
    expect(transport.scrubbing, isTrue);
    expect(transport.mediaEpoch, greaterThan(applied));
    expect(
      harness.visuals.appliedMediaEpoch,
      applied,
      reason: 'Releasing and restarting media on every scrub sample strobes',
    );

    await gesture.up();
    await harness.settle(tester);
    expect(transport.scrubbing, isFalse);
    expect(harness.visuals.appliedMediaEpoch, transport.mediaEpoch);
    expect(tester.takeException(), isNull);
  });

  testWidgets('UI11 transport answers the keyboard without a focused panel', (
    tester,
  ) async {
    final harness = await open(tester);
    expect(playing(tester), isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(playing(tester), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(playing(tester), isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    final stepped = timeUs(tester);
    expect(stepped, greaterThan(0));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(timeUs(tester), lessThan(stepped));

    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(timeUs(tester), harness.controller.active!.asset.durationUs);
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(timeUs(tester), 0);

    expect(harness.controller.active!.dirty, isFalse);
    expect(harness.port.writes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('UI11 a refused timeline drag stops warning once released', (
    tester,
  ) async {
    final harness = await open(tester);
    final asset = harness.controller.active!.asset;
    final clip = asset.tracks.first.clips.first;
    final bar = find.byKey(ValueKey('clip-${clip.id}'));
    expect(bar, findsOneWidget);
    final view = harness.views.forAsset(asset);

    final gesture = await tester.startGesture(tester.getCenter(bar));
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(900, 0));
    await tester.pump();
    expect(view.actionError, isNotNull);
    expect(find.textContaining('Déplacement refusé'), findsOneWidget);

    await gesture.up();
    await harness.settle(tester);
    expect(
      view.actionError,
      isNull,
      reason: 'A refused gesture must not leave a banner once it is over',
    );
    expect(find.textContaining('Déplacement refusé'), findsNothing);
    expect(harness.controller.active!.asset, asset);
    expect(tester.takeException(), isNull);
  });
}
