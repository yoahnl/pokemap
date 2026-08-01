# PERF-RM-00 — Diff exact des fichiers suivis modifiés

Cette annexe accompagne `perf_rm_00_observability.md` et reproduit le diff Git exact des fichiers suivis modifiés par le lot.

~~~~diff
diff --git a/.github/workflows/pokemap_hub_product_certification.yml b/.github/workflows/pokemap_hub_product_certification.yml
index 9444ea27d..b69946056 100644
--- a/.github/workflows/pokemap_hub_product_certification.yml
+++ b/.github/workflows/pokemap_hub_product_certification.yml
@@ -12,11 +12,16 @@ on:
     paths:
       - "apps/pokemap_hub/**"
       - "packages/map_core/**"
+      - "packages/map_authoring/**"
+      - "packages/map_battle/**"
       - "packages/map_distribution/**"
       - "packages/map_editor/**"
       - "packages/map_gameplay/**"
       - "packages/map_player_ui/**"
       - "packages/map_runtime/**"
+      - "examples/playable_runtime_host/**"
+      - "reports/performance/**"
+      - "tool/performance/**"
       - "pokemap_roadmap_mecaniques_fangame.md"
       - "reports/gameplay/**"
       - "tool/pokemap_product_certification/**"
@@ -117,6 +122,125 @@ jobs:
               test/narrative_large_project_workspace_performance_test.dart
           done
 
