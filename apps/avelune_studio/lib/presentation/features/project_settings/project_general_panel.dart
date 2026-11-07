import 'package:flutter/material.dart';

import '../../../features/project_settings/application/project_identity_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/layout/studio_section.dart';

class ProjectGeneralPanel extends StatelessWidget {
  const ProjectGeneralPanel({
    super.key,
    required this.identity,
    this.onOpenExport,
  });

  final ProjectIdentityController identity;
  final VoidCallback? onOpenExport;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: identity,
    builder: (context, _) {
      if (!identity.ready) {
        final error = identity.error;
        return error == null
            ? const Center(child: CircularProgressIndicator())
            : StudioNotice(error, isError: true);
      }
      final draft = identity.draft;
      final enabled = !identity.saving;
      String? problem(StudioGameIdentityField field) =>
          identity.fieldErrors[field];
      Widget field(
        StudioGameIdentityField key,
        String label,
        String value,
        ValueChanged<String> onChanged, {
        String? helper,
      }) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: StudioDraftField(
          key: ValueKey('identity-${key.name}'),
          label: label,
          value: value,
          enabled: enabled,
          errorText: problem(key),
          helperText: helper,
          onChanged: onChanged,
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (identity.needsFirstSave) ...[
            const StudioNotice(
              'Cette identité est proposée à partir du nom du projet. Elle '
              'n’est pas encore enregistrée : enregistrez la rubrique pour la '
              'fixer.',
            ),
            const SizedBox(height: 12),
          ],
          if (identity.conflict case final external?) ...[
            _ConflictPanel(identity: identity, external: external),
            const SizedBox(height: 12),
          ],
          StudioPanel(
            title: 'Identité du jeu',
            icon: Icons.public,
            children: [
              const Text(
                'Ces informations sont reprises telles quelles dans la '
                'préparation de l’export. Elles ne renomment pas le projet.',
              ),
              const SizedBox(height: 12),
              field(
                StudioGameIdentityField.title,
                'Titre du jeu',
                draft.title,
                (value) => identity.edit(title: value),
              ),
              field(
                StudioGameIdentityField.author,
                'Auteur ou équipe',
                draft.author,
                (value) => identity.edit(author: value),
              ),
              field(
                StudioGameIdentityField.version,
                'Version du contenu',
                draft.version,
                (value) => identity.edit(version: value),
                helper:
                    'Exemple : 1.0.0. Distincte de la version de Studio et du '
                    'format de fichier.',
              ),
            ],
          ),
          const SizedBox(height: 12),
          StudioPanel(
            title: 'Langues',
            icon: Icons.translate,
            children: [
              field(
                StudioGameIdentityField.locale,
                'Langue principale',
                draft.locale,
                (value) => identity.edit(locale: value),
                helper: 'Code court, par exemple fr.',
              ),
              field(
                StudioGameIdentityField.locales,
                'Langues disponibles',
                draft.locales,
                (value) => identity.edit(locales: value),
                helper:
                    'Séparées par des virgules, par exemple fr, en. La langue '
                    'principale doit en faire partie.',
              ),
            ],
          ),
          const SizedBox(height: 12),
          StudioSection(
            key: const ValueKey('settings-general-technical'),
            title: 'Identité technique',
            collapsible: true,
            initiallyExpanded: false,
            children: [
              SelectableText(
                draft.gameId,
                key: const ValueKey('identity-game-id'),
              ),
              const SizedBox(height: 6),
              const Text(
                'Cet identifiant stable relie le jeu installé et les '
                'sauvegardes des joueurs à votre projet. Changer le titre ne '
                'le modifie pas.',
              ),
              if (problem(StudioGameIdentityField.gameId)
                  case final error?) ...[
                const SizedBox(height: 8),
                StudioNotice(error, isError: true),
              ],
            ],
          ),
          if (onOpenExport case final open?) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: StudioButton(
                label: 'Voir le résumé d’export',
                icon: Icons.ios_share,
                secondary: true,
                onPressed: open,
              ),
            ),
          ],
        ],
      );
    },
  );
}

class _ConflictPanel extends StatelessWidget {
  const _ConflictPanel({required this.identity, required this.external});

  final ProjectIdentityController identity;
  final StudioGameIdentityState external;

  @override
  Widget build(BuildContext context) {
    final saved = external.metadata;
    final draft = identity.draft;
    final rows = <(String, String?, String)>[
      ('Titre', saved?.title, draft.title),
      ('Auteur', saved?.author, draft.author),
      ('Version', saved?.version, draft.version),
      ('Langue principale', saved?.locale, draft.locale),
      ('Langues disponibles', saved?.locales, draft.locales),
    ].where((row) => row.$2 != row.$3).toList();
    final contextOnly =
        external.profileRevision == identity.saved?.profileRevision;
    return StudioPanel(
      title: 'Enregistrement bloqué',
      icon: Icons.sync_problem,
      children: [
        if (identity.error case final error?)
          StudioNotice(error, isError: true),
        const SizedBox(height: 8),
        for (final row in rows)
          Text(
            '${row.$1} : enregistré « ${row.$2 ?? '—'} » · brouillon « ${row.$3} »',
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StudioButton(
              key: const ValueKey('identity-reload-external'),
              label: 'Reprendre la version enregistrée',
              secondary: true,
              onPressed: identity.reloadExternal,
            ),
            if (contextOnly)
              StudioButton(
                key: const ValueKey('identity-keep-draft'),
                label: 'Garder mon brouillon',
                onPressed: identity.keepDraftOnNewContext,
              ),
          ],
        ),
      ],
    );
  }
}
