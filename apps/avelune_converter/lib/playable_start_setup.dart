import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

typedef ConverterPlayableStartApply = Future<void> Function({
  required String mapId,
  required String spawnId,
  required List<String> starterSpeciesIds,
  required int starterLevel,
});

class ConverterPlayableStartSetup extends StatefulWidget {
  const ConverterPlayableStartSetup({
    super.key,
    required this.inspection,
    required this.onApply,
  });

  final ConverterPlayableStartInspection inspection;
  final ConverterPlayableStartApply onApply;

  @override
  State<ConverterPlayableStartSetup> createState() =>
      _ConverterPlayableStartSetupState();
}

class _ConverterPlayableStartSetupState
    extends State<ConverterPlayableStartSetup> {
  final _mapSearch = TextEditingController();
  final _speciesSearch = TextEditingController();
  final _starters = <String>{};
  String? _mapId;
  String? _spawnId;
  String _level = '5';
  String? _error;
  bool _busy = false;
  bool _applied = false;
  int _generation = 0;

  ConverterPlayableStartMap? get _map =>
      widget.inspection.maps.where((value) => value.id == _mapId).firstOrNull;

  bool get _locked =>
      _busy ||
      _applied ||
      widget.inspection.configured ||
      widget.inspection.existingNewGame;

  bool get _valid =>
      !_locked &&
      widget.inspection.avatars.length == 1 &&
      _map != null &&
      _map!.spawns.any((value) => value.id == _spawnId) &&
      _starters.length >= 2 &&
      _starters.length <= 6 &&
      _starters.every(
        (id) => widget.inspection.species.any((value) => value.id == id),
      ) &&
      int.tryParse(_level) != null &&
      int.parse(_level) >= 1 &&
      int.parse(_level) <= 100;

  @override
  void didUpdateWidget(ConverterPlayableStartSetup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.inspection.revision == widget.inspection.revision) return;
    _generation++;
    _mapId = null;
    _spawnId = null;
    _starters.clear();
    _busy = false;
    _applied = false;
    _error = null;
  }

  @override
  void dispose() {
    _generation++;
    _mapSearch.dispose();
    _speciesSearch.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    if (!_valid) return;
    final generation = _generation;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onApply(
        mapId: _mapId!,
        spawnId: _spawnId!,
        starterSpeciesIds: List.unmodifiable(_starters),
        starterLevel: int.parse(_level),
      );
      if (!mounted || generation != _generation) return;
      setState(() => _applied = true);
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(
        () => _error = 'Le départ adapté n’a pas pu être appliqué. Vérifiez le projet puis réessayez.',
      );
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.inspection.existingNewGame) {
      return const StudioPanel(
        title: 'Démarrage du projet',
        children: [
          StudioNotice('Un démarrage est déjà déclaré dans ce projet.'),
          SizedBox(height: 12),
          Text(
            'Ouvrez le projet dans Avelune Studio pour modifier son démarrage ou lancer une nouvelle partie.',
          ),
        ],
      );
    }
    final mapQuery = _mapSearch.text.trim().toLowerCase();
    final speciesQuery = _speciesSearch.text.trim().toLowerCase();
    final maps = widget.inspection.maps.where(
      (value) =>
          value.id == _mapId || value.name.toLowerCase().contains(mapQuery),
    );
    final species = widget.inspection.species
        .where((value) => value.name.toLowerCase().contains(speciesQuery))
        .toList();
    final level = int.tryParse(_level);
    return StudioPanel(
      title: 'Configurer un départ jouable adapté',
      children: [
        const StudioNotice(
          'Départ Avelune adapté, ne reproduit pas l’introduction source',
        ),
        const SizedBox(height: 12),
        const Text(
          'Choisissez un lieu de départ et les starters proposés au joueur dans le parcours Avelune.',
        ),
        const SizedBox(height: 12),
        if (_applied)
          const StudioNotice(
            'Départ adapté appliqué. Le parcours reste à tester dans le Player.',
          )
        else if (widget.inspection.configured)
          const StudioNotice(
            'Un départ adapté est déjà configuré. Le parcours reste à tester dans le Player.',
          )
        else if (widget.inspection.resumable)
          const StudioNotice(
            'Une configuration interrompue peut être reprise. Vérifiez les choix avant de réessayer.',
          ),
        if (widget.inspection.avatars.length == 1)
          Text('Avatar importé : ${widget.inspection.avatars.single.name}')
        else
          const StudioNotice(
            'Un avatar importé unique est nécessaire pour configurer le départ.',
            isError: true,
          ),
        if (widget.inspection.maps.length > 12) ...[
          const SizedBox(height: 12),
          StudioSearchField(
            key: const ValueKey('playable-start-map-search'),
            controller: _mapSearch,
            label: 'Rechercher une carte',
            onChanged: (_) => setState(() {}),
          ),
        ],
        const SizedBox(height: 12),
        StudioSelect(
          key: const ValueKey('playable-start-map'),
          label: 'Carte de départ',
          value: _mapId,
          options: {for (final map in maps) map.id: map.name},
          onChanged: _locked
              ? null
              : (id) => setState(() {
                  _mapId = id;
                  _spawnId = null;
                }),
        ),
        if (widget.inspection.maps.isEmpty)
          const StudioNotice(
            'Aucune carte avec un départ disponible n’a été trouvée.',
            isError: true,
          ),
        const SizedBox(height: 12),
        StudioSelect(
          key: const ValueKey('playable-start-spawn'),
          label: 'Point de départ',
          value: _spawnId,
          options: {
            for (final spawn in _map?.spawns ?? <ConverterPlayableStartSpawn>[])
              spawn.id: spawn.name,
          },
          onChanged: _locked || _map == null
              ? null
              : (id) => setState(() => _spawnId = id),
        ),
        if (_map != null && _map!.spawns.isEmpty)
          const StudioNotice(
            'Cette carte ne possède aucun point de départ disponible.',
            isError: true,
          ),
        const SizedBox(height: 16),
        Text('${_starters.length} starters sélectionnés'),
        if (_starters.isNotEmpty)
          Text(
            widget.inspection.species
                .where((value) => _starters.contains(value.id))
                .map((value) => value.name)
                .join(', '),
          ),
        const Text(
          'Sélectionnez entre deux et six espèces du catalogue natif disponible.',
        ),
        if (widget.inspection.species.length < 2)
          const StudioNotice(
            'Deux espèces natives disponibles au minimum sont nécessaires.',
            isError: true,
          ),
        const SizedBox(height: 12),
        StudioSearchField(
          key: const ValueKey('playable-start-species-search'),
          controller: _speciesSearch,
          label: 'Rechercher une espèce',
          onChanged: (_) => setState(() {}),
        ),
        for (final value in species.take(20))
          StudioToggleRow(
            key: ValueKey('playable-starter-${value.id}'),
            label: value.name,
            value: _starters.contains(value.id),
            onChanged:
                _locked ||
                    (_starters.length == 6 && !_starters.contains(value.id))
                ? null
                : (selected) => setState(() {
                    if (selected) {
                      _starters.add(value.id);
                    } else {
                      _starters.remove(value.id);
                    }
                  }),
          ),
        if (species.isEmpty)
          const Text('Aucune espèce ne correspond à la recherche.'),
        if (species.length > 20)
          Text(
            '${species.length} espèces correspondent. Affinez la recherche pour voir les suivantes.',
          ),
        const SizedBox(height: 12),
        StudioDraftField(
          key: const ValueKey('playable-start-level'),
          value: _level,
          label: 'Niveau des starters',
          enabled: !_locked,
          keyboardType: TextInputType.number,
          errorText: level == null || level < 1 || level > 100
              ? 'Choisissez un niveau entier entre 1 et 100.'
              : null,
          onChanged: (value) => setState(() => _level = value),
        ),
        const SizedBox(height: 12),
        if (_error != null) StudioNotice(_error!, isError: true),
        StudioButton(
          key: const ValueKey('apply-playable-start'),
          label: _busy ? 'Application en cours…' : 'Appliquer le départ adapté',
          onPressed: _valid ? _apply : null,
        ),
      ],
    );
  }
}
