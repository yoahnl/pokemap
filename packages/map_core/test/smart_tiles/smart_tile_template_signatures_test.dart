import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Smart Tile canonical templates', () {
    test('Simple has one canonical case and uses uniform topology', () {
      expect(
        smartTileCanonicalMasks(SmartTileTemplateHint.simple),
        const <int>[0],
      );
      expect(
        smartTileTopologyForTemplate(SmartTileTemplateHint.simple),
        SmartTileTopology.uniform,
      );
      expect(
        smartTileSignatureForMask(0, topology: SmartTileTopology.uniform),
        const SmartTileSignature(),
      );
      expect(
        smartTileMaskForSignature(
          const SmartTileSignature(),
          topology: SmartTileTopology.uniform,
        ),
        0,
      );
      expect(
        smartTileMaskForSignature(
          const SmartTileSignature(
            northEdge: SmartTileSlotMatch.empty(),
          ),
          topology: SmartTileTopology.uniform,
        ),
        isNull,
      );
    });

    test('Simple generates one explicit center rule per stable material id',
        () {
      const grassCandidate = SmartTileCandidate(id: 'grass-candidate');
      const dirtCandidate = SmartTileCandidate(id: 'dirt-candidate');
      const draft = ProjectSmartTilePreset(
        id: 'simple-ground',
        name: 'Simple ground',
        usage: SmartTileUsage.terrain,
        topology: SmartTileTopology.uniform,
        templateHint: SmartTileTemplateHint.simple,
        coveragePolicy: SmartTileCoveragePolicy.complete,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
        ),
        transformPolicy: SmartTileTransformPolicy(),
        defaultMaterialId: 'grass',
        allowedMaterialIds: <String>['grass', 'dirt', '', 'grass'],
      );

      final rules = generateSmartTileTemplateRules(
        preset: draft,
        candidatesByMaterialId: const <String, List<SmartTileCandidate>>{
          'grass': <SmartTileCandidate>[grassCandidate],
          'dirt': <SmartTileCandidate>[dirtCandidate],
        },
        materials: const <ProjectSmartTileMaterial>[
          ProjectSmartTileMaterial(
            id: 'grass',
            name: 'Grass',
            connectionGroupId: 'ground',
          ),
          ProjectSmartTileMaterial(
            id: 'dirt',
            name: 'Dirt',
            connectionGroupId: 'ground',
          ),
        ],
      );
      final preset = draft.copyWith(rules: rules);

      expect(rules.map((rule) => rule.id),
          <String>['material_dirt', 'material_grass']);
      expect(
        rules.map((rule) => rule.centerMatch),
        const <SmartTileSlotMatch>[
          SmartTileSlotMatch.material('dirt'),
          SmartTileSlotMatch.material('grass'),
        ],
      );
      expect(
          rules.every((rule) => rule.signature == const SmartTileSignature()),
          isTrue);

      final dirt = resolveSmartTile(
        preset: preset,
        materials: const <ProjectSmartTileMaterial>[
          ProjectSmartTileMaterial(
            id: 'grass',
            name: 'Grass',
            connectionGroupId: 'ground',
          ),
          ProjectSmartTileMaterial(
            id: 'dirt',
            name: 'Dirt',
            connectionGroupId: 'ground',
          ),
        ],
        context: const SmartTileCellContext(centerMaterialId: 'dirt'),
        x: 0,
        y: 0,
      );
      final grass = resolveSmartTile(
        preset: preset,
        materials: const <ProjectSmartTileMaterial>[
          ProjectSmartTileMaterial(
            id: 'grass',
            name: 'Grass',
            connectionGroupId: 'ground',
          ),
          ProjectSmartTileMaterial(
            id: 'dirt',
            name: 'Dirt',
            connectionGroupId: 'ground',
          ),
        ],
        context: const SmartTileCellContext(centerMaterialId: 'grass'),
        x: 0,
        y: 0,
      );

      expect(dirt.candidate, dirtCandidate);
      expect(grass.candidate, grassCandidate);
      final diagnostics = validateProjectSmartTileCatalog(
        catalog: ProjectSmartTileCatalog(
          materials: const <ProjectSmartTileMaterial>[
            ProjectSmartTileMaterial(
              id: 'grass',
              name: 'Grass',
              connectionGroupId: 'ground',
            ),
            ProjectSmartTileMaterial(
              id: 'dirt',
              name: 'Dirt',
              connectionGroupId: 'ground',
            ),
          ],
          presets: <ProjectSmartTilePreset>[preset],
        ),
        projectTilesetIds: const <String>[],
      );
      expect(
        diagnostics.map((diagnostic) => diagnostic.code),
        isNot(
          contains(anyOf(
            'smart_tiles.rules.ambiguous',
            'smart_tiles.coverage.incomplete',
          )),
        ),
      );
    });

    test('Blob rejects signatures erased by diagonal normalization', () {
      const nonRepresentable = SmartTileSignature(
        northWestCorner: SmartTileSlotMatch.same(),
        northEdge: SmartTileSlotMatch.different(),
        westEdge: SmartTileSlotMatch.different(),
        northEastCorner: SmartTileSlotMatch.different(),
        eastEdge: SmartTileSlotMatch.different(),
        southEastCorner: SmartTileSlotMatch.different(),
        southEdge: SmartTileSlotMatch.different(),
        southWestCorner: SmartTileSlotMatch.different(),
      );

      expect(
        smartTileMaskForSignature(
          nonRepresentable,
          topology: SmartTileTopology.blob8,
        ),
        isNull,
      );
    });

    test('Simple excludes isEmpty unless explicitly requested', () {
      const preset = ProjectSmartTilePreset(
        id: 'simple-empty',
        name: 'Simple empty',
        usage: SmartTileUsage.terrain,
        topology: SmartTileTopology.uniform,
        templateHint: SmartTileTemplateHint.simple,
        coveragePolicy: SmartTileCoveragePolicy.sparse,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
        ),
        transformPolicy: SmartTileTransformPolicy(),
        defaultMaterialId: 'grass',
        allowedMaterialIds: <String>['grass', 'void'],
      );
      const materials = <ProjectSmartTileMaterial>[
        ProjectSmartTileMaterial(
          id: 'grass',
          name: 'Grass',
          connectionGroupId: 'ground',
        ),
        ProjectSmartTileMaterial(
          id: 'void',
          name: 'Void',
          connectionGroupId: 'void',
          isEmpty: true,
        ),
      ];

      final implicit = generateSmartTileTemplateRules(
        preset: preset,
        candidatesByMaterialId: const <String, List<SmartTileCandidate>>{},
        materials: materials,
      );
      final explicit = generateSmartTileTemplateRules(
        preset: preset,
        candidatesByMaterialId: const <String, List<SmartTileCandidate>>{
          'void': <SmartTileCandidate>[
            SmartTileCandidate(id: 'void-candidate'),
          ],
        },
        materials: materials,
        explicitEmptyMaterialIds: const <String>{'void'},
      );

      expect(implicit.map((rule) => rule.id), <String>['material_grass']);
      expect(
        explicit.map((rule) => rule.id),
        <String>['material_grass', 'material_void'],
      );

      final resolution = resolveSmartTile(
        preset: preset.copyWith(rules: explicit),
        materials: materials,
        context: const SmartTileCellContext(centerMaterialId: 'void'),
        x: 0,
        y: 0,
      );
      expect(resolution.status, SmartTileResolutionStatus.resolved);
      expect(resolution.ruleId, 'material_void');
      expect(resolution.candidate?.id, 'void-candidate');
    });

    test('Edge 16 exposes every cardinal combination exactly once', () {
      final masks = smartTileCanonicalMasks(SmartTileTemplateHint.edge16);

      expect(masks, hasLength(16));
      expect(masks.toSet(), <int>{for (var mask = 0; mask < 16; mask++) mask});
    });

    test('Corner 16 exposes every corner combination exactly once', () {
      final masks = smartTileCanonicalMasks(SmartTileTemplateHint.corner16);

      expect(masks, hasLength(16));
      expect(
        masks.toSet(),
        <int>{
          for (var mask = 0; mask < 16; mask++)
            ((mask & 0x1) << 4) |
                ((mask & 0x2) << 4) |
                ((mask & 0x4) << 4) |
                ((mask & 0x8) << 4),
        },
      );
    });

    test('Corner 12 exposes the connected ERW corner signatures', () {
      final masks = smartTileCanonicalMasks(SmartTileTemplateHint.corner12);

      expect(
        masks,
        <int>[
          0x10,
          0x20,
          0x30,
          0x40,
          0x60,
          0x70,
          0x80,
          0x90,
          0xB0,
          0xC0,
          0xD0,
          0xE0,
        ],
      );
      expect(masks, isNot(containsAll(<int>[0x00, 0x50, 0xA0, 0xF0])));
    });

    test('Blob 47 normalizes all 256 neighborhoods into 47 signatures', () {
      final canonical = smartTileCanonicalMasks(
        SmartTileTemplateHint.blob47,
      );
      final normalized = <int>{
        for (var mask = 0; mask < 256; mask++) normalizeSmartTileBlobMask(mask),
      };

      expect(canonical, hasLength(47));
      expect(canonical.toSet(), normalized);
      expect(
        normalizeSmartTileBlobMask(
          smartTileNorthWestBit | smartTileNorthBit,
        ),
        smartTileNorthBit,
        reason: 'a diagonal is gated unless both adjacent edges connect',
      );
      expect(
        normalizeSmartTileBlobMask(
          smartTileNorthWestBit | smartTileNorthBit | smartTileWestBit,
        ),
        smartTileNorthWestBit | smartTileNorthBit | smartTileWestBit,
      );
    });

    test('Mixed 256 preserves every eight-neighbor combination', () {
      final masks = smartTileCanonicalMasks(SmartTileTemplateHint.mixed256);

      expect(masks, hasLength(256));
      expect(masks.toSet(), <int>{for (var mask = 0; mask < 256; mask++) mask});
    });

    test('mask signature uses same and different matches deterministically',
        () {
      final signature = smartTileSignatureForMask(
        smartTileNorthBit | smartTileEastBit | smartTileNorthEastBit,
        topology: SmartTileTopology.blob8,
      );

      expect(signature.northEdge.kind, SmartTileMatchKind.same);
      expect(signature.eastEdge.kind, SmartTileMatchKind.same);
      expect(signature.southEdge.kind, SmartTileMatchKind.different);
      expect(signature.westEdge.kind, SmartTileMatchKind.different);
      expect(signature.northEastCorner.kind, SmartTileMatchKind.same);
      expect(signature.southEastCorner.kind, SmartTileMatchKind.different);
    });

    test('one canonical decoder produces matching contexts for every topology',
        () {
      const material = ProjectSmartTileMaterial(
        id: 'grass',
        name: 'Grass',
        connectionGroupId: 'ground',
      );
      final cases = <(SmartTileTopology, Iterable<int>)>[
        (SmartTileTopology.uniform, const <int>[0]),
        (SmartTileTopology.cardinal4, <int>[for (var i = 0; i < 16; i++) i]),
        (SmartTileTopology.wangEdge4, <int>[for (var i = 0; i < 16; i++) i]),
        (
          SmartTileTopology.wangCorner4,
          <int>[for (var i = 0; i < 16; i++) i << 4],
        ),
        (
          SmartTileTopology.blob8,
          smartTileCanonicalMasks(SmartTileTemplateHint.blob47),
        ),
        (SmartTileTopology.wang8, <int>[for (var i = 0; i < 256; i++) i]),
      ];

      for (final entry in cases) {
        for (final mask in entry.$2) {
          final decoded = smartTileTemplateCaseForMask(
            mask: mask,
            topology: entry.$1,
            materialId: material.id,
          );

          expect(
            decoded.signature,
            smartTileSignatureForMask(mask, topology: entry.$1),
          );
          expect(
            smartTileConnectivityMask(
              topology: entry.$1,
              boundaryPolicy: SmartTileBoundaryPolicy.empty,
              materials: const <ProjectSmartTileMaterial>[material],
              context: decoded.context,
            ),
            entry.$1 == SmartTileTopology.blob8
                ? normalizeSmartTileBlobMask(mask)
                : mask,
            reason: '${entry.$1.name} mask 0x${mask.toRadixString(16)}',
          );
        }
      }
    });

    test('Free does not invent canonical native mappings', () {
      expect(smartTileCanonicalMasks(SmartTileTemplateHint.free), isEmpty);
    });
  });
}
