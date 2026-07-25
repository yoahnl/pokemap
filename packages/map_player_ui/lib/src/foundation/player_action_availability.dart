final class PlayerActionAvailability {
  const PlayerActionAvailability._({
    required this.isEnabled,
    this.disabledReason,
  });

  static const enabled = PlayerActionAvailability._(isEnabled: true);

  const PlayerActionAvailability.disabled(String reason)
      : this._(isEnabled: false, disabledReason: reason);

  final bool isEnabled;
  final String? disabledReason;
}
