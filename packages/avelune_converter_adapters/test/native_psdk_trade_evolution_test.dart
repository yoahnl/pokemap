import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/src/native_psdk_trainer_bundle.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';

void main() {
  final root = Platform.environment['AVELUNE_NATIVE_PSDK_REFERENCE_ROOT'];
  test(
      'unknown reference trade constraints remain unexecutable conditional data',
      () async {
    final native = NativePsdkTrainerBundle.builtin();
    final files = <NativePsdkTrainerSourceFile>[];
    for (final row in (native.evidence['sources'] as List).cast<Map>()) {
      final relative = row['relativePath'] as String;
      var bytes = await File('$root/$relative').readAsBytes();
      expect(crypto.sha256.convert(bytes).toString(), row['sha256']);
      if (relative == 'Data/Studio/pokemon/machoke.json') {
        final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        final form = (json['forms'] as List).first as Map;
        final rule = (form['evolutions'] as List).single as Map;
        (rule['conditions'] as List)
            .add({'type': 'futureCondition', 'value': true});
        bytes = utf8.encode(jsonEncode(json));
      }
      files.add(NativePsdkTrainerSourceFile(
          relativePath: relative,
          sha256: Sha256Hash(crypto.sha256.convert(bytes).toString()),
          bytes: bytes));
    }
    final levels = (native.evidence['requestedLevels'] as Map).map(
        (key, value) =>
            MapEntry(key as String, (value as List).cast<int>().toSet()));
    final rebuilt = const NativePsdkTrainerBundleBuilder()
        .build(files: files, requestedLevels: levels);
    final rule = rebuilt.evolutionsBySpeciesId['machoke']!.evolutions.single;
    expect(rule.method, 'conditional');
    expect(rule.tradeRequirements, isNull);
    expect(rule.conditionText.values.single, contains('futureCondition'));
  },
      skip: root == null
          ? 'Requires the optional read-only PSDK reference root.'
          : false);
  test('native reference has typed trade rules for Machoke and Graveler', () {
    final native = NativePsdkTrainerBundle.builtin();
    for (final source in ['machoke', 'graveler']) {
      final rule = native.evolutionsBySpeciesId[source]!.evolutions.single;
      expect(rule.method, 'trade');
      expect(rule.tradeRequirements, isNotNull);
      expect(rule.tradeRequirements!.requiredHeldItemId, isNull);
      expect(rule.tradeRequirements!.requiredPartnerSpeciesId, isNull);
    }
  });
  test('native Onix trade requires its actual held item catalog identity', () {
    final rule = NativePsdkTrainerBundle.builtin()
        .evolutionsBySpeciesId['onix']!
        .evolutions
        .single;
    expect(rule.method, 'trade');
    expect(rule.targetSpeciesId, 'steelix');
    expect(rule.tradeRequirements!.requiredHeldItemId, 'metal_coat');
  });
  test('trade metadata remains typed after a native bundle round trip', () {
    final bundle = NativePsdkTrainerBundle.builtin();
    final decoded = NativePsdkTrainerBundle.fromJson(bundle.toJson());
    final rule = decoded.evolutionsBySpeciesId['onix']!.evolutions.single;
    expect(
        rule.tradeRequirements!.toJson(),
        const PokemonTradeEvolutionRequirements(
                requiredHeldItemId: 'metal_coat')
            .toJson());
    expect(decoded.speciesById, hasLength(bundle.speciesById.length));
    expect(decoded.movesById.keys, orderedEquals(bundle.movesById.keys));
  });
}
