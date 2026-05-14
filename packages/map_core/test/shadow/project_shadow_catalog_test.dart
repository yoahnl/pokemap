import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

ProjectShadowProfile _profile(String id) {
  return ProjectShadowProfile(
    id: id,
    name: 'Shadow $id',
    mode: ShadowCasterMode.ellipse,
    renderPass: ShadowRenderPass.groundStatic,
  );
}

void main() {
  group('ProjectShadowCatalog', () {
    test('accepts an empty catalog', () {
      final catalog = ProjectShadowCatalog();

      expect(catalog.profiles, isEmpty);
      expect(catalog.profileCount, 0);
      expect(catalog.isEmpty, isTrue);
      expect(catalog.isNotEmpty, isFalse);
    });

    test('preserves profile order', () {
      final catalog = ProjectShadowCatalog(
        profiles: [
          _profile('first'),
          _profile('second'),
          _profile('third'),
        ],
      );

      expect(
        catalog.profiles.map((profile) => profile.id),
        ['first', 'second', 'third'],
      );
    });

    test('defensively copies the source list', () {
      final source = [_profile('only')];
      final catalog = ProjectShadowCatalog(profiles: source);

      source.add(_profile('extra'));

      expect(catalog.profileCount, 1);
      expect(catalog.profiles.map((profile) => profile.id), ['only']);
    });

    test('exposes an unmodifiable profiles list', () {
      final catalog = ProjectShadowCatalog();

      expect(
        () => catalog.profiles.add(_profile('extra')),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('profileById returns the expected profile', () {
      final profile = _profile('tree');
      final catalog = ProjectShadowCatalog(profiles: [profile]);

      expect(catalog.profileById('tree'), same(profile));
    });

    test('profileById returns null for an unknown id', () {
      final catalog = ProjectShadowCatalog(profiles: [_profile('tree')]);

      expect(catalog.profileById('missing'), isNull);
    });

    test('profileById is exact and case-sensitive', () {
      final lower = _profile('tree');
      final upper = _profile('TREE');
      final catalog = ProjectShadowCatalog(profiles: [lower, upper]);

      expect(catalog.profileById('tree'), same(lower));
      expect(catalog.profileById('TREE'), same(upper));
      expect(
          ProjectShadowCatalog(profiles: [lower]).profileById('TREE'), isNull);
    });

    test('rejects duplicate profile ids', () {
      expect(
        () => ProjectShadowCatalog(
          profiles: [
            _profile('tree'),
            _profile('tree'),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('uses ordered value equality and matching hashCode', () {
      final a = ProjectShadowCatalog(
        profiles: [
          _profile('tree'),
          _profile('rock'),
        ],
      );
      final b = ProjectShadowCatalog(
        profiles: [
          _profile('tree'),
          _profile('rock'),
        ],
      );
      final c = ProjectShadowCatalog(
        profiles: [
          _profile('rock'),
          _profile('tree'),
        ],
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('does not require JSON APIs on profile or catalog', () {
      final profile = _profile('tree');
      final catalog = ProjectShadowCatalog(profiles: [profile]);

      expect(profile, isA<ProjectShadowProfile>());
      expect(catalog, isA<ProjectShadowCatalog>());
    });
  });
}
