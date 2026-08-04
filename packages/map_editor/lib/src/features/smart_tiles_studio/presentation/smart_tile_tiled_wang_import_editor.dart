import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/smart_tile_tiled_wang_import_service.dart';

class SmartTileTiledWangImportEditor extends StatefulWidget {
  const SmartTileTiledWangImportEditor({
    super.key,
    required this.source,
    required this.onCancel,
    required this.onImport,
    this.isImporting = false,
    this.externalError,
  });

  final SmartTileTiledWangSource source;
  final VoidCallback onCancel;
  final Future<void> Function(List<TiledWangSetSelection> selections) onImport;
  final bool isImporting;
  final String? externalError;

  @override
  State<SmartTileTiledWangImportEditor> createState() =>
      _SmartTileTiledWangImportEditorState();
}

class _SmartTileTiledWangImportEditorState
    extends State<SmartTileTiledWangImportEditor> {
  late final Set<int> _included;
  late final Map<int, String> _usageBySet;

  @override
  void initState() {
    super.initState();
    _included = <int>{
      for (var index = 0;
          index < widget.source.document.wangSets.length;
          index++)
        index,
    };
    _usageBySet = <int, String>{
      for (final index in _included) index: '',
    };
  }

  bool get _canImport =>
      !widget.isImporting &&
      _included.isNotEmpty &&
      _included.every((index) => (_usageBySet[index] ?? '').isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final document = widget.source.document;
    return ListView(
      key: const Key('smart-tiles-tiled-wang-import-editor'),
      padding: const EdgeInsets.all(18),
      children: <Widget>[
        PokeMapSectionHeader(
          title: 'Importer un tileset Tiled',
          description:
              'Le Studio convertit les Wang Sets en Smart Tiles natifs. Tiled ne sera pas requis ensuite.',
          trailing: PokeMapBadge(
            label: '${document.wangSets.length} Wang Set(s)',
            variant: PokeMapBadgeVariant.info,
          ),
        ),
        const SizedBox(height: 14),
        PokeMapCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                document.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.source.displayName,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  PokeMapBadge(
                    label: '${document.tileWidth} × ${document.tileHeight} px',
                    variant: PokeMapBadgeVariant.neutral,
                  ),
                  PokeMapBadge(
                    label: '${document.columns} × ${document.rows} cellules',
                    variant: PokeMapBadgeVariant.neutral,
                  ),
                  PokeMapBadge(
                    label: '${document.tileCount} tuiles',
                    variant: PokeMapBadgeVariant.neutral,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const PokeMapSectionHeader(
          title: 'Wang Sets à convertir',
          description:
              'Choisissez leur rôle dans PokeMap. Chaque sélection deviendra un preset brouillon vérifiable avant publication.',
        ),
        const SizedBox(height: 10),
        for (var index = 0; index < document.wangSets.length; index++) ...[
          _WangSetChoice(
            key: Key('smart-tiles-wang-set-$index'),
            index: index,
            wangSet: document.wangSets[index],
            included: _included.contains(index),
            usage: _usageBySet[index] ?? '',
            enabled: !widget.isImporting,
            onIncludedChanged: (included) {
              setState(() {
                if (included) {
                  _included.add(index);
                  _usageBySet.putIfAbsent(index, () => '');
                } else {
                  _included.remove(index);
                }
              });
            },
            onUsageChanged: (usage) {
              setState(() => _usageBySet[index] = usage);
            },
          ),
          const SizedBox(height: 10),
        ],
        const PokeMapDiagnosticCallout(
          severity: PokeMapDiagnosticSeverity.info,
          title: 'Import non destructif',
          message:
              'Les matériaux, variantes, probabilités et animations sont conservés. Les presets restent en brouillon jusqu’à votre validation.',
        ),
        if (widget.externalError case final error?) ...[
          const SizedBox(height: 10),
          PokeMapDiagnosticCallout(
            key: const Key('smart-tiles-tiled-wang-error'),
            severity: PokeMapDiagnosticSeverity.error,
            title: 'Import impossible',
            message: error,
          ),
        ],
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            PokeMapButton(
              key: const Key('smart-tiles-tiled-wang-cancel'),
              onPressed: widget.isImporting ? null : widget.onCancel,
              variant: PokeMapButtonVariant.ghost,
              child: const Text('Annuler'),
            ),
            const SizedBox(width: 8),
            PokeMapButton(
              key: const Key('smart-tiles-tiled-wang-submit'),
              onPressed: _canImport ? _submit : null,
              disabledReason: _disabledReason(),
              leading: widget.isImporting
                  ? const SizedBox.square(
                      dimension: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(CupertinoIcons.arrow_down_doc, size: 15),
              child: Text(
                widget.isImporting ? 'Import en cours…' : 'Importer',
              ),
            ),
          ],
        ),
      ],
    );
  }

  String? _disabledReason() {
    if (widget.isImporting) return 'Import en cours.';
    if (_included.isEmpty) return 'Sélectionnez au moins un Wang Set.';
    if (_included.any((index) => (_usageBySet[index] ?? '').isEmpty)) {
      return 'Choisissez un usage pour chaque Wang Set sélectionné.';
    }
    return null;
  }

  Future<void> _submit() async {
    final selections = <TiledWangSetSelection>[
      for (final index in _included.toList()..sort())
        TiledWangSetSelection(
          wangSetIndex: index,
          usage: switch (_usageBySet[index]) {
            'terrain' => SmartTileUsage.terrain,
            'path' => SmartTileUsage.path,
            'forest_surface' => SmartTileUsage.forestSurface,
            _ => throw StateError('Usage Wang incomplet'),
          },
        ),
    ];
    await widget.onImport(selections);
  }
}

class _WangSetChoice extends StatelessWidget {
  const _WangSetChoice({
    super.key,
    required this.index,
    required this.wangSet,
    required this.included,
    required this.usage,
    required this.enabled,
    required this.onIncludedChanged,
    required this.onUsageChanged,
  });

  final int index;
  final TiledWangSet wangSet;
  final bool included;
  final String usage;
  final bool enabled;
  final ValueChanged<bool> onIncludedChanged;
  final ValueChanged<String> onUsageChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PokeMapToggleTile(
          label: wangSet.name,
          description: '${_typeLabel(wangSet.type)} • '
              '${wangSet.colors.length} matériau(x) • '
              '${wangSet.tiles.length} forme(s)',
          value: included,
          onChanged: enabled ? onIncludedChanged : (_) {},
        ),
        if (included) ...[
          const SizedBox(height: 8),
          PokeMapDropdownField<String>(
            key: Key('smart-tiles-wang-set-$index-usage'),
            label: 'Usage dans PokeMap',
            value: usage,
            enabled: enabled,
            items: const <PokeMapDropdownItem<String>>[
              PokeMapDropdownItem<String>(
                value: '',
                label: 'Choisir un usage…',
              ),
              PokeMapDropdownItem<String>(
                value: 'terrain',
                label: 'Terrain',
              ),
              PokeMapDropdownItem<String>(
                value: 'path',
                label: 'Chemin',
              ),
              PokeMapDropdownItem<String>(
                value: 'forest_surface',
                label: 'Surface forestière',
              ),
            ],
            onChanged: onUsageChanged,
          ),
        ],
      ],
    );
  }
}

String _typeLabel(TiledWangSetType type) => switch (type) {
      TiledWangSetType.corner => 'Coins Wang',
      TiledWangSetType.edge => 'Bords Wang',
      TiledWangSetType.mixed => 'Bords et coins Wang',
    };
