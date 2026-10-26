final class SpatialStormEvent {
  const SpatialStormEvent({
    required this.id,
    required this.strikeSeconds,
    required this.thunderSeconds,
    required this.strength,
    required this.soundVariant,
  });
  final int id, soundVariant;
  final double strikeSeconds, thunderSeconds, strength;
}

SpatialStormEvent spatialStormEventAt(double seconds) {
  if (!seconds.isFinite || seconds < 0) {
    throw ArgumentError.value(seconds, 'seconds');
  }
  var window = (seconds / 24).floor();
  var event = _event(window);
  if (window > 0 && seconds < event.strikeSeconds) event = _event(--window);
  return event;
}

SpatialStormEvent _event(int window) {
  final strike =
      window * 24 + (window == 0 ? 4.1 : 4.1 + _random(window, 1) * 8);
  final variant = (_random(window, 4) * 3).floor();
  final distance = _random(window, 2);
  final delay = switch (variant) {0 => .45 + distance * .5, 1 => .9 + distance, _ => 1.8 + distance * 1.7};
  return SpatialStormEvent(
    id: window,
    strikeSeconds: strike,
    thunderSeconds: strike + delay,
    strength: .65 + _random(window, 3) * .35,
    soundVariant: variant,
  );
}

double _random(int window, int salt) {
  var value = (window + 1 + salt * 374761393) & 0xffffffff;
  value = ((value ^ (value >> 16)) * 2246822519) & 0xffffffff;
  value = ((value ^ (value >> 13)) * 3266489917) & 0xffffffff;
  return ((value ^ (value >> 16)) & 0xffffffff) / 4294967296;
}
