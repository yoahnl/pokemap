import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('resolveShadowConfig base behavior', () {
    test('elementShadow null and override null yields no shadow', () {
      final resolution = resolveShadowConfig(
        catalog: _catalog([_profile('tree_large')]),
        elementShadow: null,
      );

      expect(resolution.hasShadow, isFalse);
      expect(resolution.isNone, isTrue);
      expect(resolution.resolved, isNull);
      expect(resolution.diagnostics, isEmpty);
      expect(resolution.hasDiagnostics, isFalse);
    });

    test('castsShadow false and override null yields no shadow', () {
      final resolution = resolveShadowConfig(
        catalog: _catalog([_profile('tree_large')]),
        elementShadow: ProjectElementShadowConfig(
          castsShadow: false,
          shadowProfileId: 'tree_large',
        ),
      );

      expect(resolution.resolved, isNull);
      expect(resolution.diagnostics, isEmpty);
    });

    test('castsShadow true with existing profile resolves profile fields', () {
      final profile = _profile(
        'tree_large',
        mode: ShadowCasterMode.ellipse,
        renderPass: ShadowRenderPass.groundStatic,
        offsetX: 4,
        offsetY: 12,
        scaleX: 1.2,
        scaleY: 0.45,
        opacity: 0.35,
        colorHexRgb: '102030',
        softnessMode: ShadowSoftnessMode.hardEdge,
      );

      final resolution = resolveShadowConfig(
        catalog: _catalog([profile]),
        elementShadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
        ),
      );

      expect(
        resolution.resolved,
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
      expect(resolution.hasShadow, isTrue);
      expect(resolution.isNone, isFalse);
      expect(resolution.diagnostics, isEmpty);
    });

    test('profile mode none yields no shadow and no diagnostics', () {
      final resolution = resolveShadowConfig(
        catalog: _catalog([
          _profile('none_profile', mode: ShadowCasterMode.none),
        ]),
        elementShadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'none_profile',
        ),
      );

      expect(resolution.resolved, isNull);
      expect(resolution.diagnostics, isEmpty);
    });
  });

  group('resolveShadowConfig element overrides', () {
    test('element overrides replace profile numeric fields', () {
      final resolution = resolveShadowConfig(
        catalog: _catalog([
          _profile(
            'tree_large',
            offsetX: 1,
            offsetY: 2,
            scaleX: 3,
            scaleY: 4,
            opacity: 0.5,
          ),
        ]),
        elementShadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
          offsetX: 10,
          offsetY: 20,
          scaleX: 0.8,
          scaleY: 0.3,
          opacity: 0.25,
        ),
      );

      expect(resolution.resolved!.offsetX, 10);
      expect(resolution.resolved!.offsetY, 20);
      expect(resolution.resolved!.scaleX, 0.8);
      expect(resolution.resolved!.scaleY, 0.3);
      expect(resolution.resolved!.opacity, 0.25);
    });

    test('partial element overrides preserve profile fallback values', () {
      final resolution = resolveShadowConfig(
        catalog: _catalog([
          _profile(
            'tree_large',
            offsetX: 1,
            offsetY: 2,
            scaleX: 3,
            scaleY: 4,
            opacity: 0.5,
          ),
        ]),
        elementShadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
          offsetX: 10,
          opacity: 0.25,
        ),
      );

      expect(resolution.resolved!.offsetX, 10);
      expect(resolution.resolved!.offsetY, 2);
      expect(resolution.resolved!.scaleX, 3);
      expect(resolution.resolved!.scaleY, 4);
      expect(resolution.resolved!.opacity, 0.25);
    });
  });

  group('resolveShadowConfig inherit and disabled overrides', () {
    test('placedOverride null and inherit are equivalent', () {
      final catalog = _catalog([_profile('tree_large')]);
      final elementShadow = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
      );

      final absent = resolveShadowConfig(
        catalog: catalog,
        elementShadow: elementShadow,
      );
      final inherit = resolveShadowConfig(
        catalog: catalog,
        elementShadow: elementShadow,
        placedOverride: MapPlacedElementShadowOverride(),
      );

      expect(inherit, absent);
    });

    test('disabled always wins and emits no diagnostics', () {
      final resolution = resolveShadowConfig(
        catalog: _catalog([_profile('tree_large')]),
        elementShadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
        ),
        placedOverride: MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.disabled,
        ),
      );

      expect(resolution.resolved, isNull);
      expect(resolution.hasShadow, isFalse);
      expect(resolution.diagnostics, isEmpty);
    });
  });

  group('resolveShadowConfig custom instance overrides', () {
    test('custom shadowProfileId replaces the element profile', () {
      final resolution = resolveShadowConfig(
        catalog: _catalog([
          _profile('tree_large', offsetX: 1),
          _profile(
            'tree_short',
            mode: ShadowCasterMode.contactBlob,
            renderPass: ShadowRenderPass.actorContact,
            offsetX: 2,
            offsetY: 3,
            scaleX: 0.4,
            scaleY: 0.5,
            opacity: 0.6,
            colorHexRgb: 'ABCDEF',
          ),
        ]),
        elementShadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
        ),
        placedOverride: MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
          shadowProfileId: 'tree_short',
        ),
      );

      expect(resolution.resolved!.shadowProfileId, 'tree_short');
      expect(resolution.resolved!.mode, ShadowCasterMode.contactBlob);
      expect(resolution.resolved!.renderPass, ShadowRenderPass.actorContact);
      expect(resolution.resolved!.colorHexRgb, 'ABCDEF');
      expect(resolution.resolved!.softnessMode, ShadowSoftnessMode.hardEdge);
      expect(resolution.resolved!.offsetX, 2);
      expect(resolution.resolved!.opacity, 0.6);
    });

    test('custom numeric overrides replace values after element overrides', () {
      final resolution = resolveShadowConfig(
        catalog: _catalog([
          _profile(
            'tree_large',
            offsetX: 1,
            offsetY: 2,
            scaleX: 3,
            scaleY: 4,
            opacity: 0.5,
          ),
        ]),
        elementShadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
          offsetX: 10,
          offsetY: 20,
          scaleX: 0.8,
          scaleY: 0.3,
          opacity: 0.4,
        ),
        placedOverride: MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
          offsetX: 100,
          offsetY: 200,
          scaleX: 1.1,
          scaleY: 1.2,
          opacity: 0.2,
        ),
      );

      expect(resolution.resolved!.offsetX, 100);
      expect(resolution.resolved!.offsetY, 200);
      expect(resolution.resolved!.scaleX, 1.1);
      expect(resolution.resolved!.scaleY, 1.2);
      expect(resolution.resolved!.opacity, 0.2);
    });

    test('custom partial overrides keep remaining element/profile values', () {
      final resolution = resolveShadowConfig(
        catalog: _catalog([
          _profile(
            'tree_large',
            offsetX: 1,
            offsetY: 2,
            scaleX: 3,
            scaleY: 4,
            opacity: 0.5,
          ),
        ]),
        elementShadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
          offsetX: 10,
          scaleX: 0.8,
        ),
        placedOverride: MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
          opacity: 0.2,
        ),
      );

      expect(resolution.resolved!.offsetX, 10);
      expect(resolution.resolved!.offsetY, 2);
      expect(resolution.resolved!.scaleX, 0.8);
      expect(resolution.resolved!.scaleY, 4);
      expect(resolution.resolved!.opacity, 0.2);
    });

    test('custom without profile keeps the element profile', () {
      final resolution = resolveShadowConfig(
        catalog: _catalog([_profile('tree_large')]),
        elementShadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
        ),
        placedOverride: MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
          opacity: 0.2,
        ),
      );

      expect(resolution.resolved!.shadowProfileId, 'tree_large');
      expect(resolution.resolved!.opacity, 0.2);
    });

    test('custom with profile can activate when element has no active shadow',
        () {
      for (final elementShadow in <ProjectElementShadowConfig?>[
        null,
        ProjectElementShadowConfig(
          castsShadow: false,
          shadowProfileId: 'tree_large',
        ),
      ]) {
        final resolution = resolveShadowConfig(
          catalog: _catalog([_profile('rock_small')]),
          elementShadow: elementShadow,
          placedOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            shadowProfileId: 'rock_small',
          ),
        );

        expect(resolution.resolved!.shadowProfileId, 'rock_small');
        expect(resolution.diagnostics, isEmpty);
      }
    });
  });

  group('resolveShadowConfig diagnostics', () {
    test('missing element profile produces missingShadowProfile diagnostic',
        () {
      final resolution = resolveShadowConfig(
        catalog: ProjectShadowCatalog(),
        elementShadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'missing_tree',
        ),
      );

      expect(resolution.resolved, isNull);
      expect(resolution.diagnostics, hasLength(1));
      expect(
        resolution.diagnostics.single.kind,
        ShadowConfigResolutionDiagnosticKind.missingShadowProfile,
      );
      expect(resolution.diagnostics.single.shadowProfileId, 'missing_tree');
      expect(resolution.diagnostics.single.message, contains('missing_tree'));
    });

    test('missing custom override profile produces missingShadowProfile', () {
      final resolution = resolveShadowConfig(
        catalog: _catalog([_profile('tree_large')]),
        elementShadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
        ),
        placedOverride: MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
          shadowProfileId: 'missing_short',
        ),
      );

      expect(resolution.resolved, isNull);
      expect(
        resolution.diagnostics.single.kind,
        ShadowConfigResolutionDiagnosticKind.missingShadowProfile,
      );
      expect(resolution.diagnostics.single.shadowProfileId, 'missing_short');
    });

    test('custom numeric override without base produces diagnostic', () {
      for (final elementShadow in <ProjectElementShadowConfig?>[
        null,
        ProjectElementShadowConfig(
          castsShadow: false,
          shadowProfileId: 'tree_large',
        ),
      ]) {
        final resolution = resolveShadowConfig(
          catalog: _catalog([_profile('tree_large')]),
          elementShadow: elementShadow,
          placedOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            opacity: 0.2,
          ),
        );

        expect(resolution.resolved, isNull);
        expect(
          resolution.diagnostics.single.kind,
          ShadowConfigResolutionDiagnosticKind.customOverrideWithoutBaseProfile,
        );
        expect(resolution.diagnostics.single.shadowProfileId, isNull);
        expect(resolution.diagnostics.single.message, contains('custom'));
      }
    });

    test('empty custom override without base is none without diagnostics', () {
      final resolution = resolveShadowConfig(
        catalog: _catalog([_profile('tree_large')]),
        elementShadow: null,
        placedOverride: MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
        ),
      );

      expect(resolution.resolved, isNull);
      expect(resolution.diagnostics, isEmpty);
    });

    test('diagnostics list is immutable', () {
      final resolution = resolveShadowConfig(
        catalog: ProjectShadowCatalog(),
        elementShadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'missing_tree',
        ),
      );

      expect(
        () => resolution.diagnostics.add(
          const ShadowConfigResolutionDiagnostic(
            kind: ShadowConfigResolutionDiagnosticKind.missingShadowProfile,
            shadowProfileId: 'another',
            message: 'another',
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });

  group('resolveShadowConfig value equality', () {
    test('ResolvedShadowConfig equality and hashCode', () {
      const a = ResolvedShadowConfig(
        shadowProfileId: 'tree_large',
        mode: ShadowCasterMode.ellipse,
        renderPass: ShadowRenderPass.groundStatic,
        offsetX: 1,
        offsetY: 2,
        scaleX: 3,
        scaleY: 4,
        opacity: 0.5,
        colorHexRgb: '000000',
        softnessMode: ShadowSoftnessMode.hardEdge,
      );
      const b = ResolvedShadowConfig(
        shadowProfileId: 'tree_large',
        mode: ShadowCasterMode.ellipse,
        renderPass: ShadowRenderPass.groundStatic,
        offsetX: 1,
        offsetY: 2,
        scaleX: 3,
        scaleY: 4,
        opacity: 0.5,
        colorHexRgb: '000000',
        softnessMode: ShadowSoftnessMode.hardEdge,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('ShadowConfigResolution equality and hashCode', () {
      final diagnostic = const ShadowConfigResolutionDiagnostic(
        kind: ShadowConfigResolutionDiagnosticKind.missingShadowProfile,
        shadowProfileId: 'missing',
        message: 'missing',
      );
      final a = ShadowConfigResolution(
        resolved: null,
        diagnostics: [diagnostic],
      );
      final b = ShadowConfigResolution(
        resolved: null,
        diagnostics: [diagnostic],
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('ShadowConfigResolutionDiagnostic equality and hashCode', () {
      const a = ShadowConfigResolutionDiagnostic(
        kind: ShadowConfigResolutionDiagnosticKind.missingShadowProfile,
        shadowProfileId: 'missing',
        message: 'missing',
      );
      const b = ShadowConfigResolutionDiagnostic(
        kind: ShadowConfigResolutionDiagnosticKind.missingShadowProfile,
        shadowProfileId: 'missing',
        message: 'missing',
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('resolveShadowConfig side effects and scope', () {
    test('does not mutate input value objects', () {
      final catalog = _catalog([_profile('tree_large', opacity: 0.4)]);
      final elementShadow = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        opacity: 0.3,
      );
      final placedOverride = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        opacity: 0.2,
      );

      resolveShadowConfig(
        catalog: catalog,
        elementShadow: elementShadow,
        placedOverride: placedOverride,
      );

      expect(catalog.profileById('tree_large')!.opacity, 0.4);
      expect(elementShadow.opacity, 0.3);
      expect(placedOverride.opacity, 0.2);
    });

    test('generic resolver requires no ProjectManifest or MapPlacedElement',
        () {
      final resolution = resolveShadowConfig(
        catalog: _catalog([_profile('tree_large')]),
        elementShadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
        ),
        placedOverride: MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
          opacity: 0.2,
        ),
      );

      expect(resolution.resolved!.shadowProfileId, 'tree_large');
      expect(resolution.resolved!.opacity, 0.2);
    });
  });
}

ProjectShadowProfile _profile(
  String id, {
  ShadowCasterMode mode = ShadowCasterMode.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
  double offsetX = 0,
  double offsetY = 0,
  double scaleX = 1,
  double scaleY = 1,
  double opacity = 0.35,
  String colorHexRgb = '000000',
  ShadowSoftnessMode softnessMode = ShadowSoftnessMode.hardEdge,
}) {
  return ProjectShadowProfile(
    id: id,
    name: '$id shadow',
    mode: mode,
    renderPass: renderPass,
    offsetX: offsetX,
    offsetY: offsetY,
    scaleX: scaleX,
    scaleY: scaleY,
    opacity: opacity,
    colorHexRgb: colorHexRgb,
    softnessMode: softnessMode,
  );
}

ProjectShadowCatalog _catalog(List<ProjectShadowProfile> profiles) {
  return ProjectShadowCatalog(profiles: profiles);
}
