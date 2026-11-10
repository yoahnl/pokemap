import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/updates/studio_update_catalog.dart';
import '../../features/updates/studio_update_controller.dart';

class StudioUpdateService {
  StudioUpdateService({
    required Future<bool> Function() prepareForRestart,
    required Future<void> Function() resumeAfterFailure,
  }) {
    final catalog = StudioUpdateCatalog(_client);
    controller = StudioUpdateController(
      nativeUpdater: !kIsWeb && Platform.isMacOS,
      checkRelease: () async =>
          catalog.newerThan((await PackageInfo.fromPlatform()).version),
      openNativeUpdate: (operationId) => _channel.invokeMethod<void>(
        'openUpdateFlow',
        {'operationId': operationId},
      ),
      respondToRestart: (operationId, allowed) => _channel.invokeMethod<void>(
        'respondToRestart',
        {'operationId': operationId, 'canRestart': allowed},
      ),
      openReleaseNotes: (uri) =>
          launchUrl(uri, mode: LaunchMode.externalApplication),
      prepareForRestart: prepareForRestart,
      resumeAfterFailure: resumeAfterFailure,
    );
    if (!kIsWeb && kReleaseMode) {
      if (Platform.isMacOS) {
        _channel.setMethodCallHandler(_handleNativeCall);
        _attached = true;
      }
      controller.scheduleCheck();
    }
  }

  static const _channel = MethodChannel('map_editor/editor_updates');
  final http.Client _client = http.Client();
  late final StudioUpdateController controller;
  bool _attached = false;

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'manualCheckRequested') {
      await controller.checkForUpdates();
    } else if (call.method == 'updateEvent' && call.arguments is Map) {
      await controller.handleEvent(call.arguments as Map);
    }
  }

  void dispose() {
    if (_attached) {
      _channel.setMethodCallHandler(null);
      _attached = false;
    }
    controller.dispose();
    _client.close();
  }
}
