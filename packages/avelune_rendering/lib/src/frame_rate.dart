import 'package:flutter/foundation.dart';

abstract final class AveluneFrameRate {
  static const supportedLimits = [30, 45, 60, 90, 120];
  static const defaultLimit = 60;
  static final _limit = ValueNotifier(defaultLimit);

  static int get limit => _limit.value;
  static ValueListenable<int> get changes => _limit;

  static void setLimit(int limit) {
    validate(limit);
    _limit.value = limit;
  }

  static int validate(int limit) {
    if (!supportedLimits.contains(limit)) {
      throw ArgumentError.value(limit, 'limit', 'Unsupported frame rate');
    }
    return limit;
  }
}
