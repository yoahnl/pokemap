import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/studio_settings_providers.dart';
import '../../../features/settings/studio_ai_preferences.dart';
import '../../shared/localization/studio_locale.dart';
import 'studio_ai_key_dialog.dart';

class StudioAiSettings extends ConsumerStatefulWidget {
  const StudioAiSettings({super.key});

  @override
  ConsumerState<StudioAiSettings> createState() => _StudioAiSettingsState();
}

class _StudioAiSettingsState extends ConsumerState<StudioAiSettings> {
  late var _providers = _load();

  Future<Set<StudioAiProvider>> _load() async {
    final store = ref.read(studioAiKeyStoreProvider);
    final configured = await Future.wait(
      StudioAiProvider.values.map(store.contains),
    );
    return {
      for (final provider in StudioAiProvider.values)
        if (configured[provider.index]) provider,
    };
  }

  Future<void> _edit(
    List<StudioAiProvider> providers, {
    bool replacing = false,
  }) async {
    final changed = await showDialog<StudioAiProvider>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StudioAiKeyDialog(
        providers: providers,
        store: ref.read(studioAiKeyStoreProvider),
        replacing: replacing,
      ),
    );
    if (mounted && changed != null) _refresh();
  }

  void _refresh() {
    final providers = _load();
    setState(() {
      _providers = providers;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StudioPanel(
      title: l10n.studioSettingsAi,
      icon: Icons.key_outlined,
      compact: true,
      children: [
        Text(l10n.studioSettingsAiLocal),
        const SizedBox(height: StudioSpacing.m),
        FutureBuilder(
          future: _providers,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LinearProgressIndicator();
            }
            final configured = snapshot.data;
            if (configured == null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StudioNotice(l10n.studioSettingsKeyReadError, isError: true),
                  StudioButton(
                    label: l10n.studioSettingsRetry,
                    secondary: true,
                    onPressed: _refresh,
                  ),
                ],
              );
            }
            final available = StudioAiProvider.values
                .where((provider) => !configured.contains(provider))
                .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (configured.isEmpty) Text(l10n.studioSettingsNoProvider),
                for (final provider in configured) ...[
                  const Divider(),
                  _StudioAiProviderRow(
                    key: ValueKey(provider),
                    provider: provider,
                    onReplace: () => _edit([provider], replacing: true),
                  ),
                ],
                if (available.isNotEmpty) ...[
                  const SizedBox(height: StudioSpacing.m),
                  StudioButton(
                    key: const ValueKey('studio-settings-add-provider'),
                    label: l10n.studioSettingsAddProvider,
                    icon: Icons.add,
                    secondary: true,
                    onPressed: () => unawaited(_edit(available)),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StudioAiProviderRow extends ConsumerStatefulWidget {
  const _StudioAiProviderRow({
    super.key,
    required this.provider,
    required this.onReplace,
  });

  final StudioAiProvider provider;
  final Future<void> Function() onReplace;

  @override
  ConsumerState<_StudioAiProviderRow> createState() =>
      _StudioAiProviderRowState();
}

class _StudioAiProviderRowState extends ConsumerState<_StudioAiProviderRow> {
  String? _visibleKey;
  StudioAiConnectionResult? _result;
  var _busy = false;
  var _testing = false;
  var _readError = false;

  Future<void> _withKey(Future<void> Function(String) action) async {
    setState(() {
      _busy = true;
      _readError = false;
    });
    try {
      final key = await ref
          .read(studioAiKeyStoreProvider)
          .read(widget.provider);
      if (!mounted) return;
      if (key == null) {
        _readError = true;
        return;
      }
      await action(key);
    } on Exception {
      _readError = true;
    } finally {
      if (mounted) {
        setState(() {
          _testing = false;
          _busy = false;
        });
      }
    }
  }

  Future<void> _toggleKey() async {
    if (_visibleKey != null) {
      setState(() => _visibleKey = null);
      return;
    }
    await _withKey((key) async => _visibleKey = key);
  }

  Future<void> _test() async {
    final connection = ref.read(studioAiConnectionProvider);
    _testing = true;
    _result = null;
    await _withKey((key) async {
      final result = await connection.test(widget.provider, key);
      if (mounted) _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final feedback = switch (_result) {
      StudioAiConnectionResult.connected => l10n.studioSettingsConnectionOk,
      StudioAiConnectionResult.denied => l10n.studioSettingsConnectionDenied,
      StudioAiConnectionResult.unavailable =>
        l10n.studioSettingsConnectionUnavailable,
      null => null,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: StudioSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: StudioSpacing.l,
            runSpacing: StudioSpacing.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  widget.provider.label,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              if (_visibleKey == null)
                Text('••••••••••', semanticsLabel: l10n.studioSettingsKeySaved),
              StudioTool(
                label: _visibleKey == null
                    ? l10n.studioSettingsShowKey
                    : l10n.studioSettingsHideKey,
                icon: _visibleKey == null
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                onPressed: _busy ? null : () => unawaited(_toggleKey()),
              ),
              StudioTool(
                label: l10n.studioSettingsChangeKey,
                icon: Icons.edit_outlined,
                onPressed: _busy
                    ? null
                    : () {
                        setState(() {
                          _visibleKey = null;
                          _result = null;
                        });
                        unawaited(widget.onReplace());
                      },
              ),
              StudioButton(
                label: _testing
                    ? l10n.studioSettingsTestingConnection
                    : l10n.studioSettingsTestConnection,
                secondary: true,
                onPressed: _busy ? null : () => unawaited(_test()),
              ),
            ],
          ),
          if (_visibleKey case final key?)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: StudioSpacing.s),
              child: SelectableText(key),
            ),
          if (_readError)
            StudioNotice(l10n.studioSettingsKeyReadError, isError: true)
          else if (feedback != null)
            Semantics(
              liveRegion: true,
              child: StudioNotice(
                feedback,
                isError: _result != StudioAiConnectionResult.connected,
              ),
            ),
        ],
      ),
    );
  }
}
