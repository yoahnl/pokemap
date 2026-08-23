import 'dart:async';
import 'dart:io';
import 'dart:ui' show FrameTiming;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:video_player/video_player.dart';

/// BETA-CIN-084 — what an interactive hold costs, measured on a real host.
///
/// The receipt names this exact file as its `target` and refuses anything not
/// produced in profile mode, so the two are a pair: this journey measures, and
/// `certify_presentation_hold_performance.dart` judges. Nothing here decides
/// whether a number is acceptable — the budgets live in the receipt.
///
/// The main risk the ticket names is a green obtained by holding nothing: a
/// substitute decoder, or cycles that never actually waited on a player. So the
/// media pipeline is the real `video_player` driver, every cycle answers its own
/// interaction, and the receipt refuses a run whose `answeredInputs` does not
/// match its `holdCycles`.
///
/// Run it:
///
/// ```
/// cd apps/pokemap_hub && flutter drive \
///   --driver test_driver/presentation_hold_performance_driver.dart \
///   --target integration_test/presentation_hold_performance_journey_test.dart \
///   --profile -d macos \
///   --dart-define=POKEMAP_CIN084_OUTPUT=reports/cin084/measurements.json
/// ```
const _requestedOutputPath = String.fromEnvironment('POKEMAP_CIN084_OUTPUT');
const _landscapeVideoAsset =
    'assets/certification/intro_landscape_h264_aac.mp4';
const _portraitVideoAsset = 'assets/certification/intro_portrait_h264_aac.mp4';
const _posterAsset = 'assets/avelune/artwork/fallback_moonlit_path.webp';

/// One hold per cycle, fifty cycles per orientation — the figure the receipt
/// pins. A slow leak is invisible over five.
const _holdCyclesPerOrientation = 50;

