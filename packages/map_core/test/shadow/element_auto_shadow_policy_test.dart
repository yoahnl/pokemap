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

    test('Selbrume lamp proportions receive calibrated tall thin config', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(id: 'lampadaire', width: 3, height: 5),
        shadowCatalog: _defaultCatalog(),
      );

      expect(suggestion!.kind, ElementAutoShadowSuggestionKind.tallThin);
      _expectConfig(
        suggestion.config,
        profileId: 'default-ground-contact-blob',
        scaleX: 0.80,
        scaleY: 0.55,
        opacity: 0.30,
        family: StaticShadowFamily.tallProp,
        anchorXRatio: 0.5,
        anchorYRatio: 1.0,
        footprintWidthRatio: 0.28,
        footprintHeightRatio: 0.05,
      );
    });

    test('Selbrume wide barriers stay wide low instead of building', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(id: 'barriere_pierre', width: 13, height: 6),
        shadowCatalog: _defaultCatalog(),
      );

      expect(suggestion!.kind, ElementAutoShadowSuggestionKind.wideLow);
      _expectConfig(
        suggestion.config,
        profileId: 'default-ground-wide-ellipse',
        scaleX: 0.74,
        scaleY: 0.50,
        opacity: 0.28,
        family: StaticShadowFamily.compactProp,
        anchorXRatio: 0.5,
        anchorYRatio: 0.98,
        footprintWidthRatio: 0.58,
        footprintHeightRatio: 0.06,
      );
    });

    test('Selbrume houses receive calibrated building config', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(id: 'maison', width: 6, height: 7),
        shadowCatalog: _defaultCatalog(),
      );

      expect(suggestion!.kind, ElementAutoShadowSuggestionKind.buildingLarge);
      _expectConfig(
        suggestion.config,
        profileId: 'default-ground-wide-ellipse',
        scaleX: 0.72,
        scaleY: 0.48,
        opacity: 0.32,
        family: StaticShadowFamily.building,
        anchorXRatio: 0.5,
        anchorYRatio: 0.98,
        footprintWidthRatio: 0.60,
        footprintHeightRatio: 0.06,
      );
    });

    test(
        'Shadow-54 building auto config projects far less area than legacy broad',
        () {
      final legacy = _projectedAreaForShadow(
        _legacyBroadSelbrumeShadow(family: StaticShadowFamily.building),
        visualWidth: 192,
        visualHeight: 224,
        projectionSpec: _legacyBuildingProjectionSpec(),
      );
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(id: 'maison', width: 6, height: 7),
        shadowCatalog: _defaultCatalog(),
      )!;
      final v1 = _projectedAreaForShadow(
        suggestion.config,
        visualWidth: 192,
        visualHeight: 224,
      );

      expect(v1, lessThan(legacy * 0.30));
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

    test('backfill replaces broad legacy Selbrume shadow without family', () {
      final result = applyElementAutoShadowPolicyToProject(
        _project(
          elements: [
            _element(
              id: 'lampadaire',
              width: 3,
              height: 5,
              shadow: _legacyBroadSelbrumeShadow(),
            ),
          ],
          shadowCatalog: _defaultCatalog(),
        ),
      );

      expect(result.appliedCount, 1);
      expect(result.changedCount, 1);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.appliedGeneric,
      );
      _expectConfig(
        result.project.elements.single.shadow!,
        profileId: 'default-ground-contact-blob',
        scaleX: 0.80,
        scaleY: 0.55,
        opacity: 0.30,
        family: StaticShadowFamily.tallProp,
        anchorXRatio: 0.5,
        anchorYRatio: 1.0,
        footprintWidthRatio: 0.28,
        footprintHeightRatio: 0.05,
      );
    });

    test('backfill replaces broad legacy Selbrume building shadow', () {
      final result = applyElementAutoShadowPolicyToProject(
        _project(
          elements: [
            _element(
              id: 'maison',
              width: 6,
              height: 7,
              shadow: _legacyBroadSelbrumeShadow(
                family: StaticShadowFamily.building,
              ),
            ),
          ],
          shadowCatalog: _defaultCatalog(),
        ),
      );

      expect(result.appliedCount, 1);
      expect(result.changedCount, 1);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.appliedGeneric,
      );
      _expectConfig(
        result.project.elements.single.shadow!,
        profileId: 'default-ground-wide-ellipse',
        scaleX: 0.72,
        scaleY: 0.48,
        opacity: 0.32,
        family: StaticShadowFamily.building,
        anchorXRatio: 0.5,
        anchorYRatio: 0.98,
        footprintWidthRatio: 0.60,
        footprintHeightRatio: 0.06,
      );
    });

    test('backfill upgrades Shadow-53 auto shadows to Shadow-54 tuning', () {
      final result = applyElementAutoShadowPolicyToProject(
        _project(
          elements: [
            _element(
              id: 'lampadaire',
              width: 3,
              height: 5,
              shadow: _shadow53TallThinShadow(),
            ),
            _element(
              id: 'maison',
              width: 6,
              height: 7,
              shadow: _shadow53BuildingLargeShadow(),
            ),
            _element(
              id: 'barriere_pierre',
              width: 13,
              height: 6,
              shadow: _shadow53WideLowShadow(),
            ),
          ],
          shadowCatalog: _defaultCatalog(),
        ),
      );

      expect(result.appliedCount, 3);
      expect(result.changedCount, 3);
      expect(
        result.entries.map((entry) => entry.status),
        everyElement(ElementAutoShadowBackfillStatus.appliedGeneric),
      );
      expect(result.project.elements[0].shadow!.opacity, 0.30);
      expect(result.project.elements[1].shadow!.opacity, 0.32);
      expect(result.project.elements[2].shadow!.opacity, 0.28);
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

ProjectElementShadowConfig _legacyBroadSelbrumeShadow({
  StaticShadowFamily? family,
}) {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-wide-ellipse',
    offsetX: 0,
    offsetY: 0,
    scaleX: 1,
    scaleY: 0.85,
    opacity: 0.30,
    family: family,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.92,
      footprintWidthRatio: 0.82,
      footprintHeightRatio: 0.12,
    ),
  );
}

