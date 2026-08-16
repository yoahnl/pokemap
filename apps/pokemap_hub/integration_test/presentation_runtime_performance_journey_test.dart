import 'dart:async';
import 'dart:io';
import 'dart:ui' show FrameTiming;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/presentation_renderer.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:video_player/video_player.dart';

const _requestedOutputPath = String.fromEnvironment('POKEMAP_CIN038_OUTPUT');
const _landscapeVideoAsset =
    'assets/certification/intro_landscape_h264_aac.mp4';
const _portraitVideoAsset = 'assets/certification/intro_portrait_h264_aac.mp4';
const _posterAsset = 'assets/avelune/artwork/fallback_moonlit_path.webp';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'certifies presentation runtime lifecycle and budgets',
    (tester) async {
      expect(const bool.fromEnvironment('dart.vm.profile'), isTrue);
      expect(_requestedOutputPath, isNotEmpty);
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final landscapeVideoBytes = _bytes(
        await rootBundle.load(_landscapeVideoAsset),
      );
      final portraitVideoBytes = _bytes(
        await rootBundle.load(_portraitVideoAsset),
      );
      final posterBytes = _bytes(await rootBundle.load(_posterAsset));
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'pokemap-cin-038-',
      );
      addTearDown(() => temporaryDirectory.delete(recursive: true));
      final landscapeVideoFile = File(
        '${temporaryDirectory.path}/cin038-landscape.mp4',
      );
      final portraitVideoFile = File(
        '${temporaryDirectory.path}/cin038-portrait.mp4',
      );
      await landscapeVideoFile.writeAsBytes(landscapeVideoBytes, flush: true);
      await portraitVideoFile.writeAsBytes(portraitVideoBytes, flush: true);

      final driver = VideoPlayerPresentationPlaybackDriver();
      final mediaController = RuntimePresentationMediaPlaybackController(
        catalog: _catalog(
          landscapeVideoBytes.length,
          portraitVideoBytes.length,
          posterBytes.length,
        ),
        targetPlatform: PresentationMediaTargetPlatform.macos,
        resolveUri:
            (media) =>
                media.id == 'cin038-landscape-video'
                    ? landscapeVideoFile.uri
                    : portraitVideoFile.uri,
        videoDriver: driver,
      );
      final receipts = <PresentationExecutionReceipt>[];
      final execution = RuntimePresentationExecutionController(
        mediaController: mediaController,
        onReceipt: receipts.add,
      );
      addTearDown(execution.dispose);

      final frameSamples = <int>[];
      void recordFrames(List<FrameTiming> timings) {
        frameSamples.addAll(
          timings.map((timing) => timing.totalSpan.inMicroseconds),
        );
      }

      WidgetsBinding.instance.addTimingsCallback(recordFrames);
      addTearDown(
        () => WidgetsBinding.instance.removeTimingsCallback(recordFrames),
      );
      final heartbeat = _MainIsolateHeartbeat()..start();
      addTearDown(heartbeat.stop);

      final skipSamples = <int>[];
      final posterSamples = <int>[];
      final videoFirstFrameSamples = <int>[];
      var maximumActiveDecoders = 0;
      var terminalReceipts = 0;
      var skippedTerminals = 0;
      var rssCycle5Bytes = 0;
      var rssCycle50Bytes = 0;
      final cycleEvidence = <Map<String, Object?>>[];

      for (var cycle = 1; cycle <= 50; cycle += 1) {
        final orientation =
            cycle.isOdd
                ? PresentationFrameOrientation.landscape
                : PresentationFrameOrientation.portrait;
        final videoMediaId =
            cycle.isOdd ? 'cin038-landscape-video' : 'cin038-portrait-video';
        final currentVideoBytes =
            cycle.isOdd ? landscapeVideoBytes : portraitVideoBytes;
        final posterProvider = MemoryImage(posterBytes);
        await posterProvider.evict();
        final posterWatch = Stopwatch()..start();
        await tester.pumpWidget(
          _app(Image(image: posterProvider), orientation: orientation),
        );
        await tester.pump();
        await tester.runAsync(
          () => precacheImage(
            posterProvider,
            tester.element(
              find.byKey(const ValueKey<String>('cin038-frame-surface')),
            ),
          ),
        );
        await tester.pump();
        posterWatch.stop();
        posterSamples.add(posterWatch.elapsedMicroseconds);

        final token = execution.start(
          observability: PresentationExecutionCorrelation(
            runId: 'cin038-cycle-$cycle',
            projectRevision:
                'sha256:${sha256.convert('cin038-project'.codeUnits)}',
            assetId: 'cin038-presentation',
            contentHash: 'sha256:${sha256.convert(currentVideoBytes)}',
          ),
        );
        final firstFrameWatch = Stopwatch()..start();
        final playback = await mediaController.playVideo(videoMediaId);
        execution.observeMediaPlaybackSnapshot(token, playback);
        expect(
          playback.status,
          RuntimePresentationMediaPlaybackStatus.playingVideo,
        );
        final handle = playback.videoHandle;
        expect(handle, isNotNull);
        maximumActiveDecoders =
            maximumActiveDecoders < driver.activeDecoderCount
                ? driver.activeDecoderCount
                : maximumActiveDecoders;

        final terminal = Completer<RuntimePresentationExecutionTerminal?>();
        await tester.pumpWidget(
          _app(
            driver.buildVideo(handle!),
            orientation: orientation,
            onSkip: () async {
              terminal.complete(await execution.skip(token));
            },
          ),
        );
        await tester.pump();
        final video = tester.widget<VideoPlayer>(find.byType(VideoPlayer));
        final deadline = DateTime.now().add(const Duration(seconds: 2));
        while (video.controller.value.position <= Duration.zero &&
            DateTime.now().isBefore(deadline)) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 16)),
          );
          await tester.pump();
        }
        expect(video.controller.value.position, greaterThan(Duration.zero));
        await tester.pump();
        firstFrameWatch.stop();
        videoFirstFrameSamples.add(firstFrameWatch.elapsedMicroseconds);

        final paused = await execution.pauseForLifecycle(token);
        expect(paused.phase, RuntimePresentationExecutionPhase.paused);
        final resumed = await execution.resumeAfterLifecycle(token);
        expect(resumed.phase, RuntimePresentationExecutionPhase.running);

        final skipWatch = Stopwatch()..start();
        await tester.tap(find.byKey(const ValueKey<String>('cin038-skip')));
        await tester.pump();
        final terminalResult = await tester.runAsync(() => terminal.future);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        skipWatch.stop();
        skipSamples.add(skipWatch.elapsedMicroseconds);

        expect(terminalResult, isNotNull);
        expect(
          terminalResult!.result,
          RuntimePresentationExecutionResult.skipped,
        );
        expect(driver.activeDecoderCount, 0);
        expect(mediaController.snapshot.videoHandle, isNull);
        final receipt = execution.lastReceipt;
        expect(receipt, isNotNull);
        terminalReceipts += 1;
        if (receipt!.terminal.outcome == PresentationExecutionOutcome.skipped) {
          skippedTerminals += 1;
        }
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
        final rssAfterCooldownBytes = ProcessInfo.currentRss;
        cycleEvidence.add(<String, Object?>{
          'cycle': cycle,
          'orientation': orientation.name,
          'replay': (cycle + 1) ~/ 2,
          'lifecycle': 'pause-resume',
          'activeDecoderAfterExit': driver.activeDecoderCount,
          'rssAfterCooldownBytes': rssAfterCooldownBytes,
        });
        if (cycle == 5) rssCycle5Bytes = rssAfterCooldownBytes;
        if (cycle == 50) rssCycle50Bytes = rssAfterCooldownBytes;
      }

      heartbeat.stop();
      await execution.dispose();
      expect(receipts, hasLength(50));
      expect(frameSamples, isNotEmpty);
      expect(heartbeat.samplesUs, isNotEmpty);

      binding.reportData = <String, dynamic>{
        'requestedOutputPath': _requestedOutputPath,
        'schemaVersion': 1,
        'benchmark': 'presentation_runtime_cin_038',
        'target':
            'integration_test/presentation_runtime_performance_journey_test.dart',
        'executionMode': 'flutter-profile',
        'platform': 'macos',
        'fixture': <String, Object?>{
          'landscapeVideoAsset': _landscapeVideoAsset,
          'landscapeVideoSha256':
              sha256.convert(landscapeVideoBytes).toString(),
          'portraitVideoAsset': _portraitVideoAsset,
          'portraitVideoSha256': sha256.convert(portraitVideoBytes).toString(),
          'posterAsset': _posterAsset,
          'posterSha256': sha256.convert(posterBytes).toString(),
        },
        'lifecycle': <String, Object?>{
          'cycles': 50,
          'maximumActiveDecoders': maximumActiveDecoders,
          'finalActiveDecoders': driver.activeDecoderCount,
          'finalMediaHandles':
              mediaController.snapshot.videoHandle == null ? 0 : 1,
          'terminalReceipts': terminalReceipts,
          'skippedTerminals': skippedTerminals,
          'rssCycle5Bytes': rssCycle5Bytes,
          'rssCycle50Bytes': rssCycle50Bytes,
        },
        'cycleEvidence': cycleEvidence,
        'samples': <String, Object?>{
          'skipUs': skipSamples,
          'posterUs': posterSamples,
          'videoFirstFrameUs': videoFirstFrameSamples,
          'mainIsolateStallUs': heartbeat.samplesUs,
          'uiFrameTotalUs': frameSamples,
        },
      };
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

