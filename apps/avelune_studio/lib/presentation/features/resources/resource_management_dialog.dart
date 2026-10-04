import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/widgets/buttons/studio_button.dart';

Future<void> showResourceManagementRoute(
  BuildContext context,
  WidgetBuilder builder,
) async {
  final route = DialogRoute<void>(
    context: context,
    barrierDismissible: false,
    builder: builder,
  );
  await Navigator.of(context).push(route);
  await route.completed;
}

class ResourceManagementDialog extends StatefulWidget {
  const ResourceManagementDialog({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.fields,
    required this.submit,
    required this.dirty,
    this.valid,
    this.maxWidth = 560,
  });
  final String title, submitLabel;
  final Widget Function(VoidCallback refresh, bool busy) fields;
  final Future<String?> Function() submit;
  final bool Function() dirty;
  final bool Function()? valid;
  final double maxWidth;

  @override
  State<ResourceManagementDialog> createState() =>
      _ResourceManagementDialogState();
}

class _ResourceManagementDialogState extends State<ResourceManagementDialog> {
  bool _busy = false;
  bool _closing = false;
  String? _error;

  Future<void> _close() async {
    if (_busy || _closing) return;
    _closing = true;
    final discard =
        !widget.dirty() ||
        await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Annuler les modifications ?'),
                content: const Text(
                  'Les informations saisies ne seront pas enregistrées.',
                ),
                actions: [
                  StudioButton(
                    label: 'Rester',
                    secondary: true,
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  StudioButton(
                    label: 'Annuler les modifications',
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ],
              ),
            ) ==
            true;
    _closing = false;
    if (mounted && discard) Navigator.pop(context);
  }

  Future<void> _submit() async {
    if (_busy || _closing || widget.valid?.call() == false) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    String? error;
    try {
      error = await widget.submit();
    } on Object catch (failure) {
      error = 'Enregistrement impossible : $failure';
    }
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _close();
    },
    child: CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
      child: Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: widget.maxWidth,
            maxHeight: MediaQuery.sizeOf(context).height - 40,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        widget.fields(() {
                          if (mounted) setState(() {});
                        }, _busy),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            key: const ValueKey('resource-management-error'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StudioButton(
                      key: const ValueKey('resource-management-cancel'),
                      label: 'Annuler',
                      secondary: true,
                      onPressed: _busy ? null : _close,
                    ),
                    StudioButton(
                      key: const ValueKey('resource-management-save'),
                      label: widget.submitLabel,
                      loading: _busy,
                      onPressed: _busy || widget.valid?.call() == false
                          ? null
                          : _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
