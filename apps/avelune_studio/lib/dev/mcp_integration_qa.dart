import 'dart:async';
import 'dart:io';

import 'package:avelune_rendering/avelune_rendering.dart';
import 'package:flutter/widgets.dart';

import '../app/studio_bootstrap.dart';
import '../main.dart' show loadStudioProjectTemplateCatalog;
import '../platform/mcp/studio_mcp_process.dart';
import '../platform/mcp/studio_mcp_project_access.dart';
import '../platform/mcp/studio_mcp_service.dart';

Future<void> main() async {
  const path = String.fromEnvironment('AVELUNE_MCP_QA_CONNECTION_FILE');
  if (!Platform.isMacOS || path.isEmpty || !File(path).isAbsolute) {
    throw StateError('The native MCP qualification requires a private connection file.');
  }
  AveluneWidgetsFlutterBinding.ensureInitialized();
  final output = File(path);
  final service = StudioMcpService(
    launch: launchStudioMcpProcess,
    projectBookmark: createStudioMcpProjectBookmark,
  );
  var updates = Future<void>.value();
  service.addListener(() {
    final configuration = service.state == StudioMcpState.ready
        ? service.connection?.clientConfiguration
        : null;
    updates = updates.then((_) async {
      if (configuration == null) {
        if (await output.exists()) await output.delete();
      } else {
        await output.parent.create(recursive: true);
        final staged = File('${output.path}.staged');
        await staged.writeAsString(configuration, flush: true);
        await staged.rename(output.path);
      }
    }).catchError((Object _) {
      debugPrint('Native MCP qualification connection export failed.');
    });
  });
  final catalog = await loadStudioProjectTemplateCatalog();
  runApp(StudioBootstrap(templateCatalog: catalog, mcpService: service));
}
