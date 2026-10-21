import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';

final class NativeTrainerMoneyWitness {
  NativeTrainerMoneyWitness._(
      this.entry, this.document, this.sourceSnapshotHash, this.sourceNamespace);

  static Future<NativeTrainerMoneyWitness> read({
    required SourceSnapshot snapshot,
    required SourceFilePort files,
    ScanCancellation? cancellation,
  }) async {
    const relativePath = 'Data/trainer_types.dat';
    final entries = snapshot.entries
        .where((entry) => entry.relativePath == relativePath)
        .toList();
    if (snapshot.state != SourceScanState.complete ||
        entries.length != 1 ||
        entries.single.kind != SourceNodeKind.file ||
        entries.single.sha256 == null ||
        entries.single.byteLength < 1 ||
        entries.single.byteLength > 2097152) {
      throw ContractError('native_trainer.money_witness', relativePath,
          'Prize money requires one bounded compiled trainer type witness.');
    }
    cancellation?.check();
    final entry = entries.single;
    final bytes = await files.read(entry.fileId);
    cancellation?.check();
    if (bytes.length != entry.byteLength ||
        bytes.any((byte) => byte < 0 || byte > 255) ||
        crypto.sha256.convert(bytes).toString() != entry.sha256!.value) {
      throw ContractError('native_trainer.money_source_changed', relativePath,
          'Compiled trainer types differ from the sealed source.');
    }
    final MarshalDocument document;
    try {
      document = const MarshalDecoder().decode(bytes,
          sourcePath: relativePath,
          limits: const MarshalDecodeLimits(
            maxInputBytes: 2097152,
            maxDepth: 32,
            maxNodes: 200000,
            maxObjects: 100000,
            maxSymbols: 20000,
            maxContainerEntries: 10000,
            maxTotalEntries: 200000,
            maxStringBytes: 65536,
            maxTotalStringBytes: 2097152,
            maxTotalLocationCodeUnits: 8388608,
          ));
    } on BinaryDecodeError catch (error) {
      throw ContractError('native_trainer.money_witness', relativePath,
          'Compiled trainer type decoding failed: ${error.code}.');
    }
    if (document.node(document.rootId).kind != MarshalKind.hash) {
      throw ContractError('native_trainer.money_witness', relativePath,
          'Compiled trainer types require a symbol-keyed hash.');
    }
    return NativeTrainerMoneyWitness._(entry, document, snapshot.canonicalHash,
        snapshot.logicalProjectNamespace);
  }

  final SourceFileEntry entry;
  final MarshalDocument document;
  final Sha256Hash sourceSnapshotHash;
  final ConverterId sourceNamespace;

  Map<String, Object?> attest(String symbol, int expectedBase) {
    final pairs = document.node(document.rootId).pairs.where((pair) {
      final key = document.node(pair.key);
      return key.kind == MarshalKind.symbol && key.name == symbol;
    }).toList();
    if (pairs.length == 1) {
      final type = document.node(pairs.single.value);
      final fields = <String, List<MarshalNode>>{};
      for (final pair in type.instanceVariables) {
        final key = document.node(pair.key);
        if (key.kind != MarshalKind.symbol || key.name == null) continue;
        (fields[key.name!] ??= []).add(document.node(pair.value));
      }
      final id = fields['@id'];
      final money = fields['@base_money'];
      if (type.kind == MarshalKind.object &&
          type.className == 'GameData::TrainerType' &&
          id?.length == 1 &&
          id!.single.kind == MarshalKind.symbol &&
          id.single.name == symbol &&
          money?.length == 1 &&
          money!.single.kind == MarshalKind.integer &&
          money.single.integerValue == BigInt.from(expectedBase)) {
        return {
          'file': entry.toJson(),
          'graphPath': type.location.graphPath,
          'byteOffset': type.location.byteOffset,
          'sourceTypeSymbol': symbol,
          'baseMoney': expectedBase,
        };
      }
    }
    throw ContractError('native_trainer.money_compiled_mismatch', symbol,
        'PBS and compiled trainer types must agree on exact prize money.');
  }
}

