import 'dart:convert';

import 'dart:collection';

import 'package:map_core/map_core.dart';

import 'canonical_json.dart';
import 'game_package_security_policy.dart';
import 'resource_pack_security_policy.dart';

final class CatalogBudgetMetric {
  const CatalogBudgetMetric({
    required this.scope,
    required this.dimension,
    required this.observed,
    this.allowed,
    required this.unit,
    required this.label,
    required this.remedy,
  });

  final String scope;
  final String dimension;
  final int observed;
  final int? allowed;
  final String unit;
  final String label;
  final String remedy;

  bool get exceeded => allowed != null && observed > allowed!;

  Map<String, Object?> toJson() => {
        'scope': scope,
        'dimension': dimension,
        'observed': observed,
        'allowed': allowed,
        'unit': unit,
        'label': label,
        'remedy': remedy,
      };
}

final class CatalogBudgetViolation {
  const CatalogBudgetViolation({required this.metric});

  final CatalogBudgetMetric metric;
  String get scope => metric.scope;
  String get dimension => metric.dimension;
  int get observed => metric.observed;
  int? get allowed => metric.allowed;
  String get unit => metric.unit;
  String get label => metric.label;
  String get remedy => metric.remedy;

  Map<String, Object?> toJson() => metric.toJson();
}

final class CatalogBudgetReport {
  CatalogBudgetReport({
    required this.scope,
    required Iterable<CatalogBudgetMetric> metrics,
    Map<String, int?> totals = const {},
    Iterable<CatalogBudgetMetric> breakdown = const [],
    Iterable<String> unknownDimensions = const [],
    this.omittedBreakdownEntries = 0,
  })  : metrics = List.unmodifiable(metrics),
        totals = Map.unmodifiable(totals),
        breakdown = List.unmodifiable(breakdown),
        unknownDimensions =
            List.unmodifiable(unknownDimensions.toSet().toList()..sort());

  final String scope;
  final List<CatalogBudgetMetric> metrics;
  final Map<String, int?> totals;
  final List<CatalogBudgetMetric> breakdown;
  final List<String> unknownDimensions;
  final int omittedBreakdownEntries;

  List<CatalogBudgetViolation> get violations => List.unmodifiable([
        for (final metric in metrics)
          if (metric.exceeded) CatalogBudgetViolation(metric: metric),
      ]);
  bool get accepted => !metrics.any((metric) => metric.exceeded);
  bool get measurementComplete => unknownDimensions.isEmpty;

  Map<String, Object?> toBoundedJson({int maximumBytes = 200 * 1024}) {
    if (maximumBytes < 512) {
      throw ArgumentError.value(
          maximumBytes, 'maximumBytes', 'must be at least 512');
    }
    final exact = toJson();
    bool fits(Map<String, Object?> value) =>
        CanonicalJson.encodeUtf8(value).length <= maximumBytes;
    if (fits(exact)) return exact;
    final groups = <(String, int?, String), List<CatalogBudgetMetric>>{};
    for (final metric in metrics) {
      groups.putIfAbsent((metric.dimension, metric.allowed, metric.unit),
          () => []).add(metric);
    }
    final aggregated = <Map<String, Object?>>[];
    final groupKeys = groups.keys.toList()
      ..sort((left, right) {
        var order = left.$1.compareTo(right.$1);
        if (order != 0) return order;
        order =
            (left.$2?.toString() ?? '').compareTo(right.$2?.toString() ?? '');
        return order != 0 ? order : left.$3.compareTo(right.$3);
      });
    for (final key in groupKeys) {
      final values = groups[key]!;
      var representative = values.first;
      var violationCount = 0;
      for (final metric in values) {
        if (metric.exceeded) violationCount++;
        if (metric.observed > representative.observed ||
            metric.observed == representative.observed &&
                metric.scope.compareTo(representative.scope) < 0) {
          representative = metric;
        }
      }
      aggregated.add({
        ...representative.toJson(),
        'metricCount': values.length,
        'violationCount': violationCount,
      });
    }
    final violationCount = metrics.where((metric) => metric.exceeded).length;
    final detailCount = breakdown.length + omittedBreakdownEntries;
    final summary = <String, Object?>{
      'scope': String.fromCharCodes(scope.runes.take(128)),
      'accepted': accepted,
      'measurementComplete': measurementComplete,
      'metricCount': metrics.length,
      'violationCount': violationCount,
      'unknownDimensionsCount': unknownDimensions.length,
      'omittedUnknownDimensions': unknownDimensions.length,
      'breakdownCount': detailCount,
      'omittedBreakdownEntries': detailCount,
      'truncated': true,
    };
    final bounded = <String, Object?>{
      ...summary,
      'scope': scope,
      'totals': totals,
      'metrics': aggregated,
      'violations': [
        for (final group in aggregated)
          if ((group['violationCount'] as int) > 0) group,
      ],
      'breakdown': <Object?>[],
      'unknownDimensions': <String>[],
      'aggregation': 'maximumObservedPerDimensionAllowedUnit',
    };
    if (fits(bounded)) return bounded;
    final scopeRunes = (summary['scope'] as String).runes.toList();
    while (!fits(summary) && scopeRunes.isNotEmpty) {
      scopeRunes.removeLast();
      summary['scope'] = String.fromCharCodes(scopeRunes);
    }
    return summary;
  }

