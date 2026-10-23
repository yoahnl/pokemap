part of '../avelune_converter_core.dart';

final class SourceTrainerDefeatPolicy {
  const SourceTrainerDefeatPolicy._(
      this.scriptsArchiveHash, this._oracleSections);

  final Sha256Hash scriptsArchiveHash;
  final List<Map<String, Object?>> _oracleSections;
  bool get canLose => false;

  Map<String, Object?> toJson() => {
        'kind': 'attestedTrainerDefeatPolicy',
        'scriptsArchiveHash': scriptsArchiveHash.value,
        'sourceCanLose': false,
        'nativeDefeatRecovery': 'returnToRecoveryPoint',
        'sourcePageRuleOverrides': 'noneInCompleteRecognizedProgram',
        'sourceBattleRulesLifetime': 'clearedWhenBattleStarts',
        'unknownRuleSetup': 'preserveAndQuarantine',
        'oracleSections': _oracleSections,
        'sourceScriptsExecuted': 0,
      };
}

SourceTrainerDefeatPolicy? _sourceTrainerDefeatPolicy(
        SourceEventAnalyzer analyzer) =>
    analyzer._trainerDefeatPolicy;

SourceTrainerDefeatPolicy? _computeSourceTrainerDefeatPolicy(
    SourceEventAnalyzer analyzer) {
  final expected = analyzer.profile.scriptsArchiveHash;
  if (!analyzer._isQualified ||
      !analyzer.project.canPlan ||
      !analyzer.project.archive.isSealed ||
      expected == null ||
      _eventScriptsHash(analyzer.project) != expected) {
    return null;
  }
  final verified = analyzer.project.interpretationProfile;
  if (verified == null ||
      verified.scriptsArchiveHash != expected ||
      canonicalJsonOf(verified.toJson()) !=
          canonicalJsonOf(analyzer.profile.interpretationProfile?.toJson())) {
    return null;
  }
  const helpers = {
    'events.Battle':
        'd61fd2ce22cc27e9d9682c14ced068dca544f39921af9b1acaa18c9022325c5b',
    'events.Overworld_BattleStarting':
        '7a0e305aad2f7939254b9e322bb86ee592e2da338b114cdec2a74e4cb1ff4b04',
  };
  final sections = <Map<String, Object?>>[];
  for (final helper in helpers.entries) {
    final section = verified.sections[helper.key];
    if (section == null || section['sha256'] != helper.value) return null;
    sections.add(section);
  }
  final files = analyzer.project.snapshot.entries
      .where((file) =>
          sourcePathCollisionKey(file.relativePath) == 'data/scripts.rxdata')
      .toList(growable: false);
  if (files.length != 1 ||
      files.single.kind != SourceNodeKind.file ||
      files.single.sha256 != expected) {
    return null;
  }
  return SourceTrainerDefeatPolicy._(
      files.single.sha256!, List.unmodifiable(sections));
}
