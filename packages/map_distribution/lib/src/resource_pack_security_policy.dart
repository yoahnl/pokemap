final class ResourcePackSecurityPolicy {
  const ResourcePackSecurityPolicy({
    int maxArchiveBytes = maxArchiveBytesV1,
    int maxTotalPayloadBytes = maxTotalPayloadBytesV1,
    int maxZipEntries = maxZipEntriesV1,
    int maxResources = maxResourcesV1,
    int maxSupports = maxSupportsV1,
    int maxManifestBytes = maxManifestBytesV1,
    int maxCatalogBytes = maxCatalogBytesV1,
    int maxFileBytes = maxFileBytesV1,
    int maxPreviewBytes = maxPreviewBytesV1,
    int maxPreviewFiles = maxPreviewFilesV1,
    int maxChunkBytes = maxChunkBytesV1,
    int maxCacheBytes = maxCacheBytesV1,
    int maxJsonDepth = maxJsonDepthV1,
    int maxJsonNodes = maxJsonNodesV1,
    int maxImageDimension = maxImageDimensionV1,
    int maxImagePixels = maxImagePixelsV1,
    int maxPublishedFiles = maxPublishedFilesV1,
    int maxHierarchyEntries = maxHierarchyEntriesV1,
    int maxHierarchyDepth = maxHierarchyDepthV1,
    int maxPublicRows = maxPublicRowsV1,
    int maxPublicResponseBytes = maxPublicResponseBytesV1,
    int maxSelectionPatchEntries = maxSelectionPatchEntriesV1,
    int maxActiveOperationsPerProject = maxActiveOperationsPerProjectV1,
    Duration maxUnreferencedAge = maxUnreferencedAgeV1,
  })  : _maxArchiveBytes = maxArchiveBytes,
        _maxTotalPayloadBytes = maxTotalPayloadBytes,
        _maxZipEntries = maxZipEntries,
        _maxResources = maxResources,
        _maxSupports = maxSupports,
        _maxManifestBytes = maxManifestBytes,
        _maxCatalogBytes = maxCatalogBytes,
        _maxFileBytes = maxFileBytes,
        _maxPreviewBytes = maxPreviewBytes,
        _maxPreviewFiles = maxPreviewFiles,
        _maxChunkBytes = maxChunkBytes,
        _maxCacheBytes = maxCacheBytes,
        _maxJsonDepth = maxJsonDepth,
        _maxJsonNodes = maxJsonNodes,
        _maxImageDimension = maxImageDimension,
        _maxImagePixels = maxImagePixels,
        _maxPublishedFiles = maxPublishedFiles,
        _maxHierarchyEntries = maxHierarchyEntries,
        _maxHierarchyDepth = maxHierarchyDepth,
        _maxPublicRows = maxPublicRows,
        _maxPublicResponseBytes = maxPublicResponseBytes,
        _maxSelectionPatchEntries = maxSelectionPatchEntries,
        _maxActiveOperationsPerProject = maxActiveOperationsPerProject,
        _maxUnreferencedAge = maxUnreferencedAge;

  static const maxArchiveBytesV1 = 536870912;
  static const maxTotalPayloadBytesV1 = 524288000;
  static const maxZipEntriesV1 = 65000;
  static const maxResourcesV1 = 100000;
  static const maxSupportsV1 = 100000;
  static const maxManifestBytesV1 = 33554432;
  static const maxCatalogBytesV1 = 134217728;
  static const maxFileBytesV1 = 268435456;
  static const maxPreviewBytesV1 = 131072;
  static const maxPreviewFilesV1 = 2048;
  static const maxChunkBytesV1 = 1048576;
  static const maxCacheBytesV1 = 2147483648;
  static const maxJsonDepthV1 = 128;
  static const maxJsonNodesV1 = 8000000;
  static const maxImageDimensionV1 = 8192;
  static const maxImagePixelsV1 = 67108864;
  static const maxPublishedFilesV1 = 65000;
  static const maxHierarchyEntriesV1 = 1024;
  static const maxHierarchyDepthV1 = 32;
  static const maxPublicRowsV1 = 200;
  static const maxPublicResponseBytesV1 = 262144;
  static const maxSelectionPatchEntriesV1 = 200;
  static const maxActiveOperationsPerProjectV1 = 1;
  static const maxUnreferencedAgeV1 = Duration(hours: 24);

  final int _maxArchiveBytes;
  final int _maxTotalPayloadBytes;
  final int _maxZipEntries;
  final int _maxResources;
  final int _maxSupports;
  final int _maxManifestBytes;
  final int _maxCatalogBytes;
  final int _maxFileBytes;
  final int _maxPreviewBytes;
  final int _maxPreviewFiles;
  final int _maxChunkBytes;
  final int _maxCacheBytes;
  final int _maxJsonDepth;
  final int _maxJsonNodes;
  final int _maxImageDimension;
  final int _maxImagePixels;
  final int _maxPublishedFiles;
  final int _maxHierarchyEntries;
  final int _maxHierarchyDepth;
  final int _maxPublicRows;
  final int _maxPublicResponseBytes;
  final int _maxSelectionPatchEntries;
  final int _maxActiveOperationsPerProject;
  final Duration _maxUnreferencedAge;

  int get maxArchiveBytes => _lower(_maxArchiveBytes, maxArchiveBytesV1);
  int get maxTotalPayloadBytes =>
      _lower(_maxTotalPayloadBytes, maxTotalPayloadBytesV1);
  int get maxZipEntries => _lower(_maxZipEntries, maxZipEntriesV1);
  int get maxResources => _lower(_maxResources, maxResourcesV1);
  int get maxSupports => _lower(_maxSupports, maxSupportsV1);
  int get maxManifestBytes => _lower(_maxManifestBytes, maxManifestBytesV1);
  int get maxCatalogBytes => _lower(_maxCatalogBytes, maxCatalogBytesV1);
  int get maxFileBytes => _lower(_maxFileBytes, maxFileBytesV1);
  int get maxPreviewBytes => _lower(_maxPreviewBytes, maxPreviewBytesV1);
  int get maxPreviewFiles => _lower(_maxPreviewFiles, maxPreviewFilesV1);
  int get maxChunkBytes => _lower(_maxChunkBytes, maxChunkBytesV1);
  int get maxCacheBytes => _lower(_maxCacheBytes, maxCacheBytesV1);
  int get maxJsonDepth => _lower(_maxJsonDepth, maxJsonDepthV1);
  int get maxJsonNodes => _lower(_maxJsonNodes, maxJsonNodesV1);
  int get maxImageDimension => _lower(_maxImageDimension, maxImageDimensionV1);
  int get maxImagePixels => _lower(_maxImagePixels, maxImagePixelsV1);
  int get maxHierarchyEntries =>
      _lower(_maxHierarchyEntries, maxHierarchyEntriesV1);
  int get maxHierarchyDepth => _lower(_maxHierarchyDepth, maxHierarchyDepthV1);
  int get maxPublishedFiles => _lower(_maxPublishedFiles, maxPublishedFilesV1);
  int get maxPublicRows => _lower(_maxPublicRows, maxPublicRowsV1);
  int get maxPublicResponseBytes =>
      _lower(_maxPublicResponseBytes, maxPublicResponseBytesV1);
  int get maxActiveOperationsPerProject =>
      _lower(_maxActiveOperationsPerProject, maxActiveOperationsPerProjectV1);
  int get maxSelectionPatchEntries =>
      _lower(_maxSelectionPatchEntries, maxSelectionPatchEntriesV1);

  Duration get maxUnreferencedAge => Duration(
        microseconds: _lower(
          _maxUnreferencedAge.inMicroseconds,
          maxUnreferencedAgeV1.inMicroseconds,
        ),
      );

  static int _lower(int requested, int maximum) {
    if (requested < 1) {
      throw ArgumentError.value(requested, 'limit', 'must be positive');
    }
    return requested < maximum ? requested : maximum;
  }
}
