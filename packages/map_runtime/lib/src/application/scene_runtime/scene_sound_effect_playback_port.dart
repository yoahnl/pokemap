abstract interface class SceneSoundEffectPlaybackPort {
  Future<void> playSoundEffect(
    String mediaAssetId, {
    required double volume,
    required String playbackId,
  });
}