+  performance-observation:
+    # PERF-RM-00 is collection-only until at least ten comparable historical
+    # observations exist. Failures stay visible without becoming release gates.
+    continue-on-error: true
+    runs-on: macos-15
+    timeout-minutes: 10
+    steps:
+      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
+      - name: Install pinned Flutter SDK
+        run: |
+          git init "$RUNNER_TEMP/flutter"
+          git -C "$RUNNER_TEMP/flutter" remote add origin https://github.com/flutter/flutter.git
+          git -C "$RUNNER_TEMP/flutter" fetch --depth 1 origin \
+            "refs/tags/$FLUTTER_VERSION:refs/tags/$FLUTTER_VERSION"
+          git -C "$RUNNER_TEMP/flutter" checkout --detach "$FLUTTER_VERSION"
+          test "$(git -C "$RUNNER_TEMP/flutter" rev-parse HEAD)" = "$FLUTTER_REVISION"
+          echo "$RUNNER_TEMP/flutter/bin" >> "$GITHUB_PATH"
+      - name: Collect bounded pure-Dart AOT receipts
+        continue-on-error: true
+        env:
+          POKEMAP_FLUTTER_VERSION: ${{ env.FLUTTER_VERSION }}
+          POKEMAP_FLAME_VERSION: 1.37.0
+        run: |
+          mkdir -p packages/map_core/build/performance
+          cd packages/map_core
+          dart pub get
+          dart compile exe benchmark/surface_role_scaling.dart \
+            -o build/performance/surface_role_scaling
+          build/performance/surface_role_scaling \
+            --warmups 1 --samples 5 --sizes 400,2500 \
+            --fixtures dense,mixed --modes topology \
+            --output build/performance/surface_role_scaling.json
+          dart compile exe benchmark/map_paint_gesture.dart \
+            -o build/performance/map_paint_gesture
+          build/performance/map_paint_gesture \
+            --warmups 1 --samples 5 --sizes 256,1024 \
+            --stroke-lengths 1,100,1000 \
+            --output build/performance/map_paint_gesture.json
+          dart compile exe benchmark/group_hierarchy_scaling.dart \
+            -o build/performance/group_hierarchy_scaling
+          build/performance/group_hierarchy_scaling \
+            --warmups 1 --samples 5 --sizes 100,400 \
+            --output build/performance/group_hierarchy_scaling.json
+          dart compile exe benchmark/json_roundtrip_scaling.dart \
+            -o build/performance/json_roundtrip_scaling
+          build/performance/json_roundtrip_scaling \
+            --warmups 1 --samples 5 --bytes 1024,102400,2420033 \
+            --output build/performance/json_roundtrip_scaling.json
+          cd ../map_gameplay
+          dart pub get
+          mkdir -p build/performance
+          dart compile exe benchmark/world_collision_scaling.dart \
+            -o build/performance/world_collision_scaling
+          build/performance/world_collision_scaling \
+            --warmups 1 --samples 5 --sizes 32,128,256 \
+            --isolated-size 512 --isolated-runs 3 \
+            --output build/performance/world_collision_scaling.json
+          cd ../map_authoring
+          dart pub get
+          mkdir -p build/performance
+          dart compile exe benchmark/authoring_snapshot_open.dart \
+            -o build/performance/authoring_snapshot_open
+          build/performance/authoring_snapshot_open \
+            --warmups 1 --samples 5 --fixtures small,selbrume \
+            --roots 1,3 --cycles 1 \
+            --output build/performance/authoring_snapshot_open.json
+          cd ../map_battle
+          dart pub get
+          mkdir -p build/performance
+          dart compile exe benchmark/battle_turn_baseline.dart \
+            -o build/performance/battle_turn_baseline
+          build/performance/battle_turn_baseline \
+            --warmups 1 --samples 5 --turns 100,500 \
+            --output build/performance/battle_turn_baseline.json
+      - name: Verify the explicit collector test manifest
+        continue-on-error: true
+        run: |
+          cd packages/map_core
+          dart test \
+            test/benchmark/surface_role_scaling_cli_test.dart \
+            test/benchmark/map_paint_gesture_cli_test.dart \
+            test/benchmark/group_hierarchy_scaling_cli_test.dart \
+            test/benchmark/json_roundtrip_scaling_cli_test.dart
+          cd ../map_gameplay
+          dart test test/benchmark/world_collision_scaling_cli_test.dart
+          cd ../map_authoring
+          dart test test/benchmark/authoring_snapshot_open_cli_test.dart
+          cd ../map_battle
+          dart test test/benchmark/battle_turn_baseline_cli_test.dart
+          cd ../../examples/playable_runtime_host
+          flutter pub get
+          flutter test \
+            test/evaluation/interactive_frame_metrics_test.dart \
+            test/evaluation/interactive_worker_client_test.dart \
+            test/evaluation/pokemap_eval_cli_test.dart
+      - name: Collect editor profile journey
+        continue-on-error: true
+        working-directory: packages/map_editor
+        run: |
+          flutter pub get
+          flutter drive --profile -d macos \
+            --driver=test_driver/performance_driver.dart \
+            --target=integration_test/editor_project_journey_test.dart \
+            --dart-define=POKEMAP_PERF_OUTPUT=build/performance/editor_project_journey.json
+      - name: Preserve performance observation receipts
+        if: always()
+        uses: actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02
+        with:
+          name: pokemap-performance-observation-${{ github.sha }}
+          if-no-files-found: warn
+          retention-days: 30
+          path: |
+            packages/map_core/build/performance/*.json
+            packages/map_gameplay/build/performance/*.json
+            packages/map_authoring/build/performance/*.json
+            packages/map_battle/build/performance/*.json
+            packages/map_editor/build/performance/*.json
+            examples/playable_runtime_host/build/performance/*.json
+
   windows-desktop-certification:
     runs-on: windows-2025
     timeout-minutes: 45
diff --git a/examples/playable_runtime_host/lib/src/evaluation/interactive/interactive_frame_metrics.dart b/examples/playable_runtime_host/lib/src/evaluation/interactive/interactive_frame_metrics.dart
index c8aab5c49..23c766331 100644
--- a/examples/playable_runtime_host/lib/src/evaluation/interactive/interactive_frame_metrics.dart
+++ b/examples/playable_runtime_host/lib/src/evaluation/interactive/interactive_frame_metrics.dart
@@ -1,39 +1,226 @@
 import 'package:flutter/scheduler.dart';
 
 final class InteractiveFrameMetricsSnapshot {
-  const InteractiveFrameMetricsSnapshot({
+  InteractiveFrameMetricsSnapshot._({
     required this.frameCount,
     required this.averageBuildMilliseconds,
     required this.averageRasterMilliseconds,
     required this.maxBuildMilliseconds,
     required this.maxRasterMilliseconds,
-  });
+    required this.buildP50Milliseconds,
+    required this.buildP95Milliseconds,
+    required this.buildP99Milliseconds,
+    required this.rasterP50Milliseconds,
+    required this.rasterP95Milliseconds,
+    required this.rasterP99Milliseconds,
+    required this.frameSpanP50Milliseconds,
+    required this.frameSpanP95Milliseconds,
+    required this.frameSpanP99Milliseconds,
+    required this.framesOver16Point67Milliseconds,
+    required this.framesOver16Point67Rate,
+    required this.framesOver33Point3Milliseconds,
+    required this.framesOver33Point3Rate,
+    required List<int> buildSamplesMicroseconds,
+    required List<int> rasterSamplesMicroseconds,
+    required List<int> frameSpanSamplesMicroseconds,
+  })  : buildSamplesMicroseconds = List<int>.unmodifiable(
+          buildSamplesMicroseconds,
+        ),
+        rasterSamplesMicroseconds = List<int>.unmodifiable(
+          rasterSamplesMicroseconds,
+        ),
+        frameSpanSamplesMicroseconds = List<int>.unmodifiable(
+          frameSpanSamplesMicroseconds,
+        );
+
+  static const schemaVersion = 2;
+
+  factory InteractiveFrameMetricsSnapshot.fromMicrosecondSamples({
+    required List<int> buildMicroseconds,
+    required List<int> rasterMicroseconds,
+    required List<int> frameSpanMicroseconds,
+  }) {
+    if (buildMicroseconds.length != rasterMicroseconds.length ||
+        buildMicroseconds.length != frameSpanMicroseconds.length) {
+      throw const FormatException(
+        'Frame metric sample collections must have equal lengths.',
+      );
+    }
+    if (<List<int>>[
+      buildMicroseconds,
+      rasterMicroseconds,
+      frameSpanMicroseconds,
+    ].any((samples) => samples.any((sample) => sample < 0))) {
+      throw const FormatException('Frame metric samples cannot be negative.');
+    }
+
+    final builds = List<int>.of(buildMicroseconds);
+    final rasters = List<int>.of(rasterMicroseconds);
+    final spans = List<int>.of(frameSpanMicroseconds);
+    final sortedBuilds = List<int>.of(builds)..sort();
+    final sortedRasters = List<int>.of(rasters)..sort();
+    final sortedSpans = List<int>.of(spans)..sort();
+    final count = builds.length;
+    final over16 = spans.where((sample) => sample > 16670).length;
+    final over33 = spans.where((sample) => sample > 33300).length;
+
+    return InteractiveFrameMetricsSnapshot._(
+      frameCount: count,
+      averageBuildMilliseconds: _averageMilliseconds(builds),
+      averageRasterMilliseconds: _averageMilliseconds(rasters),
+      maxBuildMilliseconds: _maxMilliseconds(builds),
+      maxRasterMilliseconds: _maxMilliseconds(rasters),
+      buildP50Milliseconds: _percentileMilliseconds(sortedBuilds, 0.50),
+      buildP95Milliseconds: _percentileMilliseconds(sortedBuilds, 0.95),
+      buildP99Milliseconds: _percentileMilliseconds(sortedBuilds, 0.99),
+      rasterP50Milliseconds: _percentileMilliseconds(sortedRasters, 0.50),
+      rasterP95Milliseconds: _percentileMilliseconds(sortedRasters, 0.95),
+      rasterP99Milliseconds: _percentileMilliseconds(sortedRasters, 0.99),
+      frameSpanP50Milliseconds: _percentileMilliseconds(sortedSpans, 0.50),
+      frameSpanP95Milliseconds: _percentileMilliseconds(sortedSpans, 0.95),
+      frameSpanP99Milliseconds: _percentileMilliseconds(sortedSpans, 0.99),
+      framesOver16Point67Milliseconds: over16,
+      framesOver16Point67Rate: count == 0 ? 0 : over16 / count,
+      framesOver33Point3Milliseconds: over33,
+      framesOver33Point3Rate: count == 0 ? 0 : over33 / count,
+      buildSamplesMicroseconds: builds,
+      rasterSamplesMicroseconds: rasters,
+      frameSpanSamplesMicroseconds: spans,
+    );
+  }
+
+  factory InteractiveFrameMetricsSnapshot.fromJson(
+    Map<String, Object?> json,
+  ) {
+    if (json['schemaVersion'] != schemaVersion) {
+      throw const FormatException(
+        'Unsupported interactive frame metrics schema.',
+      );
+    }
+    const requiredKeys = <String>{
+      'schemaVersion',
+      'frameCount',
+      'averageBuildMilliseconds',
+      'averageRasterMilliseconds',
+      'maxBuildMilliseconds',
+      'maxRasterMilliseconds',
+      'buildP50Milliseconds',
+      'buildP95Milliseconds',
+      'buildP99Milliseconds',
+      'rasterP50Milliseconds',
+      'rasterP95Milliseconds',
+      'rasterP99Milliseconds',
+      'frameSpanP50Milliseconds',
+      'frameSpanP95Milliseconds',
+      'frameSpanP99Milliseconds',
+      'framesOver16Point67Milliseconds',
+      'framesOver16Point67Rate',
+      'framesOver33Point3Milliseconds',
+      'framesOver33Point3Rate',
+      'buildSamplesMicroseconds',
+      'rasterSamplesMicroseconds',
+      'frameSpanSamplesMicroseconds',
+    };
+    if (json.keys.toSet().difference(requiredKeys).isNotEmpty ||
+        requiredKeys.difference(json.keys.toSet()).isNotEmpty) {
+      throw const FormatException(
+        'Interactive frame metrics fields do not match schema V2.',
+      );
+    }
+    final frameCount = json['frameCount'];
+    if (frameCount is! int || frameCount < 0) {
+      throw const FormatException('frameCount must be a non-negative integer.');
+    }
+    final snapshot = InteractiveFrameMetricsSnapshot.fromMicrosecondSamples(
+      buildMicroseconds: _integerSamples(
+        json['buildSamplesMicroseconds'],
+        'buildSamplesMicroseconds',
+      ),
+      rasterMicroseconds: _integerSamples(
+        json['rasterSamplesMicroseconds'],
+        'rasterSamplesMicroseconds',
+      ),
+      frameSpanMicroseconds: _integerSamples(
+        json['frameSpanSamplesMicroseconds'],
+        'frameSpanSamplesMicroseconds',
+      ),
+    );
+    if (snapshot.frameCount != frameCount) {
+      throw const FormatException('frameCount does not match raw samples.');
+    }
+    for (final key in requiredKeys.difference(const <String>{
+      'schemaVersion',
+      'frameCount',
+      'buildSamplesMicroseconds',
+      'rasterSamplesMicroseconds',
+      'frameSpanSamplesMicroseconds',
+    })) {
+      final declared = json[key];
+      final computed = snapshot.toJson()[key];
+      if (declared is! num ||
+          declared.toDouble() != (computed! as num).toDouble()) {
+        throw FormatException('$key does not match raw samples.');
+      }
+    }
+    return snapshot;
+  }
 
   final int frameCount;
   final double averageBuildMilliseconds;
   final double averageRasterMilliseconds;
   final double maxBuildMilliseconds;
   final double maxRasterMilliseconds;
+  final double buildP50Milliseconds;
+  final double buildP95Milliseconds;
+  final double buildP99Milliseconds;
+  final double rasterP50Milliseconds;
+  final double rasterP95Milliseconds;
+  final double rasterP99Milliseconds;
+  final double frameSpanP50Milliseconds;
+  final double frameSpanP95Milliseconds;
+  final double frameSpanP99Milliseconds;
+  final int framesOver16Point67Milliseconds;
+  final double framesOver16Point67Rate;
+  final int framesOver33Point3Milliseconds;
+  final double framesOver33Point3Rate;
+  final List<int> buildSamplesMicroseconds;
+  final List<int> rasterSamplesMicroseconds;
+  final List<int> frameSpanSamplesMicroseconds;
 
   Map<String, Object?> toJson() => <String, Object?>{
+        'schemaVersion': schemaVersion,
         'frameCount': frameCount,
         'averageBuildMilliseconds': averageBuildMilliseconds,
         'averageRasterMilliseconds': averageRasterMilliseconds,
         'maxBuildMilliseconds': maxBuildMilliseconds,
         'maxRasterMilliseconds': maxRasterMilliseconds,
+        'buildP50Milliseconds': buildP50Milliseconds,
+        'buildP95Milliseconds': buildP95Milliseconds,
+        'buildP99Milliseconds': buildP99Milliseconds,
+        'rasterP50Milliseconds': rasterP50Milliseconds,
+        'rasterP95Milliseconds': rasterP95Milliseconds,
+        'rasterP99Milliseconds': rasterP99Milliseconds,
+        'frameSpanP50Milliseconds': frameSpanP50Milliseconds,
+        'frameSpanP95Milliseconds': frameSpanP95Milliseconds,
+        'frameSpanP99Milliseconds': frameSpanP99Milliseconds,
+        'framesOver16Point67Milliseconds': framesOver16Point67Milliseconds,
+        'framesOver16Point67Rate': framesOver16Point67Rate,
+        'framesOver33Point3Milliseconds': framesOver33Point3Milliseconds,
+        'framesOver33Point3Rate': framesOver33Point3Rate,
+        'buildSamplesMicroseconds': buildSamplesMicroseconds,
+        'rasterSamplesMicroseconds': rasterSamplesMicroseconds,
+        'frameSpanSamplesMicroseconds': frameSpanSamplesMicroseconds,
       };
 }
 
 /// Aggregates Flutter frame timings only while an interactive run is active.
 ///
-/// The collector never records the collision overlays: the interactive host
-/// keeps both collision visualizations disabled independently of this class.
+/// Build, raster and full-frame spans stay separate. Adding build and raster
+/// durations would double-count pipelined work and is intentionally forbidden.
 final class InteractiveFrameMetricsCollector {
-  int _frameCount = 0;
-  int _totalBuildMicroseconds = 0;
-  int _totalRasterMicroseconds = 0;
-  int _maxBuildMicroseconds = 0;
-  int _maxRasterMicroseconds = 0;
+  final List<int> _buildMicroseconds = <int>[];
+  final List<int> _rasterMicroseconds = <int>[];
+  final List<int> _frameSpanMicroseconds = <int>[];
   bool _recording = false;
 
   void start() {
@@ -56,47 +243,65 @@ final class InteractiveFrameMetricsCollector {
     if (_recording) {
       throw StateError('Cannot reset frame metrics while recording.');
     }
-    _frameCount = 0;
-    _totalBuildMicroseconds = 0;
-    _totalRasterMicroseconds = 0;
-    _maxBuildMicroseconds = 0;
-    _maxRasterMicroseconds = 0;
+    _buildMicroseconds.clear();
+    _rasterMicroseconds.clear();
+    _frameSpanMicroseconds.clear();
   }
 
   void recordDurations({
     required Duration build,
     required Duration raster,
+    Duration? frameSpan,
   }) {
-    _frameCount += 1;
-    _totalBuildMicroseconds += build.inMicroseconds;
-    _totalRasterMicroseconds += raster.inMicroseconds;
-    if (build.inMicroseconds > _maxBuildMicroseconds) {
-      _maxBuildMicroseconds = build.inMicroseconds;
+    if (build.isNegative ||
+        raster.isNegative ||
+        frameSpan?.isNegative == true) {
+      throw const FormatException('Frame durations cannot be negative.');
     }
-    if (raster.inMicroseconds > _maxRasterMicroseconds) {
-      _maxRasterMicroseconds = raster.inMicroseconds;
-    }
-  }
-
-  InteractiveFrameMetricsSnapshot snapshot() {
-    return InteractiveFrameMetricsSnapshot(
-      frameCount: _frameCount,
-      averageBuildMilliseconds:
-          _frameCount == 0 ? 0 : _totalBuildMicroseconds / _frameCount / 1000,
-      averageRasterMilliseconds:
-          _frameCount == 0 ? 0 : _totalRasterMicroseconds / _frameCount / 1000,
-      maxBuildMilliseconds: _maxBuildMicroseconds / 1000,
-      maxRasterMilliseconds: _maxRasterMicroseconds / 1000,
+    _buildMicroseconds.add(build.inMicroseconds);
+    _rasterMicroseconds.add(raster.inMicroseconds);
+    _frameSpanMicroseconds.add(
+      frameSpan?.inMicroseconds ??
+          (build > raster ? build.inMicroseconds : raster.inMicroseconds),
     );
   }
 
+  InteractiveFrameMetricsSnapshot snapshot() =>
+      InteractiveFrameMetricsSnapshot.fromMicrosecondSamples(
+        buildMicroseconds: _buildMicroseconds,
+        rasterMicroseconds: _rasterMicroseconds,
+        frameSpanMicroseconds: _frameSpanMicroseconds,
+      );
+
   void _onTimings(List<FrameTiming> timings) {
     if (!_recording) return;
     for (final timing in timings) {
       recordDurations(
         build: timing.buildDuration,
         raster: timing.rasterDuration,
+        frameSpan: timing.totalSpan,
       );
     }
   }
 }
+
+List<int> _integerSamples(Object? value, String field) {
+  if (value is! List || value.any((sample) => sample is! int)) {
+    throw FormatException('$field must contain integer microseconds.');
+  }
+  return List<int>.unmodifiable(value.cast<int>());
+}
+
+double _averageMilliseconds(List<int> samples) => samples.isEmpty
+    ? 0
+    : samples.reduce((left, right) => left + right) / samples.length / 1000;
+
+double _maxMilliseconds(List<int> samples) => samples.isEmpty
+    ? 0
+    : samples.reduce((left, right) => left > right ? left : right) / 1000;
+
+double _percentileMilliseconds(List<int> sortedSamples, double percentile) {
+  if (sortedSamples.isEmpty) return 0;
+  final index = (percentile * sortedSamples.length).ceil() - 1;
+  return sortedSamples[index.clamp(0, sortedSamples.length - 1)] / 1000;
+}
diff --git a/examples/playable_runtime_host/lib/src/evaluation/interactive/interactive_worker_client.dart b/examples/playable_runtime_host/lib/src/evaluation/interactive/interactive_worker_client.dart
index 46b56bf8d..c4c4a72fe 100644
--- a/examples/playable_runtime_host/lib/src/evaluation/interactive/interactive_worker_client.dart
+++ b/examples/playable_runtime_host/lib/src/evaluation/interactive/interactive_worker_client.dart
@@ -14,6 +14,11 @@ import '../worker/evaluation_worker_protocol.dart';
 
 const _interactiveProtocolVersion = 1;
 
+enum EvaluationBuildMode {
+  debug,
+  profile,
+}
+
 abstract interface class InteractiveProcessRunner {
   Future<InteractiveChildProcess> start(
     String executable,
@@ -58,7 +63,9 @@ final class InteractiveWorkerClient {
     Directory? packageRoot,
     InteractiveProcessRunner processRunner = const IoInteractiveProcessRunner(),
     String Function()? tokenGenerator,
-    this.readyTimeout = const Duration(seconds: 60),
+    // A cold macOS profile build can legitimately cross one minute before the
+    // bridge connects; envelope failures still use the same bounded timeout.
+    this.readyTimeout = const Duration(seconds: 120),
     void Function(String chunk)? stderrSink,
     this.flutterExecutable = 'flutter',
   })  : repositoryRoot = repositoryRoot.absolute,
@@ -86,6 +93,7 @@ final class InteractiveWorkerClient {
   Future<InteractiveWorkerLaunch> launch({
     required String projectFile,
     double playbackRate = 1,
+    EvaluationBuildMode buildMode = EvaluationBuildMode.debug,
   }) async {
     _validatePortablePath(projectFile, 'projectFile');
     if (!playbackRate.isFinite || playbackRate <= 0 || playbackRate > 4) {
@@ -113,7 +121,7 @@ final class InteractiveWorkerClient {
           'run',
           '-d',
           'macos',
-          '--debug',
+          '--${buildMode.name}',
           '--dart-define=POKEMAP_EVAL_INTERACTIVE=true',
           '--dart-define=POKEMAP_EVAL_HOST=127.0.0.1',
           '--dart-define=POKEMAP_EVAL_PORT=${listener.port}',
@@ -143,6 +151,7 @@ final class InteractiveWorkerClient {
     EvaluationWorkerRequest request, {
     double playbackRate = 1,
     void Function(EvaluationEvent event)? eventSink,
+    EvaluationBuildMode buildMode = EvaluationBuildMode.debug,
   }) async {
     InteractiveWorkerLaunch? session;
     try {
@@ -153,6 +162,7 @@ final class InteractiveWorkerClient {
       session = await launch(
         projectFile: '${request.projectRoot}/project.json',
         playbackRate: playbackRate,
+        buildMode: buildMode,
       );
       return await session.run(
         request: request,
diff --git a/examples/playable_runtime_host/test/evaluation/interactive_frame_metrics_test.dart b/examples/playable_runtime_host/test/evaluation/interactive_frame_metrics_test.dart
index c22af4ffb..de4b39b16 100644
--- a/examples/playable_runtime_host/test/evaluation/interactive_frame_metrics_test.dart
+++ b/examples/playable_runtime_host/test/evaluation/interactive_frame_metrics_test.dart
@@ -2,23 +2,59 @@ import 'package:flutter_test/flutter_test.dart';
 import 'package:pokemap_loader/src/evaluation/interactive/interactive_frame_metrics.dart';
 
 void main() {
-  test('collector reports frame count and worst frame durations', () {
+  test('collector reports separate percentiles and frame budget rates', () {
     final collector = InteractiveFrameMetricsCollector();
     collector.recordDurations(
-      build: const Duration(milliseconds: 4),
+      build: const Duration(milliseconds: 8),
       raster: const Duration(milliseconds: 7),
+      frameSpan: const Duration(milliseconds: 10),
+    );
+    collector.recordDurations(
+      build: const Duration(milliseconds: 1),
+      raster: const Duration(milliseconds: 30),
+      frameSpan: const Duration(milliseconds: 40),
+    );
+    collector.recordDurations(
+      build: const Duration(milliseconds: 4),
+      raster: const Duration(milliseconds: 20),
+      frameSpan: const Duration(milliseconds: 20),
     );
     collector.recordDurations(
-      build: const Duration(milliseconds: 6),
+      build: const Duration(milliseconds: 2),
       raster: const Duration(milliseconds: 5),
+      frameSpan: const Duration(milliseconds: 12),
     );
 
     final snapshot = collector.snapshot();
-    expect(snapshot.frameCount, 2);
-    expect(snapshot.maxBuildMilliseconds, 6);
-    expect(snapshot.maxRasterMilliseconds, 7);
-    expect(snapshot.averageBuildMilliseconds, 5);
-    expect(snapshot.averageRasterMilliseconds, 6);
+    expect(snapshot.frameCount, 4);
+    expect(snapshot.buildP50Milliseconds, 2);
+    expect(snapshot.buildP95Milliseconds, 8);
+    expect(snapshot.buildP99Milliseconds, 8);
+    expect(snapshot.rasterP50Milliseconds, 7);
+    expect(snapshot.rasterP95Milliseconds, 30);
+    expect(snapshot.frameSpanP50Milliseconds, 12);
+    expect(snapshot.frameSpanP95Milliseconds, 40);
+    expect(snapshot.framesOver16Point67Milliseconds, 2);
+    expect(snapshot.framesOver16Point67Rate, 0.5);
+    expect(snapshot.framesOver33Point3Milliseconds, 1);
+    expect(snapshot.framesOver33Point3Rate, 0.25);
+  });
+
+  test('unsorted samples are copied and ranked without mutating input', () {
+    final build = <int>[9000, 1000, 5000];
+    final raster = <int>[4000, 8000, 2000];
+    final spans = <int>[12000, 3000, 7000];
+
+    final snapshot = InteractiveFrameMetricsSnapshot.fromMicrosecondSamples(
+      buildMicroseconds: build,
+      rasterMicroseconds: raster,
+      frameSpanMicroseconds: spans,
+    );
+
+    expect(build, <int>[9000, 1000, 5000]);
+    expect(snapshot.buildP50Milliseconds, 5);
+    expect(snapshot.rasterP50Milliseconds, 4);
+    expect(snapshot.frameSpanP95Milliseconds, 12);
   });
 
   test('collector reset isolates consecutive runs', () {
@@ -32,12 +68,56 @@ void main() {
     expect(
       collector.snapshot().toJson(),
       <String, Object?>{
+        'schemaVersion': 2,
         'frameCount': 0,
         'averageBuildMilliseconds': 0,
         'averageRasterMilliseconds': 0,
         'maxBuildMilliseconds': 0,
         'maxRasterMilliseconds': 0,
+        'buildP50Milliseconds': 0,
+        'buildP95Milliseconds': 0,
+        'buildP99Milliseconds': 0,
+        'rasterP50Milliseconds': 0,
+        'rasterP95Milliseconds': 0,
+        'rasterP99Milliseconds': 0,
+        'frameSpanP50Milliseconds': 0,
+        'frameSpanP95Milliseconds': 0,
+        'frameSpanP99Milliseconds': 0,
+        'framesOver16Point67Milliseconds': 0,
+        'framesOver16Point67Rate': 0,
+        'framesOver33Point3Milliseconds': 0,
+        'framesOver33Point3Rate': 0,
+        'buildSamplesMicroseconds': <int>[],
+        'rasterSamplesMicroseconds': <int>[],
+        'frameSpanSamplesMicroseconds': <int>[],
       },
     );
   });
+
+  test('JSON parser rejects malformed and unknown frame metric schemas', () {
+    expect(
+      () => InteractiveFrameMetricsSnapshot.fromJson(
+        const <String, Object?>{'schemaVersion': 99},
+      ),
+      throwsFormatException,
+    );
+    expect(
+      () => InteractiveFrameMetricsSnapshot.fromJson(
+        const <String, Object?>{'schemaVersion': 2, 'frameCount': 'one'},
+      ),
+      throwsFormatException,
+    );
+  });
+
+  test('JSON round trip preserves raw frame samples', () {
+    final source = InteractiveFrameMetricsSnapshot.fromMicrosecondSamples(
+      buildMicroseconds: const <int>[1000, 9000],
+      rasterMicroseconds: const <int>[2000, 8000],
+      frameSpanMicroseconds: const <int>[3000, 12000],
+    );
+
+    final restored = InteractiveFrameMetricsSnapshot.fromJson(source.toJson());
+
+    expect(restored.toJson(), source.toJson());
+  });
 }
diff --git a/examples/playable_runtime_host/test/evaluation/interactive_worker_client_test.dart b/examples/playable_runtime_host/test/evaluation/interactive_worker_client_test.dart
index 9f91d260f..f49113d16 100644
--- a/examples/playable_runtime_host/test/evaluation/interactive_worker_client_test.dart
+++ b/examples/playable_runtime_host/test/evaluation/interactive_worker_client_test.dart
@@ -52,6 +52,27 @@ void main() {
     expect(process.workingDirectory, p.join(root.path, 'host'));
   });
 
+  test('client forwards profile mode to the Flutter process', () async {
+    final root = await Directory.systemTemp.createTemp('interactive-profile-');
+    addTearDown(() => root.delete(recursive: true));
+    final process = _RecordingProcessRunner();
+    final client = InteractiveWorkerClient(
+      repositoryRoot: root,
+      packageRoot: Directory(p.join(root.path, 'host')),
+      processRunner: process,
+      tokenGenerator: () => _token,
+    );
+
+    final launch = await client.launch(
+      projectFile: 'selbrume/project.json',
+      buildMode: EvaluationBuildMode.profile,
+    );
+    addTearDown(launch.close);
+
+    expect(process.arguments, contains('--profile'));
+    expect(process.arguments, isNot(contains('--debug')));
+  });
+
   test('client times out and terminates only its child process', () async {
     final root = await Directory.systemTemp.createTemp('interactive-timeout-');
     addTearDown(() => root.delete(recursive: true));
diff --git a/examples/playable_runtime_host/test/evaluation/pokemap_eval_cli_test.dart b/examples/playable_runtime_host/test/evaluation/pokemap_eval_cli_test.dart
index bdd182802..e152fe960 100644
--- a/examples/playable_runtime_host/test/evaluation/pokemap_eval_cli_test.dart
+++ b/examples/playable_runtime_host/test/evaluation/pokemap_eval_cli_test.dart
@@ -6,6 +6,8 @@ import 'package:path/path.dart' as p;
 import 'package:pokemap_loader/src/evaluation/contracts/evaluation_policy.dart';
 import 'package:pokemap_loader/src/evaluation/contracts/evaluation_receipt.dart';
 import 'package:pokemap_loader/src/evaluation/contracts/evaluation_scenario.dart';
+import 'package:pokemap_loader/src/evaluation/interactive/interactive_frame_metrics.dart';
+import 'package:pokemap_loader/src/evaluation/interactive/interactive_worker_client.dart';
 import 'package:pokemap_loader/src/evaluation/scenario/evaluation_scenario_parser.dart';
 import 'package:pokemap_loader/src/evaluation/worker/evaluation_worker_protocol.dart';
 
@@ -23,6 +25,159 @@ void main() {
     expect(options.target, EvaluationTarget.headless);
   });
 
+  test('profile run parses an explicit repeatable performance contract', () {
+    final options = PokeMapEvalCli.parse(
+      <String>[
+        'run',
+        'selbrume.shop.after-lysa',
+        '--target',
+        'interactive',
+        '--build-mode',
+        'profile',
+        '--runs',
+        '3',
+        '--json-output',
+        'build/performance/runtime.json',
+      ],
+    );
+
+    expect(options.buildMode, EvaluationBuildMode.profile);
+    expect(options.runs, 3);
+    expect(options.jsonOutput, 'build/performance/runtime.json');
+  });
+
+  test('profile run writes one V2 aggregate from isolated frame artifacts',
+      () async {
+    final fixture = await _CliFixture.create();
+    addTearDown(fixture.dispose);
+    await fixture.writeScenario();
+    var runIndex = 0;
+    fixture.interactiveWorker.onRun = (request, buildMode) async {
+      runIndex += 1;
+      expect(buildMode, EvaluationBuildMode.profile);
+      final output =
+          Directory(p.join(fixture.root.path, request.outputDirectory));
+      final frameFile =
+          File(p.join(output.path, 'artifacts', 'frame-metrics.json'));
+      await frameFile.create(recursive: true);
+      await frameFile.writeAsString(
+        jsonEncode(
+          InteractiveFrameMetricsSnapshot.fromMicrosecondSamples(
+            buildMicroseconds: <int>[1000 * runIndex, 2000 * runIndex],
+            rasterMicroseconds: <int>[3000 * runIndex, 4000 * runIndex],
+            frameSpanMicroseconds: <int>[5000 * runIndex, 20000 * runIndex],
+          ).toJson(),
+        ),
+      );
+      final receipt = File(p.join(output.path, 'receipt.json'));
+      await receipt.writeAsString(
+        jsonEncode(<String, Object?>{
+          'schemaVersion': 1,
+          'runId': request.runId,
+          'scenarioId': 'selbrume.test',
+          'target': 'interactive',
+          'status': 'succeeded',
+          'exitCode': 0,
+          'durationMilliseconds': 42,
+          'stepResults': <Object?>[
+            <String, Object?>{'passed': true},
+          ],
+          'diff': <String, Object?>{'changes': <Object?>[]},
+          'relativeReceiptPath': p.posix.join(
+            request.outputDirectory,
+            'receipt.json',
+          ),
+        }),
+      );
+      return EvaluationWorkerResult.completed(
+        runId: request.runId,
+        status: EvaluationRunStatus.succeeded,
+        exitCode: 0,
+        receiptPath: p.posix.join(request.outputDirectory, 'receipt.json'),
+      );
+    };
+
+    final result = await fixture.cli.execute(
+      <String>[
+        'run',
+        'selbrume.test',
+        '--target',
+        'interactive',
+        '--build-mode',
+        'profile',
+        '--runs',
+        '3',
+        '--json-output',
+        'build/performance/runtime.json',
+      ],
+    );
+
+    expect(result.exitCode, 0);
+    expect(fixture.interactiveWorker.requests, hasLength(3));
+    final output = File(p.join(
+      fixture.root.path,
+      'examples',
+      'playable_runtime_host',
+      'build',
+      'performance',
+      'runtime.json',
+    ));
+    final payload =
+        jsonDecode(await output.readAsString()) as Map<String, Object?>;
+    expect(payload['schemaVersion'], 2);
+    expect(payload['benchmark'], 'runtime_interactive_journey');
+    expect(payload['executionMode'], 'flutter-profile');
+    expect(payload['runCount'], 3);
+    expect(payload['runs'], hasLength(3));
+    final aggregate = payload['aggregateFrameMetrics']! as Map<String, Object?>;
+    expect(aggregate['frameCount'], 6);
+    expect(aggregate['framesOver16Point67Milliseconds'], 3);
+  });
+
+  test('performance options reject debug mode, zero runs, and output escape',
+      () async {
+    expect(
+      () => PokeMapEvalCli.parse(<String>[
+        'run',
+        'selbrume.test',
+        '--target',
+        'interactive',
+        '--runs',
+        '3',
+      ]),
+      throwsA(isA<PokeMapEvalUsageException>()),
+    );
+    expect(
+      () => PokeMapEvalCli.parse(<String>[
+        'run',
+        'selbrume.test',
+        '--target',
+        'interactive',
+        '--build-mode',
+        'profile',
+        '--runs',
+        '0',
+      ]),
+      throwsA(isA<PokeMapEvalUsageException>()),
+    );
+    final fixture = await _CliFixture.create();
+    addTearDown(fixture.dispose);
+    await fixture.writeScenario();
+    final escaped = await fixture.cli.execute(<String>[
+      'run',
+      'selbrume.test',
+      '--target',
+      'interactive',
+      '--build-mode',
+      'profile',
+      '--json-output',
+      '../runtime.json',
+    ]);
+    expect(escaped.exitCode, 2);
+    expect(fixture.interactiveWorker.requests, isEmpty);
+    expect(fixture.stderr.toString(), contains('must stay inside'));
+  });
+
   test('run target selects the interactive worker without changing policy',
       () async {
     final options = PokeMapEvalCli.parse(
@@ -283,14 +438,23 @@ final class _CliFixture {
 
 final class _FakeWorker implements PokeMapEvalWorker {
   final List<EvaluationWorkerRequest> requests = <EvaluationWorkerRequest>[];
+  Future<EvaluationWorkerResult> Function(
+    EvaluationWorkerRequest request,
+    EvaluationBuildMode buildMode,
+  )? onRun;
   EvaluationWorkerResult result = EvaluationWorkerResult.infrastructureFailure(
     runId: 'run-test',
     message: 'Worker result was not configured.',
   );
 
   @override
-  Future<EvaluationWorkerResult> run(EvaluationWorkerRequest request) async {
+  Future<EvaluationWorkerResult> run(
+    EvaluationWorkerRequest request, {
+    EvaluationBuildMode buildMode = EvaluationBuildMode.debug,
+  }) async {
     requests.add(request);
+    final handler = onRun;
+    if (handler != null) return handler(request, buildMode);
     if (result.runId == request.runId) return result;
     return switch (result.status) {
       EvaluationRunStatus.infrastructureFailure =>
diff --git a/examples/playable_runtime_host/tool/src/pokemap_eval_cli.dart b/examples/playable_runtime_host/tool/src/pokemap_eval_cli.dart
index c194d9cbb..c335ba44d 100644
--- a/examples/playable_runtime_host/tool/src/pokemap_eval_cli.dart
+++ b/examples/playable_runtime_host/tool/src/pokemap_eval_cli.dart
@@ -1,6 +1,7 @@
 import 'dart:convert';
 import 'dart:io';
 
+import 'package:crypto/crypto.dart';
 import 'package:path/path.dart' as p;
 import 'package:pokemap_loader/src/evaluation/contracts/evaluation_policy.dart';
 import 'package:pokemap_loader/src/evaluation/contracts/evaluation_scenario.dart';
@@ -30,6 +31,9 @@ final class PokeMapEvalOptions {
     this.includeBag = false,
     this.jsonOnly = false,
     this.target = EvaluationTarget.headless,
+    this.buildMode = EvaluationBuildMode.debug,
+    this.runs = 1,
+    this.jsonOutput,
     this.port = 0,
     this.openBrowser = true,
   });
@@ -44,6 +48,9 @@ final class PokeMapEvalOptions {
   final bool includeBag;
   final bool jsonOnly;
   final EvaluationTarget target;
+  final EvaluationBuildMode buildMode;
+  final int runs;
+  final String? jsonOutput;
   final int port;
   final bool openBrowser;
 }
@@ -55,7 +62,10 @@ final class PokeMapEvalCliResult {
 }
 
 abstract interface class PokeMapEvalWorker {
-  Future<EvaluationWorkerResult> run(EvaluationWorkerRequest request);
+  Future<EvaluationWorkerResult> run(
+    EvaluationWorkerRequest request, {
+    EvaluationBuildMode buildMode = EvaluationBuildMode.debug,
+  });
 }
 
 typedef PokeMapEvalOutputSink = void Function(String line);
@@ -204,12 +214,76 @@ final class PokeMapEvalCli {
         'Scenario id "$scenarioId" is duplicated.',
       );
     }
-    return _executeScenario(
-      discovered: matches.single,
-      policyOverride: options.policy,
-      jsonOnly: options.jsonOnly,
-      target: options.target,
+    final discovered = matches.single;
+    if (options.jsonOutput == null) {
+      return (await _executeScenario(
+        discovered: discovered,
+        policyOverride: options.policy,
+        jsonOnly: options.jsonOnly,
+        target: options.target,
+        buildMode: options.buildMode,
+      ))
+          .result;
+    }
+
+    final output = _validatedPerformanceOutput(options.jsonOutput!);
+    final batchId = _runIdFactory();
+    final executions = <_ScenarioExecution>[];
+    for (var index = 0; index < options.runs; index += 1) {
+      final execution = await _executeScenario(
+        discovered: discovered,
+        policyOverride: options.policy,
+        jsonOnly: false,
+        target: options.target,
+        buildMode: options.buildMode,
+        emitOutput: false,
+        runId: '$batchId-profile-${index + 1}',
+      );
+      executions.add(execution);
+      if (execution.result.exitCode != 0) {
+        stderrSink(
+          'Profile run ${index + 1}/${options.runs} failed; '
+          'no aggregate was produced. '
+          '${execution.message ?? 'No worker diagnostic was returned.'}',
+        );
+        return execution.result;
+      }
+    }
+    final runEvidence = <Map<String, Object?>>[];
+    final aggregateBuild = <int>[];
+    final aggregateRaster = <int>[];
+    final aggregateSpan = <int>[];
+    for (final execution in executions) {
+      final metrics = await _readFrameMetrics(execution);
+      aggregateBuild.addAll(metrics.buildMicroseconds);
+      aggregateRaster.addAll(metrics.rasterMicroseconds);
+      aggregateSpan.addAll(metrics.frameSpanMicroseconds);
+      runEvidence.add(<String, Object?>{
+        'runId': execution.runId,
+        'receiptPath': execution.receiptPath,
+        'frameMetrics': metrics.toJson(),
+      });
+    }
+    final receipt = await _runtimePerformanceReceipt(
+      discovered: discovered,
+      options: options,
+      runs: runEvidence,
+      aggregate: _FrameMetricSamples(
+        buildMicroseconds: aggregateBuild,
+        rasterMicroseconds: aggregateRaster,
+        frameSpanMicroseconds: aggregateSpan,
+      ),
     );
+    await _writeJsonAtomically(output, receipt);
+    if (options.jsonOnly) {
+      stdoutSink(jsonEncode(receipt));
+    } else {
+      stdoutSink(
+        'Profile evidence: ${_portableRelativePath(output)} '
+        '(${options.runs} isolated runs)',
+      );
+    }
+    return const PokeMapEvalCliResult(0);
   }
 
   Future<PokeMapEvalCliResult> _inspect(PokeMapEvalOptions options) async {
@@ -249,14 +323,15 @@ final class PokeMapEvalCli {
     final scenario = const EvaluationScenarioParser().parseString(
       await scenarioFile.readAsString(),
     );
-    return _executeWorker(
+    return (await _executeWorker(
       scenario: scenario,
       scenarioPath: _portableRelativePath(scenarioFile),
       outputDirectory: outputDirectory,
       runId: runId,
       jsonOnly: options.jsonOnly,
       target: EvaluationTarget.headless,
-    );
+    ))
+        .result;
   }
 
   Future<PokeMapEvalCliResult> _history(PokeMapEvalOptions options) async {
@@ -305,14 +380,17 @@ final class PokeMapEvalCli {
     return const PokeMapEvalCliResult(0);
   }
 
-  Future<PokeMapEvalCliResult> _executeScenario({
+  Future<_ScenarioExecution> _executeScenario({
     required _DiscoveredScenario discovered,
     required EvaluationPolicy? policyOverride,
     required bool jsonOnly,
     required EvaluationTarget target,
+    EvaluationBuildMode buildMode = EvaluationBuildMode.debug,
+    bool emitOutput = true,
+    String? runId,
   }) async {
-    final runId = _runIdFactory();
-    final outputDirectory = _outputDirectory(runId);
+    final effectiveRunId = runId ?? _runIdFactory();
+    final outputDirectory = _outputDirectory(effectiveRunId);
     var scenario = discovered.scenario;
     var scenarioFile = discovered.file;
     if (policyOverride != null && policyOverride != scenario.policy) {
@@ -339,19 +417,23 @@ final class PokeMapEvalCli {
       scenario: scenario,
       scenarioPath: _portableRelativePath(scenarioFile),
       outputDirectory: outputDirectory,
-      runId: runId,
+      runId: effectiveRunId,
       jsonOnly: jsonOnly,
       target: target,
+      buildMode: buildMode,
+      emitOutput: emitOutput,
     );
   }
 
-  Future<PokeMapEvalCliResult> _executeWorker({
+  Future<_ScenarioExecution> _executeWorker({
     required EvaluationScenario scenario,
     required String scenarioPath,
     required String outputDirectory,
     required String runId,
     required bool jsonOnly,
     required EvaluationTarget target,
+    EvaluationBuildMode buildMode = EvaluationBuildMode.debug,
+    bool emitOutput = true,
   }) async {
     stderrSink(
       'PokeMap Eval: ${scenario.id} '
@@ -368,6 +450,7 @@ final class PokeMapEvalCli {
         scenarioPath: scenarioPath,
         outputDirectory: outputDirectory,
       ),
+      buildMode: buildMode,
     );
     _ReceiptSummary? receipt;
     if (result.receiptPath != null) {
@@ -381,7 +464,13 @@ final class PokeMapEvalCli {
         );
       } on Object catch (failure) {
         stderrSink('Worker receipt is missing or invalid: $failure');
-        return const PokeMapEvalCliResult(3);
+        return _ScenarioExecution(
+          result: const PokeMapEvalCliResult(3),
+          runId: runId,
+          outputDirectory: outputDirectory,
+          receiptPath: result.receiptPath,
+          message: result.message,
+        );
       }
     }
 
@@ -399,12 +488,20 @@ final class PokeMapEvalCli {
           'receiptPath': result.receiptPath,
           'message': result.message,
         };
-    if (jsonOnly) {
-      stdoutSink(jsonEncode(summary));
-    } else {
-      _writeHumanSummary(summary);
+    if (emitOutput) {
+      if (jsonOnly) {
+        stdoutSink(jsonEncode(summary));
+      } else {
+        _writeHumanSummary(summary);
+      }
     }
-    return PokeMapEvalCliResult(result.exitCode);
+    return _ScenarioExecution(
+      result: PokeMapEvalCliResult(result.exitCode),
+      runId: runId,
+      outputDirectory: outputDirectory,
+      receiptPath: result.receiptPath,
+      message: result.message,
+    );
   }
 
   void _writeHumanSummary(Map<String, Object?> summary) {
@@ -466,6 +563,308 @@ final class PokeMapEvalCli {
   String _outputDirectory(String runId) {
     return 'build/pokemap-eval/runs/$runId';
   }
+
+  File _validatedPerformanceOutput(String relativePath) {
+    final packageRoot = Directory(p.join(
+      repositoryRoot.path,
+      'examples',
+      'playable_runtime_host',
+    )).absolute;
+    if (p.isAbsolute(relativePath)) {
+      throw const PokeMapEvalUsageException(
+        '--json-output must stay inside examples/playable_runtime_host.',
+      );
+    }
+    final output = File(
+      p.normalize(p.join(packageRoot.path, relativePath)),
+    ).absolute;
+    if (!p.isWithin(packageRoot.path, output.path)) {
+      throw const PokeMapEvalUsageException(
+        '--json-output must stay inside examples/playable_runtime_host.',
+      );
+    }
+    return output;
+  }
+
+  Future<_FrameMetricSamples> _readFrameMetrics(
+    _ScenarioExecution execution,
+  ) async {
+    final file = File(p.join(
+      repositoryRoot.path,
+      execution.outputDirectory,
+      'artifacts',
+      'frame-metrics.json',
+    ));
+    final decoded = jsonDecode(await file.readAsString());
+    if (decoded is! Map) {
+      throw const FormatException('Frame metrics root must be an object.');
+    }
+    return _FrameMetricSamples.fromJson(Map<String, Object?>.from(decoded));
+  }
+
+  Future<Map<String, Object?>> _runtimePerformanceReceipt({
+    required _DiscoveredScenario discovered,
+    required PokeMapEvalOptions options,
+    required List<Map<String, Object?>> runs,
+    required _FrameMetricSamples aggregate,
+  }) async {
+    final flutter = await _flutterMetadata();
+    final scenarioBytes = await discovered.file.readAsBytes();
+    final status = await _git(<String>['status', '--porcelain=v1']);
+    final diff = await _git(<String>['diff', '--binary', 'HEAD']);
+    final untracked = await _git(<String>[
+      'ls-files',
+      '--others',
+      '--exclude-standard',
+    ]);
+    return <String, Object?>{
+      'schemaVersion': 2,
+      'generatorVersion': 1,
+      'benchmark': 'runtime_interactive_journey',
+      'executionMode': 'flutter-${options.buildMode.name}',
+      'sdk': Platform.version,
+      'scenarioId': discovered.scenario.id,
+      'fixtureFingerprint': sha256.convert(scenarioBytes).toString(),
+      'commit': await _git(<String>['rev-parse', 'HEAD']),
+      'treeState': status.isEmpty ? 'clean' : 'dirty',
+      'treeFingerprint': await _sourceTreeFingerprint(
+        status: status,
+        diff: diff,
+        untracked: untracked,
+      ),
+      'os': Platform.operatingSystem,
+      'osVersion': Platform.operatingSystemVersion,
+      'architecture': _architectureLabel(),
+      'toolchain': <String, Object?>{
+        'dart': Platform.version,
+        'flutter': flutter,
+        'flame': await _flameVersion(),
+      },
+      'warmups': 0,
+      'sampleCount': options.runs,
+      'runCount': options.runs,
+      'command': <String>[
+        'dart',
+        'run',
+        'tool/pokemap_eval.dart',
+        'run',
+        discovered.scenario.id,
+        '--target',
+        options.target.name,
+        '--build-mode',
+        options.buildMode.name,
+        '--runs',
+        '${options.runs}',
+        '--json-output',
+        options.jsonOutput!,
+      ],
+      'memory': <String, Object?>{
+        'rssBytes': ProcessInfo.currentRss,
+        'heapBytes': null,
+        'heapAvailability': 'not exposed by dart:io',
+      },
+      'comparisonPolicy': <String, Object?>{
+        'comparableModes': <String>['flutter-profile'],
+        'debugAsProxy': false,
+        'combineBuildAndRaster': false,
+      },
+      'thresholdPolicy': <String, Object?>{
+        'observationOnly': true,
+        'minimumHistoricalObservations': 10,
+        'requiredConsecutiveRegressions': 2,
+      },
+      'runs': runs,
+      'results': runs,
+      'aggregateFrameMetrics': aggregate.toJson(),
+    };
+  }
+
+  Future<String> _git(List<String> arguments) async {
+    final result = await Process.run(
+      'git',
+      arguments,
+      workingDirectory: repositoryRoot.path,
+    );
+    return result.exitCode == 0 ? '${result.stdout}'.trim() : 'unavailable';
+  }
+
+  // Include untracked contents because RM-00 receipts are captured before a
+  // commit; hashing names alone would miss edits to the collector itself.
+  Future<String> _sourceTreeFingerprint({
+    required String status,
+    required String diff,
+    required String untracked,
+  }) async {
+    final entries = <Map<String, Object?>>[];
+    final paths = untracked
+        .split('\n')
+        .where((path) => path.trim().isNotEmpty)
+        .toList(growable: false)
+      ..sort();
+    for (final relativePath in paths) {
+      final file = File(p.join(repositoryRoot.path, relativePath));
+      try {
+        final bytes = await file.readAsBytes();
+        entries.add(<String, Object?>{
+          'path': relativePath,
+          'bytes': bytes.length,
+          'content': sha256.convert(bytes).toString(),
+        });
+      } on FileSystemException {
+        entries.add(<String, Object?>{
+          'path': relativePath,
+          'content': 'unavailable',
+        });
+      }
+    }
+    return sha256
+        .convert(
+          utf8.encode(
+            jsonEncode(<String, Object?>{
+              'status': status,
+              'diff': diff,
+              'untracked': entries,
+            }),
+          ),
+        )
+        .toString();
+  }
+
+  Future<Map<String, Object?>> _flutterMetadata() async {
+    final result = await Process.run(
+      'flutter',
+      <String>['--version', '--machine'],
+    );
+    if (result.exitCode != 0) {
+      return const <String, Object?>{'status': 'unavailable'};
+    }
+    final decoded = jsonDecode('${result.stdout}');
+    return decoded is Map
+        ? Map<String, Object?>.from(decoded)
+        : const <String, Object?>{'status': 'malformed'};
+  }
+
+  Future<String> _flameVersion() async {
+    final lock = File(p.join(
+      repositoryRoot.path,
+      'examples',
+      'playable_runtime_host',
+      'pubspec.lock',
+    ));
+    if (!await lock.exists()) return 'unavailable';
+    final lines = await lock.readAsLines();
+    final start = lines.indexWhere((line) => line == '  flame:');
+    if (start < 0) return 'unavailable';
+    for (final line in lines.skip(start + 1)) {
+      if (!line.startsWith('    ')) break;
+      final trimmed = line.trim();
+      if (trimmed.startsWith('version: ')) {
+        return trimmed.substring('version: '.length).replaceAll('"', '');
+      }
+    }
+    return 'unavailable';
+  }
+}
+
+final class _ScenarioExecution {
+  const _ScenarioExecution({
+    required this.result,
+    required this.runId,
+    required this.outputDirectory,
+    required this.receiptPath,
+    required this.message,
+  });
+
+  final PokeMapEvalCliResult result;
+  final String runId;
+  final String outputDirectory;
+  final String? receiptPath;
+  final String? message;
+}
+
+final class _FrameMetricSamples {
+  _FrameMetricSamples({
+    required List<int> buildMicroseconds,
+    required List<int> rasterMicroseconds,
+    required List<int> frameSpanMicroseconds,
+  })  : buildMicroseconds = List<int>.unmodifiable(buildMicroseconds),
+        rasterMicroseconds = List<int>.unmodifiable(rasterMicroseconds),
+        frameSpanMicroseconds = List<int>.unmodifiable(frameSpanMicroseconds) {
+    if (this.buildMicroseconds.length != this.rasterMicroseconds.length ||
+        this.buildMicroseconds.length != this.frameSpanMicroseconds.length ||
+        <List<int>>[
+          this.buildMicroseconds,
+          this.rasterMicroseconds,
+          this.frameSpanMicroseconds,
+        ].any((samples) => samples.any((sample) => sample < 0))) {
+      throw const FormatException('Frame metric samples are inconsistent.');
+    }
+  }
+
+  factory _FrameMetricSamples.fromJson(Map<String, Object?> json) {
+    if (json['schemaVersion'] != 2) {
+      throw const FormatException('Unsupported frame metrics schema.');
+    }
+    final frameCount = json['frameCount'];
+    if (frameCount is! int || frameCount < 0) {
+      throw const FormatException('Invalid frame metric frameCount.');
+    }
+    final samples = _FrameMetricSamples(
+      buildMicroseconds: _sampleList(
+        json['buildSamplesMicroseconds'],
+        'buildSamplesMicroseconds',
+      ),
+      rasterMicroseconds: _sampleList(
+        json['rasterSamplesMicroseconds'],
+        'rasterSamplesMicroseconds',
+      ),
+      frameSpanMicroseconds: _sampleList(
+        json['frameSpanSamplesMicroseconds'],
+        'frameSpanSamplesMicroseconds',
+      ),
+    );
+    if (samples.buildMicroseconds.length != frameCount) {
+      throw const FormatException('frameCount does not match frame samples.');
+    }
+    return samples;
+  }
+
+  final List<int> buildMicroseconds;
+  final List<int> rasterMicroseconds;
+  final List<int> frameSpanMicroseconds;
+
+  Map<String, Object?> toJson() {
+    final build = List<int>.of(buildMicroseconds)..sort();
+    final raster = List<int>.of(rasterMicroseconds)..sort();
+    final spans = List<int>.of(frameSpanMicroseconds)..sort();
+    final count = build.length;
+    final over16 = spans.where((sample) => sample > 16670).length;
+    final over33 = spans.where((sample) => sample > 33300).length;
+    return <String, Object?>{
+      'schemaVersion': 2,
+      'frameCount': count,
+      'averageBuildMilliseconds': _averageMilliseconds(build),
+      'averageRasterMilliseconds': _averageMilliseconds(raster),
+      'maxBuildMilliseconds': _maxMilliseconds(build),
+      'maxRasterMilliseconds': _maxMilliseconds(raster),
+      'buildP50Milliseconds': _percentileMilliseconds(build, 0.50),
+      'buildP95Milliseconds': _percentileMilliseconds(build, 0.95),
+      'buildP99Milliseconds': _percentileMilliseconds(build, 0.99),
+      'rasterP50Milliseconds': _percentileMilliseconds(raster, 0.50),
+      'rasterP95Milliseconds': _percentileMilliseconds(raster, 0.95),
+      'rasterP99Milliseconds': _percentileMilliseconds(raster, 0.99),
+      'frameSpanP50Milliseconds': _percentileMilliseconds(spans, 0.50),
+      'frameSpanP95Milliseconds': _percentileMilliseconds(spans, 0.95),
+      'frameSpanP99Milliseconds': _percentileMilliseconds(spans, 0.99),
+      'framesOver16Point67Milliseconds': over16,
+      'framesOver16Point67Rate': count == 0 ? 0 : over16 / count,
+      'framesOver33Point3Milliseconds': over33,
+      'framesOver33Point3Rate': count == 0 ? 0 : over33 / count,
+      'buildSamplesMicroseconds': buildMicroseconds,
+      'rasterSamplesMicroseconds': rasterMicroseconds,
+      'frameSpanSamplesMicroseconds': frameSpanMicroseconds,
+    };
+  }
 }
 
 final class PokeMapEvalUsageException implements Exception {
@@ -483,7 +882,10 @@ final class _HeadlessProcessWorker implements PokeMapEvalWorker {
   final HeadlessWorkerProcess process;
 
   @override
-  Future<EvaluationWorkerResult> run(EvaluationWorkerRequest request) {
+  Future<EvaluationWorkerResult> run(
+    EvaluationWorkerRequest request, {
+    EvaluationBuildMode buildMode = EvaluationBuildMode.debug,
+  }) {
     return process.run(request);
   }
 }
@@ -494,8 +896,11 @@ final class _InteractiveProcessWorker implements PokeMapEvalWorker {
   final InteractiveWorkerClient client;
 
   @override
-  Future<EvaluationWorkerResult> run(EvaluationWorkerRequest request) {
-    return client.run(request);
+  Future<EvaluationWorkerResult> run(
+    EvaluationWorkerRequest request, {
+    EvaluationBuildMode buildMode = EvaluationBuildMode.debug,
+  }) {
+    return client.run(request, buildMode: buildMode);
   }
 }
 
@@ -634,6 +1039,9 @@ PokeMapEvalOptions _parseRun(List<String> arguments) {
   final scenarioId = arguments.first;
   EvaluationPolicy? policy;
   var target = EvaluationTarget.headless;
+  var buildMode = EvaluationBuildMode.debug;
+  var runs = 1;
+  String? jsonOutput;
   var jsonOnly = false;
   var index = 1;
   while (index < arguments.length) {
@@ -661,18 +1069,55 @@ PokeMapEvalOptions _parseRun(List<String> arguments) {
             ),
         };
         index += 2;
+      case '--build-mode':
+        final value = _optionValue(arguments, index, '--build-mode');
+        buildMode = switch (value) {
+          'debug' => EvaluationBuildMode.debug,
+          'profile' => EvaluationBuildMode.profile,
+          _ => throw PokeMapEvalUsageException(
+              'Unknown build mode "$value".',
+            ),
+        };
+        index += 2;
+      case '--runs':
+        final value = _optionValue(arguments, index, '--runs');
+        runs = int.tryParse(value) ?? 0;
+        if (runs <= 0) {
+          throw const PokeMapEvalUsageException(
+            '--runs must be a positive integer.',
+          );
+        }
+        index += 2;
+      case '--json-output':
+        jsonOutput = _optionValue(arguments, index, '--json-output');
+        index += 2;
       default:
         throw PokeMapEvalUsageException(
           'Unknown option "${arguments[index]}".',
         );
     }
   }
+  final performanceRequested = buildMode == EvaluationBuildMode.profile ||
+      runs != 1 ||
+      jsonOutput != null;
+  if (performanceRequested &&
+      (target != EvaluationTarget.interactive ||
+          buildMode != EvaluationBuildMode.profile ||
+          jsonOutput == null)) {
+    throw const PokeMapEvalUsageException(
+      'Performance collection requires --target interactive, '
+      '--build-mode profile, and --json-output.',
+    );
+  }
   return PokeMapEvalOptions(
     command: PokeMapEvalCommand.run,
     scenarioId: scenarioId,
     policy: policy,
     jsonOnly: jsonOnly,
     target: target,
+    buildMode: buildMode,
+    runs: runs,
+    jsonOutput: jsonOutput,
   );
 }
 
@@ -786,6 +1231,38 @@ String _optionValue(List<String> arguments, int index, String option) {
   return arguments[index + 1];
 }
 
+List<int> _sampleList(Object? value, String field) {
+  if (value is! List || value.any((sample) => sample is! int)) {
+    throw FormatException('$field must contain integer microseconds.');
+  }
+  return List<int>.unmodifiable(value.cast<int>());
+}
+
+double _averageMilliseconds(List<int> samples) => samples.isEmpty
+    ? 0
+    : samples.reduce((left, right) => left + right) / samples.length / 1000;
+
+double _maxMilliseconds(List<int> samples) => samples.isEmpty
+    ? 0
+    : samples.reduce((left, right) => left > right ? left : right) / 1000;
+
+double _percentileMilliseconds(List<int> sortedSamples, double percentile) {
+  if (sortedSamples.isEmpty) return 0;
+  final index = (percentile * sortedSamples.length).ceil() - 1;
+  return sortedSamples[index.clamp(0, sortedSamples.length - 1)] / 1000;
+}
+
+String _architectureLabel() {
+  final executable = Platform.resolvedExecutable.toLowerCase();
+  if (executable.contains('arm64') || executable.contains('aarch64')) {
+    return 'arm64';
+  }
+  if (executable.contains('x64') || executable.contains('x86_64')) {
+    return 'x64';
+  }
+  return Platform.version.contains('arm64') ? 'arm64' : 'unknown';
+}
+
 Future<void> _writeJsonAtomically(
   File destination,
   Map<String, Object?> json,
@@ -821,6 +1298,8 @@ Usage:
   pokemap eval list [--project <id>]
   pokemap eval run <scenario-id> [--policy probe|certify]
     [--target headless|interactive] [--json]
+    [--build-mode debug|profile] [--runs <positive-int>]
+    [--json-output <package-relative-path>]
   pokemap eval inspect --checkpoint <id> [--facts] [--party] [--bag]
   pokemap eval history [--json]
   pokemap eval web [--project <id>] [--port <0..65535>] [--no-open]''';
diff --git a/packages/map_editor/pubspec.lock b/packages/map_editor/pubspec.lock
index eb9dc7a37..d5010338e 100644
--- a/packages/map_editor/pubspec.lock
+++ b/packages/map_editor/pubspec.lock
@@ -350,6 +350,11 @@ packages:
     description: flutter
     source: sdk
     version: "0.0.0"
+  flutter_driver:
+    dependency: "direct dev"
+    description: flutter
+    source: sdk
+    version: "0.0.0"
   flutter_lints:
     dependency: "direct dev"
     description:
@@ -413,6 +418,11 @@ packages:
       url: "https://pub.dev"
     source: hosted
     version: "4.0.0"
+  fuchsia_remote_debug_protocol:
+    dependency: transitive
+    description: flutter
+    source: sdk
+    version: "0.0.0"
   glob:
     dependency: transitive
     description:
@@ -477,6 +487,11 @@ packages:
       url: "https://pub.dev"
     source: hosted
     version: "4.9.1"
+  integration_test:
+    dependency: "direct dev"
+    description: flutter
+    source: sdk
+    version: "0.0.0"
   intl:
     dependency: "direct main"
     description:
@@ -777,6 +792,14 @@ packages:
       url: "https://pub.dev"
     source: hosted
     version: "6.5.0"
+  process:
+    dependency: transitive
+    description:
+      name: process
+      sha256: c6248e4526673988586e8c00bb22a49210c258dc91df5227d5da9748ecf79744
+      url: "https://pub.dev"
+    source: hosted
+    version: "5.0.5"
   pub_semver:
     dependency: "direct main"
     description:
@@ -918,6 +941,14 @@ packages:
       url: "https://pub.dev"
     source: hosted
     version: "1.4.1"
+  sync_http:
+    dependency: transitive
+    description:
+      name: sync_http
+      sha256: "7f0cd72eca000d2e026bcd6f990b81d0ca06022ef4e32fb257b30d3d1014a961"
+      url: "https://pub.dev"
+    source: hosted
+    version: "0.3.1"
   synchronized:
     dependency: transitive
     description:
@@ -1062,6 +1093,14 @@ packages:
       url: "https://pub.dev"
     source: hosted
     version: "3.0.3"
+  webdriver:
+    dependency: transitive
+    description:
+      name: webdriver
+      sha256: "2f3a14ca026957870cfd9c635b83507e0e51d8091568e90129fbf805aba7cade"
+      url: "https://pub.dev"
+    source: hosted
+    version: "3.1.0"
   win32:
     dependency: transitive
     description:
diff --git a/packages/map_editor/pubspec.yaml b/packages/map_editor/pubspec.yaml
index 10a1c2941..e1b4f6bd7 100644
--- a/packages/map_editor/pubspec.yaml
+++ b/packages/map_editor/pubspec.yaml
@@ -39,6 +39,10 @@ dependencies:
 dev_dependencies:
   flutter_test:
     sdk: flutter
+  flutter_driver:
+    sdk: flutter
+  integration_test:
+    sdk: flutter
   flutter_lints: ^3.0.1
   build_runner: ^2.4.8
   freezed: ^2.4.7
~~~~

