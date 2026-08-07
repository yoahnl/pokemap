import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A request to display the shell toast again.
///
/// The status bar pill truncates its message, and the shell toast that carried
/// the full text has usually vanished by the time the user reads the pill.
/// Replaying is how the full message gets back on screen.
///
/// [revision] increments on every request so two identical messages stay
/// distinct: `ref.listen` must fire again when the same error is replayed.
class EditorToastReplayRequest {
  const EditorToastReplayRequest({
    required this.message,
    required this.isError,
    required this.revision,
  });

  final String message;
  final bool isError;
  final int revision;
}

class EditorToastReplayNotifier extends Notifier<EditorToastReplayRequest?> {
  @override
  EditorToastReplayRequest? build() => null;

  void replay(String message, {required bool isError}) {
    state = EditorToastReplayRequest(
      message: message,
      isError: isError,
      revision: (state?.revision ?? 0) + 1,
    );
  }
}

final editorToastReplayProvider =
    NotifierProvider<EditorToastReplayNotifier, EditorToastReplayRequest?>(
  EditorToastReplayNotifier.new,
);
