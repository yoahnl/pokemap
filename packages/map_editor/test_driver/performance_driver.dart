import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:integration_test/integration_test_driver.dart';
import 'package:path/path.dart' as p;

import 'support/fine_mask_performance_contract.dart';

Future<void> main() async {
  await integrationDriver(
    responseDataCallback: (data) async {
      if (data == null) {
        throw const FormatException('Editor performance response is missing.');
      }
      _validatePerformanceData(data, requireProvenance: false);
      final target = data['target']! as String;
      final requestedOutput = data['requestedOutputPath'];
      if (requestedOutput is! String || requestedOutput.trim().isEmpty) {
        throw const FormatException('POKEMAP_PERF_OUTPUT is required.');
      }
      final output = _validatedOutput(requestedOutput);
      final repositoryRoot = await _git(<String>[
        'rev-parse',
        '--show-toplevel',
      ]);
      final status = await _git(<String>[
        'status',
        '--porcelain=v1',
      ], workingDirectory: repositoryRoot);
      final diff = await _git(<String>[
        'diff',
        '--binary',
        'HEAD',
      ], workingDirectory: repositoryRoot);
      final untracked = await _git(<String>[
        'ls-files',
        '--others',
        '--exclude-standard',
      ], workingDirectory: repositoryRoot);
      final receipt = <String, Object?>{
        ...data,
        'commit': await _git(<String>[
          'rev-parse',
          'HEAD',
        ], workingDirectory: repositoryRoot),
        'treeState': status.isEmpty ? 'clean' : 'dirty',
        'sdk': Platform.version,
        'treeFingerprint': await _sourceTreeFingerprint(
          repositoryRoot: repositoryRoot,
          status: status,
          diff: diff,
          untracked: untracked,
        ),
        'os': Platform.operatingSystem,
        'osVersion': Platform.operatingSystemVersion,
        'architecture': _architectureLabel(),
        'toolchain': <String, Object?>{
          'dart': Platform.version,
          'flutter': await _flutterMetadata(),
          'flame': await _flameVersion(),
        },
        'command': <String>[
          'flutter',
          'drive',
          '--profile',
          '-d',
          'macos',
          '--driver=test_driver/performance_driver.dart',
          '--target=$target',
          '--dart-define=POKEMAP_PERF_OUTPUT=$requestedOutput',
        ],
      };
      validatePerformanceResponse(receipt);
      await output.parent.create(recursive: true);
      final temporary = File('${output.path}.tmp-$pid');
      await temporary.writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(receipt)}\n',
        flush: true,
      );
      if (await output.exists()) await output.delete();
      await temporary.rename(output.path);
      stdout.writeln(jsonEncode(receipt));
    },
  );
}

void validatePerformanceResponse(Map<String, dynamic> data) {
  _validatePerformanceData(data, requireProvenance: true);
}

void _validatePerformanceData(
  Map<String, dynamic> data, {
  required bool requireProvenance,
}) {
  if (data['schemaVersion'] != 2) {
    throw const FormatException(
      'Editor performance response must use schema V2.',
    );
  }
  final target = data['target'];
  if (target is! String ||
      !RegExp(r'^integration_test/[a-z0-9_]+_test\.dart$').hasMatch(target)) {
    throw const FormatException(
      'Editor performance response must declare its integration target.',
    );
  }
  if (target == 'integration_test/editor_project_journey_test.dart') {
    if (requireProvenance) _validateProvenance(data);
    _validateInstrumentation(data);
  } else if (target ==
      'integration_test/editor_canvas_projection_journey_test.dart') {
    if (requireProvenance) _validateProvenance(data);
    _validateCanvasProjection(data);
  } else if (target == 'integration_test/editor_fine_mask_journey_test.dart') {
    validateFineMaskPerformanceReceipt(
      data,
      requireProvenance: requireProvenance,
    );
  }
}

