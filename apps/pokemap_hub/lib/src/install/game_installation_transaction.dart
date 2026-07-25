import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';

enum GameInstallationTransactionState {
  snapshotReady,
  extracted,
  readyToPromote,
  repairBackupMoved,
  versionPromoted,
  receiptPromoted,
  currentUpdated,
  libraryUpdated,
}

final class GameInstallationTransaction {
  const GameInstallationTransaction({
    required this.id,
    required this.state,
    required this.mode,
    required this.activate,
    required this.gameId,
    required this.gameVersion,
    required this.treeSha256,
    required this.receiptFileName,
    required this.source,
    required this.createdAt,
  });

  final String id;
  final GameInstallationTransactionState state;
  final GamePackageActivationMode mode;
  final bool activate;
  final String gameId;
  final String gameVersion;
  final String treeSha256;
  final String receiptFileName;
  final GamePackageInstallSource source;
  final DateTime createdAt;

  GameInstallationTransaction withState(
    GameInstallationTransactionState state,
  ) =>
      GameInstallationTransaction(
        id: id,
        state: state,
        mode: mode,
        activate: activate,
        gameId: gameId,
        gameVersion: gameVersion,
        treeSha256: treeSha256,
        receiptFileName: receiptFileName,
        source: source,
        createdAt: createdAt,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': 1,
        'id': id,
        'state': state.name,
        'mode': mode.name,
        'activate': activate,
        'gameId': gameId,
        'gameVersion': gameVersion,
        'treeSha256': treeSha256,
        'receiptFileName': receiptFileName,
        'source': source.name,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };
}

abstract final class GameInstallationTransactionCodec {
  static List<int> encode(GameInstallationTransaction transaction) =>
      CanonicalJson.encodeUtf8(transaction.toJson());

  static GameInstallationTransaction decode(List<int> bytes) {
    final source = utf8.decode(bytes, allowMalformed: false);
    final value = jsonDecode(source);
    if (value is! Map ||
        value.length != 11 ||
        value['schemaVersion'] != 1 ||
        value['id'] is! String ||
        value['state'] is! String ||
        value['mode'] is! String ||
        value['activate'] is! bool ||
        value['gameId'] is! String ||
        value['gameVersion'] is! String ||
        value['treeSha256'] is! String ||
        value['receiptFileName'] is! String ||
        value['source'] is! String ||
        value['createdAt'] is! String) {
      throw const FormatException('Invalid install transaction journal.');
    }
    final stateName = value['state']! as String;
    final state = GameInstallationTransactionState.values
        .where((candidate) => candidate.name == stateName)
        .firstOrNull;
    final modeName = value['mode']! as String;
    final mode = GamePackageActivationMode.values
        .where((candidate) => candidate.name == modeName)
        .firstOrNull;
    final sourceName = value['source']! as String;
    final installSource = GamePackageInstallSource.values
        .where((candidate) => candidate.name == sourceName)
        .firstOrNull;
    final createdAtSource = value['createdAt']! as String;
    final createdAt = DateTime.parse(createdAtSource);
    final id = value['id']! as String;
    final gameId = value['gameId']! as String;
    final gameVersion = value['gameVersion']! as String;
    final treeSha256 = value['treeSha256']! as String;
    final receiptFileName = value['receiptFileName']! as String;
    if (state == null ||
        mode == null ||
        installSource == null ||
        !_transactionId.hasMatch(id) ||
        !_sha256.hasMatch(treeSha256) ||
        receiptFileName != '$gameVersion-$treeSha256.json' ||
        !createdAtSource.endsWith('Z') ||
        !createdAt.isUtc ||
        createdAt.toIso8601String() != createdAtSource) {
      throw const FormatException('Invalid install transaction values.');
    }
    GameIdentity.validateGameId(gameId);
    GameIdentity.validateSemver(
      gameVersion,
      path: r'$.gameVersion',
    );
    final transaction = GameInstallationTransaction(
      id: id,
      state: state,
      mode: mode,
      activate: value['activate']! as bool,
      gameId: gameId,
      gameVersion: gameVersion,
      treeSha256: treeSha256,
      receiptFileName: receiptFileName,
      source: installSource,
      createdAt: createdAt,
    );
    if (source != utf8.decode(encode(transaction))) {
      throw const FormatException('Non-canonical install transaction.');
    }
    return transaction;
  }

  static final RegExp _transactionId = RegExp(r'^[a-z0-9-]{1,64}$');
  static final RegExp _sha256 = RegExp(r'^[0-9a-f]{64}$');
}
