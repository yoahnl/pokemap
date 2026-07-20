import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/border_publication_transaction.dart';

enum BorderPublicationManifestOperation {
  validateStagedManifest,
  atomicReplace,
}

enum BorderPublicationManifestErrorCode {
  invalidStageId,
  stagedManifestInvalid,
  staleManifest,
  atomicReplaceFailed,
}

final class BorderPublicationManifestException implements Exception {
  const BorderPublicationManifestException({
    required this.code,
    required this.userMessage,
    this.cause,
  });

  final BorderPublicationManifestErrorCode code;
  final String userMessage;
  final Object? cause;

  @override
  String toString() =>
      'BorderPublicationManifestException.${code.name}: $userMessage';
}

typedef BorderPublicationManifestOperationHook = FutureOr<void> Function(
  BorderPublicationManifestOperation operation,
  String stagedPath,
);

typedef BorderAtomicFileReplace = Future<void> Function(
  File staged,
  File destination,
);

/// Atomically replaces `project.json` from a validated sibling temporary file.
///
/// The OS rename is the single publication point. Until it succeeds, the old
/// manifest remains untouched. Snapshot files are finalized by the enclosing
/// transaction before this adapter is invoked.
final class FileBorderPublicationManifestPort
    implements BorderPublicationManifestPort {
  FileBorderPublicationManifestPort({
    required String manifestPath,
    required void Function(ProjectManifest manifest) applyInMemoryManifest,
    String Function()? stageIdFactory,
    BorderAtomicFileReplace? atomicFileReplace,
    this.beforeOperation,
  })  : _manifestPath = p.normalize(p.absolute(manifestPath)),
        _applyInMemoryManifest = applyInMemoryManifest,
        _stageIdFactory = stageIdFactory ?? _defaultStageId,
        _atomicFileReplace = atomicFileReplace ?? _defaultAtomicFileReplace;

  final String _manifestPath;
  final void Function(ProjectManifest manifest) _applyInMemoryManifest;
  final String Function() _stageIdFactory;
  final BorderAtomicFileReplace _atomicFileReplace;
  final BorderPublicationManifestOperationHook? beforeOperation;

  @override
  Future<void> atomicallyReplace({
    required ProjectManifest previousManifest,
    required ProjectManifest nextManifest,
  }) async {
    ProjectValidator.validate(nextManifest);
    final stageId = _stageIdFactory();
    if (!_isSafeStageId(stageId)) {
      throw const BorderPublicationManifestException(
        code: BorderPublicationManifestErrorCode.invalidStageId,
        userMessage: 'L’identifiant temporaire du manifeste est invalide.',
      );
    }

    final manifestFile = File(_manifestPath);
    await manifestFile.parent.create(recursive: true);
    final staged = File('$_manifestPath.border-$stageId.tmp');
    if (await staged.exists()) {
      throw const BorderPublicationManifestException(
        code: BorderPublicationManifestErrorCode.invalidStageId,
        userMessage:
            'Un manifeste temporaire portant cet identifiant existe déjà.',
      );
    }

    try {
      final encoded = const JsonEncoder.withIndent('  ').convert(
        nextManifest.toJson(),
      );
      await staged.writeAsString(encoded, flush: true);
      await Future<void>.sync(
        () => beforeOperation?.call(
          BorderPublicationManifestOperation.validateStagedManifest,
          staged.path,
        ),
      );
      await _validateStagedManifest(staged, nextManifest);
      await Future<void>.sync(
        () => beforeOperation?.call(
          BorderPublicationManifestOperation.atomicReplace,
          staged.path,
        ),
      );
      await _validateCurrentManifest(manifestFile, previousManifest);
      try {
        await _atomicFileReplace(staged, manifestFile);
      } on FileSystemException catch (error) {
        throw BorderPublicationManifestException(
          code: BorderPublicationManifestErrorCode.atomicReplaceFailed,
          userMessage: 'Le manifeste n’a pas pu être remplacé atomiquement.',
          cause: error,
        );
      }
    } finally {
      if (await staged.exists()) {
        await staged.delete();
      }
    }
  }

  @override
  void applyInMemory(ProjectManifest manifest) {
    _applyInMemoryManifest(manifest);
  }
}

Future<void> _validateCurrentManifest(
  File manifestFile,
  ProjectManifest expected,
) async {
  try {
    if (!await manifestFile.exists()) {
      throw const FormatException('current project manifest is missing');
    }
    final decodedJson = jsonDecode(await manifestFile.readAsString());
    if (decodedJson is! Map<String, dynamic>) {
      throw const FormatException('current project manifest must be an object');
    }
    final current = ProjectManifest.fromJson(
      migrateProjectManifestJson(decodedJson),
    );
    ProjectValidator.validate(current);
    if (current != expected) {
      throw const FormatException(
        'current project manifest differs from the publication baseline',
      );
    }
  } catch (error) {
    throw BorderPublicationManifestException(
      code: BorderPublicationManifestErrorCode.staleManifest,
      userMessage:
          'Le projet a changé sur le disque. Rechargez-le avant de republier.',
      cause: error,
    );
  }
}

Future<void> _validateStagedManifest(
  File staged,
  ProjectManifest expected,
) async {
  try {
    final decodedJson = jsonDecode(await staged.readAsString());
    if (decodedJson is! Map<String, dynamic>) {
      throw const FormatException('project manifest must be an object');
    }
    final decoded = ProjectManifest.fromJson(
      migrateProjectManifestJson(decodedJson),
    );
    ProjectValidator.validate(decoded);
    if (decoded != expected) {
      throw const FormatException(
        'staged project manifest does not round-trip exactly',
      );
    }
  } catch (error) {
    throw BorderPublicationManifestException(
      code: BorderPublicationManifestErrorCode.stagedManifestInvalid,
      userMessage: 'Le manifeste temporaire est invalide après sérialisation.',
      cause: error,
    );
  }
}

bool _isSafeStageId(String value) =>
    value.isNotEmpty && RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value);

String _defaultStageId() =>
    '${DateTime.now().microsecondsSinceEpoch}_${pid.toRadixString(16)}';

Future<void> _defaultAtomicFileReplace(File staged, File destination) async {
  await staged.rename(destination.path);
}