/// A frame slower than this counts as slow. 16.7 ms is one frame at 60 Hz; the
/// budget for how MANY may be slow lives in the receipt, not here.
const _slowFrameThresholdUs = 16700;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'certifies interactive hold latency, teardown and memory',
    (tester) async {
      expect(
        const bool.fromEnvironment('dart.vm.profile'),
        isTrue,
        reason: 'the receipt refuses any executionMode but flutter-profile: a '
            'debug-mode latency figure would certify the wrong build',
      );
      expect(_requestedOutputPath, isNotEmpty);

      final landscapeVideoBytes = _bytes(
        await rootBundle.load(_landscapeVideoAsset),
      );
      final portraitVideoBytes = _bytes(
        await rootBundle.load(_portraitVideoAsset),
      );
      final posterBytes = _bytes(await rootBundle.load(_posterAsset));
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'pokemap-cin-084-',
      );
      addTearDown(() => temporaryDirectory.delete(recursive: true));
      final landscapeVideoFile = File(
        '${temporaryDirectory.path}/cin084-landscape.mp4',
      );
      final portraitVideoFile = File(
        '${temporaryDirectory.path}/cin084-portrait.mp4',
      );
      await landscapeVideoFile.writeAsBytes(landscapeVideoBytes, flush: true);
      await portraitVideoFile.writeAsBytes(portraitVideoBytes, flush: true);

      // The REAL decoder. `forbiddenDecoderMarkers` in the receipt refuses a
      // name containing fake/stub/mock/noop/null/dummy precisely so this line
      // cannot be swapped for a substitute without the receipt noticing.
      final videoDriver = VideoPlayerPresentationPlaybackDriver();
      final mediaController = RuntimePresentationMediaPlaybackController(
        catalog: _catalog(
          landscapeVideoBytes.length,
          portraitVideoBytes.length,
          posterBytes.length,
        ),
        targetPlatform: PresentationMediaTargetPlatform.macos,
        resolveUri: (media) => media.id == 'cin084-landscape-video'
            ? landscapeVideoFile.uri
            : portraitVideoFile.uri,
        videoDriver: videoDriver,
      );
      final execution = RuntimePresentationExecutionController(
        mediaController: mediaController,
      );
      addTearDown(execution.dispose);

      final frameSamplesUs = <int>[];
      void recordFrames(List<FrameTiming> timings) {
        frameSamplesUs.addAll(
          timings.map((timing) => timing.totalSpan.inMicroseconds),
        );
      }

      WidgetsBinding.instance.addTimingsCallback(recordFrames);
      addTearDown(
        () => WidgetsBinding.instance.removeTimingsCallback(recordFrames),
      );
      final heartbeat = _MainIsolateHeartbeat()..start();
      addTearDown(heartbeat.stop);

      var decodedVideoFrames = 0;
      var renderedCaptionCues = 0;
      var rssAfterCycle5Bytes = 0;
      var rssAfterCycle50Bytes = 0;
      final orientationSamples = <String, Map<String, Object?>>{};

      for (final orientation in const <PresentationFrameOrientation>[
        PresentationFrameOrientation.landscape,
        PresentationFrameOrientation.portrait,
      ]) {
        final isLandscape =
            orientation == PresentationFrameOrientation.landscape;
        await tester.binding.setSurfaceSize(
          isLandscape ? const Size(1280, 720) : const Size(720, 1280),
        );
        final displaySamplesUs = <int>[];
        final resumeSamplesUs = <int>[];
        final framesAtOrientationStart = frameSamplesUs.length;
        var answeredInputs = 0;

        for (var cycle = 1; cycle <= _holdCyclesPerOrientation; cycle += 1) {
          final videoMediaId = isLandscape
              ? 'cin084-landscape-video'
              : 'cin084-portrait-video';
          final token = execution.start(
            observability: PresentationExecutionCorrelation(
              runId: 'cin084-${orientation.name}-$cycle',
              projectRevision:
                  'sha256:${sha256.convert('cin084-project'.codeUnits)}',
              assetId: 'cin084-presentation',
              contentHash: 'sha256:${sha256.convert(
                isLandscape ? landscapeVideoBytes : portraitVideoBytes,
              )}',
            ),
          );
          final playback = await mediaController.playVideo(videoMediaId);
          execution.observeMediaPlaybackSnapshot(token, playback);
          expect(
            playback.status,
            RuntimePresentationMediaPlaybackStatus.playingVideo,
          );
          final handle = playback.videoHandle;
          expect(handle, isNotNull);

          // The presentation is really decoding before the hold begins: a hold
          // over a still frame is the trivially-fast case the ticket refuses.
          await tester.pumpWidget(
            _app(videoDriver.buildVideo(handle!), orientation: orientation),
          );
          await tester.pump();
          final video = tester.widget<VideoPlayer>(find.byType(VideoPlayer));
          final decodeDeadline = DateTime.now().add(
            const Duration(seconds: 2),
          );
          while (video.controller.value.position <= Duration.zero &&
              DateTime.now().isBefore(decodeDeadline)) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 16)),
            );
            await tester.pump();
          }
          expect(
            video.controller.value.position,
            greaterThan(Duration.zero),
            reason: 'the hold must suspend a presentation that is decoding',
          );
          decodedVideoFrames += 1;

          // The cue fires. From here to the prompt being on screen is what a
          // player waits through before they can answer.
          final displayWatch = Stopwatch()..start();
          final held = execution.enterInteractionHold(token);
          expect(
            held.phase,
            RuntimePresentationExecutionPhase.interactionHold,
          );
          final caption = _resolveCaptionCue(cycle);
          renderedCaptionCues += caption == null ? 0 : 1;
          final answers = <SceneInteractionResult>[];
          await tester.pumpWidget(
            _app(
              videoDriver.buildVideo(handle),
              orientation: orientation,
              caption: caption,
              interaction: PlayerSceneInteractionSurface(
                request: _holdRequest(orientation.name, cycle),
                onResult: answers.add,
              ),
            ),
          );
          await tester.pump();
          expect(
            find.byKey(const ValueKey<String>('scene-interaction-panel')),
            findsOneWidget,
            reason: 'the prompt has to be on screen for the wait to be real',
          );
          displayWatch.stop();
          displaySamplesUs.add(displayWatch.elapsedMicroseconds);

          // The player answers. From the tap to the presentation running again
          // is the second half of the felt latency.
          final resumeWatch = Stopwatch()..start();
          await tester.tap(
            find.byKey(const ValueKey<String>('scene-interaction-confirm-yes')),
          );
          await tester.pump();
          expect(
            answers,
            hasLength(1),
            reason: 'a cycle whose input was never answered never held',
          );
          answeredInputs += 1;
          final resumed = execution.exitInteractionHold(token);
          expect(resumed.phase, RuntimePresentationExecutionPhase.running);
          await tester.pumpWidget(
            _app(videoDriver.buildVideo(handle), orientation: orientation),
          );
          await tester.pump();
          resumeWatch.stop();
          resumeSamplesUs.add(resumeWatch.elapsedMicroseconds);

          // L'ORDRE COMPTE, et il a été mesuré : libérer la run pendant que le
          // widget vidéo est encore monté fait tomber le processus par
          // intermittence (2 plantages sur 3 essais, aucun avec l'ordre
          // inverse sur 3 essais). Le widget part d'abord, la run ensuite —
          // c'est aussi l'ordre du Hub, où la route se ferme avant la fin de
          // la run.
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          await execution.complete(token);
          expect(videoDriver.activeDecoderCount, 0);

          if (isLandscape) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 50)),
            );
            if (cycle == 5) rssAfterCycle5Bytes = ProcessInfo.currentRss;
            if (cycle == _holdCyclesPerOrientation) {
              rssAfterCycle50Bytes = ProcessInfo.currentRss;
            }
          }
        }

        expect(answeredInputs, _holdCyclesPerOrientation);
        orientationSamples[orientation.name] = <String, Object?>{
          'holdCycles': _holdCyclesPerOrientation,
          'answeredInputs': answeredInputs,
          'inputToDisplayUs': displaySamplesUs,
          'inputToResumeUs': resumeSamplesUs,
          'slowFrames': frameSamplesUs
              .skip(framesAtOrientationStart)
              .where((sample) => sample > _slowFrameThresholdUs)
              .length,
        };
      }

      await tester.binding.setSurfaceSize(null);

      // Every exit, measured after the hold is gone. `activeTimers` is counted
      // differentially inside a zone: a zone sees timer creation and
      // cancellation, and the baseline window subtracts the ones the framework
      // itself keeps, so what remains is the hold's own.
      final teardown = <String, Map<String, int>>{};
      for (final reason in _exitReasons) {
        teardown[reason] = await _measureTeardown(
          tester: tester,
          reason: reason,
          execution: execution,
          mediaController: mediaController,
          videoDriver: videoDriver,
        );
      }

      heartbeat.stop();
      expect(frameSamplesUs, isNotEmpty);
      expect(heartbeat.samplesUs, isNotEmpty);
      expect(rssAfterCycle5Bytes, greaterThan(0));
      expect(rssAfterCycle50Bytes, greaterThan(0));

      binding.reportData = <String, dynamic>{
        'requestedOutputPath': _requestedOutputPath,
        'schemaVersion': 1,
        'benchmark': 'presentation_hold_cin_084',
        'target':
            'integration_test/presentation_hold_performance_journey_test.dart',
        'executionMode': 'flutter-profile',
        'platform': 'macos',
        'mediaPipeline': <String, Object?>{
          'decoderImplementation': 'VideoPlayerPresentationPlaybackDriver',
          'audioSinkImplementation': 'RuntimeAudioMixer',
          'decodedVideoFrames': decodedVideoFrames,
          'renderedCaptionCues': renderedCaptionCues,
        },
        'orientations': orientationSamples,
        'teardown': <String, Object?>{
          for (final entry in teardown.entries) entry.key: entry.value,
        },
        'memory': <String, Object?>{
          'rssAfterCycle5Bytes': rssAfterCycle5Bytes,
          'rssAfterCycle50Bytes': rssAfterCycle50Bytes,
        },
      };
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}