  Map<String, Object?> toJson() => {
        'scope': scope,
        'accepted': accepted,
        'measurementComplete': measurementComplete,
        'unknownDimensions': unknownDimensions,
        'totals': totals,
        'metrics': [for (final metric in metrics) metric.toJson()],
        'violations': [for (final violation in violations) violation.toJson()],
        'breakdown': [for (final metric in breakdown) metric.toJson()],
        'omittedBreakdownEntries': omittedBreakdownEntries,
      };
}

final class CatalogBudgetExceededException implements Exception {
  const CatalogBudgetExceededException(this.report);

  final CatalogBudgetReport report;
  String get code => 'catalog.budget_exceeded';
  String get message {
    final violations = report.violations;
    final details = violations.take(5).map((v) =>
        '${v.label} : ${v.observed} ${v.unit}, limite ${v.allowed}. ${v.remedy}');
    return 'Budget du catalogue dépassé. ${details.join(' ')}'
        '${violations.length > 5 ? ' Autres limites dépassées : ${violations.length - 5}.' : ''}';
  }

  @override
  String toString() => '$code: $message';
}

final class CatalogBudgetFile {
  const CatalogBudgetFile({
    required this.path,
    this.byteLength,
    this.imageWidth,
    this.imageHeight,
    this.isPreview = false,
  });

  final String path;
  final int? byteLength;
  final int? imageWidth;
  final int? imageHeight;
  final bool isPreview;
}

final class CatalogBudgetCalculator {
  const CatalogBudgetCalculator({
    this.resourcePackPolicy = const ResourcePackSecurityPolicy(),
    this.gamePackagePolicy = const GamePackageSecurityPolicy(),
    this.maxBreakdownEntries = 100,
  });

  final ResourcePackSecurityPolicy resourcePackPolicy;
  final GamePackageSecurityPolicy gamePackagePolicy;
  final int maxBreakdownEntries;

  CatalogBudgetReport measureJsonDocument(
    Object? json, {
    required String scope,
    int? maxBytes,
    int? maxNodes,
    int? maxDepth,
  }) {
    final report = _BudgetBuilder(scope, maxBreakdownEntries);
    _json(report, json, maxBytes, maxNodes, maxDepth);
    return report.build();
  }

