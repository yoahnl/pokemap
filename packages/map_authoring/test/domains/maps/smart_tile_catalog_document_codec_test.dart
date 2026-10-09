import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/domains/assets/resource_information_document.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final writer
      in <String, List<int> Function(ProjectSnapshot, ProjectManifest)>{
    'resource': encodeResourceInformationDocument,
    'lifecycle': encodeProjectAuthoringDocument,
  }.entries) {
    for (final edit in [
      'offset',
      'reorder',
      'insert',
      'delete',
      'reorderOffset',
      'replaceSource'
    ]) {
      test('${writer.key} keeps visual extensions with their part after $edit',
          () {
        final initial = _manifest();
        final first = initial.smartTileCatalog.presets.single.rules.single
            .candidates.single.parts.single;
        final second = first.copyWith(
            source: const SmartTileVisualSource.frame(
                frame: SmartTileFrameRef(atlasId: 'atlas', column: 1, row: 0)),
            offsetX: 42);
        final added = first.copyWith(
            source: const SmartTileVisualSource.frame(
                frame: SmartTileFrameRef(atlasId: 'atlas', column: 2, row: 0)));
        final manifest = _withParts(initial, [first, second]);
        final raw = _expanded(manifest);
        final rawParts = _parts(raw);
        for (var index = 0; index < rawParts.length; index++) {
          rawParts[index]['extension'] = index == 0 ? 'first' : 'second';
          _object(rawParts[index]['transform'])['extension'] =
              index == 0 ? 'first-transform' : 'second-transform';
        }
        final (parts, markers) = switch (edit) {
          'offset' => (
              [first.copyWith(offsetX: 7), second],
              ['first', 'second']
            ),
          'reorder' => ([second, first], ['second', 'first']),
          'insert' => ([added, first, second], [null, 'first', 'second']),
          'delete' => ([second], ['second']),
          'reorderOffset' => (
              [second.copyWith(offsetX: 13), first.copyWith(offsetX: 7)],
              ['second', 'first']
            ),
          'replaceSource' => ([added, second], [null, 'second']),
          _ => throw StateError('Unknown edit'),
        };
        final next = _withParts(manifest, parts);
        final before = utf8.encode(jsonEncode(raw));
        final snapshot = _snapshot(manifest, before);
        final bytes = writer.value(snapshot, next);
        final actual = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        expect(ProjectManifest.fromJson(actual), next);
        final actualParts = _parts(actual);
        expect(actualParts.map((value) => value['extension']), markers);
        for (var index = 0; index < actualParts.length; index++) {
          final transform = actualParts[index]['transform'];
          expect(transform is Map ? transform['extension'] : null,
              markers[index] == null ? null : '${markers[index]}-transform');
        }
        expect(snapshot.resourceBytes('project'), before);
      });
    }

    test(
        '${writer.key} refuses ambiguous edits before reassigning visual extensions',
        () {
      final initial = _manifest();
      final first = initial.smartTileCatalog.presets.single.rules.single
          .candidates.single.parts.single;
      final manifest =
          _withParts(initial, [first, first.copyWith(offsetX: 42)]);
      final raw = _expanded(manifest);
      final rawParts = _parts(raw);
      rawParts[0]['extension'] = 'first';
      rawParts[1]['extension'] = 'second';
      final before = utf8.encode(jsonEncode(raw));
      final snapshot = _snapshot(manifest, before);
      final next = _withParts(
          manifest, [first.copyWith(offsetX: 7), first.copyWith(offsetX: 13)]);
      expect(
          () => writer.value(snapshot, next),
          throwsA(isA<FormatException>().having((value) => value.message,
              'message', contains('ambiguous identity'))));
      expect(snapshot.resourceBytes('project'), before);
    });

    test(
        '${writer.key} normalizes the entire prior catalog and keeps extensions',
        () {
      final manifest = _manifest();
      final raw = _expanded(manifest);
      final catalog = _object(raw['smartTileCatalog']);
      catalog['extension'] = {'catalog': 1};
      final material = _object((catalog['materials'] as List).single);
      material['extension'] = {'material': 2};
      final preset = _object((catalog['presets'] as List).single);
      preset['extension'] = {'preset': 3};
      final rule = _object((preset['rules'] as List).single);
      rule['extension'] = {'rule': 4};
      _object(rule['signature'])['extension'] = {'signature': 5};
      _object(rule['signature'])['futureSlot'] = {'kind': 'any'};
      _object(_object(rule['signature'])['northEdge'])['extension'] = {
        'slot': 12
      };
      final candidate = _object((rule['candidates'] as List).single);
      candidate['extension'] = {'candidate': 6};
      final part = _object((candidate['parts'] as List).single);
      part['extension'] = {'part': 7};
      _object(part['transform'])['extension'] = {'transform': 8};
      _object(_object(part['source'])['frame'])['extension'] = {'frame': 9};
      final scenario = _object(
          (_object(preset['coverageProfile'])['requiredScenarios'] as List)
              .single);
      scenario['extension'] = {'scenario': 10};
      _object(scenario['signature'])['extension'] = {'exactSignature': 11};
      _object(scenario['signature'])['futureSlot'] = null;
      raw['extension'] = {
        'root': [3, 1, 2]
      };
      final prior = ProjectManifest.fromJson(raw);
      final next = prior.copyWith(
          smartTileCatalog: ProjectSmartTileCatalog(
        materials: prior.smartTileCatalog.materials,
        presets: [
          ...prior.smartTileCatalog.presets,
          prior.smartTileCatalog.presets.single.copyWith(id: 'new-preset')
        ],
      ));
      final before =
          utf8.encode(const JsonEncoder.withIndent('  ').convert(raw));
      final snapshot = _snapshot(prior, before);
      final bytes = writer.value(snapshot, next);
      final actual = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      expect(utf8.decode(bytes), isNot(contains('\n')));
      expect(ProjectManifest.fromJson(actual), next);
      expect({...actual}..remove('smartTileCatalog'),
          {...raw}..remove('smartTileCatalog'));
      final actualCatalog = _object(actual['smartTileCatalog']);
      expect(actualCatalog['extension'], catalog['extension']);
      final actualMaterial =
          _object((actualCatalog['materials'] as List).single);
      expect(actualMaterial, isNot(contains('isEmpty')));
      expect(actualMaterial['extension'], material['extension']);
      final actualPreset = _object((actualCatalog['presets'] as List).first);
      expect(actualPreset['extension'], preset['extension']);
      final actualRule = _object((actualPreset['rules'] as List).single);
      expect(actualRule['signature'], {
        'extension': {'signature': 5},
        'northEdge': {
          'kind': 'any',
          'extension': {'slot': 12}
        },
        'futureSlot': {'kind': 'any'},
      });
      expect(actualRule['extension'], rule['extension']);
      final actualCandidate =
          _object((actualRule['candidates'] as List).single);
      expect(actualCandidate, isNot(contains('weight')));
      expect(actualCandidate['extension'], candidate['extension']);
      final actualPart = _object((actualCandidate['parts'] as List).single);
      expect(actualPart, isNot(contains('offsetX')));
      expect(actualPart['extension'], part['extension']);
      expect(actualPart['transform'], {
        'extension': {'transform': 8}
      });
      final actualFrame = _object(_object(actualPart['source'])['frame']);
      expect(actualFrame, isNot(contains('columnSpan')));
      expect(actualFrame['extension'], {'frame': 9});
      final actualScenario = _object(
          (_object(actualPreset['coverageProfile'])['requiredScenarios']
                  as List)
              .single);
      expect(actualScenario['extension'], scenario['extension']);
      expect(actualScenario['signature'], {
        'extension': {'exactSignature': 11},
        'futureSlot': null,
      });
      final newPreset = _object((actualCatalog['presets'] as List).last);
      expect(newPreset, isNot(contains('extension')));
      expect(snapshot.resourceBytes('project'), before);
    });

    test(
        '${writer.key} preserves nonneutral values during full-catalog normalization',
        () {
      final manifest = _manifest(nonneutral: true);
      final raw = _expanded(manifest);
      final next = manifest.copyWith(name: 'Changed');
      final before = utf8.encode(jsonEncode(raw));
      final bytes = writer.value(_snapshot(manifest, before), next);
      final actual = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      expect(ProjectManifest.fromJson(actual), next);
      final catalog = _object(actual['smartTileCatalog']);
      final preset = _object((catalog['presets'] as List).single);
      final rule = _object((preset['rules'] as List).single);
      expect(_object(rule['signature']), {
        'northEdge': {'kind': 'same'}
      });
      final candidate = _object((rule['candidates'] as List).single);
      expect(candidate['weight'], 5);
      final part = _object((candidate['parts'] as List).single);
      expect(part['transform'], {'quarterTurns': 3, 'flipX': true});
      expect(part['offsetX'], -2);
      expect(
          _object((catalog['materials'] as List).single)['editorColorArgb'], 0);
    });
  }
}

