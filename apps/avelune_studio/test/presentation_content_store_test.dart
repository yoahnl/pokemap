import 'dart:io';

import 'package:avelune_studio/platform/rendering/presentation_content_store.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_player_ui/presentation_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('playing a video does not report the poster of a later clip', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.close);
    final frame = fixture.frameAt(0);
    await fixture.store.prepare(fixture.asset, portrait: false);
    fixture.store.showFrame(fixture.asset, frame, portrait: false);
    fixture.sink.synchronize(
      asset: fixture.asset,
      frame: frame,
      orientation: PresentationFrameOrientation.landscape,
      running: false,
    );
    await fixture.sink.settled;

    expect(fixture.sink.videoFor('first'), isNotNull);
    expect(fixture.store.currentDiagnostic, isNull);
    expect(fixture.store.currentDiagnosticIsFailure, isFalse);
    expect(
      fixture.store.resolveVisual(
        clip: frame.visuals.single,
        orientation: PresentationFrameOrientation.landscape,
      ),
      isA<PresentationVisualReady>(),
    );
  });

  test('poster notice follows the playhead and clears at the end', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.close);
    await fixture.store.prepare(fixture.asset, portrait: false);

    fixture.store.showFrame(
      fixture.asset,
      fixture.frameAt(1000000),
      portrait: false,
    );
    expect(fixture.store.currentDiagnostic, 'Aperçu fixe : later');
    expect(fixture.store.currentDiagnosticIsFailure, isFalse);

    fixture.store.showFrame(
      fixture.asset,
      fixture.frameAt(2000000),
      portrait: false,
    );
    expect(fixture.store.currentDiagnostic, isNull);
  });

  test('portrait diagnostics use the selected image variant', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.close);
    await fixture.store.prepare(fixture.asset, portrait: true);

    fixture.store.showFrame(fixture.asset, fixture.frameAt(0), portrait: true);
    expect(fixture.store.currentDiagnostic, isNull);
    expect(fixture.store.currentDiagnosticIsFailure, isFalse);
  });
}

class _Fixture {
  _Fixture(this.root, this.asset, this.store, this.sink);

  final Directory root;
  final PresentationCinematicAsset asset;
  final PresentationContentStore store;
  final PresentationStudioMediaSink sink;

  static Future<_Fixture> create() async {
    final root = await Directory.systemTemp.createTemp('presentation-content-');
    final catalog = ProjectMediaCatalog(
      entries: [
        for (final id in ['first', 'later']) ...[
          ProjectMediaAsset(
            id: id,
            label: id,
            kind: ProjectMediaKind.video,
            sourceAssetId: '$id-asset',
            posterMediaId: '$id-poster',
          ),
          ProjectMediaAsset(
            id: '$id-poster',
            label: '$id poster',
            kind: ProjectMediaKind.image,
            sourceAssetId: '$id-poster-asset',
          ),
        ],
      ],
    );
    final sink = PresentationStudioMediaSink(
      catalog: catalog,
      mediaUris: {
        for (final id in ['first', 'later'])
          id: Uri.file('${root.path}/$id.mp4'),
      },
      targetPlatform: PresentationMediaTargetPlatform.macos,
      videoPlayback: _VideoPlayback(),
    );
    final store = PresentationContentStore(
      projectRoot: root.path,
      catalog: catalog,
      mediaUris: sink.mediaUris,
      stagedBytes: {
        for (final id in ['first', 'later']) '$id-poster': [1, 2, 3],
      },
    )..sink = sink;
    final asset = PresentationCinematicAsset(
      id: 'sequence',
      title: 'Sequence',
      durationUs: 2000000,
      layers: [PresentationLayer(id: 'film', label: 'Film', zIndex: 0)],
      tracks: [
        PresentationTrack(
          id: 'film',
          label: 'Film',
          kind: PresentationTrackKind.visual,
          clips: [
            for (final (id, start) in [('first', 0), ('later', 1000000)])
              PresentationVisualClip(
                id: '$id-clip',
                startUs: start,
                durationUs: 1000000,
                layerId: 'film',
                resourceId: id,
                mediaKind: PresentationVisualMediaKind.video,
                portraitResourceId: '$id-poster',
              ),
          ],
        ),
      ],
    );
    return _Fixture(root, asset, store, sink);
  }

  PresentationFrame frameAt(int timeUs) =>
      const PresentationCinematicEvaluator().evaluate(asset, timeUs: timeUs);

  Future<void> close() async {
    sink.dispose();
    await sink.settled;
    await root.delete(recursive: true);
  }
}

class _VideoPlayback implements PresentationStudioVideoPlayback {
  @override
  Future<Object> prepare(Uri source, {required double initialVolume}) async =>
      Object();

  @override
  Widget buildVideo(Object handle) => const SizedBox();

  @override
  Future<void> dispose(Object handle) async {}

  @override
  Future<void> pause(Object handle) async {}

  @override
  Future<void> play(Object handle) async {}

  @override
  Future<void> seek(Object handle, Duration position) async {}

  @override
  Future<void> setVolume(Object handle, double volume) async {}
}
