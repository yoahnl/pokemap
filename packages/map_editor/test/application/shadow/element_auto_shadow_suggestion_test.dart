import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/element_auto_shadow_suggestion.dart';

void main() {
  group('buildElementAutoShadowSuggestion', () {
    test('returns null without compatible ground static profile', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 1, height: 4),
        shadowCatalog: ProjectShadowCatalog(
          profiles: [
            _profile(
              'actor_contact',
              mode: ShadowCasterMode.contactBlob,
              renderPass: ShadowRenderPass.actorContact,
            ),
            _profile('none', mode: ShadowCasterMode.none),
          ],
        ),
      );

      expect(suggestion, isNull);
    });

    test('returns null for missing frames', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _elementWithFrames(const []),
        shadowCatalog: _defaultCatalog(),
      );

      expect(suggestion, isNull);
    });

    test('returns null for invalid first frame source', () {
      final invalidWidth = buildElementAutoShadowSuggestion(
        element: _element(width: 0, height: 4),
        shadowCatalog: _defaultCatalog(),
      );
      final invalidHeight = buildElementAutoShadowSuggestion(
        element: _element(width: 1, height: 0),
        shadowCatalog: _defaultCatalog(),
      );

      expect(invalidWidth, isNull);
      expect(invalidHeight, isNull);
    });

    test('classifies tall thin elements as tallThin', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 1, height: 4),
        shadowCatalog: _defaultCatalog(),
      )!;

      expect(suggestion.kind, ElementAutoShadowSuggestionKind.tallThin);
      expect(suggestion.config.shadowProfileId, 'default-ground-contact-blob');
      expect(suggestion.config.family, StaticShadowFamily.tallProp);
      expect(suggestion.config.footprint!.footprintWidthRatio, 0.18);
      expect(suggestion.config.footprint!.footprintHeightRatio, 0.07);
      expect(suggestion.config.opacity, 0.28);
    });

    test('classifies large buildings as buildingLarge', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 4, height: 3),
        shadowCatalog: _defaultCatalog(),
      )!;

      expect(suggestion.kind, ElementAutoShadowSuggestionKind.buildingLarge);
      expect(suggestion.config.shadowProfileId, 'default-ground-wide-ellipse');
      expect(suggestion.config.family, StaticShadowFamily.building);
      expect(suggestion.config.footprint!.anchorYRatio, 0.92);
      expect(suggestion.config.footprint!.footprintWidthRatio, 0.82);
      expect(suggestion.config.footprint!.footprintHeightRatio, 0.12);
      expect(suggestion.config.scaleY, 0.85);
      expect(suggestion.config.opacity, 0.30);
    });

    test('classifies wide low elements as wideLow', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 3, height: 2),
        shadowCatalog: _defaultCatalog(),
      )!;

      expect(suggestion.kind, ElementAutoShadowSuggestionKind.wideLow);
      expect(suggestion.config.shadowProfileId, 'default-ground-wide-ellipse');
      expect(suggestion.config.family, StaticShadowFamily.compactProp);
      expect(suggestion.config.footprint!.anchorYRatio, 0.95);
      expect(suggestion.config.footprint!.footprintWidthRatio, 0.72);
      expect(suggestion.config.footprint!.footprintHeightRatio, 0.10);
      expect(suggestion.config.scaleX, 0.92);
      expect(suggestion.config.scaleY, 0.75);
      expect(suggestion.config.opacity, 0.27);
    });

    test('classifies small square elements as smallSquare', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 2, height: 2),
        shadowCatalog: _defaultCatalog(),
      )!;

      expect(suggestion.kind, ElementAutoShadowSuggestionKind.smallSquare);
      expect(suggestion.config.shadowProfileId, 'default-ground-contact-blob');
      expect(suggestion.config.family, StaticShadowFamily.compactProp);
      expect(suggestion.config.footprint!.anchorYRatio, 0.96);
      expect(suggestion.config.footprint!.footprintWidthRatio, 0.46);
      expect(suggestion.config.footprint!.footprintHeightRatio, 0.10);
      expect(suggestion.config.scaleX, 0.78);
      expect(suggestion.config.scaleY, 0.70);
      expect(suggestion.config.opacity, 0.26);
    });

    test('classifies remaining valid elements as defaultProp', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 2, height: 3),
        shadowCatalog: _defaultCatalog(),
      )!;

      expect(suggestion.kind, ElementAutoShadowSuggestionKind.defaultProp);
      expect(suggestion.config.shadowProfileId, 'default-ground-soft-ellipse');
      expect(suggestion.config.family, StaticShadowFamily.genericProjection);
      expect(suggestion.config.footprint!.anchorYRatio, 0.95);
      expect(suggestion.config.footprint!.footprintWidthRatio, 0.62);
      expect(suggestion.config.footprint!.footprintHeightRatio, 0.12);
      expect(suggestion.config.scaleX, 0.90);
      expect(suggestion.config.scaleY, 0.80);
      expect(suggestion.config.opacity, 0.28);
    });

    test('prefers default compact profile for tallThin', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 1, height: 4),
        shadowCatalog: ProjectShadowCatalog(
          profiles: [
            _profile('custom-soft'),
            _profile('default-ground-contact-blob',
                mode: ShadowCasterMode.contactBlob),
          ],
        ),
      )!;

      expect(suggestion.config.shadowProfileId, 'default-ground-contact-blob');
    });

    test('falls back to custom compatible profile ids', () {
      final tallThin = buildElementAutoShadowSuggestion(
        element: _element(width: 1, height: 4),
        shadowCatalog: ProjectShadowCatalog(
          profiles: [
            _profile('custom-contact', mode: ShadowCasterMode.contactBlob)
          ],
        ),
      )!;
      final building = buildElementAutoShadowSuggestion(
        element: _element(width: 4, height: 3),
        shadowCatalog: ProjectShadowCatalog(
          profiles: [_profile('custom-ellipse')],
        ),
      )!;
      final defaultProp = buildElementAutoShadowSuggestion(
        element: _element(width: 2, height: 3),
        shadowCatalog: ProjectShadowCatalog(
          profiles: [_profile('custom-soft')],
        ),
      )!;

      expect(tallThin.config.shadowProfileId, 'custom-contact');
      expect(building.config.shadowProfileId, 'custom-ellipse');
      expect(defaultProp.config.shadowProfileId, 'custom-soft');
    });

    test('all suggestions have castsShadow true', () {
      for (final suggestion in _allSuggestionKinds()) {
        expect(suggestion.config.castsShadow, isTrue);
      }
    });

    test('all suggestion footprints are non-null and valid', () {
      for (final suggestion in _allSuggestionKinds()) {
        final footprint = suggestion.config.footprint;
        expect(footprint, isNotNull);
        expect(footprint!.anchorXRatio, inInclusiveRange(0, 1));
        expect(footprint.anchorYRatio, inInclusiveRange(0, 1));
        expect(footprint.footprintWidthRatio, greaterThan(0));
        expect(footprint.footprintHeightRatio, greaterThan(0));
      }
    });

    test('all suggestions carry a static shadow family', () {
      for (final suggestion in _allSuggestionKinds()) {
        expect(suggestion.config.family, isNotNull);
      }
    });

    test('all suggestion opacities are within 0..1', () {
      for (final suggestion in _allSuggestionKinds()) {
        expect(suggestion.config.opacity, inInclusiveRange(0, 1));
      }
    });

    test('all suggestion scaleX and scaleY are greater than zero', () {
      for (final suggestion in _allSuggestionKinds()) {
        expect(suggestion.config.scaleX, greaterThan(0));
        expect(suggestion.config.scaleY, greaterThan(0));
      }
    });
  });
}

