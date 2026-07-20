import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectManifest Border catalog integration', () {
    test('legacy manifest defaults to empty V1 without injecting JSON', () {
      final legacyJson = _minimalManifestJson();

      final manifest = ProjectManifest.fromJson(legacyJson);
      final encoded = manifest.toJson();

      expect(manifest.version, ProjectVersion.v1);
      expect(manifest.borderCatalog, const ProjectBorderCatalog.empty());
      expect(encoded.containsKey('borderCatalog'), isFalse);
      expect(legacyJson.containsKey('borderCatalog'), isFalse);
    });

    test('explicit empty catalog decodes but is canonically omitted', () {
      final json = _minimalManifestJson()
        ..['borderCatalog'] = <String, Object?>{
          'formatVersion': 1,
          'records': <Object?>[],
          'visualSnapshots': <Object?>[],
        };

      final manifest = ProjectManifest.fromJson(json);

      expect(manifest.borderCatalog.isEmpty, isTrue);
      expect(manifest.toJson().containsKey('borderCatalog'), isFalse);
    });

    test('explicit empty V2 catalog preserves its independent subformat', () {
      final json = _minimalManifestJson()
        ..['version'] = 'v2'
        ..['borderCatalog'] = <String, Object?>{
          'formatVersion': ProjectBorderCatalog.formatVersionV2,
          'records': <Object?>[],
          'visualSnapshots': <Object?>[],
        };

      final manifest = ProjectManifest.fromJson(json);
      final encoded = manifest.toJson();

      expect(
        manifest.borderCatalog.formatVersion,
        ProjectBorderCatalog.formatVersionV2,
      );
      expect(encoded['borderCatalog'], json['borderCatalog']);
      expect(
        ProjectManifest.fromJson(encoded).borderCatalog.formatVersion,
        ProjectBorderCatalog.formatVersionV2,
      );
    });

    test('explicit null, malformed, and future catalogs are rejected', () {
      for (final (invalid, expectedPath) in <(Object?, String)>[
        (null, r'$.borderCatalog'),
        (true, r'$.borderCatalog'),
        (<Object?>[], r'$.borderCatalog'),
        (
          <String, Object?>{
            'formatVersion': 5,
            'records': <Object?>[],
            'visualSnapshots': <Object?>[],
          },
          r'$.borderCatalog.formatVersion',
        ),
      ]) {
        final json = _minimalManifestJson()..['borderCatalog'] = invalid;
        expect(
          () => ProjectManifest.fromJson(json),
          _formatAt(expectedPath),
          reason: '$invalid',
        );
      }
    });

    test('V1 JSON rejects records or snapshots with absent/null/V1 version',
        () {
      for (final catalog in <ProjectBorderCatalog>[
        ProjectBorderCatalog(
          records: <BorderBlueprintRecord>[_record('coast')],
        ),
        ProjectBorderCatalog(
          visualSnapshots: <BorderVisualSnapshot>[_snapshot('a')],
        ),
      ]) {
        for (final version in <Object?>[_absentVersion, null, 'v1']) {
          final json = _minimalManifestJson()
            ..['borderCatalog'] = encodeProjectBorderCatalogJson(catalog);
          if (!identical(version, _absentVersion)) {
            json['version'] = version;
          }

          expect(
            () => ProjectManifest.fromJson(json),
            _formatAt(r'$.borderCatalog'),
            reason: '$version / ${catalog.records.length} records',
          );
        }
      }
    });

    test('V2 manifest round-trips one strict nonempty catalog', () {
      final catalog = ProjectBorderCatalog(
        records: <BorderBlueprintRecord>[_record('coast')],
      );
      final manifest = ProjectManifest(
        name: 'Border V2',
        version: ProjectVersion.v2,
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        borderCatalog: catalog,
      );

      final encoded = manifest.toJson();
      final wire = jsonDecode(jsonEncode(encoded)) as Map<String, dynamic>;
      final decoded = ProjectManifest.fromJson(wire);

      expect(encoded['version'], 'v2');
      expect(encoded['borderCatalog'], encodeProjectBorderCatalogJson(catalog));
      expect(decoded, manifest);
      expect(decoded.borderCatalog.records.single.id, 'coast');
    });

    test('copyWith preserves and can replace the Border catalog', () {
      final catalog = ProjectBorderCatalog(
        records: <BorderBlueprintRecord>[_record('coast')],
      );
      final manifest = ProjectManifest(
        name: 'Copy',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
      );

      final updated = manifest.copyWith(borderCatalog: catalog);

      expect(manifest.borderCatalog.isEmpty, isTrue);
      expect(updated.borderCatalog, catalog);
      expect(updated.name, manifest.name);
    });
  });
}

Map<String, dynamic> _minimalManifestJson() => <String, dynamic>{
      'name': 'Legacy',
      'maps': <Object?>[],
      'tilesets': <Object?>[],
    };

Matcher _formatAt(String path) => throwsA(
      isA<FormatException>().having(
        (error) => error.message,
        'message',
        startsWith('$path:'),
      ),
    );

BorderBlueprintRecord _record(String id) => BorderBlueprintRecord(
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

const Object _absentVersion = Object();

BorderVisualSnapshot _snapshot(String digit) {
  final fingerprint = digit * 64;
  return BorderVisualSnapshot(
    id: 'border-snapshot-sha256:$fingerprint',
    contentFingerprint: fingerprint,
    frames: <BorderVisualFrameSnapshot>[
      BorderVisualFrameSnapshot(
        relativeAssetPath: 'assets/borders/snapshots/$digit.png',
        sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 8, height: 8),
        durationMs: 100,
      ),
    ],
  );
}