void _validateCanvasProjection(Map<String, dynamic> data) {
  final measurementScope = data['measurementScope'];
  if (measurementScope is! Map ||
      measurementScope['metric'] != 'canvas.paint_recording' ||
      measurementScope['includesGpuRaster'] != false ||
      measurementScope['includesLayoutAndComposition'] != false) {
    throw const FormatException(
      'Canvas projection must identify UI-thread picture recording separately from full Flutter frames.',
    );
  }
  final results = data['results'];
  const extents = <int>{128, 256, 512, 1024};
  const modes = <String>{'standard', 'smart', 'shadows', 'combined'};
  if (results is! List || results.length != extents.length * modes.length) {
    throw const FormatException(
      'Canvas projection response must cover every mode and extent.',
    );
  }
  final matrix = <String>{
    for (final row in results.whereType<Map>())
      '${row['mode']}:${row['extent']}',
  };
  final expected = <String>{
    for (final mode in modes)
      for (final extent in extents) '$mode:$extent',
  };
  if (matrix.length != expected.length || !matrix.containsAll(expected)) {
    throw const FormatException(
      'Canvas projection response has an incomplete mode and extent matrix.',
    );
  }
  final sampleCount = data['sampleCountPerModeAndExtent'];
  if (sampleCount is! int || sampleCount < 30) {
    throw const FormatException(
      'Canvas projection response must declare at least 30 samples per row.',
    );
  }
  for (final row in results.whereType<Map>()) {
    _validateSampleRow(row, expectedSampleCount: sampleCount);
  }
  final placements = data['placementResults'];
  final placementCounts = placements is List
      ? placements
            .whereType<Map>()
            .map((row) => row['placedElementCount'])
            .toSet()
      : const <Object?>{};
  if (placementCounts.length != 3 ||
      !placementCounts.containsAll(const <int>{100, 1000, 10000})) {
    throw const FormatException(
      'Canvas projection response must cover 100, 1000 and 10000 elements.',
    );
  }
  for (final row in placements.whereType<Map>()) {
    _validateSampleRow(row, expectedSampleCount: sampleCount);
  }
  final cachedRepaints = data['cachedRepaintResults'];
  if (cachedRepaints is! List || cachedRepaints.length != extents.length) {
    throw const FormatException(
      'Canvas projection response must cover cached repaint at every extent.',
    );
  }
  final cachedExtentMatrix = <Object?>{
    for (final row in cachedRepaints.whereType<Map>()) row['extent'],
  };
  if (cachedExtentMatrix.length != extents.length ||
      !cachedExtentMatrix.containsAll(extents)) {
    throw const FormatException(
      'Canvas cached repaint response has an incomplete extent matrix.',
    );
  }
  for (final row in cachedRepaints.whereType<Map>()) {
    _validateSampleRow(row, expectedSampleCount: sampleCount);
    final hits = row['staticCacheHitsDuringSamples'];
    final misses = row['staticCacheMissesDuringSamples'];
    final entryCount = row['cacheEntryCount'];
    final dirtyRegion = row['dirtyRegion'];
    final dirtyLeft = dirtyRegion is Map ? dirtyRegion['leftCell'] : null;
    final dirtyTop = dirtyRegion is Map ? dirtyRegion['topCell'] : null;
    final dirtyRight = dirtyRegion is Map ? dirtyRegion['rightCell'] : null;
    final dirtyBottom = dirtyRegion is Map ? dirtyRegion['bottomCell'] : null;
    final dirtyCellCount = dirtyRegion is Map ? dirtyRegion['cellCount'] : null;
    if (row['mode'] != 'animationTick' ||
        hits is! int ||
        hits <= 0 ||
        misses != 0 ||
        entryCount is! int ||
        entryCount <= 0 ||
        entryCount > 64 ||
        dirtyRegion is! Map ||
        dirtyRegion['policy'] != 'visibleViewport' ||
        dirtyLeft is! int ||
        dirtyTop is! int ||
        dirtyRight is! int ||
        dirtyBottom is! int ||
        dirtyRight <= dirtyLeft ||
        dirtyBottom <= dirtyTop ||
        dirtyCellCount is! int ||
        dirtyCellCount != (dirtyRight - dirtyLeft) * (dirtyBottom - dirtyTop) ||
        dirtyCellCount > (row['extent'] as int) * (row['extent'] as int)) {
      throw const FormatException(
        'Canvas cached repaint must reuse warmed static pictures within its bounded dirty region.',
      );
    }
  }
  _validateMemory(data);
  final gates = data['performanceGates'];
  if (gates is! Map) {
    throw const FormatException(
      'Canvas projection response must declare repaint budgets.',
    );
  }
  final standard1024 = _canvasRow(results, mode: 'standard', extent: 1024);
  final combined128 = _canvasRow(results, mode: 'combined', extent: 128);
  final combined1024 = _canvasRow(results, mode: 'combined', extent: 1024);
  final cachedRepaint1024 = _canvasRow(
    cachedRepaints,
    mode: 'animationTick',
    extent: 1024,
  );
  final standardP95 = standard1024['p95Us']! as int;
  final combined128P95 = combined128['p95Us']! as int;
  final combined1024P95 = combined1024['p95Us']! as int;
  final cachedRepaint1024P95 = cachedRepaint1024['p95Us']! as int;
  final combinedBudget = gates['combined1024P95BudgetUs'];
  final repaintBudget = gates['repaintP95BudgetUs'];
  final scaleBudget = gates['combined1024To128P95RatioBudget'];
  final standardBudget = gates['standard1024P95ObservationCeilingUs'];
  final cachedRepaintBudget = gates['cachedRepaint1024P95BudgetUs'];
  final scaleRatio =
      combined1024P95 / (combined128P95 == 0 ? 1 : combined128P95);
  if (combinedBudget is! int ||
      repaintBudget is! int ||
      scaleBudget is! num ||
      standardBudget is! int ||
      cachedRepaintBudget is! int ||
      combined1024P95 >= combinedBudget ||
      combined1024P95 >= repaintBudget ||
      scaleRatio >= scaleBudget ||
      standardP95 >= standardBudget ||
      cachedRepaint1024P95 >= cachedRepaintBudget ||
      gates['combined1024P95Pass'] != (combined1024P95 < combinedBudget) ||
      gates['repaintP95Pass'] != (combined1024P95 < repaintBudget) ||
      gates['combinedScaleRatioPass'] != (scaleRatio < scaleBudget) ||
      gates['standardControlPass'] != (standardP95 < standardBudget)) {
    throw const FormatException(
      'Canvas projection response must pass every repaint gate.',
    );
  }
  if (gates['cachedRepaint1024P95Pass'] !=
      (cachedRepaint1024P95 < cachedRepaintBudget)) {
    throw const FormatException(
      'Canvas projection response must pass every repaint gate.',
    );
  }
}

