import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';
import 'package:path_provider/path_provider.dart';

import '../../../domain/repositories/game_save_repository.dart';

/// Implémentation fichier de [GameSaveRepository].
///
/// Stocke les sauvegardes dans le répertoire de support de l'application.
/// Chemin : `<ApplicationSupportDirectory>/pokemonProject/game_save.json`
class FileGameSaveRepository implements GameSaveRepository {
  static const String _saveFileName = 'game_save.json';
  static const String _subDirectory = 'pokemonProject';

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
  Future<void> save(GameState state) async {
    try {
      final filePath = await getSaveFilePath();
      final json = state.toJson();
      final file = File(filePath);
      debugPrint(
        '[step_studio_trace] save_repo_write_start path=$filePath completedStepIds=${state.progression.completedStepIds}',
      );
      await file
          .writeAsString(const JsonEncoder.withIndent('  ').convert(json));
      debugPrint('[save] game saved to $filePath');
      debugPrint(
        '[step_studio_trace] save_repo_write_done path=$filePath completedStepIds=${state.progression.completedStepIds}',
      );
    } catch (e, st) {
      debugPrint('[save] failed: $e\n$st');
      throw GameSaveException('Failed to save game: $e');
    }
  }

  @override
  Future<GameState?> load() async {
    try {
      final filePath = await getSaveFilePath();
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('[load] no save file found at $filePath');
        return null;
      }
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final state = normalizeLoadedGameState(GameState.fromJson(json));
      debugPrint('[load] game loaded from $filePath');
      return state;
    } catch (e, st) {
      debugPrint('[load] failed: $e\n$st');
      throw GameSaveException('Failed to load game: $e');
    }
  }

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
