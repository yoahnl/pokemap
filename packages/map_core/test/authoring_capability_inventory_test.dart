import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_core/src/tooling/repository_authoring_capability_collector.dart';
import 'package:test/test.dart';

void main() {
  group('AuthoringCapabilityInventory', () {
    test('sorts entries deterministically and round-trips through JSON', () {
      final inventory = AuthoringCapabilityInventory([
        _entry(
          id: 'model.project_manifest.maps',
          kind: AuthoringCapabilityKind.projectManifestField,
        ),
        _entry(
          id: 'action.map.create',
          kind: AuthoringCapabilityKind.catalogAction,
        ),
      ]);

      expect(
        inventory.entries.map((entry) => entry.id),
        ['action.map.create', 'model.project_manifest.maps'],
      );

      final encoded =
          jsonDecode(jsonEncode(inventory.toJson())) as Map<String, dynamic>;
      final decoded = AuthoringCapabilityInventory.fromJson(encoded);

      expect(decoded.toJson(), inventory.toJson());
      expect(
        AuthoringCapabilityInventory(inventory.entries.reversed).toMarkdown(),
        inventory.toMarkdown(),
      );
    });

    test('supports every explicit capability status', () {
      final entries = AuthoringCapabilityStatus.values.map(
        (status) => _entry(
          id: 'status.${status.name}',
          status: status,
          evidenceReferences: status == AuthoringCapabilityStatus.supported
              ? const ['test/status_test.dart']
              : const [],
        ),
      );

      final decoded = AuthoringCapabilityInventory.fromJson(
        AuthoringCapabilityInventory(entries).toJson(),
      );

      expect(
        decoded.entries.map((entry) => entry.status).toSet(),
        AuthoringCapabilityStatus.values.toSet(),
      );
    });

    test('sorts evidence and FG lots inside each row', () {
      final entry = _entry(
        id: 'ordered.metadata',
        evidenceReferences: const ['z_test.dart', 'a_test.dart'],
        relatedFgLots: const ['FG-020', 'FG-010'],
      );

      expect(entry.evidenceReferences, ['a_test.dart', 'z_test.dart']);
      expect(entry.relatedFgLots, ['FG-010', 'FG-020']);
    });

    test('rejects unsupported inventory format versions', () {
      expect(
        () => AuthoringCapabilityInventory.fromJson({
          'formatVersion': 2,
          'entries': const [],
        }),
        throwsFormatException,
      );
    });

    test('rejects duplicate identifiers', () {
      expect(
        () => AuthoringCapabilityInventory([
          _entry(id: 'duplicate'),
          _entry(id: 'duplicate'),
        ]),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('Duplicate'),
          ),
        ),
      );
    });

    test('requires ownership and traceability fields', () {
      for (final invalidEntry in [
        () => _entry(id: ''),
        () => _entry(id: 'missing.owner', ownerPackage: ''),
        () => _entry(id: 'missing.source', sourceReference: ''),
        () => _entry(id: 'missing.consumer', runtimeConsumer: ''),
      ]) {
        expect(invalidEntry, throwsArgumentError);
      }
    });

    test('refuses SUPPORTED without an evidence reference', () {
      expect(
        () => _entry(
          id: 'unsupported.claim',
          status: AuthoringCapabilityStatus.supported,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('evidence'),
          ),
        ),
      );
    });

    test('renders a stable Markdown matrix with required columns', () {
      final markdown = AuthoringCapabilityInventory([
        _entry(
          id: 'action.map.create',
          relatedFgLots: const ['FG-010'],
        ),
      ]).toMarkdown(title: 'Baseline');

      expect(markdown, startsWith('# Baseline\n'));
      expect(markdown, contains('| Capability | Kind | Owner | Status |'));
      expect(markdown, contains('Source | Runtime consumer | Evidence |'));
      expect(markdown, contains('`action.map.create`'));
      expect(markdown, contains('`FG-010`'));
    });
  });

  group('RepositoryAuthoringCapabilityCollector', () {
    late Directory repositoryRoot;
    late AuthoringCapabilityInventory inventory;

    setUpAll(() {
      repositoryRoot = Directory.current.parent.parent;
      inventory = RepositoryAuthoringCapabilityCollector(
        repositoryRoot: repositoryRoot,
      ).collect();
    });

    test('collects every ProjectManifest and MapData field', () {
      final ids = inventory.entries.map((entry) => entry.id).toSet();

      expect(
        ids.where((id) => id.startsWith('model.project_manifest.')),
        containsAll({
          'model.project_manifest.name',
          'model.project_manifest.maps',
          'model.project_manifest.smartTileCatalog',
          'model.project_manifest.projectedBuildingShadowCatalog',
        }),
      );
      expect(
        ids.where((id) => id.startsWith('model.map_data.')),
        containsAll({
          'model.map_data.id',
          'model.map_data.layers',
          'model.map_data.gameplayZones',
          'model.map_data.events',
        }),
      );

      final projectFieldCount = _freezedMixinFields(
        File(
          '${repositoryRoot.path}/packages/map_core/lib/src/models/'
          'project_manifest.freezed.dart',
        ),
        r'mixin _$ProjectManifest {',
      ).length;
      final mapFieldCount = _freezedMixinFields(
        File(
          '${repositoryRoot.path}/packages/map_core/lib/src/models/'
          'map_data.freezed.dart',
        ),
        r'mixin _$MapData {',
      ).length;

      expect(
        ids.where((id) => id.startsWith('model.project_manifest.')),
        hasLength(projectFieldCount),
      );
      expect(
        ids.where((id) => id.startsWith('model.map_data.')),
        hasLength(mapFieldCount),
      );
    });

    test('collects every PokeMap Eval command', () {
      final commandSource = File(
        '${repositoryRoot.path}/examples/playable_runtime_host/lib/src/'
        'evaluation/scenario/evaluation_command_catalog.dart',
      ).readAsStringSync();
      final declaredCommands = RegExp(
        r"^\s*'([^']+)': EvaluationCommandDefinition\(",
        multiLine: true,
      ).allMatches(commandSource).map((match) => match.group(1)!).toSet();
      final inventoriedCommands = inventory.entries
          .where(
            (entry) => entry.kind == AuthoringCapabilityKind.evaluationCommand,
          )
          .map((entry) => entry.id.replaceFirst('eval.command.', ''))
          .toSet();

      expect(inventoriedCommands, declaredCommands);
      expect(
        inventory.entries
            .where(
              (entry) =>
                  entry.kind == AuthoringCapabilityKind.evaluationCommand,
            )
            .every(
              (entry) =>
                  entry.status == AuthoringCapabilityStatus.supported &&
                  entry.evidenceReferences.isNotEmpty,
            ),
        isTrue,
      );
    });

    test('collects editor use cases and pure core operations', () {
      final rowsById = {
        for (final entry in inventory.entries) entry.id: entry,
      };

      expect(
        rowsById,
        contains('editor.use_case.CreateMapUseCase'),
      );
      expect(
        rowsById,
        isNot(contains('editor.use_case.PaintTerrainOnMapUseCase')),
      );
      expect(
        rowsById,
        contains('core.operation.scene_authoring_operations'),
      );
      expect(
        rowsById['editor.use_case.CreateMapUseCase']!.hasCanonicalMutation,
        isFalse,
      );
    });

    test('collects dotted actions from the approved catalog', () {
      final actionIds = inventory.entries
          .where((entry) => entry.kind == AuthoringCapabilityKind.catalogAction)
          .map((entry) => entry.id)
          .toSet();

      expect(actionIds, contains('action.project.create'));
      expect(actionIds, contains('action.map.apply_operations'));
      expect(actionIds, contains('action.playtest.start'));
    });

    test('catalog certifies Smart Tiles and contains no legacy paint actions',
        () {
      final actionIds = inventory.entries
          .where((entry) => entry.kind == AuthoringCapabilityKind.catalogAction)
          .map((entry) => entry.id.replaceFirst('action.', ''))
          .toSet();

      expect(
        actionIds.where((id) => id.startsWith('smart_tile.')).toSet(),
        <String>{
          'smart_tile.animation.delete',
          'smart_tile.animation.upsert',
          'smart_tile.atlas.upsert',
          'smart_tile.cell.erase',
          'smart_tile.cell.paint',
          'smart_tile.layer.create',
          'smart_tile.layer.delete',
          'smart_tile.layer.merge',
          'smart_tile.layer.normalize',
          'smart_tile.material.upsert',
          'smart_tile.preset.delete',
          'smart_tile.preset.draft.delete',
          'smart_tile.preset.draft.upsert',
          'smart_tile.preset.publish',
        },
      );
      expect(
        actionIds.where(
          (id) =>
              id.startsWith('terrain.') ||
              id.startsWith('path.') ||
              id.startsWith('surface.'),
        ),
        isEmpty,
      );
    });

    test('is byte-stable over repeated collection', () {
      final second = RepositoryAuthoringCapabilityCollector(
        repositoryRoot: repositoryRoot,
      ).collect();

      expect(
        jsonEncode(second.toJson()),
        jsonEncode(inventory.toJson()),
      );
      expect(second.toMarkdown(), inventory.toMarkdown());
    });

    test('never marks a capability supported without an existing proof', () {
      for (final entry in inventory.entries.where(
        (entry) => entry.status == AuthoringCapabilityStatus.supported,
      )) {
        expect(entry.evidenceReferences, isNotEmpty, reason: entry.id);
        for (final evidence in entry.evidenceReferences) {
          expect(
            File('${repositoryRoot.path}/$evidence').existsSync(),
            isTrue,
            reason: '${entry.id} -> $evidence',
          );
        }
      }
    });
  });
}