  CatalogBudgetReport measureResourcePack(
    ResourcePackCatalog catalog, {
    String scope = 'resourcePack',
    Iterable<CatalogBudgetFile> files = const [],
    int? archiveBytes,
    int? manifestBytes,
  }) {
    final policy = resourcePackPolicy;
    final report =
        _BudgetBuilder(scope, maxBreakdownEntries, resourcePack: true);
    final json = catalog.toJson();
    _publication(report, PortableCatalogPublication.encodeCatalog(catalog),
        maxBytes: policy.maxCatalogBytes,
        maxValues: policy.maxJsonNodes,
        maxDepth: policy.maxJsonDepth);
    final graph = ResourcePackDependencyGraph.fromCatalog(catalog);
    final closure = graph.validateAll();
    final implicitFamilies = ResourceLibraryCatalog.predefinedFamilies
        .map((f) => f.id)
        .toSet()
      ..removeAll(catalog.resourceLibraryCatalog.families.map((f) => f.id));
    final supports = closure.supports
        .where((support) =>
            support.kind != ResourcePackSupportKind.resourceFamily ||
            !implicitFamilies.contains(support.id))
        .toList();
    report.total('resources', closure.resources.length, policy.maxResources);
    report.total('supports', supports.length, policy.maxSupports);
    report.total('referencedFiles', closure.files.length, null);
    report.total('graphNodes', graph.nodes.length, null);
    report.total(
        'graphEdges',
        graph.nodes.fold<int>(0, (sum, node) => sum + node.dependencies.length),
        null);
    for (final kind in ResourcePackKind.values) {
      report.detail('$scope.resources.${kind.name}',
          closure.resources.where((r) => r.kind == kind).length);
    }
    for (final kind in ResourcePackSupportKind.values) {
      report.detail('$scope.supports.${kind.name}',
          supports.where((r) => r.kind == kind).length);
    }
    _hierarchy(report, json['tilesetFolders'], '$scope.tilesetFolders',
        'parentFolderId', policy.maxHierarchyEntries, policy.maxHierarchyDepth);
    _hierarchy(
        report,
        json['elementCategories'],
        '$scope.elementCategories',
        'parentCategoryId',
        policy.maxHierarchyEntries,
        policy.maxHierarchyDepth);
    _hierarchy(
        report,
        catalog.resourceLibraryCatalog.toJson()['families'],
        '$scope.resourceLibraryCatalog.families',
        'parentId',
        policy.maxHierarchyEntries,
        policy.maxHierarchyDepth);
    final tilesets = json['tilesets'] as List;
    for (var i = 0; i < tilesets.length; i++) {
      _hierarchy(
          report,
          (tilesets[i] as Map)['elementGroups'],
          '$scope.tilesets[$i].elementGroups',
          'parentGroupId',
          policy.maxHierarchyEntries,
          policy.maxHierarchyDepth);
    }
    final descriptors = <String, CatalogBudgetFile>{
      for (final binding in catalog.files)
        binding.archivePath: CatalogBudgetFile(
            path: binding.archivePath, byteLength: binding.byteLength),
    };
    for (final file
        in files.where((f) => !f.path.startsWith('catalog/objects/'))) {
      final previous = descriptors[file.path];
      if (previous?.byteLength != null &&
          file.byteLength != null &&
          previous!.byteLength != file.byteLength) {
        throw const FormatException('Métadonnées de fichier contradictoires.');
      }
      descriptors[file.path] = CatalogBudgetFile(
          path: file.path,
          byteLength: file.byteLength ?? previous?.byteLength,
          imageWidth: file.imageWidth,
          imageHeight: file.imageHeight,
          isPreview: file.isPreview);
    }
    report.total(
        'files', descriptors.length + report.totals['catalogObjects']!, null);
    _files(report, descriptors.values, pack: true);
    _includeCatalogFileBytes(report);
    report.optionalTotal('archiveBytes', archiveBytes, policy.maxArchiveBytes);
    report.optionalTotal(
        'manifestBytes', manifestBytes, policy.maxManifestBytes);
    report.optionalTotal('publishedFiles', null, policy.maxPublishedFiles);
    report.total(
        'zipEntries',
        descriptors.length + report.totals['catalogObjects']! + 2,
        policy.maxZipEntries);
    final fileBytes = report.totals['fileBytes'];
    report.optionalTotal(
        'payloadBytes',
        fileBytes == null
            ? null
            : fileBytes + report.totals['catalogDescriptorBytes']!,
        policy.maxTotalPayloadBytes);
    return report.build();
  }

