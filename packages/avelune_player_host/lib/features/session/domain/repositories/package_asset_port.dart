import 'dart:io';

/// A file inside an installed package, already checked for path escapes.
///
/// Opaque on purpose: the domain only carries the reference, never the logic
/// that produced it.
abstract interface class PackageAssetReferencePort {
  String get packagePath;
}

/// Resolves package-relative paths to real files on disk.
///
/// The launch context needs to hand assets to the runtime, but must not depend
/// on the concrete resolver in `data/`. This port is the seam: `domain/` names
/// the capability, `data/PackageAssetResolver` implements it.
abstract interface class PackageAssetPort {
  PackageAssetReferencePort reference(String packagePath);

  Future<File> resolveFile(String packagePath);

  Future<File> resolveReference(PackageAssetReferencePort reference);
}
