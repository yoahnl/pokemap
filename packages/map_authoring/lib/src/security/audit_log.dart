import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../support/authoring_file_snapshot.dart';
import '../support/authoring_fingerprint.dart';
import 'audit_record.dart';

final class AuthoringAuditLogException implements Exception {
  const AuthoringAuditLogException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'AuthoringAuditLogException($code): $message';
}

abstract interface class AuthoringAuditLog {
  Future<void> append(AuthoringAuditRecord record);

  Future<List<AuthoringAuditRecord>> readAll();
}

/// Locked, flushed, hash-chained JSONL audit sink inside project metadata.
final class FileAuthoringAuditLog implements AuthoringAuditLog {
  FileAuthoringAuditLog._(this._projectRoot, this._onFullRead);

  static Future<FileAuthoringAuditLog> open({
    required String projectRoot,
    void Function()? onFullRead,
  }) async {
    try {
      final directory = Directory(projectRoot);
      if ((await directory.stat()).type != FileSystemEntityType.directory) {
        throw const AuthoringAuditLogException(
          'audit.project_directory_required',
          'The audit project root is not a directory.',
        );
      }
      return FileAuthoringAuditLog._(
        await directory.resolveSymbolicLinks(),
        onFullRead,
      );
    } on AuthoringAuditLogException {
      rethrow;
    } on Object {
      throw const AuthoringAuditLogException(
        'audit.project_unavailable',
        'The audit project root is unavailable.',
      );
    }
  }

  final String _projectRoot;
  final void Function()? _onFullRead;
  _AuditAppendIndex? _cachedAppendIndex;
  AuthoringFileSnapshot? _cachedSnapshot;

  static final Map<String, Future<void>> _inProcessLocks = {};

  @override
  Future<void> append(AuthoringAuditRecord record) {
    return _guard(() async {
      await _withLock(() async {
        final file = await _auditFile();
        final index = await _readAppendIndex(file);
        if (index.auditIds.contains(record.auditId)) {
          throw const AuthoringAuditLogException(
            'audit.identity_conflict',
            'The audit identity is already present.',
          );
        }
        final previousDigest = index.lastDigest;
        final event = _AuditEvent(
          previousDigest: previousDigest,
          record: record,
          digest: _eventDigest(previousDigest, record),
        );
        final writer = await file.open(mode: FileMode.append);
        try {
          await writer.writeString('${jsonEncode(event.toJson())}\n');
          await writer.flush();
        } finally {
          await writer.close();
        }
        _cachedAppendIndex = _AuditAppendIndex(
          auditIds: <String>{...index.auditIds, record.auditId},
          lastDigest: event.digest,
        );
        _cachedSnapshot = await AuthoringFileSnapshot.capture(file);
      });
    });
  }

  @override
  Future<List<AuthoringAuditRecord>> readAll() {
    return _guard(() async {
      return _withLock(() async {
        final events = await _readEvents(await _auditFile());
        return List.unmodifiable(events.map((event) => event.record));
      });
    });
  }

  Future<T> _withLock<T>(Future<T> Function() operation) async {
    final previous = _inProcessLocks[_projectRoot] ?? Future<void>.value();
    final completion = Completer<void>();
    _inProcessLocks[_projectRoot] = completion.future;
    await previous;
    try {
      return await _withOsLock(operation);
    } finally {
      completion.complete();
      if (identical(_inProcessLocks[_projectRoot], completion.future)) {
        _inProcessLocks.remove(_projectRoot);
      }
    }
  }

  Future<T> _withOsLock<T>(Future<T> Function() operation) async {
    late final RandomAccessFile lock;
    try {
      final root = await _authoringRoot();
      lock = await File(_join(root.path, 'audit.lock')).open(
        mode: FileMode.append,
      );
      await lock.lock(FileLock.exclusive);
    } on AuthoringAuditLogException {
      rethrow;
    } on Object {
      throw const AuthoringAuditLogException(
        'audit.io',
        'The audit lock could not be acquired safely.',
      );
    }
    try {
      return await operation();
    } finally {
      try {
        await lock.unlock();
      } on Object {
        // Closing releases the OS lock even if explicit unlock fails.
      }
      await lock.close();
    }
  }