Iterable<ElementAutoShadowSuggestion> _allSuggestionKinds() sync* {
  for (final dimensions in const [
    (width: 1, height: 4),
    (width: 4, height: 3),
    (width: 3, height: 2),
    (width: 2, height: 2),
    (width: 2, height: 3),
  ]) {
    yield buildElementAutoShadowSuggestion(
      element: _element(width: dimensions.width, height: dimensions.height),
      shadowCatalog: _defaultCatalog(),
    )!;
  }
}

ProjectShadowCatalog _defaultCatalog() {
  return ProjectShadowCatalog(
    profiles: createDefaultGroundStaticShadowProfiles(),
  );
}

ProjectElementEntry _element({
  required int width,
  required int height,
}) {
  return _elementWithFrames([
    TilesetVisualFrame(
      source: TilesetSourceRect(x: 0, y: 0, width: width, height: height),
    ),
  ]);
}

ProjectElementEntry _elementWithFrames(List<TilesetVisualFrame> frames) {
  return ProjectElementEntry(
    id: 'element',
    name: 'Element',
    tilesetId: 'tileset',
    categoryId: 'decor',
    frames: frames,
  );
}

ProjectShadowProfile _profile(
  String id, {
  ShadowCasterMode mode = ShadowCasterMode.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
}) {
  return ProjectShadowProfile(
    id: id,
    name: '$id shadow',
    mode: mode,
    renderPass: renderPass,
  );
}
