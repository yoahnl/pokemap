import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'pokemon_draft_controls.dart';
import 'pokemon_media_preview.dart';
import 'pokemon_media_role_card.dart';
import 'pokemon_ui_parts.dart';

class PokemonSpeciesMediaEditor extends StatefulWidget {
  const PokemonSpeciesMediaEditor({
    super.key,
    required this.controller,
    this.pickPng,
  });

  final PokemonWorkspaceController controller;
  final Future<String?> Function()? pickPng;

  @override
  State<PokemonSpeciesMediaEditor> createState() =>
      _PokemonSpeciesMediaEditorState();
}

class _PokemonSpeciesMediaEditorState extends State<PokemonSpeciesMediaEditor> {
  String? ownerId;
  String? selectedForm;
  String selectedRole = 'icon';

  static const roles = [
    'icon',
    'party',
    'portrait',
    'frontStatic',
    'backStatic',
    'frontShinyStatic',
    'backShinyStatic',
    'overworld',
    'cry',
  ];

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final draft = controller.selectedDraft;
    final json = draft?.document(PokemonDocumentFamily.media);
    final references =
        (draft?.document(PokemonDocumentFamily.species)?['refs'] as Map?)
            ?.cast<String, dynamic>();
    if (references?['media'] == null || references?['media'] == '') {
      return const PokemonEmptyState(
        title: 'Aucun document média lié',
        description:
            'Cette fiche ne déclare aucune référence média. Les autres '
            'sections restent disponibles.',
        icon: Icons.image_not_supported_outlined,
      );
    }
    final variants = (json?['variants'] as Map?)?.cast<String, dynamic>() ?? {};
    final forms = <String>{
      ...?controller.index?.entries
          .where((entry) => entry.id == draft?.id)
          .firstOrNull
          ?.formIds,
      ...variants.keys,
    }.where((form) => form.isNotEmpty).toList();
    if (ownerId != draft?.id) {
      ownerId = draft?.id;
      selectedForm = null;
      selectedRole = 'icon';
    }
    final form = forms.contains(selectedForm)
        ? selectedForm
        : forms.contains(json?['defaultFormId'])
        ? json!['defaultFormId'] as String
        : forms.firstOrNull;
    final values = (variants[form] as Map?)?.cast<String, dynamic>() ?? {};
    final path = values[selectedRole] as String?;
    final fields = PokemonDraftControls(
      controller,
      PokemonDocumentFamily.media,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PokemonSectionHeading(
          title: 'Médias de l’espèce',
          description:
              'Une référence ne garantit pas que le fichier existe. '
              'L’import PNG conserve un rôle déjà associé.',
        ),
        if (json == null)
          const PokemonSurface(
            child: Text(
              'Le document média est absent. Un import PNG peut le créer '
              'pour un rôle pris en charge.',
            ),
          )
        else
          StudioPanel(
            title: 'Organisation des formes',
            children: [
              LayoutBuilder(
                builder: (context, bounds) {
                  final formChoice = StudioSelect(
                    label: 'Forme consultée',
                    value: form,
                    options: {for (final item in forms) item: item},
                    onChanged: (value) => setState(() => selectedForm = value),
                  );
                  final defaultField = fields.text('Forme par défaut', [
                    'defaultFormId',
                  ]);
                  if (bounds.maxWidth < 530) {
                    return Column(children: [formChoice, defaultField]);
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: formChoice),
                      const SizedBox(width: 12),
                      Expanded(child: defaultField),
                    ],
                  );
                },
              ),
            ],
          ),
        const SizedBox(height: 12),
        if (form == null)
          const PokemonEmptyState(
            title: 'Aucune forme disponible',
            description:
                'Associez d’abord une forme dans la fiche de l’espèce.',
          )
        else
          LayoutBuilder(
            builder: (context, bounds) {
              final sideBySide = bounds.maxWidth >= 760;
              final library = _roleLibrary(
                values,
                sideBySide ? bounds.maxWidth * .55 : bounds.maxWidth,
              );
              final detail = _roleDetail(
                context,
                fields,
                form,
                path,
                json != null,
              );
              if (!sideBySide) {
                return Column(
                  children: [library, const SizedBox(height: 12), detail],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 55, child: library),
                  const SizedBox(width: 12),
                  Expanded(flex: 45, child: detail),
                ],
              );
            },
          ),
        if (form != null && values['animations'] is Map) ...[
          const SizedBox(height: 12),
          StudioPanel(
            title: 'Références d’animations',
            children: [
              for (final animation
                  in (values['animations'] as Map).entries) ...[
                Text(
                  'Animation ${animation.key}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (json != null) ...[
                  fields.text('Feuille', [
                    'variants',
                    form,
                    'animations',
                    '${animation.key}',
                    'sheet',
                  ]),
                  fields.text('Identifiant de l’animation', [
                    'variants',
                    form,
                    'animations',
                    '${animation.key}',
                    'animationId',
                  ]),
                ],
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _roleLibrary(Map<String, dynamic> values, double width) {
    final columns = width >= 500 ? 2 : 1;
    final itemWidth = (width - (columns - 1) * 8) / columns;
    return StudioPanel(
      title: 'Rôles de la forme',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final role in roles)
              SizedBox(
                width: itemWidth,
                child: PokemonMediaRoleCard(
                  role: role,
                  path: values[role] as String?,
                  selected: selectedRole == role,
                  onTap: () => setState(() => selectedRole = role),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _roleDetail(
    BuildContext context,
    PokemonDraftControls fields,
    String form,
    String? path,
    bool hasDocument,
  ) {
    final canImport =
        widget.pickPng != null &&
        const {'icon', 'party', 'portrait'}.contains(selectedRole);
    return StudioPanel(
      title: pokemonMediaRoleLabel(selectedRole),
      children: [
        if (path == null || path.isEmpty)
          const PokemonEmptyState(
            title: 'Aucune référence',
            description: 'Aucun fichier associé à ce rôle.',
            icon: Icons.image_not_supported_outlined,
          )
        else if (selectedRole == 'cry')
          const PokemonEmptyState(
            title: 'Cri référencé',
            description:
                'Aucun lecteur audio n’est disponible dans cette fiche.',
            icon: Icons.graphic_eq,
          )
        else
          PokemonMediaPreview(
            key: ValueKey('media-preview-$form-$selectedRole-$path'),
            path: path,
            controller: widget.controller,
          ),
        const SizedBox(height: 10),
        if (hasDocument)
          fields.text('Chemin du fichier', ['variants', form, selectedRole]),
        if (canImport)
          StudioButton(
            label: 'Importer PNG · $selectedRole',
            icon: Icons.file_upload_outlined,
            secondary: true,
            onPressed:
                widget.controller.operationActive ||
                    widget.controller.hasPendingChanges
                ? null
                : () async {
                    final picked = await widget.pickPng!();
                    if (picked == null) return;
                    await widget.controller.importMenuPng(
                      sourcePath: picked,
                      formId: form,
                      role: selectedRole,
                    );
                  },
          ),
        Text(
          canImport
              ? 'L’import associe un PNG uniquement si ce rôle est libre. '
                    'Un choix existant est conservé.'
              : 'Seule la référence du fichier peut être modifiée ici.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
