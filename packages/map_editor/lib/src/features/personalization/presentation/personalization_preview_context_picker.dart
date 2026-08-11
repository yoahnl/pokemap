import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';
import '../application/personalization_preview_context_source.dart';
import '../application/personalization_preview_surface_descriptor.dart';

class PersonalizationPreviewContextPicker extends StatelessWidget {
  const PersonalizationPreviewContextPicker({
    super.key,
    required this.scene,
    required this.contexts,
    required this.selectedIds,
    required this.onSelected,
    this.isLoading = false,
    this.errorMessage,
  });

  final PersonalizationStudioScene scene;
  final List<PersonalizationPreviewContextOption> contexts;
  final Map<PersonalizationPreviewContextKind, String?> selectedIds;
  final void Function(PersonalizationPreviewContextKind kind, String id)
  onSelected;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final kinds = _kindsForScene(scene);
    if (kinds.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Divider(height: 20),
        Text(
          'Scène de test',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          'Choisissez la carte et le contenu utilisés pour essayer ce rendu.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.pokeMapColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const PokeMapDiagnosticCallout(
            key: ValueKey<String>('personalization-preview-context-loading'),
            severity: PokeMapDiagnosticSeverity.info,
            message: 'Chargement des cartes, dialogues et rencontres…',
          )
        else if (errorMessage != null)
          PokeMapDiagnosticCallout(
            key: const ValueKey<String>(
              'personalization-preview-context-error',
            ),
            severity: PokeMapDiagnosticSeverity.error,
            message: errorMessage!,
          )
        else
          _ContextFields(
            kinds: kinds,
            contexts: contexts,
            selectedIds: selectedIds,
            onSelected: onSelected,
          ),
      ],
    );
  }
}

class _ContextFields extends StatelessWidget {
  const _ContextFields({
    required this.kinds,
    required this.contexts,
    required this.selectedIds,
    required this.onSelected,
  });

  final List<PersonalizationPreviewContextKind> kinds;
  final List<PersonalizationPreviewContextOption> contexts;
  final Map<PersonalizationPreviewContextKind, String?> selectedIds;
  final void Function(PersonalizationPreviewContextKind kind, String id)
  onSelected;

  @override
  Widget build(BuildContext context) {
    final missing = <PersonalizationPreviewContextKind>[];
    final fields = <Widget>[];
    for (final kind in kinds) {
      final options = contexts
          .where((option) => option.kind == kind)
          .toList(growable: false);
      if (options.isEmpty) {
        missing.add(kind);
        continue;
      }
      final selected = options
          .where((option) => option.id == selectedIds[kind])
          .firstOrNull;
      final value = selected?.id ?? _preferred(options).id;
      fields.add(
        SizedBox(
          width: 210,
          child: PokeMapDropdownField<String>(
            key: ValueKey<String>(
              'personalization-preview-context-${kind.name}',
            ),
            compact: true,
            label: _kindLabel(kind),
            value: value,
            items: <PokeMapDropdownItem<String>>[
              for (final option in options)
                PokeMapDropdownItem<String>(
                  value: option.id,
                  label: option.isReady
                      ? option.label
                      : '${option.label} · incomplet',
                ),
            ],
            onChanged: (id) => onSelected(kind, id),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (fields.isNotEmpty)
          Wrap(spacing: 8, runSpacing: 8, children: fields),
        if (missing.isNotEmpty) ...<Widget>[
          if (fields.isNotEmpty) const SizedBox(height: 8),
          PokeMapDiagnosticCallout(
            key: const ValueKey<String>(
              'personalization-preview-context-empty',
            ),
            severity: PokeMapDiagnosticSeverity.warning,
            message:
                'Aucun ${missing.map(_kindMissingLabel).join(' ni ')} '
                'n’est disponible dans le projet.',
          ),
        ],
      ],
    );
  }
}

PersonalizationPreviewContextOption _preferred(
  List<PersonalizationPreviewContextOption> options,
) => options.where((option) => option.isReady).firstOrNull ?? options.first;

List<PersonalizationPreviewContextKind> _kindsForScene(
  PersonalizationStudioScene scene,
) => switch (scene) {
  PersonalizationStudioScene.title || PersonalizationStudioScene.intro =>
    const <PersonalizationPreviewContextKind>[],
  PersonalizationStudioScene.pause => const <PersonalizationPreviewContextKind>[
    PersonalizationPreviewContextKind.map,
  ],
  PersonalizationStudioScene.dialogue =>
    const <PersonalizationPreviewContextKind>[
      PersonalizationPreviewContextKind.map,
      PersonalizationPreviewContextKind.dialogue,
      PersonalizationPreviewContextKind.characterPortrait,
    ],
  PersonalizationStudioScene.battle =>
    const <PersonalizationPreviewContextKind>[
      PersonalizationPreviewContextKind.map,
      PersonalizationPreviewContextKind.encounter,
    ],
  PersonalizationStudioScene.globalStyle =>
    const <PersonalizationPreviewContextKind>[
      PersonalizationPreviewContextKind.map,
    ],
};

String _kindLabel(PersonalizationPreviewContextKind kind) => switch (kind) {
  PersonalizationPreviewContextKind.map => 'Décor',
  PersonalizationPreviewContextKind.dialogue => 'Dialogue',
  PersonalizationPreviewContextKind.characterPortrait => 'Portrait',
  PersonalizationPreviewContextKind.encounter => 'Rencontre',
};

String _kindMissingLabel(PersonalizationPreviewContextKind kind) =>
    switch (kind) {
      PersonalizationPreviewContextKind.map => 'décor de carte',
      PersonalizationPreviewContextKind.dialogue => 'dialogue',
      PersonalizationPreviewContextKind.characterPortrait => 'portrait',
      PersonalizationPreviewContextKind.encounter => 'rencontre',
    };