Map _canvasRow(
  List<Object?> rows, {
  required String mode,
  required int extent,
}) {
  return rows.whereType<Map>().firstWhere(
    (row) => row['mode'] == mode && row['extent'] == extent,
  );
}

void _validateSampleRow(Map row, {required int expectedSampleCount}) {
  final samples = row['samplesUs'];
  if (samples is! List ||
      samples.length != expectedSampleCount ||
      samples.any((sample) => sample is! int || sample < 0)) {
    throw const FormatException(
      'Performance rows must contain the declared non-negative raw samples.',
    );
  }
  final sorted = samples.cast<int>().toList(growable: false)..sort();
  if (row['p50Us'] != _percentile(sorted, 0.50) ||
      row['p95Us'] != _percentile(sorted, 0.95) ||
      row['p99Us'] != _percentile(sorted, 0.99) ||
      row['maxUs'] != sorted.last) {
    throw const FormatException(
      'Performance row percentiles must match its raw samples.',
    );
  }
}

int _percentile(List<int> sorted, double percentile) {
  final index = (percentile * sorted.length).ceil() - 1;
  return sorted[index.clamp(0, sorted.length - 1)];
}

void _validateProvenance(Map<String, dynamic> data) {
  final commit = data['commit'];
  final sdk = data['sdk'];
  final architecture = data['architecture'];
  final toolchain = data['toolchain'];
  final flutter = toolchain is Map ? toolchain['flutter'] : null;
  final dart = toolchain is Map ? toolchain['dart'] : null;
  final flame = toolchain is Map ? toolchain['flame'] : null;
  if (data['executionMode'] != 'flutter-profile' ||
      data['treeState'] != 'clean' ||
      commit is! String ||
      !RegExp(r'^[0-9a-f]{40}$').hasMatch(commit) ||
      sdk is! String ||
      !_isAvailableText(sdk) ||
      architecture is! String ||
      !const <String>{'arm64', 'x64'}.contains(architecture) ||
      toolchain is! Map ||
      dart is! String ||
      !_isAvailableText(dart) ||
      flutter is! Map ||
      flutter['frameworkRevision'] is! String ||
      !_isAvailableText(flutter['frameworkRevision']! as String) ||
      flame is! String ||
      !_isAvailableText(flame)) {
    throw const FormatException(
      'Performance receipt must come from a clean profile run with complete provenance.',
    );
  }
}

