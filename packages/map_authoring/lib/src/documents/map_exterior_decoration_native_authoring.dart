part of 'map_exterior_decoration_authoring.dart';

extension MapExteriorDecorationNativeAuthoring
    on LocalMapExteriorDecorationAuthoring {
  Future<String> inspectNativeCatalogRevision(
      {required String projectRoot,
      required String mapId,
      String? mapRelativePath}) async {
    if (runInWorker) {
      return await _runWorker(
          projectRoot: projectRoot,
          mapId: mapId,
          mapRelativePath: mapRelativePath,
          command: 'nativeCatalog') as String;
    }
    final context = await _context(projectRoot, mapId, mapRelativePath);
    return (await _nativeCatalog(context)).revision;
  }

  Future<MapExteriorDecorationMutation> nativeEdit(
      {required String projectRoot,
      required String mapId,
      String? mapRelativePath,
      required String expectedRevision,
      required String expectedCatalogRevision,
      required String operationId,
      required Map<String, Object?> edit}) {
    final kind = edit['kind'];
    if (!const {
      'terrain.paint',
      'environment.generate',
      'border.draw',
      'border.erase'
    }.contains(kind)) {
      throw const FormatException('Unknown native exterior edit kind.');
    }
    final borderErase = kind == 'border.erase';
    final borderEdit = kind == 'border.draw' || borderErase,
        environment = kind == 'environment.generate';
    final args = SemanticParameters(edit, allowed: {
      'kind',
      if (borderErase) ...[
        'borderId',
        'cells'
      ] else if (borderEdit) ...[
        'blueprintId',
        'borderId',
        'points',
        'closed',
        'seed',
        'layerId'
      ] else ...[
        'sectorId',
        'presetId',
        'cells',
        'erase'
      ],
      if (environment) ...['areaId', 'layerId', 'seed'],
      if (kind == 'terrain.paint') 'materialId'
    });
    Future<void> Function()? verify;
    return _mutate(
        projectRoot: projectRoot,
        mapId: mapId,
        mapRelativePath: mapRelativePath,
        expectedRevision: expectedRevision,
        operationId: operationId,
        descriptor: LocalMapExteriorDecorationAuthoring.nativeEditDescriptor,
        parameters: {
          'edit': edit,
          'expectedCatalogRevision': expectedCatalogRevision
        },
        precondition: () async {
          final context = await _context(projectRoot, mapId, mapRelativePath);
          final store = CatalogStorageStore(
              projectRoot: context.root,
              reader: _reader,
              gateway: context.gateway);
          if ('sha256:${(await store.readHead())?.sha256}' !=
              expectedCatalogRevision) {
            throw const FormatException(
                'Exterior native catalog revision conflict.');
          }
          await verify?.call();
        },
        prepare: (context, index) async {
          final definition = index.definition;
          if (definition == null) {
            throw const FormatException(
                'Configure exterior decoration before native editing.');
          }
          final catalog = await _nativeCatalog(context);
          if (catalog.revision != expectedCatalogRevision) {
            throw const FormatException(
                'Exterior native catalog revision conflict.');
          }
          final erasedSource =
              borderErase ? index.borders[args.string('borderId')] : null;
          if (borderErase && erasedSource == null) {
            throw const FormatException('Unknown native exterior Border.');
          }
          final sourceBeforeErase = erasedSource == null
              ? null
              : await _readBorder(context, erasedSource);
          final reference = borderErase
              ? sourceBeforeErase!.feature.blueprintId
              : args.string(borderEdit ? 'blueprintId' : 'presetId');
          final roots = <CatalogDefinitionKey>{
            CatalogDefinitionKey(
                borderEdit
                    ? CatalogDefinitionKind.borderRecord
                    : environment
                        ? CatalogDefinitionKind.environmentPreset
                        : CatalogDefinitionKind.smartTilePreset,
                reference)
          };
          ExteriorDecorationSector? selectedSector;
          ExteriorDecorationBorder? selectedBorder;
          if (!borderEdit) {
            final summary = index.sectors[args.string('sectorId')];
            if (summary == null) {
              throw const FormatException(
                  'Unknown exterior native target sector.');
            }
            selectedSector = await _readSector(context, summary);
            final map = selectedSector.asVisualMap();
            for (final instance in map.spatialScene!.instances) {
              roots.add(CatalogDefinitionKey(
                  CatalogDefinitionKind.model3d, instance.modelId));
            }
            for (final layer in map.layers) {
              switch (layer) {
                case SmartTileLayer():
                  roots.add(CatalogDefinitionKey(
                      CatalogDefinitionKind.smartTilePreset, layer.presetId));
                  for (final id in layer.materialPalette.skip(1)) {
                    roots.add(CatalogDefinitionKey(
                        CatalogDefinitionKind.smartTileMaterial, id));
                  }
                case EnvironmentLayer():
                  for (final area in layer.content.areas) {
                    roots.add(CatalogDefinitionKey(
                        CatalogDefinitionKind.environmentPreset,
                        area.presetId));
                  }
                case BorderLayer():
                  for (final feature in layer.content.features) {
                    roots.add(CatalogDefinitionKey(
                        CatalogDefinitionKind.borderRecord,
                        feature.blueprintId));
                  }
                default:
                  break;
              }
            }
          } else {
            final id = args.string('borderId');
            _safeId(id);
            if (index.borders[id] != null) {
              selectedBorder = await _readBorder(context, index.borders[id]!);
              for (final instance in selectedBorder.instances) {
                roots.add(CatalogDefinitionKey(
                    CatalogDefinitionKind.model3d, instance.modelId));
              }
            } else if (await _readBytes(context, _borderPath(mapId, id),
                    LocalMapExteriorDecorationAuthoring.maximumBorderBytes) !=
                null) {
              throw const FormatException(
                  'An unindexed exterior Border requires explicit recovery.');
            }
          }
          final selection = await catalog.reader.read((source) async {
            final owner = await CatalogMetadataDocuments.readDocuments(
                snapshot: source.snapshot,
                project: source.projectMetadata,
                ids: {
                  'maps': {mapId}
                });
            final entry =
                owner.project.maps.where((v) => v.id == mapId).firstOrNull;
            if (entry == null || entry.relativePath != context.mapPath) {
              throw const FormatException(
                  'The exterior map is not registered at its canonical path.');
            }
            return (await ProjectCatalogSelection(source).resolve(roots))
                .copyWith(maps: [entry]);
          });
          verify = () async {
            if ('sha256:${(await catalog.store.readHead())?.sha256}' !=
                    expectedCatalogRevision ||
                await context.gateway.readResourceRevision('project.json') !=
                    catalog.descriptorRevision) {
              throw const FormatException(
                  'Native exterior dependencies changed before commit.');
            }
          };
          const native = ExteriorDecorationNativeEditing();
          if (borderErase) {
            final before = sourceBeforeErase!;
            final prepared = native.prepareBorderErase(
                decoration: definition,
                manifest: selection,
                before: before,
                logicalPoints: _worldCells(args.list('cells')),
                playableMap: context.map);
            final path = _borderPath(mapId, before.id);
            if (prepared == null) {
              return {
                context.storageKey: _DecorationIndex(definition, index.sectors,
                        borders: {...index.borders}..remove(before.id))
                    .toJson(),
                path: null
              };
            }
            final next = await _resolveBorderDependencies(
                context, index, definition, selection, prepared);
            final json = next.toJson(),
                bytes = _encode(next.toJson(),
                    LocalMapExteriorDecorationAuthoring.maximumBorderBytes);
            final updated =
                _DecorationIndex(definition, index.sectors, borders: {
              ...index.borders,
              next.id: _SectorSummary.fromBorder(next,
                  computeAuthoringBytesFingerprint(bytes, logicalName: path))
            });
            updated.validate();
            return {context.storageKey: updated.toJson(), path: json};
          }
          if (borderEdit) {
            final borderId = args.string('borderId');
            _safeId(borderId);
            final points = _worldCells(args.list('points'));
            if (points.length < 2) {
              throw const FormatException(
                  'A native Border requires a complete contour.');
            }
            final border = native.prepareBorder(
                decoration: definition,
                manifest: selection,
                id: borderId,
                blueprintId: reference,
                logicalPoints: points,
                seed: BorderSignedInt64.parse(args.string('seed')),
                before: selectedBorder,
                layerId: args.optionalString('layerId'),
                closed:
                    args.contains('closed') ? args.boolean('closed') : false);
            final resolved = await _resolveBorderDependencies(
                context, index, definition, selection, border);
            final path = _borderPath(mapId, borderId), json = resolved.toJson();
            final bytes = _encode(
                json, LocalMapExteriorDecorationAuthoring.maximumBorderBytes);
            final next = _DecorationIndex(definition, index.sectors, borders: {
              ...index.borders,
              borderId: _SectorSummary.fromBorder(resolved,
                  computeAuthoringBytesFingerprint(bytes, logicalName: path))
            });
            next.validate();
            return {context.storageKey: next.toJson(), path: json};
          }
          final sectorId = args.string('sectorId'),
              summary = index.sectors[args.string('sectorId')];
          if (summary == null) {
            throw const FormatException(
                'Unknown exterior native target sector.');
          }
          final sector = selectedSector!;
          final cells = _worldCells(args.list('cells'));
          final changed = environment
              ? native.generateEnvironment(
                  decoration: definition,
                  sector: sector,
                  manifest: selection,
                  presetId: reference,
                  areaId: args.string('areaId'),
                  layerId:
                      args.optionalString('layerId') ?? 'exterior_environment',
                  seed: args.integer('seed'),
                  logicalCells: cells,
                  projectRevision: expectedCatalogRevision,
                  erase: args.contains('erase') ? args.boolean('erase') : false)
              : native.paintTerrain(
                  decoration: definition,
                  sector: sector,
                  manifest: selection,
                  presetId: reference,
                  logicalCells: cells,
                  materialId: args.optionalString('materialId'),
                  erase:
                      args.contains('erase') ? args.boolean('erase') : false);
          final path = _sectorPath(mapId, sectorId),
              json = changed.toJson(),
              bytes = _encode(changed.toJson(),
                  LocalMapExteriorDecorationAuthoring.maximumSectorBytes);
          final next = _DecorationIndex(
              definition,
              {
                ...index.sectors,
                sectorId: _SectorSummary.fromSector(changed,
                    computeAuthoringBytesFingerprint(bytes, logicalName: path))
              },
              borders: index.borders);
          next.validate();
          return {context.storageKey: next.toJson(), path: json};
        });
  }

  Future<ExteriorDecorationBorder> _resolveBorderDependencies(
      _DecorationContext context,
      _DecorationIndex index,
      MapExteriorDecoration definition,
      ProjectManifest selection,
      ExteriorDecorationBorder border) async {
    final sectors = <String, ExteriorDecorationSector>{};
    ExteriorDecorationBorder? resolved;
    for (var pass = 0; pass <= index.sectors.length; pass++) {
      final result = resolveExteriorDecorationBorder(
          manifest: selection,
          decoration: _withVisuals(definition, sectors.values, const []),
          border: border,
          playableMap: context.map);
      final samples =
          result.sourceContext!.fingerprintContext()['samples'] as List;
      final required = <String>{};
      for (final raw in samples) {
        final sample = raw as Map;
        final x = border.originX + (sample['x'] as num),
            z = border.originZ + (sample['z'] as num);
        if (definition.playableBounds.contains(x, z)) continue;
        for (final summary in index.sectors.values) {
          if (!sectors.containsKey(summary.id) &&
              x >= summary.x &&
              x < summary.x + summary.width &&
              z >= summary.z &&
              z < summary.z + summary.depth) {
            required.add(summary.id);
          }
        }
      }
      if (required.isEmpty) {
        resolved = applyExteriorDecorationBorderResolution(border, result);
        break;
      }
      for (final id in required) {
        sectors[id] = await _readSector(context, index.sectors[id]!);
      }
    }
    if (resolved == null) {
      throw const FormatException(
          'Native Border terrain dependency resolution did not converge.');
    }
    return resolved;
  }

  Future<_ExteriorNativeCatalog> _nativeCatalog(
      _DecorationContext context) async {
    final descriptorBytes = await _readBytes(context, 'project.json',
        LocalMapExteriorDecorationAuthoring.maximumDefinitionBytes);
    if (descriptorBytes == null) {
      throw const FormatException(
          'Native exterior editing requires a canonical working catalog.');
    }
    final descriptor = _decode(descriptorBytes);
    if (descriptor['format'] != 'avelune.working-catalog') {
      throw const FormatException(
          'Native exterior editing requires explicit working-catalog admission; no project is partitioned implicitly.');
    }
    final store = CatalogStorageStore(
        projectRoot: context.root, reader: _reader, gateway: context.gateway);
    final reader = await CatalogProjectReader.open(
        store: store, descriptor: descriptor, metadataFields: {'settings'});
    if (reader == null || reader.readOnly) {
      throw const FormatException(
          'Native exterior editing requires a writable canonical catalog.');
    }
    return _ExteriorNativeCatalog(
        store,
        reader,
        reader.revision,
        computeAuthoringBytesFingerprint(descriptorBytes,
            logicalName: 'project.json'));
  }
}

final class _ExteriorNativeCatalog {
  const _ExteriorNativeCatalog(
      this.store, this.reader, this.revision, this.descriptorRevision);
  final CatalogStorageStore store;
  final CatalogProjectReader reader;
  final String revision, descriptorRevision;
}

List<GridPos> _worldCells(List<Object?> raw) {
  if (raw.length > 4096) {
    throw const FormatException(
        'Native exterior gesture exceeds its bounded cell budget.');
  }
  return [
    for (final item in raw)
      if (item is Map &&
          item.length == 2 &&
          item['x'] is int &&
          item['z'] is int)
        GridPos(x: item['x'] as int, y: item['z'] as int)
      else
        throw const FormatException(
            'Native exterior cells require exact integer x and z.')
  ];
}
