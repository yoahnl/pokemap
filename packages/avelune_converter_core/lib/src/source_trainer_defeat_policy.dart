part of '../avelune_converter_core.dart';

final class SourceTrainerDefeatPolicy {
  const SourceTrainerDefeatPolicy._(this.scriptsArchiveHash);

  final Sha256Hash scriptsArchiveHash;
  bool get canLose => false;

  Map<String, Object?> toJson() => {
        'kind': 'attestedTrainerDefeatPolicy',
        'scriptsArchiveHash': scriptsArchiveHash.value,
        'sourceCanLose': false,
        'nativeDefeatRecovery': 'returnToRecoveryPoint',
        'sourcePageRuleOverrides': 'noneInCompleteRecognizedProgram',
        'sourceBattleRulesLifetime': 'clearedWhenBattleStarts',
        'unknownRuleSetup': 'preserveAndQuarantine',
        'oracleSections': const [
          {
            'index': 147,
            'name': 'Battle',
            'sha256':
                'd61fd2ce22cc27e9d9682c14ced068dca544f39921af9b1acaa18c9022325c5b',
            'lines': [131, 134]
          },
          {
            'index': 256,
            'name': 'Overworld_BattleStarting',
            'sha256':
                '7a0e305aad2f7939254b9e322bb86ee592e2da338b114cdec2a74e4cb1ff4b04',
            'lines': [492, 527]
          },
        ],
        'sourceScriptsExecuted': 0,
      };
}

SourceTrainerDefeatPolicy? _sourceTrainerDefeatPolicy(
    SourceEventAnalyzer analyzer) {
  const expected =
      '3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d';
  if (!analyzer._isQualified ||
      !analyzer.project.canPlan ||
      !analyzer.project.archive.isSealed ||
      analyzer.profile.scriptsArchiveHash?.value != expected ||
      _eventScriptsHash(analyzer.project)?.value != expected) {
    return null;
  }
  final verified = analyzer.project.interpretationProfile;
  if (verified == null ||
      verified.scriptsArchiveHash.value != expected ||
      canonicalJsonOf(verified.toJson()) !=
          canonicalJsonOf(analyzer.profile.interpretationProfile?.toJson())) {
    return null;
  }
  final files = analyzer.project.snapshot.entries
      .where((file) =>
          sourcePathCollisionKey(file.relativePath) == 'data/scripts.rxdata')
      .toList(growable: false);
  if (files.length != 1 ||
      files.single.kind != SourceNodeKind.file ||
      files.single.sha256?.value != expected) {
    return null;
  }
  return SourceTrainerDefeatPolicy._(files.single.sha256!);
}
