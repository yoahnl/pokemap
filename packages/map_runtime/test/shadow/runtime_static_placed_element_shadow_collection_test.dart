import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/runtime_static_placed_element_shadow_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
import 'package:map_runtime/src/shadow/static_placed_element_shadow_runtime_resolver.dart';

void main() {
  group('RuntimeStaticPlacedElementShadowSource', () {
    test('uses value equality and matching hashCode', () {
      final a = _source();
      final b = _source();
      final c = _source(id: 'other');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('rejects blank ids', () {
      expect(
        () => _source(id: ''),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _source(id: '   '),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects blank element ids', () {
      expect(
        () => _source(elementId: ''),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _source(elementId: '   '),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('buildRuntimeStaticPlacedElementShadowCollection', () {
    test(
        'visible active element shadow with ellipse groundStatic creates one projected instruction',
        () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(),
        ],
      );

      expect(collection.length, 1);
      expect(collection.actorContact, isEmpty);
      expect(collection.groundStatic, hasLength(1));
      final instruction = collection.groundStatic.single;
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
      _expectProjectedPolygon(instruction);
    });

    test('contactBlob groundStatic profile creates a groundStatic instruction',
        () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(elementShadow: _elementShadow(profileId: 'blob_ground')),
        ],
      );

      expect(collection.groundStatic, hasLength(1));
      expect(collection.groundStatic.single.renderPass,
          ShadowRenderPass.groundStatic);
      expect(collection.groundStatic.single.shape,
          ShadowRuntimeShapeKind.projectedPolygon);
      expect(collection.groundStatic.single.polygonPoints, hasLength(4));
    });

    test('invisible source creates no instruction', () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(isVisible: false),
        ],
      );

      expect(collection, ShadowRuntimeInstructionCollection());
    });

    test('null element shadow creates no instruction', () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(elementShadow: null),
        ],
      );

      expect(collection.isEmpty, isTrue);
    });

    test('castsShadow false creates no instruction', () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(
            elementShadow: ProjectElementShadowConfig(castsShadow: false),
          ),
        ],
      );

      expect(collection.isEmpty, isTrue);
    });

    test('disabled placed override creates no instruction', () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(
            placedOverride: MapPlacedElementShadowOverride(
              mode: ShadowOverrideMode.disabled,
            ),
          ),
        ],
      );

      expect(collection.isEmpty, isTrue);
    });

    test('inherit placed override keeps the element profile', () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(
            placedOverride: MapPlacedElementShadowOverride(),
          ),
        ],
      );

      expect(collection.groundStatic, hasLength(1));
      expect(
        collection.groundStatic.single.shape,
        ShadowRuntimeShapeKind.projectedPolygon,
      );
      expect(collection.groundStatic.single.polygonPoints, hasLength(4));
    });

    test('custom placed override applies offset scale and opacity', () {
      final baseline = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(elementShadow: _elementShadow(profileId: 'plain_ellipse')),
        ],
      ).groundStatic.single;
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(
            elementShadow: _elementShadow(profileId: 'plain_ellipse'),
            placedOverride: MapPlacedElementShadowOverride(
              mode: ShadowOverrideMode.custom,
              offsetX: 5,
              offsetY: 7,
              scaleX: 2,
              scaleY: 3,
              opacity: 0.2,
            ),
          ),
        ],
      );

      final instruction = collection.groundStatic.single;
      _expectProjectedPolygon(instruction);
      _expectDifferentPolygon(instruction, baseline);
      expect(instruction.opacity, 0.2);
    });

    test(
        'custom placed override with shadowProfileId uses the override profile',
        () {
      final elementProfile = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(elementShadow: _elementShadow(profileId: 'plain_ellipse')),
        ],
      ).groundStatic.single;
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(
            elementShadow: _elementShadow(profileId: 'plain_ellipse'),
            placedOverride: MapPlacedElementShadowOverride(
              mode: ShadowOverrideMode.custom,
              shadowProfileId: 'blob_ground',
            ),
          ),
        ],
      );

      expect(collection.groundStatic.single.shape,
          ShadowRuntimeShapeKind.projectedPolygon);
      _expectDifferentPolygon(collection.groundStatic.single, elementProfile);
    });

    test(
        'custom placed override without shadowProfileId keeps the element profile',
        () {
      final inheritedProfile = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(
            elementShadow: _elementShadow(profileId: 'plain_ellipse'),
            placedOverride: MapPlacedElementShadowOverride(
              mode: ShadowOverrideMode.custom,
            ),
          ),
        ],
      ).groundStatic.single;
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(
            elementShadow: _elementShadow(profileId: 'plain_ellipse'),
            placedOverride: MapPlacedElementShadowOverride(
              mode: ShadowOverrideMode.custom,
              offsetX: 4,
            ),
          ),
        ],
      );

      expect(
        collection.groundStatic.single.shape,
        ShadowRuntimeShapeKind.projectedPolygon,
      );
      _expectDifferentPolygon(collection.groundStatic.single, inheritedProfile);
    });

    test('element shadow footprint is transmitted to runtime geometry', () {
      final baseline = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(),
        ],
      ).groundStatic.single;
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(
            elementShadow: _elementShadow(
              footprint: StaticShadowFootprintConfig(
                anchorXRatio: 0.25,
                footprintWidthRatio: 0.5,
              ),
            ),
          ),
        ],
      );

      final instruction = collection.groundStatic.single;
      _expectProjectedPolygon(instruction);
      _expectDifferentPolygon(instruction, baseline);
    });

    test('placed override footprint is transmitted to runtime geometry', () {
      final elementOnly = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(
            elementShadow: _elementShadow(
              footprint: StaticShadowFootprintConfig(
                anchorXRatio: 0.25,
                footprintWidthRatio: 0.5,
              ),
            ),
          ),
        ],
      ).groundStatic.single;
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(
            elementShadow: _elementShadow(
              footprint: StaticShadowFootprintConfig(
                anchorXRatio: 0.25,
                footprintWidthRatio: 0.5,
              ),
            ),
            placedOverride: MapPlacedElementShadowOverride(
              mode: ShadowOverrideMode.custom,
              footprint: StaticShadowFootprintConfig(
                anchorYRatio: 0.5,
                footprintHeightRatio: 0.125,
              ),
            ),
          ),
        ],
      );

      final instruction = collection.groundStatic.single;
      _expectProjectedPolygon(instruction);
      _expectDifferentPolygon(instruction, elementOnly);
    });

    test('element shadow family is transmitted to runtime projection', () {
      final footprint = StaticShadowFootprintConfig(
        footprintWidthRatio: 0.25,
        footprintHeightRatio: 0.08,
      );
      final tallProp = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(
            elementShadow: _elementShadow(
              family: StaticShadowFamily.tallProp,
              footprint: footprint,
            ),
          ),
        ],
      ).groundStatic.single;
      final building = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(
            elementShadow: _elementShadow(
              family: StaticShadowFamily.building,
              footprint: footprint,
            ),
          ),
        ],
      ).groundStatic.single;

      expect(tallProp.width, lessThan(building.width));
      _expectDifferentPolygon(tallProp, building);
    });

    test('element shadow building family emits a short contact ledge', () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(
            metrics: _metrics(
              worldLeft: 160,
              worldTop: 96,
              visualWidth: 192,
              visualHeight: 224,
            ),
            elementShadow: _elementShadow(
              family: StaticShadowFamily.building,
              footprint: StaticShadowFootprintConfig(
                anchorXRatio: 0.5,
                anchorYRatio: 0.92,
                footprintWidthRatio: 0.6,
                footprintHeightRatio: 0.08,
              ),
            ),
          ),
        ],
      );

      final instruction = collection.groundStatic.single;
      _expectBuildingContactLedge(instruction);
      expect(instruction.height, greaterThan(13));
      expect(instruction.height, lessThan(15));
      expect(instruction.width, greaterThan(198));
      expect(instruction.width, lessThan(200));
    });

    test('placed override family wins over element shadow family', () {
      final footprint = StaticShadowFootprintConfig(
        footprintWidthRatio: 0.25,
        footprintHeightRatio: 0.08,
      );
      final overrideBuilding = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(
            elementShadow: _elementShadow(
              family: StaticShadowFamily.tallProp,
              footprint: footprint,
            ),
            placedOverride: MapPlacedElementShadowOverride(
              mode: ShadowOverrideMode.custom,
              family: StaticShadowFamily.building,
            ),
          ),
        ],
      ).groundStatic.single;
      final building = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(
            elementShadow: _elementShadow(
              family: StaticShadowFamily.building,
              footprint: footprint,
            ),
          ),
        ],
      ).groundStatic.single;

      expect(overrideBuilding.width, closeTo(building.width, 0.000001));
      expect(overrideBuilding.height, closeTo(building.height, 0.000001));
    });

    test('placed override building family emits a short contact ledge', () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(
            elementShadow: _elementShadow(
              family: StaticShadowFamily.tallProp,
              footprint: StaticShadowFootprintConfig(
                footprintWidthRatio: 0.25,
                footprintHeightRatio: 0.08,
              ),
            ),
            placedOverride: MapPlacedElementShadowOverride(
              mode: ShadowOverrideMode.custom,
              family: StaticShadowFamily.building,
            ),
          ),
        ],
      );

      _expectBuildingContactLedge(collection.groundStatic.single);
    });

    test('none profile creates no instruction', () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(elementShadow: _elementShadow(profileId: 'none_profile')),
        ],
      );

      expect(collection.isEmpty, isTrue);
    });

    test('missing profile creates no instruction in V0', () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(elementShadow: _elementShadow(profileId: 'missing_profile')),
        ],
      );

      expect(collection.isEmpty, isTrue);
    });

    test('opacity zero instruction is retained', () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(elementShadow: _elementShadow(profileId: 'zero_opacity')),
        ],
      );

      expect(collection.groundStatic, hasLength(1));
      expect(collection.groundStatic.single.opacity, 0);
    });

    test('multiple sources preserve order', () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(id: 'first', metrics: _metrics(worldLeft: 80)),
          _source(id: 'second', metrics: _metrics(worldLeft: 200)),
        ],
      );

      expect(collection.groundStatic, hasLength(2));
      expect(
        collection.groundStatic[0].worldLeft,
        lessThan(collection.groundStatic[1].worldLeft),
      );
    });

    test('identical sources are not deduplicated', () {
      final source = _source();

      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          source,
          source,
        ],
      );

      expect(collection.groundStatic, hasLength(2));
      expect(collection.groundStatic[0], collection.groundStatic[1]);
    });

    test('actorContact profile is rejected by the static resolver', () {
      expect(
        () => buildRuntimeStaticPlacedElementShadowCollection(
          catalog: _catalog(),
          sources: [
            _source(elementShadow: _elementShadow(profileId: 'actor_contact')),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('returned collection exposes immutable lists', () {
      final collection = buildRuntimeStaticPlacedElementShadowCollection(
        catalog: _catalog(),
        sources: [
          _source(),
        ],
      );

      expect(
        () => collection.instructions.add(collection.instructions.single),
        throwsUnsupportedError,
      );
    });
  });
}

RuntimeStaticPlacedElementShadowSource _source({
  String id = 'tree-instance',
  String elementId = 'tree',
  Object? elementShadow = _defaultElementShadow,
  MapPlacedElementShadowOverride? placedOverride,
  StaticPlacedElementShadowRuntimeMetrics? metrics,
  bool isVisible = true,
}) {
  final resolvedElementShadow = identical(
    elementShadow,
    _defaultElementShadow,
  )
      ? _elementShadow()
      : elementShadow as ProjectElementShadowConfig?;
  return RuntimeStaticPlacedElementShadowSource(
    id: id,
    elementId: elementId,
    elementShadow: resolvedElementShadow,
    placedOverride: placedOverride,
    metrics: metrics ?? _metrics(),
    isVisible: isVisible,
  );
}

const Object _defaultElementShadow = Object();

ProjectElementShadowConfig _elementShadow({
  String profileId = 'ellipse_ground',
  StaticShadowFootprintConfig? footprint,
  StaticShadowFamily? family,
}) {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: profileId,
    footprint: footprint,
    family: family,
  );
}

StaticPlacedElementShadowRuntimeMetrics _metrics({
  double worldLeft = 80,
  double worldTop = 120,
  double visualWidth = 40,
  double visualHeight = 60,
}) {
  return StaticPlacedElementShadowRuntimeMetrics(
    worldLeft: worldLeft,
    worldTop: worldTop,
    visualWidth: visualWidth,
    visualHeight: visualHeight,
  );
}

ProjectShadowCatalog _catalog() {
  return ProjectShadowCatalog(
    profiles: [
      _profile(
        id: 'ellipse_ground',
        mode: ShadowCasterMode.ellipse,
        renderPass: ShadowRenderPass.groundStatic,
        offsetX: 6,
        offsetY: 10,
        scaleX: 1.2,
        scaleY: 0.5,
      ),
      _profile(
        id: 'plain_ellipse',
        mode: ShadowCasterMode.ellipse,
        renderPass: ShadowRenderPass.groundStatic,
      ),
      _profile(
        id: 'blob_ground',
        mode: ShadowCasterMode.contactBlob,
        renderPass: ShadowRenderPass.groundStatic,
        scaleX: 0.5,
      ),
      _profile(
        id: 'none_profile',
        mode: ShadowCasterMode.none,
        renderPass: ShadowRenderPass.groundStatic,
      ),
      _profile(
        id: 'zero_opacity',
        mode: ShadowCasterMode.ellipse,
        renderPass: ShadowRenderPass.groundStatic,
        opacity: 0,
      ),
      _profile(
        id: 'actor_contact',
        mode: ShadowCasterMode.contactBlob,
        renderPass: ShadowRenderPass.actorContact,
      ),
    ],
  );
}

void _expectProjectedPolygon(ShadowRuntimeRenderInstruction instruction) {
  expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
  expect(instruction.polygonPoints, hasLength(4));
  expect(instruction.width, greaterThan(0));
  expect(instruction.height, greaterThan(0));
  for (final point in instruction.polygonPoints) {
    expect(point.worldX, greaterThanOrEqualTo(instruction.worldLeft));
    expect(
      point.worldX,
      lessThanOrEqualTo(instruction.worldLeft + instruction.width),
    );
    expect(point.worldY, greaterThanOrEqualTo(instruction.worldTop));
    expect(
      point.worldY,
      lessThanOrEqualTo(instruction.worldTop + instruction.height),
    );
  }
}

void _expectBuildingContactLedge(ShadowRuntimeRenderInstruction instruction) {
  _expectProjectedPolygon(instruction);
  final points = instruction.polygonPoints;
  expect(points[0].worldY, closeTo(points[1].worldY, 0.000001));
  expect(points[2].worldY, closeTo(points[3].worldY, 0.000001));
  expect(points[2].worldY, greaterThan(points[0].worldY));
  expect(points[3].worldY, greaterThan(points[1].worldY));
}

void _expectDifferentPolygon(
  ShadowRuntimeRenderInstruction actual,
  ShadowRuntimeRenderInstruction baseline,
) {
  expect(actual.polygonPoints, hasLength(baseline.polygonPoints.length));
  var hasDifferentPoint = false;
  for (var i = 0; i < actual.polygonPoints.length; i += 1) {
    final actualPoint = actual.polygonPoints[i];
    final baselinePoint = baseline.polygonPoints[i];
    if (actualPoint.worldX != baselinePoint.worldX ||
        actualPoint.worldY != baselinePoint.worldY) {
      hasDifferentPoint = true;
    }
  }
  expect(hasDifferentPoint, isTrue);
}

ProjectShadowProfile _profile({
  required String id,
  required ShadowCasterMode mode,
  required ShadowRenderPass renderPass,
  double offsetX = 0,
  double offsetY = 0,
  double scaleX = 1,
  double scaleY = 1,
  double opacity = 0.35,
}) {
  return ProjectShadowProfile(
    id: id,
    name: id,
    mode: mode,
    renderPass: renderPass,
    offsetX: offsetX,
    offsetY: offsetY,
    scaleX: scaleX,
    scaleY: scaleY,
    opacity: opacity,
  );
}
