import '../../../features/resources/application/resource_image_import_draft.dart';
import '../../../platform/rendering/resource_image_content_verifier.dart';

import 'package:flutter/material.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_image_picker.dart';

export 'package:avelune_studio/features/resources/domain/resource_image_picker.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_panel.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';

class ResourceImportResult extends StatelessWidget {
  const ResourceImportResult({
    super.key,
    required this.source,
    required this.onCreateDecor,
    required this.onPrepareTerrain,
    required this.onDismiss,
    this.canCreateDecor = true,
  });
  final ResourceItem source;
  final bool canCreateDecor;
  final VoidCallback onCreateDecor, onPrepareTerrain, onDismiss;

  @override
  Widget build(BuildContext context) => StudioPanel(
    key: const ValueKey('resource-import-result'),
    compact: true,
    icon: Icons.check_circle_outline,
    title: '« ${source.name} » est importée',
    children: [
      const Text(
        'C’est une image source : elle n’est placée sur aucune carte et '
        'n’apparaît pas dans la palette. Choisissez ce que vous voulez en faire.',
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (canCreateDecor)
            const StudioNotice(
              'La préparation des décors est temporairement indisponible. Cette image source est conservée.',
              key: ValueKey('resource-import-decor-unavailable'),
            ),
          StudioButton(
            key: const ValueKey('resource-import-create-terrain'),
            label: 'Préparer un terrain',
            icon: Icons.grid_on,
            secondary: true,
            onPressed: onPrepareTerrain,
          ),
          StudioButton(
            key: const ValueKey('resource-import-dismiss'),
            label: 'Plus tard',
            secondary: true,
            onPressed: onDismiss,
          ),
        ],
      ),
    ],
  );
}

class _PreflightLine extends StatelessWidget {
  const _PreflightLine(
    this.text, {
    this.warning = false,
    this.pending = false,
    super.key,
  });
  final String text;
  final bool warning, pending;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            pending
                ? Icons.hourglass_empty
                : warning
                ? Icons.warning_amber_outlined
                : Icons.check_circle_outline,
            size: 18,
            color: pending
                ? colors.onSurfaceVariant
                : warning
                ? colors.tertiary
                : colors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

Future<ResourceImageImport?> confirmImageImport(
  BuildContext context,
  PickedResourceImage image,
  int tileWidth,
  int tileHeight, {
  Set<String> existingNames = const {},
  ResourceImportIntent intent = ResourceImportIntent.source,
}) async {
  final takenNames = {
    for (final value in existingNames) value.trim().toLowerCase(),
  };
  return showDialog<ResourceImageImport>(
    context: context,
    builder: (context) => _ImageImportDialog(
      image: image,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      takenNames: takenNames,
      intent: intent,
    ),
  );
}

class _ImageImportDialog extends StatefulWidget {
  const _ImageImportDialog({
    required this.image,
    required this.tileWidth,
    required this.tileHeight,
    required this.takenNames,
    required this.intent,
  });
  final PickedResourceImage image;
  final int tileWidth, tileHeight;
  final Set<String> takenNames;
  final ResourceImportIntent intent;

  @override
  State<_ImageImportDialog> createState() => _ImageImportDialogState();
}

class _ImageImportDialogState extends State<_ImageImportDialog> {
  late final name = TextEditingController(text: widget.image.name);
  late final width = TextEditingController(text: '${widget.tileWidth}');
  late final height = TextEditingController(text: '${widget.tileHeight}');
  late final _draft = ResourceImageImportDraft(
    image: widget.image,
    tileWidth: widget.tileWidth,
    tileHeight: widget.tileHeight,
    existingNames: widget.takenNames,
  );

  @override
  void initState() {
    super.initState();
    _verifyContent();
  }

  Future<void> _verifyContent() async {
    await _draft.verify(verifyResourceImageContent);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _draft.dispose();
    name.dispose();
    width.dispose();
    height.dispose();
    super.dispose();
  }

  void rebuild(VoidCallback update) => setState(update);