ProjectElementShadowConfig _shadow53TallThinShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-contact-blob',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.80,
    scaleY: 0.55,
    opacity: 0.20,
    family: StaticShadowFamily.tallProp,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 1.0,
      footprintWidthRatio: 0.28,
      footprintHeightRatio: 0.05,
    ),
  );
}

ProjectElementShadowConfig _shadow53BuildingLargeShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-wide-ellipse',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.72,
    scaleY: 0.48,
    opacity: 0.20,
    family: StaticShadowFamily.building,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.98,
      footprintWidthRatio: 0.60,
      footprintHeightRatio: 0.06,
    ),
  );
}

ProjectElementShadowConfig _shadow53WideLowShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-wide-ellipse',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.74,
    scaleY: 0.50,
    opacity: 0.20,
    family: StaticShadowFamily.compactProp,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.98,
      footprintWidthRatio: 0.58,
      footprintHeightRatio: 0.06,
    ),
  );
}

void _expectConfig(
  ProjectElementShadowConfig config, {
  required String profileId,
  required double scaleX,
  required double scaleY,
  required double opacity,
  required StaticShadowFamily family,
  required double anchorXRatio,
  required double anchorYRatio,
  required double footprintWidthRatio,
  required double footprintHeightRatio,
}) {
  expect(config.castsShadow, isTrue);
  expect(config.shadowProfileId, profileId);
  expect(config.offsetX, 0);
  expect(config.offsetY, 0);
  expect(config.scaleX, closeTo(scaleX, 0.0000001));
  expect(config.scaleY, closeTo(scaleY, 0.0000001));
  expect(config.opacity, closeTo(opacity, 0.0000001));
  expect(config.family, family);
  expect(config.footprint!.anchorXRatio, closeTo(anchorXRatio, 0.0000001));
  expect(config.footprint!.anchorYRatio, closeTo(anchorYRatio, 0.0000001));
  expect(
    config.footprint!.footprintWidthRatio,
    closeTo(footprintWidthRatio, 0.0000001),
  );
  expect(
    config.footprint!.footprintHeightRatio,
    closeTo(footprintHeightRatio, 0.0000001),
  );
}

double _projectedAreaForShadow(
  ProjectElementShadowConfig shadow, {
  required double visualWidth,
  required double visualHeight,
  StaticShadowProjectionSpec? projectionSpec,
}) {
  final metrics = StaticShadowVisualMetrics(
    left: 0,
    top: 0,
    visualWidth: visualWidth,
    visualHeight: visualHeight,
  );
  final geometry = resolveStaticShadowGeometry(
    metrics: metrics,
    shadowConfig: ResolvedShadowConfig(
      shadowProfileId: shadow.shadowProfileId!,
      mode: ShadowCasterMode.ellipse,
      renderPass: ShadowRenderPass.groundStatic,
      offsetX: shadow.offsetX ?? 0,
      offsetY: shadow.offsetY ?? 0,
      scaleX: shadow.scaleX ?? 1,
      scaleY: shadow.scaleY ?? 1,
      opacity: shadow.opacity ?? 0.35,
      colorHexRgb: '000000',
      softnessMode: ShadowSoftnessMode.hardEdge,
    ),
    elementFootprint: shadow.footprint,
  );
  final projected = resolveProjectedStaticShadowGeometry(
    baseGeometry: geometry,
    metrics: metrics,
    projectionSpec: projectionSpec ??
        resolveStaticShadowFamilyProjectionSpec(
          family: shadow.family ?? StaticShadowFamily.genericProjection,
        ),
  );
  return _projectedPolygonArea(projected.points);
}

StaticShadowProjectionSpec _legacyBuildingProjectionSpec() {
  return StaticShadowProjectionSpec(
    directionX: defaultStaticShadowProjectionDirectionX,
    directionY: defaultStaticShadowProjectionDirectionY,
    lengthRatio: 0.1984,
    nearWidthMultiplier: 0.7176,
    farWidthMultiplier: 0.7316,
  );
}

double _projectedPolygonArea(List<ProjectedStaticShadowPoint> points) {
  var area = 0.0;
  for (var index = 0; index < points.length; index += 1) {
    final current = points[index];
    final next = points[(index + 1) % points.length];
    area += current.x * next.y - next.x * current.y;
  }
  return area.abs() / 2;
}
