import 'package:flutter_test/flutter_test.dart';
import 'package:playable_runtime_host/src/runtime_project_picker.dart';

void main() {
  group('pickRuntimeProjectDirectory', () {
    test('returns cancelled when the directory picker is dismissed', () async {
      final result = await pickRuntimeProjectDirectory(
        pickDirectoryPath: () async => null,
        importProjectJsonPath: (projectJsonPath) async => projectJsonPath,
      );

      expect(result.outcome, RuntimeProjectPickOutcome.cancelled);
      expect(result.projectJsonPath, isNull);
      expect(result.errorMessage, isNull);
    });

    test('rejects directories that do not contain a project.json', () async {
      final result = await pickRuntimeProjectDirectory(
        pickDirectoryPath: () async => '/picked/project_dir',
        importProjectJsonPath: (projectJsonPath) async => projectJsonPath,
        projectFileExists: (path) async => false,
      );

      expect(result.outcome, RuntimeProjectPickOutcome.invalidSelection);
      expect(result.projectJsonPath, isNull);
      expect(
        result.errorMessage,
        'Le dossier sélectionné ne contient pas de project.json.',
      );
    });

    test('imports the selected project directory through the injected seam',
        () async {
      var importedPath = '';
      final result = await pickRuntimeProjectDirectory(
        pickDirectoryPath: () async => '/picked/project_dir',
        importProjectJsonPath: (projectJsonPath) async {
          importedPath = projectJsonPath;
          return '/sandbox/copied_project/project.json';
        },
        projectFileExists: (path) async => path == '/picked/project_dir/project.json',
      );

      expect(importedPath, '/picked/project_dir/project.json');
      expect(result.outcome, RuntimeProjectPickOutcome.selected);
      expect(
        result.projectJsonPath,
        '/sandbox/copied_project/project.json',
      );
    });
  });
}
