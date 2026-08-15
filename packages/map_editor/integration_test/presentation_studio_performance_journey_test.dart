import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:integration_test/integration_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/application/authoring_api/presentation_studio_timeline_authoring_gateway.dart';
import 'package:map_editor/src/application/authoring_api/presentation_studio_timeline_command.dart';
import 'package:map_editor/src/application/authoring_api/presentation_timeline_projection_gateway.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/narrative_document_route.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/infrastructure/riverpod_retry_policy.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/cinematics/presentation/presentation_studio_timeline.dart';
import 'package:map_editor/src/ui/canvas/cinematics/presentation/presentation_timeline_editing_controller.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_navigation.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/editor_shell_page.dart';

import '../test_driver/performance_driver.dart' as performance_driver;
import '../test_driver/support/presentation_studio_performance_contract.dart';
import 'support/presentation_studio_performance_fixture.dart';

const _requestedOutputPath = String.fromEnvironment('POKEMAP_PERF_OUTPUT');
const _accentChannel = MethodChannel('appkit_ui_element_colors');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'certifies CIN-060 small medium and limit Studio fixtures',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_accentChannel, (call) async {
            if (call.method == 'getColorComponents') {
              return <String, double>{'hueComponent': 0.58};
            }
            if (call.method == 'getColor') return 0xFF0A84FF;
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_accentChannel, null);
      });

      final fixtures = <PresentationStudioPerformanceFixture>[
        PresentationStudioPerformanceFixture.build(
          name: 'small',
          libraryAssets: 10,
          layers: 10,
          tracks: 10,
          clips: 100,
        ),
        PresentationStudioPerformanceFixture.build(
          name: 'medium',
          libraryAssets: 250,
          layers: 50,
          tracks: 50,
          clips: 500,
        ),
        PresentationStudioPerformanceFixture.build(
          name: 'limit',
          libraryAssets: 1000,
          layers: 100,
          tracks: 100,
          clips: 1100,
        ),
      ];
      final scenarios = <Map<String, Object?>>[];
      _OpenCloseEvidence? openCloseEvidence;
      for (final fixture in fixtures) {
        final measured = await _measureScenario(tester, fixture);
        scenarios.add(measured.scenario);
        if (fixture.name == 'limit') openCloseEvidence = measured.openClose;
      }
      final media = await _measureMediaCache();
      final authoringSession = await _measureAuthoringSession();
      final openClose = openCloseEvidence!;
      final report = <String, dynamic>{
        'schemaVersion': 2,
        'generatorVersion': 1,
        'benchmark': 'presentation_studio_cin_060',
        'target': presentationStudioPerformanceTarget,
        'requestedOutputPath': _requestedOutputPath,
        'executionMode': const bool.fromEnvironment('dart.vm.profile')
            ? 'flutter-profile'
            : 'flutter-debug',
        'fixtureMatrix': <Map<String, Object?>>[
          for (final fixture in fixtures) fixture.toContractJson(),
        ],
        'performanceBudgets': presentationStudioPerformanceBudgets,
        'optimizationPolicy': const <String, Object?>{
          'certificationOnly': true,
          'hiddenOptimizations': 0,
        },
        'scenarios': scenarios,
        'media': media,
        'session': <String, Object?>{
          'undoRedoCycles': 50,
          'openCloseCycles': 50,
          'rateLimitCooldowns': authoringSession.rateLimitCooldowns,
          'undo': authoringSession.undo,
          'redo': authoringSession.redo,
          'rssBeforeBytes': openClose.rssBeforeBytes,
          'rssAfterBytes': openClose.rssAfterBytes,
          'rssGrowthBytes': openClose.rssAfterBytes - openClose.rssBeforeBytes,
          'fileHandlesBefore': openClose.fileHandlesBefore,
          'fileHandlesAfter': openClose.fileHandlesAfter,
          'fileHandleGrowth':
              openClose.fileHandlesAfter - openClose.fileHandlesBefore,
          'orphanedTransactions': authoringSession.orphanedTransactions,
          'draftPreservedAfterConflict':
              authoringSession.draftPreservedAfterConflict,
        },
      };
      performance_driver.validatePerformancePayload(report);
      binding.reportData = report;
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}

