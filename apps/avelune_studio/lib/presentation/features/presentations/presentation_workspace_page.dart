import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/presentations/application/presentation_workspace_controller.dart';
import '../../../features/presentations/application/presentation_preview_transport.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/layout/studio_page_header.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../theme/studio_dialogue_theme.dart';
import '../narrative/narrative_name_dialog.dart';
import 'presentation_view_state.dart';
import 'presentation_workspace_visuals.dart';
import 'presentation_canvas.dart';
import 'presentation_timeline.dart';
import 'presentation_inspector.dart';
import 'presentation_library.dart';
import 'presentation_clip_labels.dart';
import 'presentation_transport_listenable.dart';
import 'presentation_media_picker.dart';

part 'presentation_page_commands.dart';
part 'presentation_page_shortcuts.dart';
part 'presentation_page_header.dart';
part 'presentation_page_body.dart';
part 'presentation_page_library_actions.dart';
part 'presentation_page_preview.dart';
part 'presentation_document_settings.dart';

class PresentationWorkspacePage extends StatefulWidget {
  const PresentationWorkspacePage({
    super.key,
    required this.controller,
    required this.views,
    required this.visuals,
    required this.onBack,
    this.backLabel = 'Histoire',
    this.onMapCinematics,
    this.mediaPicker,
    this.onConsumer,
    this.previewSceneId,
  });
  final PresentationWorkspaceController controller;
  final PresentationViewStore views;
  final PresentationWorkspaceVisuals visuals;
  final VoidCallback onBack;
  final VoidCallback? onMapCinematics;
  final String backLabel;
  final PickPresentationMedia? mediaPicker;
  final Future<void> Function(String sceneId, String nodeId)? onConsumer;
  final String? previewSceneId;
  @override
  State<PresentationWorkspacePage> createState() =>
      _PresentationWorkspacePageState();
}

class _PresentationWorkspacePageState extends State<PresentationWorkspacePage> {
  final transport = PresentationPreviewTransport();
  PresentationWorkspaceController get controller => widget.controller;
  PresentationViewState? get view => controller.active == null
      ? null
      : widget.views.forAsset(controller.active!.asset);
  PresentationCinematicAsset? installed;
  @override
  void initState() {
    super.initState();
    controller.flushEdits = flush;
    controller.suspendPreview = () {
      transport.pause();
      unawaited(widget.visuals.release());
    };
    widget.visuals.bindTransport(transport);
    HardwareKeyboard.instance.addHandler(handleShortcut);
  }

  bool flush() {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    return view?.invalidFields.isEmpty ?? true;
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  void sync() {
    final asset = controller.active?.asset;
    if (asset == null || identical(installed, asset)) return;
    final same = installed?.id == asset.id;
    installed = asset;
    transport.install(asset, preserveTime: same);
    view!.reconcile(asset);
    unawaited(widget.visuals.prepare(asset, portrait: view!.portrait));
  }

  @override
  void didUpdateWidget(covariant PresentationWorkspacePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visuals != widget.visuals) {
      unawaited(oldWidget.visuals.release());
      widget.visuals.bindTransport(transport);
      installed = null;
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(handleShortcut);
    controller.flushEdits = null;
    controller.suspendPreview = null;
    transport.dispose();
    unawaited(widget.visuals.release());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => content(context);
  void resizeCanvas(VoidCallback action) => setState(action);

  Future<void> panel(Widget child) async {
    if (!flush()) return;
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: SizedBox(
          width: 340,
          height: MediaQuery.sizeOf(context).height * .8,
          child: child,
        ),
      ),
    );
    refresh();
  }
}
