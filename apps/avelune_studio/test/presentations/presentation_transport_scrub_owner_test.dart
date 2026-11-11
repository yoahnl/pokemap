import 'package:avelune_studio/features/presentations/application/presentation_preview_transport.dart';
import 'package:avelune_studio/features/presentations/application/presentation_timeline_scrub.dart';
import 'package:avelune_studio/platform/rendering/presentation_workspace_visuals.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/presentation_workspace_owner_fixture.dart';

void main() {
  group('transport', () {
    late PresentationWorkspaceOwnerFixture owner;
    late PresentationPreviewTransport transport;
    setUp(() async {
      owner = await PresentationWorkspaceOwnerFixture.create();
      transport = PresentationPreviewTransport()..install(owner.asset);
    });
    tearDown(() async {
      transport.dispose();
      await owner.dispose();
    });

    void scrub(double dx) => scrubPresentationTimeline(
      transport,
      dx,
      pixelsPerSecond: 60,
      durationUs: owner.asset.durationUs,
    );

    test('the playhead follows a drag on the ruler', () {
      expect(transport.timeUs, 0);
      transport.play();
      scrub(120);
      final scrubbed = transport.timeUs;
      expect(scrubbed, 2000000);
      expect(transport.playing, isFalse);
      scrub(180);
      expect(transport.timeUs, greaterThan(scrubbed));
      scrub(4);
      expect(transport.timeUs, lessThan(scrubbed));
      expect(transport.timeUs, 66667);
      scrub(-30);
      expect(transport.timeUs, 0);
      scrub(1e6);
      expect(transport.timeUs, owner.asset.durationUs);
      expect(owner.controller.active!.dirty, isFalse);
      expect(owner.controller.error, isNull);
      expect(owner.port.writes, 0);
    });

    test('ruler positions map to clamped microseconds', () {
      expect(
        presentationTimelineTimeAt(
          90,
          pixelsPerSecond: 60,
          durationUs: 12000000,
        ),
        1500000,
      );
      expect(
        presentationTimelineTimeAt(
          90,
          pixelsPerSecond: 30,
          durationUs: 2000000,
        ),
        2000000,
      );
      expect(
        presentationTimelineTimeAt(
          -1,
          pixelsPerSecond: 60,
          durationUs: 12000000,
        ),
        0,
      );
    });

    test('transport answers the keyboard without a focused panel', () {
      final asset = owner.asset;
      transport.playing ? transport.pause() : transport.play();
      expect(transport.playing, isTrue);
      transport.playing ? transport.pause() : transport.play();
      expect(transport.playing, isFalse);
      transport.seek(1000000);
      transport.stepForward();
      final forward = transport.timeUs;
      expect(forward, greaterThan(1000000));
      transport.stepBackward();
      expect(transport.timeUs, 1000000);
      transport.seek(transport.durationUs);
      expect(transport.timeUs, asset.durationUs);
      transport.seek(0);
      expect(transport.timeUs, 0);
      expect(owner.asset, same(asset));
      expect(owner.controller.active!.dirty, isFalse);
      expect(owner.port.writes, 0);
    });
  });

  testWidgets('scrubbing does not churn the media between frames', (
    tester,
  ) async {
    final media = (await tester.runAsync(
      PresentationWorkspaceOwnerFixture.create,
    ))!;
    final transport = PresentationPreviewTransport()..install(media.asset);
    final visuals = StudioPresentationVisuals(
      projectRoot: media.fixture.source.directory.path,
      revision: media.controller.active!.base!.revision,
      catalog: media.controller.active!.mediaCatalog,
    );
    void scrub(double dx) => scrubPresentationTimeline(
      transport,
      dx,
      pixelsPerSecond: 60,
      durationUs: media.asset.durationUs,
    );
    await tester.runAsync(() => visuals.prepare(media.asset, portrait: false));
    visuals.bindTransport(transport);
    await settle(tester, visuals.settled);
    final releases = visuals.mediaReleases;
    final publishes = visuals.mediaPublishes;

    transport.setScrubbing(true);
    for (var i = 1; i <= 6; i++) {
      scrub(40.0 * i);
    }
    expect(transport.scrubbing, isTrue);
    expect(visuals.mediaPublishes, greaterThan(publishes));
    expect(visuals.mediaReleases, releases);

    transport.setScrubbing(false);
    expect(transport.scrubbing, isFalse);
    expect(visuals.mediaReleases, releases);

    scrub(10);
    expect(visuals.mediaReleases, releases + 1);
    await settle(tester, visuals.settled);
    await settle(tester, visuals.close());
    visuals.dispose();
    transport.dispose();
    await tester.runAsync(media.dispose);
  });
}

Future<void> settle(WidgetTester tester, Future<void> future) async {
  var done = false;
  final pending = future.whenComplete(() => done = true);
  for (var i = 0; i < 100 && !done; i++) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  expect(done, isTrue);
  await pending;
}
