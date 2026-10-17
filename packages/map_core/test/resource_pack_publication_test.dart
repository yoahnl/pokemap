import 'dart:typed_data';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final extended in [false, true]) {
    test(
      'strict authoring guide recognizes ${extended ? 20 : 16} portable connections without trusting guideId',
      () {
        final (manifest, draft) = guideFixture(extended: extended);
        final expected = extended
            ? 'avelune-path20-v1'
            : 'avelune-cardinal4-v1';
        expect(draft.guideId, isNull);
        expect(recognizeSmartTileAuthoringGuide(manifest, draft), expected);
        expect(
          recognizeSmartTileAuthoringGuide(
            manifest,
            draft.copyWith(guideId: 'untrusted'),
          ),
          expected,
        );
        final compiled = compileSmartTileAuthoringDraft(
          draft: draft,
          catalog: manifest.smartTileCatalog,
          manifest: manifest,
        );
        expect(compiled, isA<SmartTileDraftCompilationSuccess>());
        final restored = reconstructResourcePackSmartTileDraft(
          preset: (compiled as SmartTileDraftCompilationSuccess).preset,
          catalog: manifest.smartTileCatalog,
        );
        expect(restored.rules, draft.rules);
        expect(recognizeSmartTileAuthoringGuide(manifest, restored), expected);
        expect(draft.rules.first.id, 'connection-0');
        expect(draft.rules.first.candidates.single.id, 'piece-0');
        expect(draft.atlases.single.columns, 4);
        expect(draft.atlases.single.rows, 4);
      },
    );
  }
  test(
    'strict authoring guide refuses advanced structure and altered source grid',
    () {
      final (manifest, draft) = guideFixture();
      final rule = draft.rules.first;
      final candidate = rule.candidates.single;
      final part = candidate.parts.single;
      for (final changed in [
        draft.copyWith(rules: draft.rules.reversed.toList()),
        draft.copyWith(
          rules: [
            rule.copyWith(id: 'custom'),
            ...draft.rules.skip(1),
          ],
        ),
        draft.copyWith(
          rules: [
            rule.copyWith(candidates: [candidate.copyWith(id: 'variant')]),
            ...draft.rules.skip(1),
          ],
        ),
        draft.copyWith(
          rules: [
            rule.copyWith(candidates: [candidate.copyWith(weight: 2)]),
            ...draft.rules.skip(1),
          ],
        ),
        draft.copyWith(
          rules: [
            rule.copyWith(
              candidates: [
                candidate.copyWith(parts: [part, part]),
              ],
            ),
            ...draft.rules.skip(1),
          ],
        ),
        draft.copyWith(
          rules: [
            smartTileAuthoringConnectionRule(
              0,
              SmartTileFrameRef(atlasId: 'a', column: 4, row: 0),
              'm',
            ),
            ...draft.rules.skip(1),
          ],
        ),
        draft.copyWith(
          rules: [
            smartTileAuthoringConnectionRule(
              0,
              SmartTileFrameRef(atlasId: 'a', column: 0, row: 0, columnSpan: 2),
              'm',
            ),
            ...draft.rules.skip(1),
          ],
        ),
        draft.copyWith(fallbackRuleId: rule.id),
        draft.copyWith(atlases: [draft.atlases.single.copyWith(marginX: 0)]),
        draft.copyWith(
          transformPolicy: const SmartTileTransformPolicy(allowHFlip: true),
        ),
      ]) {
        expect(recognizeSmartTileAuthoringGuide(manifest, changed), isNull);
      }
      expect(
        recognizeSmartTileAuthoringGuide(
          manifest.copyWith(tilesets: []),
          draft,
        ),
        isNull,
      );
      final tile = manifest.tilesets.single;
      final altered = ProjectTilesetEntry.fromJson({
        ...tile.toJson(),
        'source': {...tile.source!.toJson(), 'pixelWidth': 12},
      });
      expect(
        recognizeSmartTileAuthoringGuide(
          manifest.copyWith(tilesets: [altered]),
          draft,
        ),
        isNull,
      );
    },
  );

  test(
    'published border projection omits divergent private draft and reconstructs editable native state',
    () {
      final record = borderFixture();
      final catalog = ResourcePackCatalog(
        borderCatalog: ProjectBorderCatalog(
          formatVersion: 10,
          records: [record],
        ),
      );
      final json = catalog.toJson();
      final portable =
          ((json['borderCatalog'] as Map)['records'] as List).single as Map;
      expect(portable.containsKey('draft'), isFalse);
      expect(json.toString(), isNot(contains('Private unshipped')));
      final restored = ResourcePackCatalog.fromJson(
        json,
      ).borderCatalog.records.single;
      expect(restored.draft.baseRevision, 3);
      expect(restored.draft.definition.name, 'Published');
      expect(
        restored.draft.definition.primitives.single.sourceModelId,
        'model',
      );
      expect(restored.latestPublished, record.latestPublished);
      expect(
        () => ResourcePackCatalog.fromJson({
          ...json,
          'borderCatalog': {
            ...json['borderCatalog'] as Map,
            'records': [
              {...portable, 'draft': null},
            ],
          },
        }),
        throwsFormatException,
      );
    },
  );
  test('border snapshot source evidence must reproduce published pixels', () {
    final frames = [
      BorderSnapshotContentFrame(
        sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
        durationMs: 100,
        rgbaBytes: Uint8List.fromList([1, 2, 3, 255]),
      ),
    ];
    final fingerprint = computeBorderSnapshotContentFingerprint(frames: frames);
    final snapshot = BorderVisualSnapshot(
      id: 'border-snapshot-sha256:$fingerprint',
      contentFingerprint: fingerprint,
      frames: [
        BorderVisualFrameSnapshot(
          relativeAssetPath: 'assets/borders/snapshots/test.png',
          sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
          durationMs: 100,
        ),
      ],
    );
    final metrics = BorderPrimitiveAssetMetrics(
      assetFingerprint: 'source',
      pixelSize: const GridSize(width: 1, height: 1),
      opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
      defaultAnchorPx: BorderPixelPos(x: 0, y: 0),
      occupancyMaskRle: 'border-rle-v1:1:1:1',
    );
    final base = borderFixture();
    final definition = base.latestPublished!.definition;
    final sprite = BorderBlueprintRecord(
      id: 'sprite',
      draft: base.draft,
      latestPublished: BorderBlueprintRevision(
        revision: 1,
        definition: BorderBlueprintPublishedDefinition(
          name: definition.name,
          previewSeed: definition.previewSeed,
          template: definition.template,
          primitives: [
            BorderPublishedPrimitive(
              id: 'p',
              sourceElementId: 'chair',
              visualSnapshotId: snapshot.id,
              role: BorderPrimitiveRole.lineStraight,
              weight: 1,
              anchorPx: BorderPixelPos(x: 0, y: 0),
              transforms: BorderTransformPolicy(
                allowFlipX: false,
                allowedQuarterTurns: [0],
              ),
              publishedMetrics: metrics,
            ),
          ],
          defaults: definition.defaults,
          sortOrder: 0,
        ),
      ),
    );
    expect(
      projectResourcePackPublishedBorder(
        record: sprite,
        snapshots: [snapshot],
        primitiveSourceFrames: {'p': frames},
      ).draft.definition.primitives.single.sourceElementId,
      'chair',
    );
    expect(
      () => projectResourcePackPublishedBorder(
        record: sprite,
        snapshots: [snapshot],
        primitiveSourceFrames: {},
      ),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'code',
          contains('border.source_publication_mismatch'),
        ),
      ),
    );
    final wrong = [
      BorderSnapshotContentFrame(
        sourceRectPx: frames.single.sourceRectPx,
        durationMs: 100,
        rgbaBytes: Uint8List.fromList([4, 5, 6, 255]),
      ),
    ];
    expect(
      () => projectResourcePackPublishedBorder(
        record: sprite,
        snapshots: [snapshot],
        primitiveSourceFrames: {'p': wrong},
      ),
      throwsFormatException,
    );
  });
  test(
    'Smart Tile draft reconstruction compiles exactly then supports editing',
    () {
      final preset = presetFixture();
      final smart = ProjectSmartTileCatalog(
        materials: [
          const ProjectSmartTileMaterial(
            id: 'grass',
            name: 'Grass',
            connectionGroupId: 'ground',
          ),
        ],
        presets: [preset],
      );
      final manifest = ProjectManifest(
        name: 'Test',
        settings: const ProjectSettings(dimension: ProjectDimension.threeD),
        maps: [],
        tilesets: [],
        models3d: [modelFixture()],
        smartTileCatalog: smart,
      );
      final draft = reconstructResourcePackSmartTileDraft(
        preset: preset,
        catalog: smart,
      );
      final compiled = compileSmartTileAuthoringDraft(
        draft: draft,
        catalog: smart,
        manifest: manifest,
      );
      expect(
        compiled,
        isA<SmartTileDraftCompilationSuccess>(),
        reason: compiled is SmartTileDraftCompilationFailure
            ? compiled.diagnostics
                  .map((d) => '${d.code}: ${d.message}')
                  .join('\n')
            : null,
      );
      expect((compiled as SmartTileDraftCompilationSuccess).preset, preset);
      final edited = compileSmartTileAuthoringDraft(
        draft: draft.copyWith(name: 'Edited'),
        catalog: smart,
        manifest: manifest,
      );
      expect(
        (edited as SmartTileDraftCompilationSuccess).preset.name,
        'Edited',
      );
    },
  );
}

