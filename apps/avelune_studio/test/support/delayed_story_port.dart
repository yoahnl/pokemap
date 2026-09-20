import 'dart:async';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/stories/domain/story_port.dart';
import 'package:map_core/map_core.dart';

class DelayedStoryPort implements StoryPort {
  DelayedStoryPort(this.delegate, {this.failOnStory});
  final StoryPort delegate;
  final String? failOnStory;
  final entered = Completer<void>();
  final release = Completer<void>();
  int calls = 0;

  @override
  Future<ResourceMutationReceipt> publishStory({
    required String id,
    required StorylineAsset? base,
    required StorylineAsset? current,
    Set<String> requiredStoryIds = const {},
    Set<String> requiredFactIds = const {},
    Set<String> requiredSceneIds = const {},
  }) async {
    calls++;
    if (!entered.isCompleted) {
      entered.complete();
      await release.future.timeout(const Duration(seconds: 5));
    }
    if (id == failOnStory) throw const StoryFailure('Échec injecté');
    return delegate.publishStory(
      id: id,
      base: base,
      current: current,
      requiredStoryIds: requiredStoryIds,
      requiredFactIds: requiredFactIds,
      requiredSceneIds: requiredSceneIds,
    );
  }

  @override
  Future<ResourceMutationReceipt> publishFact({
    required NarrativeFactDefinition? base,
    required NarrativeFactDefinition current,
  }) => delegate.publishFact(base: base, current: current);
}