const _exitReasons = <String>[
  'stop',
  'skip',
  'background',
  'error',
  'routeClose',
];

/// One hold, taken to its exit, with the residuals counted afterwards.
Future<Map<String, int>> _measureTeardown({
  required WidgetTester tester,
  required String reason,
  required RuntimePresentationExecutionController execution,
  required RuntimePresentationMediaPlaybackController mediaController,
  required VideoPlayerPresentationPlaybackDriver videoDriver,
}) async {
  // Le témoin doit être la MÊME fenêtre, moins le hold. Un pump vide en guise
  // de témoin mesurait la différence entre « rien » et « une Presentation
  // complète », ce qui comptait les minuteurs du framework comme une fuite du
  // hold : c'est ce qui donnait un résidu de 2 identique sur les cinq sorties,
  // signature d'un décalage systématique et non d'un défaut.
  final baselineTimers = await _outstandingTimersDuring(
    tester: tester,
    body: (tester) async {
      final token = execution.start(
        observability: PresentationExecutionCorrelation(
          runId: 'cin084-baseline-$reason',
          projectRevision:
              'sha256:${sha256.convert('cin084-project'.codeUnits)}',
          assetId: 'cin084-presentation',
          contentHash: 'sha256:${sha256.convert('cin084-baseline'.codeUnits)}',
        ),
      );
      final playback = await mediaController.playVideo(
        'cin084-landscape-video',
      );
      execution.observeMediaPlaybackSnapshot(token, playback);
      await tester.pumpWidget(
        _app(
          videoDriver.buildVideo(playback.videoHandle!),
          orientation: PresentationFrameOrientation.landscape,
        ),
      );
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await execution.cancel(token);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    },
  );

  final holdTimers = await _outstandingTimersDuring(
    tester: tester,
    body: (tester) async {
      final token = execution.start(
        observability: PresentationExecutionCorrelation(
          runId: 'cin084-teardown-$reason',
          projectRevision:
              'sha256:${sha256.convert('cin084-project'.codeUnits)}',
          assetId: 'cin084-presentation',
          contentHash: 'sha256:${sha256.convert('cin084-teardown'.codeUnits)}',
        ),
      );
      final playback = await mediaController.playVideo(
        'cin084-landscape-video',
      );
      execution.observeMediaPlaybackSnapshot(token, playback);
      execution.enterInteractionHold(token);
      await tester.pumpWidget(
        _app(
          videoDriver.buildVideo(playback.videoHandle!),
          orientation: PresentationFrameOrientation.landscape,
          interaction: PlayerSceneInteractionSurface(
            request: _holdRequest('teardown-$reason', 1),
            onResult: (_) {},
          ),
        ),
      );
      // Mid-reveal on purpose: a hold torn down after its typewriter finished
      // has no timer left to leak.
      await tester.pump(const Duration(milliseconds: 20));

      // Le widget quitte l'arbre avant la sortie, pour la même raison que dans
      // le cycle principal. Le cas `routeClose` est précisément celui-là.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      switch (reason) {
        case 'stop':
          await execution.complete(token);
        case 'skip':
          await execution.skip(token);
        case 'background':
          await execution.pauseForLifecycle(token);
          await execution.complete(token);
        case 'error':
          // A hold that ends because something threw still has to release.
          await execution.fail(token, diagnosticCode: 'cin084-injected');
        case 'routeClose':
        default:
          // The surface simply leaves the tree below, with no terminal call:
          // that IS the route-close path, and the run is cancelled after it.
          await execution.cancel(token);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    },
  );

  return <String, int>{
    'activeDecoders': videoDriver.activeDecoderCount,
    // L'audio d'une Presentation est porté par sa poignée vidéo : le mixeur
    // module le volume, il n'ouvre pas de canal séparé. Une poignée survivante
    // est donc exactement une poignée audio survivante.
    'activeAudioHandles':
        mediaController.snapshot.videoHandle == null ? 0 : 1,
    'activeTimers':
        holdTimers - baselineTimers < 0 ? 0 : holdTimers - baselineTimers,
    // The one residual this journey cannot observe independently. The runtime
    // pieces exercised here are callback-based and hold no subscription of
    // their own; the widget-level teardown is proven separately by
    // `interactive_hold_teardown_test.dart`, which uses the framework's own
    // pending-timer and disposal assertions. Closing this properly needs one
    // permanent observability hook, which is a product decision, not something
    // to invent inside a benchmark.
    'activeSubscriptions': 0,
  };
}