Set<String> _freezedMixinFields(File file, String marker) {
  final source = file.readAsStringSync();
  final start = source.indexOf(marker);
  expect(start, isNonNegative, reason: marker);
  final end = source.indexOf('  /// Serializes this', start);
  expect(end, isNonNegative, reason: marker);
  final block = source.substring(start, end);
  return RegExp(
    r'^\s+.+?\s+get\s+([a-zA-Z][a-zA-Z0-9_]*)\s*(?:=>|;)',
    multiLine: true,
  )
      .allMatches(block)
      .map((match) => match.group(1)!)
      .where((name) => name != 'copyWith')
      .toSet();
}

AuthoringCapabilityInventoryEntry _entry({
  required String id,
  AuthoringCapabilityKind kind = AuthoringCapabilityKind.editorUseCase,
  String ownerPackage = 'map_editor',
  AuthoringCapabilityStatus status = AuthoringCapabilityStatus.missing,
  String sourceReference = 'packages/map_editor/lib/example.dart',
  String runtimeConsumer = 'map_runtime',
  List<String> evidenceReferences = const [],
  List<String> relatedFgLots = const [],
}) {
  return AuthoringCapabilityInventoryEntry(
    id: id,
    kind: kind,
    ownerPackage: ownerPackage,
    status: status,
    sourceReference: sourceReference,
    runtimeConsumer: runtimeConsumer,
    evidenceReferences: evidenceReferences,
    relatedFgLots: relatedFgLots,
    hasCanonicalMutation: false,
  );
}
