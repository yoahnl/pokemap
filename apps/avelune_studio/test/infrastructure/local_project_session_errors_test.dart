import 'dart:io';

import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart' show WorkspaceAccessException;
import 'package:map_authoring/map_authoring_local.dart';

void main() {
  test('reports access denied without attempting a manifest read', () async {
    final reader = DeniedProjectReader();

    await expectLater(
      LocalProjectSessionAdapter(fileReader: reader).open('/example'),
      throwsA(
        isA<ProjectOpenFailure>().having(
          (error) => error.problem,
          'problem',
          ProjectOpenProblem.accessDenied,
        ),
      ),
    );

    expect(reader.readCount, 0);
  });

  test('maps an undifferentiated filesystem read error honestly', () async {
    await expectLater(
      LocalProjectSessionAdapter(
        fileReader: UnavailableProjectReader(),
      ).open('/example'),
      throwsA(
        isA<ProjectOpenFailure>().having(
          (error) => error.problem,
          'problem',
          ProjectOpenProblem.readFailed,
        ),
      ),
    );
  });

  test('maps a surfaced native permission error', () async {
    await expectLater(
      LocalProjectSessionAdapter(
        fileReader: PermissionProjectReader(),
      ).open('/example'),
      throwsA(
        isA<ProjectOpenFailure>().having(
          (error) => error.problem,
          'problem',
          ProjectOpenProblem.accessDenied,
        ),
      ),
    );
  });
}

final class DeniedProjectReader
    implements ProjectFileReader, ProjectResourceProbeReader {
  var readCount = 0;

  @override
  Future<String> canonicalizeDirectory(String path) async => path;

  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) async => const ProjectResourceProbe.accessDenied();

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    readCount++;
    throw StateError('Denied resource must not be read');
  }
}

final class UnavailableProjectReader implements ProjectFileReader {
  @override
  Future<String> canonicalizeDirectory(String path) async => path;

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async => throw const WorkspaceAccessException(
    'workspace.file_unavailable',
    'Resource unavailable',
  );
}

final class PermissionProjectReader implements ProjectFileReader {
  @override
  Future<String> canonicalizeDirectory(String path) async =>
      throw const FileSystemException('Permission denied', '', OSError('', 13));

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async => throw StateError('Inaccessible directory must not be read');
}
