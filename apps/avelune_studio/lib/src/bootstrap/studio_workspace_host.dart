import 'package:flutter/widgets.dart';

import '../features/map_workspace/application/map_workspace_controller.dart';
import '../features/map_workspace/infrastructure/local_map_workspace_adapter.dart';
import '../features/map_workspace/presentation/map_workspace_screen.dart';
import '../features/map_workspace/rendering/studio_map_resources.dart';
import '../features/playtest/infrastructure/studio_playtest_view.dart';
import '../features/project_session/application/project_session.dart';

class StudioWorkspaceHost extends StatefulWidget {
  const StudioWorkspaceHost({
    super.key,
    required this.session,
    required this.onClose,
    required this.registerExitGuard,
  });
  final ProjectSession session;
  final Future<void> Function() onClose;
  final void Function(Future<bool> Function()?) registerExitGuard;
  @override
  State<StudioWorkspaceHost> createState() => _StudioWorkspaceHostState();
}

class _StudioWorkspaceHostState extends State<StudioWorkspaceHost> {
  late final _port = LocalMapWorkspaceAdapter();
  late final _controller = MapWorkspaceController(widget.session, _port);
  @override
  Widget build(BuildContext context) => MapWorkspaceScreen(
    controller: _controller,
    loadVisuals: StudioMapResources.load,
    runtimeBuilder: (entry, revision, close) => StudioPlaytestView(
      session: widget.session,
      entry: entry,
      expectedRevision: revision,
      port: _port,
      onClose: close,
    ),
    onClose: widget.onClose,
    registerExitGuard: widget.registerExitGuard,
  );
}
