import '../application/runtime_overworld_interaction.dart';

abstract interface class RuntimeOverworldInteractionPort {
  RuntimeOverworldInteractionSnapshot? get overworldInteractionSnapshot;

  Stream<RuntimeOverworldInteractionSnapshot?>
      get overworldInteractionSnapshots;

  bool dispatchOverworldInteraction(RuntimeOverworldInteractionRequest request);
}
