import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:path/path.dart' as p;

void main() {
  test('known editor bypasses remain explicit and release-blocking', () {
    final guardrail = File(
      p.join('test', 'authoring_api', 'editor_write_boundary_test.dart'),
    ).readAsStringSync();
    final block = RegExp(
      r'const _legacyStructuredAuthoringDebt = <String>\{(.*?)\};',
      dotAll: true,
    ).firstMatch(guardrail);
    expect(block, isNotNull);
    final actual = RegExp(r"'([^']+\.dart)'")
        .allMatches(block!.group(1)!)
        .map((match) => match.group(1)!)
        .toSet();
    expect(actual, _knownStructuredAuthoringDebt);
  });

  test('product and UI layers do not write structured project bytes directly',
      () async {
    final roots = [
      p.join('lib', 'src', 'application'),
      p.join('lib', 'src', 'features'),
      p.join('lib', 'src', 'ui'),
    ];
    final violations = <String>[];
    for (final root in roots) {
      await for (final entity in Directory(root).list(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final relative = p.relative(entity.path);
        if (_nonProjectStateWriters.contains(relative)) continue;
        final source = await entity.readAsString();
        if (_rawStructuredWrite.hasMatch(source)) violations.add(relative);
      }
    }
    expect(violations, isEmpty);
  });

  test('editor generic transport produces the shared golden receipt', () async {
    final root = await Directory.systemTemp.createTemp('pmcp085_editor');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    const manifest = ProjectManifest(
      name: 'PMCP-085 editor golden receipt',
      version: ProjectVersion.v6,
      maps: [],
      tilesets: [],
    );
    await File(p.join(root.path, 'project.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      flush: true,
    );
    const reader = EditorProjectFileReader();
    final queries = AuthoringQueryAdapter(fileReader: reader);
    final mutations = AuthoringMutationAdapter(
      fileReader: reader,
      queries: queries,
      projectRoots: reader,
    );
    addTearDown(mutations.closeAll);
    addTearDown(queries.closeAll);

    final plan = await mutations.plan(
      root.path,
      actionId: 'map.create',
      parameters: const {
        'mapId': 'pmcp085_golden_map',
        'width': 3,
        'height': 2,
      },
      idempotencyKey: 'pmcp085-golden-idempotency',
      requestId: 'pmcp085-golden-request',
    );
    final applied = await mutations.apply(
      plan,
      operationId: 'pmcp085-editor-apply',
    );
    final expected = jsonDecode(
      File(
        p.join(
          Directory.current.parent.path,
          'map_authoring',
          'test',
          'fixtures',
          'pmcp085_golden_receipt.json',
        ),
      ).readAsStringSync(),
    );
    expect(_stableReceipt(applied.receipt), expected);
  });
}

final RegExp _rawStructuredWrite = RegExp(
  r'(?:writeAsString|writeAsBytes)\s*\(\s*(?:jsonEncode|const JsonEncoder|JsonEncoder)',
);

const _nonProjectStateWriters = <String>{
  'lib/src/features/editor/state/editor_notifier.dart',
};

/// PMCP-085 must keep this debt exact rather than turn a generic editor
/// transport into false evidence that every existing product gesture uses it.
const _knownStructuredAuthoringDebt = <String>{
  'lib/src/application/services/map_lifecycle_transaction_service.dart',
  'lib/src/application/use_cases/map_use_cases.dart',
  'lib/src/features/editor/state/editor_notifier.dart',
  'lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart',
  'lib/src/ui/canvas/storylines_workspace.dart',
};

Map<String, Object?> _stableReceipt(AuthoringReceipt receipt) => {
      'actionId': receipt.actionId,
      'actionVersion': receipt.actionVersion,
      'status': receipt.status.wireName,
      'changes': [
        for (final entry in receipt.diff.entries)
          {
            'operation': entry.operation.wireName,
            'resource': {
              'kind': entry.resource.kind,
              'id': entry.resource.id,
            },
            'path': entry.path,
          },
      ],
    };
