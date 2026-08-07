/// Injectable clock so play-time and save recency stay testable.
abstract interface class ClockPort {
  DateTime now();
}

final class SystemClock implements ClockPort {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