  CatalogBudgetReport measureProjectJson(
    Map<String, Object?> projectJson, {
    String scope = 'project',
    Iterable<CatalogBudgetFile> files = const [],
    int? archiveBytes,
    int? manifestBytes,
  }) {
    final policy = gamePackagePolicy;
    final report = _BudgetBuilder(scope, maxBreakdownEntries);
    if (projectJson['version'] is String) {
      _publication(
          report,
          PortableCatalogPublication.encodeProject(
              ProjectManifest.fromJson(Map<String, dynamic>.from(projectJson))),
          maxBytes: policy.maxCatalogBytes,
          maxValues: policy.maxCatalogJsonValues,
          maxDepth: policy.maxJsonDepth);
    } else {
      _json(report, projectJson, policy.maxJsonBytes, policy.maxJsonNodes,
          policy.maxJsonDepth);
      report.total('catalogObjects', 0, null);
      report.total('catalogObjectBytes', 0, null);
      report.total(
          'catalogDescriptorBytes', report.totals['catalogBytes']!, null);
    }
    var entries = 0;
    for (final field in _projectCollections) {
      final value = projectJson[field];
      if (value is List) {
        entries += value.length;
      }
    }
    report.total(
        'collectionEntries', entries, policy.maxProjectCollectionEntries);
    for (final entry in _projectHierarchies.entries) {
      _hierarchy(
          report,
          projectJson[entry.key],
          '$scope.${entry.key}',
          entry.value,
          policy.maxProjectHierarchyEntries,
          policy.maxProjectHierarchyDepth);
    }
    final descriptors = files
        .where((f) =>
            !f.path.startsWith('project/catalog/objects/') &&
            f.path != 'project/project.json')
        .toList();
    if (descriptors.map((file) => file.path).toSet().length !=
        descriptors.length) {
      throw const FormatException('Chemin de fichier dupliqué.');
    }
    _files(report, descriptors, pack: false);
    _includeCatalogFileBytes(report);
    report.total(
        'files', descriptors.length + report.totals['catalogObjects']!, null);
    report.total(
        'payloadEntries',
        descriptors.length + report.totals['catalogObjects']! + 1,
        policy.maxPayloadEntries);
    report.optionalTotal('archiveBytes', archiveBytes, policy.maxArchiveBytes);
    report.optionalTotal(
        'manifestBytes', manifestBytes, policy.maxManifestBytes);
    final fileBytes = report.totals['fileBytes'];
    report.optionalTotal(
        'payloadBytes',
        fileBytes == null
            ? null
            : fileBytes + report.totals['catalogDescriptorBytes']!,
        policy.maxTotalPayloadBytes);
    return report.build();
  }

  void _includeCatalogFileBytes(_BudgetBuilder report) {
    final binaryBytes = report.totals['fileBytes'];
    report.totals['fileBytes'] = binaryBytes == null
        ? null
        : binaryBytes + report.totals['catalogObjectBytes']!;
  }

  void _publication(
      _BudgetBuilder report, PortableCatalogPublicationBuild publication,
      {required int maxBytes, required int maxValues, required int maxDepth}) {
    final descriptorBytes =
        CanonicalJson.encodeUtf8(publication.descriptor).length;
    var bytes = descriptorBytes;
    var values = 0;
    var depth = 0;
    for (final entry in publication.storage.objects.entries) {
      bytes += entry.value.length;
      final raw = jsonDecode(utf8.decode(entry.value));
      final local =
          _BudgetBuilder('${report.scope}.catalog.objects.${entry.key}', 0);
      _json(local, raw, null, null, null);
      values += local.totals['jsonNodes']!;
      final localDepth = local.totals['jsonDepth']!;
      if (localDepth > depth) depth = localDepth;
      final index = raw is Map && raw['type'] != 'unit';
      report.metric(
          local.scope,
          index ? 'catalogIndexBytes' : 'catalogUnitBytes',
          entry.value.length,
          index ? 256 * 1024 : 1024 * 1024);
      report.metric(
          local.scope,
          'fileBytes',
          entry.value.length,
          report.resourcePack
              ? resourcePackPolicy.maxFileBytes
              : gamePackagePolicy.maxFileBytes);
      report.metric(local.scope, 'catalogObjectValues',
          local.totals['jsonNodes']!, 100000);
    }
    final descriptor = _BudgetBuilder(report.scope, 0);
    _json(descriptor, publication.descriptor, null, null, null);
    values += descriptor.totals['jsonNodes']!;
    report.total('catalogBytes', bytes, maxBytes);
    report.total('catalogDescriptorBytes', descriptorBytes, null);
    report.total('catalogObjectBytes', bytes - descriptorBytes, null);
    report.total('catalogObjects', publication.storage.objects.length, null);
    report.total('jsonNodes', values, maxValues);
    report.total('jsonDepth', depth, maxDepth < 64 ? maxDepth : 64);
  }

