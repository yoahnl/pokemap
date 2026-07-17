import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectBorderCatalog', () {
    test('distinguishes the V1 default from the latest supported version', () {
      expect(ProjectBorderCatalog().formatVersion,
          ProjectBorderCatalog.formatVersionV1);
      expect(
        ProjectBorderCatalog.latestSupportedFormatVersion,
        ProjectBorderCatalog.formatVersionV2,
      );
      expect(
        ProjectBorderCatalog.currentFormatVersion,
        ProjectBorderCatalog.latestSupportedFormatVersion,
      );
    });

    test('freezes records and snapshots with ordered value equality', () {
      final records = <BorderBlueprintRecord>[_record('coast')];
      final snapshots = <BorderVisualSnapshot>[_snapshot()];
      final catalog = ProjectBorderCatalog(
        records: records,
        visualSnapshots: snapshots,
      );

      records.clear();
      snapshots.clear();

      expect(catalog.formatVersion, ProjectBorderCatalog.formatVersionV1);
      expect(catalog.records, hasLength(1));
      expect(catalog.visualSnapshots, hasLength(1));
      expect(catalog.recordById('coast'), isNotNull);
      expect(catalog.visualSnapshotById(_snapshotId), isNotNull);
      expect(() => catalog.records.clear(), throwsUnsupportedError);
      expect(() => catalog.visualSnapshots.clear(), throwsUnsupportedError);
      expect(
        catalog,
        ProjectBorderCatalog(
          records: <BorderBlueprintRecord>[_record('coast')],
          visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
        ),
      );
    });

    test('record order participates in catalog equality', () {
      final first = ProjectBorderCatalog(
        records: <BorderBlueprintRecord>[_record('a'), _record('b')],
      );
      final second = ProjectBorderCatalog(
        records: <BorderBlueprintRecord>[_record('b'), _record('a')],
      );

      expect(first, isNot(second));
    });

    test('empty V1 catalog is immutable', () {
      const catalog = ProjectBorderCatalog.empty();

      expect(catalog.formatVersion, 1);
      expect(catalog.isEmpty, isTrue);
      expect(() => catalog.records.add(_record('x')), throwsUnsupportedError);
    });

    test('accepts V2 and rejects unknown versions and duplicate identities',
        () {
      expect(
        ProjectBorderCatalog(
          formatVersion: ProjectBorderCatalog.formatVersionV2,
        ).formatVersion,
        ProjectBorderCatalog.formatVersionV2,
      );
      for (final version in <int>[0, 3]) {
        expect(
          () => ProjectBorderCatalog(formatVersion: version),
          throwsA(isA<ValidationException>()),
        );
      }
      expect(
        () => ProjectBorderCatalog(
          records: <BorderBlueprintRecord>[_record('same'), _record('same')],
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('same'),
          ),
        ),
      );
      expect(
        () => ProjectBorderCatalog(
          visualSnapshots: <BorderVisualSnapshot>[_snapshot(), _snapshot()],
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains(_snapshotId),
          ),
        ),
      );
    });
  });
}

const String _fingerprint =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const String _snapshotId = 'border-snapshot-sha256:$_fingerprint';

BorderBlueprintRecord _record(String id) {
  return BorderBlueprintRecord(
    id: id,
    draft: BorderBlueprintDraft(
      baseRevision: 0,
      definition:
          BorderBlueprintDefinition<BorderPrimitiveDraft, BorderGroundDraft>(
        name: 'Border $id',
        previewSeed: BorderSignedInt64.zero,
        template: BorderBlueprintTemplate.organicEdge,
        primitives: const <BorderPrimitiveDraft>[],
        defaults: BorderGenerationParams(
          irregularityPermille: 0,
          detailDensityPermille: 0,
          variationPermille: 0,
          maxOverlapPx: 0,
          gapTolerancePx: 0,
          depthRows: 1,
        ),
        sortOrder: 0,
      ),
    ),
  );
}

BorderVisualSnapshot _snapshot() {
  return BorderVisualSnapshot(
    id: _snapshotId,
    contentFingerprint: _fingerprint,
    frames: <BorderVisualFrameSnapshot>[
      BorderVisualFrameSnapshot(
        relativeAssetPath: 'assets/borders/snapshots/a.png',
        sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 8, height: 8),
        durationMs: 100,
      ),
    ],
  );
}