  @override
  Widget build(BuildContext context) {
    final image = widget.image;
    final intent = widget.intent;
    final w = _draft.cellWidth;
    final h = _draft.cellHeight;
    final nameTaken = _draft.nameTaken;
    final restWidth = _draft.restWidth;
    final restHeight = _draft.restHeight;
    final valid = _draft.valid;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Importer une image',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 210,
                width: double.infinity,
                child: Image.memory(
                  image.bytes,
                  cacheWidth: 600,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                  errorBuilder: (_, _, _) => const StudioNotice(
                    'Cette image PNG ne peut pas être prévisualisée.',
                    isError: true,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                key: const ValueKey('resource-import-preflight'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Vérification avant import',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    switch (_draft.decoded) {
                      null => const _PreflightLine(
                        'Vérification du contenu PNG…',
                        pending: true,
                        key: ValueKey('resource-import-decoding'),
                      ),
                      true => const _PreflightLine(
                        'Contenu PNG vérifié',
                        key: ValueKey('resource-import-decoded'),
                      ),
                      false => const _PreflightLine(
                        'Ce PNG est incomplet ou illisible : il ne peut pas '
                        'être importé. Le fichier choisi n’est pas modifié.',
                        warning: true,
                        key: ValueKey('resource-import-unreadable'),
                      ),
                    },
                    _PreflightLine(
                      '${image.width} × ${image.height} px · copie sans redimensionnement',
                    ),
                    if (w > 0 && h > 0)
                      _PreflightLine(
                        '${image.width ~/ w} × ${image.height ~/ h} cellules de $w × $h px',
                      ),
                    if (restWidth > 0)
                      _PreflightLine(
                        'La largeur (${image.width} px) n’est pas un multiple '
                        'de la cellule ($w px) : il resterait $restWidth px '
                        'hors de la grille. Choisissez une largeur de cellule '
                        'qui la divise exactement.',
                        warning: true,
                        key: const ValueKey('resource-import-uneven-width'),
                      ),
                    if (restHeight > 0)
                      _PreflightLine(
                        'La hauteur (${image.height} px) n’est pas un multiple '
                        'de la cellule ($h px) : il resterait $restHeight px '
                        'hors de la grille. Choisissez une hauteur de cellule '
                        'qui la divise exactement.',
                        warning: true,
                        key: const ValueKey('resource-import-uneven-height'),
                      ),
                    if (nameTaken)
                      const _PreflightLine(
                        'Une image porte déjà ce nom. Une ressource distincte '
                        'sera créée ; l’existante n’est pas remplacée.',
                        warning: true,
                        key: ValueKey('resource-import-name-taken'),
                      ),
                    _PreflightLine(switch (intent) {
                      ResourceImportIntent.source =>
                        'Résultat : une image source, placée sur aucune carte. '
                            'Vous choisirez ensuite d’en faire un décor ou un terrain.',
                      ResourceImportIntent.decor =>
                        'Résultat : une image source, puis l’atelier de décor '
                            's’ouvre pour la découper.',
                      ResourceImportIntent.terrain =>
                        'Résultat : une image source, puis l’atelier terrain '
                            's’ouvre pour définir ses raccords.',
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('resource-import-name'),
                controller: name,
                decoration: const InputDecoration(labelText: 'Nom'),
                onChanged: (value) => rebuild(() => _draft.name = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('resource-import-cell-width'),
                      controller: width,
                      decoration: const InputDecoration(
                        labelText: 'Largeur de cellule (px)',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => rebuild(() => _draft.width = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      key: const ValueKey('resource-import-cell-height'),
                      controller: height,
                      decoration: const InputDecoration(
                        labelText: 'Hauteur de cellule (px)',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) =>
                          rebuild(() => _draft.height = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const StudioNotice(
                'Une nouvelle ressource sera copiée dans le projet. Aucun fichier existant ne sera remplacé.',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StudioButton(
                    label: 'Annuler',
                    secondary: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                  StudioButton(
                    label: 'Importer',
                    onPressed: valid
                        ? () => Navigator.pop(context, _draft.build())
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