bool _isAvailableText(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized.isNotEmpty &&
      normalized != 'unavailable' &&
      normalized != 'unknown' &&
      normalized != 'malformed';
}

void _validateInstrumentation(Map<String, dynamic> data) {
  final measurementScope = data['measurementScope'];
  if (measurementScope is! Map ||
      measurementScope['pointerLatencyMetric'] != 'pointer.to_state_publish' ||
      measurementScope['canvasPaintMetric'] != 'canvas.paint_recording' ||
      measurementScope['frameMetric'] != 'flutter.frame_total' ||
      measurementScope['framePolicy'] != 'observation') {
    throw const FormatException(
      'Editor project journey must declare distinct pointer, paint-recording and Flutter-frame scopes.',
    );
  }
  final instrumentation = data['instrumentation'];
  if (instrumentation is! Map || instrumentation['schemaVersion'] != 1) {
    throw const FormatException(
      'Editor performance response must include instrumentation V1.',
    );
  }
  final spans = instrumentation['spans'];
  const spanNames = <String>{
    'pointer.pre_dispatch',
    'pointer.to_state_publish',
    'mutation.local',
    'state.publish',
    'canvas.prepare',
    'canvas.future_builder_body',
    'canvas.paint_recording',
    'mask.readback',
    'mask.pointer_move',
    'mask.commit',
    'mask.build',
    'mask.paint',
    'map.validation.incremental',
    'map.validation.full',
    'snapshot',
    'plan',
    'apply',
    'save.queue',
    'save.encode',
  };
  if (spans is! Map ||
      spans.keys.toSet().difference(spanNames).isNotEmpty ||
      spanNames.difference(spans.keys.toSet()).isNotEmpty) {
    throw const FormatException(
      'Editor performance response has an invalid span catalog.',
    );
  }
  final counters = instrumentation['counters'];
  const counterNames = <String>{
    'filesystem.read',
    'filesystem.write',
    'filesystem.metadata',
    'json.encode',
    'json.decode',
    'base64.encode',
    'base64.decode',
  };
  if (counters is! Map ||
      counters.keys.toSet().difference(counterNames).isNotEmpty ||
      counterNames.difference(counters.keys.toSet()).isNotEmpty ||
      counters.values.any((value) => value is! int || value < 0)) {
    throw const FormatException(
      'Editor performance response has an invalid counter catalog.',
    );
  }
  if (instrumentation['droppedSampleCount'] != 0) {
    throw const FormatException(
      'Editor performance instrumentation dropped samples.',
    );
  }
  if (instrumentation['coverage'] !=
      'instrumented editor and authoring application boundaries only') {
    throw const FormatException(
      'Editor performance counters must declare their exact instrumented-boundary scope.',
    );
  }
  final results = data['results'];
  if (results is! List) {
    throw const FormatException(
      'Editor performance response must include measured phases.',
    );
  }
  _validateHotPathPhase(
    results,
    phaseName: 'tile-placement-90',
    requiredSpan: 'mutation.local',
    expectedSpanCount: 90,
  );
  _validateHotPathPhase(
    results,
    phaseName: 'pointer-collision-drag',
    requiredSpan: 'pointer.pre_dispatch',
    expectedSpanCount: 90,
  );
  _validateHotPathPhase(
    results,
    phaseName: 'pointer-collision-drag',
    requiredSpan: 'pointer.to_state_publish',
    expectedSpanCount: 90,
    p95BudgetUs: 8000,
  );
  for (final extent in const <int>[128, 256, 512, 1024]) {
    for (final strokeCount in const <int>[1, 10, 100, 1000]) {
      _validateHotPathPhase(
        results,
        phaseName: 'collision-paint-${extent}x$extent-$strokeCount',
        requiredSpan: 'mutation.local',
        expectedSpanCount: strokeCount,
      );
    }
  }
  _validateCanonicalPlacementPhase(results);
  _validateMaskMatrix(results);
  _validatePlacementPhase(results);
  _validateMemory(data);
  _validateFrameMetrics(data);
}

