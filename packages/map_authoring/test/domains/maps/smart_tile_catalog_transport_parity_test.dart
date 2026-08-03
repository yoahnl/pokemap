import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Smart Tile catalog transport budget', () {
    test('one representative mixed-256 draft fits the bounded default', () {
      final line = jsonEncode(<String, Object?>{
        'id': 'mixed-256-draft',
        'command': 'plan',
        'args': <String, Object?>{
          'projectHandle': 'project',
          'request': <String, Object?>{
            'requestId': 'request-mixed-256',
            'actionId': 'smart_tile.preset.draft.upsert',
            'actionVersion': 1,
            'workspaceHandle': 'workspace',
            'parameters': <String, Object?>{
              'draft': _representativeMaximumDraft().toJson(),
            },
            'expectedRevision': 'revision',
            'idempotencyKey': 'mixed-256',
            'dryRun': false,
          },
        },
      });
      final byteLength = utf8.encode(line).length;

      expect(byteLength, greaterThan(64 * 1024));
      expect(byteLength, lessThanOrEqualTo(defaultAuthoringJsonlMaxInputBytes));
    });

    test('default JSONL budget accepts its exact limit and rejects limit + 1',
        () async {
      final worker = JsonlWorker(api: const _DescribeOnlyReadApi());
      expect(worker.maxInputBytes, defaultAuthoringJsonlMaxInputBytes);

      final exact = await _process(
          worker,
          _describeLineWithByteLength(
            defaultAuthoringJsonlMaxInputBytes,
          ));
      expect(exact.status, AuthoringResultStatus.success);

      final overflow = await _process(
          worker,
          _describeLineWithByteLength(
            defaultAuthoringJsonlMaxInputBytes + 1,
          ));
      expect(overflow.status, AuthoringResultStatus.failure);
      expect(overflow.error?.details['domainCode'], 'worker.input_too_large');
    });
  });
}

ProjectSmartTileAuthoringDraft _representativeMaximumDraft() {
  const atlas = ProjectSmartTileAtlas(
    id: 'mixed-atlas',
    name: 'Mixed 256 atlas',
    tilesetId: 'tileset',
    cellWidth: 16,
    cellHeight: 16,
    columns: 16,
    rows: 16,
  );
  return ProjectSmartTileAuthoringDraft(
    id: 'draft-mixed-256',
    targetPresetId: 'mixed-256',
    name: 'Mixed 256 representative maximum',
    usage: SmartTileUsage.terrain,
    lastStage: SmartTileAuthoringStage.publish,
    sourceTilesetIds: const <String>['tileset'],
    atlases: const <ProjectSmartTileAtlas>[atlas],
    primaryAtlasId: atlas.id,
    materials: const <ProjectSmartTileMaterial>[
      ProjectSmartTileMaterial(
        id: 'ground',
        name: 'Ground',
        connectionGroupId: 'ground',
      ),
    ],
    defaultMaterialId: 'ground',
    allowedMaterialIds: const <String>['ground'],
    topology: SmartTileTopology.wang8,
    templateHint: SmartTileTemplateHint.mixed256,
    rules: <SmartTileRule>[
      for (var mask = 0; mask < 256; mask++)
        SmartTileRule(
          id: smartTileCanonicalRuleId(mask),
          centerMatch: const SmartTileSlotMatch.material('ground'),
          signature: smartTileSignatureForMask(
            mask,
            topology: SmartTileTopology.wang8,
          ),
          candidates: <SmartTileCandidate>[
            for (var variant = 0; variant < 4; variant++)
              SmartTileCandidate(
                id: 'mask-$mask-variant-$variant',
                weight: variant + 1,
                parts: <SmartTileVisualPart>[
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.frame(
                      frame: SmartTileFrameRef(
                        atlasId: atlas.id,
                        column: mask % 16,
                        row: mask ~/ 16,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
    ],
  );
}

String _describeLineWithByteLength(int targetBytes) {
  String encodeWithId(String id) => jsonEncode(<String, Object?>{
        'id': id,
        'command': 'describe',
        'args': const <String, Object?>{},
      });

  final minimum = encodeWithId('x');
  final missing = targetBytes - utf8.encode(minimum).length;
  if (missing < 0) throw ArgumentError.value(targetBytes, 'targetBytes');
  final result = encodeWithId('x${List<String>.filled(missing, 'x').join()}');
  expect(utf8.encode(result).length, targetBytes);
  return result;
}

Future<AuthoringResult> _process(JsonlWorker worker, String line) async =>
    AuthoringResult.fromJson(
      jsonDecode(await worker.processLine(line)) as Map<String, dynamic>,
    );

final class _DescribeOnlyReadApi implements AuthoringReadApiPort {
  const _DescribeOnlyReadApi();

  @override
  Map<String, Object?> describe() => const <String, Object?>{
        'schemaVersion': 1,
        'protocol': 'test',
        'readOnly': true,
        'commands': <Object?>[],
        'resourceKinds': <Object?>[],
      };

  @override
  Future<Map<String, Object?>> close(WorkspaceHandle workspaceHandle) =>
      throw UnsupportedError('close');

  @override
  Future<Map<String, Object?>> open(String projectRootPath) =>
      throw UnsupportedError('open');

  @override
  Future<Map<String, Object?>> query(
    ProjectHandle projectHandle,
    AuthoringQueryRequest request,
  ) =>
      throw UnsupportedError('query');

  @override
  Future<Map<String, Object?>> validate(
    ProjectHandle projectHandle, {
    Iterable<ProjectCapabilityTruthRecord> capabilityRecords = const [],
    Set<String> requiredCapabilityIds = const {},
  }) =>
      throw UnsupportedError('validate');
}
