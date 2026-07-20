import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../fixtures/border/stone_chain_line_fixture.dart';

void main() {
  group('ProjectBorderCatalog V3 contract', () {
    test('round-trips a complete stone-chain catalog through V3', () {
      final catalog = _stoneChainCatalog(allowAutoRotation: false);

      final encoded = encodeProjectBorderCatalogJson(catalog);
      final record = _recordJson(encoded);
      final draft = _definitionJson(record, published: false);
      final published = _definitionJson(record, published: true);

      expect(encoded['formatVersion'], ProjectBorderCatalog.formatVersionV3);
      expect(draft['template'], 'stoneChainLine');
      expect(published['template'], 'stoneChainLine');
      expect(
        _primitiveRoles(draft),
        <String>[
          'structureLarge',
          'structureLarge',
          'structureLarge',
          'structureMedium',
          'structureMedium',
          'filler',
          'lineCorner',
          'lineCap',
        ],
      );
      expect(decodeProjectBorderCatalogJson(encoded), catalog);
      expect(
        encodeProjectBorderCatalogJson(
          decodeProjectBorderCatalogJson(encoded),
        ),
        encoded,
      );
    });

    test('rejects stoneChainLine in V1 and V2 at the exact template path', () {
      final v3Catalog = _stoneChainCatalog();
      final v3Json = encodeProjectBorderCatalogJson(v3Catalog);
      const path = r'$.records[0].draft.definition.template';

      for (final formatVersion in <int>[
        ProjectBorderCatalog.formatVersionV1,
        ProjectBorderCatalog.formatVersionV2,
      ]) {
        final mislabeledJson = _deepCopy(v3Json)
          ..['formatVersion'] = formatVersion;
        final mislabeledCatalog = ProjectBorderCatalog(
          formatVersion: formatVersion,
          records: v3Catalog.records,
          visualSnapshots: v3Catalog.visualSnapshots,
        );

        expect(
          () => decodeProjectBorderCatalogJson(mislabeledJson),
          _formatMessage(
            '$path: template requires catalog format version 3',
          ),
          reason: 'decode V$formatVersion',
        );
        expect(
          () => encodeProjectBorderCatalogJson(mislabeledCatalog),
          _formatMessage(
            '$path: template requires catalog format version 3',
          ),
          reason: 'encode V$formatVersion',
        );
      }
    });

    test('encodes and decodes allowAutoRotation in V3', () {
      final disabledJson = encodeProjectBorderCatalogJson(
        _stoneChainCatalog(allowAutoRotation: false),
      );
      final disabledRecord = _recordJson(disabledJson);
      final disabledDraft = _definitionJson(
        disabledRecord,
        published: false,
      );
      final disabledPublished = _definitionJson(
        disabledRecord,
        published: true,
      );

      expect(
        _defaultsJson(disabledDraft)['allowAutoRotation'],
        isFalse,
      );
      expect(
        _defaultsJson(disabledPublished)['allowAutoRotation'],
        isFalse,
      );
      final disabledDecoded = decodeProjectBorderCatalogJson(disabledJson);
      expect(
        disabledDecoded
            .records.single.draft.definition.defaults.allowAutoRotation,
        isFalse,
      );
      expect(
        disabledDecoded.records.single.latestPublished!.definition.defaults
            .allowAutoRotation,
        isFalse,
      );

      final enabledJson = encodeProjectBorderCatalogJson(
        _stoneChainCatalog(),
      );
      final enabledRecord = _recordJson(enabledJson);
      expect(
        _defaultsJson(
          _definitionJson(enabledRecord, published: false),
        ),
        isNot(contains('allowAutoRotation')),
      );
      expect(
        decodeProjectBorderCatalogJson(enabledJson)
            .records
            .single
            .draft
            .definition
            .defaults
            .allowAutoRotation,
        isTrue,
      );
    });

    test('keeps the historical V2 catalog fixture byte-stable', () {
      final fixtureBytes = File(
        'test/fixtures/border/project_border_catalog_v2_wire.json',
      ).readAsStringSync().trim();
      final decoded = decodeProjectBorderCatalogJson(
        jsonDecode(fixtureBytes),
      );

      expect(decoded.formatVersion, ProjectBorderCatalog.formatVersionV2);
      expect(
        decoded.records.single.draft.definition.template,
        BorderBlueprintTemplate.connectedLine,
      );
      expect(
        decoded.records.single.draft.definition.defaults.allowAutoRotation,
        isFalse,
      );
      expect(
        jsonEncode(encodeProjectBorderCatalogJson(decoded)),
        fixtureBytes,
      );
    });
  });
}