  void _json(_BudgetBuilder report, Object? json, int? maxBytes, int? maxNodes,
      int? maxDepth) {
    var bytes = 0;
    var nodes = 0;
    var depth = 0;
    final active = HashSet<Object>.identity();
    final stack = <_JsonFrame>[_JsonFrame(json, 0, report.scope)];
    while (stack.isNotEmpty) {
      final frame = stack.last;
      if (!frame.started) {
        frame.started = true;
        nodes++;
        final value = frame.value;
        if (value is Map || value is List) {
          if (!active.add(value!)) {
            throw const FormatException('Le JSON contient un cycle.');
          }
          final containerDepth = frame.depth + 1;
          if (containerDepth > depth) depth = containerDepth;
          bytes += 2;
          if (value is Map) {
            final entries = value.entries.toList();
            entries.sort((a, b) {
              if (a.key is! String || b.key is! String) {
                throw const CanonicalJsonException(
                    'Canonical JSON object keys must be strings.');
              }
              return (a.key as String).compareTo(b.key as String);
            });
            frame.children = entries.map((entry) {
              if (entry.key is! String) {
                throw const CanonicalJsonException(
                    'Canonical JSON object keys must be strings.');
              }
              bytes += CanonicalJson.encodeUtf8(entry.key).length + 1;
              return _JsonFrame(
                  entry.value, containerDepth, '${frame.path}.${entry.key}');
            }).iterator;
            bytes += entries.isEmpty ? 0 : entries.length - 1;
          } else {
            final list = value as List;
            report.detail(frame.path, list.length);
            var index = 0;
            frame.children = list
                .map((entry) => _JsonFrame(
                    entry, containerDepth, '${frame.path}[${index++}]'))
                .iterator;
            bytes += list.isEmpty ? 0 : list.length - 1;
          }
        } else {
          bytes += CanonicalJson.encodeUtf8(value).length;
        }
      }
      final children = frame.children;
      if (children != null && children.moveNext()) {
        stack.add(children.current);
      } else {
        if (frame.value is Map || frame.value is List) {
          active.remove(frame.value);
        }
        stack.removeLast();
      }
    }
    report.total('catalogBytes', bytes, maxBytes);
    report.total('jsonNodes', nodes, maxNodes);
    report.total('jsonDepth', depth, maxDepth);
  }

  void _hierarchy(_BudgetBuilder report, Object? value, String scope,
      String parentField, int maxEntries, int maxDepth) {
    if (value is! List) return;
    report.metric(scope, 'hierarchyEntries', value.length, maxEntries);
    final parents = <String, String?>{};
    for (final entry in value) {
      if (entry is Map &&
          entry['id'] is String &&
          (entry[parentField] == null || entry[parentField] is String)) {
        parents[entry['id'] as String] = entry[parentField] as String?;
      }
    }
    var deepest = 0;
    var cycles = 0;
    final depths = <String, int>{};
    for (final id in parents.keys) {
      if (depths.containsKey(id)) continue;
      final chain = <String>[];
      final seen = <String>{};
      String? current = id;
      while (current != null &&
          parents.containsKey(current) &&
          !depths.containsKey(current)) {
        if (!seen.add(current)) {
          cycles++;
          break;
        }
        chain.add(current);
        current = parents[current];
      }
      var currentDepth = depths[current] ?? 0;
      for (final ancestor in chain.reversed) {
        depths[ancestor] = ++currentDepth;
        if (currentDepth > deepest) deepest = currentDepth;
      }
    }
    report.metric(scope, 'hierarchyDepth', deepest, maxDepth);
    report.metric(scope, 'hierarchyCycles', cycles, 0);
  }

