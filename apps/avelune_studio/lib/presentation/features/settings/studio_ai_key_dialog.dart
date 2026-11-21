import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import '../../../features/settings/studio_ai_preferences.dart';
import '../../shared/localization/studio_locale.dart';

class StudioAiKeyDialog extends StatefulWidget {
  const StudioAiKeyDialog({
    super.key,
    required this.providers,
    required this.store,
    required this.replacing,
  });

  final List<StudioAiProvider> providers;
  final StudioAiKeyStore store;
  final bool replacing;

  @override
  State<StudioAiKeyDialog> createState() => _StudioAiKeyDialogState();
}

class _StudioAiKeyDialogState extends State<StudioAiKeyDialog> {
  final _text = TextEditingController();
  late var _provider = widget.providers.first;
  var _busy = false;
  var _visible = false;
  var _invalid = false;
  var _failed = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _write(Future<void> Function() change) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await change();
      if (mounted) Navigator.of(context).pop(_provider);
    } on Exception {
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
    }
  }

  Future<void> _save() async {
    final key = studioAiKeyInput(_text.text);
    if (key == null) {
      setState(() => _invalid = true);
      return;
    }
    await _write(() => widget.store.write(_provider, key));
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.studioSettingsDeleteKeyConfirm),
        actions: [
          StudioButton(
            label: l10n.studioSettingsCancel,
            secondary: true,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          StudioButton(
            label: l10n.studioSettingsDeleteKey,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (mounted && confirmed == true) {
      await _write(() => widget.store.delete(_provider));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(
          widget.replacing
              ? l10n.studioSettingsChangeKey
              : l10n.studioSettingsAddProvider,
        ),
        scrollable: true,
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.replacing)
                Text(_provider.label)
              else
                StudioSelect(
                  label: l10n.studioSettingsProvider,
                  value: _provider.name,
                  options: {
                    for (final provider in widget.providers)
                      provider.name: provider.label,
                  },
                  onChanged: _busy
                      ? null
                      : (value) => setState(
                          () =>
                              _provider = StudioAiProvider.values.byName(value),
                        ),
                ),
              const SizedBox(height: StudioSpacing.l),
              TextField(
                key: const ValueKey('studio-settings-api-key'),
                controller: _text,
                enabled: !_busy,
                obscureText: !_visible,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: l10n.studioSettingsApiKey,
                  errorText: _invalid ? l10n.studioSettingsInvalidKey : null,
                  suffixIcon: StudioTool(
                    label: _visible
                        ? l10n.studioSettingsHideKey
                        : l10n.studioSettingsShowKey,
                    icon: _visible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    onPressed: () => setState(() => _visible = !_visible),
                  ),
                ),
                onChanged: (_) {
                  if (_invalid) setState(() => _invalid = false);
                },
                onSubmitted: (_) => unawaited(_save()),
              ),
              if (_failed)
                StudioNotice(l10n.studioSettingsKeyWriteError, isError: true),
            ],
          ),
        ),
        actions: [
          if (widget.replacing)
            StudioButton(
              label: l10n.studioSettingsDeleteKey,
              secondary: true,
              onPressed: _busy ? null : () => unawaited(_delete()),
            ),
          StudioButton(
            label: l10n.studioSettingsCancel,
            secondary: true,
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
          ),
          StudioButton(
            label: _busy
                ? l10n.studioSettingsSaving
                : l10n.studioSettingsSaveKey,
            onPressed: _busy ? null : () => unawaited(_save()),
          ),
        ],
      ),
    );
  }
}