  Future<File> _auditFile() async {
    final file = File(_join((await _authoringRoot()).path, 'audit.jsonl'));
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type != FileSystemEntityType.notFound &&
        type != FileSystemEntityType.file) {
      throw const AuthoringAuditLogException(
        'audit.path_invalid',
        'The audit file is not a safe regular file.',
      );
    }
    return file;
  }

  Future<Directory> _authoringRoot() async {
    var current = Directory(_projectRoot);
    for (final segment in const ['.pokemap', 'authoring']) {
      final next = Directory(_join(current.path, segment));
      final type = await FileSystemEntity.type(next.path, followLinks: false);
      if (type == FileSystemEntityType.notFound) {
        await next.create();
      } else if (type != FileSystemEntityType.directory) {
        throw const AuthoringAuditLogException(
          'audit.path_invalid',
          'The audit metadata directory is unsafe.',
        );
      }
      current = next;
    }
    return current;
  }

  Future<List<_AuditEvent>> _readEvents(File file) async {
    final snapshot = await AuthoringFileSnapshot.capture(file);
    _onFullRead?.call();
    if (snapshot == null) {
      _cachedAppendIndex = const _AuditAppendIndex(
        auditIds: <String>{},
        lastDigest: null,
      );
      _cachedSnapshot = null;
      return const [];
    }
    final content = await file.readAsString();
    if (content.isEmpty) {
      _cachedAppendIndex = const _AuditAppendIndex(
        auditIds: <String>{},
        lastDigest: null,
      );
      _cachedSnapshot = snapshot;
      return const [];
    }
    final lines = content.split('\n');
    if (lines.last.isEmpty) lines.removeLast();
    if (lines.any((line) => line.isEmpty)) throw const FormatException();
    final events = <_AuditEvent>[];
    String? expectedPrevious;
    for (final line in lines) {
      final decoded = jsonDecode(line);
      if (decoded is! Map) throw const FormatException();
      final event = _AuditEvent.fromJson(Map<String, dynamic>.from(decoded));
      if (event.previousDigest != expectedPrevious ||
          event.digest != _eventDigest(expectedPrevious, event.record)) {
        throw const FormatException();
      }
      events.add(event);
      expectedPrevious = event.digest;
    }
    _cachedAppendIndex = _AuditAppendIndex(
      auditIds: <String>{for (final event in events) event.record.auditId},
      lastDigest: expectedPrevious,
    );
    _cachedSnapshot = snapshot;
    return events;
  }

  Future<_AuditAppendIndex> _readAppendIndex(File file) async {
    final snapshot = await AuthoringFileSnapshot.capture(file);
    final cached = _cachedAppendIndex;
    if (cached != null && snapshot == _cachedSnapshot) return cached;
    await _readEvents(file);
    return _cachedAppendIndex!;
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on AuthoringAuditLogException {
      rethrow;
    } on FormatException {
      throw const AuthoringAuditLogException(
        'audit.corrupt',
        'The audit log failed strict verification.',
      );
    } on Object {
      throw const AuthoringAuditLogException(
        'audit.io',
        'The audit log could not be accessed safely.',
      );
    }
  }
}

final class _AuditEvent {
  const _AuditEvent({
    required this.previousDigest,
    required this.record,
    required this.digest,
  });

  factory _AuditEvent.fromJson(Map<String, dynamic> json) {
    const keys = {'schemaVersion', 'previousDigest', 'record', 'digest'};
    final previous = json['previousDigest'];
    if (json['schemaVersion'] != 1 ||
        json.keys.any((key) => !keys.contains(key)) ||
        (previous != null && previous is! String) ||
        json['record'] is! Map ||
        json['digest'] is! String) {
      throw const FormatException();
    }
    return _AuditEvent(
      previousDigest: previous as String?,
      record: AuthoringAuditRecord.fromJson(
        Map<String, dynamic>.from(json['record'] as Map),
      ),
      digest: json['digest'] as String,
    );
  }

  final String? previousDigest;
  final AuthoringAuditRecord record;
  final String digest;

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'previousDigest': previousDigest,
        'record': record.toJson(),
        'digest': digest,
      };
}

final class _AuditAppendIndex {
  const _AuditAppendIndex({required this.auditIds, required this.lastDigest});

  final Set<String> auditIds;
  final String? lastDigest;
}

String _eventDigest(String? previousDigest, AuthoringAuditRecord record) {
  return computeAuthoringJsonFingerprint(
    {
      'schemaVersion': 1,
      'previousDigest': previousDigest,
      'record': record.toJson(),
    },
    logicalName: 'authoring-audit-event.json',
  );
}

String _join(String first, String second) =>
    [first, second].join(Platform.pathSeparator);
