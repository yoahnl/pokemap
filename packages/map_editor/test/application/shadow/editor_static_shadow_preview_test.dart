import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/editor_shadow_light_preview.dart';
import 'package:map_editor/src/application/shadow/editor_static_shadow_preview.dart';

void main() {
  group('buildEditorStaticShadowPreviewInstructions', () {
    test('builds a projected groundStatic instruction', () {
      final instructions = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(),
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
      );

      expect(instructions, hasLength(1));
      final instruction = instructions.single;
      expect(instruction.instanceId, 'layer::1::2');
      expect(instruction.elementId, 'stand');
      expect(instruction.colorHexRgb, '000000');
      _expectProjectedInstructionMatchesCore(
        instruction: instruction,
        shadowConfig: _resolvedConfig(),
        metrics: _defaultMetrics(),
      );
    });

    test('neutral light preview matches the runtime default projection', () {
      final instructions = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(),
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
        lightPreviewPreset: editorShadowLightPreviewPresetById('neutral'),
      );

      final instruction = instructions.single;
      _expectProjectedInstructionMatchesCore(
        instruction: instruction,
        shadowConfig: _resolvedConfig(),
        metrics: _defaultMetrics(),
      );
    });

    test('noon light preview shortens the projected polygon once', () {
      final neutral = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(),
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
        lightPreviewPreset: editorShadowLightPreviewPresetById('neutral'),
      ).single;
      final noon = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(),
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
        lightPreviewPreset: editorShadowLightPreviewPresetById('noon'),
      ).single;

      expect(_projectionLength(noon), lessThan(_projectionLength(neutral)));
      expect(noon.opacity, lessThan(neutral.opacity));
    });

    test('morning and evening light previews shift in opposite directions', () {
      final morning = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(),
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
        lightPreviewPreset: editorShadowLightPreviewPresetById('morning'),
      ).single;
      final evening = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(),
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
        lightPreviewPreset: editorShadowLightPreviewPresetById('evening'),
      ).single;

      expect(_farCenterX(morning), greaterThan(_nearCenterX(morning)));
      expect(_farCenterX(evening), lessThan(_nearCenterX(evening)));
      expect(_farCenterY(morning), greaterThan(_nearCenterY(morning)));
      expect(_farCenterY(evening), greaterThan(_nearCenterY(evening)));
    });

    test('contactBlob groundStatic produces a projected preview instruction',
        () {
      final instructions = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(
          profile: _profile(
            'base_shadow',
            mode: ShadowCasterMode.contactBlob,
          ),
        ),
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
      );

      expect(
        instructions.single.shape,
        EditorStaticShadowPreviewShapeKind.projectedPolygon,
      );
    });

    test('ignores empty catalog and missing profiles', () {
      expect(
        buildEditorStaticShadowPreviewInstructions(
          manifest: _manifest(catalog: const ProjectShadowCatalog.empty()),
          map: _map(),
          tileWidth: 16,
          tileHeight: 16,
        ),
        isEmpty,
      );
      expect(
        buildEditorStaticShadowPreviewInstructions(
          manifest: _manifest(
            elementShadow: ProjectElementShadowConfig(
              castsShadow: true,
              shadowProfileId: 'missing',
            ),
          ),
          map: _map(),
          tileWidth: 16,
          tileHeight: 16,
        ),
        isEmpty,
      );
    });

    test('ignores missing disabled incompatible and invalid sources', () {
      expect(
        buildEditorStaticShadowPreviewInstructions(
          manifest: _manifest(omitElementShadow: true),
          map: _map(),
          tileWidth: 16,
          tileHeight: 16,
        ),
        isEmpty,
      );
      expect(
        buildEditorStaticShadowPreviewInstructions(
          manifest: _manifest(
            elementShadow: ProjectElementShadowConfig(castsShadow: false),
          ),
          map: _map(),
          tileWidth: 16,
          tileHeight: 16,
        ),
        isEmpty,
      );
      expect(
        buildEditorStaticShadowPreviewInstructions(
          manifest: _manifest(
            profile: _profile(
              'base_shadow',
              mode: ShadowCasterMode.contactBlob,
              renderPass: ShadowRenderPass.actorContact,
            ),
          ),
          map: _map(),
          tileWidth: 16,
          tileHeight: 16,
        ),
        isEmpty,
      );
      expect(
        buildEditorStaticShadowPreviewInstructions(
          manifest: _manifest(
            profile: _profile('base_shadow', mode: ShadowCasterMode.none),
          ),
          map: _map(),
          tileWidth: 16,
          tileHeight: 16,
        ),
        isEmpty,
      );
      expect(
        buildEditorStaticShadowPreviewInstructions(
          manifest: _manifest(frames: const []),
          map: _map(),
          tileWidth: 16,
          tileHeight: 16,
        ),
        isEmpty,
      );
      expect(
        buildEditorStaticShadowPreviewInstructions(
          manifest: _manifest(
            frames: const [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 0),
              ),
            ],
          ),
          map: _map(),
          tileWidth: 16,
          tileHeight: 16,
        ),
        isEmpty,
      );
    });

    test('ignores invisible tile layers', () {
      final instructions = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(),
        map: _map(layerVisible: false),
        tileWidth: 16,
        tileHeight: 16,
      );

      expect(instructions, isEmpty);
    });

    test('applies disabled and custom overrides', () {
      expect(
        buildEditorStaticShadowPreviewInstructions(
          manifest: _manifest(),
          map: _map(
            shadowOverride: MapPlacedElementShadowOverride(
              mode: ShadowOverrideMode.disabled,
            ),
          ),
          tileWidth: 16,
          tileHeight: 16,
        ),
        isEmpty,
      );

      final instructions = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(),
        map: _map(
          shadowOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            offsetX: 4,
            offsetY: -2,
            scaleX: 2,
            scaleY: 0.5,
            opacity: 0.2,
          ),
        ),
        tileWidth: 16,
        tileHeight: 16,
      );

      final instruction = instructions.single;
      _expectProjectedInstructionMatchesCore(
        instruction: instruction,
        shadowConfig: _resolvedConfig(
          offsetX: 4,
          offsetY: -2,
          scaleX: 2,
          scaleY: 0.5,
          opacity: 0.2,
        ),
        metrics: _defaultMetrics(),
        opacity: 0.2,
      );
    });

    test(
        'skips legacy static shadow preview when same element has resolvable projected building shadow',
        () {
      final instructions = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(
          projectedBuildingShadow: _projectedConfig(),
          includeProjectedPreset: true,
        ),
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
      );

      expect(instructions, isEmpty);
    });

    test(
        'skips legacy static shadow preview when same element has resolvable footprint projected building shadow',
        () {
      final instructions = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(
          projectedBuildingShadow: _projectedConfig(
            presetId: 'pokemon-building-shadow-footprint-v0',
          ),
          includeProjectedPreset: true,
          projectedPreset: _projectedFootprintPreset(),
        ),
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
      );

      expect(instructions, isEmpty);
    });

    test(
        'keeps legacy static shadow preview when element has no projected building shadow',
        () {
      final instructions = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(),
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
      );

      expect(instructions, hasLength(1));
    });

    test(
        'keeps legacy static shadow preview when projected building shadow is disabled',
        () {
      final instructions = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(
          projectedBuildingShadow: _projectedConfig(enabled: false),
          includeProjectedPreset: true,
        ),
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
      );

      expect(instructions, hasLength(1));
    });

    test(
        'keeps legacy static shadow preview when projected building shadow preset is missing',
        () {
      final instructions = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(projectedBuildingShadow: _projectedConfig()),
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
      );

      expect(instructions, hasLength(1));
    });

    test(
        'skips custom placed legacy shadow preview override when same element has resolvable projected building shadow',
        () {
      final instructions = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(
          projectedBuildingShadow: _projectedConfig(),
          includeProjectedPreset: true,
        ),
        map: _map(
          shadowOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            shadowProfileId: 'base_shadow',
            opacity: 0.2,
          ),
        ),
        tileWidth: 16,
        tileHeight: 16,
      );

      expect(instructions, isEmpty);
    });

    test('uses element footprint for preview anchor and size', () {
      final instructions = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(
          elementShadow: ProjectElementShadowConfig(
            castsShadow: true,
            shadowProfileId: 'base_shadow',
            footprint: StaticShadowFootprintConfig(
              anchorXRatio: 0.25,
              anchorYRatio: 0.75,
              footprintWidthRatio: 0.5,
              footprintHeightRatio: 0.125,
            ),
          ),
        ),
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
      );

      final instruction = instructions.single;
      _expectProjectedInstructionMatchesCore(
        instruction: instruction,
        shadowConfig: _resolvedConfig(),
        metrics: _defaultMetrics(),
        elementFootprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.25,
          anchorYRatio: 0.75,
          footprintWidthRatio: 0.5,
          footprintHeightRatio: 0.125,
        ),
      );
    });

    test('uses override footprint over element footprint field by field', () {
      final elementFootprint = StaticShadowFootprintConfig(
        anchorXRatio: 0.25,
        anchorYRatio: 0.75,
        footprintWidthRatio: 0.5,
        footprintHeightRatio: 0.125,
      );
      final overrideFootprint = StaticShadowFootprintConfig(
        anchorYRatio: 0.5,
        footprintWidthRatio: 0.25,
      );
      final instructions = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(
          elementShadow: ProjectElementShadowConfig(
            castsShadow: true,
            shadowProfileId: 'base_shadow',
            footprint: elementFootprint,
          ),
        ),
        map: _map(
          shadowOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            footprint: overrideFootprint,
          ),
        ),
        tileWidth: 16,
        tileHeight: 16,
      );

      final instruction = instructions.single;
      _expectProjectedInstructionMatchesCore(
        instruction: instruction,
        shadowConfig: _resolvedConfig(),
        metrics: _defaultMetrics(),
        elementFootprint: elementFootprint,
        overrideFootprint: overrideFootprint,
      );
    });

    test('custom override without footprint keeps element footprint', () {
      final elementFootprint = StaticShadowFootprintConfig(
        anchorXRatio: 0.5,
        anchorYRatio: 0.5,
        footprintWidthRatio: 0.5,
        footprintHeightRatio: 0.5,
      );
      final instructions = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(
          elementShadow: ProjectElementShadowConfig(
            castsShadow: true,
            shadowProfileId: 'base_shadow',
            footprint: elementFootprint,
          ),
        ),
        map: _map(
          shadowOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            offsetX: 4,
            offsetY: -2,
            scaleX: 2,
            scaleY: 0.5,
          ),
        ),
        tileWidth: 16,
        tileHeight: 16,
      );

      final instruction = instructions.single;
      _expectProjectedInstructionMatchesCore(
        instruction: instruction,
        shadowConfig: _resolvedConfig(
          offsetX: 4,
          offsetY: -2,
          scaleX: 2,
          scaleY: 0.5,
        ),
        metrics: _defaultMetrics(),
        elementFootprint: elementFootprint,
      );
    });

    test('building family emits a contact ledge preview matching core', () {
      final footprint = StaticShadowFootprintConfig(
        footprintWidthRatio: 0.25,
        footprintHeightRatio: 0.08,
      );
      final tallProp = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(
          elementShadow: ProjectElementShadowConfig(
            castsShadow: true,
            shadowProfileId: 'base_shadow',
            family: StaticShadowFamily.tallProp,
            footprint: footprint,
          ),
        ),
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
      ).single;
      final building = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(
          elementShadow: ProjectElementShadowConfig(
            castsShadow: true,
            shadowProfileId: 'base_shadow',
            family: StaticShadowFamily.building,
            footprint: footprint,
          ),
        ),
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
      ).single;

      _expectBuildingInstructionMatchesCoreContactLedge(
        instruction: building,
        shadowConfig: _resolvedConfig(),
        metrics: _defaultMetrics(),
        elementFootprint: footprint,
      );
      expect(tallProp.polygonPoints, isNot(building.polygonPoints));
    });

    test('override building family wins over element family in preview', () {
      final footprint = StaticShadowFootprintConfig(
        footprintWidthRatio: 0.25,
        footprintHeightRatio: 0.08,
      );
      final overrideBuilding = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(
          elementShadow: ProjectElementShadowConfig(
            castsShadow: true,
            shadowProfileId: 'base_shadow',
            family: StaticShadowFamily.tallProp,
            footprint: footprint,
          ),
        ),
        map: _map(
          shadowOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            family: StaticShadowFamily.building,
          ),
        ),
        tileWidth: 16,
        tileHeight: 16,
      ).single;
      final building = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(
          elementShadow: ProjectElementShadowConfig(
            castsShadow: true,
            shadowProfileId: 'base_shadow',
            family: StaticShadowFamily.building,
            footprint: footprint,
          ),
        ),
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
      ).single;

      _expectBuildingInstructionMatchesCoreContactLedge(
        instruction: overrideBuilding,
        shadowConfig: _resolvedConfig(),
        metrics: _defaultMetrics(),
        elementFootprint: footprint,
      );
      expect(overrideBuilding.polygonPoints, building.polygonPoints);
    });

    test(
        'building contact ledge ignores light direction but keeps opacity preview',
        () {
      final manifest = _manifest(
        elementShadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'base_shadow',
          family: StaticShadowFamily.building,
          footprint: StaticShadowFootprintConfig(
            footprintWidthRatio: 0.25,
            footprintHeightRatio: 0.08,
          ),
        ),
      );
      final neutral = buildEditorStaticShadowPreviewInstructions(
        manifest: manifest,
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
        lightPreviewPreset: editorShadowLightPreviewPresetById('neutral'),
      ).single;
      final morning = buildEditorStaticShadowPreviewInstructions(
        manifest: manifest,
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
        lightPreviewPreset: editorShadowLightPreviewPresetById('morning'),
      ).single;

      expect(morning.polygonPoints, neutral.polygonPoints);
      expect(morning.left, closeTo(neutral.left, 0.001));
      expect(morning.top, closeTo(neutral.top, 0.001));
      expect(morning.width, closeTo(neutral.width, 0.001));
      expect(morning.height, closeTo(neutral.height, 0.001));
      expect(morning.opacity, closeTo(0.315, 0.001));
    });

    test('custom profile overrides source profile and null profile inherits it',
        () {
      final overrideProfile = _profile(
        'wide_shadow',
        scaleX: 1.5,
        opacity: 0.1,
        colorHexRgb: '112233',
      );
      final overridden = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(
          catalog: ProjectShadowCatalog(
            profiles: [_profile('base_shadow'), overrideProfile],
          ),
        ),
        map: _map(
          shadowOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            shadowProfileId: 'wide_shadow',
          ),
        ),
        tileWidth: 16,
        tileHeight: 16,
      ).single;

      expect(overridden.opacity, 0.1);
      expect(overridden.colorHexRgb, '112233');
      _expectProjectedInstructionMatchesCore(
        instruction: overridden,
        shadowConfig: _resolvedConfig(
          shadowProfileId: 'wide_shadow',
          scaleX: 1.5,
          opacity: 0.1,
          colorHexRgb: '112233',
        ),
        metrics: _defaultMetrics(),
        opacity: 0.1,
      );

      final inherited = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(),
        map: _map(
          shadowOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
          ),
        ),
        tileWidth: 16,
        tileHeight: 16,
      ).single;

      expect(inherited.colorHexRgb, '000000');
      _expectProjectedInstructionMatchesCore(
        instruction: inherited,
        shadowConfig: _resolvedConfig(),
        metrics: _defaultMetrics(),
      );
    });

    test('preserves source order and opacity zero instructions', () {
      final instructions = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(
          profile: _profile('base_shadow', opacity: 0),
        ),
        map: _map(
          placedElements: const [
            MapPlacedElement(
              id: 'first',
              layerId: 'layer',
              elementId: 'stand',
              pos: GridPos(x: 0, y: 0),
            ),
            MapPlacedElement(
              id: 'second',
              layerId: 'layer',
              elementId: 'stand',
              pos: GridPos(x: 1, y: 0),
            ),
          ],
        ),
        tileWidth: 16,
        tileHeight: 16,
      );

      expect(instructions.map((instruction) => instruction.instanceId), [
        'first',
        'second',
      ]);
      expect(instructions.first.opacity, 0);
    });

    test('instruction equality and hashCode include polygon points', () {
      final first = EditorStaticShadowPreviewInstruction(
        instanceId: 'stand_1',
        elementId: 'stand',
        shape: EditorStaticShadowPreviewShapeKind.projectedPolygon,
        left: 0,
        top: 0,
        width: 10,
        height: 10,
        opacity: 0.5,
        colorHexRgb: '000000',
        polygonPoints: [
          EditorStaticShadowPreviewPoint(x: 0, y: 0),
          EditorStaticShadowPreviewPoint(x: 10, y: 0),
          EditorStaticShadowPreviewPoint(x: 10, y: 10),
        ],
      );
      final same = EditorStaticShadowPreviewInstruction(
        instanceId: 'stand_1',
        elementId: 'stand',
        shape: EditorStaticShadowPreviewShapeKind.projectedPolygon,
        left: 0,
        top: 0,
        width: 10,
        height: 10,
        opacity: 0.5,
        colorHexRgb: '000000',
        polygonPoints: [
          EditorStaticShadowPreviewPoint(x: 0, y: 0),
          EditorStaticShadowPreviewPoint(x: 10, y: 0),
          EditorStaticShadowPreviewPoint(x: 10, y: 10),
        ],
      );
      final different = EditorStaticShadowPreviewInstruction(
        instanceId: 'stand_1',
        elementId: 'stand',
        shape: EditorStaticShadowPreviewShapeKind.projectedPolygon,
        left: 0,
        top: 0,
        width: 10,
        height: 10,
        opacity: 0.5,
        colorHexRgb: '000000',
        polygonPoints: [
          EditorStaticShadowPreviewPoint(x: 0, y: 0),
          EditorStaticShadowPreviewPoint(x: 10, y: 0),
          EditorStaticShadowPreviewPoint(x: 8, y: 10),
        ],
      );

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(different));
    });

    test('projected instruction rejects degenerate polygon points', () {
      expect(
        () => EditorStaticShadowPreviewInstruction(
          instanceId: 'stand_1',
          elementId: 'stand',
          shape: EditorStaticShadowPreviewShapeKind.projectedPolygon,
          left: 0,
          top: 0,
          width: 10,
          height: 10,
          opacity: 0.5,
          colorHexRgb: '000000',
          polygonPoints: [
            EditorStaticShadowPreviewPoint(x: 0, y: 0),
            EditorStaticShadowPreviewPoint(x: 5, y: 0),
            EditorStaticShadowPreviewPoint(x: 10, y: 0),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

void _expectProjectedInstructionMatchesCore({
  required EditorStaticShadowPreviewInstruction instruction,
  required ResolvedShadowConfig shadowConfig,
  required StaticShadowVisualMetrics metrics,
  StaticShadowFootprintConfig? elementFootprint,
  StaticShadowFootprintConfig? overrideFootprint,
  StaticShadowProjectionSpec projectionSpec = defaultStaticShadowProjectionSpec,
  double opacity = 0.35,
}) {
  final baseGeometry = resolveStaticShadowGeometry(
    metrics: metrics,
    shadowConfig: shadowConfig,
    elementFootprint: elementFootprint,
    overrideFootprint: overrideFootprint,
  );
  final projected = resolveProjectedStaticShadowGeometry(
    baseGeometry: baseGeometry,
    metrics: metrics,
    projectionSpec: projectionSpec,
  );
  final bounds = _testBounds(projected.points);

  expect(
      instruction.shape, EditorStaticShadowPreviewShapeKind.projectedPolygon);
  expect(instruction.opacity, closeTo(opacity, 0.001));
  expect(instruction.left, closeTo(bounds.left, 0.001));
  expect(instruction.top, closeTo(bounds.top, 0.001));
  expect(instruction.width, closeTo(bounds.width, 0.001));
  expect(instruction.height, closeTo(bounds.height, 0.001));
  expect(instruction.polygonPoints, hasLength(projected.points.length));
  for (var i = 0; i < projected.points.length; i += 1) {
    expect(
        instruction.polygonPoints[i].x, closeTo(projected.points[i].x, 0.001));
    expect(
        instruction.polygonPoints[i].y, closeTo(projected.points[i].y, 0.001));
  }
}

void _expectBuildingInstructionMatchesCoreContactLedge({
  required EditorStaticShadowPreviewInstruction instruction,
  required ResolvedShadowConfig shadowConfig,
  required StaticShadowVisualMetrics metrics,
  StaticShadowFootprintConfig? elementFootprint,
  StaticShadowFootprintConfig? overrideFootprint,
  double opacity = 0.35,
}) {
  final baseGeometry = resolveStaticShadowGeometry(
    metrics: metrics,
    shadowConfig: shadowConfig,
    elementFootprint: elementFootprint,
    overrideFootprint: overrideFootprint,
  );
  final ledge = resolveBuildingStaticShadowContactLedgeGeometry(
    baseGeometry: baseGeometry,
    metrics: metrics,
  );
  final bounds = _testBounds(ledge.points);

  expect(
    instruction.shape,
    EditorStaticShadowPreviewShapeKind.projectedPolygon,
  );
  expect(instruction.opacity, closeTo(opacity, 0.001));
  expect(instruction.left, closeTo(bounds.left, 0.001));
  expect(instruction.top, closeTo(bounds.top, 0.001));
  expect(instruction.width, closeTo(bounds.width, 0.001));
  expect(instruction.height, closeTo(bounds.height, 0.001));
  expect(instruction.polygonPoints, hasLength(ledge.points.length));
  for (var i = 0; i < ledge.points.length; i += 1) {
    expect(instruction.polygonPoints[i].x, closeTo(ledge.points[i].x, 0.001));
    expect(instruction.polygonPoints[i].y, closeTo(ledge.points[i].y, 0.001));
  }
}

StaticShadowVisualMetrics _defaultMetrics() {
  return StaticShadowVisualMetrics(
    left: 16,
    top: 32,
    visualWidth: 32,
    visualHeight: 64,
  );
}

ResolvedShadowConfig _resolvedConfig({
  String shadowProfileId = 'base_shadow',
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
  return ResolvedShadowConfig(
    shadowProfileId: shadowProfileId,
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

double _projectionLength(EditorStaticShadowPreviewInstruction instruction) {
  return _distance(
    _nearCenterX(instruction),
    _nearCenterY(instruction),
    _farCenterX(instruction),
    _farCenterY(instruction),
  );
}

double _nearCenterX(EditorStaticShadowPreviewInstruction instruction) {
  return (instruction.polygonPoints[0].x + instruction.polygonPoints[1].x) / 2;
}

double _nearCenterY(EditorStaticShadowPreviewInstruction instruction) {
  return (instruction.polygonPoints[0].y + instruction.polygonPoints[1].y) / 2;
}

double _farCenterX(EditorStaticShadowPreviewInstruction instruction) {
  return (instruction.polygonPoints[2].x + instruction.polygonPoints[3].x) / 2;
}

double _farCenterY(EditorStaticShadowPreviewInstruction instruction) {
  return (instruction.polygonPoints[2].y + instruction.polygonPoints[3].y) / 2;
}

double _distance(double x1, double y1, double x2, double y2) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  return dx.abs() + dy.abs();
}

_TestBounds _testBounds(List<ProjectedStaticShadowPoint> points) {
  var minX = points.first.x;
  var maxX = points.first.x;
  var minY = points.first.y;
  var maxY = points.first.y;
  for (final point in points.skip(1)) {
    if (point.x < minX) {
      minX = point.x;
    }
    if (point.x > maxX) {
      maxX = point.x;
    }
    if (point.y < minY) {
      minY = point.y;
    }
    if (point.y > maxY) {
      maxY = point.y;
    }
  }
  return _TestBounds(
    left: minX,
    top: minY,
    width: maxX - minX,
    height: maxY - minY,
  );
}

final class _TestBounds {
  const _TestBounds({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;
}

ProjectManifest _manifest({
  ProjectShadowCatalog? catalog,
  ProjectShadowProfile? profile,
  ProjectElementShadowConfig? elementShadow,
  ProjectElementProjectedBuildingShadowConfig? projectedBuildingShadow,
  bool includeProjectedPreset = false,
  bool omitElementShadow = false,
  List<TilesetVisualFrame>? frames,
  ProjectBuildingShadowPreset? projectedPreset,
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    shadowCatalog: catalog ??
        ProjectShadowCatalog(
          profiles: [profile ?? _profile('base_shadow')],
        ),
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    projectedBuildingShadowCatalog: includeProjectedPreset
        ? ProjectBuildingShadowPresetCatalog(
            presets: [projectedPreset ?? _projectedPreset()],
          )
        : const ProjectBuildingShadowPresetCatalog.empty(),
    elements: [
      ProjectElementEntry(
        id: 'stand',
        name: 'Stand',
        tilesetId: 'tiles',
        categoryId: 'props',
        frames: frames ??
            const [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 4),
              ),
            ],
        shadow: omitElementShadow
            ? null
            : elementShadow ??
                ProjectElementShadowConfig(
                  castsShadow: true,
                  shadowProfileId: 'base_shadow',
                ),
        projectedBuildingShadow: projectedBuildingShadow,
      ),
    ],
  );
}

MapData _map({
  bool layerVisible = true,
  MapPlacedElementShadowOverride? shadowOverride,
  List<MapPlacedElement>? placedElements,
}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 8, height: 8),
    layers: [
      TileLayer(
        id: 'layer',
        name: 'Layer',
        isVisible: layerVisible,
        tilesetId: 'tiles',
        tiles: List<int>.filled(64, 0),
      ),
    ],
    placedElements: placedElements ??
        [
          MapPlacedElement(
            id: 'layer::1::2',
            layerId: 'layer',
            elementId: 'stand',
            pos: const GridPos(x: 1, y: 2),
            shadowOverride: shadowOverride,
          ),
        ],
  );
}

ProjectShadowProfile _profile(
  String id, {
  ShadowCasterMode mode = ShadowCasterMode.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
  double scaleX = 1,
  double opacity = 0.35,
  String colorHexRgb = '000000',
}) {
  return ProjectShadowProfile(
    id: id,
    name: id,
    mode: mode,
    renderPass: renderPass,
    scaleX: scaleX,
    opacity: opacity,
    colorHexRgb: colorHexRgb,
  );
}

ProjectElementProjectedBuildingShadowConfig _projectedConfig({
  bool enabled = true,
  String presetId = 'shadow-a',
}) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: enabled,
    presetId: presetId,
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
}

ProjectBuildingShadowPreset _projectedPreset() {
  return ProjectBuildingShadowPreset(
    id: 'shadow-a',
    name: 'Shadow A',
    direction: ProjectedShadowDirection(x: 1, y: 0),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.5,
      nearWidthRatio: 1,
      farWidthRatio: 0.5,
    ),
    appearance: ProjectedShadowAppearance(
      opacity: 0.18,
      colorHexRgb: '123ABC',
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
}

ProjectBuildingShadowPreset _projectedFootprintPreset() {
  return ProjectBuildingShadowPreset(
    id: 'pokemon-building-shadow-footprint-v0',
    name: 'Pokemon-like footprint building shadow V0',
    geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
    direction: ProjectedShadowDirection(x: 1, y: 0),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.5,
      nearWidthRatio: 1,
      farWidthRatio: 0.5,
    ),
    footprint: ProjectedShadowFootprintTuning(),
    appearance: ProjectedShadowAppearance(
      opacity: 0.28,
      colorHexRgb: '606060',
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
}
