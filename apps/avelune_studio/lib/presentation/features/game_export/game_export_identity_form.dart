import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class GameExportIdentityForm extends StatelessWidget {
  const GameExportIdentityForm({
    super.key,
    required this.value,
    required this.enabled,
    required this.changed,
    this.problem,
  });

  final StudioGameExportMetadata value;
  final bool enabled;
  final ValueChanged<StudioGameExportMetadata> changed;
  final StudioGameIdentityProblem? problem;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locales = value.locales
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    String? error(StudioGameIdentityField field) =>
        problem?.field == field ? problem!.message : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioDraftField(
          key: const ValueKey('export-title'),
          value: value.title,
          label: l10n.exportTitle,
          enabled: enabled,
          errorText: error(StudioGameIdentityField.title),
          onChanged: (text) => changed(value.copyWith(title: text)),
        ),
        const SizedBox(height: StudioSpacing.l),
        StudioDraftField(
          key: const ValueKey('export-author'),
          value: value.author,
          label: l10n.exportAuthor,
          enabled: enabled,
          errorText: error(StudioGameIdentityField.author),
          onChanged: (text) => changed(value.copyWith(author: text)),
        ),
        const SizedBox(height: StudioSpacing.l),
        StudioDraftField(
          key: const ValueKey('export-version'),
          value: value.version,
          label: l10n.exportVersion,
          enabled: enabled,
          errorText: error(StudioGameIdentityField.version),
          onChanged: (text) => changed(value.copyWith(version: text)),
        ),
        const SizedBox(height: StudioSpacing.l),
        StudioDraftField(
          key: const ValueKey('export-locales'),
          value: value.locales,
          label: l10n.exportLocales,
          helperText: l10n.exportLocalesHint,
          enabled: enabled,
          errorText: error(StudioGameIdentityField.locales),
          onChanged: (text) => changed(value.copyWith(locales: text)),
        ),
        const SizedBox(height: StudioSpacing.l),
        StudioSelect(
          key: const ValueKey('export-default-locale'),
          value: value.locale,
          label: l10n.exportDefaultLocale,
          options: {
            value.locale: value.locale.toUpperCase(),
            for (final locale in locales) locale: locale.toUpperCase(),
          },
          onChanged: enabled
              ? (text) => changed(value.copyWith(locale: text))
              : null,
        ),
        if (error(StudioGameIdentityField.locale) case final message?)
          StudioNotice(message, isError: true),
        ExpansionTile(
          key: const ValueKey('export-identity'),
          title: Text(l10n.exportIdentity),
          children: [
            SelectableText(value.gameId),
            Padding(
              padding: const EdgeInsets.all(StudioSpacing.m),
              child: Text(l10n.exportIdentityHint),
            ),
          ],
        ),
      ],
    );
  }
}
