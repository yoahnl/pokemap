import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../workspace/project_snapshot.dart';
import '../domains/narrative/dialogue_authoring_service.dart';
import '../domains/assets/project_media_store.dart';

final class ResourceUsageDocument {
  const ResourceUsageDocument(
      this.kind, this.id, this.label, this.origin, this.value);

  final String kind;
  final String id;
  final String label;
  final String origin;
  final Map<String, dynamic> value;
  String get identity => '$kind:$id';
}

List<ResourceUsageDocument> resourceUsageDocuments(
  ProjectSnapshot snapshot,
  List<String> issues,
) {
  final result = <ResourceUsageDocument>[];
  final project = Map<String, dynamic>.from(snapshot.manifest.toJson());
  const sections = {
    'tilesets': 'tileset',
    'elements': 'element',
    'characters': 'character',
    'scenes': 'scene',
    'presentationCinematics': 'presentationCinematic',
    'cinematicMediaAssets': 'cinematicMedia',
    'cinematics': 'cinematic',
    'scripts': 'script',
    'dialogues': 'dialogue',
    'presentationPresets': 'presentationPreset',
    'environmentPresets': 'environmentPreset',
  };
  void add(String kind, Object? entries, String origin) {
    if (entries is! List) return;
    for (var i = 0; i < entries.length; i++) {
      final raw = entries[i];
      if (raw is! Map) continue;
      final value = Map<String, dynamic>.from(raw);
      final id = '${value['id'] ?? value['targetPresetId'] ?? i}';
      final draft = value['draft'];
      final definition = draft is Map ? draft['definition'] : null;
      final nestedName = definition is Map ? definition['name'] : null;
      result.add(ResourceUsageDocument(
          kind,
          id,
          '${value['name'] ?? value['title'] ?? value['label'] ?? nestedName ?? id}',
          '$origin[$i]',
          value));
    }
  }

  for (final section in sections.entries) {
    add(section.value, project.remove(section.key), section.key);
  }
  final smart = project.remove('smartTileCatalog');
  if (smart is Map) {
    const smartSections = {
      'presets': 'preset',
      'drafts': 'smartTileDraft',
      'materials': 'smartTileMaterial',
      'assets': 'smartTileAsset',
      'atlases': 'smartTileAtlas',
      'animations': 'smartTileAnimation',
      'patterns': 'smartTilePattern',
    };
    final remainder = Map<String, dynamic>.from(smart);
    for (final section in smartSections.entries) {
      add(section.value, remainder.remove(section.key),
          'smartTileCatalog.${section.key}');
    }
    result.add(ResourceUsageDocument('smartTileCatalog', 'catalog', 'Terrains',
        'smartTileCatalog', remainder));
  }
  final border = project.remove('borderCatalog');
  if (border is Map) {
    add('border', border['records'], 'borderCatalog.records');
    add('borderSnapshot', border['visualSnapshots'],
        'borderCatalog.visualSnapshots');
  }
  result.add(ResourceUsageDocument(
      'project', 'project', snapshot.manifest.name, 'project', project));
  for (final map in snapshot.maps) {
    result.add(ResourceUsageDocument(
        'map', map.id, map.name, 'map:${map.id}', map.toJson()));
  }
  if (snapshot.maps.length != snapshot.manifest.maps.length) {
    issues.add('resource.usages.maps_incomplete');
  }
  if (snapshot.manifest.pokemon.enabled && !snapshot.pokemonInventoryComplete) {
    issues.add('asset.inventory_unavailable');
  }
  for (final identity in snapshot.resourceFingerprints.keys) {
    if (!identity.startsWith('pokemonMedia:') &&
        !identity.startsWith('dialogueSource:') &&
        identity != 'projectMediaCatalog') {
      continue;
    }
    try {
      if (identity.startsWith('dialogueSource:')) {
        final id = identity.substring('dialogueSource:'.length);
        final entry = snapshot.manifest.dialogues
            .where((entry) => entry.id == id)
            .firstOrNull;
        if (entry == null) throw const FormatException('Owner unavailable.');
        final compiled = const DialogueAuthoringCompiler().compile(
            entry: entry,
            source: utf8.decode(snapshot.resourceBytes(identity)));
        if (!compiled.canPublish) {
          issues.add('resource.usages.dialogue_invalid:$id');
        }
        if (compiled.document != null) {
          result.add(ResourceUsageDocument('dialogueSource', id, entry.name,
              entry.relativePath, compiled.document!.toJson()));
        }
        continue;
      }
      final raw = jsonDecode(utf8.decode(snapshot.resourceBytes(identity)));
      if (raw is! Map) throw const FormatException('Document expected.');
      final json = Map<String, dynamic>.from(raw);
      if (identity == projectMediaCatalogResourceIdentity) {
        decodeProjectMediaCatalogBytes(snapshot.resourceBytes(identity));
        add('media', json['entries'], projectMediaCatalogStorageKey);
        continue;
      }
      if (identity.startsWith('pokemonMedia:')) {
        final document = PokemonMediaFile.fromJson(json);
        if (document.speciesId.isEmpty ||
            document.defaultFormId.isEmpty ||
            json['variants'] is! Map) {
          throw const FormatException('Incomplete Pokemon media document.');
        }
      }
      final split = identity.indexOf(':');
      final kind = split < 0 ? identity : identity.substring(0, split);
      final id = split < 0 ? identity : identity.substring(split + 1);
      result.add(ResourceUsageDocument(kind, id, '$kind · $id',
          snapshot.resourceStorageKeys[identity] ?? identity, json));
    } on Object {
      issues.add('resource.usages.document_invalid:$identity');
    }
  }
  issues.addAll(snapshot.loadDiagnostics.map(
      (entry) => '${entry.code}:${entry.resourceKind}:${entry.resourceId}'));
  return result;
}
