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
        'visible active element shadow with ellipse groundStatic creates one instruction',
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
      expect(instruction.shape, ShadowRuntimeShapeKind.ellipse);
      expect(instruction.width, closeTo(36, 0.0001));
      expect(instruction.height, closeTo(7.5, 0.0001));
      expect(instruction.worldLeft, closeTo(88, 0.0001));
      expect(instruction.worldTop, closeTo(186.25, 0.0001));
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
          ShadowRuntimeShapeKind.contactBlob);
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
          collection.groundStatic.single.shape, ShadowRuntimeShapeKind.ellipse);
      expect(collection.groundStatic.single.width, closeTo(36, 0.0001));
    });

    test('custom placed override applies offset scale and opacity', () {
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
      expect(instruction.width, closeTo(60, 0.0001));
      expect(instruction.height, closeTo(45, 0.0001));
      expect(instruction.worldLeft, closeTo(75, 0.0001));
      expect(instruction.worldTop, closeTo(164.5, 0.0001));
      expect(instruction.opacity, 0.2);
    });

    test(
        'custom placed override with shadowProfileId uses the override profile',
        () {
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
          ShadowRuntimeShapeKind.contactBlob);
      expect(collection.groundStatic.single.width, closeTo(30, 0.0001));
    });

    test(
        'custom placed override without shadowProfileId keeps the element profile',
        () {
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
          collection.groundStatic.single.shape, ShadowRuntimeShapeKind.ellipse);
      expect(collection.groundStatic.single.worldLeft, closeTo(89, 0.0001));
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
}) {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: profileId,
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
