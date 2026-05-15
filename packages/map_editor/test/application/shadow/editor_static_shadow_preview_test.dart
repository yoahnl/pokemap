import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/editor_static_shadow_preview.dart';

void main() {
  group('buildEditorStaticShadowPreviewInstructions', () {
    test('builds an ellipse groundStatic instruction', () {
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
      expect(instruction.shape, ShadowCasterMode.ellipse);
      expect(instruction.left, closeTo(20, 0.001));
      expect(instruction.top, closeTo(88, 0.001));
      expect(instruction.width, closeTo(24, 0.001));
      expect(instruction.height, closeTo(16, 0.001));
      expect(instruction.opacity, 0.35);
      expect(instruction.colorHexRgb, '000000');
    });

    test('builds a contactBlob groundStatic instruction', () {
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

      expect(instructions.single.shape, ShadowCasterMode.contactBlob);
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
      expect(instruction.left, closeTo(12, 0.001));
      expect(instruction.top, closeTo(90, 0.001));
      expect(instruction.width, closeTo(48, 0.001));
      expect(instruction.height, closeTo(8, 0.001));
      expect(instruction.opacity, 0.2);
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
      expect(instruction.left, closeTo(16, 0.001));
      expect(instruction.top, closeTo(76, 0.001));
      expect(instruction.width, closeTo(16, 0.001));
      expect(instruction.height, closeTo(8, 0.001));
    });

    test('uses override footprint over element footprint field by field', () {
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
        map: _map(
          shadowOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            footprint: StaticShadowFootprintConfig(
              anchorYRatio: 0.5,
              footprintWidthRatio: 0.25,
            ),
          ),
        ),
        tileWidth: 16,
        tileHeight: 16,
      );

      final instruction = instructions.single;
      expect(instruction.left, closeTo(20, 0.001));
      expect(instruction.top, closeTo(60, 0.001));
      expect(instruction.width, closeTo(8, 0.001));
      expect(instruction.height, closeTo(8, 0.001));
    });

    test('custom override without footprint keeps element footprint', () {
      final instructions = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(
          elementShadow: ProjectElementShadowConfig(
            castsShadow: true,
            shadowProfileId: 'base_shadow',
            footprint: StaticShadowFootprintConfig(
              anchorXRatio: 0.5,
              anchorYRatio: 0.5,
              footprintWidthRatio: 0.5,
              footprintHeightRatio: 0.5,
            ),
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
      expect(instruction.left, closeTo(20, 0.001));
      expect(instruction.top, closeTo(54, 0.001));
      expect(instruction.width, closeTo(32, 0.001));
      expect(instruction.height, closeTo(16, 0.001));
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

      expect(overridden.width, closeTo(36, 0.001));
      expect(overridden.opacity, 0.1);
      expect(overridden.colorHexRgb, '112233');

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

      expect(inherited.width, closeTo(24, 0.001));
      expect(inherited.colorHexRgb, '000000');
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
  });
}

ProjectManifest _manifest({
  ProjectShadowCatalog? catalog,
  ProjectShadowProfile? profile,
  ProjectElementShadowConfig? elementShadow,
  bool omitElementShadow = false,
  List<TilesetVisualFrame>? frames,
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    shadowCatalog: catalog ??
        ProjectShadowCatalog(
          profiles: [profile ?? _profile('base_shadow')],
        ),
    surfaceCatalog: ProjectSurfaceCatalog(),
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
