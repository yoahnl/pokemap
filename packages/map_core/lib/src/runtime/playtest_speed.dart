enum PlaytestSpeed {
  normal(1),
  comfortable(2),
  fast(5),
  fastest(10);

  const PlaytestSpeed(this.multiplier);

  final int multiplier;

  static PlaytestSpeed fromMultiplier(num value) => values.firstWhere(
    (speed) => speed.multiplier == value,
    orElse: () =>
        throw ArgumentError.value(value, 'speed', 'Use 1, 2, 5 or 10.'),
  );
}
