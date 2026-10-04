import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/widgets/buttons/studio_button.dart';

Future<void> showMapCatalogueForm(
  BuildContext context, {
  required String title,
  required String submitLabel,
  required Widget Function(VoidCallback refresh, bool busy) fields,
  required Future<String?> Function() submit,
  bool Function()? valid,
  String Function()? currentSubmitLabel,
  bool Function()? additionalBusy,
  String cancelLabel = 'Annuler',
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _MapCatalogueFormDialog(
    title: title,
    submitLabel: submitLabel,
    fields: fields,
    submit: submit,
    valid: valid,
    currentSubmitLabel: currentSubmitLabel,
    additionalBusy: additionalBusy,
    cancelLabel: cancelLabel,
  ),
);

class _MapCatalogueFormDialog extends StatefulWidget {
  const _MapCatalogueFormDialog({
    required this.title,
    required this.submitLabel,
    required this.fields,
    required this.submit,
    this.valid,
    this.currentSubmitLabel,
    this.additionalBusy,
    required this.cancelLabel,
  });
  final String title, submitLabel;
  final Widget Function(VoidCallback refresh, bool busy) fields;
  final Future<String?> Function() submit;
  final bool Function()? valid;
  final String Function()? currentSubmitLabel;
  final bool Function()? additionalBusy;
  final String cancelLabel;
  @override
  State<_MapCatalogueFormDialog> createState() =>
      _MapCatalogueFormDialogState();
}

class _MapCatalogueFormDialogState extends State<_MapCatalogueFormDialog> {
  bool _busy = false;
  String? _error;
  bool get _working => _busy || widget.additionalBusy?.call() == true;
  Future<void> _submit() async {
    if (_working || widget.valid?.call() == false) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    String? error;
    try {
      error = await widget.submit();
    } on Object catch (failure) {
      error = 'Opération impossible : $failure';
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
    canPop: !_working,
    child: CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): _submit,
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (!_working) Navigator.pop(context);
        },
      },
      child: Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 520,
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
                        }, _working),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
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
                      label: widget.cancelLabel,
                      secondary: true,
                      onPressed: _working ? null : () => Navigator.pop(context),
                    ),
                    StudioButton(
                      label:
                          widget.currentSubmitLabel?.call() ??
                          widget.submitLabel,
                      loading: _working,
                      onPressed: _working || widget.valid?.call() == false
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
