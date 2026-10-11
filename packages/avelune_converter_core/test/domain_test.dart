import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'contracts_test.dart' show fixture;

Map<String, Object?> event({int id = 1, int x = 0}) => {
      'sourceEventId': id,
      'name': 'Event',
      'x': x,
      'y': 0,
      'pages': [
        {
          'originalPageIndex': 0,
          'conditionsDataRef': null,
          'triggerCode': 0,
          'commands': [
            {
              'originalIndex': 0,
              'code': 101,
              'indent': 0,
              'parameters': [
                {
                  'inert': [null, true, 'text']
                }
              ],
              'sourceLocator': {
                'file': 'Data/Map001.rxdata',
                'mapId': 1,
                'eventId': id,
                'pageIndex': 0,
                'commandIndex': 0,
                'tileId': null,
                'line': null
              },
            }
          ],
          'rawDataRef': null,
        }
      ],
    };

void main() {
  test('IR preserves the non-square row-major cell sequence', () {
    final ir = SourceMapIr.fromJson(fixture('source_map_ir'));
    expect(ir.map.layers.first.cells, [384, 385, 386, 387, 388, 389]);
    expect(ir.map.layers.first.cells[1 * ir.map.width + 2], 389);
  });
  test('IR rejects a short layer', () {
    final input = fixture('source_map_ir');
    ((input['map'] as Map)['layers'] as List)[0]['cells'].removeLast();
    expect(() => decodeContract(input), throwsFormatException);
  });
  test('IR rejects duplicate z', () {
    final input = fixture('source_map_ir');
    ((input['map'] as Map)['layers'] as List)[1]['sourceZ'] = 0;
    expect(() => decodeContract(input), throwsFormatException);
  });
  test('IR rejects an event outside the map', () {
    final input = fixture('source_map_ir');
    (input['map'] as Map)['events'] = [event(x: 3)];
    expect(() => decodeContract(input), throwsFormatException);
  });
  test('IR rejects duplicate event IDs', () {
    final input = fixture('source_map_ir');
    (input['map'] as Map)['events'] = [event(), event()];
    expect(() => decodeContract(input), throwsFormatException);
  });
  test('IR rejects a locator that names another command', () {
    final input = fixture('source_map_ir');
    final e = event();
    ((e['pages'] as List)[0]['commands'] as List)[0]['sourceLocator']
        ['commandIndex'] = 4;
    (input['map'] as Map)['events'] = [e];
    expect(() => decodeContract(input), throwsFormatException);
  });
  test('IR rejects duplicate command indices', () {
    final input = fixture('source_map_ir');
    final e = event();
    final commands = (e['pages'] as List)[0]['commands'] as List;
    commands.add(commands.first);
    (input['map'] as Map)['events'] = [e];
    expect(() => decodeContract(input), throwsFormatException);
  });
  test('IR rejects duplicate page indices', () {
    final input = fixture('source_map_ir');
    final e = event();
    final pages = e['pages'] as List;
    pages.add(jsonDecode(jsonEncode(pages.first)));
    (input['map'] as Map)['events'] = [e];
    expect(() => decodeContract(input), throwsFormatException);
  });
  test('JSON integer semantics accept integral doubles', () {
    final input = fixture('source_map_ir');
    (input['map'] as Map)['width'] = 3.0;
    expect(SourceMapIr.fromJson(input).map.width, 3);
  });
  test('unknown nested fields report their exact path', () {
    final input = fixture('asset_candidate');
    (input['parts'] as List)[0]['sourceRect']['surprise'] = 1;
    expect(
        () => decodeContract(input),
        throwsA(isA<ContractError>()
            .having((e) => e.path, 'path', r'$.parts[0].sourceRect.surprise')));
  });
  for (final name in ['source_map_ir', 'asset_candidate', 'conversion_plan']) {
    test('$name rejects missing required fields', () {
      final input = fixture(name)..remove('sourceSnapshotHash');
      expect(() => decodeContract(input), throwsFormatException);
    });
  }
  test('candidate preserves the bottomCenter border anchor', () {
    final candidate = AssetCandidate.fromJson(fixture('asset_candidate'));
    expect(candidate.anchor.y, candidate.canvasSize.height);
  });
  test('candidate rejects a source rectangle outside its image', () {
    final input = fixture('asset_candidate');
    (input['parts'] as List)[0]['sourceRect']['x'] = 200;
    expect(() => decodeContract(input), throwsFormatException);
  });
  test('candidate rejects unresolved image references', () {
    final input = fixture('asset_candidate');
    (input['parts'] as List)[0]['sourceFileId'] = 'unknown';
    expect(() => decodeContract(input), throwsFormatException);
  });
  test('candidate rejects duplicate source IDs', () {
    final input = fixture('asset_candidate');
    (input['sources'] as List)
        .add(jsonDecode(jsonEncode((input['sources'] as List).first)));
    expect(() => decodeContract(input), throwsFormatException);
  });
  test('candidate rejects duplicate part IDs', () {
    final input = fixture('asset_candidate');
    (input['parts'] as List)
        .add(jsonDecode(jsonEncode((input['parts'] as List).first)));
    expect(() => decodeContract(input), throwsFormatException);
  });
  test('candidate checks the rotated destination extent', () {
    final input = fixture('asset_candidate');
    (input['parts'] as List)[0]['sourceRect']['height'] = 128;
    (input['parts'] as List)[0]['quarterTurns'] = 1;
    expect(() => decodeContract(input), throwsFormatException);
  });
  test('candidate accepts a rectangular quarter-turn in its new canvas', () {
    final input = fixture('asset_candidate');
    (input['parts'] as List)[0]['sourceRect']['height'] = 128;
    (input['parts'] as List)[0]['quarterTurns'] = 1;
    input['canvasSize'] = {'width': 128, 'height': 96};
    (input['anchor'] as Map)['x'] = 64;
    expect(AssetCandidate.fromJson(input).parts.first.quarterTurns, 1);
  });
  test('candidate rejects a negative offset clipping the canvas', () {
    final input = fixture('asset_candidate');
    (input['parts'] as List)[0]['destinationOffset']['x'] = -1;
    expect(() => decodeContract(input), throwsFormatException);
  });
  test('candidate rejects an inconsistent anchor convention', () {
    final input = fixture('asset_candidate');
    (input['anchor'] as Map)['x'] = 40;
    expect(() => decodeContract(input), throwsFormatException);
  });
  test('candidate rejects stale approved revision', () {
    final input = fixture('asset_candidate')
      ..['state'] = 'approved'
      ..['revision'] = 2
      ..['approvedRevision'] = 1;
    expect(() => decodeContract(input), throwsFormatException);
  });
  test('candidate rejects approval on an unapproved state', () {
    final input = fixture('asset_candidate')..['approvedRevision'] = 1;
    expect(() => decodeContract(input), throwsFormatException);
  });
  test('capability rejects declaration-only supported claims', () {
    final input = fixture('target_capabilities');
    (input['capabilities'] as List)[0]['status'] = 'supported';
    (input['capabilities'] as List)[0]['evidence'] = [
      {
        'type': 'codeRead',
        'summary': 'Declaration',
        'reference': 'file:declaration'
      }
    ];
    expect(() => decodeContract(input), throwsFormatException);
  });
  test('capability rejects duplicate IDs', () {
    final input = fixture('target_capabilities');
    (input['capabilities'] as List)
        .add(jsonDecode(jsonEncode((input['capabilities'] as List).first)));
    expect(() => decodeContract(input), throwsFormatException);
  });
  test('review rejects duplicate decision IDs', () {
    final input = fixture('review_decisions');
    (input['decisions'] as List)
        .add(jsonDecode(jsonEncode((input['decisions'] as List).first)));
    expect(() => decodeContract(input), throwsFormatException);
  });
  test('plan rejects duplicate operation IDs', () {
    final input = fixture('conversion_plan');
    (input['operations'] as List)
        .add(jsonDecode(jsonEncode((input['operations'] as List).first)));
    expect(() => decodeContract(input), throwsFormatException);
  });
  test('plan rejects duplicate selected map IDs', () {
    final input = fixture('conversion_plan')..['selectedSourceMapIds'] = [1, 1];
    expect(() => decodeContract(input), throwsFormatException);
  });
  test('plan rejects an escaping destination folder name', () {
    final input = fixture('conversion_plan');
    (input['outputPolicy'] as Map)['destinationFolderName'] = '../target';
    expect(() => decodeContract(input), throwsFormatException);
  });
  test('report rejects counts greater than their denominator', () {
    final input = fixture('conversion_report');
    (input['coverage'] as List)[0]['extracted'] = 2;
    expect(() => decodeContract(input), throwsFormatException);
  });
  test('report does not sum extraction and adaptation stages', () {
    final input = fixture('conversion_report');
    (input['coverage'] as List)[0]['adapted'] = 1;
    expect(ConversionReport.fromJson(input).coverage.first.adapted, 1);
  });
  test('report keeps native, visual and gameplay checks independent', () {
    final input = fixture('conversion_report');
    (input['checks'] as Map)['nativeLoad'] = 'passed';
    final report = ConversionReport.fromJson(input);
    expect(report.checks.nativeLoad, CheckStatus.passed);
    expect(report.checks.gameplayTrace, CheckStatus.notRun);
    expect(report.checks.visualParity, CheckStatus.notRun);
  });
  test('deep immutable JSON preserves inert unknown parameters', () {
    final input = fixture('source_map_ir');
    (input['map'] as Map)['events'] = [event()];
    final ir = SourceMapIr.fromJson(input);
    final before = ir.canonicalHash;
    (((input['map'] as Map)['events'] as List)[0]['pages'] as List)[0]
        ['commands'][0]['parameters'][0]['inert'][2] = 'changed';
    expect(ir.canonicalHash, before);
    expect(
        () => ir.map.events.first.pages.first.commands.first.parameters.add(1),
        throwsUnsupportedError);
    expect(() => ir.toJson()['exampleOnly'] = false, throwsUnsupportedError);
  });
  test('canonical JSON sorts objects and preserves semantic list order', () {
    expect(
        canonicalJsonOf({
          'b': 1,
          'a': [2, 1]
        }),
        '{"a":[2,1],"b":1}');
    expect(
        canonicalHashOf({
          'b': 1,
          'a': [2, 1]
        }),
        canonicalHashOf({
          'a': [2, 1],
          'b': 1
        }));
    expect(canonicalHashOf([1, 2]), isNot(canonicalHashOf([2, 1])));
  });
  test('JSON quotas reject deeply nested opaque values', () {
    expect(
        () => canonicalJsonOf([
              [
                [1]
              ]
            ], limits: const ContractLimits(maxDepth: 2)),
        throwsFormatException);
  });
  test('inert JSON rejects non-finite numbers and callbacks', () {
    for (final value in [double.nan, double.infinity, () {}]) {
      expect(() => canonicalJsonOf(value), throwsFormatException);
    }
  });
  test('inert JSON rejects cycles', () {
    final list = <Object?>[];
    list.add(list);
    expect(() => canonicalJsonOf(list), throwsFormatException);
  });
}
