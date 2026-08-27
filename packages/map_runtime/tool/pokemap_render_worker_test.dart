import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/application/authoring_preview/runtime_authoring_asset_render_worker.dart';

const _requestPath = String.fromEnvironment('POKEMAP_RENDER_REQUEST_PATH');
const _responsePath = String.fromEnvironment('POKEMAP_RENDER_RESPONSE_PATH');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders the requested map through the Flutter runtime', () async {
    if (_requestPath.isEmpty || _responsePath.isEmpty) {
      throw StateError('The render worker paths are unavailable.');
    }
    final decoded = jsonDecode(await File(_requestPath).readAsString());
    if (decoded is! Map) throw const FormatException();
    final envelope = Map<String, Object?>.from(decoded);
    final projectRoot = envelope['projectRoot'];
    final request = envelope['request'];
    if (projectRoot is! String || request is! Map) {
      throw const FormatException();
    }
    final response = await renderRuntimeAuthoringAssetRequest(
      projectRoot: projectRoot,
      request: Map<String, Object?>.from(request),
    );
    await File(_responsePath).writeAsString(
      jsonEncode(response),
      flush: true,
    );
  });
}
