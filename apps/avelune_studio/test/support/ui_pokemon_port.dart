import 'dart:typed_data';

import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_import_models.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_moves_sync_models.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_external_import_models.dart';
import 'package:map_authoring/map_authoring.dart'
    show PokemonExternalSourceRepository;
import 'package:map_authoring/map_authoring_local.dart' show ProjectFileReader;
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_port.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/pokemon_moves_snapshot_source.dart';
import 'package:flutter_test/flutter_test.dart';

import 'm2_ui_fixture.dart';
import 'm3_story_fixture.dart';

class UiPokemonPort implements PokemonWorkspacePort {
  const UiPokemonPort(this.source, this.tester);

  factory UiPokemonPort.forFixture(
    M3StoryFixture fixture,
    WidgetTester tester, {
    PokemonMovesSnapshotSource? movesSource,
    PokemonExternalSourceRepository? externalSource,
    ProjectFileReader? reader,
  }) => UiPokemonPort(
    LocalPokemonWorkspaceAdapter(
      session: fixture.session,
      mapAdapter: fixture.maps,
      movesSource: movesSource,
      externalSource: externalSource,
      reader: reader,
    ),
    tester,
  );

  final PokemonWorkspacePort source;
  final WidgetTester tester;

  @override
  Future<PokemonWorkspaceIndex> loadIndex() async =>
      (await WidgetResourcePort.serial(tester, source.loadIndex))!;

  @override
  Future<PokemonSpeciesBundle> loadSpecies(PokemonSpeciesSummary entry) async =>
      (await WidgetResourcePort.serial(
        tester,
        () => source.loadSpecies(entry),
      ))!;

  @override
  Future<PokemonSpeciesBundle> save(PokemonSpeciesDraft draft) async {
    final outcome =
        (await WidgetResourcePort.serial<(PokemonSpeciesBundle?, Object?)>(
          tester,
          () async {
            try {
              return (await source.save(draft), null);
            } on Object catch (error) {
              return (null, error);
            }
          },
        ))!;
    if (outcome.$2 != null) throw outcome.$2!;
    return outcome.$1!;
  }

  @override
  Future<Uint8List?> loadImage(String relativePath) async =>
      await WidgetResourcePort.serial<Uint8List?>(
        tester,
        () => source.loadImage(relativePath),
      );

  @override
  Future<Uint8List?> loadThumbnail(PokemonSpeciesSummary entry) async =>
      await WidgetResourcePort.serial<Uint8List?>(
        tester,
        () => source.loadThumbnail(entry),
      );

  @override
  Future<PokemonLocalImportPreview> previewJsonImport(String path) async {
    final outcome =
        (await WidgetResourcePort.serial<(PokemonLocalImportPreview?, Object?)>(
          tester,
          () async {
            try {
              return (await source.previewJsonImport(path), null);
            } on Object catch (error) {
              return (null, error);
            }
          },
        ))!;
    if (outcome.$2 != null) throw outcome.$2!;
    return outcome.$1!;
  }

  @override
  Future<String> applyJsonImport(
    PokemonLocalImportPreview preview, {
    required bool confirmOverwrite,
  }) async => (await WidgetResourcePort.serial(
    tester,
    () => source.applyJsonImport(preview, confirmOverwrite: confirmOverwrite),
  ))!;

  @override
  Future<String> importMenuPng({
    required String sourcePath,
    required String speciesId,
    required String formId,
    required String role,
  }) async => (await WidgetResourcePort.serial(
    tester,
    () => source.importMenuPng(
      sourcePath: sourcePath,
      speciesId: speciesId,
      formId: formId,
      role: role,
    ),
  ))!;

  @override
  Future<PokemonMovesSyncPreview> previewMovesSync() async =>
      (await WidgetResourcePort.serial(tester, source.previewMovesSync))!;

  @override
  Future<void> applyMovesSync(PokemonMovesSyncPreview preview) async =>
      WidgetResourcePort.serial(tester, () => source.applyMovesSync(preview));

  @override
  Future<PokemonExternalSearch> searchExternal(String query) async =>
      (await WidgetResourcePort.serial(
        tester,
        () => source.searchExternal(query),
      ))!;

  @override
  Future<PokemonExternalImportPreview> previewExternal(String id) async {
    final outcome =
        (await WidgetResourcePort.serial<
          (PokemonExternalImportPreview?, Object?)
        >(tester, () async {
          try {
            return (await source.previewExternal(id), null);
          } on Object catch (error) {
            return (null, error);
          }
        }))!;
    if (outcome.$2 != null) throw outcome.$2!;
    return outcome.$1!;
  }

  @override
  Future<PokemonExternalImportResult> applyExternal(
    PokemonExternalImportPreview preview,
    PokemonExternalConflictPolicy policy,
  ) async {
    final outcome =
        (await WidgetResourcePort.serial<
          (PokemonExternalImportResult?, Object?)
        >(tester, () async {
          try {
            return (await source.applyExternal(preview, policy), null);
          } on Object catch (error) {
            return (null, error);
          }
        }))!;
    if (outcome.$2 != null) throw outcome.$2!;
    return outcome.$1!;
  }
}
