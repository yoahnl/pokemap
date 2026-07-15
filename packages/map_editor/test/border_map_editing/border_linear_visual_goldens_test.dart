import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../fixtures/border/linear_border_visual_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('synthetic primitive metrics match their exact opaque pixels', () {
    final masonry = MasonryVisualGoldenFixture();
    final stone = masonry.primitives.first.publishedMetrics;
    expect(
      decodeBorderRleMask(
        stone.occupancyMaskRle,
        expectedLength: stone.pixelSize.width * stone.pixelSize.height,
      ),
      <bool>[
        for (var y = 0; y < 10; y += 1)
          for (var x = 0; x < 12; x += 1)
            (y >= 2 && y <= 8) || (y == 1 && x >= 1 && x <= 10),
      ],
    );
    expect(
      stone.opaqueBounds,
      BorderPixelRect(x: 0, y: 1, width: 12, height: 8),
    );

    final fence = OpenFenceVisualGoldenFixture();
    final post = fence.primitives.first.publishedMetrics;
    expect(
      decodeBorderRleMask(
        post.occupancyMaskRle,
        expectedLength: post.pixelSize.width * post.pixelSize.height,
      ),
      <bool>[
        for (var y = 0; y < 16; y += 1)
          for (var x = 0; x < 8; x += 1)
            (y >= 2 && x >= 1 && x <= 6) || (y == 1 && x >= 2 && x <= 5),
      ],
    );
    expect(
      post.opaqueBounds,
      BorderPixelRect(x: 1, y: 1, width: 6, height: 15),
    );

    final rail = fence.primitives.last.publishedMetrics;
    expect(
      decodeBorderRleMask(
        rail.occupancyMaskRle,
        expectedLength: rail.pixelSize.width * rail.pixelSize.height,
      ),
      everyElement(isTrue),
    );
    expect(
      rail.opaqueBounds,
      BorderPixelRect(x: 0, y: 0, width: 16, height: 6),
    );
  });

  group('strict masonry visual evidence', () {
    late MasonryVisualGoldenFixture fixture;
    late LinearBorderVisualRenderer renderer;
    var images = <String, ui.Image?>{};

    setUp(() async {
      fixture = MasonryVisualGoldenFixture();
      renderer = LinearBorderVisualRenderer(project: fixture.project);
      images = await fixture.loadSyntheticImages();
    });

    tearDown(() {
      for (final image in images.values.whereType<ui.Image>()) {
        image.dispose();
      }
    });

    test('applied strict masonry uses native solver materialization', () async {
      final applied = fixture.resolveFeature(
        geometry: fixture.appliedGeometry,
        seed: 31415,
      );
      _expectNativeOpaqueBounds(
        applied.materialization!,
        fixture.primitives,
      );
      final image = await renderer.render(
        map: fixture.mapWithFeature(applied),
        images: images,
      );

      await expectLater(
        image,
        matchesGoldenFile('goldens/strict_masonry_applied.png'),
      );
      image.dispose();
    });

    test('strict masonry saved and transient preview match before-after golden',
        () async {
      final saved = fixture.resolveFeature(
        geometry: fixture.appliedGeometry,
        seed: 31415,
      );
      final proposed = fixture.feature(
        geometry: fixture.previewGeometry,
        seed: 31416,
      );
      final result = fixture.resolve(proposed);
      expect(result.canApply, isTrue, reason: _diagnostics(result));
      expect(result.materialization, isNot(saved.materialization));
      _expectNativeOpaqueBounds(result.materialization!, fixture.primitives);
      final map = fixture.mapWithFeature(saved);
      final preview = linearGoldenPreview(
        projectIdentity: fixture,
        map: map,
        layerId: MasonryVisualGoldenFixture.layerId,
        featureId: MasonryVisualGoldenFixture.featureId,
        proposedFeature: proposed,
        result: result,
        variationOrdinal: 1,
      );
      final image = await renderer.renderBeforeAfter(
        map: map,
        preview: preview,
        images: images,
      );

      await expectLater(
        image,
        matchesGoldenFile('goldens/strict_masonry_before_after_preview.png'),
      );
      image.dispose();
    });

    test('strict masonry real endpoint diagnostics match overlay golden',
        () async {
      final saved = fixture.resolveFeature(
        geometry: fixture.appliedGeometry,
        seed: 31415,
      );
      final proposed = fixture.feature(
        geometry: fixture.appliedGeometry,
        seed: 31415,
      );
      final result = fixture.resolve(proposed);
      expect(result.canApply, isTrue, reason: _diagnostics(result));
      expect(
        result.diagnostics.map((item) => item.code),
        contains('border.resolution.masonry_end_finish_missing'),
      );
      expect(
        result.diagnostics
            .where((item) =>
                item.code == 'border.resolution.masonry_end_finish_missing')
            .every((item) => item.cell != null),
        isTrue,
      );
      final map = fixture.mapWithFeature(saved);
      final preview = linearGoldenPreview(
        projectIdentity: fixture,
        map: map,
        layerId: MasonryVisualGoldenFixture.layerId,
        featureId: MasonryVisualGoldenFixture.featureId,
        proposedFeature: proposed,
        result: result,
        variationOrdinal: 0,
      );
      final image = await renderer.render(
        map: map,
        images: images,
        preview: preview,
        diagnosticPalette: linearGoldenDiagnosticPalette,
      );

      await expectLater(
        image,
        matchesGoldenFile('goldens/strict_masonry_diagnostics.png'),
      );
      image.dispose();
    });
  });

  group('open fence visual evidence', () {
    late OpenFenceVisualGoldenFixture fixture;
    late LinearBorderVisualRenderer renderer;
    var images = <String, ui.Image?>{};

    setUp(() async {
      fixture = OpenFenceVisualGoldenFixture();
      renderer = LinearBorderVisualRenderer(project: fixture.project);
      images = await fixture.loadSyntheticImages();
    });

    tearDown(() {
      for (final image in images.values.whereType<ui.Image>()) {
        image.dispose();
      }
    });

    test('applied open fence preserves its gap and paints rails behind posts',
        () async {
      final applied = fixture.resolveFeature(
        geometry: fixture.appliedGeometry,
        seed: 27182,
      );
      final materialization = applied.materialization!;
      _expectNativeOpaqueBounds(materialization, fixture.primitives);
      expect(
        materialization.placements.map((item) => item.anchorCell.x),
        isNot(contains(anyOf(8, 9, 10))),
        reason: 'The independent strokes must preserve a visible opening.',
      );
      _expectRailsBeforeOverlappingPosts(materialization);
      final image = await renderer.render(
        map: fixture.mapWithFeature(applied),
        images: images,
      );

      await expectLater(
        image,
        matchesGoldenFile('goldens/open_fence_applied.png'),
      );
      image.dispose();
    });

    test('open fence saved and transient preview match before-after golden',
        () async {
      final saved = fixture.resolveFeature(
        geometry: fixture.appliedGeometry,
        seed: 27182,
      );
      final proposed = fixture.feature(
        geometry: fixture.previewGeometry,
        seed: 27182,
      );
      final result = fixture.resolve(proposed);
      expect(result.canApply, isTrue, reason: _diagnostics(result));
      _expectNativeOpaqueBounds(result.materialization!, fixture.primitives);
      _expectRailsBeforeOverlappingPosts(result.materialization!);
      final map = fixture.mapWithFeature(saved);
      final preview = linearGoldenPreview(
        projectIdentity: fixture,
        map: map,
        layerId: OpenFenceVisualGoldenFixture.layerId,
        featureId: OpenFenceVisualGoldenFixture.featureId,
        proposedFeature: proposed,
        result: result,
        variationOrdinal: 1,
      );
      final image = await renderer.renderBeforeAfter(
        map: map,
        preview: preview,
        images: images,
      );

      await expectLater(
        image,
        matchesGoldenFile('goldens/open_fence_before_after_preview.png'),
      );
      image.dispose();
    });

    test('open fence real orientation diagnostics match overlay golden',
        () async {
      final saved = fixture.resolveFeature(
        geometry: fixture.appliedGeometry,
        seed: 27182,
      );
      final proposed = fixture.feature(
        geometry: fixture.diagnosticGeometry,
        seed: 27182,
      );
      final result = fixture.resolve(proposed);
      expect(result.canApply, isFalse);
      expect(result.materialization, isNull);
      expect(
        result.diagnostics.map((item) => item.code),
        everyElement('border.resolution.orientation_unavailable'),
      );
      expect(result.diagnostics.every((item) => item.cell != null), isTrue);
      final map = fixture.mapWithFeature(saved);
      final preview = linearGoldenPreview(
        projectIdentity: fixture,
        map: map,
        layerId: OpenFenceVisualGoldenFixture.layerId,
        featureId: OpenFenceVisualGoldenFixture.featureId,
        proposedFeature: proposed,
        result: result,
        variationOrdinal: 0,
      );
      final image = await renderer.render(
        map: map,
        images: images,
        preview: preview,
        diagnosticPalette: linearGoldenDiagnosticPalette,
      );

      await expectLater(
        image,
        matchesGoldenFile('goldens/open_fence_diagnostics.png'),
      );
      image.dispose();
    });
  });
}

