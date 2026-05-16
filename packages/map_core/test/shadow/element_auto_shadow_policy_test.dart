import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('buildElementAutoShadowSuggestion', () {
    test('small square and default prop return null', () {
      expect(
        buildElementAutoShadowSuggestion(
          element: _element(id: 'small', width: 2, height: 2),
          shadowCatalog: _defaultCatalog(),
        ),
        isNull,
      );
      expect(
        buildElementAutoShadowSuggestion(
          element: _element(id: 'prop', width: 2, height: 3),
          shadowCatalog: _defaultCatalog(),
        ),
        isNull,
      );
    });

    test('wide low needs enough surface', () {
      expect(
        buildElementAutoShadowSuggestion(
          element: _element(id: 'small-wide', width: 3, height: 2),
          shadowCatalog: _defaultCatalog(),
        ),
        isNull,
      );
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(id: 'wide', width: 4, height: 2),
        shadowCatalog: _defaultCatalog(),
      );

      expect(suggestion!.kind, ElementAutoShadowSuggestionKind.wideLow);
      expect(suggestion.config.shadowProfileId, 'default-ground-wide-ellipse');
    });

    test('tall thin and building elements receive suggestions', () {
      final tall = buildElementAutoShadowSuggestion(
        element: _element(id: 'lamp', width: 1, height: 4),
        shadowCatalog: _defaultCatalog(),
      );
      final building = buildElementAutoShadowSuggestion(
        element: _element(id: 'house', width: 4, height: 3),
        shadowCatalog: _defaultCatalog(),
      );

      expect(tall!.kind, ElementAutoShadowSuggestionKind.tallThin);
      expect(tall.config.family, StaticShadowFamily.tallProp);
      expect(building!.kind, ElementAutoShadowSuggestionKind.buildingLarge);
      expect(building.config.family, StaticShadowFamily.building);
    });
  });

  group('applyElementAutoShadowPolicyToProject', () {
    test('backfill clears recognized old auto shadows without suggestion', () {
      final result = applyElementAutoShadowPolicyToProject(
        _project(
          elements: [
            _element(
              id: 'small',
              width: 2,
              height: 2,
              shadow: _oldAutoSmallSquareShadow(),
            ),
          ],
          shadowCatalog: _defaultCatalog(),
        ),
      );

      expect(result.appliedCount, 0);
      expect(result.clearedCount, 1);
      expect(result.changedCount, 1);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
      );
      expect(result.project.elements.single.shadow, isNull);
    });

    test('backfill applies eligible missing shadows', () {
      final result = applyElementAutoShadowPolicyToProject(
        _project(
          elements: [
            _element(id: 'lamp', width: 1, height: 4),
          ],
          shadowCatalog: const ProjectShadowCatalog.empty(),
        ),
      );

      expect(result.addedDefaultProfiles, isTrue);
      expect(result.appliedCount, 1);
      expect(result.clearedCount, 0);
      expect(result.changedCount, 1);
      expect(
        result.project.elements.single.shadow!.shadowProfileId,
        'default-ground-contact-blob',
      );
    });

    test('manual and disabled shadows are preserved', () {
      final manual = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'custom-ground-shadow',
      );
      final disabled = ProjectElementShadowConfig(castsShadow: false);
      final result = applyElementAutoShadowPolicyToProject(
        _project(
          elements: [
            _element(id: 'manual', width: 2, height: 2, shadow: manual),
            _element(id: 'disabled', width: 4, height: 3, shadow: disabled),
          ],
          shadowCatalog: ProjectShadowCatalog(
            profiles: [
              ...createDefaultGroundStaticShadowProfiles(),
              ProjectShadowProfile(
                id: 'custom-ground-shadow',
                name: 'Custom ground shadow',
                mode: ShadowCasterMode.ellipse,
                renderPass: ShadowRenderPass.groundStatic,
              ),
            ],
          ),
        ),
      );

      expect(result.changedCount, 0);
      expect(result.hasChanges, isFalse);
      expect(result.project.elements[0].shadow, manual);
      expect(result.project.elements[1].shadow, disabled);
    });
  });
}

ProjectManifest _project({
  required List<ProjectElementEntry> elements,
  required ProjectShadowCatalog shadowCatalog,
}) {
  return ProjectManifest(
    name: 'Auto shadow policy test',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'tileset_main',
        name: 'Main tileset',
        relativePath: 'tilesets/main.png',
      ),
    ],
    elementCategories: const <ProjectElementCategory>[
      ProjectElementCategory(id: 'decor', name: 'Decor'),
    ],
    elements: elements,
    shadowCatalog: shadowCatalog,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectShadowCatalog _defaultCatalog() {
  return ProjectShadowCatalog(
    profiles: createDefaultGroundStaticShadowProfiles(),
  );
}

ProjectElementEntry _element({
  required String id,
  required int width,
  required int height,
  ProjectElementShadowConfig? shadow,
}) {
  return ProjectElementEntry(
    id: id,
    name: id,
    tilesetId: 'tileset_main',
    categoryId: 'decor',
    frames: [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0, width: width, height: height),
      ),
    ],
    shadow: shadow,
  );
}

ProjectElementShadowConfig _oldAutoSmallSquareShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-contact-blob',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.78,
    scaleY: 0.70,
    opacity: 0.26,
    family: StaticShadowFamily.compactProp,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.96,
      footprintWidthRatio: 0.46,
      footprintHeightRatio: 0.10,
    ),
  );
}