ProjectManifest _manifest({bool nonneutral = false}) => ProjectManifest(
      name: 'Original',
      version: ProjectVersion.v9,
      maps: const [],
      tilesets: const [],
      settings: const ProjectSettings(dimension: ProjectDimension.threeD),
      globalProperties: const {'campaign': 'unchanged'},
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: [
          ProjectSmartTileMaterial(
              id: 'grass',
              name: 'Grass',
              connectionGroupId: 'ground',
              editorColorArgb: nonneutral ? 0 : null)
        ],
        presets: [
          ProjectSmartTilePreset(
            id: 'old-preset',
            name: 'Old',
            usage: SmartTileUsage.terrain,
            topology: SmartTileTopology.uniform,
            status: SmartTilePresetStatus.published,
            coveragePolicy: SmartTileCoveragePolicy.complete,
            coverageProfile: const SmartTileCoverageProfile(
                mode: SmartTileCoverageMode.explicit,
                requiredScenarios: [
                  SmartTileCoverageScenario(
                      id: 'center', centerMaterialId: 'grass')
                ]),
            transformPolicy: const SmartTileTransformPolicy(),
            defaultMaterialId: 'grass',
            allowedMaterialIds: const ['grass'],
            rules: [
              SmartTileRule(
                  id: 'rule',
                  centerMatch: const SmartTileSlotMatch.material('grass'),
                  signature: nonneutral
                      ? const SmartTileSignature(
                          northEdge: SmartTileSlotMatch.same())
                      : const SmartTileSignature(),
                  candidates: [
                    SmartTileCandidate(
                        id: 'candidate',
                        weight: nonneutral ? 5 : 1,
                        parts: [
                          SmartTileVisualPart(
                            source: const SmartTileVisualSource.frame(
                                frame: SmartTileFrameRef(
                                    atlasId: 'atlas', column: 0, row: 0)),
                            transform: nonneutral
                                ? const SmartTileSpriteTransform(
                                    quarterTurns: 3, flipX: true)
                                : const SmartTileSpriteTransform(),
                            offsetX: nonneutral ? -2 : 0,
                          )
                        ])
                  ])
            ],
          )
        ],
      ),
    );