ProjectSmartTilePreset presetFixture() => const ProjectSmartTilePreset(
  id: 'terrain',
  name: 'Terrain',
  usage: SmartTileUsage.terrain,
  topology: SmartTileTopology.uniform,
  templateHint: SmartTileTemplateHint.simple,
  status: SmartTilePresetStatus.published,
  coveragePolicy: SmartTileCoveragePolicy.complete,
  coverageProfile: SmartTileCoverageProfile(
    mode: SmartTileCoverageMode.template,
  ),
  transformPolicy: SmartTileTransformPolicy(),
  defaultMaterialId: 'grass',
  allowedMaterialIds: ['grass'],
  rules: [
    SmartTileRule(
      id: 'rule',
      centerMatch: SmartTileSlotMatch.material('grass'),
      signature: SmartTileSignature(),
      candidates: [
        SmartTileCandidate(
          id: 'candidate',
          parts: [
            SmartTileVisualPart(
              source: SmartTileVisualSource.model3d(modelId: 'model'),
            ),
          ],
        ),
      ],
    ),
  ],
);

ProjectModel3dEntry modelFixture() => ProjectModel3dEntry(
  id: 'model',
  name: 'Model',
  sourceAssetId: 'glb',
  relativePath: 'assets/models3d/model.glb',
  inspection: Model3dInspection(
    bounds: Model3dBounds(
      min: Model3dVector3.zero,
      max: Model3dVector3(x: 1, y: 1, z: 1),
    ),
    meshCount: 1,
    triangleCount: 1,
    materials: [],
    animations: [],
    diagnostics: [],
  ),
);

