import 'dart:convert';

import 'package:avelune_converter_adapters/src/native_psdk_trainer_bundle.dart';
import 'package:avelune_converter_adapters/src/native_trainer_catalog_bindings.dart';
import 'package:avelune_converter_adapters/src/native_trainer_money_binding.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

final class _Files implements SourceFilePort {
  _Files(this.values);
  final Map<ConverterId, List<int>> values;

  @override
  Future<List<int>> read(ConverterId id) async => values[id]!;
}

Future<SourcePbsProject> _source({
  String? trainerTypes =
      '[FRLG_BUGCATCHER]\nName = Bug Catcher\nBaseMoney = 8\n',
  String roster = '[FRLG_BUGCATCHER,Conner]\nPokemon = CATERPIE,20\n'
      'Pokemon = WEEDLE,20\nPokemon = VENONAT,20\n',
}) async {
  final values = <String, String>{
    'PBS/trainers.txt': roster,
    if (trainerTypes != null) 'PBS/trainer_types.txt': trainerTypes,
  };
  final files = <ConverterId, List<int>>{};
  final entries = <SourceFileEntry>[];
  for (final entry in values.entries) {
    final id = ConverterId('file-${entries.length}');
    final bytes = utf8.encode(entry.value);
    files[id] = bytes;
    entries.add(SourceFileEntry(
      fileId: id,
      relativePath: entry.key,
      kind: SourceNodeKind.file,
      byteLength: bytes.length,
      sha256: Sha256Hash(crypto.sha256.convert(bytes).toString()),
      format: 'pbs',
      family: 'pbs',
    ));
  }
  final snapshot = SourceSnapshot(
    logicalProjectNamespace: ConverterId('trainer-money-fixture'),
    policyHash: SourceScanPolicy().canonicalHash,
    entries: entries,
    diagnostics: [],
    excludedPaths: [],
    profileEvidence: [],
    state: SourceScanState.complete,
  );
  return const SourcePbsParser().read(snapshot: snapshot, files: _Files(files));
}

void main() {
  test('trainer conversion carries source prize money into native rewards',
      () async {
    final source = await _source();
    final identity = source.entries
        .singleWhere((entry) => entry.family == SourcePbsFamily.trainers)
        .identity!;
    final result = const NativeTrainerCatalogBindings().bind(
      source: source,
      requestedTrainers: [identity],
      native: NativePsdkTrainerBundle.builtin(),
      movePolicy: NativeTrainerMovePolicy.nativeAveluneDefaults,
    );
    expect(result.trainers.single.moneyReward, 160);
    expect(result.trainers.single.team, hasLength(3));
  });

  NativeTrainerMoneyBinding bind(SourcePbsProject source, {List<int>? levels}) {
    final roster = source.entries
        .singleWhere((entry) => entry.family == SourcePbsFamily.trainers);
    return NativeTrainerMoneyBinding.fromPbs(
      source: source,
      roster: roster,
      team: [
        for (final level in levels ??
            roster.party
                .map((member) => int.parse(member.headerField.values.last)))
          ProjectTrainerPokemonEntry(speciesId: 'caterpie', level: level),
      ],
    );
  }

  test(
      'highest level determines the prize even when the final member is weaker',
      () async {
    final source = await _source(
        roster:
            '[FRLG_BUGCATCHER,Conner]\nPokemon = CATERPIE,25\nPokemon = WEEDLE,5\n');
    expect(bind(source).amount, 200);
    expect(bind(source).evidence['highestTeamLevel'], 25);
  });

  test('a present type with omitted BaseMoney uses the attested source default',
      () async {
    final reward = bind(
        await _source(trainerTypes: '[FRLG_BUGCATCHER]\nName = Bug Catcher\n'));
    expect(reward.amount, 600);
    expect(reward.evidence['sourceBaseMoneyDefaultUsed'], isTrue);
  });

  test('explicit zero remains zero rather than selecting the source default',
      () async {
    final reward = bind(await _source(
        trainerTypes:
            '[FRLG_BUGCATCHER]\nName = Bug Catcher\nBaseMoney = 0\n'));
    expect(reward.amount, 0);
    expect(reward.evidence['sourceBaseMoneyDefaultUsed'], isFalse);
  });

  for (final types in <String?>[
    null,
    '[OTHER]\nName = Other\nBaseMoney = 8\n',
    '[FRLG_BUGCATCHER]\nName = Bug Catcher\nBaseMoney = -1\n',
    '[FRLG_BUGCATCHER]\nName = Bug Catcher\nBaseMoney = invalid\n',
    '[FRLG_BUGCATCHER]\nName = Bug Catcher\nBaseMoney = 1\n'
        '[FRLG_BUGCATCHER]\nName = Duplicate\nBaseMoney = 2\n',
    '[FRLG_BUGCATCHER]\nName = Bug Catcher\n'
        'BaseMoney = 9007199254740991\n',
  ]) {
    test('unqualified trainer type cannot silently become a zero prize: $types',
        () async {
      final source = await _source(trainerTypes: types);
      expect(() => bind(source), throwsA(isA<ContractError>()));
    });
  }

  test('native team level changes cannot borrow the source prize proof',
      () async {
    final source = await _source();
    expect(() => bind(source, levels: [21, 20, 20]),
        throwsA(isA<ContractError>()));
    expect(() => bind(source, levels: []), throwsA(isA<ContractError>()));
  });
}
