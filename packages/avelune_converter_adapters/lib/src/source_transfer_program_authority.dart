import 'package:avelune_converter_core/avelune_converter_core.dart';

import 'native_project_writer.dart';

final class SourceTransferProgramAuthority {
  SourceTransferProgramAuthority.forSource(NormalizedSourceProject source)
      : _source = source,
        _snapshotHash = source.snapshot.canonicalHash,
        _normalizationHash = source.canonicalHash,
        _profile = SourceEventProfile.forProject(source);

  final NormalizedSourceProject _source;
  final Sha256Hash _snapshotHash, _normalizationHash;
  final SourceEventProfile _profile;

  late final SourceEventAnalysis _analysis =
      SourceEventAnalyzer.forProject(_source, profile: _profile).analyze();
  late final SourceParallelDormancyAuditor _parallelDormancyAuditor =
      SourceParallelDormancyAuditor.forProject(_source, profile: _profile);
  int _executionContextAcquisitionCount = 0;

  int get executionContextAcquisitionCount => _executionContextAcquisitionCount;

  ({
    SourceEventAnalysis analysis,
    SourceParallelDormancyAuditor parallelDormancyAuditor
  }) executionContextFor(NormalizedSourceProject source) {
    _validateSource(source);
    final context = (
      analysis: _analysis,
      parallelDormancyAuditor: _parallelDormancyAuditor
    );
    _executionContextAcquisitionCount++;
    return context;
  }

  SourceEventAnalysis get analysis {
    _validateSource(_source);
    return _analysis;
  }

  SourceEventAnalysis analysisFor({
    required NormalizedSourceProject source,
    required SourceEventAnalysis analysis,
  }) {
    _validateSource(source);
    if (analysis.profile.sourceSnapshotHash != _snapshotHash ||
        analysis.profile.normalizationHash != _normalizationHash ||
        analysis.profile.canonicalHash != _profile.canonicalHash) {
      throw const NativeWriteException('events.transfer.authority_binding',
          'Transfer qualification requires its exact source interpretation context.');
    }
    return this.analysis;
  }

  void _validateSource(NormalizedSourceProject source) {
    if (!identical(source, _source) ||
        !source.archive.isSealed ||
        source.snapshot.canonicalHash != _snapshotHash ||
        source.canonicalHash != _normalizationHash ||
        SourceEventProfile.forProject(source).canonicalHash !=
            _profile.canonicalHash) {
      throw const NativeWriteException('events.transfer.authority_binding',
          'Transfer qualification requires its owned sealed source context.');
    }
  }
}
