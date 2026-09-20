import 'package:map_core/map_core_domain.dart';
import '../../resources/domain/resource_port.dart';

abstract interface class StoryPort {
  Future<ResourceMutationReceipt> publishStory({
    required String id,
    required StorylineAsset? base,
    required StorylineAsset? current,
    Set<String> requiredStoryIds = const {},
    Set<String> requiredFactIds = const {},
    Set<String> requiredSceneIds = const {},
  });

  Future<ResourceMutationReceipt> publishFact({
    required NarrativeFactDefinition? base,
    required NarrativeFactDefinition current,
  });
}

class StoryFailure implements Exception {
  const StoryFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
