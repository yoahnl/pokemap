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
  var window = (seconds / 40).floor();
  var event = _event(window);
  if (window > 0 && seconds < event.strikeSeconds) event = _event(--window);
  return event;
}

SpatialStormEvent _event(int window) {
  final strike =
      window * 40 + (window == 0 ? 6.1 : 6.1 + _random(window, 1) * 16);
  return SpatialStormEvent(
    id: window,
    strikeSeconds: strike,
    thunderSeconds: strike + .8 + _random(window, 2) * 2.7,
    strength: .65 + _random(window, 3) * .35,
    soundVariant: (_random(window, 4) * 3).floor(),
  );
}

double _random(int window, int salt) {
  var value = (window + 1 + salt * 374761393) & 0xffffffff;
  value = ((value ^ (value >> 16)) * 2246822519) & 0xffffffff;
  value = ((value ^ (value >> 13)) * 3266489917) & 0xffffffff;
  return ((value ^ (value >> 16)) & 0xffffffff) / 4294967296;
}
