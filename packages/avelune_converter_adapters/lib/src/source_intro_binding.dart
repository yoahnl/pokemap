import 'package:avelune_converter_core/avelune_converter_core.dart';

final class SourceIntroBindingResolver {
  const SourceIntroBindingResolver();

  Future<Map<int, SourceIntroProgram>> readTextVariables({
    required NormalizedSourceProject source,
    required SourceFilePort files,
    required Set<int> referencedVariableIds,
    ScanCancellation? cancellation,
  }) async {
    if (!SourceEventProfile.forProject(source).isQualified) return const {};
    final candidates = <int>{
      ...source.selectedSourceMapIds,
      for (final info in source.mapHierarchy)
        if (info.name == 'Intro') info.sourceMapId,
    };
    final missing = referencedVariableIds.isEmpty
        ? <int>{}
        : candidates.difference(source.selectedSourceMapIds.toSet());
    final extra = missing.isEmpty
        ? null
        : await const RmxpSourceNormalizer().normalize(
            snapshot: source.snapshot,
            files: files,
            selectedMapIds: missing,
            includeEventSystem: true,
            interpretationProfile: source.interpretationProfile,
            cancellation: cancellation,
          );
    final result = <int, SourceIntroProgram>{};
    for (final context in [source, if (extra != null) extra]) {
      for (final map in context.maps
          .where((map) => candidates.contains(map.map.sourceMapId))) {
        for (final event
            in map.map.events.where((event) => event.pages.length == 3)) {
          cancellation?.check();
          final program = sourceIntroProgram(context,
              sourceMapId: map.map.sourceMapId,
              sourceEventId: event.sourceEventId);
          if (program == null ||
              !referencedVariableIds.contains(program.nameVariableId)) {
            continue;
          }
          final previous = result[program.nameVariableId];
          if (previous != null && previous.programHash != program.programHash) {
            throw ContractError('events.text_variable.ambiguous', r'$',
                'A source text variable requires one attested introduction.');
          }
          result[program.nameVariableId] = program;
        }
      }
    }
    return Map.unmodifiable(result);
  }
}
