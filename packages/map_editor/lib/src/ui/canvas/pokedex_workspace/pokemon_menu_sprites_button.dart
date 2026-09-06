import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../app/providers/core/repository_providers.dart';
import '../../../app/providers/pokedex_providers.dart';
import '../../../application/use_cases/import_pokemon_menu_sprites_use_case.dart';
import '../../../infrastructure/filesystem/pokemon_menu_sprite_source.dart';
import '../../../infrastructure/filesystem/project_filesystem.dart';
import '../../design_system/pokemap_button.dart';
import '../../design_system/pokemap_dialog.dart';

class PokemonMenuSpritesButton extends ConsumerStatefulWidget {
  const PokemonMenuSpritesButton({
    super.key,
    required this.projectRoot,
    required this.onImported,
  });

  final String projectRoot;
  final VoidCallback onImported;

  @override
  ConsumerState<PokemonMenuSpritesButton> createState() =>
      _PokemonMenuSpritesButtonState();
}

class _PokemonMenuSpritesButtonState
    extends ConsumerState<PokemonMenuSpritesButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) => PokeMapButton(
    key: const Key('pokedex-menu-sprites-button'),
    variant: PokeMapButtonVariant.secondary,
    size: PokeMapButtonSize.small,
    isLoading: _busy,
    onPressed: _busy ? null : _import,
    leading: const Icon(Icons.collections_outlined, size: 16),
    child: const Text('Récupérer les miniatures'),
  );

  Future<void> _import() async {
    setState(() => _busy = true);
    final root = widget.projectRoot;
    final service = ImportPokemonMenuSpritesUseCase(
      repository: ref.read(pokemonReadRepositoryProvider),
      mutations: ref.read(authoringMutationAdapterProvider),
    );
    final client = http.Client();
    PokemonMenuSpriteImportPreview? preview;
    try {
      final manifest = PokemonMenuSpriteSource.decodeManifest(
        await rootBundle.loadString('assets/pokemon/menu_sprite_sources.json'),
      );
      final support = await getApplicationSupportDirectory();
      final cacheRoot = p.join(
        support.path,
        'pokemon-menu-sprites',
        manifest['revision'] as String,
      );
      await Directory(cacheRoot).create(recursive: true);
      final source = PokemonMenuSpriteSource(
        cacheRoot: cacheRoot,
        manifest: manifest,
        client: client,
      );
      preview = await service.preview(
        ProjectFileSystem(root),
        sourceDirectory: cacheRoot,
        sourceCatalog: source.catalog,
        resolveSourceFile: source.resolve,
        verifySourceArtifact: source.verify,
      );
      if (!mounted || widget.projectRoot != root) return;
      final details = preview.unavailable.take(12).join('\n');
      if (preview.additions == 0) {
        await showPokeMapNoticeDialog(
          context,
          title: 'Miniatures à jour',
          message:
              '${preview.preserved} emplacements déjà renseignés.\n'
              '${preview.unavailable.length} emplacements sans image disponible.'
              '${details.isEmpty ? '' : '\n\n$details'}',
        );
        return;
      }
      final confirmed = await showPokeMapBinaryConfirmationDialog(
        context,
        title: 'Associer les miniatures au Pokédex',
        message:
            '${preview.additions} emplacements seront complétés ; '
            '${preview.preserved} choix existants seront conservés.\n'
            'Les images seront enregistrées dans ce jeu et disponibles hors ligne.\n'
            'Les portraits personnalisés restent inchangés.\n'
            '${preview.unavailable.length} emplacements sans correspondance.'
            '${details.isEmpty ? '' : '\n\n$details'}',
        secondaryLabel: 'Annuler',
        primaryLabel: 'Associer les miniatures',
      );
      if (!confirmed || !mounted || widget.projectRoot != root) return;
      final count = await service.execute(preview);
      if (!mounted || widget.projectRoot != root) return;
      widget.onImported();
      await showPokeMapNoticeDialog(
        context,
        title: 'Miniatures enregistrées',
        message: '$count emplacements complétés dans le Pokédex de ce jeu.',
      );
    } on Object catch (error) {
      if (mounted && widget.projectRoot == root) {
        widget.onImported();
        await showPokeMapNoticeDialog(
          context,
          title: 'Import des miniatures interrompu',
          message:
              'Vous pouvez réessayer : les associations déjà enregistrées sont conservées.\n\n$error',
        );
      }
    } finally {
      try {
        if (preview != null) await service.release(preview);
      } finally {
        client.close();
        if (mounted) setState(() => _busy = false);
      }
    }
  }
}