Map<String, dynamic> _expanded(ProjectManifest manifest) {
  final raw = jsonDecode(jsonEncode(manifest.toJson())) as Map<String, dynamic>;
  final catalog = _object(raw['smartTileCatalog']);
  catalog['materials'] = manifest.smartTileCatalog.materials
      .map((value) => value.toJson())
      .toList();
  catalog['presets'] =
      manifest.smartTileCatalog.presets.map((value) => value.toJson()).toList();
  return jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
}

ProjectManifest _withParts(
    ProjectManifest manifest, List<SmartTileVisualPart> parts) {
  final catalog = manifest.smartTileCatalog;
  final preset = catalog.presets.single;
  final rule = preset.rules.single;
  return manifest.copyWith(
      smartTileCatalog:
          ProjectSmartTileCatalog(materials: catalog.materials, presets: [
    preset.copyWith(rules: [
      rule.copyWith(candidates: [rule.candidates.single.copyWith(parts: parts)])
    ])
  ]));
}

List<Map<String, dynamic>> _parts(Map<String, dynamic> manifest) {
  final catalog = _object(manifest['smartTileCatalog']);
  final preset = _object((catalog['presets'] as List).single);
  final rule = _object((preset['rules'] as List).single);
  final candidate = _object((rule['candidates'] as List).single);
  return (candidate['parts'] as List).cast<Map<String, dynamic>>();
}

ProjectSnapshot _snapshot(ProjectManifest manifest, List<int> bytes) {
  final fingerprint =
      computeAuthoringBytesFingerprint(bytes, logicalName: 'project.json');
  return ProjectSnapshot(
      projectHandle: const ProjectHandle('prj_codec'),
      revision: fingerprint,
      manifest: manifest,
      maps: const [],
      resourceFingerprints: {'project': fingerprint},
      resourceBytes: {'project': bytes});
}

Map<String, dynamic> _object(Object? value) => value as Map<String, dynamic>;
