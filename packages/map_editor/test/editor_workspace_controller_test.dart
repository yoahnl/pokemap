import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/application/editor_workspace_controller.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  group('EditorWorkspaceController', () {
    const controller = EditorWorkspaceController();

    test('selectPokedexWorkspace switches mode and clears stale errors', () {
      const current = EditorState(
        workspaceMode: EditorWorkspaceMode.map,
        errorMessage: 'Old failure',
        pokemonCatalogSection: PokemonCatalogSection.items,
      );

      final next = controller.selectPokedexWorkspace(current);

      expect(next.workspaceMode, EditorWorkspaceMode.pokedex);
      expect(next.pokemonCatalogSection, PokemonCatalogSection.pokedex);
      expect(next.errorMessage, isNull);
      expect(next.statusMessage, current.statusMessage);
    });

    test('selectTrainerWorkspace switches mode and clears stale errors', () {
      const current = EditorState(
        workspaceMode: EditorWorkspaceMode.map,
        errorMessage: 'Old failure',
      );

      final next = controller.selectTrainerWorkspace(current);

      expect(next.workspaceMode, EditorWorkspaceMode.trainer);
      expect(next.errorMessage, isNull);
      expect(next.statusMessage, current.statusMessage);
    });

    test('selectDialogueWorkspace keeps project session and only changes mode',
        () {
      const current = EditorState(
        projectRootPath: '/tmp/demo',
        workspaceMode: EditorWorkspaceMode.cutscene,
      );

      final next = controller.selectDialogueWorkspace(current);

      expect(next.projectRootPath, '/tmp/demo');
      expect(next.workspaceMode, EditorWorkspaceMode.dialogue);
    });

    test(
        'selectEnvironmentStudioWorkspace switches mode and clears stale errors',
        () {
      const current = EditorState(
        workspaceMode: EditorWorkspaceMode.map,
        errorMessage: 'Old failure',
      );

      final next = controller.selectEnvironmentStudioWorkspace(current);

      expect(next.workspaceMode, EditorWorkspaceMode.environmentStudio);
      expect(next.errorMessage, isNull);
      expect(next.statusMessage, current.statusMessage);
    });

    test('selectBorderStudioWorkspace opens without an active map', () {
      const current = EditorState(
        projectRootPath: '/tmp/border-project',
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: null,
        errorMessage: 'Old failure',
      );

      final next = controller.selectBorderStudioWorkspace(current);

      expect(next.workspaceMode, EditorWorkspaceMode.borderStudio);
      expect(next.projectRootPath, '/tmp/border-project');
      expect(next.activeMap, isNull);
      expect(next.errorMessage, isNull);
    });

    test(
        'selectPersonalizationStudioWorkspace keeps project context and clears stale errors',
        () {
      const current = EditorState(
        projectRootPath: '/tmp/personalized-project',
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: null,
        errorMessage: 'Old failure',
      );

      final next = controller.selectPersonalizationStudioWorkspace(current);

      expect(next.workspaceMode, EditorWorkspaceMode.personalizationStudio);
      expect(next.projectRootPath, '/tmp/personalized-project');
      expect(next.activeMap, isNull);
      expect(next.errorMessage, isNull);
    });

    test(
        'selectPokemonCatalogSection opens the parent workspace and stores the section',
        () {
      const current = EditorState(
        workspaceMode: EditorWorkspaceMode.map,
        errorMessage: 'Old failure',
      );

      final next = controller.selectPokemonCatalogSection(
        current,
        PokemonCatalogSection.items,
      );

      expect(next.workspaceMode, EditorWorkspaceMode.pokedex);
      expect(next.pokemonCatalogSection, PokemonCatalogSection.items);
      expect(next.errorMessage, isNull);
    });
  });
}
