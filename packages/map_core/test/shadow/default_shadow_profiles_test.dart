import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('default ground static shadow profiles', () {
    test('default profile ids are stable and unique', () {
      final profiles = createDefaultGroundStaticShadowProfiles();

      expect(profiles.map((profile) => profile.id), [
        'default-ground-soft-ellipse',
        'default-ground-wide-ellipse',
        'default-ground-contact-blob',
      ]);
      expect(
        profiles.map((profile) => profile.id).toSet(),
        hasLength(profiles.length),
      );
    });

    test('default profiles are valid groundStatic element profiles', () {
      final profiles = createDefaultGroundStaticShadowProfiles();

      expect(profiles, hasLength(3));
      for (final profile in profiles) {
        expect(profile.id.trim(), isNotEmpty);
        expect(profile.name.trim(), isNotEmpty);
        expect(profile.renderPass, ShadowRenderPass.groundStatic);
        expect(profile.renderPass, isNot(ShadowRenderPass.actorContact));
        expect(profile.mode, isNot(ShadowCasterMode.none));
        expect(profile.colorHexRgb, '000000');
        expect(profile.softnessMode, ShadowSoftnessMode.hardEdge);
        expect(isGroundStaticElementShadowProfile(profile), isTrue);
      }
    });

    test('profile compatibility requires groundStatic and non-none mode', () {
      expect(
        isGroundStaticElementShadowProfile(
          _profile('ellipse', mode: ShadowCasterMode.ellipse),
        ),
        isTrue,
      );
      expect(
        isGroundStaticElementShadowProfile(
          _profile(
            'actor',
            mode: ShadowCasterMode.contactBlob,
            renderPass: ShadowRenderPass.actorContact,
          ),
        ),
        isFalse,
      );
      expect(
        isGroundStaticElementShadowProfile(
          _profile('none', mode: ShadowCasterMode.none),
        ),
        isFalse,
      );
    });

    test('catalog compatibility ignores actorContact and none profiles', () {
      expect(
        hasGroundStaticElementShadowProfiles(
            const ProjectShadowCatalog.empty()),
        isFalse,
      );
      expect(
        hasGroundStaticElementShadowProfiles(
          ProjectShadowCatalog(
            profiles: [
              _profile(
                'actor',
                mode: ShadowCasterMode.contactBlob,
                renderPass: ShadowRenderPass.actorContact,
              ),
            ],
          ),
        ),
        isFalse,
      );
      expect(
        hasGroundStaticElementShadowProfiles(
          ProjectShadowCatalog(
            profiles: [_profile('none', mode: ShadowCasterMode.none)],
          ),
        ),
        isFalse,
      );
      expect(
        hasGroundStaticElementShadowProfiles(
          ProjectShadowCatalog(
            profiles: [_profile('ellipse', mode: ShadowCasterMode.ellipse)],
          ),
        ),
        isTrue,
      );
    });

    test('ensure defaults adds defaults to an empty catalog', () {
      final updated = ensureDefaultGroundStaticShadowProfiles(
        const ProjectShadowCatalog.empty(),
      );

      expect(
        updated.profiles.map((profile) => profile.id),
        createDefaultGroundStaticShadowProfiles().map((profile) => profile.id),
      );
    });

    test(
        'ensure defaults preserves incompatible custom profiles before defaults',
        () {
      final actorProfile = _profile(
        'actor-contact',
        mode: ShadowCasterMode.contactBlob,
        renderPass: ShadowRenderPass.actorContact,
      );
      final noneProfile = _profile('none-profile', mode: ShadowCasterMode.none);

      final updated = ensureDefaultGroundStaticShadowProfiles(
        ProjectShadowCatalog(profiles: [actorProfile, noneProfile]),
      );

      expect(updated.profiles.take(2), [actorProfile, noneProfile]);
      expect(updated.profiles.skip(2).map((profile) => profile.id), [
        'default-ground-soft-ellipse',
        'default-ground-wide-ellipse',
        'default-ground-contact-blob',
      ]);
    });

    test('ensure defaults does not modify a catalog with a compatible profile',
        () {
      final catalog = ProjectShadowCatalog(
        profiles: [_profile('custom-ground')],
      );

      final updated = ensureDefaultGroundStaticShadowProfiles(catalog);

      expect(updated, catalog);
    });

    test('ensure defaults does not duplicate default ids when seeding', () {
      final existingDefault = createDefaultGroundStaticShadowProfiles().first;
      final actorOnlyDefaultId = ProjectShadowProfile(
        id: existingDefault.id,
        name: 'Actor copy',
        mode: ShadowCasterMode.contactBlob,
        renderPass: ShadowRenderPass.actorContact,
      );

      final updated = ensureDefaultGroundStaticShadowProfiles(
        ProjectShadowCatalog(profiles: [actorOnlyDefaultId]),
      );

      expect(
        updated.profiles.where((profile) => profile.id == existingDefault.id),
        hasLength(1),
      );
      expect(updated.profileById('default-ground-wide-ellipse'), isNotNull);
      expect(updated.profileById('default-ground-contact-blob'), isNotNull);
    });

    test('manifest operation updates only shadowCatalog', () {
      final element = ProjectElementEntry(
        id: 'tree',
        name: 'Tree',
        tilesetId: 'tileset',
        categoryId: 'decor',
        frames: const [
          TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 2)),
        ],
        shadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'missing',
        ),
      );
      final manifest = ProjectManifest(
        name: 'Demo',
        maps: const [
          ProjectMapEntry(
              id: 'map', name: 'Map', relativePath: 'maps/map.json'),
        ],
        tilesets: const [],
        elements: [element],
        settings: const ProjectSettings(tileWidth: 24, tileHeight: 24),
        surfaceCatalog: ProjectSurfaceCatalog(),
        shadowCatalog: const ProjectShadowCatalog.empty(),
      );

      final updated = ensureDefaultGroundStaticShadowProfilesForProject(
        manifest,
      );

      expect(updated.shadowCatalog.isNotEmpty, isTrue);
      expect(updated.name, manifest.name);
      expect(updated.maps, manifest.maps);
      expect(updated.tilesets, manifest.tilesets);
      expect(updated.elements, manifest.elements);
      expect(updated.elements.single.shadow, same(element.shadow));
      expect(updated.settings, manifest.settings);
      expect(updated.surfaceCatalog, manifest.surfaceCatalog);
    });
  });
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