void _expectNativeOpaqueBounds(
  BorderMaterialization materialization,
  List<BorderPublishedPrimitive> primitives,
) {
  final byId = <String, BorderPublishedPrimitive>{
    for (final primitive in primitives) primitive.id: primitive,
  };
  for (final placement in materialization.placements) {
    final primitive = byId[placement.primitiveId]!;
    final sourceBounds = primitive.publishedMetrics.opaqueBounds;
    final rotated = placement.transform.quarterTurns.isOdd;
    expect(
      placement.opaqueWorldBoundsPx.width,
      rotated ? sourceBounds.height : sourceBounds.width,
      reason: '${placement.primitiveId} must keep its native opaque width.',
    );
    expect(
      placement.opaqueWorldBoundsPx.height,
      rotated ? sourceBounds.width : sourceBounds.height,
      reason: '${placement.primitiveId} must keep its native opaque height.',
    );
  }
}

void _expectRailsBeforeOverlappingPosts(BorderMaterialization materialization) {
  final placements = materialization.placements;
  final rails = placements
      .where((item) => item.primitiveId == 'open-fence-rail')
      .toList(growable: false);
  final posts = placements
      .where((item) => item.primitiveId == 'open-fence-post')
      .toList(growable: false);
  expect(rails, isNotEmpty);
  expect(posts, isNotEmpty);
  var comparedOverlap = false;
  for (final rail in rails) {
    for (final post in posts) {
      if (!_overlaps(rail.opaqueWorldBoundsPx, post.opaqueWorldBoundsPx)) {
        continue;
      }
      comparedOverlap = true;
      expect(
        placements.indexOf(rail),
        lessThan(placements.indexOf(post)),
        reason: 'A rail must be painted before every post it overlaps.',
      );
    }
  }
  expect(
    comparedOverlap,
    isTrue,
    reason: 'The fixture must exercise a real rail/post overlap.',
  );
}

bool _overlaps(BorderPixelRect left, BorderPixelRect right) =>
    left.x < right.x + right.width &&
    right.x < left.x + left.width &&
    left.y < right.y + right.height &&
    right.y < left.y + left.height;

String _diagnostics(BorderResolutionResult result) => result.diagnostics
    .map((item) => '${item.severity.name}:${item.code}')
    .join(', ');
