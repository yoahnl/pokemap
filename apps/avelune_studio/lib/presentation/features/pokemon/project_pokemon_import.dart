import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_external_import_models.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_port.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';
import 'package:flutter/material.dart';

Future<bool?> showProjectPokemonImport(
  BuildContext context, {
  required PokemonWorkspacePort port,
}) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (context) => _ProjectPokemonImportDialog(port: port),
);

class _ProjectPokemonImportDialog extends StatefulWidget {
  const _ProjectPokemonImportDialog({required this.port});

  final PokemonWorkspacePort port;

  @override
  State<_ProjectPokemonImportDialog> createState() =>
      _ProjectPokemonImportDialogState();
}

class _ProjectPokemonImportDialogState
    extends State<_ProjectPokemonImportDialog> {
  final _query = TextEditingController();
  var _suggestions = const <PokemonExternalSuggestion>[];
  PokemonExternalImportPreview? _preview;
  PokemonExternalImportResult? _result;
  String? _error;
  String? _notice;
  var _busy = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_busy) return;
    setState(() {
      _error = null;
      _notice = null;
      _busy = true;
    });
    try {
      await operation();
    } catch (error) {
      if (mounted) _error = '$error';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _search() => _run(() async {
    _preview = null;
    _suggestions = const [];
    final result = await widget.port.searchExternal(_query.text.trim());
    if (!mounted) return;
    _suggestions = result.suggestions;
    _notice =
        result.message ??
        (_suggestions.isEmpty ? context.l10n.pokemonNoResults : null);
  });

  Future<void> _prepare(String id) =>
      _run(() async => _preview = await widget.port.previewExternal(id));

  Future<void> _apply(PokemonExternalImportPreview preview) => _run(() async {
    _result = await widget.port.applyExternal(
      preview,
      preview.hasConflicts
          ? PokemonExternalConflictPolicy.skipExisting
          : PokemonExternalConflictPolicy.failOnConflict,
    );
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preview = _preview;
    final result = _result;
    final messages = result?.warnings ?? preview?.warnings ?? const [];
    return PopScope(
      canPop: !_busy && result == null,
      child: AlertDialog(
        title: Text(l10n.pokemonImportSpecies),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (result != null)
                  StudioNotice(
                    result.requiresReopen
                        ? l10n.pokemonImportReopen
                        : l10n.pokemonImportCompleted,
                  )
                else if (preview != null) ...[
                  Text(
                    preview.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (preview.hasConflicts)
                    StudioNotice(l10n.pokemonImportKeepsExisting),
                ] else ...[
                  StudioSearchField(
                    controller: _query,
                    label: l10n.pokemonSearchExternal,
                    onChanged: (_) => setState(() {}),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: StudioButton(
                      label: l10n.pokemonSearchAction,
                      onPressed: _busy || _query.text.trim().isEmpty
                          ? null
                          : _search,
                    ),
                  ),
                  for (final suggestion in _suggestions)
                    StudioNavigationEntry(
                      label: suggestion.name,
                      detail: '#${suggestion.nationalDex}',
                      icon: Icons.catching_pokemon,
                      onTap: _busy ? null : () => _prepare(suggestion.id),
                    ),
                ],
                if (_busy) const LinearProgressIndicator(),
                if (_error case final error?)
                  StudioNotice(error, isError: true),
                if (_notice case final notice?) StudioNotice(notice),
                for (final message in messages) StudioNotice(message),
              ],
            ),
          ),
        ),
        actions: [
          StudioButton(
            label: result == null ? l10n.leaveGuardCancel : l10n.pokemonDone,
            variant: StudioButtonVariant.secondary,
            onPressed: _busy
                ? null
                : () => Navigator.pop(context, result != null),
          ),
          if (result == null && preview != null)
            StudioButton(
              label: l10n.pokemonImportApply,
              onPressed: _busy ? null : () => _apply(preview),
            ),
        ],
      ),
    );
  }
}
