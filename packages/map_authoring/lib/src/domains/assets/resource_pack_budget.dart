import 'dart:convert';
import 'dart:isolate';

import 'package:map_distribution/map_distribution.dart';

Future<CatalogBudgetReport> measureProjectDocumentBudget(
  List<int> bytes, {
  required String scope,
}) =>
    Isolate.run(() {
      final json = jsonDecode(utf8.decode(bytes));
      if (json is! Map<String, dynamic>) {
        throw const FormatException('The project document must be an object.');
      }
      const policy = GamePackageSecurityPolicy();
      const calculator = CatalogBudgetCalculator();
      final source = calculator.measureJsonDocument(json,
          scope: '$scope.sourceDocument',
          maxBytes: policy.maxCatalogBytes,
          maxNodes: policy.maxCatalogJsonValues,
          maxDepth: policy.maxJsonDepth);
      final report = json['version'] is String
          ? calculator.measureProjectJson(json.cast<String, Object?>(),
              scope: scope)
          : null;
      const unmeasured = {
        'files',
        'fileBytes',
        'imagePixels',
        'rgba8BytesEstimate',
        'payloadEntries',
        'payloadBytes',
        'archiveBytes',
        'manifestBytes',
        'fileInventory',
        'runtimeProjection',
      };
      const sourceDimensions = {
        'catalogBytes': 'sourceDocumentBytes',
        'jsonNodes': 'sourceDocumentJsonValues',
        'jsonDepth': 'sourceDocumentJsonDepth',
      };
      return CatalogBudgetReport(
        scope: scope,
        metrics: [
          ...?report?.metrics
              .where((metric) => !unmeasured.contains(metric.dimension)),
          for (final metric in source.metrics.where(
              (metric) => sourceDimensions.containsKey(metric.dimension)))
            CatalogBudgetMetric(
                scope: metric.scope,
                dimension: sourceDimensions[metric.dimension]!,
                observed: metric.dimension == 'catalogBytes'
                    ? bytes.length
                    : metric.observed,
                allowed: metric.allowed,
                unit: metric.unit,
                label: metric.label,
                remedy: metric.remedy),
        ],
        totals: {
          ...?report?.totals,
          'sourceDocumentBytes': bytes.length,
          'sourceDocumentJsonValues': source.totals['jsonNodes'],
          'sourceDocumentJsonDepth': source.totals['jsonDepth'],
          for (final dimension in unmeasured) dimension: null,
          if (report == null) ...{
            'catalogBytes': null,
            'jsonNodes': null,
            'jsonDepth': null,
            'catalogObjects': null,
            'collectionEntries': null,
          },
        },
        breakdown: report?.breakdown ?? const [],
        unknownDimensions: {
          ...?report?.unknownDimensions,
          ...unmeasured,
          if (report == null) ...{
            'catalogBytes',
            'jsonNodes',
            'jsonDepth',
            'catalogObjects',
            'collectionEntries',
            'hierarchies',
          },
        },
        omittedBreakdownEntries: report?.omittedBreakdownEntries ?? 0,
      );
    });
