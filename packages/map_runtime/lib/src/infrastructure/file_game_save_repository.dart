import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';
import 'package:path_provider/path_provider.dart';

import '../../../domain/repositories/game_save_repository.dart';
import '../application/narrative_runtime_activity_gate.dart';
import 'game_save_codec_executor.dart';

/// Implémentation fichier de [GameSaveRepository].
///
/// Stocke les sauvegardes dans le répertoire de support de l'application.
/// Chemin : `<ApplicationSupportDirectory>/pokemonProject/game_save.json`
class FileGameSaveRepository implements GameSaveRepository {
  FileGameSaveRepository({
    NarrativeRuntimeActivityGate? activityGate,
    GameSaveCodecExecutor? codecExecutor,
  })  : _activityGate = activityGate ?? NarrativeRuntimeActivityGate(),
        _codecExecutor = codecExecutor ?? GameSaveCodecExecutor();

  static const String _saveFileName = 'game_save.json';
  static const String _subDirectory = 'pokemonProject';
  final NarrativeRuntimeActivityGate _activityGate;
  final GameSaveCodecExecutor _codecExecutor;

  /// Retourne le chemin complet du fichier de sauvegarde.
  @protected
  Future<String> getSaveFilePath() async {
    final directory = await getApplicationSupportDirectory();
    final saveDir = Directory('${directory.path}/$_subDirectory');
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }
    return '${saveDir.path}/$_saveFileName';
  }

  @override
  Future<void> save(GameState state) => _activityGate.runCheckpoint(
        NarrativeRuntimeCheckpointOperation.save,
        () async {
          try {
            final filePath = await getSaveFilePath();
            final normalizedSaveData = saveDataFromGameState(state);
            final normalizedState = state.copyWith(
              saveId: normalizedSaveData.saveId,
              currentMapId: normalizedSaveData.currentMapId,
              playerPosition: normalizedSaveData.playerPosition,
              playerFacing: normalizedSaveData.playerFacing,
              party: normalizedSaveData.party,
              trainerProfile: normalizedSaveData.trainerProfile,
              bag: normalizedSaveData.bag,
              progression: normalizedSaveData.progression,
              narrativeFactRuntimeState:
                  normalizedSaveData.narrativeFactRuntimeState,
              narrativeEventProgress: normalizedSaveData.narrativeEventProgress,
              metadata: normalizedSaveData.properties,
            );
            final json = normalizedState.toJson();
            final encoded = await _codecExecutor.encodeJson(json);
            final file = File(filePath);
            if (kDebugMode) {
              debugPrint(
                '[step_studio_trace] save_repo_write_start path=$filePath completedStepIds=${normalizedState.progression.completedStepIds}',
              );
            }
            await file.writeAsString(encoded);
            if (kDebugMode) {
              debugPrint('[save] game saved to $filePath');
              debugPrint(
                '[step_studio_trace] save_repo_write_done path=$filePath completedStepIds=${normalizedState.progression.completedStepIds}',
              );
            }
          } catch (e, st) {
            debugPrint('[save] failed: $e\n$st');
            throw GameSaveException('Failed to save game: $e');
          }
        },
      );

  @override
  Future<GameState?> load() => _activityGate.runCheckpoint(
        NarrativeRuntimeCheckpointOperation.load,
        () async {
          try {
            final filePath = await getSaveFilePath();
            final file = File(filePath);
            if (!await file.exists()) {
              debugPrint('[load] no save file found at $filePath');
              return null;
            }
            final state = await _codecExecutor.decode(
              await file.readAsBytes(),
            );
            debugPrint('[load] game loaded from $filePath');
            return state;
          } catch (e, st) {
            debugPrint('[load] failed: $e\n$st');
            throw GameSaveException('Failed to load game: $e');
          }
        },
      );

  @override
  Future<bool> exists() async {
    try {
      final filePath = await getSaveFilePath();
      final file = File(filePath);
      return await file.exists();
    } catch (e, st) {
      debugPrint('[exists] failed: $e\n$st');
      throw GameSaveException('Failed to check save existence: $e');
    }
  }

  @override
  Future<void> delete() async {
    try {
      final filePath = await getSaveFilePath();
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('[delete] save deleted at $filePath');
      }
    } catch (e, st) {
      debugPrint('[delete] failed: $e\n$st');
      throw GameSaveException('Failed to delete save: $e');
    }
  }
}