Future<_MeasuredScenario> _measureScenario(
  WidgetTester tester,
  PresentationStudioPerformanceFixture fixture,
) async {
  final firstLibrary = Stopwatch()..start();
  final harness = await _EditorHarness.start(tester, fixture.project);
  firstLibrary.stop();
  try {
    await tester.tap(find.text('Cinématiques de présentation'));
    await tester.pump();
    for (final folderId in fixture.folderIds) {
      await tester.tap(
        find.byKey(ValueKey<String>('cinematic-folder-$folderId')),
      );
      await tester.pump();
    }
    final list = find.byKey(
      const ValueKey<String>('cinematic-list-presentation'),
    );
    final scrollable = find.descendant(
      of: list,
      matching: find.byType(Scrollable),
    );
    if (scrollable.evaluate().isNotEmpty) {
      await tester.drag(list, const Offset(0, -600));
      await tester.pump();
    }
    final search = find.byKey(
      const ValueKey<String>('cinematic-family-search'),
    );
    final searchSamples = <int>[];
    for (var index = 0; index < 31; index++) {
      final watch = Stopwatch()..start();
      await tester.enterText(search, index.isEven ? 'Needle' : 'needle');
      await tester.pump();
      watch.stop();
      searchSamples.add(watch.elapsedMicroseconds);
    }
    final scrollAtOpen = scrollable.evaluate().isEmpty
        ? 0.0
        : tester.state<ScrollableState>(scrollable.first).position.pixels;
    final studioOpen = Stopwatch()..start();
    await _openTarget(tester, fixture.target.id);
    studioOpen.stop();
    final route = harness.container
        .read(narrativeStudioNavigationControllerProvider)
        .documentRoute!;
    final source = route.source as NarrativeLibrarySourceContext;
    final restoredFolder = source.folderId == fixture.folderIds.last;
    final restoredScrollOffset =
        (source.scrollOffset - scrollAtOpen).abs() < 0.5;
    final restoredQuery = source.searchQuery.toLowerCase().contains('needle');
    final controllerMetrics = _measureControllerMetrics(fixture.target);
    final frameMetrics = await _measureTimelineFrames(tester);
    final visibleTracks = find
        .byType(PokeMapCinematicTrackRow)
        .evaluate()
        .length;
    final visibleClips = find
        .byType(PokeMapCinematicTimelineClip)
        .evaluate()
        .length;
    _OpenCloseEvidence? openClose;
    if (fixture.name == 'limit') {
      openClose = await _measureOpenClose(tester, fixture);
    } else {
      await _closeTarget(tester);
    }
    expect(restoredFolder, isTrue);
    expect(restoredScrollOffset, isTrue);
    expect(restoredQuery, isTrue);
    return _MeasuredScenario(
      scenario: <String, Object?>{
        'fixture': fixture.name,
        'library': <String, Object?>{
          'firstUs': firstLibrary.elapsedMicroseconds,
          'search': _metrics(searchSamples),
          'restoredFolder': restoredFolder,
          'restoredScrollOffset': restoredScrollOffset,
          'restoredQuery': restoredQuery,
        },
        'studio': <String, Object?>{
          'firstFrameUs': studioOpen.elapsedMicroseconds,
          ...controllerMetrics,
          'frames': frameMetrics,
          'visibleTrackWidgetsMax': visibleTracks,
          'visibleClipWidgetsMax': visibleClips,
        },
      },
      openClose: openClose,
    );
  } finally {
    await harness.dispose(tester);
  }
}