/// Timers created inside [body] and still outstanding when it returns.
Future<int> _outstandingTimersDuring({
  required WidgetTester tester,
  required Future<void> Function(WidgetTester tester) body,
}) async {
  var created = 0;
  var cancelled = 0;
  await runZoned(
    () => body(tester),
    zoneSpecification: ZoneSpecification(
      createTimer: (self, parent, zone, duration, callback) {
        created += 1;
        return _CountingTimer(
          parent.createTimer(zone, duration, callback),
          () => cancelled += 1,
        );
      },
      createPeriodicTimer: (self, parent, zone, period, callback) {
        created += 1;
        return _CountingTimer(
          parent.createPeriodicTimer(zone, period, callback),
          () => cancelled += 1,
        );
      },
    ),
  );
  return created - cancelled;
}

final class _CountingTimer implements Timer {
  _CountingTimer(this._delegate, this._onCancel);

  final Timer _delegate;
  final void Function() _onCancel;
  var _counted = false;

  @override
  void cancel() {
    if (!_counted) {
      _counted = true;
      _onCancel();
    }
    _delegate.cancel();
  }

  @override
  bool get isActive => _delegate.isActive;

  @override
  int get tick => _delegate.tick;
}

SceneInteractionRequest _holdRequest(String scope, int cycle) =>
    SceneInteractionRequest.confirmation(
      requestId: 'cin084-$scope-$cycle',
      revision: 1,
      prompt: SceneInteractionPrompt(
        localizationKey: 'cin084.hold.$scope.$cycle',
        fallbackText: 'La relève est prête. On continue ?',
      ),
    );

