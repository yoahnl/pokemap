import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Projected building shadow diagnostics', () {
    test(
        'returns no diagnostics for active element referencing existing preset',
        () {
      final diagnostics = diagnoseProjectedBuildingShadows(
        _manifest(
          catalog: _catalog([
            _preset(id: 'short-west'),
          ]),
          elements: [
            _element(
              id: 'house',
              projectedBuildingShadow: _config(presetId: 'short-west'),
            ),
          ],
        ),
      );

      expect(diagnostics, isEmpty);
    });

    test('reports active missing preset as error', () {
      final diagnostics = diagnoseProjectedBuildingShadows(
        _manifest(
          catalog: _catalog(),
          elements: [
            _element(
              id: 'house',
              name: 'Blue Roof House',
              projectedBuildingShadow: _config(presetId: 'missing-preset'),
            ),
          ],
        ),
      );

      expect(diagnostics, hasLength(1));
      expect(
        diagnostics.single,
        ProjectedBuildingShadowDiagnostic(
          severity: ProjectedBuildingShadowDiagnosticSeverity.error,
          kind: ProjectedBuildingShadowDiagnosticKind.missingPreset,
          message:
              'Element "house" references missing projected building shadow preset "missing-preset".',
          elementId: 'house',
          elementName: 'Blue Roof House',
          presetId: 'missing-preset',
        ),
      );
    });

    test('reports disabled missing preset as warning', () {
      final diagnostics = diagnoseProjectedBuildingShadows(
        _manifest(
          catalog: _catalog(),
          elements: [
            _element(
              id: 'house',
              projectedBuildingShadow: _config(
                enabled: false,
                presetId: 'missing-preset',
              ),
            ),
          ],
        ),
      );

      expect(diagnostics, hasLength(1));
      expect(
        diagnostics.single,
        ProjectedBuildingShadowDiagnostic(
          severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
          kind: ProjectedBuildingShadowDiagnosticKind
              .missingPresetForDisabledConfig,
          message:
              'Element "house" has disabled projected building shadow config referencing missing preset "missing-preset".',
          elementId: 'house',
          elementName: 'House',
          presetId: 'missing-preset',
        ),
      );
    });

    test('reports unused preset as warning', () {
      final diagnostics = diagnoseProjectedBuildingShadows(
        _manifest(
          catalog: _catalog([
            _preset(id: 'unused', name: 'Unused shadow'),
          ]),
        ),
      );

      expect(diagnostics, hasLength(1));
      expect(
        diagnostics.single,
        ProjectedBuildingShadowDiagnostic(
          severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
          kind: ProjectedBuildingShadowDiagnosticKind.unusedPreset,
          message:
              'Projected building shadow preset "unused" is not referenced by any element.',
          presetId: 'unused',
          presetName: 'Unused shadow',
        ),
      );
    });

    test('disabled config counts as preset usage without extra noise', () {
      final diagnostics = diagnoseProjectedBuildingShadows(
        _manifest(
          catalog: _catalog([
            _preset(id: 'kept-disabled'),
          ]),
          elements: [
            _element(
              id: 'house',
              projectedBuildingShadow: _config(
                enabled: false,
                presetId: 'kept-disabled',
              ),
            ),
          ],
        ),
      );

      expect(diagnostics, isEmpty);
    });

    test('reports V1 and enabled V2 coexistence as warning', () {
      final diagnostics = diagnoseProjectedBuildingShadows(
        _manifest(
          catalog: _catalog([
            _preset(id: 'short-west', name: 'Short west'),
          ]),
          elements: [
            _element(
              id: 'house',
              name: 'Blue Roof House',
              shadow: _v1Shadow(),
              projectedBuildingShadow: _config(presetId: 'short-west'),
            ),
          ],
        ),
      );

      expect(diagnostics, hasLength(1));
      expect(
        diagnostics.single,
        ProjectedBuildingShadowDiagnostic(
          severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
          kind: ProjectedBuildingShadowDiagnosticKind.v1AndV2Coexistence,
          message:
              'Element "house" has both Shadow V1 and enabled projected building shadow V2.',
          elementId: 'house',
          elementName: 'Blue Roof House',
          presetId: 'short-west',
          presetName: 'Short west',
        ),
      );
    });

    test('reports coexistence for any non-null V1 shadow config', () {
      final diagnostics = diagnoseProjectedBuildingShadows(
        _manifest(
          catalog: _catalog([
            _preset(id: 'short-west'),
          ]),
          elements: [
            _element(
              id: 'house',
              shadow: _v1Shadow(castsShadow: false),
              projectedBuildingShadow: _config(presetId: 'short-west'),
            ),
          ],
        ),
      );

      expect(
        diagnostics.map((diagnostic) => diagnostic.kind),
        contains(ProjectedBuildingShadowDiagnosticKind.v1AndV2Coexistence),
      );
    });

    test('does not report V1 and V2 coexistence when V2 is disabled', () {
      final diagnostics = diagnoseProjectedBuildingShadows(
        _manifest(
          catalog: _catalog([
            _preset(id: 'short-west'),
          ]),
          elements: [
            _element(
              id: 'house',
              shadow: _v1Shadow(),
              projectedBuildingShadow: _config(
                enabled: false,
                presetId: 'short-west',
              ),
            ),
          ],
        ),
      );

      expect(
        diagnostics
            .where(
              (diagnostic) =>
                  diagnostic.kind ==
                  ProjectedBuildingShadowDiagnosticKind.v1AndV2Coexistence,
            )
            .toList(),
        isEmpty,
      );
    });

    test('reports active followsSun preset as info', () {
      final diagnostics = diagnoseProjectedBuildingShadows(
        _manifest(
          catalog: _catalog([
            _preset(
              id: 'sun-following',
              name: 'Sun following shadow',
              timeOfDayMode: ProjectedShadowTimeOfDayMode.followsSun,
            ),
          ]),
          elements: [
            _element(
              id: 'tower',
              projectedBuildingShadow: _config(presetId: 'sun-following'),
            ),
          ],
        ),
      );

      expect(diagnostics, hasLength(1));
      expect(
        diagnostics.single,
        ProjectedBuildingShadowDiagnostic(
          severity: ProjectedBuildingShadowDiagnosticSeverity.info,
          kind:
              ProjectedBuildingShadowDiagnosticKind.followsSunWithoutTimeOfDay,
          message:
              'Projected building shadow preset "sun-following" follows the sun, but no time-of-day system is active yet.',
          presetId: 'sun-following',
          presetName: 'Sun following shadow',
        ),
      );
    });

    test('reports followsSun unused preset only as unused warning', () {
      final diagnostics = diagnoseProjectedBuildingShadows(
        _manifest(
          catalog: _catalog([
            _preset(
              id: 'sun-following',
              timeOfDayMode: ProjectedShadowTimeOfDayMode.followsSun,
            ),
          ]),
        ),
      );

      expect(diagnostics, hasLength(1));
      expect(
        diagnostics.single.kind,
        ProjectedBuildingShadowDiagnosticKind.unusedPreset,
      );
    });

    test('does not report followsSun when referenced only by disabled configs',
        () {
      final diagnostics = diagnoseProjectedBuildingShadows(
        _manifest(
          catalog: _catalog([
            _preset(
              id: 'sun-following',
              timeOfDayMode: ProjectedShadowTimeOfDayMode.followsSun,
            ),
          ]),
          elements: [
            _element(
              id: 'tower',
              projectedBuildingShadow: _config(
                enabled: false,
                presetId: 'sun-following',
              ),
            ),
          ],
        ),
      );

      expect(diagnostics, isEmpty);
    });

    test('keeps stable element diagnostics then catalog diagnostics order', () {
      final diagnostics = diagnoseProjectedBuildingShadows(
        _manifest(
          catalog: _catalog([
            _preset(id: 'used'),
            _preset(id: 'unused-a'),
            _preset(
              id: 'sun-following',
              timeOfDayMode: ProjectedShadowTimeOfDayMode.followsSun,
            ),
            _preset(id: 'unused-b'),
          ]),
          elements: [
            _element(
              id: 'missing-active',
              projectedBuildingShadow: _config(presetId: 'missing-a'),
            ),
            _element(
              id: 'coexisting',
              shadow: _v1Shadow(),
              projectedBuildingShadow: _config(presetId: 'used'),
            ),
            _element(
              id: 'missing-disabled',
              projectedBuildingShadow: _config(
                enabled: false,
                presetId: 'missing-b',
              ),
            ),
            _element(
              id: 'sun-user',
              projectedBuildingShadow: _config(presetId: 'sun-following'),
            ),
          ],
        ),
      );

      expect(
        diagnostics.map((diagnostic) => diagnostic.kind).toList(),
        [
          ProjectedBuildingShadowDiagnosticKind.missingPreset,
          ProjectedBuildingShadowDiagnosticKind.v1AndV2Coexistence,
          ProjectedBuildingShadowDiagnosticKind.missingPresetForDisabledConfig,
          ProjectedBuildingShadowDiagnosticKind.unusedPreset,
          ProjectedBuildingShadowDiagnosticKind.followsSunWithoutTimeOfDay,
          ProjectedBuildingShadowDiagnosticKind.unusedPreset,
        ],
      );
      expect(
        diagnostics.map((diagnostic) => diagnostic.elementId).toList(),
        [
          'missing-active',
          'coexisting',
          'missing-disabled',
          null,
          null,
          null,
        ],
      );
      expect(
        diagnostics.map((diagnostic) => diagnostic.presetId).toList(),
        [
          'missing-a',
          'used',
          'missing-b',
          'unused-a',
          'sun-following',
          'unused-b',
        ],
      );
    });

    test('diagnostic equality includes all fields', () {
      const base = ProjectedBuildingShadowDiagnostic(
        severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
        kind: ProjectedBuildingShadowDiagnosticKind.unusedPreset,
        message: 'message',
        elementId: 'element',
        elementName: 'Element',
        presetId: 'preset',
        presetName: 'Preset',
      );

      expect(
        base,
        const ProjectedBuildingShadowDiagnostic(
          severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
          kind: ProjectedBuildingShadowDiagnosticKind.unusedPreset,
          message: 'message',
          elementId: 'element',
          elementName: 'Element',
          presetId: 'preset',
          presetName: 'Preset',
        ),
      );
      expect(
        base.hashCode,
        const ProjectedBuildingShadowDiagnostic(
          severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
          kind: ProjectedBuildingShadowDiagnosticKind.unusedPreset,
          message: 'message',
          elementId: 'element',
          elementName: 'Element',
          presetId: 'preset',
          presetName: 'Preset',
        ).hashCode,
      );
      expect(
        base,
        isNot(
          const ProjectedBuildingShadowDiagnostic(
            severity: ProjectedBuildingShadowDiagnosticSeverity.error,
            kind: ProjectedBuildingShadowDiagnosticKind.unusedPreset,
            message: 'message',
            elementId: 'element',
            elementName: 'Element',
            presetId: 'preset',
            presetName: 'Preset',
          ),
        ),
      );
      expect(
        base,
        isNot(
          const ProjectedBuildingShadowDiagnostic(
            severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
            kind: ProjectedBuildingShadowDiagnosticKind.missingPreset,
            message: 'message',
            elementId: 'element',
            elementName: 'Element',
            presetId: 'preset',
            presetName: 'Preset',
          ),
        ),
      );
      expect(
        base,
        isNot(
          const ProjectedBuildingShadowDiagnostic(
            severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
            kind: ProjectedBuildingShadowDiagnosticKind.unusedPreset,
            message: 'different',
            elementId: 'element',
            elementName: 'Element',
            presetId: 'preset',
            presetName: 'Preset',
          ),
        ),
      );
      expect(
        base,
        isNot(
          const ProjectedBuildingShadowDiagnostic(
            severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
            kind: ProjectedBuildingShadowDiagnosticKind.unusedPreset,
            message: 'message',
            elementId: 'different',
            elementName: 'Element',
            presetId: 'preset',
            presetName: 'Preset',
          ),
        ),
      );
      expect(
        base,
        isNot(
          const ProjectedBuildingShadowDiagnostic(
            severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
            kind: ProjectedBuildingShadowDiagnosticKind.unusedPreset,
            message: 'message',
            elementId: 'element',
            elementName: 'Different',
            presetId: 'preset',
            presetName: 'Preset',
          ),
        ),
      );
      expect(
        base,
        isNot(
          const ProjectedBuildingShadowDiagnostic(
            severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
            kind: ProjectedBuildingShadowDiagnosticKind.unusedPreset,
            message: 'message',
            elementId: 'element',
            elementName: 'Element',
            presetId: 'different',
            presetName: 'Preset',
          ),
        ),
      );
      expect(
        base,
        isNot(
          const ProjectedBuildingShadowDiagnostic(
            severity: ProjectedBuildingShadowDiagnosticSeverity.warning,
            kind: ProjectedBuildingShadowDiagnosticKind.unusedPreset,
            message: 'message',
            elementId: 'element',
            elementName: 'Element',
            presetId: 'preset',
            presetName: 'Different',
          ),
        ),
      );
    });

    test('returned diagnostics list is unmodifiable', () {
      final diagnostics = diagnoseProjectedBuildingShadows(
        _manifest(
          catalog: _catalog([
            _preset(id: 'unused'),
          ]),
        ),
      );

      expect(
        () => diagnostics.add(
          const ProjectedBuildingShadowDiagnostic(
            severity: ProjectedBuildingShadowDiagnosticSeverity.info,
            kind: ProjectedBuildingShadowDiagnosticKind.unusedPreset,
            message: 'extra',
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });
}

ProjectManifest _manifest({
  ProjectBuildingShadowPresetCatalog? catalog,
  List<ProjectElementEntry> elements = const [],
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    elements: elements,
    surfaceCatalog: ProjectSurfaceCatalog(),
    projectedBuildingShadowCatalog:
        catalog ?? const ProjectBuildingShadowPresetCatalog.empty(),
  );
}

ProjectBuildingShadowPresetCatalog _catalog([
  List<ProjectBuildingShadowPreset> presets = const [],
]) {
  return ProjectBuildingShadowPresetCatalog(presets: presets);
}

ProjectBuildingShadowPreset _preset({
  required String id,
  String? name,
  ProjectedShadowTimeOfDayMode timeOfDayMode =
      ProjectedShadowTimeOfDayMode.fixed,
}) {
  return ProjectBuildingShadowPreset(
    id: id,
    name: name ?? 'Shadow $id',
    direction: ProjectedShadowDirection(x: -0.55, y: 0.35),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.28,
      nearWidthRatio: 0.85,
      farWidthRatio: 0.75,
    ),
    appearance: ProjectedShadowAppearance(opacity: 0.18),
    timeOfDayMode: timeOfDayMode,
  );
}

ProjectElementEntry _element({
  required String id,
  String? name,
  ProjectElementShadowConfig? shadow,
  ProjectElementProjectedBuildingShadowConfig? projectedBuildingShadow,
}) {
  return ProjectElementEntry(
    id: id,
    name: name ?? _title(id),
    tilesetId: 'tileset',
    categoryId: 'building',
    frames: const [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0),
      ),
    ],
    shadow: shadow,
    projectedBuildingShadow: projectedBuildingShadow,
  );
}

ProjectElementProjectedBuildingShadowConfig _config({
  bool enabled = true,
  required String presetId,
}) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: enabled,
    presetId: presetId,
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.98),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
}

ProjectElementShadowConfig _v1Shadow({bool castsShadow = true}) {
  return ProjectElementShadowConfig(
    castsShadow: castsShadow,
    shadowProfileId: 'default-shadow',
  );
}

String _title(String id) {
  final words = id.split('-');
  return words
      .map((word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
