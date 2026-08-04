import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_pattern_authoring_service.dart';

void main() {
  test('upserts through the canonical action and reloads exact snapshot',
      () async {
    final gateway = _PatternGateway();
    final service = SmartTilePatternAuthoringService(gateway: gateway);

    final result = await service.upsert(
      projectRootPath: '/project',
      pattern: _pattern,
    );

    expect(gateway.actionId, 'smart_tile.pattern.upsert');
    expect(gateway.parameters, <String, Object?>{
      'pattern': _pattern.toJson(),
    });
    expect(gateway.expectedRevision, 'revision-1');
    expect(
      gateway.idempotencyKey,
      matches(RegExp(r'^smart-tile-pattern-[0-9a-f]{64}$')),
      reason:
          'The canonical gateway also derives a durable filesystem operation '
          'id from this value, so the sha256: wire prefix must not leak here.',
    );
    expect(result.pattern, _pattern);
    expect(result.manifest.smartTileCatalog.patterns, <Object>[_pattern]);
  });

  test('rejects a stale snapshot after canonical apply', () async {
    final gateway = _PatternGateway(staleAfterApply: true);
    final service = SmartTilePatternAuthoringService(gateway: gateway);

    expect(
      () => service.upsert(
        projectRootPath: '/project',
        pattern: _pattern,
      ),
      throwsA(
        isA<SmartTilePatternAuthoringServiceException>().having(
          (error) => error.code,
          'code',
          'smart_tile.pattern.snapshot_stale',
        ),
      ),
    );
  });
}

final class _PatternGateway implements SmartTilePatternAuthoringGateway {
  _PatternGateway({this.staleAfterApply = false});

  final bool staleAfterApply;
  var _applied = false;
  String? actionId;
  Map<String, Object?>? parameters;
  String? expectedRevision;
  String? idempotencyKey;

  @override
  Future<String> apply({
    required String projectRootPath,
    required String actionId,
    required Map<String, Object?> parameters,
    required String expectedRevision,
    required String idempotencyKey,
  }) async {
    this.actionId = actionId;
    this.parameters = parameters;
    this.expectedRevision = expectedRevision;
    this.idempotencyKey = idempotencyKey;
    _applied = true;
    return 'revision-2';
  }

  @override
  Future<SmartTilePatternCanonicalSnapshot> load({
    required String projectRootPath,
  }) async {
    final revision = _applied && !staleAfterApply ? 'revision-2' : 'revision-1';
    return SmartTilePatternCanonicalSnapshot(
      revision: revision,
      manifest: ProjectManifest(
        name: 'Project',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        smartTileCatalog: ProjectSmartTileCatalog(
          patterns: _applied && !staleAfterApply
              ? const <ProjectSmartTilePattern>[_pattern]
              : const <ProjectSmartTilePattern>[],
        ),
      ),
    );
  }
}

const _pattern = ProjectSmartTilePattern(
  id: 'stone_patch',
  name: 'Pierre claire',
  usage: SmartTileUsage.path,
  width: 1,
  height: 1,
  cells: <SmartTilePatternCell>[
    SmartTilePatternCell(
      x: 0,
      y: 0,
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
);
