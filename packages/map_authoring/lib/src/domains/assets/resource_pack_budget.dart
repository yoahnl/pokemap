import 'dart:convert';
import 'dart:isolate';

import 'package:map_distribution/map_distribution.dart';

Future<CatalogBudgetReport> measureProjectDocumentBudget(
  List<int> bytes, {
  required String scope,
}) => Isolate.run(() {
  final json = jsonDecode(utf8.decode(bytes));
  if (json is! Map<String, dynamic>) {
    throw const FormatException('The project document must be an object.');
  }
  final report = const CatalogBudgetCalculator().measureProjectJson(
    json.cast<String, Object?>(), scope: scope,
  );
  const documentDimensions = {
    'catalogBytes', 'jsonNodes', 'jsonDepth', 'collectionEntries',
    'hierarchyEntries', 'hierarchyDepth', 'hierarchyCycles',
  };
  const unmeasured = {
    'files', 'fileBytes', 'imagePixels', 'rgba8BytesEstimate',
    'payloadEntries', 'payloadBytes', 'archiveBytes', 'manifestBytes',
    'fileInventory', 'runtimeProjection',
  };
  return CatalogBudgetReport(
    scope: scope,
    metrics: [for (final metric in report.metrics.where(
        (metric) => documentDimensions.contains(metric.dimension)))
      metric.dimension == 'catalogBytes'
        ? CatalogBudgetMetric(scope: scope, dimension: 'catalogBytes',
            observed: bytes.length,
            allowed: const GamePackageSecurityPolicy().maxJsonBytes,
            unit: 'octets', label: 'Document de projet enregistré',
            remedy: metric.remedy)
        : metric],
    totals: {...report.totals, 'catalogBytes': bytes.length,
      for (final dimension in unmeasured) dimension: null},
    breakdown: report.breakdown,
    unknownDimensions: {...report.unknownDimensions, ...unmeasured},
    omittedBreakdownEntries: report.omittedBreakdownEntries,
  );
});