Uint8List _bytes(ByteData data) =>
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

ProjectMediaCatalog _catalog(
  int landscapeVideoBytes,
  int portraitVideoBytes,
  int posterBytes,
) => ProjectMediaCatalog(
  entries: <ProjectMediaAsset>[
    ProjectMediaAsset(
      id: 'cin038-landscape-video',
      label: 'CIN-038 landscape video',
      kind: ProjectMediaKind.video,
      sourceAssetId: 'cin038-landscape-video-source',
      posterMediaId: 'cin038-poster',
      technicalMetadata: ProjectMediaTechnicalMetadata(
        mediaType: 'video/mp4',
        container: 'mp4',
        codec: 'h264',
        audioCodec: 'aac',
        sizeBytes: landscapeVideoBytes,
        width: 320,
        height: 180,
        durationMilliseconds: 2000,
      ),
    ),
    ProjectMediaAsset(
      id: 'cin038-portrait-video',
      label: 'CIN-038 portrait video',
      kind: ProjectMediaKind.video,
      sourceAssetId: 'cin038-portrait-video-source',
      posterMediaId: 'cin038-poster',
      technicalMetadata: ProjectMediaTechnicalMetadata(
        mediaType: 'video/mp4',
        container: 'mp4',
        codec: 'h264',
        audioCodec: 'aac',
        sizeBytes: portraitVideoBytes,
        width: 180,
        height: 320,
        durationMilliseconds: 2000,
      ),
    ),
    ProjectMediaAsset(
      id: 'cin038-poster',
      label: 'CIN-038 poster',
      kind: ProjectMediaKind.poster,
      sourceAssetId: 'cin038-poster-source',
      technicalMetadata: ProjectMediaTechnicalMetadata(
        mediaType: 'image/webp',
        container: 'webp',
        codec: 'webp',
        sizeBytes: posterBytes,
        width: 512,
        height: 853,
      ),
    ),
  ],
);