ProjectBorderCatalog _stoneChainCatalog({bool allowAutoRotation = true}) {
  final publishedPrimitives = stoneChainPrimitives();
  final snapshots = <BorderVisualSnapshot>[
    for (final primitive in publishedPrimitives)
      stoneChainSnapshotFor(primitive),
  ];
  final parameters = stoneChainParameters(
    allowAutoRotation: allowAutoRotation,
  );
  final draftPrimitives = <BorderPrimitiveDraft>[
    for (final primitive in publishedPrimitives)
      BorderPrimitiveDraft(
        id: primitive.id,
        sourceElementId: primitive.sourceElementId,
        role: primitive.role,
        weight: primitive.weight,
        anchorPx: primitive.anchorPx,
        transforms: primitive.transforms,
        currentMetrics: primitive.publishedMetrics,
      ),
  ];
  final draftDefinition = BorderBlueprintDraftDefinition(
    name: 'Falaises Selbrume — pierres',
    previewSeed: BorderSignedInt64.fromInt(-29),
    template: BorderBlueprintTemplate.stoneChainLine,
    primitives: draftPrimitives,
    defaults: parameters,
    categoryId: 'coast',
    sortOrder: 3,
  );
  final publishedDefinition = BorderBlueprintPublishedDefinition(
    name: 'Falaises Selbrume — pierres',
    previewSeed: BorderSignedInt64.fromInt(29),
    template: BorderBlueprintTemplate.stoneChainLine,
    primitives: publishedPrimitives,
    defaults: parameters,
    categoryId: 'coast',
    sortOrder: 3,
  );

  return ProjectBorderCatalog(
    formatVersion: ProjectBorderCatalog.formatVersionV3,
    records: <BorderBlueprintRecord>[
      BorderBlueprintRecord(
        id: 'stone-chain',
        draft: BorderBlueprintDraft(
          baseRevision: 2,
          definition: draftDefinition,
        ),
        latestPublished: BorderBlueprintRevision(
          revision: 2,
          definition: publishedDefinition,
        ),
        isDeprecated: true,
      ),
    ],
    visualSnapshots: snapshots,
  );
}

Map<String, Object?> _recordJson(Map<String, Object?> catalog) =>
    (catalog['records']! as List<Object?>).single! as Map<String, Object?>;

Map<String, Object?> _definitionJson(
  Map<String, Object?> record, {
  required bool published,
}) {
  final container =
      record[published ? 'latestPublished' : 'draft']! as Map<String, Object?>;
  return container['definition']! as Map<String, Object?>;
}

Map<String, Object?> _defaultsJson(Map<String, Object?> definition) =>
    definition['defaults']! as Map<String, Object?>;

List<String> _primitiveRoles(Map<String, Object?> definition) =>
    (definition['primitives']! as List<Object?>)
        .map(
          (primitive) =>
              (primitive! as Map<String, Object?>)['role']! as String,
        )
        .toList(growable: false);

Map<String, Object?> _deepCopy(Map<String, Object?> value) =>
    jsonDecode(jsonEncode(value))! as Map<String, Object?>;

Matcher _formatMessage(String message) => throwsA(
      isA<FormatException>().having(
        (error) => error.message,
        'message',
        message,
      ),
    );
