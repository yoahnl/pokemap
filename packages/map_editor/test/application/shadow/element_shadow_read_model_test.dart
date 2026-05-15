import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/element_shadow_read_model.dart';

void main() {
  group('buildShadowProfileOptions', () {
    test('returns an empty list for an empty catalog', () {
      expect(buildShadowProfileOptions(ProjectShadowCatalog()), isEmpty);
    });

    test('preserves catalog order', () {
      final options = buildShadowProfileOptions(
        ProjectShadowCatalog(
          profiles: [
            _profile('tree_large', name: 'Large tree'),
            _profile('rock_small', name: 'Small rock'),
          ],
        ),
      );

      expect(options.map((option) => option.id), [
        'tree_large',
        'rock_small',
      ]);
    });

    test('exposes compatible groundStatic profile metadata for a dropdown', () {
      final options = buildShadowProfileOptions(
        ProjectShadowCatalog(
          profiles: [
            _profile(
              'tree_shadow',
              name: 'Tree shadow',
              mode: ShadowCasterMode.contactBlob,
              renderPass: ShadowRenderPass.groundStatic,
              opacity: 0.2,
              colorHexRgb: '123ABC',
            ),
          ],
        ),
      );

      final option = options.single;
      expect(option.id, 'tree_shadow');
      expect(option.name, 'Tree shadow');
      expect(option.label, 'Tree shadow');
      expect(option.mode, ShadowCasterMode.contactBlob);
      expect(option.renderPass, ShadowRenderPass.groundStatic);
      expect(option.opacity, 0.2);
      expect(option.colorHexRgb, '123ABC');
      expect(option.isNoneMode, isFalse);
    });

    test('filters out actorContact and none-mode profiles', () {
      final options = buildShadowProfileOptions(
        ProjectShadowCatalog(
          profiles: [
            _profile('shadow_none', mode: ShadowCasterMode.none),
            _profile(
              'actor_contact',
              mode: ShadowCasterMode.contactBlob,
              renderPass: ShadowRenderPass.actorContact,
            ),
            _profile('tree_shadow'),
          ],
        ),
      );

      expect(options.map((option) => option.id), ['tree_shadow']);
      expect(options.single.isNoneMode, isFalse);
    });

    test('returns an immutable list', () {
      final options = buildShadowProfileOptions(
        ProjectShadowCatalog(profiles: [_profile('tree_large')]),
      );

      expect(
        () => options.add(
          const ShadowProfileOptionReadModel(
            id: 'other',
            name: 'Other',
            mode: ShadowCasterMode.ellipse,
            renderPass: ShadowRenderPass.groundStatic,
            opacity: 0.35,
            colorHexRgb: '000000',
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });

  group('buildElementShadowReadModel status', () {
    test('element shadow null returns notConfigured', () {
      final element = _element(id: 'tree_large');
      final model = buildElementShadowReadModel(
        manifest: _manifest(elements: [element]),
        element: element,
      );

      expect(model.elementId, 'tree_large');
      expect(model.status, ElementShadowReadStatus.notConfigured);
      expect(model.hasShadowConfig, isFalse);
      expect(model.castsShadow, isFalse);
      expect(model.shadowProfileId, isNull);
      expect(model.shadowProfileName, isNull);
      expect(model.profileExists, isFalse);
      expect(model.resolved, isNull);
      expect(model.diagnostics, isEmpty);
    });

    test('castsShadow false returns disabled without diagnostics', () {
      final element = _element(
        id: 'flat_decor',
        shadow: ProjectElementShadowConfig(),
      );
      final model = buildElementShadowReadModel(
        manifest: _manifest(elements: [element]),
        element: element,
      );

      expect(model.status, ElementShadowReadStatus.disabled);
      expect(model.hasShadowConfig, isTrue);
      expect(model.castsShadow, isFalse);
      expect(model.resolved, isNull);
      expect(model.diagnostics, isEmpty);
    });

    test('castsShadow false with a profile id does not emit diagnostics', () {
      final element = _element(
        id: 'decor',
        shadow: ProjectElementShadowConfig(shadowProfileId: 'missing'),
      );
      final model = buildElementShadowReadModel(
        manifest: _manifest(elements: [element]),
        element: element,
      );

      expect(model.status, ElementShadowReadStatus.disabled);
      expect(model.shadowProfileId, 'missing');
      expect(model.profileExists, isFalse);
      expect(model.diagnostics, isEmpty);
    });

    test('castsShadow true with an existing profile returns active', () {
      final element = _element(
        id: 'tree',
        shadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
        ),
      );
      final manifest = _manifest(
        shadowCatalog: ProjectShadowCatalog(
          profiles: [
            _profile(
              'tree_large',
              mode: ShadowCasterMode.ellipse,
              renderPass: ShadowRenderPass.groundStatic,
              offsetX: 4,
              offsetY: 12,
              scaleX: 1.2,
              scaleY: 0.45,
              opacity: 0.35,
              colorHexRgb: '102030',
            ),
          ],
        ),
        elements: [element],
      );

      final model = buildElementShadowReadModel(
        manifest: manifest,
        element: element,
      );

      expect(model.status, ElementShadowReadStatus.active);
      expect(model.resolved, isNotNull);
      expect(
        model.resolved,
        const ResolvedShadowConfig(
          shadowProfileId: 'tree_large',
          mode: ShadowCasterMode.ellipse,
          renderPass: ShadowRenderPass.groundStatic,
          offsetX: 4,
          offsetY: 12,
          scaleX: 1.2,
          scaleY: 0.45,
          opacity: 0.35,
          colorHexRgb: '102030',
          softnessMode: ShadowSoftnessMode.hardEdge,
        ),
      );
      expect(model.diagnostics, isEmpty);
    });

    test('active status applies element numeric overrides', () {
      final element = _element(
        id: 'tree',
        shadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
          offsetX: 8,
          offsetY: 16,
          scaleX: 0.9,
          scaleY: 0.4,
          opacity: 0.25,
        ),
      );
      final model = buildElementShadowReadModel(
        manifest: _manifest(
          shadowCatalog: ProjectShadowCatalog(
            profiles: [
              _profile(
                'tree_large',
                offsetX: 4,
                offsetY: 12,
                scaleX: 1.2,
                scaleY: 0.45,
                opacity: 0.35,
              ),
            ],
          ),
          elements: [element],
        ),
        element: element,
      );

      expect(model.status, ElementShadowReadStatus.active);
      expect(model.offsetXOverride, 8);
      expect(model.offsetYOverride, 16);
      expect(model.scaleXOverride, 0.9);
      expect(model.scaleYOverride, 0.4);
      expect(model.opacityOverride, 0.25);
      expect(model.resolved!.offsetX, 8);
      expect(model.resolved!.offsetY, 16);
      expect(model.resolved!.scaleX, 0.9);
      expect(model.resolved!.scaleY, 0.4);
      expect(model.resolved!.opacity, 0.25);
    });

    test('missing profile returns missingProfile with a diagnostic', () {
      final element = _element(
        id: 'tree',
        shadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'missing_profile',
        ),
      );
      final model = buildElementShadowReadModel(
        manifest: _manifest(elements: [element]),
        element: element,
      );

      expect(model.status, ElementShadowReadStatus.missingProfile);
      expect(model.resolved, isNull);
      expect(model.shadowProfileId, 'missing_profile');
      expect(model.shadowProfileName, isNull);
      expect(model.profileExists, isFalse);
      expect(model.diagnostics, hasLength(1));
      expect(model.diagnostics.single.severity,
          ElementShadowDiagnosticSeverity.error);
      expect(model.diagnostics.single.code, 'missingShadowProfile');
      expect(model.diagnostics.single.message, contains('missing_profile'));
    });

    test('none-mode profile returns profileNone without diagnostics', () {
      final element = _element(
        id: 'flat_shadow',
        shadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'shadow_none',
        ),
      );
      final model = buildElementShadowReadModel(
        manifest: _manifest(
          shadowCatalog: ProjectShadowCatalog(
            profiles: [
              _profile('shadow_none', mode: ShadowCasterMode.none),
            ],
          ),
          elements: [element],
        ),
        element: element,
      );

      expect(model.status, ElementShadowReadStatus.profileNone);
      expect(model.resolved, isNull);
      expect(model.profileExists, isTrue);
      expect(model.shadowProfileName, 'shadow_none shadow');
      expect(model.diagnostics, isEmpty);
    });
  });

  group('buildElementShadowReadModel profile metadata', () {
    test('fills profile name when the selected profile exists', () {
      final element = _element(
        shadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
        ),
      );
      final model = buildElementShadowReadModel(
        manifest: _manifest(
          shadowCatalog: ProjectShadowCatalog(
            profiles: [_profile('tree_large', name: 'Large tree shadow')],
          ),
          elements: [element],
        ),
        element: element,
      );

      expect(model.shadowProfileId, 'tree_large');
      expect(model.shadowProfileName, 'Large tree shadow');
      expect(model.profileExists, isTrue);
    });

    test('keeps profile name null when the selected profile is missing', () {
      final element = _element(
        shadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'missing',
        ),
      );
      final model = buildElementShadowReadModel(
        manifest: _manifest(elements: [element]),
        element: element,
      );

      expect(model.shadowProfileId, 'missing');
      expect(model.shadowProfileName, isNull);
      expect(model.profileExists, isFalse);
    });

    test('includes profile options on each element read model', () {
      final element = _element();
      final model = buildElementShadowReadModel(
        manifest: _manifest(
          shadowCatalog: ProjectShadowCatalog(
            profiles: [
              _profile('tree_large'),
              _profile('rock_small'),
            ],
          ),
          elements: [element],
        ),
        element: element,
      );

      expect(model.profileOptions.map((option) => option.id), [
        'tree_large',
        'rock_small',
      ]);
    });
  });

  group('diagnostics and immutability', () {
    test('diagnostics are empty for notConfigured, disabled, and active', () {
      final notConfigured = _element(id: 'not_configured');
      final disabled = _element(
        id: 'disabled',
        shadow: ProjectElementShadowConfig(),
      );
      final active = _element(
        id: 'active',
        shadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
        ),
      );
      final manifest = _manifest(
        shadowCatalog: ProjectShadowCatalog(
          profiles: [_profile('tree_large')],
        ),
        elements: [notConfigured, disabled, active],
      );

      expect(
        buildElementShadowReadModel(
          manifest: manifest,
          element: notConfigured,
        ).diagnostics,
        isEmpty,
      );
      expect(
        buildElementShadowReadModel(
          manifest: manifest,
          element: disabled,
        ).diagnostics,
        isEmpty,
      );
      expect(
        buildElementShadowReadModel(
          manifest: manifest,
          element: active,
        ).diagnostics,
        isEmpty,
      );
    });

    test('diagnostics list is immutable', () {
      final element = _element(
        shadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'missing',
        ),
      );
      final model = buildElementShadowReadModel(
        manifest: _manifest(elements: [element]),
        element: element,
      );

      expect(
        () => model.diagnostics.add(
          const ElementShadowDiagnosticReadModel(
            severity: ElementShadowDiagnosticSeverity.warning,
            code: 'other',
            message: 'Other',
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('profile options list on the element read model is immutable', () {
      final element = _element();
      final model = buildElementShadowReadModel(
        manifest: _manifest(
          shadowCatalog: ProjectShadowCatalog(
            profiles: [_profile('tree_large')],
          ),
          elements: [element],
        ),
        element: element,
      );

      expect(
        () => model.profileOptions.clear(),
        throwsUnsupportedError,
      );
    });
  });

  group('non-mutation', () {
    test('does not mutate manifest, element shadow, or shadow catalog', () {
      final shadow = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        opacity: 0.2,
      );
      final element = _element(shadow: shadow);
      final catalog = ProjectShadowCatalog(
        profiles: [_profile('tree_large')],
      );
      final manifest = _manifest(
        shadowCatalog: catalog,
        elements: [element],
      );

      final beforeManifest = manifest;
      final beforeElement = element;
      final beforeShadow = element.shadow;
      final beforeCatalog = manifest.shadowCatalog;

      buildElementShadowReadModel(manifest: manifest, element: element);

      expect(manifest, beforeManifest);
      expect(element, beforeElement);
      expect(element.shadow, beforeShadow);
      expect(manifest.shadowCatalog, beforeCatalog);
      expect(manifest.shadowCatalog.profileById('tree_large'), isNotNull);
    });
  });

  group('bulk builder', () {
    test('buildElementShadowReadModels builds models in manifest element order',
        () {
      final first = _element(id: 'first');
      final second = _element(
        id: 'second',
        shadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
        ),
      );
      final models = buildElementShadowReadModels(
        _manifest(
          shadowCatalog: ProjectShadowCatalog(
            profiles: [_profile('tree_large')],
          ),
          elements: [first, second],
        ),
      );

      expect(models.map((model) => model.elementId), ['first', 'second']);
      expect(models.map((model) => model.status), [
        ElementShadowReadStatus.notConfigured,
        ElementShadowReadStatus.active,
      ]);
      expect(() => models.clear(), throwsUnsupportedError);
    });
  });

  group('value equality', () {
    test('ShadowProfileOptionReadModel supports value equality', () {
      const a = ShadowProfileOptionReadModel(
        id: 'tree_large',
        name: 'Large tree',
        mode: ShadowCasterMode.ellipse,
        renderPass: ShadowRenderPass.groundStatic,
        opacity: 0.35,
        colorHexRgb: '000000',
      );
      const b = ShadowProfileOptionReadModel(
        id: 'tree_large',
        name: 'Large tree',
        mode: ShadowCasterMode.ellipse,
        renderPass: ShadowRenderPass.groundStatic,
        opacity: 0.35,
        colorHexRgb: '000000',
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('ElementShadowDiagnosticReadModel supports value equality', () {
      const a = ElementShadowDiagnosticReadModel(
        severity: ElementShadowDiagnosticSeverity.error,
        code: 'missingShadowProfile',
        message: 'Missing shadow profile "tree".',
      );
      const b = ElementShadowDiagnosticReadModel(
        severity: ElementShadowDiagnosticSeverity.error,
        code: 'missingShadowProfile',
        message: 'Missing shadow profile "tree".',
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('ElementShadowReadModel supports value equality', () {
      final profileOptions = [
        const ShadowProfileOptionReadModel(
          id: 'tree_large',
          name: 'Large tree',
          mode: ShadowCasterMode.ellipse,
          renderPass: ShadowRenderPass.groundStatic,
          opacity: 0.35,
          colorHexRgb: '000000',
        ),
      ];
      final a = ElementShadowReadModel(
        elementId: 'tree',
        status: ElementShadowReadStatus.active,
        hasShadowConfig: true,
        castsShadow: true,
        shadowProfileId: 'tree_large',
        shadowProfileName: 'Large tree',
        profileExists: true,
        resolved: const ResolvedShadowConfig(
          shadowProfileId: 'tree_large',
          mode: ShadowCasterMode.ellipse,
          renderPass: ShadowRenderPass.groundStatic,
          offsetX: 0,
          offsetY: 0,
          scaleX: 1,
          scaleY: 1,
          opacity: 0.35,
          colorHexRgb: '000000',
          softnessMode: ShadowSoftnessMode.hardEdge,
        ),
        diagnostics: const [],
        profileOptions: profileOptions,
      );
      final b = ElementShadowReadModel(
        elementId: 'tree',
        status: ElementShadowReadStatus.active,
        hasShadowConfig: true,
        castsShadow: true,
        shadowProfileId: 'tree_large',
        shadowProfileName: 'Large tree',
        profileExists: true,
        resolved: const ResolvedShadowConfig(
          shadowProfileId: 'tree_large',
          mode: ShadowCasterMode.ellipse,
          renderPass: ShadowRenderPass.groundStatic,
          offsetX: 0,
          offsetY: 0,
          scaleX: 1,
          scaleY: 1,
          opacity: 0.35,
          colorHexRgb: '000000',
          softnessMode: ShadowSoftnessMode.hardEdge,
        ),
        diagnostics: const [],
        profileOptions: profileOptions,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
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

ProjectElementEntry _element({
  String id = 'tree',
  ProjectElementShadowConfig? shadow,
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
  );
}

ProjectShadowProfile _profile(
  String id, {
  String? name,
  ShadowCasterMode mode = ShadowCasterMode.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
  double offsetX = 0,
  double offsetY = 0,
  double scaleX = 1,
  double scaleY = 1,
  double opacity = 0.35,
  String colorHexRgb = '000000',
}) {
  return ProjectShadowProfile(
    id: id,
    name: name ?? '$id shadow',
    mode: mode,
    renderPass: renderPass,
    offsetX: offsetX,
    offsetY: offsetY,
    scaleX: scaleX,
    scaleY: scaleY,
    opacity: opacity,
    colorHexRgb: colorHexRgb,
  );
}
