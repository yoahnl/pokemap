abstract interface class SceneSoundEffectPlaybackPort {
  Future<void> playSoundEffect(
    String mediaAssetId, {
    required double volume,
    required String playbackId,
  });
}

abstract interface class SceneSoundCompletionPort {
  Future<bool> waitForPlayback(String playbackId);
}

abstract interface class SceneOwnedSoundEffectPlaybackPort
    implements SceneSoundEffectPlaybackPort {
  Future<void> playOwnedSoundEffect(
    String mediaAssetId, {
    required double volume,
    required String playbackId,
    required Object owner,
    Object? sceneOwner,
  });
  Future<void> stopOwnedSoundEffects(Object owner);
}