Map<String, Object?> _measureControllerMetrics(
  PresentationCinematicAsset asset,
) {
  final viewport = PresentationTimelineViewportController(
    durationUs: asset.durationUs,
  )..configureViewport(960);
  final editing = PresentationTimelineEditingController(asset: asset);
  final clip = asset.tracks.first.clips.first;
  final pointer = <int>[];
  final drag = <int>[];
  final trim = <int>[];
  final scrub = <int>[];
  final zoom = <int>[];
  for (var index = 0; index < 60; index++) {
    pointer.add(
      _measureSync(
        () => viewport.timeUsAtViewportX((index * 13 % 960).toDouble()),
      ),
    );
    drag.add(
      _measureSync(() {
        editing.beginDrag(
          clipId: clip.id,
          kind: PresentationTimelineDragKind.move,
        );
        editing.updateDrag(deltaUs: 100000 + index);
        editing.cancelDrag();
      }),
    );
    trim.add(
      _measureSync(() {
        editing.beginDrag(
          clipId: clip.id,
          kind: PresentationTimelineDragKind.trimEnd,
        );
        editing.updateDrag(deltaUs: index.isEven ? 100000 : -100000);
        editing.cancelDrag();
      }),
    );
    scrub.add(
      _measureSync(() => viewport.seekTo(index * asset.durationUs ~/ 60)),
    );
    zoom.add(
      _measureSync(
        () => viewport.zoomAt(
          factor: index.isEven ? 1.01 : 0.99,
          anchorViewportX: 480,
        ),
      ),
    );
  }
  editing.dispose();
  viewport.dispose();
  return <String, Object?>{
    'pointer': _metrics(pointer),
    'drag': _metrics(drag),
    'trim': _metrics(trim),
    'scrub': _metrics(scrub),
    'zoom': _metrics(zoom),
  };
}