BorderBlueprintRecord borderFixture() {
  final published = BorderBlueprintPublishedDefinition(
    name: 'Published',
    previewSeed: BorderSignedInt64.fromInt(1),
    template: BorderBlueprintTemplate.connectedLine,
    primitives: [
      BorderPublishedPrimitive(
        id: 'p',
        sourceModelId: 'model',
        role: BorderPrimitiveRole.lineStraight,
        weight: 1,
        anchorWorld: Model3dVector3.zero,
        transforms: BorderTransformPolicy(
          allowFlipX: false,
          allowedQuarterTurns: [0],
        ),
      ),
    ],
    defaults: BorderGenerationParams(
      irregularityPermille: 0,
      detailDensityPermille: 0,
      variationPermille: 0,
      maxOverlapPx: 0,
      gapTolerancePx: 0,
      depthRows: 1,
    ),
    sortOrder: 0,
  );
  return BorderBlueprintRecord(
    id: 'border',
    draft: BorderBlueprintDraft(
      baseRevision: 3,
      definition: BorderBlueprintDraftDefinition(
        name: 'Private unshipped',
        previewSeed: published.previewSeed,
        template: published.template,
        primitives: [],
        defaults: published.defaults,
        sortOrder: 0,
      ),
    ),
    latestPublished: BorderBlueprintRevision(
      revision: 3,
      definition: published,
    ),
  );
}

(ProjectManifest, ProjectSmartTileAuthoringDraft) guideFixture({
  bool extended = false,
}) {
  final source = ProjectTilesetEntry(
    id: 'tiles',
    name: 'Source',
    relativePath: 'assets/source.png',
    source: ProjectTilesetSource.regularAtlas(
      assetId: 'source',
      pixelWidth: 13,
      pixelHeight: 22,
      tileWidth: 2,
      tileHeight: 3,
      marginX: 1,
      marginY: 2,
      spacingX: 1,
      spacingY: 2,
      pixelOffsetX: 1,
      pixelOffsetY: -1,
    ),
  );
  final atlas = smartTileAuthoringAtlas(source, 'a');
  final material = ProjectSmartTileMaterial(
    id: 'm',
    name: 'Ground',
    connectionGroupId: 'g',
  );
  final draft = ProjectSmartTileAuthoringDraft(
    id: 'draft-terrain',
    targetPresetId: 'terrain',
    name: 'Original',
    usage: SmartTileUsage.path,
    topology: extended ? SmartTileTopology.blob8 : SmartTileTopology.cardinal4,
    templateHint: extended
        ? SmartTileTemplateHint.blob47
        : SmartTileTemplateHint.edge16,
    lastStage: SmartTileAuthoringStage.connections,
    sourceTilesetIds: ['tiles'],
    atlases: [atlas],
    primaryAtlasId: 'a',
    materials: [material],
    defaultMaterialId: 'm',
    allowedMaterialIds: ['m'],
    rules: [
      for (var i = 0; i < (extended ? 20 : 16); i++)
        i < 16
            ? smartTileAuthoringConnectionRule(
                i,
                SmartTileFrameRef(atlasId: 'a', column: i % 4, row: i ~/ 4),
                'm',
              )
            : smartTileAuthoringOuterCornerRule(
                i,
                SmartTileFrameRef(atlasId: 'a', column: (i - 16) % 4, row: 0),
                'm',
              ),
    ],
  );
  return (
    ProjectManifest(
      name: 'Guide',
      maps: [],
      tilesets: [source],
      smartTileCatalog: ProjectSmartTileCatalog(
        atlases: [atlas],
        materials: [material],
      ),
    ),
    draft,
  );
}
