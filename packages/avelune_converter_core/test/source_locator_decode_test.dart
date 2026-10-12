import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

void main() {
  final source = <String, Object?>{
    'file': 'Data/Map098.rxdata',
    'mapId': 98,
    'eventId': 4,
    'pageIndex': 0,
    'commandIndex': 2,
    'tileId': null,
    'line': null,
  };

  test('a recipe locator preserves its exact source identity and is frozen',
      () {
    final input = Map<String, Object?>.from(source);
    final locator = SourceLocator.fromJson(input);
    input['mapId'] = 99;
    expect(locator.toJson(), source);
    expect(locator.mapId, 98);
    expect(locator.file, 'Data/Map098.rxdata');
    expect(() => locator.toJson()['mapId'] = 99, throwsUnsupportedError);
  });

  for (final invalid in <Map<String, Object?>>[
    {...source, 'unexpected': true},
    {...source, 'file': '/private/tmp/Map098.rxdata'},
    {...source, 'file': '../Map098.rxdata'},
    {...source, 'file': 'Data/../Map098.rxdata'},
    {...source, 'mapId': -1},
    {...source, 'mapId': 2147483648},
    {...source, 'pageIndex': 0.5},
    {...source, 'commandIndex': '2'},
    {...source, 'line': 0},
  ]) {
    test('a recipe locator rejects $invalid', () {
      expect(
          () => SourceLocator.fromJson(invalid), throwsA(isA<ContractError>()));
    });
  }
}