Future<Map<String, Object?>> _measureTimelineFrames(WidgetTester tester) async {
  final timings = <FrameTiming>[];
  void capture(List<FrameTiming> value) => timings.addAll(value);
  SchedulerBinding.instance.addTimingsCallback(capture);
  try {
    final ruler = find.byType(PokeMapCinematicTimelineViewportRuler);
    expect(ruler, findsOneWidget);
    final rect = tester.getRect(ruler);
    for (var index = 0; index < 60; index++) {
      final x = rect.left + 8 + (index * 17 % mathMax(1, rect.width - 16));
      await tester.tapAt(Offset(x, rect.center.dy));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
  } finally {
    SchedulerBinding.instance.removeTimingsCallback(capture);
  }
  expect(timings.length, greaterThanOrEqualTo(60));
  final measured = timings.sublist(timings.length - 60);
  return <String, Object?>{
    'build': _metrics([
      for (final timing in measured) timing.buildDuration.inMicroseconds,
    ]),
    'raster': _metrics([
      for (final timing in measured) timing.rasterDuration.inMicroseconds,
    ]),
    'total': _metrics([
      for (final timing in measured) timing.totalSpan.inMicroseconds,
    ]),
  };
}

Future<_OpenCloseEvidence> _measureOpenClose(
  WidgetTester tester,
  PresentationStudioPerformanceFixture fixture,
) async {
  final rssBefore = ProcessInfo.currentRss;
  final handlesBefore = _fileHandleCount();
  for (var cycle = 0; cycle < 50; cycle++) {
    await _closeTarget(tester);
    await _openTarget(tester, fixture.target.id);
  }
  await _closeTarget(tester);
  return _OpenCloseEvidence(
    rssBeforeBytes: rssBefore,
    rssAfterBytes: ProcessInfo.currentRss,
    fileHandlesBefore: handlesBefore,
    fileHandlesAfter: _fileHandleCount(),
  );
}

Future<Map<String, Object?>> _measureMediaCache() async {
  final reader = _ProjectionReader();
  final gateway = CanonicalPresentationTimelineProjectionGateway(
    reader: reader,
  );
  final cold = <int>[];
  final warm = <int>[];
  var warmLoads = 0;
  var backgroundDecodeResponsive = true;
  for (var index = 0; index < 31; index++) {
    final controller = PresentationTimelineProjectionController(
      projectRootPath: '/cin-060',
      gateway: gateway,
    );
    final clips = <PresentationClip>[
      PresentationAudioClip(
        id: 'audio-$index',
        startUs: 0,
        durationUs: 1000000,
        resourceId: 'audio-$index.wav',
      ),
      PresentationVisualClip(
        id: 'video-$index',
        startUs: 0,
        durationUs: 1000000,
        layerId: 'layer-$index',
        resourceId: 'video-$index.mp4',
        mediaKind: PresentationVisualMediaKind.video,
      ),
      PresentationCaptionClip(
        id: 'captions-$index',
        startUs: 0,
        durationUs: 1000000,
        captionId: 'captions-$index.vtt',
      ),
    ];
    final coldWatch = Stopwatch()..start();
    controller.sync(clips: clips, pixelsPerSecond: 80);
    backgroundDecodeResponsive =
        backgroundDecodeResponsive &&
        clips.every(
          (clip) =>
              controller.projectionFor(clip, pixelsPerSecond: 80)?.loading ==
              true,
        );
    await _waitForProjections(controller, clips);
    coldWatch.stop();
    cold.add(coldWatch.elapsedMicroseconds);
    final beforeWarm = reader.loads;
    final warmWatch = Stopwatch()..start();
    controller.sync(clips: clips, pixelsPerSecond: 80);
    await Future<void>.delayed(Duration.zero);
    warmWatch.stop();
    warm.add(warmWatch.elapsedMicroseconds);
    warmLoads += reader.loads - beforeWarm;
    controller.dispose();
  }
  return <String, Object?>{
    'cold': _metrics(cold),
    'warm': _metrics(warm),
    'projectionKinds': const <String>['audio', 'video', 'captions'],
    'backgroundDecodeResponsive': backgroundDecodeResponsive,
    'coldGatewayLoads': reader.loads,
    'warmGatewayLoads': warmLoads,
  };
}

Future<void> _waitForProjections(
  PresentationTimelineProjectionController controller,
  List<PresentationClip> clips,
) async {
  for (var attempt = 0; attempt < 500; attempt++) {
    if (clips.every(
      (clip) =>
          controller.projectionFor(clip, pixelsPerSecond: 80)?.loading == false,
    )) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
  fail('CIN-060 media projections timed out.');
}

Future<_AuthoringSessionEvidence> _measureAuthoringSession() async {
  final root = await Directory.systemTemp.createTemp('cin-060-session-');
  final file = File('${root.path}/project.json');
  final container = ProviderContainer(retry: disableAutomaticProviderRetry);
  try {
    var current = _sessionManifest();
    await file.writeAsString(jsonEncode(current.toJson()), flush: true);
    final mutations = container.read(authoringMutationAdapterProvider);
    final queries = container.read(authoringQueryAdapterProvider);
    final gateway = CanonicalPresentationStudioTimelineAuthoringGateway(
      mutations: mutations,
      queries: queries,
    );
    final undo = <int>[];
    final redo = <int>[];
    for (var cycle = 0; cycle < 50; cycle++) {
      if (cycle > 0 && cycle % 20 == 0) {
        await Future<void>.delayed(const Duration(seconds: 61));
      }
      final targetUs = cycle.isEven ? 2000000 : 3000000;
      final command = _markerCommand(targetUs);
      final committed = await gateway.apply(
        root.path,
        expectedProject: current,
        command: command,
      );
      final undoWatch = Stopwatch()..start();
      final restored = await gateway.undo(
        root.path,
        expectedProject: committed.manifest,
        transaction: committed,
      );
      undoWatch.stop();
      undo.add(undoWatch.elapsedMicroseconds);
      final redoWatch = Stopwatch()..start();
      final redone = await gateway.redo(
        root.path,
        expectedProject: restored,
        transaction: committed,
      );
      redoWatch.stop();
      redo.add(redoWatch.elapsedMicroseconds);
      current = redone.manifest;
    }
    final external = current.copyWith(name: 'External drift');
    await file.writeAsString(jsonEncode(external.toJson()), flush: true);
    var conflictRejected = false;
    try {
      await gateway.apply(
        root.path,
        expectedProject: current,
        command: _markerCommand(4000000),
      );
    } on EditorConflictException {
      conflictRejected = true;
    }
    final afterConflict = ProjectManifest.fromJson(
      Map<String, dynamic>.from(jsonDecode(await file.readAsString()) as Map),
    );
    await mutations.closeAll();
    await queries.closeAll();
    final transactions = Directory(
      '${root.path}/.pokemap/authoring/transactions',
    );
    final orphaned = await transactions.exists()
        ? transactions
              .listSync(followLinks: false)
              .whereType<Directory>()
              .length
        : 0;
    return _AuthoringSessionEvidence(
      undo: _metrics(undo),
      redo: _metrics(redo),
      rateLimitCooldowns: 2,
      orphanedTransactions: orphaned,
      draftPreservedAfterConflict:
          conflictRejected && afterConflict.name == 'External drift',
    );
  } finally {
    container.dispose();
    if (await root.exists()) await root.delete(recursive: true);
  }
}

ProjectManifest _sessionManifest() => ProjectManifest(
  name: 'CIN-060 session',
  version: ProjectVersion.v7,
  maps: const <ProjectMapEntry>[],
  tilesets: const <ProjectTilesetEntry>[],
  presentationCinematics: <PresentationCinematicAsset>[
    PresentationCinematicAsset(
      id: 'session',
      title: 'Session',
      durationUs: const Duration(seconds: 10).inMicroseconds,
      tracks: <PresentationTrack>[
        PresentationTrack(
          id: 'markers',
          label: 'Repères',
          kind: PresentationTrackKind.marker,
          clips: <PresentationClip>[
            PresentationMarkerClip(
              id: 'marker',
              startUs: 1000000,
              label: 'Repère',
            ),
          ],
        ),
      ],
    ),
  ],
);

PresentationTimelineClipCommand _markerCommand(int startUs) =>
    PresentationTimelineClipCommand(
      actionId: 'presentationClip.batch',
      parameters: <String, Object?>{
        'cinematicId': 'session',
        'operations': <Object?>[
          <String, Object?>{
            'kind': 'edit',
            'clipId': 'marker',
            'targetTrackId': 'markers',
            'startUs': startUs,
            'durationUs': 0,
          },
        ],
      },
    );

Future<void> _openTarget(WidgetTester tester, String targetId) async {
  final target = find.byKey(ValueKey<String>('cinematic-asset-$targetId'));
  await _pumpUntil(tester, () => target.hitTestable().evaluate().isNotEmpty);
  await tester.tap(target.hitTestable());
  await tester.pump();
  final open = find.byKey(const ValueKey<String>('cinematic-open-selection'));
  await _pumpUntil(tester, () => open.hitTestable().evaluate().isNotEmpty);
  await tester.tap(open.hitTestable());
  await _pumpUntil(
    tester,
    () => find
        .byKey(const ValueKey<String>('cinematics-presentation-document-route'))
        .evaluate()
        .isNotEmpty,
  );
}

Future<void> _closeTarget(WidgetTester tester) async {
  final back = find.byKey(
    const ValueKey<String>('cinematics-presentation-route-back'),
  );
  await _pumpUntil(tester, () => back.hitTestable().evaluate().isNotEmpty);
  await tester.tap(back.hitTestable());
  await _pumpUntil(
    tester,
    () => find
        .byKey(const ValueKey<String>('cinematics-library-workspace'))
        .evaluate()
        .isNotEmpty,
  );
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 300; attempt++) {
    if (condition()) return;
    await tester.pump(const Duration(milliseconds: 10));
  }
  fail('CIN-060 UI condition timed out.');
}

int _measureSync(void Function() operation) {
  final watch = Stopwatch()..start();
  operation();
  watch.stop();
  return watch.elapsedMicroseconds;
}

Map<String, Object?> _metrics(List<int> samples) {
  final sorted = List<int>.of(samples)..sort();
  int percentile(double value) {
    final index = (value * sorted.length).ceil() - 1;
    return sorted[index.clamp(0, sorted.length - 1)];
  }

  return <String, Object?>{
    'samplesUs': samples,
    'p50Us': percentile(0.50),
    'p95Us': percentile(0.95),
    'p99Us': percentile(0.99),
    'maxUs': sorted.last,
  };
}

int mathMax(int left, double right) =>
    left > right.floor() ? left : right.floor();

int _fileHandleCount() {
  final result = Process.runSync('/usr/sbin/lsof', <String>[
    '-p',
    '$pid',
    '-Ff',
  ]);
  if (result.exitCode != 0) return 0;
  return const LineSplitter()
      .convert(result.stdout as String)
      .where((line) => RegExp(r'^f\d+$').hasMatch(line))
      .length;
}

final class _EditorHarness {
  _EditorHarness(this.container, this._closeSubscription);

  static Future<_EditorHarness> start(
    WidgetTester tester,
    ProjectManifest project,
  ) async {
    final container = ProviderContainer(retry: disableAutomaticProviderRetry);
    final subscription = container.listen<EditorState>(
      editorNotifierProvider,
      (_, _) {},
      fireImmediately: true,
    );
    container.read(editorNotifierProvider.notifier).state = EditorState(
      project: project,
      workspaceMode: EditorWorkspaceMode.cutscene,
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.dark(),
          builder: (context, child) => PokeMapMacosCompatibilityBridge(
            child: child ?? const SizedBox.shrink(),
          ),
          home: const EditorShellPage(restoreLastOpenedProjectOnStartup: false),
        ),
      ),
    );
    await _pumpUntil(
      tester,
      () => find
          .byKey(const ValueKey<String>('cinematics-library-workspace'))
          .evaluate()
          .isNotEmpty,
    );
    return _EditorHarness(container, subscription.close);
  }

  final ProviderContainer container;
  final void Function() _closeSubscription;

  Future<void> dispose(WidgetTester tester) async {
    _closeSubscription();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    container.dispose();
  }
}

