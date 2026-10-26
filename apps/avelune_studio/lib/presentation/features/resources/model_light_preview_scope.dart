import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

class ModelLightPreviewScope extends StatefulWidget {
  const ModelLightPreviewScope({
    super.key,
    required this.model,
    required this.child,
  });
  final ProjectModel3dEntry model;
  final Widget child;
  static ModelPreviewController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PreviewBinding>()?.notifier;
  @override
  State<ModelLightPreviewScope> createState() => _ModelLightPreviewScopeState();
}

class _ModelLightPreviewScopeState extends State<ModelLightPreviewScope> {
  final controller = ModelPreviewController();
  @override
  void initState() {
    super.initState();
    controller.setLight(widget.model.light);
  }

  @override
  void didUpdateWidget(ModelLightPreviewScope old) {
    super.didUpdateWidget(old);
    if (old.model.id != widget.model.id ||
        old.model.light != widget.model.light) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) controller.setLight(widget.model.light);
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _PreviewBinding(notifier: controller, child: widget.child);
}

class _PreviewBinding extends InheritedNotifier<ModelPreviewController> {
  const _PreviewBinding({required super.notifier, required super.child});
}
