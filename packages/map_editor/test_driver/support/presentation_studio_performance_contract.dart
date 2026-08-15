const presentationStudioPerformanceTarget =
    'integration_test/presentation_studio_performance_journey_test.dart';

const presentationStudioPerformanceBudgets = <String, int>{
  'libraryFirstUs': 5000000,
  'librarySearchP95Us': 100000,
  'studioFirstFrameUs': 5000000,
  'interactionP95Us': 16000,
  'frameBuildP95Us': 16000,
  'frameRasterP95Us': 16000,
  'frameTotalP95Us': 32000,
  'mediaColdP95Us': 1000000,
  'mediaWarmP95Us': 16000,
  'undoP95Us': 250000,
  'redoP95Us': 250000,
  'rssGrowthBytes': 128 * 1024 * 1024,
  'visibleTrackWidgetsMax': 12,
  'visibleClipWidgetsMax': 80,
  'fileHandleGrowthMax': 2,
};

const presentationStudioFixtureMatrix = <Map<String, Object>>[
  <String, Object>{
    'name': 'small',
    'libraryAssets': 10,
    'layers': 10,
    'tracks': 10,
    'clips': 100,
    'durationUs': 15 * 60 * 1000000,
  },
  <String, Object>{
    'name': 'medium',
    'libraryAssets': 250,
    'layers': 50,
    'tracks': 50,
    'clips': 500,
    'durationUs': 15 * 60 * 1000000,
  },
  <String, Object>{
    'name': 'limit',
    'libraryAssets': 1000,
    'layers': 100,
    'tracks': 100,
    'clips': 1100,
    'durationUs': 15 * 60 * 1000000,
  },
];

void validatePresentationStudioPerformanceReceipt(
  Map<String, dynamic> data, {
  required bool requireProvenance,
}) {
  if (data['benchmark'] != 'presentation_studio_cin_060' ||
      data['generatorVersion'] != 1 ||
      data['target'] != presentationStudioPerformanceTarget) {
    throw const FormatException('CIN-060 receipt identity is invalid.');
  }
  _validateExactMap(
    data['performanceBudgets'],
    presentationStudioPerformanceBudgets,
    'CIN-060 performance budgets',
  );
  _validateFixtureMatrix(data['fixtureMatrix']);
  final policy = data['optimizationPolicy'];
  if (policy is! Map ||
      policy['certificationOnly'] != true ||
      policy['hiddenOptimizations'] != 0) {
    throw const FormatException(
      'CIN-060 must remain a certification-only ticket.',
    );
  }
  final enforceBudgets = data['executionMode'] == 'flutter-profile';
  if (requireProvenance && !enforceBudgets) {
    throw const FormatException(
      'CIN-060 exact-SHA receipts require a profile execution.',
    );
  }
  _validateScenarios(data['scenarios'], enforceBudgets: enforceBudgets);
  _validateMedia(data['media'], enforceBudgets: enforceBudgets);
  _validateSession(data['session'], enforceBudgets: enforceBudgets);
}

void _validateFixtureMatrix(Object? value) {
  if (value is! List ||
      value.length != presentationStudioFixtureMatrix.length) {
    throw const FormatException(
      'CIN-060 requires the small, medium and limit fixture matrix.',
    );
  }
  for (var index = 0; index < presentationStudioFixtureMatrix.length; index++) {
    _validateExactMap(
      value[index],
      presentationStudioFixtureMatrix[index],
      'CIN-060 fixture ${presentationStudioFixtureMatrix[index]['name']}',
    );
  }
}

void _validateScenarios(Object? value, {required bool enforceBudgets}) {
  if (value is! List ||
      value.length != presentationStudioFixtureMatrix.length) {
    throw const FormatException(
      'CIN-060 requires one result per declared fixture.',
    );
  }
  final names = <String>{};
  for (final entry in value) {
    if (entry is! Map || entry['fixture'] is! String) {
      throw const FormatException('CIN-060 scenario is malformed.');
    }
    final fixture = entry['fixture']! as String;
    if (!names.add(fixture) ||
        !const <String>{'small', 'medium', 'limit'}.contains(fixture)) {
      throw const FormatException('CIN-060 scenario identity is invalid.');
    }
    _validateLibrary(entry['library'], enforceBudgets: enforceBudgets);
    _validateStudio(entry['studio'], enforceBudgets: enforceBudgets);
  }
}

