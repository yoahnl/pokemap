import 'package:flutter/cupertino.dart';

import '../../../../ui/design_system/design_system.dart';
import '../../application/smart_tile_grid_detector.dart';

class SmartTileGridStage extends StatelessWidget {
  const SmartTileGridStage({
    super.key,
    required this.proposals,
    required this.selectedProposal,
    required this.geometry,
    required this.controllers,
    required this.onProposalSelected,
    required this.onChanged,
    required this.onConfirm,
    this.atlasPreview,
  });

  final List<SmartTileGridCandidate> proposals;
  final int selectedProposal;
  final SmartTileGridGeometry geometry;
  final Map<String, TextEditingController> controllers;
  final ValueChanged<int> onProposalSelected;
  final void Function(String field, String value) onChanged;
  final VoidCallback? onConfirm;
  final Widget? atlasPreview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PokeMapSectionHeader(
          title: 'Confirmer la grille',
          description:
              '${geometry.columns} × ${geometry.rows} cellules proposées. Rien n’est appliqué avant confirmation.',
          trailing: PokeMapBadge(
            label: geometry.isWithinImage
                ? 'Dans les limites de l’image'
                : 'Cellules hors image',
            variant: geometry.isWithinImage
                ? PokeMapBadgeVariant.success
                : PokeMapBadgeVariant.error,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              for (var index = 0; index < proposals.length; index++)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: PokeMapButton(
                    key: Key('smart-tiles-grid-proposal-$index'),
                    onPressed: () => onProposalSelected(index),
                    variant: PokeMapButtonVariant.ghost,
                    size: PokeMapButtonSize.small,
                    isSelected: selectedProposal == index,
                    child: Text(
                      '${proposals[index].geometry.cellWidth} × '
                      '${proposals[index].geometry.cellHeight} px • '
                      '${(proposals[index].confidence * 100).round()} %',
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (proposals.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(proposals[selectedProposal].reason),
        ],
        if (atlasPreview != null) ...[
          const SizedBox(height: 12),
          atlasPreview!,
        ],
        const SizedBox(height: 14),
        _SmartTileGridFields(
          controllers: controllers,
          onChanged: onChanged,
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: PokeMapButton(
            key: const Key('smart-tiles-confirm-grid'),
            onPressed: onConfirm,
            trailing: const Icon(CupertinoIcons.chevron_right, size: 14),
            child: const Text('Confirmer et continuer'),
          ),
        ),
      ],
    );
  }
}

class _SmartTileGridFields extends StatelessWidget {
  const _SmartTileGridFields({
    required this.controllers,
    required this.onChanged,
  });

  final Map<String, TextEditingController> controllers;
  final void Function(String field, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    const fields = <({String id, String label, String keySuffix})>[
      (id: 'cellWidth', label: 'Largeur cellule', keySuffix: 'cell-width'),
      (id: 'cellHeight', label: 'Hauteur cellule', keySuffix: 'cell-height'),
      (id: 'columns', label: 'Colonnes', keySuffix: 'columns'),
      (id: 'rows', label: 'Lignes', keySuffix: 'rows'),
      (id: 'originX', label: 'Origine X', keySuffix: 'origin-x'),
      (id: 'originY', label: 'Origine Y', keySuffix: 'origin-y'),
      (id: 'marginX', label: 'Marge X', keySuffix: 'margin-x'),
      (id: 'marginY', label: 'Marge Y', keySuffix: 'margin-y'),
      (id: 'spacingX', label: 'Espacement X', keySuffix: 'spacing-x'),
      (id: 'spacingY', label: 'Espacement Y', keySuffix: 'spacing-y'),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        for (final field in fields)
          SizedBox(
            width: 160,
            child: PokeMapTextField(
              label: field.label,
              controller: controllers[field.id],
              fieldKey: Key('smart-tiles-${field.keySuffix}'),
              keyboardType: TextInputType.number,
              onChanged: (value) => onChanged(field.id, value),
            ),
          ),
      ],
    );
  }
}
