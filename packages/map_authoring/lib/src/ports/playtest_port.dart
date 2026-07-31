import 'dart:async';

import '../contracts/authoring_receipt.dart';
import '../contracts/playtest_contracts.dart';

/// Runtime boundary consumed by the Authoring API and, later, the MCP layer.
///
/// Implementations own all platform resources. [PlaytestSession.stop] is
/// therefore idempotent and is the only successful terminal operation.
abstract interface class PlaytestPort {
  Future<PlaytestSession> start(PlaytestStartRequest request);
}

abstract interface class PlaytestSession {
  String get sessionId;

  PlaytestSessionState get state;

  Stream<PlaytestEvent> get events;

  Future<PlaytestSnapshot> snapshot();

  Future<PlaytestCommandResult> execute(PlaytestCommand command);

  Future<void> pause();

  Future<void> resume();

  Future<AuthoringArtifactRef> captureScreenshot(String name);

  Future<PlaytestReceipt> stop();
}