final class _ProjectionReader
    implements PresentationTimelineProjectionMediaReader {
  _ProjectionReader()
    : _poster = Uint8List.fromList(
        image.encodePng(image.Image(width: 8, height: 4)),
      ),
      _waveform = _pcmWav(<int>[-32768, 0, 32767, 0]);

  final Uint8List _poster;
  final Uint8List _waveform;
  int loads = 0;

  @override
  Future<PresentationTimelineProjectionMedia?> read(
    String projectRootPath,
    String mediaId,
  ) async {
    loads += 1;
    if (mediaId.endsWith('.wav')) {
      return PresentationTimelineProjectionMedia(
        mediaId: mediaId,
        kind: ProjectMediaKind.audio,
        sourceAvailable: true,
        sourceBytes: _waveform,
      );
    }
    if (mediaId.endsWith('.mp4')) {
      return PresentationTimelineProjectionMedia(
        mediaId: mediaId,
        kind: ProjectMediaKind.video,
        sourceAvailable: true,
        posterBytes: _poster,
      );
    }
    return PresentationTimelineProjectionMedia(
      mediaId: mediaId,
      kind: ProjectMediaKind.captions,
      sourceAvailable: true,
      sourceBytes: Uint8List.fromList(
        utf8.encode('WEBVTT\n\n00:00:00.000 --> 00:00:01.000\nCIN-060\n'),
      ),
    );
  }
}