void _validateLibrary(Object? value, {required bool enforceBudgets}) {
  if (value is! Map ||
      value['firstUs'] is! int ||
      (value['firstUs']! as int) < 0 ||
      value['restoredFolder'] != true ||
      value['restoredScrollOffset'] != true) {
    throw const FormatException('CIN-060 Library evidence is incomplete.');
  }
  final search = _validateMetrics(value['search'], minimumSamples: 31);
  if (enforceBudgets &&
      ((value['firstUs']! as int) >=
              presentationStudioPerformanceBudgets['libraryFirstUs']! ||
          search.p95 >=
              presentationStudioPerformanceBudgets['librarySearchP95Us']!)) {
    throw const FormatException('CIN-060 Library budget exceeded.');
  }
}

void _validateStudio(Object? value, {required bool enforceBudgets}) {
  if (value is! Map ||
      value['firstFrameUs'] is! int ||
      (value['firstFrameUs']! as int) < 0 ||
      value['visibleTrackWidgetsMax'] is! int ||
      value['visibleClipWidgetsMax'] is! int) {
    throw const FormatException('CIN-060 Studio evidence is incomplete.');
  }
  final interactionMetrics = <_Metrics>[
    for (final name in const <String>[
      'pointer',
      'drag',
      'trim',
      'scrub',
      'zoom',
    ])
      _validateMetrics(value[name], minimumSamples: 60),
  ];
  final frames = value['frames'];
  if (frames is! Map) {
    throw const FormatException('CIN-060 frame evidence is missing.');
  }
  final build = _validateMetrics(frames['build'], minimumSamples: 60);
  final raster = _validateMetrics(frames['raster'], minimumSamples: 60);
  final total = _validateMetrics(frames['total'], minimumSamples: 60);
  final tracks = value['visibleTrackWidgetsMax']! as int;
  final clips = value['visibleClipWidgetsMax']! as int;
  if (tracks < 0 ||
      clips < 0 ||
      tracks >
          presentationStudioPerformanceBudgets['visibleTrackWidgetsMax']! ||
      clips > presentationStudioPerformanceBudgets['visibleClipWidgetsMax']!) {
    throw const FormatException(
      'CIN-060 viewport virtualization bounds were exceeded.',
    );
  }
  if (enforceBudgets &&
      ((value['firstFrameUs']! as int) >=
              presentationStudioPerformanceBudgets['studioFirstFrameUs']! ||
          interactionMetrics.any(
            (metrics) =>
                metrics.p95 >=
                presentationStudioPerformanceBudgets['interactionP95Us']!,
          ) ||
          build.p95 >=
              presentationStudioPerformanceBudgets['frameBuildP95Us']! ||
          raster.p95 >=
              presentationStudioPerformanceBudgets['frameRasterP95Us']! ||
          total.p95 >=
              presentationStudioPerformanceBudgets['frameTotalP95Us']!)) {
    throw const FormatException('CIN-060 Studio budget exceeded.');
  }
}

void _validateMedia(Object? value, {required bool enforceBudgets}) {
  if (value is! Map ||
      !_exactList(value['projectionKinds'], const <String>[
        'audio',
        'video',
        'captions',
      ]) ||
      value['backgroundDecodeResponsive'] != true ||
      value['coldGatewayLoads'] != 93 ||
      value['warmGatewayLoads'] != 0) {
    throw const FormatException('CIN-060 media cache evidence is incomplete.');
  }
  final cold = _validateMetrics(value['cold'], minimumSamples: 31);
  final warm = _validateMetrics(value['warm'], minimumSamples: 31);
  if (warm.p95 > cold.p95) {
    throw const FormatException('CIN-060 warm media cache regressed.');
  }
  if (enforceBudgets &&
      (cold.p95 >= presentationStudioPerformanceBudgets['mediaColdP95Us']! ||
          warm.p95 >=
              presentationStudioPerformanceBudgets['mediaWarmP95Us']!)) {
    throw const FormatException('CIN-060 media cache budget exceeded.');
  }
}

