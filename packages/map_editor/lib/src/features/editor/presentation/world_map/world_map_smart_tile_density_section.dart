import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../../ui/design_system/design_system.dart';
import '../../application/smart_tile_variant_density.dart';

/// Ce que le réglage de densité écrit : la surcharge du calque actif, ou les
/// poids par défaut du preset — donc tous les calques qui le suivent.
enum SmartTileDensityScope { layer, preset }

/// Réglage de la fréquence de chaque variante d'une règle Smart Tile.
///
/// Repliée par défaut : le panneau de peinture garde sa longueur, et la ligne
/// de résumé suffit à voir qu'un réglage s'écarte du preset. Le widget ne
/// touche à rien — il rend une table de poids et sa portée à [onApply] et
/// attend.
class WorldMapSmartTileDensitySection extends StatefulWidget {
  const WorldMapSmartTileDensitySection({
    super.key,
    required this.rule,
    required this.layerWeights,
    required this.spriteBuilder,
    required this.onApply,
    this.isEditable = true,
  });

  final SmartTileRule rule;

  /// Surcharge portée par le calque actif, par identifiant de candidat. Une
  /// entrée absente suit le poids du preset — que [rule] porte déjà sur ses
  /// candidats.
  final Map<String, int> layerWeights;

  final Widget Function(SmartTileCandidate candidate) spriteBuilder;
  final Future<void> Function(
    SmartTileDensityScope scope,
    Map<String, int> weights,
  ) onApply;
  final bool isEditable;

  @override
  State<WorldMapSmartTileDensitySection> createState() =>
      _WorldMapSmartTileDensitySectionState();
}

class _WorldMapSmartTileDensitySectionState
    extends State<WorldMapSmartTileDensitySection> {
  var _scope = SmartTileDensityScope.layer;
  late Map<String, int> _opening;
  late Map<String, int> _current;
  var _expanded = false;
  var _applying = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(WorldMapSmartTileDensitySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rule.id == widget.rule.id &&
        mapEquals(oldWidget.layerWeights, widget.layerWeights)) {
      return;
    }
    _reload();
  }

  void _reload() {
    _opening = _openingFor(_scope);
    _current = Map<String, int>.of(_opening);
  }

  /// Poids d'ouverture pour une portée : la table du calque complétée par les
  /// défauts du preset, ou les défauts seuls.
  Map<String, int> _openingFor(SmartTileDensityScope scope) {
    return normaliseSmartTileVariantWeights(<String, int>{
      for (final candidate in widget.rule.candidates)
        candidate.id: scope == SmartTileDensityScope.layer
            ? widget.layerWeights[candidate.id] ?? candidate.weight
            : candidate.weight,
    });
  }

  void _selectScope(SmartTileDensityScope scope) {
    if (scope == _scope) return;
    setState(() {
      _scope = scope;
      _reload();
    });
  }

  bool get _dirty => !mapEquals(_current, _opening);

  String _label(int permille) => permille == 0
      ? 'jamais'
      : '${(permille / 10).toStringAsFixed(1).replaceAll('.', ',')} %';

  Future<void> _apply() async {
    setState(() => _applying = true);
    try {
      await widget.onApply(_scope, Map<String, int>.of(_current));
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
    final defaults = _openingFor(SmartTileDensityScope.preset);
    final layerOpening = _openingFor(SmartTileDensityScope.layer);
    final changed = layerOpening.entries
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
          Row(
            children: <Widget>[
              Expanded(
                child: PokeMapButton(
                  key: const Key('world-map-density-scope-layer'),
                  onPressed: () => _selectScope(SmartTileDensityScope.layer),
                  variant: _scope == SmartTileDensityScope.layer
                      ? PokeMapButtonVariant.primary
                      : PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.compact,
                  child: const Text('Ce calque'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: PokeMapButton(
                  key: const Key('world-map-density-scope-preset'),
                  onPressed: () => _selectScope(SmartTileDensityScope.preset),
                  variant: _scope == SmartTileDensityScope.preset
                      ? PokeMapButtonVariant.primary
                      : PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.compact,
                  child: const Text('Tous les calques'),
                ),
              ),
            ],
          ),
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