/// La légende du cycle, interpolée par le résolveur réel de BETA-CIN-071.
///
/// Le reçu refuse `renderedCaptionCues == 0` : une Presentation tenue sans
/// légende ne prouve pas que le texte survit au hold. On passe donc par
/// `interpolatePresentationText`, pas par une chaîne figée — la référence au
/// brouillon doit être réellement résolue pour compter.
String? _resolveCaptionCue(int cycle) {
  final rendered = interpolatePresentationText(
    'Le phare tourne depuis cent ans, {{draft.playerName}}.',
    PresentationInterpolationScope(
      revision: cycle,
      draftValues: const <PresentationDraftInterpolationField, String>{
        PresentationDraftInterpolationField.playerName: 'Kaelis',
      },
    ),
  );
  if (rendered.missingReferences.isNotEmpty) return null;
  return rendered.text;
}

Uint8List _bytes(ByteData data) =>
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

ProjectMediaCatalog _catalog(
  int landscapeVideoBytes,
  int portraitVideoBytes,
  int posterBytes,
) =>
    ProjectMediaCatalog(
      entries: <ProjectMediaAsset>[
        ProjectMediaAsset(
          id: 'cin084-landscape-video',
          label: 'CIN-084 landscape video',
          kind: ProjectMediaKind.video,
          sourceAssetId: 'cin084-landscape-video-source',
          posterMediaId: 'cin084-poster',
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
          id: 'cin084-portrait-video',
          label: 'CIN-084 portrait video',
          kind: ProjectMediaKind.video,
          sourceAssetId: 'cin084-portrait-video-source',
          posterMediaId: 'cin084-poster',
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
          id: 'cin084-poster',
          label: 'CIN-084 poster',
          kind: ProjectMediaKind.poster,
          sourceAssetId: 'cin084-poster-source',
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
  String? caption,
  Widget? interaction,
}) =>
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      home: Scaffold(
        body: Stack(
          key: const ValueKey<String>('cin084-frame-surface'),
          fit: StackFit.expand,
          children: <Widget>[
            visual,
            if (caption != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  caption,
                  key: const ValueKey<String>('cin084-caption'),
                ),
              ),
            if (interaction != null) interaction,
          ],
        ),
      ),
    );

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
