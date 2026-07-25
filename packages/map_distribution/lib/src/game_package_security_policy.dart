enum PackageTrustRequirement { signatureOptional, signatureRequired }

enum PackageSignatureStatus { notPresent, presentUnverified, verified }

final class GamePackageSecurityPolicy {
  const GamePackageSecurityPolicy({
    int maxArchiveBytes = maxArchiveBytesV1,
    int maxManifestBytes = maxManifestBytesV1,
    int maxPayloadEntries = maxPayloadEntriesV1,
    int maxFileBytes = maxFileBytesV1,
    int maxTotalPayloadBytes = maxTotalPayloadBytesV1,
    int maxJsonBytes = maxJsonBytesV1,
    int maxImageDimension = maxImageDimensionV1,
    int maxImagePixels = maxImagePixelsV1,
    int maxMediaHeaderBytes = maxMediaHeaderBytesV1,
    int maxJsonDepth = maxJsonDepthV1,
    int maxJsonNodes = maxJsonNodesV1,
    int maxProjectCollectionEntries = maxProjectCollectionEntriesV1,
    int maxProjectHierarchyEntries = maxProjectHierarchyEntriesV1,
    int maxProjectHierarchyDepth = maxProjectHierarchyDepthV1,
  })  : _maxArchiveBytes = maxArchiveBytes,
        _maxManifestBytes = maxManifestBytes,
        _maxPayloadEntries = maxPayloadEntries,
        _maxFileBytes = maxFileBytes,
        _maxTotalPayloadBytes = maxTotalPayloadBytes,
        _maxJsonBytes = maxJsonBytes,
        _maxImageDimension = maxImageDimension,
        _maxImagePixels = maxImagePixels,
        _maxMediaHeaderBytes = maxMediaHeaderBytes,
        _maxJsonDepth = maxJsonDepth,
        _maxJsonNodes = maxJsonNodes,
        _maxProjectCollectionEntries = maxProjectCollectionEntries,
        _maxProjectHierarchyEntries = maxProjectHierarchyEntries,
        _maxProjectHierarchyDepth = maxProjectHierarchyDepth;

  static const int maxArchiveBytesV1 = 1073741824;
  static const int maxManifestBytesV1 = 4194304;
  static const int maxPayloadEntriesV1 = 20000;
  static const int maxFileBytesV1 = 268435456;
  static const int maxTotalPayloadBytesV1 = 1073741824;
  static const int maxJsonBytesV1 = 33554432;
  static const int maxImageDimensionV1 = 8192;
  static const int maxImagePixelsV1 = 67108864;
  static const int maxMediaHeaderBytesV1 = 1048576;

  /// Defensive parser bounds for project JSON inside the normative byte quota.
  static const int maxJsonDepthV1 = 128;
  static const int maxJsonNodesV1 = 1000000;
  static const int maxProjectCollectionEntriesV1 = 100000;
  static const int maxProjectHierarchyEntriesV1 = 1024;
  static const int maxProjectHierarchyDepthV1 = 32;

  final int _maxArchiveBytes;
  final int _maxManifestBytes;
  final int _maxPayloadEntries;
  final int _maxFileBytes;
  final int _maxTotalPayloadBytes;
  final int _maxJsonBytes;
  final int _maxImageDimension;
  final int _maxImagePixels;
  final int _maxMediaHeaderBytes;
  final int _maxJsonDepth;
  final int _maxJsonNodes;
  final int _maxProjectCollectionEntries;
  final int _maxProjectHierarchyEntries;
  final int _maxProjectHierarchyDepth;

  // A platform may lower a v1 limit, but never raise it. The getters enforce
  // this in all build modes, including when assertions are disabled.
  int get maxArchiveBytes => _lower(_maxArchiveBytes, maxArchiveBytesV1);
  int get maxManifestBytes => _lower(_maxManifestBytes, maxManifestBytesV1);
  int get maxPayloadEntries => _lower(_maxPayloadEntries, maxPayloadEntriesV1);
  int get maxFileBytes => _lower(_maxFileBytes, maxFileBytesV1);
  int get maxTotalPayloadBytes =>
      _lower(_maxTotalPayloadBytes, maxTotalPayloadBytesV1);
  int get maxJsonBytes => _lower(_maxJsonBytes, maxJsonBytesV1);
  int get maxImageDimension => _lower(_maxImageDimension, maxImageDimensionV1);
  int get maxImagePixels => _lower(_maxImagePixels, maxImagePixelsV1);
  int get maxMediaHeaderBytes =>
      _lower(_maxMediaHeaderBytes, maxMediaHeaderBytesV1);
  int get maxJsonDepth => _lower(_maxJsonDepth, maxJsonDepthV1);
  int get maxJsonNodes => _lower(_maxJsonNodes, maxJsonNodesV1);
  int get maxProjectCollectionEntries => _lower(
        _maxProjectCollectionEntries,
        maxProjectCollectionEntriesV1,
      );
  int get maxProjectHierarchyEntries => _lower(
        _maxProjectHierarchyEntries,
        maxProjectHierarchyEntriesV1,
      );
  int get maxProjectHierarchyDepth => _lower(
        _maxProjectHierarchyDepth,
        maxProjectHierarchyDepthV1,
      );

  static int _lower(int requested, int normativeMaximum) =>
      requested < normativeMaximum ? requested : normativeMaximum;
}

abstract interface class GamePackageSignatureVerifier {
  bool verify({
    required String keyId,
    required List<int> preimage,
    required List<int> signature,
  });
}