void _validateHotPathPhase(
  List<Object?> results, {
  required String phaseName,
  required String requiredSpan,
  required int expectedSpanCount,
  int? p95BudgetUs,
}) {
  final phase = _singlePhase(results, phaseName);
  final instrumentation = phase['instrumentation'];
  final spans = instrumentation is Map ? instrumentation['spans'] : null;
  final metrics = spans is Map ? spans[requiredSpan] : null;
  if (metrics is! Map || metrics['count'] != expectedSpanCount) {
    throw FormatException(
      '$phaseName must record exactly $expectedSpanCount $requiredSpan span(s).',
    );
  }
  _validateSampleRow(metrics, expectedSampleCount: expectedSpanCount);
  if (p95BudgetUs != null &&
      (metrics['p95Us'] is! int || (metrics['p95Us']! as int) >= p95BudgetUs)) {
    throw FormatException(
      '$phaseName must keep $requiredSpan P95 below $p95BudgetUs us.',
    );
  }
  final counters = instrumentation is Map ? instrumentation['counters'] : null;
  const counterNames = <String>{
    'filesystem.read',
    'filesystem.write',
    'filesystem.metadata',
    'json.encode',
    'json.decode',
    'base64.encode',
    'base64.decode',
  };
  if (counters is! Map ||
      counterNames.difference(counters.keys.toSet()).isNotEmpty ||
      counterNames.any((name) => counters[name] != 0)) {
    throw FormatException(
      '$phaseName must perform zero filesystem, JSON and base64 work.',
    );
  }
}

void _validatePlacementPhase(List<Object?> results) {
  final phase = _singlePhase(results, 'tile-placement-90');
  final p95Us = phase['p95Us'];
  _validateSampleRow(phase, expectedSampleCount: 90);
  if (p95Us is! int || p95Us >= 16000) {
    throw const FormatException(
      'tile-placement-90 must keep P95 below 16000 us.',
    );
  }
}

void _validateCanonicalPlacementPhase(List<Object?> results) {
  final phase = _singlePhase(results, 'canonical-element-placement');
  final instrumentation = phase['instrumentation'];
  final spans = instrumentation is Map ? instrumentation['spans'] : null;
  for (final name in const <String>['snapshot', 'plan', 'apply']) {
    final metrics = spans is Map ? spans[name] : null;
    if (metrics is! Map || metrics['count'] is! int || metrics['count'] == 0) {
      throw FormatException(
        'canonical-element-placement must record at least one $name span.',
      );
    }
    _validateSampleRow(metrics, expectedSampleCount: metrics['count']! as int);
  }
}

void _validateMaskMatrix(List<Object?> results) {
  for (final extent in const <int>[64, 256, 512, 1024]) {
    final phaseName = 'mask-roundtrip-${extent}x$extent';
    final phase = _singlePhase(results, phaseName);
    final instrumentation = phase['instrumentation'];
    final counters = instrumentation is Map
        ? instrumentation['counters']
        : null;
    if (counters is! Map ||
        counters['base64.encode'] != 10 ||
        counters['base64.decode'] != 10) {
      throw FormatException(
        '$phaseName must record 10 base64 encodes and decodes.',
      );
    }
    _validateSampleRow(phase, expectedSampleCount: 10);
  }
}

Map _singlePhase(List<Object?> results, String phaseName) {
  final matches = results
      .whereType<Map>()
      .where((candidate) => candidate['phase'] == phaseName)
      .toList(growable: false);
  if (matches.length != 1) {
    throw FormatException(
      'Editor performance response must contain exactly one $phaseName phase.',
    );
  }
  return matches.single;
}

void _validateMemory(Map<String, dynamic> data) {
  final memory = data['memory'];
  if (memory is! Map ||
      memory['forcedGarbageCollection'] != true ||
      memory['garbageCollectionTimestampMicros'] is! int ||
      const <String>{
        'allocatedBytes',
        'allocationCount',
        'heapBeforeGcBytes',
        'heapAfterGcBytes',
        'heapCapacityAfterGcBytes',
        'externalAfterGcBytes',
      }.any((name) => memory[name] is! int || (memory[name] as int) < 0)) {
    throw const FormatException(
      'Editor performance response must include VM allocations and heap after GC.',
    );
  }
}

