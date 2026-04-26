import '../models/enums.dart';
import '../models/project_manifest.dart';
import 'legacy_path_surface_view.dart';
import 'legacy_terrain_surface_view.dart';

/// Read-only inventory of legacy project surfaces.
///
/// This catalog is a transition view over the current [ProjectManifest]. It is
/// deliberately not a persisted Surface model and deliberately not a unified
/// surface hierarchy. Terrain presets and path presets still carry different
/// legacy semantics:
///
/// - terrains are keyed by [TerrainType] and weighted visual variants;
/// - paths are keyed by [PathSurfaceKind] and [TerrainPathVariant] mappings.
///
/// Keeping those lists separate gives future Surface Engine work a safe project
/// level inventory without changing JSON, Freezed contracts, editor behavior,
/// runtime rendering, or gameplay rules.
final class LegacyProjectSurfaceCatalogView {
  LegacyProjectSurfaceCatalogView({
    required List<LegacyTerrainSurfaceView> terrainSurfaces,
    required List<LegacyPathSurfaceView> pathSurfaces,
  })  : terrainSurfaces = List.unmodifiable(terrainSurfaces),
        pathSurfaces = List.unmodifiable(pathSurfaces);

  /// Legacy terrain preset views in the same order as
  /// [ProjectManifest.terrainPresets].
  final List<LegacyTerrainSurfaceView> terrainSurfaces;

  /// Legacy path preset views in the same order as
  /// [ProjectManifest.pathPresets].
  final List<LegacyPathSurfaceView> pathSurfaces;

  /// Whether the catalog contains at least one terrain surface candidate.
  bool get hasTerrainSurfaces => terrainSurfaces.isNotEmpty;

  /// Whether the catalog contains at least one path surface candidate.
  bool get hasPathSurfaces => pathSurfaces.isNotEmpty;

  /// Whether both legacy surface collections are empty.
  bool get isEmpty => terrainSurfaces.isEmpty && pathSurfaces.isEmpty;

  /// Returns the first terrain surface whose id matches [id].
  ///
  /// Legacy manifests store presets as lists and may contain duplicate ids. V0
  /// does not validate, de-duplicate, or repair those manifests; it simply
  /// returns the first match to keep lookup semantics visible and deterministic.
  LegacyTerrainSurfaceView? terrainSurfaceById(String id) {
    for (final surface in terrainSurfaces) {
      if (surface.id == id) {
        return surface;
      }
    }
    return null;
  }

  /// Returns the first path surface whose id matches [id].
  ///
  /// This lookup is intentionally scoped to [pathSurfaces]. A terrain and a
  /// path may share the same legacy id without being merged by this catalog.
  LegacyPathSurfaceView? pathSurfaceById(String id) {
    for (final surface in pathSurfaces) {
      if (surface.id == id) {
        return surface;
      }
    }
    return null;
  }

  /// Returns all terrain surfaces with [type], preserving manifest order.
  ///
  /// The returned list is unmodifiable. The catalog does not synthesize missing
  /// terrain types or apply fallback rules.
  List<LegacyTerrainSurfaceView> terrainSurfacesByType(TerrainType type) {
    return List.unmodifiable(
      terrainSurfaces.where((surface) => surface.terrainType == type),
    );
  }

  /// Returns all path surfaces with [kind], preserving manifest order.
  ///
  /// The returned list is unmodifiable. Path kind filtering remains separate
  /// from terrain type filtering until a real Surface model exists.
  List<LegacyPathSurfaceView> pathSurfacesByKind(PathSurfaceKind kind) {
    return List.unmodifiable(
      pathSurfaces.where((surface) => surface.surfaceKind == kind),
    );
  }
}

/// Creates a read-only legacy surface catalog from [manifest].
///
/// This is a pure adapter. It reads the existing preset lists, delegates each
/// preset to the Lot 4/Lot 5 adapters, and performs no validation or migration.
LegacyProjectSurfaceCatalogView createLegacyProjectSurfaceCatalogView(
  ProjectManifest manifest,
) {
  return LegacyProjectSurfaceCatalogView(
    terrainSurfaces: manifest.terrainPresets
        .map(createLegacyTerrainSurfaceView)
        .toList(growable: false),
    pathSurfaces: manifest.pathPresets
        .map(createLegacyPathSurfaceView)
        .toList(growable: false),
  );
}