Uint8List _pcmWav(List<int> samples) {
  final dataLength = samples.length * 2;
  final bytes = Uint8List(44 + dataLength);
  final data = ByteData.sublistView(bytes);
  bytes.setRange(0, 4, ascii.encode('RIFF'));
  data.setUint32(4, 36 + dataLength, Endian.little);
  bytes.setRange(8, 12, ascii.encode('WAVE'));
  bytes.setRange(12, 16, ascii.encode('fmt '));
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, 44100, Endian.little);
  data.setUint32(28, 88200, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  bytes.setRange(36, 40, ascii.encode('data'));
  data.setUint32(40, dataLength, Endian.little);
  for (var index = 0; index < samples.length; index++) {
    data.setInt16(44 + index * 2, samples[index], Endian.little);
  }
  return bytes;
}

final class _MeasuredScenario {
  const _MeasuredScenario({required this.scenario, required this.openClose});

  final Map<String, Object?> scenario;
  final _OpenCloseEvidence? openClose;
}

final class _OpenCloseEvidence {
  const _OpenCloseEvidence({
    required this.rssBeforeBytes,
    required this.rssAfterBytes,
    required this.fileHandlesBefore,
    required this.fileHandlesAfter,
  });

  final int rssBeforeBytes;
  final int rssAfterBytes;
  final int fileHandlesBefore;
  final int fileHandlesAfter;
}

final class _AuthoringSessionEvidence {
  const _AuthoringSessionEvidence({
    required this.undo,
    required this.redo,
    required this.rateLimitCooldowns,
    required this.orphanedTransactions,
    required this.draftPreservedAfterConflict,
  });

  final Map<String, Object?> undo;
  final Map<String, Object?> redo;
  final int rateLimitCooldowns;
  final int orphanedTransactions;
  final bool draftPreservedAfterConflict;
}
