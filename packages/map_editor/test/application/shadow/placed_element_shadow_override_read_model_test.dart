import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/placed_element_shadow_override_read_model.dart';

void main() {
  group('buildPlacedElementShadowOverrideReadModel', () {
    test('null and explicit inherit override map to inherit mode', () {
      final nullModel = buildPlacedElementShadowOverrideReadModel(
        manifest: _manifest(),
        element: _element(),
        instance: _instance(),
      );
      final explicitModel = buildPlacedElementShadowOverrideReadModel(
        manifest: _manifest(),
        element: _element(),
        instance: _instance(
          shadowOverride: MapPlacedElementShadowOverride(),
        ),
      );

      expect(nullModel.mode, PlacedElementShadowOverrideUiMode.inherit);
      expect(explicitModel.mode, PlacedElementShadowOverrideUiMode.inherit);
      expect(nullModel.usesNullInheritance, isTrue);
      expect(explicitModel.usesNullInheritance, isFalse);
    });

    test('disabled and custom override map to matching modes', () {
      final disabled = buildPlacedElementShadowOverrideReadModel(
        manifest: _manifest(),
        element: _element(),
        instance: _instance(
          shadowOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.disabled,
          ),
        ),
      );
      final custom = buildPlacedElementShadowOverrideReadModel(
        manifest: _manifest(),
        element: _element(),
        instance: _instance(
          shadowOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            shadowProfileId: 'wide_shadow',
          ),
        ),
      );

      expect(disabled.mode, PlacedElementShadowOverrideUiMode.disabled);
      expect(custom.mode, PlacedElementShadowOverrideUiMode.custom);
      expect(custom.selectedProfileId, 'wide_shadow');
      expect(custom.selectedProfileLabel, 'Wide shadow');
    });

    test('filters actorContact and none profiles from static instance options',
        () {
      final model = buildPlacedElementShadowOverrideReadModel(
        manifest: _manifest(
          catalog: ProjectShadowCatalog(
            profiles: [
              _profile('ground_shadow'),
              _profile(
                'actor_shadow',
                mode: ShadowCasterMode.contactBlob,
                renderPass: ShadowRenderPass.actorContact,
              ),
              _profile('none_shadow', mode: ShadowCasterMode.none),
            ],
          ),
        ),
        element: _element(),
        instance: _instance(),
      );

      expect(model.profileOptions.map((option) => option.id), [
        'ground_shadow',
      ]);
    });

    test('empty catalog reports no compatible profiles', () {
      final model = buildPlacedElementShadowOverrideReadModel(
        manifest: _manifest(catalog: const ProjectShadowCatalog.empty()),
        element: _element(),
        instance: _instance(),
      );

      expect(model.profileOptions, isEmpty);
      expect(model.hasCompatibleProfiles, isFalse);
      expect(model.noCompatibleProfileMessage, isNotNull);
    });

    test('custom without shadowProfileId inherits source profile', () {
      final model = buildPlacedElementShadowOverrideReadModel(
        manifest: _manifest(),
        element: _element(),
        instance: _instance(
          shadowOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            offsetX: 2,
          ),
        ),
      );

      expect(model.mode, PlacedElementShadowOverrideUiMode.custom);
      expect(model.selectedProfileId, isNull);
      expect(model.selectedProfileLabel, 'Profil de l’élément source');
    });

    test('source element without shadow config exposes an informative message',
        () {
      final model = buildPlacedElementShadowOverrideReadModel(
        manifest: _manifest(),
        element: _elementWithoutShadow(),
        instance: _instance(),
      );

      expect(model.sourceShadowMessage, isNotNull);
    });
  });
}

ProjectManifest _manifest({ProjectShadowCatalog? catalog}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    shadowCatalog: catalog ??
        ProjectShadowCatalog(
          profiles: [
            _profile('base_shadow', name: 'Base shadow'),
            _profile('wide_shadow', name: 'Wide shadow'),
          ],
        ),
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
}

ProjectElementEntry _element({ProjectElementShadowConfig? shadow}) {
  return ProjectElementEntry(
    id: 'lamp',
    name: 'Lamp',
    tilesetId: 'ts',
    categoryId: 'cat',
    frames: const [
      TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
    ],
    shadow: shadow ??
        ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'base_shadow',
        ),
  );
}

ProjectElementEntry _elementWithoutShadow() {
  return const ProjectElementEntry(
    id: 'lamp',
    name: 'Lamp',
    tilesetId: 'ts',
    categoryId: 'cat',
    frames: [
      TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
    ],
  );
}

MapPlacedElement _instance({MapPlacedElementShadowOverride? shadowOverride}) {
  return MapPlacedElement(
    id: 'layer::1::1',
    layerId: 'layer',
    elementId: 'lamp',
    pos: const GridPos(x: 1, y: 1),
    shadowOverride: shadowOverride,
  );
}

ProjectShadowProfile _profile(
  String id, {
  String? name,
  ShadowCasterMode mode = ShadowCasterMode.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
}) {
  return ProjectShadowProfile(
    id: id,
    name: name ?? '$id profile',
    mode: mode,
    renderPass: renderPass,
  );
}