  void _files(_BudgetBuilder report, Iterable<CatalogBudgetFile> files,
      {required bool pack}) {
    var byteTotal = 0;
    var imagePixels = 0;
    var bytesKnown = true;
    var imagesKnown = true;
    var previewCount = 0;
    final sorted = files.toList()..sort((a, b) => a.path.compareTo(b.path));
    for (final file in sorted) {
      if (file.path.isEmpty ||
          file.path.startsWith('/') ||
          file.path.startsWith('\\') ||
          RegExp(r'^[A-Za-z]:').hasMatch(file.path) ||
          file.path.split(RegExp(r'[/\\]')).contains('..')) {
        throw const FormatException('Un chemin de fichier relatif est requis.');
      }
      for (final value in [
        file.byteLength,
        file.imageWidth,
        file.imageHeight
      ]) {
        if (value != null && value < 0) {
          throw const FormatException('Une mesure ne peut pas être négative.');
        }
      }
      final preview = file.isPreview || file.path.startsWith('previews/');
      final size = file.byteLength;
      if (size == null) {
        bytesKnown = false;
        report.unknown.add('${file.path}.fileBytes');
      } else {
        byteTotal += size;
        report.metric(
            file.path,
            'fileBytes',
            size,
            pack
                ? resourcePackPolicy.maxFileBytes
                : gamePackagePolicy.maxFileBytes);
        if (pack && preview) {
          report.metric(file.path, 'previewBytes', size,
              resourcePackPolicy.maxPreviewBytes);
        }
      }
      final width = file.imageWidth;
      final height = file.imageHeight;
      final image = width != null ||
          height != null ||
          RegExp(r'\.(png|jpe?g|gif|webp)$', caseSensitive: false)
              .hasMatch(file.path);
      if (image) {
        if (width != null) {
          report.metric(
              file.path,
              'imageWidth',
              width,
              pack
                  ? resourcePackPolicy.maxImageDimension
                  : gamePackagePolicy.maxImageDimension);
        }
        if (height != null) {
          report.metric(
              file.path,
              'imageHeight',
              height,
              pack
                  ? resourcePackPolicy.maxImageDimension
                  : gamePackagePolicy.maxImageDimension);
        }
        if (width == null || height == null) {
          imagesKnown = false;
          report.unknown.add('${file.path}.imageDimensions');
        } else {
          final pixels = width * height;
          imagePixels += pixels;
          report.metric(
              file.path,
              'imagePixels',
              pixels,
              pack
                  ? resourcePackPolicy.maxImagePixels
                  : gamePackagePolicy.maxImagePixels);
          report.metric(file.path, 'rgba8BytesEstimate', pixels * 4, null);
        }
      }
      if (preview) previewCount++;
      report.detail(file.path, 1);
    }
    report.totals['fileBytes'] = bytesKnown ? byteTotal : null;
    report.totals['imagePixels'] = imagesKnown ? imagePixels : null;
    report.totals['rgba8BytesEstimate'] = imagesKnown ? imagePixels * 4 : null;
    if (pack) {
      report.total(
          'previewFiles', previewCount, resourcePackPolicy.maxPreviewFiles);
    }
  }

  static const _projectCollections = {
    'maps',
    'models3d',
    'groups',
    'tilesetFolders',
    'tilesets',
    'elementCategories',
    'elements',
    'terrainCategories',
    'pathCategories',
    'terrainPresets',
    'pathPresets',
    'pathPatternPresets',
    'environmentPresets',
    'encounterTables',
    'dialogueFolders',
    'dialogues',
    'scripts',
    'scenarios',
    'cinematics',
    'cinematicMediaAssets',
    'facts',
    'worldRules',
    'scenes',
    'storylines',
    'shops',
    'badges',
    'trainers',
    'characters',
  };
  static const _projectHierarchies = {
    'groups': 'parentGroupId',
    'tilesetFolders': 'parentFolderId',
    'dialogueFolders': 'parentFolderId',
    'elementCategories': 'parentCategoryId',
    'terrainCategories': 'parentCategoryId',
    'pathCategories': 'parentCategoryId',
  };
}

final class _JsonFrame {
  _JsonFrame(this.value, this.depth, this.path);
  final Object? value;
  final int depth;
  final String path;
  bool started = false;
  Iterator<_JsonFrame>? children;
}

