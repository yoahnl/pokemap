export 'package:map_authoring/map_authoring_resources.dart'
    show
        ResourceUsageTarget,
        ResourceUsageEntry,
        ResourceUsageRelation,
        ResourceUsageReport;

import 'package:map_authoring/map_authoring_resources.dart';

abstract interface class ResourceUsagePort {
  Future<ResourceUsageReport> analyze(
    ResourceUsageTarget target, {
    bool Function()? cancelled,
  });

  Future<bool> isCurrent(ResourceUsageReport report);
  Future<void> dispose();
}

abstract interface class ResourceUsageProvider {
  ResourceUsagePort get usages;
}

final class UnavailableResourceUsagePort implements ResourceUsagePort {
  const UnavailableResourceUsagePort();
  @override
  Future<ResourceUsageReport> analyze(
    ResourceUsageTarget target, {
    bool Function()? cancelled,
  }) async => throw StateError('L’analyse des usages est indisponible.');
  @override
  Future<bool> isCurrent(ResourceUsageReport report) async => false;
  @override
  Future<void> dispose() async {}
}

final class ResourceUsageCancelled implements Exception {
  const ResourceUsageCancelled();
}
