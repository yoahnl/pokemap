import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_embedded_widgets.dart';

const _kSpawnNone = '__spawn_none__';

class MapPropertiesPanel extends ConsumerStatefulWidget {
  const MapPropertiesPanel({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<MapPropertiesPanel> createState() => _MapPropertiesPanelState();
}

class _MapPropertiesPanelState extends ConsumerState<MapPropertiesPanel> {
  final _displayNameController = TextEditingController();
  final _musicIdController = TextEditingController();
  final _tagsController = TextEditingController();

  String? _boundFingerprint;
  MapType _mapType = MapType.route;
  MapWeather _weather = MapWeather.none;
  bool _isIndoor = false;
  bool _allowEscapeRope = true;
  String _defaultSpawnMenuValue = _kSpawnNone;

  @override
  void dispose() {
    _displayNameController.dispose();
    _musicIdController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final map = state.activeMap;
    _syncFromMap(map);

    const accent = EditorChrome.inspectorJoyPlum;
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final labelColor = CupertinoColors.label.resolveFrom(context);

    if (map == null) {
      return Center(
        child: Text(
          'Aucune carte chargée',
          style: TextStyle(
            color: CupertinoColors.placeholderText.resolveFrom(context),
          ),
        ),
      );
    }

    final mapTypeIds =
        MapType.values.map((e) => e.name).toList(growable: false);
    final weatherIds =
        MapWeather.values.map((e) => e.name).toList(growable: false);

    final spawnEntries = _spawnMenuEntries(map);
    final spawnKeys = spawnEntries.keys.toList(growable: false);
    final curSpawn = _defaultSpawnMenuValue;
    final spawnOrdered = <String>[
      _kSpawnNone,
      if (curSpawn != _kSpawnNone && !spawnKeys.contains(curSpawn)) curSpawn,
      ...spawnKeys,
    ];

    return ListView(
      padding: widget.embedded
          ? kInspectorTileBodyPadding
          : const EdgeInsets.fromLTRB(8, 8, 8, 8),
      children: [
        Text(
          'Nom affiché',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: subtle,
          ),
        ),
        const SizedBox(height: 4),
        CupertinoTextField(
          controller: _displayNameController,
          placeholder: 'Optionnel',
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        const SizedBox(height: 10),
        InspectorEmbeddedDropdown(
          accent: accent,
          fieldLabel: 'Type de carte',
          valueLabel: _mapTypeLabel(_mapType),
          orderedIds: mapTypeIds,
          selectedMenuValue: _mapType.name,
          idToLabel: (id) => _mapTypeLabel(
            MapType.values.firstWhere((e) => e.name == id),
          ),
          onSelected: (id) => setState(() {
            _mapType = MapType.values.firstWhere((e) => e.name == id);
          }),
        ),
        const SizedBox(height: 10),
        Text(
          'Musique (identifiant)',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: subtle,
          ),
        ),
        const SizedBox(height: 4),
        CupertinoTextField(
          controller: _musicIdController,
          placeholder: 'Optionnel',
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        const SizedBox(height: 10),
        InspectorEmbeddedDropdown(
          accent: accent,
          fieldLabel: 'Météo',
          valueLabel: _weatherLabel(_weather),
          orderedIds: weatherIds,
          selectedMenuValue: _weather.name,
          idToLabel: (id) => _weatherLabel(
            MapWeather.values.firstWhere((e) => e.name == id),
          ),
          onSelected: (id) => setState(() {
            _weather = MapWeather.values.firstWhere((e) => e.name == id);
          }),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                'Intérieur',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
            ),
            MacosSwitch(
              value: _isIndoor,
              onChanged: (v) => setState(() => _isIndoor = v),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                'Corde sortie autorisée',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
            ),
            MacosSwitch(
              value: _allowEscapeRope,
              onChanged: (v) => setState(() => _allowEscapeRope = v),
            ),
          ],
        ),
        const SizedBox(height: 10),
        InspectorEmbeddedDropdown(
          accent: accent,
          fieldLabel: 'Point de spawn par défaut',
          valueLabel: _spawnValueLabel(
            spawnEntries,
            _defaultSpawnMenuValue,
          ),
          orderedIds: spawnOrdered,
          selectedMenuValue: spawnOrdered.contains(_defaultSpawnMenuValue)
              ? _defaultSpawnMenuValue
              : _kSpawnNone,
          idToLabel: (id) => _spawnValueLabel(spawnEntries, id),
          onSelected: (id) => setState(() => _defaultSpawnMenuValue = id),
        ),
        if (spawnEntries.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Ajoutez une entité « spawn » sur la carte pour choisir un défaut.',
              style: TextStyle(fontSize: 11, color: subtle, height: 1.25),
            ),
          ),
        const SizedBox(height: 10),
        Text(
          'Tags (séparés par des virgules)',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: subtle,
          ),
        ),
        const SizedBox(height: 4),
        CupertinoTextField(
          controller: _tagsController,
          placeholder: 'ex. shop, story_act2',
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        const SizedBox(height: 12),
        CupertinoButton.filled(
          onPressed: () => _save(notifier),
          child: const Text('Enregistrer les propriétés'),
        ),
      ],
    );
  }

  void _syncFromMap(MapData? map) {
    if (map == null) {
      return;
    }
    final fp = jsonEncode(map.mapMetadata.toJson());
    if (_boundFingerprint == fp) {
      return;
    }
    _boundFingerprint = fp;
    final md = map.mapMetadata;
    _displayNameController.text = md.displayName;
    _musicIdController.text = md.musicId ?? '';
    _tagsController.text = md.tags.join(', ');
    _mapType = md.mapType;
    _weather = md.weather;
    _isIndoor = md.isIndoor;
    _allowEscapeRope = md.allowEscapeRope;
    final cur = md.defaultSpawnId?.trim();
    if (cur == null || cur.isEmpty) {
      _defaultSpawnMenuValue = _kSpawnNone;
    } else {
      _defaultSpawnMenuValue = cur;
    }
  }

  Map<String, String> _spawnMenuEntries(MapData map) {
    final out = <String, String>{};
    for (final e in map.entities) {
      if (e.kind != MapEntityKind.spawn) continue;
      final key = e.spawn?.spawnKey.trim() ?? '';
      final value = key.isNotEmpty ? key : e.id;
      final head = key.isNotEmpty ? key : e.id;
      out.putIfAbsent(
        value,
        () => '$head · (${e.pos.x}, ${e.pos.y})',
      );
    }
    return out;
  }

  String _spawnValueLabel(
    Map<String, String> entries,
    String menuId,
  ) {
    if (menuId == _kSpawnNone) {
      return 'Aucun';
    }
    return entries[menuId] ?? menuId;
  }

  void _save(EditorNotifier notifier) {
    final tagsRaw = _tagsController.text.split(',');
    final tags = tagsRaw
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList(growable: false);
    final music = _musicIdController.text.trim();
    final metadata = MapMetadata(
      displayName: _displayNameController.text,
      mapType: _mapType,
      musicId: music.isEmpty ? null : music,
      weather: _weather,
      isIndoor: _isIndoor,
      allowEscapeRope: _allowEscapeRope,
      defaultSpawnId: _defaultSpawnMenuValue == _kSpawnNone
          ? null
          : _defaultSpawnMenuValue,
      tags: tags,
    );
    notifier.updateMapMetadata(metadata);
  }
}

String _mapTypeLabel(MapType t) {
  return switch (t) {
    MapType.route => 'Route',
    MapType.city => 'Ville',
    MapType.building => 'Bâtiment',
    MapType.interior => 'Intérieur',
    MapType.cave => 'Grotte',
    MapType.forest => 'Forêt',
    MapType.facility => 'Installation',
    MapType.special => 'Spécial',
    MapType.custom => 'Personnalisé',
  };
}

String _weatherLabel(MapWeather w) {
  return switch (w) {
    MapWeather.none => 'Aucune',
    MapWeather.rain => 'Pluie',
    MapWeather.storm => 'Orage',
    MapWeather.snow => 'Neige',
    MapWeather.fog => 'Brouillard',
    MapWeather.sandstorm => 'Tempête de sable',
    MapWeather.harshSunlight => 'Soleil brutal',
    MapWeather.custom => 'Personnalisée',
  };
}