final class _BudgetBuilder {
  _BudgetBuilder(this.scope, this.maxBreakdownEntries,
      {this.resourcePack = false}) {
    if (maxBreakdownEntries < 0) {
      throw ArgumentError.value(maxBreakdownEntries, 'maxBreakdownEntries');
    }
  }
  final String scope;
  final int maxBreakdownEntries;
  final bool resourcePack;
  final metrics = <CatalogBudgetMetric>[];
  final breakdown = <CatalogBudgetMetric>[];
  final totals = <String, int?>{};
  final unknown = <String>{};
  int detailCount = 0;

  void total(String dimension, int observed, int? allowed) {
    totals[dimension] = observed;
    metric(scope, dimension, observed, allowed);
  }

  void optionalTotal(String dimension, int? observed, int? allowed) {
    if (observed == null) {
      totals[dimension] = null;
      unknown.add(dimension);
    } else {
      if (observed < 0) {
        throw const FormatException('Une mesure ne peut pas être négative.');
      }
      total(dimension, observed, allowed);
    }
  }

  void metric(
      String metricScope, String dimension, int observed, int? allowed) {
    metrics.add(_metric(metricScope, dimension, observed, allowed));
  }

  CatalogBudgetMetric _metric(
      String metricScope, String dimension, int observed, int? allowed) {
    final bytes = dimension.toLowerCase().contains('bytes');
    final label = switch (dimension) {
      'catalogBytes' => 'Taille du catalogue JSON',
      'jsonNodes' => 'Valeurs JSON',
      'jsonDepth' => 'Profondeur JSON',
      'resources' => 'Ressources',
      'supports' => 'Supports et dépendances',
      'collectionEntries' => 'Entrées des collections du projet',
      'hierarchyEntries' => 'Entrées de la hiérarchie',
      'hierarchyDepth' => 'Profondeur de la hiérarchie',
      'hierarchyCycles' => 'Cycles de la hiérarchie',
      'fileBytes' => 'Taille des fichiers',
      'payloadBytes' => 'Charge utile déclarée',
      'archiveBytes' => 'Taille de l’archive',
      'manifestBytes' => 'Taille du manifeste',
      'imageWidth' => 'Largeur de l’image',
      'imageHeight' => 'Hauteur de l’image',
      'imagePixels' => 'Surface des images',
      'rgba8BytesEstimate' =>
        'Estimation de surface RGBA8, hors mémoire réelle du processus',
      'referencedFiles' => 'Fichiers déclarés dans le graphe',
      'graphNodes' => 'Nœuds du graphe',
      'graphEdges' => 'Dépendances du graphe',
      'publishedFiles' => 'Fichiers publiés',
      'zipEntries' => 'Entrées ZIP',
      'payloadEntries' => 'Entrées de charge utile',
      'previewFiles' => 'Aperçus',
      'previewBytes' => 'Taille de l’aperçu',
      _ => 'Entrées',
    };
    return CatalogBudgetMetric(
        scope: metricScope,
        dimension: dimension,
        observed: observed,
        allowed: allowed,
        unit: bytes
            ? 'octets'
            : dimension.startsWith('image')
                ? 'pixels'
                : 'unités',
        label: label,
        remedy: allowed == null
            ? 'Mesure informative.'
            : dimension.startsWith('image')
                ? 'Réduire les dimensions de l’image.'
                : dimension.startsWith('hierarchy')
                    ? 'Réduire ou corriger la hiérarchie.'
                    : resourcePack
                        ? 'Réduire la sélection ou répartir les définitions dans plusieurs packs.'
                        : 'Réduire la complexité du document.');
  }

  void detail(String detailScope, int count) {
    detailCount++;
    final value = _metric(detailScope, 'entries', count, null);
    if (breakdown.length < maxBreakdownEntries) {
      breakdown.add(value);
    }
  }

  CatalogBudgetReport build() {
    int compare(CatalogBudgetMetric a, CatalogBudgetMetric b) {
      final scopeOrder = a.scope.compareTo(b.scope);
      return scopeOrder == 0 ? a.dimension.compareTo(b.dimension) : scopeOrder;
    }

    metrics.sort(compare);
    breakdown.sort(compare);
    return CatalogBudgetReport(
        scope: scope,
        metrics: metrics,
        totals: totals,
        breakdown: breakdown,
        unknownDimensions: unknown,
        omittedBreakdownEntries: detailCount - breakdown.length);
  }
}
