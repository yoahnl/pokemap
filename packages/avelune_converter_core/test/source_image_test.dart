import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

Map<String, Object?> imageJson() => {
      'fileId': 'original-atlas',
      'contentHash': 'a' * 64,
      'pixelWidth': 256,
      'pixelHeight': 32,
    };

void main() {
  test('standalone SourceImage uses the existing strict bounded record', () {
    final json = imageJson();
    final source = SourceImage.fromJson(json);
    expect(source.fileId, ConverterId('original-atlas'));
    expect(source.contentHash, Sha256Hash('a' * 64));
    expect(source.pixelWidth, 256);
    expect(source.pixelHeight, 32);
    expect(source.toJson(), json);
    expect(SourceImage.fromJson({...json, 'pixelWidth': 2147483647}).pixelWidth,
        2147483647);
  });

  test('SourceImage refuses missing unknown malformed and out of bound fields',
      () {
    final valid = imageJson();
    final invalid = <Object?>[
      null,
      [],
      {...valid}..remove('fileId'),
      {...valid}..remove('contentHash'),
      {...valid}..remove('pixelWidth'),
      {...valid}..remove('pixelHeight'),
      {...valid, 'secret': 'unknown'},
      {...valid, 'fileId': '../outside'},
      {...valid, 'fileId': ''},
      {...valid, 'contentHash': 'g' * 64},
      {...valid, 'contentHash': 'a' * 63},
      {...valid, 'pixelWidth': 0},
      {...valid, 'pixelHeight': -1},
      {...valid, 'pixelWidth': 2147483648},
      {...valid, 'pixelHeight': 2147483648},
      {...valid, 'pixelWidth': 1.5},
      {...valid, 'pixelHeight': '32'},
      {...valid, 'contentHash': Object()},
    ];
    for (final json in invalid) {
      expect(() => SourceImage.fromJson(json), throwsA(isA<ContractError>()));
    }
  });

  test('SourceImage freezes its input and output record', () {
    final json = imageJson();
    final source = SourceImage.fromJson(json);
    json['pixelWidth'] = 512;
    expect(source.pixelWidth, 256);
    expect(() => source.toJson()['pixelHeight'] = 64, throwsUnsupportedError);
    expect(() => source.toJson().clear(), throwsUnsupportedError);
  });

  test('SourceImage obeys caller JSON budgets before retaining data', () {
    for (final limits in [
      const ContractLimits(maxNodes: 1),
      const ContractLimits(maxTextCodeUnits: 4),
      const ContractLimits(maxStringCodeUnits: 4),
    ]) {
      expect(() => SourceImage.fromJson(imageJson(), limits: limits),
          throwsA(isA<ContractError>()));
    }
    final cyclic = imageJson();
    cyclic['cycle'] = cyclic;
    expect(() => SourceImage.fromJson(cyclic), throwsA(isA<ContractError>()));
  });
}
