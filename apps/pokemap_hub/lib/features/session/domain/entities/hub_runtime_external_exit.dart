import 'dart:async';

import 'package:map_runtime/map_runtime.dart';

typedef HubReturnCallback = FutureOr<void> Function();

/// Runtime exit port that delegates navigation back to the Hub composition.
final class HubRuntimeExternalExit implements RuntimeExternalExit {
  const HubRuntimeExternalExit(this._returnToHub);

  final HubReturnCallback _returnToHub;

  @override
  Future<void> returnToHost() async {
    await _returnToHub();
  }
}
