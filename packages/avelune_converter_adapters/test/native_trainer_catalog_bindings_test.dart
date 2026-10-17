import 'dart:convert';

import 'package:avelune_converter_adapters/src/native_psdk_trainer_bundle.dart';
import 'package:avelune_converter_adapters/src/native_trainer_catalog_bindings.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _teams = '''
[FRLG_BUGCATCHER,Brent]
Pokemon = BEEDRILL,19
Pokemon = BEEDRILL,19
[FRLG_BUGCATCHER,Conner]
Pokemon = CATERPIE,20
Pokemon = WEEDLE,20
Pokemon = VENONAT,20
[FRLG_HIKER,Jeremy]
Pokemon = MACHOP,20
Pokemon = ONIX,20
[FRLG_HIKER,Alan]
Pokemon = GEODUDE,21
Pokemon = ONIX,21
[FRLG_HIKER,Brice]
Pokemon = GEODUDE,20
Pokemon = MACHOP,20
Pokemon = GEODUDE,20
[FRLG_PICNICKER,Alicia]
Pokemon = ODDISH,18
Pokemon = BELLSPROUT,18
Pokemon = ODDISH,18
Pokemon = BELLSPROUT,18
[FRLG_PICNICKER,Caitlin]
Pokemon = MEOWTH,23
[FRLG_CAMPER,Chris]
Pokemon = GROWLITHE,21
Pokemon = CHARMANDER,21
[FRLG_CAMPER,Drew]
Pokemon = RATTATA,19
Pokemon = SANDSHREW,19
Pokemon = EKANS,19
Pokemon = SANDSHREW,19
[FRLG_PICNICKER,Heidi]
Pokemon = PIKACHU,20
Pokemon = CLEFAIRY,20
[FRLG_POKEMANIAC,Mark]
Pokemon = RHYHORN,29
Pokemon = LICKITUNG,29
''';

final class _Files implements SourceFilePort {
  const _Files(this.bytes);
  final List<int> bytes;
  @override
  Future<List<int>> read(ConverterId id) async => bytes;
}

Future<SourcePbsProject> _source([String text = _teams]) async {
  final bytes = utf8.encode(text);
  final snapshot = SourceSnapshot(
      logicalProjectNamespace: ConverterId('native-trainer-test'),
      policyHash: SourceScanPolicy().canonicalHash,
      entries: [
        SourceFileEntry(
            fileId: ConverterId('source-trainers'),
            relativePath: 'PBS/trainers.txt',
            kind: SourceNodeKind.file,
            byteLength: bytes.length,
            sha256: Sha256Hash(crypto.sha256.convert(bytes).toString()),
            format: 'pbs',
            family: 'pbs')
      ],
      diagnostics: [],
      excludedPaths: [],
      profileEvidence: [],
      state: SourceScanState.complete);
  return const SourcePbsParser().read(
      snapshot: snapshot,
      files: _Files(bytes),
      families: const {SourcePbsFamily.trainers});
}

Matcher _code(String code) =>
    throwsA(isA<ContractError>().having((error) => error.code, 'code', code));

void main() {
  test('ships the bounded native reference without a local PSDK checkout', () {
    final native = NativePsdkTrainerBundle.builtin();
    expect(native.speciesById, hasLength(68));
    expect(native.movesById, hasLength(396));
    expect(native.catalogs['types']!.entries, hasLength(18));
    expect(native.catalogs['natures']!.entries, hasLength(25));
    expect(
        native.catalogs['types']!.entries
            .every((type) => type['damageTo'] is List),
        isTrue);
    expect(native.speciesById['beedrill']!.typing.types, ['bug', 'poison']);
    expect(native.speciesById['beedrill']!.abilities.primary, 'swarm');
    expect(native.speciesById['beedrill']!.breeding.genderRatio,
        {'male': 50, 'female': 50});
    expect(native.speciesById['beedrill_form30']!.breeding.genderRatio,
        {'male': 50, 'female': 50});
    expect(native.speciesById['machop']!.baseStats.atk, 80);
    expect(native.movesById['seismic_toss']!.unsupportedReasons,
        contains('psdk_method:s_hp_eq_level'));
    expect(
        native.movesById.values.where((move) =>
            move.engineSupportLevel ==
            PokemonMoveEngineSupportLevel.catalogOnly),
        hasLength(335));
    expect(native.evidence['nativeQualifiedFieldMoveIds'], ['cut']);
    expect(native.movesById['cut']!.engineSupportLevel,
        PokemonMoveEngineSupportLevel.structuredPartial);
    expect(native.evidence['nativeBattleDefaultMoveIds'] as List,
        isNot(contains('cut')));
    expect(native.evidence['globalCatalogComplete'], isFalse);
    expect(native.evidence['globalLearnsetsPublished'], isTrue);
    expect(native.evidence['sourceScriptsExecuted'], 0);
  });

  test('binds eleven exact trainer rosters to native explicit battle defaults',
      () async {
    final source = await _source();
    final native = NativePsdkTrainerBundle.builtin();
    final result = const NativeTrainerCatalogBindings().bind(
        source: source,
        requestedTrainers: source.entries.map((entry) => entry.identity!),
        native: native,
        movePolicy: NativeTrainerMovePolicy.nativeAveluneDefaults);
    expect(result.trainers, hasLength(11));
    final team = result.trainers.expand((trainer) => trainer.team).toList();
    expect(team, hasLength(27));
    expect(team.map((member) => member.speciesId).toSet(), hasLength(19));
    expect(team.expand((member) => member.moves).toSet(), hasLength(60));
    for (final member in team) {
      final species = native.speciesById[member.speciesId]!;
      expect(member.abilityId, species.abilities.primary);
      expect(member.moves, isNotEmpty);
      expect(member.moves.length, lessThanOrEqualTo(4));
      expect(member.moves.every(native.movesById.containsKey), isTrue);
    }
    expect(result.trainers.first.team.first.moves,
        ['fury_attack', 'twineedle', 'rage', 'pursuit']);
    expect(result.trainers.last.team.last.moves,
        ['wrap', 'stomp', 'disable', 'slam']);
    expect(result.evidence['movePolicy'], 'nativeAveluneDefaults');
    expect(result.evidence['sourceDefaultMovePolicyUsed'], isFalse);
    expect(result.evidence['runtimeBattleBuilderQualified'], isFalse);
    expect(() => result.trainers.clear(), throwsUnsupportedError);
  });

  test(
      'accepts unrelated roster text changes but refuses changed qualified team members',
      () async {
    final native = NativePsdkTrainerBundle.builtin();
    final comment = await _source('$_teams\n# Unrelated source comment\n');
    final keys = comment.entries.map((entry) => entry.identity!);
    final result = const NativeTrainerCatalogBindings().bind(
        source: comment,
        requestedTrainers: keys,
        native: native,
        movePolicy: NativeTrainerMovePolicy.nativeAveluneDefaults);
    expect(result.trainers, hasLength(11));
    expect(result.evidence['referenceRosterHashMatched'], isFalse);
    final changed =
        await _source(_teams.replaceFirst('BEEDRILL,19', 'BEEDRILL,20'));
    expect(
        () => const NativeTrainerCatalogBindings().bind(
            source: changed,
            requestedTrainers: changed.entries.map((entry) => entry.identity!),
            native: native,
            movePolicy: NativeTrainerMovePolicy.nativeAveluneDefaults),
        _code('native_trainer.roster_changed'));
  });

  test('refuses an unresolved move decision before binding any trainer',
      () async {
    final source = await _source();
    expect(
        () => const NativeTrainerCatalogBindings().bind(
            source: source,
            requestedTrainers: source.entries.map((entry) => entry.identity!),
            native: NativePsdkTrainerBundle.builtin(),
            movePolicy: NativeTrainerMovePolicy.unresolved),
        _code('native_trainer.move_policy_required'));
  });

  test('rejects malformed source member arity with typed errors', () async {
    for (final (heading, code) in [
      ('Pokemon = BEEDRILL,19,UNEXPECTED', 'native_trainer.member_invalid'),
      ('Pokemon = BEEDRILL', 'native_trainer.source_missing'),
      ('Pokemon =', 'native_trainer.source_missing'),
    ]) {
      final source = await _source(
          '[FRLG_BUGCATCHER,Brent]\n$heading\nPokemon = BEEDRILL,19\n');
      expect(
          () => const NativeTrainerCatalogBindings().bind(
              source: source,
              requestedTrainers: source.entries.map((entry) => entry.identity!),
              native: NativePsdkTrainerBundle.builtin(),
              movePolicy: NativeTrainerMovePolicy.nativeAveluneDefaults),
          _code(code));
    }
  });

  test('refuses missing species and unsupported authored party overrides',
      () async {
    for (final testCase in [
      (
        '[TEST,Unknown]\nPokemon = MISSINGNO,20\n',
        'native_trainer.member_invalid'
      ),
      (
        '[TEST,Unknown]\nPokemon = BEEDRILL,19\nAbility = SNIPER\n',
        'native_trainer.party_override'
      ),
    ]) {
      final source = await _source(testCase.$1);
      expect(
          () => const NativeTrainerCatalogBindings().bind(
              source: source,
              requestedTrainers: source.entries.map((entry) => entry.identity!),
              native: NativePsdkTrainerBundle.builtin(),
              movePolicy: NativeTrainerMovePolicy.nativeAveluneDefaults),
          _code(testCase.$2));
    }
  });

  test('does not promote a forged catalog-only native move', () async {
    final json =
        jsonDecode(jsonEncode(NativePsdkTrainerBundle.builtin().toJson()))
            as Map<String, dynamic>;
    final moves = (json['catalogs'] as List)
        .cast<Map>()
        .singleWhere((catalog) => catalog['catalog'] == 'moves');
    ((moves['entries'] as List).cast<Map>().singleWhere(
            (move) => move['id'] == 'fury_attack'))['engineSupportLevel'] =
        'catalog_only';
    final forged = NativePsdkTrainerBundle.fromJson(json);
    final source = await _source();
    expect(
        () => const NativeTrainerCatalogBindings().bind(
            source: source,
            requestedTrainers: source.entries.map((entry) => entry.identity!),
            native: forged,
            movePolicy: NativeTrainerMovePolicy.nativeAveluneDefaults),
        _code('native_trainer.move_closure'));
  });

  test('checks source hashes and quotas before accepting a native JSON witness',
      () {
    expect(
        () => NativePsdkTrainerSourceFile(
            relativePath: 'Data/Studio/pokemon/beedrill.json',
            sha256: Sha256Hash('0' * 64),
            bytes: utf8.encode('{}')),
        _code('native_trainer.source_witness'));
    expect(
        () => NativePsdkTrainerSourceFile(
            relativePath: '../../pokemon/beedrill.json',
            sha256:
                Sha256Hash(crypto.sha256.convert(utf8.encode('{}')).toString()),
            bytes: utf8.encode('{}')),
        _code('native_trainer.source_witness'));
  });
}
