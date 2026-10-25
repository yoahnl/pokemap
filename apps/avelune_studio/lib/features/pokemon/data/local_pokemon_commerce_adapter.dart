import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/map_authoring.dart'
    show AuthoringTransactionFaultInjector;
import 'package:map_core/map_core.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../../project_session/data/local_workshop_reader.dart';
import '../domain/pokemon_commerce_port.dart';
import 'pokemon_capture_sprite_import.dart';
import 'local_pokemon_transaction.dart';
import 'pokemon_media_projection.dart';

final class LocalPokemonCommerceAdapter
    implements PokemonCommercePort, PokemonCommerceReferencePort {
  const LocalPokemonCommerceAdapter({
    required this.session,
    required this.mapAdapter,
    this.reader = const LocalProjectFileReader(),
    this.faultInjector,
  });

  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final ProjectFileReader reader;
  final AuthoringTransactionFaultInjector? faultInjector;

  @override
  Future<String> importCaptureSprite({
    required String sourcePath,
    required String itemId,
    bool Function()? shouldContinue,
  }) => PokemonCaptureSpriteImport(
    session: session,
    mapAdapter: mapAdapter,
  ).run(sourcePath: sourcePath, itemId: itemId, shouldContinue: shouldContinue);

  @override
  Future<Uint8List?> loadCaptureSprite(String relativePath) async {
    if (!ProjectCaptureItemDefinition.isValidAnimationSpritePath(
      relativePath,
    )) {
      return null;
    }
    return loadPokemonImage(
      reader: const LocalProjectFileReader(),
      projectRoot: session.directoryPath,
      relativePath: relativePath.trim(),
    );
  }

  @override
  Future<PokemonCommerceImportPreview> previewJson(
    String path, {
    required bool item,
  }) async {
    final document = jsonDecode(await File(path).readAsString());
    if (document is! Map<String, dynamic>) {
      throw const FormatException('Le JSON doit contenir une fiche unique.');
    }
    final snapshot = await load();
    if (item) {
      if (snapshot.catalog == null) {
        throw StateError(snapshot.problem ?? 'Catalogue indisponible.');
      }
      final definition = ProjectItemDefinition.fromJson(document);
      return PokemonCommerceImportPreview(
        item: definition,
        shop: null,
        existingItem: snapshot.catalog!.entries
            .where((value) => value.id == definition.id)
            .firstOrNull,
        existingShop: null,
      );
    }
    final definition = ShopDefinition.fromJson(document);
    return PokemonCommerceImportPreview(
      item: null,
      shop: definition,
      existingItem: null,
      existingShop: snapshot.shops
          .where((value) => value.id == definition.id)
          .firstOrNull,
    );
  }

  @override
  Future<PokemonCommerceSnapshot>
  load() => LocalWorkshopReader(session, reader: reader).read(
    metadataFields: {'pokemon', 'shops', 'bagCapacity', 'newGame', 'trainers'},
    operation: (project, access, _) async {
      final path = project.pokemon.catalogFiles['items'];
      ProjectItemCatalog? catalog;
      if (path != null) {
        final probe = await access.probeResource(path);
        if (probe.status != ProjectResourceProbeStatus.missing) {
          final bytes = await access.readBytes(path);
          try {
            catalog = decodeProjectItemCatalog(jsonDecode(utf8.decode(bytes)));
          } on FormatException {
            catalog = null;
          }
        }
      }
      return _projection(project, const [], catalog, referencesComplete: false);
    },
  );

  @override
  Future<PokemonCommerceSnapshot> analyzeReferences() => _transaction.analyze(
    (snapshot) async =>
        _projection(snapshot.manifest, snapshot.maps, snapshot.itemCatalog),
  );

  PokemonCommerceSnapshot _projection(
    ProjectManifest manifest,
    List<MapData> maps,
    ProjectItemCatalog? catalog, {
    bool referencesComplete = true,
  }) {
    final catalogPath = manifest.pokemon.catalogFiles['items'];
    return PokemonCommerceSnapshot(
      project: manifest,
      catalog: catalog,
      shops: List.unmodifiable(manifest.shops),
      references: buildProjectItemReferenceIndex(
        project: manifest,
        maps: maps,
        itemCatalog: catalog,
      ),
      narrativeReferences: buildNarrativeDependencyIndex(
        project: manifest,
        maps: maps,
        itemCatalog: catalog,
      ),
      shopDiagnostics: ShopStateValidator(
        project: manifest,
        knownItemIds: {
          for (final item
              in catalog?.entries ?? const <ProjectItemDefinition>[])
            item.id,
        },
      ).validate(),
      catalogPath: catalogPath,
      referencesComplete: referencesComplete,
      problem: !manifest.pokemon.enabled
          ? 'La configuration Pokémon est désactivée.'
          : catalogPath == null
          ? 'Aucun catalogue d’objets n’est configuré pour ce projet.'
          : catalog == null
          ? 'Le catalogue d’objets est absent ou illisible.'
          : null,
    );
  }

  LocalPokemonTransaction get _transaction => LocalPokemonTransaction(
    session: session,
    mapAdapter: mapAdapter,
    reader: reader,
    faultInjector: faultInjector,
  );

  @override
  Future<void> saveItem(
    ProjectItemDefinition? before,
    ProjectItemDefinition after,
  ) async {
    ProjectItemDefinition? current(ProjectSnapshot snapshot) {
      final catalog = snapshot.itemCatalog;
      if (catalog == null) throw StateError('Catalogue d’objets indisponible.');
      return catalog.entries.where((entry) => entry.id == after.id).firstOrNull;
    }

    final warning = await _transaction.run(
      actionId: before == null ? 'item.create' : 'item.update',
      parameters: before == null
          ? {'definition': after.toJson()}
          : {'itemId': after.id, 'definition': after.toJson()},
      allowedStorageKeys: (snapshot) {
        final path = snapshot.manifest.pokemon.catalogFiles['items'];
        if (path == null) throw StateError('Destination non configurée.');
        return {path};
      },
      validateBefore: (snapshot) {
        if (!_same(current(snapshot)?.toJson(), before?.toJson())) {
          throw StateError(
            'Cet objet a changé sur le disque. Votre brouillon est conservé.',
          );
        }
      },
      validateAfter: (snapshot) {
        if (!_same(current(snapshot)?.toJson(), after.normalized().toJson())) {
          throw StateError('L’objet enregistré ne correspond pas au reçu.');
        }
      },
    );
    if (warning != null) throw StateError(warning);
  }

  @override
  Future<({String? refreshWarning})> saveBagCapacity(
    ProjectBagCapacity before,
    ProjectBagCapacity after,
  ) async {
    final warning = await _transaction.run(
      actionId: 'bag.capacity.set',
      parameters: after.toJson(),
      allowedStorageKeys: (_) => {'project.json'},
      validateBefore: (snapshot) {
        if (snapshot.manifest.bagCapacity != before) {
          throw StateError(
            'La capacité du sac a changé sur le disque. Votre brouillon est conservé.',
          );
        }
      },
      validateAfter: (snapshot) {
        if (snapshot.manifest.bagCapacity != after) {
          throw StateError(
            'La capacité enregistrée ne correspond pas au reçu.',
          );
        }
      },
    );
    return (
      refreshWarning: warning?.replaceFirst(
        'Enregistrement confirmé',
        'Capacité enregistrée',
      ),
    );
  }

  @override
  Future<void> saveShop(ShopDefinition? before, ShopDefinition after) async {
    ShopDefinition? current(ProjectSnapshot snapshot) => snapshot.manifest.shops
        .where((entry) => entry.id == after.id)
        .firstOrNull;
    final warning = await _transaction.run(
      actionId: 'campaign.shop.upsert',
      parameters: {'value': after.toJson()},
      allowedStorageKeys: (_) => {'project.json'},
      validateBefore: (snapshot) {
        if (!_same(current(snapshot)?.toJson(), before?.toJson())) {
          throw StateError(
            'Cette boutique a changé sur le disque. Votre brouillon est conservé.',
          );
        }
      },
      validateAfter: (snapshot) {
        if (!_same(current(snapshot)?.toJson(), after.normalized().toJson())) {
          throw StateError(
            'La boutique enregistrée ne correspond pas au reçu.',
          );
        }
      },
    );
    if (warning != null) throw StateError(warning);
  }

  bool _same(Object? first, Object? second) =>
      jsonEncode(first) == jsonEncode(second);
}
