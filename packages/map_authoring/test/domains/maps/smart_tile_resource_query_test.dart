import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('queries all six native Smart Tile resource kinds', () {
    final snapshot = _snapshot();
    final expected = <String, int>{
      'smartTileAtlas': 1,
      'smartTileMaterial': 1,
      'smartTileAnimation': 1,
      'smartTilePreset': 1,
      'smartTileLayer': 1,
      'smartTileDraft': 1,
    };

    for (final entry in expected.entries) {
      final page = const ProjectQueryService().query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: entry.key,
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.detail,
        ),
      );
      expect(page.totalAvailable, entry.value, reason: entry.key);
      expect(page.items.single['resourceKind'], entry.key);
    }
  });

  test('draft detail exposes the byte-stable canonical document', () {
    final page = const ProjectQueryService().query(
      _snapshot(),
      AuthoringQueryRequest(
        resourceKind: 'smartTileDraft',
        operation: AuthoringQueryOperation.get,
        view: AuthoringQueryView.detail,
        ids: <String>['draft-grass'],
      ),
    );

    expect(page.items.single, <String, Object?>{
      ..._draft.toJson(),
      'resourceKind': 'smartTileDraft',
    });
  });

  test('preset detail includes exact coverage diagnostics', () {
    final page = const ProjectQueryService().query(
      _snapshot(),
      AuthoringQueryRequest(
        resourceKind: 'smartTilePreset',
        operation: AuthoringQueryOperation.get,
        view: AuthoringQueryView.detail,
        ids: <String>['grass'],
      ),
    );

    final coverage = page.items.single['coverage']! as Map<String, Object?>;
    expect(coverage['caseCount'], 1);
    expect(coverage['exactCount'], 1);
    expect(coverage['isExact'], isTrue);
  });
}

ProjectSnapshot _snapshot() {
  const atlas = ProjectSmartTileAtlas(
    id: 'atlas',
    name: 'Atlas',
    tilesetId: 'tileset',
    columns: 1,
    rows: 1,
  );
  const material = ProjectSmartTileMaterial(
    id: 'grass',
    name: 'Grass',
    connectionGroupId: 'ground',
  );
  const animation = ProjectSmartTileAnimation(
    id: 'wind',
    name: 'Wind',
    frames: <ProjectSmartTileAnimationFrame>[
      ProjectSmartTileAnimationFrame(
        frame: SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0),
        durationMs: 100,
      ),
    ],
  );
  const preset = ProjectSmartTilePreset(
    id: 'grass',
    name: 'Grass',
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
    allowedMaterialIds: <String>['grass'],
    rules: <SmartTileRule>[
      SmartTileRule(
        id: 'base',
        centerMatch: SmartTileSlotMatch.material('grass'),
        signature: SmartTileSignature(),
        candidates: <SmartTileCandidate>[
          SmartTileCandidate(
            id: 'base',
            parts: <SmartTileVisualPart>[
              SmartTileVisualPart(
                source: SmartTileVisualSource.frame(
                  frame: SmartTileFrameRef(
                    atlasId: 'atlas',
                    column: 0,
                    row: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  const map = MapData(
    id: 'map',
    name: 'Map',
    version: ProjectVersion.v6,
    size: GridSize(width: 1, height: 1),
    layers: <MapLayer>[
      MapLayer.smartTile(
        id: 'terrain',
        name: 'Terrain',
        presetId: 'grass',
        usage: SmartTileUsage.terrain,
        materialPalette: <String>['', 'grass'],
        field: SmartTileField.cell(semanticCells: <int>[1]),
      ),
    ],
  );
  final manifest = ProjectManifest(
    name: 'Query fixture',
    version: ProjectVersion.v6,
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'map',
        name: 'Map',
        relativePath: 'maps/map.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'tileset',
        name: 'Tileset',
        relativePath: 'assets/tileset.png',
      ),
    ],
    smartTileCatalog: ProjectSmartTileCatalog(
      atlases: const <ProjectSmartTileAtlas>[atlas],
      materials: const <ProjectSmartTileMaterial>[material],
      animations: const <ProjectSmartTileAnimation>[animation],
      presets: const <ProjectSmartTilePreset>[preset],
      drafts: const <ProjectSmartTileAuthoringDraft>[_draft],
    ),
  );
  final projectBytes = _encode(manifest.toJson());
  final mapBytes = _encode(map.toJson());
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('project_query'),
    revision: computeAuthoringBytesFingerprint(
      utf8.encode('query-snapshot'),
      logicalName: 'snapshot',
    ),
    manifest: manifest,
    maps: const <MapData>[map],
    resourceFingerprints: <String, String>{
      'project': computeAuthoringBytesFingerprint(
        projectBytes,
        logicalName: 'project.json',
      ),
      'map:map': computeAuthoringBytesFingerprint(
        mapBytes,
        logicalName: 'maps/map.json',
      ),
    },
    resourceBytes: <String, List<int>>{
      'project': projectBytes,
      'map:map': mapBytes,
    },
  );
}

const _draft = ProjectSmartTileAuthoringDraft(
  id: 'draft-grass',
  targetPresetId: 'future-grass',
  name: 'Future grass',
  usage: SmartTileUsage.terrain,
  lastStage: SmartTileAuthoringStage.image,
);

List<int> _encode(Object? value) =>
    utf8.encode(const JsonEncoder.withIndent('  ').convert(value));