bool _exactList(Object? value, List<Object> expected) {
  if (value is! List || value.length != expected.length) return false;
  for (var index = 0; index < expected.length; index++) {
    if (value[index] != expected[index]) return false;
  }
  return true;
}

void _validateSession(Object? value, {required bool enforceBudgets}) {
  if (value is! Map ||
      value['undoRedoCycles'] != 50 ||
      value['openCloseCycles'] != 50 ||
      value['rssBeforeBytes'] is! int ||
      value['rssAfterBytes'] is! int ||
      value['rssGrowthBytes'] is! int ||
      value['fileHandlesBefore'] is! int ||
      value['fileHandlesAfter'] is! int ||
      value['fileHandleGrowth'] is! int ||
      value['orphanedTransactions'] != 0 ||
      value['draftPreservedAfterConflict'] != true) {
    throw const FormatException('CIN-060 session evidence is incomplete.');
  }
  final rssGrowth =
      (value['rssAfterBytes']! as int) - (value['rssBeforeBytes']! as int);
  final handleGrowth =
      (value['fileHandlesAfter']! as int) -
      (value['fileHandlesBefore']! as int);
  if (value['rssGrowthBytes'] != rssGrowth ||
      value['fileHandleGrowth'] != handleGrowth) {
    throw const FormatException('CIN-060 session deltas are inconsistent.');
  }
  final undo = _validateMetrics(value['undo'], minimumSamples: 50);
  final redo = _validateMetrics(value['redo'], minimumSamples: 50);
  if (enforceBudgets &&
      (undo.p95 >= presentationStudioPerformanceBudgets['undoP95Us']! ||
          redo.p95 >= presentationStudioPerformanceBudgets['redoP95Us']! ||
          rssGrowth >=
              presentationStudioPerformanceBudgets['rssGrowthBytes']! ||
          handleGrowth >
              presentationStudioPerformanceBudgets['fileHandleGrowthMax']!)) {
    throw const FormatException('CIN-060 session budget exceeded.');
  }
}

_Metrics _validateMetrics(Object? value, {required int minimumSamples}) {
  if (value is! Map || value['samplesUs'] is! List) {
    throw const FormatException('CIN-060 metric samples are missing.');
  }
  final raw = value['samplesUs']! as List;
  if (raw.length < minimumSamples ||
      raw.any((sample) => sample is! int || sample < 0)) {
    throw const FormatException('CIN-060 metric samples are invalid.');
  }
  final samples = raw.cast<int>().toList(growable: false)..sort();
  final metrics = _Metrics(
    p50: _percentile(samples, 0.50),
    p95: _percentile(samples, 0.95),
    p99: _percentile(samples, 0.99),
    max: samples.last,
  );
  if (value['p50Us'] != metrics.p50 ||
      value['p95Us'] != metrics.p95 ||
      value['p99Us'] != metrics.p99 ||
      value['maxUs'] != metrics.max) {
    throw const FormatException('CIN-060 metric percentiles are invalid.');
  }
  return metrics;
}

void _validateExactMap(Object? value, Map expected, String label) {
  if (value is! Map || value.length != expected.length) {
    throw FormatException('$label is incomplete.');
  }
  for (final entry in expected.entries) {
    if (value[entry.key] != entry.value) {
      throw FormatException('$label must remain versioned and immutable.');
    }
  }
}

int _percentile(List<int> sorted, double percentile) {
  final index = (percentile * sorted.length).ceil() - 1;
  return sorted[index.clamp(0, sorted.length - 1)];
}

final class _Metrics {
  const _Metrics({
    required this.p50,
    required this.p95,
    required this.p99,
    required this.max,
  });

  final int p50;
  final int p95;
  final int p99;
  final int max;
}