final class NativeTrainerMoneyBinding {
  NativeTrainerMoneyBinding._(this.amount, this.evidence);

  factory NativeTrainerMoneyBinding.fromPbs({
    required SourcePbsProject source,
    required SourcePbsEntry roster,
    required List<ProjectTrainerPokemonEntry> team,
    NativeTrainerMoneyWitness? compiledWitness,
  }) {
    if (compiledWitness != null &&
        (compiledWitness.sourceSnapshotHash != source.sourceSnapshotHash ||
            compiledWitness.sourceNamespace !=
                source.logicalProjectNamespace)) {
      throw ContractError('native_trainer.money_witness_context', r'$',
          'Compiled prize money belongs to a different source snapshot.');
    }
    final identity = roster.identity;
    if (identity == null ||
        identity.family != SourcePbsFamily.trainers ||
        identity.namespace != source.logicalProjectNamespace ||
        source.lookup(identity) != roster ||
        team.isEmpty ||
        team.length > 6 ||
        team.length != roster.party.length) {
      throw ContractError('native_trainer.money_roster', r'$',
          'Prize money requires the exact source roster and native team.');
    }
    for (var i = 0; i < team.length; i++) {
      final values = roster.party[i].headerField.values;
      if (values.length != 2 ||
          int.tryParse(values.last) != team[i].level ||
          team[i].level < 1 ||
          team[i].level > 100) {
        throw ContractError('native_trainer.money_roster', identity.key,
            'Prize money must use the exact authored team levels.');
      }
    }
    final typeIdentity = SourcePbsIdentity(
      namespace: source.logicalProjectNamespace,
      family: SourcePbsFamily.trainerTypes,
      sourceSymbol: identity.trainerType,
    );
    final type = source.lookup(typeIdentity);
    if (type == null) {
      throw ContractError('native_trainer.money_type', identity.key,
          'A unique valid source trainer type is required for prize money.');
    }
    final fields = type.fieldsNamed('BaseMoney');
    final base = fields.isEmpty
        ? 30
        : fields.length == 1 && fields.single.values.length == 1
            ? int.tryParse(fields.single.values.single)
            : null;
    final highestLevel = team
        .map((member) => member.level)
        .reduce((left, right) => left > right ? left : right);
    if (base == null || base < 0 || base > 9007199254740991 ~/ highestLevel) {
      throw ContractError('native_trainer.money_value', identity.key,
          'Prize money must remain a nonnegative exactly representable integer.');
    }
    return NativeTrainerMoneyBinding._(base * highestLevel, {
      'kind': 'sourceTrainerPrizeToNativeFixedReward',
      'sourceSnapshotHash': source.sourceSnapshotHash.value,
      'sourcePbsHash': source.canonicalHash.value,
      'trainerTypeIdentity': typeIdentity.toJson(),
      'trainerTypeLocator': type.headerLocator.toJson(),
      'trainerTypeHash': canonicalHashOf(type.toJson()).value,
      'baseMoney': base,
      'sourceBaseMoneyDefaultUsed': fields.isEmpty,
      'highestTeamLevel': highestLevel,
      'nativeMoneyReward': base * highestLevel,
      'compiledTrainerTypeAttested': compiledWitness != null,
      if (compiledWitness != null)
        'compiledTrainerType':
            compiledWitness.attest(identity.trainerType!, base),
      'policy': 'baseMoneyTimesHighestAuthoredTeamLevel',
      'sourceOracle': {
        'archiveSha256':
            '3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d',
        'payout': {
          'section': 148,
          'name': 'Battle_StartAndEnd',
          'lines': [352, 359]
        },
        'default': {'section': 135, 'name': 'TrainerType', 'line': 105},
      },
      'sourceBattleModifiersImported': false,
      'nativeBattleRulesModified': false,
      'sourceScriptsExecuted': 0,
    });
  }

  final int amount;
  final Map<String, Object?> evidence;
}
