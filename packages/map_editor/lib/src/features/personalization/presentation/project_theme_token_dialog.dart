import 'package:flutter/material.dart';

import '../../../ui/design_system/design_system.dart';

/// Opens a design-system prompt for one semantic hexadecimal color token.
Future<String?> showProjectThemeTokenDialog({
  required BuildContext context,
  required String tokenLabel,
  required String currentValue,
  String? impactDescription,
  String? Function(String value)? validator,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ProjectThemeTokenDialog(
      tokenLabel: tokenLabel,
      currentValue: currentValue,
      impactDescription: impactDescription,
      validator: validator,
    ),
  );
}

class _ProjectThemeTokenDialog extends StatefulWidget {
  const _ProjectThemeTokenDialog({
    required this.tokenLabel,
    required this.currentValue,
    this.impactDescription,
    this.validator,
  });

  final String tokenLabel;
  final String currentValue;
  final String? impactDescription;
  final String? Function(String value)? validator;

  @override
  State<_ProjectThemeTokenDialog> createState() =>
      _ProjectThemeTokenDialogState();
}

class _ProjectThemeTokenDialogState extends State<_ProjectThemeTokenDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value)) {
      setState(() {
        _errorText =
            'Utilisez exactement six chiffres hexadécimaux, '
            'par exemple #086D7A.';
      });
      return;
    }
    final validationError = widget.validator?.call(value);
    if (validationError != null) {
      setState(() => _errorText = validationError);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const ValueKey<String>('personalization-theme-token-dialog'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: PokeMapPanel(
          header: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Text(
              'Modifier ${widget.tokenLabel}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          footer: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                PokeMapButton(
                  onPressed: () => Navigator.of(context).pop(),
                  variant: PokeMapButtonVariant.secondary,
                  child: const Text('Annuler'),
                ),
                PokeMapButton(
                  onPressed: _submit,
                  child: const Text('Appliquer'),
                ),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (widget.impactDescription != null) ...<Widget>[
                PokeMapDiagnosticCallout(
                  key: const ValueKey<String>(
                    'personalization-theme-token-impact',
                  ),
                  severity: PokeMapDiagnosticSeverity.info,
                  message: widget.impactDescription!,
                ),
                const SizedBox(height: 12),
              ],
              PokeMapTextField(
                label: 'Couleur hexadécimale',
                fieldKey: const ValueKey<String>(
                  'personalization-theme-token-input',
                ),
                controller: _controller,
                placeholder: '#086D7A',
                errorText: _errorText,
                autofocus: true,
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
