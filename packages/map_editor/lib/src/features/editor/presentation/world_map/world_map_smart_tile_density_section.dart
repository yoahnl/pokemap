import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../../ui/design_system/design_system.dart';
import '../../application/smart_tile_variant_density.dart';

/// Réglage de la fréquence de chaque variante d'une règle Smart Tile.
///
/// Repliée par défaut : le panneau de peinture garde sa longueur, et la ligne
/// de résumé suffit à voir qu'un réglage s'écarte du preset. Le widget ne
/// touche à rien — il rend une table de poids à [onApply] et attend.
class WorldMapSmartTileDensitySection extends StatefulWidget {
  const WorldMapSmartTileDensitySection({
    super.key,
    required this.rule,
    required this.initialWeights,
    required this.spriteBuilder,
    required this.onApply,
    this.isEditable = true,
  });

  final SmartTileRule rule;

  /// Poids d'ouverture, par identifiant de candidat. Une entrée absente prend
  /// le poids porté par le candidat lui-même.
  final Map<String, int> initialWeights;

  final Widget Function(SmartTileCandidate candidate) spriteBuilder;
  final Future<void> Function(Map<String, int> weights) onApply;
  final bool isEditable;

  @override
  State<WorldMapSmartTileDensitySection> createState() =>
      _WorldMapSmartTileDensitySectionState();
}

class _WorldMapSmartTileDensitySectionState
    extends State<WorldMapSmartTileDensitySection> {
  late Map<String, int> _opening;
  late Map<String, int> _current;
  var _expanded = false;
  var _applying = false;

  @override
  void initState() {
    super.initState();
    _opening = _normalisedOpening();
    _current = Map<String, int>.of(_opening);
  }

  @override
  void didUpdateWidget(WorldMapSmartTileDensitySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rule.id == widget.rule.id &&
        mapEquals(oldWidget.initialWeights, widget.initialWeights)) {
      return;
    }
    _opening = _normalisedOpening();
    _current = Map<String, int>.of(_opening);
  }

  Map<String, int> _normalisedOpening() {
    return normaliseSmartTileVariantWeights(<String, int>{
      for (final candidate in widget.rule.candidates)
        candidate.id: widget.initialWeights[candidate.id] ?? candidate.weight,
    });
  }

  /// Poids par défaut du preset, normalisés — la référence dont un réglage
  /// « s'écarte ».
  Map<String, int> _presetDefaults() {
    return normaliseSmartTileVariantWeights(<String, int>{
      for (final candidate in widget.rule.candidates)
        candidate.id: candidate.weight,
    });
  }

  bool get _dirty => !mapEquals(_current, _opening);

  String _label(int permille) => permille == 0
      ? 'jamais'
      : '${(permille / 10).toStringAsFixed(1).replaceAll('.', ',')} %';

  Future<void> _apply() async {
    setState(() => _applying = true);
    try {
      await widget.onApply(Map<String, int>.of(_current));
      if (mounted) {
        setState(() => _opening = Map<String, int>.of(_current));
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.rule.candidates.length;
    final defaults = _presetDefaults();
    final changed = _opening.entries
        .where((entry) => defaults[entry.key] != entry.value)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 10),
        const PokeMapSectionHeader(
          title: 'Densité des variantes',
          description: 'Ajuste la fréquence de chaque forme possible pour '
              'cette matière.',
        ),
        const SizedBox(height: 8),
        PokeMapButton(
          key: const Key('world-map-density-summary'),
          onPressed: () => setState(() => _expanded = !_expanded),
          variant: PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.compact,
          trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          child: Text(
            changed == 0
                ? '$count variantes'
                : '$count variantes · $changed '
                    'modifiée${changed > 1 ? 's' : ''}',
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          const PokeMapBadge(
            key: Key('world-map-density-reshuffle-notice'),
            variant: PokeMapBadgeVariant.warning,
            label: 'Le premier enregistrement redistribue le tirage : la '
                'surface se remélange, même sans avoir bougé un curseur.',
          ),
          const SizedBox(height: 8),
          for (final candidate in widget.rule.candidates)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: <Widget>[
                  widget.spriteBuilder(candidate),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PokeMapGuidedSlider(
                      key: ValueKey<String>(
                        'world-map-density-${candidate.id}',
                      ),
                      label: _label(_current[candidate.id]!),
                      value: _current[candidate.id]!,
                      max: kSmartTileVariantWeightTotal,
                      onChanged: widget.isEditable
                          ? (next) => setState(() {
                                _current = rescaleSmartTileVariantWeights(
                                  weights: _current,
                                  targetId: candidate.id,
                                  targetPermille: next,
                                );
                              })
                          : (_) {},
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              Expanded(
                child: PokeMapButton(
                  key: const Key('world-map-density-reset'),
                  onPressed: _dirty
                      ? () => setState(
                            () => _current = Map<String, int>.of(_opening),
                          )
                      : null,
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.compact,
                  child: const Text('Réinitialiser'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: PokeMapButton(
                  key: const Key('world-map-density-apply'),
                  onPressed: _applying || !widget.isEditable ? null : _apply,
                  variant: PokeMapButtonVariant.primary,
                  size: PokeMapButtonSize.compact,
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
