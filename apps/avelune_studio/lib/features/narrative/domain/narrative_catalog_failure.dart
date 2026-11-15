class NarrativeCatalogFailure implements Exception {
  const NarrativeCatalogFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

final class NarrativeCatalogWriteFailure extends NarrativeCatalogFailure {
  const NarrativeCatalogWriteFailure(super.message);
}
