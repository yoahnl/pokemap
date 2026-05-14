import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Shadow authoring diagnostics', () {
    test('manifest without element shadows has no diagnostics', () {
      final diagnostics = diagnoseProjectShadowAuthoring(
        _manifest(elements: [_element(id: 'tree')]),
      );

      expect(diagnostics, isEmpty);
    });

    test('ignores null shadow and castsShadow false', () {
      final diagnostics = diagnoseProjectShadowAuthoring(
        _manifest(
          elements: [
            _element(id: 'no_shadow'),
            _element(
              id: 'disabled_shadow',
              shadow: ProjectElementShadowConfig(
                castsShadow: false,
                shadowProfileId: 'missing_profile',
              ),
            ),
          ],
        ),
      );

      expect(diagnostics, isEmpty);
    });

    test('castsShadow true with existing profile has no diagnostics', () {
      final diagnostics = diagnoseProjectShadowAuthoring(
        _manifest(
          shadowCatalog: _catalog('tree_large'),
          elements: [
            _element(
              id: 'tree',
              shadow: ProjectElementShadowConfig(
                castsShadow: true,
                shadowProfileId: 'tree_large',
              ),
            ),
          ],
        ),
      );

      expect(diagnostics, isEmpty);
    });

    test('castsShadow true with missing profile produces a diagnostic', () {
      final diagnostics = diagnoseProjectShadowAuthoring(
        _manifest(
          elements: [
            _element(
              id: 'tree',
              shadow: ProjectElementShadowConfig(
                castsShadow: true,
                shadowProfileId: 'missing_profile',
              ),
            ),
          ],
        ),
      );

      expect(diagnostics, hasLength(1));
      expect(
        diagnostics.single.kind,
        ShadowAuthoringDiagnosticKind.missingShadowProfile,
      );
      expect(diagnostics.single.elementId, 'tree');
      expect(diagnostics.single.shadowProfileId, 'missing_profile');
      expect(diagnostics.single.message, contains('tree'));
      expect(diagnostics.single.message, contains('missing_profile'));
    });

    test('emits one diagnostic per element in manifest order', () {
      final diagnostics = diagnoseProjectShadowAuthoring(
        _manifest(
          elements: [
            _element(
              id: 'tree',
              shadow: ProjectElementShadowConfig(
                castsShadow: true,
                shadowProfileId: 'missing_tree',
              ),
            ),
            _element(
              id: 'rock',
              shadow: ProjectElementShadowConfig(
                castsShadow: true,
                shadowProfileId: 'missing_rock',
              ),
            ),
          ],
        ),
      );

      expect(diagnostics, hasLength(2));
      expect(diagnostics[0].elementId, 'tree');
      expect(diagnostics[0].shadowProfileId, 'missing_tree');
      expect(diagnostics[1].elementId, 'rock');
      expect(diagnostics[1].shadowProfileId, 'missing_rock');
    });

    test('same missing profile on two elements emits two diagnostics', () {
      final diagnostics = diagnoseProjectShadowAuthoring(
        _manifest(
          elements: [
            _element(
              id: 'tree_a',
              shadow: ProjectElementShadowConfig(
                castsShadow: true,
                shadowProfileId: 'missing_profile',
              ),
            ),
            _element(
              id: 'tree_b',
              shadow: ProjectElementShadowConfig(
                castsShadow: true,
                shadowProfileId: 'missing_profile',
              ),
            ),
          ],
        ),
      );

      expect(diagnostics, hasLength(2));
      expect(
        diagnostics.map((diagnostic) => diagnostic.elementId),
        <String>['tree_a', 'tree_b'],
      );
      expect(
        diagnostics.map((diagnostic) => diagnostic.shadowProfileId),
        <String>['missing_profile', 'missing_profile'],
      );
    });

    test('diagnostics use value equality', () {
      const a = ShadowAuthoringDiagnostic(
        kind: ShadowAuthoringDiagnosticKind.missingShadowProfile,
        elementId: 'tree',
        shadowProfileId: 'missing_profile',
        message:
            'Element "tree" references missing shadow profile "missing_profile".',
      );
      const b = ShadowAuthoringDiagnostic(
        kind: ShadowAuthoringDiagnosticKind.missingShadowProfile,
        elementId: 'tree',
        shadowProfileId: 'missing_profile',
        message:
            'Element "tree" references missing shadow profile "missing_profile".',
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('diagnostics do not modify collision data', () {
      const mask = ElementCollisionPixelMask(widthPx: 1, heightPx: 1);
      const collisionProfile = ElementCollisionProfile(
        visualMask: mask,
        collisionMask: mask,
        occlusionMask: mask,
        cells: <GridPos>[GridPos(x: 1, y: 2)],
      );
      final element = _element(
        id: 'tree',
        collisionProfile: collisionProfile,
        shadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'missing_profile',
        ),
      );
      final manifest = _manifest(elements: [element]);

      diagnoseProjectShadowAuthoring(manifest);

      expect(manifest.elements.single.collisionProfile, same(collisionProfile));
      expect(manifest.elements.single.collisionProfile!.visualMask, same(mask));
      expect(
        manifest.elements.single.collisionProfile!.collisionMask,
        same(mask),
      );
      expect(
        manifest.elements.single.collisionProfile!.occlusionMask,
        same(mask),
      );
      expect(
        manifest.elements.single.collisionProfile!.cells,
        const <GridPos>[GridPos(x: 1, y: 2)],
      );
    });
  });
}

ProjectManifest _manifest({
  ProjectShadowCatalog? shadowCatalog,
  List<ProjectElementEntry> elements = const [],
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    elements: elements,
    surfaceCatalog: ProjectSurfaceCatalog(),
    shadowCatalog: shadowCatalog ?? ProjectShadowCatalog(),
  );
}

ProjectShadowCatalog _catalog(String id) {
  return ProjectShadowCatalog(
    profiles: [
      ProjectShadowProfile(
        id: id,
        name: '$id shadow',
        mode: ShadowCasterMode.ellipse,
        renderPass: ShadowRenderPass.groundStatic,
      ),
    ],
  );
}

ProjectElementEntry _element({
  required String id,
  ProjectElementShadowConfig? shadow,
  ElementCollisionProfile? collisionProfile,
}) {
  return ProjectElementEntry(
    id: id,
    name: id,
    tilesetId: 'tileset',
    categoryId: 'nature',
    frames: const [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0),
      ),
    ],
    shadow: shadow,
    collisionProfile: collisionProfile,
  );
}
