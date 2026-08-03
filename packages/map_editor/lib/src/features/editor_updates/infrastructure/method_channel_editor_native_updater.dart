import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../domain/editor_native_updater.dart';
import '../domain/editor_update_models.dart';

const _windowsNativeUpdateEnabled = bool.fromEnvironment(
  'POKEMAP_WINDOWS_AUTO_UPDATE_ENABLED',
  defaultValue: false,
);

final class MethodChannelEditorNativeUpdater implements EditorNativeUpdater {
  MethodChannelEditorNativeUpdater({
    MethodChannel channel = const MethodChannel('map_editor/editor_updates'),
    bool? isSupported,
    EditorNativeUpdaterCapabilities? capabilities,
  })  : _channel = channel,
        isSupported = isSupported ??
            (Platform.isMacOS ||
                (Platform.isWindows && _windowsNativeUpdateEnabled)),
        capabilities = capabilities ??
            (Platform.isWindows
                ? EditorNativeUpdaterCapabilities.windowsV1
                : EditorNativeUpdaterCapabilities.macosV1) {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  final MethodChannel _channel;
  final StreamController<EditorNativeUpdateEvent> _events =
      StreamController<EditorNativeUpdateEvent>.broadcast(sync: true);
  final StreamController<void> _manualCheckRequests =
      StreamController<void>.broadcast(sync: true);

  @override
  final bool isSupported;

  @override
  final EditorNativeUpdaterCapabilities capabilities;

  @override
  Stream<EditorNativeUpdateEvent> get events => _events.stream;

  @override
  Stream<void> get manualCheckRequests => _manualCheckRequests.stream;

  @override
  Future<void> openUpdateFlow({
    required String operationId,
    required EditorUpdateRelease release,
  }) async {
    if (!isSupported) {
      throw UnsupportedError(
          'Native updates are not supported on this platform.');
    }
    await _channel.invokeMethod<void>('openUpdateFlow', {
      'operationId': operationId,
      'version': release.version.toString(),
      'tag': release.tag,
    });
  }

  @override
  Future<void> setRestartReady({required bool canRestart}) async {
    if (!isSupported) {
      return;
    }
    await _channel.invokeMethod<void>('setRestartReady', {
      'canRestart': canRestart,
    });
  }

  @override
  Future<void> respondToRestart({
    required String operationId,
    required bool canRestart,
  }) async {
    if (!isSupported) {
      return;
    }
    await _channel.invokeMethod<void>('respondToRestart', {
      'operationId': operationId,
      'canRestart': canRestart,
    });
  }

  @override
  Future<void> dispose() async {
    _channel.setMethodCallHandler(null);
    await _events.close();
    await _manualCheckRequests.close();
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'manualCheckRequested') {
      if (!_manualCheckRequests.isClosed) {
        _manualCheckRequests.add(null);
      }
      return;
    }
    if (call.method != 'updateEvent' || _events.isClosed) {
      return;
    }
    final arguments = call.arguments;
    if (arguments is! Map) {
      return;
    }
    final kind = arguments['kind'];
    final operationId = arguments['operationId'];
    if (kind is! String || operationId is! String || operationId.isEmpty) {
      return;
    }

    final EditorNativeUpdateEvent? event = switch (kind) {
      'cancelled' => EditorNativeUpdateEvent.cancelled(operationId),
      'noUpdate' => EditorNativeUpdateEvent.noUpdate(operationId),
      'installing' => EditorNativeUpdateEvent.installing(operationId),
      'restartRequested' =>
        EditorNativeUpdateEvent.restartRequested(operationId),
      'failed' => EditorNativeUpdateEvent.failed(
          operationId,
          const EditorUpdateFailure(
            code: 'native_update_failed',
            message: 'The native update flow failed.',
          ),
        ),
      _ => null,
    };
    if (event != null) {
      _events.add(event);
    }
  }
}
