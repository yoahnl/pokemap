import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

class StoryFlagsManager {
  const StoryFlagsManager();

  static const String _trainerDefeatedPrefix = 'trainer_defeated:';

  static String _normalizeFlag(String flagName) => flagName.trim();

  bool isSet(GameState state, String flagName) {
    final normalized = _normalizeFlag(flagName);
    if (normalized.isEmpty) {
      return false;
    }
    return state.storyFlags.activeFlags.contains(normalized);
  }

  bool isUnset(GameState state, String flagName) => !isSet(state, flagName);

  GameState set(GameState state, String flagName) {
    return const GameStateMutations().setFlag(state, flagName);
  }

  GameState clear(GameState state, String flagName) {
    return const GameStateMutations().clearFlag(state, flagName);
  }

  String trainerDefeatedFlag(String trainerId) {
    final normalizedTrainerId = trainerId.trim();
    if (normalizedTrainerId.isEmpty) {
      return '';
    }
    return '$_trainerDefeatedPrefix$normalizedTrainerId';
  }

  bool isTrainerDefeated(GameState state, String trainerId) {
    final flag = trainerDefeatedFlag(trainerId);
    if (flag.isEmpty) {
      return false;
    }
    return isSet(state, flag);
  }

  GameState markTrainerDefeated(GameState state, String trainerId) {
    final flag = trainerDefeatedFlag(trainerId);
    if (flag.isEmpty) {
      return state;
    }
    return set(state, flag);
  }

  GameState unmarkTrainerDefeated(GameState state, String trainerId) {
    final flag = trainerDefeatedFlag(trainerId);
    if (flag.isEmpty) {
      return state;
    }
    return clear(state, flag);
  }
}