void _validateFrameMetrics(Map<String, dynamic> data) {
  final metrics = data['frameMetrics'];
  final samples = metrics is Map
      ? metrics['frameSpanSamplesMicroseconds']
      : null;
  if (metrics is! Map ||
      metrics['scope'] != 'flutter.frame_total' ||
      metrics['policy'] != 'observation' ||
      samples is! List ||
      samples.length < 30) {
    throw const FormatException(
      'Editor project journey must include raw Flutter frame timings.',
    );
  }
  _validateSampleRow(<Object?, Object?>{
    'samplesUs': samples,
    'p50Us': metrics['frameSpanP50Us'],
    'p95Us': metrics['frameSpanP95Us'],
    'p99Us': metrics['frameSpanP99Us'],
    'maxUs': samples.cast<int>().reduce((a, b) => a > b ? a : b),
  }, expectedSampleCount: samples.length);
}

File _validatedOutput(String relativePath) {
  final packageRoot = Directory(Directory.current.resolveSymbolicLinksSync());
  if (p.isAbsolute(relativePath)) {
    throw const FormatException(
      'POKEMAP_PERF_OUTPUT must stay inside packages/map_editor.',
    );
  }
  final output = File(
    p.normalize(p.join(packageRoot.path, relativePath)),
  ).absolute;
  if (!p.isWithin(packageRoot.path, output.path)) {
    throw const FormatException(
      'POKEMAP_PERF_OUTPUT must stay inside packages/map_editor.',
    );
  }
  return output;
}

Future<String> _git(List<String> arguments, {String? workingDirectory}) async {
  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: workingDirectory,
  );
  return result.exitCode == 0 ? '${result.stdout}'.trim() : 'unavailable';
}

// Run Git from the repository root and hash untracked contents. The driver is
// itself untracked during this lot, so path-only fingerprints would be false.
Future<String> _sourceTreeFingerprint({
  required String repositoryRoot,
  required String status,
  required String diff,
  required String untracked,
}) async {
  final entries = <Map<String, Object?>>[];
  final paths =
      untracked
          .split('\n')
          .where((path) => path.trim().isNotEmpty)
          .toList(growable: false)
        ..sort();
  for (final relativePath in paths) {
    final file = File(p.join(repositoryRoot, relativePath));
    try {
      final bytes = await file.readAsBytes();
      entries.add(<String, Object?>{
        'path': relativePath,
        'bytes': bytes.length,
        'content': sha256.convert(bytes).toString(),
      });
    } on FileSystemException {
      entries.add(<String, Object?>{
        'path': relativePath,
        'content': 'unavailable',
      });
    }
  }
  return sha256
      .convert(
        utf8.encode(
          jsonEncode(<String, Object?>{
            'status': status,
            'diff': diff,
            'untracked': entries,
          }),
        ),
      )
      .toString();
}

Future<Map<String, Object?>> _flutterMetadata() async {
  final result = await Process.run('flutter', <String>[
    '--version',
    '--machine',
  ]);
  if (result.exitCode != 0) {
    return const <String, Object?>{'status': 'unavailable'};
  }
  final decoded = jsonDecode('${result.stdout}');
  return decoded is Map
      ? Map<String, Object?>.from(decoded)
      : const <String, Object?>{'status': 'malformed'};
}

Future<String> _flameVersion() async {
  final lock = File('pubspec.lock');
  if (!await lock.exists()) return 'unavailable';
  final lines = (await lock.readAsLines());
  final start = lines.indexWhere((line) => line == '  flame:');
  if (start < 0) return 'unavailable';
  for (final line in lines.skip(start + 1)) {
    if (!line.startsWith('    ')) break;
    final trimmed = line.trim();
    if (trimmed.startsWith('version: ')) {
      return trimmed.substring('version: '.length).replaceAll('"', '');
    }
  }
  return 'unavailable';
}

String _architectureLabel() {
  final executable = Platform.resolvedExecutable.toLowerCase();
  if (executable.contains('arm64') || executable.contains('aarch64')) {
    return 'arm64';
  }
  if (executable.contains('x64') || executable.contains('x86_64')) {
    return 'x64';
  }
  if (Platform.version.contains('arm64')) return 'arm64';
  if (Platform.version.contains('x64')) return 'x64';
  return 'unknown';
}
