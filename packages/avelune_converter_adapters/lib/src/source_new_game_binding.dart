import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';
import 'source_event_projection.dart';
import 'source_fresh_entry_binding.dart';
import 'source_player_character_import.dart';
import 'source_system_entry_binding.dart';

abstract interface class SourceNewGameBinding {
  ProjectNewGameConfig get config;
  ProjectDefeatRecoveryConfig? get defeatRecovery;
  List<SceneAsset> get scenes;
  List<NativeArtifact> get artifacts;
  List<NativeMutation> get importMutations;
  List<NativeMutation> get mutations;
  List<NarrativeFactDefinition> get facts;
  Map<int, MapData> get nativeMaps;
  List<SourcePlayerCharacterImport> get imports;
  Map<String, Object?> get evidence;
}

final class SourceNewGameBindingResolver {
  const SourceNewGameBindingResolver();

  Future<SourceNewGameBinding?> read({
    required NormalizedSourceProject source,
    required SourceEventProjection projection,
    required SourceFilePort files,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    if (sourceFreshEntryProgram(source) != null) {
      return const SourceFreshEntryBindingResolver().read(
          source: source,
          projection: projection,
          files: files,
          limits: limits,
          cancellation: cancellation);
    }
    return const SourceSystemEntryBindingResolver().read(
        source: source,
        projection: projection,
        files: files,
        limits: limits,
        cancellation: cancellation);
  }
}
