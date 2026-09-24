import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'pokemon_draft_controls.dart';

class PokemonSpeciesMediaEditor extends StatelessWidget {
  const PokemonSpeciesMediaEditor({
    super.key,
    required this.controller,
    this.pickPng,
  });

  final PokemonWorkspaceController controller;
  final Future<String?> Function()? pickPng;

  @override
  Widget build(BuildContext context) {
    final json = controller.selectedDraft?.document(
      PokemonDocumentFamily.media,
    );
    final draft = controller.selectedDraft;
    final references =
        (draft?.document(PokemonDocumentFamily.species)?['refs'] as Map?)
            ?.cast<String, dynamic>();
    if (references?['media'] == null || references?['media'] == '') {
      return const StudioPanel(
        children: [Text('Aucune référence média associée à cette espèce.')],
      );
    }
    final fields = PokemonDraftControls(
      controller,
      PokemonDocumentFamily.media,
    );
    final variants = (json?['variants'] as Map?)?.cast<String, dynamic>() ?? {};
    final forms =
        controller.index?.entries
            .where((entry) => entry.id == draft?.id)
            .firstOrNull
            ?.formIds ??
        const <String>[];
    return Column(
      children: [
        if (json != null)
          StudioPanel(
            title: 'Forme par défaut',
            children: [
              fields.text('Identifiant de la forme', ['defaultFormId']),
            ],
          )
        else
          const StudioPanel(
            children: [
              Text('Aucun document média. Un import PNG peut le créer.'),
            ],
          ),
        const SizedBox(height: 12),
        for (final form in {...forms, ...variants.keys}) ...[
          StudioPanel(
            title: 'Variante $form',
            children: [
              for (final role in const [
                'icon',
                'party',
                'portrait',
                'frontStatic',
                'backStatic',
                'frontShinyStatic',
                'backShinyStatic',
                'overworld',
                'cry',
              ]) ...[
                if (json != null) fields.text(role, ['variants', form, role]),
                if (role != 'cry' &&
                    ((variants[form] as Map?)?[role] as String?)?.isNotEmpty ==
                        true)
                  _MediaPreview(
                    path: (variants[form] as Map)[role] as String,
                    controller: controller,
                  ),
                if (pickPng != null &&
                    const {'icon', 'party', 'portrait'}.contains(role))
                  StudioButton(
                    label: 'Importer PNG · $role',
                    secondary: true,
                    onPressed:
                        controller.operationActive ||
                            controller.hasPendingChanges
                        ? null
                        : () async {
                            final path = await pickPng!();
                            if (path == null) return;
                            await controller.importMenuPng(
                              sourcePath: path,
                              formId: form,
                              role: role,
                            );
                          },
                  ),
              ],
              if ((variants[form] as Map?)?['animations']
                  case final Map animations)
                for (final animation in animations.entries) ...[
                  Text('Animation ${animation.key}'),
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
                  if ((animation.value as Map?)?['sheet']
                      case final String sheet)
                    if (sheet.isNotEmpty)
                      _MediaPreview(path: sheet, controller: controller),
                ],
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (forms.isEmpty && variants.isEmpty)
          const StudioPanel(
            children: [Text('Aucune forme disponible pour les médias.')],
          ),
        const Text(
          'Un import PNG conserve un média déjà choisi. Il ne le remplace pas.',
        ),
      ],
    );
  }
}

class _MediaPreview extends StatefulWidget {
  const _MediaPreview({required this.path, required this.controller});

  final String path;
  final PokemonWorkspaceController controller;

  @override
  State<_MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<_MediaPreview> {
  late Future<Uint8List?> image;

  @override
  void initState() {
    super.initState();
    image = widget.controller.port.loadImage(widget.path);
  }

  @override
  void didUpdateWidget(covariant _MediaPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path ||
        oldWidget.controller.port != widget.controller.port) {
      image = widget.controller.port.loadImage(widget.path);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: image,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const SizedBox(
          height: 48,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final bytes = snapshot.data;
      if (bytes == null) {
        return Text('Fichier absent ou illisible : ${widget.path}');
      }
      return Image.memory(bytes, width: 96, height: 96, fit: BoxFit.contain);
    },
  );
}