Widget _app(
  Widget visual, {
  required PresentationFrameOrientation orientation,
  Future<void> Function()? onSkip,
}) => MaterialApp(
  theme: PokeMapPlayerTheme.dark(),
  home: _BenchmarkSurface(
    visual: visual,
    orientation: orientation,
    onSkip: onSkip,
  ),
);

final class _BenchmarkSurface extends StatefulWidget {
  const _BenchmarkSurface({
    required this.visual,
    required this.orientation,
    required this.onSkip,
  });

  final Widget visual;
  final PresentationFrameOrientation orientation;
  final Future<void> Function()? onSkip;

  @override
  State<_BenchmarkSurface> createState() => _BenchmarkSurfaceState();
}

final class _BenchmarkSurfaceState extends State<_BenchmarkSurface> {
  var _showVisual = true;
  var _skipStarted = false;

  void _skip() {
    if (_skipStarted) return;
    _skipStarted = true;
    setState(() => _showVisual = false);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      await widget.onSkip?.call();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: <Widget>[
        Positioned.fill(
          child:
              _showVisual
                  ? RuntimePresentationFrameSurface(
                    key: const ValueKey<String>('cin038-frame-surface'),
                    snapshot: RuntimePresentationFrameSnapshot(
                      assetRevision: 'cin038-revision',
                      frame: _frame(),
                      orientation: widget.orientation,
                    ),
                    contentPort: _VisualContentPort(widget.visual),
                  )
                  : const SizedBox.shrink(),
        ),
        if (widget.onSkip != null)
          Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
              key: const ValueKey<String>('cin038-skip'),
              onPressed: _skip,
              child: const Text('Skip'),
            ),
          ),
      ],
    ),
  );
}

PresentationFrame _frame() => PresentationFrame(
  cinematicId: 'cin038-presentation',
  timeUs: 0,
  durationUs: 2000000,
  visuals: <PresentationVisualFrameClip>[
    PresentationVisualFrameClip(
      clipId: 'cin038-visual',
      trackId: 'visuals',
      layerId: 'main',
      zIndex: 0,
      resourceId: 'cin038-resource',
      startUs: 0,
      durationUs: 2000000,
      elapsedUs: 0,
      progress: 0,
      easedProgress: 0,
      easing: PresentationEasing.linear,
      composition: PresentationVisualComposition.identity,
      reducedMotionComposition: PresentationVisualComposition.identity,
    ),
  ],
);

final class _VisualContentPort implements PresentationFrameContentPort {
  const _VisualContentPort(this.visual);

  final Widget visual;

  @override
  PresentationVisualResolution resolveVisual({
    required PresentationVisualFrameClip clip,
    required PresentationFrameOrientation orientation,
  }) => PresentationVisualReady(child: visual);

  @override
  PresentationCaptionResolution resolveCaption({
    required PresentationCaptionFrameClip clip,
    required Locale locale,
  }) => const PresentationCaptionUnavailable(
    reason: PresentationContentUnavailableReason.missing,
    message: 'Unavailable',
  );
}

final class _MainIsolateHeartbeat {
  final List<int> samplesUs = <int>[];
  final Stopwatch _clock = Stopwatch();
  Timer? _timer;
  int _previousUs = 0;

  void start() {
    _clock.start();
    _previousUs = _clock.elapsedMicroseconds;
    _timer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      final now = _clock.elapsedMicroseconds;
      final delay = now - _previousUs - 10000;
      samplesUs.add(delay > 0 ? delay : 0);
      _previousUs = now;
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _clock.stop();
  }
}
